#!/usr/bin/env python3
"""Parse JUROS, SALARIOS, TERRAS, and TRANSPORTE sections from Para OCR text."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

import parse_quest_agri_sc_sections as base
from parse_quest_agri_sc_sections import Municipio


ORIG_LINE_KIND = base.line_kind


MUNICIPIOS = [
    Municipio("Abaeté", "Abaeté"),
    Municipio("Acará", "Acara"),
    Municipio("Afuá", "Afua"),
    Municipio("Alemquér", "Alemquér"),
    Municipio("Almerim", "Almerim"),
    Municipio("Anajás", "Anajas"),
    Municipio("Aveiros", "Aveiros"),
    Municipio("Bagre", "Bagre"),
    Municipio("Baião", "Baiao"),
    Municipio("Belém", "Belem"),
    Municipio("Bragança", "Braganca"),
    Municipio("Breves", "Breves"),
    Municipio("Cametá", "Cameta"),
    Municipio("Cachoeira", "Cachoeira"),
    Municipio("Chaves", "Chaves"),
    Municipio("Conceição de Araguaya", "Conceicao de Araguaya"),
    Municipio("Curralinho", "Curralinho"),
    Municipio("Curuçá", "Ouruca"),
    Municipio("Faro", "Faro"),
    Municipio("Gurupá", "Gurupa"),
    Municipio("Igarapé-Assú", "Igarapé-Assu"),
    Municipio("Igarapé-Mirim", "Igarapé-Mirim"),
    Municipio("Irituia", "Irituia"),
    Municipio("Itaituba", "Itaituba"),
    Municipio("Macapá", "Macap&"),
    Municipio("Mazagão", "Mazagao"),
    Municipio("Marapanim", "Marapanim"),
    Municipio("Maracanã", "Maracan&"),
    Municipio("Melgaço", "Melgaco"),
    Municipio("Mocajuba", "Mocajuba"),
    Municipio("Mojú", "Moju"),
    Municipio("Monte Alegre", "Monte Alegre"),
    Municipio("Montenegro", "Montenegro"),
    Municipio("Muaná", "Muana"),
    Municipio("Obidos", "Obidos"),
    Municipio("Ourém", "Ourém"),
    Municipio("Oeiras", "Oeiras"),
    Municipio("Ponta de Pedras", "Ponta de Pedras"),
    Municipio("Porto de Moz", "Porto de Moz"),
    Municipio("Portel", "Portel"),
    Municipio("Prainha", "Prainha"),
    Municipio("Quatipurú", "Quatipuru"),
    Municipio("Salinas", "Salinas"),
    Municipio("Santarém", "Santarém"),
    Municipio("S. Caetano de Odivellas", "S.Caetano de Odivellas"),
    Municipio("S. Domingos da Boa Vista", "S.Domingos da Boa Vista"),
    Municipio("S. João de Araguaya", "S.Joaode.Araguaya"),
    Municipio("S. Miguel do Guamá", "S.Migueldo Guama"),
    Municipio("S. Sebastião da Boa Vista", "S.Sebastiao da Boa Vistn"),
    Municipio("Soure (Ilha de Marajó)", "Soure (ma lade Marajo)"),
    Municipio("Souzel", "Souzel"),
    Municipio("Vigia", "Vigia"),
    Municipio("Vizeu", "Vizeu"),
]


def line_kind(line: str) -> str | None:
    kind = ORIG_LINE_KIND(line)
    if kind:
        return kind
    c = base.compact_prefix(line)
    if c.startswith(("JUROS", "JURO", "UROS", "ROS", "FUROS")):
        return "juros"
    if c.startswith(("SALARIOS", "SALARIQS", "SALARIO", "SALARI", "SAIARIOS", "SAIARIO", "SALAROS", "SALARIS")):
        return "salarios"
    if c.startswith(("TERRAS", "TERRASQUAL", "TERRA")):
        return "terras"
    if c.startswith(("TRANSPORTE", "TRANSPORTES", "TRASPORTE")):
        return "transporte"
    return None


def fix_percent_tokens(text: str) -> str:
    text = base.fix_percent_tokens(text)
    text = text.replace("annuaes", "annuaes").replace("annuacs", "annuaes")
    text = text.replace("aomez", "ao mez").replace("aomcz", "ao mez")
    text = text.replace("aoanno", "ao anno").replace("aoanmo", "ao anno")
    text = re.sub(r"\b([568]|10|12|15|20)\s*[°º\"'|/\\],]*\s*(?=annuaes|ao anno)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([12])\s*[°º\"'|/\\],]*\s*(?=ao mez|mens)", r"\1% ", text, flags=re.I)
    text = re.sub(r"\b([568]|10|12|15|20)\s+por cento", r"\1% por cento", text, flags=re.I)
    text = re.sub(r"\b([12])\s+por cento", r"\1% por cento", text, flags=re.I)
    return re.sub(r"\s+", " ", text).strip()


def fix_text(text: str, kind: str) -> str:
    text = base.fix_currency_tokens(text)
    if kind == "juros":
        text = fix_percent_tokens(text)
    return text


def collect(lines: list[str], start_idx: int, kind: str, stop_at_note: bool = False) -> tuple[str, int]:
    out: list[str] = []
    idx = start_idx
    first = True
    while idx < len(lines):
        line = lines[idx]
        if base.is_noise(line):
            idx += 1
            continue
        current_kind = line_kind(line)
        if not first and base.is_stop(line, kind):
            break
        if not first and current_kind and current_kind != kind:
            break
        if not first and stop_at_note and base.compact_prefix(line).startswith(("NOTA", "LIMITES")):
            break
        if current_kind == kind or first:
            line = base.clean_label(line, kind)
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
        if base.is_noise(line):
            idx += 1
            continue
        current_kind = line_kind(line)
        if not first and base.is_stop(line, "salarios"):
            break
        if not first and current_kind in {"terras", "transporte"}:
            break
        if first or current_kind == "salarios":
            line = base.clean_label(line, "salarios")
        out.append(line)
        first = False
        idx += 1
        if re.search(r"C[UO]MPR|PAG[O0]S|CONTRACT", base.compact_prefix(line)):
            break
    return fix_text(" ".join(out), "salarios"), idx


def find_heading_positions(lines: list[str]) -> list[tuple[Municipio, int]]:
    start = next(i for i, line in enumerate(lines) if line.strip() == "=== Page 5 ===")
    positions: list[tuple[Municipio, int]] = []
    cursor = start
    for municipio in MUNICIPIOS:
        target = base.ascii_norm(municipio.ocr_heading)
        found = None
        for idx in range(cursor, len(lines)):
            if base.ascii_norm(lines[idx]) == target:
                found = idx
                break
        if found is None:
            raise RuntimeError(f"Could not find heading for {municipio.name!r}")
        positions.append((municipio, found))
        cursor = found + 1
    return positions


def parse_block(block: list[str]) -> dict[str, str]:
    juros_idx = base.find_kind(block, "juros")
    salarios_idx = base.find_kind(block, "salarios")
    terras_idx = base.find_kind(block, "terras", (salarios_idx or 0) + 1)
    transporte_idx = base.find_kind(block, "transporte", (terras_idx or salarios_idx or 0) + 1)

    result = {"juros": "", "salarios": "", "terras": "", "transporte": ""}
    if juros_idx is not None:
        result["juros"], _ = collect(block, juros_idx, "juros")

    salarios_end = 0
    if salarios_idx is not None:
        result["salarios"], salarios_end = collect_salarios(block, salarios_idx)

    if terras_idx is not None:
        result["terras"], _ = collect(block, terras_idx, "terras")
    elif transporte_idx is not None and salarios_end < transporte_idx:
        result["terras"] = base.non_noise_join(block[salarios_end:transporte_idx], "terras")

    if transporte_idx is not None:
        result["transporte"], _ = collect(block, transporte_idx, "transporte", stop_at_note=True)
    elif terras_idx is not None:
        _, terras_end = collect(block, terras_idx, "terras")
        note_idx = base.first_note_or_end(block, terras_end)
        tail = block[terras_end:note_idx]
        if tail:
            result["transporte"] = base.non_noise_join(tail, "transporte")
    return result


def apply_targeted_overrides(row: dict[str, str]) -> None:
    replacements = {
        "Ataxausial": "A taxa usual",
        "Ataxausual": "A taxa usual",
        "Naohataxafxa": "Nao ha taxa fixa",
        "Naohaprestamistas": "Nao ha prestamistas",
        "Naohacmprestimos": "Nao ha emprestimos",
        "Naohacmprestimosa": "Nao ha emprestimos a",
        "I$000": "1$000",
        "I$500": "1$500",
        "1o$000": "10$000",
        "2o$000": "20$000",
        "3o$000": "30$000",
        "4o$000": "40$000",
        "5o$000": "50$000",
        "6o$000": "60$000",
        "8o$000": "80$000",
        "1oo$000": "100$000",
        "2oo$000": "200$000",
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
    base.line_kind = line_kind
    base.fix_text = fix_text
    base.apply_targeted_overrides = apply_targeted_overrides
    base.find_kind = lambda lines, kind, start=0: next((idx for idx in range(start, len(lines)) if line_kind(lines[idx]) == kind), None)
    lines = raw_text.splitlines()
    positions = find_heading_positions(lines)
    rows: list[dict[str, str]] = []
    for i, (municipio, start) in enumerate(positions):
        end = positions[i + 1][1] if i + 1 < len(positions) else len(lines)
        row = {"municipio": municipio.name}
        row.update(parse_block(lines[start + 1 : end]))
        apply_targeted_overrides(row)
        rows.append(row)
    return rows


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
