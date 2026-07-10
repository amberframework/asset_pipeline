# Phase 9 — Intent Catalog + Tier 2 Translation Contract (SCOPING DRAFT)

**Date opened:** 2026-05-25
**Status:** SCOPING — architect → Codex co-planner → owner-driven intent collection → brief.
**Branch:** to be cut as `phase-09-intent-catalog`.
**Predecessor:** Phase 8 collective review (in-flight).

---

## The problem being solved

Phase 8 closed the ergonomic MVC-style API. The library now has:
- 80 `UI::View` types in `src/ui/views/`.
- A tier model in CLAUDE.md:148-160 (Tier 1 brand-universal; Tier 2 platform-default; Tier 3 platform-only).
- A `component-mapping-matrix` skill catalogging UI::View → SwiftUI/UIKit/AppKit/Compose/HTML translations per VIEW TYPE.

**What's missing:** the framework documents that Button is a Tier 2 widget that "maps to the idiomatic native widget" on each platform, but it does NOT document:

1. **What user *intent* each Tier 2 widget fulfills.** Why does an app reach for `UI::Button` vs `UI::IconButton` vs `UI::MenuButton` vs `UI::LinkButton`? The user intents these fulfill are distinct ("trigger an action" vs "trigger an action with icon-only chrome" vs "open a menu of actions" vs "navigate") — but nothing names them.

2. **The DEFAULT platform translation per intent.** Today the translation is hard-coded in each renderer's `visit(UI::Button)`. If an author wants per-row actions, they pick `UI::SwipeActionRow` and accept whatever the renderer does. They cannot ask the framework "give me the default per-row-actions widget" and have it pick swipe on iOS, inline buttons on macOS, drag-handles on web-wide.

3. **An override mechanism.** When an author wants something different than the framework default (e.g. "on iOS I want inline buttons, not swipe"), there's no documented hook. They have to write platform-specific code or fork the widget.

This was the gap that surfaced when the owner described "the Mail app swipe behavior" — the framework HAD a SwipeActionRow but no one had named the *intent* it fulfilled, so we didn't know if we'd already shipped it.

## What "Tier 2 translation contract" means concretely

A widget is Tier 2 if it has a universal API surface that maps to a different idiomatic native widget per platform. Today's contract (implicit):

```
UI::Button (universal Crystal class)
  → visit(view) in each renderer:
     - UIKit::Renderer.visit(Button) → UIButton + SwiftUI Button facade
     - AppKit::Renderer.visit(Button) → NSButton
     - Web::Renderer.visit(Button) → <button>
     - Android::Renderer.visit(Button) → MaterialButton
```

The author writes `UI::Button.new("Save")` and gets the platform's idiomatic button. They cannot intervene; they can only style via tokens.

**Proposed contract (explicit):**

```
UI::ActionableRow (intent: "let user pick from N actions on a row item")
  defaults_to:
    :ios            → UI::SwipeActionRow
    :ipados         → UI::SwipeActionRow
    :macos          → UI::InlineActionRow
    :android        → UI::SwipeActionRow
    :web_wide       → UI::InlineActionRow
    :web_narrow     → UI::SwipeActionRow

Author override (per-app):
  VoyagerApp.override_intent :actionable_row,
    with: UI::DragHandleRow, on: [:web_wide, :web_narrow]

Author override (per-screen):
  class SettingsScreen < UI::Screen
    override_intent :actionable_row, with: UI::InlineActionRow, on: [:ios]
  end
```

The four parts of the contract:

1. **An intent identifier** (Symbol). Names the user need without naming the implementation.
2. **A default-translation table.** Per platform key (or platform+responsive-state key), the concrete `UI::View` class the framework uses.
3. **An override registry.** App-level + screen-level overrides, stored in a registry queried at render time.
4. **A high-level constructor.** `UI::ActionableRow.new(...)` resolves through the registry → returns the matching widget instance.

## The intent taxonomy

The catalog is the foundation. Without it, "Tier 2 translation contract" is just an empty registry. Sources we draw from:

1. **Apple HIG** (`.claude/skills/apple-hig/pages/`):
   - `gestures.md` — swipe, long-press, drag, pinch, etc.
   - `inputs.md` — keyboard, pointer, Apple Pencil, etc.
   - `selection-and-input.md` — picking, text entry, value adjustment.
   - `drag-and-drop.md` — moving/copying content.
   - Plus the component pages (Buttons, Pickers, Sheets, etc.) which name the intents implicitly.

