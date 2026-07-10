# R10 Part 2 — BX8 sheet slug evidence

Date: 2026-05-21
Branch: phase-03-swiftui-native-bridge, HEAD a2e56bb
Simulator: iPhone 17 Pro (UDID 92DA97A0-5FEC-46BD-A525-8AFE2A4FDC21, iOS 26.5)

## Baseline reproduction

### testBX8_sheetDismissReturnsFocus — FAIL

```
t = 4.69s Checking existence of "sheet-trigger" Button        ← FOUND
t = 4.71s Checking existence of "sheet-primary" Button        ← NOT FOUND
Phase03BehaviorTests.swift:354: error: XCTAssertTrue failed:
  BX8: sheet-primary must exist
```

- `sheet-trigger` exists in the AX tree.
- `sheet-primary` does NOT exist in the AX tree at launch.
- The test (line 354) currently expects `sheet-primary` to exist at launch
  without ever tapping `sheet-trigger` first. This is structurally wrong
  for SwiftUI `.sheet(isPresented:)` — content is conditionally rendered.

## Code inspection

### Gap 1 (proven): sheet-trigger has empty on_tap

samples/cross_platform/ios_host/hig_bridge.cr:3163
```crystal
ios_sheet_trigger = UI::Button.new("Open sheet") { }
```

The block is empty. Even if a reactive Sheet bridge existed, tapping
`sheet-trigger` would not present the sheet because nothing mutates
`ios_sheet_v.is_presented`.

### Gap 2 (proven): SheetFacade reads initial isPresented once

swift/AssetPipelineSwiftKit/.../SheetFacade.swift:24
```swift
let isPresented = overrides.isPresented?.boolValue ?? false
let storage = BoolStorage(initial: isPresented, token: dismissToken)
...
.sheet(isPresented: storage.binding, onDismiss: { ... })
```

`storage` is constructed once at facade-make-time. `BoolStorage` IS an
ObservableObject, so updates to `storage.value` would update the binding.
BUT — Crystal-side mutation of `UI::Sheet#is_presented` does NOT reach
`storage.value` because there is no reactive bridge:

- `UI::Sheet` (src/ui/views/sheet.cr) declares `property is_presented :
  Bool = false` — a plain setter. No `apsk_sheet_set_presented` call. No
  swiftkit_state_handle wiring.
- `LibSwiftKitBridge` (src/ui/native/swiftkit_bridge.cr) has no
  `apsk_make_sheet_reactive` and no `apsk_sheet_set_presented` fun.
- swiftkit_bridge.m has no `apsk_make_sheet_reactive` trampoline.
- uikit_renderer's `visit(view : UI::Sheet)` calls `apsk_make_sheet` (the
  static, non-reactive entry point) and never sets `view.swiftkit_state_handle`
  or `handle.state_handle`.

So `sheet.is_presented = true` is purely a Crystal-side property write
that never reaches SwiftUI. The full reactive bridge (Swift + Crystal sides)
must ship for sheet presentation to work end-to-end.

### Gap 3 (HYPOTHESIS — not yet proved)

Once the trigger is wired and the sheet opens, `sheet-content`,
`sheet-primary`, `sheet-cancel` may or may not surface to XCUITest. Brief
mandates an `app.debugDescription` dump after the sheet animates open to
discover the correct collection (sheets vs otherElements) and any AX-tree
gaps (e.g. APSKHostedChild boundary blocking descent). We will run that
diagnostic AFTER applying the Swift + Crystal reactive Sheet bridge and
wiring the trigger.

## Required fixes (matches brief)

1. **Crystal slug rewrite** (hig_bridge.cr):
   - sheet-trigger.on_tap → `sheet_v.is_presented = true`
   - sheet-primary.on_tap → record reason, set explicit flag, then
     `sheet_v.is_presented = false`
   - sheet-cancel.on_tap → record reason, set explicit flag, then
     `sheet_v.is_presented = false`
   - sheet_v.on_dismiss → record "swipe" reason ONLY IF explicit flag is
     false; always reset explicit flag

2. **Swift reactive Sheet bridge**:
   - Add `SheetState : ObservableObject` with `@Published var isPresented: Bool`
     in ReactiveState.swift
   - Add `apsk_sheet_set_presented` @_cdecl mutator in ReactiveState.swift
   - Refactor SheetFacade to take/expose a SheetState (replace the local
     `BoolStorage(initial:token:)` with `SheetState`), with new
     `makeReactiveSheet(...:outState:)` selector
   - Add `apsk_make_sheet_reactive` C trampoline in swiftkit_bridge.m

3. **Crystal LibSwiftKitBridge**:
   - Add `apsk_make_sheet_reactive` and `apsk_sheet_set_presented` fun decls
     in swiftkit_bridge.cr

4. **UI::Sheet view**:
   - Add `def is_presented=(new_value : Bool) : Bool` that dispatches
     through LibSwiftKitBridge.apsk_sheet_set_presented when
     swiftkit_state_handle is set

5. **uikit_renderer visit(UI::Sheet)**:
   - Call `apsk_make_sheet_reactive` with `state_box : Void**` out-parameter
   - Store result on handle.state_handle AND view.swiftkit_state_handle

6. **DismissProbe** — add `explicit?` flag handling so on_dismiss doesn't
   stomp button-driven reason.

7. **Test rewrite** (Phase03BehaviorTests.swift testBX8):
   - Initial assertion: sheet-trigger exists; sheet-* content does NOT
   - Tap trigger, wait for `app.buttons["sheet-primary"].waitForExistence`
   - For each of 3 dismiss paths (primary, cancel, swipe):
     - re-tap sheet-trigger
     - perform the dismiss action
     - assert sheet content vanishes (waitForExistence with NSPredicate exists == false)
     - assert dismiss-reason mirror label transitioned correctly
   - Final: assert sheet-trigger is re-discoverable (focus return rubric)

8. **AX-dump diagnostic** (Gap-3 — after 1-6 are applied):
   - run a one-off probe test that taps trigger, sleeps for animation,
     dumps `app.debugDescription` to console
   - decide based on output whether queries need `app.sheets[…]` or
     `app.otherElements[…]` or AX-element-children annotation in the
     facade
