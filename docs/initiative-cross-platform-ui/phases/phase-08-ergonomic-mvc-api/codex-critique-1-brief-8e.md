# Phase 8E Brief Critique — Codex Antagonist (Architect-Side, Iter 1)

**Date:** 2026-05-25
**Brief reviewed:** `brief-8e.md` v1.
**Verdict:** REVISE — 0 BLOCKER / 2 HIGH / 2 MEDIUM / 2 LOW. All addressed inline (no v1 snapshot needed; edits are narrow).

## Findings + resolutions

- **HIGH 1** — Brief used `action: :submit` / `action: {Controller, :action}` / `action_params:` from views as if `UI::Button` exposed them as kwargs. **Shipped API uses closures**: `button.on_tap = -> { Voyager.dispatch(:submit) }`. **Resolved:** Skill §5 + Tutorial Ch.5 + Five Rules examples rewritten to use closure form. Explicit "do NOT use Button(action:) — never shipped" note added.

- **HIGH 2** — Brief claimed the bootstrap invariant ends with "assign `App.dispatcher = dispatcher`" — but there is no generic `UI::App.dispatcher` slot. Voyager publishes to sample-local `Voyager.dispatcher`. **Resolved:** Skill §7 reworded to "publish/pin the dispatcher in the host's holder (Voyager uses `Voyager.dispatcher = dispatcher`)."

- **MEDIUM 1** — Section-number drift after adding "Action Results" to the skill section list (12 sections, not 11). **Resolved:** acceptance criteria now reference section TITLES not numbers.

- **MEDIUM 2** — Rule 3 listed push/replace_root/republish but missed Pop. `ActionDispatcher#translate_result` also mounts target route before `navigation.pop`. **Resolved:** Rule 3 now explicitly includes Pop.

- **LOW 1** — Item 3d tag verification was over-specified. **Resolved:** reworded to "verify predecessor tags exist."

- **LOW 2** — Item 3 said "Three edits" but listed 3a/3b/3c/3d. **Resolved:** "Four edits (3a-3d)."

## Codex direct answers (recorded for reference)

1. Five rules substantively accurate (Rule 3 fixed).
2. CLAUDE.md insertion plan precise enough.
3. Voyager lifts stable: `VoyagerApp`, `HostBootstrap.build`, `SignInController#submit`, `TodosScreen#build`.
4. SKILL.md shape matches `build-ui/SKILL.md` frontmatter pattern.
5. Tag verification cheap but not strictly needed.
6. Tutorial chapters + skill sections cover different proof types (narrative vs operational reference) — intended overlap.
7. Closing gate enforceable after section-title cleanup.
8. Main risk was Phase 8 design.md syntax leaking back into docs — closed by HIGH 1 fix.

— Codex (medium reasoning, arg-form prompt)
