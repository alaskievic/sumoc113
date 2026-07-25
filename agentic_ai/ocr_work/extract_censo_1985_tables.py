#!/usr/bin/env python3
"""Extract Censo 1985 tables from Mistral OCR and the PDF text layer."""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import unicodedata
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Iterable


PDF_DEFAULT = Path(
    "/Users/alaskievic/Library/CloudStorage/"
    "Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/"
    "sumoc_shared/censo_1985/part3_all_1985.pdf"
)


@dataclass(frozen=True)
class CensusConfig:
    name: str
    table1_pages: tuple[int, ...]
    table2_pages: tuple[int, ...]
    table3_pairs: tuple[tuple[int, int], ...]
    table3_ranges: tuple[tuple[int, int], ...]
    left_columns: tuple[str, ...]
    right_columns: tuple[str, ...]
    summary_last_value: str


CONFIGS = (
    CensusConfig(
        name="industrial",
        table1_pages=(1,),
        table2_pages=(2, 3),
        table3_pairs=tuple((page, page + 1) for page in range(4, 23, 2)),
        table3_ranges=(
            (1, 76),
            (77, 144),
            (145, 211),
            (212, 261),
            (262, 339),
            (340, 400),
            (401, 447),
            (448, 513),
            (514, 563),
            (564, 578),
        ),
        left_columns=(
            "establishments_1980",
            "personnel_total_1980",
            "personnel_linked_to_production_1980",
            "salaries_withdrawals_other_compensation_1980_mil_cruzeiros",
            "gross_production_value_1980_mil_cruzeiros",
            "industrial_transformation_value_1980_mil_cruzeiros",
        ),
        right_columns=(
            "companies_headquartered_in_municipality_1985",
            "establishments_1985",
            "personnel_total_1985",
            "personnel_linked_to_production_1985",
            "salaries_withdrawals_other_compensation_1985_mil_cruzeiros",
            "gross_production_value_1985_mil_cruzeiros",
            "industrial_transformation_value_1985_mil_cruzeiros",
        ),
        summary_last_value="gross_production_value_1985_million_cruzeiros",
    ),
    CensusConfig(
        name="commerce",
        table1_pages=(25,),
        table2_pages=(26, 27),
        table3_pairs=tuple((page, page + 1) for page in range(28, 51, 2)),
        table3_ranges=(
            (1, 75),
            (76, 143),
            (144, 214),
            (215, 280),
            (281, 329),
            (330, 403),
            (404, 480),
            (481, 525),
            (526, 575),
            (576, 650),
            (651, 701),
            (702, 721),
        ),
        left_columns=(
            "establishments_1980",
            "personnel_total_1980",
            "personnel_linked_to_commercialization_1980",
            "salaries_withdrawals_other_compensation_1980_mil_cruzeiros",
            "total_revenue_1980_mil_cruzeiros",
            "commercialization_revenue_1980_mil_cruzeiros",
        ),
        right_columns=(
            "companies_headquartered_in_municipality_1985",
            "establishments_1985",
            "personnel_total_1985",
            "personnel_linked_to_commercialization_1985",
            "salaries_withdrawals_other_compensation_1985_mil_cruzeiros",
            "total_revenue_1985_mil_cruzeiros",
            "commercialization_revenue_1985_mil_cruzeiros",
        ),
        summary_last_value="merchandise_sales_revenue_1985_million_cruzeiros",
    ),
    CensusConfig(
        name="services",
        table1_pages=(53,),
        table2_pages=(54, 55),
        table3_pairs=tuple((page, page + 1) for page in range(56, 77, 2)),
        table3_ranges=(
            (1, 68),
            (69, 131),
            (132, 194),
            (195, 250),
            (251, 311),
            (312, 377),
            (378, 432),
            (433, 477),
            (478, 542),
            (543, 598),
            (599, 625),
        ),
        left_columns=(
            "establishments_1980",
            "personnel_total_1980",
            "personnel_linked_to_service_activity_1980",
            "salaries_withdrawals_1980_mil_cruzeiros",
            "total_revenue_1980_mil_cruzeiros",
        ),
        right_columns=(
            "companies_headquartered_in_municipality_1985",
            "establishments_1985",
            "personnel_total_1985",
            "personnel_linked_to_service_activity_1985",
            "salaries_withdrawals_1985_mil_cruzeiros",
            "total_revenue_1985_mil_cruzeiros",
        ),
        summary_last_value="total_revenue_1985_million_cruzeiros",
    ),
)


