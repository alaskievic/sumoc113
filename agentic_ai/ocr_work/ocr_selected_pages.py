#!/usr/bin/env python3
"""Run PaddleOCR on selected PDF pages and write text/JSON output."""

from __future__ import annotations

import argparse
import json
import os
import tempfile
import time
from pathlib import Path

from pdf2image import convert_from_path
from paddleocr import PaddleOCR


def parse_pages(value: str) -> list[int]:
    pages: list[int] = []
    for part in value.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            start, end = (int(x) for x in part.split("-", 1))
            pages.extend(range(start, end + 1))
        else:
            pages.append(int(part))
    return sorted(dict.fromkeys(pages))


def render_page(pdf_path: Path, page_num: int, dpi: int, out_dir: Path) -> Path:
    images = convert_from_path(
        str(pdf_path),
        dpi=dpi,
        first_page=page_num,
        last_page=page_num,
        fmt="png",
        thread_count=1,
    )
    out_path = out_dir / f"page_{page_num:03d}.png"
    images[0].save(out_path)
    return out_path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", required=True, type=Path)
    parser.add_argument("--page-list", required=True)
    parser.add_argument("--dpi", type=int, default=180)
    parser.add_argument("--det-limit", type=int, default=1400)
    parser.add_argument("--json-out", required=True, type=Path)
    parser.add_argument("--text-out", required=True, type=Path)
    args = parser.parse_args()

    os.environ.setdefault("PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK", "True")
    pages = parse_pages(args.page_list)
    ocr = PaddleOCR(
        lang="pt",
        ocr_version="PP-OCRv3",
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
        use_textline_orientation=False,
        text_recognition_batch_size=48,
    )

    result = {
        "source": str(args.pdf),
        "engine": "paddleocr",
        "lang": "pt",
        "ocr_version": "PP-OCRv3",
        "dpi": args.dpi,
        "text_det_limit_side_len": args.det_limit,
        "pages": [],
    }
    chunks: list[str] = []
    with tempfile.TemporaryDirectory(prefix="quest_agri_selected_pages_") as tmp:
        tmp_dir = Path(tmp)
        for page_num in pages:
            started = time.time()
            image_path = render_page(args.pdf, page_num, args.dpi, tmp_dir)
            page_results = ocr.predict(
                str(image_path),
                text_det_limit_side_len=args.det_limit,
                use_doc_orientation_classify=False,
                use_doc_unwarping=False,
                use_textline_orientation=False,
            )
            page = page_results[0] if page_results else {}
            rec_texts = page.get("rec_texts", [])
            rec_scores = page.get("rec_scores", [])
            rec_boxes = page.get("rec_boxes", [])
            elapsed = time.time() - started
            print(f"OCR page {page_num:03d}: {len(rec_texts)} lines in {elapsed:.1f}s", flush=True)
            result["pages"].append(
                {
                    "page": page_num,
                    "elapsed_seconds": round(elapsed, 3),
                    "lines": rec_texts,
                    "scores": [float(s) for s in rec_scores],
                    "boxes": rec_boxes.tolist() if hasattr(rec_boxes, "tolist") else rec_boxes,
                }
            )
            chunks.append(f"=== Page {page_num} ===")
            chunks.extend(rec_texts)
            chunks.append("")

    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    args.text_out.write_text("\n".join(chunks), encoding="utf-8")


if __name__ == "__main__":
    main()
