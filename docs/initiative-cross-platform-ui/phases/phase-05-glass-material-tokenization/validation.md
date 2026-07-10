
# Phase 5 — Validation Rubric: Glass Material Tokenization

**Audience:** Validator agent (single execution, cold-eyed).
**Read also:** `README.md` (this folder), `../../rubric/validation_criteria.md`, `../../rubric/gate_report_schema.md`. Do **not** read `implementation.md` before forming expectations from the README — your job is to verify the README's acceptance summary, not to be talked into the implementer's interpretation of it.

---

## Validator scope reminder

You **read, run, inspect, and record**. You do **not** modify committed code (temporary edits for verification only — revert before returning). For each numbered check below: capture evidence under `handoff/phase-05-evidence-{YYYY-MM-DD}/`, decide pass/fail using the check's own criteria, and record the result in `GATE_REPORT.json`. Every check must appear in your report — none may be skipped.

---

## Pre-reading checklist

- [ ] `README.md` (this folder)
- [ ] `../../rubric/validation_criteria.md`
- [ ] `../../rubric/gate_report_schema.md`
- [ ] The implementer's commit list (subject lines only; **do not** read commit bodies until you have formed your expectations).
- [ ] `src/ui/views/glass_background.cr` (one screen — confirms the public API hasn't moved).
- [ ] The four renderer files referenced by line range in the README's "Why this phase exists" section, **after** you've run the inspection-based checks for each.

---

## Check list

Checks are numbered 1–8 (each phase's validation rubric numbers its own checks from 1; cross-phase consolidation is the team lead's job, not the validator's). All checks below are scoped to Phase 5 evidence only.

---

### Check 1 — `glass.ios-default-intensity-renders`
**Required:** Yes.
**What:** `GlassBackground` at default intensity (`tokens.material.intensity == 1.0`) on iOS renders the platform-correct surface. On iOS 26+, Liquid Glass appears automatically (system Material). On iOS 15–25, regular blur via system Material. No fallback flat fill.
**How:**
1. Build and run `samples/cross_platform/glass_intensity_demo.cr` on an iOS simulator booted to the highest available iOS version (capture the version: `xcrun simctl list runtimes`).
2. Capture screenshot at the default intensity (no `--` argument): `xcrun simctl io booted screenshot screenshots/check-1-ios-default.png`.
3. Visually compare to the SwiftUI reference snapshot in `swift/AssetPipelineSwiftKit/Tests/Reference/glass_regular_default.png`. Differences in tile noise are expected; differences in apparent blur radius, opacity, or tint hue are failures.
**Pass:** Five visible glass tiers (ultra_thin → chrome) with a monotonically increasing frosted look. iOS 26+ Liquid Glass present (chromatic edge, dynamic specular highlight on motion). No flat-fill regression.
**Evidence:** `screenshots/check-1-ios-default.png`, `screenshots/check-1-ios-reference.png` (the reference snapshot).

---

### Check 2 — `glass.macos-default-intensity-renders`
**Required:** Yes.
**What:** `GlassBackground` at default intensity on macOS renders the platform-correct surface (`NSVisualEffectView` material backed; on macOS 26+, Liquid Glass appears automatically via SwiftUI `Material`).
**How:**
1. Build and run the macOS sample via `samples/cross_platform/macos_host/` after the host harness is rebuilt with Phase 5 changes.
2. Drive it to the glass intensity demo screen.
3. Capture via the existing visual regression harness (already produces PNGs into `samples/cross_platform/macos_host/baselines/`).
4. Compare to the reference image under `swift/AssetPipelineSwiftKit/Tests/Reference/glass_regular_default_macos.png`.
**Pass:** Five tiers visible with the expected blur progression. The macOS material translation (UIKit constant → AppKit constant) produces a `regular`-tier result that looks like `NSVisualEffectMaterial.windowBackground`, not like `light` or `medium`.
**Evidence:** `screenshots/check-2-macos-default.png`, `screenshots/check-2-macos-reference.png`.

---

### Check 3 — `glass.web-default-intensity-renders-with-supports-fallback`
**Required:** Yes.
**What:** On web at default intensity, a `GlassBackground.new(material: :regular)` produces:
1. An inline `backdrop-filter: blur(var(--ap-material-blur-regular)) saturate(var(--ap-material-saturation-regular))` declaration.
2. A `-webkit-backdrop-filter:` fallback in the same declaration.
3. A `color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-regular) * 100%), transparent)` background.
4. A `@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px)))` block in the stylesheet root with five `.ap-glass--{step}` rules.
**How:**
1. Render `samples/cross_platform/glass_intensity_demo.cr` to HTML via the existing web pipeline.
2. Grep the output: `grep -n 'backdrop-filter\|@supports\|ap-material-blur' samples/cross_platform/dist/glass_intensity_demo.html samples/cross_platform/dist/styles.css`.
3. Open the rendered page in a modern Chromium via the browser MCP; capture a screenshot showing visible blur on the demo tiles.
4. To verify the `@supports` fallback path: temporarily override the support check in DevTools by adding a CSS rule that forces `.ap-glass--regular` to ignore `backdrop-filter` (set `backdrop-filter: none !important` in an inline `<style>` injected via the MCP). Confirm the panel does **not** become invisible — it must show the higher-opacity fallback fill. Capture this screenshot too. Revert the override before moving on.
**Pass:** All four substrings above appear in the source. Live rendering shows blur. Forced-fallback rendering shows the documented higher-opacity solid panel (94% opacity for `regular`). Both screenshots clearly distinguishable.
**Evidence:** `inspections/check-3-html-grep.txt`, `screenshots/check-3-web-live.png`, `screenshots/check-3-web-fallback.png`.

---

### Check 4 — `glass.android-default-intensity-renderseffect-or-fallback`
**Required:** Yes.
**What:** On Android API 31+, `GlassBackground` produces a real `RenderEffect.createBlurEffect`-backed view. On API ≤30, it produces the documented semi-transparent fallback fill. Both paths invoke the `AssetPipelineGlassHelper.applyGlass` static method.
**How:**
1. Build the Android sample. Confirm `AssetPipelineGlassHelper.java` exists at the expected path.
2. Boot an Android emulator with API 33 (or higher). Install the sample. Drive to the glass intensity demo. Capture via `adb exec-out screencap -p > screenshots/check-4-android-api33.png`.
3. Repeat with an API 29 emulator. Capture: `screenshots/check-4-android-api29.png`.
4. Inspect the Android visit method in `src/ui/renderers/android_renderer.cr` — confirm it calls the helper, does not call `setBackgroundColor` directly.
**Pass:** API 33 capture shows a visibly blurred panel. API 29 capture shows the documented semi-transparent fill (no blur, but readable panel separation). The renderer file no longer contains the `0x33FFFFFF / 0x66FFFFFF / 0x99FFFFFF / 0xBBFFFFFF / 0xDDFFFFFF` literal switch — those values now derive from `tokens.material.resolve(...).opacity` and `tokens.colors.surface_panel`.
**Evidence:** `screenshots/check-4-android-api33.png`, `screenshots/check-4-android-api29.png`, `inspections/check-4-android-renderer-source.txt`.

---

### Check 5 — `glass.intensity-1.5-increases-blur-all-platforms`
**Required:** Yes.
**What:** Setting `material.intensity = 1.5` produces visibly more frosted glass on all four platforms.
**How:**
1. Run the demo with `1.5` on each platform (per the build commands in `samples/cross_platform/glass_intensity_demo.cr`'s header comment).
2. Capture screenshots: `check-5-{ios,macos,web,android}-intensity-1.5.png`.
3. Diff each against the default-intensity capture from checks 1–4 using `compare` (ImageMagick) or equivalent. Report the per-pixel difference percentage.
4. Visual gut check: on the `regular` tier in particular, the 1.5 capture should be perceptibly more frosted than the 1.0 capture — text behind the panel should be more obscured.
**Pass:** All four platforms show a measurable per-pixel difference (>5% changed pixels on the `regular` tier alone) and the visual gut check passes on each.
**Evidence:** Four `screenshots/check-5-*-intensity-1.5.png` files. `inspections/check-5-diff-summary.txt` reporting the per-platform pixel diff percentages.

---

### Check 6 — `glass.intensity-0.5-decreases-blur-all-platforms`
**Required:** Yes.
**What:** Setting `material.intensity = 0.5` produces visibly less frosted glass on all four platforms.
**How:** Same procedure as check 5, but with `0.5`.
**Pass:** All four platforms show measurable difference *in the opposite direction*. On the `regular` tier, text behind the panel should be more readable at 0.5 than at 1.0. iOS 26+ Liquid Glass should still appear (the `.background(material)` base is unchanged; only the additive `.blur(_:)` modifier delta has flipped sign — verify the SwiftUI bridge handles negative deltas gracefully or clamps the additive blur to zero).
**Evidence:** Four `screenshots/check-6-*-intensity-0.5.png` files. `inspections/check-6-diff-summary.txt`.
**Note for validator:** The Swift bridge's "delta blur" approach (additive `.blur()` on top of `Material`) means intensity < 1.0 needs a *negative* delta — but SwiftUI's `.blur(radius:)` clamps negative values to zero, which means iOS *cannot make blur lower than the system material's baseline*. This is an Apple-API limitation, not an implementer failure. Confirm with the implementer's handoff whether they documented this and whether the visual difference at 0.5 is therefore smaller on iOS than on web/Android. If the visual difference on iOS at 0.5 is essentially zero, that is acceptable per the limitation but must be acknowledged; the other three platforms still need a clear visible difference.

---

### Check 7 — `glass.no-nested-double-blur`
**Required:** Yes.
**What:** Two `GlassBackground` views nested (one inside the other) do not double-apply the blur effect on web. The inner glass must inherit the parent's already-blurred backdrop rather than re-blurring it.
**How:**
1. Write a small ad-hoc demo: a `GlassBackground(material: :regular)` containing a `GlassBackground(material: :thin)` containing text.
2. Render to web. Inspect the resulting HTML/CSS: the inner `.ap-glass--thin` should still emit its own `backdrop-filter`, but the validator should confirm that the *visual* result is not a doubly-frosted panel (i.e., the text behind the *outer* panel is blurred once, the inner panel adds its own slight tint but does not stack a second `blur(20px)` on top of the already-blurred backdrop).
3. Capture the web screenshot.
4. Capture the iOS screenshot of the same nested arrangement.
**Pass:** Visual inspection confirms the nested case looks like two stacked panels, not a triple-frosted opaque blob. The README's risk note explicitly calls this out as a concern; the validator confirms the implementation hasn't regressed here.
**Evidence:** `screenshots/check-7-web-nested.png`, `screenshots/check-7-ios-nested.png`. Free-text observation in `notes`.

---

### Check 8 — `inspection.no-hard-coded-blur-or-material-constants`
**Required:** Yes.
**What:** Three renderer files no longer hard-code blur amounts or material constants for glass surfaces:
- `web_renderer.cr` — no `blur(10px)`, `blur(20px)`, `blur(30px)`, `blur(40px)`, `blur(50px)`, no `72%` opacity literal in the glass visit method.
- `uikit_renderer.cr` — `visit(view : UI::GlassBackground)` does not contain a `case view.material when :ultra_thin then 8_i64` switch (or equivalent); the integer comes from the resolved token.
- `appkit_renderer.cr` — same as uikit, with **one documented exception**: the UIKit→AppKit translation table. That block is the only acceptable hard-coded glass switch in the entire codebase post-Phase 5 and **must be wrapped with the exact marker comment** `# AppKit material translation table — only allowed hard-coded glass switch` immediately above it (see `implementation.md` §"Mandatory marker comment").
- `android_renderer.cr` — no `0x33FFFFFF / 0x66FFFFFF / 0x99FFFFFF / 0xBBFFFFFF / 0xDDFFFFFF` literals in the glass visit method.
**How:**
1. `grep -n 'blur(10px\|blur(20px\|blur(30px\|blur(40px\|blur(50px\|72%' src/ui/renderers/web_renderer.cr`
2. `grep -nB1 'when :ultra_thin\|when :thin\|when :regular\|when :thick\|when :chrome' src/ui/renderers/uikit_renderer.cr src/ui/renderers/appkit_renderer.cr` and inspect every hit. **The only acceptable hits are inside the AppKit translation table**, identified by the marker comment on the line immediately above the case/switch block. The marker text must be exactly `# AppKit material translation table — only allowed hard-coded glass switch` (em dash `—`, not `--`). Any hit not preceded by this marker (within 1 line of context) is a fail.
3. Confirm the marker is present and unique: `grep -nE '# AppKit material translation table — only allowed hard-coded glass switch' src/ui/renderers/appkit_renderer.cr` must return exactly one match in `appkit_renderer.cr` and zero matches in any other source file.
4. `grep -n '0x33FFFFFF\|0x66FFFFFF\|0x99FFFFFF\|0xBBFFFFFF\|0xDDFFFFFF' src/ui/renderers/android_renderer.cr` — expect zero hits.
5. **Deviation check:** also grep for `setMaterial:` in `appkit_renderer.cr` and `effectWithStyle:` in `uikit_renderer.cr`. Every remaining hit must either (a) come from a visit method that delegates to a token resolution, or (b) be one of the visit methods that the implementer explicitly disclosed in their handoff as out-of-scope per the deviation prompt, or (c) sit inside the marker-comment-wrapped translation table. Any undisclosed hard-coded `setMaterial:` integer is a fail.
6. **CSS prefix check (D9):** confirm no `--amber-*` custom properties appear in any Phase 5 emission. `grep -rnE 'var\(--amber-' src/ui/design_tokens/ src/ui/renderers/web_renderer.cr src/ui/design_tokens/generators/` must return zero matches. The canonical prefix is `--ap-*`; the `--amber-*` aliases have been removed across the initiative.
**Pass:** All grep results are clean (or, for the AppKit translation table, are limited to the marker-comment-wrapped block and the marker is present exactly once in `appkit_renderer.cr`). The CSS prefix grep returns zero `--amber-*` hits. Every `setMaterial:` / `effectWithStyle:` call traces back to a token resolution, is disclosed as deferred, or sits inside the marked translation table.
**Evidence:** `inspections/check-8-grep-results.txt` containing the full grep output, the marker-comment match, and the validator's annotation of each remaining hit.

---

## Spec suite

Before computing the verdict, run the full Crystal spec suite:

```
cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline
crystal spec 2>&1 | tee handoff/phase-05-evidence-DATE/test_output/spec-suite.log
```

Pass = `0 errors, 0 failures, 0 pending` (pending tests are noted, not failed).

Specifically confirm that the new specs introduced by Phase 5 are among the runs:
- `spec/ui/design_tokens/material_spec.cr`
- `spec/ui/design_tokens/web_generator_material_spec.cr`
- `spec/ui/renderers/web_glass_spec.cr`
- `spec/ui/renderers/uikit_glass_spec.cr`
- `spec/ui/renderers/appkit_glass_spec.cr`
- `spec/ui/renderers/android_glass_spec.cr`

If any of these spec files are missing, mark the relevant check `blocked: true` with a note that the test surface is incomplete.

Spec suite results count as part of the verdict — if the suite is red, the phase fails regardless of the eight numbered checks. Capture in `notes` against check 8 (or add an 8a sub-bullet) and reflect in the report `summary`.

---

## Build verification

Run each sample build at `--no-codegen`:

```
crystal build --no-codegen src/asset_pipeline.cr
crystal build --no-codegen samples/cross_platform/macos_host/hig_showcase.cr -Dmacos
crystal build --no-codegen samples/cross_platform/ios_host/build_target.cr -Dios
crystal build --no-codegen samples/cross_platform/android_host/build_target.cr -Dandroid
```

(Substitute actual sample file names if the brief has them differ. The Phase 1 / Phase 3 samples and build scripts are the authority.)

Pass = each command returns exit 0 with no warnings involving any file modified in Phase 5. Capture in `test_output/build-{platform}.log`.

---

## Verdict computation

PASS if and only if:
- All eight numbered checks (1–8) marked `required: true` have `passed: true`.
- Spec suite returns clean.
- All four sample builds return exit 0.

Otherwise FAIL. If any check is `blocked: true` (e.g., simulator unavailable, JNI bridge not present in sandbox), that counts as a failure for verdict purposes; the team lead may choose to unblock and re-run rather than ship back to the implementer.

---

## Report structure

Return a single GATE_REPORT.json under `handoff/phase-05-evidence-{YYYY-MM-DD}/GATE_REPORT.json` with:
- `phase: 5`, `phase_name: "Glass Material Tokenization"`.
- `checks` array in numerical order (1, 2, 3, 4, 5, 6, 7, 8).
- `notes` populated for every check — one line for passes, multi-line for failures with what-was-expected / what-was-seen / where-the-gap-is.
- `summary` paragraph: 2–4 sentences citing the verdict, the number of checks passed, and the most important finding (or "no significant findings" if everything passes cleanly).

Final assistant message to the team lead follows the `trust_pair_protocol.md` format: `## Verdict`, `## GATE_REPORT`, `## Summary`. Do not narrate the run inline — the evidence files are the narrative.
