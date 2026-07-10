# Crystal wrappers for the ObjC collection bridge (NSArray / NSDictionary).
# Provides type-safe construction and access from Crystal on Apple targets.

{% if flag?(:macos) || flag?(:ios) %}
  # Crystal wrappers for Objective-C collection bridge operations.
  #
  # NOTE (Phase 3 link-gap repair, 2026-05-20): This module was previously
  # gated on `flag?(:darwin)`, which is auto-set on macOS hosts regardless
  # of whether a renderer flag was passed. That meant `crystal spec` from
  # the repo root (no `-Dmacos` / `-Dios`) tried to compile this module's
  # `lib LibCollectionBridge` references and then failed to link because
  # the implementing C trampolines live in code that is only compiled +
  # linked by the native sample builds. The narrower gate below restricts
  # the module to actual native-target builds (the sample apps, which
  # always pass `-Dmacos` or `-Dios` and explicitly link the bridge .m).
  # Crystal spec runs on macOS / Linux now skip this module entirely;
  # the spec-time `LibObjCBridge` / `LibSwiftKitBridge` shims live in
  # `spec/support/fake_lib_objc_bridge.cr`.
  #
  # These wrap the C functions defined in collection_bridge.c (Section 1:
  # Objective-C Collection Bridge). All returned ObjC objects follow standard
  # Cocoa memory management conventions:
  #
  # - **AUTORELEASED (+0)**: Most factory methods return autoreleased objects.
  #   Crystal does NOT own them. They live until the enclosing autorelease
  #   pool drains. Use `retain` if you need to store them longer.
  #
  # - **BORROWED (+0)**: Accessors like `[]` return pointers owned by their
  #   container. Do not release them.
  #
  # ## Batch Operations
  #
  # The primary design goal is minimizing Crystal-to-C bridge crossings.
  # Instead of N individual `addSubview:` calls, use `add_subviews_batch`
  # for a single crossing. Similarly, `stack_set_views` replaces N
  # `addArrangedSubview:` calls.
  #
  # ## Autorelease Pool Scoping
  #
  # Every render pass should be wrapped in an autorelease scope:
  #
  # ```
  # UI::ObjC.autoreleasepool do
  #   array = UI::ObjC::NSArray.from_pointers(child_ptrs)
  #   UI::ObjC.stack_set_views(stack_ptr, child_ptrs)
  # end
  # ```

  module UI
    module ObjC
      # Low-level lib bindings for the C collection bridge functions.
      # These mirror the function signatures in collection_bridge.c exactly.
      @[Link(framework: "Foundation")]
      lib LibCollectionBridge
        # -- NSString --
        fun nsstring_create(utf8_str : UInt8*) : Void*
        fun nsstring_create_with_bytes(bytes : UInt8*, byte_len : UInt64) : Void*
        fun nsstring_to_utf8(nsstring : Void*, out_len : UInt64*) : UInt8*
        fun nsstring_length(nsstring : Void*) : UInt64

        # -- NSArray (immutable) --
        fun nsarray_create(objects : Void**, count : UInt64) : Void*
        fun nsarray_count(nsarray : Void*) : UInt64
        fun nsarray_object_at(nsarray : Void*, index : UInt64) : Void*
        fun nsarray_get_objects(nsarray : Void*, out_buf : Void**, count : UInt64)

        # -- NSMutableArray --
        fun nsmutablearray_create(capacity : UInt64) : Void*
        fun nsmutablearray_create_from(objects : Void**, count : UInt64) : Void*
        fun nsmutablearray_add(marray : Void*, object : Void*)
        fun nsmutablearray_insert(marray : Void*, object : Void*, index : UInt64)
        fun nsmutablearray_remove_at(marray : Void*, index : UInt64)
        fun nsmutablearray_remove_all(marray : Void*)
        fun nsmutablearray_add_batch(marray : Void*, objects : Void**, count : UInt64)
        fun nsmutablearray_count(marray : Void*) : UInt64
        fun nsmutablearray_object_at(marray : Void*, index : UInt64) : Void*

        # -- NSDictionary --
        fun nsdictionary_create(keys : Void**, values : Void**, count : UInt64) : Void*
        fun nsmutabledictionary_create(capacity : UInt64) : Void*
        fun nsmutabledictionary_set(mdict : Void*, key : Void*, value : Void*)
        fun nsdictionary_get(dict : Void*, key : Void*) : Void*
        fun nsdictionary_all_keys(dict : Void*) : Void*
        fun nsdictionary_count(dict : Void*) : UInt64

        # -- Batch view operations --
        fun nsstack_set_views(stack_view : Void*, views : Void**, count : UInt64, gravity : Int64)
        fun objc_add_subviews_batch(parent : Void*, children : Void**, count : UInt64)

        # -- Autorelease pool --
        fun autorelease_pool_push : Void*
        fun autorelease_pool_pop(pool : Void*)

        # -- Retain/Release --
        fun objc_retain_object(obj : Void*) : Void*
        fun objc_release_object(obj : Void*)
        fun objc_autorelease_object(obj : Void*) : Void*
      end

      # ========================================================================
      # Autorelease pool scoping.
      #
      # Every render pass should be wrapped in an autorelease scope so that
      # temporary ObjC objects (NSStrings, NSArrays created by bridge helpers)
      # are cleaned up deterministically rather than waiting for a framework
      # pool drain.
      #
      # ```
      # UI::ObjC.autoreleasepool do
      #   array = UI::ObjC::NSArray.from_pointers(child_ptrs)
      #   UI::ObjC.stack_set_views(stack_ptr, child_ptrs)
      # end
      # ```
      # ========================================================================
      def self.autoreleasepool(&)
        pool = LibCollectionBridge.autorelease_pool_push
        begin
          yield
        ensure
          LibCollectionBridge.autorelease_pool_pop(pool)
        end
      end

      # Retain an ObjC object (+1). Use when storing a reference in Crystal
      # that must outlive the current autorelease scope.
      #
      # NOTE: This is distinct from `ObjC.retain(ptr, label:)` in objc_handle.cr,
      # which creates a `NativeHandle` wrapper. This method performs a raw
      # `objc_retain` on the pointer without wrapping it.
      def self.retain_object(obj : Void*) : Void*
        LibCollectionBridge.objc_retain_object(obj)
      end

      # Release an ObjC object (-1). Call when Crystal no longer needs
      # a retained reference.
      #
      # NOTE: This is a raw `objc_release` call, distinct from the
      # `NativeHandle#release!` lifecycle method.
      def self.release_object(obj : Void*)
        LibCollectionBridge.objc_release_object(obj)
      end

      # ========================================================================
      # NSString wrapper
      #
      # Memory ownership:
      #   .from_string / .from_cstr -> AUTORELEASED. Crystal does not own it.
      #     If you need to store it, call `retain`.
      #   .to_string -> Returns a Crystal String (GC-managed copy).
      #     The NSString can be released afterward.
      # ========================================================================
      struct NSString
        getter ptr : Void*

        def initialize(@ptr : Void*)
        end

        # Create from a Crystal String.
        # The Crystal string is copied into ObjC memory.
        # Returns an autoreleased NSString.
        #
        # Uses the byte-length variant so embedded NULs are preserved.
        def self.from_string(str : String) : NSString
          ptr = LibCollectionBridge.nsstring_create_with_bytes(
            str.to_unsafe, str.bytesize.to_u64)
          NSString.new(ptr)
        end

        # Shorthand for common case (no embedded NULs).
        # Uses `stringWithUTF8String:` which stops at the first NUL.
        def self.from_cstr(str : String) : NSString
          ptr = LibCollectionBridge.nsstring_create(str.to_unsafe)
          NSString.new(ptr)
        end

        # Convert back to Crystal String.
        # Makes a copy of the UTF-8 bytes so the NSString can be released.
        def to_string : String
          len = uninitialized UInt64
          utf8_ptr = LibCollectionBridge.nsstring_to_utf8(@ptr, pointerof(len))
          String.new(utf8_ptr, len.to_i32)
        end

        # UTF-16 code unit count (same as `-[NSString length]`).
        def length : UInt64
          LibCollectionBridge.nsstring_length(@ptr)
        end

        # Retain this NSString (+1). Returns self for chaining.
        def retain : NSString
          LibCollectionBridge.objc_retain_object(@ptr)
          self
        end

        # Release this NSString (-1).
        def release
          LibCollectionBridge.objc_release_object(@ptr)
        end
      end

      # ========================================================================
      # NSArray wrapper (immutable)
      #
      # Memory ownership:
      #   .from_pointers -> AUTORELEASED. The array retains its elements.
      #   .from_slice    -> AUTORELEASED. Same, but from a Slice.
      #   [index]        -> BORROWED pointer, owned by the array.
      # ========================================================================
      struct NSArray
        getter ptr : Void*

        def initialize(@ptr : Void*)
        end

        # Create from a Crystal array of ObjC object pointers.
        # This is the primary batch marshalling operation.
        #
        # ```
        # ptrs = [label.ptr, button.ptr, spacer.ptr]
        # arr = UI::ObjC::NSArray.from_pointers(ptrs)
        # ```
        def self.from_pointers(objects : Array(Void*)) : NSArray
          ptr = LibCollectionBridge.nsarray_create(
            objects.to_unsafe, objects.size.to_u64)
          NSArray.new(ptr)
        end

        # Create from a Slice (avoids Array allocation when building from
        # a stack buffer or pre-allocated region).
        def self.from_slice(objects : Slice(Void*)) : NSArray
          ptr = LibCollectionBridge.nsarray_create(
            objects.to_unsafe, objects.size.to_u64)
          NSArray.new(ptr)
        end

        def size : UInt64
          LibCollectionBridge.nsarray_count(@ptr)
        end

        def [](index : Int) : Void*
          LibCollectionBridge.nsarray_object_at(@ptr, index.to_u64)
        end

        # Copy all elements into a new Crystal Array(Void*).
        def to_a : Array(Void*)
          count = size
          buf = Array(Void*).new(count.to_i32, Pointer(Void).null)
          LibCollectionBridge.nsarray_get_objects(@ptr, buf.to_unsafe, count)
          buf
        end

        # Iterate over elements.
        def each(&)
          count = size
          i = 0_u64
          while i < count
            yield LibCollectionBridge.nsarray_object_at(@ptr, i)
            i += 1
          end
        end

        def retain : NSArray
          LibCollectionBridge.objc_retain_object(@ptr)
          self
        end

        def release
          LibCollectionBridge.objc_release_object(@ptr)
        end
      end

      # ========================================================================
      # NSMutableArray wrapper
      #
      # Memory ownership:
      #   .new(capacity)     -> AUTORELEASED.
      #   .from_pointers     -> AUTORELEASED.
      #   add/insert/remove  -> Mutates in place. The array manages element
      #                         retain counts.
      # ========================================================================
      struct NSMutableArray
        getter ptr : Void*

        def initialize(@ptr : Void*)
        end

        # Create empty with capacity hint.
        def self.new(capacity : Int = 0) : NSMutableArray
          ptr = LibCollectionBridge.nsmutablearray_create(capacity.to_u64)
          NSMutableArray.new(ptr)
        end

        # Create pre-populated from a Crystal array of pointers.
        def self.from_pointers(objects : Array(Void*)) : NSMutableArray
          ptr = LibCollectionBridge.nsmutablearray_create_from(
            objects.to_unsafe, objects.size.to_u64)
          NSMutableArray.new(ptr)
        end

        def add(object : Void*)
          LibCollectionBridge.nsmutablearray_add(@ptr, object)
        end

        def <<(object : Void*) : NSMutableArray
          add(object)
          self
        end

        def insert(object : Void*, at index : Int)
          LibCollectionBridge.nsmutablearray_insert(@ptr, object, index.to_u64)
        end

        def remove_at(index : Int)
          LibCollectionBridge.nsmutablearray_remove_at(@ptr, index.to_u64)
        end

        def clear
          LibCollectionBridge.nsmutablearray_remove_all(@ptr)
        end

        # Batch add: append multiple objects in one bridge crossing.
        def add_batch(objects : Array(Void*))
          LibCollectionBridge.nsmutablearray_add_batch(
            @ptr, objects.to_unsafe, objects.size.to_u64)
        end

        def size : UInt64
          LibCollectionBridge.nsmutablearray_count(@ptr)
        end

        def [](index : Int) : Void*
          LibCollectionBridge.nsmutablearray_object_at(@ptr, index.to_u64)
        end

        def retain : NSMutableArray
          LibCollectionBridge.objc_retain_object(@ptr)
          self
        end

        def release
          LibCollectionBridge.objc_release_object(@ptr)
        end
      end

      # ========================================================================
      # NSDictionary wrapper (immutable)
      #
      # Memory ownership:
      #   .from_pointers      -> AUTORELEASED.
      #   .from_string_hash   -> AUTORELEASED. Convenience for String->String.
      #   [key]               -> BORROWED, owned by the dictionary.
      # ========================================================================
      struct NSDictionary
        getter ptr : Void*

        def initialize(@ptr : Void*)
        end

        # Create from parallel arrays of ObjC object pointers.
        def self.from_pointers(keys : Array(Void*), values : Array(Void*)) : NSDictionary
          count = keys.size
          raise "keys and values must have same size" if count != values.size
          ptr = LibCollectionBridge.nsdictionary_create(
            keys.to_unsafe, values.to_unsafe, count.to_u64)
          NSDictionary.new(ptr)
        end

        # Create from a Crystal Hash(String, String).
        # Both keys and values are converted to NSString.
        # This is the common case for view properties.
        #
        # ```
        # props = {"accessibilityLabel" => "Submit button", "tag" => "42"}
        # dict = UI::ObjC::NSDictionary.from_string_hash(props)
        # ```
        def self.from_string_hash(hash : Hash(String, String)) : NSDictionary
          keys = Array(Void*).new(hash.size)
          values = Array(Void*).new(hash.size)

          hash.each do |k, v|
            keys << LibCollectionBridge.nsstring_create(k.to_unsafe).as(Void*)
            values << LibCollectionBridge.nsstring_create(v.to_unsafe).as(Void*)
          end

          from_pointers(keys, values)
        end

        def [](key : Void*) : Void*
          LibCollectionBridge.nsdictionary_get(@ptr, key)
        end

        def [](key : String) : Void*
          ns_key = LibCollectionBridge.nsstring_create(key.to_unsafe)
          LibCollectionBridge.nsdictionary_get(@ptr, ns_key)
        end

        def keys : NSArray
          NSArray.new(LibCollectionBridge.nsdictionary_all_keys(@ptr))
        end

        def size : UInt64
          LibCollectionBridge.nsdictionary_count(@ptr)
        end

        def retain : NSDictionary
          LibCollectionBridge.objc_retain_object(@ptr)
          self
        end

        def release
          LibCollectionBridge.objc_release_object(@ptr)
        end
      end

      # ========================================================================
      # NSMutableDictionary wrapper
      # ========================================================================
      struct NSMutableDictionary
        getter ptr : Void*

        def initialize(@ptr : Void*)
        end

        def self.new(capacity : Int = 0) : NSMutableDictionary
          ptr = LibCollectionBridge.nsmutabledictionary_create(capacity.to_u64)
          NSMutableDictionary.new(ptr)
        end

        def []=(key : Void*, value : Void*)
          LibCollectionBridge.nsmutabledictionary_set(@ptr, key, value)
        end

        # Convenience: set with Crystal strings.
        def []=(key : String, value : String)
          ns_key = LibCollectionBridge.nsstring_create(key.to_unsafe)
          ns_val = LibCollectionBridge.nsstring_create(value.to_unsafe)
          LibCollectionBridge.nsmutabledictionary_set(@ptr, ns_key, ns_val)
        end

        def [](key : Void*) : Void*
          LibCollectionBridge.nsdictionary_get(@ptr, key)
        end

        def [](key : String) : Void*
          ns_key = LibCollectionBridge.nsstring_create(key.to_unsafe)
          LibCollectionBridge.nsdictionary_get(@ptr, ns_key)
        end

        def size : UInt64
          LibCollectionBridge.nsdictionary_count(@ptr)
        end

        def retain : NSMutableDictionary
          LibCollectionBridge.objc_retain_object(@ptr)
          self
        end

        def release
          LibCollectionBridge.objc_release_object(@ptr)
        end
      end

      # ========================================================================
      # Batch view helpers
      #
      # These minimize Crystal-to-C bridge crossings for common view hierarchy
      # operations. Instead of N individual calls, one batch call is made.
      # ========================================================================

      # Set all arranged subviews of an NSStackView at once.
      # Uses `setViews:inGravity:` which is much faster than N individual
      # `addArrangedSubview:` calls.
      #
      # gravity: 0 = top/leading, 1 = center, 2 = bottom/trailing
      #
      # ```
      # child_ptrs = children.map(&.native_ptr)
      # UI::ObjC.stack_set_views(stack_view_ptr, child_ptrs, gravity: 1)
      # ```
      def self.stack_set_views(stack_view : Void*, views : Array(Void*), gravity : Int64 = 1_i64)
        LibCollectionBridge.nsstack_set_views(
          stack_view, views.to_unsafe, views.size.to_u64, gravity)
      end

      # Add multiple subviews to any NSView/UIView at once.
      # Single bridge crossing instead of N.
      #
      # Skips the call entirely if the children array is empty.
      def self.add_subviews_batch(parent : Void*, children : Array(Void*))
        return if children.empty?
        LibCollectionBridge.objc_add_subviews_batch(
          parent, children.to_unsafe, children.size.to_u64)
      end
    end
  end
{% end %}
