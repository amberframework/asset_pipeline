# Phase 8C — Implementer Report

**Branch:** `phase-08c-routes-for-app`
**Branch HEAD at completion:** `d267c209` (after iter-2 codex handoff commit it will be one further)
**Commit count on this branch (new):** 6 implementer commits

| # | Commit | Description |
|---|--------|-------------|
| 1 | `6be6eb1d` | [Phase 8C iter 1] Items 1 + 2 — ScreenRegistration web fields + routes_for macro |
| 2 | `8146efa7` | [Phase 8C iter 1 rev 1] Address Codex iter-1 REVISE findings |
| 3 | `56c5a3c0` | [Phase 8C iter 1 rev 2] Tighten bare-web_controller guard + correct doc |
| 4 | `65e93c8a` | [Phase 8C iter 1] Record Codex review verdicts at handoff/phase-08c-codex-1.md |
| 5 | `d267c209` | [Phase 8C iter 2] Item 3 — spike migration + browser POST regression proof |
| 6 | (post-report) | [Phase 8C iter 2] Record Codex iter-2 verdict at handoff/phase-08c-codex-2.md + implementer report |

Forward commits only on `phase-08c-routes-for-app` (no force-push, no rewrites).

## Codex verdicts per iteration

### Iter 1 (Items 1 + 2)
* Initial review (`6be6eb1d`) — **REVISE**: 2 MAJOR + 2 MINOR.
  - MAJOR 1: Phase 8B native spike `registration.screen_class.new` broke under new nilable type → fixed via explicit nil-check.
  - MAJOR 2: macro signature reorder silently re-bound 3rd positional → fixed by pinning `screen_class` at 3rd positional.
  - MINOR 1: compile-time vs runtime `has_web` inconsistency → tightened.
  - MINOR 2: source-grep instead of compile-failure tests → switched to fixture-based shell-out to `crystal build`.
* Rev 1 (`8146efa7`) — **REVISE**: 2 MINOR.
  - Bare-web_controller guard only fired on web-only screens → tightened to fire regardless of native side.
  - Doc comment still referenced removed `*` separator → rewritten.
* Rev 2 (`56c5a3c0`) — **APPROVE** (no findings).

### Iter 2 (Item 3)
* Single review (`d267c209`) — **APPROVE_WITH_NOTES**.
  - No blocking findings.
  - Codex independently verified `routes_for(SpikeApp)` resolves to the correct router calls inside real Amber, screenshot is a valid PNG, Voyager untouched, spec baseline preserved.
  - Notes (not blocking): `findings-browser-after-routes-for.png` byte-identical to `findings-browser-submit.png` (acceptable — same Selenium run); diff has 6 paths not 5 (handoff doc).

## Spec counts

| | Examples | Failures | Errors | Pending |
|---|---|---|---|---|
| Entering iter 1 | 1659 | 4 | 0 | 66 |
| Exiting iter 1 rev 2 | 1671 | 4 | 0 | 66 |
| Exiting iter 2 | 1671 | 4 | 0 | 66 |

Same 4 pre-existing failures throughout (unrelated to Phase 8C: 1 UI::Theme web renderer + 3 Phase 2 component verification). 12 new Phase 8C examples added during iter 1.

## Browser POST proof artifact

`samples/phase-08-amber-spike/findings-browser-after-routes-for.png` — Selenium / Chrome 149 / ChromeDriver 149 captured the post-submit page after the `UI::AmberIntegration.routes_for(SpikeApp)`-driven Amber router served GET `/` + POST `/sign_in/submit`. Flash notice "Signed in as seth@example.com" visible. Identical behavior to Phase 8A baseline.

Output of `browser_post_proof.py`:

```
GET screenshot:  findings-browser-get.png (10834 bytes)
GET title:       'Phase 8 Amber Spike'
OK   form, _csrf, email, password, submit all present in DOM
Email value before submit: 'seth@example.com'
POST screenshot: findings-browser-submit.png (15176 bytes)
Network log:     findings-browser-network.json (4 relevant events)
OK   flash notice 'Signed in as seth@example.com' visible after submit
```

## Architectural payoff

The `class SpikeApp < UI::App` declaration in `samples/phase-08-amber-spike/config/application.cr` is now the SINGLE source of:

1. Amber web routes (via `config/routes.cr`'s `UI::AmberIntegration.routes_for(SpikeApp)`).
2. Native screen registry (latent in the spike — exercised when the native side is added in a future phase).

Phase 8C closes the loop. Phase 8D's Voyager migration can proceed against this surface.

## Hard rules — satisfied

* ✅ Forward commits only on `phase-08c-routes-for-app`.
* ✅ NO native side changes — Phase 8B's UI::App/Controller/Dispatcher/FormState stay. ScreenRegistration extension is additive (new nilable fields with sane defaults; Phase 8B callers compile unchanged).
* ✅ NO new sentinels or design-token changes.
* ✅ NO macro file generation.
* ✅ Voyager UNCHANGED. `grep -rE "voyager-(save-chain|interaction-proof)" .` returns 0 NEW matches in the iter range (historical mentions in old handoff docs unchanged).
* ✅ Standard Claude co-author footer on every commit.
* ✅ Spike's `config/routes.cr` is one line (the `routes_for` call) instead of per-route manual `get`/`post`.

## Deferred / open notes

* **Implementer deviation from brief:** dropped the `*` kwarg-only separator on the `screen` macro. Crystal macros cannot combine `*,` with a default on a positional arg before it. Type-system mitigation documented inline. Codex re-reviewed and approved.
* **`web_controller` stored as `String` (class name)** in `ScreenRegistration#web_controller_name`. Crystal disallows `Class` in union types AND as instance-variable type. The class reference is interpolated directly into the macro emission (no runtime storage needed). Codex re-reviewed and approved.
* **Macro-raise validation uses fixture-based shell-out specs** (`spec/fixtures/phase_08c_macro_raise/*.cr` + `Process.run("crystal", ["build", "--no-codegen", ...])`). Slower than source-grep but catches relocated guards.
* **Native dispatch tests for web-only screens**: spec case (g) covers `WebOnlyScreenError` on `:submit` action. Other action symbols would follow the same path; spec doesn't enumerate them.

## Status

**APPROVED for phase close.** Awaiting architect sign-off.
