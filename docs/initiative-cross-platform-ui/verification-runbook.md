# Cross-platform UI initiative — verification runbook

This runbook is the operator's manual for the Phase 7 CI gate at
`.github/workflows/initiative-cross-platform-ui.yml`. The gate wraps
Phase 6.5's audit harness (`scripts/audit_harness.cr` +
`scripts/audit_harness_smoke.sh`) around Phase 6 / 6.8 / 6.9's committed
demo baselines (`docs/initiative-cross-platform-ui/baselines/`). The
audits run automatically on every PR targeting
`feature/utility-first-css-asset-pipeline`; the documentation here
covers the human side of the loop — refreshing baselines after
intentional UI changes, running audits locally, interpreting CI
failures, and the override path for known-failing audits.

---

## 1. What the CI gate checks

Every PR to `feature/utility-first-css-asset-pipeline` triggers the
workflow. Three parallel build jobs produce platform artifacts; three
audit jobs then consume those artifacts and invoke the smoke shim.

| Audit job   | Command                                              | What it fails on                                                                              |
|-------------|------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `audit-web` | `bash scripts/audit_harness_smoke.sh I-1 web demo-all`  | Visual-regression: any web demo screen exceeds its tolerance vs `baselines/web-desktop/*.png` or `baselines/web-mobile/*.png`. |
| `audit-web` | `bash scripts/audit_harness_smoke.sh I-6 web demo-all`  | Accessibility: axe-core or IBM Equal Access reports any violation at severity ≥ `serious`.    |
| `audit-macos` | `bash scripts/audit_harness_smoke.sh I-1 macos demo-all` | Visual-regression: any macOS demo screen exceeds tolerance vs `baselines/macos/*.png`.        |
| `audit-ios`   | `bash scripts/audit_harness_smoke.sh I-1 ios demo-all`   | Visual-regression: any iOS-simulator demo screen exceeds tolerance vs `baselines/ios/*.png`.  |

A final job (`no-working-tree-mutation`) runs `git status --porcelain`
to confirm the workflow did not touch any tracked source file. CI fails
non-zero if any of the above probes returns FAIL.

The demo screen set covered by `demo-all` is exactly the five Phase 6
slugs declared in `scripts/audit_harness.cr` (`DEMO_SCREEN_SLUGS`):
`demo-sign-in`, `demo-dashboard`, `demo-detail`, `demo-settings`,
`demo-tier-three`. Each slug ships paired light and dark PNG baselines
plus a `.tolerance.json` per appearance, all committed to the
`baselines/` tree.

Probes against other invariants (I-2 through I-11) are not minimum CI
content but they ARE reachable from the smoke shim, and the Phase 6.5
Validator runs the full 11 × 4 routing matrix locally. The CI gate is
deliberately a subset focused on the two regression classes that bite
hardest in code review: pixel drift and a11y violations.

---

## 2. Refreshing baselines after an intentional UI change

When a PR intentionally changes how a demo screen renders (e.g. a new
button style, a typography refresh, an icon swap), the CI gate will
flag the visual diff. That is correct behavior — the gate cannot
distinguish "intended improvement" from "accidental regression." The
fix is to regenerate the affected baselines locally and commit the new
PNGs in the same PR.

Use `scripts/regenerate_baselines.sh` per platform:

```bash
# Refresh a single web slug (desktop + mobile viewports both regenerated)
bash scripts/regenerate_baselines.sh --platform web --slug demo-sign-in

# Refresh every web baseline
bash scripts/regenerate_baselines.sh --platform web --all

# macOS — self-snapshotting host, no TCC prompt
bash scripts/regenerate_baselines.sh --platform macos --slug demo-dashboard

# iOS — drives xcodebuild + simctl, slow (~100s per slug)
bash scripts/regenerate_baselines.sh --platform ios --slug demo-detail
```

The regen script writes both appearances (`<slug>-light.png` and
`<slug>-dark.png`) and a default `tolerance.json` if one is not already
present. It also writes a toolchain fingerprint
(`<slug>.fingerprint.json`) so any future visual drift can be
attributed to a toolchain upgrade vs an application code change.

Output paths by platform:

| Platform | Refreshed files (per slug)                                                                 |
|----------|---------------------------------------------------------------------------------------------|
| `web`    | `docs/initiative-cross-platform-ui/baselines/web-desktop/<slug>-{light,dark}.png` AND `…/web-mobile/<slug>-{light,dark}.png` (+ tolerance + fingerprint) |
| `macos`  | `docs/initiative-cross-platform-ui/baselines/macos/<slug>-{light,dark}.png` (+ tolerance + fingerprint)                                                  |
| `ios`    | `docs/initiative-cross-platform-ui/baselines/ios/<slug>-{light,dark}.png` (+ tolerance + fingerprint)                                                    |

After regenerating, review the new PNGs visually, then commit them in
the same PR as the source-code change that produced them. The commit
message should explain *why* the visual changed so reviewers don't
have to reverse-engineer the diff.

> **Do not regenerate baselines from CI.** The workflow is read-only by
> design. If the gate fails on visual diff and you decide the new
> rendering is correct, regenerate locally, commit, push, and let CI
> re-run.

---

## 3. Running audits locally

The same probes CI runs are directly invocable from a developer
workstation. The shim is positional:

```bash
bash scripts/audit_harness_smoke.sh <I-N> <platform> [slug] [--format json]
```

Common invocations:

```bash
# Quick: visual regression for one web slug
bash scripts/audit_harness_smoke.sh I-1 web demo-sign-in

# Full sweep, web platform
bash scripts/audit_harness_smoke.sh I-1 web demo-all

# Accessibility, web
bash scripts/audit_harness_smoke.sh I-6 web demo-all

# macOS visual diff for the dashboard screen
bash scripts/audit_harness_smoke.sh I-1 macos demo-dashboard

# JSON output for further tooling
bash scripts/audit_harness_smoke.sh I-1 web demo-detail --format json
```

