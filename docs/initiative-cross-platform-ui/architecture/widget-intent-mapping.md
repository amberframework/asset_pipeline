# Widget → Intent Mapping

**Companion to:** `intent-catalog.md`, `translation-matrix.md`, `intent-backlog.md`.

Retro-classification of every `*.cr` file under `src/ui/views/` (including the gate-stub subdirectory). Each row carries:

- **View file** — path under `src/ui/views/`.
- **Primary intent (Apple name)** — the SwiftUI / UIKit / AppKit identifier this widget serves; `—` for pure layout primitives with no Apple-named intent.
- **Class** — exactly one of A / B / C / D (per brief-9 §"Item 6": every row carries an exact class assignment; layout primitives that map 1:1 to a SwiftUI primitive — `VStack`, `HStack`, `ZStack`, `Spacer`, `Divider`, `Rectangle`, `Circle`, `Capsule`, `RoundedRectangle`, `Path` — are Class D direct translations even though the catalog does not yet enumerate them).
- **Tier** — 1 (brand-universal), 2 (platform default), or 3 (platform-only gated). Tier assignments mirror `docs/initiative-cross-platform-ui/tier-matrix.md`.
- **Routing candidate?** — `YES` only for Class A widgets (per brief-9 §5 Item 6, only `swipe_action_row.cr` qualifies in this catalog).
- **Reason** — one sentence justifying the class assignment, citing the source line.
- **Gaps** — backlog ID(s) from `intent-backlog.md` for missing per-platform defaults; `—` if none.

**Phase 10-pre.1 amendment:** every row carries an explicit source citation. Per brief-10-pre-1 v2 §4 Deliverable 4, `activity_view.cr` stays Class C (Codex caught the v1 reclassification error — renderer-bridge wiring exists per `phase-10-pre-1-class-c-reaudit-2026-05-25.md`).

**Row count: 82** (79 top-level `src/ui/views/*.cr` files + 3 gate-stub siblings under `_gate_stubs/`). The total file count and category breakdown are reconciled in `translation-matrix.md` §"Freshness reconciliation."

---

## Top-level views (79)

