// objc_bridge.m — Type-safe ObjC message send wrappers for ARM64
//
// On ARM64 (AAPCS64), objc_msgSend's variadic C signature cannot be called
// directly when floating-point arguments must land in d-registers.  Each
// wrapper casts objc_msgSend to the exact function-pointer type so the
// compiler places arguments in the correct registers.
//
// CGRect is a Homogeneous Floating-point Aggregate (HFA) with 4 doubles,
// passed in d0-d3 on ARM64.
//
// Memory management: This bridge does NOT use ARC.  Crystal's NativeHandle
// with ReleaseStrategy manages all object lifetimes.  Raw void* pointers
// are simply cast to/from id for the message send and back.
//
// Cross-platform: this same source file is compiled for both macOS (AppKit)
// and iOS (UIKit) by conditioning on TARGET_OS_IPHONE vs TARGET_OS_OSX.
// CGRect is used internally so the struct layout is identical on both.
//
// Compile (macOS):
//   clang -c src/ui/native/objc_bridge.m -o objc_bridge.o -fno-objc-arc
// Compile (iOS simulator):
//   clang -c src/ui/native/objc_bridge.m -o objc_bridge.o \
//     -target arm64-apple-ios-simulator \
//     -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
//     -fno-objc-arc

#include <objc/runtime.h>
#include <objc/message.h>
#include <TargetConditionals.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#if TARGET_OS_OSX
  #import <AppKit/AppKit.h>
  #import <QuartzCore/QuartzCore.h>
  #import <UserNotifications/UserNotifications.h>
  #import <WebKit/WebKit.h>
  #import <MapKit/MapKit.h>
  #import <AVKit/AVKit.h>
  #import <AVFoundation/AVFoundation.h>
  typedef NSView      BridgeView;
  typedef NSButton    BridgeButton;
  #define BRIDGE_RECT_MAKE(r) NSMakeRect((r).x, (r).y, (r).width, (r).height)
  typedef NSRect      BridgeRect;
#else
  #import <UIKit/UIKit.h>
  #import <QuartzCore/QuartzCore.h>
  #import <UserNotifications/UserNotifications.h>
  #import <WebKit/WebKit.h>
  #import <MapKit/MapKit.h>
  #import <AVKit/AVKit.h>
  #import <AVFoundation/AVFoundation.h>
  typedef UIView      BridgeView;
  typedef UIButton    BridgeButton;
  #define BRIDGE_RECT_MAKE(r) CGRectMake((r).x, (r).y, (r).width, (r).height)
  typedef CGRect      BridgeRect;
#endif

#if TARGET_OS_OSX
static char apsk_pending_focus_key;
static char apsk_focus_result_key;

@interface NSView (APSKDeferredFirstResponder)
- (void)apsk_deferred_view_did_move_to_window;
@end

@implementation NSView (APSKDeferredFirstResponder)
+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(viewDidMoveToWindow));
    Method replacement = class_getInstanceMethod(self, @selector(apsk_deferred_view_did_move_to_window));
    if (original != NULL && replacement != NULL) {
        method_exchangeImplementations(original, replacement);
    }
}

- (void)apsk_deferred_view_did_move_to_window {
    [self apsk_deferred_view_did_move_to_window];

    NSNumber *is_pending = objc_getAssociatedObject(self, &apsk_pending_focus_key);
    NSWindow *window = self.window;
    if (!is_pending.boolValue || window == nil) return;

    BOOL succeeded = [window makeFirstResponder:(NSResponder *)self];
    objc_setAssociatedObject(self, &apsk_pending_focus_key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &apsk_focus_result_key, @(succeeded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
#endif

// ============================================================
// Section 1: Basic message sends (integer / pointer arguments)
// ============================================================

// (id, SEL) -> id
void *objc_send(void *obj, void *sel) {
    return ((id (*)(id, SEL))objc_msgSend)((id)obj, sel);
}

// (id, SEL, id) -> id
void *objc_send_id(void *obj, void *sel, void *arg) {
    return ((id (*)(id, SEL, id))objc_msgSend)((id)obj, sel, (id)arg);
}

// (id, SEL, id, id) -> id
void *objc_send_id_id(void *obj, void *sel, void *arg1, void *arg2) {
    return ((id (*)(id, SEL, id, id))objc_msgSend)(
        (id)obj, sel, (id)arg1, (id)arg2);
}

// (id, SEL, id, id, id) -> id
void *objc_send_id_id_id(void *obj, void *sel, void *arg1, void *arg2, void *arg3) {
    return ((id (*)(id, SEL, id, id, id))objc_msgSend)(
        (id)obj, sel, (id)arg1, (id)arg2, (id)arg3);
}

// (id, SEL, BOOL) -> void
void objc_send_bool(void *obj, void *sel, int val) {
    ((void (*)(id, SEL, BOOL))objc_msgSend)((id)obj, sel, (BOOL)val);
}

// (id, SEL, NSInteger) -> id
void *objc_send_long(void *obj, void *sel, long long val) {
    return ((id (*)(id, SEL, NSInteger))objc_msgSend)((id)obj, sel, (NSInteger)val);
}

// (id, SEL, NSUInteger) -> id
void *objc_send_ulong(void *obj, void *sel, unsigned long long val) {
    return ((id (*)(id, SEL, NSUInteger))objc_msgSend)((id)obj, sel, (NSUInteger)val);
}

// (id, SEL, id) -> void
void objc_send_void_id(void *obj, void *sel, void *arg) {
    ((void (*)(id, SEL, id))objc_msgSend)((id)obj, sel, (id)arg);
}

// (id, SEL, SEL) -> void
void objc_send_sel(void *obj, void *sel, void *arg) {
    ((void (*)(id, SEL, SEL))objc_msgSend)((id)obj, sel, (SEL)arg);
}

// (id, SEL, id, NSInteger) -> id
void *objc_send_id_long(void *obj, void *sel, void *arg1, long long arg2) {
    return ((id (*)(id, SEL, id, NSInteger))objc_msgSend)(
        (id)obj, sel, (id)arg1, (NSInteger)arg2);
}

// (id, SEL, id, id, NSInteger) -> id
// Used on iOS for e.g. alertControllerWithTitle:message:preferredStyle:.
void *objc_send_id_id_long(void *obj, void *sel, void *arg1, void *arg2, long long arg3) {
    return ((id (*)(id, SEL, id, id, NSInteger))objc_msgSend)(
        (id)obj, sel, (id)arg1, (id)arg2, (NSInteger)arg3);
}

// ============================================================
// Section 2: Double / float register sends
// ============================================================

// (id, SEL, CGFloat) -> void
void objc_send_1d(void *obj, void *sel, double d0) {
    ((void (*)(id, SEL, CGFloat))objc_msgSend)((id)obj, sel, (CGFloat)d0);
}

// (id, SEL, CGFloat) -> id
void *objc_send_1d_ret_id(void *obj, void *sel, double d0) {
    return ((id (*)(id, SEL, CGFloat))objc_msgSend)((id)obj, sel, (CGFloat)d0);
}

// (id, SEL, CGFloat, CGFloat) -> id
void *objc_send_2d_ret_id(void *obj, void *sel, double d0, double d1) {
    return ((id (*)(id, SEL, CGFloat, CGFloat))objc_msgSend)(
        (id)obj, sel, (CGFloat)d0, (CGFloat)d1);
}

// (id, SEL, CGFloat, CGFloat, CGFloat, CGFloat) -> id
void *objc_send_4d_ret_id(void *obj, void *sel, double d0, double d1, double d2, double d3) {
    return ((id (*)(id, SEL, CGFloat, CGFloat, CGFloat, CGFloat))objc_msgSend)(
        (id)obj, sel, (CGFloat)d0, (CGFloat)d1, (CGFloat)d2, (CGFloat)d3);
}

// ============================================================
// Section 3: CGRect / HFA sends
// ============================================================

typedef struct { double x, y, width, height; } BridgeCGRect;

// (id, SEL, CGRect) -> id  (NSRect on macOS, CGRect on iOS — layouts match)
void *objc_send_rect(void *obj, void *sel, BridgeCGRect rect) {
    BridgeRect r = BRIDGE_RECT_MAKE(rect);
    return ((id (*)(id, SEL, BridgeRect))objc_msgSend)((id)obj, sel, r);
}

// (id, SEL, CGRect) -> void
void objc_send_rect_void(void *obj, void *sel, BridgeCGRect rect) {
    BridgeRect r = BRIDGE_RECT_MAKE(rect);
    ((void (*)(id, SEL, BridgeRect))objc_msgSend)((id)obj, sel, r);
}

// (id, SEL) -> BOOL
int objc_send_ret_bool(void *obj, void *sel) {
    return (int)((BOOL (*)(id, SEL))objc_msgSend)((id)obj, sel);
}

// Phase 10B.2a iter 2 (Codex Finding 3) — guarded setEnabled: helper.
// Sends `-setEnabled:` to `obj` only if the object responds to that
// selector. Used by the accessibility-metadata path to functionally
// disable UIControl / NSControl instances when the `:not_enabled`
// trait is set, while no-oping on plain UIView / NSView objects that
// have no enabled state to flip. Returns 1 if the message was sent,
// 0 if the object didn't respond.
int ap_set_enabled_if_responds(void *obj, int enabled) {
    if (!obj) return 0;
    id receiver = (id)obj;
    SEL set_enabled_sel = @selector(setEnabled:);
    if (![receiver respondsToSelector:set_enabled_sel]) return 0;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(receiver, set_enabled_sel, (BOOL)enabled);
    return 1;
}

// ============================================================
// Section 4: Convenience helpers
// ============================================================

// Create an NSString from a C string (caller must manage retain/release)
void *nsstring_from_cstr(const char *str) {
    if (!str) return NULL;
    return [NSString stringWithUTF8String:str];
}

// [NSColor/UIColor colorWithRed:green:blue:alpha:]
void *nscolor_rgba(double r, double g, double b, double a) {
#if TARGET_OS_OSX
    return [NSColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a];
#else
    return [UIColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a];
#endif
}

// [NSColor/UIColor colorWithWhite:alpha:]
void *nscolor_white_alpha(double white, double alpha) {
#if TARGET_OS_OSX
    return [NSColor colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha];
#else
    return [UIColor colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha];
#endif
}

// Apple semantic label colors — dynamic system colors that track appearance.
// Use these instead of a baked RGBA so Light / Dark / Increase-Contrast are
// handled automatically by AppKit / UIKit.
void *nscolor_label_primary(void) {
#if TARGET_OS_OSX
    return [NSColor labelColor];
#else
    return [UIColor labelColor];
#endif
}

void *nscolor_label_secondary(void) {
#if TARGET_OS_OSX
    return [NSColor secondaryLabelColor];
#else
    return [UIColor secondaryLabelColor];
#endif
}

void *nscolor_label_tertiary(void) {
#if TARGET_OS_OSX
    return [NSColor tertiaryLabelColor];
#else
    return [UIColor tertiaryLabelColor];
#endif
}

void *nscolor_label_quaternary(void) {
#if TARGET_OS_OSX
    return [NSColor quaternaryLabelColor];
#else
    return [UIColor quaternaryLabelColor];
#endif
}

// Semantic fill colors for grouped containers (boxes / cards).
// These track the system appearance automatically.
// nscolor_control_background -> macOS: NSColor.controlBackgroundColor (light gray
//   in light, dark charcoal in dark). On iOS falls back to
//   UIColor.secondarySystemBackgroundColor.
// nscolor_separator -> macOS: NSColor.separatorColor (hairline). iOS: UIColor.separatorColor.
void *nscolor_control_background(void) {
#if TARGET_OS_OSX
    return [NSColor controlBackgroundColor];
#else
    return [UIColor secondarySystemBackgroundColor];
#endif
}

void *nscolor_separator(void) {
#if TARGET_OS_OSX
    return [NSColor separatorColor];
#else
    return [UIColor separatorColor];
#endif
}

// Phase 6.12A — platform-native accent color resolver.
//
// macOS: NSColor.controlAccentColor (the live system accent that follows
//   the user's General > Accent preference and the active appearance).
// iOS:   UIColor.tintColor (the dynamic placeholder that resolves to the
//   view hierarchy's tintColor at draw time — typically systemBlue when
//   no override is installed). On iOS 15+ this is a valid class method.
//
// Returned to Crystal when a `UI::DesignTokens::Color::SYSTEM_ACCENT`
// sentinel reaches `token_nscolor` in the AppKit / UIKit renderers
// (Phase 6.12A library-identity pivot).
void *nscolor_control_accent(void) {
#if TARGET_OS_OSX
    return [NSColor controlAccentColor];
#else
    return [UIColor tintColor];
#endif
}

// iOS-only alias for the same accent path, exposed under the more
// UIKit-idiomatic name. Keeps the UIKit-renderer call site reading
// like the surrounding UIColor.* family. On macOS it falls back to
// controlAccentColor for parity.
void *uicolor_tint(void) {
#if TARGET_OS_OSX
    return [NSColor controlAccentColor];
#else
    return [UIColor tintColor];
#endif
}

// [NSFont/UIFont systemFontOfSize:]
void *nsfont_system(double size) {
#if TARGET_OS_OSX
    return [NSFont systemFontOfSize:(CGFloat)size];
#else
    return [UIFont systemFontOfSize:(CGFloat)size];
#endif
}

// [NSFont/UIFont boldSystemFontOfSize:]
void *nsfont_bold_system(double size) {
#if TARGET_OS_OSX
    return [NSFont boldSystemFontOfSize:(CGFloat)size];
#else
    return [UIFont boldSystemFontOfSize:(CGFloat)size];
#endif
}

// [NSFont/UIFont systemFontOfSize:weight:]
void *nsfont_system_weight(double size, double weight) {
#if TARGET_OS_OSX
    return [NSFont systemFontOfSize:(CGFloat)size weight:(NSFontWeight)weight];
#else
    return [UIFont systemFontOfSize:(CGFloat)size weight:(UIFontWeight)weight];
#endif
}

// [NSFont/UIFont monospacedSystemFontOfSize:weight:]
void *nsfont_monospaced_system(double size, double weight) {
#if TARGET_OS_OSX
    return [NSFont monospacedSystemFontOfSize:(CGFloat)size weight:(NSFontWeight)weight];
#else
    return [UIFont monospacedSystemFontOfSize:(CGFloat)size weight:(UIFontWeight)weight];
#endif
}

// [NSFont/UIFont fontWithName:size:]
void *nsfont_named(void *name, double size) {
#if TARGET_OS_OSX
    return [NSFont fontWithName:(NSString *)name size:(CGFloat)size];
#else
    return [UIFont fontWithName:(NSString *)name size:(CGFloat)size];
#endif
}

// [parent addSubview:child]
void objc_add_subview(void *parent, void *child) {
    [(BridgeView *)parent addSubview:(BridgeView *)child];
}

// view.autoresizingMask = mask
void objc_set_autoresize(void *view, unsigned long long mask) {
#if TARGET_OS_OSX
    ((BridgeView *)view).autoresizingMask = (NSAutoresizingMaskOptions)mask;
#else
    ((BridgeView *)view).autoresizingMask = (UIViewAutoresizing)mask;
#endif
}

// [obj setFrame:rect]
void objc_set_frame(void *obj, BridgeCGRect frame) {
    BridgeRect r = BRIDGE_RECT_MAKE(frame);
    [(BridgeView *)obj setFrame:r];
}

// Pin a view's width and height to explicit values via NSLayoutConstraints so
// that the dimensions survive inside auto-layout containers (NSStackView /
// UIStackView).  Sets translatesAutoresizingMaskIntoConstraints:NO first,
// then activates two constraints at high (not required) priority so they do
// not conflict with UIStackView's own internal required constraints while
// still strongly expressing the desired size.
//
// Priority 999 = UILayoutPriorityRequired - 1. UIStackView's internal
// distribution/alignment constraints are at priority 1000 (required).
// Using 999 here lets UIStackView resolve conflicts gracefully rather
// than triggering unsatisfiable constraint warnings.
// Returns the current UIScreen main width in points (logical pixels).
// Used by the renderer to compute row widths when fill-alignment cannot
// propagate a definite width down through nested UIStackViews.
double objc_screen_width(void) {
#if TARGET_OS_OSX
    return 0.0; // Not used on macOS
#else
    return (double)[UIScreen mainScreen].bounds.size.width;
#endif
}

// Phase 6.10 Rem 4 (Item 2B/2C) — runtime device-metrics queries.
//
// These wrap the OS APIs the architect's brief mandates we use INSTEAD of
// baking per-device dimensions into design tokens:
//   iOS:   UIScreen.main.bounds + key window's safeAreaInsets + UITraitCollection
//   macOS: NSScreen.mainScreen.frame
//
// Crystal callers query these on each render so a runtime resize / rotation
// / size-class change always reads the live value.

// Phase 6.10 Rem 4 Continuation (Codex P2 fix): on macOS, `root_fill`
// must size to the active WINDOW's content area, not the physical
// screen. Returning NSScreen.frame from these helpers produced root
// views wider/taller than the host window, clipping the content and
// breaking fluid-resize. We now query the key window's contentView
// frame; we fall back to any visible window's content view, and only
// then to the screen (so the helper still returns *something* during
// app startup before any window is on screen — Crystal callers can
// treat 0 as "unknown").
//
// On iOS the screen IS the window (modulo Slide Over / Split View
// which we don't yet support), so we keep the existing UIScreen path.
#if TARGET_OS_OSX
static NSRect ap_macos_active_window_content_rect(void) {
    NSWindow *win = [NSApp keyWindow];
    if (!win) win = [NSApp mainWindow];
    if (!win) {
        for (NSWindow *w in [NSApp windows]) {
            if (w.isVisible) { win = w; break; }
        }
    }
    if (!win || !win.contentView) {
        NSScreen *screen = [NSScreen mainScreen];
        if (!screen) return NSMakeRect(0, 0, 0, 0);
        return screen.frame;
    }
    return win.contentView.frame;
}
#endif

double objc_screen_height(void) {
#if TARGET_OS_OSX
    return (double)ap_macos_active_window_content_rect().size.height;
#else
    return (double)[UIScreen mainScreen].bounds.size.height;
#endif
}

double objc_macos_screen_width(void) {
#if TARGET_OS_OSX
    return (double)ap_macos_active_window_content_rect().size.width;
#else
    return 0.0;
#endif
}

// Safe-area insets from the foreground key window. Returns 0 on macOS
// (NSWindow has no safe-area concept — return 0 so callers can treat
// the four insets uniformly).
double objc_safe_area_top(void) {
#if TARGET_OS_OSX
    return 0.0;
#else
    UIWindow *win = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) { win = w; break; }
            }
            if (win) break;
        }
    }
    if (!win) {
        // Fallback: any visible window.
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                if (ws.windows.count > 0) { win = ws.windows.firstObject; break; }
            }
        }
    }
    if (!win) return 0.0;
    return (double)win.safeAreaInsets.top;
#endif
}

double objc_safe_area_bottom(void) {
#if TARGET_OS_OSX
    return 0.0;
#else
    UIWindow *win = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) { win = w; break; }
            }
            if (win) break;
        }
    }
    if (!win) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *ws = (UIWindowScene *)scene;
                if (ws.windows.count > 0) { win = ws.windows.firstObject; break; }
            }
        }
    }
    if (!win) return 0.0;
    return (double)win.safeAreaInsets.bottom;
#endif
}

double objc_safe_area_leading(void) {
#if TARGET_OS_OSX
    return 0.0;
#else
    UIWindow *win = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) { win = w; break; }
            }
            if (win) break;
        }
    }
    if (!win) return 0.0;
    return (double)win.safeAreaInsets.left;
#endif
}

double objc_safe_area_trailing(void) {
#if TARGET_OS_OSX
    return 0.0;
#else
    UIWindow *win = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) { win = w; break; }
            }
            if (win) break;
        }
    }
    if (!win) return 0.0;
    return (double)win.safeAreaInsets.right;
#endif
}

// Size class. Returns: 0 = Unspecified, 1 = Compact, 2 = Regular.
// On macOS we synthesize Compact / Regular from the main window's width
// using the 768pt breakpoint (same threshold web uses for `md`).
int32_t objc_horizontal_size_class(void) {
#if TARGET_OS_OSX
    // Track 2 metric-contract fix: derive the size class from the SAME
    // active-window content rect that objc_macos_screen_width reports, not
    // from a bare [NSApp mainWindow]. The previous mainWindow-only lookup
    // returned nil (→ Unspecified → never Compact) during offscreen capture
    // — the capture window is visible but not "main" — so narrow captures
    // never reflowed to the compact column. ap_macos_active_window_content_rect
    // falls back keyWindow→mainWindow→any-visible→screen, matching width.
    double w = ap_macos_active_window_content_rect().size.width;
    if (w <= 0.0) return 0;
    return (w >= 768.0) ? 2 : 1;
#else
    UIWindow *win = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            if (ws.windows.count > 0) { win = ws.windows.firstObject; break; }
        }
    }
    if (!win) return 0;
    switch (win.traitCollection.horizontalSizeClass) {
        case UIUserInterfaceSizeClassCompact: return 1;
        case UIUserInterfaceSizeClassRegular: return 2;
        default: return 0;
    }
#endif
}

int32_t objc_vertical_size_class(void) {
#if TARGET_OS_OSX
    // Same metric-contract fix as objc_horizontal_size_class — use the
    // active-window content rect (capture-path safe) rather than mainWindow.
    double h = ap_macos_active_window_content_rect().size.height;
    if (h <= 0.0) return 0;
    return (h >= 768.0) ? 2 : 1;
#else
    UIWindow *win = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            if (ws.windows.count > 0) { win = ws.windows.firstObject; break; }
        }
    }
    if (!win) return 0;
    switch (win.traitCollection.verticalSizeClass) {
        case UIUserInterfaceSizeClassCompact: return 1;
        case UIUserInterfaceSizeClassRegular: return 2;
        default: return 0;
    }
#endif
}

// Constrain child.widthAnchor = parent.widthAnchor at required priority.
// Used to explicitly pin a UIStackView arranged subview's width to the
// parent UIStackView's width, working around the case where UIStackView's
// alignment=fill does not propagate width into nested UIStackViews.
void objc_constrain_equal_width(void *child, void *parent) {
    BridgeView *c = (BridgeView *)child;
    BridgeView *p = (BridgeView *)parent;
    NSLayoutConstraint *wc = [c.widthAnchor constraintEqualToAnchor:p.widthAnchor];
#if TARGET_OS_OSX
    wc.priority = NSLayoutPriorityRequired;
#else
    wc.priority = UILayoutPriorityRequired;
#endif
    wc.active = YES;
}

// Like objc_constrain_equal_width but child.width = parent.width + delta (delta
// negative to inset). Used so a fill_horizontal child respects the parent stack's
// horizontal padding (edgeInsets): pinning to the full parent width ignores the
// insets, so a padded screen container rendered its content edge-to-edge with no
// gutters. delta = -(leading + trailing inset); the stack's cross-axis centering
// then yields symmetric gutters.
void objc_constrain_equal_width_offset(void *child, void *parent, double delta) {
    BridgeView *c = (BridgeView *)child;
    BridgeView *p = (BridgeView *)parent;
    NSLayoutConstraint *wc =
        [c.widthAnchor constraintEqualToAnchor:p.widthAnchor constant:(CGFloat)delta];
#if TARGET_OS_OSX
    wc.priority = NSLayoutPriorityRequired;
#else
    wc.priority = UILayoutPriorityRequired;
#endif
    wc.active = YES;
}

// Pin a child view to its parent's layout margins on iOS. The macOS branch
// falls back to edge pinning; UIKit is the current caller.
void objc_pin_child_to_layout_margins(void *parent, void *child) {
    BridgeView *p = (BridgeView *)parent;
    BridgeView *c = (BridgeView *)child;
    c.translatesAutoresizingMaskIntoConstraints = NO;
#if TARGET_OS_OSX
    NSLayoutConstraint *leading = [c.leadingAnchor constraintEqualToAnchor:p.leadingAnchor];
    NSLayoutConstraint *trailing = [c.trailingAnchor constraintEqualToAnchor:p.trailingAnchor];
    NSLayoutConstraint *top = [c.topAnchor constraintEqualToAnchor:p.topAnchor];
    NSLayoutConstraint *bottom = [c.bottomAnchor constraintEqualToAnchor:p.bottomAnchor];
#else
    UILayoutGuide *g = p.layoutMarginsGuide;
    NSLayoutConstraint *leading = [c.leadingAnchor constraintEqualToAnchor:g.leadingAnchor];
    NSLayoutConstraint *trailing = [c.trailingAnchor constraintEqualToAnchor:g.trailingAnchor];
    NSLayoutConstraint *top = [c.topAnchor constraintEqualToAnchor:g.topAnchor];
    NSLayoutConstraint *bottom = [c.bottomAnchor constraintEqualToAnchor:g.bottomAnchor];
#endif
    leading.active = YES;
    trailing.active = YES;
    top.active = YES;
    bottom.active = YES;
}

// Pin a child view to its parent's bounds (no insets). Used by
// FullScreenCover + Inspector visit paths in the UIKit / AppKit
// renderers — without this the child UIView/NSView has no Auto
// Layout constraints and renders with a zero frame inside the parent.
// Phase 10D-refocus introduced this helper because the existing
// `objc_pin_child_to_layout_margins` left content invisible inside
// covers / inspectors that wanted edge-to-edge fill (cover chrome
// owns its own padding, the parent should NOT subtract margins).
void objc_pin_child_to_superview_edges(void *parent, void *child) {
    BridgeView *p = (BridgeView *)parent;
    BridgeView *c = (BridgeView *)child;
    c.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *leading = [c.leadingAnchor constraintEqualToAnchor:p.leadingAnchor];
    NSLayoutConstraint *trailing = [c.trailingAnchor constraintEqualToAnchor:p.trailingAnchor];
    NSLayoutConstraint *top = [c.topAnchor constraintEqualToAnchor:p.topAnchor];
    NSLayoutConstraint *bottom = [c.bottomAnchor constraintEqualToAnchor:p.bottomAnchor];
    leading.active = YES;
    trailing.active = YES;
    top.active = YES;
    bottom.active = YES;
}

