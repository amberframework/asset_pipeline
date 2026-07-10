// HIG showcase window helper.
//
// Asset Pipeline's core objc_bridge.m intentionally does NOT expose helpers
// for NSApplication/NSWindow creation -- those belong to the host, not the
// renderer. happy_coach solves this with happy_coach_platform_bridge.m.
// This file is the HIG-host equivalent: a few small C functions that wrap
// the multi-argument initializers Crystal can't call directly.
//
// Build: clang -c window_helper.m -o window_helper.o -fno-objc-arc
//        (link with -framework CoreGraphics for CGWindowListCreateImage path)
//
// Memory: returns retained NSWindow*. Caller (Crystal) owns one +1 retain.
// No ARC -- matches asset_pipeline's bridge memory model.

#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import <QuartzCore/QuartzCore.h>
#include <dlfcn.h>

// CGWindowListCreateImage is marked obsoleted=15.0 in the macOS 15 SDK
// (SCREEN_CAPTURE_OBSOLETE macro → __attribute__((availability(macos,obsoleted=15.0,...)))).
// Calling it directly through the header would be a compile-time hard error.
// Instead we resolve it at runtime via dlsym so the build is clean on any SDK.
// The symbol is still present and functional in the CoreGraphics dylib on
// macOS 26 -- Apple has not removed it, only deprecated it in headers.
// ScreenCaptureKit requires an async model + explicit entitlement; it is not
// suitable for a synchronous validation CLI running from Terminal.
typedef CGImageRef (*CGWindowListCreateImageFn)(
    CGRect, CGWindowListOption, CGWindowID, CGWindowImageOption);

static CGWindowListCreateImageFn resolve_cgwindowlist_create_image(void) {
    void *sym = dlsym(RTLD_DEFAULT, "CGWindowListCreateImage");
    return (CGWindowListCreateImageFn)sym;
}

// ============================================================
// Live-window capture path (Phase 0.1)
//
// CGWindowListCreateImage composites the actual CoreAnimation layer tree,
// which means NSVisualEffectView / Liquid Glass picks up the backdrop layer
// beneath the tested view and produces a real frosted-glass render.
//
// cacheDisplayInRect:toBitmapImageRep: rasterizes against an empty bitmap
// context -- NSVisualEffectView sees no backdrop and falls back to a solid
// fill. That path produced every false "PASS_WITH_NOTES" for glass slugs.
//
// One-time host setup required:
//   System Settings -> Privacy & Security -> Screen Recording ->
//   allow Terminal (or iTerm or whatever launches the spec). Without this
//   CGWindowListCreateImage returns a 1x1 black image silently.
//
// Diagnostic: if the output PNG is all-black or < 4 KB, the process lacks
// Screen Recording permission -- we print a clear message to stdout.
// ============================================================

// Create a capture-grade NSWindow.
//   - Borderless style so the window chrome doesn't appear in the capture.
//   - Positioned far off-screen so it does not steal focus or overlap any
//     real display. CGWindowListCreateImage still composites off-screen
//     windows as long as isVisible == YES and the window has been order-fronted.
//   - appearance_name: "dark" selects NSAppearanceNameDarkAqua, anything else
//     selects NSAppearanceNameAqua (light).
// Returns the retained NSWindow*. Pass it to objc_install_backdrop,
// then add your tested content to [window contentView], then call
// objc_capture_window_to_png, then objc_close_capture_window.
// Returns a pair of windows packed as: { backdrop_window*, capture_window* }
// encoded as a single void* pointing to a malloc'd two-pointer array.
// Callers use objc_install_backdrop and objc_install_content_view with
// the capture window, and objc_close_capture_window with both.
//
// Architecture: NSVisualEffectView blurs the window-server compositor stack
// that is BEHIND the window (real on-screen content), not CALayers inside
// the same window. To get Liquid Glass blurring against our backdrop image
// we create two windows on the primary display at a corner the user is
// unlikely to notice:
//   1. backdrop_window (below) -- NSWindow with an NSImageView filling it.
//   2. capture_window (above, transparent) -- the actual content sits here.
// NSVisualEffectView in the capture_window sees the backdrop_window below it
// in the window-server compositor and blurs it, producing a genuine frosted
// glass render.
//
// We use the far top-right corner of the main screen (outside typical usage
// areas) at level NSNormalWindowLevel - 1 so neither window interferes with
// normal app windows.
static void **g_capture_pair = NULL;

