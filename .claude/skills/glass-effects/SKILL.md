---
name: glass-effects
description: Apple glass/translucency effect integration via NSVisualEffectView (macOS) and UIVisualEffectView (iOS)
version: "1.0"
---

# Apple Glass Effect Integration

This skill covers how to use Apple's vibrancy/translucency glass effects from Crystal via the ObjC runtime bridge. Glass effects allow UI to blur and tint the content behind a window or behind another view, creating the frosted-glass appearance used throughout macOS and iOS.

## macOS: NSVisualEffectView

`NSVisualEffectView` is the macOS class for glass/translucency effects. It blurs and tints content behind the view or behind the window.

### Three Key Properties

| Property | Selector | Type | Description |
|----------|----------|------|-------------|
| Material | `setMaterial:` | `NSInteger` | What the effect looks like (color/tint) |
| Blending Mode | `setBlendingMode:` | `NSInteger` | What gets blurred (window background or view behind) |
| State | `setState:` | `NSInteger` | When the effect is active |

### Material Constants

| Value | Name | Appearance |
|-------|------|------------|
| 0 | `NSVisualEffectMaterialAppearanceBased` | Matches app appearance (deprecated) |
| 1 | `NSVisualEffectMaterialLight` | Light translucent (deprecated, use Titlebar) |
| 2 | `NSVisualEffectMaterialDark` | Dark translucent (deprecated, use HUDWindow) |
| 3 | `NSVisualEffectMaterialTitlebar` | Window title bar appearance |
| 4 | `NSVisualEffectMaterialSelection` | Selected content appearance |
| 5 | `NSVisualEffectMaterialMenu` | Menu background |
| 6 | `NSVisualEffectMaterialPopover` | Popover background |
| 7 | `NSVisualEffectMaterialSidebar` | Sidebar background |
| 8 | `NSVisualEffectMaterialHeaderView` | Header view background |
| 9 | `NSVisualEffectMaterialSheet` | Sheet background |
| 10 | `NSVisualEffectMaterialWindowBackground` | Standard window background |
| 11 | `NSVisualEffectMaterialHUDWindow` | HUD window (heads-up display) |
| 12 | `NSVisualEffectMaterialFullScreenUI` | Full screen UI background |
| 13 | `NSVisualEffectMaterialToolTip` | Tooltip background |
| 14 | `NSVisualEffectMaterialContentBackground` | Content area background |
| 15 | `NSVisualEffectMaterialUnderWindowBackground` | Under-window background |
| 16 | `NSVisualEffectMaterialUnderPageBackground` | Under-page background |

### Blending Mode Constants

| Value | Name | Description |
|-------|------|-------------|
| 0 | `BehindWindow` | Blurs content behind the window (desktop, other windows) |
| 1 | `WithinWindow` | Blurs content behind this view within the same window |

### State Constants

| Value | Name | Description |
|-------|------|-------------|
| 0 | `FollowsWindowActiveState` | Effect active only when window is key/main |
| 1 | `Active` | Effect always active, even when window is not focused |
| 2 | `Inactive` | Effect always inactive (appears opaque) |

### Crystal Example: macOS Glass Window

```crystal
# Create the visual effect view filling the content area
content_view = LibObjC.objc_send(window, sel("contentView"))
content_frame = LibObjC.objc_get_frame(content_view)

visual_effect = LibObjC.objc_send_rect(
  alloc("NSVisualEffectView"), sel("initWithFrame:"), content_frame)

# Material: HUDWindow (dark translucent panel)
LibObjC.objc_send_long(visual_effect, sel("setMaterial:"), 11_i64)

# Blending: behind the window (blurs desktop and other windows)
LibObjC.objc_send_long(visual_effect, sel("setBlendingMode:"), 0_i64)

# State: always active (even when window loses focus)
LibObjC.objc_send_long(visual_effect, sel("setState:"), 1_i64)

# Fill entire content area on resize
# Width-sizable (2) | Height-sizable (16) = 18
LibObjC.objc_set_autoresize(visual_effect, 18_u64)

# Add as subview of the content view
LibObjC.objc_add_subview(content_view, visual_effect)

# Now add UI elements as children of the visual effect view
LibObjC.objc_add_subview(visual_effect, title_label)
LibObjC.objc_add_subview(visual_effect, button)
```

