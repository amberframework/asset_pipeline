# Phase 3 — Current state for Codex external review — 2026-05-21

This document gives an external reviewer (Codex CLI) full context on Phase 3 (SwiftUI Native Bridge) of the asset_pipeline cross-platform UI initiative. It is **not** authoritative for the project; the authoritative docs live at the paths cited below. This is a snapshot to anchor independent fact-checking.

## What Phase 3 was supposed to ship

Per `docs/initiative-cross-platform-ui/phases/phase-03-swiftui-native-bridge/README.md`:

- Replace direct AppKit/UIKit calls for 37 widgets with SwiftUI facades shipped as the `AssetPipelineSwiftKit` Swift package.
- A typed `LibSwiftKitBridge` (Crystal `lib`) calls into `@objc`-exported facade constructors via the ObjC ABI.
- Per-widget `*Overrides` Swift classes propagate per-instance overrides into SwiftUI modifier chains.
- `APSKRuntime.setBrandTint` propagates a single brand color via `.tint()` cascade rather than per-widget injection.
- Action callbacks fire Swift → Crystal via the existing callback registry trampoline.
- iOS 26 / macOS 26 Liquid Glass via `.glassEffect()` with material fallback for older OS.

The brief did NOT explicitly enumerate:
- Bidirectional state binding (Crystal-side state mutation → SwiftUI view re-render).
- Hit-test propagation for value-bound SwiftUI controls hosted inside UIHostingController via UIViewRepresentable on iOS.
- Memory-lifetime guarantees for Crystal String values whose C pointers cross the Crystal/ObjC/Swift boundary and persist past the original Crystal scope.
- Touch-target (44pt minimum) enforcement at the SwiftUI facade level for arbitrary hosted control sizes.

The owner has explicitly noted (saved as a feedback memory) that reactivity should have been assumed-by-default — calling it out as optional was a planning gap.

## What's been shipped so far

13 implementer dispatches across 6 owner-mediated decision branches and 8 remediation loops have produced ~25 substantive commits on branch `phase-03-swiftui-native-bridge`. Commits since the iter-3 ledger commit (`1c43f94`):

```
git log --oneline 1c43f94..HEAD
```

Files of interest:
- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/` — 37 widget facades + `ReactiveState.swift` (`APSKLabelState`, `APSKButtonState`, `BoolStorage`, `DoubleStorage`)
- `swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/` — 53 tests passing
- `src/ui/native/swiftkit_bridge.cr` + `swiftkit_bridge.m` — typed Crystal lib + ObjC C trampolines
- `src/ui/native/swiftkit_overrides.cr` — Crystal-side populators
- `src/ui/views/{label,button,toggle,slider}.cr` — Crystal-side reactive setters
- `src/ui/renderers/uikit_renderer.cr` + `appkit_renderer.cr` — visit-method routing
- `samples/cross_platform/macos_host/hig_showcase.cr` + `samples/cross_platform/ios_host/Sources/` — 12 named probe slugs
- `samples/cross_platform/ios_host/UITests/Phase03BehaviorTests.swift` — XCUITest target with 12 BX methods
- `spec/ui/hig_validation/macos_action_tap_probe_spec.cr` + `macos_form_layout_spec.cr` — macOS AXTest specs

## Current validator status (iter 6, 2026-05-21)

49 required checks: 44 PASS, 5 FAIL, 0 BLOCKED.
Gate report: `docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter6/gate-report.json`

All three load-bearing reactive invariants empirically PASS on both platforms:
- BX1: iOS XCUITest observes `["0", "1", "2", "3"]` strict label transitions across 3 synthetic taps
- BX2: macOS AXTest observes `"0" → "1" → "2" → "3"` via real `AXUIElementPerformAction(kAXPressAction)`
- BX5: iOS XCUITest observes runtime override propagation — center pixel ΔE drops from 63.5 (transparent) to 33.6 (toward pure red) after the make-red trigger

Remediation 8 (most recent dispatch) closed 3 of the 5 iter-6 FAILs:
- BX4 (slider): PASS via integer-arithmetic decimal formatter (Crystal `sprintf("%.2f", Float64)` crashes inside `Float::Printer::RyuPrintf` on iOS arm64 simulator — Crystal-iOS toolchain bug)
- BX6 + BX9 (form row + button touch target): PASS via `.contentShape(Rectangle())` applied alongside `.frame(minHeight:)` in `ButtonFacade`. `.contentShape` was the actual key — `.frame(minHeight:)` only resized the outer container; XCUITest reads the inner Button's AX hit-rect which stayed at ~25pt without `.contentShape`.

Two failures remain deferred:

## The 2 remaining failures

### BX3 — Toggle synthetic tap doesn't flip SwiftUI `@State isOn`

**Deferral doc:** `docs/initiative-cross-platform-ui/handoff/phase-03-remediation-8-bx3-bx8-investigation.md`

**Symptom:** XCUITest taps the AX Switch element. The tap is reported delivered. The Toggle's underlying `BoolStorage.value` never flips. The mirror label `toggle-probe-value` stays at the initial value.

**Implementer's 4 investigation angles:**
1. Restructured `ToggleFacade` to build the Toggle inside the View body with `@ObservedObject + $storage.value`
2. Pinned default `.toggleStyle(.switch)` on iOS
3. Added `BoolStorage.suppressNextFire` + `setProgrammatically(_:)` to break a hypothesized Crystal→Swift→Crystal loop
4. Applied `.contentShape(Rectangle())` (the BX6/BX9 fix)

None propagated the tap into the binding.

**Implementer's hypothesis:** UIHostingController-in-UIViewRepresentable hit-test propagation gap **specific to value-bound SwiftUI controls**. Discrete-action controls (Button) work because the `.tap()` triggers an action closure. Value-bound controls (Toggle, Slider) need the binding to receive the value mutation — which happens inside SwiftUI's internal hit-test machinery that may not propagate cleanly through the UIViewRepresentable wrapper.

**Why I (architect) am skeptical of the hosting-topology-refactor framing:**
- Discrete-action Buttons work via the same UIHostingController-in-UIViewRepresentable pattern. The hit-test machinery DOES propagate at least for closure-fire taps.
- It seems unlikely that SwiftUI's internal binding logic is *categorically* unreachable through the hosting wrapper — value-bound controls work fine in pure SwiftUI apps that nest UIHostingControllers.
- 4 angles tried but none looked at the actual UIHostingController -> SwiftUI tap routing internals (e.g. examining the `_UIHostingView` AX adapter, checking if `XCUITest.tap()` goes through `UITouch` events vs accessibility-action invocation, examining the `UIAccessibility.notification(.layoutChanged)` flow).

### BX8 — Sheet slug crashes at launch (NULL/use-after-free String pointer)

**Deferral doc:** Same handoff as BX3.

**Symptom:** Launching the iOS host with `HIG_SLUG=phase-03-sheet-focus-return` crashes during initial render. `EXC_BAD_ACCESS` at `0x0` in `_platform_strlen` called from `apsk_nsstring` called from `apsk_make_label_reactive`.

**Implementer's investigation:**
1. NULL-guarded `apsk_nsstring` (Swift side) and Crystal-side label populator — insufficient. The C `text` pointer arrives non-NULL but pointing to freed memory (use-after-free).
2. Crashes only on the sheet slug because it's the only slug that routes labels through `render_detached` (which presumably builds a detached view tree whose Crystal strings get GC'd before the SwiftUI render reads them).
3. Detoured via `libc malloc` to copy strings into stable buffers — regressed to a different crash inside `visit<UI::Label>`, hypothesized as Crystal-iOS `String#bytesize` ABI gap with BoehmGC.
4. Reverted to local-pin (current state).

