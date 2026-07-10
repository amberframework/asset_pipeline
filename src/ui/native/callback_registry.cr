# C-exported callback for the CrystalActionDispatcher ObjC class.
# Called from ObjC when a button's action fires: dispatch: -> crystal_ui_callback_dispatch(tag)
fun crystal_ui_callback_dispatch(tag : UInt64) : Void
  UI::CallbackRegistry.call(tag)
end

fun crystal_ui_string_callback_dispatch(tag : UInt64, value : UInt8*) : Void
  return if tag == 0_u64 || value.null?
  UI::CallbackRegistry.call_string(tag, String.new(value))
end

fun crystal_ui_string_bool_callback_dispatch(tag : UInt64, value : UInt8*) : Int32
  return 1 if tag == 0_u64

  resolved = value.null? ? "" : String.new(value)
  UI::CallbackRegistry.call_string_bool(tag, resolved) ? 1 : 0
end

fun crystal_ui_bool_callback_dispatch(tag : UInt64, value : Int32) : Void
  return if tag == 0_u64
  UI::CallbackRegistry.call_bool(tag, value != 0)
end

fun crystal_ui_float_callback_dispatch(tag : UInt64, value : Float64) : Void
  return if tag == 0_u64
  UI::CallbackRegistry.call_float(tag, value)
end

fun crystal_ui_int_callback_dispatch(tag : UInt64, value : Int32) : Void
  return if tag == 0_u64
  UI::CallbackRegistry.call_int(tag, value)
end

# -----------------------------------------------------------------------------
# SwiftKit action trampoline.
#
# Called by AssetPipelineSwiftKit's `CallbackBridge.fire(token:value:)` via
# the `@convention(c)` function pointer installed by
# `APSKRuntime.initialize(actionTrampoline:)`. The pointer to this `fun`
# is what Crystal hands to Swift during sample-app startup.
#
# `value` carries:
#   - 0.0 for no-arg callbacks (Button#on_tap)
#   - the new Float64 for Slider#on_change, Stepper#on_change
#   - 1.0/0.0 for Toggle#on_change (Bool encoded as Float64)
#
# Unknown tokens are a silent no-op (matches the existing crystal_ui_*
# convention so a callback firing after teardown does not crash).
# -----------------------------------------------------------------------------
fun ap_swiftkit_invoke_action(token : UInt64, value : Float64) : Void
  return if token == 0_u64
  UI::CallbackRegistry.invoke_swiftkit(token, value)
end

# Phase 6.10 Rem 4 (Item 1) — string-valued SwiftKit action trampoline.
#
# Called by AssetPipelineSwiftKit's `CallbackBridge.fireString(token:value:)`
# via the `@convention(c)` function pointer installed by
# `APSKRuntime.initialize(stringTrampoline:)`. Receives a NUL-terminated
# UTF-8 string that must be copied into a Crystal `String` before the
# pointer becomes invalid (Swift's `value.withCString` keeps the buffer
# alive only for the duration of the trampoline call).
fun ap_swiftkit_invoke_action_string(token : UInt64, value : LibC::Char*) : Void
  return if token == 0_u64
  return if value.null?
  text = String.new(value)
  UI::CallbackRegistry.invoke_swiftkit_string(token, text)
end

# The Crystal-side address of `ap_swiftkit_invoke_action` is needed by
# `apsk_runtime_initialize`. Producing it from Crystal is finicky —
# `->ap_swiftkit_invoke_action(...).pointer` works at one optimisation
# level and not another, and a wrapped `Proc.pointer` leaks the closure
# header into the @convention(c) ABI. The robust path is to resolve the
# symbol from C: the static linker has already emitted
# `_ap_swiftkit_invoke_action` (the underscore-prefixed Mach-O symbol)
# so `swiftkit_bridge.m` knows the function exists. A no-arg
# `apsk_runtime_install_action_trampoline()` C trampoline takes the
# Crystal address by name and forwards it into
# `[APSKRuntime initializeWithActionTrampoline:]`. Crystal renderers
# call the no-arg variant; the `fun apsk_runtime_initialize(void*)`
# Crystal binding stays available for tests that want to install a
# different trampoline.

