---
name: ios26-native-components
description: |
  Complete catalog of iOS 26 and macOS 26 native UI components including SwiftUI views,
  UIKit classes, and AppKit classes. Covers Liquid Glass design language, new WWDC 2025
  APIs, and mapping guidance for Crystal cross-platform UI integration.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
version: "1.0.0"
---

# iOS 26 / macOS 26 Native Components Reference

This document is the authoritative reference for native Apple platform UI components
available in iOS 26, iPadOS 26, and macOS Tahoe 26. It covers the Liquid Glass design
language introduced at WWDC 2025, all major SwiftUI views, UIKit view classes, and
AppKit view classes. It provides implementation priority guidance for the
asset_pipeline Crystal library's PlatformVisitor system.

The asset_pipeline maps Crystal `UI::View` types to native platform elements at compile
time. For macOS, the `AppKit::Renderer` (in `src/ui/renderers/appkit_renderer.cr`)
allocates AppKit classes via the ObjC runtime bridge. For iOS, the same pattern applies
using UIKit classes. For web, the `WebRenderer` emits HTML/CSS.

---

## 1. Overview

iOS 26 and macOS Tahoe 26, released at WWDC 2025, introduce the most significant visual
redesign since iOS 7. The new "Liquid Glass" material system replaces flat and frosted
designs with a physically-based translucency that bends and refracts light in real time.

Every major UI surface is updated: tab bars, toolbars, sheets, navigation bars, and
control backgrounds now render with Liquid Glass. Developers can apply the material to
their own views using new SwiftUI modifiers (`.glassEffect()`), new UIKit classes
(`UIGlassEffect`, `UIGlassEffectView`, `UIGlassEffectContainerView`), and new AppKit
classes (`NSGlassEffectView`, `NSGlassEffectContainerView`).

Beyond the visual system, iOS 26 adds two long-requested features: a native SwiftUI
`WebView` type (eliminating the need for UIKit wrapping of `WKWebView`) and rich-text
editing in `TextEditor` via `AttributedString`. Other additions include 3D charting with
`Chart3D`, enhanced `TabView` with collapse-on-scroll behavior, `ToolbarSpacer`, list
section index labels, the `@Animatable` macro, new SF Symbols draw-on effects, and the
`.backgroundExtensionEffect()` modifier.

---

## 2. Liquid Glass Design Language (iOS 26 / macOS 26)

### What Liquid Glass Is

Liquid Glass is Apple's new material introduced across all Apple platforms in 2025. It
is a translucent, physically-based surface that:

- **Refracts and lenses light** - uses real-time lensing (not blur-scatter like Gaussian
  blur) to bend the content behind the glass surface
- **Responds to device motion** - specular highlights shift as the device tilts
- **Adapts to background content** - the frosting and tinting adjust to remain legible
  over any background color, image, or video
- **Morphs between states** - adjacent glass elements can merge and separate with fluid
  animations when assigned matching IDs within a shared namespace
- **Supports interactive behaviors** - when `.interactive()` is applied, touch events
  cause the glass to scale, bounce, shimmer, and light up at the contact point
- **Adapts to accessibility settings** - automatically increases frosting when
  `reduceTransparency` is enabled; reduces motion when `reduceMotion` is enabled

Liquid Glass replaces `UIVisualEffectView` / `NSVisualEffectView` as the primary
background material for controls and navigation chrome. The old blur/vibrancy APIs
remain available but are not used by system-provided controls in iOS 26.

### SwiftUI APIs

#### Primary Modifier

```swift
// Minimal form — applies .regular glass with capsule shape
.glassEffect()

// Full form
.glassEffect(_ glass: GlassEffect, in shape: some Shape, isEnabled: Bool = true)
```

#### Glass Variants

| Variant | Transparency | Typical Use |
|---------|-------------|-------------|
| `.regular` | Medium | Toolbars, buttons, navigation bars |
| `.clear` | High (minimal frosting) | Floating controls over photos/video |
| `.identity` | None (disabled) | Conditional toggling without layout change |

#### Glass Modifiers (chained on GlassEffect)

```swift
.glassEffect(.regular.tint(.blue))             // semantic color tint
.glassEffect(.regular.interactive())           // enable touch responsiveness (iOS only)
.glassEffect(.clear.tint(.red).interactive())  // chainable
```

#### Supported Shapes

- `.capsule` (default when no shape specified)
- `.circle`
- `.ellipse`
- `RoundedRectangle(cornerRadius: 12)`
- `.rect(cornerRadius: .containerConcentric)` — auto-aligns corner radius with parent
- Any custom type conforming to the `Shape` protocol

#### Morphing and Grouping

```swift
// GlassEffectContainer wraps multiple glass views and composites them
// together so they sample background content once and morph as a unit.
GlassEffectContainer(spacing: 8) {
    Button("A") { }
        .glassEffect()
        .glassEffectID("buttonA", in: namespace)
    Button("B") { }
        .glassEffect()
        .glassEffectID("buttonB", in: namespace)
}
```

- `GlassEffectContainer(spacing:)` — groups glass elements; ensures uniform
  background sampling and enables morphing transitions
- `.glassEffectID(_ id:, in: Namespace.ID)` — assigns identity so elements can
  morph into each other during state changes; requires a `@Namespace` variable

#### Accessibility Environment

The glass system reads these environment values automatically:

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion
```

No code required — Apple's implementation increases frosting when transparency is
reduced and disables physics-based animations when reduce motion is active.

### UIKit APIs (iOS 26 / iPadOS 26)

#### Class Hierarchy

```
UIVisualEffect
  └── UIGlassEffect          (NEW in iOS 26)

UIView
  └── UIVisualEffectView
        └── UIGlassEffectView          (NEW in iOS 26)
        └── UIGlassEffectContainerView (NEW in iOS 26)
```

#### UIGlassEffect

```objc
// Subclass of UIVisualEffect
@interface UIGlassEffect : UIVisualEffect

// Factory method — preferred over alloc/init
+ (instancetype)effectWithStyle:(UIGlassEffectStyle)style;

@property (nonatomic) BOOL interactive;       // enables touch response
@property (nonatomic, strong) UIColor *tintColor;

@end

// Enum values
typedef NS_ENUM(NSInteger, UIGlassEffectStyle) {
    UIGlassEffectStyleRegular = 0,
    UIGlassEffectStyleClear   = 1,
};
```

#### UIGlassEffectView

```objc
// Works like UIVisualEffectView: add subviews to its contentView
UIGlassEffect *glass = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
UIGlassEffectView *glassView = [[UIGlassEffectView alloc] initWithEffect:glass];
glassView.layer.cornerRadius = 20;
glassView.clipsToBounds = YES;
[glassView.contentView addSubview:myLabel];
```

#### UIGlassEffectContainerView

Groups multiple `UIGlassEffectView` instances so they sample the background together
and morph as a unit. Add `UIGlassEffectView` instances as subviews of the container.

```objc
UIGlassEffectContainerView *container = [[UIGlassEffectContainerView alloc] init];
[container addSubview:glassViewA];
[container addSubview:glassViewB];
```

### AppKit APIs (macOS 26 / Tahoe)

#### NSGlassEffectView

```objc
// Embed content on a glass background — add your views to contentView
@interface NSGlassEffectView : NSView

@property (nonatomic, strong) NSView *contentView;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic, strong) NSColor *tintColor;

@end

// Usage pattern
NSGlassEffectView *glassView = [[NSGlassEffectView alloc] initWithFrame:frame];
glassView.cornerRadius = 12;
glassView.tintColor = [NSColor systemBlueColor];
[glassView.contentView addSubview:myControl];
```

#### NSGlassEffectContainerView

Groups multiple `NSGlassEffectView` instances for unified background sampling and
morphing. Equivalent to `UIGlassEffectContainerView` on iOS.

```objc
NSGlassEffectContainerView *container = [[NSGlassEffectContainerView alloc] initWithFrame:frame];
[container addSubview:glassViewA];
[container addSubview:glassViewB];
```

### Crystal Integration Notes

The existing `glass-effects` skill covers Liquid Glass integration patterns for
asset_pipeline. The UIKit path would add a `UI::GlassEffect` view that wraps
`UIGlassEffectView` on iOS and `NSGlassEffectView` on macOS. Web rendering would
use CSS `backdrop-filter: blur()` with a translucent background color as the
closest equivalent.

Crystal ObjC bridge pattern for NSGlassEffectView:

```crystal
# In AppKit::Renderer
def visit(view : UI::GlassView)
  ptr = alloc_init("NSGlassEffectView")

  LibObjCBridge.objc_send_1d(ptr, sel("setCornerRadius:"), view.corner_radius)

  if tint = view.tint
    tint_ptr = LibObjCBridge.nscolor_rgba(tint.r, tint.g, tint.b, tint.a)
    LibObjCBridge.objc_send_id(ptr, sel("setTintColor:"), tint_ptr)
  end

  # contentView is a property — get it and add children to it
  content_view = LibObjCBridge.objc_send(ptr, sel("contentView"))
  # ... add arranged subviews to content_view ...

  apply_common_properties(ptr, view)
  emit(ptr, "NSGlassEffectView")