Exit-code contract (passthrough from `scripts/audit_harness.cr`):

| Exit | Meaning                                                                                    |
|------|--------------------------------------------------------------------------------------------|
| `0`  | Probe PASS, or a documented SKIP (e.g. Android cells, web-I-9 embedding skip).             |
| `1`  | Probe FAIL — visual diff above tolerance, a11y violation, contract walker miss, etc.       |
| `2`  | Probe unimplemented (routing matrix gap). Should never fire post Phase 6.5; file a bug.    |
| `3`  | Internal error (missing dep, bad arg, missing source). Check stderr for the failing tool.  |

The harness writes a per-run log under `tmp/audit-harness/` and (for
visual probes) diff PNGs under `tmp/audit-diffs/`. CI uploads both
trees as `audit-logs-<platform>` artifacts on every run, success or
failure.

---

## 4. Interpreting CI failures

Three failure classes account for nearly every red run. Diagnose in
this order.

### 4a. Visual diff above threshold (`audit-{web,macos,ios}` red on I-1)

Open the failing job's `audit-logs-<platform>` artifact in the
GitHub UI. You will find:

- `tmp/audit-diffs/<slug>-<appearance>.diff.png` — the magick `compare`
  visualization showing the deltas (red pixels = above tolerance).
- `tmp/audit-diffs/<slug>-<appearance>.actual.png` — what this run
  produced.
- `tmp/audit-harness/<run-timestamp>.log` — pixel deltas + tolerance
  decisions.

Diagnostic decision tree:

1. **Diff is widespread and looks like font/anti-aliasing noise**: the
   CI runner's font stack drifted (rare on macos-14, but possible after
   a Homebrew Cairo/Pango bump). Re-run; if persistent, regenerate
   baselines on the new toolchain and pin the upgrade in
   `<slug>.fingerprint.json`.
2. **Diff is localized to a single component or screen region**: an
   actual rendering change. Either (a) it is intentional and you must
   refresh baselines (see §2), or (b) it is a regression and you must
   revert the offending source change.
3. **Diff is across every slug on a single platform**: a shared chrome
   (status bar, window frame, theme tokens) shifted. Often the design
   token regenerator was run without the matching CSS/Swift refresh.

### 4b. Accessibility violation (`audit-web` red on I-6)

axe-core and IBM Equal Access write violation lists to
`tmp/audit-harness/<run-timestamp>.a11y.json`. Each entry contains a
rule ID, severity, the offending DOM selector, and remediation
guidance. Common shapes:

- `color-contrast` — a token override broke the WCAG 2.2 AA contrast
  guarantee that the default palette ships with. Either fix the
  override or override the override-override.
- `aria-required-attr` / `label` — a `UI::View` lost its
  `accessibility_label`. The native renderer falls back to the visual
  text, but a11y tooling treats absent labels as serious.
- `region` — a top-level landmark went missing. Likely the web renderer
  shed a `<main>` / `<nav>` wrapper.

### 4c. Build closure regression (`build-{web,macos,ios}` red before audit)

These jobs run the existing make targets, so a failure here means a
production-code change broke the build closure — independent of audit
behavior. Reproduce locally:

```bash
# Web closure
crystal-alpha build --no-codegen src/asset_pipeline.cr
make -C samples/initiative-cross-platform-ui-demo web

# macOS closure
swift build -c release --package-path swift/AssetPipelineSwiftKit
make -C samples/initiative-cross-platform-ui-demo macos

# iOS closure
bash samples/initiative-cross-platform-ui-demo/ios/build_crystal_lib.sh simulator
make -C samples/initiative-cross-platform-ui-demo ios
```

The `no-working-tree-mutation` job is failing only if one of the audit
scripts wrote to a tracked path. That's a Phase 6.5 harness bug; file
it against the harness rather than the failing PR.

---

## 5. When to override the gate

The gate exists to catch regressions, not to block work that
legitimately needs to land before its audit story is complete. If you
believe a failing audit should be deferred, follow this path — do
**not** disable the workflow or merge with red.

1. **Document the failure** in a new file under
   `docs/initiative-cross-platform-ui/handoff/audit-deferral-<YYYY-MM-DD>-<slug>.md`.
   Capture: the failing probe (invariant + platform + slug), the diff
   evidence (link to the `audit-logs-*` artifact), why the failure is
   expected/acceptable, and a target date/PR for resolving it.
2. **Open an architect adjudication request.** Tag the architect on
   the PR with a link to the handoff doc. The architect either (a)
   confirms the deferral and the gate-override path, or (b) rejects
   it and requests a fix-first resolution.
3. **If the architect approves the deferral**, the deferral handoff
   doc is the authority. Two follow-up paths are possible:
   - **Tolerance bump** (preferred for visual diffs that are real but
     within an acceptable cosmetic envelope): bump the
     `pixel_diff_max` in the slug's `tolerance.json`, commit, re-run.
   - **Audit suppression** (used only when the failing audit is the
     direct subject of a planned remediation): add the rule + selector
     to a suppression list referenced by the harness; the audit
     reports the violation but exits 0. The suppression entry must
     reference the deferral handoff doc by path.
4. **Never edit the workflow file to skip a job.** The workflow is the
   gate; degrading it defeats the purpose. If the gate itself is
   wrong (false positive in the harness), file against the harness
   and let Phase 6.5 fix it.

The deferral mechanism is intentionally heavyweight. The cross-platform
UI initiative's North Star is "beauty-by-default" — every audit
deferred is a tax on that goal, and the architect adjudication is the
brake that keeps the tax visible.
