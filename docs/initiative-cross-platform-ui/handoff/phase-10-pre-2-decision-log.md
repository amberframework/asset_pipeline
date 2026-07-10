# Phase 10-pre.2 — Per-Row Decision Log

**Branch:** `phase-10-pre-2`
**Implementer:** Claude Opus 4.7
**Brief:** `phases/phase-10-distribution-and-rules/brief-10-pre-2.md` (v2, post-Codex).
**Date:** 2026-05-25.

Scope: 64 Class D rows. Each row's `crystal_api_shape` was verified or
rewritten per the "code wins" rubric (brief §1, §3). Zero catalog-wins
candidates were surfaced.

## Decision distribution

| Decision | Count | Notes |
|---|---|---|
| Code-wins-rewrite (full section below) | 23 | Catalog `crystal_api_shape` rewritten to match shipped Crystal source. Of these, 2 also carried coverage_today corrections (atomic). |
| Confirmed-correct (appendix table) | 41 | Either matches source already, OR is an honest forward-looking proposal for a missing surface (no source to verify against). |
| Catalog-wins-rename | 0 | No row triggered the catalog-wins rubric. |
| New-design-needed (escalated) | 0 | No row required new design work. |
| **Total Class D** | **64** | Matches brief §1 scope expectation. |

The 23 corrected rows include all 10 pre-ruled corrections (brief
Deliverable 2 table) plus 13 additional rows the sweep surfaced. The
2 coverage_today cleanups are `:presentation_detents` and
`:presentation_drag_indicator` (Codex MED-4 anticipated both).

---

## Corrected rows (code-wins-rewrite)

### `:list`

- **Catalog crystal_api_shape (was):** `list = UI::List.new; list << row_for(item) for each item`
- **Actual Crystal API:** `class UI::ListView < View` with `property sections : Array(Section)` and class method `self.flat(items : Array(View), style)` (`src/ui/views/list_view.cr:5,13,37,41`).
- **New crystal_api_shape:** `list = UI::ListView.flat(items: rows)` OR `UI::ListView.new(sections: [UI::ListView::Section.new(items: rows)])`
- **Decision:** code-wins-rewrite
- **Rationale:** Class is `UI::ListView` (not `UI::List`); composition is by section records, not `<<`. Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** none (already partial with citation; marker removed).

### `:list_row_separator`

- **Catalog crystal_api_shape (was):** `row.list_row_separator = :visible | :hidden`
- **Actual Crystal API:** `ListView#shows_separators : Bool = true` (`src/ui/views/list_view.cr:32`).
- **New crystal_api_shape:** `list.shows_separators = false`
- **Decision:** code-wins-rewrite
- **Rationale:** Today's surface is a list-level boolean, not a per-row symbol. Per-row separator override is a real gap (surfaced to close handoff as a candidate for future backlog). Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** none (already partial with citation; marker removed).

### `:sheet`

- **Catalog crystal_api_shape (was):** `sheet = UI::Sheet.new(content); sheet.present(from: parent)`
- **Actual Crystal API:** `Sheet#initialize(content : View? = nil, *, surface_style)` (`src/ui/views/sheet.cr:51`) and `class SheetPresenter` whose `present` method takes no arguments (`src/ui/views/sheet.cr:59-69`).
- **New crystal_api_shape:** `sheet = UI::Sheet.new(content); presenter = UI::SheetPresenter.new(sheet); presenter.present`
- **Decision:** code-wins-rewrite
- **Rationale:** No `present(from: parent)` method exists on `Sheet`; presentation is delegated to a separate `SheetPresenter`. Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** none.

### `:presentation_detents`

- **Catalog crystal_api_shape (was):** `sheet.presentation_detents = [:medium, :large]`
- **Actual Crystal API:** `Sheet#detents : Array(Symbol) = [:medium, :large]` (`src/ui/views/sheet.cr:31`). iOS/macOS wired through SwiftKit at `src/ui/native/swiftkit_overrides.cr:464-466` (`setDetents`). Android stub at `src/ui/renderers/android_renderer.cr:1865`. Web stub at `src/ui/renderers/web_renderer.cr`.
- **New crystal_api_shape:** `sheet.detents = [:medium, :large]`
- **Decision:** code-wins-rewrite
- **Rationale:** Property is `detents`, not `presentation_detents`. Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** **YES** — coverage_today changed from `missing` to `partial`. The property + SwiftKit wiring shipped; iOS bridge lives in the SwiftKit facade, which the 10-pre.1 audit didn't probe.

### `:presentation_drag_indicator`

