// CallbackBridge — the one-direction Swift → Crystal action dispatch surface
// PLUS the brand-tint runtime registry that drives the "SwiftUI Default
// Supremacy" cascade.
//
// Action dispatch:
//
//   At runtime the Swift companion is statically linked into the
//   Crystal-driven host binary. Crystal exports a single `@convention(c)`
//   trampoline function, `ap_swiftkit_invoke_action(token: UInt64, value:
//   Double)`. During app startup Crystal calls
//   `APSKRuntime.initialize(actionTrampoline:)` once, passing the address
//   of that trampoline. Subsequent UI events (Button tap, Toggle change,
//   Slider drag-end) fire `CallbackBridge.fire(token:value:)` which calls
//   the trampoline, which routes through the Crystal-side
//   `UI::CallbackRegistry` to the original `Proc`.
//
//   `token == 0` means "no callback wired" — every call site checks. This
//   matches the Crystal-side convention (token 0 is never handed out by
//   `register_action`).
//
// Brand tint:
//
//   Under Option B ("SwiftUI Default Supremacy") brand identity propagates
//   through the SwiftUI `.tint()` accent cascade rather than per-widget
//   colour overrides. The Crystal renderer calls
//   `APSKRuntime.setBrandTint(red:green:blue:alpha:)` once during render
//   set-up (and re-applies it whenever `design_tokens` changes), passing
//   the active `brand_primary` colour. The current tint is stored on
//   `APSKRuntime` and every facade's `HostingHelpers.host(_:)` wrapper
//   applies it via `.tint(...)` to its hosted root. A `nil` tint means
//   "no override — use the system accent colour."

import SwiftUI
import Foundation

/// Pointer to the Crystal-side trampoline. Set once at startup by
/// `APSKRuntime.initializeWithActionTrampoline:`. Stored as an optional
/// so the package can be loaded before Crystal initialization (the spec
/// helper exercises this path).
private var actionTrampoline: (@convention(c) (UInt64, Double) -> Void)? = nil

/// Phase 6.10 Rem 4 (Item 1) — string-valued trampoline for TextField /
/// SecureField / TextArea / SearchField on_change events that need to
/// dispatch the actual typed string (not just a length signal). Crystal
/// exports `ap_swiftkit_invoke_action_string(token, c_string)`; Swift
/// installs the pointer via `APSKRuntime.initialize(stringTrampoline:)`.
///
/// Without this, the previous on_change callback collapsed every char
/// event to `value: Double(text.count)` — the Crystal-side
/// `->(value : String) { ... }` closure never saw the actual text,
/// breaking Save (the editor's `state.add_todo(draft.title, ...)`
/// committed an empty title).
private var stringTrampoline: (@convention(c) (UInt64, UnsafePointer<CChar>?) -> Void)? = nil

/// Cached brand tint applied to every hosted SwiftUI root. `nil` means
/// "use the system accent colour" (SwiftUI default behaviour). Stored as
/// `SwiftUI.Color?` so `HostingHelpers.host(_:)` can splat it into a
/// `.tint(_:)` call without re-converting on every render.
///
/// Reads and writes are confined to the main thread (UIKit/AppKit
/// renderer contract — the Crystal-side renderer initialiser and the
/// facade `host(_:)` call both run on the main thread).
private var currentBrandTint: Color? = nil

@objc(APSKRuntime)
public class APSKRuntime: NSObject {
    /// Called by Crystal once, immediately after `GC.init` and before any
    /// facade is invoked. Passes a C function pointer to
    /// `ap_swiftkit_invoke_action` (Crystal-exported `fun`).
    ///
    /// `trampoline` is treated as `UnsafeRawPointer` to keep the ObjC
    /// surface free of Swift-only types; the unsafeBitCast restores the
    /// expected `@convention(c)` signature on the Swift side.
    @objc public static func initialize(actionTrampoline trampoline: UnsafeRawPointer) {
        actionTrampoline = unsafeBitCast(
            trampoline,
            to: (@convention(c) (UInt64, Double) -> Void).self
        )
    }

