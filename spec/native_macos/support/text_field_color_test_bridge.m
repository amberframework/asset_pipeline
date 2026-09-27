#import <AppKit/AppKit.h>
#include <stdint.h>
#include <string.h>

// --- Text field color capture harness ------------------------------------
//
// These specs run while someone may be using the machine, so the capture
// window never activates the app, never becomes key, and never appears on a
// screen: it is borderless, parked far outside every display, and never
// ordered in. The field is drawn into an sRGB bitmap with
// cacheDisplayInRect:, which renders the view hierarchy without the window
// server.

@interface APSpecOffscreenColorWindow : NSWindow
@end

@implementation APSpecOffscreenColorWindow
- (NSRect)constrainFrameRect:(NSRect)frame_rect toScreen:(NSScreen *)screen {
    return frame_rect;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}
@end

static void ap_spec_color_pump_run_loop(NSTimeInterval seconds) {
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:seconds];
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
}

// Creates the offscreen window with `content_view_ptr` as its content view,
// in the Aqua (dark == 0) or Dark Aqua (dark == 1) appearance.
void *ap_spec_color_window_new(void *content_view_ptr, double width, double height, int32_t dark) {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyAccessory];

    APSpecOffscreenColorWindow *window = [[APSpecOffscreenColorWindow alloc]
        initWithContentRect:NSMakeRect(-30000, -30000, width, height)
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];
    [window setReleasedWhenClosed:NO];
    NSAppearanceName name = dark ? NSAppearanceNameDarkAqua : NSAppearanceNameAqua;
    [window setAppearance:[NSAppearance appearanceNamed:name]];
    NSView *view = (NSView *)content_view_ptr;
    [view setAppearance:[NSAppearance appearanceNamed:name]];
    [window setContentView:view];
    for (int pass = 0; pass < 10; pass++) {
        [[window contentView] layoutSubtreeIfNeeded];
        [window displayIfNeeded];
        ap_spec_color_pump_run_loop(0.02);
    }
    return window;
}

static NSTextField *ap_spec_color_first_text_field(NSView *view) {
    if ([view isKindOfClass:[NSTextField class]] && [(NSTextField *)view isEditable]) {
        return (NSTextField *)view;
    }
    for (NSView *child in view.subviews) {
        NSTextField *field = ap_spec_color_first_text_field(child);
        if (field != nil) return field;
    }
    return nil;
}

// Draws the window's content view into an 8-bit sRGB RGBA bitmap and copies
// the pixels covering the first editable NSTextField (the SwiftUI
// TextField / SecureField backing view) into `out_rgba`, row 0 at the top.
// `capacity` is the size of `out_rgba` in bytes. Returns 1 and fills
// `out_size` with {pixel_width, pixel_height} on success, 0 when there is no
// field or the buffer is too small.
int32_t ap_spec_color_capture_field(void *window_ptr, uint8_t *out_rgba, int64_t capacity, int32_t *out_size) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSView *root = [window contentView];
    NSTextField *field = ap_spec_color_first_text_field(root);
    if (field == nil || out_rgba == NULL || out_size == NULL) return 0;

    [root layoutSubtreeIfNeeded];
    NSRect field_rect = [root convertRect:[field bounds] fromView:field];
    field_rect = NSIntegralRect(NSIntersectionRect(field_rect, [root bounds]));
    if (NSIsEmptyRect(field_rect)) return 0;

    NSBitmapImageRep *cached = [root bitmapImageRepForCachingDisplayInRect:field_rect];
    if (cached == nil) return 0;
    [root cacheDisplayInRect:field_rect toBitmapImageRep:cached];

    NSInteger width = [cached pixelsWide];
    NSInteger height = [cached pixelsHigh];
    if ((int64_t)width * height * 4 > capacity) return 0;

    CGColorSpaceRef srgb = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context = CGBitmapContextCreate(
        out_rgba, width, height, 8, width * 4, srgb,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(srgb);
    if (context == NULL) return 0;

    memset(out_rgba, 0, (size_t)(width * height * 4));
    CGImageRef image = [cached CGImage];
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);

    out_size[0] = (int32_t)width;
    out_size[1] = (int32_t)height;
    return 1;
}

int32_t ap_spec_color_application_is_active(void) {
    return [NSApp isActive] ? 1 : 0;
}

void ap_spec_color_window_close(void *window_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    [window close];
    [window release];
}

// Puts the first editable field into editing (installs the field editor)
// without making the window key or activating the app, then inserts
// `utf8_text` through the field editor's text input path, the same
// NSTextInputClient entry point a keyboard or input method uses. Returns 1
// when the field editor accepted the text.
int32_t ap_spec_color_edit_field(void *window_ptr, const char *utf8_text) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *field = ap_spec_color_first_text_field([window contentView]);
    if (field == nil || utf8_text == NULL) return 0;
    if (![window makeFirstResponder:field]) return 0;
    NSText *editor = [field currentEditor];
    if (editor == nil || ![editor isKindOfClass:[NSTextView class]]) return 0;
    NSString *text = [NSString stringWithUTF8String:utf8_text];
    [(NSTextView *)editor insertText:text replacementRange:NSMakeRange(NSNotFound, 0)];
    for (int pass = 0; pass < 10; pass++) {
        [[window contentView] layoutSubtreeIfNeeded];
        [window displayIfNeeded];
        ap_spec_color_pump_run_loop(0.02);
    }
    return 1;
}
