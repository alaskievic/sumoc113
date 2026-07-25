#!/usr/bin/env python3
"""Parse JUROS, SALARIOS, TERRAS, and TRANSPORTE sections from Goyaz OCR text."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

import parse_quest_agri_sc_sections as base
from parse_quest_agri_sc_sections import Municipio


MUNICIPIOS = [
    Municipio("Allemao", "Allemao"),
    Municipio("Annapolis", "Annapolis"),
    Municipio("Arrayas", "Arrayas"),
    Municipio("Bella Vista", "Bella Vista"),
    Municipio("Boa Vista do Tocantins", "Boa Vista do Tocantins"),
    Municipio("Bomfim", "Bomfim"),
    Municipio("Campinas", "Campinas"),
    Municipio("Campo Formoso", "Campo Formoso"),
    Municipio("Catalao", "Catalao"),
    Municipio("Cavalcanti", "Cavalcanti"),
    Municipio("Chapéo", "Chapéo"),
    Municipio("Conceicao do Norte", "Conceicao"),
    Municipio("Corumba", "Corumba"),
    Municipio("Corumbahyba", "Corumbahyba"),
    Municipio("Curralinho", "Curralinho"),
    Municipio("S. José do Duro", "S. José do Duro"),
    Municipio("Formosa", "Formoso"),
    Municipio("Forte", "Forte"),
    Municipio("Goyaz", "Goyaz"),
    Municipio("Ipamery", "Ipamery"),
    Municipio("Jaragua", "Jaragu&"),
    Municipio("Jatahy", "Jatahy"),
    Municipio("Mestre d'Armas", "Mestre d'Armas"),
    Municipio("Mineiros", "Mineiros"),
    Municipio("Morrinhos", "Morrinhos"),
    Municipio("Natividade", "Natividade"),
    Municipio("Palma", "Palma"),
    Municipio("Pedro Affonso", "Pedro Affonso."),
    Municipio("Peixe", "Peixe"),
    Municipio("Pilar", "Pilar"),
    Municipio("Porto Nacional", "Porto Nacional"),
    Municipio("Posse", "Posse"),
    Municipio("Pouso Alto", "Pouso Alto"),
    Municipio("Pyrenopolis", "Pyrenopolis"),
    Municipio("Rio Bonito", "Rio Bonito"),
    Municipio("Rio Verde", ".Rio Verde"),
    Municipio("Santa Cruz", "SantaCruz"),
    Municipio("Santa Luzia", "Sant& Luzia"),
    Municipio("Santa Rita do Paranahyba", "Santa Rita do Paranahyba"),
    Municipio("Sao Domingos", "Sao Domingos"),
    Municipio("S. José do Tocantins", "S. José do Tocantins."),
    Municipio("Sitio d'Abbadia", "Sitio d'Abbadia"),
    Municipio("Taguatinga", "Taguatinga"),
]


def fix_percent_tokens(text: str) -> str:
    text = base.fix_percent_tokens(text)
    text = text.replace("Ataxausualede", "A taxa usual é de ")
    text = text.replace("aomez", "ao mez").replace("ao;mez", "ao mez")
    text = text.replace("annuaes", "annuaes")
    text = re.sub(r"\bI\s*([°º\"'|/l\],]+)\s*(?=ao mez|ao anno|mens)", "1% ", text, flags=re.I)
    text = re.sub(r"\b1\s*([°º\"'|/l\],]+)\s*(?=ao mez|ao anno|mens)", "1% ", text, flags=re.I)
    text = re.sub(r"\b2\s*([°º\"'|/l\],]+)\s*(?=ao mez|ao anno|mens)", "2% ", text, flags=re.I)
    text = re.sub(r"\b10\s*([°º\"'|/l\],]+)\s*(?=ao anno|annuaes)", "10% ", text, flags=re.I)
    text = re.sub(r"\b18\s*([°º\"'|/l\],]+)\s*a\s*24\s*([°º\"'|/l\],]+)\s*(?=annuaes)", "18% a 24% ", text, flags=re.I)
    text = re.sub(r"\b8\s*a\s*10\s*([°º\"'|/l\],]+)\s*(?=annuaes)", "8 a 10% ", text, flags=re.I)
    text = re.sub(r"\b12\s*([°º\"'|/l\],]+)\s*(?=ao anno|annuaes)", "12% ", text, flags=re.I)
    text = re.sub(r"\b1\s*a\s*2\s*([°º\"'|/l\],]+)\s*(?=mens|ao mez)", "1 a 2% ", text, flags=re.I)
    text = re.sub(r"\b1\s+por cento", "1% por cento", text, flags=re.I)
    text = text.replace("Iaomez", "1% ao mez").replace("I °l, ao mez", "1% ao mez")
    text = text.replace("I ° ao mez", "1% ao mez").replace("1 \" ao mez", "1% ao mez")
    text = text.replace("2 \" mensaes", "2% mensaes")
    text = text.replace("1 º|º ao mez", "1% ao mez")
    text = text.replace("1 º]º ao mez", "1% ao mez")
    text = text.replace("1°|° ao mez", "1% ao mez")
    text = text.replace("1º/º", "1%").replace("2º/º", "2%")
    text = text.replace("74 º|º", "3/4%")
    text = text.replace("1 4a 2% ao mez", "1 a 2% ao mez")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def fix_text(text: str, kind: str) -> str:
    text = base.fix_currency_tokens(text)
    if kind == "juros":
        text = fix_percent_tokens(text)
    return text


def apply_targeted_overrides(row: dict[str, str]) -> None:
    for field in ("juros", "salarios", "terras", "transporte"):
        text = row[field]
        for old, new in {
            "Ataxade": "A taxa de",
            "taxae": "taxa é",
            "taxaede": "taxa é de",
            "taxausualede": "taxa usual é de",
            "aomez": "ao mez",
            "aanno": "ao anno",
            "2o$000": "20$000",
            "3o$000": "30$000",
            "4o$000": "40$000",
            "5o$000": "50$000",
            "6o$000": "60$000",
            "7o$000": "70$000",
            "8o$000": "80$000",
            "1o$000": "10$000",
            "I$000": "1$000",
            "I5$000": "15$000",
            "Ioo$000": "100$000",
            "z$000": "2$000",
        }.items():
            text = text.replace(old, new)
        row[field] = fix_text(text, field)


def parse(raw_text: str) -> list[dict[str, str]]:
    base.MUNICIPIOS = MUNICIPIOS
    base.fix_text = fix_text
    base.apply_targeted_overrides = apply_targeted_overrides
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
