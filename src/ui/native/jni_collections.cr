# Crystal wrappers for the JNI collection bridge (ArrayList / HashMap). Provides
# type-safe construction and access from Crystal code targeting Android.

{% if flag?(:android) %}
  # Crystal wrappers for JNI collection bridge operations.
  #
  # These wrap the C functions defined in collection_bridge.c (Section 2:
  # JNI Collection Bridge). All JNI functions require a `JNIEnv*` pointer
  # which is thread-local on Android and passed to every native method.
  #
  # ## JNI Reference Types
  #
  # - **LOCAL refs**: Valid only within the current native method call or
  #   `PushLocalFrame`/`PopLocalFrame` scope. Automatically freed when the
  #   scope ends. Most factory methods return local refs.
  #
  # - **GLOBAL refs**: Created via `NewGlobalRef`, valid across native calls
  #   until explicitly freed. Use `to_global` to promote local refs that
  #   Crystal needs to store long-term.
  #
  # ## Local Reference Hygiene
  #
  # JNI has a default limit of 512 local references per native call.
  # Bracket batch operations with `local_frame` to avoid exhaustion:
  #
  # ```
  # UI::JNI.local_frame(env, capacity: 64) do
  #   # create up to 64 local refs safely
  # end
  # ```
  #
  # ## Batch Operations
  #
  # Like the ObjC bridge, the primary design goal is minimizing bridge
  # crossings. `viewgroup_add_views` replaces N individual `addView()` calls.

  # JNI environment pointer type.
  # On Android, every native method receives JNIEnv* as the first argument.
  alias JNIEnv = Void*

  module UI
    module JNI
      # Low-level lib bindings for the C JNI collection bridge functions.
      # These mirror the function signatures in collection_bridge.c exactly.
      lib LibJNICollectionBridge
        # -- jstring --
        fun jni_string_create(env : JNIEnv, utf8_str : UInt8*) : Void*
        fun jni_string_create_with_bytes(env : JNIEnv, bytes : UInt8*, byte_len : Int32) : Void*
        fun jni_string_to_utf8(env : JNIEnv, jstr : Void*, out_len : Int32*) : UInt8*
        fun jni_string_release_utf8(env : JNIEnv, jstr : Void*, utf8 : UInt8*)
        fun jni_string_length(env : JNIEnv, jstr : Void*) : Int32

        # -- jobjectArray --
        fun jni_object_array_create(env : JNIEnv, element_class : UInt8*,
                                    objects : Void**, count : Int32) : Void*
        fun jni_object_array_length(env : JNIEnv, jarr : Void*) : Int32
        fun jni_object_array_get(env : JNIEnv, jarr : Void*, index : Int32) : Void*

        # -- ArrayList --
        fun jni_arraylist_create(env : JNIEnv, objects : Void**, count : Int32) : Void*
        fun jni_arraylist_size(env : JNIEnv, list : Void*) : Int32
        fun jni_arraylist_get(env : JNIEnv, list : Void*, index : Int32) : Void*
        fun jni_arraylist_add(env : JNIEnv, list : Void*, object : Void*)
        fun jni_arraylist_remove_at(env : JNIEnv, list : Void*, index : Int32) : Void*
        fun jni_arraylist_clear(env : JNIEnv, list : Void*)

        # -- Batch ViewGroup operations --
        fun jni_viewgroup_add_views_batch(env : JNIEnv, view_group : Void*,
                                          children : Void**, count : Int32)
        fun jni_viewgroup_remove_all(env : JNIEnv, view_group : Void*)

        # -- Reference management --
        fun jni_new_global_ref(env : JNIEnv, local_ref : Void*) : Void*
        fun jni_delete_global_ref(env : JNIEnv, global_ref : Void*)
        fun jni_delete_local_ref(env : JNIEnv, local_ref : Void*)
        fun jni_push_local_frame(env : JNIEnv, capacity : Int32) : Int32
        fun jni_pop_local_frame(env : JNIEnv, result : Void*) : Void*

        # -- HashMap --
        fun jni_hashmap_create_string_string(env : JNIEnv, keys : UInt8**,
                                             values : UInt8**, count : Int32) : Void*
      end

      # ========================================================================
      # Local reference frame scoping.
      #
      # JNI has a limited local reference table (default 512 entries).
      # Bracket batch operations with a local frame to avoid exhaustion.
      #
      # ```
      # UI::JNI.local_frame(env, capacity: 64) do
      #   # create up to 64 local refs safely
      # end
      # ```
      # ========================================================================
      def self.local_frame(env : JNIEnv, capacity : Int32 = 32, &)
        if LibJNICollectionBridge.jni_push_local_frame(env, capacity) < 0
          raise "JNI: PushLocalFrame failed (out of memory)"
        end
        begin
          result = yield
          LibJNICollectionBridge.jni_pop_local_frame(env, Pointer(Void).null)
          result
        rescue ex
          LibJNICollectionBridge.jni_pop_local_frame(env, Pointer(Void).null)
          raise ex
        end
      end

      # ========================================================================
      # JString wrapper
      #
      # Memory ownership:
      #   .from_string     -> JNI LOCAL ref. Must be used before the native
      #                       method returns (or the local frame pops).
      #                       Call .to_global to promote to a global ref.
      #   .to_string       -> Crystal String (GC-managed copy). The jstring
      #                       can then be freed.
      # ========================================================================
      struct JString
        getter ptr : Void*
        getter env : JNIEnv

        def initialize(@env : JNIEnv, @ptr : Void*)
        end

        # Create from a Crystal String.
        # Uses byte-length variant to handle embedded NULs correctly.
        def self.from_string(env : JNIEnv, str : String) : JString
          ptr = LibJNICollectionBridge.jni_string_create_with_bytes(
            env, str.to_unsafe, str.bytesize.to_i32)
          JString.new(env, ptr)
        end

        # Fast path for simple strings (no embedded NULs).
        def self.from_cstr(env : JNIEnv, str : String) : JString
          ptr = LibJNICollectionBridge.jni_string_create(env, str.to_unsafe)
          JString.new(env, ptr)
        end

        # Convert to Crystal String (copies the data).
        def to_string : String
          len = uninitialized Int32
          utf8_ptr = LibJNICollectionBridge.jni_string_to_utf8(@env, @ptr, pointerof(len))
          begin
            String.new(utf8_ptr, len)
          ensure
            LibJNICollectionBridge.jni_string_release_utf8(@env, @ptr, utf8_ptr)
          end
        end

        # UTF-16 code unit count.
        def length : Int32
          LibJNICollectionBridge.jni_string_length(@env, @ptr)
        end

        # Promote to a global reference (survives beyond current native call).
        # Returns a new JString backed by a global ref.
        # Caller MUST call `.delete_global` when done.
        def to_global : JString
          global = LibJNICollectionBridge.jni_new_global_ref(@env, @ptr)
          JString.new(@env, global)
        end

        # Delete this local reference (free a slot).
        def delete_local
          LibJNICollectionBridge.jni_delete_local_ref(@env, @ptr)
        end

        # Delete a global reference.
        def delete_global
          LibJNICollectionBridge.jni_delete_global_ref(@env, @ptr)
        end
      end

      # ========================================================================
      # ObjectArray wrapper (fixed-size Java array)
      #
      # Memory ownership:
      #   .create -> JNI LOCAL ref.
      #   [index] -> JNI LOCAL ref (new ref each call -- delete when done).
      # ========================================================================
      struct ObjectArray
        getter ptr : Void*
        getter env : JNIEnv

        def initialize(@env : JNIEnv, @ptr : Void*)
        end

        # Create from a Crystal array of JNI object pointers.
        # element_class: JNI class descriptor (e.g., "android/view/View").
        def self.create(env : JNIEnv, element_class : String,
                        objects : Array(Void*)) : ObjectArray
          ptr = LibJNICollectionBridge.jni_object_array_create(
            env, element_class.to_unsafe,
            objects.to_unsafe, objects.size.to_i32)
          ObjectArray.new(env, ptr)
        end

        def size : Int32
          LibJNICollectionBridge.jni_object_array_length(@env, @ptr)
        end

        def [](index : Int) : Void*
          LibJNICollectionBridge.jni_object_array_get(@env, @ptr, index.to_i32)
        end

        def delete_local
          LibJNICollectionBridge.jni_delete_local_ref(@env, @ptr)
        end
      end

      # ========================================================================
      # ArrayList wrapper (dynamic Java list)
      #
      # Memory ownership:
      #   .create / .new  -> JNI LOCAL ref.
      #   add/remove      -> Mutates in place. The list manages element refs.
      #   [index]         -> JNI LOCAL ref.
      # ========================================================================
      struct ArrayList
        getter ptr : Void*
        getter env : JNIEnv

        def initialize(@env : JNIEnv, @ptr : Void*)
        end

        # Create pre-populated from a Crystal array of JNI object pointers.
        def self.create(env : JNIEnv, objects : Array(Void*)) : ArrayList
          ptr = LibJNICollectionBridge.jni_arraylist_create(
            env, objects.to_unsafe, objects.size.to_i32)
          ArrayList.new(env, ptr)
        end

        # Create empty.
        def self.create(env : JNIEnv) : ArrayList
          empty = Array(Void*).new(0)
          ptr = LibJNICollectionBridge.jni_arraylist_create(
            env, empty.to_unsafe, 0)
          ArrayList.new(env, ptr)
        end

        def size : Int32
          LibJNICollectionBridge.jni_arraylist_size(@env, @ptr)
        end

        def [](index : Int) : Void*
          LibJNICollectionBridge.jni_arraylist_get(@env, @ptr, index.to_i32)
        end

        def add(object : Void*)
          LibJNICollectionBridge.jni_arraylist_add(@env, @ptr, object)
        end

        def <<(object : Void*) : ArrayList
          add(object)
          self
        end

        def remove_at(index : Int) : Void*
          LibJNICollectionBridge.jni_arraylist_remove_at(@env, @ptr, index.to_i32)
        end

        def clear
          LibJNICollectionBridge.jni_arraylist_clear(@env, @ptr)
        end

        def to_global : ArrayList
          global = LibJNICollectionBridge.jni_new_global_ref(@env, @ptr)
          ArrayList.new(@env, global)
        end

        def delete_local
          LibJNICollectionBridge.jni_delete_local_ref(@env, @ptr)
        end

        def delete_global
          LibJNICollectionBridge.jni_delete_global_ref(@env, @ptr)
        end
      end

      # ========================================================================
      # Batch ViewGroup helpers
      # ========================================================================

      # Add multiple child views to a ViewGroup in one bridge crossing.
      # Equivalent to calling `viewGroup.addView(child)` for each child,
      # but with a single Crystal-to-C transition.
      #
      # Skips the call entirely if the children array is empty.
      def self.viewgroup_add_views(env : JNIEnv, view_group : Void*,
                                   children : Array(Void*))
        return if children.empty?
        LibJNICollectionBridge.jni_viewgroup_add_views_batch(
          env, view_group, children.to_unsafe, children.size.to_i32)
      end

      # Remove all child views from a ViewGroup.
      def self.viewgroup_remove_all(env : JNIEnv, view_group : Void*)
        LibJNICollectionBridge.jni_viewgroup_remove_all(env, view_group)
      end

      # ========================================================================
      # HashMap helper (for view properties)
      # ========================================================================

      # Create a Java HashMap<String,String> from a Crystal Hash.
      # Returns a JNI LOCAL ref.
      def self.hashmap_from_strings(env : JNIEnv, hash : Hash(String, String)) : Void*
        keys = Array(Pointer(UInt8)).new(hash.size)
        values = Array(Pointer(UInt8)).new(hash.size)

        hash.each do |k, v|
          keys << k.to_unsafe
          values << v.to_unsafe
        end

        LibJNICollectionBridge.jni_hashmap_create_string_string(
          env, keys.to_unsafe, values.to_unsafe, hash.size.to_i32)
      end
    end
  end
{% end %}