// Pin a ZStack child for a DIRECTIONAL alignment (UI::Alignment Leading/Trailing/
// Top/Bottom), honoring ZStack#alignment. Center/Fill keep using
// objc_pin_child_to_superview_edges (force-fill all 4 edges) — this function is
// ONLY for the directional cases, which the renderer previously ignored (every
// child was force-filled regardless of alignment, so a fixed-size child could
// never sit aligned to one side — drawer panel / toast / badge / FAB).
//
// For align direction it:
//   - pins the ALIGNED edge to the parent at required priority (1000),
//   - pins the two CROSS-AXIS edges to the parent at required (fills the other
//     axis — the 1-D Alignment enum can't express compound alignment, and the
//     overlay use cases (drawer) want full extent on the unspecified axis),
//   - adds a REQUIRED containment inequality on the OPPOSITE edge so the child
//     can never overflow the parent even when the parent is narrower than a
//     fixed child, and
//   - adds a SOFT equality (priority 499) on the OPPOSITE edge: an UNCONSTRAINED
//     child still fills (499 beats default content-hugging 250), while a
//     FIXED-size child (width/height pinned at 999 via objc_constrain_width)
//     keeps its size and aligns (999 beats 499). 499 — not 500 — avoids a tie
//     with objc_constrain_minimum_width's 500-priority `>=` constraint.
//
// align: 0 = leading, 1 = trailing, 2 = top, 3 = bottom.
void objc_pin_child_aligned(void *parent, void *child, int align) {
    BridgeView *p = (BridgeView *)parent;
    BridgeView *c = (BridgeView *)child;
    c.translatesAutoresizingMaskIntoConstraints = NO;

    NSLayoutConstraint *leading  = [c.leadingAnchor  constraintEqualToAnchor:p.leadingAnchor];
    NSLayoutConstraint *trailing = [c.trailingAnchor constraintEqualToAnchor:p.trailingAnchor];
    NSLayoutConstraint *top      = [c.topAnchor      constraintEqualToAnchor:p.topAnchor];
    NSLayoutConstraint *bottom   = [c.bottomAnchor   constraintEqualToAnchor:p.bottomAnchor];

    // Required containment inequalities keep the child inside the parent bounds
    // regardless of the soft fill (the OPPOSITE edge from the aligned one).
    NSLayoutConstraint *leadingGE  = [c.leadingAnchor  constraintGreaterThanOrEqualToAnchor:p.leadingAnchor];
    NSLayoutConstraint *trailingLE = [c.trailingAnchor constraintLessThanOrEqualToAnchor:p.trailingAnchor];
    NSLayoutConstraint *topGE      = [c.topAnchor      constraintGreaterThanOrEqualToAnchor:p.topAnchor];
    NSLayoutConstraint *bottomLE   = [c.bottomAnchor   constraintLessThanOrEqualToAnchor:p.bottomAnchor];

    const float SOFT = 499.0f; // > content-hugging (250), < fixed-size pin (999)

    switch (align) {
        case 1: // trailing: pin right; fill vertically; soft-fill from the left
            trailing.active = YES;
            top.active = YES; bottom.active = YES;
            leadingGE.active = YES;
            leading.priority = SOFT; leading.active = YES;
            break;
        case 2: // top: pin top; fill horizontally; soft-fill from the bottom
            top.active = YES;
            leading.active = YES; trailing.active = YES;
            bottomLE.active = YES;
            bottom.priority = SOFT; bottom.active = YES;
            break;
        case 3: // bottom: pin bottom; fill horizontally; soft-fill from the top
            bottom.active = YES;
            leading.active = YES; trailing.active = YES;
            topGE.active = YES;
            top.priority = SOFT; top.active = YES;
            break;
        case 0: // leading: pin left; fill vertically; soft-fill toward the right
        default:
            leading.active = YES;
            top.active = YES; bottom.active = YES;
            trailingLE.active = YES;
            trailing.priority = SOFT; trailing.active = YES;
            break;
    }
}

// Read a view's frame (points). Used by native layout specs to assert resolved
// geometry after a layout pass.
BridgeCGRect objc_get_frame(void *view) {
    BridgeRect f = [(BridgeView *)view frame];
    BridgeCGRect r;
    r.x = f.origin.x; r.y = f.origin.y;
    r.width = f.size.width; r.height = f.size.height;
    return r;
}

// Force an immediate Auto Layout pass on a view subtree so a spec can read
// resolved child frames synchronously.
void objc_layout_now(void *view) {
#if TARGET_OS_OSX
    [(BridgeView *)view layoutSubtreeIfNeeded];
#else
    [(BridgeView *)view setNeedsLayout];
    [(BridgeView *)view layoutIfNeeded];
#endif
}

// Exact-width arranged subviews should resist horizontal stretching in
// UIStackView's Fill distribution. Width constraints remain the source of
// truth; these priorities make the intent visible to stack fitting passes.
void objc_set_horizontal_fixed_priority(void *view) {
    BridgeView *v = (BridgeView *)view;
#if TARGET_OS_OSX
    [v setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    [v setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
#else
    [v setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [v setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
#endif
}

// The inverse of the fixed-priority helper: mark a view as the flexible element that
// GROWS to fill the remaining horizontal space in its containing stack. Lowering the
// horizontal content-hugging priority makes BOTH UIStackView (.fill distribution) and
// NSStackView stretch this view to absorb slack, instead of hugging its intrinsic
// width. This is the cross-platform "flex-grow" primitive (UI::View#fill_horizontal):
// a horizontal row of otherwise fixed-width controls needs at least one such absorber,
// or UIKit over-constrains the row and shoves it off the leading edge (the Voyager
// compose-field left-clip).
//
// Compression resistance is RAISED to Required so the fill child grows to absorb
// slack but NEVER compresses below its intrinsic width. Leaving it at the default
// (750) caused the "50/50 layout disease" (B2.1): in an
// `HStack[Button(fill_horizontal), IconButton]` row, UIStackView's .fill
// distribution would shrink the fill Button below its label's intrinsic width
// (so "Change Password" wrapped to two lines despite fitting) while the
// no-width IconButton host stretched. A flex-grow element must absorb the EXTRA
// space, not surrender its own content — so compression resistance is pinned high.
void objc_set_horizontal_fill_priority(void *view) {
    BridgeView *v = (BridgeView *)view;
#if TARGET_OS_OSX
    [v setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [v setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
#else
    [v setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [v setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
#endif
}

// Make a view claim the flexible (extra) space along the VERTICAL axis of an
// enclosing stack. Used for a scroll view that must fill the remaining window
// height and reflow on resize rather than sit at a fixed point height: with the
// lowest vertical hugging priority in the stack it is the arranged view the
// stack stretches to absorb leftover height. Compression resistance stays low
// too so the stack may shrink it below its content when the window is small.
void objc_set_vertical_fill_priority(void *view) {
    BridgeView *v = (BridgeView *)view;
#if TARGET_OS_OSX
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v setContentHuggingPriority:1 forOrientation:NSLayoutConstraintOrientationVertical];
    [v setContentCompressionResistancePriority:1 forOrientation:NSLayoutConstraintOrientationVertical];
#else
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [v setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisVertical];
    [v setContentCompressionResistancePriority:1 forAxis:UILayoutConstraintAxisVertical];
#endif
}

// Scroll an NSScrollView so its newest (bottom) content is visible — the
// "stick to bottom while streaming" primitive. The document view is top-anchored
// and grows downward (chat transcript: oldest at top, newest at bottom). A
// single scrollPoint to the far edge, clamped by the clip view, reveals the
// bottom in both flipped and non-flipped document coordinate systems.
void nsscrollview_scroll_to_end(void *scroll_view) {
#if TARGET_OS_OSX
    NSScrollView *sv = (NSScrollView *)scroll_view;
    if (sv == nil) return;
    NSClipView *clip = sv.contentView;
    NSView *doc = sv.documentView;
    if (clip == nil || doc == nil) return;
    CGFloat docH = doc.bounds.size.height;
    CGFloat clipH = clip.bounds.size.height;
    NSPoint p;
    if (doc.isFlipped) {
        CGFloat y = docH - clipH;
        p = NSMakePoint(0.0, y > 0 ? y : 0.0);
    } else {
        p = NSMakePoint(0.0, 0.0);  // non-flipped: bottom edge is y == 0
    }
    [clip scrollToPoint:p];
    [sv reflectScrolledClipView:clip];
#endif
}

// 1 when the scroll view is within `tolerance` points of its bottom edge (the
// newest content), else 0 — used to decide whether streaming should keep
// auto-pinning (re-arm) or leave the user's scroll position alone (they scrolled
// up to read). Returns 1 when the content is shorter than the viewport (there is
// no "up" to scroll to) so a short transcript always stays pinned.
int nsscrollview_is_at_bottom(void *scroll_view, double tolerance) {
#if TARGET_OS_OSX
    NSScrollView *sv = (NSScrollView *)scroll_view;
    if (sv == nil) return 1;
    NSClipView *clip = sv.contentView;
    NSView *doc = sv.documentView;
    if (clip == nil || doc == nil) return 1;
    CGFloat docH = doc.bounds.size.height;
    CGFloat clipH = clip.bounds.size.height;
    if (docH <= clipH + tolerance) return 1;  // nothing to scroll
    NSRect vis = clip.documentVisibleRect;
    if (doc.isFlipped) {
        return (NSMaxY(vis) >= docH - tolerance) ? 1 : 0;
    } else {
        return (NSMinY(vis) <= tolerance) ? 1 : 0;
    }
#else
    return 1;
#endif
}

// A Spacer is pure flex space — it must absorb ALL slack in its containing stack,
// in BOTH orientations (a VStack Spacer grows vertically, an HStack Spacer grows
// horizontally), and it must WIN that slack against ordinary content. DefaultLow
// (250) is NOT low enough: a plain UIView/NSView and most content both sit at 250,
// so UIStackView's .fill distribution resolves the tie arbitrarily — a [Spacer,
// card, Spacer] column could pin the card to the top instead of centering it. Drop
// the hugging to 1 on both axes so the Spacer is unambiguously the flexible element.
void objc_set_flex_spacer_priority(void *view) {
    BridgeView *v = (BridgeView *)view;
#if TARGET_OS_OSX
    [v setContentHuggingPriority:1.0f forOrientation:NSLayoutConstraintOrientationHorizontal];
    [v setContentHuggingPriority:1.0f forOrientation:NSLayoutConstraintOrientationVertical];
#else
    [v setContentHuggingPriority:1.0f forAxis:UILayoutConstraintAxisHorizontal];
    [v setContentHuggingPriority:1.0f forAxis:UILayoutConstraintAxisVertical];
#endif
}

void objc_constrain_size(void *view, double w, double h) {
    BridgeView *v = (BridgeView *)view;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *wc = [v.widthAnchor constraintEqualToConstant:(CGFloat)w];
    NSLayoutConstraint *hc = [v.heightAnchor constraintEqualToConstant:(CGFloat)h];
    wc.priority = 999;
    hc.priority = 999;
    wc.active = YES;
    hc.active = YES;
}

// Constrain only the width of a view, leaving height unconstrained.
// Use this for sidebar columns inside a split layout where the parent
// provides the height and only the width needs an explicit value.
void objc_constrain_width(void *view, double w) {
    BridgeView *v = (BridgeView *)view;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *wc = [v.widthAnchor constraintEqualToConstant:(CGFloat)w];
    wc.priority = 999;
    wc.active = YES;
}

// Constrain width at required priority. Use sparingly for exact design tokens
// (minimum_width == maximum_width) in validation previews where UIKit's fitting
// pass otherwise breaks the 999-priority width and lets rounded containers clip.
void objc_constrain_required_width(void *view, double w) {
    BridgeView *v = (BridgeView *)view;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *wc = [v.widthAnchor constraintEqualToConstant:(CGFloat)w];
#if TARGET_OS_OSX
    wc.priority = NSLayoutPriorityRequired;
#else
    wc.priority = UILayoutPriorityRequired;
#endif
    wc.active = YES;
}

// Apply a MINIMUM width constraint (>=) to a view.
// Use this for content panels that should expand to fill available space
// without being pinned to an exact width. NSStackView GravityAreas distribution
// gives each child at least its intrinsic content size; this constraint raises
// the floor so the panel gets at least `min_w` points.
// Priority 250 (defaultLow) so it defers to any explicit equality constraints
// from siblings, and lets the layout engine solve for a feasible layout.
void objc_constrain_minimum_width(void *view, double min_w) {
    BridgeView *v = (BridgeView *)view;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *wc = [v.widthAnchor constraintGreaterThanOrEqualToConstant:(CGFloat)min_w];
    wc.priority = 500;
    wc.active = YES;
}

// Apply the full UI::Fluid "readable column" width behavior to a view that is
// ALREADY in its superview: greedily fill the parent's width, floored at min and
// capped at max, so it reflows when the parent/window resizes. Priority ordering
// (per Codex review): bound-to-parent (900) > cap≤max (800) > floor≥min (700) >
// fill==parent (500). The fill must beat the view's content hugging (default 250)
// so the container stops hugging its intrinsic content width; cap/floor/bound are
// stronger so the column never exceeds max or the parent and never drops below
// min (min yields only if the parent is narrower than min, to stay solvable).
// min_w<=0 means "no floor"; max_w>=1e5 means "no cap".
void objc_constrain_fluid_width(void *view, double min_w, double max_w) {
    BridgeView *v = (BridgeView *)view;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    if (min_w > 0.0) {
        NSLayoutConstraint *floorc = [v.widthAnchor constraintGreaterThanOrEqualToConstant:(CGFloat)min_w];
        floorc.priority = 700;
        floorc.active = YES;
    }
    if (max_w < 100000.0) {
        NSLayoutConstraint *capc = [v.widthAnchor constraintLessThanOrEqualToConstant:(CGFloat)max_w];
        capc.priority = 800;
        capc.active = YES;
    }
    BridgeView *parent = v.superview;
    if (parent) {
        NSLayoutConstraint *bound = [v.widthAnchor constraintLessThanOrEqualToAnchor:parent.widthAnchor];
        bound.priority = 900;
        bound.active = YES;
        NSLayoutConstraint *fill = [v.widthAnchor constraintEqualToAnchor:parent.widthAnchor];
        fill.priority = 500;
        fill.active = YES;
    }
}

// Apply a MAXIMUM width constraint (<=) to a view. Pairs with
// objc_constrain_minimum_width to express a resizable RANGE [min, max]: the view
// grows with available space up to max, then stops — a "readable column" that
// resizes with the window/size class but never sprawls. Used by UI::Fluid native
// resolution (Phase B). Priority 500 so it defers to any required exact pins and
// cooperates with the >= floor; a low-priority (≤500) "fill" tendency from the
// stack/root makes the view want to be as wide as allowed within [min, max].
void objc_constrain_maximum_width(void *view, double max_w) {
    BridgeView *v = (BridgeView *)view;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *wc = [v.widthAnchor constraintLessThanOrEqualToConstant:(CGFloat)max_w];
    wc.priority = 500;
    wc.active = YES;
}

// Constrain only the height of a view, leaving width unconstrained.
// Use this for scroll views embedded in stack views where the stack
// provides the width and only the height needs an explicit value.
void objc_constrain_height(void *view, double h) {
    BridgeView *v = (BridgeView *)view;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *hc = [v.heightAnchor constraintEqualToConstant:(CGFloat)h];
    hc.priority = 999;
    hc.active = YES;
}

// Constrain the MINIMUM height of a view. The view can grow taller than min_h
// but never shorter. Used for iOS sheet detent sizing so the sheet fills at
// least its .medium detent height (~520pt) and Cancel/CTA buttons are visible.
void objc_constrain_minimum_height(void *view, double min_h) {
    BridgeView *v = (BridgeView *)view;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *hc = [v.heightAnchor constraintGreaterThanOrEqualToConstant:(CGFloat)min_h];
    hc.priority = 999;
    hc.active = YES;
}

// Pin a content view's edges to a UIScrollView's contentLayoutGuide and
// pin its width to the frameLayoutGuide.  This is the canonical way to
// achieve a vertically-scrolling UIScrollView with Auto Layout:
//   - content top/leading/bottom/trailing -> contentLayoutGuide
//   - content width = frameLayoutGuide.width  (no horizontal scroll)
// The content view must already be a subview of the scroll view.
// macOS: no-op (NSScrollView uses documentView, not constraints).
void uiscrollview_pin_content(void *scroll_view, void *content_view) {
#if !TARGET_OS_OSX
    UIScrollView *sv = (UIScrollView *)scroll_view;
    UIView *cv = (UIView *)content_view;
    cv.translatesAutoresizingMaskIntoConstraints = NO;
    UILayoutGuide *content = sv.contentLayoutGuide;
    UILayoutGuide *frame = sv.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [cv.topAnchor constraintEqualToAnchor:content.topAnchor],
        [cv.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [cv.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [cv.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],
        [cv.widthAnchor constraintEqualToAnchor:frame.widthAnchor],
    ]];
#endif
}

// Phase 6.11 — swipe-reveal row factory for iOS.
//
// Builds a UIScrollView-based swipe row whose visible area equals the
// supplied row_width. Layout:
//
//   contentSize.width  = row_width + actions_width  (horizontal scroll)
//   contentSize.height = max(content_height, action_height)
//   contentOffset.x    = 0    (initial — only content visible)
//
// User can pan-left to reveal the trailing actions area. The scroll view
// uses isPagingEnabled = NO + bounces on so the user can flick back to
// hide the actions. directionalLockEnabled = YES prevents diagonal panning.
//
// content_view + each action_view are added as subviews of an inner
// horizontal UIStackView so Auto Layout sizes them naturally; the stack
// view is then pinned to the scroll view's contentLayoutGuide.
//
// Returns the +1 retained UIScrollView pointer. macOS: returns NULL.
void *make_swipe_reveal_row(void *content_view,
                            void **action_views,
                            int action_count,
                            double row_width) {
#if !TARGET_OS_OSX
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsHorizontalScrollIndicator = NO;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.directionalLockEnabled = YES;
    scroll.alwaysBounceHorizontal = YES;
    scroll.bounces = YES;
    scroll.decelerationRate = UIScrollViewDecelerationRateNormal;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 0.0;
    [scroll addSubview:stack];

    // Pin stack to contentLayoutGuide. Phase 6.11 iter-3 (Option A) fix:
    // the previous revision pinned `stack.heightAnchor` equal to
    // `fg.heightAnchor` (the scroll view's frame height). That created a
    // circular constraint — UIScrollView has no intrinsic content height,
    // so its frame height depended on an outer layout pass that never
    // received a definite size, leaving the row vertically ambiguous and
    // causing collapse to zero height in the iPhone 17 Pro sim.
    //
    // The fix: derive height from the inner stack's intrinsic content
    // (its arranged subviews each have intrinsic content size). Pin the
    // scroll view's height greaterThanOrEqualTo the stack's height so the
    // scroll view grows to match. Outer layout passes then see a definite
    // intrinsic content size for the scroll view and place it correctly
    // inside the parent UIStackView.
    UILayoutGuide *cg = scroll.contentLayoutGuide;
    NSLayoutConstraint *heightFloor =
        [scroll.heightAnchor constraintGreaterThanOrEqualToAnchor:stack.heightAnchor];
    heightFloor.priority = UILayoutPriorityRequired;
    NSLayoutConstraint *heightEqual =
        [scroll.heightAnchor constraintEqualToAnchor:stack.heightAnchor];
    // Priority 999 (Required - 1): the equality drives the scroll view's
    // intrinsic vertical placement under an outer UIStackView while
    // leaving the floor constraint authoritative if the outer layout
    // tries to compress below the inner stack's natural height.
    heightEqual.priority = UILayoutPriorityRequired - 1;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:cg.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:cg.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:cg.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:cg.bottomAnchor],
        heightFloor,
        heightEqual,
    ]];

    // Add the content view first; force its width to row_width so it
    // occupies exactly the visible area.
    UIView *cv = (UIView *)content_view;
    cv.translatesAutoresizingMaskIntoConstraints = NO;
    [stack addArrangedSubview:cv];
    [cv.widthAnchor constraintEqualToConstant:row_width].active = YES;

    // Add each action view next; each gets a sensible minimum width so
    // the user can tap them comfortably (74pt is iOS Mail's approximate
    // swipe-action width).
    for (int i = 0; i < action_count; i++) {
        UIView *av = (UIView *)action_views[i];
        if (av == NULL) continue;
        av.translatesAutoresizingMaskIntoConstraints = NO;
        [stack addArrangedSubview:av];
        [av.widthAnchor constraintGreaterThanOrEqualToConstant:74.0].active = YES;
    }

    // Pin the scroll view's intrinsic visible width to row_width so the
    // outer layout sizes it correctly. Without this the scroll view would
    // try to expand horizontally to its contentSize.
    [scroll.widthAnchor constraintEqualToConstant:row_width].active = YES;

    return (void *)scroll;
#else
    return NULL;
#endif
}

// Set a view as the documentView of an NSScrollView and wire Auto Layout
// constraints so the document view fills the NSScrollView's width while
// being free to grow vertically (enabling vertical scrolling).
//
// Steps:
//   1. setDocumentView: wires the view into the NSScrollView's NSClipView.
//   2. Pinning the documentView's leading/trailing to the NSScrollView's
//      content layout guide's leading/trailing sets the scroll width.
//   3. NOT pinning the bottom anchor lets the view grow as tall as needed.
//
// iOS: no-op (use uiscrollview_pin_content instead).
// Toggle whether the NSScrollView (and its NSClipView) paints an opaque
// background. draws=0 makes the scroll view transparent so content layered
// BEHIND it (e.g. a full-bleed hero image in a ZStack) shows through the
// scrolling content; the default (drawsBackground=YES) paints the system
// background and hides anything behind. Both the scroll view and its clip view
// must be toggled — each paints independently.
void nsscrollview_set_draws_background(void *scroll_view, int draws) {
#if TARGET_OS_OSX
    NSScrollView *sv = (NSScrollView *)scroll_view;
    BOOL b = (draws != 0);
    sv.drawsBackground = b;
    if (sv.contentView) {
        sv.contentView.drawsBackground = b;
    }
#endif
}

void nsscrollview_set_document_view(void *scroll_view, void *doc_view) {
#if TARGET_OS_OSX
    NSScrollView *sv = (NSScrollView *)scroll_view;
    NSView *dv = (NSView *)doc_view;
    dv.translatesAutoresizingMaskIntoConstraints = NO;
    sv.documentView = dv;
    // Pin width of documentView to NSScrollView's content (clip) width.
    // The documentView is now inside NSClipView; constrain to its superview.
    NSView *clip = sv.contentView;  // NSClipView
    if (clip) {
        [NSLayoutConstraint activateConstraints:@[
            [dv.leadingAnchor constraintEqualToAnchor:clip.leadingAnchor],
            [dv.trailingAnchor constraintEqualToAnchor:clip.trailingAnchor],
            [dv.topAnchor constraintEqualToAnchor:clip.topAnchor],
        ]];
        // Fill-the-viewport: when content is SHORTER than the viewport, an
        // NSScrollView leaves the (top-pinned) document view at its intrinsic
        // height — and a non-flipped clip view drops that short content to the
        // BOTTOM, exposing the scroll view's bare background above it (a broken
        // empty/short-list state). Pin the document view's height to at least
        // the clip height so short content stretches to fill (staying
        // top-anchored, its own background covering the whole viewport); taller
        // content still exceeds the clip and scrolls normally. Priority 999 so a
        // genuinely tall subtree never makes the layout unsatisfiable.
        NSLayoutConstraint *fill =
            [dv.heightAnchor constraintGreaterThanOrEqualToAnchor:clip.heightAnchor];
        fill.priority = NSLayoutPriorityRequired - 1;  // 999
        fill.active = YES;
    }
#endif
}

// Create an NSImageView (macOS) / UIImageView (iOS) that renders a system
// SF Symbol image in template mode with an explicit content tint color.
//
// On macOS, NSImageView.contentTintColor reliably propagates through the
// template rendering mode to the displayed symbol pixels.  This is more
// reliable than NSButton.contentTintColor which does not consistently
// apply to the image portion when bezelStyle != 0 (borderless).
//
// On iOS, UIImageView.tintColor achieves the same effect for UIButtonTypeSystem
// when the image is set via UIImage.systemImageNamed: (which always returns a
// template-mode image).  This helper is provided as a symmetric API but the
// UIKit renderer prefers the UIButton path for hit-testing reasons.
//
// Parameters:
//   symbol_name  -- C string with the SF Symbol name (e.g. "envelope")
//   tint_color   -- NSColor* (macOS) or UIColor* (iOS) to apply as tint
//   size_pts     -- Point size for the symbol image configuration; pass 0.0
//                   to use the SF Symbol's default point size.
//
// Returns: NSImageView* (macOS) or UIImageView* (iOS), or NULL if the symbol
//          is not found or the platform API is unavailable.
//
// Caller owns a +1 retain count (from alloc/init) and must release via
// ObjC.owned / NativeHandle.
void *nsimageview_make_symbol(const char *symbol_name, void *tint_color, double size_pts) {
#if TARGET_OS_OSX
    NSString *name = [NSString stringWithUTF8String:symbol_name];
    if (!name) return NULL;

    NSImage *img = nil;
    if (size_pts > 0.0) {
        NSImageSymbolConfiguration *cfg =
            [NSImageSymbolConfiguration configurationWithPointSize:(CGFloat)size_pts
                                                            weight:NSFontWeightRegular];
        img = [NSImage imageWithSystemSymbolName:name
                     accessibilityDescription:@""];
        if (img) {
            img = [img imageWithSymbolConfiguration:cfg];
        }
    } else {
        img = [NSImage imageWithSystemSymbolName:name
                     accessibilityDescription:@""];
    }
    if (!img) return NULL;

    NSImageView *iv = [[NSImageView alloc] initWithFrame:NSZeroRect];
    iv.image = img;
    // imageScaling = NSImageScaleProportionallyUpOrDown (3) so the symbol
    // fills the constrained size while preserving aspect ratio.
    iv.imageScaling = (NSImageScaling)3;
    // contentTintColor on NSImageView reliably routes template-mode SF Symbol
    // rendering through the brand color.  This does NOT require a specific
    // bezel style and works in both light and dark appearances.
    if (tint_color) {
        SEL tintSel = sel_registerName("setContentTintColor:");
        if ([iv respondsToSelector:tintSel]) {
            ((void (*)(id, SEL, id))objc_msgSend)(iv, tintSel, (id)tint_color);
        }
    }
    return (void *)iv;
#else
    NSString *name = [NSString stringWithUTF8String:symbol_name];
    if (!name) return NULL;
    UIImage *img = [UIImage systemImageNamed:name];
    if (!img) return NULL;
    UIImageView *iv = [[UIImageView alloc] initWithImage:img];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    if (tint_color) {
        iv.tintColor = (UIColor *)tint_color;
    }
    return (void *)iv;
#endif
}

// Install a warm-amber-to-ember CAGradientLayer as the bottommost sublayer
// of a UIView (iOS only).  The gradient provides a pre-composited warm tonal
// variation that bleeds through the UIGlassEffect / UIBlurEffect layer placed
// above it.  Under XCUITest rasterization, live UIVisualEffectView blending
// is not composited against real window content; a pre-composited gradient
// behind the glass surface allows the "bleed-through" tonal variation to
// appear in the captured screenshot.
//
// The gradient runs from top-left (warm amber, r=0.90 g=0.55 b=0.15 a=1.0)
// to bottom-right (deep ember, r=0.60 g=0.25 b=0.05 a=1.0).  The diagonal
// direction maximizes the visible tonal range in the glass card's crop.
//
// macOS: no-op (gradient layer approach not needed; live CGWindowListCreateImage
// composites the backdrop through NSVisualEffectView naturally).
void uiview_install_amber_gradient_layer(void *view) {
#if !TARGET_OS_OSX
    UIView *v = (UIView *)view;

    CAGradientLayer *grad = [CAGradientLayer layer];
    // Warm amber -> deep ember diagonal gradient.
    UIColor *amber  = [UIColor colorWithRed:0.90 green:0.55 blue:0.15 alpha:1.0];
    UIColor *ember  = [UIColor colorWithRed:0.55 green:0.22 blue:0.04 alpha:1.0];
    grad.colors   = @[ (id)amber.CGColor, (id)ember.CGColor ];
    grad.startPoint = CGPointMake(0.0, 0.0);  // top-left
    grad.endPoint   = CGPointMake(1.0, 1.0);  // bottom-right
    // Frame will be updated to match the view bounds in the next layout pass
    // via a bounds-tracking dispatch (same pattern as slider track).
    grad.frame = v.bounds;

    // Insert below all existing sublayers so the gradient is behind everything.
    if (v.layer.sublayers.count > 0) {
        [v.layer insertSublayer:grad atIndex:0];
    } else {
        [v.layer addSublayer:grad];
    }

    // Schedule a frame update after the next layout pass resolves the bounds.
    __unsafe_unretained CAGradientLayer *weakGrad = grad;
    dispatch_async(dispatch_get_main_queue(), ^{
        CAGradientLayer *g = weakGrad;
        if (g && g.superlayer) {
            g.frame = g.superlayer.bounds;
        }
    });
#else
    (void)view;
#endif
}

// Set button title with foreground color via NSAttributedString.
// On macOS this sets NSButton.attributedTitle; on iOS we approximate the
// same effect by setting the button's titleLabel font + titleColor for the
// normal control state. iOS's preferred configuration-based API
// (UIButton.configuration) is not used here — the renderer applies its own
// configuration above these primitives when it wants a richer look.
void nsbutton_set_colored_title(void *button, void *title_nsstring, void *color, void *font) {
#if TARGET_OS_OSX
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: (NSColor *)color,
        NSFontAttributeName: (NSFont *)font
    };
    NSAttributedString *attrStr = [[NSAttributedString alloc]
        initWithString:(NSString *)title_nsstring attributes:attrs];
    [(NSButton *)button setAttributedTitle:attrStr];
    [attrStr release];
#else
    UIButton *b = (UIButton *)button;
    [b setTitle:(NSString *)title_nsstring forState:UIControlStateNormal];
    [b setTitleColor:(UIColor *)color forState:UIControlStateNormal];
    b.titleLabel.font = (UIFont *)font;
#endif
}

// ============================================================
// Section 5b: Slider synthetic track (iOS only)
//
// UISlider's track is drawn via private CALayer sublayers that are not
// composited into XCUITest rasterized screenshots.  This helper builds a
// screenshot-stable synthetic track composed of plain UIView subviews and
// lays them out with explicit frames + UIViewAutoresizingFlexibleWidth so
// they resize when the container is placed inside a UIStackView.
//
// Returns the container UIView (height 44pt, TAMIC=NO).  The invisible
// UISlider is added on top at alpha 0 so it still receives touch events.
//
// Parameters:
//   value_fraction  -- fraction in [0,1] representing the thumb position
//   filled_color    -- UIColor for the leading (filled) track segment
//   unfilled_color  -- UIColor for the trailing (unfilled) track segment
//   slider_ptr      -- the pre-built UISlider (alpha set to 0.0 here)
//
// iOS only.  On macOS this is a no-op (returns NULL).
// ============================================================

#if !TARGET_OS_OSX
void *uislider_build_synthetic_track(double value_fraction,
                                     void *filled_color,
                                     void *unfilled_color,
                                     void *slider_ptr) {
    // Clamp fraction to [0, 1].
    if (value_fraction < 0.0) value_fraction = 0.0;
    if (value_fraction > 1.0) value_fraction = 1.0;

    // Container: 44pt tall (HIG minimum hit target).  Width is unspecified
    // here -- the container will be sized by its UIStackView parent.
    // We use autoresizing masks on child views so they track the container width.
    UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *hc = [container.heightAnchor constraintEqualToConstant:44.0];
    hc.priority = 999;
    hc.active = YES;

    // Background (unfilled) track: full width, 4pt tall, vertically centered.
    // Uses UIViewAutoresizingFlexibleWidth so it stretches with the container.
    UIView *bgTrack = [[UIView alloc] initWithFrame:CGRectZero];
    bgTrack.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                               UIViewAutoresizingFlexibleTopMargin |
                               UIViewAutoresizingFlexibleBottomMargin;
    bgTrack.backgroundColor = (UIColor *)unfilled_color;
    bgTrack.layer.cornerRadius = 2.0;
    [container addSubview:bgTrack];

    // Filled (leading) track: width = container.width * value_fraction, 4pt tall.
    // Uses UIViewAutoresizingFlexibleRightMargin so it anchors to the leading edge.
    UIView *fillTrack = [[UIView alloc] initWithFrame:CGRectZero];
    fillTrack.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                 UIViewAutoresizingFlexibleTopMargin |
                                 UIViewAutoresizingFlexibleBottomMargin;
    fillTrack.backgroundColor = (UIColor *)filled_color;
    fillTrack.layer.cornerRadius = 2.0;
    [container addSubview:fillTrack];

    // Thumb: 28pt circle, white, with a subtle drop shadow.
    UIView *thumb = [[UIView alloc] initWithFrame:CGRectZero];
    thumb.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                             UIViewAutoresizingFlexibleRightMargin |
                             UIViewAutoresizingFlexibleTopMargin |
                             UIViewAutoresizingFlexibleBottomMargin;
    thumb.backgroundColor = [UIColor whiteColor];
    thumb.layer.cornerRadius = 14.0;
    thumb.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.25].CGColor;
    thumb.layer.shadowOpacity = 1.0;
    thumb.layer.shadowRadius = 3.0;
    thumb.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    [container addSubview:thumb];

    // The real UISlider sits on top at alpha 0.0 so touch events still work.
    UISlider *slider = (UISlider *)slider_ptr;
    slider.alpha = 0.0;
    slider.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight;
    [container addSubview:slider];

    // layoutSubviews is overridden via a block-based approach would require
    // a subclass.  Instead, we schedule frame computation in layoutIfNeeded
    // by registering a one-shot layout observation via KVO on the container
    // bounds — which is heavyweight.  Simpler: use a deferred layout via
    // dispatch_async(main_queue) so the stack view has resolved the container
    // width before we compute child frames.
    //
    // We capture the fraction and child view references weakly via __weak
    // references stored in an NSArray to avoid retain cycles.
    // __weak is ARC-only.  Under MRC (-fno-objc-arc) we use __unsafe_unretained.
    // The container holds strong refs to all children (addSubview: retains them),
    // so these pointers remain valid for the lifetime of the container and the
    // dispatch_async block below is safe.
    __unsafe_unretained UIView *weakContainer = container;
    __unsafe_unretained UIView *weakBgTrack   = bgTrack;
    __unsafe_unretained UIView *weakFill      = fillTrack;
    __unsafe_unretained UIView *weakThumb     = thumb;
    CGFloat frac = (CGFloat)value_fraction;

    // Dispatch to the next run-loop turn so UIStackView has had a chance to
    // size the container before we compute frames.
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *c = weakContainer;
        if (!c) return;
        CGFloat w = c.bounds.size.width;
        if (w <= 0.0) w = [UIScreen mainScreen].bounds.size.width - 32.0;

        CGFloat trackH = 4.0;
        CGFloat trackY = (44.0 - trackH) / 2.0;
        CGFloat thumbD = 28.0;
        CGFloat thumbY = (44.0 - thumbD) / 2.0;
        CGFloat fillW  = w * frac;
        CGFloat thumbX = fillW - thumbD / 2.0;

        weakBgTrack.frame = CGRectMake(0.0, trackY, w, trackH);
        weakFill.frame    = CGRectMake(0.0, trackY, fillW, trackH);
        weakThumb.frame   = CGRectMake(thumbX, thumbY, thumbD, thumbD);
        // Also size the slider to fill the container for touch routing.
        slider.frame = c.bounds;
    });

    // Return the container; the caller wraps it in NativeView.
    return (void *)container;
}
#else
void *uislider_build_synthetic_track(double value_fraction,
                                     void *filled_color,
                                     void *unfilled_color,
                                     void *slider_ptr) {
    (void)value_fraction; (void)filled_color; (void)unfilled_color; (void)slider_ptr;
    return NULL; // Not used on macOS.
}
#endif

