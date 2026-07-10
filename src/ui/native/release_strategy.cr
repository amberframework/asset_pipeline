# Enumerates how a `NativeHandle` should release its underlying pointer
# (ObjC retain/release, JNI global ref, manual, no-op, etc.).

module UI
  # Describes how a `NativeHandle` should release its underlying platform pointer.
  #
  # Each strategy maps to a specific platform memory management model:
  #
  # - `ObjCRelease`: The handle owns the pointer and will call `objc_release`
  #   when released. Use for ObjC objects that Crystal has retained (+1).
  #
  # - `ObjCBorrowed`: The pointer is a borrowed reference from the ObjC runtime.
  #   Crystal does NOT own it and must NOT release it. Typical for class objects,
  #   method return values that are autoreleased, or pointers into parent containers.
  #
  # - `JNIGlobalRef`: The pointer is a JNI global reference created via
  #   `NewGlobalRef`. Must be freed with `DeleteGlobalRef` via the JNI environment.
  #
  # - `Unowned`: The pointer's lifetime is managed externally. The handle is a
  #   tag-only wrapper. No release action is taken. Used for stack-allocated values,
  #   pointers managed by another system, or testing with mock pointers.
  enum ReleaseStrategy
    ObjCRelease
    ObjCBorrowed
    JNIGlobalRef
    Unowned
  end
end
