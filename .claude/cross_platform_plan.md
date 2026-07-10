# Crystal Cross-Platform UI Component System - Architecture Plan (v2, Updated)

---

## Section 1: Executive Summary

This document describes the validated architecture for extending the `asset_pipeline` shard with cross-platform native rendering. A single Crystal source tree compiles to web (HTML via the existing component system), macOS (AppKit), iOS (UIKit), and Android (JNI/Views) using Crystal's compile-time `flag?()` macro for zero-overhead platform dispatch.

**Core model:** A class-based `UI::View` abstract hierarchy feeds a visitor pattern renderer that is selected at compile time. Each platform renderer produces native UI using the ObjC runtime bridge (macOS/iOS) or the JNI bridge (Android); the web renderer delegates directly to the existing `Components::Elements` system.

**Key update from v1:** This revision incorporates corrections from 9 independent research reviews and addresses all 13 validator findings. The most significant changes are:

- `UI::View` is an **abstract class**, not a struct or module. Crystal prohibits recursive structs; `Array(View)` requires pointer-sized virtual dispatch, identical to the `ASTNode` / `Component` / `HTMLElement` patterns already in use.
- Layout is **fully delegated to each platform's native engine**. There is no custom constraint solver. `VStack` maps to `NSStackView` / `UIStackView` / `LinearLayout` / `flex-column`; each platform handles its own geometry.
- Memory management uses a **`NativeHandle` class** with an explicit `ReleaseStrategy` enum rather than implicit GC finalizers alone.
- A **`CallbackRegistry` module** prevents Crystal `Proc` closures from being collected while native code holds function pointers.
- Cross-compilation targets iOS and Android using the **full Crystal stdlib** (with cross-compiled `libgc` + `libpcre2`), not `--prelude=empty`.

---

## Section 2: Current State

### 2.1 Asset Pipeline (v0.36.0)

The `asset_pipeline` shard provides 83 HTML elements organised into a typed component hierarchy:

- **Component hierarchy**: `Component` > `StatelessComponent` / `StatefulComponent` > `ReactiveComponent`
- **HTML elements**: 83 elements across sections, grouping, forms, tables, embedded, text semantics, interactive, and void categories. All implement `#render : String` and `#render_attributes`.
- **Reactive WebSocket layer**: `ReactiveComponent#push_update` broadcasts HTML diffs to all sessions via `ReactiveHandler`. Actions route from `data-action` attributes through `ReactiveSession` dispatch.
- **State**: JSON-compatible state with change tracking and Redis/memory cache backends.
- **300+ CSS utilities** with WCAG accessibility compliance.

### 2.2 Crystal Compiler (incremental-compilation branch)

- **7 build targets**: native macOS, iOS device (`arm64-apple-ios`), iOS simulator (`arm64-apple-ios-simulator`), Android (`aarch64-linux-android`), WASM (`wasm32-wasi`), Linux x86\_64, Linux arm64.
- **`--shared` flag**: produces `.dylib` / `.so` for embedding Crystal in a Swift or Kotlin shell.
- **iOS linker integration**: `xcrun --sdk iphoneos clang` / `xcrun --sdk iphonesimulator clang`.
- **Android linker integration**: NDK clang `--target=aarch64-linux-android{api}`.
- **Compile-time flags available**: `:macos`, `:ios`, `:apple`, `:darwin`, `:android`, `:unix`, `:wasm32`.
- **Validated working**: the `samples/cross_platform/macos_app.cr` demo builds and runs a live AppKit window with `NSVisualEffectView` glass effects. ObjC bridge (`objc_bridge.c`) and collection bridge (`collection_bridge.c`) are functional and tested.

### 2.3 Amber V2 (v2.0.0-dev)

Web-focused HTTP framework at `/Users/crimsonknight/open_source_coding_projects/amber/`. Features ECR templating, pipeline middleware, and schema validation. It consumes `asset_pipeline` for JavaScript/CSS management. Integration with the native UI layer is a future concern; the initial focus is making `asset_pipeline` self-sufficient.

---

## Section 3: Validated Architecture

### 3.1 Layer Model

```
App Code (single source, shared Crystal)
  |
  v
UI::View (abstract class hierarchy - pointer-sized virtual dispatch)
  |
  v
UI::PlatformRenderer (compile-time selected via flag?())
  |
  +-- Web::Renderer
  |     -> Components::Elements (existing asset_pipeline system)
  |     -> Produces HTML strings, delegates to ReactiveComponent
  |
  +-- AppKit::Renderer       [compiled only when flag?(:macos)]
  |     -> NSView via LibObjC / objc_bridge.c
  |     -> NSStackView, NSTextField, NSButton, NSImageView, NSScrollView
  |
  +-- UIKit::Renderer        [compiled only when flag?(:ios)]
  |     -> UIView via LibObjC / objc_bridge.c (same bridge, different classes)
  |     -> UIStackView, UILabel, UIButton, UITextField, UIImageView
  |
  +-- Android::Renderer      [compiled only when flag?(:android)]
        -> Android View hierarchy via LibJNI / jni_bridge.c
        -> LinearLayout, TextView, MaterialButton, EditText, ImageView
```

