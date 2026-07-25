#!/usr/bin/env python3
"""OCR the Alagoas agricultural questionnaire with the local paddle-ocr skill."""

from __future__ import annotations

import argparse
import json
import os
import tempfile
import time
from pathlib import Path

from pdf2image import convert_from_path
from paddleocr import PaddleOCR


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


def ocr_pdf(pdf_path: Path, pages: int, dpi: int, det_limit: int) -> dict:
    ocr = PaddleOCR(
        lang="pt",
        ocr_version="PP-OCRv3",
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
        use_textline_orientation=False,
        text_recognition_batch_size=48,
    )

    result = {
        "source": str(pdf_path),
        "engine": "paddleocr",
        "lang": "pt",
        "ocr_version": "PP-OCRv3",
        "dpi": dpi,
        "text_det_limit_side_len": det_limit,
        "pages": [],
    }

    with tempfile.TemporaryDirectory(prefix="quest_agri_al_pages_") as tmp:
        tmp_dir = Path(tmp)
        for page_num in range(1, pages + 1):
            started = time.time()
            image_path = render_page(pdf_path, page_num, dpi, tmp_dir)
            page_results = ocr.predict(
                str(image_path),
                text_det_limit_side_len=det_limit,
                use_doc_orientation_classify=False,
                use_doc_unwarping=False,
                use_textline_orientation=False,
            )
            if not page_results:
                rec_texts = []
                rec_scores = []
                rec_boxes = []
            else:
                page = page_results[0]
                rec_texts = page.get("rec_texts", [])
                rec_scores = page.get("rec_scores", [])
                rec_boxes = page.get("rec_boxes", [])
            elapsed = time.time() - started
            print(
                f"OCR page {page_num:03d}/{pages}: {len(rec_texts)} lines in {elapsed:.1f}s",
                flush=True,
            )
            result["pages"].append(
                {
                    "page": page_num,
                    "elapsed_seconds": round(elapsed, 3),
                    "lines": rec_texts,
                    "scores": [float(s) for s in rec_scores],
                    "boxes": rec_boxes.tolist() if hasattr(rec_boxes, "tolist") else rec_boxes,
                }
            )
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", required=True, type=Path)
    parser.add_argument("--pages", required=True, type=int)
    parser.add_argument("--dpi", type=int, default=120)
    parser.add_argument("--det-limit", type=int, default=960)
    parser.add_argument("--json-out", required=True, type=Path)
    parser.add_argument("--text-out", required=True, type=Path)
    args = parser.parse_args()

    os.environ.setdefault("PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK", "True")
    result = ocr_pdf(args.pdf, args.pages, args.dpi, args.det_limit)

    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")

    chunks = []
    for page in result["pages"]:
        chunks.append(f"=== Page {page['page']} ===")
        chunks.extend(page["lines"])
        chunks.append("")
    args.text_out.write_text("\n".join(chunks), encoding="utf-8")


if __name__ == "__main__":
    main()