void *objc_create_capture_window(double width, double height, const char *appearance_name) {
    NSAppearance *app_appearance = [NSAppearance appearanceNamed:
        (appearance_name && strcmp(appearance_name, "dark") == 0)
            ? NSAppearanceNameDarkAqua
            : NSAppearanceNameAqua];

    // Position in the top-right corner of the primary screen, partially or
    // fully off the screen edge if the display is smaller than 1200px wide.
    // The windows will be on-screen for the compositor but will flash briefly.
    NSScreen *screen = [NSScreen mainScreen];
    NSRect screen_frame = screen ? [screen frame] : NSMakeRect(0, 0, 1440, 900);
    CGFloat x = screen_frame.origin.x + screen_frame.size.width - width;
    CGFloat y = screen_frame.origin.y + screen_frame.size.height - height;
    NSRect frame = NSMakeRect(x, y, width, height);

    // 1. Backdrop window -- opaque, holds the backdrop image.
    NSWindow *bg_win = [[NSWindow alloc]
        initWithContentRect:frame
                  styleMask:NSWindowStyleMaskBorderless
                    backing:NSBackingStoreBuffered
                      defer:NO];
    if (!bg_win) return NULL;
    [bg_win setAppearance:app_appearance];
    [bg_win setOpaque:YES];
    [bg_win setLevel:NSNormalWindowLevel - 2];

    NSView *bg_root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    bg_root.wantsLayer = YES;
    bg_root.layer.backgroundColor = [[NSColor blackColor] CGColor];
    [bg_win setContentView:bg_root];
    [bg_win orderFront:nil];

    // 2. Capture window -- opaque with a white/black base so NSVisualEffectView
    // withinWindow mode has something to sample beneath the glass card.
    // The backdrop image will be installed as a full-window NSImageView inside
    // this window (behind the content NSView), so the NSVisualEffectView sees
    // it as a real sublayer beneath itself and blurs it correctly.
    //
    // WHY opaque: NSVisualEffectBlendingModeWithinWindow requires the window to
    // be opaque (or at least the root view to be opaque) for the compositor to
    // have a definite backdrop to blur. With a clearColor transparent window the
    // material sees nothing and renders as a solid fill.
    NSWindow *cap_win = [[NSWindow alloc]
        initWithContentRect:frame
                  styleMask:NSWindowStyleMaskBorderless
                    backing:NSBackingStoreBuffered
                      defer:NO];
    if (!cap_win) {
        [bg_win close];
        [bg_win release];
        return NULL;
    }
    [cap_win setAppearance:app_appearance];
    // Opaque + black/white fallback base so the material compositor has a
    // definite background to sample when no backdrop image is supplied.
    [cap_win setOpaque:YES];
    BOOL is_dark = (appearance_name && strcmp(appearance_name, "dark") == 0);
    [cap_win setBackgroundColor:is_dark ? [NSColor colorWithWhite:0.12 alpha:1.0]
                                        : [NSColor colorWithWhite:0.97 alpha:1.0]];
    [cap_win setLevel:NSNormalWindowLevel - 1];

    // Root view: layer-backed, fills the window.
    NSView *cap_root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    cap_root.wantsLayer = YES;
    [cap_win setContentView:cap_root];
    [cap_win orderFront:nil];

    // Pack both into a malloc'd array. objc_install_backdrop writes into cap_win
    // (as a background NSImageView at index 0), objc_install_content_view adds
    // the glass NSVisualEffectView on top, and objc_capture_window_to_png captures
    // cap_win. bg_win is still created for compatibility but is not used in the
    // withinWindow architecture -- it is closed immediately by objc_close_capture_window.
    void **pair = (void **)malloc(2 * sizeof(void *));
    pair[0] = (void *)bg_win;
    pair[1] = (void *)cap_win;
    g_capture_pair = pair;
    return (void *)pair;
}

// Install a backdrop image as a bottom-most NSImageView inside the CAPTURE
// window (pair[1]). This is the correct architecture for
// NSVisualEffectBlendingModeWithinWindow: the backdrop must be a layer within
// the same NSWindow as the NSVisualEffectView so the compositor can blur it.
//
// The old approach put the backdrop in a separate NSWindow (pair[0]) and used
// .behindWindow mode. That produced solid fills because CGWindowListCreateImage
// captured only the foreground window in practice. The new approach:
//   1. Adds an NSImageView filling the capture window's content view root.
//   2. The NSVisualEffectView is later added on top (via objc_install_content_view).
//   3. With .withinWindow mode, the material blurs the NSImageView beneath it.
//
// pair_ptr is the void** returned by objc_create_capture_window.
// image_path must be an absolute filesystem path to a JPEG or PNG.
// Returns 1 on success, 0 if the image could not be loaded.
int objc_install_backdrop(void *pair_ptr, const char *image_path) {
    if (!pair_ptr || !image_path) return 0;
    void **pair = (void **)pair_ptr;
    // Install into the CAPTURE window (pair[1]), not the backdrop window (pair[0]).
    NSWindow *cap_win = (NSWindow *)pair[1];
    NSView *root = [cap_win contentView];
    if (!root) return 0;

    NSString *path = [NSString stringWithUTF8String:image_path];
    NSImage *img = [[NSImage alloc] initWithContentsOfFile:path];
    if (!img) {
        fprintf(stdout, "BACKDROP_LOAD_FAIL %s\n", image_path);
        fflush(stdout);
        return 0;
    }

    // NSImageView fills the entire root view. It is added BEFORE the content
    // NSVisualEffectView (which is added in objc_install_content_view), so it
    // sits at z-index 0 -- beneath the glass card. The NSVisualEffectView with
    // .withinWindow blending samples and blurs this image view's contents.
    NSImageView *iv = [[NSImageView alloc] initWithFrame:[root bounds]];
    iv.image = img;
    iv.imageScaling = NSImageScaleAxesIndependently;
    iv.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [root addSubview:iv positioned:NSWindowBelow relativeTo:nil];
    [iv release];
    [img release];
    NSLog(@"[window_helper] installing backdrop: %@", path);
    return 1;
}

