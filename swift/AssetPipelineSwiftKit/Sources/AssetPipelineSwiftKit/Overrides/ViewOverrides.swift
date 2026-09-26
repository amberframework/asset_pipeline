// ViewOverrides — the common @objc override carrier shared by every widget.
//
// Every field is nullable (`UIColor?`, `NSNumber?`, `String?`) and defaults
// to `nil`. A `nil` field means "the Crystal-side `UI::View` left this
// property at its type default — apply the SwiftUI default treatment."
// A non-nil field means the Crystal author explicitly set the property,
// so the corresponding modifier MUST be applied (see CommonModifiers.apply).
//
// All numeric fields are `NSNumber?` rather than `Double?` so they bridge
// cleanly to ObjC where `Double?` is not representable.
//
// This file is the sole owner of `APSKPlatformView`. HostingHelpers.swift
// imports the typealias from here; declaring it in two places is a
// duplicate-typealias error (see §5.5 / implementation.md line 701).

import SwiftUI
import Foundation
// NOTE on watchOS: `canImport(UIKit)` is TRUE (the framework ships) but the VIEW
// types (UIView/UIViewController/UIHostingController) are `API_UNAVAILABLE(watchos)`.
// UIColor/UIFont/UIImage ARE available. So the color typealias stays under
// `canImport(UIKit)`, but APSKPlatformView must be gated by `os(watchOS)` FIRST
// (a SwiftUI-native box) since watchOS has no UIView host.
#if canImport(UIKit)
import UIKit
public typealias APSKPlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias APSKPlatformColor = NSColor
#endif

#if os(watchOS)
import Combine

// watchOS Apple output node: a reference-type (NSObject) box carrying the SwiftUI
// content, so the Crystal bridge holds it as a +1-retained opaque pointer (same
// ObjC retain/release contract as a UIView/NSView handle) and the WatchKit
// renderer composes children by reading `.content`. See
// foundational-output-and-layout-model.md §"Principle 1" — the watchOS boundary is
// an explicit Apple output node, NOT a bare box, so it must satisfy the same
// bridge + reconciler contract a UIView/NSView handle does:
//
//   * Ownership   — NSObject with a real ObjC retain/release path (the Crystal
//                   NativeHandle holds it via ReleaseStrategy::ObjCRelease).
//   * Identity    — a stable `kind` (the watch analog of the debug-label
//                   `view_kind` the iOS/macOS reconciler infers in
//                   native_view.cr:70-109). The in-place reconciler ABORTS on a
//                   nil/mismatched kind (ios/bridge.cr:304-323), so the boundary
//                   node carries it explicitly. Settable by the Crystal renderer
//                   the same way it stamps a debug label on iOS/macOS.
//   * Topology    — ordered child boundary nodes the WatchKit renderer walks to
//                   compose; container facades read each child's `.content`.
//   * Update chan — `content` is @Published so an in-place swap (reconcile, which
//                   preserves focus across rerender) re-renders the observing
//                   SwiftUI view instead of tearing the subtree down.
public final class APSKWatchHostView: NSObject, ObservableObject {
    /// Stable widget kind — the watch analog of the iOS/macOS debug-label
    /// view_kind. Empty until the Crystal renderer stamps it (mirrors how the
    /// UIKit/AppKit path sets a debug label after `host` returns).
    @objc public var kind: String

    /// The SwiftUI content this node renders. @Published so an in-place content
    /// swap re-renders any observing `APSKHostedChild` rather than rebuilding.
    @Published public var content: AnyView

    /// Ordered child boundary nodes — the watch analog of the UIView/NSView child
    /// topology the reconciler walks. Container facades compose by reading each
    /// child's `.content`; reconcile updates this in place.
    public private(set) var children: [APSKWatchHostView]

    public init(content: AnyView, kind: String = "", children: [APSKWatchHostView] = []) {
        self.kind = kind
        self.content = content
        self.children = children
        super.init()
    }

