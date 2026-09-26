#import <AppKit/AppKit.h>

int ap_spec_capture_appkit_view(void *view_ptr) {
    if (view_ptr == NULL) return 0;

    @autoreleasepool {
        [NSApplication sharedApplication];
        NSView *view = (NSView *)view_ptr;
        NSRect frame = NSMakeRect(0, 0, 320, 220);
        [view setFrame:frame];

        NSWindow *window = [[NSWindow alloc]
            initWithContentRect:frame
            styleMask:NSWindowStyleMaskBorderless
            backing:NSBackingStoreBuffered
            defer:NO];
        if (window == nil) return 0;
        [window setReleasedWhenClosed:NO];
        [window setContentView:view];
        [window makeKeyAndOrderFront:nil];

        [window layoutIfNeeded];
        [view layoutSubtreeIfNeeded];
        [window displayIfNeeded];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.025]];
        [view layoutSubtreeIfNeeded];
        [view displayIfNeeded];

        NSBitmapImageRep *bitmap = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
        if (bitmap != nil) {
            [view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmap];
        }
        NSData *png = bitmap == nil ? nil : [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];

        [window orderOut:nil];
        [window close];
        [window release];
        return png.length > 0 ? 1 : 0;
    }
}

double ap_spec_appkit_view_layer_translation_y(void *view_ptr) {
    if (view_ptr == NULL) return 0;
    NSView *view = (NSView *)view_ptr;
    CALayer *root = view.layer;
    return root == nil ? 0 : root.transform.m42;
}

float ap_spec_appkit_view_layer_shadow_opacity(void *view_ptr) {
    if (view_ptr == NULL) return 0;
    NSView *view = (NSView *)view_ptr;
    CALayer *root = view.layer;
    return root == nil ? 0 : root.shadowOpacity;
}
