# Phase 9 — Apple-Native Intent Catalog + Tier 2 Translation Contract (SCOPING v3)

**Date:** 2026-05-25
**Status:** SCOPING v3 — addresses Codex antagonist+validator v2 critique. Codex stays in-parallel as antagonist on every iteration per owner directive.
**Branch:** to be cut as `phase-09-intent-catalog`.
**Predecessor:** Phase 8 collective review.
**Planning artifacts:** `scoping-9.v1.md`, `scoping-9.v2.md`, `coplan-9-codex-1.md`, `codex-antagonist-9-v2.md`.

---

## The problem being solved

Phase 8 closed the ergonomic MVC API. The library has 80 `UI::View` types in `src/ui/views/` and a tier model (CLAUDE.md:148-160). The `component-mapping-matrix` skill catalogues views per platform.

**What's missing:**

1. **An Apple-native intent catalog** that names what each user behavior IS in SwiftUI / UIKit / AppKit terminology. The framework's whole reason for existing is to let Crystal authors get idiomatic Apple-platform UI; the catalog must speak Apple's vocabulary verbatim, not generic substitutes.
2. **A documented cross-platform translation per intent** for the small set of behaviors where Apple's idiom differs materially from web/Android (e.g., `swipeActions` on a list row).
3. **An override mechanism** so authors can pick a non-default translation when their UX needs it.

The gap surfaced when the owner described "the Mail-app swipe behavior" and we had to *describe behavior* to discover that `UI::SwipeActionRow` already shipped. SwiftUI calls this `swipeActions(edge:allowsFullSwipe:content:)`; UIKit calls it `UISwipeActionsConfiguration`. Both names existed before our widget did. The catalog should have made the existing widget findable under those exact names.

## Owner directive — the binding constraint

**Speak Apple. Don't invent.** Every intent in the catalog must:
- Have a `primary_apple_name` field that matches a SwiftUI modifier / UIKit type / AppKit type / HIG page name verbatim.
- Use the snake_case form of that Apple name as its Crystal intent identifier UNLESS no Apple canonical name exists (documented exception, reviewed by Codex antagonist).
- Cite at least one of: SwiftUI API, UIKit API, AppKit API, HIG page slug.

A "generic" intent name like `:actionable_row` when SwiftUI says `swipeActions` is a planning failure. The repo's own comments are already ahead of this — `src/ui/views/swipe_action_row.cr` describes itself in SwiftUI vocab — the catalog has to catch up.

## Four classes of intent (UPDATED — Class D added per Codex BLOCKER 2)

Not all intents fit one model. The catalog classifies every entry as exactly one of:

### Class A — Widget-routing intents
Framework picks a *materially different concrete `UI::View` class* per platform. Gets the four-part contract (capabilities + defaults + override_registry + resolver).

**Class A is small.** Codex prediction: 5-10 intents total. Examples:
- `:swipe_actions` — SwiftUI `swipeActions(edge:allowsFullSwipe:content:)` / UIKit `UISwipeActionsConfiguration`. Default: iOS → swipe-reveal; macOS → inline buttons; web-wide → inline buttons; web-narrow → swipe-reveal.

That's likely the ONLY canonical Class A intent. Other candidates fold into Class D or stay as concrete widgets.

### Class B — Framework-contract intents (cross-cutting)
Every widget must honor; not widget-substitutable. Accessibility + reduced-motion + system-keyboard live here.

Examples (Apple-native names):
- `:accessibility_label` / `:accessibility_hint` / `:accessibility_value`
- `:accessibility_focused` (SwiftUI `accessibilityFocused`)
- `:accessibility_rotor` (SwiftUI `AccessibilityRotor`)
- `:accessibility_action` (SwiftUI `accessibilityAction` — critical for swipe-action rows per HIG `accessibility.md:130-138`)
- `:respect_reduced_motion` (SwiftUI `@Environment(\.accessibilityReduceMotion)`)
- `:dynamic_type` (SwiftUI scaled fonts; UIKit `UIFontMetrics`)
- `:full_keyboard_access` (HIG `accessibility.md:152`)
- `:voiceover_landmark` (SwiftUI `accessibilityElement(children: .contain)` + traits)

These are invariants every renderer enforces. NOT registry entries; documentation contracts.

