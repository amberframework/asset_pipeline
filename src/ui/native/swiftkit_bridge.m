// swiftkit_bridge.m — C trampolines that forward calls from Crystal's
// `LibSwiftKitBridge` into the Swift companion library's `@objc` facade
// classes.
//
// Each trampoline locates the `APSK*Facade` / `APSK*Overrides` class via
// the ObjC runtime (`objc_getClass`) and dispatches to the
// `@objc public static func make...` method through `objc_msgSend`.
// Selector lookup and argument boxing live here so the Crystal-side
// callers see a flat C ABI; the Swift side never has to know about
// `objc_msgSend` casting.
//
// Compile (macOS / iOS) with `-fno-objc-arc`; this file follows the same
// memory convention as `objc_bridge.m`: returned objects are autoreleased
// per Cocoa convention, the Crystal-side `NativeHandle` takes ownership
// with `objc_retain` (+1) on the receiving side.
//
// Phase 3 ships the Button facade end-to-end. Phase 3 remediation /
// follow-up commits add a trampoline per widget in the §6 coverage list.

#include <objc/runtime.h>
#include <objc/message.h>
#include <stdlib.h>
#include <string.h>
#include <Foundation/Foundation.h>

// Forward-declare to keep the file self-contained; the actual Swift
// implementations land in AssetPipelineSwiftKit via @objc.
extern Class objc_getClass(const char *name);
extern SEL sel_registerName(const char *name);

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

// Returns @"" (empty NSString) when the incoming C string pointer is
// NULL. Returning `nil` was technically safe for the Crystal-bridged
// `text: String` Swift signature on macOS, but on iOS the implicit
// ObjC-to-Swift `String` bridge crashes when handed a `nil` NSString
// (BX8 sheet-focus-return regression: EXC_BAD_ACCESS in
// `_platform_strlen` from `+[NSString stringWithUTF8String:]`).
// Coalescing here keeps every facade's `String` argument well-formed
// without needing per-call-site fallbacks.
static inline NSString *apsk_nsstring(const char *utf8) {
    if (utf8 == NULL) return @"";
    return [NSString stringWithUTF8String:utf8] ?: @"";
}

// Box a UInt64 token into an NSNumber so `@objc` method signatures that
// accept `actionToken: UInt64` can route through `objc_msgSend` cleanly.
// Swift's `@objc` UInt64 lowers to `unsigned long long`; ObjC handles it
// natively, no NSNumber needed — kept here as a future hook.

// -----------------------------------------------------------------------------
// Overrides allocators
// -----------------------------------------------------------------------------

void *apsk_view_overrides_new(void) {
    Class cls = objc_getClass("APSKViewOverrides");
    if (cls == nil) return NULL;
    return ((id (*)(Class, SEL))objc_msgSend)(cls, sel_registerName("new"));
}

void *apsk_button_overrides_new(void) {
    Class cls = objc_getClass("APSKButtonOverrides");
    if (cls == nil) return NULL;
    return ((id (*)(Class, SEL))objc_msgSend)(cls, sel_registerName("new"));
}

// -----------------------------------------------------------------------------
// Runtime initialization
// -----------------------------------------------------------------------------

// Install the Crystal-side action trampoline pointer onto APSKRuntime.
// `trampoline` is the address of Crystal's `fun ap_swiftkit_invoke_action`.
void apsk_runtime_initialize(void *trampoline) {
    Class cls = objc_getClass("APSKRuntime");
    if (cls == nil) return;
    SEL sel = sel_registerName("initializeWithActionTrampoline:");
    ((void (*)(Class, SEL, void *))objc_msgSend)(cls, sel, trampoline);
}

// Forward-declare the Crystal trampoline so the static linker resolves
// `_ap_swiftkit_invoke_action` at link time and the address below is a
// straight load against the resolved symbol. Crystal emits this `fun`
// in `callback_registry.cr`.
extern void ap_swiftkit_invoke_action(unsigned long long token, double value);

// Phase 6.10 Rem 4 (Item 1) — string-valued trampoline counterpart.
// Crystal emits `ap_swiftkit_invoke_action_string` in
// `callback_registry.cr`.
extern void ap_swiftkit_invoke_action_string(unsigned long long token, const char *value);

