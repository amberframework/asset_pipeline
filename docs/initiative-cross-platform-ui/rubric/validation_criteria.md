# Validation Criteria (Universal)

These standards apply to every phase's validator. The phase-specific `validation.md` extends them with the actual check list. This document specifies *how* to run a check, capture evidence, and structure the report.

---

## Validator scope

The validator:

- **Reads** code, configuration, test output, screenshots, audit reports, and prior gate reports.
- **Runs** test suites, build commands, screenshot capture scripts, accessibility audits.
- **Inspects** rendered output (HTML for web, captured ObjC call traces for native if available, screenshots).
- **Records** findings in a structured `GATE_REPORT.json`.

The validator **does not**:

- Modify code, tests, configuration, or documentation. (Exception: see "Temporary edits for verification" below.)
- Pass judgement on style preferences not in the rubric. The rubric is the contract.
- Skip checks. Every check in `validation.md` must be addressed, even if blocked.
- Consolidate two failures into one. Each check is reported independently.

---

## Verification depth: presence, behavior, conformance

Every validator check in this initiative sits on one of three escalating bars. Phase rubrics declare which bar a given check is held to. The validator must read each check with this taxonomy in mind, because a check phrased as "verify X exists" without a stated bar is almost always being held to **behavior** or **conformance**, not the easy presence bar that the words alone suggest.

### The three bars

**Presence check.** "The element, file, CSS rule, symbol, or declaration exists." This is the lowest bar. It is satisfied by `grep`, by an AST walk, by reading a generated artifact. Presence is easy to automate and easy to false-pass: a button rendered with the right `data-testid` but no `onclick` wiring will pass a presence check trivially. Presence is **never sufficient on its own** for an interactive widget claim, a layout claim, or any claim that involves runtime wiring across a language boundary (Crystal → ObjC, Crystal → SwiftUI, Crystal → JS). Presence is sufficient for: static design tokens, generated CSS variables, file-existence assertions, module-load assertions, public-API surface assertions ("type `Foo` is declared as `abstract class`").

**Behavior check.** "The element does the thing it claims to do, end to end." For a button: tap on the rendered surface (XCUITest tap, CDP `Input.dispatchMouseEvent` click or `Runtime.evaluate` `.click()` on web, AppKit synthetic event) fires the bound action handler, the bound state mutates, the next render reflects the new state, and any visible feedback (press animation, focus ring, haptic) plays. For a navigation: trigger the link, the next view becomes visible, the back affordance restores the previous view. For a modal: trigger open, the modal is in the accessibility tree; trigger each documented dismiss path (primary action, cancel, backdrop, escape key on web, swipe-down on iOS); confirm the modal is removed from the accessibility tree and focus returns to the trigger. Behavior is required for every Tier 2 and Tier 3 widget claim, every phase that wires a Crystal-side declaration to a native or web runtime, and every navigation flow.

**Conformance check.** "The rendered output matches the design intent, not just the schema." Conformance is measured from rendered pixels and from the platform's runtime accessibility tree, never from the source. For a button: read `getBoundingClientRect()` on web or query the `XCUIElement.frame` on iOS and assert the hit-target measures at least 44×44 device-independent pixels — do not assert that the source declares `padding: 12px` and call it done. For a layout: capture screenshots at the declared breakpoints and confirm the headline does not overflow, the card grid reflows to a single column at 375 px, the safe-area inset is honored at the bottom of an iOS action sheet. For a color: render the page, sample the pixel, compute Lab distance against the token value; do not assert the CSS variable is set. Conformance is required for every visual claim, every "looks right" claim, every accessibility claim that depends on contrast, every visual regression baseline.

### Examples of failures that slip past presence but get caught downstream

These are illustrative, not exhaustive. Each names a real category of bug the cross-platform UI initiative has reason to expect.

- **Wired-wrong action handler.** A Crystal `Button` view declares `on_click ProductsAction::Open.new` and the SwiftUI bridge renders the button into the iOS host with the correct `setAccessibilityIdentifier:`. Presence: pass — the button exists with the right testid. The `onClick` handler in the SwiftUI shim is mis-routed to `ProductsAction::Close.new` because the callback registry indexed by the wrong key. Tapping does nothing user-visible because Close on an unopened detail is a no-op. **Behavior check fails:** XCUITest taps the button, asserts the next view is Detail, asserts the state property changed — none of these hold.

