---
name: historical-pdf-ocr
description: Use this skill when Codex needs OCR-first extraction from scanned or low-quality historical PDFs, especially archival documents with old typography, Portuguese/English content, page images, noisy OCR, or requests to turn historical PDFs into text, CSV, JSONL, or structured datasets. Use for rendering pages, running Tesseract OCR, caching OCR output, cleaning historical text, and building structured extraction workflows from OCR results.
---

# Historical PDF OCR

## Overview

Use this skill to convert scanned historical PDFs into reproducible OCR artifacts and then extract structured text data from those artifacts. Prefer a sample-tune-full-run workflow rather than running full-document OCR blindly.

## Workflow

1. Locate the source PDFs and choose an output folder. In this project, prefer `agentic_ai/output_ocr/` unless the user specifies another destination.
2. Check whether the PDF already has embedded text. If embedded text is sparse or garbled, run OCR.
3. Run a small OCR sample first, usually 2-5 representative pages:

```bash
python scripts/ocr_historical_pdf.py path/to/input.pdf --output-dir ../../output_ocr --lang por+eng --dpi 300 --pages 1-3
```

4. Inspect the sample `.txt`, `_pages.jsonl`, and `_lines.csv` outputs. Adjust `--dpi`, `--lang`, `--psm`, `--threshold`, or `--no-threshold` if text is faint, columns merge, or headings fragment.
5. Run full OCR only after the sample is acceptable. Keep the manifest and cache so later extraction steps are auditable and repeatable.
6. For structured data, define the target schema first, then parse from `_pages.jsonl` or `_lines.csv`. Use accent-insensitive and OCR-tolerant matching for historical headings and place names.
7. Validate results by spot-checking rows against page images or PDF pages, counting missing fields, and preserving raw OCR text beside any cleaned fields.

## OCR Script

Use `scripts/ocr_historical_pdf.py` for repeatable OCR. It renders PDF pages with PyMuPDF, preprocesses images with Pillow, runs Tesseract through pytesseract, caches page text, and emits:

- `<stem>.txt`: full OCR text with page separators
- `<stem>_pages.jsonl`: one JSON object per page
- `<stem>_lines.csv`: one OCR line per row with source and page metadata
- `<stem>_manifest.json`: run settings, dependency hints, and output paths

Run commands from this skill directory or resolve `scripts/ocr_historical_pdf.py` to its absolute path.

Useful commands:

```bash
# Install Python OCR dependencies for this skill
python3 -m pip install -r scripts/requirements.txt

# Sample a few pages
python scripts/ocr_historical_pdf.py input.pdf --output-dir output_ocr --lang por+eng --pages 1-3

# Full run with historical-document defaults
python scripts/ocr_historical_pdf.py input.pdf --output-dir output_ocr --lang por+eng --dpi 300 --psm 6

# Try stronger binarization for faded scans
python scripts/ocr_historical_pdf.py input.pdf --output-dir output_ocr --threshold 175 --pages 10-12
```

## References

- Read `references/historical_ocr.md` when tuning OCR quality, choosing Tesseract settings, or diagnosing poor recognition.
- Read `references/structured_extraction.md` when converting OCR text into CSV/JSON datasets with project-specific fields.
