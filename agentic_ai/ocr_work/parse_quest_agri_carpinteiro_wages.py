#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
import unicodedata
from pathlib import Path


SOURCE = Path(
    "/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/"
    "Andrei Arminio Laskievic/sumoc_shared/output_ocr/quest_agri_wages.csv"
)
OUTPUT = SOURCE.with_name("quest_agri_wages_carpinteiro_extracted.csv")


def strip_accents(value: str) -> str:
    return "".join(
        ch for ch in unicodedata.normalize("NFKD", value) if not unicodedata.combining(ch)
    )


def norm(value: str) -> str:
    value = strip_accents(value).lower()
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def sentence_bounds(text: str, start: int) -> tuple[int, int]:
    def period_boundary(pos: int) -> bool:
        before = text[pos - 1] if pos > 0 else ""
        after = text[pos + 1] if pos + 1 < len(text) else ""
        return not (before.isdigit() and after.isdigit())

    left_candidates = [text.rfind(";", 0, start), text.rfind("\n", 0, start)]
    left_periods = [i for i, ch in enumerate(text[:start]) if ch == "." and period_boundary(i)]
    if left_periods:
        left_candidates.append(left_periods[-1])
    left = max(left_candidates)

    right_candidates = [pos for pos in [text.find(";", start), text.find("\n", start)] if pos != -1]
    right_period = next((i for i in range(start, len(text)) if text[i] == "." and period_boundary(i)), -1)
    if right_period != -1:
        right_candidates.append(right_period)
    right = min(right_candidates) if right_candidates else len(text)
    return left + 1, right


def find_carpinteiro_clause(text: str) -> tuple[str, str]:
    normalized = norm(text)
    patterns = [
        r"\bcarpinteir[oa]s?\b",
        r"\bcarpinteiro\b",
        r"\bcapinteir[oa]s?\b",
        r"\bcarpinter[oa]s?\b",
        r"\bcarpinte[rn]r[oa]s?\b",
        r"\bcarpinte\b",
        r"\bcarpimeir[oa]s?\b",
    ]
    for pattern in patterns:
        match = re.search(pattern, normalized)
        if match:
            start, end = sentence_bounds(text, match.start())
            return text[start:end].strip(" ,;."), "matched_carpinteiro"
    return "", "no_carpinteiro_clause"


def money_to_reis(raw: str, context: str) -> int | None:
    value = raw.strip().lower().replace(".", "").replace(" ", "")
    value = value.replace(",", "")
    value = value.replace("réis", "").replace("reis", "")
    value = value.strip()
    if not value:
        return None
    if "$" in value:
        left, right = value.split("$", 1)
        left_digits = re.sub(r"\D", "", left)
        right_digits = re.sub(r"\D", "", right)
        if not left_digits:
            return None
        if not right_digits:
            return int(left_digits) * 1000
        return int(left_digits) * 1000 + int((right_digits + "000")[:3])
    if re.fullmatch(r"\d{1,3}:\d{3,}(?:\$\d{3})?", value):
        left, right = value.split(":", 1)
        return int(left) * 1_000_000 + int(right[:3]) * 1000
    compact = re.fullmatch(r"(\d{1,3})8(\d{3})", value)
    if compact:
        return int(compact.group(1)) * 1000 + int(compact.group(2))
    if re.fullmatch(r"\d{1,7}", value):
        if "reis" in norm(context) or "réis" in context.lower():
            return int(value)
        if len(value) >= 4:
            return int(value)
    return None


MONEY_PATTERN = re.compile(
    r"""
    (?:
        \d{1,3}\$\d{2,3}
        |
        \d{1,3}\.\d{3}
        |
        \d{1,3}\$
        |
        \d{1,3}:\d{3,}(?:\$\d{3})?
        |
        \d{1,3}8\d{3}
        |
        \d{3,7}\s*(?:r[eé]is)?
    )
    """,
    re.IGNORECASE | re.VERBOSE,
)


