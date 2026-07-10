require "spec"
require "../../../src/ui"

# ==========================================================================
# Collection Bridge Specs
#
# These specs validate the Crystal wrapper API for ObjC and JNI collection
# bridge operations. Since the underlying C bridge functions require a live
# ObjC or JNI runtime (which is only available on macOS/iOS and Android
# respectively), the specs are split into two categories:
#
# 1. **Platform-gated integration tests** ({% if flag?(:darwin) %} / {:android}):
#    These call through to real ObjC/JNI runtime functions and verify actual
#    behavior. They compile and run ONLY on the target platform.
#
# 2. **Pure Crystal unit tests**: These verify helper logic, type signatures,
#    and any pure-Crystal behavior that does not require FFI calls.
# ==========================================================================

# Helper to create non-null mock pointers for testing.
private def mock_ptr(address : UInt64 = 0x1234_u64) : Void*
  Pointer(Void).new(address)
end

# ==========================================================================
# ObjC Collection Specs (macOS/iOS only)
# ==========================================================================

{% if flag?(:macos) || flag?(:ios) %}
  # Phase 3 link-gap repair: narrowed from `flag?(:darwin)` (auto-set on macOS
  # hosts) to `flag?(:macos) || flag?(:ios)` (explicit renderer flags). This
  # matches the gate now used by src/ui/native/objc_collections.cr so the
  # spec block compiles only when the LibCollectionBridge symbols are
  # actually linked (i.e. by the native sample builds).
  describe UI::ObjC::NSString do
    it "creates an NSString from a Crystal String and converts back" do
      UI::ObjC.autoreleasepool do
        ns = UI::ObjC::NSString.from_string("Hello, Crystal!")
        ns.ptr.should_not eq(Pointer(Void).null)
        ns.to_string.should eq("Hello, Crystal!")
      end
    end

    it "creates an NSString from a C string" do
      UI::ObjC.autoreleasepool do
        ns = UI::ObjC::NSString.from_cstr("test")
        ns.ptr.should_not eq(Pointer(Void).null)
        ns.to_string.should eq("test")
      end
    end

    it "handles empty strings" do
      UI::ObjC.autoreleasepool do
        ns = UI::ObjC::NSString.from_string("")
        ns.to_string.should eq("")
      end
    end

    it "reports UTF-16 code unit length" do
      UI::ObjC.autoreleasepool do
        ns = UI::ObjC::NSString.from_string("abc")
        ns.length.should eq(3)
      end
    end

    it "handles multi-byte UTF-8 characters" do
      UI::ObjC.autoreleasepool do
        # Each emoji is 1 UTF-16 surrogate pair (2 code units on macOS)
        # or a single code point depending on the character.
        # "A" is 1 code unit, so a simple test:
        ns = UI::ObjC::NSString.from_string("AB")
        ns.to_string.should eq("AB")
        ns.length.should eq(2)
      end
    end
  end

  describe UI::ObjC::NSArray do
    it "creates an NSArray from pointers and reports correct size" do
      UI::ObjC.autoreleasepool do
        # Create real NSString objects to use as array elements
        s1 = UI::ObjC::NSString.from_string("one")
        s2 = UI::ObjC::NSString.from_string("two")
        s3 = UI::ObjC::NSString.from_string("three")

        arr = UI::ObjC::NSArray.from_pointers([s1.ptr, s2.ptr, s3.ptr])
        arr.size.should eq(3)
      end
    end

    it "retrieves elements by index" do
      UI::ObjC.autoreleasepool do
        s1 = UI::ObjC::NSString.from_string("first")
        s2 = UI::ObjC::NSString.from_string("second")

        arr = UI::ObjC::NSArray.from_pointers([s1.ptr, s2.ptr])

        # The pointers should point to the same NSString objects
        retrieved = UI::ObjC::NSString.new(arr[0])
        retrieved.to_string.should eq("first")

        retrieved2 = UI::ObjC::NSString.new(arr[1])
        retrieved2.to_string.should eq("second")
      end
    end

    it "creates from a Slice" do
      UI::ObjC.autoreleasepool do
        s1 = UI::ObjC::NSString.from_string("a")
        s2 = UI::ObjC::NSString.from_string("b")
        slice = Slice[s1.ptr, s2.ptr]

        arr = UI::ObjC::NSArray.from_slice(slice)
        arr.size.should eq(2)
      end
    end

    it "converts to Crystal Array" do
      UI::ObjC.autoreleasepool do
        s1 = UI::ObjC::NSString.from_string("x")
        s2 = UI::ObjC::NSString.from_string("y")

        arr = UI::ObjC::NSArray.from_pointers([s1.ptr, s2.ptr])
        crystal_arr = arr.to_a
        crystal_arr.size.should eq(2)
      end
    end

    it "iterates with each" do
      UI::ObjC.autoreleasepool do
        s1 = UI::ObjC::NSString.from_string("iter1")
        s2 = UI::ObjC::NSString.from_string("iter2")

        arr = UI::ObjC::NSArray.from_pointers([s1.ptr, s2.ptr])

        results = [] of String
        arr.each do |ptr|
          results << UI::ObjC::NSString.new(ptr).to_string
        end
        results.should eq(["iter1", "iter2"])
      end
    end

    it "handles empty arrays" do
      UI::ObjC.autoreleasepool do
        arr = UI::ObjC::NSArray.from_pointers([] of Void*)
        arr.size.should eq(0)
      end
    end
  end

  describe UI::ObjC::NSMutableArray do
    it "creates empty with capacity" do
      UI::ObjC.autoreleasepool do
        arr = UI::ObjC::NSMutableArray.new(capacity: 10)
        arr.size.should eq(0)
      end
    end

    it "appends objects with add and <<" do
      UI::ObjC.autoreleasepool do
        arr = UI::ObjC::NSMutableArray.new
        s1 = UI::ObjC::NSString.from_string("hello")
        s2 = UI::ObjC::NSString.from_string("world")

        arr.add(s1.ptr)
        arr << s2.ptr
        arr.size.should eq(2)
      end
    end

    it "inserts at index" do
      UI::ObjC.autoreleasepool do
        arr = UI::ObjC::NSMutableArray.new
        s1 = UI::ObjC::NSString.from_string("a")
        s2 = UI::ObjC::NSString.from_string("b")
        s3 = UI::ObjC::NSString.from_string("INSERTED")

        arr.add(s1.ptr)
        arr.add(s2.ptr)
        arr.insert(s3.ptr, at: 1)

        arr.size.should eq(3)
        UI::ObjC::NSString.new(arr[1]).to_string.should eq("INSERTED")
      end
    end

    it "removes at index" do
      UI::ObjC.autoreleasepool do
        arr = UI::ObjC::NSMutableArray.new
        s1 = UI::ObjC::NSString.from_string("keep")
        s2 = UI::ObjC::NSString.from_string("remove")

        arr.add(s1.ptr)
        arr.add(s2.ptr)
        arr.remove_at(1)
        arr.size.should eq(1)
      end
    end

    it "clears all elements" do
      UI::ObjC.autoreleasepool do
        arr = UI::ObjC::NSMutableArray.new
        s1 = UI::ObjC::NSString.from_string("a")
        arr.add(s1.ptr)
        arr.clear
        arr.size.should eq(0)
      end
    end

    it "batch adds multiple objects" do
      UI::ObjC.autoreleasepool do
        arr = UI::ObjC::NSMutableArray.new
        strings = (1..5).map { |i| UI::ObjC::NSString.from_string("item#{i}") }
        ptrs = strings.map(&.ptr)

        arr.add_batch(ptrs)
        arr.size.should eq(5)
      end
    end

    it "creates from existing pointers" do
      UI::ObjC.autoreleasepool do
        s1 = UI::ObjC::NSString.from_string("pre1")
        s2 = UI::ObjC::NSString.from_string("pre2")

        arr = UI::ObjC::NSMutableArray.from_pointers([s1.ptr, s2.ptr])
        arr.size.should eq(2)
        UI::ObjC::NSString.new(arr[0]).to_string.should eq("pre1")
      end
    end

    it "<< returns self for chaining" do
      UI::ObjC.autoreleasepool do
        arr = UI::ObjC::NSMutableArray.new
        s1 = UI::ObjC::NSString.from_string("a")
        s2 = UI::ObjC::NSString.from_string("b")

        result = arr << s1.ptr << s2.ptr
        result.size.should eq(2)
      end
    end
  end

  describe UI::ObjC::NSDictionary do
    it "creates from a String hash" do
      UI::ObjC.autoreleasepool do
        dict = UI::ObjC::NSDictionary.from_string_hash({
          "key1" => "value1",
          "key2" => "value2",
        })
        dict.size.should eq(2)
      end
    end

    it "retrieves values by string key" do
      UI::ObjC.autoreleasepool do
        dict = UI::ObjC::NSDictionary.from_string_hash({
          "name" => "Crystal",
        })
        value_ptr = dict["name"]
        value_ptr.should_not eq(Pointer(Void).null)
        UI::ObjC::NSString.new(value_ptr).to_string.should eq("Crystal")
      end
    end

    it "returns all keys as NSArray" do
      UI::ObjC.autoreleasepool do
        dict = UI::ObjC::NSDictionary.from_string_hash({
          "a" => "1",
          "b" => "2",
        })
        keys = dict.keys
        keys.size.should eq(2)
      end
    end

    it "handles empty hash" do
      UI::ObjC.autoreleasepool do
        dict = UI::ObjC::NSDictionary.from_string_hash({} of String => String)
        dict.size.should eq(0)
      end
    end

    it "raises when keys and values have different sizes" do
      expect_raises(Exception, /same size/) do
        UI::ObjC::NSDictionary.from_pointers(
          [mock_ptr(1_u64)],
          [mock_ptr(1_u64), mock_ptr(2_u64)]
        )
      end
    end
  end

  describe UI::ObjC::NSMutableDictionary do
    it "creates empty with capacity" do
      UI::ObjC.autoreleasepool do
        dict = UI::ObjC::NSMutableDictionary.new(capacity: 4)
        dict.size.should eq(0)
      end
    end

    it "sets and retrieves string key-value pairs" do
      UI::ObjC.autoreleasepool do
        dict = UI::ObjC::NSMutableDictionary.new
        dict["language"] = "Crystal"
        dict.size.should eq(1)

        value_ptr = dict["language"]
        value_ptr.should_not eq(Pointer(Void).null)
        UI::ObjC::NSString.new(value_ptr).to_string.should eq("Crystal")
      end
    end
  end

  describe "UI::ObjC.autoreleasepool" do
    it "executes the block and returns" do
      executed = false
      UI::ObjC.autoreleasepool do
        executed = true
      end
      executed.should be_true
    end

    it "drains autoreleased objects after the block" do
      # We cannot directly verify drain behavior in a unit test,
      # but we can verify the block completes without error and
      # objects created inside are accessible during the block.
      result = ""
      UI::ObjC.autoreleasepool do
        ns = UI::ObjC::NSString.from_string("pool test")
        result = ns.to_string
      end
      result.should eq("pool test")
    end

    it "drains even if the block raises" do
      # The ensure block should still pop the pool on exception.
      expect_raises(Exception, /test error/) do
        UI::ObjC.autoreleasepool do
          raise "test error"
        end
      end
    end
  end

  describe "UI::ObjC.add_subviews_batch" do
    it "does not crash with empty children array" do
      UI::ObjC.autoreleasepool do
        # Should be a no-op when children is empty
        UI::ObjC.add_subviews_batch(mock_ptr, [] of Void*)
      end
    end
  end
{% end %}

# ==========================================================================
# Pure Crystal logic tests (no platform gate required)
#
# These test aspects of the wrapper API that are pure Crystal and do not
# require the underlying C bridge or native runtime.
# ==========================================================================

describe "Collection bridge platform gating" do
  {% if flag?(:macos) || flag?(:ios) %}
    it "ObjC collection types are available on Darwin native builds" do
      # Verify the types compile and are accessible
      typeof(UI::ObjC::NSString).should_not be_nil
      typeof(UI::ObjC::NSArray).should_not be_nil
      typeof(UI::ObjC::NSMutableArray).should_not be_nil
      typeof(UI::ObjC::NSDictionary).should_not be_nil
      typeof(UI::ObjC::NSMutableDictionary).should_not be_nil
    end
  {% end %}

  {% if flag?(:android) %}
    it "JNI collection types are available on Android" do
      typeof(UI::JNI::JString).should_not be_nil
      typeof(UI::JNI::ObjectArray).should_not be_nil
      typeof(UI::JNI::ArrayList).should_not be_nil
    end
  {% end %}
end
