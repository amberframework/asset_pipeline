# Intent Routing Candidates — Class A Only

**Companion to:** `intent-catalog.md`.

This document lists every Class A intent (widget-routing intents) with its full capabilities block, per-platform default translation, and rationale. Class A intents get the four-part contract per `tier-2-translation-contract.md`; Class D intents do not.

Codex co-plan §1 predicted 1-3 Class A intents in the entire framework. The final count is **1**.

---

## `:swipe_actions`

### Identity
- **intent_identifier_crystal:** `:swipe_actions`
- **primary_apple_name:** `swipeActions`
- **catalog entry:** `intent-catalog.md` §"Class A — Widget-routing intents"

### Capabilities (verified against today's source — Phase 10-pre.1)

The original Phase 9 capability block listed 12 entries. The Phase 10-pre
freshness audit (`handoff/phase-10-pre-catalog-freshness-2026-05-25.md`)
found 4 outright false claims and 2 unbacked. Phase 10-pre.1 trims the
**active capabilities** to what today's source actually backs and moves
the rest to the "Planned (Phase 10B targets)" section below.

```crystal
intent :swipe_actions do
  capabilities do
    # SwiftUI/UIKit API surface — backed by source today:
    supports_edge :leading,    web_only: true       # web only (src/ui/renderers/web_renderer.cr:2909-2911);
                                                    # iOS/macOS/Android render trailing only — Phase 10B.1b target.
    supports_edge :trailing                          # src/ui/views/swipe_action_row.cr:65;
                                                    # honored by uikit_renderer.cr:3851-3860,
                                                    # appkit_renderer.cr:3819-3826,
                                                    # web_renderer.cr:2905-2907.
    supports_role :default                           # src/ui/views/swipe_action_row.cr:21,34;
                                                    # default branch of `role` used unchanged.
    supports_role :destructive, partial: true        # iOS: uikit_renderer.cr:3852 forwards role to UI::Button;
                                                    # web: web_renderer.cr:2942 adds --destructive class;
                                                    # AppKit drops role (appkit_renderer.cr:3819-3826);
                                                    # Android stub. Phase 10B.1b/c target.

    # HIG-mandated invariants — partially honored today:
    requires_visible_or_keyboard_alternative true,   # HIG gestures.md:23 — unenforced today;
      enforced: false                                # no lint, no runtime check. Phase 10A LSP rule target.
    supports_voice_control_labels partial: true      # iOS: uikit_renderer.cr:3853 sets accessibility_label
                                                    # = action.label; web: web_renderer.cr:2946 sets aria-label;
                                                    # AppKit does not set NSButton label. Phase 10B.1b target.
    supports_switch_control_activation partial: true # web `<button>` is focusable by default;
                                                    # native paths offer no Switch Control surface beyond
                                                    # what UIKit/AppKit do automatically.

    # Runtime-only invariant — cannot be confirmed from code alone:
    does_not_conflict_with_system_gestures true,     # iOS swipe via make_swipe_reveal_row
      verified_at: :runtime                          # (uikit_renderer.cr:3870 → objc_bridge.m). Requires
                                                    # hands-on runtime testing to confirm; currently
                                                    # unverified from static source. Phase 10D target.
  end

  defaults do
    ios        UI::SwipeActionRow
    ipados     UI::SwipeActionRow
    macos      UI::InlineActionRow      # MISSING — see intent-backlog.md B-001 (P0)
    android    UI::SwipeActionRow       # STUB — android_renderer.cr:3148-3152; see B-035
    web_wide   UI::InlineActionRow      # MISSING — see intent-backlog.md B-002 (P0)
    web_narrow UI::SwipeActionRow
  end
end
```

### Planned (Phase 10B targets — not yet backed by source)

These capabilities were declared in the Phase 9 block but are NOT backed
by the framework as it stands on 2026-05-25. They are preserved here as
design intent and tracked in `intent-backlog.md` (notably B-036, the
:swipe_actions capability honesty bundle).

```crystal
# Phase 10B.1b targets — :swipe_actions capability honesty
supports_disabled_actions true            # SwipeAction struct has no disabled/is_disabled
                                          # field (src/ui/views/swipe_action_row.cr:19-39);
                                          # no renderer applies disabled state. Phase 10B.1b.
requires_row_identity_dispatch true       # SwipeAction.on_tap is a Proc(Nil) closure
                                          # (swipe_action_row.cr:23,33) — apps close over
                                          # the row from the build site; no row-identity
                                          # argument is threaded through the API. Not
                                          # enforced today. Phase 10B.1b.

# Phase 10B.2b target — Accessibility custom actions
requires_accessibility_custom_actions true   # Neither SwipeActionRow nor SwipeAction
                                             # exposes accessibility_custom_actions;
                                             # no UIAccessibilityCustomAction is wired
                                             # on the row. HIG accessibility.md:134 mandates
                                             # this; framework does not satisfy it today.
                                             # Phase 10B.2b.
supports_voiceover_actions true              # Corollary of the above — no accessibilityAction
                                             # modifier path on SwipeActionRow. Phase 10B.2b.

# Phase 10B.1b target — leading-edge native parity
supports_edge :leading (native)              # Native iOS/macOS/Android renderers iterate
                                             # only trailing_actions today (uikit:3851,
                                             # appkit:3819, android stub). Only web
                                             # honors leading_actions. Phase 10B.1b
                                             # extends iOS to the leading edge.

# Phase 10B.1b/c targets — destructive role honesty across platforms
supports_role :destructive (full)            # Currently partial (iOS + web only).
                                             # Phase 10B.1b adds AppKit destructive tint;
                                             # Phase 10B.1c adds Android proper integration.
```

