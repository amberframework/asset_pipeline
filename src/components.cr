# Main components module that requires all component files
require "./components/base/component"
require "./components/base/stateful_component"
require "./components/base/stateless_component"

# Elements
require "./components/elements/base/html_element"
require "./components/elements/base/container_element"
require "./components/elements/base/void_element"
require "./components/elements/base/raw_html"

# Document elements
require "./components/elements/document/html"
require "./components/elements/document/head"
require "./components/elements/document/body"
require "./components/elements/document/title"
require "./components/elements/document/meta"
require "./components/elements/document/link"
require "./components/elements/document/script"
require "./components/elements/document/style"

# Content elements
require "./components/elements/sections/section"
require "./components/elements/sections/article"
require "./components/elements/sections/aside"
require "./components/elements/sections/header"
require "./components/elements/sections/footer"
require "./components/elements/sections/main"
require "./components/elements/sections/nav"
require "./components/elements/sections/headings"
require "./components/elements/grouping/div"
require "./components/elements/grouping/span"
require "./components/elements/grouping/p"
require "./components/elements/grouping/lists"
require "./components/elements/text/a"
require "./components/elements/text/text_semantics"
require "./components/elements/forms/form"
require "./components/elements/forms/input"
require "./components/elements/forms/form_controls"
require "./components/elements/embedded/img"

# CSS System
require "./components/css/class_registry"
require "./components/css/class_builder"
require "./components/css/styleable"
require "./components/css/config/css_config"
require "./components/css/engine/css_rule"
require "./components/css/engine/css_parser"
require "./components/css/engine/css_generator"
require "./components/css/scanner/class_scanner"

# Asset Pipeline
require "./components/assets/base/asset"
require "./components/assets/css_asset"

# Reactive components
require "./components/reactive/reactive_component"

# Integration
require "./components/integration"

# Helper to create a page
module Components
  class Page < Component
    property title : String
    property? lang : String = "en"
    property head_content : Proc(Nil)?
    property body_content : Proc(Nil)?
    
    def initialize(@title : String, @lang = "en", &block : Nil ->)
      super()
      @body_content = block
    end
    
    def render_content : String
      html(lang: lang) do
        head do
          title { @title }
          @head_content.try(&.call)
        end
        body do
          @body_content.try(&.call)
        end
      end
    end
  end
  
  # Helper method to create raw HTML
  def self.raw_html(content : String)
    Elements::RawHTML.new(content)
  end
end