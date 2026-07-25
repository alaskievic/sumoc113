#!/usr/bin/env python3
import csv
import html
import json
import re
import zipfile
from collections import defaultdict
from pathlib import Path
from xml.sax.saxutils import escape


BASE = Path(__file__).resolve().parent
PLAIN_JSON = BASE / "plain_ocr" / "missing_rj_1980_mistral_raw.json"
TESS_PAGE5 = BASE / "page400-05.tsv"
OUT_XLSX = BASE / "missing_rj_1980_complete_table.xlsx"


COLUMNS = [
    "num_ordem",
    "microrregiao_municipio_genero_industria",
    "estabelecimentos_1980",
    "pessoal_ocupado_31_12_1980_total",
    "pessoal_ocupado_31_12_1980_ligado_producao",
    "media_mensal_pessoal_ocupado_1980",
    "salarios_total_mil_cruzeiros",
    "salarios_pessoal_ligado_producao_mil_cruzeiros",
    "despesas_gerais_mil_cruzeiros",
    "despesas_operacoes_industriais_total_mil_cruzeiros",
    "despesas_operacoes_industriais_materias_primas_materiais_componentes_mil_cruzeiros",
    "valor_producao_mil_cruzeiros",
    "valor_transformacao_industrial_mil_cruzeiros",
    "pagina_esquerda",
    "pagina_direita",
    "observacao_ocr",
]


def clean_cell(value):
    value = html.unescape(str(value)).strip()
    value = re.sub(r"\s+", " ", value)
    value = value.replace("( x )", "(X)").replace("( X )", "(X)")
    value = value.replace("(x)", "(X)").replace("{x}", "(X)").replace("(xX)", "(X)")
    value = value.replace("I XI", "(X)").replace("lXI", "(X)").replace("IX I", "(X)")
    value = value.replace("(8)", "(X)").replace("(R)", "(X)")
    return value


def normalize_num(value):
    value = clean_cell(value)
    if value in {"", "-"}:
        return value
    if value.upper() == "(X)":
        return "(X)"
    if re.fullmatch(r"\d{1,3}(?: \d{3})*", value):
        return int(value.replace(" ", ""))
    return value


def markdown_rows(markdown):
    rows = []
    for line in markdown.splitlines():
        s = line.strip()
        if not s.startswith("|") or not s.endswith("|"):
            continue
        cells = [clean_cell(c) for c in s.strip("|").split("|")]
        if cells and all(re.fullmatch(r"-+", c) for c in cells):
            continue
        if any(c for c in cells):
            rows.append(cells)
    return rows


def parse_odd_page(page_no, markdown):
    rows = []
    for cells in markdown_rows(markdown):
        if not cells or not re.fullmatch(r"\d{3}", cells[0]):
            continue
        num = int(cells[0])
        if not 575 <= num <= 863:
            continue
        if len(cells) >= 6:
            vals = cells[:6]
        elif len(cells) == 4:
            vals = cells[:4] + ["", ""]
        else:
            continue
        rows.append(
            {
                "num_ordem": num,
                "microrregiao_municipio_genero_industria": vals[1],
                "estabelecimentos_1980": normalize_num(vals[2]),
                "pessoal_ocupado_31_12_1980_total": normalize_num(vals[3]),
                "pessoal_ocupado_31_12_1980_ligado_producao": normalize_num(vals[4]),
                "media_mensal_pessoal_ocupado_1980": normalize_num(vals[5]),
                "pagina_esquerda": page_no,
                "observacao_ocr": "",
            }
        )
    return rows


def parse_even_markdown(page_no, markdown, expected_nums):
    candidates = []
    for cells in markdown_rows(markdown):
        if len(cells) < 8:
            continue
        first = clean_cell(cells[0])
        last = clean_cell(cells[-1])
        if not (
            re.fullmatch(r"\d{1,3}(?: \d{3})*", first)
            or first in {"-", "(X)"}
            or first.lower() == "(x)"
        ):
            continue
        vals = [clean_cell(c) for c in cells[:7]]
        row_num = int(last) if re.fullmatch(r"\d{3}", last) else None
        candidates.append((row_num, vals))
    return assign_even_candidates(candidates, expected_nums)


TOKEN_RE = re.compile(r"\( ?[Xx] ?\)|-|\d{1,3}(?:\s+\d{3})*")


def parse_even_text(markdown, expected_nums):
    candidates = []
    in_values = False
    for line in markdown.splitlines():
        if "MIL CRUZEIROS" in line:
            in_values = True
            continue
        if not in_values:
            continue
        row_num = None
        row_match = re.search(r"\s(\d{3})\s*$", line)
        if row_match and int(row_match.group(1)) in expected_nums:
            row_num = int(row_match.group(1))
            line = line[: row_match.start(1)]
        tokens = [clean_cell(t) for t in TOKEN_RE.findall(line)]
        if len(tokens) != 7:
            tokens = split_collapsed_numeric_line(line)
        if len(tokens) >= 7:
            candidates.append((row_num, tokens[:7]))
    return assign_even_candidates(candidates, expected_nums)