end
```

---

## 3. SwiftUI Views by Category

For each view: SwiftUI name, underlying UIKit/AppKit class, Crystal UI::View equivalent
or proposed name, and implementation priority.

Legend for Crystal column:
- `UI::Label` — already implemented
- `UI::Toggle` (proposed) — not yet implemented, new view needed
- — — no Crystal equivalent planned / low priority

Legend for Priority:
- **P0** — already implemented
- **P1** — high priority, common daily-use patterns
- **P2** — medium priority, rich interactions
- **P3** — lower priority, specialized use cases
- **iOS26** — new in iOS 26 / WWDC 2025

---

### 3.1 Layout

| SwiftUI View | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `VStack` | — (Auto Layout) | `NSStackView` (orientation=1) | `UI::VStack` | P0 |
| `HStack` | — (Auto Layout) | `NSStackView` (orientation=0) | `UI::HStack` | P0 |
| `ZStack` | — (Auto Layout) | `NSView` (manual subviews) | `UI::ZStack` | P0 |
| `Spacer` | — | `NSView` (flexible) | `UI::Spacer` | P0 |
| `LazyVStack` | — | — | `UI::LazyVStack` (proposed) | P2 |
| `LazyHStack` | — | — | `UI::LazyHStack` (proposed) | P2 |
| `Grid` | — (compositional) | — | `UI::Grid` (proposed) | P2 |
| `GridRow` | — | — | `UI::GridRow` (proposed) | P2 |
| `LazyVGrid` | `UICollectionView` | `NSCollectionView` | `UI::LazyVGrid` (proposed) | P2 |
| `LazyHGrid` | `UICollectionView` | `NSCollectionView` | `UI::LazyHGrid` (proposed) | P2 |
| `ViewThatFits` | — | — | — | P3 |
| `AnyLayout` | — | — | — | P3 |
| `GeometryReader` | — | — | — | P3 |
| `Group` | — (no-op container) | — | — | P2 |
| `Section` | — | — | — | P2 |

Notes:
- `LazyVStack` / `LazyHStack` defer child view creation until needed; UIKit equivalent
  is `UICollectionView` with a diffable data source.
- `Grid` is a two-dimensional layout container (iOS 16+, not lazy). On UIKit it
  requires `UICollectionViewCompositionalLayout`.
- `ViewThatFits` tries views in order and uses the first one that fits in its proposed
  size. No direct UIKit equivalent; requires measurement logic.

---

### 3.2 Scroll and Lists

| SwiftUI View | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `ScrollView` | `UIScrollView` | `NSScrollView` | `UI::ScrollView` | P0 |
| `List` | `UITableView` (older) / `UICollectionView` (newer) | `NSTableView` | `UI::List` (proposed) | P1 |
| `Form` | `UITableView` (grouped) | — | `UI::Form` (proposed) | P2 |
| `Table` | `UICollectionView` | `NSTableView` | `UI::Table` (proposed) | P2 |
| `OutlineGroup` | — | `NSOutlineView` | — | P3 |
| `DisclosureGroup` | — | `NSDisclosureButton` + content | `UI::DisclosureGroup` (proposed) | P2 |
| `ForEach` | — (data-driven loop) | — | — (handled in Crystal loop) | P1 |
| `ScrollViewReader` | — | — | — | P2 |
| `LazyVStack` (in ScrollView) | `UICollectionView` | `NSCollectionView` | — | P2 |

Notes:
- `List` in SwiftUI renders as a `UICollectionView` since iOS 16 (previously
  `UITableView`). The AppKit renderer maps to `NSTableView`.
- `Form` is a styled `List` for settings-style data entry; UIKit uses grouped
  `UITableView` style.
- `Table` is a multi-column tabular display (iOS 16+ / macOS 12+); AppKit uses
  `NSTableView` with multiple `NSTableColumn` instances.

---

### 3.3 Text

| SwiftUI View | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `Text` | `UILabel` | `NSTextField` (non-editable) | `UI::Label` | P0 |
| `Label` (icon+text) | `UILabel` + `UIImageView` | `NSTextField` + `NSImageView` | — (compose manually) | P2 |
| `TextEditor` | `UITextView` | `NSTextView` | `UI::TextEditor` (proposed) | P1 |
| `TextField` | `UITextField` | `NSTextField` (editable) | `UI::TextField` | P0 |
| `SecureField` | `UITextField` (secureTextEntry=YES) | `NSSecureTextField` | `UI::TextField` (secure_entry: true) | P0 |
| `TextEditor` (AttributedString) | `UITextView` | `NSTextView` | `UI::RichTextEditor` (proposed) | P2 |

Notes:
- SwiftUI `Text` maps to a read-only text display. In the AppKit renderer this is
  `NSTextField` with `setEditable:NO`, `setBezeled:NO`, `setDrawsBackground:NO`.
- In iOS 26, `TextEditor` now accepts `AttributedString` for rich text editing
  (bold, italic, color, links). This is **NEW in iOS 26**.
- `Label` (the SwiftUI view with an icon slot) is distinct from `Text`. It displays
  a system SF Symbol alongside text. No single UIKit class; compose from
  `UILabel` + `UIImageView` in a horizontal arrangement.

---

### 3.4 Images and Media

| SwiftUI View | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `Image` | `UIImageView` | `NSImageView` | `UI::Image` | P0 |
| `AsyncImage` | `UIImageView` + async loading | `NSImageView` + async loading | `UI::AsyncImage` (proposed) | P1 |
| `VideoPlayer` | `AVPlayerViewController` | `AVPlayerView` | `UI::VideoPlayer` (proposed) | P3 |
| `PhotosPicker` | `PHPickerViewController` | — | — | P3 |

Notes:
- `AsyncImage` loads an image from a URL asynchronously, showing a placeholder during
  load. No single UIKit class; uses `URLSession` + `UIImageView`.
- `VideoPlayer` is from the `AVKit` framework, not UIKit. UIKit class is
  `AVPlayerViewController`; AppKit is `AVPlayerView`.
- `PhotosPicker` presents the system photo library picker.

---

### 3.5 Controls

| SwiftUI View | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `Button` | `UIButton` | `NSButton` | `UI::Button` | P0 |
| `Toggle` | `UISwitch` | `NSSwitch` | `UI::Toggle` (proposed) | P1 |
| `Slider` | `UISlider` | `NSSlider` | `UI::Slider` (proposed) | P1 |
| `Stepper` | `UIStepper` | `NSStepper` | `UI::Stepper` (proposed) | P2 |
| `Picker` | `UIPickerView` / `UISegmentedControl` | `NSPopUpButton` / `NSSegmentedControl` | `UI::Picker` (proposed) | P2 |
| `DatePicker` | `UIDatePicker` | `NSDatePicker` | `UI::DatePicker` (proposed) | P2 |
| `ColorPicker` | `UIColorPickerViewController` | `NSColorWell` | `UI::ColorPicker` (proposed) | P3 |
| `Menu` | `UIMenu` / `UIContextMenuInteraction` | `NSMenu` / `NSPopUpButton` | `UI::Menu` (proposed) | P2 |
| `Link` | — (opens URL) | — | — | P2 |
| `ShareLink` | `UIActivityViewController` | `NSSharingServicePicker` | — | P3 |
| `PasteButton` | — | — | — | P3 |
| `EditButton` | — | — | — | P3 |
| `ControlGroup` | — | — | — | P3 |
| `GlassButtonStyle` | `UIGlassEffectView` | `NSGlassEffectView` | — (modifier) | P2 |

Notes:
- `Toggle` renders as `UISwitch` on iOS and `NSSwitch` on macOS 10.15+.
- `Slider` renders as `UISlider` on iOS and `NSSlider` on macOS.
- `Picker` style determines the underlying control: `.menu` style uses `UIButton` with
  a `UIMenu` on iOS; `.segmented` uses `UISegmentedControl`; `.wheel` uses
  `UIPickerView`. On macOS, `.menu` uses `NSPopUpButton`, `.segmented` uses
  `NSSegmentedControl`.
- **NEW in iOS 26**: `GlassButtonStyle` applies the Liquid Glass treatment to a
  `Button`, rendering it with glass border artwork based on the button's context.
- **NEW in iOS 26**: `Slider` gains custom tick support via `SliderTickContentForEach`
  and a new initializer that accepts a range with custom tick displays.

---

### 3.6 Navigation

| SwiftUI View | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `NavigationStack` | `UINavigationController` | — | `UI::NavigationStack` (proposed) | P1 |
| `NavigationSplitView` | `UISplitViewController` | `NSSplitViewController` | `UI::NavigationSplitView` (proposed) | P2 |
| `TabView` | `UITabBarController` | — | `UI::TabView` (proposed) | P1 |
| `NavigationLink` | `UINavigationController` push | — | — | P1 |
| `NavigationPath` | — | — | — | P2 |

Notes:
- `NavigationStack` is the modern replacement for `NavigationView` (deprecated iOS 16+).
  UIKit: `UINavigationController`. Provides type-safe push/pop with `NavigationPath`.
- `TabView` renders as `UITabBarController` on iOS. On macOS it renders as a tab
  switcher using `NSTabView`. In iOS 26, `TabView` gains:
  - `.tabBarMinimizeBehavior(_:)` modifier — tab bar shrinks to a single pill and
    shifts left during downward scroll; expands when the user scrolls back up
  - `tabViewBottomAccessoryPlacement` — places content above the tab bar
  - `.bottomAccessory` — a new tab role for accessory content
  - The tab bar surface renders with Liquid Glass by default

New iOS 26 TabView modifiers:
```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Search", systemImage: "magnifyingglass") { SearchView() }
}
.tabBarMinimizeBehavior(.onScrollDown)
```

---

### 3.7 Presentation and Modals

| SwiftUI View / Modifier | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `.sheet(isPresented:)` | `UIViewController.present()` modal | `NSPanel` / sheet | — (modifier) | P2 |
| `.fullScreenCover` | `UIViewController.present()` fullscreen | — | — | P2 |
| `.alert` | `UIAlertController` (.alert) | `NSAlert` | — (modifier) | P2 |
| `.confirmationDialog` | `UIAlertController` (.actionSheet) | `NSAlert` | — | P2 |
| `.popover` | `UIPopoverPresentationController` | `NSPopover` | — | P2 |
| `.inspector` | — | — | — | P3 |
| `.contextMenu` | `UIContextMenuInteraction` | `NSMenu` (contextual) | — | P2 |
| `.actionSheet` (deprecated) | `UIAlertController` (.actionSheet) | — | — | — |

Notes:
- **NEW in iOS 26**: Sheets are inset by default (floating above the base view with
  Liquid Glass backgrounds at half-height detent). At smaller detent heights, the
  bottom edges pull in, nestling in the display's curved corners.
- **NEW in iOS 26**: `.sheet` gains `.presentationDragIndicatorVisibility()` for
  controlling the drag indicator.

---

### 3.8 Toolbars and Bars

| SwiftUI Concept | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `.toolbar` modifier | `UIToolbar` / `UINavigationBar` | `NSToolbar` | — (modifier) | P2 |
| `ToolbarItem` | `UIBarButtonItem` | `NSToolbarItem` | — | P2 |
| `ToolbarItemGroup` | — | `NSToolbarItemGroup` | — | P2 |
| `ToolbarSpacer` | `UIBarButtonItem(barButtonSystemItem: .flexibleSpace)` | `NSToolbarFlexibleSpaceItem` | — | P2 |

Notes:
- **NEW in iOS 26**: `ToolbarSpacer` is a new built-in spacer item for organizing
  toolbar content. Previously developers had to create `ToolbarItem { Spacer() }`.
- **NEW in iOS 26**: `ToolbarItem` supports `.sharedBackgroundVisibility(_:)` for
  controlling whether items share the Liquid Glass background surface.
- **NEW in iOS 26**: New placement values: `.largeTitle`, `.title`, `.subtitle`,
  `.largeSubtitle` for placing content in title areas.
- In iOS 26, toolbar items sit on a Liquid Glass surface that floats above app content
  and automatically adapts to what is beneath it.

---

### 3.9 Search

| SwiftUI Modifier | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `.searchable(text:)` | `UISearchController` | `NSSearchField` | — (modifier) | P2 |
| `.searchSuggestions(_:)` | — | — | — | P2 |
| `.searchScopes(_:)` | `UISearchController.scopeButtonTitles` | — | — | P3 |
| `SearchSuggestion` | — | — | — | P3 |

---

### 3.10 Shapes and Drawing

| SwiftUI View | UIKit Equivalent | AppKit Equivalent | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `Rectangle` | `UIView` (layer) | `NSView` (layer) | — (use background modifier) | P1 |
| `RoundedRectangle` | `UIView` (cornerRadius) | `NSView` (cornerRadius) | — | P1 |
| `Circle` | `UIView` (cornerRadius=50%) | `NSView` | — | P1 |
| `Ellipse` | `UIView` (oval mask) | `NSView` | — | P2 |
| `Capsule` | `UIView` (cornerRadius=height/2) | `NSView` | — | P2 |
| `Path` | `UIBezierPath` / `CAShapeLayer` | `NSBezierPath` | — | P3 |
| `Canvas` | — (manual `CGContext` drawing) | — (manual `NSGraphicsContext`) | `UI::Canvas` (proposed) | P3 |
| `Shape` protocol | — | — | — | P3 |
| `TimelineView` | — | — | — | P3 |

Notes:
- Shapes in SwiftUI are pure value types that conform to `Shape` and render into
  `Path`. UIKit/AppKit have no direct equivalent structure; they use `CAShapeLayer`
  or direct `CGContext` drawing.
- `Canvas` (iOS 15+) provides a procedural 2D drawing API using `GraphicsContext`,
  analogous to HTML5 Canvas. The underlying implementation uses `CGContext`.

---

### 3.11 Visual Effects

| SwiftUI Modifier | UIKit Equivalent | AppKit Equivalent | Notes |
|---|---|---|---|
| `.blur(radius:)` | `CIFilter(name: "CIGaussianBlur")` / `UIVisualEffectView` | `CIFilter` | |
| `.shadow(color:radius:x:y:)` | `CALayer.shadowColor/shadowRadius` | `CALayer` | |
| `.opacity(_:)` | `UIView.alpha` | `NSView.alphaValue` | |
| `.colorMultiply(_:)` | — | — | Compositing |
| `.rotation3DEffect(_:axis:)` | `CALayer.transform` (3D) | `CALayer.transform` | |
| `.scaleEffect(_:)` | `UIView.transform` / `CALayer.transform` | `NSView` / `CALayer` | |
| `.offset(_:)` | `UIView.frame.origin` | `NSView.frame.origin` | |
| `.mask(_:)` | `CALayer.mask` | `CALayer.mask` | |
| `.clipShape(_:)` | `UIView.clipsToBounds` + `layer.cornerRadius` | same | |
| `.background(_:)` | `UIView.backgroundColor` / `UIVisualEffectView` | `NSView.layer.backgroundColor` | |
| `.overlay(_:)` | layered subview | layered subview | |
| `.glassEffect()` | `UIGlassEffectView` | `NSGlassEffectView` | NEW iOS 26 |
| `.backgroundExtensionEffect()` | — | — | NEW iOS 26 — mirrors view edges |

Notes:
- **NEW in iOS 26**: `.backgroundExtensionEffect()` duplicates a view into mirrored
  copies that are placed around the view's edges. This creates the effect of
  extending content into surrounding areas (used for immersive backgrounds).

---

### 3.12 Animation

| SwiftUI API | UIKit Equivalent | Notes |
|---|---|---|
| `withAnimation(_:_:)` | `UIView.animate(withDuration:)` | |
| `.animation(_:value:)` | `CAAnimation` | Implicit animation modifier |
| `.transition(_:)` | `UIViewControllerTransitioningDelegate` | View insertion/removal |
| `Animation.spring()` | `UISpringTimingParameters` | |
| `Animation.easeIn/Out/InOut` | `UIViewAnimationOptions` curves | |
| `Animation.bouncy` | `UISpringAnimation` | |
| `TimelineView` | `CADisplayLink` | Frame-driven animation |
| `PhaseAnimator` | — | Multi-phase sequential animation (iOS 17+) |
| `KeyframeAnimator` | `CAKeyframeAnimation` | Keyframe-based (iOS 17+) |
| `@Animatable` macro | — | NEW iOS 26 — auto-synthesizes Animatable conformance |
| SF Symbols draw-on effect | — | NEW iOS 26 — new `.drawOn` symbol animation |

Notes:
- **NEW in iOS 26**: The `@Animatable` macro automatically synthesizes conformance
  to the `Animatable` protocol for custom views and view modifiers. Previously this
  required manual `animatableData` property implementation.
- **NEW in iOS 26**: SF Symbols gain a new `.drawOn` animation effect that traces the
  symbol's path as a draw-on entry animation.

---

### 3.13 Gestures

| SwiftUI Gesture | UIKit Equivalent | Notes |
|---|---|---|
| `TapGesture` | `UITapGestureRecognizer` | |
| `LongPressGesture` | `UILongPressGestureRecognizer` | |
| `DragGesture` | `UIPanGestureRecognizer` | |
| `MagnifyGesture` | `UIPinchGestureRecognizer` | |
| `RotateGesture` | `UIRotationGestureRecognizer` | |
| `SpatialTapGesture` | — | 3D / spatial computing (visionOS) |
| `.onTapGesture(count:)` | Target-action on control / `UITapGestureRecognizer` | Modifier shorthand |
| `.simultaneousGesture` | Multiple gesture recognizers | |
| `.highPriorityGesture` | `gestureRecognizer:shouldBeRequiredToFailBy:` | |

---

### 3.14 Haptics

| SwiftUI API | UIKit Equivalent | Notes |
|---|---|---|
| `.sensoryFeedback(_:trigger:)` | `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` / `UISelectionFeedbackGenerator` | iOS 17+ |

Haptic styles:
- `.impact(weight:intensity:)` → `UIImpactFeedbackGenerator(style: .light/.medium/.heavy/.rigid/.soft)`
- `.selection` → `UISelectionFeedbackGenerator`
- `.success` / `.warning` / `.error` → `UINotificationFeedbackGenerator`

---

### 3.15 Accessibility

| SwiftUI Modifier | UIKit Equivalent | AppKit Equivalent |
|---|---|---|
| `.accessibilityLabel(_:)` | `UIView.accessibilityLabel` | `NSView.accessibilityLabel` |
| `.accessibilityHint(_:)` | `UIView.accessibilityHint` | `NSView.accessibilityHint` |
| `.accessibilityValue(_:)` | `UIView.accessibilityValue` | `NSView.accessibilityValue` |
| `.accessibilityHidden(_:)` | `UIView.isAccessibilityElement = false` | `NSView.isAccessibilityElement` |
| `.accessibilityAction(_:_:)` | `UIAccessibilityCustomAction` | `NSAccessibilityCustomAction` |
| `AccessibilityRotor` | `UIAccessibilityCustomRotor` | — |
| `.accessibilityAddTraits(_:)` | `UIView.accessibilityTraits` | — |
| `.accessibilityFocused(_:)` | — | — |
| `.accessibilityElement(children:)` | — | — |

Notes:
- The AppKit renderer in asset_pipeline already sets `accessibilityLabel` via
  `objc_send_id(ptr, sel("setAccessibilityLabel:"), a11y_str)` in
  `apply_common_properties`.

---

### 3.16 Maps and Location (MapKit)

| SwiftUI View | UIKit Class | AppKit Class | Priority |
|---|---|---|---|
| `Map` | `MKMapView` | `MKMapView` | P3 |
| `MapAnnotation` | `MKAnnotationView` | `MKAnnotationView` | P3 |
| `MapCircle` | `MKCircle` overlay | `MKCircle` | P3 |
| `MapPolyline` | `MKPolyline` overlay | `MKPolyline` | P3 |
| `MapPolygon` | `MKPolygon` overlay | `MKPolygon` | P3 |
| `MapCameraPosition` | — | — | P3 |

---

### 3.17 Charts (Swift Charts)

| SwiftUI View / Type | UIKit / AppKit | Priority |
|---|---|---|
| `Chart` | `CALayer` / custom | P3 |
| `BarMark` | — | P3 |
| `LineMark` | — | P3 |
| `PointMark` | — | P3 |
| `AreaMark` | — | P3 |
| `RuleMark` | — | P3 |
| `SectorMark` (pie/donut) | — | P3 |
| `Chart3D` | — | P3 |
| `SurfacePlot` | — | P3 |

Notes:
- **NEW in iOS 26**: `Chart3D` and `SurfacePlot` for three-dimensional data
  visualization. These are Metal-backed and have no UIKit class equivalent.
- Swift Charts renders entirely using Core Animation and Metal; there is no
  UIKit view class hierarchy to bridge against.

---

### 3.18 Widgets and App Intents

| Type | Framework | Notes |
|---|---|---|
| `WidgetFamily` | WidgetKit | smallSquare, mediumRectangle, etc. |
| `TimelineProvider` | WidgetKit | Drives widget updates |
| `AppIntent` | App Intents | Siri / Shortcuts integration |
| `AppShortcut` | App Intents | Exposes functionality to Siri |
| `ControlWidget` | WidgetKit | Lock Screen / Control Center controls |

Notes:
- These are not renderered by the PlatformVisitor; they are registered with the
  system. No Crystal equivalent planned.

---

### 3.19 WebView (NEW in iOS 26)

| SwiftUI View | UIKit Class | AppKit Class | Crystal Equivalent | Priority |
|---|---|---|---|---|
| `WebView` | `WKWebView` | `WKWebView` | `UI::WebView` (proposed) | P1 |
| `WebPage` | `WKWebView` data model | same | — | P1 |

Notes:
- **NEW in iOS 26**: `WebView` is a first-class SwiftUI view for displaying web
  content. Before iOS 26, developers had to wrap `WKWebView` in a
  `UIViewRepresentable`. The underlying engine is still WebKit (`WKWebView`).
- `WebPage` is an observable model object that represents the loaded web page,
  exposing properties like `title`, `url`, `isLoading`, and methods like `reload()`.
- Crystal bridge pattern using `WKWebView` directly via ObjC runtime is possible.

---

### 3.20 Other New iOS 26 Views and Modifiers

| SwiftUI API | Category | Notes |
|---|---|---|
| `GlassButtonStyle` | Controls | Button style with Liquid Glass border artwork |
| `GlassEffectContainer` | Layout | Groups glass elements for morphing |
| `.glassEffect()` | Modifier | Applies Liquid Glass to any view |
| `.glassEffectID(_:in:)` | Modifier | Identity for glass morphing transitions |
| `.backgroundExtensionEffect()` | Modifier | Mirrors view edges into surrounding area |
| `.tabBarMinimizeBehavior(_:)` | TabView | Collapses tab bar on scroll |
| `tabViewBottomAccessoryPlacement` | TabView | Positions content above tabs |
| `ToolbarSpacer` | Toolbar | Standard flexible spacing in toolbars |
| `.sharedBackgroundVisibility(_:)` | Toolbar | Controls Liquid Glass background per item |
| `Chart3D` / `SurfacePlot` | Charts | 3D data visualization |
| `WebView` / `WebPage` | Web | Native web content embedding |
| `TextEditor` + `AttributedString` | Text | Rich text editing |
| `@Animatable` macro | Animation | Auto-synthesizes Animatable protocol |
| `.sectionIndexLabel(_:)` | List | Section index labels for fast scrolling |
| `.listSectionIndexVisibility(_:)` | List | Control index label visibility |
| `List` section margins | List | Per-section margin control |
| `ScrollView` `.scrollEdgeEffect(.hard)` | Scroll | Hard cutoff + dividing line at scroll edges |
| `.navigationSubtitle(_:)` | Navigation | Secondary navigation title |
| `.labelIconToTitleSpacing(_:)` | Label | Custom spacing between icon and text |
| `.labelReservedIconWidth(_:)` | Label | Fixed-width icon slot in labels |
| `.presentationDragIndicatorVisibility(_:)` | Sheet | Control drag indicator visibility |
| SF Symbols draw-on animation | Animation | New `.drawOn` symbol effect |

---

## 4. UIKit View Classes (Complete Reference)

All classes listed inherit from `UIView` unless otherwise noted. Classes marked
**[iOS 26]** are new in iOS 26.

### 4.1 Base Infrastructure

| Class | Description | ObjC Superclass |
|---|---|---|
| `UIView` | Base class for all visual elements | `UIResponder` |
| `UIControl` | Base for interactive controls (touch events) | `UIView` |
| `UIWindow` | Top-level container; one per scene | `UIView` |
| `UIResponder` | Base for event handling chain | `NSObject` |

### 4.2 Text Display and Input

| Class | Description | Superclass |
|---|---|---|
| `UILabel` | Static text display, single or multi-line | `UIView` |
| `UITextField` | Single-line text input | `UIControl` |
| `UITextView` | Multi-line scrollable text input / display | `UIScrollView` |
| `UISearchTextField` | Text field with search-specific behavior | `UITextField` |

Crystal mapping:
- `UILabel` → `UI::Label`
- `UITextField` → `UI::TextField`
- `UITextField` (secureTextEntry=YES) → `UI::TextField` (secure_entry: true)
- `UITextView` → `UI::TextEditor` (proposed)

### 4.3 Images and Media

| Class | Description | Superclass |
|---|---|---|
| `UIImageView` | Displays `UIImage` | `UIView` |

Crystal mapping: `UIImageView` → `UI::Image`

### 4.4 Controls

| Class | Description | Key Properties | Superclass |
|---|---|---|---|
| `UIButton` | Tappable button | `setTitle:forState:`, `setImage:forState:` | `UIControl` |
| `UISwitch` | Boolean on/off toggle | `isOn`, `setOn:animated:` | `UIControl` |
| `UISlider` | Continuous value slider | `value`, `minimumValue`, `maximumValue` | `UIControl` |
| `UIStepper` | Increment/decrement control | `value`, `stepValue`, `minimumValue` | `UIControl` |
| `UISegmentedControl` | Multi-segment selector | `selectedSegmentIndex` | `UIControl` |
| `UIPageControl` | Dot-style page indicator | `currentPage`, `numberOfPages` | `UIControl` |
| `UIDatePicker` | Date/time picker wheel | `date`, `datePickerMode`, `preferredDatePickerStyle` | `UIControl` |
| `UIColorWell` | Color selection control (iOS 14+) | `selectedColor` | `UIControl` |

`UIDatePickerMode` enum values:
- `UIDatePickerModeTime = 0`
- `UIDatePickerModeDate = 1`
- `UIDatePickerModeDateAndTime = 2`
- `UIDatePickerModeCountDownTimer = 3`

`UIDatePickerStyle` enum values (iOS 14+):
- `UIDatePickerStyleAutomatic = 0`
- `UIDatePickerStyleWheels = 1`
- `UIDatePickerStyleCompact = 2`
- `UIDatePickerStyleInline = 3`

### 4.5 Pickers

| Class | Description | Superclass |
|---|---|---|
| `UIPickerView` | Spinning wheel data picker | `UIView` |

`UIPickerView` requires a `UIPickerViewDataSource` and `UIPickerViewDelegate`.

### 4.6 Scroll, Table, Collection

| Class | Description | Superclass |
|---|---|---|
| `UIScrollView` | Scrollable content area | `UIView` |
| `UITableView` | Vertical list of cells | `UIScrollView` |
| `UITableViewCell` | Single row in a table | `UIView` |
| `UICollectionView` | Multi-directional grid/list | `UIScrollView` |
| `UICollectionViewCell` | Single item in a collection | `UIView` |
| `UICollectionReusableView` | Supplementary view (header/footer) | `UIView` |

`UITableViewStyle` enum:
- `UITableViewStylePlain = 0`
- `UITableViewStyleGrouped = 1`
- `UITableViewStyleInsetGrouped = 2`

Modern layout classes (iOS 13+):
- `UICollectionViewCompositionalLayout` — section-based compositional layout
- `UICollectionViewDiffableDataSource<SectionType, ItemType>` — type-safe data
- `NSDiffableDataSourceSnapshot` — snapshot of section/item state
- `UICollectionLayoutListConfiguration` — list appearance for compositional layout

### 4.7 Stack and Layout

| Class | Description | Superclass |
|---|---|---|
| `UIStackView` | Auto Layout-managed stack | `UIView` |

`UIStackView` properties:
- `axis`: `UILayoutConstraintAxisHorizontal = 0`, `UILayoutConstraintAxisVertical = 1`
- `distribution`: `.fill=0`, `.fillEqually=1`, `.fillProportionally=2`, `.equalSpacing=3`, `.equalCentering=4`
- `alignment`: `.fill=0`, `.leading=1`, `.top=1`, `.firstBaseline=2`, `.center=3`, `.trailing=4`, `.bottom=4`, `.lastBaseline=5`
- `spacing`: CGFloat

Crystal mapping:
- `UIStackView` (axis=Vertical) → `UI::VStack`
- `UIStackView` (axis=Horizontal) → `UI::HStack`

### 4.8 Visual Effects and Glass

| Class | Description | Superclass |
|---|---|---|
| `UIVisualEffectView` | Blur / vibrancy effects | `UIView` |
| `UIBlurEffect` | Gaussian blur visual effect | `UIVisualEffect` |
| `UIVibrancyEffect` | Vibrancy effect (requires blur) | `UIVisualEffect` |
| `UIGlassEffect` | Liquid Glass effect descriptor **[iOS 26]** | `UIVisualEffect` |
| `UIGlassEffectView` | View with Liquid Glass material **[iOS 26]** | `UIVisualEffectView` |
| `UIGlassEffectContainerView` | Groups glass views for morphing **[iOS 26]** | `UIView` |

`UIBlurEffect` style enum values:
- `.extraLight = 0`
- `.light = 1`
- `.dark = 2`
- `.regular = 4`
- `.prominent = 5`
- `.systemUltraThinMaterial = 6`
- `.systemThinMaterial = 7`
- `.systemMaterial = 8`
- `.systemThickMaterial = 9`
- `.systemChromeMaterial = 10`

`UIGlassEffectStyle` enum values (iOS 26):
- `UIGlassEffectStyleRegular = 0`
- `UIGlassEffectStyleClear = 1`

### 4.9 Progress Indicators

| Class | Description | Superclass |
|---|---|---|
| `UIProgressView` | Horizontal progress bar | `UIView` |
| `UIActivityIndicatorView` | Spinning activity indicator | `UIView` |

`UIActivityIndicatorView` style enum:
- `UIActivityIndicatorViewStyleMedium = 100`
- `UIActivityIndicatorViewStyleLarge = 101`

### 4.10 Navigation and Tab Chrome

| Class | Description | Superclass |
|---|---|---|
| `UINavigationBar` | Navigation title and button area | `UIView` |
| `UITabBar` | Bottom tab bar with icons | `UIView` |
| `UITabBarItem` | Single tab item | `UIBarItem` |
| `UIToolbar` | Bottom toolbar for action buttons | `UIView` |
| `UISearchBar` | Composite search control | `UIView` |
| `UIBarButtonItem` | Button item for navigation/toolbar bar | `UIBarItem` |

### 4.11 Alerts and Menus

| Class | Description | Superclass |
|---|---|---|
| `UIAlertController` | Alert and action sheet | `UIViewController` |
| `UIAlertAction` | Action within alert | `NSObject` |
| `UIMenu` | Hierarchical menu (iOS 14+) | `UIMenuElement` |
| `UIAction` | Concrete menu action | `UIMenuElement` |
| `UIContextMenuInteraction` | Context menu via long press | `NSObject` |

`UIAlertControllerStyle` enum:
- `UIAlertControllerStyleActionSheet = 0`
- `UIAlertControllerStyleAlert = 1`

### 4.12 Web Content

| Class | Description | Framework |
|---|---|---|
| `WKWebView` | WebKit web content view | WebKit |
| `WKWebViewConfiguration` | Configuration for WKWebView | WebKit |
| `WKUserScript` | JavaScript injection | WebKit |

### 4.13 Split and Multi-Column

| Class | Description | Superclass |
|---|---|---|
| `UISplitViewController` | Primary/supplementary/secondary columns | `UIViewController` |

### 4.14 Drawing Canvas

| Class | Description | Superclass |
|---|---|---|
| `PKCanvasView` | PencilKit drawing canvas | `UIScrollView` |

### 4.15 Scroll Content Refresh

| Class | Description | Superclass |
|---|---|---|
| `UIRefreshControl` | Pull-to-refresh control | `UIControl` |

---

## 5. AppKit View Classes (Complete Reference)

All classes listed inherit from `NSView` unless otherwise noted. Classes marked
**[macOS 26]** are new in macOS Tahoe 26.

### 5.1 Base Infrastructure

| Class | Description | ObjC Superclass |
|---|---|---|
| `NSView` | Base class for all AppKit visual elements | `NSResponder` |
| `NSControl` | Base for interactive controls | `NSView` |
| `NSWindow` | Top-level window container | `NSResponder` |
| `NSPanel` | Auxiliary floating window | `NSWindow` |

### 5.2 Text Display and Input

| Class | Description | Superclass |
|---|---|---|
| `NSTextField` | Single-line text field (editable or static) | `NSControl` |
| `NSSecureTextField` | Password field (masked input) | `NSTextField` |
| `NSTextView` | Multi-line rich text editor | `NSText` |
| `NSText` | Abstract text view base | `NSView` |
| `NSSearchField` | Text field with search behavior | `NSTextField` |
| `NSComboBox` | Editable field with dropdown suggestions | `NSTextField` |
| `NSTokenField` | Token-based text input | `NSTextField` |

Crystal mapping:
- `NSTextField` (non-editable) → `UI::Label`
- `NSTextField` (editable) → `UI::TextField`
- `NSSecureTextField` → `UI::TextField` (secure_entry: true)
- `NSTextView` → `UI::TextEditor` (proposed)
- `NSSearchField` → `UI::SearchField` (proposed)

### 5.3 Images and Media

| Class | Description | Superclass |
|---|---|---|
| `NSImageView` | Displays `NSImage` | `NSControl` |

Crystal mapping: `NSImageView` → `UI::Image`

### 5.4 Controls

| Class | Description | Key Properties | Superclass |
|---|---|---|---|
| `NSButton` | Clickable button (many styles) | `title`, `bezelStyle`, `buttonType` | `NSControl` |
| `NSPopUpButton` | Dropdown button with menu | `selectedItem`, `menu` | `NSButton` |
| `NSSwitch` | Boolean on/off toggle (macOS 10.15+) | `state` | `NSControl` |
| `NSSlider` | Continuous value slider | `doubleValue`, `minValue`, `maxValue` | `NSControl` |
| `NSStepper` | Increment/decrement | `doubleValue`, `increment` | `NSControl` |
| `NSSegmentedControl` | Multi-segment selector | `selectedSegment` | `NSControl` |
| `NSDatePicker` | Date/time picker | `dateValue`, `datePickerStyle` | `NSControl` |
| `NSColorWell` | Color selection control | `color` | `NSControl` |
| `NSLevelIndicator` | Bar-style level/meter indicator | `doubleValue`, `levelIndicatorStyle` | `NSControl` |
| `NSRatingIndicator` | Star rating (macOS 10.14+) | `doubleValue`, `maxValue` | `NSLevelIndicator` |
| `NSPathControl` | File path display/selection | `url` | `NSControl` |

`NSButton` `bezelStyle` integer values:
- `NSBezelStyleRounded = 1`
- `NSBezelStyleRegularSquare = 2`
- `NSBezelStyleShadowlessSquare = 6`
- `NSBezelStyleCircular = 7`
- `NSBezelStyleTexturedSquare = 8`
- `NSBezelStyleHelpButton = 9`
- `NSBezelStyleSmallSquare = 10`
- `NSBezelStyleTexturedRounded = 11`
- `NSBezelStyleRoundRect = 12`
- `NSBezelStyleRecessed = 13`
- `NSBezelStyleRoundedDisclosure = 14`
- `NSBezelStyleInline = 15`

Crystal mapping:
- `NSButton` → `UI::Button`
- `NSSwitch` → `UI::Toggle` (proposed)
- `NSSlider` → `UI::Slider` (proposed)
- `NSStepper` → `UI::Stepper` (proposed)
- `NSSegmentedControl` → `UI::Picker` (segmented style) (proposed)
- `NSPopUpButton` → `UI::Picker` (menu style) (proposed)
- `NSDatePicker` → `UI::DatePicker` (proposed)
- `NSColorWell` → `UI::ColorPicker` (proposed)

### 5.5 Scroll, Table, Collection, Outline

| Class | Description | Superclass |
|---|---|---|
| `NSScrollView` | Scrollable content with optional scrollbars | `NSView` |
| `NSClipView` | The inner clip/scroll content view | `NSView` |
| `NSScroller` | Scroll bar indicator | `NSControl` |
| `NSTableView` | Column-based tabular data display | `NSControl` |
| `NSTableColumn` | A single column definition | `NSObject` |
| `NSTableCellView` | Cell view in a view-based table | `NSView` |
| `NSOutlineView` | Hierarchical tree/outline display | `NSTableView` |
| `NSCollectionView` | Grid/list display (similar to UICollectionView) | `NSView` |
| `NSCollectionViewItem` | Single item in a collection | `NSViewController` |

Crystal mapping:
- `NSScrollView` → `UI::ScrollView`
- `NSTableView` → `UI::List` / `UI::Table` (proposed)
- `NSOutlineView` → `UI::OutlineGroup` (proposed)

### 5.6 Stack and Layout

| Class | Description | Superclass |
|---|---|---|
| `NSStackView` | Auto Layout-managed stack (horizontal or vertical) | `NSView` |
| `NSGridView` | Two-dimensional grid layout | `NSView` |
| `NSGridRow` | Row in an NSGridView | `NSObject` |
| `NSGridColumn` | Column in an NSGridView | `NSObject` |
| `NSSplitView` | Resizable split pane layout | `NSView` |

`NSStackView` orientation:
- `NSUserInterfaceLayoutOrientationHorizontal = 0`
- `NSUserInterfaceLayoutOrientationVertical = 1`

Crystal mapping:
- `NSStackView` (orientation=1) → `UI::VStack`
- `NSStackView` (orientation=0) → `UI::HStack`
- `NSSplitView` → `UI::NavigationSplitView` (proposed)

### 5.7 Visual Effects and Glass

| Class | Description | Superclass |
|---|---|---|
| `NSVisualEffectView` | Blur / vibrancy material view | `NSView` |
| `NSGlassEffectView` | Liquid Glass material view **[macOS 26]** | `NSView` |
| `NSGlassEffectContainerView` | Groups glass views **[macOS 26]** | `NSView` |

`NSVisualEffectView` material enum values:
- `NSVisualEffectMaterialTitlebar = 3`
- `NSVisualEffectMaterialSelection = 4`
- `NSVisualEffectMaterialMenu = 5`
- `NSVisualEffectMaterialPopover = 6`
- `NSVisualEffectMaterialSidebar = 7`
- `NSVisualEffectMaterialHeaderView = 10`
- `NSVisualEffectMaterialSheet = 11`
- `NSVisualEffectMaterialWindowBackground = 12`
- `NSVisualEffectMaterialHudWindow = 13`
- `NSVisualEffectMaterialFullScreenUI = 15`
- `NSVisualEffectMaterialToolTip = 17`
- `NSVisualEffectMaterialContentBackground = 18`
- `NSVisualEffectMaterialUnderWindowBackground = 21`
- `NSVisualEffectMaterialUnderPageBackground = 22`

Crystal mapping:
- `NSGlassEffectView` → `UI::GlassView` (proposed)

### 5.8 Progress Indicators

| Class | Description | Superclass |
|---|---|---|
| `NSProgressIndicator` | Progress bar or spinner | `NSView` |

`NSProgressIndicator` style:
- `NSProgressIndicatorStyleBar = 0`
- `NSProgressIndicatorStyleSpinning = 1`

Crystal mapping: `NSProgressIndicator` → `UI::ProgressView` (proposed)

### 5.9 Toolbars

| Class | Description | Superclass |
|---|---|---|
| `NSToolbar` | Window toolbar containing items | `NSObject` |
| `NSToolbarItem` | Single item in a toolbar | `NSObject` |
| `NSToolbarItemGroup` | Group of toolbar items | `NSToolbarItem` |
| `NSMenuToolbarItem` | Toolbar item with associated menu | `NSToolbarItem` |
| `NSTrackingSeparatorToolbarItem` | Separator that tracks a split view | `NSToolbarItem` |
| `NSSearchToolbarItem` | Search field as a toolbar item | `NSToolbarItem` |

### 5.10 Disclosure and Boxes

| Class | Description | Superclass |
|---|---|---|
| `NSBox` | Grouping box with optional title | `NSView` |
| `NSDisclosureTriangle` | Expandable disclosure triangle | `NSButton` |

### 5.11 Rulers and Scroll Accessories

| Class | Description | Superclass |
|---|---|---|
| `NSRulerView` | Horizontal or vertical ruler | `NSView` |

---

## 6. Crystal Integration Priority Matrix

This table defines the implementation roadmap for adding native components to the
asset_pipeline `UI::View` system. Views already implemented are P0. Priorities reflect
how commonly the components are used in typical application UIs.

| Priority | Native Component (SwiftUI) | Proposed `UI::View` | UIKit Class | AppKit Class | Web Equivalent |
|---|---|---|---|---|---|
| **P0** | Text / Label | `UI::Label` | `UILabel` | `NSTextField` | `<p>`, `<span>`, `<h1>`-`<h6>` |
| **P0** | Button | `UI::Button` | `UIButton` | `NSButton` | `<button>` |
| **P0** | VStack | `UI::VStack` | `UIStackView` (vertical) | `NSStackView` (v) | CSS flexbox column |
| **P0** | HStack | `UI::HStack` | `UIStackView` (horizontal) | `NSStackView` (h) | CSS flexbox row |
| **P0** | ZStack | `UI::ZStack` | `UIView` (manual) | `NSView` (manual) | CSS position absolute |
| **P0** | Image | `UI::Image` | `UIImageView` | `NSImageView` | `<img>` |
| **P0** | TextField | `UI::TextField` | `UITextField` | `NSTextField` | `<input type="text">` |
| **P0** | ScrollView | `UI::ScrollView` | `UIScrollView` | `NSScrollView` | CSS overflow scroll |
| **P0** | Spacer | `UI::Spacer` | `UIView` (flexible) | `NSView` (flexible) | CSS flex-grow |
| **P1** | Toggle | `UI::Toggle` | `UISwitch` | `NSSwitch` | `<input type="checkbox">` |
| **P1** | Slider | `UI::Slider` | `UISlider` | `NSSlider` | `<input type="range">` |
| **P1** | List | `UI::List` | `UICollectionView` | `NSTableView` | `<ul>` / `<ol>` |
| **P1** | NavigationStack | `UI::NavigationStack` | `UINavigationController` | — | Browser history API |
| **P1** | TabView | `UI::TabView` | `UITabBarController` | `NSTabView` | `<nav>` + tab JS |
| **P1** | ProgressView | `UI::ProgressView` | `UIProgressView` | `NSProgressIndicator` | `<progress>` |
| **P1** | ActivityIndicator | `UI::ActivityIndicator` | `UIActivityIndicatorView` | `NSProgressIndicator` (spinning) | CSS spinner |
| **P1** | AsyncImage | `UI::AsyncImage` | `UIImageView` + async | `NSImageView` + async | `<img loading="lazy">` |
| **P1** | WebView [iOS 26] | `UI::WebView` | `WKWebView` | `WKWebView` | `<iframe>` / `<webview>` |
| **P1** | TextEditor | `UI::TextEditor` | `UITextView` | `NSTextView` | `<textarea>` |
| **P2** | DatePicker | `UI::DatePicker` | `UIDatePicker` | `NSDatePicker` | `<input type="date">` |
| **P2** | Picker | `UI::Picker` | `UIPickerView` / `UISegmentedControl` | `NSPopUpButton` / `NSSegmentedControl` | `<select>` |
| **P2** | Stepper | `UI::Stepper` | `UIStepper` | `NSStepper` | `<input type="number">` |
| **P2** | SegmentedControl | `UI::SegmentedControl` | `UISegmentedControl` | `NSSegmentedControl` | `<div role="tablist">` |
| **P2** | Menu | `UI::Menu` | `UIMenu` + `UIButton` | `NSMenu` / `NSPopUpButton` | `<details>` / custom dropdown |
| **P2** | SearchField | `UI::SearchField` | `UISearchBar` | `NSSearchField` | `<input type="search">` |
| **P2** | DisclosureGroup | `UI::DisclosureGroup` | — | `NSBox` + `NSDisclosureTriangle` | `<details>` + `<summary>` |
| **P2** | NavigationSplitView | `UI::NavigationSplitView` | `UISplitViewController` | `NSSplitView` | CSS two-column layout |
| **P2** | RichTextEditor [iOS 26] | `UI::RichTextEditor` | `UITextView` | `NSTextView` | `contenteditable` div |
| **P2** | LazyVStack | `UI::LazyVStack` | `UICollectionView` | `NSCollectionView` | Intersection Observer list |
| **P2** | LazyHStack | `UI::LazyHStack` | `UICollectionView` | `NSCollectionView` | Intersection Observer list |
| **P2** | Table | `UI::Table` | `UICollectionView` | `NSTableView` | `<table>` |
| **P2** | GlassView [iOS 26] | `UI::GlassView` | `UIGlassEffectView` | `NSGlassEffectView` | CSS `backdrop-filter` |
| **P3** | Map | `UI::Map` | `MKMapView` | `MKMapView` | Leaflet / Google Maps |
| **P3** | Chart | `UI::Chart` | Custom Metal | Custom Metal | Chart.js / D3 |
| **P3** | Canvas | `UI::Canvas` | `CGContext` | `NSGraphicsContext` | `<canvas>` |
| **P3** | ColorPicker | `UI::ColorPicker` | `UIColorPickerViewController` | `NSColorWell` | `<input type="color">` |
| **P3** | VideoPlayer | `UI::VideoPlayer` | `AVPlayerViewController` | `AVPlayerView` | `<video>` |
| **P3** | PhotosPicker | — | `PHPickerViewController` | — | `<input type="file" accept="image/*">` |

---

## 7. ObjC Runtime Bridge Patterns

The asset_pipeline uses a C bridge file (`objc_bridge.c`) with type-safe ARM64
wrappers. Crystal calls these wrappers via `lib LibObjCBridge` bindings defined in
`src/ui/renderers/appkit_renderer.cr`.

### 7.1 Class Allocation Pattern

```crystal
# Step 1: Get the class object by name
cls = LibObjCBridge.objc_getClass("NSButton")