// Add a native view into the CAPTURE window (pair[1]).
// pair_ptr is the void** returned by objc_create_capture_window.
// LEGACY: stretches the content view to fill the entire window.
// Use objc_install_content_view_centered for modal card components (sheets,
// alerts, popovers, action-sheets, activity-views) that should be centered
// with content-hugging height.
void objc_install_content_view(void *pair_ptr, void *content_view_ptr) {
    if (!pair_ptr || !content_view_ptr) return;
    void **pair = (void **)pair_ptr;
    NSWindow *cap_win = (NSWindow *)pair[1];
    NSView *root = [cap_win contentView];
    NSView *content = (NSView *)content_view_ptr;
    content.wantsLayer = YES;

    // The VStack renderer bakes a solid opaque background onto the root
    // NSStackView's CALayer to fix legibility in the old offscreen bitmap path
    // (gaps.md iteration-21). In the live compositor path that background blocks
    // the backdrop NSImageView, preventing NSVisualEffectView .withinWindow from
    // blurring the backdrop. Clear it here so the backdrop shows through.
    // This only affects the capture window; production apps use hig_run_app which
    // does not call this function.
    if (content.layer) {
        content.layer.backgroundColor = [[NSColor clearColor] CGColor];
    }

    content.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:root.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
    ]];
}

// Add a native view centered inside the CAPTURE window with a max-width
// constraint and content-hugging height. This is the correct installation
// path for modal card components (sheets, alerts, popovers, action-sheets,
// activity-views) that must appear as a centered card floating over the
// backdrop, NOT stretched to fill the window.
//
// max_width: the maximum width of the card in points. The card may be
//   narrower if its intrinsic content is narrower. Pass 540 for sheets,
//   380 for alerts, 320 for popovers.
// max_height: soft upper bound on card height in points. Pass 0 (or a
//   very large value like 10000) to let the card hug its content height
//   with no upper limit.
//
// Layout logic:
//   - centerX and centerY pins center the card within the window.
//   - widthAnchor <= max_width (priority NSLayoutPriorityDefaultHigh=750)
//     so the card can shrink but not grow beyond max_width.
//   - No bottomAnchor/topAnchor equality — the card takes its intrinsic
//     height from its content (NSStackView compresses to its arranged
//     subviews, NSVisualEffectView sizes to its subview).
//   - Vertical content-hugging priority is set to NSLayoutPriorityRequired
//     (1000) on the content view so it resists vertical expansion.
//
// The visitor-level objc_constrain_width calls on Sheet/Alert/Popover add
// equality width constraints at priority 999, which will conflict with
// the max-width (<=) constraint here. The <= constraint at 750 is
// weaker and will defer to the equality at 999, making the visitor-level
// constraint the effective width. This is intentional: visitor sets
// exact width, window installation centers it.
void objc_install_content_view_centered(void *pair_ptr, void *content_view_ptr,
                                        double max_width, double max_height) {
    if (!pair_ptr || !content_view_ptr) return;
    void **pair = (void **)pair_ptr;
    NSWindow *cap_win = (NSWindow *)pair[1];
    NSView *root = [cap_win contentView];
    NSView *content = (NSView *)content_view_ptr;
    content.wantsLayer = YES;

    // Clear any baked solid background so the backdrop shows through the glass.
    if (content.layer) {
        content.layer.backgroundColor = [[NSColor clearColor] CGColor];
    }

    content.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:content];

    // Center the card within the window.
    NSLayoutConstraint *cx = [content.centerXAnchor
        constraintEqualToAnchor:root.centerXAnchor];
    NSLayoutConstraint *cy = [content.centerYAnchor
        constraintEqualToAnchor:root.centerYAnchor];
    cx.active = YES;
    cy.active = YES;

    // Max-width: card may not exceed max_width, but the visitor-level
    // equality constraint (priority 999) wins if set and is <= max_width.
    if (max_width > 0.0) {
        NSLayoutConstraint *mw = [content.widthAnchor
            constraintLessThanOrEqualToConstant:(CGFloat)max_width];
        mw.priority = NSLayoutPriorityDefaultHigh; // 750
        mw.active = YES;
    }

    // Soft max-height: only applied when the caller explicitly limits height.
    // Passing 0 skips this constraint entirely so the card hugs content.
    if (max_height > 0.0 && max_height < 5000.0) {
        NSLayoutConstraint *mh = [content.heightAnchor
            constraintLessThanOrEqualToConstant:(CGFloat)max_height];
        mh.priority = NSLayoutPriorityDefaultHigh; // 750
        mh.active = YES;
    }

    // Vertical content-hugging: resist growing taller than intrinsic height.
    // NSLayoutConstraintOrientationVertical = 1.
    [content setContentHuggingPriority:NSLayoutPriorityRequired
                        forOrientation:NSLayoutConstraintOrientationVertical];
    // Horizontal content-hugging at defaultHigh so the card can reach max_width
    // if the content warrants it, but won't stretch beyond it.
    [content setContentHuggingPriority:NSLayoutPriorityDefaultHigh
                        forOrientation:NSLayoutConstraintOrientationHorizontal];
}

