
# Phase 7 — Implementation Brief

**Audience:** Implementer agent for Phase 7 (CI Integration for Accessibility & Visual Verification).
**Scope contract:** This document, plus `README.md` in this folder, plus the universal `rubric/implementation_criteria.md`, are the complete brief. Do not infer requirements from outside these documents.

---

> **2026-05-22 SCOPE NARROWED — read first.** This brief was authored under the original Phase 7 scope ("build the audit infrastructure + integrate into CI"). Per the planning retrospective (`handoff/planning-retrospective-2026-05-22.md` Principle 6 — audit-first), shipping audit infrastructure AFTER the work it audits is the failure mode that drove Phase 3's 10-remediation cost. **Phase 6.5 was inserted to ship the reusable audit harness BEFORE Phase 6 begins.** Phase 7's scope is now strictly **CI integration**: wrap Phase 6.5's existing harness (CDP harness extensions, AXTest patterns, XCUITest patterns, accessibility audit drivers) into GitHub Actions / equivalent workflow that runs on every PR. Steps 1, 2, 3 in the Goal section below — and most of the implementation steps that follow — describe infrastructure-building scope that **now belongs in Phase 6.5**. When Phase 7's brief is re-authored as YAML against `schemas/phase_brief.schema.json`, those scope sections will be removed or rewritten as "wire existing Phase 6.5 harness into CI."
>
> Until that re-authoring happens, treat this entire document as **stale-scope reference** for the historical CI-baselines work. The valid Phase 7 scope is in the README's "SCOPE NARROWED" callout at the top.

## Goal (STALE under narrowed Phase 7 scope; see banner above)

Stand up the automated verification floor for the cross-platform demo app produced in Phase 6:

1. A complete, deterministic set of **visual regression baselines** for every demo screen × platform × viewport × color scheme combination, committed under `test-results/initiative-demo-baselines/`.
2. A **diff script** that re-captures and compares against those baselines with a tuned pixel-tolerance threshold, emitting a human-readable side-by-side HTML report on failure.
3. **Accessibility audits** extended to cover the demo app on web (axe-core + IBM Equal Access), iOS (XCUITest), and macOS (AXUIElement walk).
4. A **GitHub Actions workflow** that runs all of the above on PRs to `feature/utility-first-css-asset-pipeline`, gating the merge.
5. A **verification runbook** documenting how to refresh baselines after intentional visual changes, run audits locally, and interpret CI failures.

When Phase 7 closes, the initiative is shippable: any future regression in look or accessibility will be caught by the gate before merge.

---

## Pre-reading checklist

Read these in order before writing any code. Skipping any of them will produce a brief that fights the codebase.

1. `docs/initiative-cross-platform-ui/MASTER_PLAN.md` — the tier model and phase sequence.
2. `docs/initiative-cross-platform-ui/phases/phase-07-accessibility-visual-verification/README.md` — scope summary, risks, acceptance criteria.
3. `docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/README.md` — what the demo contains (the five screens, build outputs, brand override).
4. `docs/initiative-cross-platform-ui/rubric/implementation_criteria.md` — universal standards.
5. `docs/initiative-cross-platform-ui/rubric/validation_criteria.md` — what the validator will check; build for it.
6. `docs/initiative-cross-platform-ui/rubric/gate_report_schema.md` — the report your work will be judged against.
7. `scripts/capture_amber_demo_screenshots.cr` — the existing screenshot harness. Phase 7 extends this pattern; do not rewrite it.
8. `scripts/axe_amber_demo_audit.cr` — axe-core audit pattern; extend.
9. `scripts/ibm_amber_demo_audit.cr` — IBM Equal Access pattern; extend.
10. `scripts/validate_amber_demo.cr` — orchestrator pattern; mirror.
11. `samples/cross_platform/ios_host/UITests/HIGVisualTests.swift` — existing iOS test target; extend.
12. `samples/cross_platform/macos_host/hig_showcase.cr` — macOS sample harness pattern.
13. `.github/workflows/static_docs.yml` — the only existing workflow; note the runner image convention (`crystal:latest`).
14. `test-results/web-design-system/` — the existing baseline naming convention (`{page}-{viewport}-{scheme}.png`). Mirror it.
15. `CLAUDE.md` — repo conventions; the new runbook is referenced here in step 11 below.

---

## Existing infrastructure to use (vs. rebuild)

Phase 7 is more "wire existing pieces together with a CI gate" than "build new tools." The accessibility audit runners, screenshot capture script, and macOS AX framework all exist; Phase 7 extends them with the initiative demo's screen set, commits baselines under a new tree, and adds a GitHub Actions workflow.

### Existing scripts to extend (do not duplicate)

