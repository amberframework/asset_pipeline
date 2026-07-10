import SwiftUI
import UIKit

// SwiftUI @main entry point for the HIG visual-validation host.
// Reads the slug from the launch arg -HIGSlug <slug> (defaults to "buttons").
//
// @main avoids clashing with Crystal's _main via the
// `ld -r -unexported_symbol _main` step in build_crystal_lib.sh.

@main
struct CrystalHIGHostApp: App {
    @UIApplicationDelegateAdaptor(HIGAppDelegate.self) var delegate

    var slug: String {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-HIGSlug"), i + 1 < args.count {
            return args[i + 1]
        }
        return "buttons"
    }

    var body: some Scene {
        WindowGroup {
            ContentView(slug: slug)
                // IMPORTANT: no .background() here. The window background is
                // set to .clear in HIGSceneDelegate so UIVisualEffectView can
                // composite against the backdrop UIImageView installed by
                // HIGBackdropController.install(in:). Adding a solid
                // background here would flatten glass exactly as
                // cacheDisplayInRect: did on macOS before Phase 0.1.
                .preferredColorScheme(preferredScheme)
        }
    }

    private var preferredScheme: ColorScheme? {
        let env = ProcessInfo.processInfo.environment
        switch env["HIG_APPEARANCE"] {
        case "dark":  return .dark
        case "light": return .light
        default:      return .light
        }
    }
}

// UIApplicationDelegate that applies HIG_APPEARANCE to every connected
// UIWindow so the Liquid Glass materials sample the correct trait
// collection. SwiftUI's .preferredColorScheme modifies only the view
// environment; .overrideUserInterfaceStyle on the window is the
// authoritative knob for UIVisualEffectView material resolution.
//
// Additionally sets window.backgroundColor = .clear and installs the
// HIGBackdropController backdrop beneath the content hierarchy so that
// UIVisualEffectView materials can blur through real image content rather
// than a solid fill.
final class HIGAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let cfg = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        cfg.delegateClass = HIGSceneDelegate.self
        return cfg
    }
}

final class HIGSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }
        applyAppearance(to: ws)
    }

    private func applyAppearance(to scene: UIWindowScene) {
        let env = ProcessInfo.processInfo.environment
        let wantDark = (env["HIG_APPEARANCE"] ?? "light") == "dark"
        let style: UIUserInterfaceStyle = wantDark ? .dark : .light

        // Deferred apply so the SwiftUI-provided window is attached.
        // Two-step: first apply appearance + clear background, then install
        // the backdrop after one more runloop pass so rootViewController.view
        // is in the hierarchy.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            for w in scene.windows {
                // Step 1: appearance + transparent window background.
                // A clear window background is required for UIVisualEffectView
                // to composite against content beneath the window layer.
                // On the simulator this means the backdrop UIImageView
                // (installed at index 0 of rootViewController.view) is the
                // visible content that glass materials blur through.
                w.overrideUserInterfaceStyle = style
                w.backgroundColor = .clear
            }

            // Step 2: Install the backdrop one more pass later so
            // rootViewController.view is fully laid out.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                for w in scene.windows {
                    HIGBackdropController.install(in: w)
                }
            }
        }
    }
}
