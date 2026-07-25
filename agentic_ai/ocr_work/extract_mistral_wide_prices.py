#!/usr/bin/env python3
"""Combine questionario_agri Mistral wide CSVs and extract selected price fields."""

from __future__ import annotations

import argparse
import csv
import glob
import re
import unicodedata
from pathlib import Path


DEFAULT_INPUT_GLOB = "ocr_work/quest_agri_*_mistral_wide.csv"
DEFAULT_OUTPUT = "ocr_work/questionario_agri_mistral_wide_prices_combined.csv"

TEXT_COLUMNS = ["CUSTO_DOS_TECIDOS", "JUROS", "SALARIOS", "TERRAS"]

FIELDNAMES = [
    "state",
    "municipio",
    *TEXT_COLUMNS,
    "tecidos_min_raw",
    "tecidos_max_raw",
    "tecidos_min_value",
    "tecidos_max_value",
    "tecidos_match_text",
    "juros_min_raw",
    "juros_max_raw",
    "juros_min_value",
    "juros_max_value",
    "juros_period",
    "juros_match_text",
    "salario_trabalhador_rural_min_raw",
    "salario_trabalhador_rural_max_raw",
    "salario_trabalhador_rural_min_value",
    "salario_trabalhador_rural_max_value",
    "salario_trabalhador_rural_period",
    "salario_trabalhador_rural_match_text",
    "terras_preco_min_raw",
    "terras_preco_max_raw",
    "terras_preco_min_value",
    "terras_preco_max_value",
    "terras_preco_match_text",
]

PRICE_TOKEN_RE = re.compile(
    r"""
    (?<!\w)
    (?:
        \d{1,3}(?::\d{3})+\$\d{1,3}
        |\d{1,6}\$\d{1,3}
        |\d{1,4}8\d{3,6}
        |\d+(?:[.,]\d+)?
    )
    (?!\w)
    """,
    re.VERBOSE,
)

JUROS_TOKEN_RE = re.compile(
    r"""
    (?<!\w)
    (?:
        \d+½
        |
        \d+\s+\d/2
        |\d+/\d+
        |\d+(?:[.,]\d+)?(?:\s*%)?
    )
    (?!\w)
    """,
    re.VERBOSE,
)

NUMBER_WORD_VALUES = {
    "um": 1,
    "uma": 1,
    "dois": 2,
    "duas": 2,
    "tres": 3,
    "trez": 3,
    "quatro": 4,
    "cinco": 5,
    "seis": 6,
    "sete": 7,
    "oito": 8,
    "nove": 9,
    "dez": 10,
    "onze": 11,
    "doze": 12,
    "quinze": 15,
    "vinte": 20,
    "trinta": 30,
}

NUMBER_WORD_RE = re.compile(
    r"\b((?:de\s+)?(?:(?:um|uma|dois|duas|tres|trez|quatro|cinco|seis|sete|oito|nove|dez|onze|doze|quinze|vinte|trinta|meio|e|a)\s+)+)por\s+cento\b"
)

NO_VALUE_RE = re.compile(
    r"\b(nao|não)\s+(ha|há|e|é|sao|são|existem?|costumam?|fazem?|contrah[ei]|emprest)",
    re.IGNORECASE,
)


def ascii_text(text: str) -> str:
    normalized = unicodedata.normalize("NFKD", text or "")
    return "".join(ch for ch in normalized if not unicodedata.combining(ch)).lower()


