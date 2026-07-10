// HostingHelpers — platform-conditional aliases and the single `host(_:)`
// helper every facade routes through to wrap a SwiftUI view in a hosting
// controller and return the controller's `.view` as a raw platform pointer.
//
// Architectural decision (§5.6): one `UIHostingController` per widget facade.
// This matches the "Crystal builds a widget, hands the pointer to a parent"
// model that every existing visit method assumes. Performance optimization
// of nested hosting controllers is explicitly out of scope for Phase 3.
//
// Known SwiftUI quirk addressed here (§5.6): inside `Form` / `List`, a
// `UIViewRepresentable` child can collapse to zero intrinsic size on the
// first layout pass. `host(_:)` wraps every view in
// `.frame(minWidth: 1, minHeight: 1)` so the intrinsic-size invariant
// stays positive on the first pass; the real content size propagates
// normally on the next pass and the 1pt floor is never visible.
//
// `APSKPlatformView` is declared in `Overrides/ViewOverrides.swift` and
// MUST NOT be redeclared here — Swift rejects the duplicate
// `public typealias` (see implementation.md §5.5 + line 701).

import SwiftUI

#if canImport(UIKit)
import UIKit
// APSKPlatformView is declared in ViewOverrides.swift; do not redeclare.
public typealias APSKHostingController = UIHostingController
#elseif canImport(AppKit)
import AppKit
// APSKPlatformView is declared in ViewOverrides.swift; do not redeclare.
public typealias APSKHostingController = NSHostingController

// On AppKit we prefer NSHostingView directly over NSHostingController:
// the view *is* the hosting surface, reports the SwiftUI root's
// intrinsic content size to NSStackView without any extra sizing-options
// dance, and produces a stable +1-retain NSView pointer the Crystal
// renderer can hand to `ObjC.owned(...)`. NSHostingController exists
// for cases where the SwiftUI root needs to participate in a view
// controller hierarchy (e.g. an NSWindow's contentViewController); a
// Crystal-driven AppKit renderer never needs that layer.
#endif

/// Anchor key for the associated hosting-controller object. The hosting
/// controller must live as long as the returned `.view` does; ObjC
/// associations are the cleanest way to attach that lifetime without
/// modifying the platform view itself.
private var kHostingControllerKey: UInt8 = 0

#if canImport(UIKit)
/// Phase 6.10 Rem 3 (Path A) — UIView subclass that fires a callback
/// every time its window membership changes. Used as a 0-sized,
/// hidden subview of the SwiftUI hosting controller's `.view` so we
/// observe `didMoveToWindow` reliably without giving up the SwiftUI
/// rendering surface.
///
/// Rejected approaches (per Codex review 1 + 2):
/// - `deinit` cleanup: the parent VC's `children` array retains its
///   children until `removeFromParent()` runs, so ARC cannot reach
///   `deinit` while the controller is still parented. `.id(slug)`
///   reroute paths therefore leaked stale child controllers.
/// - `view.window` KVO: empirically did not fire on iOS 26 simulator
///   under the current SwiftUI hosting model.
/// - Replacing the controller's `.view` with our own subclass via
///   `loadView()`: breaks SwiftUI's render surface, the SwiftUI
///   content stops drawing entirely.
/// - `viewWillDisappear`-only detach: doesn't fire on `.id(slug)`
///   discard — SwiftUI never asks the off-screen controller's view
///   to disappear normally.
///
/// Accepted approach: insert a hidden 0pt × 0pt sentinel UIView as a
/// subview of the hosting controller's `.view`. UIKit forwards
/// `didMoveToWindow` to every subview when their ancestor view's
/// window membership changes, so the sentinel reliably tracks
/// window-add and window-remove events. The hosting controller's
/// SwiftUI render surface is untouched.
@available(iOS 13.0, tvOS 13.0, *)
final class APSKHostingWindowSentinel: UIView {
    /// Invoked every time this view's window membership changes
    /// (either becoming non-nil or going nil).
    var onWindowChange: ((UIWindow?) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Hidden + non-interactive so the sentinel never intercepts
        // touches or appears in the AX tree.
        isHidden = true
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChange?(window)
    }
}