# Step 2: Allocate uninitialized memory
obj = LibObjCBridge.objc_send(cls, sel("alloc"))

# Step 3: Initialize (use init or an initWith... variant)
obj = LibObjCBridge.objc_send(obj, sel("init"))
# or: obj = LibObjCBridge.objc_send_id(obj, sel("initWithFrame:"), frame_ptr)

# Convenience helper already defined:
private def alloc_init(class_name : String) : Void*
  cls = LibObjCBridge.objc_getClass(class_name.to_unsafe)
  obj = LibObjCBridge.objc_send(cls, sel("alloc"))
  LibObjCBridge.objc_send(obj, sel("init"))
end
```

### 7.2 Property Setting Patterns

```crystal
# String property (NSString)
str = LibObjCBridge.nsstring_from_cstr("Hello".to_unsafe)
LibObjCBridge.objc_send_id(ptr, sel("setTitle:"), str)

# Integer / enum property
LibObjCBridge.objc_send_long(ptr, sel("setBezelStyle:"), 1_i64)

# Boolean property (0 = NO, 1 = YES)
LibObjCBridge.objc_send_bool(ptr, sel("setEditable:"), 1)

# Float / Double property
LibObjCBridge.objc_send_1d(ptr, sel("setAlphaValue:"), 0.5)

