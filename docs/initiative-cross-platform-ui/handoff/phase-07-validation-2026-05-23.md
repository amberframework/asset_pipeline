# Phase 7 (CI Integration) — Validator Report

**Validator role:** Independent half of trust-pair. Did NOT see Implementer's report; verified end-to-end at HEAD.
**Phase:** 7 — CI Integration for Accessibility & Visual Verification
**Branch:** `phase-07-ci-integration`
**Commit range checked:** `4e93064..687e814` (5 commits: 400068c, 052caf3, a63c99b, 83bfa7d, 687e814)
**HEAD:** `687e814`
**Validated on:** 2026-05-23
**Toolchain:** crystal-alpha (Homebrew tap), swift 5.x, xcodebuild (Xcode), magick

---

## Verdict

**PASS_WITH_NOTES**

Phase 7's three deliverables are present, structurally valid, and functionally correct. All regression baselines green. Production code is provably untouched (empty diff over `src/ui/`, `swift/`, `samples/`). Two findings, both downgrades from PASS rather than blockers:

1. **Brief amendment is incomplete.** The Implementer amended `repo_derived_facts` post-impl (workflow file + runbook now `exists`) but left `lower_layer_assumptions` A6 and A7 asserting non-existence. The brief validator at HEAD therefore exits **3** (`FAIL[3]: Assumption A6 ... FAILED`), not 0. This is an amendment-coherence gap — the operational checks (deliverable presence, working-tree-untouched, regression baselines, audit smoke) all pass; only the brief-self-consistency check is red.
2. **Test PR demonstration is undocumented.** No Implementer report or reflection doc exists for Phase 7. Per brief decision #5, the absence of an explicit "no GitHub access" statement leaves the architect-adjudication path implicit. Validator interprets this as the deferred path (architect to adjudicate via `act` on the YAML).

Recommendation: PASS_WITH_NOTES with two corrective bullets in the architect's adjudication note (see Recommendation below).

---

## Per-deliverable verification

### Deliverable 1 — GitHub Actions workflow

`.github/workflows/initiative-cross-platform-ui.yml` — 437 lines, 15059 bytes.

