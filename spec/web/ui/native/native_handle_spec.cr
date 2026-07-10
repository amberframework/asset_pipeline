require "spec"
require "../../../../src/ui"

# Create a mock pointer for testing. Using a non-null address
# avoids the null-pointer special case.
private def mock_ptr(address : UInt64 = 0x1234_u64) : Void*
  Pointer(Void).new(address)
end

describe UI::NativeHandle do
  # IMPORTANT: On Darwin, ObjCRelease strategy handles with fake pointers
  # will crash when perform_release calls objc_release on an invalid address.
  # All tests use Unowned strategy with fake pointers.
  # ObjCRelease strategy is tested only with null pointers (where perform_release
  # is skipped), verifying the strategy assignment and lifecycle logic.

  describe "#initialize" do
    it "creates a handle with Unowned strategy" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.strategy.should eq(UI::ReleaseStrategy::Unowned)
      handle.valid?.should be_true
      handle.released?.should be_false
    end

    it "creates a handle with ObjCBorrowed strategy" do
      # ObjCBorrowed is a no-op in perform_release, safe with fake pointers.
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::ObjCBorrowed)
      handle.strategy.should eq(UI::ReleaseStrategy::ObjCBorrowed)
      handle.valid?.should be_true
    end

    it "creates a handle with ObjCRelease strategy using null pointer" do
      # Use null pointer to avoid objc_release crash on fake address.
      handle = UI::NativeHandle.new(Pointer(Void).null, UI::ReleaseStrategy::ObjCRelease)
      handle.strategy.should eq(UI::ReleaseStrategy::ObjCRelease)
      handle.released?.should be_false
    end

    it "creates a handle with JNIGlobalRef strategy using null pointer" do
      # Use null pointer; JNIGlobalRef on non-Android is a no-op anyway,
      # but null prevents issues if the test ever runs on Android.
      handle = UI::NativeHandle.new(Pointer(Void).null, UI::ReleaseStrategy::JNIGlobalRef)
      handle.strategy.should eq(UI::ReleaseStrategy::JNIGlobalRef)
      handle.released?.should be_false
    end

    it "accepts an optional debug label" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned, label: "NSButton")
      handle.label.should eq("NSButton")
    end

    it "label defaults to nil" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.label.should be_nil
    end
  end

  describe "#ptr" do
    it "returns the raw pointer" do
      ptr = mock_ptr(0xDEAD_u64)
      handle = UI::NativeHandle.new(ptr, UI::ReleaseStrategy::Unowned)
      handle.ptr.should eq(ptr)
    end
  end

  describe "#ptr!" do
    it "returns the pointer when valid" do
      ptr = mock_ptr(0xBEEF_u64)
      handle = UI::NativeHandle.new(ptr, UI::ReleaseStrategy::Unowned)
      handle.ptr!.should eq(ptr)
    end

    it "raises after release" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned, label: "test-handle")
      handle.release!
      expect_raises(Exception, /released/) do
        handle.ptr!
      end
    end

    it "raises for null pointer" do
      handle = UI::NativeHandle.new(Pointer(Void).null, UI::ReleaseStrategy::Unowned, label: "null-handle")
      expect_raises(Exception, /null/) do
        handle.ptr!
      end
    end

    it "includes the label in the error message" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned, label: "MyButton")
      handle.release!
      expect_raises(Exception, /MyButton/) do
        handle.ptr!
      end
    end

    it "uses 'unlabeled' in the error when no label is set" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.release!
      expect_raises(Exception, /unlabeled/) do
        handle.ptr!
      end
    end
  end

  describe "#valid?" do
    it "returns true for a live handle with non-null pointer" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.valid?.should be_true
    end

    it "returns false after release" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.release!
      handle.valid?.should be_false
    end

    it "returns false for null pointer" do
      handle = UI::NativeHandle.new(Pointer(Void).null, UI::ReleaseStrategy::Unowned)
      handle.valid?.should be_false
    end
  end

  describe "#released?" do
    it "returns false before release" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.released?.should be_false
    end

    it "returns true after release" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.release!
      handle.released?.should be_true
    end
  end

  describe "#release!" do
    it "marks the handle as released" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.release!
      handle.released?.should be_true
    end

    it "poisons the pointer to null" do
      handle = UI::NativeHandle.new(mock_ptr(0xABCD_u64), UI::ReleaseStrategy::Unowned)
      handle.release!
      handle.ptr.should eq(Pointer(Void).null)
    end

    it "is idempotent: calling twice is safe" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.release!
      handle.release!  # should not raise
      handle.released?.should be_true
    end

    it "is idempotent with ObjCRelease strategy on null pointer" do
      # Null pointer causes perform_release to be skipped, so no
      # actual objc_release call is made.
      handle = UI::NativeHandle.new(Pointer(Void).null, UI::ReleaseStrategy::ObjCRelease)
      handle.release!
      handle.release!
      handle.released?.should be_true
      handle.ptr.should eq(Pointer(Void).null)
    end

    it "is idempotent with JNIGlobalRef strategy on null pointer" do
      handle = UI::NativeHandle.new(Pointer(Void).null, UI::ReleaseStrategy::JNIGlobalRef)
      handle.release!
      handle.release!
      handle.released?.should be_true
    end

    it "handles null pointer gracefully" do
      handle = UI::NativeHandle.new(Pointer(Void).null, UI::ReleaseStrategy::Unowned)
      handle.release!
      handle.released?.should be_true
      handle.ptr.should eq(Pointer(Void).null)
    end

    it "works with ObjCBorrowed strategy (no-op release)" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::ObjCBorrowed)
      handle.release!
      handle.released?.should be_true
      handle.ptr.should eq(Pointer(Void).null)
    end
  end

  describe "ReleaseStrategy enum" do
    it "has all four strategies" do
      UI::ReleaseStrategy::ObjCRelease.value.should be_a(Int32)
      UI::ReleaseStrategy::ObjCBorrowed.value.should be_a(Int32)
      UI::ReleaseStrategy::JNIGlobalRef.value.should be_a(Int32)
      UI::ReleaseStrategy::Unowned.value.should be_a(Int32)
    end

    it "ObjCBorrowed does not perform release (safe with fake ptr)" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::ObjCBorrowed)
      handle.release!
      handle.released?.should be_true
    end
  end

  describe "ObjC factory" do
    it ".owned creates an ObjCRelease handle" do
      # Use null pointer to avoid objc_release crash on fake address
      # during GC finalization.
      handle = UI::ObjC.owned(Pointer(Void).null, label: "NSView")
      handle.strategy.should eq(UI::ReleaseStrategy::ObjCRelease)
      handle.label.should eq("NSView")
    end

    it ".borrowed creates an ObjCBorrowed handle" do
      handle = UI::ObjC.borrowed(mock_ptr, label: "borrowed-NSView")
      handle.strategy.should eq(UI::ReleaseStrategy::ObjCBorrowed)
      handle.valid?.should be_true
    end

    it ".retain creates an ObjCRelease handle" do
      # .retain calls objc_retain on the pointer. On Darwin,
      # objc_retain(nil) is a documented no-op, so use null.
      handle = UI::ObjC.retain(Pointer(Void).null, label: "retained-NSView")
      handle.strategy.should eq(UI::ReleaseStrategy::ObjCRelease)
    end

    it ".class_ref creates an Unowned handle" do
      handle = UI::ObjC.class_ref(mock_ptr, label: "NSButton class")
      handle.strategy.should eq(UI::ReleaseStrategy::Unowned)
      handle.valid?.should be_true
    end
  end

  describe "#state_handle (Phase 3 Remediation 4 reactive bridge)" do
    it "defaults to nil" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.state_handle.should be_nil
    end

    it "stores and reads back an opaque pointer" do
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      state_ptr = Pointer(Void).new(0xCAFE_u64)
      handle.state_handle = state_ptr
      handle.state_handle.should eq(state_ptr)
    end

    it "clears the state handle on release! (no double-free)" do
      # Use Unowned strategy so release! is a no-op against the platform
      # pointer; the state handle path is what we want to exercise.
      # apsk_state_release is gated on macos/ios — on spec builds the
      # release_state_handle! body falls through to a nil assign only.
      handle = UI::NativeHandle.new(mock_ptr, UI::ReleaseStrategy::Unowned)
      handle.state_handle = Pointer(Void).new(0xCAFE_u64)
      handle.release!
      handle.state_handle.should be_nil
      # Idempotent: second release! is safe.
      handle.release!
      handle.state_handle.should be_nil
    end
  end

  describe "JNI factory" do
    it ".global creates a handle" do
      # On non-Android, this creates an Unowned handle as a placeholder.
      handle = UI::JNI.global(mock_ptr(0x1_u64), mock_ptr(0x2_u64), label: "JNI-View")
      handle.label.should eq("JNI-View")
      handle.valid?.should be_true
    end

    it ".wrap_global creates a JNIGlobalRef handle" do
      # Use null pointer to avoid potential issues.
      handle = UI::JNI.wrap_global(Pointer(Void).null, label: "JNI-global")
      handle.strategy.should eq(UI::ReleaseStrategy::JNIGlobalRef)
    end
  end
end
