# Phase 3 — Architect Reflection — 2026-05-21

**Phase:** SwiftUI Native Bridge
**Outcome:** PASSED (Validator iter 7 — 49/49 required checks)
**Tag:** `phase-03-passed-2026-05-21` (forthcoming)
**Final HEAD:** `bfd129d`

## What this phase actually cost

10 implementer remediations + 7 validator iterations + 5 owner-decision branches + 1 Codex CLI integration. ~33 substantive commits over multiple sessions. Far over budget compared to Phases 1 and 2 (each 1 remediation, 2 validator iterations).

## What planning got wrong

The Phase 3 README treated the SwiftUI bridge as a **construction/rendering** problem. The actual surface area was **mounted behavior**, which is much larger:

1. **Reactivity (Crystal→SwiftUI):** the README's silence on reactive state propagation led to a static bridge shipped in the Dispatches A/B/C. Owner correctly flagged this as a planning miss; Remediation 4 shipped the forward direction (`@_cdecl` mutators + `@Published`).
2. **Reactivity (SwiftUI→Crystal) for value-bound controls:** the same gap on the opposite side. Owner had to flag this a second time before I connected it. The fix was the UIKit `UISwitch` UIViewRepresentable in Remediation 10.
3. **Memory ownership across Crystal/ObjC/Swift:** `apsk_nsstring` and detached-render-path string lifetimes weren't explicit invariants. Surfaced as the BX8 crash; resolved in Remediation 9 — though the actual root cause turned out to be deeper (see #4).
4. **iOS embedding class-init gap:** Crystal class-variable initializers and `Crystal::once`-protected lookup tables don't fire under the iOS embedding because `_main` is hidden. Discovered in Remediation 9 BX8 diagnostics. Workaround landed (probe `.reset` in `initialize_runtime`); systematic fix is Phase 5+ work. See `memory/project_crystal_ios_class_init_gap.md`.
5. **XCUITest tap synthesis through `UIHostingController-in-UIViewRepresentable`:** XCUIElement.tap() doesn't route through SwiftUI Toggle's value-bound binding under that hosting topology. Coordinate taps work; drag-style controls work; only the AX-activate path for value-bound controls breaks. Fix: UIKit wrappers for value-bound controls (Remediation 10).
6. **Hit-test expansion via `.contentShape(Rectangle())`:** `.frame(minHeight:)` alone resizes outer container but doesn't expand the AX hit rect; `.contentShape` is the actual mechanism for 44pt touch-target enforcement. Discovered in Remediation 8.
7. **Probe slug authoring discipline:** 12 named probe slugs the rubric drove off were never authored in the iOS/macOS samples. R3 fixed this. Should have been part of Dispatch B/C's original brief.
8. **Test-flow reconciliation:** changing iOS sheet behavior (R10) required corresponding rewrite of the XCUITest flow (sheet content doesn't exist at launch until trigger taps). Brief explicitly enumerated; would've shipped wrong without that.

The pattern: each remediation closed one surface layer; the next iteration exposed the layer underneath. The reactive-bridge framing in particular was central — once I and the owner reframed BX3/BX8 as **bidirectional bridge completeness** (not isolated hit-test bugs), the remaining fixes followed cleanly.

## What worked

1. **Diagnostic-first protocol (Remediation 9 onward).** Prior remediations hypothesized fixes without instrumentation. R9 enforced "no fix before evidence file exists with captured logs/lldb output." Result: R8's two confident hypotheses (UIHostingController hit-test gap, Crystal-iOS ABI) were both falsified by hard data, and the actual root causes were much more local.

2. **Codex CLI as built-in critique tool.** Used in two modes:
   - **Brief review** (architect-side): R9 dispatch brief passed Codex on round 3 (caught stale identifier names, wrong file path for `apsk_nsstring`, instrumentation gaps); R10 dispatch brief passed on round 6 (caught incomplete UIView patch, hypothesis-baked-in, missing Crystal-side write path, test-flow not reconciled, missing dismiss-path enumeration, onDismiss overwrite race).
   - **Implementer critique cycles** (implementer-side): 4 mandatory checkpoints per dispatch (post-diagnostic, pre-fix, post-fix, optional pre-deferral). R10 implementer's Codex Checkpoint 2A caught a smart Slider scope-cut that saved unnecessary work.

3. **Trust pair with strict role boundaries.** Architect never wrote production code; implementer never validated own work; validator never wrote source. After Remediation 8 we added Codex as an out-of-band fact-check at the brief level, which turned out to be a quality-multiplier.

4. **Deferral checklist (R9 onward).** 7 items required for any deferral, adjusted to bug class (crash/lifetime vs interaction). Prevented the "we hypothesized and got tired" failure mode that drove R8.

## What didn't work and shouldn't be repeated

1. **Trusting implementer hypotheses without diagnostic backing.** R8's two deferrals were both wrong in non-obvious ways. The cost was R9 + R10 + this much architect time. Always require the data.

2. **Treating macOS empirical proof as sufficient for an iOS-targeted bridge.** macOS BX2 passed end-to-end from R4 onward, which masked the fact that iOS had its own deeper layers (link config, require leaks, probe slug authoring, AX-tree exposure, class-init gap, hit-test routing, sheet reactive state).

3. **Single-architect framing.** Through R8 I kept reframing problems with my own working context, which calcified blind spots. Adding Codex as external review in R9+ was load-bearing.

4. **One-time briefing pass.** The first version of R10's brief had 6 latent defects Codex caught across 5 review rounds. Single-pass briefs are not safe for complex cross-language work.

## Phase 5+ inheritances (real work, not ignore-list)

1. **Crystal-iOS class-init gap** — `memory/project_crystal_ios_class_init_gap.md` documents the full pattern. Phase 5 (Glass Material Tokenization) or a dedicated sub-phase should ship `UI::Native::iOS::Runtime.boot` that explicitly initializes the subsystems Crystal's hidden `_main` skipped (Fiber, STDERR, Float::Printer::Dragonbox, any other class-var initializers downstream consumers might rely on).
2. **Slider migration to UIKit wrapper** — R10 Codex Checkpoint 2A correctly skipped Slider because BX4 was already passing via `.adjust(toNormalizedSliderPosition:)`. If a future BX surface needs `XCUIElement.tap()` synthesis on Slider (or any other value-bound control beyond Toggle), the same UIViewRepresentable + UIKit-control pattern applies.
3. **Groups 4-5 widgets (15 widgets)** — owner-deferred from Phase 3. These need facade + overrides + populator + visit-method migration in both renderers, plus probe coverage if any need behavioral verification.
4. **Visual baseline regeneration** — macOS captures earlier in Phase 3 were degenerate due to Screen Recording TCC not being granted. Resolved before Validator iter 7; future captures will be substantive.

## Phase 4 readiness check

Per protocol I'll re-read Phase 4's README before Seth gives the go-ahead. Specific things to flag:

- Phase 4 is "Platform Tier Gating" — should explicitly include macOS 14+ / iOS 16+ deployment targets per `memory/project_platform_minimums.md`.
- The class-init gap (#1 above) may surface as Phase 4's responsibility if its scope includes any iOS-specific runtime initialization. If Phase 4 is purely about compile-time `if #available(...)` and SDK selection, the class-init work stays a Phase 5 item.

## Closing note

Phase 3 is structurally complete with empirical proof of every load-bearing reactive invariant on both macOS and iOS. The bridge supports default visual fidelity, action callbacks, override propagation, brand cascade, runtime state mutation, and bidirectional state flow for the 37 widgets currently in scope. The cost was high; the foundation is real.
