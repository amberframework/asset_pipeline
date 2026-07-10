# Phase 9 — Intent Catalog + Tier 2 Translation Contract (SCOPING v2)

**Date:** 2026-05-25
**Status:** SCOPING v2 — Codex co-planner findings adopted; Codex antagonist-in-parallel pass pending per owner directive.
**Branch:** to be cut as `phase-09-intent-catalog`.
**Predecessor:** Phase 8 collective review (in-flight).
**Planning artifacts:** `scoping-9.v1.md`, `coplan-9-codex-1.md`.

---

## The problem being solved

Phase 8 closed the ergonomic MVC API. The library has 80 `UI::View` types in `src/ui/views/` and a tier model documented in CLAUDE.md:148-160 (Tier 1 brand-universal; Tier 2 platform-default; Tier 3 platform-only). The `component-mapping-matrix` skill catalogues each VIEW TYPE against SwiftUI/UIKit/AppKit/Compose/HTML.

**What's missing:** the framework documents that Tier 2 widgets "map to the idiomatic native widget" but does NOT document:

1. **What user *intent* each Tier 2 widget fulfills** — `UI::Button` vs `UI::IconButton` vs `UI::MenuButton` are distinct intents, but nothing names them in HIG/UIKit/SwiftUI vocabulary.
2. **The DEFAULT cross-platform translation per intent** — today the translation is hard-coded in `visit(view)`; there's no documented way to say "give me the default per-row-actions widget for this platform."
3. **An override mechanism** — when an author wants something different from the framework default (e.g., "on iOS render inline buttons instead of swipe-to-reveal"), there's no documented hook.

The gap surfaced when the owner described "the Mail-app swipe behavior." The framework already shipped `UI::SwipeActionRow`, but nobody had named the *intent* it fulfilled (SwiftUI calls this `swipeActions(edge:allowsFullSwipe:content:)` on List rows; UIKit calls it `UISwipeActionsConfiguration`). Because the intent vocabulary didn't exist in our docs, the existing widget was discoverable only by accident.

**Critical framing (owner directive):** the catalog must use vocabulary that **already exists in SwiftUI / UIKit / AppKit**. We are tying into existing Apple platform concepts — we are not inventing a new design language. Where SwiftUI/UIKit has a named API for a behavior, our intent must reference that name. Where Apple HIG names a pattern, we adopt the HIG name. Inventing fresh names where Apple has good vocabulary is a planning failure.

## The Tier 2 translation contract (final shape — Codex co-plan adopted)

**Scope discipline:** intent routing is OPT-IN and reserved for cross-platform interaction intents where the framework would pick a *materially different concrete `UI::View` class* per platform. Existing Tier 2 widgets remain the default authoring surface unless explicitly marked as routing candidates. **Button, Slider, TextField, Card, Divider do NOT become intent-routed.**

The contract has four parts:

```crystal
intent :actionable_row do
  # 1. CAPABILITIES — declares what this intent supports.
  #    Guardrails for override validation; HIG-derived requirements.
  capabilities do
    max_primary_actions 3
    supports_destructive true
    supports_leading_actions true
    requires_alternative_activation true   # HIG: gesture must not be sole path
  end

  # 2. DEFAULTS — per-platform-key default concrete UI::View class.
  defaults do
    ios        UI::SwipeActionRow
    ipados     UI::SwipeActionRow
    macos      UI::InlineActionRow
    android    UI::SwipeActionRow
    web_wide   UI::InlineActionRow
    web_narrow UI::SwipeActionRow
  end
end
```

**3. Override registry** — app-level + screen-level scope, precedence `screen > app > default`:

```crystal
class VoyagerApp < UI::App
  override_intent :actionable_row, with: UI::DragHandleRow, on: [:web_wide]
end

class SettingsScreen < UI::Screen
  override_intent :actionable_row, with: UI::InlineActionRow, on: [:ios]
end
```

Override registration MUST validate against the intent's `capabilities` block — if the substitute widget doesn't support `:destructive` or doesn't provide an `alternative_activation` path, the framework raises with a specific message naming the missing capability.

**4. Resolver (deferred from constructor)** — Phase 10 ships `UI::Intent.resolve(:actionable_row, ctx).build(...)`. NOT a high-level constructor — Crystal type erasure makes that ergonomically painful. Authors use the concrete widget directly OR call the resolver explicitly.

## Three classes of intent (per Codex co-plan)