- `scripts/capture_web_demo_screenshots.cr` — pattern source for the new `scripts/capture_demo_baselines.cr`. Existing script drives headless Chrome directly via CDP over WebSocket (see `../../rubric/behavior-simulation-toolkit.md` §3 and the canonical `scripts/capture_amber_demo_screenshots.cr` it re-exports), sets viewport sizes via `Emulation.setDeviceMetricsOverride`, captures PNGs via `Page.captureScreenshot`. New script targets the initiative demo screens, writes to `test-results/initiative-demo-baselines/web/`. Same CDP harness, same approach, different output path.
- `scripts/capture_amber_demo_screenshots.cr` — alternative reference for amber-themed demo capture. Read once for completeness.
- `scripts/axe_web_demo_audit.cr` — extend to point at the initiative demo's 7 HTML files.
- `scripts/axe_amber_demo_audit.cr` — reference pattern for amber-themed audit.
- `scripts/ibm_web_demo_audit.cr` — extend similarly.
- `scripts/ibm_amber_demo_audit.cr` — reference.
- `scripts/validate_web_demo.cr` and `scripts/validate_amber_demo.cr` — orchestrator patterns; new `scripts/validate_initiative_demo.cr` mirrors these.
- `scripts/capture_demo_quad.cr` (created in Phase 6) — pattern source for the quad-comparison artifact. **Distinct from Phase 7's baselines** — see the "Relationship to Phase 6's quad-comparison artifact" section above. Do not merge the two output trees.
- `samples/cross_platform/ios_host/UITests/HIGVisualTests.swift` — existing iOS visual XCUITest. Extend with new test cases for the initiative demo screens (or copy into `samples/initiative-cross-platform-ui-demo/ios/UITests/InitiativeDemoVisualTests.swift`).
- `scripts/run_ios_hig_tests.sh` — wraps `xcodebuild test`. The new iOS visual capture step in the CI workflow uses this script (or a near-clone targeting the new UITest target).
- `samples/cross_platform/macos_host/hig_showcase.cr` — macOS visual harness pattern.
- `spec/ui/hig_validation/macos_visual_spec.cr` — pattern for AX-driven macOS captures.

### Crystal source / test infrastructure you reuse

- `src/ui/ax_test/` and `src/ui/ax_test.cr` — Crystal-native macOS Accessibility API. The new `scripts/audit_macos_demo_accessibility.cr` (per phase brief) drives the AX tree via this framework. **Do not roll Carbon `AXUIElementCopyAttributeValue` bindings from scratch** — the prior audit (§A) flagged this; the existing `src/ui/ax_test/ax_ffi.cr` already declares the needed `lib` bindings. If a needed AX attribute is not yet bound in `ax_ffi.cr`, add it there rather than in a new file.
- `spec/ui/ax_test/ax_app_spec.cr` — existing spec for the AX framework. Extend.

### Existing CI / workflow infrastructure

- `.github/workflows/static_docs.yml` — the only existing workflow. Read it to understand the repo's GitHub Actions conventions (`crystal:latest` runner image, working-directory style). The new workflow `.github/workflows/initiative-cross-platform-ui.yml` follows the same conventions where they apply, but adds macOS-15 runners for the macOS + iOS jobs.

### Existing test result conventions

- `test-results/web-design-system/` — existing baseline tree. The new `test-results/initiative-demo-baselines/` is a sibling, **deliberately separate** (different naming convention: underscores not dashes, see Baseline directory layout above). Reuse the conceptual model (one PNG per `{page,viewport,scheme}` tuple, a `manifest.json`-style index) but do not write into the existing tree.
- `test-results/amber-design-system/` — older sibling. Reference pattern.
- `output/` — generated web artifacts. Read-only for Phase 7; do not write here.

### Pinned versions and runner environment

| Tool | Version | Where |
|---|---|---|
| Crystal compiler | `crystal-alpha` locally; `crystal:latest` container in CI for ubuntu-leg jobs | Follow existing `static_docs.yml` precedent. |
| GitHub Actions runner | `ubuntu-latest` for web jobs; `macos-15` for macOS + iOS jobs | Budget impact: 4 macOS minutes/PR per the Master Plan's notes-for-team-lead callout. Confirm budget before dispatch. |
| iOS simulator | `iPhone 17 Pro` device on `iOS-26-2` runtime | Match Phase 6 pin exactly. |
| Xcode | 16+ (iOS SDK 26 present on macos-15 runner) | Confirm via `xcodebuild -version` in workflow. |
| Chrome | headless Chrome launched directly with `--remote-debugging-port` per `../../rubric/behavior-simulation-toolkit.md` §3.2; capture the version reported by `GET /json/version` (the CDP HTTP endpoint) and record in `manifest.json.tooling.chrome` | Headless Chrome capture must record version so the diff script can warn when versions drift. |
| swift-snapshot-testing | `1.17.x` | Inherited from Phase 3 / 6. |
| axe-core | whatever `scripts/axe_web_demo_audit.cr` resolves at runtime | Phase 7 does not bump; just records the version in the manifest. |
| Pixel-diff threshold | ≤ 1.0% pixels differ by > 3/255 per channel (web); ≤ 0.5% (native) | Same as Phase 3's snapshot thresholds; **must match Phase 3's check V1–V8 thresholds** so baselines that pass Phase 3 also pass Phase 7. |

### Cross-phase artifact path alignment (flagged by prior audit)

The prior audit (§D) noted Phase 6's quad-evidence at `output/initiative-demo/quad-evidence/` is distinct from Phase 7's baseline tree at `test-results/initiative-demo-baselines/`. **This is intentional** (the "Relationship to Phase 6's quad-comparison artifact" section above documents the distinction). The two systems share viewport tag vocabulary and screen set but not file naming or output path. Do not merge them. Do not delete one in favor of the other.

