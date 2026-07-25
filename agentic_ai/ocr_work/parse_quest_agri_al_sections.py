#!/usr/bin/env python3
"""Parse JUROS, SALARIOS, TERRAS, and TRANSPORTE sections from raw OCR text."""

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
    Municipio("Agua Branca", "Agua Branca"),
    Municipio("Alagoas", "Alagoas"),
    Municipio("Anadia", "Anadia"),
    Municipio("Atalaia", "Atalaia"),
    Municipio("Bello Monte", "Bello Monte"),
    Municipio("Coruripe", "Coruripe"),
    Municipio("Euclydes Malta (actualmente Parahyba)", "Euclydes Malta (actualmente Parahyba)"),
    Municipio("Junqueiro", "Junqueiro"),
    Municipio("Leopoldina", "Leopoldina"),
    Municipio("Limoeiro", "Limoeiro"),
    Municipio("Maceió", "Maceió"),
    Municipio("Maragogy", "Maragogy"),
    Municipio("Muricy", "Muricy"),
    Municipio("Palmeira dos Indios", "Palmeira dos Indios"),
    Municipio("Pao de Assucar", "pao de Assucar"),
    Municipio("Passo de Camaragibe", "Passo de Camaragibe"),
    Municipio("Paulo Affonso", "Paulo Affonso"),
    Municipio("Penedo", "Penedo"),
    Municipio("Piassabussu", "Piassabussu"),
    Municipio("Pilar", "Pilar"),
    Municipio("Piranhas", "Piranhas"),
    Municipio("Porto Calvo", "Porto Calvo"),
    Municipio("Porto de Pedras", "Porto de Pedras"),
    Municipio("Porto Real do Collegio", "Porto Real do Collegio"),
    Municipio("Sant'Anna de Ipanema", "Sant'Anna de Ipanema"),
    Municipio("Santa Luzia do Norte", "Santa Luzia do Norte"),
    Municipio("Sao Braz", "Sao Braz"),
    Municipio("S. José da Lage", "S. José da Lage"),
    Municipio("Sao Luiz do Quitunde", "Sao Luiz do Quitunde"),
    Municipio("S. Miguel de Campos", "S. Miguel de Campos"),
    Municipio("Traipu", "Traipu"),
    Municipio("Triumpho", "Triumpho"),
    Municipio("Uniao", "Uuiao"),
    Municipio("Vicosa", "Vicosa"),
    Municipio("Victoria", "Victoria"),
]


