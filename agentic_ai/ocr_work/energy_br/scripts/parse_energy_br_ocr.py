#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import re
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OCR_DIR = ROOT / "mistral_outputs"
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
    if not text:
        return ""
    for state, aliases in STATE_ALIASES:
        for alias in aliases:
            alias_n = norm_text(alias)
            if alias_n and re.search(rf"(^| )({re.escape(alias_n)})( |$)", text):
                return state
    return ""


def load_json(stem: str) -> dict:
    return json.loads((OCR_DIR / f"{stem}_mistral_raw.json").read_text(encoding="utf-8"))


def parse_md_table(content: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for line in content.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells:
            continue
        if all(re.fullmatch(r":?-+:?", c or "-") for c in cells):
            continue
        rows.append(cells)
    return rows


def clean_value(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def normalized_number(value: str) -> str:
    value = clean_value(value)
    if value in {"", "—", "-", "»", "» »"}:
        return value
    return value.replace(".", "").replace(" ", "")


def footnotes(value: str) -> str:
    return ";".join(re.findall(r"\((\d+)\)", value))


def clean_label(value: str) -> str:
    return re.sub(r"\(\d+\)", "", clean_value(value)).strip()


def is_headerish(cells: list[str]) -> bool:
    joined = norm_text(" ".join(cells))
    header_tokens = [
        "DENOMINACAO",
        "MUNICIPIOS",
        "MUNICIPES",
        "NATUREZA",
        "MOTORES",
        "ENCANAMENTOS",
        "ILLUMINACAO PUBLICA",
        "LAMPADAS",
        "NUMERO DE POSTES",
        "DESPESA ANNUAL",
        "CATEGORIA DO MUNICIPIO",
        "NOMBRE",
        "POUVOIR",
        "BOUGIES",
    ]
    return any(tok in joined for tok in header_tokens)


def is_empty_or_header_row(cells: list[str]) -> bool:
    return all(not c for c in cells) or is_headerish(cells)


def table_contexts(page: dict) -> dict[str, str]:
    md = page.get("markdown", "")
    matches = list(re.finditer(r"\[(tbl-\d+\.md)\]\(tbl-\d+\.md\)", md))
    contexts: dict[str, str] = {}
    previous_end = 0
    for match in matches:
        context = md[previous_end : match.start()]
        contexts[match.group(1)] = context
        previous_end = match.end()
    return contexts


def data_tables(page: dict, min_cols: int | None = None, max_cols: int | None = None) -> list[dict]:
    result = []
    for table in page.get("tables") or []:
        rows = parse_md_table(table["content"])
        if not rows:
            continue
        cols = len(rows[0])
        if min_cols is not None and cols < min_cols:
            continue
        if max_cols is not None and cols > max_cols:
            continue
        result.append(table)
    return result


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def parse_tables_1_2() -> dict[str, int]:
    data = load_json("tables_1_2")
    regional_rows: list[dict] = []
    large_rows: list[dict] = []

    table0 = data["raw_response"]["pages"][0]["tables"][0]
    for row in parse_md_table(table0["content"])[4:]:
        if len(row) < 10:
            continue
        regional_rows.append(
            {
                "source_file": "tables_1_2.pdf",
                "page": 1,
                "source_table_id": table0["id"],
                "state": clean_label(row[0]),
                "total_number": normalized_number(row[1]),
                "total_hp": normalized_number(row[2]),
                "until_1890_number": normalized_number(row[3]),
                "until_1890_hp": normalized_number(row[4]),
                "1891_1900_number": normalized_number(row[5]),
                "1891_1900_hp": normalized_number(row[6]),
                "1901_1910_number": normalized_number(row[7]),
                "1901_1910_hp": normalized_number(row[8]),
                "1911_1920_number": normalized_number(row[9]),
                "1911_1920_hp": "",
                "note": "OCR table did not expose the final 1911-1920 HP column",
            }
        )

    current_year = ""
    previous_state = ""
    previous_municipality = ""
    for page in data["raw_response"]["pages"]:
        for table in page.get("tables") or []:
            rows = parse_md_table(table["content"])
            for row in rows:
                if len(row) != 5 or is_empty_or_header_row(row):
                    continue
                if norm_text(row[0]).startswith("ANNO DE"):
                    current_year = re.sub(r"\D+", "", row[0])
                    continue
                if not row[0] or all(not c for c in row[1:]):
                    continue
                state = clean_label(row[2])
                municipality = clean_label(row[3])
                state_inferred = "no"
                municipality_inferred = "no"
                if state in {"»", "» »", "—", ""}:
                    state = previous_state
                    state_inferred = "yes"
                if municipality in {"»", "» »", ""}:
                    municipality = previous_municipality
                    municipality_inferred = "yes"
                if state:
                    previous_state = state
                if municipality and municipality != "—":
                    previous_municipality = municipality
                large_rows.append(
                    {
                        "source_file": "tables_1_2.pdf",
                        "page": page["index"] + 1,
                        "source_table_id": table["id"],
                        "year": current_year,
                        "company": clean_label(row[0]),
                        "plant": clean_label(row[1]),
                        "state": state,
                        "state_inferred_from_ditto": state_inferred,
                        "municipality": municipality,
                        "municipality_inferred_from_ditto": municipality_inferred,
                        "power_hp": normalized_number(row[4]),
                        "footnotes": ";".join(n for n in [footnotes(row[0]), footnotes(row[1])] if n),
                    }
                )

    write_csv(
        CSV_DIR / "tables_1_2_regional_foundation_distribution.csv",
        regional_rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "state",
            "total_number",
            "total_hp",
            "until_1890_number",
            "until_1890_hp",
            "1891_1900_number",
            "1891_1900_hp",
            "1901_1910_number",
            "1901_1910_hp",
            "1911_1920_number",
            "1911_1920_hp",
            "note",
        ],
    )
    write_csv(
        CSV_DIR / "tables_1_2_large_plants_over_1000hp.csv",
        large_rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "year",
            "company",
            "plant",
            "state",
            "state_inferred_from_ditto",
            "municipality",
            "municipality_inferred_from_ditto",
            "power_hp",
            "footnotes",
        ],
    )
    return {"regional_distribution": len(regional_rows), "large_plants": len(large_rows)}