Zero bytes of Android code appear in a macOS binary. Zero bytes of AppKit code appear in an Android binary. The flag?()-based conditional compilation is enforced at the Crystal compiler level.

---

### 3.2 Core Design Decisions (Revised from Validator Feedback)

**1. Abstract class hierarchy, NOT structs**

Crystal prohibits recursive struct types. A `VStack` containing `Array(View)` children cannot be a struct because that would embed an array of embedded structs — an infinite-size type. The solution, identical to what Crystal's own `ASTNode`, `Component`, and `HTMLElement` use, is an abstract class: every `UI::View` instance is heap-allocated, referenced through an 8-byte pointer. `Array(View)` stores an `Array(UI::View*)` which is `VirtualType` dispatch at 8 bytes/slot.

```crystal
abstract class UI::View
  abstract def accept(visitor : UI::PlatformVisitor)
  property parent : UI::View? = nil   # WeakRef in practice; see 3.5
  property id : String? = nil
  property accessibility_label : String? = nil
end
```

**2. Visitor pattern for platform dispatch**

Adding a new concrete view type requires one method per renderer. Adding a new platform requires one new renderer class. No `case view` switching on runtime type strings.

```crystal
abstract class UI::PlatformVisitor
  abstract def visit(v : UI::Label)
  abstract def visit(v : UI::Button)
  abstract def visit(v : UI::VStack)
  abstract def visit(v : UI::HStack)
  abstract def visit(v : UI::ZStack)
  abstract def visit(v : UI::Image)
  abstract def visit(v : UI::TextField)
  abstract def visit(v : UI::ScrollView)
  abstract def visit(v : UI::Spacer)
end
```

Each concrete `View` subclass implements `accept` as a one-liner: `visitor.visit(self)`.

**3. Compile-time platform selection via flag?()**

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

**4. 100% native layout delegation — no custom constraint engine**

There is no Flexbox implementation in Crystal. Each view type maps to a native layout container:

- `VStack` → `NSStackView(vertical)` / `UIStackView(.vertical)` / `LinearLayout(VERTICAL)` / `div[display:flex;flex-direction:column]`
- `HStack` → `NSStackView(horizontal)` / `UIStackView(.horizontal)` / `LinearLayout(HORIZONTAL)` / `div[display:flex;flex-direction:row]`
- `Spacer` → flexible space (NSStackView gravity spacing) / `Space(weight=1)` / `div[flex:1]`

Each platform's layout engine handles geometry. Crystal passes the view tree structure; the platform does the math.

**5. Adapter pattern for Component integration**

`UI::View` is platform-agnostic and knows nothing about WebSocket sessions or `ReactiveComponent`. The bridge is `UI::ViewAdapter < Components::Reactive::ReactiveComponent`. The adapter wraps a `UI::View` tree, renders it via `Web::Renderer` for the HTML output path, and routes state changes through `push_update` as before. This preserves 100% backward compatibility: existing `StatefulComponent` / `StatelessComponent` subclasses continue working without changes.

**6. NativeHandle memory management**

Wraps a `Void*` to a platform object and an explicit release strategy. `finalize` acts as a safety net; `teardown!` provides deterministic cleanup (required for views that hold open native resources).

**7. CallbackRegistry for GC-safe callbacks**

Crystal `Proc` closures passed as C function pointers to the ObjC runtime or JNI are at risk of being collected by BoehmGC if no Crystal reference remains. `UI::CallbackRegistry` holds a module-level `Hash(UInt64, Proc)` keyed by a stable numeric ID. The native side stores only the ID; the Crystal dispatch trampoline looks up the live `Proc` by ID and calls it.

**8. Full stdlib, NOT --prelude=empty**

Cross-compile `libgc` (BoehmGC) and `libpcre2` for iOS (`arm64-apple-ios`) and Android (`aarch64-linux-android31`). The only disabled flags are `-Dwithout_openssl` and `-Dwithout_xml` (network TLS and XML parsing are not needed for the UI layer). The full standard library gives: `String`, `Array`, `Hash`, `IO`, `Fiber`, `Channel`, `JSON`, `Log` — all available in native targets.

---

### 3.3 View Type Hierarchy (Concrete Crystal Code)

