# Phase 9 Scoping v2 — Codex Antagonist+Validator Findings

**Date:** 2026-05-25
**Codex session:** medium reasoning, arg-form prompt, antagonist+validator role.
**Source log:** `/tmp/codex-antagonist-9-v2.log`.
**Verdict:** REVISE — 2 BLOCKER, 3 HIGH, 2 MEDIUM, 1 LOW.

---

## BLOCKER 1 — Class A vocabulary fails the Apple-native rule

Codex: v2's Class A example names (`:actionable_row`, `:reorder_list_items`, `:refresh_content`, `:present_secondary_context`) are GENERIC. Only `:refresh_content` is close, and it should be `:refreshable`. The doc says "speak SwiftUI/UIKit" but its own examples don't.

**Resolution (v3):**
- `:actionable_row` → **`:swipe_actions`** (SwiftUI `swipeActions(edge:allowsFullSwipe:content:)`; UIKit `UISwipeActionsConfiguration`).
- `:refresh_content` → **`:refreshable`** (SwiftUI `.refreshable`; UIKit `UIRefreshControl`).
- `:reorder_list_items` → **`:on_move`** (SwiftUI `.onMove`; UIKit table/collection reorder; AppKit table drag/drop).
- `:present_secondary_context` is multiple intents bundled. Split into:
  - **`:popover`** (`.popover` / `UIPopoverPresentationController` / `NSPopover`)
  - **`:sheet`** (`.sheet` / `UISheetPresentationController` / `NSViewController.presentAsSheet`)
  - **`:inspector`** (`.inspector` / iPadOS/macOS detail panes)
  - **`:navigation_split_view`** (`NavigationSplitView` / `UISplitViewController` / `NSSplitViewController`)

## BLOCKER 2 — Missing Class D: Native modifier intents

Codex: a huge swath of Apple's surface is SwiftUI modifiers that CONFIGURE existing widgets without substituting them. The A/B/C taxonomy doesn't hold them. Add **Class D — Native modifier intents.**

Examples Codex lists:
- **List modifiers** — `listRowSeparator`, `listSectionSpacing`, `sectionIndexLabel`, `listSectionIndexVisibility`.
- **Sheet modifiers** — `presentationDetents`, `interactiveDismissDisabled`, `presentationDragIndicator`.
- **Toolbar modifiers** — `toolbar`, `ToolbarItemPlacement`, `toolbarBackground`, `ToolbarSpacer`.
- **Search modifiers** — `searchable`, `searchSuggestions`, `searchScopes`.
- **Animation modifiers** — `transition`, `matchedGeometryEffect`, `animation`.
- **Haptics** — `sensoryFeedback`.
- **Accessibility modifiers** — `accessibilityLabel`, `accessibilityHint`, `accessibilityRotor`, `accessibilityAction`.

**Resolution (v3):** add Class D. Class D intents use **direct modifier-shaped APIs** (`refreshable`, `presentation_detents`, `toolbar_item`, `searchable`, `accessibility_label`) — NOT the four-part Class A contract with intent resolver. A one-size resolver for these would be over-engineering.

## HIGH 1 — Apple-surface coverage incomplete

Codex: the required Apple-surface checklist isn't in the catalog candidate model. Missing named coverage:
- Lists: `List`, `listRowSeparator`, `listSectionSpacing`, `refreshable`, `searchable`, section indexes.
- Sheets/modals: `presentationDetents`, `interactiveDismissDisabled`, `presentationDragIndicator`, `fullScreenCover`.
- Toolbars: `ToolbarItem`, `ToolbarItemGroup`, `ToolbarItemPlacement`, `ToolbarSpacer`, `toolbarBackground`.
- Forms: `formStyle`, `GroupedFormStyle`, `ColumnsFormStyle`.
- Navigation: `NavigationDestination`, `NavigationPath`, `NavigationStack`, `NavigationSplitView`.
- Picker styles: `.menu`, `.segmented`, `.wheel`, `.palette`, `.inline`.
- Date/time picker styles: `compact`, `graphical`, `wheel`, AppKit `NSDatePicker` text style.
- Menus: `Menu`, `contextMenu`, `UIMenu`, `UIAction`, `primaryAction`.
- Drag/drop: `draggable`, `dropDestination`, `Transferable`.
- Accessibility: `accessibilityAction` (critical for swipe/action rows per HIG).

**Resolution (v3):** Apple-surface coverage becomes an **explicit 9A acceptance gate.** The catalog must include rows for each named SwiftUI modifier/component family above. Missing rows = phase blocked.

