# iOS XCUITest Crash Root Causes (iter 6)

## BX4 (`testBX4_sliderValueCallback`) — CrystalHIGHost crashed in <external symbol>

**Signal:** EXC_BAD_ACCESS KERN_INVALID_ADDRESS at 0x4
**Top frame:** `Array(UInt8)#[]<Int32>` from `Float::Printer::RyuPrintf::d2fixed_buffered_n`
**Call site:** `UI::Probes::SliderProbe::formatted` -> `sprintf(Float64)` -> Crystal Float printer panic
**Slug:** `phase-03-slider-value-probe` — crashes when probe formats the slider's current value
**Root cause class:** **NOT a SwiftUI hit-test gap.** This is a Crystal-side Float-to-String formatting failure inside the probe singleton. Likely a stack guard or initialization-order issue inside RyuPrintf when called early on iOS.
**Implementer's BX4 claim of "same UIHostingController hit-test gap as BX3" is incorrect** — BX4 never reaches a tap because the host crashes during the initial render.

## BX8 (`testBX8_sheetDismissReturnsFocus`) — CrystalHIGHost crashed in <external symbol>

**Signal:** EXC_BAD_ACCESS KERN_INVALID_ADDRESS at 0x0
**Top frame:** `_platform_strlen` from `NSString stringWithUTF8String:`
**Call site:** `apsk_nsstring` <- `apsk_make_label_reactive` <- `UI::UIKit::Renderer#visit<UI::Label>`
**Slug:** `phase-03-sheet-focus-return` — crashes during initial slug render before sheet is even presented
**Root cause class:** **Integration-level bug in the bridge.** A NULL C string pointer reaches `apsk_nsstring` when rendering one of the Labels in the sheet-focus-return slug. Likely a Crystal-side `String#to_unsafe` returning NULL when the source string is nil/uninitialised.
**Implementer's claim that BX8 "Crystal host crashes on launch" is verified.**
