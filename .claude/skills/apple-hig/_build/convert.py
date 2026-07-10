#!/usr/bin/env python3
"""Convert scraped Apple HIG DocC JSON into markdown + images + search index.

Reads _build/json/*.json, emits:
  pages/<slug>.md        one markdown file per HIG page
  images/<identifier>    2x light images preferred, fallback any variant
  index.json             search index (title, role, abstract, tags, path)
  tags.json              tag -> [slugs] inverted index

Excludes visionOS/watchOS/tvOS/CarPlay pages entirely, and strips visionOS/
watchOS/tvOS platform-considerations subsections within otherwise-kept pages.

Usage:
    python3 convert.py
"""
from __future__ import annotations

import json
import re
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote

EXCLUDED_SLUG_KEYWORDS = ("visionos", "watchos", "tvos", "carplay")
EXCLUDED_PLATFORM_HEADINGS = {"visionos", "watchos", "tvos"}
KEPT_PLATFORMS = ("iOS", "iPadOS", "macOS")

SKILL_ROOT = Path(__file__).resolve().parent.parent
JSON_DIR = SKILL_ROOT / "_build" / "json"
PAGES_DIR = SKILL_ROOT / "pages"
IMAGES_DIR = SKILL_ROOT / "images"
INDEX_PATH = SKILL_ROOT / "index.json"
TAGS_PATH = SKILL_ROOT / "tags.json"

UA = "Mozilla/5.0"
TIMEOUT = 20

HIG_DOC_PREFIX = "doc://com.apple.HIG/design/Human-Interface-Guidelines/"
HIG_URL_PREFIX = "/design/human-interface-guidelines/"


# ---------------------------------------------------------------------------
# Utilities

def slug_from_doc_identifier(ident: str) -> str | None:
    """doc://com.apple.HIG/design/Human-Interface-Guidelines/buttons#anchor -> buttons (or None if not an article slug)."""
    if not ident.startswith(HIG_DOC_PREFIX):
        return None
    tail = ident[len(HIG_DOC_PREFIX):]
    slug = tail.split("#", 1)[0]
    slug = slug.strip("/")
    if not slug:
        return None
    return slug.lower() if slug.lower() == slug else slug


def slug_from_url(url: str) -> str | None:
    if url.startswith(HIG_URL_PREFIX):
        tail = url[len(HIG_URL_PREFIX):].split("#", 1)[0].strip("/")
        return tail or None
    return None


def is_excluded_slug(slug: str) -> bool:
    low = slug.lower()
    return any(k in low for k in EXCLUDED_SLUG_KEYWORDS)


# ---------------------------------------------------------------------------
# Inline content → markdown

def render_inline(nodes: list, refs: dict) -> str:
    if not nodes:
        return ""
    out: list[str] = []
    for n in nodes:
        if not isinstance(n, dict):
            continue
        t = n.get("type")
        if t == "text":
            out.append(n.get("text", ""))
        elif t == "strong":
            out.append(f"**{render_inline(n.get('inlineContent', []), refs)}**")
        elif t == "emphasis":
            out.append(f"*{render_inline(n.get('inlineContent', []), refs)}*")
        elif t == "codeVoice":
            code = "".join(n.get("code", [])) if "code" in n else render_inline(n.get("inlineContent", []), refs)
            out.append(f"`{code}`")
        elif t == "reference":
            out.append(render_reference(n.get("identifier", ""), refs))
        elif t == "image":
            ident = n.get("identifier", "")
            ref = refs.get(ident, {})
            alt = (ref.get("alt") or "").replace("\n", " ").strip()
            fname = image_filename(ident, ref)
            if fname:
                out.append(f"![{alt}](../images/{fname})")
        elif t == "link":
            title = n.get("title") or n.get("destination", "")
            dest = n.get("destination", "")
            out.append(f"[{title}]({dest})")
        elif t == "newTerm":
            out.append(f"**{render_inline(n.get('inlineContent', []), refs)}**")
        elif t == "definition":
            out.append(render_inline(n.get("inlineContent", []), refs))
        else:
            # fall back: try nested inlineContent
            if "inlineContent" in n:
                out.append(render_inline(n["inlineContent"], refs))
            elif "text" in n:
                out.append(n["text"])
    return "".join(out)


