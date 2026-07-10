---
name: component-mapping-matrix
description: |
  Comprehensive cross-platform UI component mapping matrix showing how every common
  UI pattern maps across Crystal UI::View, SwiftUI, UIKit, AppKit, Jetpack Compose,
  Android Views, and Web HTML/CSS. Implementation priority guide for expanding the
  asset_pipeline cross-platform component system.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
version: "2.0.0"
---

# Component Mapping Matrix

This is the master reference for expanding the asset_pipeline cross-platform UI component system. Every row represents one component and shows its exact native equivalent on every supported platform.

### See also: Apple Platform Guide

For each `UI::View` below, the **`apple-platform-guide` skill** contains a developer-facing usage doc at `components/<slug>.md` covering: feel-of-the-flow, Quickstart code, Customization table (all knobs + theme tokens), feel recipes, platform behavior, and HIG citations. The slug is the HIG page slug (e.g. `UI::Button` → `components/buttons.md`; `UI::MenuButton` → `components/pop-up-buttons.md`). When this matrix tells you *what to map*, the platform guide tells you *how to use it and why*.

Raw HIG markdown for every component lives in the **`apple-hig` skill** at `pages/<slug>.md`.

---

## 1. How to Read This Matrix

### Columns

| Column | Meaning |
|--------|---------|
| **Crystal UI::View** | The abstract class name in `src/ui/views/`. This is what app developers write. |
| **Priority** | P0 = done/implemented, P3 = specialized stubs being upgraded. See Section 3. |
| **SwiftUI** | Apple's declarative framework equivalent. Useful for cross-referencing SwiftUI docs when designing the Crystal API. |
| **UIKit** | The imperative iOS class our ObjC bridge instantiates on `flag?(:ios)`. Exact class names for `objc_getClass()`. |
| **AppKit** | The imperative macOS class our ObjC bridge instantiates on `flag?(:macos)`. Exact class names for `objc_getClass()`. |
| **Compose** | Android Jetpack Compose function equivalent. Reference for the future declarative Android renderer. |
| **Android View** | The imperative Android class our JNI bridge instantiates on `flag?(:android)`. Exact class names for JNI `FindClass()`. |
| **Web HTML/CSS** | The HTML element and CSS our `Web::Renderer` emits. |

### Priority Tiers

- **P0** — Fully implemented. Working and tested across all 4 platform renderers.
- **Implemented** — Class exists with full API; P3 stubs being upgraded to full renderer support in parallel.

### Using This Matrix for Implementation

When adding a new component, use this matrix to:
1. Confirm all 4 platform equivalents before writing any Crystal code.
2. Note any platform divergences in the "Notes" column before designing the abstract API.
3. Track implementation status by updating the priority to P0 once all renderers are complete.
4. Identify which renderer visit methods to add (`abstract def visit(view : NewView)` in `PlatformVisitor`).

---

## 2. Complete Mapping Matrix

### Text Display

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::Label` | **P0** | `Text` | `UILabel` | `NSTextField` (non-editable, no bezel, no background) | `Text()` | `TextView` | `<span>` with inline font/color styles | Done. AppKit uses NSTextField configured as a label, not NSText. |
| `UI::RichText` | **P0** | `Text` with `.attributedString` | `UITextView` (non-editable) | `NSTextView` (non-editable) | `AnnotatedString` in `Text()` | `TextView` with `SpannableString` | `<p>` or `<div>` with inner HTML | `Span` records with bold/italic/underline/strikethrough/link. `add_span()` builder. `plain_text` helper. |
| `UI::TextEditor` | **P0** | `TextEditor` | `UITextView` (editable) | `NSTextView` (editable) | `TextField(minLines=3)` or `BasicTextField` | `EditText` (multiline) | `<textarea>` | Multiline editor with optional line numbers and syntax highlighting hint. |

### Text Input

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::TextField` | **P0** | `TextField` | `UITextField` | `NSTextField` (editable) / `NSSecureTextField` for `secure_entry` | `TextField()` / `OutlinedTextField()` | `EditText` | `<input type="text">` or `<input type="password">` | Done. `secure_entry` property switches to NSSecureTextField / UITextField secureTextEntry / EditText inputType=textPassword. |
| `UI::SecureField` | **P0** | `SecureField` | `UITextField` (secureTextEntry=true) | `NSSecureTextField` | `TextField(visualTransformation=PasswordVisualTransformation)` | `EditText` (inputType=textPassword) | `<input type="password">` | Dedicated type for type-safe visitor dispatch. Always secure. |
| `UI::SearchField` | **P0** | `searchable()` modifier + `TextField` | `UISearchBar` or `UISearchTextField` (iOS 13+) | `NSSearchField` | `SearchBar()` or `DockedSearchBar()` | `SearchView` | `<input type="search">` | Has `on_submit` and `on_cancel` callbacks in addition to `on_change`. |
| `UI::TextArea` | **P0** | `TextEditor` | `UITextView` (editable) | `NSTextView` (editable) | `TextField(minLines=N)` | `EditText` (multiline, scrollbars) | `<textarea rows="N">` | Multiline text input with `line_limit`, `is_editable`, `is_scrollable`. |

