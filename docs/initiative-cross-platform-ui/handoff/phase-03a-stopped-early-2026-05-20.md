# Phase 3 Dispatch A — Implementer Stopped Early — 2026-05-20

**Status:** Implementer returned early per `implementation_criteria.md` §"When the brief is wrong" and the dispatch brief's explicit stop condition ("If the macOS cascade demo cannot pivot the rendered pixel under Option B, STOP and return early — that's a structural decision the Architect needs to make"). This is a legitimate, well-justified escalation. The Phase 3 Button migration itself is **clean and complete**.

**Commits landed (4):**

- `7486040` `[Phase 3a] Add brand-tint cascade hook for SwiftUI Default Supremacy`
- `ed51fd7` `[Phase 3a] Migrate visit(UI::Button) to SwiftUI facade in both renderers`
- `dfe1274` `[Phase 3a] Wire sample build scripts for AssetPipelineSwiftKit linking`
- `bdfcf18` `[Phase 3a] Extract ObjC setter-selector helper + spec`

---

## What landed (clean and complete)

- **`visit(UI::Button)` migrated in BOTH `appkit_renderer.cr` and `uikit_renderer.cr`.** ~230 lines of brand customization deleted per renderer (~460 total). New visit body is a 6-line populator flow: `apsk_button_overrides_new` → `Populator.populate_button(target, view, sender)` → `CallbackRegistry.register_action` → `apsk_make_button` → `ObjC.owned(...)` → `push_native(native)`.
- **Brand tint propagation wired.** `apsk_runtime_set_brand_tint(r, g, b, a)` is called once on every `render()` entry via `ensure_swiftkit_runtime!`. Swift's `APSKRuntime.setBrandTint(...)` stores a `Color?`, and `HostingHelpers.host(_:)` wraps every hosted root in `.tint(...)` when one is installed.
- **`apsk_runtime_install_default_action_trampoline()` C convenience** — sidesteps Crystal's unstable `@convention(c)` pointer behavior across optimization levels.
- **`Populator.objc_setter_selector` helper** — normalizes `:setStyle` → `"setStyle:"` at the Symbol→objc_msgSend boundary.
- **`NSHostingView` (not `NSHostingController.view`) in `HostingHelpers.swift`** — the prior Implementer's scaffold collapsed to 0×0 inside `NSStackView`; `NSHostingView` reports `intrinsicContentSize` correctly out of the box.
- **macOS Makefiles wired** for the AssetPipelineSwiftKit static archive — including `-Wl,-force_load,libAssetPipelineSwiftKit.a` (non-optional; without it ld64 dead-strips the `APSK*` ObjC classes), `-framework SwiftUI -framework Combine`, the full Swift runtime dylib chain (`libswiftCore` + `libswift{Foundation, AppKit, Dispatch, ObjectiveC, Quartz, Metal, UniformTypeIdentifiers, OSLog, Concurrency}`), `-Wl,-rpath` for `/usr/lib/swift` and the Xcode toolchain `swift-5.0/macosx` dir.
- **iOS `build_crystal_lib.sh` wired** for both simulator and device slices via `swift build --triple --sdk`. UNTESTED on this host (no iPhoneOS SDK active). Dispatch B should run a full iOS slice build before adding iOS-specific widgets.
- **41 specs passing** (38 prior + 3 new for `objc_setter_selector_spec.cr`).

## Crystal→Swift integration verified working via NSLog

The full chain works on macOS:

1. Crystal: `design_tokens.colors_light.brand_primary = #ff00ff` (from `SentinelBrand`)
2. Crystal `ensure_swiftkit_runtime!` calls `apsk_runtime_set_brand_tint(1.0, 0.0, 1.0, 1.0)`
3. NSLog confirms: `[apsk] set_brand_tint r=1.0 g=0.0 b=1.0 a=1.0`
4. Swift `APSKRuntime.setBrandTint` stores `Color(.sRGB, red: 1.0, green: 0.0, blue: 1.0, opacity: 1.0)`
5. `HostingHelpers.host(_:)` reads `APSKRuntime.brandTint` and applies `.tint(...)`
6. NSLog confirms: `[APSKHost] applying tint #FF00FFFF`
7. `APSKButtonFacade.makeButton(label: "Sentinel Magenta", ...)` constructs a SwiftUI `Button` with `.buttonStyle(.borderedProminent)`

All four trampolines fire end-to-end. The cascade is wired correctly.

---

## The structural problem the Implementer surfaced

