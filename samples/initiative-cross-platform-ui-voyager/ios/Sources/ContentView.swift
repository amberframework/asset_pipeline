import SwiftUI
import UIKit
import Combine

/// The Voyager root content view — owns a @State String tracking the
/// currently-visible route slug. When the Crystal-side coordinator
/// fires its route-changed callback (via VoyagerBridge.routeChanged
/// PassthroughSubject), this view's @State updates, which causes
/// SwiftUI to re-evaluate `body` and rebuild the hosted UIView via
/// VoyagerHost(slug:) — that calls VoyagerBridge.render(slug:) for
/// the new route.
///
/// This is the runtime-navigation substrate Phase 6.10 ships on iOS:
/// any Crystal-rendered button can call `coord.push(...)`, which fires
/// the on_change subscriber, which crosses into Swift via the C
/// trampoline, which re-renders the view tree.
///
/// Phase 6.10 Rem 4 (Item 1 — Save-propagation fix):
///
/// Architect's hypothesis: returning from Editor → Todos via coord.pop
/// goes slug "voyager-todos" → "voyager-todo-editor" → "voyager-todos".
/// When the slug transitions BACK to "voyager-todos" the `.id(slug)`
/// modifier does discard the existing representable and call
/// `makeUIView` fresh — but if SwiftUI does any view caching by id, or
/// if the slug change arrives in the same render pass that already
/// reset, the new makeUIView call could end up returning a UIView
/// built from a stale Crystal state snapshot.
///
/// Fix: include a monotonic `renderVersion` counter in the `.id()` so
/// every `routeChanged` publish ALWAYS yields a fresh representable
/// identity, even when the slug string is identical to a previous
/// value. Combined with a properly-wired `updateUIView` that re-builds
/// from Crystal (defensive — `.id` should already discard, but
/// `updateUIView` becomes the safety net), the new todo always appears
/// in the Todos list after Save → pop.
///
/// Phase 6.10 Rem 4 (Item 2A — full-screen fill):
///
/// The SwiftUI host now uses `.ignoresSafeArea(.all)` on the outer
/// container so the Crystal-rendered content gets the full window
/// (no SwiftUI safe-area padding leaving black bars at top + bottom on
/// iPhone 17 Pro). Crystal-side screens that need to respect the
/// Dynamic Island or home indicator query the runtime safe-area insets
/// via the new `UI::DesignTokens::DeviceMetrics` utilities.
struct ContentView: View {
    let initialSlug: String

    @State private var slug: String
    /// Monotonic counter — bumped every time the Crystal coordinator
    /// publishes a route change. Combined with `slug` in `.id()` so
    /// even a same-slug republish (e.g. Editor → Todos return) forces
    /// SwiftUI to discard + recreate the representable.
    @State private var renderVersion: Int = 0

    init(initialSlug: String) {
        self.initialSlug = initialSlug
        _slug = State(initialValue: initialSlug)
    }

    var body: some View {
        // Phase 6.10 Rem 4 Item 2A — full-screen fill:
        //
        // The host UIViewRepresentable is given a frame of
        // `.infinity × .infinity` and combined with `.ignoresSafeArea(.all)`
        // so the UIKit content paints edge-to-edge from the very top of
        // the screen (under the Dynamic Island) to the very bottom
        // (under the home indicator). The Crystal screen builder
        // queries `UI::DesignTokens::DeviceMetrics.current` and pads
        // by `safe_area_top_pt` / `safe_area_bottom_pt` so visible
        // controls stay clear of system chrome.
        VoyagerHost(slug: slug, renderVersion: renderVersion)
            // Phase 6.10 Rem 4 Item 1 — include renderVersion in the
            // SwiftUI identity so route republishes always force a
            // fresh `makeUIView` (defensive against the same-slug-
            // return case where `.id(slug)` alone wouldn't change
            // identity).
            .id("\(slug)#\(renderVersion)")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(UIColor.systemGroupedBackground))
            .ignoresSafeArea(.all)
            .accessibilityIdentifier("voyager-root-host")
            .accessibilityElement(children: .contain)
        .onReceive(VoyagerBridge.routeChanged) { newSlug in
            // Bump renderVersion FIRST so the new identity is in place
            // BEFORE the slug update triggers re-evaluation; both
            // changes coalesce into a single SwiftUI render pass.
            renderVersion &+= 1
            if newSlug != slug {
                slug = newSlug
            }
        }
        .onAppear {
            // Make sure VoyagerBridge.initialize runs so the route-changed
            // callback is registered BEFORE any tap handler inside the
            // Crystal view tree fires coord.push(...).
            VoyagerBridge.initialize()
        }
    }
}

/// Bridges a Crystal-produced UIView into the SwiftUI tree.
///
/// Mirrors Cascade's CascadeHost — return the Crystal UIStackView root
/// DIRECTLY so SwiftUI ScrollView reads its intrinsic content size
/// correctly. Wrapping in an extra UIView container with edge-pinned
/// constraints broke the intrinsic-size chain (the container had no
/// intrinsicContentSize of its own, so SwiftUI ScrollView gave it 0
/// height, which collapsed the inner UIStackView's arranged subviews).
///
/// Slug swaps are handled by `.id(slug)` on the SwiftUI side which
/// forces a fresh `makeUIView` call each time the route changes.
///
/// Phase 6.10 Rem 4: `updateUIView` is now the SAFETY NET for the
/// Save-propagation path. When the parent ContentView bumps
/// `renderVersion` (every coordinator publish), the `.id()` should
/// already discard + recreate the representable. But if SwiftUI ever
/// elides the recreation, `updateUIView` defensively re-builds the
/// Crystal content for the current slug and swaps it in place.
struct VoyagerHost: UIViewRepresentable {
    let slug: String
    let renderVersion: Int

