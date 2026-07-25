#!/usr/bin/env python3
"""Parse Mistral OCR text into a wide municipality-by-topic CSV."""

from __future__ import annotations

import argparse
import csv
import difflib
import re
import unicodedata
from collections import OrderedDict
from pathlib import Path


STOP_HEADINGS = (
    "QUADRO DA CULTURA",
    "MEDIDAS AGRARIAS",
    "MEDIDAS DE CAPACIDADE",
    "QUADRO DO TEMPO",
    "TABELLA",
)

LABEL_ALIASES = {
    "AGRICULTORES": "AGRICULTORES",
    "AGUAS SUPERFICIAIS": "AGUAS",
    "AGUAS": "AGUAS",
    "ARVORES FRUCTIFERAS": "ARVORES_FRUCTIFERAS",
    "ALIMENTACAO DA POPULACAO": "ALIMENTACAO_DA_POPULACAO",
    "CAMPOS E PASTOS": "CAMPOS_E_PASTOS",
    "CULTURAS": "CULTURAS",
    "COLHEITAS": "COLHEITAS",
    "CEREAES ETC": "CEREAES",
    "CEREAES": "CEREAES",
    "CANNA DE ASSUCAR": "CANNA",
    "CANNA E SEUS PRODUCTOS": "CANNA",
    "CANNA E SEUS PRODUTOS": "CANNA",
    "COOPERATIVAS": "COOPERATIVAS",
    "CALOR E FRIO": "CALOR_E_FRIO",
    "CHUVAS": "CHUVAS",
    "CONDICOES DE SAUDE DA POPULACAO": "CONDICOES_DE_SAUDE_DA_POPULACAO",
    "CONTABILIDADE": "CONTABILIDADE",
    "CRIACAO DO MUNICIPIO": "CRIACAO",
    "CRIACAO": "CRIACAO",
    "CUSTO DOS ANIMAES": "CUSTO_DOS_ANIMAES",
    "CUSTO DOS ANIMAIS": "CUSTO_DOS_ANIMAES",
    "CUSTO DOS TECIDOS": "CUSTO_DOS_TECIDOS",
    "ESTRADAS E PONTES": "ESTRADAS_E_PONTES",
    "EXPORTACAO E IMPORTACAO": "EXPORTACAO_E_IMPORTACAO",
    "ESCOLAS": "ESCOLAS",
    "FABRICAS": "FABRICAS",
    "FARINHA DE MANDIOCA E FEIJAO": "FARINHA_DE_MANDIOCA_E_FEIJAO",
    "FARINHA DE MANILIOCA E FEIJAO": "FARINHA_DE_MANDIOCA_E_FEIJAO",
    "HYPOTHECAS": "HYPOTHECAS",
    "HYYPOTHECAS": "HYPOTHECAS",
    "HABITACOES": "HABITACOES",
    "INSTRUMENTOS AGRICOLAS": "INSTRUMENTOS_AGRICOLAS",
    "JUROS": "JUROS",
    "MADEIRAS DE LEI": "MADEIRAS_DE_LEI",
    "MINAS": "MINAS",
    "MOLESTIAS DA POPULACAO": "MOLESTIAS_DA_POPULACAO",
    "NUCLEOS COLONIAIS": "NUCLEOS_COLONIAIS",
    "NUCLEOS COLONIAES": "NUCLEOS_COLONIAIS",
    "NUCLEOS COLONIALES": "NUCLEOS_COLONIAIS",
    "OPEROSIDADE DA POPULACAO": "OPEROSIDADE_DA_POPULACAO",
    "OPERODIADE DA POPULACAO": "OPEROSIDADE_DA_POPULACAO",
    "PADROES DE TERRAS BOAS": "PADROES_DE_TERRAS_BOAS",
    "PADROES DE TERRA BOA": "PADROES_DE_TERRAS_BOAS",
    "PADROES INDICANDO TERRA BOA": "PADROES_DE_TERRAS_BOAS",
    "PORTOS": "PORTOS",
    "SEMENTES": "SEMENTES",
    "SEMEADURA": "SEMEADURA",
    "SEMEADURAS": "SEMEADURA",
    "SYSTEMA DE TRABALHO DO PESSOAL AGRICOLA": "SYSTEMA DE TRABALHO",
    "SISTEMA DE TRABALHO DO PESSOAL AGRICOLA": "SYSTEMA DE TRABALHO",
    "SYSTEMA DE TRABALHO": "SYSTEMA DE TRABALHO",
    "SALARIOS": "SALARIOS",
    "SALARIO": "SALARIOS",
    "TERRAS": "TERRAS",
    "TERAS": "TERRAS",
    "TERRAS QUALIDADES": "TERRAS",
    "TERRAS PRECOS": "TERRAS",
    "TRANSPORTES": "TRANSPORTE",
    "TRANSPORTE": "TRANSPORTE",
    "CANHA DE ASSUCAR": "CANNA",
    "CANNA DE ASSINAR": "CANNA",
}