| View file | Primary intent (Apple name) | Class | Tier | Routing candidate? | Reason | Gaps |
|---|---|---|---|---|---|---|
| `action_sheet.cr` | `confirmationDialog` (iOS surface) | D | 3 | NO | Tier 3 iOS-only action sheet; uses SwiftUI `.confirmationDialog` via the ConfirmationDialogFacade. See `src/ui/views/action_sheet.cr:17`. | — |
| `action_sheet_with_web_fallback.cr` | `confirmationDialog` | D | 3 | NO | Cross-platform companion to `UI::ActionSheet`; delegates to iOS facade or synthesizes `UI::ConfirmationDialog` on every other target. See `src/ui/views/action_sheet_with_web_fallback.cr:21`. | — |
| `activity_indicator.cr` | `ProgressView` (indeterminate) | D | 2 | NO | Indeterminate spinner. Direct mapping; see `src/ui/views/activity_indicator.cr:5`. | — |
| `activity_ring.cr` | `Gauge` (`accessoryCircularCapacity`) | D | 2 | NO | Single circular activity ring; renders as a shared fallback surface mirroring SwiftUI `Gauge` semantics. See `src/ui/views/activity_ring.cr:10`. | — |
| `activity_rings.cr` | `Gauge` (Move/Exercise/Stand triplet) | D | 2 | NO | Three-ring HIG activity summary; a composition over `Gauge` semantics, not a routed widget. See `src/ui/views/activity_rings.cr:10`. | — |
| `activity_view.cr` | `ShareLink` / `UIActivityViewController` | C | 2 | NO | Activity view for sharing; bridges to `UIActivityViewController` on iOS (`src/ui/renderers/uikit_renderer.cr:3408` → `src/ui/native/objc_bridge.m:2216-2245`), `NSSharingServicePicker` on macOS (`src/ui/renderers/appkit_renderer.cr:3417` → `src/ui/native/objc_bridge.m:2148-2214`), `Intent.ACTION_SEND` on Android (`src/ui/renderers/android_renderer.cr:2871` → `src/ui/native/android_bridge.c:1045`); web visitor at `src/ui/renderers/web_renderer.cr:2184-2265` emits an inline HTML approximation of the share-sheet (NOT `navigator.share()`). Carries an `ActivityViewPresenter` helper. Defined at `src/ui/views/activity_view.cr:54`. | B-026 closed by 10-pre.1 (`:share_link` shipped). |
| `alert.cr` | `alert` | D | 2 | NO | Modal alert dialog. Direct mapping; see `src/ui/views/alert.cr:5`. | — |
| `async_image.cr` | `AsyncImage` | D | 2 | NO | Asynchronous remote image loader. Direct mapping; see `src/ui/views/async_image.cr:4`. | — |
| `button.cr` | `Button` | D | 2 | NO | Clean SwiftUI `Button` / `UIButton` / `NSButton` mapping; concrete widget, never routed. See `src/ui/views/button.cr:41`. | — |
| `canvas.cr` | `Canvas` | D | 2 | NO | Immediate-mode drawing surface. Direct mapping; see `src/ui/views/canvas.cr:32`. | — |
| `capsule.cr` | `Capsule` (shape) | D | 1 | NO | Tier 1 brand-universal shape primitive. Direct mapping; see `src/ui/views/capsule.cr:4`. | — |
| `card.cr` | `GroupBox` / Boxes (HIG) | D | 1 | NO | Brand-universal container that follows HIG Boxes guidance; closest Apple analog is SwiftUI `GroupBox`. See `src/ui/views/card.cr:4`. | — |
| `chart_view.cr` | `Chart` (Swift Charts) | D | 2 | NO | Maps to SwiftUI `Chart` (Swift Charts framework). See `src/ui/views/chart_view.cr:9`. | — |
| `checkbox.cr` | `Toggle` (`.checkbox` style) | D | 2 | NO | Boolean toggle styled as a checkbox; maps to SwiftUI `Toggle(...).toggleStyle(.checkbox)`, `NSButton(checkboxWithTitle:)`. See `src/ui/views/checkbox.cr:4`. | — |
| `circle.cr` | `Circle` (shape) | D | 1 | NO | Tier 1 brand-universal shape primitive. Direct mapping; see `src/ui/views/circle.cr:4`. | — |
| `color_picker.cr` | `ColorPicker` | D | 2 | NO | Color selection. Direct mapping; see `src/ui/views/color_picker.cr:4`. | — |
| `column_view.cr` | `NSBrowser` (Finder-style columns) | D | 1 | NO | Tier 1 column browser; renderer-agnostic primitive whose closest Apple analog is `NSBrowser`. See `src/ui/views/column_view.cr:9`. | — |
| `combo_box.cr` | `NSComboBox` | D | 2 | NO | Hybrid text field + pull-down; maps to `NSComboBox` on macOS; HIG marks iOS as N/A so the widget degrades to a `Picker`-style fallback. See `src/ui/views/combo_box.cr:20`. | — |
| `confirmation_dialog.cr` | `confirmationDialog` | D | 2 | NO | Cross-platform confirmation dialog; maps to SwiftUI `.confirmationDialog`, `UIAlertController(.actionSheet)`, `NSAlert`. See `src/ui/views/confirmation_dialog.cr:4`. | — |
| `context_menu.cr` | `contextMenu` | D | 3 | NO | Tier 3 Apple-family-only context menu; SwiftUI `.contextMenu` / `UIContextMenuConfiguration`. See `src/ui/views/context_menu.cr:10`. | — |
| `context_menu_with_web_fallback.cr` | `contextMenu` | D | 3 | NO | Cross-platform companion that delegates on Apple targets and emits a vanilla-JS positioned dropdown on web. See `src/ui/views/context_menu_with_web_fallback.cr:15`. | B-006 |
| `date_picker.cr` | `DatePicker` | D | 2 | NO | Date selection. Direct mapping; see `src/ui/views/date_picker.cr:4`. | B-013 |
| `disclosure_group.cr` | `DisclosureGroup` | D | 2 | NO | Header + collapsible content. Direct mapping; see `src/ui/views/disclosure_group.cr:26`. | — |
| `divider.cr` | `Divider` | D | 1 | NO | Tier 1 layout primitive. Direct mapping; see `src/ui/views/divider.cr:4`. | — |
| `form.cr` | `Form` | D | 2 | NO | Form container that also doubles as a web `<form>` host when `action` is non-nil. Direct mapping; see `src/ui/views/form.cr:41`. | B-008 |
| `gauge.cr` | `Gauge` | D | 2 | NO | Circular gauge primitive; maps to SwiftUI `Gauge`, `NSLevelIndicator` (capacity/relevancy styles). See `src/ui/views/gauge.cr:11`. | — |
| `glass_background.cr` | `Material` / `UIVisualEffectView` | D | 2 | NO | Liquid Glass material backdrop; maps to SwiftUI `.background(.regularMaterial)`, `UIVisualEffectView(effect: UIBlurEffect)`, `NSVisualEffectView`. See `src/ui/views/glass_background.cr:4`. | — |
| `grid.cr` | `Grid` | D | 1 | NO | Tier 1 layout primitive; maps to SwiftUI `Grid` / `LazyVGrid`. See `src/ui/views/grid.cr:4`. | — |
| `hstack.cr` | `HStack` | D | 1 | NO | Tier 1 layout primitive. Direct mapping; see `src/ui/views/hstack.cr:8`. | — |
| `icon_button.cr` | `Button` (icon-only label) | D | 2 | NO | Icon-only button using SF Symbol on Apple and material icons elsewhere; specialization of `Button`. See `src/ui/views/icon_button.cr:5`. | — |
| `image.cr` | `Image` | D | 1 | NO | Tier 1 image primitive. Direct mapping; see `src/ui/views/image.cr:8`. | — |
| `image_well.cr` | `NSImageView` (image well) | D | 2 | NO | Bordered image drop-target; maps to `NSImageView` with `isEditable = true`; iOS uses a custom drop-zone analog. See `src/ui/views/image_well.cr:10`. | — |
| `label.cr` | `Text` | D | 1 | NO | Tier 1 read-only text primitive. Direct mapping; see `src/ui/views/label.cr:12`. | — |
| `link_button.cr` | `Link` | D | 2 | NO | URL-opening button; maps to SwiftUI `Link`, `UIButton`-with-URL-handler, web `<a>`. See `src/ui/views/link_button.cr:4`. | — |
| `list_view.cr` | `List` | D | 2 | NO | Scrollable list with optional sections; maps to SwiftUI `List`, `UITableView` / `UICollectionView`, `NSTableView`. See `src/ui/views/list_view.cr:5`. | B-003, B-004, B-005 |
| `map_view.cr` | `Map` (MapKit) | D | 2 | NO | Map view. Direct mapping; see `src/ui/views/map_view.cr:10`. | — |
| `menu_button.cr` | `Menu` / `NSPopUpButton` | D | 2 | NO | Pop-up / pull-down menu trigger; maps to SwiftUI `Menu`, `NSPopUpButton`, `UIButton` with `UIMenu`. See `src/ui/views/menu_button.cr:22`. | — |
| `navigation_link.cr` | `NavigationLink` | D | 2 | NO | Push-style nav link. Direct mapping; see `src/ui/views/navigation_link.cr:10`. | — |
| `navigation_split_view.cr` | `NavigationSplitView` | D | 2 | NO | Two/three-column split navigation; maps to SwiftUI `NavigationSplitView`, `UISplitViewController`, `NSSplitViewController`. Future Class A candidate per `translation-matrix.md`. See `src/ui/views/navigation_split_view.cr:4`. | — |
| `navigation_stack.cr` | `NavigationStack` | D | 2 | NO | Push/pop stack navigation; maps to SwiftUI `NavigationStack`, `UINavigationController`. See `src/ui/views/navigation_stack.cr:10`. | — |
| `outline_view.cr` | `OutlineGroup` / `NSOutlineView` | D | 2 | NO | Hierarchical outline; maps to SwiftUI `OutlineGroup` (in `List`), `NSOutlineView`. Carries a `Node` record. See `src/ui/views/outline_view.cr:4`. | — |
| `page_control.cr` | `UIPageControl` | D | 2 | NO | Dot indicators showing position in a paged list; UIKit-named primitive with macOS/web fallbacks. See `src/ui/views/page_control.cr:15`. | — |
| `panel.cr` | `Inspector` / `NSPanel` | D | 1 | NO | Tier 1 inspector/auxiliary panel surface; nearest Apple analog is SwiftUI `.inspector` or `NSPanel`. See `src/ui/views/panel.cr:16`. | B-009 |
| `path_control.cr` | `NSPathControl` | D | 3 | NO | Tier 3 macOS-only path control. Direct mapping; see `src/ui/views/path_control.cr:15`. | — |
| `path_control_with_web_fallback.cr` | `NSPathControl` | D | 3 | NO | Cross-platform companion; delegates on macOS and emits a semantic `<nav aria-label="Breadcrumb">` everywhere else. See `src/ui/views/path_control_with_web_fallback.cr:16`. | — |
| `path_view.cr` | `Path` (shape) | D | 1 | NO | Tier 1 SVG/path primitive. Direct mapping; see `src/ui/views/path_view.cr:21`. | — |
| `picker.cr` | `Picker` | D | 2 | NO | Selection control; maps to SwiftUI `Picker` (all styles). See `src/ui/views/picker.cr:5`. | B-012 |
| `popover.cr` | `popover` | D | 2 | NO | Anchored popover surface. Direct mapping; see `src/ui/views/popover.cr:4` (carries `PopoverPresenter` helper). | — |
| `progress_view.cr` | `ProgressView` | D | 2 | NO | Determinate / indeterminate progress. Direct mapping; see `src/ui/views/progress_view.cr:5`. | — |
| `radio_group.cr` | `Picker(.radioGroup)` | D | 2 | NO | Mutually exclusive radio options; maps to SwiftUI `Picker(...).pickerStyle(.radioGroup)` on macOS, custom on iOS. See `src/ui/views/radio_group.cr:4`. | — |
| `rating_indicator.cr` | `NSLevelIndicator(.rating)` | D | 2 | NO | Star-style rating row; maps to `NSLevelIndicator` with `.rating` style on macOS, custom on iOS/web. See `src/ui/views/rating_indicator.cr:21`. | — |
| `rectangle.cr` | `Rectangle` (shape) | D | 1 | NO | Tier 1 shape primitive. Direct mapping; see `src/ui/views/rectangle.cr:4`. | — |
| `rich_text.cr` | `AttributedString` `Text` | D | 2 | NO | Attributed-string text view. Direct mapping; see `src/ui/views/rich_text.cr:4`. | — |
| `rounded_rectangle.cr` | `RoundedRectangle` (shape) | D | 1 | NO | Tier 1 shape primitive. Direct mapping; see `src/ui/views/rounded_rectangle.cr:4`. | — |
| `scroll_view.cr` | `ScrollView` | D | 2 | NO | Scrollable container. Direct mapping; see `src/ui/views/scroll_view.cr:8`. | — |
| `search_field.cr` | `searchable` / `UISearchBar` | D | 2 | NO | Search input; maps to SwiftUI `.searchable`, `UISearchBar`, `NSSearchField`. See `src/ui/views/search_field.cr:4`. | B-004 |
| `secure_field.cr` | `SecureField` | D | 2 | NO | Password input; convenience wrapper. Direct mapping; see `src/ui/views/secure_field.cr:6`. | — |
| `segmented_control.cr` | `Picker(.segmented)` | D | 2 | NO | Segmented selection; maps to SwiftUI `Picker(...).pickerStyle(.segmented)`, `UISegmentedControl`, `NSSegmentedControl`. See `src/ui/views/segmented_control.cr:4`. | — |
| `sheet.cr` | `sheet` | D | 2 | NO | Modal sheet presentation. Direct mapping; see `src/ui/views/sheet.cr:7` (carries `SheetPresenter` helper). | B-007 |
| `slider.cr` | `Slider` | D | 2 | NO | Continuous-value slider. Direct mapping; see `src/ui/views/slider.cr:7`. | — |
| `snackbar.cr` | `Toast` / transient banner | D | 2 | NO | Transient feedback banner; Material `Snackbar` analog on Apple is a custom transient overlay (no first-party HIG name). Carries a `SnackbarPresenter` helper. See `src/ui/views/snackbar.cr:4`. | — |
| `spacer.cr` | `Spacer` | D | 1 | NO | Tier 1 layout primitive. Direct mapping; see `src/ui/views/spacer.cr:8`. | — |
| `stepper.cr` | `Stepper` | D | 2 | NO | Increment/decrement control. Direct mapping; see `src/ui/views/stepper.cr:4`. | — |
| `surface.cr` | Material/elevation surface | D | 1 | NO | Tier 1 themed surface primitive; nearest Apple analog is SwiftUI `.background(.background)` over a `GroupBox`-style container. See `src/ui/views/surface.cr:4`. | — |
| `swipe_action_row.cr` | `swipeActions` | A | 2 | YES | The single Class A intent — materially different per platform (iOS swipe-reveal vs macOS/web inline buttons); also defines a `SwipeAction` record. See `src/ui/views/swipe_action_row.cr:19` (struct), `src/ui/views/swipe_action_row.cr:64-65` (`leading_actions` / `trailing_actions`). Class A capability claims trimmed in 10-pre.1; full capability surface delivered in 10B.1b. | B-001 (P0), B-002 (P0), B-035, B-036 (P0) |
| `tab_view.cr` | `TabView` | D | 2 | NO | Tab-bar navigation; maps to SwiftUI `TabView`, `UITabBarController`. See `src/ui/views/tab_view.cr:15`. | — |
| `text_area.cr` | `TextField(axis: .vertical)` | D | 2 | NO | Multi-line text input; maps to SwiftUI `TextField(axis: .vertical)`, `UITextView`, `NSTextView`. See `src/ui/views/text_area.cr:4`. | — |
| `text_editor.cr` | `TextEditor` | D | 2 | NO | Long-form text editor. Direct mapping; see `src/ui/views/text_editor.cr:4`. | — |
| `text_field.cr` | `TextField` | D | 2 | NO | Single-line editable input. Direct mapping; see `src/ui/views/text_field.cr:8`. | — |
| `time_picker.cr` | `DatePicker(displayedComponents: .hourAndMinute)` | D | 2 | NO | Time-only specialization of `DatePicker`. See `src/ui/views/time_picker.cr:4`. | — |
| `toggle.cr` | `Toggle` | D | 2 | NO | Boolean toggle (switch). Direct mapping; see `src/ui/views/toggle.cr:7`. | — |
| `toggle_button.cr` | `Button` (toggle role) | D | 2 | NO | Two-state pushable button; maps to SwiftUI `Toggle(...).toggleStyle(.button)`, `NSButton(.toggle)`. See `src/ui/views/toggle_button.cr:4`. | — |
| `token_field.cr` | `NSTokenField` | D | 2 | NO | Pill-style token entry; maps to `NSTokenField` on macOS, custom on iOS/web. See `src/ui/views/token_field.cr:10`. | — |
| `toolbar.cr` | `toolbar` | D | 2 | NO | Toolbar surface; maps to SwiftUI `.toolbar`, `UIToolbar`, `NSToolbar`. See `src/ui/views/toolbar.cr:4`. | B-011 |
| `tooltip.cr` | `help` / tooltip | D | 2 | NO | Hover/long-press tooltip; maps to SwiftUI `.help(_:)`, `NSView.toolTip`. See `src/ui/views/tooltip.cr:4`. | — |
| `video_player.cr` | `VideoPlayer` (AVKit) | D | 2 | NO | Media playback. Direct mapping; see `src/ui/views/video_player.cr:4`. | — |
| `vstack.cr` | `VStack` | D | 1 | NO | Tier 1 layout primitive. Direct mapping; see `src/ui/views/vstack.cr:8`. | — |
| `web_view.cr` | `WKWebView` | D | 2 | NO | Embedded web content; maps to `WKWebView` on Apple, `WebView` (Android), `<iframe>` (web). See `src/ui/views/web_view.cr:4`. | — |
| `zstack.cr` | `ZStack` | D | 1 | NO | Tier 1 layout primitive. Direct mapping; see `src/ui/views/zstack.cr:9`. | — |

