#import <AppKit/AppKit.h>

void *ap_spec_create_focus_target(void) {
    NSTextField *target = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 180, 28)];
    [target setEditable:YES];
    return target;
}

// The first-responder probe runs while someone may be using the machine, so
// its window never activates the app and never becomes key: it is borderless,
// parked far outside every display, and ordered in behind all other windows.
// makeFirstResponder: installs the field editor on a non-key window, which is
// all the deferred-focus contract needs.
@interface APSpecOffscreenFocusWindow : NSWindow
@end

@implementation APSpecOffscreenFocusWindow
- (NSRect)constrainFrameRect:(NSRect)frame_rect toScreen:(NSScreen *)screen {
    return frame_rect;
}
@end

static const NSTimeInterval AP_SPEC_FOCUS_TIMEOUT = 2.0;

void *ap_spec_create_focus_window(void) {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyAccessory];

    APSpecOffscreenFocusWindow *window = [[APSpecOffscreenFocusWindow alloc]
        initWithContentRect:NSMakeRect(-30000, -30000, 260, 100)
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];
    [window setReleasedWhenClosed:NO];
    [window setTitle:@"First Responder Probe"];
    [window orderBack:nil];
    return window;
}

// Attaching the target fires the deferred makeFirstResponder: request from
// viewDidMoveToWindow. Pump the run loop in short, bounded passes until the
// field editor is in place so the probe does not race AppKit's setup.
void ap_spec_attach_focus_target(void *window_ptr, void *target_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *target = (NSTextField *)target_ptr;
    [window setContentView:(NSView *)target];

    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:AP_SPEC_FOCUS_TIMEOUT];
    do {
        [[window contentView] layoutSubtreeIfNeeded];
        [window displayIfNeeded];
        NSDate *until = [NSDate dateWithTimeIntervalSinceNow:0.02];
        [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
        if (target.currentEditor != nil) break;
    } while ([deadline timeIntervalSinceNow] > 0);
}

int ap_spec_focus_window_is_key(void *window_ptr) {
    return [(NSWindow *)window_ptr isKeyWindow] ? 1 : 0;
}

BOOL ap_spec_window_has_first_responder(void *window_ptr, void *target_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *target = (NSTextField *)target_ptr;
    NSResponder *first_responder = window.firstResponder;
    return first_responder == (NSResponder *)target || target.currentEditor == first_responder;
}

void ap_spec_release_focus_objects(void *window_ptr, void *target_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *target = (NSTextField *)target_ptr;
    [window orderOut:nil];
    [window close];
    [window release];
    [target release];
}

// --- Selectable Label harness ------------------------------------------
//
// These specs run while someone may be using the machine, so the Label
// window never activates the app, never becomes key, and never appears on
// a screen: it is borderless, parked far outside every display, and ordered
// in behind all other windows. Ordering it in is what puts it in the
// application's accessibility tree.

@interface APSpecOffscreenLabelWindow : NSWindow
@end

@implementation APSpecOffscreenLabelWindow
- (NSRect)constrainFrameRect:(NSRect)frame_rect toScreen:(NSScreen *)screen {
    return frame_rect;
}
@end

void *ap_spec_create_label_window(void *content_view_ptr) {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [application finishLaunching];

    APSpecOffscreenLabelWindow *window = [[APSpecOffscreenLabelWindow alloc]
        initWithContentRect:NSMakeRect(-30000, -30000, 540, 120)
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];
    [window setReleasedWhenClosed:NO];
    [window setTitle:@"Selectable Label Probe"];
    [window setContentView:(NSView *)content_view_ptr];
    [window orderBack:nil];
    [[window contentView] layoutSubtreeIfNeeded];
    [window displayIfNeeded];
    return window;
}

// Runs one short pass of the main run loop so SwiftUI can apply pending
// updates. Callers poll a condition around it under a deadline.
void ap_spec_pump_label_run_loop(void) {
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:0.02];
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:until];
}

int ap_spec_application_is_active(void) {
    return [NSApp isActive] ? 1 : 0;
}

int ap_spec_window_is_key(void *window_ptr) {
    return [(NSWindow *)window_ptr isKeyWindow] ? 1 : 0;
}

void ap_spec_label_fitting_size(void *view_ptr, double *width, double *height) {
    NSView *view = (NSView *)view_ptr;
    NSSize fitting_size = [view fittingSize];
    *width = fitting_size.width;
    *height = fitting_size.height;
}

void ap_spec_label_frame(void *view_ptr, double *x, double *y, double *width, double *height) {
    NSRect frame = [(NSView *)view_ptr frame];
    *x = frame.origin.x;
    *y = frame.origin.y;
    *width = frame.size.width;
    *height = frame.size.height;
}

