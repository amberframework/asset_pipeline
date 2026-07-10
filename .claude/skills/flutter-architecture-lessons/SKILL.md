---
name: flutter-architecture-lessons
description: |
  Architecture patterns and lessons learned from Flutter's widget system, adapted for
  Crystal's native-rendering approach. Covers the three-tree model, constraint-based
  layout, platform adaptation, and key differences from asset_pipeline's PlatformVisitor
  approach. Guides architectural decisions for expanding the cross-platform component system.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
version: "1.0.0"
---

# Flutter Architecture Lessons

This document captures what the asset_pipeline team has learned from studying Flutter's architecture, what we adopt, what we explicitly reject, and where Flutter's pain points validate our design choices.

## 1. Flutter's Architecture Overview

Flutter builds UI with three parallel trees that coexist at runtime:

### The Three Trees

**Widget tree** — Immutable, lightweight descriptions of UI. Widgets are plain Dart objects with no identity; they are rebuilt frequently (potentially on every frame). The widget tree is the developer-facing declaration of what the UI should look like. `StatelessWidget.build()` and `StatefulWidget.build()` return widget trees.

**Element tree** — Mutable, long-lived objects that Flutter creates once and updates in place. Each widget has a corresponding element. The element tracks the widget's position in the tree, holds references to child elements, and manages the widget lifecycle (mount, rebuild, unmount). The element tree is Flutter's internal book-keeping layer — developers rarely interact with it directly.

**RenderObject tree** — Does the actual layout math and painting. Each element that represents a visible component has a corresponding `RenderObject`. RenderObjects implement `performLayout()` (size and position children using BoxConstraints) and `paint()` (draw pixels using Canvas). This tree is what ultimately drives Skia/Impeller to put pixels on screen.

The reason Flutter needs three trees: widgets are immutable (easy to create/discard), elements provide stable identity across rebuilds (so Flutter can diff old vs. new widget trees efficiently), and RenderObjects are expensive to construct and carry layout state that must persist across frames.

### Why Three Trees Are Necessary for Flutter

Flutter does its own layout and painting. Because it cannot delegate layout to a native engine, it must do layout math itself — hence RenderObjects. Because widgets are immutable and rebuilt constantly, Flutter needs a stable layer (elements) to track what changed. If Flutter used native widgets it could drop to one tree. It doesn't. We do.

### Crystal's Two-Layer Model

```
App code builds UI::View tree (immutable-style declarations)
  |
  v
UI::PlatformVisitor walks the tree (compile-time selected)
  |
  +-- Web::Renderer       -> HTML/CSS  (no layout math needed; CSS handles it)
  +-- AppKit::Renderer    -> NSView    (no layout math; NSStackView handles it)
  +-- UIKit::Renderer     -> UIView    (no layout math; UIStackView handles it)
  +-- Android::Renderer   -> Views     (no layout math; LinearLayout handles it)
```

We have no Element tree because Crystal's `UI::View` objects are not rebuilt every frame — they are constructed once per build pass and handed to the visitor. We have no RenderObject tree because we delegate all layout math to native engines. Our design is simpler by design, not by accident.

---

## 2. What We Adopt from Flutter

### 2a. Declarative View Tree

Flutter's widget tree is a declarative description of UI — it says *what* the UI is, not *how* to draw it. Our `UI::View` tree serves exactly the same purpose.

| Flutter | Crystal |
|---------|---------|
| `Widget.build()` returns a widget tree | `build_view()` returns a `UI::View` tree |
| Tree is rebuilt when state changes | Tree is rebuilt when state changes |
| Framework diffs old vs. new tree | Visitor re-renders from the tree directly |
| Tree is pure description | Tree is pure description |

The key mental model is identical: write a function that describes UI as a tree of values, and let the system turn that into visible pixels. Neither Flutter nor our system expects the developer to imperatively mutate a live display list.

### 2b. Composition Over Inheritance

Flutter composes small single-purpose widgets into larger ones. `Card` in Flutter is implemented as `Material` wrapping `Padding` wrapping a `Column`. No deep class hierarchy. We should follow this.

**Do not** create a `UI::Card` class with 20 properties. **Do** compose existing primitives:

