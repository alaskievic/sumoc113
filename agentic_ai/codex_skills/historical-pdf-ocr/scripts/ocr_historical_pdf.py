#!/usr/bin/env python3
"""OCR scanned historical PDFs into text, JSONL, CSV, and a manifest."""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib
import json
import re
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable


@dataclass
class PageResult:
    page: int
    text: str
    char_count: int
    line_count: int
    cached: bool


def import_or_exit(module_name: str, package_hint: str):
    try:
        return importlib.import_module(module_name)
    except ImportError:
        print(
            f"Missing Python dependency: {module_name}. Install it with: "
            f"python3 -m pip install {package_hint}",
            file=sys.stderr,
        )
        sys.exit(2)


def parse_page_spec(spec: str | None, total_pages: int) -> list[int]:
    if not spec:
        return list(range(total_pages))

    pages: set[int] = set()
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            start_s, end_s = part.split("-", 1)
            start, end = int(start_s), int(end_s)
            if start > end:
                raise ValueError(f"Invalid page range: {part}")
            pages.update(range(start, end + 1))
        else:
            pages.add(int(part))

    invalid = [p for p in pages if p < 1 or p > total_pages]
    if invalid:
        raise ValueError(f"Page(s) outside 1-{total_pages}: {invalid}")
    return [p - 1 for p in sorted(pages)]


def pdf_cache_key(pdf_path: Path, args: argparse.Namespace) -> str:
    stat = pdf_path.stat()
    data = {
        "path": str(pdf_path.resolve()),
        "size": stat.st_size,
        "mtime_ns": stat.st_mtime_ns,
        "dpi": args.dpi,
        "lang": args.lang,
        "psm": args.psm,
        "threshold": args.threshold,
        "median_filter": args.median_filter,
        "tesseract_config": args.tesseract_config,
    }
    return hashlib.sha256(json.dumps(data, sort_keys=True).encode("utf-8")).hexdigest()[:20]


