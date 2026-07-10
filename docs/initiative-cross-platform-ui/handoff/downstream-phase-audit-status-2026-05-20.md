# Downstream phase doc-audit status — 2026-05-20

**Compiled by:** Architect, while Phase 1 Implementer is in-flight, as non-conflicting prep work for checkpoint #3.
**Source of audit items:** `handoff/plan-quality-audit-2026-05-20.md` §"Top 10 fixes to make before execution".

This note records whether each of the 10 plan-quality-audit findings has been addressed in the phase docs themselves, so the Architect does not relitigate them when dispatching downstream phases. **It does not certify the implementer or validator output of those phases; that is each phase's gate report.**

---

## Audit fix coverage

| # | Audit fix | Status | Where addressed |
|---|---|---|---|
| 1 | Phase 1 + Phase 2: `touch_target_minimum_px` field on the `Tokens` aggregate | ✅ Resolved | Phase 1 §3 ships `getter touch_target_minimum_px : Float64` (default 44.0); Phase 2 implementation.md §46 hard-blocks if it's missing on dispatch |
| 2 | Phase 1 + Phase 6: `Brand` API reconciliation | ✅ Resolved | Phase 6 implementation.md §573 explicitly states "no `Brand.declare do |b|` DSL"; uses `UI::Brand` subclass + `override_*` methods returning new records via `copy_with`. Phase 1 ships the `Brand` interface in this exact shape |
| 3 | Phase 3 + Phase 5: `LibSwiftKitBridge` typed-wrapper module name | ✅ Resolved | Phase 3 implementation.md §59 creates `src/ui/native/lib_swiftkit_bridge.cr`; Phase 5 implementation.md §59 explicitly references the same path. Phase 5 surface contract documented in Phase 3 §7.4 |
| 4 | Phase 4 compile-error spec via tempfile, not stdin | ✅ Resolved | Phase 4 implementation.md §1080 explicitly: "Compile-check subprocess pattern: tempfile, not stdin." Validation §81 + §139 follow through |
| 5 | Phase 1 cascade-checks pin sample file path | ✅ Resolved | Phase 1 Step 12 commits `samples/cross_platform/web/brand_cascade_demo.cr`; validator checks #18–#20 quote that exact path |
| 6 | Phase 3 `fake LibObjCBridge` as its own step | ✅ Resolved | Phase 3 implementation.md Step 8a (line 1361) is the dedicated commit — `spec/support/fake_lib_objc_bridge.cr` with its own sanity spec |
| 7 | Phase 3 `APSKPlatformView` duplicate | ✅ Resolved | Phase 3 implementation.md §5.5 declares it once with conditional `#if/#else`; line 701 explicitly forbids redeclaration in `HostingHelpers.swift` |
| 8 | Phase 6 XcodeGen version pin | ✅ Resolved | Phase 6 implementation.md §99 pins `>= 2.41`; §922–§939 bootstrap script enforces |
| 9 | Phase 5 + Phase 4 web CSS prefix | ✅ Resolved | Phase 1's `WebGenerator` is `--ap-*`-only with `--amber-*` aliases removed wholesale; downstream phases inherit |
| 10 | Phase 6 + Phase 7 viewport tag vocabulary | ✅ Resolved | Both phases use canonical `iphone17pro` (lowercase, no spaces, no underscores); Phase 7 implementation.md §141 explicitly forbids `iPhone 17 Pro` / `iphone_17_pro` / `iPhone17Pro` in baselines |

---

## Phase-2-readiness summary

Phase 2 (`Responsive Web Fluid Resize`) is ready to dispatch the moment Phase 1 passes its validator and the Architect's reflection note is written. Specifically:

- Phase 2 reads `tokens.touch_target_minimum_px` and `tokens.breakpoints` from Phase 1 — both ship.
- Phase 2 reads `var(--ap-*)` CSS custom properties from `dist/web_tokens.css` — Phase 1 emits all of these and only these.
- Phase 2 does not depend on Phase 1's Android scope. The Android-generator deferral is transparent to Phase 2.
- Phase 2's existing-infrastructure list (`scripts/capture_web_demo_screenshots.cr`, `scripts/axe_web_demo_audit.cr`, `scripts/ibm_web_demo_audit.cr`, `scripts/validate_web_demo.cr`, `output/web-design-system-*.html`) is all committed on the basis state.

No additional Phase 2 scope adjustments are needed pre-dispatch. The Team Lead briefing (now Architect-dispatched per `architect-dispatch-collapse-2026-05-20.md`) can use the standard template.

---

## Phase-3+ readiness — held until Phase 2 passes

Per `start-architect.md` checkpoint discipline, phases are dispatched one at a time after the prior phase's reflection note. This audit only verifies the *phase docs* are internally consistent and audit-compliant. Cross-phase readiness depends on:

- Phase 1's `Brand` interface shape landing exactly as Phase 6's brief expects (the Phase 1 Implementer's handoff will document this; Architect verifies at reflection).
- Phase 3's `LibSwiftKitBridge` `fun` declarations matching what Phase 5 calls (verified at Phase 3 reflection).
- Phase 6's `output/initiative-demo/quad-evidence/` and Phase 7's `test-results/initiative-demo-baselines/` deliberately staying separate (called out in Phase 7 §94).

Re-verify each of those at the corresponding phase boundary; do not pre-resolve them now.

---

## Items not in the audit but worth Architect attention

- **CI cost (Phase 7).** Phase 7 implementation.md §596 has an explicit "Open budget questions for the team lead" section flagging macOS-15 × 4 jobs per PR as the dominant cost. Not a doc inconsistency — a real budget decision Seth needs to make before Phase 7 dispatch. Default recommendation in §600(a): collapse `visual-regression-macos` and `native-a11y-audit-macos` into one job.
- **Android deferral aftermath.** Phases 4 (new gated visit methods) and 5 (glass token block replacement) both legitimately touch `android_renderer.cr`. Those touches are *not* the Phase 1 token-literal-scrub deferral — they are independent work the deferred Android phase does not block. No action needed.