Not all intents fit the "widget routing" model. The catalog must classify each intent as one of:

### Class A — Widget-routing intents (small set)
The framework picks a materially different `UI::View` per platform. Examples:
- `:actionable_row` — SwipeActionRow vs InlineActionRow vs DragHandleRow.
- `:reorder_list_items` — drag-handle vs up/down buttons vs reorder-anywhere.
- `:refresh_content` — pull-to-refresh vs explicit refresh button vs keyboard shortcut.
- `:present_secondary_context` — Popover vs Sheet vs Sidebar (depends on platform + size class).

Codex predicts ~5-10 widget-routing intents total. These get the four-part contract.

### Class B — Framework-contract intents (cross-cutting)
Every widget must honor; accessibility lives here. Examples:
- `:manage_focus_after_navigation`
- `:restore_focus_after_dismiss`
- `:declare_screen_landmark`
- `:provide_alternate_activation` (HIG `gestures.md:23,31` — gestures must not be sole path)
- `:scale_content_for_large_text`
- `:respect_reduced_motion`

These are NOT widget substitutions; they're invariants every renderer enforces. The catalog documents them as contracts, not as registry entries.

### Class C — System-integration intents (single API, platform implementation varies)
One API surface, different implementations per platform. Examples:
- `:share_content` (UIActivityViewController on iOS, NSSharingService on macOS, Intent.ACTION_SEND on Android, Web Share API on web).
- `:copy_to_clipboard`, `:paste_from_clipboard`.
- `:request_permission` (camera, microphone, notifications, location).
- `:open_deep_link`, `:open_external_url`.
- `:share_to_system_app`, `:print_document`.

Catalog documents these as platform-bridged APIs. They may need new `UI::View`-shaped wrappers later, but for now they're function calls, not widgets.

## Platform key vocabulary

Six keys: `:ios, :ipados, :macos, :android, :web_wide, :web_narrow`.

iPadOS pointer + size-class subconditions become *capability predicates* in a later phase, not enum keys. Don't expand the key set in 9A.

## The catalog must speak SwiftUI/UIKit (owner directive)

Every intent's documentation must include:

- **SwiftUI API name** (e.g. `swipeActions(edge:allowsFullSwipe:content:)`, `contextMenu`, `refreshable`, `confirmationDialog`).
- **UIKit API name** (e.g. `UISwipeActionsConfiguration`, `UIContextMenuConfiguration`, `UIRefreshControl`, `UIAlertController`).
- **AppKit API name** if applicable (`NSMenu`, `NSAlert`, etc.).
- **HIG page** (e.g. `gestures.md`, `pull-down-buttons.md`).

The intent NAME itself should adopt Apple's vocabulary where Apple has good names. Examples:
- Apple says "context menu" → our intent is `:context_menu` (NOT `:reveal_action_palette_on_long_press`).
- Apple says "swipe actions" → our intent is `:swipe_actions_on_row` or just folded under `:actionable_row` if the cross-platform translation makes sense.
- Apple says "confirmation dialog" → our intent is `:confirmation_dialog` (NOT `:destructive_confirm`).
- Apple says "pull to refresh" / `refreshable` → our intent is `:refreshable` (matches SwiftUI verbatim).

Where Android/Web have different but equivalent names, list them as aliases. The PRIMARY name follows Apple.

## What 9A ships (revised)

1. **`docs/initiative-cross-platform-ui/architecture/intent-catalog.md`** — every intent named in Apple vocabulary + classified (A/B/C) + described in user-need language + sourced (SwiftUI API, UIKit API, AppKit API, HIG page, Material page, web pattern).

2. **`docs/initiative-cross-platform-ui/architecture/intent-routing-candidates.md`** *(Codex addition)* — the short list of Class A intents that justify the four-part contract. Each entry: intent name, capabilities block draft, per-platform defaults draft, rationale for why this needs routing (vs being a single Tier 2 widget).

3. **`docs/initiative-cross-platform-ui/architecture/translation-matrix.md`** — for each Class A intent, the default per-platform translation (which existing `UI::View` class, or `MISSING — backlog`). Also includes a freshness check on the existing `component-mapping-matrix` skill (the 59-vs-80 count discrepancy Codex flagged).

4. **`docs/initiative-cross-platform-ui/architecture/tier-2-translation-contract.md`** — contract definition: how intents are declared, how defaults are registered, how overrides work + validate against capabilities. Includes implementation-shaped pseudocode + acceptance examples so Phase 10 is implementation, not redesign.

