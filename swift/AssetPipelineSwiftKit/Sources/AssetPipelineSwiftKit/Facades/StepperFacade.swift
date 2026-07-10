// StepperFacade — SwiftUI Stepper(value:in:step:) bridge.

import SwiftUI
import Foundation

@objc(APSKStepperFacade)
public class StepperFacade: NSObject {
    @objc public static func makeStepper(
        label: String,
        value: Double,
        minimum: Double,
        maximum: Double,
        overrides: StepperOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = DoubleStorage(initial: value, token: actionToken)
        let step = overrides.step?.doubleValue ?? 1.0

        var content: AnyView = AnyView(
            Stepper(label,
                    value: storage.binding,
                    in: minimum...maximum,
                    step: step)
        )

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(DoubleHost(storage: storage, content: content))
    }
}
