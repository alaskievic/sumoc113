import csv
import json
import os
import re
import unicodedata

import pdfplumber
import pytesseract


PDF_PATH = (
    "/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/"
    "Andrei Arminio Laskievic/sumoc_shared/questionario_agri/quest_agri_al.pdf"
)
OCR_JSON = "quest_agri_al_fresh_ocr.json"
OUT_CSV = "quest_agri_al_fresh.csv"

FIELDS = ["juros", "salarios", "portos", "transportes", "terras"]

# Transcribed from the document's municipality ordering. This avoids letting
# isolated OCR damage in a section title become the municipality identifier.
MUNICIPALITIES = [
    "Agua Branca",
    "Alagoas",
    "Anadia",
    "Atalaia",
    "Bello Monte",
    "Coruripe",
    "Euclydes Malta",
    "Junqueiro",
    "Leopoldina",
    "Limoeiro",
    "Maceio",
    "Maragogy",
    "Muricy",
    "Palmeira dos Indios",
    "Pao de Assucar",
    "Passo de Camaragibe",
    "Paulo Affonso",
    "Penedo",
    "Piassabussu",
    "Pilar",
    "Piranhas",
    "Porto Calvo",
    "Porto de Pedra",
    "Porto Real do Collegio",
    "Sant'Anna do Ipanema",
    "Santa Luzia do Norte",
    "Sao Braz",
    "S. Jose da Lage",
    "Sao Luiz do Quitunde",
    "S. Miguel de Campos",
    "Traipu",
    "Triumpho",
    "Uniao",
    "Vicosa",
    "Victoria",
]


def ocr_pdf():
    if os.path.exists(OCR_JSON):
        with open(OCR_JSON, encoding="utf-8") as f:
            return json.load(f)

    texts = []
    with pdfplumber.open(PDF_PATH) as pdf:
        total = len(pdf.pages)
        for page_no, page in enumerate(pdf.pages, start=1):
            print(f"OCR {page_no}/{total}", flush=True)
            image = page.to_image(resolution=300).original
            texts.append(pytesseract.image_to_string(image, lang="por"))

    with open(OCR_JSON, "w", encoding="utf-8") as f:
        json.dump(texts, f, ensure_ascii=False)
    return texts


def strip_accents(value):
    normalized = unicodedata.normalize("NFKD", value)
    return "".join(ch for ch in normalized if not unicodedata.combining(ch))


def normalize_heading(value):
    value = strip_accents(value.upper())
    value = re.sub(r"[^A-Z]+", "", value)
    if value.startswith("JUROS"):
        return "juros"
    if value.startswith("SALARIO"):
        return "salarios"
    if value.startswith("PORTOS"):
        return "portos"
    if value.startswith("TRANSPORTE") or value.startswith("TRANSSPORTE"):
        return "transportes"
    if value in {"TRANS", "TRANSPORT"}:
        return "transportes"
    if value.startswith("TERRAS"):
        return "terras"
    if value.startswith("PRECO"):
        return "precos"
    return value.lower()


def split_municipality_blocks(full_text):
    anchor = re.compile(r"AGRIC[A-Z][A-Z ]{3,10}(?:RES|ES|S)\s*[—\-<]", re.I)
    starts = [match.start() for match in anchor.finditer(full_text)]
    starts = [pos for pos in starts if "ULTURA" not in full_text[pos : pos + 14].upper()]
    blocks = []
    for idx, start in enumerate(starts):
        end = starts[idx + 1] - 500 if idx + 1 < len(starts) else len(full_text)
        blocks.append(full_text[start:end])
    return blocks


def find_heading(line):
    match = re.match(
        r"^\s*[\"'“”]?\s*([A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ][A-Za-zÁÉÍÓÚÀÂÊÔÃÕÜÇáéíóúàâêôãõüç\s\.]{1,60}?)\s*[—\-<]+\s*(.*)$",
        line,
    )
    if match:
        return normalize_heading(match.group(1)), match.group(2).strip()

    match = re.match(r"^\s*TRANS\s+SPORTES\s*[—\-<]+\s*(.*)$", line, re.I)
    if match:
        return "transportes", match.group(1).strip()

    return None


def clean_text(value):
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
    collected = {field: [] for field in FIELDS}
    current = None
    current_lines = []

    def save_current():
        nonlocal current, current_lines
        if current in collected:
            text = clean_text("\n".join(current_lines))
            if text:
                collected[current].append(text)
        current = None
        current_lines = []

    for raw_line in block.splitlines():
        line = raw_line.strip()
        heading = find_heading(line)

        if heading:
            label, remainder = heading
            if current == "terras" and label == "precos":
                current_lines.append(line)
                continue
            save_current()
            current = label if label in collected else None
            current_lines = [remainder] if current and remainder else []
            continue

        if current and line.upper() == "NOTA":
            save_current()
            continue

        if current:
            current_lines.append(raw_line)

    save_current()

    if not collected["salarios"]:
        match = re.search(
            r"SYSTEMA[^\n]{0,120}[—\-<].*?\n(.*?)(?=\n\s*[\"'“”]?\s*TERRAS\s*[—\-<])",
            block,
            flags=re.I | re.S,
        )
        if match:
            fallback = clean_text(match.group(1))
            if fallback:
                collected["salarios"].append(fallback)

    return {field: " | ".join(collected[field]) for field in FIELDS}


def main():
    pages = ocr_pdf()
    blocks = split_municipality_blocks("\n".join(pages))
    if len(blocks) != len(MUNICIPALITIES):
        raise RuntimeError(f"Expected {len(MUNICIPALITIES)} municipality blocks, found {len(blocks)}")

    rows = []
    for municipality, block in zip(MUNICIPALITIES, blocks):
        row = {"municipio": municipality}
        row.update(extract_topics(block))
        rows.append(row)

    with open(OUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["municipio", *FIELDS])
        writer.writeheader()
        writer.writerows(rows)

    empty = {
        field: [row["municipio"] for row in rows if not row[field]]
        for field in FIELDS
    }
    print(f"Wrote {len(rows)} rows to {OUT_CSV}")
    print("Empty fields:", empty)


if __name__ == "__main__":
    main()
