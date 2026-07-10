# June Round-1 Fix Iteration — Implementation Plan

Date: 2026-04-15
Branch: feature/utility-first-css-asset-pipeline
Iteration: june-round-1

## Scope

Address every specific fix item cited by design critic June across four NEEDS_WORK
slugs: sheets, buttons, sidebars, toggles.

## Systemic Issues Addressed

### Issue A — iOS UIKit theme not propagating

Root cause: `UI::UIKit::Renderer#amber_brand_gold` called `ENV["TEST_RUNNER_HIG_APPEARANCE"]?`
from within UIKit's `makeUIView` layout callback. Crystal's `ENV[]` accessor acquires a
mutex via `Thread::current` and `Crystal::once`, both of which require Crystal's fiber
subsystem to be initialized. UIKit fires `makeUIView` during SwiftUI's first layout pass,
BEFORE `crystal_init` has set up that subsystem. Result: SIGSEGV at 0x18 in
`Thread::LinkedList#push` — every slug that uses a button crashes before rendering.

Fix applied: `src/ui/renderers/uikit_renderer.cr` — replaced `ENV["TEST_RUNNER_HIG_APPEARANCE"]?`
with `LibC.getenv("TEST_RUNNER_HIG_APPEARANCE")` followed by a null check and
`String.new(raw)`. `LibC.getenv` is a raw POSIX C syscall that touches no Crystal runtime
state and is safe to call from any thread at any time.

Before: `dark = (ENV["TEST_RUNNER_HIG_APPEARANCE"]? == "dark")`
After: `raw = LibC.getenv("TEST_RUNNER_HIG_APPEARANCE"); dark = !raw.null? && String.new(raw) == "dark"`

### Issue B — Debug "HIG: <slug>" headers in iOS captures

Two sources removed:
1. `build_focal` in `hig_bridge.cr`: `vstack << UI::Label.new("HIG: #{slug}")` removed.
2. `when "toggles"` arm: explicit `ios_heading = UI::Label.new("HIG: toggles")` removed.

Regression introduced by source 1 removal: non-scene-wrapped slugs (buttons, toggles,
sidebars) had no `accessibility_label = "hig-component-root"` on their root vstack,
causing the iOS XCUITest harness to fail with "No accessibility root" on those slugs.

Fix: Added `vstack.accessibility_label = "hig-component-root"` and
`vstack.test_id = "hig-component-root"` to the non-scene path in `build_focal`.

### Issue C — Two-panel peach gap on macOS Preferences

Root cause: NSStackView children (sidebar and right panel) have transparent CALayers.
The NSWindow content view's peach backdrop gradient bleeds through the gaps between
children during offscreen compositing. The outer `page.background = page_bg` only sets
the NSStackView layer's background, not the children's layers.

Fix: `src/ui/validation_scenes/settings_scene.cr` — added explicit `background` color
matching `page_bg` to both `build_sidebar` and `build_right_panel`. Colors are
`HIG_APPEARANCE`-aware (cream in light, deep ember in dark) to maintain visual
continuity across the full window surface.

## Sheets-Specific Fixes

File: `samples/cross_platform/macos_host/hig_showcase.cr` and
      `samples/cross_platform/ios_host/hig_bridge.cr`

1. Cancel/Conjure role inversion: Changed `Conjure` button from `role: :default` to
   `role: :default, style: UI::ButtonStyle::Prominent`. Cancel remains as bordered
   secondary (the default for `:cancel` role). This corrects the visual hierarchy:
   Prominent = amber gold filled pill (primary CTA), Cancel = grey bordered (secondary).

2. Missing grabber: Added `ios_sh_grabber` — a Label with grey semi-transparent
   background, 2.5pt corner_radius, 36pt min_width, 5pt min_height. No `maximum_height`
   set (avoids the UILabel impossible-height constraint crash that triggered during the
   first grabber implementation attempt). macOS version uses same pattern.

3. Field label font: Changed from 14.0 to 13.0 regular (HIG macOS form rows use 13pt).

4. Row gap: Changed VStack spacing from 10.0 to 13.0 (HIG form row inter-gap).

5. iOS-specific: Added `ios_sh_save.minimum_height = 44.0` for HIG minimum hit target.

