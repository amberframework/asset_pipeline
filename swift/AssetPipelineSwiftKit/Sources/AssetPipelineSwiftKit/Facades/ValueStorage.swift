// ValueStorage — shared @ObservedObject wrappers used by selection /
// form-control facades (Toggle, Slider, Stepper, Picker, etc.) to keep
// SwiftUI bindings alive across layout passes and propagate value
// changes back to Crystal through the CallbackBridge.

import SwiftUI
import Foundation

final class BoolStorage: ObservableObject {
    @Published var value: Bool
    let token: UInt64
    /// When true, `setProgrammatically(_:)` is updating `value` from a
    /// Crystal-side `apsk_toggle_set_value` call. The facade's `.onChange`
    /// callback uses this flag to suppress an outbound CallbackBridge.fire
    /// — programmatic mutations are NOT user interactions and must not
    /// re-fire the Crystal `on_change` handler.
    var suppressNextFire: Bool = false
    init(initial: Bool, token: UInt64) {
        self.value = initial
        self.token = token
    }
    /// Crystal-driven programmatic mutation entry point. Sets `value`
    /// while flagging the change so the facade's `.onChange` observer
    /// skips its callback fire.
    func setProgrammatically(_ newValue: Bool) {
        suppressNextFire = true
        value = newValue
    }
    var binding: Binding<Bool> {
        Binding(
            get: { self.value },
            set: { newValue in
                self.value = newValue
                CallbackBridge.fire(token: self.token, value: newValue ? 1.0 : 0.0)
            }
        )
    }
}

final class DoubleStorage: ObservableObject {
    @Published var value: Double
    let token: UInt64
    /// See BoolStorage.suppressNextFire — same semantics for sliders /
    /// other Double-bound controls.
    var suppressNextFire: Bool = false
    init(initial: Double, token: UInt64) {
        self.value = initial
        self.token = token
    }
    func setProgrammatically(_ newValue: Double) {
        suppressNextFire = true
        value = newValue
    }
    var binding: Binding<Double> {
        Binding(
            get: { self.value },
            set: { newValue in
                self.value = newValue
                CallbackBridge.fire(token: self.token, value: newValue)
            }
        )
    }
}

final class IntStorage: ObservableObject {
    @Published var value: Int
    let token: UInt64
    init(initial: Int, token: UInt64) {
        self.value = initial
        self.token = token
    }
    var binding: Binding<Int> {
        Binding(
            get: { self.value },
            set: { newValue in
                self.value = newValue
                CallbackBridge.fire(token: self.token, value: Double(newValue))
            }
        )
    }
}

final class DateStorage: ObservableObject {
    @Published var value: Date
    let token: UInt64
    init(initial: Date, token: UInt64) {
        self.value = initial
        self.token = token
    }
    var binding: Binding<Date> {
        Binding(
            get: { self.value },
            set: { newValue in
                self.value = newValue
                CallbackBridge.fire(token: self.token, value: newValue.timeIntervalSince1970)
            }
        )
    }
}

final class ColorStorage: ObservableObject {
    @Published var value: Color
    let token: UInt64
    init(initial: Color, token: UInt64) {
        self.value = initial
        self.token = token
    }
    var binding: Binding<Color> {
        Binding(
            get: { self.value },
            set: { newValue in
                self.value = newValue
                // Value channel carries 1.0 = "changed"; richer
                // colour-change dispatch is a future hook.
                CallbackBridge.fire(token: self.token, value: 1.0)
            }
        )
    }
}
