
# Phase 7 — Validation Rubric

**Audience:** Validator agent for Phase 7 (CI Integration for Accessibility & Visual Verification).
**Scope reminder:** You **read, run, and report**. You do not modify code, tests, configuration, or docs except for the temporary-edit exceptions documented in `rubric/validation_criteria.md`. Every check below must be addressed in your `GATE_REPORT.json`, in order, with evidence captured under `handoff/phase-07-evidence-{YYYY-MM-DD}/`.

---

> **2026-05-22 SCOPE NARROWED — read first.** This validation rubric was authored under the original Phase 7 scope ("validate that the audit infrastructure + CI integration ships correctly"). Per the planning retrospective, Phase 6.5 now ships the audit infrastructure; Phase 7's scope is strictly **CI integration**. Until this rubric is re-authored to match the narrowed scope, treat checks below that name "infrastructure deliverables" (visual diff script, axe-core / IBM driver scripts, AXUIElement walker, XCUITest target authoring, baseline initial commits) as **inherited from Phase 6.5** rather than Phase 7 deliverables. Phase 7's validator should verify the CI workflow file, the workflow's ability to invoke Phase 6.5's harness, and the workflow's gate behavior on PRs — not re-validate Phase 6.5's deliverables.

## Pre-reading checklist

Read in order before running any check:

1. `docs/initiative-cross-platform-ui/MASTER_PLAN.md`
2. `docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/README.md`
3. `docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/implementation.md` (the implementer's contract — your checks verify it)
4. `docs/initiative-cross-platform-ui/rubric/validation_criteria.md`
5. `docs/initiative-cross-platform-ui/rubric/gate_report_schema.md`
6. `docs/initiative-cross-platform-ui/rubric/behavior-simulation-toolkit.md` — the keyboard-traversal step inside check 19, the macOS AX walk in check 22, and the iOS XCUITest accessibility methods in check 21 all reference its idioms (web §3.4, macOS §5.10, iOS §2.1–2.9).
7. The implementer's handoff message (commits, CI dry-run URL, deviations).

Do not read the implementer's commit messages until you have formed expectations from this rubric. Independence rule from `validation_criteria.md`.

---

## How to count checks

There are 18 numbered checks below (15 through 32). All are required unless explicitly marked optional. The `GATE_REPORT.json` `checks` array must contain one entry per check in the exact order they appear here, with `check_id` strings matching the slug in each section heading.

---

## Check 15 — `baselines.all-present`

**Required.** Verify every PNG enumerated in the implementation brief's capture matrix exists on disk and is listed in `manifest.json` with a matching sha256.

How to run:

1. Read `test-results/initiative-demo-baselines/manifest.json`.
2. Confirm `entries` has exactly 60 elements.
3. For each entry, confirm the file exists at the declared path and `sha256sum` of the file matches the manifest's `sha256` field.
4. Confirm there are no PNGs in `test-results/initiative-demo-baselines/web/`, `macos/`, or `ios/` that are not listed in the manifest.

Pass criteria: 60/60 files present, all sha256s match, no extras.

Evidence: `inspections/baselines.all-present.log` (output of file count + sha256 verification loop).

---

## Check 16 — `baselines.naming-convention`

**Required.** Verify every file under `test-results/initiative-demo-baselines/{web,macos,ios}/` follows the `{screen}_{viewport}_{scheme}.png` convention.

How to run:

1. List all PNGs under the three platform subdirectories.
2. For each, parse the filename against the regex documented in `implementation.md`. Confirm `{screen}` ∈ {signin, dashboard, detail, settings, tier3}, `{viewport}` ∈ {desktop, tablet, mobile, wide, narrow, iphone17pro}, `{scheme}` ∈ {light, dark}.
3. Confirm viewport tag matches the directory (e.g., `desktop` only appears under `web/`, `iphone17pro` only under `ios/`).

Pass criteria: every filename parses cleanly and lives in the correct directory.

Evidence: `inspections/baselines.naming-convention.log`.

---

## Check 17 — `baselines.determinism`

**Required.** Re-running the capture script against the same source produces **zero diffs** against the committed baselines. This is the single most important check in the phase — if it fails, every other capture-based check is unreliable.

How to run:

1. Ensure working tree is clean (`git status --short`).
2. Run `crystal run scripts/capture_demo_baselines.cr -- verify`. Capture stdout/stderr.
3. The `verify` subcommand re-captures into a temporary directory and diffs against the committed baselines. Confirm exit code 0.
4. Independently, run `crystal run scripts/capture_demo_baselines.cr -- all` against a copy of the working tree (do not commit). Run `crystal run scripts/diff_demo_screenshots.cr -- all`. Confirm exit code 0.
5. If the script lacks a `verify` subcommand, perform step 4 only and mark that as a deviation note (do not fail this check on subcommand naming alone).

Pass criteria: both runs exit 0 and the diff script reports zero entries above threshold.

Evidence: `test_output/baselines.determinism-verify.log`, `test_output/baselines.determinism-full.log`.

---

## Check 18 — `baselines.regression-detected`

**Required.** Introduce a known visual change, confirm the diff script reports failure, then revert. This is the inverse of check 17 — proves the harness catches real changes.

How to run:

**Canonical path for the brand-override source edit:** `samples/initiative-cross-platform-ui-demo/src/brand.cr` (the file Phase 6 ships, containing `DemoApp::DemoBrand < UI::Brand` — see Phase 6 implementation `Brand declaration` section). The implementer's Phase 6 handoff confirms this path — if Phase 6 chose a different location or renamed the brand class, the validator notes the substitution in this check's `notes` field, but the default is `src/brand.cr` with `DemoBrand`. This avoids the previous "circular dependency on the implementer's handoff" problem: the validator can run check 18 against a known path without first reading a handoff that may not exist yet.

1. Pick a single, easily-reverted source change that will visibly alter at least one screen. Recommended: shift the demo brand primary color by 30° hue rotation in `samples/initiative-cross-platform-ui-demo/src/brand.cr` (within `override_color_light`'s `brand_primary:` line — flip the `h` argument from `25` to `55`).
2. Rebuild the demo: `make -C samples/initiative-cross-platform-ui-demo web`.
3. Run `crystal run scripts/capture_demo_baselines.cr -- web` against a scratch output directory (or accept default overwrite, since you'll revert).
4. Run `crystal run scripts/diff_demo_screenshots.cr -- web`. Confirm exit code is non-zero.
5. Confirm `test-results/initiative-demo-baselines/diffs/report.html` exists and lists at least the signin and dashboard screens as failing (those screens use brand primary prominently per the Phase 6 brief).
6. **Revert the change.** `git checkout -- samples/initiative-cross-platform-ui-demo/src/brand.cr` and `git checkout -- test-results/initiative-demo-baselines/`. Confirm working tree is clean (`git status --short` empty).
7. Re-run check 17's determinism verification to confirm revert is clean.

Pass criteria: diff script exits non-zero with the introduced regression; tree clean after revert; check 17 still passes after revert.

Evidence: `screenshots/baselines.regression-detected-report.png` (screenshot of `report.html`), `test_output/baselines.regression-detected.log`, `inspections/baselines.regression-detected-git-status-after-revert.log`.

Notes field: explicitly document the source file changed (path + line), the modified value (before / after), and the revert command used.

---

## Check 19 — `audits.web-axe-zero-serious`

**Required.** **Bar:** behavior + conformance — the audit not only reports zero serious violations, but the audit actually visited every interactive element on every page.

Running axe-core against all five initiative demo pages reports zero violations at impact `serious` or `critical` AND covers every interactive element documented on each page.

How to run:

1. Confirm `output/initiative-demo/*.html` exist (build if not: `make -C samples/initiative-cross-platform-ui-demo web`).
2. Run `crystal run scripts/axe_initiative_demo_audit.cr`. Confirm exit code 0.
3. Open `test-results/initiative-demo-baselines/audits/axe-audit.json`. For each page, count violations by impact. Confirm `serious + critical == 0` across all pages.
4. **Coverage check:** for each page, count the number of distinct DOM elements that axe-core's run inspected (`results.passes.flatMap(p => p.nodes).length + results.violations.flatMap(v => v.nodes).length`). Cross-reference against an expected minimum derived from the Phase 6 screen specs — each page must have at least 5 interactive elements audited (button / input / link), AND every element with a `data-testid` attribute on the page must appear in the audit's `nodes` array under either `passes` or `violations`. An element with a `data-testid` that does not appear in any audit node means axe could not see it — that is a conformance failure even if it does not register as a violation.
5. **Keyboard traversal check (behavior bar — not source inspection).** Load each page in headless Chrome via CDP per `../../rubric/behavior-simulation-toolkit.md` §3.2. Use `Input.dispatchKeyEvent` to send **real trusted Tab key events** — CDP-dispatched input has `isTrusted === true`, which is required because focus libraries gate on `event.isTrusted` and reject JS-side `dispatchEvent(new KeyboardEvent(...))`. After each Tab press, evaluate via `Runtime.evaluate` and push to a window-side array:
   ```js
   window.__tabTrace.push({
     n: window.__tabTrace.length,
     tag: document.activeElement?.tagName,
     testid: document.activeElement?.getAttribute('data-testid'),
     text: document.activeElement?.textContent?.slice(0, 60)
   });
   ```
   Press Tab up to `2 × focusable_count` times (enough to wrap once); then send Shift-Tab the same number of times. Reference `../../rubric/behavior-simulation-toolkit.md` §3.4 for the trace pattern.

   Assertions:
   - Every focusable element with a `data-testid` appears at least once in the Tab trace (full coverage).
   - The order of first-visit `testid`s in the Tab trace matches the document order of `[data-testid]` elements, modulo skip-link prefix entries documented in the implementation brief. Compare against the source-of-truth array `expected_order = Array.from(document.querySelectorAll('[tabindex], a, button, input, select, textarea, [contenteditable]')).filter(el => el.offsetParent !== null).map(el => el.getAttribute('data-testid'))` — compute this once after the page loads.
   - Shift-Tab from the last entry visits the focusables in reverse first-visit order.
   - No entry has `testid === null` for elements documented to be focusable.

   A traversal that visits the address bar before all in-page focusables are covered is a focus-trap escape and fails the check.
6. Note `moderate` and `minor` violations in the check notes (informational; do not fail on them).

Pass criteria:
- Zero `serious` or `critical` violations across all five pages.
- Script exit code 0.
- Every `data-testid`-labeled element on each page is covered by axe's audit node list.
- Keyboard traversal visits every focusable `data-testid` element in DOM order.

Evidence: `audits/axes-initiative.json` (the audit report), `test_output/audits.web-axe.log`, `inspections/audits.web-axe-coverage.json` (per-page testid-coverage table), `inspections/audits.web-axe-keyboard-traversal-{page}.json` (the activeElement transcript per page).

---

## Check 20 — `audits.web-ibm-zero-violations`

**Required.** IBM Equal Access reports zero rule violations at level `violation` across the five demo pages.

How to run:

1. Run `crystal run scripts/ibm_initiative_demo_audit.cr`. Confirm exit code 0.
2. Open `test-results/initiative-demo-baselines/audits/ibm-equal-access.json`. Confirm the count of `level: "violation"` entries is zero across all pages.
3. `recommendation` and `potentialviolation` entries are informational; document counts in notes.

Pass criteria: zero `violation`-level entries; script exit code 0.

Evidence: `audits/ibm-initiative.json`, `test_output/audits.web-ibm.log`.

---

## Check 21 — `audits.ios-xcuitest-passes`

**Required.** **Bar:** behavior — the XCUITest accessibility target builds AND its tests actually drive the running app's accessibility tree, asserting per-element label/trait/role on real rendered widgets (not a source scan).

The implementation brief's XCUITest accessibility target contains three test methods per screen, totaling 15 tests:
- **focus-order:** walks `app.descendants(matching: .any)` in document order; asserts every interactive element (`buttons`, `switches`, `sliders`, `textFields`, `secureTextFields`, `pickers`) has `accessibilityIdentifier` set AND has a non-empty `label`. Validates the iOS analog of "every focusable has a label."
- **labels-exist:** for every element with a known `accessibilityIdentifier`, asserts `element.label` is non-empty AND `element.value` is non-nil-or-non-empty where the widget type requires it (switches, sliders, text fields).
- **dynamic-type:** launches the app with `app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]`; asserts the rendered text scales (verifiable by capturing `staticText.frame.size.height` at standard vs XXXL and asserting the XXXL height is at least 1.5× the standard height for at least one labeled text element per screen).

How to run:

1. From the macOS host (this check is blocked on non-macOS environments — mark `blocked: true` if you are not on macOS):
   ```
   xcodebuild test \
     -project samples/cross_platform/ios_host/CrystalHIGHost.xcodeproj \
     -scheme InitiativeDemoAccessibility \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
     -resultBundlePath /tmp/phase07-xcresult
   ```
2. Confirm exit code 0.
3. Open the xcresult bundle (`xcrun xcresulttool get --path /tmp/phase07-xcresult --format json`) and confirm three test methods per screen (focus order, labels exist, dynamic type) all passed.
4. Confirm 15 tests total (5 screens × 3 methods). Note any pending/skipped tests.
5. **Spot-check a single failing assertion's evidence quality.** Pick one passing dynamic-type test; in the xcresult bundle confirm the test attached the `staticText.frame.size.height` measurements at both content sizes (per the brief's evidence pattern). If the test passed but attached no measurement artifact, the validator marks the check `passed: false` with note `"Test reported pass but did not attach measured evidence — cannot independently verify."` This catches tests that have been rewritten into presence-only checks since the brief was authored.

Pass criteria: 15/15 tests pass; xcodebuild exits 0; spot-checked test attached genuine geometry measurements.

Evidence: `test_output/audits.ios-xcuitest.log`, `audits/ios-xcresult-summary.json` (the parsed xcresult).

---

## Check 22 — `audits.macos-axwalk-passes`

**Required.** **Bar:** behavior — the macOS AXUIElement walk programmatically traverses the running app's AX tree, recording every node, and asserts the role + identifier + label invariant on each interactive element. The audit runs against the launched binary, **not** a static analysis of the Crystal source.

The audit script (`scripts/audit_macos_demo_accessibility.cr`) implements the walk pattern from `../../rubric/behavior-simulation-toolkit.md` §5.10. For each demo screen, it:
1. Launches `./bin/demo_app` with the screen's `DEMO_SCREEN` env var.
2. Attaches via `UI::AXTest::App.connect(pid)`.
3. Recursively walks `app.root` via `children`.
4. For every node whose `role` is in the interactive set (`AXButton`, `AXSwitch`, `AXTextField`, `AXSlider`, `AXCheckBox`, `AXRadioButton`, `AXPopUpButton`, `AXTabGroup`, `AXMenuItem`, `AXLink`), records `{role, identifier, label, title, value, subrole, enabled, position, size}`.
5. Writes the per-screen accumulated array to `test-results/initiative-demo-baselines/audits/macos-axwalk.json`.

How to run:

1. Build the macOS demo: `make -C samples/initiative-cross-platform-ui-demo macos`.
2. Run `crystal run scripts/audit_macos_demo_accessibility.cr`. Confirm exit code 0.
3. Open `test-results/initiative-demo-baselines/audits/macos-axwalk.json`. Confirm every entry under every screen has: non-empty `role`, non-empty `identifier` (read via `AXIdentifier` attribute per toolkit §1.4), and at least one of `title` or `label` (read via `AXTitle` / `AXDescription`) is non-empty.
4. Confirm every entry's `enabled` field is a real boolean (read from `AXEnabled`, not absent / nil — absence indicates the script silently swallowed an error reading the attribute).
5. Sample-spot-check at least three interactive elements per screen and confirm the recorded role matches the widget type expected (e.g., a sign-in primary button is `AXButton` with role description "button").
6. **Coverage cross-check.** For each screen, cross-reference the count of interactive entries in `macos-axwalk.json` against the count of `test_id`-bearing `UI::View` declarations in that screen's Crystal source. The counts should be within ±2 (allowing for internal SwiftUI scaffolding views that get their own AX nodes). A discrepancy of more than 2 means either the walk missed nodes or the renderer is emitting AX nodes for views that shouldn't have them; both are bugs.

Pass criteria: script exit code 0; every entry has role + identifier + (title or label); enabled is a real boolean; coverage cross-check within tolerance for every screen.

Evidence: `audits/macos-axwalk.json`, `test_output/audits.macos-axwalk.log`, `inspections/audits.macos-axwalk-spotcheck.md`.

---

## Check 23 — `ci.workflow-syntactically-valid`

**Required.** `.github/workflows/initiative-cross-platform-ui.yml` exists and is syntactically valid YAML and valid GitHub Actions.

How to run:

1. Confirm file exists at `.github/workflows/initiative-cross-platform-ui.yml`.
2. Parse as YAML using a known-good tool (`crystal eval` with `YAML.parse`, or `python -c "import yaml; yaml.safe_load(open('...'))"` if available).
3. If `actionlint` is on PATH, run `actionlint .github/workflows/initiative-cross-platform-ui.yml`. Otherwise note its absence and proceed.
4. Inspect the file for the six required jobs: `build-web`, `build-macos`, `build-ios`, `visual-regression-{web,macos,ios}`, `web-a11y-audit`, `native-a11y-audit-macos`, `native-a11y-audit-ios`. Confirm trigger is `pull_request` on `feature/utility-first-css-asset-pipeline`. Confirm pinned versions present in `env` block.

Pass criteria: YAML parses, actionlint clean if available, all required jobs present, pinned versions present.

Evidence: `inspections/ci.workflow-yamllint.log`, `inspections/ci.workflow-actionlint.log` (or note absence), `inspections/ci.workflow-job-inventory.md`.

---

## Check 24 — `ci.dry-run-green`

**Required.** The CI workflow has been demonstrated to run end-to-end. The implementer's handoff includes a URL to a GitHub Actions run where all six jobs succeeded.

How to run:

1. Read the implementer's handoff. Extract the CI dry-run URL.
2. Visit the URL (use WebFetch if browser tools allow). Confirm:
   - The run targeted a branch derived from `feature/utility-first-css-asset-pipeline` (or the branch itself).
   - All six jobs completed with conclusion `success`.
   - The run is on a commit that is in the implementer's commit list.
3. If the run is older than 30 days, request a re-run before passing this check.

Pass criteria: URL is reachable, all six jobs green, commit matches.

Evidence: `inspections/ci.dry-run-url.txt`, `screenshots/ci.dry-run-green.png` (screenshot of the run summary).

If no dry-run URL is provided, mark `passed: false` with a note. Do not push the branch yourself to trigger one — that's an implementer responsibility.

---

## Check 25 — `ci.regression-gates-fail-correctly`

**Required.** A test commit with an intentional visual regression demonstrably fails CI; a test commit with an a11y violation demonstrably fails CI.

How to run:

The implementer's handoff should reference one or two test PRs/runs that exercised these failure modes. If present, follow links and confirm:

1. **Visual regression PR:** introduced a known visual change without updating baselines. Confirm the `visual-regression-{web|macos|ios}` job failed (not the build job — that should still pass). Confirm the diff artifact is downloadable and shows the expected screens failing.
2. **A11y violation PR:** introduced a known a11y violation (e.g., removed an aria-label). Confirm the `web-a11y-audit` job failed with the expected rule ID in its output.

If the implementer did not produce these test PRs:

1. Mark this check `blocked: true` with note "Implementer did not provide failure-mode dry-runs."
2. Do NOT freelance the PRs yourself — pushing to the initiative branch is an implementer action.

Pass criteria: both failure-mode runs exist, both failed in the right job for the right reason.

Evidence: `inspections/ci.regression-gates-prs.md` (links + summary).

---

## Check 26 — `runbook.present-and-complete`

**Required.** `docs/initiative-cross-platform-ui/verification-runbook.md` exists and contains all sections enumerated in the implementation brief's runbook outline.

How to run:

1. Confirm file exists.
2. Confirm sections present: Purpose & audience, What the audits check, Running the audits locally (web/macOS/iOS), Updating baselines, Interpreting CI failures, Determinism gotchas, Updating pinned versions, FAQ.
3. Confirm each "Running the audits locally" subsection contains an executable command sequence and an expected-runtime statement.
4. Confirm the "Interpreting CI failures" section covers all five failure modes (visual web/macOS/iOS, axe, IBM, macOS AX walk, iOS XCUITest).

Pass criteria: all sections present and non-empty.

Evidence: `inspections/runbook.section-inventory.md` (your section-by-section presence audit).

---

## Check 27 — `runbook.commands-actually-work`

**Required.** Follow the "Running the audits locally" section verbatim and confirm the commands succeed.

How to run:

1. Open the runbook.
2. For the web local-run section: copy-paste each command into a shell, run it, capture exit code.
3. Same for macOS section (skip if not on macOS; mark partial).
4. Same for iOS section (skip if not on macOS; mark partial).
5. For the "Updating baselines" section: do not actually update committed baselines, but confirm step 2 (capture command) and step 3 (inspection command) execute cleanly against a scratch directory.

Pass criteria: every documented command runs without modification and produces the documented effect.

Evidence: `test_output/runbook.commands-{web,macos,ios,update}.log`.

If you encounter a command that does not work as documented, mark `passed: false` and quote the broken command in `notes`.

---

## Check 28 — `runbook.claude-md-pointer`

**Required.** `CLAUDE.md` contains a pointer to the verification runbook.

How to run:

1. Read `CLAUDE.md`.
2. Confirm a line exists in the "Cross-Platform UI System" section (or a clearly-marked successor section) that points readers at `docs/initiative-cross-platform-ui/verification-runbook.md`.
3. Confirm the line is reachable by `grep -F "verification-runbook" CLAUDE.md`.

Pass criteria: pointer present and findable.

Evidence: `inspections/runbook.claude-md-pointer.log`.

---

## Check 29 — `specs.suite-passes`

**Required.** The full Crystal spec suite passes.

How to run:

1. From repo root: `crystal spec 2>&1 | tee handoff/phase-07-evidence-{DATE}/test_output/specs.suite-passes.log`.
2. Confirm the final line reports `0 errors, 0 failures`.
3. Note any `pending` counts; investigate whether any are pending tests added by this phase (they should not be — Phase 7 specs should be either implemented or absent).

Pass criteria: zero errors, zero failures.

Evidence: `test_output/specs.suite-passes.log`.

---

## Check 30 — `specs.diff-script-coverage`

**Required.** Specs for `scripts/diff_demo_screenshots.cr` exist and cover the threshold edges.

How to run:

1. Read `spec/scripts/diff_demo_screenshots_spec.cr` (or wherever the implementer placed it; check `spec/` tree).
2. Confirm tests cover at minimum: (a) ratio just under threshold passes, (b) ratio just over threshold fails, (c) dimension mismatch fails, (d) missing fresh file fails, (e) per-platform thresholds applied to the right platform.
3. Run the spec file specifically: `crystal spec spec/scripts/diff_demo_screenshots_spec.cr`. Confirm pass.

Pass criteria: all five edges covered; spec file passes.

Evidence: `test_output/specs.diff-script-coverage.log`, `inspections/specs.diff-coverage-mapping.md` (your map from test name to edge).

---

## Check 31 — `manifest.consistency`

**Required.** `manifest.json` is internally consistent with itself and with the implementation brief's pinned tooling.

How to run:

1. Read `test-results/initiative-demo-baselines/manifest.json`.
2. Confirm `tooling.crystal` equals the version pinned in `.github/workflows/initiative-cross-platform-ui.yml`.
3. Confirm `tooling.chrome` equals the workflow's `CHROME_VERSION`.
4. Confirm `tooling.macos_runner` equals `MACOS_RUNNER`.
5. Confirm `tooling.ios_simulator` references the same device + OS as `IOS_SIMULATOR_DEVICE` + `IOS_SIMULATOR_OS`.
6. Confirm every `entries[*].viewport_px` matches the per-platform tag (e.g., `desktop` → `[1280, 800]`, `mobile` → `[375, 667]`).

Pass criteria: every cross-reference matches.

Evidence: `inspections/manifest.consistency.md` (your line-by-line cross-reference table).

---

## Check 32 — `handoff.complete` (optional)

**Optional.** The implementer's handoff message includes the required pieces.

How to run:

1. Read the handoff message.
2. Confirm presence of: commit hashes, CI dry-run URL, determinism check output, and a "Deviations / Known concerns" section (even if empty, the heading must exist per `implementation_criteria.md`).

Pass criteria: all four pieces present.

Evidence: `inspections/handoff.complete.md`.

This check is optional because the team lead will catch a missing handoff field even without an explicit validator check. But surfacing it here makes the implementer's next iteration faster if a piece is missing.

---

## Final report

Return per `validation_criteria.md`:

- `## Verdict` — `PASS` if every required check (15–31) has `passed: true`, otherwise `FAIL`.
- `## GATE_REPORT` — full JSON conforming to `gate_report_schema.md`.
- `## Summary` — 2–4 sentence prose. If FAIL, name the failing checks and the smallest set of changes needed to unblock.

Pay specific attention in the summary to:

- Whether the determinism check (17) and the regression-detection check (18) both pass. These two together are the load-bearing pair that proves the harness works. A pass on either alone is insufficient.
- Whether the CI dry-run (24) and the CI regression-gate dry-runs (25) are both green. Without both, the workflow's value is unproven even if its YAML is valid.
- Any threshold tuning concerns. If during check 17 you see diff ratios trending close to (but under) threshold, note it — that's a future flakiness risk worth flagging to the team lead even if it doesn't fail the check today.