## HIGH 2 — Classification boundaries need tightening

- `:focus` stays Class B.
- `:refreshable` is Class D first (modifier on List), Class A fallback only where the platform can't express pull-to-refresh.
- `:on_move` (reorder) is Class D (list capability modifier), not Class A.
- `:present_secondary_context` was bundled; now split per BLOCKER 1.
- `:context_menu` is Class D (named modifier with platform-specific fallback policy), NOT Class A.

**Resolution (v3):** rewrite the classification examples section with correct A/B/C/D buckets.

## HIGH 3 — Capability descriptors too weak for `swipe_actions`

Codex names 13+ specific predicates needed to prevent override misuse:

- `supports_edge(:leading | :trailing)`
- `supports_full_swipe` + whether full swipe is destructive-safe
- `requires_accessibility_custom_actions`
- `requires_visible_or_keyboard_alternative` (HIG: gestures must not be sole path)
- `requires_row_identity_dispatch`
- `supports_disabled_actions`
- `supports_role(:destructive, :cancel, :default)`
- `requires_confirmation_for_destructive_full_swipe`
- `preserves_focus_after_action`
- `supports_voiceover_actions`
- `supports_switch_control_activation`
- `supports_voice_control_labels`
- `does_not_conflict_with_system_gestures`

**Resolution (v3):** the capability descriptor example for `:swipe_actions` includes ALL 13 predicates. Other Class A intents get equivalent depth.

## MEDIUM 1 — Enforcement language too soft

Codex: "should" adopt Apple vocabulary is a loophole. Need:
- Every intent row must have `primary_apple_name`.
- Crystal intent identifier MUST be the snake_case form of the Apple name unless exception is documented.
- Exceptions require "no Apple canonical name exists" + reviewed aliases.
- CI/docs lint should reject intent rows missing SwiftUI/UIKit/AppKit fields.

**Resolution (v3):** rewrite the enforcement section with HARD rules. Catalog rows have a strict schema: `primary_apple_name`, `swiftui_api`, `uikit_api`, `appkit_api`, `hig_page`, `class` (A/B/C/D), `tier`, `intent_identifier_crystal`. Lint validates every row has all required fields.

## MEDIUM 2 — Four-part contract is Class-A-only

Codex: the four-part contract (intent_id + capabilities + defaults + override_registry) is right for Class A. For Class D, use direct modifier-shaped APIs (`refreshable`, `presentation_detents`, `toolbar_item`, `searchable`, `accessibility_label`). No intent resolver needed for modifiers.

**Resolution (v3):** the contract section explicitly scopes the four-part contract to Class A. Class D documentation shape is "Crystal API that emits SwiftUI modifier 1:1." Class B (cross-cutting) and Class C (system integration) have their own documentation shapes.

## LOW 1 — Repo evidence supports the critique

Codex notes `swipe_action_row.cr` and `context_menu.cr` already use Apple vocab in comments. `button.cr` is the correct counterexample (clean Button/UIButton/NSButton mapping, no routing). The repo's own comments are ahead of v2's scoping language.

**Resolution (v3):** cite the repo evidence in the rationale.

---

## Severity counts

BLOCKER: 2  
HIGH: 3  
MEDIUM: 2  
LOW: 1  

## v3 changes summary

- Add Class D — Native modifier intents.
- Rename all Class A examples to Apple vocabulary verbatim.
- Add Apple-surface coverage gate as explicit 9A acceptance.
- Strengthen enforcement with strict catalog schema + lint requirements.
- Expand capability descriptor for `:swipe_actions` to 13+ predicates.
- Scope four-part contract to Class A only; Class D uses direct modifier APIs.

## v3 Codex iteration history

**v3 iter 1** (`/tmp/codex-antagonist-9-v3.log`): REVISE. 0 BLOCKER / 0 HIGH / 2 MEDIUM / 0 LOW. Findings: (a) lint enforcement still too narrow — only rejected missing `primary_apple_name` and Apple-API trio, not other schema fields; (b) `D-ish` classification in widget audit table violated exact-class rule.

**v3 iter 2 fixes:**
- Lint rule rewritten to require ALL 11 schema fields with `"—"` em-dash sentinel for no-equivalent-on-platform cases.
- `D-ish` for `button.cr` replaced with `D` + explanation that class assignment is exact and orthogonal to routing-candidate status.

**v3 final pass** (`/tmp/codex-final-9.log`): **APPROVE.** Both MEDIUMs addressed. No new findings. Phase 9 scoping locked.

— Codex (medium reasoning, arg-form prompt, antagonist+validator mode)