- **Cosmetically-correct, structurally-wrong modal.** An action sheet renders on iOS at the correct moment with the correct title and buttons. Presence: pass. The dismiss button is positioned in the lower-left because the SwiftUI modifier order in the bridge places `.padding()` before `.frame(maxWidth: .infinity)` instead of after, so the button hugs leading instead of centering. Behavior: pass — tapping the button dismisses the sheet. **Conformance check fails:** the rendered button's bounding box centerX is not within ±4 px of the sheet's centerX.

- **Layout that fits but doesn't read.** A web demo at 320 px viewport has every element technically inside the viewport. Presence: every element is in the DOM. Conformance, naively: no horizontal scrollbar. **Real conformance fails:** the headline's `clamp(2rem, 6vw, 4rem)` was authored with the wrong ideal value, so at 320 px the headline computes to 1.92 rem and visually collapses; the same headline at 1280 px computes to 4 rem; the type ramp does not preserve scale ratio across breakpoints. The check that catches this measures `font-size` on the rendered element at each breakpoint and compares against the token scale.

- **Cascade that doesn't cascade.** A brand override changes the Crystal-side `brand_primary` to coral. The web generator emits an updated `--ap-color-brand-primary` custom property. Presence: pass — the variable is set. **Behavior fails:** the rendered Button still draws teal because the Button widget's renderer visitor hard-codes a Color literal instead of reading `var(--ap-color-brand-primary)`. A presence check on the variable would never have surfaced this.

- **Accessibility tree out of sync with the visual layer.** A custom Crystal widget renders the correct visible label. Presence and conformance on the visible label pass. **Behavior fails for accessibility:** VoiceOver focus order steps right past the widget because the bridge forgot to set `isAccessibilityElement = true` on the UIView, and the widget contributes nothing to the AX tree. The check that catches this is "drive the AX tree, not the visible tree."

- **Compile-time gate that does not gate.** Phase 4 introduces a compile-time error when `UI::ActionSheet` is used outside an `{% if flag?(:ios) || flag?(:macos) %}` block. The macro is declared. Presence: pass. **Behavior fails:** the macro pattern-matches on the wrong AST node and never raises. The check that catches this writes a temp Crystal file using `UI::ActionSheet` from a non-Apple target, runs `crystal build --no-codegen` against it, and asserts the build fails with the expected error text.

### When to apply each bar

The table below maps common claim types to the bar required. Phase rubrics may add stricter bars, but they may not relax these defaults.

| Claim type | Required bar |
|---|---|
| Static design token value, Crystal constant, or generated CSS variable exists with the right name. | Presence. |
| Generated CSS file contains the expected `@layer`, `@media`, or `@container` rule. | Presence + textual contents check. |
| Renderer-emitted CSS with computed sizing (`clamp()`, `min()`, container queries, `dvh`/`svh`). | Conformance — measure rendered sizes at the breakpoints the rule targets. |
| Token value cascades into a rendered widget. | Behavior — modify the token, rebuild the demo or re-render, confirm the rendered widget reflects the change. |
| Interactive widget (button, toggle, picker, slider, segmented control, switch). | Behavior + conformance. Hit-target measured ≥ 44×44 on touch platforms; tap fires the bound action; bound state reflects in the next render. |
| Modal-like widget (action sheet, popover, sheet, confirmation dialog, context menu). | Behavior — every documented dismiss path; focus returns to trigger; element leaves accessibility tree on dismiss. Conformance — position and inset match spec at the declared viewport sizes. |
| Navigation flow (sign-in → dashboard, tab switching, push/pop, present/dismiss). | Behavior — end-to-end through every documented step; back affordance restores prior state. |
| Accessibility — focus order, ARIA roles, labels, keyboard traversal. | Behavior + conformance. Tab through the rendered output; assert the order observed equals the order expected. Query the AX tree, not the DOM. |
| Accessibility — contrast. | Conformance — sample rendered pixels for foreground and background, compute WCAG contrast ratio against AA threshold (4.5:1 normal text, 3:1 large text). |
| Visual regression baseline. | Conformance with explicit pixel/ΔE tolerance stated in the check. |
| Layout reflow at viewport sizes. | Conformance — capture at each declared viewport, measure rendered element bounding boxes, confirm no overflow and no zero-sized interactive elements. |
| Cross-platform brand parity ("looks like the same product"). | Conformance — capture matched-state screenshots on each platform, sample primary color at known coordinates, assert Lab distance is within the documented threshold. |
| Compile-time error on misuse of a gated widget. | Behavior — write a non-compiling fixture file, run `crystal build --no-codegen` against it, assert non-zero exit and assert error text contains the documented marker. |
| Crystal spec exists and passes for a new public method. | Presence (file exists) + behavior (spec passes when executed against the actual implementation). |

