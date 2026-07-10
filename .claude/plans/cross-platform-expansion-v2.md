# Cross-Platform UI Expansion Plan — Version 2

**Date:** 2026-02-19
**Branch context:** asset_pipeline (current), crystal/incremental-compilation
**Supersedes:** `.claude/cross_platform_plan.md` (v1) for all forward work
**Status:** Milestones 1–8 from v1 are mostly complete. This plan covers expansion beyond the initial 9 P0 view types.

---

## Section 1: Executive Summary

### What We Are Building

The asset_pipeline currently exposes 9 cross-platform `UI::View` types (Label, Button, VStack, HStack, ZStack, Image, TextField, ScrollView, Spacer) with four working platform renderers (Web/HTML, AppKit/macOS, UIKit/iOS, Android/JNI). This expansion phase adds approximately 51 new component types identified through systematic research into iOS 26 / macOS 26, Android Jetpack Compose / Material 3, and cross-platform patterns from Flutter.

Target composition after expansion:
- **P0 (done):** 9 views — the core vocabulary
- **P1 (next wave):** 14 views — used in 90%+ of apps, unlock real-world UI patterns
- **P2 (second wave):** 25 views — richer experiences, platform-divergent patterns
- **P3 (stubs):** 12 views — specialized or high-complexity, compile but render placeholders
- **Total:** ~60 views — a complete cross-platform component vocabulary

### Architecture Approach

The architecture established in v1 is unchanged and correct:

1. **Native components over custom drawing.** Every view maps to a real platform widget. No custom paint loops, no Skia, no Canvas overrides for standard controls. Native widgets provide accessibility, keyboard navigation, scrolling physics, and OS-version adaptations for free.

2. **PlatformVisitor with compile-time dispatch.** A single `abstract def visit(view : NewView)` in `PlatformVisitor` forces all four renderers to implement every new view type at compile time. Missing implementations are compiler errors, not runtime crashes.

3. **Composition over inheritance.** Many P2/P3 "components" are better expressed as factory functions that compose existing P0/P1 views. A `card()` factory returning a styled `VStack` requires zero new platform code. Prefer this pattern before creating new view classes.

4. **Modifier properties on the base class, not wrapper views.** Shadow, blur, corner radius, and border are properties on `UI::View`, not separate view types that wrap other views. This avoids Flutter's "pyramid of doom" anti-pattern.

### Key Architecture Decisions (from Flutter Lessons)

| Decision | Rationale |
|----------|-----------|
| Never add a custom layout engine | NSStackView, UIStackView, LinearLayout, CSS flexbox are each better than anything we would write |
| Never custom-implement text input | UITextField / NSTextField / EditText have IME, locale, and accessibility correct; we inherit all of it |
| Never add a three-tree model (Widget / Element / RenderObject) | We delegate layout to native; we only need one tree |
| Platform dispatch at compile time, not runtime | `flag?()` macros produce zero runtime branches; smaller binaries |
| Accessibility is inherited, not synthesized | Setting `accessibility_label` on `UI::View` propagates to native; we never build an accessibility tree |

### Scope Summary

| Phase | Milestone | Deliverable |
|-------|-----------|-------------|
| Infrastructure | A | Modifier system, new enums, expanded CallbackRegistry |
| P1 Batch 1 | B | Toggle, Checkbox, RadioButton, Slider — all 4 renderers |
| P1 Batch 2 | C | NavigationStack, NavigationLink, TabView — all 4 renderers |
| P1 Batch 3-4 | D | ProgressBar, ActivityIndicator, Alert, SecureField, Picker, IconButton, List |
| P2 Wave 1 | E | Stepper, SegmentedControl, DatePicker, TimePicker, SearchField, TextArea, Grid, Form |
| P2 Wave 2 | F | NavigationSplitView, Toolbar, Sheet, Popover, ConfirmationDialog, Snackbar, Card, Surface, Divider, GlassBackground, Shadow/Blur modifiers |
| P2 Wave 3 + P3 | G | AsyncImage, RichText, LinkButton, MenuButton, ToggleButton, TextEditor + all P3 stubs |

---

## Section 2: Prerequisites and Infrastructure Upgrades

Before implementing any new view types, the following infrastructure must be in place. All work in Milestone A.

### 2a. Modifier System — New Base View Properties

The current `UI::View` base class has six properties: `id`, `accessibility_label`, `padding`, `background`, `hidden`, `opacity`. Expand it with the following:

```crystal
# src/ui/view.cr — additions to abstract class UI::View

# Shape modifiers
property corner_radius : Float64 = 0.0
property clip_to_bounds : Bool = false

# Shadow modifier (flat properties, no nested record to avoid nullable record issues)
property shadow_radius : Float64 = 0.0
property shadow_color : Color? = nil
property shadow_offset_x : Float64 = 0.0
property shadow_offset_y : Float64 = 0.0

# Border modifier
property border_width : Float64 = 0.0
property border_color : Color? = nil

# Blur modifier (0 = no blur; degrade gracefully on Android < 12)
property blur_radius : Float64 = 0.0

# Size constraints
property minimum_width : Float64? = nil
property minimum_height : Float64? = nil
property maximum_width : Float64? = nil
property maximum_height : Float64? = nil
```

Each renderer must apply these in a shared helper method called after instantiating the native view:

- **Web:** `box-shadow`, `border-radius`, `border`, `filter: blur()`, `min-width`/`max-width` CSS properties
- **AppKit:** `layer.cornerRadius`, `layer.shadowRadius`, `layer.shadowColor`, `layer.shadowOffset`, `NSShadow`, `layer.masksToBounds`, `CIFilter` blur on the layer
- **UIKit:** `layer.cornerRadius`, `layer.shadowRadius`, `layer.shadowColor`, `layer.shadowOffset`, `layer.masksToBounds`, `UIVisualEffectView` blur wrapper when `blur_radius > 0`
- **Android:** `setElevation()` approximates shadow; `RenderEffect.createBlurEffect()` for blur (API 31+, else skip gracefully); no native corner radius on base `View` — use a `ShapeDrawable` background

### 2b. New Enum Definitions

Add to `src/ui/enums.cr` (or individual view files if co-located):

```crystal
module UI
  enum ToggleStyle
    Switch      # UISwitch / NSButton(switch) / Switch / <input role="switch">
    Checkbox    # Checkbox-shaped toggle on platforms that support it
    Custom      # Platform decides
  end

  enum PickerStyle
    Wheel       # UIPickerView scrolling wheel (iOS)
    Segmented   # UISegmentedControl / NSSegmentedControl style
    Menu        # Dropdown menu (NSPopUpButton / UIButton+UIMenu)
    Inline      # Inline selection (calendar, etc.)
  end

  enum DatePickerMode
    Date          # Date only
    Time          # Time only
    DateAndTime   # Full date + time
  end

  enum ProgressStyle
    Linear      # Horizontal bar
    Circular    # Spinning circle
  end

  enum NavigationStyle
    Stack       # Push/pop navigation (UINavigationController model)
    Split       # Sidebar + detail (UISplitViewController model)
  end

  enum AlertStyle
    Alert               # Centered modal alert
    ConfirmationDialog  # Action sheet / bottom sheet style
  end

  enum ListStyle
    Plain           # Simple list, no section chrome
    Inset           # Inset rows with rounded backgrounds (iOS 14+)
    Grouped         # Section headers/footers with grouped background
    InsetGrouped    # Inset + grouped (iOS 14+ default)
    Sidebar         # macOS sidebar-appropriate style
  end

  enum TabPosition
    Bottom    # iOS bottom tab bar, Android bottom nav
    Top       # Android top tab layout, Web horizontal tabs
    Leading   # macOS sidebar tabs
  end
end
```

### 2c. CallbackRegistry Expansion

The current `UI::CallbackRegistry` supports `Proc(Nil)` (for `on_tap`) and `Proc(String, Nil)` (for `on_change` on text fields). New view types require additional callback signatures.

```crystal
# src/ui/callback_registry.cr — additions

module UI::CallbackRegistry
  # Existing
  # register_tap(id : Int64, proc : Proc(Nil))
  # register_change(id : Int64, proc : Proc(String, Nil))
  # dispatch(id : Int64)
  # dispatch_change(id : Int64, value : String)

  # New: Boolean callback (Toggle on_change, Checkbox on_change)
  def self.register_bool_change(id : Int64, proc : Proc(Bool, Nil))
  def self.dispatch_bool_change(id : Int64, value : Bool)

  # New: Float64 callback (Slider on_change, Stepper on_change)
  def self.register_float_change(id : Int64, proc : Proc(Float64, Nil))
  def self.dispatch_float_change(id : Int64, value : Float64)

  # New: Int32 callback (Picker on_selected_index_change, SegmentedControl, TabView on_tab_change)
  def self.register_int_change(id : Int64, proc : Proc(Int32, Nil))
  def self.dispatch_int_change(id : Int64, value : Int32)

  # New: Time callback (DatePicker on_change)
  def self.register_time_change(id : Int64, proc : Proc(Time, Nil))
  def self.dispatch_time_change(id : Int64, epoch_seconds : Int64)
end
```

The C-level `crystal_ui_callback_dispatch` entry point must be extended to handle the new payload types. The simplest approach: add typed dispatch functions with distinct symbols:

```c
// jni_bridge.c and objc_bridge.c additions
void crystal_ui_dispatch_bool(long id, int value);
void crystal_ui_dispatch_float(long id, double value);
void crystal_ui_dispatch_int(long id, int value);
void crystal_ui_dispatch_time(long id, long epoch_seconds);
```

On the ObjC side, new `target-action` selectors encode the callback type prefix: `crystalBoolAction_<id>:`, `crystalFloatAction_<id>:`. On the JNI side, the `CrystalCallbackBridge` gets new `static native` methods per payload type.

### 2d. `UI::Size` Value Type

Several new views need size constraints. Add to `src/ui/value_types.cr`:

```crystal
record UI::Size, width : Float64, height : Float64
```

---

## Section 3: P1 Components — High Priority Next Wave

P1 components appear in 90%+ of production apps. All P1 components must be implemented with all four renderers before any P2 work begins. They are grouped into implementation batches based on shared callback patterns.

For each view: the Crystal class definition, the platform mapping table, implementation notes per renderer, bridge additions needed, and complexity estimate.

---

### Batch 1: Selection Controls

**Components:** Toggle, Checkbox, RadioButton (+RadioGroup container), Slider

All four share the same callback infrastructure: they take a value-typed `on_change` callback. Implement the CallbackRegistry `Proc(Bool, Nil)` and `Proc(Float64, Nil)` types (Section 2c) before starting this batch.

---

#### 3.1 `UI::Toggle`

```crystal
# src/ui/views/toggle.cr

class UI::Toggle < UI::View
  property label : String
  property is_on : Bool = false
  property style : ToggleStyle = ToggleStyle::Switch
  property on_change : Proc(Bool, Nil)? = nil
  property tint_color : Color? = nil  # active color

  def initialize(@label : String, @is_on : Bool = false)
  def initialize(@label : String, @is_on : Bool = false, &block : Bool -> Nil)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Class | Notes |
|----------|-------------|-------|
| UIKit (iOS) | `UISwitch` | `setOn:animated:`, `addTarget:action:` for `UIControlEventValueChanged`. Label placed in a `UIStackView` horizontally alongside the switch. |
| AppKit (macOS) | `NSButton` with `setButtonType: 6` (NSToggleButton → use `NSButtonTypePushOnPushOff`) | macOS 14+: use `NSSwitch` which is an actual slide toggle. For macOS 10.15–13: `NSButton(buttonType: .switch)` with title. |
| Android | `com.google.android.material.switchmaterial.SwitchMaterial` or `androidx.appcompat.widget.SwitchCompat` | `setChecked()`, `setOnCheckedChangeListener()`. Wrap in `LinearLayout` with a `TextView` label. |
| Web | `<label>` containing `<input type="checkbox" role="switch">` | Style with CSS to look like a pill toggle. Emit `data-action` for reactive dispatch. ARIA role="switch" for accessibility. |

**ObjC Bridge additions (Toggle):**
- `objc_uiswitch_create(env) -> id`
- `objc_uiswitch_set_on(env, switch_ref, on : Bool)`
- `objc_uiswitch_get_on(env, switch_ref) -> Bool`
- Target-action pattern using `crystalBoolAction_<id>:` selector

**JNI Bridge additions (Toggle):**
- `jni_switchmaterial_create(env, context) -> jobject`
- `jni_switchmaterial_set_checked(env, switch_ref, checked : Bool)`
- `jni_set_oncheckedchange_listener(env, switch_ref, callback_id : Int64)`

**Complexity:** Low-Medium. The pattern is identical to Button but with a boolean return value.

---

#### 3.2 `UI::Checkbox`

```crystal
# src/ui/views/checkbox.cr