def parse_table_3() -> int:
    data = load_json("table_3")
    table = data["raw_response"]["pages"][0]["tables"][0]
    rows = []
    for row in parse_md_table(table["content"])[3:]:
        if len(row) != 8:
            continue
        category_sum = sum(
            0 if normalized_number(row[i]) in {"—", "-", ""} else int(normalized_number(clean_label(row[i])))
            for i in range(1, 6)
        )
        total = 0 if normalized_number(row[6]) in {"—", "-", ""} else int(normalized_number(row[6]))
        rows.append(
            {
                "source_file": "table_3.png",
                "page": 1,
                "source_table_id": table["id"],
                "state": clean_label(row[0]),
                "exclusively_electric": normalized_number(row[1]),
                "exclusively_kerosene": normalized_number(row[2]),
                "exclusively_acetylene": normalized_number(row[3]),
                "exclusively_alcohol": normalized_number(row[4]),
                "more_than_one_system": normalized_number(clean_label(row[5])),
                "total_with_lighting": normalized_number(row[6]),
                "without_lighting": normalized_number(row[7]),
                "footnotes": footnotes(row[5]),
                "validation_note": ""
                if category_sum == total
                else f"category_sum_{category_sum}_differs_from_printed_total_{total}",
            }
        )
    write_csv(
        CSV_DIR / "table_3_city_lighting_system.csv",
        rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "state",
            "exclusively_electric",
            "exclusively_kerosene",
            "exclusively_acetylene",
            "exclusively_alcohol",
            "more_than_one_system",
            "total_with_lighting",
            "without_lighting",
            "footnotes",
            "validation_note",
        ],
    )
    return len(rows)


def section_for_page(page_no: int) -> str:
    if page_no <= 32:
        return "I_principaes_condicoes_technicas"
    if page_no <= 58:
        return "II_principaes_caracteristicos"
    if page_no <= 61:
        return "photos_or_divider"
    if page_no <= 92:
        return "illuminacao_I_informacoes_geraes"
    if page_no <= 97:
        return "illuminacao_II_kerozene"
    if page_no <= 99:
        return "illuminacao_III_IV_acetyleno_alcool"
    return "illuminacao_V_electrica"


