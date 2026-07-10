
# Phase 3 — Implementer Briefing: SwiftUI Native Bridge

**Audience:** the implementer agent spawned for Phase 3.
**Read first:** `README.md` (this folder), then `../../rubric/implementation_criteria.md`, then this file.
**Branch:** `phase-03-swiftui-native-bridge` (already created by the Architect from the latest `feature/utility-first-css-asset-pipeline`; do not branch further).
**Validator contract:** `validation.md` (same folder). Do not read it cover-to-cover before starting; skim once to know what evidence the validator will demand, then implement against this briefing.

---

## 1. Goal

Build a Swift companion library at `swift/AssetPipelineSwiftKit/` that exposes one `@objc`-callable facade per Tier 1/Tier 2 widget. Each facade constructs the SwiftUI view, applies an `Overrides` object whose every field is `nil`-by-default (modifiers only apply when the field is set), wraps the result in a `UIHostingController` (iOS) or `NSHostingController` (macOS), and returns the controller's `.view` as a `UIView`/`NSView` pointer. Refactor `uikit_renderer.cr` and `appkit_renderer.cr` so that every visit method for a migrated widget stops constructing raw `UIButton`/`NSButton`/`UIStackView`/`NSStackView` etc., and instead populates an overrides object and calls into the Swift facade. Add an action-dispatch contract so button taps, toggle changes, etc., reach the Crystal `on_tap` / `on_change` proc through a `@convention(c)` callback. Update the iOS and macOS sample build scripts to compile and link the Swift companion.

When done, a `UI::Button.new("Save")` with no other settings rendered on iOS shows a SwiftUI default Button (system blue tint, system font weight, default insets, hover/press animations, accessibility traits, dynamic type, dark-mode adapt). Setting `view.background_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)` produces a red-background button that still uses SwiftUI typography, default radius, and default insets. Setting `view.corner_radius = 0.0` produces a square-cornered button without changing other defaults. iOS 26+ Liquid Glass appears automatically on `GlassBackground` and `NavigationStack` surfaces. The author writes against the platform-agnostic Crystal `UI::*` types; the bridge does the platform tailoring.

This is the highest-risk phase. Two remediation loops are budgeted.

---

## 2. Pre-reading checklist

Before writing any code, read in this order:

- [ ] `README.md` (this folder) — phase scope, architecture, risk notes.
- [ ] `../../MASTER_PLAN.md` — North Star and tier model.
- [ ] `../../rubric/implementation_criteria.md` — universal standards.
- [ ] `../phase-01-design-token-foundation/implementation.md` §4.2 (`AppleGenerator` → Swift). Phase 1 ships `src/ui/design_tokens/dist/AssetPipelineTokens.swift` — your Swift companion imports that file directly. Confirm it exists before starting; if it does not, **stop and return early** to the team lead.
- [ ] `src/ui/view.cr` lines 95–140 — the `UI::View` base class properties. The override fields (`padding`, `background`, `corner_radius`, `shadow_*`, `border_*`, `blur_radius`, `minimum_*`, `maximum_*`, `opacity`, `hidden`, `test_id`) are common to every widget. Per-widget overrides come from the widget's own properties (`Button#font`, `Button#foreground_color`, etc.).
- [ ] `src/ui/views/button.cr` and `src/ui/views/toggle.cr` — representative widgets being migrated. Read every property; each one either drops out as nil (use SwiftUI default) or maps to an override field.
- [ ] `src/ui/renderers/uikit_renderer.cr` lines 1–300 and the visit method index at line numbers in §6 below. Skim every visit method whose widget is in the migration list; the refactor replaces the body, not the signature.
- [ ] `src/ui/renderers/appkit_renderer.cr` — same approach. Note that `amber_brand_gold` and other ad-hoc helpers are removed when their visit method goes through the Swift facade; the Swift side reads brand tokens from `AssetPipelineTokens`.
- [ ] `src/ui/native/objc_bridge.m` lines 1–100 — the existing ObjC bridge convention (no ARC, raw `void*` pointers). Your Swift facade returns objects through this same convention; the Crystal side already knows how to receive a `UIView*` pointer.
- [ ] `samples/cross_platform/ios_host/build_crystal_lib.sh` — iOS build script. You will add Swift compilation steps to it.
- [ ] `samples/cross_platform/macos_host/Makefile` — macOS build. You will add Swift compilation steps.
- [ ] `samples/cross_platform/ios_host/hig_bridge.cr` — example of the runtime initialization sequence on iOS.

Do not read this phase's `validation.md`. The validator owns that.

---

## 2a. Existing infrastructure to use (vs. rebuild)

Phase 3 is the highest-integration phase in the initiative. Treat the existing repository as the trunk you graft Swift companion code onto — not as a blank slate. Inventory below; any file path that is **NEW** is created by this phase, every other path already exists.

### Crystal source you extend (do not replace)

- `src/ui/view.cr` — `UI::View` base class. The override fields the Swift `ViewOverrides` mirrors (`padding`, `background`, `corner_radius`, `shadow_*`, `border_*`, `opacity`, `hidden`, `minimum_*`, `maximum_*`, `test_id`) live here. Read once; do not modify property defaults.
- `src/ui/views/*.cr` — 70+ widget definitions already exist (Button, Toggle, Label, VStack/HStack/ZStack, Form, Picker, Slider, Stepper, TextField, NavigationStack, TabView, Card, GlassBackground, Sheet, Popover, ConfirmationDialog, etc.). Run `ls src/ui/views/` against §6's coverage list before starting; every widget you migrate must already have a `*.cr` file. If §6 lists a widget and the file is missing, **stop and return early** — the brief is wrong.
- `src/ui/renderers/uikit_renderer.cr` — iOS visitor. You refactor the visit methods listed in §6 in place; you do not create a new renderer.
- `src/ui/renderers/appkit_renderer.cr` — macOS visitor. Same pattern.
- `src/ui/renderers/web_renderer.cr` and `src/ui/renderers/android_renderer.cr` — **do not touch these**. SwiftKit is Apple-only. The web and Android renderers must remain bit-for-bit identical after this phase (verified by B8 / B9 in `validation.md`).
- `src/ui/native/objc_bridge.m` — existing ObjC trampoline. Add `objc_send_ulong_ret_id` here (§9 Step 1); the file is compiled with `clang -c ... -fno-objc-arc`. Do not enable ARC.
- `src/ui/native/callback_registry.cr` — existing callback indirection. Extend with `register_action`, `register_action_with_value`, `invoke`, and the exported `ap_swiftkit_invoke_action` trampoline (§8.1).
- `src/ui/native/lib_objc_runtime.cr` and `src/ui/native/native_handle.cr` — already define `LibObjCBridge` and the handle lifecycle. The new `objc_send_ulong_ret_id` `fun` binding is added to the `lib LibObjCBridge` block here, not to a new lib.

### Crystal source you create

- `src/ui/native/lib_swiftkit_bridge.cr` — **NEW**. Typed wrapper around the `objc_msgSend` calls to the SwiftKit facades. This is what §7.4 calls `LibSwiftKitBridge`. The wrapper lives alongside `lib_objc_runtime.cr`; do not call SwiftKit through raw `LibObjCBridge` from the renderer visit methods.
- `spec/ui/renderers/swiftkit/` — **NEW** spec directory mirroring the new Swift bridge surface.
- `spec/support/fake_lib_objc_bridge.cr` — **NEW** (§9 Step 8a). Read `spec/spec_helper.cr` to see how existing support files are required; follow the same pattern.

### Swift companion (entirely new)

- `swift/AssetPipelineSwiftKit/` — **NEW** top-level directory. No Swift code in the repo predates this phase; you are adding the first Swift package.
- The Swift package depends on Phase 1's generated `src/ui/design_tokens/dist/AssetPipelineTokens.swift`. If Phase 1 has not landed, **stop and return early**.

### Sample apps you extend (do not replace)

- `samples/cross_platform/ios_host/` — existing Xcode project + Crystal bridge:
  - `build_crystal_lib.sh` — build script. You insert Step 1b (Swift build) between Step 1 and Step 2 of the existing script. Read top to bottom before editing.
  - `project.yml` — XcodeGen input. **Pinned constraints to preserve:** `EXCLUDED_ARCHS[sdk=iphonesimulator*]: x86_64` (Crystal compiles arm64 only), `deploymentTarget.iOS: "26.0"` (matches the Liquid Glass requirement; do not lower).
  - `hig_bridge.cr` — Crystal-side runtime initialization. Action-trampoline registration call (§8.3) goes after the existing `GC.init` call here.
  - `Sources/CrystalHIGHostApp.swift`, `Sources/ContentView.swift`, `Sources/CrystalBridge.swift` — Swift host app. Bridging header is `Sources/CrystalHIGHost-Bridging-Header.h`. Do not rename.
  - `UITests/HIGVisualTests.swift` — existing XCUITest that drives `HIG_SLUG` + `HIG_APPEARANCE` via `app.launchEnvironment`. Phase 3 reuses this harness for visual verification (no new XCUITest target needed).
- `samples/cross_platform/macos_host/` — existing AppKit host:
  - `Makefile` — already drives `crystal build` + `clang` + linker. Add Swift build target per §9 Step 2. Preserve `CODESIGN_IDENTITY` macro (TCC permissions depend on stable signing identity).
  - `hig_showcase.cr` — Crystal entry. Action-trampoline registration (§8.3) goes after `GC.init` here.
  - `window_helper.m` — AppKit `NSApplication`/`NSWindow` bootstrap. Do not edit.

### Test infrastructure you reuse (do not replicate)

- `src/ui/ax_test/` and `src/ui/ax_test.cr` — Crystal-native UI testing via macOS Accessibility API (`AXUIElement`). Already used by `spec/ui/hig_validation/macos_visual_spec.cr`. Phase 3's macOS visual checks and any future action-dispatch behavior checks should drive the running sample through this framework; do not roll new AXUIElement bindings.
- `spec/ui/hig_validation/macos_visual_spec.cr` — example pattern for launching the macOS host with `HIG_SCREENSHOT_PATH` + `HIG_SLUG`, waiting for AX-tree readiness, and capturing. Mirror this pattern for any new macOS behavior spec.
- `spec/ui/native/callback_registry_spec.cr` — already exists. The new `register_action` / `register_action_with_value` / `invoke` tests append here, not in a new file.
- `spec/spec_helper.cr` — already auto-requires `spec/support/**`. New support files (the fake `LibObjCBridge`) are auto-loaded; you do not need to add a new `require` line.
- `scripts/run_ios_hig_tests.sh` — wraps `xcodebuild test` with the per-slug environment dance. Use this script for any iOS-simulator capture; do not write a new XCUITest runner.

### Pinned versions and environment

Hardcode these in `Package.swift`, build scripts, and any environment-check spec. The validator will confirm; the implementer must not float.

