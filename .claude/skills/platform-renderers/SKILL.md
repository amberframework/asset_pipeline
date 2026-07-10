---
name: platform-renderers
description: How each platform renderer maps UI::View types to native elements across Web, macOS, iOS, and Android
version: "2.0"
---

# Platform Renderers

Each platform renderer is a subclass of `UI::PlatformVisitor` that translates the abstract `UI::View` tree into platform-native elements. Only one renderer is compiled into any given binary, selected at compile time via `flag?()`.

## Compile-Time Selection

```crystal
{% if flag?(:macos) %}
  require "./renderers/appkit_renderer"
  alias PlatformRenderer = UI::AppKit::Renderer
{% elsif flag?(:ios) %}
  require "./renderers/uikit_renderer"
  alias PlatformRenderer = UI::UIKit::Renderer
{% elsif flag?(:android) %}
  require "./renderers/android_renderer"
  alias PlatformRenderer = UI::Android::Renderer
{% else %}
  require "./renderers/web_renderer"
  alias PlatformRenderer = UI::Web::Renderer
{% end %}
```

---

## Web::Renderer

**Target file:** `src/ui/renderers/web_renderer.cr`
**Compiled when:** No platform flag set (default), or explicitly for web targets

The web renderer delegates to the existing `Components::Elements` classes in the asset_pipeline shard. It does NOT reimplement HTML generation -- it maps each `UI::View` to the appropriate `Components::Elements` class and applies CSS styles.

### View-to-Element Mapping

| UI::View | Components::Elements class | CSS applied |
|----------|---------------------------|-------------|
| `Label` | `Elements::Span` | `font-family`, `font-size`, `font-weight`, `color`, `text-align`, line clamping |
| `Button` | `Elements::Button` | Foreground color, `data-action` attribute for reactive dispatch |
| `VStack` | `Elements::Div` | `display:flex; flex-direction:column; gap:{spacing}px; align-items:{alignment}` |
| `HStack` | `Elements::Div` | `display:flex; flex-direction:row; gap:{spacing}px; align-items:{alignment}` |
| `ZStack` | `Elements::Div` | `position:relative` with `position:absolute` on children |
| `Image` | `Elements::Img` | `object-fit` mapped from `ContentMode` |
| `TextField` | `Elements::Input` | `.text` or `.password` factory depending on `secure_entry` |
| `ScrollView` | `Elements::Div` | `overflow-x`/`overflow-y` based on scroll axes |
| `Spacer` | `Elements::Div` | `flex:1 1 0%; min-height:{min_length}px` or `min-width:{min_length}px` |
| `Toggle` | `Elements::Input` | `type="checkbox" role="switch"` |
| `Checkbox` | `Elements::Input` | `type="checkbox"` with label |
| `RadioGroup` | `Elements::Div` | Multiple `<input type="radio" name="...">` with shared name |
| `Slider` | `Elements::Input` | `type="range" min max step` |
| `Stepper` | `Elements::Input` | `type="number" min max step` |
| `SegmentedControl` | `Elements::Div` | CSS button group with `aria-pressed` on active segment |
| `NavigationStack` | `Elements::Div` | JS-router `<div>` visibility toggling, browser history API |
| `NavigationLink` | `Elements::A` | `<a href="...">` with SPA router integration |
| `TabView` | `Elements::Div` | `role="tablist"` nav + `role="tabpanel"` content divs |
| `NavigationSplitView` | `Elements::Div` | `display:grid; grid-template-columns: {sidebar_width}px 1fr` |
| `Toolbar` | `Elements::Header` | `<header>` or `<nav>` with action `<button>` elements |
| `ProgressView` | `Elements::Div` | `<progress>` (determinate) or CSS spinner (indeterminate Circular) |
| `ActivityIndicator` | `Elements::Div` | CSS keyframe animation spinner |
| `Alert` | `Elements::Div` | `<dialog>` element or modal overlay div |
| `Picker` | `Elements::Select` | `<select>` with `<option>` children |
| `IconButton` | `Elements::Button` | `<button>` with icon `<img>` or CSS icon class |
| `ListView` | `Elements::Div` | `<ul>` or `<div>` with repeated child elements and section headers |
| `SecureField` | `Elements::Input` | `type="password"` |
| `SearchField` | `Elements::Input` | `type="search"` with cancel button |
| `TextArea` | `Elements::Div` | `<textarea rows="N">` |
| `TextEditor` | `Elements::Div` | `<textarea>` with optional syntax highlighting via CSS/JS |
| `DatePicker` | `Elements::Input` | `type="date"`, `type="time"`, or `type="datetime-local"` per mode |
| `TimePicker` | `Elements::Input` | `type="time"` with step for minute_interval |
| `Grid` | `Elements::Div` | `display:grid; grid-template-columns:...` with child cells |
| `Form` | `Elements::Form` | `<form>` with `<fieldset>`/`<legend>` per section |
| `AsyncImage` | `Elements::Img` | `<img loading="lazy">` with placeholder swap via JS |
| `RichText` | `Elements::Div` | Multiple `<span>` with inline styles per Span record |
| `LinkButton` | `Elements::A` | `<a href="...">` styled as button |
| `MenuButton` | `Elements::Div` | `<button>` + hidden `<ul>` dropdown, shown on click |
| `ToggleButton` | `Elements::Button` | `<button aria-pressed="true/false">` |
| `Sheet` | `Elements::Div` | Fixed overlay from bottom with CSS animation, `is_presented` toggles visibility |
| `Popover` | `Elements::Div` | Absolutely positioned `<div>` relative to anchor, Popover API when available |
| `ConfirmationDialog` | `Elements::Div` | `<dialog>` with confirm/cancel buttons |
| `Snackbar` | `Elements::Div` | Fixed-position `<div>` at bottom with CSS slide/fade animation |
| `Card` | `Elements::Div` | `border-radius`, `box-shadow`, `background-color` |
| `Surface` | `Elements::Div` | `background-color`, optional `border` |
| `Divider` | `Elements::Div` | `<hr>` or `<div style="height:1px;background:...">` |
| `GlassBackground` | `Elements::Div` | `backdrop-filter:blur(Xpx); background:rgba(...,0.5)` |
| `Circle` | `Elements::Div` | `border-radius:50%; width/height={size}px` or SVG `<circle>` |
| `Rectangle` | `Elements::Div` | `<div>` with explicit width/height and background |
| `RoundedRectangle` | `Elements::Div` | `border-radius:{corner_radius}px` |
| `Capsule` | `Elements::Div` | `border-radius:9999px` |
| `Canvas` | `Elements::Div` | `<canvas>` element; operations serialized to JS 2D context calls |
| `PathView` | `Elements::Div` | SVG `<path>` element (stub) |
| `MapView` | `Elements::Div` | `<div id="map">` + Leaflet.js / Google Maps JS API |
| `ChartView` | `Elements::Div` | `<canvas>` + Chart.js or D3.js integration |
| `WebViewComponent` | `Elements::Div` | `<iframe src="...">` |
| `ColorPicker` | `Elements::Input` | `type="color"` |
| `VideoPlayer` | `Elements::Div` | `<video src="..." controls>` |
| `Tooltip` | `Elements::Div` | `title` attribute or custom `:hover` CSS tooltip |

