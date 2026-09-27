#import <AppKit/AppKit.h>
#import <ImageIO/ImageIO.h>
#include <math.h>
#include <stdio.h>
#include <stdint.h>

extern void appkit_view_apply_surface_craft(void *view_ptr, const char *json);

@interface APSpecBackingScaleWindow : NSWindow
@property(nonatomic) CGFloat specBackingScaleFactor;
@end

@implementation APSpecBackingScaleWindow
- (CGFloat)backingScaleFactor {
    return self.specBackingScaleFactor > 0.0
        ? self.specBackingScaleFactor
        : [super backingScaleFactor];
}
@end

static APSpecBackingScaleWindow *ap_spec_held_window;

static CALayer *ap_spec_surface_layer_named(CALayer *root, NSString *name) {
    for (CALayer *layer in root.sublayers) {
        if ([layer.name isEqualToString:name]) return layer;
    }
    return nil;
}

static CGContextRef ap_spec_srgb_bitmap_context(uint8_t *pixels, size_t width, size_t height) {
    CGColorSpaceRef color_space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    if (color_space == NULL) return NULL;
    CGContextRef context = CGBitmapContextCreate(
        pixels,
        width,
        height,
        8,
        width * 4,
        color_space,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    return context;
}

static void ap_spec_texture_tile_pixel_size(NSView *view, int32_t *width, int32_t *height) {
    CALayer *texture_layer = ap_spec_surface_layer_named(view.layer, @"ap.surfaceCraft.texture");
    CALayer *row_layer = texture_layer.sublayers.count > 0 ? texture_layer.sublayers[0] : nil;
    CALayer *image_layer = row_layer.sublayers.count > 0 ? row_layer.sublayers[0] : nil;
    CGImageRef tile = (CGImageRef)image_layer.contents;
    *width = tile == NULL ? 0 : (int32_t)CGImageGetWidth(tile);
    *height = tile == NULL ? 0 : (int32_t)CGImageGetHeight(tile);
}

static int32_t ap_spec_attach_view_to_offscreen_window(
    NSView *view,
    double point_width,
    double point_height,
    double initial_scale,
    double changed_scale,
    BOOL should_change_scale,
    BOOL should_hold_window,
    int32_t *initial_tile_width,
    int32_t *initial_tile_height,
    int32_t *changed_tile_width,
    int32_t *changed_tile_height) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        NSRect frame = NSMakeRect(0, 0, point_width, point_height);
        NSScreen *screen = [NSScreen mainScreen];
        if (screen != nil) {
            NSRect visible_frame = screen.visibleFrame;
            frame.origin = NSMakePoint(
                NSMidX(visible_frame) - point_width / 2.0,
                NSMidY(visible_frame) - point_height / 2.0);
        }
        APSpecBackingScaleWindow *window = [[APSpecBackingScaleWindow alloc]
            initWithContentRect:frame
            styleMask:NSWindowStyleMaskBorderless
            backing:NSBackingStoreBuffered
            defer:NO];
        if (window == nil) return 0;
        [window setReleasedWhenClosed:NO];
        window.specBackingScaleFactor = initial_scale;
        int32_t result = 1;
        @try {
            [view setFrame:frame];
            [window setContentView:view];
            [window orderOut:nil];
            [window layoutIfNeeded];
            [view layoutSubtreeIfNeeded];
            [window displayIfNeeded];
            [view displayIfNeeded];
            if (initial_tile_width != NULL && initial_tile_height != NULL) {
                ap_spec_texture_tile_pixel_size(view, initial_tile_width, initial_tile_height);
            }

            if (should_change_scale) {
                window.specBackingScaleFactor = changed_scale;
                [view viewDidChangeBackingProperties];
                [window layoutIfNeeded];
                [view layoutSubtreeIfNeeded];
                [window displayIfNeeded];
                [view displayIfNeeded];
                if (changed_tile_width != NULL && changed_tile_height != NULL) {
                    ap_spec_texture_tile_pixel_size(view, changed_tile_width, changed_tile_height);
                }
            }
        } @catch (NSException *exception) {
            fprintf(stderr, "SurfaceCraft attach exception: %s: %s\n",
                exception.name.UTF8String, exception.reason.UTF8String);
            result = 2;
        }

        if (should_hold_window && result == 1) {
            ap_spec_held_window = window;
        } else {
            @try {
                [window setContentView:nil];
                [window close];
            } @catch (NSException *exception) {
                fprintf(stderr, "SurfaceCraft window cleanup exception: %s: %s\n",
                    exception.name.UTF8String, exception.reason.UTF8String);
                result = 2;
            }
            [window release];
        }
        return result;
    }
}