## Gate-stub siblings (3)

These files live under `src/ui/views/_gate_stubs/` and exist solely to emit a `{% raise %}` compile-time error on non-matching builds (per CLAUDE.md:148-160). They mirror an existing Tier 3 widget and inherit its classification.

| View file | Primary intent (Apple name) | Class | Tier | Routing candidate? | Reason | Gaps |
|---|---|---|---|---|---|---|
| `_gate_stubs/action_sheet.cr` | `confirmationDialog` (iOS surface) | D | 3 | NO | Compile-time stub mirroring `UI::ActionSheet`; emits a `{% raise %}` error on non-iOS builds. See `src/ui/views/_gate_stubs/action_sheet.cr:14`. | — |
| `_gate_stubs/context_menu.cr` | `contextMenu` | D | 3 | NO | Compile-time stub mirroring `UI::ContextMenu`; emits a `{% raise %}` error on non-Apple-family builds. See `src/ui/views/_gate_stubs/context_menu.cr:9`. | — |
| `_gate_stubs/path_control.cr` | `NSPathControl` | D | 3 | NO | Compile-time stub mirroring `UI::PathControl`; emits a `{% raise %}` error on non-macOS builds. See `src/ui/views/_gate_stubs/path_control.cr:9`. | — |

---

## Summary

