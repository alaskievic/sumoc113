#!/usr/bin/env python3
"""Parse JUROS, SALARIOS, TERRAS, and TRANSPORTE sections from Santa Catharina OCR text."""

from __future__ import annotations

import argparse
import csv
import re
import unicodedata
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Municipio:
    name: str
    ocr_heading: str


MUNICIPIOS = [
    Municipio("Ararangua", "Ararangua"),
    Municipio("Biguassu", "Biguassu"),
    Municipio("Blumenau", "Blumenau"),
    Municipio("Brusque", "Brusque"),
    Municipio("Camburiu", "Camburiu"),
    Municipio("Campo Alegre", "Campo Alegre"),
    Municipio("Campos Novos", "Campos Novos"),
    Municipio("Canoinhas", "Canoinhas"),
    Municipio("Curitybanos", "Coritybanos"),
    Municipio("Florianopolis", "Florianopolis"),
    Municipio("Garopaba", "Garopaba"),
    Municipio("Imaruhy", "Imaruhy"),
    Municipio("Itajahy", "Itajahy"),
    Municipio("Jaguaruna", "Jaguaruna"),
    Municipio("Joinville", "Joinville"),
    Municipio("Lages", "Iages"),
    Municipio("Laguna", "Laguna"),
    Municipio("Nova Trento", "Nova Trento"),
    Municipio("Palhoca", "Palhoca"),
    Municipio("Paraty", "Paraty"),
    Municipio("Porto Bello", "Porto Bello"),
    Municipio("S. Bento", "Sao Bento"),
    Municipio("S. Francisco", "Sao Francisco"),
    Municipio("S. Joaquim da Costa da Serra", "Sao Joaquim da Costa da Serra"),
    Municipio("S. Jose", "Sao José"),
    Municipio("Tijucas", "Tijucas"),
    Municipio("Tubarao", "Tubarao"),
    Municipio("Urussanga", "Urussanga"),
]


JUROS_STOP_PREFIXES = (
    "MADEIRA",
    "MADEIRAS",
    "MINAS",
    "MOLESTIA",
    "MOLESTIAS",
    "EPRAGAS",
    "NUCLEOS",
    "OPEROSIDADE",
    "PADRO",
    "PADRES",
    "PORTOS",
    "SEMENTE",
    "SEMEADURA",
    "SYSTEMA",
    "SISTEMA",
)

LABEL_PATTERNS = {
    "juros": re.compile(r"^[\s'\".]*(?:JURO[$S]|JUR[O0Q]S|JUROS|JUR0S|IUROS|UROS|jUROS)\s*[-—:=]*\s*", re.I),
    "salarios": re.compile(r"^[\s'\".]*(?:[$S]ALARIOS?|SALARIOS?|SALARIO)\s*[-—:=]*\s*", re.I),
    "terras": re.compile(r"^[\s'\".]*TERRA[$S]?\s*[-—:=]*\s*", re.I),
    "transporte": re.compile(r"^[\s'\".]*(?:TRAN[$S]PORTES?|TRANSPORTE)\s*[-—:=]*\s*", re.I),
}