def state_context_for_all_tables(data: dict) -> dict[tuple[int, str], str]:
    contexts: dict[tuple[int, str], str] = {}
    pages = data["raw_response"]["pages"]
    for page in pages:
        page_no = page["index"] + 1
        for table_id, ctx in table_contexts(page).items():
            state = infer_state(ctx)
            if state:
                contexts[(page_no, table_id)] = state

    # In section I, identity pages and technical pages alternate. The clearer
    # state labels often appear on the technical page, so map those labels back
    # onto the preceding identity page by table order.
    for page in pages:
        page_no = page["index"] + 1
        if page_no > 32 or page_no % 2 != 1:
            continue
        if page_no >= len(pages):
            continue
        next_page = pages[page_no]
        next_states = []
        for table in data_tables(next_page):
            state = contexts.get((page_no + 1, table["id"]), "")
            rows = parse_md_table(table["content"])
            if rows and len(rows[0]) == 13 and state:
                next_states.append(state)
        identity_tables = []
        for table in data_tables(page):
            rows = parse_md_table(table["content"])
            has_data = any(len(row) == 4 and not is_empty_or_header_row(row) for row in rows)
            if rows and len(rows[0]) == 4 and has_data:
                identity_tables.append(table)
        for table, state in zip(identity_tables, next_states):
            contexts.setdefault((page_no, table["id"]), state)
    return contexts


def parse_all_tables_raw(data: dict, state_context: dict[tuple[int, str], str]) -> int:
    rows = []
    for page in data["raw_response"]["pages"]:
        page_no = page["index"] + 1
        section = section_for_page(page_no)
        for table in page.get("tables") or []:
            state = state_context.get((page_no, table["id"]), "")
            for idx, cells in enumerate(parse_md_table(table["content"]), 1):
                rows.append(
                    {
                        "source_file": "all_tables.pdf",
                        "page": page_no,
                        "section": section,
                        "source_table_id": table["id"],
                        "row_in_table": idx,
                        "column_count": len(cells),
                        "state_context": state,
                        "first_cell": cells[0] if cells else "",
                        "cells_json": json.dumps(cells, ensure_ascii=False),
                    }
                )
    write_csv(
        CSV_DIR / "all_tables_raw_ocr_fragments.csv",
        rows,
        [
            "source_file",
            "page",
            "section",
            "source_table_id",
            "row_in_table",
            "column_count",
            "state_context",
            "first_cell",
            "cells_json",
        ],
    )
    return len(rows)


def parse_section_i(data: dict, state_context: dict[tuple[int, str], str]) -> dict[str, int]:
    identity_rows = []
    technical_rows = []
    current_identity_state = ""
    current_technical_state = ""
    for page in data["raw_response"]["pages"][:32]:
        page_no = page["index"] + 1
        for table in page.get("tables") or []:
            state = state_context.get((page_no, table["id"]), "")
            rows = parse_md_table(table["content"])
            for row_idx, row in enumerate(rows, 1):
                if len(row) == 4 and not is_empty_or_header_row(row):
                    row_state = infer_state(row[0])
                    if row_state and all(not c for c in row[1:]):
                        current_identity_state = row_state
                        continue
                    effective_state = state or current_identity_state
                    if effective_state:
                        current_identity_state = effective_state
                    identity_rows.append(
                        {
                            "source_file": "all_tables.pdf",
                            "page": page_no,
                            "source_table_id": table["id"],
                            "row_in_table": row_idx,
                            "state": effective_state,
                            "company": clean_label(row[0]),
                            "municipality": clean_label(row[1]),
                            "plant": clean_label(row[2]),
                            "installation_year": normalized_number(row[3]),
                        }
                    )
                elif len(row) == 13 and not is_empty_or_header_row(row):
                    effective_state = state or current_technical_state
                    if effective_state:
                        current_technical_state = effective_state
                    technical_rows.append(
                        {
                            "source_file": "all_tables.pdf",
                            "page": page_no,
                            "source_table_id": table["id"],
                            "row_in_table": row_idx,
                            "state": effective_state,
                            "row_type": "continuation" if not row[0] else "data",
                            "energy_source": clean_label(row[0]),
                            "primary_motor_type": clean_label(row[1]),
                            "primary_motor_number": normalized_number(row[2]),
                            "primary_motor_hp": normalized_number(row[3]),
                            "transmission_line_km": normalized_number(row[4]),
                            "distribution_line_km": normalized_number(row[5]),
                            "transmission_voltage": normalized_number(row[6]),
                            "distribution_voltage": normalized_number(row[7]),
                            "current_type": clean_label(row[8]),
                            "phases": normalized_number(row[9]),
                            "cycles": normalized_number(row[10]),
                            "transformer_stations": normalized_number(row[11]),
                            "personnel": normalized_number(row[12]),
                        }
                    )
    write_csv(
        CSV_DIR / "all_tables_section_i_company_identity.csv",
        identity_rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "row_in_table",
            "state",
            "company",
            "municipality",
            "plant",
            "installation_year",
        ],
    )
    write_csv(
        CSV_DIR / "all_tables_section_i_technical_conditions.csv",
        technical_rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "row_in_table",
            "state",
            "row_type",
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
        ],
    )
    return {"section_i_identity": len(identity_rows), "section_i_technical": len(technical_rows)}


