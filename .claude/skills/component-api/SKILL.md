---
name: component-api
description: Full API reference for all UI::View types, value types, enums, and composition patterns
version: "2.0"
---

# Component API Reference

Complete API reference for the cross-platform `UI::View` hierarchy defined in `src/ui/`.

---

## Value Types

### `UI::Color`

RGBA color with floating-point components in the range 0.0 to 1.0.

```crystal
record Color,
  r : Float64,
  g : Float64,
  b : Float64,
  a : Float64 = 1.0
```

**Usage:**
```crystal
red   = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
white = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)
semi  = UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.5)
```

### `UI::Font`

Font specification with family, size, weight, and italic flag.

```crystal
record Font,
  family : String = "system",
  size : Float64 = 17.0,
  weight : Symbol = :regular,
  italic : Bool = false
```

**Weight values:** `:ultralight`, `:thin`, `:light`, `:regular`, `:medium`, `:semibold`, `:bold`, `:heavy`, `:black`

**Usage:**
```crystal
heading = UI::Font.new(size: 24.0, weight: :bold)
mono    = UI::Font.new(family: "monospace", size: 14.0)
italic  = UI::Font.new(weight: :medium, italic: true)
default = UI::Font.new  # system font, 17pt, regular
```

### `UI::EdgeInsets`

Edge insets for padding or margin values, in points.

```crystal
record EdgeInsets,
  top : Float64 = 0.0,
  trailing : Float64 = 0.0,
  bottom : Float64 = 0.0,
  leading : Float64 = 0.0
```

Note: Uses `leading`/`trailing` (not `left`/`right`) for RTL language support.

**Usage:**
```crystal
uniform  = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
vertical = UI::EdgeInsets.new(top: 8.0, bottom: 8.0)
none     = UI::EdgeInsets.new  # all zeros
```

### `UI::ThemeColor`

Semantic color in `UI::Theme`. Same RGBA structure as `UI::Color` but semantically scoped to theme roles.

```crystal
record ThemeColor,
  r : Float64,
  g : Float64,
  b : Float64,
  a : Float64 = 1.0
```

---

## Enums

### `UI::Alignment`

Controls alignment of children within stack layouts.

```crystal
enum Alignment
  Leading   # Left-aligned (or start, in RTL)
  Center    # Center-aligned
  Trailing  # Right-aligned (or end, in RTL)
  Top       # Top-aligned (for HStack vertical alignment)
  Bottom    # Bottom-aligned (for HStack vertical alignment)
  Fill      # Stretch to fill available space
end
```

- **VStack** uses `Leading`, `Center`, `Trailing`, `Fill` for horizontal alignment of children
- **HStack** uses `Top`, `Center`, `Bottom`, `Fill` for vertical alignment of children
- **ZStack** uses `Leading`, `Center`, `Trailing`, `Top`, `Bottom` for overlay positioning

### `UI::ContentMode`

Controls how an image is scaled to fit its bounds.

```crystal
enum ContentMode
  Fit      # Scale to fit within bounds, preserving aspect ratio (may letterbox)
  Fill     # Scale to fill bounds, preserving aspect ratio (may crop)
  Stretch  # Scale to exactly fill bounds (may distort)
end
```

### `UI::KeyboardType`

Hint for the platform's virtual keyboard type on mobile.

```crystal
enum KeyboardType
  Default       # Standard text keyboard
  EmailAddress  # Keyboard optimized for email input (@ key prominent)
  NumberPad     # Numeric-only keyboard
  PhonePad      # Phone number keyboard
  URL           # Keyboard optimized for URL input
end
```

### `UI::ToggleStyle`

Visual style for `UI::Toggle`.

```crystal
enum ToggleStyle
  Switch    # iOS-style toggle switch (thumb that slides)
  Checkbox  # Standard checkbox
end
```

### `UI::PickerStyle`

Visual style for `UI::Picker`.

```crystal
enum PickerStyle
  Wheel     # Spinning wheel picker (iOS UIPickerView style)
  Segmented # Segmented control inline
  Menu      # Dropdown/popup menu (default)
  Inline    # Expanded inline
end
```

### `UI::DatePickerMode`

What components the date picker shows.

```crystal
enum DatePickerMode
  Date         # Date only
  Time         # Time only
  DateAndTime  # Both date and time
end
```

### `UI::ProgressStyle`

Visual style for `UI::ProgressView`.

```crystal
enum ProgressStyle
  Linear    # Horizontal progress bar
  Circular  # Spinning circular progress
end
```

### `UI::ListStyle`

Visual style for `UI::ListView`.

```crystal
enum ListStyle
  Plain         # No grouping, no separators between sections
  Inset         # Rounded group sections with insets
  Grouped       # Grouped with section headers
  InsetGrouped  # Rounded grouped sections
  Sidebar       # macOS-style sidebar list
end
```

---

## Abstract Base: `UI::View`

**File:** `src/ui/view.cr`

All concrete view types inherit from this abstract class.

```crystal
abstract class UI::View
  # Identity & accessibility
  property id : String? = nil
  property accessibility_label : String? = nil

  # Layout
  property padding : EdgeInsets = EdgeInsets.new
  property background : Color? = nil
  property hidden : Bool = false
  property opacity : Float64 = 1.0

  # Shape modifiers
  property corner_radius : Float64 = 0.0
  property clip_to_bounds : Bool = false

  # Shadow modifier
  property shadow_radius : Float64 = 0.0
  property shadow_color : Color? = nil
  property shadow_offset_x : Float64 = 0.0
  property shadow_offset_y : Float64 = 0.0

  # Border modifier
  property border_width : Float64 = 0.0
  property border_color : Color? = nil

  # Blur modifier
  property blur_radius : Float64 = 0.0

  # Size constraints
  property minimum_width : Float64? = nil
  property minimum_height : Float64? = nil
  property maximum_width : Float64? = nil
  property maximum_height : Float64? = nil

  abstract def accept(visitor : PlatformVisitor)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `id` | `String?` | `nil` | Optional identifier for lookup and testing |
| `accessibility_label` | `String?` | `nil` | Screen reader label |
| `padding` | `EdgeInsets` | all zeros | Content padding |
| `background` | `Color?` | `nil` | Background color (nil = transparent/inherited) |
| `hidden` | `Bool` | `false` | Whether the view is hidden from display |
| `opacity` | `Float64` | `1.0` | Opacity from 0.0 (transparent) to 1.0 (opaque) |
| `corner_radius` | `Float64` | `0.0` | Corner radius in points |
| `clip_to_bounds` | `Bool` | `false` | Clip children to bounds |
| `shadow_radius` | `Float64` | `0.0` | Shadow blur radius (0 = no shadow) |
| `shadow_color` | `Color?` | `nil` | Shadow color |
| `shadow_offset_x` | `Float64` | `0.0` | Shadow horizontal offset |
| `shadow_offset_y` | `Float64` | `0.0` | Shadow vertical offset |
| `border_width` | `Float64` | `0.0` | Border stroke width (0 = no border) |
| `border_color` | `Color?` | `nil` | Border stroke color |
| `blur_radius` | `Float64` | `0.0` | Blur radius (0 = no blur) |
| `minimum_width` | `Float64?` | `nil` | Minimum width constraint |
| `minimum_height` | `Float64?` | `nil` | Minimum height constraint |
| `maximum_width` | `Float64?` | `nil` | Maximum width constraint |
| `maximum_height` | `Float64?` | `nil` | Maximum height constraint |

---

## Concrete View Types

### P0 Base Views

---

### `UI::Label`

**File:** `src/ui/views/label.cr`

Read-only text display.

```crystal
class UI::Label < UI::View
  property text : String
  property font : Font = Font.new
  property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property text_alignment : Alignment = Alignment::Leading
  property number_of_lines : Int32 = 0

  def initialize(@text : String)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `text` | `String` | (required) | The displayed text content |