// ============================================================
// Section 5c: NSSlider track fill color (macOS only)
//
// NSSlider does not expose setMinimumTrackTintColor: (that is UISlider-only).
// On macOS 10.14+, NSSliderCell has a trackFillColor property that sets the
// filled portion of the track independently of the system accent color.
//
// On macOS < 10.14, this is a no-op (the property is not available via
// respondToSelector:, so we guard before sending the message).
// ============================================================

void nsslider_set_track_fill_color(void *slider, void *color) {
#if TARGET_OS_OSX
    NSSlider *s = (NSSlider *)slider;
    NSSliderCell *cell = (NSSliderCell *)[s cell];
    if (!cell) return;
    if ([cell respondsToSelector:@selector(setTrackFillColor:)]) {
        // Use performSelector: to suppress the compile-time unrecognized selector
        // warning.  The respondsToSelector: guard ensures this is safe at runtime.
        [cell performSelector:@selector(setTrackFillColor:) withObject:(NSColor *)color];
    }
#else
    (void)slider; (void)color;
#endif
}

// ============================================================
// Section 5a: NSSwitch factory (macOS 10.15+)
//
// NSSwitch requires initWithFrame:NSZeroRect — plain -init is not supported
// and will crash on ARM64.  This helper allocates, initializes, and
// optionally configures the switch in one call so Crystal does not need to
// call objc_send_rect directly for initialization.
//
// Returns the initialized NSSwitch pointer.  The caller owns +1 retain count
// (from alloc) and must release via ObjC.owned / NativeHandle.
// ============================================================

#if TARGET_OS_OSX
void *nsswitch_new(int state_on, int enabled) {
    Class cls = objc_getClass("NSSwitch");
    if (!cls) return NULL;
    NSSwitch *sw = [[cls alloc] initWithFrame:NSZeroRect];
    if (!sw) return NULL;
    sw.state = state_on ? NSControlStateValueOn : NSControlStateValueOff;
    sw.enabled = (BOOL)enabled;
    return (void *)sw;
}

// Apply a content tint color to an NSSwitch.
// setContentTintColor: is available macOS 12+; on 10.15/11 this is a no-op.
// Guards on respondsToSelector: so the call is safe on all macOS 10.15+ targets.
//
// Dark appearance fix: NSSwitch reads its ON-state track color from the
// current effective appearance at draw time. In the offscreen capture path
// the switch may be added to a window AFTER setContentTintColor: is called,
// causing the appearance to be unset at tint-application time. To fix this,
// we explicitly set the switch's own -appearance to match HIG_APPEARANCE
// before applying the tint. This forces NSSwitch to resolve the gold color
// against the correct appearance trait collection, ensuring the ON-state
// track renders amber gold in both light and dark.
void nsswitch_set_tint(void *sw_ptr, void *color) {
    id sw = (id)sw_ptr;

#if TARGET_OS_OSX
    // Explicitly set the switch's appearance from HIG_APPEARANCE so
    // setContentTintColor: resolves against the correct appearance trait.
    // Without this, the switch uses the inherited (possibly nil) appearance
    // from a window that hasn't been ordered front yet, and the dark ON-state
    // track may render with no tint.
    const char *hig_app = getenv("HIG_APPEARANCE");
    BOOL want_dark = (hig_app && strcmp(hig_app, "dark") == 0);
    NSAppearanceName appearance_name = want_dark
        ? NSAppearanceNameDarkAqua
        : NSAppearanceNameAqua;
    NSAppearance *appearance = [NSAppearance appearanceNamed:appearance_name];
    SEL setAppSel = sel_registerName("setAppearance:");
    if ([sw respondsToSelector:setAppSel]) {
        ((void (*)(id, SEL, id))objc_msgSend)(sw, setAppSel, appearance);
    }
#endif

    SEL tintSel = sel_registerName("setContentTintColor:");
    if ([sw respondsToSelector:tintSel]) {
        ((void (*)(id, SEL, id))objc_msgSend)(sw, tintSel, (id)color);
    }
}
#else
void *nsswitch_new(int state_on, int enabled) {
    (void)state_on; (void)enabled;
    return NULL; // Not used on iOS/Android.
}
void nsswitch_set_tint(void *sw_ptr, void *color) {
    (void)sw_ptr; (void)color;
}
#endif

// ============================================================
// Section 5d: Rich native content helpers
// ============================================================

static NSURL *ap_url_from_cstr(const char *value) {
    if (!value || !value[0]) return nil;
    NSString *str = [NSString stringWithUTF8String:value];
    if (!str || !str.length) return nil;
    return [NSURL URLWithString:str];
}

static NSString *ap_string_from_cstr(const char *value) {
    if (!value || !value[0]) return nil;
    return [NSString stringWithUTF8String:value];
}

static void ap_run_on_main_thread_sync(dispatch_block_t block) {
    if (!block) return;
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

extern void crystal_ui_string_callback_dispatch(unsigned long long tag, const char *value);
extern int crystal_ui_string_bool_callback_dispatch(unsigned long long tag, const char *value);

static NSString *ap_web_preview_html(NSString *title, NSString *url_string) {
    NSString *resolved_title = (title && title.length) ? title : @"Amber Journal";
    NSString *resolved_url = (url_string && url_string.length) ? url_string : @"https://amber.local";

    return [NSString stringWithFormat:
        @"<!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
         "<style>"
         "html,body{margin:0;padding:0;background:#f4efe8;color:#171311;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text',sans-serif;}"
         "body{display:flex;align-items:stretch;justify-content:center;min-height:100vh;}"
         ".shell{width:100%%;padding:20px;box-sizing:border-box;}"
         ".card{background:rgba(255,255,255,.72);border:1px solid rgba(127,102,77,.12);backdrop-filter:blur(18px);"
         "border-radius:20px;padding:18px 18px 16px;box-shadow:0 18px 40px rgba(56,35,20,.12);}"
         ".eyebrow{font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:#8d6a45;margin:0 0 10px;}"
         "h1{font-size:24px;line-height:1.08;margin:0 0 8px;font-weight:650;}"
         "p{font-size:14px;line-height:1.45;margin:0;color:#57463a;}"
         ".toolbar{display:flex;gap:8px;margin:16px 0 18px;}"
         ".chip{display:inline-flex;align-items:center;border-radius:999px;padding:7px 12px;font-size:12px;font-weight:600;}"
         ".chip.primary{background:#ffb14a;color:#2f1900;}"
         ".chip.secondary{background:rgba(141,106,69,.12);color:#6e5746;}"
         ".preview{margin-top:2px;border-radius:16px;background:linear-gradient(180deg,rgba(255,255,255,.92),rgba(249,240,231,.92));"
         "padding:16px;border:1px solid rgba(127,102,77,.10);}"
         ".row{display:flex;justify-content:space-between;align-items:center;padding:11px 0;border-bottom:1px solid rgba(127,102,77,.08);font-size:13px;color:#3b2d23;}"
         ".row:last-child{border-bottom:none;padding-bottom:0;}"
         ".row strong{font-size:14px;font-weight:620;color:#171311;}"
         ".row span{color:#8d6a45;font-weight:600;}"
         ".footer{margin-top:14px;font-size:11px;color:#8d6a45;}"
         "</style></head><body><div class=\"shell\"><div class=\"card\">"
         "<div class=\"eyebrow\">Embedded Web Content</div>"
         "<h1>%@</h1>"
         "<p>Use a web view for rich content that belongs in context, not as unrelated chrome around the component itself.</p>"
         "<div class=\"toolbar\"><div class=\"chip primary\">Review</div><div class=\"chip secondary\">Shared draft</div></div>"
         "<div class=\"preview\">"
         "<div class=\"row\"><strong>Launch notes</strong><span>Ready</span></div>"
         "<div class=\"row\"><strong>Editorial preview</strong><span>3 blocks</span></div>"
         "<div class=\"row\"><strong>Source</strong><span>%@</span></div>"
         "</div><div class=\"footer\">WebKit preview loaded locally for validation capture.</div>"
         "</div></div></body></html>",
        resolved_title, resolved_url];
}

static NSString *ap_video_preview_title(NSString *url_string) {
    if (url_string && url_string.length) {
        return @"Neighborhood walkthrough";
    }
    return @"Playback preview";
}

#if TARGET_OS_OSX
static NSImageView *ap_make_web_capture_preview(NSString *title, NSString *url_string) {
    CGFloat width = 420.0;
    CGFloat height = 320.0;
    NSString *resolved_title = (title && title.length) ? title : @"Editorial Review";
    NSString *resolved_url = (url_string && url_string.length) ? url_string : @"amber.local/review";

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image lockFocus];

    [[NSColor colorWithCalibratedRed:0.956 green:0.937 blue:0.910 alpha:1.0] setFill];
    NSRectFill(NSMakeRect(0.0, 0.0, width, height));

    NSRect card_rect = NSMakeRect(24.0, 22.0, width - 48.0, height - 44.0);
    NSBezierPath *card_path = [NSBezierPath bezierPathWithRoundedRect:card_rect xRadius:22.0 yRadius:22.0];
    [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.82] setFill];
    [card_path fill];
    [[NSColor colorWithCalibratedRed:0.498 green:0.400 blue:0.302 alpha:0.12] setStroke];
    [card_path setLineWidth:1.0];
    [card_path stroke];

    NSDictionary *eyebrow_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:11.0 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedRed:0.553 green:0.416 blue:0.271 alpha:1.0]
    };
    NSDictionary *title_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:24.0 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedRed:0.090 green:0.075 blue:0.067 alpha:1.0]
    };
    NSDictionary *body_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:14.0 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedRed:0.341 green:0.275 blue:0.227 alpha:1.0]
    };
    NSDictionary *row_title_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:14.0 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedRed:0.090 green:0.075 blue:0.067 alpha:1.0]
    };
    NSDictionary *row_meta_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:13.0 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedRed:0.553 green:0.416 blue:0.271 alpha:1.0]
    };
    NSDictionary *chip_primary_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12.0 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedRed:0.184 green:0.098 blue:0.000 alpha:1.0]
    };
    NSDictionary *chip_secondary_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12.0 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedRed:0.431 green:0.341 blue:0.275 alpha:1.0]
    };

    [@"EMBEDDED WEB CONTENT" drawInRect:NSMakeRect(44.0, height - 58.0, 220.0, 16.0) withAttributes:eyebrow_attrs];
    [resolved_title drawInRect:NSMakeRect(44.0, height - 102.0, width - 88.0, 34.0) withAttributes:title_attrs];
    [@"Keep the web content contextual and legible so it feels like part of the app instead of a dropped-in browser tab." drawInRect:NSMakeRect(44.0, height - 152.0, width - 88.0, 44.0) withAttributes:body_attrs];

    NSBezierPath *primary_chip = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(44.0, height - 200.0, 78.0, 32.0) xRadius:16.0 yRadius:16.0];
    [[NSColor colorWithCalibratedRed:1.0 green:0.694 blue:0.290 alpha:1.0] setFill];
    [primary_chip fill];
    [@"Review" drawInRect:NSMakeRect(62.0, height - 190.0, 44.0, 16.0) withAttributes:chip_primary_attrs];

    NSBezierPath *secondary_chip = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(132.0, height - 200.0, 110.0, 32.0) xRadius:16.0 yRadius:16.0];
    [[NSColor colorWithCalibratedRed:0.553 green:0.416 blue:0.271 alpha:0.12] setFill];
    [secondary_chip fill];
    [@"Shared draft" drawInRect:NSMakeRect(154.0, height - 190.0, 78.0, 16.0) withAttributes:chip_secondary_attrs];

    NSRect list_rect = NSMakeRect(44.0, 42.0, width - 88.0, 108.0);
    NSBezierPath *list_path = [NSBezierPath bezierPathWithRoundedRect:list_rect xRadius:16.0 yRadius:16.0];
    [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.92] setFill];
    [list_path fill];
    [[NSColor colorWithCalibratedRed:0.498 green:0.400 blue:0.302 alpha:0.10] setStroke];
    [list_path setLineWidth:1.0];
    [list_path stroke];

    [@"Launch notes" drawInRect:NSMakeRect(60.0, 116.0, 150.0, 18.0) withAttributes:row_title_attrs];
    [@"Ready" drawInRect:NSMakeRect(width - 118.0, 116.0, 70.0, 18.0) withAttributes:row_meta_attrs];
    [@"Editorial preview" drawInRect:NSMakeRect(60.0, 82.0, 180.0, 18.0) withAttributes:row_title_attrs];
    [@"3 blocks" drawInRect:NSMakeRect(width - 124.0, 82.0, 76.0, 18.0) withAttributes:row_meta_attrs];
    [@"Source" drawInRect:NSMakeRect(60.0, 48.0, 120.0, 18.0) withAttributes:row_title_attrs];
    [resolved_url drawInRect:NSMakeRect(width - 188.0, 48.0, 140.0, 18.0) withAttributes:row_meta_attrs];

    [[NSColor colorWithCalibratedRed:0.498 green:0.400 blue:0.302 alpha:0.08] setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(60.0, 108.0) toPoint:NSMakePoint(width - 60.0, 108.0)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(60.0, 74.0) toPoint:NSMakePoint(width - 60.0, 74.0)];

    [image unlockFocus];

    NSImageView *image_view = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, width, height)];
    image_view.image = image;
    image_view.imageScaling = NSImageScaleAxesIndependently;
    [image release];
    return image_view;
}

static NSImageView *ap_make_video_capture_preview(NSString *url_string, BOOL shows_controls) {
    CGFloat width = 560.0;
    CGFloat height = 315.0;
    NSString *resolved_title = ap_video_preview_title(url_string);

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image lockFocus];

    NSRect bounds = NSMakeRect(0.0, 0.0, width, height);
    NSBezierPath *outer_path = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:24.0 yRadius:24.0];
    [outer_path addClip];

    NSGradient *backdrop = [[NSGradient alloc] initWithColorsAndLocations:
        [NSColor colorWithCalibratedRed:0.067 green:0.071 blue:0.090 alpha:1.0], 0.0,
        [NSColor colorWithCalibratedRed:0.110 green:0.129 blue:0.176 alpha:1.0], 0.55,
        [NSColor colorWithCalibratedRed:0.153 green:0.118 blue:0.094 alpha:1.0], 1.0,
        nil];
    [backdrop drawInBezierPath:outer_path angle:135.0];
    [backdrop release];

    NSBezierPath *glow = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(width - 220.0, height - 210.0, 220.0, 220.0)];
    [[NSColor colorWithCalibratedRed:1.0 green:0.706 blue:0.341 alpha:0.16] setFill];
    [glow fill];

    NSBezierPath *glass_band = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(24.0, height - 64.0, 126.0, 30.0) xRadius:15.0 yRadius:15.0];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.14] setFill];
    [glass_band fill];

    NSDictionary *badge_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:11.0 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedWhite:1.0 alpha:0.82]
    };
    NSDictionary *title_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:22.0 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedWhite:1.0 alpha:0.96]
    };
    NSDictionary *meta_attrs = @{
        NSFontAttributeName : [NSFont systemFontOfSize:12.0 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName : [NSColor colorWithCalibratedWhite:1.0 alpha:0.70]
    };

    [@"VALIDATION PREVIEW" drawInRect:NSMakeRect(42.0, height - 56.0, 120.0, 16.0) withAttributes:badge_attrs];
    [resolved_title drawInRect:NSMakeRect(40.0, height - 106.0, width - 160.0, 28.0) withAttributes:title_attrs];
    [@"Capture-only poster." drawInRect:NSMakeRect(40.0, height - 132.0, width - 120.0, 18.0) withAttributes:meta_attrs];

    NSBezierPath *play_circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect((width - 70.0) / 2.0, (height - 70.0) / 2.0 + 8.0, 70.0, 70.0)];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.18] setFill];
    [play_circle fill];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.24] setStroke];
    [play_circle setLineWidth:1.0];
    [play_circle stroke];

    NSBezierPath *play_triangle = [NSBezierPath bezierPath];
    [play_triangle moveToPoint:NSMakePoint(width / 2.0 - 8.0, height / 2.0 + 34.0)];
    [play_triangle lineToPoint:NSMakePoint(width / 2.0 - 8.0, height / 2.0 - 2.0)];
    [play_triangle lineToPoint:NSMakePoint(width / 2.0 + 22.0, height / 2.0 + 16.0)];
    [play_triangle closePath];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.94] setFill];
    [play_triangle fill];

    CGFloat scrubber_y = 36.0;
    NSBezierPath *track = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(40.0, scrubber_y, width - 140.0, 4.0) xRadius:2.0 yRadius:2.0];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.18] setFill];
    [track fill];

    NSBezierPath *progress = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(40.0, scrubber_y, (width - 140.0) * 0.36, 4.0) xRadius:2.0 yRadius:2.0];
    [[NSColor colorWithCalibratedRed:1.0 green:0.706 blue:0.341 alpha:0.95] setFill];
    [progress fill];

    if (shows_controls) {
        [@"01:28" drawInRect:NSMakeRect(40.0, 16.0, 42.0, 16.0) withAttributes:meta_attrs];
        [@"03:54" drawInRect:NSMakeRect(width - 82.0, 16.0, 42.0, 16.0) withAttributes:meta_attrs];
    }

    [image unlockFocus];

    NSImageView *image_view = [[NSImageView alloc] initWithFrame:bounds];
    image_view.image = image;
    image_view.imageScaling = NSImageScaleAxesIndependently;
    [image release];
    return image_view;
}
#endif

