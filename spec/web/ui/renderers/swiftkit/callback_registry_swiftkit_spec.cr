require "../../../spec_helper"
require "../../../../../src/ui"

# Phase 3 added two action-dispatch aliases plus a unified
# `invoke_swiftkit(token, value)` entry point on `UI::CallbackRegistry`.
# These specs lock down the behavior the renderer + the
# `ap_swiftkit_invoke_action` C trampoline rely on.

describe UI::CallbackRegistry do
  describe ".register_action" do
    it "returns a UInt64 token" do
      UI::CallbackRegistry.clear
      token = UI::CallbackRegistry.register_action { }
      token.should be_a(UInt64)
      token.should be > 0_u64
    end

    it "produces monotonically increasing tokens" do
      UI::CallbackRegistry.clear
      a = UI::CallbackRegistry.register_action { }
      b = UI::CallbackRegistry.register_action { }
      c = UI::CallbackRegistry.register_action { }
      (b > a).should be_true
      (c > b).should be_true
    end

    it "holds the proc by strong reference so GC cannot collect it" do
      UI::CallbackRegistry.clear
      fired = 0
      token = UI::CallbackRegistry.register_action { fired += 1 }
      # Force a few GC cycles to be sure the proc is not freed.
      3.times { GC.collect }
      UI::CallbackRegistry.invoke_swiftkit(token, 0.0)
      fired.should eq(1)
    end
  end

  describe ".register_action_with_value" do
    it "passes the Float64 through on dispatch" do
      UI::CallbackRegistry.clear
      received : Float64 = 0.0
      token = UI::CallbackRegistry.register_action_with_value { |v| received = v }
      UI::CallbackRegistry.invoke_swiftkit(token, 0.42)
      received.should eq(0.42)
    end
  end

  describe ".invoke_swiftkit" do
    it "is a no-op for an unknown token (no crash)" do
      UI::CallbackRegistry.clear
      # Bogus token must not raise.
      UI::CallbackRegistry.invoke_swiftkit(99_999_u64, 0.0)
    end

    it "is a no-op for token 0" do
      # `ap_swiftkit_invoke_action` short-circuits on token == 0 before
      # reaching the registry, but defending here too keeps the
      # registry safe if a future call site forgets the guard.
      UI::CallbackRegistry.clear
      registered = false
      UI::CallbackRegistry.register_action { registered = true }
      UI::CallbackRegistry.invoke_swiftkit(0_u64, 0.0)
      registered.should be_false
    end

    it "routes no-arg actions to the void registry" do
      UI::CallbackRegistry.clear
      fired = false
      token = UI::CallbackRegistry.register_action { fired = true }
      UI::CallbackRegistry.invoke_swiftkit(token, 0.0)
      fired.should be_true
    end

    it "routes value-arg actions to the Float64 registry" do
      UI::CallbackRegistry.clear
      seen : Float64 = 0.0
      token = UI::CallbackRegistry.register_action_with_value { |v| seen = v }
      UI::CallbackRegistry.invoke_swiftkit(token, 1.5)
      seen.should eq(1.5)
    end
  end
end
