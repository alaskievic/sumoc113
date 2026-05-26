#!/usr/bin/env python3
"""Fresh OCR pipeline for quest_agri_al.pdf with currency-aware post-processing.

Improvements vs. the original 300 DPI / PSM 4 pipeline:
  - 500 DPI grayscale rendering (preserves the thin '$' stroke in mil-reis amounts)
  - Tesseract por+eng PSM 4, --oem 1 (LSTM only)
  - Currency-aware post-processing: recovers '$' from common OCR misreads
    ('8', 'f', 'S', 's', etc.) inside money contexts, plus token-level
    repairs (Goo->600, Soo->500, tooo->1$000, 4co$000->400$000, ...)

Writes a cache JSON compatible with codex_skills/scripts/extract_municipality_topics.py,
so the existing parser can produce the structured CSV from this fresher OCR.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import tempfile
from pathlib import Path

import pdfplumber


DEFAULT_PDF = (
    "/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/"
    "Andrei Arminio Laskievic/sumoc_shared/questionario_agri/quest_agri_al.pdf"
)
DEFAULT_CACHE = "output_ocr/questionario_agri/cache/quest_agri_al_my_ocr.json"
DPI = 500
LANG = "por+eng"
PSM = "4"
OEM = "1"


def render_page(pdf: str, page_no: int, out_png: str, dpi: int = DPI) -> None:
    subprocess.run(
        [
            "gs",
            "-q",
            "-dSAFER",
            "-dBATCH",
            "-dNOPAUSE",
            "-sDEVICE=pnggray",
            f"-r{dpi}",
            f"-dFirstPage={page_no}",
            f"-dLastPage={page_no}",
            f"-sOutputFile={out_png}",
            pdf,
        ],
        check=True,
    )


def ocr_image(png_path: str, psm: str = PSM, lang: str = LANG, oem: str = OEM) -> str:
    result = subprocess.run(
        [
            "tesseract",
            png_path,
            "stdout",
            "-l",
            lang,
            "--psm",
            psm,
            "--oem",
            oem,
            "-c",
            "preserve_interword_spaces=1",
        ],
        check=True,
        capture_output=True,
        text=True,
        errors="replace",
    )
    return result.stdout


MONEY_HINT_RE = re.compile(
    r"r[eé]is|diari|mensa|annua|anno|kilo|saca|sacca|sacco|carga|"
    r"hectar|pre[çc]o|custa|vale|paga(?!men)|ganha|tarefa|alqueire|"
    r"conto|valor|cargueiro|emprest|deposit|juro|sal[aá]rio|salari|"
    r"divida|capital|arroba|cabe[çc]a|d[uú]zia|tropa|porto|venal|"
    r"impost|propried|aluguel|loca[çc][aã]o|venda|compra|frete|"
    r"a (?:semana|hora|mez|m[eê]s|tarefa|arroba|saca|cabe[çc]a|"
    r"duzia|d[uú]zia)|por (?:dia|mez|m[eê]s|anno|kilo|saca|"
    r"sacco|carga|cabe[çc]a|duzia|d[uú]zia|hectare|tarefa)",
    re.I,
)

SPECIFIC_TOKEN_REPAIRS = [
    (re.compile(r"\bGoo\b"), "600"),
    (re.compile(r"\bG00\b"), "600"),
    (re.compile(r"\bSoo\b"), "500"),
    (re.compile(r"\bSO0\b"), "500"),
    (re.compile(r"\btooo\b"), "1$000"),
    (re.compile(r"\bIooo\b"), "1$000"),
    (re.compile(r"\$eco\b"), "$000"),
    (re.compile(r"\$ec0\b"), "$000"),
    (re.compile(r"\$ooo\b"), "$000"),
    (re.compile(r"\$0oo\b"), "$000"),
    (re.compile(r"\$o0o\b"), "$000"),
]

CO_AS_ZEROS_RE = re.compile(r"(\d)[Cc]o(\$\d{3})")
# "$" most commonly misread as 8 or f; less often as F, s, S, B, b, &, |
SIGN_MISREAD_DIGIT_RE = re.compile(r"(?<!\d)(\d{1,3})([8fFsSBb&|])(\d{3})(?!\d)")
S_DOLLAR_RE = re.compile(r"(?<![A-Za-z\d])S(\$\d{3})")
# Leading-digit misreads when followed directly by "$NNN"
G_DOLLAR_RE = re.compile(r"(?<![A-Za-z\d])G(\$\d{3})")
# "B/b" between a digit (or "Co"-style zeros stand-in) and a run of "o"s reads as
# misread "$" followed by misread "000", e.g. "4coBooo" -> "4co$000".  The
# CO_AS_ZEROS_RE pass that runs later then collapses "Co"/"co" to "00".
DIGIT_B_OOO_RE = re.compile(r"(\b\d{1,3}(?:[Cc]o)?)[Bb]o{2,4}\b")


def is_money_context(window_text: str) -> bool:
    return bool(MONEY_HINT_RE.search(window_text))


def repair_specific_tokens(text: str) -> str:
    for pat, repl in SPECIFIC_TOKEN_REPAIRS:
        text = pat.sub(repl, text)
    return text


def repair_money_line(line: str) -> str:
    # Order matters: collapse "B-misread + ooo" first so it can flow through
    # CO_AS_ZEROS_RE on the same pass.
    line = DIGIT_B_OOO_RE.sub(lambda m: m.group(1) + "$000", line)
    line = CO_AS_ZEROS_RE.sub(lambda m: m.group(1) + "00" + m.group(2), line)
    line = SIGN_MISREAD_DIGIT_RE.sub(r"\1$\3", line)
    line = S_DOLLAR_RE.sub(r"5\1", line)
    line = G_DOLLAR_RE.sub(r"6\1", line)
    return line


def strip_column_gutter_noise(line: str) -> str:
    # Tesseract picks up vertical column rules and page-edge borders as "|".
    # When they land at the start of a line they break the parser's heading
    # regex (e.g. "|      TERRAS — ...").  Strip leading-pipe gunk.
    return re.sub(r"^\s*\|+\s*", "", line)


def post_process(text: str) -> str:
    text = repair_specific_tokens(text)
    lines = [strip_column_gutter_noise(l) for l in text.split("\n")]
    out: list[str] = []
    for i, line in enumerate(lines):
        # Wider sliding window so mid-paragraph numeric lines still see the
        # money-context keywords introduced at the paragraph's start.
        window = " ".join(lines[max(0, i - 3) : min(len(lines), i + 4)])
        # A line that already contains a "$NNN" amount is itself a strong
        # money-context signal even if neighbours don't mention currency words.
        if is_money_context(window) or re.search(r"\$\d{3}", line):
            line = repair_money_line(line)
        out.append(line)
    return "\n".join(out)


def load_cache(path: str) -> dict:
    if not Path(path).exists():
        return {
            "renderer": f"ghostscript_{DPI}dpi",
            "ocr": f"tesseract_{LANG}_psm{PSM}_oem{OEM}",
            "post_processing": "currency_repair_v1",
            "pages": {},
            "raw_pages": {},
        }
    with open(path, encoding="utf-8") as f:
        cache = json.load(f)
    cache.setdefault("pages", {})
    cache.setdefault("raw_pages", {})
    return cache


def save_cache(path: str, cache: dict) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)
    os.replace(tmp, path)


def parse_pages_arg(spec: str | None, total: int) -> list[int]:
    if not spec:
        return list(range(1, total + 1))
    pages: set[int] = set()
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            pages.update(range(int(a), int(b) + 1))
        else:
            pages.add(int(part))
    invalid = [p for p in pages if p < 1 or p > total]
    if invalid:
        raise ValueError(f"Pages outside 1-{total}: {invalid}")
    return sorted(pages)


def ocr_pdf(
    pdf: str, cache_path: str, pages: list[int], dpi: int, psm: str, oem: str
) -> None:
    cache = load_cache(cache_path)
    missing = [p for p in pages if str(p) not in cache["pages"]]
    if missing:
        print(
            f"OCR {len(missing)} page(s): Ghostscript {dpi} DPI + Tesseract "
            f"{LANG} PSM {psm} OEM {oem}",
            flush=True,
        )
    with tempfile.TemporaryDirectory(prefix="my_ocr_al_") as tmp:
        for i, page_no in enumerate(missing, start=1):
            png = os.path.join(tmp, f"page_{page_no:04d}.png")
            print(f"  OCR page {page_no} ({i}/{len(missing)})", flush=True)
            render_page(pdf, page_no, png, dpi)
            raw = ocr_image(png, psm, LANG, oem)
            cache["raw_pages"][str(page_no)] = raw
            cache["pages"][str(page_no)] = post_process(raw)
            save_cache(cache_path, cache)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", default=DEFAULT_PDF)
    ap.add_argument("--cache", default=DEFAULT_CACHE)
    ap.add_argument("--pages", help="Comma-separated pages / ranges, e.g. 7-9,12")
    ap.add_argument("--dpi", type=int, default=DPI)
    ap.add_argument("--psm", default=PSM)
    ap.add_argument("--oem", default=OEM)
    args = ap.parse_args()

    with pdfplumber.open(args.pdf) as p:
        total = len(p.pages)
    pages = parse_pages_arg(args.pages, total)
    ocr_pdf(args.pdf, args.cache, pages, args.dpi, args.psm, args.oem)


if __name__ == "__main__":
    main()
