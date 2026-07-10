# Design-system component skeleton.
#
# Replace `ExampleWidget` with a product name and add a contract section in
# docs before promoting the component.

# Repo-local path for this template. Consuming apps should use:
# require "asset_pipeline/design_system"
require "../../src/asset_pipeline/design_system"

module Components
  module DesignSystem
    # Use an app-specific component name that does not collide with promoted
    # Asset Pipeline aliases such as Button, Card, Dialog, or FormField.
    class ExampleWidget < StatelessComponent
      component_css <<-CSS
      .ap-example-widget {
        background: var(--ap-color-surface-panel, var(--amber-color-surface-panel));
        border: 1px solid var(--ap-color-border-default, var(--amber-color-border-default));
        border-radius: var(--ap-radius-panel, var(--amber-radius-panel));
        color: var(--ap-color-text-primary, var(--amber-color-text-primary));
        padding: var(--spacing-4);
      }
      CSS

      def initialize(@title : String, @id : String = "example-widget", **attrs)
        super(**attrs)
      end

      def render_content : String
        Elements::Section.new(
          id: @id,
          class: "ap-example-widget",
          "data-component": "example-widget",
          "aria-labelledby": "#{@id}-title",
        ).build do |section|
          heading = Elements::H2.new(id: "#{@id}-title")
          heading << @title
          section << heading
          section << Elements::P.new.build { |p| p << "Replace this copy with real component content." }
        end.render
      end
    end
  end
end
