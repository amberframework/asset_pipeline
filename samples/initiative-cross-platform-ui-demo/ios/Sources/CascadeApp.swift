import SwiftUI
import UIKit

// SwiftUI @main entry — reads the slug from launch arg `-DemoSlug <slug>`
// (defaults to "demo-sign-in") and the appearance from env var
// DEMO_APPEARANCE / HIG_APPEARANCE. `@main` coexists with Crystal's
// _main via the `ld -r -unexported_symbol _main` step in
// build_crystal_lib.sh.

@main
struct CascadeApp: App {
    @UIApplicationDelegateAdaptor(CascadeAppDelegate.self) var delegate

    var slug: String {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-DemoSlug"), i + 1 < args.count {
            return args[i + 1]
        }
        return ProcessInfo.processInfo.environment["DEMO_SLUG"] ?? "demo-sign-in"
    }

    var body: some Scene {
        WindowGroup {
            ContentView(slug: slug)
                .preferredColorScheme(preferredScheme)
        }
    }

    private var preferredScheme: ColorScheme? {
        let env = ProcessInfo.processInfo.environment
        switch env["DEMO_APPEARANCE"] ?? env["HIG_APPEARANCE"] {
        case "dark":  return .dark
        case "light": return .light
        default:      return .light
        }
    }
}

final class CascadeAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let cfg = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        cfg.delegateClass = CascadeSceneDelegate.self
        return cfg
    }
}

final class CascadeSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }
        let env = ProcessInfo.processInfo.environment
        let wantDark = (env["DEMO_APPEARANCE"] ?? env["HIG_APPEARANCE"] ?? "light") == "dark"
        let style: UIUserInterfaceStyle = wantDark ? .dark : .light
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            for w in ws.windows {
                w.overrideUserInterfaceStyle = style
            }
        }
    }
}