// Install a translucent dimming overlay (semi-transparent black NSView) over
// everything already in the capture window. Call this AFTER installing the
// chrome background and BEFORE installing the sheet card, so the dim sits
// between chrome and sheet. Matches HIG: "the app appears dimmed behind the
// sheet" (Sheets / macOS Platform considerations).
//
// alpha: 0.30 for light appearance, 0.50 for dark appearance.
// pair_ptr: the void** returned by objc_create_capture_window.
void objc_install_dimming_overlay(void *pair_ptr, double alpha) {
    if (!pair_ptr) return;
    void **pair = (void **)pair_ptr;
    NSWindow *cap_win = (NSWindow *)pair[1];
    NSView *root = [cap_win contentView];
    if (!root) return;

    // Use Auto Layout (TAMIC=NO + 4-edge pin) so the dim layer fills the root
    // even when the root's bounds are determined by Auto Layout after layout pass.
    // Using autoresizingMask in a mixed Auto Layout hierarchy can produce a
    // zero-frame dim that is invisible in the capture. 4-edge constraints are
    // authoritative regardless of when layout resolves.
    // alpha: 0.40 for both light and dark to ensure legibility of the dim effect
    // in the validation screenshot (June R3: previous 0.30 was not visible).
    NSView *dim = [[NSView alloc] initWithFrame:NSZeroRect];
    dim.wantsLayer = YES;
    dim.translatesAutoresizingMaskIntoConstraints = NO;
    // Force the layer so we can set its background immediately (without waiting
    // for a layout pass -- the layer is ready as soon as wantsLayer=YES is set).
    [dim setWantsLayer:YES];
    dim.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:(CGFloat)alpha] CGColor];
    [root addSubview:dim];
    [NSLayoutConstraint activateConstraints:@[
        [dim.topAnchor    constraintEqualToAnchor:root.topAnchor],
        [dim.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [dim.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [dim.bottomAnchor  constraintEqualToAnchor:root.bottomAnchor],
    ]];
    [dim release];
}

// Install a sheet card anchored near the top of the capture window.
//
// HIG (macOS, Sheets): "a sheet is a cardlike view with rounded corners that
// floats on top of its parent window. ... the app appears dimmed behind the
// sheet." The sheet's top edge should kiss the bottom of the titlebar area.
//
// Layout:
//   - topAnchor constrained to root.topAnchor + titlebar_offset (44pt default).
//   - centerXAnchor constrained to root.centerXAnchor (sheet is centered).
//   - width equality at sheet_width (540pt for Conjure Reminder).
//   - No bottomAnchor constraint: the card hugs its content height.
//
// titlebar_offset: distance from the top of the window to the top of the sheet
//   card. 44pt simulates the titlebar height for a titled window.
// sheet_width: exact width of the sheet card in points.
//
// pair_ptr is the void** returned by objc_create_capture_window.
void objc_install_sheet_top_anchored(void *pair_ptr, void *content_view_ptr,
                                      double titlebar_offset, double sheet_width) {
    if (!pair_ptr || !content_view_ptr) return;
    void **pair = (void **)pair_ptr;
    NSWindow *cap_win = (NSWindow *)pair[1];
    NSView *root = [cap_win contentView];
    NSView *content = (NSView *)content_view_ptr;
    content.wantsLayer = YES;

    // Clear any baked solid background so the backdrop shows through the glass.
    if (content.layer) {
        content.layer.backgroundColor = [[NSColor clearColor] CGColor];
    }

    content.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:content];

    // Top edge anchored to titlebar_offset below the window top.
    // NSView coordinate system is bottom-up on macOS, so "top of window"
    // in AppKit terms is the view's topAnchor (NSLayoutYAxisAnchor on the
    // root). constraintEqualToAnchor:constant: with a negative constant
    // pushes DOWN from the top of the root view.
    // AppKit Auto Layout: root.topAnchor is the top of the content view
    // in the flipped-coordinate sense provided by NSLayoutAnchor. Positive
    // constant moves the sheet DOWN from the top edge.
    NSLayoutConstraint *top_c = [content.topAnchor
        constraintEqualToAnchor:root.topAnchor
                       constant:(CGFloat)titlebar_offset];
    top_c.active = YES;

    // Horizontal centering.
    NSLayoutConstraint *cx = [content.centerXAnchor
        constraintEqualToAnchor:root.centerXAnchor];
    cx.active = YES;

    // Width equality at sheet_width (e.g. 540pt for standard sheets).
    if (sheet_width > 0.0) {
        NSLayoutConstraint *wc = [content.widthAnchor
            constraintEqualToConstant:(CGFloat)sheet_width];
        wc.priority = NSLayoutPriorityRequired - 1; // 999
        wc.active = YES;
    }

    // Vertical content-hugging: the card takes its height from its content.
    [content setContentHuggingPriority:NSLayoutPriorityRequired
                        forOrientation:NSLayoutConstraintOrientationVertical];
}