### Class C — System-integration intents (single API, platform implementation varies)
One author-facing API, different native implementations. Examples:
- `:share_sheet` (SwiftUI `ShareLink` / UIKit `UIActivityViewController` / NSKit `NSSharingService` / Android `Intent.ACTION_SEND` / Web `navigator.share`)
- `:copy_to_clipboard` / `:paste_from_clipboard` (UIKit `UIPasteboard` / NSKit `NSPasteboard` / Web `navigator.clipboard`)
- `:request_permission` (camera, microphone, notifications, location, contacts)
- `:open_url` (UIKit `UIApplication.shared.open(_:)` / NSKit `NSWorkspace.open(_:)` / web `window.location`)
- `:print_document` (UIKit `UIPrintInteractionController` / NSKit `NSPrintOperation` / web `window.print`)

These need `UI::View`-shaped wrappers eventually but in 9A are documented as future Crystal API surfaces.

### Class D — Native modifier intents (NEW per Codex BLOCKER 2)
SwiftUI modifiers that configure existing widgets/presentations without substituting them. NO four-part contract — these are direct Crystal-to-SwiftUI-modifier translations.

Examples (every name is Apple verbatim):

**List modifiers:**
- `:refreshable` (SwiftUI `.refreshable` / UIKit `UIRefreshControl`)
- `:searchable` (SwiftUI `.searchable` / UIKit `UISearchController`)
- `:search_suggestions` / `:search_scopes`
- `:list_row_separator` / `:list_section_spacing`
- `:on_move` (SwiftUI `.onMove` / UIKit table reorder / AppKit table drag/drop)
- `:on_delete` (SwiftUI `.onDelete`)
- `:section_index_label` / `:list_section_index_visibility`

**Sheet/modal modifiers:**
- `:sheet` (SwiftUI `.sheet`)
- `:full_screen_cover` (SwiftUI `.fullScreenCover`)
- `:popover` (SwiftUI `.popover`)
- `:inspector` (SwiftUI `.inspector`)
- `:alert` / `:confirmation_dialog`
- `:presentation_detents` (SwiftUI `.presentationDetents`)
- `:presentation_drag_indicator`
- `:interactive_dismiss_disabled`

**Toolbar modifiers:**
- `:toolbar` (SwiftUI `.toolbar`)
- `:toolbar_item` (`ToolbarItem`)
- `:toolbar_item_group` (`ToolbarItemGroup`)
- `:toolbar_item_placement` (`ToolbarItemPlacement`)
- `:toolbar_background`
- `:toolbar_spacer`

**Navigation modifiers:**
- `:navigation_stack` (SwiftUI `NavigationStack`)
- `:navigation_split_view` (SwiftUI `NavigationSplitView` / UIKit `UISplitViewController` / NSKit `NSSplitViewController`)
- `:navigation_destination`
- `:navigation_path`
- `:navigation_link`

**Form modifiers:**
- `:form_style` (SwiftUI `.formStyle`)
- `:grouped_form_style` / `:columns_form_style`

**Picker styles:**
- `:picker_menu_style` / `:picker_segmented_style` / `:picker_wheel_style` / `:picker_palette_style` / `:picker_inline_style`

**Date/time picker styles:**
- `:date_picker_compact_style` / `:date_picker_graphical_style` / `:date_picker_wheel_style`

**Menus:**
- `:menu` (SwiftUI `Menu`)
- `:context_menu` (SwiftUI `.contextMenu` / UIKit `UIContextMenuConfiguration`)
- `:primary_action` (`primaryAction` on Menu)

**Drag/drop:**
- `:draggable` / `:drop_destination` / `:transferable` (Transferable protocol)

**Animation:**
- `:transition` (SwiftUI `.transition`)
- `:matched_geometry_effect`
- `:animation` (modifier form)
- `:phase_animator` (iOS 17+)
- `:keyframe_animator`

**Haptics:**
- `:sensory_feedback` (SwiftUI `.sensoryFeedback` / UIKit `UIImpactFeedbackGenerator`)

**Class D documentation shape** — not the four-part contract. Each Class D entry has:
- `primary_apple_name`
- `swiftui_api`, `uikit_api`, `appkit_api`, `hig_page`
- `crystal_api_shape` — the Crystal method/property signature that emits this modifier 1:1.
- `platforms` — list of platforms where this is honored; web/Android may be no-ops or polyfilled.
- `coverage_today` — shipped / partial / missing in the codebase.

## Catalog row schema (HARD REQUIREMENT per Codex MEDIUM 1)

Every catalog row MUST have:

