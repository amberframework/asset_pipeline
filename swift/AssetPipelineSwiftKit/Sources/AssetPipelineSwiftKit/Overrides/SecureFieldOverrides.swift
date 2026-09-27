// SecureFieldOverrides — SwiftUI's `SecureField` ships obscured glyphs,
// password-AutoFill, and accessibility traits at the default; the only
// per-field knobs are the brand font fields (so a password field matches its
// sibling text fields on a sign-in / sign-up surface).

import Foundation

@objc(APSKSecureFieldOverrides)
public class SecureFieldOverrides: ViewOverrides {
    // Crystal `text_alignment`: logical leading / center / trailing placement
    // for both the value and the custom placeholder overlay.
    @objc public var textAlignment: String? = nil
    // Font: point size, raw Font.Weight intValue, custom family / PostScript
    // name. nil = SwiftUI default. Mirrors TextFieldOverrides.
    @objc public var fontSize: NSNumber? = nil
    @objc public var fontWeight: NSNumber? = nil
    @objc public var fontFamily: String? = nil

    @objc public override init() { super.init() }
}