def render_reference(ident: str, refs: dict) -> str:
    ref = refs.get(ident)
    if not ref:
        # unresolved — emit the last path component as fallback
        tail = ident.rsplit("/", 1)[-1]
        return tail

    if ref.get("type") == "image":
        alt = (ref.get("alt") or "").replace("\n", " ").strip()
        fname = image_filename(ident, ref)
        if fname:
            return f"![{alt}](../images/{fname})"
        return alt or ""

    title = ref.get("title") or ident
    url = ref.get("url", "")
    # HIG-internal: rewrite to local md
    internal_slug = slug_from_url(url) if url else None
    if internal_slug:
        if is_excluded_slug(internal_slug):
            # Link to an excluded page — keep title as plain text (no link)
            return title
        return f"[{title}](./{internal_slug}.md)"
    # External
    if url.startswith("http"):
        return f"[{title}]({url})"
    if url.startswith("/"):
        return f"[{title}](https://developer.apple.com{url})"
    return title


# ---------------------------------------------------------------------------
# Image handling

IMAGE_EXTS = (".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp")


def image_filename(identifier: str, ref: dict) -> str | None:
    """Pick the filename to save an image under. Uses the identifier if it looks
    like a filename; otherwise derives from the variant URL."""
    variant_url = pick_variant_url(ref)
    if not variant_url:
        return None
    # Prefer identifier when it looks like an image filename
    if identifier and identifier.lower().endswith(IMAGE_EXTS):
        return identifier
    # else derive from URL tail
    tail = unquote(variant_url.rsplit("/", 1)[-1])
    return tail


def pick_variant_url(ref: dict) -> str | None:
    variants = ref.get("variants") or []
    if not variants:
        return None
    # prefer 2x + light
    for v in variants:
        traits = set(v.get("traits", []))
        if "2x" in traits and "light" in traits:
            return v.get("url")
    for v in variants:
        if "2x" in set(v.get("traits", [])):
            return v.get("url")
    return variants[0].get("url")


def collect_image_downloads(refs: dict) -> list[tuple[str, str]]:
    """Return list of (url, filename) for images to download."""
    jobs: list[tuple[str, str]] = []
    seen: set[str] = set()
    for ident, ref in refs.items():
        if not isinstance(ref, dict) or ref.get("type") != "image":
            continue
        url = pick_variant_url(ref)
        if not url:
            continue
        fname = image_filename(ident, ref)
        if not fname or fname in seen:
            continue
        seen.add(fname)
        jobs.append((url, fname))
    return jobs


def download_image(url: str, fname: str) -> tuple[str, bool, str | None]:
    out = IMAGES_DIR / fname
    if out.exists() and out.stat().st_size > 0:
        return fname, True, None
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in (1, 2):
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
                body = resp.read()
            out.write_bytes(body)
            return fname, True, None
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
            if attempt == 2:
                return fname, False, f"{type(e).__name__}: {e}"
            time.sleep(0.3)
    return fname, False, "unreachable"


# ---------------------------------------------------------------------------
# Block → markdown

def render_blocks(blocks: list, refs: dict, indent: int = 0) -> str:
    """Render a list of content blocks. Returns markdown, may include blank
    lines between blocks."""
    out: list[str] = []
    i = 0
    while i < len(blocks):
        b = blocks[i]
        if not isinstance(b, dict):
            i += 1
            continue
        t = b.get("type")

        # Platform-scoped heading skip logic
        if t == "heading":
            text = (b.get("text") or "").strip()
            if text.lower() in EXCLUDED_PLATFORM_HEADINGS:
                # skip this heading and subsequent siblings until next heading of same/higher level
                level = b.get("level", 1)
                j = i + 1
                while j < len(blocks):
                    nb = blocks[j]
                    if isinstance(nb, dict) and nb.get("type") == "heading" and nb.get("level", 99) <= level:
                        break
                    j += 1
                i = j
                continue

        out.append(render_block(b, refs, indent))
        i += 1
    # dedupe blank lines
    text = "\n\n".join(x for x in out if x is not None and x != "")
    return text


