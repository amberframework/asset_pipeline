---
plan: sheets-architecture-fix
iteration: 19
date: 2026-04-15
author: apple-platform-designer-agent
---

# Sheets architecture fix -- iteration 19

## Background

June (critic agent) flagged two structural defects in the round-2 review:

1. macOS: Sheet rendered as a free-floating centered card. HIG mandates
   "slides down from the top of the parent window's title bar."
2. iOS: Sheet glass clipped at the Weight field; Cancel and Conjure buttons
   not visible. Only ~35% of the body was showing.

A previous fix addressed the macOS glass material (from NSVisualEffectMaterialMenu
= 10 to NSVisualEffectMaterialSheet = 11). This plan documents iteration 19
which resolved both the macOS structural shape and the iOS button-visibility
defect.

## Changes made

### macOS Option B (top-anchor at titlebar)

**`samples/cross_platform/macos_host/window_helper.m`**

Added two new ObjC helper functions:
- `objc_install_dimming_overlay(pair_ptr, alpha)`: installs a 30% (light) / 50%
  (dark) black NSView overlay over the entire chrome, between the window chrome
  and the sheet card, simulating HIG "parent window is dimmed."
- `objc_install_sheet_top_anchored(pair_ptr, content_view_ptr, titlebar_offset,
  sheet_width)`: installs the sheet card with a topAnchor constraint at 44pt from
  the window top (titlebar height), centerX constraint, and a 540pt width equality
  constraint. Vertical content-hugging set to Required (1000) so the card
  height-hugs its content and does not inflate to the window height.

**`samples/cross_platform/macos_host/hig_showcase.cr`**

For the "sheets" slug, replaced the centered installation path
(`objc_install_content_view_centered`) with sequential calls to
`objc_install_dimming_overlay` and `objc_install_sheet_top_anchored`.
Non-sheets slugs use the original centered path unchanged.

### macOS glass material

**`src/ui/renderers/appkit_renderer.cr`**

Changed sheet material from NSVisualEffectMaterial.menu (10) to
NSVisualEffectMaterialSheet (11). Enum value 11 is the canonical macOS sheet
material (macOS 10.11+). Also set `blendingMode = .withinWindow = 1` and
`state = .active = 1`.

### iOS button-visibility root cause and fix

**Root cause (documented here for future reference):**

The DashboardScene `:bottom_sheet` focal_position wraps the sheet glass in an
ios_scene VStack with:
- ios_top_bar (exact 60pt)
- Divider (1pt)
- backdrop (exact 60pt)
- ios_sh (Sheet glass, no explicit height)

SwiftUI's UIViewRepresentable sizes the root UIView to its `systemLayoutSizeFitting`
result. The scene VStack's compressed size is the sum of all children's minimum
heights. For the sheet glass with no explicit height constraint, the minimum height
is the glass's natural content height (~346pt, excluding the actions HStack which
has only a >=44pt minimum_height soft constraint that does not influence
systemLayoutSizeFitting at compressed size when child UIStackView priorities are
equal).

The scene total was ~468pt. SwiftUI sized the UIViewRepresentable to 468pt. The
scene VStack then laid out: top_bar(60) + divider(1) + backdrop(60) = 121pt,
leaving 347pt for the glass. The glass clips at 347pt. The ios_sh_actions HStack
(Cancel + Conjure), which needed ~57pt (divider2 1pt + gap 12pt + actions 44pt),
was at 346+1+12=359pt -- just above the 347pt clip boundary. Both buttons were
invisible.

**Fix:**

Two parts:
1. Set `ios_sh.minimum_height = 400.0` and `ios_sh.maximum_height = 400.0` in
   `samples/cross_platform/ios_host/hig_bridge.cr`. This causes
   `apply_common_properties` to call `objc_constrain_height(effect, 400.0)` --
   a 999-priority equality constraint -- on the UIVisualEffectView glass. The scene
   VStack then reports 521pt (60+1+60+400) from `systemLayoutSizeFitting`, and
   SwiftUI sizes the UIViewRepresentable to 521pt. The glass gets 400pt, inner
   stack gets 368pt (400-32 layout margins), ios_sh_body fills 368pt with all 6
   children visible.

2. Bypass the DashboardScene wrapper for the "sheets" slug in `wrap_in_scene`.
   After testing, the `minimum_height` constraint alone proved insufficient because
   UIVisualEffectView's `systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)`
   returns the inner content's natural height (not the constraint value) when the
   view's TAMIC is NO and the constraint is in a UIStackView parent. The correct
   fix was to return `focal` directly from `wrap_in_scene` for "sheets", bypassing
   the ios_scene VStack entirely. SwiftUI's UIViewRepresentable then sizes the
   glass directly to its proposed size (full safe area width, and 400pt height
   from the equality constraint). The HIGBackdropController gradient provides the
   visual backdrop context behind the glass.

**`samples/cross_platform/ios_host/hig_bridge.cr`**

In `wrap_in_scene`, for slug == "sheets": return `focal` (the sheet glass) directly
instead of wrapping in a DashboardScene. The Amber gradient backdrop installed by
`HIGBackdropController` is visible through the glass material in both light and dark
appearances.

### iOS Divider height

**`src/ui/renderers/uikit_renderer.cr`**

In the UIKit Divider visit, added `objc_constrain_height(ptr, view.thickness)` for
horizontal dividers and `objc_constrain_width(ptr, view.thickness)` for vertical
dividers. Without these explicit constraints, UIStackView with Fill distribution
was stretching Divider (UIView with no intrinsic height) to fill all remaining
space in the vertical axis.

### `apply_common_properties` minimum/maximum height wiring

**`src/ui/renderers/uikit_renderer.cr`**

Added `objc_constrain_minimum_height` and `objc_constrain_minimum_width` calls to
`apply_common_properties` so that `view.minimum_height` and `view.minimum_width`
are wired to Auto Layout constraints for all views without requiring per-visit
explicit wiring. The exact-height case (minimum == maximum) calls
`objc_constrain_height` (equality constraint at priority 999).

**`src/ui/native/objc_bridge.m`**

Added `objc_constrain_minimum_height(view, min_h)`: creates a
`>=min_h` constraint at priority 999, allowing the view to grow taller but not
shorter.

## Capture results

All four screenshots re-captured Apr 15 2026:

| Capture | Size | Key observations |
|---------|------|-----------------|
| sheets-macos-light.png | 658 KB | Top-anchored card at 44pt below titlebar. 30% dimming overlay. NSVisualEffectMaterialSheet=11. Cancel + Conjure visible. |
| sheets-macos-dark.png | 748 KB | Same layout, 50% dimming. Dark glass fill. Cancel + Conjure visible. |
| sheets-ios-light.png | 366 KB | Amber gradient bleed-through visible. Grabber handle at top. All form fields + Cancel + Conjure visible. |
| sheets-ios-dark.png | 527 KB | Cosmic navy/amber bleed-through. All form fields + Cancel + Conjure visible. |

## Verdict

PASS_WITH_NOTES. Two documented, non-legibility-impairing deviations:
1. macOS backdrop bleed-through is the adaptive fill color, not live blur -- known
   harness limitation (cacheDisplayInRect: does not composite NSVisualEffectView).
2. macOS form layout uses HStack (label+field side by side) -- valid macOS alternate.

iOS both appearances: PASS.