2. **Android Material Design / Compose** (`android-compose-components` skill).

3. **Web HTML/CSS interaction patterns** — form controls, drag-and-drop API, ARIA roles.

4. **Owner-provided screens.** Owner has stated they'll find additional examples that reveal intents we'd otherwise miss. The Mail-app-swipe example is the model: a behavior that's obvious in context but doesn't appear in the HIG component listing.

5. **Cross-platform pattern languages** — e.g., Material's "interaction states," Apple's "selection patterns."

The catalog should be **intent-keyed**, not component-keyed. Intent names should be neutral re: implementation (use "select_one_from_few" not "segmented_control").

## Candidate intent groups (strawman — owner refines via screens)

These are the rough buckets. Each group expands to 3-8 specific intents. Final list lands at ~25-40 intents.

**Selecting & Picking**
- Pick one from a few options
- Pick one from many options
- Pick multiple from a set
- Pick a value from a range
- Pick a date / time / date-time
- Pick a color
- Pick a file / photo / contact

**Triggering & Acting**
- Trigger a primary action
- Trigger a destructive action (with confirmation)
- Trigger a quick toggle
- Trigger an action on a list item ← Mail-app-swipe lives here
- Trigger an action that opens a menu of related actions

**Navigating**
- Navigate forward (push)
- Navigate back (pop)
- Navigate to a sibling section (tabs / sidebar)
- Navigate to a related context without losing place (popover / sheet)
- Navigate to a modal task and back (full-screen modal)

**Editing & Entering**
- Enter a short string (email, name)
- Enter a long string (note, description)
- Enter a secure string (password)
- Enter a numeric value
- Edit existing structured data (form)
- Reorder items in a list ← drag-to-reorder lives here

**Browsing & Discovering**
- Browse a long list of items
- Browse a list with filtering / search
- See related context next to an item (master-detail)
- Drill into an item for more detail
- Refresh a list / view (pull-to-refresh)

**Feedback & Status**
- Show a transient confirmation (snackbar / toast)
- Show a persistent status (banner)
- Show progress for a long task
- Show a non-blocking notification

**System Integration**
- Share content with another app
- Save to system clipboard
- Print
- Open a URL

**Affordances**
- Reveal a tooltip / help-text
- Show pointer hover effects (iPad pointer / desktop hover)
- Give haptic feedback on confirmation
- Provide keyboard shortcut for an action

This is roughly the shape; the owner's screens will refine + add.

## The override mechanism — design space

Three real decisions to make.

### D1: Override scope

- **App-level only** — author overrides per `UI::App` subclass. Simple; matches `Brand`. But can't override per-screen.
- **Screen-level only** — overrides in `class FooScreen < UI::Screen`. Flexible but verbose if many screens want the same override.
- **Both** — app-level default; screen-level overrides app-level. More API surface but matches how CSS / theming usually works.

**Architect lean: both.** Phase 9 doc lays out both; Phase 10 ships app-level first, screen-level as a quick follow-on.

### D2: Platform key granularity

- **Platform-only** — `:ios, :ipados, :macos, :android, :web`. Five keys.
- **Platform + responsive state** — `:ios, :ipados, :macos, :android, :web_wide, :web_narrow`. Six keys.
- **Platform + size class** — full breakpoint matrix like CSS. Many keys; complex.

**Architect lean: platform + binary web responsive** (six keys). Wide vs. narrow web is the most common real branching. Anything finer is the application's job, not the framework's.

### D3: Implementation timing

- **Phase 9 ships catalog + contract design ONLY; Phase 10 implements override registry.** Fastest path to documented coverage.
- **Phase 9 ships catalog + contract design + implementation together.** Higher risk of contract churn during implementation.

**Architect lean: split.** Catalog can be wrong; better to have it visible + reviewed before locking in the API. Override registry implementation should land after the catalog has stabilized.

## Sub-phasing

This phase has an inherent **owner-driven discovery loop** (owner provides screens; architect extracts intents). So:

- **9A — Initial catalog + contract design.** Architect drafts catalog from HIG + Android + web sources; designs the contract; produces the coverage matrix against current widgets. Closing gate: doc lands, no implementation.
- **9-DISCOVER — Owner-screen loop.** Owner provides screens; architect extracts new intents into the catalog. Loops until owner says catalog is complete. This is NOT a sub-phase; it's an ongoing-while-9A-is-open activity OR happens between 9A and 9B.
- **9B — Override registry implementation.** (Future phase if architect lean adopted.)

