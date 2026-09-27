#import <AppKit/AppKit.h>
#include <stdint.h>

// --- Text field alignment harness ----------------------------------------
//
// These specs run while someone may be using the machine, so the probe
// window never activates the app, never becomes key, and never appears on
// a screen: it is borderless, parked far outside every display, and ordered
// in behind all other windows. The field enters editing by becoming its
// window's first responder, which installs the field editor without the
// window being key, and typing is delivered to that field editor directly.
//
// Every probe window counts the application activations and the times it
// became key while it existed, so the spec can prove neither happened.

@interface APSpecOffscreenAlignmentWindow : NSWindow
@property(nonatomic) int32_t activation_count;
@property(nonatomic) int32_t became_key_count;
@end

@implementation APSpecOffscreenAlignmentWindow
- (NSRect)constrainFrameRect:(NSRect)frame_rect toScreen:(NSScreen *)screen {
    return frame_rect;
}

- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (BOOL)canBecomeMainWindow {
    return NO;
}

- (void)ap_spec_application_did_become_active:(NSNotification *)notification {
    self.activation_count += 1;
}

- (void)ap_spec_window_did_become_key:(NSNotification *)notification {
    self.became_key_count += 1;
}
@end

static const NSTimeInterval AP_SPEC_ALIGNMENT_TIMEOUT = 5.0;

static void ap_spec_alignment_pump_run_loop(void) {
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:0.02];
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
}

static void ap_spec_alignment_settle(NSWindow *window) {
    [[window contentView] layoutSubtreeIfNeeded];
    [window displayIfNeeded];
    ap_spec_alignment_pump_run_loop();
}

static NSTextField *ap_spec_first_editable_text_field(NSView *view) {
    if ([view isKindOfClass:[NSTextField class]] && [(NSTextField *)view isEditable]) {
        return (NSTextField *)view;
    }

    for (NSView *child in view.subviews) {
        NSTextField *field = ap_spec_first_editable_text_field(child);
        if (field != nil) return field;
    }
    return nil;
}

// Creates the offscreen probe window with `view_ptr` as its content view and
// pumps the run loop until SwiftUI has laid out an editable field with a
// non-empty frame, or the timeout passes.
void *ap_spec_text_field_window_new(void *view_ptr, double width, double height) {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyAccessory];

    APSpecOffscreenAlignmentWindow *window = [[APSpecOffscreenAlignmentWindow alloc]
        initWithContentRect:NSMakeRect(-30000, -30000, width, height)
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];
    [window setReleasedWhenClosed:NO];
    [window setTitle:@"Text Field Alignment Probe"];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:window
               selector:@selector(ap_spec_application_did_become_active:)
                   name:NSApplicationDidBecomeActiveNotification
                 object:nil];
    [center addObserver:window
               selector:@selector(ap_spec_window_did_become_key:)
                   name:NSWindowDidBecomeKeyNotification
                 object:window];

    NSView *view = (NSView *)view_ptr;
    [view setFrame:NSMakeRect(0, 0, width, height)];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [window setContentView:view];
    [window orderBack:nil];

    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:AP_SPEC_ALIGNMENT_TIMEOUT];
    do {
        ap_spec_alignment_settle(window);
        NSTextField *field = ap_spec_first_editable_text_field(view);
        if (field != nil && NSWidth(field.frame) > 0) break;
    } while ([deadline timeIntervalSinceNow] > 0);
    ap_spec_alignment_settle(window);
    return window;
}

void *ap_spec_find_editable_text_field(void *view_ptr) {
    return ap_spec_first_editable_text_field((NSView *)view_ptr);
}

// Puts the field into editing by making it the window's first responder.
// The window is not made key and the app is not activated. Returns 1 once
// the field editor is installed, 0 when it never is.
int32_t ap_spec_focus_text_field(void *window_ptr, void *field_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *field = (NSTextField *)field_ptr;
    if (![window makeFirstResponder:field]) return 0;

    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:AP_SPEC_ALIGNMENT_TIMEOUT];
    do {
        ap_spec_alignment_settle(window);
        if (field.currentEditor != nil) return 1;
    } while ([deadline timeIntervalSinceNow] > 0);
    return 0;
}