| Tool | Version | Where it is referenced |
|---|---|---|
| Crystal compiler | `crystal-alpha` (`/opt/homebrew/bin/crystal-alpha`, currently 1.20.0-dev) | All build scripts; do not switch to upstream Crystal. |
| Xcode | 16.0+ (Swift 5.9+, iOS SDK 26 present) | `project.yml` deploymentTarget; macOS Makefile assumes `xcrun --sdk macosx` resolves to 14+ SDK. |
| iOS simulator runtime | `com.apple.CoreSimulator.SimRuntime.iOS-26-2` | V6 Liquid Glass cascade check; sample build target. |
| iOS simulator device | `iPhone 17 Pro` | Standard target across the initiative. Match Scribe's pinned name. |
| swift-snapshot-testing | `1.17.x` (`.upToNextMinor(from: "1.17.0")`) | Phase 3 `Package.swift`; Phases 6 and 7 assume same minor. |
| AppKit codesign identity | `Developer ID Application: AgentC Consulting LLC (PXDF92M2T4)` | Makefile `CODESIGN_IDENTITY`. Do not change; TCC grants tied to it. |

### Conventions enforced project-wide

- **`test_id`** — every widget already carries a `property test_id : String? = nil` on `UI::View`. The renderer emits `data-testid` (web), `setAccessibilityIdentifier:` (UIKit), `setAccessibilityIdentifier:` (AppKit), `setContentDescription:` (Android). Your refactored visit methods must continue to honor `test_id` through the new Overrides plumbing (`accessibilityIdentifier` field on `ViewOverrides`).
- **`-Dmacos`, `-Dios`, `-Dandroid` flags** — platform-gated Crystal code uses `{% if flag?(:macos) %}` / `flag?(:ios)`. The Swift companion is only reachable from `flag?(:ios) || flag?(:macos)` code paths. Do not check `flag?(:darwin)` — the repo convention is the more specific flag.
- **Spec file location** — new specs mirror source paths. `src/ui/renderers/uikit_renderer.cr` Swift facade calls → `spec/ui/renderers/swiftkit/*_spec.cr`. Crystal's `crystal spec` auto-discovers `spec/**/*_spec.cr` from repo root; you do not register specs anywhere.
- **No `puts` / `pp`** — universal implementation criteria. Use `Log.info { ... }` if you must log from a Crystal renderer; from Swift, use `os_log` (already imported by SwiftUI).

### What is genuinely new vs. extended

| New | Extended |
|---|---|
| `swift/AssetPipelineSwiftKit/` (entire Swift package) | `src/ui/renderers/uikit_renderer.cr`, `src/ui/renderers/appkit_renderer.cr` |
| `src/ui/native/lib_swiftkit_bridge.cr` | `src/ui/native/objc_bridge.m`, `src/ui/native/callback_registry.cr` |
| `spec/ui/renderers/swiftkit/` (entire directory) | `spec/ui/native/callback_registry_spec.cr` |
| `spec/support/fake_lib_objc_bridge.cr` | `samples/cross_platform/ios_host/build_crystal_lib.sh`, `samples/cross_platform/macos_host/Makefile` |
| Action-trampoline registration call site in each sample | `samples/cross_platform/ios_host/hig_bridge.cr`, `samples/cross_platform/macos_host/hig_showcase.cr` |

If you find yourself about to create a file not on the "New" list, stop. You are likely duplicating something that exists.

---

## 3. Architecture overview

The bridge has three layers:

```
        Crystal UI::View tree
                |
                v
   uikit_renderer.cr / appkit_renderer.cr
   (visit methods build an Overrides struct,
    call the Swift facade through objc_msgSend)
                |
                v
   AssetPipelineSwiftKit  (Swift companion)
   - @objc class XOverrides : NSObject { ...nullable props... }
   - @objc public static func makeX(label:, overrides:, actionToken:) -> UIView
   - Conditional modifier application
   - UIHostingController(rootView: AnyView(...))
                |
                v
       UIView / NSView pointer (raw void*)
                |
                v
    NativeHandle (Crystal) — owned, lifecycle tracked
                |
                v
   Parent container's addSubview: / addArrangedSubview:
```

Action dispatch flows the other direction:

```
   UIControl event (button tap, toggle toggle, slider drag-end)
                |
                v
   Swift @objc selector on a CallbackTrampoline class
   (holds the actionToken: UInt64)
                |
                v
   Calls registered @convention(c) function pointer
   `(token: UInt64, value: Float64) -> Void`
                |
                v
   Crystal callback registry resolves the token to
   a Proc(...) and invokes it on the main thread
```

The Crystal callback registry already exists at `src/ui/native/callback_registry.cr`. The phase extends it with a `register_action(proc) -> UInt64` API and an exported `ap_swiftkit_invoke_action` function the Swift side calls.

---

## 4. Swift companion package layout

### 4.1 Directory structure

Add a new top-level directory `swift/AssetPipelineSwiftKit/`:

```
swift/AssetPipelineSwiftKit/
  Package.swift
  Sources/
    AssetPipelineSwiftKit/
      AssetPipelineSwiftKit.swift          # umbrella: imports + runtime init
      Tokens.swift                         # imports AssetPipelineTokens.swift
      CallbackBridge.swift                 # action dispatch trampoline
      HostingHelpers.swift                 # platform-conditional hosting controller helpers
      Overrides/
        ViewOverrides.swift                # common overrides shared by every widget
        ButtonOverrides.swift
        TextOverrides.swift
        StackOverrides.swift
        ToggleOverrides.swift
        PickerOverrides.swift
        SliderOverrides.swift
        StepperOverrides.swift
        TextFieldOverrides.swift
        NavigationStackOverrides.swift
        NavigationLinkOverrides.swift
        NavigationSplitViewOverrides.swift
        TabViewOverrides.swift
        SheetOverrides.swift
        FormOverrides.swift
        ListOverrides.swift
        CardOverrides.swift
        GlassBackgroundOverrides.swift
        ImageOverrides.swift
        ProgressViewOverrides.swift
        DividerOverrides.swift
      Facades/
        ButtonFacade.swift
        TextFacade.swift
        StackFacade.swift                  # VStack / HStack / ZStack
        ToggleFacade.swift
        PickerFacade.swift
        SliderFacade.swift
        StepperFacade.swift
        TextFieldFacade.swift              # TextField / SecureField / SearchField
        NavigationStackFacade.swift
        NavigationLinkFacade.swift
        NavigationSplitViewFacade.swift
        TabViewFacade.swift
        SheetFacade.swift
        FormFacade.swift
        ListFacade.swift
        CardFacade.swift
        GlassBackgroundFacade.swift
        ImageFacade.swift
        ProgressViewFacade.swift
        DividerFacade.swift
      Modifiers/
        CommonModifiers.swift              # apply background/cornerRadius/padding/border/shadow/opacity
    AssetPipelineTokens/
      AssetPipelineTokens.swift            # SYMLINK or copy from phase-01 dist
  Tests/
    AssetPipelineSwiftKitTests/
      ButtonFacadeTests.swift
      ToggleFacadeTests.swift
      OverridesPropagationTests.swift
      SnapshotTests/
        default_button_ios.png             # baseline images
        default_button_macos.png
        background_override_ios.png
        ...
```

`AssetPipelineTokens.swift` is generated by phase 1; either symlink it into the Sources tree or copy on build. Pick one and document it once at the top of `AssetPipelineSwiftKit.swift`. Recommended: symlink at `swift/AssetPipelineSwiftKit/Sources/AssetPipelineTokens/AssetPipelineTokens.swift -> ../../../../src/ui/design_tokens/dist/AssetPipelineTokens.swift`.

### 4.2 `Package.swift`

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AssetPipelineSwiftKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        // Static library so the Crystal-driven build can `ar` it into
        // libhighost.a alongside libobjc_bridge.o and the Crystal .o files.
        .library(
            name: "AssetPipelineSwiftKit",
            type: .static,
            targets: ["AssetPipelineSwiftKit"]
        ),
    ],
    targets: [
        .target(
            name: "AssetPipelineSwiftKit",
            path: "Sources/AssetPipelineSwiftKit"
        ),
        .testTarget(
            name: "AssetPipelineSwiftKitTests",
            dependencies: ["AssetPipelineSwiftKit"],
            path: "Tests/AssetPipelineSwiftKitTests"
        ),
    ]
)
```

### 4.3 Build configurations

The Swift companion must build for three slices:

| Target | swift build command |
|---|---|
| iOS simulator (arm64) | `swift build -c release --triple arm64-apple-ios16.0-simulator --sdk $(xcrun --sdk iphonesimulator --show-sdk-path)` |
| iOS device (arm64) | `swift build -c release --triple arm64-apple-ios16.0 --sdk $(xcrun --sdk iphoneos --show-sdk-path)` |
| macOS (arm64) | `swift build -c release --triple arm64-apple-macosx13.0 --sdk $(xcrun --sdk macosx --show-sdk-path)` |

The build output path is `swift/AssetPipelineSwiftKit/.build/<triple>/release/libAssetPipelineSwiftKit.a` plus a `.swiftmodule` directory. The Crystal sample build scripts pick up the right slice based on `BUILD_TARGET`.

### 4.4 Judgment: SwiftPM vs xcodebuild

**Decision: use Swift Package Manager (`swift build`).** Rationale:

- The build scripts already invoke `crystal build` and `clang` directly; adding `swift build` is consistent with that style. No `.xcodeproj` to maintain.
- SwiftPM's `.target` configuration is checked-in, declarative, diff-friendly. An Xcode project is a binary plist that produces noisy diffs.
- Static library output (`type: .static`) is what we need to `ar` into `libhighost.a`.
- The downside (SwiftPM cannot produce framework bundles directly) does not apply here — we want the `.a` and the `.swiftmodule`, not a framework.

The validator is told to verify both slices build via `swift build` invocations. Do not introduce an `.xcodeproj` in this phase.

---

## 5. `@objc` exposure contract

### 5.1 Judgment: `@objc` vs `@_cdecl`

**Decision: use `@objc`.** Rationale:

- The Crystal renderers already speak ObjC (`objc_send_*` wrappers in `objc_bridge.m`). Adding a parallel `@_cdecl` C-function surface duplicates the calling convention.
- `@objc` lets us pass and return `NSString *`, `UIView *`, and `NSObject` subclasses without manual marshaling.
- The Crystal side calls Swift exactly the same way it calls UIKit: `objc_getClass("APSKButtonFacade")` then `objc_send_id_id(cls, sel("makeButtonWithLabel:overrides:"), label_str, overrides_obj)`.
- ObjC selectors namespace cleanly: every Swift class exposed gets an `APSK` prefix so a future Swift class named `APSKButtonFacade` cannot collide with system classes.

`@_cdecl` is used only for the action-dispatch entry point on the Crystal side (`ap_swiftkit_invoke_action`) because the Swift side calls it as a `@convention(c)` function pointer; there is no ObjC trampoline involved.

### 5.2 Common types

```swift
// Sources/AssetPipelineSwiftKit/Overrides/ViewOverrides.swift
import SwiftUI
#if canImport(UIKit)
import UIKit
public typealias APSKPlatformView = UIView
#elseif canImport(AppKit)
import AppKit
public typealias APSKPlatformView = NSView
#endif

