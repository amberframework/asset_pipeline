# Behavior Simulation Toolkit

This document is the validator's reference for **driving** the rendered UI on each platform — invoking taps, presses, scrolls, type events, focus transitions, drag gestures, menu activations, and dismissal paths — and **observing** the consequences (state changes, accessibility-tree diffs, rendered geometry, focus restoration).

Every validator check in the cross-platform UI initiative that is held to the **behavior** or **conformance** bar in `rubric/validation_criteria.md` must drive the running app or browser, not the source. This document is the contract for *how*.

The validator environment for this initiative is **macOS** (local or Mac-in-the-cloud). All three platform toolchains are therefore available simultaneously: a booted iOS simulator, a launched macOS sample, and a Chrome session against the web demo.

---

## Section index

1. macOS — `UI::AXTest` and Carbon Accessibility API
2. iOS — XCUITest
3. Web — Chrome DevTools Protocol (CDP) over WebSocket from Crystal
4. Cross-platform patterns (action → state → output, dismiss flows, navigation flows, runtime override)
5. Recipes — copy-paste-able fragments per common action
6. AXTest extension gaps and proposed extensions

---

## 1. macOS — `UI::AXTest` and Carbon Accessibility API

### 1.1 What is wired today

`UI::AXTest` lives in `src/ui/ax_test/` and is the project's Crystal-native macOS UI testing framework. It wraps the Carbon Accessibility C API (`ApplicationServices.framework`) and a thin shim over `screencapture(1)`.

The framework exposes two types:

- `UI::AXTest::App` — launches or attaches to a running app and gives you a root `Element` plus screenshot helpers.
- `UI::AXTest::Element` — a single AXUIElement wrapper with attribute readers, search, and a press action.

It also exposes the raw `LibAX` and `LibCF` FFI bindings, which you can call directly when the high-level wrapper does not yet expose the action you need (see section 6).

Prerequisites the validator must verify before the first AX call:

- The app under test is code-signed (Phase 6 macOS sample's `make build` produces a signed binary; do not bypass).
- The Terminal (or whatever process is running `crystal spec`) holds the macOS Accessibility permission. Check with `UI::AXTest::App.accessibility_trusted?`. If `false`, the spec must `pending!` with a clear note; the validator does not toggle the system permission.
- Link flags `-framework ApplicationServices -framework CoreFoundation` are present in the spec's compile command.

### 1.2 Launching, attaching, and tearing down

Launch a built `.app` and wait for the run loop to settle:

```crystal
{% if flag?(:macos) %}
require "asset_pipeline/ui/ax_test"

app = UI::AXTest::App.launch("/path/to/DemoApp.app", wait_seconds: 3.0)
# ...drive the UI...
app.terminate
{% end %}
```

`App.launch` shells out to `open -a`, waits, then `pgrep`s the bundle name to find the PID. If you already know the PID (you started the binary yourself with `Process.new`), use:

```crystal
app = UI::AXTest::App.connect(pid)
```

Always set a generous messaging timeout before the first drive call — the default per-message timeout will surface as `AXErrorCannotComplete` on slow runs:

```crystal
# Already done by App#initialize: 10.0 seconds.
# If you need a longer one for a specific Element, call it directly:
LibAX.AXUIElementSetMessagingTimeout(element.ref, 30.0_f32)
```

Teardown is your responsibility. Every spec that launches a fresh app must terminate it:

```crystal
after_all { app.terminate }
```

A test scenario that crashes between launch and terminate will leave orphaned processes. Wrap the body in `begin/ensure`:

```crystal
begin
  app = UI::AXTest::App.launch(BIN_PATH)
  # drive
ensure
  app.terminate if app
end
```

### 1.3 Locating elements

The high-level search is breadth-first by role / label / title / subrole, with a configurable max depth:

```crystal
app.find(role: "AXButton", label: "Sign in", max_depth: 12)
app.find_all(role: "AXButton")
app.window("HIG: buttons")
app.windows  # all top-level windows of this app
```

Search criteria are matched **exactly** (no substring, no case-insensitivity). If a Crystal-side `UI::View.test_id` propagates to AppKit as `setAccessibilityIdentifier:`, you can find by it via the `AXIdentifier` attribute. Use the high-level `find(identifier:)` / `find!(identifier:)` (or the convenience `find_by_id` / `find_by_id!`) — these shipped as A1 (see section 6). Filter walks against `read_string_attribute("AXIdentifier")` only as a fallback for elements whose identifier was set via raw AX, not via a `UI::View.test_id`.

For deterministic test selectors, prefer `accessibilityIdentifier` over `label`. Labels are localized; identifiers are not. Phase 3 onward sets `test_id` on every demo button and the iOS bridge maps it through `setAccessibilityIdentifier:`. The same identifier propagates to `kAXIdentifierAttribute` on AppKit. Validator checks should compare against the identifier, not the visible title.

### 1.4 Reading attributes

The high-level `Element` exposes the most common attributes:

| Crystal method | Underlying Carbon attribute |
|---|---|
| `element.role` | `kAXRoleAttribute` |
| `element.title` | `kAXTitleAttribute` |
| `element.value` | `kAXValueAttribute` (string form only) |
| `element.label` | `kAXDescriptionAttribute` |
| `element.help` | `kAXHelpAttribute` |
| `element.subrole` | `kAXSubroleAttribute` |
| `element.enabled?` | `kAXEnabledAttribute` |
| `element.focused?` | `kAXFocusedAttribute` |
| `element.children` | `kAXChildrenAttribute` |
| `element.windows` | `kAXWindowsAttribute` |

For attributes the wrapper does not expose (position, size, identifier, selected children, role description, parent, top-level UI element, etc.), use the raw FFI directly. The pattern:

```crystal
def read_string_attribute_raw(element, attr_name : String) : String?
  cf = LibCF.CFStringCreateWithCString(Pointer(Void).null, attr_name.to_unsafe, LibCF::CFStringEncodingUTF8)
  value_ref = Pointer(Void).null
  err = LibAX.AXUIElementCopyAttributeValue(element.ref, cf, pointerof(value_ref))
  LibCF.CFRelease(cf)
  return nil unless err == LibAX::AXErrorSuccess && !value_ref.null?
  return nil unless LibCF.CFGetTypeID(value_ref) == LibCF.CFStringGetTypeID
  cstr = LibCF.CFStringGetCStringPtr(value_ref, LibCF::CFStringEncodingUTF8)
  result = cstr.null? ? nil : String.new(cstr)
  LibCF.CFRelease(value_ref)
  result
end

identifier = read_string_attribute_raw(button, "AXIdentifier")
```

Position and size are returned as `AXValueRef` boxes wrapping `CGPoint` / `CGSize`. The preferred path is the shipped A2 surface: `Element#position`, `Element#size`, `Element#frame`, and `Element#bounds_in_screen` (see section 6). They return `NamedTuple` with `x:`, `y:`, `width:`, `height:` keys. The older `osascript` + System Events pattern below is retained for completeness, but new code should not use it unless A2 returns nil (e.g., the element has no position attribute).

```crystal
def element_rect(app_name : String, locator_applescript : String) : Tuple(Int32, Int32, Int32, Int32)?
  script = <<-APPLESCRIPT
    tell application "System Events" to tell process "#{app_name}"
      set t to #{locator_applescript}
      set p to position of t
      set s to size of t
      return (item 1 of p as text) & "," & (item 2 of p as text) & "," & (item 1 of s as text) & "," & (item 2 of s as text)
    end tell
  APPLESCRIPT
  out = IO::Memory.new
  status = Process.run("/usr/bin/osascript", ["-e", script], output: out)
  return nil unless status.success?
  parts = out.to_s.strip.split(",")
  return nil unless parts.size == 4
  {parts[0].to_i32, parts[1].to_i32, parts[2].to_i32, parts[3].to_i32}
end
```

### 1.5 Performing actions

The wrapper today exposes one action: `Element#click`, which performs `kAXPressAction`. For every other action — `kAXShowMenu`, `kAXIncrement`, `kAXDecrement`, `kAXPick`, `kAXCancel`, `kAXConfirm`, `kAXRaise`, `kAXShowDefaultUI`, `kAXShowAlternateUI` — call `AXUIElementPerformAction` directly.

```crystal
def perform_action(element : UI::AXTest::Element, action_name : String) : Bool
  cf = LibCF.CFStringCreateWithCString(Pointer(Void).null, action_name.to_unsafe, LibCF::CFStringEncodingUTF8)
  err = LibAX.AXUIElementPerformAction(element.ref, cf)
  LibCF.CFRelease(cf)
  err == LibAX::AXErrorSuccess
end

# Press a button
perform_action(button, "AXPress")
# Show a popup button's menu
perform_action(popup, "AXShowMenu")
# Pick a menu item
perform_action(menu_item, "AXPick")
# Increment a stepper / slider via discrete action
perform_action(stepper, "AXIncrement")
```

Inspect what an element supports before driving it:

```crystal
puts element.action_names  # => ["AXPress"] for a default Button
```

### 1.6 Writing attributes

For widgets where the action surface is **value-driven** rather than discrete (sliders, text fields, color wells, popup buttons by index), set `kAXValueAttribute` directly. The raw FFI supports this; the wrapper does not yet expose a setter helper.

Setting a slider's normalized value:

```crystal
def set_double_value(element, value : Float64) : Bool
  # AXValueRef boxing for CGFloat. The simplest path: wrap the double in a CFNumber.
  attr = LibCF.CFStringCreateWithCString(Pointer(Void).null, "AXValue", LibCF::CFStringEncodingUTF8)
  num_ptr = Pointer(Float64).malloc(1)
  num_ptr.value = value
  # kCFNumberDoubleType = 13
  cf_num = LibCF.CFNumberCreate(Pointer(Void).null, 13, num_ptr.as(Void*))
  err = LibAX.AXUIElementSetAttributeValue(element.ref, attr, cf_num)
  LibCF.CFRelease(attr)
  LibCF.CFRelease(cf_num) unless cf_num.null?
  err == LibAX::AXErrorSuccess
end
```

Use `Element#set_value(value : Float64)` (shipped as A3, see section 6) — it boxes the value into a `CFNumber` and writes via `AXUIElementSetAttributeValue`. The raw `LibCF.CFNumberCreate` binding shown below is what A3 wraps; you should not normally need to call it directly.

Typing into a text field:

```crystal
# Focus the field first, then either:
#   (a) set its AXValue directly (string), or
#   (b) post synthetic keystrokes via CGEvent — heavier and racier.

# Path (a):
perform_action(field, "AXConfirm")  # ensure focus
attr = LibCF.CFStringCreateWithCString(Pointer(Void).null, "AXValue", LibCF::CFStringEncodingUTF8)
val  = LibCF.CFStringCreateWithCString(Pointer(Void).null, "hello".to_unsafe, LibCF::CFStringEncodingUTF8)
LibAX.AXUIElementSetAttributeValue(field.ref, attr, val)
LibCF.CFRelease(attr); LibCF.CFRelease(val)
```

If the widget rejects the direct value write (some custom controls do), fall back to CGEvent posting:

```crystal
@[Link(framework: "ApplicationServices")]
lib LibCGEvent
  fun CGEventCreateKeyboardEvent(src : Void*, keycode : UInt16, key_down : UInt8) : Void*
  fun CGEventPost(tap : Int32, evt : Void*) : Void
  fun CFRelease = CFRelease(cf : Void*) : Void
end

# 0 = kCGHIDEventTap
# Keycode 38 = 'j' (US layout). Real validator helpers should build a key-map.
evt_down = LibCGEvent.CGEventCreateKeyboardEvent(Pointer(Void).null, 38_u16, 1_u8)
LibCGEvent.CGEventPost(0, evt_down)
LibCGEvent.CFRelease(evt_down)
```

CGEvent posting is the macOS equivalent of XCUITest's `XCUIElement.typeText`. It is genuinely synthetic — it interacts with the system as if a user typed — so the validator must ensure the target app holds focus before posting.

### 1.7 Scrolling

`kAXScrollByXAction` and friends are not standard. Programmatic scrolling on macOS through AX is best driven by setting `kAXVerticalScrollBarAttribute`'s value or by sending a synthetic scroll wheel CGEvent:

```crystal
@[Link(framework: "ApplicationServices")]
lib LibCGEventScroll
  fun CGEventCreateScrollWheelEvent2(src : Void*, units : UInt32, wheel_count : UInt32,
      w1 : Int32, w2 : Int32, w3 : Int32) : Void*
  fun CGEventPost(tap : Int32, evt : Void*) : Void
  fun CFRelease = CFRelease(cf : Void*) : Void
end

# units: 0 = pixel, 1 = line
# Scroll up 60 pixels:
e = LibCGEventScroll.CGEventCreateScrollWheelEvent2(Pointer(Void).null, 0_u32, 1_u32, 60_i32, 0_i32, 0_i32)
LibCGEventScroll.CGEventPost(0, e)
LibCGEventScroll.CFRelease(e)
```

For widgets whose AX tree exposes a `kAXScrollAreaRole` ancestor, prefer reading the scroll position from `kAXValueAttribute` before and after the wheel post, and asserting the delta.

### 1.8 Focus and focus-restoration

Focus is a first-class AX attribute on macOS. Reading whether an element has keyboard focus:

```crystal
element.focused?  # convenience reader
```

Driving focus to an element programmatically (without clicking):

```crystal
attr = LibCF.CFStringCreateWithCString(Pointer(Void).null, "AXFocused", LibCF::CFStringEncodingUTF8)
true_ref = LibCF.kCFBooleanTrue  # bound in LibCF as part of A4
LibAX.AXUIElementSetAttributeValue(element.ref, attr, true_ref)
LibCF.CFRelease(attr)
```

Reading the focused element of the entire app (for restoration assertions):

```crystal
def focused_element(app : UI::AXTest::App) : UI::AXTest::Element?
  attr = LibCF.CFStringCreateWithCString(Pointer(Void).null, "AXFocusedUIElement",
                                          LibCF::CFStringEncodingUTF8)
  ref = Pointer(Void).null
  err = LibAX.AXUIElementCopyAttributeValue(app.root.ref, attr, pointerof(ref))
  LibCF.CFRelease(attr)
  return nil unless err == LibAX::AXErrorSuccess && !ref.null?
  UI::AXTest::Element.new(ref.as(LibAX::AXUIElementRef))
end
```

This is load-bearing for the "modal dismiss returns focus to trigger" check pattern in section 4.

### 1.9 Window resize via System Events

Use `App#resize_window(title, width, height, timeout = 5.0)` — shipped as A5 (see section 6). It sets `kAXSizeAttribute` on the window's AXUIElement and polls until the size attribute reflects the request. The older System Events fallback below is retained only for cases where the target app doesn't accept AX size writes.

```crystal
def resize_window(process_name : String, title : String, width : Int32, height : Int32)
  script = <<-APPLESCRIPT
    tell application "System Events" to tell process "#{process_name}"
      set size of (first window whose title is "#{title}") to {#{width}, #{height}}
    end tell
  APPLESCRIPT
  Process.run("/usr/bin/osascript", ["-e", script])
end

resize_window("demo_app", "Demo", 768, 800)
sleep(0.6)  # let layout settle past Phase 1 motion duration
```

This is the technique Phase 6's `resize.macos` check uses for its five-width sequence.

### 1.10 Screenshots

Three levels of capture, all going through `/usr/sbin/screencapture`:

- Full screen: `UI::AXTest::Screenshot.capture("/tmp/full.png")`
- By window ID (deterministic, no AX query needed): `UI::AXTest::Screenshot.capture_window(window_id, path)`
- By window title (AX query + crop via `screencapture -R`): `app.screenshot(path, window_title: "Demo")`

For deterministic per-window captures during a behavior run, prefer the by-window-ID path. Look up the window ID with `CGWindowListCopyWindowInfo` — for an example pattern see `samples/cross_platform/macos_host/window_helper.m`'s capture path.

The `app.screenshot(path, window_title: t)` path uses `osascript` to read window position/size, then `screencapture -R x,y,w,h`. It is slower but works without entitlements when the source window is on the active display.

The macOS HIG showcase host (`samples/cross_platform/macos_host/window_helper.m`) demonstrates the higher-fidelity path: snapshot the contentView directly via `cacheDisplayInRect:toBitmapImageRep:` (when materials are not in play) or composite via `CGWindowListCreateImage` when the snapshot must include `NSVisualEffectView` blur against the real backdrop. For the cross-platform initiative the simpler `screencapture`-based path is sufficient because the demo app uses solid surfaces; glass-cascade checks (Phase 5, BX6 / V6) require the live-window path and inherit the existing harness.

### 1.11 Putting it together — a complete behavior probe

```crystal
{% if flag?(:macos) %}
require "spec"
require "asset_pipeline/ui/ax_test"

describe "Sign-in primary CTA fires action" do
  bin = File.expand_path("../../../samples/initiative-cross-platform-ui-demo/macos/bin/demo_app", __DIR__)
  app : UI::AXTest::App? = nil

  before_all do
    env = {"DEMO_SCREEN" => "sign-in", "DEMO_TAP_PROBE" => "1"}
    process = Process.new(bin, env: env)
    sleep(2.0)
    app = UI::AXTest::App.connect(process.pid)
  end

  after_all { app.try &.terminate }

  it "increments TapProbe counter on every press" do
    a = app.not_nil!
    cta = a.find(role: "AXButton", label: "Sign in") || raise "CTA not located"

    3.times do
      cta_attr = LibCF.CFStringCreateWithCString(Pointer(Void).null, "AXPress",
                                                  LibCF::CFStringEncodingUTF8)
      LibAX.AXUIElementPerformAction(cta.ref, cta_attr)
      LibCF.CFRelease(cta_attr)
      sleep(0.15)  # let the callback flush
    end

    # Read the counter label — it mirrors the Crystal-side TapProbe.count
    counter = a.find(role: "AXStaticText", label: "tap-probe-counter") || raise "counter label missing"
    counter.value.should eq("3")
  end
end
{% end %}
```

This is the literal pattern Phase 3 BX2 and Phase 6 `nav.flow-end-to-end-macos` instantiate. Adapt the locator, the action, and the post-action assertion; the rest is the same.

---

## 2. iOS — XCUITest

### 2.1 What is wired today

The iOS sample at `samples/cross_platform/ios_host/` already has an XCUITest target. The single existing file `UITests/HIGVisualTests.swift` demonstrates the patterns the validator builds on:

- Setting `app.launchArguments` and `app.launchEnvironment` before `app.launch()`.
- Waiting on `app.otherElements["..."]` to appear via `waitForExistence(timeout:)`.
- Capturing screenshots via `XCUIScreen.main.screenshot()` or `app.windows.firstMatch.screenshot()` and attaching them via `XCTAttachment`.

The Phase 6 `nav.flow-end-to-end-ios` and Phase 3 BX1–BX6 checks all extend this target with new test classes.

### 2.2 Querying elements

Every Crystal `UI::View` with a `test_id` propagates through the SwiftUI bridge to `accessibilityIdentifier`. The XCUIElement query uses the identifier:

```swift
let cta = app.buttons["screen-sign-in-primary-cta"]
let card = app.buttons["screen-dashboard-activity-card-0"]
let titleLabel = app.staticTexts["screen-detail-title"]
let toggle = app.switches["screen-settings-notifications-toggle"]
let slider = app.sliders["screen-settings-volume-slider"]
let field = app.textFields["screen-sign-in-email"]
let secureField = app.secureTextFields["screen-sign-in-password"]
let tab = app.tabBars.buttons["Activity"]  // SwiftUI TabView label, not identifier
```

The TabView caveat from the project's memory applies: `.accessibilityIdentifier()` on SwiftUI tab content does not propagate to the tab-bar button. Address tabs by their visible label via `app.tabBars.buttons["Activity"]`.

Existence + state assertions:

```swift
XCTAssertTrue(cta.waitForExistence(timeout: 3))
XCTAssertTrue(cta.isHittable)
XCTAssertEqual(toggle.value as? String, "1")  // "0" or "1" for UISwitch
```

### 2.3 Tap, double-tap, long-press, swipe

```swift
cta.tap()
card.doubleTap()
card.press(forDuration: 1.0)                          // long-press
card.press(forDuration: 1.0, thenDragTo: targetElem)  // long-press + drag
list.swipeUp()
list.swipeDown()
list.swipeLeft()
list.swipeRight()
list.swipeUp(velocity: .slow)                          // iOS 13+
```

For coordinate-based taps (e.g., dismissing an action sheet by tapping the backdrop):

```swift
let backdropTap = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
backdropTap.tap()
```

### 2.4 Type into a field

```swift
field.tap()           // give it focus
field.typeText("user@example.com")
// Clear before re-typing:
field.press(forDuration: 1.2)
app.menuItems["Select All"].tap()
field.typeText(XCUIKeyboardKey.delete.rawValue)
```

The keyboard must be available. If a hardware keyboard is connected to the simulator the on-screen one will not appear; either disconnect it (`Hardware → Keyboard → Connect Hardware Keyboard` off in the simulator UI, or set `defaults write com.apple.iphonesimulator ConnectHardwareKeyboard 0` before booting) or use the slower-but-reliable per-element `typeText` which works either way.

### 2.5 Drag a slider precisely

```swift
slider.adjust(toNormalizedSliderPosition: 0.5)   // mid
slider.adjust(toNormalizedSliderPosition: 0.85)  // near end
```

This is the API the validator uses for Phase 3 BX4 (slider value-callback test). Wait briefly after the adjustment for the `on_change` callback to flush back through the bridge and update the probe label, then read the label's text:

```swift
slider.adjust(toNormalizedSliderPosition: 0.5)
Thread.sleep(forTimeInterval: 0.3)
let probe = app.staticTexts["slider-probe-value"]
XCTAssertTrue((Double(probe.label) ?? -1) >= 0.45 && (Double(probe.label) ?? -1) <= 0.55)
```

### 2.6 Tabs, navigation, modals

```swift
app.tabBars.buttons["Settings"].tap()
app.navigationBars.buttons.element(boundBy: 0).tap()  // back button (leftmost nav-bar button)

// Sheet dismissal — primary action:
app.buttons["screen-tier3-action-primary"].tap()
XCTAssertFalse(app.sheets.element.exists)

// Sheet dismissal — backdrop:
app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()

// Sheet dismissal — swipe-down (iOS-modal swipe):
app.sheets.element.swipeDown()

// Sheet dismissal — Cancel button:
app.sheets.buttons["Cancel"].tap()
```

### 2.7 Reading bounding rects (touch-target conformance)

```swift
let frame = app.buttons["save"].frame  // CGRect in window coordinates
XCTAssertGreaterThanOrEqual(frame.size.width, 44)
XCTAssertGreaterThanOrEqual(frame.size.height, 44)
```

Write the rect to disk via an XCTAttachment so the validator can capture it as evidence:

```swift
let rect = ["x": frame.origin.x, "y": frame.origin.y, "w": frame.size.width, "h": frame.size.height]
let data = try JSONSerialization.data(withJSONObject: rect)
let att  = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
att.name = "BX6-frame.json"
att.lifetime = .keepAlways
add(att)
```

### 2.8 Focus restoration after modal dismiss

iOS does not expose keyboard focus per element the same way macOS or web do, but it does have `hasFocus` on text inputs and an active accessibility element concept. For non-keyboard-focused widgets, "focus restoration" maps to two assertions:

1. The dismissed sheet is gone from the AX tree: `XCTAssertFalse(app.sheets.element.exists)`.
2. The original trigger is again the most-recently-interacted hittable element: `XCTAssertTrue(app.buttons["screen-tier3-show-action-sheet"].isHittable)` and, where applicable, `XCTAssertTrue(app.buttons["screen-tier3-show-action-sheet"].hasFocus)` (only valid for text-input-like widgets).

For VoiceOver-driven focus, the test target can enable VoiceOver programmatically via `XCUIDevice.shared.press(.home)` patterns, but Apple's preferred path is the `XCUITest` framework's built-in `XCUIElement.exists` + `isHittable` invariants on the trigger. This is what Phase 4 `focus.action-sheet-focus-trap`'s iOS analog asserts (via Phase 6's tier3 dismiss-path checks).

