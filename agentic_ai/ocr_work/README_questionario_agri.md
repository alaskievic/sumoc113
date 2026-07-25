# Questionario Agricola OCR Runbook

This directory contains the reusable PaddleOCR workflow used for the agricultural questionnaire PDFs.

## Goal

For each `quest_agri_*.pdf`, OCR the PDF and extract the text following these section headers into CSV:

- `JUROS`
- `SALARIOS`
- `TERRAS`
- `TRANSPORTE` / `TRANSPORTES`

The CSV schema is:

```csv
municipio,juros,salarios,terras,transporte
```

Pay special attention to:

- `$` as mil-reis currency markers.
- `%` in `JUROS`, because Paddle often reads percent signs as `°`, `º`, `]`, quotes, or drops them entirely.

## Important Paths

Repository/workspace:

```text
/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai
```

Dropbox-backed shared folder:

```text
/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared
```

Input PDFs:

```text
/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared/questionario_agri
```

Final CSV output:

```text
/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared/output_ocr/questionario_agri/csv
```

## Local OCR Environment

Use the local Python 3.12 virtualenv:

```bash
.venv-paddle-ocr312/bin/python
```

Set these environment variables when running OCR:

```bash
PADDLE_PDX_CACHE_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.paddlex-cache
MODELSCOPE_CACHE=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.modelscope-cache
HF_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.hf-cache
PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True
```

The Paddle models are cached locally under `.paddlex-cache`.

## OCR Command

Use `ocr_work/ocr_quest_agri_al.py` as the generic full-PDF OCR runner despite the `al` name.

Example for Sergipe:

```bash
PADDLE_PDX_CACHE_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.paddlex-cache \
MODELSCOPE_CACHE=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.modelscope-cache \
HF_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.hf-cache \
PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True \
.venv-paddle-ocr312/bin/python ocr_work/ocr_quest_agri_al.py \
  --pdf '/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared/questionario_agri/quest_agri_se.pdf' \
  --pages 117 \
  --dpi 120 \
  --det-limit 960 \
  --json-out ocr_work/quest_agri_se_paddle_raw.json \
  --text-out ocr_work/quest_agri_se_paddle_raw.txt
```

Use `pdfinfo <pdf>` to get page count before running.

## Parsing

Existing parsers:

- `ocr_work/parse_quest_agri_al_sections.py`
- `ocr_work/parse_quest_agri_se_sections.py`

For a new state, copy one of these and update:

- `MUNICIPIOS` list and OCR headings.
- any OCR label variants in `LABEL_PATTERNS` and `line_kind`.
- `apply_targeted_overrides()` for page-boundary misses.
- `fix_percent_tokens()` if `JUROS` has new percent-sign OCR patterns.

Run parser example:

```bash
.venv-paddle-ocr312/bin/python ocr_work/parse_quest_agri_se_sections.py \
  --raw-text ocr_work/quest_agri_se_paddle_raw.txt \
  --csv-out ocr_work/quest_agri_se_paddle_sections.csv
```

## Targeted Page OCR

If a section label is missing at a page break, use targeted OCR and/or render the page for visual verification.

Targeted OCR:

```bash
PADDLE_PDX_CACHE_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.paddlex-cache \
MODELSCOPE_CACHE=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.modelscope-cache \
HF_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.hf-cache \
PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True \
.venv-paddle-ocr312/bin/python ocr_work/ocr_selected_pages.py \
  --pdf '<pdf>' \
  --page-list 21-22,30-31 \
  --dpi 180 \
  --det-limit 1400 \
  --json-out ocr_work/<state>_targeted.json \
  --text-out ocr_work/<state>_targeted.txt
```

Render pages for visual QA:

```bash
mkdir -p ocr_work/rendered_pages
pdftoppm -f <page> -l <page> -r 220 -png '<pdf>' ocr_work/rendered_pages/<state>_page
```

Then inspect with the image viewer if needed.

## Validation Checklist

After generating a CSV:

```bash
python3 - <<'PY'
import csv
from pathlib import Path
p = Path('ocr_work/<state>_paddle_sections.csv')
rows = list(csv.DictReader(p.open(encoding='utf-8', newline='')))
print('rows', len(rows))
print('fields', rows[0].keys())
print('empty', {k:[r['municipio'] for r in rows if not r[k]] for k in rows[0] if k != 'municipio'})
print('total_dollar_signs', sum(sum(r[k].count('$') for k in ['juros','salarios','terras','transporte']) for r in rows))
print('juros_without_percent_or_por_cento', [
    r['municipio'] for r in rows
    if '%' not in r['juros']
    and 'por cento' not in r['juros'].lower()
    and 'prestamistas' not in r['juros'].lower()
])
PY
```

Expected:

- correct row count for the municipality index.
- no empty `juros`, `salarios`, `terras`, or `transporte` cells.
- `JUROS` entries should include `%`, `por cento`, or `Nao ha prestamistas`.
- review suspicious `$` OCR substitutions manually.

## Save Final CSV

Copy final CSV to the shared output folder:

```bash
cp ocr_work/<state>_paddle_sections.csv \
  '/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared/output_ocr/questionario_agri/csv/quest_agri_<state>_paddle.csv'
```

This path may require sandbox escalation in Codex because it is outside the repository writable root.

## Completed So Far

- `quest_agri_al.pdf` -> `quest_agri_al_paddle.csv`
- `quest_agri_se.pdf` -> `quest_agri_se_paddle.csv`