class UI::Checkbox < UI::View
  property label : String
  property is_checked : Bool = false
  property on_change : Proc(Bool, Nil)? = nil
  property disabled : Bool = false

  def initialize(@label : String, @is_checked : Bool = false)
  def initialize(@label : String, @is_checked : Bool = false, &block : Bool -> Nil)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Class | Notes |
|----------|-------------|-------|
| UIKit (iOS) | `UIButton` with custom checkmark image | No native UICheckbox. Use `UIButton` in `.custom` style. Swap image between "checkbox.empty" and "checkmark.square.fill" SF Symbols on tap. `UIControlEventTouchUpInside`. |
| AppKit (macOS) | `NSButton` with `setButtonType: 3` (`NSButtonTypeSwitch`) | Native macOS checkbox. `setTitle:`. Target-action for state change. `state` is `NSControlStateValueOn/Off`. |
| Android | `android.widget.CheckBox` | Native. `setChecked()`, `setOnCheckedChangeListener()`. |
| Web | `<label>` + `<input type="checkbox">` | Semantic HTML checkbox with label. `data-action` for reactive dispatch. |

**ObjC Bridge additions (Checkbox):** Reuse UIButton bridge for iOS. AppKit: `objc_nsbutton_set_button_type(env, btn, type: 3)`.

**JNI Bridge additions (Checkbox):**
- `jni_checkbox_create(env, context) -> jobject`
- `jni_checkbox_set_checked(env, cb, checked : Bool)`
- `jni_checkbox_set_text(env, cb, text : String)`
- `jni_set_oncheckedchange_listener(env, cb, callback_id : Int64)` (reusable from Toggle)

**Complexity:** Low. macOS and Android are native checkboxes. iOS requires a styled UIButton.

---

#### 3.3 `UI::RadioButton` and `UI::RadioGroup`

```crystal
# src/ui/views/radio_button.cr

class UI::RadioButton < UI::View
  property label : String
  property value : String          # the logical value this button represents
  property is_selected : Bool = false
  property on_select : Proc(String, Nil)? = nil  # called with self.value when selected

  def initialize(@label : String, @value : String)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end

class UI::RadioGroup < UI::View
  property options : Array(RadioButton)
  property selected_value : String? = nil
  property on_change : Proc(String, Nil)? = nil   # called with the new selected value

  getter children : Array(View)  # alias for visitor iteration

  def initialize(@selected_value : String? = nil)
  def initialize(@selected_value : String? = nil, &block : String -> Nil)

  def add(button : RadioButton) : self

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Class | Notes |
|----------|-------------|-------|
| UIKit (iOS) | `UIButton` (custom) per option, or third-party | No native `UIRadioButton`. Each option is a `UIButton` in `.custom` style with SF Symbol circle icons. The group manages mutual exclusion in Crystal before calling the renderer. |
| AppKit (macOS) | `NSButton` with `setButtonType: 4` (`NSButtonTypeRadio`) per option | Native macOS radio buttons. No automatic mutual exclusion — the group must coordinate. |
| Android | `android.widget.RadioButton` inside `android.widget.RadioGroup` | Fully native. `RadioGroup.setOnCheckedChangeListener()` returns the checked ID; map back to Crystal value. |
| Web | `<fieldset>` + `<legend>` + repeated `<input type="radio" name="groupX">` | All buttons must share the same `name` attribute for browser-native mutual exclusion. |

**Implementation note:** The `RadioGroup` visitor method renders the full group as a unit, not by iterating individual `RadioButton` children through the visitor. On Android, it creates a single `RadioGroup` and populates it. On iOS, it creates a `UIStackView` with custom radio-style buttons and manages selection state internally. Pass the `callback_id` to the native side; the C bridge calls `crystal_ui_dispatch_string(id, value)` on selection.

**ObjC Bridge additions:** Reuse `NSButton` bridge. Add `objc_nsbutton_set_state(env, btn, state : Int32)`.

**JNI Bridge additions:**
- `jni_radiogroup_create(env, context) -> jobject`
- `jni_radiobutton_create(env, context, text : String) -> jobject`
- `jni_radiogroup_add_button(env, group, button) -> jobject` (returns button id)
- `jni_radiogroup_set_onchange(env, group, callback_id : Int64, values_json : String)`

**Complexity:** Medium. Android is clean native. iOS requires custom button management.

---

#### 3.4 `UI::Slider`

```crystal
# src/ui/views/slider.cr

class UI::Slider < UI::View
  property value : Float64 = 0.0
  property min_value : Float64 = 0.0
  property max_value : Float64 = 1.0
  property step : Float64? = nil       # nil = continuous
  property on_change : Proc(Float64, Nil)? = nil
  property tint_color : Color? = nil   # track fill color
  property disabled : Bool = false

  def initialize(@min_value : Float64 = 0.0, @max_value : Float64 = 1.0, @value : Float64 = 0.0)
  def initialize(@min_value : Float64, @max_value : Float64, @value : Float64, &block : Float64 -> Nil)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Class | Notes |
|----------|-------------|-------|
| UIKit (iOS) | `UISlider` | `minimumValue`, `maximumValue`, `value`. Target-action on `UIControlEventValueChanged`. `minimumTrackTintColor` for `tint_color`. Step via `round(value / step) * step` in callback. |
| AppKit (macOS) | `NSSlider` | `setMinValue:`, `setMaxValue:`, `setFloatValue:`, `setNumberOfTickMarks:` for step. Target-action on `NSSlider` change. `setSliderType: NSLinearSlider`. |
| Android | `com.google.android.material.slider.Slider` | `valueFrom`, `valueTo`, `value`, `stepSize`. `addOnSliderTouchListener` / `addOnChangeListener`. |
| Web | `<input type="range" min="X" max="Y" step="Z">` | Native range input. `oninput` event via `data-action`. |

**ObjC Bridge additions:**
- `objc_uislider_create(env) -> id`
- `objc_uislider_set_range(env, slider, min : Float64, max : Float64)`
- `objc_uislider_set_value(env, slider, value : Float64)`
- `objc_nsslider_create(env) -> id` (AppKit variant)

**JNI Bridge additions:**
- `jni_slider_create(env, context) -> jobject`
- `jni_slider_configure(env, slider, from : Float32, to : Float32, value : Float32, step : Float32)`
- `jni_slider_set_onchange(env, slider, callback_id : Int64)`

**Complexity:** Low. Direct native equivalents on all platforms with clean APIs.

---

### Batch 2: Navigation

**Components:** NavigationStack, NavigationLink, TabView

Navigation is the most complex cross-platform challenge. Read Section 6 (Navigation Architecture Deep Dive) before implementing this batch. This batch depends on Milestone A being complete. It does NOT depend on Batch 1.

---

#### 3.5 `UI::NavigationStack`

```crystal
# src/ui/views/navigation_stack.cr

class UI::NavigationStack < UI::View
  property root_view : View
  property title : String? = nil
  property large_title : Bool = false          # iOS large title mode
  property shows_back_button : Bool = true

  # Navigation state — managed by the renderer, not Crystal
  # Renderers maintain their own stack internally and expose
  # push/pop through platform-native mechanisms.

  def initialize(@root_view : View)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

See Section 6 for the full navigation architecture. The key design decision: `NavigationStack` holds only the root view. The native renderer manages the push/pop stack. Crystal does not maintain a view stack in memory beyond the initial root.

**Platform Mapping:**

| Platform | Native Container | Back Navigation |
|----------|-----------------|-----------------|
| UIKit (iOS) | `UINavigationController` | `UINavigationBar` back button + swipe gesture |
| AppKit (macOS) | Custom `NSViewController` stack inside `NSView` with a `NSButton` back button in the toolbar | Manual, no system chrome |
| Android | `FragmentManager` + `addToBackStack()` + custom `Toolbar` with back button | System back gesture + `Toolbar` navigation icon |
| Web | JS history API (`history.pushState`) + `<div>` visibility switch | Browser back button |

**ObjC Bridge additions (NavigationStack):**
- `objc_uinavcontroller_create(env, root_view : id) -> id`
- `objc_uinavcontroller_push(env, nav, view : id, animated : Bool)`
- `objc_uinavcontroller_pop(env, nav, animated : Bool)`
- AppKit: `objc_nsview_add_subview_fade(env, container, view : id)`

**JNI Bridge additions (NavigationStack):**
- `jni_fragmentmanager_push(env, fm, fragment_class : String, args_json : String, tag : String)`
- `jni_fragmentmanager_pop(env, fm)`
- `jni_fragmentmanager_get(env, activity) -> jobject`

**Complexity:** High. Each platform has a fundamentally different navigation model. Plan for 3–4x the implementation time of a standard view.

---

#### 3.6 `UI::NavigationLink`

```crystal
# src/ui/views/navigation_link.cr

class UI::NavigationLink < UI::View
  property label : String
  property destination : View         # the view to push when tapped
  property destination_title : String? = nil

  def initialize(@label : String, destination : View)
    @destination = destination
  end

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Implementation |
|----------|---------------|
| UIKit (iOS) | `UIButton` in plain style that calls `UINavigationController.pushViewController(_:animated:)` on tap |
| AppKit (macOS) | `NSButton` with link bezel style that triggers the custom navigation stack push |
| Android | `MaterialButton` (text style) that triggers a `FragmentManager.beginTransaction().replace().addToBackStack().commit()` |
| Web | `<a>` element with `href="#"` and `onclick` that calls `history.pushState` and swaps the visible view `<div>` |

**Complexity:** Medium. Depends entirely on `NavigationStack` being set up first. The button itself is trivial; the navigation call is the complexity.

---

#### 3.7 `UI::TabView`

```crystal
# src/ui/views/tab_view.cr

class UI::TabView < UI::View
  record Tab,
    label : String,
    icon : String?,          # SF Symbol name / Material icon name / filename
    content : View

  property tabs : Array(Tab)
  property selected_index : Int32 = 0
  property tab_position : TabPosition = TabPosition::Bottom
  property on_tab_change : Proc(Int32, Nil)? = nil

  def initialize(@tabs : Array(Tab) = [] of Tab, @selected_index : Int32 = 0)

  def add_tab(label : String, icon : String? = nil, &block : -> View) : self

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Container | Tab Position |
|----------|-----------------|-------------|
| UIKit (iOS) | `UITabBarController` | Bottom (system default, system chrome) |
| AppKit (macOS) | `NSTabViewController` | Top (tab strip) or as `NSSegmentedControl` |
| Android | `com.google.android.material.bottomnavigation.BottomNavigationView` + `ViewPager2` (or Fragment swap) | Bottom (Material 3 default) |
| Web | Custom `<nav role="tablist">` + `<div role="tabpanel">` | Flexible — default top |

**ObjC Bridge additions (TabView):**
- `objc_uitabbarcontroller_create(env) -> id`
- `objc_uitabbarcontroller_set_viewcontrollers(env, tbc, vcs : Array(id), animated : Bool)`
- `objc_uitabbaritem_create(env, title : String, image_name : String) -> id`
- `objc_nstabviewcontroller_create(env) -> id`
- `objc_nstabviewitem_create(env, label : String, view : id) -> id`

**JNI Bridge additions (TabView):**
- `jni_bottomnavigationview_create(env, context) -> jobject`
- `jni_bottomnavigationview_add_item(env, nav, item_id : Int32, title : String, icon_res : Int32)`
- `jni_bottomnavigationview_set_onitemselected(env, nav, callback_id : Int64)`

**Complexity:** High. Tab position varies per platform. Content swapping strategy differs. Badge support is a later concern.

---

### Batch 3: Feedback Views

**Components:** ProgressBar, ActivityIndicator, Alert

---

#### 3.8 `UI::ProgressBar`

```crystal
# src/ui/views/progress_bar.cr

