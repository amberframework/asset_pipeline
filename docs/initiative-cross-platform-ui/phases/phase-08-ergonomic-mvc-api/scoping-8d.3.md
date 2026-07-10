# Phase 8D.3 — 14-Row Interaction Proof + Captures + Disposition (SCOPING DRAFT)

**Date opened:** 2026-05-25
**Status:** SCOPING — architect → Codex co-planner → brief.
**Branch:** to be cut as `phase-08d.3-interaction-proof-and-captures` after planning lands.
**Predecessors:**
- Phase 8D.1 `phase-08d.1-pass-with-notes-2026-05-25` (macOS dispatcher migration).
- Phase 8D.2 `phase-08d.2-pass-with-notes-2026-05-25` (iOS dispatcher migration).

---

## The problem being solved

Phase 8D.1 + 8D.2 wired the dispatcher into Voyager's native hosts. The Crystal + build + XCUITest layers prove the architecture is correct. But owner-driven interaction proof has been deferred TWICE (8D.1 path-2, 8D.2 path-2). The architectural promise of "live action dispatch on a real simulator" is unproven beyond cold-launch + AX-discovery. **8D.3 is the last responsible phase before 8E (docs) where the hand-test gate can land.**

Concurrently, the long-deferred Phase 6.11 14-row Voyager behavior contract (defined originally in `phases/phase-06.11-ios-polish-defaults/brief.md`, deferred through 6.12 → 8B → 8D.1 → 8D.2) needs to land. The 14 rows are the canonical "this works as a real app" gate. 28 iOS captures (14 × light+dark) + macOS equivalents are the evidence.

A third concern: `Voyager.build_route` compat shim's permanent disposition. Web `static_site.cr` still calls it; the Phase 8D co-plan picked B2 (web stays static; not on the unified-dispatcher path).

## Three layered problems

### A. UI behavior bug blocking the 14-row contract — Save-enabled-on-type

`samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr:120`:
```crystal
save.disabled = seed_title.strip.empty?
```

`save.disabled` is set ONCE at render time. The title field's `on_change` only writes to `FormState` (via `fs.register("title", ...)`); it does NOT re-evaluate `save.disabled`. So Row 4 of the 14-row contract ("Type 'Rem 6.11 test' into title field → Save button enables") cannot pass as-is.

This bug has been deferred 4 phases: 6.11 → 6.12 → 8B → 8D.1 → 8D.2. Each phase's Codex review flagged it; each phase chose to defer. 8D.3 should fix it OR formally adjust the 14-row contract.

### B. 14-row interaction proof — capture matrix

14 rows × 2 appearances = 28 iOS captures. Per Phase 6.11 brief's table: each row is a testable sequence of taps that produces a specific visible state, screenshotted in both light and dark appearance.

macOS equivalents: the swipe-revealed rows (7, 8, 10) don't map directly to AppKit (no swipe gesture on NSTableView). Open question: substitute with context-menu or trailing buttons, OR mark macOS as covering only the non-swipe rows?

### C. Hand-test gate — owner runs the 7-step recipe

Item 9 from brief-8d.2.md. The owner runs the recipe on the simulator with real touch input. This is the [[owner-hands-on-finds-real-bugs]] gate — the highest-fidelity interaction proof.

### D. `Voyager.build_route` compat shim disposition

Three options:
- **D1.** Keep as-is. Doc as the permanent static-site entry point.
- **D2.** Rename to `Voyager.build_route_for_static_site` to make intent clear.
- **D3.** Migrate `web/static_site.cr` to call screen.build directly (constructs its own ScreenContext::Native).