```crystal
# src/ui/view.cr
module UI
  record Color, r : Float64, g : Float64, b : Float64, a : Float64 = 1.0
  record Font,  family : String = "system", size : Float64 = 17.0,
                weight : Symbol = :regular, italic : Bool = false
  record EdgeInsets, top : Float64 = 0.0, right : Float64 = 0.0,
                     bottom : Float64 = 0.0, left : Float64 = 0.0

  abstract class View
    property id : String? = nil
    property accessibility_label : String? = nil
    property padding : EdgeInsets = EdgeInsets.new
    property background : Color? = nil
    # Parent stored as WeakRef to avoid retain cycles (see 3.5)
    property parent : View? = nil

    abstract def accept(visitor : PlatformVisitor)
  end

  class Label < View
    property text : String
    property font : Font
    property color : Color?
    property max_lines : Int32 = 0  # 0 = unlimited

    def initialize(@text : String, @font : Font = Font.new, @color : Color? = nil)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  class Button < View
    property label : String
    property on_tap : Proc(Nil)
    property enabled : Bool = true
    property style : Symbol = :default  # :default, :destructive, :plain

    def initialize(@label : String, &block : -> Nil)
      @on_tap = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  class VStack < View
    property children : Array(View)
    property spacing : Float64
    property alignment : Symbol  # :leading, :center, :trailing

    def initialize(@children : Array(View) = [] of View,
                   @spacing : Float64 = 8.0,
                   @alignment : Symbol = :center)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  class HStack < View
    property children : Array(View)
    property spacing : Float64
    property alignment : Symbol  # :top, :center, :bottom, :firstBaseline

    def initialize(@children : Array(View) = [] of View,
                   @spacing : Float64 = 8.0,
                   @alignment : Symbol = :center)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  class ZStack < View
    property children : Array(View)
    property alignment : Symbol  # :topLeading, :center, :bottomTrailing, etc.

    def initialize(@children : Array(View) = [] of View,
                   @alignment : Symbol = :center)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  class Image < View
    property source : String       # URL, asset name, or system symbol
    property content_mode : Symbol # :scaleToFill, :scaleAspectFit, :scaleAspectFill
    property alt : String = ""

    def initialize(@source : String, @content_mode : Symbol = :scaleAspectFit,
                   @alt : String = "")
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  class TextField < View
    property placeholder : String
    property value : String
    property on_change : Proc(String, Nil)
    property secure : Bool = false  # password field
    property keyboard : Symbol = :default

    def initialize(@placeholder : String, @value : String = "",
                   secure : Bool = false, &block : String -> Nil)
      @secure = secure
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  class ScrollView < View
    property child : View
    property axes : Symbol  # :vertical, :horizontal, :both

    def initialize(@child : View, @axes : Symbol = :vertical)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  class Spacer < View
    property min_length : Float64

    def initialize(@min_length : Float64 = 0.0)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
```

---

### 3.4 Platform Mapping Table

| UI::View    | Web (HTML + CSS)                                | macOS (AppKit)                        | iOS (UIKit)                              | Android                        |
|-------------|------------------------------------------------|---------------------------------------|------------------------------------------|--------------------------------|
| `Label`     | `<p>` or `<span>`, styled via CSS              | `NSTextField` (non-editable)          | `UILabel`                                | `TextView`                     |
| `Button`    | `<button>` with `data-action`                  | `NSButton` (bezel: rounded)           | `UIButton` (system)                      | `MaterialButton`               |
| `VStack`    | `<div style="display:flex;flex-direction:column">` | `NSStackView` (vertical)          | `UIStackView` (axis: .vertical)          | `LinearLayout` (VERTICAL)      |
| `HStack`    | `<div style="display:flex;flex-direction:row">` | `NSStackView` (horizontal)           | `UIStackView` (axis: .horizontal)        | `LinearLayout` (HORIZONTAL)    |
| `ZStack`    | `<div style="position:relative">` + abs children | `NSView` with manual frame layout  | `UIView` with Auto Layout anchors        | `FrameLayout`                  |
| `Image`     | `<img src alt>`                                | `NSImageView`                         | `UIImageView`                            | `ImageView`                    |
| `TextField` | `<input type=text>` or `type=password`         | `NSTextField` (editable)              | `UITextField`                            | `EditText`                     |
| `ScrollView`| `<div style="overflow:auto">`                  | `NSScrollView`                        | `UIScrollView`                           | `ScrollView` / `HorizontalScrollView` |
| `Spacer`    | `<div style="flex:1;min-height:{min}px">`      | Flexible space (NSStackView gravity)  | Flexible space via UILayoutGuide          | `Space` with `weight=1`        |

---

### 3.5 Memory Management Architecture