// Capture the window's composited framebuffer to a PNG file.
// Uses CGWindowListCreateImage so the CoreAnimation compositor (including
// Liquid Glass backdrop blur) is baked into the output.
//
// Permission note: CGWindowListCreateImage requires the host process to have
// Screen Recording permission (TCC). If permission is missing the returned
// CGImageRef is 1x1 or has zero dimensions -- we detect this and print a
// diagnostic rather than writing a black PNG silently.
//
// Returns 1 on success, 0 on failure.
// Capture the CAPTURE window (pair[1]) to PNG.
// pair_ptr is the void** returned by objc_create_capture_window.
int objc_capture_window_to_png(void *pair_ptr, const char *output_path) {
    if (!pair_ptr || !output_path) return 0;
    void **pair = (void **)pair_ptr;
    NSWindow *win = (NSWindow *)pair[1];

    // Flush all pending CA transactions before capture.
    [CATransaction flush];

    CGWindowID win_id = (CGWindowID)[win windowNumber];

    // kCGWindowImageBestResolution: uses the window's backing scale factor
    // (2x on Retina) so the PNG is full resolution.
    // kCGWindowImageBoundsIgnoreFraming: excludes the window shadow/chrome.
    //
    // Resolved via dlsym to avoid the macOS 15 SDK compile-time "obsoleted"
    // error. The symbol is still present in the CoreGraphics dylib on macOS 26.
    CGWindowListCreateImageFn cg_capture = resolve_cgwindowlist_create_image();
    if (!cg_capture) {
        fprintf(stdout, "CAPTURE_FAIL -- CGWindowListCreateImage not found in dylib "
                "(unexpected on macOS 26)\n");
        fflush(stdout);
        return 0;
    }
    // Single-window capture: the backdrop NSImageView and the NSVisualEffectView
    // are both inside the capture window (pair[1]), so a single-window capture
    // picks up both layers composited correctly by the window server. The old
    // two-window CGWindowListCreateImageFromArray path is no longer needed and
    // was unreliable (it consistently fell back to single-window capture anyway).
    CGImageRef img = cg_capture(
        CGRectNull,
        kCGWindowListOptionIncludingWindow,
        win_id,
        kCGWindowImageBestResolution | kCGWindowImageBoundsIgnoreFraming
    );

    if (!img) {
        fprintf(stdout, "CAPTURE_FAIL windowID=%u -- CGWindowListCreateImage returned NULL\n", win_id);
        fflush(stdout);
        return 0;
    }

    size_t img_w = CGImageGetWidth(img);
    size_t img_h = CGImageGetHeight(img);
    if (img_w <= 1 || img_h <= 1) {
        fprintf(stdout, "CAPTURE_FAIL windowID=%u -- image is %zux%zu "
                "(Screen Recording permission likely missing: "
                "System Settings -> Privacy & Security -> Screen Recording -> "
                "allow your terminal)\n", win_id, img_w, img_h);
        fflush(stdout);
        CGImageRelease(img);
        return 0;
    }

    // White-frame detector: CGWindowListCreateImage can return a valid-dimension
    // all-white image when the capture window has not yet been composited by the
    // window server (window off-screen, level too low, or compositor not settled).
    // This is distinct from TCC-denied (which returns 1x1). Detect only the true
    // blank-frame case by downsampling the ENTIRE image and requiring every sampled
    // pixel to be near-white. A center-only detector false-positives on valid light
    // Liquid Glass captures because the middle of a sheet can legitimately be white.
    //
    // Trigger condition: ALL sampled pixels have R >= 250, G >= 250, B >= 250
    // (pure white or near-white) AND A >= 10 (opaque -- rules out transparency).
    // This catches the CGWindowListCreateImage-returns-white-compositor-not-ready
    // case without false-positiving on amber-backdrop glass cards (which have
    // amber gradient pixels somewhere in the full-frame downsample).
    //
    // On trigger: return 0 so the caller can fall back to the offscreen path.
    // The transparent-alpha check from the old detector is intentionally omitted:
    // TCC-denied returns 1x1 (caught above), not a transparent 2400x1800 image.
    {
        int white_frame = 1;  // assume white until proven otherwise
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        size_t sample_w = 96, sample_h = 96;
        size_t bytes_per_row = sample_w * 4;
        uint8_t *buf = (uint8_t *)calloc(sample_h * bytes_per_row, 1);
        if (buf && cs) {
            CGContextRef ctx = CGBitmapContextCreate(
                buf, sample_w, sample_h, 8, bytes_per_row, cs,
                kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
            if (ctx) {
                CGContextDrawImage(ctx, CGRectMake(0, 0, sample_w, sample_h), img);
                CGContextRelease(ctx);
                // BGRA layout: byte0=B, byte1=G, byte2=R, byte3=A
                // White frame: all pixels R>=250, G>=250, B>=250, A>=10.
                // Any pixel with at least one channel < 250 proves real content.
                int has_non_white = 0;
                for (size_t i = 0; i < sample_w * sample_h; i++) {
                    uint8_t b_px = buf[i * 4 + 0];
                    uint8_t g_px = buf[i * 4 + 1];
                    uint8_t r_px = buf[i * 4 + 2];
                    uint8_t a_px = buf[i * 4 + 3];
                    if (a_px >= 10 && (r_px < 250 || g_px < 250 || b_px < 250)) {
                        has_non_white = 1;
                        break;
                    }
                }
                white_frame = has_non_white ? 0 : 1;
                if (white_frame) {
                    fprintf(stdout, "CAPTURE_INFO -- full-frame 96x96 downsample is all-white "
                            "(compositor not settled); falling back to offscreen path\n");
                    fflush(stdout);
                }
            } else {
                white_frame = 0;  // ctx alloc failed; assume not blank
            }
            free(buf);
        } else {
            white_frame = 0;  // alloc failed; assume not blank
        }
        if (cs) CGColorSpaceRelease(cs);

        if (white_frame) {
            fprintf(stdout, "CAPTURE_FAIL windowID=%u -- white frame detected "
                    "(dimensions %zux%zu; window compositor not settled; "
                    "returning 0 for offscreen fallback)\n", win_id, img_w, img_h);
            fflush(stdout);
            CGImageRelease(img);
            return 0;
        }
    }

    // Write PNG via ImageIO.
    CFStringRef path_cf = CFStringCreateWithCString(NULL, output_path, kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, path_cf, kCFURLPOSIXPathStyle, false);
    CFStringRef png_uti = CFSTR("public.png");
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, png_uti, 1, NULL);
    CFRelease(path_cf);
    CFRelease(url);

    if (!dest) {
        fprintf(stdout, "CAPTURE_FAIL -- could not create PNG destination at %s\n", output_path);
        fflush(stdout);
        CGImageRelease(img);
        return 0;
    }

    CGImageDestinationAddImage(dest, img, NULL);
    bool ok = CGImageDestinationFinalize(dest);
    CFRelease(dest);
    CGImageRelease(img);

    if (ok) {
        fprintf(stdout, "SNAPSHOT OK %s (dimensions %zux%zu)\n", output_path, img_w, img_h);
    } else {
        fprintf(stdout, "CAPTURE_FAIL -- CGImageDestinationFinalize failed for %s\n", output_path);
    }
    fflush(stdout);
    return ok ? 1 : 0;
}