PART_LAYOUTS = {
    "part4_all_1985": {
        "industrial": (1, (2, 3), (4, 79)),
        "commerce": (81, (82, 83), (84, 167)),
        "services": (169, (170, 171), (172, 245)),
        "appendix_page": 246,
    },
    "part5_all_1985": {
        "industrial": (1, (2, 3), (4, 79)),
        "commerce": (81, (82, 83), (84, 169)),
        "services": (171, (172, 173), (174, 249)),
        "appendix_page": 250,
    },
    "part6_all_1985": {
        "industrial": (1, (2, 3), (4, 45)),
        "commerce": (47, (48, 49), (50, 95)),
        "services": (97, (98, 99), (100, 141)),
        "appendix_page": 142,
    },
    "part7_all_1985": {
        "industrial": (1, (2, 3), (4, 23)),
        "commerce": (25, (26, 27), (28, 49)),
        "services": (51, (52, 53), (54, 73)),
        "appendix_page": 74,
    },
}


PART_TABLE3_RANGE_ENDS = {
    "part6_all_1985": {
        "industrial": [75, 162, 209, 256, 303, 350, 397, 444, 509, 578, 625, 672, 719, 775, 859, 935, 982, 1029, 1076, 1123, 1153],
        "commerce": [75, 156, 211, 256, 301, 346, 391, 436, 481, 549, 611, 656, 701, 746, 791, 868, 934, 995, 1040, 1085, 1130, 1175, 1217],
        "services": [68, 143, 193, 240, 287, 334, 381, 428, 483, 551, 598, 645, 692, 743, 819, 888, 935, 982, 1029, 1076, 1102],
    },
    "part7_all_1985": {
        "industrial": [76, 135, 196, 254, 318, 371, 418, 465, 512, 536],
        "commerce": [75, 143, 188, 261, 306, 378, 424, 469, 514, 559, 593],
        "services": [68, 128, 177, 241, 292, 353, 400, 447, 494, 534],
    },
}


def ranges_from_ends(ends: list[int]) -> tuple[tuple[int, int], ...]:
    start = 1
    output = []
    for end in ends:
        output.append((start, end))
        start = end + 1
    return tuple(output)


def configs_for_pdf(pdf: Path) -> tuple[tuple[CensusConfig, ...], int]:
    if pdf.stem == "part3_all_1985":
        return CONFIGS, 78
    layout = PART_LAYOUTS.get(pdf.stem)
    if layout is None:
        raise ValueError(f"No page layout configured for {pdf.name}")
    configs = []
    configured_ranges = PART_TABLE3_RANGE_ENDS.get(pdf.stem, {})
    for base in CONFIGS:
        table1_page, table2_pages, (first, last) = layout[base.name]
        configs.append(
            replace(
                base,
                table1_pages=(table1_page,),
                table2_pages=table2_pages,
                table3_pairs=tuple(
                    (page, page + 1) for page in range(first, last + 1, 2)
                ),
                table3_ranges=ranges_from_ends(configured_ranges[base.name])
                if base.name in configured_ranges
                else (),
            )
        )
    return tuple(configs), int(layout["appendix_page"])


SUMMARY_COLUMNS = (
    "entity",
    "establishments_1985_absolute",
    "establishments_1985_percent",
    "personnel_occupied_1985_absolute",
    "personnel_occupied_1985_percent",
    "salaries_withdrawals_other_compensation_1985_million_cruzeiros",
    "salaries_withdrawals_other_compensation_1985_percent",
)