```crystal
# src/ui/native_handle.cr
module UI
  enum ReleaseStrategy
    ObjCRelease    # call -release on the ObjC object
    ObjCBorrowed   # borrowed reference; do NOT release
    JNIGlobalRef   # call DeleteGlobalRef via stored JNIEnv*
    Unowned        # caller manages lifetime; NativeHandle is a tag only
  end

  # Wraps a Void* to a platform-native object.
  # finalize is the GC safety net.
  # teardown! is the deterministic cleanup path; ALWAYS prefer it.
  class NativeHandle
    getter ptr : Void*
    getter strategy : ReleaseStrategy

    def initialize(@ptr : Void*, @strategy : ReleaseStrategy)
    end

    def finalize
      release_native
    end

    def teardown!
      return if @ptr.null?
      release_native
      @ptr = Pointer(Void).null  # poison to catch use-after-free
    end

    private def release_native
      case @strategy
      when .objc_release?
        {% if flag?(:darwin) %}
          LibCollectionBridge.objc_release_object(@ptr)
        {% end %}
      when .jni_global_ref?
        {% if flag?(:android) %}
          # JNIEnv must be stored alongside; see NativeView
        {% end %}
      when .objc_borrowed?, .unowned?
        # no-op
      end
    end
  end

  # ObjC factory helpers
  module ObjC
    def self.owned(ptr : Void*) : NativeHandle
      NativeHandle.new(ptr, ReleaseStrategy::ObjCRelease)
    end

    def self.borrowed(ptr : Void*) : NativeHandle
      NativeHandle.new(ptr, ReleaseStrategy::ObjCBorrowed)
    end
  end

  # JNI factory helper
  module JNI
    def self.global(env : Void*, local_ref : Void*) : NativeHandle
      global_ptr = LibJNICollectionBridge.jni_new_global_ref(env, local_ref)
      NativeHandle.new(global_ptr, ReleaseStrategy::JNIGlobalRef)
    end
  end

  # A rendered native view: wraps a NativeHandle and its children.
  # teardown! cascades through the child tree.
  class NativeView
    getter handle : NativeHandle
    getter children : Array(NativeView)
    # Weak back-reference to parent (avoids retain cycle)
    property parent : WeakRef(NativeView)? = nil

    def initialize(@handle : NativeHandle, @children = [] of NativeView)
    end

    def teardown!
      @children.each(&.teardown!)
      @children.clear
      @handle.teardown!
    end
  end
end
```

**WeakRef for parent back-references:** Crystal's `WeakRef(T)` is used for `parent` links in both `UI::View` and `UI::NativeView` to prevent reference cycles that would prevent GC collection of unmounted view trees.

---

### 3.6 Event and Callback Routing

**ObjC (macOS / iOS)**

The ObjC target-action mechanism requires a registered class method as the IMP (implementation pointer). A single dynamically-created class `CrystalActionDispatcher` handles all button/gesture callbacks. Each action is registered with a unique SEL that encodes a `UInt64` callback ID. On dispatch, the IMP looks up the ID in `UI::CallbackRegistry` and calls the stored `Proc`.

```crystal
module UI
  module CallbackRegistry
    @@callbacks = Hash(UInt64, Proc(Nil)).new
    @@next_id = Atomic(UInt64).new(1_u64)

    def self.register(block : Proc(Nil)) : UInt64
      id = @@next_id.add(1)
      @@callbacks[id] = block
      id
    end

    def self.call(id : UInt64) : Nil
      @@callbacks[id]?.try(&.call)
    end

    def self.unregister(id : UInt64) : Nil
      @@callbacks.delete(id)
    end
  end
end
```

The ObjC dispatcher IMP is:

```c
// In objc_bridge.c — called by ObjC runtime for any button tap
void crystal_action_dispatcher(id self, SEL sel, id sender) {
    // Decode callback ID from selector name: "crystalAction_<id>:"
    const char* sel_name = sel_getName(sel);
    uint64_t callback_id = strtoull(sel_name + strlen("crystalAction_"), NULL, 10);
    crystal_ui_callback_dispatch(callback_id);  // calls back into Crystal
}
```

Crystal exports `crystal_ui_callback_dispatch(id : UInt64)` as a C-visible function via `@[Exported]`.

**JNI (Android)**

A Java `CrystalCallbackBridge` class has a single `static native void dispatch(long callbackId)` method. The JNI implementation calls the same `crystal_ui_callback_dispatch` entry point.

**Web**

No change to the existing system. `data-action` attributes on rendered HTML elements route through `ReactiveHandler` → `ActionRegistry` → `ReactiveComponent#handle_action`. The `Web::Renderer` emits these attributes when rendering `Button` views.

---

### 3.7 Collection Bridge

The `collection_bridge.c` / `collection_bridge.cr` files are already complete and tested (see `samples/cross_platform/`). Key APIs used by the renderers:

**ObjC side:**