### Sidebar Glass Pattern

A common pattern for apps with a sidebar:

```crystal
# Sidebar with sidebar material
sidebar = LibObjC.objc_send_rect(
  alloc("NSVisualEffectView"), sel("initWithFrame:"),
  LibObjC::CGRect.new(x: 0.0, y: 0.0, width: 240.0, height: 600.0))
LibObjC.objc_send_long(sidebar, sel("setMaterial:"), 7_i64)  # Sidebar
LibObjC.objc_send_long(sidebar, sel("setBlendingMode:"), 0_i64)
LibObjC.objc_send_long(sidebar, sel("setState:"), 0_i64)  # Follow window state
```

---

## iOS: UIVisualEffectView

`UIVisualEffectView` is the iOS equivalent. It takes a `UIVisualEffect` object (either `UIBlurEffect` or `UIVibrancyEffect`) rather than individual material/blending/state properties.

### UIBlurEffect Styles

| Value | Name | Appearance |
|-------|------|------------|
| 0 | `UIBlurEffectStyleExtraLight` | Extra light blur |
| 1 | `UIBlurEffectStyleLight` | Light blur |
| 2 | `UIBlurEffectStyleDark` | Dark blur |
| 3 | `UIBlurEffectStyleRegular` | Adapts to light/dark mode (iOS 10+) |
| 4 | `UIBlurEffectStyleProminent` | Adapts, more opaque than Regular (iOS 10+) |
| 10 | `UIBlurEffectStyleSystemMaterial` | System material (iOS 13+) |
| 11 | `UIBlurEffectStyleSystemMaterialLight` | System material, light |
| 12 | `UIBlurEffectStyleSystemMaterialDark` | System material, dark |
| 13 | `UIBlurEffectStyleSystemThinMaterial` | Thin system material |
| 14 | `UIBlurEffectStyleSystemUltraThinMaterial` | Ultra thin system material |
| 15 | `UIBlurEffectStyleSystemThickMaterial` | Thick system material |
| 16 | `UIBlurEffectStyleSystemChromeMaterial` | Chrome-style system material |

### Crystal Example: iOS Glass

```crystal
# Create a blur effect
blur_cls = LibObjC.objc_getClass("UIBlurEffect")
blur_effect = LibObjC.objc_send_long(
  blur_cls.as(LibObjC::Id), sel("effectWithStyle:"), 3_i64)  # Regular

# Create the visual effect view with the blur
visual_effect = LibObjC.objc_send_id(
  alloc("UIVisualEffectView"), sel("initWithEffect:"), blur_effect)

# Set frame (or use Auto Layout)
LibObjC.objc_send_rect_void(visual_effect, sel("setFrame:"),
  LibObjC::CGRect.new(x: 0.0, y: 0.0, width: 375.0, height: 667.0))

# Add UI elements to the contentView of the visual effect view
content_view = LibObjC.objc_send(visual_effect, sel("contentView"))
LibObjC.objc_add_subview(content_view, label)
```

### Vibrancy Effect (Text/Icons on Glass)

For text and icons that should vibrate (change opacity/blend) with the glass:

```crystal
# First create the blur effect
blur_effect = LibObjC.objc_send_long(
  LibObjC.objc_getClass("UIBlurEffect").as(LibObjC::Id),
  sel("effectWithStyle:"), 3_i64)

# Create vibrancy effect referencing the blur
vibrancy_cls = LibObjC.objc_getClass("UIVibrancyEffect")
vibrancy_effect = LibObjC.objc_send_id(
  vibrancy_cls.as(LibObjC::Id),
  sel("effectForBlurEffect:"), blur_effect)

# Create a secondary visual effect view for vibrant content
vibrant_view = LibObjC.objc_send_id(
  alloc("UIVisualEffectView"), sel("initWithEffect:"), vibrancy_effect)

# Add vibrant content (labels, icons) to this view's contentView
vibrant_content = LibObjC.objc_send(vibrant_view, sel("contentView"))
LibObjC.objc_add_subview(vibrant_content, label)

# Add the vibrant view inside the blur view's contentView
blur_content = LibObjC.objc_send(blur_visual_effect_view, sel("contentView"))
LibObjC.objc_add_subview(blur_content, vibrant_view)
```