```yaml
intent_identifier_crystal: :swipe_actions
primary_apple_name: swipeActions
class: A
tier: 2
swiftui_api: swipeActions(edge:allowsFullSwipe:content:)
uikit_api: UISwipeActionsConfiguration
appkit_api: NSTableView row actions (NSTableViewRowActionStyle)
hig_page: gestures.md, accessibility.md
android_equivalent: SwipeToDismissBox (Material 3)
web_equivalent: CSS swipe libraries / inline buttons fallback
coverage_today: shipped (UI::SwipeActionRow at src/ui/views/swipe_action_row.cr)
description: |
  Reveal trailing or leading actions on a list row via swipe.
  HIG requires an alternate non-gesture path (button, custom action,
  or keyboard shortcut) per gestures.md:23,31 + accessibility.md:134.
```

**Linting rule:** every catalog row must declare ALL required schema fields. The lint rejects any row missing ANY of: `intent_identifier_crystal`, `primary_apple_name`, `class` (exactly one of A/B/C/D), `tier` (1/2/3), at least one of `swiftui_api`/`uikit_api`/`appkit_api` (the row must cite at least one canonical Apple API), `hig_page`, `android_equivalent`, `web_equivalent`, `coverage_today`, `description`. Fields with no real equivalent on the target platform are declared with the literal sentinel value `"—"` (em-dash). The lint REJECTS missing field declarations but ACCEPTS `"—"` as a valid populated value — this is how the schema captures "explicitly no equivalent" vs "we forgot to fill it in." The 9A acceptance gate runs the lint and verifies zero rows fail.

**Exception process:** if NO Apple canonical name exists for an intent (rare — most cross-platform interactions DO have an Apple name), the row carries `apple_canonical_name_exists: false` + a justification + a reviewed snake_case name. Codex antagonist must approve every exception.

## The Tier 2 translation contract (Class A only)

Scope: intent routing is **opt-in** and reserved for Class A intents only. Existing Tier 2 widgets (Button, Slider, TextField, etc.) stay as the default authoring surface unless explicitly marked as Class A. Codex predicts only 1-3 Class A intents total — likely just `:swipe_actions` plus maybe `:navigation_split_view` if iPad vs iPhone responsiveness justifies it.

Four parts for Class A:

```crystal
intent :swipe_actions do
  # 1. CAPABILITIES — guardrails for override validation.
  #    These predicates derive from HIG + SwiftUI + UIKit semantics.
  capabilities do
    supports_edge :leading
    supports_edge :trailing
    supports_full_swipe true
    full_swipe_destructive_safe true
    supports_role :destructive
    supports_role :cancel
    supports_role :default
    supports_disabled_actions true
    requires_row_identity_dispatch true
    requires_visible_or_keyboard_alternative true   # HIG gestures.md:23
    requires_accessibility_custom_actions true       # HIG accessibility.md:134
    requires_confirmation_for_destructive_full_swipe true
    preserves_focus_after_action true
    supports_voiceover_actions true
    supports_switch_control_activation true
    supports_voice_control_labels true
    does_not_conflict_with_system_gestures true
  end

  # 2. DEFAULTS — per-platform default UI::View class.
  defaults do
    ios        UI::SwipeActionRow
    ipados     UI::SwipeActionRow
    macos      UI::InlineActionRow    # MISSING — backlog item
    android    UI::SwipeActionRow
    web_wide   UI::InlineActionRow    # MISSING — backlog item
    web_narrow UI::SwipeActionRow
  end
end
```

**3. Override registry** — app + screen scope, precedence `screen > app > default`:

```crystal
# App-level override
class VoyagerApp < UI::App
  override_intent :swipe_actions, with: UI::DragHandleRow, on: [:web_wide]
end

# Screen-level override
class SettingsScreen < UI::Screen
  override_intent :swipe_actions, with: UI::InlineActionRow, on: [:ios]
end
```

Override MUST validate against `capabilities`. If `UI::DragHandleRow` doesn't declare `supports_role :destructive`, the override raises with a specific error naming the missing capability.

**4. Resolver (deferred)** — Phase 10 ships `UI::Intent.resolve(:swipe_actions, ctx).build(...)`. NOT a high-level constructor (Crystal type erasure makes that ergonomically painful per Codex co-plan R9).

## Class D documentation shape (NEW)

Class D is the bulk of Apple's interaction surface. Each Class D entry documents the Crystal method/property that emits the SwiftUI modifier 1:1.

