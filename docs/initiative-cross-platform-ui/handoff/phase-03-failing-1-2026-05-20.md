# Phase 3 — Failing GATE_REPORT (iteration 1) — 2026-05-20

**Verdict:** FAIL
**Validator run date:** 2026-05-20
**Iteration:** 1

**Implementer commits validated (10):**
- Foundation: `7756d25` (link-gap repair), `6996ba7` (Swift scaffold + Button facade + LibSwiftKitBridge + populator + 38 specs)
- Dispatch A: `7486040` `ed51fd7` `dfe1274` `bdfcf18` (Button migration + brand-tint cascade + sample build wiring + helper extraction)
- Dispatch B: `3a81950` `34e1d4b` (Groups 1+2: 20 widgets)
- Dispatch C: `f647ddb` `f2cae3b` (Group 3: 15 container widgets)

**Evidence directory:** `docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20/`

---

## Architect adjudication

51 checks evaluated: 9 passing, 28 failing, 13 blocked behind the Swift package compile errors, 1 optional. The pattern is clear:

### Crystal-side foundation is solid (PASS)

- `crystal spec` from repo root: 1294 examples / 0 errors / 4 pre-existing failures (architect-adjudicated) — no Phase 3 regressions.
- `crystal build --no-codegen src/asset_pipeline.cr`: exit 0, no warnings.
- 36 facade/overrides/populator/visit-method triplets shipped (Button + Groups 1+2+3).
- LibSwiftKitBridge typed wrapper, default-nil propagation centralized in `populate_view_common`, callback registry trampoline wired, `objc_setAssociatedObject` retention policy in place.
- 105 SwiftKit-related Crystal spec examples pass.

### Swift-side has three concrete, fixable defects (FAIL)

1. **`ViewOverrides.accessibilityLabel` selector collision** on iOS slices — `@objc public var accessibilityLabel: String?` collides with `NSObject`-supplied `UIAccessibility.accessibilityLabel`. Rename to e.g. `apskAccessibilityLabel` with `@objc(apskAccessibilityLabel)` to avoid the SDK selector.
2. **`ToolbarFacade.swift:40` ViewBuilder error** on macOS — `ForEach { ToolbarItem(...) }` inside a `@ViewBuilder` context can't resolve. Refactor: build the `ToolbarContent` in a separate function typed `@ToolbarContentBuilder`.
3. **Swift test suite is entirely absent** — `Tests/AssetPipelineSwiftKitTests/` has zero `.swift` source files. The required `OverridesPropagationTests.swift`, `RuntimeBridgeTests.swift`, and `SnapshotTests/*.swift` don't exist. Five baseline PNGs (`default_button_ios.png`, `default_button_macos.png`, `background_override_ios.png`, `corner_radius_zero_ios.png`, `glass_default_ios26.png`) are all missing.

### Widget coverage gap

The 36 widgets shipped are 76% of the SwiftUI-migrable set. Not yet shipped:
- **Group 4 (feedback/media, 9 widgets):** ProgressView, ActivityIndicator, RichText, VideoPlayer, MapView, WebViewComponent, ChartView, Tooltip, Snackbar.
- **Group 5 (shapes, 6 widgets):** Circle, Rectangle, RoundedRectangle, Capsule, Canvas, PathView.
- **Group 6 (glass, 1 widget):** **GlassBackground** — flagged by the Validator as "the phase's headline visual differentiator" because the Phase 3 README explicitly names "Liquid Glass on default Card/Sheet" as a load-bearing invariant. The Card and Surface facades use `.regularMaterial`/`.thinMaterial`/`.thickMaterial` static backgrounds with no `if #available(iOS 26.0, *) { .glassBackgroundEffect() }` branch.

Layout primitives (5) intentionally stay native per owner decision α — those are not failures.

### Blocked checks (13)

Every behavior check (`button-tap-fires-handler-ios`, `button-tap-fires-handler-macos`, `value-callback-toggle-ios`, etc.) and every visual check (`button-default-renders-ios`, `glass-cascade-ios26`, etc.) is blocked because:
- Swift package doesn't compile → no sample binaries on either platform.
- iOS sample build requires `crystal-alpha` (env gap).
- No iOS 26.2 simulator / iPhone 17 Pro available on this validation host.
- The existing `bin/hig_showcase` predates Phase 3 (April 17) and `otool` shows no SwiftUI/Combine linkage.

These would likely pass once the Swift compile errors are fixed and a sample binary is built — but proof requires the build to succeed.

---

## Remediation scope (concrete + bounded)

**Definite (must fix to pass iter-2):**

1. **Rename `ViewOverrides.accessibilityLabel`** to avoid the UIAccessibility selector collision on iOS. Use `apskAccessibilityLabel` with `@objc(apskAccessibilityLabel)`. Update every Override class that inherits from `ViewOverrides` plus the Populator's `populate_view_common`. Update specs that assert the setter name.
2. **Refactor `ToolbarFacade.swift`** to extract the `ForEach { ToolbarItem(...) }` into a separate `@ToolbarContentBuilder`-typed function. The current shape is structurally invalid Swift.
3. **Author the Swift test suite:**
   - `Tests/AssetPipelineSwiftKitTests/OverridesPropagationTests.swift` — verify that setting fields on each `*Overrides` class produces the expected SwiftUI modifier chain on the corresponding `*Facade`.
   - `Tests/AssetPipelineSwiftKitTests/RuntimeBridgeTests.swift` — verify `APSKRuntime.setBrandTint`, action trampoline install, callback dispatch.
   - `Tests/AssetPipelineSwiftKitTests/SnapshotTests/*.swift` with the five required baseline PNGs.
4. **Verify the Swift package builds on all three slices** (iOS simulator + iOS device + macOS). Run `swift build -c release` for the package; run `swift build --triple arm64-apple-ios16.0-simulator --sdk ...` and `--triple arm64-apple-ios16.0` for the iOS variants.

**Owner-decision territory (separate question):** Groups 4 + 5 + 6.

---

## Architect's view on widget-coverage scope

Three reasonable paths:

**(I) Remediation 1 = compile fixes + Swift tests only. Groups 4-6 deferred to a separate dispatch.** Cleanest split. The Validator's verdict on the 36 widgets-shipped path becomes provable once the Swift package compiles. Remaining widgets become Dispatch D under a new phase label or roll into Phase 5's glass work (since GlassBackground is Phase 5's primary focus anyway).

**(II) Remediation 1 = compile fixes + Swift tests + Groups 4-6.** All in one remediation loop. Bigger blast radius; takes longer; risks another natural-boundary stop. But ships the complete Phase 3 widget set in one validator pass.

**(III) Remediation 1 = compile fixes + Swift tests + GlassBackground only (Group 6).** Treats Groups 4-5 as deferrable but ships the "headline visual differentiator" the Phase 3 README names. This is a middle path — Glass is what the Phase 3 brief most emphasizes; Groups 4-5 (ProgressView, shapes) are less load-bearing.

**Architect's recommendation: (III).** It clears the headline visual differentiator (Glass) the Phase 3 README names, fixes the two compile errors, ships the Swift test suite, and keeps the remediation loop tightly scoped. Groups 4-5 become a small post-Phase-3 cleanup dispatch.

---

## Full validator report

See `docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20/` for the 51-check JSON GATE_REPORT, build_logs/, inspections/, test_output/.