```crystal
def card(title : String, body : String, &on_action : -> Nil) : UI::View
  stack = UI::VStack.new(spacing: 12.0)
  stack.padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
  stack.background = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)

  title_label = UI::Label.new(title)
  title_label.font = UI::Font.new(size: 20.0, weight: :bold)
  stack << title_label

  stack << UI::Label.new(body)
  stack << UI::Button.new("Action", &on_action)
  stack
end
```

This is a factory function, not a class. It composes three existing view types. The visitor already knows how to render all three. No new `visit` method needed, no new platform implementations needed. This is the right default.

### 2c. Constraint-Based Layout Thinking

Flutter's constraint system is elegant and worth internalizing even though we never implement it ourselves:

> Constraints go down. Sizes go up. Parent sets position.

The layout protocol works as follows: a parent passes a `BoxConstraints` (min/max width and height) down to each child. The child decides its size within those bounds and reports it back up. The parent then positions each child. This is a one-pass layout, which is what makes it fast.

We do not implement this protocol — native layout engines do it for us. But the mental model maps cleanly:

- `UI::VStack(spacing: 16.0, alignment: .leading)` expresses constraints: children are arranged vertically with 16pt gaps, aligned to the leading edge.
- The native engine (NSStackView, UIStackView, LinearLayout, CSS flexbox) applies this constraint to measure and position children.
- Our `spacing` and `alignment` properties *are* constraints expressed as values; we just let the platform solve them.

Understanding Flutter's constraint model helps reason about why our `VStack`/`HStack`/`ZStack` properties are what they are, and it guides the design of new container types.

### 2d. Platform-Adaptive Components

Flutter's `.adaptive()` constructors (e.g., `Switch.adaptive`, `Slider.adaptive`, `CircularProgressIndicator.adaptive`) select the platform-appropriate widget at runtime by reading `Theme.of(context).platform`.

Our `PlatformVisitor` does this at compile time via `flag?()`. Both approaches solve the same problem — matching UI affordances to the platform the user is running on — but our approach eliminates runtime branching entirely:

| Aspect | Flutter `.adaptive()` | Crystal `PlatformVisitor` |
|--------|----------------------|--------------------------|
| Selection time | Runtime | Compile time |
| Mechanism | `Theme.of(context).platform` | `flag?()` macro |
| Runtime cost | Branch per render | Zero |
| Flexibility | Can change at runtime | Fixed per binary |
| Use case | Single binary, multiple platforms | Separate binary per platform |

Our approach is more efficient and produces smaller binaries. The tradeoff is that a single binary cannot serve multiple platform targets — which is fine because we cross-compile anyway.

When adding new view types, if the behavior differs across platforms, express that difference in the per-platform `visit` implementation, not in a runtime branch in the view class. The visitor pattern is our `.adaptive()`.

### 2e. State Management Patterns

Flutter's state management evolution (setState → InheritedWidget → Provider → Riverpod) reflects the difficulty of propagating state changes through a widget tree that is rebuilt constantly. Flutter developers spend significant time choosing and learning state management libraries.

Our state model is simpler because we do not rebuild the entire tree on every state change:

| Flutter | Crystal |
|---------|---------|
| `StatefulWidget` + `setState()` | `UI::State(T)` with `on_change` listener |
| `InheritedWidget` for propagation | Captured variables in builder block |
| Provider/Riverpod for complex apps | `UI::ViewAdapter` + `invalidate!` |
| Full subtree rebuild on change | Builder block called, renderer re-renders |

```crystal
count = UI::State(Int32).new(0)

adapter = UI::ViewAdapter.new do
  stack = UI::VStack.new(spacing: 16.0)
  stack << UI::Label.new("Count: #{count.value}")
  stack << UI::Button.new("Increment") { count.value += 1; nil }
  stack.as(UI::View)
end

count.on_change { |_, _| adapter.invalidate! }
```

The builder block captures `count` by reference. When `invalidate!` is called, the block runs again, producing a new view tree with the updated count. No state management library needed. The simplicity is an advantage, not a limitation.

---

## 3. What We Explicitly Do NOT Adopt

### 3a. Custom Drawing Engine

