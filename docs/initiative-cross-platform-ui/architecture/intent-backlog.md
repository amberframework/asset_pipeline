# Intent Backlog

**Companion to:** `intent-catalog.md`, `translation-matrix.md`.

> **Frozen 2026-05-25 by Phase 10-pre.1.** **Tracked entries: 36** (preserves ID history including closed B-026 and deprecated B-021). **Active work items: 34** (= 36 − closed B-026 − deprecated B-021†). Class breakdown by tracked entry: 4 A (B-001/B-002/B-035/B-036) / 7 B (B-020/B-021†/B-022/B-023/B-024/B-025/B-037) / 8 C (B-026 closed + B-027–B-034 open) / 17 D (B-003–B-019). Priority reconciliation applied per freshness audit + 2026-05-25 correction.

Class A + Class D intents where no shipped widget covers the per-platform default. Buildable backlog for Phase 10+ implementation.

Each entry: ID, intent, platform with the gap, what's missing, rough size estimate (S/M/L), priority (P0/P1/P2).

---

## Class A gaps

### B-001 — `:swipe_actions` macOS default

- **Intent:** `:swipe_actions`
- **Platform:** macOS
- **Gap:** No `UI::InlineActionRow` class exists. Today `UI::SwipeActionRow` is used and the AppKit renderer emits inline trailing buttons (`src/ui/renderers/appkit_renderer.cr:3801-3826`), but the widget name is misleading.
- **Action:** Create `UI::InlineActionRow` as the named macOS default. Move the AppKit inline-button rendering logic from `UI::SwipeActionRow`'s renderer into `UI::InlineActionRow`. Migrate the override registry to use the new class.
- **Size:** M. Renderer move + new class + spec coverage + Voyager migration.
- **Priority:** **P0** (promoted from P1 by Phase 10-pre.1 freshness audit — the catalog's only Class A intent advertises a default class that does not exist; this is a load-bearing dishonesty that 10B.1a must resolve before any other 10B work).

### B-002 — `:swipe_actions` web_wide default

- **Intent:** `:swipe_actions`
- **Platform:** web_wide
- **Gap:** Same as B-001 but for desktop web. No native swipe gesture exists; inline buttons with hover affordance are idiomatic.
- **Action:** Extend `UI::InlineActionRow` to the web renderer. Hover state shows row backdrop + trailing buttons. Mobile-web (`web_narrow`) continues to use `UI::SwipeActionRow`.
- **Size:** M.
- **Priority:** **P0** (promoted from P1; same justification as B-001).

### B-035 — `:swipe_actions` Android proper integration

- **Intent:** `:swipe_actions`
- **Platform:** Android
- **Gap:** `src/ui/renderers/android_renderer.cr:3148-3152` is explicitly a stub that renders only the content view, omitting the swipe gesture + trailing actions. Comment notes: "Android proper integration is deferred per the brief."
- **Action:** Wire Material 3 `SwipeToDismissBox` (or equivalent Compose foundation `swipeable` modifier) into the Android renderer's `visit(UI::SwipeActionRow)` method. Honor `trailing_actions` + `leading_actions` properties. Respect destructive role for color tinting.
- **Size:** M.
- **Priority:** P1 if Android is in scope for a near-term release; P2 if Android remains deferred. **Confirmed P1 by Phase 10-pre.1.**

### B-036 — `:swipe_actions` capability honesty (NEW — Phase 10-pre.1)

- **Intent:** `:swipe_actions`
- **Platforms with gap:** All native (iOS/iPadOS/macOS/Android); web partial.
- **Gap:** The Phase 9 capability block in `intent-routing-candidates.md` declared 12 capabilities; the Phase 10-pre.1 trim moved 6 of them to "Planned (Phase 10B targets)" because they were UNBACKED. Specifically:
  - `supports_disabled_actions` — `SwipeAction` struct (`src/ui/views/swipe_action_row.cr:19-39`) has no `disabled` / `is_disabled` field; no renderer applies disabled state.
  - `requires_row_identity_dispatch` — `SwipeAction.on_tap` is a `Proc(Nil)` closure (`src/ui/views/swipe_action_row.cr:23,33`) with no row-identity argument threaded through.
  - `requires_accessibility_custom_actions` + `supports_voiceover_actions` — no `UIAccessibilityCustomAction` is wired on `SwipeActionRow` or `SwipeAction`. HIG `accessibility.md:134` mandates this; framework does not satisfy it. Phase 10B.2b target.
  - `supports_edge :leading` (native) — iOS/macOS/Android iterate only `trailing_actions` (`src/ui/renderers/uikit_renderer.cr:3851`, `src/ui/renderers/appkit_renderer.cr:3819`, `src/ui/renderers/android_renderer.cr:3152`). Only web honors leading (`src/ui/renderers/web_renderer.cr:2909-2911`).
  - `supports_role :destructive` (full) — AppKit drops the role (`src/ui/renderers/appkit_renderer.cr:3819-3826`); Android stub drops it; iOS + web only.
  - `requires_visible_or_keyboard_alternative` — declared but unenforced (no lint, no runtime check).
- **Action:** 10B.1b implementation slice — add a `disabled : Bool` field to `SwipeAction`; honor it across renderers. Add a row-identity argument to `on_tap`. Extend the iOS/macOS/Android renderers to iterate `leading_actions`. Wire destructive tint on AppKit (NSButton.tintColor) and Android (Compose Button colors). The visible-or-keyboard-alternative invariant is delivered by 10A as a LSP rule.
- **Size:** M (excluding the LSP rule, which is 10A).
- **Priority:** **P0**. The keystone Class A contract pattern is rhetorically dead if even one declared capability is dishonest — Phase 10B cannot proceed without this bundle.

---

## Class D gaps (high priority)

### B-003 — `:refreshable` integration

- **Intent:** `:refreshable`
- **Platforms with gap:** All (no `UI::ListView.refreshable=` property exists today).
- **Gap:** `UI::ListView` (`src/ui/views/list_view.cr:5`) has no `refreshable` property. Authors cannot wire pull-to-refresh.
- **Action:** Add `refreshable : Proc(Nil)?` to `UI::ListView` (or `UI::ScrollView`?). UIKit renderer wires `UIRefreshControl`. Android renderer wires `PullRefreshContainer`. macOS renderer emits a refresh `UI::ToolbarItem` automatically. Web renderer custom JS OR toolbar fallback.
- **Size:** L. Cross-platform renderer work + native gesture handling + CI test coverage.
- **Priority:** P0 if mobile-list apps are a near-term target; P1 otherwise.

### B-004 — `:searchable` integration

- **Intent:** `:searchable`
- **Platforms with gap:** All (no integration).
- **Gap:** No `UI::ListView.searchable=` integration. Apps that want to surface search in the navigation toolbar have to write per-renderer code.
- **Action:** Add `searchable : String?` (placeholder) + `on_search : Proc(String, Nil)?` properties to `UI::ListView`. UIKit `UISearchController` integration. AppKit `NSSearchToolbarItem`. Android Material `SearchBar`. Web `<input type="search">`.
- **Size:** L.
- **Priority:** P1.

### B-005 — `:on_move` (reorder) integration

- **Intent:** `:on_move`
- **Platforms with gap:** All.
- **Gap:** `UI::ListView` has no `on_move` property. Drag-to-reorder is not exposed at the framework level.
- **Action:** Add `on_move : Proc(Int32, Int32, Nil)?` to `UI::ListView`. UIKit `UITableView.isEditing` + reorder. AppKit drag-source/destination protocols. Web HTML5 draggable.
- **Size:** L.
- **Priority:** P2 unless an app needs it; the widget gap matters less for Voyager-style demos.

### B-006 — `:context_menu` web-wide rendering

- **Intent:** `:context_menu`
- **Platforms with gap:** web_wide (partial).
- **Gap:** `UI::ContextMenu` exists but `UI::ContextMenuWithWebFallback` is the explicit web-fallback class per the Tier 3 conventions. The framework should be able to render context menus natively on right-click for web_wide without requiring the fallback class.
- **Action:** Extend web renderer to bind `contextmenu` event on the parent view and render the menu as a positioned overlay. Keep `ContextMenuWithWebFallback` as the explicit-opt-in for backwards compat.
- **Size:** S.
- **Priority:** P2.

### B-007 — `:presentation_detents` on Sheet

- **Intent:** `:presentation_detents`
- **Platforms with gap:** macos+web (full); iOS/iPadOS + Android wired partially.
- **Gap:** `UI::Sheet#detents : Array(Symbol)` ships at `src/ui/views/sheet.cr:31`. Per Phase 10-pre.2 audit: iOS/iPadOS wiring lands via SwiftKit's `setDetents` (`src/ui/native/swiftkit_overrides.cr:464-466`) and is APPLIED to SwiftUI as `.presentationDetents(_:)` (`swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SheetFacade.swift:91`). Android stub at `src/ui/renderers/android_renderer.cr:1865` echoes the values but does not produce a real detented surface. macOS and web emit no detent behavior at all. The companion `presentation_drag_indicator` row is stored-not-applied on iOS/macOS (SwiftKit overrides records the bool but `SheetFacade.swift` never calls `.presentationDragIndicator(_:)`) — see catalog `:presentation_drag_indicator`.
- **Action:** Either keep `detents` as the public name (catalog `crystal_api_shape` already settled there) or add an alias. iOS/iPadOS is the only platform with real detent behavior today; B-007 now scopes to: (1) wire macOS sheet to a documented "no detents" fallback or to NSPanel sizing, (2) make Android `ModalBottomSheet` honor the detents array beyond echoing, (3) decide on web detent semantics, (4) fix the drag-indicator stored-not-applied gap by adding the SwiftUI modifier call in `SheetFacade.swift`.
- **Size:** M.
- **Priority:** P1.

---

## Class D gaps (lower priority)

### B-008 — Form modifiers
`:form_style`, `:grouped_form_style`, `:columns_form_style`. No `UI::Form.form_style=` integration today. Size: M. Priority: P2.

### B-009 — Inspector view
`:inspector`. No `UI::Inspector` view. Size: L (cross-platform split-view extension). Priority: P2.

### B-010 — Full-screen cover
`:full_screen_cover`. No `UI::FullScreenCover` view. Size: S. Priority: P2.

### B-011 — Toolbar modifiers
`:toolbar_item_group`, `:toolbar_background`, `:toolbar_spacer`. Partial coverage today (`toolbar_item_placement` downgraded to missing in Phase 10-pre.1; no `placement` field on `record ToolbarItem`). Size: S each. Priority: P2.

### B-012 — Picker styles
`:wheel_picker_style`, `:palette_picker_style`, `:inline_picker_style`. Currently `UI::Picker` has `style : PickerStyle` (`src/ui/views/picker.cr:16`) but the `PickerStyle` enum (`src/ui/view.cr:67-71`) only defines `Wheel`, `Segmented`, `Menu`, `Inline` — no `Palette` value. Size: M total. Priority: P2.

### B-013 — Date picker styles
`:graphical_date_picker_style`, `:wheel_date_picker_style`. `UI::DatePicker` has no style property. Size: M. Priority: P2.

### B-014 — Drag and drop (full)
`:draggable`, `:drop_destination`, `:transferable`. No drag-drop integration in any view. Size: L. Priority: P2.

### B-015 — Animation modifiers
`:transition`, `:matched_geometry_effect`, `:animation`, `:phase_animator`, `:keyframe_animator`. No animation modifier integration. Size: L. Priority: P2.

### B-016 — Haptics
`:sensory_feedback`. No `view.sensory_feedback=` property. Size: S. Priority: P2.

### B-017 — Search suggestions / scopes
`:search_suggestions`, `:search_scopes`. Depend on B-004 landing first. Size: M total. Priority: P2.

### B-018 — Long-press as standalone
`:long_press_gesture`. Currently only used internally by ContextMenu. Size: S. Priority: P2.

### B-019 — Magnify / Rotate gestures
`:magnify_gesture`, `:rotate_gesture`. No view-level integration. Size: M. Priority: P2.

---

## Class B gaps (accessibility — significant)

### B-020 — Accessibility action surface

- **Intent:** `:accessibility_action`
- **Gap:** No `view.accessibility_actions=` property. Critical for swipe-action rows per HIG `accessibility.md:134`.
- **Action:** Add `accessibility_actions : Array(UI::AccessibilityAction)?` to base `UI::View`. UIKit `UIAccessibilityCustomAction`. AppKit `NSAccessibilityCustomAction`.
- **Size:** M.
- **Priority:** **P0** (confirmed by Phase 10-pre.1 freshness audit). HIG-mandated for any view that uses gestures.

### B-021 — Accessibility hint / value surfacing (DEPRECATED by B-037)

- **Intent:** `:accessibility_hint`, `:accessibility_value`
- **Status:** Superseded by B-037 (NEW Phase 10-pre.1 amendment). B-021 originally described the same surface but at P1; B-037 escalates to P0 because the Phase 10-pre.1 audit confirmed the catalog's previous "partial" claim was FALSE — zero views expose either property today.

### B-022 — Reduce-motion contract

- **Intent:** `:accessibility_reduce_motion`
- **Gap:** No framework helper for querying `prefersReducedMotion`. Authors have to know per-platform APIs.
- **Action:** Add `UI::Environment.reduce_motion? : Bool` that reads the platform setting. Document the contract that animation modifiers should consult this.
- **Size:** S.
- **Priority:** P1.

### B-023 — Dynamic-type runtime scaling

- **Intent:** `:dynamic_type_size`
- **Gap:** Design tokens (`src/ui/design_tokens.cr:537,643,1048`) carry semantic font sizes but runtime scaling is not wired through to renderers.
- **Action:** Renderers honor system text-size preference and scale `UI::Font` sizes proportionally.
- **Size:** M.
- **Priority:** P1.

### B-024 — Full keyboard access

- **Intent:** `:full_keyboard_access`
- **Gap:** Partial. Web `<button>` / `<input>` emitted by `src/ui/renderers/web_renderer.cr:159,294` are focusable by default; `src/ui/view.cr:132` is the only AX property on base `UI::View` — no `focusable` / `focus_effect` Crystal-side helper.
- **Action:** Audit every interactive widget for keyboard focusability; add focus-ring rendering; document the contract.
- **Size:** L.
- **Priority:** P1.

### B-025 — VoiceOver landmark grouping

- **Intent:** `:accessibility_element`
- **Gap:** No `accessibility_element` (children:) grouping property on container views; VoiceOver users hear leaf elements.
- **Action:** Add `accessibility_element_children : Symbol?` (or equivalent) to container views. Renderers map to platform grouping.
- **Size:** M.
- **Priority:** P1.

### B-037 — `accessibility_hint` + `accessibility_value` surfacing (NEW — Phase 10-pre.1)

- **Intent:** `:accessibility_hint`, `:accessibility_value`
- **Gap:** Phase 9 catalog claimed "partial" for both; Phase 10-pre.1 audit confirmed zero views expose either property. `src/ui/view.cr:132` exposes only `accessibility_label`; no `accessibility_hint` / `accessibility_value` exists anywhere in `src/ui/views/`. Two of the catalog's three Class B "partial" claims are factually zero — the catalog row pattern is rhetorically dead if Class B's most-cited gap stays unbacked.
- **Action:** 10B.2a implementation slice — add `accessibility_hint : String? = nil` and `accessibility_value : String? = nil` to base `UI::View` (same one-line treatment as the existing `accessibility_label`). UIKit renderer maps to `UIView.accessibilityHint` / `UIView.accessibilityValue`. AppKit maps to `NSView.accessibilityHelp` / `accessibilityValue`. Android maps via Compose `Modifier.semantics`. Web maps to `aria-describedby` (with an internal description span) and `aria-valuenow` / `aria-valuetext`.
- **Size:** S (one-line property additions + four-renderer pass + spec).
- **Priority:** **P0**. The catalog row pattern's credibility depends on this landing in 10B.2a.

---

## Class C gaps (system integration — 8 of 9 missing)

8 of 9 Class C intents are missing — no Crystal API surfaces today. `:share_link` (B-026) is **SHIPPED and CLOSED** as of Phase 10-pre.1.

| ID | Intent | Size | Priority | Status |
|---|---|---|---|---|
| ~~B-026~~ | ~~`:share_link`~~ | — | — | **CLOSED 2026-05-25 by Phase 10-pre.1.** Codex caught the original freshness audit's false-negative; re-audit verified `UI::ActivityView` wires `UIActivityViewController` (iOS), `NSSharingServicePicker` (macOS), and `Intent.ACTION_SEND` (Android) via the renderers + native bridges. See `phase-10-pre-1-class-c-reaudit-2026-05-25.md`. |
| B-027 | `:copy_to_clipboard` (`:copyable`) | S | P1 | open — zero `UIPasteboard` / `NSPasteboard` / `ClipboardManager` matches in `src/`. |
| B-028 | `:paste_from_clipboard` (`:paste_button`) | S | P2 | open — same as B-027. |
| B-029 | `:request_permission` (`:authorization_request`) | L | P1 (camera, photos); P2 (others) | open — zero `AVCaptureDevice.requestAccess` / `PHPhotoLibrary` / `CLLocationManager` matches in `src/`. |
| B-030 | `:open_url` | S | P1 | open — zero `openURL:` / `NSWorkspace.open` matches in `src/`. |
| B-031 | `:open_deep_link` (`:on_open_url`) | M | P2 | open — zero `application:openURL:options:` matches. |
| B-032 | `:print_document` (`:ui_print_interaction_controller`) | M | P2 | open — zero `UIPrintInteractionController` / `NSPrintInfo` matches. |
| B-033 | `:file_importer` | M | P2 | open — zero `UIDocumentPickerViewController` / `NSOpenPanel` matches. |
| B-034 | `:file_exporter` | M | P2 | open — zero `NSSavePanel` / `UIDocumentInteractionController` matches. |

These 8 ship as `UI::System.*` module-level functions (single Crystal API, renderer translates to platform) per Phase 10B.3.x.

---

## Total backlog (reconciled 2026-05-25 by Phase 10-pre.1)

| Class | Count | P0 | P1 | P2 |
|---|---|---|---|---|
| A | 4 (B-001, B-002, B-035, B-036) | 3 (B-001, B-002, B-036) | 1 (B-035) | 0 |
| B | 7 (B-020, B-021†, B-022, B-023, B-024, B-025, B-037) | 2 (B-020, B-037) | 5 | 0 |
| C | 8 (B-026 closed; B-027–B-034 open) | 0 | 3 (B-027, B-029, B-030) | 5 |
| D | 17 (B-003–B-019) | 0 | 4 | 13 |
| **Tracked** | **36** | **5** | **13** | **18** |

**Active (excluding deprecated B-021 and closed B-026): 34 work items.**

† B-021 is deprecated and superseded by B-037 — counted in the class total for ID-history continuity but does not contribute work.

**P0 (5):** B-001, B-002 (Class A defaults — Phase 10B.1a), B-020 (accessibility actions — HIG-mandated for swipe rows; Phase 10B.2b), B-036 (`:swipe_actions` capability honesty — Phase 10B.1b), B-037 (`accessibility_hint` + `accessibility_value` surfacing — Phase 10B.2a).
**P1 (13):** Mostly Voyager-compliance work + key Class C surfaces.
**P2 (18):** Nice-to-haves, ships as needed.

**Changes from Phase 9 close to Phase 10-pre.1 (2026-05-25):**
- B-001 P1 → **P0** (Class A's only intent advertises a default class that does not exist).
- B-002 P1 → **P0** (same).
- B-035 confirmed **P1** (was floating P1/P2).
- B-026 **CLOSED** (`:share_link` shipped — Codex catch + Class C re-audit).
- **B-036 added P0** (`:swipe_actions` capability honesty bundle).
- **B-037 added P0** (accessibility_hint + accessibility_value surfacing — supersedes B-021).
- B-021 deprecated by B-037.

— Architect (Claude Opus 4.7); reconciled by Phase 10-pre.1 implementer 2026-05-25.
