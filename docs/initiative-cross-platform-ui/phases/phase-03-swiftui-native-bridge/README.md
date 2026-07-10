# Phase 3 — SwiftUI Native Bridge

**Tier:** 2 (Platform Default)
**Depends on:** Phase 1 (token system needed for the `AppleGenerator` Swift output)
**Blocks:** Phase 4 (cannot verify Tier 2 platform defaults without SwiftUI in place), Phase 5 (glass tokenization wires through SwiftUI), Phase 6 (demo's iOS/macOS targets render via this bridge)
**Estimated remediation budget:** 2 loops (this is the highest-risk phase)

---

## Why this phase exists

Today the Apple renderers (`appkit_renderer.cr`, `uikit_renderer.cr`) emit native widgets by calling AppKit/UIKit ObjC selectors directly: `NSButton`, `UIButton`, `NSStackView`, `UIStackView`, etc. Styling is set imperatively (`setBackgroundColor:`, `setCornerRadius:`).

The user-visible consequence: the components don't get the iOS 26 / macOS 26 SwiftUI default treatments. There is no Liquid Glass on a default Button. The system font weight transitions, system animations, focus states, accessibility traits, dynamic type response, dark-mode chromatic tracking, and high-contrast mode are all present in raw form but lack the "I'm using a system component" polish that comes from SwiftUI's modifiers being applied by default.

The user's intent: **on Apple platforms, components should look like SwiftUI defaults out of the box. Only when the developer customizes (sets `background_color`, `border_radius`, `padding`, etc.) should the override cascade in and replace the default treatment.**

This phase builds the bridge that makes that possible.

## Architecture

Two new artifacts:

1. **`AssetPipelineSwiftKit`** — a Swift companion library (Swift Package or static library) added to the repo at `swift/AssetPipelineSwiftKit/`. Defines `@objc`-exported facades for every Tier 1 + Tier 2 view that has a SwiftUI counterpart. Each facade wraps the SwiftUI view in a `UIHostingController` (iOS) or `NSHostingController` (macOS) and exposes the controller's `.view` for embedding.
2. **Refactored Apple renderers** — `uikit_renderer.cr` and `appkit_renderer.cr` shift from "build raw AppKit/UIKit instance" to "call SwiftKit facade; pass override modifiers as a small struct; SwiftKit applies modifiers conditionally only when set."

The bridge contract for one widget looks like:

```
Crystal side:
  visit(view : Button) →
    overrides = ButtonOverrides.new(
      background_color: view.background_color,    # nil if unset
      foreground_color: view.foreground_color,    # nil if unset
      corner_radius:    view.corner_radius,       # nil if unset
      padding:          view.padding,             # nil if unset
      font:             view.font,                # nil if unset
    )
    ptr = AssetPipelineSwiftKit.makeButton(label, overrides)
    # ptr is a UIView / NSView ready to add to parent

Swift side:
  @objc public static func makeButton(label: String, overrides: ButtonOverrides) -> UIView {
    var view = AnyView(SwiftUI.Button(label) { /* action wired separately */ })
    if let bg = overrides.backgroundColor { view = AnyView(view.background(bg)) }
    if let fg = overrides.foregroundColor { view = AnyView(view.foregroundColor(fg)) }
    if let cr = overrides.cornerRadius    { view = AnyView(view.clipShape(RoundedRectangle(cornerRadius: cr))) }
    // ...
    return UIHostingController(rootView: view).view
  }
```

This pattern means **a developer who calls `Button.new("Save")` with no other settings gets a SwiftUI default Button** — system blue, system font weight, default insets, hover/press animations, accessibility traits, dynamic type, dark mode, all for free.

## Scope summary

In scope:

- Create the `swift/AssetPipelineSwiftKit/` Swift package with module map, build configuration for iOS device + simulator + macOS, and `@objc` exports.
- Implement facades for Tier 1 + Tier 2 widgets: **Button**, **Text/Label**, **VStack/HStack/ZStack**, **Toggle**, **Picker**, **Slider**, **Stepper**, **TextField/SecureField/SearchField**, **NavigationStack**, **NavigationLink**, **NavigationSplitView**, **TabView**, **Sheet**, **Form**, **List/ListView**, **Card/Surface**, **GlassBackground**, **Image**, **ProgressView**, **Divider**. (~25 widgets — that's the bulk of Tier 1/2.)
- Refactor `uikit_renderer.cr` and `appkit_renderer.cr` visit methods for each of the above widgets to call the SwiftKit facade instead of building raw AppKit/UIKit views.
- Update the iOS and macOS sample build scripts (`samples/cross_platform/ios_host/build_crystal_lib.sh`, `samples/cross_platform/macos_host/`) to link the SwiftKit library.
- Specs:
  - Crystal-side: assert that each visit method correctly populates the overrides struct (defaults of `nil` when widget property is unset; populated when set).
  - Swift-side: SwiftUI snapshot tests showing default Button vs. Button with `background_color` override, etc.

Out of scope:

- Tier 3 widgets (ActionSheet, ContextMenu, HapticFeedback) — phase 4 handles them.
- Migrating widgets without SwiftUI counterparts (e.g., Canvas, MapView, VideoPlayer): they remain on direct AppKit/UIKit for now.
- Performance optimization of `UIHostingController` overhead. We're optimizing for correctness/polish first.
- Compose-equivalent on Android. Android remains raw View-based.

## Acceptance summary

Phase 3 is done when:

- A demo screen with default (unstyled) Button, Toggle, Picker, TabView, Form on iOS visually matches a side-by-side SwiftUI native reference.
- The same screen on macOS visually matches a SwiftUI macOS reference.
- Setting `background_color` on a default Button overrides the background while preserving SwiftUI's other default treatments.
- Setting `corner_radius: 0` produces a square Button (no rounding) while preserving system color and typography.
- iOS 26+ Liquid Glass appears automatically on widgets that should have it (GlassBackground, NavigationStack surfaces, etc.) without the developer doing anything.
- All four sample apps still build clean.
- Spec suite passes.

Detailed checks in `validation.md`.

## Risk notes

- **Crystal calling Swift via ObjC is not natural** — Swift exports to ObjC via `@objc`, but the calling conventions, ARC, and Swift runtime initialization need care. The implementer must verify the Swift runtime is initialized before Crystal calls into it.
- **`UIHostingController` is not free.** Each one is a child view controller. For the demo app this is fine; for high-density screens this is a performance concern (not addressed in this phase).
- **Cross-platform code in Swift package**: iOS and macOS SwiftUI APIs differ slightly. Use `#if os(iOS)` / `#if os(macOS)` guards.
- **Linking on iOS simulator vs device**: ensure the Swift package builds for arm64 simulator (M-series Macs), x86_64 simulator (Intel Macs), and arm64 device. Crystal Apple builds are already simulator-arm64-only; this is consistent.
- **Sample build complexity will grow.** Validator should explicitly check that build instructions in CLAUDE.md / sample README files are updated.

## Briefing documents

- Implementer: `implementation.md`
- Validator: `validation.md`
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