// Convenience wrapper Crystal renderers actually call. Avoids the
// Crystal-side gymnastics of producing an `@convention(c)`-compatible
// function pointer from Crystal's `->fun(...)` syntax (which produces
// either a closure-bearing Proc or, depending on optimisation level,
// no stable address at all). The C compiler knows the address of
// `ap_swiftkit_invoke_action` natively — we just hand it over.
void apsk_runtime_install_default_action_trampoline(void) {
    apsk_runtime_initialize((void *)&ap_swiftkit_invoke_action);

    // Phase 6.10 Rem 4 (Item 1) — also install the string trampoline.
    // The selector is `initializeWithStringTrampoline:` — Swift's
    // `@objc static func initialize(stringTrampoline:)` synthesizes
    // this name.
    Class cls = objc_getClass("APSKRuntime");
    if (cls == nil) return;
    SEL sel = sel_registerName("initializeWithStringTrampoline:");
    ((void (*)(Class, SEL, void *))objc_msgSend)(
        cls, sel, (void *)&ap_swiftkit_invoke_action_string);
}

// Install (or replace) the brand tint colour applied to every SwiftUI
// facade root. Crystal calls this on every `render(...)` entry with the
// active `design_tokens.colors_light.brand_primary` RGBA so a brand
// override on the renderer's `design_tokens` cascades through to every
// hosted SwiftUI Button (and any other tint-aware widget in later
// dispatches). Channel values are normalised 0...1 sRGB.
//
// Selector is `setBrandTintWithRed:green:blue:alpha:` — that is the ObjC
// name Swift synthesises for `@objc static func setBrandTint(red:green:
// blue:alpha:)`.
void apsk_runtime_set_brand_tint(double r, double g, double b, double a) {
    Class cls = objc_getClass("APSKRuntime");
    if (cls == nil) return;
    SEL sel = sel_registerName("setBrandTintWithRed:green:blue:alpha:");
    ((void (*)(Class, SEL, double, double, double, double))objc_msgSend)(
        cls, sel, r, g, b, a);
}

// Clear the brand tint. Hosted roots fall back to SwiftUI's automatic
// accent colour. Currently used by spec helpers and by sample builds
// that want raw SwiftUI defaults.
void apsk_runtime_clear_brand_tint(void) {
    Class cls = objc_getClass("APSKRuntime");
    if (cls == nil) return;
    SEL sel = sel_registerName("clearBrandTint");
    ((void (*)(Class, SEL))objc_msgSend)(cls, sel);
}

// -----------------------------------------------------------------------------
// Overrides field setters
// -----------------------------------------------------------------------------
//
// Each setter takes the `APSK*Overrides` instance pointer, the setter
// selector NAME (e.g. "setBackgroundColor:"), and the value. The
// selector-name path keeps the C surface flat: Crystal's
// `Populator::Sender` already enumerates setter Symbols, so passing the
// Symbol as a UTF-8 C string + dispatching via `sel_registerName` matches
// the Crystal-side abstraction exactly without exposing `objc_msgSend`
// casting to renderer call sites.
//
// `NULL` selector / `NULL` target are silently no-ops so the renderer
// can pass overrides constructed from a renderer that does not yet have
// a `LibSwiftKitBridge` link (the Web/Android renderers).

// Boxes a normalised sRGB quad into a platform-specific colour object.
// On iOS this is `+[UIColor colorWithRed:green:blue:alpha:]`; on macOS
// this is `+[NSColor colorWithRed:green:blue:alpha:]`. The same selector
// works on both classes; only the receiving class differs.
static id apsk_make_platform_color(double r, double g, double b, double a) {
#if TARGET_OS_IPHONE
    Class color_cls = objc_getClass("UIColor");
#else
    Class color_cls = objc_getClass("NSColor");
#endif
    if (color_cls == nil) return nil;
    SEL sel = sel_registerName("colorWithRed:green:blue:alpha:");
    return ((id (*)(Class, SEL, double, double, double, double))objc_msgSend)(
        color_cls, sel, r, g, b, a);
}

void apsk_overrides_set_color(void *target, const char *setter_name,
                              double r, double g, double b, double a) {
    if (target == NULL || setter_name == NULL) return;
    id color = apsk_make_platform_color(r, g, b, a);
    if (color == nil) return;
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, id))objc_msgSend)((id)target, sel, color);
}