### CSS Strategy

- Layout CSS uses utility classes: `ui-vstack`, `ui-hstack`, `ui-spacer`, etc.
- Inline styles handle dynamic values (spacing, colors, fonts)
- Base class modifier properties (`corner_radius`, `shadow_*`, `border_*`, `blur_radius`) are applied as inline CSS on every rendered element
- The renderer produces standard HTML that works with the existing `ReactiveHandler` WebSocket system

### Integration with Components System

The `UI::ViewAdapter` class bridges the UI view tree into the reactive component system:

```crystal
class UI::ViewAdapter < Components::Reactive::ReactiveComponent
  def render_content : String
    renderer = UI::Web::Renderer.new
    @root.accept(renderer)
    renderer.output
  end
end
```

Existing `StatelessComponent`, `StatefulComponent`, and `ReactiveComponent` subclasses continue working without modifications.

---

## AppKit::Renderer (macOS)

**Target file:** `src/ui/renderers/appkit_renderer.cr`
**Compiled when:** `flag?(:macos)` — you MUST pass `-Dmacos` to crystal-alpha
**Bridge:** `src/ui/native/objc_bridge.m` (compile with `clang -c ... -fno-objc-arc`)

**Build prerequisites:**
```bash
# 1. Compile the ObjC bridge (required — provides typed objc_msgSend wrappers)
clang -c src/ui/native/objc_bridge.m -o objc_bridge.o -fno-objc-arc

# 2. Build with -Dmacos flag and link the bridge
crystal-alpha build app.cr -o app -Dmacos \
  --link-flags="objc_bridge.o -framework AppKit -framework Foundation -lobjc"
```

Maps `UI::View` types to AppKit `NSView` subclasses via the ObjC runtime C API.

### View-to-NSView Mapping