For now, scope this scoping doc as 9A territory only. 9B is a follow-on.

## What 9A ships

1. **`docs/initiative-cross-platform-ui/architecture/intent-catalog.md`** — every intent named + described in user-need language. Sources cited (HIG page, Material page, web pattern).
2. **`docs/initiative-cross-platform-ui/architecture/translation-matrix.md`** — for each intent, the default per-platform translation (which existing `UI::View` class, or `MISSING — backlog item`).
3. **`docs/initiative-cross-platform-ui/architecture/tier-2-translation-contract.md`** — the contract definition: how intents are declared, how defaults are registered, how overrides work, why this exists. Reference architecture doc.
4. **`docs/initiative-cross-platform-ui/architecture/intent-backlog.md`** — intents where no shipped widget covers the default for some platform. Each entry: intent name + platform + what's missing + rough size estimate.

NO code changes in 9A. NO new `UI::View` classes. NO registry implementation.

## Risk register

- **R1** — Intent catalog over-fits to the apps we have. *Mitigation:* draw from HIG/Material/web first (authoritative sources), then owner screens, then existing widgets. Don't just walk `src/ui/views/`.
- **R2** — Bike-shedding intent names. *Mitigation:* intent names follow `{verb}_{object}` convention (e.g., `pick_one_from_few`, `trigger_destructive_action`). Codex critique on naming consistency.
- **R3** — Owner-screen loop is open-ended. *Mitigation:* set a soft deadline (e.g., 7 days from 9A start); after that, ship 9A with a "more intents may surface" caveat. Owner can add to the catalog later via PR.
- **R4** — Translation matrix has subjective entries (e.g., "default per-row-actions on macOS — inline buttons OR right-click menu?"). *Mitigation:* pick one default + document the alternative as a known override pattern.
- **R5** — Phase 9A produces docs that conflict with what Phase 10 implements. *Mitigation:* explicit API-design straw in 9A (the four-part contract above) so 10 is implementation, not redesign.
- **R6** — Existing Tier 2 widgets (Button, Sheet, etc.) don't fit the intent model cleanly because they already have one universal API. *Mitigation:* not every Tier 2 widget needs to be intent-routed. Only widgets where DIFFERENT WIDGETS would be appropriate per platform get an intent-route. Single-widget Tier 2 entries stay as they are.
- **R7** — Web's "narrow vs wide" is run-time, not compile-time. *Mitigation:* the override mechanism handles this; in 9A we just declare the dimension. Implementation in 9B/10 deals with media-query routing.
- **R8** — Existing widget names may not match intent vocabulary. *Mitigation:* don't rename existing widgets in 9A; just map them to intents.

## Open questions for Codex co-planner

1. Is the four-part contract (intent id + default-table + override-registry + high-level constructor) the right shape, or should it be simpler (just a registry, no constructor)?
2. Is the "platform + binary web responsive" key set right, or should we go finer (size classes) or simpler (platform-only)?
3. Should the override be per-app, per-screen, or both? Matching `Brand`'s app-only model is simpler.
4. Should the override mechanism be co-designed in 9A, OR should 9A only ship the catalog and leave the override mechanism for 9B?
5. Are there any intents I've missed? In particular: accessibility intents (VoiceOver landmarks?), animation intents (entrance/exit?), platform-system intents (open in another app, request system permission)?
6. Anything I'm not seeing.

## Hard rules

- Forward commits only on `phase-09-intent-catalog`.
- NO code changes in 9A. Docs only.
- NO renames of existing `UI::View` classes.
- The catalog is INTENT-KEYED, not component-keyed.
- The catalog cites authoritative sources (HIG page slug, Material page, web pattern doc).
- Owner-screen feedback loop is part of the workflow; the catalog isn't "done" until owner signs off.
- Codex per-iteration review.
- Standard Claude co-author footer.

---

**Next steps:**

1. Send to Codex as co-planner.
2. Reconcile Codex response.
3. Draft initial intent catalog from HIG/Material/web sources.
4. Owner provides reference screens; architect extracts intents.
5. Author brief; Codex antagonist; revise.
6. Dispatch implementer (the implementer's job is mostly to verify the catalog against the codebase + author the matrix doc; the catalog itself is largely architect work).
7. Tag 9A close. Defer 9B (override registry implementation) to a later phase.

— Architect (Claude Opus 4.7)
