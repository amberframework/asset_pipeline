# Phase 8D.3a — Save-Enabled-On-Type Fix + Owner Hand-Test Gate + Shim Disposition (BRIEF v1)

**Date drafted:** 2026-05-25
**Status:** Brief v1 — pending Codex antagonist critique.
**Branch:** `phase-08d.3a-interaction-proof-and-disposition` (to be cut at owner-approval checkpoint).
**Predecessors:**
- Phase 8D.1 `phase-08d.1-pass-with-notes-2026-05-25`.
- Phase 8D.2 `phase-08d.2-pass-with-notes-2026-05-25`.
**Planning artifacts:** `scoping-8d.3.md`, `coplan-8d.3-codex-1.md`.
**Successor:** `brief-8d.3b.md` (to be drafted after 8D.3a closes).

---

## 1. Mission

Close the long-deferred Save-enabled-on-type behavioral bug in `TodoEditorScreen` AND run the owner hand-test gate that 8D.1 + 8D.2 both deferred. Resolve the `Voyager.build_route` web shim disposition to D1 (keep, doc). Commit the B2 web architecture position note.

This is an architecture + verification phase. NO capture work — that's 8D.3b.

## 2. Architectural reframing — view-local affordance vs app/domain state

Per Codex co-plan §8: the Save button's enabled/disabled is **view-local control affordance state**, NOT app/domain state. The "every state mutation through dispatcher" architectural rule applies to app/domain state (todos list, user session, settings flags). Local UI affordances — a button's disabled state mirroring a single field's emptiness, a tooltip showing on hover — are local UI affordances and may be wired with closures over view references.

This reframing was always implicit; 8D.3a writes it down so future contributors don't dispatch through controllers for trivial UI feedback.

## 3. Frozen surfaces

- **No public UI framework API changes.** `UI::Button`, `UI::FormState`, `UI::TextField`, `UI::Controller`, `UI::ActionDispatcher`, `UI::ActionResult` all unchanged.
- **No C ABI changes** to `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr`.
- **No Swift production code** edits.
- **No `Voyager.build_route` rename or migration.**

## 4. Item-by-item scope

### Item 1 — Save-enabled-on-type fix in `TodoEditorScreen`

**File:** `samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr`.

**Approach (Codex co-plan §3 — option 1B):** local UI mutation through the existing reactive `UI::Button#disabled=` setter. The button's `disabled=` is reactive — assigning a new value propagates to native through `apsk_button_set_disabled`. So a closure on the title field's `on_change` that mutates `save.disabled` is sufficient.

**Reference implementation:**

```crystal
# In TodoEditorScreen#build, AFTER both title_field and save have been
# constructed (the closure needs to capture the `save` reference):

title_field.on_change = ->(value : String) {
  # View-local affordance: disabled mirrors title-emptiness.
  # The existing UI::FormStateRendererHook.wrap_text_handler composes
  # this with FormState.update("title", value), so domain state still
  # flows through FormState; this closure only updates the visible
  # affordance.
  save.disabled = value.strip.empty?
}
```

**Implementation detail:** The current code at `todo_editor.cr:34-67` constructs `title_field` BEFORE `save` (which is at `:110`). The closure assignment must go AFTER `save` exists, OR `title_field.on_change` is assigned later in the build method. **Implementer chooses:** the simplest re-ordering that makes the closure capture `save` cleanly. Don't introduce intermediate variables or restructure broader scope.

**Composition with `wrap_text_handler`:** the renderer hook composes:
1. Stale-fire guard (mount_token + form_state matches).
2. `captured_fs.update(name, new_value)` — FormState write.
3. `user_handler.try(&.call(new_value))` — user's `on_change` callback.

So FormState gets the typed value FIRST, then our closure runs SECOND. Both writes happen on every keystroke.

### Item 2 — Crystal smoke spec for the wiring

**File:** `spec/asset_pipeline/voyager_todo_editor_save_disabled_spec.cr` (new).

Doesn't require iOS — exercises the screen's build method directly + asserts that the closure assigned to `title_field.on_change`, when invoked with various string values, mutates `save.disabled` to the expected value. Architect-direction examples:

- Empty title → `save.disabled == true`.
- Whitespace-only ("   ") → `save.disabled == true`.
- "anything" → `save.disabled == false`.
- Title becomes empty again → `save.disabled == true`.

Cover the editing-prefilled case too (Editor opened with seed title; user clears the field → `save.disabled` becomes true).

### Item 3 — `TodoEditorController#save` defensive-fallback documentation

