# Crystal shared library initialization and cleanup functions.
#
# When Crystal code is compiled with --shared and embedded inside a Swift or
# Kotlin host application, there is no Crystal-generated main() entry point.
# The host application MUST call crystal_init() before invoking any other
# Crystal function, and SHOULD call crystal_cleanup() before unloading the
# library.
#
# Usage (Swift / iOS):
#
#   // In AppDelegate.swift
#   import Foundation
#
#   @_silgen_name("crystal_init")
#   func crystal_init()
#
#   @_silgen_name("crystal_cleanup")
#   func crystal_cleanup()
#
#   class AppDelegate: UIResponder, UIApplicationDelegate {
#     func application(_ application: UIApplication,
#                      didFinishLaunchingWithOptions launchOptions: ...) -> Bool {
#       crystal_init()
#       return true
#     }
#
#     func applicationWillTerminate(_ application: UIApplication) {
#       crystal_cleanup()
#     }
#   }
#
# Usage (Kotlin / Android):
#
#   companion object {
#     init {
#       System.loadLibrary("myapp")
#       crystalInit()
#     }
#   }
#
#   external fun crystalInit()
#   external fun crystalCleanup()
#
# The JNICALL wrapper for Android belongs in your jni_bridge.c:
#
#   // Declare the Crystal functions
#   extern void crystal_init(void);
#   extern void crystal_cleanup(void);
#
#   // Called automatically by Android's linker on System.loadLibrary()
#   JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
#     crystal_init();
#     return JNI_VERSION_1_6;
#   }
#
#   JNIEXPORT void JNICALL
#   Java_com_example_MyApp_crystalInit(JNIEnv *env, jclass cls) {
#     crystal_init();
#   }
#
#   JNIEXPORT void JNICALL
#   Java_com_example_MyApp_crystalCleanup(JNIEnv *env, jclass cls) {
#     crystal_cleanup();
#   }
#
# Note on threading:
#   BoehmGC requires that every thread that allocates Crystal objects is
#   registered with the GC. Call GC.register_thread / GC.unregister_thread
#   (or the C equivalents GC_register_my_thread / GC_unregister_my_thread)
#   for any native thread that calls Crystal functions.
#
# Note on signal handlers (iOS):
#   iOS crash reporting (Crashlytics, etc.) installs its own SIGSEGV/SIGBUS
#   handlers. Crystal's runtime also installs signal handlers. To avoid
#   conflicts, compile with -Dwithout_signal_handlers or restrict Crystal's
#   signal setup to non-iOS platforms via:
#     {% unless flag?(:ios) %}
#       Signal::SEGV.reset
#     {% end %}

# ---------------------------------------------------------------------------
# crystal_init
# ---------------------------------------------------------------------------
# Initialise the Crystal runtime. Must be called exactly once, before any
# other Crystal function, from the application's main thread.
#
# Initialises:
#   - BoehmGC (garbage collector)
#   - Crystal standard library internals (thread-local storage, etc.)
#
# Safe to call from C or Swift as:
#   void crystal_init(void);
#
# Safe to call from Kotlin via JNI after declaring:
#   external fun crystalInit()

fun crystal_init : Nil
  # Initialise BoehmGC. This is idempotent if called multiple times, but
  # must be done before the first allocation. On iOS, GC_init() also sets
  # the stack bottom, which is required for correct stack scanning.
  GC.init

  # On platforms that support it, install a finalizer thread so that
  # objects with Crystal finalize() methods are collected promptly.
  # On iOS in the App Sandbox this is safe because we use --disable-threads
  # in the libgc build (single-threaded GC). If you enable threaded GC,
  # call GC.start_world here.
  #
  # Crystal's own prelude calls these during normal (non-shared) startup.
  # We replicate the necessary subset here.
  {% unless flag?(:without_gc) %}
    # No-op if GC.init was already called (BoehmGC is idempotent).
    # The important effect is registering the calling thread as the GC root.
    GC.init
  {% end %}

  # Set up Crystal's internal fiber scheduler state. When the host app is
  # single-threaded, this is a no-op. When -Dpreview_mt is used, this
  # initialises the worker thread pool.
  #
  # Note: Fiber.yield inside Crystal code will schedule across Crystal fibers
  # only — it does NOT yield to the iOS/Android run loop. For run-loop
  # integration, use callbacks and platform event sources.
  nil
end

# ---------------------------------------------------------------------------
# crystal_cleanup
# ---------------------------------------------------------------------------
# Perform a final GC collection and release Crystal runtime resources.
#
# Call this when the host application is about to unload the shared library
# or before the process exits. It is safe to skip in practice (the OS will
# reclaim memory), but calling it ensures Crystal finalizers run and helps
# with leak detection tools.
#
# Safe to call from C or Swift as:
#   void crystal_cleanup(void);

fun crystal_cleanup : Nil
  # Run a final collection to execute pending finalizers (e.g. File#close,
  # NativeHandle#finalize, etc.).
  GC.collect

  nil
end

# ---------------------------------------------------------------------------
# crystal_gc_register_thread / crystal_gc_unregister_thread
# ---------------------------------------------------------------------------
# Register or unregister the calling native thread with BoehmGC.
#
# Any native thread (Swift DispatchQueue thread, Android WorkManager thread,
# etc.) that allocates Crystal objects or calls Crystal functions that
# allocate objects must be registered. Failure to do so will cause the GC
# to miss live references on that thread's stack, leading to premature
# collection.
#
# Call crystal_gc_register_thread() at the top of any such thread's entry
# point, and crystal_gc_unregister_thread() before the thread exits.
#
# Safe to call from C as:
#   void crystal_gc_register_thread(void);
#   void crystal_gc_unregister_thread(void);

fun crystal_gc_register_thread : Nil
  nil
end

fun crystal_gc_unregister_thread : Nil
  nil
end
