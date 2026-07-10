#!/usr/bin/env python3
"""
Regenerate the HIG validation dashboard at validation/index.html.

On every run:
1. Snapshot every PNG in validation/screenshots/ into validation/history/<stamp>-<label>/
2. Write the canonical index.html (src paths → screenshots/...) always showing latest state.
3. Write a timestamped snapshot index-<label>.html with src paths → history/<stamp>-<label>/...
   so the frozen version truly is frozen even after captures are overwritten.
4. Regenerate validation/history.html — the per-slug timeline that shows every iteration's
   captures side-by-side for each slug, so progress (and regressions) are visible at a glance.

Reads: worklist.json, reports/<slug>.md frontmatter, screenshots/<slug>-*.png
Writes: index.html (current), index-<label>.html (frozen), history.html (timeline),
        history/<stamp>-<label>/<slug>-*.png (snapshot PNGs)

Run from anywhere. Paths are anchored to this script's directory.
"""
from __future__ import annotations
import json
import re
import shutil
from datetime import datetime, timezone
from html import escape
from pathlib import Path

HERE = Path(__file__).resolve().parent            # .../validation/
SKILL = HERE.parent                                # .../apple-platform-guide/
CORPUS = SKILL.parent / "apple-hig"                # .../apple-hig/
REPO_ROOT = HERE.parents[3]                        # .../asset_pipeline/
PUBLIC_VALIDATION = REPO_ROOT / "docs" / "apple-native-validation"

WORKLIST = HERE / "worklist.json"
REPORTS = HERE / "reports"
SHOTS = HERE / "screenshots"
BACKDROPS = HERE / "backdrops"
HISTORY = HERE / "history"
COMPONENTS = SKILL / "components"
HIG_IMAGES = CORPUS / "images"

STATE_CLASS = {
    "pass": "v-pass",
    "pass_with_notes": "v-pwn",
    "skipped": "v-skip",
    "needs_work": "v-needs",
    "fail": "v-needs",
    "pending": "v-pending",
}
STATE_LABEL = {
    "pass": "PASS",
    "pass_with_notes": "PASS_WITH_NOTES",
    "skipped": "SKIPPED",
    "needs_work": "NEEDS_WORK",
    "fail": "FAIL",
    "pending": "PENDING",
}
SUB_CLASS = {
    "pass": "sv-pass",
    "pass_with_notes": "sv-pwn",
    "needs_work": "sv-needs",
    "fail": "sv-needs",
    "n/a (platform)": "sv-skip",
}


def read_worklist():
    return json.loads(WORKLIST.read_text())


def report_frontmatter(slug: str) -> dict:
    p = REPORTS / f"{slug}.md"
    if not p.exists():
        return {}
    txt = p.read_text()
    m = re.match(r"^---\n(.*?)\n---", txt, re.DOTALL)
    if not m:
        return {}
    out = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith(" "):
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip()
    return out


def shot_exists(slug: str, platform: str, appearance: str) -> bool:
    return (SHOTS / f"{slug}-{platform}-{appearance}.png").exists()


def hig_ref_path(row) -> str | None:
    ref = row.get("hig_ref_image")
    if not ref:
        return None
    # Worklist stores paths as "../apple-hig/images/..." (relative to the skill root),
    # but index.html lives at validation/index.html, so the href needs one more "../".
    # Try both and return whichever exists on disk, with the correct href for index.html.
    candidates = [ref, "../" + ref]
    for href in candidates:
        abs_path = (HERE / href).resolve()
        if abs_path.exists():
            return href
    return None


def render_sub_verdicts(vpa: dict | None) -> str:
    if not vpa:
        return ""
    cells = []
    order = ["macos_light", "macos_dark", "ios_light", "ios_dark"]
    labels = {"macos_light": "macOS L", "macos_dark": "macOS D",
              "ios_light": "iOS L", "ios_dark": "iOS D"}
    for k in order:
        v = str(vpa.get(k, "") or "").lower()
        cls = SUB_CLASS.get(v, "")
        cells.append(f"<strong>{labels[k]}</strong><span class='{cls}'>{escape(v or '—')}</span>")
    return f"<div class='sub-verdicts'>{''.join(cells)}</div>"