### What is genuinely new vs. extended

| New | Extended / reused |
|---|---|
| `test-results/initiative-demo-baselines/` (entire tree, committed) | `scripts/capture_web_demo_screenshots.cr` (pattern source) |
| `scripts/capture_demo_baselines.cr` | `scripts/axe_web_demo_audit.cr`, `scripts/ibm_web_demo_audit.cr` (extended for demo screens) |
| `scripts/diff_demo_screenshots.cr` | `scripts/validate_web_demo.cr` (orchestrator pattern) |
| `scripts/audit_macos_demo_accessibility.cr` | `src/ui/ax_test/ax_ffi.cr` (extend with new AX attribute bindings if needed) |
| `scripts/validate_initiative_demo.cr` | `samples/cross_platform/ios_host/UITests/HIGVisualTests.swift` (XCUITest pattern) |
| `.github/workflows/initiative-cross-platform-ui.yml` | `.github/workflows/static_docs.yml` (workflow conventions) |
| `docs/initiative-cross-platform-ui/runbook.md` (or wherever the runbook lives per Step 11) | (none — runbook is new) |
| Manifest schema (`test-results/initiative-demo-baselines/manifest.json`) | (none) |

---

## Baseline directory layout

All baselines live under `test-results/initiative-demo-baselines/`. The directory is a sibling of the existing `test-results/web-design-system/` and `test-results/amber-design-system/` trees so the convention is recognizable to anyone who has worked in this repo before.

```
test-results/initiative-demo-baselines/
  README.md                          # generated; explains what this folder is and how to refresh
  manifest.json                      # generated; lists every baseline file + capture parameters + sha256
  web/
    {screen}_{viewport}_{scheme}.png
  macos/
    {screen}_{width}_{scheme}.png
  ios/
    {screen}_{viewport}_{scheme}.png
  diffs/                             # ephemeral; .gitignored; populated by diff script on failure
    {screen}_{platform}_{viewport}_{scheme}.diff.png
    report.html
```

### File naming convention

`{screen}_{platform}_{viewport}_{scheme}.png` with platform implied by parent directory.

- `{screen}` is one of: `signin`, `dashboard`, `detail`, `settings`, `tier3`.
- `{viewport}` is the rendered viewport tag:
  - web: `desktop` (1280×800), `tablet` (768×1024), `mobile` (375×667).
  - macOS: `wide` (1440×900), `narrow` (820×900).
  - iOS: `iphone17pro` (393×852 logical points / 1179×2556 px at @3x).
- `{scheme}` is `light` or `dark`.

