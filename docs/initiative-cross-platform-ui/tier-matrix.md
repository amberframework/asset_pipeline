# Tier Matrix — Cross-Platform UI

This document classifies every widget in `src/ui/views/` into Tier 1
(Brand-universal), Tier 2 (Platform default), or Tier 3
(Platform-only). It is the canonical source for the tier
classification; the Phase 4 implementer populated it from the
proposal in `phases/phase-04-platform-tier-gating/implementation.md`,
reconciled against Codex Checkpoint 1 feedback.

See the Tier model section of [MASTER_PLAN.md](MASTER_PLAN.md) for the
definitions.

## How to use this matrix

* New widget? Pick a tier and add it here in the same commit that adds
  the source file. Unclassified widgets are a build-time TODO.
* Tier 3 widget needs a fallback? Add a `*WithWebFallback` row.
* Found a widget here that isn't in `src/ui/views/`? File a bug — the
  matrix is stale.
* The `AssetPipeline::Platform.requires(:ios)` macro is the app-author
  way to gate non-widget code by platform; see
  `src/asset_pipeline/platform.cr`.

## Tier 1 — Brand-universal (17 widgets)

These have no platform-idiomatic chrome — they are visual primitives
or layout. They require no gating and look identical (modulo
platform unit conventions) on every target.

| Widget | Source file |
|---|---|
| Capsule | `src/ui/views/capsule.cr` |
| Card | `src/ui/views/card.cr` |
| Circle | `src/ui/views/circle.cr` |
| ColumnView | `src/ui/views/column_view.cr` |
| Divider | `src/ui/views/divider.cr` |
| Grid | `src/ui/views/grid.cr` |
| HStack | `src/ui/views/hstack.cr` |
| Image | `src/ui/views/image.cr` |
| Label | `src/ui/views/label.cr` |
| Panel | `src/ui/views/panel.cr` |
| PathView | `src/ui/views/path_view.cr` |
| Rectangle | `src/ui/views/rectangle.cr` |
| RoundedRectangle | `src/ui/views/rounded_rectangle.cr` |
| Spacer | `src/ui/views/spacer.cr` |
| Surface | `src/ui/views/surface.cr` |
| VStack | `src/ui/views/vstack.cr` |
| ZStack | `src/ui/views/zstack.cr` |

## Tier 2 — Platform default (55 widgets)

These have a meaningful semantic on every platform; their visual
treatment shifts based on the renderer. No gating; Phase 3's SwiftUI
bridge gives them their Apple polish.

| Widget | Source file | SwiftUI facade (Phase 3) | Notes |
|---|---|---|---|
| ActivityIndicator | `src/ui/views/activity_indicator.cr` | — | |
| ActivityRing | `src/ui/views/activity_ring.cr` | — | |
| ActivityRings | `src/ui/views/activity_rings.cr` | — | |
| ActivityView | `src/ui/views/activity_view.cr` | — | Shares; UIActivityViewController on iOS, Web Share / copy on web. |
| Alert | `src/ui/views/alert.cr` | — | |
| AsyncImage | `src/ui/views/async_image.cr` | — | |
| Button | `src/ui/views/button.cr` | Yes | |
| Canvas | `src/ui/views/canvas.cr` | — | |
| ChartView | `src/ui/views/chart_view.cr` | — | |
| Checkbox | `src/ui/views/checkbox.cr` | Yes | |
| ColorPicker | `src/ui/views/color_picker.cr` | Yes | `<input type="color">` on web. |
| ComboBox | `src/ui/views/combo_box.cr` | — | |
| ConfirmationDialog | `src/ui/views/confirmation_dialog.cr` | Yes | Generic modal; ActionSheetWithWebFallback delegates here on macOS / Android. |
| DatePicker | `src/ui/views/date_picker.cr` | Yes | `<input type="date">` on web. |
| DisclosureGroup | `src/ui/views/disclosure_group.cr` | — | |
| Form | `src/ui/views/form.cr` | Yes | |
| Gauge | `src/ui/views/gauge.cr` | — | |
| GlassBackground | `src/ui/views/glass_background.cr` | Yes | Degrades to standard backdrop on platforms without the glass material. |
| IconButton | `src/ui/views/icon_button.cr` | Yes | |
| ImageWell | `src/ui/views/image_well.cr` | — | |
| LinkButton | `src/ui/views/link_button.cr` | Yes | |
| ListView | `src/ui/views/list_view.cr` | Yes | |
| MapView | `src/ui/views/map_view.cr` | — | MapKit on Apple; Leaflet/Google embed on web. |
| MenuButton | `src/ui/views/menu_button.cr` | Yes | Pop-up / pull-down menu. |
| NavigationLink | `src/ui/views/navigation_link.cr` | Yes | |
| NavigationSplitView | `src/ui/views/navigation_split_view.cr` | Yes | |
| NavigationStack | `src/ui/views/navigation_stack.cr` | Yes | |
| OutlineView | `src/ui/views/outline_view.cr` | — | |
| PageControl | `src/ui/views/page_control.cr` | — | |
| Picker | `src/ui/views/picker.cr` | Yes | |
| Popover | `src/ui/views/popover.cr` | Yes | Arrow chrome is Apple polish; structure is universal. |
| ProgressView | `src/ui/views/progress_view.cr` | — | |
| RadioGroup | `src/ui/views/radio_group.cr` | Yes | |
| RatingIndicator | `src/ui/views/rating_indicator.cr` | — | |
| RichText | `src/ui/views/rich_text.cr` | — | |
| ScrollView | `src/ui/views/scroll_view.cr` | — | |
| SearchField | `src/ui/views/search_field.cr` | Yes | |
| SecureField | `src/ui/views/secure_field.cr` | Yes | |
| SegmentedControl | `src/ui/views/segmented_control.cr` | Yes | |
| Sheet | `src/ui/views/sheet.cr` | Yes | Bottom sheet / modal sheet. |
| Slider | `src/ui/views/slider.cr` | Yes | |
| Snackbar | `src/ui/views/snackbar.cr` | — | |
| Stepper | `src/ui/views/stepper.cr` | Yes | |
| TabView | `src/ui/views/tab_view.cr` | Yes | |
| TextArea | `src/ui/views/text_area.cr` | Yes | |
| TextEditor | `src/ui/views/text_editor.cr` | Yes | |
| TextField | `src/ui/views/text_field.cr` | Yes | |
| TimePicker | `src/ui/views/time_picker.cr` | Yes | `<input type="time">` on web. |
| Toggle | `src/ui/views/toggle.cr` | Yes | |
| ToggleButton | `src/ui/views/toggle_button.cr` | Yes | |
| TokenField | `src/ui/views/token_field.cr` | — | |
| Toolbar | `src/ui/views/toolbar.cr` | Yes | Kept as a single cross-platform class; NSToolbar-style customization UI would land as a future Tier 3 `PlatformToolbar`. |
| Tooltip | `src/ui/views/tooltip.cr` | — | |
| VideoPlayer | `src/ui/views/video_player.cr` | — | |
| WebViewComponent | `src/ui/views/web_view.cr` | — | |