| `font` | `Font` | system 17pt | Font specification |
| `text_color` | `Color` | black | Text foreground color |
| `text_alignment` | `Alignment` | `Leading` | Horizontal text alignment |
| `number_of_lines` | `Int32` | `0` | Max lines to display (0 = unlimited) |

**Example:**
```crystal
title = UI::Label.new("Welcome Back")
title.font = UI::Font.new(size: 28.0, weight: :bold)
title.text_color = UI::Color.new(r: 0.2, g: 0.2, b: 0.2)
title.text_alignment = UI::Alignment::Center
```

---

### `UI::Button`

**File:** `src/ui/views/button.cr`

A tappable button with a text label.

```crystal
class UI::Button < UI::View
  property label : String
  property font : Font = Font.new
  property foreground_color : Color = Color.new(r: 0.0, g: 0.478, b: 1.0)
  property disabled : Bool = false
  property on_tap : Proc(Nil)? = nil

  def initialize(@label : String)
  def initialize(@label : String, &block : -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `label` | `String` | (required) | Button display text |
| `font` | `Font` | system 17pt | Label font |
| `foreground_color` | `Color` | system blue | Label and tint color |
| `disabled` | `Bool` | `false` | Whether interaction is disabled |
| `on_tap` | `Proc(Nil)?` | `nil` | Callback invoked on tap |

**Example:**
```crystal
save = UI::Button.new("Save") { puts "Saved!"; nil }

delete = UI::Button.new("Delete")
delete.foreground_color = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
delete.on_tap = ->{ handle_delete; nil }
```

---

### `UI::VStack`

**File:** `src/ui/views/vstack.cr`

Vertical stack layout.

```crystal
class UI::VStack < UI::View
  property spacing : Float64 = 8.0
  property alignment : Alignment = Alignment::Center
  getter children : Array(View) = [] of View

  def initialize(@spacing : Float64 = 8.0, @alignment : Alignment = Alignment::Center)
  def <<(child : View) : self
end
```

---

### `UI::HStack`

**File:** `src/ui/views/hstack.cr`

Horizontal stack layout.

```crystal
class UI::HStack < UI::View
  property spacing : Float64 = 8.0
  property alignment : Alignment = Alignment::Center
  getter children : Array(View) = [] of View

  def initialize(@spacing : Float64 = 8.0, @alignment : Alignment = Alignment::Center)
  def <<(child : View) : self
end
```

---

### `UI::ZStack`

**File:** `src/ui/views/zstack.cr`

Z-axis overlay stack. Later children are rendered on top.

```crystal
class UI::ZStack < UI::View
  property alignment : Alignment = Alignment::Center
  getter children : Array(View) = [] of View

  def initialize(@alignment : Alignment = Alignment::Center)
  def <<(child : View) : self
end
```

---

### `UI::Image`

**File:** `src/ui/views/image.cr`

Displays an image from a named resource.

```crystal
class UI::Image < UI::View
  property source : String
  property content_mode : ContentMode = ContentMode::Fit
  property tint_color : Color? = nil

  def initialize(@source : String)
end
```

---

### `UI::TextField`

**File:** `src/ui/views/text_field.cr`

Editable single-line text input.

```crystal
class UI::TextField < UI::View
  property text : String = ""
  property placeholder : String = ""
  property font : Font = Font.new
  property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property secure_entry : Bool = false
  property keyboard_type : KeyboardType = KeyboardType::Default
  property on_change : Proc(String, Nil)? = nil

  def initialize(@placeholder : String = "")
  def initialize(@placeholder : String = "", &block : String -> Nil)
end
```

---

### `UI::ScrollView`

**File:** `src/ui/views/scroll_view.cr`

A scrollable container wrapping a single child view.

```crystal
class UI::ScrollView < UI::View
  property content : View? = nil
  property scroll_horizontal : Bool = false
  property scroll_vertical : Bool = true
  property shows_indicators : Bool = true

  def initialize(@content : View? = nil)
end
```

---

### `UI::Spacer`

**File:** `src/ui/views/spacer.cr`

Flexible space within a stack layout.

```crystal
class UI::Spacer < UI::View
  property min_length : Float64 = 0.0

  def initialize(@min_length : Float64 = 0.0)