### Buttons and Actions

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::Button` | **P0** | `Button` | `UIButton` (system style) | `NSButton` (bezelStyle=rounded) | `Button()` / `ElevatedButton()` | `MaterialButton` / `Button` | `<button type="button">` | Done. Foreground color, disabled state, on_tap callback. |
| `UI::IconButton` | **P0** | `Button { Image(...) }` | `UIButton` with `setImage:forState:` | `NSButton` with image + no title | `IconButton()` | `ImageButton` | `<button><img src=...></button>` or `<button class="icon-btn">` | SF Symbol / material icon / CSS icon class by platform. `icon_size`, `tint_color`, `disabled`. |
| `UI::LinkButton` | **P0** | `Link` | `UIButton` with URL action | `NSButton` + `NSWorkspace.openURL:` | `TextButton()` styled as link, or `ClickableText` | `Button` with URL intent | `<a href="...">` | `url` property. `opens_in_browser` flag. Optional `on_tap` override. |
| `UI::MenuButton` | **P0** | `Menu` | `UIMenu` + `UIButton` (iOS 14+ `menu` property) | `NSPopUpButton` | `DropdownMenu { ... }` | `PopupMenu` or `DropdownMenu` | `<select>` or custom `<div>` dropdown | `MenuItem` records with `is_destructive` flag. `add_item()` builder methods. |
| `UI::ToggleButton` | **P0** | `Toggle` (button style) | `UIButton` (checkboxConfiguration / selected state) | `NSButton` (buttonType=switch or toggle) | `FilledTonalButton()` with toggle state | `ToggleButton` | `<button aria-pressed="true/false">` | `is_selected`, `icon`, `on_toggle : Proc(Bool, Nil)`. `toggle()` convenience method. |

### Layout Containers

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::VStack` | **P0** | `VStack` | `UIStackView` (axis=.vertical) | `NSStackView` (orientation=vertical, 1) | `Column()` | `LinearLayout` (orientation=VERTICAL) | `<div style="display:flex;flex-direction:column">` | Done. Spacing and alignment supported. |
| `UI::HStack` | **P0** | `HStack` | `UIStackView` (axis=.horizontal) | `NSStackView` (orientation=horizontal, 0) | `Row()` | `LinearLayout` (orientation=HORIZONTAL) | `<div style="display:flex;flex-direction:row">` | Done. |
| `UI::ZStack` | **P0** | `ZStack` | `UIView` + Auto Layout constraints (or manual frames) | `NSView` + addSubview + autoresizing mask | `Box()` | `FrameLayout` | `<div style="position:relative">` with children `position:absolute` | Done. Children stack back-to-front in document order. |
| `UI::ScrollView` | **P0** | `ScrollView` | `UIScrollView` | `NSScrollView` | `LazyColumn()` / `LazyRow()` / `ScrollableColumn()` | `ScrollView` (vertical only) / `HorizontalScrollView` | `<div style="overflow:auto">` | Done. scroll_horizontal + scroll_vertical properties. Android ScrollView only scrolls one axis; HorizontalScrollView for horizontal. |
| `UI::Spacer` | **P0** | `Spacer` | `UILayoutGuide` (flexible space) or `UIView` with low compression | NSView with low hugging priority inside NSStackView | `Spacer()` | `Space` with `layout_weight=1` | `<div style="flex:1 1 0%">` | Done. min_length property sets minimum size. |
| `UI::Grid` | **P0** | `LazyVGrid` / `LazyHGrid` | `UICollectionView` with `UICollectionViewFlowLayout` | `NSCollectionView` with `NSCollectionViewGridLayout` | `LazyVerticalGrid()` / `LazyHorizontalGrid()` | `RecyclerView` with `GridLayoutManager` | CSS Grid: `<div style="display:grid;grid-template-columns:...">` | `Column` records with alignment + minimum_width. `add_row()` builder. `row_count`/`column_count` helpers. |
| `UI::ListView` | **P0** | `List` | `UITableView` or `UICollectionView` (iOS 14+ list) | `NSTableView` or `NSOutlineView` | `LazyColumn { items(...) }` | `RecyclerView` with `LinearLayoutManager` | `<ul>` or `<div>` with repeated child elements | `Section` records with header/footer. `ListView.flat()` convenience constructor. `on_item_tap : Proc(Int32, Int32, Nil)`. |
| `UI::Form` | **P0** | `Form` | `UITableView` (grouped / inset-grouped style) | `NSForm` or sectioned `NSTableView` | `Column()` with Section grouping | `RecyclerView` with section headers | `<form>` with fieldsets or Material-style card groupings | `FormSection` + `Field` records. `add_section()` builder. `field_count` helper. |

