// SwiftUI Material API compile spike — Phase 5 v2 brief assumption A1.
//
// Purpose: prove every SwiftUI Material API named in the Phase 5 v2 per-widget
// defaults table compiles on both iOS 16.4+ and macOS 13.3+ SDKs:
//
//   * The 5 thickness Materials (.ultraThinMaterial / .thinMaterial /
//     .regularMaterial / .thickMaterial / .ultraThickMaterial)
//   * The chrome-tinted .bar Material (toolbar/tab-bar canonical)
//   * The .background(Material) modifier on a plain View (NavigationSplitView
//     sidebar Category B path)
//   * The .presentationBackground(Material) modifier (Sheet + Popover
//     Category B path - iOS 16.4+ / macOS 13.3+)
//   * The .toolbarBackground(Material, for:) modifier (TabView + Toolbar
//     Category B path)
//
// Compile via:
//   xcrun --sdk iphonesimulator swiftc -emit-library \
//     -target arm64-apple-ios16.4-simulator \
//     -o /tmp/spike-ios.dylib spikes/swiftui_material_spike.swift
//   xcrun --sdk macosx swiftc -emit-library \
//     -target arm64-apple-macos13.3 \
//     -o /tmp/spike-macos.dylib spikes/swiftui_material_spike.swift
//
// The explicit -target on iOS is required because xcrun's default when given
// the iPhoneSimulator SDK is still the host (macOS). The macOS target is
// pinned to 13.3 to match the presentationBackground availability floor.
//
// Both must exit 0 for assumption A1 to hold. If either fails, surface to
// architect - Phase 5 v2 cannot ship its claimed per-widget SwiftUI modifier
// delivery without working Material APIs on both platforms.

import SwiftUI

@available(iOS 16.4, macOS 13.3, *)
public struct APSKMaterialSpike: View {
    public let step: APSKMaterialStep

    public enum APSKMaterialStep {
        case ultraThin
        case thin
        case regular
        case thick
        case chrome  // Maps to .ultraThickMaterial (no public .chromeMaterial in SwiftUI)
        case bar     // Toolbar/tab-bar canonical Material (.bar)
    }

    @State private var sheetShown: Bool = false

    public var body: some View {
        // 1. Plain .background(Material) modifier - exercises all 6 materials.
        let materialBacked = Group {
            switch step {
            case .ultraThin:
                Text("MaterialSpike").padding().background(.ultraThinMaterial)
            case .thin:
                Text("MaterialSpike").padding().background(.thinMaterial)
            case .regular:
                Text("MaterialSpike").padding().background(.regularMaterial)
            case .thick:
                Text("MaterialSpike").padding().background(.thickMaterial)
            case .chrome:
                Text("MaterialSpike").padding().background(.ultraThickMaterial)
            case .bar:
                Text("MaterialSpike").padding().background(.bar)
            }
        }

        // 2. .presentationBackground(Material) - Sheet + Popover Category B
        //    code path. Verifies the modifier is exposed on both platforms.
        let sheetHost = materialBacked
            .sheet(isPresented: $sheetShown) {
                Text("SheetBody").padding().presentationBackground(.thickMaterial)
            }

        // 3. .toolbarBackground(Material, for:) - TabView + Toolbar Category B
        //    code path. Note: .navigationBar and .tabBar ToolbarPlacement cases
        //    are iOS-only (marked @available(macOS, unavailable)). The cross-
        //    platform-safe placement is .automatic, which the Phase 5 v2 facade
        //    will use by default; platform-specific overrides require #if
        //    os(iOS) guards inside the SwiftKit facade.
        let toolbarHosted = NavigationStack {
            sheetHost
                .toolbarBackground(.bar, for: .automatic)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Text("ToolbarItem")
                    }
                }
        }

        return toolbarHosted
    }
}