    /// Phase 6.10 Rem 4 — install the string-valued action trampoline.
    /// Called by the Crystal runtime initializer alongside the
    /// numeric `actionTrampoline:` installer. Pass `nil` (via a
    /// separate clear method if needed) is intentionally not supported
    /// — the runtime spec installs once at startup and never clears.
    @objc public static func initialize(stringTrampoline trampoline: UnsafeRawPointer) {
        stringTrampoline = unsafeBitCast(
            trampoline,
            to: (@convention(c) (UInt64, UnsafePointer<CChar>?) -> Void).self
        )
    }

    /// Returns true once `initialize(stringTrampoline:)` has been
    /// called. Used by the runtime spec.
    @objc public static var isStringTrampolineInstalled: Bool {
        stringTrampoline != nil
    }

    /// Install (or replace) the brand tint colour applied to every
    /// SwiftUI facade root. Components inside a hosted root inherit this
    /// tint as their accent colour, which is how a brand override on
    /// Crystal's `design_tokens.colors.brand_primary` reaches the
    /// rendered pixel.
    ///
    /// Re-callable: the renderer calls this on every `render(...)` entry
    /// so a brand swap mid-session (`design_tokens =
    /// Tokens.default.with_brand(...)`) takes effect on the next render.
    /// Channel values are normalised 0...1 sRGB.
    @objc public static func setBrandTint(red: Double, green: Double, blue: Double, alpha: Double) {
        currentBrandTint = Color(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: alpha
        )
    }

    /// Clear the brand tint. After this call, hosted roots fall back to
    /// SwiftUI's automatic accent colour. Used by tests and for sample
    /// builds that intentionally want raw SwiftUI defaults.
    @objc public static func clearBrandTint() {
        currentBrandTint = nil
    }

    /// Internal accessor used by `HostingHelpers.host(_:)`. Marked
    /// `internal` because nothing outside the package needs the raw
    /// `SwiftUI.Color`; ObjC callers go through `setBrandTint`.
    static var brandTint: Color? { currentBrandTint }

    /// Returns true once `setBrandTint` has been called at least once and
    /// the tint has not been cleared. Used by specs and by the runtime
    /// spec to confirm wiring without exposing the colour itself.
    @objc public static var hasBrandTint: Bool {
        currentBrandTint != nil
    }

    /// Test-only hook. Lets `CallbackBridgeTests.swift` install a Swift
    /// closure in place of the Crystal trampoline so the round-trip can
    /// be exercised without linking against libcrystal.
    @objc public static func _installTestTrampoline(
        _ trampoline: @convention(c) (UInt64, Double) -> Void
    ) {
        actionTrampoline = trampoline
    }

    /// Returns true once `initialize(actionTrampoline:)` has been called.
    /// Used by the runtime spec to confirm wiring.
    @objc public static var isActionTrampolineInstalled: Bool {
        actionTrampoline != nil
    }
}

enum CallbackBridge {
    /// Fire the registered Crystal trampoline. `token == 0` is a no-op
    /// (matches the Crystal-side "no callback wired" convention). If the
    /// trampoline has not been installed yet, the call is silently dropped
    /// rather than crashing — first-launch race protection.
    static func fire(token: UInt64, value: Double) {
        guard token != 0 else { return }
        actionTrampoline?(token, value)
    }

    /// Phase 6.10 Rem 4 (Item 1) — string-valued counterpart for
    /// TextField / SecureField / TextArea / SearchField on_change
    /// callbacks. Crystal receives the actual typed text (not just a
    /// length signal), so closures like
    /// `->(value : String) { draft.title = value }` work end-to-end.
    ///
    /// The Crystal side must handle UTF-8 encoded NUL-terminated
    /// strings; Swift hands a pointer to the String's UTF-8 buffer
    /// which is valid for the duration of the trampoline call only.
    static func fireString(token: UInt64, value: String) {
        guard token != 0 else { return }
        value.withCString { ptr in
            stringTrampoline?(token, ptr)
        }
    }
}