def parse_section_ii(data: dict) -> dict[str, int]:
    capacity_rows = []
    adduction_rows = []
    current_state = ""
    for page in data["raw_response"]["pages"][32:58]:
        page_no = page["index"] + 1
        for table in page.get("tables") or []:
            for row_idx, row in enumerate(parse_md_table(table["content"]), 1):
                state = infer_state(" ".join(row))
                if (state or norm_text(row[0]).startswith("ESTADO")) and all(not c for c in row[1:]):
                    if state:
                        current_state = state
                    continue
                if len(row) == 7 and not is_empty_or_header_row(row):
                    capacity_rows.append(
                        {
                            "source_file": "all_tables.pdf",
                            "page": page_no,
                            "source_table_id": table["id"],
                            "row_in_table": row_idx,
                            "state": current_state,
                            "company": clean_label(row[0]),
                            "municipality_plant_location": clean_label(row[1]),
                            "plant": clean_label(row[2]),
                            "electrical_installation_capacity_hp": normalized_number(row[3]),
                            "total_waterfall_capacity_hp": normalized_number(row[4]),
                            "waterfall_height_m": normalized_number(row[5]),
                            "extension_m": normalized_number(row[6]),
                        }
                    )
                elif len(row) == 10 and not is_empty_or_header_row(row):
                    adduction_rows.append(
                        {
                            "source_file": "all_tables.pdf",
                            "page": page_no,
                            "source_table_id": table["id"],
                            "row_in_table": row_idx,
                            "state_context": current_state,
                            "adduction_material": clean_label(row[0]),
                            "pipe_diameter_mm": normalized_number(row[1]),
                            "pipe_thickness_mm": normalized_number(row[2]),
                            "transmission_line_km": normalized_number(row[3]),
                            "distribution_line_km": normalized_number(row[4]),
                            "transmission_voltage": normalized_number(row[5]),
                            "distribution_voltage": normalized_number(row[6]),
                            "transformer_stations": normalized_number(row[7]),
                            "watercourse_used": clean_label(row[8]),
                            "reservoir_capacity_m3": normalized_number(row[9]),
                        }
                    )
    write_csv(
        CSV_DIR / "all_tables_section_ii_hydraulic_capacity.csv",
        capacity_rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "row_in_table",
            "state",
            "company",
            "municipality_plant_location",
            "plant",
            "electrical_installation_capacity_hp",
            "total_waterfall_capacity_hp",
            "waterfall_height_m",
            "extension_m",
        ],
    )
    write_csv(
        CSV_DIR / "all_tables_section_ii_adduction_lines.csv",
        adduction_rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "row_in_table",
            "state_context",
            "adduction_material",
            "pipe_diameter_mm",
            "pipe_thickness_mm",
            "transmission_line_km",
            "distribution_line_km",
            "transmission_voltage",
            "distribution_voltage",
            "transformer_stations",
            "watercourse_used",
            "reservoir_capacity_m3",
        ],
    )
    return {"section_ii_capacity": len(capacity_rows), "section_ii_adduction": len(adduction_rows)}


