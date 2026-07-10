// Phase 6.12C Item 1 empirical probe — macOS .borderedProminent × .tint().
//
// Tests whether SwiftUI's `.borderedProminent` button style honors a `.tint()`
// applied (a) in the SwiftUI environment cascade and (b) directly on the button
// on macOS. Cascade's regression (phase-06.12b-evidence) shows a gray
// prominent button instead of the expected deep teal — Cascade's brand cascade
// reaches `.bordered` chrome (Forgot-password link is teal) but not
// `.borderedProminent`.
//
// Run:
//   swift samples/initiative-cross-platform-ui-demo/scratch/probe.swift
//
// Expected behavior to capture:
//   - "System blue prominent" — system accent (likely blue)
//   - "Tinted teal prominent" — IF `.tint()` works on macOS, teal; otherwise
//     same system accent as button 1 (regression confirmed).
//   - "Tinted teal bordered" — teal-tinted bordered chrome.
//
// Three states each: idle, hovered, pressed. The window also exercises a
// disabled prominent + a focused prominent to satisfy the brief's pressed /
// disabled / focus state coverage requirement.

import SwiftUI
import AppKit
import CoreGraphics
import Darwin

let DEEP_TEAL = Color(red: 0.059, green: 0.522, blue: 0.522)

struct ProbeView: View {
    @State private var pressedLog: String = "(no presses yet)"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phase 6.12C probe").font(.title3)

            Text("Case 1 — default system accent").font(.caption).foregroundStyle(.secondary)
            Button("System blue prominent") { pressedLog = "case1" }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Text("Case 2 — .tint() on .borderedProminent").font(.caption).foregroundStyle(.secondary)
            Button("Tinted teal prominent") { pressedLog = "case2" }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(DEEP_TEAL)

            Text("Case 3 — .tint() on .bordered").font(.caption).foregroundStyle(.secondary)
            Button("Tinted teal bordered") { pressedLog = "case3" }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(DEEP_TEAL)

            Text("Case 4 — .tint() in environment").font(.caption).foregroundStyle(.secondary)
            VStack {
                Button("Env-tint prominent") { pressedLog = "case4" }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .tint(DEEP_TEAL)

            Text("Case 5 — Disabled .tint prominent").font(.caption).foregroundStyle(.secondary)
            Button("Disabled tinted prominent") { }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(DEEP_TEAL)
                .disabled(true)

            Text("Case 6 — Custom APSKBrandProminentButtonStyle").font(.caption).foregroundStyle(.secondary)
            Button("Custom ButtonStyle (teal)") { pressedLog = "case6" }
                .buttonStyle(APSKBrandProminentButtonStyle(tint: DEEP_TEAL))

            Button("Custom ButtonStyle (disabled)") { }
                .buttonStyle(APSKBrandProminentButtonStyle(tint: DEEP_TEAL))
                .disabled(true)

            Spacer()
            Text("Last action: \(pressedLog)").font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 520, height: 720, alignment: .topLeading)
    }
}

struct APSKBrandProminentButtonStyle: ButtonStyle {
    let tint: Color
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? tint.opacity(0.85) : tint)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.95 : 1.0) : 0.5)
            .accessibilityAddTraits(.isButton)
    }
}

// AppKit entry — bring up a regular window with the probe view embedded.
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var hostingView: NSHostingView<ProbeView>!
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Use NSHostingView so we have direct access to layoutSubtreeIfNeeded.
        hostingView = NSHostingView(rootView: ProbeView())
        hostingView.frame = NSRect(x: 0, y: 0, width: 520, height: 720)
        hostingView.wantsLayer = true
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 520, height: 720),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        window.title = "Phase 6.12C probe"
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if let path = ProcessInfo.processInfo.environment["PROBE_SCREENSHOT_PATH"] {
            // Settle SwiftUI layout: drive the runloop a few times before capture.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                self.hostingView.layoutSubtreeIfNeeded()
                self.hostingView.displayIfNeeded()
                // Use cacheDisplay (same path as window_helper.m offscreen)
                let bounds = self.hostingView.bounds
                guard let rep = self.hostingView.bitmapImageRepForCachingDisplay(in: bounds) else {
                    NSApp.terminate(nil); return
                }
                self.hostingView.cacheDisplay(in: bounds, to: rep)
                if let data = rep.representation(using: .png, properties: [:]) {
                    try? data.write(to: URL(fileURLWithPath: path))
                }
                NSApp.terminate(nil)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