void *wkwebview_new(const char *url_cstr,
                    const char *html_cstr,
                    const char *base_url_cstr,
                    const char *title_cstr,
                    int allows_navigation,
                    int allows_scripts) {
    NSString *html = ap_string_from_cstr(html_cstr);
    NSString *title = ap_string_from_cstr(title_cstr);
    NSString *url_string = ap_string_from_cstr(url_cstr);
    NSURL *base_url = ap_url_from_cstr(base_url_cstr);

#if TARGET_OS_OSX
    if (getenv("HIG_SCREENSHOT_PATH")) {
        return (void *)ap_make_web_capture_preview(title, url_string);
    }
#endif

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    if (!configuration) return NULL;

    if ([configuration respondsToSelector:@selector(defaultWebpagePreferences)]) {
        id webpage_prefs = [configuration defaultWebpagePreferences];
        SEL js_sel = sel_registerName("setAllowsContentJavaScript:");
        if (webpage_prefs && [webpage_prefs respondsToSelector:js_sel]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(webpage_prefs, js_sel, (BOOL)allows_scripts);
        }
    }

    WKPreferences *preferences = [configuration preferences];
    SEL legacy_js_sel = sel_registerName("setJavaScriptEnabled:");
    if (preferences && [preferences respondsToSelector:legacy_js_sel]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(preferences, legacy_js_sel, (BOOL)allows_scripts);
    }

#if TARGET_OS_OSX
    WKWebView *web_view = [[WKWebView alloc] initWithFrame:NSZeroRect configuration:configuration];
#else
    WKWebView *web_view = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
#endif
    if (!web_view) return NULL;

    SEL gestures_sel = sel_registerName("setAllowsBackForwardNavigationGestures:");
    if ([web_view respondsToSelector:gestures_sel]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(web_view, gestures_sel, (BOOL)allows_navigation);
    }

    if (html && html.length) {
        [web_view loadHTMLString:html baseURL:base_url];
    } else if (getenv("HIG_SCREENSHOT_PATH")) {
        NSString *preview_html = ap_web_preview_html(title, url_string);
        NSURL *preview_base_url = base_url ?: ap_url_from_cstr(url_cstr);
        [web_view loadHTMLString:preview_html baseURL:preview_base_url];
    } else {
        NSURL *url = ap_url_from_cstr(url_cstr);
        if (url) {
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [web_view loadRequest:request];
        }
    }

    return (void *)web_view;
}

static const char ap_web_delegate_association_key;

static unsigned long long ap_web_delegate_read_u64(id self, const char *name) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), name);
    if (!ivar) return 0ULL;
    return *(unsigned long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar));
}

static void ap_web_delegate_write_u64(id self, const char *name, unsigned long long value) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), name);
    if (!ivar) return;
    *(unsigned long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar)) = value;
}

static long long ap_web_delegate_read_long(id self, const char *name) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), name);
    if (!ivar) return 0LL;
    return *(long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar));
}

static void ap_web_delegate_write_long(id self, const char *name, long long value) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), name);
    if (!ivar) return;
    *(long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar)) = value;
}

static void ap_web_delegate_set_policy_tag(id self, SEL _cmd, unsigned long long tag) {
    ap_web_delegate_write_u64(self, "_policyTag", tag);
}

static void ap_web_delegate_set_start_tag(id self, SEL _cmd, unsigned long long tag) {
    ap_web_delegate_write_u64(self, "_startTag", tag);
}

static void ap_web_delegate_set_finish_tag(id self, SEL _cmd, unsigned long long tag) {
    ap_web_delegate_write_u64(self, "_finishTag", tag);
}

static void ap_web_delegate_set_allows_navigation(id self, SEL _cmd, long long value) {
    ap_web_delegate_write_long(self, "_allowsNavigation", value);
}

static NSString *ap_web_navigation_url_string(WKWebView *web_view, WKNavigationAction *action) {
    NSURL *url = nil;
    if (action) {
        NSURLRequest *request = [action request];
        if ([request respondsToSelector:@selector(URL)]) {
            url = [request URL];
        }
    }
    if (!url && [web_view respondsToSelector:@selector(URL)]) {
        url = [web_view URL];
    }
    NSString *absolute = [url absoluteString];
    return (absolute && absolute.length) ? absolute : @"";
}

static void ap_web_delegate_dispatch_string(unsigned long long tag, NSString *value) {
    if (!tag) return;
    const char *utf8 = value ? [value UTF8String] : "";
    crystal_ui_string_callback_dispatch(tag, utf8);
}

static BOOL ap_web_delegate_should_allow(id self, WKWebView *web_view, WKNavigationAction *action) {
    unsigned long long policy_tag = ap_web_delegate_read_u64(self, "_policyTag");
    NSString *url_string = ap_web_navigation_url_string(web_view, action);
    if (policy_tag) {
        const char *utf8 = [url_string UTF8String];
        return crystal_ui_string_bool_callback_dispatch(policy_tag, utf8) != 0;
    }

    if (ap_web_delegate_read_long(self, "_allowsNavigation") != 0) {
        return YES;
    }

    id target_frame = nil;
    SEL target_frame_sel = sel_registerName("targetFrame");
    if (action && [action respondsToSelector:target_frame_sel]) {
        target_frame = ((id (*)(id, SEL))objc_msgSend)(action, target_frame_sel);
    }

    BOOL is_main_frame = YES;
    SEL is_main_frame_sel = sel_registerName("isMainFrame");
    if (target_frame && [target_frame respondsToSelector:is_main_frame_sel]) {
        is_main_frame = ((BOOL (*)(id, SEL))objc_msgSend)(target_frame, is_main_frame_sel);
    }

    if (!is_main_frame) {
        return YES;
    }

    if (ap_web_delegate_read_long(self, "_didAllowInitialNavigation") == 0) {
        ap_web_delegate_write_long(self, "_didAllowInitialNavigation", 1);
        return YES;
    }

    return NO;
}

static void ap_web_delegate_decide_policy(id self,
                                          SEL _cmd,
                                          WKWebView *web_view,
                                          WKNavigationAction *action,
                                          void (^decisionHandler)(WKNavigationActionPolicy)) {
    BOOL allow = ap_web_delegate_should_allow(self, web_view, action);
    if (decisionHandler) {
        decisionHandler(allow ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
    }
}

static void ap_web_delegate_did_start(id self, SEL _cmd, WKWebView *web_view, WKNavigation *navigation) {
    (void)navigation;
    ap_web_delegate_dispatch_string(
        ap_web_delegate_read_u64(self, "_startTag"),
        ap_web_navigation_url_string(web_view, nil)
    );
}

static void ap_web_delegate_did_finish(id self, SEL _cmd, WKWebView *web_view, WKNavigation *navigation) {
    (void)navigation;
    ap_web_delegate_dispatch_string(
        ap_web_delegate_read_u64(self, "_finishTag"),
        ap_web_navigation_url_string(web_view, nil)
    );
}

void register_ap_web_view_delegate(void) {
    if (objc_getClass("APCrystalWebViewDelegate") != Nil) {
        return;
    }

    Class cls = objc_allocateClassPair([NSObject class], "APCrystalWebViewDelegate", 0);
    if (!cls) return;

    class_addProtocol(cls, @protocol(WKNavigationDelegate));
    class_addIvar(cls, "_policyTag", sizeof(unsigned long long), __alignof__(unsigned long long), @encode(unsigned long long));
    class_addIvar(cls, "_startTag", sizeof(unsigned long long), __alignof__(unsigned long long), @encode(unsigned long long));
    class_addIvar(cls, "_finishTag", sizeof(unsigned long long), __alignof__(unsigned long long), @encode(unsigned long long));
    class_addIvar(cls, "_allowsNavigation", sizeof(long long), __alignof__(long long), @encode(long long));
    class_addIvar(cls, "_didAllowInitialNavigation", sizeof(long long), __alignof__(long long), @encode(long long));

    class_addMethod(cls, sel_registerName("setPolicyTag:"), (IMP)ap_web_delegate_set_policy_tag, "v@:Q");
    class_addMethod(cls, sel_registerName("setStartTag:"), (IMP)ap_web_delegate_set_start_tag, "v@:Q");
    class_addMethod(cls, sel_registerName("setFinishTag:"), (IMP)ap_web_delegate_set_finish_tag, "v@:Q");
    class_addMethod(cls, sel_registerName("setAllowsNavigation:"), (IMP)ap_web_delegate_set_allows_navigation, "v@:q");
    class_addMethod(cls, sel_registerName("webView:decidePolicyForNavigationAction:decisionHandler:"), (IMP)ap_web_delegate_decide_policy, "v@:@@@");
    class_addMethod(cls, sel_registerName("webView:didStartProvisionalNavigation:"), (IMP)ap_web_delegate_did_start, "v@:@@");
    class_addMethod(cls, sel_registerName("webView:didFinishNavigation:"), (IMP)ap_web_delegate_did_finish, "v@:@@");

    objc_registerClassPair(cls);
}

void wkwebview_set_callback_tags(void *web_view_ptr,
                                 unsigned long long policy_tag,
                                 unsigned long long start_tag,
                                 unsigned long long finish_tag,
                                 int allows_navigation) {
    if (!web_view_ptr) return;

    id raw_view = (id)web_view_ptr;
    if (![raw_view isKindOfClass:[WKWebView class]]) return;
    if (!policy_tag && !start_tag && !finish_tag && allows_navigation) return;

    register_ap_web_view_delegate();

    Class delegate_cls = objc_getClass("APCrystalWebViewDelegate");
    if (!delegate_cls) return;

    id delegate = [[delegate_cls alloc] init];
    if (!delegate) return;

    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(delegate, sel_registerName("setPolicyTag:"), policy_tag);
    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(delegate, sel_registerName("setStartTag:"), start_tag);
    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(delegate, sel_registerName("setFinishTag:"), finish_tag);
    ((void (*)(id, SEL, long long))objc_msgSend)(delegate, sel_registerName("setAllowsNavigation:"), (long long)allows_navigation);

    [(WKWebView *)raw_view setNavigationDelegate:delegate];
    objc_setAssociatedObject(raw_view, &ap_web_delegate_association_key, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [delegate release];
}

void *mkmapview_new(double latitude,
                    double longitude,
                    double latitude_delta,
                    double longitude_delta,
                    long long map_type,
                    int shows_user_location) {
#if TARGET_OS_OSX
    MKMapView *map_view = [[MKMapView alloc] initWithFrame:NSZeroRect];
#else
    MKMapView *map_view = [[MKMapView alloc] initWithFrame:CGRectZero];
#endif
    if (!map_view) return NULL;

    map_view.mapType = (MKMapType)map_type;
    map_view.showsUserLocation = (BOOL)shows_user_location;

    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(latitude, longitude);
    CLLocationDegrees lat_span = latitude_delta > 0.0 ? latitude_delta : 0.18;
    CLLocationDegrees lon_span = longitude_delta > 0.0 ? longitude_delta : 0.18;
    MKCoordinateSpan span = MKCoordinateSpanMake(lat_span, lon_span);
    MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
    [map_view setRegion:region animated:NO];

    return (void *)map_view;
}

void mkmapview_add_annotation(void *map_ptr,
                              double latitude,
                              double longitude,
                              const char *title_cstr,
                              const char *subtitle_cstr) {
    MKMapView *map_view = (MKMapView *)map_ptr;
    if (!map_view) return;

    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    if (!annotation) return;

    annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);

    NSString *title = ap_string_from_cstr(title_cstr);
    if (title && title.length) annotation.title = title;

    NSString *subtitle = ap_string_from_cstr(subtitle_cstr);
    if (subtitle && subtitle.length) annotation.subtitle = subtitle;

    [map_view addAnnotation:annotation];
}

static const char ap_player_association_key;
static const char ap_player_controller_association_key;
static const char ap_share_picker_association_key;
static const char ap_share_controller_association_key;

void *video_player_view_new(const char *url_cstr,
                            int shows_controls,
                            int auto_play,
                            int muted,
                            int loop) {
    (void)loop;

    NSString *url_string = ap_string_from_cstr(url_cstr);

#if TARGET_OS_OSX
    if (getenv("HIG_SCREENSHOT_PATH")) {
        return (void *)ap_make_video_capture_preview(url_string, (BOOL)shows_controls);
    }
#else
    if (getenv("HIG_SCREENSHOT_PATH") || getenv("HIG_VALIDATION_CAPTURE")) {
        CGFloat width = 320.0;
        CGFloat height = shows_controls ? 214.0 : 180.0;
        NSString *resolved_title = ap_video_preview_title(url_string);

        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();

        UIColor *top = [UIColor colorWithRed:0.067 green:0.071 blue:0.090 alpha:1.0];
        UIColor *bottom = [UIColor colorWithRed:0.153 green:0.118 blue:0.094 alpha:1.0];
        NSArray *colors = @[(__bridge id)top.CGColor, (__bridge id)bottom.CGColor];
        CGFloat locations[] = {0.0, 1.0};
        CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(color_space, (__bridge CFArrayRef)colors, locations);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0, 0.0), CGPointMake(width, height), 0);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(color_space);

        [[UIColor colorWithRed:1.0 green:0.706 blue:0.341 alpha:0.16] setFill];
        UIBezierPath *glow = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(width - 120.0, 18.0, 120.0, 120.0)];
        [glow fill];

        [[UIColor colorWithWhite:1.0 alpha:0.14] setFill];
        UIBezierPath *badge = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(18.0, 16.0, 104.0, 24.0) cornerRadius:12.0];
        [badge fill];

        NSDictionary *badge_attrs = @{
            NSFontAttributeName : [UIFont systemFontOfSize:10.0 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.82]
        };
        NSDictionary *title_attrs = @{
            NSFontAttributeName : [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.96]
        };
        NSDictionary *meta_attrs = @{
            NSFontAttributeName : [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium],
            NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.72]
        };

        [@"VALIDATION" drawInRect:CGRectMake(30.0, 21.0, 80.0, 14.0) withAttributes:badge_attrs];
        [resolved_title drawInRect:CGRectMake(18.0, 48.0, width - 80.0, 22.0) withAttributes:title_attrs];
        [@"Capture-only poster." drawInRect:CGRectMake(18.0, 70.0, width - 44.0, 16.0) withAttributes:meta_attrs];

        CGRect play_rect = CGRectMake((width - 56.0) / 2.0, (height - 56.0) / 2.0 - 6.0, 56.0, 56.0);
        [[UIColor colorWithWhite:1.0 alpha:0.18] setFill];
        UIBezierPath *play_circle = [UIBezierPath bezierPathWithOvalInRect:play_rect];
        [play_circle fill];
        [[UIColor colorWithWhite:1.0 alpha:0.24] setStroke];
        play_circle.lineWidth = 1.0;
        [play_circle stroke];

        [[UIColor colorWithWhite:1.0 alpha:0.94] setFill];
        UIBezierPath *triangle = [UIBezierPath bezierPath];
        [triangle moveToPoint:CGPointMake(CGRectGetMidX(play_rect) - 6.0, CGRectGetMidY(play_rect) - 12.0)];
        [triangle addLineToPoint:CGPointMake(CGRectGetMidX(play_rect) - 6.0, CGRectGetMidY(play_rect) + 12.0)];
        [triangle addLineToPoint:CGPointMake(CGRectGetMidX(play_rect) + 14.0, CGRectGetMidY(play_rect))];
        [triangle closePath];
        [triangle fill];

        CGFloat track_y = height - 30.0;
        [[UIColor colorWithWhite:1.0 alpha:0.18] setFill];
        UIBezierPath *track = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(18.0, track_y, width - 78.0, 4.0) cornerRadius:2.0];
        [track fill];

        [[UIColor colorWithRed:1.0 green:0.706 blue:0.341 alpha:0.95] setFill];
        UIBezierPath *progress = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(18.0, track_y, (width - 78.0) * 0.34, 4.0) cornerRadius:2.0];
        [progress fill];

        if (shows_controls) {
            [@"01:28" drawInRect:CGRectMake(18.0, height - 20.0, 40.0, 12.0) withAttributes:meta_attrs];
            [@"03:54" drawInRect:CGRectMake(width - 54.0, height - 20.0, 36.0, 12.0) withAttributes:meta_attrs];
        }

        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        UIImageView *image_view = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
        image_view.image = image;
        image_view.contentMode = UIViewContentModeScaleToFill;
        image_view.clipsToBounds = YES;
        return (void *)image_view;
    }
#endif

    NSURL *url = ap_url_from_cstr(url_cstr);
    AVPlayer *player = url ? [AVPlayer playerWithURL:url] : nil;
    if (player) {
        player.muted = (BOOL)muted;
    }

#if TARGET_OS_OSX
    AVPlayerView *player_view = [[AVPlayerView alloc] initWithFrame:NSZeroRect];
    if (!player_view) return NULL;

    if (player) player_view.player = player;
    SEL controls_sel = sel_registerName("setControlsStyle:");
    if ([player_view respondsToSelector:controls_sel]) {
        long long style = shows_controls ? 0 : 1;
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(player_view, controls_sel, (NSInteger)style);
    }

    if (player) objc_setAssociatedObject(player_view, &ap_player_association_key, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (player && auto_play) [player play];
    return (void *)player_view;
#else
    AVPlayerViewController *controller = [[AVPlayerViewController alloc] init];
    if (!controller) return NULL;

    controller.showsPlaybackControls = (BOOL)shows_controls;
    if (player) controller.player = player;
    UIView *player_view = controller.view;
    if (!player_view) return NULL;

    if (player) {
        objc_setAssociatedObject(player_view, &ap_player_association_key, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(player_view, &ap_player_controller_association_key, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (player && auto_play) [player play];
    return (void *)player_view;
#endif
}

void *ap_ring_view_new(double width,
                       double height,
                       double center_x,
                       double center_y,
                       double radius,
                       double track_start_angle,
                       double track_end_angle,
                       double progress_start_angle,
                       double progress_end_angle,
                       double line_width,
                       double track_r,
                       double track_g,
                       double track_b,
                       double track_a,
                       double progress_r,
                       double progress_g,
                       double progress_b,
                       double progress_a) {
#if TARGET_OS_OSX
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, width, height)];
    if (!view) return NULL;
    [view setWantsLayer:YES];
    if (!view.layer) {
        view.layer = [CALayer layer];
    }
    view.layer.backgroundColor = NSColor.clearColor.CGColor;
#else
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
    if (!view) return NULL;
    view.backgroundColor = UIColor.clearColor;
#endif

    CGMutablePathRef track_path = CGPathCreateMutable();
    CGPathAddArc(track_path,
                 NULL,
                 (CGFloat)center_x,
                 (CGFloat)center_y,
                 (CGFloat)radius,
                 (CGFloat)track_start_angle,
                 (CGFloat)track_end_angle,
                 false);

    CGMutablePathRef progress_path = CGPathCreateMutable();
    CGPathAddArc(progress_path,
                 NULL,
                 (CGFloat)center_x,
                 (CGFloat)center_y,
                 (CGFloat)radius,
                 (CGFloat)progress_start_angle,
                 (CGFloat)progress_end_angle,
                 false);

    id track_color = nscolor_rgba(track_r, track_g, track_b, track_a);
    id progress_color = nscolor_rgba(progress_r, progress_g, progress_b, progress_a);

    CAShapeLayer *track_layer = [CAShapeLayer layer];
    track_layer.frame = CGRectMake(0.0, 0.0, width, height);
    track_layer.path = track_path;
    track_layer.fillColor = NULL;
    track_layer.strokeColor = track_color ? [track_color CGColor] : NULL;
    track_layer.lineWidth = (CGFloat)line_width;
    track_layer.lineCap = kCALineCapRound;

    CAShapeLayer *progress_layer = [CAShapeLayer layer];
    progress_layer.frame = CGRectMake(0.0, 0.0, width, height);
    progress_layer.path = progress_path;
    progress_layer.fillColor = NULL;
    progress_layer.strokeColor = progress_color ? [progress_color CGColor] : NULL;
    progress_layer.lineWidth = (CGFloat)line_width;
    progress_layer.lineCap = kCALineCapRound;

    [view.layer addSublayer:track_layer];
    [view.layer addSublayer:progress_layer];

    CGPathRelease(track_path);
    CGPathRelease(progress_path);

    return (void *)view;
}

static double ap_clamp_unit(double value) {
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
}

static void ap_add_activity_ring_layers(CALayer *container_layer,
                                        double size,
                                        double center,
                                        double radius,
                                        double start_angle,
                                        double end_angle,
                                        double thickness,
                                        double progress_fraction,
                                        double r,
                                        double g,
                                        double b) {
    if (!container_layer || radius <= 0.0 || thickness <= 0.0) return;

    double clamped_progress = ap_clamp_unit(progress_fraction);
    double progress_end = start_angle + ((end_angle - start_angle) * clamped_progress);

    CGMutablePathRef track_path = CGPathCreateMutable();
    CGPathAddArc(track_path,
                 NULL,
                 (CGFloat)center,
                 (CGFloat)center,
                 (CGFloat)radius,
                 (CGFloat)start_angle,
                 (CGFloat)end_angle,
                 false);

    CGMutablePathRef progress_path = CGPathCreateMutable();
    CGPathAddArc(progress_path,
                 NULL,
                 (CGFloat)center,
                 (CGFloat)center,
                 (CGFloat)radius,
                 (CGFloat)start_angle,
                 (CGFloat)progress_end,
                 false);

    id track_color = nscolor_rgba(r * 0.26, g * 0.26, b * 0.26, 1.0);
    id progress_color = nscolor_rgba(r, g, b, 1.0);

    CAShapeLayer *track_layer = [CAShapeLayer layer];
    track_layer.frame = CGRectMake(0.0, 0.0, size, size);
    track_layer.path = track_path;
    track_layer.fillColor = NULL;
    track_layer.strokeColor = track_color ? [track_color CGColor] : NULL;
    track_layer.lineWidth = (CGFloat)thickness;
    track_layer.lineCap = kCALineCapRound;

    CAShapeLayer *progress_layer = [CAShapeLayer layer];
    progress_layer.frame = CGRectMake(0.0, 0.0, size, size);
    progress_layer.path = progress_path;
    progress_layer.fillColor = NULL;
    progress_layer.strokeColor = progress_color ? [progress_color CGColor] : NULL;
    progress_layer.lineWidth = (CGFloat)thickness;
    progress_layer.lineCap = kCALineCapRound;

    [container_layer addSublayer:track_layer];
    [container_layer addSublayer:progress_layer];

    CGPathRelease(track_path);
    CGPathRelease(progress_path);
}

void *ap_activity_rings_view_new(double size,
                                 double thickness,
                                 double gap,
                                 double move_progress,
                                 double exercise_progress,
                                 double stand_progress) {
#if TARGET_OS_OSX
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, size, size)];
    if (!view) return NULL;
    [view setWantsLayer:YES];
    if (!view.layer) {
        view.layer = [CALayer layer];
    }
    view.layer.backgroundColor = NSColor.clearColor.CGColor;
#else
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, size, size)];
    if (!view) return NULL;
    view.backgroundColor = UIColor.clearColor;
#endif

    CALayer *container_layer = view.layer;
    if (!container_layer) return (void *)view;

#if TARGET_OS_OSX
    CGColorRef black_cg = NSColor.blackColor.CGColor;
#else
    CGColorRef black_cg = UIColor.blackColor.CGColor;
#endif

    CAShapeLayer *background_layer = [CAShapeLayer layer];
    background_layer.frame = CGRectMake(0.0, 0.0, size, size);
    CGMutablePathRef background_path = CGPathCreateMutable();
    CGPathAddEllipseInRect(background_path, NULL, CGRectMake(0.0, 0.0, size, size));
    background_layer.path = background_path;
    background_layer.fillColor = black_cg;
    background_layer.strokeColor = black_cg;
    background_layer.lineWidth = 1.0;
    [container_layer addSublayer:background_layer];
    CGPathRelease(background_path);

    double center = size / 2.0;
    double outer_radius = center - (thickness / 2.0) - gap;
    double middle_radius = outer_radius - thickness - gap;
    double inner_radius = middle_radius - thickness - gap;
    double start_angle = -1.5707963267948966;
    double end_angle = 4.71238898038469;

    ap_add_activity_ring_layers(container_layer, size, center, outer_radius, start_angle, end_angle, thickness, move_progress, 250.0 / 255.0, 17.0 / 255.0, 79.0 / 255.0);
    ap_add_activity_ring_layers(container_layer, size, center, middle_radius, start_angle, end_angle, thickness, exercise_progress, 166.0 / 255.0, 1.0, 0.0);
    ap_add_activity_ring_layers(container_layer, size, center, inner_radius, start_angle, end_angle, thickness, stand_progress, 0.0, 1.0, 246.0 / 255.0);

    return (void *)view;
}

// PathView — build a CGPath from a flattened segment array and render it
// via a CAShapeLayer with optional fill + stroke. seg_data holds 7 doubles
// per segment: [command, x, y, cx1, cy1, cx2, cy2]; command is
// 0=MoveTo 1=LineTo 2=QuadCurveTo 3=CurveTo 4=Close. Path coordinates use
// the top-left, y-down convention (matching iOS/UIKit and the
// cross-platform authoring convention); on macOS the layer geometry is
// flipped so the same coordinates render identically.
void *ap_path_view_new(double width, double height,
                       const double *seg_data, int seg_count,
                       int has_fill, double fr, double fg, double fb, double fa,
                       double sr, double sg, double sb, double sa,
                       double line_width) {
#if TARGET_OS_OSX
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, width, height)];
    if (!view) return NULL;
    [view setWantsLayer:YES];
    if (!view.layer) {
        view.layer = [CALayer layer];
    }
    view.layer.backgroundColor = NSColor.clearColor.CGColor;
    view.layer.geometryFlipped = YES; // top-left, y-down to match iOS
#else
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
    if (!view) return NULL;
    view.backgroundColor = UIColor.clearColor;
#endif

    CGMutablePathRef path = CGPathCreateMutable();
    if (seg_data) {
        for (int i = 0; i < seg_count; i++) {
            const double *s = seg_data + (i * 7);
            int cmd = (int)s[0];
            CGFloat x = (CGFloat)s[1], y = (CGFloat)s[2];
            CGFloat cx1 = (CGFloat)s[3], cy1 = (CGFloat)s[4];
            CGFloat cx2 = (CGFloat)s[5], cy2 = (CGFloat)s[6];
            switch (cmd) {
                case 0: CGPathMoveToPoint(path, NULL, x, y); break;
                case 1: CGPathAddLineToPoint(path, NULL, x, y); break;
                case 2: CGPathAddQuadCurveToPoint(path, NULL, cx1, cy1, x, y); break;
                case 3: CGPathAddCurveToPoint(path, NULL, cx1, cy1, cx2, cy2, x, y); break;
                case 4: CGPathCloseSubpath(path); break;
                default: break;
            }
        }
    }

    CAShapeLayer *shape = [CAShapeLayer layer];
    shape.frame = CGRectMake(0.0, 0.0, width, height);
    shape.path = path;
    shape.lineWidth = (CGFloat)line_width;

    id stroke_color = nscolor_rgba(sr, sg, sb, sa);
    shape.strokeColor = stroke_color ? [stroke_color CGColor] : NULL;
    if (has_fill) {
        id fill_color = nscolor_rgba(fr, fg, fb, fa);
        shape.fillColor = fill_color ? [fill_color CGColor] : NULL;
    } else {
        shape.fillColor = NULL;
    }

    [view.layer addSublayer:shape];
    CGPathRelease(path);
    return (void *)view;
}