| Operation | C function | Crystal wrapper |
|-----------|-----------|-----------------|
| Batch add children to NSStackView | `nsstack_set_views(stack, views**, count, gravity)` | `ObjC.stack_set_views(ptr, child_ptrs)` |
| Batch add subviews to any NSView | `objc_add_subviews_batch(parent, children**, count)` | `ObjC.add_subviews_batch(ptr, ptrs)` |
| NSArray from pointer array | `nsarray_create(objects**, count)` | `ObjC::NSArray.from_pointers(arr)` |
| NSMutableArray | `nsmutablearray_create(capacity)` | `ObjC::NSMutableArray.new(capacity)` |
| NSDictionary (view props) | `nsdictionary_create(keys**, vals**, count)` | `ObjC::NSDictionary.from_string_hash(h)` |
| NSString from Crystal String | `nsstring_create_with_bytes(bytes, len)` | `ObjC::NSString.from_string(str)` |
| Autorelease pool scope | `autorelease_pool_push/pop` | `ObjC.autoreleasepool { ... }` |
| Retain / Release | `objc_retain_object` / `objc_release_object` | `ObjC.retain(ptr)` / `ObjC.release(ptr)` |

**JNI side:**

| Operation | C function | Crystal wrapper |
|-----------|-----------|-----------------|
| Batch add views to ViewGroup | `jni_viewgroup_add_views_batch(env, vg, children**, count)` | `JNI.viewgroup_add_views(env, ptr, ptrs)` |
| ArrayList creation | `jni_arraylist_create(env, objects**, count)` | `JNI::ArrayList.create(env, ptrs)` |
| jobjectArray | `jni_object_array_create(env, class_name, objects**, count)` | `JNI::ObjectArray.create(env, cls, ptrs)` |
| jstring from Crystal String | `jni_string_create_with_bytes(env, bytes, len)` | `JNI::JString.from_string(env, str)` |
| Global ref promotion | `jni_new_global_ref(env, local)` | `JNI::JString#to_global` |
| Local frame scope | `jni_push_local_frame` / `jni_pop_local_frame` | `JNI.local_frame(env, 64) { ... }` |

Every render pass on macOS/iOS is bracketed with `ObjC.autoreleasepool { ... }`. Every batch Android operation is bracketed with `JNI.local_frame(env, capacity) { ... }`.

---

### 3.8 Component Integration (UI::View and Components::Component)

`UI::View` and the existing `Components::Component` hierarchy are kept strictly separate. The integration point is `UI::ViewAdapter`:

```crystal
# src/ui/view_adapter.cr
require "components/reactive/reactive_component"
require "ui/view"
require "ui/renderers/web_renderer"

module UI
  # Bridges a UI::View tree into the existing ReactiveComponent system.
  # The web renderer is used for HTML output; native renderers bypass this class.
  class ViewAdapter < Components::Reactive::ReactiveComponent
    def initialize(@root : UI::View)
      super()
    end

    def render_content : String
      renderer = UI::Web::Renderer.new
      @root.accept(renderer)
      renderer.output
    end

    # Native targets: render the view tree directly to the platform.
    # Called by the platform entry point, not by ReactiveHandler.
    {% if flag?(:macos) %}
      def render_native(parent_ptr : Void*) : UI::NativeView
        renderer = UI::AppKit::Renderer.new(parent_ptr)
        @root.accept(renderer)
        renderer.result
      end
    {% elsif flag?(:ios) %}
      def render_native(parent_ptr : Void*) : UI::NativeView
        renderer = UI::UIKit::Renderer.new(parent_ptr)
        @root.accept(renderer)
        renderer.result
      end
    {% elsif flag?(:android) %}
      def render_native(env : Void*, parent_ptr : Void*) : UI::NativeView
        renderer = UI::Android::Renderer.new(env, parent_ptr)
        @root.accept(renderer)
        renderer.result
      end
    {% end %}
  end
end
```

**State change propagation:**

- **Web path:** State changes call `ReactiveComponent#push_update` → `ReactiveHandler#broadcast_update` → WebSocket diff to client. No changes to the existing system.
- **Native path:** State changes trigger a re-render of the affected `UI::View` subtree. The renderer diffs the new `NativeView` tree against the current one and applies only the changed properties to native objects via the ObjC/JNI bridge. A full re-render of unchanged subtrees is avoided by storing the previous render result.

---

### 3.9 Full Stdlib Cross-Compilation

**iOS (arm64-apple-ios device, arm64-apple-ios-simulator)**

- libc bindings: 36 files already present in Crystal (`src/lib_c/aarch64-darwin/`).
- Event loop: kqueue (EVFILT\_USER, EVFILT\_TIMER) — already used by macOS target.
- Fiber context switching: `aarch64` context (`makecontext`/`swapcontext` via `libunwind`) — works on iOS.
- Cross-compile BoehmGC: `./configure --host=aarch64-apple-ios --disable-threads` (or with pthreads for multi-threaded GC).
- Cross-compile libpcre2: `./configure --host=aarch64-apple-ios`.
- **Caveats:** `Process.fork` crashes under iOS App Sandbox (expected; do not call). Signal handlers (`SIGSEGV`, `SIGBUS`) may conflict with iOS crash reporting — guard with `{% unless flag?(:ios) %}` in signal-sensitive code.
- Build command (device):
  ```bash
  crystal build src/my_app.cr \
    --target aarch64-apple-ios \
    --cross-compile \
    --mcpu apple-a17 \
    -Dwithout_openssl -Dwithout_xml \
    -o my_app.o
  xcrun --sdk iphoneos clang my_app.o \
    /path/to/ios-libs/libgc.a \
    /path/to/ios-libs/libpcre2-8.a \
    -framework UIKit -framework Foundation \
    -o MyApp.framework/MyApp
  ```
