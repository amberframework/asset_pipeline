#!/usr/bin/env python3
"""
Triage the Apple HIG corpus into a validation worklist.

Reads:
  - .claude/skills/apple-hig/index.json                     (HIG pages)
  - .claude/skills/apple-hig/_build/json/*.json             (HIG topic groups)
  - .claude/skills/apple-hig/pages/<slug>.md                (for hig_ref_image)
  - src/ui/views/*.cr                                       (for UI::View classes)
  - src/ui/renderers/{appkit,uikit}_renderer.cr             (for visit methods)
  - .claude/skills/component-mapping-matrix/SKILL.md        (for priority)

Writes:
  - .claude/skills/apple-platform-guide/validation/worklist.json

Stdlib only. Python 3.
"""

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# -------------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------------

# This file lives at <repo>/.claude/skills/apple-hig/_build/triage.py
SCRIPT_DIR = Path(__file__).resolve().parent
APPLE_HIG_DIR = SCRIPT_DIR.parent                        # .../apple-hig
SKILLS_DIR = APPLE_HIG_DIR.parent                        # .../skills
CLAUDE_DIR = SKILLS_DIR.parent                           # .../.claude
REPO_ROOT = CLAUDE_DIR.parent                            # repo root

INDEX_JSON = APPLE_HIG_DIR / "index.json"
JSON_DIR = APPLE_HIG_DIR / "_build" / "json"
PAGES_DIR = APPLE_HIG_DIR / "pages"

VIEWS_DIR = REPO_ROOT / "src" / "ui" / "views"
APPKIT_RENDERER = REPO_ROOT / "src" / "ui" / "renderers" / "appkit_renderer.cr"
UIKIT_RENDERER = REPO_ROOT / "src" / "ui" / "renderers" / "uikit_renderer.cr"

MAPPING_MATRIX = SKILLS_DIR / "component-mapping-matrix" / "SKILL.md"

OUT_DIR = SKILLS_DIR / "apple-platform-guide" / "validation"
OUT_FILE = OUT_DIR / "worklist.json"

# -------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


def load_topic_group_slugs() -> dict:
    """
    Read the HIG topic-group JSONs and return a dict of
      { 'foundations': set([...]), 'patterns': set([...]), 'components': set([...]), 'platform-guides': set([...]) }

    Also identifies which topic-slug each page belongs to (e.g. "content",
    "layout-and-organization", etc.) — those nested under "components" all
    count as component pages.
    """
    topic_groups = {
        "foundations": set(),
        "patterns": set(),
        "components": set(),   # union of all component sub-topics
        "platform-guides": set(),
        "inputs": set(),
        "technologies": set(),
    }

    # component sub-topics — pages listed under these are components.
    component_subtopics = [
        "content",
        "layout-and-organization",
        "menus-and-actions",
        "navigation-and-search",
        "presentation",
        "selection-and-input",
        "status",
        "system-experiences",
    ]

    def slugs_from(name: str) -> list:
        p = JSON_DIR / f"{name}.json"
        if not p.exists():
            return []
        data = json.loads(p.read_text())
        ids = []
        for ts in data.get("topicSections", []):
            ids.extend(ts.get("identifiers", []))
        return [i.rsplit("/", 1)[-1].lower() for i in ids]

    topic_groups["foundations"].update(slugs_from("foundations"))
    topic_groups["patterns"].update(slugs_from("patterns"))
    topic_groups["platform-guides"].update(slugs_from("getting-started"))
    topic_groups["inputs"].update(slugs_from("inputs"))
    topic_groups["technologies"].update(slugs_from("technologies"))

    for sub in component_subtopics:
        topic_groups["components"].update(slugs_from(sub))

    return topic_groups


def classify_role(slug: str, groups: dict) -> str:
    """Classify a page slug into one of: platform-guide, foundation, pattern, component, other."""
    # platform-guide: slug starts with designing-for- OR is carplay (per plan)
    if slug.startswith("designing-for-") or slug == "carplay":
        return "platform-guide"
    if slug in groups["platform-guides"]:
        return "platform-guide"
    if slug in groups["foundations"]:
        return "foundation"
    if slug in groups["patterns"]:
        return "pattern"
    if slug in groups["components"]:
        return "component"
    # inputs / technologies are neither components nor patterns — mark as pattern-ish "other"
    # but fold into "pattern" so the full HIG is accounted for with non-component role.
    if slug in groups["inputs"]:
        return "pattern"
    if slug in groups["technologies"]:
        return "pattern"
    # Root/collection nodes
    if slug in ("_root", "components", "foundations", "patterns", "inputs",
                "technologies", "getting-started", "content",
                "layout-and-organization", "menus-and-actions",
                "navigation-and-search", "presentation", "selection-and-input",
                "status", "system-experiences"):
        return "collection"
    # Default: component (per plan — "when in doubt default to component")
    return "component"


