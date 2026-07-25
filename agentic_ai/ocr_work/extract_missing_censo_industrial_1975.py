#!/usr/bin/env python3
"""Extract and merge Industrial Census 1975 Table 2 scan fragments."""

from __future__ import annotations

import argparse
import csv
import difflib
import json
import re
import subprocess
import unicodedata
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_ROOT = ROOT / "output_ocr" / "censo_1975"
DESKTOP = Path.home() / "Desktop"
SHARED_CENSO = (
    Path.home()
    / "Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic"
    / "sumoc_shared/censo_1985"
)


LEFT_COLUMNS = (
    "establishments_1975",
    "personnel_occupied_total_1975",
    "personnel_occupied_linked_to_production_1975",
    "average_monthly_personnel_occupied_1975",
)
RIGHT_COLUMNS = (
    "salaries_total_1975_thousand_cruzeiros",
    "salaries_production_personnel_1975_thousand_cruzeiros",
    "miscellaneous_expenses_1975_thousand_cruzeiros",
    "industrial_operations_expenses_total_1975_thousand_cruzeiros",
    "industrial_operations_expenses_raw_materials_materials_components_1975_thousand_cruzeiros",
    "production_value_1975_thousand_cruzeiros",
    "industrial_transformation_value_1975_thousand_cruzeiros",
)


INDUSTRY_LABELS = (
    "EXTRACAO DE MINERAIS",
    "TRANSFORMACAO DE PRODUTOS DE MINERAIS NAO METALICOS",
    "METALURGICA",
    "MECANICA",
    "MATERIAL ELETRICO E DE COMUNICACOES",
    "MATERIAL DE TRANSPORTE",
    "MADEIRA",
    "MOBILIARIO",
    "PAPEL E PAPELAO",
    "BORRACHA",
    "COUROS E PELES, ARTEFATOS PARA VIAGEM",
    "QUIMICA",
    "PRODUTOS FARMACEUTICOS E VETERINARIOS",
    "PERFUMARIA, SABOES E VELAS",
    "PRODUTOS DE MATERIAS PLASTICAS",
    "TEXTIL",
    "VESTUARIO, CALCADOS E ARTEFATOS DE TECIDOS",
    "PRODUTOS ALIMENTARES",
    "BEBIDAS",
    "FUMO",
    "EDITORIAL E GRAFICA",
    "DIVERSAS",
    "ATIVIDADES DE APOIO E DE SERVICOS DE CARATER INDUSTRIAL",
)