def ascii_norm(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return re.sub(r"\s+", " ", text).strip().upper()


def compact_prefix(text: str) -> str:
    text = ascii_norm(text)
    text = text.replace("$", "S").replace("0", "O")
    return re.sub(r"[^A-Z]", "", text[:42])


def line_kind(line: str) -> str | None:
    c = compact_prefix(line)
    if c.startswith(("JUROS", "JURQS", "IURQS", "IUROS", "UROS")):
        return "juros"
    if c.startswith(("SALARIOS", "SALARIO")):
        return "salarios"
    if c.startswith("TERRA"):
        return "terras"
    if c.startswith("TRANSPORTE") or c.startswith("TRANSPORTES"):
        return "transporte"
    return None


JUROS_STOP_PREFIXES = (
    "MADEIRA",
    "MADEIPA",
    "MINAS",
    "MOLESTIA",
    "EPRAGAS",
    "NUCLEOS",
    "OPEROSIDADE",
    "PADRO",
    "PORTOS",
    "SEMENTE",
    "SEMEADURA",
    "SYSTEMA",
    "SISTEMA",
)


LABEL_PATTERNS = {
    "juros": re.compile(r"^[\s'\".]*(?:JUR[O0Q]S|JUROS|JUR0S|JURO[$S]|JURQ[$S]|IURQS|IUROS|UROS)\s*[-—:=]*\s*", re.I),
    "salarios": re.compile(r"^[\s'\".]*(?:[$S]ALARIOS?|SALARIO)\s*[-—:=]*\s*", re.I),
    "terras": re.compile(r"^[\s'\".]*TERRA[$S]?\s*[-—:=]*\s*", re.I),
    "transporte": re.compile(r"^[\s'\".]*TRAN[$S]PORTES?\s*[-—:=]*\s*", re.I),
}


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
    if current in {"salarios", "terras"}:
        return prefix.startswith("NOTA")
    if current == "transporte":
        return prefix.startswith(("NOTA", "LIMITES"))
    return False


def fix_currency_tokens(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        token = match.group(0)
        left, right = token.split("$", 1)
        left = left.replace("o", "0").replace("O", "0").replace("c", "0").replace("C", "0")
        left = left.replace("I", "1").replace("l", "1")
        left = left.replace("r", "1").replace("R", "1")
        left = left.replace("z", "2").replace("Z", "2").replace("&", "8")
        right = right.replace("o", "0").replace("O", "0").replace("c", "0").replace("C", "0")
        right = right.replace("z", "2").replace("Z", "2")
        right = right.replace("x", "0").replace("X", "0").replace("&", "8")
        right = right.replace("I", "1").replace("l", "1")
        return f"{left}${right}"

    text = re.sub(r"\b[A-Za-z0-9]+[$][A-Za-z0-9]+\b", repl, text)
    text = re.sub(r"\b[A-Za-z0-9&:]+[$][A-Za-z0-9&:xX]+\b", repl, text)
    text = re.sub(r"(?<!\w)[$][A-Za-z0-9&:xX]+\b", lambda m: repl(re.match(r"[$].+", m.group(0))), text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


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
        if current_kind == kind:
            line = clean_label(line, kind)
        elif first:
            line = clean_label(line, kind)
        out.append(line)
        first = False
        idx += 1
    return fix_currency_tokens(" ".join(out)), idx


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
        norm_line = ascii_norm(line).replace("0", "O")
        if re.search(r"C[UO]MPR|CUNPR", norm_line):
            break
    return fix_currency_tokens(" ".join(out)), idx


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


def find_after_phrase(lines: list[str], phrase_prefixes: tuple[str, ...], start: int = 0) -> int | None:
    for idx in range(start, len(lines)):
        prefix = compact_prefix(lines[idx])
        if any(prefix.startswith(p) for p in phrase_prefixes):
            return idx
    return None


def parse_block(block: list[str]) -> dict[str, str]:
    juros_idx = find_kind(block, "juros")
    salarios_idx = find_kind(block, "salarios")
    terras_idx = find_kind(block, "terras", (salarios_idx or 0) + 1)
    transporte_idx = find_kind(block, "transporte", (terras_idx or salarios_idx or 0) + 1)

    result = {"juros": "", "salarios": "", "terras": "", "transporte": ""}
    if juros_idx is not None:
        result["juros"], _ = collect(block, juros_idx, "juros")

    if salarios_idx is not None:
        text, end = collect_salarios(block, salarios_idx)
        result["salarios"] = text
    else:
        system_idx = find_after_phrase(block, ("SYSTEMADETRABALHO", "SISTEMADETRABALHO"))
        if system_idx is not None and terras_idx is not None:
            result["salarios"] = fix_currency_tokens(
                " ".join(line for line in block[system_idx + 1 : terras_idx] if not is_noise(line))
            )
            end = terras_idx
        else:
            end = 0

    if terras_idx is not None:
        result["terras"], _ = collect(block, terras_idx, "terras")
    elif transporte_idx is not None:
        # Some pages missed the TERRAS label but still OCRed the body between
        # salary and transport sections.
        start = None
        for idx in range((salarios_idx or 0), transporte_idx):
            if "contract" in ascii_norm(block[idx]).lower() or "CUMPR" in ascii_norm(block[idx]):
                start = idx + 1
        if start is None:
            start = end if "end" in locals() else 0
        result["terras"] = fix_currency_tokens(
            " ".join(line for line in block[start:transporte_idx] if not is_noise(line))
        )

    if transporte_idx is not None:
        result["transporte"], _ = collect(block, transporte_idx, "transporte", stop_at_note=True)

    return result


def parse(raw_text: str) -> list[dict[str, str]]:
    lines = raw_text.splitlines()
    positions = find_heading_positions(lines)
    rows = []
    for i, (municipio, start) in enumerate(positions):
        end = positions[i + 1][1] if i + 1 < len(positions) else len(lines)
        block = lines[start + 1 : end]
        row = {"municipio": municipio.name}
        row.update(parse_block(block))
        apply_targeted_overrides(row)
        rows.append(row)
    return rows


def apply_targeted_overrides(row: dict[str, str]) -> None:
    """Patch a few page-boundary OCR misses with higher-DPI PaddleOCR readings."""
    name = row["municipio"]
    if name == "S. José da Lage":
        row["salarios"] = fix_currency_tokens(
            "Nao ha cozinheiro; as lavadeiras ganham por peca; um carpinteiro ganha "
            "de 2$ooo a 3$ooo diarios; um vaqueiro, de 48o$ooo a 6oo$ooo annuaes; "
            "administrador de fazenda, de 6oo$ooo a 85o$ooo annuaes; nao ha escrivaes "
            "de fazenda; o salario do trabalhador rural seja colono ou camarada é de "
            "6oo a 8oo réis diarios. Os salarios sao pagos e os contractos cumpridos."
        )
        if row["terras"].startswith("sao mais"):
            row["terras"] = "Qualidades-No municipio predominam as boas e regulares; " + row["terras"]
    elif name == "Uniao":
        row["terras"] = fix_currency_tokens(
            "Qualidades-No municipio predominam as böas e regulares havendo poucas "
            "inferiores; algunas sao planas, outras montanhoass e seccas, existindo "
            "em grande quantidade argillosas e nisturadas e em pequena quantidade "
            "arenosas, pedregosas e pantanosas. A vegetacao é representada por "
            "algumas mattas virgens, cerrados, carrascaes e campos. Precos - Um "
            "hectare de terra böa custa 20o$o00, approximadamente."
        )
    elif name == "Vicosa" and row["terras"].startswith("lares, havendo"):
        row["terras"] = "Qualidades-No municipio predominam as terras boas e regu" + row["terras"]
    elif name == "Porto Real do Collegio" and row["terras"].startswith("havendo para"):
        row["terras"] = "Qualidades-Sao boas em geral, quasi em sua totalidade planas, " + row["terras"]
    elif name == "Victoria":
        row["salarios"] = fix_currency_tokens(
            "Cozinheira, 8$ooo mensaes; lavadeira, por peca; carpinteiro, "
            "2$5oo diarios; trabalhador rural, 1$ooo; nao ha escrivaes nem "
            "administradores de fazenda. Os salarios sao pagos e os contractos "
            "cumpridos."
        )
    for field in ("juros", "salarios", "terras", "transporte"):
        text = fix_currency_tokens(row[field])
        replacements = {
            "carpinteiro,$000 a 3$000": "carpinteiro, 2$000 a 3$000",
            "carpinteiro, $000 a 3$000": "carpinteiro, 2$000 a 3$000",
            "tendo mais :$000": "tendo mais 2$000",
            "8oo réisa $000": "8oo réis a 1$000",
            "6oo réis a $000": "6oo réis a 1$000",
            "7oo réis a $200": "7oo réis a 1$200",
            "pagan $000": "pagam 2$000",
            "paga, $000": "paga, 2$000",
            "&00$000": "800$000",
            "&0$000": "80$000",
            "&$000": "8$000",
            "a $200": "a 1$200",
            "0usta": "custa",
        }
        for old, new in replacements.items():
            text = text.replace(old, new)
        if name == "Palmeira dos Indios":
            text = text.replace("cozinheiros, 8$000", "cozinheiros, 5$000")
            text = text.replace("pagam 2$000 para a cstaqao", "pagam 2$000 para a cstaqao")
        row[field] = text


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