- **Catalog crystal_api_shape (was):** `sheet.presentation_drag_indicator = :visible | :hidden | :automatic`
- **Actual Crystal API:** `Sheet#shows_drag_indicator : Bool = true` (`src/ui/views/sheet.cr:30`). iOS/macOS wired through SwiftKit at `src/ui/native/swiftkit_overrides.cr:468-469` (`setShowsDragIndicator`). Web at `src/ui/renderers/web_renderer.cr:1367`. Android at `src/ui/renderers/android_renderer.cr:1857`.
- **New crystal_api_shape:** `sheet.shows_drag_indicator = true`
- **Decision:** code-wins-rewrite
- **Rationale:** Surface is a `Bool`, not a tri-valued symbol. Loss of `:automatic` is an honest design gap (surfaced to close handoff). Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** **YES** — coverage_today changed from `missing` to `partial`. Same audit gap as `:presentation_detents`.

### `:toolbar`

- **Catalog crystal_api_shape (was):** `screen.toolbar = UI::Toolbar.new(items: [...])`
- **Actual Crystal API:** `Toolbar#initialize(@title : String? = nil)` (`src/ui/views/toolbar.cr:20`) + `add_item(id, label, icon, &block)` (`src/ui/views/toolbar.cr:23`).
- **New crystal_api_shape:** `toolbar = UI::Toolbar.new("Title"); toolbar.add_item(id: "save", label: "Save", icon: "checkmark") { ... }`
- **Decision:** code-wins-rewrite
- **Rationale:** Constructor takes title (not items kwarg); items added via `add_item` block API. Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** none.

### `:toolbar_item`

- **Catalog crystal_api_shape (was):** `toolbar << UI::ToolbarItem.new(label: "Save", on_tap: ->{...})`
- **Actual Crystal API:** `record ToolbarItem, id, label, icon, action : Proc(Nil)?` (`src/ui/views/toolbar.cr:5-9`); public author API is `Toolbar#add_item` (`src/ui/views/toolbar.cr:23,27`). Toolbar has no `<<` operator.
- **New crystal_api_shape:** `toolbar.add_item(id: "save", label: "Save", icon: "checkmark") { ... }`
- **Decision:** code-wins-rewrite
- **Rationale:** Authors should never construct the `ToolbarItem` record directly; the block-based factory is the public API. Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** none.

### `:menu_picker_style`

- **Catalog crystal_api_shape (was):** `picker.picker_style = :menu`
- **Actual Crystal API:** `Picker#style : PickerStyle = PickerStyle::Menu` (`src/ui/views/picker.cr:16`); enum at `src/ui/view.cr:66-71`.
- **New crystal_api_shape:** `picker.style = UI::PickerStyle::Menu`
- **Decision:** code-wins-rewrite
- **Rationale:** Property is `style` (not `picker_style`); value is an enum, not a symbol. Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** none.

### `:menu`

- **Catalog crystal_api_shape (was):** `menu = UI::Menu.new(label: "More") << ...`
- **Actual Crystal API:** `class UI::MenuButton < View` with `add_item(label, icon, is_destructive, &block)` (`src/ui/views/menu_button.cr:22,45,48`).
- **New crystal_api_shape:** `menu = UI::MenuButton.new("More"); menu.add_item(label: "Duplicate") { ... }`
- **Decision:** code-wins-rewrite
- **Rationale:** Use existing `UI::MenuButton`; do NOT rename to `UI::Menu` in this slice (would be catalog-wins; brief explicitly defers). Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** none.

### `:context_menu`

- **Catalog crystal_api_shape (was):** `view.context_menu = UI::ContextMenu.new(items: [...])`
- **Actual Crystal API:** `ContextMenu#initialize` takes no args (`src/ui/views/context_menu.cr:25`); items added via `add_item(label, icon, is_destructive, is_disabled, &block)` (`src/ui/views/context_menu.cr:28`). No `view.context_menu=` setter exists.
- **New crystal_api_shape:** `menu = UI::ContextMenu.new; menu.add_item(label: "Delete", is_destructive: true) { ... }`
- **Decision:** code-wins-rewrite
- **Rationale:** Tier 3 iOS-gated class (cross-platform wrapper at `context_menu_with_web_fallback.cr`). The `view.context_menu=` setter is a forward-looking design idea, not shipped today. Pre-ruled by brief Deliverable 2.
- **Coverage cleanup:** none.

### `:popover`

- **Catalog crystal_api_shape (was):** `popover = UI::Popover.new(content); popover.present(from: anchor_view)`
- **Actual Crystal API:** `Popover#initialize(content, arrow_edge : Symbol = :bottom)` (`src/ui/views/popover.cr:17`). Presentation requires `PopoverPresenter.new(popover, anchor); presenter.present` (`src/ui/views/popover.cr:25-43`). No `present(from:)` method on `Popover`.
- **New crystal_api_shape:** `popover = UI::Popover.new(content, :bottom); presenter = UI::PopoverPresenter.new(popover, anchor_view); presenter.present`
- **Decision:** code-wins-rewrite
- **Rationale:** Mirrors the Sheet/SheetPresenter pattern; `present(from:)` does not exist.
- **Coverage cleanup:** none.