class UI::ProgressBar < UI::View
  property value : Float64 = 0.0     # 0.0 to 1.0
  property tint_color : Color? = nil  # filled track color
  property track_color : Color? = nil # unfilled track color

  def initialize(@value : Float64 = 0.0)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Class | Notes |
|----------|-------------|-------|
| UIKit | `UIProgressView` | `setProgress:animated:`, `progressTintColor` |
| AppKit | `NSProgressIndicator` | `setIndeterminate: NO`, `style: NSProgressIndicatorStyleBar`, `setDoubleValue:`, `maxValue: 1.0` |
| Android | `android.widget.ProgressBar` (horizontal style) | `setProgress((int)(value * 100))`, `setMax(100)`. Use `android.R.attr.progressBarStyleHorizontal`. |
| Web | `<progress value="X" max="1">` | Native HTML progress element. CSS for color via `accent-color`. |

**ObjC Bridge additions:**
- `objc_uiprogressview_create(env) -> id`
- `objc_uiprogressview_set_progress(env, pv, value : Float64)`
- `objc_nsprogressindicator_create_bar(env) -> id`
- `objc_nsprogressindicator_set_value(env, pi, value : Float64)`

**JNI Bridge additions:**
- `jni_progressbar_create_horizontal(env, context) -> jobject`
- `jni_progressbar_set_progress(env, pb, value : Int32, max : Int32)`

**Complexity:** Low. All platforms have direct equivalents.

---

#### 3.9 `UI::ActivityIndicator`

```crystal
# src/ui/views/activity_indicator.cr

class UI::ActivityIndicator < UI::View
  property is_animating : Bool = true
  property style : ProgressStyle = ProgressStyle::Circular
  property color : Color? = nil

  def initialize(@is_animating : Bool = true)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Class | Notes |
|----------|-------------|-------|
| UIKit | `UIActivityIndicatorView` | `startAnimating` / `stopAnimating`. `style: .medium` or `.large`. `color` for tint. |
| AppKit | `NSProgressIndicator` | `setIndeterminate: YES`, `style: NSProgressIndicatorStyleSpinning`, `startAnimation:` / `stopAnimation:` |
| Android | `android.widget.ProgressBar` (circular, indeterminate) | Default style is circular indeterminate. `setVisibility(VISIBLE/GONE)`. |
| Web | `<div class="ui-spinner">` + CSS keyframe `@keyframes spin { to { transform: rotate(360deg) } }` | Pure CSS spinner. No HTML element equivalent. |

**ObjC Bridge additions:** Reuse `NSProgressIndicator` bridge. Add `objc_uiactivityindicator_create(env) -> id`, `objc_uiactivityindicator_start(env, ai)`, `objc_uiactivityindicator_stop(env, ai)`.

**JNI Bridge additions:** `jni_progressbar_create_circular(env, context) -> jobject` (default ProgressBar is already circular/indeterminate).

**Complexity:** Low.

---

#### 3.10 `UI::Alert`

Alert is fundamentally different from other view types: it is presented imperatively over the current content, not placed in the view tree. The Crystal API must reflect this.

```crystal
# src/ui/views/alert.cr

class UI::Alert
  record Action,
    title : String,
    style : ActionStyle,
    on_tap : Proc(Nil)?

  enum ActionStyle
    Default
    Cancel
    Destructive
  end

  property title : String
  property message : String? = nil
  property actions : Array(Action)

  def initialize(@title : String, @message : String? = nil)
  def add_action(title : String, style : ActionStyle = ActionStyle::Default, &block : -> Nil) : self
  def add_cancel(title : String = "Cancel") : self
end

# Presentation is done via a platform-level AlertPresenter, NOT via the view tree.
# AlertPresenter is a module that each renderer module extends:

module UI::AlertPresenter
  abstract def present_alert(alert : Alert, from_view : View? = nil)
end
```

**Implementation strategy:** `UI::Alert` is NOT a `UI::View`. It does not go through `PlatformVisitor`. Instead, the app holds a reference to the platform renderer (which implements `AlertPresenter`) and calls `present_alert(alert)` on it directly. The renderer presents the alert using platform APIs:

| Platform | Presentation API | Notes |
|----------|-----------------|-------|
| UIKit | `UIAlertController(style: .alert)` presented via `UIViewController.present(_:animated:)` | Actions added with `UIAlertAction`. Destructive style turns red. |
| AppKit | `NSAlert` | `addButtonWithTitle:`, `runModal()` (synchronous) or `beginSheetModal(for:)` (async). |
| Android | `AlertDialog.Builder` + `AlertDialog.show()` | `setTitle`, `setMessage`, `setPositiveButton`, `setNegativeButton`, `setNeutralButton`. |
| Web | `<dialog>` element with `.showModal()` | HTML5 dialog. Style with CSS. Close with `dialog.close()`. |

**ObjC Bridge additions:**
- `objc_uialertcontroller_create(env, title : String, message : String, style : Int32) -> id`
- `objc_uialertcontroller_add_action(env, ac, title : String, style : Int32, callback_id : Int64)`
- `objc_uivc_present(env, presenting_vc : id, presented_vc : id, animated : Bool)`
- `objc_nsalert_create(env, title : String, message : String) -> id`
- `objc_nsalert_add_button(env, alert, title : String) -> Int32` (returns button index)
- `objc_nsalert_run_modal(env, alert) -> Int32`

**JNI Bridge additions:**
- `jni_alertdialog_create(env, context, title : String, message : String) -> jobject`
- `jni_alertdialog_set_button(env, dialog, which : Int32, text : String, callback_id : Int64)`
- `jni_alertdialog_show(env, dialog)`

**Complexity:** Medium-High. The imperative presentation model is a departure from the view-tree pattern. The `AlertPresenter` module design must be established before implementation.

---

### Batch 4: Input Variants and List

**Components:** SecureField, Picker, IconButton, List

---

#### 3.11 `UI::SecureField`

```crystal
# src/ui/views/secure_field.cr

class UI::SecureField < UI::View
  property text : String = ""
  property placeholder : String = ""
  property font : Font = Font.new
  property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property on_change : Proc(String, Nil)? = nil

  def initialize(@placeholder : String = "")
  def initialize(@placeholder : String = "", &block : String -> Nil)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

`SecureField` is semantically distinct from `TextField(secure_entry: true)` — it can never be toggled to insecure mode, making intent clear. The visitor dispatches separately, but the renderer implementations are essentially identical to `TextField` with `secureTextEntry = true` / `NSSecureTextField` / `inputType = textPassword` / `<input type="password">`.

**Complexity:** Very Low. Effectively a named alias with enforced security mode.

---

#### 3.12 `UI::Picker`

```crystal
# src/ui/views/picker.cr

class UI::Picker < UI::View
  property options : Array(String)
  property selected_index : Int32 = 0
  property style : PickerStyle = PickerStyle::Menu
  property placeholder : String? = nil
  property on_change : Proc(Int32, Nil)? = nil

  def initialize(@options : Array(String), @selected_index : Int32 = 0)
  def initialize(@options : Array(String), @selected_index : Int32 = 0, &block : Int32 -> Nil)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Class | Style Note |
|----------|-------------|-----------|
| UIKit | `UIPickerView` (Wheel style) or `UIButton` with `UIMenu` (Menu style, iOS 14+) | Menu style is preferred for most use cases. Fall back to UIPickerView for Wheel. |
| AppKit | `NSPopUpButton` | Single class handles all styles. `addItemWithTitle:`. `selectItemAtIndex:`. Target-action on `NSPopUpButton`. |
| Android | `android.widget.Spinner` | `ArrayAdapter`, `setOnItemSelectedListener`. Material `ExposedDropdownMenuBox` for full M3 appearance. |
| Web | `<select>` + `<option>` elements | Native browser dropdown. `onchange` event via `data-action`. |

**ObjC Bridge additions:**
- `objc_nspopupbutton_create(env) -> id`
- `objc_nspopupbutton_add_item(env, pb, title : String)`
- `objc_nspopupbutton_select_index(env, pb, index : Int32)`
- `objc_nspopupbutton_get_index(env, pb) -> Int32`
- `objc_uimenu_create_for_button(env, btn, options : Array(String), callback_id : Int64)`

**JNI Bridge additions:**
- `jni_spinner_create(env, context) -> jobject`
- `jni_spinner_set_items(env, spinner, items_json : String)`
- `jni_spinner_set_selection(env, spinner, index : Int32)`
- `jni_spinner_set_onitemselected(env, spinner, callback_id : Int64)`

**Complexity:** Medium. iOS has a UX split between Wheel and Menu styles that requires a decision per use case.

---

#### 3.13 `UI::IconButton`

```crystal
# src/ui/views/icon_button.cr

class UI::IconButton < UI::View
  property icon : String               # SF Symbol / Material icon / filename
  property accessibility_hint : String? = nil
  property icon_size : Float64 = 24.0
  property tint_color : Color? = nil
  property disabled : Bool = false
  property on_tap : Proc(Nil)? = nil

  def initialize(@icon : String)
  def initialize(@icon : String, &block : -> Nil)

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Platform Mapping:**

| Platform | Native Class | Notes |
|----------|-------------|-------|
| UIKit | `UIButton` with `setImage:forState:` | `UIImage(systemName: icon)` for SF Symbols. `tintColor` on button. Remove title. |
| AppKit | `NSButton` with `image` property set, `title = ""` | `NSImage(systemSymbolName:)` for macOS 11+. `bezelStyle = .regularSquare` or `.recessed`. |
| Android | `com.google.android.material.button.MaterialButton` with `icon` attribute only, `text = ""` | Or `ImageButton`. Use Material Icons. `iconGravity = textStart`. |
| Web | `<button class="icon-btn" aria-label="...">` containing `<img>` or SVG inline | `aria-label` required since no visible text. |

**Complexity:** Low. Very similar to Button; just uses an image source instead of a text label.

---

#### 3.14 `UI::List`

```crystal
# src/ui/views/list.cr

class UI::List < UI::View
  property style : ListStyle = ListStyle::Plain
  property items : Array(View)         # Non-virtualized: all items rendered
  property separator_visible : Bool = true
  property separator_color : Color? = nil
  property on_item_tap : Proc(Int32, Nil)? = nil  # called with tapped row index

  def initialize(@style : ListStyle = ListStyle::Plain)
  def <<(item : View) : self

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

**Implementation note — Non-virtualized first:** For v1, implement `List` as a non-lazy container (like a styled `VStack` with dividers). Do NOT implement `UITableView` cell reuse or `RecyclerView` recycling in the first pass. Virtualization is a performance optimization for v2; correctness comes first.

**Platform Mapping:**

| Platform | Native Class (v1) | Notes |
|----------|-----------------|-------|
| UIKit | `UITableView` with static cells | `UITableViewStylePlain` or `UITableViewStyleInsetGrouped`. Static `numberOfRowsInSection` / `cellForRowAt`. Separator lines native. |
| AppKit | `NSTableView` with one column | `NSTableViewStyle` per `ListStyle`. Datasource with fixed row count. |
| Android | `RecyclerView` with `LinearLayoutManager` | Even non-virtualized uses RecyclerView (simpler than ListView). Crystal side provides the item views; RecyclerView calls back via JNI. |
| Web | `<ul>` (plain) or `<div>` with separator lines | `<li>` children. `list-style: none`. Separator via CSS `border-bottom`. |

**Complexity:** Medium-High. `UITableView` requires a delegate/datasource pattern that differs significantly from the other platforms. Plan for this being the largest single implementation in Batch 4.

---

## Section 4: P2 Components — Medium Priority Second Wave

P2 components are summarized with Crystal property sketches and key platform divergence notes. Full implementation detail is generated at milestone time.

---

### 4.1 `UI::Stepper`

```crystal
class UI::Stepper < UI::View
  property value : Float64 = 0.0
  property min_value : Float64 = 0.0
  property max_value : Float64 = 100.0
  property step : Float64 = 1.0
  property on_change : Proc(Float64, Nil)? = nil