end
```

---

## Selection Controls

---

### `UI::Toggle`

**File:** `src/ui/views/toggle.cr`

Boolean on/off switch control.

```crystal
class UI::Toggle < UI::View
  property is_on : Bool = false
  property label : String = ""
  property style : ToggleStyle = ToggleStyle::Switch
  property tint_color : Color? = nil
  property on_change : Proc(Bool, Nil)? = nil

  def initialize(@label : String = "", @is_on : Bool = false)
  def initialize(@label : String = "", @is_on : Bool = false, &block : Bool -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `is_on` | `Bool` | `false` | Current state |
| `label` | `String` | `""` | Descriptive label |
| `style` | `ToggleStyle` | `Switch` | Switch or Checkbox style |
| `tint_color` | `Color?` | `nil` | Tint for the active state |
| `on_change` | `Proc(Bool, Nil)?` | `nil` | Fires with new boolean value |

**Example:**
```crystal
wifi = UI::Toggle.new("Wi-Fi", true) { |on| configure_wifi(on); nil }
wifi.style = UI::ToggleStyle::Switch
```

---

### `UI::Checkbox`

**File:** `src/ui/views/checkbox.cr`

A checkable selection control.

```crystal
class UI::Checkbox < UI::View
  property is_checked : Bool = false
  property label : String = ""
  property on_change : Proc(Bool, Nil)? = nil

  def initialize(@label : String = "", @is_checked : Bool = false)
  def initialize(@label : String = "", @is_checked : Bool = false, &block : Bool -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `is_checked` | `Bool` | `false` | Current checked state |
| `label` | `String` | `""` | Label text |
| `on_change` | `Proc(Bool, Nil)?` | `nil` | Fires with new checked state |

**Example:**
```crystal
terms = UI::Checkbox.new("I agree to the terms") { |checked| enable_submit(checked); nil }
```

---

### `UI::RadioGroup`

**File:** `src/ui/views/radio_group.cr`

A group of mutually exclusive radio options.

```crystal
class UI::RadioGroup < UI::View
  property options : Array(String) = [] of String
  property selected_index : Int32 = 0
  property on_change : Proc(Int32, Nil)? = nil

  def initialize(@options : Array(String) = [] of String, @selected_index : Int32 = 0)
  def initialize(@options : Array(String), @selected_index : Int32 = 0, &block : Int32 -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `options` | `Array(String)` | `[]` | Option labels |
| `selected_index` | `Int32` | `0` | Currently selected option index |
| `on_change` | `Proc(Int32, Nil)?` | `nil` | Fires with newly selected index |

**Example:**
```crystal
size = UI::RadioGroup.new(["Small", "Medium", "Large"]) { |i| set_size(i); nil }
```

---

### `UI::Slider`

**File:** `src/ui/views/slider.cr`

A continuous or stepped value control.

```crystal
class UI::Slider < UI::View
  property value : Float64 = 0.0
  property minimum : Float64 = 0.0
  property maximum : Float64 = 1.0
  property step : Float64 = 0.0  # 0 = continuous
  property label : String = ""
  property tint_color : Color? = nil
  property on_change : Proc(Float64, Nil)? = nil

  def initialize(@minimum : Float64 = 0.0, @maximum : Float64 = 1.0, @value : Float64 = 0.0)
  def initialize(@minimum : Float64 = 0.0, @maximum : Float64 = 1.0, @value : Float64 = 0.0, &block : Float64 -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `value` | `Float64` | `0.0` | Current value |
| `minimum` | `Float64` | `0.0` | Minimum bound |
| `maximum` | `Float64` | `1.0` | Maximum bound |
| `step` | `Float64` | `0.0` | Step increment (0 = continuous) |
| `label` | `String` | `""` | Descriptive label |
| `tint_color` | `Color?` | `nil` | Track tint color |
| `on_change` | `Proc(Float64, Nil)?` | `nil` | Fires with new value |

**Example:**
```crystal
volume = UI::Slider.new(0.0, 1.0, 0.5) { |v| set_volume(v); nil }
```

---

### `UI::Stepper`

**File:** `src/ui/views/stepper.cr`

A numeric increment/decrement control.

```crystal
class UI::Stepper < UI::View
  property value : Float64 = 0.0
  property minimum : Float64 = 0.0
  property maximum : Float64 = 100.0
  property step_value : Float64 = 1.0
  property label : String = ""
  property wraps : Bool = false
  property on_change : Proc(Float64, Nil)? = nil

  def initialize(@minimum : Float64 = 0.0, @maximum : Float64 = 100.0, @value : Float64 = 0.0)
  def initialize(@minimum : Float64, @maximum : Float64, @value : Float64 = 0.0, &block : Float64 -> Nil)

  def increment  # increments value by step_value, respecting maximum and wraps
  def decrement  # decrements value by step_value, respecting minimum and wraps
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `value` | `Float64` | `0.0` | Current value |
| `minimum` | `Float64` | `0.0` | Minimum value |
| `maximum` | `Float64` | `100.0` | Maximum value |
| `step_value` | `Float64` | `1.0` | Amount to increment/decrement |
| `label` | `String` | `""` | Descriptive label |
| `wraps` | `Bool` | `false` | Wrap around at min/max |
| `on_change` | `Proc(Float64, Nil)?` | `nil` | Fires with new value |

**Example:**
```crystal
quantity = UI::Stepper.new(1.0, 99.0, 1.0) { |v| update_quantity(v.to_i); nil }
quantity.step_value = 1.0
quantity.label = "Quantity"
```

---

### `UI::SegmentedControl`

**File:** `src/ui/views/segmented_control.cr`

A horizontal set of mutually exclusive segment buttons.

```crystal
class UI::SegmentedControl < UI::View
  property segments : Array(String) = [] of String
  property selected_index : Int32 = 0
  property on_change : Proc(Int32, Nil)? = nil

  def initialize(@segments : Array(String) = [] of String, @selected_index : Int32 = 0)
  def initialize(@segments : Array(String), @selected_index : Int32 = 0, &block : Int32 -> Nil)

  def selected_segment : String?  # returns current segment label or nil
end
```

**Example:**
```crystal
period = UI::SegmentedControl.new(["Day", "Week", "Month"]) { |i| load_data(i); nil }
```

---

## Navigation

---

### `UI::NavigationStack`

**File:** `src/ui/views/navigation_stack.cr`

A push/pop navigation container.

```crystal
class UI::NavigationStack < UI::View
  property root : View
  property title : String? = nil
  property large_title : Bool = false
  property shows_navigation_bar : Bool = true
  getter stack : Array(View) = [] of View

  def initialize(@root : View, @title : String? = nil)

  def push(view : View)          # push view onto stack
  def pop : View?                # pop top view, returns it
  def pop_to_root                # clear entire stack
  def current_view : View        # top of stack or root
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `root` | `View` | (required) | Initial/root view |
| `title` | `String?` | `nil` | Navigation bar title |
| `large_title` | `Bool` | `false` | Use large title style (iOS) |
| `shows_navigation_bar` | `Bool` | `true` | Whether to show the nav bar |
| `stack` | `Array(View)` | `[]` | Pushed views (read-only) |

**Example:**
```crystal
nav = UI::NavigationStack.new(root: home_view, title: "App")
nav.large_title = true
nav.push(detail_view)
nav.pop
nav.pop_to_root
```

---

### `UI::NavigationLink`

**File:** `src/ui/views/navigation_link.cr`

A tappable element that pushes a destination view.

```crystal
class UI::NavigationLink < UI::View
  property label : String
  property destination : View
  property icon : String? = nil
  property shows_disclosure : Bool = true

  def initialize(@label : String, @destination : View)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `label` | `String` | (required) | Display text |
| `destination` | `View` | (required) | View pushed when tapped |
| `icon` | `String?` | `nil` | Optional icon name |
| `shows_disclosure` | `Bool` | `true` | Show chevron indicator |

**Example:**
```crystal
link = UI::NavigationLink.new("Settings", settings_view)
link.icon = "gear"
```

---

### `UI::TabView`

**File:** `src/ui/views/tab_view.cr`

A tab bar navigation container.

```crystal
class UI::TabView < UI::View
  record Tab,
    label : String,
    icon : String? = nil,
    content : View = Label.new("")

  property tabs : Array(Tab) = [] of Tab
  property selected_index : Int32 = 0
  property on_change : Proc(Int32, Nil)? = nil

  def initialize(@tabs : Array(Tab) = [] of Tab, @selected_index : Int32 = 0)
  def initialize(@tabs : Array(Tab), @selected_index : Int32 = 0, &block : Int32 -> Nil)

  def current_content : View?  # content of selected tab
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `tabs` | `Array(Tab)` | `[]` | Tab definitions |
| `selected_index` | `Int32` | `0` | Active tab index |
| `on_change` | `Proc(Int32, Nil)?` | `nil` | Fires when tab changes |

**Tab record fields:** `label : String`, `icon : String?`, `content : View`

**Example:**
```crystal
tabs = UI::TabView.new([
  UI::TabView::Tab.new(label: "Home", icon: "house", content: home_view),
  UI::TabView::Tab.new(label: "Profile", icon: "person", content: profile_view),
]) { |i| puts "switched to tab #{i}"; nil }
```

---

### `UI::NavigationSplitView`

**File:** `src/ui/views/navigation_split_view.cr`

A sidebar/detail split layout.

```crystal
class UI::NavigationSplitView < UI::View
  property sidebar : View? = nil
  property content : View? = nil
  property detail : View? = nil
  property sidebar_width : Float64 = 250.0
  property shows_sidebar : Bool = true
  property column_visibility : Symbol = :all  # :all, :double_column, :detail_only

  def initialize(@sidebar : View? = nil, @content : View? = nil, @detail : View? = nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `sidebar` | `View?` | `nil` | Leading sidebar column |
| `content` | `View?` | `nil` | Middle content column (3-column only) |
| `detail` | `View?` | `nil` | Trailing detail column |
| `sidebar_width` | `Float64` | `250.0` | Sidebar width in points |
| `shows_sidebar` | `Bool` | `true` | Whether sidebar is visible |
| `column_visibility` | `Symbol` | `:all` | Column layout: `:all`, `:double_column`, `:detail_only` |

**Example:**
```crystal
split = UI::NavigationSplitView.new(
  sidebar: sidebar_list,
  detail: detail_view
)
split.sidebar_width = 280.0
```

---

### `UI::Toolbar`

**File:** `src/ui/views/toolbar.cr`

A toolbar with action items.

```crystal
class UI::Toolbar < UI::View
  record ToolbarItem,
    id : String = "",
    label : String = "",
    icon : String? = nil,
    action : Proc(Nil)? = nil

  property items : Array(ToolbarItem) = [] of ToolbarItem
  property title : String? = nil
  property shows_title : Bool = true

  def initialize(@title : String? = nil)

  def add_item(id : String, label : String, icon : String? = nil, &block : -> Nil)
  def add_item(id : String, label : String, icon : String? = nil)
end
```

**Example:**
```crystal
toolbar = UI::Toolbar.new(title: "Documents")
toolbar.add_item("add", "New", icon: "plus") { create_document; nil }
toolbar.add_item("share", "Share", icon: "square.and.arrow.up") { share; nil }
```

---

## Feedback & Input

---

### `UI::ProgressView`

**File:** `src/ui/views/progress_view.cr`

A determinate or indeterminate progress indicator.

```crystal
class UI::ProgressView < UI::View
  property value : Float64? = nil   # nil = indeterminate
  property style : ProgressStyle = ProgressStyle::Linear
  property tint_color : Color? = nil
  property label : String = ""

  def initialize(@value : Float64? = nil, @style : ProgressStyle = ProgressStyle::Linear)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `value` | `Float64?` | `nil` | Progress 0.0–1.0; nil = indeterminate |
| `style` | `ProgressStyle` | `Linear` | `Linear` or `Circular` |
| `tint_color` | `Color?` | `nil` | Track fill color |
| `label` | `String` | `""` | Descriptive label |

**Example:**
```crystal
# Determinate
bar = UI::ProgressView.new(0.65)

# Indeterminate
spinner = UI::ProgressView.new(nil, UI::ProgressStyle::Circular)
```

---

### `UI::ActivityIndicator`

**File:** `src/ui/views/activity_indicator.cr`

An indeterminate spinning activity indicator.

```crystal
class UI::ActivityIndicator < UI::View
  property is_animating : Bool = true
  property size : Symbol = :medium   # :small, :medium, :large
  property color : Color? = nil

  def initialize(@is_animating : Bool = true, @size : Symbol = :medium)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `is_animating` | `Bool` | `true` | Whether spinner is spinning |
| `size` | `Symbol` | `:medium` | Size: `:small`, `:medium`, `:large` |
| `color` | `Color?` | `nil` | Spinner color (nil = platform default) |

---

### `UI::Alert`

**File:** `src/ui/views/alert.cr`

A modal alert dialog.

```crystal
class UI::Alert < UI::View
  record AlertButton,
    label : String,
    style : Symbol = :default,  # :default, :destructive, :cancel
    action : Proc(Nil)? = nil

  property title : String
  property message : String = ""
  property buttons : Array(AlertButton) = [] of AlertButton
  property is_presented : Bool = false

  def initialize(@title : String, @message : String = "")

  def add_button(label : String, style : Symbol = :default, &action : -> Nil)
  def add_button(label : String, style : Symbol = :default)
end
```

**Example:**
```crystal
alert = UI::Alert.new("Delete File", "This action cannot be undone.")
alert.add_button("Cancel", :cancel)
alert.add_button("Delete", :destructive) { perform_delete; nil }
alert.is_presented = true
```

---

### `UI::Picker`

**File:** `src/ui/views/picker.cr`

A selection control for choosing from a list of options.

```crystal
class UI::Picker < UI::View
  property options : Array(String) = [] of String
  property selected_index : Int32 = 0
  property label : String = ""
  property style : PickerStyle = PickerStyle::Menu
  property on_change : Proc(Int32, Nil)? = nil

  def initialize(@options : Array(String) = [] of String, @selected_index : Int32 = 0)
  def initialize(@options : Array(String), @selected_index : Int32 = 0, &block : Int32 -> Nil)

  def selected_option : String?  # currently selected option text
end
```

**Example:**
```crystal
country = UI::Picker.new(["USA", "Canada", "Mexico"]) { |i| set_country(i); nil }
country.label = "Country"
country.style = UI::PickerStyle::Menu
```

---

### `UI::IconButton`

**File:** `src/ui/views/icon_button.cr`

A button that displays an icon instead of text.

```crystal
class UI::IconButton < UI::View
  property icon : String
  property label : String? = nil
  property icon_size : Float64 = 24.0
  property tint_color : Color = Color.new(r: 0.0, g: 0.478, b: 1.0)
  property disabled : Bool = false
  property on_tap : Proc(Nil)? = nil

  def initialize(@icon : String)
  def initialize(@icon : String, &block : -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `icon` | `String` | (required) | SF Symbol (Apple) / material icon name (Android) / CSS class (Web) |
| `label` | `String?` | `nil` | Optional text label alongside icon |
| `icon_size` | `Float64` | `24.0` | Icon size in points |
| `tint_color` | `Color` | system blue | Icon color |
| `disabled` | `Bool` | `false` | Whether button is disabled |
| `on_tap` | `Proc(Nil)?` | `nil` | Tap callback |

**Example:**
```crystal
share_btn = UI::IconButton.new("square.and.arrow.up") { share_content; nil }
share_btn.tint_color = UI::Color.new(r: 0.0, g: 0.478, b: 1.0)
```

---

### `UI::ListView`

**File:** `src/ui/views/list_view.cr`

A scrollable list of items, optionally grouped into sections.

```crystal
class UI::ListView < UI::View
  record Section,
    header : String? = nil,
    items : Array(View) = [] of View,
    footer : String? = nil

  property sections : Array(Section) = [] of Section
  property style : ListStyle = ListStyle::Plain
  property shows_separators : Bool = true
  property on_item_tap : Proc(Int32, Int32, Nil)? = nil

  def initialize(@sections : Array(Section) = [] of Section, @style : ListStyle = ListStyle::Plain)

  def self.flat(items : Array(View), style : ListStyle = ListStyle::Plain) : ListView
  def item_count : Int32
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `sections` | `Array(Section)` | `[]` | List sections |
| `style` | `ListStyle` | `Plain` | Visual style |
| `shows_separators` | `Bool` | `true` | Show dividers between items |
| `on_item_tap` | `Proc(Int32, Int32, Nil)?` | `nil` | Tap callback (section_index, item_index) |

**Example:**
```crystal
# Flat list
rows = items.map { |item| UI::Label.new(item.title) }
list = UI::ListView.flat(rows, UI::ListStyle::Inset)

# Sectioned list
list = UI::ListView.new
list.sections = [
  UI::ListView::Section.new(header: "Favorites", items: fav_rows),
  UI::ListView::Section.new(header: "Recent", items: recent_rows),
]
list.on_item_tap = ->(s : Int32, i : Int32) { open_item(s, i); nil }
```

---

### `UI::SecureField`

**File:** `src/ui/views/secure_field.cr`

A password/secure text input. Always obscures input.

```crystal
class UI::SecureField < UI::View
  property text : String = ""
  property placeholder : String = ""
  property font : Font = Font.new
  property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property on_change : Proc(String, Nil)? = nil

  def initialize(@placeholder : String = "")
  def initialize(@placeholder : String = "", &block : String -> Nil)
end
```

---

### `UI::SearchField`

**File:** `src/ui/views/search_field.cr`

A search-optimized text input with cancel button.

```crystal
class UI::SearchField < UI::View
  property text : String = ""
  property placeholder : String = "Search"
  property is_searching : Bool = false
  property shows_cancel_button : Bool = true
  property on_change : Proc(String, Nil)? = nil
  property on_submit : Proc(String, Nil)? = nil
  property on_cancel : Proc(Nil)? = nil

  def initialize(@placeholder : String = "Search")
  def initialize(@placeholder : String = "Search", &block : String -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `text` | `String` | `""` | Current search text |
| `placeholder` | `String` | `"Search"` | Placeholder text |
| `is_searching` | `Bool` | `false` | Whether search is active |
| `shows_cancel_button` | `Bool` | `true` | Show cancel affordance |
| `on_change` | `Proc(String, Nil)?` | `nil` | Fires on text change |
| `on_submit` | `Proc(String, Nil)?` | `nil` | Fires on submit/return |
| `on_cancel` | `Proc(Nil)?` | `nil` | Fires on cancel |

---

### `UI::TextArea`

**File:** `src/ui/views/text_area.cr`

A multiline text input field.

```crystal
class UI::TextArea < UI::View
  property text : String = ""
  property placeholder : String = ""
  property font : Font = Font.new
  property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property is_editable : Bool = true
  property is_scrollable : Bool = true
  property line_limit : Int32? = nil
  property on_change : Proc(String, Nil)? = nil

  def initialize(@placeholder : String = "")
  def initialize(@placeholder : String = "", &block : String -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `text` | `String` | `""` | Text content |
| `placeholder` | `String` | `""` | Placeholder when empty |
| `font` | `Font` | system 17pt | Content font |
| `text_color` | `Color` | black | Text color |
| `is_editable` | `Bool` | `true` | Whether content is editable |
| `is_scrollable` | `Bool` | `true` | Whether to scroll when content overflows |
| `line_limit` | `Int32?` | `nil` | Maximum number of lines (nil = unlimited) |
| `on_change` | `Proc(String, Nil)?` | `nil` | Fires on text change |

---

### `UI::TextEditor`

**File:** `src/ui/views/text_editor.cr`

A multiline editor with optional line numbers and syntax highlighting.

```crystal
class UI::TextEditor < UI::View
  property text : String = ""
  property placeholder : String = ""
  property font : Font = Font.new
  property text_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property is_editable : Bool = true
  property shows_line_numbers : Bool = false
  property syntax_highlighting : Symbol? = nil  # :crystal, :json, :markdown, etc.
  property on_change : Proc(String, Nil)? = nil

  def initialize(@placeholder : String = "")
  def initialize(@placeholder : String = "", &block : String -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `text` | `String` | `""` | Text content |
| `placeholder` | `String` | `""` | Placeholder when empty |
| `is_editable` | `Bool` | `true` | Whether editable |
| `shows_line_numbers` | `Bool` | `false` | Show gutter line numbers |
| `syntax_highlighting` | `Symbol?` | `nil` | Language hint (`:crystal`, `:json`, `:markdown`, etc.) |
| `on_change` | `Proc(String, Nil)?` | `nil` | Fires on text change |

---

## Advanced Controls

---

### `UI::DatePicker`

**File:** `src/ui/views/date_picker.cr`

A date and/or time selection control.

```crystal
class UI::DatePicker < UI::View
  property selected_date : Time = Time.utc
  property mode : DatePickerMode = DatePickerMode::Date
  property minimum_date : Time? = nil
  property maximum_date : Time? = nil
  property label : String = ""
  property on_change : Proc(Time, Nil)? = nil

  def initialize(@mode : DatePickerMode = DatePickerMode::Date)
  def initialize(@mode : DatePickerMode = DatePickerMode::Date, &block : Time -> Nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `selected_date` | `Time` | `Time.utc` | Currently selected date/time |
| `mode` | `DatePickerMode` | `Date` | `Date`, `Time`, or `DateAndTime` |
| `minimum_date` | `Time?` | `nil` | Earliest selectable date |
| `maximum_date` | `Time?` | `nil` | Latest selectable date |
| `label` | `String` | `""` | Descriptive label |
| `on_change` | `Proc(Time, Nil)?` | `nil` | Fires with selected Time |

---

### `UI::TimePicker`

**File:** `src/ui/views/time_picker.cr`

A time-of-day selection control.

```crystal
class UI::TimePicker < UI::View
  property selected_time : Time = Time.utc
  property shows_24_hour : Bool = false
  property minute_interval : Int32 = 1
  property label : String = ""
  property on_change : Proc(Time, Nil)? = nil

  def initialize(@shows_24_hour : Bool = false)
  def initialize(@shows_24_hour : Bool = false, &block : Time -> Nil)
end
```

---

### `UI::Grid`

**File:** `src/ui/views/grid.cr`

A fixed-column grid layout.

```crystal
class UI::Grid < UI::View
  record Column,
    alignment : Alignment = Alignment::Leading,
    minimum_width : Float64? = nil

  property children : Array(Array(View)) = [] of Array(View)
  property columns : Array(Column) = [] of Column
  property row_spacing : Float64 = 8.0
  property column_spacing : Float64 = 8.0
  property alignment : Alignment = Alignment::Leading

  def initialize(@columns : Array(Column) = [] of Column)

  def add_row(views : Array(View))
  def add_row(&)          # yields mutable row array
  def row_count : Int32
  def column_count : Int32
end
```

**Example:**
```crystal
grid = UI::Grid.new([
  UI::Grid::Column.new(alignment: UI::Alignment::Leading),
  UI::Grid::Column.new(alignment: UI::Alignment::Trailing),
])
grid.add_row([UI::Label.new("Name"), UI::Label.new("Value")])
grid.add_row { |row| row << UI::Label.new("A"); row << UI::Label.new("1") }
```

---

### `UI::Form`

**File:** `src/ui/views/form.cr`

A settings-style grouped form layout.

```crystal
class UI::Form < UI::View
  record Field,
    label : String = "",
    content : View? = nil

  record FormSection,
    header : String? = nil,
    fields : Array(Field) = [] of Field,
    footer : String? = nil

  property sections : Array(FormSection) = [] of FormSection

  def initialize

  def add_section(header : String? = nil, footer : String? = nil) : FormSection
  def field_count : Int32
end
```

**Example:**
```crystal
form = UI::Form.new
section = form.add_section(header: "Account", footer: "Changes take effect immediately.")
section.fields << UI::Form::Field.new(label: "Name", content: name_field)
section.fields << UI::Form::Field.new(label: "Email", content: email_field)
```

---

### `UI::AsyncImage`

**File:** `src/ui/views/async_image.cr`

An image loaded asynchronously from a URL.

```crystal
class UI::AsyncImage < UI::View
  property url : String = ""
  property placeholder : View? = nil
  property content_mode : ContentMode = ContentMode::Fit
  property is_loading : Bool = false
  property error_message : String? = nil
  property on_load : Proc(Nil)? = nil
  property on_error : Proc(String, Nil)? = nil

  def initialize(@url : String = "")
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `url` | `String` | `""` | Remote image URL |
| `placeholder` | `View?` | `nil` | View shown while loading |
| `content_mode` | `ContentMode` | `Fit` | Image scaling mode |
| `is_loading` | `Bool` | `false` | Current loading state |
| `error_message` | `String?` | `nil` | Error description if load failed |
| `on_load` | `Proc(Nil)?` | `nil` | Fires on successful load |
| `on_error` | `Proc(String, Nil)?` | `nil` | Fires with error message on failure |

**Example:**
```crystal
avatar = UI::AsyncImage.new("https://example.com/avatar.png")
avatar.placeholder = UI::ActivityIndicator.new
avatar.content_mode = UI::ContentMode::Fill
avatar.on_error = ->(msg : String) { log_error(msg); nil }
```

---

### `UI::RichText`

**File:** `src/ui/views/rich_text.cr`

A styled/attributed text display with multiple inline spans.

```crystal
class UI::RichText < UI::View
  record Span,
    text : String = "",
    font : Font = Font.new,
    color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0),
    bold : Bool = false,
    italic : Bool = false,
    underline : Bool = false,
    strikethrough : Bool = false,
    link : String? = nil

  property spans : Array(Span) = [] of Span
  property text_alignment : Alignment = Alignment::Leading

  def initialize

  def add_span(text : String, bold : Bool = false, italic : Bool = false, color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0))
  def plain_text : String   # joins all span text
end
```

**Example:**
```crystal
rt = UI::RichText.new
rt.add_span("Hello, ", bold: false)
rt.add_span("World!", bold: true, color: UI::Color.new(r: 0.0, g: 0.478, b: 1.0))
rt.spans << UI::RichText::Span.new(text: " (link)", link: "https://example.com", underline: true)
```

---

### `UI::LinkButton`

**File:** `src/ui/views/link_button.cr`

A button that opens a URL.

```crystal
class UI::LinkButton < UI::View
  property label : String
  property url : String = ""
  property opens_in_browser : Bool = true
  property on_tap : Proc(Nil)? = nil

  def initialize(@label : String, @url : String = "")
end
```

---

### `UI::MenuButton`

**File:** `src/ui/views/menu_button.cr`

A button that reveals a drop-down menu of actions.

```crystal
class UI::MenuButton < UI::View
  record MenuItem,
    label : String = "",
    icon : String? = nil,
    is_destructive : Bool = false,
    action : Proc(Nil)? = nil

  property label : String
  property icon : String? = nil
  property items : Array(MenuItem) = [] of MenuItem

  def initialize(@label : String)

  def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, &block : -> Nil)
  def add_item(label : String, icon : String? = nil, is_destructive : Bool = false)
end
```

**Example:**
```crystal
menu = UI::MenuButton.new("Options", icon: "ellipsis.circle")
menu.add_item("Edit", icon: "pencil") { begin_edit; nil }
menu.add_item("Delete", icon: "trash", is_destructive: true) { confirm_delete; nil }
```

---

### `UI::ToggleButton`

**File:** `src/ui/views/toggle_button.cr`

A button-shaped toggle control.

```crystal
class UI::ToggleButton < UI::View
  property label : String
  property is_selected : Bool = false
  property icon : String? = nil
  property on_toggle : Proc(Bool, Nil)? = nil

  def initialize(@label : String, @is_selected : Bool = false)
  def initialize(@label : String, @is_selected : Bool = false, &block : Bool -> Nil)

  def toggle   # flips is_selected
end
```

---

## Modals and Overlays

---

### `UI::Sheet` + `UI::SheetPresenter`

**File:** `src/ui/views/sheet.cr`

A modal bottom/top sheet with detents.

```crystal
class UI::Sheet < UI::View
  property content : View? = nil
  property is_presented : Bool = false
  property shows_drag_indicator : Bool = true
  property detents : Array(Symbol) = [:medium, :large]  # :small, :medium, :large, :custom
  property selected_detent : Symbol = :medium
  property on_dismiss : Proc(Nil)? = nil

  def initialize(@content : View? = nil)
end

class UI::SheetPresenter
  property sheet : Sheet
  property is_presenting : Bool = false

  def initialize(@sheet : Sheet)
  def present    # sets sheet.is_presented = true
  def dismiss    # sets sheet.is_presented = false, fires on_dismiss
end
```

**Example:**
```crystal
sheet = UI::Sheet.new(content: filter_form)
sheet.detents = [:medium, :large]
sheet.on_dismiss = ->{ reset_filters; nil }

presenter = UI::SheetPresenter.new(sheet)
presenter.present
```

---

### `UI::Popover` + `UI::PopoverPresenter`

**File:** `src/ui/views/popover.cr`

An anchored popover/callout.

```crystal
class UI::Popover < UI::View
  property content : View? = nil
  property is_presented : Bool = false
  property arrow_edge : Symbol = :bottom  # :top, :bottom, :leading, :trailing
  property preferred_width : Float64? = nil
  property preferred_height : Float64? = nil
  property on_dismiss : Proc(Nil)? = nil

  def initialize(@content : View? = nil, @arrow_edge : Symbol = :bottom)
end

class UI::PopoverPresenter
  property popover : Popover
  property anchor : View? = nil
  property is_presenting : Bool = false

  def initialize(@popover : Popover, @anchor : View? = nil)
  def present
  def dismiss
end
```

---

### `UI::ConfirmationDialog`

**File:** `src/ui/views/confirmation_dialog.cr`

A two-action confirmation alert (confirm/cancel).

```crystal
class UI::ConfirmationDialog < UI::View
  property title : String
  property message : String = ""
  property is_presented : Bool = false
  property confirm_label : String = "Confirm"
  property cancel_label : String = "Cancel"
  property confirm_style : Symbol = :default  # :default, :destructive
  property on_confirm : Proc(Nil)? = nil
  property on_cancel : Proc(Nil)? = nil

  def initialize(@title : String, @message : String = "")
end
```

**Example:**
```crystal
dialog = UI::ConfirmationDialog.new("Delete Account", "This cannot be undone.")
dialog.confirm_label = "Delete"
dialog.confirm_style = :destructive
dialog.on_confirm = ->{ delete_account; nil }
dialog.on_cancel = ->{ nil }
dialog.is_presented = true
```

---

### `UI::Snackbar` + `UI::SnackbarPresenter`

**File:** `src/ui/views/snackbar.cr`

A transient feedback message with optional action.

```crystal
class UI::Snackbar < UI::View
  property message : String
  property action_label : String? = nil
  property duration : Float64 = 4.0  # seconds
  property is_presented : Bool = false
  property on_action : Proc(Nil)? = nil
  property on_dismiss : Proc(Nil)? = nil

  def initialize(@message : String, @action_label : String? = nil)
end

class UI::SnackbarPresenter
  property snackbar : Snackbar
  property is_presenting : Bool = false

  def initialize(@snackbar : Snackbar)
  def show      # sets snackbar.is_presented = true
  def dismiss   # sets snackbar.is_presented = false, fires on_dismiss
end
```

**Example:**
```crystal
snackbar = UI::Snackbar.new("File deleted", "Undo")
snackbar.duration = 5.0
snackbar.on_action = ->{ undo_delete; nil }

presenter = UI::SnackbarPresenter.new(snackbar)
presenter.show
```

---

## Cards and Containers

---

### `UI::Card`

**File:** `src/ui/views/card.cr`

An elevated content container.

```crystal
class UI::Card < UI::View
  property content : View? = nil
  property elevation : Float64 = 1.0
  property is_outlined : Bool = false

  def initialize(@content : View? = nil)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `content` | `View?` | `nil` | Card body content |
| `elevation` | `Float64` | `1.0` | Shadow elevation level |
| `is_outlined` | `Bool` | `false` | Show outline border instead of shadow |

---

### `UI::Surface`

**File:** `src/ui/views/surface.cr`

A flat Material Design surface container.

```crystal
class UI::Surface < UI::View
  property content : View? = nil
  property elevation : Float64 = 0.0
  property tonal_elevation : Float64 = 0.0
  property shape : Symbol = :rectangle  # :rectangle, :rounded, :circle

  def initialize(@content : View? = nil)
end
```

---

### `UI::Divider`

**File:** `src/ui/views/divider.cr`

A separator line.

```crystal
class UI::Divider < UI::View
  property color : Color = Color.new(r: 0.8, g: 0.8, b: 0.8)
  property thickness : Float64 = 1.0
  property orientation : Symbol = :horizontal  # :horizontal, :vertical

  def initialize(@orientation : Symbol = :horizontal)
end
```

---

### `UI::GlassBackground`

**File:** `src/ui/views/glass_background.cr`

A translucent blurred glass/vibrancy background.

```crystal
class UI::GlassBackground < UI::View
  property content : View? = nil
  property material : Symbol = :regular  # :thin, :ultra_thin, :regular, :thick, :chrome
  property is_vibrant : Bool = true

  def initialize(@content : View? = nil, @material : Symbol = :regular)
end
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `content` | `View?` | `nil` | Content layered on top of glass |
| `material` | `Symbol` | `:regular` | Blur intensity: `:thin`, `:ultra_thin`, `:regular`, `:thick`, `:chrome` |
| `is_vibrant` | `Bool` | `true` | Enable vibrancy effect (Apple platforms) |

---

## Shapes and Drawing

These are P3 components with defined Crystal APIs; renderer support is being added.

---

### `UI::Circle`

**File:** `src/ui/views/circle.cr`

```crystal
class UI::Circle < UI::View
  property fill_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property stroke_color : Color? = nil
  property stroke_width : Float64 = 0.0
  property size : Float64 = 50.0

  def initialize(@size : Float64 = 50.0)
end
```

---

### `UI::Rectangle`

**File:** `src/ui/views/rectangle.cr`

```crystal
class UI::Rectangle < UI::View
  property fill_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property stroke_color : Color? = nil
  property stroke_width : Float64 = 0.0
  property width : Float64 = 100.0
  property height : Float64 = 50.0

  def initialize(@width : Float64 = 100.0, @height : Float64 = 50.0)
end
```

---

### `UI::RoundedRectangle`

**File:** `src/ui/views/rounded_rectangle.cr`

```crystal
class UI::RoundedRectangle < UI::View
  property fill_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property stroke_color : Color? = nil
  property stroke_width : Float64 = 0.0
  property corner_radius : Float64
  property corner_style : Symbol = :continuous  # :continuous, :circular
  property width : Float64 = 100.0
  property height : Float64 = 50.0

  def initialize(@corner_radius : Float64 = 8.0, @width : Float64 = 100.0, @height : Float64 = 50.0)
end
```

---

### `UI::Capsule`

**File:** `src/ui/views/capsule.cr`

A rectangle with fully rounded ends.

```crystal
class UI::Capsule < UI::View
  property fill_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property stroke_color : Color? = nil
  property stroke_width : Float64 = 0.0
  property width : Float64 = 100.0
  property height : Float64 = 40.0

  def initialize(@width : Float64 = 100.0, @height : Float64 = 40.0)
end
```

---

### `UI::Canvas`

**File:** `src/ui/views/canvas.cr`

An imperative 2D drawing surface.

```crystal
enum UI::DrawCommand
  MoveTo; LineTo; Arc; QuadCurveTo; BezierCurveTo; ClosePath
  Fill; Stroke; SetFillColor; SetStrokeColor; SetLineWidth; BeginPath
end

record UI::CanvasOp,
  command : DrawCommand,
  x : Float64 = 0.0, y : Float64 = 0.0,
  x2 : Float64 = 0.0, y2 : Float64 = 0.0,
  x3 : Float64 = 0.0, y3 : Float64 = 0.0,
  radius : Float64 = 0.0,
  start_angle : Float64 = 0.0, end_angle : Float64 = 0.0,
  color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)

class UI::Canvas < UI::View
  property width : Float64 = 300.0
  property height : Float64 = 150.0
  property operations : Array(CanvasOp) = [] of CanvasOp

  def initialize(@width : Float64 = 300.0, @height : Float64 = 150.0)

  def begin_path
  def move_to(x : Float64, y : Float64)
  def line_to(x : Float64, y : Float64)
  def arc(x : Float64, y : Float64, radius : Float64, start_angle : Float64 = 0.0, end_angle : Float64 = Math::PI * 2)
  def fill(color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0))
  def stroke(color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0), width : Float64 = 1.0)
  def close_path
