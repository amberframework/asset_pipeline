# Phase 8D.3a — Architect Reflection (short)

**Phase:** 8D.3a — Save-enabled-on-type + shim disposition + position note
**Date closed:** 2026-05-25 (PASS_WITH_NOTES, merge-on-automated-proof)
**Branch merged:** `phase-08d.3a-interaction-proof-and-disposition` → `feature/utility-first-css-asset-pipeline`
**Final HEAD:** `1c27bcb2`
**Tag:** `phase-08d.3a-pass-with-notes-2026-05-25`

## Verdict

PASS_WITH_NOTES. Save-enabled-on-type closure ships; FormState renderer-hook composition spec proves the wrap composes; `Voyager.build_route` is now documented as the permanent static-site entry point; the web-target position note explains the B2 architecture stance. Hand-test gate deferred to Phase 8 collective review per new owner directive `[[complete-phase-arc-before-review]]`.

## What shipped

- `samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr` — view-local closure on `title_field.on_change` mutates `save.disabled = value.strip.empty?`. Stale "Phase 8B follow-up" comment replaced.
- `spec/asset_pipeline/voyager_todo_editor_save_disabled_spec.cr` — 9 examples (Section 2a: 7 screen-authored closure; Section 2b: 2 renderer-hook composition).
- `samples/initiative-cross-platform-ui-voyager/controllers/todo_editor_controller.cr` — defensive-fallback comment (no behavior change).
- `samples/initiative-cross-platform-ui-voyager/app.cr` — 5 stale-comment blocks cleaned up per Codex LOW 1 audit.
- `docs/initiative-cross-platform-ui/architecture/web-target-position.md` — B2 position note (96 lines).

## Numbers

- `crystal spec`: **1714 → 1723** (+9 new; same 4 pre-existing failures).
- iOS build clean; XCUITest cold-launch smokes **3/3 pass** (regression coverage).
- Codex iter-1: final APPROVE (Item 6 commit-ordering REVISE resolved by commit 2).

## What's open (carried to Phase 8 collective review)

- 8-step owner hand-test (the live Item 1 integration proof — step 8 type/backspace verifies the renderer-time wrap composition).
- 8D.3b 14-row capture matrix (next sub-phase).

## Lesson

**Architectural reframing: view-local affordance vs app/domain state.** The "every mutation through dispatcher" rule applies to app/domain state. Local UI affordances (button disabled mirroring a single field's emptiness, tooltip visibility, etc.) may be wired with closures. Codex's `1A rejected` reasoning was decisive: `ActionResult::Rerender` allocates fresh FormState; that destroys the in-progress typed value the rerender was meant to reflect. Pure-architecture purity can be functionally broken.

This reframing belongs in the Phase 8E docs as a stated rule, not just a code comment.

— Architect (Claude Opus 4.7)