Flutter paints every pixel itself using Skia (older releases) or Impeller (current). This means Flutter reimplemented text rendering, scroll physics, animations, input handling, selection handles, cursor blinking, context menus, drag-and-drop, and hundreds of other behaviors that native platforms provide for free.

**Flutter's stated advantage:** Pixel-perfect consistency across platforms — a Flutter button looks identical on iOS, Android, and the web.

**Flutter's actual disadvantage:** Inconsistency with the platform the user is running on. Users on iOS expect iOS scrolling physics, iOS text selection handles, iOS keyboard behavior. Flutter apps can feel slightly "off" even when beautifully designed. This is why `.adaptive()` constructors exist — they are an acknowledgement that consistency-with-platform matters.

**Our advantage:** Native look-and-feel, native accessibility, native scrolling physics, native text selection, native keyboard behavior, native context menus — all for free. `UIScrollView` has momentum scrolling, rubber-band overscroll, and snap behavior that took Apple years to perfect. We get all of it automatically.

**Our disadvantage:** Pixel-level visual differences across platforms (a `UI::Button` looks like an `NSButton` on macOS and a `MaterialButton` on Android). This is not a bug; it is what users expect.

**Decision:** We will never add a custom drawing layer to replace native rendering. If a view type needs custom appearance, style it with platform APIs (background colors, corner radii, shadows via view properties), not custom painting.

### 3b. Three-Tree Architecture

We do not need an Element tree or a RenderObject tree. See Section 1 for the full explanation. Our `UI::View` tree feeds directly into `PlatformVisitor`. No intermediate layers.

If performance profiling ever shows that constructing view trees is a bottleneck, the correct fix is to cache or diff view trees at the Crystal level — not to add a Flutter-style element tree. But this is extremely unlikely given that native layout engines are doing the expensive work.

### 3c. Custom Layout Protocol

Flutter's `RenderBox.performLayout()` with `BoxConstraints` is necessary because Flutter does layout itself. We do not. NSStackView, UIStackView, LinearLayout, and CSS flexbox are each more capable than any layout engine we would write, and they have been debugged against thousands of edge cases over decades.

If a complex layout cannot be expressed with `VStack`/`HStack`/`ZStack` properties, the correct fix is one of:
1. Add a new view type that maps to the appropriate native container (e.g., a grid view).
2. Use platform-specific layout via a platform-native code path (acceptable for complex one-off layouts).
3. Compose multiple nested stacks creatively.

Do not add a constraint solver or layout arithmetic to Crystal. Let the platform do it.

### 3d. GlobalKey System

Flutter's `GlobalKey` allows cross-tree widget identity — finding a specific widget from anywhere in the tree. It is notoriously complex and has sharp footguns (performance problems, lifecycle bugs).

Our equivalent: `view.id = "my-view"`. Native frameworks have their own view identity and lookup systems (`viewWithTag:` on iOS, `view(withIdentifier:)` on macOS, `findViewById` on Android). We expose `id` on `UI::View` for testing and debugging. We do not need a global registry.

---

## 4. Lessons from Flutter's Pain Points

### 4a. Text Input Is Hard to Reimplement

Flutter reimplemented text input from scratch. As of 2024–2025, text input in Flutter still has platform-specific edge cases: autocorrect behavior, IME (input method editor) handling for CJK languages, copy/paste integration with the system clipboard, drag-to-select, and smart punctuation all require ongoing maintenance across platforms.

**Lesson:** Never custom-implement text input. Always use `UITextField` (iOS), `NSTextField` (macOS), `EditText` (Android), `<input>` (web). These have been battle-tested with every keyboard layout, locale, accessibility tool, and OS version. `UI::TextField` must always map to the native text input widget on every platform.

### 4b. Accessibility Requires Platform Integration

Flutter's accessibility layer sits atop its custom rendering tree. It must synthesize an accessibility tree from scratch and keep it synchronized with the visual tree. This is difficult and error-prone. Flutter apps occasionally have screen reader regressions when widgets are rebuilt.

**Lesson:** Native components carry accessibility for free. `UILabel` already supports VoiceOver. `NSTextField` already supports VoiceOver and the macOS accessibility APIs. `TextView` already supports TalkBack. Our job is to surface the right semantic information to each native component:

- Set `accessibility_label` on `UI::View`.
- The platform renderer maps it to `accessibilityLabel` (iOS/macOS), `contentDescription` (Android), or `aria-label` (web).
- The platform's accessibility subsystem does the rest.

We should never synthesize accessibility trees ourselves. The `accessibility_label` property exists on `UI::View` for exactly this reason.

### 4c. Platform-Specific Behaviors Matter to Users

Flutter's approach of simulating platform behaviors (scroll physics, pull-to-refresh, page transitions) in pure Dart is never quite right. iOS users notice when scroll bounce feels slightly off. Android users notice when transitions don't match Material motion specs.

**Lesson:** Do not try to unify scrolling behavior, animation curves, or interaction physics. Let each platform be native.

`UI::ScrollView` maps to `UIScrollView` on iOS (with momentum scrolling and rubber-band overscroll), `NSScrollView` on macOS (with elastic scrolling and scroll wheel inertia), `ScrollView` on Android (with Material overscroll glow), and `overflow: auto` on web (with browser-native scroll). Each platform gets exactly its own behavior. This is correct.

### 4d. Web Target Is Weak When You Custom-Paint

Flutter's web output compiles to either HTML+CSS (which uses DOM elements) or CanvasKit (which renders with Skia to a `<canvas>` element). The CanvasKit path has poor SEO (no semantic HTML), poor accessibility (screen readers cannot read canvas content), and large initial load size (the Skia WASM binary). The HTML path is more web-native but has layout limitations.

**Lesson:** Our web renderer produces real, semantic HTML+CSS. A `UI::Label` becomes a `<span>` with appropriate styles. A `UI::VStack` becomes a `<div>` with `display: flex`. Search engines can index this. Screen readers can read it. CSS can style it. The browser's rendering engine does layout. This is the right approach for web.

Never add a Canvas-based rendering path for the web renderer. If custom drawing is ever needed on the web, it should go through a separate `UI::Canvas` view type (see the graphics-rendering skill), not replace the HTML renderer.

### 4e. Deep Widget Nesting ("Pyramid of Doom")

Flutter code frequently nests 10–15 levels of widgets to compose complex layouts, even for simple screens. This is because everything in Flutter is a widget — including invisible concerns like padding, alignment, and decoration. The result is code that is hard to read and hard to edit.

```dart
// Flutter — common pattern (illustrative, not a quote)
return Scaffold(
  body: Center(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(...),
            child: Padding(
              child: Text("Hello"),
            ),
          ),
        ],
      ),
    ),
  ),
);
```

**Lesson:** Crystal's `<<` operator for adding children and the property-based API for padding/background reduces nesting significantly. A `VStack` with padding is one object with a `padding` property, not two nested objects. Preserve this pattern when adding new view types.

For future DSL work, consider builder patterns that further reduce nesting:

```crystal
# Builder pattern concept (future API)
UI::VStack.build(spacing: 16.0) do |stack|
  stack.label("Title") { |l| l.font = UI::Font.new(size: 20.0, weight: :bold) }
  stack.label("Body text goes here")
  stack.button("Action") { do_action }
end
```

---

## 5. Architecture Comparison Table

| Aspect | Flutter | asset_pipeline (Crystal) |
|--------|---------|--------------------------|
| Rendering engine | Custom (Skia / Impeller) | Native (UIKit / AppKit / Views / HTML) |
| Layout engine | Custom (RenderBox / BoxConstraints) | Delegated to platform |
| Tree model | 3 trees: Widget, Element, RenderObject | 1 tree: UI::View + PlatformVisitor |
| Platform dispatch | Runtime (`.adaptive()`, `Theme.platform`) | Compile time (`flag?()` macro) |
| Accessibility | Custom synthesized tree | Inherited from native components |
| Text input | Custom reimplementation | Native components only |
| Scrolling physics | Simulated per-platform in Dart | Native (UIScrollView, NSScrollView, etc.) |
| Web rendering | CanvasKit (Skia/WASM) or HTML | Semantic HTML + CSS |
| State management | setState / Provider / Riverpod | `UI::State(T)` + `ViewAdapter` |
| Code language | Dart | Crystal |
| Hot reload | Yes (JIT-compiled Dart) | No (but fast release compilation) |
| App size | Larger (bundles Skia + Dart VM) | Smaller (links native frameworks) |
| Platform look-and-feel | Simulated (not native) | Genuine native |