### Navigation

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::NavigationStack` | **P0** | `NavigationStack` | `UINavigationController` | `No direct equivalent` — use `NSWindowController` or `NSViewController` stack | `NavHost` + `NavController` | `FragmentManager` + back stack, or Navigation Component | Browser history + `<div>` visibility toggle | `push(view)`, `pop`, `pop_to_root`, `current_view`. `large_title`, `shows_navigation_bar` properties. |
| `UI::TabView` | **P0** | `TabView` | `UITabBarController` | `NSTabViewController` | `TabRow()` + `Scaffold(bottomBar=...)` | `BottomNavigationView` or `TabLayout` + `ViewPager2` | `<nav>` with tab styling or custom CSS tabs | `Tab` record with label/icon/content. `current_content` helper. `on_change : Proc(Int32, Nil)`. |
| `UI::NavigationSplitView` | **P0** | `NavigationSplitView` | `UISplitViewController` | `NSSplitViewController` | `NavigationSuiteScaffold` | `SlidingPaneLayout` or `NavigationDrawer` | CSS two-column layout or `<aside>` + `<main>` | sidebar/content/detail columns. `sidebar_width`, `shows_sidebar`, `column_visibility` (`:all`, `:double_column`, `:detail_only`). |
| `UI::NavigationLink` | **P0** | `NavigationLink` | `UINavigationController.pushViewController:` | No direct equivalent — trigger `NSViewController` presentation | `navController.navigate("route")` | `startActivity()` or `navController.navigate()` | `<a href="...">` or JS router `navigate()` | `label`, `destination`, `icon`, `shows_disclosure`. Pairs with NavigationStack. |
| `UI::Toolbar` | **P0** | `.toolbar {}` modifier | `UINavigationItem` toolbar / `UIToolbar` | `NSToolbar` | `TopAppBar()` / `CenterAlignedTopAppBar()` | `Toolbar` (androidx.appcompat) | `<header>` or `<nav>` with action buttons | `ToolbarItem` records. `add_item()` builder. `title`, `shows_title`. |

### Selection Controls

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::Toggle` | **P0** | `Toggle` | `UISwitch` | `NSButton` (buttonType=switch, setButtonType: 6) | `Switch()` | `SwitchMaterial` / `Switch` (androidx) | `<input type="checkbox" role="switch">` | `ToggleStyle` enum: `:Switch` or `:Checkbox`. `is_on`, `label`, `tint_color`, `on_change : Proc(Bool, Nil)`. |
| `UI::Checkbox` | **P0** | `Toggle` (checkbox style via `.toggleStyle(.checkbox)`) | No native UICheckbox — use `UIButton` with custom checkmark image | `NSButton` (buttonType=check, setButtonType: 3) | `Checkbox()` | `CheckBox` (android.widget) | `<input type="checkbox">` | `is_checked`, `label`, `on_change : Proc(Bool, Nil)`. |
| `UI::RadioGroup` | **P0** | `Picker` with `.pickerStyle(.radioGroup)` | No native UIRadioButton — use `UIButton` with selection state management | `NSButton` (buttonType=radio, setButtonType: 4) | `RadioButton()` inside `RadioGroup` | `RadioButton` + `RadioGroup` | `<input type="radio" name="group">` | `options : Array(String)`, `selected_index`, `on_change : Proc(Int32, Nil)`. Self-contained group. |
| `UI::Slider` | **P0** | `Slider` | `UISlider` | `NSSlider` | `Slider()` | `SeekBar` or `Slider` (material) | `<input type="range">` | `minimum`, `maximum`, `value`, `step` (0 = continuous), `label`, `tint_color`, `on_change : Proc(Float64, Nil)`. |
| `UI::Stepper` | **P0** | `Stepper` | `UIStepper` | `NSStepper` | No direct Compose equivalent — `Row` with `-`/`+` buttons | No native stepper — compose from `Button` + `TextView` + `Button` | `<input type="number">` or custom `-`/`+` buttons | `value`, `minimum`, `maximum`, `step_value`, `wraps`, `label`, `on_change`. `increment()`/`decrement()` helpers. |
| `UI::SegmentedControl` | **P0** | `Picker` with `.pickerStyle(.segmented)` | `UISegmentedControl` | `NSSegmentedControl` | `SegmentedButton()` (Material 3) | `RadioGroup` styled, or Material `SegmentedButton` | Custom CSS button group | `segments : Array(String)`, `selected_index`, `on_change`. `selected_segment` helper. |

