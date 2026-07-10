// TextFieldOverrides — per-TextField overrides above ViewOverrides.
//
// Fields:
//   secureEntry  : NSNumber bool. nil = SwiftUI default (`TextField`,
//                  not `SecureField`).
//   keyboardType : "default" | "email" | "number" | "phone" | "url" — only
//                  consumed on iOS via `.keyboardType(_:)`. nil = default.

import Foundation

@objc(APSKTextFieldOverrides)
public class TextFieldOverrides: ViewOverrides {
    @objc public var secureEntry: NSNumber? = nil
    @objc public var keyboardType: String? = nil

    @objc public override init() { super.init() }
}