**Implementer's hypothesis:** Memory-lifetime issue with Crystal Strings whose C pointers persist past the original Crystal scope into the SwiftUI hosting render. Specific to `render_detached`'s detached-tree handling.

**Why I'm skeptical of the "deep Crystal/iOS ABI" framing:**
- The same `apsk_make_label_reactive` works for all other slugs. Only `render_detached` triggers the crash. That implicates the detached-render path, not the bridge.
- "Use-after-free" is a specific diagnosis; the Implementer didn't show a memory-sanitizer log or `lldb` backtrace proving it. Could also be: pointer to a Crystal String that was reassigned, garbage in the C struct's text field from uninitialized stack space, or `text` being read at the wrong offset in a Swift struct.
- The "different crash after malloc copy" claim suggests the issue mutated under the workaround — which could mean the workaround was wrong, or could mean there's a chain of two separate issues.

## What I'd like Codex to assess

1. **For BX3:** Is the "UIHostingController-in-UIViewRepresentable hit-test propagation gap specific to value-bound controls" framing technically correct? If so, what's the canonical iOS pattern to fix it (without rebuilding the hosting topology)? If not, what's the actual root cause and what's the missing fix?

2. **For BX8:** Is the "Crystal String C pointer use-after-free in `render_detached`" framing technically correct? What's the actual diagnostic step we're missing (lldb? Address sanitizer? Inspect the Crystal `render_detached` path)? Is there a smaller fix at the `render_detached` call site, or is this really a Crystal-iOS ABI issue?

3. **Broader review of the Phase 3 plan:** Looking at the README + the 25 commits + the failure cascade across iters 1-6, what fundamental thing did the original Phase 3 brief miss? Was reactivity the only major scoping gap, or were there others I haven't identified? What should the Phase 3 README have said upfront to prevent the 8-remediation cascade?

4. **Forward path recommendation:** Given the current state (44 + 3 = 47/49 PASS, 2 substantive deferrals), do you (Codex) agree that BX3 and BX8 require architectural-scope work (Phase 5+ or upstream toolchain), or do you see fixes that fit in a focused Remediation 9?

The goal is independent perspective on a project where the architect (me) keeps missing layers and would benefit from a different model's fact-check.