def parse_illumination_general(data: dict) -> int:
    rows = []
    current_state = ""
    carry = {"category": "", "system": "", "company": ""}
    for page in data["raw_response"]["pages"][61:92]:
        page_no = page["index"] + 1
        page_state = infer_state(page.get("markdown", ""))
        if page_state:
            current_state = page_state
        for table in page.get("tables") or []:
            for row_idx, row in enumerate(parse_md_table(table["content"]), 1):
                if len(row) != 6 or is_empty_or_header_row(row):
                    continue
                state = infer_state(row[0])
                if state and all(not c for c in row[1:]):
                    current_state = state
                    continue
                category = clean_label(row[1])
                system = clean_label(row[2])
                company = clean_label(row[3])
                category_inferred = "no"
                system_inferred = "no"
                company_inferred = "no"
                if category in {"»", "» »"}:
                    category = carry["category"]
                    category_inferred = "yes"
                if system in {"»", "» »"}:
                    system = carry["system"]
                    system_inferred = "yes"
                if company in {"»", "» »"}:
                    company = carry["company"]
                    company_inferred = "yes"
                if category and category != "—":
                    carry["category"] = category
                if system and system != "—":
                    carry["system"] = system
                if company and company != "—":
                    carry["company"] = company
                rows.append(
                    {
                        "source_file": "all_tables.pdf",
                        "page": page_no,
                        "source_table_id": table["id"],
                        "row_in_table": row_idx,
                        "state": current_state,
                        "municipality": clean_label(row[0]),
                        "category": category,
                        "category_inferred_from_ditto": category_inferred,
                        "lighting_system": system,
                        "lighting_system_inferred_from_ditto": system_inferred,
                        "directing_company": company,
                        "directing_company_inferred_from_ditto": company_inferred,
                        "inauguration_date": clean_label(row[4]),
                        "annual_government_expense": clean_label(row[5]),
                    }
                )
    write_csv(
        CSV_DIR / "all_tables_illumination_i_general_service.csv",
        rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "row_in_table",
            "state",
            "municipality",
            "category",
            "category_inferred_from_ditto",
            "lighting_system",
            "lighting_system_inferred_from_ditto",
            "directing_company",
            "directing_company_inferred_from_ditto",
            "inauguration_date",
            "annual_government_expense",
        ],
    )
    return len(rows)


def parse_two_panel_posts(data: dict, page_start: int, page_end: int, out_name: str) -> int:
    rows = []
    states = ["", ""]
    for page in data["raw_response"]["pages"][page_start - 1 : page_end]:
        page_no = page["index"] + 1
        for table in page.get("tables") or []:
            for row_idx, row in enumerate(parse_md_table(table["content"]), 1):
                if len(row) != 6 or is_empty_or_header_row(row):
                    continue
                for panel in range(2):
                    offset = panel * 3
                    cells = row[offset : offset + 3]
                    state = infer_state(cells[0])
                    if state:
                        states[panel] = state
                        continue
                    if not cells[0]:
                        continue
                    rows.append(
                        {
                            "source_file": "all_tables.pdf",
                            "page": page_no,
                            "source_table_id": table["id"],
                            "row_in_table": row_idx,
                            "panel": panel + 1,
                            "state": states[panel],
                            "municipality": clean_label(cells[0]),
                            "posts": normalized_number(cells[1]),
                            "annual_expense": clean_label(cells[2]),
                        }
                    )
    write_csv(
        CSV_DIR / out_name,
        rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "row_in_table",
            "panel",
            "state",
            "municipality",
            "posts",
            "annual_expense",
        ],
    )
    return len(rows)