CANONICAL_COLUMNS = {re.sub(r"\s+", "_", value) for value in LABEL_ALIASES.values()}


def ascii_norm(text: str) -> str:
    text = text.replace("’", "'").replace("“", '"').replace("”", '"')
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def heading_text(line: str) -> str:
    line = re.sub(r"^#+\s*", "", line.strip())
    line = re.sub(r"^\|\s*", "", line)
    line = re.sub(r"\s*\|.*$", "", line)
    return line.strip(" #|-")


def norm_heading(line: str) -> str:
    return ascii_norm(heading_text(line)).upper()


def column_name(label: str) -> str:
    label = ascii_norm(label).upper()
    label = label.replace("'", "")
    label = re.sub(r"[^A-Z0-9]+", " ", label).strip()
    for source, target in sorted(LABEL_ALIASES.items(), key=lambda item: len(item[0]), reverse=True):
        if label == source or label.startswith(source + " "):
            label = target
            break
    label = LABEL_ALIASES.get(label, label)
    return re.sub(r"\s+", "_", label)


def is_noise(line: str) -> bool:
    s = line.strip()
    if not s or s.startswith("=== Page"):
        return True
    if re.fullmatch(r"[—\-.\d\sIVXLCDM]+", s):
        return True
    if s.startswith("!["):
        return True
    return False


def is_content_start(line: str) -> bool:
    normalized = norm_heading(line)
    return (
        line.strip().startswith("#")
        and "CONDICOES" in normalized
        and "AGRICULTURA" in normalized
        and "ESTADO" in normalized
    )


def is_stop_heading(line: str) -> bool:
    normalized = norm_heading(line)
    return any(normalized.startswith(stop) for stop in STOP_HEADINGS)


def is_candidate_municipio_heading(line: str) -> bool:
    stripped = line.strip()
    if not stripped.startswith("#"):
        return False
    text = heading_text(line)
    normalized = ascii_norm(text).upper()
    if not text or normalized in {"NOTA", "INDICE", "ADVERTENCIA"}:
        return False
    if is_content_start(line) or is_stop_heading(line):
        return False
    if any(word in normalized for word in ("MUNICIPIOS DO ESTADO", "RIO DE JANEIRO", "TYPOGRAPHIA")):
        return False
    if len(text) > 90:
        return False
    return True


def canonical_municipio_name(name: str) -> str:
    name = re.sub(r"\s+", " ", heading_text(name)).strip()
    name = re.sub(r"^Munic[ií]pio\s+(?:de|do|da|dos|das)\s+", "", name, flags=re.I)
    name = re.sub(r"^Munic[ií]pio\s+", "", name, flags=re.I)
    return name.rstrip(".")


def line_title_text(line: str) -> str:
    return canonical_municipio_name(line).strip("*_")


def has_agricultores_near(lines: list[str], idx: int, window: int = 10) -> bool:
    end = min(len(lines), idx + window + 1)
    for line in lines[idx + 1 : end]:
        normalized = ascii_norm(line).upper()
        if "AGRICULTORES" in normalized:
            return True
    return False


def clean_index_name(name: str) -> str:
    name = re.sub(r"\s+", " ", name).strip()
    name = re.sub(r"\s+PAGS?\.?.*$", "", name, flags=re.I)
    name = re.sub(r"\s+Inspec[cç].*$", "", name, flags=re.I)
    name = re.sub(r"\s+\d+\s*$", "", name)
    return name.strip(" .;:-|")