int32_t ap_spec_attach_noise_view_and_change_backing_scale(
    void *view_ptr,
    double point_width,
    double point_height,
    double initial_scale,
    double changed_scale,
    int32_t *initial_tile_width,
    int32_t *initial_tile_height,
    int32_t *changed_tile_width,
    int32_t *changed_tile_height) {
    if (view_ptr == NULL || initial_scale <= 0.0 || changed_scale <= 0.0 ||
        initial_tile_width == NULL || initial_tile_height == NULL ||
        changed_tile_width == NULL || changed_tile_height == NULL) return 0;
    return ap_spec_attach_view_to_offscreen_window(
        (__bridge NSView *)view_ptr,
        point_width,
        point_height,
        initial_scale,
        changed_scale,
        YES,
        NO,
        initial_tile_width,
        initial_tile_height,
        changed_tile_width,
        changed_tile_height);
}

int32_t ap_spec_attach_and_detach_noise_view(void *view_ptr, double point_width, double point_height, double backing_scale) {
    if (view_ptr == NULL || backing_scale <= 0.0) return 0;
    return ap_spec_attach_view_to_offscreen_window(
        (__bridge NSView *)view_ptr,
        point_width,
        point_height,
        backing_scale,
        backing_scale,
        NO,
        NO,
        NULL,
        NULL,
        NULL,
        NULL);
}

int32_t ap_spec_attach_noise_view_to_held_window(void *view_ptr, double point_width, double point_height, double backing_scale) {
    if (view_ptr == NULL || backing_scale <= 0.0 || ap_spec_held_window != nil) return 0;
    return ap_spec_attach_view_to_offscreen_window(
        (__bridge NSView *)view_ptr,
        point_width,
        point_height,
        backing_scale,
        backing_scale,
        NO,
        YES,
        NULL,
        NULL,
        NULL,
        NULL);
}

void ap_spec_close_held_noise_window(void) {
    @autoreleasepool {
        APSpecBackingScaleWindow *window = ap_spec_held_window;
        if (window == nil) return;
        ap_spec_held_window = nil;
        [window setContentView:nil];
        [window close];
        [window release];
    }
}

int32_t ap_spec_render_surface_craft_json(
    const char *json,
    double point_width,
    double point_height,
    double backing_scale,
    uint8_t *pixels,
    int32_t capacity,
    int32_t *pixel_width,
    int32_t *pixel_height,
    int32_t *tile_pixel_width,
    int32_t *tile_pixel_height,
    double *texture_opacity,
    double *contents_scale,
    int32_t *has_compositing_filter) {
    if (json == NULL || pixels == NULL || pixel_width == NULL || pixel_height == NULL ||
        tile_pixel_width == NULL || tile_pixel_height == NULL || texture_opacity == NULL ||
        contents_scale == NULL || has_compositing_filter == NULL || backing_scale <= 0.0) return 0;

    size_t output_width = (size_t)llround(point_width * backing_scale);
    size_t output_height = (size_t)llround(point_height * backing_scale);
    if (output_width == 0 || output_height == 0 || output_width > INT32_MAX ||
        output_height > INT32_MAX || output_width * output_height > SIZE_MAX / 4 ||
        (size_t)capacity < output_width * output_height * 4) return 0;

    @autoreleasepool {
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, point_width, point_height)];
        if (view == nil) return 0;
        view.wantsLayer = YES;
        view.layer.contentsScale = backing_scale;
        appkit_view_apply_surface_craft(view, json);

        CALayer *texture_layer = ap_spec_surface_layer_named(view.layer, @"ap.surfaceCraft.texture");
        CALayer *row_layer = texture_layer.sublayers.count > 0 ? texture_layer.sublayers[0] : nil;
        CALayer *image_layer = row_layer.sublayers.count > 0 ? row_layer.sublayers[0] : nil;
        CGImageRef tile = (CGImageRef)image_layer.contents;
        *tile_pixel_width = tile == NULL ? 0 : (int32_t)CGImageGetWidth(tile);
        *tile_pixel_height = tile == NULL ? 0 : (int32_t)CGImageGetHeight(tile);
        *texture_opacity = texture_layer == nil ? 0.0 : texture_layer.opacity;
        *contents_scale = image_layer == nil ? 0.0 : image_layer.contentsScale;
        *has_compositing_filter = image_layer.compositingFilter == nil ? 0 : 1;

        CGContextRef context = ap_spec_srgb_bitmap_context(pixels, output_width, output_height);
        if (context == NULL) {
            [view release];
            return 0;
        }
        CGContextTranslateCTM(context, 0, output_height);
        CGContextScaleCTM(context, backing_scale, -backing_scale);
        [view.layer renderInContext:context];
        CGContextFlush(context);
        CGContextRelease(context);
        [view release];

        *pixel_width = (int32_t)output_width;
        *pixel_height = (int32_t)output_height;
        return 1;
    }
}