| UI::View | AppKit class | Configuration |
|----------|-------------|---------------|
| `Label` | `NSTextField` | Non-editable, `setBezeled:NO`, `setDrawsBackground:NO` |
| `Button` | `NSButton` | `NSBezelStyleRounded`, target-action via `CrystalActionDispatcher` |
| `VStack` | `NSStackView` | `orientation: .vertical`, `spacing`, `alignment` |
| `HStack` | `NSStackView` | `orientation: .horizontal`, `spacing`, `alignment` |
| `ZStack` | `NSView` | Children added as subviews with manual frame layout |
| `Image` | `NSImageView` | `imageScaling` mapped from `ContentMode` |
| `TextField` | `NSTextField` | Editable, delegate for change notifications |
| `ScrollView` | `NSScrollView` | `hasVerticalScroller`/`hasHorizontalScroller` |
| `Spacer` | (no view) | Flexible space via NSStackView gravity areas |
| `Toggle` | `NSButton` | `setButtonType: NSButtonTypeSwitch` (switch style) or `NSButtonTypeCheck` (checkbox style) |
| `Checkbox` | `NSButton` | `setButtonType: NSButtonTypeCheck` (buttonType=check) |
| `RadioGroup` | `NSMatrix` or group of `NSButton` | `setButtonType: NSButtonTypeRadio` per option |
| `Slider` | `NSSlider` | `minValue`, `maxValue`, `numberOfTickMarks` for step |
| `Stepper` | `NSStepper` | `minValue`, `maxValue`, `increment` |
| `SegmentedControl` | `NSSegmentedControl` | `trackingMode: .selectOne`, one segment per label |
| `NavigationStack` | Custom `NSViewController` stack | Push via `presentAsModalWindow:` or custom stack |
| `NavigationLink` | `NSButton` | Action triggers push on parent NavigationStack |
| `TabView` | `NSTabViewController` | One `NSTabViewItem` per `Tab` record |
| `NavigationSplitView` | `NSSplitViewController` | `NSSplitViewItem` per column |
| `Toolbar` | `NSToolbar` | `NSToolbarItem` per ToolbarItem; window decoration |
| `ProgressView` | `NSProgressIndicator` | `style: .bar` (Linear) or `.spinning` (Circular); `isIndeterminate` when value=nil |
| `ActivityIndicator` | `NSProgressIndicator` | `style: .spinning`, `isIndeterminate: YES`, `startAnimation:` |
| `Alert` | `NSAlert` | `runModal` or `beginSheetModal:` per `is_presented` |
| `Picker` | `NSPopUpButton` | `addItemWithTitle:` per option (Menu style); `NSSegmentedControl` for Segmented style |
| `IconButton` | `NSButton` | `setImage:` with no title; `imagePosition: NSImageOnly` |
| `ListView` | `NSTableView` | Single-column or `NSOutlineView` for sections |
| `SecureField` | `NSSecureTextField` | Always secure |
| `SearchField` | `NSSearchField` | `NSSearchField` subclass of `NSTextField` |
| `TextArea` | `NSTextView` | Embedded in `NSScrollView`, editable, multi-line |
| `TextEditor` | `NSTextView` | With `NSRulerView` for line numbers; syntax via `NSLayoutManager` |
| `DatePicker` | `NSDatePicker` | `datePickerMode` mapped from `DatePickerMode`; text field, stepper, or clock display |
| `TimePicker` | `NSDatePicker` | Hour+minute `datePickerElements`; `locale` for 24-hour |
| `Grid` | `NSGridView` | `NSGridView` with `NSGridRow`/`NSGridColumn` |
| `Form` | Sectioned `NSTableView` | Grouped rows with `NSTableCellView` label+content |
| `AsyncImage` | `NSImageView` | Async download via `URLSession`; placeholder view while loading |
| `RichText` | `NSTextView` | Non-editable; `NSAttributedString` built from `Span` records |
| `LinkButton` | `NSButton` | Action opens URL via `NSWorkspace.shared.open(url:)` |
| `MenuButton` | `NSPopUpButton` | `NSMenu` items added per `MenuItem`; destructive items styled red |
| `ToggleButton` | `NSButton` | `setButtonType: NSButtonTypeToggle`; `state` tracks `is_selected` |
| `Sheet` | `NSPanel` or `beginSheet:` | `NSWindowController.beginSheet:completionHandler:` |
| `Popover` | `NSPopover` | `showRelativeToRect:ofView:preferredEdge:` |
| `ConfirmationDialog` | `NSAlert` | Multiple buttons; `addButton:` for confirm/cancel |
| `Snackbar` | Custom `NSPanel` | Floating borderless panel at bottom of window |
| `Card` | `NSBox` | `boxType: .custom` with shadow + corner radius on `contentView` |
| `Surface` | `NSBox` | `boxType: .custom` or styled `NSView` |
| `Divider` | `NSBox` | `boxType: .separator` |
| `GlassBackground` | `NSVisualEffectView` | `material` mapped from Symbol to `NSVisualEffectView.Material` |
| `Circle` | Custom `NSView` | `NSBezierPath(ovalIn:)` drawn in `draw(_:)` |
| `Rectangle` | Custom `NSView` | `NSBezierPath(rect:)` drawn in `draw(_:)` |
| `RoundedRectangle` | Custom `NSView` | `NSBezierPath(roundedRect:xRadius:yRadius:)` drawn in `draw(_:)` |
| `Capsule` | Custom `NSView` | `NSBezierPath` with capsule path drawn in `draw(_:)` |
| `Canvas` | Custom `NSView` | `draw(_:)` replays `CanvasOp` array via `NSBezierPath` + `NSColor` |
| `PathView` | Custom `NSView` | `NSBezierPath` (stub) |
| `MapView` | `MKMapView` | `MapKit.framework`; `centerCoordinate`, `region` |
| `ChartView` | Swift Charts `Chart` | iOS 16+ / macOS 13+ `Swift Charts.framework` |
| `WebViewComponent` | `WKWebView` | `WebKit.framework`; `load(URLRequest:)` |
| `ColorPicker` | `NSColorWell` + `NSColorPanel` | `NSColorPanel.shared` for color selection |
| `VideoPlayer` | `AVPlayerView` | `AVKit.framework`; `AVPlayer(url:)` |
| `Tooltip` | `NSView.toolTip` | Property set on wrapped content view |

### ObjC Bridge Architecture

Crystal calls the ObjC runtime through C wrapper functions in `objc_bridge.c`. Each wrapper has a correctly-typed function signature matching the ARM64 calling convention (AAPCS64):

- **Integer/pointer args** go in registers `x0-x7`
- **Float/double args** go in registers `d0-d7` (independent bank)
- **CGRect/CGPoint/CGSize** are Homogeneous Floating-point Aggregates (HFA) passed in `d0-d3`

Every unique combination of (return type, parameter types) has its own wrapper to prevent register corruption. This is critical on ARM64 where `objc_msgSend` is a raw assembly trampoline that does not know argument types.

### Callback Dispatch

Button taps (and all `on_tap`/`on_change`/`on_toggle` callbacks) go through this chain:

1. `NSButton` (or other control) target-action fires `CrystalActionDispatcher` (ObjC class created at runtime)
2. The SEL encodes a callback ID: `crystalAction_<id>:`
3. The dispatcher IMP calls `crystal_ui_callback_dispatch(id)` (exported C function)
4. Crystal looks up the `Proc` in `UI::CallbackRegistry` by ID and calls it

### Memory Management

- Every render pass is bracketed with `ObjC.autoreleasepool { }`
- Created views are wrapped in `NativeHandle` with `ReleaseStrategy::ObjCRelease`
- Borrowed references (e.g., `contentView`) use `ReleaseStrategy::ObjCBorrowed`
- `NativeView.teardown!` cascades through the child tree for deterministic cleanup

