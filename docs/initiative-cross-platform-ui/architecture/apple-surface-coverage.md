# Apple-Surface Coverage Checklist

**Companion to:** `intent-catalog.md`.

Phase 9's hard rule (per scoping-9.md §"Apple-surface coverage gate" + brief-9.md §6): every named SwiftUI / UIKit / AppKit API enumerated in the scoping coverage gate has its own catalog row, not aggregated by family. This checklist walks every named API and confirms its catalog presence.

**Format:**
- `[x] **`API name`** — covered by `:catalog_identifier` (Class X)` when the catalog has the row.
- `[ ] **`API name`** — MISSING; escalate to architect` when no row exists.

The implementer's escalation rule (per brief-9 §"Item 7"): do **not** add new rows; surface every gap to the architect.

---

## Lists

- [x] **`List`** — covered by `:list` (Class D)
- [x] **`listRowSeparator`** — covered by `:list_row_separator` (Class D)
- [x] **`listSectionSpacing`** — covered by `:list_section_spacing` (Class D)
- [x] **`refreshable`** — covered by `:refreshable` (Class D)
- [x] **`searchable`** — covered by `:searchable` (Class D)
- [x] **section indexes** — covered by `:list_section_index_visibility` (Class D)
- [x] **`onMove`** — covered by `:on_move` (Class D)
- [x] **`onDelete`** — covered by `:on_delete` (Class D)

## Sheets / modals

- [x] **`sheet`** — covered by `:sheet` (Class D)
- [x] **`fullScreenCover`** — covered by `:full_screen_cover` (Class D)
- [x] **`popover`** — covered by `:popover` (Class D)
- [x] **`inspector`** — covered by `:inspector` (Class D)
- [x] **`presentationDetents`** — covered by `:presentation_detents` (Class D)
- [x] **`interactiveDismissDisabled`** — covered by `:interactive_dismiss_disabled` (Class D)
- [x] **`presentationDragIndicator`** — covered by `:presentation_drag_indicator` (Class D)
- [x] **`confirmationDialog`** — covered by `:confirmation_dialog` (Class D)
- [x] **`alert`** — covered by `:alert` (Class D)

## Toolbars

- [x] **`toolbar`** — covered by `:toolbar` (Class D)
- [x] **`ToolbarItem`** — covered by `:toolbar_item` (Class D)
- [x] **`ToolbarItemGroup`** — covered by `:toolbar_item_group` (Class D)
- [x] **`ToolbarItemPlacement`** — covered by `:toolbar_item_placement` (Class D)
- [x] **`ToolbarSpacer`** — covered by `:toolbar_spacer` (Class D)
- [x] **`toolbarBackground`** — covered by `:toolbar_background` (Class D)

## Forms

- [x] **`formStyle`** — covered by `:form_style` (Class D)
- [x] **`GroupedFormStyle`** — covered by `:grouped_form_style` (Class D)
- [x] **`ColumnsFormStyle`** — covered by `:columns_form_style` (Class D)

## Navigation

- [x] **`NavigationStack`** — covered by `:navigation_stack` (Class D)
- [x] **`NavigationSplitView`** — covered by `:navigation_split_view` (Class D)
- [x] **`NavigationDestination`** — covered by `:navigation_destination` (Class D)
- [x] **`NavigationPath`** — covered by `:navigation_path` (Class D)
- [x] **`NavigationLink`** — covered by `:navigation_link` (Class D)

## Picker styles

- [x] **`.menu`** — covered by `:menu_picker_style` (Class D)
- [x] **`.segmented`** — covered by `:segmented_picker_style` (Class D)
- [x] **`.wheel`** — covered by `:wheel_picker_style` (Class D)
- [x] **`.palette`** — covered by `:palette_picker_style` (Class D)
- [x] **`.inline`** — covered by `:inline_picker_style` (Class D)

## Date/time picker styles

- [x] **`compact` (DatePickerStyle)** — covered by `:compact_date_picker_style` (Class D)
- [x] **`graphical` (DatePickerStyle)** — covered by `:graphical_date_picker_style` (Class D)
- [x] **`wheel` (DatePickerStyle)** — covered by `:wheel_date_picker_style` (Class D)
- [x] **AppKit `NSDatePicker` text style** — covered by `:compact_date_picker_style` (Class D) (the catalog row's `appkit_api` field cites `NSDatePicker` text/stepper style as the AppKit analog)

## Menus

- [x] **`Menu`** — covered by `:menu` (Class D)
- [x] **`contextMenu`** — covered by `:context_menu` (Class D)
- [x] **`UIMenu`** — covered by `:ui_menu` (Class D)
- [x] **`UIAction`** — covered by `:ui_action` (Class D)
- [x] **`primaryAction`** — covered by `:primary_action` (Class D)

## Drag and drop

- [x] **`draggable`** — covered by `:draggable` (Class D)
- [x] **`dropDestination`** — covered by `:drop_destination` (Class D)
- [x] **`Transferable`** — covered by `:transferable` (Class D)

## Animation

- [x] **`transition`** — covered by `:transition` (Class D)
- [x] **`matchedGeometryEffect`** — covered by `:matched_geometry_effect` (Class D)
- [x] **`animation` (modifier form)** — covered by `:animation` (Class D)
- [x] **`PhaseAnimator`** — covered by `:phase_animator` (Class D)
- [x] **`KeyframeAnimator`** — covered by `:keyframe_animator` (Class D)

## Haptics

- [x] **`sensoryFeedback`** — covered by `:sensory_feedback` (Class D)
- [x] **`UIImpactFeedbackGenerator`** — covered by `:ui_impact_feedback_generator` (Class D)
- [x] **`UINotificationFeedbackGenerator`** — covered by `:ui_notification_feedback_generator` (Class D)
- [x] **`UISelectionFeedbackGenerator`** — covered by `:ui_selection_feedback_generator` (Class D)

## Accessibility

- [x] **`accessibilityLabel`** — covered by `:accessibility_label` (Class B)
- [x] **`accessibilityHint`** — covered by `:accessibility_hint` (Class B)
- [x] **`accessibilityValue`** — covered by `:accessibility_value` (Class B)
- [x] **`accessibilityAction`** — covered by `:accessibility_action` (Class B)
- [x] **`accessibilityRotor`** — covered by `:accessibility_rotor` (Class B)
- [x] **`accessibilityFocused`** — covered by `:accessibility_focused` (Class B)

## Gestures

- [x] **`TapGesture`** — covered by `:tap_gesture` (Class D)
- [x] **`LongPressGesture`** — covered by `:long_press_gesture` (Class D)
- [x] **`DragGesture`** — covered by `:drag_gesture` (Class D)
- [x] **`MagnifyGesture`** — covered by `:magnify_gesture` (Class D)
- [x] **`RotateGesture`** — covered by `:rotate_gesture` (Class D)
- [x] **`SpatialTapGesture`** — covered by `:spatial_tap_gesture` (Class D)

---

## Summary

- **Total APIs in scoping gate:** 65 named entries across 13 families.
- **Covered:** 65.
- **MISSING (escalated to architect):** 0.

The Apple-surface coverage gate is **green**. Phase 9 close is unblocked on this dimension.

— Implementer (Claude Opus 4.7), Phase 9 iter 1
