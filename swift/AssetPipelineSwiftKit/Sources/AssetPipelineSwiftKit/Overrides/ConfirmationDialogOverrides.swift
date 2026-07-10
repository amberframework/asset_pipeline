// ConfirmationDialogOverrides — per-ConfirmationDialog overrides above
// ViewOverrides.
//
// Field semantics:
//   title         : dialog title (positional on the facade).
//   message       : optional message body.
//   isPresented   : NSNumber bool. nil = false.
//   confirmLabel  : confirm button label. nil = "Confirm".
//   cancelLabel   : cancel button label. nil = "Cancel".
//   confirmStyle  : "default" | "destructive". nil = "default".
//   confirmToken  : NSNumber UInt64 action token for confirm.
//   cancelToken   : NSNumber UInt64 action token for cancel.

import Foundation

@objc(APSKConfirmationDialogOverrides)
public class ConfirmationDialogOverrides: ViewOverrides {
    @objc public var title: String? = nil
    @objc public var message: String? = nil
    @objc public var isPresented: NSNumber? = nil
    @objc public var confirmLabel: String? = nil
    @objc public var cancelLabel: String? = nil
    @objc public var confirmStyle: String? = nil
    @objc public var confirmToken: NSNumber? = nil
    @objc public var cancelToken: NSNumber? = nil

    @objc public override init() { super.init() }
}