### Applying Base Class Modifiers

The AppKit renderer applies `UI::View` modifier properties via a shared `apply_common_properties(view, ns_view)` method:

```
corner_radius    → layer.cornerRadius + clipsToBounds
shadow_*         → layer.shadowRadius, layer.shadowColor, layer.shadowOffset
border_*         → layer.borderWidth, layer.borderColor
blur_radius      → CIFilter blur on layer contents
opacity          → alphaValue
padding          → NSStackView internal edges or manual frame adjustment
```

---

## UIKit::Renderer (iOS)

**Target file:** `src/ui/renderers/uikit_renderer.cr`
**Compiled when:** `flag?(:ios)`
**Bridge:** Same `objc_bridge.c` (ObjC runtime is shared between macOS and iOS)

Maps `UI::View` types to UIKit `UIView` subclasses. Uses the same ObjC bridge as macOS — the only difference is class names and some API differences.

### View-to-UIView Mapping

| UI::View | UIKit class | Configuration |
|----------|------------|---------------|
| `Label` | `UILabel` | `numberOfLines`, `textAlignment`, `textColor`, `font` |
| `Button` | `UIButton` | `UIButton.systemButton(with:)`, target-action pattern |
| `VStack` | `UIStackView` | `axis: .vertical`, `spacing`, `alignment`, `distribution` |
| `HStack` | `UIStackView` | `axis: .horizontal`, `spacing`, `alignment`, `distribution` |
| `ZStack` | `UIView` | Children positioned with Auto Layout anchors |
| `Image` | `UIImageView` | `contentMode` mapped from `ContentMode` |
| `TextField` | `UITextField` | `placeholder`, `isSecureTextEntry`, `keyboardType` |
| `ScrollView` | `UIScrollView` | `showsVerticalScrollIndicator`/`showsHorizontalScrollIndicator` |
| `Spacer` | (layout guide) | `UILayoutGuide` with flexible priority constraints |
| `Toggle` | `UISwitch` | `isOn`, `addTarget:action:` for `valueChanged` |
| `Checkbox` | `UIButton` | Custom checkmark image for checked/unchecked states |
| `RadioGroup` | `UIStackView` | Group of styled `UIButton` with mutual exclusion logic |
| `Slider` | `UISlider` | `minimumValue`, `maximumValue`, `value` |
| `Stepper` | `UIStepper` | `minimumValue`, `maximumValue`, `stepValue` |
| `SegmentedControl` | `UISegmentedControl` | `insertSegmentWithTitle:` per segment |
| `NavigationStack` | `UINavigationController` | `pushViewController:animated:` / `popViewControllerAnimated:` |
| `NavigationLink` | `UIButton` | Action calls `pushViewController:animated:` on parent nav controller |
| `TabView` | `UITabBarController` | One `UITabBarItem` per `Tab` record |
| `NavigationSplitView` | `UISplitViewController` | `UISplitViewControllerColumn` per column |
| `Toolbar` | `UIToolbar` | `UIBarButtonItem` per ToolbarItem |
| `ProgressView` | `UIProgressView` | `progress` (determinate) or hidden + `UIActivityIndicatorView` (Circular indeterminate) |
| `ActivityIndicator` | `UIActivityIndicatorView` | `style` mapped from size Symbol; `startAnimating` when `is_animating` |
| `Alert` | `UIAlertController` | `preferredStyle: .alert`; `UIAlertAction` per `AlertButton` |
| `Picker` | `UIPickerView` | Wheel style; `UIButton+UIMenu` for Menu style (iOS 14+) |
| `IconButton` | `UIButton` | `setImage:forState:` with no title |
| `ListView` | `UITableView` | `UITableViewCell` per item; `UITableViewHeaderFooterView` for sections |
| `SecureField` | `UITextField` | `isSecureTextEntry = true` |
| `SearchField` | `UISearchTextField` | iOS 13+; `UISearchBar` for older |
| `TextArea` | `UITextView` | Editable, scrollable; `UITextViewDelegate` for changes |
| `TextEditor` | `UITextView` | With custom overlay for line numbers; `NSLayoutManager` for syntax |
| `DatePicker` | `UIDatePicker` | `datePickerMode` mapped from `DatePickerMode`; `.inline`, `.compact`, or `.wheels` style |
| `TimePicker` | `UIDatePicker` | `.countDownTimer` or `.time` mode; `minuteInterval` |
| `Grid` | `UICollectionView` | `UICollectionViewFlowLayout` with fixed column count |
| `Form` | `UITableView` | `UITableView.Style.insetGrouped` |
| `AsyncImage` | `UIImageView` | `URLSession.dataTask(with:)` async download; placeholder while loading |
| `RichText` | `UITextView` | Non-editable; `NSAttributedString` built from `Span` records |
| `LinkButton` | `UIButton` | Action opens URL via `UIApplication.shared.open(_:)` |
| `MenuButton` | `UIButton` | `button.menu = UIMenu(...)` (iOS 14+); `showsMenuAsPrimaryAction = true` |
| `ToggleButton` | `UIButton` | `isSelected` state; custom selected/normal appearance |
| `Sheet` | `UISheetPresentationController` | iOS 15+; `detents` mapped from Symbol array |
| `Popover` | `UIPopoverPresentationController` | `sourceView`, `permittedArrowDirections` mapped from `arrow_edge` |
| `ConfirmationDialog` | `UIAlertController` | `preferredStyle: .actionSheet` on iPhone, `.alert` on iPad |
| `Snackbar` | Custom `UIView` | Presented as child view at bottom with spring animation |
| `Card` | Custom `UIView` | `layer.cornerRadius`, `layer.shadowRadius`, `layer.shadowColor` |
| `Surface` | `UIView` | `backgroundColor`, optional `layer.borderWidth` |
| `Divider` | `UIView` | `frame.size.height = thickness`; `backgroundColor = color` |
| `GlassBackground` | `UIVisualEffectView` | `UIBlurEffect(style:)` mapped from `material` symbol |
| `Circle` | Custom `UIView` | `UIBezierPath(ovalIn:)` drawn in `draw(_:)` |
| `Rectangle` | Custom `UIView` | `UIBezierPath(rect:)` drawn in `draw(_:)` |
| `RoundedRectangle` | Custom `UIView` | `UIBezierPath(roundedRect:cornerRadius:)` drawn in `draw(_:)` |
| `Capsule` | Custom `UIView` | `UIBezierPath` with capsule path drawn in `draw(_:)` |
| `Canvas` | Custom `UIView` | `draw(_:)` replays `CanvasOp` array via `UIBezierPath` + `UIColor` |
| `PathView` | Custom `UIView` | `UIBezierPath` (stub) |
| `MapView` | `MKMapView` | `MapKit.framework`; `centerCoordinate`, `region` |
| `ChartView` | Swift Charts `Chart` | iOS 16+ `Swift Charts.framework` |
| `WebViewComponent` | `WKWebView` | `WebKit.framework`; `load(URLRequest:)` |
| `ColorPicker` | `UIColorPickerViewController` | iOS 14+; presented as sheet |
| `VideoPlayer` | `AVPlayerViewController` | `AVKit.framework`; `AVPlayer(url:)` |
| `Tooltip` | `UITooltipInteraction` | iOS 17+; fallback: no-op on older iOS |