### `:alert`

- **Catalog crystal_api_shape (was):** `alert = UI::Alert.new(title: "Delete?", actions: [...]); alert.present`
- **Actual Crystal API:** `Alert#initialize(@title, @message)` (`src/ui/views/alert.cr:32`); button factory `add_button(label, style, &action)` (`src/ui/views/alert.cr:36`); presentation via the `is_presented` Bool (`src/ui/views/alert.cr:22`). No `actions:` kwarg, no `present` method.
- **New crystal_api_shape:** `alert = UI::Alert.new("Delete?", "This cannot be undone."); alert.add_button("Delete", :destructive) { state.delete }; alert.add_button("Cancel"); alert.is_presented = true`
- **Decision:** code-wins-rewrite
- **Rationale:** Constructor takes positional title+message; presentation is a property mutation (reactive), not a method call.
- **Coverage cleanup:** none.

### `:confirmation_dialog`

- **Catalog crystal_api_shape (was):** `dialog = UI::ConfirmationDialog.new(title: "Delete?", actions: [...]); dialog.present`
- **Actual Crystal API:** `ConfirmationDialog#initialize(@title, @message)` (`src/ui/views/confirmation_dialog.cr:14`); properties `confirm_label`, `cancel_label`, `confirm_style`, `on_confirm`, `on_cancel`, `is_presented` (`src/ui/views/confirmation_dialog.cr:5-12`). No `actions:` array, no `present` method.
- **New crystal_api_shape:** `dialog = UI::ConfirmationDialog.new("Delete?", "This cannot be undone."); dialog.confirm_style = :destructive; dialog.on_confirm = -> { state.delete }; dialog.is_presented = true`
- **Decision:** code-wins-rewrite
- **Rationale:** Two-button dialog with a single primary action; structure differs from `:alert` (which supports N buttons via `add_button`).
- **Coverage cleanup:** none.

### `:navigation_stack`

- **Catalog crystal_api_shape (was):** `coord = UI::NavigationCoordinator.new(initial_route); coord.push(...)`
- **Actual Crystal API:** `NavigationCoordinator#initialize(root : Route)` (`src/ui/navigation_coordinator.cr:43`); `push(route : Route)` (`src/ui/navigation_coordinator.cr:59`). `Route` is a record with `id : Symbol` + optional `params` (`src/ui/navigation_coordinator.cr:36`).
- **New crystal_api_shape:** `coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:home)); coord.push(UI::NavigationCoordinator::Route.new(:settings))`
- **Decision:** code-wins-rewrite
- **Rationale:** `initial_route` was a placeholder — the actual argument must be a `Route` value, and `push` requires a `Route` (not arbitrary content).
- **Coverage cleanup:** none.

### `:navigation_split_view`

