#!/usr/bin/env python3
"""Audit HIG validation screenshot evidence.

The validation loop is only trustworthy when a report evaluates the exact PNGs
currently linked from it. This script checks that relationship and can also
sync the machine-readable backlog in ``worklist.json`` so stale evidence stops
masquerading as current validation.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


VALIDATION_ROOT = Path(__file__).resolve().parent
REPORTS_DIR = VALIDATION_ROOT / "reports"
SCREENSHOTS_DIR = VALIDATION_ROOT / "screenshots"
EVIDENCE_DIR = VALIDATION_ROOT / "evidence"
WORKLIST_PATH = VALIDATION_ROOT / "worklist.json"
REQUIRED_PLATFORMS = ("macos", "ios")
REQUIRED_APPEARANCES = ("light", "dark")
MIN_SCREENSHOT_BYTES = 10 * 1024
MTIME_TOLERANCE_SECONDS = 1.0
DEFAULT_REMEDIATION_HINT = (
    "Evidence audit failed; regenerate all four screenshots, report, and "
    "evidence manifest before design-critic review."
)
LEGACY_SKIP_REASON_KEYS = ("skipped_reason",)
SKIP_REASON_FALLBACKS = {
    "windows": "window-chrome-not-view",
}
VALIDATION_STATES = ("pass", "pass_with_notes", "pending", "needs_work", "fail", "skipped")
EVIDENCE_STATES = ("valid", "invalid", "not_applicable", "unknown")


def iso_from_mtime(path: Path) -> str:
    return datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def png_dimensions(path: Path) -> tuple[int, int] | None:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", header[16:24])


def screenshot_name(slug: str, platform: str, appearance: str) -> str:
    return f"{slug}-{platform}-{appearance}.png"


def load_worklist() -> dict[str, Any]:
    with WORKLIST_PATH.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def auditable_rows(worklist: dict[str, Any], slug: str | None = None) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in worklist.get("pages", []):
        is_component = row.get("role") == "component"
        is_implemented_study = row.get("status") == "implemented" and bool(row.get("ui_view"))
        if not (is_component or is_implemented_study):
            continue
        if slug and row.get("slug") != slug:
            continue
        rows.append(row)
    return rows


def iter_rows(worklist: dict[str, Any], slug: str | None, include_pending: bool) -> list[dict[str, Any]]:
    rows = []
    for row in auditable_rows(worklist, slug):
        state = row.get("validation_state")
        if state in ("pass", "pass_with_notes"):
            rows.append(row)
            continue
        if include_pending and state in ("pending", "needs_work", "fail"):
            rows.append(row)
    return rows


def report_frontmatter(slug: str) -> dict[str, str]:
    path = REPORTS_DIR / f"{slug}.md"
    if not path.exists():
        return {}

    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return {}

    frontmatter: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line or line.startswith(" "):
            continue
        key, value = line.split(":", 1)
        frontmatter[key.strip()] = value.strip()
    return frontmatter


def normalize_validation_state(value: str | None) -> str | None:
    if not value:
        return None
    state = value.strip().lower()
    return state if state in VALIDATION_STATES else None


def audit_row(row: dict[str, Any]) -> dict[str, Any]:
    slug = row["slug"]
    errors: list[str] = []
    warnings: list[str] = []
    report_path = REPORTS_DIR / f"{slug}.md"

    report: dict[str, Any] = {
        "path": str(report_path.relative_to(VALIDATION_ROOT)),
        "exists": report_path.exists(),
    }
    report_text = ""
    report_mtime = None
    if report_path.exists():
        report_mtime = report_path.stat().st_mtime
        report.update(
            {
                "size_bytes": report_path.stat().st_size,
                "mtime": iso_from_mtime(report_path),
                "sha256": sha256(report_path),
            }
        )
        report_text = report_path.read_text(encoding="utf-8")
    else:
        errors.append(f"missing report: {report_path}")

    screenshots: dict[str, Any] = {}
    for platform in REQUIRED_PLATFORMS:
        for appearance in REQUIRED_APPEARANCES:
            name = screenshot_name(slug, platform, appearance)
            key = f"{platform}_{appearance}"
            path = SCREENSHOTS_DIR / name
            item: dict[str, Any] = {
                "path": str(path.relative_to(VALIDATION_ROOT)),
                "exists": path.exists(),
            }
            if not path.exists():
                errors.append(f"missing screenshot: {name}")
                screenshots[key] = item
                continue

            size = path.stat().st_size
            item["size_bytes"] = size
            item["mtime"] = iso_from_mtime(path)
            item["sha256"] = sha256(path)
            dims = png_dimensions(path)
            if dims:
                item["pixel_width"], item["pixel_height"] = dims
            else:
                errors.append(f"not a readable PNG: {name}")

            if size < MIN_SCREENSHOT_BYTES:
                errors.append(f"screenshot under {MIN_SCREENSHOT_BYTES} bytes: {name} ({size})")

            if report_mtime is not None and path.stat().st_mtime > report_mtime + MTIME_TOLERANCE_SECONDS:
                errors.append(f"screenshot newer than report: {name}")

            if report_text and name not in report_text:
                errors.append(f"report does not link required screenshot: {name}")

            screenshots[key] = item

    if report_text:
        for legacy_name in (f"{slug}-macos.png", f"{slug}-ios.png"):
            if legacy_name in report_text:
                errors.append(f"report still links legacy two-capture screenshot: {legacy_name}")
        if "../screenshots/" not in report_text:
            warnings.append("report contains no screenshot links")

    return {
        "slug": slug,
        "validation_state": row.get("validation_state"),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "valid": not errors,
        "errors": errors,
        "warnings": warnings,
        "report": report,
        "screenshots": screenshots,
    }


def write_manifest(result: dict[str, Any]) -> None:
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    path = EVIDENCE_DIR / f"{result['slug']}.json"
    path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def normalize_skip_reason(row: dict[str, Any]) -> None:
    for legacy_key in LEGACY_SKIP_REASON_KEYS:
        legacy_value = row.pop(legacy_key, None)
        if legacy_value and not row.get("skip_reason"):
            row["skip_reason"] = legacy_value

    if row.get("validation_state") != "skipped":
        row.pop("skip_reason", None)
        return

    if row.get("skip_reason"):
        return

    skip_reason = report_frontmatter(row["slug"]).get("skip_reason")
    if skip_reason:
        row["skip_reason"] = skip_reason
        return

    fallback = SKIP_REASON_FALLBACKS.get(row["slug"])
    if fallback:
        row["skip_reason"] = fallback


def counts_from_worklist(worklist: dict[str, Any]) -> dict[str, int]:
    role_keys = {
        "component": "components",
        "foundation": "foundations",
        "pattern": "patterns",
        "platform-guide": "platform_guides",
        "collection": "collections",
    }
    counts = {
        "total_hig_pages": 0,
        "components": 0,
        "foundations": 0,
        "patterns": 0,
        "platform_guides": 0,
        "collections": 0,
        "implemented": 0,
        "stub": 0,
        "missing": 0,
    }

    pages = worklist.get("pages", [])
    counts["total_hig_pages"] = len(pages)
    for row in pages:
        role_key = role_keys.get(row.get("role"))
        if role_key:
            counts[role_key] += 1
        status = row.get("status")
        if status in ("implemented", "stub", "missing"):
            counts[status] += 1
    return counts


def validation_counts_from_worklist(worklist: dict[str, Any]) -> dict[str, int]:
    counter = Counter((row.get("validation_state") or "pending") for row in auditable_rows(worklist))
    return {state: counter.get(state, 0) for state in VALIDATION_STATES}


def evidence_counts_from_worklist(worklist: dict[str, Any]) -> dict[str, int]:
    counter = Counter((row.get("evidence_state") or "unknown") for row in auditable_rows(worklist))
    return {state: counter.get(state, 0) for state in EVIDENCE_STATES}


def sync_worklist(
    worklist: dict[str, Any],
    results: list[dict[str, Any]],
    *,
    requeue_invalid: bool,
) -> None:
    results_by_slug = {result["slug"]: result for result in results}

    for row in auditable_rows(worklist):
        normalize_skip_reason(row)

        if row.get("validation_state") == "skipped":
            row["evidence_state"] = "not_applicable"
            row["evidence_errors"] = []
            if row.get("remediation_hint") == DEFAULT_REMEDIATION_HINT:
                row.pop("remediation_hint", None)
            continue

        result = results_by_slug.get(row["slug"])
        if result is None:
            continue

        was_terminal = row.get("validation_state") in ("pass", "pass_with_notes")
        if result["valid"]:
            row["evidence_state"] = "valid"
            row["evidence_errors"] = []
            report_state = normalize_validation_state(report_frontmatter(row["slug"]).get("verdict"))
            if report_state and row.get("validation_state") != "skipped":
                row["validation_state"] = report_state
            if row.get("remediation_hint") == DEFAULT_REMEDIATION_HINT:
                row.pop("remediation_hint", None)
            continue

        row["evidence_state"] = "invalid"
        row["evidence_errors"] = result["errors"]
        if was_terminal:
            row["remediation_hint"] = DEFAULT_REMEDIATION_HINT
            if requeue_invalid:
                row["validation_state"] = "pending"

    worklist["generated_at"] = datetime.now(timezone.utc).isoformat()
    worklist["counts"] = counts_from_worklist(worklist)
    worklist["validation_counts"] = validation_counts_from_worklist(worklist)
    worklist["evidence_counts"] = evidence_counts_from_worklist(worklist)
    WORKLIST_PATH.write_text(json.dumps(worklist, indent=2) + "\n", encoding="utf-8")


def requeue_invalid_results(worklist: dict[str, Any], results: list[dict[str, Any]]) -> None:
    invalid_by_slug = {result["slug"]: result for result in results if not result["valid"]}
    if not invalid_by_slug:
        return

    for row in worklist.get("pages", []):
        result = invalid_by_slug.get(row.get("slug"))
        if not result:
            continue
        if row.get("validation_state") not in ("pass", "pass_with_notes"):
            continue
        row["validation_state"] = "pending"
        row["evidence_state"] = "invalid"
        row["evidence_errors"] = result["errors"]
        row["remediation_hint"] = DEFAULT_REMEDIATION_HINT

    WORKLIST_PATH.write_text(json.dumps(worklist, indent=2) + "\n", encoding="utf-8")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--slug", help="Audit a single slug")
    parser.add_argument("--include-pending", action="store_true", help="Also audit pending/needs_work auditable rows")
    parser.add_argument("--write-manifest", action="store_true", help="Write validation/evidence/<slug>.json")
    parser.add_argument("--json", action="store_true", help="Print JSON results")
    parser.add_argument("--requeue-invalid", action="store_true", help="Set invalid pass/pass_with_notes rows back to pending")
    parser.add_argument(
        "--sync-worklist",
        action="store_true",
        help="Normalize skip reasons, refresh counts, and write evidence_state/evidence_errors for all auditable rows",
    )
    args = parser.parse_args(argv)

    worklist = load_worklist()
    auditable_matches = auditable_rows(worklist, args.slug)
    if args.slug and not auditable_matches:
        print(f"No auditable row found for slug: {args.slug}", file=sys.stderr)
        return 2

    if args.sync_worklist:
        rows = [row for row in auditable_matches if row.get("validation_state") != "skipped"]
    else:
        rows = iter_rows(worklist, args.slug, args.include_pending)
        if args.slug and not rows and auditable_matches:
            print(f"No auditable row found for slug: {args.slug}", file=sys.stderr)
            return 2

    results = [audit_row(row) for row in rows]
    if args.write_manifest:
        for result in results:
            write_manifest(result)
    if args.sync_worklist:
        sync_worklist(worklist, results, requeue_invalid=args.requeue_invalid)
    elif args.requeue_invalid:
        requeue_invalid_results(worklist, results)

    invalid = [result for result in results if not result["valid"]]

    if args.json:
        print(json.dumps(results, indent=2, sort_keys=True))
    else:
        print(f"audited={len(results)} invalid={len(invalid)}")
        for result in invalid:
            print(f"INVALID {result['slug']}")
            for error in result["errors"][:8]:
                print(f"  - {error}")
            remaining = len(result["errors"]) - 8
            if remaining > 0:
                print(f"  - ... {remaining} more")

    return 1 if invalid else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