void apsk_overrides_set_number(void *target, const char *setter_name,
                               double value) {
    if (target == NULL || setter_name == NULL) return;
    NSNumber *boxed = [NSNumber numberWithDouble:value];
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, id))objc_msgSend)((id)target, sel, boxed);
}

void apsk_overrides_set_bool(void *target, const char *setter_name,
                             int value) {
    if (target == NULL || setter_name == NULL) return;
    NSNumber *boxed = [NSNumber numberWithBool:(value != 0)];
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, id))objc_msgSend)((id)target, sel, boxed);
}

void apsk_overrides_set_string(void *target, const char *setter_name,
                               const char *value) {
    if (target == NULL || setter_name == NULL) return;
    NSString *ns_value = apsk_nsstring(value);
    if (ns_value == nil) return;
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, id))objc_msgSend)((id)target, sel, ns_value);
}

// -----------------------------------------------------------------------------
// Facade entry points
// -----------------------------------------------------------------------------

// makeButton(label:overrides:actionToken:) → UIView*/NSView*
void *apsk_make_button(const char *label,
                       void *overrides,
                       unsigned long long action_token) {
    Class cls = objc_getClass("APSKButtonFacade");
    if (cls == nil) return NULL;
    NSString *ns_label = apsk_nsstring(label);
    SEL sel = sel_registerName("makeButtonWithLabel:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, unsigned long long))objc_msgSend)(
        cls, sel, ns_label, (id)overrides, action_token);
}

// ---------------------------------------------------------------------------
// Group 1 + 2 overrides allocators. Each opens an `APSK*Overrides` class via
// `objc_getClass` and dispatches +new through `objc_msgSend`. Pattern matches
// `apsk_button_overrides_new` above.
// ---------------------------------------------------------------------------

#define APSK_OVERRIDES_NEW(NAME, CLS)                                            \
    void *NAME(void) {                                                           \
        Class cls = objc_getClass(CLS);                                          \
        if (cls == nil) return NULL;                                             \
        return ((id (*)(Class, SEL))objc_msgSend)(cls, sel_registerName("new")); \
    }

APSK_OVERRIDES_NEW(apsk_label_overrides_new,             "APSKLabelOverrides")
APSK_OVERRIDES_NEW(apsk_image_overrides_new,             "APSKImageOverrides")
APSK_OVERRIDES_NEW(apsk_text_field_overrides_new,        "APSKTextFieldOverrides")
APSK_OVERRIDES_NEW(apsk_secure_field_overrides_new,      "APSKSecureFieldOverrides")
APSK_OVERRIDES_NEW(apsk_search_field_overrides_new,      "APSKSearchFieldOverrides")
APSK_OVERRIDES_NEW(apsk_text_area_overrides_new,         "APSKTextAreaOverrides")
APSK_OVERRIDES_NEW(apsk_text_editor_overrides_new,       "APSKTextEditorOverrides")
APSK_OVERRIDES_NEW(apsk_link_button_overrides_new,       "APSKLinkButtonOverrides")
APSK_OVERRIDES_NEW(apsk_icon_button_overrides_new,       "APSKIconButtonOverrides")
APSK_OVERRIDES_NEW(apsk_divider_overrides_new,           "APSKDividerOverrides")
APSK_OVERRIDES_NEW(apsk_spacer_overrides_new,            "APSKSpacerOverrides")
APSK_OVERRIDES_NEW(apsk_toggle_overrides_new,            "APSKToggleOverrides")
APSK_OVERRIDES_NEW(apsk_checkbox_overrides_new,          "APSKCheckboxOverrides")
APSK_OVERRIDES_NEW(apsk_radio_group_overrides_new,       "APSKRadioGroupOverrides")
APSK_OVERRIDES_NEW(apsk_slider_overrides_new,            "APSKSliderOverrides")
APSK_OVERRIDES_NEW(apsk_stepper_overrides_new,           "APSKStepperOverrides")
APSK_OVERRIDES_NEW(apsk_segmented_control_overrides_new, "APSKSegmentedControlOverrides")
APSK_OVERRIDES_NEW(apsk_picker_overrides_new,            "APSKPickerOverrides")
APSK_OVERRIDES_NEW(apsk_date_picker_overrides_new,       "APSKDatePickerOverrides")
APSK_OVERRIDES_NEW(apsk_time_picker_overrides_new,       "APSKTimePickerOverrides")
APSK_OVERRIDES_NEW(apsk_color_picker_overrides_new,      "APSKColorPickerOverrides")

