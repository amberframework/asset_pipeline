# Phase 7 — Implementation Brief (CI Integration scope, post-2026-05-22 narrowing)

**Audience:** Implementer agent for Phase 7 (CI Integration for Accessibility & Visual Verification).
**Scope contract:** This document, plus `README.md` in this folder, plus the universal `rubric/implementation_criteria.md`, plus the validated `brief.yml` (per the MASTER_PLAN team-lead playbook), are the complete brief.

> **Important:** The previous Phase 7 implementation brief (which had Phase 7 building the entire audit infrastructure) is preserved at `implementation.stale-pre-2026-05-22.md`. **Do not implement from that file.** Phase 6.5 ships the audit infrastructure; Phase 7's narrowed scope is below.

---

## Goal

Wrap Phase 6.5's pre-existing audit harness into a GitHub Actions workflow that runs on every PR. Commit initial baseline PNGs for Phase 6's demo. Document the baseline-refresh procedure.

Phase 7 ships when:
1. `.github/workflows/initiative-cross-platform-ui.yml` exists and on every PR builds + invokes Phase 6.5's harness + reports pass/fail with structured artifacts.
2. The initial baseline PNG set for the Phase 6 demo screens is committed.
3. `docs/initiative-cross-platform-ui/verification-runbook.md` exists explaining how to refresh baselines after an intentional visual change.
4. `CLAUDE.md` has a one-line pointer to the runbook.

---

## Pre-reading checklist

Before touching code, read in order:

1. `docs/initiative-cross-platform-ui/MASTER_PLAN.md` — confirm Phase 6.5 and Phase 6 are both PASSED in the ledger (Phase 7 cannot start otherwise).
2. `docs/initiative-cross-platform-ui/phases/phase-06.5-audit-infrastructure-first/README.md` — read what Phase 6.5 shipped; note the entry point command(s) and the artifact paths.
3. `docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/README.md` — confirm the demo's build paths.
4. `docs/initiative-cross-platform-ui/handoff/planning-retrospective-2026-05-22.md` — Principles 1–8.
5. `docs/initiative-cross-platform-ui/schemas/phase_brief.schema.json` — your `brief.yml` must validate against this.

---

## Step-by-step plan (commit-sized chunks)

Each numbered item is one commit. Subjects use the `[Phase 7] {imperative}` format from `implementation_criteria.md`.

1. **`[Phase 7] Add .github/workflows/initiative-cross-platform-ui.yml`** — Skeleton workflow: triggers on PR to `feature/utility-first-css-asset-pipeline`, defines a job matrix (web / macOS / iOS), each job calls Phase 6.5's harness entry point with the demo's path. No baselines committed yet.
2. **`[Phase 7] Commit initial demo baselines under test-results/initiative-demo-baselines/`** — Run Phase 6.5's regenerate command locally on the pinned environment (matching CI's tooling versions); commit the resulting PNG set. Commit body lists exact tooling versions used.
3. **`[Phase 7] Wire CI workflow to invoke Phase 6.5 audit + diff against committed baselines`** — Workflow now produces a pass/fail per the matrix entries; failing diffs upload as workflow artifacts. Threshold rules (web ≤1%, native ≤0.5% pixel diff, etc.) match what Phase 6.5 documented.
4. **`[Phase 7] Add docs/initiative-cross-platform-ui/verification-runbook.md`** — Document: how to refresh baselines, how to diagnose CI failures by audit type, gotchas (font installation, simulator state, TCC), version-bump procedure.
5. **`[Phase 7] Update CLAUDE.md with runbook pointer`** — One-line link to the runbook in the cross-platform UI section.

If a step balloons past ~400 LOC of diff, split it. Atomic commits are easier for the validator to navigate.

---

## Out of scope (explicit — moved to Phase 6.5)

- **Authoring `scripts/audit_harness.cr` or equivalent.** Phase 6.5 ships it; Phase 7 calls it.
- **Authoring `scripts/diff_demo_screenshots.cr`.** Phase 6.5 ships it.
- **Authoring axe-core driver / IBM Equal Access driver / AXUIElement walker / XCUITest target.** All Phase 6.5.
- **Designing visual diff algorithm or pixel tolerance values.** Phase 6.5 documents the chosen values; Phase 7 inherits them.

If Phase 6.5 has shipped a script under a different name than this brief expects, the implementer surfaces this immediately as architect-attention — DO NOT author a parallel script.

---

## Brief authoring contract

Phase 7's `brief.yml` MUST be authored against `docs/initiative-cross-platform-ui/schemas/phase_brief.schema.json` and pass `crystal run scripts/validate_phase_brief.cr -- phases/phase-07-accessibility-visual-verification/brief.yml` with exit 0 before dispatch.

The invariant matrix for Phase 7 will have most rows as `preserves` (Phase 7 doesn't touch the rendering or interaction surfaces; it audits them). Likely `extends` rows: I-1 (visual baseline comparison is a new render-correctness gate), I-6 (accessibility audits become CI-gated), I-10 (CI workflow itself is a new API surface with documented behavior on PR).

---

## Reporting back

When done, report per the universal contract in `implementation_criteria.md`. Phase 7's load-bearing proof points:

- The workflow file exists and is syntactically valid.
- On a clean test PR, the workflow runs to completion.
- Baselines are committed; their tooling fingerprints match the workflow's invocation environment.
- Runbook exists and matches the actual harness commands.