# -------------------------------------------------------------------------
# UI::View class discovery
# -------------------------------------------------------------------------

CLASS_RE = re.compile(r"^\s*class\s+(\w+)\s*(?:<\s*\w+)?\s*$", re.MULTILINE)


def discover_ui_views() -> dict:
    """
    Return { file_stem (str) -> class_name (str) } for every UI::View subclass.

    File stem is the bare filename without .cr (e.g. "button", "menu_button").
    Class name is the Crystal class name (e.g. "Button", "MenuButton").
    """
    result = {}
    for path in sorted(VIEWS_DIR.glob("*.cr")):
        stem = path.stem
        text = path.read_text()
        # look for `class Name < View` or `class Name` inside module UI
        # We match any top-level class declaration inside the module UI block.
        # The views all live in `module UI ... class X < View ... end ... end`
        classes = CLASS_RE.findall(text)
        # Heuristic: prefer a class whose name looks like CamelCase of the stem,
        # otherwise take the first class found.
        chosen = None
        if classes:
            # Skip helper classes like record types — prefer the one that
            # matches the stem CamelCase.
            camel = "".join(part.capitalize() for part in stem.split("_"))
            for c in classes:
                if c == camel:
                    chosen = c
                    break
            if chosen is None:
                # fall back to first class that is not a plain record-ish name
                chosen = classes[0]
        if chosen:
            result[stem] = chosen
    return result


def slug_to_candidate_class_names(slug: str) -> list:
    """
    Given a HIG slug like 'buttons' or 'pop-up-buttons' or 'action-sheets',
    yield candidate UI::View class names to search for.
    """
    candidates = []

    # Normalize: replace hyphens with spaces for easier splitting
    parts = slug.split("-")

    # Try as-is (plural form joined)
    camel_plural = "".join(p.capitalize() for p in parts)
    candidates.append(camel_plural)

    # Try singular (strip trailing -s on the last segment only)
    if parts and parts[-1].endswith("s") and len(parts[-1]) > 1:
        singular_parts = parts[:-1] + [parts[-1][:-1]]
        camel_singular = "".join(p.capitalize() for p in singular_parts)
        candidates.append(camel_singular)

    # Try stripping trailing "s" from every segment (rare but cheap)
    stripped_parts = [p[:-1] if p.endswith("s") and len(p) > 1 else p for p in parts]
    camel_all_singular = "".join(p.capitalize() for p in stripped_parts)
    if camel_all_singular not in candidates:
        candidates.append(camel_all_singular)

    # Special-case aliases
    alias_map = {
        "pop-up-buttons": ["MenuButton", "PopUpButton"],
        "pull-down-buttons": ["MenuButton", "PullDownButton"],
        "action-sheets": ["ActionSheet", "Sheet"],
        "activity-views": ["ActivityView", "Sheet"],
        "segmented-controls": ["SegmentedControl"],
        "text-fields": ["TextField"],
        "search-fields": ["SearchField"],
        "secure-fields": ["SecureField"],
        "color-wells": ["ColorPicker", "ColorWell"],
        "progress-indicators": ["ProgressView", "ActivityIndicator"],
        "rating-indicators": ["RatingView"],
        "image-views": ["Image", "AsyncImage"],
        "image-wells": ["ImageWell"],
        "text-views": ["TextArea", "TextEditor", "RichText"],
        "web-views": ["WebViewComponent", "WebView"],
        "charts": ["ChartView"],
        "charting-data": ["ChartView"],
        "maps": ["MapView"],
        "lists-and-tables": ["ListView"],
        "tab-bars": ["TabView"],
        "tab-views": ["TabView"],
        "split-views": ["NavigationSplitView"],
        "navigation-bars": ["NavigationStack"],
        "navigation-and-search": ["NavigationStack"],
        "pickers": ["Picker"],
        "date-pickers": ["DatePicker"],
        "time-pickers": ["TimePicker"],
        "digit-entry-views": ["TextField"],
        "disclosure-controls": ["Toggle"],
        "combo-boxes": ["ComboBox"],
        "context-menus": ["MenuButton"],
        "edit-menus": ["MenuButton"],
        "dock-menus": ["MenuButton"],
        "the-menu-bar": ["Menu"],
        "pop-up-menus": ["MenuButton"],
        "menus": ["MenuButton"],
        "toolbars": ["Toolbar"],
        "sidebars": ["NavigationSplitView"],
        "path-controls": ["PathView"],
        "page-controls": ["PageControl"],
        "scroll-views": ["ScrollView"],
        "column-views": ["ColumnView"],
        "outline-views": ["OutlineView"],
        "labels": ["Label"],
        "boxes": ["Surface", "Card"],
        "collections": ["Grid", "ListView"],
        "lockups": ["Card"],
        "video-views": ["VideoPlayer"],
        "virtual-keyboards": ["VirtualKeyboard"],
        "token-fields": ["TokenField"],
    }
    if slug in alias_map:
        for a in alias_map[slug]:
            if a not in candidates:
                candidates.insert(0, a)

    return candidates