// ---------------------------------------------------------------------------
// Group 3 overrides allocators (container widgets).
// ---------------------------------------------------------------------------
APSK_OVERRIDES_NEW(apsk_navigation_stack_overrides_new,      "APSKNavigationStackOverrides")
APSK_OVERRIDES_NEW(apsk_navigation_link_overrides_new,       "APSKNavigationLinkOverrides")
APSK_OVERRIDES_NEW(apsk_navigation_split_view_overrides_new, "APSKNavigationSplitViewOverrides")
APSK_OVERRIDES_NEW(apsk_tab_view_overrides_new,              "APSKTabViewOverrides")
APSK_OVERRIDES_NEW(apsk_sheet_overrides_new,                 "APSKSheetOverrides")
APSK_OVERRIDES_NEW(apsk_popover_overrides_new,               "APSKPopoverOverrides")
APSK_OVERRIDES_NEW(apsk_alert_overrides_new,                 "APSKAlertOverrides")
APSK_OVERRIDES_NEW(apsk_confirmation_dialog_overrides_new,   "APSKConfirmationDialogOverrides")
APSK_OVERRIDES_NEW(apsk_toolbar_overrides_new,               "APSKToolbarOverrides")
APSK_OVERRIDES_NEW(apsk_form_overrides_new,                  "APSKFormOverrides")
APSK_OVERRIDES_NEW(apsk_grid_overrides_new,                  "APSKGridOverrides")
APSK_OVERRIDES_NEW(apsk_card_overrides_new,                  "APSKCardOverrides")
APSK_OVERRIDES_NEW(apsk_surface_overrides_new,               "APSKSurfaceOverrides")
APSK_OVERRIDES_NEW(apsk_menu_button_overrides_new,           "APSKMenuButtonOverrides")
APSK_OVERRIDES_NEW(apsk_toggle_button_overrides_new,         "APSKToggleButtonOverrides")
APSK_OVERRIDES_NEW(apsk_list_view_overrides_new,             "APSKListViewOverrides")

// ---------------------------------------------------------------------------
// Glass (P1 — Phase 3 "headline visual differentiator").
// ---------------------------------------------------------------------------
APSK_OVERRIDES_NEW(apsk_glass_background_overrides_new,      "APSKGlassBackgroundOverrides")

// ---------------------------------------------------------------------------
// Array-field overrides setters. Each takes the overrides instance, the
// setter selector name (with trailing colon), and a contiguous C array
// of the matching element type. The C trampoline boxes the elements
// into an NSArray<NSString*> / NSArray<NSNumber*> and dispatches the
// setter via objc_msgSend.
// ---------------------------------------------------------------------------

void apsk_overrides_set_string_array(void *target, const char *setter_name,
                                     const void *values_ptr, int count) {
    if (target == NULL || setter_name == NULL || count < 0) return;
    NSMutableArray<NSString *> *arr = [NSMutableArray arrayWithCapacity:count];
    const char **strs = (const char **)values_ptr;
    for (int i = 0; i < count; i++) {
        const char *s = strs ? strs[i] : NULL;
        [arr addObject:(s ? [NSString stringWithUTF8String:s] : @"")];
    }
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, id))objc_msgSend)((id)target, sel, arr);
}

void apsk_overrides_set_int_array(void *target, const char *setter_name,
                                  const long long *values_ptr, int count) {
    if (target == NULL || setter_name == NULL || count < 0) return;
    NSMutableArray<NSNumber *> *arr = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        long long v = values_ptr ? values_ptr[i] : 0;
        [arr addObject:[NSNumber numberWithLongLong:v]];
    }
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, id))objc_msgSend)((id)target, sel, arr);
}

void apsk_overrides_set_uint64_array(void *target, const char *setter_name,
                                     const unsigned long long *values_ptr, int count) {
    if (target == NULL || setter_name == NULL || count < 0) return;
    NSMutableArray<NSNumber *> *arr = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        unsigned long long v = values_ptr ? values_ptr[i] : 0;
        [arr addObject:[NSNumber numberWithUnsignedLongLong:v]];
    }
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, id))objc_msgSend)((id)target, sel, arr);
}