/// Phase 6.10 Rem 3 (Path A) — UIHostingController subclass that
/// installs an `APSKHostingWindowSentinel` as a hidden subview of its
/// `.view` and uses the sentinel's `didMoveToWindow` callback to
/// drive attach + detach against the responder-chain's parent
/// UIViewController.
///
/// Why this exists: SwiftUI's `Button` (and every other interactive
/// SwiftUI control hosted via `UIHostingController`) wires its
/// `action: () -> Void` closure through the SwiftUI gesture scheduler,
/// which in turn depends on the hosting controller being in the parent
/// VC hierarchy (`addChild` + `didMove(toParent:)`). When the Crystal
/// renderer adds the controller's `.view` as a UIStackView's arranged
/// subview WITHOUT registering the controller as a child VC, the
/// gesture scheduler never observes the host's responder chain and the
/// SwiftUI Button's action closure is never invoked. Confirmed via
/// 11+ XCUITest variants in Rem 2 (see
/// `handoff/phase-06.10-remediation-2-codex-blocker.md`).
///
/// Generic parameter is bound to `AnyView` because every call site
/// wraps its content in an `AnyView` at `HostingHelpers.host` entry.
@available(iOS 13.0, tvOS 13.0, *)
final class APSKAttachingHostingController: UIHostingController<AnyView> {
    private weak var sentinel: APSKHostingWindowSentinel?

    override func viewDidLoad() {
        super.viewDidLoad()
        installSentinel()
    }

    private func installSentinel() {
        guard sentinel == nil else { return }
        let s = APSKHostingWindowSentinel(frame: .zero)
        s.translatesAutoresizingMaskIntoConstraints = false
        s.onWindowChange = { [weak self] window in
            guard let self = self else { return }
            if window != nil {
                self.attachIfNeeded()
            } else {
                self.detachIfNeeded()
            }
        }
        view.addSubview(s)
        // 0pt × 0pt sentinel pinned at the host view's origin. UIKit
        // still routes window-membership change events through it
        // because subview lifecycle is independent of frame size.
        NSLayoutConstraint.activate([
            s.widthAnchor.constraint(equalToConstant: 0),
            s.heightAnchor.constraint(equalToConstant: 0),
            s.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            s.topAnchor.constraint(equalTo: view.topAnchor),
        ])
        sentinel = s
    }

    private func attachIfNeeded() {
        guard parent == nil, view.window != nil else { return }
        if let parent = nextParentViewController() {
            parent.addChild(self)
            didMove(toParent: parent)
        }
    }

    private func detachIfNeeded() {
        guard parent != nil else { return }
        willMove(toParent: nil)
        removeFromParent()
    }

    private func nextParentViewController() -> UIViewController? {
        var responder: UIResponder? = view.next
        while let r = responder {
            if let vc = r as? UIViewController, vc !== self {
                return vc
            }
            responder = r.next
        }
        return nil
    }
}

#endif