### How to phrase a check so the bar is unambiguous

When a phase rubric introduces a new check, prefer this structure:

1. **Claim.** One sentence stating what is being verified.
2. **Bar.** Presence, behavior, or conformance. Stated explicitly.
3. **Procedure.** Exact commands or tool calls, including which simulator device, which viewport, which color scheme, which token value to perturb.
4. **Pass criterion.** A boolean predicate over captured evidence. "Bounding box width ≥ 44 px and height ≥ 44 px on the iPhone 17 Pro simulator in portrait."
5. **Evidence artifact.** What file or capture is recorded under `handoff/phase-{NN}-evidence-{YYYY-MM-DD}/` to make the result auditable months later.

A check that conflates these — "verify the button looks right" — fails the rubric independently of whether the button is right, because no later validator can reproduce the call. If you encounter such a check while validating, mark it `passed: false` with a note identifying the missing dimension; do not freelance a behavior probe that the rubric did not authorize.

### Implication for validator workload

The behavior and conformance bars are more expensive than presence. Phases that wire Crystal-side declarations to native or web runtimes (Phases 3, 4, 5, 6) will produce validation runs that need a booted iOS simulator, a launched macOS sample app, and a Chrome session against the rendered web demo. Budget accordingly; do not collapse a behavior check into a presence check because the simulator is slow to boot. If the environment genuinely cannot run a check, mark it `blocked: true` with the specific environmental gap (e.g., "iOS 26.2 simulator not installed on this host") and let the team lead reassign or unblock. A blocked check that should have been runnable is more recoverable than a falsely-passed presence check.

---

## Running checks

For each check in the phase's `validation.md`, the validator must:

1. **Read the check's full description** in `validation.md`. Each check states what to verify and how to verify it.
2. **Run the check.** Use the tools available (Bash for tests/builds/scripts, Read for file inspection, the CDP-via-Crystal harness in `scripts/capture_amber_demo_screenshots.cr` and its siblings for visual verification if relevant — see `rubric/behavior-simulation-toolkit.md` §3).
3. **Capture evidence.** Output, screenshots, file diffs, command logs — whatever the check calls for. Store under `handoff/phase-{NN}-evidence-{YYYY-MM-DD}/`.
4. **Decide pass/fail.** Use the criteria in the check itself. If criteria are ambiguous, mark `passed: false` with a note explaining the ambiguity — the team lead will adjudicate.
5. **Record the result** in `GATE_REPORT.json`.

---

## Evidence directory layout

For each validation run, create:

```
handoff/phase-{NN}-evidence-{YYYY-MM-DD}/
  README.md                    # one-paragraph orientation
  test_output/
    {check_id}.log             # captured stdout/stderr
  screenshots/
    {check_id}-{platform}-{viewport}-{scheme}.png
  audits/
    {check_id}-axe.json
    {check_id}-ibm-equal-access.json
  inspections/
    {check_id}-{file}.diff     # if comparing file contents
```

File naming must be consistent across phases so anyone reviewing months later can find what they need.

---

## Temporary edits for verification

Some checks require temporarily modifying code or config to verify behavior. Examples:

- Changing a theme value to verify it cascades to all renderers.
- Resizing a window to verify a layout reflow.
- Setting a feature flag to confirm a fallback path.

When this happens:

1. Make the change.
2. Run the check and capture evidence.
3. **Revert the change.**
4. In the check's `notes` field, document the change made, the evidence captured, and confirmation of revert.
5. Verify the working tree is clean (`git status --short`) before returning.

The validator must never commit a temporary change. If a check requires a code change that you can't cleanly revert, mark the check `blocked: true` and explain.

---

## GATE_REPORT format

The final output is a single JSON document. Schema: `rubric/gate_report_schema.md`. Summary:

```json
{
  "phase": 1,
  "phase_name": "Design Token Foundation",
  "validator_run_date": "2026-05-21",
  "implementer_commits": ["abc123", "def456"],
  "verdict": "PASS",
  "checks": [
    {
      "check_id": "tokens.types-defined",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["test_output/tokens.types-defined.log"],
      "notes": "All five token categories (color, spacing, type, radius, motion) defined as Crystal types with frozen instances."
    },
    {
      "check_id": "tokens.cascade-to-web",
      "required": true,
      "passed": false,
      "blocked": false,
      "evidence": ["screenshots/tokens.cascade-to-web-before.png", "screenshots/tokens.cascade-to-web-after.png"],
      "notes": "Changed brand_primary from #7c9a92 to #ff0000 in test theme. CSS custom property --ap-color-brand-primary updated correctly. But button background did not change — the button widget hard-codes its background_color attribute and does not read from the token system. See spec output for failing test."
    }
  ],
  "summary": "11 of 12 required checks pass. One failure in token cascade to web renderer for Button widget. No optional checks attempted in this run."
}
```