### Pickers

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::Picker` | **P0** | `Picker` (default / wheel / menu style) | `UIPickerView` (wheel) or `UIButton` + `UIMenu` | `NSPopUpButton` | `ExposedDropdownMenuBox()` | `Spinner` or `AutoCompleteTextView` (dropdown) | `<select>` | `PickerStyle` enum: `Wheel`, `Segmented`, `Menu`, `Inline`. `selected_option` helper. |
| `UI::DatePicker` | **P0** | `DatePicker` | `UIDatePicker` (inline / compact / wheels styles) | `NSDatePicker` (text / stepper / clock display modes) | `DatePicker()` (Material dialogs) | `DatePickerDialog` or Material `DatePicker` | `<input type="date">` | `DatePickerMode` enum: `Date`, `Time`, `DateAndTime`. `minimum_date`/`maximum_date` bounds. `on_change : Proc(Time, Nil)`. |
| `UI::TimePicker` | **P0** | `DatePicker` (displayedComponents: .hourAndMinute) | `UIDatePicker` (.countDownTimer or hourAndMinute mode) | `NSDatePicker` (hour/minute display mode) | `TimePicker()` (Material dialogs) | `TimePickerDialog` or Material `TimePicker` | `<input type="time">` | `shows_24_hour`, `minute_interval`, `on_change : Proc(Time, Nil)`. |
| `UI::ColorPicker` | Implemented | `ColorPicker` | No native UIColorPicker in older iOS — use `UIColorPickerViewController` (iOS 14+) | `NSColorPanel` (singleton) or `NSColorWell` | No native Compose equivalent — custom or third-party | No native Android color picker — third-party library typically used | `<input type="color">` | `selected_color : Color`, `on_change : Proc(Color, Nil)`. P3 stub being upgraded. |

### Progress and Activity

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::ProgressView` | **P0** | `ProgressView(value:total:)` | `UIProgressView` | `NSProgressIndicator` (style=bar, indeterminate=false) | `LinearProgressIndicator()` | `ProgressBar` (horizontal style, android.widget) | `<progress value="X" max="Y">` | `ProgressStyle` enum: `Linear`, `Circular`. `value : Float64?` (nil = indeterminate). `tint_color`, `label`. |
| `UI::ActivityIndicator` | **P0** | `ProgressView()` (no value, spinner style) | `UIActivityIndicatorView` | `NSProgressIndicator` (style=spinning, indeterminate=true) | `CircularProgressIndicator()` | `ProgressBar` (circular / indeterminate style) | `<div class="spinner">` with CSS animation | `is_animating`, `size : Symbol` (`:small`, `:medium`, `:large`), `color`. |

### Images and Media

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::Image` | **P0** | `Image` | `UIImageView` | `NSImageView` | `Image()` (via `AsyncImage` or `painterResource`) | `ImageView` | `<img src="...">` | Done. source, content_mode, tint_color supported. |
| `UI::AsyncImage` | **P0** | `AsyncImage` | `UIImageView` + async download via `URLSession` | `NSImageView` + async download | `AsyncImage()` (Coil library integration) | `ImageView` + Glide / Coil / Picasso | `<img>` with lazy loading attribute, or CSS `background-image` loaded via JS fetch | `url`, `placeholder : View?`, `content_mode`, `is_loading`, `error_message`, `on_load`, `on_error : Proc(String, Nil)`. |
| `UI::VideoPlayer` | Implemented | `VideoPlayer` (AVKit) | `AVPlayerViewController` or `AVPlayerLayer` | `AVPlayerView` (AVKit on macOS) | `VideoPlayer()` (Media3 / ExoPlayer) | `VideoView` or `PlayerView` (Media3/ExoPlayer) | `<video src="...">` | `url`, `is_playing`, `shows_controls`. P3 stub being upgraded. |

### Visual Effects

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::GlassBackground` | **P0** | `.background(.ultraThinMaterial)` modifier | `UIVisualEffectView` (UIBlurEffect) | `NSVisualEffectView` | No direct equivalent — `BlurMask` modifier | No native blur/glass — compose with `RenderScript` or `BlurMaskFilter` (deprecated) | `backdrop-filter: blur(Xpx); background: rgba(...,0.5)` | `material` (`:thin`, `:ultra_thin`, `:regular`, `:thick`, `:chrome`), `is_vibrant`, `content`. |
| Shadow (base modifier) | **P0** | `.shadow(color:radius:x:y:)` modifier | `.layer.shadowColor`, `.layer.shadowRadius`, `.layer.shadowOffset` | `NSShadow` + `setShadow:` | `Modifier.shadow(elevation:)` | `setElevation()` for Material shadows or custom `Paint.setShadowLayer()` | `box-shadow: X Y blur spread color` | `shadow_radius`, `shadow_color`, `shadow_offset_x`, `shadow_offset_y` on `UI::View` base class. |
| Blur (base modifier) | **P0** | `.blur(radius:)` modifier | `UIVisualEffectView` or `CIFilter` blur on layer | `CIFilter` blur via Core Image | `Modifier.blur(radius:)` | `RenderEffect.createBlurEffect()` (Android 12+) | `filter: blur(Xpx)` on the element | `blur_radius` on `UI::View` base class. |
| Border (base modifier) | **P0** | `.border(_:width:)` modifier | `layer.borderColor` + `layer.borderWidth` | `NSView.layer.borderColor/Width` | `Modifier.border(width, color, shape)` | `setBackground(GradientDrawable)` with border | `border: Xpx solid color` CSS | `border_width`, `border_color` on `UI::View` base class. |
| Corner Radius (base modifier) | **P0** | `.cornerRadius(_:)` modifier | `layer.cornerRadius` | `layer.cornerRadius` | `Modifier.clip(RoundedCornerShape(...))` | `setBackground(GradientDrawable)` with corner radius | `border-radius: Xpx` CSS | `corner_radius`, `clip_to_bounds` on `UI::View` base class. |
| Opacity (base property) | **P0** | `.opacity(_:)` modifier | `.alpha` property on UIView | `setAlphaValue:` on NSView | `Modifier.alpha(alpha:)` | `setAlpha()` on View | `opacity: X` CSS property | `opacity` on `UI::View` base class. |