def check_tesseract() -> dict[str, str | bool]:
    try:
        result = subprocess.run(
            ["tesseract", "--version"],
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return {"available": False, "version": "not found"}

    first_line = result.stdout.splitlines()[0] if result.stdout else "unknown"
    return {"available": result.returncode == 0, "version": first_line}


def render_page(pdf_document, page_index: int, dpi: int):
    fitz = import_or_exit("fitz", "pymupdf")
    Image = import_or_exit("PIL.Image", "pillow")

    page = pdf_document.load_page(page_index)
    scale = dpi / 72
    pix = page.get_pixmap(matrix=fitz.Matrix(scale, scale), alpha=False)
    return Image.frombytes("RGB", (pix.width, pix.height), pix.samples)


def preprocess_image(image, threshold: int | None, median_filter: bool):
    ImageOps = import_or_exit("PIL.ImageOps", "pillow")
    ImageFilter = import_or_exit("PIL.ImageFilter", "pillow")

    processed = ImageOps.grayscale(image)
    processed = ImageOps.autocontrast(processed)
    if median_filter:
        processed = processed.filter(ImageFilter.MedianFilter(size=3))
    if threshold is not None:
        processed = processed.point(lambda value: 255 if value > threshold else 0, mode="1")
    return processed


def clean_text(text: str, dehyphenate: bool) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n").replace("\f", "")
    text = re.sub(r"[ \t]+\n", "\n", text)
    text = re.sub(r"\n{4,}", "\n\n\n", text)
    if dehyphenate:
        text = re.sub(r"(\w)-\n(\w)", r"\1\2", text)
    return text.strip()


def iter_csv_lines(result: PageResult, source_pdf: Path) -> Iterable[dict[str, str | int]]:
    for line_number, line in enumerate(result.text.splitlines(), start=1):
        cleaned = re.sub(r"\s+", " ", line).strip()
        if not cleaned:
            continue
        yield {
            "source_pdf": str(source_pdf),
            "page": result.page,
            "line_number": line_number,
            "text": cleaned,
        }


def ocr_page(image, lang: str, psm: int, extra_config: str) -> str:
    pytesseract = import_or_exit("pytesseract", "pytesseract")
    config = f"--psm {psm} preserve_interword_spaces=1 {extra_config}".strip()
    try:
        return pytesseract.image_to_string(image, lang=lang, config=config)
    except pytesseract.TesseractError as exc:
        print(f"Tesseract failed: {exc}", file=sys.stderr)
        sys.exit(3)


def process_pdf(args: argparse.Namespace) -> dict[str, Path]:
    pdf_path = args.input_pdf.expanduser().resolve()
    if not pdf_path.exists():
        raise FileNotFoundError(pdf_path)

    fitz = import_or_exit("fitz", "pymupdf")

    output_dir = args.output_dir.expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    stem = args.output_stem or pdf_path.stem
    txt_path = output_dir / f"{stem}.txt"
    jsonl_path = output_dir / f"{stem}_pages.jsonl"
    csv_path = output_dir / f"{stem}_lines.csv"
    manifest_path = output_dir / f"{stem}_manifest.json"

    cache_root = args.cache_dir.expanduser().resolve() if args.cache_dir else output_dir / ".ocr_cache"
    cache_dir = cache_root / pdf_cache_key(pdf_path, args)
    if not args.no_cache:
        cache_dir.mkdir(parents=True, exist_ok=True)

    image_dir = output_dir / f"{stem}_page_images"
    if args.save_page_images:
        image_dir.mkdir(parents=True, exist_ok=True)

    tesseract = check_tesseract()
    if not tesseract["available"]:
        print("Tesseract is not available on PATH. Install it before running OCR.", file=sys.stderr)
        sys.exit(2)

    doc = fitz.open(pdf_path)
    page_indexes = parse_page_spec(args.pages, len(doc))
    results: list[PageResult] = []

    for position, page_index in enumerate(page_indexes, start=1):
        page_number = page_index + 1
        cache_file = cache_dir / f"page_{page_number:05d}.txt"
        print(f"OCR page {page_number}/{len(doc)} ({position}/{len(page_indexes)})", flush=True)

        if cache_file.exists() and not args.no_cache:
            text = cache_file.read_text(encoding="utf-8")
            cached = True
        else:
            image = render_page(doc, page_index, args.dpi)
            image = preprocess_image(image, args.threshold, args.median_filter)
            if args.save_page_images:
                image.save(image_dir / f"page_{page_number:05d}.png")
            text = ocr_page(image, args.lang, args.psm, args.tesseract_config)
            text = clean_text(text, args.dehyphenate)
            if not args.no_cache:
                cache_file.write_text(text, encoding="utf-8")
            cached = False

        results.append(
            PageResult(
                page=page_number,
                text=text,
                char_count=len(text),
                line_count=len([line for line in text.splitlines() if line.strip()]),
                cached=cached,
            )
        )

    with txt_path.open("w", encoding="utf-8") as handle:
        for result in results:
            handle.write(f"\n\n===== Page {result.page} =====\n\n")
            handle.write(result.text)
            handle.write("\n")

    with jsonl_path.open("w", encoding="utf-8") as handle:
        for result in results:
            handle.write(json.dumps(asdict(result), ensure_ascii=False) + "\n")

    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        fieldnames = ["source_pdf", "page", "line_number", "text"]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for result in results:
            writer.writerows(iter_csv_lines(result, pdf_path))

    manifest = {
        "source_pdf": str(pdf_path),
        "total_pdf_pages": len(doc),
        "processed_pages": [result.page for result in results],
        "settings": {
            "dpi": args.dpi,
            "lang": args.lang,
            "psm": args.psm,
            "threshold": args.threshold,
            "median_filter": args.median_filter,
            "dehyphenate": args.dehyphenate,
            "tesseract_config": args.tesseract_config,
        },
        "tesseract": tesseract,
        "outputs": {
            "txt": str(txt_path),
            "pages_jsonl": str(jsonl_path),
            "lines_csv": str(csv_path),
            "manifest": str(manifest_path),
            "cache_dir": str(cache_dir) if not args.no_cache else None,
            "page_images": str(image_dir) if args.save_page_images else None,
        },
    }
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    return {
        "txt": txt_path,
        "pages_jsonl": jsonl_path,
        "lines_csv": csv_path,
        "manifest": manifest_path,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="OCR scanned historical PDFs into text, JSONL, CSV, and a manifest."
    )
    parser.add_argument("input_pdf", type=Path, help="PDF to OCR")
    parser.add_argument("--output-dir", type=Path, default=Path("output_ocr"), help="Output directory")
    parser.add_argument("--output-stem", help="Base filename for output artifacts")
    parser.add_argument("--pages", help="1-indexed pages or ranges, e.g. 1,3-5,10")
    parser.add_argument("--lang", default="por+eng", help="Tesseract language code(s)")
    parser.add_argument("--dpi", type=int, default=300, help="Render DPI")
    parser.add_argument("--psm", type=int, default=6, help="Tesseract page segmentation mode")
    parser.add_argument("--threshold", type=int, default=185, help="Binarization threshold 0-255")
    parser.add_argument("--no-threshold", action="store_const", const=None, dest="threshold")
    parser.add_argument("--median-filter", action="store_true", help="Apply a 3x3 median filter")
    parser.add_argument("--dehyphenate", action="store_true", help="Join words split by hyphen-newline")
    parser.add_argument("--tesseract-config", default="", help="Extra Tesseract config string")
    parser.add_argument("--cache-dir", type=Path, help="Cache directory for per-page OCR text")
    parser.add_argument("--no-cache", action="store_true", help="Disable cache reads and writes")
    parser.add_argument("--save-page-images", action="store_true", help="Save preprocessed page PNGs")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    try:
        outputs = process_pdf(args)
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    print("Wrote OCR artifacts:")
    for label, path in outputs.items():
        print(f"  {label}: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
