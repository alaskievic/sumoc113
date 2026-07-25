#!/usr/bin/env python3
"""Combine corrected rural wages with carpenter wages and interest rates."""

from __future__ import annotations

import csv
import difflib
import sys
import re
from pathlib import Path


WORKSPACE = Path(__file__).resolve().parents[1]
SHARED_OUTPUT = Path(
    "/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/"
    "Andrei Arminio Laskievic/sumoc_shared/output_ocr"
)
CORRECTED_RURAL = SHARED_OUTPUT / "quest_agri_rural_cleaned.csv"
ORIGINAL_WIDE = SHARED_OUTPUT / "quest_agri_wages.csv"
DEFAULT_OUTPUT = WORKSPACE / "ocr_work" / "quest_agri_rural_carpinteiro_juros_cleaned.csv"

sys.path.insert(0, str(Path(__file__).resolve().parent))
import parse_quest_agri_mistral_wide as wide_parser  # noqa: E402
from extract_mistral_wide_prices import format_number, rate_tokens  # noqa: E402
from parse_quest_agri_carpinteiro_wages import (  # noqa: E402
    extract_wages as extract_carpinteiro_wages,
    find_carpinteiro_clause,
)


FIELDNAMES = [
    "state",
    "municipio",
    "SALARIOS",
    "rural_wage_clause",
    "rural_wage_min_reis",
    "rural_wage_max_reis",
    "rural_wage_period",
    "carpinteiro_wage_clause",
    "carpinteiro_wage_min_reis",
    "carpinteiro_wage_max_reis",
    "carpinteiro_wage_period",
    "JUROS",
    "juros_lower_bound",
    "juros_upper_bound",
    "juros_period",
    "TERRAS",
    "land_price_text",
    "land_price_lower_bound_reis",
    "land_price_upper_bound_reis",
    "land_price_unit",
    "land_price_not_per_hectare",
]


# Historical names and OCR heading errors that cannot be resolved by spelling alone.
RAW_HEADING_OVERRIDES = {
    ("CE", "Acaraty"): "Aracaty",
    ("CE", "Araripe"): "Araripe ou Brejo Secco",
    ("CE", "São Bernardo das Russas"): "Russas",
    ("CE", "Sao Francisco"): "S. Francisco de Uruburetama",
    ("ES", "Anchieta"): "Benevente",
    ("GO", "Alta-Mir"): "Mestre d'Armas",
    ("MG", "Baependy"): "Enopendy",
    ("MG", "Itabira"): "Itabira do Matto Dentro",
    ("MG", "Jacuhy"): "Jacoby",
    ("MT", "Rosario do Rio Acima"): "Villa do Rosario Oeste",
    ("PA", "Conceição"): "Conceição de Araguaya",
    ("PR", "Santo Antonio de Imbituva"): "Imbituva",
    ("RN", "Canguaretama"): "Penha",
    ("RN", "São Miguel"): "São Miguel de Pão dos Ferros",
    ("RN", "Pedro Velho"): "Villa Nova",
    ("SE", "Simão Dias"): "Annapolis (antigo Simão Dias)",
    ("SE", "Nossa Senhora das Dôres"): "Dôres",
    ("SP", "Capão Bonito"): "Capão Bonito do Paranapanema",
    ("SP", "Itanhaem"): "Conceição de Itanhaem",
    ("SP", "São Manoel do Paraiso"): "São Manuel",
}

# Two headings were omitted by Mistral. Their records sit between these headings.
RAW_INTERVAL_OVERRIDES = {
    ("MG", "Campos Gerais"): ("Campo Bello", "Capellinha da Graça"),
    ("PA", "Santarem"): ("Salinas", "S. Caetano de Odivellas"),
}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def name_similarity(left: str, right: str) -> float:
    return difflib.SequenceMatcher(
        None,
        wide_parser.comparable_name(left),
        wide_parser.comparable_name(right),
    ).ratio()