# Order numbers on these scan lines were damaged in the embedded OCR. Labels
# were transcribed from the same visible PDF rows; numeric cells remain flagged.
LABEL_OVERRIDES = {
    "industrial": {
        75: "METALURGICA",
        76: "MECANICA",
        77: "MATERIAL ELETRICO",
        107: "NAO METALICOS",
        108: "METALURGICA",
        114: "BORRACHA",
        125: "TRANSFORMACAO",
        126: "NAO METALICOS",
        137: "ALIMENTARES",
        138: "BEBIDAS",
        139: "FUMO",
        140: "GRAFICA",
        141: "DIVERSAS",
        142: "ASSIS BRASIL",
        143: "BRASILEIA",
        144: "CRUZEIRO DO SUL",
        358: "VESTUARIO",
        361: "FUMO",
        368: "TEXTIL",
        370: "DEMAIS GENEROS",
        371: "ABAETETUBA",
        374: "ALENQUER",
        342: "TRANSFORMACAO",
        343: "NAO METALICOS",
        375: "ALMEIRIM",
        381: "BAGRE",
        384: "BENEVIDES",
        388: "BUJARU",
        389: "CACHOEIRA DO ARARI",
        390: "CAMETA",
        398: "CURUCA",
    }
}


def clean_cell(value: str) -> str:
    value = value.replace("\u00a0", " ").replace("\u200b", " ")
    return re.sub(r"\s+", " ", value).strip(" \t\r\n|")


def clean_label(value: str) -> str:
    value = clean_cell(value)
    value = re.sub(r"[.•·,;:\s]+$", "", value)
    value = re.sub(r"\s+", " ", value).strip(" .,:;•·")
    return value


def valid_label(value: str) -> bool:
    letters = re.findall(r"[A-ZÁÉÍÓÚÃÕÇ]", value.upper())
    if len(letters) < 2:
        return False
    if re.fullmatch(r"(?:\([A-Z]\)|\(X\)|-)(?:\s+(?:\([A-Z]\)|\(X\)|-))*", value):
        return False
    return True


def markdown_rows(content: str) -> Iterable[list[str]]:
    for line in content.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [clean_cell(cell) for cell in line.strip().strip("|").split("|")]
        if not cells or all(not cell for cell in cells):
            continue
        if all(not cell or re.fullmatch(r":?-{3,}:?", cell) for cell in cells):
            continue
        yield cells


def page_tables(pages: dict[int, dict], page: int) -> Iterable[list[str]]:
    for table in pages[page].get("tables", []):
        yield from markdown_rows(table.get("content", ""))


def split_order_label(cell: str) -> tuple[int | None, str]:
    match = re.fullmatch(r"(\d{1,4})(?:\s+(.+))?", clean_cell(cell))
    if not match:
        return None, ""
    return int(match.group(1)), clean_label(match.group(2) or "")


def numeric_fragment(value: str) -> bool:
    return bool(re.fullmatch(r"[0-9 ]+", value))


def reconcile_cells(values: list[str], expected_count: int) -> list[str] | None:
    """Repair table cells split at a thousands-group boundary.

    Mistral occasionally emits ``111 | 914`` for the single value ``111 914``.
    Joins are attempted from right to left because the large monetary fields are
    the columns affected in these tables.
    """

    values = [clean_cell(value) for value in values if clean_cell(value)]
    while len(values) > expected_count:
        joined = False
        for index in range(len(values) - 2, -1, -1):
            left, right = values[index], values[index + 1]
            if not numeric_fragment(left) or not re.fullmatch(r"\d{3}", right):
                continue
            values[index : index + 2] = [f"{left} {right}"]
            joined = True
            break
        if not joined:
            return None
    return values if len(values) == expected_count else None


def parse_left_mistral(
    pages: dict[int, dict], page: int, expected_count: int
) -> dict[int, dict]:
    rows: dict[int, dict] = {}
    for cells in page_tables(pages, page):
        nonempty = [(index, cell) for index, cell in enumerate(cells) if cell]
        if not nonempty:
            continue
        first_index, first = nonempty[0]
        order, label = split_order_label(first)
        if order is None:
            continue
        cursor = first_index + 1
        if not label:
            while cursor < len(cells) and not cells[cursor]:
                cursor += 1
            if cursor >= len(cells):
                continue
            label = clean_label(cells[cursor])
            cursor += 1
        values = reconcile_cells([cell for cell in cells[cursor:] if cell], expected_count)
        if not valid_label(label):
            continue
        candidate = {
            "label": label,
            "values": values or [""] * expected_count,
            "method": "mistral_table" if values is not None else "mistral_table_partial",
            "complete": values is not None,
            "source_page": page,
        }
        existing = rows.get(order)
        if existing is None or (candidate["complete"] and not existing["complete"]):
            rows[order] = candidate
    return rows