def match_view_for_slug(slug: str, view_map: dict):
    """
    Return (class_name, file_stem) or (None, None) if no match.
    view_map: { file_stem -> class_name }
    """
    # Build reverse lookup by class name
    class_to_stem = {cls: stem for stem, cls in view_map.items()}

    for cand in slug_to_candidate_class_names(slug):
        if cand in class_to_stem:
            return cand, class_to_stem[cand]

    # Also try stem-based match as backup
    stem_guesses = [
        slug.replace("-", "_"),
        slug.rstrip("s").replace("-", "_"),
    ]
    for stem in stem_guesses:
        if stem in view_map:
            return view_map[stem], stem

    return None, None


# -------------------------------------------------------------------------
# Renderer visit detection
# -------------------------------------------------------------------------

STUB_MARKERS = ("# TODO", "# STUB", 'raise "not implemented"', "raise \"not implemented\"")


def find_visit_block(renderer_text: str, class_name: str) -> str | None:
    """
    Return the body of `def visit(view : UI::<ClassName>)` up to the matching
    `end`, or None if the method isn't defined. Naive depth-matching on
    `def`/`do`/`if`/`case`/`class`/`module`/`begin` vs `end`.
    """
    pattern = re.compile(
        rf"^(\s*)def\s+visit\(view\s*:\s*UI::{re.escape(class_name)}\s*\)\s*$",
        re.MULTILINE,
    )
    m = pattern.search(renderer_text)
    if not m:
        return None
    start = m.start()
    base_indent = len(m.group(1))
    lines = renderer_text[start:].splitlines()

    # First line is the def. Walk until we hit an `end` at base_indent.
    body = []
    body.append(lines[0])
    for line in lines[1:]:
        body.append(line)
        stripped = line.strip()
        if line.startswith(" " * base_indent + "end") and line[base_indent:].rstrip() == "end":
            break
        # If indentation goes back to base_indent with 'end' as sole content
        if stripped == "end" and (len(line) - len(line.lstrip())) == base_indent:
            break
    return "\n".join(body)


def detect_status(class_name: str | None, appkit_text: str, uikit_text: str) -> tuple:
    """
    Returns (status, ios_visit_found, macos_visit_found).
    status is 'implemented' | 'stub' | 'missing'.
    """
    if class_name is None:
        return "missing", False, False

    mac_block = find_visit_block(appkit_text, class_name)
    ios_block = find_visit_block(uikit_text, class_name)

    mac_found = mac_block is not None
    ios_found = ios_block is not None

    if not mac_found and not ios_found:
        return "stub", False, False

    def is_stub_body(block: str) -> bool:
        return any(marker in block for marker in STUB_MARKERS)

    mac_stub = mac_found and is_stub_body(mac_block)
    ios_stub = ios_found and is_stub_body(ios_block)

    if mac_found and ios_found and not mac_stub and not ios_stub:
        return "implemented", ios_found, mac_found

    return "stub", ios_found, mac_found


# -------------------------------------------------------------------------
# Priority lookup from mapping matrix
# -------------------------------------------------------------------------