// Close both backdrop and capture windows and free the pair.
// pair_ptr is the void** returned by objc_create_capture_window.
void objc_close_capture_window(void *pair_ptr) {
    if (!pair_ptr) return;
    void **pair = (void **)pair_ptr;
    NSWindow *bg_win  = (NSWindow *)pair[0];
    NSWindow *cap_win = (NSWindow *)pair[1];
    if (cap_win) { [cap_win orderOut:nil]; [cap_win close]; [cap_win release]; }
    if (bg_win)  { [bg_win orderOut:nil];  [bg_win close];  [bg_win release]; }
    free(pair);
    g_capture_pair = NULL;
}

// ============================================================
// Offscreen rasterization path (no Screen Recording TCC required)
//
// Uses NSView cacheDisplayInRect:toBitmapImageRep: which renders the view
// tree directly into a private bitmap context without going through the
// window server compositor. NSVisualEffectView renders as a solid tinted
// fill (no live blur), but all layout, text, controls, and role colors are
// accurate. This path is correct for layout validation in headless CI or
// in contexts where Screen Recording permission has not been granted.
//
// view_ptr: any NSView that has been installed in a window and laid out.
//   Must have a non-zero frame. Call after objc_run_loop_for() to ensure
//   Auto Layout has resolved all constraints.
// width, height: the pixel dimensions to rasterize (logical points on
//   non-Retina, physical pixels on Retina at 2x scale). Pass the window
//   frame dimensions.
// output_path: absolute filesystem path for the PNG output.
// Returns 1 on success, 0 on failure.
// ============================================================
int objc_capture_view_offscreen(void *pair_ptr, const char *output_path,
                                 double width, double height) {
    if (!pair_ptr || !output_path) return 0;
    void **pair = (void **)pair_ptr;
    NSWindow *cap_win = (NSWindow *)pair[1];
    NSView *root = [cap_win contentView];
    if (!root) return 0;

    // Force a layout pass so all Auto Layout constraints are resolved.
    [root layoutSubtreeIfNeeded];
    [cap_win layoutIfNeeded];

    NSRect bounds = NSMakeRect(0, 0, width, height);

    // cacheDisplayInRect:toBitmapImageRep: rasterizes the view tree into a
    // private bitmap context. NSVisualEffectView renders as a solid tinted
    // fill (no live backdrop blur), but all other content (text, controls,
    // images, borders, backgrounds) renders correctly without TCC permission.
    NSBitmapImageRep *rep = [root bitmapImageRepForCachingDisplayInRect:bounds];
    if (!rep) {
        fprintf(stdout, "CAPTURE_OFFSCREEN_FAIL -- bitmapImageRepForCachingDisplayInRect returned nil\n");
        fflush(stdout);
        return 0;
    }
    [root cacheDisplayInRect:bounds toBitmapImageRep:rep];

    NSData *png_data = [rep representationUsingType:NSBitmapImageFileTypePNG
                                         properties:@{}];
    if (!png_data || [png_data length] == 0) {
        fprintf(stdout, "CAPTURE_OFFSCREEN_FAIL -- PNG encoding returned nil or empty\n");
        fflush(stdout);
        return 0;
    }

    NSString *path_str = [NSString stringWithUTF8String:output_path];
    BOOL ok = [png_data writeToFile:path_str atomically:YES];

    size_t img_w = (size_t)[rep pixelsWide];
    size_t img_h = (size_t)[rep pixelsHigh];

    if (ok) {
        fprintf(stdout, "SNAPSHOT OK %s (dimensions %zux%zu) [offscreen]\n",
                output_path, img_w, img_h);
    } else {
        fprintf(stdout, "CAPTURE_OFFSCREEN_FAIL -- writeToFile failed for %s\n", output_path);
    }
    fflush(stdout);
    return ok ? 1 : 0;
}

// ============================================================
// Original window factory (interactive / interactive-debug mode)
// ============================================================