### iOS-Specific Considerations

- **No `Process.fork`:** iOS App Sandbox forbids forking. Never call `Process` module methods.
- **No JIT for PCRE2:** iOS blocks `mmap(PROT_EXEC)`, so `libpcre2` must be compiled with JIT disabled.
- **Signal handlers:** `SIGSEGV`/`SIGBUS` handlers may conflict with iOS crash reporting; guard with `{% unless flag?(:ios) %}`.
- **Build command:**
  ```bash
  crystal build src/app.cr --target aarch64-apple-ios --cross-compile \
    -Dwithout_openssl -Dwithout_xml -o app.o
  xcrun --sdk iphoneos clang app.o -lgc -lpcre2-8 \
    -framework UIKit -framework Foundation -o MyApp.framework/MyApp
  ```

---

## Android::Renderer

**Target file:** `src/ui/renderers/android_renderer.cr`
**Compiled when:** `flag?(:android)`
**Bridge:** `jni_bridge.c` + JNI portion of `collection_bridge.c`

Maps `UI::View` types to Android `View` subclasses via JNI (Java Native Interface).

### View-to-Android View Mapping

| UI::View | Android class | Configuration |
|----------|--------------|---------------|
| `Label` | `TextView` | `setText`, `setTextSize`, `setTypeface`, `setTextColor` |
| `Button` | `MaterialButton` | `setText`, `setOnClickListener` via JNI callback bridge |
| `VStack` | `LinearLayout` | `orientation: VERTICAL`, `LayoutParams` with margins |
| `HStack` | `LinearLayout` | `orientation: HORIZONTAL` |
| `ZStack` | `FrameLayout` | Children positioned with `LayoutParams` gravity |
| `Image` | `ImageView` | `setScaleType` mapped from `ContentMode` |
| `TextField` | `EditText` | `setHint`, `setInputType`, `addTextChangedListener` |
| `ScrollView` | `ScrollView` / `HorizontalScrollView` | Depends on scroll axis |
| `Spacer` | `Space` | `LayoutParams` with `weight=1` |
| `Toggle` | `SwitchMaterial` | `setChecked`, `setOnCheckedChangeListener`; `Switch` on older API |
| `Checkbox` | `CheckBox` | `android.widget.CheckBox`; `setOnCheckedChangeListener` |
| `RadioGroup` | `RadioGroup` + `RadioButton` | `android.widget.RadioGroup`; `setOnCheckedChangeListener` |
| `Slider` | `Slider` (Material) | `com.google.android.material.slider.Slider`; `addOnChangeListener` |
| `Stepper` | Composed `LinearLayout` | Custom: `MaterialButton("-")` + `TextView` + `MaterialButton("+")` |
| `SegmentedControl` | `MaterialButtonToggleGroup` | `com.google.android.material.button.MaterialButtonToggleGroup` (single selection) |
| `NavigationStack` | `FragmentManager` + back stack | `FragmentTransaction.replace + addToBackStack()` |
| `NavigationLink` | `View.setOnClickListener` | Calls `FragmentTransaction.replace` on tap |
| `TabView` | `BottomNavigationView` | `com.google.android.material.bottomnavigation.BottomNavigationView` + `FragmentContainerView` |
| `NavigationSplitView` | `SlidingPaneLayout` | `androidx.slidingpanelayout.widget.SlidingPaneLayout` |
| `Toolbar` | `MaterialToolbar` | `com.google.android.material.appbar.MaterialToolbar`; `MenuItem` per item |
| `ProgressView` | `LinearProgressIndicator` / `CircularProgressIndicator` | Material `com.google.android.material.progressindicator.*`; `setProgress` |
| `ActivityIndicator` | `CircularProgressIndicator` | `setIndeterminate(true)`; `setVisibility` via `is_animating` |
| `Alert` | `MaterialAlertDialogBuilder` | `com.google.android.material.dialog.MaterialAlertDialogBuilder` |
| `Picker` | `Spinner` | `android.widget.Spinner` with `ArrayAdapter` |
| `IconButton` | `ImageButton` | `android.widget.ImageButton`; `setImageResource` / `setImageDrawable` |
| `ListView` | `RecyclerView` | `androidx.recyclerview.widget.RecyclerView` with `LinearLayoutManager` |
| `SecureField` | `EditText` | `setInputType(TYPE_CLASS_TEXT | TYPE_TEXT_VARIATION_PASSWORD)` |
| `SearchField` | `SearchView` | `android.widget.SearchView`; `setOnQueryTextListener` |
| `TextArea` | `EditText` | `setInputType(TYPE_CLASS_TEXT | TYPE_TEXT_FLAG_MULTI_LINE)`; `setLines(minLines)` |
| `TextEditor` | `EditText` | Multi-line, monospace font; line numbers via custom `LinearLayout` overlay |
| `DatePicker` | `MaterialDatePicker` | `com.google.android.material.datepicker.MaterialDatePicker` dialog |
| `TimePicker` | `MaterialTimePicker` | `com.google.android.material.timepicker.MaterialTimePicker` dialog |
| `Grid` | `RecyclerView` | `GridLayoutManager(context, spanCount)` |
| `Form` | `RecyclerView` | Section headers + field rows with `ConcatAdapter` |
| `AsyncImage` | `ImageView` | `ImageView` + Coil / Glide / Picasso for async load + caching |
| `RichText` | `TextView` | `SpannableStringBuilder` with `StyleSpan`, `ForegroundColorSpan`, `URLSpan` |
| `LinkButton` | `MaterialButton` | `setOnClickListener` opens URL via `Intent(ACTION_VIEW, Uri.parse(url))` |
| `MenuButton` | `MaterialButton` + `PopupMenu` | `android.widget.PopupMenu`; destructive items styled red |
| `ToggleButton` | `MaterialButton` | `android.widget.ToggleButton` or `MaterialButton` with toggle state |
| `Sheet` | `BottomSheetDialogFragment` | `com.google.android.material.bottomsheet.BottomSheetDialogFragment`; `peekHeight` from detents |
| `Popover` | `PopupWindow` | `android.widget.PopupWindow`; shown relative to anchor view |
| `ConfirmationDialog` | `MaterialAlertDialogBuilder` | Two buttons (confirm + cancel); `positiveButton` style for confirm_style |
| `Snackbar` | `Snackbar` | `com.google.android.material.snackbar.Snackbar`; `setDuration`, `setAction` |
| `Card` | `MaterialCardView` | `com.google.android.material.card.MaterialCardView`; `cardElevation`, `strokeWidth` |
| `Surface` | `CardView` | `androidx.cardview.widget.CardView` or plain `ViewGroup` with background |
| `Divider` | `View` | `height=1dp`, `background=color`, or `DividerItemDecoration` in lists |
| `GlassBackground` | `RenderEffect` (API 31+) | `RenderEffect.createBlurEffect()` on API 31+; translucent solid fallback on older |
| `Circle` | Custom `View` | `onDraw`: `canvas.drawCircle(cx, cy, radius, paint)` |
| `Rectangle` | Custom `View` | `onDraw`: `canvas.drawRect(rect, paint)` |
| `RoundedRectangle` | Custom `View` | `onDraw`: `canvas.drawRoundRect(rect, rx, ry, paint)` |
| `Capsule` | Custom `View` | `onDraw`: `canvas.drawRoundRect` with `rx = min(w,h)/2` |
| `Canvas` | Custom `View` | `onDraw` replays `CanvasOp` array via `android.graphics.Canvas` + `Paint` |
| `PathView` | Custom `View` | `android.graphics.Path` (stub) |
| `MapView` | `SupportMapFragment` | Google Maps SDK `com.google.android.gms.maps`; `LatLng`, `CameraUpdateFactory` |
| `ChartView` | `MPAndroidChart` | `com.github.PhilJay:MPAndroidChart`; `BarChart`/`LineChart`/`PieChart` per `chart_type` |
| `WebViewComponent` | `WebView` | `android.webkit.WebView`; `loadUrl(url)` |
| `ColorPicker` | Custom dialog | No native; third-party or custom `AlertDialog` with `ColorPicker` view |
| `VideoPlayer` | `PlayerView` | `androidx.media3.ui.PlayerView` (Media3/ExoPlayer) |
| `Tooltip` | `TooltipCompat` | `androidx.appcompat.widget.TooltipCompat.setTooltipText(view, text)` |