The trimmed active block accurately describes today's framework. The
Planned section preserves the design intent without falsifying the
current state.

**Removed from earlier drafts (no source backing):**
- `supports_full_swipe` / `full_swipe_destructive_safe` — `allowsFullSwipe` exists in SwiftUI's `swipeActions(edge:allowsFullSwipe:content:)` but the "destructive-safe" semantic is a design opinion, not a HIG rule. If the framework wants to encode that opinion, it belongs in a separate `framework_opinion` block, not in `capabilities`.
- `supports_role :cancel` — SwiftUI `Button.role` accepts `.cancel` but the cancel role is meant for dismissal-style actions, not swipe-row actions. Removed pending a use case.
- `requires_confirmation_for_destructive_full_swipe` — UX recommendation, not a HIG or API requirement. Apps that want this discipline implement it via `:confirmation_dialog` after the swipe action; not a property of `:swipe_actions` itself.
- `preserves_focus_after_action` — desirable but not specified by SwiftUI or HIG.

These were architect opinions that hadn't been validated against the cited sources. The capability block now reflects only what's backed by SwiftUI's API + HIG's accessibility rules.

### Per-platform default rationale

| Platform | Default widget | Reasoning |
|---|---|---|
| iOS | `UI::SwipeActionRow` | Native swipe gesture is the idiomatic affordance. UIKit `UISwipeActionsConfiguration` backs this. |
| iPadOS | `UI::SwipeActionRow` | Same as iOS; iPadOS list rows support swipe. |
| macOS | `UI::InlineActionRow` (missing) | macOS has no swipe gesture on lists. Idiomatic AppKit equivalent is visible trailing buttons. The current `UI::SwipeActionRow` renderer already emits inline buttons on AppKit (`appkit_renderer.cr:3806`), so this is partially shipped — but it's masquerading under the wrong type name. Phase 10 introduces `UI::InlineActionRow` as the named default. |
| Android | `UI::SwipeActionRow` (STUB) | Android renderer is explicitly a stub at `android_renderer.cr:3148` — defers proper Material `SwipeToDismissBox` integration. Backlog item B-035. |
| web_wide | `UI::InlineActionRow` (missing) | Desktop web has no native swipe gesture. Hover/right-click affordances + visible trailing buttons are idiomatic. |
| web_narrow | `UI::SwipeActionRow` | Mobile web honors touch gestures; CSS+JS libraries provide swipe-reveal. |

### Why this is Class A (and not Class D)

Class A vs Class D boils down to whether the framework picks a **materially different concrete widget** per platform. For `:swipe_actions`:

- iOS uses a row that listens for swipe gesture and reveals hidden actions on edge-reveal.
- macOS/web-wide uses a row with visible trailing buttons — no hidden state, no gesture.

These are structurally different views. A single `UI::SwipeActionRow` class with a `mobile_breakpoint_px` property today fudges this by branching internally, but the renderer-side abstraction is brittle: AppKit's renderer ignores most swipe-action properties and just lays out the trailing buttons. Class A formalizes the split.

`:context_menu` is Class D, not Class A, because while the gesture differs per platform (long-press vs right-click), the conceptual widget is the same — a popover menu. The framework doesn't pick a different concrete class per platform; it picks a different trigger gesture, which is renderer-internal.

### Override examples

```crystal
# App-wide override: on macOS-wide, use the new DragHandleRow class instead.
class VoyagerApp < UI::App
  override_intent :swipe_actions, with: UI::DragHandleRow, on: [:macos, :web_wide]
end

# Screen-scoped override: SettingsScreen always uses InlineActionRow regardless of platform.
class SettingsScreen < UI::Screen
  override_intent :swipe_actions, with: UI::InlineActionRow, on: :all
end
```

### Capability validation

If an override declares a widget that doesn't satisfy `:swipe_actions`'s capability set, the framework raises with a specific message at registration time:

```
UI::Intent::CapabilityMismatchError:
  Override for :swipe_actions with UI::DragHandleRow on platforms [:macos, :web_wide]
  does NOT declare capability `requires_accessibility_custom_actions`.

  :swipe_actions requires this per HIG accessibility.md:134 (gesture must not be the sole path).
  UI::DragHandleRow should declare `provides :accessibility_custom_actions` in its widget capabilities,
  OR a different override widget should be chosen.
```

This is the guardrail Codex's antagonist pass identified as missing in scoping v2.

---

## Why only one Class A intent?

The Codex co-plan predicted "5-10 widget-routing intents total"; the actual scoping work produced one. Why?

1. **Most cross-platform interaction differences are renderer-internal.** When SwiftUI's `Menu` and Android's `DropdownMenu` are visually different but functionally identical — same API, same callbacks, same options — that's renderer-internal. One Crystal class, different `visit(view)` implementations. Class D.

2. **The materially-different-widget bar is high.** For Class A to apply, the framework needs to swap *entire* concrete classes per platform — not just style values. `:swipe_actions` qualifies because iOS swipes (hidden state revealed by gesture) and macOS inline buttons (always-visible state) really are different widgets, not the same widget with different styling.

3. **Routing has a cost.** Override registries + capability validation + resolver patterns are real complexity. Most apps don't need to override widget choice per platform; they just want the framework's default to be sensible. Class D's direct-modifier shape gets there without the contract overhead.

If a future phase identifies a new Class A candidate (e.g., `:reorder_list_items` if the drag-handle vs up-down-button divergence proves to be a different widget rather than the same widget with different rendering), it gets added here.

— Architect (Claude Opus 4.7)
