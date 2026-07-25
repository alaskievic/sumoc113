#!/usr/bin/env python3
"""OCR any PDF with Mistral Document AI OCR."""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import sys
import time
import uuid
from pathlib import Path
from typing import Any
from urllib import error, request


API_BASE = "https://api.mistral.ai/v1"


class MistralAPIError(RuntimeError):
    """Raised when the Mistral API returns an unsuccessful response."""


def load_env() -> None:
    """Load KEY=VALUE pairs from .env.local or .env in cwd/parents."""

    candidates: list[Path] = []
    for base in [Path.cwd(), *Path.cwd().parents]:
        candidates.extend([base / ".env.local", base / ".env"])
    for env_path in candidates:
        if not env_path.exists():
            continue
        for line in env_path.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("#") or "=" not in stripped:
                continue
            key, value = stripped.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value


def parse_page_list(page_list: str | None) -> list[int] | None:
    """Parse one-based page specs like '1,4-6' and return zero-based indexes."""

    if not page_list:
        return None
    pages: set[int] = set()
    for chunk in page_list.split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        if "-" in chunk:
            start_s, end_s = chunk.split("-", 1)
            start = int(start_s)
            end = int(end_s)
            if start < 1 or end < start:
                raise ValueError(f"Invalid page range: {chunk}")
            pages.update(range(start - 1, end))
        else:
            page = int(chunk)
            if page < 1:
                raise ValueError(f"Invalid page number: {chunk}")
            pages.add(page - 1)
    return sorted(pages)


def api_request(
    method: str,
    path: str,
    api_key: str,
    *,
    body: bytes | None = None,
    headers: dict[str, str] | None = None,
) -> Any:
    req = request.Request(
        f"{API_BASE}{path}",
        data=body,
        method=method,
        headers={"Authorization": f"Bearer {api_key}", **(headers or {})},
    )
    try:
        with request.urlopen(req, timeout=600) as response:
            payload = response.read()
    except error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise MistralAPIError(f"{method} {path} failed with HTTP {exc.code}: {detail}") from exc
    except error.URLError as exc:
        raise MistralAPIError(f"{method} {path} failed: {exc}") from exc
    return json.loads(payload.decode("utf-8")) if payload else None


def multipart_body(fields: dict[str, str], file_field: str, file_path: Path) -> tuple[bytes, str]:
    boundary = f"----mistral-pdf-ocr-{uuid.uuid4().hex}"
    content_type = mimetypes.guess_type(file_path.name)[0] or "application/pdf"
    body = bytearray()

    for name, value in fields.items():
        body.extend(f"--{boundary}\r\n".encode("utf-8"))
        body.extend(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode("utf-8"))
        body.extend(value.encode("utf-8"))
        body.extend(b"\r\n")

    body.extend(f"--{boundary}\r\n".encode("utf-8"))
    body.extend(
        (
            f'Content-Disposition: form-data; name="{file_field}"; filename="{file_path.name}"\r\n'
            f"Content-Type: {content_type}\r\n\r\n"
        ).encode("utf-8")
    )
    body.extend(file_path.read_bytes())
    body.extend(b"\r\n")
    body.extend(f"--{boundary}--\r\n".encode("utf-8"))
    return bytes(body), f"multipart/form-data; boundary={boundary}"


def upload_file(pdf_path: Path, api_key: str) -> str:
    body, content_type = multipart_body({"purpose": "ocr"}, "file", pdf_path)
    response = api_request(
        "POST",
        "/files",
        api_key,
        body=body,
        headers={"Content-Type": content_type},
    )
    file_id = response.get("id") if isinstance(response, dict) else None
    if not file_id:
        raise MistralAPIError(f"File upload response did not include an id: {response!r}")
    return file_id


def delete_file(file_id: str, api_key: str) -> None:
    api_request("DELETE", f"/files/{file_id}", api_key, headers={"Content-Type": "application/json"})


