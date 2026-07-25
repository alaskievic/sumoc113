#!/usr/bin/env python3
"""Parse JUROS, SALARIOS, TERRAS, and TRANSPORTE sections from Sergipe OCR text."""

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
    Municipio("Annapolis (antigo Simao Dias)", "Annapolis (antigo Simao Dias)"),
    Municipio("Aquidaban", "Aquidaban"),
    Municipio("Aracaju", "Aracajü"),
    Municipio("Araua", "Araua"),
    Municipio("Buquim", "Buquim"),
    Municipio("Campo do Britto", "Campo.do Britto"),
    Municipio("Campos", "Campos"),
    Municipio("Capella", "Capella"),
    Municipio("Divina Pastora", "Divina Pastora"),
    Municipio("Dores", "Dores"),
    Municipio("Espirito Santo", "Espirito Santo"),
    Municipio("Estancia", "Estancia"),
    Municipio("Gararu", "Cararu"),
    Municipio("Itabaiana", "Itabaiana"),
    Municipio("Itabaianinha", "Itabaianinha"),
    Municipio("Itaporanga", "Itaporanga"),
    Municipio("Japaratuba", "Japaratuba"),
    Municipio("Lagarto", "Lagarto"),
    Municipio("Laranjeiras", "Laranjeiras"),
    Municipio("Maroim", "Maroim"),
    Municipio("Pacatuba", "Pacatuba"),
    Municipio("Porto da Folha", "Porto da Folha"),
    Municipio("Propria", "Propria"),
    Municipio("Riachao", "Riachao"),
    Municipio("Riachuelo", "Riachuelo"),
    Municipio("Rosario", "Rosario"),
    Municipio("Santa Luzia", "Santa Luzia"),
    Municipio("S. Christovao", "S.Christovao"),
    Municipio("S. Paulo", "S.Paulo"),
    Municipio("Siriry", "Siriry"),
    Municipio("Soccorro", "Soccorro"),
    Municipio("Santo Amaro", "Santo Amaro"),
    Municipio("Villa Christina", "Villa Christina"),
    Municipio("Villa Nova", "Villa Nova"),
]


JUROS_STOP_PREFIXES = (
    "MADEIRA",
    "MADEIRAS",
    "MADEIPA",
    "MINAS",
    "MOLESTIA",
    "MOLESTIAS",
    "EPRAGAS",
    "NUCLEOS",
    "NUCIEOS",
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
    "juros": re.compile(r"^[\s'\".]*(?:JUR[O0Q]S|JUROS|JUR0S|JURO[$S]|JURQ[$S]|IURQS|IUROS|ILROS|UROS)\s*[-—:=]*\s*", re.I),
    "salarios": re.compile(r"^[\s'\".]*(?:[$S]ALARIOS?|SALAR[I1]OS?|SALARIO)\s*[-—:=]*\s*", re.I),
    "terras": re.compile(r"^[\s'\".]*TERRA[$S]?\s*[-—:=]*\s*", re.I),
    "transporte": re.compile(r"^[\s'\".]*(?:TRAN[$S]PORTES?|TRANSFORTES?)\s*[-—:=]*\s*", re.I),
}


