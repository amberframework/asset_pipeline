// TextEditorOverrides — per-TextEditor overrides above ViewOverrides.

import Foundation

@objc(APSKTextEditorOverrides)
public class TextEditorOverrides: ViewOverrides {
    @objc public var editable: NSNumber? = nil
    @objc public var syntaxHighlighting: String? = nil

    @objc public override init() { super.init() }
}