/// Common overrides every widget can carry. A `nil` field means the SwiftUI
/// default applies. A non-nil field means the Crystal author set the property,
/// and the corresponding modifier MUST be applied.
///
/// All numeric fields are `NSNumber?` rather than `Double?` so they bridge
/// cleanly to ObjC where `Double?` is not representable.
@objc(APSKViewOverrides)
public class ViewOverrides: NSObject {
    @objc public var backgroundColor: UIColor? = nil       // nil = SwiftUI default
    @objc public var foregroundColor: UIColor? = nil
    @objc public var cornerRadius: NSNumber? = nil         // pt
    @objc public var paddingTop: NSNumber? = nil
    @objc public var paddingLeading: NSNumber? = nil
    @objc public var paddingBottom: NSNumber? = nil
    @objc public var paddingTrailing: NSNumber? = nil
    @objc public var borderWidth: NSNumber? = nil          // pt
    @objc public var borderColor: UIColor? = nil
    @objc public var shadowRadius: NSNumber? = nil
    @objc public var shadowColor: UIColor? = nil
    @objc public var shadowOffsetX: NSNumber? = nil
    @objc public var shadowOffsetY: NSNumber? = nil
    @objc public var opacity: NSNumber? = nil              // 0..1; nil = 1
    @objc public var hidden: NSNumber? = nil               // bool-as-int
    @objc public var minWidth: NSNumber? = nil
    @objc public var minHeight: NSNumber? = nil
    @objc public var maxWidth: NSNumber? = nil
    @objc public var maxHeight: NSNumber? = nil
    @objc public var accessibilityIdentifier: String? = nil
    @objc public var accessibilityLabel: String? = nil

    @objc public override init() { super.init() }
}
```

(On macOS, `UIColor` is typedef'd to `NSColor` via a compatibility shim in `HostingHelpers.swift`. Same source pattern; one less branching site.)

### 5.3 Representative facades

Four facades are spelled out in full here. Every other widget follows the same pattern; §6 lists each one's `Overrides` fields.

#### 5.3.1 Button — simple

```swift
// Sources/AssetPipelineSwiftKit/Overrides/ButtonOverrides.swift
@objc(APSKButtonOverrides)
public class ButtonOverrides: ViewOverrides {
    @objc public var font: APSKFont? = nil                 // nil = SwiftUI .body
    @objc public var fontWeight: NSNumber? = nil           // raw Font.Weight intvalue; nil = .regular
    @objc public var role: String? = nil                   // "default" | "destructive" | "cancel"
    @objc public var style: String? = nil                  // "default" | "prominent" | "tinted" | "bordered" | "borderless"
    @objc public var disabled: NSNumber? = nil
    @objc public var symbolName: String? = nil             // SF Symbol
    @objc public override init() { super.init() }
}

// Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift
import SwiftUI

@objc(APSKButtonFacade)
public class ButtonFacade: NSObject {

    /// Build a SwiftUI Button hosted in a UIHostingController / NSHostingController.
    ///
    /// - Parameters:
    ///   - label: button title.
    ///   - overrides: nullable modifier object. Pass an empty ButtonOverrides()
    ///                to get full SwiftUI default treatment.
    ///   - actionToken: opaque token; the Swift side invokes
    ///                  `ap_swiftkit_invoke_action(token, 0.0)` on tap.
    ///                  Zero means "no action wired."
    @objc public static func makeButton(
        label: String,
        overrides: ButtonOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        var content = AnyView(
            SwiftUI.Button(label) {
                CallbackBridge.fire(token: actionToken, value: 0.0)
            }
        )

        // Style cascade. Each branch returns the system's idiomatic SwiftUI
        // style for that prominence; SwiftUI then layers in all the system
        // defaults (font, animation, focus, dynamic type, dark mode).
        switch overrides.style {
        case "prominent":   content = AnyView(content.buttonStyle(.borderedProminent))
        case "tinted":      content = AnyView(content.buttonStyle(.bordered).tint(.accentColor))
        case "bordered":    content = AnyView(content.buttonStyle(.bordered))
        case "borderless":  content = AnyView(content.buttonStyle(.borderless))
        default:            break // .automatic — SwiftUI picks per context
        }

        // Role mapping; SwiftUI's ButtonRole influences color and emphasis.
        if overrides.role == "destructive" {
            content = AnyView(SwiftUI.Button(role: .destructive) {
                CallbackBridge.fire(token: actionToken, value: 0.0)
            } label: { Text(label) })
        }

        // Per-widget overrides FIRST so common modifiers stack on top.
        if let weight = overrides.fontWeight {
            content = AnyView(content.fontWeight(Font.Weight(rawValue: weight.intValue) ?? .regular))
        }
        if let symbol = overrides.symbolName {
            content = AnyView(SwiftUI.Button(action: {
                CallbackBridge.fire(token: actionToken, value: 0.0)
            }) {
                Label(label, systemImage: symbol)
            })
        }
        if let disabled = overrides.disabled, disabled.boolValue {
            content = AnyView(content.disabled(true))
        }

        // Apply common (View-level) overrides last. CommonModifiers.apply
        // walks the ViewOverrides fields and applies only the non-nil ones.
        content = CommonModifiers.apply(content, overrides: overrides)

        return HostingHelpers.host(content)
    }
}
```

#### 5.3.2 TabView — composition

A TabView takes a variable number of tab children. SwiftUI tabs are declared in a `ViewBuilder`; the Crystal side hands the Swift side an array of pre-built child `UIView*` pointers (each one itself is a hosted SwiftUI view) and a parallel array of tab titles + tab system-image names.

```swift
// Sources/AssetPipelineSwiftKit/Overrides/TabViewOverrides.swift
@objc(APSKTabViewOverrides)
public class TabViewOverrides: ViewOverrides {
    @objc public var selectionIndex: NSNumber? = nil       // 0-based; nil = first
    @objc public var tintColor: UIColor? = nil
    @objc public override init() { super.init() }
}

// Sources/AssetPipelineSwiftKit/Facades/TabViewFacade.swift
@objc(APSKTabViewFacade)
public class TabViewFacade: NSObject {

