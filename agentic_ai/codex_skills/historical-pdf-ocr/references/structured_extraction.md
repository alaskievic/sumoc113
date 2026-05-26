# Structured Extraction From OCR

Use this guide when the user wants CSV, JSON, or tabular data from historical OCR text.

## Extraction Pattern

1. Define the output schema before parsing, including source PDF, page, raw text span, cleaned value, and confidence/audit fields.
2. Parse from `_pages.jsonl` for page-aware blocks or `_lines.csv` for line-level matching.
3. Normalize matching keys without discarding raw text:

```python
import re
import unicodedata

def key(text: str) -> str:
    text = unicodedata.normalize("NFD", text.upper())
    text = "".join(ch for ch in text if unicodedata.category(ch) != "Mn")
    return re.sub(r"[^A-Z0-9]+", "", text)
```

4. Build tolerant heading patterns for OCR variants. Example: match `SALARIOS`, `SALARIO`, `SALARI0S`, or split labels such as `TRANS SPORTES`.
5. Segment the document with stable anchors first, such as municipality names, repeated headings, page headers, or index entries.
6. Extract target fields from each segment and preserve the raw segment for review.
7. Validate against expected counts, known entity lists, and manual page spot checks.

## Practical Heuristics

- Use known lists of municipalities, offices, people, or headings when available.
- Treat all-caps historical headings as anchors, but filter page headers and decorative title lines.
- Join broken words with `(\w)-\s+(\w)` only after verifying that hyphenation is not semantic.
- Keep one row per logical entity, not one row per OCR page, when building datasets.
- Add columns such as `source_pdf`, `source_page_start`, `source_page_end`, `raw_ocr`, `parser_notes`, and `needs_review`.

## Validation Checklist

- Row count matches the expected number of entities or missing entities are listed.
- Every extracted value can be traced to `raw_ocr` and page metadata.
- Empty values are distinguishable from "not mentioned" and "OCR failed".
- Parser warnings are summarized before delivering the dataset.