PRIORITY_ROW_RE = re.compile(r"^\|\s*`UI::(\w+)`\s*\|\s*\*\*(P[0-3])\*\*", re.MULTILINE)


def load_priority_map(matrix_path: Path) -> dict:
    """
    Return { ClassName -> "P0"|"P1"|"P2"|"P3" } from the mapping matrix SKILL.md.
    """
    if not matrix_path.exists():
        return {}
    text = matrix_path.read_text()
    result = {}
    for cls, prio in PRIORITY_ROW_RE.findall(text):
        # If a class appears multiple times (shouldn't, but defensive), keep the
        # highest priority (smallest number).
        if cls in result:
            if int(prio[1]) < int(result[cls][1]):
                result[cls] = prio
        else:
            result[cls] = prio
    return result


# -------------------------------------------------------------------------
# HIG page image extraction
# -------------------------------------------------------------------------

IMAGE_LINE_RE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")


def find_first_image(page_path: Path) -> str | None:
    """
    Return the first image path referenced from the page markdown, normalized
    to 'images/...' relative to the apple-hig skill root (without leading ../).
    """
    if not page_path.exists():
        return None
    for line in page_path.read_text().splitlines():
        m = IMAGE_LINE_RE.search(line)
        if m:
            raw = m.group(1).strip()
            # The pages reference ../images/<file>.png ; emit relative to
            # apple-platform-guide/validation/ (which sits next to apple-hig),
            # so we use ../apple-hig/images/<file> per the plan's spot-check.
            if raw.startswith("../images/"):
                fname = raw[len("../images/"):]
            elif raw.startswith("images/"):
                fname = raw[len("images/"):]
            elif raw.startswith("./images/"):
                fname = raw[len("./images/"):]
            else:
                # external URL or unexpected — skip
                continue
            return f"../apple-hig/images/{fname}"
    return None


# -------------------------------------------------------------------------
# Environment detection
# -------------------------------------------------------------------------