# Object property (id argument)
color = LibObjCBridge.nscolor_rgba(1.0, 0.0, 0.0, 1.0)  # red
LibObjCBridge.objc_send_id(ptr, sel("setTextColor:"), color)

# CGRect struct (Homogeneous Floating-Point Aggregate on ARM64)
rect = LibObjCBridge::CGRect.new(x: 0.0, y: 0.0, width: 200.0, height: 44.0)
LibObjCBridge.objc_send_rect_void(ptr, sel("setFrame:"), rect)

# Reading a property (returns Void*)
result = LibObjCBridge.objc_send(ptr, sel("stringValue"))

# Reading a string as a Crystal String
raw = LibObjCBridge.objc_send(ptr, sel("stringValue"))
cstr = LibObjCBridge.objc_send(raw, sel("UTF8String"))
crystal_string = String.new(cstr.as(UInt8*)) unless cstr.null?

# Reading a bool (returns Int32)
enabled = LibObjCBridge.objc_send_ret_bool(ptr, sel("isEnabled"))
```

### 7.3 Target-Action Pattern for Controls

UIKit and AppKit controls use the target-action pattern for event callbacks. The
asset_pipeline implements this via a registered `CrystalActionDispatcher` ObjC class:

```crystal
# From appkit_renderer.cr — wiring a button's on_tap callback
if tap_handler = view.on_tap
  callback_id = native.register_callback(tap_handler)

  dispatcher_cls = LibObjCBridge.objc_getClass("CrystalActionDispatcher")
  unless dispatcher_cls.null?
    # Allocate and init a dispatcher instance
    dispatcher = LibObjCBridge.objc_send(dispatcher_cls, sel("alloc"))
    dispatcher = LibObjCBridge.objc_send(dispatcher, sel("init"))

    # Store the callback_id as the NSView tag so dispatch: can route it
    LibObjCBridge.objc_send_long(dispatcher, sel("setTag:"), callback_id.to_i64)

    # Set the button's target and action
    LibObjCBridge.objc_send_id(ptr, sel("setTarget:"), dispatcher)
    LibObjCBridge.objc_send_sel(ptr, sel("setAction:"), sel("dispatch:"))
  end
