import pdfplumber
import pytesseract
import re
import csv
import json
import os

PDF_PATH = ("/Users/alaskievic/Library/CloudStorage/"
            "Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/"
            "sumoc_shared/questionario_agri/quest_agri_al.pdf")
CACHE_PATH = "/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/quest_agri_al_ocr_cache.json"
OUTPUT_CSV  = "/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/quest_agri_al.csv"

TARGETS = ["JUROS", "SALARIOS", "PORTOS", "TRANSPORTES", "TERRAS"]

# Official municipality list from the document index (alphabetical)
KNOWN_MUNIS = [
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

# ── OCR ──────────────────────────────────────────────────────────────────────

def ocr_all_pages(pdf_path, cache_path):
    if os.path.exists(cache_path):
        print("Loading OCR cache …")
        with open(cache_path) as f:
            return json.load(f)

    pages = []
    with pdfplumber.open(pdf_path) as pdf:
        n = len(pdf.pages)
        for i, page in enumerate(pdf.pages):
            print(f"  OCR page {i+1}/{n} …", flush=True)
            img = page.to_image(resolution=300).original
            text = pytesseract.image_to_string(img, lang="por")
            pages.append(text)

    with open(cache_path, "w") as f:
        json.dump(pages, f)
    return pages

# ── MUNICIPALITY SEGMENTATION ─────────────────────────────────────────────────

# Matches AGRICULTORES and common OCR variants (AGRICULIORES, AGRICUL CORES, etc.)
_AGRIC_RE = re.compile(
    r"AGRIC[A-Z][A-Z ]{3,7}(?:RES|ES|S)\s*[—\-<]"
)

def _is_title_line(line: str) -> bool:
    """True for lines that are OCR noise, page numbers, decorations, etc."""
    line = line.strip()
    if not line:
        return True
    if re.fullmatch(r"[-–—=\s\d\|]+", line):
        return True
    # Long all-caps lines are chapter titles, not municipality names
    if re.fullmatch(r"[A-ZÁÉÍÓÚÀÂÊÔÃÕÜ\s]+", line) and len(line) > 25:
        return True
    return False

def _clean_name(name: str) -> str:
    """Strip OCR artifacts from a municipality name candidate."""
    # Remove leading/trailing quotes, curly quotes, asterisks, stray letters
    name = re.sub(r'^[\"\"\'\*\"\'"]+', '', name)
    name = re.sub(r'[\"\"\'\*\"\'"]+$', '', name)
    # Remove a lone leading letter followed by space (e.g. "a Pilar")
    name = re.sub(r'^[a-z]\s+', '', name)
    return name.strip()

def split_municipalities(full_text):
    """
    Split full OCR text into (raw_name, block) pairs.
    Uses AGRICULTORES (+ OCR variants) as the reliable anchor.
    Municipality name is the last meaningful line before the anchor.
    """
    text = full_text.replace("\r\n", "\n").replace("\r", "\n")

    positions = [m.start() for m in _AGRIC_RE.finditer(text)]
    # Drop the very first hit if it's the document-level "CONDIÇÕES DA AGRICULTURA" header
    positions = [p for p in positions if 'ULTURA' not in text[p:p+12]]

    blocks = []
    for idx, pos in enumerate(positions):
        # Look back up to 500 chars for the municipality name
        preceding = text[max(0, pos - 500):pos]
        lines = [l.strip() for l in preceding.split("\n")]
        name = ""
        for line in reversed(lines):
            if _is_title_line(line):
                continue
            candidate = _clean_name(line)
            if candidate:
                name = candidate
                break

        end = positions[idx + 1] - 500 if idx + 1 < len(positions) else len(text)
        block = text[pos:end]
        blocks.append((name, block))

    return blocks

# ── SECTION EXTRACTION ────────────────────────────────────────────────────────

_DASHES = r"[—\-<]+"
_ACCENT_TRANS = str.maketrans({
    "Á": "A", "À": "A", "Â": "A", "Ã": "A", "Ä": "A",
    "É": "E", "È": "E", "Ê": "E", "Ë": "E",
    "Í": "I", "Ì": "I", "Î": "I", "Ï": "I",
    "Ó": "O", "Ò": "O", "Ô": "O", "Õ": "O", "Ö": "O",
    "Ú": "U", "Ù": "U", "Û": "U", "Ü": "U",
    "Ç": "C",
})

_HEADING_RE = re.compile(
    rf"^\s*[\"“”']?([A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ][A-Za-zÁÉÍÓÚÀÂÊÔÃÕÜÇáéíóúàâêôãõüç\s\.\"]{{1,55}}?)\s*{_DASHES}\s*(.*)$"
)

def _normalize_heading(label: str) -> str:
    label = label.upper().translate(_ACCENT_TRANS)
    label = re.sub(r"[^A-Z]+", "", label)
    label = re.sub(r"^(MADEIRAS|MOLESTIAS|NUCLEOS|PADROES|SEMENTES|SEMEADURAS|SEMEADURA|SYSTEMA|OPEROSIDADE|MINAS|NOTA).*$", r"\1", label)
    if label.startswith("SALARIO"):
        return "SALARIOS"
    if label.startswith("TRANSPORTE") or label.startswith("TRANSSPORTE"):
        return "TRANSPORTES"
    if label == "TRANS" or label.startswith("TRANSPORTE"):
        return "TRANSPORTES"
    if label.startswith("TERRAS"):
        return "TERRAS"
    if label.startswith("PORTOS"):
        return "PORTOS"
    if label.startswith("JUROS"):
        return "JUROS"
    if label in {"JUROS", "PORTOS", "TERRAS", "PRECOS"}:
        return label
    return label

def _is_heading_line(line: str):
    m = _HEADING_RE.match(line)
    if not m:
        return None
    label = _normalize_heading(m.group(1))
    return label, m.group(2).strip()

def _clean_section_text(text: str) -> str:
    text = re.split(
        rf"\s+[\"“”']?(?:MADEIRAS\s+de\s+lei|MINAS|MOLESTIAS(?:\s+da\s+popula[cç][aã]o)?|NUCLEOS(?:\s+coloniaes)?|PADR[OÕ]ES(?:\s+de\s+terras)?|SEMENTES|SEMEADURAS?|SYSTEMA(?:\s+de\s+trabalho)?|OPEROSIDADE(?:\s+da\s+popula[cç][aã]o)?)\s*{_DASHES}",
        text,
        maxsplit=1,
        flags=re.I,
    )[0]
    text = re.sub(r"\n\s*[-—]?\s*\d+\s*[-—]?\s*\n", " ", text)
    text = re.sub(r"\bSAL\b", " ", text)
    text = re.sub(r"(\w)-\s+(\w)", r"\1\2", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip(" ;,")

def extract_sections(block: str) -> dict[str, str]:
    sections = {kw: [] for kw in TARGETS}
    current = None
    current_lines = []

    def flush():
        nonlocal current, current_lines
        if current in sections:
            text = _clean_section_text("\n".join(current_lines))
            if text:
                sections[current].append(text)
        current = None
        current_lines = []

    lines = block.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        heading = _is_heading_line(line)

        # Tesseract sometimes splits "TRANSPORTES" into "TRANS SPORTES".
        if not heading and line.upper().startswith("TRANS SPORTES"):
            m = re.match(rf"^\s*TRANS\s+SPORTES\s*{_DASHES}\s*(.*)$", line, re.I)
            if m:
                heading = ("TRANSPORTES", m.group(1).strip())

        if heading:
            label, rest = heading
            if current == "TERRAS" and label == "PRECOS":
                current_lines.append(line)
                i += 1
                continue
            if current:
                flush()
            current = label if label in sections else None
            current_lines = [rest] if current and rest else []
        elif current and line.upper() == "NOTA":
            flush()
        elif current:
            current_lines.append(lines[i])
        i += 1
    flush()

    # On a few pages OCR drops the "SALARIOS" heading but leaves the wage
    # paragraph immediately before TERRAS, after the SYSTEMA heading.
    if not sections["SALARIOS"]:
        m = re.search(
            rf"SYSTEMA[^\n]{{0,120}}{_DASHES}.*?\n(.*?)(?=\n\s*TERRAS\s*{_DASHES})",
            block,
            flags=re.I | re.S,
        )
        if m:
            fallback = _clean_section_text(m.group(1))
            if fallback:
                sections["SALARIOS"].append(fallback)

    return {kw.lower(): " | ".join(sections[kw]) for kw in TARGETS}

# ── NAME RECONCILIATION ───────────────────────────────────────────────────────

def _strip_accents_lower(s: str) -> str:
    import unicodedata
    nfkd = unicodedata.normalize("NFKD", s)
    return "".join(c for c in nfkd if not unicodedata.combining(c)).lower()

def reconcile_names(raw_names: list[str], known: list[str]) -> list[str]:
    """
    Match each raw OCR name to the nearest known municipality name.
    Falls back to positional assignment if the block count matches.
    """
    if len(raw_names) == len(known):
        # Positional assignment — most reliable when counts match
        return list(known)

    # Otherwise, fuzzy-match by stripped name similarity
    result = []
    used = set()
    for raw in raw_names:
        raw_norm = _strip_accents_lower(raw)
        best, best_score = None, 0
        for k in known:
            k_norm = _strip_accents_lower(k)
            # Simple overlap score: longest common prefix or substring
            score = sum(1 for a, b in zip(raw_norm, k_norm) if a == b)
            if score > best_score and k not in used:
                best, best_score = k, score
        if best and best_score > 2:
            result.append(best)
            used.add(best)
        else:
            result.append(raw)  # keep raw if no good match
    return result

# ── MAIN ──────────────────────────────────────────────────────────────────────

def main():
    print("Step 1: OCR")
    pages = ocr_all_pages(PDF_PATH, CACHE_PATH)
    full_text = "\n".join(pages)

    print("Step 2: Segmenting municipalities …")
    blocks = split_municipalities(full_text)
    raw_names = [name for name, _ in blocks]
    print(f"  Found {len(blocks)} municipality blocks (expected 35)")

    print("Step 3: Reconciling names …")
    final_names = reconcile_names(raw_names, KNOWN_MUNIS)
    for raw, final in zip(raw_names, final_names):
        marker = "" if raw == final else f"  ← was: {repr(raw)}"
        print(f"  {final}{marker}")

    print("Step 4: Extracting sections …")
    rows = []
    for (_, block), name in zip(blocks, final_names):
        row = {"municipio": name}
        row.update(extract_sections(block))
        rows.append(row)

    print(f"Step 5: Writing {OUTPUT_CSV} …")
    fieldnames = ["municipio"] + [kw.lower() for kw in TARGETS]
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Done — {len(rows)} rows written.")

if __name__ == "__main__":
    main()