def detect_ios_target() -> tuple:
    """
    Runs `xcrun --sdk iphonesimulator --show-sdk-version`. If the major is >= 26,
    return ("26.0", sdk_version_str, True). Else ("17.0", sdk_version_str_or_"unknown", False).
    """
    try:
        r = subprocess.run(
            ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        sdk = r.stdout.strip()
    except Exception as e:
        log(f"[triage] xcrun failed: {e}")
        sdk = ""

    try:
        major = int(sdk.split(".")[0]) if sdk else 0
    except ValueError:
        major = 0

    if major >= 26:
        return "26.0", sdk or "unknown", True
    return "17.0", sdk or "unknown", False


# -------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Backdrop selection map
# Mirrors the logic in validation/backdrops/generate_backdrops.py.
# When triage.py regenerates the worklist, each component row gets a
# `backdrop` field naming the image stem (without -light/-dark suffix).
# The capture harness appends the appropriate suffix per HIG_APPEARANCE.
# ---------------------------------------------------------------------------

SLUG_BACKDROP_MAP: dict[str, str] = {
    # Menus / context menus / dock / edit / menu bar
    "context-menus":          "menu-backdrop-amber-document",
    "menus":                  "menu-backdrop-amber-document",
    "dock-menus":             "menu-backdrop-amber-document",
    "edit-menus":             "menu-backdrop-amber-document",
    "the-menu-bar":           "menu-backdrop-amber-document",
    "pop-up-buttons":         "menu-backdrop-amber-document",
    "pull-down-buttons":      "menu-backdrop-amber-document",
    # Sidebars / split-views / navigation
    "sidebars":               "sidebar-backdrop-amber-inbox",
    "split-views":            "sidebar-backdrop-amber-inbox",
    "navigation-bars":        "sidebar-backdrop-amber-inbox",
    # Finder-style column / outline
    "column-views":           "finder-mail-backdrop",
    "outline-views":          "finder-mail-backdrop",
    # Home screen / widgets / live activities / lock screen
    "widgets":                "home-screen-amber-wallpaper",
    "live-activities":        "lock-screen-amber",
    "complications":          "lock-screen-amber",
    "notifications":          "lock-screen-amber",
    "home-screen-quick-actions": "home-screen-amber-wallpaper",
    "top-shelf":              "home-screen-amber-wallpaper",
}
DEFAULT_BACKDROP = "sheet-backdrop-amber-gradient"


def backdrop_for_slug(slug: str) -> str:
    return SLUG_BACKDROP_MAP.get(slug, DEFAULT_BACKDROP)


def main() -> int:
    log(f"[triage] repo root: {REPO_ROOT}")
    log(f"[triage] reading HIG index: {INDEX_JSON}")
    index = json.loads(INDEX_JSON.read_text())
    pages = index.get("pages", [])

    groups = load_topic_group_slugs()
    log(
        f"[triage] topic groups: foundations={len(groups['foundations'])}, "
        f"patterns={len(groups['patterns'])}, components={len(groups['components'])}, "
        f"platform-guides={len(groups['platform-guides'])}, "
        f"inputs={len(groups['inputs'])}, technologies={len(groups['technologies'])}"
    )

    log(f"[triage] discovering UI::View classes under {VIEWS_DIR}")
    view_map = discover_ui_views()
    log(f"[triage] found {len(view_map)} UI::View classes")

    appkit_text = APPKIT_RENDERER.read_text() if APPKIT_RENDERER.exists() else ""
    uikit_text = UIKIT_RENDERER.read_text() if UIKIT_RENDERER.exists() else ""

    priority_map = load_priority_map(MAPPING_MATRIX)
    log(f"[triage] loaded {len(priority_map)} priorities from mapping matrix")

    ios_target, sdk_version, liquid_glass = detect_ios_target()
    log(f"[triage] iOS target: {ios_target} (sdk={sdk_version}, liquid_glass={liquid_glass})")

    rows = []
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

    for page in pages:
        slug = page.get("slug", "")
        if not slug or slug == "_root":
            # skip the root collection
            continue

        role = classify_role(slug, groups)
        counts["total_hig_pages"] += 1
        if role == "component":
            counts["components"] += 1
        elif role == "foundation":
            counts["foundations"] += 1
        elif role == "pattern":
            counts["patterns"] += 1
        elif role == "platform-guide":
            counts["platform_guides"] += 1
        elif role == "collection":
            counts["collections"] += 1

        page_md_path = PAGES_DIR / f"{slug}.md"
        hig_ref_image = find_first_image(page_md_path)

        if role != "component":
            # Non-component rows: skipped but included for audit.
            rows.append({
                "slug": slug,
                "hig_title": page.get("title", ""),
                "hig_page": f"../apple-hig/pages/{slug}.md",
                "hig_ref_image": hig_ref_image,
                "role": role,
                "ui_view": None,
                "ui_view_file": None,
                "status": "n/a",
                "priority": None,
                "iOS_visit_found": False,
                "macOS_visit_found": False,
                "validation_state": "skipped",
                "skip_reason": role,
                "docs_written": False,
            })
            continue

        # Component row
        class_name, file_stem = match_view_for_slug(slug, view_map)
        status, ios_found, mac_found = detect_status(class_name, appkit_text, uikit_text)

        if status == "implemented":
            counts["implemented"] += 1
        elif status == "stub":
            counts["stub"] += 1
        elif status == "missing":
            counts["missing"] += 1

        priority = priority_map.get(class_name, "P2") if class_name else "P2"

        rows.append({
            "slug": slug,
            "hig_title": page.get("title", ""),
            "hig_page": f"../apple-hig/pages/{slug}.md",
            "hig_ref_image": hig_ref_image,
            "role": "component",
            "ui_view": f"UI::{class_name}" if class_name else None,
            "ui_view_file": f"src/ui/views/{file_stem}.cr" if file_stem else None,
            "status": status,
            "priority": priority,
            "iOS_visit_found": ios_found,
            "macOS_visit_found": mac_found,
            # TODO: a future version of this script should preserve an
            # existing validation_state from a prior worklist.json so that
            # agent progress isn't clobbered on re-run.
            "validation_state": "pending",
            "docs_written": False,
            "backdrop": backdrop_for_slug(slug),
        })

    out = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "environment": {
            "ios_target": ios_target,
            "xcode_sdk_version": sdk_version,
            "liquid_glass_available": liquid_glass,
        },
        "counts": counts,
        "pages": rows,
    }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(json.dumps(out, indent=2) + "\n")
    log(f"[triage] wrote {OUT_FILE}")
    log(f"[triage] counts: {json.dumps(counts)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
