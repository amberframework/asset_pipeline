require "../../spec_helper"
require "../../../../src/components/css/config/css_config"
require "../../../../src/components/css/engine/css_rule"
require "../../../../src/components/css/engine/css_parser"
require "../../../../src/components/css/engine/css_generator"
require "../../../../src/components/css/class_registry"
require "../../../../src/components/css/component_css_registry"

describe "CSS Layer Structure (Phase 1)" do
  before_each do
    Components::CSS::ClassRegistry.instance.clear
    Components::CSS::ComponentCSSRegistry.instance.clear
  end

  describe "Layer order declaration" do
    it "emits @layer order as first line" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should start_with("@layer reset, tokens, base, components, utilities;")
    end
  end

  describe "@layer reset" do
    it "wraps CSS reset in @layer reset block" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer reset {")
      output.should contain("/* CSS Reset */")
      output.should contain("box-sizing: border-box;")
    end
  end

  describe "@layer tokens" do
    it "contains :root with color-scheme" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer tokens {")
      output.should contain(":root {")
      output.should contain("color-scheme: light dark;")
    end

    it "emits custom properties for colors" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--color-black:")
      output.should contain("--color-white:")
      output.should contain("--color-gray-500:")
      output.should contain("--color-blue-500:")
    end

    it "emits custom properties for spacing" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--spacing-4:")
      output.should contain("--spacing-8:")
    end

    it "emits custom properties for fonts" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--font-sans:")
      output.should contain("--font-mono:")
    end

    it "emits custom properties for font sizes" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--font-size-sm:")
      output.should contain("--font-size-lg:")
    end

    it "emits custom properties for border radius with DEFAULT handling" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--radius: 0.25rem;")
      output.should contain("--radius-md:")
      output.should_not contain("--radius-DEFAULT:")
    end

    it "emits custom properties for shadows with DEFAULT handling" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--shadow:")
      output.should contain("--shadow-sm:")
      output.should_not contain("--shadow-DEFAULT:")
    end

    it "emits custom properties for transitions with DEFAULT handling" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--transition:")
      output.should contain("--transition-all:")
      output.should_not contain("--transition-DEFAULT:")
    end

    it "emits custom properties for z-index" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--z-10:")
      output.should contain("--z-50:")
    end

    it "emits custom properties for opacity" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--opacity-50:")
      output.should contain("--opacity-100:")
    end
  end

  describe "@layer base" do
    it "contains focus-visible baseline" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer base {")
      output.should contain(":focus-visible {")
      output.should contain("outline: 2px solid var(--focus-ring-color")
    end

    it "contains reduced motion override" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (prefers-reduced-motion: reduce)")
      output.should contain("animation-duration: 0.01ms !important;")
    end

    it "contains forced-colors focus ring" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (forced-colors: active)")
      output.should contain("outline: 2px solid Highlight;")
    end

    it "contains list semantics restoration" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("[role=\"list\"]")
    end
  end

  describe "@layer components" do
    it "is present even when empty" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer components {")
    end

    it "includes registered component CSS" do
      Components::CSS::ComponentCSSRegistry.instance.register(
        "TestComponent",
        ".test-btn { display: inline-flex; }"
      )

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer components {")
      output.should contain(".test-btn { display: inline-flex; }")
    end
  end

  describe "@layer utilities" do
    it "wraps utility rules in @layer utilities" do
      Components::CSS::ClassRegistry.instance.register_class("flex")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer utilities {")
      output.should contain("display: flex;")
    end

    it "groups media query rules inside utilities layer" do
      Components::CSS::ClassRegistry.instance.register_class("sm:flex")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer utilities {")
      output.should contain("@media (min-width: 640px)")
    end
  end

  describe "Full-class-name selectors" do
    it "uses full class name for simple utilities" do
      Components::CSS::ClassRegistry.instance.register_class("flex")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".flex {")
    end

    it "uses escaped full class name for hover modifier" do
      Components::CSS::ClassRegistry.instance.register_class("hover:bg-blue-500")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".hover\\:bg-blue-500:hover")
    end

    it "uses escaped full class name for responsive modifier" do
      Components::CSS::ClassRegistry.instance.register_class("sm:flex")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".sm\\:flex")
    end

    it "uses escaped full class name for dark mode modifier" do
      Components::CSS::ClassRegistry.instance.register_class("dark:bg-black")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".dark\\:bg-black")
    end
  end

  describe "CSS.escape" do
    it "escapes colons" do
      Components::CSS::Engine::CSS.escape("hover:bg-blue-500").should eq("hover\\:bg-blue-500")
    end

    it "escapes @ symbol" do
      Components::CSS::Engine::CSS.escape("@sm:flex").should eq("\\@sm\\:flex")
    end

    it "preserves hyphens and word characters" do
      Components::CSS::Engine::CSS.escape("bg-blue-500").should eq("bg-blue-500")
    end

    it "escapes dots" do
      Components::CSS::Engine::CSS.escape("p-0.5").should eq("p-0\\.5")
    end
  end

  describe "to_custom_properties" do
    it "returns custom property declarations" do
      config = Components::CSS::Config.new
      props = config.to_custom_properties

      props.should contain("--color-black:")
      props.should contain("--spacing-4:")
      props.should contain("--font-sans:")
    end

    it "handles DEFAULT keys without suffix" do
      config = Components::CSS::Config.new
      props = config.to_custom_properties

      props.should contain("--radius: 0.25rem;")
      props.should_not contain("--radius-DEFAULT")
    end

    it "handles nested color groups" do
      config = Components::CSS::Config.new
      props = config.to_custom_properties

      props.should contain("--color-gray-500:")
      props.should contain("--color-blue-500:")
      props.should contain("--color-red-500:")
      props.should contain("--color-green-500:")
    end
  end

  describe "ComponentCSSRegistry" do
    it "registers and retrieves component CSS" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.clear
      registry.register("Button", ".btn { display: inline-flex; }")

      registry.all_css.should contain(".btn { display: inline-flex; }")
    end

    it "concatenates multiple component CSS blocks" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.clear
      registry.register("Button", ".btn { display: inline-flex; }")
      registry.register("Card", ".card { border-radius: var(--radius-md); }")

      all = registry.all_css
      all.should contain(".btn { display: inline-flex; }")
      all.should contain(".card { border-radius: var(--radius-md); }")
    end

    it "last-writer-wins for same component name" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.clear
      registry.register("Button", ".btn { color: red; }")
      registry.register("Button", ".btn { color: blue; }")

      registry.all_css.should contain("color: blue;")
      registry.all_css.should_not contain("color: red;")
    end

    it "clears all entries" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.register("Test", ".test { color: red; }")
      registry.clear

      registry.all_css.should eq("")
    end
  end

  describe "Layer ordering in output" do
    it "layers appear in correct order: reset, tokens, base, components, utilities" do
      Components::CSS::ClassRegistry.instance.register_class("flex")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      reset_pos = output.index("@layer reset {").not_nil!
      tokens_pos = output.index("@layer tokens {").not_nil!
      base_pos = output.index("@layer base {").not_nil!
      components_pos = output.index("@layer components {").not_nil!
      utilities_pos = output.index("@layer utilities {").not_nil!

      (reset_pos < tokens_pos).should be_true
      (tokens_pos < base_pos).should be_true
      (base_pos < components_pos).should be_true
      (components_pos < utilities_pos).should be_true
    end
  end

  describe "Rule class" do
    it "supports attribute selectors" do
      rule = Components::CSS::Engine::Rule.new(".test")
      rule.with_attribute("aria-expanded", "true")

      rule.full_selector.should eq(".test[aria-expanded=\"true\"]")
    end

    it "supports attribute presence selectors" do
      rule = Components::CSS::Engine::Rule.new(".test")
      rule.with_attribute_present("data-disabled")

      rule.full_selector.should eq(".test[data-disabled]")
    end

    it "supports complex pseudo selectors" do
      rule = Components::CSS::Engine::Rule.new(".test")
      rule.with_complex_pseudo(":is([inert], [inert] *)")

      rule.full_selector.should eq(".test:is([inert], [inert] *)")
    end

    it "supports container queries" do
      rule = Components::CSS::Engine::Rule.new(".test")
      rule.with_container("(min-width: 640px)")

      rule.container_query.should eq("(min-width: 640px)")
    end

    it "combines attribute and pseudo selectors" do
      rule = Components::CSS::Engine::Rule.new(".test")
      rule.with_attribute("aria-expanded", "true")
      rule.with_pseudo("hover")

      rule.full_selector.should eq(".test[aria-expanded=\"true\"]:hover")
    end

    it "renders declarations correctly" do
      rule = Components::CSS::Engine::Rule.new(".test")
      rule.add_declaration("display", "flex")
      rule.add_declaration("color", "red")

      rendered = rule.render
      rendered.should contain(".test {")
      rendered.should contain("display: flex;")
      rendered.should contain("color: red;")
    end

    it "returns empty string for no declarations" do
      rule = Components::CSS::Engine::Rule.new(".test")
      rule.render.should eq("")
    end
  end
end