end
```

For UISwitch (Toggle), wire target-action on `valueChanged:`:

```crystal
# Proposed pattern for UI::Toggle -> UISwitch / NSSwitch
LibObjCBridge.objc_send_id(ptr, sel("setTarget:"), dispatcher)
LibObjCBridge.objc_send_sel(ptr, sel("setAction:"), sel("dispatch:"))
# On iOS: addTarget:action:forControlEvents: with UIControlEventValueChanged (4096)
```

For UISlider (Slider), wire on `valueChanged:`:

```crystal
# Proposed pattern for UI::Slider -> UISlider
# addTarget:action:forControlEvents: with UIControlEventValueChanged (4096)
# selector "dispatch:" — read slider's value in the callback
slider_value = LibObjCBridge.objc_send(slider_ptr, sel("value"))
# Returns float — needs a float return variant in the bridge
```

### 7.4 Delegate Pattern for Callbacks

Some UIKit/AppKit classes use delegates instead of target-action:

```crystal
# NSTextField text change via delegate (controlTextDidChange:)
# From appkit_renderer.cr TextField visitor:
if change_handler = view.on_change
  text_field_ptr = ptr
  wrapped = Proc(Nil).new do
    raw_str = LibObjCBridge.objc_send(text_field_ptr, sel("stringValue"))
    unless raw_str.null?
      cstr = LibObjCBridge.objc_send(raw_str, sel("UTF8String"))
      unless cstr.null?
        change_handler.call(String.new(cstr.as(UInt8*)))
      end
    end
  end
  native.register_callback(wrapped)
