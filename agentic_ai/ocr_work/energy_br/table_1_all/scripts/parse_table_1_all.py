#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import re
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OCR_JSON = ROOT / "mistral_outputs" / "table_1_all_mistral_raw.json"
CSV_DIR = ROOT / "csv"


STATE_ALIASES = [
    ("Alagoas", ["ALAGOAS", "ALAGOAS", "ALAGO"]),
    ("Amazonas", ["AMAZONAS"]),
    ("Bahia", ["BAHIA", "BABIA"]),
    ("Ceará", ["CEARA"]),
    ("Districto Federal", ["DISTRICTO FEDERAL", "DISTRITO FEDERAL", "FEDERAL"]),
    ("Espírito Santo", ["ESPIRITO SANTO", "PIRITO SANTO"]),
    ("Goyaz", ["GOYAZ", "GOIAS"]),
    ("Maranhão", ["MARANHAO"]),
    ("Matto Grosso", ["MATTO GROSSO", "MATO GROSSO"]),
    ("Minas Geraes", ["MINAS GERAES", "MINAS GERAIS"]),
    ("Pará", ["PARA"]),
    ("Parahyba", ["PARAHYBA", "PARAIBA", "PARATYBA"]),
    ("Paraná", ["PARANA"]),
    ("Pernambuco", ["PERNAMBUCO"]),
    ("Piauhy", ["PIAUHY", "PIAUI"]),
    ("Rio de Janeiro", ["RIO DE JANEIRO", "IIO DE JANEIRO"]),
    ("Rio Grande do Norte", ["RIO GRANDE DO NORTE", "GRANDE DO NORTE"]),
    ("Rio Grande do Sul", ["RIO GRANDE DO SUL", "GRANDE DO SUL"]),
    ("Santa Catharina", ["SANTA CATHARINA", "SANTA CATARINA"]),
    ("São Paulo", ["SAO PAULO", "SAN PAULO", "S. PAULO"]),
    ("Sergipe", ["SERGIPE"]),
    ("Território do Acre", ["ACRE"]),
]


UNION_COLUMNS = [
    "source_file",
    "section",
    "spread_index",
    "left_page",
    "right_page",
    "left_table_id",
    "right_table_id",
    "pair_record_index",
    "right_subrow_index",
    "alignment_status",
    "state",
    "company",
    "municipality",
    "plant",
    "installation_year",
    "energy_source",
    "primary_motor_type",
    "primary_motor_number",
    "primary_motor_hp",
    "transmission_line_km",
    "distribution_line_km",
    "transmission_voltage",
    "distribution_voltage",
    "current_type",
    "phases",
    "cycles",
    "transformer_stations",
    "personnel",
    "municipality_plant_location",
    "electrical_installation_capacity_hp",
    "total_waterfall_capacity_hp",
    "waterfall_height_m",
    "extension_m",
    "adduction_material",
    "pipe_diameter_mm",
    "pipe_thickness_mm",
    "watercourse_used",
    "reservoir_capacity_m3",
    "raw_left_cells_json",
    "raw_right_cells_json",
]


def strip_accents(value: str) -> str:
    return "".join(
        ch for ch in unicodedata.normalize("NFKD", value) if not unicodedata.combining(ch)
    )