int32_t ap_spec_text_field_glyph_metrics(void *field_ptr, double *metrics) {
    NSTextField *field = (NSTextField *)field_ptr;
    NSTextView *editor = (NSTextView *)field.currentEditor;
    if (editor == nil || editor.layoutManager == nil || editor.textContainer == nil || metrics == NULL) return 0;

    NSString *text = editor.string;
    if (text.length == 0) return 0;

    NSLayoutManager *layout_manager = editor.layoutManager;
    NSTextContainer *container = editor.textContainer;
    [layout_manager ensureLayoutForTextContainer:container];
    NSRange characters = NSMakeRange(0, text.length);
    NSRange glyphs = [layout_manager glyphRangeForCharacterRange:characters actualCharacterRange:NULL];
    if (glyphs.length == 0) return 0;

    NSRect glyph_bounds = [layout_manager boundingRectForGlyphRange:glyphs inTextContainer:container];
    NSPoint text_origin = editor.textContainerOrigin;
    metrics[0] = text_origin.x;
    metrics[1] = text_origin.x + container.containerSize.width;
    metrics[2] = text_origin.x + NSMinX(glyph_bounds);
    metrics[3] = text_origin.x + NSMaxX(glyph_bounds);
    return 1;
}

static NSEvent *ap_spec_key_event(NSEventType type, NSWindow *window, NSString *characters) {
    return [NSEvent keyEventWithType:type
        location:NSZeroPoint
        modifierFlags:0
        timestamp:NSProcessInfo.processInfo.systemUptime
        windowNumber:window.windowNumber
        context:nil
        characters:characters
        charactersIgnoringModifiers:characters
        isARepeat:NO
        keyCode:0];
}

// Types `utf8_text` one character at a time. Each key-down event goes
// straight to the field editor's keyDown:, which runs the key through
// interpretKeyEvents: into insertText: (the path a keyboard takes), and
// never through NSApplication or NSWindow event dispatch, which would need
// a key window. Returns 1 when the field editor held the field's editing
// session for every key.
int32_t ap_spec_type_into_text_field(void *window_ptr, void *field_ptr, const char *utf8_text) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *field = (NSTextField *)field_ptr;
    if (utf8_text == NULL) return 0;
    NSString *text = [NSString stringWithUTF8String:utf8_text];

    for (NSUInteger index = 0; index < text.length; index++) {
        NSText *editor = field.currentEditor;
        if (editor == nil) return 0;
        NSString *character = [text substringWithRange:NSMakeRange(index, 1)];
        [editor keyDown:ap_spec_key_event(NSEventTypeKeyDown, window, character)];
        [editor keyUp:ap_spec_key_event(NSEventTypeKeyUp, window, character)];
        ap_spec_alignment_settle(window);
    }
    return 1;
}

// Pumps the run loop until the field editor holds exactly `utf8_text`.
// Returns 1 when it does before the timeout, 0 otherwise.
int32_t ap_spec_text_field_editor_equals(void *window_ptr, void *field_ptr, const char *utf8_text) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *field = (NSTextField *)field_ptr;
    if (utf8_text == NULL) return 0;
    NSString *expected = [NSString stringWithUTF8String:utf8_text];

    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:AP_SPEC_ALIGNMENT_TIMEOUT];
    do {
        NSText *editor = field.currentEditor;
        if (editor != nil && [editor.string isEqualToString:expected]) return 1;
        ap_spec_alignment_settle(window);
    } while ([deadline timeIntervalSinceNow] > 0);
    return 0;
}

int32_t ap_spec_text_field_application_is_active(void) {
    return [NSApp isActive] ? 1 : 0;
}

int32_t ap_spec_text_field_window_is_key(void *window_ptr) {
    return [(NSWindow *)window_ptr isKeyWindow] ? 1 : 0;
}

int32_t ap_spec_text_field_window_activation_count(void *window_ptr) {
    return ((APSpecOffscreenAlignmentWindow *)window_ptr).activation_count;
}

int32_t ap_spec_text_field_window_became_key_count(void *window_ptr) {
    return ((APSpecOffscreenAlignmentWindow *)window_ptr).became_key_count;
}

void ap_spec_text_field_window_close(void *window_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    [[NSNotificationCenter defaultCenter] removeObserver:window];
    [window orderOut:nil];
    [window close];
    [window release];
}