### Modals and Overlays

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::Alert` | **P0** | `Alert` via `.alert(...)` modifier | `UIAlertController` (style=alert) | `NSAlert` | `AlertDialog()` | `AlertDialog.Builder` | `<dialog>` element or custom modal overlay | `AlertButton` records with `label`, `style` (`:default`, `:destructive`, `:cancel`), `action`. `add_button()` builder. `is_presented`. |
| `UI::Sheet` | **P0** | `.sheet(isPresented:)` modifier | `UIViewController.present(_:animated:)` with `UISheetPresentationController` | `NSPanel` or `NSWindowController.beginSheet:` | `ModalBottomSheet()` | `BottomSheetDialogFragment` | Custom CSS overlay sliding up from bottom | `detents : Array(Symbol)` (`:small`, `:medium`, `:large`, `:custom`). `shows_drag_indicator`. Companion: `SheetPresenter`. |
| `UI::Popover` | **P0** | `.popover(isPresented:)` modifier | `UIPopoverPresentationController` | `NSPopover` | `Popup()` or custom positioned `Box` | `PopupWindow` | `<div>` positioned absolutely relative to anchor, or Popover API | `arrow_edge` (`:top`, `:bottom`, `:leading`, `:trailing`). `preferred_width/height`. Companion: `PopoverPresenter`. |
| `UI::ConfirmationDialog` | **P0** | `confirmationDialog(...)` modifier | `UIAlertController` (style=actionSheet) | `NSAlert` with multiple buttons | `AlertDialog()` with multiple actions | `AlertDialog.Builder` with multiple buttons | Custom `<dialog>` or modal with action buttons | `confirm_label`, `cancel_label`, `confirm_style` (`:default`, `:destructive`). `on_confirm`/`on_cancel` callbacks. |
| `UI::Snackbar` | **P0** | No direct SwiftUI equivalent — custom overlay | No native iOS Snackbar — custom view or third-party | No native macOS Snackbar — custom overlay | `SnackbarHost` + `Snackbar()` | `Snackbar` (Material, com.google.android.material) | Custom `<div>` with CSS animation, positioned at bottom | `message`, `action_label`, `duration` (seconds), `on_action`/`on_dismiss`. Companion: `SnackbarPresenter`. |
| `UI::Tooltip` | Implemented | `.help(...)` modifier (desktop only) | No standard iOS tooltip — `UITooltipInteraction` (iOS 17+) | `NSView.toolTip` property | `TooltipBox()` (experimental in Compose Multiplatform) | `TooltipCompat` (AppCompat, limited) | `title` attribute or custom CSS `:hover` tooltip | `text`, `content : View?`. P3 stub being upgraded. |

### Cards and Containers

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::Card` | **P0** | No named Card view — use `.background(.background, in: RoundedRectangle(...))` | No native UICard — compose from `UIView` with layer shadow + corner radius | No native NSCard — compose from `NSBox` or styled `NSView` | `Card()` | `MaterialCardView` (com.google.android.material) | `<div class="card">` with border-radius, shadow, background | `content : View?`, `elevation : Float64`, `is_outlined : Bool`. |
| `UI::Surface` | **P0** | No direct equivalent — use `background` modifier with `.background` style | `UIView` with background color and optional shadow | `NSBox` (titlePosition=none for a plain panel) | `Surface()` | `CardView` or plain `ViewGroup` with background | `<div>` with background color and optional border | `content`, `elevation`, `tonal_elevation`, `shape` (`:rectangle`, `:rounded`, `:circle`). Material Design Surface concept. |
| `UI::Divider` | **P0** | `Divider` | `UIView` with height=1 and background color | `NSBox` (boxType=separator) | `Divider()` | `View` with height=1dp and background color, or `DividerItemDecoration` in lists | `<hr>` or `<div style="height:1px;background:...">` | `color`, `thickness`, `orientation` (`:horizontal`, `:vertical`). |