def render_block(b: dict, refs: dict, indent: int = 0) -> str:
    t = b.get("type")
    pad = "  " * indent

    if t == "paragraph":
        content = render_inline(b.get("inlineContent", []), refs).strip()
        if not content:
            return ""
        # If paragraph is just a single image, keep it on its own line (no indent wrap)
        return pad + content.replace("\n", "\n" + pad)

    if t == "heading":
        level = min(max(int(b.get("level", 2)), 1), 6)
        text = (b.get("text") or "").strip()
        return "#" * level + " " + text

    if t in ("unorderedList", "orderedList"):
        return render_list(b, refs, indent)

    if t == "aside":
        style = (b.get("style") or "note").lower()
        prefix = {
            "note": "Note",
            "important": "Important",
            "tip": "Tip",
            "warning": "Warning",
            "experiment": "Experiment",
        }.get(style, style.capitalize())
        inner = render_blocks(b.get("content", []), refs, indent)
        lines = inner.split("\n")
        quoted = "\n".join("> " + ln if ln else ">" for ln in lines)
        return f"> **{prefix}:**\n{quoted}"

    if t == "codeListing":
        syntax = b.get("syntax") or ""
        code = "\n".join(b.get("code", []))
        return f"```{syntax}\n{code}\n```"

    if t == "image":
        ident = b.get("identifier", "")
        ref = refs.get(ident, {})
        alt = (ref.get("alt") or "").replace("\n", " ").strip()
        fname = image_filename(ident, ref)
        if fname:
            return f"![{alt}](../images/{fname})"
        return ""

    if t == "links":
        items = b.get("items", [])
        lines = []
        for ident in items:
            rendered = render_reference(ident, refs)
            if rendered:
                lines.append(f"- {rendered}")
        return "\n".join(lines)

    if t == "row":
        cols = b.get("columns", [])
        parts = [render_blocks(c.get("content", []), refs, indent) for c in cols]
        return "\n\n".join(p for p in parts if p)

    if t == "column":
        return render_blocks(b.get("content", []), refs, indent)

    if t == "termList":
        items = b.get("items", [])
        lines = []
        for item in items:
            term_nodes = item.get("term", {}).get("inlineContent", [])
            def_blocks = item.get("definition", {}).get("content", [])
            term = render_inline(term_nodes, refs).strip()
            definition = render_blocks(def_blocks, refs, 0).strip().replace("\n", " ")
            lines.append(f"- **{term}** — {definition}")
        return "\n".join(lines)

    if t == "table":
        return render_table(b, refs)

    if t == "small":
        return render_blocks(b.get("inlineContent", []), refs, indent)

    # unknown → try content
    if "content" in b:
        return render_blocks(b["content"], refs, indent)
    if "inlineContent" in b:
        return render_inline(b["inlineContent"], refs)
    return ""


def render_list(b: dict, refs: dict, indent: int) -> str:
    ordered = b.get("type") == "orderedList"
    items = b.get("items", [])
    lines: list[str] = []
    pad = "  " * indent
    for idx, item in enumerate(items, 1):
        marker = f"{idx}." if ordered else "-"
        content = item.get("content", [])
        # Render item content, then prefix first line with marker
        rendered = render_blocks(content, refs, indent + 1)
        if not rendered.strip():
            continue
        item_lines = rendered.split("\n")
        # strip leading indent from first line since we prefix with marker
        first_raw = item_lines[0].lstrip()
        lines.append(f"{pad}{marker} {first_raw}")
        for ln in item_lines[1:]:
            if ln.strip():
                lines.append(pad + "  " + ln.lstrip())
            else:
                lines.append("")
    return "\n".join(lines)


def render_table(b: dict, refs: dict) -> str:
    rows = b.get("rows", [])
    if not rows:
        return ""
    header = b.get("header") == "row"
    md_rows: list[list[str]] = []
    for row in rows:
        cells = []
        for cell_blocks in row:
            txt = render_blocks(cell_blocks, refs, 0).strip().replace("\n", " ")
            txt = txt.replace("|", "\\|")
            cells.append(txt)
        md_rows.append(cells)
    if not md_rows:
        return ""
    ncol = max(len(r) for r in md_rows)
    for r in md_rows:
        while len(r) < ncol:
            r.append("")
    lines = ["| " + " | ".join(r) + " |" for r in md_rows]
    if header:
        sep = "| " + " | ".join(["---"] * ncol) + " |"
        lines.insert(1, sep)
    else:
        sep = "| " + " | ".join(["---"] * ncol) + " |"
        lines.insert(0, "| " + " | ".join([""] * ncol) + " |")
        lines.insert(1, sep)
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Topics section

def render_topics(topic_sections: list, refs: dict) -> str:
    if not topic_sections:
        return ""
    out = ["## Topics"]
    for sec in topic_sections:
        title = sec.get("title") or ""
        idents = sec.get("identifiers", [])
        # filter out excluded pages
        items = []
        for ident in idents:
            ref = refs.get(ident, {})
            url = ref.get("url", "")
            internal = slug_from_url(url) if url else slug_from_doc_identifier(ident)
            if internal and is_excluded_slug(internal):
                continue
            items.append(render_reference(ident, refs))
        if not items:
            continue
        if title:
            out.append(f"### {title}")
        out.extend(f"- {it}" for it in items)
    return "\n\n".join(out) if len(out) > 1 else ""


