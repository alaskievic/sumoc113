# SUMOC Questionario Agri Workflow

## Paths

Workspace:

```text
/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai
```

Shared folder:

```text
/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared
```

Input PDFs:

```text
/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared/questionario_agri
```

Output CSVs:

```text
/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared/output_ocr/questionario_agri/csv
```

## Local Environment

Run from the workspace. Use:

```bash
.venv-paddle-ocr312/bin/python
```

Set these variables for OCR commands:

```bash
PADDLE_PDX_CACHE_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.paddlex-cache
MODELSCOPE_CACHE=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.modelscope-cache
HF_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.hf-cache
PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True
```

## Full OCR

Get page count:

```bash
pdfinfo '<pdf>'
```

Run OCR:

```bash
PADDLE_PDX_CACHE_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.paddlex-cache \
MODELSCOPE_CACHE=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.modelscope-cache \
HF_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.hf-cache \
PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True \
.venv-paddle-ocr312/bin/python ocr_work/ocr_quest_agri_al.py \
  --pdf '<pdf>' \
  --pages <page_count> \
  --dpi 120 \
  --det-limit 960 \
  --json-out ocr_work/quest_agri_<state>_paddle_raw.json \
  --text-out ocr_work/quest_agri_<state>_paddle_raw.txt
```

## Mistral OCR

Use this path when the user asks for Mistral OCR, when PaddleOCR loses page
structure, or when comparing engines to improve parser coverage.

Requirements:

```bash
export MISTRAL_API_KEY='<key>'
```

Run full-document OCR:

```bash
python3 ocr_work/ocr_quest_agri_mistral.py \
  --pdf '<pdf>' \
  --model mistral-ocr-2512 \
  --json-out ocr_work/quest_agri_<state>_mistral_raw.json \
  --text-out ocr_work/quest_agri_<state>_mistral_raw.txt \
  --confidence-scores page
```

Run targeted pages using the same one-based page notation as the Paddle helper:

```bash
python3 ocr_work/ocr_quest_agri_mistral.py \
  --pdf '<pdf>' \
  --model mistral-ocr-2512 \
  --page-list '<pages>' \
  --json-out ocr_work/quest_agri_<state>_mistral_targeted.json \
  --text-out ocr_work/quest_agri_<state>_mistral_targeted.txt \
  --confidence-scores page
```

Notes:

- `MISTRAL_API_KEY` is read from the environment; do not hard-code it.
- The script uploads the PDF with `purpose=ocr`, calls `/v1/ocr`, and deletes
  the remote file unless `--keep-remote-file` is set.
- The Mistral API uses zero-based page indexes, but this wrapper accepts
  one-based page lists to match local workflow habits.
- The raw JSON preserves Mistral page markdown, confidence scores, tables, and
  usage info. The text output is page-delimited with `=== Page N ===` markers
  so existing parser scripts can be adapted incrementally.

## Parsers

Existing parser examples:

```text
ocr_work/parse_quest_agri_al_sections.py
ocr_work/parse_quest_agri_se_sections.py
ocr_work/parse_quest_agri_sc_sections.py
```

For a new state:

1. Build the municipality list from the index page.
2. Find municipality heading line numbers with `rg -n`.
3. Copy the closest parser and update headings and OCR variants.
4. Ensure labels include variants for `JUROS`, `SALARIOS`, `TERRAS`, and `TRANSPORTE(S)`.
5. Add targeted overrides only for verified OCR issues.

Run parser:

```bash
.venv-paddle-ocr312/bin/python ocr_work/parse_quest_agri_<state>_sections.py \
  --raw-text ocr_work/quest_agri_<state>_paddle_raw.txt \
  --csv-out ocr_work/quest_agri_<state>_paddle_sections.csv
```

## Targeted OCR

Use when page tops/tails drop labels or a section is missing:

```bash
PADDLE_PDX_CACHE_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.paddlex-cache \
MODELSCOPE_CACHE=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.modelscope-cache \
HF_HOME=/Users/alaskievic/Desktop/master_work/sumoc113/agentic_ai/.hf-cache \
PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK=True \
.venv-paddle-ocr312/bin/python ocr_work/ocr_selected_pages.py \
  --pdf '<pdf>' \
  --page-list '<pages>' \
  --dpi 180 \
  --det-limit 1400 \
  --json-out ocr_work/quest_agri_<state>_targeted.json \
  --text-out ocr_work/quest_agri_<state>_targeted.txt
```

Render pages for manual visual checks:

```bash
mkdir -p ocr_work/rendered_pages
pdftoppm -f <page> -l <page> -r 220 -png '<pdf>' ocr_work/rendered_pages/<state>_page
```

## Validation

Use the validator bundled with this skill:

```bash
python3 codex_skills/questionario-agri-ocr/scripts/validate_questionario_agri_csv.py \
  ocr_work/quest_agri_<state>_paddle_sections.csv
```

Review:

- row count against the municipality index,
- blanks in `juros`, `salarios`, `terras`, `transporte`,
- `JUROS` rows without `%`, `por cento`, or accepted no-rate wording,
- suspicious currency OCR patterns around `$`.

## Save Final CSV

```bash
cp ocr_work/quest_agri_<state>_paddle_sections.csv \
  '/Users/alaskievic/Library/CloudStorage/Dropbox-UniversityofMichigan/Andrei Arminio Laskievic/sumoc_shared/output_ocr/questionario_agri/csv/quest_agri_<state>_paddle.csv'
```

The final copy may require sandbox escalation.