end
```

**Platform divergence:** Android has no native Stepper. Compose it from two `MaterialButton` (- and +) and a `TextView` in a `LinearLayout`. iOS `UIStepper` and macOS `NSStepper` are native. Web: `<input type="number" min step max>`. Complexity: Medium (Android composition).

---

### 4.2 `UI::SegmentedControl`

```crystal
class UI::SegmentedControl < UI::View
  property segments : Array(String)
  property selected_index : Int32 = 0
  property on_change : Proc(Int32, Nil)? = nil
end
```

**Platform divergence:** iOS `UISegmentedControl`, macOS `NSSegmentedControl`, Android Material 3 `SegmentedButton` (M3 1.1+), Web custom CSS button group. All have close native equivalents. Complexity: Low-Medium.

---

### 4.3 `UI::DatePicker`

```crystal
class UI::DatePicker < UI::View
  property mode : DatePickerMode = DatePickerMode::Date
  property selected_date : Time = Time.utc
  property min_date : Time? = nil
  property max_date : Time? = nil
  property style : PickerStyle = PickerStyle::Inline
  property on_change : Proc(Time, Nil)? = nil
end
```

**Platform divergence:** iOS has three UIDatePicker presentation styles (compact, inline, wheels). macOS NSDatePicker has text/stepper/clock/calendar modes. Android shows a Material DatePicker dialog. Web uses `<input type="date">`. Requires `Proc(Time, Nil)` callback support in CallbackRegistry (transmit as epoch seconds through the C bridge). Complexity: High.

---

### 4.4 `UI::TimePicker`

```crystal
class UI::TimePicker < UI::View
  property selected_time : Time = Time.utc
  property mode : DatePickerMode = DatePickerMode::Time  # always Time
  property on_change : Proc(Time, Nil)? = nil
end
```

**Note:** May be implemented as `DatePicker` with `mode: .Time` rather than a separate class. Keep separate for type-safe visitor dispatch. Complexity: Medium (shares implementation with DatePicker).

---

### 4.5 `UI::SearchField`

```crystal
class UI::SearchField < UI::View
  property text : String = ""
  property placeholder : String = "Search"
  property on_change : Proc(String, Nil)? = nil
  property on_submit : Proc(String, Nil)? = nil
end
```

**Platform divergence:** iOS `UISearchTextField` (iOS 13+, preferred) or `UISearchBar`. macOS `NSSearchField` (subclass of NSTextField). Android `SearchView` or `MaterialSearchBar` (M3). Web `<input type="search">`. Complexity: Low-Medium.

---

### 4.6 `UI::TextArea`

```crystal
class UI::TextArea < UI::View
  property text : String = ""
  property placeholder : String = ""
  property min_lines : Int32 = 3
  property max_lines : Int32? = nil
  property on_change : Proc(String, Nil)? = nil
end
```

**Platform mapping:** iOS `UITextView` (editable), macOS `NSTextView` (in `NSScrollView`), Android `EditText` with `minLines`/`maxLines` + `inputType=textMultiLine`, Web `<textarea rows="N">`. Complexity: Low-Medium.

---

### 4.7 `UI::LinkButton`

```crystal
class UI::LinkButton < UI::View
  property label : String
  property url : String
end
```

**Platform divergence:** macOS `NSWorkspace.shared.open(URL)`. iOS `UIApplication.shared.open(URL)`. Android `Intent(Intent.ACTION_VIEW, Uri.parse(url))`. Web `<a href="...">`. The action is platform-specific URL opening; no `on_tap` needed (the URL is the action). Complexity: Low.

---

### 4.8 `UI::MenuButton`

```crystal
class UI::MenuButton < UI::View
  record MenuItem,
    label : String,
    icon : String?,
    on_tap : Proc(Nil)?

  property label : String
  property items : Array(MenuItem)
end
```

**Platform divergence:** macOS `NSPopUpButton` or `NSMenu`. iOS `UIButton` with `UIMenu` (iOS 14+ required). Android `PopupMenu` or Material `DropdownMenu`. Web custom `<div>` dropdown. The iOS 14+ requirement is a hard lower bound. Complexity: Medium.

---

### 4.9 `UI::ToggleButton`

```crystal
class UI::ToggleButton < UI::View
  property label : String
  property icon : String? = nil
  property is_selected : Bool = false
  property on_change : Proc(Bool, Nil)? = nil
end
```

**Platform mapping:** UIKit `UIButton` with `isSelected` state, custom styling. AppKit `NSButton` with `setButtonType: NSButtonTypePushOnPushOff`. Android Material 3 `FilledTonalButton` or native `ToggleButton`. Web `<button aria-pressed="true/false">`. Complexity: Low-Medium.

---

### 4.10 `UI::Grid`

```crystal
class UI::Grid < UI::View
  property columns : Int32 = 2
  property spacing : Float64 = 8.0
  property items : Array(View)

  def initialize(@columns : Int32 = 2, @spacing : Float64 = 8.0)
  def <<(item : View) : self
end
```

**Platform divergence:** UIKit `UICollectionView` with `UICollectionViewFlowLayout`. AppKit `NSCollectionView` with `NSCollectionViewGridLayout`. Android `RecyclerView` with `GridLayoutManager(context, columns)`. Web CSS Grid `display:grid; grid-template-columns: repeat(N, 1fr)`. Most complex layout primitive due to UICollectionView API differences. Complexity: High.

---

### 4.11 `UI::Form`

```crystal
class UI::Form < UI::View
  record Section,
    title : String?,
    footer : String?,
    rows : Array(View)

  property sections : Array(Section)
  property style : ListStyle = ListStyle::InsetGrouped

  def add_section(title : String? = nil, &block : Array(View) -> Nil) : self
end
```

**Platform mapping:** iOS `UITableView` (grouped style) — `Form` is essentially a grouped List for settings. macOS: a `VStack` with section headers (NSForm is a legacy control). Android: `RecyclerView` with section headers. Web: `<form>` with `<fieldset>` groupings. Complexity: Medium (shares infrastructure with List).

---

### 4.12 `UI::NavigationSplitView`

```crystal
class UI::NavigationSplitView < UI::View
  property sidebar : View
  property detail : View
  property sidebar_width : Float64? = nil  # nil = platform default
  property preferred_split_style : NavigationStyle = NavigationStyle::Split
end
```

**Platform divergence:** iOS/iPadOS `UISplitViewController`. macOS `NSSplitViewController`. Android `SlidingPaneLayout` (Jetpack) or drawer pattern. Web two-column CSS layout. Complexity: High.

---

### 4.13 `UI::Toolbar`

```crystal
class UI::Toolbar < UI::View
  property leading_items : Array(View)
  property center_items : Array(View)
  property trailing_items : Array(View)
  property title : String? = nil
end
```

**Platform divergence:** macOS `NSToolbar` is a window decoration, not an embedded view — must be set on `NSWindow`, not added as a subview. iOS `UINavigationItem` has `leftBarButtonItems` / `rightBarButtonItems` added to `UINavigationBar`. Android `androidx.appcompat.widget.Toolbar` is a regular ViewGroup. Web: `<header>` with flex layout. Complexity: High (especially macOS window-level integration).

---

### 4.14 `UI::GlassBackground`

```crystal
class UI::GlassBackground < UI::View
  enum Material
    UltraThin; Thin; Regular; Thick; UltraThick
    Sidebar; Header
  end

  property material : Material = Material::Regular
  property tint_color : Color? = nil
  property fallback_color : Color = Color.new(r: 0.95, g: 0.95, b: 0.95, a: 0.85)
  property content : View? = nil
end
```

**Platform divergence:** iOS/macOS have excellent native glass — `UIVisualEffectView(UIBlurEffect)` and `NSVisualEffectView`. Android: `RenderEffect.createBlurEffect()` (API 31+); use `fallback_color` on older API levels. Web: `backdrop-filter: blur(20px)` + `background: rgba(...)`. Complexity: Medium. The iOS 26 / macOS 26 Liquid Glass API (`UIGlassEffectView`, `NSGlassEffectView`) should be used when available, with fallback to `UIVisualEffectView`.

---

### 4.15 `UI::Sheet`

```crystal
class UI::Sheet
  property content : View
  property detents : Array(Detent)
  property shows_drag_indicator : Bool = true

  enum Detent
    Medium; Large; Custom
  end
end

module UI::SheetPresenter
  abstract def present_sheet(sheet : Sheet, from_view : View? = nil)
  abstract def dismiss_sheet
end
```

Like `Alert`, `Sheet` is not a view-tree node — it is presented imperatively via `SheetPresenter`. iOS `UISheetPresentationController` (iOS 15+) with detents. macOS `NSPanel` beginSheetModal. Android `BottomSheetDialogFragment`. Web: custom overlay with CSS slide-up animation. Complexity: Medium-High.

---

### 4.16 `UI::Popover`

```crystal
class UI::Popover
  property content : View
  property anchor : View         # the view the popover points to
  property preferred_edge : Edge = Edge::Bottom

  enum Edge; Top; Bottom; Leading; Trailing; end
end

module UI::PopoverPresenter
  abstract def present_popover(popover : Popover)
  abstract def dismiss_popover
end
```

**Platform mapping:** macOS `NSPopover`. iOS `UIPopoverPresentationController`. Android `PopupWindow`. Web positioned `<div>`. Complexity: Medium.

---

### 4.17 `UI::ConfirmationDialog`

```crystal
class UI::ConfirmationDialog
  property title : String
  property message : String? = nil
  property actions : Array(UI::Alert::Action)
end
```

Essentially `Alert` with `UIAlertController(style: .actionSheet)` on iOS (appears from bottom on iPhone, as popover on iPad). Same `AlertPresenter` interface. Complexity: Low (shares Alert infrastructure).

---

### 4.18 `UI::Snackbar`

```crystal
class UI::Snackbar
  property message : String
  property action_label : String? = nil
  property action : Proc(Nil)? = nil
  property duration : Duration = Duration::Short

  enum Duration; Short; Long; Indefinite; end
end

module UI::SnackbarPresenter
  abstract def show_snackbar(snackbar : Snackbar)
end
```

**Platform mapping:** Android `com.google.android.material.snackbar.Snackbar` — native and idiomatic. iOS/macOS: custom overlay view anchored at bottom. Web: custom `<div>` with CSS slide-up animation. Complexity: Medium (iOS/macOS require custom implementation).

---

### 4.19 `UI::Card`

```crystal
class UI::Card < UI::View
  property content : View? = nil
  property elevation : Float64 = 4.0
end
```

**Implementation strategy:** On Android, use `com.google.android.material.card.MaterialCardView`. On other platforms, compose from a `VStack`/`ZStack` with `corner_radius`, `shadow_radius`, and `shadow_offset` modifier properties (from Section 2a). The Card class primarily sets these modifier defaults and wraps a content view. Complexity: Low-Medium.

---

### 4.20 `UI::Surface`

```crystal
class UI::Surface < UI::View
  property content : View? = nil
end
```

Analogous to Card but without implied elevation. macOS `NSBox` (titlePosition=none). Other platforms: a `ZStack` with `background` color set. Complexity: Low.

---

### 4.21 `UI::Divider`

```crystal
class UI::Divider < UI::View
  property color : Color? = nil
  property thickness : Float64 = 1.0
  property horizontal : Bool = true
end
```

**Platform mapping:** macOS `NSBox(boxType: .separator)`. iOS `UIView` with height=1 and background color. Android `View` with height=1dp and divider drawable. Web `<hr>` or `<div style="height:1px">`. Complexity: Very Low.

---

### 4.22 `UI::AsyncImage`

```crystal
class UI::AsyncImage < UI::View
  property url : String
  property placeholder : View? = nil
  property error_view : View? = nil
  property content_mode : ContentMode = ContentMode::Fit