The viewport tags are deliberately short, lowercase, hyphenless words so they sort cleanly and grep cleanly. Underscores separate the four axes. **`iphone17pro` is the canonical iOS tag** (matching Phase 6's "Viewport tag vocabulary" section in its implementation brief — both phases are aligned on this exact string). Forms like `iPhone 17 Pro`, `iphone_17_pro`, `iPhone17Pro` are not permitted in baseline filenames, manifest entries, or evidence paths.

### Relationship to Phase 6's quad-comparison artifact

Phase 6 produces `output/initiative-demo/quad-comparison.html` (assembled by `scripts/capture_demo_quad.cr`) with screenshots under `output/initiative-demo/quad-evidence/`. That artifact is a **human-visible side-by-side dashboard** showing all four platforms next to each other — its purpose is brand-cohesion verification by eyeball. Phase 7 produces a **machine-verifiable regression suite** under `test-results/initiative-demo-baselines/` driven by `scripts/capture_demo_baselines.cr` and `scripts/diff_demo_screenshots.cr` — its purpose is automated drift detection in CI.

The two systems are **deliberately parallel, not consolidated**:

| Aspect | Phase 6 quad-evidence | Phase 7 baselines |
|---|---|---|
| Artifact root | `output/initiative-demo/quad-evidence/` | `test-results/initiative-demo-baselines/` |
| Filename pattern | `{platform}-{screen}-{viewport}-{scheme}.png` (dashes) | `{platform}/{screen}_{viewport}_{scheme}.png` (underscores) |
| Audience | Humans assembling the four-up demo page | CI; the diff script |
| Lifetime | Refreshed per demo run; not regression baselines | Committed; refreshed only via the documented runbook |
| Tracking | Ad-hoc evidence; not gated on equality | Equality-gated against committed baselines |

Both systems use the same viewport tag vocabulary (`iphone17pro` etc.) and the same set of screens (`signin`, `dashboard`, `detail`, `settings`, `tier3`). Do not delete or rewrite the Phase 6 quad system; it serves a distinct purpose. The Phase 7 baselines may be regenerated from the Phase 6 capture orchestrator at any time, but the Phase 7 diff harness operates only against the `test-results/initiative-demo-baselines/` tree.

### `manifest.json` shape

Generated by the capture script; committed alongside the PNGs. The diff script reads it as the authoritative list of expected files and their parameters. Schema:

```json
{
  "generated_at": "2026-05-20T14:32:01Z",
  "tooling": {
    "crystal": "1.18.0",
    "chrome": "131.0.6778.85",
    "macos_runner": "macos-15",
    "ios_simulator": "iPhone 17 Pro / iOS 26.1"
  },
  "entries": [
    {
      "path": "web/signin_desktop_light.png",
      "screen": "signin",
      "platform": "web",
      "viewport": "desktop",
      "scheme": "light",
      "viewport_px": [1280, 800],
      "sha256": "..."
    }
  ]
}
```

The manifest is the single source of truth for the capture matrix. If a baseline PNG exists on disk but is not in the manifest, the diff script treats that as an error.

---

## Capture matrix

Five screens × the platform-viewport-scheme combinations enumerated below.

### Per-platform viewport counts

| Platform | Viewports | Color schemes | Per-screen captures |
|----------|-----------|---------------|---------------------|
| Web      | desktop, tablet, mobile = 3 | light, dark = 2 | 3 × 2 = **6** |
| macOS    | wide, narrow = 2 | light, dark = 2 | 2 × 2 = **4** |
| iOS      | iphone17pro = 1 | light, dark = 2 | 1 × 2 = **2** |
| **Total per screen** | | | **12** |

### Total baseline count

5 screens × 12 captures = **60 baseline PNGs**.

### Explicit enumeration

The implementer must produce exactly these 60 files. Anything else is a deviation that must be called out in the handoff.

**Web (5 × 6 = 30 files):**

```
web/signin_desktop_light.png       web/signin_desktop_dark.png
web/signin_tablet_light.png        web/signin_tablet_dark.png
web/signin_mobile_light.png        web/signin_mobile_dark.png
web/dashboard_desktop_light.png    web/dashboard_desktop_dark.png
web/dashboard_tablet_light.png     web/dashboard_tablet_dark.png
web/dashboard_mobile_light.png     web/dashboard_mobile_dark.png
web/detail_desktop_light.png       web/detail_desktop_dark.png
web/detail_tablet_light.png        web/detail_tablet_dark.png
web/detail_mobile_light.png        web/detail_mobile_dark.png
web/settings_desktop_light.png     web/settings_desktop_dark.png
web/settings_tablet_light.png      web/settings_tablet_dark.png
web/settings_mobile_light.png      web/settings_mobile_dark.png
web/tier3_desktop_light.png        web/tier3_desktop_dark.png
web/tier3_tablet_light.png         web/tier3_tablet_dark.png
web/tier3_mobile_light.png         web/tier3_mobile_dark.png
```

**macOS (5 × 4 = 20 files):**

```
macos/signin_wide_light.png      macos/signin_wide_dark.png
macos/signin_narrow_light.png    macos/signin_narrow_dark.png
macos/dashboard_wide_light.png   macos/dashboard_wide_dark.png
macos/dashboard_narrow_light.png macos/dashboard_narrow_dark.png
macos/detail_wide_light.png      macos/detail_wide_dark.png
macos/detail_narrow_light.png    macos/detail_narrow_dark.png
macos/settings_wide_light.png    macos/settings_wide_dark.png
macos/settings_narrow_light.png  macos/settings_narrow_dark.png
macos/tier3_wide_light.png       macos/tier3_wide_dark.png
macos/tier3_narrow_light.png     macos/tier3_narrow_dark.png
```

**iOS (5 × 2 = 10 files):**

```
ios/signin_iphone17pro_light.png    ios/signin_iphone17pro_dark.png
ios/dashboard_iphone17pro_light.png ios/dashboard_iphone17pro_dark.png
ios/detail_iphone17pro_light.png    ios/detail_iphone17pro_dark.png
ios/settings_iphone17pro_light.png  ios/settings_iphone17pro_dark.png
ios/tier3_iphone17pro_light.png     ios/tier3_iphone17pro_dark.png
```

Grand total: **60 files** (30 web + 20 macOS + 10 iOS).

---

## Capture script spec — `scripts/capture_demo_baselines.cr`

A single Crystal driver that orchestrates capture across the three platforms. Mirrors the structure of `scripts/capture_amber_demo_screenshots.cr` but writes into `test-results/initiative-demo-baselines/`.

Responsibilities:

- Build the demo app for the active platform target (`make web`, `make macos`, `make ios`) if outputs are missing or stale. Use mtime comparison; do not unconditionally rebuild.
- For each `(screen, platform, viewport, scheme)` tuple in the matrix, capture a PNG to the canonical path.
- Compute sha256 of each PNG and update `manifest.json`.
- Force every source of nondeterminism to a fixed value:
  - System time injected via `AP_DEMO_FAKE_NOW=2026-05-20T12:00:00Z` (read by the demo's clock shim).
  - All animations disabled by injecting `prefers-reduced-motion: reduce` on web, `UIAccessibilityIsReduceMotionEnabled` mock on iOS, `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` mock on macOS.
  - All images sourced from local, checked-in placeholder SVGs (no remote fetches).
  - Font rendering: disable subpixel AA on web (`-webkit-font-smoothing: antialiased`); document iOS and macOS font-rendering toggles in the runbook.
  - Cursors hidden, scrollbars hidden, blinking carets disabled.

Subcommands:

```
crystal run scripts/capture_demo_baselines.cr -- web         # web only
crystal run scripts/capture_demo_baselines.cr -- macos       # macOS only
crystal run scripts/capture_demo_baselines.cr -- ios         # iOS only
crystal run scripts/capture_demo_baselines.cr -- all         # all three
crystal run scripts/capture_demo_baselines.cr -- verify      # rerun + compare; no overwrite
```

The `verify` subcommand is what CI calls. The first three are what humans call to refresh baselines after an intentional visual change.

---

## Diff script spec — `scripts/diff_demo_screenshots.cr`

Independent driver. Takes two directories (or a manifest + a fresh capture), produces a verdict and a report.

### Algorithm

For each baseline entry in `manifest.json`:

1. Read the baseline PNG and the fresh PNG. If the fresh PNG is missing, the entry fails.
2. Confirm dimensions match. If not, the entry fails with `dimension_mismatch`.
3. Compute per-pixel difference. A pixel "differs" if any RGBA channel deviates by more than **3/255** (this absorbs lossless-encoder noise while catching real changes).
4. Compute `diff_ratio = differing_pixels / total_pixels`.
5. Compare `diff_ratio` against the **per-platform threshold**:
   - Web: `0.01` (1%) — sub-pixel font rendering varies enough on web to need a bit of slack.
   - macOS: `0.005` (0.5%) — AppKit is more deterministic.
   - iOS: `0.005` (0.5%) — simulator at a pinned device + iOS is highly deterministic.
   - The thresholds live in a single `THRESHOLDS` constant at the top of the file with a comment explaining the rationale. Validator and future tuning needs one place to look.
6. If `diff_ratio` exceeds the threshold, emit a diff visualization to `test-results/initiative-demo-baselines/diffs/`:
   - `{screen}_{platform}_{viewport}_{scheme}.diff.png` — red-highlighted differing pixels overlaid on the baseline.
   - Append an entry to `report.html`.

### Output format

The script writes `test-results/initiative-demo-baselines/diffs/report.html` with one section per failing entry containing, side-by-side: baseline | actual | diff overlay. The HTML is self-contained (inline CSS, base64 PNGs) so it can be viewed without serving the directory.

Top of report includes a summary table:

| Entry | Diff ratio | Threshold | Verdict |

Exit code: `0` if all entries within threshold, `1` otherwise. CI keys off the exit code.

### Library choice

Use pure-Crystal PNG decoding via the `stumpy_png` shard (already in the Crystal ecosystem and minimal-dependency). If `stumpy_png` is not present in `shard.yml`, add it; document the addition in the commit body. Do not shell out to ImageMagick — that introduces a system dependency that derails CI on a clean runner.

---

## Accessibility audit extensions

### Web — extend axe + IBM EA scripts

Existing scripts (`scripts/axe_web_demo_audit.cr` and `scripts/ibm_web_demo_audit.cr` — currently thin wrappers that delegate to `axe_amber_demo_audit.cr` / `ibm_amber_demo_audit.cr`) need a sibling pair that targets the initiative demo:

- New: `scripts/axe_initiative_demo_audit.cr`
- New: `scripts/ibm_initiative_demo_audit.cr`

Both share structure with their amber-demo counterparts. The PAGES constant points at the new demo outputs:

```crystal
PAGES = {
  "signin"    => File.join(ROOT, "output/initiative-demo/signin.html"),
  "dashboard" => File.join(ROOT, "output/initiative-demo/dashboard.html"),
  "detail"    => File.join(ROOT, "output/initiative-demo/detail.html"),
  "settings"  => File.join(ROOT, "output/initiative-demo/settings.html"),
  "tier3"     => File.join(ROOT, "output/initiative-demo/tier3.html"),
}
```

Output reports land under `test-results/initiative-demo-baselines/audits/`:

- `axe-audit.json`
- `ibm-equal-access.json`
- `axe-summary.md` (human-readable summary; one line per violation)

The failure threshold is **any axe or IBM violation at impact `serious` or higher**. The script's exit code is `0` only if zero violations at that level exist across all five pages. `moderate` and `minor` violations are reported but do not fail the script.

### iOS — XCUITest target

Add a new test target in `samples/cross_platform/ios_host/UITests/` (alongside the existing `HIGVisualTests.swift`):

- `InitiativeDemoAccessibilityTests.swift`

The test target launches the iOS sample app's initiative-demo entry point (a launch argument like `-initiativeDemo 1` selects the demo scene). For each of the five screens, three tests:

1. **`testFocusOrderIsLogical_{screen}`** — Use `XCUIApplication().keyboards.firstMatch` and the simulator's hardware keyboard (`UIKeyCommand`) to walk focus with Tab. Assert focus order matches a declared expectation array of accessibility identifiers (e.g., for signin: `[email_field, password_field, signin_button, social_apple_button, social_google_button, forgot_link]`).
2. **`testAccessibilityLabelsExist_{screen}`** — Iterate every `XCUIElement` of types `.button`, `.textField`, `.secureTextField`, `.switch`, `.slider`, `.staticText` (where the text is interactive). Assert each has a non-empty `label`. Assert each has a non-empty `identifier`.
3. **`testDynamicTypeLayout_{screen}`** — For each of `UIContentSizeCategory` values `.large`, `.extraLarge`, `.extraExtraLarge`, launch the app with the size category set, navigate to the screen, screenshot it, then assert no element's `frame.maxY` exceeds the safe area's `maxY` (proxy for "layout doesn't break"). Screenshots are written to `test-results/initiative-demo-baselines/ios-dynamic-type/{screen}_{size}.png` as attachments to the test run; they are evidence, not regressions baselines.

The Xcode scheme is named `InitiativeDemoAccessibility`. The test target runs via:

```
xcodebuild test \
  -project samples/cross_platform/ios_host/CrystalHIGHost.xcodeproj \
  -scheme InitiativeDemoAccessibility \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.1' \
  -resultBundlePath test-results/initiative-demo-baselines/audits/ios-xcresult
```

### macOS — AXUIElement walk

A standalone Crystal+ObjC bridge script: `scripts/audit_macos_demo_accessibility.cr`.

The script launches the macOS demo `.app` via NSWorkspace, waits for it to be foregrounded, then for each of the five screens (navigating between them with synthesized key events corresponding to the demo's nav shortcuts):

1. Walk the AX tree starting from the application's frontmost window.
2. For every element whose role is in the interactive set — `AXButton`, `AXTextField`, `AXSecureTextField`, `AXCheckBox`, `AXPopUpButton`, `AXSlider`, `AXTabGroup`, `AXLink`, `AXMenuButton` — record:
   - `role`
   - `roleDescription` (must be non-empty)
   - `title` or `value` (at least one must be non-empty)
   - `help` (warn if empty for `AXButton` without a visible title)
   - `identifier` (must be non-empty)
3. Emit `test-results/initiative-demo-baselines/audits/macos-axwalk.json` with the full tree per screen.
4. Exit non-zero if any element has an empty role, empty identifier, or no title-or-value.

The walk uses the Carbon `AXUIElementCopyAttributeValue` C API via Crystal's `lib` declarations. No external Swift code needed. Pattern after the existing `hig_showcase.cr` ObjC bridging.

---

## CI workflow — `.github/workflows/initiative-cross-platform-ui.yml`

A new workflow file. Does not replace `static_docs.yml`.

### Triggers

```yaml
on:
  pull_request:
    branches:
      - feature/utility-first-css-asset-pipeline
    paths:
      - "src/**"
      - "samples/initiative-cross-platform-ui-demo/**"
      - "scripts/**"
      - "test-results/initiative-demo-baselines/**"
      - ".github/workflows/initiative-cross-platform-ui.yml"
  workflow_dispatch:
```

### Job graph

Six jobs. `build-*` jobs are independent; `*-audit` and `visual-regression` jobs depend on the corresponding build.

```
build-web ─────────────────────┬──> visual-regression-web
                               └──> web-a11y-audit
build-macos ───────────────────┬──> visual-regression-macos
                               └──> native-a11y-audit-macos
build-ios ─────────────────────┬──> visual-regression-ios
                               └──> native-a11y-audit-ios
```

### Pinning

All version pins live in a single `env` block at the top of the workflow:

```yaml
env:
  CRYSTAL_VERSION: "1.18.0"
  CHROME_VERSION: "131.0.6778.85"
  MACOS_RUNNER: "macos-15"
  XCODE_VERSION: "26.1"
  IOS_SIMULATOR_DEVICE: "iPhone 17 Pro"
  IOS_SIMULATOR_OS: "26.1"
```

Runners:

- `build-web`, `web-a11y-audit`, `visual-regression-web`: `ubuntu-24.04` (cheaper than macOS; web work doesn't need Apple).
- All other jobs: `macos-15`.

> **Cost note for the team lead:** macOS GitHub-hosted runners are 10× the price of Linux runners. Four jobs running on macOS per PR is the dominant CI cost line. A weekly cadence + matrix slimming may be needed if PR volume is high. See "Open budget questions" below.

### Per-job steps

**`build-web`**
1. Checkout
2. Setup Crystal (use `crystal-lang/install-crystal@v1` at `CRYSTAL_VERSION`)
3. `make -C samples/initiative-cross-platform-ui-demo web`
4. Upload `output/initiative-demo/` as artifact `initiative-demo-web`.

**`build-macos`**
1. Checkout
2. Setup Crystal
3. Select Xcode `XCODE_VERSION`
4. `make -C samples/initiative-cross-platform-ui-demo macos`
5. Upload `output/initiative-demo-macos.app/` as artifact `initiative-demo-macos`.

**`build-ios`**
1. Checkout
2. Setup Crystal (cross-compile path; iOS host build is documented in `CROSS_COMPILE.md`)
3. Select Xcode + boot simulator: `xcrun simctl boot "$IOS_SIMULATOR_DEVICE"`
4. `xcodebuild build -project samples/cross_platform/ios_host/CrystalHIGHost.xcodeproj -scheme InitiativeDemo ...`
5. Upload `.app` bundle as artifact `initiative-demo-ios`.

**`visual-regression-web`** / `visual-regression-macos` / `visual-regression-ios`
1. Download corresponding build artifact.
2. Download repository (for baseline PNGs in `test-results/initiative-demo-baselines/`).
3. Install Chrome at pinned version (web job only).
4. Run `crystal run scripts/capture_demo_baselines.cr -- verify` for the relevant platform.
5. Run `crystal run scripts/diff_demo_screenshots.cr -- {platform}`.
6. On failure, upload `test-results/initiative-demo-baselines/diffs/` as artifact `visual-diff-{platform}`.

**`web-a11y-audit`**
1. Download `initiative-demo-web` artifact.
2. Install Chrome at pinned version.
3. `crystal run scripts/axe_initiative_demo_audit.cr`
4. `crystal run scripts/ibm_initiative_demo_audit.cr`
5. Upload `test-results/initiative-demo-baselines/audits/` as artifact `a11y-web`.
6. Fail the job on any `serious` or higher violation (script exit code).

**`native-a11y-audit-macos`**
1. Download `initiative-demo-macos` artifact.
2. `crystal run scripts/audit_macos_demo_accessibility.cr`
3. Upload `macos-axwalk.json` as artifact.

**`native-a11y-audit-ios`**
1. Build + run XCUITest target via `xcodebuild test` (scheme `InitiativeDemoAccessibility`).
2. Upload xcresult bundle as artifact.

### Failure threshold (single source of truth)

The threshold rules below are normative; do not duplicate them inside individual scripts beyond reading them from this contract:

| Audit | Failure threshold |
|---|---|
| Visual regression (web) | `diff_ratio > 0.01` on any baseline |
| Visual regression (macOS) | `diff_ratio > 0.005` on any baseline |
| Visual regression (iOS) | `diff_ratio > 0.005` on any baseline |
| axe-core | Any violation at impact `serious` or `critical` |
| IBM Equal Access | Any violation at level `violation` (their highest tier) |
| iOS XCUITest | Any test failure |
| macOS AX walk | Any interactive element missing role, identifier, or both title+value |

---

## Verification runbook — outline

A new file at `docs/initiative-cross-platform-ui/verification-runbook.md`. The implementer creates this file as part of Phase 7. The runbook is the source future humans/agents consult when a CI failure lands or an intentional visual change needs to land cleanly.

### Required sections

1. **Purpose & audience** — single paragraph; orient a reader who's never seen this initiative.
2. **What the audits check** — short table mirroring the failure-threshold table above.
3. **Running the audits locally**
   - Web: prerequisites (Chrome at pinned version, `CHROME_BIN` env var if not default), commands to run capture + diff + axe + IBM, expected runtime.
   - macOS: prerequisites (Xcode version, signed sample app), commands, expected runtime.
   - iOS: prerequisites (Xcode + simulator at pinned device/OS), commands, expected runtime.
4. **Updating baselines after an intentional visual change**
   - Step 1: confirm the change is intentional and reviewed.
   - Step 2: from a clean working tree, run `crystal run scripts/capture_demo_baselines.cr -- all`.
   - Step 3: inspect the diff against the previous baseline: `crystal run scripts/diff_demo_screenshots.cr -- all`.
   - Step 4: commit the new baselines in a dedicated commit with subject `[Phase 7] Refresh demo baselines: {reason}` and a body explaining the change.
   - Step 5: open the PR; CI will re-run the diff against the freshly-committed baselines and pass.
5. **Interpreting CI failures**
   - Visual regression failure: download the `visual-diff-{platform}` artifact, open `diffs/report.html`, look at the side-by-side. Decide: bug to fix, or intentional change requiring a baseline refresh.
   - axe-core failure: open `audits/axe-audit.json`, find the entry by `id`, fix the underlying widget (do not suppress).
   - IBM EA failure: open `audits/ibm-equal-access.json`, find the failing rule, fix.
   - macOS AX walk failure: open `audits/macos-axwalk.json`, search for the offending element by `identifier`, add the missing AX attribute in the macOS renderer or the demo source.
   - iOS XCUITest failure: open the xcresult bundle in Xcode locally, find the failing assertion, fix.
6. **Determinism gotchas** — short reference for what to do if local runs diverge from CI (font installation, simulator state, hardware keyboard attachment, etc.).
7. **Updating pinned versions** — process for bumping Crystal / Chrome / Xcode / Crystal shard versions, including the obligatory baseline refresh that follows.

The runbook ends with a short FAQ: "Why is the web threshold 1% and native 0.5%?", "Why don't we use ImageMagick?", "Can I skip the audits for a quick fix?"

---

## Step-by-step plan (commit-sized chunks)

Each numbered item is one commit. Subjects use the `[Phase 7] {imperative}` format from `implementation_criteria.md`.

1. **`[Phase 7] Add stumpy_png dependency for PNG diff`** — `shard.yml` + `shard.lock`. Commit body: justify pure-Crystal PNG decoding choice.
2. **`[Phase 7] Scaffold initiative-demo-baselines directory + manifest schema`** — empty directory with `.gitkeep`, `README.md`, an empty `manifest.json` skeleton. Add `diffs/` to `.gitignore`.
3. **`[Phase 7] Add capture_demo_baselines.cr (web subcommand)`** — Crystal driver implementing web capture for all 30 web baselines. No baselines committed yet. Manifest written.
4. **`[Phase 7] Add macos + ios subcommands to capture_demo_baselines.cr`** — macOS via the AppKit sample's screenshot path; iOS via `xcrun simctl io booted screenshot`. Manifest updates.
5. **`[Phase 7] Commit initial baselines for all 60 entries`** — produced from a clean local run on a pinned environment. Commit body: lists tooling versions (must match `manifest.json.tooling`).
6. **`[Phase 7] Add diff_demo_screenshots.cr with HTML report`** — independent of capture; reads manifest + filesystem; emits report.
7. **`[Phase 7] Add axe_initiative_demo_audit.cr and ibm_initiative_demo_audit.cr`** — copy-and-modify of amber-demo counterparts.
8. **`[Phase 7] Add audit_macos_demo_accessibility.cr`** — AXUIElement walk via `lib` bindings.
9. **`[Phase 7] Add InitiativeDemoAccessibility XCUITest target`** — Xcode project changes + `InitiativeDemoAccessibilityTests.swift`.
10. **`[Phase 7] Add CI workflow initiative-cross-platform-ui.yml`** — pinned versions, six jobs, threshold rules.
11. **`[Phase 7] Add verification-runbook.md and update CLAUDE.md pointer`** — runbook content; one-line pointer at the bottom of the cross-platform UI section of `CLAUDE.md`.
12. **`[Phase 7] Wire spec coverage for diff_demo_screenshots and manifest schema`** — `spec/scripts/diff_demo_screenshots_spec.cr` covers threshold edges, dimension mismatch, missing-file handling. Schema validator spec for `manifest.json`.

If a step balloons past ~400 LOC of diff, split it. Atomic commits are easier for the validator to navigate.

---

## Testing requirements

1. **Spec suite still passes:** `crystal spec` from repo root. Zero failures, zero errors. Pending tests must be either justified in spec comments or removed.
2. **Determinism sanity check:** re-running `crystal run scripts/capture_demo_baselines.cr -- all` immediately after a fresh baseline commit, then `crystal run scripts/diff_demo_screenshots.cr -- all`, must report **zero entries above threshold**. This is the strongest possible smoke test of the harness and is what the validator will repeat.
3. **Synthetic regression test:** introduce a 1-line CSS change (e.g., `--brand-primary` shifted by 10°), re-capture, confirm the diff script reports failures for every screen × scheme where that color appears. Revert before commit. The implementer documents this in the handoff "Deviations / Notes" section. (Do not commit the synthetic regression — it's a smoke test for the implementer, not a baseline.)
4. **Synthetic a11y violation:** drop `aria-label` on the sign-in primary button, run axe, confirm a `serious` violation is reported and exit code is non-zero. Revert.
5. **CI dry-run:** push the branch to a fork or feature ref where the workflow is allowed to run, confirm all six jobs go green. Attach the run URL to the handoff.

---

## Definition of done

Phase 7 implementation is done when, in addition to the universal definition in `implementation_criteria.md`:

1. All 60 baseline PNGs are committed under `test-results/initiative-demo-baselines/` and listed in `manifest.json` with correct sha256s.
2. `crystal run scripts/capture_demo_baselines.cr -- verify` exits 0 against the committed baselines on the implementer's machine.
3. `crystal run scripts/diff_demo_screenshots.cr -- all` exits 0 against the committed baselines.
4. `crystal run scripts/axe_initiative_demo_audit.cr` exits 0 (zero `serious+` violations).
5. `crystal run scripts/ibm_initiative_demo_audit.cr` exits 0.
6. `crystal run scripts/audit_macos_demo_accessibility.cr` exits 0.
7. `xcodebuild test -scheme InitiativeDemoAccessibility ...` exits 0.
8. `.github/workflows/initiative-cross-platform-ui.yml` parses (no syntax errors; `actionlint` reports clean if available).
9. CI dry-run on a feature ref shows all six jobs green; URL in handoff.
10. `docs/initiative-cross-platform-ui/verification-runbook.md` is present, complete per the outline above, and its commands have been executed end-to-end by the implementer at least once.
11. `CLAUDE.md` contains a single new line in the Cross-Platform UI section pointing future agents at the runbook.
12. The handoff message includes commit hashes, the CI dry-run URL, the determinism check output, and a "Deviations / Known concerns" section.

---

## Open budget questions for the team lead

Flagging these before implementation rather than after a surprise CI bill:

- **macOS runner spend.** Four jobs per PR on `macos-15` is the dominant cost. Options if the bill is unacceptable: (a) collapse `visual-regression-macos` and `native-a11y-audit-macos` into a single job that shares the build artifact; (b) run macOS/iOS audits only on `merge_group` events instead of every PR push; (c) switch to a self-hosted Apple Silicon runner. The implementer should default to (a) unless told otherwise; it's the least disruptive optimization.
- **iOS simulator boot time.** Cold-booting iPhone 17 Pro on iOS 26.1 in a fresh runner is ~90s. Consider caching the simulator runtime image via `actions/cache` keyed on `XCODE_VERSION + IOS_SIMULATOR_OS`. Cache hit drops boot to ~15s.
- **Chrome version pinning on Ubuntu runners.** Ubuntu's Chrome from `apt` is the rolling-stable version, not a pinned one. We'll need either `browser-actions/setup-chrome@v1` with a version pin or to download a specific build from `chromium-browser-snapshots`. The pinned-version approach is necessary for baseline stability; document the chosen mechanism in the runbook.
- **Baseline storage.** 60 PNGs at ~500KB each is ~30MB committed to git. Acceptable for now. If baselines triple in a future phase, consider git-lfs.

These are the only places where Phase 7 has externally-visible cost or operational implications. Everything else fits inside the existing build + scripts pattern.
