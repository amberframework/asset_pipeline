---
name: graphics-rendering
description: |
  Survey of graphics and rendering APIs for cross-platform 2D/3D graphics in Crystal.
  Covers WebGPU/wgpu-native, Metal 4, Vulkan/MoltenVK, Skia, Filament, and OpenGL ES.
  Includes FFI feasibility assessment. STUB — implementation deferred, research preserved.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
version: "0.1.0"
---

# Graphics & Rendering APIs

## STATUS: STUB — Implementation Deferred

This document preserves research findings for future work. No graphics rendering code exists in the asset_pipeline today. Implementation is deferred pending prioritization.

The asset_pipeline currently renders UI using native platform components (NSView, UIView, Android Views, HTML elements). These native components handle 2D presentation (layout, text, images, basic shapes) perfectly well. Custom 2D drawing and 3D rendering require a separate graphics layer that does not yet exist.

When graphics rendering is eventually implemented, this document is the starting point for architectural decisions.

---

## 1. Planned Capabilities (Future)

The asset_pipeline will eventually include:

- **2D custom drawing** — A `UI::Canvas` view type that allows application code to draw paths, shapes, text, and images using a programmatic API. This is the "draw it yourself" escape hatch beyond the 9 native view types.
- **GPU-accelerated effects** — Blur, gradients, shadows, image filters applied via GPU rather than CPU compositing.
- **3D scene rendering** — A `UI::Scene3D` view type embedding a 3D viewport. Physically-based rendering (PBR), lighting, mesh loading.
- **Cross-platform shader support** — Write shaders once, compile to platform-appropriate format (MSL, SPIR-V, GLSL ES, WGSL).

None of the above exist today. The view type stubs (if added) should produce empty/placeholder output in all current renderers.

---

## 2. GPU API Landscape

### 2a. WebGPU / wgpu-native (RECOMMENDED PRIMARY BACKEND)

**What it is:** A modern, unified GPU programming API. `webgpu.h` is a C header defining the API surface; `wgpu-native` is a production implementation of that header in Rust, exposing a shared library that Crystal can link against via `@[Link]`.

**Lineage:** The WebGPU specification was designed by W3C with input from Apple, Google, and Mozilla. `wgpu-native` (by the gfx-rs team) and Dawn (by Google) are both conforming implementations sharing a converging `webgpu.h` header. Firefox uses `wgpu-native`; Chrome uses Dawn.

**Backend mapping on each platform:**

| Crystal target | wgpu-native backend |
|----------------|---------------------|
| macOS (`flag?(:macos)`) | Metal |
| iOS (`flag?(:ios)`) | Metal |
| Android (`flag?(:android)`) | Vulkan |
| Linux | Vulkan |
| Windows | DirectX 12 or Vulkan |
| Web (WASM) | Native WebGPU API in the browser |

**FFI feasibility: Tier 1 — pure C header, direct `lib` binding from Crystal.**

The header (`webgpu.h`) uses only C types: opaque pointers, enums, structs of primitives, and function pointer callbacks. No C++ templates, no exceptions, no ObjC. Crystal's `lib` declarations can cover the entire surface.

**Why recommended:** Single API for all platforms. C header. Actively maintained. Production-proven (Firefox). Powers cross-platform Rust graphics (wgpu crate). The `webgpu.h` standard is converging across implementations, so bindings written today will remain valid as the ecosystem matures.

**Status as of 2025:** Production-ready. `webgpu.h` is stable. wgpu-native releases are tagged on GitHub. The two major implementations (wgpu-native and Dawn) are converging toward the shared header format, meaning Crystal bindings written to `webgpu.h` will work against either.

**Repository:** https://github.com/gfx-rs/wgpu-native

---

### 2b. Metal 4 (Apple Platforms Only)

**What it is:** Apple's GPU API, announced at WWDC 2025. Metal 4 is a significant redesign — not just an incremental update. It brings Apple's GPU API to rough feature parity with DirectX 12 and Vulkan in terms of explicit control.

**Platform requirements:** macOS 26 (Tahoe) or later, iOS 26 or later, Apple M1 / A14 Bionic or later. Metal 4 drops Intel Mac support entirely. Metal 3 and earlier remain available on older hardware.