    /// In-place content update (reconcile path). Publishes the change so the
    /// observing SwiftUI view refreshes while staying mounted (focus-preserving).
    public func update(content newContent: AnyView) {
        self.content = newContent
    }

    /// Number of child boundary nodes — discoverable from the Crystal bridge.
    @objc public var childCount: Int { children.count }

    /// Append a child boundary node (renderer composition path).
    @objc public func appendChild(_ child: APSKWatchHostView) {
        children.append(child)
    }

    /// Replace the full child list in order (reconcile topology update).
    public func setChildren(_ newChildren: [APSKWatchHostView]) {
        children = newChildren
    }

    /// The child at `index`, or nil if out of range (renderer walk).
    @objc public func child(at index: Int) -> APSKWatchHostView? {
        guard index >= 0 && index < children.count else { return nil }
        return children[index]
    }
}
public typealias APSKPlatformView = APSKWatchHostView
#elseif canImport(UIKit)
public typealias APSKPlatformView = UIView
#elseif canImport(AppKit)
public typealias APSKPlatformView = NSView
#endif

@objc(APSKViewOverrides)
public class ViewOverrides: NSObject {
    @objc public var backgroundColor: APSKPlatformColor? = nil    // nil = SwiftUI default
    @objc public var foregroundColor: APSKPlatformColor? = nil
    @objc public var cornerRadius: NSNumber? = nil                 // pt
    @objc public var paddingTop: NSNumber? = nil
    @objc public var paddingLeading: NSNumber? = nil
    @objc public var paddingBottom: NSNumber? = nil
    @objc public var paddingTrailing: NSNumber? = nil
    @objc public var borderWidth: NSNumber? = nil                  // pt
    @objc public var borderColor: APSKPlatformColor? = nil
    @objc public var shadowRadius: NSNumber? = nil
    @objc public var shadowColor: APSKPlatformColor? = nil
    @objc public var shadowOffsetX: NSNumber? = nil
    @objc public var shadowOffsetY: NSNumber? = nil
    // Compact generic surface modifiers. Nil preserves platform defaults.
    @objc(apskSurfaceCraftSpec) public var apskSurfaceCraftSpec: String? = nil
    @objc(apskSurfaceCraftKeycapStyle) public var apskSurfaceCraftKeycapStyle: String? = nil
    // Forced preview phase: hover, pressed, or focus. Nil preserves events.
    @objc(apskPreviewState) public var apskPreviewState: String? = nil
    @objc public var opacity: NSNumber? = nil                      // 0..1; nil = 1
    @objc public var hidden: NSNumber? = nil                       // bool-as-int
    @objc public var minWidth: NSNumber? = nil
    @objc public var minHeight: NSNumber? = nil
    @objc public var maxWidth: NSNumber? = nil
    @objc public var maxHeight: NSNumber? = nil
    @objc public var accessibilityIdentifier: String? = nil
    // Renamed from `accessibilityLabel` to avoid colliding with the
    // `NSObject`-supplied `UIAccessibility.accessibilityLabel` selector on
    // iOS slices, which produced the iter-1 "setter conflicts with
    // superclass" compile error. The explicit `@objc(apskAccessibilityLabel)`
    // pins the Objective-C selector so the Crystal Populator addresses an
    // unambiguous setter (`setApskAccessibilityLabel:`).
    @objc(apskAccessibilityLabel) public var apskAccessibilityLabel: String? = nil

