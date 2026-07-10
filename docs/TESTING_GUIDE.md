# AssetPipeline Testing Guide

This document covers automated UI testing with the AssetPipeline cross-platform renderer, focusing on the `test_id` property and how it maps to native test attributes on each supported platform.

## Table of Contents

- [The test_id Property](#the-test_id-property)
- [Platform-Native Mapping](#platform-native-mapping)
  - [How Each Renderer Applies test_id](#how-each-renderer-applies-test_id)
  - [Web (WebRenderer)](#web-webrenderer)
  - [macOS (AppKitRenderer)](#macos-appkitrenderer)
  - [iOS (UIKitRenderer)](#ios-uikitrenderer)
  - [Android (AndroidRenderer)](#android-androidrenderer)
- [Android contentDescription Caveat](#android-contentdescription-caveat)
- [Test ID Naming Convention](#test-id-naming-convention)
- [Code Examples](#code-examples)
  - [Setting test_id on Views](#setting-test_id-on-views)
  - [Querying test_id in Platform Tests](#querying-test_id-in-platform-tests)
- [Writing Specs for Views with test_id](#writing-specs-for-views-with-test_id)
- [Cross-Platform Testing Strategy](#cross-platform-testing-strategy)
- [FSDD Cross-References](#fsdd-cross-references)

---

## The test_id Property

Every view in AssetPipeline inherits from `UI::View`, which defines a nullable `test_id` property on line 133 of `src/ui/view.cr`:

```crystal
# Test identifier for automated UI testing, maps to native test attributes
property test_id : String? = nil
```

Because `test_id` is declared on the base class, all 60+ concrete view types (Button, Label, TextField, VStack, HStack, ScrollView, and so on) inherit it automatically. You set it once in your Crystal layout code, and the active renderer translates it to the correct native attribute for whichever platform you are building against.

---

## Platform-Native Mapping

### Summary Table

| Platform | Renderer | Native Attribute | Test Query Method |
|----------|----------|-----------------|-------------------|
| Web | WebRenderer | `data-testid` | `querySelector('[data-testid="..."]')` |
| macOS | AppKitRenderer | `accessibilityIdentifier` | XCUIElement query |
| iOS | UIKitRenderer | `accessibilityIdentifier` | XCUIElement query |
| Android | AndroidRenderer | `contentDescription` | `onNodeWithTag()` |

### How Each Renderer Applies test_id

Each renderer checks `view.test_id` after laying out the native element. If the value is non-nil, it writes the string into the platform-appropriate attribute.

### Web (WebRenderer)

From `src/ui/renderers/web_renderer.cr`:

```crystal
# Test identifier -> data-testid attribute for automated UI testing
if tid = view.test_id
  el.set_attribute("data-testid", tid)
end
```

Query in browser tests (Selenium, Playwright, Cypress, or plain JS):

```javascript
document.querySelector('[data-testid="7.1-record-button"]')
```

### macOS (AppKitRenderer)

From `src/ui/renderers/appkit_renderer.cr`:

```crystal
# Test identifier -> accessibilityIdentifier for automated UI testing
if tid = view.test_id
  tid_str = LibObjCBridge.nsstring_from_cstr(tid.to_unsafe)
  LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityIdentifier:"), tid_str)
end
```

Query in XCUITest:

```swift
let button = app.buttons["7.1-record-button"]
XCTAssertTrue(button.exists)
```

### iOS (UIKitRenderer)

From `src/ui/renderers/uikit_renderer.cr`:

```crystal
# Test identifier -> accessibilityIdentifier for automated UI testing
if tid = view.test_id
  tid_str = LibObjCBridge.nsstring_from_cstr(tid.to_unsafe)
  LibObjCBridge.objc_send_id(ptr, sel("setAccessibilityIdentifier:"), tid_str)
end
```

The code is identical to AppKit. Both Apple platforms use `accessibilityIdentifier`, and both are queried via XCUIElement in XCUITest.

### Android (AndroidRenderer)

From `src/ui/renderers/android_renderer.cr`:

```crystal
# Accessibility label -> contentDescription
if a11y = view.accessibility_label
  LibAndroidBridge.android_view_set_content_description(
    @env, v, a11y.to_unsafe, a11y.bytesize)
end

# Test identifier -> contentDescription (used as test tag on Android)
# Only set if accessibility_label was not already set, to avoid overwriting it
if tid = view.test_id
  unless view.accessibility_label
    LibAndroidBridge.android_view_set_content_description(
      @env, v, tid.to_unsafe, tid.bytesize)
  end
end
```

Query in Compose UI tests:

```kotlin
composeTestRule.onNodeWithContentDescription("7.1-record-button").assertIsDisplayed()
```

---

## Android contentDescription Caveat

On Android, both `accessibility_label` and `test_id` write to the same native attribute: `contentDescription`. The renderer gives `accessibility_label` priority. When a view has both properties set, `contentDescription` will contain the accessibility label and the test_id value is silently dropped.

If you need both accessibility and test identification on the same Android view, use the Compose `testTag` modifier separately in your Compose integration layer:

```kotlin
Modifier.semantics { testTag = "7.1-record-button" }
```

On Web, macOS, and iOS this conflict does not exist because `test_id` and `accessibility_label` map to different native attributes (`data-testid` vs `aria-label`, `accessibilityIdentifier` vs `accessibilityLabel`).

---

## Test ID Naming Convention

When using FSDD (Feature-Story-Driven Development), follow the naming pattern:

```
{epic}.{story}-{element-name}
```

**Examples:**

| Test ID | Meaning |
|---------|---------|
| `7.1-record-button` | Epic 7, Story 1, the record button |
| `7.1-stop-button` | Epic 7, Story 1, the stop button |
| `7.2-audio-file-picker` | Epic 7, Story 2, the audio file picker |
| `3.1-transcript-label` | Epic 3, Story 1, the transcript label |

This convention ties every testable UI element directly to the feature story that specified it, making it straightforward to build coverage mapping tables in your FSDD documentation.

---

## Code Examples

### Setting test_id on Views

```crystal
require "asset_pipeline/ui"

# Simple button with a test ID
button = UI::Button.new
button.title = "Record"
button.test_id = "7.1-record-button"

# A label with both test_id and accessibility_label
status_label = UI::Label.new
status_label.text = "Ready"
status_label.accessibility_label = "Recording status"
status_label.test_id = "7.1-status-label"

# Composing views in a layout
vstack = UI::VStack.new
vstack.test_id = "7.1-main-stack"
vstack.children << button
vstack.children << status_label
```

### Querying test_id in Platform Tests

**Crystal spec (verify the property is set):**

```crystal
it "assigns test_id to the record button" do
  button = UI::Button.new
  button.test_id = "7.1-record-button"
  button.test_id.should eq("7.1-record-button")
end
```

**XCUITest (macOS or iOS):**

```swift
func testRecordButtonExists() {
    let app = XCUIApplication()
    app.launch()
    let recordButton = app.buttons["7.1-record-button"]
    XCTAssertTrue(recordButton.waitForExistence(timeout: 5))
}
```

**Compose UI test (Android):**

```kotlin
@Test
fun recordButtonIsDisplayed() {
    composeTestRule
        .onNodeWithContentDescription("7.1-record-button")
        .assertIsDisplayed()
}
```

**Web (Playwright):**

```javascript
test('record button is visible', async ({ page }) => {
  await page.goto('/');
  const button = page.locator('[data-testid="7.1-record-button"]');
  await expect(button).toBeVisible();
});
```

---

## Writing Specs for Views with test_id

Crystal specs can validate that your view hierarchy assigns the correct test IDs without requiring a running renderer or native platform.

```crystal
require "spec"
require "asset_pipeline/ui"

describe "Recording screen view hierarchy" do
  it "sets test_id on all interactive elements" do
    button = UI::Button.new
    button.test_id = "7.1-record-button"

    status = UI::Label.new
    status.test_id = "7.1-status-label"

    timer = UI::Label.new
    timer.test_id = "7.1-timer-label"

    button.test_id.should eq("7.1-record-button")
    status.test_id.should eq("7.1-status-label")
    timer.test_id.should eq("7.1-timer-label")
  end

  it "defaults test_id to nil" do
    view = UI::Label.new
    view.test_id.should be_nil
  end

  it "allows overwriting test_id" do
    button = UI::Button.new
    button.test_id = "draft-id"
    button.test_id = "7.1-record-button"
    button.test_id.should eq("7.1-record-button")
  end
end
```

For renderer-level verification (confirming the native attribute is actually written), you need platform-specific UI tests: XCUITest on Apple platforms, Compose instrumented tests on Android, or browser-based tests for Web.

---

## Cross-Platform Testing Strategy

The test_id property enables a layered testing approach where one identifier set in Crystal propagates to all four platforms automatically.

```
Crystal code (one test_id)
  |
  +---> WebRenderer     ---> data-testid       ---> Playwright / Selenium
  +---> AppKitRenderer  ---> accessibilityIdentifier ---> XCUITest (macOS)
  +---> UIKitRenderer   ---> accessibilityIdentifier ---> XCUITest (iOS)
  +---> AndroidRenderer ---> contentDescription ---> Compose UI Test
```

**Layer 1 -- Crystal specs:** Verify that the view hierarchy assigns the correct test_id strings. Fast, no hardware needed.

**Layer 2 -- Platform UI tests:** XCUITest (Apple) or Compose instrumented tests (Android) query views by the native attribute that test_id maps to. These run on simulators or devices.

**Layer 3 -- End-to-end scripts:** Shell scripts that build the app, launch it on a simulator or device, run the Layer 2 tests, and report results. These are orchestrated by CI.

When you add a new interactive element to your Crystal layout, the workflow is:

1. Set `test_id` on the view in Crystal code.
2. Add a Crystal spec asserting the test_id value (Layer 1).
3. Add platform UI tests that query the native attribute (Layer 2).
4. The E2E scripts (Layer 3) pick up the new tests automatically.

---

## FSDD Cross-References

For the full testing specification within FSDD, including coverage mapping tables, test layer definitions, and partial-testability analysis, see:

- `Feature-Story-Driven-Development/Part-5-Advanced-Topics/16-Testing-Specification/`
- `docs/fsdd/testing/partial-testability-epic-7.md` (in projects using FSDD)
- Feature story epic docs that include test mapping tables linking story IDs to test_id values

---

## See Also

- [API Reference](API_REFERENCE.md)
- [Usage Examples](USAGE_EXAMPLES.md)