### 2.9 Capturing screenshots

```swift
let shot = XCUIScreen.main.screenshot()                   // full simulator screen
let shot = app.windows.firstMatch.screenshot()            // just the app window
let shot = app.buttons["save"].screenshot()               // single element

let att = XCTAttachment(screenshot: shot)
att.name = "BX5-after.png"
att.lifetime = .keepAlways
add(att)
```

`app.windows.firstMatch.screenshot()` is the right default for the side-by-side comparisons because it crops out the simulator status bar and home-indicator region (which differ from device captures). The known exception, baked into `HIGVisualTests.swift`, is presentation-style components (action sheets, activity views) that extend below the safe-area edge — for those, use `XCUIScreen.main.screenshot()`.

### 2.10 Putting it together — a complete behavior probe

```swift
import XCTest

final class NavFlowEndToEndTests: XCTestCase {
    func testFullFlow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["DEMO_SCREEN"] = "sign-in"
        app.launch()

        // Sign-in screen → tap CTA
        let cta = app.buttons["screen-sign-in-primary-cta"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3))
        cta.tap()

        // Dashboard → tap first card
        let activityTab = app.tabBars.buttons["Activity"]
        XCTAssertTrue(activityTab.waitForExistence(timeout: 3))
        let card = app.buttons["screen-dashboard-activity-card-0"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()

        // Detail → assert hero present → back
        let hero = app.otherElements["screen-detail-hero"]
        XCTAssertTrue(hero.waitForExistence(timeout: 3))
        let back = app.navigationBars.buttons.element(boundBy: 0)
        back.tap()

        // Dashboard tabs → Settings tab → open full settings
        XCTAssertTrue(activityTab.waitForExistence(timeout: 3))
        app.tabBars.buttons["Settings"].tap()
        app.buttons["screen-dashboard-settings-open-full"].tap()

        // Settings form present
        let form = app.otherElements["screen-settings-form"]
        XCTAssertTrue(form.waitForExistence(timeout: 3))

        let shot = XCUIScreen.main.screenshot()
        let att  = XCTAttachment(screenshot: shot)
        att.name = "nav-flow-final.png"
        att.lifetime = .keepAlways
        add(att)
    }
}
```

