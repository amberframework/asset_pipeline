// SecureFieldOverrides — SwiftUI's `SecureField` ships obscured glyphs,
// password-AutoFill, and accessibility traits at the default; the only
// per-field knobs are the brand font and color fields (so a password field matches its
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
    // Value text color (Crystal `text_color`, sent only when the consumer
    // assigned it). nil = the appearance-tracking label color. When set, the
    // masked value draws in exactly this color in light and dark.
    @objc public var textColor: APSKPlatformColor? = nil
    // Placeholder tint. nil = the kit's contrast-safe default. Mirrors
    // TextFieldOverrides.placeholderColor.
    @objc public var placeholderColor: APSKPlatformColor? = nil

    @objc public override init() { super.init() }
}