end
```

**Platform mapping:** iOS: `UIImageView` + `URLSession` async download with `DispatchQueue.main.async` for UI update. macOS: same pattern. Android: Coil / Glide library via JNI, or `Volley`-style ImageRequest. Web: `<img>` with native lazy loading (`loading="lazy"`). Complexity: High (requires async download management and caching strategy per renderer).

---

### 4.23 `UI::RichText`

```crystal
class UI::RichText < UI::View
  property attributed_text : AttributedString   # Crystal type defined below
end

record UI::AttributedString,
  raw : String,
  spans : Array(TextSpan)

record UI::TextSpan,
  start : Int32,
  length : Int32,
  font : Font? = nil,
  color : Color? = nil,
  background : Color? = nil,
  link : String? = nil
```

**Platform mapping:** iOS/macOS `NSAttributedString`. Android `SpannableString` / `SpannableStringBuilder`. Web inner HTML or `dangerouslySetInnerHTML`-style approach with `<span>` elements per run. Complexity: High (new `AttributedString` type must be designed first).

---

### 4.24 `UI::TextEditor`

```crystal
class UI::TextEditor < UI::View
  property text : String = ""
  property placeholder : String = ""
  property font : Font = Font.new
  property on_change : Proc(String, Nil)? = nil
end
```

**Platform mapping:** iOS `UITextView` (editable, scrollable). macOS `NSTextView` inside `NSScrollView`. Android `EditText` with `inputType=textMultiLine`. Web `<textarea>`. Essentially `TextArea` under a different name with richer future potential (rich text editing). Complexity: Low-Medium.

---

## Section 5: P3 Components — Specialized Third Wave

P3 components are implemented as stub view types that compile across all platforms and render a visible placeholder (e.g., a `Label` saying "[ComponentName not yet implemented]" in debug builds, or an empty view in release builds). Full implementation is deferred to specific project needs.

### P3 Stub Template

```crystal
# Template for each P3 stub view
class UI::ComponentName < UI::View
  # Properties defined for API completeness
  # Renderer implementations return a placeholder or no-op

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

### P3 Component List

| Component | Crystal Class | Primary Properties | Platform Blocker |
|-----------|--------------|-------------------|-----------------|
| Circle | `UI::Circle` | `fill_color`, `stroke_color`, `stroke_width` | Requires platform drawing APIs |
| Rectangle | `UI::Rectangle` | `fill_color`, `stroke_color`, `corner_radius` | Platform drawing; largely covered by `View` + modifiers |
| RoundedRectangle | `UI::RoundedRectangle` | `fill_color`, `corner_radius` | Platform drawing |
| Capsule | `UI::Capsule` | `fill_color`, `stroke_color` | Platform drawing |
| Canvas | `UI::Canvas` | `draw_proc : Proc(DrawContext, Nil)` | Requires `DrawContext` abstraction design |
| Path | `UI::Path` | `commands : Array(PathCommand)` | Requires portable path builder API |
| Map | `UI::Map` | `region`, `annotations`, `map_type` | Requires Apple Maps / Google Maps SDK per platform |
| Chart | `UI::Chart` | `data`, `chart_type`, `axis_config` | No single cross-platform charting library |
| WebView | `UI::WebView` | `url : String`, `allows_navigation : Bool` | `WKWebView` / android.webkit.WebView / `<iframe>` — security implications |
| ColorPicker | `UI::ColorPicker` | `selected_color`, `on_change` | `NSColorPanel` is singleton; iOS 14+; Android no native |
| VideoPlayer | `UI::VideoPlayer` | `url : String`, `auto_play : Bool` | Requires AVFoundation / Media3 per platform |
| Tooltip | `UI::Tooltip` | `content : View`, `tip_text : String` | iOS 17+ only; macOS hover; Android long-press only |

### P3 Renderer Stub Implementation Pattern

```crystal
# In each renderer, P3 view visitors:
def visit(view : UI::Canvas)
  {% if flag?(:debug) %}
    # Render a visible placeholder in debug builds
    visit(UI::Label.new("[Canvas: not yet implemented]"))
  {% end %}
  # In release: no-op, renders nothing
end
```

---

## Section 6: Navigation Architecture Deep Dive

Navigation is the single most platform-divergent UI concept in the system. This section defines the full abstraction before any implementation begins.

### The Problem

| Platform | Navigation Paradigm | Root Container | Back Navigation |
|----------|--------------------|-----------------|----|
| iOS | Push/pop stack; modal presentation | `UINavigationController` | Swipe right or Back button in `UINavigationBar` |
| macOS | Windowed model; no standard push nav | `NSWindowController` / `NSViewController` stack (custom) | Custom back button in toolbar; no system chrome |
| Android | Fragment back stack or Navigation Component | `NavHostFragment` | System back button or gesture; custom `Toolbar` nav icon |
| Web | URL routing + browser history | `<div>` visibility toggle | Browser back button / `history.back()` |

### Route Model

The Crystal navigation model does not use string keys or typed enums — it uses view factory closures. This avoids routing tables and allows type-safe view construction with parameters:

```crystal
# A NavigationRoute is a named factory that produces a View
record UI::NavigationRoute,
  identifier : String,
  factory : Proc(View)

class UI::NavigationStack < UI::View
  # The route registry is held by the NavigationStack
  property routes : Hash(String, Proc(View)) = {} of String => Proc(View)
  property root_view : View
  property title : String? = nil
  property large_title : Bool = false

  def register(route : String, &factory : -> View) : self
  def push(route : String)    # Calls the route factory; hands view to renderer
  def pop
  def pop_to_root

  def accept(visitor : PlatformVisitor)
    visitor.visit(self)
  end
end
```

The renderer (not Crystal) owns the live navigation stack. When `push(route)` is called:
1. Crystal calls the registered factory to produce the new `View`.
2. Crystal calls the renderer's `navigate_push(view, title)` method.
3. The renderer hands the view to the platform native navigation container.

This means `NavigationStack` is both a view type (placed in the view tree) AND a controller object (with `push`/`pop` methods the app calls). This is intentional — it mirrors UINavigationController's dual role.

### Platform Rendering Strategy

#### iOS (UINavigationController)

```crystal
# In UIKit::Renderer
def visit(view : UI::NavigationStack)
  nav_vc = objc_uinavcontroller_alloc_init
  root_vc = create_viewcontroller_for(view.root_view)
  objc_uinavcontroller_set_root(nav_vc, root_vc)

  # Store reference so push/pop can access it
  @active_nav_controller = nav_vc

  # Set up large title if requested
  if view.large_title
    objc_uinavcontroller_set_large_title_mode(nav_vc, 2)  # .always
  end
end

def navigate_push(view : UI::View, title : String? = nil)
  vc = create_viewcontroller_for(view)
  objc_uinavcontroller_push(@active_nav_controller, vc, animated: true)
end
```

#### macOS (Custom NSViewController Stack)

macOS has no `NSNavigationController`. The renderer maintains a `NSView` container and manually swaps views with a crossfade transition:

```crystal
# In AppKit::Renderer
def visit(view : UI::NavigationStack)
  # Create a container NSView that fills the window
  @nav_container = objc_nsview_alloc_init
  @nav_vc_stack = [] of Pointer(Void)  # ObjC id stack

  render_into_container(view.root_view, @nav_container)
end

def navigate_push(view : UI::View, title : String? = nil)
  new_view = render_detached(view)
  @nav_vc_stack.push(@nav_container.current_content)
  objc_nsview_animate_swap(@nav_container, new_view, duration: 0.25)
  # Update toolbar back button
end
```

#### Android (FragmentManager)

```crystal
# In Android::Renderer
def visit(view : UI::NavigationStack)
  @fragment_manager = jni_activity_get_fragment_manager(@activity)
  @container_id = jni_create_framelayout_with_id(@activity, "nav_container")

  root_fragment = create_crystal_fragment_for(view.root_view)
  jni_fragmentmanager_begin_transaction(@fragment_manager)
    .replace(@container_id, root_fragment)
    .commit
end
```

#### Web (History API + Visibility)

```crystal
# In Web::Renderer
def visit(view : UI::NavigationStack)
  # Render all registered routes upfront as hidden <div>s
  # Show/hide via CSS display:none toggle on navigation
  # Push state to window.history on each navigate_push call

  html = %(<div class="ui-nav-stack" data-current="root">)
  html += %(<div class="ui-nav-screen" data-route="root" style="display:block">)
  html += render_view(view.root_view)
  html += %(</div>)
  html += %(</div>)
end
```

### TabView Architecture

TabView is simpler than NavigationStack but still requires per-platform consideration:

```crystal
# TabView rendering creates the native tab container and
# passes each tab's content view to the appropriate slot.

# iOS: UITabBarController receives one UIViewController per tab.
# Each VC's view is the rendered Crystal tab content.

# macOS: NSTabViewController with one NSTabViewItem per tab.
# Item label set from Tab.label; NSImage from Tab.icon.

# Android: BottomNavigationView (for navigation-style tabs) OR
# TabLayout + ViewPager2 (for content tabs). Default: BottomNavigationView.
# Each tab content is a Fragment.

# Web: <nav role="tablist"> with <button role="tab"> elements.
# Associated <div role="tabpanel"> elements, one visible at a time.
# Keyboard navigation via aria-selected, tabindex.
```

---

## Section 7: Theme System Design

The theme system provides semantic color roles and typography scales, allowing app code to reference `theme.primary` instead of hardcoded `Color.new(r: 0.0, g: 0.478, b: 1.0)`. This enables dark mode support and easy branding changes.

### Crystal Theme Definition

Based on Material Design 3's 26 semantic color roles (the most comprehensive cross-platform system):

```crystal
# src/ui/theme.cr

class UI::Theme
  # Primary colors
  property primary : Color
  property on_primary : Color
  property primary_container : Color
  property on_primary_container : Color

  # Secondary colors
  property secondary : Color
  property on_secondary : Color
  property secondary_container : Color
  property on_secondary_container : Color

  # Tertiary colors
  property tertiary : Color
  property on_tertiary : Color
  property tertiary_container : Color
  property on_tertiary_container : Color

  # Error colors
  property error : Color
  property on_error : Color
  property error_container : Color
  property on_error_container : Color

  # Background and surface
  property background : Color
  property on_background : Color
  property surface : Color
  property on_surface : Color
  property surface_variant : Color
  property on_surface_variant : Color
  property surface_container : Color
  property inverse_surface : Color
  property inverse_on_surface : Color

  # Utility
  property outline : Color
  property outline_variant : Color
  property shadow : Color
  property scrim : Color

  # Typography
  property typography : Typography

  # Shape
  property shape : ShapeTheme

  # Factory: Apple HIG system colors (sensible defaults for Apple-first apps)
  def self.apple_default : Theme

  # Factory: Material 3 baseline (Google's default M3 palette)
  def self.material_baseline : Theme

  # Apply this theme to all views within a block
  def apply(&block : -> View) : View
end

record UI::Typography,
  display_large : Font = Font.new(size: 57.0, weight: :regular),
  display_medium : Font = Font.new(size: 45.0, weight: :regular),
  display_small : Font = Font.new(size: 36.0, weight: :regular),
  headline_large : Font = Font.new(size: 32.0, weight: :regular),
  headline_medium : Font = Font.new(size: 28.0, weight: :regular),
  headline_small : Font = Font.new(size: 24.0, weight: :regular),
  title_large : Font = Font.new(size: 22.0, weight: :regular),
  title_medium : Font = Font.new(size: 16.0, weight: :medium),
  title_small : Font = Font.new(size: 14.0, weight: :medium),
  body_large : Font = Font.new(size: 16.0, weight: :regular),
  body_medium : Font = Font.new(size: 14.0, weight: :regular),
  body_small : Font = Font.new(size: 12.0, weight: :regular),
  label_large : Font = Font.new(size: 14.0, weight: :medium),
  label_medium : Font = Font.new(size: 12.0, weight: :medium),
  label_small : Font = Font.new(size: 11.0, weight: :medium)

record UI::ShapeTheme,
  extra_small : Float64 = 4.0,    # corner radius for small controls
  small : Float64 = 8.0,
  medium : Float64 = 12.0,
  large : Float64 = 16.0,
  extra_large : Float64 = 28.0,
  full : Float64 = 9999.0          # capsule/pill shape
```