5. **`docs/initiative-cross-platform-ui/architecture/intent-backlog.md`** — Class A intents where no shipped widget covers the default for some platform. Each entry: intent + platform + what's missing + rough size estimate. This is the buildable backlog for Phase 10+.

6. **`docs/initiative-cross-platform-ui/architecture/widget-intent-mapping.md`** — table of all 80 `UI::View` types annotated with: primary intent, tier, routing candidate (yes/no), reason, gaps. Codex's hybrid-audit approach.

**NO code changes in 9A.** NO new `UI::View` classes. NO registry implementation. Phase 10 (or later) implements.

## Owner-screen discovery loop — fixed window

```
T+0:  publish initial catalog draft
T+7:  owner-screen intake closes for 9A
T+9:  architect reconciles
T+10: Codex antagonist review
T+12: 9A close candidate
```

Late screens become backlog items / Phase 9B amendments. "Catalog complete" is not a real state; use "complete enough for first implementation slice."

## Risk register (R1-R16, all from co-plan adopted)

- **R1** — Intent catalog over-fits to apps we have. *Mitigation:* draw from SwiftUI/UIKit/AppKit + HIG + Material + web FIRST; then owner screens; then existing widgets.
- **R2** — Bike-shedding intent names. *Mitigation:* names match Apple vocabulary where Apple has named the behavior; Codex critiques naming consistency.
- **R3** — Owner-screen loop open-ended. *Mitigation:* fixed 12-day window per Codex.
- **R4** — Translation matrix has subjective entries. *Mitigation:* pick one default + document alternatives as known overrides.
- **R5** — 9A docs conflict with Phase 10 implementation. *Mitigation:* implementation-shaped pseudocode + acceptance examples in 9A.
- **R6** — Existing Tier 2 widgets don't fit intent model. *Mitigation:* hybrid audit; routing is opt-in; most widgets stay unrelated.
- **R7** — Web narrow vs wide is runtime, not compile-time. *Mitigation:* resolver pattern handles runtime resolution; capability predicates extend later.
- **R8** — Existing widget names may not match intent vocabulary. *Mitigation:* don't rename; just map.
- **R9** — Constructor type erasure. *Mitigation:* drop high-level constructor; use resolver pattern.
- **R10** — Capability mismatch on override. *Mitigation:* override validates against capabilities block; loud error on mismatch.
- **R11** — Accessibility regression by override. *Mitigation:* `requires_alternative_activation` capability blocks gesture-only overrides.
- **R12** — SSR/runtime split for web_wide/web_narrow. *Mitigation:* Phase 10 resolver design must handle hydration; document SSR vs runtime in 9A.
- **R13** — Catalog inflation. *Mitigation:* hard cap ~40 intents in 9A; beyond that becomes taxonomy theater.
- **R14** — Platform policy conflict. *Mitigation:* system gestures (predictive back, edge swipe) are Class B contracts, not Class A routing.
- **R15** — Component matrix staleness (59 vs 80 count). *Mitigation:* 9A includes explicit freshness check + reconciliation.
- **R16** — Override without state semantics. *Mitigation:* capability descriptor includes state/lifecycle requirements (e.g., "must dispatch action with row identity").

## Hard rules

- Forward commits only on `phase-09-intent-catalog`.
- NO code changes in 9A. Docs only.
- NO renames of existing `UI::View` classes.
- Intent vocabulary derives FROM Apple (SwiftUI, UIKit, AppKit) where Apple has named the behavior. Aliases for Android/web are secondary.
- Catalog cites: SwiftUI API + UIKit API + AppKit API + HIG page slug for every intent.
- Class A (routing candidates) gets the four-part contract; Class B + C documented but not registry-routed.
- Owner-screen window is 7 days; late additions are backlog.
- **Codex stays in-parallel as antagonist on every iteration of the scoping + brief docs** per owner directive 2026-05-25. Each scoping rev gets a Codex antagonist pass; convergence requires Codex APPROVE or APPROVE_WITH_NOTES.

---

**Next:**
1. Dispatch Codex as ANTAGONIST + VALIDATOR on this v2 scoping. Specific framing: validate SwiftUI/UIKit fidelity; push on whether vocabulary, classification, and coverage match Apple's actual API surface.
2. Reconcile.
3. Brief.
4. Owner-screen loop opens (T+0 = brief approval).
5. Dispatch implementer.

— Architect (Claude Opus 4.7)
