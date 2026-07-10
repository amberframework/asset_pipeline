---
name: cross-platform-components
description: Overview of the Crystal cross-platform UI component system
version: "1.0"
---

# Cross-Platform UI Component System

## What This System Is

The cross-platform UI component system extends the `asset_pipeline` shard with native rendering for macOS (AppKit), iOS (UIKit), and Android (JNI/Views), alongside the existing web (HTML) output path. A single Crystal source tree defines a `UI::View` abstract class hierarchy that is rendered by platform-specific visitors selected at compile time via `flag?()`. Zero bytes of platform code leak across targets.

**Core model:** App code builds a tree of `UI::View` objects. A compile-time-selected `PlatformRenderer` (a `PlatformVisitor` subclass) walks the tree and produces native UI. The web renderer delegates to the existing `Components::Elements` system; native renderers call through ObjC or JNI bridges.

## Layer Model

```
App Code (single Crystal source)
  |
  v
UI::View (abstract class hierarchy, pointer-sized virtual dispatch)
  |
  v
UI::PlatformVisitor (compile-time selected via flag?())
  |
  +-- Web::Renderer       -> Components::Elements (existing HTML system)
  +-- AppKit::Renderer     -> NSView via ObjC bridge      [flag?(:macos)]
  +-- UIKit::Renderer      -> UIView via ObjC bridge      [flag?(:ios)]
  +-- Android::Renderer    -> Android Views via JNI bridge [flag?(:android)]
```

Layout is 100% delegated to each platform's native engine. There is no custom constraint solver or Flexbox implementation in Crystal. `VStack` maps to `NSStackView` / `UIStackView` / `LinearLayout` / `flex-column`; each platform handles its own geometry.

## The 9 Core View Types

| View Type | Purpose |
|-----------|---------|
| `UI::Label` | Read-only text display with font, color, alignment, and line limit |
| `UI::Button` | Tappable element with a text label and `on_tap` callback |
| `UI::VStack` | Vertical stack layout arranging children top to bottom |
| `UI::HStack` | Horizontal stack layout arranging children leading to trailing |
| `UI::ZStack` | Z-axis overlay stack drawing children back to front |
| `UI::Image` | Image display with content mode and optional tint |
| `UI::TextField` | Editable single-line text input with change callback |
| `UI::ScrollView` | Scrollable container for content exceeding visible bounds |
| `UI::Spacer` | Flexible space that expands within a stack layout |

All view types are classes (not structs) because container views hold `Array(View)` children, creating recursive type relationships that Crystal structs cannot represent.

## When to Use This System

Use the cross-platform UI layer when:

- Building apps that target **web + macOS + iOS + Android** from one Crystal codebase
- You want **native UI** on each platform (not a web view wrapper)
- Your UI can be expressed as a **declarative view tree** of the 9 core view types
- You need **type-safe, compile-time checked** UI code with zero runtime overhead for unused platforms

Do NOT use this when:

- Your app only targets the web (use `Components::Elements` directly)
- You need highly custom rendering (use platform-native code directly)
- You need views not in the 9 core types (extend the system first, see platform-renderers skill)

## Quick Reference: Counter App Example

```crystal
require "ui"

class CounterApp
  @count = 0

  def build_view : UI::View
    stack = UI::VStack.new(spacing: 16.0, alignment: UI::Alignment::Center)

    label = UI::Label.new("Count: #{@count}")
    label.font = UI::Font.new(size: 24.0, weight: :bold)
    stack << label

    button = UI::Button.new("Increment") { @count += 1; nil }
    stack << button

    stack
  end
end
```

This single definition renders as:

- **Web:** `<div style="display:flex;flex-direction:column;gap:16px">` with `<span>` and `<button>` children
- **macOS:** `NSStackView(vertical)` containing `NSTextField` (non-editable) and `NSButton`
- **iOS:** `UIStackView(.vertical)` containing `UILabel` and `UIButton`
- **Android:** `LinearLayout(VERTICAL)` containing `TextView` and `MaterialButton`

## Compile-Time Platform Selection

The platform renderer is selected at compile time with zero runtime branching:

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

The Crystal compiler eliminates all code for non-selected platforms. A macOS binary contains zero Android code, and vice versa.

## Key Source Locations

| File | Purpose |
|------|---------|
| `src/ui/view.cr` | `UI::View` abstract class, `Color`, `Font`, `EdgeInsets`, enums |
| `src/ui/views/*.cr` | All 9 concrete view types |
| `src/ui/platform_visitor.cr` | `UI::PlatformVisitor` abstract class with 9 `visit` methods |
| `src/ui.cr` | Top-level require that pulls in the full UI module |

## Related Skills

- **component-api** -- Full API reference for all view types, value types, and patterns
- **platform-renderers** -- How each renderer maps views to native elements
- **glass-effects** -- Apple glass/translucency effect integration
- **build-ui** -- Existing web component system (83 HTML elements, builder DSL)