---

## 6. Recommended Architecture Patterns

Based on Flutter lessons, these patterns are recommended for the asset_pipeline:

### Pattern 1: Component Factory Functions

Composition via factory functions is the preferred way to build reusable UI. Do not subclass `UI::View` for composite components; instead write a function that returns a composed view tree.

```crystal
def card(title : String, body : String, &on_action : -> Nil) : UI::View
  stack = UI::VStack.new(spacing: 12.0)
  stack.padding = UI::EdgeInsets.new(top: 16.0, trailing: 16.0, bottom: 16.0, leading: 16.0)
  stack.background = UI::Color.new(r: 1.0, g: 1.0, b: 1.0)

  title_label = UI::Label.new(title)
  title_label.font = UI::Font.new(size: 20.0, weight: :bold)
  stack << title_label

  stack << UI::Label.new(body)
  stack << UI::Button.new("Action", &on_action)
  stack
end
```

This composes three existing view types. No new `visit` methods, no new platform code needed.

### Pattern 2: Modifier Chain (Future API Concept)

Inspired by SwiftUI modifiers and Jetpack Compose's `Modifier` chain — allows a fluent, readable API for styling views without deep nesting.

```crystal
# Future API concept — not yet implemented
UI::Label.new("Hello")
  .font(size: 24.0, weight: :bold)
  .foreground(UI::Color.new(r: 0.0, g: 0.478, b: 1.0))
  .padding(16.0)
  .background(UI::Color.new(r: 1.0, g: 1.0, b: 1.0))
  .corner_radius(8.0)
  .shadow(radius: 4.0)
```

Each modifier method would return `self` (or a wrapper) so the chain can be continued. This is more readable than the current property-assignment style for deeply styled views.

### Pattern 3: Conditional Platform Content

When views genuinely need platform-specific content in shared code:

```crystal
stack = UI::VStack.new(spacing: 16.0)

{% if flag?(:ios) || flag?(:macos) %}
  # Apple glass effect (see glass-effects skill)
  stack.background = UI::GlassBackground.new(material: :sidebar)
{% elsif flag?(:android) %}
  # Material 3 surface elevation
  stack.background = UI::MaterialSurface.new(elevation: 2)
{% else %}
  # Web fallback: light grey
  stack.background = UI::Color.new(r: 0.95, g: 0.95, b: 0.95)
{% end %}
```

The `flag?()` macro means this branching is resolved at compile time — the binary contains only one branch. No runtime cost.

### Pattern 4: Theme System (Future)

Inspired by Flutter's `MaterialTheme` and SwiftUI's environment, a theme system would allow semantic color roles rather than hardcoded values:

```crystal
# Future API concept
theme = UI::Theme.new(
  primary:    UI::Color.new(r: 0.0,  g: 0.478, b: 1.0),
  on_primary: UI::Color.new(r: 1.0,  g: 1.0,   b: 1.0),
  surface:    UI::Color.new(r: 1.0,  g: 1.0,   b: 1.0),
  on_surface: UI::Color.new(r: 0.0,  g: 0.0,   b: 0.0),
  secondary:  UI::Color.new(r: 0.33, g: 0.33,  b: 0.33)
)

UI::Theme.apply(theme) do
  # All views in this block use semantic colors from the theme
  stack << UI::Button.new("Primary Action")  # automatically gets theme.primary background
end
```

This avoids hardcoded RGBA values scattered through view builder functions and enables dark-mode switching by swapping themes.

---

## 7. Related Skills

- **cross-platform-components** — Overview of the full system, the 9 core view types, and when to use the UI layer
- **platform-renderers** — How each renderer maps views to native elements, how to add new view types
- **glass-effects** — Apple glass/translucency integration (Pattern 3 example for iOS/macOS)
- **component-api** — Full API reference for all existing view types and value types