    /// - Parameters:
    ///   - childViews: array of pre-hosted child platform views.
    ///   - titles: tab titles; count == childViews.count.
    ///   - systemImages: SF Symbol names; count == childViews.count
    ///                   (use empty string for no icon).
    ///   - overrides: TabViewOverrides.
    @objc public static func makeTabView(
        childViews: [APSKPlatformView],
        titles: [String],
        systemImages: [String],
        overrides: TabViewOverrides
    ) -> APSKPlatformView {
        precondition(childViews.count == titles.count, "child/title count mismatch")
        precondition(childViews.count == systemImages.count, "child/image count mismatch")

        let selection = overrides.selectionIndex?.intValue ?? 0

        var content = AnyView(
            SwiftUI.TabView(selection: .constant(selection)) {
                ForEach(0..<childViews.count, id: \.self) { i in
                    APSKHostedChild(view: childViews[i])
                        .tabItem {
                            if !systemImages[i].isEmpty {
                                Label(titles[i], systemImage: systemImages[i])
                            } else {
                                Text(titles[i])
                            }
                        }
                        .tag(i)
                }
            }
        )

        if let tint = overrides.tintColor {
            content = AnyView(content.tint(Color(uiColor: tint)))
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}

/// SwiftUI wrapper around an already-hosted platform view.
/// Lets the Crystal side compose pre-built children into a TabView/Form/etc.
struct APSKHostedChild: UIViewRepresentable {
    let view: APSKPlatformView
    func makeUIView(context: Context) -> APSKPlatformView { view }
    func updateUIView(_: APSKPlatformView, context: Context) {}
}
```

(On macOS substitute `NSViewRepresentable` for `UIViewRepresentable`; the `HostingHelpers.swift` file hides this with a typealias.)

#### 5.3.3 Form — children container

```swift
@objc(APSKFormOverrides)
public class FormOverrides: ViewOverrides {
    @objc public var formStyle: String? = nil              // "automatic" | "grouped" | "columns"
    @objc public override init() { super.init() }
}

@objc(APSKFormFacade)
public class FormFacade: NSObject {
    @objc public static func makeForm(
        childViews: [APSKPlatformView],
        overrides: FormOverrides
    ) -> APSKPlatformView {
        var content = AnyView(
            SwiftUI.Form {
                ForEach(0..<childViews.count, id: \.self) { i in
                    APSKHostedChild(view: childViews[i])
                }
            }
        )

        switch overrides.formStyle {
        case "grouped":  content = AnyView(content.formStyle(.grouped))
        case "columns":
            #if os(macOS)
            content = AnyView(content.formStyle(.columns))
            #endif
        default: break
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
```

#### 5.3.4 GlassBackground — modifier-heavy

```swift
@objc(APSKGlassBackgroundOverrides)
public class GlassBackgroundOverrides: ViewOverrides {
    /// One of: "thin" | "regular" | "thick" | "ultraThin" | "ultraThick".
    /// nil = "regular".
    @objc public var material: String? = nil
    /// One of: "none" | "small" | "medium" | "large" | "capsule".
    /// nil lets SwiftUI pick based on container.
    @objc public var shape: String? = nil
    @objc public var displayMode: String? = nil            // "always" | "automatic"
    @objc public override init() { super.init() }
}

@objc(APSKGlassBackgroundFacade)
public class GlassBackgroundFacade: NSObject {
    @objc public static func makeGlassBackground(
        childView: APSKPlatformView,
        overrides: GlassBackgroundOverrides
    ) -> APSKPlatformView {
        let inner = APSKHostedChild(view: childView)

        // Resolve material; .regular is the SwiftUI default.
        let material: Material = {
            switch overrides.material {
            case "ultraThin":  return .ultraThinMaterial
            case "thin":       return .thinMaterial
            case "thick":      return .thickMaterial
            case "ultraThick": return .ultraThickMaterial
            default:           return .regularMaterial
            }
        }()

        var content: AnyView
        if #available(iOS 26.0, macOS 26.0, *) {
            // iOS 26+ Liquid Glass: SwiftUI exposes `.glassBackgroundEffect()`
            // which defers to the system's Liquid Glass renderer and adapts
            // automatically to ambient color, motion, and accessibility.
            // The OS picks the polish; we just opt in.
            content = AnyView(inner.glassBackgroundEffect())
        } else {
            // Fallback for iOS 16-25 / macOS 13-25: classic background material.
            content = AnyView(inner.background(material))
        }

        // Shape override (clips the glass surface).
        switch overrides.shape {
        case "capsule":  content = AnyView(content.clipShape(Capsule()))
        case "small":    content = AnyView(content.clipShape(RoundedRectangle(cornerRadius: 8)))
        case "medium":   content = AnyView(content.clipShape(RoundedRectangle(cornerRadius: 16)))
        case "large":    content = AnyView(content.clipShape(RoundedRectangle(cornerRadius: 28)))
        default: break
        }

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(content)
    }
}
```

### 5.4 `CommonModifiers.apply`

A single helper, called at the end of every facade, applies the `ViewOverrides` fields conditionally:

```swift
// Sources/AssetPipelineSwiftKit/Modifiers/CommonModifiers.swift
import SwiftUI

enum CommonModifiers {
    static func apply<V: View>(_ view: V, overrides: ViewOverrides) -> AnyView {
        var current = AnyView(view)

        if let bg = overrides.backgroundColor {
            current = AnyView(current.background(Color(uiColor: bg)))
        }
        if let fg = overrides.foregroundColor {
            current = AnyView(current.foregroundStyle(Color(uiColor: fg)))
        }
        if let r = overrides.cornerRadius {
            current = AnyView(current.clipShape(
                RoundedRectangle(cornerRadius: CGFloat(r.doubleValue))
            ))
        }
        if overrides.paddingTop != nil || overrides.paddingLeading != nil
            || overrides.paddingBottom != nil || overrides.paddingTrailing != nil {
            let insets = EdgeInsets(
                top:      overrides.paddingTop.map { CGFloat($0.doubleValue) } ?? 0,
                leading:  overrides.paddingLeading.map { CGFloat($0.doubleValue) } ?? 0,
                bottom:   overrides.paddingBottom.map { CGFloat($0.doubleValue) } ?? 0,
                trailing: overrides.paddingTrailing.map { CGFloat($0.doubleValue) } ?? 0,
            )
            current = AnyView(current.padding(insets))
        }
        if let bw = overrides.borderWidth, let bc = overrides.borderColor {
            current = AnyView(current.overlay(
                RoundedRectangle(cornerRadius: CGFloat(overrides.cornerRadius?.doubleValue ?? 0))
                    .stroke(Color(uiColor: bc), lineWidth: CGFloat(bw.doubleValue))
            ))
        }
        if let sr = overrides.shadowRadius {
            let sc = overrides.shadowColor.map { Color(uiColor: $0) } ?? .black.opacity(0.25)
            let sx = overrides.shadowOffsetX.map { CGFloat($0.doubleValue) } ?? 0
            let sy = overrides.shadowOffsetY.map { CGFloat($0.doubleValue) } ?? 0
            current = AnyView(current.shadow(color: sc, radius: CGFloat(sr.doubleValue), x: sx, y: sy))
        }
        if let o = overrides.opacity {
            current = AnyView(current.opacity(o.doubleValue))
        }
        if let h = overrides.hidden, h.boolValue {
            current = AnyView(current.hidden())
        }
        if overrides.minWidth != nil || overrides.minHeight != nil
            || overrides.maxWidth != nil || overrides.maxHeight != nil {
            current = AnyView(current.frame(
                minWidth:  overrides.minWidth.map  { CGFloat($0.doubleValue) },
                maxWidth:  overrides.maxWidth.map  { CGFloat($0.doubleValue) },
                minHeight: overrides.minHeight.map { CGFloat($0.doubleValue) },
                maxHeight: overrides.maxHeight.map { CGFloat($0.doubleValue) },
            ))
        }
        if let id = overrides.accessibilityIdentifier {
            current = AnyView(current.accessibilityIdentifier(id))
        }
        if let lbl = overrides.accessibilityLabel {
            current = AnyView(current.accessibilityLabel(lbl))
        }
        return current
    }
}
```

### 5.5 Hosting helpers

`APSKPlatformView` is owned **exclusively** by `Sources/AssetPipelineSwiftKit/Overrides/ViewOverrides.swift` (see §5.2). Do **not** redeclare it in `HostingHelpers.swift` — Swift will reject the duplicate `public typealias`. Declare only the hosting-controller typealias here:

```swift
// Sources/AssetPipelineSwiftKit/HostingHelpers.swift
import SwiftUI

#if canImport(UIKit)
import UIKit
// APSKPlatformView is declared in ViewOverrides.swift; do not redeclare.
public typealias APSKHostingController = UIHostingController
#elseif canImport(AppKit)
import AppKit
// APSKPlatformView is declared in ViewOverrides.swift; do not redeclare.
public typealias APSKHostingController = NSHostingController
#endif

enum HostingHelpers {
    /// Wrap `view` in a hosting controller, retain the controller for the
    /// lifetime of its `.view`, and return the platform view.
    ///
    /// Crystal's NativeHandle takes ownership of the returned view pointer
    /// (+1 retain). The hosting controller is associated with the view via
    /// objc_setAssociatedObject so it lives as long as the view does.
    ///
    /// The `.frame(minWidth: 1, minHeight: 1)` defensive sizing is required
    /// (see §5.6 known risk): inside SwiftUI `Form` / `List` containers, a
    /// `UIViewRepresentable` host can collapse to zero intrinsic size on the
    /// first layout pass. The 1×1 floor keeps the intrinsic-size invariant
    /// while letting the child's real content size propagate normally.
    static func host<V: View>(_ view: V) -> APSKPlatformView {
        let sized = AnyView(view.frame(minWidth: 1, minHeight: 1))
        let controller = APSKHostingController(rootView: sized)
        let platformView = controller.view!
        // Anchor the controller to the view's lifetime.
        objc_setAssociatedObject(
            platformView,
            &kHostingControllerKey,
            controller,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return platformView
    }
}

private var kHostingControllerKey: UInt8 = 0
```

### 5.6 Judgment: hosting granularity

**Decision: one `UIHostingController` per widget facade**, as the README specifies. Rationale:

- Composition: a TabView built by `makeTabView` already contains child hosting controllers; SwiftUI handles nested representables. Replacing the per-widget pattern with per-screen would require Crystal to defer rendering until a screen root is identified, which is a much bigger refactor and breaks the "Crystal builds a view, hands the pointer to a parent" model that every existing visit method assumes.
- Overhead: nested `UIHostingController`s incur measurable allocation but the README explicitly classifies performance as a non-goal for this phase. Document the concern in the code (a one-line comment at the top of `HostingHelpers.swift`).
- Future-proof: phase 6 (demo app) may revisit per-screen hosting if profiling demands; nothing in the public Crystal API binds the decision either way.

**Known risk — nested-hosting layout pathology in `Form` / `List`:** SwiftUI re-measures the children of a `UIViewRepresentable` (which is how each child facade lands inside a parent host) on every layout pass, and inside `Form` / `List` contexts that re-measurement is unstable: the child's intrinsic content size frequently collapses to zero on first pass, then expands to the correct size on a subsequent pass, producing visible layout thrash and occasional permanently-zero-height rows. The fix is defensive sizing at the boundary. Every Swift facade's `host(...)` helper (i.e. `HostingHelpers.host(_:)` and any per-facade equivalent) **must** wrap the SwiftUI content with `.frame(minWidth: 1, minHeight: 1)` *before* handing it to `UIHostingController` / `NSHostingController`. The `1×1` floor is enough for SwiftUI to keep the intrinsic-size invariant; the child's real content size propagates through normally on the next layout pass and the floor is never visible to the user. This is a known SwiftUI quirk, not a bug in this bridge — but the bridge owns the fix because it is the only place that uniformly wraps every widget. Validators look for this `.frame(minWidth: 1, minHeight: 1)` modifier in `HostingHelpers.swift` (and any Form/List facade override).

### 5.7 Judgment: typed `Overrides` class vs `NSDictionary`

**Decision: typed `@objc class : NSObject` per widget.** Rationale:

- Compile-time field checking on the Swift side: misspelling `cornerRadius` is a build error, not a silent miss.
- Crystal-side likewise gets named selectors (`setCornerRadius:`) instead of `objectForKey:@"cornerRadius"`.
- `NSDictionary` requires every value to be boxed in `NSNumber`/`NSString` anyway, so we get no encoding wins.
- Snapshot diff readability: a typed class declares its surface up front.

---

## 6. Widget coverage list

Each widget below gets a facade, an `Overrides` class, and a refactored visit method in both `uikit_renderer.cr` and `appkit_renderer.cr`. Line numbers are current locations; the visit method body changes but the signature does not.

| # | Widget | SwiftUI equivalent | Overrides fields beyond `ViewOverrides` | Platform notes |
|---|---|---|---|---|
| 1 | `UI::Button` | `Button` | font, fontWeight, role, style, disabled, symbolName | uikit_renderer:250, appkit_renderer:239 |
| 2 | `UI::Label` | `Text` | font, fontWeight, textAlignment, numberOfLines, preferredMaxLayoutWidth, textColorRole | uikit_renderer:176, appkit_renderer:166 |
| 3 | `UI::VStack` | `VStack` | spacing, alignment | uikit_renderer:482, appkit_renderer:461 |
| 4 | `UI::HStack` | `HStack` | spacing, alignment | uikit_renderer:528, appkit_renderer:567 |
| 5 | `UI::ZStack` | `ZStack` | alignment | uikit_renderer:571, appkit_renderer:627 |
| 6 | `UI::Image` | `Image` | systemImage, resizable, scaledToFit, scaledToFill, renderingMode, tint | uikit_renderer:601, appkit_renderer:657 |
| 7 | `UI::TextField` | `TextField` | placeholder, text, font, keyboardType, autocapitalization, autocorrection, isSecure | uikit_renderer:649, appkit_renderer:706 |
| 8 | `UI::SecureField` | `SecureField` | placeholder, font | uikit_renderer:2056, appkit_renderer:1680 |
| 9 | `UI::SearchField` | `TextField + .searchable` | placeholder, font | uikit_renderer:2239, appkit_renderer:1835 |
| 10 | `UI::Toggle` | `Toggle` | isOn, label, tintColor, style, disabled | uikit_renderer:834, appkit_renderer:876 |
| 11 | `UI::Checkbox` | `Toggle(.checkbox)` (macOS); custom on iOS | isChecked, label, disabled | iOS has no native checkbox — Swift facade reproduces the SwiftUI checkbox look. uikit_renderer:911, appkit_renderer:912 |
| 12 | `UI::RadioGroup` | `Picker(.inline)` (macOS); `Picker(.segmented)` (iOS) | selectedIndex, options, label | uikit_renderer:985, appkit_renderer:944 |
| 13 | `UI::Slider` | `Slider` | value, range, step, tintColor, disabled | uikit_renderer:1104, appkit_renderer:976 |
| 14 | `UI::Stepper` | `Stepper` | value, range, step, disabled | uikit_renderer:2103, appkit_renderer:1726 |
| 15 | `UI::Picker` | `Picker` | selectedIndex, options, label, pickerStyle | uikit_renderer:1651, appkit_renderer:1419 |
| 16 | `UI::SegmentedControl` | `Picker(.segmented)` | selectedIndex, options | uikit_renderer:2146, appkit_renderer:1755 |
| 17 | `UI::DatePicker` | `DatePicker` | date, range, displayedComponents, pickerStyle | uikit_renderer:2191, appkit_renderer:1786 |
| 18 | `UI::ProgressView` | `ProgressView` | value, total, label, tintColor | uikit_renderer:1404, appkit_renderer:1216 |
| 19 | `UI::NavigationStack` | `NavigationStack` | rootChild, navigationTitle | uikit_renderer:1195, appkit_renderer:1017 |
| 20 | `UI::NavigationLink` | `NavigationLink` | label, destinationChild, navigationTitle | uikit_renderer:1214, appkit_renderer:1036 |
| 21 | `UI::NavigationSplitView` | `NavigationSplitView` | sidebarChild, detailChild, sidebarWidth, columnVisibility | iOS: 3-column collapses to stack at compact widths automatically (SwiftUI). macOS: native split behavior. uikit_renderer:2395, appkit_renderer:2026 |
| 22 | `UI::TabView` | `TabView` | selectionIndex, tintColor, children, titles, systemImages | uikit_renderer:1249, appkit_renderer:1073 |
| 23 | `UI::Toolbar` | `.toolbar { }` | items, placement | iOS toolbar items sit in navigation bar; macOS uses `NSToolbar` semantics via SwiftUI. `placement` field accepts platform-specific keys. uikit_renderer:2509, appkit_renderer:2175 |
| 24 | `UI::Form` | `Form` | formStyle, children | uikit_renderer:2324, appkit_renderer:1927 |
| 25 | `UI::ListView` | `List` | listStyle, children, selectionEnabled | uikit_renderer:1820, appkit_renderer:1515 |
| 26 | `UI::Sheet` | `.sheet(isPresented:)` | isPresented, child, detents (iOS only) | uikit_renderer:2622, appkit_renderer:2304 |
| 27 | `UI::Popover` | `.popover(isPresented:)` | isPresented, child, arrowEdge | uikit_renderer:2795, appkit_renderer:2451 |
| 28 | `UI::ConfirmationDialog` | `.confirmationDialog` | title, message, actions | uikit_renderer:2876, appkit_renderer:2517 |
| 29 | `UI::Card` (new container) | wrapper around a `VStack` inside `GlassBackground` | child, glassMaterial, contentPadding | The Crystal `Card` type already exists; refactor its visit method only. |
| 30 | `UI::GlassBackground` | `.glassBackgroundEffect()` (26+) / `.background(.regularMaterial)` (≤25) | material, shape, displayMode, childView | Tier 2 critical: this is the headline visual difference between phase-2 and phase-3 output on Apple. |
| 31 | `UI::ProgressView` (duplicate of #18 — skip) | | | |
| 32 | `UI::ActivityIndicator` | `ProgressView()` (indeterminate) | tintColor, size | uikit_renderer:1439, appkit_renderer:1242 |
| 33 | `UI::Divider` | `Divider` | (none beyond ViewOverrides) | New facade; existing visit method just emits a 1pt line — refactor to use SwiftUI's `Divider` so it tracks system separator color. |
| 34 | `UI::Spacer` | `Spacer` | minLength | uikit_renderer:801, appkit_renderer:839 |
| 35 | `UI::ScrollView` | `ScrollView` | child, axis, showsIndicators | uikit_renderer:737, appkit_renderer:781 |

Widgets explicitly NOT in scope for phase 3 (remain on raw UIKit/AppKit; phase 4 handles them):

- `UI::Alert` (Tier 3 surface; uses `UIAlertController`/`NSAlert` directly)
- `UI::TokenField`, `UI::OutlineView`, `UI::ColumnView`, `UI::ImageWell`, `UI::ColorPicker`, `UI::TimePicker` (Tier 3 macOS-only or rarely used; remain stubs)
- `UI::Grid` — SwiftUI's `Grid` has different semantics from the existing widget; revisit in phase 6
- `UI::TextArea` — kept on `UITextView`/`NSTextView` since SwiftUI's `TextEditor` lacks parity for the existing API; revisit later

---

## 7. Crystal-side calling convention

### 7.1 Building an `Overrides` object

The Crystal renderer instantiates the ObjC class through the runtime, sets each non-nil field via its setter, and passes the object pointer to the facade. Add a private helper module at the top of each renderer file:

```crystal
# In src/ui/renderers/uikit_renderer.cr (and mirrored in appkit_renderer.cr)
private module SwiftKit
  extend self

  # Allocate an APSK Overrides object of the given class name.
  #   alloc("APSKButtonOverrides") -> Void* (retained)
  def alloc(class_name : String) : Void*
    cls = LibObjCBridge.objc_getClass(class_name.to_unsafe)
    raise "Swift companion not loaded: #{class_name}" if cls.null?
    instance = LibObjCBridge.objc_send(cls, sel("alloc"))
    LibObjCBridge.objc_send(instance, sel("init"))
  end

  # Set a UIColor? field. If color is nil the field stays nil (= SwiftUI default).
  def set_color(obj : Void*, setter : String, color : UI::Color?)
    return if color.nil?
    uicolor = LibObjCBridge.nscolor_rgba(color.r, color.g, color.b, color.alpha)
    LibObjCBridge.objc_send_id(obj, sel(setter), uicolor)
  end

  # Set an NSNumber? field from a Float64? value. Nil leaves the field nil.
  def set_number(obj : Void*, setter : String, value : Float64?)
    return if value.nil?
    nsnumber_cls = LibObjCBridge.objc_getClass("NSNumber")
    boxed = LibObjCBridge.objc_send_1d_ret_id(nsnumber_cls, sel("numberWithDouble:"), value)
    LibObjCBridge.objc_send_id(obj, sel(setter), boxed)
  end

  def set_number(obj : Void*, setter : String, value : Int32?)
    return if value.nil?
    nsnumber_cls = LibObjCBridge.objc_getClass("NSNumber")
    boxed = LibObjCBridge.objc_send_long(nsnumber_cls, sel("numberWithLong:"), value.to_i64)
    LibObjCBridge.objc_send_id(obj, sel(setter), boxed)
  end

  def set_bool(obj : Void*, setter : String, value : Bool?)
    return if value.nil?
    nsnumber_cls = LibObjCBridge.objc_getClass("NSNumber")
    boxed = LibObjCBridge.objc_send_long(nsnumber_cls, sel("numberWithBool:"), value ? 1_i64 : 0_i64)
    LibObjCBridge.objc_send_id(obj, sel(setter), boxed)
  end

  def set_string(obj : Void*, setter : String, value : String?)
    return if value.nil?
    str = LibObjCBridge.nsstring_from_cstr(value.to_unsafe)
    LibObjCBridge.objc_send_id(obj, sel(setter), str)
  end
end
```

### 7.2 Calling a facade — Button example

The migrated `visit(view : UI::Button)` in `uikit_renderer.cr`:

```crystal
def visit(view : UI::Button)
  # 1. Build the overrides object.
  overrides = SwiftKit.alloc("APSKButtonOverrides")

  # ViewOverrides (inherited) — only set when the Crystal view has the property
  # set to a non-default value. The "default-detection" rule for each property:
  #   - background (Color?)     -> set if non-nil
  #   - corner_radius (Float64) -> set if != 0.0 (the type default)
  #   - padding (EdgeInsets)    -> set per-side if non-zero
  #   - opacity                 -> set if != 1.0
  #   - border_width            -> set if > 0
  #   - shadow_radius           -> set if > 0
  #   - minimum_*, maximum_*    -> set if non-nil
  #   - test_id                 -> set as accessibilityIdentifier if non-nil
  SwiftKit.set_color(overrides, "setBackgroundColor:", view.background)
  SwiftKit.set_number(overrides, "setCornerRadius:", view.corner_radius == 0.0 ? nil : view.corner_radius)
  SwiftKit.set_number(overrides, "setPaddingTop:",      view.padding.top    == 0 ? nil : view.padding.top.to_f64)
  SwiftKit.set_number(overrides, "setPaddingLeading:",  view.padding.left   == 0 ? nil : view.padding.left.to_f64)
  SwiftKit.set_number(overrides, "setPaddingBottom:",   view.padding.bottom == 0 ? nil : view.padding.bottom.to_f64)
  SwiftKit.set_number(overrides, "setPaddingTrailing:", view.padding.right  == 0 ? nil : view.padding.right.to_f64)
  SwiftKit.set_number(overrides, "setOpacity:", view.opacity == 1.0 ? nil : view.opacity)
  SwiftKit.set_bool(overrides,   "setHidden:",  view.hidden == false ? nil : view.hidden)
  SwiftKit.set_number(overrides, "setBorderWidth:", view.border_width == 0.0 ? nil : view.border_width)
  SwiftKit.set_color(overrides,  "setBorderColor:", view.border_color)
  SwiftKit.set_number(overrides, "setShadowRadius:", view.shadow_radius == 0.0 ? nil : view.shadow_radius)
  SwiftKit.set_color(overrides,  "setShadowColor:",  view.shadow_color)
  SwiftKit.set_number(overrides, "setMinWidth:",  view.minimum_width)
  SwiftKit.set_number(overrides, "setMinHeight:", view.minimum_height)
  SwiftKit.set_number(overrides, "setMaxWidth:",  view.maximum_width)
  SwiftKit.set_number(overrides, "setMaxHeight:", view.maximum_height)
  SwiftKit.set_string(overrides, "setAccessibilityIdentifier:", view.test_id)
  SwiftKit.set_string(overrides, "setAccessibilityLabel:",      view.accessibility_label)

  # Button-specific overrides — note `font` is always set if non-default,
  # but the Swift facade still falls back to SwiftUI defaults when not set.
  SwiftKit.set_string(overrides, "setRole:", view.role == :default ? nil : view.role.to_s)
  SwiftKit.set_string(overrides, "setStyle:", style_string_for(view.style))
  SwiftKit.set_bool(overrides,   "setDisabled:", view.disabled == false ? nil : true)
  SwiftKit.set_string(overrides, "setSymbolName:", view.symbol)

  # 2. Register the on_tap callback. action_token = 0 when no callback wired.
  action_token = if proc = view.on_tap
    UI::Native::CallbackRegistry.register_action { proc.call }
  else
    0_u64
  end

  # 3. Call the facade. Selector signature is one of the @objc class methods.
  cls = LibObjCBridge.objc_getClass("APSKButtonFacade")
  raise "AssetPipelineSwiftKit not loaded" if cls.null?

  label_str = LibObjCBridge.nsstring_from_cstr(view.label.to_unsafe)
  token_ns = LibObjCBridge.objc_send_ulong(
    LibObjCBridge.objc_getClass("NSNumber"),
    sel("numberWithUnsignedLongLong:"),
    action_token
  )
  ptr = LibObjCBridge.objc_send_id_id_id(
    cls,
    sel("makeButtonWithLabel:overrides:actionToken:"),
    label_str,
    overrides,
    token_ns
  )

  emit(ptr, "APSKButtonFacade")
end
```

(`emit` is the existing helper that wraps the returned pointer in a `NativeHandle`/`NativeView` and adds it to the parent stack. No change needed there.)

### 7.3 New `LibObjCBridge` bindings

Add to the `lib LibObjCBridge` block in both renderer files:

```crystal
# Used for actionToken passing.
fun objc_send_ulong_ret_id(obj : Void*, sel : Void*, val : UInt64) : Void*
```

The corresponding C wrapper goes into `src/ui/native/objc_bridge.m`:

```c
// (id, SEL, unsigned long long) -> id
void *objc_send_ulong_ret_id(void *obj, void *sel, unsigned long long val) {
    return ((id (*)(id, SEL, unsigned long long))objc_msgSend)((id)obj, sel, val);
}
```

### 7.4 `LibSwiftKitBridge` — typed wrapper around Swift facades

Alongside `LibObjCBridge`, Phase 3 ships a typed Crystal `lib LibSwiftKitBridge` block in `src/ui/native/swiftkit_bridge.cr` that exposes a typed `fun` per Swift facade. Downstream phases (Phase 5 glass material tokenization in particular) call into Swift through this bridge instead of repeating raw `objc_msgSend` plumbing in each visit method.

The lib block is the canonical Crystal-side surface for the Swift companion. Every facade in §6 has a corresponding `fun` declared here. The implementation of each `fun` is a small C trampoline in `src/ui/native/swiftkit_bridge.m` that locates the `APSK*Facade` class through the Objective-C runtime and forwards to its `@objc public static func make…` entry point. The trampolines centralize selector lookup and `actionToken` boxing so callers see a flat C ABI.

```crystal
# src/ui/native/swiftkit_bridge.cr
#
# Typed wrapper around AssetPipelineSwiftKit. Every Swift facade exposed via
# @objc has a corresponding fun here so Crystal call sites stay readable and
# typecheckable. The actual ObjC msg-send is performed by the C trampolines
# in swiftkit_bridge.m.
{% if flag?(:ios) || flag?(:macos) %}
@[Link(framework: "Foundation")]
lib LibSwiftKitBridge
  # --- Overrides constructors (one per Overrides class in §5.2 / §6) ----------

  fun view_overrides_new : Void*
  fun button_overrides_new : Void*
  fun toggle_overrides_new : Void*
  fun stack_overrides_new : Void*
  fun text_overrides_new : Void*
  fun image_overrides_new : Void*
  fun text_field_overrides_new : Void*
  fun picker_overrides_new : Void*
  fun slider_overrides_new : Void*
  fun stepper_overrides_new : Void*
  fun progress_view_overrides_new : Void*
  fun navigation_stack_overrides_new : Void*
  fun navigation_link_overrides_new : Void*
  fun navigation_split_view_overrides_new : Void*
  fun tab_view_overrides_new : Void*
  fun sheet_overrides_new : Void*
  fun form_overrides_new : Void*
  fun list_overrides_new : Void*
  fun card_overrides_new : Void*
  fun glass_background_overrides_new : Void*
  fun divider_overrides_new : Void*

  # Phase 5 promotes glass material to a dedicated overrides/facade pair. The
  # Phase 5 implementer extends THIS bridge — they do not invent a new lib.
  fun material_parameters_new : Void*
  fun glass_background_overrides_set_material(overrides : Void*, params : Void*)

  # --- Facade entry points ----------------------------------------------------

  fun make_button(label : UInt8*, overrides : Void*, action_token : UInt64) : Void*
  fun make_text(text : UInt8*, overrides : Void*) : Void*
  fun make_stack(axis : Int32, children : Void**, children_count : Int32, overrides : Void*) : Void*
  fun make_toggle(label : UInt8*, is_on : Bool, overrides : Void*, action_token : UInt64) : Void*
  fun make_image(name : UInt8*, overrides : Void*) : Void*
  fun make_text_field(placeholder : UInt8*, text : UInt8*, overrides : Void*, action_token : UInt64) : Void*
  fun make_picker(options : UInt8**, options_count : Int32, selected_index : Int32, overrides : Void*, action_token : UInt64) : Void*
  fun make_slider(value : Float64, min : Float64, max : Float64, overrides : Void*, action_token : UInt64) : Void*
  fun make_stepper(value : Float64, min : Float64, max : Float64, step : Float64, overrides : Void*, action_token : UInt64) : Void*
  fun make_progress_view(value : Float64, total : Float64, overrides : Void*) : Void*
  fun make_navigation_stack(root_child : Void*, overrides : Void*) : Void*
  fun make_navigation_link(label : UInt8*, destination_child : Void*, overrides : Void*) : Void*
  fun make_navigation_split_view(sidebar_child : Void*, detail_child : Void*, overrides : Void*) : Void*
  fun make_tab_view(child_views : Void**, child_count : Int32, titles : UInt8**, titles_count : Int32, overrides : Void*) : Void*
  fun make_sheet(child : Void*, overrides : Void*) : Void*
  fun make_form(children : Void**, children_count : Int32, overrides : Void*) : Void*
  fun make_list(children : Void**, children_count : Int32, overrides : Void*) : Void*
  fun make_card(child : Void*, overrides : Void*) : Void*
  # Phase 5 owns the glass facade. Signature: glass surface is created bare
  # from material parameters + overrides; child content is attached as a
  # subview afterward by the calling visitor (push_stack / accept / pop_stack).
  fun glass_background_facade_make(material_params : Void*, overrides : Void*) : Void*
  fun make_divider(overrides : Void*) : Void*

  # --- Runtime init (used by sample app startup) ------------------------------

  fun runtime_initialize(action_trampoline : Void*)
end
{% end %}
```

Call-site example (Crystal-side button refactor, equivalent to the §7.2 snippet but going through the typed bridge):

```crystal
overrides = LibSwiftKitBridge.button_overrides_new
# ...set fields on `overrides` via ObjC setters (helpers from §7.1)...
ptr = LibSwiftKitBridge.make_button(view.label.to_unsafe, overrides, token)
emit(ptr, "APSKButtonFacade")
```

**Bridge surface invariants:**

- Every facade in §6 must have a matching `fun` here. Adding a new facade is a two-file change: declare it in §6 (Swift companion) and add a `fun` here (Crystal bridge).
- All pointers are `Void*` at the bridge boundary; type information lives on the Swift side. The Crystal-side typing comes from wrapping each `Void*` in a `NativeHandle` immediately after the call.
- `action_token` is `UInt64`; `0` means "no callback wired."
- String arguments are NUL-terminated UTF-8 (`UInt8*`), produced by `.to_unsafe` on Crystal `String`. Array arguments take a `count` because Crystal `Slice` does not survive the C ABI boundary.
- Phase 5 references like `LibSwiftKitBridge.material_parameters_new(...)` resolve against this bridge. The Phase 5 implementer's job is to add (a) the Swift facade for material parameters and (b) the corresponding `fun` declarations in this block — they do not introduce a new lib.

The C trampolines live in `src/ui/native/swiftkit_bridge.m`. Each trampoline is one line: locate the class via `objc_getClass("APSK…")` and `objc_msgSend` the relevant selector. Patterns are mechanical; do not over-abstract.

---

## 8. Action dispatch contract

### 8.1 Token registry on the Crystal side

Add to `src/ui/native/callback_registry.cr`:

```crystal
module UI::Native::CallbackRegistry
  @@actions = {} of UInt64 => Proc(Nil)
  @@actions_with_double = {} of UInt64 => Proc(Float64, Nil)
  @@next_token : UInt64 = 1_u64
  @@mutex = Mutex.new

  # Register a no-arg callback (Button#on_tap). Returns an opaque token.
  def self.register_action(&block : -> Nil) : UInt64
    @@mutex.synchronize do
      token = @@next_token
      @@next_token += 1
      @@actions[token] = block
      token
    end
  end

  # Register a Float64-arg callback (Slider#on_change, Toggle#on_change).
  def self.register_action_with_value(&block : Float64 -> Nil) : UInt64
    @@mutex.synchronize do
      token = @@next_token
      @@next_token += 1
      @@actions_with_double[token] = block
      token
    end
  end

  # Called by Swift through @convention(c) function pointer.
  #
  # IMPORTANT: look up the proc UNDER the lock, then release the lock BEFORE
  # invoking it. User-supplied procs can be arbitrarily slow, can re-enter the
  # registry (e.g. a tap handler that registers a new action), and can perform
  # I/O. Calling them under @@mutex causes priority-inversion-style stalls and
  # deadlocks on registry re-entry.
  def self.invoke(token : UInt64, value : Float64)
    action : Proc(Nil)? = nil
    action_with_value : Proc(Float64, Nil)? = nil
    @@mutex.synchronize do
      action = @@actions[token]?
      action_with_value = @@actions_with_double[token]? if action.nil?
    end
    if a = action
      a.call
    elsif av = action_with_value
      av.call(value)
    end
  end
end

# C-callable trampoline. Swift holds a function pointer to this symbol.
fun ap_swiftkit_invoke_action(token : UInt64, value : Float64) : Nil
  UI::Native::CallbackRegistry.invoke(token, value)
end
```

### 8.2 Swift-side callback bridge

```swift
// Sources/AssetPipelineSwiftKit/CallbackBridge.swift
import Foundation

/// Pointer to the Crystal-side trampoline. Set once at startup by
/// `APSKRuntime.initialize(actionTrampoline:)`.
private var actionTrampoline: (@convention(c) (UInt64, Double) -> Void)? = nil

@objc(APSKRuntime)
public class APSKRuntime: NSObject {
    /// Called by Crystal once, immediately after the Crystal runtime is up
    /// and before any facade is invoked. Passes a C function pointer to
    /// `ap_swiftkit_invoke_action` (Crystal-exported `fun`).
    @objc public static func initialize(actionTrampoline trampoline: UnsafeRawPointer) {
        actionTrampoline = unsafeBitCast(
            trampoline,
            to: (@convention(c) (UInt64, Double) -> Void).self
        )
    }
}

enum CallbackBridge {
    static func fire(token: UInt64, value: Double) {
        guard token != 0 else { return }
        actionTrampoline?(token, value)
    }
}
```

### 8.3 Registration call site in Crystal

The renderer (or its caller — the iOS app's `crystal_render_slug` bridge function) must invoke `APSKRuntime.initialize(actionTrampoline:)` exactly once, after `GC.init`. Add to `samples/cross_platform/ios_host/hig_bridge.cr` in the `initialize_runtime` method:

```crystal
def self.initialize_runtime
  return if @@initialized
  GC.init
  install_swiftkit_action_trampoline
  @@initialized = true
end

private def self.install_swiftkit_action_trampoline
  apsk_runtime_cls = LibObjCBridge.objc_getClass("APSKRuntime".to_unsafe)
  return if apsk_runtime_cls.null?  # AssetPipelineSwiftKit not linked (e.g., unit tests)
  trampoline_ptr = ->ap_swiftkit_invoke_action(UInt64, Float64).pointer
  LibObjCBridge.objc_send_id(
    apsk_runtime_cls,
    sel("initializeWithActionTrampoline:"),
    trampoline_ptr.as(Void*)
  )
end
```

Add the analogous call to the macOS sample's startup path (in `samples/cross_platform/macos_host/hig_showcase.cr` — locate the existing `GC.init` call and follow it with `install_swiftkit_action_trampoline`).

### 8.4 Multi-arg callbacks

`Slider#on_change` (Float64) and `Toggle#on_change` (Bool) use the same trampoline; the value field carries the Float64 directly, or 1.0/0.0 for bool. The facade chooses which token registry the proc lives in based on the widget. If a future widget needs richer arguments (e.g., `Picker#on_select(Int32)`), extend the trampoline signature to `(UInt64, Float64, Int64)` and add a third registry — but do not over-engineer in phase 3. Two registries cover every Tier 1/2 widget in §6.

---

## 9. Step-by-step implementation plan

Commit boundaries are marked `▸ Commit N`. Treat each as a reviewable unit.

### Step 1. Swift package scaffold + Button facade + Button refactor

**Change:** Create the Swift package, write the four common files (`AssetPipelineSwiftKit.swift`, `HostingHelpers.swift`, `CallbackBridge.swift`, `Modifiers/CommonModifiers.swift`), write `Overrides/ViewOverrides.swift`, `Overrides/ButtonOverrides.swift`, `Facades/ButtonFacade.swift`. Refactor the `visit(view : UI::Button)` method in `uikit_renderer.cr` and `appkit_renderer.cr` to go through the facade. Add the `SwiftKit` helper module to both renderers. Add `ap_swiftkit_invoke_action` to `callback_registry.cr`.

**Files touched:**
- `swift/AssetPipelineSwiftKit/Package.swift` (new)
- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/*` (new files listed above)
- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineTokens/AssetPipelineTokens.swift` (symlink to phase 1 output)
- `src/ui/native/callback_registry.cr` — add `register_action`, `register_action_with_value`, `invoke`, and `fun ap_swiftkit_invoke_action`.
- `src/ui/native/objc_bridge.m` — add `objc_send_ulong_ret_id` if not present.
- `src/ui/renderers/uikit_renderer.cr` — add `SwiftKit` private module, refactor `visit(view : UI::Button)`.
- `src/ui/renderers/appkit_renderer.cr` — same.

**Rationale:** Button is the simplest and highest-traffic widget. Landing it first proves the end-to-end pattern (Swift facade, ObjC bridge, callback dispatch) without dragging in the composition complications of TabView/Form.

**Good output:**
- `cd swift/AssetPipelineSwiftKit && swift build -c release --triple arm64-apple-ios16.0-simulator` succeeds.
- `crystal spec spec/ui/renderers/swiftkit_button_spec.cr` (added in step 5) passes the overrides-population assertions.

▸ **Commit 1:** `[Phase 3] Add AssetPipelineSwiftKit scaffold with Button facade`

### Step 2. Sample build script updates

**Change:** Extend `samples/cross_platform/ios_host/build_crystal_lib.sh` to compile and link the Swift companion. Add equivalent steps to `samples/cross_platform/macos_host/Makefile`.

**iOS script additions (slot between Step 1 and Step 2 of the existing script):**

```bash
# ---------------------------------------------------------------------------
# Step 1b: Build AssetPipelineSwiftKit for $BUILD_TARGET
# ---------------------------------------------------------------------------
SWIFT_PKG_ROOT="$PROJECT_ROOT/swift/AssetPipelineSwiftKit"
case "$BUILD_TARGET" in
    simulator) SWIFT_TRIPLE="arm64-apple-ios${MIN_IOS_VER}-simulator" ;;
    device)    SWIFT_TRIPLE="arm64-apple-ios${MIN_IOS_VER}" ;;
esac

info "Building AssetPipelineSwiftKit for $SWIFT_TRIPLE..."
(
    cd "$SWIFT_PKG_ROOT"
    swift build -c release \
        --triple "$SWIFT_TRIPLE" \
        --sdk "$SDK_PATH"
)
SWIFT_LIB="$SWIFT_PKG_ROOT/.build/$SWIFT_TRIPLE/release/libAssetPipelineSwiftKit.a"
[[ ! -f "$SWIFT_LIB" ]] && fail "Swift companion library not produced: $SWIFT_LIB"
ok "AssetPipelineSwiftKit built: $SWIFT_LIB"
```

In Step 4 (Pack into static library) add `$SWIFT_LIB` to the `ar` inputs **or** keep `$SWIFT_LIB` as a separate `-lAssetPipelineSwiftKit` linker argument and document the choice. Recommended: keep separate — easier to debug, the Swift `.a` is `arm64`-only and bundling it with `ar rcs` produces a fat archive that still links correctly.

**macOS Makefile additions:**

```makefile
# AssetPipelineSwiftKit static library.
SWIFT_PKG_ROOT := $(SHARD_ROOT)/swift/AssetPipelineSwiftKit
SWIFT_TRIPLE   := arm64-apple-macosx13.0
SWIFT_LIB      := $(SWIFT_PKG_ROOT)/.build/$(SWIFT_TRIPLE)/release/libAssetPipelineSwiftKit.a

ext-swift: $(SWIFT_LIB)
$(SWIFT_LIB):
	cd $(SWIFT_PKG_ROOT) && swift build -c release \
		--triple $(SWIFT_TRIPLE) \
		--sdk $$(xcrun --sdk macosx --show-sdk-path)

# Add ext-swift to build, and $(SWIFT_LIB) + -lswiftCore frameworks to link flags.
MACOS_LINK_FLAGS := $(AP_BRIDGE) $(WIN_HELPER) $(SWIFT_LIB) $(MACOS_FRAMEWORKS) \
	-framework SwiftUI -framework Combine \
	-Wl,-rpath,/usr/lib/swift -Wl,-rpath,@executable_path

build: ext-ap ext-win ext-swift $(BIN)
```

Also add `clean` target updates to wipe `$(SWIFT_PKG_ROOT)/.build`.

**Files touched:**
- `samples/cross_platform/ios_host/build_crystal_lib.sh`
- `samples/cross_platform/macos_host/Makefile`

**Rationale:** Until the Swift companion is in the build, none of the refactored visit methods can run. This step gets the linker working before more widgets are migrated.

**Good output:**
- `cd asset_pipeline && ./samples/cross_platform/ios_host/build_crystal_lib.sh simulator` exits 0.
- `cd asset_pipeline/samples/cross_platform/macos_host && make build` exits 0.

▸ **Commit 2:** `[Phase 3] Link AssetPipelineSwiftKit into iOS and macOS sample builds`

### Step 3. Text + Stack widgets (Tier 1 layout primitives)

**Change:** Add facades + overrides for Label, VStack, HStack, ZStack, Spacer, Divider, Image. Refactor the corresponding visit methods in both renderers.

**Files touched:**
- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/{Text,Stack,Image}Overrides.swift`
- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/{Text,Stack,Image}Facade.swift`
- `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/DividerFacade.swift`
- `src/ui/renderers/uikit_renderer.cr` — refactor visit methods for Label, VStack, HStack, ZStack, Spacer, Divider (if a visit method exists), Image.
- `src/ui/renderers/appkit_renderer.cr` — same.

**Rationale:** Stacks are how every other widget composes. Getting stacks right early eliminates ambiguous failures later.

**Good output:**
- A composed `VStack { Label("A"); Label("B") }` renders correctly on iOS simulator with SwiftUI default spacing.
- Setting `vstack.background = UI::Color.new(r: 0.0, g: 1.0, b: 0.0)` paints the stack background green while preserving SwiftUI default spacing.

▸ **Commit 3:** `[Phase 3] Migrate Text and Stack primitives to SwiftKit facades`

### Step 4. Input widgets

**Change:** Toggle, Checkbox, Slider, Stepper, TextField, SecureField, SearchField, RadioGroup, SegmentedControl, Picker, DatePicker, ProgressView, ActivityIndicator. All facades + overrides + visit refactors.

This step also wires the **value-bearing callbacks** through `register_action_with_value`. The Swift facades for Slider/Stepper/Toggle pass the new value as the second argument when firing the trampoline.

**Files touched:**
- 12 new Swift overrides files, 12 new Swift facade files (or grouped by widget category)
- Both renderer files

**Rationale:** Inputs share the value-callback contract. Landing them together keeps that contract consistent.

**Good output:**
- Default `UI::Toggle.new(label: "Notify", is_on: true)` renders as a SwiftUI Switch with system green tint on iOS.
- Setting `view.tint_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)` produces a red switch.
- Crystal-side: dragging the slider in the iOS simulator fires `on_change` with the new value (manual verification; specs in step 8).

▸ **Commit 4:** `[Phase 3] Migrate input widgets to SwiftKit facades with value callbacks`

### Step 5. Navigation + container widgets

**Change:** NavigationStack, NavigationLink, NavigationSplitView, TabView, Form, ListView, ScrollView, Card. These widgets host **children**; the facade takes an array of pre-built `APSKPlatformView` pointers.

**Files touched:** as for previous steps; plus the `APSKHostedChild` helper struct in `HostingHelpers.swift` (already added in step 1 if you're efficient about it; if not, add now).

**Rationale:** This is the composition-heavy chunk. Once it works, the demo app's screens are renderable end-to-end.

**Good output:**
- `UI::TabView.new(children: [tab_a, tab_b])` on iOS renders as a native SwiftUI TabView with bottom tab bar; on macOS as a tab strip at the top of the window.
- Setting no overrides on a Form yields SwiftUI's grouped form style (iOS) / column layout (macOS).

▸ **Commit 5:** `[Phase 3] Migrate navigation and container widgets to SwiftKit facades`

### Step 6. GlassBackground + presentations

**Change:** GlassBackground, Sheet, Popover, ConfirmationDialog, Toolbar.

GlassBackground is the headline visual deliverable. Test on iOS 26 simulator that `glassBackgroundEffect()` is invoked when available. Sheet uses `.sheet(isPresented:)`; the Crystal `UI::Sheet` carries an `is_presented : Bool` property — the facade reads it and toggles the presentation.

**Files touched:** as before.

**Rationale:** Glass is what the user actually wants to see working. Landing it last lets the rest of the surface area be in place around it.

**Good output:**
- A `UI::Card.new(child: UI::Label.new("Hello"))` on iOS 26 shows Liquid Glass automatically; on iOS 16-25 falls back to `.regularMaterial`.
- Sheet presentation animates correctly on iOS.

▸ **Commit 6:** `[Phase 3] Migrate GlassBackground and presentation widgets`

### Step 7. Sample app verification

**Change:** Run the iOS and macOS sample apps. Confirm they build, launch, and render the existing `hig_showcase` slugs through the Swift bridge. Adjust the sample's `hig_bridge.cr` if any slug exercises a widget that needs additional facade work that step 1-6 missed.

**Files touched:** `samples/cross_platform/ios_host/hig_bridge.cr` (action-trampoline registration), `samples/cross_platform/macos_host/hig_showcase.cr` (same). Possibly small fixes to renderers.

▸ **Commit 7:** `[Phase 3] Verify iOS and macOS sample apps build and render through SwiftKit`

### Step 8a. Fake `LibObjCBridge` for spec runs without iOS frameworks

**Change:** Add `spec/support/fake_lib_objc_bridge.cr`, a Crystal spec helper that *replaces* the real `LibObjCBridge` and `LibSwiftKitBridge` in the spec environment so the renderer specs can run on a Linux CI runner (or any host without Foundation linked). The shim must:

- Record every `objc_send_*` (and `LibSwiftKitBridge.*`) call made during a spec: the selector name (or `fun` name), the ordered argument list, and the return value handed back to the caller.
- Provide an API to **assert** that a selector was sent N times with specific arguments, e.g. `FakeLibObjCBridge.assert_sent(:setCornerRadius, times: 1, args: [12.0])`.
- Provide an API to **configure stub return values** for upcoming calls (e.g. fake `objc_getClass` returns a non-null sentinel pointer; fake `*_overrides_new` returns a fresh unique pointer per call so each Overrides instance is distinguishable).
- Reset between `it` blocks (use `Spec.before_each` hook).
- Compile only under the `spec` build (gate with `{% if flag?(:spec) %}` or a similar conditional require). The real bridge is the production path; the shim must never leak into release builds.

File layout sketch:

```crystal
# spec/support/fake_lib_objc_bridge.cr
module FakeLibObjCBridge
  record Call, name : Symbol, args : Array(Object), returned : Object

  @@calls = [] of Call
  @@stub_returns = {} of Symbol => Object
  @@next_sentinel : UInt64 = 1_u64

  def self.reset
    @@calls.clear
    @@stub_returns.clear
    @@next_sentinel = 1_u64
  end

  def self.calls : Array(Call)
    @@calls.dup
  end

  def self.stub_return(selector : Symbol, value)
    @@stub_returns[selector] = value
  end

  def self.record(name : Symbol, args : Array(Object), returned)
    @@calls << Call.new(name, args, returned)
    returned
  end

  def self.assert_sent(name : Symbol, times : Int32 = 1, args : Array(Object)? = nil) : Nil
    matches = @@calls.select { |c| c.name == name && (args.nil? || c.args == args) }
    raise "expected #{name} sent #{times} times, got #{matches.size}" if matches.size != times
  end

  # Per-spec setup
  Spec.before_each { reset }
end

# Replace LibObjCBridge and LibSwiftKitBridge in spec runs.
lib LibObjCBridge
  # …no-op wrappers that delegate to FakeLibObjCBridge.record(...)
end

lib LibSwiftKitBridge
  # …no-op wrappers that delegate to FakeLibObjCBridge.record(...)
end
```

The implementer fills in the wrapper bodies; each is two lines (record the call, return the configured stub or a fresh sentinel pointer).

**Files touched:** `spec/support/fake_lib_objc_bridge.cr` (new); `spec/spec_helper.cr` (require the support file when running under spec); no production source touched.

**Rationale:** Step 8's spec files (`button_overrides_spec.cr`, etc.) all depend on this shim. Splitting it out keeps the spec commit reviewable and gives the validator a clean target to inspect the shim contract against.

**Good output:** `crystal spec spec/support/fake_lib_objc_bridge_spec.cr` (a thin sanity spec for the shim itself — assert record / reset / assert_sent / stub_return behaviors) passes. No production source changed.

▸ **Commit 8a:** `[Phase 3] Add FakeLibObjCBridge spec helper for framework-less spec runs` (sequenced before Commit 8 so the spec files in §10.1 can depend on the shim)

### Step 8. Specs

**Change:** Add Crystal specs and Swift snapshot tests. See §10.

▸ **Commit 8:** `[Phase 3] Specs for SwiftKit overrides and snapshot regression`

### Step 9. Documentation

**Change:** Update `CLAUDE.md` (repo root) with a one-paragraph "SwiftUI native bridge" section pointing to `swift/AssetPipelineSwiftKit/`, the build script changes, and the override-by-default pattern. Update the top-level `README.md` only if the public Crystal `UI::*` API has actually changed (it should not have — only the renderer internals did).

▸ **Commit 9:** `[Phase 3] Document SwiftKit bridge in CLAUDE.md`

---

## 10. Testing requirements

### 10.1 Crystal specs

Place under `spec/ui/renderers/swiftkit/` mirroring source paths.

Required spec files:

1. `spec/ui/renderers/swiftkit/button_overrides_spec.cr` — assert that `visit(view : UI::Button)` populates the `APSKButtonOverrides` object correctly. For each property: when the Crystal view leaves it at default, the corresponding Swift field stays `nil` (i.e., the setter is not called). When the Crystal view sets it, the setter is called with the correct value. Use a fake `LibObjCBridge` (a Crystal spec helper that records setter calls instead of routing them to ObjC) so the spec runs without iOS/macOS frameworks.
2. `spec/ui/renderers/swiftkit/toggle_overrides_spec.cr` — same pattern for Toggle.
3. `spec/ui/renderers/swiftkit/stack_overrides_spec.cr` — VStack/HStack/ZStack.
4. `spec/ui/renderers/swiftkit/text_overrides_spec.cr` — Label.
5. `spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr` — GlassBackground.
6. `spec/ui/renderers/swiftkit/tab_view_overrides_spec.cr` — TabView composition; assert children are passed in the correct order.
7. `spec/ui/native/callback_registry_spec.cr` — extend with `register_action` / `register_action_with_value` / `invoke` behavior. Assert token monotonicity, mutex isolation, and that invoking with an unknown token is a no-op (not a crash).
8. `spec/ui/renderers/swiftkit/default_detection_spec.cr` — central test of the "nil-when-default" rule. For each Crystal `UI::View` property listed in §7.2's comment, assert that the matched Swift setter is NOT called when the Crystal value equals the type default. This is the single most important behavioral invariant of phase 3.

### 10.2 Swift tests

Place under `swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/`.

1. `ButtonFacadeTests.swift` — render `ButtonFacade.makeButton(label: "Save", overrides: ButtonOverrides(), actionToken: 0)` and assert that the returned view's hosted SwiftUI hierarchy contains a `Button` with no `.background()` modifier. Use a small `ViewInspector`-style helper or compare the returned `_printChanges()` output.
2. `OverridesPropagationTests.swift` — exhaustive: for each ViewOverrides field, set it and confirm the corresponding modifier appears in the rendered hierarchy.
3. `SnapshotTests/` — XCTest snapshot tests. **Pin Point-Free's `swift-snapshot-testing` package at minor `1.17.x`.** In `Package.swift`, add the dependency as:

   ```swift
   .package(
     url: "https://github.com/pointfreeco/swift-snapshot-testing",
     from: "1.17.0"
   )
   ```

   and bound to the 1.17 minor line via `.upToNextMinor(from: "1.17.0")` in the `.package(url:, _:)` overload (use whichever form matches the project's existing dependency style; both produce the same resolution). 1.17.x is the canonical pin for this initiative — Phase 3 specs, Phase 6's quad-evidence snapshot tooling, and Phase 7's visual baselines all assume this exact library and minor version. Do not pick a different snapshot library; do not float to 1.18+ without a coordinated bump across all three phases.

   Baselines (committed PNGs, one per assertion):
   - `default_button_ios` — `ButtonFacade.makeButton(label: "Save", overrides: ButtonOverrides(), actionToken: 0)` snapshotted at 200×60 against `default_button_ios.png` (committed baseline).
   - `default_button_macos` — same on macOS.
   - `background_override_ios` — `overrides.backgroundColor = .red` snapshotted.
   - `corner_radius_zero_ios` — `overrides.cornerRadius = 0.0` snapshotted.
   - `glass_default_ios26` — `GlassBackgroundFacade.makeGlassBackground` on iOS 26 vs iOS 16 (separate baselines if you can run both).
4. `RuntimeBridgeTests.swift` — confirm `APSKRuntime.initialize(actionTrampoline:)` accepts a pointer and a subsequent `CallbackBridge.fire(token:value:)` invokes it.

### 10.3 Build verification

These must remain green at every commit boundary:

- `crystal spec` from repo root — full suite.
- `crystal build --no-codegen src/asset_pipeline.cr` — default web build.
- `crystal build samples/cross_platform/macos_host/hig_showcase.cr -Dmacos --no-codegen`.
- `./samples/cross_platform/ios_host/build_crystal_lib.sh simulator` — iOS simulator slice.
- `./samples/cross_platform/ios_host/build_crystal_lib.sh device` — iOS device slice (only required at the final commit; the intermediate commits can skip device-slice).
- `cd samples/cross_platform/macos_host && make build` — macOS sample.
- `cd swift/AssetPipelineSwiftKit && swift test` — Swift unit + snapshot tests.

### 10.4 Crystal runtime + Swift runtime initialization order

Documented invariant for the validator and future agents:

1. The hosting process starts (Swift `@main` on iOS app, AppKit `NSApplicationMain` on macOS sample).
2. The host calls `crystal_init` / `crystal_main` (existing entry; sets up the Crystal runtime).
3. Crystal's `Bridge.initialize_runtime` runs `GC.init`.
4. `Bridge.initialize_runtime` calls `install_swiftkit_action_trampoline`, which invokes `APSKRuntime.initialize(actionTrampoline:)` via ObjC. The Swift runtime is already up at this point because (a) Swift's runtime initializes on first Swift code execution, which happened in step 1 (the Swift host launching) and (b) the Swift companion is statically linked into the same binary.
5. Any subsequent `crystal_render_slug` invocation can safely call Swift facades.

**Failure mode to watch for:** the very first call from Crystal to Swift on iOS sometimes hits a "missing Swift runtime support library" link error if the linker did not pull in `libswiftCore`. The fix is to add `-Wl,-rpath,/usr/lib/swift -Wl,-rpath,@executable_path -framework SwiftUI -framework Combine` to the host's link flags (already in §9 step 2 for macOS; the iOS Swift host's existing project already links SwiftUI for its own SwiftUI views, so this is a non-issue on iOS).

---

## 11. Definition of done

Phase 3 is done when **every** item is true:

- [ ] `swift/AssetPipelineSwiftKit/` exists with `Package.swift`, all override classes, all facade classes, the common modifiers helper, the hosting helpers, and the callback bridge.
- [ ] The Swift companion builds clean for `arm64-apple-ios16.0-simulator`, `arm64-apple-ios16.0`, and `arm64-apple-macosx13.0` via `swift build -c release --triple <triple>`.
- [ ] Every widget in §6 has: a facade, an `Overrides` class inheriting from `ViewOverrides`, and refactored `visit` methods in `uikit_renderer.cr` AND `appkit_renderer.cr` that construct the overrides object and call the facade. No widget in §6 still constructs a raw `UIButton`/`NSButton`/`UIStackView`/etc. in its visit method (except where the implementation explicitly documents a fallback for unsupported OS versions).
- [ ] `UI::Native::CallbackRegistry` exposes `register_action`, `register_action_with_value`, `invoke`, and the exported `ap_swiftkit_invoke_action` trampoline.
- [ ] `APSKRuntime.initialize(actionTrampoline:)` is invoked once during sample app startup; the call site is documented.
- [ ] iOS sample builds via `./samples/cross_platform/ios_host/build_crystal_lib.sh simulator` and `./samples/cross_platform/ios_host/build_crystal_lib.sh device`.
- [ ] macOS sample builds via `cd samples/cross_platform/macos_host && make build`.
- [ ] Default-detection invariant holds: a `UI::Button.new("Save")` with no other properties set sends NO setters on its `APSKButtonOverrides` object beyond `setRole:`/`setStyle:` (which are non-nullable). Verified by `spec/ui/renderers/swiftkit/default_detection_spec.cr`.
- [ ] `crystal spec` from repo root — zero failures, zero new pending tests.
- [ ] `cd swift/AssetPipelineSwiftKit && swift test` — zero failures.
- [ ] All snapshot baseline PNGs are committed under `swift/AssetPipelineSwiftKit/Tests/AssetPipelineSwiftKitTests/SnapshotTests/`.
- [ ] `CLAUDE.md` updated with the SwiftKit section.
- [ ] Handoff message written, with commit hashes for each `▸ Commit N` boundary and any deviations from this brief.

You do **not** run the validation rubric in `validation.md` yourself. That's the validator's job.

What is **not** in done:

- Performance optimization of nested hosting controllers. Explicit non-goal.
- Tier 3 widgets (`Alert`, `TokenField`, `OutlineView`, `ColumnView`, `ImageWell`, `ColorPicker`, `TimePicker`, `Grid`, `TextArea`). Phase 4 owns those.
- Compose-equivalent on Android. Android remains raw View-based.
- Removing the existing `LibObjCBridge.nscolor_rgba` / `nsfont_system` helpers from the renderer file. They remain because non-migrated widgets still use them.
- Visual regression baseline for the side-by-side demo app — that is phase 6's deliverable.
