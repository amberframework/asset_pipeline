require "spec"
require "../../../src/ui/state"

describe UI::State do
  describe "State(Int32)" do
    it "stores and retrieves initial value" do
      state = UI::State(Int32).new(42)
      state.value.should eq(42)
    end

    it "updates value via setter" do
      state = UI::State(Int32).new(0)
      state.value = 10
      state.value.should eq(10)
    end
  end

  describe "State(String)" do
    it "stores and retrieves a string value" do
      state = UI::State(String).new("hello")
      state.value.should eq("hello")
    end

    it "updates string value" do
      state = UI::State(String).new("hello")
      state.value = "world"
      state.value.should eq("world")
    end
  end

  describe "State(Bool)" do
    it "stores and retrieves a boolean value" do
      state = UI::State(Bool).new(false)
      state.value.should be_false
    end

    it "updates boolean value" do
      state = UI::State(Bool).new(false)
      state.value = true
      state.value.should be_true
    end
  end

  describe "on_change listeners" do
    it "triggers listener with old and new values when value changes" do
      state = UI::State(Int32).new(0)
      received_old = -1
      received_new = -1

      state.on_change do |old_val, new_val|
        received_old = old_val
        received_new = new_val
      end

      state.value = 5
      received_old.should eq(0)
      received_new.should eq(5)
    end

    it "does NOT trigger listener when same value is set" do
      state = UI::State(Int32).new(10)
      call_count = 0

      state.on_change do |_old, _new|
        call_count += 1
      end

      state.value = 10 # same value
      call_count.should eq(0)
    end

    it "fires multiple listeners when value changes" do
      state = UI::State(String).new("a")
      results = [] of String

      state.on_change do |old_val, new_val|
        results << "listener1: #{old_val}->#{new_val}"
      end

      state.on_change do |old_val, new_val|
        results << "listener2: #{old_val}->#{new_val}"
      end

      state.value = "b"
      results.size.should eq(2)
      results[0].should eq("listener1: a->b")
      results[1].should eq("listener2: a->b")
    end

    it "fires listener for each successive change" do
      state = UI::State(Int32).new(0)
      changes = [] of {Int32, Int32}

      state.on_change do |old_val, new_val|
        changes << {old_val, new_val}
      end

      state.value = 1
      state.value = 2
      state.value = 3

      changes.size.should eq(3)
      changes[0].should eq({0, 1})
      changes[1].should eq({1, 2})
      changes[2].should eq({2, 3})
    end
  end

  describe "remove_listeners" do
    it "clears all listeners so they no longer fire" do
      state = UI::State(Int32).new(0)
      call_count = 0

      state.on_change { |_old, _new| call_count += 1 }
      state.on_change { |_old, _new| call_count += 1 }

      state.value = 1
      call_count.should eq(2)

      state.remove_listeners

      state.value = 2
      call_count.should eq(2) # no additional calls
    end
  end
end