**Rules:**

- `verdict` is `PASS` if and only if every `required: true` check has `passed: true`. Optional checks may fail without changing the verdict.
- `verdict` is `FAIL` if any required check has `passed: false`.
- `blocked: true` is treated as a failure for verdict purposes, but the team lead may decide to unblock the environment and re-run rather than send back to implementer.
- Every check's `evidence` field lists paths relative to the evidence directory.
- `notes` is mandatory for every check. For passing required checks, a one-line confirmation is fine. For failures, describe what you saw, what was expected, and where the discrepancy is.

---

## Running common check types

### Behavior-simulation toolkit

Every behavior or conformance check in this initiative — modal dismiss paths, button-tap-fires-handler probes, focus-trap traversal, slider drag callbacks, runtime-override re-render, navigation flows, geometry measurements at multiple viewports — drives the rendered UI through one of three idioms: `UI::AXTest` + the Carbon Accessibility API on macOS, XCUITest on iOS, or headless Chrome driven directly via CDP over WebSocket from Crystal on web (canonical implementation: `scripts/capture_amber_demo_screenshots.cr`). The actual API surface for each (which actions are wired today, which Carbon constants to invoke for unwired actions, how to assert focus restoration, how to drive a Tab cycle through a focus-trap, how to sample rendered geometry per platform) is documented in `rubric/behavior-simulation-toolkit.md`. Validators read that file once before their first behavior check; phase rubrics reference it from their pre-reading checklists. If a check appears to require an action the toolkit cannot express, mark the check `blocked: true` with a reference to the missing capability rather than freelancing a workaround — the toolkit's section 6 enumerates known gaps for follow-up framework work.

### Crystal specs

```
cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline
crystal spec spec/path/to/relevant_spec.cr 2>&1 | tee handoff/phase-XX-evidence-DATE/test_output/check-id.log
```

Pass = `0 errors, 0 failures, 0 pending`. Pending tests are not failures but should be noted.

### Build verification

```
crystal build --no-codegen src/asset_pipeline.cr           # default web
crystal build samples/cross_platform/macos_host/hig_showcase.cr -Dmacos --no-codegen
# similar for ios, android
```

Capture full output. Any warning involving the phase's new code is worth noting.

### Web screenshot capture

Drive Chrome via the Chrome DevTools Protocol (CDP) from Crystal — extend `scripts/capture_amber_demo_screenshots.cr` or its `DevTools` wrapper per `rubric/behavior-simulation-toolkit.md` §3. Standard viewport set: `1280×800` desktop, `768×1024` tablet, `375×667` mobile, `320×568` mobile-min (set via `Emulation.setDeviceMetricsOverride`). Standard color schemes: light, dark (via `Emulation.setEmulatedMedia` `prefers-color-scheme`). Standard motion: full, reduced (via `Emulation.setEmulatedMedia` `prefers-reduced-motion`).

For checks that require a specific demo page, the phase's `validation.md` will list the URL or output file.

### Accessibility audit (web)

```
crystal run scripts/axe_web_demo_audit.cr          # axe-core
crystal run scripts/ibm_web_demo_audit.cr          # IBM Equal Access
```

(Or whatever scripts the phase introduces.) Capture both JSON reports.

### Native screenshot capture

For macOS sample builds, the existing visual regression harness in `samples/cross_platform/macos_host/` produces PNGs. Run the build, capture, copy relevant images into the evidence directory.

For iOS, `xcrun simctl io booted screenshot {path}.png` while the sample app is in the relevant state.

---

## Independence rules

The validator must remain cold-eyed:

- **Do not read the implementer's commit messages before reading the rubric.** Form expectations from the rubric, then verify them.
- **Do not assume "it probably works" because the implementer's handoff says it does.** Run the check.
- **Do not consult previous gate reports for this phase.** A previous validator's call doesn't constrain yours.
- **If a check is ambiguous, fail closed.** Mark `passed: false` and let the team lead adjudicate. False positives erode trust faster than false negatives.

---

## Returning the report

Return a single message to the team lead with the structure specified in `trust_pair_protocol.md`. Include:

- `## Verdict` line (PASS or FAIL)
- `## GATE_REPORT` block containing the full JSON
- `## Summary` paragraph (2–4 sentences)

Do not narrate the run inline. The evidence files are the narrative; the report is the index.
