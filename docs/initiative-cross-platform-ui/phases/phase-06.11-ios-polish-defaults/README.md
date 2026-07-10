# Phase 6.11 — iOS-First Polish + SwiftUI Defaults

**Inserted:** 2026-05-23, after Phase 6.10 PASS_WITH_NOTES.
**Dependencies:** Phase 6.10 PASS_WITH_NOTES (tag `phase-06.10-pass-with-notes-2026-05-23`).
**Blocks:** Initiative final sign-off + Phase 6.12 macOS polish.

## Why this phase exists

Phase 6.10 met its brief — the Voyager Todos demo is navigable, the
NavigationCoordinator + SwipeActionRow primitives shipped, AX traversal
works, taps fire, Save propagates. But owner hand-test of the iPhone 17
Pro build surfaced three polish gaps that block "feels like a real app":

1. **Illegible text** on Todos screen — white text on off-white surface.
2. **Brand override produces low-contrast output** — the deep-indigo +
   teal-button branding doesn't include contrast-correct text-on-brand
   color pairs, so surfaces using the brand color render with mismatched
   foregrounds.
3. **CRUD doesn't feel functional** — typed save shows the result but
   toggle-complete-in-row, swipe-delete, edit-then-save, and Settings
   filter don't yet feel like real interactions.

Owner directive (verbatim):

> "I'd like it if you stuck with the default colors for the Swift UI
> before we try overwriting them. I know that we have the teal button
> right now, but if you could just stick with whatever the default
> styling is that we're binding to in this Swift, that would be more
> ideal for getting to a working 'final' version of this component
> system."

So this phase intentionally **drops the Voyager brand override** to
validate the SwiftUI default binding chain works end-to-end. Once defaults
work, future phases can revisit how brand overrides should layer in
contrast-correct color pairs.

## Scope

**In scope (iOS only — macOS is Phase 6.12):**

1. **Drop Voyager brand override.** `samples/.../brand.cr` either
   deleted or stripped to a no-op. Voyager screens use SwiftUI defaults
   (system blue prominent buttons, system label colors on system surfaces).
2. **iOS Todos text legibility verified.** After dropping the brand
   override, all 4 screens have legible text in both light + dark
   appearance. If something still doesn't read legibly, identify the
   specific token / renderer path producing it and fix.
3. **Functional Todos polish:**
   - Type todo title → tap Save → row appears in list immediately with
     correct title.
   - Toggle complete in a row (via UI::Toggle or row tap) → row visually
     reflects completed state (strikethrough / dimmed) → chart counts
     update.
   - Swipe-delete a row → row removes from list → chart counts update.
   - Edit a todo from swipe → save → row updates with new title.
   - Settings filter (Hide completed) → toggle → back → Todos list
     visibly filters.
4. **iOS hand-test gate** — owner runs the flow on iPhone 17 Pro and
   confirms all of the above.

**Explicitly out of scope:**

- macOS polish (window sizing, width-resizable, legibility) → Phase 6.12.
- Brand override redesign (semantic contrast pairs) → future phase.
- Cascade demo modifications.
- Android renderer changes.
- URL routing / deep links.
- Adding new widgets.

## Acceptance

Owner can:

1. Launch the Voyager iOS app on iPhone 17 Pro simulator.
2. See all 4 screens with LEGIBLE text in both light + dark appearance.
3. Sign in (any valid email + password).
4. Tap Add Todo → type title → Save → see new row in list with chart
   counts updated.
5. Toggle complete on a row → see visual completed state + chart counts
   change.
6. Swipe a row left → see Edit + Delete actions.
7. Tap Edit → modify title → Save → see row update with new title.
8. Tap Delete → row removes from list, chart counts update.
9. Navigate to Settings → toggle Hide completed → back → see filtered
   list + correct chart counts.
10. Repeat 4-9 in dark appearance (sim toggle) — text remains legible.

Plus:

- `crystal spec` baseline preserved (1497/4/0 or improved).
- No new uncritiqued diagnostic logging in shipped commits.
- Codex per-iteration review of Implementer's work AND architect-side
  Codex review of this brief before dispatch (per
  [[codex-as-architect-antagonist]] directive).

## Risk notes

- **Dropping the brand override may surface OTHER hidden bugs** that
  were masked by the override. Treat surprises as evidence-bearing, not
  blockers — diagnose, document, decide whether to fix in 6.11 or
  defer.
- **Toggle / Swipe-Delete may share the SwiftUI Button bug class** that
  Path A fixed in Rem 3 — verify those facades fire via the
  [[native-interaction-instrumentation]] grep-token NSLog pattern before
  declaring them working.
- **Hand-test is the closing gate** (per [[owner-hands-on-finds-real-bugs]]).
  Audit harness PASS is necessary but not sufficient.

## Briefing documents

- Implementer brief: `brief.md` (architect-Codex critiqued)
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
- Reflection on close: `../../handoff/phase-06.11-reflection-{date}.md` (TBD)