### How the Theme Flows to Renderers

The theme is a global-per-build-tree value, not an environment variable. Views do not hold theme references; instead, the renderer has access to the theme when it visits each view and applies themed defaults for unset properties:

```crystal
# In each renderer — apply theme defaults before view-specific overrides
def apply_themed_defaults(view : UI::View, theme : UI::Theme)
  view.background ||= theme.surface  # only if not explicitly set
end
```

**Web Renderer:** Emit CSS custom properties at the root level on first render:

```html
<style>
  :root {
    --ui-primary: rgba(0, 122, 255, 1.0);
    --ui-on-primary: rgba(255, 255, 255, 1.0);
    --ui-surface: rgba(255, 255, 255, 1.0);
    /* ... all 26 roles ... */
    --ui-font-body-large: 16px system-ui;
  }
</style>
```

Components then use `var(--ui-primary)` in generated CSS, enabling runtime theme switching without re-rendering.

**iOS/macOS Renderers:** Apply `UIColor`/`NSColor` instances derived from the theme to each native view's `tintColor`, `backgroundColor`, etc. For system components that respond to the system accent color, check if the theme primary matches the system accent and prefer `UIColor.systemBlue` / `.systemTeal` when appropriate.

**Android Renderer:** Apply Material You / dynamic color by creating a `ColorScheme` from the theme's primary color using `MaterialColors.harmonize()` and passing it to `MaterialComponents` via a custom `MaterialTheme.ColorScheme`.

---

## Section 8: ObjC Bridge Expansion Plan

All new C wrappers are added to `objc_bridge.c`. Each function uses the ARM64 AAPCS64 calling convention. Float64 arguments go in D-registers; integer/pointer arguments go in X-registers. All wrapped to avoid register corruption through `objc_msgSend`.

### New ObjC Bridge Functions for P1 Components

**Toggle / Switch:**
```c
id   objc_uiswitch_create(void);
void objc_uiswitch_set_on(id sw, BOOL on);
BOOL objc_uiswitch_get_on(id sw);
void objc_uiswitch_add_target(id sw, long callback_id);
// AppKit:
id   objc_nsbutton_create_switch(const char *title);
void objc_nsbutton_set_state(id btn, int state);  // NSControlStateValue
int  objc_nsbutton_get_state(id btn);
```

**Slider:**
```c
id   objc_uislider_create(void);
void objc_uislider_set_min(id sl, double min);
void objc_uislider_set_max(id sl, double max);
void objc_uislider_set_value(id sl, double value);
void objc_uislider_set_tint(id sl, double r, double g, double b, double a);
void objc_uislider_add_target(id sl, long callback_id);
// AppKit:
id   objc_nsslider_create(void);
void objc_nsslider_configure(id sl, double min, double max, double value, int ticks);
void objc_nsslider_add_target(id sl, long callback_id);
```

**Progress Indicators:**
```c
id   objc_uiprogressview_create(int style);  // 0=default, 1=bar
void objc_uiprogressview_set_progress(id pv, double value);
void objc_uiprogressview_set_tint(id pv, double r, double g, double b, double a);
id   objc_uiactivityindicator_create(int style);  // 0=medium, 1=large
void objc_uiactivityindicator_start(id ai);
void objc_uiactivityindicator_stop(id ai);
// Both share NSProgressIndicator on AppKit:
id   objc_nsprogressindicator_create_bar(void);
id   objc_nsprogressindicator_create_spinner(void);
void objc_nsprogressindicator_set_value(id pi, double value);
void objc_nsprogressindicator_start(id pi);
void objc_nsprogressindicator_stop(id pi);
```

**Navigation (UIKit):**
```c
id   objc_uinavcontroller_alloc_init(void);
void objc_uinavcontroller_set_root_vc(id nav, id vc);
void objc_uinavcontroller_push_vc(id nav, id vc, BOOL animated);
void objc_uinavcontroller_pop_vc(id nav, BOOL animated);
void objc_uinavcontroller_set_nav_bar_large_title(id nav, int mode);
id   objc_uiviewcontroller_alloc_init(void);
void objc_uiviewcontroller_set_title(id vc, const char *title);
void objc_uiviewcontroller_set_view(id vc, id view);
```

**Tab Bar (UIKit):**
```c
id   objc_uitabbarcontroller_alloc_init(void);
void objc_uitabbarcontroller_set_viewcontrollers(id tbc, id *vcs, int count);
id   objc_uitabbaritem_create(const char *title, const char *image_name, int tag);
void objc_uiviewcontroller_set_tabbaritem(id vc, id item);
```

**Alert (UIKit + AppKit):**
```c
id   objc_uialertcontroller_create(const char *title, const char *message, int style);
void objc_uialertcontroller_add_action(id ac, const char *title, int style, long callback_id);
void objc_uiviewcontroller_present(id presenting, id presented, BOOL animated);
id   objc_nsalert_create(void);
void objc_nsalert_set_title(id alert, const char *title);
void objc_nsalert_set_message(id alert, const char *message);
long objc_nsalert_add_button(id alert, const char *title);
int  objc_nsalert_run_modal(id alert);  // returns button index
```

**NSButton setButtonType (Checkbox, RadioButton):**
```c
void objc_nsbutton_set_button_type(id btn, int button_type);
// button_type: 3=NSSwitchButton(checkbox), 4=NSRadioButton, 6=NSPushOnPushOff
```

**NSTabViewController (AppKit tabs):**
```c
id   objc_nstabviewcontroller_alloc_init(void);
void objc_nstabviewcontroller_set_style(id tvc, int style);  // 0=automatic, 1=unboxed, etc.
id   objc_nstabviewitem_create(const char *label);
void objc_nstabviewitem_set_viewcontroller(id item, id vc);
void objc_nstabviewcontroller_add_tab(id tvc, id item);
```

### Typed Callback Dispatch (ObjC Side)

The `CrystalActionDispatcher` ObjC class must be extended to handle typed callbacks:

```c
// New selectors added to CrystalActionDispatcher:
// crystalBoolAction_<id>:     — for Toggle, Checkbox
// crystalFloatAction_<id>:    — for Slider, Stepper
// crystalIntAction_<id>:      — for Picker, TabView, SegmentedControl

// New C entry points called by dispatcher:
void crystal_ui_dispatch_bool(long id, int bool_value);
void crystal_ui_dispatch_float(long id, double float_value);
void crystal_ui_dispatch_int(long id, int int_value);
```

---

## Section 9: JNI Bridge Expansion Plan

All new JNI functions are added to `jni_bridge.c`. The `JNIEnv*` is always the first parameter. Class and method IDs are cached at initialization using `(*env)->FindClass` / `(*env)->GetMethodID` patterns already established in the bridge.

### New JNI Bridge Functions for P1 Components

**Toggle / Switch:**
```c
jobject jni_switchmaterial_create(JNIEnv *env, jobject context);
void    jni_switchmaterial_set_checked(JNIEnv *env, jobject sw, jboolean checked);
void    jni_switchmaterial_set_text(JNIEnv *env, jobject sw, const char *text);
void    jni_switch_set_onchange(JNIEnv *env, jobject sw, jlong callback_id);
```

**Checkbox:**
```c
jobject jni_checkbox_create(JNIEnv *env, jobject context);
void    jni_checkbox_set_checked(JNIEnv *env, jobject cb, jboolean checked);
void    jni_checkbox_set_text(JNIEnv *env, jobject cb, const char *text);
// Reuse jni_switch_set_onchange for OnCheckedChangeListener
```

**RadioButton + RadioGroup:**
```c
jobject jni_radiogroup_create(JNIEnv *env, jobject context);
jobject jni_radiobutton_create(JNIEnv *env, jobject context, const char *text);
int     jni_radiogroup_add_button(JNIEnv *env, jobject group, jobject button);
void    jni_radiogroup_set_onchange(JNIEnv *env, jobject group, jlong callback_id, const char *values_json);
// values_json: JSON array of string values corresponding to button IDs
```

**Slider:**
```c
jobject jni_slider_create(JNIEnv *env, jobject context);
void    jni_slider_configure(JNIEnv *env, jobject sl, jfloat from, jfloat to, jfloat value, jfloat step);
void    jni_slider_set_onchange(JNIEnv *env, jobject sl, jlong callback_id);
```

**Progress Indicators:**
```c
jobject jni_progressbar_horizontal_create(JNIEnv *env, jobject context);
void    jni_progressbar_set_progress(JNIEnv *env, jobject pb, int progress, int max);
jobject jni_progressbar_circular_create(JNIEnv *env, jobject context);
// Circular is already indeterminate by default; no extra configuration needed
```

**Navigation (Fragments):**
```c
jobject jni_fragmentmanager_get(JNIEnv *env, jobject activity);
void    jni_fragmentmanager_push(JNIEnv *env, jobject fm, jobject fragment, const char *tag, int container_id);
void    jni_fragmentmanager_pop(JNIEnv *env, jobject fm);
jobject jni_framelayout_create_with_id(JNIEnv *env, jobject context, int view_id);
```

**TabView:**
```c
jobject jni_bottomnavview_create(JNIEnv *env, jobject context);
void    jni_bottomnavview_add_item(JNIEnv *env, jobject nav, int item_id, const char *title, const char *icon_name);
void    jni_bottomnavview_set_onitemselected(JNIEnv *env, jobject nav, jlong callback_id);
void    jni_bottomnavview_set_selected(JNIEnv *env, jobject nav, int item_id);
```

**Alert:**
```c
jobject jni_alertdialog_create(JNIEnv *env, jobject context, const char *title, const char *message);
void    jni_alertdialog_set_positive_button(JNIEnv *env, jobject dialog, const char *text, jlong callback_id);
void    jni_alertdialog_set_negative_button(JNIEnv *env, jobject dialog, const char *text, jlong callback_id);
void    jni_alertdialog_set_neutral_button(JNIEnv *env, jobject dialog, const char *text, jlong callback_id);
void    jni_alertdialog_show(JNIEnv *env, jobject dialog);
void    jni_alertdialog_dismiss(JNIEnv *env, jobject dialog);
```

**Picker (Spinner):**
```c
jobject jni_spinner_create(JNIEnv *env, jobject context);
void    jni_spinner_set_items(JNIEnv *env, jobject spinner, const char *items_json);
void    jni_spinner_set_selection(JNIEnv *env, jobject spinner, int index);
void    jni_spinner_set_onitemselected(JNIEnv *env, jobject spinner, jlong callback_id);
```

**Typed Callback Dispatch (JNI Side):**

```java
// CrystalCallbackBridge.java — new static native methods
public class CrystalCallbackBridge {
  public static native void dispatch(long callbackId);           // existing: Proc(Nil)
  public static native void dispatchString(long id, String val); // existing: Proc(String, Nil)
  public static native void dispatchBool(long id, boolean val);  // new: Proc(Bool, Nil)
  public static native void dispatchFloat(long id, double val);  // new: Proc(Float64, Nil)
  public static native void dispatchInt(long id, int val);       // new: Proc(Int32, Nil)
  public static native void dispatchLong(long id, long val);     // new: Proc(Time, Nil) — epoch seconds
}
```

Crystal-side JNI implementation calls into `crystal_ui_dispatch_*` functions.

---

## Section 10: Web Renderer Expansion Plan

The web renderer emits HTML + inline CSS and uses `data-action` attributes for reactive event dispatch through the existing `ReactiveHandler` WebSocket system. All new components follow this pattern.

### P1 Component HTML Mappings