enum HostingHelpers {
    /// Wrap `view` in a hosting controller, retain the controller for the
    /// lifetime of its `.view`, and return the platform view.
    ///
    /// Crystal's `NativeHandle` takes ownership of the returned view pointer
    /// (+1 retain). The hosting controller is associated with the view via
    /// `objc_setAssociatedObject` so it lives as long as the view does.
    ///
    /// The `.frame(minWidth: 1, minHeight: 1)` defensive sizing is required
    /// for the SwiftUI Form/List re-measure quirk documented in §5.6.
    ///
    /// Phase 6.10 Rem 3 (Path A): on UIKit an
    /// `APSKHostingControllerAttacher` is attached via ObjC association
    /// to the returned hosted view so the hosting controller can be
    /// registered as a child VC of the responder-chain's parent
    /// UIViewController the moment the view enters a window. This is
    /// required for SwiftUI's gesture scheduler to fire Button / Toggle
    /// / Slider callbacks when the hosting controller's `.view` is
    /// embedded in a UIKit subtree (the Crystal renderer's UIStackView
    /// root model). AppKit is unaffected — NSHostingView reports actions
    /// independently of NSViewController containment.
    static func host<V: View>(_ view: V) -> APSKPlatformView {
        // Apply the brand tint last so it cascades into every child view
        // SwiftUI considers part of this hosted root. Hosted roots are
        // isolated tint scopes — there is no propagation across
        // `UIHostingController` / `NSHostingController` boundaries — so
        // each facade re-applies the currently installed brand tint.
        // When no tint has been installed (`APSKRuntime.brandTint == nil`)
        // SwiftUI's system accent colour shows through unchanged.
        let tinted: AnyView
        if let tint = APSKRuntime.brandTint {
            tinted = AnyView(view.tint(tint))
        } else {
            tinted = AnyView(view)
        }
        let sized = AnyView(tinted.frame(minWidth: 1, minHeight: 1))

        let platformView: APSKPlatformView
        let lifetimeOwner: AnyObject
        #if canImport(UIKit)
        // UIHostingController + .view is the standard UIKit path.
        // `sizingOptions` is set BEFORE first access to `.view` so the
        // hosted UIView reports the SwiftUI intrinsic size on the first
        // layout pass; the prior order produced a CGSizeZero report and
        // collapsed the button to invisible inside a UIStackView.
        // Phase 6.10 Rem 3 (Path A): use the
        // `APSKAttachingHostingController` subclass that registers
        // itself as a child VC of the responder-chain's parent
        // UIViewController on first layout. This is the missing
        // handshake SwiftUI's gesture scheduler needs to fire Button /
        // Toggle / Slider action closures when the hosting controller's
        // `.view` is embedded in a UIKit subtree.
        //
        // Returning `controller.view` directly (not a wrapper view)
        // preserves the layout shape every Crystal caller already
        // expects — the renderer's `objc_constrain_*` helpers and
        // UIStackView arranged-subview intrinsic-size invariants still
        // see the unmodified UIHostingController.view, identical to the
        // pre-Rem-3 path.
        let controller = APSKAttachingHostingController(rootView: sized)
        if #available(iOS 16.0, *) {
            controller.sizingOptions = [.intrinsicContentSize]
        }
        let hostedView = controller.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        hostedView.backgroundColor = .clear
        platformView = hostedView
        lifetimeOwner = controller
        #else
        // NSHostingView is the AppKit-native shortcut: the view *is* the
        // SwiftUI surface, reports `intrinsicContentSize` accurately to
        // NSStackView's gravity-areas distribution out of the box, and
        // saves us from `NSHostingController.sizingOptions` ordering
        // bugs. The view is a +0-retain NSView; ObjC.owned on the
        // Crystal side bumps it to +1 immediately.
        let hostingView = NSHostingView(rootView: sized)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        platformView = hostingView
        lifetimeOwner = hostingView
        #endif

        // Keep the lifetime owner pinned for as long as the platform
        // view lives. On AppKit they are the same object, but the
        // association is cheap and uniform across platforms. On UIKit
        // the container already strongly references the controller via
        // its stored property, but we keep the association too as a
        // belt-and-suspenders measure.
        objc_setAssociatedObject(
            platformView,
            &kHostingControllerKey,
            lifetimeOwner,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return platformView
    }
}

/// SwiftUI representable wrapping an already-hosted platform view.
/// Container facades (TabView, Form, List) use this to compose child
/// widgets that the Crystal renderer has already built and handed to Swift
/// as raw platform pointers.
#if canImport(UIKit)
struct APSKHostedChild: UIViewRepresentable {
    let view: APSKPlatformView
    func makeUIView(context: Context) -> APSKPlatformView { view }
    func updateUIView(_: APSKPlatformView, context: Context) {}
}
#elseif canImport(AppKit)
struct APSKHostedChild: NSViewRepresentable {
    let view: APSKPlatformView
    func makeNSView(context: Context) -> APSKPlatformView { view }
    func updateNSView(_: APSKPlatformView, context: Context) {}
}
#endif
