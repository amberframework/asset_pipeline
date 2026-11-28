// Tap-latency probe helper for asset_pipeline AppKit controls.
//
// Part of the macOS tap-latency lane (`make test-latency-macos`); see README.md
// beside this file. Compiled with -fobjc-arc into build/latency-macos/.
//
// Records, in one lock-free ring buffer of (kind, t_ns, value) rows:
//   * main run-loop iteration start (AfterWaiting) and end (BeforeWaiting,
//     ordered after Core Animation's commit observer),
//   * display-link ticks on the main thread (one per vsync while the main
//     thread is free; a missing tick is a dropped frame),
//   * synthetic mouse-down / mouse-up: the time a background thread posted
//     it and the time AppKit dispatched it on the main thread,
//   * the first time the pressed pixels of the target view differ from rest,
//   * marks written by Crystal (action start/end, rerender start/end, GC).
//
// Synthetic clicks are posted from a background thread at fixed wall-clock
// times, so a busy main thread shows up as queued input latency, the way a
// person's real click would wait.
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#include <mach/mach_time.h>
#include <stdatomic.h>
#include <pthread.h>

enum {
  K_ITER_START = 1, K_ITER_END = 2, K_VSYNC = 3,
  K_MD_POST = 10, K_MD_DISPATCH = 11, K_MU_POST = 12, K_MU_DISPATCH = 13,
  K_PRESS_PIXELS = 14, K_RELEASE_PIXELS = 15,
  // 20..39 reserved for Crystal marks
};

#define CAP (1 << 20)
typedef struct { int32_t kind; int32_t pad; uint64_t t; int64_t v; } Row;
static Row g_rows[CAP];
static _Atomic uint64_t g_n = 0;
static mach_timebase_info_data_t g_tb;

uint64_t probe_now_ns(void) {
  if (g_tb.denom == 0) mach_timebase_info(&g_tb);
  return mach_absolute_time() * g_tb.numer / g_tb.denom;
}

void probe_mark(int32_t kind, int64_t v) {
  uint64_t i = atomic_fetch_add(&g_n, 1);
  if (i >= CAP) return;
  g_rows[i].kind = kind; g_rows[i].t = probe_now_ns(); g_rows[i].v = v;
}

static NSWindow *g_win;
static NSView *g_target;          // the view the clicks land on
static NSPoint g_click_pt;        // window coordinates
static int g_pixel_watch = 0;     // 1 = watch for pressed pixels, 2 = release
static double g_rest_luma = -1;

static double view_luma(NSView *v) {
  if (!v) return -1;
  NSRect b = [v bounds];
  NSBitmapImageRep *rep = [v bitmapImageRepForCachingDisplayInRect:b];
  if (!rep) return -1;
  [v cacheDisplayInRect:b toBitmapImageRep:rep];
  unsigned char *d = [rep bitmapData];
  NSInteger bpr = [rep bytesPerRow], w = [rep pixelsWide], h = [rep pixelsHigh];
  NSInteger spp = [rep samplesPerPixel];
  double sum = 0; long cnt = 0;
  for (NSInteger y = 0; y < h; y += 2)
    for (NSInteger x = 0; x < w; x += 2) {
      unsigned char *p = d + y * bpr + x * spp;
      sum += 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]; cnt++;
    }
  return cnt ? sum / cnt : -1;
}

@interface ProbeTicker : NSObject
@end
@implementation ProbeTicker
- (void)tick:(id)link { probe_mark(K_VSYNC, 0); }
@end
static ProbeTicker *g_ticker;
static id g_link;

static void observer_cb(CFRunLoopObserverRef o, CFRunLoopActivity a, void *info) {
  if (a == kCFRunLoopAfterWaiting) {
    probe_mark(K_ITER_START, 0);
  } else if (a == kCFRunLoopBeforeWaiting) {
    probe_mark(K_ITER_END, 0);
    if (g_pixel_watch && g_target) {
      double l = view_luma(g_target);
      if (g_pixel_watch == 1 && fabs(l - g_rest_luma) > 1.0) {
        probe_mark(K_PRESS_PIXELS, (int64_t)(l * 1000)); g_pixel_watch = 0;
      } else if (g_pixel_watch == 2 && fabs(l - g_rest_luma) <= 1.0) {
        probe_mark(K_RELEASE_PIXELS, (int64_t)(l * 1000)); g_pixel_watch = 0;
      }
    }
  }
}

void *probe_create_window(double w, double h) {
  NSApplication *app = [NSApplication sharedApplication];
  [app setActivationPolicy:NSApplicationActivationPolicyRegular];
  g_win = [[NSWindow alloc] initWithContentRect:NSMakeRect(80, 80, w, h)
                                      styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                        backing:NSBackingStoreBuffered defer:NO];
  [g_win setTitle:@"latency-probe"];
  [g_win setReleasedWhenClosed:NO];
  [g_win makeKeyAndOrderFront:nil];
  [app activateIgnoringOtherApps:YES];
  return (__bridge void *)g_win;
}

