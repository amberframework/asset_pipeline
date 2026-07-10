require "../spec_helper"
require "../../../src/asset_pipeline/native_context"

# Iter-3 ships the real `UI::FormState` with mount-token bookkeeping.
# For iter-2, the forward declaration's `to_h` stub returns {}. This
# subclass overrides `to_h` so a spec can prove `ctx.params` reads
# real form-state values without depending on iter-3's API surface.
private class NativeContextSpecStubbedFormState < UI::FormState
  def initialize(values : Hash(String, String))
    super(mount_token: 0_i64, initial: values)
  end
end

private def build_native_context(
  *,
  form_state : UI::FormState = UI::FormState.new,
  session : UI::Session = UI::Session::InProcess.new,
  flash : UI::Flash = UI::Flash::InProcess.new,
  navigation : UI::NavigationCoordinator = UI::NavigationCoordinator.new(
    UI::NavigationCoordinator::Route.new(:sign_in)
  ),
  action_params : Hash(String, String) = {} of String => String,
) : UI::ScreenContext::Native
  UI::ScreenContext::Native.new(
    form_state: form_state,
    session: session,
    flash: flash,
    design_tokens: UI::DesignTokens::Tokens.default,
    navigation: navigation,
    action_params: action_params,
  )
end

describe UI::Session::InProcess do
  it "stores and reads keys" do
    sess = UI::Session::InProcess.new
    sess["user_email"] = "seth@example.com"
    sess["user_email"].should eq("seth@example.com")
    sess["missing"]?.should be_nil
  end

  it "returns a defensive copy via to_h" do
    sess = UI::Session::InProcess.new
    sess["k"] = "v"
    snapshot = sess.to_h
    snapshot["k"] = "mutated"
    sess["k"].should eq("v")
  end
end

describe UI::Flash::InProcess do
  it "stores and clears one-shot messages" do
    flash = UI::Flash::InProcess.new
    flash["notice"] = "saved"
    flash["notice"].should eq("saved")
    flash.clear
    flash["notice"]?.should be_nil
  end

  it "to_h returns a defensive copy" do
    flash = UI::Flash::InProcess.new
    flash["k"] = "v"
    flash.to_h["k"] = "mutated"
    flash["k"].should eq("v")
  end
end

describe UI::ScreenContext::Native do
  it "exposes form_state, session, flash, design_tokens, navigation, action_params" do
    sess = UI::Session::InProcess.new
    sess["user_email"] = "seth@example.com"
    flash = UI::Flash::InProcess.new
    flash["notice"] = "welcome"
    nav = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))

    ctx = build_native_context(
      session: sess, flash: flash, navigation: nav,
      action_params: {"todo_id" => "42"},
    )

    ctx.session.should be(sess)
    ctx.flash.should be(flash)
    ctx.navigation.should be(nav)
    ctx.action_params["todo_id"].should eq("42")
    ctx.design_tokens.should be_a(UI::DesignTokens::Tokens)
  end

  it "params + action_params stay SEPARATE (no silent merge)" do
    # Per Codex finding #2 on Phase 8B brief.
    ctx = build_native_context(
      action_params: {"todo_id" => "42", "email" => "FROM_BUTTON"},
    )

    # form_state is the iter-3 stub: its to_h returns {} until iter 3
    # ships the real FormState. The key point we test here is that
    # action_params is NOT silently merged into ctx.params.
    ctx.params.has_key?("todo_id").should be_false
    ctx.action_params["todo_id"].should eq("42")
  end

  it "params reflects non-empty form_state values via to_h delegation" do
    # Per Codex iter-2 review note: prove `ctx.params` surfaces form
    # field values, AND that an action_params key with the same name
    # does not silently override the form value. iter 3 ships the real
    # FormState; here we subclass it with a deterministic to_h.
    fs = NativeContextSpecStubbedFormState.new({
      "email"    => "seth@example.com",
      "password" => "secret",
    })
    ctx = build_native_context(
      form_state: fs,
      # Same key name as a form field — must NOT clobber.
      action_params: {"email" => "FROM_BUTTON_NOT_FORM"},
    )

    ctx.params["email"].should eq("seth@example.com")
    ctx.params["password"].should eq("secret")
    ctx.action_params["email"].should eq("FROM_BUTTON_NOT_FORM")
    # ctx.params contains EXACTLY the form-state keys (no action_params bleed).
    ctx.params.keys.sort.should eq(["email", "password"])
  end

  it "csrf_token is explicitly nil for native targets" do
    ctx = build_native_context
    ctx.csrf_token.should be_nil
  end

  it "flash_data returns a Hash snapshot of flash messages" do
    flash = UI::Flash::InProcess.new
    flash["notice"] = "ok"
    ctx = build_native_context(flash: flash)
    ctx.flash_data["notice"].should eq("ok")
  end

  it "params_multi returns an empty hash (native targets are scalar-only for now)" do
    ctx = build_native_context
    ctx.params_multi.should be_empty
  end
end