module UI
  # Module-level registry that prevents Crystal `Proc` closures from being
  # garbage collected while native code holds references to them.
  #
  # ## Problem
  #
  # When Crystal passes a `Proc` as a C function pointer (e.g., to the ObjC
  # target-action mechanism or JNI callback bridge), BoehmGC may collect the
  # closure if no Crystal-side reference remains. This causes a use-after-free
  # crash when the native side later invokes the callback.
  #
  # ## Solution
  #
  # `CallbackRegistry` holds a strong reference to every registered `Proc` in
  # a module-level `Hash`. Each registration returns a unique `UInt64` ID that
  # the native side stores. When the native callback fires, it passes the ID
  # back to Crystal, which looks up and invokes the live `Proc`.
  #
  # ## Lifecycle
  #
  # 1. Register a callback: `id = CallbackRegistry.register(proc)`
  # 2. Pass `id` to the native side (stored in SEL name, JNI callback ID, etc.)
  # 3. Native fires: calls `crystal_ui_callback_dispatch(id)` -> `CallbackRegistry.call(id)`
  # 4. On teardown: `CallbackRegistry.unregister(id)` removes the strong reference
  #
  # ## Thread Safety
  #
  # The registry itself is not thread-safe. All registration,
  # unregistration, and callback dispatch should happen on the main thread,
  # which matches the normal UI callback model for AppKit/UIKit/Android.
  module CallbackRegistry
    private class VoidCallbackBox
      getter callback : Proc(Nil)

      def initialize(@callback : Proc(Nil))
      end
    end

    private class StringCallbackBox
      getter callback : Proc(String, Nil)

      def initialize(@callback : Proc(String, Nil))
      end
    end

    private class StringBoolCallbackBox
      getter callback : Proc(String, Bool)

      def initialize(@callback : Proc(String, Bool))
      end
    end

    private class BoolCallbackBox
      getter callback : Proc(Bool, Nil)

      def initialize(@callback : Proc(Bool, Nil))
      end
    end

    private class FloatCallbackBox
      getter callback : Proc(Float64, Nil)

      def initialize(@callback : Proc(Float64, Nil))
      end
    end

    private class IntCallbackBox
      getter callback : Proc(Int32, Nil)

      def initialize(@callback : Proc(Int32, Nil))
      end
    end

    private class TimeCallbackBox
      getter callback : Proc(Time, Nil)

      def initialize(@callback : Proc(Time, Nil))
      end
    end

    # Existing void callbacks (button taps)
    @@callbacks : Hash(UInt64, VoidCallbackBox)? = nil

    # String callbacks (text field changes)
    @@string_callbacks : Hash(UInt64, StringCallbackBox)? = nil

    # String -> Bool callbacks (navigation policy decisions)
    @@string_bool_callbacks : Hash(UInt64, StringBoolCallbackBox)? = nil

    # Bool callbacks (toggle changes)
    @@bool_callbacks : Hash(UInt64, BoolCallbackBox)? = nil

    # Float64 callbacks (slider changes)
    @@float_callbacks : Hash(UInt64, FloatCallbackBox)? = nil

    # Int32 callbacks (picker/segmented changes)
    @@int_callbacks : Hash(UInt64, IntCallbackBox)? = nil

    # Time callbacks (date/time picker changes)
    @@time_callbacks : Hash(UInt64, TimeCallbackBox)? = nil

    @@next_id : UInt64? = nil

    private def self.callbacks
      @@callbacks ||= Hash(UInt64, VoidCallbackBox).new
    end

    private def self.string_callbacks
      @@string_callbacks ||= Hash(UInt64, StringCallbackBox).new
    end

    private def self.string_bool_callbacks
      @@string_bool_callbacks ||= Hash(UInt64, StringBoolCallbackBox).new
    end

    private def self.bool_callbacks
      @@bool_callbacks ||= Hash(UInt64, BoolCallbackBox).new
    end

    private def self.float_callbacks
      @@float_callbacks ||= Hash(UInt64, FloatCallbackBox).new
    end

    private def self.int_callbacks
      @@int_callbacks ||= Hash(UInt64, IntCallbackBox).new
    end

    private def self.time_callbacks
      @@time_callbacks ||= Hash(UInt64, TimeCallbackBox).new
    end

    private def self.next_id
      current = @@next_id || 1_u64
      @@next_id = current + 1_u64
      current
    end

    # Register a callback proc and return its unique ID.
    #
    # The proc is held by strong reference until `unregister` is called.
    def self.register(callback : Proc(Nil)) : UInt64
      id = next_id
      callbacks[id] = VoidCallbackBox.new(callback)
      id
    end

    # Register a callback block and return its unique ID.
    #
    # Convenience overload that wraps a block in a Proc.
    def self.register(&block : -> Nil) : UInt64
      register(block)
    end

    # Invoke the callback registered under the given ID.
    #
    # If the ID is not found (e.g., it was already unregistered), this is
    # a safe no-op. This prevents crashes if a native callback fires after
    # the Crystal side has torn down.
    def self.call(id : UInt64) : Nil
      callbacks[id]?.try(&.callback.call)
    end

    # Register a String callback proc and return its unique ID.
    def self.register_string(callback : Proc(String, Nil)) : UInt64
      id = next_id
      string_callbacks[id] = StringCallbackBox.new(callback)
      id
    end

    # Invoke the String callback registered under the given ID.
    def self.call_string(id : UInt64, value : String) : Nil
      string_callbacks[id]?.try { |box| box.callback.call(value) }
    end

    # Register a String -> Bool callback proc and return its unique ID.
    def self.register_string_bool(callback : Proc(String, Bool)) : UInt64
      id = next_id
      string_bool_callbacks[id] = StringBoolCallbackBox.new(callback)
      id
    end

    # Invoke the String -> Bool callback registered under the given ID.
    #
    # Missing IDs default to `true` so native policy delegates stay permissive
    # instead of failing closed when a view has already been torn down.
    def self.call_string_bool(id : UInt64, value : String) : Bool
      string_bool_callbacks[id]?.try { |box| box.callback.call(value) } || true
    end

    # Register a Bool callback proc and return its unique ID.
    def self.register_bool(callback : Proc(Bool, Nil)) : UInt64
      id = next_id
      bool_callbacks[id] = BoolCallbackBox.new(callback)
      id
    end

    # Invoke the Bool callback registered under the given ID.
    def self.call_bool(id : UInt64, value : Bool) : Nil
      bool_callbacks[id]?.try { |box| box.callback.call(value) }
    end

    # Register a Float64 callback proc and return its unique ID.
    def self.register_float(callback : Proc(Float64, Nil)) : UInt64
      id = next_id
      float_callbacks[id] = FloatCallbackBox.new(callback)
      id
    end

    # Invoke the Float64 callback registered under the given ID.
    def self.call_float(id : UInt64, value : Float64) : Nil
      float_callbacks[id]?.try { |box| box.callback.call(value) }
    end

    # Register an Int32 callback proc and return its unique ID.
    def self.register_int(callback : Proc(Int32, Nil)) : UInt64
      id = next_id
      int_callbacks[id] = IntCallbackBox.new(callback)
      id
    end

    # Invoke the Int32 callback registered under the given ID.
    def self.call_int(id : UInt64, value : Int32) : Nil
      int_callbacks[id]?.try { |box| box.callback.call(value) }
    end

    # Register a Time callback proc and return its unique ID.
    def self.register_time(callback : Proc(Time, Nil)) : UInt64
      id = next_id
      time_callbacks[id] = TimeCallbackBox.new(callback)
      id
    end

    # Invoke the Time callback registered under the given ID.
    def self.call_time(id : UInt64, value : Time) : Nil
      time_callbacks[id]?.try { |box| box.callback.call(value) }
    end

    # -------------------------------------------------------------------------
    # Phase 3 — SwiftKit action dispatch surface.
    #
    # `register_action` and `register_action_with_value` are thin aliases
    # that route to the existing `register` / `register_float` machinery
    # while giving SwiftKit-aware callers a clearer name. The brief's
    # contract (implementation.md §8.1) explicitly calls for these names
    # so the renderer code reads "register a SwiftKit action" rather than
    # "register a Crystal Proc."
    #
    # `invoke_swiftkit(token, value)` dispatches to whichever typed
    # registry holds the token. Order matters only when a token id is
    # genuinely ambiguous; the next_id monotonic counter guarantees a
    # token resolves at most one registry, so the lookup order is
    # cosmetic. Unknown tokens are a silent no-op.
    # -------------------------------------------------------------------------

    # Register a no-arg SwiftKit action (Button#on_tap, MenuItem activation).
    # Returns the opaque `UInt64` token the Swift facade keeps.
    def self.register_action(&block : -> Nil) : UInt64
      register(block)
    end

    # Register a Float64-valued SwiftKit action (Slider#on_change,
    # Stepper#on_change, Toggle#on_change after Bool→Float64 coercion).
    def self.register_action_with_value(&block : Float64 -> Nil) : UInt64
      register_float(block)
    end

    # Dispatch a SwiftKit action by token. Called from the
    # `ap_swiftkit_invoke_action` C trampoline.
    #
    # Looks the token up across the relevant typed registries:
    #   1. The no-arg Proc(Nil) registry (Button taps fire here).
    #   2. The Float64 registry (Slider/Stepper/Toggle fire here).
    #
    # Unknown tokens fall through silently — mirrors the existing
    # `crystal_ui_*_callback_dispatch` convention so a stale callback
    # fired by Swift after Crystal teardown does not crash.
    def self.invoke_swiftkit(token : UInt64, value : Float64) : Nil
      if box = callbacks[token]?
        box.callback.call
      elsif box = float_callbacks[token]?
        box.callback.call(value)
      end
    end

    # Phase 6.10 Rem 4 (Item 1) — string-valued counterpart to
    # `invoke_swiftkit`. Routes `Proc(String, Nil)` callbacks fired by
    # AssetPipelineSwiftKit's string trampoline. Unknown tokens fall
    # through silently — mirrors the float channel's policy.
    def self.invoke_swiftkit_string(token : UInt64, value : String) : Nil
      if box = string_callbacks[token]?
        box.callback.call(value)
      end
    end

    # Remove the callback registered under the given ID.
    #
    # After this call, the `Proc` is eligible for GC and the ID will no
    # longer resolve. Safe to call with an ID that was already unregistered.
    # Checks all typed hashes.
    def self.unregister(id : UInt64) : Nil
      @@callbacks.try(&.delete(id))
      @@string_callbacks.try(&.delete(id))
      @@string_bool_callbacks.try(&.delete(id))
      @@bool_callbacks.try(&.delete(id))
      @@float_callbacks.try(&.delete(id))
      @@int_callbacks.try(&.delete(id))
      @@time_callbacks.try(&.delete(id))
    end

    # Remove multiple callbacks by their IDs.
    #
    # Convenience method for bulk cleanup during `NativeView#teardown!`.
    def self.unregister(ids : Array(UInt64)) : Nil
      ids.each { |id| unregister(id) }
    end

    # Returns the number of currently registered callbacks across all typed hashes.
    def self.size : Int32
      (@@callbacks.try(&.size) || 0) + (@@string_callbacks.try(&.size) || 0) +
        (@@string_bool_callbacks.try(&.size) || 0) + (@@bool_callbacks.try(&.size) || 0) +
        (@@float_callbacks.try(&.size) || 0) + (@@int_callbacks.try(&.size) || 0) +
        (@@time_callbacks.try(&.size) || 0)
    end

    # Remove all registered callbacks from all typed hashes.
    #
    # Intended for use in test cleanup (`Spec.after_each`). Do NOT call
    # this in production code -- use `unregister` for targeted cleanup.
    def self.clear : Nil
      @@callbacks.try(&.clear)
      @@string_callbacks.try(&.clear)
      @@string_bool_callbacks.try(&.clear)
      @@bool_callbacks.try(&.clear)
      @@float_callbacks.try(&.clear)
      @@int_callbacks.try(&.clear)
      @@time_callbacks.try(&.clear)
      @@next_id = 1_u64
    end
  end
end