- Build command (simulator):
  ```bash
  crystal build src/my_app.cr \
    --target aarch64-apple-ios-simulator \
    --cross-compile \
    -Dwithout_openssl -Dwithout_xml \
    -o my_app_sim.o
  xcrun --sdk iphonesimulator clang my_app_sim.o \
    /path/to/iossim-libs/libgc.a \
    /path/to/iossim-libs/libpcre2-8.a \
    -framework UIKit -framework Foundation \
    -o MyApp.framework/MyApp
  ```

**Android (aarch64-linux-android, API 31+)**

- libc bindings: 44 Bionic libc files already present in Crystal (`src/lib_c/aarch64-linux-android/`).
- Event loop: epoll — already used by the Linux target; Bionic exposes the same syscall interface.
- Thread-local storage: Android Bionic does not support `__thread` for Crystal's fiber TLS on older APIs; use `pthread_key_create` / `pthread_getspecific` (Crystal already has this fallback for `-Dpreview_mt`).
- Cross-compile BoehmGC: use Android NDK toolchain: `$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android31-clang`.
- Cross-compile libpcre2: same NDK clang.
- Build command:
  ```bash
  crystal build src/my_app.cr \
    --target aarch64-linux-android \
    --cross-compile \
    --shared \
    -Dwithout_openssl -Dwithout_xml \
    -o libmyapp.o
  $NDK_CLANG --target=aarch64-linux-android31 \
    -shared -fPIC \
    libmyapp.o \
    /path/to/android-libs/libgc.a \
    /path/to/android-libs/libpcre2-8.a \
    -o libmyapp.so
  ```

**Required cross-compiled libraries (all targets):**

| Library | Purpose | Notes |
|---------|---------|-------|
| `libgc.a` | BoehmGC — Crystal's GC | Must match target ABI exactly |
| `libpcre2-8.a` | Regex — `String#match` | Disable JIT for iOS (no `mmap(PROT_EXEC)`) |

Only `-Dwithout_openssl` and `-Dwithout_xml` are required. All other stdlib modules (`String`, `Array`, `Hash`, `Fiber`, `Channel`, `JSON`, `Log`, `Time`) are available natively.

---

## Section 4: Implementation Phases (Ralph Loop Milestones)

The implementation is organized into 8 milestones designed for parallel execution via Ralph Loop. Each milestone has clear inputs, outputs, and success criteria.

### Milestone 1: Core View Types + Infrastructure

**Location:** `asset_pipeline/src/ui/`

**Deliverables:**
- `src/ui/view.cr` — `abstract class UI::View` + value types (`Color`, `Font`, `EdgeInsets`)
- `src/ui/views/label.cr` — `UI::Label`
- `src/ui/views/button.cr` — `UI::Button` (with `on_tap : Proc(Nil)`)
- `src/ui/views/vstack.cr` — `UI::VStack` (children, spacing, alignment)
- `src/ui/views/hstack.cr` — `UI::HStack`
- `src/ui/views/zstack.cr` — `UI::ZStack`
- `src/ui/views/image.cr` — `UI::Image`
- `src/ui/views/text_field.cr` — `UI::TextField`
- `src/ui/views/scroll_view.cr` — `UI::ScrollView`
- `src/ui/views/spacer.cr` — `UI::Spacer`
- `src/ui/platform_visitor.cr` — `abstract class UI::PlatformVisitor` with abstract `visit` methods
- `spec/ui/views_spec.cr` — Spec coverage for all view types

**Success criteria:** All view types instantiate, accept visitors, and compose into trees. `VStack.new(children: [Label.new("Hi"), Button.new("Click") { }])` compiles and type-checks.

### Milestone 2: Web::Renderer (Bridges to Existing Elements)

**Location:** `asset_pipeline/src/ui/renderers/`