Per Codex R11: `TodoEditorController#save` currently calls `Pop` on blank-title save attempts. With Item 1 the button is disabled on blank, so this branch is unreachable from the UI — but it remains a defensive fallback for any code path that bypasses the disabled affordance.

Implementer adds a one-line code comment in `samples/initiative-cross-platform-ui-voyager/controllers/todo_editor_controller.cr` at the blank-title check:

```crystal
# Defensive fallback: with Phase 8D.3a's title-field on_change closure,
# save.disabled is true while title is blank, so this branch is
# unreachable from the UI. Kept for safety against renderer
# implementations that ignore disabled state.
```

NO behavior change in the controller.

### Item 4 — Owner hand-test gate (BLOCKING)

The 7-step recipe from `brief-8d.2.md` Item 9, executed on the iOS simulator by the owner. Architect coordinates: implementer ships build artifacts + recipe → architect surfaces to owner → owner reports PASS/FAIL per step.

**Recipe (verbatim from brief-8d.2.md Item 9):**

1. Open simulator. Launch VoyagerDemo. Confirm Sign-in screen renders.
2. Tap "Sign in". Confirm navigation to Todos (5 seed rows visible).
3. Tap "Add Todo". Confirm Editor screen renders with empty title field + disabled Save. Tap "Cancel". Confirm Pop to Todos with NO new row.
4. Swipe a seeded row → tap "Edit". Confirm Editor renders with title prefilled + ENABLED Save. Edit the title (e.g. append " updated"). Tap "Save". Confirm Pop to Todos with row showing updated title.
5. Tap a row's checkbox. Confirm checkmark applies + title strikethrough renders.
6. Swipe a row → tap "Delete". Confirm row disappears from the list.
7. Tap "Settings". Toggle "Hide completed". Tap "Back to todos". Confirm Todos rerenders with completed rows hidden.

**Plus an extension (Item 1 verification):**