end
```

For `UIScrollView` scroll events, the delegate method is `scrollViewDidScroll:`.
For `UITableView`, the data source and delegate provide `tableView:numberOfRowsInSection:`,
`tableView:cellForRowAtIndexPath:`, and selection callbacks.

### 7.5 Adding Subviews

```crystal
# For NSStackView — use addArrangedSubview: to preserve layout ordering
LibObjCBridge.objc_send_void_id(parent_ptr, sel("addArrangedSubview:"), child_ptr)

# For plain NSView / UIView — use addSubview:
LibObjCBridge.objc_add_subview(parent_ptr, child_ptr)

# For NSScrollView — set the documentView
LibObjCBridge.objc_send_id(scroll_ptr, sel("setDocumentView:"), content_ptr)
```

### 7.6 Memory Management

All native views in asset_pipeline are tracked via `NativeHandle` which calls
`objc_retain` on creation and `objc_release` on finalization:

```crystal
# ObjC.owned wraps a raw pointer in a NativeHandle with +1 retain count
handle = ObjC.owned(ptr, label: "NSButton")
native = NativeView.new(handle)

# Call teardown! on the root NativeView to recursively release the tree
native_view.teardown!
```

### 7.7 New iOS 26 UIGlassEffectView Bridge Pattern

```crystal
# Proposed pattern for implementing UI::GlassView on iOS
def visit_ios(view : UI::GlassView)
  # 1. Create UIGlassEffect with desired style
  glass_cls = LibObjCBridge.objc_getClass("UIGlassEffect")
  # UIGlassEffectStyleRegular = 0
  glass_effect = LibObjCBridge.objc_send_long(glass_cls, sel("effectWithStyle:"), 0_i64)

  # 2. Set interactive property if needed
  if view.interactive
    LibObjCBridge.objc_send_bool(glass_effect, sel("setInteractive:"), 1)
  end

  # 3. Create UIGlassEffectView with the effect
  glass_view_cls = LibObjCBridge.objc_getClass("UIGlassEffectView")
  alloc = LibObjCBridge.objc_send(glass_view_cls, sel("alloc"))
  ptr = LibObjCBridge.objc_send_id(alloc, sel("initWithEffect:"), glass_effect)

  # 4. Set corner radius via layer
  LibObjCBridge.objc_send_bool(ptr, sel("setClipsToBounds:"), 1)
  layer = LibObjCBridge.objc_send(ptr, sel("layer"))
  LibObjCBridge.objc_send_1d(layer, sel("setCornerRadius:"), view.corner_radius)

  # 5. Add children to contentView (not directly to the glass view)
  content_view = LibObjCBridge.objc_send(ptr, sel("contentView"))
  # ... add child views to content_view

  apply_common_properties(ptr, view)
  emit(ptr, "UIGlassEffectView")
