# Minimal Crystal bindings to the ObjC runtime (retain / release / autorelease)
# needed by NativeHandle for Apple-target memory management.

{% if flag?(:darwin) %}
  # Minimal ObjC runtime bindings needed for NativeHandle memory management.
  #
  # These are the standard ObjC runtime functions from Apple's libobjc.
  # Only the retain/release functions are bound here; full ObjC messaging
  # is handled by the bridge C file (objc_bridge.c) in the platform renderers.
  @[Link("objc")]
  lib LibObjCRuntime
    # Increment the retain count of an ObjC object.
    # Returns the same pointer (for chaining).
    fun objc_retain(obj : Void*) : Void*

    # Decrement the retain count of an ObjC object.
    # If the count reaches zero, the object is deallocated.
    fun objc_release(obj : Void*)
  end
{% end %}