def extract_wages(clause: str) -> dict[str, str]:
    if not clause:
        return {
            "carpinteiro_wage_min_raw": "",
            "carpinteiro_wage_max_raw": "",
            "carpinteiro_wage_min_reis": "",
            "carpinteiro_wage_max_reis": "",
            "carpinteiro_wage_period": "",
            "wage_extraction_note": "no_clause",
        }

    matches = []
    for match in MONEY_PATTERN.finditer(clause):
        raw = match.group(0).strip()
        reis = money_to_reis(raw, clause)
        if reis is not None:
            matches.append((raw, reis))

    clause_n = norm(clause)
    period = ""
    if any(token in clause_n for token in ["por dia", "diario", "diarios", "diaria", "diarias", "a secco", "com comida"]):
        period = "daily"
    elif any(token in clause_n for token in ["mensal", "mensaes", "mensais", "por mez", "por mes"]):
        period = "monthly"
    elif any(token in clause_n for token in ["annual", "annua", "anuais", "por anno", "por ano"]):
        period = "annual"

    if not matches:
        return {
            "carpinteiro_wage_min_raw": "",
            "carpinteiro_wage_max_raw": "",
            "carpinteiro_wage_min_reis": "",
            "carpinteiro_wage_max_reis": "",
            "carpinteiro_wage_period": period,
            "wage_extraction_note": "clause_found_no_numeric_wage",
        }

    if len(matches) == 1:
        raw, reis = matches[0]
        return {
            "carpinteiro_wage_min_raw": raw,
            "carpinteiro_wage_max_raw": "",
            "carpinteiro_wage_min_reis": str(reis),
            "carpinteiro_wage_max_reis": "",
            "carpinteiro_wage_period": period,
            "wage_extraction_note": "single_value",
        }

    first, second = matches[0], matches[1]
    low, high = sorted([first, second], key=lambda item: item[1])
    note = "range_first_two_values"
    if "com comida" in clause_n or "a secco" in clause_n:
        note = "two_condition_values_sorted"
    return {
        "carpinteiro_wage_min_raw": low[0],
        "carpinteiro_wage_max_raw": high[0],
        "carpinteiro_wage_min_reis": str(low[1]),
        "carpinteiro_wage_max_reis": str(high[1]),
        "carpinteiro_wage_period": period,
        "wage_extraction_note": note,
    }


def main() -> None:
    with SOURCE.open(encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))

    output_rows = []
    for row in rows:
        clause, clause_note = find_carpinteiro_clause(row.get("SALARIOS", ""))
        extracted = extract_wages(clause)
        output_rows.append(
            {
                "state": row.get("state", ""),
                "municipio": row.get("municipio", ""),
                "SALARIOS": row.get("SALARIOS", ""),
                "carpinteiro_wage_clause": clause,
                "carpinteiro_wage_clause_note": clause_note,
                **extracted,
            }
        )

    fieldnames = [
        "state",
        "municipio",
        "SALARIOS",
        "carpinteiro_wage_clause",
        "carpinteiro_wage_clause_note",
        "carpinteiro_wage_min_raw",
        "carpinteiro_wage_max_raw",
        "carpinteiro_wage_min_reis",
        "carpinteiro_wage_max_reis",
        "carpinteiro_wage_period",
        "wage_extraction_note",
    ]
    with OUTPUT.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_rows)

    total = len(output_rows)
    clauses = sum(1 for row in output_rows if row["carpinteiro_wage_clause"])
    wages = sum(1 for row in output_rows if row["carpinteiro_wage_min_reis"])
    ranges = sum(1 for row in output_rows if row["carpinteiro_wage_max_reis"])
    print(f"Wrote {total} rows to {OUTPUT}")
    print(f"clauses_found={clauses} wages_extracted={wages} ranges_or_two_values={ranges}")


if __name__ == "__main__":
    main()
