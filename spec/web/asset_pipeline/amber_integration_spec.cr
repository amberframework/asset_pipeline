require "../spec_helper"
require "../../../src/asset_pipeline/amber_integration"

# Tiny fake screen the integration specs render.
private class TestSpecScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    label = UI::Label.new("hello-#{context.params["q"]? || "default"}-csrf:#{context.csrf_token || "none"}")
    label
  end
end

describe UI::ScreenContext::Web do
  it "exposes the constructor-supplied values" do
    tokens = UI::DesignTokens::Tokens.default
    ctx = UI::ScreenContext::Web.new(
      params: {"q" => "alpha"},
      params_multi: {"tag" => ["a", "b"]},
      flash_data: {"notice" => "ok"},
      design_tokens: tokens,
      csrf_token: "TOKEN_123",
    )
    ctx.params["q"].should eq("alpha")
    ctx.params_multi["tag"].should eq(["a", "b"])
    ctx.flash_data["notice"].should eq("ok")
    ctx.design_tokens.should be(tokens)
    ctx.csrf_token.should eq("TOKEN_123")
  end

  it "is assignable to UI::ScreenContext" do
    ctx : UI::ScreenContext = UI::ScreenContext::Web.new(
      params: {} of String => String,
      params_multi: {} of String => Array(String),
      flash_data: {} of String => String,
      design_tokens: UI::DesignTokens::Tokens.default,
      csrf_token: nil,
    )
    ctx.csrf_token.should be_nil
  end
end

describe UI::AmberConfig do
  it "exposes a default token bundle" do
    UI::AmberConfig.design_tokens.should be_a(UI::DesignTokens::Tokens)
  end

  it "round-trips through the setter" do
    original = UI::AmberConfig.design_tokens
    begin
      override = UI::DesignTokens::Tokens.default
      UI::AmberConfig.design_tokens = override
      UI::AmberConfig.design_tokens.should be(override)
    ensure
      UI::AmberConfig.design_tokens = original
    end
  end
end

describe UI::RenderContext do
  it "carries a csrf_token" do
    ctx = UI::RenderContext.new(csrf_token: "ABC")
    ctx.csrf_token.should eq("ABC")
  end

  it "exposes a no-op empty value" do
    UI::RenderContext.empty.csrf_token.should be_nil
  end
end

describe UI::Web::Renderer do
  it "render(view, render_context:) carries the context through visit methods" do
    # Smoke test: rendering a label with a render context still works.
    # The Form-specific CSRF threading is exercised in iter 4.
    label = UI::Label.new("plain")
    renderer = UI::Web::Renderer.new
    html = renderer.render(label, render_context: UI::RenderContext.new(csrf_token: "T"))
    html.should contain("plain")
    # Context resets after render
    renderer.render_context.csrf_token.should be_nil
  end
end

describe UI::Screen do
  it "is abstract — concrete subclass builds a view tree" do
    screen = TestSpecScreen.new
    ctx = UI::ScreenContext::Web.new(
      params: {"q" => "world"},
      params_multi: {} of String => Array(String),
      flash_data: {} of String => String,
      design_tokens: UI::DesignTokens::Tokens.default,
      csrf_token: "tok",
    )
    view = screen.build(ctx)
    view.should be_a(UI::Label)
    view.as(UI::Label).text.should eq("hello-world-csrf:tok")
  end
end