def align_original_rows(
    corrected: list[dict[str, str]], original: list[dict[str, str]]
) -> dict[int, dict[str, str]]:
    """Align original rows to the longer corrected sequence, allowing inserted rows."""

    result: dict[int, dict[str, str]] = {}
    states = sorted({row["state"].upper() for row in corrected})
    for state in states:
        targets = [(idx, row) for idx, row in enumerate(corrected) if row["state"].upper() == state]
        sources = [row for row in original if row["state"].upper() == state]
        n, m = len(sources), len(targets)
        negative = -10**9
        dp = [[negative] * (m + 1) for _ in range(n + 1)]
        back: dict[tuple[int, int], tuple[int, int]] = {}
        dp[0][0] = 0.0
        for j in range(1, m + 1):
            dp[0][j] = dp[0][j - 1] - 0.10
            back[(0, j)] = (0, j - 1)

        for i in range(1, n + 1):
            for j in range(1, m + 1):
                source = sources[i - 1]
                target = targets[j - 1][1]
                score = name_similarity(source["municipio"], target["municipio"])
                if source.get("SALARIOS") and source["SALARIOS"] == target.get("SALARIOS"):
                    score += 1.0
                choices = [
                    (dp[i][j - 1] - 0.10, (i, j - 1)),
                    (dp[i - 1][j - 1] + score, (i - 1, j - 1)),
                ]
                dp[i][j], back[(i, j)] = max(choices, key=lambda item: item[0])

        i, j = n, m
        while i:
            previous_i, previous_j = back[(i, j)]
            if previous_i == i - 1:
                corrected_idx = targets[j - 1][0]
                result[corrected_idx] = sources[i - 1]
            i, j = previous_i, previous_j
    return result


def raw_records(state: str) -> tuple[list[str], list[tuple[str, int]]]:
    path = WORKSPACE / "ocr_work" / f"quest_agri_{state.lower()}_mistral_raw.txt"
    lines = path.read_text(encoding="utf-8").splitlines()
    content_start = next(
        (idx for idx, line in enumerate(lines) if wide_parser.is_content_start(line)), 0
    )
    return lines, wide_parser.content_heading_positions(lines, content_start)


def find_heading_index(
    state: str, municipio: str, positions: list[tuple[str, int]]
) -> int:
    requested = RAW_HEADING_OVERRIDES.get((state, municipio), municipio)
    return max(
        range(len(positions)),
        key=lambda idx: name_similarity(requested, positions[idx][0]),
    )


def extract_raw_sections(
    state: str,
    municipio: str,
    lines: list[str],
    positions: list[tuple[str, int]],
) -> dict[str, str]:
    interval = RAW_INTERVAL_OVERRIDES.get((state, municipio))
    if interval:
        start_idx = find_heading_index(state, interval[0], positions)
        end_idx = find_heading_index(state, interval[1], positions)
        start = positions[start_idx][1] + 1
        end = positions[end_idx][1]
        juros_starts = [
            line_idx
            for line_idx in range(start, end)
            if any(col == "JUROS" for col, _ in wide_parser.split_sections(lines[line_idx]))
        ]
        if juros_starts:
            start = juros_starts[-1]
    else:
        heading_idx = find_heading_index(state, municipio, positions)
        start = positions[heading_idx][1] + 1
        end = positions[heading_idx + 1][1] if heading_idx + 1 < len(positions) else len(lines)
    return dict(wide_parser.parse_block(lines[start:end]))


def extract_interest(text: str) -> dict[str, str]:
    """Extract the first reported rate or range, ignoring unrelated OCR numbers."""

    plausible = [(raw, value) for raw, value in rate_tokens(text) if value and value <= 100]
    chosen = plausible[:2]
    if not chosen:
        lower = upper = ""
    else:
        values = [value for _, value in chosen]
        lower = format_number(min(values))
        upper = format_number(max(values))

    normalized = wide_parser.ascii_norm(text).lower()
    monthly = bool(re.search(r"\b(me[szc]\w*|mens\w*)\b", normalized))
    annual = bool(
        re.search(
            r"\b(an+n?\w*|anu\w*|ano?s?|anim\w*|anma\w*|animal\w*|asso|oanno)\b",
            normalized,
        )
    )
    if monthly and annual:
        period = "monthly;annual"
    elif monthly:
        period = "monthly"
    elif annual:
        period = "annual"
    elif chosen:
        # Where the OCR dropped the period wording, rates up to 3% match the
        # monthly convention in this source; larger rates match annual entries.
        period = "monthly" if max(value for _, value in chosen) <= 3 else "annual"
    else:
        period = ""
    return {"lower": lower, "upper": upper, "period": period}