void apsk_overrides_set_bool_array(void *target, const char *setter_name,
                                   const int *values_ptr, int count) {
    if (target == NULL || setter_name == NULL || count < 0) return;
    NSMutableArray<NSNumber *> *arr = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        int v = values_ptr ? values_ptr[i] : 0;
        [arr addObject:[NSNumber numberWithBool:(v != 0)]];
    }
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, id))objc_msgSend)((id)target, sel, arr);
}

void apsk_overrides_set_int(void *target, const char *setter_name,
                            long long value) {
    if (target == NULL || setter_name == NULL) return;
    SEL sel = sel_registerName(setter_name);
    ((void (*)(id, SEL, NSInteger))objc_msgSend)(
        (id)target, sel, (NSInteger)value);
}

// ---------------------------------------------------------------------------
// Helper: build NSArray<APSKPlatformView*> from a C array of view
// pointers. Used by every container facade trampoline below.
// ---------------------------------------------------------------------------
static NSArray *apsk_nsarray_from_views(const void *views_ptr, int count) {
    if (views_ptr == NULL || count <= 0) return @[];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    void *const *views = (void *const *)views_ptr;
    for (int i = 0; i < count; i++) {
        void *p = views[i];
        if (p == NULL) continue;
        [arr addObject:(__bridge id)p];
    }
    return arr;
}

// ---------------------------------------------------------------------------
// Group 3 facade trampolines.
// ---------------------------------------------------------------------------