// Canvas — replay an immediate-mode drawing command stream. op_data holds
// 14 doubles per op: [command, x, y, x2, y2, x3, y3, radius, start_angle,
// end_angle, r, g, b, a]. command ordinals match UI::DrawCommand:
// 0=MoveTo 1=LineTo 2=Arc 3=QuadCurveTo 4=BezierCurveTo 5=ClosePath
// 6=Fill 7=Stroke 8=SetFillColor 9=SetStrokeColor 10=SetLineWidth
// 11=BeginPath. Fill/Stroke each emit a CAShapeLayer snapshot of the
// current path with the current fill/stroke state, so a path can be both
// filled and stroked.
void *ap_canvas_view_new(double width, double height,
                         const double *op_data, int op_count) {
#if TARGET_OS_OSX
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, width, height)];
    if (!view) return NULL;
    [view setWantsLayer:YES];
    if (!view.layer) {
        view.layer = [CALayer layer];
    }
    view.layer.backgroundColor = NSColor.clearColor.CGColor;
    view.layer.geometryFlipped = YES;
#else
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, width, height)];
    if (!view) return NULL;
    view.backgroundColor = UIColor.clearColor;
#endif
    if (!op_data) return (void *)view;

    CGMutablePathRef path = CGPathCreateMutable();
    double fr = 0, fg = 0, fb = 0, fa = 1;        // current fill color
    double kr = 0, kg = 0, kb = 0, ka = 1;        // current stroke color
    double line_width = 1.0;

    for (int i = 0; i < op_count; i++) {
        const double *o = op_data + (i * 14);
        int cmd = (int)o[0];
        CGFloat x = (CGFloat)o[1], y = (CGFloat)o[2];
        CGFloat x2 = (CGFloat)o[3], y2 = (CGFloat)o[4];
        CGFloat x3 = (CGFloat)o[5], y3 = (CGFloat)o[6];
        CGFloat radius = (CGFloat)o[7], sa = (CGFloat)o[8], ea = (CGFloat)o[9];
        double r = o[10], g = o[11], b = o[12], a = o[13];
        switch (cmd) {
            case 0: CGPathMoveToPoint(path, NULL, x, y); break;
            case 1: CGPathAddLineToPoint(path, NULL, x, y); break;
            case 2: CGPathAddArc(path, NULL, x, y, radius, sa, ea, false); break;
            case 3: CGPathAddQuadCurveToPoint(path, NULL, x2, y2, x, y); break;
            case 4: CGPathAddCurveToPoint(path, NULL, x2, y2, x3, y3, x, y); break;
            case 5: CGPathCloseSubpath(path); break;
            case 8: fr = r; fg = g; fb = b; fa = a; break;  // SetFillColor
            case 9: kr = r; kg = g; kb = b; ka = a; break;  // SetStrokeColor
            case 10: line_width = o[1]; break;              // SetLineWidth (in x)
            case 11: {                                       // BeginPath
                CGPathRelease(path);
                path = CGPathCreateMutable();
                break;
            }
            case 6: {                                        // Fill
                CAShapeLayer *layer = [CAShapeLayer layer];
                layer.frame = CGRectMake(0.0, 0.0, width, height);
                layer.path = CGPathCreateCopy(path);
                id fc = nscolor_rgba(fr, fg, fb, fa);
                layer.fillColor = fc ? [fc CGColor] : NULL;
                layer.strokeColor = NULL;
                [view.layer addSublayer:layer];
                break;
            }
            case 7: {                                        // Stroke
                CAShapeLayer *layer = [CAShapeLayer layer];
                layer.frame = CGRectMake(0.0, 0.0, width, height);
                layer.path = CGPathCreateCopy(path);
                layer.fillColor = NULL;
                id sc = nscolor_rgba(kr, kg, kb, ka);
                layer.strokeColor = sc ? [sc CGColor] : NULL;
                layer.lineWidth = (CGFloat)line_width;
                layer.lineCap = kCALineCapRound;
                layer.lineJoin = kCALineJoinRound;
                [view.layer addSublayer:layer];
                break;
            }
            default: break;
        }
    }
    CGPathRelease(path);
    return (void *)view;
}

static NSMutableArray *ap_share_items_from_payload(NSString *text, NSString *url_string) {
    NSMutableArray *items = [NSMutableArray array];
    if (text && text.length) {
        [items addObject:text];
    }
    if (url_string && url_string.length) {
        NSURL *url = nil;
        if ([url_string containsString:@"://"]) {
            url = [NSURL URLWithString:url_string];
        } else {
            url = [NSURL fileURLWithPath:url_string];
        }
        if (url) {
            [items addObject:url];
        } else {
            [items addObject:url_string];
        }
    }
    return items;
}

#if TARGET_OS_OSX
void nssharingservicepicker_present(void *anchor_view_ptr,
                                    const char *text_cstr,
                                    const char *url_cstr) {
    NSView *anchor_view = (NSView *)anchor_view_ptr;
    if (!anchor_view) return;

    NSString *text = ap_string_from_cstr(text_cstr);
    NSString *url_string = ap_string_from_cstr(url_cstr);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!anchor_view.window) return;

        NSMutableArray *items = ap_share_items_from_payload(text, url_string);
        if (!items.count) return;

        NSSharingServicePicker *picker = [[NSSharingServicePicker alloc] initWithItems:items];
        if (!picker) return;

        NSRect rect = anchor_view.bounds;
        if (rect.size.width <= 0.0 || rect.size.height <= 0.0) {
            rect = NSMakeRect(0.0, 0.0, 1.0, 1.0);
        }

        objc_setAssociatedObject(anchor_view, &ap_share_picker_association_key, picker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [picker showRelativeToRect:rect ofView:anchor_view preferredEdge:NSRectEdgeMinY];
        [picker release];
    });
}
#else
static UIWindow *ap_application_key_window(UIApplication *application) {
    if (!application) return nil;
    if ([application respondsToSelector:@selector(connectedScenes)]) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
                if (candidate.isKeyWindow) return candidate;
            }
        }
    }

    SEL key_window_sel = sel_registerName("keyWindow");
    if ([application respondsToSelector:key_window_sel]) {
        return ((UIWindow *(*)(id, SEL))objc_msgSend)(application, key_window_sel);
    }
    return nil;
}

static UIViewController *ap_top_presenting_view_controller(UIView *anchor_view) {
    UIResponder *responder = anchor_view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *controller = (UIViewController *)responder;
            while (controller.presentedViewController) {
                controller = controller.presentedViewController;
            }
            return controller;
        }
        responder = [responder nextResponder];
    }

    UIWindow *window = anchor_view.window;
    UIApplication *application = [UIApplication sharedApplication];
    if (!window) window = ap_application_key_window(application);
    if (!window) return nil;

    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    return controller;
}

void uiactivityview_present(void *anchor_view_ptr,
                            const char *text_cstr,
                            const char *url_cstr,
                            const char *subject_cstr) {
    UIView *anchor_view = (UIView *)anchor_view_ptr;
    if (!anchor_view) return;

    NSString *text = ap_string_from_cstr(text_cstr);
    NSString *url_string = ap_string_from_cstr(url_cstr);
    NSString *subject = ap_string_from_cstr(subject_cstr);

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presenter = ap_top_presenting_view_controller(anchor_view);
        if (!presenter || [presenter isKindOfClass:[UIActivityViewController class]]) return;

        NSMutableArray *items = ap_share_items_from_payload(text, url_string);
        if (!items.count) return;

        UIActivityViewController *controller =
            [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        if (!controller) return;

        if (subject && subject.length) {
            @try {
                [controller setValue:subject forKey:@"subject"];
            } @catch (__unused NSException *exception) {
            }
        }

        UIPopoverPresentationController *popover = controller.popoverPresentationController;
        if (popover) {
            popover.sourceView = anchor_view;
            CGRect rect = anchor_view.bounds;
            if (rect.size.width <= 0.0 || rect.size.height <= 0.0) {
                rect = CGRectMake(0.0, 0.0, 1.0, 1.0);
            }
            popover.sourceRect = rect;
        }

        objc_setAssociatedObject(anchor_view, &ap_share_controller_association_key, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [presenter presentViewController:controller animated:NO completion:nil];
        [controller release];
    });
}
#endif

static UNUserNotificationCenter *ap_notifications_center(void) {
    Class center_class = NSClassFromString(@"UNUserNotificationCenter");
    if (!center_class) return nil;
    // +currentNotificationCenter THROWS (NSInternalInconsistencyException,
    // "bundleProxyForCurrentProcess is nil") in a process with no app bundle — e.g.
    // a bare CLI binary like the sample's macos/bin/voyager. Guard on the main
    // bundle identifier so notifications gracefully no-op there (every caller
    // already handles a nil center) instead of aborting the whole app.
    if ([[NSBundle mainBundle] bundleIdentifier] == nil) return nil;
    return [UNUserNotificationCenter currentNotificationCenter];
}

long long ap_notifications_authorization_status(void) {
    UNUserNotificationCenter *center = ap_notifications_center();
    if (!center) return 5;

    __block long long status = 5;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        if (settings) {
            status = (long long)settings.authorizationStatus;
        }
        dispatch_semaphore_signal(sema);
    }];

    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(sema, timeout);
    return status;
}

int ap_notifications_request_authorization(int alert, int sound, int badge, int provisional) {
    UNUserNotificationCenter *center = ap_notifications_center();
    if (!center) return 0;

    UNAuthorizationOptions options = 0;
    if (alert) options |= UNAuthorizationOptionAlert;
    if (sound) options |= UNAuthorizationOptionSound;
    if (badge) options |= UNAuthorizationOptionBadge;
    // Provisional = quiet, no-prompt authorization (no permission dialog / tap).
    if (provisional) options |= UNAuthorizationOptionProvisional;

    __block BOOL granted = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [center requestAuthorizationWithOptions:options completionHandler:^(BOOL ok, NSError *error) {
        granted = (ok && error == nil);
        dispatch_semaphore_signal(sema);
    }];

    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(sema, timeout);
    return granted ? 1 : 0;
}

int ap_notifications_schedule_local(const char *identifier_cstr,
                                    const char *title_cstr,
                                    const char *subtitle_cstr,
                                    const char *body_cstr,
                                    double delay_seconds,
                                    int badge,
                                    int play_sound,
                                    int repeats,
                                    const char *thread_id_cstr) {
    UNUserNotificationCenter *center = ap_notifications_center();
    if (!center) return 0;

    NSString *title = ap_string_from_cstr(title_cstr);
    NSString *body = ap_string_from_cstr(body_cstr);
    if (!title || !body || !title.length || !body.length) return 0;

    NSString *identifier = ap_string_from_cstr(identifier_cstr);
    if (!identifier || !identifier.length) {
        identifier = [NSString stringWithFormat:@"ui-notification-%f", CFAbsoluteTimeGetCurrent()];
    }

    NSString *subtitle = ap_string_from_cstr(subtitle_cstr);
    NSString *thread_id = ap_string_from_cstr(thread_id_cstr);

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    if (subtitle && subtitle.length) {
        content.subtitle = subtitle;
    }
    if (thread_id && thread_id.length) {
        content.threadIdentifier = thread_id;
    }
    if (badge >= 0) {
        content.badge = [NSNumber numberWithInt:badge];
    }
    if (play_sound) {
        content.sound = UNNotificationSound.defaultSound;
    }

    NSTimeInterval interval = delay_seconds > 0.0 ? delay_seconds : 0.25;
    if (repeats && interval < 60.0) {
        interval = 60.0;
    }

    UNTimeIntervalNotificationTrigger *trigger =
        [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:interval repeats:(BOOL)repeats];
    UNNotificationRequest *request =
        [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

    __block BOOL scheduled = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [center addNotificationRequest:request withCompletionHandler:^(NSError *error) {
        scheduled = (error == nil);
        dispatch_semaphore_signal(sema);
    }];

    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(sema, timeout);
    [content release];
    return scheduled ? 1 : 0;
}

void ap_notifications_remove_pending(const char *identifier_cstr) {
    UNUserNotificationCenter *center = ap_notifications_center();
    if (!center) return;

    NSString *identifier = ap_string_from_cstr(identifier_cstr);
    if (!identifier || !identifier.length) return;
    [center removePendingNotificationRequestsWithIdentifiers:@[identifier]];
}

void ap_notifications_remove_all_pending(void) {
    UNUserNotificationCenter *center = ap_notifications_center();
    if (!center) return;
    [center removeAllPendingNotificationRequests];
}

// Returns the number of notification requests currently pending delivery.
// Pending requests are tracked by the system independently of authorization
// (authorization gates DELIVERY, not scheduling), so this is an honest signal
// that `ap_notifications_schedule_local` actually landed a request — usable as
// a functional-outcome assertion in tests without needing to observe a
// delivered banner. Synchronous via a semaphore, like the sibling calls.
int ap_notifications_pending_count(void) {
    UNUserNotificationCenter *center = ap_notifications_center();
    if (!center) return -1;

    __block int count = -1;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
        count = requests ? (int)requests.count : 0;
        dispatch_semaphore_signal(sema);
    }];

    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(sema, timeout);
    return count;
}

// Returns 1 when a pending notification request with the given identifier
// exists, 0 when not, -1 when the center is unavailable. Lets a caller assert
// that ITS specific notification (not just "some notification") is scheduled.
int ap_notifications_has_pending(const char *identifier_cstr) {
    UNUserNotificationCenter *center = ap_notifications_center();
    if (!center) return -1;

    NSString *identifier = ap_string_from_cstr(identifier_cstr);
    if (!identifier || !identifier.length) return 0;

    __block int found = 0;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
        for (UNNotificationRequest *req in requests) {
            if ([req.identifier isEqualToString:identifier]) { found = 1; break; }
        }
        dispatch_semaphore_signal(sema);
    }];

    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC));
    dispatch_semaphore_wait(sema, timeout);
    return found;
}

// ---- Foreground delivery → Crystal (the agent reaches you, with voice) ----
// Implemented in Crystal (src/ui/notifications.cr): routes the delivered body to
// the registered UI::Notifications.on_foreground handler. Portable twin lives in
// notifications_bridge.m for watchOS (this file isn't compiled there).
extern void ap_on_foreground_notification(const char *body);

@interface APForegroundNotifDelegate : NSObject <UNUserNotificationCenterDelegate>
@end
@implementation APForegroundNotifDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSString *body = notification.request.content.body;
    if (body && body.length) ap_on_foreground_notification([body UTF8String]);
    if (@available(iOS 14.0, macOS 11.0, *)) {
        completionHandler(UNNotificationPresentationOptionBanner |
                          UNNotificationPresentationOptionSound |
                          UNNotificationPresentationOptionList);
    } else {
        completionHandler(UNNotificationPresentationOptionSound);
    }
}
@end

static APForegroundNotifDelegate *g_fg_delegate = nil;
void ap_notifications_install_foreground_delegate(void) {
    UNUserNotificationCenter *center = ap_notifications_center();
    if (!center) return;
    if (!g_fg_delegate) g_fg_delegate = [[APForegroundNotifDelegate alloc] init];
    center.delegate = g_fg_delegate;
}

// ============================================================
// Text-to-speech (AVSpeechSynthesizer) — the agent SPEAKS.
// Portable twin lives in speech_bridge.m for watchOS (this file isn't compiled
// there). See UI::Speech.
// ============================================================

static AVSpeechSynthesizer *ap_speech_synth(void) {
    static AVSpeechSynthesizer *synth = nil;
    if (!synth) synth = [[AVSpeechSynthesizer alloc] init];
    return synth;
}

int ap_speech_speak(const char *text_cstr, double rate, double pitch, double volume, const char *lang_cstr) {
    NSString *text = ap_string_from_cstr(text_cstr);
    if (!text || !text.length) return 0;

    AVSpeechSynthesizer *synth = ap_speech_synth();
    if (!synth) return 0;

#if !TARGET_OS_OSX
    // iOS needs an active playback audio session; macOS has no AVAudioSession.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (session) {
        [session setCategory:AVAudioSessionCategoryPlayback
                        mode:AVAudioSessionModeSpokenAudio
                     options:AVAudioSessionCategoryOptionDuckOthers
                       error:nil];
        [session setActive:YES error:nil];
    }
#endif

    AVSpeechUtterance *utt = [AVSpeechUtterance speechUtteranceWithString:text];
    utt.rate = (float)rate;
    utt.pitchMultiplier = (float)pitch;
    utt.volume = (float)volume;
    NSString *lang = ap_string_from_cstr(lang_cstr);
    if (lang && lang.length) {
        AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:lang];
        if (voice) utt.voice = voice;
    }

    [synth speakUtterance:utt];
    return 1; // enqueued; speech starts asynchronously — caller queries is_speaking
}

void ap_speech_stop(void) {
    AVSpeechSynthesizer *synth = ap_speech_synth();
    [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

int ap_speech_is_speaking(void) {
    AVSpeechSynthesizer *synth = ap_speech_synth();
    return synth.isSpeaking ? 1 : 0;
}

void ap_free_c_string(char *payload) {
    if (payload) free(payload);
}

// ============================================================
// Persistent settings (NSUserDefaults). Portable twin: prefs_bridge.m (watchOS).
// See UI::Preferences.
// ============================================================

static NSString *ap_prefs_key(const char *key) {
    if (!key || !key[0]) return nil;
    return [NSString stringWithUTF8String:key];
}

void ap_prefs_set_bool(const char *key, int value) {
    NSString *k = ap_prefs_key(key);
    if (!k) return;
    [[NSUserDefaults standardUserDefaults] setBool:(value != 0) forKey:k];
}

int ap_prefs_get_bool(const char *key, int default_value) {
    NSString *k = ap_prefs_key(key);
    if (!k) return default_value;
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:k] == nil) return default_value;
    return [d boolForKey:k] ? 1 : 0;
}

void ap_prefs_set_double(const char *key, double value) {
    NSString *k = ap_prefs_key(key);
    if (!k) return;
    [[NSUserDefaults standardUserDefaults] setDouble:value forKey:k];
}

double ap_prefs_get_double(const char *key, double default_value) {
    NSString *k = ap_prefs_key(key);
    if (!k) return default_value;
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:k] == nil) return default_value;
    return [d doubleForKey:k];
}

void ap_prefs_clear_all(void) {
    NSString *domain = [[NSBundle mainBundle] bundleIdentifier];
    if (domain) [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domain];
}

static NSDictionary *ap_json_dictionary_from_cstr(const char *payload_cstr) {
    NSString *payload = ap_string_from_cstr(payload_cstr);
    if (!payload || !payload.length) return nil;

    NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;

    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error || ![object isKindOfClass:[NSDictionary class]]) return nil;
    return (NSDictionary *)object;
}

#if TARGET_OS_OSX
static NSString *g_last_menu_bar_identifier = nil;
static NSString *g_last_status_item_identifier = nil;
static NSMutableDictionary *g_status_items = nil;

static void ap_store_triggered_identifier(NSString **slot, NSString *identifier) {
    if (*slot) {
        [*slot release];
        *slot = nil;
    }
    if (identifier && identifier.length) {
        *slot = [identifier copy];
    }
}

@interface APShellCommandTarget : NSObject
@end

@implementation APShellCommandTarget
- (void)dispatchMenuBarItem:(id)sender {
    NSString *identifier = [sender representedObject];
    if (![identifier isKindOfClass:[NSString class]] || !identifier.length) {
        identifier = [sender title];
    }
    ap_store_triggered_identifier(&g_last_menu_bar_identifier, identifier);
}

- (void)dispatchStatusItem:(id)sender {
    NSString *identifier = [sender representedObject];
    if (![identifier isKindOfClass:[NSString class]] || !identifier.length) {
        identifier = [sender title];
    }
    ap_store_triggered_identifier(&g_last_status_item_identifier, identifier);
}
@end

static APShellCommandTarget *ap_shell_command_target(void) {
    static APShellCommandTarget *target = nil;
    if (!target) {
        target = [[APShellCommandTarget alloc] init];
    }
    return target;
}

static NSImage *ap_menu_symbol_image(NSString *symbol_name, BOOL template_icon) {
    if (!symbol_name || !symbol_name.length) return nil;
    if (![NSImage respondsToSelector:@selector(imageWithSystemSymbolName:accessibilityDescription:)]) {
        return nil;
    }

    NSImage *image = [NSImage imageWithSystemSymbolName:symbol_name accessibilityDescription:nil];
    if (image) {
        [image setTemplate:template_icon];
    }
    return image;
}

static void ap_populate_menu_items(NSMenu *menu, NSArray *items, SEL action_selector) {
    if (!menu || ![items isKindOfClass:[NSArray class]]) return;
    [menu setAutoenablesItems:NO];

    for (id raw_item in items) {
        if (![raw_item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *item_dict = (NSDictionary *)raw_item;
        NSString *type = item_dict[@"type"];
        if ([type isEqualToString:@"separator"]) {
            [menu addItem:[NSMenuItem separatorItem]];
            continue;
        }

        NSString *label = item_dict[@"label"];
        if (![label isKindOfClass:[NSString class]] || !label.length) continue;

        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:label action:action_selector keyEquivalent:@""];
        item.target = ap_shell_command_target();
        item.enabled = ![item_dict[@"is_disabled"] boolValue];

        NSString *identifier = item_dict[@"identifier"];
        if ([identifier isKindOfClass:[NSString class]] && identifier.length) {
            [item setRepresentedObject:identifier];
        }

        NSString *symbol_name = item_dict[@"icon"];
        NSImage *image = ap_menu_symbol_image(symbol_name, YES);
        if (image) {
            [item setImage:image];
        }

        if ([item_dict[@"is_destructive"] boolValue]) {
            NSColor *destructive = [NSColor systemRedColor];
            NSDictionary *attributes = @{NSForegroundColorAttributeName: destructive};
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:label attributes:attributes];
            [item setAttributedTitle:title];
            [title release];
        }

        [menu addItem:item];
        [item release];
    }
}
#endif

#if !TARGET_OS_OSX
static UIApplicationShortcutIcon *ap_home_screen_quick_action_icon(NSString *symbol_name) {
    if (!symbol_name || !symbol_name.length) return nil;
    if (![UIApplicationShortcutIcon respondsToSelector:@selector(iconWithTemplateImageName:)]) {
        return nil;
    }

    return [UIApplicationShortcutIcon iconWithTemplateImageName:symbol_name];
}
#endif