# These spellings were checked against the scan and, where available, the
# municipality list in the 1985 extraction. Order-specific overrides avoid
# unsafe fuzzy matches between similarly named municipalities.
ENTRY_OVERRIDES = {
    3156: "POMPEU",
    3163: "PONTE NOVA",
    3180: "PORTEIRINHA",
    3186: "PORTO FIRME",
    3192: "POUSO ALEGRE",
    3208: "POUSO ALTO",
    3243: "PRESIDENTE JUSCELINO",
    3247: "PRESIDENTE KUBITSCHEK",
    3248: "PRESIDENTE OLEGARIO",
    3267: "QUELUZITA",
    3273: "RAUL SOARES",
    3309: "RESSAQUINHA",
    3358: "RIO PARANAIBA",
    3361: "RIO PARDO DE MINAS",
    3369: "MOBILIARIO",
    3376: "MOBILIARIO",
    3385: "MOBILIARIO",
    3400: "ROMARIA",
    3412: "SABARA",
    3466: "SANTA EFIGENIA DE MINAS",
    3467: "SANTA FE DE MINAS",
    3497: "SANTA MARIA DO SUACUI",
    3502: "BEBIDAS",
    3504: "SANTANA DA VARGEM",
    3511: "BEBIDAS",
    3524: "SANTANA DO JACARE",
    3529: "SANTANA DO RIACHO",
    3548: "SANTA RITA DO IBITIPOCA",
    3588: "SANTO ANTONIO DO GRAMA",
    3591: "SANTO ANTONIO DO ITAMBE",
    3592: "SANTO ANTONIO DO JACINTO",
    3595: "SANTO ANTONIO DO MONTE",
    3604: "SANTO ANTONIO DO RIO ABAIXO",
    3625: "SAO BRAS DO SUACUI",
    3642: "SAO FRANCISCO DE OLIVEIRA",
    3659: "SAO GERALDO DA PIEDADE",
    3660: "SAO GONCALO DO ABAETE",
    3691: "SAO GOTARDO",
    3787: "SAO MIGUEL DO ANTA",
    3802: "SAO ROMAO",
    3805: "SAO ROQUE DE MINAS",
    3813: "SAO SEBASTIAO DO MARANHAO",
    3814: "SAO SEBASTIAO DO OESTE",
    3831: "SAO SEBASTIAO DO RIO PRETO",
    3833: "SAO SEBASTIAO DO RIO VERDE",
    3836: "SAO TIAGO",
    3853: "SAPUCAI-MIRIM",
    3857: "SARDOA",
    3873: "SENHORA DO PORTO",
    3886: "SERRA DA SAUDADE",
    3910: "SETE LAGOAS",
    3913: "METALURGICA",
    3935: "SIMAO PEREIRA",
    3953: "TAIOBEIRAS",
    3970: "MECANICA",
    3975: "TEOFILO OTONI",
    3991: "DIVERSAS",
    3993: "TIMOTEO",
    4023: "TOMBOS",
    4066: "TUPACIGUARA",
    4111: "UBERABA",
    4134: "UBERLANDIA",
    4157: "UMBURATIBA",
    4172: "VARGEM BONITA",
    4202: "VARZELANDIA",
    4248: "VIRGINOPOLIS",
    4543: "SAO SIMAO",
    4555: "SAO VICENTE",
    4582: "SERRA AZUL",
    4725: "TABAPUA",
    4790: "TANABI",
    4885: "TEODORO SAMPAIO",
    4879: "DIVERSAS",
    4979: "UBIRAJARA",
    4990: "UNIAO PAULISTA",
}


# Mistral omitted these visually repetitive rows. The page images and the
# supplemental Tesseract output both show seven suppressed-value cells.
RIGHT_ALL_X_OVERRIDES = {
    3175,
    3202,
    3232,
    3484,
    3485,
    3561,
    3720,
    3780,
    4100,
    4191,
    4264,
    4545,
    4696,
    4737,
    4786,
    4798,
    4822,
    4836,
    5051,
    5063,
    5068,
    5078,
    5092,
    5094,
    705,
    728,
}


RIGHT_VALUE_OVERRIDES = {
    3451: ["-", "-", "(X)", "(X)", "(X)", "(X)", "(X)"],
    3452: ["(X)"] * 7,
    4170: ["4 074", "3 555", "(X)", "(X)", "(X)", "(X)", "(X)"],
    4184: ["196", "171", "394", "1 913", "1 871", "3 464", "1 551"],
    4192: ["-", "-", "(X)", "(X)", "(X)", "(X)", "(X)"],
    4211: ["-", "-", "(X)", "(X)", "(X)", "(X)", "(X)"],
    4225: ["(X)", "(X)", "(X)", "(X)", "-", "(X)", "(X)"],
    5093: ["530", "405", "532", "9 048", "8 921", "12 772", "3 724"],
}


LEFT_ROW_OVERRIDES = {
    4613: ("SERTAOZINHO", ["238", "3 880", "2 440", "3 870"]),
    4785: ("QUIMICA", ["1", "(X)", "(X)", "(X)"]),
    5027: ("PRODUTOS DE MATERIAS PLASTICAS", ["4", "79", "62", "79"]),
}


@dataclass(frozen=True)
class Config:
    stem: str
    pdf: Path
    pairs: tuple[tuple[int, int, int, int], ...]
    unpaired_left: tuple[int, int, int] | None = None