// Converts an accessibility point (screen space, top-left origin on the
// primary display) into the window's base coordinates.
static NSPoint ap_spec_window_point_for_ax_point(NSWindow *window, double ax_x, double ax_y) {
    NSScreen *primary_screen = [[NSScreen screens] firstObject];
    double screen_y = NSMaxY([primary_screen frame]) - ax_y;
    return [window convertPointFromScreen:NSMakePoint(ax_x, screen_y)];
}

static NSView *ap_spec_view_hit_at_ax_point(NSWindow *window, double ax_x, double ax_y) {
    NSPoint window_point = ap_spec_window_point_for_ax_point(window, ax_x, ax_y);
    NSView *frame_view = [[window contentView] superview];
    return [frame_view hitTest:window_point];
}

// 1 when a click at the accessibility point would land on a view that can
// hold a text selection (a selectable text field or a text view).
int ap_spec_ax_point_hits_selectable_text(void *window_ptr, double ax_x, double ax_y) {
    NSView *hit = ap_spec_view_hit_at_ax_point((NSWindow *)window_ptr, ax_x, ax_y);
    if ([hit isKindOfClass:[NSTextView class]]) {
        return [(NSTextView *)hit isSelectable] ? 1 : 0;
    }
    if ([hit isKindOfClass:[NSTextField class]]) {
        return [(NSTextField *)hit isSelectable] ? 1 : 0;
    }
    return 0;
}

// Triple-clicks (select the whole line, as a person would) the view that
// the window's own hit test finds at the accessibility point. The events
// go straight to that view, never through NSWindow, so the window is not
// made key and the application is not activated. The matching mouse-up is
// queued first so the view's tracking loop ends; any mouse-up the view did
// not consume is discarded. Returns 0 when nothing is hit.
int ap_spec_triple_click_at_ax_point(void *window_ptr, double ax_x, double ax_y) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSView *hit = ap_spec_view_hit_at_ax_point(window, ax_x, ax_y);
    if (hit == nil) {
        return 0;
    }

    NSPoint window_point = ap_spec_window_point_for_ax_point(window, ax_x, ax_y);
    NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
    NSEvent *mouse_up = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp
                                           location:window_point
                                      modifierFlags:0
                                          timestamp:now
                                       windowNumber:[window windowNumber]
                                            context:nil
                                        eventNumber:0
                                         clickCount:3
                                           pressure:0];
    NSEvent *mouse_down = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                             location:window_point
                                        modifierFlags:0
                                            timestamp:now
                                         windowNumber:[window windowNumber]
                                              context:nil
                                          eventNumber:0
                                           clickCount:3
                                             pressure:1];
    [NSApp postEvent:mouse_up atStart:NO];
    [hit mouseDown:mouse_down];
    [NSApp discardEventsMatchingMask:NSEventMaskLeftMouseUp beforeEvent:nil];
    return 1;
}

// Sends copy: along the window's responder chain from its first responder,
// which is where Edit > Copy (Cmd+C) delivers it. Returns 1 when a
// responder accepted copy:, 0 when none in the chain implements it.
int ap_spec_copy_from_first_responder(void *window_ptr) {
    NSResponder *responder = [(NSWindow *)window_ptr firstResponder];
    while (responder != nil) {
        if ([responder respondsToSelector:@selector(copy:)]) {
            [NSApp sendAction:@selector(copy:) to:responder from:nil];
            return 1;
        }
        responder = [responder nextResponder];
    }
    return 0;
}

// Snapshots every item and type on the general pasteboard so the proof can
// put the clipboard back exactly as it found it. The caller must pass the
// result to ap_spec_pasteboard_restore.
void *ap_spec_pasteboard_snapshot(void) {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (NSPasteboardItem *item in [pasteboard pasteboardItems]) {
        NSPasteboardItem *item_copy = [[NSPasteboardItem alloc] init];
        for (NSPasteboardType type in [item types]) {
            NSData *data = [item dataForType:type];
            if (data != nil) {
                [item_copy setData:data forType:type];
            }
        }
        [items addObject:item_copy];
        [item_copy release];
    }
    return items;
}

void ap_spec_pasteboard_restore(void *snapshot_ptr) {
    NSArray *items = (NSArray *)snapshot_ptr;
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    if ([items count] > 0) {
        [pasteboard writeObjects:items];
    }
    [items release];
}

void ap_spec_pasteboard_write_string(const char *text) {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:[NSString stringWithUTF8String:text] forType:NSPasteboardTypeString];
}

// Returns a malloc'd UTF-8 copy of the pasteboard's string, which the
// caller frees, or NULL when the pasteboard holds no string.
char *ap_spec_pasteboard_copy_string(void) {
    NSString *text = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
    if (text == nil) {
        return NULL;
    }
    return strdup([text UTF8String]);
}

void ap_spec_close_label_window(void *window_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    [window orderOut:nil];
    [window close];
    [window release];
}
