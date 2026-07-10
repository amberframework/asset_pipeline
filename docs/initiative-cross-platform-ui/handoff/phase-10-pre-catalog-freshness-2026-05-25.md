# Phase 10-pre — Catalog ↔ Framework Freshness Check

**Date:** 2026-05-25
**Auditor:** general-purpose agent (read-only)
**Scope:** verify the 67 Phase 9 intent catalog rows against `src/ui/views/`.

## Headline

The catalog is **honest about what's missing** (most rows correctly read `coverage_today: missing`) but **dishonest about what's shipped**: it claims capabilities and API shapes that the source does not back. The single Class A intent (`:swipe_actions`) is the worst offender — 4 of 12 capabilities are factually false against the native renderers, and the named macOS/web-wide default widget (`UI::InlineActionRow`) does not exist anywhere in the source tree. The 9 Class C intents are entirely catalog-only — no framework code realizes them. Class D `crystal_api_shape` strings frequently misname the actual class or property (e.g. `UI::List` vs `UI::ListView`, `presentation_detents` vs `detents`).

## Missing widgets

| Catalog claim | Claimed Crystal class | File exists? | Severity |
|---|---|---|---|
| `:swipe_actions` macOS default | `UI::InlineActionRow` | NO (`src/ui/views/inline_action_row.cr` absent; zero matches for `InlineActionRow` in `src/`) | **HIGH** — Class A default unfulfilled; catalog flags this with "MISSING — see B-001" but `widget-intent-mapping.md` and `translation-matrix.md` should not advertise the name as the default |
| `:swipe_actions` web_wide default | `UI::InlineActionRow` | NO (same) | **HIGH** — same as above (B-002) |
| `:menu` | `UI::Menu` (with `<<`) | NO — only `UI::MenuButton` exists (`src/ui/views/menu_button.cr`) | MEDIUM — catalog row 1167 lists this as Class D but the class is missing |
| `:ui_menu` | `UI::UIMenu` | NO | LOW — coverage_today: missing in row 1184, so honest |
| `:ui_action` | `UI::UIAction` | NO | LOW — coverage_today: missing |
| `:full_screen_cover` | `UI::FullScreenCover` | NO | LOW — coverage_today: missing |
| `:inspector` | `UI::Inspector` | NO — only `PanelStyle::Inspector` enum value in `panel.cr:6` | LOW — coverage_today: missing |
| `:toolbar_item_group` | `UI::ToolbarItemGroup` | NO | LOW — coverage_today: missing |
| `:toolbar_spacer` | `UI::ToolbarSpacer` | NO | LOW — coverage_today: missing |
| `:navigation_path` | `UI::NavigationPath` | NO — `UI::NavigationCoordinator` exists but lacks that type | LOW — coverage_today: missing |

## Capability claim verification (Class A `:swipe_actions`)

Catalog (`intent-routing-candidates.md:20-49`) declares 12 capabilities. Source of truth: `src/ui/views/swipe_action_row.cr` + three renderers.