void *hig_create_window(double x, double y, double w, double h, const char *title_cstr) {
    NSRect frame = NSMakeRect(x, y, w, h);
    NSUInteger style = NSWindowStyleMaskTitled
                     | NSWindowStyleMaskClosable
                     | NSWindowStyleMaskResizable;
    NSWindow *win = [[NSWindow alloc] initWithContentRect:frame
                                                styleMask:style
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    if (title_cstr) {
        [win setTitle:[NSString stringWithUTF8String:title_cstr]];
    }
    [win center];
    return (void *)win;
}

// Phase 6.12A — interactive window with content-min-size + appearance pinning.
//
// Identical to `hig_create_window` plus three additions:
//   1. `setContentMinSize:` enforces a lower bound on the user-resizable
//      content area (the brief requires 480×400 for Voyager).
//   2. `appearance_name` is honoured when non-null: "dark" pins the window
//      to NSAppearanceNameDarkAqua, "light" pins to NSAppearanceNameAqua.
//      Any other value (or NULL) leaves the window following the system
//      appearance — the same env-var-or-system contract iOS's
//      SceneDelegate already uses.
//   3. NSWindowStyleMaskMiniaturizable is added so the window behaves like
//      a normal macOS app window (minimise to dock).
//
// Cascade keeps using `hig_create_window` verbatim; Voyager moves to this
// new helper. Avoids modifying the existing helper's signature so neither
// host regresses.
void *hig_create_window_with_min(double x, double y, double w, double h,
                                 double min_w, double min_h,
                                 const char *title_cstr,
                                 const char *appearance_name) {
    NSRect frame = NSMakeRect(x, y, w, h);
    NSUInteger style = NSWindowStyleMaskTitled
                     | NSWindowStyleMaskClosable
                     | NSWindowStyleMaskResizable
                     | NSWindowStyleMaskMiniaturizable;
    NSWindow *win = [[NSWindow alloc] initWithContentRect:frame
                                                styleMask:style
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    if (title_cstr) {
        [win setTitle:[NSString stringWithUTF8String:title_cstr]];
    }
    [win setContentMinSize:NSMakeSize(min_w, min_h)];

    if (appearance_name) {
        if (strcmp(appearance_name, "dark") == 0) {
            [win setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
        } else if (strcmp(appearance_name, "light") == 0) {
            [win setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
        }
        // Any other appearance_name leaves the window following the system.
    }

    [win center];
    return (void *)win;
}

// Snapshot the window using CGWindowListCreateImage (live compositor path).
// This is the correct path for any window that contains NSVisualEffectView
// (Liquid Glass) because the compositor blurs whatever is behind the window
// in the layer stack, including any backdrop CALayer we installed.
//
// The legacy cacheDisplayInRect:toBitmapImageRep: path is preserved as a
// comment below for archaeology. It is NOT used -- it rasterizes against an
// empty context and collapses glass to solid fills.
static int save_window_to_png_live(NSWindow *win, NSString *path) {
    [CATransaction flush];

    CGWindowID win_id = (CGWindowID)[win windowNumber];

    CGWindowListCreateImageFn cg_capture = resolve_cgwindowlist_create_image();
    if (!cg_capture) {
        fprintf(stdout, "CAPTURE_FAIL -- CGWindowListCreateImage not found in dylib\n");
        fflush(stdout);
        return 0;
    }
    CGImageRef img = cg_capture(
        CGRectNull,
        kCGWindowListOptionIncludingWindow,
        win_id,
        kCGWindowImageBestResolution | kCGWindowImageBoundsIgnoreFraming
    );

    if (!img) {
        fprintf(stdout, "CAPTURE_FAIL windowID=%u -- CGWindowListCreateImage returned NULL\n", win_id);
        fflush(stdout);
        return 0;
    }

    size_t img_w = CGImageGetWidth(img);
    size_t img_h = CGImageGetHeight(img);
    if (img_w <= 1 || img_h <= 1) {
        fprintf(stdout,
            "CAPTURE_FAIL windowID=%u -- captured image is %zux%zu pixels.\n"
            "  This almost certainly means Screen Recording permission is missing.\n"
            "  Fix: System Settings -> Privacy & Security -> Screen Recording ->\n"
            "  enable your terminal (Terminal.app / iTerm2 / whatever runs this binary).\n"
            "  Then re-run the capture.\n",
            win_id, img_w, img_h);
        fflush(stdout);
        CGImageRelease(img);
        return 0;
    }

    CFStringRef cf_path = CFStringCreateWithCString(NULL, [path UTF8String], kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, cf_path, kCFURLPOSIXPathStyle, false);
    CFStringRef png_uti = CFSTR("public.png");
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, png_uti, 1, NULL);
    CFRelease(cf_path);
    CFRelease(url);

    if (!dest) {
        fprintf(stdout, "CAPTURE_FAIL -- could not open PNG destination at %s\n", [path UTF8String]);
        fflush(stdout);
        CGImageRelease(img);
        return 0;
    }

    CGImageDestinationAddImage(dest, img, NULL);
    bool ok = CGImageDestinationFinalize(dest);
    CFRelease(dest);
    CGImageRelease(img);

    fprintf(stdout, "SNAPSHOT %s %s (dimensions %zux%zu)\n",
            ok ? "OK" : "FAIL", [path UTF8String], img_w, img_h);
    fflush(stdout);
    return ok ? 1 : 0;
}

// LEGACY (not called): cacheDisplayInRect: path collapses NSVisualEffectView
// to a solid fill because it rasterizes against an empty bitmap context with
// no window-server backdrop. Retained here as documentation of the old approach.
// static int save_window_to_png_legacy(NSWindow *win, NSString *path) { ... }

// Helper invoked off the main loop after the window has settled. If the
// HIG_SCREENSHOT_PATH env var is set, snapshot the window's content view to
// that path and exit cleanly. Otherwise just keep the app running.
@interface HIGScreenshotter : NSObject
@property (assign) NSWindow *win;
- (void)snapshotAndExit:(id)sender;
@end

@implementation HIGScreenshotter
- (void)snapshotAndExit:(id)sender {
    const char *env_path = getenv("HIG_SCREENSHOT_PATH");
    if (env_path && env_path[0]) {
        NSString *path = [NSString stringWithUTF8String:env_path];
        int ok = save_window_to_png_live(self.win, path);
        exit(ok ? 0 : 1);
    }
    // Defense-in-depth: if the binary was launched without HIG_SCREENSHOT_PATH
    // AND without HIG_INTERACTIVE=1 (the explicit opt-in for a persistent
    // window, e.g. during renderer-tweak debugging), exit after the settle
    // delay so an unattended pipeline invocation cannot hang. Previously a
    // missing env var would leave the window up forever, stalling the
    // validation loop until a human manually closed it.
    const char *interactive = getenv("HIG_INTERACTIVE");
    if (!interactive || !interactive[0] || interactive[0] == '0') {
        fprintf(stdout, "NO_SNAPSHOT_PATH exiting (set HIG_INTERACTIVE=1 to keep window open)\n");
        fflush(stdout);
        exit(0);
    }
}
@end

// Pump the AppKit run loop for `seconds` wall-clock time.
// Used by the screenshot path to let NSVisualEffectView render its blur.
//
// NSVisualEffectView's material compositing is driven by the window server and
// requires at least one run loop cycle + display refresh to produce real pixels.
// Without this, CGWindowListCreateImage sees the window before the blur pass
// and captures only the raw subview hierarchy (solid fill from the material's
// nominal color, no blur of the backdrop beneath).
//
// Spinning the run loop for 0.6s is the same approach hig_run_app uses via
// NSTimer + [NSApp run]. Here we use [NSRunLoop runUntilDate:] which is safe
// to call without entering [NSApp run] as long as NSApplication has been
// initialized and the window is on-screen.
void objc_run_loop_for(double seconds) {
    // Ensure NSApplication is initialized and the process is treated as a
    // regular app so the window server gives it access to the compositor.
    // Without activateIgnoringOtherApps:YES the window may not receive
    // compositor attention and NSVisualEffectView's blur pass is skipped.
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [app activateIgnoringOtherApps:YES];

    // Ensure the capture window is key + front (required for compositor rendering).
    if (g_capture_pair) {
        NSWindow *cap_win = (NSWindow *)(g_capture_pair[1]);
        if (cap_win) {
            [cap_win makeKeyAndOrderFront:nil];
        }
    }

    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:seconds];
    [[NSRunLoop mainRunLoop] runUntilDate:end];
}

// Print window geometry to stdout (kept for debugging / fallback paths).
//   RECT_PX x y w h    -- physical pixels, top-origin.
static void print_window_rect(NSWindow *win) {
    NSRect frame = [win frame];
    NSScreen *screen = [win screen] ?: [[NSScreen screens] objectAtIndex:0];
    CGFloat screen_h = [screen frame].size.height;
    CGFloat scale = [screen backingScaleFactor];

    CGFloat top_pts = screen_h - frame.origin.y - frame.size.height;
    long x_px = (long)(frame.origin.x * scale);
    long y_px = (long)(top_pts * scale);
    long w_px = (long)(frame.size.width * scale);
    long h_px = (long)(frame.size.height * scale);

    fprintf(stdout, "RECT_PX %ld %ld %ld %ld\n", x_px, y_px, w_px, h_px);
    fflush(stdout);
}

void hig_run_app(void *window_ptr) {
    NSWindow *win = (NSWindow *)window_ptr;
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];

    // Appearance override for reproducible validation captures.
    // HIG_APPEARANCE=dark -> NSAppearanceNameDarkAqua; anything else (or
    // unset) -> NSAppearanceNameAqua (light). Default matches HIG
    // reference illustrations, which are authored in light appearance.
    const char *appearance = getenv("HIG_APPEARANCE");
    NSAppearance *app_appearance = [NSAppearance appearanceNamed:
        (appearance && strcmp(appearance, "dark") == 0)
            ? NSAppearanceNameDarkAqua
            : NSAppearanceNameAqua];
    [app setAppearance:app_appearance];
    [win setAppearance:app_appearance];

    [win makeKeyAndOrderFront:nil];
    [app activateIgnoringOtherApps:YES];
    print_window_rect(win);

    // Schedule a snapshot pass shortly after the run loop starts so AppKit
    // has a chance to lay out and draw the views once. 0.6s matches the
    // settle delay other test harnesses use for Liquid Glass animations.
    HIGScreenshotter *shooter = [[HIGScreenshotter alloc] init];
    shooter.win = win;
    [NSTimer scheduledTimerWithTimeInterval:0.6
                                     target:shooter
                                   selector:@selector(snapshotAndExit:)
                                   userInfo:nil
                                    repeats:NO];

    [app run];
}