### JNI Bridge Architecture

The Android renderer requires a `JNIEnv*` pointer (obtained from the Java VM when the native library is loaded). All JNI calls go through typed C wrappers in `jni_bridge.c`:

- **String creation:** `jni_string_create_with_bytes(env, bytes, len)` creates a `jstring`
- **Batch child add:** `jni_viewgroup_add_views_batch(env, parent, children, count)` adds multiple children in one JNI crossing
- **Global refs:** Local references must be promoted to global refs (`jni_new_global_ref`) to survive beyond the current JNI call

### Callback Dispatch

1. A Java `CrystalCallbackBridge` class has a `static native void dispatch(long callbackId)` method
2. The JNI implementation calls `crystal_ui_callback_dispatch(id)` -- the same entry point as ObjC
3. Crystal looks up the `Proc` in `UI::CallbackRegistry` by ID

### Memory Management

- Every batch operation is bracketed with `JNI.local_frame(env, capacity) { }`
- Created views are wrapped in `NativeHandle` with `ReleaseStrategy::JNIGlobalRef`
- `teardown!` calls `DeleteGlobalRef` on each handle
- **Build command:**
  ```bash
  crystal build src/app.cr --target aarch64-linux-android --cross-compile \
    --shared -Dwithout_openssl -Dwithout_xml -o libapp.o
  $NDK_CLANG --target=aarch64-linux-android31 -shared -fPIC \
    libapp.o -lgc -lpcre2-8 -o libapp.so
  ```

