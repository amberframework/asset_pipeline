// ToggleFacade — SwiftUI Toggle(isOn:) bridge.
//
// Phase 3 Remediation 4: `makeReactiveToggle` writes the underlying
// `BoolStorage` pointer through `outState` so Crystal can mutate
// `storage.value` later via `apsk_toggle_set_value` (programmatic isOn).
//
// Phase 3 Remediation 10: on iOS the Toggle is now rendered through a
// UIViewRepresentable wrapping a UIKit `UISwitch` instead of a SwiftUI
// `Toggle(isOn:)`. R9 evidence + R10 baseline reproduction proved that
// `XCUIElement.tap()` against the AX switch element produced by a
// SwiftUI `Toggle(isOn:)` (hosted via UIHostingController-in-
// UIViewRepresentable) does NOT flip the binding — the tap reaches the
// AX layer but routes through an accessibility-activate path SwiftUI's
// `Toggle(isOn:)` value-bound internals do not pick up. Coordinate taps
// flipped the same Toggle (R9 evidence), proving the Crystal/Swift
// callback chain is intact. `UISwitch` is the canonical Apple value-
// bound control with first-class XCUITest interop:
// `UISwitch.accessibilityActivate` translates directly to
// `setOn:!isOn animated:` and fires `UIControlEventValueChanged`, which
// drives the storage write + Crystal callback fire.
//
// macOS keeps the SwiftUI Toggle path — AppKit-side rendering and
// XCUITest tap routing differ; the BX3 bug is iOS-only.

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@objc(APSKToggleFacade)
public class ToggleFacade: NSObject {
    @objc public static func makeToggle(
        label: String,
        isOn: Bool,
        overrides: ToggleOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        return makeReactiveToggle(
            label: label, isOn: isOn,
            overrides: overrides, actionToken: actionToken, outState: nil
        )
    }

    @objc public static func makeReactiveToggle(
        label: String,
        isOn: Bool,
        overrides: ToggleOverrides,
        actionToken: UInt64,
        outState: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
    ) -> APSKPlatformView {
        let storage = BoolStorage(initial: isOn, token: actionToken)

        if let outState = outState {
            outState.pointee = Unmanaged.passRetained(storage).toOpaque()
        }

        return HostingHelpers.host(
            ToggleHost(
                label: label,
                storage: storage,
                overrides: overrides,
                actionToken: actionToken
            )
        )
    }
}

// On iOS the host wraps a UIKit `APSKToggleRepresentable` (UISwitch); a
// SwiftUI `Text(label)` is paired beside it via HStack so the visible
// label that SwiftUI's `Toggle(label:)` provided isn't lost.
//
// On macOS the historical SwiftUI Toggle path is preserved (BX3 is iOS-
// only; macOS BX2 already PASSES via SwiftUI Toggle + AppKit rendering).
private struct ToggleHost: View {
    let label: String
    @ObservedObject var storage: BoolStorage
    let overrides: ToggleOverrides
    let actionToken: UInt64

    var body: some View {
        #if canImport(UIKit)
        // ----- iOS path: UIViewRepresentable wrapping UISwitch -----
        var content: AnyView = AnyView(
            HStack(spacing: 8) {
                if !label.isEmpty {
                    Text(label)
                }
                APSKToggleRepresentable(
                    storage: storage,
                    overrides: overrides,
                    actionToken: actionToken
                )
            }
        )

        if let disabled = overrides.disabled, disabled.boolValue {
            content = AnyView(content.disabled(true))
        }

        return CommonModifiers.apply(content, overrides: overrides)
        #else
        // ----- macOS path: original SwiftUI Toggle (BX3 is iOS-only) -----
        var content: AnyView = AnyView(
            Toggle(label, isOn: $storage.value)
                .onChange(of: storage.value) { newValue in
                    if storage.suppressNextFire {
                        storage.suppressNextFire = false
                        return
                    }
                    CallbackBridge.fire(
                        token: storage.token,
                        value: newValue ? 1.0 : 0.0
                    )
                }
                .contentShape(Rectangle())
        )

        switch overrides.toggleStyle {
        case "button":   content = AnyView(content.toggleStyle(.button))
        case "switch":   content = AnyView(content.toggleStyle(.switch))
        case "checkbox": content = AnyView(content.toggleStyle(.checkbox))
        default: break
        }

        if let disabled = overrides.disabled, disabled.boolValue {
            content = AnyView(content.disabled(true))
        }

        return CommonModifiers.apply(content, overrides: overrides)
        #endif
    }
}

