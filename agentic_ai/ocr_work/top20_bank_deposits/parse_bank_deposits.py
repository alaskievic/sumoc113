#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent
OCR_DIR = ROOT / "mistral_outputs"
CSV_DIR = ROOT / "csv"

SOURCES = [
    "bank_depost_1_1960",
    "bank_deposit_2_1960",
]


def parse_md_table(content: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for line in content.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if all(re.fullmatch(r":?-+:?", cell or "-") for cell in cells):
            continue
        rows.append(cells)
    return rows


def clean_space(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def clean_rank(value: str) -> tuple[str, str]:
    value = clean_space(value)
    marked = "yes" if "×" in value else "no"
    value = value.replace("×", "").strip()
    if value in {"", "-", "—"}:
        return "", marked
    return value, marked


def clean_amount(value: str) -> tuple[str, str, str]:
    raw = clean_space(value)
    marked = "yes" if "×" in raw else "no"
    cleaned = raw.replace("×", "").strip()
    integer = re.sub(r"\D+", "", cleaned)
    return cleaned, integer, marked


def split_bank_notes(value: str) -> tuple[str, str]:
    notes = ";".join(re.findall(r"\(([*]+)\)", value))
    bank = clean_space(re.sub(r"\s*\([*]+\)", "", value))
    return bank, notes


def iter_rows() -> list[dict[str, str]]:
    output: list[dict[str, str]] = []
    for source_stem in SOURCES:
        data = json.loads((OCR_DIR / f"{source_stem}_mistral_raw.json").read_text(encoding="utf-8"))
        source = Path(data["source"]).name
        for page in data["raw_response"]["pages"]:
            page_number = str(int(page["index"]) + 1)
            for table in page.get("tables", []):
                rows = parse_md_table(table["content"])
                for cells in rows[2:]:
                    if len(cells) < 6:
                        continue
                    if clean_space(cells[4]).upper().replace(" ", "") == "TOTAL":
                        amount, amount_int, amount_marked = clean_amount(cells[5])
                        output.append(
                            {
                                "source_image": source,
                                "page": page_number,
                                "table_id": table["id"],
                                "row_type": "total",
                                "rank_1960_12_31": "",
                                "rank_1960_06_30": "",
                                "rank_1959_12_31": "",
                                "rank_1959_06_30": "",
                                "bank": "TOTAL",
                                "bank_footnote_marks": "",
                                "deposits_millions_cruzeiros_raw": amount,
                                "deposits_millions_cruzeiros": amount_int,
                                "rank_or_amount_marked_x": amount_marked,
                            }
                        )
                        continue
                    if not any(clean_space(cell) for cell in cells[:5]):
                        continue

                    rank_1960_12_31, mark_1 = clean_rank(cells[0])
                    rank_1960_06_30, mark_2 = clean_rank(cells[1])
                    rank_1959_12_31, mark_3 = clean_rank(cells[2])
                    rank_1959_06_30, mark_4 = clean_rank(cells[3])
                    bank, notes = split_bank_notes(cells[4])
                    amount, amount_int, amount_marked = clean_amount(cells[5])

                    output.append(
                        {
                            "source_image": source,
                            "page": page_number,
                            "table_id": table["id"],
                            "row_type": "bank",
                            "rank_1960_12_31": rank_1960_12_31,
                            "rank_1960_06_30": rank_1960_06_30,
                            "rank_1959_12_31": rank_1959_12_31,
                            "rank_1959_06_30": rank_1959_06_30,
                            "bank": bank,
                            "bank_footnote_marks": notes,
                            "deposits_millions_cruzeiros_raw": amount,
                            "deposits_millions_cruzeiros": amount_int,
                            "rank_or_amount_marked_x": "yes"
                            if "yes" in {mark_1, mark_2, mark_3, mark_4, amount_marked}
                            else "no",
                        }
                    )
    return output


def main() -> None:
    rows = iter_rows()
    CSV_DIR.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "source_image",
        "page",
        "table_id",
        "row_type",
        "rank_1960_12_31",
        "rank_1960_06_30",
        "rank_1959_12_31",
        "rank_1959_06_30",
        "bank",
        "bank_footnote_marks",
        "deposits_millions_cruzeiros_raw",
        "deposits_millions_cruzeiros",
        "rank_or_amount_marked_x",
    ]
    out_path = CSV_DIR / "bank_deposits_1960.csv"
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} rows to {out_path}")


if __name__ == "__main__":
    main()