def ascii_norm(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return re.sub(r"\s+", " ", text).strip().upper()


def compact_prefix(text: str, length: int = 70) -> str:
    text = ascii_norm(text)
    text = text.replace("$", "S").replace("0", "O").replace("1", "I")
    return re.sub(r"[^A-Z]", "", text[:length])


def line_kind(line: str) -> str | None:
    c = compact_prefix(line)
    if c.startswith(("JUROS", "JURQS", "IUROS", "UROS")):
        return "juros"
    if c.startswith(("SALARIOS", "SALARIO")):
        return "salarios"
    if c.startswith("TERRA"):
        return "terras"
    if c.startswith(("TRANSPORTE", "TRANSPORTES")):
        return "transporte"
    return None


def is_noise(line: str) -> bool:
    s = line.strip()
    if not s or s.startswith("=== Page"):
        return True
    return bool(re.fullmatch(r"[-.\d\"'\s]{1,8}", s))


def clean_label(line: str, kind: str) -> str:
    line = LABEL_PATTERNS[kind].sub("", line, count=1)
    return line.strip(" -—:=\t")


def is_stop(line: str, current: str) -> bool:
    kind = line_kind(line)
    if kind and kind != current:
        return True
    prefix = compact_prefix(line)
    if current == "juros":
        return any(prefix.startswith(stop) for stop in JUROS_STOP_PREFIXES)
    if current in {"salarios", "terras", "transporte"}:
        return prefix.startswith(("NOTA", "LIMITES", "MEDIDASAGRARIAS"))
    return False


def fix_currency_tokens(text: str) -> str:
    def normalize_side(value: str) -> str:
        return (
            value.replace("o", "0")
            .replace("O", "0")
            .replace("c", "0")
            .replace("C", "0")
            .replace("I", "1")
            .replace("l", "1")
            .replace("i", "1")
            .replace("r", "1")
            .replace("R", "1")
            .replace("z", "2")
            .replace("Z", "2")
            .replace("&", "8")
        )

    def repl(match: re.Match[str]) -> str:
        token = match.group(0)
        left, right = token.split("$", 1)
        return f"{normalize_side(left)}${normalize_side(right)}"

    text = re.sub(r"\b[A-Za-z0-9&:]+[$][A-Za-z0-9&:xX]+\b", repl, text)
    text = re.sub(r"(?<!\w)[$][A-Za-z0-9&:xX]+\b", lambda m: "$" + normalize_side(m.group(0)[1:]), text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def fix_percent_tokens(text: str) -> str:
    text = text.replace("Ataxade", "A taxa de").replace("Ataxa", "A taxa")
    text = text.replace("taxausual", "taxa usual").replace("usualéde", "usual é de")
    text = text.replace("_", " ")
    text = text.replace("acanno", "ao anno").replace("aanno", "ao anno").replace("oanno", "anno")
    text = re.sub(r"\b[Iil](?=\s*(?:%|a|ao|ann|°|º|\"|'|]))", "1", text)
    text = re.sub(r"\bde\s*([568]|12)\s*[,\"'\[\]°º]*\s*(?=a?o?\s*anno|annuaes)", r"de \1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|12)\s*([°º][\[\]\"'!/°]*|[\]\"]+)?\s*(?=ao anno|annuaes|por cento)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|12)\s+(?=ao anno|annuaes)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|12)(?=ao anno|annuaes)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\bde([568]|12)%?\s*(?=ao anno|annuaes)", r"de \1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|12)\s+por cento", r"\1% por cento", text, flags=re.I)
    text = text.replace("por .cento", "por cento").replace("por ceuto", "por cento")
    text = text.replace("A tara", "A taxa")
    text = text.replace("éde ", "é de ").replace("ede ", "é de ")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def fix_text(text: str, kind: str) -> str:
    text = fix_currency_tokens(text)
    if kind == "juros":
        text = fix_percent_tokens(text)
    return text


def collect(lines: list[str], start_idx: int, kind: str, stop_at_note: bool = False) -> tuple[str, int]:
    out: list[str] = []
    idx = start_idx
    first = True
    while idx < len(lines):
        line = lines[idx]
        if is_noise(line):
            idx += 1
            continue
        if not first and is_stop(line, kind):
            break
        if stop_at_note and compact_prefix(line).startswith(("NOTA", "LIMITES")):
            break
        current_kind = line_kind(line)
        if current_kind == kind or first:
            line = clean_label(line, kind)
        out.append(line)
        first = False
        idx += 1
    return fix_text(" ".join(out), kind), idx


def collect_salarios(lines: list[str], start_idx: int) -> tuple[str, int]:
    out: list[str] = []
    idx = start_idx
    first = True
    while idx < len(lines):
        line = lines[idx]
        if is_noise(line):
            idx += 1
            continue
        if not first and is_stop(line, "salarios"):
            break
        if line_kind(line) in {"terras", "transporte"}:
            break
        if first or line_kind(line) == "salarios":
            line = clean_label(line, "salarios")
        out.append(line)
        idx += 1
        first = False
        if re.search(r"C[UO]MPR|CUNPR|PAG[O0]S", compact_prefix(line)):
            break
    return fix_text(" ".join(out), "salarios"), idx


def find_heading_positions(lines: list[str]) -> list[tuple[Municipio, int]]:
    start = next(i for i, line in enumerate(lines) if line.strip() == "=== Page 7 ===")
    positions: list[tuple[Municipio, int]] = []
    cursor = start
    for municipio in MUNICIPIOS:
        target = ascii_norm(municipio.ocr_heading)
        found = None
        for idx in range(cursor, len(lines)):
            if ascii_norm(lines[idx]) == target:
                found = idx
                break
        if found is None:
            raise RuntimeError(f"Could not find heading for {municipio.name!r}")
        positions.append((municipio, found))
        cursor = found + 1
    return positions


def find_kind(lines: list[str], kind: str, start: int = 0) -> int | None:
    for idx in range(start, len(lines)):
        if line_kind(lines[idx]) == kind:
            return idx
    return None


def non_noise_join(lines: list[str], kind: str) -> str:
    return fix_text(" ".join(line for line in lines if not is_noise(line)), kind)


def first_note_or_end(lines: list[str], start: int) -> int:
    for idx in range(start, len(lines)):
        if compact_prefix(lines[idx]).startswith(("NOTA", "LIMITES", "MEDIDASAGRARIAS")):
            return idx
    return len(lines)


def parse_block(block: list[str]) -> dict[str, str]:
    juros_idx = find_kind(block, "juros")
    salarios_idx = find_kind(block, "salarios")
    terras_idx = find_kind(block, "terras", (salarios_idx or 0) + 1)
    transporte_idx = find_kind(block, "transporte", (terras_idx or salarios_idx or 0) + 1)

    result = {"juros": "", "salarios": "", "terras": "", "transporte": ""}

    if juros_idx is not None:
        result["juros"], _ = collect(block, juros_idx, "juros")

    end = 0
    if salarios_idx is not None:
        result["salarios"], end = collect_salarios(block, salarios_idx)

    if terras_idx is not None:
        result["terras"], _ = collect(block, terras_idx, "terras")
    elif transporte_idx is not None and end < transporte_idx:
        result["terras"] = non_noise_join(block[end:transporte_idx], "terras")

    if transporte_idx is not None:
        result["transporte"], _ = collect(block, transporte_idx, "transporte", stop_at_note=True)
    elif terras_idx is not None:
        _, terras_end = collect(block, terras_idx, "terras")
        note_idx = first_note_or_end(block, terras_end)
        tail = block[terras_end:note_idx]
        if tail:
            result["transporte"] = non_noise_join(tail, "transporte")

    return result


def parse(raw_text: str) -> list[dict[str, str]]:
    lines = raw_text.splitlines()
    positions = find_heading_positions(lines)
    rows: list[dict[str, str]] = []
    for i, (municipio, start) in enumerate(positions):
        if i + 1 < len(positions):
            end = positions[i + 1][1]
        else:
            end = next(
                (
                    idx
                    for idx in range(start + 1, len(lines))
                    if compact_prefix(lines[idx]).startswith("MEDIDASAGRARIAS")
                ),
                len(lines),
            )
        row = {"municipio": municipio.name}
        row.update(parse_block(lines[start + 1 : end]))
        apply_targeted_overrides(row)
        rows.append(row)
    return rows


def trim_after_any(text: str, markers: tuple[str, ...]) -> str:
    for marker in markers:
        idx = text.find(marker)
        if idx >= 0:
            text = text[:idx]
    return text.strip(" ;.,")


def apply_targeted_overrides(row: dict[str, str]) -> None:
    name = row["municipio"]
    replacements = {
        "Ataxade": "A taxa de",
        "taxadc": "taxa de",
        "taxa ede": "taxa é de",
        "taxaéde": "taxa é de",
        "8o$000": "80$000",
        "&0$000": "80$000",
        "&o$000": "80$000",
        "&$000": "8$000",
        "I$000": "1$000",
        "I$500": "1$500",
        "I8$000": "18$000",
        "1g$000": "18$000",
        "2o$000": "20$000",
        "3o$000": "30$000",
        "4o$000": "40$000",
        "5o$000": "50$000",
        "6o$000": "60$000",
        "7o$000": "70$000",
        "1o$000": "10$000",
        "Ioo$000": "100$000",
        "I5o$000": "150$000",
        "r50$000": "150$000",
        "z$000": "2$000",
        "z$500": "2$500",
        "$000 a 3$000": "2$000 a 3$000",
        "$000 a 3$000": "2$000 a 3$000",
        "ooo diarios": "2$000 diarios",
    }
    for field in ("juros", "salarios", "terras", "transporte"):
        text = row[field]
        for old, new in replacements.items():
            text = text.replace(old, new)
        row[field] = fix_text(text, field)

    if name in {"Blumenau", "Brusque"} and not row["juros"]:
        row["juros"] = ""
    if name == "S. Bento":
        row["juros"] = row["juros"].replace("81ao anno", "8% ao anno")
    if name == "Urussanga":
        row["juros"] = row["juros"].replace("8a anno", "8% ao anno").replace("8% a anno", "8% ao anno")
    if name == "S. Joaquim da Costa da Serra":
        row["juros"] = "A taxa é de 12% ao anno."


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-text", required=True, type=Path)
    parser.add_argument("--csv-out", required=True, type=Path)
    args = parser.parse_args()

    rows = parse(args.raw_text.read_text(encoding="utf-8"))
    args.csv_out.parent.mkdir(parents=True, exist_ok=True)
    with args.csv_out.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["municipio", "juros", "salarios", "terras", "transporte"],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {args.csv_out}")
    for col in ["juros", "salarios", "terras", "transporte"]:
        empty = [row["municipio"] for row in rows if not row[col]]
        print(f"{col}: {len(empty)} empty")
        if empty:
            print("  " + ", ".join(empty))


if __name__ == "__main__":
    main()