# ---------------------------------------------------------------------------
# Frontmatter builder

STOPWORDS = set("""a an the and or of for in on with to from by as is at be this that
these those your you their app apps user users people use using used make making
can should could would may also other more less new old""".split())

KEYWORD_TAGS = {
    "button": "button", "buttons": "button",
    "menu": "menu", "menus": "menu",
    "sheet": "sheet", "sheets": "sheet",
    "toolbar": "toolbar", "toolbars": "toolbar",
    "navigation": "navigation",
    "tab": "tab-bar", "tabs": "tab-bar",
    "sidebar": "sidebar",
    "window": "window", "windows": "window",
    "icon": "icon", "icons": "icon",
    "color": "color", "colors": "color",
    "typography": "typography", "font": "typography",
    "layout": "layout",
    "accessibility": "accessibility", "voiceover": "accessibility",
    "animation": "animation", "animations": "animation", "motion": "animation",
    "gesture": "gesture", "gestures": "gesture",
    "image": "image", "images": "image",
    "text": "text", "input": "input", "field": "input",
    "picker": "picker", "pickers": "picker",
    "slider": "slider", "sliders": "slider",
    "toggle": "toggle", "toggles": "toggle", "switch": "toggle",
    "alert": "alert", "alerts": "alert",
    "notification": "notification", "notifications": "notification",
    "widget": "widget", "widgets": "widget",
    "chart": "chart", "charts": "chart",
    "list": "list", "lists": "list",
    "table": "table", "tables": "table",
    "material": "material", "materials": "material",
    "glass": "glass", "liquid": "glass",
    "dark": "appearance", "light": "appearance", "mode": "appearance",
    "search": "search",
    "map": "map", "maps": "map",
    "feedback": "feedback",
    "onboarding": "onboarding",
    "interactive": "interactive",
}


def abstract_text(abstract: list, refs: dict) -> str:
    return re.sub(r"\s+", " ", render_inline(abstract or [], refs)).strip()


def platforms_mentioned(body: str) -> list[str]:
    found = []
    for p in KEPT_PLATFORMS:
        # word boundary match (case-sensitive for branding)
        if re.search(rf"\b{re.escape(p)}\b", body):
            found.append(p)
    return found


def derive_tags(title: str, abstract: str) -> list[str]:
    text = f"{title} {abstract}".lower()
    words = re.findall(r"[a-z]+", text)
    tags: list[str] = []
    for w in words:
        if w in STOPWORDS:
            continue
        t = KEYWORD_TAGS.get(w)
        if t and t not in tags:
            tags.append(t)
    return tags


def collect_related(topic_sections: list, refs: dict) -> list[dict]:
    related = []
    seen: set[str] = set()
    for sec in topic_sections or []:
        for ident in sec.get("identifiers", []):
            ref = refs.get(ident, {})
            url = ref.get("url", "")
            slug = slug_from_url(url) if url else slug_from_doc_identifier(ident)
            if not slug or slug in seen or is_excluded_slug(slug):
                continue
            seen.add(slug)
            related.append({"slug": slug, "title": ref.get("title") or slug})
    return related


def yaml_escape(s: str) -> str:
    if s is None:
        return '""'
    s = s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")
    return f'"{s}"'


# ---------------------------------------------------------------------------
# Main conversion

