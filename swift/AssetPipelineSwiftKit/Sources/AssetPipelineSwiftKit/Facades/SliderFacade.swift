// SliderFacade — SwiftUI Slider(value:in:) bridge.
//
// Phase 3 Remediation 4: `makeReactiveSlider` writes the underlying
// `DoubleStorage` pointer through `outState` so Crystal can later mutate
// `storage.value` via `apsk_slider_set_value`.

import SwiftUI
import Foundation

@objc(APSKSliderFacade)
public class SliderFacade: NSObject {
    @objc public static func makeSlider(
        value: Double,
        minimum: Double,
        maximum: Double,
        overrides: SliderOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        return makeReactiveSlider(
            value: value, minimum: minimum, maximum: maximum,
            overrides: overrides, actionToken: actionToken, outState: nil
        )
    }

    @objc public static func makeReactiveSlider(
        value: Double,
        minimum: Double,
        maximum: Double,
        overrides: SliderOverrides,
        actionToken: UInt64,
        outState: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
    ) -> APSKPlatformView {
        let storage = DoubleStorage(initial: value, token: actionToken)

        if let outState = outState {
            outState.pointee = Unmanaged.passRetained(storage).toOpaque()
        }

        return HostingHelpers.host(
            SliderDoubleHost(
                storage: storage,
                overrides: overrides,
                minimum: minimum,
                maximum: maximum
            )
        )
    }
}

// Shared host kept for non-reactive Double-bound facades (Stepper, etc.)
// that haven't been migrated to the SliderDoubleHost in-body pattern.
struct DoubleHost<Content: View>: View {
    @ObservedObject var storage: DoubleStorage
    let content: Content
    var body: some View { content }
}

// Slider is now constructed inside the View body so its Binding tracks
// the @ObservedObject. See ToggleFacade comments for the BX3 rationale.
struct SliderDoubleHost: View {
    @ObservedObject var storage: DoubleStorage
    let overrides: SliderOverrides
    let minimum: Double
    let maximum: Double

    var body: some View {
        let slider: AnyView
        if let step = overrides.step, step.doubleValue > 0 {
            slider = AnyView(
                Slider(
                    value: $storage.value,
                    in: minimum...maximum,
                    step: step.doubleValue
                )
            )
        } else {
            slider = AnyView(
                Slider(value: $storage.value, in: minimum...maximum)
            )
        }

        let content = AnyView(
            slider.onChange(of: storage.value) { newValue in
                if storage.suppressNextFire {
                    storage.suppressNextFire = false
                    return
                }
                CallbackBridge.fire(token: storage.token, value: newValue)
            }
        )
        return CommonModifiers.apply(content, overrides: overrides)
    }
}