**Architect lean: D1.** Renaming has migration cost (callsite update + doc churn) without architectural benefit. Migrating web has cost without clear payoff (web isn't on the unified-dispatcher path per 8D co-plan B2). Keep + doc.

### E. B2 web architecture position note (documentation)

Phase 8D co-plan picked B2 (Voyager web stays static-site; Amber web is a separate proof path covered by Phase 8C). 8D.3 should commit a position note in `docs/initiative-cross-platform-ui/` (probably in the handoff directory or a new `architecture/` subdir) that says:

- The "unified UI::App declaration drives all 3 targets" claim is true for native (macOS + iOS).
- Web has TWO modes: (i) static-site (Voyager's path; uses `Voyager.build_route` shim); (ii) full Amber server (Phase 8C's `routes_for(UI::App)`; proven on `samples/phase-08-amber-spike/`).
- Future Voyager web could migrate to Amber but is NOT a regression as static-site.

## Scope candidates

### Item 1 — Fix Save-enabled-on-type in `todo_editor.cr`

Two implementation paths:

**1A. Reactive Button.disabled via dispatcher Rerender.**
- `title_field.on_change` dispatches `:title_changed` action_ref.
- `TodoEditorController#title_changed(ctx)` returns `UI::ActionResult::Rerender`.
- The screen rebuilds; `save.disabled` is re-evaluated from `ctx.form_state["title"]`.

Cost: every keystroke fires a Crystal dispatch + full screen re-render. Heavy.

**1B. Local UI state — direct Button mutation on title field change.**
- `title_field.on_change` directly mutates `save.disabled = value.strip.empty?` via a captured reference (closure).
- No dispatcher involvement; pure local UI behavior.

Cost: ergonomically clean for this case but breaks the "every state mutation through dispatcher" architectural rule.

**1C. Phase 8B's reactive-button feature (if it exists / can be wired).**
- Check whether `UI::Button` has any reactive-disabled binding to a `FormState` field. If yes, wire `save.disabled` to a binding on `form_state["title"]`. If no, this option is unavailable.

Architect lean: **1A is architecturally honest but expensive.** **1B is the right pragmatic choice for an Editor screen.** Codex should weigh in.

### Item 2 — 14-row capture matrix

Per Phase 6.11 brief's table. 28 iOS captures using `xcrun simctl io DEVICE screenshot OUTPUT.png` after walking the simulator through each row's state.

The capture script must:
- Boot the iPhone 17 Pro simulator (or whatever's installed).
- Install + launch `VoyagerDemo.app`.
- For each row, drive the simulator into the required state (taps, types, swipes) using `xcrun simctl` + AppleScript-driven tap synthesis OR scripted XCUITest setup.
- Capture screenshot in light, switch appearance via `xcrun simctl ui DEVICE appearance dark`, recapture.
- Commit to `docs/initiative-cross-platform-ui/handoff/phase-08d.3-evidence/voyager-{row-id}-{light,dark}.png`.

**Open question:** Phase 6.10 documented that XCUITest tap synthesis on Crystal-rendered UIButtons does NOT reliably fire on_tap. If the capture script depends on synthesized taps, the captures will fail at Row 2 (Sign in tap).

**Alternative:** Set `VOYAGER_ROOT_SLUG=voyager-<route>` to skip directly into each route's initial state, then capture. This bypasses interaction (just renders that route), losing the "interaction proof" character of the contract. Several rows (6 toggle, 7 swipe-revealed, 9 after-edit, 13 filtered) require state changes that ROOT_SLUG can't produce alone.

**Third alternative:** Author a `--scenario` flag on the iOS bridge or a launch-arg-driven path that walks Crystal's coordinator + state mutations directly to the target row state, then renders. The screenshot is of the resulting state without needing tap synthesis. **Architect lean: this third option.**

### Item 3 — macOS equivalents

Determine which rows map to macOS and capture them. Open question: do non-swipe rows (1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14) get macOS captures? Do swipe rows (7, 8) get macOS substitutes via right-click context-menu or visible action buttons? Architect lean: capture the non-swipe rows on macOS (12 rows × 2 appearances = 24 macOS captures), document swipe rows as iOS-only.

Combined matrix: 28 iOS + 24 macOS = 52 captures total. Heavy.

### Item 4 — Save Item 1 + hand-test gate

The 7-step hand-test recipe from brief-8d.2.md Item 9. Owner runs it on the simulator with real touch input. Architect coordinates: implementer ships build + recipe → architect surfaces to owner → owner reports PASS/FAIL per step.

### Item 5 — `Voyager.build_route` shim disposition

Choose D1/D2/D3 (architect lean D1). If D1, add a doc note + one-line method docstring. If D2/D3, migration work.

### Item 6 — B2 web architecture position note

Commit a position note. Two-page max.

### Item 7 — macOS host migrate to `HostBootstrap.build` (optional cleanup)

Codex flagged this as 8D.2 follow-up. The helper exists; macOS still hand-rolls construction in `host.cr#run!`. Migration would unify both hosts on one entry point. Pure cleanup. Architect lean: defer to a later phase unless it's trivially cheap.

## Sub-phase decision

8D.3 is large. Three sub-phasing options:

**8D.3 as one phase.** Risk: too many moving parts (UI bug fix, capture matrix, hand-test, disposition, doc note). Implementer will mid-stop at capture work; architect will lose checkpoint cadence.

**Split into 8D.3a (UI fix + hand-test) and 8D.3b (capture matrix).** 8D.3a closes the architectural debt (Save bug + owner verification). 8D.3b is pure evidence work. The shim disposition + position note can land in either.

**Split into 8D.3a (UI fix), 8D.3b (capture matrix), 8D.3c (hand-test + disposition).** Three sub-phases is overkill — 8D.3c is a 30-minute task once 8D.3a + 8D.3b land.

**Architect lean: 2-sub-phase split.**
- **8D.3a** — Save-enabled-on-type fix + hand-test gate execution + shim disposition + position note. All-architecture, no captures. Closing gate: hand-test PASS.
- **8D.3b** — 28 iOS captures + 24 macOS captures. All-evidence. Closing gate: capture matrix complete.

Codex partner: validate or counter this split.

## Risk register

- **R1 — Save-enabled-on-type fix may interact with FormState wire-time hook.** The title field's existing on_change writes to FormState via the renderer's wrap_text_handler. Adding a closure that mutates `save.disabled` on the same on_change may or may not compose cleanly. Implementer verifies on first iteration.
- **R2 — XCUITest tap synthesis still doesn't fire on_tap.** Same Phase 6.10 limitation. Capture matrix MUST NOT depend on synthesized taps. The launch-arg/scenario path (Item 2 third alternative) is the workaround.
- **R3 — Mid-stop at capture work.** Per `[[mid-stop-pattern]]`: implementer agents stop at simulator screenshot/interactive flows. Split dispatch is mandatory.
- **R4 — macOS swipe gestures don't exist natively.** Rows 7, 8, 10 may need macOS-substitute design. Open question; defer to brief.
- **R5 — Hand-test gate failure cascades.** If owner finds a bug during the recipe, 8D.3a fails — and the bug may be the very pattern 8D.1 + 8D.2 said was correct. The remediation could pull back into the dispatcher, FormState, or renderer layers. Mitigation: hand-test FIRST, captures SECOND.
- **R6 — Web shim disposition is a doc-only decision but has long-term implications.** If D1 (keep), web stays divergent forever. If D2 (rename), the rename has to land in 8C consumers too. Codex weighs in.
- **R7 — Capture-matrix tooling drift.** The `xcrun simctl` invocations + xcodebuild paths drifted between 6.11 + 8D.2. Implementer should verify the working invocation pattern before declaring a baseline.

## Open questions for Codex

1. **Sub-phase split.** Is the 2-phase 8D.3a/8D.3b split the right shape, or is single-phase cleaner with strict gating?
2. **Save-enabled-on-type fix path (1A/1B/1C).** Reactive Rerender (architecturally pure but expensive) vs local closure mutation (pragmatic but breaks rule) vs hypothetical Phase 8B reactive Button (need to verify exists)?
3. **Capture-driver design.** Scenario-flag pre-walked state (architect lean) vs XCUITest scripted taps (blocked by Phase 6.10 tap-synthesis limitation) vs manual hand-driven captures (slow, error-prone)?
4. **macOS swipe-row coverage.** Capture only non-swipe rows on macOS (architect lean), substitute with right-click context-menu, OR skip macOS captures entirely?
5. **Web shim disposition.** D1/D2/D3 — pick one with justification.
6. **macOS HostBootstrap cleanup.** Defer to later phase, OR bundle into 8D.3a as a 30-line cleanup?
7. **Hand-test gate placement.** Run before captures (8D.3a) so bugs surface early, or after captures (8D.3b) so owner sees the full proof at once?
8. **Anything I'm not seeing.**

## Hard rules (preserved into the brief)

- Forward commits only on `phase-08d.3-*` branches.
- NO Phase 8A/8B/8C/8D.1/8D.2 API changes. 8D.3 is evidence + tiny UI polish.
- The Save-enabled-on-type fix MUST NOT change `UI::Button` or `UI::FormState` or `UI::TextField` API surfaces. It's a Voyager-side wiring change ONLY.
- Mid-stop dispatch protocol mandatory for capture work.
- Codex per-iteration review.
- Standard Claude co-author footer.

---

**Next steps:**

1. Send to Codex as co-planner.
2. Iterate on Q1-8.
3. Convert refined plan → `brief-8d.3a.md` (+ `brief-8d.3b.md` if split).
4. Codex antagonist on brief(s).
5. Owner checkpoint.
6. Cut branch + dispatch.

— Architect (Claude Opus 4.7)