def convert_page(slug: str, data: dict) -> tuple[str, dict, list[tuple[str, str]]]:
    """Return (markdown, index_entry, image_jobs)."""
    metadata = data.get("metadata", {}) or {}
    refs = data.get("references", {}) or {}
    title = metadata.get("title") or slug
    role = metadata.get("role") or "article"
    abstract = abstract_text(data.get("abstract", []), refs)

    # Body
    prim = data.get("primaryContentSections", []) or []
    body_parts: list[str] = []
    for section in prim:
        if section.get("kind") == "content":
            body_parts.append(render_blocks(section.get("content", []), refs))
    body = "\n\n".join(bp for bp in body_parts if bp.strip())

    topics = render_topics(data.get("topicSections", []), refs)
    if topics:
        body = (body + "\n\n" + topics).strip() if body else topics

    # Frontmatter
    platforms = platforms_mentioned(body)
    related = collect_related(data.get("topicSections", []), refs)
    source_slug = slug if slug != "_root" else ""
    source_url = f"https://developer.apple.com/design/human-interface-guidelines"
    if source_slug:
        source_url += f"/{source_slug}"

    fm_lines = ["---"]
    fm_lines.append(f"title: {yaml_escape(title)}")
    fm_lines.append(f"slug: {yaml_escape(slug)}")
    fm_lines.append(f"source_url: {yaml_escape(source_url)}")
    fm_lines.append(f"role: {yaml_escape(role)}")
    fm_lines.append(f"abstract: {yaml_escape(abstract)}")
    if platforms:
        fm_lines.append("platforms_mentioned: [" + ", ".join(platforms) + "]")
    else:
        fm_lines.append("platforms_mentioned: []")
    if related:
        fm_lines.append("related:")
        for r in related:
            fm_lines.append(f"  - slug: {yaml_escape(r['slug'])}")
            fm_lines.append(f"    title: {yaml_escape(r['title'])}")
    else:
        fm_lines.append("related: []")
    fm_lines.append("---")
    fm = "\n".join(fm_lines)

    md = fm + "\n\n" + f"# {title}\n"
    if abstract:
        md += f"\n{abstract}\n"
    if body:
        md += f"\n{body}\n"

    # cleanup excessive blank lines
    md = re.sub(r"\n{3,}", "\n\n", md).rstrip() + "\n"

    tags = derive_tags(title, abstract)
    index_entry = {
        "slug": slug,
        "title": title,
        "role": role,
        "abstract": abstract,
        "platforms": platforms,
        "tags": tags,
        "path": f"pages/{slug}.md",
    }

    image_jobs = collect_image_downloads(refs)
    return md, index_entry, image_jobs


def main() -> int:
    PAGES_DIR.mkdir(parents=True, exist_ok=True)
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    json_files = sorted(JSON_DIR.glob("*.json"))
    print(f"[convert] {len(json_files)} JSON files to process")

    index_entries: list[dict] = []
    all_image_jobs: dict[str, str] = {}  # fname -> url (dedup)
    failures: list[tuple[str, str]] = []

    for jf in json_files:
        slug = jf.stem
        if is_excluded_slug(slug):
            continue
        try:
            data = json.loads(jf.read_text())
            md, entry, jobs = convert_page(slug, data)
            (PAGES_DIR / f"{slug}.md").write_text(md)
            index_entries.append(entry)
            for url, fname in jobs:
                if fname not in all_image_jobs:
                    all_image_jobs[fname] = url
        except Exception as e:
            failures.append((slug, f"{type(e).__name__}: {e}"))
            print(f"[convert]  FAIL {slug}: {e}")

    print(f"[convert] markdown: {len(index_entries)} pages, {len(failures)} failures")

    # Download images
    print(f"[convert] images: {len(all_image_jobs)} unique to fetch")
    img_ok = 0
    img_fail: list[tuple[str, str]] = []
    with ThreadPoolExecutor(max_workers=8) as pool:
        futs = {pool.submit(download_image, url, fname): fname for fname, url in all_image_jobs.items()}
        for i, fut in enumerate(as_completed(futs), 1):
            fname, success, err = fut.result()
            if success:
                img_ok += 1
            else:
                img_fail.append((fname, err or "?"))
            if i % 100 == 0 or i == len(futs):
                print(f"[convert]  images {i}/{len(futs)} (ok={img_ok}, fail={len(img_fail)})")

    # Write index.json
    index_entries.sort(key=lambda e: e["slug"])
    INDEX_PATH.write_text(json.dumps({
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "count": len(index_entries),
        "pages": index_entries,
    }, indent=2))

    # Write tags.json
    tag_map: dict[str, list[str]] = {}
    for e in index_entries:
        for tag in e["tags"]:
            tag_map.setdefault(tag, []).append(e["slug"])
    for tag in tag_map:
        tag_map[tag].sort()
    TAGS_PATH.write_text(json.dumps(dict(sorted(tag_map.items())), indent=2))

    print(f"[convert] wrote index.json ({len(index_entries)} entries), tags.json ({len(tag_map)} tags)")
    if failures:
        print("[convert] PAGE FAILURES:")
        for slug, err in failures:
            print(f"  {slug}: {err}")
    if img_fail:
        print("[convert] IMAGE FAILURES:")
        for fname, err in img_fail[:20]:
            print(f"  {fname}: {err}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
