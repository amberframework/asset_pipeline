# Phase 7 — CI Integration for Accessibility & Visual Verification

**Tier:** Infrastructure
**Depends on:** Phase 6.5 (audit harness must exist to wrap into CI) AND Phase 6 (demo app must exist to baseline against)
**Blocks:** Initiative sign-off
**Estimated remediation budget:** 1 loop

> **2026-05-22 SCOPE NARROWED:** This phase originally read "build audit infrastructure + integrate into CI." Per the planning retrospective (`handoff/planning-retrospective-2026-05-22.md` Principle 6), shipping audit infrastructure AFTER the work it audits is the failure mode that drove Phase 3's 10-remediation cost. Phase 6.5 was inserted to ship the reusable audit harness BEFORE Phase 6 begins. **Phase 7's scope is now strictly "CI integration"** — wrap Phase 6.5's existing harness into GitHub Actions / equivalent workflow that runs on every PR. The original "build the harness" scope is now in Phase 6.5.
>
> **Brief authoring constraint:** Phase 7's brief MUST be authored as YAML against `schemas/phase_brief.schema.json` and pass `scripts/validate_phase_brief.cr` before dispatch. The pre_dispatch_validation script_path must reference an existing script.

---

## Why this phase exists

By this point, phases 1–6 have built a real cross-platform demo. But without an automated way to *prove* it stays correct over time, the next change to a renderer could silently regress glass appearance or push a button off-screen at 375px without anyone noticing until a human spots it.

This phase establishes the automated verification floor:

- **Visual regression** for the demo app at every screen × platform × viewport × scheme combination.
- **Accessibility audits** per platform: axe-core + IBM Equal Access for web, XCUITest/AXTest for native.
- **CI gate** so the audits and visual diffs run on every PR to the initiative branch.

After this phase, the initiative is shippable.

## Scope summary (NARROWED 2026-05-22)

In scope (CI integration of Phase 6.5's existing harness — NOT infrastructure-building):

- **GitHub Actions workflow** (or equivalent) at `.github/workflows/initiative-cross-platform-ui.yml` that runs on PRs to `feature/utility-first-css-asset-pipeline`:
  - Invokes Phase 6.5's pre-existing audit harness (`scripts/audit_harness.cr` or equivalent path shipped by Phase 6.5) to run visual regression + accessibility audits.
  - Builds the demo on web, macOS, iOS (Android per its own gating from the cross-platform compile policy).
  - Fails the check if any audit reports a violation above a configured severity threshold.
- **Baselines already exist** at `docs/initiative-cross-platform-ui/baselines/{ios,macos,web-desktop,web-mobile}/` — 40 PNGs committed by Phase 6 (sign-in/dashboard/detail/settings/tier-three × light/dark × 4 surfaces). Phase 7 CI workflow CONSUMES these baselines (read-only — workflow must NOT modify the working tree). Intentional baseline refresh after a deliberate UI change is performed via the verification runbook + Phase 6.5's `scripts/regenerate_baselines.sh` invoked locally by a developer, NOT by CI.
- **Verification runbook** at `docs/initiative-cross-platform-ui/verification-runbook.md` explaining how to update baselines after an intentional visual change (re-run Phase 6.5's regenerate command + commit new PNGs).
- **CLAUDE.md pointer** to the runbook + the audit-harness scripts Phase 6.5 ships.

Explicitly out of scope (moved to Phase 6.5):

- **Authoring the audit harness itself** — Phase 6.5's deliverable. Phase 7 does not author `scripts/audit_harness.cr`, `scripts/diff_demo_screenshots.cr`, axe-core/IBM drivers, AXUIElement walkers, or XCUITest target authoring. Phase 7 calls them.
- **Designing the visual diff algorithm or pixel tolerance** — Phase 6.5's deliverable.
- **AXTest / XCUITest pattern library** — Phase 6.5's deliverable.

Other out-of-scope (unchanged):

- Performance regression testing (FPS, render time). Possible future phase.
- User testing / qualitative research. This phase is about machine-checkable invariants.
- Fixing audit failures discovered during baselining — those become bugs to fix, but the bug fixing itself is not phase 7 work. Phase 7 establishes the CI gate; the work of staying above the gate is permanent.

## Acceptance summary

Phase 7 is done when:

- Visual regression baselines are committed for every demo screen × platform × viewport × scheme combination.
- The diff script runs cleanly: zero diffs immediately after baseline (sanity check).
- Web accessibility audits (axe + IBM EA) produce zero violations at level "serious" or higher on the demo pages, or every remaining violation is documented in the runbook with a justification and disposition.
- iOS XCUITest accessibility checks pass.
- macOS AXUIElement walk passes.
- CI workflow is set up and a test PR demonstrates that:
  - Introducing a visual regression fails the check.
  - Introducing an accessibility violation fails the check.
- The verification runbook documents the steps to refresh baselines, run audits locally, and interpret CI failures.

Detailed checks in `validation.md`.

## Risk notes

- **Pixel-diff false positives.** Anti-aliasing, font hinting, and subpixel rendering vary across CI machines. The tolerance threshold must be tuned. Validator should explicitly check that re-running the baseline twice produces zero diffs.
- **iOS simulator screenshot determinism.** The simulator must be at a fixed device + iOS version. Pin in the build script.
- **macOS resizable window captures.** The `.app` must be launched at a deterministic window size for baselining. Make this scripted, not interactive.
- **CI runtime cost.** Building three platform targets per PR may be slow. Budget for it; the alternative (no CI gate) is worse.
- **Existing audit infrastructure** is solid (`scripts/validate_web_demo.cr`, axe, IBM EA). Extend it; do not rewrite from scratch.

## Briefing documents

- Implementer: `implementation.md`
- Validator: `validation.md`
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
