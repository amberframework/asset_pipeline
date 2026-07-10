require "../spec_helper"
require "../../../src/ui"

describe UI::FormState do
  describe "core registry" do
    it "register seeds initial values" do
      fs = UI::FormState.new(mount_token: 1_i64)
      fs.register("email", "seth@example.com")
      fs["email"].should eq("seth@example.com")
    end

    it "register is no-op if key already present (preserves user input)" do
      fs = UI::FormState.new(mount_token: 1_i64)
      fs.update("email", "user_typed")
      fs.register("email", "default")
      fs["email"].should eq("user_typed")
    end

    it "update mutates the value for a key" do
      fs = UI::FormState.new(mount_token: 1_i64)
      fs.update("email", "first")
      fs.update("email", "second")
      fs["email"].should eq("second")
    end

    it "[] returns empty string for unknown keys" do
      UI::FormState.new["missing"].should eq("")
    end

    it "[]? returns nil for unknown keys" do
      UI::FormState.new["missing"]?.should be_nil
    end

    it "to_h returns a defensive copy of values" do
      fs = UI::FormState.new(mount_token: 1_i64)
      fs.update("k", "v")
      snapshot = fs.to_h
      snapshot["k"] = "mutated"
      fs["k"].should eq("v")
    end

    it "carries a mount_token" do
      UI::FormState.new(mount_token: 42_i64).mount_token.should eq(42_i64)
    end

    it "initial values pre-seed the registry" do
      fs = UI::FormState.new(mount_token: 1_i64, initial: {"email" => "pre"})
      fs["email"].should eq("pre")
    end

    it "legacy zero-arg new returns a FormState with mount_token 0" do
      UI::FormState.new.mount_token.should eq(0_i64)
    end
  end

  describe "renderer hook surface (UI::FormState.current / current_mount_token)" do
    it "current and current_mount_token start at nil / 0" do
      UI::FormState.reset_renderer_hooks!
      UI::FormState.current.should be_nil
      UI::FormState.current_mount_token.should eq(0_i64)
    end

    it "the dispatcher's writes (current=, current_mount_token=) are observable" do
      UI::FormState.reset_renderer_hooks!
      fs = UI::FormState.new(mount_token: 7_i64)
      UI::FormState.current = fs
      UI::FormState.current_mount_token = 7_i64

      UI::FormState.current.should be(fs)
      UI::FormState.current_mount_token.should eq(7_i64)
    end

    it "reset_renderer_hooks! clears current + token" do
      UI::FormState.current = UI::FormState.new(mount_token: 9_i64)
      UI::FormState.current_mount_token = 9_i64
      UI::FormState.reset_renderer_hooks!
      UI::FormState.current.should be_nil
      UI::FormState.current_mount_token.should eq(0_i64)
    end
  end

  describe "FormStateRendererHook.wrap_text_handler" do
    it "returns nil when view has no name and no on_change" do
      UI::FormState.reset_renderer_hooks!
      tf = UI::TextField.new(placeholder: "Email")
      UI::FormStateRendererHook.wrap_text_handler(tf).should be_nil
    end

    it "returns the original on_change unchanged when view has no name" do
      observed = [] of String
      handler = ->(v : String) { observed << v; nil }
      tf = UI::TextField.new(placeholder: "Email")
      tf.on_change = handler

      wrapped = UI::FormStateRendererHook.wrap_text_handler(tf).not_nil!
      wrapped.call("hi")
      # If wrapped IS the original handler, our observed array gets "hi".
      observed.should eq(["hi"])
    end

    it "registers initial value when view has a name and FormState.current is set" do
      UI::FormState.reset_renderer_hooks!
      fs = UI::FormState.new(mount_token: 5_i64)
      UI::FormState.current = fs
      UI::FormState.current_mount_token = 5_i64

      tf = UI::TextField.new(placeholder: "Email", name: "email", text: "seed@example.com")
      UI::FormStateRendererHook.wrap_text_handler(tf)
      fs["email"].should eq("seed@example.com")
    end

    it "wrapped handler updates form_state with mount-token guard + invokes user handler" do
      UI::FormState.reset_renderer_hooks!
      fs = UI::FormState.new(mount_token: 1_i64)
      UI::FormState.current = fs
      UI::FormState.current_mount_token = 1_i64

      observed = [] of String
      tf = UI::TextField.new(placeholder: "Email", name: "email")
      tf.on_change = ->(v : String) { observed << v; nil }

      wrapped = UI::FormStateRendererHook.wrap_text_handler(tf).not_nil!
      wrapped.call("seth@example.com")

      fs["email"].should eq("seth@example.com")
      observed.should eq(["seth@example.com"])
    end

    it "wrapped handler is a no-op against form_state if mount token mismatch" do
      UI::FormState.reset_renderer_hooks!
      fs_a = UI::FormState.new(mount_token: 1_i64)
      UI::FormState.current = fs_a
      UI::FormState.current_mount_token = 1_i64

      tf = UI::TextField.new(placeholder: "Email", name: "email")
      wrapped = UI::FormStateRendererHook.wrap_text_handler(tf).not_nil!

      # Simulate navigation: dispatcher swaps FormState
      fs_b = UI::FormState.new(mount_token: 2_i64)
      UI::FormState.current = fs_b
      UI::FormState.current_mount_token = 2_i64

      # At wire-time, the hook called register("email", view.text="").
      # So fs_a["email"] was seeded to "". The stale-fire must NOT
      # overwrite that to "STALE".
      fs_a["email"].should eq("")

      # Stale fire — should NOT write to fs_a
      wrapped.call("STALE")
      fs_a["email"].should eq("")
      fs_b["email"]?.should be_nil
    end

    it "stale wrapped handler ALSO suppresses the user's on_change (no side effects)" do
      # Per Codex iter-3 finding: a stale fire must be a FULL no-op,
      # not just a no-op against FormState. If the user's on_change
      # had side effects (e.g. logging, analytics, validation), a
      # stale fire would still trigger them under the prior shape.
      UI::FormState.reset_renderer_hooks!
      fs_a = UI::FormState.new(mount_token: 1_i64)
      UI::FormState.current = fs_a
      UI::FormState.current_mount_token = 1_i64

      observed = [] of String
      tf = UI::TextField.new(placeholder: "Email", name: "email")
      tf.on_change = ->(v : String) { observed << v; nil }
      wrapped = UI::FormStateRendererHook.wrap_text_handler(tf).not_nil!

      # Live fire — both FormState AND user handler run.
      wrapped.call("live")
      fs_a["email"].should eq("live")
      observed.should eq(["live"])

      # Navigate away
      UI::FormState.current = UI::FormState.new(mount_token: 2_i64)
      UI::FormState.current_mount_token = 2_i64

      # Stale fire — must NOT update FormState AND must NOT call user handler
      wrapped.call("STALE")
      fs_a["email"].should eq("live")            # FormState unchanged
      observed.should eq(["live"])               # user handler did NOT run
    end
  end

  describe "FormStateRendererHook.wrap_secure_handler" do
    it "wraps SecureField on_change with FormState update + mount-token guard" do
      UI::FormState.reset_renderer_hooks!
      fs = UI::FormState.new(mount_token: 1_i64)
      UI::FormState.current = fs
      UI::FormState.current_mount_token = 1_i64

      observed = [] of String
      sf = UI::SecureField.new(placeholder: "Password", name: "password")
      sf.on_change = ->(v : String) { observed << v; nil }

      wrapped = UI::FormStateRendererHook.wrap_secure_handler(sf).not_nil!
      wrapped.call("")  # Bridge fires with "" (current limitation)
      fs["password"].should eq("")
      observed.should eq([""])
    end

    it "stale SecureField wrapped handler is a FULL no-op" do
      UI::FormState.reset_renderer_hooks!
      fs_a = UI::FormState.new(mount_token: 1_i64)
      UI::FormState.current = fs_a
      UI::FormState.current_mount_token = 1_i64

      observed = [] of String
      sf = UI::SecureField.new(placeholder: "Password", name: "password")
      sf.on_change = ->(v : String) { observed << v; nil }
      wrapped = UI::FormStateRendererHook.wrap_secure_handler(sf).not_nil!

      # Navigate
      UI::FormState.current = UI::FormState.new(mount_token: 2_i64)
      UI::FormState.current_mount_token = 2_i64

      # Stale fire — FormState write + user handler both suppressed
      wrapped.call("STALE_PASSWORD")
      fs_a["password"].should eq("")     # was registered to "" at wire-time
      observed.should be_empty
    end

    it "returns nil when SecureField has no name and no on_change" do
      UI::FormState.reset_renderer_hooks!
      sf = UI::SecureField.new(placeholder: "Password")
      UI::FormStateRendererHook.wrap_secure_handler(sf).should be_nil
    end
  end

  describe "stale-callback semantics (mount-token mismatch is a no-op)" do
    it "demonstrates the call-site pattern: only update when captured token matches current" do
      # This spec illustrates the exact code shape the renderer uses
      # inside `visit(UI::TextField)`. We simulate the renderer wiring
      # a callback that captures the FormState reference AND the token
      # at wire-time, then a navigation later, then a stale fire of
      # the captured callback.
      UI::FormState.reset_renderer_hooks!

      # Screen A mounts
      fs_a = UI::FormState.new(mount_token: 1_i64)
      UI::FormState.current = fs_a
      UI::FormState.current_mount_token = 1_i64

      # Renderer wires a callback for an input on screen A
      captured_fs = UI::FormState.current.not_nil!
      captured_token = captured_fs.mount_token

      callback = ->(new_value : String) do
        if UI::FormState.current_mount_token == captured_token
          captured_fs.update("email", new_value)
        end
        # else: stale — no-op.
      end

      # User types on screen A — callback fires while still on screen A
      callback.call("seth@example.com")
      fs_a["email"].should eq("seth@example.com")

      # User navigates to screen B; dispatcher mounts a new FormState
      fs_b = UI::FormState.new(mount_token: 2_i64)
      UI::FormState.current = fs_b
      UI::FormState.current_mount_token = 2_i64

      # Stale fire of screen A's callback (e.g. deferred async)
      callback.call("STALE_LEAK")

      # Screen A's FormState was NOT mutated (callback short-circuited)
      fs_a["email"].should eq("seth@example.com")
      # Screen B's FormState is empty
      fs_b["email"]?.should be_nil
    end
  end
end
