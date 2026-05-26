#!/usr/bin/env python3
import argparse
import csv
import json
import os
import re
import subprocess
import tempfile
import unicodedata
from dataclasses import dataclass
from pathlib import Path

import pdfplumber
from PIL import Image


DEFAULT_PDF = (
    "/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/"
    "Andrei Arminio Laskievic/sumoc_shared/questionario_agri/quest_agri_sc.pdf"
)
DEFAULT_OUT_CSV = "quest_agri_sc.csv"
DEFAULT_OCR_JSON = "quest_agri_sc_ocr.json"

TOPICS = ["juros", "salarios", "portos", "transportes", "terras"]
OCR_LANG = "por+eng"
OCR_PSM = "4"
GS_DPI = "300"

_DASHES = r"[—–\-<]+"
_AGRICULTORES_WORD = r"AGRIC[UO0I][LI1]?\s*(?:T|I|L|C)?\s*[O0C]?\s*R\s*[E3]?\s*['’]?\s*S"
_AGRIC_RE = re.compile(
    rf"\b{_AGRICULTORES_WORD}\s*(?:{_DASHES}|(?=[(]?\s*[Cc][O0oUu][Nn][Dd][Ii]))"
)

# Repairs observed in the Santa Catharina index/header OCR. They keep the
# index-based page segmentation but avoid using damaged OCR as identifiers.
NAME_REPAIRS = {
    "brusqtte": "Brusque",
    "camburiu": "Camburiú",
    "cumburiu": "Camburiú",
    "coritybanos": "Curitybanos",
    "curitybanos": "Curitybanos",
    "imarthy": "Imaruhy",
    "imaruhy": "Imaruhy",
    "itajalry": "Itajahy",
    "itajahy": "Itajahy",
    "palhoga": "Palhoça",
    "palhoca": "Palhoça",
    "s bento": "São Bento",
    "sao bento": "São Bento",
    "s francisco": "São Francisco",
    "sao francisco": "São Francisco",
    "s joaquim da costa da serra": "São Joaquim da Costa da Serra",
    "sao joaquim da costa da serra": "São Joaquim da Costa da Serra",
    "s jose": "São José",
    "sao jose": "São José",
    "tubarao": "Tubarão",
    "fame montenegro": "Montenegro",
    "vcpelagal repre sentada pur wwnattas cah iras ccermulos calnpos": "Porto de Móz",
    "soure in lia de marajo": "Soure (Ilha Marajó)",
}

# OCR-specific index page repairs, keyed by PDF stem. These only repair damaged
# page numbers in the document index; segmentation remains index-based.
INDEX_PAGE_REPAIRS_BY_STEM = {
    # Santa Catharina: Araranguá reads as "4.." and Curitybanos as "a?".
    "quest_agri_sc": {1: 1, 9: 27},
}

STOP_HEADINGS = (
    "AGUAS",
    "ARVORES",
    "ALIMENTACAO",
    "CAMPOS",
    "CULTURAS",
    "COLHEITAS",
    "CEREAES",
    "CANNA",
    "COOPERATIVAS",
    "CALOR",
    "CHUVAS",
    "CONDICOES",
    "CONTABILIDADE",
    "CRIACAO",
    "CUSTO",
    "ESTRADAS",
    "EXPORTACAO",
    "ESCOLAS",
    "FABRICAS",
    "FARINHA",
    "HYPOTHECAS",
    "HABITACOES",
    "INSTRUMENTOS",
    "MADEIRAS",
    "MINAS",
    "MOLESTIAS",
    "NUCLEOS",
    "OPEROSIDADE",
    "PADROES",
    "PORTOS",
    "PROPRIEDADES",
    "SALARIOS",
    "SEMENTES",
    "SEMEADURA",
    "SEMEADURAS",
    "SYSTEMA",
    "TERRAS",
    "TRANSPORTES",
    "JUROS",
)


@dataclass
class IndexEntry:
    number: int
    index_name: str
    printed_start: int
    pdf_start: int
    pdf_end: int