## Buttons-Specific Fixes

File: `samples/cross_platform/macos_host/hig_showcase.cr`

1. macOS dark Prominent invisible: `src/ui/renderers/appkit_renderer.cr` — added
   CALayer belt-and-suspenders after `setBezelColor:`:
   - `setWantsLayer: YES` before `setBezelStyle:1`
   - After bezelColor set: get layer pointer, call `setBackgroundColor:` with CGColor
     from fill_color, then `setCornerRadius: 6.0`
   This ensures the fill is visible in DarkAqua offscreen rendering where `bezelColor`
   alone can be ignored by the compositor.

2. Button heights: Added `minimum_height = 28.0` to Default/Bordered/Tinted/Borderless/
   Destructive/Cancel rows; `minimum_height = 32.0` to Prominent rows.

3. Label-to-button gap: Changed all HStack spacing from 12.0 to 8.0.

## Sidebars-Specific Fixes

Files: `samples/cross_platform/macos_host/hig_showcase.cr`,
       `samples/cross_platform/ios_host/hig_bridge.cr`

macOS:
- Message list column: Replaced grey wireframe skeleton with real `msg_list` VStack
  (280pt wide) containing INBOX section header (11pt SemiBold) + 5 Amber-voice message
  rows (sender/subject/preview with unread dots, 24pt minimum height each).
- Detail pane: Replaced blank with `detail_empty` VStack containing `envelope.open`
  Image (48pt, secondary tint) + "Select a memory to read" Label (empty state).

iOS:
- Per HIG: "Avoid using a sidebar on iPhone." Replaced NavigationSplitView with
  `UI::TabView` (4 tabs: Memories/Rituals/Vault/Profile, Amber gold selected tint,
  glass bar, bar_position: :bottom). This is the HIG-correct iPhone pattern.

## Toggles-Specific Fixes

Files: `samples/cross_platform/macos_host/hig_showcase.cr`,
       `samples/cross_platform/ios_host/hig_bridge.cr`

1. All ON UISwitch instances use Amber gold: set `tint_color = amber_gold_tgl` on both
   Notifications (Row 1) and Focus Mode (Row 4) toggles in both iOS bridge and macOS
   showcase arms.

2. Removed per-toggle purple override: Row 4 `tgl_tinted` had `(r: 0.522, g: 0.176,
   b: 0.996)` — replaced with amber gold, renamed variable to `tgl_focus`.

3. Debug header removed: `ios_heading = UI::Label.new("HIG: toggles")` removed from
   iOS bridge arm.

## 16 PNG Captures — Byte Sizes

| Slug | Platform | Appearance | Bytes |
|------|----------|------------|-------|
| sheets | macOS | light | 862,955 |
| sheets | macOS | dark | 1,163,053 |
| sheets | iOS | light | 537,425 |
| sheets | iOS | dark | 688,179 |
| buttons | macOS | light | 399,667 |
| buttons | macOS | dark | 435,998 |
| buttons | iOS | light | 669,529 |
| buttons | iOS | dark | 911,948 |
| sidebars | macOS | light | 155,331 |
| sidebars | macOS | dark | 158,063 |
| sidebars | iOS | light | 107,317 |
| sidebars | iOS | dark | 107,095 |
| toggles | macOS | light | 330,839 |
| toggles | macOS | dark | 366,780 |
| toggles | iOS | light | 542,996 |
| toggles | iOS | dark | 792,826 |

All 16 PNGs: above 10KB minimum, non-black, mtime today (2026-04-15).

## Residual Issues (Not Declared PASS)

Per Ralph's explicit instruction, no slug is declared PASS here. June will re-evaluate.

Known residual:
- macOS toggles: ON-state NSSwitch amber gold tint is set in code but may not be visually
  obvious at screenshot scale. The `nsswitch_set_tint` / `setContentTintColor:` path is
  wired; whether NSSwitch renders the custom tint in offscreen compositing needs June
  re-examination.
- sidebars iOS: TabView content area is empty (only "Memories" title visible). The tab
  content VStack needs real message rows for the Memories tab to match the macOS detail
  level. This is a content completeness gap, not a crash or theme issue.