---

## Platform Mapping Table (Complete)

| UI::View | Web (HTML + CSS) | macOS (AppKit) | iOS (UIKit) | Android |
|----------|-----------------|----------------|-------------|---------|
| `Label` | `<span>` styled via CSS | `NSTextField` (non-editable) | `UILabel` | `TextView` |
| `Button` | `<button>` with `data-action` | `NSButton` (rounded bezel) | `UIButton` (system) | `MaterialButton` |
| `VStack` | `<div>` flex column | `NSStackView` (vertical) | `UIStackView` (.vertical) | `LinearLayout` (VERTICAL) |
| `HStack` | `<div>` flex row | `NSStackView` (horizontal) | `UIStackView` (.horizontal) | `LinearLayout` (HORIZONTAL) |
| `ZStack` | `<div>` position:relative | `NSView` + frame layout | `UIView` + Auto Layout | `FrameLayout` |
| `Image` | `<img>` with object-fit | `NSImageView` | `UIImageView` | `ImageView` |
| `TextField` | `<input type=text/password>` | `NSTextField` (editable) | `UITextField` | `EditText` |
| `ScrollView` | `<div>` overflow:auto | `NSScrollView` | `UIScrollView` | `ScrollView` / `HorizontalScrollView` |
| `Spacer` | `<div>` flex:1 | NSStackView gravity space | `UILayoutGuide` flexible | `Space` weight=1 |
| `Toggle` | `<input type=checkbox role=switch>` | `NSButton` (switch type) | `UISwitch` | `SwitchMaterial` |
| `Checkbox` | `<input type=checkbox>` | `NSButton` (check type) | Custom `UIButton` | `CheckBox` |
| `RadioGroup` | `<input type=radio>` group | `NSButton` (radio type) group | Custom `UIButton` group | `RadioGroup` + `RadioButton` |
| `Slider` | `<input type=range>` | `NSSlider` | `UISlider` | `Slider` (Material) |
| `Stepper` | `<input type=number>` | `NSStepper` | `UIStepper` | Composed `LinearLayout` |
| `SegmentedControl` | CSS button group | `NSSegmentedControl` | `UISegmentedControl` | `MaterialButtonToggleGroup` |
| `NavigationStack` | JS router + history API | Custom `NSViewController` stack | `UINavigationController` | `FragmentManager` backstack |
| `NavigationLink` | `<a href>` / router link | `NSButton` + push action | `UIButton` + push action | `View.setOnClickListener` |
| `TabView` | `role=tablist` nav + panels | `NSTabViewController` | `UITabBarController` | `BottomNavigationView` |
| `NavigationSplitView` | CSS grid two-column | `NSSplitViewController` | `UISplitViewController` | `SlidingPaneLayout` |
| `Toolbar` | `<header>` / `<nav>` | `NSToolbar` | `UIToolbar` | `MaterialToolbar` |
| `ProgressView` | `<progress>` / CSS spinner | `NSProgressIndicator` | `UIProgressView` / `UIActivityIndicatorView` | `LinearProgressIndicator` / `CircularProgressIndicator` |
| `ActivityIndicator` | CSS keyframe spinner | `NSProgressIndicator` (spinning) | `UIActivityIndicatorView` | `CircularProgressIndicator` |
| `Alert` | `<dialog>` element | `NSAlert` | `UIAlertController` (.alert) | `MaterialAlertDialogBuilder` |
| `Picker` | `<select>` | `NSPopUpButton` | `UIPickerView` / `UIButton+UIMenu` | `Spinner` |
| `IconButton` | `<button>` + icon | `NSButton` (image only) | `UIButton` (image only) | `ImageButton` |
| `ListView` | `<ul>` / `<div>` list | `NSTableView` | `UITableView` | `RecyclerView` (Linear) |
| `SecureField` | `<input type=password>` | `NSSecureTextField` | `UITextField` (secure) | `EditText` (password type) |
| `SearchField` | `<input type=search>` | `NSSearchField` | `UISearchTextField` | `SearchView` |
| `TextArea` | `<textarea>` | `NSTextView` (in `NSScrollView`) | `UITextView` | `EditText` (multiline) |
| `TextEditor` | `<textarea>` + syntax CSS | `NSTextView` + ruler | `UITextView` + overlay | `EditText` + monospace |
| `DatePicker` | `<input type=date/datetime-local>` | `NSDatePicker` | `UIDatePicker` | `MaterialDatePicker` |
| `TimePicker` | `<input type=time>` | `NSDatePicker` (time mode) | `UIDatePicker` (time mode) | `MaterialTimePicker` |
| `Grid` | CSS grid | `NSGridView` | `UICollectionView` + `FlowLayout` | `RecyclerView` + `GridLayoutManager` |
| `Form` | `<form>` + `<fieldset>` | Sectioned `NSTableView` | `UITableView` (insetGrouped) | `RecyclerView` + section adapter |
| `AsyncImage` | `<img loading=lazy>` | `NSImageView` + URLSession | `UIImageView` + URLSession | `ImageView` + Coil/Glide |
| `RichText` | Multiple `<span>` | `NSTextView` + `NSAttributedString` | `UITextView` + `NSAttributedString` | `TextView` + `SpannableStringBuilder` |
| `LinkButton` | `<a href>` | `NSButton` + NSWorkspace | `UIButton` + UIApplication.open | `MaterialButton` + Intent |
| `MenuButton` | `<button>` + dropdown `<ul>` | `NSPopUpButton` + `NSMenu` | `UIButton` + `UIMenu` (iOS 14+) | `MaterialButton` + `PopupMenu` |
| `ToggleButton` | `<button aria-pressed>` | `NSButton` (toggle type) | `UIButton` (selected state) | `ToggleButton` / `MaterialButton` |
| `Sheet` | CSS bottom overlay | `beginSheet:` / `NSPanel` | `UISheetPresentationController` | `BottomSheetDialogFragment` |
| `Popover` | Popover API / `<div>` absolute | `NSPopover` | `UIPopoverPresentationController` | `PopupWindow` |
| `ConfirmationDialog` | `<dialog>` modal | `NSAlert` (multiple buttons) | `UIAlertController` (.actionSheet) | `MaterialAlertDialogBuilder` |
| `Snackbar` | CSS fixed bottom `<div>` | Custom `NSPanel` | Custom `UIView` animation | `Snackbar` (Material) |
| `Card` | `<div>` rounded + shadow | `NSBox` + shadow layer | Custom `UIView` + layer shadow | `MaterialCardView` |
| `Surface` | `<div>` background | `NSBox` | `UIView` background | `CardView` / `ViewGroup` |
| `Divider` | `<hr>` / 1px `<div>` | `NSBox` (separator) | `UIView` 1pt height | `View` 1dp height |
| `GlassBackground` | `backdrop-filter:blur()` | `NSVisualEffectView` | `UIVisualEffectView` | `RenderEffect.blur` (API 31+) |
| `Circle` | `<div>` border-radius:50% / SVG | Custom `NSView` + NSBezierPath | Custom `UIView` + UIBezierPath | Custom `View` + canvas.drawCircle |
| `Rectangle` | `<div>` with dimensions | Custom `NSView` + NSBezierPath | Custom `UIView` + UIBezierPath | Custom `View` + canvas.drawRect |
| `RoundedRectangle` | `<div>` border-radius | Custom `NSView` + NSBezierPath | Custom `UIView` + UIBezierPath | Custom `View` + canvas.drawRoundRect |
| `Capsule` | `<div>` border-radius:9999px | Custom `NSView` + NSBezierPath | Custom `UIView` + UIBezierPath | Custom `View` + canvas.drawRoundRect |
| `Canvas` | `<canvas>` + 2D context | Custom `NSView` + NSBezierPath | Custom `UIView` + UIBezierPath | Custom `View` + android.graphics.Canvas |
| `PathView` | SVG `<path>` | Custom `NSView` (stub) | Custom `UIView` (stub) | Custom `View` (stub) |
| `MapView` | Leaflet.js / Google Maps JS | `MKMapView` | `MKMapView` | `SupportMapFragment` (Google Maps) |
| `ChartView` | Chart.js / D3.js | Swift Charts `Chart` | Swift Charts `Chart` | MPAndroidChart |
| `WebViewComponent` | `<iframe>` | `WKWebView` | `WKWebView` | `android.webkit.WebView` |
| `ColorPicker` | `<input type=color>` | `NSColorWell` + `NSColorPanel` | `UIColorPickerViewController` (iOS 14+) | Custom dialog (no native) |
| `VideoPlayer` | `<video controls>` | `AVPlayerView` (AVKit) | `AVPlayerViewController` (AVKit) | `PlayerView` (Media3/ExoPlayer) |
| `Tooltip` | `title` attr / CSS hover | `NSView.toolTip` property | `UITooltipInteraction` (iOS 17+) | `TooltipCompat` |

