#import <AppKit/AppKit.h>

void *ap_spec_create_focus_target(void) {
    NSTextField *target = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 180, 28)];
    [target setEditable:YES];
    return target;
}

void *ap_spec_create_focus_window(void) {
    [NSApplication sharedApplication];
    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(100, 100, 260, 100)
        styleMask:NSWindowStyleMaskTitled
        backing:NSBackingStoreBuffered
        defer:NO];
    [window setReleasedWhenClosed:NO];
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    return window;
}

void ap_spec_attach_focus_target(void *window_ptr, void *target_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    [window setContentView:(NSView *)target_ptr];
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