def render_4grid(slug: str) -> str:
    pairs = [
        ("macOS light", f"{slug}-macos-light.png"),
        ("macOS dark", f"{slug}-macos-dark.png"),
        ("iOS light", f"{slug}-ios-light.png"),
        ("iOS dark", f"{slug}-ios-dark.png"),
    ]
    parts = []
    for label, name in pairs:
        p = SHOTS / name
        if p.exists():
            parts.append(f"<div class='cap'><span class='cap-label'>{label}</span>"
                         f"<a href='screenshots/{name}'><img src='screenshots/{name}'></a></div>")
        else:
            parts.append(f"<div class='cap'><span class='cap-label'>{label}</span>"
                         f"<span class='missing'>missing</span></div>")
    return f"<div class='grid4'>{''.join(parts)}</div>"


def render_hig_ref(row) -> str:
    ref = hig_ref_path(row)
    if ref:
        return f"<a href='{ref}'><img class='small' src='{ref}'></a>"
    return "<span class='missing'>no HIG ref</span>"


def render_artifacts(slug: str) -> str:
    links = []
    if (REPORTS / f"{slug}.md").exists():
        links.append(f"<a href='reports/{slug}.md'>report</a>")
    if (COMPONENTS / f"{slug}.md").exists():
        links.append(f"<a href='../components/{slug}.md'>usage doc</a>")
    return " · ".join(links) if links else "<span class='missing'>no docs</span>"


def render_backdrop_cell(row) -> str:
    """
    Renders a thumbnail + name for the backdrop assigned to this row.
    Shows light variant thumbnail if available (macOS preferred).
    """
    stem = row.get("backdrop") or ""
    if not stem:
        return "<span class='missing'>none</span>"

    # Try macOS light variant first, then iOS light, then dark
    candidates = [
        f"{stem}-light.png",
        f"{stem}-ios-light.png",
        f"{stem}-dark.png",
        f"{stem}.png",
    ]
    found_name = None
    for name in candidates:
        if (BACKDROPS / name).exists():
            found_name = name
            break

    label = escape(stem)
    if found_name:
        href = f"backdrops/{found_name}"
        return (
            f"<div class='backdrop-cell'>"
            f"<a href='{href}'><img class='backdrop-thumb' src='{href}'></a>"
            f"<span class='backdrop-name'>{label}</span>"
            f"</div>"
        )
    return f"<span class='backdrop-name missing'>{label}</span>"


def render_evidence_badge(row) -> str:
    state = str(row.get("evidence_state") or "").lower()
    if not state:
        return ""

    cls = {
        "valid": "ev-valid",
        "invalid": "ev-invalid",
        "not_applicable": "ev-na",
    }.get(state, "ev-na")
    label = {
        "valid": "evidence current",
        "invalid": "evidence stale",
        "not_applicable": "evidence n/a",
    }.get(state, state.replace("_", " "))
    errors = row.get("evidence_errors") or []
    suffix = f" ({len(errors)})" if state == "invalid" and errors else ""
    return f"<span class='evidence {cls}'>{escape(label + suffix)}</span>"


def render_row(row) -> str:
    slug = row["slug"]
    state = (row.get("validation_state") or "pending").lower()
    st_cls = STATE_CLASS.get(state, "v-pending")
    st_lbl = STATE_LABEL.get(state, state.upper())
    fm = report_frontmatter(slug)
    iteration = fm.get("iteration", "")
    sub = render_sub_verdicts(row.get("verdict_per_appearance"))
    notes = row.get("notes") or row.get("remediation_hint") or row.get("skip_reason") or ""
    ui_view = row.get("ui_view") or ""
    priority = row.get("priority") or ""
    glass_required = row.get("glass_required")
    glass_expected = row.get("glass_material_expected")
    glass_note = ""
    if glass_required:
        glass_note = f"<span class='ui-view'>glass: {escape(str(glass_expected or ''))}</span>"

    backdrop_cell = render_backdrop_cell(row)

    meta_bits = [f"<span class='ui-view'>{escape(ui_view)}</span>"]
    if glass_note:
        meta_bits.append(glass_note)
    meta_line = " ".join(meta_bits)

    return f"""<tr>
<td><span class='pri'>{priority}</span> <span class='slug'>{escape(slug)}</span><br>
<span class='{st_cls}'>{st_lbl}</span>{f" · iter {escape(iteration)}" if iteration else ""} {render_evidence_badge(row)}<br>
{meta_line}
{sub}
{f"<span class='notes'>{escape(notes)}</span>" if notes else ""}</td>
<td>{render_4grid(slug)}</td>
<td>{render_hig_ref(row)}</td>
<td>{backdrop_cell}</td>
<td>{render_artifacts(slug)}</td>
</tr>"""