    // Phase 10B.2a iter 2 (Codex Finding 1) — five new accessibility
    // metadata slots threaded through from the Crystal-side `UI::View`
    // base. Each setter is renamed to `apsk*` to avoid collision with
    // the `NSObject`-supplied `UIAccessibility.*` properties on iOS
    // slices (same root cause as `apskAccessibilityLabel`). The Crystal
    // Populator addresses these via `setApskAccessibilityHint:` etc.
    //
    // CommonModifiers.apply reads these and emits the matching SwiftUI
    // accessibility modifier:
    //   apskAccessibilityHint       -> .accessibilityHint(Text(...))
    //   apskAccessibilityValue      -> .accessibilityValue(Text(...))
    //   apskAccessibilityRole       -> role-specific modifier (heading/image/...)
    //   apskAccessibilityTraitsMask -> .accessibilityAddTraits(...) bitmask
    //   apskAccessibilityIdentifier2 — duplicate of accessibilityIdentifier
    //                                  because the View-base `accessibility_identifier`
    //                                  is a SEPARATE Crystal property from `test_id`;
    //                                  the populator writes BOTH slots and the
    //                                  Crystal-side precedence rule (identifier wins
    //                                  over test_id) is enforced by the Populator
    //                                  emitting nil for the looser slot when
    //                                  identifier is set.
    @objc(apskAccessibilityHint) public var apskAccessibilityHint: String? = nil
    @objc(apskAccessibilityValue) public var apskAccessibilityValue: String? = nil
    // Role symbol stringified ("button", "heading", "image", "search",
    // "text", "link", ...). The Modifier reads this and dispatches to
    // the matching SwiftUI `.accessibilityAddTraits()` or
    // `.accessibilityRepresentation { ... }` form. Unmapped roles fall
    // through silently.
    @objc(apskAccessibilityRole) public var apskAccessibilityRole: String? = nil
    // UIAccessibilityTraits bitmask, raw `UInt64` boxed in NSNumber.
    // Crystal computes the OR of `accessibility_traits` + role-trait
    // and passes the composed mask. The Modifier maps known bits to
    // SwiftUI `AccessibilityTraits` and emits a single
    // `.accessibilityAddTraits(...)` call.
    @objc(apskAccessibilityTraitsMask) public var apskAccessibilityTraitsMask: NSNumber? = nil

    // Phase 10B.2b — action + focus + keyboard accessibility slots.
    //
    // `apskAccessibilityActions` is a comma-joined string of action
    // names. Names containing commas are %2C-escaped on the Crystal
    // side; the modifier splits + unescapes. Each action's callback
    // is wired separately via the ObjC bridge (`apsk_view_add_*`),
    // so the Swift facade only needs the *names* to attach
    // `.accessibilityAction(named:action:)` modifiers — the action
    // closures invoke the matching custom-action handler on the
    // attached UIAccessibilityCustomAction object.
    //
    // For SwiftUI views constructed through the facade we can also
    // attach `.accessibilityAction(named:)` modifiers directly so the
    // VoiceOver rotor surfaces them without depending on the legacy
    // UIView accessibilityCustomActions path. The callback token is
    // resolved in the Swift facade via a per-view dispatch table
    // populated by the Crystal renderer; iter 1 ships the data
    // pipeline and Apple-host validation is deferred to the snapshot
    // harness.
    @objc(apskAccessibilityActions) public var apskAccessibilityActions: String? = nil
    @objc(apskAccessibilityActionCount) public var apskAccessibilityActionCount: NSNumber? = nil

    // Focus request: when true the view should call
    // `.accessibilityFocused` (or equivalent) on the next render.
    // SwiftUI's `.accessibilityFocused` requires a `@FocusState`
    // binding inside the View, which we cannot synthesise from
    // outside the facade. The reactive `apsk_view_become_first_responder`
    // helper bridges the gap on iOS/macOS at the UIView/NSView layer
    // for the native renderer path.
    @objc(apskFocused) public var apskFocused: NSNumber? = nil

    // Keyboard shortcut: key (single character or special key name)
    // + UIKeyModifierFlags-compatible bitmask. SwiftUI's
    // `.keyboardShortcut` takes a `KeyEquivalent` + `EventModifiers`;
    // the modifier maps the bitmask onto `EventModifiers` bits.
    @objc(apskKeyboardShortcutKey) public var apskKeyboardShortcutKey: String? = nil
    @objc(apskKeyboardShortcutModifiers) public var apskKeyboardShortcutModifiers: NSNumber? = nil

    @objc public override init() { super.init() }
}