**Deliverables:**
- `src/ui/renderers/web_renderer.cr` — `UI::Web::Renderer < UI::PlatformVisitor`
- Visit methods delegate to existing `Components::Elements`:
  - `Label` → `Elements::Span` with font/color styles
  - `Button` → `Elements::Button` with `data-action` attribute
  - `VStack` → `Elements::Div` + `display:flex;flex-direction:column;gap:Xpx`
  - `HStack` → `Elements::Div` + `display:flex;flex-direction:row;gap:Xpx`
  - `ZStack` → `Elements::Div` + `position:relative` + absolute children
  - `Image` → `Elements::Img` with `object-fit` CSS
  - `TextField` → `Elements::Input.text` or `Elements::Input.password`
  - `ScrollView` → `Elements::Div` + `overflow:auto`
  - `Spacer` → `Elements::Div` + `flex:1 1 0%`
- Layout CSS base stylesheet (`ui-vstack`, `ui-hstack`, `ui-spacer`, etc.)
- `spec/ui/web_renderer_spec.cr` — output matches expected HTML

**Success criteria:** `Web::Renderer.new.render(my_view_tree)` produces valid HTML using existing `Components::Elements` classes. Zero modifications to existing element classes.

### Milestone 3: ViewAdapter + Component Integration

**Location:** `asset_pipeline/src/ui/`

**Deliverables:**
- `src/ui/view_adapter.cr` — `UI::ViewAdapter < Components::Reactive::ReactiveComponent`
- `src/ui/state.cr` — `UI::State(T)` typed reactive state with change listeners
- ViewAdapter wraps a `UI::View` tree, renders via `Web::Renderer` for `render_content`
- State changes trigger `push_update` for web reactive updates
- Platform alias: `{% if flag?(:macos) %} alias PlatformRenderer = ... {% end %}`
- `spec/ui/view_adapter_spec.cr`
- `spec/ui/state_spec.cr`

**Success criteria:** A `ViewAdapter` wrapping a counter app view tree renders to HTML, pushes updates via WebSocket on state change, and is fully compatible with the existing `ReactiveHandler` middleware.

### Milestone 4: NativeHandle + Memory Management

**Location:** `asset_pipeline/src/ui/native/`

**Deliverables:**
- `src/ui/native/native_handle.cr` — `NativeHandle` class with `ReleaseStrategy` enum
- `src/ui/native/objc_handle.cr` — `ObjC.owned()`, `ObjC.borrowed()`, `ObjC.retain()`
- `src/ui/native/jni_handle.cr` — `JNI.global()`, `JNI.wrap_global()`
- `src/ui/native/native_view.cr` — `NativeView` with children, `teardown!` cascade
- `src/ui/native/callback_registry.cr` — `CallbackRegistry` module (register/unregister/call)
- `src/ui/native/handle_tracker.cr` — Debug leak tracker (`-Dui_debug`)
- `spec/ui/native/native_handle_spec.cr`
- `spec/ui/native/callback_registry_spec.cr`

**Success criteria:** `NativeHandle` correctly tracks ownership. `teardown!` cascades through children. `CallbackRegistry` prevents Proc GC. Debug tracker reports unreleased handles.

### Milestone 5: ObjC Bridge Fix + AppKit Renderer

**Location:** `crystal/samples/cross_platform/` + `asset_pipeline/src/ui/renderers/`

**Deliverables:**
- Fixed `objc_bridge.c` with 42 typed wrappers (all ARM64 multi-double bugs fixed)
- `src/ui/renderers/appkit_renderer.cr` — `UI::AppKit::Renderer < UI::PlatformVisitor`
  - `Label` → `NSTextField` (non-editable) via ObjC bridge
  - `Button` → `NSButton` with `CallbackRegistry` + `CrystalActionDispatcher`
  - `VStack` → `NSStackView(vertical)` with spacing + alignment
  - `HStack` → `NSStackView(horizontal)`
  - `Image` → `NSImageView`
  - `TextField` → `NSTextField` (editable) with change callback
  - `ScrollView` → `NSScrollView`
  - `Spacer` → flexible space in NSStackView
- NSColor convenience helpers (rgba, white+alpha — all multi-double bugs fixed)
- NSFont convenience helpers (system, bold, monospaced)
- `CrystalActionDispatcher` ObjC class + callback dispatch trampoline
- Working demo app using the new renderer

**Success criteria:** macOS demo app launches with a window, renders all 9 view types natively via AppKit, button clicks fire Crystal callbacks, no ARM64 register corruption.

### Milestone 6: Collection Bridge + Batch Operations

**Location:** `crystal/samples/cross_platform/` + `asset_pipeline/src/ui/native/`