def parse_right_mistral(
    pages: dict[int, dict], page: int, expected_count: int
) -> dict[int, dict]:
    rows: dict[int, dict] = {}
    for cells in page_tables(pages, page):
        nonempty = [cell for cell in cells if cell]
        if len(nonempty) < 2 or not re.fullmatch(r"\d{1,4}", nonempty[-1]):
            continue
        order = int(nonempty[-1])
        values = reconcile_cells(nonempty[:-1], expected_count)
        rows[order] = {
            "values": values or [""] * expected_count,
            "method": "mistral_table" if values is not None else "mistral_table_partial",
            "complete": values is not None,
            "source_page": page,
        }
    return rows


VALUE_TOKEN = re.compile(r"^(?:\d+|[-–—]|\([A-GX]\))$", re.IGNORECASE)


def normalize_order_token(token: str) -> int | None:
    translation = str.maketrans(
        {"O": "0", "Q": "0", "D": "0", "I": "1", "L": "1", "|": "1", "Z": "2", "S": "5", "B": "8"}
    )
    normalized = token.upper().translate(translation)
    return int(normalized) if re.fullmatch(r"\d{1,4}", normalized) else None


def normalize_value_token(token: str) -> str:
    token = token.strip(".,;:")
    if re.fullmatch(r"\d+|[-–—]", token):
        return token
    match = re.fullmatch(r"[^0-9A-Z]*([A-GX])[^0-9A-Z]*[LIT]?[)>!}°']?", token.upper())
    return f"({match.group(1)})" if match else token


def parse_left_text_lines(text: str, expected_count: int, method: str) -> dict[int, dict]:
    rows: dict[int, dict] = {}
    for line in text.splitlines():
        match = re.match(r"^\s*([0-9OQDISBZIl|]{1,4})\s+(.+?)\s*$", line)
        if not match:
            continue
        order = normalize_order_token(match.group(1))
        if order is None:
            continue
        raw_tokens = match.group(2).split()
        tokens = [normalize_value_token(token) for token in raw_tokens]
        value_start = next(
            (index for index, token in enumerate(tokens) if VALUE_TOKEN.fullmatch(token)),
            None,
        )
        if value_start is None:
            continue
        label = clean_label(" ".join(raw_tokens[:value_start]))
        values = reconcile_cells(tokens[value_start:], expected_count)
        if not valid_label(label):
            continue
        rows[order] = {
            "label": label,
            "values": values or [""] * expected_count,
            "method": method if values is not None else f"{method}_partial",
            "complete": values is not None,
        }
    return rows


def parse_right_text_lines(text: str, expected_count: int, method: str) -> dict[int, dict]:
    rows: dict[int, dict] = {}
    for line in text.splitlines():
        raw_tokens = line.split()
        if len(raw_tokens) < expected_count + 1:
            continue
        order = normalize_order_token(raw_tokens[-1])
        if order is None:
            continue
        tokens = [normalize_value_token(token) for token in raw_tokens[:-1]]
        if not all(VALUE_TOKEN.fullmatch(token) for token in tokens):
            continue
        values = reconcile_cells(tokens, expected_count)
        rows[order] = {
            "values": values or [""] * expected_count,
            "method": method if values is not None else f"{method}_partial",
            "complete": values is not None,
        }
    return rows


def parse_left_markdown(
    pages: dict[int, dict], page: int, expected_count: int
) -> dict[int, dict]:
    return parse_left_text_lines(
        pages[page].get("markdown", ""), expected_count, "mistral_markdown"
    )


def parse_right_markdown(
    pages: dict[int, dict], page: int, expected_count: int
) -> dict[int, dict]:
    return parse_right_text_lines(
        pages[page].get("markdown", ""), expected_count, "mistral_markdown"
    )


def consecutive_runs(values: Iterable[int]) -> list[tuple[int, int, int]]:
    numbers = sorted(set(number for number in values if 0 < number < 10_000))
    if not numbers:
        return []
    output: list[tuple[int, int, int]] = []
    start = end = numbers[0]
    for number in numbers[1:]:
        if number == end + 1:
            end = number
            continue
        output.append((start, end, end - start + 1))
        start = end = number
    output.append((start, end, end - start + 1))
    return sorted(output, key=lambda run: (run[2], run[1]), reverse=True)