def compact_space(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").strip())


def state_from_path(path: Path) -> str:
    match = re.search(r"quest_agri_([a-z]{2})_mistral_wide\.csv$", path.name)
    return match.group(1) if match else ""


def parse_moneyish(raw: str) -> float | None:
    token = compact_space(raw).replace(" ", "")
    if not token:
        return None

    if "$" in token:
        left, right = token.split("$", 1)
        left_digits = re.sub(r"\D", "", left)
        right_digits = re.sub(r"\D", "", right)
        if not left_digits and not right_digits:
            return None
        left_value = int(left_digits or "0")
        right_value = int((right_digits + "000")[:3] or "0")
        return float(left_value * 1000 + right_value)

    digits = re.sub(r"\D", "", token)
    if not digits:
        return None

    # In this OCR, the mil-reis marker is often read as an 8:
    # 28000 -> 2$000, 608000 -> 60$000, 1008000 -> 100$000.
    if len(digits) >= 5 and digits.endswith(("000", "00")) and "8" in digits[:-3]:
        sep = digits.rfind("8", 0, -3)
        if sep > 0:
            left = digits[:sep]
            right = digits[sep + 1 :]
            if right and set(right) <= {"0"}:
                return float(int(left) * 1000)

    cleaned = token.replace(".", "").replace(",", ".")
    try:
        return float(cleaned)
    except ValueError:
        return float(digits)


def parse_rate(raw: str) -> float | None:
    token = compact_space(raw).replace("%", "")
    half = re.fullmatch(r"(\d+)½", token)
    if half:
        return float(half.group(1)) + 0.5
    mixed = re.fullmatch(r"(\d+)\s+(\d)/(\d)", token)
    if mixed:
        return float(mixed.group(1)) + float(mixed.group(2)) / float(mixed.group(3))
    frac = re.fullmatch(r"(\d+)/(\d)", token)
    if frac:
        return float(frac.group(1)) / float(frac.group(2))
    token = token.replace(".", "").replace(",", ".")
    try:
        return float(token)
    except ValueError:
        return None


def extrema(tokens: list[tuple[str, float | None]]) -> tuple[str, str, str, str]:
    values = [(raw, value) for raw, value in tokens if value is not None]
    if not values:
        return "", "", "", ""
    min_raw, min_value = min(values, key=lambda item: item[1])
    max_raw, max_value = max(values, key=lambda item: item[1])
    return min_raw, max_raw, format_number(min_value), format_number(max_value)


def format_number(value: float) -> str:
    return str(int(value)) if value.is_integer() else f"{value:g}"


def price_tokens(text: str) -> list[tuple[str, float | None]]:
    return [(m.group(0), parse_moneyish(m.group(0))) for m in PRICE_TOKEN_RE.finditer(text or "")]


def rate_tokens(text: str) -> list[tuple[str, float | None]]:
    tokens = [(m.group(0), parse_rate(m.group(0))) for m in JUROS_TOKEN_RE.finditer(text or "")]
    tokens.extend(word_rate_tokens(text or ""))
    return tokens


def parse_number_word_phrase(phrase: str) -> list[tuple[str, float]]:
    phrase = re.sub(r"\bde\s+", "", phrase.strip())
    parts = re.split(r"\s+a\s+", phrase)
    values = []
    for part in parts:
        words = [word for word in part.split() if word != "e"]
        if not words:
            continue
        value = 0.0
        raw_words = []
        for word in words:
            if word in NUMBER_WORD_VALUES:
                value += NUMBER_WORD_VALUES[word]
                raw_words.append(word)
            elif word == "meio":
                value += 0.5
                raw_words.append(word)
        if raw_words and value:
            values.append((" ".join(raw_words), value))
    return values


def word_rate_tokens(text: str) -> list[tuple[str, float]]:
    normalized = ascii_text(text)
    tokens: list[tuple[str, float]] = []
    for match in NUMBER_WORD_RE.finditer(normalized):
        tokens.extend(parse_number_word_phrase(match.group(1)))
    return tokens


def first_price_set(text: str) -> dict[str, str]:
    tokens = price_tokens(text)
    chosen = tokens[:2]
    if len(chosen) == 1:
        chosen = [chosen[0], chosen[0]]
    min_raw, max_raw, min_value, max_value = extrema(chosen)
    return {
        "tecidos_min_raw": min_raw,
        "tecidos_max_raw": max_raw,
        "tecidos_min_value": min_value,
        "tecidos_max_value": max_value,
        "tecidos_match_text": compact_space(text)[:260] if chosen else "",
    }


def juros_extract(text: str) -> dict[str, str]:
    lowered = ascii_text(text)
    period = ""
    if re.search(r"\b(me[zsc]|mensal|mensae?s|mezes|meses)\b", lowered):
        period = "monthly"
    if re.search(r"\b(ann?o|annuae?s|anuai?s|anual)\b", lowered):
        period = "yearly" if not period else f"{period};yearly"

    tokens = rate_tokens(text)
    if not tokens and NO_VALUE_RE.search(text or ""):
        tokens = []
    min_raw, max_raw, min_value, max_value = extrema(tokens)
    return {
        "juros_min_raw": min_raw,
        "juros_max_raw": max_raw,
        "juros_min_value": min_value,
        "juros_max_value": max_value,
        "juros_period": period,
        "juros_match_text": compact_space(text)[:260] if tokens else "",
    }


def salary_period(segment_ascii: str) -> str:
    daily_pos = min([p for p in [segment_ascii.find("diari"), segment_ascii.find("por dia")] if p >= 0], default=-1)
    monthly_pos = min([p for p in [segment_ascii.find("mens"), segment_ascii.find("mez")] if p >= 0], default=-1)
    if daily_pos >= 0 and monthly_pos >= 0:
        return "daily" if daily_pos < monthly_pos else "monthly"
    if daily_pos >= 0:
        return "daily"
    if monthly_pos >= 0:
        return "monthly"
    return ""


def salary_segment(text: str) -> str:
    normalized = ascii_text(text)
    patterns = [
        r"trabalhador\s+rural",
        r"trabalhador,?\s+rural",
        r"trabalhadores\s+ruraes",
        r"salari[oa]s?\s+d[eo]\s+trabalhador",
        r"um\s+trabalhador\s+rural",
        r"trabalhador",
    ]
    starts = [m.start() for pat in patterns for m in re.finditer(pat, normalized)]
    if not starts:
        return ""
    start = min(starts)
    end_candidates = []
    for sep in [";", "."]:
        pos = text.find(sep, start)
        if pos > start:
            end_candidates.append(pos + 1)
    end = min(end_candidates) if end_candidates else min(len(text), start + 260)
    return text[start:end]


def salario_extract(text: str) -> dict[str, str]:
    segment = salary_segment(text or "")
    segment_ascii = ascii_text(segment)
    period = salary_period(segment_ascii)

    type_positions = [pos for pos in [segment_ascii.find("diari"), segment_ascii.find("mens"), segment_ascii.find("por dia")] if pos >= 0]
    number_area = segment[: min(type_positions)] if type_positions else segment
    tokens = price_tokens(number_area)
    min_raw, max_raw, min_value, max_value = extrema(tokens)
    return {
        "salario_trabalhador_rural_min_raw": min_raw,
        "salario_trabalhador_rural_max_raw": max_raw,
        "salario_trabalhador_rural_min_value": min_value,
        "salario_trabalhador_rural_max_value": max_value,
        "salario_trabalhador_rural_period": period,
        "salario_trabalhador_rural_match_text": compact_space(segment)[:260] if tokens or period else "",
    }


def terras_segment(text: str) -> str:
    normalized = ascii_text(text)
    heading_matches = list(re.finditer(r"\bprecos\b", normalized))
    generic_matches = list(re.finditer(r"\bpreco\b", normalized))
    if heading_matches:
        start = heading_matches[-1].start()
    elif generic_matches:
        start = generic_matches[-1].start()
    else:
        return ""
    return text[start:]


def terras_extract(text: str) -> dict[str, str]:
    segment = terras_segment(text or "")
    tokens = price_tokens(segment)
    min_raw, max_raw, min_value, max_value = extrema(tokens)
    return {
        "terras_preco_min_raw": min_raw,
        "terras_preco_max_raw": max_raw,
        "terras_preco_min_value": min_value,
        "terras_preco_max_value": max_value,
        "terras_preco_match_text": compact_space(segment)[:320] if tokens else "",
    }


def extract_row(row: dict[str, str], state: str) -> dict[str, str]:
    out = {name: "" for name in FIELDNAMES}
    out["state"] = state
    out["municipio"] = row.get("municipio", "")
    for col in TEXT_COLUMNS:
        out[col] = row.get(col, "")
    out.update(first_price_set(row.get("CUSTO_DOS_TECIDOS", "")))
    out.update(juros_extract(row.get("JUROS", "")))
    out.update(salario_extract(row.get("SALARIOS", "")))
    out.update(terras_extract(row.get("TERRAS", "")))
    return out


def combine(input_glob: str, output: str) -> dict[str, int]:
    paths = sorted(Path().glob(input_glob) if not Path(input_glob).is_absolute() else glob.glob(input_glob))
    if paths and isinstance(paths[0], str):
        paths = [Path(p) for p in paths]
    if not paths:
        raise FileNotFoundError(f"No input files matched: {input_glob}")

    counts = {"files": len(paths), "rows": 0, "tecidos": 0, "juros": 0, "salarios": 0, "terras": 0}
    output_path = Path(output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", newline="", encoding="utf-8") as f_out:
        writer = csv.DictWriter(f_out, fieldnames=FIELDNAMES, delimiter=";")
        writer.writeheader()
        for path in paths:
            state = state_from_path(path)
            with path.open(newline="", encoding="utf-8") as f_in:
                reader = csv.DictReader(f_in, delimiter=";")
                for row in reader:
                    extracted = extract_row(row, state)
                    writer.writerow(extracted)
                    counts["rows"] += 1
                    counts["tecidos"] += bool(extracted["tecidos_min_raw"])
                    counts["juros"] += bool(extracted["juros_min_raw"])
                    counts["salarios"] += bool(extracted["salario_trabalhador_rural_min_raw"])
                    counts["terras"] += bool(extracted["terras_preco_min_raw"])
    return counts


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-glob", default=DEFAULT_INPUT_GLOB)
    parser.add_argument("--output", default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    counts = combine(args.input_glob, args.output)
    print(f"Wrote {args.output}")
    print(
        "Processed {files} files, {rows} rows. Extracted: "
        "tecidos={tecidos}, juros={juros}, salarios={salarios}, terras={terras}".format(**counts)
    )


if __name__ == "__main__":
    main()
