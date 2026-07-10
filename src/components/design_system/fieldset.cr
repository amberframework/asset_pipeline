require "../base/stateless_component"

module Components
  module DesignSystem
    class Fieldset < StatelessComponent
      component_css <<-CSS
      .am-form-fieldset {
        border: 0;
        display: grid;
        gap: 1rem;
        margin: 0;
        min-inline-size: 0;
        padding: 0;
      }

      .am-visually-hidden {
        border: 0;
        clip: rect(0 0 0 0);
        clip-path: inset(50%);
        height: 1px;
        margin: -1px;
        overflow: hidden;
        padding: 0;
        position: absolute;
        white-space: nowrap;
        width: 1px;
      }
      CSS

      private def root_classes(base : String, modifiers : Array(String) = [] of String) : String
        classes = [base]
        modifiers.each do |modifier|
          next if modifier.empty?
          classes << "#{base}--#{modifier}"
        end

        if extra = @attributes["class"]?
          classes.concat(extra.split(/\s+/).reject(&.empty?))
        end

        classes.join(" ")
      end

      private def bool_attr?(name : String) : Bool
        @attributes[name]? == "true"
      end

      private def escaped(value : String) : String
        escape_html(value)
      end

      def render_content : String
        id = @attributes["id"]?
        legend = @attributes["legend"]? || @attributes["label"]? || "Grouped fields"
        describedby = @attributes["described_by"]? || @attributes["describedby"]? || @attributes["aria_describedby"]?
        hidden_legend = @attributes["hidden_legend"]? != "false"
        legend_class = @attributes["legend_class"]? || (hidden_legend ? "am-visually-hidden" : nil)
        disabled = bool_attr?("disabled")

        String.build do |io|
          io << %(<fieldset class="#{root_classes("am-form-fieldset")}")
          io << %( id="#{escaped(id)}") if id
          io << %( aria-describedby="#{escaped(describedby)}") if describedby
          io << " disabled" if disabled
          io << ">"
          io << %(<legend)
          io << %( class="#{escaped(legend_class)}") if legend_class
          io << ">#{escaped(legend)}</legend>"
          io << render_children
          io << "</fieldset>"
        end
      end
    end
  end
end
