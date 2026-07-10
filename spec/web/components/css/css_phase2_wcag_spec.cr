require "../../spec_helper"
require "../../../../src/components/css/config/css_config"
require "../../../../src/components/css/engine/css_rule"
require "../../../../src/components/css/engine/css_parser"
require "../../../../src/components/css/engine/css_generator"
require "../../../../src/components/css/class_registry"
require "../../../../src/components/css/class_builder"
require "../../../../src/components/css/component_css_registry"

describe "Phase 2: Modern Values + WCAG Accessibility Utilities" do
  before_each do
    Components::CSS::ClassRegistry.instance.clear
    Components::CSS::ComponentCSSRegistry.instance.clear
  end

  describe "oklch color values" do
    it "uses oklch for black" do
      config = Components::CSS::Config.new
      config.get_color("black").should eq("oklch(0 0 0)")
    end

    it "uses oklch for white" do
      config = Components::CSS::Config.new
      config.get_color("white").should eq("oklch(1 0 0)")
    end

    it "uses oklch for blue-500" do
      config = Components::CSS::Config.new
      color = config.get_color("blue-500")
      color.should_not be_nil
      color.not_nil!.should start_with("oklch(")
    end

    it "uses oklch for gray-500" do
      config = Components::CSS::Config.new
      color = config.get_color("gray-500")
      color.should_not be_nil
      color.not_nil!.should start_with("oklch(")
    end

    it "uses oklch for red-500" do
      config = Components::CSS::Config.new
      color = config.get_color("red-500")
      color.should_not be_nil
      color.not_nil!.should start_with("oklch(")
    end

    it "uses oklch for green-500" do
      config = Components::CSS::Config.new
      color = config.get_color("green-500")
      color.should_not be_nil
      color.not_nil!.should start_with("oklch(")
    end

    it "preserves transparent and currentColor" do
      config = Components::CSS::Config.new
      config.get_color("transparent").should eq("transparent")
      config.get_color("current").should eq("currentColor")
    end

    it "generates oklch in CSS output" do
      Components::CSS::ClassRegistry.instance.register_class("bg-blue-500")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("oklch(0.623 0.214 259.815)")
    end
  end

  describe "sr-only utility" do
    it "generates screen reader only declarations" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("sr-only", config)

      result.should_not be_nil
      result = result.not_nil!
      result["position"].should eq("absolute")
      result["width"].should eq("1px")
      result["height"].should eq("1px")
      result["overflow"].should eq("hidden")
      result["clip"].should eq("rect(0, 0, 0, 0)")
      result["white-space"].should eq("nowrap")
      result["border-width"].should eq("0")
    end

    it "renders in CSS output" do
      Components::CSS::ClassRegistry.instance.register_class("sr-only")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".sr-only")
      output.should contain("position: absolute;")
      output.should contain("clip: rect(0, 0, 0, 0);")
    end
  end

  describe "not-sr-only utility" do
    it "generates reverse screen reader declarations" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("not-sr-only", config)

      result.should_not be_nil
      result = result.not_nil!
      result["position"].should eq("static")
      result["width"].should eq("auto")
      result["height"].should eq("auto")
      result["overflow"].should eq("visible")
      result["clip"].should eq("auto")
    end
  end

  describe "focus ring utilities" do
    it "parses ring (default)" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("ring", config)

      result.should_not be_nil
      result.not_nil!["box-shadow"].should contain("3px")
    end

    it "parses ring-2" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("ring-2", config)

      result.should_not be_nil
      result.not_nil!["box-shadow"].should contain("2px")
    end

    it "parses ring-0" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("ring-0", config)

      result.should_not be_nil
      result.not_nil!["box-shadow"].should contain("0px")
    end

    it "parses ring-inset" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("ring-inset", config)

      result.should_not be_nil
      result.not_nil!["box-shadow"].should contain("inset")
    end

    it "uses oklch for ring color" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("ring", config)

      result.should_not be_nil
      result.not_nil!["box-shadow"].should contain("oklch(")
    end

    it "parses outline-2" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("outline-2", config)

      result.should_not be_nil
      result.not_nil!["outline-width"].should eq("2px")
    end

    it "parses outline-none" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("outline-none", config)

      result.should_not be_nil
      result.not_nil!["outline"].should contain("transparent")
    end

    it "parses outline-offset-2" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("outline-offset-2", config)

      result.should_not be_nil
      result.not_nil!["outline-offset"].should eq("2px")
    end
  end

  describe "min-width/height utilities" do
    it "parses min-w-0" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("min-w-0", config)

      result.should_not be_nil
      result.not_nil!["min-width"].should eq("0px")
    end

    it "parses min-w with spacing value" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("min-w-4", config)

      result.should_not be_nil
      result.not_nil!["min-width"].should eq("1rem")
    end

    it "parses min-h-0" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("min-h-0", config)

      result.should_not be_nil
      result.not_nil!["min-height"].should eq("0px")
    end

    it "parses min-h with spacing value" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("min-h-8", config)

      result.should_not be_nil
      result.not_nil!["min-height"].should eq("2rem")
    end
  end

  describe "focus-visible: modifier" do
    it "generates focus-visible pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("focus-visible:ring-2")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".focus-visible\\:ring-2:focus-visible")
      output.should contain("box-shadow:")
    end
  end

  describe "focus-within: modifier" do
    it "generates focus-within pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("focus-within:ring-2")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".focus-within\\:ring-2:focus-within")
    end
  end

  describe "motion-safe: modifier" do
    it "generates motion-safe media query" do
      Components::CSS::ClassRegistry.instance.register_class("motion-safe:transition")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (prefers-reduced-motion: no-preference)")
      output.should contain(".motion-safe\\:transition")
    end
  end

  describe "motion-reduce: modifier" do
    it "generates motion-reduce media query" do
      Components::CSS::ClassRegistry.instance.register_class("motion-reduce:hidden")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (prefers-reduced-motion: reduce)")
      output.should contain(".motion-reduce\\:hidden")
    end
  end

  describe "invalid: modifier" do
    it "generates invalid pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("invalid:border-red-500")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".invalid\\:border-red-500:invalid")
    end
  end

  describe "valid: modifier" do
    it "generates valid pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("valid:border-green-500")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".valid\\:border-green-500:valid")
    end
  end

  describe "user-invalid: modifier" do
    it "generates user-invalid pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("user-invalid:border-red-500")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".user-invalid\\:border-red-500:user-invalid")
    end
  end

  describe "user-valid: modifier" do
    it "generates user-valid pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("user-valid:border-green-500")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".user-valid\\:border-green-500:user-valid")
    end
  end

  describe "aria-expanded: modifier" do
    it "generates attribute selector" do
      Components::CSS::ClassRegistry.instance.register_class("aria-expanded:bg-gray-100")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".aria-expanded\\:bg-gray-100[aria-expanded=\"true\"]")
    end
  end

  describe "aria-selected: modifier" do
    it "generates attribute selector" do
      Components::CSS::ClassRegistry.instance.register_class("aria-selected:bg-blue-100")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".aria-selected\\:bg-blue-100[aria-selected=\"true\"]")
    end
  end

  describe "aria-checked: modifier" do
    it "generates attribute selector" do
      Components::CSS::ClassRegistry.instance.register_class("aria-checked:bg-blue-500")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".aria-checked\\:bg-blue-500[aria-checked=\"true\"]")
    end
  end

  describe "aria-disabled: modifier" do
    it "generates attribute selector" do
      Components::CSS::ClassRegistry.instance.register_class("aria-disabled:opacity-50")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".aria-disabled\\:opacity-50[aria-disabled=\"true\"]")
    end
  end

  describe "compound modifiers" do
    it "handles dark + aria-expanded" do
      Components::CSS::ClassRegistry.instance.register_class("dark:aria-expanded:bg-gray-800")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (prefers-color-scheme: dark)")
      output.should contain(".dark\\:aria-expanded\\:bg-gray-800[aria-expanded=\"true\"]")
    end

    it "handles focus-visible + ring" do
      Components::CSS::ClassRegistry.instance.register_class("focus-visible:ring-2")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".focus-visible\\:ring-2:focus-visible")
    end
  end

  describe "ClassBuilder convenience methods" do
    it "builds focus-visible variant classes" do
      builder = Components::CSS::ClassBuilder.new
      builder.focus_visible("ring-2 outline-none")
      result = builder.build

      result.should contain("focus-visible:ring-2")
      result.should contain("focus-visible:outline-none")
    end

    it "builds motion-safe variant classes" do
      builder = Components::CSS::ClassBuilder.new
      builder.motion_safe("transition")
      result = builder.build

      result.should contain("motion-safe:transition")
    end

    it "builds aria-expanded variant classes" do
      builder = Components::CSS::ClassBuilder.new
      builder.aria_expanded("bg-gray-100")
      result = builder.build

      result.should contain("aria-expanded:bg-gray-100")
    end

    it "builds aria-selected variant classes" do
      builder = Components::CSS::ClassBuilder.new
      builder.aria_selected("bg-blue-100")
      result = builder.build

      result.should contain("aria-selected:bg-blue-100")
    end

    it "builds invalid variant classes" do
      builder = Components::CSS::ClassBuilder.new
      builder.invalid("border-red-500")
      result = builder.build

      result.should contain("invalid:border-red-500")
    end
  end

  describe "default accessibility CSS in base layer" do
    it "includes focus-visible ring in base layer" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@layer base {")
      output.should contain(":focus-visible {")
      output.should contain("outline: 2px solid var(--focus-ring-color")
    end

    it "includes reduced motion override in base layer" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (prefers-reduced-motion: reduce)")
      output.should contain("animation-duration: 0.01ms !important;")
      output.should contain("transition-duration: 0.01ms !important;")
    end

    it "includes forced-colors focus ring in base layer" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (forced-colors: active)")
      output.should contain("outline: 2px solid Highlight;")
    end
  end

  describe "oklch in custom properties" do
    it "emits oklch values in token custom properties" do
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("--color-black: oklch(0 0 0);")
      output.should contain("--color-white: oklch(1 0 0);")
      output.should contain("--color-blue-500: oklch(0.623 0.214 259.815);")
    end
  end
end