def strip_accents(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    return "".join(ch for ch in normalized if not unicodedata.combining(ch))


def compact_key(value: str) -> str:
    value = strip_accents(value.lower())
    value = re.sub(r"[^a-z0-9]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def page_count(pdf_path: str) -> int:
    with pdfplumber.open(pdf_path) as pdf:
        return len(pdf.pages)


def run_checked(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True, errors="replace")


def render_page_with_ghostscript(pdf_path: str, page_no: int, out_png: str) -> None:
    subprocess.run(
        [
            "gs",
            "-q",
            "-dSAFER",
            "-dBATCH",
            "-dNOPAUSE",
            "-sDEVICE=pnggray",
            f"-r{GS_DPI}",
            f"-dFirstPage={page_no}",
            f"-dLastPage={page_no}",
            f"-sOutputFile={out_png}",
            pdf_path,
        ],
        check=True,
    )


def ocr_png(path: str) -> str:
    completed = subprocess.run(
        ["tesseract", path, "stdout", "-l", OCR_LANG, "--psm", OCR_PSM],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        errors="replace",
    )
    return clean_ocr_text(completed.stdout)


def clean_ocr_text(text: str) -> str:
    text = re.sub(r"(?m)^Detected\s+\d+\s+diacritics\s*$", "", text)
    return text


def load_cache(path: str) -> dict:
    if not os.path.exists(path):
        return {"renderer": f"ghostscript_{GS_DPI}dpi", "ocr": f"tesseract_{OCR_LANG}_psm{OCR_PSM}", "pages": {}}
    with open(path, encoding="utf-8") as f:
        cache = json.load(f)
    cache.setdefault("pages", {})
    return cache


def save_cache(path: str, cache: dict) -> None:
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)
    os.replace(tmp, path)


def ocr_pages(pdf_path: str, cache_path: str, pages: list[int]) -> dict[int, str]:
    cache = load_cache(cache_path)
    out: dict[int, str] = {}
    missing = [p for p in pages if str(p) not in cache["pages"]]
    if missing:
        print(
            f"OCR {len(missing)} uncached page(s) with Ghostscript {GS_DPI} DPI and "
            f"Tesseract {OCR_LANG} --psm {OCR_PSM}",
            flush=True,
        )

    with tempfile.TemporaryDirectory(prefix="quest_agri_ocr_") as tmpdir:
        for idx, page_no in enumerate(missing, start=1):
            png = os.path.join(tmpdir, f"page_{page_no:04d}.png")
            print(f"  OCR page {page_no} ({idx}/{len(missing)})", flush=True)
            render_page_with_ghostscript(pdf_path, page_no, png)
            cache["pages"][str(page_no)] = ocr_png(png)
            save_cache(cache_path, cache)

    for page_no in pages:
        key = str(page_no)
        cleaned = clean_ocr_text(cache["pages"][key])
        if cleaned != cache["pages"][key]:
            cache["pages"][key] = cleaned
            save_cache(cache_path, cache)
        out[page_no] = cleaned
    return out


def render_page_image(pdf_path: str, page_no: int, tmpdir: str) -> str:
    png = os.path.join(tmpdir, f"page_{page_no:04d}.png")
    render_page_with_ghostscript(pdf_path, page_no, png)
    return png


def crop_half_image(path: str, side: str, out_path: str) -> None:
    image = Image.open(path)
    width, height = image.size
    mid = width // 2
    if side == "left":
        box = (0, 0, mid, height)
    else:
        box = (mid, 0, width, height)
    image.crop(box).save(out_path)


def crop_vertical_fraction(path: str, start: float, end: float, out_path: str) -> None:
    image = Image.open(path)
    width, height = image.size
    left = max(0, min(width, int(width * start)))
    right = max(0, min(width, int(width * end)))
    image.crop((left, 0, right, height)).save(out_path)


def ocr_index_pages_for_parsing(pdf_path: str, cache_path: str, index_pages: list[int]) -> str:
    cache = load_cache(cache_path)
    cache.setdefault("index_page_slices_v3", {})
    pieces = []

    with tempfile.TemporaryDirectory(prefix="quest_agri_index_") as tmpdir:
        for page_no in index_pages:
            page_key = str(page_no)
            full_text = cache["pages"].get(page_key)
            if full_text:
                pieces.append(full_text)

            slice_texts = cache["index_page_slices_v3"].setdefault(page_key, {})
            slices = {
                "left": (0.0, 0.5),
                "right": (0.5, 1.0),
                "left_col": (0.0, 0.43),
                "right_col": (0.40, 0.82),
            }
            missing = [name for name in slices if name not in slice_texts]
            if missing:
                png = render_page_image(pdf_path, page_no, tmpdir)
                for name in missing:
                    crop_path = os.path.join(tmpdir, f"page_{page_no:04d}_{name}.png")
                    start, end = slices[name]
                    crop_vertical_fraction(png, start, end, crop_path)
                    slice_texts[name] = ocr_png(crop_path)
                save_cache(cache_path, cache)

            pieces.extend(slice_texts.get(name, "") for name in ("left", "right", "left_col", "right_col"))

    return "\n".join(piece for piece in pieces if piece)


def two_up_location(index_end_page: int, printed_page: int, first_side: str) -> tuple[int, str]:
    if first_side == "right":
        if printed_page == 1:
            return index_end_page, "right"
        offset = printed_page - 2
        return index_end_page + 1 + (offset // 2), "left" if offset % 2 == 0 else "right"

    offset = printed_page - 1
    return index_end_page + (offset // 2), "left" if offset % 2 == 0 else "right"


def ocr_two_up_printed_pages(
    pdf_path: str,
    cache_path: str,
    index_end_page: int,
    printed_pages: list[int],
    first_side: str,
) -> dict[int, str]:
    cache = load_cache(cache_path)
    cache.setdefault("logical_pages", {})
    out: dict[int, str] = {}

    missing = [p for p in printed_pages if str(p) not in cache["logical_pages"]]
    if missing:
        print(
            f"OCR {len(missing)} uncached two-up logical page(s) with Ghostscript {GS_DPI} DPI "
            f"and Tesseract {OCR_LANG} --psm {OCR_PSM}",
            flush=True,
        )

    with tempfile.TemporaryDirectory(prefix="quest_agri_twoup_") as tmpdir:
        rendered: dict[int, str] = {}
        for idx, printed_page in enumerate(missing, start=1):
            pdf_page, side = two_up_location(index_end_page, printed_page, first_side)
            if pdf_page not in rendered:
                rendered[pdf_page] = render_page_image(pdf_path, pdf_page, tmpdir)
            crop_path = os.path.join(tmpdir, f"logical_{printed_page:04d}_{side}.png")
            print(
                f"  OCR printed page {printed_page} from PDF page {pdf_page} {side} "
                f"({idx}/{len(missing)})",
                flush=True,
            )
            crop_half_image(rendered[pdf_page], side, crop_path)
            cache["logical_pages"][str(printed_page)] = ocr_png(crop_path)
            save_cache(cache_path, cache)

    for printed_page in printed_pages:
        out[printed_page] = cache["logical_pages"][str(printed_page)]
    return out


def normalize_heading(value: str) -> str:
    label = strip_accents(value.upper())
    label = re.sub(r"[^A-Z]+", "", label)
    if label.startswith("PADRO"):
        return "padroes"
    if label.startswith("JUROS") or "JUROS" in label:
        return "juros"
    if label.startswith("SALARIO") or "SALARIO" in label:
        return "salarios"
    if label.startswith("PORTOS") or "PORTOS" in label:
        return "portos"
    if (
        label.startswith("TRANSPORTE")
        or label.startswith("TRANSSPORTE")
        or "TRANSPORTE" in label
        or "TRANSSPORTE" in label
        or "RANSPORTE" in label
    ):
        return "transportes"
    if label in {"TRANS", "TRANSPORT", "TRANSP"}:
        return "transportes"
    if label.startswith("TERRAS") or label.startswith("TERAS") or label.startswith("TRRAS") or label.startswith("TRRRAS"):
        return "terras"
    if label.startswith("PRECO") or "PRECO" in label:
        return "precos"
    return label.lower()


# Heading "name" is capped at 32 chars and the remainder must be non-empty so
# word-internal hyphenations like "aos alaga-\n" stop matching as bogus
# headings (the original 70-char limit + optional empty remainder swallowed
# whole sentence fragments that happened to end in a hyphen).
_HEADING_RE = re.compile(
    rf"^\s*(?:[-—–_]\s*)?(?:[a-z]{{1,3}}\s+)?[\"'“”]?\s*"
    rf"([A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ][A-Za-zÁÉÍÓÚÀÂÊÔÃÕÜÇáéíóúàâêôãõüç\s\.\"]{{1,32}}?)"
    rf"\s*{_DASHES}\s*(.+)$"
)


def find_heading(line: str) -> tuple[str, str] | None:
    match = _HEADING_RE.match(line)
    if match:
        return normalize_heading(match.group(1)), match.group(2).strip()

    match = re.match(rf"^\s*TRANS\s+SPORTES\s*{_DASHES}\s*(.*)$", line, re.I)
    if match:
        return "transportes", match.group(1).strip()

    match = re.match(rf"^\s*TRANSP\s+ORTES\s*{_DASHES}\s*(.*)$", line, re.I)
    if match:
        return "transportes", match.group(1).strip()

    return None


def is_bare_stop_heading(line: str) -> bool:
    label = strip_accents(line.upper())
    label = re.sub(r"[^A-Z]+", "", label)
    return label in {"MADEIRASDELEI", "MADEIRASDELE", "MADEIRASDELEL"}


def strip_repeated_current_heading(value: str, current: str | None) -> str:
    if not current:
        return value
    topic_patterns = {
        "juros": r"JUROS",
        "salarios": r"SAL[ÁA]RIOS",
        "portos": r"PORTOS",
        "transportes": r"TRANS\s*PORTES|TRANSP\s*ORTES|TRANSPORTES|PRANSPORTES",
        "terras": r"T[ER]{1,3}RAS",
    }
    pattern = topic_patterns.get(current)
    if not pattern:
        return value
    matches = list(
        re.finditer(rf"[\"'“”‘’«»]?\s*(?:{pattern})\s*{_DASHES}\s*", value, flags=re.I)
    )
    if matches:
        return value[matches[-1].end() :]
    return value


def clean_section_text(value: str, current: str | None = None) -> str:
    value = strip_repeated_current_heading(value, current)
    stop_pattern = "|".join(
        [
            r"M[AÁ]DEIRAS\s+de\s+l\w{0,3}:?",
            r"JUROS",
            r"MINAS",
            r"MOLESTIAS(?:\s+da\s+popula[cç][aã]o)?",
            r"N[UÚ]CLEOS(?:\s+coloniaes)?",
            r"OPEROSIDADE(?:\s+da\s+popula[cç][aã]o)?",
            r"PADR[OÕ]ES(?:\s+de\s+terras)?",
            r"PORTOS",
            r"SAL[ÁA]RIOS",
            r"SEMENTES",
            r"SEMEADURAS?",
            r"SYSTEMA(?:\s+de\s+trabalho)?",
            r"T[ER]{1,3}RAS",
            r"TRANSPORTES",
        ]
    )
    # Require trailing dashes so the split only fires on actual heading bleed
    # ("TERRAS —") and not on the same word appearing in body text ("terras
    # são bôas").  Previously the dashes were optional, which truncated many
    # TERRAS rows the moment the word "terras" appeared in the Qualidades
    # description.
    value = re.split(
        rf"(?:^|\s+)[\"'“”‘’«»]?(?:{stop_pattern})\s*{_DASHES}",
        value,
        maxsplit=1,
        flags=re.I,
    )[0]
    value = re.sub(r"\n\s*[-—–]?\s*\d+\s*[-—–]?\s*\n", " ", value)
    value = re.sub(r"\bSAL\b", " ", value)
    value = re.sub(r"(\w)-\s+(\w)", r"\1\2", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip(" ;,")


def extract_topics(block: str) -> dict[str, str]:
    collected = {topic: [] for topic in TOPICS}
    current: str | None = None
    current_lines: list[str] = []

    def flush() -> None:
        nonlocal current, current_lines
        if current in collected:
            text = clean_section_text("\n".join(current_lines), current)
            if text:
                collected[current].append(text)
        current = None
        current_lines = []

    for raw_line in block.replace("\r\n", "\n").replace("\r", "\n").splitlines():
        line = raw_line.strip()
        heading = find_heading(line)

        if heading:
            label, remainder = heading
            if current == "terras" and label == "precos":
                current_lines.append(line)
                continue
            flush()
            current = label if label in collected else None
            current_lines = [remainder] if current and remainder else []
            continue

        if current and line.upper() == "NOTA":
            flush()
            continue

        if current and is_bare_stop_heading(line):
            flush()
            continue

        if current:
            current_lines.append(raw_line)

    flush()

    # Preserve the prior fallback: on some pages OCR drops SALARIOS but leaves
    # the wage paragraph immediately before TERRAS, after SYSTEMA.
    if not collected["salarios"]:
        match = re.search(
            rf"SYSTEMA[^\n]{{0,140}}{_DASHES}.*?\n(.*?)(?=\n\s*[\"'“”]?\s*TERRAS\s*{_DASHES})",
            block,
            flags=re.I | re.S,
        )
        if match:
            fallback = clean_section_text(match.group(1))
            if fallback:
                collected["salarios"].append(fallback)

    return {topic: " | ".join(collected[topic]) for topic in TOPICS}


def clean_index_name(value: str) -> str:
    value = re.sub(r"\bInspec[cç][aã]o\b.*$", "", value, flags=re.I)
    value = re.split(r"\s+[»\"]\s*", value, maxsplit=1)[0]
    value = re.split(r"\.{2,}", value, maxsplit=1)[0]
    value = re.split(r"\.\s+(?=[A-Za-zÁÉÍÓÚÀÂÊÔÃÕÜÇáéíóúàâêôãõüç]{3,}\b)", value, maxsplit=1)[0]
    value = re.sub(r"^[\"'“”*]+|[\"'“”*]+$", "", value.strip())
    value = re.sub(r"^[a-z]\s+", "", value)
    value = re.sub(r"^[58]\.", "S.", value)
    value = re.sub(r"\s+", " ", value).strip(" .,:;©®")
    return repair_name(value)


def repair_name(value: str) -> str:
    value = re.sub(r"\s+", " ", value).strip(" .,:;©®")
    key = compact_key(value)
    if key in NAME_REPAIRS:
        return NAME_REPAIRS[key]
    return value


def clean_body_header_name(value: str) -> str:
    value = repair_name(value)
    value = re.sub(r"^[|\"'“”‘’«»*]+|[|\"'“”‘’«»*]+$", "", value.strip())
    value = re.sub(r"^[—–\-]+\s*\d+\s*[—–\-]+\s*", "", value)
    value = re.sub(r"^\d{1,4}\s+(?=[A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ])", "", value)
    value = re.sub(
        r"^(?:Municipio|Município|Wunicipio|Wiunicipio|Wiunicivio)\s*[,.\-]?\s*d(?:[seéoa]s?)?\s+",
        "",
        value,
        flags=re.I,
    )
    value = re.sub(r"^(?:Municipio|Município|Wunicipio|Wiunicipio|Wiunicivio)\s+", "", value, flags=re.I)
    value = re.sub(r"^d[eéoa]s?\s+(?=[A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ])", "", value, flags=re.I)
    value = re.sub(r"^[58]\.", "S.", value)
    value = re.sub(r"^[a-z]\s+(?=[A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ])", "", value)
    value = re.sub(r"\s+", " ", value).strip(" .,:;©®-")
    return repair_name(value)


def plausible_header_name(value: str) -> bool:
    if not value or len(value) > 80:
        return False
    if len(value) < 3:
        return False
    if re.search(r"\d", value):
        return False
    if re.search(r"[+=]", value):
        return False
    if "—" in value or " - " in value:
        return False
    if not re.match(r"[A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇS|]", value):
        return False
    normalized = compact_key(value)
    if normalized in {"jt o"}:
        return False
    bad_terms = {
        "agricultores",
        "aguas superficiaes",
        "alimentacao",
        "a maior queixa",
        "condicoes economicas",
        "economicas",
        "engenhos",
        "estrangeiros",
        "existe neste",
        "impostos",
        "instrumentos",
        "mattas",
        "o estado",
        "seguem os processos",
        "sobre o valor",
        "terras",
        "transporte",
        "valor venal",
    }
    if any(term in normalized for term in bad_terms):
        return False
    if re.match(r"^[a-záéíóúàâêôãõç]", value):
        return False
    return True


def parse_index_entries(
    index_text: str,
    printed_page_offset: int,
    total_pages: int,
    index_page_repairs: dict[int, int] | None = None,
) -> tuple[list[IndexEntry], int | None]:
    index_page_repairs = index_page_repairs or {}
    parsed: list[tuple[int, str, int]] = []
    after_muni_printed: int | None = None
    logical_records: list[tuple[str, str]] = []
    current_token: str | None = None
    current_parts: list[str] = []

    def entry_start(line: str) -> tuple[str, str] | None:
        line = re.sub(r"^\s*[0-9A-Za-z$|]{1,4}\s*\|\s*", "", line)
        match = re.match(
            r"^\s*[-—–:;,.\"'“”‘’\[]*\s*(?:[A-Za-z]\s+)?([0-9]{1,3}|[A-Za-z$§&]{1,3}|[A-Za-z$§&]?\d[A-Za-z$§&]?)\s*(?:[—–\-:.]+\s*|\s+)(.+)$",
            line,
        )
        if not match:
            return None
        rest = match.group(2).strip().lstrip("—–-:;,.~ ")
        if not re.match(r"[\[A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ8S$§\"'“”‘’]", rest):
            return None
        return match.group(1), rest

    def flush_record() -> None:
        nonlocal current_token, current_parts
        if current_token and current_parts:
            logical_records.append((current_token, " ".join(current_parts)))
        current_token = None
        current_parts = []

    for raw_line in index_text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        normalized = strip_accents(line.upper()).strip()
        if (
            "MEDIDAS AGRARIAS" in normalized
            or "MEDIDAS DE CAPACIDADE" in normalized
            or normalized.startswith("QUADRO ")
        ):
            page = parse_printed_page(line, total_pages)
            if page and (after_muni_printed is None or page > after_muni_printed):
                after_muni_printed = page
            flush_record()
            continue
        if normalized.startswith(("PAGS", "PAG.", "INDICE", "DOS ", "MUNICIPIOS", "MUNICÍPIOS")):
            continue
        start = entry_start(line)
        if start:
            flush_record()
            current_token, rest = start
            current_parts = [rest]
            continue
        if current_parts and not re.search(r"\b(?:AGRICULTORES|CONDICOES DA AGRICULTURA)\b", normalized):
            current_parts.append(line)

    flush_record()

    seen_numbers: set[int] = set()
    previous_number = 0
    by_number: dict[int, tuple[str, int | None]] = {}

    for token, record in logical_records:
        raw_number = parse_entry_number(token)
        if raw_number is not None and raw_number <= total_pages:
            number = raw_number
            used_raw_number = True
        else:
            number = previous_number + 1
            used_raw_number = False
        if not used_raw_number and number <= previous_number and number in seen_numbers:
            number = previous_number + 1
        if not used_raw_number:
            previous_number = max(previous_number, number)
        elif number > previous_number:
            previous_number = number

        if number in index_page_repairs:
            printed_page: int | None = index_page_repairs[number]
        else:
            printed_page = parse_printed_page(record, total_pages)

        name = clean_index_name(remove_printed_page_tail(record))
        if not name:
            continue

        existing = by_number.get(number)
        if (
            existing is None
            or (existing[1] is None and printed_page is not None)
            or (printed_page is not None and len(name) > len(existing[0]) and len(name) < 80)
        ):
            by_number[number] = (name, printed_page)
        seen_numbers.add(number)

    by_number = mark_nonmonotonic_pages_missing(by_number)
    repaired_pages = fill_missing_printed_pages(by_number)
    for number in sorted(repaired_pages):
        name, printed_page = repaired_pages[number]
        if printed_page is None:
            raise RuntimeError(f"Could not parse printed page from index entry {number}: {name!r}")
        parsed.append((number, name, printed_page))

    if not parsed:
        raise RuntimeError("No municipality entries found in the OCR index page")

    if after_muni_printed is not None and after_muni_printed <= parsed[-1][2]:
        after_muni_printed = None

    entries: list[IndexEntry] = []
    for idx, (number, name, printed_start) in enumerate(parsed):
        pdf_start = printed_page_offset + printed_start
        if idx + 1 < len(parsed):
            next_printed = parsed[idx + 1][2]
        else:
            next_printed = after_muni_printed
        pdf_end = printed_page_offset + next_printed - 1 if next_printed else total_pages
        pdf_end = min(pdf_end, total_pages)
        entries.append(IndexEntry(number, name, printed_start, pdf_start, pdf_end))

    return entries, after_muni_printed


def parse_entry_number(token: str) -> int | None:
    token = token.strip()
    if token.isdigit():
        return int(token)
    return None


def parse_ocr_number_token(token: str) -> int | None:
    token = token.strip().strip(".,;:()[]{}'\"“”")
    if not token:
        return None
    translation = str.maketrans(
        {
            "O": "0",
            "o": "0",
            "Q": "0",
            "I": "1",
            "l": "1",
            "|": "1",
            "Z": "2",
            "z": "2",
            "a": "2",
            "A": "4",
            "E": "3",
            "S": "5",
            "s": "5",
            "$": "5",
            "b": "6",
            "G": "6",
            "g": "9",
            "q": "9",
            "d": "4",
        }
    )
    converted = re.sub(r"[^0-9]", "", token.translate(translation))
    if not converted:
        return None
    value = int(converted)
    if len(converted) == 4 and 1850 <= value <= 1930:
        return None
    return value


def parse_printed_page(text: str, total_pages: int) -> int | None:
    if "|" in text:
        first_segment = text.split("|", 1)[0]
        value = parse_printed_page(first_segment, total_pages)
        if value is not None:
            return value
    tail_match = re.search(r"([0-9A-Za-z$|]{1,4})\D*$", text)
    if not tail_match:
        return None
    value = parse_ocr_number_token(tail_match.group(1))
    if value is None or value < 1 or value > max(total_pages * 2, total_pages + 20):
        return None
    return value


def remove_printed_page_tail(text: str) -> str:
    if "|" in text:
        text = text.split("|", 1)[0]
    text = re.sub(r"([.,;:\s]{2,}|[.]{2,})[0-9A-Za-z$|]{1,4}\D*$", "", text).strip()
    text = re.sub(r"\b(?:18|19|20)\d{2}\D*$", "", text).strip()
    return text


def fill_missing_printed_pages(
    by_number: dict[int, tuple[str, int | None]]
) -> dict[int, tuple[str, int | None]]:
    numbers = sorted(by_number)
    repaired = dict(by_number)
    for i, number in enumerate(numbers):
        name, page = repaired[number]
        if page is not None:
            continue

        prev_page = None
        next_page = None
        for prev_number in reversed(numbers[:i]):
            if repaired[prev_number][1] is not None:
                prev_page = repaired[prev_number][1]
                break
        for next_number in numbers[i + 1 :]:
            if repaired[next_number][1] is not None:
                next_page = repaired[next_number][1]
                break

        if prev_page is not None and next_page is not None and next_page > prev_page:
            gap = max(1, round((next_page - prev_page) / (next_number - prev_number)))
            page = min(next_page - 1, prev_page + gap)
        elif prev_page is not None:
            page = prev_page + 3
        repaired[number] = (name, page)
    return repaired


def mark_nonmonotonic_pages_missing(
    by_number: dict[int, tuple[str, int | None]]
) -> dict[int, tuple[str, int | None]]:
    repaired = dict(by_number)
    numbers = sorted(repaired)
    for idx, number in enumerate(numbers):
        name, page = repaired[number]
        if page is None:
            continue

        prev_page = None
        for prev_number in reversed(numbers[:idx]):
            candidate = repaired[prev_number][1]
            if candidate is not None:
                prev_page = candidate
                break

        next_page = None
        for next_number in numbers[idx + 1 :]:
            candidate = repaired[next_number][1]
            if candidate is not None:
                next_page = candidate
                break

        if (prev_page is not None and page <= prev_page) or (next_page is not None and page >= next_page):
            repaired[number] = (name, None)
    return repaired


def looks_like_index_page(text: str) -> bool:
    normalized = strip_accents(text.upper())
    if "INDICE" in normalized and ("MUNICIP" in normalized or "PAGS" in normalized):
        return True
    numbered_entries = index_entry_line_count(text)
    if numbered_entries >= 3:
        return True
    if "MEDIDAS AGRARIAS" in normalized or "MEDIDAS DE CAPACIDADE" in normalized:
        return True
    return False


def contains_municipality_body_start(text: str) -> bool:
    normalized = strip_accents(text.upper())
    return bool(_AGRIC_RE.search(normalized)) or "CONDICOES DA AGRICULTURA" in normalized


def index_entry_line_count(text: str) -> int:
    numbered_entries = 0
    for line in text.splitlines():
        if re.match(
            r"^\s*[-—–:;,.\"'“”‘’\[]*\s*(?:[A-Za-z]\s+)?([0-9]{1,3}|[A-Za-z$§&]{1,3}|[A-Za-z$§&]?\d[A-Za-z$§&]?)\s*(?:[—–\-:.]+\s*|\s+)",
            line,
        ) and (parse_printed_page(line, 1000) is not None or "Inspec" in line):
            numbered_entries += 1
    return numbered_entries


def find_index_pages(pdf_path: str, cache_path: str, max_scan_pages: int) -> tuple[int, int, str]:
    page_nos = list(range(1, max_scan_pages + 1))
    texts = ocr_pages(pdf_path, cache_path, page_nos)
    index_start = None
    for page_no, text in texts.items():
        normalized = strip_accents(text.upper())
        if "INDICE" in normalized and ("MUNICIP" in normalized or "PAGS" in normalized):
            index_start = page_no
            break
    if index_start is None:
        for page_no, text in texts.items():
            if index_entry_line_count(text) >= 20:
                index_start = page_no
                break
    if index_start is None:
        raise RuntimeError(f"Could not find index page in first {max_scan_pages} pages")

    index_end = index_start
    index_texts = []
    for page_no in range(index_start, max_scan_pages + 1):
        text = texts[page_no]
        normalized = strip_accents(text.upper())
        if page_no > index_start and contains_municipality_body_start(text):
            numbered_entries = index_entry_line_count(text)
            has_index_title = (
                ("INDICE" in normalized and "MUNICIP" in normalized)
                or "PAGS" in normalized
            )
            if has_index_title or numbered_entries >= 8:
                index_end = page_no
                index_texts.append(text)
            break
        if page_no == index_start or looks_like_index_page(text):
            index_end = page_no
            index_texts.append(text)
            continue
        # Some index continuation pages are noisy; keep a page with at least
        # one numbered line if it appears immediately after another index page.
        if index_entry_line_count(text) >= 1:
            index_end = page_no
            index_texts.append(text)
            continue
        break

    return index_start, index_end, "\n".join(index_texts)


def is_noise_line(line: str) -> bool:
    line = line.strip()
    if not line:
        return True
    if re.fullmatch(r"[-–—=\s\d\|]+", line):
        return True
    if "CONDIÇÕES DA AGRICULTURA" in line.upper() or "CONDICOES DA AGRICULTURA" in strip_accents(line.upper()):
        return True
    if re.fullmatch(r"[A-ZÁÉÍÓÚÀÂÊÔÃÕÜÇ\s]+", line) and len(line) > 28:
        return True
    return False


def extract_municipality_header(block: str, fallback: str) -> str:
    match = _AGRIC_RE.search(block)
    if match:
        line_start = block.rfind("\n", 0, match.start()) + 1
        same_line_prefix = clean_body_header_name(block[line_start : match.start()])
        if plausible_header_name(same_line_prefix) and not is_noise_line(same_line_prefix):
            return same_line_prefix
    preceding = block[: match.start()] if match else block[:500]
    for raw_line in reversed(preceding.splitlines()):
        candidate = raw_line.strip()
        if is_noise_line(candidate):
            continue
        candidate = clean_body_header_name(candidate)
        if plausible_header_name(candidate):
            return candidate
    return fallback


def extract_anchor_name(text: str, match: re.Match, fallback: str = "") -> str:
    line_start = text.rfind("\n", 0, match.start()) + 1
    same_line_prefix = clean_body_header_name(text[line_start : match.start()])
    if plausible_header_name(same_line_prefix) and not is_noise_line(same_line_prefix):
        return same_line_prefix

    preceding = text[max(0, match.start() - 500) : match.start()]
    lines = preceding.splitlines()
    for raw_line in reversed(lines):
        if not re.match(r"\s*[\"'“”‘’«»*]?(?:Munic[ií]pio|W?i?unic)", raw_line, flags=re.I):
            continue
        candidate = clean_body_header_name(raw_line.strip())
        if plausible_header_name(candidate) and not is_noise_line(candidate) and not candidate.startswith("====="):
            return candidate
    for raw_line in reversed(lines):
        candidate = clean_body_header_name(raw_line.strip())
        if plausible_header_name(candidate) and not is_noise_line(candidate) and not candidate.startswith("====="):
            return candidate
    return fallback


def build_blocks_from_anchor_pages(page_texts: dict[int, str]) -> list[tuple[str, str]]:
    pieces = []
    for page_no in sorted(page_texts):
        pieces.append(f"\n\n===== PAGE {page_no} =====\n\n{page_texts[page_no]}")
    full_text = "\n".join(pieces)
    matches = list(_AGRIC_RE.finditer(full_text))
    blocks: list[tuple[str, str]] = []
    for idx, match in enumerate(matches):
        line_start = full_text.rfind("\n", 0, match.start()) + 1
        next_start = (
            full_text.rfind("\n", 0, matches[idx + 1].start()) + 1
            if idx + 1 < len(matches)
            else len(full_text)
        )
        block = full_text[line_start:next_start]
        name = extract_anchor_name(full_text, match, f"municipio_{idx + 1:03d}")
        if name and not name.startswith("Quadro do tempo"):
            blocks.append((name, block))
    return blocks


def build_blocks(page_texts: dict[int, str], entries: list[IndexEntry]) -> list[tuple[IndexEntry, str]]:
    blocks = []
    for entry in entries:
        parts = [page_texts[p] for p in range(entry.pdf_start, entry.pdf_end + 1) if p in page_texts]
        blocks.append((entry, "\n".join(parts)))
    return blocks


def build_blocks_from_printed_pages(
    logical_texts: dict[int, str],
    entries: list[IndexEntry],
    after_muni_printed: int | None,
) -> list[tuple[IndexEntry, str]]:
    blocks = []
    for idx, entry in enumerate(entries):
        if idx + 1 < len(entries):
            printed_end = entries[idx + 1].printed_start - 1
        elif after_muni_printed:
            printed_end = after_muni_printed - 1
        else:
            printed_end = max(logical_texts)
        parts = [logical_texts[p] for p in range(entry.printed_start, printed_end + 1) if p in logical_texts]
        blocks.append((entry, "\n".join(parts)))
    return blocks


def index_parse_is_usable(entries: list[IndexEntry], after_muni_printed: int | None) -> bool:
    if not entries:
        return False
    starts = [entry.printed_start for entry in entries]
    if any(curr <= prev for prev, curr in zip(starts, starts[1:])):
        return False
    if after_muni_printed is not None and after_muni_printed <= starts[-1]:
        return False
    return True


def parse_best_index(
    pdf_path: str,
    cache_path: str,
    index_start: int,
    index_end: int,
    total_pages: int,
    repairs: dict[int, int] | None,
) -> tuple[list[IndexEntry], int | None, bool]:
    cache = load_cache(cache_path)
    full_text = "\n".join(cache["pages"].get(str(page), "") for page in range(index_start, index_end + 1))
    try:
        entries, after = parse_index_entries(full_text, index_end, total_pages, repairs)
        if index_parse_is_usable(entries, after):
            return entries, after, False
    except Exception:
        pass

    augmented = ocr_index_pages_for_parsing(pdf_path, cache_path, list(range(index_start, index_end + 1)))
    entries, after = parse_index_entries(augmented, index_end, total_pages, repairs)
    return entries, after, True


def write_csv(path: str, rows: list[dict[str, str]]) -> None:
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["municipio", *TOPICS])
        writer.writeheader()
        writer.writerows(rows)


def validate_rows(rows: list[dict[str, str]], expected_count: int) -> dict:
    missing = {topic: [row["municipio"] for row in rows if not row[topic].strip()] for topic in TOPICS}
    heading_issues = []

    bleed_patterns = [
        rf"\bAGRICULTORES\s*{_DASHES}",
        rf"\bINDICE\s*{_DASHES}",
        rf"\bMADEIRAS\s+DE\s+L\w{{0,3}}:?(?:\s*{_DASHES})?",
        rf"\bMINAS\s*{_DASHES}",
        rf"\bMOLESTIAS(?:\s+DA\s+POPULACAO)?\s*{_DASHES}",
        rf"\bNUCLEOS(?:\s+COLONIAES)?\s*{_DASHES}",
        rf"\bOPEROSIDADE(?:\s+DA\s+POPULACAO)?\s*{_DASHES}",
        rf"\bPADROES(?:\s+DE\s+TERRAS?)?\s*{_DASHES}",
        rf"\bSEMENTES\s*{_DASHES}",
        rf"\bSEMEADURAS?\s*{_DASHES}",
        rf"\bSYSTEMA(?:\s+DE\s+TRABALHO)?[A-Z\s]*\s*{_DASHES}",
        rf"\bJUROS\s*{_DASHES}",
        rf"\bSALARIOS\s*{_DASHES}",
        rf"\bPORTOS\s*{_DASHES}",
        rf"\bTRANSPORTES\s*{_DASHES}",
        rf"\bTERRAS\s*{_DASHES}",
    ]
    heading_pattern = re.compile("|".join(f"(?:{pattern})" for pattern in bleed_patterns))
    for row in rows:
        for topic in TOPICS:
            normalized = strip_accents(row[topic].upper())
            checks = [match.group(0) for match in heading_pattern.finditer(normalized)]
            if topic == "terras":
                checks = [hit for hit in checks if not hit.startswith("PRECOS")]
            if checks:
                heading_issues.append({"municipio": row["municipio"], "field": topic, "matches": checks[:3]})

    return {
        "expected_rows": expected_count,
        "actual_rows": len(rows),
        "row_count_ok": len(rows) == expected_count,
        "missing": missing,
        "heading_bleed": heading_issues,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", default=DEFAULT_PDF)
    parser.add_argument("--out-csv", default=DEFAULT_OUT_CSV)
    parser.add_argument("--ocr-json", default=DEFAULT_OCR_JSON)
    parser.add_argument("--max-index-scan-pages", type=int, default=40)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    total_pages = page_count(args.pdf)
    print(f"PDF pages: {total_pages}", flush=True)

    index_start, index_end, _index_text = find_index_pages(
        args.pdf, args.ocr_json, min(args.max_index_scan_pages, total_pages)
    )
    stem = Path(args.pdf).stem
    entries, after_muni_printed, used_augmented_index = parse_best_index(
        args.pdf,
        args.ocr_json,
        index_start,
        index_end,
        total_pages,
        INDEX_PAGE_REPAIRS_BY_STEM.get(stem),
    )
    if index_start == index_end:
        print(f"Index page: PDF page {index_start}", flush=True)
    else:
        print(f"Index pages: PDF pages {index_start}-{index_end}", flush=True)
    print(f"Municipality entries from index: {len(entries)}", flush=True)
    if after_muni_printed:
        print(f"First post-municipality printed page: {after_muni_printed}", flush=True)
    if used_augmented_index:
        print("Used half-page OCR repairs for index parsing", flush=True)

    index_end_text = load_cache(args.ocr_json).get("pages", {}).get(str(index_end), "")
    body_starts_on_index_end = contains_municipality_body_start(index_end_text)
    max_printed_start = max(entry.printed_start for entry in entries)
    physical_body_capacity = total_pages - index_end + 10
    two_up = bool(
        (after_muni_printed and after_muni_printed > physical_body_capacity)
        or (body_starts_on_index_end and max_printed_start > physical_body_capacity)
    )
    if two_up:
        print("Detected two-up scan layout; OCRing left/right halves as logical printed pages", flush=True)
        first_side = "right"
        logical_capacity = 1 + 2 * (total_pages - index_end)
        logical_limit = after_muni_printed - 1 if after_muni_printed else logical_capacity
        logical_limit = max(max_printed_start, min(logical_limit, logical_capacity))
        logical_limit = min(logical_limit, logical_capacity)
        needed_printed_pages = list(range(1, logical_limit + 1))
        page_texts = ocr_two_up_printed_pages(
            args.pdf,
            args.ocr_json,
            index_end,
            needed_printed_pages,
            first_side,
        )
        anchor_blocks = build_blocks_from_anchor_pages(page_texts)
        if len(anchor_blocks) >= max(1, int(len(entries) * 0.65)):
            print(f"Using body-anchor segmentation: {len(anchor_blocks)} municipality blocks", flush=True)
            rows = []
            for municipality, block in anchor_blocks:
                row = {"municipio": municipality}
                row.update(extract_topics(block))
                rows.append(row)
            expected_count = len(anchor_blocks)
            write_csv(args.out_csv, rows)
            validation = validate_rows(rows, expected_count)
            print(f"Wrote {len(rows)} rows to {args.out_csv}", flush=True)
            print("Validation:", json.dumps(validation, ensure_ascii=False, indent=2), flush=True)
            if not validation["row_count_ok"] or validation["heading_bleed"]:
                raise SystemExit(1)
            return
        block_pairs = build_blocks_from_printed_pages(page_texts, entries, after_muni_printed)
    else:
        needed_pages = sorted({p for entry in entries for p in range(entry.pdf_start, entry.pdf_end + 1)})
        page_texts = ocr_pages(args.pdf, args.ocr_json, needed_pages)
        anchor_blocks = build_blocks_from_anchor_pages(page_texts)
        if len(anchor_blocks) > len(entries) + 5:
            print(f"Using body-anchor segmentation: {len(anchor_blocks)} municipality blocks", flush=True)
            rows = []
            for municipality, block in anchor_blocks:
                row = {"municipio": municipality}
                row.update(extract_topics(block))
                rows.append(row)
            expected_count = len(anchor_blocks)
            write_csv(args.out_csv, rows)
            validation = validate_rows(rows, expected_count)
            print(f"Wrote {len(rows)} rows to {args.out_csv}", flush=True)
            print("Validation:", json.dumps(validation, ensure_ascii=False, indent=2), flush=True)
            if not validation["row_count_ok"] or validation["heading_bleed"]:
                raise SystemExit(1)
            return
        block_pairs = build_blocks(page_texts, entries)

    rows = []
    for entry, block in block_pairs:
        row = {"municipio": extract_municipality_header(block, entry.index_name)}
        row.update(extract_topics(block))
        rows.append(row)

    write_csv(args.out_csv, rows)
    validation = validate_rows(rows, len(entries))

    print(f"Wrote {len(rows)} rows to {args.out_csv}", flush=True)
    print("Validation:", json.dumps(validation, ensure_ascii=False, indent=2), flush=True)

    if not validation["row_count_ok"] or validation["heading_bleed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
