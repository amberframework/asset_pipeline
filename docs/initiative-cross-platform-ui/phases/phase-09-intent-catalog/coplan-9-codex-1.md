# Phase 9 Co-Planning — Codex Response

**Date:** 2026-05-25
**Codex session:** medium reasoning, arg-form prompt, default model.
**Role:** Co-planner.
**Source log:** `/tmp/codex-coplan-9.log`.

---

## Bottom line (Codex headline)

**The catalog is useful, but the proposed contract is too broad if applied to all Tier 2 widgets.** Treat intent routing as a narrow escape hatch for ambiguous cross-platform interaction patterns, NOT as a new base model for `UI::View`.

`SwipeActionRow` is the right motivating case — already encodes multiple platform behaviors in one class. `Button` is the counterexample — stable universal API, no need for intent indirection.

## Adopted decisions

### Contract shape: four parts, but DROP the high-level constructor

Codex flags constructor type erasure as a real Crystal pain. Better:

```crystal
intent :actionable_row do
  capabilities do
    max_primary_actions 3
    supports_destructive true
    supports_leading_actions true
    requires_alternative_activation true   # HIG: gestures must not be only path
  end

  defaults do
    ios UI::SwipeActionRow
    ipados UI::SwipeActionRow
    macos UI::InlineActionRow
    android UI::SwipeActionRow
    web_wide UI::InlineActionRow
    web_narrow UI::SwipeActionRow
  end
end
```

Four parts:
1. `intent_id` (Symbol)
2. `capabilities` (descriptor — guardrails for overrides)
3. `default_table` (per-platform-key → concrete `UI::View` class)
4. `override_registry` (app + screen scope)

**Defer the high-level constructor.** Phase 10 prefers `UI::Intent.resolve(:actionable_row, ctx).build(...)` resolver pattern OR a narrow semantic wrapper only where constructor parity is proven across all candidate widgets.

### Platform key granularity: 6 keys

`:ios, :ipados, :macos, :android, :web_wide, :web_narrow`. Document as "default routing keys," not a complete adaptive model. iPadOS pointer/size-class subconditions become *capability predicates* in a later phase, not enum keys now.

### Override scope: both, with precedence

`screen override > app override > framework default`. App-level matches the existing `UI::App.design_tokens` `Brand` model. Screen-level is necessary because interaction intent is contextual in a way brand is not (Settings wants explicit inline destructive; Mail wants swipe). Implementation order can be app-first, but the 9A contract reserves screen-level now.

### 9A vs 9B/10 split: 9A docs-only

But 9A MUST include implementation-shaped pseudocode + acceptance examples. Otherwise Phase 10 becomes redesign, not implementation.

Add a deliverable Codex flagged: **`intent-routing-candidates.md`** — the short list of intents that actually justify routing (vs. intents that are documentation-only or capability-predicate-only).

### Existing widget audit: hybrid

Do NOT force all 80 views into intent routing. Most are already well-defined Tier 1/2/3 under the existing tier model. Retro-classify each view at the documentation level (table format Codex proposed):

| View | Primary user intent | Tier | Routing candidate? | Reason | Gaps |
|---|---|---|---|---|---|

**Routing candidates should be rare.** Codex predicts: `SwipeActionRow`, maybe `Sheet`/`Popover`/`ConfirmationDialog` (presentation context), maybe navigation surfaces, maybe list reorder + refresh. **`Button`, `Slider`, `TextField`, `Card`, `Divider`, etc. stay UNRELATED to registry routing.**

Codex also flags: **the scoping doc said 80 view types but the component-mapping-matrix skill still says 59.** Phase 9 has to settle whether fallbacks, gate stubs, presenters, and compat files count. This is a freshness check on the existing matrix.

### Owner-screen loop: fixed window, not open-ended

```
T+0:  publish initial catalog draft
T+7:  owner-screen intake closes for 9A
T+9:  architect reconciles
T+10: Codex antagonist review
T+12: 9A close candidate
```

Late screens become backlog items / Phase 9B amendments. "Catalog complete" is not a real state; use "complete enough for first implementation slice."

## Intent additions from Codex

