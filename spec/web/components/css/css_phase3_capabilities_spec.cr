require "../../spec_helper"
require "../../../../src/components/css/config/css_config"
require "../../../../src/components/css/engine/css_rule"
require "../../../../src/components/css/engine/css_parser"
require "../../../../src/components/css/engine/css_generator"
require "../../../../src/components/css/class_registry"
require "../../../../src/components/css/component_css_registry"

describe "Phase 3: New Capabilities" do
  before_each do
    Components::CSS::ClassRegistry.instance.clear
    Components::CSS::ComponentCSSRegistry.instance.clear
  end

  describe "Container queries" do
    it "has default container breakpoints in config" do
      config = Components::CSS::Config.new
      config.containers["sm"].should eq("640px")
      config.containers["md"].should eq("768px")
      config.containers["lg"].should eq("1024px")
    end

    it "parses container utility" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("container", config)
      result.should_not be_nil
      result.not_nil!["container-type"].should eq("inline-size")
    end

    it "generates container query modifier @sm:" do
      Components::CSS::ClassRegistry.instance.register_class("@sm:flex")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@container (min-width: 640px)")
      output.should contain(".\\@sm\\:flex")
    end

    it "generates container query modifier @md:" do
      Components::CSS::ClassRegistry.instance.register_class("@md:grid")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@container (min-width: 768px)")
      output.should contain(".\\@md\\:grid")
    end

    it "nests container queries inside media queries" do
      Components::CSS::ClassRegistry.instance.register_class("dark:@sm:flex")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (prefers-color-scheme: dark)")
      output.should contain("@container (min-width: 640px)")
    end
  end

  describe "Logical property utilities" do
    it "parses ms- (margin-inline-start)" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("ms-4", config)
      result.should_not be_nil
      result.not_nil!["margin-inline-start"].should eq("1rem")
    end

    it "parses me- (margin-inline-end)" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("me-4", config)
      result.should_not be_nil
      result.not_nil!["margin-inline-end"].should eq("1rem")
    end

    it "parses ps- (padding-inline-start)" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("ps-4", config)
      result.should_not be_nil
      result.not_nil!["padding-inline-start"].should eq("1rem")
    end

    it "parses pe- (padding-inline-end)" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("pe-4", config)
      result.should_not be_nil
      result.not_nil!["padding-inline-end"].should eq("1rem")
    end
  end

  describe "Scroll padding/margin utilities" do
    it "parses scroll-pt- (scroll-padding-top)" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("scroll-pt-16", config)
      result.should_not be_nil
      result.not_nil!["scroll-padding-top"].should eq("4rem")
    end

    it "parses scroll-pb-" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("scroll-pb-4", config)
      result.should_not be_nil
      result.not_nil!["scroll-padding-bottom"].should eq("1rem")
    end

    it "parses scroll-p-" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("scroll-p-4", config)
      result.should_not be_nil
      result.not_nil!["scroll-padding"].should eq("1rem")
    end

    it "parses scroll-mt-" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("scroll-mt-4", config)
      result.should_not be_nil
      result.not_nil!["scroll-margin-top"].should eq("1rem")
    end

    it "parses scroll-mb-" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("scroll-mb-4", config)
      result.should_not be_nil
      result.not_nil!["scroll-margin-bottom"].should eq("1rem")
    end

    it "parses scroll-m-" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("scroll-m-8", config)
      result.should_not be_nil
      result.not_nil!["scroll-margin"].should eq("2rem")
    end
  end

  describe "Touch action utilities" do
    it "parses touch-auto" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("touch-auto", config)
      result.should_not be_nil
      result.not_nil!["touch-action"].should eq("auto")
    end

    it "parses touch-none" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("touch-none", config)
      result.should_not be_nil
      result.not_nil!["touch-action"].should eq("none")
    end

    it "parses touch-manipulation" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("touch-manipulation", config)
      result.should_not be_nil
      result.not_nil!["touch-action"].should eq("manipulation")
    end
  end

  describe "User select utilities" do
    it "parses select-all" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("select-all", config)
      result.should_not be_nil
      result.not_nil!["user-select"].should eq("all")
    end

    it "parses select-none" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("select-none", config)
      result.should_not be_nil
      result.not_nil!["user-select"].should eq("none")
    end

    it "parses select-text" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("select-text", config)
      result.should_not be_nil
      result.not_nil!["user-select"].should eq("text")
    end
  end

  describe "Appearance utilities" do
    it "parses appearance-none" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("appearance-none", config)
      result.should_not be_nil
      result.not_nil!["appearance"].should eq("none")
    end

    it "parses appearance-auto" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("appearance-auto", config)
      result.should_not be_nil
      result.not_nil!["appearance"].should eq("auto")
    end
  end

  describe "Forced color adjust utilities" do
    it "parses forced-color-adjust-auto" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("forced-color-adjust-auto", config)
      result.should_not be_nil
      result.not_nil!["forced-color-adjust"].should eq("auto")
    end

    it "parses forced-color-adjust-none" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("forced-color-adjust-none", config)
      result.should_not be_nil
      result.not_nil!["forced-color-adjust"].should eq("none")
    end
  end

  describe "Accent color utilities" do
    it "parses accent-auto" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("accent-auto", config)
      result.should_not be_nil
      result.not_nil!["accent-color"].should eq("auto")
    end

    it "parses accent-blue-500" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("accent-blue-500", config)
      result.should_not be_nil
      result.not_nil!["accent-color"].should start_with("oklch(")
    end
  end

  describe "Caret color utilities" do
    it "parses caret-blue-500" do
      config = Components::CSS::Config.new
      result = Components::CSS::Engine::Parser.parse_utility("caret-blue-500", config)
      result.should_not be_nil
      result.not_nil!["caret-color"].should start_with("oklch(")
    end
  end

  describe "P1 variant prefixes" do
    it "generates contrast-more: media query" do
      Components::CSS::ClassRegistry.instance.register_class("contrast-more:font-bold")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (prefers-contrast: more)")
      output.should contain(".contrast-more\\:font-bold")
    end

    it "generates forced-colors: media query" do
      Components::CSS::ClassRegistry.instance.register_class("forced-colors:border")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (forced-colors: active)")
      output.should contain(".forced-colors\\:border")
    end

    it "generates pointer-coarse: media query" do
      Components::CSS::ClassRegistry.instance.register_class("pointer-coarse:min-h-11")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (pointer: coarse)")
      output.should contain(".pointer-coarse\\:min-h-11")
    end

    it "generates pointer-fine: media query" do
      Components::CSS::ClassRegistry.instance.register_class("pointer-fine:min-h-8")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain("@media (pointer: fine)")
      output.should contain(".pointer-fine\\:min-h-8")
    end

    it "generates required: pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("required:ring-1")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".required\\:ring-1:required")
    end

    it "generates checked: pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("checked:bg-blue-500")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".checked\\:bg-blue-500:checked")
    end

    it "generates indeterminate: pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("indeterminate:bg-gray-300")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".indeterminate\\:bg-gray-300:indeterminate")
    end

    it "generates read-only: pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("read-only:bg-gray-100")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".read-only\\:bg-gray-100:read-only")
    end

    it "generates placeholder-shown: pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("placeholder-shown:text-gray-400")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".placeholder-shown\\:text-gray-400:placeholder-shown")
    end

    it "generates open: pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("open:bg-gray-100")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".open\\:bg-gray-100:open")
    end

    it "generates aria-hidden: attribute selector" do
      Components::CSS::ClassRegistry.instance.register_class("aria-hidden:hidden")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".aria-hidden\\:hidden[aria-hidden=\"true\"]")
    end

    it "generates aria-pressed: attribute selector" do
      Components::CSS::ClassRegistry.instance.register_class("aria-pressed:bg-blue-700")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".aria-pressed\\:bg-blue-700[aria-pressed=\"true\"]")
    end

    it "generates aria-busy: attribute selector" do
      Components::CSS::ClassRegistry.instance.register_class("aria-busy:opacity-50")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".aria-busy\\:opacity-50[aria-busy=\"true\"]")
    end

    it "generates inert: complex pseudo selector" do
      Components::CSS::ClassRegistry.instance.register_class("inert:opacity-50")
      config = Components::CSS::Config.new
      generator = Components::CSS::Engine::Generator.new(config)
      output = generator.generate

      output.should contain(".inert\\:opacity-50:is([inert], [inert] *)")
    end
  end
end