### Shapes and Drawing

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::Circle` | Implemented | `Circle()` | `UIView` with `layer.cornerRadius = width/2` | `NSView` with oval `bezierPath` in `draw:` | `CircleShape` or `Box(Modifier.clip(CircleShape))` | `ShapeableImageView` or custom View with canvas draw | `<div style="border-radius:50%">` or SVG `<circle>` | `fill_color`, `stroke_color`, `stroke_width`, `size`. P3 stub being upgraded. |
| `UI::Rectangle` | Implemented | `Rectangle()` | `UIView` with rectangular frame | `NSView` with rectangle draw | `RectangleShape` or plain `Box` | Plain `View` with background color | `<div>` with dimensions | `fill_color`, `stroke_color`, `stroke_width`, `width`, `height`. P3 stub being upgraded. |
| `UI::RoundedRectangle` | Implemented | `RoundedRectangle(cornerRadius:)` | `UIView` with `layer.cornerRadius` | `NSView` with `NSBezierPath(roundedRect:xRadius:yRadius:)` | `RoundedCornerShape` | `ShapeableImageView` or `MaterialShapeDrawable` | `<div style="border-radius:Xpx">` | `corner_radius`, `corner_style` (`:continuous`, `:circular`), `width`, `height`, `fill_color`, `stroke_color`, `stroke_width`. P3 stub being upgraded. |
| `UI::Capsule` | Implemented | `Capsule()` | `UIView` with `layer.cornerRadius = min(width,height)/2` | `NSView` with capsule bezier path | `CapsuleShape` | `ShapeableImageView` with `CornerSize(50%)` | `<div style="border-radius:9999px">` | `fill_color`, `stroke_color`, `stroke_width`, `width`, `height`. P3 stub being upgraded. |
| `UI::Canvas` | Implemented | `Canvas { context, size in ... }` | Custom `UIView` subclass overriding `draw(_ rect:)` | Custom `NSView` subclass overriding `draw(_ dirtyRect:)` | `Canvas { drawScope -> ... }` | Custom `View` subclass overriding `onDraw(canvas:)` | `<canvas>` with 2D context API | `DrawCommand` enum. `CanvasOp` records. `move_to`, `line_to`, `arc`, `fill`, `stroke`, `begin_path`, `close_path` methods. P3 stub being upgraded. |
| `UI::PathView` | Implemented | `Path { path in ... }` | `UIBezierPath` | `NSBezierPath` | `Path()` with path builder | `Path` (android.graphics) | SVG `<path>` or Canvas path commands | Stub — API to be defined. P3 stub being upgraded. |

### Advanced and Specialized

| Crystal UI::View | Priority | SwiftUI | UIKit | AppKit | Compose | Android View | Web HTML/CSS | Notes |
|-----------------|----------|---------|-------|--------|---------|--------------|--------------|-------|
| `UI::MapView` | Implemented | `Map` (MapKit) | `MKMapView` (MapKit) | `MKMapView` (MapKit on macOS) | `GoogleMap()` (Maps SDK) or `MapLibre` | `SupportMapFragment` (Google Maps) or `MapView` | `<div id="map">` + Leaflet.js / Google Maps JS API / Mapbox | `latitude`, `longitude`, `zoom_level`. P3 stub being upgraded. |
| `UI::ChartView` | Implemented | `Chart` (Swift Charts, iOS 16+/macOS 13+) | `DKLineChartView` or third-party | Same as iOS via Swift Charts | `Canvas` with custom draw or Vico / MPAndroidChart library | `MPAndroidChart` or Vico library | Chart.js, D3.js, or native `<canvas>` | `chart_type : Symbol` (`:bar`, `:line`, `:pie`). P3 stub being upgraded. |
| `UI::WebViewComponent` | Implemented | `WebView` (WebKit, macOS/iOS only) | `WKWebView` (WebKit) | `WKWebView` (WebKit on macOS) | `AndroidView { WebView(context) }` | `WebView` (android.webkit) | `<iframe>` or direct page content | `url`. Note: class name is `WebViewComponent` (not `WebView`). P3 stub being upgraded. |

---

## 3. Implementation Status

### Fully Implemented (P0) — 47 components + 5 base modifier groups

All of the following have classes in `src/ui/views/`, `visit` methods in `PlatformVisitor`, and are implemented across all four renderer files.

**P0 Base (9):** `Label`, `Button`, `VStack`, `HStack`, `ZStack`, `Image`, `TextField`, `ScrollView`, `Spacer`

**P0 Selection (6):** `Toggle`, `Checkbox`, `RadioGroup`, `Slider`, `Stepper`, `SegmentedControl`

**P0 Navigation (5):** `NavigationStack`, `NavigationLink`, `TabView`, `NavigationSplitView`, `Toolbar`

**P0 Feedback & Input (10):** `ProgressView`, `ActivityIndicator`, `Alert`, `Picker`, `IconButton`, `ListView`, `SecureField`, `SearchField`, `TextArea`, `TextEditor`

**P0 Advanced Controls (8):** `DatePicker`, `TimePicker`, `Form`, `Grid`, `AsyncImage`, `RichText`, `LinkButton`, `MenuButton`, `ToggleButton`

**P0 Containers & Visual (9):** `Sheet`, `Popover`, `ConfirmationDialog`, `Snackbar`, `Card`, `Surface`, `Divider`, `GlassBackground`

**P0 Base Class Modifiers (5 groups):** `shadow_*`, `blur_radius`, `border_*`, `corner_radius`/`clip_to_bounds`, `opacity`

**Presenter Companions (3):** `SheetPresenter`, `PopoverPresenter`, `SnackbarPresenter`

**Theme System:** `UI::Theme` with `apple_default` and `material_baseline` factory methods, full `ThemeColor` semantic roles, typography, shape scales, and `to_css_custom_properties`.

### Implemented (Stubs Being Upgraded) — 12 P3 components

| View | Crystal Class | File |
|------|---------------|------|
| Circle | `UI::Circle` | `src/ui/views/circle.cr` |
| Rectangle | `UI::Rectangle` | `src/ui/views/rectangle.cr` |
| RoundedRectangle | `UI::RoundedRectangle` | `src/ui/views/rounded_rectangle.cr` |
| Capsule | `UI::Capsule` | `src/ui/views/capsule.cr` |
| Canvas | `UI::Canvas` | `src/ui/views/canvas.cr` |
| PathView | `UI::PathView` | `src/ui/views/path_view.cr` |
| MapView | `UI::MapView` | `src/ui/views/map_view.cr` |
| ChartView | `UI::ChartView` | `src/ui/views/chart_view.cr` |
| WebViewComponent | `UI::WebViewComponent` | `src/ui/views/web_view.cr` |
| ColorPicker | `UI::ColorPicker` | `src/ui/views/color_picker.cr` |
| VideoPlayer | `UI::VideoPlayer` | `src/ui/views/video_player.cr` |
| Tooltip | `UI::Tooltip` | `src/ui/views/tooltip.cr` |

---

## 4. Platform Divergence Notes

These are the cases where the same logical component concept requires meaningfully different approaches per platform. Understanding these divergences before implementing is critical to designing the right Crystal abstraction.

### Navigation — The Biggest Divergence

Navigation is the single most platform-divergent UI concept.

| Platform | Navigation Paradigm | Root Container | Back Navigation |
|----------|--------------------|-----------------|-|
| iOS | Push/pop stack | `UINavigationController` | Swipe right or Back button in `UINavigationBar` |
| macOS | No standard push nav — windowed model | `NSWindowController` / view controller presentation | Close window, or custom back button in toolbar |
| Android | Fragment back stack or Navigation Component | `NavHostFragment` | System back button or gesture |
| Web | URL routing + browser history | `<div>` visibility or JS router | Browser back button / `history.back()` |

**Crystal Strategy:** `UI::NavigationStack` owns a stack of `UI::View` bodies and exposes `push(view)` / `pop()` / `pop_to_root` / `current_view`. Each renderer translates this to the platform pattern.

### Tab Navigation

| Platform | Tab Position | Root Container | Behavior |
|----------|-------------|-----------------|---------|
| iOS | Bottom (UITabBar) | `UITabBarController` | System-managed, touch targets, badge support |
| macOS | Top or segmented (NSTabViewController) | `NSTabViewController` | Top-of-window tabs or segmented control look |
| Android | Bottom (Material 3) or Top (Material 2) | `BottomNavigationView` or `TabLayout` | Bottom nav or sliding tabs |
| Web | Flexible — any position | Custom CSS | No system chrome |

### Modals

| Platform | Alert | Sheet | Action Sheet |
|----------|-------|-------|-------------|
| iOS | Centered dialog | Slides up from bottom (detents) | Slides up from bottom |
| macOS | Centered NSAlert panel | Slides down from title bar | NSAlert with multiple buttons |
| Android | `AlertDialog` (centered) | `BottomSheetDialogFragment` | `AlertDialog` with button list |
| Web | `<dialog>` element or custom | Custom overlay | Custom menu |

### Date/Time Pickers

| Platform | Date Picker Style | Presentation |
|----------|------------------|-------------|
| iOS | Inline calendar / compact tappable field / wheel | Inline or popover |
| macOS | Text field with stepper / calendar / clock face | Inline as a view widget |
| Android | Material DatePicker dialog | Modal dialog |
| Web | `<input type="date">` | Browser native UI |

The `UI::DatePicker` `mode` property (`DatePickerMode::Date`, `DatePickerMode::Time`, `DatePickerMode::DateAndTime`) lets each renderer map to the closest available native presentation.

### Progress Indicators

Both `UI::ProgressView` (determinate or indeterminate depending on `value`) and `UI::ActivityIndicator` (always indeterminate spinner) map to a single class on macOS — `NSProgressIndicator` — with different `isIndeterminate` and `style` settings.

### Glass / Blur Effects

| Platform | Native Blur Support | Implementation |
|----------|--------------------|-|
| iOS | Excellent — `UIVisualEffectView` | System-integrated, composited by GPU |
| macOS | Excellent — `NSVisualEffectView` | System-integrated, window-aware |
| Android | No native solution pre-Android 12 | `RenderEffect.createBlurEffect()` (API 31+); fallback: solid translucent color |
| Web | `backdrop-filter: blur()` | Wide support in modern browsers; GPU-accelerated |

`UI::GlassBackground` uses the `material` property (`:thin`, `:ultra_thin`, `:regular`, `:thick`, `:chrome`) to hint at blur intensity. The Android renderer checks API level and uses RenderEffect when available, falling back to a translucent solid color on older devices.

### Presenter Pattern for Modals

`Sheet`, `Popover`, and `Snackbar` use companion presenter classes rather than being placed directly in the view tree. This matches the platform paradigm where modals are presented imperatively:

```crystal
sheet = UI::Sheet.new(content: my_form)
presenter = UI::SheetPresenter.new(sheet)
presenter.present    # → sheet.is_presented = true
presenter.dismiss    # → sheet.is_presented = false, fires on_dismiss
```

---

## 5. Implementation Strategy

### Adding a New Renderer Visit Method (Step-by-Step)

For P3 components being upgraded from stubs to full implementations:

1. **Verify the Crystal API** — Read the existing class in `src/ui/views/new_view.cr`. API is already defined.

2. **Add to PlatformVisitor** — Add `abstract def visit(view : NewView)` to `src/ui/platform_visitor.cr`. This will cause compile errors in all renderer files until all `visit` methods are implemented — that is intentional.

3. **Implement Web renderer** — Add `def visit(view : UI::NewView)` to `src/ui/renderers/web_renderer.cr`. Web is usually the fastest to implement since it just emits HTML/CSS.

4. **Implement AppKit renderer** — Add `def visit(view : UI::NewView)` to `src/ui/renderers/appkit_renderer.cr`. Use `objc_getClass("NSClassName")` for the target class.

5. **Implement UIKit renderer** — Add `def visit(view : UI::NewView)` to `src/ui/renderers/uikit_renderer.cr`. Use `objc_getClass("UIClassName")` for the target class.

6. **Implement Android renderer** — Add `def visit(view : UI::NewView)` to `src/ui/renderers/android_renderer.cr`. Use JNI `FindClass` and `GetMethodID` for the target Android class.

7. **Write specs** — Add specs to `spec/ui/views/new_view_spec.cr` testing the Web renderer output at minimum.

8. **Update this matrix** — Change status from `Implemented` to `P0` in this file.

### Modifier System (Complete)

The `UI::View` base class already has a full modifier property set. All renderers apply these in their common-properties method:

```crystal
# UI::View base class modifier properties (all implemented)
property corner_radius : Float64 = 0.0
property clip_to_bounds : Bool = false
property shadow_radius : Float64 = 0.0
property shadow_color : Color? = nil
property shadow_offset_x : Float64 = 0.0
property shadow_offset_y : Float64 = 0.0
property border_width : Float64 = 0.0
property border_color : Color? = nil
property blur_radius : Float64 = 0.0
property minimum_width : Float64? = nil
property minimum_height : Float64? = nil
property maximum_width : Float64? = nil
property maximum_height : Float64? = nil
```

---

## 6. Coverage Statistics

### Current Coverage

| Status | Count | Description |
|--------|-------|-------------|
| P0 (fully implemented) | 47 views + 5 modifier groups + 3 presenters + Theme | Working across all 4 renderers |
| Implemented (stubs being upgraded) | 12 views | Crystal API defined; renderer support in progress |
| **Total view types** | **59** | Full cross-platform component vocabulary |

### Coverage by Category

| Category | Status | Views |
|----------|--------|-------|
| Text Display | P0 | Label, RichText, TextEditor |
| Text Input | P0 | TextField, SecureField, SearchField, TextArea |
| Buttons | P0 | Button, IconButton, LinkButton, MenuButton, ToggleButton |
| Layout | P0 | VStack, HStack, ZStack, ScrollView, Spacer, Grid, ListView, Form |
| Navigation | P0 | NavigationStack, NavigationLink, TabView, NavigationSplitView, Toolbar |
| Selection | P0 | Toggle, Checkbox, RadioGroup, Slider, Stepper, SegmentedControl |
| Pickers | P0 (except ColorPicker) | Picker, DatePicker, TimePicker + ColorPicker (Implemented) |
| Progress | P0 | ProgressView, ActivityIndicator |
| Images & Media | P0 (except VideoPlayer) | Image, AsyncImage + VideoPlayer (Implemented) |
| Visual Effects | P0 | GlassBackground + base modifier groups |
| Modals | P0 (except Tooltip) | Alert, Sheet, Popover, ConfirmationDialog, Snackbar + Tooltip (Implemented) |
| Cards & Containers | P0 | Card, Surface, Divider |
| Shapes & Drawing | Implemented | Circle, Rectangle, RoundedRectangle, Capsule, Canvas, PathView |
| Advanced & Specialized | Implemented | MapView, ChartView, WebViewComponent |
| Theme System | P0 | UI::Theme with apple_default, material_baseline |
