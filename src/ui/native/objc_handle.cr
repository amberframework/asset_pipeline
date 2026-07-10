# Factory methods that produce NativeHandle instances wrapping ObjC objects,
# encoding the correct ReleaseStrategy (owned / borrowed / autoreleased).

require "./native_handle"

module UI
  # Factory methods for creating `NativeHandle` instances that wrap ObjC objects.
  #
  # Each factory encodes the correct `ReleaseStrategy` for the ownership model:
  #
  # - `owned`: Crystal owns the pointer (+1 retain count). Will call `objc_release`
  #   on cleanup. Use for objects returned by `alloc/init`, `copy`, `mutableCopy`,
  #   or any method where Crystal has explicitly retained the result.
  #
  # - `borrowed`: Crystal does NOT own the pointer. No release will occur.
  #   Use for autoreleased return values, pointers borrowed from containers,
  #   or objects whose lifetime is managed by a parent view hierarchy.
  #
  # - `retain`: Immediately calls `objc_retain` on the pointer to take ownership,
  #   then wraps it with `ObjCRelease` strategy. Use when you receive an autoreleased
  #   object that you need to store beyond the current autorelease scope.
  #
  # - `class_ref`: Wraps an ObjC class pointer (e.g., from `objc_getClass`).
  #   Class objects are never released; uses `Unowned` strategy.
  #
  # All factories are gated behind `flag?(:darwin)` to ensure zero ObjC code
  # compiles on non-Apple platforms.
  module ObjC
    # Wrap an ObjC pointer that Crystal already owns (+1 retain count).
    # The handle will call `objc_release` when released.
    def self.owned(ptr : Void*, label : String? = nil) : NativeHandle
      NativeHandle.new(ptr, ReleaseStrategy::ObjCRelease, label: label)
    end

    # Wrap a borrowed ObjC pointer that Crystal does NOT own.
    # No release action will be taken.
    def self.borrowed(ptr : Void*, label : String? = nil) : NativeHandle
      NativeHandle.new(ptr, ReleaseStrategy::ObjCBorrowed, label: label)
    end

    # Retain an ObjC pointer (+1) and wrap it as owned.
    # Use when you need to extend the lifetime of an autoreleased object.
    def self.retain(ptr : Void*, label : String? = nil) : NativeHandle
      {% if flag?(:darwin) %}
        LibObjCRuntime.objc_retain(ptr)
      {% end %}
      NativeHandle.new(ptr, ReleaseStrategy::ObjCRelease, label: label)
    end

    # Wrap an ObjC class object pointer.
    # Class objects are singletons managed by the ObjC runtime and are
    # never released. Uses `Unowned` strategy.
    def self.class_ref(ptr : Void*, label : String? = nil) : NativeHandle
      NativeHandle.new(ptr, ReleaseStrategy::Unowned, label: label)
    end
  end
end