def extract_index_municipios(lines: list[str]) -> list[str]:
    try:
        index_start = next(i for i, line in enumerate(lines) if norm_heading(line) == "INDICE")
    except StopIteration:
        index_start = 0
    try:
        content_start = next(i for i, line in enumerate(lines) if is_content_start(line))
    except StopIteration:
        content_start = min(len(lines), index_start + 180)

    entries: list[tuple[int, str]] = []
    seen: set[str] = set()
    for line in lines[index_start:content_start]:
        stripped = line.strip()
        if "—" not in stripped and not re.search(r"^\|?\s*\d+\s+[A-Za-zÁÀÂÃÉÊÍÓÔÕÚÜÇ]", stripped):
            if not re.search(r"^\|?\s*\d+\s*\|", stripped):
                continue
        cells = [cell.strip() for cell in stripped.strip("|").split("|") if cell.strip()]
        if len(cells) >= 2 and cells[0].isdigit():
            number = int(cells[0])
            if "(*)" in cells[1] or "(**)" in cells[1]:
                continue
            name = clean_index_name(cells[1])
            if name and not name.isdigit() and number >= 1:
                key = ascii_norm(name).upper()
                if key not in seen:
                    seen.add(key)
                    entries.append((number, name))
            continue
        candidates = cells if cells else [stripped]
        for cell in candidates:
            match = re.match(r"^\s*(\d+)\s*(?:[—-]\s*)?(.+?)\s*$", cell)
            if not match:
                continue
            number = int(match.group(1))
            if "(*)" in match.group(2) or "(**)" in match.group(2):
                continue
            name = clean_index_name(match.group(2))
            if not name or name.isdigit() or number < 1:
                continue
            key = ascii_norm(name).upper()
            if key in seen:
                continue
            seen.add(key)
            entries.append((number, name))
    entries.sort(key=lambda item: item[0])
    return [name for _, name in entries]


def comparable_name(name: str) -> str:
    name = ascii_norm(name).upper()
    name = re.sub(r"\([^)]*\)", "", name)
    if name == "ITO":
        name = "ITU"
    name = name.replace("MUNICIPIO DE ", "")
    name = name.replace("MUNICIPIO DO ", "")
    name = name.replace("MUNICIPIO DA ", "")
    name = name.replace("MUNICIPIO DOS ", "")
    name = name.replace("MUNICIPIO DAS ", "")
    name = name.replace("S.", "SAO")
    name = name.replace("S ", "SAO ")
    name = name.replace("SANTO ", "SAO ")
    name = re.sub(r"[^A-Z0-9]+", "", name)
    return name


def heading_matches_index(heading: str, index_name: str) -> bool:
    h = comparable_name(heading)
    n = comparable_name(index_name)
    if not h or not n:
        return False
    if h == n:
        return True
    if len(h) >= 5 and len(n) >= 5 and (h in n or n in h):
        return True
    if len(h) >= 5 and len(n) >= 5 and h[0] == n[0]:
        return difflib.SequenceMatcher(None, h, n).ratio() >= 0.72
    return False


def content_heading_positions(lines: list[str], content_start: int) -> list[tuple[str, int]]:
    positions: list[tuple[str, int]] = []
    for idx in range(content_start + 1, len(lines)):
        line = lines[idx]
        if is_stop_heading(line):
            break
        stripped = line.strip()
        if is_candidate_municipio_heading(line):
            name = canonical_municipio_name(line)
        elif (
            stripped
            and not is_noise(line)
            and not stripped.startswith(("-", "*", '"', "“", "|"))
            and "—" not in stripped
            and len(stripped) <= 90
            and not re.search(r"\d", stripped)
            and not re.search(r"[.;:]$", stripped)
        ):
            name = line_title_text(line)
            normalized = ascii_norm(name).upper()
            if normalized in {"NOTA", "ATTENCAO", "ADVERTENCIA"}:
                continue
        else:
            continue

        if not has_agricultores_near(lines, idx):
            continue
        positions.append((name, idx))
    return positions


def find_municipio_positions(lines: list[str]) -> list[tuple[str, int]]:
    try:
        content_start = next(i for i, line in enumerate(lines) if is_content_start(line))
    except StopIteration:
        content_start = 0

    index_names = extract_index_municipios(lines)
    heading_positions = content_heading_positions(lines, content_start)
    if index_names and heading_positions:
        positions: list[tuple[str, int]] = []
        cursor = 0
        for index_name in index_names:
            found_at = None
            for pos_idx in range(cursor, len(heading_positions)):
                heading, line_idx = heading_positions[pos_idx]
                if heading_matches_index(heading, index_name):
                    found_at = pos_idx
                    positions.append((heading, line_idx))
                    break
            if found_at is not None:
                cursor = found_at + 1
        if len(positions) >= max(1, int(len(index_names) * 0.6)):
            return positions

    if heading_positions:
        return heading_positions
    raise RuntimeError("Could not infer municipality headings from OCR text")