- **Total rows:** 82 (79 top-level + 3 gate-stub siblings).
- **Class A (routing candidates):** 1 (`swipe_action_row.cr`).
- **Class B:** 0 (Class B intents are framework invariants, not view files; cross-cutting accessibility lives on every `UI::View`, not in a dedicated view file).
- **Class C:** 1 (`activity_view.cr` — Phase 10-pre.1 re-audit confirmed `:share_link` SHIPPED with renderer-bridge wiring on all three native platforms plus web; see `phase-10-pre-1-class-c-reaudit-2026-05-25.md`).
- **Class D:** 80 (every concrete widget that maps 1:1 to a SwiftUI / UIKit / AppKit named API, modifier, or primitive — including the 10 Tier 1 layout primitives that map directly to SwiftUI `VStack` / `HStack` / `ZStack` / `Spacer` / `Divider` / `Rectangle` / `Circle` / `Capsule` / `RoundedRectangle` / `Path`).
- **Tier 1:** 17. **Tier 2:** 56 (incl. the WithWebFallback companions that ride along the Tier 3 widget but render universally). **Tier 3:** 3 gated + 3 companions + 3 gate stubs = 9 files in the Tier 3 orbit, but only 3 widget rows in `tier-matrix.md` (per brief-9 §6 and Codex iter 1's note: `swipe_action_row.cr` is also currently absent from `tier-matrix.md` — a documented staleness in the matrix, not a discrepancy in the source tree).

**Row math:** 1 (A) + 0 (B) + 1 (C) + 80 (D) = 82. Matches the source-tree count. Unchanged from Phase 9 close (Codex prevented the v1 reclassification of `activity_view.cr` from C to D).

— Implementer (Claude Opus 4.7), Phase 9 iter 1; updated Phase 10-pre.1