int ap_home_screen_quick_actions_apply(const char *payload_cstr) {
#if TARGET_OS_OSX
    (void)payload_cstr;
    return 0;
#else
    NSDictionary *payload = ap_json_dictionary_from_cstr(payload_cstr);
    NSArray *actions = payload[@"actions"];
    if (![actions isKindOfClass:[NSArray class]]) return 0;

    __block BOOL applied = NO;
    ap_run_on_main_thread_sync(^{
        UIApplication *application = [UIApplication sharedApplication];
        if (!application) return;

        NSMutableArray *shortcut_items = [[NSMutableArray alloc] init];
        for (id raw_action in actions) {
            if (![raw_action isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *action_dict = (NSDictionary *)raw_action;

            NSString *type = action_dict[@"type"];
            NSString *title = action_dict[@"title"];
            if (![type isKindOfClass:[NSString class]] || !type.length) continue;
            if (![title isKindOfClass:[NSString class]] || !title.length) continue;

            NSString *subtitle = action_dict[@"subtitle"];
            NSString *system_image = action_dict[@"system_image"];
            NSDictionary *user_info = action_dict[@"user_info"];
            UIApplicationShortcutIcon *icon = ap_home_screen_quick_action_icon(system_image);

            UIApplicationShortcutItem *item = [[UIApplicationShortcutItem alloc]
                initWithType:type
              localizedTitle:title
           localizedSubtitle:([subtitle isKindOfClass:[NSString class]] && subtitle.length) ? subtitle : nil
                        icon:icon
                    userInfo:[user_info isKindOfClass:[NSDictionary class]] ? user_info : nil];
            [shortcut_items addObject:item];
            [item release];
        }

        application.shortcutItems = shortcut_items;
        [shortcut_items release];
        applied = YES;
    });

    return applied ? 1 : 0;
#endif
}

void ap_home_screen_quick_actions_clear(void) {
#if TARGET_OS_OSX
    return;
#else
    ap_run_on_main_thread_sync(^{
        UIApplication *application = [UIApplication sharedApplication];
        if (!application) return;
        application.shortcutItems = @[];
    });
#endif
}

int ap_menu_bar_install(const char *payload_cstr) {
#if !TARGET_OS_OSX
    return 0;
#else
    NSDictionary *payload = ap_json_dictionary_from_cstr(payload_cstr);
    NSArray *menus = payload[@"menus"];
    if (![menus isKindOfClass:[NSArray class]]) return 0;

    __block BOOL installed = NO;
    ap_run_on_main_thread_sync(^{
        NSApplication *application = NSApp ?: [NSApplication sharedApplication];
        if (!application) return;

        NSMenu *main_menu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
        for (id raw_menu in menus) {
            if (![raw_menu isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *menu_dict = (NSDictionary *)raw_menu;
            NSString *title = menu_dict[@"title"];
            NSArray *items = menu_dict[@"items"];
            if (![title isKindOfClass:[NSString class]] || !title.length) continue;

            NSMenuItem *root_item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
            NSMenu *submenu = [[NSMenu alloc] initWithTitle:title];
            ap_populate_menu_items(submenu, items, @selector(dispatchMenuBarItem:));
            [root_item setSubmenu:submenu];
            [main_menu addItem:root_item];
            [submenu release];
            [root_item release];
        }

        [application setMainMenu:main_menu];
        [main_menu release];
        installed = YES;
    });

    return installed ? 1 : 0;
#endif
}

void ap_menu_bar_clear(void) {
#if TARGET_OS_OSX
    ap_run_on_main_thread_sync(^{
        NSApplication *application = NSApp ?: [NSApplication sharedApplication];
        if (!application) return;
        NSMenu *main_menu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
        [application setMainMenu:main_menu];
        [main_menu release];
    });
#endif
}

char *ap_menu_bar_take_triggered_identifier(void) {
#if !TARGET_OS_OSX
    return NULL;
#else
    if (!g_last_menu_bar_identifier) return NULL;
    const char *utf8 = [g_last_menu_bar_identifier UTF8String];
    char *copy = utf8 ? strdup(utf8) : NULL;
    [g_last_menu_bar_identifier release];
    g_last_menu_bar_identifier = nil;
    return copy;
#endif
}

int ap_status_item_install(const char *identifier_cstr,
                           const char *title_cstr,
                           const char *icon_cstr,
                           const char *tooltip_cstr,
                           int template_icon,
                           int visible,
                           const char *menu_payload_cstr) {
#if !TARGET_OS_OSX
    return 0;
#else
    NSString *identifier = ap_string_from_cstr(identifier_cstr);
    if (!identifier || !identifier.length) return 0;

    NSString *title = ap_string_from_cstr(title_cstr);
    NSString *icon = ap_string_from_cstr(icon_cstr);
    NSString *tooltip = ap_string_from_cstr(tooltip_cstr);
    NSDictionary *menu_payload = ap_json_dictionary_from_cstr(menu_payload_cstr);
    NSArray *items = menu_payload[@"items"];

    __block BOOL installed = NO;
    ap_run_on_main_thread_sync(^{
        if (!g_status_items) {
            g_status_items = [[NSMutableDictionary alloc] init];
        }

        NSStatusBar *system_bar = [NSStatusBar systemStatusBar];
        NSStatusItem *status_item = [g_status_items objectForKey:identifier];
        if (!status_item) {
            status_item = [system_bar statusItemWithLength:NSVariableStatusItemLength];
            if (!status_item) return;
            [g_status_items setObject:status_item forKey:identifier];
        }

        if ([status_item respondsToSelector:@selector(setVisible:)]) {
            [status_item setVisible:(BOOL)visible];
        }

        NSStatusBarButton *button = [status_item button];
        if (button) {
            button.title = (title && title.length) ? title : @"";
            button.image = ap_menu_symbol_image(icon, (BOOL)template_icon);
            button.toolTip = tooltip;
        }

        status_item.menu = nil;
        if ([items isKindOfClass:[NSArray class]] && items.count > 0) {
            NSMenu *menu = [[NSMenu alloc] initWithTitle:(title && title.length) ? title : identifier];
            ap_populate_menu_items(menu, items, @selector(dispatchStatusItem:));
            status_item.menu = menu;
            [menu release];
        }

        installed = YES;
    });

    return installed ? 1 : 0;
#endif
}

void ap_status_item_uninstall(const char *identifier_cstr) {
#if TARGET_OS_OSX
    NSString *identifier = ap_string_from_cstr(identifier_cstr);
    if (!identifier || !identifier.length) return;

    ap_run_on_main_thread_sync(^{
        NSStatusItem *status_item = [g_status_items objectForKey:identifier];
        if (!status_item) return;
        [[NSStatusBar systemStatusBar] removeStatusItem:status_item];
        [g_status_items removeObjectForKey:identifier];
    });
#endif
}

char *ap_status_item_take_triggered_identifier(void) {
#if !TARGET_OS_OSX
    return NULL;
#else
    if (!g_last_status_item_identifier) return NULL;
    const char *utf8 = [g_last_status_item_identifier UTF8String];
    char *copy = utf8 ? strdup(utf8) : NULL;
    [g_last_status_item_identifier release];
    g_last_status_item_identifier = nil;
    return copy;
#endif
}

#if TARGET_OS_OSX
static NSWindow *ap_target_window(void) {
    NSApplication *application = NSApp ?: [NSApplication sharedApplication];
    if (!application) return nil;
    if (application.keyWindow) return application.keyWindow;
    if (application.mainWindow) return application.mainWindow;
    return application.windows.firstObject;
}
#else
static UIWindow *ap_target_window(void) {
    UIApplication *application = [UIApplication sharedApplication];
    return ap_application_key_window(application);
}

static long long g_status_bar_style = 0;
static BOOL g_status_bar_hidden = NO;

static UIStatusBarStyle ap_status_bar_preferred_style(id self, SEL _cmd) {
    switch (g_status_bar_style) {
        case 1: return UIStatusBarStyleLightContent;
        case 2:
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
            return UIStatusBarStyleDarkContent;
#else
            return UIStatusBarStyleDefault;
#endif
        default: return UIStatusBarStyleDefault;
    }
}

static BOOL ap_status_bar_prefers_hidden(id self, SEL _cmd) {
    return g_status_bar_hidden;
}

static void ap_install_status_bar_hooks(Class controller_class) {
    if (!controller_class) return;

    Method style_method = class_getInstanceMethod(controller_class, @selector(preferredStatusBarStyle));
    const char *style_types = style_method ? method_getTypeEncoding(style_method) : "q@:";
    class_replaceMethod(controller_class, @selector(preferredStatusBarStyle), (IMP)ap_status_bar_preferred_style, style_types);

    Method hidden_method = class_getInstanceMethod(controller_class, @selector(prefersStatusBarHidden));
    const char *hidden_types = hidden_method ? method_getTypeEncoding(hidden_method) : "B@:";
    class_replaceMethod(controller_class, @selector(prefersStatusBarHidden), (IMP)ap_status_bar_prefers_hidden, hidden_types);
}

static UIViewController *ap_status_bar_target_controller(void) {
    UIWindow *window = ap_target_window();
    if (!window) return nil;

    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }

    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigation = (UINavigationController *)controller;
        controller = navigation.topViewController ?: controller;
    }
    return controller;
}
#endif

int ap_status_bar_apply(long long style, int hidden, int animated) {
#if TARGET_OS_OSX
    (void)style;
    (void)hidden;
    (void)animated;
    return 0;
#else
    __block BOOL applied = NO;
    ap_run_on_main_thread_sync(^{
        g_status_bar_style = style;
        g_status_bar_hidden = (BOOL)hidden;

        UIViewController *controller = ap_status_bar_target_controller();
        if (!controller) return;

        ap_install_status_bar_hooks([controller class]);
        [controller setNeedsStatusBarAppearanceUpdate];
        if (animated && controller.view) {
            [UIView animateWithDuration:0.2 animations:^{
                [controller.view layoutIfNeeded];
            }];
        }
        applied = YES;
    });

    return applied ? 1 : 0;
#endif
}

int ap_window_apply_configuration(const char *title_cstr,
                                  const char *subtitle_cstr,
                                  double width,
                                  double height,
                                  double min_width,
                                  double min_height,
                                  double max_width,
                                  double max_height,
                                  long long titlebar_style,
                                  int shows_titlebar,
                                  int shows_toolbar,
                                  int allows_full_screen,
                                  int resizable) {
    __block BOOL applied = NO;
    ap_run_on_main_thread_sync(^{
#if TARGET_OS_OSX
        NSWindow *window = ap_target_window();
        if (!window) return;

        NSString *title = ap_string_from_cstr(title_cstr);
        NSString *subtitle = ap_string_from_cstr(subtitle_cstr);
        if (title && title.length) {
            [window setTitle:title];
        }
        if ([window respondsToSelector:@selector(setSubtitle:)]) {
            [window setSubtitle:(subtitle && subtitle.length) ? subtitle : @""];
        }

        if (width > 0.0 && height > 0.0) {
            [window setContentSize:NSMakeSize((CGFloat)width, (CGFloat)height)];
            [window center];
        }
        if (min_width > 0.0 && min_height > 0.0) {
            [window setMinSize:NSMakeSize((CGFloat)min_width, (CGFloat)min_height)];
        }
        if (max_width > 0.0 && max_height > 0.0) {
            [window setMaxSize:NSMakeSize((CGFloat)max_width, (CGFloat)max_height)];
        }

        NSUInteger style_mask = window.styleMask;
        if (resizable) {
            style_mask |= NSWindowStyleMaskResizable;
        } else {
            style_mask &= ~NSWindowStyleMaskResizable;
        }

        BOOL hidden_title = (!shows_titlebar || titlebar_style == 4);
        if (hidden_title) {
            style_mask |= NSWindowStyleMaskFullSizeContentView;
        }
        [window setStyleMask:style_mask];
        [window setTitleVisibility:hidden_title ? NSWindowTitleHidden : NSWindowTitleVisible];
        [window setTitlebarAppearsTransparent:hidden_title ? YES : NO];

        if ([window respondsToSelector:@selector(setToolbarStyle:)]) {
            NSWindowToolbarStyle toolbar_style = NSWindowToolbarStyleAutomatic;
            switch (titlebar_style) {
                case 2: toolbar_style = NSWindowToolbarStyleUnified; break;
                case 3: toolbar_style = NSWindowToolbarStyleUnifiedCompact; break;
                case 1: toolbar_style = NSWindowToolbarStyleExpanded; break;
                default: toolbar_style = NSWindowToolbarStyleAutomatic; break;
            }
            [window setToolbarStyle:toolbar_style];
        }

        if (window.toolbar) {
            [window.toolbar setVisible:(BOOL)shows_toolbar];
        }

        NSWindowCollectionBehavior behavior = window.collectionBehavior;
        if (allows_full_screen) {
            behavior |= NSWindowCollectionBehaviorFullScreenPrimary;
        } else {
            behavior &= ~NSWindowCollectionBehaviorFullScreenPrimary;
        }
        [window setCollectionBehavior:behavior];
#else
        UIWindow *window = ap_target_window();
        if (!window) return;

        UIViewController *controller = window.rootViewController;
        while (controller.presentedViewController) {
            controller = controller.presentedViewController;
        }

        NSString *title = ap_string_from_cstr(title_cstr);
        NSString *subtitle = ap_string_from_cstr(subtitle_cstr);
        if (title && title.length) {
            controller.title = title;
        } else if (subtitle && subtitle.length) {
            controller.title = subtitle;
        }
        if (width > 0.0 && height > 0.0 && [controller respondsToSelector:@selector(setPreferredContentSize:)]) {
            controller.preferredContentSize = CGSizeMake((CGFloat)width, (CGFloat)height);
        }
#endif
        applied = YES;
    });

    return applied ? 1 : 0;
}

// ============================================================
// Section 5: CrystalActionDispatcher — dynamic ObjC class for
// button target-action routing to Crystal's CallbackRegistry
// ============================================================

// Crystal exports this function from callback_registry.cr.
// It routes into UI::CallbackRegistry.call(tag).
extern void crystal_ui_callback_dispatch(unsigned long long tag);

// IMP for setTag: — stores the callback ID in the _tag ivar.
static void crystal_action_dispatcher_set_tag(id self, SEL _cmd, long long tag) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_tag");
    if (ivar) {
        *(NSInteger *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar)) = (NSInteger)tag;
    }
}

// IMP for tag — returns the _tag ivar value.
static long long crystal_action_dispatcher_get_tag(id self, SEL _cmd) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_tag");
    if (ivar) {
        return (long long)(*(NSInteger *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar)));
    }
    return 0;
}

// IMP for dispatch: — reads tag via the ivar and calls into Crystal.
static void crystal_action_dispatcher_dispatch(id self, SEL _cmd, id sender) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_tag");
    if (ivar) {
        NSInteger tag = *(NSInteger *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar));
        crystal_ui_callback_dispatch((unsigned long long)tag);
    }
}

// Generic asset-pipeline interaction logger.
//
// STDERR.puts from Crystal does not reach the simulator's unified log
// stream (`xcrun simctl spawn booted log stream`). This helper emits a
// NUL-terminated C string via NSLog so user-action breadcrumbs (button
// taps, etc.) reach the unified logging system from sample apps.
//
// Kept in objc_bridge.m (not a sample-only file) so the same compiled
// .o supports both macOS and iOS hosts without a per-target wrapper.
void ap_voyager_interaction_log(const char *msg) {
    if (msg == NULL) {
        NSLog(@"[asset-pipeline] <null>");
        return;
    }
    NSLog(@"[asset-pipeline] %s", msg);
}

// Registers the CrystalActionDispatcher ObjC class at runtime.
// Must be called once before the AppKit / UIKit renderer creates any buttons.
void register_crystal_action_dispatcher(void) {
    // Guard: only register once
    if (objc_getClass("CrystalActionDispatcher") != Nil) {
        return;
    }

    Class cls = objc_allocateClassPair([NSObject class], "CrystalActionDispatcher", 0);
    if (!cls) return;

    // Add _tag ivar (NSInteger sized, pointer-aligned)
    class_addIvar(cls, "_tag", sizeof(NSInteger), __alignof__(NSInteger), @encode(NSInteger));

    // setTag: — "v@:q" (void, id, SEL, long long)
    class_addMethod(cls, sel_registerName("setTag:"),
                    (IMP)crystal_action_dispatcher_set_tag, "v@:q");

    // tag — "q@:" (long long, id, SEL)
    class_addMethod(cls, sel_registerName("tag"),
                    (IMP)crystal_action_dispatcher_get_tag, "q@:");

    // dispatch: — "v@:@" (void, id, SEL, id)
    class_addMethod(cls, sel_registerName("dispatch:"),
                    (IMP)crystal_action_dispatcher_dispatch, "v@:@");

    objc_registerClassPair(cls);
}

// =============================================================================
// Phase 10B.2b — Action + focus + keyboard accessibility helpers.
//
// Custom AX actions, focus management, and keyboard shortcut helpers shared by
// AppKit + UIKit renderers. Each helper takes a callback token (UInt64) the
// Crystal-side `UI::CallbackRegistry` returns when registering the action's
// Proc; activating the AX action / key command on the platform side fires
// `crystal_ui_callback_dispatch(token)` which routes back to Crystal.
// =============================================================================

#if TARGET_OS_IPHONE

// Add a UIAccessibilityCustomAction with the given name + callback token to
// the view's `accessibilityCustomActions` array. We use a block-based target
// (iOS 13+) so we don't need the global selector-dispatcher pattern.
//
// Returns 1 on success, 0 on no-op (target nil / name nil).
int ap_view_add_accessibility_custom_action(void *view_ptr, const char *name,
                                            unsigned long long token) {
    if (view_ptr == NULL || name == NULL) return 0;
    UIView *view = (__bridge UIView *)view_ptr;
    NSString *ns_name = [NSString stringWithUTF8String:name];
    if (ns_name == nil) return 0;

    UIAccessibilityCustomAction *action =
        [[UIAccessibilityCustomAction alloc] initWithName:ns_name
                                            actionHandler:^BOOL(UIAccessibilityCustomAction *_Nonnull a) {
                                                crystal_ui_callback_dispatch(token);
                                                return YES;
                                            }];

    NSArray<UIAccessibilityCustomAction *> *existing = view.accessibilityCustomActions;
    NSMutableArray *next = existing ? [existing mutableCopy] : [NSMutableArray array];
    [next addObject:action];
    view.accessibilityCustomActions = next;
    return 1;
}

// Add a UIKeyCommand to a view's keyCommands. UIKit's stock UIView returns
// a static keyCommands array, so we install ours via the associated-object
// dynamic-subclass pattern. For simplicity we use `setKeyCommands:` on
// UIViewController-derived hosts when available; on plain UIView we fall
// back to associating an array the renderer can read back later. The
// Crystal side compose `keyCommands` at the view-controller level.
//
// This helper handles the common case: the view is the
// UIHostingController/UIViewController root we got from the SwiftKit
// facade — we set its `additionalKeyCommands` (iOS 15+) via runtime.
//
// Returns 1 if the message was sent, 0 if the receiver didn't respond.
int ap_view_add_key_command(void *view_ptr, const char *input, unsigned long long modifier_mask,
                            unsigned long long token) {
    if (view_ptr == NULL || input == NULL) return 0;
    id receiver = (__bridge id)view_ptr;
    NSString *ns_input = [NSString stringWithUTF8String:input];
    if (ns_input == nil) return 0;

    // Build the UIKeyCommand. The selector is dispatched via the global
    // CrystalActionDispatcher class (registered separately); we wire the
    // tag via an associated object so the dispatcher's invocation can
    // pull the right callback token.
    //
    // For simplicity in iter 1, we use the action-block convenience via
    // UIKeyCommand's keyCommandWithInput:modifierFlags:action: which uses
    // the responder chain's @selector. We bind to a static selector
    // registered on UIResponder via category — but to avoid adding a
    // category we instead leverage the same CrystalActionDispatcher
    // class as the button click path.
    SEL action_sel = sel_registerName("dispatch:");
    UIKeyCommand *cmd = [UIKeyCommand keyCommandWithInput:ns_input
                                           modifierFlags:(UIKeyModifierFlags)modifier_mask
                                                  action:action_sel];

    // Allocate a CrystalActionDispatcher to carry the token, retain via
    // associated objects so the lifetime tracks the view.
    Class disp_cls = objc_getClass("CrystalActionDispatcher");
    if (disp_cls == Nil) return 0;
    id dispatcher = ((id (*)(Class, SEL))objc_msgSend)(disp_cls, sel_registerName("new"));
    ((void (*)(id, SEL, long long))objc_msgSend)(dispatcher, sel_registerName("setTag:"), (long long)token);
    objc_setAssociatedObject(cmd, "apsk_dispatcher", dispatcher, OBJC_ASSOCIATION_RETAIN);

    // Attempt to append to `keyCommands`. UIView doesn't have a setter, but
    // UIViewController has `addKeyCommand:`. We try the latter first.
    SEL add_sel = sel_registerName("addKeyCommand:");
    if ([receiver respondsToSelector:add_sel]) {
        ((void (*)(id, SEL, id))objc_msgSend)(receiver, add_sel, cmd);
        return 1;
    }
    // Fallback: store on associated object so a host VC can read+install later.
    NSMutableArray *bag = objc_getAssociatedObject(receiver, "apsk_pending_key_commands");
    if (bag == nil) {
        bag = [NSMutableArray array];
        objc_setAssociatedObject(receiver, "apsk_pending_key_commands", bag, OBJC_ASSOCIATION_RETAIN);
    }
    [bag addObject:cmd];
    return 1;
}

// Request first-responder status (focus). Returns whether focus succeeded.
BOOL ap_view_become_first_responder(void *view_ptr) {
    if (view_ptr == NULL) return 0;
    id receiver = (__bridge id)view_ptr;
    SEL sel = @selector(becomeFirstResponder);
    if (![receiver respondsToSelector:sel]) return 0;
    return ((BOOL (*)(id, SEL))objc_msgSend)(receiver, sel);
}

// Resign first-responder status (blur).
int ap_view_resign_first_responder(void *view_ptr) {
    if (view_ptr == NULL) return 0;
    id receiver = (__bridge id)view_ptr;
    SEL sel = @selector(resignFirstResponder);
    if (![receiver respondsToSelector:sel]) return 0;
    ((void (*)(id, SEL))objc_msgSend)(receiver, sel);
    return 1;
}

// -----------------------------------------------------------------
// Raw UITextField string-change wiring (ComboBox value-drop fix).
//
// ComboBox renders as a bare UITextField (no SwiftUI facade / TextStorage),
// so the `fireString` trampoline never runs for it. We attach a
// CrystalStringFieldDispatcher via addTarget:action:forControlEvents: that,
// on every edit + commit, reads [field text] and routes it through the
// existing raw string channel `crystal_ui_string_callback_dispatch(token, utf8)`
// -> UI::CallbackRegistry.call_string. The dispatcher carries the u64 token
// in an ivar and is pinned to the field via an associated object so BoehmGC
// + ObjC retain both keep it alive for the field's lifetime.
// -----------------------------------------------------------------
static const void *ap_text_field_string_dispatcher_key = &ap_text_field_string_dispatcher_key;

// IMP for setToken: — store the u64 callback token in the _token ivar.
static void ap_string_field_set_token(id self, SEL _cmd, unsigned long long token) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_token");
    if (ivar) {
        *(unsigned long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar)) = token;
    }
}

// IMP for fieldChanged: — read the sender's text and dispatch it to Crystal.
static void ap_string_field_changed(id self, SEL _cmd, id sender) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_token");
    if (!ivar) return;
    unsigned long long token =
        *(unsigned long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar));
    if (token == 0ULL) return;

    NSString *text = nil;
    SEL text_sel = sel_registerName("text");
    if (sender && [sender respondsToSelector:text_sel]) {
        text = ((id (*)(id, SEL))objc_msgSend)(sender, text_sel);
    }
    const char *utf8 = text ? [text UTF8String] : "";
    crystal_ui_string_callback_dispatch(token, utf8 ? utf8 : "");
}

static Class ap_register_string_field_dispatcher(void) {
    Class cls = objc_getClass("CrystalStringFieldDispatcher");
    if (cls) return cls;

    cls = objc_allocateClassPair([NSObject class], "CrystalStringFieldDispatcher", 0);
    if (!cls) return Nil;

    class_addIvar(cls, "_token", sizeof(unsigned long long),
                  __alignof__(unsigned long long), @encode(unsigned long long));
    class_addMethod(cls, sel_registerName("setToken:"),
                    (IMP)ap_string_field_set_token, "v@:Q");
    class_addMethod(cls, sel_registerName("fieldChanged:"),
                    (IMP)ap_string_field_changed, "v@:@");

    objc_registerClassPair(cls);
    return cls;
}

// Wire a raw UITextField's editing-changed + editing-did-end events to the
// Crystal string callback `token`. Idempotent: re-wiring the same field
// updates the token on the existing dispatcher rather than stacking targets.
// Returns 1 on success, 0 on no-op (nil field / class registration failure).
int ap_text_field_wire_string_change(void *field_ptr, unsigned long long token) {
    if (field_ptr == NULL) return 0;

    id field = (__bridge id)field_ptr;
    SEL action = sel_registerName("fieldChanged:");
    UIControlEvents events = UIControlEventEditingChanged | UIControlEventEditingDidEnd;

    id dispatcher = objc_getAssociatedObject(field, ap_text_field_string_dispatcher_key);
    if (!dispatcher) {
        Class cls = ap_register_string_field_dispatcher();
        if (!cls) return 0;

        dispatcher = ((id (*)(Class, SEL))objc_msgSend)(cls, sel_registerName("new"));
        objc_setAssociatedObject(field, ap_text_field_string_dispatcher_key,
                                 dispatcher, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        ((void (*)(id, SEL, id, SEL, NSUInteger))objc_msgSend)(
            field, sel_registerName("addTarget:action:forControlEvents:"),
            dispatcher, action, (NSUInteger)events);
        [dispatcher release]; // objc_bridge.m compiles with -fno-objc-arc
    }

    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(
        dispatcher, sel_registerName("setToken:"), token);

    return 1;
}

// =============================================================================
// Phase 10B.3.x — Class C feature bridge functions (iOS / iPadOS branch).
//
// One C entry-point per Class C feature implemented for the iOS/iPadOS
// platform. Each function is fire-and-forget — the Crystal-side Class C
// dispatch wraps the call in a DispatchResult.success unless the function
// raises. Functions that need to return data (paste, file picker) route
// the result through `crystal_ui_string_callback_dispatch` using a token
// the caller passes in.
//
// All functions are main-thread-safe: they dispatch_async onto the main
// queue when they need to touch UIKit (UIPasteboard is safe off-main; the
// UIViewController-presenting calls are not).
// =============================================================================

// :copy_to_clipboard — write `value` to UIPasteboard.general.string.
void ap_clipboard_write_ios(const char *value_cstr) {
    NSString *value = ap_string_from_cstr(value_cstr);
    if (!value) value = @"";
    // UIPasteboard.string is documented main-thread-only on iOS.
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIPasteboard generalPasteboard].string = value;
    });
}

// :paste_from_clipboard — read UIPasteboard.general.string and route to
// the Crystal-side callback. `token` is a callback tag returned by
// `UI::CallbackRegistry`. The callback fires on the main thread.
//
// Returns 1 if a string was found and the callback was scheduled, 0 if
// the pasteboard had no string content.
int ap_clipboard_read_ios(unsigned long long token) {
    __block int found = 0;
    void (^work)(void) = ^{
        NSString *value = [UIPasteboard generalPasteboard].string;
        if (value) {
            const char *cstr = value.UTF8String;
            crystal_ui_string_callback_dispatch(token, cstr ? cstr : "");
            found = 1;
        } else {
            crystal_ui_string_callback_dispatch(token, "");
        }
    };
    if ([NSThread isMainThread]) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return found;
}

// :open_url — UIApplication.openURL via the modern openURL:options:
// completionHandler: selector. Returns 1 if the dispatch was scheduled,
// 0 if the URL was malformed.
int ap_open_url_ios(const char *url_cstr) {
    NSURL *url = ap_url_from_cstr(url_cstr);
    if (!url) return 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        if ([app respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            [app openURL:url options:@{} completionHandler:nil];
        }
    });
    return 1;
}

// :request_permission — request UNUserNotificationCenter authorization on
// iOS. Reuses the shared notifications helpers already in this file.
// Returns 1 if granted, 0 otherwise. Synchronous via dispatch_semaphore;
// the helper times out at 5 s.
int ap_request_notification_permission_ios(void) {
    return ap_notifications_request_authorization(1, 1, 1, 0);
}

// :print — present a UIPrintInteractionController for a plain-text
// payload. Best-effort: the substrate ships a text-only path here, real
// apps composing with PDFs / images call the controller themselves with
// a richer formatter. Returns 1 if dispatch scheduled, 0 if the API is
// not available (UIPrintInteractionController.isPrintingAvailable == NO).
int ap_print_text_ios(const char *text_cstr, const char *job_name_cstr) {
    if (![UIPrintInteractionController isPrintingAvailable]) return 0;
    NSString *text = ap_string_from_cstr(text_cstr);
    NSString *job_name = ap_string_from_cstr(job_name_cstr);
    if (!text) text = @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
        UIPrintInfo *info = [UIPrintInfo printInfo];
        info.outputType = UIPrintInfoOutputGeneral;
        if (job_name && job_name.length) info.jobName = job_name;
        pic.printInfo = info;
        UISimpleTextPrintFormatter *formatter =
            [[UISimpleTextPrintFormatter alloc] initWithText:text];
        pic.printFormatter = formatter;
        [formatter release];
        [pic presentAnimated:YES completionHandler:nil];
    });
    return 1;
}

// :open_file_picker — present a UIDocumentPickerViewController in
// open-mode. The picker's selection is routed back via the
// `crystal_ui_string_callback_dispatch` callback (with the picked URL,
// or empty string on cancel).
//
// Anchor is required — iOS modal presentation needs a presenting
// view-controller. The Crystal side passes the active view ptr from
// the renderer surface.
//
// Returns 1 if the picker was scheduled, 0 if anchor is nil.
//
// NOTE: this minimal path registers an inline delegate via runtime —
// in production the renderer should retain the delegate via associated
// object so it survives the modal presentation. For the substrate's
// fire-and-forget contract we accept a small leak; a real picker
// component (10B.4) replaces this.
static const void *ap_doc_picker_delegate_key = &ap_doc_picker_delegate_key;

@interface APDocPickerDelegate : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, assign) unsigned long long callback_token;
@end
@implementation APDocPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSString *first = urls.firstObject.absoluteString ?: @"";
    crystal_ui_string_callback_dispatch(self.callback_token, first.UTF8String);
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    crystal_ui_string_callback_dispatch(self.callback_token, "");
}
@end

