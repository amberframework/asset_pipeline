require "spec"
require "../../../../src/ui"

describe UI::CallbackRegistry do
  # Clean up the registry between tests to prevent state leaking.
  after_each do
    UI::CallbackRegistry.clear
  end

  describe ".register" do
    it "returns a unique ID for each registration" do
      id1 = UI::CallbackRegistry.register(->{ })
      id2 = UI::CallbackRegistry.register(->{ })
      id1.should_not eq(id2)
    end

    it "returns monotonically increasing IDs" do
      id1 = UI::CallbackRegistry.register(->{ })
      id2 = UI::CallbackRegistry.register(->{ })
      id3 = UI::CallbackRegistry.register(->{ })
      (id2 > id1).should be_true
      (id3 > id2).should be_true
    end

    it "registers with a block" do
      called = false
      id = UI::CallbackRegistry.register { called = true }
      UI::CallbackRegistry.call(id)
      called.should be_true
    end

    it "registers with a Proc" do
      called = false
      callback = Proc(Nil).new { called = true }
      id = UI::CallbackRegistry.register(callback)
      UI::CallbackRegistry.call(id)
      called.should be_true
    end

    it "increments size" do
      UI::CallbackRegistry.size.should eq(0)
      UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.size.should eq(1)
      UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.size.should eq(2)
    end
  end

  describe ".call" do
    it "invokes the registered proc" do
      call_count = 0
      id = UI::CallbackRegistry.register { call_count += 1 }
      UI::CallbackRegistry.call(id)
      call_count.should eq(1)
    end

    it "can invoke the same callback multiple times" do
      call_count = 0
      id = UI::CallbackRegistry.register { call_count += 1 }
      UI::CallbackRegistry.call(id)
      UI::CallbackRegistry.call(id)
      UI::CallbackRegistry.call(id)
      call_count.should eq(3)
    end

    it "is a safe no-op for an unknown ID" do
      # Should not raise or crash
      UI::CallbackRegistry.call(999999_u64)
    end

    it "is a safe no-op for an unregistered ID" do
      id = UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.unregister(id)
      # Should not raise or crash
      UI::CallbackRegistry.call(id)
    end

    it "invokes distinct callbacks independently" do
      results = [] of String
      id1 = UI::CallbackRegistry.register { results << "first" }
      id2 = UI::CallbackRegistry.register { results << "second" }
      UI::CallbackRegistry.call(id2)
      UI::CallbackRegistry.call(id1)
      results.should eq(["second", "first"])
    end
  end

  describe ".unregister" do
    it "removes the callback" do
      id = UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.size.should eq(1)
      UI::CallbackRegistry.unregister(id)
      UI::CallbackRegistry.size.should eq(0)
    end

    it "prevents future calls from invoking the proc" do
      called = false
      id = UI::CallbackRegistry.register { called = true }
      UI::CallbackRegistry.unregister(id)
      UI::CallbackRegistry.call(id)
      called.should be_false
    end

    it "is safe to call with an unknown ID" do
      # Should not raise
      UI::CallbackRegistry.unregister(999999_u64)
    end

    it "is idempotent: double unregister is safe" do
      id = UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.unregister(id)
      UI::CallbackRegistry.unregister(id)  # should not raise
      UI::CallbackRegistry.size.should eq(0)
    end
  end

  describe ".unregister(ids)" do
    it "removes multiple callbacks at once" do
      id1 = UI::CallbackRegistry.register(->{ })
      id2 = UI::CallbackRegistry.register(->{ })
      id3 = UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.size.should eq(3)
      UI::CallbackRegistry.unregister([id1, id3])
      UI::CallbackRegistry.size.should eq(1)
    end

    it "handles empty array" do
      UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.unregister([] of UInt64)
      UI::CallbackRegistry.size.should eq(1)
    end
  end

  describe ".size" do
    it "returns 0 when empty" do
      UI::CallbackRegistry.size.should eq(0)
    end

    it "reflects current count after registrations and unregistrations" do
      id1 = UI::CallbackRegistry.register(->{ })
      id2 = UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.size.should eq(2)
      UI::CallbackRegistry.unregister(id1)
      UI::CallbackRegistry.size.should eq(1)
      UI::CallbackRegistry.unregister(id2)
      UI::CallbackRegistry.size.should eq(0)
    end
  end

  describe ".clear" do
    it "removes all callbacks" do
      UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.size.should eq(3)
      UI::CallbackRegistry.clear
      UI::CallbackRegistry.size.should eq(0)
    end

    it "resets the ID counter" do
      id1 = UI::CallbackRegistry.register(->{ })
      UI::CallbackRegistry.clear
      id2 = UI::CallbackRegistry.register(->{ })
      # After clear, IDs restart from 1, so id2 should be small
      # (not necessarily equal to id1, but the counter is reset)
      (id2 <= id1).should be_true
    end
  end

  describe "typed callbacks" do
    it "registers and calls bool callbacks" do
      called_with = false
      id = UI::CallbackRegistry.register_bool(->(val : Bool) { called_with = val; nil })
      UI::CallbackRegistry.call_bool(id, true)
      called_with.should be_true
    end

    it "registers and calls float callbacks" do
      called_with = 0.0
      id = UI::CallbackRegistry.register_float(->(val : Float64) { called_with = val; nil })
      UI::CallbackRegistry.call_float(id, 0.75)
      called_with.should eq(0.75)
    end

    it "registers and calls int callbacks" do
      called_with = -1
      id = UI::CallbackRegistry.register_int(->(val : Int32) { called_with = val; nil })
      UI::CallbackRegistry.call_int(id, 3)
      called_with.should eq(3)
    end

    it "registers and calls string callbacks" do
      called_with = ""
      id = UI::CallbackRegistry.register_string(->(val : String) { called_with = val; nil })
      UI::CallbackRegistry.call_string(id, "hello")
      called_with.should eq("hello")
    end

    it "unregister removes from all typed hashes" do
      id1 = UI::CallbackRegistry.register(->() { nil })
      id2 = UI::CallbackRegistry.register_bool(->(val : Bool) { nil })
      UI::CallbackRegistry.size.should eq(2)
      UI::CallbackRegistry.unregister(id1)
      UI::CallbackRegistry.unregister(id2)
      UI::CallbackRegistry.size.should eq(0)
    end
  end
end