end
```

### 7.8 Selector Registration

```crystal
# Selectors must be registered before use
private def sel(name : String) : Void*
  LibObjCBridge.sel_registerName(name.to_unsafe)
end

# Common selectors used across the codebase:
# "alloc", "init", "dealloc"
# "setFrame:", "frame"
# "setHidden:", "isHidden"
# "setAlphaValue:", "alpha"              (AppKit: alphaValue, UIKit: alpha)
# "setEnabled:", "isEnabled"
# "addSubview:", "removeFromSuperview"
# "addArrangedSubview:"                  (NSStackView / UIStackView only)
# "setStringValue:", "stringValue"       (AppKit text fields)
# "setText:", "text"                     (UIKit labels/text fields)
# "setTitle:", "title"
# "setFont:", "font"
# "setTextColor:", "textColor"
# "setBackgroundColor:", "backgroundColor"
# "setTarget:", "setAction:"
# "setTag:", "tag"
# "layer", "setWantsLayer:"
# "setBackgroundColor:" (on CALayer, takes CGColor)
# "CGColor"
# "UTF8String"
# "setEditable:", "setSelectable:", "setBezeled:", "setDrawsBackground:"
# "setAlignment:", "setMaximumNumberOfLines:"
# "setPlaceholderString:"
# "setBezelStyle:"
# "setOrientation:", "setSpacing:", "setAlignment:"
# "setImageScaling:", "setImage:", "imageNamed:"
# "setContentTintColor:"
# "setHasVerticalScroller:", "setHasHorizontalScroller:"
# "setScrollerStyle:", "setDocumentView:"
# "setTranslatesAutoresizingMaskIntoConstraints:"
# "setAccessibilityLabel:"
# "setCornerRadius:", "setTintColor:", "contentView"
```

---

## 8. Platform Visitor Extension Guide

To add a new view (e.g., `UI::Toggle`) to the asset_pipeline:

### Step 1: Create the Crystal view type

Create `src/ui/views/toggle.cr`:

```crystal
module UI
  class Toggle < View
    getter label : String
    getter value : Bool
    property on_change : Proc(Bool, Nil)?

    def initialize(@label : String, @value : Bool = false, @on_change : Proc(Bool, Nil)? = nil)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
