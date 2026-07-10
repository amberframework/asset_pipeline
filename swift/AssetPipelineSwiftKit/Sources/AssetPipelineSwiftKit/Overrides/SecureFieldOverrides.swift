// SecureFieldOverrides — empty by design; SwiftUI's `SecureField` ships
// every behaviour we need (obscured glyphs, password-AutoFill, accessibility
// traits) at the default. Override carrier exists for future-proofing.

import Foundation

@objc(APSKSecureFieldOverrides)
public class SecureFieldOverrides: ViewOverrides {
    @objc public override init() { super.init() }
}