def infer_table3_ranges(
    config: CensusConfig, pages: dict[int, dict]
) -> tuple[tuple[int, int], ...]:
    """Infer continuous printed-order intervals for each two-page pair."""

    runs_by_pair: list[list[tuple[int, int, int]]] = []
    for left_page, right_page in config.table3_pairs:
        orders = set(
            parse_left_mistral(pages, left_page, len(config.left_columns))
        )
        orders.update(
            parse_left_markdown(pages, left_page, len(config.left_columns))
        )
        orders.update(
            parse_right_mistral(pages, right_page, len(config.right_columns))
        )
        orders.update(
            parse_right_markdown(pages, right_page, len(config.right_columns))
        )
        runs_by_pair.append(consecutive_runs(orders))

    output: list[tuple[int, int]] = []
    expected_start = 1
    for index, runs in enumerate(runs_by_pair):
        longest = next((run for run in runs if run[2] >= 3), None)
        plausible = next(
            (
                run
                for run in runs
                if run[2] >= 3
                and (run[0] <= expected_start <= run[1] or run[0] <= expected_start + 3)
            ),
            None,
        )
        if plausible is not None:
            end = plausible[1]
        else:
            next_start = None
            for future_runs in runs_by_pair[index + 1 :]:
                candidates = [run for run in future_runs if run[2] >= 3 and run[0] > expected_start]
                if candidates:
                    next_start = max(candidates, key=lambda run: run[2])[0]
                    break
            if next_start is None:
                if longest is None or longest[1] < expected_start:
                    raise ValueError(
                        f"Cannot infer final order range for {config.name} pair "
                        f"{config.table3_pairs[index]}"
                    )
                end = longest[1]
            else:
                end = next_start - 1
        if end < expected_start:
            raise ValueError(
                f"Invalid inferred range {expected_start}-{end} for {config.name}"
            )
        output.append((expected_start, end))
        expected_start = end + 1
    return tuple(output)


PDF_TEXT_CACHE: dict[Path, list[str]] = {}


def run_pdftotext(pdf: Path, page: int) -> str:
    cached = PDF_TEXT_CACHE.get(pdf)
    if cached is None:
        result = subprocess.run(
            ["pdftotext", "-layout", str(pdf), "-"],
            check=True,
            capture_output=True,
            text=True,
        )
        cached = result.stdout.split("\f")
        PDF_TEXT_CACHE[pdf] = cached
    if page <= len(cached):
        return cached[page - 1]
    return ""


def layout_parts(line: str) -> list[str]:
    return [clean_cell(part) for part in re.split(r" {2,}", line.strip()) if clean_cell(part)]


def parse_layout_left(text: str, expected_count: int) -> dict[int, dict]:
    rows: dict[int, dict] = {}
    for line in text.splitlines():
        parts = layout_parts(line)
        if not parts:
            continue
        order, label = split_order_label(parts[0])
        value_start = 1
        if order is not None and not label and len(parts) > 1:
            label = clean_label(parts[1])
            value_start = 2
        if order is None or not valid_label(label):
            continue
        values = reconcile_cells(parts[value_start:], expected_count)
        candidate = {
            "label": label,
            "values": values or [""] * expected_count,
            "method": "pdf_text_layout" if values is not None else "pdf_text_layout_partial",
            "complete": values is not None,
        }
        existing = rows.get(order)
        if existing is None or (candidate["complete"] and not existing["complete"]):
            rows[order] = candidate
    return rows


def parse_layout_right(text: str, expected_count: int) -> dict[int, dict]:
    rows: dict[int, dict] = {}
    for line in text.splitlines():
        parts = layout_parts(line)
        if len(parts) < 2:
            continue
        order_text = re.sub(r"[^0-9]", "", parts[-1])
        if not order_text or len(order_text) > 4:
            continue
        values = reconcile_cells(parts[:-1], expected_count)
        rows[int(order_text)] = {
            "values": values or [""] * expected_count,
            "method": "pdf_text_layout" if values is not None else "pdf_text_layout_partial",
            "complete": values is not None,
        }
    return rows


def normalized_key(value: str) -> str:
    value = unicodedata.normalize("NFD", value.upper())
    value = "".join(char for char in value if unicodedata.category(char) != "Mn")
    return re.sub(r"[^A-Z0-9]+", "", value)