| Component | HTML Element | CSS Strategy | Event |
|-----------|-------------|-------------|-------|
| `Toggle` | `<label class="ui-toggle"><input type="checkbox" role="switch"><span class="ui-toggle-track"></span></label>` | CSS custom checkbox pill styling. `transition: background 0.2s` | `data-action="change->dispatch#boolChange"` |
| `Checkbox` | `<label><input type="checkbox"> Label text</label>` | Native appearance. `accent-color: var(--ui-primary)`. | `data-action="change->dispatch#boolChange"` |
| `RadioButton` | `<fieldset class="ui-radio-group"><legend>...</legend> <label><input type="radio" name="grpX" value="V"> Label</label> ...</fieldset>` | Native. `accent-color`. | `data-action="change->dispatch#stringChange"` on each input |
| `Slider` | `<input type="range" min="X" max="Y" step="Z" value="V">` | `accent-color: var(--ui-primary)`. `width: 100%`. | `data-action="input->dispatch#floatChange"` |
| `SecureField` | `<input type="password" placeholder="P">` | Identical to TextField password mode (already implemented) | `data-action="input->dispatch#stringChange"` |
| `Picker` | `<select class="ui-picker">` + `<option value="X">` per item | `appearance: none`. Custom arrow via CSS. Border from theme. | `data-action="change->dispatch#intChange"` |
| `IconButton` | `<button class="ui-icon-btn" aria-label="label"><img src="icon" alt="">` or SVG inline | `background: transparent; border: none; cursor: pointer` | `data-action="click->dispatch#tap"` |
| `ProgressBar` | `<progress class="ui-progress" value="X" max="1">` | `accent-color: var(--ui-primary)`. Width 100% by default. | None (display only) |
| `ActivityIndicator` | `<div class="ui-spinner" aria-label="Loading" role="status"><div></div></div>` | CSS `@keyframes` rotation. `border-radius: 50%`. Border with transparent bottom. | None (display only) |
| `Alert` | `<dialog class="ui-alert" role="alertdialog" aria-modal="true"><h2>Title</h2><p>Message</p><div class="ui-alert-actions">...</div></dialog>` | Position centered with `::backdrop` overlay. `animation` for entrance. | `data-action` on each action button |
| `List` | `<ul class="ui-list" role="list">` with `<li>` children | `list-style: none`. `border-bottom: 1px solid var(--ui-outline-variant)` for separators. | `data-action="click->dispatch#intChange"` on `<li>` for row tap |
| `NavigationStack` | Root: `<div class="ui-nav-stack">`. Screens: `<div class="ui-screen" data-route="X" hidden>` | `display: none` / `display: block` toggle. Slide transition via CSS `@keyframes` | JS `history.pushState` + `popstate` listener |
| `NavigationLink` | `<a href="#" class="ui-nav-link" data-route="X">Label</a>` | Link appearance or button appearance. | `onclick` intercepts, calls `history.pushState`, toggles screen visibility |
| `TabView` | `<div role="tablist">` with `<button role="tab" aria-selected>` elements + `<div role="tabpanel">` per tab | Tab bar at bottom (mobile) or top (desktop) via CSS. Active tab indicator. | `data-action="click->dispatch#intChange"` on tab buttons |

### Web Renderer CSS Injection

The web renderer should inject a `<style>` block on first render containing:
1. All `--ui-*` CSS custom property definitions from the active theme
2. Base styles for all UI component classes (`.ui-toggle`, `.ui-spinner`, `.ui-alert`, etc.)
3. CSS animation keyframes for spinner, alert entrance, navigation transitions

This keeps inline styles minimal — only dynamic values (colors from view properties, specific sizes) go inline.

---

## Section 11: Testing Strategy

### 11.1 Unit Specs for Each New View Type

Create `spec/ui/views/component_name_spec.cr` for each new view. Every spec must cover:

```crystal
describe UI::ComponentName do
  describe "construction" do
    it "initializes with defaults" do
      view = UI::ComponentName.new(...)
      view.property.should eq(expected_default)
    end

    it "accepts required parameters" do
      view = UI::ComponentName.new(required_arg: "value")
      view.required_arg.should eq("value")
    end
  end

  describe "base view properties" do
    it "inherits padding, background, hidden, opacity from UI::View" do
      view = UI::ComponentName.new(...)
      view.padding = UI::EdgeInsets.new(top: 8.0)
      view.background = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)
      view.hidden = true
      view.opacity = 0.5
      view.padding.top.should eq(8.0)
      view.background.not_nil!.r.should eq(1.0)
      view.hidden.should be_true
      view.opacity.should eq(0.5)
    end
  end

  describe "accept(visitor)" do
    it "dispatches to visitor.visit(self)" do
      view = UI::ComponentName.new(...)
      visitor = MockVisitor.new
      view.accept(visitor)
      visitor.visited_component_name.should be_true
    end
  end

  describe "web renderer output" do
    it "emits correct HTML structure" do
      view = UI::ComponentName.new(...)
      renderer = UI::Web::Renderer.new
      view.accept(renderer)
      output = renderer.output
      output.should contain(expected_html_element)
    end

    it "applies data-action for interactive components" do
      view = UI::Toggle.new("Dark Mode")
      view.on_change = ->(v : Bool) { nil }
      # verify data-action attribute present
    end
  end
end
```

### 11.2 Web Renderer Snapshot Tests

For HTML-emitting views, add snapshot tests that compare rendered output against stored HTML fixtures. Store expected HTML in `spec/fixtures/web/component_name.html`. The test verifies the rendered output matches the fixture, failing loudly on unintentional HTML changes.

### 11.3 Integration Test — macOS Demo App

Expand the existing `samples/cross_platform/macos_app.cr` demo to include every new P1 and P2 view type in a scrollable showcase. The demo should:

1. Render all Selection Controls in one section (Toggle, Checkbox, RadioButton, Slider)
2. Show a NavigationStack with 2 levels of push depth
3. Show a TabView with 3 tabs
4. Display ProgressBar at 0.3, 0.6, 1.0 and an AnimatingActivityIndicator
5. Show a List with 10 rows, each with a label and an icon
6. Show a Picker with 5 options
7. Trigger an Alert via a button tap

Build command:
```bash
crystal build samples/cross_platform/macos_app.cr -Dmacos -o samples/cross_platform/build/macos_demo
./samples/cross_platform/build/macos_demo
```

### 11.4 Cross-Compilation Smoke Tests

For every new view type added to `PlatformVisitor`, verify that iOS and Android cross-compilation succeeds without errors. These do not need to run; they just need to link:

```bash
# iOS compile check
crystal build samples/cross_platform/macos_app.cr \
  --target aarch64-apple-ios --cross-compile \
  -Dwithout_openssl -Dwithout_xml \
  -o /tmp/ios_smoke_check.o

# Android compile check
crystal build samples/cross_platform/macos_app.cr \
  --target aarch64-linux-android --cross-compile \
  --shared -Dwithout_openssl -Dwithout_xml \
  -o /tmp/android_smoke_check.o
```

Both are added as CI steps after each milestone.

### 11.5 Accessibility Verification

For each new interactive view type:
- Verify `accessibility_label` is wired to the native accessibility API:
  - iOS/macOS: `setAccessibilityLabel:`
  - Android: `setContentDescription()`
  - Web: `aria-label` attribute
- Run macOS VoiceOver manually on the demo app after each milestone to catch regressions.

---

## Section 12: Milestone Schedule

### Milestone A — Infrastructure (Prerequisites)

**Owner:** Any
**Estimated effort:** 3–5 days
**Dependencies:** None (start here)

**Deliverables:**
1. `UI::View` base class gains 12 new modifier properties (Section 2a) — all renderers updated to apply them in `apply_common_properties` helper
2. New enums added to `src/ui/enums.cr` (Section 2b) — all 7 enum types
3. `UI::CallbackRegistry` expanded with `Proc(Bool, Nil)`, `Proc(Float64, Nil)`, `Proc(Int32, Nil)`, `Proc(Time, Nil)` types (Section 2c)
4. `crystal_ui_dispatch_bool`, `crystal_ui_dispatch_float`, `crystal_ui_dispatch_int`, `crystal_ui_dispatch_time` added to `objc_bridge.c` and `jni_bridge.c`
5. `CrystalCallbackBridge.java` updated with new `static native` methods
6. `UI::Size` value type added
7. `UI::AlertPresenter`, `UI::SheetPresenter`, `UI::PopoverPresenter`, `UI::SnackbarPresenter` modules defined (empty abstract interfaces for now)
8. All existing specs pass. New modifier property specs added.

**Completion check:** `crystal spec` passes. iOS and Android cross-compilation smoke checks pass. The macOS demo app window opens (no new views yet).

---

### Milestone B — Selection Controls (P1 Batch 1)

**Owner:** Any
**Estimated effort:** 5–7 days
**Dependencies:** Milestone A (CallbackRegistry bool/float types)

**Deliverables:**
1. `UI::Toggle` — all 4 renderers, specs, demo integration
2. `UI::Checkbox` — all 4 renderers, specs, demo integration
3. `UI::RadioButton` + `UI::RadioGroup` — all 4 renderers, specs, demo integration
4. `UI::Slider` — all 4 renderers, specs, demo integration
5. ObjC bridge: `objc_uiswitch_*`, `objc_nsbutton_create_switch`, `objc_nsbutton_set_state`, `objc_uislider_*`, `objc_nsslider_*` wrappers
6. JNI bridge: `jni_switchmaterial_*`, `jni_checkbox_*`, `jni_radiogroup_*`, `jni_slider_*` wrappers
7. Web renderer: CSS pill toggle, native checkbox and radio, range input

**Completion check:** Demo app shows all 4 controls working on macOS. Callbacks print to stdout. Specs pass. Cross-compile smoke checks pass.

---

### Milestone C — Navigation (P1 Batch 2)

**Owner:** Any (ideally the same developer, as navigation state is complex)
**Estimated effort:** 8–12 days
**Dependencies:** Milestone A

**Deliverables:**
1. `UI::NavigationStack` — all 4 renderers, `push`/`pop` working on macOS and Web
2. `UI::NavigationLink` — all 4 renderers
3. `UI::TabView` — all 4 renderers, specs, demo integration
4. ObjC bridge: all `objc_uinavcontroller_*`, `objc_uitabbarcontroller_*`, `objc_nstabviewcontroller_*` wrappers
5. JNI bridge: all `jni_fragmentmanager_*`, `jni_bottomnavview_*` wrappers
6. Web renderer: History API navigation, tab panel pattern with aria roles
7. Navigation deep-dive design doc finalized and agreed before coding starts (see Section 6)

**Completion check:** macOS demo shows a NavigationStack with push/pop working. TabView shows 3 tabs with content. Web demo navigates between screens using history API. Specs pass. Cross-compile smoke checks pass.

---

### Milestone D — Feedback and Input (P1 Batch 3 + 4)

**Owner:** Any
**Estimated effort:** 6–9 days
**Dependencies:** Milestone A (CallbackRegistry int/float types), Milestone C (NavigationStack needed for AlertPresenter context)

**Deliverables:**
1. `UI::ProgressBar` — all 4 renderers, specs
2. `UI::ActivityIndicator` — all 4 renderers, specs
3. `UI::Alert` + `AlertPresenter` — all 4 renderers, imperative presentation API, specs
4. `UI::SecureField` — all 4 renderers, specs
5. `UI::Picker` — all 4 renderers, specs
6. `UI::IconButton` — all 4 renderers, specs
7. `UI::List` (non-virtualized) — all 4 renderers, specs
8. ObjC bridge: all progress, alert, picker, icon button wrappers
9. JNI bridge: all progress, alert, spinner, image button wrappers

**Completion check:** All 14 P1 components are implemented and working on macOS. Demo shows the full P1 showcase. Web demo renders all P1 components as valid HTML. Cross-compile smoke checks pass.

**Milestone D completion = All P1 components done. Update matrix: all 14 P1 rows marked P0.**

---

### Milestone E — P2 Wave 1

**Owner:** Any
**Estimated effort:** 7–10 days
**Dependencies:** Milestone A, Milestone D (List infrastructure reused by Form)