    func makeUIView(context: Context) -> UIView {
        guard let crystalRoot = VoyagerBridge.render(slug: slug) else {
            let fallback = UILabel()
            fallback.text = "render failed: \(slug)"
            fallback.accessibilityIdentifier = "voyager-root-fallback"
            return fallback
        }
        crystalRoot.accessibilityIdentifier = "voyager-root-\(slug)"

        // Phase 6.10 Rem 3 (Item 3 Layer A — framework default):
        //
        // If the Crystal-side screen already wraps its content in a
        // UI::ScrollView (Layer B explicit override), the rendered root
        // IS already a UIScrollView — return it unwrapped to avoid
        // nested scrollviews.
        if crystalRoot is UIScrollView {
            return crystalRoot
        }

        // Otherwise wrap in a UIKit UIScrollView so any overflowing
        // content scrolls vertically. UIKit (NOT SwiftUI) UIScrollView
        // preserves the AX-tree traversal won in Rem 2 — XCUITest walks
        // through it transparently. Constraints pin the Crystal root's
        // edges to the scroll view's contentLayoutGuide and pin its
        // width to frameLayoutGuide so only the vertical axis scrolls
        // (mirrors the proven-working UIKit renderer's
        // uiscrollview_pin_content pattern at
        // `src/ui/renderers/uikit_renderer.cr#visit(ScrollView)`).
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.alwaysBounceHorizontal = false
        scroll.showsHorizontalScrollIndicator = false
        // Re-use the same AX identifier the bare-root path uses so
        // XCUITest selectors stay stable across the wrap / no-wrap
        // branches.
        scroll.accessibilityIdentifier = "voyager-root-\(slug)"

        crystalRoot.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(crystalRoot)
        // Phase 6.10 Rem 3 (Codex review 1, P2 #1): the width constraint
        // between the Crystal root and the scroll's frameLayoutGuide
        // must NOT be required priority. The Voyager screens emit a
        // required `min_w == max_w == 340.0` constraint on their root
        // VStack (UIKit renderer's `objc_constrain_*` helpers default
        // to priority 1000). A second required width constraint here
        // creates a conflict that Auto Layout resolves by breaking one
        // unpredictably. Use `.defaultHigh` (priority 750) so the
        // inner 340pt pin wins. The constraint's job is to prevent
        // horizontal overflow when the Crystal root has no explicit
        // width pin — high priority is sufficient because the scroll's
        // contentLayoutGuide leading/trailing anchors already define
        // the horizontal bounds.
        let widthHint = crystalRoot.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        widthHint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            crystalRoot.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            crystalRoot.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            crystalRoot.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            crystalRoot.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            widthHint,
        ])
        return scroll
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Phase 6.10 Rem 4 Item 1 — safety net.
        //
        // Slug changes are normally handled by `.id("slug#renderVersion")`
        // on the SwiftUI side, which discards this representable and
        // calls `makeUIView` fresh. But if SwiftUI ever elides that
        // recreation (e.g. same identity hash, or a coalesced update),
        // we defensively re-build the Crystal content here so the
        // user-visible UIView ALWAYS reflects the latest Crystal state.
        //
        // The owner's Rem 3 hand-test bug: Save → pop → Todos list does
        // not show the new todo. Even if `.id()` discards reliably, the
        // bug-proof posture is: always be ready to swap content on
        // update, never assume identity-based discard alone.

        // If the existing UIView is our UIScrollView wrap (from
        // makeUIView), the Crystal root is the FIRST subview. Re-render
        // and swap it. If the existing UIView is the Crystal root
        // directly (already a UIScrollView), just replace the whole
        // representable's hosted view — but UIViewRepresentable doesn't
        // expose a `replaceRoot` API, so we mutate in place by removing
        // all subviews + adding the freshly-rendered root.
        guard let crystalRoot = VoyagerBridge.render(slug: slug) else {
            return
        }
        crystalRoot.accessibilityIdentifier = "voyager-root-\(slug)"

        if let scroll = uiView as? UIScrollView, scroll.accessibilityIdentifier == "voyager-root-\(slug)" || scroll.accessibilityIdentifier?.hasPrefix("voyager-root-") == true {
            // Drop the old Crystal root subview(s); pin the new one.
            for sub in scroll.subviews {
                sub.removeFromSuperview()
            }
            crystalRoot.translatesAutoresizingMaskIntoConstraints = false
            scroll.addSubview(crystalRoot)
            let widthHint = crystalRoot.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
            widthHint.priority = .defaultHigh
            NSLayoutConstraint.activate([
                crystalRoot.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
                crystalRoot.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
                crystalRoot.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
                crystalRoot.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
                widthHint,
            ])
            scroll.accessibilityIdentifier = "voyager-root-\(slug)"
        } else {
            // Crystal root is the representable's view directly — we
            // can't swap the representable's hosted view from here, but
            // the `.id()` bump on the parent side should already have
            // discarded this representable and called makeUIView fresh.
        }
    }
}