end
```

**Example:**
```crystal
canvas = UI::Canvas.new(200.0, 200.0)
canvas.begin_path
canvas.arc(100.0, 100.0, 50.0)
canvas.fill(UI::Color.new(r: 0.0, g: 0.478, b: 1.0))
canvas.stroke(UI::Color.new(r: 0.0, g: 0.0, b: 0.0), 2.0)
```

---

### `UI::PathView`

**File:** `src/ui/views/path_view.cr`

A placeholder for vector path rendering. API to be expanded.

```crystal
class UI::PathView < UI::View
  def initialize
end
```

---

## Media and Interactive (P3 Stubs)

---

### `UI::MapView`

**File:** `src/ui/views/map_view.cr`

```crystal
class UI::MapView < UI::View
  property latitude : Float64 = 0.0
  property longitude : Float64 = 0.0
  property zoom_level : Float64 = 10.0

  def initialize
end
```

---

### `UI::ChartView`

**File:** `src/ui/views/chart_view.cr`

```crystal
class UI::ChartView < UI::View
  property chart_type : Symbol = :bar  # :bar, :line, :pie

  def initialize
end
```

---

### `UI::WebViewComponent`

**File:** `src/ui/views/web_view.cr`

Embeds a web page inside a native view. Note: class name is `WebViewComponent`.

```crystal
class UI::WebViewComponent < UI::View
  property url : String = ""

  def initialize(@url : String = "")