---

## 3. Web — Chrome DevTools Protocol (CDP) over WebSocket from Crystal

### 3.1 What is wired today

The validator drives Chrome **directly** via the Chrome DevTools Protocol (CDP). No browser MCP, no Puppeteer, no Playwright. The canonical implementation is `scripts/capture_amber_demo_screenshots.cr`; new validator scripts must extend or copy that pattern, not reinvent it.

The pattern in three sentences: spawn a headless Chrome with `--remote-debugging-port=<port>`; poll `http://127.0.0.1:<port>/json/version` until ready; open a `HTTP::WebSocket` to a new target's `webSocketDebuggerUrl` and exchange JSON-RPC messages (`{"id": N, "method": "...", "params": {...}}`). Every probe in this section reduces to a `Runtime.evaluate`, `Input.dispatchKeyEvent`, `Input.dispatchMouseEvent`, `Emulation.setDeviceMetricsOverride`, or `Page.captureScreenshot` call.

The CDP surface relevant to behavior probing:

| CDP method | Use |
|---|---|
| `Page.navigate` | Load a URL (incl. `file://` for built demos) |
| `Page.enable` / `Runtime.enable` / `Accessibility.enable` | Bootstrap the target before driving |
| `Emulation.setDeviceMetricsOverride` | Set viewport width/height, devicePixelRatio, mobile flag |
| `Emulation.setEmulatedMedia` | Set `prefers-color-scheme`, `prefers-reduced-motion` |
| `Runtime.evaluate` | Evaluate JS in the page; supports `awaitPromise`, `returnByValue` |
| `Input.dispatchKeyEvent` | OS-level trusted key events (`isTrusted === true`) |
| `Input.dispatchMouseEvent` | OS-level trusted mouse events at exact coordinates |
| `Page.captureScreenshot` | PNG capture (full viewport or `captureBeyondViewport`) |
| `Accessibility.getFullAXTree` | Real Chrome-computed accessibility tree, not aria-attribute approximation |
| `Log.enable` + `Log.entryAdded` event | Console / network log capture (filter on `level` for errors) |
| `Network.enable` + `Network.responseReceived` event | Per-request status capture (for 404 / broken-asset checks) |

Most behavior probes are `Runtime.evaluate` because JS is the most expressive way to introspect rendered state. Trusted key/mouse synthesis goes through `Input.dispatchKeyEvent` / `Input.dispatchMouseEvent` — CDP input events are trusted by the browser, which is the entire reason this protocol is used for the keyboard-trust-gated focus probes (focus-trap libraries that gate on `event.isTrusted` respond to CDP input but reject JS-dispatched `KeyboardEvent`).

### 3.2 Launching Chrome and opening a CDP session

The shape (full version in `scripts/capture_amber_demo_screenshots.cr`):

```crystal
require "http/client"
require "http/web_socket"
require "json"
require "uri"

CHROME_CANDIDATES = [
  ENV["CHROME_BIN"]?,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  Process.find_executable("google-chrome"),
  Process.find_executable("chromium"),
  Process.find_executable("chrome"),
].compact

chrome = CHROME_CANDIDATES.find { |path| File::Info.executable?(path) } || raise "no chrome binary found"
port = 9400 + Random.rand(400)
profile_dir = File.tempname("validator-chrome")
FileUtils.mkdir_p(profile_dir)

chrome_process = Process.new(
  chrome,
  [
    "--headless=new",
    "--remote-debugging-port=#{port}",
    "--user-data-dir=#{profile_dir}",
    "--no-first-run",
    "--disable-background-networking",
    "--disable-gpu",
    "about:blank",
  ],
  output: Process::Redirect::Close,
  error: Process::Redirect::Close
)

# Wait for the DevTools endpoint
http = HTTP::Client.new("127.0.0.1", port)
ready = false
60.times do
  begin
    if http.get("/json/version").status.success?
      ready = true
      break
    end
  rescue
  end
  sleep 0.2.seconds
end
raise "chrome did not expose DevTools on port #{port}" unless ready

# Create a fresh target and open its WebSocket
target_response = http.exec("PUT", "/json/new?about:blank")
websocket_url = JSON.parse(target_response.body)["webSocketDebuggerUrl"].as_s
devtools = DevTools.new(websocket_url)  # the thin JSON-RPC wrapper from scripts/capture_amber_demo_screenshots.cr
```

The `DevTools` class from the canonical script is ~40 lines: it opens an `HTTP::WebSocket`, runs it in a spawned fiber, maintains an `@id` counter, and exposes `#call(method, params_json)` plus `#evaluate(expression)`. Reuse it; do not write a new wrapper. Quote of the minimal interface for orientation:

```crystal
devtools.call("Page.enable")
devtools.call("Runtime.enable")
devtools.call("Accessibility.enable")
value = devtools.evaluate("document.readyState")  # → JSON::Any | nil
devtools.call("Page.navigate", %({"url":"file:///path/to/sign-in.html"}))
```

Teardown: `devtools.close` then `chrome_process.terminate`. Always do this in an `ensure` block — orphaned headless Chromes will exhaust ports across repeated runs.

### 3.3 Driving clicks, keys, and typing

**Programmatic click (sufficient for normal listeners):**

```crystal
devtools.evaluate(%(document.querySelector('[data-testid="screen-tier3-show-action-sheet"]').click()))
```

**Trusted synthetic click (custom widgets that gate on `isTrusted` or that listen on `pointer*` rather than `click`):**

```crystal
# Read the target's center coordinate from the rendered geometry
rect = devtools.evaluate(%(JSON.stringify(document.querySelector('[data-testid="..."]').getBoundingClientRect()))).not_nil!.as_s
parsed = JSON.parse(rect)
x = (parsed["left"].as_f + parsed["width"].as_f / 2).to_i
y = (parsed["top"].as_f + parsed["height"].as_f / 2).to_i

# Dispatch a real mouse click at that coordinate
devtools.call("Input.dispatchMouseEvent", %({"type":"mousePressed","x":#{x},"y":#{y},"button":"left","clickCount":1}))
devtools.call("Input.dispatchMouseEvent", %({"type":"mouseReleased","x":#{x},"y":#{y},"button":"left","clickCount":1}))
```

**Trusted keyboard input** — this is the canonical replacement for any old reference to "synthetic key via the browser MCP." CDP key events pass `isTrusted === true` by default:

```crystal
def dispatch_key(devtools, key : String, code : String, vkey : Int32, modifiers : Int32 = 0)
  devtools.call("Input.dispatchKeyEvent",
    %({"type":"keyDown","key":#{key.to_json},"code":#{code.to_json},"windowsVirtualKeyCode":#{vkey},"nativeVirtualKeyCode":#{vkey},"modifiers":#{modifiers}}))
  devtools.call("Input.dispatchKeyEvent",
    %({"type":"keyUp","key":#{key.to_json},"code":#{code.to_json},"windowsVirtualKeyCode":#{vkey},"nativeVirtualKeyCode":#{vkey},"modifiers":#{modifiers}}))
end

dispatch_key(devtools, "Tab",     "Tab",     9)
dispatch_key(devtools, "Tab",     "Tab",     9,  modifiers: 8)   # Shift+Tab
dispatch_key(devtools, "Escape",  "Escape",  27)
dispatch_key(devtools, "Enter",   "Enter",   13)
dispatch_key(devtools, "ArrowDown",  "ArrowDown",  40)
dispatch_key(devtools, "ArrowUp",    "ArrowUp",    38)
dispatch_key(devtools, "Home",       "Home",       36)
dispatch_key(devtools, "End",        "End",        35)
```

Modifier bit field (CDP): 1 = Alt, 2 = Ctrl, 4 = Meta, 8 = Shift.

For typing text, either set `value` on the field via `Runtime.evaluate` and dispatch an `input` event, or dispatch `Input.insertText` (single CDP call, includes the input event):

```crystal
devtools.call("Input.dispatchKeyEvent", %({"type":"char","text":"a@b.com"}))
# or, all at once, via the dedicated method:
devtools.call("Input.insertText", %({"text":"a@b.com"}))
```

`Input.insertText` only works when an editable element holds focus; click or focus the field first.

### 3.4 Reading focus, the AX tree, and computed styles

Standard introspection runs through `Runtime.evaluate`:

```crystal
devtools.evaluate("document.activeElement?.outerHTML?.slice(0, 200)")
devtools.evaluate(%(JSON.stringify(document.querySelector('[data-testid="x"]').getBoundingClientRect())))
devtools.evaluate(%(getComputedStyle(document.querySelector('[data-testid="x"]')).backgroundColor))
# → "rgb(124, 154, 146)"
```

