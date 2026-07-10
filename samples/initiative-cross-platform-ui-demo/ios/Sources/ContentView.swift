import SwiftUI
import UIKit

struct ContentView: View {
    let slug: String

    var body: some View {
        // Wrap the Crystal-produced UIView in a vertical ScrollView so any
        // screen taller than the iPhone portrait viewport remains reachable.
        // The Phase 6 Rem 2 sign-in baseline showed the Sign-in button +
        // Forgot-password link below the fold on iPhone 17 portrait
        // (1206 x 2622) because the root Crystal VStack vertical-centred
        // its content inside the available SwiftUI space. ScrollView pins
        // the content top-anchored, lets the user scroll if needed, and
        // costs nothing visually when the content already fits.
        ScrollView(.vertical, showsIndicators: false) {
            CascadeHost(slug: slug)
                .frame(maxWidth: .infinity, alignment: .top)
                .accessibilityIdentifier("cascade-root-host")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// Bridges a Crystal-produced UIView into the SwiftUI tree.
struct CascadeHost: UIViewRepresentable {
    let slug: String

    func makeUIView(context: Context) -> UIView {
        if let view = CascadeBridge.render(slug: slug) {
            return view
        }
        let fallback = UILabel()
        fallback.text = "render failed: \(slug)"
        fallback.accessibilityIdentifier = "cascade-root-fallback"
        return fallback
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
