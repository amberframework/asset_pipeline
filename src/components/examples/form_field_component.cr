require "../base/stateless_component"
require "../elements/forms/input"
require "../elements/forms/form_controls"
require "../elements/base/raw_html"

module Components
  module Examples
    # Token-backed label/control wrapper for common browser-native form fields.
    #
    # The component keeps the public contract semantic: callers pick the native
    # control type and HTML validation attributes, while Amber supplies the
    # consistent label, hint, invalid, and data-hook structure.
    class FormFieldComponent < StatelessComponent
      record Option, label : String, value : String

      component_css <<-CSS
      .am-field {
        display: grid;
        gap: 0.42rem;
      }

      .am-field > span:first-child,
      .am-field label {
        color: var(--ap-color-text-secondary);
        font-size: 0.875rem;
        font-weight: 680;
      }

      .am-field__hint {
        color: var(--ap-color-text-muted);
        font-size: 0.8125rem;
      }

      .am-field__error {
        color: var(--ap-color-danger-text);
        font-size: 0.8125rem;
        font-weight: 680;
      }

      .am-input,
      .am-select,
      .am-textarea {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-default);
        border-radius: var(--ap-radius-control);
        color: var(--ap-color-text-primary);
        font: inherit;
        min-height: 2.55rem;
        padding: 0.65rem 0.75rem;
        width: 100%;
      }

      .am-textarea {
        min-height: 7rem;
        resize: vertical;
      }

      .am-input:focus,
      .am-select:focus,
      .am-textarea:focus {
        border-color: var(--ap-color-border-focus);
        box-shadow: 0 0 0 3px var(--ap-color-border-focus);
        outline: none;
      }

      .am-input[aria-invalid="true"],
      .am-select[aria-invalid="true"],
      .am-textarea[aria-invalid="true"] {
        border-color: var(--ap-color-danger-border);
        box-shadow: 0 0 0 3px var(--ap-color-danger-focus-ring);
      }

      .am-range {
        accent-color: var(--ap-color-brand-primary);
        min-height: 1.5rem;
        width: 100%;
      }
      CSS

      @options : Array(Option)
      @data_attrs : Hash(String, String)
      @aria_attrs : Hash(String, String)

      def initialize(
        @options : Array(Option) = [] of Option,
        @data_attrs : Hash(String, String) = {} of String => String,
        @aria_attrs : Hash(String, String) = {} of String => String,
        **attrs,
      )
        super(**attrs)
      end

      def render_content : String
        id = @attributes["id"]? || @attributes["name"]? || "field-#{component_id}"
        label = @attributes["label"]? || id
        type = @attributes["type"]? || "text"
        wide = @attributes["wide"]? == "true"
        error = @attributes["error"]?

        wrapper_classes = ["am-field"]
        wrapper_classes << "am-field--wide" if wide

        Elements::Label.new(for: id, class: wrapper_classes.join(" ")).build do |field|
          field.set_attribute("data-component", "field")
          title = Elements::Span.new
          title << label
          field << title
          field << control_for(type, id, error)

          if hint_html = @attributes["hint_html"]?
            field << Elements::RawHTML.new(%(<span class="am-field__hint">#{hint_html}</span>))
          elsif hint = @attributes["hint"]?
            hint_el = Elements::Span.new(class: "am-field__hint")
            hint_el << hint
            field << hint_el
          end

          if error
            error_el = Elements::Span.new(class: "am-field__error")
            error_el.set_attribute("id", "#{id}-error")
            error_el << error
            field << error_el
          end
        end.render
      end

      private def control_for(type : String, id : String, error : String?) : Elements::HTMLElement
        case type
        when "select"
          select_el = Elements::Select.new(id: id, name: name_for(id), class: "am-select")
          common_control_attributes(select_el, error)
          @options.each do |option|
            select_el << Elements::Option.new(option.label, option.value)
          end
          select_el
        when "textarea"
          textarea = Elements::Textarea.new(id: id, name: name_for(id), class: "am-textarea")
          common_control_attributes(textarea, error)
          if value = @attributes["value"]?
            textarea << value
          end
          textarea
        else
          input_class = type == "range" ? "am-range" : "am-input"
          input = Elements::Input.new(type: type, id: id, name: name_for(id), class: input_class)
          common_control_attributes(input, error)
          input
        end
      end

      private def common_control_attributes(control : Elements::HTMLElement, error : String?) : Nil
        %w[autocomplete placeholder min max minlength maxlength pattern inputmode step value].each do |name|
          control.set_attribute(name, @attributes[name]) if @attributes[name]?
        end

        control.set_attribute("required", "required") if @attributes["required"]? == "true"
        control.set_attribute("disabled", "disabled") if @attributes["disabled"]? == "true"
        control.set_attribute("readonly", "readonly") if @attributes["readonly"]? == "true"
        control.set_attribute("aria-invalid", "true") if error
        control.set_attribute("aria-describedby", "#{control["id"]}-error") if error

        @data_attrs.each { |name, value| control.set_attribute(name, value) }
        @aria_attrs.each { |name, value| control.set_attribute(name, value) }
      end

      private def name_for(id : String) : String
        @attributes["name"]? || id.tr("-", "_")
      end
    end
  end
end
