# Historical OCR Guidance

Use a sample-tune-full-run workflow for historical PDFs. Old typefaces, skewed scans, stained paper, and multi-column layouts can make one-pass OCR unreliable.

## Dependency Checklist

- System OCR engine: Tesseract must be installed and visible on `PATH`.
- Python packages: `pymupdf`, `pillow`, and `pytesseract`.
- Language data: ensure the requested Tesseract languages are installed, such as `por` for Portuguese and `eng` for English.

If dependencies are missing, report the exact missing dependency and the command that failed. Do not overwrite source PDFs.

## Tuning Defaults

Start with:

```bash
python scripts/ocr_historical_pdf.py input.pdf --output-dir output_ocr --lang por+eng --dpi 300 --psm 6 --pages 1-3
```

Adjust in this order:

1. `--pages`: sample title pages, dense tables, typical body pages, and damaged pages.
2. `--dpi`: use 300 by default; try 400 for small type or poor scans.
3. `--psm`: use `6` for a single block of text, `4` for column-like text, `11` for sparse text.
4. `--threshold`: try values between 150 and 210 for faded or yellowed pages.
5. `--no-threshold`: use when binarization removes faint letters.

## Quality Checks

- Confirm page count and selected page ranges in the manifest.
- Check whether headers, municipality names, section labels, and numbers survive OCR.
- Look for recurring OCR variants and encode them in downstream parsing instead of manually editing raw OCR.
- Keep raw text, page JSONL, line CSV, and any cleaned extraction output together.
- Save page images only when needed for visual debugging; they can be large.

## Historical Text Cleanup

Prefer reversible cleanup:

- Normalize line endings and whitespace.
- Preserve page numbers and page IDs in intermediate files.
- Dehyphenate words only after checking that line breaks are not meaningful.
- Use accent-insensitive matching for headings, but keep original text in output columns when possible.
- Record uncertain matches in an audit column rather than silently dropping them.