#if canImport(UIKit)
// APSKToggleRepresentable — wraps a UIKit `UISwitch` so XCUIElement.tap()
// routes through the canonical UIControl tap-handling that fires
// `UIControlEventValueChanged`. Crystal-side programmatic mutations
// (apsk_toggle_set_value) flow through the @ObservedObject storage and
// land in `updateUIView`, which mirrors the new value onto the UISwitch
// via `setOn:animated:false` — UIKit programmatic setters do NOT
// re-fire valueChanged, so there is no callback loop.
private struct APSKToggleRepresentable: UIViewRepresentable {
    @ObservedObject var storage: BoolStorage
    let overrides: ToggleOverrides
    let actionToken: UInt64

    func makeUIView(context: Context) -> UISwitch {
        let sw = UISwitch()
        sw.addTarget(context.coordinator,
                     action: #selector(Coordinator.valueChanged(_:)),
                     for: .valueChanged)
        sw.setOn(storage.value, animated: false)
        applyOverrides(to: sw)
        return sw
    }

    func updateUIView(_ sw: UISwitch, context: Context) {
        // Crystal-driven programmatic mutation: storage.value flipped,
        // SwiftUI re-evaluated body, updateUIView fires. Mirror onto
        // UISwitch without re-firing valueChanged (programmatic setOn
        // does not invoke target-action).
        if sw.isOn != storage.value {
            sw.setOn(storage.value, animated: false)
        }
        // Re-apply overrides every update so accessibilityIdentifier /
        // accessibilityLabel / isEnabled / tints reflect the latest
        // override values (these can change post-mount on reactive paths).
        applyOverrides(to: sw)
        context.coordinator.storage = storage
        context.coordinator.actionToken = actionToken
    }

    private func applyOverrides(to sw: UISwitch) {
        // accessibilityIdentifier must be set DIRECTLY on the UISwitch —
        // XCUITest's `app.switches["…"]` lookup queries the AX
        // identifier on the focal switch element, not on outer modifiers.
        if let axId = overrides.accessibilityIdentifier, !axId.isEmpty {
            sw.accessibilityIdentifier = axId
        }
        if let axLabel = overrides.apskAccessibilityLabel, !axLabel.isEmpty {
            sw.accessibilityLabel = axLabel
        }
        if let disabled = overrides.disabled {
            sw.isEnabled = !disabled.boolValue
        } else {
            sw.isEnabled = true
        }
        // ViewOverrides exposes `backgroundColor` / `foregroundColor`; iOS
        // UISwitch maps the "on" tint to `onTintColor`. We reuse the
        // foregroundColor field as the tint hint (callers that want a
        // brand-tinted switch should set it via the existing populator
        // path). nil = system default tint.
        if let onColor = overrides.foregroundColor {
            sw.onTintColor = onColor
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(storage: storage, actionToken: actionToken)
    }

    final class Coordinator: NSObject {
        var storage: BoolStorage
        var actionToken: UInt64

        init(storage: BoolStorage, actionToken: UInt64) {
            self.storage = storage
            self.actionToken = actionToken
        }

        @objc func valueChanged(_ sender: UISwitch) {
            // User-initiated change (or XCUIElement.tap synthesizing
            // through UIControl). Update storage WITHOUT routing
            // through the SwiftUI-only `suppressNextFire` flag — that
            // flag was designed for the SwiftUI `.onChange` consumer
            // on the macOS path. The UIKit-wrapper path doesn't have a
            // SwiftUI onChange observer, so suppressNextFire is unused
            // here. The equality check in `updateUIView` is what
            // prevents the Crystal→storage→updateUIView→UISwitch.setOn
            // loop from re-firing this callback.
            storage.value = sender.isOn
            CallbackBridge.fire(
                token: actionToken,
                value: sender.isOn ? 1.0 : 0.0
            )
        }
    }
}
#endif