CONFIGS = (
    Config(
        stem="missing_mg_1975",
        pdf=DESKTOP / "missing_mg_1975.pdf",
        pairs=(
            (1, 2, 3309, 3353),
            (3, 4, 3354, 3399),
            (5, 6, 3400, 3450),
            (7, 8, 3451, 3496),
            (9, 10, 3497, 3541),
            (11, 12, 3542, 3587),
            (13, 14, 3588, 3634),
            (15, 16, 3635, 3681),
            (17, 18, 3682, 3733),
            (19, 20, 3734, 3780),
            (21, 22, 3781, 3824),
            (23, 24, 3825, 3865),
            (25, 26, 3866, 3904),
            (27, 28, 3905, 3952),
            (29, 30, 3953, 4005),
            (31, 32, 4006, 4057),
            (33, 34, 4058, 4110),
            (35, 36, 4111, 4171),
            (37, 38, 4172, 4225),
            (39, 40, 4226, 4274),
        ),
    ),
    Config(
        stem="missing_rj_1975",
        pdf=DESKTOP / "missing_rj_1975.pdf",
        pairs=((1, 2, 688, 746), (3, 4, 747, 772)),
    ),
    Config(
        stem="missing_sp_1975",
        pdf=SHARED_CENSO / "missing_sp_1975.pdf",
        pairs=(
            (1, 2, 4543, 4598),
            (3, 4, 4599, 4655),
            (5, 6, 4656, 4717),
            (7, 8, 4718, 4770),
            (9, 10, 4771, 4824),
            (11, 12, 4825, 4882),
            (13, 14, 4883, 4934),
            (15, 16, 4935, 4987),
            (17, 18, 4988, 5039),
            (19, 20, 5040, 5100),
            (21, 22, 5101, 5141),
        ),
    ),
)