end
```

---

### `UI::ColorPicker`

**File:** `src/ui/views/color_picker.cr`

```crystal
class UI::ColorPicker < UI::View
  property selected_color : Color = Color.new(r: 0.0, g: 0.0, b: 0.0)
  property on_change : Proc(Color, Nil)? = nil

  def initialize
end
```

---

### `UI::VideoPlayer`

**File:** `src/ui/views/video_player.cr`

```crystal
class UI::VideoPlayer < UI::View
  property url : String = ""
  property is_playing : Bool = false
  property shows_controls : Bool = true

  def initialize(@url : String = "")
end
```

---

### `UI::Tooltip`

**File:** `src/ui/views/tooltip.cr`

```crystal
class UI::Tooltip < UI::View
  property text : String = ""
  property content : View? = nil

  def initialize(@text : String = "")
end
```

---

## Theme System

### `UI::Theme`

**File:** `src/ui/theme.cr`

A Material Design 3 semantic color/typography/shape theme.

```crystal
class UI::Theme
  # Semantic color roles (Material Design 3)
  property primary : ThemeColor
  property on_primary : ThemeColor
  property primary_container : ThemeColor
  property on_primary_container : ThemeColor
  property secondary : ThemeColor
  property on_secondary : ThemeColor
  property secondary_container : ThemeColor
  property on_secondary_container : ThemeColor
  property tertiary : ThemeColor
  property on_tertiary : ThemeColor
  property tertiary_container : ThemeColor
  property on_tertiary_container : ThemeColor
  property error : ThemeColor
  property on_error : ThemeColor
  property error_container : ThemeColor
  property on_error_container : ThemeColor
  property background : ThemeColor
  property on_background : ThemeColor
  property surface : ThemeColor
  property on_surface : ThemeColor
  property surface_variant : ThemeColor
  property on_surface_variant : ThemeColor
  property outline : ThemeColor
  property outline_variant : ThemeColor
  property inverse_surface : ThemeColor
  property inverse_on_surface : ThemeColor

  # Typography
  property font_family : String = "system"
  property font_size_body : Float64 = 16.0
  property font_size_title : Float64 = 22.0
  property font_size_headline : Float64 = 28.0
  property font_size_caption : Float64 = 12.0

  # Shape
  property corner_radius_small : Float64 = 4.0
  property corner_radius_medium : Float64 = 8.0
  property corner_radius_large : Float64 = 16.0

  def initialize

  # Factory methods
  def self.apple_default : Theme      # Apple HIG defaults, system blue, -apple-system font
  def self.material_baseline : Theme  # Material Design 3 purple, Roboto, MD3 corner radii

  # Web output
  def to_css_custom_properties : String  # emits :root { --md-sys-color-* ... } CSS block
