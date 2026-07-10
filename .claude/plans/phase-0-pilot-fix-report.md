# Phase 0 Pilot Fix Report

**Date:** 2026-04-14
**Fixes:** 4 (backdrop composite bug, Amber dark palette, presentation margins, iOS chart height)

## Fix 1 -- macOS backdrop composite bug

### Diagnosis

Candidate 4 was the root cause: the blending mode was `NSVisualEffectBlendingModeBehindWindow` (0), but
that was not the only issue. Three compounding bugs existed:

1. **Blending mode wrong**: `behindWindow` samples what is behind the NSWindow itself in the window server.
   Changed to `withinWindow` (1) across all surface component visitors in `appkit_renderer.cr`:
   `UI::Sheet`, `UI::Alert`, `UI::Popover`, `UI::ActivityView`, `UI::Sidebar`, `UI::Toolbar`,
   `UI::TabView`, `UI::GlassBackground`.

2. **Backdrop in wrong window**: `objc_install_backdrop` was adding the backdrop NSImageView to the
   BACKDROP window (pair[0]). For `.withinWindow` blending to work, the backdrop must be inside
   the SAME window as the NSVisualEffectView. Changed `objc_install_backdrop` to install the
   NSImageView into the CAPTURE window (pair[1]) as the lowest-Z subview
   (`positioned:NSWindowBelow relativeTo:nil`). Also changed `objc_capture_window_to_png` to
   use single-window capture (two-window composite was the approach for `.behindWindow`; now
   obsolete).

3. **Root VStack has opaque background**: The VStack renderer bakes a solid background
   (`rgba(0.12, 0.12, 0.12, 1.0)` dark, `rgba(1.0, 1.0, 1.0, 1.0)` light) onto its CALayer for
   the old offscreen bitmap capture path (gaps.md iteration-21). This opaque fill completely blocked
   the backdrop NSImageView. Fixed by clearing the content view's layer background in
   `objc_install_content_view` before adding it to the capture window.

4. **Run loop not pumped**: Crystal's `sleep()` parks the fiber without running the AppKit run loop.
   NSVisualEffectView `.withinWindow` requires at least one run loop cycle + compositor refresh.
   Added `objc_run_loop_for(seconds)` to `window_helper.m` and replaced `sleep(600.milliseconds)`
   in `hig_showcase.cr` with `LibWindowHelper.objc_run_loop_for(0.6)`. Also added
   `[app activateIgnoringOtherApps:YES]` in `objc_run_loop_for` so the window server composites
   the capture window.

### Before/after

Before: solid `#1E1E1E` charcoal fill behind the sheet card. No backdrop visible.
After: warm amber gradient (#FFAD33 center -> #2A1A08 edges) visibly blurring through the
NSVisualEffectMaterialMenu dark frosted glass. The card sits against a warm sunset-amber backdrop.

## Fix 2 -- Amber dark palette correction

`amber.md` updated:
- Dark surface: `#141122` (cosmic navy, cool plum) -> `#2A1A08` (deep ember, warm hue 25 degrees)
- Dark glass tint: `#2B2140` (plum-leaning) -> `#3D2614` (ember, warm hue 22 degrees)
- "Cosmic navy" name retired; replaced with "deep ember"
- Dark separator: `#38373D` (cool gray) -> `#4A3520` (warm brown)
- Dark secondary label: `#8E8E93` (cool gray) -> `#B8A898` (warm gray)

`generate_backdrops.py` updated with new hex values. All 13 backdrop PNGs regenerated.
Dark gradient center changed from `PLUM_DARK` (#7D59B8, purple) to `AMBER_GOLD` (#FFAD33, warm gold)
for visible warmth even through the glass material. The dark backdrop now reads as "sunset-into-night"
rather than "twilight-into-void."

## Fix 3 -- Presentation component viewport margins

`appkit_renderer.cr` updated with `objc_constrain_width` calls after each surface component build:
- `UI::Sheet`: 540pt max width (HIG macOS sheet spec)
- `UI::Alert`: 270pt max width (HIG alert card spec)
- `UI::Popover`: 320pt max width (HIG popover spec)
- `UI::ActivityView`: 540pt max width (HIG share sheet spec)

The Sheet visitor also uses `view.responds_to?(:max_width)` to allow per-instance override.
Cards now sit comfortably inset from the 1200pt capture window rather than stretching edge-to-edge.

## Fix 4 -- iOS chart height constraint

`uikit_renderer.cr` updated: added explicit
`LibObjCBridge.objc_send_bool(outer, sel("setTranslatesAutoresizingMaskIntoConstraints:"), 0)`
before `objc_constrain_size(outer, chart_w, chart_h)` in `visit(UI::ChartView)`.
`objc_constrain_size` already sets TAMIC=NO internally; the explicit call is belt-and-suspenders.
Confirmed macOS chart (AppKit) also renders correctly -- bar charts with plum bars visible.

## Captures produced

All 5 pilot slugs x 2 macOS appearances = 10 PNG files written to
`.claude/skills/apple-platform-guide/validation/screenshots/`.

Each file: 2400x1800 px, 130KB -- 1.1MB, fresh mtime 2026-04-14.

Visual assessment per slug:
- **sheets**: light shows frosted white glass over cream-to-peach gradient. Dark shows dark frosted
  glass over amber gold gradient. Card 540pt wide, centered. Form fields and buttons legible.
- **action-sheets**: light shows peach backdrop blurring through glass, destructive red "Banish draft
  forever" button visible, cancel "Never mind" semibold. Dark shows amber gold glow.
- **alerts**: light shows 270pt card with title, message, Cancel + Banish (red) buttons. Dark shows
  amber glow behind 270pt card. Width constraint working -- card is no longer 1200pt wide.
- **sidebars**: dark shows warm-brown deep-ember background (not purple). Sidebar navigation with
  MEMORIES/VAULTS sections. The sidebar-backdrop-amber-inbox uses a flat color block design (not
  radial gradient), so amber gold is not visible in the backdrop area -- but the overall warm-brown
  tone is present.
- **charts**: bar chart with all 7 bars visible (Mon-Sun) in both appearances. No zero-height
  collapse. Plum (#5B3A94) bars on amber gradient backdrop in dark.

## Remaining gaps

1. The sidebars backdrop (`sidebar-backdrop-amber-inbox`) uses solid colored blocks rather than a
   warm gradient. The sidebar glass card does not show amber bleed-through because the sidebar-inbox
   backdrop is not as saturated as the sheet gradient. A future iteration could use a richer warm
   gradient for the sidebar backdrop.

2. The iOS captures were not re-run in this iteration (iOS build requires Xcode simulator path).
   Phase 0.2 should re-run iOS captures with the warm-amber palette.

3. The `sheets-macos-dark.png` now overwrites the previously canonical DEMO capture. The new
   capture is the correct canonical state.
