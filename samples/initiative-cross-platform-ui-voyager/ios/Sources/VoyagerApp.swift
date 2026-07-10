import SwiftUI
import UIKit

// SwiftUI @main entry for the Voyager Phase 6.10 navigable demo.
//
// Unlike Cascade (which renders ONE slug from a launch arg), Voyager
// owns a NavigationCoordinator-driven app: the initial slug comes from
// VOYAGER_ROOT_SLUG / -VoyagerRoot launch arg (default "voyager-sign-in"),
// and SwiftUI re-renders whenever the Crystal-side coordinator notifies
// a route change via the C-callable route-changed callback wired in
// VoyagerBridge.

@main
struct VoyagerApp: App {
    @UIApplicationDelegateAdaptor(VoyagerAppDelegate.self) var delegate

    var rootSlug: String {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-VoyagerRoot"), i + 1 < args.count {
            return args[i + 1]
        }
        return ProcessInfo.processInfo.environment["VOYAGER_ROOT_SLUG"] ?? "voyager-sign-in"
    }

    var body: some Scene {
        WindowGroup {
            ContentView(initialSlug: rootSlug)
                .preferredColorScheme(preferredScheme)
        }
    }

    private var preferredScheme: ColorScheme? {
        let env = ProcessInfo.processInfo.environment
        switch env["VOYAGER_APPEARANCE"] ?? env["HIG_APPEARANCE"] {
        case "dark":  return .dark
        case "light": return .light
        default:      return .light
        }
    }
}

final class VoyagerAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let cfg = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        cfg.delegateClass = VoyagerSceneDelegate.self
        return cfg
    }
}

final class VoyagerSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }
        let env = ProcessInfo.processInfo.environment
        let wantDark = (env["VOYAGER_APPEARANCE"] ?? env["HIG_APPEARANCE"] ?? "light") == "dark"
        let style: UIUserInterfaceStyle = wantDark ? .dark : .light
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            for w in ws.windows {
                w.overrideUserInterfaceStyle = style
            }
        }
    }
}
