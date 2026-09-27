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

void *ap_spec_create_label_window(void *content_view_ptr) {
    NSApplication *application = [NSApplication sharedApplication];
    [application setActivationPolicy:NSApplicationActivationPolicyRegular];
    [application finishLaunching];

    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(100, 100, 540, 100)
        styleMask:NSWindowStyleMaskTitled
        backing:NSBackingStoreBuffered
        defer:NO];
    [window setReleasedWhenClosed:NO];
    [window setTitle:@"Selectable Label Probe"];
    [window setContentView:(NSView *)content_view_ptr];
    [window makeKeyAndOrderFront:nil];
    [application activateIgnoringOtherApps:YES];

    NSDate *settle_date = [NSDate dateWithTimeIntervalSinceNow:0.2];
    [[NSRunLoop mainRunLoop] runUntilDate:settle_date];
    return window;
}

void ap_spec_pump_label_run_loop(void) {
    NSDate *settle_date = [NSDate dateWithTimeIntervalSinceNow:0.1];
    [[NSRunLoop mainRunLoop] runUntilDate:settle_date];
}

void ap_spec_label_fitting_size(void *view_ptr, double *width, double *height) {
    NSView *view = (NSView *)view_ptr;
    NSSize fitting_size = [view fittingSize];
    *width = fitting_size.width;
    *height = fitting_size.height;
}

static NSTextField *ap_spec_find_selectable_text_field(NSView *view);

int ap_spec_copy_label_selection(void *window_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *text_field = ap_spec_find_selectable_text_field([window contentView]);
    if (text_field == nil) {
        return 0;
    }

    NSTextView *field_editor = (NSTextView *)[text_field currentEditor];
    if (field_editor == nil) {
        field_editor = (NSTextView *)[window fieldEditor:YES forObject:text_field];
    }
    if (field_editor == nil) {
        return 0;
    }

    [field_editor copy:nil];
    return 1;
}

static NSTextField *ap_spec_find_selectable_text_field(NSView *view) {
    if ([view isKindOfClass:[NSTextField class]]) {
        NSTextField *text_field = (NSTextField *)view;
        if ([text_field isSelectable] && ![text_field isEditable]) {
            return text_field;
        }
    }

    for (NSView *subview in [view subviews]) {
        NSTextField *text_field = ap_spec_find_selectable_text_field(subview);
        if (text_field != nil) {
            return text_field;
        }
    }

    return nil;
}

int ap_spec_select_label_text(void *window_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *text_field = ap_spec_find_selectable_text_field([window contentView]);
    if (text_field == nil) {
        return 0;
    }

    [window makeKeyAndOrderFront:nil];
    if (![window makeFirstResponder:text_field]) {
        return -2;
    }
    NSTextView *field_editor = (NSTextView *)[text_field currentEditor];
    if (field_editor == nil) {
        field_editor = (NSTextView *)[window fieldEditor:YES forObject:text_field];
    }
    if (field_editor == nil) {
        return -3;
    }

    [field_editor setSelectedRange:NSMakeRange(0, [[text_field stringValue] length])];
    return 1;
}

void ap_spec_close_label_window(void *window_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    [window orderOut:nil];
    [window close];
    [window release];
}