LAND_MONEY_RE = re.compile(
    r"""
    (?<!\w)
    (
        \d{1,3}(?::\d{3})+\$\d{1,3}
        |\d{1,3}(?:[ .:]\d{3})+\$\d{1,3}
        |\d{1,3}[ .:]\d{4}[58]\d{3}
        |\d{1,3}(?:[ .:]\d{3})+[58]\d{3}
        |\d{1,6}\$\d{1,3}
        |\d{1,4}[58]\d{2,4}
        |\d{1,3}(?:\.\d{3})+
        |\d{1,6}\s*r[eé]is
    )
    (?!\w)
    """,
    re.IGNORECASE | re.VERBOSE,
)


def land_price_segment(text: str) -> str:
    normalized = wide_parser.ascii_norm(text)
    heading = re.search(r"\bPre[cç]os?\s*[—-]", normalized, re.IGNORECASE)
    if not heading:
        return ""
    start = heading.start()
    tail = text[start:]
    stops = [
        match.start()
        for pattern in (
            r"\bTRA[N]?S?PORTES?[* ]*[—-]",
            r"\bQUALIDADES?\s*[—-]",
            r"#{1,3}\s",
        )
        for match in [re.search(pattern, tail[heading.end() - heading.start() :], re.IGNORECASE)]
        if match
    ]
    if stops:
        # Stop offsets were measured after the price heading.
        end = heading.end() - heading.start() + min(stops)
        tail = tail[:end]
    return re.sub(r"\s+", " ", tail).strip()


def parse_land_money(raw: str) -> int | None:
    compact = re.sub(r"\s+", "", raw.lower())
    compact = compact.replace("réis", "").replace("reis", "")
    if "$" in compact:
        left, right = compact.split("$", 1)
        left_digits = re.sub(r"\D", "", left)
        right_digits = re.sub(r"\D", "", right)
        if not left_digits:
            return None
        return int(left_digits) * 1000 + int((right_digits + "000")[:3])
    digits = re.sub(r"[.:]", "", compact)
    if not digits.isdigit():
        return None

    # Mistral frequently read the mil-réis marker as 8 or 5:
    # 28000 -> 2$000, 1458000 -> 145$000, 405000 -> 40$000.
    marker_pos = len(digits) - 4
    if marker_pos > 0 and digits[marker_pos] in {"5", "8"}:
        left = digits[:marker_pos]
        if " " in raw and left.endswith("0") and len(left) > 1:
            left = left[:-1]
        return int(left) * 1000 + int(digits[marker_pos + 1 :])
    return int(digits)


def extract_land_price(text: str) -> dict[str, str]:
    segment = land_price_segment(text)
    normalized = wide_parser.ascii_norm(segment).lower()
    if re.match(r"precos?\s*[—-]\s*(?:o\s+)?transporte\b", normalized):
        segment = ""
        normalized = ""

    def price_clause(position: int) -> str:
        separators = [match.start() for match in re.finditer(r";|(?<!\d)\.(?=\s+[A-ZÁÀÂÃÉÊÍÓÔÕÚÜÇ])", segment)]
        left = max((pos for pos in separators if pos < position), default=-1) + 1
        right = min((pos for pos in separators if pos > position), default=len(segment))
        return segment[left:right]

    values = []
    unit_contexts = []
    for match in LAND_MONEY_RE.finditer(segment):
        following = wide_parser.ascii_norm(segment[match.end() : match.end() + 30]).lower()
        if re.match(r"\s*(bracas?|leguas?|metros?|hectares?|tarefas?|pes)\b", following):
            continue
        value = parse_land_money(match.group(1))
        if value is not None and value > 0:
            values.append(value)
            unit_contexts.append(price_clause(match.start()))
    for match in re.finditer(r"\b(?:de\s+)?(\d+)\s+a\s+\d+\s*r[eé]is\b", segment, re.IGNORECASE):
        values.append(int(match.group(1)))
        unit_contexts.append(price_clause(match.start()))
    if values:
        lower = str(min(values))
        upper = str(max(values))
    else:
        lower = upper = ""

    unit_text = wide_parser.ascii_norm(" ".join(dict.fromkeys(unit_contexts))).lower()
    unit_patterns = [
        ("hectare", r"\b(?:hectare|kectare|bexare|bertare)s?\b"),
        ("alqueire", r"\balqueires?\b"),
        ("tarefa", r"\btarefas?\b"),
        ("braca", r"\bbracas?\b"),
        ("legua", r"\bleguas?\b"),
        ("metro_quadrado", r"\bmetros?\s+quadrados?\b"),
        ("metro", r"\bmetros?\b(?!\s+quadrad)"),
        ("seringueiras", r"\b(seringueiras?|seringueiros?|seringaes|seringais)\b"),
        ("property", r"\b(propriedades?|em globo)\b"),
    ]
    units = [name for name, pattern in unit_patterns if re.search(pattern, unit_text)]
    if not units:
        units = [name for name, pattern in unit_patterns if re.search(pattern, normalized)]
    if "seringueiras" not in units and re.search(r"\bestradas?\b", unit_text) and "seringueir" in normalized:
        units.append("seringueiras")
    unit = ";".join(units) if units else ("unspecified" if values else "")
    if not values:
        non_hectare = ""
    else:
        non_hectare = "0" if units == ["hectare"] else "1"
    return {
        "text": segment,
        "lower": lower,
        "upper": upper,
        "unit": unit,
        "non_hectare": non_hectare,
    }


