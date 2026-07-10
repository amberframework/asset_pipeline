// TextAreaOverrides — per-TextArea overrides above ViewOverrides.

import Foundation

@objc(APSKTextAreaOverrides)
public class TextAreaOverrides: ViewOverrides {
    @objc public var editable: NSNumber? = nil
    @objc public var scrollable: NSNumber? = nil
    @objc public var lineLimit: NSNumber? = nil

    @objc public override init() { super.init() }
}