int32_t ap_spec_rebake_noise_surface_on_scale_change(
    const char *json,
    double point_width,
    double point_height,
    double initial_scale,
    double new_scale,
    int32_t *initial_tile_width,
    int32_t *initial_tile_height,
    double *initial_contents_scale,
    int32_t *new_tile_width,
    int32_t *new_tile_height,
    double *new_contents_scale) {
    if (json == NULL || initial_tile_width == NULL || initial_tile_height == NULL ||
        initial_contents_scale == NULL || new_tile_width == NULL || new_tile_height == NULL ||
        new_contents_scale == NULL || initial_scale <= 0.0 || new_scale <= 0.0) return 0;

    @autoreleasepool {
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, point_width, point_height)];
        if (view == nil) return 0;
        view.wantsLayer = YES;
        view.layer.contentsScale = initial_scale;
        appkit_view_apply_surface_craft(view, json);

        CALayer *texture_layer = ap_spec_surface_layer_named(view.layer, @"ap.surfaceCraft.texture");
        CALayer *row_layer = texture_layer.sublayers.count > 0 ? texture_layer.sublayers[0] : nil;
        CALayer *image_layer = row_layer.sublayers.count > 0 ? row_layer.sublayers[0] : nil;
        CGImageRef initial_tile = (CGImageRef)image_layer.contents;
        *initial_tile_width = initial_tile == NULL ? 0 : (int32_t)CGImageGetWidth(initial_tile);
        *initial_tile_height = initial_tile == NULL ? 0 : (int32_t)CGImageGetHeight(initial_tile);
        *initial_contents_scale = image_layer == nil ? 0.0 : image_layer.contentsScale;

        view.layer.contentsScale = new_scale;
        [view viewDidChangeBackingProperties];

        texture_layer = ap_spec_surface_layer_named(view.layer, @"ap.surfaceCraft.texture");
        row_layer = texture_layer.sublayers.count > 0 ? texture_layer.sublayers[0] : nil;
        image_layer = row_layer.sublayers.count > 0 ? row_layer.sublayers[0] : nil;
        CGImageRef new_tile = (CGImageRef)image_layer.contents;
        *new_tile_width = new_tile == NULL ? 0 : (int32_t)CGImageGetWidth(new_tile);
        *new_tile_height = new_tile == NULL ? 0 : (int32_t)CGImageGetHeight(new_tile);
        *new_contents_scale = image_layer == nil ? 0.0 : image_layer.contentsScale;

        [view release];
        return 1;
    }
}

int32_t ap_spec_copy_png_rgba(
    const char *path,
    uint8_t *pixels,
    int32_t capacity,
    int32_t *pixel_width,
    int32_t *pixel_height) {
    if (path == NULL || pixels == NULL || pixel_width == NULL || pixel_height == NULL) return 0;

    @autoreleasepool {
        NSString *path_string = [NSString stringWithUTF8String:path];
        NSURL *url = [NSURL fileURLWithPath:path_string];
        CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
        if (source == NULL) return 0;
        CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
        if (image == NULL) return 0;

        size_t width = CGImageGetWidth(image);
        size_t height = CGImageGetHeight(image);
        if (width == 0 || height == 0 || width > INT32_MAX || height > INT32_MAX ||
            width * height > SIZE_MAX / 4 || (size_t)capacity < width * height * 4) {
            CGImageRelease(image);
            return 0;
        }

        CGContextRef context = ap_spec_srgb_bitmap_context(pixels, width, height);
        if (context == NULL) {
            CGImageRelease(image);
            return 0;
        }
        CGContextTranslateCTM(context, 0, height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        CGContextFlush(context);
        CGContextRelease(context);
        CGImageRelease(image);
        *pixel_width = (int32_t)width;
        *pixel_height = (int32_t)height;
        return 1;
    }
}

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