### Accessibility (cross-cutting contracts, NOT widget substitutions)
`manage_focus_after_navigation`, `restore_focus_after_dismiss`, `declare_screen_landmark`, `declare_group_semantics`, `provide_alternate_activation`, `scale_content_for_large_text`, `preserve_reading_order`, `announce_status_change`.

These don't fit the "different widget per platform" model. They're orthogonal — every widget must honor them. The catalog should call them out as a SEPARATE class of intent: "framework contract intents" vs "widget routing intents."

### Animation / transition
`transition_between_navigation_destinations`, `present_modal_context`, `dismiss_modal_context`, `reveal_contextual_actions`, `confirm_reorder_motion`, `show_loading_transition`, `respect_reduced_motion`.

### System integration
`share_content`, `copy_to_clipboard`, `paste_from_clipboard`, `request_permission`, `open_deep_link`, `open_external_url`, `import_file`, `export_file`, `handoff_to_system_app`, `print_document`.

### Edge / system gestures
`navigate_back_via_system_gesture`, `avoid_system_gesture_conflict`, `reveal_system_context_menu`, `support_predictive_back`, `support_edge_swipe_navigation`.

HIG explicitly says gestures must not be the only way to perform important actions (`.claude/skills/apple-hig/pages/gestures.md:23,31`). That's the source of the `requires_alternative_activation` capability predicate.

## Risk additions (R9-R16, all adopted)

- **R9 — Constructor type erasure.** Crystal typing makes return-different-concrete-classes painful.
- **R10 — Capability mismatch.** Override might select a widget that can't express required actions/destructive roles/icons.
- **R11 — Accessibility regression by override.** An override could create gesture-only interaction with no visible/keyboard path.
- **R12 — SSR/runtime split.** `web_narrow` vs `web_wide` is unknown at server render time — hydration mismatch risk.
- **R13 — Catalog inflation.** Beyond 25-40 intents the catalog becomes taxonomy theater.
- **R14 — Platform policy conflict.** Predictive back, edge swipe, macOS menu conventions are system behaviors, not interchangeable widget choices.
- **R15 — Matrix staleness.** The component matrix already drifts from `src/ui/views/` count; freshness check needed.
- **R16 — Override without state semantics.** Row actions, reorder, refresh, modals carry state/lifecycle implications beyond rendering.

## Codex's recommended 9A framing (verbatim adopted)

> Intent routing is opt-in and reserved for cross-platform interaction intents where the framework may choose materially different concrete UI::View implementations by platform or responsive context. Existing Tier 2 widgets remain the default authoring surface unless marked as routing candidates.

This goes in the 9A docs verbatim.

## Simpler architecture (Codex §9 — partially adopted)

Codex argues the simpler shape:
1. Keep existing concrete widgets.
2. Add intent catalog + translation matrix.
3. Add semantic factory helpers only for the small ambiguous set.
4. Let screens compose concrete widgets directly.
5. Permit platform-specific code through `AssetPipeline::Platform.requires` for genuinely app-specific divergence.

**Architect adopts this framing.** The intent registry is a routing layer for "same user need, different idiomatic interaction object" — not a second component system. **First implementation slice (Phase 10) proves one or two cases (`actionable_row`, `refresh_content`) before generalizing.**

## Scoping v2 changes

1. Tighten the scope: not all 80 views become intent-keyed. Most stay as-is. Routing candidates are flagged explicitly.
2. Drop the high-level constructor from the contract; defer to Phase 10 resolver pattern.
3. Add `capabilities` as a first-class part of the contract (4 parts, not 4 + constructor).
4. Add `intent-routing-candidates.md` as a 9A deliverable.
5. Split intents into THREE classes in the catalog:
   - **Widget-routing intents** (small set; framework picks different widgets per platform).
   - **Framework-contract intents** (cross-cutting; every widget must honor; accessibility lives here).
   - **System-integration intents** (single API surface; platform implementation varies).
6. Fix the freshness check: settle the 59 vs 80 widget count discrepancy in 9A.
7. Add the 12-day owner-screen intake window.
8. Architect-level framing sentence (Codex's wording verbatim) lands in 9A docs.

— Architect (Claude Opus 4.7)
