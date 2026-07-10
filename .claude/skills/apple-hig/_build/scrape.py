#!/usr/bin/env python3
"""Scrape Apple HIG DocC JSON for every non-excluded page.

Reads /tmp/hig/_crawl_index.json (built by an earlier recon crawl), filters out
visionOS/watchOS/tvOS/CarPlay pages, and downloads the DocC JSON backing each
surviving page into _build/json/<slug>.json. Idempotent — pages already on disk
are skipped on re-run.

Usage:
    python3 scrape.py
"""
from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

EXCLUDED = ("visionos", "watchos", "tvos", "carplay")
CRAWL_INDEX = Path("/tmp/hig/_crawl_index.json")
SKILL_ROOT = Path(__file__).resolve().parent.parent
JSON_DIR = SKILL_ROOT / "_build" / "json"
UA = "Mozilla/5.0"
TIMEOUT = 20
WORKERS = 8


def page_paths() -> list[str]:
    data = json.loads(CRAWL_INDEX.read_text())
    paths = []
    for p in data["pages"].keys():
        low = p.lower()
        if any(k in low for k in EXCLUDED):
            continue
        paths.append(p)
    return sorted(paths)


def slug_for(path: str) -> str:
    # /design/human-interface-guidelines/<slug>  or  /design/human-interface-guidelines (root)
    tail = path.rstrip("/").split("/")[-1]
    if tail == "human-interface-guidelines":
        return "_root"
    return tail


def json_url(path: str) -> str:
    # /design/human-interface-guidelines/foo -> tutorials/data/design/human-interface-guidelines/foo.json
    # /design/human-interface-guidelines     -> tutorials/data/design/human-interface-guidelines.json
    rel = path[len("/design/human-interface-guidelines"):]
    base = "https://developer.apple.com/tutorials/data/design/human-interface-guidelines"
    if not rel:
        return base + ".json"
    return base + rel + ".json"


def fetch(path: str) -> tuple[str, bool, str | None]:
    slug = slug_for(path)
    out = JSON_DIR / f"{slug}.json"
    if out.exists() and out.stat().st_size > 0:
        return slug, True, None

    url = json_url(path)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in (1, 2):
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
                body = resp.read()
            # validate JSON
            json.loads(body)
            out.write_bytes(body)
            return slug, True, None
        except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError, TimeoutError) as e:
            if attempt == 2:
                return slug, False, f"{type(e).__name__}: {e}"
            time.sleep(0.5)
    return slug, False, "unreachable"


def main() -> int:
    JSON_DIR.mkdir(parents=True, exist_ok=True)
    paths = page_paths()
    print(f"[scrape] {len(paths)} pages to fetch (after exclusions)")

    ok = 0
    fail: list[tuple[str, str]] = []
    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futures = {pool.submit(fetch, p): p for p in paths}
        for i, fut in enumerate(as_completed(futures), 1):
            slug, success, err = fut.result()
            if success:
                ok += 1
            else:
                fail.append((slug, err or "?"))
            if i % 20 == 0 or i == len(paths):
                print(f"[scrape] {i}/{len(paths)} done (ok={ok}, fail={len(fail)})")

    print(f"[scrape] complete: {ok} ok, {len(fail)} failed")
    for slug, err in fail:
        print(f"  FAIL {slug}: {err}")
    return 0 if not fail else 1


if __name__ == "__main__":
    sys.exit(main())
