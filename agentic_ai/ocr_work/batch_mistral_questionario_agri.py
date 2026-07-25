#!/usr/bin/env python3
"""Run Mistral OCR and wide CSV parsing for all questionario_agri PDFs."""

from __future__ import annotations

import argparse
import csv
import subprocess
import sys
from pathlib import Path


WORKSPACE = Path(__file__).resolve().parents[1]
INPUT_DIR = Path(
    "/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/"
    "Andrei Arminio Laskievic/sumoc_shared/questionario_agri"
)
OUTPUT_DIR = Path(
    "/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/"
    "Andrei Arminio Laskievic/sumoc_shared/output_ocr/questionario_agri/csv"
)


def state_from_pdf(pdf_path: Path) -> str:
    return pdf_path.stem.removeprefix("quest_agri_")


def run(cmd: list[str]) -> None:
    print("+ " + " ".join(cmd), flush=True)
    subprocess.run(cmd, cwd=WORKSPACE, check=True)


def summarize_csv(csv_path: Path) -> dict[str, object]:
    with csv_path.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f, delimiter=";"))
    summary: dict[str, object] = {
        "rows": len(rows),
        "columns": len(rows[0]) if rows else 0,
        "dollar_count": sum(sum(value.count("$") for value in row.values()) for row in rows),
    }
    for col in ("JUROS", "SALARIOS", "TERRAS", "TRANSPORTE"):
        summary[f"{col.lower()}_empty"] = sum(1 for row in rows if not row.get(col))
    return summary


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--force-ocr", action="store_true")
    parser.add_argument("--states", nargs="*", help="Optional state codes, e.g. al sp rj.")
    args = parser.parse_args()

    wanted = {state.lower() for state in args.states or []}
    pdfs = sorted(INPUT_DIR.glob("quest_agri_*.pdf"))
    if wanted:
        pdfs = [pdf for pdf in pdfs if state_from_pdf(pdf).lower() in wanted]
    if not pdfs:
        raise SystemExit("No PDFs matched.")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    summaries: list[tuple[str, dict[str, object]]] = []

    for pdf_path in pdfs:
        state = state_from_pdf(pdf_path)
        raw_json = WORKSPACE / "ocr_work" / f"quest_agri_{state}_mistral_raw.json"
        raw_txt = WORKSPACE / "ocr_work" / f"quest_agri_{state}_mistral_raw.txt"
        local_csv = WORKSPACE / "ocr_work" / f"quest_agri_{state}_mistral_wide.csv"
        final_csv = OUTPUT_DIR / f"quest_agri_{state}_mistral_wide.csv"

        print(f"\n=== {state}: {pdf_path.name} ===", flush=True)
        if args.force_ocr or not (raw_json.exists() and raw_txt.exists()):
            run(
                [
                    sys.executable,
                    "ocr_work/ocr_quest_agri_mistral.py",
                    "--pdf",
                    str(pdf_path),
                    "--model",
                    "mistral-ocr-2512",
                    "--json-out",
                    str(raw_json),
                    "--text-out",
                    str(raw_txt),
                    "--confidence-scores",
                    "page",
                ]
            )
        else:
            print(f"Skipping OCR; found {raw_json.name} and {raw_txt.name}", flush=True)

        run(
            [
                sys.executable,
                "ocr_work/parse_quest_agri_mistral_wide.py",
                "--raw-text",
                str(raw_txt),
                "--csv-out",
                str(local_csv),
            ]
        )
        final_csv.write_bytes(local_csv.read_bytes())
        summary = summarize_csv(final_csv)
        summaries.append((state, summary))
        print(f"Copied {final_csv}", flush=True)
        print(f"Summary {state}: {summary}", flush=True)

    print("\n=== Batch summary ===", flush=True)
    for state, summary in summaries:
        print(f"{state}: {summary}", flush=True)


if __name__ == "__main__":
    main()