def summary_pairs(parts: list[str]) -> list[tuple[str, str]]:
    pairs: list[tuple[str, str]] = []
    absolute_fragments: list[str] = []
    for part in parts:
        combined = re.fullmatch(r"(.+\d)\s+(\d{1,3}[,.'\"]\d)", part)
        if combined:
            absolute_fragments.append(combined.group(1))
            pairs.append((" ".join(absolute_fragments), combined.group(2)))
            absolute_fragments = []
            continue
        compact = re.sub(r"\s+", "", part)
        looks_percent = bool(
            len(compact) <= 8
            and re.search(r"[,.'\"]", compact)
            and re.search(r"\d", compact)
        )
        if looks_percent and absolute_fragments:
            pairs.append((" ".join(absolute_fragments), part))
            absolute_fragments = []
        else:
            absolute_fragments.append(part)
    return pairs


def parse_summary_mistral_page(
    pages: dict[int, dict], page: int, last_value_name: str
) -> list[dict]:
    columns = (*SUMMARY_COLUMNS, last_value_name, f"{last_value_name}_percent")
    output: list[dict] = []
    for cells in page_tables(pages, page):
        nonempty = [cell for cell in cells if cell]
        label_index = next(
            (index for index, cell in enumerate(nonempty) if re.search(r"[A-ZÁÉÍÓÚÃÕÇ]", cell)),
            None,
        )
        if label_index is None:
            continue
        label = clean_label(nonempty[label_index])
        pairs = summary_pairs(nonempty[label_index + 1 :])
        if len(pairs) not in (3, 4):
            continue
        incomplete = len(pairs) == 3
        if incomplete:
            pairs.append(("", ""))
        values = [value for pair in pairs for value in pair]
        row = dict(zip(columns, (label, *values)))
        row["source_page"] = page
        row["extraction_method"] = (
            "mistral_table_partial" if incomplete else "mistral_table"
        )
        row["needs_review"] = "yes" if incomplete else "no"
        output.append(row)
    return output


def merge_summary_rows(mistral_rows: list[dict], layout_rows: list[dict]) -> list[dict]:
    if not mistral_rows:
        return layout_rows
    layout_by_key: dict[str, list[dict]] = {}
    for row in layout_rows:
        layout_by_key.setdefault(normalized_key(row["entity"]), []).append(row)
    merged: list[dict] = []
    for row in mistral_rows:
        if row.get("needs_review") != "yes":
            merged.append(row)
            continue
        matches = layout_by_key.get(normalized_key(row["entity"]), [])
        if matches:
            layout = matches.pop(0)
            for key, value in layout.items():
                if not row.get(key):
                    row[key] = value
            row["extraction_method"] = "mistral_table_plus_pdf_text_layout"
            row["needs_review"] = "no"
        merged.append(row)
    return merged if len(merged) >= len(layout_rows) else layout_rows


