// DatePickerFacade — SwiftUI DatePicker(...) bridge.

import SwiftUI
import Foundation

@objc(APSKDatePickerFacade)
public class DatePickerFacade: NSObject {
    @objc public static func makeDatePicker(
        label: String,
        initialEpoch: Double,
        overrides: DatePickerOverrides,
        actionToken: UInt64
    ) -> APSKPlatformView {
        let storage = DateStorage(initial: Date(timeIntervalSince1970: initialEpoch), token: actionToken)

        let components: DatePickerComponents
        switch overrides.datePickerMode {
        case "time":        components = .hourAndMinute
        case "datetime":    components = [.date, .hourAndMinute]
        default:            components = .date
        }

        var content: AnyView = AnyView(
            DatePicker(label, selection: storage.binding, displayedComponents: components)
        )

        content = CommonModifiers.apply(content, overrides: overrides)
        return HostingHelpers.host(DateHost(storage: storage, content: content))
    }
}

struct DateHost<Content: View>: View {
    @ObservedObject var storage: DateStorage
    let content: Content
    var body: some View { content }
}