void probe_set_content(void *view) {
  NSView *v = (__bridge NSView *)view;
  [g_win setContentView:v];
}

// Depth-first search for the n-th NSHostingView-backed descendant (SwiftUI
// controls are each hosted in their own view). Returns its center in window
// coordinates through out params.
static int g_seen;
static NSView *find_hosting(NSView *v, int n) {
  NSString *cls = NSStringFromClass([v class]);
  if ([cls containsString:@"HostingView"]) {
    if (g_seen == n) return v;
    g_seen++;
    return nil;
  }
  for (NSView *s in [v subviews]) { NSView *r = find_hosting(s, n); if (r) return r; }
  return nil;
}

int probe_target_nth_hosting(int n) {
  [[g_win contentView] layoutSubtreeIfNeeded];
  g_seen = 0;
  NSView *v = find_hosting([g_win contentView], n);
  if (!v) return 0;
  g_target = v;
  NSRect r = [v convertRect:[v bounds] toView:nil];
  g_click_pt = NSMakePoint(NSMidX(r), NSMidY(r));
  fprintf(stderr, "[probe] target %s frame=(%.0f,%.0f %.0fx%.0f)\n",
          [NSStringFromClass([v class]) UTF8String], r.origin.x, r.origin.y, r.size.width, r.size.height);
  return 1;
}

// After every rerender the target view is replaced, so re-resolve it.
void probe_retarget(int n) { probe_target_nth_hosting(n); }

static void post_mouse(NSEventType type) {
  NSEvent *e = [NSEvent mouseEventWithType:type location:g_click_pt modifierFlags:0
                                 timestamp:[[NSProcessInfo processInfo] systemUptime]
                              windowNumber:[g_win windowNumber] context:nil
                               eventNumber:0 clickCount:1 pressure:(type == NSEventTypeLeftMouseDown ? 1.0 : 0.0)];
  probe_mark(type == NSEventTypeLeftMouseDown ? K_MD_POST : K_MU_POST, 0);
  [NSApp postEvent:e atStart:NO];
}

typedef struct { int count; double interval_ms; double hold_ms; double start_delay_ms; } ClickPlan;
static ClickPlan g_plan;
static void (*g_done_cb)(void) = NULL;

static void *click_thread(void *arg) {
  usleep((useconds_t)(g_plan.start_delay_ms * 1000));
  uint64_t base = probe_now_ns();
  for (int i = 0; i < g_plan.count; i++) {
    uint64_t at = base + (uint64_t)(i * g_plan.interval_ms * 1e6) + (uint64_t)arc4random_uniform(17000000); // jitter so taps do not phase-lock to vsync
    while (probe_now_ns() < at) usleep(200);
    post_mouse(NSEventTypeLeftMouseDown);
    uint64_t up = at + (uint64_t)(g_plan.hold_ms * 1e6);
    while (probe_now_ns() < up) usleep(200);
    post_mouse(NSEventTypeLeftMouseUp);
  }
  usleep(1500 * 1000);
  dispatch_async(dispatch_get_main_queue(), ^{ if (g_done_cb) g_done_cb(); });
  return NULL;
}

void probe_start(int count, double interval_ms, double hold_ms, int watch_pixels, void (*done)(void)) {
  g_plan.count = count; g_plan.interval_ms = interval_ms; g_plan.hold_ms = hold_ms;
  g_plan.start_delay_ms = 1200; g_done_cb = done;

  CFRunLoopObserverRef o = CFRunLoopObserverCreate(NULL, kCFRunLoopAfterWaiting | kCFRunLoopBeforeWaiting,
                                                   true, LONG_MAX, observer_cb, NULL);
  CFRunLoopAddObserver(CFRunLoopGetMain(), o, kCFRunLoopCommonModes);

  g_ticker = [ProbeTicker new];
  g_link = [g_win displayLinkWithTarget:g_ticker selector:@selector(tick:)]; // the window outlives every rerender
  [g_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

  [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp)
                                        handler:^NSEvent *(NSEvent *e) {
    probe_mark(e.type == NSEventTypeLeftMouseDown ? K_MD_DISPATCH : K_MU_DISPATCH, 0);
    if (watch_pixels) {
      if (g_rest_luma < 0 || e.type == NSEventTypeLeftMouseDown) {
        if (e.type == NSEventTypeLeftMouseDown) { g_rest_luma = view_luma(g_target); g_pixel_watch = 1; }
      } else {
        g_pixel_watch = 2;
      }
    }
    return e;
  }];

  pthread_t t; pthread_create(&t, NULL, click_thread, NULL); pthread_detach(t);
}

// Re-read the target's rest luma (after a rerender replaced the view).
void probe_reset_rest(void) { g_rest_luma = -1; }

void probe_dump(const char *path) {
  FILE *f = fopen(path, "w");
  uint64_t n = atomic_load(&g_n); if (n > CAP) n = CAP;
  for (uint64_t i = 0; i < n; i++) fprintf(f, "%d %llu %lld\n", g_rows[i].kind, g_rows[i].t, g_rows[i].v);
  fclose(f);
}

void probe_run_app(void) { [NSApp run]; }
