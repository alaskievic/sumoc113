#!/usr/bin/env python3
"""Parse JUROS, SALARIOS, TERRAS, and TRANSPORTE sections from Ceara OCR text."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

import parse_quest_agri_sc_sections as base
from parse_quest_agri_sc_sections import Municipio


ORIG_LINE_KIND = base.line_kind


MUNICIPIOS = [
    Municipio("Acarahu", "Acarahu"),
    Municipio("Aquiraz", "Aquiraz"),
    Municipio("Aracaty", "Aracaty"),
    Municipio("Aracoyaba", "Aracoyaba"),
    Municipio("Araripe ou Brejo Secco", "Araripe ou Brejo Secco"),
    Municipio("Arneiroz", "Arneiroz"),
    Municipio("Assaré", "Assaré"),
    Municipio("Aurora", "Aurora"),
    Municipio("Barbalha", "Barbalha"),
    Municipio("Baturité", "Baturité"),
    Municipio("Beberibe", "Beberibe"),
    Municipio("Benjamin Constant", "Benjamin Constant"),
    Municipio("Boa Viagem", "Boa.Viagem"),
    Municipio("Brejo dos Santos", "Brejo.dos Santos"),
    Municipio("Cachoeira", "Cachoeira"),
    Municipio("Camocim", "Camocim"),
    Municipio("Campo Grande", "Campo Grande"),
    Municipio("Campos Salles", "Campos.Salles"),
    Municipio("Canindé", "Canindé"),
    Municipio("Caridade", "Caridade"),
    Municipio("Cascavel", "Cascavel"),
    Municipio("Coité", "Coité"),
    Municipio("Cratheus", "Cratheus"),
    Municipio("Crato", "Crato"),
    Municipio("Entre-Rios", "Entre-Rios"),
    Municipio("Fortaleza", "Fortaleza"),
    Municipio("Granja", "Granja"),
    Municipio("Guarany", "Guarany"),
    Municipio("Ibiapina", "Ibiapina"),
    Municipio("Icó", "Ic6"),
    Municipio("Iguatú", "Iguatu"),
    Municipio("Independencia", "Independencia"),
    Municipio("Ipu", "Ipu"),
    Municipio("Ipueiras", "Ipueiras"),
    Municipio("Iracema", "Ir&cema"),
    Municipio("Itapipoca", "Itapipóca"),
    Municipio("Jaguaribe-Mirim", "Jaguaribe-Mirim"),
    Municipio("Jardim", "Jardim"),
    Municipio("Joazeiro", "Joazeiro"),
    Municipio("Lavras", "Lavras"),
    Municipio("Limoeiro", "Limoeiro"),
    Municipio("Maranguape", "Maranguape"),
    Municipio("Massapé", "Massapé"),
    Municipio("Mecejana", "Mecejana"),
    Municipio("Meruoca", "Meruoca"),
    Municipio("Milagres", "Milagres"),
    Municipio("Missão Velha", "Missao Velha"),
    Municipio("Morada Nova", "Morada Nova"),
    Municipio("Mulungu", "Mulungu"),
    Municipio("Pacatuba", "Pacatuba"),
    Municipio("Pacoty", "Pacoty"),
    Municipio("Palma", "Palma"),
    Municipio("Paracurú", "Paracuru"),
    Municipio("Pedra Branca", "Pedra Branc&"),
    Municipio("Pentecoste", "Pentecoste"),
    Municipio("Pereiro", "Pereiro"),
    Municipio("Porangaba", "Porangaba"),
    Municipio("Porteiras", "Porteiras"),
    Municipio("Quixadá", "Quixada"),
    Municipio("Quixará", "Quixara"),
    Municipio("Quixeramobim", "Ouixeramobim"),
    Municipio("Redempção", "Redempcao"),
    Municipio("Riacho do Sangue", "Riacho do Sangue"),
    Municipio("Russas", "Russas"),
    Municipio("Saboeiro", "Saboeiro"),
    Municipio("Sant'Anna", "Sant'Anna"),
    Municipio("Sant'Anna do Cariry", "Sant'Anna de Cariry"),
    Municipio("Santa Quiteria", "Santa Quiteria"),
    Municipio("S. Benedicto", "Sao Benedicto"),
    Municipio("S. Francisco de Uruburetama", "S. Francisco de Uruburetama"),
    Municipio("S. Joao de Uruburetama", "S. Joao de Uruburetama"),
    Municipio("S. Matheus", "S.Matheus"),
    Municipio("S. Pedro do Crato", "S.Pedro do Orato"),
    Municipio("Senador Pompéo", "Senador Pompéo"),
    Municipio("Sobral", "Sobral"),
    Municipio("Soure", "Soure"),
    Municipio("Tamboril", "Tamboril"),
    Municipio("Tauhá", "Tahua"),
    Municipio("Tianguá", "Tiangua"),
    Municipio("Trahiry", "Trahiry"),
    Municipio("Umary", "Umary"),
    Municipio("União", "Uniao"),
    Municipio("Varzea Alegre", "Varzea Alegre"),
    Municipio("Viçosa", "Vicosa"),
]


def fix_percent_tokens(text: str) -> str:
    text = base.fix_percent_tokens(text)
    text = text.replace("ao.mez", "ao mez").replace("aomez", "ao mez")
    text = text.replace("aanno", "ao anno").replace("aoanno", "ao anno")
    text = text.replace("por .cento", "por cento")
    text = re.sub(r"\b([12])\s*[°º\"'|/\\],]+\s*(?=ao mez|mens)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|10|12|15|18|20|24)\s*[°º\"'|/\\],]+\s*(?=ao anno|annuaes|no anno)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([12])\s+por cento", r"\1% por cento", text, flags=re.I)
    text = re.sub(r"\b([568]|10|12|15|18|20|24)\s+por cento", r"\1% por cento", text, flags=re.I)
    text = re.sub(r"\b([12])(?=\s*ao mez)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b(12|15|18|20|24)(?=\s*ao anno)", r"\1% ", text, flags=re.I)
    text = text.replace("1 %", "1%").replace("2 %", "2%")
    return re.sub(r"\s+", " ", text).strip()


def fix_text(text: str, kind: str) -> str:
    text = base.fix_currency_tokens(text)
    if kind == "juros":
        text = fix_percent_tokens(text)
    return text


def line_kind(line: str) -> str | None:
    kind = ORIG_LINE_KIND(line)
    if kind:
        return kind
    c = base.compact_prefix(line)
    if c.startswith(("SLRIOS", "SALARIDS", "SALARIOS")):
        return "salarios"
    if c.startswith(("TERFAS", "TERRAS", "TERRA")):
        return "terras"
    if c.startswith(("TRANSPORTE", "TRANSPORTES", "TRANSPORLE", "TRANSPORTL", "TRANSFORTE", "TRANSFORTES", "TRANPORTES")):
        return "transporte"
    return None


def collect_generic_until(lines: list[str], start_idx: int, kind: str) -> tuple[str, int]:
    out: list[str] = []
    idx = start_idx
    while idx < len(lines):
        line = lines[idx]
        if base.is_noise(line):
            idx += 1
            continue
        current_kind = line_kind(line)
        if out and (current_kind in {"terras", "transporte"} or base.compact_prefix(line).startswith(("NOTA", "LIMITES"))):
            break
        if current_kind == kind:
            line = base.clean_label(line, kind)
        out.append(line)
        idx += 1
    return fix_text(" ".join(out), kind), idx


def find_systema(lines: list[str], start: int = 0) -> int | None:
    for idx in range(start, len(lines)):
        if base.compact_prefix(lines[idx]).startswith("SYSTEMADETRABALHO"):
            return idx
    return None


def parse_block(block: list[str]) -> dict[str, str]:
    juros_idx = base.find_kind(block, "juros")
    salarios_idx = base.find_kind(block, "salarios")
    systema_idx = find_systema(block, (juros_idx or 0) + 1)
    if salarios_idx is None and systema_idx is not None:
        salarios_idx = systema_idx
    terras_idx = base.find_kind(block, "terras", (salarios_idx or 0) + 1)
    transporte_idx = base.find_kind(block, "transporte", (terras_idx or salarios_idx or 0) + 1)

    result = {"juros": "", "salarios": "", "terras": "", "transporte": ""}

    if juros_idx is not None:
        result["juros"], _ = base.collect(block, juros_idx, "juros")

    salarios_end = 0
    if salarios_idx is not None:
        if line_kind(block[salarios_idx]) == "salarios":
            result["salarios"], salarios_end = base.collect_salarios(block, salarios_idx)
        else:
            result["salarios"], salarios_end = collect_generic_until(block, salarios_idx, "salarios")

    if terras_idx is not None:
        result["terras"], _ = base.collect(block, terras_idx, "terras")
    elif transporte_idx is not None and salarios_end < transporte_idx:
        result["terras"] = base.non_noise_join(block[salarios_end:transporte_idx], "terras")

    if transporte_idx is not None:
        result["transporte"], _ = base.collect(block, transporte_idx, "transporte", stop_at_note=True)
    elif terras_idx is not None:
        _, terras_end = base.collect(block, terras_idx, "terras")
        note_idx = base.first_note_or_end(block, terras_end)
        tail = block[terras_end:note_idx]
        if tail:
            result["transporte"] = base.non_noise_join(tail, "transporte")

    return result


def apply_targeted_overrides(row: dict[str, str]) -> None:
    replacements = {
        "Ataxade": "A taxa de",
        "Ataxa": "A taxa",
        "taxaede": "taxa é de",
        "taxae": "taxa é",
        "taxausual": "taxa usual",
        "I$000": "1$000",
        "I$200": "1$200",
        "I$500": "1$500",
        "I5$000": "15$000",
        "Ioo$000": "100$000",
        "1o$000": "10$000",
        "2o$000": "20$000",
        "3o$000": "30$000",
        "4o$000": "40$000",
        "5o$000": "50$000",
        "6o$000": "60$000",
        "7o$000": "70$000",
        "8o$000": "80$000",
        "z$000": "2$000",
        "$ooo": "$000",
        "$oo0": "$000",
        "$o0o": "$000",
    }
    for field in ("juros", "salarios", "terras", "transporte"):
        text = row[field]
        for old, new in replacements.items():
            text = text.replace(old, new)
        row[field] = fix_text(text, field)


def parse(raw_text: str) -> list[dict[str, str]]:
    base.MUNICIPIOS = MUNICIPIOS
    base.line_kind = line_kind
    base.fix_text = fix_text
    base.apply_targeted_overrides = apply_targeted_overrides
    base.parse_block = parse_block
    return base.parse(raw_text)


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