def split_collapsed_numeric_line(line):
    normalized = re.sub(r"\(\s*[Xx]\s*\)", " X ", line)
    parts = re.findall(r"X|-|\d+", normalized)
    if not parts:
        return []

    memo = {}

    def rec(i, remaining):
        key = (i, remaining)
        if key in memo:
            return memo[key]
        if remaining == 0:
            return (0, []) if i == len(parts) else (10**9, [])
        if i >= len(parts):
            return (10**9, [])

        best = (10**9, [])
        part = parts[i]
        if part == "X":
            score, tail = rec(i + 1, remaining - 1)
            cand = (score, ["(X)"] + tail)
            best = min(best, cand, key=lambda x: x[0])
        elif part == "-":
            score, tail = rec(i + 1, remaining - 1)
            cand = (score, ["-"] + tail)
            best = min(best, cand, key=lambda x: x[0])
        else:
            for length in (1, 2, 3):
                seg = parts[i : i + length]
                if len(seg) != length or not all(s.isdigit() for s in seg):
                    continue
                if length > 1 and not all(len(s) == 3 for s in seg[1:]):
                    continue
                value = " ".join(seg)
                penalty = {1: 1 if len(seg[0]) == 3 else 4, 2: 0, 3: 2}[length]
                score, tail = rec(i + length, remaining - 1)
                cand = (score + penalty, [value] + tail)
                best = min(best, cand, key=lambda x: x[0])
        memo[key] = best
        return best

    score, values = rec(0, 7)
    if score >= 10**9:
        return [clean_cell(v) for v in TOKEN_RE.findall(line)]
    return values


def assign_even_candidates(candidates, expected_nums):
    expected = list(expected_nums)
    positions = {n: i for i, n in enumerate(expected)}
    cursor = 0
    out = {}
    for row_num, vals in candidates:
        if row_num in positions:
            out[row_num] = [normalize_num(v) for v in vals[:7]]
            cursor = positions[row_num] + 1
            continue
        while cursor < len(expected) and expected[cursor] in out:
            cursor += 1
        if cursor < len(expected):
            out[expected[cursor]] = [normalize_num(v) for v in vals[:7]]
            cursor += 1
    return out


def parse_page5_tesseract():
    if not TESS_PAGE5.exists():
        return {}
    line_words = defaultdict(list)
    with TESS_PAGE5.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            text = row["text"].strip()
            if not text:
                continue
            key = (row["block_num"], row["par_num"], row["line_num"])
            row["left"] = int(row["left"])
            row["top"] = int(row["top"])
            line_words[key].append(row)

    parsed = {}
    active_num = None
    for _, words in sorted(line_words.items(), key=lambda item: min(w["top"] for w in item[1])):
        words = sorted(words, key=lambda w: w["left"])
        first = words[0]["text"]
        fuzzy_num = clean_tess_order_num(first)
        if fuzzy_num is not None:
            active_num = fuzzy_num
        if active_num is None or not 713 <= active_num <= 779:
            continue
        right = [w for w in words if w["left"] >= 2000]
        if len(right) < 3:
            continue
        bins = [
            (2000, 2225),
            (2225, 2465),
            (2465, 2685),
            (2685, 2900),
        ]
        vals = []
        for lo, hi in bins:
            pieces = [w["text"] for w in right if lo <= w["left"] < hi]
            vals.append(clean_tess_value(" ".join(pieces)))
        if len(vals) == 4 and any(v != "" for v in vals[1:]):
            parsed[active_num] = vals
    return parsed


def clean_tess_order_num(value):
    value = value.strip()
    value = value.translate(str.maketrans({"T": "7", "L": "1", "I": "1", "l": "1", "S": "5", "O": "0", "o": "0", "c": "0"}))
    value = re.sub(r"\D", "", value)
    if len(value) == 3:
        num = int(value)
        if 713 <= num <= 779:
            return num
    return None


def clean_tess_value(value):
    value = clean_cell(value)
    if not value:
        return ""
    low = value.lower()
    if "x" in low or "}" in low or "{" in low or re.fullmatch(r"\(?a\)?", low):
        return "(X)"
    value = value.replace("R", "8").replace("T", "7").replace("l", "1").replace("I", "1")
    value = value.replace("O", "0").replace("o", "0").replace("$", "8")
    value = re.sub(r"[^0-9 -]", "", value)
    value = re.sub(r"\s+", " ", value).strip()
    if value in {"", "-"}:
        return value
    return normalize_num(value)


def excel_col(index):
    s = ""
    index += 1
    while index:
        index, rem = divmod(index - 1, 26)
        s = chr(65 + rem) + s
    return s


def cell_xml(row_idx, col_idx, value):
    ref = f"{excel_col(col_idx)}{row_idx}"
    if isinstance(value, int):
        return f'<c r="{ref}"><v>{value}</v></c>'
    text = "" if value is None else str(value)
    return f'<c r="{ref}" t="inlineStr"><is><t>{escape(text)}</t></is></c>'