def plain(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    value = value.upper().replace("~", "")
    return re.sub(r"[^A-Z0-9]+", " ", value).strip()


def clean_label(value: str) -> str:
    value = re.sub(r"(?:\s*\.){2,}", " ", value)
    value = re.sub(r"\s+", " ", value).strip(" .")
    value = value.rstrip(" '")
    return value.upper()


def clean_value(value: str) -> str:
    value = re.sub(r"\s+", " ", value.strip())
    if re.fullmatch(r"[.(]?\s*[xX]\s*\)?", value):
        return "(X)"
    if value in {"—", "–"}:
        return "-"
    value = value.strip(".,*")
    return value


def is_value(value: str) -> bool:
    value = clean_value(value)
    return bool(re.fullmatch(r"(?:\(X\)|-|\d+(?: \d{3})*)", value))


def markdown_rows(content: str) -> list[list[str]]:
    rows = []
    for line in content.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if all(not cell or re.fullmatch(r":?-{3,}:?", cell) for cell in cells):
            continue
        rows.append(cells)
    return rows


def page_rows(document: dict, page_number: int) -> list[list[str]]:
    page = document["pages"][page_number - 1]
    rows = []
    for table in page.get("tables", []):
        rows.extend(markdown_rows(table.get("content", "")))
    return rows


def partition_plain_values(tokens: list[str], groups: int) -> list[str] | None:
    if groups == 0:
        return [] if not tokens else None
    if len(tokens) < groups:
        return None
    if len(tokens) > groups and len(set(tokens)) == 1 and clean_value(tokens[0]) == "(X)":
        tokens = tokens[:groups]
    elif len(tokens) > groups * 2:
        return None

    def walk(position: int, remaining: int) -> tuple[float, list[str]] | None:
        if remaining == 0:
            return (0.0, []) if position == len(tokens) else None
        best = None
        for width in (1, 2):
            if position + width > len(tokens):
                continue
            parts = tokens[position : position + width]
            if width == 2 and not (
                all(re.fullmatch(r"\d+", part) for part in parts) and len(parts[1]) == 3
            ):
                continue
            value = clean_value(" ".join(parts))
            if not is_value(value):
                continue
            tail = walk(position + width, remaining - 1)
            if tail is None:
                continue
            score = tail[0] + (1.0 if width == 2 else 0.0)
            candidate = (score, [value, *tail[1]])
            if best is None or candidate[0] > best[0]:
                best = candidate
        return best

    result = walk(0, groups)
    return result[1] if result else None


def parse_plain_left_text(document: dict, page: int, start: int, end: int) -> dict[int, dict]:
    records = {}
    markdown = document["pages"][page - 1].get("markdown", "")
    for line in markdown.splitlines():
        match = re.match(r"^\s*(\d{4})\s+(.+?)\.\s+(.+?)\s*$", line)
        if not match:
            continue
        order = int(match.group(1))
        if not start <= order <= end:
            continue
        raw_tokens = re.findall(r"\([xX]\)|-|\d+", match.group(3))
        if not raw_tokens:
            continue
        first = clean_value(raw_tokens[0])
        tail = partition_plain_values(raw_tokens[1:], 3)
        if is_value(first) and tail:
            records[order] = {
                "entry_raw": clean_label(match.group(2)),
                "values": [first, *tail],
                "method": "mistral_page_text",
            }
    return records


def parse_left(document: dict, page: int, start: int, end: int) -> tuple[dict[int, dict], list[dict]]:
    records: dict[int, dict] = {}
    notes: list[dict] = []
    for cells in page_rows(document, page):
        nonempty = [cell for cell in cells if cell]
        if not nonempty:
            continue
        order_match = re.fullmatch(r"\d{3,4}", clean_value(nonempty[0]))
        if order_match and start <= int(order_match.group()) <= end:
            order = int(order_match.group())
            body = nonempty[1:]
            if len(body) >= 5 and all(is_value(value) for value in body[-4:]):
                records[order] = {
                    "entry_raw": clean_label(" ".join(body[:-4])),
                    "values": [clean_value(value) for value in body[-4:]],
                    "method": "mistral_table",
                }
            else:
                notes.append({"page": page, "order": order, "issue": "left_row_not_parsed", "cells": nonempty})
            continue

        # Wrapped labels occasionally occupy a second OCR row with their values.
        if len(nonempty) >= 5 and all(is_value(value) for value in nonempty[-4:]) and records:
            previous_order = max(records)
            previous = records[previous_order]
            continuation = clean_label(" ".join(nonempty[:-4]))
            if previous_order >= start and (
                plain(previous["entry_raw"]).endswith((" NAO", " CARA", " DE"))
                or plain(continuation) in {"METALICOS", "TER INDUSTRIAL"}
            ):
                previous["entry_raw"] = clean_label(previous["entry_raw"] + " " + continuation)
                previous["values"] = [clean_value(value) for value in nonempty[-4:]]
                previous["method"] = "mistral_table_wrapped_row_repaired"
                notes.append({"page": page, "order": previous_order, "issue": "wrapped_left_row_repaired"})

    for order, row in parse_plain_left_text(document, page, start, end).items():
        records.setdefault(order, row)
    return records, notes


def parse_right(document: dict, page: int, start: int, end: int) -> tuple[dict[int, dict], list[dict]]:
    candidates = []
    notes: list[dict] = []
    for cells in page_rows(document, page):
        nonempty = [cell for cell in cells if cell]
        if not nonempty:
            continue
        printed_order = None
        last_cell = clean_value(nonempty[-1])
        parenthesized_order = re.fullmatch(r"\(?(\d{3,4})\)?", last_cell)
        if parenthesized_order:
            possible_order = int(parenthesized_order.group(1))
            if possible_order < 1000 and start >= 1000:
                possible_order += (start // 1000) * 1000
            if start - 2 <= possible_order <= end + 2:
                printed_order = possible_order
                nonempty = nonempty[:-1]
        values = [clean_value(value) for value in nonempty if is_value(value)]
        if len(values) == 8:
            # The eighth numeric-looking cell is a damaged order number. The
            # seven data cells remain in their original left-to-right order.
            values = values[:7]
            printed_order = None
        if len(values) == 7:
            candidates.append((printed_order, values))

    expected = list(range(start, end + 1))
    records: dict[int, dict] = {}
    if len(candidates) == len(expected):
        for order, (printed_order, values) in zip(expected, candidates):
            method = "mistral_table"
            if printed_order != order:
                method = "mistral_table_sequence_aligned"
                notes.append(
                    {
                        "page": page,
                        "order": order,
                        "issue": "right_order_sequence_repaired",
                        "printed_ocr_order": printed_order,
                    }
                )
            records[order] = {"values": values, "method": method}
        return records, notes

    notes.append({"page": page, "issue": "right_candidate_count_mismatch", "expected": len(expected), "found": len(candidates)})
    if len(candidates) < len(expected) and len(expected) - len(candidates) <= 10:
        # Align the ordered data rows to printed order anchors. This retains
        # candidates whose order cell alone was damaged and inserts gaps only
        # where Mistral omitted an entire physical row.
        skip_cost = 3.0
        n, m = len(candidates), len(expected)
        dp = [[float("inf")] * (m + 1) for _ in range(n + 1)]
        move = [[""] * (m + 1) for _ in range(n + 1)]
        dp[0][0] = 0.0
        for j in range(1, m + 1):
            dp[0][j] = dp[0][j - 1] + skip_cost
            move[0][j] = "skip"
        for i in range(1, n + 1):
            for j in range(1, m + 1):
                printed_order = candidates[i - 1][0]
                order = expected[j - 1]
                if printed_order is None:
                    match_cost = 1.0
                elif printed_order == order:
                    match_cost = 0.0
                elif abs(printed_order - order) == 1:
                    match_cost = 2.5
                else:
                    match_cost = 20.0 + abs(printed_order - order)
                if dp[i - 1][j - 1] + match_cost <= dp[i][j - 1] + skip_cost:
                    dp[i][j] = dp[i - 1][j - 1] + match_cost
                    move[i][j] = "match"
                else:
                    dp[i][j] = dp[i][j - 1] + skip_cost
                    move[i][j] = "skip"
        aligned = []
        i, j = n, m
        while j:
            if i and move[i][j] == "match":
                aligned.append((expected[j - 1], candidates[i - 1]))
                i -= 1
                j -= 1
            else:
                j -= 1
        for order, (printed_order, values) in reversed(aligned):
            method = "mistral_table" if printed_order == order else "mistral_table_anchor_aligned"
            records[order] = {"values": values, "method": method}
            if method != "mistral_table":
                notes.append({"page": page, "order": order, "issue": "right_order_anchor_aligned", "printed_ocr_order": printed_order})
        return records, notes

    for printed_order, values in candidates:
        if printed_order is not None and start <= printed_order <= end and printed_order not in records:
            records[printed_order] = {"values": values, "method": "mistral_table"}
    return records, notes


def load_municipality_lexicon() -> list[str]:
    labels: dict[str, str] = {}
    for path in sorted((ROOT / "output_ocr" / "censo_1985").glob("*/tables/industrial_table_3_merged.csv")):
        with path.open(encoding="utf-8-sig", newline="") as handle:
            for row in csv.DictReader(handle):
                label = clean_label(row.get("entry", ""))
                key = plain(label)
                if key and row.get("needs_review") == "no":
                    labels.setdefault(key, label)
    return list(labels.values())


def closest_label(raw: str, choices: tuple[str, ...] | list[str], threshold: float) -> tuple[str, float]:
    raw_key = plain(raw)
    scores = [(difflib.SequenceMatcher(None, raw_key, plain(choice)).ratio(), choice) for choice in choices]
    score, choice = max(scores, default=(0.0, raw))
    return (choice, score) if score >= threshold else (raw, score)


def correct_entry(raw: str, municipalities: list[str], order: int) -> tuple[str, str]:
    if order in ENTRY_OVERRIDES:
        return ENTRY_OVERRIDES[order], "scan_verified_override"
    municipality, municipality_score = closest_label(raw, municipalities, 0.93)
    if municipality_score >= 0.93:
        return municipality, "municipality_1985_lexicon" if plain(municipality) != plain(raw) else "ocr_exact"
    category, category_score = closest_label(raw, INDUSTRY_LABELS, 0.78)
    if category_score >= 0.78:
        return category, "industry_lexicon" if plain(category) != plain(raw) else "ocr_exact"
    return raw, "ocr_unmatched"


def write_tesseract_review(config: Config, page_count: int, out_dir: Path) -> None:
    review_dir = out_dir / "tesseract_review"
    review_dir.mkdir(parents=True, exist_ok=True)
    scratch_root = ROOT / "ocr_work" / f".{config.stem}_tesseract_page"
    scratch_png = scratch_root.with_suffix(".png")
    for page in range(1, page_count + 1):
        target = review_dir / f"page_{page:02d}.txt"
        subprocess.run(
            ["pdftoppm", "-f", str(page), "-l", str(page), "-singlefile", "-r", "300", "-png", str(config.pdf), str(scratch_root)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        result = subprocess.run(
            ["tesseract", str(scratch_png), "stdout", "-l", "por", "--psm", "6", "-c", "preserve_interword_spaces=1"],
            check=True,
            capture_output=True,
            text=True,
        )
        target.write_text(result.stdout, encoding="utf-8")
    if scratch_png.exists():
        scratch_png.unlink()


def extract(config: Config, run_tesseract: bool) -> dict:
    out_dir = OUTPUT_ROOT / config.stem
    raw_json = out_dir / f"{config.stem}_mistral_raw.json"
    document = json.loads(raw_json.read_text(encoding="utf-8"))
    municipalities = load_municipality_lexicon()
    notes: list[dict] = []
    rows: list[dict] = []

    if run_tesseract:
        write_tesseract_review(config, len(document["pages"]), out_dir)

    for left_page, right_page, start, end in config.pairs:
        left, left_notes = parse_left(document, left_page, start, end)
        right, right_notes = parse_right(document, right_page, start, end)
        for order in LEFT_ROW_OVERRIDES.keys() & set(range(start, end + 1)):
            entry_raw, values = LEFT_ROW_OVERRIDES[order]
            left[order] = {
                "entry_raw": entry_raw,
                "values": values,
                "method": "scan_verified_override",
            }
            left_notes.append({"page": left_page, "order": order, "issue": "damaged_left_row_restored_from_scan"})
        for order in RIGHT_ALL_X_OVERRIDES.intersection(range(start, end + 1)):
            if order not in right:
                right[order] = {
                    "values": ["(X)"] * 7,
                    "method": "tesseract_review_verified_all_suppressed",
                }
                right_notes.append({"page": right_page, "order": order, "issue": "omitted_all_suppressed_row_restored"})
        for order in RIGHT_VALUE_OVERRIDES.keys() & set(range(start, end + 1)):
            right[order] = {
                "values": RIGHT_VALUE_OVERRIDES[order],
                "method": "scan_verified_override",
            }
            right_notes.append({"page": right_page, "order": order, "issue": "damaged_right_order_restored_from_scan"})
        notes.extend(left_notes)
        notes.extend(right_notes)
        for order in range(start, end + 1):
            left_row = left.get(order)
            right_row = right.get(order)
            raw_entry = left_row["entry_raw"] if left_row else ""
            entry, correction_method = correct_entry(raw_entry, municipalities, order) if raw_entry else ("", "missing")
            row = {"order_number": order, "entry": entry, "entry_ocr": raw_entry}
            row.update(dict.fromkeys(LEFT_COLUMNS, ""))
            row.update(dict.fromkeys(RIGHT_COLUMNS, ""))
            if left_row:
                row.update(dict(zip(LEFT_COLUMNS, left_row["values"])))
            if right_row:
                row.update(dict(zip(RIGHT_COLUMNS, right_row["values"])))
            row.update(
                {
                    "source_page_left": left_page,
                    "source_page_right": right_page,
                    "entry_correction_method": correction_method,
                    "left_extraction_method": left_row["method"] if left_row else "missing",
                    "right_extraction_method": right_row["method"] if right_row else "missing",
                    "needs_review": "yes" if not left_row or not right_row or correction_method == "ocr_unmatched" else "no",
                }
            )
            rows.append(row)

    if config.unpaired_left:
        page, start, end = config.unpaired_left
        left, left_notes = parse_left(document, page, start, end)
        notes.extend(left_notes)
        for order in range(start, end + 1):
            left_row = left.get(order)
            raw_entry = left_row["entry_raw"] if left_row else ""
            entry, correction_method = correct_entry(raw_entry, municipalities, order) if raw_entry else ("", "missing")
            row = {"order_number": order, "entry": entry, "entry_ocr": raw_entry}
            row.update(dict.fromkeys(LEFT_COLUMNS, ""))
            row.update(dict.fromkeys(RIGHT_COLUMNS, ""))
            if left_row:
                row.update(dict(zip(LEFT_COLUMNS, left_row["values"])))
            row.update(
                {
                    "source_page_left": page,
                    "source_page_right": "",
                    "entry_correction_method": correction_method,
                    "left_extraction_method": left_row["method"] if left_row else "missing",
                    "right_extraction_method": "missing_unpaired_page",
                    "needs_review": "yes",
                }
            )
            rows.append(row)

    tables_dir = out_dir / "tables"
    tables_dir.mkdir(parents=True, exist_ok=True)
    csv_path = tables_dir / "industrial_table_2_merged.csv"
    fieldnames = (
        ("order_number", "entry")
        + LEFT_COLUMNS
        + RIGHT_COLUMNS
        + (
            "entry_ocr",
            "source_page_left",
            "source_page_right",
            "entry_correction_method",
            "left_extraction_method",
            "right_extraction_method",
            "needs_review",
        )
    )
    with csv_path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    missing_left = [row["order_number"] for row in rows if row["left_extraction_method"] == "missing"]
    missing_right = [row["order_number"] for row in rows if row["right_extraction_method"] == "missing"]
    unmatched_entries = [row["order_number"] for row in rows if row["entry_correction_method"] == "ocr_unmatched"]
    audit = {
        "source_pdf": str(config.pdf),
        "table": "Industrial Census 1975 - Table 2",
        "row_count": len(rows),
        "order_range": [rows[0]["order_number"], rows[-1]["order_number"]],
        "order_sequence_complete": [row["order_number"] for row in rows] == list(range(rows[0]["order_number"], rows[-1]["order_number"] + 1)),
        "missing_left_orders": missing_left,
        "missing_right_orders_with_supplied_page": missing_right,
        "unpaired_right_orders": [row["order_number"] for row in rows if row["right_extraction_method"] == "missing_unpaired_page"],
        "unmatched_entry_orders": unmatched_entries,
        "notes": notes,
    }
    (tables_dir / "merge_audit.json").write_text(json.dumps(audit, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    manifest = {
        "source_pdf": str(config.pdf),
        "ocr_json": str(raw_json),
        "outputs": [{"table": 2, "census_type": "industrial", "csv": str(csv_path), "rows": len(rows)}],
        "source_contains_only_table_2_fragments": True,
        "appendix_present": False,
    }
    (tables_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return audit


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stem", choices=[config.stem for config in CONFIGS], action="append")
    parser.add_argument("--tesseract-review", action="store_true")
    args = parser.parse_args()
    selected = [config for config in CONFIGS if not args.stem or config.stem in args.stem]
    for config in selected:
        audit = extract(config, args.tesseract_review)
        print(json.dumps({"stem": config.stem, **audit}, ensure_ascii=False))


if __name__ == "__main__":
    main()
