# Phase 8D.3a Brief Critique — Codex Antagonist (Architect-Side, Iter 1)

**Date:** 2026-05-25
**Brief reviewed:** `phase-08-ergonomic-mvc-api/brief-8d.3a.md` (v1)
**Source log:** `/tmp/codex-critique-brief-8d3a.log`.

## Verdict: REVISE

8 findings: 0 BLOCKER, 2 HIGH, 2 MEDIUM, 2 LOW + 2 missed-points. All addressed in v2.

## Findings

### HIGH 1 — Item 2 spec gives false confidence about iOS wiring

Brief v1 Item 2 spec exercises the closure that `TodoEditorScreen#build` AUTHORS on `title_field.on_change`. But iOS doesn't invoke that closure directly — the UIKit renderer's `visit(UI::TextField)` calls `UI::FormStateRendererHook.wrap_text_handler(view)`, which wraps the user's closure (captured at wrap time). Native text changes invoke the WRAPPED proc.

A build-only spec proves the screen assigned a closure that mutates save.disabled. It does NOT prove the wrap composition, mount-token gating, OR that the wrap fires the user's closure correctly.

**Resolution (v2):** Item 2 mandates TWO specs:
- **2a — screen-authored spec.** Exercises the closure on `title_field.on_change` directly. Asserts save.disabled mutation.
- **2b — renderer-hook spec.** Sets `UI::FormState.current` + `UI::FormState.current_mount_token`, builds the screen, locates field + button BY test_id, calls `UI::FormStateRendererHook.wrap_text_handler(title_field)`, invokes the wrapped handler with sample values, asserts BOTH `fs["title"]` (FormState updated) AND `save.disabled` (closure ran).

### HIGH 2 — R5 overclaims iOS proof

Brief v1 R5 claims the existing sign-in email field on_change proves on_change fires on iOS today. The code path supports the claim architecturally, but the existing iOS XCUITest smokes only prove cold launch + AX-discoverable elements. They do NOT type into the email field or assert FormState mutation.

**Resolution (v2):** Downgrade R5 wording — "same code path as sign-in email field; covered by FormState unit specs but not directly proven on iOS until owner step 8 (renderer integration proof)."

### MEDIUM 1 — Item 4 step 8 is the ONLY real Item 1 integration proof

Step 8 ("type x → Save enables; backspace → Save disables") is well-formed for manual owner testing. It verifies Item 1 on the live iOS renderer because it exercises:
- Renderer-time `wrap_text_handler` composition.
- Native text change invokes wrapped handler.
- Wrapped handler composes FormState write + user closure invocation.
- User closure mutates `save.disabled`.
- `Button#disabled=` propagates via `apsk_button_set_disabled`.

**Resolution (v2):** Brief makes this explicit — step 8 is the integration proof; Item 2b is the unit proof; Item 2a is the screen-authored sanity check.

### MEDIUM 2 — Hand-test gate not fully self-contained

Brief v1 §4 depends on "architect coordinates" + "implementer ships build artifacts + recipe" without specifying the artifact path, simulator target, install commands, app-state reset between steps, or evidence reporting format.

**Resolution (v2):** New sub-section §4.1 "Hand-test handoff checklist" with:
- App artifact path: `~/Library/Developer/Xcode/DerivedData/VoyagerDemo-*/Build/Products/Debug-iphonesimulator/VoyagerDemo.app`.
- Simulator target: iPhone 17 Pro (or newest available; `xcrun simctl list devices available | grep iPhone | head -3` to confirm).
- Install command: `xcrun simctl install "$DEVICE" "$APP_PATH"`.
- Launch command: `xcrun simctl launch "$DEVICE" com.assetpipeline.voyager.VoyagerDemo`.
- Reset between steps: each step starts from the state the previous step ended in (no app relaunch unless explicitly stated).
- Reporting format: owner replies in chat with PASS/FAIL per step, e.g. "Step 1 PASS, Step 2 PASS, Step 4 FAIL — Save did not enable after typing." Failures include what the screen showed.

### LOW 1 — `app.cr` has more stale comments than the two cited blocks

Beyond `:16-24` and `:86-103`, brief v1 missed:
- `@@dispatcher` comment block at `:51-62` references "static-site web + current iOS bridge" — iOS bridge now dispatches.
- `dispatch` method docstring at `:74-77` says "No-op when no dispatcher is set (static-site web + current iOS bridge)" — same issue.
- `route_for_slug` comment at `:137-140` says iOS/macOS hosts may pre-build routes; verify whether that's still true post-8D.2.

**Resolution (v2):** Item 5 expanded to enumerate ALL stale-comment locations. Implementer audits via `grep -n "iOS\|bridge\|dispatcher\|8D\." samples/initiative-cross-platform-ui-voyager/app.cr` and updates each.

### LOW 2 — Position note location OK, page guardrail tight

`docs/initiative-cross-platform-ui/architecture/web-target-position.md` is the right home. Two pages is enough IF the note stays architectural; should NOT become a migration history dump.

**Resolution (v2):** Brief Item 6 adds explicit "link predecessor docs; don't re-narrate the journey" guardrail.

### Missed-points

- **Spec test_id selectors.** New specs should locate field + button by test_id (e.g. `"voyager-todo-editor-title"`, `"voyager-todo-editor-save"`), not child-order traversal. Brief Item 2 updated to specify.
- **`todo_editor.cr` stale comment.** Near `save.disabled = seed_title.strip.empty?` at `:115-119`, the existing comment says reactive update is a follow-up. Brief Item 1 expanded to require cleanup of this comment as part of the fix.

## What's strong about the brief

The view-local-affordance vs app/domain-state reframing is the architectural insight that justifies 1B. The sub-phase split (8D.3a / 8D.3b) is correct. The frozen-surface declaration is clean. Hand-test placement BEFORE captures is the right call.

Codex's iOS call-chain trace ("the closure captures save → UIKit renderer visits the text field after build → wrap_text_handler captures user_handler = view.on_change → native text change invokes wrapped handler → wrapper checks current FormState/token, calls captured_fs.update(name, new_value), then calls the captured user handler → user handler sets save.disabled = value.strip.empty? → Button#disabled= propagates via apsk_button_set_disabled") confirms Item 1 wiring is safe.

— Codex (medium reasoning, arg-form prompt)
