require "../../spec_helper"
require "../../../../src/components/css/config/css_config"
require "../../../../src/components/css/engine/css_generator"
require "../../../../src/components/css/engine/css_parser"
require "../../../../src/components/css/class_registry"
require "../../../../src/components/css/tokens/amber_theme"

describe "Semantic design-system tokens" do
  before_each do
    Components::CSS::ClassRegistry.instance.clear
  end

  it "exposes named token model pieces" do
    theme = Components::CSS::Tokens::Theme.design_system_default

    theme.palettes["amber"].stops["500"].should contain("oklch")
    theme.intents["danger"].indicator.should contain("oklch")
    theme.states.hover.should contain("oklch")
    theme.typography.paragraph_line_height.should eq("1.72")
    theme.motion.duration_base.should eq("240ms")
    theme.elevation.raised.should contain("oklch")
    theme.radius.card.should eq("0.5rem")
  end

  it "keeps the Amber theme constructor as a compatibility alias" do
    generic = Components::CSS::Tokens::Theme.design_system_default
    compatibility = Components::CSS::Tokens::Theme.amber_default

    generic.to_css_variables(:light).should eq(compatibility.to_css_variables(:light))
    generic.to_css_variables(:dark).should eq(compatibility.to_css_variables(:dark))
  end

  it "emits generic light and dark CSS custom properties (no --amber-* aliases)" do
    theme = Components::CSS::Tokens::Theme.design_system_default

    light = theme.to_css_variables(:light)
    dark = theme.to_css_variables(:dark)

    light.should contain("--ap-color-brand-primary:")
    light.should contain("--ap-color-danger-bg:")
    light.should contain("--ap-font-sans:")
    # Phase 1 of the cross-platform UI initiative dropped the `--amber-*`
    # alias block wholesale — only `--ap-*` is canonical.
    light.includes?("--amber-color-brand-primary:").should be_false
    dark.should contain("--ap-color-surface-canvas:")
    dark.should contain("--ap-color-danger-bg:")
    dark.includes?("--amber-").should be_false
    dark.should_not eq(light)
  end

  it "allows app overrides without forking the theme class" do
    theme = Components::CSS::Tokens::Theme.design_system_default
    theme.override_token("brand-primary", "oklch(0.7 0.2 60)", "oklch(0.78 0.18 60)")

    theme.to_css_variables(:light).should contain("--ap-color-brand-primary: oklch(0.7 0.2 60);")
    theme.to_css_variables(:dark).should contain("--ap-color-brand-primary: oklch(0.78 0.18 60);")
    # No --amber-* alias is emitted alongside the override.
    theme.to_css_variables(:light).includes?("--amber-color-brand-primary:").should be_false
  end

  it "adds semantic utility colors to config" do
    config = Components::CSS::Config.new

    # Phase 1 of the cross-platform UI initiative dropped --amber-* fallback
    # chains; utility classes resolve directly through --ap-* only.
    config.get_color("danger-subtle").should eq("var(--ap-color-danger-bg)")
    config.get_color("surface-elevated").should eq("var(--ap-color-surface-elevated)")
    config.get_color("muted").should eq("var(--ap-color-text-muted)")
    config.get_color("focus").should eq("var(--ap-color-border-focus)")
  end

  it "supports a neutral config theme API" do
    theme = Components::CSS::Tokens::Theme.design_system_default
    theme.override_token("brand-primary", "oklch(0.68 0.18 48)")

    config = Components::CSS::Config.new.use_design_system_theme(theme)
    config.design_system_theme.should be(theme)
    config.amber_theme.should be(theme)
    config.get_color("brand-primary").should eq("var(--ap-color-brand-primary)")

    compatibility = Components::CSS::Config.new.use_amber_theme(theme)
    compatibility.design_system_theme.should be(theme)
  end

  it "keeps default tracking utilities neutral for the Amber web proof" do
    config = Components::CSS::Config.new

    config.letter_spacing.values.uniq.should eq(["0em"])
    Components::CSS::Engine::Parser.parse_utility("tracking-tight", config).not_nil!["letter-spacing"]
      .should eq("0em")
    Components::CSS::Engine::Parser.parse_utility("tracking-widest", config).not_nil!["letter-spacing"]
      .should eq("0em")
  end

  it "generates semantic utility classes and dark token overrides" do
    registry = Components::CSS::ClassRegistry.instance
    registry.register_class("bg-danger-subtle")
    registry.register_class("border-danger-strong")
    registry.register_class("text-muted")
    registry.register_class("ring-focus")
    registry.register_class("bg-surface-elevated")

    css = Components::CSS::Engine::Generator.new(Components::CSS::Config.new).generate

    css.should contain("--ap-color-brand-primary:")
    # `--amber-*` aliases and `[data-amber-theme]` selectors were dropped in
    # Phase 1 of the cross-platform UI initiative.
    css.includes?("--amber-color-brand-primary:").should be_false
    css.should contain("@media (prefers-color-scheme: dark)")
    css.should contain("[data-ap-theme=\"light\"]")
    css.should contain("[data-ap-theme=\"dark\"]")
    css.includes?("[data-amber-theme=\"light\"]").should be_false
    css.includes?("[data-amber-theme=\"dark\"]").should be_false
    css.should contain(".bg-danger-subtle")
    css.should contain("background-color: var(--ap-color-danger-bg);")
    css.should contain("border-color: var(--ap-color-danger-indicator);")
    css.should contain("color: var(--ap-color-text-muted);")
    css.should contain("box-shadow: 0 0 0 3px var(--ap-color-border-focus);")
    css.should contain("background-color: var(--ap-color-surface-elevated);")
  end

  it "parses motion utilities used by the web proof" do
    config = Components::CSS::Config.new

    Components::CSS::Engine::Parser.parse_utility("duration-base", config).not_nil!["transition-duration"]
      .should eq("var(--ap-motion-duration-base)")
    Components::CSS::Engine::Parser.parse_utility("ease-emphasized", config).not_nil!["transition-timing-function"]
      .should eq("var(--ap-motion-ease-emphasized)")
    Components::CSS::Engine::Parser.parse_utility("animate-row-in", config).not_nil!["animation"]
      .should contain("ap-row-enter")
    Components::CSS::Engine::Parser.parse_utility("bg-gradient-brand", config).not_nil!["background-image"]
      .should contain("var(--ap-color-brand-primary")
  end
end