| # | Capability | Verdict | Evidence |
|---|---|---|---|
| 1 | `supports_edge :leading` | **FALSE** on native paths; VERIFIED on web | `swipe_action_row.cr:64` declares `leading_actions : Array(SwipeAction)`. UIKit renderer iterates only `view.trailing_actions` (`uikit_renderer.cr:3851`); AppKit iterates only `view.trailing_actions` (`appkit_renderer.cr:3819`). Android stub iterates neither (`android_renderer.cr:3152` — renders content only). Only web honors leading (`web_renderer.cr:2909-2911`). |
| 2 | `supports_edge :trailing` | VERIFIED | `swipe_action_row.cr:65`; rendered by UIKit (`uikit_renderer.cr:3851-3860`), AppKit (`appkit_renderer.cr:3819-3826`), web (`web_renderer.cr:2905-2907`). |
| 3 | `supports_role :destructive` | PARTIAL — honored only on iOS + web | The `SwipeAction` struct accepts `role : Symbol` (`swipe_action_row.cr:21,34`). UIKit forwards `role: action.role` to `UI::Button` (`uikit_renderer.cr:3852`). Web adds `--destructive` class (`web_renderer.cr:2942`). **AppKit creates `NSButton` with no role styling at all** (`appkit_renderer.cr:3819-3826`) — destructive tint is silently dropped. Android stub drops the role entirely. |
| 4 | `supports_role :default` | VERIFIED | Default branch of `role` symbol used unchanged. |
| 5 | `supports_disabled_actions true` | **UNBACKED** | The `SwipeAction` struct (`swipe_action_row.cr:19-39`) has no `disabled`/`is_disabled` property. No renderer applies a disabled state. Catalog asserts API parity with SwiftUI `Button.disabled()`; framework offers no surface for it. |
| 6 | `requires_row_identity_dispatch true` | **UNBACKED** | The `SwipeAction.on_tap` is a `Proc(Nil)` closure (`swipe_action_row.cr:23,33`). There is no row-identity argument threaded through — apps close over the row from the build site. This is fine semantically, but the catalog's framing ("callbacks need to know which row") is not enforced or surfaced by the API. |
| 7 | `requires_visible_or_keyboard_alternative true` | **UNENFORCED** | No framework code checks for this. Apps can ship a `SwipeActionRow` whose actions exist only behind the gesture. Catalog cites HIG `gestures.md:23,31` but the framework provides no lint, no runtime check, no alternative-path API. |
| 8 | `requires_accessibility_custom_actions true` | **FALSE** | Neither `SwipeActionRow` nor `SwipeAction` exposes `accessibility_custom_actions`. UIKit renderer sets `inner.accessibility_label = action.label` on the action button (`uikit_renderer.cr:3853`) but never wires `UIAccessibilityCustomAction` on the row itself. Catalog cites HIG `accessibility.md:134` as mandatory; framework does not satisfy it. |
| 9 | `supports_voiceover_actions true` | **FALSE** (corollary of #8) | No `accessibilityAction` modifier path. Same evidence as #8. |
| 10 | `supports_switch_control_activation true` | **UNBACKED** | No `focusable`-equivalent on the action buttons; web renderer marks them as `<button>` (which is keyboard-focusable by default — partial credit on web only). UIKit/AppKit make them tappable buttons but offer no Switch Control activation surface beyond what UIKit/AppKit default. |
| 11 | `supports_voice_control_labels true` | PARTIAL | UIKit sets `accessibility_label = action.label` (`uikit_renderer.cr:3853`); web sets `aria-label = action.label` (`web_renderer.cr:2946`). AppKit sets no accessibility label on `NSButton`. So Voice Control matches on iOS and web but not on macOS. |
| 12 | `does_not_conflict_with_system_gestures true` | **UNVERIFIABLE FROM CODE** | This is an empirical/test claim about the iOS swipe gesture not fighting the system back-gesture. UIKit uses `make_swipe_reveal_row` (`uikit_renderer.cr:3870`), an ObjC bridge whose source is in `objc_bridge.m`. The catalog claim cannot be confirmed without runtime testing of the bridge implementation, which is outside this audit's read-only scope. Flagging as unverified, not false. |

**Summary:** 2 VERIFIED, 3 PARTIAL, 4 FALSE, 2 UNBACKED, 1 UNVERIFIABLE. **The capability block does not accurately describe today's framework.** Honest re-statement: framework supports trailing-edge swipe with destructive tint on iOS + web, inline-button degradation on macOS, and content-only stub on Android. Leading edges, disabled actions, custom accessibility actions, and HIG-mandated alternative paths are missing surface area, not "shipped invariants."

## Class B accessibility coverage

Every `UI::View` subclass inherits `accessibility_label : String?` from `view.cr:132`. **No other Class B intent property is defined anywhere in `src/ui/`** — `grep` for `accessibility_hint`, `accessibility_value`, `accessibility_action`, `accessibility_rotor`, `accessibility_focused`, `accessibility_reduce_motion`, `dynamic_type`, `accessibility_increase_contrast`, `accessibility_differentiate`, `accessibility_voice_over`, `accessibility_switch`, `accessibility_voice_control`, `accessibility_full_keyboard`, `accessibility_element`, `accessibility_captions`, `accessibility_assistive`, `accessibility_dim_flashing` returns zero matches.

| Class B intent | Catalog coverage_today claim | Source-tree reality |
|---|---|---|
| `:accessibility_label` | "shipped (every `UI::View` exposes `accessibility_label : String`)" | **VERIFIED**: `view.cr:132 property accessibility_label : String? = nil`. Inherited by all 79 view types. Used by 9 view files for sub-component forwarding. |
| `:accessibility_hint` | "partial (some views; not universally exposed)" | **FALSE** — zero views expose any `accessibility_hint` property. The catalog says "some views"; the source says "no views." |
| `:accessibility_value` | "partial" | **FALSE** — zero views. |
| `:accessibility_action` | "missing (not surfaced on `UI::View`)" | VERIFIED — zero views. |
| `:accessibility_rotor` | "missing" | VERIFIED |
| `:accessibility_focused` | "missing" | VERIFIED |
| `:accessibility_reduce_motion` | "missing (no framework-level helper)" | VERIFIED — no `prefers_reduced_motion` helper in `src/ui/`. |
| `:dynamic_type_size` | "partial (design tokens carry semantic font sizes; runtime scaling not yet wired)" | PARTIALLY VERIFIED — `src/ui/design_tokens.cr` does carry semantic font scales (per CLAUDE.md token model). No runtime accessor on `View`. |
| `:accessibility_increase_contrast` | "missing" | VERIFIED |
| `:accessibility_differentiate_without_color` | "missing" | VERIFIED |
| `:accessibility_voice_over_enabled` | "partial (accessibility_label honors VoiceOver; full traits/value not exposed)" | VERIFIED |
| `:accessibility_switch_control` | "missing" | VERIFIED |
| `:accessibility_voice_control` | "missing" | VERIFIED (labels exist; Voice Control matching not explicitly tested) |
| `:accessibility_full_keyboard_access` | "partial" | VERIFIED — web `<button>` and standard elements are focusable by default; no Crystal-side helper. |
| `:accessibility_element` | "missing" | VERIFIED |
| `:accessibility_captions` | "missing" | VERIFIED |
| `:accessibility_assistive_access` | "missing" | VERIFIED |
| `:accessibility_dim_flashing_lights` | "missing" | VERIFIED |

**Worst gaps:** `:accessibility_hint` and `:accessibility_value` are catalogued as "partial" — they are in fact entirely missing. Every other "partial" claim has at least some indirect coverage; these two have none. Honest re-statement: 1 of 17 Class B intents is fully shipped (`:accessibility_label`); 3 are partial (`:dynamic_type_size`, `:accessibility_voice_over_enabled`, `:accessibility_full_keyboard_access`); 13 are missing.

## Class C system-integration realization

For each Class C intent, search results across `src/` for the named API:

| Intent | Catalog coverage_today | Framework code? |
|---|---|---|
| `:share_link` | "missing" | NONE. `ShareLink`/`UIActivityViewController`/`NSSharingService` mentioned only inside `src/ui/views/activity_view.cr` doc comments — not implemented. No share-bridge code in `src/asset_pipeline/`. **Note:** `UI::ActivityView` (`activity_view.cr`) is a *view model* with destinations + actions; its visitor uses these to draw an inline share-sheet preview. There is NO call to native sharing APIs from any renderer. |
| `:copyable` | "missing" | NONE. Zero matches for `UIPasteboard` / `NSPasteboard` / `clipboard` in `src/` except in catalog/doc files. |
| `:paste_button` | "missing" | NONE. |
| `:authorization_request` | "missing" | NONE. |
| `:open_url` | "missing" | NONE. No `openURL`, `NSWorkspace.open`, `Intent.ACTION_VIEW` in renderers. Web `link_button.cr` emits an anchor `<a href=...>`, which is the closest thing — but it's per-view markup, not a Class C bridge. |
| `:on_open_url` | "missing" | NONE. |
| `:ui_print_interaction_controller` | "missing" | NONE. |
| `:file_importer` | "missing" | NONE. Zero matches for `UIDocumentPicker`, `NSOpenPanel`, `fileImporter`. |
| `:file_exporter` | "missing" | NONE. Zero matches for `NSSavePanel`, `fileExporter`, `ACTION_CREATE_DOCUMENT`. |

**Verdict: Class C is 0/9 realized.** The entire class is catalog-only. The single Class C *view file* (`activity_view.cr`) is a presentation shell, not a system-integration bridge. This is consistent with catalog's stated `coverage_today: missing` on all 9 rows — but the existence of `UI::ActivityView` as a "Class C view" in `widget-intent-mapping.md` (row 28) creates the false impression that share-sheet integration is closer than it is.

> **⚠️ CORRECTION 2026-05-25** (added by architect after Codex brief-10-pre.1 review caught the error):
>
> The above verdict is **WRONG about `:share_link`**. The audit searched only `src/asset_pipeline/` and `src/ui/views/activity_view.cr` doc comments — it did NOT scan the renderers, which is where the actual bridge wiring lives. Verified post-correction:
>
> - `src/ui/renderers/uikit_renderer.cr:3408` — `LibObjCBridge.uiactivityview_present(...)` is called in the iOS `visit(UI::ActivityView)` path when `view.is_presented && has_share_payload`.
> - `src/ui/renderers/appkit_renderer.cr:3417` — `LibObjCBridge.nssharingservicepicker_present(...)` is called in the macOS `visit(UI::ActivityView)` path.
> - `src/ui/renderers/android_renderer.cr:2871` — `LibAndroidBridge.android_context_start_share_chooser(...)` is called in the Android visitor.
> - `src/ui/native/objc_bridge.m:2148-2245` — the actual ObjC implementations of `nssharingservicepicker_present` (NSSharingServicePicker) and `uiactivityview_present` (UIActivityViewController) live here.
>
> So `:share_link` is **SHIPPED on all three native platforms** plus web (`activity_view.cr` web visitor emits the share affordances inline). `UI::ActivityView` is a correctly-classified Class C view, NOT a presentational stub. The catalog row for `:share_link` should be `shipped (src/ui/renderers/uikit_renderer.cr:3408; appkit_renderer.cr:3417; android_renderer.cr:2871; src/ui/native/objc_bridge.m:2148-2245)`.
>
> **Class C corrected realization: 1/9 shipped (`:share_link`), 8/9 missing.** The other 8 Class C intents (`:copyable`, `:paste_button`, `:authorization_request`, `:open_url`, `:on_open_url`, `:ui_print_interaction_controller`, `:file_importer`, `:file_exporter`) remain honestly missing — verified post-correction by searching `src/ui/` AND `src/asset_pipeline/` for `Pasteboard`, `openURL:`, `NSWorkspace`, `UIDocumentPicker`, `NSOpenPanel`, `NSSavePanel`, `UIPrintInteraction`, `AVCaptureDevice` — zero matches.
>
> **Methodological lesson:** future framework-coverage audits MUST scan renderers + native bridges (`src/ui/renderers/`, `src/ui/native/`), not just `src/ui/views/` doc comments. The audit prompt for any future re-audit must specify these directories explicitly. See `[[audit-shortcut-trap]]` memory — this is the same failure mode (skip-the-real-code) in a new form.

## Class D spot checks (12 of 40)

| Intent | Catalog `crystal_api_shape` | Actual API on view class | Verdict |
|---|---|---|---|
| `:list` (catalog:483) | `list = UI::List.new; list << row_for(item) for each item` | Class is `UI::ListView` (`list_view.cr:5`), not `UI::List`. No `<<` operator. Items go through `sections : Array(Section)` (`list_view.cr:13`) or `flat(items:)` factory (`list_view.cr:41`). | **WRONG** — class name and operator both fictional. |
| `:list_row_separator` (catalog:500) | `row.list_row_separator = :visible \| :hidden` | `ListView#shows_separators : Bool` (`list_view.cr:32`) is list-level, not per-row. No per-row setter exists. | WRONG shape. |
| `:list_section_spacing` (catalog:517) | `list.list_section_spacing = 24.0` | Property does not exist on `ListView` or anywhere in `src/ui/`. | NOT IMPLEMENTED (consistent with `coverage_today: missing`). |
| `:refreshable` (catalog:551) | `list.refreshable = -> { state.reload_todos }` | `ListView` has no `refreshable` property. Zero matches. | NOT IMPLEMENTED. |
| `:searchable` (catalog:568) | `list.searchable = "Search todos..."` | `ListView` has no `searchable` property. `UI::SearchField` (`search_field.cr`) is a separate widget. | NOT IMPLEMENTED; conflates two designs. |
| `:on_move` (catalog:619) | `list.on_move = ->(from, to) { ... }` | `ListView` has no `on_move`. | NOT IMPLEMENTED. |
| `:on_delete` (catalog:636) | `list.on_delete = ->(indices) { ... }` | `ListView` has no `on_delete`. | NOT IMPLEMENTED. |
| `:sheet` (catalog:653) | `sheet = UI::Sheet.new(content); sheet.present(from: parent)` | `UI::Sheet.new(@content : View? = nil, *, @surface_style : Symbol = :auto)` (`sheet.cr:51`). `UI::SheetPresenter#present` (`sheet.cr:66`) takes NO arguments. There is no `present(from:)` API. | **WRONG** — `present(from:)` signature is fictional. |
| `:presentation_detents` (catalog:755) | `sheet.presentation_detents = [:medium, :large]` | Actual property: `Sheet#detents : Array(Symbol) = [:medium, :large]` (`sheet.cr:31`). | **WRONG name** — property is `detents`, not `presentation_detents`. |
| `:presentation_drag_indicator` (catalog:772) | `sheet.presentation_drag_indicator = :visible \| :hidden \| :automatic` | Actual property: `Sheet#shows_drag_indicator : Bool = true` (`sheet.cr:30`). Boolean, not three-valued symbol. | **WRONG name and shape**. |
| `:toolbar` (catalog:806) | `screen.toolbar = UI::Toolbar.new(items: [...])` | `UI::Toolbar.new(@title : String? = nil)` (`toolbar.cr:20`) — no `items:` keyword. Items added via `add_item(id:, label:, icon:, &block)` (`toolbar.cr:23`). | **WRONG init signature**. |
| `:toolbar_item` (catalog:823) | `toolbar << UI::ToolbarItem.new(label: "Save", on_tap: ->{...})` | `Toolbar` has no `<<`. `Toolbar::ToolbarItem` is a record with field `action : Proc(Nil)?` (`toolbar.cr:9`), not `on_tap`. | **WRONG operator and field name**. |
| `:tap_gesture` (catalog:1468) | `view.on_tap = -> { ... }` — claimed shipped on every view | `on_tap` exists ONLY on `Button` (`button.cr:93`), `IconButton` (`icon_button.cr:22`), `LinkButton` (`link_button.cr:8`), and `SwipeAction` struct (`swipe_action_row.cr:23`). Base `UI::View` has no `on_tap`. | **MISLEADING shipped claim** — works on 3 view types, not framework-wide. |
| `:context_menu` (catalog:1231) | `view.context_menu = UI::ContextMenu.new(items: [...])` | No `context_menu` setter on `UI::View`. `UI::ContextMenu.new` takes no args (`context_menu.cr:25-26`); items added via `add_item` (`context_menu.cr:28`). | **WRONG** — fictional setter and init signature. |
| `:menu_picker_style` (catalog:1044) | `picker.picker_style = :menu` | Actual property: `Picker#style : PickerStyle = PickerStyle::Menu` (`picker.cr:16`). Named `style`, not `picker_style`. Enum, not symbol. | **WRONG name and shape**. |
| `:palette_picker_style` (catalog:1095) | `picker.picker_style = :palette` | `PickerStyle` enum (`view.cr:67-71`) only defines `Wheel`, `Segmented`, `Menu`, `Inline`. **No `Palette` value.** | **NOT IMPLEMENTED** even at the enum level. |

**Pattern:** Where the catalog records a row as `coverage_today: missing` (`:refreshable`, `:on_move`, `:on_delete`, etc.), the absence is consistent with the source — those are honest aspirational shapes. But where the catalog says `shipped` (`:tap_gesture`) or pretends the shape exists today (`:list`, `:sheet`, `:toolbar`, `:presentation_detents`, `:presentation_drag_indicator`, `:menu_picker_style`, `:context_menu`), the catalog routinely misnames the class, misnames the property, invents methods (`present(from:)`), or invents operators (`<<` on `Toolbar` and `ListView`). The catalog appears to have been written against the *intended* future API, not the *current* code — and it never marks that distinction.

## Recommended Phase 10B priority adjustments

These are flags, not redesigns:

1. **P0 — `:swipe_actions` capability honesty.** The Class A capability block has 4 outright false claims. Either retract `requires_accessibility_custom_actions`, `supports_disabled_actions`, `supports_voiceover_actions`, and re-scope `supports_edge :leading` to "web only," OR ship the missing surface area immediately. The four-part contract is the keystone of the catalog; if one row of it is dishonest, the contract pattern is rhetorically dead.

2. **P0 — `:accessibility_hint`, `:accessibility_value`.** Catalog says "partial"; reality is zero coverage. Either move to "missing" honestly, or add the properties to `UI::View` base class — the same one-line treatment `accessibility_label` already gets. This is a 10-minute fix.

3. **P0 — Add `UI::InlineActionRow` OR retract the claim.** `widget-intent-mapping.md`, `translation-matrix.md`, and `intent-routing-candidates.md` all advertise `UI::InlineActionRow` as the macOS/web_wide default for `:swipe_actions`. Zero source backing. Either ship a 30-line type alias / wrapper today, or stop naming a non-existent class as the default.

4. **P1 — `crystal_api_shape` reconciliation pass.** Sweep all 40 Class D rows and align `crystal_api_shape` strings with actual class names / property names / init signatures. This is mechanical work — `UI::List` → `UI::ListView`, `presentation_detents` → `detents`, `shows_drag_indicator : Bool` (not three-valued symbol), `add_item(...)` instead of `<<`, etc. The catalog cannot be a source of truth for downstream agents until this is done.

5. **P1 — Mark `:tap_gesture` as `partial` not `shipped`.** Three view types, not framework-wide.

6. **P2 — Class C realization or honest exclusion.** Zero of 9 are realized. If Phase 10B is about widget routing, defer all 9 Class C rows to a later phase explicitly named "system integration bridges" and remove them from the Phase 9 catalog rather than carrying 9 catalog-only entries forward.

7. **P2 — `:palette_picker_style` is undefined even at the enum level.** Add a `PickerStyle::Palette` value (one-line enum addition) before any catalog row can reference it.

## Summary table

| Class | Catalog rows | Fully realized | Partially realized | Catalog-only (`missing` and source matches) | Lies (`shipped`/`partial` claims falsified against code) |
|---|---|---|---|---|---|
| A | 1 | 0 | 1 (`:swipe_actions` — trailing-only on iOS/web; macOS chrome-only; Android stub) | 0 | 1 (4 capability claims false; macOS/web_wide default class missing) |
| B | 17 | 1 (`:accessibility_label`) | 3 (`:dynamic_type_size`, `:accessibility_voice_over_enabled`, `:accessibility_full_keyboard_access`) | 11 | 2 (`:accessibility_hint`, `:accessibility_value` — claimed "partial," actually zero) |
| C | 9 | 1 (`:share_link` — corrected 2026-05-25; UI::ActivityView wires UIActivityViewController/NSSharingServicePicker/Intent.ACTION_SEND in renderers) | 0 | 8 (8/9 honestly `missing`) | **1 in the OPPOSITE direction — original audit falsely marked `:share_link` "missing" by skipping renderer + native bridge files; corrected above** |
| D | 40 | unknown without full sweep | unknown | most rows correctly `missing` | At least 9 of the 12 spot-checked rows misname classes / properties / operators (`:list`, `:list_row_separator`, `:sheet`, `:presentation_detents`, `:presentation_drag_indicator`, `:toolbar`, `:toolbar_item`, `:menu_picker_style`, `:context_menu`); `:tap_gesture` overstates shipped scope |
| **Total** | **67** | **~1** | **~4** | **~30** | **~12 spot-checked lies + extrapolated ~20 Class D shape errors** |

The catalog accurately catalogues *intentions*; it does not accurately catalogue *today's framework*. Phase 10B should either treat the catalog as a forward-looking spec (and label it as such everywhere) or do a reconciliation pass to bring `crystal_api_shape` and `coverage_today` into alignment with `src/ui/views/` as it actually stands on 2026-05-25.

— general-purpose auditor (read-only)
