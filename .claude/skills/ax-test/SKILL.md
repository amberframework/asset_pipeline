# UI::AXTest — Crystal-Native UI Testing Skill

## When to Use
- Testing native macOS UI rendering and accessibility
- Verifying settings/preferences windows have correct elements
- Testing first-run wizards and onboarding flows
- UI regression testing after renderer or view changes
- Accessibility compliance verification (VoiceOver readiness)

## Require
```crystal
require "asset_pipeline/ui/ax_test"
```

## Link Flags
```
-framework ApplicationServices -framework CoreFoundation
```

## Prerequisites
- The app must be **code-signed** (unsigned apps can't be queried via AXUIElement)
- The test runner (Terminal) needs **Accessibility permission** in System Settings → Privacy → Accessibility
- macOS 13.0+ required

## Standard Test File Structure
```
my_app/
  spec/
    ui/
      ui_spec_helper.cr    # Launch app, require ax_test
      settings_spec.cr     # Test the settings/preferences window
      wizard_spec.cr       # Test the first-run wizard
      about_spec.cr        # Test the about window
  Makefile                 # make test-ui target
```

## Makefile Target
```makefile
test-ui: macos-release bundle sign
	crystal-alpha spec spec/ui/ -Dmacos --link-flags="-framework ApplicationServices -framework CoreFoundation"
```

## Core API

### Launch an app
```crystal
app = UI::AXTest::App.launch("/Applications/MyApp.app")
# Or connect to already-running app:
app = UI::AXTest::App.connect(pid)
```

### Find windows
```crystal
prefs = app.window("My App Preferences")  # finds by title, waits up to 5s
prefs.should_not be_nil
```

### Find elements by role and/or label
```crystal
# Find by accessibility label (set via view.accessibility_label in Crystal)
btn = prefs.find(label: "Browse for audio save location")

# Find by role
toggle = prefs.find(role: "AXCheckBox")

# Find by both
dropdown = prefs.find(role: "AXPopUpButton", label: "Select model")

# Find all matching
edit_buttons = prefs.find_all(role: "AXButton", label: /Edit/)
```

### Read element properties
```crystal
element.role      # => "AXButton"
element.title     # => "Browse..."
element.label     # => "Browse for audio save location"
element.value     # => current value (for text fields, toggles)
element.enabled?  # => true/false
element.focused?  # => true/false
```

### Interact with elements
```crystal
button.click       # Performs AXPress action
```

### Take screenshots
```crystal
app.screenshot("/tmp/test_screenshots/settings.png")
# Or use the helper:
path = UI::AXTest::Screenshot.test_path("settings", "scribe")
app.screenshot(path)
```

### Debugging
```crystal
# Print the full accessibility tree
app.dump

# Print a subtree
prefs.dump
```

### Check accessibility permission
```crystal
UI::AXTest::App.accessibility_trusted?  # => true/false
```

### Cleanup
```crystal
app.terminate       # Graceful quit
app.force_terminate # kill -9
```

## Example Complete Test File

```crystal
require "spec"
require "asset_pipeline/ui/ax_test"

describe "Scribe Settings" do
  app : UI::AXTest::App? = nil

  before_all do
    app = UI::AXTest::App.launch("/Applications/Scribe.app", wait_seconds: 5.0)
  end

  after_all do
    app.try(&.terminate)
  end

  it "opens preferences window" do
    # Click the status item menu → Preferences
    # (For menu bar apps, may need to simulate via accessibility)
    prefs = app.not_nil!.window("Scribe Preferences")
    prefs.should_not be_nil
    app.not_nil!.screenshot("/tmp/scribe_test/01_preferences.png")
  end

  it "has audio save location section" do
    prefs = app.not_nil!.window("Scribe Preferences")
    browse = prefs.not_nil!.find(label: "Browse for audio save location")
    browse.should_not be_nil
  end

  it "has recording modes with edit buttons" do
    prefs = app.not_nil!.window("Scribe Preferences")
    edit_buttons = prefs.not_nil!.find_all(role: "AXButton").select { |b| b.label.try(&.includes?("Edit")) }
    edit_buttons.size.should be >= 1
  end

  it "has whisper model dropdown" do
    prefs = app.not_nil!.window("Scribe Preferences")
    dropdown = prefs.not_nil!.find(role: "AXPopUpButton", label: "Select whisper transcription model")
    dropdown.should_not be_nil
  end

  it "has toggle for launch at login" do
    prefs = app.not_nil!.window("Scribe Preferences")
    toggle = prefs.not_nil!.find(role: "AXCheckBox")
    toggle.should_not be_nil
  end
end
```

## Testability Conventions

1. **Every interactive element MUST have `accessibility_label`** — this is how tests find elements
2. **Labels should be descriptive** — "Browse for audio save location" not "Browse"
3. **Window titles must be unique and stable** — tests find windows by title
4. **`spec/ui/` directory** is the standard location
5. **`make test-ui`** is the standard Makefile target
6. **Tests should be independent** — each test can run alone
7. **Screenshots saved to `/tmp/{app}_test_screenshots/`**