## Tier 3 — Platform-only (3 gated classes + 3 cross-platform companions)

The 3 Tier 3 widgets below have **no honest cross-platform analog**.
Building them without the right `-D` flag is a compile error (via a
`macro new` that fires `{% raise %}` at the call site). An explicit
`*WithWebFallback` sibling class is provided for every Tier 3 widget
so application code can target both the native chrome and a credible
cross-platform fallback.

| Gated widget | Source file | Required flag | With-web-fallback class | Notes |
|---|---|---|---|---|
| ActionSheet | `src/ui/views/action_sheet.cr` | `:ios` | `ActionSheetWithWebFallback` | New in Phase 4. SwiftUI `.confirmationDialog` on iOS via `ConfirmationDialogFacade`. Current iOS routing degrades multi-action to {first non-cancel, cancel}; Phase 5 will add a multi-action SwiftKit facade. |
| ContextMenu | `src/ui/views/context_menu.cr` | `:macos` or `:ios` | `ContextMenuWithWebFallback` | Right-click / long-press menu. Vanilla-JS positioned dropdown on web with arrow-key nav, Tab/Shift+Tab focus trap, Escape close, click-outside dismiss, Shift+F10 / ContextMenu key open. |
| PathControl | `src/ui/views/path_control.cr` | `:macos` | `PathControlWithWebFallback` | NSPathControl is macOS-only. Web fallback emits a semantic `<nav aria-label="Breadcrumb"><ol>...</ol></nav>` with `aria-current="page"` on the leaf. |

Cross-platform companion classes (Tier-2-behavior on the target where
the gated class exists, full local rendering everywhere else):

| Companion | Source file | Required flag | Notes |
|---|---|---|---|
| ActionSheetWithWebFallback | `src/ui/views/action_sheet_with_web_fallback.cr` | none | Delegates to UI::ActionSheet on iOS; renders a bottom-sheet on web; synthesises a UI::ConfirmationDialog on macOS / Android. |
| ContextMenuWithWebFallback | `src/ui/views/context_menu_with_web_fallback.cr` | none | Delegates to UI::ContextMenu on Apple-family targets; renders a positioned vanilla-JS dropdown on web; renders a LinearLayout on Android. Carries an optional `trigger : View?` that the renderer emits as the host's first child so the fallback JS can bind contextmenu / Shift+F10 listeners. |
| PathControlWithWebFallback | `src/ui/views/path_control_with_web_fallback.cr` | none | Delegates to UI::PathControl on macOS; renders a semantic breadcrumb everywhere else. |

`UI::PathControlStyle` (enum) remains universal so non-macOS callers
can still annotate their `PathControlWithWebFallback` instances.

## Open questions / known concerns

None remaining for Phase 4 closure. The Phase 5 multi-action SwiftKit
facade is the documented follow-up for the iOS ActionSheet degradation.

`HapticFeedback` was referenced by an earlier README draft but no
file exists in `src/ui/views/` — it is **out of scope** for Phase 4
and will be tracked in a future phase.

`MenuBarExtra` is covered by the existing `src/ui/menu_bar.cr` (now
itself gated to Apple-family targets because it references the Tier 3
`UI::ContextMenu`).

## Change log

* **2026-05-21** — Phase 4 created the initial classification.
  17 Tier 1, 55 Tier 2, 3 Tier 3 (gated classes: `ActionSheet`,
  `ContextMenu`, `PathControl`) + 3 cross-platform companions
  (`ActionSheetWithWebFallback`, `ContextMenuWithWebFallback`,
  `PathControlWithWebFallback`). Total source files in
  `src/ui/views/`: 78 (74 pre-Phase-4 + 4 new: `action_sheet.cr`,
  `action_sheet_with_web_fallback.cr`,
  `context_menu_with_web_fallback.cr`,
  `path_control_with_web_fallback.cr`). Codex Checkpoint 1 moved
  `confirmation_dialog`, `icon_button`, `link_button`, and `snackbar`
  from Tier 1 to Tier 2. Codex Checkpoint 4 added the WithWebFallback
  companion table.
