require "../../spec_helper"
require "../../../../src/components/css/config/css_config"
require "../../../../src/components/css/engine/css_rule"
require "../../../../src/components/css/engine/css_parser"
require "../../../../src/components/css/engine/css_generator"
require "../../../../src/components/css/class_registry"
require "../../../../src/components/css/component_css_registry"

describe "Phase 4: Component CSS Layer" do
  before_each do
    Components::CSS::ClassRegistry.instance.clear
    Components::CSS::ComponentCSSRegistry.instance.clear
  end

  describe "ComponentCSSRegistry" do
    it "registers and retrieves CSS for components" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.register("ButtonComponent", ".btn { display: inline-flex; }")

      registry.entries.size.should eq(1)
      registry.entries["ButtonComponent"].should eq(".btn { display: inline-flex; }")
    end

    it "concatenates multiple component CSS blocks" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.register("ButtonComponent", ".btn { display: inline-flex; }")
      registry.register("CardComponent", ".card { border-radius: var(--radius-md); }")

      all = registry.all_css
      all.should contain(".btn { display: inline-flex; }")
      all.should contain(".card { border-radius: var(--radius-md); }")
    end

    it "uses last-writer-wins for same component name" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.register("ButtonComponent", ".btn { color: red; }")
      registry.register("ButtonComponent", ".btn { color: blue; }")

      registry.all_css.should contain("color: blue;")
      registry.all_css.should_not contain("color: red;")
      registry.entries.size.should eq(1)
    end

    it "clears all entries" do
      registry = Components::CSS::ComponentCSSRegistry.instance
      registry.register("Test", ".test {}")
      registry.clear

      registry.entries.size.should eq(0)
      registry.all_css.should eq("")
    end
  end

  describe "Component CSS in @layer components" do
    it "emits registered CSS inside @layer components block" do
      Components::CSS::ComponentCSSRegistry.instance.register(
        "TestButton",
        <<-CSS
        .btn {
          display: inline-flex;
          align-items: center;
        }
        CSS
      )

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer components {")
      output.should contain("display: inline-flex;")
      output.should contain("align-items: center;")
    end

    it "emits component CSS with CSS nesting" do
      Components::CSS::ComponentCSSRegistry.instance.register(
        "TestNav",
        <<-CSS
        .nav {
          display: flex;

          & a {
            color: var(--color-blue-500);
          }

          &:hover {
            background-color: var(--color-gray-100);
          }
        }
        CSS
      )

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer components {")
      output.should contain("& a {")
      output.should contain("&:hover {")
    end

    it "supports light-dark() in component CSS" do
      Components::CSS::ComponentCSSRegistry.instance.register(
        "TestCard",
        <<-CSS
        .card {
          background-color: light-dark(var(--color-white), var(--color-gray-900));
          color: light-dark(var(--color-gray-900), var(--color-white));
        }
        CSS
      )

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("light-dark(var(--color-white), var(--color-gray-900))")
      output.should contain("light-dark(var(--color-gray-900), var(--color-white))")
    end

    it "emits empty @layer components when no CSS registered" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer components {\n}")
    end
  end

  describe "Utility override behavior (layer priority)" do
    it "utility layer comes after components layer in output" do
      Components::CSS::ComponentCSSRegistry.instance.register(
        "TestComponent",
        ".test { color: red; }"
      )
      Components::CSS::ClassRegistry.instance.register_class("text-blue-500")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      components_pos = output.index("@layer components {").not_nil!
      utilities_pos = output.index("@layer utilities {").not_nil!

      (utilities_pos > components_pos).should be_true
    end

    it "layer order declaration ensures utilities win over components" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should start_with("@layer reset, tokens, base, components, utilities;")
    end
  end

  describe "Multiple component registrations" do
    it "handles multiple components in output" do
      Components::CSS::ComponentCSSRegistry.instance.register(
        "Button",
        ".btn { display: inline-flex; font-weight: 500; }"
      )
      Components::CSS::ComponentCSSRegistry.instance.register(
        "Card",
        ".card { border-radius: var(--radius-lg); padding: var(--spacing-4); }"
      )
      Components::CSS::ComponentCSSRegistry.instance.register(
        "Modal",
        <<-CSS
        .modal-overlay {
          position: fixed;
          inset: 0;
          background-color: oklch(0 0 0 / 0.5);
        }
        .modal-content {
          position: relative;
          background-color: var(--color-white);
          border-radius: var(--radius-lg);
        }
        CSS
      )

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".btn { display: inline-flex;")
      output.should contain(".card { border-radius:")
      output.should contain(".modal-overlay {")
      output.should contain(".modal-content {")
    end
  end

  describe "color-scheme in tokens" do
    it "includes color-scheme: light dark in :root" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("color-scheme: light dark;")
    end
  end

  describe "Complete output structure" do
    it "has all 5 layers in correct order" do
      Components::CSS::ComponentCSSRegistry.instance.register(
        "TestBtn",
        ".test-btn { display: flex; }"
      )
      Components::CSS::ClassRegistry.instance.register_class("flex")
      Components::CSS::ClassRegistry.instance.register_class("hover:bg-blue-500")

      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      # Verify layer order declaration
      output.should start_with("@layer reset, tokens, base, components, utilities;")

      # Verify all layers present
      output.should contain("@layer reset {")
      output.should contain("@layer tokens {")
      output.should contain("@layer base {")
      output.should contain("@layer components {")
      output.should contain("@layer utilities {")

      # Verify content in correct layers
      output.should contain("box-sizing: border-box;")      # reset
      output.should contain("color-scheme: light dark;")    # tokens
      output.should contain(":focus-visible {")             # base
      output.should contain(".test-btn { display: flex; }") # components
      output.should contain(".flex {")                      # utilities
      output.should contain(".hover\\:bg-blue-500:hover")   # utilities with modifier
    end
  end
end
