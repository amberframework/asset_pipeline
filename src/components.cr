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
require "./components/elements/embedded/media"

# CSS System
require "./components/css/class_registry"
require "./components/css/class_builder"
require "./components/css/styleable"
require "./components/css/tokens/design_system_theme"
require "./components/css/config/css_config"
require "./components/css/engine/css_rule"
require "./components/css/engine/css_parser"
require "./components/css/engine/css_generator"
require "./components/css/component_css_registry"
require "./components/css/container_query_components"
require "./components/css/scanner/class_scanner"
require "./components/variants/component_variant"

# Asset Pipeline
require "./components/assets/base/asset"
require "./components/assets/css_asset"
require "./components/assets/font_asset"

# Reactive components — server/web only (pulls in http/server + OpenSSL + zlib
# via reactive_handler). iOS and Android targets must skip this subtree;
# their Crystal binaries cross-compile without the OpenSSL/zlib symbols
# present, so unconditionally requiring it leaves undefined link symbols.
{% unless flag?(:ios) || flag?(:android) %}
  require "./components/reactive/reactive_component"
{% end %}

# Example components
require "./components/examples/button_component"
require "./components/examples/card_component"
require "./components/examples/auth_form_component"
{% unless flag?(:ios) || flag?(:android) %}
  require "./components/examples/chat_component"
{% end %}
require "./components/examples/command_palette_component"
require "./components/examples/counter_component"
require "./components/examples/carousel_component"
require "./components/examples/data_table_component"
require "./components/examples/dialog_component"
require "./components/examples/form_field_component"
require "./components/examples/form_component"
{% unless flag?(:ios) || flag?(:android) %}
  require "./components/examples/live_search_component"
{% end %}
require "./components/examples/payment_form_component"
require "./components/examples/pricing_card_component"
require "./components/examples/schedule_heatmap_component"
require "./components/examples/simple_chart_component"
require "./components/examples/tabs_component"
require "./components/examples/theme_switcher_component"
require "./components/examples/timeline_component"

# Design system namespace
require "./components/design_system/components"

# Integration — Amber framework helpers; transitively pulls in http/server
# via reactive_handler. Web/server only.
{% unless flag?(:ios) || flag?(:android) %}
  require "./components/integration"
{% end %}

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
      Elements::Html.new(lang: @lang).build do |html|
        html << Elements::Head.new.build do |head|
          head << Elements::Title.new.build { |title| title << @title }
          @head_content.try(&.call)
        end
        html << Elements::Body.new.build do |_body|
          @body_content.try(&.call)
        end
      end.render
    end
  end

  # Helper method to create raw HTML
  def self.raw_html(content : String)
    Elements::RawHTML.new(content)
  end
end