**Deliverables:**
- `collection_bridge.c` — NSArray/NSMutableArray/NSDictionary/NSString batch ops (ObjC)
- `collection_bridge.c` — ArrayList/jobjectArray/jstring batch ops (JNI, #ifdef __ANDROID__)
- `src/ui/native/objc_collections.cr` — Crystal wrappers for ObjC collections
- `src/ui/native/jni_collections.cr` — Crystal wrappers for JNI collections
- Autorelease pool scoping (`ObjC.autoreleasepool { }`)
- JNI local frame scoping (`JNI.local_frame(env, cap) { }`)
- Batch `stack_set_views` and `viewgroup_add_views` for renderer performance

**Success criteria:** Batch adding 20 children to NSStackView uses 1 bridge crossing. Autorelease pools prevent memory accumulation across render passes.

### Milestone 7: Cross-Compilation Toolchain

**Location:** Scripts + documentation

**Deliverables:**
- `scripts/cross_compile_deps.sh` — Automates building libgc + libpcre2 for:
  - iOS device (aarch64-apple-ios17.0)
  - iOS simulator (aarch64-apple-ios17.0-simulator)
  - Android (aarch64-linux-android31)
- `scripts/build_ios.sh` — Full iOS build (crystal --cross-compile + xcrun link)
- `scripts/build_android.sh` — Full Android build (crystal --cross-compile + NDK link)
- `crystal_init` function for shared library initialization
- Verification: all 3 targets produce linkable .dylib/.so files
- Documentation in `CROSS_COMPILE.md`

**Success criteria:** Running `scripts/build_ios.sh` produces a `.dylib` that can be loaded in an Xcode project. `scripts/build_android.sh` produces a `.so` that can be loaded via `System.loadLibrary`.

### Milestone 8: Claude Skills + Sub-Agent Documentation

**Location:** `asset_pipeline/.claude/`

**Deliverables:**
- `.claude/skills/cross-platform-components/SKILL.md` — Overview, when to use, quick reference
- `.claude/skills/component-api/SKILL.md` — Full API reference for all UI::View types
- `.claude/skills/platform-renderers/SKILL.md` — How each renderer works (Web, AppKit, UIKit, Android)
- `.claude/skills/glass-effects/SKILL.md` — Apple glass effect integration guide (NSVisualEffectView, UIVisualEffectView)
- `.claude/agents/component-reviewer/agent.md` — Reviews cross-platform component code for compatibility
- `.claude/agents/platform-tester/agent.md` — Verifies builds across all targets

**Success criteria:** Skills load correctly when referenced. Sub-agents can be invoked for code review and build verification.

---

## Section 5: Dependency Graph

```
Milestone 1 (Core Types)
    |
    +---> Milestone 2 (Web::Renderer)
    |         |
    |         +---> Milestone 3 (ViewAdapter + Integration)
    |
    +---> Milestone 4 (NativeHandle + Memory)
    |         |
    |         +---> Milestone 5 (ObjC Bridge + AppKit Renderer)
    |         |         |
    |         |         +---> Milestone 6 (Collection Bridge + Batch)
    |         |
    |         +---> Milestone 7 (Cross-Compilation Toolchain)
    |
    +---> Milestone 8 (Documentation) [can start anytime]
```

**Parallelizable pairs:**
- Milestones 2 + 4 (Web renderer + Native handle infrastructure)
- Milestones 3 + 5 (ViewAdapter + AppKit renderer, after their dependencies)
- Milestone 8 (Documentation) runs in parallel with everything

---

## Section 6: Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| ObjC bridge multi-double bugs (ARM64) | Critical | **Fixed** — 42 typed wrappers with explicit register allocation |
| Recursive struct compilation error | Critical | **Fixed** — abstract class hierarchy eliminates the issue |
| Crystal Proc GC'd while native holds pointer | Critical | `CallbackRegistry` holds strong refs; `unregister` on teardown |
| ObjC retain cycle (native ↔ Crystal) | High | `WeakRef` for parent back-refs; `NativeView.teardown!` breaks all refs |
| iOS Process.fork crash | Medium | Don't call `Process` module; use platform-native process APIs |
| JNI local ref table exhaustion | Medium | `PushLocalFrame/PopLocalFrame` in batch operations |
| libgc cross-compilation fails | Medium | Detailed build scripts with tested configure flags |
| State diffing correctness | Medium | Phase 5 (future) — start without diffing, full re-render |
| Android TLS underalignment | Low | Already handled in Crystal (pthread TSS fallback) |

---

## Section 7: Success Criteria (End-to-End)

1. A single `app.cr` source file compiles to macOS native (with interactive AppKit GUI), web (HTML via asset_pipeline), and cross-compiles for iOS and Android
2. The macOS app shows a window with all 9 view types rendered natively via AppKit
3. Button clicks fire Crystal callbacks via `CallbackRegistry` → `CrystalActionDispatcher`
4. The web build produces HTML that uses existing `Components::Elements` classes
5. The iOS build produces a linkable `.dylib` with full Crystal stdlib
6. The Android build produces a linkable `.so` with full Crystal stdlib
7. All native resources are deterministically released via `NativeView.teardown!`
8. `CallbackRegistry` prevents GC of active callbacks; no use-after-free crashes
9. All documentation exists as Claude skills in `.claude/skills/`
10. Reviewer and tester sub-agents are functional in `.claude/agents/`
