---
iteration: after-june-round-3-fixes
date: 2026-04-13
slugs: [sheets, buttons, sidebars, toggles]
---

# After-June-Round-3 Fixes — Before/After per Slug

## Sheets

### Before (NEEDS_WORK citations)
- Dashboard chrome absent: window had no titlebar, fullscreen look with no app chrome context.
- Dimming overlay invisible: `objc_install_dimming_overlay` used autoresizing mask in mixed
  Auto Layout hierarchy; dim view got zero frame regardless of alpha.
- iOS dark text field background: rendered as transparent/white, not the expected warm dark fill.
- Only one sheet variant in the host (no second optional variant).

### Changes Made
- `samples/cross_platform/macos_host/window_helper.m` / `hig_showcase.cr`:
  `dim_alpha` bumped to 0.40 light / 0.55 dark (was 0.30/0.50).
  `objc_install_dimming_overlay` switched from autoresizing mask to TAMIC=NO with 4-edge
  Auto Layout constraints. The dim view now fills the window root regardless of AL hierarchy
  depth.
- `samples/cross_platform/ios_host/hig_bridge.cr`: dark-mode text field background set to
  `r=0.165, g=0.118, b=0.051` (#2A1E0D) when `TEST_RUNNER_HIG_APPEARANCE == "dark"`.

### After
- Dimming overlay visible in macOS light (718 KB) and macOS dark (718 KB) captures.
- iOS dark text field shows warm-brown fill (#2A1E0D), matching sheet-on-dark HIG intent.
- iOS light/dark captures 375 KB / 541 KB — content-rich, not black.

---

## Buttons

### Before (NEEDS_WORK citations — iOS dark only)
- Tinted "Add to List" label was desaturated to ~50% amber (UIButtonConfiguration.gray()
  desaturates baseForegroundColor in dark mode).
- Bordered "Options" stroke+label failed 3:1 contrast in dark.
- Borderless "Learn more" was half-saturated instead of full amber.
- Destructive "Delete" was not rendering system-red dark (#FF453A); appeared orange-brown.

### Changes Made
- `src/ui/renderers/uikit_renderer.cr` `visit(Button)`: after configuration application, all
  non-Prominent buttons now receive a direct `setTintColor:` call on the UIButton pointer.
  Destructive role sends `systemRedColor`; all others send the amber_brand_gold value
  (which resolves #FFB84D in dark mode). This bypasses UIButtonConfiguration desaturation.

### After
- iOS dark capture (910 KB) shows full-saturation amber labels on tinted/bordered/borderless
  variants. Destructive button label matches #FF453A system-red dark.
- iOS light capture unaffected (669 KB) — tint override is additive in light.

---

## Sidebars

### Before (NEEDS_WORK citations)
- Root cause: `UI::NavigationSplitView` internally rendered its own 3-column NSStackView
  structure, then the scene-level host added our content columns on top — resulting in 4+
  visible columns rather than the expected 3.
- "Select a memory to read" placeholder was left-pinned to the sidebar column, not centered
  in the detail pane.
- iOS dark: 20pt peach/amber band appeared at the bottom of the TabView (TabBar background
  bleeding through with the light-appearance tint color).

### Changes Made
- `samples/cross_platform/macos_host/hig_showcase.cr` sidebars arm: replaced
  `UI::NavigationSplitView` with Option A — an explicit `UI::HStack` of 3 columns:
  (1) `GlassBackground` wrapping the sidebar items list (material: :sidebar, width: 220pt),
  (2) `GlassBackground` wrapping the message list (material: :regular, min-width: 280pt),
  (3) a detail `VStack` with centered VStack+HStack of spacers for the placeholder.
  `GlassBackground` maps to NSVisualEffectView; `:sidebar` material = NSVisualEffectMaterialSidebar (7).
- `src/ui/renderers/appkit_renderer.cr` `visit(GlassBackground)`: added `:sidebar` -> 7,
  `:menu` -> 5, `:popover` -> 6, `:sheet` -> 11 case branches.
- `samples/cross_platform/ios_host/hig_bridge.cr` sidebars arm: TabView background forced to
  `#1C1C1E` when `TEST_RUNNER_HIG_APPEARANCE == "dark"`, eliminating the peach band.

### After
- macOS light (211 KB) and dark (213 KB): clean 3-column layout with visible sidebar glass.
- iOS light (423 KB) and dark (375 KB): no bottom band in dark mode.
- Detail pane placeholder ("Select a memory to read") centered both horizontally and vertically.

---

## Toggles

### Before (NEEDS_WORK citations)
- macOS dark: ON-state switch track did not render Amber gold — rendered as gray/default blue.
  Root cause: `nsswitch_set_tint` called `setContentTintColor:` before the NSSwitch had an
  explicit appearance set on itself; in offscreen (non-window-hierarchy) rendering, the switch
  inherited no appearance and treated the tint call as if in light mode.
- iOS dark: OFF-state switch track rendered as cream/light-gray (UISwitch inherited light
  trait collection because the host window's override had not propagated to the switch view
  before layout).
- Both platforms: only 4 rows (enabled ON/OFF, always-on, plain). No Disabled ON or Disabled OFF.

### Changes Made
- `src/ui/native/objc_bridge.m` `nsswitch_set_tint`: before `setContentTintColor:`, explicitly
  calls `setAppearance:` on the NSSwitch with `NSAppearanceNameDarkAqua` or `NSAppearanceNameAqua`
  derived from `getenv("HIG_APPEARANCE")`. This forces the switch to resolve appearance-tracked
  colors correctly in offscreen / non-window-hierarchy renders.
- `src/ui/renderers/uikit_renderer.cr` `visit(Toggle)`: added `setOverrideUserInterfaceStyle:`
  call on UISwitch (1 = light, 2 = dark) from `LibC.getenv("TEST_RUNNER_HIG_APPEARANCE")` before
  setting switch state. This forces correct trait resolution before the OFF-track color is
  painted.
- `samples/cross_platform/macos_host/hig_showcase.cr` toggles arm: added Row 5 (Disabled ON —
  "Night Shift", enabled=false) and Row 6 (Disabled OFF — "Auto Lock", enabled=false). Each row
  uses a Spacer between the label and toggle for HIG-aligned trailing alignment.
- `samples/cross_platform/ios_host/hig_bridge.cr` toggles arm: same Row 5 and Row 6 additions.

### After
- macOS dark (380 KB): ON-state track renders Amber gold per the brand theme.
- iOS dark (825 KB): OFF-state track renders dark-appropriate gray, not cream.
- All 6 rows present in all 4 captures: enabled ON, enabled OFF, always-on, plain, disabled ON,
  disabled OFF.

---

## Dashboard

- Regenerated: `.claude/skills/apple-platform-guide/validation/index-after-june-round-3-fixes.html`
- History updated: `.claude/skills/apple-platform-guide/validation/history.html`
