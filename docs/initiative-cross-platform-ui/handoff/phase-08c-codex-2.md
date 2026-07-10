# Phase 8C — Codex iter-2 review (Item 3 — spike migration)

**Branch:** `phase-08c-routes-for-app`
**Iteration scope:** brief-8c.md Item 3 — spike migration to `routes_for(SpikeApp)` + browser POST regression proof.

## Review — commit `d267c209`

**Codex verdict:** APPROVE_WITH_NOTES.

### Verification (Codex)

* `samples/phase-08-amber-spike/config/application.cr` requires `SignInController` BEFORE `SpikeApp`, and defines `SpikeApp` BEFORE requiring `./routes`. Order is correct.
* `routes_for(SpikeApp)` is well-formed for the spike. Real Amber router matching resolves `GET / -> SignInController#index` and `POST /sign_in/submit -> SignInController#submit`; `GET /sign_in/submit` and `POST /` are NOT registered. Amber's `HEAD` / `OPTIONS` side routes remain equivalent to the old manual DSL.
* Screenshot evidence is valid. `findings-browser-after-routes-for.png` is a non-corrupt 1024×625 PNG, 15176 bytes, and visibly shows the flash notice "Signed in as seth@example.com." It is byte-identical to `findings-browser-submit.png` (acceptable; both are screenshots of the same post-submit response).
* Voyager / native / token scope is clean in the commit diff. No changed paths under Voyager/native/token areas. No new sentinel or macro-generation pattern in the diff.
* `crystal spec` baseline preserved: `1671 examples, 4 failures, 0 errors, 66 pending`.
* `git diff --check` is clean. Spike source compiles to a temp binary.
* Codex could not rerun Selenium end-to-end in its own sandbox (refuses binding to `localhost:3000`), but the router routing, the network log, and the screenshot artifacts collectively support the reported browser proof.

### Notes (not blocking)

* `findings-browser-after-routes-for.png` is byte-identical to `findings-browser-submit.png` (same Selenium run captured both — acceptable since they prove the same response).
* The diff contains six paths, not five — `docs/initiative-cross-platform-ui/handoff/phase-08c-codex-1.md` was added between `56c5a3c0` and `d267c209`. Scope-note observation only.

## Status

Iter 2 (Item 3) — **APPROVED WITH NOTES.**

Phase 8C closes:

* Brief Items 1 + 2 + 3 all shipped.
* `crystal spec` exit baseline: 1671 / 4 / 0 / 66 (same 4 pre-existing failures as entering).
* Browser POST proof passes with `routes_for(SpikeApp)`-driven router. Same HTTP 200 + flash notice as Phase 8A baseline.
* `routes_for` mechanism empirically proven against the FULL `Amber::DSL::Router` surface during iter 1 review (Codex smoke test) AND end-to-end via the spike's actual Selenium browser flow during iter 2.
* A single `class SpikeApp < UI::App` declaration now drives BOTH native screen-registry navigation (latent, exercised in future phase) AND Amber web route registration. The architectural payoff that makes Phase 8D's Voyager migration possible.