8. With the Editor at empty title (Step 3 state, before tapping Cancel), tap into the title field, type "x". Confirm Save button ENABLES. Backspace to empty. Confirm Save button DISABLES. (Tests Item 1's reactive wiring directly.)

**Owner reports** PASS/FAIL per step. ALL 8 steps must PASS for 8D.3a to close. If a step fails, implementer remediates and re-dispatches.

### Item 5 — `Voyager.build_route` D1 disposition + comment cleanup

**File:** `samples/initiative-cross-platform-ui-voyager/app.cr`.

The existing docstring/comments (per `samples/initiative-cross-platform-ui-voyager/app.cr:16-24, 86-103`) describe the shim as a "Phase 8D.1 compat shim" with iOS as a caller. As of 8D.2, iOS no longer calls it. Update the comments:

- The shim is now the **permanent static-site entry point** for `web/static_site.cr`.
- iOS no longer calls it (post 8D.2).
- Web's static-site path is the only live caller.
- Rename is NOT planned — too much migration churn for too little benefit per Codex co-plan §2.5.

**Concrete edit:** rewrite the docstrings at `app.cr:16-24` and `app.cr:86-103` to describe the post-8D.2 state. Don't rename the method.

### Item 6 — B2 web architecture position note

**New file:** `docs/initiative-cross-platform-ui/architecture/web-target-position.md` (create the `architecture/` directory).

**Content (2 pages max):**

- Header section: "Voyager web is a static-site target; Amber is a separate full-server proof."
- Architectural claim split:
  - "Unified UI::App declaration drives native (macOS + iOS) via UI::ActionDispatcher" — TRUE per 8D.1 + 8D.2.
  - "Unified UI::App declaration drives Amber web via UI::AmberIntegration.routes_for" — TRUE per Phase 8C (proven at `samples/phase-08-amber-spike/`).
  - "Voyager web specifically uses the static-site mode (which is NOT on the unified dispatcher path)." This is deliberate — Voyager web prioritizes deployable static HTML over live action dispatch.
- Code paths:
  - Static-site web: `samples/initiative-cross-platform-ui-voyager/web/static_site.cr` → `Voyager.build_route` shim.
  - Amber web: `samples/phase-08-amber-spike/config/routes.cr` → `UI::AmberIntegration.routes_for`.
- Future work option: a Voyager Amber port is possible (Phase 8 architecture supports it); not a 2026 commitment.
- Cross-references to predecessor docs (8D scoping, 8D co-plan, this 8D.3 scoping).

### Item 7 — Codex per-iteration review

Standard pattern. Output saved to `docs/initiative-cross-platform-ui/handoff/phase-08d.3a-codex-N.md`.

## 5. Acceptance criteria (closing-gate)

A passing 8D.3a means ALL of:

- [ ] `samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr` has the `title_field.on_change` closure that mutates `save.disabled` per Item 1.
- [ ] `spec/asset_pipeline/voyager_todo_editor_save_disabled_spec.cr` exists with the 5+ scenarios from Item 2, all green.
- [ ] `crystal spec` passes: baseline + new spec examples; same 4 pre-existing failures.
- [ ] `samples/initiative-cross-platform-ui-voyager/controllers/todo_editor_controller.cr` has the defensive-fallback comment from Item 3.
- [ ] iOS simulator build succeeds; `VoyagerDemo.app` installed; XCUITest cold-launch smokes from 8D.2 still pass.
- [ ] **Owner hand-test recipe (Item 4) PASSES on all 8 steps.**
- [ ] `samples/initiative-cross-platform-ui-voyager/app.cr` shim comments updated per Item 5; method NOT renamed.
- [ ] `docs/initiative-cross-platform-ui/architecture/web-target-position.md` committed per Item 6.
- [ ] Codex review APPROVE or APPROVE_WITH_NOTES (no REVISE outstanding).

## 6. Risk register

- **R1** — Closure capture of `save` requires reordering. *Mitigation:* implementer reorders. Simple.
- **R2** — `title_field.on_change` composes with `wrap_text_handler`. *Mitigation:* per `src/ui/form_state.cr:160-180`, the wrap COMPOSES user handler AFTER FormState.update. Verified safe.
- **R3** — XCUITest smokes from 8D.2 might fail with the new closure (if compositor breaks). *Mitigation:* implementer runs them after the fix; if fail, escalate.
- **R4** — Hand-test gate fails on a step unrelated to Item 1 (e.g. Item 4's checkbox toggle reveals a dispatcher bug). *Mitigation:* implementer remediates; if architectural, escalate.
- **R5** — Closure on `title_field.on_change` doesn't fire on iOS due to renderer wiring gap. *Mitigation:* the existing FormState write path proves on_change fires on iOS today (sign-in email field works). The closure is just additional work in the same handler.
- **R6** — `Voyager.build_route` doc cleanup misses callsite — code citation reveals other callers we forgot. *Mitigation:* grep for callsites before editing comments. Should be web/static_site.cr only.

## 7. Implementation order

1. Item 1: closure wiring in `todo_editor.cr` + Item 3 controller comment.
2. Item 2: spec.
3. `crystal spec` validation.
4. iOS simulator build + XCUITest re-run (`testColdLaunchSignInDispatcherWired`, `testColdLaunchTodosDispatcherWired`, `testRenderInitialSlug` — all must still pass).
5. Item 5: `app.cr` comment cleanup.
6. Item 6: position note.
7. Codex iteration review.
8. Hand off to architect with `.app` artifact + recipe → architect surfaces to owner → owner runs hand-test → owner reports.

## 8. Validation invocations

- `crystal spec` — full suite.
- `crystal spec spec/asset_pipeline/voyager_todo_editor_save_disabled_spec.cr` — new spec.
- `crystal spec spec/asset_pipeline/voyager_dispatcher_integration_spec.cr` + `voyager_host_bootstrap_spec.cr` — regression coverage.
- `cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator && xcodebuild ... build` — iOS build.
- `xcodebuild ... test -only-testing:VoyagerDemoUITests/VoyagerVisualTests/testColdLaunchSignInDispatcherWired -only-testing:VoyagerDemoUITests/VoyagerVisualTests/testColdLaunchTodosDispatcherWired -only-testing:VoyagerDemoUITests/VoyagerVisualTests/testRenderInitialSlug` — XCUITest regression smoke.
- Codex review: `codex exec -c 'model_reasoning_effort="medium"' "<prompt>" 2>&1 | tee /tmp/codex-iter-N.log | tail -300`.

## 9. Hard rules

- Forward commits only on `phase-08d.3a-interaction-proof-and-disposition`.
- NO public UI framework API changes. Voyager-side wiring only.
- NO C ABI changes.
- NO Swift production code edits.
- NO `Voyager.build_route` rename or migration.
- Mid-stop dispatch protocol does NOT apply — 8D.3a is code work + owner verification, no capture work. Single implementer agent runs the full Mode A.
- Codex review per iteration.
- Standard Claude co-author footer: `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`.

— Architect (Claude Opus 4.7)