def parse_summary_pages(pdf: Path, pages: tuple[int, ...], last_value_name: str) -> list[dict]:
    output: list[dict] = []
    columns = (*SUMMARY_COLUMNS, last_value_name, f"{last_value_name}_percent")
    for page in pages:
        text = run_pdftotext(pdf, page)
        for line in text.splitlines():
            parts = layout_parts(line)
            if len(parts) < 3:
                continue
            label = clean_label(parts[0])
            if not label or not re.search(r"[A-ZÁÉÍÓÚÃÕÇ]", label):
                continue
            pairs = summary_pairs(parts[1:])
            if len(pairs) != 4:
                continue
            values = [value for pair in pairs for value in pair]
            row = dict(zip(columns, (label, *values)))
            row["source_page"] = page
            row["extraction_method"] = "pdf_text_layout"
            row["needs_review"] = "no"
            output.append(row)
    return output


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def extract_table3(
    config: CensusConfig,
    pages: dict[int, dict],
    pdf: Path,
    tesseract_dir: Path | None = None,
) -> tuple[list[dict], dict]:
    left_candidates: dict[int, dict[int, dict]] = {}
    right_candidates: dict[int, dict[int, dict]] = {}
    layout_cache: dict[int, str] = {}

    for left_page, right_page in config.table3_pairs:
        layout_cache[left_page] = run_pdftotext(pdf, left_page)
        layout_cache[right_page] = run_pdftotext(pdf, right_page)
        left = parse_layout_left(layout_cache[left_page], len(config.left_columns))
        for candidates in (
            parse_left_text_lines(
                layout_cache[left_page], len(config.left_columns), "pdf_text_tokens"
            ),
            parse_left_mistral(pages, left_page, len(config.left_columns)),
            parse_left_markdown(pages, left_page, len(config.left_columns)),
        ):
            for order, row in candidates.items():
                if row["complete"] or order not in left or not left[order]["complete"]:
                    left[order] = row
        if tesseract_dir is not None:
            tesseract_path = tesseract_dir / f"page_{left_page}.txt"
            if tesseract_path.exists():
                tesseract_rows = parse_left_text_lines(
                    tesseract_path.read_text(encoding="utf-8"),
                    len(config.left_columns),
                    "tesseract_por_review",
                )
                for order, row in tesseract_rows.items():
                    existing = left.get(order)
                    if existing and existing.get("complete"):
                        continue
                    if row["complete"] and existing and valid_label(existing.get("label", "")):
                        row["label"] = existing["label"]
                    if row["complete"] or existing is None or not valid_label(existing.get("label", "")):
                        left[order] = row
        right = parse_layout_right(layout_cache[right_page], len(config.right_columns))
        for candidates in (
            parse_right_text_lines(
                layout_cache[right_page], len(config.right_columns), "pdf_text_tokens"
            ),
            parse_right_mistral(pages, right_page, len(config.right_columns)),
            parse_right_markdown(pages, right_page, len(config.right_columns)),
        ):
            for order, row in candidates.items():
                if row["complete"] or order not in right or not right[order]["complete"]:
                    right[order] = row
        if tesseract_dir is not None:
            tesseract_path = tesseract_dir / f"page_{right_page}.txt"
            if tesseract_path.exists():
                tesseract_rows = parse_right_text_lines(
                    tesseract_path.read_text(encoding="utf-8"),
                    len(config.right_columns),
                    "tesseract_por_review",
                )
                for order, row in tesseract_rows.items():
                    existing = right.get(order)
                    if row["complete"] and not (existing and existing.get("complete")):
                        right[order] = row
        left_candidates[left_page] = left
        right_candidates[right_page] = right

    rows: list[dict] = []
    pair_audits: list[dict] = []
    table3_ranges = config.table3_ranges or infer_table3_ranges(config, pages)
    label_overrides = LABEL_OVERRIDES.get(config.name, {}) if pdf.stem == "part3_all_1985" else {}

    for (left_page, right_page), (start, end) in zip(
        config.table3_pairs, table3_ranges
    ):
        left = left_candidates[left_page]
        right = right_candidates[right_page]
        expected = set(range(start, end + 1))
        left_orders = set(left) & expected
        right_orders = set(right) & expected
        for order in sorted(expected):
            override_label = label_overrides.get(order, "")
            if order not in left and override_label:
                left[order] = {
                    "label": override_label,
                    "values": [""] * len(config.left_columns),
                    "method": "manual_label_from_pdf_layout",
                    "complete": False,
                }
        left_orders = set(left) & expected
        incomplete_left = sorted(
            order for order in left_orders if not left[order].get("complete", False)
        )
        incomplete_right = sorted(
            order for order in right_orders if not right[order].get("complete", False)
        )
        pair_audits.append(
            {
                "left_page": left_page,
                "right_page": right_page,
                "expected_start": start,
                "expected_end": end,
                "expected_rows": len(expected),
                "left_rows": len(left_orders),
                "right_rows": len(right_orders),
                "missing_left_orders": sorted(expected - left_orders),
                "missing_right_orders": sorted(expected - right_orders),
                "incomplete_left_orders": incomplete_left,
                "incomplete_right_orders": incomplete_right,
            }
        )
        for order in sorted(expected):
            left_row = left.get(order, {})
            right_row = right.get(order, {})
            row = {
                "order_number": order,
                "entry": label_overrides.get(order, left_row.get("label", "")),
                "source_page_1980": left_page,
                "source_page_1985": right_page,
                "left_extraction_method": left_row.get("method", "missing"),
                "right_extraction_method": right_row.get("method", "missing"),
            }
            row.update(dict(zip(config.left_columns, left_row.get("values", []))))
            row.update(dict(zip(config.right_columns, right_row.get("values", []))))
            row["needs_review"] = (
                "no"
                if left_row.get("complete", False) and right_row.get("complete", False)
                else "yes"
            )
            rows.append(row)

    all_orders = [row["order_number"] for row in rows]
    audit = {
        "census": config.name,
        "row_count": len(rows),
        "first_order": min(all_orders) if all_orders else None,
        "last_order": max(all_orders) if all_orders else None,
        "duplicate_orders": sorted(
            number for number in set(all_orders) if all_orders.count(number) > 1
        ),
        "rows_needing_review": sum(row["needs_review"] == "yes" for row in rows),
        "pairs": pair_audits,
    }
    return rows, audit


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", type=Path, default=PDF_DEFAULT)
    parser.add_argument("--mistral-json", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--tesseract-dir", type=Path)
    args = parser.parse_args()

    result = json.loads(args.mistral_json.read_text(encoding="utf-8"))
    pages = {int(page["page"]): page for page in result["pages"]}
    args.out_dir.mkdir(parents=True, exist_ok=True)
    configs, appendix_page = configs_for_pdf(args.pdf)

    audits: dict[str, dict] = {}
    summary_audits: dict[str, dict] = {}
    manifest_files: list[str] = []
    for config in configs:
        summary_audits[config.name] = {}
        for table_number, table_pages in ((1, config.table1_pages), (2, config.table2_pages)):
            summary_rows = []
            for page in table_pages:
                layout_rows = parse_summary_pages(
                    args.pdf, (page,), config.summary_last_value
                )
                mistral_rows = parse_summary_mistral_page(
                    pages, page, config.summary_last_value
                )
                summary_rows.extend(merge_summary_rows(mistral_rows, layout_rows))
            summary_fields = [
                *SUMMARY_COLUMNS,
                config.summary_last_value,
                f"{config.summary_last_value}_percent",
                "source_page",
                "extraction_method",
                "needs_review",
            ]
            output_path = args.out_dir / f"{config.name}_table_{table_number}.csv"
            write_csv(output_path, summary_rows, list(summary_fields))
            manifest_files.append(output_path.name)
            expected_rows = 42 if table_number == 1 else 122
            summary_audits[config.name][f"table_{table_number}"] = {
                "row_count": len(summary_rows),
                "expected_rows": expected_rows,
                "missing_rows": max(expected_rows - len(summary_rows), 0),
                "rows_needing_review": sum(
                    row.get("needs_review") == "yes" for row in summary_rows
                ),
                "source_pages": list(table_pages),
            }

        table3_rows, table3_audit = extract_table3(
            config, pages, args.pdf, args.tesseract_dir
        )
        table3_fields = [
            "order_number",
            "entry",
            *config.left_columns,
            *config.right_columns,
            "source_page_1980",
            "source_page_1985",
            "left_extraction_method",
            "right_extraction_method",
            "needs_review",
        ]
        output_path = args.out_dir / f"{config.name}_table_3_merged.csv"
        write_csv(output_path, table3_rows, table3_fields)
        manifest_files.append(output_path.name)
        audits[config.name] = table3_audit

    audit_path = args.out_dir / "table_3_merge_audit.json"
    audit_path.write_text(json.dumps(audits, ensure_ascii=False, indent=2), encoding="utf-8")
    manifest_files.append(audit_path.name)
    summary_audit_path = args.out_dir / "summary_tables_audit.json"
    summary_audit_path.write_text(
        json.dumps(summary_audits, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    manifest_files.append(summary_audit_path.name)
    manifest = {
        "source_pdf": str(args.pdf),
        "mistral_json": str(args.mistral_json),
        "supplemental_tesseract_dir": str(args.tesseract_dir) if args.tesseract_dir else None,
        "processed_pdf_pages": f"1-{appendix_page - 1}",
        "appendix_excluded_from_page": appendix_page,
        "files": manifest_files,
        "notes": [
            "Raw OCR strings are preserved; thousands separators are not normalized.",
            "Table 3 joins use the printed order number.",
            "Supplemental Portuguese Tesseract text is used only to fill an incomplete Mistral/PDF-text row when all expected columns reconcile.",
            "needs_review=yes means one side of the printed pair still did not reconcile exactly.",
        ],
    }
    manifest_path = args.out_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(audits, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
