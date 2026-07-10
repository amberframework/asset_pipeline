# Plan Quality Audit — 2026-05-20

Sub-agent audit dispatched to evaluate whether the freshly-written plan is *actually implementable*. Findings below; verdict is **NEEDS MAJOR REVISION** with 10 named blocking fixes. None of the gaps are unrecoverable — they would each burn a remediation loop if not fixed up front.

---

## Verdict
**NEEDS MAJOR REVISION**

The plan is unusually thorough for a single-pass agent write — far better than typical — but several blocking issues will cause execution to stall or produce ambiguous validator verdicts. The most serious problems concentrate in:

- **Phase 3** (the explicitly-flagged highest-risk phase)
- **Phase 5** (which depends on Phase 3 internals that don't quite match)
- **Cross-phase API drift** between Phase 1's token shape and what Phases 2/5/6 assume

---

## Per-dimension findings

### A — Tool & environment clarity

- **Phase 3 §10.2:** Implementer told to pick a snapshot library at execution time. Validator S6 then requires named PNG baselines exist. Pin a choice (`swift-snapshot-testing` at a specific version, or hand-rolled `UIView.drawHierarchy` capture).
- **Phase 3 §10.1:** A "fake `LibObjCBridge`" Crystal spec helper is required but never specified as its own step. It's non-trivial test infrastructure and needs a dedicated commit.
- **Phase 3 §5.5:** `typealias APSKPlatformView = UIView` declared twice (in `ViewOverrides.swift` and `HostingHelpers.swift`). Swift will reject the duplicate.
- **Phase 4 (commits 4 & 10):** `crystal build --no-codegen -` with stdin input — the bare `-` flag is not the correct Crystal compiler invocation. Validator's compile-error check will fail to even reach the assertion.
- **Phase 5:** References `LibSwiftKitBridge.material_parameters_new(...)`, `LibSwiftKitBridge.glass_background_overrides_new(...)`. `LibSwiftKitBridge` is never defined anywhere. Phase 3 uses `LibObjCBridge` + a `SwiftKit` module.
- **Phase 5 web CSS:** Uses `var(--amber-color-surface-panel)` while Phase 1 says canonical is `--ap-color-*` (with `--amber-*` as deprecated alias).
- **Phase 6 capture script:** macOS capture pseudocode uses `osascript` + `screencapture -l <window_id>`, but `<window_id>` lookup is unspecified and non-trivial.
- **Phase 6:** References `xcodegen generate` (external Homebrew tool) with no version pin.
- **Phase 6 brand declaration:** Uses `b.color.brand_primary = ...` syntax incompatible with Phase 1's immutable `ColorPalette` `record`.
- **Phase 7 `audit_macos_demo_accessibility.cr`:** Says it uses Carbon `AXUIElementCopyAttributeValue` C API via Crystal `lib` declarations. Crystal doesn't ship AX bindings. Needs a dedicated FFI commit.

### B — Testing expectations

- Universal `implementation_criteria.md` §Testing is concrete enough. ✓
- **Phase 3 §10.1:** Doesn't say what to do with existing renderer specs (keep/update/delete).
- **Phase 4 compile-error specs:** Pattern using `Process.run` against `crystal build` is unproven; no fallback.
- **Phase 5 validation §Spec suite:** Graceful degrade with `blocked: true` is reasonable, but spec-file-name enumeration is missing so validator can't distinguish "missed" from "differently-named".
- **Phase 6 testing item 1:** "Verify the C-ABI export function compiles" doesn't say how. Spec it as `crystal build --no-codegen ... -Dios`.
- **Visual fidelity bar inconsistent:** Phase 3 uses 8/255 channel delta, Phase 7 uses 3/255. Pick one or document the difference.

### C — Validation rubric clarity

- **Phase 1 checks 18-20:** Cascade behavioral checks need a concrete sample file path (currently placeholder).
- **Phase 3 V6:** iOS-26 simulator dependency should be stated once up front, not implicit across many checks.
- **Phase 3 I1:** Uses pre-implementation line-number guesses to identify `visit` method ranges. By validator time, lines have shifted. Restate as textual range (grep for `def visit(view : UI::Button)` + next `def visit`).
- **Phase 4 `tier.tier3-set-correct`:** Hard-codes the set `{ActionSheet, ContextMenu, PathControl}` but implementation defers Toolbar/Popover/MenuButton to team-lead adjudication. Add an escape hatch.
- **Phase 5 check 22:** Allows "the AppKit translation table" as exception but doesn't tell validator how to distinguish it from a leftover. Add a marker comment requirement.
- **Phase 6 `brand.override-visible`:** Asks validator to comment out brand declaration, rebuild, revert. Invasive and subjective. Better: capture two screenshots, compute Lab color distance on a known primary-button hue.
- **Phase 7 `baselines.regression-detected`:** Path described as "in implementer handoff" — circular dependency. State up front in rubric.

### D — Inter-phase dependencies

- **Phase 1 ↔ Phase 2:** Phase 2 halts if `touch_target_minimum` not in tokens. Phase 1 doesn't define it. **Phase 2 will halt on dispatch.**
- **Phase 1 ↔ Phase 3:** ✓ Match on token Swift output location.
- **Phase 1 ↔ Phase 5:** Material block extension to `WebGenerator` is implicit. Should be explicit in Phase 5.
- **Phase 1 ↔ Phase 6:** Brand API mismatch (covered in A). **Will not compile as written.**
- **Phase 3 ↔ Phase 5:** Naming mismatch (`LibSwiftKitBridge` doesn't exist).
- **Phase 3 ↔ Phase 4:** Phase 4 says "use SwiftKit's `.confirmationDialog`" but Phase 3 widget list has `ConfirmationDialog`+`Sheet`, no `ActionSheet` facade. Unclear whether Phase 4 builds it or routes.
- **Phase 4 ↔ Phase 6:** Phase 6 calls `UI::ActionSheet.show(...)`, `UI::HapticFeedback.impact(:medium)`. Phase 4 declares instance methods, not class-level `.show`/`.impact`.
- **Phase 6 ↔ Phase 7 viewport tags:** Tiny mismatch (`iPhone 17 Pro` vs `iphone17pro`).
- **Phase 6 ↔ Phase 7 artifact paths:** Phase 7 baselines at `test-results/initiative-demo-baselines/`, Phase 6 quad evidence at `output/initiative-demo/quad-evidence/`. Two parallel systems; flag the distinction.

### E — Architectural soundness

- **Phase 3 nested `UIHostingController`:** Will likely surface layout pathologies in `Form`/`List` contexts (SwiftUI re-measures children of representable hosts unpredictably). Recommend documenting `.frame()` minWidth/minHeight defensive sizing as workaround in the brief.
- **Phase 3 callback registry mutex:** `proc.call` runs under the lock — should release before invoking. Quick fix.
- **Phase 3 `NSNumber?` heap allocation cost:** Hundreds of allocs per layout pass on complex screens. Document as known cost.
- **Phase 5 SwiftUI clamps negative blur to zero:** Correctly flagged. Means `intensity < 1.0` cannot reduce iOS blur below system default. Acceptable API limitation.
- **Phase 4 vanilla JS MutationObserver:** `observe(document.documentElement, { subtree: true })` is catastrophically expensive on large pages. Fine for demo, perf bug for real consumers. Flag as known concern.
- **Phase 6 `prefers-reduced-motion` in capture:** Captures deterministic but not realistic. Acceptable for regression baselines; document in runbook.
- **Phase 5 `@supports` fallback opacity (94% on regular):** Materially changes visual hierarchy when fallback fires. Pin headless Chrome version (Phase 7 does); verify it supports `backdrop-filter`.

### F — Risky judgment calls

All major judgment calls (SwiftPM vs xcodebuild, `@objc` vs `@_cdecl`, per-widget hosting controller, typed Overrides class, deferring Toolbar/Popover/MenuButton tier classification) were assessed as correct or acceptable trade-offs. No risky-and-wrong judgment calls identified.

---

## Top 10 fixes to make before execution

1. **Phase 1 + Phase 2 — add `touch_target_minimum` to Phase 1's `Tokens` aggregate.** Either add `getter touch_target_minimum_px : Float64` field (default 44.0) in Phase 1 §3.2, or remove Phase 2's halt condition.

2. **Phase 1 + Phase 6 — reconcile the `Brand` API.** Phase 1 ships an `abstract class Brand` with `override_color_light(palette)` style. Phase 6 writes a `Brand.declare do |b| b.color.brand_primary = ...` builder DSL. Incompatible. Pick one in Phase 1, update Phase 6 to match.

3. **Phase 3 + Phase 5 — converge on a single bridge module name.** Phase 5's `LibSwiftKitBridge` references need a real home. Either Phase 3 ships `LibSwiftKitBridge` as a typed wrapper alongside `LibObjCBridge`, or Phase 5 is rewritten to use Phase 3's actual surface.

4. **Phase 4 — verify or replace the `crystal build --no-codegen -` stdin pattern.** If it doesn't work on the project's Crystal version, switch to writing to `/tmp/test.cr` and building that.

5. **Phase 1 cascade checks 18-20 — pin the exact sample file path to edit.** Replace placeholder with a real sample, or add `samples/cross_platform/web/brand_cascade_demo.cr` in Phase 1 commit 13 specifically for the validator.

6. **Phase 3 §10.1 — split out the "fake `LibObjCBridge`" test-shim work** as a named step (Step 8a) with its own commit. This shim is the only thing standing between spec suite running with iOS frameworks installed vs without.

7. **Phase 3 §5.5 — remove duplicate `typealias APSKPlatformView`.** Pick one source-of-truth file; document which file owns it.

8. **Phase 6 — pin XcodeGen version.** Either drop XcodeGen and write the `.xcodeproj` literally, or install at pinned version via `brew install xcodegen` at top of build script.

9. **Phase 5 + Phase 4 web CSS — choose one prefix (`--ap-*` or `--amber-*`) for new emissions.** Document the choice in both phases.

10. **Phase 6 + Phase 7 — align viewport tag vocabulary.** Phase 7's `iphone17pro` (lowercase, no spaces) is filesystem-safe; update Phase 6's harness to match.

---

## What's working well

- **Trust-pair protocol is genuinely well-designed.** Independence rules, no-skip invariant, GATE_REPORT schema, and fail-closed-on-ambiguity rule are mature and will produce reproducible verdicts.
- **Phase sequencing and dependency graph are correct.** 1 → 2/3 → 4/5 → 6 → 7 is the right order; dependency notes accurately identify blockers.
- **Deviation prompts in Phase 4 (ActionSheet missing) and Phase 5 (cascade scope) are excellent** — preempt likely implementer stalls by explicitly authorizing or flagging for adjudication.
- **`implementation_criteria.md` "When the brief is wrong" section** is the single most important piece of universal text — correctly distinguishes small auto-correctable from large stop-and-return divergences.

---

## Notes for the team lead

- **Phase 3 is the longest doc (1259 lines) and explicitly highest-risk.** Budget 2-3 days + at least one remediation loop. Have a debugging plan ready (Xcode View Debugger, `_printChanges()` dumps).
- **Phase 5 validation.md numbers checks starting at 15** (not 1). Unusual — no other phase does this. Reset to 1 or document the global numbering scheme.
- **Phase 4 compile-error spec mechanism (subprocess `crystal build`) is novel for this repo.** May not work first try. Have a platform-gated spec plan as fallback.
- **Phases 5 and 6 reference Crystal APIs that may not match Phase 1's actual shape.** Have Phase 1 implementer confirm final `Brand`/`Tokens` API surface in their handoff; do a 30-minute reconciliation pass before dispatching Phase 2.
- **Phase 7 budgets significant CI runner cost** (macOS-15 × 4 jobs per PR). Decide budget before dispatching.
- **Plan is heavily Apple-weighted.** Android coverage is thinner. End state: Android functional but visually less polished. Phase 6 quad-comparison excludes Android, consistent with prioritization.