def parse_electric_lighting(data: dict) -> int:
    rows = []
    current_state = ""
    page100_states = ["Alagoas", "Amazonas", "Bahia", "Ceará", "Districto Federal"]
    page100_state_index = 0
    for page in data["raw_response"]["pages"][99:129]:
        page_no = page["index"] + 1
        page_state = infer_state(page.get("markdown", ""))
        if page_state:
            current_state = page_state
        for table in page.get("tables") or []:
            for row_idx, row in enumerate(parse_md_table(table["content"]), 1):
                if len(row) != 10 or is_empty_or_header_row(row):
                    continue
                state = infer_state(row[0])
                first_norm = norm_text(row[0])
                if (state or first_norm.startswith(("ESTADO", "DISTRICTO"))) and all(
                    not c for c in row[1:]
                ):
                    if state:
                        current_state = state
                    elif page_no == 100 and page100_state_index < len(page100_states):
                        current_state = page100_states[page100_state_index]
                        page100_state_index += 1
                    continue
                rows.append(
                    {
                        "source_file": "all_tables.pdf",
                        "page": page_no,
                        "source_table_id": table["id"],
                        "row_in_table": row_idx,
                        "state": current_state,
                        "municipality": clean_label(row[0]),
                        "public_arc_lamps_number": normalized_number(row[1]),
                        "public_arc_lamps_candlepower": normalized_number(row[2]),
                        "public_incandescent_lamps_number": normalized_number(row[3]),
                        "public_incandescent_lamps_candlepower": normalized_number(row[4]),
                        "public_total_candlepower": normalized_number(row[5]),
                        "private_arc_lamps_number": normalized_number(row[6]),
                        "private_arc_lamps_candlepower": normalized_number(row[7]),
                        "private_incandescent_lamps_number": normalized_number(row[8]),
                        "private_incandescent_lamps_candlepower": normalized_number(row[9]),
                    }
                )
    write_csv(
        CSV_DIR / "all_tables_illumination_v_electric_lighting.csv",
        rows,
        [
            "source_file",
            "page",
            "source_table_id",
            "row_in_table",
            "state",
            "municipality",
            "public_arc_lamps_number",
            "public_arc_lamps_candlepower",
            "public_incandescent_lamps_number",
            "public_incandescent_lamps_candlepower",
            "public_total_candlepower",
            "private_arc_lamps_number",
            "private_arc_lamps_candlepower",
            "private_incandescent_lamps_number",
            "private_incandescent_lamps_candlepower",
        ],
    )
    return len(rows)


def main() -> None:
    CSV_DIR.mkdir(parents=True, exist_ok=True)
    summary = {}
    summary.update(parse_tables_1_2())
    summary["table_3_city_lighting_system"] = parse_table_3()

    all_data = load_json("all_tables")
    state_context = state_context_for_all_tables(all_data)
    summary["all_tables_raw_fragments"] = parse_all_tables_raw(all_data, state_context)
    summary.update(parse_section_i(all_data, state_context))
    summary.update(parse_section_ii(all_data))
    summary["illumination_general"] = parse_illumination_general(all_data)
    summary["illumination_kerosene"] = parse_two_panel_posts(
        all_data, 93, 97, "all_tables_illumination_ii_kerosene.csv"
    )
    summary["illumination_acetylene_alcohol"] = parse_two_panel_posts(
        all_data, 98, 99, "all_tables_illumination_iii_iv_acetylene_alcohol.csv"
    )
    summary["illumination_electric"] = parse_electric_lighting(all_data)

    report_lines = [
        "Energy BR OCR parse report",
        f"OCR directory: {OCR_DIR}",
        f"CSV directory: {CSV_DIR}",
        "",
        "Rows written:",
    ]
    for key in sorted(summary):
        report_lines.append(f"- {key}: {summary[key]}")
    report_lines.extend(
        [
            "",
            "Notes:",
            "- all_tables_raw_ocr_fragments.csv preserves every Mistral table row as JSON cells.",
            "- all_tables.pdf is split into many OCR fragments; normalized CSVs retain page/source_table_id/row_in_table for audit.",
            "- Section I identity rows and technical rows are not merged one-to-one yet; they are separate normalized views.",
            "- State inference uses OCR headings and state rows where available, so blank/uncertain state cells should be reviewed.",
            "- tables_1_2_regional_foundation_distribution.csv lacks the final 1911-1920 HP column because Mistral did not expose it in the table object.",
        ]
    )
    (ROOT / "energy_br_parse_report.txt").write_text("\n".join(report_lines) + "\n", encoding="utf-8")
    print("\n".join(report_lines))


if __name__ == "__main__":
    main()
