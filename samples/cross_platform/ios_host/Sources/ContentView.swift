import SwiftUI
import UIKit

struct ContentView: View {
    let slug: String

    var body: some View {
        // Transparent container so UIVisualEffectView can composite against
        // the backdrop UIImageView installed by HIGBackdropController.
        // Do NOT add a solid .background() here -- that would flatten glass.
        CrystalHost(slug: slug)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .accessibilityIdentifier("hig-component-root-host")
    }
}

/// Bridges a Crystal-produced UIView into the SwiftUI tree.
/// The view itself carries no background; the backdrop lives below it
/// in the window's view hierarchy (installed by HIGBackdropController).
struct CrystalHost: UIViewRepresentable {
    let slug: String

    func makeUIView(context: Context) -> UIView {
        if let view = CrystalBridge.render(slug: slug) {
            return view
        }
        let fallback = UILabel()
        fallback.text = "render failed: \(slug)"
        fallback.accessibilityIdentifier = "hig-component-root"
        return fallback
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Installs a UIImageView backdrop beneath the component hierarchy so that
/// UIVisualEffectView materials can composite against real image content
/// rather than a solid window background.
///
/// This mirrors the macOS two-window backdrop approach from window_helper.m
/// (Phase 0.1), adapted for iOS: instead of a second NSWindow, we insert a
/// UIImageView at index 0 of the key window's root view.
///
/// Reads `HIG_BACKDROP_PATH` from ProcessInfo.environment. If the path is
/// set and the image loads successfully, the backdrop UIImageView is pinned
/// to the full window bounds with contentMode = .scaleAspectFill.
/// If the path is not set or the image fails to load, a gradient layer is
/// installed instead -- Amber cream to cosmic navy -- matching the Phase 0.1
/// macOS fallback.
enum HIGBackdropController {

    static func install(in window: UIWindow) {
        let env = ProcessInfo.processInfo.environment
        let backdropPath = env["HIG_BACKDROP_PATH"]

        let backdropView = UIView()
        backdropView.translatesAutoresizingMaskIntoConstraints = false

        if let path = backdropPath, let image = UIImage(contentsOfFile: path) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            backdropView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: backdropView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: backdropView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: backdropView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: backdropView.bottomAnchor),
            ])
        } else {
            // Amber gradient fallback: cream (#FAF6F0) -> cosmic navy (#141122).
            // In dark mode, invert so the dark surface reads against the dark
            // backdrop -- same gradient, just flipped direction.
            let gradient = CAGradientLayer()
            let cream = UIColor(red: 0.980, green: 0.965, blue: 0.941, alpha: 1.0).cgColor
            let navy  = UIColor(red: 0.078, green: 0.067, blue: 0.133, alpha: 1.0).cgColor
            let wantDark = (env["HIG_APPEARANCE"] ?? "light") == "dark"
            gradient.colors = wantDark ? [navy, cream] : [cream, navy]
            gradient.startPoint = CGPoint(x: 0.3, y: 0.0)
            gradient.endPoint   = CGPoint(x: 0.7, y: 1.0)
            gradient.frame = window.bounds
            backdropView.layer.addSublayer(gradient)
        }

        // Insert at index 0 so it sits beneath everything else -- including
        // the SwiftUI-managed UIView that hosts ContentView.
        guard let rootView = window.rootViewController?.view else { return }
        rootView.insertSubview(backdropView, at: 0)
        NSLayoutConstraint.activate([
            backdropView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            backdropView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            backdropView.topAnchor.constraint(equalTo: rootView.topAnchor),
            backdropView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
        ])
    }
}