```

### Step 2: Add visit to PlatformVisitor

In `src/ui/platform_visitor.cr`, add an abstract method or default implementation.

### Step 3: Implement in AppKit::Renderer

```crystal
def visit(view : UI::Toggle)
  # NSSwitch is available on macOS 10.15+
  ptr = alloc_init("NSSwitch")

  # NSControlStateValueOn = 1, NSControlStateValueOff = 0
  state = view.value ? 1_i64 : 0_i64
  LibObjCBridge.objc_send_long(ptr, sel("setState:"), state)

  apply_common_properties(ptr, view)

  handle = ObjC.owned(ptr, label: "NSSwitch")
  native = NativeView.new(handle)

  # Wire on_change via target-action
  if change_handler = view.on_change
    callback_id = native.register_callback(Proc(Nil).new {
      state_val = LibObjCBridge.objc_send_ret_bool(ptr, sel("state"))
      change_handler.call(state_val != 0)
    })

    dispatcher_cls = LibObjCBridge.objc_getClass("CrystalActionDispatcher")
    unless dispatcher_cls.null?
      dispatcher = LibObjCBridge.objc_send(dispatcher_cls, sel("alloc"))
      dispatcher = LibObjCBridge.objc_send(dispatcher, sel("init"))
      LibObjCBridge.objc_send_long(dispatcher, sel("setTag:"), callback_id.to_i64)
      LibObjCBridge.objc_send_id(ptr, sel("setTarget:"), dispatcher)
      LibObjCBridge.objc_send_sel(ptr, sel("setAction:"), sel("dispatch:"))
    end
  end

  push_native(native)
end
```

### Step 4: Implement in WebRenderer

Add HTML rendering in `src/ui/renderers/web_renderer.cr`:

```crystal
def visit(view : UI::Toggle)
  checked = view.value ? " checked" : ""
  id = "toggle-#{object_id}"
  emit_html(%(<label><input type="checkbox" id="#{id}"#{checked}> #{view.label}</label>))
end
```

### Step 5: Wire up in iOS renderer (when iOS renderer exists)

For UISwitch on iOS, the key difference from NSSwitch:
- Class: `UISwitch` (not `NSSwitch`)
- State property: `isOn` (Bool) vs `state` (Int)
- Target-action event: `UIControlEventValueChanged = 4096`
- Method: `addTarget:action:forControlEvents:` (3-argument form)

---

## References

- [Apple introduces Liquid Glass design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [Build a SwiftUI app with the new design - WWDC25](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Build a UIKit app with the new design - WWDC25](https://developer.apple.com/videos/play/wwdc2025/284/)
- [Build an AppKit app with the new design - WWDC25](https://developer.apple.com/videos/play/wwdc2025/310/)
- [What's new in SwiftUI - WWDC25](https://developer.apple.com/videos/play/wwdc2025/256/)
- [SwiftUI for iOS 26 embraces Liquid Glass, introduces WebView and Rich Text Editing - InfoQ](https://www.infoq.com/news/2025/06/swiftui-ios26-liquid-glass/)
- [What's new in SwiftUI for iOS 26 - Hacking with Swift](https://www.hackingwithswift.com/articles/278/whats-new-in-swiftui-for-ios-26)
- [iOS 26 by Examples - GitHub](https://github.com/artemnovichkov/iOS-26-by-Examples)
- [Liquid Glass Reference - GitHub](https://github.com/conorluddy/LiquidGlassReference)
- [UIGlassEffect Class Reference - Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/uikit.uiglasseffect?view=net-ios-26.2-10.0)
- [NSGlassEffectView - Apple Developer Documentation](https://developer.apple.com/documentation/appkit/nsglasseffectview)
- [Exploring tab bars on iOS 26 - Donny Wals](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [WWDC25 SwiftUI Features - Explore SwiftUI](https://exploreswiftui.com/wwdc25)
- [macOS Tahoe Release Notes - Apple Developer](https://developer.apple.com/documentation/macos-release-notes/macos-26-release-notes)