end
```

**Usage:**
```crystal
# Apple theme
theme = UI::Theme.apple_default
theme.primary  # => ThemeColor for system blue
theme.font_family  # => "-apple-system"

# Material theme
theme = UI::Theme.material_baseline
theme.primary  # => ThemeColor for M3 purple
theme.font_family  # => "Roboto"

# Generate CSS variables for web rendering
css = theme.to_css_custom_properties
# => ":root { --md-sys-color-primary: rgba(102, 79, 163, 1.0); ... }"

# Custom theme
theme = UI::Theme.new
theme.primary = UI::ThemeColor.new(r: 0.8, g: 0.2, b: 0.2)  # red primary
```

---

## PlatformVisitor Abstract Interface

**File:** `src/ui/platform_visitor.cr`

Every platform renderer implements this abstract class, providing one `visit` method per view type. Adding a new view type requires adding one `abstract def visit(view : NewType)` here and implementing it in each renderer.

```crystal
abstract class UI::PlatformVisitor
  # P0 Base
  abstract def visit(view : Label)
  abstract def visit(view : Button)
  abstract def visit(view : VStack)
  abstract def visit(view : HStack)
  abstract def visit(view : ZStack)
  abstract def visit(view : Image)
  abstract def visit(view : TextField)
  abstract def visit(view : ScrollView)
  abstract def visit(view : Spacer)
  # Selection
  abstract def visit(view : Toggle)
  abstract def visit(view : Checkbox)
  abstract def visit(view : RadioGroup)
  abstract def visit(view : Slider)
  abstract def visit(view : Stepper)
  abstract def visit(view : SegmentedControl)
  # Navigation
  abstract def visit(view : NavigationStack)
  abstract def visit(view : NavigationLink)
  abstract def visit(view : TabView)
  abstract def visit(view : NavigationSplitView)
  abstract def visit(view : Toolbar)
  # Feedback & Input
  abstract def visit(view : ProgressView)
  abstract def visit(view : ActivityIndicator)
  abstract def visit(view : Alert)
  abstract def visit(view : Picker)
  abstract def visit(view : IconButton)
  abstract def visit(view : ListView)
  abstract def visit(view : SecureField)
  abstract def visit(view : SearchField)
  abstract def visit(view : TextArea)
  abstract def visit(view : TextEditor)
  # Advanced Controls
  abstract def visit(view : DatePicker)
  abstract def visit(view : TimePicker)
  abstract def visit(view : Grid)
  abstract def visit(view : Form)
  abstract def visit(view : AsyncImage)
  abstract def visit(view : RichText)
  abstract def visit(view : LinkButton)
  abstract def visit(view : MenuButton)
  abstract def visit(view : ToggleButton)
  # Modals & Overlays
  abstract def visit(view : Sheet)
  abstract def visit(view : Popover)
  abstract def visit(view : ConfirmationDialog)
  abstract def visit(view : Snackbar)
  # Containers & Visual
  abstract def visit(view : Card)
  abstract def visit(view : Surface)
  abstract def visit(view : Divider)
  abstract def visit(view : GlassBackground)
  # P3 Shapes & Drawing
  abstract def visit(view : Circle)
  abstract def visit(view : Rectangle)
  abstract def visit(view : RoundedRectangle)
  abstract def visit(view : Capsule)
  abstract def visit(view : Canvas)
  abstract def visit(view : PathView)
  # P3 Media & Specialized
  abstract def visit(view : MapView)
  abstract def visit(view : ChartView)
  abstract def visit(view : WebViewComponent)
  abstract def visit(view : ColorPicker)
  abstract def visit(view : VideoPlayer)
  abstract def visit(view : Tooltip)
