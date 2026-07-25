#!/usr/bin/env python3
"""Validate questionario_agri OCR section CSVs."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path


SECTION_FIELDS = ["juros", "salarios", "terras", "transporte"]
NO_RATE_WORDS = (
    "taxa fixa",
    "taxas fixas",
    "emprestimos",
    "prestamistas",
    "prestamistas",
)
SUSPICIOUS_CURRENCY_PATTERNS = [
    r":[$]",
    r"\ba\$\d",
    r"&\$\d",
    r"\bg\$\d",
    r"\bz\$\d",
    r"\b[riI]\$\d",
    r"\$[a-zA-Z]",
    r"0q0",
    r"1\$ a",
    r"\bI\d\$",
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path", type=Path)
    args = parser.parse_args()

    with args.csv_path.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))

    print(f"rows {len(rows)}")
    if not rows:
        return

    print(f"fields {list(rows[0].keys())}")
    print("empty", {field: [row["municipio"] for row in rows if not row.get(field, "").strip()] for field in SECTION_FIELDS})
    print("total_dollar_signs", sum(sum(row.get(field, "").count("$") for field in SECTION_FIELDS) for row in rows))

    juros_check = []
    for row in rows:
        juros = row.get("juros", "")
        lower = juros.lower()
        if not juros.strip():
            continue
        if "%" in juros or "por cento" in lower or any(word in lower for word in NO_RATE_WORDS):
            continue
        juros_check.append((row["municipio"], juros))
    print("juros_needing_review", juros_check)

    suspicious = []
    for row in rows:
        for field in ("salarios", "terras", "transporte"):
            text = row.get(field, "")
            hits = [pattern for pattern in SUSPICIOUS_CURRENCY_PATTERNS if re.search(pattern, text)]
            if hits:
                suspicious.append((row["municipio"], field, hits, text[:180]))
    print("suspicious_currency", suspicious)


if __name__ == "__main__":
    main()
