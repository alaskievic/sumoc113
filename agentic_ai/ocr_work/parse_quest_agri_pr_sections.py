#!/usr/bin/env python3
"""Parse JUROS, SALARIOS, TERRAS, and TRANSPORTE sections from Parana OCR text."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

import parse_quest_agri_sc_sections as base
from parse_quest_agri_sc_sections import Municipio


def line_kind(line: str) -> str | None:
    c = base.compact_prefix(line)
    if c.startswith(("JUROS", "JURQS", "IURQS", "IUROS", "UROS")):
        return "juros"
    if c.startswith(("SALARIOS", "SALARIO")):
        return "salarios"
    if c.startswith("TERRA"):
        return "terras"
    if c.startswith(("TRANSPORTE", "TRANSPORTES", "TRASPORTES")):
        return "transporte"
    return None


MUNICIPIOS = [
    Municipio("Antonina", "Antonina"),
    Municipio("Araucaria", "Araucaria"),
    Municipio("Assunguy", "Assunguy"),
    Municipio("Bocayuva", "Bocayuva"),
    Municipio("Campina Grande", "Campina Grande"),
    Municipio("Campo Largo", "Campo:Largo"),
    Municipio("Castro", "Castro"),
    Municipio("Colombo", "Colombo"),
    Municipio("Clevelandia", "Clevelandia"),
    Municipio("Conchas", "Conchas"),
    Municipio("Curitiba", "Curitiba"),
    Municipio("Deodoro", "Deodoro"),
    Municipio("Entre-Rios", "Entre-Rios"),
    Municipio("Guarakessaba", "Guarakessaba"),
    Municipio("Guarapuava", "Guarapuava"),
    Municipio("Guaratuba", "Guaratuba"),
    Municipio("Imbituva", ".Imbituva"),
    Municipio("Itayopolis", "Itayopolis"),
    Municipio("Ipiranga", "Ipiranga"),
    Municipio("Iraty", "Iraty"),
    Municipio("Jacarézinho", "Jacarézinho"),
    Municipio("Jaguariahyva", "Jaguariahyva"),
    Municipio("Jaboticabal", "Jaboticabal"),
    Municipio("Lapa", "Lapa"),
    Municipio("Morretes", "Morretes"),
    Municipio("Palmeira", "Palmeira"),
    Municipio("Palmas", "Palmas"),
    Municipio("Paranagua", "Paranagua"),
    Municipio("Palmyra", "Palmyra"),
    Municipio("Pirahy", "Pirahy"),
    Municipio("Ponta Grossa", "Ponta Grossa"),
    Municipio("Porto de Cima", "Porto de.Cima"),
    Municipio("Prudentopolis", "Prudentopolis"),
    Municipio("Ribeirao Claro", "Ribeirao Claro"),
    Municipio("Rio Branco", "Rio Branco"),
    Municipio("Rio Negro", "Rio Negro"),
    Municipio("S. Joao do Triumpho", "Sao Joao do Triumpho"),
    Municipio("S. José da Boa Vista", "Sao José da Boa Vista"),
    Municipio("S. José dos Pinhaes", "S.José dos Pinhaes"),
    Municipio("Sao Matheus", "SaoMatheus"),
    Municipio("Serro Azul", "Serro Azul"),
    Municipio("Tamandare", "Tamandare"),
    Municipio("Thomazina", "Thomazina"),
    Municipio("Tibagy", "Tibagy"),
    Municipio("Uniao da Victoria", "Uniao da Victoria"),
]


def fix_percent_tokens(text: str) -> str:
    text = base.fix_percent_tokens(text)
    text = text.replace("Ataxade", "A taxa de").replace("Ataxa", "A taxa")
    text = text.replace("taxausualede", "taxa usual é de")
    text = text.replace("aomez", "ao mez").replace("auno", "anno").replace("as anno", "ao anno")
    text = re.sub(r"\b([568]|10|12|18|20|24)\s*([°º\"'|/\\[\\],j]+)\s*(?=ao anno|annuaes|annual)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|10|12|18|20|24)\s+(?=ao anno|annuaes|annual)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|10|12|18|20|24)(?=aoanno|ao anno|annuaes|annual)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|10|12|18|20|24)\s*a\s*([568]|10|12|18|20|24)\s*(?:[°º\"'|/\\[\\],j]+)?\s*(?=ao anno|annuaes|annual)", r"\1 a \2% ", text, flags=re.I)
    text = re.sub(r"\b([12])\s*(?:[°º\"'|/\\[\\],j]+)?\s*(?=ao mez|mens)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b1\s*/\s*2\s*(?:[°º\"'|/\\[\\],j]+)?\s*(?=ao mez|mens)", "1/2% ", text, flags=re.I)
    text = text.replace("1/,aomez", "1/2% ao mez").replace("1/,ao mez", "1/2% ao mez")
    text = text.replace("114 a 2%", "1 1/4 a 2%")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def fix_text(text: str, kind: str) -> str:
    text = base.fix_currency_tokens(text)
    if kind == "juros":
        text = fix_percent_tokens(text)
    return text


def apply_targeted_overrides(row: dict[str, str]) -> None:
    replacements = {
        "Ataxade": "A taxa de",
        "taxadc": "taxa de",
        "taxaede": "taxa é de",
        "taxa e de": "taxa é de",
        "taxa & de": "taxa é de",
        "usualede": "usual é de",
        "annnacs": "annuaes",
        "liarios": "diarios",
        "mensaes": "mensaes",
        "I$000": "1$000",
        "I$500": "1$500",
        "Ioo$000": "100$000",
        "I5o$000": "150$000",
        "1o$000": "10$000",
        "2o$000": "20$000",
        "3o$000": "30$000",
        "4o$000": "40$000",
        "5o$000": "50$000",
        "6o$000": "60$000",
        "7o$000": "70$000",
        "8o$000": "80$000",
        "9o$000": "90$000",
        "&o$000": "80$000",
        "&$000": "8$000",
        "z$000": "2$000",
        "z$5oo": "2$500",
        "$S": "$5",
        "$a": "$0",
        "$g": "$9",
        "$0q0": "$000",
        "2$S00": "2$500",
        "$000 a 3$000": "2$000 a 3$000",
        "g$000": "9$000",
        "61$g80": "61$980",
        "6$g00": "6$900",
        "$a0 are": "Sao are",
    }
    for field in ("juros", "salarios", "terras", "transporte"):
        text = row[field]
        for old, new in replacements.items():
            text = text.replace(old, new)
        row[field] = fix_text(text, field)

    if row["municipio"] == "Antonina":
        row["juros"] = ""
    if row["municipio"] == "Campina Grande" and not row["salarios"]:
        row["salarios"] = fix_text(
            "Cozinheira, 20$000 mensaes; lavadeira, 15$000 mensaes; "
            "carpinteiro, de 5$000 a 6$000 por dia; trabalhador rural, 4$000; "
            "nao ha administradores nem escrivaes de fazenda. Os salarios sao "
            "pagos e os contractos cumpridos.",
            "salarios",
        )
    if row["municipio"] == "Palmyra" and not row["salarios"]:
        row["salarios"] = fix_text(
            "Trabalhador rural ganha 2$000 diarios a secco; cozinheiro, "
            "40$000 mensaes; lavadeira, 15$000; carpinteiro, 4$000 a 5$000 "
            "diarios. Nao ha administradores nem escrivaes de fazenda. Os "
            "salarios sao pagos e os contractos cumpridos.",
            "salarios",
        )
    if row["municipio"] == "Thomazina" and not row["salarios"]:
        row["salarios"] = fix_text(
            "Trabalhador rural, de 2$000 a 3$000 diarios, com comida; as "
            "fazendas sao administradas pelos donos; escrivao de fazenda, "
            "perto da villa, de 80$000 a 100$000 mensaes; longe, de 10$000 "
            "a 20$000, no maximo; carpinteiro, de 5$000 a 6$000 diarios, "
            "com comida; cozinheiro, 20$000 mensaes; lavadeira, paga-se por "
            "duzia a razao de 800 reis a 1$000, dando-se o sabao. Os salarios "
            "sao pagos e os contractos cumpridos.",
            "salarios",
        )
    if row["municipio"] == "S. José da Boa Vista":
        row["juros"] = row["juros"].replace("1/,ao mez", "1/2% ao mez")

    juros_overrides = {
        "Castro": "Taxa de 12 a 18% ao anno.",
        "Colombo": "Nao ha emprestimos agricolas.",
        "Clevelandia": "A taxa é de 12 a 18% annuaes.",
        "Conchas": "As taxas variam de 12 a 18% ao anno.",
        "Curitiba": "Nao ha emprestimos communs.",
        "Deodoro": "Nao ha taxa fixa.",
        "Entre-Rios": "A taxa usual é de 18% ao anno.",
        "Guarakessaba": "Nao ha emprestimos.",
        "Guarapuava": "A taxa usual é de 12% ao anno.",
        "Imbituva": "A taxa é de 12 a 24% ao anno.",
        "Itayopolis": "A taxa é de 6% a 12% ao anno.",
        "Ipiranga": "A taxa é de 12 a 18% annuaes.",
        "Iraty": "18 a 20% annuaes.",
        "Jacarézinho": "Taxa de 1 a 1 1/2% ao mez.",
        "Palmas": "A taxa é de 12 a 18% ao anno.",
        "Palmyra": "Nao ha emprestimos a juro.",
        "Ponta Grossa": "O juro usual é o de 12% annuaes.",
        "S. Joao do Triumpho": "12% ao anno.",
        "S. José dos Pinhaes": "Cobram 10 a 12% annuaes.",
        "Serro Azul": "A taxa usual é de 2 a 3% ao mez.",
        "Tamandare": "A taxa é de 8 a 12% ao anno.",
        "Thomazina": "1 1/4 a 2% ao mez.",
    }
    if row["municipio"] in juros_overrides:
        row["juros"] = juros_overrides[row["municipio"]]


def parse(raw_text: str) -> list[dict[str, str]]:
    base.MUNICIPIOS = MUNICIPIOS
    base.fix_text = fix_text
    base.line_kind = line_kind
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
