import UIKit

/// Swift wrapper around the Crystal C-ABI bridge functions exposed by
/// `samples/initiative-cross-platform-ui-demo/ios/bridge.cr` and
/// packaged into libcascade.a.
enum CascadeBridge {
    private static var didInit = false

    static func initialize() {
        guard !didInit else { return }
        cascade_init()
        didInit = true
    }

    /// Render a demo screen by slug and return the produced UIView.
    /// Crystal returns a retained UIView*; ownership transfers here via
    /// takeRetainedValue().
    static func render(slug: String) -> UIView? {
        initialize()
        return slug.withCString { ptr in
            guard let raw = cascade_render(ptr) else { return nil }
            let view = Unmanaged<UIView>.fromOpaque(raw).takeRetainedValue()
            view.accessibilityIdentifier = "cascade-root-\(slug)"
            view.isAccessibilityElement = false
            return view
        }
    }
}