def write_xlsx(path, rows):
    sheet_rows = [COLUMNS] + [[row.get(col, "") for col in COLUMNS] for row in rows]
    sheet_xml_rows = []
    for r_idx, values in enumerate(sheet_rows, 1):
        cells = "".join(cell_xml(r_idx, c_idx, v) for c_idx, v in enumerate(values))
        sheet_xml_rows.append(f'<row r="{r_idx}">{cells}</row>')
    sheet_xml = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>
  <cols>
    <col min="1" max="1" width="10" customWidth="1"/>
    <col min="2" max="2" width="72" customWidth="1"/>
    <col min="3" max="16" width="18" customWidth="1"/>
  </cols>
  <sheetData>{''.join(sheet_xml_rows)}</sheetData>
  <autoFilter ref="A1:P{len(sheet_rows)}"/>
</worksheet>'''
    workbook_xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets><sheet name="complete_table" sheetId="1" r:id="rId1"/></sheets>
</workbook>'''
    rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>'''
    wb_rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>'''
    styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>'''
    content_types = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>'''
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", content_types)
        zf.writestr("_rels/.rels", rels)
        zf.writestr("xl/workbook.xml", workbook_xml)
        zf.writestr("xl/_rels/workbook.xml.rels", wb_rels)
        zf.writestr("xl/styles.xml", styles)
        zf.writestr("xl/worksheets/sheet1.xml", sheet_xml)


def main():
    data = json.loads(PLAIN_JSON.read_text())
    pages = {p["page"]: p["markdown"] for p in data["pages"]}

    odd_pages = [1, 3, 5, 7, 9]
    even_pages = [2, 4, 6, 8, 10]
    rows_by_num = {}
    order_by_pair = {}
    for odd in odd_pages:
        parsed = parse_odd_page(odd, pages[odd])
        order_by_pair[odd] = [row["num_ordem"] for row in parsed]
        for row in parsed:
            rows_by_num[row["num_ordem"]] = row

    page5_tess = parse_page5_tesseract()
    for num, vals in page5_tess.items():
        row = rows_by_num.get(num)
        if not row:
            continue
        if row["pessoal_ocupado_31_12_1980_ligado_producao"] == "":
            row["pessoal_ocupado_31_12_1980_ligado_producao"] = vals[2]
        if row["media_mensal_pessoal_ocupado_1980"] == "":
            row["media_mensal_pessoal_ocupado_1980"] = vals[3]
        row["observacao_ocr"] = "page 5 columns 5-6 from local Tesseract fallback"

    manual_even = {
        642: ["(X)", "(X)", 1270, 6809, "(X)", 11826, 5017],
        643: ["(X)", "-", "(X)", "-", "-", "-", "-"],
        587: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        593: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        660: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        678: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        679: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        703: [13035, 9947, 7340, 109686, 106815, 206766, 97080],
        779: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        806: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        823: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        836: [3246, 2813, 1379, 8127, 7663, 19938, 11811],
        840: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
        859: ["(X)", "(X)", "(X)", "(X)", "(X)", "(X)", "(X)"],
    }

    even_cols = [
        "salarios_total_mil_cruzeiros",
        "salarios_pessoal_ligado_producao_mil_cruzeiros",
        "despesas_gerais_mil_cruzeiros",
        "despesas_operacoes_industriais_total_mil_cruzeiros",
        "despesas_operacoes_industriais_materias_primas_materiais_componentes_mil_cruzeiros",
        "valor_producao_mil_cruzeiros",
        "valor_transformacao_industrial_mil_cruzeiros",
    ]
    missing_even = []
    for odd, even in zip(odd_pages, even_pages):
        expected = order_by_pair[odd]
        if even == 4:
            even_data = parse_even_text(pages[even], expected)
        else:
            even_data = parse_even_markdown(even, pages[even], expected)
        for num in expected:
            row = rows_by_num[num]
            vals = even_data.get(num) or manual_even.get(num)
            row["pagina_direita"] = even
            if not vals:
                missing_even.append(num)
                row["observacao_ocr"] = (row["observacao_ocr"] + "; " if row["observacao_ocr"] else "") + "missing continuation values"
                vals = [""] * 7
            elif num in manual_even and num not in even_data:
                row["observacao_ocr"] = (row["observacao_ocr"] + "; " if row["observacao_ocr"] else "") + "continuation from sequence/manual fallback"
            for col, val in zip(even_cols, vals):
                row[col] = val

    rows = [rows_by_num[n] for n in sorted(rows_by_num)]
    write_xlsx(OUT_XLSX, rows)

    blank_left = [
        r["num_ordem"]
        for r in rows
        if r["pessoal_ocupado_31_12_1980_ligado_producao"] == ""
        or r["media_mensal_pessoal_ocupado_1980"] == ""
    ]
    print(f"wrote={OUT_XLSX}")
    print(f"rows={len(rows)} min_num={rows[0]['num_ordem']} max_num={rows[-1]['num_ordem']}")
    print(f"missing_even={missing_even}")
    print(f"blank_left_cols={blank_left}")
    print(f"page5_tesseract_rows={len(page5_tess)}")


if __name__ == "__main__":
    main()
