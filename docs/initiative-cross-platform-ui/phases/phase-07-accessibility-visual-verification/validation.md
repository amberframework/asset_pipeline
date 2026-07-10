# Phase 7 — Validation Rubric (CI Integration scope, post-2026-05-22 narrowing)

**Audience:** Validator agent for Phase 7 (CI Integration for Accessibility & Visual Verification).
**Scope reminder:** You **read, run, and report**. You do not modify code, tests, configuration, or docs except for the temporary-edit exceptions documented in `rubric/validation_criteria.md`. Every check below must be addressed in your `GATE_REPORT.json` with evidence captured under `handoff/phase-07-evidence-{YYYY-MM-DD}/`.

> **Important:** The previous Phase 7 validation rubric (which validated the full audit infrastructure as Phase 7's deliverable) is preserved at `validation.stale-pre-2026-05-22.md`. **Do not validate against that file.** Phase 6.5 ships the audit infrastructure; Phase 7's validation rubric is below.

---

## Pre-reading checklist

1. `phases/phase-06.5-audit-infrastructure-first/README.md` — what was shipped + the entry-point command names.
2. `phases/phase-07-accessibility-visual-verification/README.md` — the narrowed Phase 7 scope.
3. `phases/phase-07-accessibility-visual-verification/implementation.md` — the active brief (5-commit plan).
4. The implementer's `brief.yml` and its validator output (was `validate_phase_brief.cr` exit 0?).

---

## Required checks

### B (Build)

**B1. `ci.workflow-yaml-syntactically-valid`**
- **Required.** `.github/workflows/initiative-cross-platform-ui.yml` exists and parses as valid YAML.
- **How:** `python -c 'import yaml,sys; yaml.safe_load(open(sys.argv[1]))' .github/workflows/initiative-cross-platform-ui.yml; echo $?` → 0.
- **Evidence:** `build_logs/B1-workflow-syntax.log`.

**B2. `ci.workflow-uses-phase-6.5-entry-points`**
- **Required.** Every step that runs an audit in the workflow YAML cites a script path Phase 6.5 actually shipped (verify via Phase 6.5's `README.md` "Acceptance summary" + actual file presence).
- **How:** grep the workflow file for `scripts/...` references; for each, `test -e <path>; echo $?` → 0.
- **Evidence:** `inspections/B2-workflow-script-refs.log`.

**B3. `ci.workflow-builds-demo-on-each-target`**
- **Required.** The workflow includes build steps for web, macOS, iOS. (Android per its own gating — if Phase 6 deferred, this check carries the deferral forward.)
- **How:** grep workflow for matrix entries / job names per target.
- **Evidence:** `inspections/B3-target-builds.log`.

### V (Visual baselines)

**V1. `baselines.committed-under-canonical-path`**
- **Required.** Initial PNG baselines exist under `test-results/initiative-demo-baselines/` and the directory tree matches the Phase 6 demo's screen × platform × viewport × scheme product.
- **How:** `find test-results/initiative-demo-baselines/ -name "*.png" | wc -l` matches the expected count from Phase 6's demo screens.
- **Evidence:** `inspections/V1-baseline-inventory.log`.

**V2. `baselines.tooling-fingerprint-matches-ci`**
- **Required.** The baseline commit's body cites tooling versions that match what the CI workflow uses (Crystal compiler, Chrome version, Xcode SDK version).
- **How:** git log on the baseline commit; cross-check against workflow YAML pinned versions.
- **Evidence:** `inspections/V2-tooling-match.log`.

### D (Docs)

**D1. `runbook.exists-and-references-active-scripts`**
- **Required.** `docs/initiative-cross-platform-ui/verification-runbook.md` exists. Every script path it mentions exists on disk.
- **How:** parse for `scripts/...` mentions; `test -e` each.
- **Evidence:** `inspections/D1-runbook-script-refs.log`.

**D2. `claude-md-points-at-runbook`**
- **Required.** `CLAUDE.md` contains a link to `docs/initiative-cross-platform-ui/verification-runbook.md`.
- **How:** `grep -E "verification-runbook" CLAUDE.md`.
- **Evidence:** `inspections/D2-claude-md.log`.

### CI (End-to-end)

**CI1. `workflow-runs-end-to-end-on-test-pr`**
- **Required.** A test PR opened against the validator's chosen test base branch triggers the workflow and the workflow runs to completion (pass or fail).
- **How:** create a test PR (no source changes; CI-only); observe workflow execution; capture run URL.
- **Evidence:** `inspections/CI1-test-run-url.txt`, `inspections/CI1-workflow-summary.json` (exported via `gh run view --json`).

**CI2. `workflow-fails-on-intentional-baseline-mismatch`**
- **Required.** A second test PR that intentionally changes one demo pixel without updating baselines causes the workflow to FAIL with a clear diff artifact.
- **How:** make a 1-pixel render change in a demo source file; push as PR; observe FAIL; download the diff artifact.
- **Evidence:** `inspections/CI2-fail-artifact.zip`, `inspections/CI2-diff-summary.json`.

### S (Spec)

**S1. `crystal-spec-baseline-holds`**
- **Required.** `crystal spec` produces no new failures beyond the documented baseline. Phase 7 doesn't add new specs (it adds CI infrastructure); the existing spec suite must remain unchanged.
- **How:** `crystal spec` from repo root.
- **Evidence:** `test_output/S1-crystal-spec.log`.

---

## Reporting

The Validator produces a `GATE_REPORT.json` matching `rubric/gate_report_schema.md`, with every check above represented. PASS verdict requires all "Required" checks to pass; failures are returned to the architect for adjudication.