def maybe_section(line: str) -> tuple[str, str] | None:
    if is_noise(line):
        return None

    original = line.strip()
    if re.match(r"""^[-*"']""", original):
        return None

    stripped = original.replace("—", " - ")
    stripped = re.sub(r"^CRIAÇÃO\s*-\s*Custo", "CRIAÇÃO Custo", stripped)

    first_word = re.match(r"^([A-Za-zÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç]+)", stripped)
    if not first_word:
        return None
    if len(first_word.group(1)) < 2 or not first_word.group(1).isupper():
        return None

    match = re.match(r"^([A-ZÁÀÂÃÉÊÍÓÔÕÚÜÇ][A-Za-zÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç' .º0-9()/-]{1,80}?)\s+-\s+(.*)$", stripped)
    if not match:
        return None

    label, body = match.groups()
    clean_label = label.strip(" .:-")
    upper_ratio_chars = [ch for ch in clean_label if ch.isalpha()]
    if not upper_ratio_chars:
        return None

    normalized = ascii_norm(clean_label)
    col = column_name(clean_label)
    if col in CANONICAL_COLUMNS:
        return col, body.strip()

    return col, body.strip()


def is_header_label(label: str) -> bool:
    clean_label = label.strip(" .:-")
    first_word = re.match(r"^([A-Za-zÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç]+)", clean_label)
    if not first_word:
        return False
    if len(first_word.group(1)) < 2 or not first_word.group(1).isupper():
        return False
    return column_name(clean_label) in CANONICAL_COLUMNS


def split_sections(line: str) -> list[tuple[str | None, str]]:
    """Split one OCR line when Mistral joined multiple uppercase headers."""

    if is_noise(line):
        return []

    original = line.strip()
    if re.match(r"""^[-*"']""", original):
        return [(None, original)]

    stripped = original.replace("—", " - ")
    stripped = re.sub(r"^CRIAÇÃO\s*-\s*Custo", "CRIAÇÃO Custo", stripped)
    matches = []
    pattern = re.compile(
        r"(?<!\w)([A-ZÁÀÂÃÉÊÍÓÔÕÚÜÇ][A-Za-zÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç' .º0-9(),/-]{1,80}?)\s+-\s+"
    )
    for match in pattern.finditer(stripped):
        label = match.group(1)
        if is_header_label(label):
            matches.append(match)

    if not matches:
        return [(None, original)]

    sections: list[tuple[str | None, str]] = []
    if matches[0].start() > 0:
        sections.append((None, stripped[: matches[0].start()].strip()))

    for idx, match in enumerate(matches):
        next_start = matches[idx + 1].start() if idx + 1 < len(matches) else len(stripped)
        col = column_name(match.group(1))
        body = stripped[match.end() : next_start].strip()
        sections.append((col, body))
    return sections


def append_value(row: OrderedDict[str, str], col: str, text: str) -> None:
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return
    if row.get(col):
        row[col] = f"{row[col]} {text}"
    else:
        row[col] = text


def parse_block(block: list[str]) -> OrderedDict[str, str]:
    row: OrderedDict[str, str] = OrderedDict()
    current_col = "PREFACE"

    for line in block:
        if is_noise(line):
            continue
        normalized_heading = norm_heading(line)
        if any(normalized_heading.startswith(stop) for stop in STOP_HEADINGS):
            break
        if normalized_heading == "NOTA":
            current_col = "NOTA"
            continue

        for col, body in split_sections(line):
            if col:
                current_col = col
            append_value(row, current_col, body)

    row.pop("PREFACE", None)
    return row


def parse(raw_text: str) -> list[OrderedDict[str, str]]:
    lines = raw_text.splitlines()
    positions = find_municipio_positions(lines)
    rows: list[OrderedDict[str, str]] = []
    for i, (municipio, start) in enumerate(positions):
        end = positions[i + 1][1] if i + 1 < len(positions) else len(lines)
        row: OrderedDict[str, str] = OrderedDict()
        row["municipio"] = municipio
        row.update(parse_block(lines[start + 1 : end]))
        rows.append(row)
    return rows


def fieldnames(rows: list[OrderedDict[str, str]]) -> list[str]:
    cols = ["municipio"]
    seen = set(cols)
    for row in rows:
        for col in row:
            if col not in seen:
                seen.add(col)
                cols.append(col)
    return cols


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-text", required=True, type=Path)
    parser.add_argument("--csv-out", required=True, type=Path)
    args = parser.parse_args()

    rows = parse(args.raw_text.read_text(encoding="utf-8"))
    cols = fieldnames(rows)

    args.csv_out.parent.mkdir(parents=True, exist_ok=True)
    with args.csv_out.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=cols, delimiter=";", quoting=csv.QUOTE_ALL)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)

    print(f"Wrote {len(rows)} rows and {len(cols)} columns to {args.csv_out}")
    for required in ("JUROS", "SALARIOS", "TERRAS", "TRANSPORTE"):
        empty = [row["municipio"] for row in rows if not row.get(required)]
        print(f"{required}: {len(empty)} empty")
        if empty:
            print("  " + ", ".join(empty))


if __name__ == "__main__":
    main()