**Key features introduced in Metal 4:**
- Unified command encoder (replaces the separate render/compute/blit encoders of Metal 3)
- First-class tensor support for machine learning inference within shaders
- Native frame interpolation via MetalFX (generates intermediate frames cheaply)
- Path-traced rendering support
- Explicit memory management (closer to Vulkan's memory model)
- Improved debugging and GPU capture tooling

**FFI feasibility: Tier 2 — ObjC API, requires C shim wrappers.**

Metal's API is expressed in Objective-C (and Swift, which is not usable from Crystal FFI). Crystal cannot call ObjC methods directly without going through the ObjC runtime C API (`objc_msgSend`) as the asset_pipeline's existing AppKit bridge already does. For Metal, C shim wrappers in a `.c` file would be needed — the same pattern as `objc_bridge.c` in the existing renderer.

**When to use Metal 4 directly:** Only for Apple-specific optimization or features not available through wgpu-native's Metal backend. The wgpu-native library already uses Metal on Apple platforms; reaching for Metal 4 APIs directly would be for cases where wgpu-native's abstraction is too high-level (e.g., tensor operations, frame interpolation).

**Note:** Metal 4 and Metal 3 coexist. Metal 4 is not a replacement that removes older APIs. Code targeting Metal 4 must gate on OS version at runtime (`#available` in ObjC/Swift, or a version-check C wrapper for Crystal).

---

### 2c. Vulkan / MoltenVK

**What it is:** The Khronos Group's cross-platform, low-level GPU API. The `vulkan.h` C header defines the full API. Android supports Vulkan natively through the NDK. Apple platforms support Vulkan through MoltenVK (a translation layer that implements Vulkan on top of Metal).

**MoltenVK 1.4 (released August 2025):** Implements Vulkan 1.4 on macOS, iOS, tvOS, and visionOS. It is layered atop Metal — MoltenVK translates Vulkan calls to Metal calls at runtime. MoltenVK is "non-conformant" (it passes most but not all Vulkan conformance tests) due to Metal API limitations, but it is stable and widely used in shipping games.

**Platform support:**

| Platform | Vulkan availability |
|----------|---------------------|
| Android | Native (NDK), Vulkan 1.3+ on modern devices |
| macOS | Via MoltenVK (Vulkan 1.4, non-conformant) |
| iOS | Via MoltenVK (Vulkan 1.4, non-conformant) |
| Linux | Native (Mesa, NVIDIA, AMD drivers) |
| Windows | Native (NVIDIA, AMD, Intel drivers) |

**FFI feasibility: Tier 1 — pure C API, direct `lib` binding from Crystal.**

`vulkan.h` is a C header with opaque handles, enums, structs, and function pointers. The same Crystal `lib` approach as wgpu-native applies. Vulkan's API surface is significantly larger than WebGPU's and requires more boilerplate per operation (explicit pipeline state objects, descriptor sets, render passes, memory allocation). This is not a barrier to FFI, but it means more Crystal binding code to write.

**Relationship to wgpu-native:** wgpu-native uses Vulkan as its backend on Android and Linux. Writing directly to Vulkan instead of wgpu-native bypasses the abstraction but gains lower-level control. For most use cases, wgpu-native is the better choice. Vulkan directly would be appropriate only if wgpu-native's overhead were measurably problematic (unlikely for UI rendering workloads).

---

### 2d. Skia C API (2D Drawing)

**What it is:** Google's 2D graphics library. Skia underlies Chrome, Android's 2D rendering, Flutter's custom painting, and many other products. Skia has a stable C API (`sk_*.h` headers) that wraps its C++ internals.

**C API types:** `sk_canvas_t`, `sk_paint_t`, `sk_path_t`, `sk_surface_t`, `sk_image_t`, `sk_typeface_t`, `sk_font_t`. These are opaque `void*` wrappers with C function interfaces.

**Platforms:** macOS, iOS, Android, Linux, Windows, Web (via Skia compiled to WASM).

**FFI feasibility: Tier 1 — C API available, direct `lib` binding from Crystal.**

The C API is more stable than Skia's C++ API (which changes frequently). C bindings for Skia exist for other languages (Go via `cskia`, .NET via SkiaSharp) and serve as a reference. The C API does not expose the full Skia feature set — some GPU-accelerated paths require using the C++ API through thin C wrappers.

**Best for:**
- 2D custom drawing (paths, shapes, arcs, curves)
- Text rendering with fine-grained control (custom typefaces, glyph manipulation)
- Image manipulation (filters, compositing, pixel operations)
- A `UI::Canvas` implementation that needs CPU-side 2D drawing without a GPU pipeline

**Relationship to Flutter:** Skia is exactly what Flutter uses for its custom painting (`Canvas` in Flutter's painting API). If we eventually add `UI::Canvas`, Skia is the most direct path to the same capability.

**Note on building Skia:** Skia is not available as a pre-built system library on macOS or iOS (unlike on Android, where it is part of the OS). It must be compiled from source and bundled or linked statically. The build system uses GN (not CMake or Make), which adds complexity. Pre-built Skia binaries are available from the SkiaSharp project as a reference.

---

### 2e. Filament (3D Engine)

**What it is:** Google's open-source, real-time physically based rendering (PBR) 3D engine. Filament is designed for mobile and desktop, with a focus on correct PBR materials, global illumination, and efficient rendering.

**Platforms:** Android, iOS, macOS, Windows, Linux, Web (WebGL2 / WebAssembly).

**Backend rendering APIs:**
- Android: Vulkan (preferred) or OpenGL ES
- iOS / macOS: Metal
- Web: WebGL2

**FFI feasibility: Tier 2 — C++ API, requires a C wrapper layer.**

Filament's public API is C++. It uses C++ classes with virtual dispatch, templates, and RAII. Crystal cannot call C++ directly. A C wrapper library (a thin `.c` or `.cpp` shim exposing C-compatible `filament_*` functions) would be needed. This is more work than Tier 1 APIs but is a well-understood pattern (Filament's own Android bindings use a similar JNI-bridging approach).

**Best for:** 3D scene rendering with correct lighting, PBR materials, shadows. Filament is far more than a GL wrapper — it includes a material system, a GPU-resident scene graph, and optimized shaders for mobile GPUs. If `UI::Scene3D` is ever implemented, Filament is the best candidate backend.

**Maintenance:** Actively maintained by Google (used in production in Android apps and Google Earth). Regular releases on GitHub.

---

### 2f. OpenGL ES

**What it is:** The embedded/mobile subset of OpenGL. OpenGL ES 2.0 and 3.x are widely supported on older devices.

**Platform status in 2025:**

| Platform | Status |
|----------|--------|
| Apple platforms (iOS, macOS) | Deprecated since iOS 12 / macOS 10.14 (2018). Still available but not recommended. No new features. May be removed in future OS versions. |
| Android | Available but Vulkan is preferred for new work. OpenGL ES 3.2 is standard. |
| Linux | Available via Mesa. Not deprecated. |
| Windows | Available. Not deprecated. |

**FFI feasibility: Tier 1 — pure C API (`gl.h`, `gles2.h`, `gles3.h`), direct `lib` binding.**

**Recommendation: Do not use for new code.** Apple has deprecated OpenGL ES on all Apple platforms and may remove it. On Android, Vulkan supersedes it. For any new graphics work, use wgpu-native (which supports OpenGL ES as a fallback backend on platforms where Vulkan is unavailable).

The only scenario where OpenGL ES makes sense is supporting very old Android devices (pre-API 24) that lack Vulkan. wgpu-native handles this automatically by falling back to OpenGL ES.

---

### 2g. Core Graphics (Apple 2D, Bonus Entry)

**What it is:** Apple's 2D drawing framework. Available on macOS and iOS as a C API (`CoreGraphics/CoreGraphics.h`). Powers all 2D drawing in AppKit and UIKit.

**FFI feasibility: Tier 1 — pure C API (CGContext, CGPath, CGColor, etc.).**

Core Graphics is already partially used via the ObjC bridge (CGRect, CGPoint, CGSize are used in the AppKit renderer for view geometry). Expanding to drawing operations (CGContextAddPath, CGContextFillPath, etc.) would be straightforward.

**When relevant:** If `UI::Canvas` is implemented and the web/Android renderers use Skia or wgpu-native, the Apple renderer could use Core Graphics for 2D drawing rather than bundling Skia, since Core Graphics is already present on every Apple device.

---

### 2h. AGSL (Android Graphics Shading Language, Bonus Entry)

**What it is:** Android's runtime shader language, available on Android 13 (API 33) and later. Allows attaching custom GPU shaders to Android `View` backgrounds and effects using the `RuntimeShader` API.

**FFI feasibility: Tier 2 — JNI API.** Accessible via the existing JNI bridge pattern used in the Android renderer.

**When relevant:** Custom visual effects on Android that go beyond what `MaterialSurface` or view backgrounds provide. Not a general-purpose GPU API — specifically for Android view-level shader effects.

---

## 3. FFI Feasibility Matrix

| API | FFI Tier | Header | Crystal Difficulty | Platforms | Recommended Use |
|-----|----------|--------|--------------------|-----------|----------------|
| WebGPU / wgpu-native | 1 | `webgpu.h` | Low | All (Metal/Vulkan/D3D12/WebGPU backends) | Primary GPU backend |
| Vulkan | 1 | `vulkan.h` | Medium (large, verbose API) | Android, macOS/iOS via MoltenVK, Linux, Windows | Alternative to wgpu-native; lower-level |
| Skia C API | 1 | `sk_*.h` | Low | All | 2D drawing / UI::Canvas |
| Core Graphics | 1 | `CoreGraphics.h` (C) | Low | Apple only | 2D drawing on Apple (no bundling needed) |
| Metal 4 | 2 | ObjC | Medium (needs C shim, same as AppKit bridge) | Apple only (macOS 26 / iOS 26+, M1/A14+) | Apple-specific optimization or tensor ops |
| Filament | 2 | C++ | High (needs C wrapper library) | All | 3D rendering / UI::Scene3D |
| OpenGL ES | 1 | `gles2.h` / `gles3.h` | Low | Android, Linux (deprecated Apple) | Avoid; legacy only |
| AGSL | 2 | JNI | Medium | Android 13+ (API 33+) | Custom shaders on Android views |

**Tier 1:** Pure C header, standard Crystal `lib` declarations, direct linking. Same pattern as the existing ObjC bridge C helpers.

**Tier 2:** Requires additional work — either C shim wrappers (Metal 4, Filament) or JNI bridge (AGSL). Still feasible, just more code.

---

## 4. Recommended Architecture (When Implemented)

### For GPU-accelerated rendering (2D + 3D):

```
UI::Canvas (Crystal view type — stub today)
  |
  v
PlatformVisitor (compile-time selected)
  |
  +-- Web::Renderer       -> HTML5 Canvas API  (via <canvas> element)
  +-- AppKit::Renderer    -> wgpu-native (Metal backend) or Core Graphics
  +-- UIKit::Renderer     -> wgpu-native (Metal backend) or Core Graphics
  +-- Android::Renderer   -> wgpu-native (Vulkan backend)

UI::Scene3D (Crystal view type — stub today)
  |
  v
PlatformVisitor
  |
  +-- Web::Renderer       -> WebGL2 via Filament WASM or Three.js
  +-- AppKit::Renderer    -> Filament (Metal backend)
  +-- UIKit::Renderer     -> Filament (Metal backend)
  +-- Android::Renderer   -> Filament (Vulkan backend)
```

### For 2D drawing only (simpler path):

```
UI::Canvas -> Skia C API -> Skia's platform backend
```

Skia handles the platform backend selection internally. This avoids writing per-platform rendering code for 2D at the cost of bundling Skia (adds ~6–10 MB to binary size depending on compile options).

---

## 5. Crystal FFI Binding Examples

These are structural examples to guide future binding work. They are not yet in the codebase.

### 5a. WebGPU (wgpu-native)

```crystal
# Future: src/ui/native/wgpu.cr
@[Link("wgpu_native")]
lib LibWGPU
  # Opaque handles (all are void* underneath)
  type WGPUInstance       = Void*
  type WGPUAdapter        = Void*
  type WGPUDevice         = Void*
  type WGPUQueue          = Void*
  type WGPUSurface        = Void*
  type WGPURenderPipeline = Void*
  type WGPUCommandEncoder = Void*
  type WGPUTextureView    = Void*
  type WGPUBuffer         = Void*
  type WGPUShaderModule   = Void*

  # Descriptor structs (simplified — full structs have many fields)
  struct WGPUInstanceDescriptor
    next_in_chain : Void*  # chaining for extensions
  end

  struct WGPURequestAdapterOptions
    next_in_chain     : Void*
    compatible_surface : WGPUSurface
    power_preference   : UInt32  # WGPUPowerPreference enum
    backend_type       : UInt32  # WGPUBackendType enum
    force_fallback_adapter : Bool
  end

  # Callback types
  alias WGPURequestAdapterCallback = (UInt32, WGPUAdapter, LibC::Char*, Void*) -> Void
  alias WGPURequestDeviceCallback  = (UInt32, WGPUDevice, LibC::Char*, Void*) -> Void

  # Core functions
  fun wgpuCreateInstance(descriptor : WGPUInstanceDescriptor*) : WGPUInstance
  fun wgpuInstanceRequestAdapter(
    instance  : WGPUInstance,
    options   : WGPURequestAdapterOptions*,
    callback  : WGPURequestAdapterCallback,
    user_data : Void*
  ) : Void
  fun wgpuAdapterRequestDevice(
    adapter   : WGPUAdapter,
    descriptor : Void*,   # WGPUDeviceDescriptor*
    callback  : WGPURequestDeviceCallback,
    user_data : Void*
  ) : Void
  fun wgpuDeviceGetQueue(device : WGPUDevice) : WGPUQueue
  fun wgpuInstanceRelease(instance : WGPUInstance) : Void
  fun wgpuAdapterRelease(adapter : WGPUAdapter) : Void
  fun wgpuDeviceRelease(device : WGPUDevice) : Void
end
```

### 5b. Skia C API

```crystal
# Future: src/ui/native/skia.cr
@[Link("skia")]
lib LibSkia
  # Opaque handles
  type SKSurface = Void*
  type SKCanvas  = Void*
  type SKPaint   = Void*
  type SKPath    = Void*
  type SKImage   = Void*
  type SKFont    = Void*

  # Value structs
  struct SKRect
    left   : Float32
    top    : Float32
    right  : Float32
    bottom : Float32
  end

  struct SKPoint
    x : Float32
    y : Float32
  end

  struct SKColor  # packed ARGB UInt32
    value : UInt32
  end

  # Surface creation
  fun sk_surface_new_raster_n32_premul(width : Int32, height : Int32, props : Void*) : SKSurface
  fun sk_surface_get_canvas(surface : SKSurface) : SKCanvas
  fun sk_surface_unref(surface : SKSurface) : Void

  # Paint
  fun sk_paint_new : SKPaint
  fun sk_paint_delete(paint : SKPaint) : Void
  fun sk_paint_set_color(paint : SKPaint, color : UInt32) : Void
  fun sk_paint_set_stroke_width(paint : SKPaint, width : Float32) : Void
  fun sk_paint_set_antialias(paint : SKPaint, antialias : Bool) : Void

  # Canvas drawing
  fun sk_canvas_clear(canvas : SKCanvas, color : UInt32) : Void
  fun sk_canvas_draw_rect(canvas : SKCanvas, rect : SKRect*, paint : SKPaint) : Void
  fun sk_canvas_draw_circle(canvas : SKCanvas, cx : Float32, cy : Float32, radius : Float32, paint : SKPaint) : Void
  fun sk_canvas_draw_path(canvas : SKCanvas, path : SKPath, paint : SKPaint) : Void
  fun sk_canvas_save(canvas : SKCanvas) : Int32
  fun sk_canvas_restore(canvas : SKCanvas) : Void
  fun sk_canvas_translate(canvas : SKCanvas, dx : Float32, dy : Float32) : Void
  fun sk_canvas_scale(canvas : SKCanvas, sx : Float32, sy : Float32) : Void

  # Path
  fun sk_path_new : SKPath
  fun sk_path_delete(path : SKPath) : Void
  fun sk_path_move_to(path : SKPath, x : Float32, y : Float32) : Void
  fun sk_path_line_to(path : SKPath, x : Float32, y : Float32) : Void
  fun sk_path_cubic_to(path : SKPath, x0 : Float32, y0 : Float32, x1 : Float32, y1 : Float32, x2 : Float32, y2 : Float32) : Void
  fun sk_path_close(path : SKPath) : Void
end
```

### 5c. Vulkan (abbreviated)

```crystal
# Future: src/ui/native/vulkan.cr
@[Link("vulkan")]
lib LibVulkan
  # Handles (defined in vulkan.h as dispatchable/non-dispatchable)
  type VkInstance       = Void*
  type VkPhysicalDevice = Void*
  type VkDevice         = Void*
  type VkQueue          = Void*
  type VkCommandBuffer  = Void*
  type VkSwapchainKHR   = UInt64  # non-dispatchable handles are 64-bit on all platforms

  VK_SUCCESS           = 0_i32
  VK_ERROR_OUT_OF_DATE = -1000001004_i32  # VK_ERROR_OUT_OF_DATE_KHR

  struct VkApplicationInfo
    s_type              : Int32     # VkStructureType
    p_next              : Void*
    p_application_name  : LibC::Char*
    application_version : UInt32
    p_engine_name       : LibC::Char*
    engine_version      : UInt32
    api_version         : UInt32
  end

  struct VkInstanceCreateInfo
    s_type                     : Int32
    p_next                     : Void*
    flags                      : UInt32
    p_application_info         : VkApplicationInfo*
    enabled_layer_count        : UInt32
    pp_enabled_layer_names     : LibC::Char**
    enabled_extension_count    : UInt32
    pp_enabled_extension_names : LibC::Char**
  end

  fun vkCreateInstance(create_info : VkInstanceCreateInfo*, allocator : Void*, instance : VkInstance*) : Int32
  fun vkDestroyInstance(instance : VkInstance, allocator : Void*) : Void
  fun vkEnumeratePhysicalDevices(instance : VkInstance, count : UInt32*, devices : VkPhysicalDevice*) : Int32
end
```

---

## 6. Implementation Roadmap (Future Phases)

These phases are not scheduled. They are recorded here so that when graphics work is prioritized, the team has a starting point.

**Phase G1: UI::Canvas view type (stub)**
- Add `UI::Canvas` to `src/ui/views/canvas.cr` as a concrete `UI::View` subclass
- `PlatformVisitor` gains an abstract `visit(view : Canvas)` method
- All existing renderers implement `visit` as a no-op or placeholder `<canvas>` element (web)
- No actual drawing API yet
- Add to the 9 core view types (making it 10)

**Phase G2: Skia C API bindings for 2D drawing**
- Add `src/ui/native/skia.cr` with `LibSkia` bindings
- Implement a `UI::DrawingContext` Crystal wrapper around `LibSkia` primitives
- Application code calls `DrawingContext` methods inside a `UI::Canvas` builder block
- AppKit/UIKit/Android renderers route Canvas rendering through Skia
- Web renderer routes to HTML5 Canvas API

**Phase G3: wgpu-native bindings for GPU-accelerated rendering**
- Add `src/ui/native/wgpu.cr` with `LibWGPU` bindings
- Implement swap chain and render pass management
- Replace or complement Skia with GPU-accelerated path via wgpu-native
- Enable GPU effects on Canvas (blur, composite operations, shader effects)

**Phase G4: 3D scene graph (UI::Scene3D)**
- Evaluate Filament vs. writing a minimal 3D renderer on top of wgpu-native
- Add `UI::Scene3D` view type
- Define a Crystal-level scene graph API (meshes, lights, cameras, materials)
- Implement per-platform rendering

---

## 7. Open Questions

These questions need answers before implementation begins:

1. **Bundling vs. system library:** Should Skia and wgpu-native be bundled with the shard (checked in as pre-built static libs) or required as system installations? Bundling simplifies developer setup but increases repository size. wgpu-native is available as pre-built releases from GitHub.

2. **Shader authoring:** How do developers write shaders? Options: WGSL (WebGPU Shading Language, works with wgpu-native on all platforms), GLSL (needs compilation to SPIR-V for Vulkan), or platform-specific (MSL for Metal, GLSL ES for Android). WGSL is the cleanest answer for wgpu-native.

3. **Crystal GC interaction with GPU resources:** GPU resources (buffers, textures, pipelines) must be destroyed deterministically. Crystal's BoehmGC does not guarantee finalization order. GPU resource wrappers should use explicit `dispose!` or a `with_gpu_resource { }` block pattern — do not rely on Crystal finalizers for GPU cleanup.

4. **UI::Canvas placement in the view type hierarchy:** Should `UI::Canvas` be a leaf view type (no children) that receives a drawing callback, or should it be a container type? A leaf type with a drawing callback is simpler and matches how HTML5 Canvas, Core Graphics, and Skia think about drawing contexts.

5. **2D coordinate system:** Crystal UI uses points (not pixels). Canvas drawing should also use points with device pixel ratio applied by the renderer. Define this contract clearly before implementing.

6. **Metal 4 timing:** Metal 4 requires macOS 26 / iOS 26. The existing AppKit and UIKit renderers target earlier OS versions. Metal 4 bindings should gate on OS version, not replace Metal 3 support.

---

## 8. Related Skills

- **cross-platform-components** — The existing 9 view types; Canvas will be the 10th when implemented
- **platform-renderers** — How to add new view types; the same pattern applies to UI::Canvas
- **flutter-architecture-lessons** — Section 3a explains why we use native components instead of custom painting; the Canvas type is the deliberate exception for cases that genuinely need custom drawing