def ascii_norm(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return re.sub(r"\s+", " ", text).strip().upper()


def compact_prefix(text: str, length: int = 60) -> str:
    text = ascii_norm(text)
    text = text.replace("$", "S").replace("0", "O").replace("1", "I")
    return re.sub(r"[^A-Z]", "", text[:length])


def line_kind(line: str) -> str | None:
    c = compact_prefix(line)
    if c.startswith(("JUROS", "JURQS", "IUROS", "ILROS", "UROS")):
        return "juros"
    if c.startswith(("SALARIOS", "SALARIO", "SALARI")):
        return "salarios"
    if c.startswith("TERRA"):
        return "terras"
    if c.startswith(("TRANSPORTE", "TRANSPORTES", "TRANSFORTE", "TRANSFORTES")):
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
    if current in {"salarios", "terras"}:
        return prefix.startswith(("NOTA", "LIMITES"))
    if current == "transporte":
        return prefix.startswith(("NOTA", "LIMITES"))
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
    """Normalize OCR variants of percent signs in JUROS only."""
    text = text.replace("Pagam1", "Pagam 1").replace("Ataxa", "A taxa")
    text = re.sub(r"\baomez\b", "ao mez", text, flags=re.I)
    text = re.sub(r"\blao mez\b", " ao mez", text, flags=re.I)
    text = re.sub(r"\b[Iil](?=\s*(?:%|a|e|ao|°|º|\"|'|]))", "1", text)
    text = re.sub(r"\b[Iil](?=\d)", "1", text)
    text = re.sub(r"\b([12])\s*([°º][\[\]\"'!/°]*|[\]\"]+)\s*,?\s*(?=(?:a|ao|e|\b))", r"\1% ", text)
    text = re.sub(r"\b([23])\s*([°º][\[\]\"'!/°]*|[\]\"]+)\s*(?=(?:ao|mensaes|\b))", r"\1% ", text)
    text = re.sub(r"\b(12|24)\s*([°º\"]+)?\s*(?=ao anno)", r"\1% ", text, flags=re.I)
    text = re.sub(r"éde([12])", r"é de \1", text, flags=re.I)
    text = re.sub(r"\ba([23])(?=[°º\"'])", r"a \1", text, flags=re.I)
    text = re.sub(r"\b([12])\s+a\s+([23])\s+(?=ao mez)", r"\1% a \2% ", text, flags=re.I)
    text = re.sub(r"\b([12])\s*%\s*a\s+([23])\s+(?=ao mez)", r"\1% a \2% ", text, flags=re.I)
    text = re.sub(r"\b([12])\s+a\s+([23])%\s+(?=ao mez)", r"\1% a \2% ", text, flags=re.I)
    text = re.sub(r"\b([12])\s+a\s*([23])%?\s*(?:\"\"|''),?\s*(?=ao mez)", r"\1% a \2% ", text, flags=re.I)
    text = re.sub(r"\b([12])\s+e\s+([23])\s+(?=mensaes)", r"\1% e \2% ", text, flags=re.I)
    text = re.sub(r"\b([23])\s+e\s+([23])%\s+(?=mensaes)", r"\1% e \2% ", text, flags=re.I)
    text = re.sub(r"\b([123])\s+(?=ao mez)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b(12|24)\s+(?=ao anno)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b(12|24)\s*\.\s*(?=ao anno)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\bde1aaomez\b", "de 1% ao mez", text, flags=re.I)
    text = re.sub(r"\b([12])%\s*a\s*([23])(?=ao mez)", r"\1% a \2% ", text, flags=re.I)
    text = re.sub(r"\b([12])%\s*a\s*([23])l?(?=ao mez)", r"\1% a \2% ", text, flags=re.I)
    text = text.replace("2% 1% ao mez", "2% ao mez")
    text = text.replace("por .cento", "por cento").replace("por ceuto", "por cento")
    text = text.replace(".1%", "1%")
    text = text.replace("éde ", "é de ").replace("e.de", "é de")
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
        norm_line = compact_prefix(line)
        if re.search(r"C[UO]MPR|CUNPR", norm_line):
            if idx < len(lines) and compact_prefix(lines[idx]).startswith(("SALARIOSPAG", "OSSALARIOS")):
                continue
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


def find_after_phrase(lines: list[str], phrase_prefixes: tuple[str, ...], start: int = 0) -> int | None:
    for idx in range(start, len(lines)):
        prefix = compact_prefix(lines[idx])
        if any(prefix.startswith(p) for p in phrase_prefixes):
            return idx
    return None


def non_noise_join(lines: list[str], kind: str) -> str:
    return fix_text(" ".join(line for line in lines if not is_noise(line)), kind)


def first_note_or_end(lines: list[str], start: int) -> int:
    for idx in range(start, len(lines)):
        if compact_prefix(lines[idx]).startswith(("NOTA", "LIMITES")):
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
    else:
        system_idx = find_after_phrase(block, ("SYSTEMADETRABALHO", "SYSTEMADE", "SISTEMADETRABALHO"))
        if system_idx is not None and terras_idx is not None:
            result["salarios"] = non_noise_join(block[system_idx + 1 : terras_idx], "salarios")
            end = terras_idx

    if terras_idx is not None:
        result["terras"], _ = collect(block, terras_idx, "terras")
    elif transporte_idx is not None:
        start = end
        if start < transporte_idx:
            result["terras"] = non_noise_join(block[start:transporte_idx], "terras")

    if transporte_idx is not None:
        result["transporte"], _ = collect(block, transporte_idx, "transporte", stop_at_note=True)
    elif terras_idx is not None:
        # Paddle sometimes misses the TRANSPORTES label at a page break, but the
        # body still appears immediately after the land-price paragraph.
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
                    if compact_prefix(lines[idx]).startswith("QUADRODACULTURA")
                ),
                len(lines),
            )
        block = lines[start + 1 : end]
        row = {"municipio": municipio.name}
        row.update(parse_block(block))
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
    """Patch page-boundary misses and frequent OCR substitutions."""
    name = row["municipio"]

    if name == "Annapolis (antigo Simao Dias)":
        row["salarios"] = fix_text(
            "Cozinheira, ganha 8$000 a 10$000 mensaes; lavadeira, 8$000 a "
            "10$000; carpinteiro, 2$000 a 2$500 diarios; feitor de fazenda, "
            "25$000 a 30$000 mensaes; trabalhador rural, 1$000 diarios. Nao ha "
            "escrivaes de fazenda. Os salarios sao pagos e os contractos cumpridos.",
            "salarios",
        )
    elif name == "Aracaju":
        row["terras"] = fix_text(
            "Qualidades-Em sua maioria arenosas e inferiores, havendo um bom "
            "numero de boas e regulares. Na maior parte planas e seccas. Nao ha "
            "mattas virgens; ha muitas capoeiras, cerrados e campos e poucos "
            "carrascaes. Precos - O preco das terras é excessivamente variavel e "
            "conforme o logar, a qualidade, etc.; assim, um hectare de terra "
            "custa de 10$000 a 1:000$000.",
            "terras",
        )
        row["transporte"] = fix_text(
            "O transporte é feito pelo rio Cotinguiba e por tropas; o preco varia "
            "sobremodo, principalmente nas embarcacoes a vela, e canoas.",
            "transporte",
        )
    elif name == "Araua":
        row["transporte"] = fix_text(
            "Os transportes sao feitos por cavallos e burros e carros de bois, "
            "sendo o preco muito variavel.",
            "transporte",
        )
    elif name == "Buquim":
        row["terras"] = trim_after_any(row["terras"], ("de bois, por estradas",))
        row["terras"] = fix_text(
            row["terras"].removesuffix("mais ou menos").rstrip(" .")
            + ". Precos - Um hectare de terra boa custa 10$000 a 30$000, mais ou menos.",
            "terras",
        )
        row["transporte"] = fix_text(
            "Os transportes sao feitos em costas de animaes, ou carros de bois, "
            "por estradas accidentadas, ora argillosas, ora arenosas, mal "
            "conservadas e sem pontes, pelo que, na estacao invernosa, isto é, "
            "das chuvas, difficultando sobremodo o transito dos vehiculos e "
            "tropas, o preco do transporte se eleva.",
            "transporte",
        )
    elif name == "Capella":
        row["terras"] = trim_after_any(row["terras"], ("assucar paga",))
        row["transporte"] = fix_text(
            "Pagam 8 a 10 réis por litro, para Maroim. Um sacco de assucar paga "
            "500 réis, sendo o sacco de 60 kilos. Esse transporte é feito em "
            "costas de burros, e, por maos caminhos.",
            "transporte",
        )
    elif name == "Divina Pastora":
        row["terras"] = trim_after_any(row["terras"], ("carros de boi.",))
        row["terras"] = fix_text(
            row["terras"].rstrip(" .") + ". Precos - Um hectare de terra boa custa 300$000.",
            "terras",
        )
        row["transporte"] = fix_text(
            "O transporte dos productos agricolas é feito por animaes e carros de "
            "boi. Os precos variam extraordinariamente.",
            "transporte",
        )
    elif name == "Gararu":
        row["terras"] = fix_text(
            "Qualidades - No geral inferiores, misturadas, montanhosas, pedregosas "
            "e seccas, havendo algumas regulares e arenosas. A vegetacao é "
            "representada por muitas capoeiras e carrascaes, poucos cerrados, "
            "mattas e campos. Precos - Com excepcao das lagoas, onde se cultiva o "
            "arroz e que se vende em lotes, a terra nas catingas nao teem preco, "
            "por ser muito secca.",
            "terras",
        )
        row["transporte"] = fix_text(
            "O transporte é feito por via fluvial e por via terrestre. Pelo rio "
            "S. Francisco que tem um porto na villa as mercadorias sao conduzidas "
            "em canoas em toda a sua extensao navegavel, para os centros consumidores.",
            "transporte",
        )
    elif name == "Itabaiana":
        row["terras"] = trim_after_any(row["terras"], ("aninaes.", "animaes."))
        row["transporte"] = fix_text(
            "Os transportes se fazem em carros de bois e costas de animaes. No "
            "inverno as estradas sao de transito difficil, elevando-se por causa "
            "disso, o preco do transporte.",
            "transporte",
        )
    elif name == "Itabaianinha":
        row["juros"] = "A taxa usada é de 1% a 2% ao mez."
        row["terras"] = trim_after_any(row["terras"], ("mais elevado durante",))
        row["transporte"] = fix_text(
            "O preco dos transportes das mercadorias é variavel, sendo mais "
            "elevado durante o inverno, por causa dos caminhos ficarem com o "
            "transito muito penoso com as chuvas.",
            "transporte",
        )
    elif name == "Lagarto":
        row["transporte"] = fix_text(
            "O custo dos transportes das mercadorias é muito variavel.",
            "transporte",
        )
    elif name == "Laranjeiras":
        row["terras"] = trim_after_any(row["terras"], ("bois para o interior",))
        row["transporte"] = fix_text(
            "Sao feitos em canoas, pelo rio Cotinguiba e em carros de bois para "
            "o interior do municipio. Os fretes sao muito variaveis.",
            "transporte",
        )
    elif name == "Maroim":
        if row["terras"].startswith("C Qualidades"):
            row["terras"] = row["terras"].replace("C Qualidades", "Qualidades", 1)
        row["terras"] = fix_text(
            row["terras"]
            .replace("ou_menos. ou lanchas.sendo o custo muito variavel.", "")
            .removesuffix("ou menos.")
            .rstrip(" .")
            + ". Precos - Uma tarefa ou 3.025 metros quadrados custa 50$000, mais ou menos.",
            "terras",
        )
        row["transporte"] = fix_text(
            "Os transportes sao feitos em tropas, carros de bois, canoas ou "
            "lanchas, sendo o custo muito variavel.",
            "transporte",
        )
    elif name == "Porto da Folha":
        row["terras"] = trim_after_any(row["terras"], ("fretes varia",))
        row["transporte"] = fix_text(
            "O transporte dos productos é feito por canoas, pelo rio S. Francisco "
            "e lagoas e por animaes e carros de bois. O preco dos fretes varia muito.",
            "transporte",
        )
    elif name == "S. Paulo":
        row["terras"] = trim_after_any(row["terras"], ("para fora,",))
        row["transporte"] = fix_text(
            "O preco de transporte, quer para o mercado local, quer para fora, "
            "é muito variavel.",
            "transporte",
        )
    elif name == "Villa Nova":
        row["juros"] = "Taxa de 12% ao anno."
        row["terras"] = trim_after_any(row["terras"], ("preco do transporte",))
        row["transporte"] = fix_text(
            "O transporte é feito por via fluvial pelo rio S. Francisco e por via "
            "terrestre, por meio de tropas e carros de boi. O preco do transporte "
            "varia com a distancia.",
            "transporte",
        )

    replacements = {
        "aI :000$000": "a 1:000$000",
        "I :000$000": "1:000$000",
        "Io$000": "10$000",
        "1o$000": "10$000",
        "I5$000": "15$000",
        "3o$000": "30$000",
        "5o$000": "50$000",
        "6o$000": "60$000",
        "7o$000": "70$000",
        "8oo$000": "800$000",
        "7oo$000": "700$000",
        "Ioo$000": "100$000",
        "2oo$000": "200$000",
        "Io$coo": "10$000",
        "I$000": "1$000",
        "i$500": "1$500",
        "r$000": "1$000",
        "r$200": "1$200",
        "r$zoo": "1$200",
        "g$000": "8$000",
        "z$000": "2$000",
        "z$500": "2$500",
        ":$000": "2$000",
        "a$000": "a 1$000",
        "&$000": "8$000",
        "500$0q0": "500$000",
        "$oco": "$000",
        "$coo": "$000",
        "$ooo": "$000",
        "$zoo": "$200",
        "de I$ a 30$000": "de 10$000 a 30$000",
        "de 1$ a 30$000": "de 10$000 a 30$000",
        "c os pagos.": "c os salarios pagos.",
        "  ": " ",
    }

    for field in ("juros", "salarios", "terras", "transporte"):
        text = row[field]
        for old, new in replacements.items():
            text = text.replace(old, new)
        row[field] = fix_text(text, field)


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