CSS = """body{font:14px -apple-system,sans-serif;margin:24px;background:#f2f2f7;color:#1d1d1f}
h1{font-size:28px;margin-bottom:4px}h2{margin-top:32px}
table{border-collapse:collapse;width:100%;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.08)}
th,td{padding:12px 16px;text-align:left;border-bottom:1px solid #e5e5ea;vertical-align:top}
th{background:#f9f9fb;font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:#636366}
tr:last-child td{border-bottom:none}
img{max-width:240px;max-height:240px;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.08);display:block;background:#fff}
img.small{max-width:200px;max-height:200px}
.grid4{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.grid4 .cap{display:flex;flex-direction:column;gap:4px}
.grid4 .cap-label{font-size:11px;color:#636366;text-transform:uppercase;letter-spacing:.04em}
.pri{display:inline-block;padding:2px 6px;font-size:11px;background:#e5e5ea;color:#1d1d1f;border-radius:4px;font-weight:600;margin-right:4px}
.v-pass{color:#34c759;font-weight:600}
.v-pwn{color:#ff9500;font-weight:600}
.v-skip{color:#8e8e93;font-weight:600}
.v-needs{color:#ff3b30;font-weight:600}
.v-pending{color:#8e8e93;font-weight:600}
.evidence{display:inline-block;margin-left:6px;padding:2px 6px;border-radius:999px;font-size:10px;font-weight:600;letter-spacing:.04em;text-transform:uppercase;vertical-align:middle}
.ev-valid{background:#e8fff0;color:#1f8f4d}
.ev-invalid{background:#fff1ef;color:#d93025}
.ev-na{background:#f1f1f5;color:#636366}
.sub-verdicts{margin-top:8px;font-size:11px;color:#636366;display:grid;grid-template-columns:auto auto;gap:2px 12px;max-width:260px}
.sub-verdicts strong{font-weight:600;text-transform:uppercase;letter-spacing:.04em;color:#636366;margin-right:6px}
.sv-pass{color:#34c759}.sv-pwn{color:#ff9500}.sv-needs{color:#ff3b30}.sv-skip{color:#8e8e93}
.slug{font-family:ui-monospace,monospace;font-weight:600;font-size:13px}
.notes{color:#636366;font-size:12px;max-width:340px;display:block;margin-top:8px;line-height:1.4}
.ui-view{color:#636366;font-size:12px;margin-right:8px}
a{color:#007aff;text-decoration:none}a:hover{text-decoration:underline}
.missing{color:#ff3b30;font-size:12px}
.backdrop-cell{display:flex;flex-direction:column;gap:4px;max-width:120px}
img.backdrop-thumb{max-width:120px;max-height:90px;border-radius:6px;box-shadow:0 1px 3px rgba(0,0,0,.12)}
.backdrop-name{font-size:11px;color:#636366;word-break:break-word;line-height:1.3}
.pending-list{columns:3;list-style:square;padding-left:20px}
.bar{background:#fff;border-radius:12px;padding:16px 20px;margin-bottom:16px;box-shadow:0 1px 3px rgba(0,0,0,.08)}
.bar h3{margin:0 0 8px;font-size:14px;text-transform:uppercase;letter-spacing:.04em;color:#636366}
.bar ol{margin:0;padding-left:20px;font-size:13px;color:#1d1d1f}
.bar .progress{height:8px;background:#e5e5ea;border-radius:4px;overflow:hidden;margin:8px 0}
.bar .progress-fill{height:100%;background:linear-gradient(90deg,#34c759,#30d158)}
.summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px}
.summary .stat{background:#fff;border-radius:12px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,.08)}
.summary .stat-num{font-size:28px;font-weight:700}
.summary .stat-label{font-size:11px;color:#636366;text-transform:uppercase;letter-spacing:.04em}"""