---

## ARM64 Calling Convention Considerations

Glass effects involve selectors with multiple `Float64` (CGFloat) arguments, which makes the ARM64 calling convention critical.

### The Problem

On ARM64, `objc_msgSend` is a raw assembly trampoline. It does not know the types of arguments. The **caller** must set up registers correctly:

- **Integer/pointer arguments:** `x0` (self), `x1` (_cmd), `x2`-`x7` (method args)
- **Float/double arguments:** `d0`-`d7` (independent register bank)
- **CGRect:** Passed as HFA (Homogeneous Floating-point Aggregate) in `d0`-`d3`

If you cast `objc_msgSend` to a function pointer with fewer double parameters than the actual ObjC method expects, the higher `d` registers contain garbage from prior computations. This produces random colors, invisible views (alpha = 0.0 or NaN), or crashes.

### The Solution

Every unique combination of (return type, parameter types) has a dedicated C wrapper function in `objc_bridge.c`. Key wrappers used for glass effects:

```c
// Material, blending, state (all take NSInteger = long)
void* objc_send_long(void* self, SEL sel, long arg1);

// NSVisualEffectView initWithFrame: (CGRect = 4 doubles as HFA)
void* objc_send_rect(void* self, SEL sel, CGRect rect);

// Autoresize mask (NSUInteger = unsigned long)
void objc_set_autoresize(void* view, unsigned long mask);

// NSColor creation (4 doubles: r, g, b, a)
void* nscolor_rgba(double r, double g, double b, double a);
void* nscolor_white_alpha(double white, double alpha);
```

### Rule

Never cast `objc_msgSend` directly in Crystal with a generic function pointer. Always go through the typed wrapper in `objc_bridge.c`. If a new ObjC method needs a combination of argument types not covered by existing wrappers, add a new wrapper function to the bridge.

### Existing Typed Wrappers for Float/Double Arguments

| Wrapper | Signature | Use case |
|---------|-----------|----------|
| `objc_send_1d` | `(id, SEL, d0)` | Single double arg (e.g., `setAlphaValue:`) |
| `objc_send_2d_ret_id` | `(id, SEL, d0, d1) -> id` | Two doubles returning object |
| `objc_send_4d_ret_id` | `(id, SEL, d0, d1, d2, d3) -> id` | Four doubles returning object (color creation) |
| `objc_send_rect` | `(id, SEL, CGRect) -> id` | CGRect HFA argument (frame init) |
| `objc_send_rect_void` | `(id, SEL, CGRect)` | CGRect HFA, no return (setFrame:) |
| `nscolor_rgba` | `(r, g, b, a) -> id` | NSColor RGBA creation |
| `nscolor_srgba` | `(r, g, b, a) -> id` | NSColor sRGB creation |
| `nscolor_white_alpha` | `(w, a) -> id` | NSColor grayscale creation |

---

## Integration with the UI Component System

When glass effects are integrated into the cross-platform `UI::View` system, they would be handled at the renderer level rather than as a view type. For example, the `AppKit::Renderer` could apply glass effects to any view with a specific `background` configuration:

```crystal
# Future API concept
stack = UI::VStack.new(spacing: 12.0)
stack.background = UI::GlassBackground.new(
  material: :sidebar,
  blending: :behind_window
)
```

The web renderer would map this to CSS `backdrop-filter: blur()`, the AppKit renderer to `NSVisualEffectView`, and the UIKit renderer to `UIVisualEffectView`.

---

## Working Demo Reference

A complete working macOS app with glass effects is at:

```
/Users/crimsonknight/open_source_coding_projects/crystal/samples/cross_platform/macos_app.cr
```

Build and run:
```bash
cd /Users/crimsonknight/open_source_coding_projects/crystal/samples/cross_platform
clang -c objc_bridge.c -o objc_bridge.o
bin/crystal build macos_app.cr --link-flags="objc_bridge.o" -o macos_app
./macos_app
```

This demo creates a window with `NSVisualEffectMaterialHUDWindow` (material 13), `BehindWindow` blending (0), and `Active` state (1), showing Crystal-generated labels and a button on top of the glass surface.
