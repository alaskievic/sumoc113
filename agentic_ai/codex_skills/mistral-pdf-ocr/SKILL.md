---
name: mistral-pdf-ocr
description: Use this skill when the user asks Codex to OCR any PDF file with the Mistral OCR API and output Mistral text files, raw OCR JSON, or page-delimited markdown/text. The skill handles local PDF paths, MISTRAL_API_KEY from environment or local .env files, optional page ranges, and writes OCR artifacts without hard-coding project-specific parsing.
---

# Mistral PDF OCR

Use this skill to OCR any PDF with Mistral Document AI OCR and save text artifacts.

## Workflow

1. Confirm the input PDF exists.
2. Use `scripts/mistral_pdf_ocr.py`.
3. Keep secrets out of tracked files. The script reads `MISTRAL_API_KEY` from the environment, `.env.local`, or `.env` in the current workspace or parent directories.
4. Save outputs as:
   - `<stem>_mistral_raw.json`
   - `<stem>_mistral_raw.txt`
5. Report the output paths, page count processed, and whether the remote file was deleted.

## Quick Command

```bash
python3 codex_skills/mistral-pdf-ocr/scripts/mistral_pdf_ocr.py \
  --pdf '<pdf>' \
  --out-dir '<output_dir>'
```

## Options

- `--model mistral-ocr-2512` is the default.
- `--page-list '1,4-6'` accepts one-based page numbers/ranges and converts them for the API.
- `--json-out` and `--text-out` override default output paths.
- `--confidence-scores page` or `--confidence-scores word` requests confidence scores when supported.
- `--table-format markdown` or `--table-format html` requests a table format when supported.
- `--keep-remote-file` leaves the uploaded file in Mistral; otherwise the script deletes it after OCR.

## Output Text Format

The `.txt` file is page-delimited:

```text
=== Page 1 ===
<Mistral page markdown/text>

=== Page 2 ===
...
```

Use the raw JSON when layout metadata, dimensions, confidence scores, tables, or usage info are needed.