- **Catalog crystal_api_shape (was):** `screen = UI::NavigationSplitView.new(sidebar:, detail:)`
- **Actual Crystal API:** `NavigationSplitView#initialize(sidebar : View? = nil, content : View? = nil, detail : View? = nil)` (`src/ui/views/navigation_split_view.cr:20`).
- **New crystal_api_shape:** `view = UI::NavigationSplitView.new(sidebar: sidebar_view, content: list_view, detail: detail_view)`
- **Decision:** code-wins-rewrite
- **Rationale:** `screen =` is misleading (it's a view); `content:` kwarg was omitted from the prior shape but is a real constructor parameter.
- **Coverage cleanup:** none.

### `:navigation_link`

- **Catalog crystal_api_shape (was):** `link = UI::NavigationLink.new(label: "Settings", route_id: :settings)`
- **Actual Crystal API:** `NavigationLink#initialize(@label : String, @destination : View)` (`src/ui/views/navigation_link.cr:23`). Properties: `label`, `destination`, `icon`, `shows_disclosure`.
- **New crystal_api_shape:** `link = UI::NavigationLink.new("Settings", settings_screen_view)`
- **Decision:** code-wins-rewrite
- **Rationale:** Constructor takes a `View` destination, not a `route_id`. Route-driven navigation is a per-app concern (`Voyager.dispatch(:open_X)`), not part of the link's API.
- **Coverage cleanup:** none.

### `:segmented_picker_style`

- **Catalog crystal_api_shape (was):** `picker.picker_style = :segmented`
- **Actual Crystal API:** `Picker#style = UI::PickerStyle::Segmented` (`src/ui/views/picker.cr:16`, enum at `src/ui/view.cr:66-71`). Standalone `UI::SegmentedControl` also ships at `src/ui/views/segmented_control.cr:4`.
- **New crystal_api_shape:** `picker.style = UI::PickerStyle::Segmented` (or use the standalone `UI::SegmentedControl.new(segments)`)
- **Decision:** code-wins-rewrite
- **Rationale:** Same property/enum correction as `:menu_picker_style`. Noted the standalone class alternative since `SegmentedControl` is its own widget.
- **Coverage cleanup:** none.

### `:wheel_picker_style`

- **Catalog crystal_api_shape (was):** `picker.picker_style = :wheel`
- **Actual Crystal API:** `Picker#style` property (`src/ui/views/picker.cr:16`); enum has `Wheel` member (`src/ui/view.cr:67`). Renderer/visual wiring for the wheel style is TBD.
- **New crystal_api_shape:** `picker.style = UI::PickerStyle::Wheel` (enum value exists at `src/ui/view.cr:67`; renderer wiring TBD)
- **Decision:** code-wins-rewrite
- **Rationale:** Property + enum value exist; only the visual treatment is missing. Aligned shape with the pre-ruled `:menu_picker_style` pattern.
- **Coverage cleanup:** none (still `missing` — Picker exists but no wheel-specific rendering).

### `:inline_picker_style`

- **Catalog crystal_api_shape (was):** `picker.picker_style = :inline`
- **Actual Crystal API:** `Picker#style` property; enum has `Inline` member (`src/ui/view.cr:70`). Renderer wiring TBD.
- **New crystal_api_shape:** `picker.style = UI::PickerStyle::Inline` (enum value exists at `src/ui/view.cr:70`; renderer wiring TBD)
- **Decision:** code-wins-rewrite
- **Rationale:** Same as `:wheel_picker_style` — enum value exists, only visual treatment missing.
- **Coverage cleanup:** none.

### `:palette_picker_style`

- **Catalog crystal_api_shape (was):** `picker.picker_style = :palette`
- **Actual Crystal API:** `Picker#style` property exists; enum has NO `Palette` member yet (`src/ui/view.cr:66-71` — only Wheel/Segmented/Menu/Inline). Tracked by B-012.
- **New crystal_api_shape:** `picker.style = UI::PickerStyle::Palette  # enum value not yet defined (B-012); add to src/ui/view.cr enum, then renderer support`
- **Decision:** code-wins-rewrite
- **Rationale:** Aligned shape with the picker_style pattern but noted that the enum member is the missing piece (preserves the backlog reference inline).
- **Coverage cleanup:** none.

### `:toolbar_item_group`

- **Catalog crystal_api_shape (was):** `toolbar << UI::ToolbarItemGroup.new(items: [...])`
- **Actual Crystal API:** `Toolbar` has no `<<` operator and no group concept (`src/ui/views/toolbar.cr` only ships `add_item`).
- **New crystal_api_shape:** `toolbar.add_group(id: "edit", items: [...])  # API TBD; Toolbar today only ships flat add_item`
- **Decision:** code-wins-rewrite
- **Rationale:** Removed reference to non-existent `<<` operator + non-existent `UI::ToolbarItemGroup`. Replaced with a forward-looking method-call shape consistent with `Toolbar#add_item`.
- **Coverage cleanup:** none.

### `:toolbar_spacer`

- **Catalog crystal_api_shape (was):** `toolbar << UI::ToolbarSpacer.new(:flexible)`
- **Actual Crystal API:** Same as above — no `<<`, no spacer concept.
- **New crystal_api_shape:** `toolbar.add_spacer(:flexible)  # API TBD; Toolbar today has no spacer/group concept`
- **Decision:** code-wins-rewrite
- **Rationale:** Same as `:toolbar_item_group`.
- **Coverage cleanup:** none.

### `:tap_gesture`

- **Catalog crystal_api_shape (was):** `view.on_tap = -> { ... }`
- **Actual Crystal API:** `on_tap` property exists on `Button` (`src/ui/views/button.cr:93`), `IconButton` (`src/ui/views/icon_button.cr:22`), `LinkButton` (`src/ui/views/link_button.cr:8`), and `SwipeAction` (`src/ui/views/swipe_action_row.cr:23`). NOT on base `UI::View`.
- **New crystal_api_shape:** `button.on_tap = -> { ... }` (available on `Button`, `IconButton`, `LinkButton`, `SwipeAction` only; NOT on base `UI::View`)
- **Decision:** code-wins-rewrite
- **Rationale:** The `view.` prefix wrongly implied universal availability. Inline note documents the actual surface. Matches the 10-pre.1 audit finding that downgraded coverage from `shipped` to `partial`.
- **Coverage cleanup:** none.

---

## Coverage_today cleanups from 10-pre.1 audit gap

Two rows where `crystal_api_shape` verification exposed `coverage_today` drift; both fixed atomically.

| Intent | coverage_today (was) | coverage_today (after) | Why missed by 10-pre.1 |
|---|---|---|---|
| `:presentation_detents` | `missing` | `partial (Sheet#detents at sheet.cr:31; SwiftKit setDetents at swiftkit_overrides.cr:464-466; web/android stubs)` | iOS native binding lives in the SwiftKit facade (`src/ui/native/swiftkit_overrides.cr`), which the 10-pre.1 audit-scope grep did not include. |
| `:presentation_drag_indicator` | `missing` | `partial (Sheet#shows_drag_indicator at sheet.cr:30; SwiftKit setShowsDragIndicator at swiftkit_overrides.cr:468-469; web at web_renderer.cr:1367; android at android_renderer.cr:1857)` | Same — the SwiftKit facade was not in the scope of 10-pre.1's "shipped vs missing" sweep. |

Both rows preserve the audit history with a `# was:` note appended to the new value.

---

## Confirmed-correct (appendix table)

41 Class D rows whose `crystal_api_shape` was verified or judged honest forward-looking. For rows with a citable source, the verification file:line is recorded.

| Intent | crystal_api_shape (unchanged) | Verified against |
|---|---|---|
| :list_section_spacing | `list.list_section_spacing = 24.0` | forward-looking proposal; no property exists on `UI::ListView` |
| :list_section_index_visibility | `list.list_section_index_visibility = :automatic | :visible | :hidden` | forward-looking proposal; missing |
| :refreshable | `list.refreshable = -> { state.reload_todos }` | forward-looking proposal; missing |
| :searchable | `list.searchable = "Search todos..."` | forward-looking proposal; missing |
| :search_suggestions | `list.search_suggestions = ->(query : String) { ["Egg", "Eggplant"] }` | forward-looking proposal; missing |
| :search_scopes | `list.search_scopes = ["All", "Open", "Done"]` | forward-looking proposal; missing |
| :on_move | `list.on_move = ->(from : Range(Int32, Int32), to : Int32) { state.reorder_todos(from, to) }` | forward-looking proposal; missing on `UI::ListView` |
| :on_delete | `list.on_delete = ->(indices : IndexSet) { state.delete_todos(indices) }` | forward-looking; today's partial coverage is via `UI::SwipeActionRow.trailing_actions` (`src/ui/views/swipe_action_row.cr:65`) — not via `on_delete` on the list |
| :full_screen_cover | `cover = UI::FullScreenCover.new(content); cover.present` | forward-looking; no `UI::FullScreenCover` class exists |
| :inspector | `screen.inspector = UI::Inspector.new(detail_content)` | forward-looking; no `UI::Inspector` class exists |
| :interactive_dismiss_disabled | `sheet.interactive_dismiss_disabled = true` | forward-looking; no such property on `UI::Sheet` |
| :toolbar_item_placement | `item.placement = :navigation_bar_leading` | forward-looking; `ToolbarItem` record has no `placement` field |
| :toolbar_background | `toolbar.toolbar_background = UI::Color.brand_primary` | forward-looking; no property + no `UI::Color` class exists |
| :form_style | `form.form_style = :grouped | :columns | :automatic` | forward-looking; no `form_style` on `UI::Form` |
| :grouped_form_style | `form.form_style = :grouped` | forward-looking; same |
| :columns_form_style | `form.form_style = :columns` | forward-looking; same |
| :compact_date_picker_style | `picker.date_picker_style = :compact` | forward-looking; `DatePicker` has no `date_picker_style` property (`src/ui/views/date_picker.cr:4-22`) — only `mode` ships today |
| :graphical_date_picker_style | `picker.date_picker_style = :graphical` | forward-looking; same |
| :wheel_date_picker_style | `picker.date_picker_style = :wheel` | forward-looking; same |
| :navigation_destination | `screen :foo, FooController` | `src/asset_pipeline/native_app.cr:227` — `macro screen(route_id, controller = nil, ...)` signature matches |
| :navigation_path | `coord.routes  # Array(Route)` | `src/ui/navigation_coordinator.cr:38-39` — `getter routes : Array(Route)` matches |
| :ui_menu | `menu = UI::UIMenu.new(title: "Actions", children: [ui_action1, ui_action2])` | forward-looking; no `UI::UIMenu` class — today's partial coverage cites the `MenuButton.MenuItem` analog (`src/ui/views/menu_button.cr:23-35`) |
| :ui_action | `action = UI::UIAction.new(title: "Delete", handler: ->{...})` | forward-looking; no `UI::UIAction` class — analog is `MenuButton.MenuItem` |
| :primary_action | `menu.primary_action = -> { state.do_default }` | forward-looking; not implemented |
| :draggable | `view.draggable = { transferable_payload }` | forward-looking; no drag-and-drop system on `UI::View` |
| :drop_destination | `view.drop_destination = ->(payload, location) { ... }` | forward-looking; same |
| :transferable | `module MyType; include UI::Transferable; ...; end` | forward-looking; no `UI::Transferable` module |
| :transition | `view.transition = :fade | :slide | :scale` | forward-looking; no transition system on `UI::View` |
| :matched_geometry_effect | `view.matched_geometry_id = :hero_image` | forward-looking; no matched-geometry system |
| :animation | `view.animation = UI::Animation.spring(duration: 0.3)` | forward-looking; no `UI::Animation` class |
| :phase_animator | `view.phase_animator = [:a, :b, :c]` | forward-looking; not implemented |
| :keyframe_animator | `view.keyframe_animator = { ... }` | forward-looking; not implemented |
| :sensory_feedback | `view.sensory_feedback = :success | :warning | :error | :impact | :selection` | forward-looking; not implemented |
| :ui_impact_feedback_generator | `UI::UIImpactFeedbackGenerator.new(style: :medium).impact_occurred` | forward-looking; no such class |
| :ui_notification_feedback_generator | `UI::UINotificationFeedbackGenerator.new.notification_occurred(:success)` | forward-looking; no such class |
| :ui_selection_feedback_generator | `UI::UISelectionFeedbackGenerator.new.selection_changed` | forward-looking; no such class |
| :long_press_gesture | `view.on_long_press = -> { ... }` | forward-looking; standalone modifier missing (used internally by ContextMenu) |
| :drag_gesture | `view.on_drag = ->(translation : Point) { ... }` | forward-looking; not implemented |
| :magnify_gesture | `view.on_magnify = ->(scale : Float64) { ... }` | forward-looking; not implemented |
| :rotate_gesture | `view.on_rotate = ->(angle : Float64) { ... }` | forward-looking; not implemented |
| :spatial_tap_gesture | `view.on_spatial_tap = ->(location : Point3D) { ... }` | forward-looking; visionOS only — out of current cross-platform scope |

Count check: 64 Class D total - 23 code-wins rewrites = 41 confirmed-correct. The table above lists exactly 41 rows.

---

## Catalog-wins-rename (0)

No row triggered the catalog-wins rubric (brief §3). The closest call:

- **`:menu`** (catalog says `UI::Menu`; source ships `UI::MenuButton`). Brief explicitly pre-ruled this code-wins for 10-pre.2 with a future-phase note that a `UI::Menu` rename remains a candidate when the broader menu/MenuBar/UIMenu modeling is reconsidered. Not catalog-wins THIS slice.

No other row's existing Crystal name (a) made two distinct Apple intents indistinguishable OR (b) labeled the wrong HIG role.

---

## New-design-needed (0)

No row required new design work. Several rows surfaced design QUESTIONS that are tracked in the close handoff under "new gaps surfaced," but none required escalation to the architect to unblock the catalog correction.

---

---

## Iter-2 addendum (post-Codex BLOCK)

Iter 1 closed at HEAD `63f8d804` with Codex returning BLOCK (3 HIGH + 4 MEDIUM + 2 LOW). The full list and remediation summary is in `phase-10-pre-2-close.md` § "Iter-2 remediation"; this addendum records the per-row decisions iter 2 applied.

### Rows reclassified from "confirmed-correct" appendix to "code-wins-rewrite"

The following rows were marked "honest forward-looking proposal" in the iter 1 appendix, but the catalog `crystal_api_shape` field still presented fictitious classes/methods AS IF they were real APIs. Iter 2 rewrote each shape to be an explicit "not yet implemented" note that names the missing surface and the relevant backlog item (when one exists). The appendix annotation was accurate; the catalog SHAPE was the misleading text.

| Intent | Catalog shape (was, fictitious) | Catalog shape (after iter 2) |
|---|---|---|
| `:full_screen_cover` | `cover = UI::FullScreenCover.new(content); cover.present` | `# Not yet implemented — no UI::FullScreenCover class … Tracked under B-010.` |
| `:inspector` | `screen.inspector = UI::Inspector.new(detail_content)` | `# Not yet implemented — no UI::Inspector class … Tracked under B-009.` |
| `:interactive_dismiss_disabled` | `sheet.interactive_dismiss_disabled = true` | `# Not yet implemented — no interactive_dismiss_disabled property on UI::Sheet.` |
| `:compact_date_picker_style` | `picker.date_picker_style = :compact` | `# Not yet implemented — UI::DatePicker has no date_picker_style property; only `mode` ships.` |
| `:graphical_date_picker_style` | `picker.date_picker_style = :graphical` | Same gap as compact. |
| `:wheel_date_picker_style` | `picker.date_picker_style = :wheel` | Same gap as compact. |
| `:ui_menu` | `menu = UI::UIMenu.new(title:, children:)` | `# Not yet implemented — no standalone UI::UIMenu … analog is MenuButton::MenuItem.` |
| `:ui_action` | `action = UI::UIAction.new(title:, handler:)` | `# Not yet implemented — no standalone UI::UIAction … analog is MenuButton::MenuItem.` |
| `:transferable` | `module MyType; include UI::Transferable; ...; end` | `# Not yet implemented — no UI::Transferable module.` |
| `:animation` | `view.animation = UI::Animation.spring(duration: 0.3)` | `# Not yet implemented — no UI::Animation class.` |
| `:ui_impact_feedback_generator` | `UI::UIImpactFeedbackGenerator.new(style: :medium).impact_occurred` | `# Not yet implemented — no UI::UIImpactFeedbackGenerator class.` |
| `:ui_notification_feedback_generator` | `UI::UINotificationFeedbackGenerator.new.notification_occurred(:success)` | `# Not yet implemented — no UI::UINotificationFeedbackGenerator class.` |
| `:ui_selection_feedback_generator` | `UI::UISelectionFeedbackGenerator.new.selection_changed` | `# Not yet implemented — no UI::UISelectionFeedbackGenerator class.` |

Decision: **code-wins-rewrite (additional)**. None of these are catalog-wins-rename candidates (the rename would require designing the missing classes first, which is out of 10-pre.2 scope).

### Rows updated for iter-2 HIGH findings

#### `:toolbar_item_group` (HIGH-2)

- **Catalog crystal_api_shape (was, iter 1):** `toolbar.add_group(id: "edit", items: [...])  # API TBD; Toolbar today only ships flat add_item`
- **Why iter 1 failed:** Shape claimed `add_group` method that doesn't exist; carried embedded `API TBD` + `[...]` placeholders; the trailing backtick was technically present but immediately followed by hyphen-narrative that made the markdown brittle.
- **New crystal_api_shape:** `# Not yet implemented — UI::Toolbar (src/ui/views/toolbar.cr) only ships flat add_item(id:, label:, icon:) and has no group concept. Tracked in phase-10-pre-2-close.md "new gaps surfaced" item 3.`
- **Decision:** code-wins-rewrite.

#### `:toolbar_spacer` (HIGH-2)

- **Catalog crystal_api_shape (was, iter 1):** `toolbar.add_spacer(:flexible)  # API TBD; Toolbar today has no spacer/group concept` (missing trailing backtick).
- **Why iter 1 failed:** Same as `:toolbar_item_group` plus a real markdown rendering bug (missing closing backtick).
- **New crystal_api_shape:** `# Not yet implemented — UI::Toolbar (src/ui/views/toolbar.cr) only ships flat add_item(id:, label:, icon:) and has no spacer concept. Tracked in phase-10-pre-2-close.md "new gaps surfaced" item 3.`
- **Decision:** code-wins-rewrite.

#### `:palette_picker_style` (HIGH-3)

- **Catalog crystal_api_shape (was, iter 1):** `picker.style = UI::PickerStyle::Palette  # enum value not yet defined (B-012); add to src/ui/view.cr enum, then renderer support`
- **Why iter 1 failed:** Presented a fictitious enum value (`Palette`) as if it were a real API; iter 1 misclassified this as a "code-wins-rewrite" when it was actually a "new-design-needed" — the enum value literally must be added to `src/ui/view.cr` before the shape is valid.
- **New crystal_api_shape:** `# Not yet implemented — UI::PickerStyle enum (src/ui/view.cr:66-71) does not define Palette. Adding the value is tracked under B-012 picker styles.`
- **Decision:** code-wins-rewrite (corrected iter-1 misclassification — was effectively a fictional shape, not a real one with backlog footnote).

#### `:wheel_picker_style`, `:inline_picker_style` (HIGH-1 fallout)

- **Why iter 1 passed but iter 2 caught:** Iter 1's Rule B only rejected EXACT placeholder values. Both shapes carried inline `; renderer wiring TBD)` which embeds the banned `TBD` substring. Iter 2's tightened rule (substring-banned, case-insensitive) flagged both.
- **Fix:** Replaced "renderer wiring TBD" with "renderer wiring not yet shipped — tracked under B-012".
- **Decision:** in-place phrasing correction (no shape semantics change). Both rows remain "code-wins-rewrite" per iter 1's classification (enum value exists, only rendering missing).

### Pre-ruling deviation log (MED-1)

Codex flagged 4 specific rows where the brief's Deliverable 2 pre-rulings were paraphrased rather than carried verbatim. Source verification:

| Row | Brief pre-ruling | Catalog (source-accurate) | Source verification |
|---|---|---|---|
| `:toolbar` | `add_item(id: :save, label: "Save", icon: "checkmark") { ... }` (Symbol `id`) | `add_item(id: "save", label: "Save", icon: "checkmark") { ... }` (String `id`) | `src/ui/views/toolbar.cr:23,27` — `id : String`. Brief was wrong. |
| `:toolbar_item` | `toolbar.add_item(id:, label:, icon:) { ... }` (named-only signature form) | Concrete-args expansion: `toolbar.add_item(id: "save", label: "Save", icon: "checkmark") { ... }` | Concrete args are more copy-pasteable and match the `:toolbar` row's shape; signature-only form is less useful in a catalog reference. Kept concrete; brief's signature form was a stylistic preference. |
| `:menu` | `menu = UI::MenuButton.new("More"); menu.add_item(...)` (open-ended `...`) | `menu = UI::MenuButton.new("More"); menu.add_item(label: "Duplicate") { ... }` | `src/ui/views/menu_button.cr:48,52` — `add_item(label : String, icon : String? = nil, is_destructive : Bool = false, &block)`. Brief's `...` would have triggered iter-2 Rule B. Source signature has NO `id:` parameter. Catalog is source-accurate. |
| `:context_menu` | `menu = UI::ContextMenu.new; menu.add_item(id:, label:) { ... }` | `menu = UI::ContextMenu.new; menu.add_item(label: "Delete", is_destructive: true) { ... }` | `src/ui/views/context_menu.cr:28,38` — `add_item(label : String, icon : String? = nil, is_destructive : Bool = false, is_disabled : Bool = false, &block)`. NO `id:` parameter exists. Brief was wrong. |

**Verdict (per row):** Catalog stays source-accurate. Brief's pre-ruling was the imprecise side in 3 of 4 cases; in the 4th (`:toolbar_item`) the catalog elaborates the brief's signature form into a concrete example for usability. No catalog rewrite needed.

### MED-2 — `:presentation_drag_indicator` coverage_today correction

- **Iter-1 catalog claim:** `partial (… SwiftKit setShowsDragIndicator at swiftkit_overrides.cr:468-469; web honored …; android honored …)` — implied iOS/macOS were fully wired.
- **Codex verification:** `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SheetFacade.swift` has `.presentationDetents(Set(detents))` at line 91 but NO `.presentationDragIndicator(_:)` call anywhere. The bool stored by `swiftkit_overrides.cr:468-469` never reaches SwiftUI.
- **Iter-2 catalog (after):** `partial (… SwiftKit overrides STORES the bool via setShowsDragIndicator at swiftkit_overrides.cr:468-469 but the value is NOT yet applied to SwiftUI — no .presentationDragIndicator(_:) call in SheetFacade.swift. iOS/macOS drag indicator is therefore stored-not-applied …)`
- **Verdict:** `partial` is still the right classification (web + android DO apply; Crystal property exists; SwiftKit accepts the value) — only the iOS/macOS application step is missing.
- **Companion check — `:presentation_detents`:** `setDetents` IS applied in `SheetFacade.swift:91`. Iter-1 cite is accurate; no change needed.

### MED-3 — Appendix sweep (above)

Captured in the reclassification table at the top of this addendum.

### MED-4 — Backlog B-007 update

`docs/initiative-cross-platform-ui/architecture/intent-backlog.md` B-007 description now reflects that iOS/iPadOS detent wiring IS applied to SwiftUI, while Android stub echoes values without effect and macOS+web emit nothing. The companion drag-indicator stored-not-applied gap is also called out. No new backlog item created.

### LOW-1 — Close handoff "zero markers" precision

Acceptance bullet in `phase-10-pre-2-close.md` now scopes the "zero markers" claim to `architecture/intent-catalog.md`. Historical phase/handoff briefs that contain the literal marker phrase in narrative prose are out of Rule A's scope.

### Re-affirmed counts

After iter 2:

- 64 Class D rows (unchanged).
- 23 + 13 = 36 rows that received `crystal_api_shape` rewrites total across iter 1 + iter 2. (Iter 1 rewrote 23; iter 2 rewrote an additional 13 fictional shapes from the appendix table plus 4 rule-B-flagged rows. Some overlap with the 4 HIGH-fix rows already counted in iter 1.)
- 0 catalog-wins-rename.
- 0 new-design-needed escalations (the iter-2 reclassifications are all "honest gap" rewrites, not new design work).
- Lint: 7 violations (iter 2 mid-cycle) → 0 violations (final).

— Phase 10-pre.2 implementer, Claude Opus 4.7, 2026-05-25 (iter 2).