**Deliverables:**
1. `UI::Stepper` — all 4 renderers (Android: composed from primitives)
2. `UI::SegmentedControl` — all 4 renderers
3. `UI::DatePicker` — all 4 renderers (needs `Proc(Time, Nil)` from Milestone A)
4. `UI::TimePicker` — all 4 renderers
5. `UI::SearchField` — all 4 renderers
6. `UI::TextArea` — all 4 renderers
7. `UI::Grid` — all 4 renderers (highest complexity in this milestone)
8. `UI::Form` — all 4 renderers (reuses List infrastructure)

**Completion check:** 8 new P2 components implemented. Demo expanded with P2 Wave 1 showcase section. Cross-compile smoke checks pass.

---

### Milestone F — P2 Wave 2

**Owner:** Any
**Estimated effort:** 10–14 days
**Dependencies:** Milestone C (NavigationSplitView requires NavigationStack patterns), Milestone B (GlassBackground needs modifier system)

**Deliverables:**
1. `UI::NavigationSplitView` — all 4 renderers
2. `UI::Toolbar` — all 4 renderers (macOS window-level NSToolbar is the hard part)
3. `UI::Sheet` + `SheetPresenter` — all 4 renderers
4. `UI::Popover` + `PopoverPresenter` — all 4 renderers
5. `UI::ConfirmationDialog` — all 4 renderers (shares Alert infrastructure)
6. `UI::Snackbar` + `SnackbarPresenter` — all 4 renderers
7. `UI::Card` — all 4 renderers (Android MaterialCardView + modifier composition on others)
8. `UI::Surface` — all 4 renderers
9. `UI::Divider` — all 4 renderers
10. `UI::GlassBackground` — all 4 renderers (iOS 26 UIGlassEffectView, macOS 26 NSGlassEffectView, Android fallback, Web backdrop-filter)
11. Shadow modifier properties applied by all renderers (from Section 2a — enabled in Milestone A, rendered in this milestone for all views)
12. Blur modifier properties applied by all renderers

**Completion check:** 12 new P2 components implemented. Visual effects (glass, shadow, blur) visible in macOS demo. Modal sheets and popovers work. Cross-compile smoke checks pass.

---

### Milestone G — P2 Wave 3 + P3 Stubs

**Owner:** Any
**Estimated effort:** 8–12 days
**Dependencies:** Milestones D, E, F complete (all foundation in place)

**Deliverables:**
1. `UI::AsyncImage` — all 4 renderers (requires async download + placeholder)
2. `UI::RichText` — all 4 renderers (requires `AttributedString` type)
3. `UI::LinkButton` — all 4 renderers
4. `UI::MenuButton` — all 4 renderers
5. `UI::ToggleButton` — all 4 renderers
6. `UI::TextEditor` — all 4 renderers
7. **P3 stubs** (all 12): Circle, Rectangle, RoundedRectangle, Capsule, Canvas, Path, Map, Chart, WebView, ColorPicker, VideoPlayer, Tooltip
8. `UI::Theme` class with `apple_default` and `material_baseline` factory methods
9. CSS custom property injection in Web renderer
10. Component mapping matrix updated: all P1 + P2 rows marked P0; P3 rows show stub status

**Completion check:** All P1 (14) and P2 (25) components implemented. P3 stubs (12) compile without errors, render empty or placeholder. Theme system injects CSS properties on Web. Cross-compile smoke checks pass for all new types.

---

## Section 13: Dependency Graph

```
Milestone A (Infrastructure — no dependencies, start here)
    |
    +----> Milestone B (Selection Controls)
    |          |
    |          +----> Milestone D (Feedback & Input — B provides callback patterns)
    |
    +----> Milestone C (Navigation — independent of B)
    |          |
    |          +----> Milestone F (P2 Wave 2 — NavigationSplitView, Toolbar depend on C)
    |          |
    |          +----> Milestone D (Alert needs NavigationStack context for presentation)
    |
    +----> Milestone E (P2 Wave 1 — Stepper, SegmentedControl, SearchField independent of B/C)
               |
               +----> Milestone F (partial — some P2 Wave 2 views depend on Grid/Form from E)

Milestone D + Milestone E + Milestone F (all complete)
    |
    +----> Milestone G (P2 Wave 3 + P3 Stubs — all foundations in place)
```

**Parallelism opportunities:**
- Milestones B and C can be worked in parallel by different developers (no shared state).
- Milestone E can begin as soon as Milestone A is complete (does not need B or C).
- Milestones D requires A (for callback types) and ideally C (for AlertPresenter), but Progress/ActivityIndicator/SecureField/Picker/IconButton/List within D do not need C and can start after A+B.

**Critical path:** A → C → D (Alert portion) → G. Navigation is the longest path; prioritize it.

---

## Section 14: Success Criteria

The expansion is complete when ALL of the following are true:

### Functional Completeness
1. All 14 P1 components are implemented with correct behavior on all 4 renderers (Web, AppKit, UIKit, Android).
2. All 25 P2 components are implemented with correct behavior on all 4 renderers.
3. All 12 P3 components have stub class definitions that compile without errors on all 4 renderers and render a placeholder or empty content.

### Navigation
4. `NavigationStack` supports at least 3 levels of push depth on iOS (UINavigationController) and macOS (custom stack).
5. `TabView` renders a bottom tab bar on iOS and Web with correct content switching.
6. `NavigationLink` correctly triggers push navigation when tapped.

### Theme System
7. `UI::Theme` is defined with all 26 M3 semantic color roles.
8. The Web renderer injects CSS custom properties for the active theme on first render.
9. `Theme.apple_default` and `Theme.material_baseline` factory methods exist and return valid themes.

### Quality
10. All Crystal specs pass: `crystal spec` exits 0.
11. macOS demo app (`samples/cross_platform/macos_app.cr`) builds and opens a window showing all P1 and P2 view types in an organized showcase.
12. iOS cross-compilation smoke check succeeds (object file produced without errors).
13. Android cross-compilation smoke check succeeds (shared object produced without errors).

### Accessibility
14. Every new interactive view type sets `accessibility_label` / `aria-label` / `contentDescription` on its native control.
15. VoiceOver manual testing on the macOS demo app shows no silent interactive controls (every button, toggle, slider, picker, tab, and list row is reachable and labeled).

### Documentation
16. The component mapping matrix (`skills/component-mapping-matrix/SKILL.md`) is updated with all completed components moved from P1/P2/P3 to P0.
17. The `skills/component-api/SKILL.md` reference is updated with API documentation for all new view types.
18. The `skills/platform-renderers/SKILL.md` view-to-native mapping table is updated.

---

## Appendix A: File Locations Reference

| File | Purpose |
|------|---------|
| `src/ui/view.cr` | Abstract base class — add modifier properties here |
| `src/ui/enums.cr` | All shared enums — add new ones here |
| `src/ui/platform_visitor.cr` | Abstract visitor — add `visit(view : NewView)` for each new type |
| `src/ui/callback_registry.cr` | Callback dispatch — add new typed proc registrations |
| `src/ui/views/toggle.cr` | `UI::Toggle` class |
| `src/ui/views/checkbox.cr` | `UI::Checkbox` class |
| `src/ui/views/radio_button.cr` | `UI::RadioButton` + `UI::RadioGroup` |
| `src/ui/views/slider.cr` | `UI::Slider` class |
| `src/ui/views/navigation_stack.cr` | `UI::NavigationStack` class |
| `src/ui/views/navigation_link.cr` | `UI::NavigationLink` class |
| `src/ui/views/tab_view.cr` | `UI::TabView` class |
| `src/ui/views/progress_bar.cr` | `UI::ProgressBar` class |
| `src/ui/views/activity_indicator.cr` | `UI::ActivityIndicator` class |
| `src/ui/views/alert.cr` | `UI::Alert` + `UI::AlertPresenter` |
| `src/ui/views/secure_field.cr` | `UI::SecureField` class |
| `src/ui/views/picker.cr` | `UI::Picker` class |
| `src/ui/views/icon_button.cr` | `UI::IconButton` class |
| `src/ui/views/list.cr` | `UI::List` class |
| `src/ui/theme.cr` | `UI::Theme` + `UI::Typography` + `UI::ShapeTheme` |
| `src/ui/renderers/web_renderer.cr` | Web renderer — add `visit` methods here |
| `src/ui/renderers/appkit_renderer.cr` | macOS renderer — add `visit` methods here |
| `src/ui/renderers/uikit_renderer.cr` | iOS renderer — add `visit` methods here |
| `src/ui/renderers/android_renderer.cr` | Android renderer — add `visit` methods here |
| `src/ui/native/objc_bridge.c` | ObjC C wrappers — add new functions here |
| `src/ui/native/jni_bridge.c` | JNI C wrappers — add new functions here |
| `spec/ui/views/` | One spec file per view type |
| `samples/cross_platform/macos_app.cr` | macOS demo app — expand for each milestone |

---

## Appendix B: Platform API Quick Reference

### UIKit — Key Classes for P1 Components

| Component | UIKit Class | Availability |
|-----------|------------|-------------|
| Toggle | `UISwitch` | iOS 2.0+ |
| Checkbox | `UIButton` (custom) + SF Symbols | iOS 13+ (SF Symbols) |
| RadioButton | `UIButton` (custom) | iOS 2.0+ |
| Slider | `UISlider` | iOS 2.0+ |
| NavigationStack | `UINavigationController` | iOS 2.0+ |
| TabView | `UITabBarController` | iOS 2.0+ |
| ProgressBar | `UIProgressView` | iOS 2.0+ |
| ActivityIndicator | `UIActivityIndicatorView` | iOS 2.0+ |
| Alert | `UIAlertController` | iOS 8.0+ |
| Picker | `UIPickerView` / `UIButton+UIMenu` | iOS 14+ for menu |
| IconButton | `UIButton` with image | iOS 2.0+ |
| List | `UITableView` | iOS 2.0+ |

### AppKit — Key Classes for P1 Components

| Component | AppKit Class | Notes |
|-----------|-------------|-------|
| Toggle | `NSButton` (buttonType=switch) / macOS 14+ `NSSwitch` | Check OS version |
| Checkbox | `NSButton` (buttonType=check, type 3) | Native |
| RadioButton | `NSButton` (buttonType=radio, type 4) | Native |
| Slider | `NSSlider` | `sliderType: linear` |
| NavigationStack | Custom `NSView` + `NSViewController` stack | No native equivalent |
| TabView | `NSTabViewController` | Top tabs |
| ProgressBar | `NSProgressIndicator` (style=bar, indeterminate=NO) | Shares class with spinner |
| ActivityIndicator | `NSProgressIndicator` (style=spinning, indeterminate=YES) | Shares class with bar |
| Alert | `NSAlert` | Synchronous `runModal` or sheet |
| Picker | `NSPopUpButton` | Native dropdown |
| IconButton | `NSButton` (image + no title) | `bezelStyle: .regularSquare` |
| List | `NSTableView` | Datasource/delegate |

### Android — Key Classes for P1 Components

| Component | Android Class | Package |
|-----------|--------------|---------|
| Toggle | `SwitchMaterial` | `com.google.android.material.switchmaterial` |
| Checkbox | `CheckBox` | `android.widget` |
| RadioButton | `RadioButton` / `RadioGroup` | `android.widget` |
| Slider | `Slider` | `com.google.android.material.slider` |
| NavigationStack | `FragmentManager` + back stack | `androidx.fragment.app` |
| TabView | `BottomNavigationView` | `com.google.android.material.bottomnavigation` |
| ProgressBar | `ProgressBar` (horizontal) | `android.widget` |
| ActivityIndicator | `ProgressBar` (circular) | `android.widget` |
| Alert | `AlertDialog.Builder` | `androidx.appcompat.app` |
| Picker | `Spinner` / `ExposedDropdownMenuBox` | `android.widget` / Material |
| IconButton | `ImageButton` / `MaterialButton` (icon only) | `android.widget` / Material |
| List | `RecyclerView` | `androidx.recyclerview.widget` |

---

*End of plan. Supersedes v1 for all forward work. Milestones 1–8 from the v1 plan are complete.*