def build(output_label: str | None = None) -> tuple[Path, Path]:
    data = read_worklist()
    studies = [
        r for r in data["pages"]
        if r.get("role") == "component" or (r.get("status") == "implemented" and r.get("ui_view"))
    ]
    by_state: dict[str, list[dict]] = {}
    for r in studies:
        s = (r.get("validation_state") or "pending").lower()
        by_state.setdefault(s, []).append(r)

    total = len(studies)
    passed = len(by_state.get("pass", [])) + len(by_state.get("pass_with_notes", []))
    skipped = len(by_state.get("skipped", []))
    needs = len(by_state.get("needs_work", [])) + len(by_state.get("fail", []))
    pending = len(by_state.get("pending", []))
    stale = sum(1 for r in studies if (r.get("evidence_state") or "").lower() == "invalid")
    pct = round(100 * passed / total) if total else 0

    sort_key = lambda r: (r.get("priority", "P9"), r.get("slug", ""))
    terminal = sorted(
        by_state.get("pass", []) + by_state.get("pass_with_notes", []) +
        by_state.get("skipped", []) + by_state.get("needs_work", []) +
        by_state.get("fail", []),
        key=sort_key,
    )
    pending_rows = sorted(by_state.get("pending", []), key=sort_key)

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    html = [
        "<!doctype html><meta charset='utf-8'>",
        "<title>Apple HIG validation dashboard</title>",
        f"<style>{CSS}</style>",
        "<h1>Apple HIG validation &mdash; dashboard</h1>",
        f"<p>Generated {now}. <strong>{passed}/{total}</strong> auditable studies reached a terminal state "
        f"(<strong>{pct}%</strong>). {skipped} skipped, {needs} needs-work, {pending} pending, "
        f"{stale} with stale evidence.</p>",
        "<div class='summary'>",
        f"<div class='stat'><div class='stat-num' style='color:#34c759'>{passed}</div><div class='stat-label'>Passing</div></div>",
        f"<div class='stat'><div class='stat-num' style='color:#8e8e93'>{skipped}</div><div class='stat-label'>Skipped</div></div>",
        f"<div class='stat'><div class='stat-num' style='color:#ff3b30'>{needs}</div><div class='stat-label'>Needs work</div></div>",
        f"<div class='stat'><div class='stat-num' style='color:#8e8e93'>{pending}</div><div class='stat-label'>Pending</div></div>",
        f"<div class='stat'><div class='stat-num' style='color:#d93025'>{stale}</div><div class='stat-label'>Stale evidence</div></div>",
        f"<div class='stat'><div class='stat-num'>{total}</div><div class='stat-label'>Auditable studies</div></div>",
        "</div>",
        "<div class='bar'><h3>Progress</h3>",
        f"<div class='progress'><div class='progress-fill' style='width:{pct}%'></div></div>",
        f"<p style='margin:0;font-size:13px;color:#636366'>{passed} of {total} auditable studies terminal · {pct}% complete</p>",
        "</div>",
        "<div class='bar'><h3>Acceptance bar</h3><ol>"
        "<li>Four fresh captures per slug: macOS light/dark + iOS light/dark.</li>"
        "<li>Surface components must show Liquid Glass in every capture.</li>"
        "<li>Legibility verified in both appearances.</li>"
        "<li>Component doc includes 'Light / dark appearance notes' + 'Customization / brand override'.</li>"
        "</ol></div>",
    ]

    html.append(f"<h2>Terminal ({len(terminal)})</h2>")
    html.append("<table><thead><tr><th>Slug / Verdict</th><th>Captures</th><th>HIG reference</th><th>Backdrop</th><th>Artifacts</th></tr></thead><tbody>")
    for row in terminal:
        html.append(render_row(row))
    html.append("</tbody></table>")

    html.append(f"<h2>Pending ({len(pending_rows)})</h2>")
    if pending_rows:
        html.append("<ul class='pending-list'>")
        for r in pending_rows:
            html.append(f"<li><span class='pri'>{r.get('priority','')}</span> "
                        f"<span class='slug'>{escape(r['slug'])}</span> {render_evidence_badge(r)}</li>")
        html.append("</ul>")
    else:
        html.append("<p><em>None — all components terminal.</em></p>")

    out = "\n".join(html)

    current = HERE / "index.html"
    current.write_text(out)

    # Snapshot all PNGs into history/<stamp>-<label>/ so the frozen index-<label>.html
    # stays pinned to what was captured at this moment in time.
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    label_for_folder = output_label if output_label else f"{passed:02d}of{total}"
    history_folder_name = f"{stamp}-{label_for_folder}"
    history_dest = HISTORY / history_folder_name
    history_dest.mkdir(parents=True, exist_ok=True)
    for png in sorted(SHOTS.glob("*.png")):
        shutil.copy2(png, history_dest / png.name)

    # Snapshot HTML rewrites image src paths to the frozen history folder.
    frozen = out.replace("src='screenshots/", f"src='history/{history_folder_name}/")
    frozen = frozen.replace("href='screenshots/", f"href='history/{history_folder_name}/")
    suffix = output_label if output_label else f"{passed:02d}of{total}-{today}"
    snapshot = HERE / f"index-{suffix}.html"
    snapshot.write_text(frozen)

    # Regenerate the per-slug timeline page.
    write_history_page()

    return current, snapshot