Example:

```crystal
# Class D: refreshable
# primary_apple_name: refreshable
# swiftui_api: .refreshable { await loadData() }
# uikit_api: UIRefreshControl on UIScrollView
# appkit_api: NSRefreshableTableView (custom; AppKit has no native pull-to-refresh)
# hig_page: lists-and-tables.md
# coverage_today: MISSING — no UI::List.refreshable yet
#
# Crystal API shape (proposed):
#   list = UI::List.new
#   list.refreshable = -> { state.reload_todos }
#
# Platforms honored: iOS, iPadOS, Android (Material PullRefreshContainer).
# macOS: emit an explicit refresh ToolbarItem instead (manual fallback).
# Web: emit a custom JS-driven implementation or polyfill.
```

NO four-part contract for Class D. Just the Crystal API + the SwiftUI translation + the per-platform implementation note + coverage status.

## Apple-surface coverage gate (HARD per Codex HIGH 1)

9A is NOT complete until the catalog includes rows for EVERY behavior in Codex's Apple-surface checklist. Codex enumerated these explicitly:

- **Lists:** `List`, `listRowSeparator`, `listSectionSpacing`, `refreshable`, `searchable`, section indexes, `onMove`, `onDelete`.
- **Sheets/modals:** `sheet`, `fullScreenCover`, `popover`, `inspector`, `presentationDetents`, `interactiveDismissDisabled`, `presentationDragIndicator`, `confirmationDialog`, `alert`.
- **Toolbars:** `toolbar`, `ToolbarItem`, `ToolbarItemGroup`, `ToolbarItemPlacement`, `ToolbarSpacer`, `toolbarBackground`.
- **Forms:** `formStyle`, `GroupedFormStyle`, `ColumnsFormStyle`.
- **Navigation:** `NavigationStack`, `NavigationSplitView`, `NavigationDestination`, `NavigationPath`, `NavigationLink`.
- **Picker styles:** `.menu`, `.segmented`, `.wheel`, `.palette`, `.inline`.
- **Date/time picker styles:** `compact`, `graphical`, `wheel`; AppKit `NSDatePicker` text style.
- **Menus:** `Menu`, `contextMenu`, `UIMenu`, `UIAction`, `primaryAction`.
- **Drag/drop:** `draggable`, `dropDestination`, `Transferable`.
- **Animation:** `transition`, `matchedGeometryEffect`, `animation`, `PhaseAnimator`, `KeyframeAnimator`.
- **Haptics:** `sensoryFeedback`, `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`, `UISelectionFeedbackGenerator`.
- **Accessibility:** `accessibilityLabel`, `accessibilityHint`, `accessibilityValue`, `accessibilityAction` (critical for action rows), `accessibilityRotor`, `accessibilityFocused`.
- **Gestures:** `TapGesture`, `LongPressGesture`, `DragGesture`, `MagnifyGesture`, `RotateGesture`, `SpatialTapGesture`.

The catalog MUST include each named entry. Phase 9 close requires Codex antagonist to verify coverage.

## Existing widget audit (Codex hybrid approach)

Don't force all 80 view files into intent routing. Most are concrete widgets that already map cleanly. Retro-classify each view via a documentation table:

| View file | Primary intent (Apple name) | Class | Tier | Routing candidate? | Reason |
|---|---|---|---|---|---|
| `swipe_action_row.cr` | `swipeActions` | A | 2 | YES | iOS swipe vs macOS/web inline buttons |
| `button.cr` | `Button` | D | 2 | NO | Clean Button / UIButton / NSButton mapping; concrete widget, not routed; documented as direct-modifier-shape entry. |
| `context_menu.cr` | `contextMenu` | D | 2 | NO | Named modifier with platform fallback |
| `text_field.cr` | `TextField` | D | 2 | NO | Clean mapping |
| ... | ... | ... | ... | ... | ... |

**Class assignment is exact.** Every row carries exactly one of A/B/C/D. `button.cr` is Class D because it documents a direct 1:1 Apple-name → Crystal-API translation (Button/UIButton/NSButton), not because it's a routing candidate. The `Routing candidate?` column is orthogonal to class: a Class D widget is never a routing candidate; a Class A widget always is.

Routing candidates (Class A) should be rare — likely just `swipe_action_row.cr` + maybe `navigation_split_view`.