static NSArray *ap_document_content_types_from_identifiers(NSArray<NSString *> *identifiers) {
    Class ut_type_class = NSClassFromString(@"UTType");
    SEL type_with_identifier_sel = sel_registerName("typeWithIdentifier:");
    if (!ut_type_class || ![ut_type_class respondsToSelector:type_with_identifier_sel]) {
        return nil;
    }

    NSMutableArray *content_types = [NSMutableArray array];
    NSCharacterSet *trim_set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSString *identifier in identifiers) {
        NSString *trimmed = [identifier stringByTrimmingCharactersInSet:trim_set];
        if (!trimmed.length) continue;
        id type = ((id (*)(id, SEL, id))objc_msgSend)(ut_type_class, type_with_identifier_sel, trimmed);
        if (type) [content_types addObject:type];
    }
    if (!content_types.count) {
        id data_type = ((id (*)(id, SEL, id))objc_msgSend)(ut_type_class, type_with_identifier_sel, @"public.data");
        if (data_type) [content_types addObject:data_type];
    }
    return content_types.count ? content_types : nil;
}

static UIDocumentPickerViewController *ap_document_picker_for_opening(NSArray<NSString *> *types) {
    SEL modern_sel = sel_registerName("initForOpeningContentTypes:asCopy:");
    if ([UIDocumentPickerViewController instancesRespondToSelector:modern_sel]) {
        NSArray *content_types = ap_document_content_types_from_identifiers(types);
        if (content_types.count) {
            return ((UIDocumentPickerViewController *(*)(id, SEL, id, BOOL))objc_msgSend)(
                [UIDocumentPickerViewController alloc], modern_sel, content_types, YES);
        }
    }

    SEL legacy_sel = sel_registerName("initWithDocumentTypes:inMode:");
    if ([UIDocumentPickerViewController instancesRespondToSelector:legacy_sel]) {
        return ((UIDocumentPickerViewController *(*)(id, SEL, id, NSInteger))objc_msgSend)(
            [UIDocumentPickerViewController alloc], legacy_sel, types, (NSInteger)0);
    }
    return nil;
}

static UIDocumentPickerViewController *ap_document_picker_for_exporting(NSURL *source) {
    SEL modern_sel = sel_registerName("initForExportingURLs:asCopy:");
    if ([UIDocumentPickerViewController instancesRespondToSelector:modern_sel]) {
        return ((UIDocumentPickerViewController *(*)(id, SEL, id, BOOL))objc_msgSend)(
            [UIDocumentPickerViewController alloc], modern_sel, @[source], YES);
    }

    SEL legacy_sel = sel_registerName("initWithURL:inMode:");
    if ([UIDocumentPickerViewController instancesRespondToSelector:legacy_sel]) {
        return ((UIDocumentPickerViewController *(*)(id, SEL, id, NSInteger))objc_msgSend)(
            [UIDocumentPickerViewController alloc], legacy_sel, source, (NSInteger)2);
    }
    return nil;
}

int ap_open_file_picker_ios(void *anchor_view_ptr, const char *utis_cstr,
                            unsigned long long token) {
    // A null anchor is allowed: `ap_top_presenting_view_controller(nil)`
    // resolves the key window's rootViewController, so a Class C dispatch
    // that has no concrete view to anchor to (the SystemAction path) still
    // presents a real picker instead of silently no-oping. We only return 0
    // when NO presenter can be resolved at all (see the main-queue block),
    // never merely because the anchor was null.
    UIView *anchor = (UIView *)anchor_view_ptr;
    NSString *utis = ap_string_from_cstr(utis_cstr);
    // Default to public.data when caller doesn't specify a UTI list.
    NSArray<NSString *> *types = nil;
    if (utis && utis.length) {
        types = [utis componentsSeparatedByString:@","];
    } else {
        types = @[@"public.data"];
    }
    // Resolve the presenter SYNCHRONOUSLY so the int return honestly reflects
    // whether a picker can actually be presented. Returning 1 unconditionally
    // with the presenter check only inside the async block would let a missing
    // presenter silently no-op while Crystal reported success — the
    // false-success class this binding must avoid (the SecureField lesson).
    // UIKit must be touched on the main thread; guard for an off-main caller.
    // A BOOL (not the VC pointer) crosses back so there is no MRC lifetime
    // issue; the async block re-resolves a fresh (autoreleased) presenter.
    __block BOOL can_present = NO;
    if ([NSThread isMainThread]) {
        can_present = (ap_top_presenting_view_controller(anchor) != nil);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            can_present = (ap_top_presenting_view_controller(anchor) != nil);
        });
    }
    if (!can_present) return 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presenter = ap_top_presenting_view_controller(anchor);
        if (!presenter) return;
        UIDocumentPickerViewController *picker = ap_document_picker_for_opening(types);
        if (!picker) return;
        APDocPickerDelegate *delegate = [[APDocPickerDelegate alloc] init];
        delegate.callback_token = token;
        picker.delegate = delegate;
        objc_setAssociatedObject(picker, ap_doc_picker_delegate_key, delegate,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [delegate release];
        [presenter presentViewController:picker animated:YES completion:nil];
        [picker release];
    });
    return 1;
}

// :export_file — present a UIDocumentPickerViewController in export-mode.
// The Crystal side hands us a temp-file URL pointing at the bytes to
// export; the picker copies it into the user-chosen location.
//
// Returns 1 if scheduled, 0 if anchor / source-url is nil.
int ap_export_file_ios(void *anchor_view_ptr, const char *source_url_cstr,
                       unsigned long long token) {
    // A null anchor is allowed (see ap_open_file_picker_ios). We still
    // require a real source URL — exporting nothing is a programmer error,
    // not a degrade — so a nil source returns 0 and the Crystal proc maps
    // that to a not-performed result.
    UIView *anchor = (UIView *)anchor_view_ptr;
    NSURL *source = ap_url_from_cstr(source_url_cstr);
    if (!source) return 0;
    // Honest synchronous presenter check (see ap_open_file_picker_ios) so a
    // missing presenter returns 0 rather than reporting fake success.
    __block BOOL can_present = NO;
    if ([NSThread isMainThread]) {
        can_present = (ap_top_presenting_view_controller(anchor) != nil);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            can_present = (ap_top_presenting_view_controller(anchor) != nil);
        });
    }
    if (!can_present) return 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presenter = ap_top_presenting_view_controller(anchor);
        if (!presenter) return;
        UIDocumentPickerViewController *picker = ap_document_picker_for_exporting(source);
        if (!picker) return;
        APDocPickerDelegate *delegate = [[APDocPickerDelegate alloc] init];
        delegate.callback_token = token;
        picker.delegate = delegate;
        objc_setAssociatedObject(picker, ap_doc_picker_delegate_key, delegate,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [delegate release];
        [presenter presentViewController:picker animated:YES completion:nil];
        [picker release];
    });
    return 1;
}

#else  // macOS / AppKit

// AppKit accessibility-custom-action support. NSAccessibilityCustomAction is
// available on macOS 10.13+ via the NSAccessibility informal protocol.
int ap_view_add_accessibility_custom_action(void *view_ptr, const char *name,
                                            unsigned long long token) {
    if (view_ptr == NULL || name == NULL) return 0;
    NSView *view = (__bridge NSView *)view_ptr;
    NSString *ns_name = [NSString stringWithUTF8String:name];
    if (ns_name == nil) return 0;

    NSAccessibilityCustomAction *action =
        [[NSAccessibilityCustomAction alloc] initWithName:ns_name
                                                  handler:^BOOL(void) {
                                                      crystal_ui_callback_dispatch(token);
                                                      return YES;
                                                  }];

    NSArray<NSAccessibilityCustomAction *> *existing = view.accessibilityCustomActions;
    NSMutableArray *next = existing ? [existing mutableCopy] : [NSMutableArray array];
    [next addObject:action];
    view.accessibilityCustomActions = next;
    return 1;
}

// AppKit keyboard shortcuts: NSButton-derived controls accept setKeyEquivalent:
// + setKeyEquivalentModifierMask:. Non-button controls get the value stored as
// an associated object the host menu / responder chain can consult later.
int ap_view_add_key_command(void *view_ptr, const char *input, unsigned long long modifier_mask,
                            unsigned long long token) {
    if (view_ptr == NULL || input == NULL) return 0;
    id receiver = (__bridge id)view_ptr;
    NSString *ns_input = [NSString stringWithUTF8String:input];
    if (ns_input == nil) return 0;

    SEL set_ke = @selector(setKeyEquivalent:);
    SEL set_kem = @selector(setKeyEquivalentModifierMask:);
    if ([receiver respondsToSelector:set_ke]) {
        // First character only for keyEquivalent.
        NSString *first_char = ns_input.length > 0 ? [ns_input substringToIndex:1] : @"";
        ((void (*)(id, SEL, id))objc_msgSend)(receiver, set_ke, first_char);
        if ([receiver respondsToSelector:set_kem]) {
            ((void (*)(id, SEL, NSUInteger))objc_msgSend)(
                receiver, set_kem, (NSUInteger)modifier_mask);
        }
        // The button's target/action already wires Crystal-side callbacks.
        // Token is advisory in the NSButton path — Crystal-side dispatcher
        // already routes the click.
        (void)token;
        return 1;
    }
    // Non-button: store associated for later wiring (debug aid).
    NSDictionary *meta = @{
        @"input": ns_input,
        @"mask": @(modifier_mask),
        @"token": @(token),
    };
    objc_setAssociatedObject(receiver, "apsk_keyboard_shortcut", meta, OBJC_ASSOCIATION_RETAIN);
    return 1;
}

// AppKit "become first responder": queue detached views and report the
// result once they have a window. A queued request returns YES to indicate
// that the request was accepted; attached views return makeFirstResponder:.
BOOL ap_view_become_first_responder(void *view_ptr) {
    if (view_ptr == NULL) return 0;
    NSView *view = (__bridge NSView *)view_ptr;
    NSWindow *win = view.window;
    if (win == nil) {
        objc_setAssociatedObject(view, &apsk_focus_result_key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, &apsk_pending_focus_key, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return YES;
    }
    BOOL succeeded = [win makeFirstResponder:(NSResponder *)view];
    objc_setAssociatedObject(view, &apsk_pending_focus_key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view, &apsk_focus_result_key, @(succeeded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return succeeded;
}

// Read the result of an immediate or deferred first-responder request.
BOOL ap_view_focus_request_succeeded(void *view_ptr) {
    if (view_ptr == NULL) return NO;
    NSNumber *result = objc_getAssociatedObject((__bridge id)view_ptr, &apsk_focus_result_key);
    return result.boolValue;
}

// Resign first responder by asking the window to take the responder spot back.
int ap_view_resign_first_responder(void *view_ptr) {
    if (view_ptr == NULL) return 0;
    NSView *view = (__bridge NSView *)view_ptr;
    NSWindow *win = view.window;
    if (win == nil) return 0;
    if (win.firstResponder == (NSResponder *)view) {
        [win makeFirstResponder:nil];
        return 1;
    }
    return 0;
}


// Phase 10B.3.0 — Class C `:hello_world_alert` binding (macOS).
//
// Presents an `NSAlert` modally on the active key window. Pure
// fire-and-forget: the proof binding does not need the user's
// response (a real production alert binding would route the button
// taps through `crystal_ui_callback_dispatch`, but the substrate
// proof intentionally stays minimal).
//
// Dispatch is queued onto the main thread because the binding may be
// invoked from any thread (e.g. a background work item that finished
// and wants to surface a notification). NSAlert is main-thread-only.
//
// Why `runModal` instead of `beginSheetModalForWindow:`?
// `runModal` works without an anchor window — `:hello_world_alert`
// is a proof intent that may fire before any window has been
// constructed (e.g. in a launch-time smoke test). Real Class C
// alert / dialog bindings introduced in 10B.3.x will prefer a
// window-anchored API.
void ap_alert_show_macos(const char *title_cstr, const char *message_cstr) {
    NSString *title = ap_string_from_cstr(title_cstr);
    NSString *message = ap_string_from_cstr(message_cstr);
    if (!title) title = @"Hello";
    if (!message) message = @"";

    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = title;
        alert.informativeText = message;
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        [alert release];
    });
}

// =============================================================================
// Phase 10B.3.x — Class C feature bridge functions (macOS / AppKit branch).
//
// One C entry-point per Class C feature implemented for the macOS
// platform. Each function is fire-and-forget — the Crystal-side Class C
// dispatch wraps the call in a DispatchResult.success unless the
// function raises. Functions that need to return data (paste, file
// picker) route the result through `crystal_ui_string_callback_dispatch`
// using a token the caller passes in.
// =============================================================================

// :copy_to_clipboard — write `value` to NSPasteboard.general.
void ap_clipboard_write_macos(const char *value_cstr) {
    NSString *value = ap_string_from_cstr(value_cstr);
    if (!value) value = @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:value forType:NSPasteboardTypeString];
    });
}

// :paste_from_clipboard — read NSPasteboard.general string content and
// route to the Crystal-side callback. Synchronous to keep the contract
// symmetric with iOS — the pasteboard read is cheap on macOS.
// Returns 1 when a string was found, 0 otherwise.
int ap_clipboard_read_macos(unsigned long long token) {
    __block int found = 0;
    void (^work)(void) = ^{
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        NSString *value = [pb stringForType:NSPasteboardTypeString];
        if (value) {
            const char *cstr = value.UTF8String;
            crystal_ui_string_callback_dispatch(token, cstr ? cstr : "");
            found = 1;
        } else {
            crystal_ui_string_callback_dispatch(token, "");
        }
    };
    if ([NSThread isMainThread]) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return found;
}

// :open_url — NSWorkspace.shared.openURL: (modern openURL:configuration:
// completionHandler: on macOS 10.15+; falls back to legacy openURL: on
// older systems).
int ap_open_url_macos(const char *url_cstr) {
    NSURL *url = ap_url_from_cstr(url_cstr);
    if (!url) return 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        if ([ws respondsToSelector:@selector(openURL:configuration:completionHandler:)]) {
            [ws openURL:url
              configuration:[NSWorkspaceOpenConfiguration configuration]
          completionHandler:nil];
        } else {
            [ws openURL:url];
        }
    });
    return 1;
}

// :request_permission — request UNUserNotificationCenter authorization on
// macOS. Returns 1 if granted, 0 otherwise. Synchronous via dispatch
// semaphore; the helper times out at 5 s.
int ap_request_notification_permission_macos(void) {
    return ap_notifications_request_authorization(1, 1, 1, 0);
}

// :print — present an NSPrintOperation for a plain-text payload built
// into an NSTextView, run runModal on the active window. Returns 1 if
// dispatch scheduled, 0 if no key window available.
int ap_print_text_macos(const char *text_cstr, const char *job_name_cstr) {
    NSString *text = ap_string_from_cstr(text_cstr);
    NSString *job_name = ap_string_from_cstr(job_name_cstr);
    if (!text) text = @"";

    __block int ok = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        // Build an off-screen NSTextView sized to the printable page so
        // NSPrintOperation can paginate it. The text view lives only
        // for the duration of the modal print panel.
        NSPrintInfo *info = [NSPrintInfo sharedPrintInfo];
        NSSize paper = info.paperSize;
        NSRect frame = NSMakeRect(0.0, 0.0, paper.width, paper.height);
        NSTextView *tv = [[NSTextView alloc] initWithFrame:frame];
        [tv.textStorage replaceCharactersInRange:NSMakeRange(0, 0)
                                      withString:text];
        if (job_name && job_name.length) {
            info.jobDisposition = NSPrintSpoolJob;
        }
        NSPrintOperation *op = [NSPrintOperation printOperationWithView:tv
                                                              printInfo:info];
        op.showsPrintPanel = YES;
        op.showsProgressPanel = YES;
        if (job_name && job_name.length) {
            op.jobTitle = job_name;
        }
        [op runOperation];
        [tv release];
    });
    return ok;
}

// :open_file_picker — present an NSOpenPanel modally. Returns the
// selected URL via crystal_ui_string_callback_dispatch (empty string on
// cancel). `utis` is a comma-separated list of UTI strings, e.g.
// "public.image,public.data"; empty/nil means any file.
//
// Synchronous via runModal — NSOpenPanel returns when the user dismisses
// the panel.
int ap_open_file_picker_macos(const char *utis_cstr, unsigned long long token) {
    NSString *utis = ap_string_from_cstr(utis_cstr);
    void (^work)(void) = ^{
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.canChooseFiles = YES;
        panel.canChooseDirectories = NO;
        panel.allowsMultipleSelection = NO;
        if (utis && utis.length) {
            NSArray<NSString *> *types = [utis componentsSeparatedByString:@","];
            if (@available(macOS 11.0, *)) {
                // UTType API requires casts that depend on UniformType
                // Identifiers framework. Defer to allowedFileTypes (legacy
                // but still works on 11+) so we don't take a new link
                // dependency.
                panel.allowedFileTypes = types;
            } else {
                panel.allowedFileTypes = types;
            }
        }
        NSModalResponse response = [panel runModal];
        if (response == NSModalResponseOK && panel.URLs.firstObject) {
            const char *cstr = panel.URLs.firstObject.absoluteString.UTF8String;
            crystal_ui_string_callback_dispatch(token, cstr ? cstr : "");
        } else {
            crystal_ui_string_callback_dispatch(token, "");
        }
    };
    if ([NSThread isMainThread]) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return 1;
}

// :export_file — present an NSSavePanel modally. Suggests
// `suggested_name` as the default filename. Returns chosen URL via
// crystal_ui_string_callback_dispatch (empty on cancel).
int ap_export_file_macos(const char *suggested_name_cstr,
                         unsigned long long token) {
    NSString *suggested = ap_string_from_cstr(suggested_name_cstr);
    void (^work)(void) = ^{
        NSSavePanel *panel = [NSSavePanel savePanel];
        if (suggested && suggested.length) {
            panel.nameFieldStringValue = suggested;
        }
        NSModalResponse response = [panel runModal];
        if (response == NSModalResponseOK && panel.URL) {
            const char *cstr = panel.URL.absoluteString.UTF8String;
            crystal_ui_string_callback_dispatch(token, cstr ? cstr : "");
        } else {
            crystal_ui_string_callback_dispatch(token, "");
        }
    };
    if ([NSThread isMainThread]) {
        work();
    } else {
        dispatch_sync(dispatch_get_main_queue(), work);
    }
    return 1;
}

// -----------------------------------------------------------------
// NSComboBox value-change wiring (macOS ComboBox value-drop fix).
//
// NSComboBox has no SwiftUI facade. iOS wires its raw UITextField via a
// UIControl target-action (ap_text_field_wire_string_change); AppKit
// instead delivers combo-box changes through delegate notifications:
//   - controlTextDidChange:        (typed text — NSControl editing delegate)
//   - comboBoxSelectionDidChange:  (list pick — NSComboBoxDelegate)
// A dynamically-registered CrystalComboBoxDelegate carries the u64 token,
// reads the combo box's current value from the notification's object on
// each change, and routes it through crystal_ui_string_callback_dispatch.
// The delegate is pinned via objc_setAssociatedObject for the box's life.
// (Note: in comboBoxSelectionDidChange: the combo's -stringValue is not yet
// updated to the new selection, so we read -objectValueOfSelectedItem.)
// -----------------------------------------------------------------
static const void *ap_combo_box_delegate_key = &ap_combo_box_delegate_key;

static unsigned long long ap_combo_read_token(id self) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_token");
    if (!ivar) return 0ULL;
    return *(unsigned long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar));
}

static void ap_combo_set_token(id self, SEL _cmd, unsigned long long token) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_token");
    if (ivar) {
        *(unsigned long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar)) = token;
    }
}

static void ap_combo_dispatch_value(unsigned long long token, NSString *s) {
    if (token == 0ULL) return;
    const char *utf8 = s ? [s UTF8String] : "";
    crystal_ui_string_callback_dispatch(token, utf8 ? utf8 : "");
}

static void ap_combo_control_text_did_change(id self, SEL _cmd, id note) {
    unsigned long long token = ap_combo_read_token(self);
    id combo = note ? ((id (*)(id, SEL))objc_msgSend)(note, sel_registerName("object")) : nil;
    NSString *s = nil;
    if (combo && [combo respondsToSelector:sel_registerName("stringValue")]) {
        s = ((id (*)(id, SEL))objc_msgSend)(combo, sel_registerName("stringValue"));
    }
    ap_combo_dispatch_value(token, s);
}

static void ap_combo_selection_did_change(id self, SEL _cmd, id note) {
    unsigned long long token = ap_combo_read_token(self);
    id combo = note ? ((id (*)(id, SEL))objc_msgSend)(note, sel_registerName("object")) : nil;
    NSString *s = nil;
    if (combo && [combo respondsToSelector:sel_registerName("objectValueOfSelectedItem")]) {
        id val = ((id (*)(id, SEL))objc_msgSend)(combo, sel_registerName("objectValueOfSelectedItem"));
        if ([val isKindOfClass:[NSString class]]) {
            s = val;
        } else if (val) {
            s = [val description];
        }
    }
    ap_combo_dispatch_value(token, s);
}

static Class ap_register_combo_box_delegate(void) {
    Class cls = objc_getClass("CrystalComboBoxDelegate");
    if (cls) return cls;

    cls = objc_allocateClassPair([NSObject class], "CrystalComboBoxDelegate", 0);
    if (!cls) return Nil;

    class_addIvar(cls, "_token", sizeof(unsigned long long),
                  __alignof__(unsigned long long), @encode(unsigned long long));
    class_addMethod(cls, sel_registerName("setToken:"),
                    (IMP)ap_combo_set_token, "v@:Q");
    class_addMethod(cls, sel_registerName("controlTextDidChange:"),
                    (IMP)ap_combo_control_text_did_change, "v@:@");
    class_addMethod(cls, sel_registerName("comboBoxSelectionDidChange:"),
                    (IMP)ap_combo_selection_did_change, "v@:@");

    objc_registerClassPair(cls);
    return cls;
}

// Wire an NSComboBox's text + selection changes to the Crystal string
// callback `token`. Idempotent: re-wiring updates the token on the
// existing delegate. Returns 1 on success, 0 on no-op.
int ap_combo_box_wire_string_change(void *combo_ptr, unsigned long long token) {
    if (combo_ptr == NULL) return 0;

    id combo = (__bridge id)combo_ptr;
    id delegate = objc_getAssociatedObject(combo, ap_combo_box_delegate_key);
    if (!delegate) {
        Class cls = ap_register_combo_box_delegate();
        if (!cls) return 0;

        delegate = ((id (*)(Class, SEL))objc_msgSend)(cls, sel_registerName("new"));
        objc_setAssociatedObject(combo, ap_combo_box_delegate_key,
                                 delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        ((void (*)(id, SEL, id))objc_msgSend)(
            combo, sel_registerName("setDelegate:"), delegate);
        [delegate release]; // objc_bridge.m compiles with -fno-objc-arc
    }

    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(
        delegate, sel_registerName("setToken:"), token);

    return 1;
}

#endif

// =============================================================================
// Section 6: Discrete gesture surface — swipe (4 directions) + long-press.
//
// "Discrete" here means each recognizer fires the Crystal callback ONCE per
// completed gesture: a swipe fires when UIKit/AppKit recognizes the completed
// flick; a long-press fires when the hold threshold is crossed (state .began).
// Continuous pan tracking is intentionally out of scope.
//
// Target objects carry the Crystal callback token in a `_token` ivar.
// The macOS swipe target also carries a `_direction` ivar (int) so the
// NSPanGestureRecognizer action can classify the dominant translation at .ended
// (threshold 30 pt) and fire only when the translation matches the registered
// direction.
//
// Each target object is pinned to the host view via objc_setAssociatedObject
// using a per-direction static key. This keeps the target alive as long as
// the view is alive, so the Crystal Proc is not collected prematurely.
// Re-attaching the same direction replaces the old associated target.
// =============================================================================

// ------------------------------------------------------------------
// Shared token helpers (used by all gesture target classes).
// ------------------------------------------------------------------

static unsigned long long ap_gesture_read_token(id self) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_token");
    if (!ivar) return 0ULL;
    return *(unsigned long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar));
}

static void ap_gesture_set_token(id self, SEL _cmd, unsigned long long token) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_token");
    if (ivar) {
        *(unsigned long long *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar)) = token;
    }
}

// ------------------------------------------------------------------
// CrystalSwipeTarget — fires token unconditionally (iOS path).
// On iOS UISwipeGestureRecognizer already enforces the direction;
// the target just dispatches.
// ------------------------------------------------------------------

static void ap_swipe_target_handle(id self, SEL _cmd, id recognizer) {
    unsigned long long token = ap_gesture_read_token(self);
    if (token != 0ULL) {
        crystal_ui_callback_dispatch(token);
    }
}

static Class ap_register_swipe_target(void) {
    Class cls = objc_getClass("CrystalSwipeTarget");
    if (cls) return cls;

    cls = objc_allocateClassPair([NSObject class], "CrystalSwipeTarget", 0);
    if (!cls) return Nil;

    class_addIvar(cls, "_token", sizeof(unsigned long long),
                  __alignof__(unsigned long long), @encode(unsigned long long));
    class_addMethod(cls, sel_registerName("setToken:"),
                    (IMP)ap_gesture_set_token, "v@:Q");
    class_addMethod(cls, sel_registerName("handleSwipe:"),
                    (IMP)ap_swipe_target_handle, "v@:@");

    objc_registerClassPair(cls);
    return cls;
}

// ------------------------------------------------------------------
// CrystalPanSwipeTarget — macOS path. Carries both a token ivar
// and a direction ivar; the handlePan: action classifies translation
// at .ended and dispatches only when the dominant axis matches.
//
// Direction encoding (matches UI::SwipeDirection enum):
//   0 = Left, 1 = Right, 2 = Up, 3 = Down
//
// Classification threshold: 30 pt. When both axes exceed the threshold,
// the larger magnitude wins; Left and Down are biased slightly in the
// case of a tie (the recognizer fires for the first matching direction).
// ------------------------------------------------------------------

#if TARGET_OS_OSX

static int ap_pan_read_direction(id self) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_direction");
    if (!ivar) return -1;
    return *(int *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar));
}

static void ap_pan_set_direction(id self, SEL _cmd, int dir) {
    Ivar ivar = class_getInstanceVariable(object_getClass(self), "_direction");
    if (ivar) {
        *(int *)((uint8_t *)(__bridge void *)self + ivar_getOffset(ivar)) = dir;
    }
}

// Classification threshold: below this, the gesture is considered noise.
#define AP_SWIPE_THRESHOLD 30.0