def write_history_page() -> Path:
    """Generate history.html — per-slug chronological strip showing every iteration's captures."""
    # Scan history/ folders (each one is a timestamped iteration).
    if not HISTORY.exists():
        return HERE / "history.html"
    folders = sorted([f for f in HISTORY.iterdir() if f.is_dir()])
    if not folders:
        return HERE / "history.html"

    # Parse the folder name into (stamp, label).
    def parse_folder(f: Path) -> tuple[str, str, str]:
        # Folder format: "YYYYMMDD-HHMMSS-label" — split on first occurrence of the label.
        name = f.name
        m = re.match(r"(\d{8})-(\d{6})-(.+)", name)
        if m:
            date_part, time_part, label = m.groups()
            pretty_stamp = f"{date_part[:4]}-{date_part[4:6]}-{date_part[6:]} {time_part[:2]}:{time_part[2:4]}"
            return (name, pretty_stamp, label)
        return (name, name, "")

    # Build slug → list[(folder_name, pretty_stamp, label, appearance_map)]
    # appearance_map: {"macos-light": "path", "macos-dark": ..., "ios-light": ..., "ios-dark": ...}
    slug_timelines: dict[str, list[dict]] = {}
    for f in folders:
        folder_name, pretty_stamp, label = parse_folder(f)
        for png in f.glob("*.png"):
            # parse slug + appearance from filename like "sheets-macos-dark.png"
            m = re.match(r"(.+?)-(macos|ios)-(light|dark)\.png", png.name)
            if not m:
                continue
            slug, platform, mode = m.groups()
            appearance = f"{platform}-{mode}"
            timeline = slug_timelines.setdefault(slug, [])
            # find or create the row for this folder
            row = next((r for r in timeline if r["folder"] == folder_name), None)
            if row is None:
                row = {
                    "folder": folder_name,
                    "stamp": pretty_stamp,
                    "label": label,
                    "appearances": {},
                }
                timeline.append(row)
            row["appearances"][appearance] = f"history/{folder_name}/{png.name}"

    # Render history.html
    html = [
        "<!doctype html><meta charset='utf-8'>",
        "<title>HIG validation — per-slug timeline</title>",
        f"<style>{HISTORY_CSS}</style>",
        "<h1>HIG validation &mdash; per-slug timeline</h1>",
        "<p>Each row is one iteration's captures for that slug. Use this to see progress and regressions.</p>",
        f"<p><a href='index.html'>← back to dashboard</a></p>",
    ]

    for slug in sorted(slug_timelines.keys()):
        timeline = sorted(slug_timelines[slug], key=lambda r: r["folder"])
        html.append(f"<h2 id='{slug}'>{escape(slug)}</h2>")
        html.append("<table class='timeline'>")
        html.append("<thead><tr><th>Iteration</th><th>When (UTC)</th>"
                    "<th>macOS light</th><th>macOS dark</th>"
                    "<th>iOS light</th><th>iOS dark</th></tr></thead>")
        html.append("<tbody>")
        for row in timeline:
            html.append("<tr>")
            html.append(f"<td><span class='label'>{escape(row['label'])}</span></td>")
            html.append(f"<td class='stamp'>{escape(row['stamp'])}</td>")
            for appearance in ("macos-light", "macos-dark", "ios-light", "ios-dark"):
                path = row["appearances"].get(appearance)
                if path:
                    html.append(f"<td><a href='{path}'><img src='{path}'></a></td>")
                else:
                    html.append("<td><span class='missing'>—</span></td>")
            html.append("</tr>")
        html.append("</tbody></table>")

    out_path = HERE / "history.html"
    out_path.write_text("\n".join(html))
    return out_path


