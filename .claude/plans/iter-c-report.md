# Iter C: Layout Bug Fix Report

**Date:** 2026-04-15
**Pilot slugs re-captured:** sheets, buttons, sidebars (6 macOS PNGs — each appearance)

---

## Root Cause Analysis

### Bug 1: All captures blank-transparent (highest severity)

Prior iterations used `objc_create_capture_window` + `CGWindowListCreateImage` to capture screenshots. This path requires Screen Recording TCC permission. In the agent execution environment (non-interactive terminal process), Screen Recording is not granted. `CGWindowListCreateImage` returns a correctly-sized PNG containing fully transparent RGBA (0,0,0,0) pixels — it does NOT return a 1x1 image as the code comments suggested. The spec accepted these transparent files because they passed the size > 1000 bytes check.

**Fix:** Added `objc_capture_view_offscreen` to `window_helper.m` using `bitmapImageRepForCachingDisplayInRect:toBitmapImageRep:`. This path rasterizes the view hierarchy directly into a bitmap context — no TCC permission required. NSVisualEffectView renders as a solid tinted fill (no live backdrop blur), which is acceptable for layout validation. The `hig_showcase.cr` capture path now calls `objc_capture_view_offscreen` unconditionally for the automated spec.

### Bug 2: Scene panels not filling window width

With `NSStackView GravityAreas` distribution (the default), arranged subviews are sized to their intrinsic content width. A `>= min_w` constraint at priority 500 was added to `apply_common_properties` but NSStackView GravityAreas did not expand children beyond their intrinsic size because the constraint priority (500) was insufficient to override NSStackView's internal sizing.

**Fix:** Changed scene body_row HStacks to use `Alignment::Fill` (which triggers `setDistribution:0` = NSStackViewDistributionFill on the NSStackView) AND added `minimum_width = maximum_width = 1200` (exact-width equality constraint at priority 999) to both the top_bar and body_row in each scene. The exact pin gives the HStack a definite 1200pt frame; NSStackViewDistributionFill then expands the last arranged subview (right panel/message list/chart card) to fill remaining space.

Affected scenes: SettingsScene, InboxScene, DashboardScene, ChartScene.

### Bug 3: Sheet TextFields clipping to 3-4 characters

The original `sheets` case arm built a VStack alternating between Label and TextField children with default `Alignment::Center`. Each TextField was sized to its intrinsic content width (~60pt) and centered.

**Fix:** Restructured the sheet form to use HStack form rows (label 80pt exact-pin + TextField `minimum_width = 360`). The TextField `>= 360pt` constraint gives it adequate width within the row.

---

## Visual Verification Results

| Capture | Layout | Role colors | Text | Status |
|---|---|---|---|---|
| buttons-macos-light | Settings scene, 11 button variants visible with backdrop gradient | Default=blue, Destructive=red, Cancel=semibold blue | All labels readable | PASS |
| buttons-macos-dark | Same layout, dark background | All roles correct | White text legible on dark | PASS |
| sidebars-macos-light | 2-pane Inbox, message list extends to right edge, no orphaned dots | Gold Amber indicators inline with message rows | All rows readable | PASS |
| sidebars-macos-dark | Same layout, dark background | Gold tint visible | White text legible | PASS |
| sheets-macos-light | Dashboard chrome + Sheet centered, TextFields show full placeholder text | Cancel=blue, Conjure=blue | Full placeholder visible | PASS |
| sheets-macos-dark | Same layout, dark mode Sheet card with dark gradient backdrop | Same role colors | White text on dark card | PASS |

---

## Files Changed (Iter C)

- `samples/cross_platform/macos_host/window_helper.m` — added `objc_capture_view_offscreen` using offscreen rasterization path (no TCC required)
- `samples/cross_platform/macos_host/hig_showcase.cr` — switched capture call to `objc_capture_view_offscreen`, declared new lib function
- `src/ui/renderers/appkit_renderer.cr` — added `setDistribution:0` for HStack `Alignment::Fill`; re-enabled size constraints in `apply_common_properties`
- `src/ui/validation_scenes/settings_scene.cr` — exact width pins (min=max=1200) on body_row and top_bar; body_row uses `Alignment::Fill`
- `src/ui/validation_scenes/inbox_scene.cr` — same pattern across all focal_position branches
- `src/ui/validation_scenes/dashboard_scene.cr` — same pattern
- `src/ui/validation_scenes/chart_scene.cr` — same pattern
- `src/ui/native/objc_bridge.m` — added `objc_constrain_minimum_width` (>= constraint at priority 500) for general-purpose minimum width flooring