For the **real accessibility tree** Chrome computes (not just the DOM's aria attributes), call `Accessibility.getFullAXTree` after `Accessibility.enable`. The returned `nodes` array contains role, name, value, properties, and `nodeId` references; the canonical script's `ax_value(node, key)` and `ax_property(node, name)` helpers (lines ~106-114 of `scripts/capture_amber_demo_screenshots.cr`) cover the common reads:

```crystal
devtools.call("Accessibility.enable")
tree = devtools.call("Accessibility.getFullAXTree")
nodes = tree["result"]["nodes"].as_a
panel = nodes.find { |n| ax_value(n, "role") == "dialog" }
modal = ax_property(panel.not_nil!, "modal")  # "true" | "false" | nil
hidden = ax_property(panel.not_nil!, "hidden")
```

A panel removed from the accessibility tree after dismiss returns `nil` from the `find` — that is the conformance signal for "sheet absent from AX tree."

For aria-attribute reads (lighter, sufficient when full AX is overkill):

```crystal
devtools.evaluate(<<-JS)
  (() => {
    const el = document.querySelector('[data-presented="true"]');
    return el ? {
      role: el.getAttribute('role'),
      label: el.getAttribute('aria-label') || el.getAttribute('aria-labelledby'),
      modal: el.getAttribute('aria-modal'),
      hidden: el.getAttribute('aria-hidden')
    } : null;
  })()
JS
```

### 3.5 Driving the Tab cycle (focus-trap conformance)

The Phase 4 `focus.action-sheet-focus-trap` pattern, fully expanded against CDP. Note: every Tab press is `Input.dispatchKeyEvent` (trusted), not `dispatchEvent(new KeyboardEvent(...))` (untrusted; rejected by focus-trap libraries that check `event.isTrusted`).

```crystal
# 1. Stash pre-open focus on window
devtools.evaluate("window.__trigger = document.activeElement; window.__focusTrace = []; null")

# 2. Click the trigger (programmatic click is fine here; widget intentionally exposes click)
devtools.evaluate(%(document.querySelector('[data-testid="screen-tier3-show-action-sheet"]').click()))

# 3. Poll for the panel to mount
20.times do
  presented = devtools.evaluate(%(!!document.querySelector('[data-presented="true"]')))
  break if presented.try(&.as_bool?)
  sleep 0.1.seconds
end

# 4. Drive Tab N+2 times, capture activeElement after each
focusable_count = devtools.evaluate(%(document.querySelectorAll('.ap-action-sheet__panel [tabindex], .ap-action-sheet__panel button, .ap-action-sheet__panel a, .ap-action-sheet__panel input').length)).not_nil!.as_i

(focusable_count + 2).times do
  dispatch_key(devtools, "Tab", "Tab", 9)
  devtools.evaluate(<<-JS)
    window.__focusTrace.push({
      n: window.__focusTrace.length,
      tag: document.activeElement?.tagName,
      testid: document.activeElement?.getAttribute('data-testid'),
      inside: !!document.activeElement?.closest('.ap-action-sheet__panel')
    })
  JS
end

trace = devtools.evaluate("JSON.stringify(window.__focusTrace)").not_nil!.as_s
```

After N+2 presses where N is the focusable count, the recorded array must:

- Have every entry's `inside === true` (focus never escaped the panel).
- Cover every focusable descendant of the panel.
- Cycle: `trace[N]` equals `trace[0]`.

For Escape-then-restore:

```crystal
dispatch_key(devtools, "Escape", "Escape", 27)
result = devtools.evaluate(<<-JS).not_nil!
  ({
    active_id: document.activeElement?.getAttribute('data-testid'),
    trigger_id: window.__trigger?.getAttribute('data-testid'),
    match: document.activeElement === window.__trigger
  })
JS
```

`result["match"]` must be `true`. The `window.__trigger` reference survives because the DOM element remains in the document; if the implementation re-creates the trigger on each render, compare by `testid` instead.

### 3.6 Driving the dismiss-flow (Escape, backdrop click, primary tap)

The dismiss-flow idiom. Open the modal, drive the path under test, assert (a) the panel is gone, (b) focus is back on the trigger, (c) the dismiss event fired with the expected reason.

```crystal
# Pre-open: install the dismiss-log listener and stash the trigger
devtools.evaluate(<<-JS)
  window.__phase4DismissLog = [];
  document.addEventListener('ap:action-sheet:dismiss', e => window.__phase4DismissLog.push(e.detail));
  window.__trigger = document.querySelector('[data-testid="screen-tier3-show-action-sheet"]');
JS

# Open
devtools.evaluate(%(window.__trigger.click()))
# (poll for [data-presented="true"] as above)

# Path: Escape (trusted)
dispatch_key(devtools, "Escape", "Escape", 27)

# Assertion bundle
result = devtools.evaluate(<<-JS).not_nil!
  ({
    dismiss_log: window.__phase4DismissLog,
    data_presented: document.querySelector('.ap-action-sheet')?.getAttribute('data-presented'),
    panel_ax_visible: (() => {
      const p = document.querySelector('.ap-action-sheet__panel');
      if (!p) return false;
      if (p.getAttribute('aria-hidden') === 'true') return false;
      if (getComputedStyle(p).display === 'none') return false;
      return true;
    })(),
    focus_restored: document.activeElement === window.__trigger
  })
JS
```

Pass when `dismiss_log.length === 1 && dismiss_log[0].reason === 'escape'`, `data_presented === 'false'`, `panel_ax_visible === false`, `focus_restored === true`.

**Backdrop click path** — read the backdrop's rect, then dispatch a real mouse press/release at its center via `Input.dispatchMouseEvent` (programmatic `backdrop.click()` is what well-behaved implementations guard against, so this MUST be the trusted path):

```crystal
rect_json = devtools.evaluate(%(JSON.stringify(document.querySelector('.ap-action-sheet__backdrop').getBoundingClientRect()))).not_nil!.as_s
r = JSON.parse(rect_json)
x = (r["left"].as_f + r["width"].as_f / 2).to_i
y = 8  # Above the panel — explicitly outside the panel rect; verify by reading the panel rect first

devtools.call("Input.dispatchMouseEvent", %({"type":"mousePressed","x":#{x},"y":#{y},"button":"left","clickCount":1}))
devtools.call("Input.dispatchMouseEvent", %({"type":"mouseReleased","x":#{x},"y":#{y},"button":"left","clickCount":1}))
```

Verify the click coordinate is outside the panel's rect before dispatching — otherwise the test rig is hitting the panel and the result is meaningless.

### 3.7 Verifying reflow on resize

Drive viewport changes via `Emulation.setDeviceMetricsOverride`, then re-measure geometry. This is the canonical pattern for Phase 2 fluid resize and Phase 6 `resize.web`.

```crystal
[
  {1280, 800, false}, {1024, 768, false}, {900, 800, false}, {768, 1024, false},
  {640, 800, false}, {480, 800, true},   {375, 667, true},  {320, 568, true},
].each do |(w, h, mobile)|
  devtools.call("Emulation.setDeviceMetricsOverride",
    %({"width":#{w},"height":#{h},"deviceScaleFactor":1,"mobile":#{mobile}}))

  measurement = devtools.evaluate(<<-JS).not_nil!
    (() => {
      const tracked = Array.from(document.querySelectorAll('[data-testid]')).map(el => ({
        testid: el.dataset.testid,
        rect: el.getBoundingClientRect()
      }));
      return {
        viewport: { w: innerWidth, h: innerHeight },
        scroll: { x: document.documentElement.scrollWidth, y: document.documentElement.scrollHeight },
        tracked
      };
    })()
JS

  File.write(File.join(ARTIFACT_DIR, "reflow-#{w}.json"), measurement.to_json)
  screenshot = devtools.call("Page.captureScreenshot", %({"format":"png","captureBeyondViewport":true}))
  File.write(File.join(ARTIFACT_DIR, "reflow-#{w}.png"), Base64.decode(screenshot["result"]["data"].as_s))
end
```

Assert (per the established Phase 2 contract): `scroll.x === viewport.w` (no horizontal overflow), every critical element's width and height stays ≥ 44 at the smallest viewport, and per-element widths are monotonically non-increasing as viewport shrinks (allow ±2 px tolerance, one breakpoint hand-off per element).

For `prefers-color-scheme` and `prefers-reduced-motion` emulation alongside viewport:

```crystal
devtools.call("Emulation.setEmulatedMedia",
  %({"features":[{"name":"prefers-color-scheme","value":"dark"},{"name":"prefers-reduced-motion","value":"reduce"}]}))
```

### 3.8 Console + network capture

Subscribe to the relevant CDP events before navigating; collect them as they fire.

```crystal
console_errors = [] of String
network_failures = [] of String

devtools.call("Log.enable")
devtools.call("Network.enable")
devtools.call("Runtime.enable")

# The DevTools wrapper from scripts/capture_amber_demo_screenshots.cr currently
# treats all incoming non-response messages as the response stream. For event
# subscription, extend the wrapper to expose an on_event callback (about 5 LoC):
#   @ws.on_message do |raw|
#     msg = JSON.parse(raw)
#     if msg["id"]?
#       @messages.send(msg)
#     else
#       @events.send(msg) if @events
#     end
#   end
# Then filter on msg["method"]:
#   - "Runtime.consoleAPICalled" with params.type === "error" → console error
#   - "Log.entryAdded"           with params.entry.level === "error" → page error / network error logged via console
#   - "Network.responseReceived" with params.response.status >= 400 → broken asset
```

For checks that need only a post-hoc dump (the simpler path), accumulate errors in-page via JS and read once:

```crystal
devtools.evaluate(<<-JS)
  window.__consoleErrors = [];
  const origError = console.error;
  console.error = (...args) => { window.__consoleErrors.push(args.map(String).join(' ')); origError.apply(console, args); };
  window.addEventListener('error', e => window.__consoleErrors.push('window.error: ' + e.message));
  window.addEventListener('unhandledrejection', e => window.__consoleErrors.push('unhandled: ' + String(e.reason)));
JS
# ...drive the page...
errors = devtools.evaluate("JSON.stringify(window.__consoleErrors)").not_nil!.as_s
```

This is the lighter idiom used inside the canonical script's per-case audit block.

### 3.9 Capturing screenshots

```crystal
result = devtools.call("Page.captureScreenshot", %({"format":"png","captureBeyondViewport":true}))
File.write(path, Base64.decode(result["result"]["data"].as_s))
```

For per-element captures (BX5 ΔE sampling, brand override), measure the element's screen rect via `getBoundingClientRect()` plus the viewport offset (always `0,0` in headless), then crop the full-viewport screenshot in post (e.g., via `Stumpy::PNG`) — CDP itself takes viewport or full-page captures, not element-region.

For `prefers-reduced-motion` evidence shots, set the emulation flag (section 3.7) before capturing.

### 3.10 Installing axe-core or other JS audit libraries

The `axe_web_demo_audit.cr` pattern is the canonical example. Read the axe-core source from disk, evaluate it in the page to install `window.axe`, then evaluate `axe.run(...)` and `await` the promise via `Runtime.evaluate`'s `awaitPromise: true`:

```crystal
axe_source = File.read("vendor/axe-core/axe.min.js")
devtools.call("Page.navigate", %({"url":#{page_url.to_json}}))
# wait for readyState === "complete"
devtools.evaluate(axe_source)  # installs window.axe
report = devtools.evaluate("axe.run().then(r => JSON.stringify(r))").not_nil!.as_s
File.write("audits/axe-#{page_name}.json", report)
```

Note: `DevTools#evaluate` already passes `awaitPromise: true` (see line ~78 of `scripts/capture_amber_demo_screenshots.cr`), so the `.then(...) → JSON string` idiom works without explicit promise plumbing on the Crystal side.

IBM Equal Access (`scripts/ibm_web_demo_audit.cr`) and other JS-only audit toolkits install the same way: read source from disk, evaluate, then evaluate the audit entry point.

### 3.11 Cross-origin / file URL gotchas

The demo's static output lives at `output/initiative-demo/*.html`. Chrome's file-URL handling restricts JS access to sibling files (`<img src="assets/foo.svg">` works but `fetch("assets/foo.json")` fails). For validator runs that need fetch-based loading (rare), serve the directory through a local HTTP server before navigating:

```crystal
http_server = Process.new("python3", ["-m", "http.server", "7777"], chdir: "output/initiative-demo",
                           output: Process::Redirect::Close, error: Process::Redirect::Close)
sleep 0.5.seconds
devtools.call("Page.navigate", %({"url":"http://localhost:7777/sign-in.html"}))
# ...
ensure
  http_server.terminate
end
```

Phase 6 and Phase 7 checks generally do not need this — they navigate to file URLs directly and probe via DOM APIs that do not hit `fetch`.

### 3.12 Extending the canonical script vs. writing new

If the check is "capture screenshots, run an in-page audit, write JSON evidence," extend `scripts/capture_amber_demo_screenshots.cr` (or copy its `DevTools` class into a new script next to it). Do not introduce a new browser-automation dependency. The list of existing CDP-based validator scripts:

| Script | Role |
|---|---|
| `scripts/capture_amber_demo_screenshots.cr` | Canonical CDP harness — screenshots, contrast, keyboard traversal, touch targets, accessibility tree |
| `scripts/capture_web_demo_screenshots.cr` | Thin re-export of the above (web-design-system variant) |
| `scripts/axe_web_demo_audit.cr` / `axe_amber_demo_audit.cr` | axe-core injection + run, JSON report |
| `scripts/ibm_web_demo_audit.cr` / `ibm_amber_demo_audit.cr` | IBM Equal Access injection + run, JSON report |
| `scripts/validate_web_demo.cr` / `validate_amber_demo.cr` | Composite gate — orchestrates the above |

New validator scripts MUST follow this naming pattern and live in `scripts/`. They MUST NOT add an npm, Puppeteer, or Playwright dependency.

---

## 4. Cross-platform patterns

These are the four shapes every behavior check in the initiative composes from. When a validation.md says "behavior" or "conformance," the rubric is asking for one or more of these patterns to be applied.

### 4.1 Action → state → output

The basic shape. Trigger an action; assert the bound state changed; assert the rendered output reflects the new state.

**macOS:**

```crystal
counter_before = a.find(role: "AXStaticText", label: "tap-counter").not_nil!.value
button = a.find(role: "AXButton", label: "Increment").not_nil!
button.click  # performs AXPress
sleep(0.2)
counter_after  = a.find(role: "AXStaticText", label: "tap-counter").not_nil!.value
counter_after.should eq((counter_before.to_i + 1).to_s)
```

**iOS:**

```swift
let before = app.staticTexts["tap-counter"].label
app.buttons["Increment"].tap()
let after = app.staticTexts["tap-counter"].label
XCTAssertEqual(Int(after) ?? -1, (Int(before) ?? 0) + 1)
```

**Web:**

```js
const before = document.querySelector('[data-testid="tap-counter"]').textContent;
document.querySelector('[data-testid="increment"]').click();
const after = document.querySelector('[data-testid="tap-counter"]').textContent;
({ before, after, ok: parseInt(after) === parseInt(before) + 1 })
```

### 4.2 Modal: open, exercise every dismiss path, verify focus restoration

This is the contract Phase 4 holds action-sheet and context-menu fallbacks to, and Phase 6 holds the Tier 3 demo screen to.

For every modal-like widget, the validator runs **all** documented dismiss paths in sequence, re-opening between each:

| Platform | Dismiss paths |
|---|---|
| **iOS native ActionSheet** | primary-action tap, Cancel tap, backdrop tap (coordinate above sheet), swipe-down |
| **macOS NSPanel sheet** | primary-action AXPress, Cancel AXPress, Escape keystroke (CGEvent) |
| **Web fallback** | primary-action click, Cancel click, backdrop click (real `Input.dispatchMouseEvent` at backdrop center), Escape key (real `Input.dispatchKeyEvent`) |

After each dismiss, the validator asserts three things, in this order:

1. The sheet is absent from the AX tree.
   - iOS: `XCTAssertFalse(app.sheets.element.exists)`.
   - macOS: `app.find(role: "AXSheet")` returns nil.
   - Web: `document.querySelector('[data-presented="true"]')` returns null AND `[role="dialog"][aria-hidden="false"]` returns null.
2. Focus has returned to the originating trigger.
   - iOS: `XCTAssertTrue(app.buttons["trigger-id"].isHittable)` and (for text-input triggers) `hasFocus`.
   - macOS: `focused_element(app)?.label == "trigger-id"`.
   - Web: `document.activeElement === window.__trigger`.
3. The dismiss event/callback fired with the correct reason.
   - Web: `window.__dismissLog[-1].reason` equals the path identifier.
   - Native: the Crystal-side probe singleton (`DismissProbe.last_reason`) reflects the path.

The validator must NOT consolidate these three assertions into a single boolean. Each is reported with its own evidence file.

### 4.3 Navigation flow: drive end-to-end, restore prior state on back

The Phase 6 `nav.flow-end-to-end-{macos,ios,web}` checks instantiate this.

The pattern:

1. Launch / navigate to the starting screen.
2. For each step in the documented flow:
   - Identify the trigger element by stable identifier.
   - Drive the action (tap / click / press).
   - Wait (with explicit timeout) for the next-screen marker element to appear.
   - Capture a screenshot named for the step.
   - Optionally assert any intermediate state (the new screen contains the expected heading, the URL changed, etc.).
3. At the end of the forward flow, drive the back affordance.
4. Assert the prior screen's identity marker is again present AND any prior-screen state (selected tab, scroll position, focused field) is restored.

The back-restore step is what catches forgotten state preservation. The validator MUST assert restoration, not just "back button exists."

### 4.4 Runtime override: mutate at runtime, re-render, verify reflected

The Phase 3 BX5 pattern. The demo must expose an affordance (button, gesture, or env-var-driven mutation) that perturbs a property of an already-rendered view, then re-renders.

The shape:

1. Capture screenshot of initial state.
2. Sample the property's rendered manifestation at a known coordinate (color at center pixel, geometry of bounding rect, text content).
3. Drive the affordance that mutates the override.
4. Wait for the re-render (a frame, plus motion duration if the override is animated).
5. Re-capture and re-sample.
6. Assert the sampled value changed in the expected direction by at least the documented threshold (ΔE ≥ 10 for color, ≥ 4 px for geometry, exact match for text).

If the demo does not already expose a mutation affordance for the property under test, the implementer for the relevant phase must add one. This is a known requirement for Phase 3 BX5 and is called out in the strengthened rubric — do not freelance a code change to add it; mark the check `blocked: true` and let the team lead route back to the implementer.

---

## 5. Recipes — copy-paste per common action

### 5.1 Tap a button and verify counter incremented

See section 4.1.

### 5.2 Toggle a switch and verify bound bool changed

**iOS:**

```swift
let toggle = app.switches["screen-settings-notify"]
let before = toggle.value as? String  // "0" or "1"
toggle.tap()
Thread.sleep(forTimeInterval: 0.2)
let after = toggle.value as? String
XCTAssertNotEqual(before, after)

// And the bound state, as reflected in the probe label
let probe = app.staticTexts["toggle-probe-value"]
XCTAssertEqual(probe.label, after == "1" ? "true" : "false")
```

**macOS:**

```crystal
toggle = a.find(role: "AXCheckBox", label: "Notify") || raise "toggle missing"
before = toggle.value  # "0" or "1"
toggle.click           # AXPress flips the switch
sleep(0.2)
after = toggle.value
after.should_not eq(before)

probe = a.find(role: "AXStaticText", label: "toggle-probe-value").not_nil!
probe.value.should eq(after == "1" ? "true" : "false")
```

**Web:**

```js
const t = document.querySelector('[data-testid="screen-settings-notify"]');
const before = t.checked;
t.click();
const after = t.checked;
const probe = document.querySelector('[data-testid="toggle-probe-value"]').textContent;
({ before, after, probe, ok: after !== before && probe === String(after) })
```

### 5.3 Drag a slider to a normalized position and verify on_change fired with the new value

**iOS:**

```swift
let slider = app.sliders["screen-settings-volume"]
slider.adjust(toNormalizedSliderPosition: 0.5)
Thread.sleep(forTimeInterval: 0.3)
let probe = Double(app.staticTexts["slider-probe-value"].label) ?? -1
XCTAssertTrue(probe >= 0.45 && probe <= 0.55)
```

**macOS** (uses A3's `Element#set_value`):

```crystal
slider = a.find(role: "AXSlider", label: "Volume").not_nil!
set_double_value(slider, 0.5)  # helper from section 1.6
sleep(0.3)
probe = a.find(role: "AXStaticText", label: "slider-probe-value").not_nil!
probe.value.not_nil!.to_f.should be_close(0.5, 0.05)
```

**Web:**

```js
const s = document.querySelector('[data-testid="screen-settings-volume"]');
s.value = '0.5';
s.dispatchEvent(new Event('input',  { bubbles: true }));
s.dispatchEvent(new Event('change', { bubbles: true }));
({ probe: document.querySelector('[data-testid="slider-probe-value"]').textContent })
```

### 5.4 Type into a text field and verify model bound

**iOS:**

```swift
let f = app.textFields["screen-sign-in-email"]
f.tap()
f.typeText("a@b.com")
XCTAssertEqual(app.staticTexts["email-probe"].label, "a@b.com")
```

**Web:**

```js
const f = document.querySelector('[data-testid="screen-sign-in-email"]');
f.focus();
f.value = 'a@b.com';
f.dispatchEvent(new Event('input', { bubbles: true }));
({ probe: document.querySelector('[data-testid="email-probe"]').textContent })
```

**macOS:** use the `AXValue`-set path from section 1.6. The Crystal-side probe label updates through the bridge.

### 5.5 Open a sheet, dismiss every path, verify focus restored each time

See section 4.2 for the contract. Concretely on web:

```js
// Open + record dismiss
window.__dismissLog = [];
document.querySelectorAll('.ap-action-sheet').forEach(el => {
  el.addEventListener('ap:action-sheet:dismiss', e => window.__dismissLog.push(e.detail));
});

// Path 1: primary
window.__trigger = document.querySelector('[data-testid="screen-tier3-show-action-sheet"]');
window.__trigger.click();
// (wait for [data-presented="true"])
document.querySelector('[data-testid="screen-tier3-action-primary"]').click();
// assert: data-presented = false, activeElement === __trigger, dismissLog last reason = 'primary'
```

Repeat with cancel / backdrop / escape paths. Reset `window.__dismissLog` between if you want per-path arrays; otherwise read by index.

### 5.6 Tab through a focus-trapped modal and capture the path

See section 3.4.

### 5.7 Resize the macOS window and capture geometry at each step

See section 1.9 plus the Phase 6 `resize.macos` loop in its validation.md.

### 5.8 Resize the web viewport and re-measure

```
1. devtools.call("Emulation.setDeviceMetricsOverride", %({"width":1280,"height":800,"deviceScaleFactor":1,"mobile":false}))
2. devtools.evaluate(<measurement JS from section 3.7>)
3. devtools.call("Page.captureScreenshot", %({"format":"png","captureBeyondViewport":true}))
4. repeat at 768×1024 (mobile:false) and 375×667 (mobile:true)
```

### 5.9 Open a context menu at three positions, measure bounding rect

```js
// Position 1: trigger near top-left corner
const t1 = document.querySelector('[data-testid="ctx-trigger-tl"]');
t1.dispatchEvent(new MouseEvent('contextmenu', { bubbles: true, clientX: 10, clientY: 10 }));
// wait for menu
const menu = document.querySelector('[role="menu"][data-presented="true"]');
({ rect: menu.getBoundingClientRect(), viewport: { w: innerWidth, h: innerHeight } })
// assert menu.left >= 0 && menu.top >= 0 && menu.right <= innerWidth && menu.bottom <= innerHeight
```

Repeat at center and bottom-right trigger positions.

### 5.10 Walk the macOS AX tree and assert every interactive element has a label

```crystal
def walk(element, depth = 0, &block)
  yield element, depth
  element.children.each { |c| walk(c, depth + 1, &block) }
end

violations = [] of String
walk(app.root) do |el, depth|
  role = el.role
  interactive = %w[AXButton AXSwitch AXTextField AXSlider AXCheckBox AXRadioButton AXPopUpButton]
  if interactive.includes?(role)
    label = el.label || el.title
    identifier = read_string_attribute_raw(el, "AXIdentifier")
    if (label.nil? || label.empty?) && (identifier.nil? || identifier.empty?)
      violations << "#{role} at depth #{depth} has no label or identifier"
    end
  end
end
violations.should be_empty
```

This is the pattern Phase 7 check 22 (`audits.macos-axwalk-passes`) instantiates.

---

## 6. AXTest extensions — shipped

All seven extensions originally proposed during toolkit authoring (A1–A7) shipped in commits `5e78fc8`, `dac1ca6`, `397466a`, `8fb6e3a`, `bcedd8f`, `c000a9c`, `dcda1d7` on `feature/utility-first-css-asset-pipeline`. Spec suite under `spec/ui/ax_test/` runs 33 examples, 0 failures, 4 pending (each pending is a permission-gated integration assertion — see "Permission requirements" at the end of this section).

Validators reach for these extensions directly. Do not freelance CGEvent posts or private-API calls; if a check requires a capability not listed here, mark `blocked: true` and let the team lead decide.

### A1. Find by AXIdentifier

`UI::AXTest::Element#find(identifier: String)` and the raising `#find!(identifier: String)`, plus convenience wrappers `#find_by_id(id : String) : Element?` and `#find_by_id!(id : String) : Element`. Recursive walk, first match wins.

```crystal
window = app.window!(title: "Demo")
button = window.find_by_id!("primary-cta")
button.perform_press!
```

### A2. Geometry — position, size, frame, bounds

Three accessors on `Element`:

- `#position : NamedTuple(x: Float64, y: Float64)?` reads `kAXPositionAttribute`.
- `#size : NamedTuple(width: Float64, height: Float64)?` reads `kAXSizeAttribute`.
- `#frame : NamedTuple(x: Float64, y: Float64, width: Float64, height: Float64)?` composes the two.

Note: keys are `width:` / `height:` (matching `CGSize` field names), not `w:` / `h:`.

```crystal
frame = window.find_by_id!("primary-cta").frame
raise "primary CTA too small" if frame[:width] < 44 || frame[:height] < 44
```

### A3. `Element#set_value`

Writes `kAXValueAttribute` via `AXUIElementSetAttributeValue`. Accepts `Float64 | Float32 | Int32 | Int64 | Int | String | Bool`. Returns `Bool` (success).

```crystal
slider = window.find_by_id!("brightness-slider")
slider.set_value(0.75)         # slider drag to 75%
checkbox.set_value(true)       # checkbox toggle on
text_field.set_value("hello")  # text field population
```

Live numeric writes require Accessibility permission for the spec runner's parent process.

### A4. Focus

- `Element#focus!` sets `kAXFocusedAttribute` to true. Returns `Bool`.
- `App#focused_element : Element?` returns the focused element inside this app.
- `App.system_focused_element : Element?` returns the system-wide focused element.

```crystal
window.find_by_id!("email-field").focus!
keys.type("user@example.com")
```

### A5. `App#resize_window(title, width, height, timeout = 5.0)`

Finds a window by title, sets `kAXSizeAttribute` via AX value writer. The `timeout` parameter (default 5.0 s) matches `App#window`'s existing idiom — the call polls until the window's size attribute reflects the request.

```crystal
app = UI::AXTest::App.attach("com.assetpipeline.democross")
app.resize_window("Demo", 375, 800)   # narrow → mobile-like reflow
sleep 0.3
narrow_geom = app.window!(title: "Demo").find_by_id!("primary-cta").frame
app.resize_window("Demo", 1280, 800)  # back to wide
```

### A6. `UI::AXTest::Keys` synthetic keyboard

Module exposing CGEvent-backed key delivery. Named helpers for the common keys plus a general `press(keycode, modifiers)` and `type(string)`:

- `Keys.escape!`, `Keys.tab!`, `Keys.shift_tab!`, `Keys.return!`, `Keys.space!`, `Keys.delete!`
- `Keys.arrow_up!`, `Keys.arrow_down!`, `Keys.arrow_left!`, `Keys.arrow_right!`
- `Keys.press(keycode : UInt16, modifiers : CGEventFlags = CGEventFlags::None)`
- `Keys.type(string : String)` — types each character (key down + key up per char).

```crystal
# Open a sheet, dismiss via Escape, assert focus restored.
trigger = window.find_by_id!("share-trigger")
trigger.perform_press!
sleep 0.3
UI::AXTest::Keys.escape!
sleep 0.2
assert_equal "share-trigger", app.focused_element.try(&.read_string_attribute("AXIdentifier"))
```

Live key delivery requires Accessibility permission (the same requirement as A3 and A4 — it's actually the same TCC permission).

### A7. `Element#bounds_in_screen` + `App#screenshot_element`

- `Element#bounds_in_screen : NamedTuple(x: Float64, y: Float64, width: Float64, height: Float64)?` — alias for `#frame` documented to clarify it's screen-coordinates.
- `App#screenshot_element(element : Element, path : String) : Bool` — captures just the element's bounds rectangle. Internally shells `/usr/sbin/screencapture -R x,y,w,h <path>`. Returns true on success.

```crystal
cta = window.find_by_id!("primary-cta")
app.screenshot_element(cta, "evidence/cta_only.png")
# Now sample center pixel for ΔE comparison.
```

### Permission requirements

A3, A4, A5, A6 live integration tests require the spec runner's parent process (Terminal, iTerm, your IDE) to be granted Accessibility in **System Settings → Privacy & Security → Accessibility**.

There is no `tccutil` add-from-CLI for Accessibility — it requires the user-consent dialog through System Settings (`tccutil reset Accessibility com.apple.Terminal` only resets, never grants).

Specs that need the permission can introspect it via `UI::AXTest::App.accessibility_trusted?` and call `pending!("requires Accessibility permission") unless ...`. The four pending specs in the suite already follow this pattern — see `spec/ui/ax_test/ax_value_writer_spec.cr`, `ax_focus_spec.cr`, `ax_resize_spec.cr`, `ax_keys_spec.cr`.

---

## Last word

If a validator check requires an action this toolkit cannot express, do not freelance a CGEvent post or a private API call. Mark the check `blocked: true` with a reference to the missing capability (cite the section heading or extension ID), and let the team lead decide whether to extend the framework, route to a different platform, or accept a weaker proxy. Behavior bars are expensive to set and even more expensive to silently soften.