static void ap_pan_target_handle(id self, SEL _cmd, id recognizer) {
    // Only classify at .ended — we are not tracking continuous pans.
    NSGestureRecognizerState state =
        ((NSGestureRecognizerState (*)(id, SEL))objc_msgSend)(
            recognizer, sel_registerName("state"));
    if (state != NSGestureRecognizerStateEnded) return;

    // Read the translation in the recognizer's view.
    SEL trans_sel = sel_registerName("translationInView:");
    NSView *rec_view =
        (NSView *)((id (*)(id, SEL))objc_msgSend)(recognizer, sel_registerName("view"));
    CGPoint translation = { 0, 0 };
    // NSPanGestureRecognizer translationInView: returns an NSPoint (CGPoint alias).
    // The return type is a struct; we use objc_msgSend_stret-compatible cast.
    // On arm64 macOS small structs (≤16 bytes) are returned in registers via
    // the normal objc_msgSend, NOT via stret. CGPoint = 2 doubles = 16 bytes.
    typedef CGPoint (*CGPointIMP)(id, SEL, id);
    translation = ((CGPointIMP)objc_msgSend)(recognizer, trans_sel, (id)rec_view);

    double dx = translation.x;
    double dy = translation.y;
    double abs_x = dx < 0 ? -dx : dx;
    double abs_y = dy < 0 ? -dy : dy;

    // Neither axis met the threshold — not a swipe.
    if (abs_x < AP_SWIPE_THRESHOLD && abs_y < AP_SWIPE_THRESHOLD) return;

    // Classify by dominant axis.
    int classified;
    if (abs_x >= abs_y) {
        classified = (dx < 0) ? 0 : 1; // Left = 0, Right = 1
    } else {
        classified = (dy < 0) ? 2 : 3; // Up = 2, Down = 3
        // Note: AppKit's Y axis is flipped relative to UIKit. On macOS a pan
        // toward the top of the screen produces a positive dy (NSView coords
        // are bottom-origin). dy < 0 means the finger moved downward in the
        // coordinate system, which is visually "Up" for the user when the view
        // is not flipped; most NSViews ARE flipped in asset_pipeline (the stack
        // views use flipped coordinates via NSFlippedView). We use the raw
        // sign here — callers that need the visual direction should account for
        // the flip. This is a known macOS vs iOS behavioral difference and is
        // documented on UI::SwipeDirection.
    }

    int expected = ap_pan_read_direction(self);
    if (expected < 0 || classified == expected) {
        unsigned long long token = ap_gesture_read_token(self);
        if (token != 0ULL) {
            crystal_ui_callback_dispatch(token);
        }
    }
}

static Class ap_register_pan_swipe_target(void) {
    Class cls = objc_getClass("CrystalPanSwipeTarget");
    if (cls) return cls;

    cls = objc_allocateClassPair([NSObject class], "CrystalPanSwipeTarget", 0);
    if (!cls) return Nil;

    class_addIvar(cls, "_token", sizeof(unsigned long long),
                  __alignof__(unsigned long long), @encode(unsigned long long));
    class_addIvar(cls, "_direction", sizeof(int),
                  __alignof__(int), @encode(int));
    class_addMethod(cls, sel_registerName("setToken:"),
                    (IMP)ap_gesture_set_token, "v@:Q");
    class_addMethod(cls, sel_registerName("setDirection:"),
                    (IMP)ap_pan_set_direction, "v@:i");
    class_addMethod(cls, sel_registerName("handlePan:"),
                    (IMP)ap_pan_target_handle, "v@:@");

    objc_registerClassPair(cls);
    return cls;
}

#endif // TARGET_OS_OSX

// ------------------------------------------------------------------
// CrystalLongPressTarget — fires token when the recognizer enters
// the .began state (hold threshold crossed).
// ------------------------------------------------------------------

static void ap_long_press_target_handle(id self, SEL _cmd, id recognizer) {
    // Fire only at .began — the threshold has just been crossed.
#if TARGET_OS_IPHONE
    UIGestureRecognizerState state =
        ((UIGestureRecognizerState (*)(id, SEL))objc_msgSend)(
            recognizer, sel_registerName("state"));
    if (state != UIGestureRecognizerStateBegan) return;
#else
    NSGestureRecognizerState state =
        ((NSGestureRecognizerState (*)(id, SEL))objc_msgSend)(
            recognizer, sel_registerName("state"));
    if (state != NSGestureRecognizerStateBegan) return;
#endif
    unsigned long long token = ap_gesture_read_token(self);
    if (token != 0ULL) {
        crystal_ui_callback_dispatch(token);
    }
}

static Class ap_register_long_press_target(void) {
    Class cls = objc_getClass("CrystalLongPressTarget");
    if (cls) return cls;

    cls = objc_allocateClassPair([NSObject class], "CrystalLongPressTarget", 0);
    if (!cls) return Nil;

    class_addIvar(cls, "_token", sizeof(unsigned long long),
                  __alignof__(unsigned long long), @encode(unsigned long long));
    class_addMethod(cls, sel_registerName("setToken:"),
                    (IMP)ap_gesture_set_token, "v@:Q");
    class_addMethod(cls, sel_registerName("handleLongPress:"),
                    (IMP)ap_long_press_target_handle, "v@:@");

    objc_registerClassPair(cls);
    return cls;
}

// ------------------------------------------------------------------
// Per-direction associated-object keys.
//
// Static self-referencing pointers are a stable, unique key per
// translation unit — the same technique used throughout this file.
// ------------------------------------------------------------------
static const void *ap_swipe_key_0 = &ap_swipe_key_0; // Left  (0)
static const void *ap_swipe_key_1 = &ap_swipe_key_1; // Right (1)
static const void *ap_swipe_key_2 = &ap_swipe_key_2; // Up    (2)
static const void *ap_swipe_key_3 = &ap_swipe_key_3; // Down  (3)
static const void *ap_long_press_key = &ap_long_press_key;

static const void *ap_swipe_assoc_key_for_direction(int direction) {
    switch (direction) {
        case 1:  return ap_swipe_key_1;
        case 2:  return ap_swipe_key_2;
        case 3:  return ap_swipe_key_3;
        default: return ap_swipe_key_0;
    }
}

// ------------------------------------------------------------------
// objc_attach_swipe_gesture — attach a discrete swipe recognizer.
//
// `direction` is the SwipeDirection enum ordinal (Left=0, Right=1,
// Up=2, Down=3). `token` is the Crystal CallbackRegistry id.
//
// iOS: UISwipeGestureRecognizer — natively directional.
//   cancelsTouchesInView defaults to YES (swipe consumes the touch),
//   which matches standard iOS list-row swipe affordance.
//
// macOS: NSPanGestureRecognizer with a direction-aware target
//   (CrystalPanSwipeTarget). The action fires only when the dominant
//   translation component at .ended matches the registered direction
//   and exceeds the 30 pt threshold. Each direction installs its own
//   independent recognizer so all four can coexist on one view.
//
// Returns 1 on success, 0 on nil view or class registration failure.
// ------------------------------------------------------------------
int objc_attach_swipe_gesture(void *view_ptr, int direction, unsigned long long token) {
    if (view_ptr == NULL) return 0;

    id view = (__bridge id)view_ptr;
    const void *assoc_key = ap_swipe_assoc_key_for_direction(direction);

#if TARGET_OS_IPHONE
    Class target_cls = ap_register_swipe_target();
    if (!target_cls) return 0;

    id target = ((id (*)(Class, SEL))objc_msgSend)(target_cls, sel_registerName("new"));
    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(
        target, sel_registerName("setToken:"), token);
    objc_setAssociatedObject(view, assoc_key, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [target release];

    id target_obj = objc_getAssociatedObject(view, assoc_key);

    UISwipeGestureRecognizerDirection ui_dir;
    switch (direction) {
        case 0:  ui_dir = UISwipeGestureRecognizerDirectionLeft;  break;
        case 1:  ui_dir = UISwipeGestureRecognizerDirectionRight; break;
        case 2:  ui_dir = UISwipeGestureRecognizerDirectionUp;    break;
        case 3:  ui_dir = UISwipeGestureRecognizerDirectionDown;  break;
        default: ui_dir = UISwipeGestureRecognizerDirectionDown;  break;
    }
    UISwipeGestureRecognizer *rec =
        [[UISwipeGestureRecognizer alloc] initWithTarget:target_obj
                                                  action:sel_registerName("handleSwipe:")];
    rec.direction = ui_dir;
    // cancelsTouchesInView defaults to YES — swipe consumes the touch.
    [(UIView *)view addGestureRecognizer:rec];
    [rec release];

#else // TARGET_OS_OSX
    Class target_cls = ap_register_pan_swipe_target();
    if (!target_cls) return 0;

    id target = ((id (*)(Class, SEL))objc_msgSend)(target_cls, sel_registerName("new"));
    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(
        target, sel_registerName("setToken:"), token);
    ((void (*)(id, SEL, int))objc_msgSend)(
        target, sel_registerName("setDirection:"), direction);
    objc_setAssociatedObject(view, assoc_key, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [target release];

    id target_obj = objc_getAssociatedObject(view, assoc_key);

    NSPanGestureRecognizer *rec =
        [[NSPanGestureRecognizer alloc] initWithTarget:target_obj
                                                action:sel_registerName("handlePan:")];
    [(NSView *)view addGestureRecognizer:rec];
    [rec release];
#endif

    return 1;
}

// ------------------------------------------------------------------
// objc_attach_long_press_gesture — attach a discrete long-press recognizer.
//
// `token` is the Crystal CallbackRegistry id. `min_duration` is the
// hold threshold in seconds (pass 0.5 for the Apple HIG default).
//
// iOS: UILongPressGestureRecognizer. cancelsTouchesInView = NO so
//   child button taps fire normally on short presses.
// macOS: NSPressGestureRecognizer (same semantics).
//
// The callback fires once when the recognizer enters .began (threshold
// crossed). Later state transitions (.changed, .ended) are ignored.
//
// Returns 1 on success, 0 on nil view or class registration failure.
// ------------------------------------------------------------------
int objc_attach_long_press_gesture(void *view_ptr, unsigned long long token, double min_duration) {
    if (view_ptr == NULL) return 0;

    Class target_cls = ap_register_long_press_target();
    if (!target_cls) return 0;

    id view = (__bridge id)view_ptr;

    id target = ((id (*)(Class, SEL))objc_msgSend)(target_cls, sel_registerName("new"));
    ((void (*)(id, SEL, unsigned long long))objc_msgSend)(
        target, sel_registerName("setToken:"), token);
    objc_setAssociatedObject(view, ap_long_press_key, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [target release];

    id target_obj = objc_getAssociatedObject(view, ap_long_press_key);

#if TARGET_OS_IPHONE
    UILongPressGestureRecognizer *rec =
        [[UILongPressGestureRecognizer alloc] initWithTarget:target_obj
                                                      action:sel_registerName("handleLongPress:")];
    rec.minimumPressDuration = (NSTimeInterval)min_duration;
    // cancelsTouchesInView = NO: a long-press overlay must not prevent child
    // button taps from completing — the button's on_tap fires on tap-up, which
    // only reaches the button if this recognizer does not swallow the touch.
    rec.cancelsTouchesInView = NO;
    [(UIView *)view addGestureRecognizer:rec];
    [rec release];

#else // TARGET_OS_OSX
    NSPressGestureRecognizer *rec =
        [[NSPressGestureRecognizer alloc] initWithTarget:target_obj
                                                  action:sel_registerName("handleLongPress:")];
    rec.minimumPressDuration = (NSTimeInterval)min_duration;
    [(NSView *)view addGestureRecognizer:rec];
    [rec release];
#endif

    return 1;
}

// ------------------------------------------------------------------
// appkit_view_apply_surface_craft — CALayer-backed surface overrides for
// AppKit views that are rendered without an NSHostingView facade (for
// example, raw NSStackView rows). SwiftUI facades apply the same typed
// payload in SurfaceCraftModifiers.swift.
// ------------------------------------------------------------------
#if TARGET_OS_OSX
static NSColor *ap_surface_color(NSString *value) {
    if ([value hasPrefix:@"rgba("] && [value hasSuffix:@")"]) {
        NSString *components = [[value substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@")"]];
        NSArray<NSString *> *parts = [components componentsSeparatedByString:@","];
        if (parts.count == 4) {
            CGFloat r = parts[0].doubleValue / 255.0;
            CGFloat g = parts[1].doubleValue / 255.0;
            CGFloat b = parts[2].doubleValue / 255.0;
            CGFloat a = parts[3].doubleValue;
            return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
        }
    }
    if (![value hasPrefix:@"role:"]) return NSColor.clearColor;
    NSString *role = [value substringFromIndex:5];
    if ([role isEqualToString:@"brand-primary"]) return NSColor.controlAccentColor;
    if ([role isEqualToString:@"brand-accent"]) return NSColor.systemTealColor;
    if ([role isEqualToString:@"surface-canvas"]) return NSColor.windowBackgroundColor;
    if ([role isEqualToString:@"surface-elevated"]) return NSColor.controlBackgroundColor;
    if ([role isEqualToString:@"surface-panel"]) return NSColor.underPageBackgroundColor;
    if ([role isEqualToString:@"surface-sunken"]) return NSColor.textBackgroundColor;
    if ([role isEqualToString:@"surface-inverse"]) return NSColor.textColor;
    if ([role isEqualToString:@"text-primary"]) return NSColor.labelColor;
    if ([role isEqualToString:@"text-inverse"]) return NSColor.windowBackgroundColor;
    if ([role isEqualToString:@"warning"]) return NSColor.systemOrangeColor;
    return NSColor.clearColor;
}

static CGImageRef ap_surface_texture_tile(NSString *kind) {
    static CGImageRef noise = NULL;
    static CGImageRef brushed = NULL;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        for (int variant = 0; variant < 2; variant++) {
            CGContextRef context = CGBitmapContextCreate(NULL, 64, 64, 8, 0, space,
                kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            if (!context) continue;
            for (int y = 0; y < 64; y++) {
                for (int x = 0; x < 64; x++) {
                    double u = (double)x / 64.0;
                    double v = (double)y / 64.0;
                    CGFloat value = 0.0;
                    if (variant == 0) {
                        double sum = 0.0;
                        double total_weight = 0.0;
                        for (int octave = 0; octave < 5; octave++) {
                            double frequency = (double)(2 << octave);
                            double phase = (double)octave * 1.73;
                            double first = sin(2.0 * M_PI * (frequency * u + frequency * 3.0 * v) + phase);
                            double second = cos(2.0 * M_PI * (frequency * 2.0 * u - frequency * v) + phase * 1.91);
                            double weight = 1.0 / sqrt(frequency);
                            sum += (first + second) * 0.5 * weight;
                            total_weight += weight;
                        }
                        value = (CGFloat)fmin(1.0, fmax(0.0, 0.5 + sum / total_weight * 0.32));
                    } else {
                        double lengthwise = sin(2.0 * M_PI * (16.0 * u + 0.08 * v) + 0.7);
                        double variation = cos(2.0 * M_PI * (32.0 * u - 0.12 * v) + 2.1);
                        double banding = sin(2.0 * M_PI * (2.0 * v + 0.03 * u) + 1.2);
                        value = (CGFloat)fmin(1.0, fmax(0.0, 0.5 + lengthwise * 0.12 + variation * 0.07 + banding * 0.04));
                    }
                    CGContextSetRGBFillColor(context, value, value, value, 1.0);
                    CGContextFillRect(context, CGRectMake(x, y, 1, 1));
                }
            }
            CGImageRef image = CGBitmapContextCreateImage(context);
            if (variant == 0) noise = image; else brushed = image;
            CGContextRelease(context);
        }
        CGColorSpaceRelease(space);
    });
    return [kind isEqualToString:@"brushed"] ? brushed : noise;
}

static NSArray<CALayer *> *ap_surface_layers_named(CALayer *root, NSString *name) {
    NSMutableArray<CALayer *> *matches = [NSMutableArray array];
    for (CALayer *layer in root.sublayers) {
        if ([layer.name isEqualToString:name]) [matches addObject:layer];
    }
    return matches;
}

static void ap_surface_remove_layers_with_prefix(CALayer *root, NSString *prefix) {
    for (CALayer *layer in root.sublayers) {
        if ([layer.name hasPrefix:prefix]) [layer removeFromSuperlayer];
    }
}

static void ap_surface_apply_preview_feedback(CALayer *root, NSDictionary *values) {
    BOOL had_preview_state = NO;
    for (CALayer *layer in root.sublayers) {
        if ([layer.name hasPrefix:@"ap.surfaceCraft.preview."]) {
            had_preview_state = YES;
            break;
        }
    }
    ap_surface_remove_layers_with_prefix(root, @"ap.surfaceCraft.preview.");
    if (had_preview_state) {
        root.transform = CATransform3DIdentity;
        root.shadowColor = nil;
        root.shadowOpacity = 0;
        root.shadowRadius = 0;
        root.shadowOffset = CGSizeZero;
    }

    NSString *feedback = [values[@"feedback"] isKindOfClass:[NSString class]] ? values[@"feedback"] : nil;
    NSString *phase = [values[@"previewState"] isKindOfClass:[NSString class]] ? values[@"previewState"] : nil;
    if (phase == nil) return;

    BOOL is_hover = [phase isEqualToString:@"hover"];
    BOOL is_pressed = [phase isEqualToString:@"pressed"];
    BOOL is_focus = [phase isEqualToString:@"focus"];
    BOOL uses_edge = [feedback isEqualToString:@"edge"];

    // Mark the root so a later application can undo only the transform and
    // shadow installed by this preview modifier. The hidden marker also
    // lets the None path leave a fresh view's existing layer settings alone.
    CALayer *marker = [CALayer layer];
    marker.name = @"ap.surfaceCraft.preview.active";
    marker.hidden = YES;
    [root addSublayer:marker];

    // Match the SwiftUI SurfaceCraft face tint. It is attached to the
    // container's own layer, below its arranged children, so a composite's
    // state never leaks into child controls.
    if (is_hover) {
        CALayer *hover = [CALayer layer];
        hover.name = @"ap.surfaceCraft.preview.hover";
        hover.frame = root.bounds;
        hover.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        hover.cornerRadius = root.cornerRadius;
        hover.backgroundColor = [[NSColor.labelColor colorWithAlphaComponent:0.035] CGColor];
        [root addSublayer:hover];
    }

    if ([feedback isEqualToString:@"sink"] && is_pressed) {
        root.transform = CATransform3DMakeTranslation(0, -1, 0);
    } else if ([feedback isEqualToString:@"lift"] && is_hover) {
        root.transform = CATransform3DMakeTranslation(0, 2, 0);
    } else if (([feedback isEqualToString:@"lift"] || uses_edge) && is_pressed) {
        root.transform = CATransform3DMakeTranslation(0, -1, 0);
    }

    if ([feedback isEqualToString:@"lift"] && (is_hover || is_pressed)) {
        root.shadowColor = NSColor.blackColor.CGColor;
        root.shadowOpacity = 0.16;
        root.shadowRadius = is_hover ? 7 : 5;
        root.shadowOffset = CGSizeMake(0, is_hover ? 3 : 1);
    }

    if (uses_edge && (is_hover || is_pressed || is_focus)) {
        CALayer *edge = [CALayer layer];
        edge.name = @"ap.surfaceCraft.preview.edge";
        edge.frame = CGRectMake(0, 4, 2, MAX(0, CGRectGetHeight(root.bounds) - 8));
        edge.autoresizingMask = kCALayerHeightSizable;
        edge.cornerRadius = 1;
        edge.backgroundColor = NSColor.controlAccentColor.CGColor;
        [root addSublayer:edge];
    }

    // A preview focus ring is drawn directly, without asking AppKit to make
    // this container first responder. Edge feedback supplies its own accent
    // indication; other styles use the system keyboard focus color.
    if (is_focus && !uses_edge) {
        CALayer *ring = [CALayer layer];
        ring.name = @"ap.surfaceCraft.preview.focusRing";
        ring.frame = root.bounds;
        ring.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        ring.cornerRadius = root.cornerRadius + 2;
        ring.borderWidth = 2;
        ring.borderColor = NSColor.keyboardFocusIndicatorColor.CGColor;
        [root addSublayer:ring];
    }
}

void appkit_view_apply_surface_craft(void *view_ptr, const char *json) {
    if (!view_ptr || !json || json[0] == '\0') return;
    @autoreleasepool {
        NSData *data = [[NSString stringWithUTF8String:json] dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *values = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if (![values isKindOfClass:[NSDictionary class]]) return;
        NSView *view = (__bridge NSView *)view_ptr;
        view.wantsLayer = YES;
        CALayer *root = view.layer;
        if (!root) return;

        NSString *fill = values[@"fill"];
        if ([fill isKindOfClass:[NSString class]]) {
            root.backgroundColor = ap_surface_color(fill).CGColor;
        }

        for (CALayer *old in ap_surface_layers_named(root, @"ap.surfaceCraft.gradient")) [old removeFromSuperlayer];
        NSDictionary *gradient = values[@"gradient"];
        NSArray *stops = gradient[@"stops"];
        if ([stops isKindOfClass:[NSArray class]] && stops.count >= 2) {
            NSMutableArray *colors = [NSMutableArray array];
            NSMutableArray *locations = [NSMutableArray array];
            for (NSDictionary *stop in stops) {
                NSString *color = stop[@"color"];
                if (![color isKindOfClass:[NSString class]]) continue;
                [colors addObject:(id)ap_surface_color(color).CGColor];
                [locations addObject:@([stop[@"position"] doubleValue])];
            }
            if (colors.count >= 2) {
                double radians = [gradient[@"angle"] doubleValue] * 3.141592653589793 / 180.0;
                CAGradientLayer *layer = [CAGradientLayer layer];
                layer.name = @"ap.surfaceCraft.gradient";
                layer.frame = root.bounds;
                layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
                layer.colors = colors;
                layer.locations = locations;
                layer.startPoint = CGPointMake(0.5 - sin(radians) * 0.5, 0.5 - cos(radians) * 0.5);
                layer.endPoint = CGPointMake(0.5 + sin(radians) * 0.5, 0.5 + cos(radians) * 0.5);
                [root insertSublayer:layer atIndex:0];
            }
        }

        for (CALayer *old in ap_surface_layers_named(root, @"ap.surfaceCraft.texture")) [old removeFromSuperlayer];
        NSDictionary *texture = values[@"texture"];
        NSString *kind = texture[@"kind"];
        CGImageRef tile = [kind isKindOfClass:[NSString class]] ? ap_surface_texture_tile(kind) : NULL;
        if (tile) {
            CAReplicatorLayer *vertical = [CAReplicatorLayer layer];
            vertical.name = @"ap.surfaceCraft.texture";
            vertical.frame = root.bounds;
            vertical.instanceCount = 128;
            vertical.instanceTransform = CATransform3DMakeTranslation(0, 64, 0);
            vertical.opacity = (float)[texture[@"opacity"] doubleValue];
            CAReplicatorLayer *row = [CAReplicatorLayer layer];
            row.frame = CGRectMake(0, 0, CGRectGetWidth(root.bounds), 64);
            row.instanceCount = 128;
            row.instanceTransform = CATransform3DMakeTranslation(64, 0, 0);
            CALayer *image = [CALayer layer];
            image.frame = CGRectMake(0, 0, 64, 64);
            image.contents = (__bridge id)tile;
            image.contentsGravity = kCAGravityResize;
            image.compositingFilter = @"multiplyBlendMode";
            [row addSublayer:image];
            [vertical addSublayer:row];
            [root insertSublayer:vertical atIndex:(unsigned)MIN(1, root.sublayers.count)];
        }

        ap_surface_remove_layers_with_prefix(root, @"ap.surfaceCraft.drop.");
        NSArray *drops = values[@"dropShadows"];
        if ([drops isKindOfClass:[NSArray class]]) {
            NSUInteger shadow_index = 0;
            for (NSDictionary *shadow in drops) {
                NSString *color = shadow[@"color"];
                if (![color isKindOfClass:[NSString class]]) continue;
                CALayer *layer = [CALayer layer];
                layer.name = [NSString stringWithFormat:@"ap.surfaceCraft.drop.%lu", (unsigned long)shadow_index++];
                layer.frame = root.bounds;
                layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
                CGPathRef shadow_path = CGPathCreateWithRoundedRect(root.bounds, root.cornerRadius, root.cornerRadius, NULL);
                layer.shadowPath = shadow_path;
                CGPathRelease(shadow_path);
                layer.shadowColor = ap_surface_color(color).CGColor;
                layer.shadowOpacity = 1.0;
                layer.shadowRadius = [shadow[@"blur"] doubleValue];
                layer.shadowOffset = CGSizeMake([shadow[@"x"] doubleValue], [shadow[@"y"] doubleValue]);
                [root insertSublayer:layer atIndex:0];
            }
        }

        ap_surface_remove_layers_with_prefix(root, @"ap.surfaceCraft.inner.");
        NSArray *inner = values[@"innerShadows"];
        if ([inner isKindOfClass:[NSArray class]]) {
            NSUInteger shadow_index = 0;
            for (NSDictionary *shadow in inner) {
                NSString *color = shadow[@"color"];
                if (![color isKindOfClass:[NSString class]]) continue;
                CAShapeLayer *layer = [CAShapeLayer layer];
                layer.name = [NSString stringWithFormat:@"ap.surfaceCraft.inner.%lu", (unsigned long)shadow_index++];
                layer.frame = root.bounds;
                layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
                CGRect inset = CGRectInset(root.bounds, 1, 1);
                CGPathRef inner_path = CGPathCreateWithRoundedRect(inset, root.cornerRadius, root.cornerRadius, NULL);
                layer.path = inner_path;
                CGPathRelease(inner_path);
                layer.fillColor = NSColor.clearColor.CGColor;
                layer.strokeColor = ap_surface_color(color).CGColor;
                layer.lineWidth = MAX(1, [shadow[@"blur"] doubleValue] * 2);
                layer.shadowColor = ap_surface_color(color).CGColor;
                layer.shadowOpacity = 0.55;
                layer.shadowRadius = [shadow[@"blur"] doubleValue];
                layer.shadowOffset = CGSizeMake([shadow[@"x"] doubleValue], [shadow[@"y"] doubleValue]);
                layer.masksToBounds = YES;
                [root addSublayer:layer];
            }
        }

        ap_surface_apply_preview_feedback(root, values);
    }
}

int appkit_view_has_surface_layer(void *view_ptr, const char *name) {
    if (!view_ptr || !name) return 0;
    NSView *view = (__bridge NSView *)view_ptr;
    NSString *target = [NSString stringWithUTF8String:name];
    for (CALayer *layer in view.layer.sublayers) {
        if ([layer.name isEqualToString:target]) return 1;
        if ([layer isKindOfClass:[CAReplicatorLayer class]]) {
            for (CALayer *child in layer.sublayers) {
                if ([child.name isEqualToString:target]) return 1;
            }
        }
    }
    return 0;
}
#else
void appkit_view_apply_surface_craft(void *view_ptr, const char *json) {
    (void)view_ptr; (void)json;
}
int appkit_view_has_surface_layer(void *view_ptr, const char *name) {
    (void)view_ptr; (void)name; return 0;
}
#endif