def build_rows() -> tuple[list[dict[str, str]], int]:
    corrected = read_csv(CORRECTED_RURAL)
    original = read_csv(ORIGINAL_WIDE)
    original_by_corrected = align_original_rows(corrected, original)
    raw_cache = {state: raw_records(state) for state in {r["state"].upper() for r in corrected}}
    recovered = 0
    output: list[dict[str, str]] = []

    for idx, rural in enumerate(corrected):
        state = rural["state"].upper()
        original_row = original_by_corrected.get(idx)
        if original_row:
            salarios = original_row.get("SALARIOS", "") or rural.get("SALARIOS", "")
            juros = original_row.get("JUROS", "")
            terras = original_row.get("TERRAS", "")
        else:
            lines, positions = raw_cache[state]
            sections = extract_raw_sections(state, rural["municipio"], lines, positions)
            salarios = sections.get("SALARIOS", "") or rural.get("SALARIOS", "")
            juros = sections.get("JUROS", "")
            terras = sections.get("TERRAS", "")
            recovered += 1

        carpenter_clause, _ = find_carpinteiro_clause(salarios)
        carpenter = extract_carpinteiro_wages(carpenter_clause)
        rate = extract_interest(juros)
        land = extract_land_price(terras)
        output.append(
            {
                "state": state,
                "municipio": rural["municipio"],
                "SALARIOS": salarios,
                "rural_wage_clause": rural.get("rural_wage_clause", ""),
                "rural_wage_min_reis": rural.get("rural_wage_min_reis", ""),
                "rural_wage_max_reis": rural.get("rural_wage_max_reis", ""),
                "rural_wage_period": rural.get("rural_wage_period", ""),
                "carpinteiro_wage_clause": carpenter_clause,
                "carpinteiro_wage_min_reis": carpenter["carpinteiro_wage_min_reis"],
                "carpinteiro_wage_max_reis": carpenter["carpinteiro_wage_max_reis"],
                "carpinteiro_wage_period": carpenter["carpinteiro_wage_period"],
                "JUROS": juros,
                "juros_lower_bound": rate["lower"],
                "juros_upper_bound": rate["upper"],
                "juros_period": rate["period"],
                "TERRAS": terras,
                "land_price_text": land["text"],
                "land_price_lower_bound_reis": land["lower"],
                "land_price_upper_bound_reis": land["upper"],
                "land_price_unit": land["unit"],
                "land_price_not_per_hectare": land["non_hectare"],
            }
        )
    return output, recovered


def main() -> None:
    rows, recovered = build_rows()
    with DEFAULT_OUTPUT.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {DEFAULT_OUTPUT}")
    print(f"municipalities_recovered_from_raw={recovered}")
    for field in ("SALARIOS", "carpinteiro_wage_min_reis", "JUROS", "juros_lower_bound"):
        print(f"{field}_empty={sum(not row[field] for row in rows)}")


if __name__ == "__main__":
    main()