end
```

Each concrete `View` subclass implements `accept` as:

```crystal
def accept(visitor : PlatformVisitor)
  visitor.visit(self)
end
```

---

## View Composition Patterns

### Building Trees with `<<`

Container views (`VStack`, `HStack`, `ZStack`) support the `<<` operator:

```crystal
stack = UI::VStack.new
stack << UI::Label.new("Line 1")
stack << UI::Label.new("Line 2")
```

### Nesting Containers

```crystal
page = UI::VStack.new(spacing: 20.0)

header = UI::HStack.new
header << UI::Image.new("logo")
header << UI::Spacer.new
header << UI::Button.new("Menu") { nil }
page << header

content = UI::ScrollView.new
body = UI::VStack.new(spacing: 8.0)
body << UI::Label.new("Article title")
body << UI::Label.new("Article body text...")
content.content = body
page << content
```

### Setting Common Properties

All `View` base properties can be set on any view type:

```crystal
card = UI::VStack.new(spacing: 12.0)
card.id = "main-card"
card.padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
card.background = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)
card.corner_radius = 12.0
card.shadow_radius = 4.0
card.shadow_color = UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.15)
card.shadow_offset_y = 2.0
```

### Callback Patterns

**Button `on_tap` (`Proc(Nil)`):**
```crystal
btn = UI::Button.new("Tap Me") { handle_tap; nil }

btn = UI::Button.new("Tap Me")
btn.on_tap = ->{ handle_tap; nil }
```

**TextField / TextArea / SearchField `on_change` (`Proc(String, Nil)`):**
```crystal
field = UI::TextField.new("Search") { |text| filter(text); nil }

field = UI::TextField.new("Search")
field.on_change = ->(text : String) { filter(text); nil }
```

**Toggle / Checkbox `on_change` (`Proc(Bool, Nil)`):**
```crystal
toggle = UI::Toggle.new("Dark Mode") { |on| apply_theme(on); nil }
```

**Slider `on_change` (`Proc(Float64, Nil)`):**
```crystal
slider = UI::Slider.new(0.0, 1.0) { |v| set_value(v); nil }
```

**Picker / RadioGroup / SegmentedControl `on_change` (`Proc(Int32, Nil)`):**
```crystal
picker = UI::Picker.new(["A", "B", "C"]) { |i| select_option(i); nil }
```

**DatePicker / TimePicker `on_change` (`Proc(Time, Nil)`):**
```crystal
dp = UI::DatePicker.new { |t| schedule_for(t); nil }
```