def norm_text(value: str) -> str:
    value = strip_accents(value).upper()
    value = re.sub(r"[^A-Z0-9 .-]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def infer_state(value: str) -> str:
    text = norm_text(value)
    for state, aliases in STATE_ALIASES:
        for alias in aliases:
            alias_n = norm_text(alias)
            if alias_n and re.search(rf"(^| )({re.escape(alias_n)})( |$)", text):
                return state
    return ""


def infer_state_from_context(value: str) -> str:
    candidates = []
    for raw_line in value.splitlines():
        line = raw_line.strip().strip("#").strip()
        if not line or len(line) > 70:
            continue
        if line.startswith("("):
            continue
        norm = norm_text(line)
        if "COMPANHIA" in norm or "EMPRESA" in norm or "MUNICIPALIDADE" in norm:
            continue
        candidates.append(line)
    return infer_state(" ".join(candidates))


def clean(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def clean_num(value: str) -> str:
    value = clean(value)
    if value in {"", "—", "-", "–"}:
        return value
    return value.replace(".", "").replace(" ", "")


def parse_md_table(content: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for line in content.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if all(re.fullmatch(r":?-+:?", c or "-") for c in cells):
            continue
        rows.append(cells)
    return rows


def table_contexts(page: dict) -> dict[str, str]:
    md = page.get("markdown", "")
    matches = list(re.finditer(r"\[(tbl-\d+\.md)\]\(tbl-\d+\.md\)", md))
    contexts: dict[str, str] = {}
    previous_end = 0
    for match in matches:
        contexts[match.group(1)] = md[previous_end : match.start()]
        previous_end = match.end()
    return contexts


def is_headerish(row: list[str]) -> bool:
    text = norm_text(" ".join(row))
    tokens = [
        "DENOMINACAO DAS EMPRESAS",
        "DENOMINATION DES ENTREPRISES",
        "NATUREZA DA FORCA",
        "NATURE DE LA FORCE",
        "MOTORES PRIMARIOS",
        "MOTEURS PRIMAIRES",
        "MOTRURS PRIMAIRES",
        "MOTEUNS PRIMAIRES",
        "TIPO DO APPARELHO",
        "TYPE DE",
        "TYPO DO",
        "NUMERO NOMBRE",
        "NUMERO NOM",
        "NOMBRE",
        "POTENCIA",
        "PO TENCIA",
        "FORCE H",
        "ENCANAMENTOS ADDUCTORES",
        "CONDUITES D ADDUCTION",
        "NATUREZA DO MATERIAL",
        "NATURE DU MATERIEL",
        "DIAMETRO DOS TUBOS",
        "DIAMETRE",
        "EPAISSEUR",
    ]
    return any(token in text for token in tokens)


def is_state_label(row: list[str]) -> bool:
    first = norm_text(row[0]) if row else ""
    if not first.startswith(("ESTADO", "DISTRICT")):
        return False
    return all(not clean(c) for c in row[1:])


def is_blank(row: list[str]) -> bool:
    return all(not clean(c) for c in row)


def pad(row: list[str], width: int) -> list[str]:
    if len(row) >= width:
        return row[:width]
    return row + [""] * (width - len(row))


def left_tables(page: dict, section: str) -> list[dict]:
    wanted = 4 if section == "section_i" else 7
    alt_wanted = {6} if section == "section_ii" else set()
    result = []
    for table in page.get("tables") or []:
        records = []
        for row in parse_md_table(table["content"]):
            if len(row) not in {wanted, *alt_wanted}:
                continue
            if is_blank(row) or is_headerish(row) or is_state_label(row):
                continue
            records.append(pad(row, wanted))
        if records:
            result.append({"id": table["id"], "records": records})
    return result


def right_tables(page: dict, section: str) -> list[dict]:
    wanted = 13 if section == "section_i" else 10
    result = []
    for table in page.get("tables") or []:
        groups: list[list[list[str]]] = []
        for row in parse_md_table(table["content"]):
            if len(row) not in {wanted, wanted - 1, wanted - 2}:
                continue
            row = pad(row, wanted)
            if is_blank(row) or is_headerish(row) or is_state_label(row):
                continue
            if section == "section_i":
                if row[0] or not groups:
                    groups.append([row])
                else:
                    groups[-1].append(row)
            else:
                # The right half of section II is already one physical record per row.
                groups.append([row])
        if groups:
            result.append({"id": table["id"], "groups": groups})
    return result


def state_context_for_pages(pages: list[dict]) -> dict[tuple[int, str], str]:
    contexts: dict[tuple[int, str], str] = {}
    for page in pages:
        page_no = page["index"] + 1
        for table_id, ctx in table_contexts(page).items():
            state = infer_state_from_context(ctx)
            if state:
                contexts[(page_no, table_id)] = state
    return contexts


def spread_state_for_table(
    left_page_no: int,
    right_page_no: int,
    left_index: int,
    left_id: str,
    right_id: str,
    state_context: dict[tuple[int, str], str],
    prior_state: str,
) -> str:
    state = state_context.get((right_page_no, right_id), "")
    if not state:
        state = state_context.get((left_page_no, left_id), "")
    if not state and left_index == 0:
        state = prior_state
    return state or prior_state


def empty_row(section: str) -> dict:
    return {col: "" for col in UNION_COLUMNS} | {
        "source_file": "table_1_all.pdf",
        "section": section,
    }


def section_i_row(
    base: dict,
    left: list[str] | None,
    right: list[str] | None,
) -> dict:
    row = dict(base)
    if left:
        row.update(
            {
                "company": clean(left[0]),
                "municipality": clean(left[1]),
                "plant": clean(left[2]),
                "installation_year": clean_num(left[3]),
                "raw_left_cells_json": json.dumps(left, ensure_ascii=False),
            }
        )
    if right:
        row.update(
            {
                "energy_source": clean(right[0]),
                "primary_motor_type": clean(right[1]),
                "primary_motor_number": clean_num(right[2]),
                "primary_motor_hp": clean_num(right[3]),
                "transmission_line_km": clean_num(right[4]),
                "distribution_line_km": clean_num(right[5]),
                "transmission_voltage": clean_num(right[6]),
                "distribution_voltage": clean_num(right[7]),
                "current_type": clean(right[8]),
                "phases": clean_num(right[9]),
                "cycles": clean_num(right[10]),
                "transformer_stations": clean_num(right[11]),
                "personnel": clean_num(right[12]),
                "raw_right_cells_json": json.dumps(right, ensure_ascii=False),
            }
        )
    return row


def section_ii_row(
    base: dict,
    left: list[str] | None,
    right: list[str] | None,
) -> dict:
    row = dict(base)
    if left:
        row.update(
            {
                "company": clean(left[0]),
                "municipality_plant_location": clean(left[1]),
                "plant": clean(left[2]),
                "electrical_installation_capacity_hp": clean_num(left[3]),
                "total_waterfall_capacity_hp": clean_num(left[4]),
                "waterfall_height_m": clean_num(left[5]),
                "extension_m": clean_num(left[6]),
                "raw_left_cells_json": json.dumps(left, ensure_ascii=False),
            }
        )
    if right:
        row.update(
            {
                "adduction_material": clean(right[0]),
                "pipe_diameter_mm": clean_num(right[1]),
                "pipe_thickness_mm": clean_num(right[2]),
                "transmission_line_km": clean_num(right[3]),
                "distribution_line_km": clean_num(right[4]),
                "transmission_voltage": clean_num(right[5]),
                "distribution_voltage": clean_num(right[6]),
                "transformer_stations": clean_num(right[7]),
                "watercourse_used": clean(right[8]),
                "reservoir_capacity_m3": clean_num(right[9]),
                "raw_right_cells_json": json.dumps(right, ensure_ascii=False),
            }
        )
    return row


def combine_spreads(pages: list[dict], section: str, start_page: int, end_page: int) -> tuple[list[dict], list[str]]:
    state_context = state_context_for_pages(pages)
    rows: list[dict] = []
    diagnostics: list[str] = []
    prior_state = ""
    spread_index = 0
    for page_no in range(start_page, end_page + 1, 2):
        spread_index += 1
        left_page = pages[page_no - 1]
        right_page = pages[page_no]
        ltables = left_tables(left_page, section)
        rtables = right_tables(right_page, section)
        max_tables = max(len(ltables), len(rtables))
        diagnostics.append(
            f"spread {page_no}-{page_no + 1}: left_tables={len(ltables)} right_tables={len(rtables)}"
        )
        pair_record_index = 0
        if section == "section_ii" or len(ltables) != len(rtables):
            left_flat = []
            for table_idx, ltable in enumerate(ltables):
                table_state = state_context.get((page_no, ltable["id"]), "")
                if section != "section_ii":
                    table_state = table_state or prior_state
                if table_state:
                    prior_state = table_state
                for record in ltable["records"]:
                    left_flat.append((ltable["id"], table_state, record))
            right_flat = []
            for table_idx, rtable in enumerate(rtables):
                table_state = state_context.get((page_no + 1, rtable["id"]), "") or prior_state
                if table_state:
                    prior_state = table_state
                for group in rtable["groups"]:
                    right_flat.append((rtable["id"], table_state, group))
            max_records = max(len(left_flat), len(right_flat))
            if len(left_flat) != len(right_flat):
                diagnostics.append(
                    f"  spread_order_pairing: left_records={len(left_flat)} right_groups={len(right_flat)}"
                )
            for rec_idx in range(max_records):
                pair_record_index += 1
                left_item = left_flat[rec_idx] if rec_idx < len(left_flat) else ("", prior_state, None)
                right_item = right_flat[rec_idx] if rec_idx < len(right_flat) else ("", prior_state, [])
                left_id, left_state, left = left_item
                right_id, right_state, group = right_item
                if section == "section_ii":
                    state = right_state or left_state or prior_state
                else:
                    state = left_state or right_state or prior_state
                if state:
                    prior_state = state
                if left and group:
                    status = "matched"
                elif left:
                    status = "left_only"
                else:
                    status = "right_only"
                if not group:
                    group = [None]
                for sub_idx, right in enumerate(group, 1):
                    base = empty_row(section)
                    base.update(
                        {
                            "spread_index": spread_index,
                            "left_page": page_no,
                            "right_page": page_no + 1,
                            "left_table_id": left_id,
                            "right_table_id": right_id,
                            "pair_record_index": pair_record_index,
                            "right_subrow_index": sub_idx,
                            "alignment_status": status,
                            "state": state,
                        }
                    )
                    if section == "section_i":
                        rows.append(section_i_row(base, left, right))
                    else:
                        rows.append(section_ii_row(base, left, right))
            continue
        for table_idx in range(max_tables):
            ltable = ltables[table_idx] if table_idx < len(ltables) else {"id": "", "records": []}
            rtable = rtables[table_idx] if table_idx < len(rtables) else {"id": "", "groups": []}
            state = spread_state_for_table(
                page_no,
                page_no + 1,
                table_idx,
                ltable["id"],
                rtable["id"],
                state_context,
                prior_state,
            )
            if state:
                prior_state = state
            left_records = ltable["records"]
            right_groups = rtable["groups"]
            max_records = max(len(left_records), len(right_groups))
            if len(left_records) != len(right_groups):
                diagnostics.append(
                    f"  table_pair {ltable['id'] or '<none>'}/{rtable['id'] or '<none>'}: "
                    f"left_records={len(left_records)} right_groups={len(right_groups)}"
                )
            for rec_idx in range(max_records):
                pair_record_index += 1
                left = left_records[rec_idx] if rec_idx < len(left_records) else None
                group = right_groups[rec_idx] if rec_idx < len(right_groups) else []
                if left and group:
                    status = "matched"
                elif left:
                    status = "left_only"
                else:
                    status = "right_only"
                if not group:
                    group = [None]
                for sub_idx, right in enumerate(group, 1):
                    base = empty_row(section)
                    base.update(
                        {
                            "spread_index": spread_index,
                            "left_page": page_no,
                            "right_page": page_no + 1,
                            "left_table_id": ltable["id"],
                            "right_table_id": rtable["id"],
                            "pair_record_index": pair_record_index,
                            "right_subrow_index": sub_idx,
                            "alignment_status": status,
                            "state": state,
                        }
                    )
                    if section == "section_i":
                        rows.append(section_i_row(base, left, right))
                    else:
                        rows.append(section_ii_row(base, left, right))
    return rows, diagnostics


def write_csv(path: Path, rows: list[dict], fieldnames: list[str] = UNION_COLUMNS) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    data = json.loads(OCR_JSON.read_text(encoding="utf-8"))
    pages = data["raw_response"]["pages"]
    section_i, diag_i = combine_spreads(pages, "section_i", 1, 32)
    section_ii, diag_ii = combine_spreads(pages, "section_ii", 33, 58)
    combined = section_i + section_ii

    write_csv(CSV_DIR / "table_1_all_combined_wide.csv", combined)
    write_csv(CSV_DIR / "table_1_all_section_i_technical_conditions_wide.csv", section_i)
    write_csv(CSV_DIR / "table_1_all_section_ii_hydraulic_characteristics_wide.csv", section_ii)

    report = [
        "table_1_all parse report",
        f"source_pdf: /Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared/energy_br/table_1_all.pdf",
        f"ocr_json: {OCR_JSON}",
        f"csv_dir: {CSV_DIR}",
        f"pages_processed: {len(pages)}",
        f"section_i_rows: {len(section_i)}",
        f"section_ii_rows: {len(section_ii)}",
        f"combined_rows: {len(combined)}",
        "",
        "alignment_status_counts:",
    ]
    for status in sorted({r["alignment_status"] for r in combined}):
        report.append(f"- {status}: {sum(1 for r in combined if r['alignment_status'] == status)}")
    report.extend(["", "diagnostics:", *diag_i, *diag_ii])
    (ROOT / "table_1_all_parse_report.txt").write_text("\n".join(report) + "\n", encoding="utf-8")
    print("\n".join(report[:20]))


if __name__ == "__main__":
    main()
