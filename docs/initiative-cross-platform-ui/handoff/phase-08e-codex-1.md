# Phase 8E — Codex antagonist log

Final architect verdict: **APPROVED with the Rule 1 wording fix**.

## Iter 1

**Verdict:** REVISE

**Key findings:**

1. **Three web meanings not kept fully distinct.** `tutorial-ui-app.md:351` described Amber full-server web as "Live dispatcher? Yes (per request)." That is misleading: Amber full-server uses `UI::AmberIntegration.routes_for(App)` to emit Amber routes, then Amber controllers build `UI::ScreenContext::Web` and render via `UI::Web::Renderer` — it is not the native `UI::ActionDispatcher` path. Violates the brief's explicit split between Amber full-server web, Voyager static-site web, and the generic web renderer.

2. **Frozen surfaces not honored.** `spec/test_js/some_js.js` was modified in the worktree (unrelated to Phase 8E) and untracked `output/` artifacts were present. Required scope correction at commit time.

**Per-criterion findings (positive):**
- `SKILL.md` present, 412 lines, valid frontmatter matching `build-ui` shape, all 12 required sections in brief order.
- Tutorial present, 385 lines, all 13 chapters in brief order.
- Five architectural rules present in both skill §10 and tutorial Ch. 12 with required substance.
- `CLAUDE.md` edits 3a, 3b, 3c, 3d applied (subsection in requested location, 8 Key Entry Points bullets, Quick Reference row, Phase 8 close note).
- Phase 8 tags 8A / 8B / 8C / 8D.1 / 8D.2 / 8D.3a / 8D.3b verified via `git tag --list "phase-08*"`.
- Voyager code lifts: `VoyagerApp`, `Voyager.dispatch`, `Voyager.build_route`, `Voyager::HostBootstrap.build`, `Voyager::SignInController#submit` match the lifted examples.
- Shipped closure pattern documented; stale `Button(action: :submit)` syntax explicitly rejected.
- `git diff --check` clean.

**Required fixes:**
- Rewrite Ch. 11 table so Amber full-server web is not described as dispatcher-backed.
- Exclude `spec/test_js/some_js.js` and `output/` artifacts from the Phase 8E commit scope.

## Iter 2

**Verdict:** REVISE

**Key finding (single new blocker, frozen-surfaces concern not re-raised because commit scoping handles it):**

> The Ch. 11 table is fixed, but the immediately following canonical Ch. 12 rule reintroduces the same ambiguity.
>
> At `docs/initiative-cross-platform-ui/tutorial-ui-app.md:362`, the tutorial says the five rules "hold across every `UI::App` deployment," then line 362 says:
>
> `App/domain state mutations go through controllers + dispatcher.`
>
> That now conflicts with the corrected Amber row at line 351, which explicitly says Amber full-server web has "No native `UI::ActionDispatcher`" and uses Amber controllers/routes/request cycle instead.
>
> The same canonical wording also appears in `.claude/skills/ui-app/SKILL.md:353`, so the tutorial and skill remain mutually reinforcing but still dispatcher-biased for Amber.

## Iter 3

Iter 3 stalled. The `codex exec` invocation hung at `Reading additional input from stdin...` (its log contains only that one line) because the prompt was not piped on stdin. The orchestrator's `monitor` event never fired.

The architect resolved the Iter 2 finding directly without a fresh Codex pass, by approving the following Rule 1 wording (applied identically in both `SKILL.md` and `tutorial-ui-app.md`):

> 1. **App/domain state mutations go through the target's controller layer** — `UI::Controller` + `UI::ActionDispatcher` on native; the Amber controller's request cycle on Amber full-server web; build-time only for static-site. Never in screen `build` methods.

That replacement preserves the substance of Rule 1 (no mutations in `build`; route everything through the controller layer) while honestly acknowledging the three targets have different controller mechanisms — eliminating the dispatcher-biased framing Codex flagged.

**Final architect verdict: APPROVED with the Rule 1 fix.**
