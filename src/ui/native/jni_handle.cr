# Factory methods that produce NativeHandle instances wrapping JNI global refs,
# encoding the correct ReleaseStrategy for cross-call lifetime management.

require "./native_handle"

module UI
  # Factory methods for creating `NativeHandle` instances that wrap JNI objects.
  #
  # JNI has two kinds of object references:
  #
  # - **Local refs**: Valid only within the current native method call or
  #   `PushLocalFrame`/`PopLocalFrame` scope. Automatically freed when the
  #   scope ends. Crystal does NOT need to manage these.
  #
  # - **Global refs**: Created via `NewGlobalRef`, valid across native calls
  #   until explicitly freed with `DeleteGlobalRef`. Crystal MUST manage these.
  #
  # `NativeHandle` only wraps global refs, because local refs have scoped
  # lifetimes that do not need GC safety nets.
  #
  # All factories are gated behind `flag?(:android)` to ensure zero JNI code
  # compiles on non-Android platforms.
  module JNI
    # Promote a JNI local ref to a global ref and wrap it in a `NativeHandle`.
    #
    # This calls `NewGlobalRef(env, local_ref)` to create a durable reference,
    # then wraps the result with `JNIGlobalRef` strategy. The local ref is NOT
    # deleted -- the caller or the enclosing local frame will handle that.
    #
    # The `env` pointer is needed for the `NewGlobalRef` call but is NOT stored
    # in the handle. JNI global refs must be deleted with a valid `JNIEnv*`
    # at release time -- this is handled by `NativeView`, which stores the env.
    def self.global(env : Void*, local_ref : Void*, label : String? = nil) : NativeHandle
      {% if flag?(:android) %}
        global_ptr = LibJNICollectionBridge.jni_new_global_ref(env, local_ref)
        NativeHandle.new(global_ptr, ReleaseStrategy::JNIGlobalRef, label: label)
      {% else %}
        # On non-Android platforms, create an Unowned handle as a no-op placeholder.
        # This allows shared code to compile on all platforms without #ifdef guards
        # at every call site.
        NativeHandle.new(local_ref, ReleaseStrategy::Unowned, label: label)
      {% end %}
    end

    # Wrap an existing JNI global ref that was already promoted externally.
    #
    # Use this when the global ref was created by Java code or another native
    # method and passed to Crystal. Crystal takes ownership and will call
    # `DeleteGlobalRef` on release.
    def self.wrap_global(global_ref : Void*, label : String? = nil) : NativeHandle
      NativeHandle.new(global_ref, ReleaseStrategy::JNIGlobalRef, label: label)
    end
  end
end
