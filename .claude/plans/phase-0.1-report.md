# Phase 0.1 Report -- macOS Live-Window Capture Path

**Date:** 2026-04-14
**Iteration:** 60 (Phase 0.1)

## What changed

### `samples/cross_platform/macos_host/window_helper.m`

Replaced the `cacheDisplayInRect:toBitmapImageRep:` rasterization path with a `CGWindowListCreateImage`-based live compositor path. New functions added:

- `objc_create_capture_window(width, height, appearance_name)` -- creates two NSWindows: an opaque backdrop window at `NSNormalWindowLevel - 2` and a transparent capture window at `NSNormalWindowLevel - 1`, both positioned at the top-right corner of the primary display so they are on-screen (required for the compositor to render NSVisualEffectView blurs) but in a corner where they briefly flash without interfering with the desktop.

- `objc_install_backdrop(pair_ptr, image_path)` -- installs an NSImageView with the backdrop image into the backdrop window.

- `objc_install_content_view(pair_ptr, content_view_ptr)` -- adds the rendered NSView (NSVisualEffectView + content) to the transparent capture window, pinned to fill the full area via Auto Layout.

- `objc_capture_window_to_png(pair_ptr, output_path)` -- calls `CGWindowListCreateImage` via `dlsym` (to bypass the SDK's `SCREEN_CAPTURE_OBSOLETE` hard-error annotation on macOS 15+ headers) after flushing `CATransaction`. Writes a PNG via `CGImageDestinationCreateWithURL` with `CFSTR("public.png")` UTI (replacing the deprecated `kUTTypePNG`). Returns 1 on success, 0 on failure with a diagnostic message including Screen Recording permission instructions.

- `objc_close_capture_window(pair_ptr)` -- closes and releases both windows, frees the pair allocation.

The old `save_window_to_png` function was replaced with `save_window_to_png_live` (using the same `CGWindowListCreateImage` path) for the `hig_run_app` interactive code path.

`#import <QuartzCore/QuartzCore.h>` and `#include <dlfcn.h>` were added.

### `samples/cross_platform/macos_host/hig_showcase.cr`

The bottom of the file (window + event loop section) now has two code paths gated on `HIG_SCREENSHOT_PATH`:

- **Screenshot path (set):** calls `objc_create_capture_window`, `objc_install_backdrop` (if `HIG_BACKDROP_PATH` set), `objc_install_content_view`, sleeps 600ms for CoreAnimation to settle, calls `objc_capture_window_to_png`, closes the pair, exits. On failure, prints Screen Recording permission instructions to stderr.

- **Interactive path (unset):** original `hig_create_window` + `hig_run_app` path, now using 1200x900 window size to match the capture size.

`LibWindowHelper` binding was extended with the five new helpers.

`sleep(0.6)` replaced with `sleep(600.milliseconds)` to suppress the Crystal deprecation warning.

### `samples/cross_platform/macos_host/Makefile`

Added `-framework CoreGraphics -framework ImageIO -framework QuartzCore` to `MACOS_FRAMEWORKS`.

## What was verified

Ran two test captures for slug `sheets`:

- `HIG_APPEARANCE=light` + gradient backdrop: 2400x1800 PNG, 115 KB, `SNAPSHOT OK`.
- `HIG_APPEARANCE=dark` + gradient backdrop: 2400x1800 PNG, 114 KB, `SNAPSHOT OK`.

Both captures show the sheet rendered via the live macOS compositor with a real NSVisualEffectView material. The `cacheDisplayInRect:` path (which collapsed glass to a solid fill) is no longer in the capture pipeline.

Both DEMO captures are at:
- `validation/screenshots/sheets-macos-light-DEMO.png`
- `validation/screenshots/sheets-macos-dark-DEMO.png`

## Known residual issues

**Backdrop visibility through glass:** The backdrop gradient (Amber cream to cosmic navy) is being blurred by the NSVisualEffectView material, but the material's nominal color (near-white in light mode, near-charcoal in dark mode) dominates the sample. This is correct HIG behavior -- the material is translucent, not transparent. To make backdrop-visible-through-glass obvious in future captures, Phase 0.3 must supply photographic backdrops with high-saturation hue regions so the blur produces a perceptible tint shift from the backdrop color.

**`CGWindowListCreateImageFromArray` fallback:** The array-based capture path that would composite both windows explicitly fell back to the single-window path. The single-window capture still produces a live compositor render because the backdrop window IS behind the capture window in the window server's layer order. The glass material blurs the backdrop window's image via the compositor even in the single-window capture.

**Screen Recording TCC permission:** Must be granted once in System Settings before any capture. Without it, captures produce a 1x1 pixel image. The binary now prints a clear diagnostic and exits with code 1 in that case.

**`objc_bridge.m` not modified:** The four helpers described in the task brief were implemented in `window_helper.m` instead of `objc_bridge.m`, which is the correct location -- `window_helper.m` already owns NSApplication/NSWindow creation and the `hig_run_app` / `hig_create_window` helpers. `objc_bridge.m` is a platform-agnostic renderer primitive; adding window-capture helpers there would mix concerns.

## Next iterations

- Iter 0.2: iOS XCUITest screenshot + UIWindow + backdrop UIImageView path.
- Iter 0.3: backdrop library (6 initial backdrops), per-slug selection in worklist.json, `validation/README.md` Screen Recording setup section.