def write_public_redirects() -> tuple[Path, Path]:
    """
    Publish easy-to-open docs-path redirect pages that forward to the canonical
    validation dashboard under .claude/.
    """
    PUBLIC_VALIDATION.mkdir(parents=True, exist_ok=True)

    def redirect_page(title: str, target: str) -> str:
        return "\n".join([
            "<!doctype html>",
            "<meta charset='utf-8'>",
            f"<title>{escape(title)}</title>",
            f"<meta http-equiv='refresh' content='0; url={target}'>",
            "<style>body{font:14px -apple-system,sans-serif;margin:40px;background:#f2f2f7;color:#1d1d1f}"
            "main{max-width:720px;background:#fff;padding:24px 28px;border-radius:14px;box-shadow:0 1px 3px rgba(0,0,0,.08)}"
            "a{color:#007aff;text-decoration:none}a:hover{text-decoration:underline}"
            "code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:13px;background:#f5f5f7;padding:2px 6px;border-radius:6px}</style>",
            "<main>",
            f"<h1>{escape(title)}</h1>",
            f"<p>Redirecting to <code>{escape(target)}</code>.</p>",
            f"<p><a href='{target}'>Open the validation page</a></p>",
            "</main>",
        ])

    index_path = PUBLIC_VALIDATION / "index.html"
    index_path.write_text(
        redirect_page(
            "Apple Native Validation Dashboard",
            "../../.claude/skills/apple-platform-guide/validation/index.html",
        )
    )

    history_path = PUBLIC_VALIDATION / "history.html"
    history_path.write_text(
        redirect_page(
            "Apple Native Validation History",
            "../../.claude/skills/apple-platform-guide/validation/history.html",
        )
    )

    return index_path, history_path


HISTORY_CSS = """body{font:14px -apple-system,sans-serif;margin:24px;background:#f2f2f7;color:#1d1d1f}
h1{font-size:28px;margin-bottom:4px}
h2{margin-top:48px;font-family:ui-monospace,monospace;background:#fff;padding:8px 12px;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,.08)}
a{color:#007aff;text-decoration:none}a:hover{text-decoration:underline}
table.timeline{border-collapse:collapse;width:100%;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.08);margin-bottom:16px}
.timeline th,.timeline td{padding:8px 12px;text-align:left;border-bottom:1px solid #e5e5ea;vertical-align:top}
.timeline th{background:#f9f9fb;font-weight:600;font-size:11px;text-transform:uppercase;letter-spacing:.04em;color:#636366}
.timeline tr:last-child td{border-bottom:none}
.timeline img{max-width:180px;max-height:160px;border-radius:6px;box-shadow:0 1px 3px rgba(0,0,0,.12);display:block;background:#fff}
.label{font-family:ui-monospace,monospace;font-weight:600;font-size:12px;display:inline-block;padding:2px 6px;background:#f9f9fb;border-radius:4px}
.stamp{font-size:11px;color:#636366;white-space:nowrap}
.missing{color:#c7c7cc;font-size:12px}
"""


if __name__ == "__main__":
    import sys
    label = sys.argv[1] if len(sys.argv) > 1 else None
    current, snap = build(label)
    public_index, public_history = write_public_redirects()
    print(f"wrote {current}")
    print(f"wrote {snap}")
    print(f"wrote {HERE / 'history.html'}")
    print(f"wrote {public_index}")
    print(f"wrote {public_history}")