def run_ocr(
    api_key: str,
    file_id: str,
    model: str,
    page_indexes: list[int] | None,
    table_format: str | None,
    confidence_scores: str | None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "model": model,
        "document": {"type": "file", "file_id": file_id},
        "include_image_base64": False,
    }
    if page_indexes is not None:
        payload["pages"] = page_indexes
    if table_format:
        payload["table_format"] = table_format
    if confidence_scores:
        payload["confidence_scores_granularity"] = confidence_scores

    body = json.dumps(payload).encode("utf-8")
    try:
        return api_request(
            "POST",
            "/ocr",
            api_key,
            body=body,
            headers={"Content-Type": "application/json"},
        )
    except MistralAPIError as exc:
        fallback = dict(payload)
        fallback["document"] = {"file_id": file_id}
        try:
            return api_request(
                "POST",
                "/ocr",
                api_key,
                body=json.dumps(fallback).encode("utf-8"),
                headers={"Content-Type": "application/json"},
            )
        except MistralAPIError:
            raise exc


def normalize_result(pdf_path: Path, model: str, response: dict[str, Any]) -> dict[str, Any]:
    pages = []
    for page in response.get("pages", []):
        index = page.get("index", 0)
        markdown = page.get("markdown") or ""
        try:
            page_num = int(index) + 1
        except (TypeError, ValueError):
            page_num = index
        pages.append(
            {
                "page": page_num,
                "markdown": markdown,
                "lines": [line for line in markdown.splitlines() if line.strip()],
                "dimensions": page.get("dimensions"),
                "confidence_scores": page.get("confidence_scores"),
                "tables": page.get("tables", []),
                "images": page.get("images", []),
            }
        )
    return {
        "source": str(pdf_path),
        "engine": "mistral",
        "model": response.get("model", model),
        "usage_info": response.get("usage_info"),
        "document_annotation": response.get("document_annotation"),
        "raw_response": response,
        "pages": pages,
    }


def write_text(result: dict[str, Any], text_out: Path) -> None:
    chunks: list[str] = []
    for page in result["pages"]:
        chunks.append(f"=== Page {page['page']} ===")
        chunks.extend(page["lines"])
        chunks.append("")
    text_out.write_text("\n".join(chunks), encoding="utf-8")


def main() -> None:
    load_env()
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdf", required=True, type=Path)
    parser.add_argument("--out-dir", type=Path, default=Path("."))
    parser.add_argument("--json-out", type=Path)
    parser.add_argument("--text-out", type=Path)
    parser.add_argument("--model", default="mistral-ocr-2512")
    parser.add_argument("--page-list", help="One-based pages/ranges, e.g. '1,4-6'.")
    parser.add_argument("--table-format", choices=["markdown", "html"])
    parser.add_argument("--confidence-scores", choices=["page", "word"])
    parser.add_argument("--keep-remote-file", action="store_true")
    args = parser.parse_args()

    api_key = os.environ.get("MISTRAL_API_KEY")
    if not api_key:
        print("MISTRAL_API_KEY is required.", file=sys.stderr)
        raise SystemExit(2)
    if not args.pdf.exists():
        print(f"PDF not found: {args.pdf}", file=sys.stderr)
        raise SystemExit(2)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    json_out = args.json_out or args.out_dir / f"{args.pdf.stem}_mistral_raw.json"
    text_out = args.text_out or args.out_dir / f"{args.pdf.stem}_mistral_raw.txt"

    started = time.time()
    print(f"Uploading {args.pdf} to Mistral OCR...", flush=True)
    file_id = upload_file(args.pdf, api_key)
    try:
        print(f"Running {args.model} OCR on file_id={file_id}...", flush=True)
        response = run_ocr(
            api_key,
            file_id,
            args.model,
            parse_page_list(args.page_list),
            args.table_format,
            args.confidence_scores,
        )
    finally:
        if args.keep_remote_file:
            print(f"Keeping remote file_id={file_id}", flush=True)
        else:
            try:
                delete_file(file_id, api_key)
                print(f"Deleted remote file_id={file_id}", flush=True)
            except MistralAPIError as exc:
                print(f"Warning: could not delete remote file_id={file_id}: {exc}", file=sys.stderr)

    result = normalize_result(args.pdf, args.model, response)
    result["elapsed_seconds"] = round(time.time() - started, 3)
    result["remote_file_id"] = file_id if args.keep_remote_file else None

    json_out.parent.mkdir(parents=True, exist_ok=True)
    text_out.parent.mkdir(parents=True, exist_ok=True)
    json_out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    write_text(result, text_out)
    print(f"Wrote {len(result['pages'])} pages to {json_out} and {text_out}", flush=True)


if __name__ == "__main__":
    main()