**Freshness check (Codex R15):** the scoping doc says 80 view types; the component-mapping-matrix skill says 59. 9A includes an audit reconciling the numbers + flagging fallbacks/gate-stubs/presenters/compat files.

## Owner-screen discovery loop — fixed 12-day window

```
T+0:  publish initial Apple-vocabulary catalog draft (architect + Codex)
T+7:  owner-screen intake closes for 9A
T+9:  architect reconciles
T+10: Codex antagonist review on the merged catalog
T+12: 9A close candidate
```

Late screens → backlog or Phase 9B amendment. Owner-screen input adds intents the HIG/SwiftUI/UIKit/AppKit scan didn't surface naturally (e.g., domain-specific behaviors observed in real apps).

## 9A deliverables (revised for v3)

1. **`docs/initiative-cross-platform-ui/architecture/intent-catalog.md`** — every intent, Apple-vocabulary names, schema-compliant rows, A/B/C/D classification.
2. **`docs/initiative-cross-platform-ui/architecture/intent-routing-candidates.md`** — short list of Class A intents that justify the four-part contract. Each entry: capabilities block, per-platform defaults, rationale.
3. **`docs/initiative-cross-platform-ui/architecture/translation-matrix.md`** — for Class A intents, default per-platform translation + coverage status. Includes freshness reconciliation of view-count discrepancy.
4. **`docs/initiative-cross-platform-ui/architecture/tier-2-translation-contract.md`** — Class A contract definition + Class D direct-modifier doc shape. Implementation-shaped pseudocode + acceptance examples so Phase 10 is implementation, not redesign.
5. **`docs/initiative-cross-platform-ui/architecture/intent-backlog.md`** — Class A + Class D intents where no shipped widget covers the default. Buildable backlog for Phase 10+.
6. **`docs/initiative-cross-platform-ui/architecture/widget-intent-mapping.md`** — all 80 (or actual-count) `UI::View` types annotated.
7. **`docs/initiative-cross-platform-ui/architecture/apple-surface-coverage.md`** — checklist against Codex's enumerated Apple API families. Phase 9 close requires every line green or explicit deferral.

NO code changes in 9A. NO new `UI::View` classes. NO registry implementation.

## Risk register (R1-R16 from co-plan + R17-R20 new from v3 work)

R1-R16: see `coplan-9-codex-1.md`. All adopted.

- **R17** — Catalog rows missing required schema fields. *Mitigation:* hard lint rule; Codex verifies before close.
- **R18** — Class D inflation (every SwiftUI modifier becomes a row). *Mitigation:* scope to modifiers Apple documents in the HIG corpus + the iOS26-native-components skill + ones the codebase already touches. Skip exotic/rarely-used modifiers.
- **R19** — "Exception" loophole for non-Apple names. *Mitigation:* Codex antagonist must approve every exception in writing. No silent exceptions.
- **R20** — A vs D classification ambiguity. *Mitigation:* Codex antagonist double-checks A/D boundary on every routing candidate; A is reserved for materially-different-widget cases.

## Hard rules

- Forward commits only on `phase-09-intent-catalog`.
- NO code changes in 9A. Docs only.
- NO renames of existing `UI::View` classes.
- **Catalog vocabulary derives FROM Apple SwiftUI/UIKit/AppKit FIRST.** snake_case-of-the-Apple-name is the canonical Crystal identifier. Exceptions require Codex antagonist approval.
- Every catalog row has the full schema (intent_identifier_crystal, primary_apple_name, class, tier, swiftui_api, uikit_api, appkit_api, hig_page, android_equivalent, web_equivalent, coverage_today, description).
- Class A gets the four-part contract; Class B is invariants doc; Class C is bridged-API doc; Class D is direct-modifier doc.
- Apple-surface coverage gate: every named SwiftUI modifier in the Codex checklist has a catalog row.
- Owner-screen window: 7 days; late additions → backlog.
- **Codex stays in-parallel as antagonist+validator on every iteration.** Convergence requires Codex APPROVE or APPROVE_WITH_NOTES.
- Standard Claude co-author footer.

---

**Next:**
1. Dispatch Codex antagonist+validator on v3 — verify findings resolved + no new issues introduced.
2. If APPROVE_WITH_NOTES, write brief.
3. Owner-screen intake opens at brief approval.
4. Implementer ships the 7 documents (mostly architect-led writing; implementer verifies schema compliance + runs the freshness check + writes the widget-intent-mapping audit table).
5. Tag 9A close.

— Architect (Claude Opus 4.7)
