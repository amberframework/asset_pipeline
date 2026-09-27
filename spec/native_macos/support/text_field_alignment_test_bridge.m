#import <AppKit/AppKit.h>
#include <stdint.h>

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

void *ap_spec_text_field_window_new(double width, double height) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSWindow *window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(100, 100, width, height)
        styleMask:NSWindowStyleMaskTitled
        backing:NSBackingStoreBuffered
        defer:NO];
    [window setReleasedWhenClosed:NO];
    [window setTitle:@"Text Field Alignment Spec"];
    return window;
}

void ap_spec_text_field_window_attach(void *window_ptr, void *view_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSView *view = (NSView *)view_ptr;
    NSView *content_view = window.contentView;
    [view setFrame:content_view.bounds];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [window setContentView:view];
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [window displayIfNeeded];
    [view displayIfNeeded];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}

void *ap_spec_find_editable_text_field(void *view_ptr) {
    return ap_spec_first_editable_text_field((NSView *)view_ptr);
}

int32_t ap_spec_focus_text_field(void *window_ptr, void *field_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *field = (NSTextField *)field_ptr;
    [window makeKeyAndOrderFront:nil];
    BOOL accepted = [window makeFirstResponder:field];
    [window displayIfNeeded];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    return accepted && field.currentEditor != nil;
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

void ap_spec_type_into_text_field(void *window_ptr, void *field_ptr, const char *utf8_text) {
    NSWindow *window = (NSWindow *)window_ptr;
    NSTextField *field = (NSTextField *)field_ptr;
    NSString *text = utf8_text == NULL ? @"" : [NSString stringWithUTF8String:utf8_text];
    [window makeFirstResponder:field];

    for (NSUInteger index = 0; index < text.length; index++) {
        NSString *character = [text substringWithRange:NSMakeRange(index, 1)];
        NSEvent *down = ap_spec_key_event(NSEventTypeKeyDown, window, character);
        NSEvent *up = ap_spec_key_event(NSEventTypeKeyUp, window, character);
        [NSApp sendEvent:down];
        [NSApp sendEvent:up];
    }

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}

int32_t ap_spec_text_field_editor_equals(void *field_ptr, const char *utf8_text) {
    NSTextField *field = (NSTextField *)field_ptr;
    NSTextView *editor = (NSTextView *)field.currentEditor;
    if (editor == nil || utf8_text == NULL) return 0;
    NSString *expected = [NSString stringWithUTF8String:utf8_text];
    return [editor.string isEqualToString:expected];
}

void ap_spec_text_field_window_close(void *window_ptr) {
    NSWindow *window = (NSWindow *)window_ptr;
    [window orderOut:nil];
    [window close];
    [window release];
}