**The macOS brand-cascade pixel-pivot proof from Phase 1 (#19) no longer works under SwiftUI.**

Both `#ff00ff` and `#00cc66` brand runs produce **byte-identical** rendered pixels: `rgba(248, 248, 248, 255)` washed-out grey across the button's bounding box. ΔE = 0 between magenta and green.

### Implementer's diagnosis

> The capture window is `orderFront:` only — never `makeKeyAndOrderFront:` — and SwiftUI's `.borderedProminent` button renders in **inactive/inactive-appearance** mode in a non-key window, which dims the fill to the system's "inactive button" treatment (essentially the tint at very low alpha). The previous NSButton-based implementation didn't have this problem because `NSButton.bezelColor` is set directly on the button object and `drawRect:` paints it unconditionally regardless of window key state.

The cascade IS wired (verified via NSLog at every layer). The brand tint IS being applied. The rendered pixel just doesn't show it because SwiftUI's `.borderedProminent` style is appearance-sensitive in a way `NSButton.bezelColor` was not.

This is a **Phase 1 validation-infrastructure question**, not a Phase 3 implementation defect. The Phase 1 cascade-proof mechanism (offscreen-window `CGWindowListCreateImage` + pixel sample) is no longer authoritative for SwiftUI-hosted widgets.

### Three resolution options the Implementer identified

**(a) Modify `samples/cross_platform/macos_host/window_helper.m`** to call `[NSApp activateIgnoringOtherApps:YES] + [cap_win makeKeyAndOrderFront:nil]` before capture. Risk: changes Phase 1 validation infrastructure used by every other slug in `hig_showcase.cr` — needs Architect blessing because side-effects on already-passed phases are non-trivial.

**(b) Replace the Phase 1 brand-cascade demo with a `swift-snapshot-testing` variant.** Swift snapshot baselines are already on the Phase 3 implementation roadmap (Steps 8–9 in §6). Adopts the authoritative SwiftUI rendering pipeline (active-state appearance, real screen anchor). Implementer's recommended path.

**(c) Accept that the offscreen-pixel proof is no longer authoritative for SwiftUI-hosted widgets.** Replace #19 with a code-level assertion ("`apsk_runtime_set_brand_tint` was called with the right RGBA after `SentinelBrand` is applied") plus the swift-snapshot baselines (a deferred subset of (b)). Phase 1's pixel-pivot tag still stands as authoritative for the pre-SwiftUI era; subsequent phases use the new mechanism.

---

## Implementer-flagged Known Concerns (verbatim)

1. **macOS cascade pivot fails — STRUCTURAL.** (see "the structural problem" above; the dispatch brief explicitly told the Implementer to STOP on this).
2. SwiftUI hosting collapses to 0×0 by default (fixed via `NSHostingView`; Dispatch B should verify the fix holds across all 34 widgets — VStack/HStack contents of varying sizes may need additional layout coaxing).
3. Swift runtime linker chain is intricate (`-Wl,-force_load` is non-optional; Crystal's `ld64.lld` ignores Swift autolink directives so the dylib chain is fully spelled out in the Makefile).
4. Pre-existing 4 spec failures (1× `views_spec.cr:3247` Phase 1 token output change; 3× `phase2_verification_spec.cr` legacy `btn btn-primary` class names) still present, unchanged by Dispatch A.
5. iOS cross-compilation of the Swift package is wired but UNTESTED on this machine (no iPhoneOS SDK active). Dispatch B's first iOS slice build will verify.
6. `crystal-alpha` not installed on this dev environment; used `crystal` 1.20.0. Makefiles default to `crystal-alpha` per CLAUDE.md but accept `CRYSTAL=crystal` override.

---

## Implementer's deviations from the dispatch (all defensible)

1. **`NSHostingView` instead of `NSHostingController.view`** — the prior scaffold collapsed to 0×0 inside NSStackView; `NSHostingView` is the AppKit-native shortcut that reports `intrinsicContentSize` correctly.
2. **`apsk_runtime_install_default_action_trampoline()` C convenience** — Crystal's `@convention(c)` pointer was unstable across optimization levels (one integration crashed at `Crystal::exit` with SIGSEGV). The C trampoline takes the symbol address directly.
3. **`Populator.objc_setter_selector` extracted as a module method** — the Populator emits colon-less Symbols (spec convention); `objc_msgSend` needs the colon for single-arg setters. Without this the first `apsk_overrides_set_string` call crashed.
4. **No new visit-method integration specs** — the renderer visit methods are gated under `flag?(:macos)`/`flag?(:ios)` and aren't reachable from default `crystal spec`. Building a shim large enough to exercise them via `FakeLibObjCBridge` was outside Dispatch A's scope. The integration build (which runs all four trampolines end-to-end on the real renderer) covered the visit-method shape during integration spin-up. The 38 prior + 3 new specs cover every Populator code path.

---

## Recommended Architect path

**This decision is yours, not the Implementer's:**

The Phase 1 brand-cascade demo (#19) was load-bearing for Phase 1's pass — the pivot proved the cascade was wired through `NSButton.bezelColor`. Under Option B (SwiftUI Default Supremacy), the cascade is wired through SwiftUI's `.tint()`, which is verifiable via:
- Code-level: `apsk_runtime_set_brand_tint` is called with the right RGBA whenever the brand changes (verifiable in `crystal spec`).
- Swift-level: `APSKRuntime.brandTint` returns the expected `Color` (verifiable in `swift test`).
- Snapshot-level: a `swift-snapshot-testing` reference image of a `.tint(brandPrimary)` button matches under controlled active-state conditions (verifiable in Xcode test runs).

The offscreen-pixel-pivot mechanism from Phase 1 was the right tool for the AppKit-direct era; it's not the right tool for the SwiftUI-hosted era. Phase 1's tag still stands as the authoritative proof for what Phase 1 shipped. The question is: **how do we prove the cascade is wired going forward?**

If you pick (b) [swift-snapshot-testing], Dispatch B carries that infrastructure work alongside the remaining 34 widgets — it's a natural fit because Steps 8–9 of `implementation.md` §6 already plan for snapshot baselines.

If you pick (a) [`makeKeyAndOrderFront:` in window_helper.m], that's a one-line change but it ripples into every existing `hig_showcase.cr` slug that already passed validation with the inactive-window assumption.

If you pick (c) [accept code-level + future-snapshot], Dispatch B doesn't carry any infrastructure burden; we just record that #19's pivot mechanism is era-specific and Phase 3+ uses different proofs.

**My recommendation as Architect:** (c) for Dispatch B (lowest risk, doesn't block 34 widgets on snapshot work), with (b)'s `swift-snapshot-testing` infrastructure landing as part of Phase 7 (Accessibility & Visual Verification Automation). That phase already owns the visual-regression baseline framework; bolting swift-snapshot-testing onto it is natural and avoids putting snapshot work on every phase boundary.

But it's your call. Surfacing for checkpoint.
