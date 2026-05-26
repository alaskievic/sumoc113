import csv
import json
import os
import re
import unicodedata

import pdfplumber
import pytesseract


PDF_PATH = "/Users/alaskievic/Desktop/test_for_gpt.pdf"
OCR_JSON = "test_for_gpt_ocr.json"
OUT_CSV = "test_for_gpt_extract.csv"
TOPICS = ["juros", "salarios", "portos", "transportes", "terras"]


def ocr_pdf():
    if os.path.exists(OCR_JSON):
        with open(OCR_JSON, encoding="utf-8") as f:
            return json.load(f)

    pages = []
    with pdfplumber.open(PDF_PATH) as pdf:
        total = len(pdf.pages)
        for idx, page in enumerate(pdf.pages, start=1):
            print(f"OCR {idx}/{total}", flush=True)
            image = page.to_image(resolution=300).original
            pages.append(pytesseract.image_to_string(image, lang="por"))

    with open(OCR_JSON, "w", encoding="utf-8") as f:
        json.dump(pages, f, ensure_ascii=False)
    return pages


def strip_accents(value):
    normalized = unicodedata.normalize("NFKD", value)
    return "".join(ch for ch in normalized if not unicodedata.combining(ch))


def normalize_label(value):
    label = strip_accents(value.upper())
    label = re.sub(r"[^A-Z]+", "", label)
    if label.startswith("JUROS"):
        return "juros"
    if label.startswith("SALARIO"):
        return "salarios"
    if label.startswith("PORTOS"):
        return "portos"
    if label.startswith("TRANSPORTE") or label.startswith("TRANSSPORTE"):
        return "transportes"
    if label in {"TRANS", "TRANSPORT"}:
        return "transportes"
    if label.startswith("TERRAS"):
        return "terras"
    if label.startswith("PRECO"):
        return "precos"
    return label.lower()


def title_noise(line):
    line = line.strip()
    if not line:
        return True
    if re.fullmatch(r"[-–—=\s\d\|]+", line):
        return True
    if len(line) > 28 and re.fullmatch(r"[A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ\s]+", line):
        return True
    if line.upper() in {"NOTA", "INDICE", "ADVERTENCIA"}:
        return True
    return False


def clean_name(name):
    name = re.sub(r"^[\"'“”*]+|[\"'“”*]+$", "", name.strip())
    name = re.sub(r"^[a-z]\s+", "", name)
    return re.sub(r"\s+", " ", name).strip(" .,:;")


def split_municipalities(full_text):
    text = full_text.replace("\r\n", "\n").replace("\r", "\n")
    anchor = re.compile(r"AGRIC[A-Z][A-Z ]{3,12}(?:RES|ES|S)\s*[—\-<]", re.I)
    starts = [m.start() for m in anchor.finditer(text)]
    starts = [pos for pos in starts if "ULTURA" not in text[pos : pos + 14].upper()]

    blocks = []
    for i, start in enumerate(starts):
        previous = text[max(0, start - 650) : start]
        name = ""
        for raw_line in reversed(previous.splitlines()):
            candidate = clean_name(raw_line)
            if candidate and not title_noise(candidate):
                name = candidate
                break
        end = starts[i + 1] - 500 if i + 1 < len(starts) else len(text)
        blocks.append((name, text[start:end]))
    return blocks


def find_heading(line):
    match = re.match(
        r"^\s*[\"'“”]?\s*([A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ][A-Za-zÁÉÍÓÚÀÂÊÔÃÕÜÇáéíóúàâêôãõüç\s\.]{1,64}?)\s*[—\-<]+\s*(.*)$",
        line,
    )
    if match:
        return normalize_label(match.group(1)), match.group(2).strip()

    match = re.match(r"^\s*TRANS\s+SPORTES\s*[—\-<]+\s*(.*)$", line, re.I)
    if match:
        return "transportes", match.group(1).strip()
    return None


def clean_section(value):
    value = re.split(
        r"\s+[\"'“”]?(?:MADEIRAS\s+de\s+lei|MINAS|MOLESTIAS(?:\s+da\s+popula[cç][aã]o)?|NUCLEOS(?:\s+coloniaes)?|PADR[OÕ]ES(?:\s+de\s+terras)?|SEMENTES|SEMEADURAS?|SYSTEMA(?:\s+de\s+trabalho)?|OPEROSIDADE(?:\s+da\s+popula[cç][aã]o)?)\s*[—\-<]+",
        value,
        maxsplit=1,
        flags=re.I,
    )[0]
    value = re.sub(r"\n\s*[-—]?\s*\d+\s*[-—]?\s*\n", " ", value)
    value = re.sub(r"\bSAL\b", " ", value)
    value = re.sub(r"(\w)-\s+(\w)", r"\1\2", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip(" ;,")


def extract_topics(block):
    out = {topic: [] for topic in TOPICS}
    current = None
    lines = []

    def flush():
        nonlocal current, lines
        if current in out:
            text = clean_section("\n".join(lines))
            if text:
                out[current].append(text)
        current = None
        lines = []

    for raw_line in block.splitlines():
        line = raw_line.strip()
        heading = find_heading(line)
        if heading:
            label, rest = heading
            if current == "terras" and label == "precos":
                lines.append(line)
                continue
            flush()
            current = label if label in out else None
            lines = [rest] if current and rest else []
            continue
        if current and line.upper() == "NOTA":
            flush()
            continue
        if current:
            lines.append(raw_line)
    flush()

    if not out["salarios"]:
        match = re.search(
            r"SYSTEMA[^\n]{0,140}[—\-<].*?\n(.*?)(?=\n\s*[\"'“”]?\s*TERRAS\s*[—\-<])",
            block,
            flags=re.I | re.S,
        )
        if match:
            fallback = clean_section(match.group(1))
            if fallback:
                out["salarios"].append(fallback)

    return {topic: " | ".join(out[topic]) for topic in TOPICS}


def main():
    pages = ocr_pdf()
    blocks = split_municipalities("\n".join(pages))
    rows = []
    for idx, (municipio, block) in enumerate(blocks, start=1):
        row = {"municipio": municipio or f"municipio_{idx:03d}"}
        row.update(extract_topics(block))
        rows.append(row)

    with open(OUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["municipio", *TOPICS])
        writer.writeheader()
        writer.writerows(rows)

    empty = {topic: [r["municipio"] for r in rows if not r[topic]] for topic in TOPICS}
    print(f"Wrote {len(rows)} rows to {OUT_CSV}")
    print("Empty topic fields:", empty)


if __name__ == "__main__":
    main()