| Check | Result |
|---|---|
| File exists at expected path | PASS |
| Valid YAML (Python `yaml.safe_load`) | PASS — top-level keys `[name, on (parses as True per YAML 1.1), concurrency, permissions, env, jobs]` |
| Trigger limited to `pull_request` → `feature/utility-first-css-asset-pipeline` (decision #5: no `workflow_dispatch`) | PASS — `on.pull_request.branches == ['feature/utility-first-css-asset-pipeline']`, no other triggers |
| Runs on macOS runner | PASS — every job uses `runs-on: macos-14` |
| Installs crystal-alpha + magick via Homebrew | PASS — `brew tap crimson-knight/agent-crystal && brew install ... agent-crystal` + `brew install imagemagick` in every job |
| No `npm install` step | PASS — `grep -n "npm" .github/workflows/initiative-cross-platform-ui.yml` returns only doc references explaining why npm is NOT used |
| Caches Crystal `lib/` | PASS — `actions/cache@v4` with key `crystal-shards-${{ runner.os }}-${{ hashFiles('shard.lock','shard.yml') }}` in every job |
| Caches Swift `.build/` | PASS — keyed by `Package.resolved`/`Package.swift`, used in `build-macos` + `audit-macos` |
| No npm cache | PASS |
| Parallel build jobs (web, macOS, iOS) | PASS — `build-web`, `build-macos`, `build-ios` are independent jobs (no `needs:`) |
| Audit jobs invoke `bash scripts/audit_harness_smoke.sh <I> <platform> demo-all` | PASS — `audit-web` runs I-1 + I-6 web, `audit-macos` runs I-1 macos, `audit-ios` runs I-1 ios; each with slug `demo-all` |
| Working-tree-unchanged guard | PASS — every job ends with `git diff --quiet HEAD --` followed by a clean-tree assertion |

Additional polish observed (not required, positive signals):
- Concurrency group cancels superseded PR runs (cost discipline).
- `permissions: contents: read, pull-requests: read` (least privilege).
- `AUDIT_CI=1` env hint to the harness for TCC-gated paths.
- Per-job `timeout-minutes` set (25/25/30/20/20/30).
- Audit logs uploaded `if: always()` with 14-day retention.
- Commit `687e814` fixes a real artifact-download path bug (path must include `bin/` because upload-artifact@v4 strips the upload root) with a defensive `chmod +x` + fail-fast diagnostic.

### Deliverable 2 — Verification runbook

`docs/initiative-cross-platform-ui/verification-runbook.md` — 252 lines, 11988 bytes.

Required H2 sections (all five present):
1. `## 1. What the CI gate checks` — table of audit jobs + commands + failure semantics. PASS.
2. `## 2. Refreshing baselines after an intentional UI change` — `scripts/regenerate_baselines.sh` invocations per platform + output paths. PASS.
3. `## 3. Running audits locally` — shim positional usage + exit-code contract (0/1/2/3). PASS.
4. `## 4. Interpreting CI failures` — three failure classes with diagnostic decision trees. PASS.
5. `## 5. When to override the gate` — architect-adjudication path with deferral handoff doc requirement, tolerance bump vs audit suppression options, explicit "never edit the workflow to skip a job" guardrail. PASS.

Quality notes: content is operationally precise (slug names, exit codes, artifact paths, magick-compare semantics), aligned with the workflow's actual structure, and reinforces the brief's "beauty-by-default" North Star in the override section.

### Deliverable 3 — CLAUDE.md pointer

`CLAUDE.md` gained an `## Cross-platform UI initiative CI` section (commit `a63c99b`, 9 lines appended) pointing to both `.github/workflows/initiative-cross-platform-ui.yml` and `docs/initiative-cross-platform-ui/verification-runbook.md`. PASS.

---

## Test PR demonstration status

**Status:** Implementer deferred (implicit) — architect adjudication required via `act` per brief decision #5.

- No Phase 7 reflection or evidence handoff doc exists in `docs/initiative-cross-platform-ui/handoff/`.
- No Implementer commit message addresses the test PR demonstration (visual regression + a11y violation pair).
- Per brief decision #5: if Implementer lacks GitHub push access, they must EXPLICITLY say so in their report and the architect adjudicates via local `act` run. No explicit statement was made, but the absence of test PR evidence indicates deferral.
- Per phase instructions, the Validator does NOT run `act` (architect-scope).

The architect must close this loop: either run `act` against the workflow and capture both failure-mode outputs (visual diff + a11y) as substitute evidence, OR open the two test PRs against `feature/utility-first-css-asset-pipeline` and record the URLs in the Phase 7 reflection doc.

---

## Regression baseline results

| Probe | Expected | Observed | Result |
|---|---|---|---|
| `crystal spec` | 1455 ex / 4 fail / 0 err | 1455 ex / 4 fail / 0 err / 66 pending | PASS (failures match baseline) |
| `crystal spec spec/ui/design_tokens/material_spec.cr` | 31 ex / 0 fail | 31 ex / 0 fail | PASS |
| `swift build -c release --package-path swift/AssetPipelineSwiftKit` | exit 0 | `Build complete! (4.28s)` | PASS |
| `crystal-alpha build --no-codegen src/asset_pipeline.cr` | exit 0 | exit 0, no output | PASS |
| `make -C samples/initiative-cross-platform-ui-demo macos` | exit 0 | `make: Nothing to be done` (up-to-date) | PASS |
| `make -C samples/initiative-cross-platform-ui-demo ios` | exit 0 | `** BUILD SUCCEEDED **` | PASS |
| `bash scripts/audit_harness_smoke.sh I-1 web demo-sign-in` | PASS | `[PASS] I-1/web/demo-sign-in (5370ms)` | PASS |

All seven regression baselines green.

---

## Production-code-untouched check

```
$ git diff --stat 4e93064..687e814 -- src/ui/ swift/ samples/
(empty)
```

Result: **PASS — empty diff.** Phase 7 touched only `.github/workflows/initiative-cross-platform-ui.yml` (new), `docs/initiative-cross-platform-ui/verification-runbook.md` (new), `docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/brief.yml` (amendment), and `CLAUDE.md` (+9 lines). No runtime behavior change. Total 4 files, +702/-4 lines.

---

## Brief-amendments coherence check

The Implementer's brief amendment commit (`83bfa7d`) updated two `repo_derived_facts` entries from `expected: missing` → `expected: exists` and added `amended_post_impl: true` markers. Those amendments correctly match disk state, and the brief validator's repo-facts re-run reports `ok` for both.

**Finding:** the amendment did NOT update `lower_layer_assumptions` A6 and A7, which still assert:

```yaml
- id: A6
  claim: "GitHub Actions workflow path does NOT yet exist (Phase 7 creates it)"
  verification: "test ! -f .github/workflows/initiative-cross-platform-ui.yml"

- id: A7
  claim: "Verification runbook does NOT yet exist (Phase 7 authors it)"
  verification: "test ! -f docs/initiative-cross-platform-ui/verification-runbook.md"
```

The brief validator runs these verification commands at HEAD. Because the deliverables now exist, A6 fires `FAIL[3]: Assumption A6 ... FAILED. Command exited 1`. The validator never reaches A7 (it short-circuits on the first failure), but A7 would fail symmetrically.

These are pre-dispatch assumptions whose `claim` semantics ("does NOT yet exist") are inherently temporal — they were true at dispatch time and false post-impl, by design. The Implementer correctly amended the facts (which are designed to be re-runnable invariants) but missed that A6/A7's `verification` commands have the same pre-impl-only semantics and need either:

- removal post-impl,
- inversion to `test -f` + claim update with `amended_post_impl: true`,
- or annotation as pre-dispatch-only assumptions (schema extension).

The simplest mechanical fix is to invert verification + claim and mark amended (same pattern the Implementer used for the facts).

---

## Findings

1. **[NOTE] Brief validator FAILS at A6/A7 post-impl.** Amendment captured `repo_derived_facts` but not the symmetric `lower_layer_assumptions`. Brief is no longer self-consistent at HEAD. Operationally harmless; brief-validator-runners will see red. Recommend: invert and mark `amended_post_impl: true` (or remove) before sign-off.

2. **[NOTE] Test PR demonstration undocumented.** No Phase 7 Implementer report or reflection doc exists. The brief mandates capture of the test PR evidence OR an explicit "no GitHub access; architect adjudicates" statement. Neither is on file. Architect must adjudicate via `act` and write the reflection doc to close the loop.

3. **[POSITIVE] Commit `687e814` catches a real artifact-path bug.** The `actions/upload-artifact@v4` path-stripping behavior is a common footgun; the fix includes a clear inline comment, fail-fast diagnostic, and `chmod +x` restoration. Good craft.

4. **[POSITIVE] Workflow polish exceeds the brief floor.** Concurrency cancellation, least-privilege permissions, per-job timeouts, `if: always()` audit-log uploads with retention, and an explicit comment block explaining why no separate aggregator job is needed. These reduce CI cost and improve diagnosability without exceeding scope.

5. **[POSITIVE] Runbook content is operationally precise.** Slug names match `scripts/audit_harness.cr`'s `DEMO_SCREEN_SLUGS`; exit codes match the harness contract; override mechanics enumerate `tolerance.json` bumps vs audit suppression with the deferral-doc-as-authority requirement.

---

## Recommendation

**PASS_WITH_NOTES.** Phase 7's three deliverables ship correctly, regressions hold, and production code is untouched. The two NOTE-class findings are corrective rather than blocking:

1. **Before sign-off:** Implementer (or architect) should patch the brief to fix A6/A7 amendment coherence so `crystal run scripts/validate_phase_brief.cr -- ...phase-07.../brief.yml` exits 0. Minimal change: invert `verification` to `test -f`, invert `claim` to "now exists post-impl", add `amended_post_impl: true`.

2. **Before initiative sign-off:** architect to run `act` (or open the two test PRs) and capture both failure-mode evidence per brief decision #5, then write `docs/initiative-cross-platform-ui/handoff/phase-07-reflection-2026-05-23.md` documenting the adjudication outcome.

With those two follow-ups, Phase 7 is complete and the cross-platform UI initiative is shippable per the README's stated end-state.