void *apsk_make_navigation_stack(const void *child_views, int child_count,
                                 void *overrides) {
    Class cls = objc_getClass("APSKNavigationStackFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeNavigationStackWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

void *apsk_make_navigation_link(const char *label, const void *child_views,
                                int child_count, void *overrides) {
    Class cls = objc_getClass("APSKNavigationLinkFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeNavigationLinkWithLabel:childViews:overrides:");
    return ((id (*)(Class, SEL, id, id, id))objc_msgSend)(
        cls, sel, apsk_nsstring(label), children, (id)overrides);
}

void *apsk_make_navigation_split_view(const void *child_views, int child_count,
                                      void *overrides) {
    Class cls = objc_getClass("APSKNavigationSplitViewFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeNavigationSplitViewWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

void *apsk_make_tab_view(const void *child_views, int child_count,
                        void *overrides) {
    Class cls = objc_getClass("APSKTabViewFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeTabViewWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

void *apsk_make_sheet(const void *child_views, int child_count,
                      void *overrides, unsigned long long dismiss_token) {
    Class cls = objc_getClass("APSKSheetFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeSheetWithChildViews:overrides:dismissToken:");
    return ((id (*)(Class, SEL, id, id, unsigned long long))objc_msgSend)(
        cls, sel, children, (id)overrides, dismiss_token);
}

void *apsk_make_popover(const void *child_views, int child_count,
                        void *overrides, unsigned long long dismiss_token) {
    Class cls = objc_getClass("APSKPopoverFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makePopoverWithChildViews:overrides:dismissToken:");
    return ((id (*)(Class, SEL, id, id, unsigned long long))objc_msgSend)(
        cls, sel, children, (id)overrides, dismiss_token);
}

void *apsk_make_alert(const char *title, const char *message, void *overrides) {
    Class cls = objc_getClass("APSKAlertFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeAlertWithTitle:message:overrides:");
    return ((id (*)(Class, SEL, id, id, id))objc_msgSend)(
        cls, sel, apsk_nsstring(title),
        apsk_nsstring(message ? message : ""), (id)overrides);
}

void *apsk_make_confirmation_dialog(const char *title, const char *message,
                                    void *overrides) {
    Class cls = objc_getClass("APSKConfirmationDialogFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeConfirmationDialogWithTitle:message:overrides:");
    return ((id (*)(Class, SEL, id, id, id))objc_msgSend)(
        cls, sel, apsk_nsstring(title),
        apsk_nsstring(message ? message : ""), (id)overrides);
}

void *apsk_make_toolbar(const void *child_views, int child_count,
                        void *overrides) {
    Class cls = objc_getClass("APSKToolbarFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeToolbarWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

void *apsk_make_form(const void *child_views, int child_count, void *overrides) {
    Class cls = objc_getClass("APSKFormFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeFormWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

void *apsk_make_grid(const void *child_views, int child_count, void *overrides) {
    Class cls = objc_getClass("APSKGridFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeGridWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

void *apsk_make_card(const void *child_views, int child_count, void *overrides) {
    Class cls = objc_getClass("APSKCardFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeCardWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

void *apsk_make_surface(const void *child_views, int child_count, void *overrides) {
    Class cls = objc_getClass("APSKSurfaceFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeSurfaceWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

void *apsk_make_menu_button(const char *label, void *overrides) {
    Class cls = objc_getClass("APSKMenuButtonFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeMenuButtonWithLabel:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, apsk_nsstring(label), (id)overrides);
}

void *apsk_make_toggle_button(const char *label, void *overrides,
                              unsigned long long action_token) {
    Class cls = objc_getClass("APSKToggleButtonFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeToggleButtonWithLabel:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), (id)overrides, action_token);
}

void *apsk_make_list_view(const void *child_views, int child_count,
                          void *overrides) {
    Class cls = objc_getClass("APSKListViewFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName("makeListViewWithChildViews:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, children, (id)overrides);
}

// ---------------------------------------------------------------------------
// Glass facade trampoline. Phase 3 "headline visual differentiator" — the
// Swift facade routes through `.glassEffect()` on iOS 26 / macOS 26 and
// falls back to `.background(<Material>)` on the pre-26 OSes.
// ---------------------------------------------------------------------------
void *apsk_make_glass_background(void *overrides, void *child_view) {
    Class cls = objc_getClass("APSKGlassBackgroundFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeGlassBackgroundWithOverrides:childView:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, (id)overrides, (id)child_view);
}

// ---------------------------------------------------------------------------
// Helper: build an NSArray<NSString*> from a C array of UTF-8 strings.
// Used by Picker / RadioGroup / SegmentedControl facades whose options are
// arrays. The Crystal side passes a Void* that points to a contiguous block
// of `const char *` pointers plus a count.
// ---------------------------------------------------------------------------
static NSArray<NSString *> *apsk_nsarray_from_cstrings(const char **utf8s,
                                                      int count) {
    if (utf8s == NULL || count <= 0) return @[];
    NSMutableArray<NSString *> *arr = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        const char *s = utf8s[i];
        if (s == NULL) continue;
        [arr addObject:[NSString stringWithUTF8String:s]];
    }
    return arr;
}

// ---------------------------------------------------------------------------
// Group 1 facade trampolines.
// ---------------------------------------------------------------------------

void *apsk_make_label(const char *text, void *overrides) {
    Class cls = objc_getClass("APSKLabelFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeLabelWithText:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, apsk_nsstring(text), (id)overrides);
}

void *apsk_make_image(const char *source, void *overrides) {
    Class cls = objc_getClass("APSKImageFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeImageWithSource:overrides:");
    return ((id (*)(Class, SEL, id, id))objc_msgSend)(
        cls, sel, apsk_nsstring(source), (id)overrides);
}

void *apsk_make_text_field(const char *placeholder, const char *initial_text,
                           void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKTextFieldFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeTextFieldWithPlaceholder:initialText:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(placeholder), apsk_nsstring(initial_text),
        (id)overrides, action_token);
}

void *apsk_make_secure_field(const char *placeholder, const char *initial_text,
                             void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKSecureFieldFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeSecureFieldWithPlaceholder:initialText:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(placeholder), apsk_nsstring(initial_text),
        (id)overrides, action_token);
}

void *apsk_make_search_field(const char *placeholder, const char *initial_text,
                             void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKSearchFieldFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeSearchFieldWithPlaceholder:initialText:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(placeholder), apsk_nsstring(initial_text),
        (id)overrides, action_token);
}

void *apsk_make_text_area(const char *placeholder, const char *initial_text,
                          void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKTextAreaFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeTextAreaWithPlaceholder:initialText:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(placeholder), apsk_nsstring(initial_text),
        (id)overrides, action_token);
}

void *apsk_make_text_editor(const char *placeholder, const char *initial_text,
                            void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKTextEditorFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeTextEditorWithPlaceholder:initialText:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(placeholder), apsk_nsstring(initial_text),
        (id)overrides, action_token);
}

void *apsk_make_link_button(const char *label, const char *url,
                            void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKLinkButtonFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeLinkButtonWithLabel:url:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), apsk_nsstring(url),
        (id)overrides, action_token);
}

void *apsk_make_icon_button(const char *icon, void *overrides,
                            unsigned long long action_token) {
    Class cls = objc_getClass("APSKIconButtonFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeIconButtonWithIcon:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(icon), (id)overrides, action_token);
}

void *apsk_make_divider(void *overrides) {
    Class cls = objc_getClass("APSKDividerFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeDividerWithOverrides:");
    return ((id (*)(Class, SEL, id))objc_msgSend)(cls, sel, (id)overrides);
}

void *apsk_make_spacer(void *overrides) {
    Class cls = objc_getClass("APSKSpacerFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeSpacerWithOverrides:");
    return ((id (*)(Class, SEL, id))objc_msgSend)(cls, sel, (id)overrides);
}

// ---------------------------------------------------------------------------
// Group 2 facade trampolines.
// ---------------------------------------------------------------------------

void *apsk_make_toggle(const char *label, int is_on, void *overrides,
                       unsigned long long action_token) {
    Class cls = objc_getClass("APSKToggleFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeToggleWithLabel:isOn:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, BOOL, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), is_on != 0, (id)overrides, action_token);
}

void *apsk_make_checkbox(const char *label, int is_on, void *overrides,
                         unsigned long long action_token) {
    Class cls = objc_getClass("APSKCheckboxFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeCheckboxWithLabel:isOn:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, BOOL, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), is_on != 0, (id)overrides, action_token);
}

void *apsk_make_radio_group(const void *options_ptr, int option_count,
                            int selected_index, void *overrides,
                            unsigned long long action_token) {
    Class cls = objc_getClass("APSKRadioGroupFacade");
    if (cls == nil) return NULL;
    NSArray<NSString *> *arr = apsk_nsarray_from_cstrings(
        (const char **)options_ptr, option_count);
    SEL sel = sel_registerName("makeRadioGroupWithOptions:selectedIndex:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, NSInteger, id, unsigned long long))objc_msgSend)(
        cls, sel, arr, (NSInteger)selected_index, (id)overrides, action_token);
}

void *apsk_make_slider(double value, double minimum, double maximum,
                       void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKSliderFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeSliderWithValue:minimum:maximum:overrides:actionToken:");
    return ((id (*)(Class, SEL, double, double, double, id, unsigned long long))objc_msgSend)(
        cls, sel, value, minimum, maximum, (id)overrides, action_token);
}

void *apsk_make_stepper(const char *label, double value, double minimum,
                        double maximum, void *overrides,
                        unsigned long long action_token) {
    Class cls = objc_getClass("APSKStepperFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeStepperWithLabel:value:minimum:maximum:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, double, double, double, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), value, minimum, maximum,
        (id)overrides, action_token);
}

void *apsk_make_segmented_control(const void *segments_ptr, int segment_count,
                                  int selected_index, void *overrides,
                                  unsigned long long action_token) {
    Class cls = objc_getClass("APSKSegmentedControlFacade");
    if (cls == nil) return NULL;
    NSArray<NSString *> *arr = apsk_nsarray_from_cstrings(
        (const char **)segments_ptr, segment_count);
    SEL sel = sel_registerName("makeSegmentedControlWithSegments:selectedIndex:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, NSInteger, id, unsigned long long))objc_msgSend)(
        cls, sel, arr, (NSInteger)selected_index, (id)overrides, action_token);
}

void *apsk_make_picker(const char *label, const void *options_ptr,
                       int option_count, int selected_index, void *overrides,
                       unsigned long long action_token) {
    Class cls = objc_getClass("APSKPickerFacade");
    if (cls == nil) return NULL;
    NSArray<NSString *> *arr = apsk_nsarray_from_cstrings(
        (const char **)options_ptr, option_count);
    SEL sel = sel_registerName("makePickerWithLabel:options:selectedIndex:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, id, NSInteger, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), arr, (NSInteger)selected_index,
        (id)overrides, action_token);
}

void *apsk_make_date_picker(const char *label, double initial_epoch,
                            void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKDatePickerFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeDatePickerWithLabel:initialEpoch:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, double, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), initial_epoch,
        (id)overrides, action_token);
}

void *apsk_make_time_picker(const char *label, double initial_epoch,
                            void *overrides, unsigned long long action_token) {
    Class cls = objc_getClass("APSKTimePickerFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeTimePickerWithLabel:initialEpoch:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, double, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), initial_epoch,
        (id)overrides, action_token);
}

void *apsk_make_color_picker(const char *label, double r, double g, double b,
                             double a, void *overrides,
                             unsigned long long action_token) {
    Class cls = objc_getClass("APSKColorPickerFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeColorPickerWithLabel:initialR:initialG:initialB:initialA:overrides:actionToken:");
    return ((id (*)(Class, SEL, id, double, double, double, double, id, unsigned long long))objc_msgSend)(
        cls, sel, apsk_nsstring(label), r, g, b, a,
        (id)overrides, action_token);
}

// ---------------------------------------------------------------------------
// Phase 3 Remediation 4 — reactive `makeReactive*` trampolines.
//
// Each function mirrors the matching `apsk_make_*` above but writes the
// allocated state pointer through `out_state`. The Crystal renderer
// stores that pointer on the resulting `NativeHandle.state_handle` so
// the matching widget-level mutator methods (`UI::Label#text=`, etc.)
// can dispatch through the `apsk_*_set_*` @_cdecl helpers.
//
// `out_state` is permitted to be NULL — callers that don't want the
// reactive path pay no overhead beyond the extra parameter.
// ---------------------------------------------------------------------------

void *apsk_make_label_reactive(const char *text, void *overrides,
                               void **out_state) {
    Class cls = objc_getClass("APSKLabelFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName("makeReactiveLabelWithText:overrides:outState:");
    return ((id (*)(Class, SEL, id, id, void **))objc_msgSend)(
        cls, sel, apsk_nsstring(text), (id)overrides, out_state);
}

void *apsk_make_button_reactive(const char *label, void *overrides,
                                unsigned long long action_token,
                                void **out_state) {
    Class cls = objc_getClass("APSKButtonFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName(
        "makeReactiveButtonWithLabel:overrides:actionToken:outState:");
    return ((id (*)(Class, SEL, id, id, unsigned long long, void **))objc_msgSend)(
        cls, sel, apsk_nsstring(label), (id)overrides, action_token, out_state);
}

void *apsk_make_toggle_reactive(const char *label, int is_on, void *overrides,
                                unsigned long long action_token,
                                void **out_state) {
    Class cls = objc_getClass("APSKToggleFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName(
        "makeReactiveToggleWithLabel:isOn:overrides:actionToken:outState:");
    return ((id (*)(Class, SEL, id, BOOL, id, unsigned long long, void **))objc_msgSend)(
        cls, sel, apsk_nsstring(label), is_on != 0, (id)overrides,
        action_token, out_state);
}

void *apsk_make_slider_reactive(double value, double minimum, double maximum,
                                void *overrides, unsigned long long action_token,
                                void **out_state) {
    Class cls = objc_getClass("APSKSliderFacade");
    if (cls == nil) return NULL;
    SEL sel = sel_registerName(
        "makeReactiveSliderWithValue:minimum:maximum:overrides:actionToken:outState:");
    return ((id (*)(Class, SEL, double, double, double, id, unsigned long long, void **))objc_msgSend)(
        cls, sel, value, minimum, maximum, (id)overrides, action_token, out_state);
}

// Phase 3 Remediation 10 — reactive Sheet trampoline. Mirrors the static
// apsk_make_sheet but writes a +1 retained `APSKSheetState` pointer
// through `out_state` so Crystal can later flip presentation via
// apsk_sheet_set_presented.
void *apsk_make_sheet_reactive(const void *child_views, int child_count,
                               void *overrides, unsigned long long dismiss_token,
                               void **out_state) {
    Class cls = objc_getClass("APSKSheetFacade");
    if (cls == nil) return NULL;
    NSArray *children = apsk_nsarray_from_views(child_views, child_count);
    SEL sel = sel_registerName(
        "makeReactiveSheetWithChildViews:overrides:dismissToken:outState:");
    return ((id (*)(Class, SEL, id, id, unsigned long long, void **))objc_msgSend)(
        cls, sel, children, (id)overrides, dismiss_token, out_state);
}

// The `apsk_*_set_*` and `apsk_state_release` functions themselves are
// emitted directly by Swift via `@_cdecl` (see ReactiveState.swift). They
// are linked symbols on the AssetPipelineSwiftKit static library; Crystal
// declares them in `LibSwiftKitBridge` and the linker resolves them
// without any ObjC trampoline. No C wrappers required here.
