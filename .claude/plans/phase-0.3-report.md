# Phase 0.3 Report -- Backdrop Library

**Date:** 2026-04-14
**Iteration:** 62 (Phase 0.3)

## What changed

### Backdrop library -- 13 PNG files

Directory: `.claude/skills/apple-platform-guide/validation/backdrops/`

| File | Dimensions | Size |
|---|---|---|
| `sheet-backdrop-amber-gradient-light.png` | 2400x1800 | 260 KB |
| `sheet-backdrop-amber-gradient-dark.png` | 2400x1800 | 295 KB |
| `sheet-backdrop-amber-gradient-ios-light.png` | 1170x2532 | 145 KB |
| `sheet-backdrop-amber-gradient-ios-dark.png` | 1170x2532 | 160 KB |
| `sidebar-backdrop-amber-inbox-light.png` | 2400x1800 | 23 KB |
| `sidebar-backdrop-amber-inbox-dark.png` | 2400x1800 | 23 KB |
| `menu-backdrop-amber-document-light.png` | 2400x1800 | 23 KB |
| `menu-backdrop-amber-document-dark.png` | 2400x1800 | 23 KB |
| `home-screen-amber-wallpaper-light.png` | 1170x2532 | 140 KB |
| `home-screen-amber-wallpaper-dark.png` | 1170x2532 | 153 KB |
| `lock-screen-amber-dark.png` | 1170x2532 | 147 KB |
| `finder-mail-backdrop-light.png` | 2400x1800 | 22 KB |
| `finder-mail-backdrop-dark.png` | 2400x1800 | 22 KB |

The gradient backdrops (sheet + home-screen + lock-screen) use Amber palette
radial gradients and are large enough to provide meaningful hue variation for
the NSVisualEffectView blur kernel -- per Phase 0.1's finding that
high-saturation regions make backdrop bleed-through perceptible.

The structured-content backdrops (sidebar-inbox, menu-document, finder-mail)
use color-block approximations of UI rows / cards / columns. No text
rasterization (no font access from stdlib); row content is rendered as
palette-colored rectangles at the correct Fibonacci-golden spacing scale.

All PNGs written via pure Python stdlib (`struct` + `zlib`). No Pillow
dependency. No third-party libraries.

### Generator

`generate_backdrops.py` at the same directory is the canonical regeneration
script. `generate.cr` is the Crystal entry point that delegates to it.
Regeneration command:

```
python3 .claude/skills/apple-platform-guide/validation/backdrops/generate_backdrops.py
```

### worklist.json -- `backdrop` field

All 63 component rows now carry a `backdrop` field naming the image stem.
The capture harness resolves the full path by appending `-light.png` or
`-dark.png` based on `HIG_APPEARANCE` (and `-ios-` for iOS contexts).

Example rows:

| slug | backdrop |
|---|---|
| `sheets` | `sheet-backdrop-amber-gradient` |
| `alerts` | `sheet-backdrop-amber-gradient` |
| `context-menus` | `menu-backdrop-amber-document` |
| `sidebars` | `sidebar-backdrop-amber-inbox` |
| `column-views` | `finder-mail-backdrop` |
| `widgets` | `home-screen-amber-wallpaper` |
| `live-activities` | `lock-screen-amber` |
| `buttons` | `sheet-backdrop-amber-gradient` (default) |

### triage.py -- `backdrop` field on regeneration

`backdrop_for_slug(slug)` added before `main()`. The component row dict in
`main()` now includes `"backdrop": backdrop_for_slug(slug)`. Re-running
triage will emit the correct backdrop stem for all 63 component slugs.

### build_index.py -- Backdrop column

Added:
- `BACKDROPS` path constant pointing to `validation/backdrops/`.
- `render_backdrop_cell(row)` -- renders a 120x90 thumbnail of the backdrop's
  light variant (falls back to iOS light, then dark) with the stem name below.
- `render_row` now emits a fifth `<td>` with the backdrop cell.
- Table header gained a "Backdrop" column.
- CSS added `.backdrop-cell`, `img.backdrop-thumb`, `.backdrop-name` rules.

Dashboard written to:
- `validation/index.html` (current)
- `validation/index-phase-0.3-backdrops.html` (snapshot)

Backdrop thumbnails: 63 rows x 5 distinct stemss -- 63 backdrop cells appear
in the terminal-component table, each linking to the macOS-light PNG.

## Phase 0 complete

All three Phase 0 iterations have landed:
- 0.1: macOS CGWindowListCreateImage live-compositor capture path.
- 0.2: iOS XCUIScreen simulator capture path with UIWindow + backdrop layer.
- 0.3: Backdrop library + worklist schema + triage.py + build_index.py.

**USER REVIEW GATE.** Please review the 13 backdrop PNGs at
`.claude/skills/apple-platform-guide/validation/backdrops/` before
approving Phase 1-2 kickoff. The key question: do the gradient backdrops
have enough hue variation (especially the radial peach-edge in light, and
the plum-center in dark) that NSVisualEffectView / UIVisualEffectView blur
will produce a visible tint shift when glass components are rendered over them?

If the color saturation looks weak, the generator knobs to adjust are
`radius_scale` (controls how far the gradient extends) and the `edge_color`
in `make_sheet_gradient`. Re-run `python3 generate_backdrops.py` after any
change.

## Next phase

Phase 1 (color audit + spacing audit) begins after backdrop approval.
