# Planning retrospective — 2026-05-22 (revision 6, post 5 individual Codex rounds + 1 holistic round)

## Premise

Workarounds in this codebase are evidence that the plan didn't predict reality. This document catalogs them, traces each to a planning failure, names the underlying cognitive failure, and produces a **forward artifact** — a phase brief template with invariant matrix, executable proof commands, and a pre-dispatch validation script — that is concrete enough that "invariant-driven planning" cannot remain rhetoric.

This is **revision 6** (5 individual Codex rounds + 1 cross-document holistic round). Codex (acting as productive antagonist) found substantive gaps each round. R1 missed 5 workarounds outright + framed lessons as platitudes. R2 added missing workarounds + invariant grid but mis-attributed mapping, left "executable tests" as checklists, lacked a concrete forcing artifact. R3 added the 10th invariant, fixed attribution, replaced checklists with actual commands, and produced the Phase Brief Template. R4 caught the validator was facade-grade (not enforcing schema; null-op probes passing; required sections downgraded to warnings; Phase 6.5 not operationally locked); fixes added null-op rejection + path-existence checks + required-section enforcement + Phase 6.5 ledger row + folder + Phase 6/7 README updates. R5 caught schema-validator drift (validator wasn't a true superset); fixed with phase additionalProperties + min lengths + date/SHA formats + repo_derived_facts captured_at_sha enforcement + adapter_cardinality field checks. R6 (holistic) caught principle mislabeling + master plan playbook bypass + Phase 7 contract still describing old work + memory entries lower-resolution; fixes integrated above.

---

## The workarounds, honestly (8 with 2 splits)

### Workaround #0 — the bridge shipped as a static renderer (Phase 3 R4 + R10)

**What we did:** R4 added `APSKLabelState` / `APSKButtonState` / `BoolStorage` / `DoubleStorage` ObservableObjects, `@_cdecl` mutators, `LibSwiftKitBridge` typed funs, `NativeHandle#state_handle`, Crystal-side setter methods on `UI::Label` / `UI::Button` / `UI::Toggle` / `UI::Slider`. R10 added the symmetric **SwiftUI → Crystal** path (UIKit `UISwitch` wrapper) + the full reactive Sheet bridge.

**Root cause:** the Phase 3 README framed facades as "wrap SwiftUI view, expose `.view`" with no state topology. Acceptance criteria were visual / build / spec, not round-trip state.

**Owner intervention required twice.** Once for forward render, once for backward event. Quoted in `feedback_reactivity_is_table_stakes.md`.

**Cost:** ~20% of total Phase 3 commits + multiple validator iterations + the bulk of owner planning frustration.

**Invariant violated (per the I-1…I-11 grid below):** I-2 (state forward), I-3 (event backward). Both absent from brief.

**Planning failure shape:** **noun-driven scope.** Brief named widgets, not invariants.

### Workaround #1 — Crystal `__crystal_main` embedding gap (Phase 3 R8/R9, ongoing)

**What we did:** explicit `.reset()` on 6 probe singletons in `hig_bridge.cr#initialize_runtime`. Replaced `sprintf("%.2f", Float64)` with integer-arithmetic decimal formatter in `SliderProbe::formatted`.

**These are two symptoms of one missing embedding contract.** Same root cause (`ld -r -unexported_symbol _main` skip → `__crystal_main` never runs → class-var initializers + `Crystal::once` lazy lookups never fire) also affects STDERR, `Float::Printer::Dragonbox`, and **any downstream consumer's class vars**. Probe singletons fixed (6 explicit `.reset()`). Float formatting fixed (1 widget). Everything else is **latent**.

**Invariant violated:** I-9 (survive embedding). PLUS the per-platform proof should have included "Crystal class-var initializers fire under our embedding" — never tested before Phase 3 shipped.

**Planning failure shape:** **black-box-correct assumption about a lower runtime layer** + **partial workaround sufficient for visible tests accepted as resolution**.

### Workaround #2 — OpenSSL / zlib transitive require on iOS (Phase 3 R5 → R6)

**What we did:** `{% unless flag?(:ios) || flag?(:android) %}` guards around `reactive_component` require chain in `src/components.cr:62` + `chat_component` / `live_search_component` / `integration`.

**Root cause:** `samples/cross_platform/ios_host/hig_bridge.cr` → `src/ui` → `src/ui/renderers/web_renderer` → `src/components` → `src/components/reactive/reactive_handler.cr` (`require "openssl"`, `require "http/server"`). iOS linker demanded OpenSSL + zlib symbols → 9 undefined symbols. R5 blocker doc: *"This was masked since Remediation 3 because no one could actually `xcodebuild build` until iOS 26.5 landed."*

**Invariant violated:** I-11 (target build / link / load closure — the iOS target's transitive require closure pulled symbols the target couldn't provide). Per Round 3's correction, this is I-11 territory, not I-10 (API contract fidelity).

**Planning failure shape:** **no target-link-closure audit.** Critically, `crystal build --no-codegen -Dios` would not have caught this either — it doesn't prove link closure. Real proof requires either (a) full build to bin/ on each target, OR (b) symbol-closure check via `nm`/`otool` on intermediate `.o` files.

### Workaround #3 — Sheet reactive bridge + lifecycle setter (Phase 3 R10)

**What we did:** added full reactive bridge from `UI::Sheet#is_presented` through `APSKSheetFacade.makeReactive` into SwiftUI's `.sheet(isPresented:)`. Added explicit-flag `on_dismiss` guard semantics. `is_presented=` setter in `src/ui/views/sheet.cr:11`. Slug rewrite + test rewrite.

**Not "just" reactivity — lifecycle topology + dismissal-source disambiguation.** Sheets have presentation lifecycle AND dismissal-source semantics (primary tap / cancel tap / swipe-down / [excluded backdrop]) that the original Crystal `UI::Sheet` API didn't model.

**Invariant violated:** I-5 (lifecycle) + I-3 (event semantics — the dismissal-source must reach the host with semantics intact).

**Planning failure shape:** **noun-driven scope** (Sheet listed as a widget; its lifecycle + dismissal-source semantics not listed as invariants).

### Workaround #4 — SwiftUI AX semantics for value-bound controls (Phase 3 R7 + R10)

**What we did:** R7 removed Crystal-side `accessibility_label` on probe mirror labels. R10 swapped iOS Toggle facade from `UIHostingController-in-UIViewRepresentable` to `UIViewRepresentable + UISwitch` because `XCUIElement.tap()` synthesizes via accessibility-activate and SwiftUI value-bound controls don't route AX-activate to their internal binding.

**Two related workarounds with the same root.** Override grid + hosting pattern both treated SwiftUI as transparent rendering. SwiftUI's AX model is opinionated; value-bound controls have specific routing requirements.

**Invariant violated:** I-6 (accessibility) — propagation through the hosting layer was never modeled per-target.

**Planning failure shape:** **no per-platform behavior model for the override surface.** PLUS the UIHostingController choice was made without auditing XCUITest tap synthesis routing.

### Workaround #5a — Web fallback HTML/ARIA contract never modeled (Phase 4 R2)

**What we did:** dropped `role="group"` from the `<ul role="group"><li>` action sheet markup.

**Root cause:** the fallback's expected accessible structure (role hierarchy, list semantics, dismiss roles, focus order) was never declared as a design artifact reviewed before any markup was emitted. axe-core was deferred to validation gate. `role="group"` on a `<ul>` is a textbook WAI-ARIA anti-pattern that any spec reading would have flagged upfront.

**Invariant violated:** I-6 (accessibility) + I-10 (API/fallback contract fidelity — the fallback's contract included accessibility but didn't audit it).

**Planning failure shape:** **HTML/ARIA contract not declared as a design artifact.**

### Workaround #5b — Action-text color token misassignment (Phase 4 R2)

**What we did:** swapped action color from `--ap-color-brand-accent` to `--ap-color-brand-primary` to meet WCAG-AA 4.5:1 contrast on `--ap-color-surface-sunken`.

**Root cause:** the `--ap-color-brand-accent` token is a chromatic brand color, NOT a foreground-text token. Using it for action text was a semantic-role mismatch. Phase 1's token system distinguishes chromatic brand tokens (e.g. accent) from semantic foreground tokens (e.g. text-primary, interactive-text). The web fallback CSS authored in Phase 4 picked the chromatic token without checking its semantic role contract.

**Distinct root cause from 5a.** 5a is HTML/ARIA. 5b is token-role semantics. They co-occurred at the same axe-core gate, but the underlying contracts violated are different.

**Invariant violated:** I-6 (accessibility — WCAG-AA contrast).

**Planning failure shape:** **token semantic-role contract not declared or enforced.** Token names alone don't communicate which tokens are safe for which uses; needs an explicit role contract (this token may be used as a foreground on these backgrounds with this contrast).

### Workaround #6 — Phase 4 brief required an incapable adapter (Phase 4 initial)

**What we did:** iOS `ActionSheet` routes through `ConfirmationDialogFacade` from Phase 3, degrading multi-action lists to "first non-cancel → confirm" + "cancel → cancel."

**Root cause (sharper than Round 2 version):** the Phase 4 implementation.md at line 44 REQUIRED routing iOS ActionSheet through the existing `ConfirmationDialogFacade`. The facade was authored in Phase 3 with binary confirm/cancel semantics. **The Phase 4 brief named an incapable adapter without proving its cardinality matched the public API it was binding.** Codex's framing: *"The plan selected an incapable adapter without proving the API cardinality matched."* This is a planning act, not just an implementation degradation.

**Invariant violated:** I-10 (API/fallback contract fidelity — public API claims arbitrary action list; iOS silently degrades to 2).

**Planning failure shape:** **adapter selection without cardinality proof.** Choosing an existing component as the target for a new API requires proving the component supports the API's full input space.

### Workaround #7 — `_gate_stubs/` macro stub + weakened compile-time contract (Phase 4 Commits 4-6)

**What we did:** split gated widgets' stub files into `_gate_stubs/` subdir excluded from `./views/*`. Nested `{% raise %}` inside `{% if/else %}` fires during outer expansion.

**Contract downgrade:** the intended contract was *"using `ContextMenu` on web is a compile error."* Actual contract is *"constructing `ContextMenu` on web is a compile error, but type-only references still compile."* `var x : ContextMenu?` on a non-Apple build doesn't get the error the rubric promised.

**Invariant violated:** I-10 (the contract delivered weaker than the contract promised).

**Planning failure shape:** **prototyping the gate pattern after fanning out** + **the downgrade is not in any published contract** (buried in a deviation doc).

### Workaround #8 — Stale facts in plan documents (cross-phase)

**What we did:** repeatedly. Phase 4 brief said `:darwin`; codebase used `:macos || :ios`. Brief said "75 widgets"; actual is 74-78 depending on phase. Brief dropped `PathControlWithWebFallback`; canonical required it.

**Planning failure shape:** **plan facts rot unless derived from repo queries at brief-authoring time.**

---

## The cognitive failure underneath

**Noun-driven planning.** Phase 3 brief said "build facades for widgets." A UI library has a known invariant set; scoping by widget list lets entire invariant categories be silently absent. Each absent category surfaced later as a workaround.

The retrospective's earlier framing ("scope what to understand") was true but incomplete. The deeper failure is naming the wrong unit of work. Widgets are the wrong unit. **Invariants are the unit.**

---

## The 11 UI-library invariants (corrected from Round 3)

Round 2 had 9 invariants; Round 3 noted Codex's call to add API/fallback contract fidelity (I-10). Round 3's Codex critique then said I-10 was over-broad — link-closure failures (Workaround #2 OpenSSL/zlib) and stale plan facts (Workaround #8) weren't really "API fidelity." Split into I-10 (API contract) + I-11 (target build / link / load closure). Plus explicit primary-ownership clauses on I-3 / I-7 / I-9 to lock boundaries.

| ID | Invariant | Definition + primary-ownership clause |
|----|-----------|------------|
| **I-1** | Render correctly | Visual output matches design intent on every target. Typography, spacing, color, motion. |
| **I-2** | Update reactively (forward) | Host-language state mutation triggers native re-render with the new value. **Primary owner of:** Crystal `view.text = "new"` → SwiftUI Text shows "new". Sheet `is_presented = true` → SwiftUI `.sheet(isPresented:)` opens. |
| **I-3** | Dispatch events (backward) | Native interaction (tap, drag, value change, swipe, gesture) propagates back to host with semantics intact: which control, what value, why. **Primary owner of:** observable event contract — including main-thread / run-loop delivery semantics, exactly-once invocation, source disambiguation. |
| **I-4** | Restore focus | Focus order survives lifecycle transitions (modal present/dismiss, navigation push/pop, sheet expand/collapse, window switch). Keyboard focus AND accessibility-focus on each platform's AX tree. |
| **I-5** | Manage lifecycle | Mount/unmount/teardown order is predictable; nested view lifecycles compose correctly. |
| **I-6** | Propagate accessibility | Every interactive element has correct label / role / value / state on each platform's AX tree. WCAG-AA contrast, ARIA correctness, AXIdentifier propagation, dynamic-type response. |
| **I-7** | Manage memory ownership | **Primary owner of:** lifetime / GC / leak safety. Values crossing language boundaries don't UAF; pointers stay valid; GC roots respected; callback registry doesn't leak. (NOT thread/run-loop semantics — that's I-3.) |
| **I-8** | Honor environment | Dynamic type, dark mode, high contrast, reduced motion, RTL, locale all work without per-widget overrides. |
| **I-9** | Survive embedding | **Primary owner of:** runtime initialization + run-loop embedding preconditions. Class-var init, lazy-static init, `Crystal::once`-protected lookup tables, stdlib state, main-thread / run-loop init requirements all honored under the chosen embedding. (NOT individual event delivery — that's I-3.) |
| **I-10** | API / fallback contract fidelity | The public API's declared semantics, arity, action ordering, compile-time error strength, and per-target degradation are explicitly documented AND verified per target. No silent degradation. No weaker compile-time contracts than promised. |
| **I-11** | Target build / link / load closure | Each platform target builds, links, and loads cleanly. The transitive include / require / dependency closure on the most-restricted target doesn't pull in symbols the target can't provide. Verified by **actual build to bin/** OR **`nm`/`otool` symbol-closure on intermediate `.o` files**, not by `crystal build --no-codegen` (which doesn't link). |

## Mapping (invariants ↔ workarounds — corrected from Round 3's mis-attribution)

Codex round 3 critique: my Round 2 table mixed "workarounds" with "coverage notes." Round 3 also identified that Sheet `is_presented` bridging is forward reactivity (I-2), not solely event/lifecycle, and that #2 (OpenSSL/zlib) is a link-closure failure (now I-11), not API contract (I-10). #8 (stale facts) isn't an invariant at all — it's pre-dispatch validation domain.

Workaround → invariant attributions (each workaround can touch multiple invariants):

| Workaround | Primary invariants violated |
|-----------|---------------------------|
| #0 SwiftUI bridge shipped static | I-2 (forward reactive), I-3 (backward events) |
| #1 Crystal `__crystal_main` embedding gap | I-9 (embedding) |
| #2 OpenSSL/zlib transitive require on iOS | I-11 (target build/link/load closure) |
| #3 Sheet reactive bridge + lifecycle setter | I-2 (forward `is_presented` mutation), I-3 (dismissal-source semantics), I-5 (presentation lifecycle) |
| #4 SwiftUI AX semantics for value-bound controls | I-3 (event routing through AX), I-6 (AX propagation) |
| #5a Web fallback HTML/ARIA contract never modeled | I-6 (accessibility — role semantics) |
| #5b Action-text color token misassignment | I-6 (accessibility — WCAG contrast) |
| #6 Phase 4 brief required an incapable adapter | I-10 (API/fallback contract fidelity) |
| #7 `_gate_stubs/` weakened compile-time contract | I-10 (compile-time error contract downgrade) |
| #8 Stale facts in plan documents | **Not an invariant.** Belongs to pre-dispatch validation domain — Section 3 of the Phase Brief Template below. |

Coverage notes (NOT workarounds — current state of invariant verification):

| Invariant | Coverage state |
|-----------|---------------|
| I-1 Render correctly | Verified on iOS/macOS/web via existing visual specs + CDP harness baselines. Android NOT verified. |
| I-4 Restore focus | Only Sheet covered via BX8. Navigation push/pop, TabView switch, Window minimize NOT covered on any platform. |
| I-7 Memory ownership | NULL string crash fixed in R8; broader UAF / lifetime probes still partial. ASan-built test runs not part of CI. |
| I-8 Environment | BX10 dark-mode tint shift on Button only. Dynamic type / high contrast / reduced motion / RTL / locale NOT verified on any platform. |
| I-11 Build closure | iOS + macOS + web verified post-Workaround #2. Android remains architect-precedent PASS without actual demonstration. |

6 of 11 invariants have surfaced workarounds (I-2, I-3, I-5, I-6, I-9, I-10, I-11). 3 more (I-4, I-7, I-8) have known partial coverage. Only I-1 has clean coverage (and only on 3 of 4 platforms).

---

## The forward artifact: phase_brief.yml schema + validator script

This is the forcing function. Every phase brief from Phase 5 onward is authored as a YAML file conforming to:

- **Schema:** `docs/initiative-cross-platform-ui/schemas/phase_brief.schema.json` (JSON Schema, draft 2020-12)
- **Validator:** `scripts/validate_phase_brief.cr` (Crystal; runs all queries, runs all verifications, rejects placeholders, asserts structural completeness)

The validator's exit semantics:

| Exit code | Meaning |
|-----------|---------|
| 0 | Brief is dispatchable |
| 1 | Schema violation: missing required field, wrong shape, unknown top-level key, placeholder detected (`<...>`, `...`, `same`, `equivalent`, `OR deferred`, `TBD`, `TODO`, `FIXME`), null-op command (`true`, `false`, `echo …`, `:`, comment-only, `TODO`), invariant_matrix not exactly 11 rows, probe cell too short, missing required adapter_cardinality fields, missing invariant `name` field, missing skip-record fields |
| 2 | Repo fact drift: re-running a captured query produced a different result than the brief expected |
| 3 | Lower-layer assumption falsified: a verification command exited non-zero |
| 4 | Adapter cardinality MISMATCH without documented_degradation + owner_approved |
| 5 | Probe cell references a path that does not exist (bare path OR a path argument inside a multi-token command) |
| 6 | `pre_dispatch_validation` section missing OR script_path nonexistent OR script invocation exited with code != expected_exit_code |

Invocation: `crystal run scripts/validate_phase_brief.cr -- path/to/phase-NN-brief.yml`. Architect runs this BEFORE dispatching to the Implementer. Exit 0 → dispatch ready. Exit non-zero → brief must be updated.

The sections below define the brief's required structure (instantiated by the schema). They are NOT prose to copy — they describe what the schema enforces.

### Section 1 — Invariant Coverage Matrix

For each of I-1 through I-11, declare touch level and per-platform proof command.

```
| ID  | Invariant | Touch level                  | Probe (iOS)         | Probe (macOS)       | Probe (web)         | Probe (android)     |
|-----|-----------|------------------------------|---------------------|---------------------|---------------------|---------------------|
| I-1 | Render    | preserves                    | <cmd or spec path>  | <cmd or spec path>  | <cmd or spec path>  | <cmd or spec path>  |
| I-2 | Update    | preserves / extends / skips  | ...                 | ...                 | ...                 | ...                 |
| ... |
| I-10| API contract | preserves                 | ...                 | ...                 | ...                 | ...                 |
```

Touch levels:
- `preserves` — phase doesn't change this invariant; existing proof still holds; cite existing probe.
- `extends` — phase adds new surface that this invariant must hold for; new probe required.
- `replaces` — phase changes how this invariant is satisfied; new probe required + old probe deprecation noted.
- `skips` — phase explicitly does not touch this invariant; brief states why.

Each cell holding `extends` or `replaces` must have a concrete probe command in the cell.

### Section 2 — Lower-layer assumptions table

```
| # | Assumption | Falsifier | Verification command |
|---|------------|-----------|---------------------|
| A1 | <claim about layer below> | <observable that would prove the claim wrong> | <shell command that runs the check> |
```

Every "we assume X" must have a one-line shell command (or equivalent) that verifies X at brief-authoring time. If the verification command requires manual interpretation, the brief converts it to a deterministic check (e.g., `test "$(otool -L bin/app | grep -c libssl)" -eq 0`).

### Section 3 — Repo-derived facts (at HEAD `<SHA>`)

```
| Fact | Query | Result captured at brief authoring |
|------|-------|-----------------------------------|
| Widget count | `ls src/ui/views/*.cr | wc -l` | 74 |
| Flag convention | `grep -rE 'flag\?\(:darwin\)' src/ | wc -l` vs `grep -rE 'flag\?\(:macos\) \|\| flag\?\(:ios\)' src/ | wc -l` | 0 vs N (use the winner) |
| Symbol exists: `<Name>` | `grep -rn '<Name>' src/ swift/` | <line N>:<file> |
| Tool version | `<tool> --version` | <captured output> |
```

Every numeric count, symbol name, flag, file path, or version pin in the brief is generated by a query against the actual repo state. If a fact has no query backing, it's removed or replaced.

### Section 4 — Pre-dispatch validation script

Every phase brief includes a runnable `scripts/phase-NN-predispatch.sh` that:
1. Re-runs every query in the Repo-derived facts table; fails if any result differs from the captured value.
2. Re-runs every verification command in the Lower-layer assumptions table; fails if any returns falsifier.
3. For each `extends` or `replaces` cell in the Invariant Coverage Matrix, confirms the probe command exists and is runnable (does not run it — the dispatch implementer will).

The architect runs this script. Exit 0 → dispatch ready. Exit non-zero → brief must be updated.

### Section 5 — Per-platform proof commands by category

To make Section 1 actually executable, the template provides a menu of standard probe commands per invariant + platform:

**I-1 Render correctly:**
- iOS: XCUITest snapshot via `xcodebuild test ... -only-testing:.../<test>; xcrun simctl io <UDID> screenshot ...`
- macOS: AXTest spec via `crystal-alpha spec spec/ui/hig_validation/<spec>.cr -Dmacos --link-flags="-framework ApplicationServices -framework CoreFoundation"; magick compare baseline.png actual.png`
- web: CDP harness via `crystal-alpha run scripts/phase04_cdp_harness.cr -- <page>` then `axe-core` + IBM Equal Access
- android: `gradle test connectedAndroidTest` against API 31+ emulator OR deferred with explicit note

**I-2 Update reactively (forward):**
- iOS: XCUITest invokes Crystal mutator via test trigger; reads `XCUIElement.staticTexts[<id>].label` post-mutation; asserts transition
- macOS: AXTest spec drives Crystal mutator; reads `AXValue` via `kAXValueAttribute`; asserts transition
- web: CDP harness `Runtime.evaluate("apiCallToMutate()")` then `Runtime.evaluate("document.querySelector(...).textContent")`; asserts transition
- android: equivalent UI Automator query

**I-3 Dispatch events (backward):**
- iOS: XCUITest `XCUIElement.tap()` AND coordinate tap; assert Crystal-side `Probe.last_value` updates AND the bound `on_change` callback fires
- macOS: `AXUIElementPerformAction(elem, kAXPressAction)`; assert same
- web: CDP `Input.dispatchMouseEvent` / `dispatchKeyEvent`; assert window-level JS reflects change AND if applicable a host-language probe receives the value
- android: UI Automator click event; assert callback dispatch

**I-4 Restore focus:**
- iOS: open modal/navigation/sheet; record `app.firstMatch(forAccessibilityActivate:)` pre and post; assert focus returns to invoking element
- macOS: same via `AXUIElementCopyAttributeValue(kAXFocusedUIElementAttribute, ...)`
- web: CDP `document.activeElement` snapshots pre/post
- android: same via UI Automator focused-element query

**I-5 Lifecycle:**
- All platforms: implement teardown spy on the native handle release; emit log on dealloc; assert log message appears within N ms of host-side dismissal

**I-6 Accessibility:**
- iOS: `xcrun simctl spawn` accessibility audit OR XCUITest `XCTAttachment` with AX tree dump + assertion
- macOS: `AXIsProcessTrustedWithOptions` + AX tree walk via AXTest
- web: axe-core + IBM Equal Access via CDP harness
- android: Espresso accessibility checks

**I-7 Memory ownership:**
- iOS: Address Sanitizer or Guard Malloc build; XCUITest scenario that stresses lifetime; assert no detected violations
- macOS: same
- web: not directly applicable; JS GC abstracts it
- android: LeakCanary or equivalent

**I-8 Environment:**
- iOS: XCUITest with `app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]` + capture render
- macOS: per-appearance + per-content-size launch via `defaults write`
- web: CDP `Emulation.setEmulatedMedia` + `Page.setAutoAttach` + run through high-contrast / reduced-motion media queries
- android: `adb shell settings put system font_scale 2.0` etc.

**I-9 Survive embedding:**
- iOS: build a minimal iOS spike that exercises the specific embedding scenario (class-var init, lazy-static init, etc.); print the resulting state; verify expected value
- macOS: same via AXTest spec runner
- web: N/A (no embedding)
- android: same via JNI spike

**I-10 API contract fidelity:**
- All platforms: spec that asserts public API behavior per platform AS DOCUMENTED in the per-target degradation contract; fail if behavior differs from contract

**I-11 Target build / link / load closure:**
- iOS: `samples/cross_platform/ios_host/build_crystal_lib.sh simulator && xcodebuild build -project ... -destination ...` (full link, not `--no-codegen`); confirm zero undefined symbols. If new code paths added, also `nm path/to/host | grep U` and verify no symbols outside the iOS SDK / project link set.
- macOS: `make -C samples/cross_platform/macos_host build` (full link to bin/); confirm signed binary + zero link warnings.
- web: `crystal build --no-codegen src/asset_pipeline.cr` AND `crystal run examples/web_design_system_demo.cr` (web has no link step in the iOS sense; the no-codegen build + run is sufficient).
- android: `acrystal build --no-codegen samples/cross_platform/android_host/<host>.cr -Dandroid` (current architect-precedent-PASS state per Phase 1 #17; if this changes, swap in real Android cross-build to `.so` + JNI link).

### Section 6 — Adapter selection cardinality proof

For any phase that binds a public API to an existing native component, the brief includes:

```
| Public API method/property | Adapter chosen | Adapter's input space | API's input space | Match status |
|---|---|---|---|---|
| `ActionSheet.new(actions:)` | `ConfirmationDialogFacade` | binary confirm/cancel | Array(Action) of arbitrary length | **MISMATCH** — adapter insufficient; either change adapter OR narrow API OR document degradation explicitly |
```

Workaround #6 would have been caught by this table at brief-authoring time. The architect must reject any "MISMATCH" row unless the degradation is explicitly documented as the API's per-platform contract.

---

## Forward principles (now backed by concrete artifacts above)

Each principle is now an instance of the template, not a standalone aspiration.

**P1 (Invariant declaration):** Every brief instantiates Section 1's matrix. `scripts/validate_phase_brief.cr` enforces exactly 11 rows (one per I-1 through I-11), each with a non-blank cell or an explicit `skip` record with owner approval.

**P2 (Executable proof):** Every `extends` or `replaces` cell in Section 1 has an actual command (not a description). Section 5 provides the menu of standard commands. The pre-dispatch script verifies each cited probe script exists at the path named.

**P3 (Repo-derived facts):** Section 3 captures every fact. Pre-dispatch script (Section 4 step 1) re-runs each query and fails if results drifted.

**P4 (Lower-layer assumption verification):** Section 2 captures every assumption. Pre-dispatch script (Section 4 step 2) runs each verification command and fails if any falsifier appears.

**P5 (Target-link-closure):** the Verification commands in Section 2 for any cross-target build include either (a) full build to bin/ on each target, OR (b) `nm` / `otool` symbol-closure on intermediate `.o`. `crystal build --no-codegen` is INSUFFICIENT — it does not link.

**P6 (Audit infrastructure FIRST):** every phase that exercises an audit dimension (visual diff, accessibility, behavior probe) ships OR uses pre-existing audit infrastructure that the implementer can run during development — NOT just at validation gate time. If the audit harness doesn't exist when the work begins, the phase either (a) ships the harness as its first commit before any work it audits, or (b) is sequenced AFTER the phase that ships it (this is why Phase 6.5 inserts before Phase 6). Cited by Phase 6/6.5/7 READMEs as "Principle 6 = audit-first"; that citation is now load-bearing.

**P7 (Per-platform verification):** Section 1's matrix has 4 platform columns. Pre-dispatch verifies no `extends`/`replaces` invariant has empty platform cells.

**P8 (Adapter cardinality at brief-authoring):** for any public API the phase binds to an existing native component, the brief's `adapter_cardinality` section MUST capture the input-space match per Workaround #6. Validator exits code 4 if MISMATCH rows lack documented_degradation + owner_approved.

---

## "Still likely missing" — UI-library invariants vs verification-infrastructure concerns

Codex correctly noted my Round 2 list confused these. Restated:

### UI-library invariants still unverified

1. **Android target actually builds.** Phases 5 + 6 promise 4 platforms. Phase 1 #17 architect-adjudicated Android-fail-on-darwin as precedent; we've carried it. Before Phase 5: verify Android build at least produces a known failure with a known reason (currently `c/sys/epoll` stdlib gap), not unknown failure.
2. **Focus restoration across navigation (I-4 cells).** Sheet covered via BX8; Navigation push/pop, TabView switch, Window minimize/restore not covered.
3. **Text input editing (I-3 cells for text widgets).** TextField / TextEditor / SearchField / SecureField not exercised with real typing.
4. **Lifecycle teardown (I-5).** `NativeHandle.ReleaseStrategy` exists but execution not probed.
5. **Disabled / state sync (I-2 extended).** `Button.disabled = true` runtime mutation not verified.
6. **Dynamic type / high contrast / reduced motion (I-8 cells).** Only BX10 dark-mode tint shift; everything else absent.
7. **Action / callback reason semantics (I-3 cells).** Beyond Sheet dismissal-source, other event-source disambiguation (e.g., gesture vs key invocation, drag vs tap) not modeled.
8. **Main-thread / run-loop / actor requirements for native callbacks (I-3 — observable event contract).** Callbacks crossing the bridge: are they delivered on the main thread? Does SwiftUI binding mutation require main-actor isolation? Per the locked I-3 / I-7 / I-9 boundaries, this is I-3's primary concern (event delivery contract), not I-7 (retained callback storage) or I-9 (runtime init). Not currently modeled.
9. **Per-target compile-time contract strength (I-10).** Workaround #7's downgrade pattern (constructor compile-error but type-only references compile) likely applies elsewhere. Audit.

### Verification-infrastructure concerns (not UI-library invariants — separate Phase 7 scope)

- macOS AXTest TCC determinism after rebuild
- iOS simulator runtime version pinning
- Browser version pinning + axe-core + IBM Equal Access version pinning
- CI runner provisioning

---

## What this implies for Phase 5, 6, 7

Each future phase brief INSTANTIATES the template above. The pre-dispatch script must exit 0 before dispatch.

**Phase 5 (Glass Material Tokenization):**
- Section 1 matrix: I-1 extends (new material params), I-6 extends (must preserve accessibility under blurred backgrounds), I-8 extends (material must respond to reduced motion), I-10 extends (new token API).
- Section 2 assumptions: SwiftUI Material API on iOS 26.5 + macOS 26.5; web `backdrop-filter` browser matrix; Android `RenderEffect` min SDK.
- Section 3 facts: regenerate at brief-authoring.
- Section 6 cardinality: token-role contract for each new material token MUST be declared (avoid Workaround #5b recurrence).

**Phase 6 (Side-by-Side Demo App):**
- Highest risk. ALL latent invariants surface.
- Section 1 matrix: every invariant `extends` (real demo exercises real consumer patterns).
- Class-init systematic fix is **required prerequisite** — either Phase 5 ships it or a "Phase 5.5" interstitial does.
- Audit infrastructure must exist in-dev (see Phase 7 split below).

**Phase 7 (Accessibility & Visual Verification Automation):**
- Current README: `depends on Phase 6`. **This conflicts with the audit-first lesson.** Phase 6 will repeat Phase 3's pattern (ship then chase regressions).
- Recommended split:
  - **Phase 6.5 (audit-during-dev infrastructure):** ships visual-diff harness + reusable CDP / AXTest / XCUITest patterns BEFORE Phase 6 begins. Phase 6 uses it during dev.
  - **Phase 7 (CI integration):** wraps Phase 6.5's infrastructure into GitHub Actions / equivalent, runs on every PR.
- Phase 6.5 + Phase 7 together still equal one phase of net work; the split moves the deliverable timing.

---

## The single most important lesson

**Plans must declare load-bearing invariants and provide executable proof commands before construction.**

Noun-driven planning ("build facades for widgets") is how a UI library ships one-way data flow + multi-action degradation + weakened compile-time contracts + transitive iOS link failures. Invariant-driven planning instantiates the template above.

If "invariant-driven" remains rhetoric, this retrospective fails. The Phase Brief Template + pre-dispatch validation script is the forcing function that prevents that.
