---
name: questionario-agri-ocr
description: Use this skill when the user asks Codex to OCR Brazilian agricultural questionnaire PDFs named quest_agri_*.pdf and extract the sections JUROS, SALARIOS, TERRAS, and TRANSPORTE/TRANSPORTES into CSV. This skill is for the SUMOC questionario_agri workflow using the local PaddleOCR environment or the Mistral OCR API, preserving mil-reis $ currency markers, checking missing % signs in JUROS, comparing old CSV outputs when useful, and saving final CSVs to sumoc_shared/output_ocr/questionario_agri/csv.
---

# Questionario Agri OCR

Use this skill for the SUMOC `quest_agri_*.pdf` extraction workflow.

## Quick Command

When the user says something like:

```text
Use $questionario-agri-ocr for quest_agri_sc.pdf
```

process that PDF from the shared `questionario_agri` folder and save:

```text
sumoc_shared/output_ocr/questionario_agri/csv/quest_agri_<state>_paddle.csv
```

## Workflow

1. Read `references/workflow.md` for project paths, commands, and validation details.
2. Confirm the target PDF exists in the shared input folder.
3. Use `pdfinfo` to get page count.
4. Run OCR. Default to local PaddleOCR when no API key is available. Use Mistral OCR (`ocr_work/ocr_quest_agri_mistral.py`) when the user asks for it or when PaddleOCR misses page structure.
5. Parse sections into CSV. If a state parser already exists, use it. For a new state, copy the closest existing parser and update:
   `MUNICIPIOS`, heading variants, label matching, `%` fixes for `JUROS`, and targeted overrides.
6. Validate with `scripts/validate_questionario_agri_csv.py`.
7. For missing sections caused by page breaks or OCR misses, run targeted OCR with `ocr_work/ocr_selected_pages.py` or rerun `ocr_work/ocr_quest_agri_mistral.py --page-list '<pages>'`; inspect rendered pages if needed.
8. Use old CSVs in the output folder only as reference or fallback after checking the new OCR.
9. Copy the final CSV to the shared output folder. This may require sandbox escalation.

## Extraction Rules

- CSV schema: `municipio,juros,salarios,terras,transporte`.
- Preserve `$` because it marks mil-reis currency values.
- Normalize common `JUROS` percent OCR errors: `°`, `º`, `]`, `"`, missing signs, and strings like `12ao anno`.
- `JUROS` entries with no interest rate are valid when the text says `Nao ha taxa fixa`, `Nao ha taxas fixas`, `Nao ha emprestimos`, or similar.
- Do not invent missing cells. If the source lacks a section, leave it blank and mention it in the final response.

## Final Response

Report:

- final CSV path,
- row count,
- empty cells by field,
- total `$` count,
- any manual fallbacks or targeted OCR pages used.