---

## How to Add a New View Type

1. **Create the view class** in `src/ui/views/new_view.cr`:
   ```crystal
   class UI::NewView < UI::View
     # properties...
     def accept(visitor : PlatformVisitor)
       visitor.visit(self)
     end
   end
   ```

2. **Add the abstract visit method** to `src/ui/platform_visitor.cr`:
   ```crystal
   abstract def visit(view : NewView)
   ```

3. **Implement `visit` in each renderer:**
   - `Web::Renderer#visit(view : NewView)` -- map to `Components::Elements` class
   - `AppKit::Renderer#visit(view : NewView)` -- map to `NSView` subclass
   - `UIKit::Renderer#visit(view : NewView)` -- map to `UIView` subclass
   - `Android::Renderer#visit(view : NewView)` -- map to Android `View` subclass

4. **Add specs** in `spec/ui/views_spec.cr` to verify construction, property defaults, and visitor acceptance.

The compiler enforces completeness: if a renderer does not implement the new `visit` overload, the build fails with a missing abstract method error.

---

## How to Add a New Platform

1. **Create the renderer file** at `src/ui/renderers/new_platform_renderer.cr`:
   ```crystal
   module UI::NewPlatform
     class Renderer < UI::PlatformVisitor
       def visit(view : Label)
         # platform-specific rendering
       end
       # ... implement all visit methods (currently 59)
     end
   end
   ```

2. **Add the compile-time flag check** in the platform selection block:
   ```crystal
   {% elsif flag?(:new_platform) %}
     require "./renderers/new_platform_renderer"
     alias PlatformRenderer = UI::NewPlatform::Renderer
   ```

3. **Create a native bridge** (C file) if the platform requires FFI calls, following the pattern of `objc_bridge.c` or `jni_bridge.c`.

4. **Add the platform column** to the mapping table and update all documentation.

The compiler enforces that every `visit` method is implemented. Missing methods result in a compile-time error.
