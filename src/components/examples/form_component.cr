require "../base/stateful_component"
require "../elements/forms/form"
require "../elements/forms/input"
require "../elements/forms/form_controls"
require "../elements/grouping/div"
require "../elements/text/text_semantics"

module Components
  module Examples
    # A form component with validation
    class FormComponent < StatefulComponent
      component_css <<-CSS
      .am-form {
        display: grid;
        gap: 1rem;
      }

      .am-field {
        display: grid;
        gap: 0.375rem;
      }

      .am-field label {
        color: var(--ap-color-text-secondary);
        font-weight: 680;
      }

      .am-field__required,
      .am-field__error {
        color: var(--ap-color-danger-text);
      }

      .am-field__error {
        font-size: 0.875rem;
      }

      .am-input {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-default);
        border-radius: var(--ap-radius-control);
        color: var(--ap-color-text-primary);
        min-height: 2.5rem;
        padding: 0.625rem 0.75rem;
      }

      .am-input--invalid,
      .am-input[aria-invalid="true"] {
        border-color: var(--ap-color-danger-border);
        box-shadow: 0 0 0 3px var(--ap-color-danger-focus-ring);
      }

      .am-alert {
        border-radius: var(--ap-radius-card);
        padding: 0.85rem 1rem;
      }

      .am-alert--success {
        background: var(--ap-color-success-bg);
        border: 1px solid var(--ap-color-success-border);
        color: var(--ap-color-success-text);
      }
      CSS

      # Form field configuration
      struct Field
        property name : String
        property type : String
        property label : String
        property required : Bool
        property placeholder : String?
        property value : String
        property error : String?

        def initialize(@name, @type, @label, @required = false, @placeholder = nil)
          @value = ""
          @error = nil
        end
      end

      # Initialize form state
      protected def initialize_state
        # Form values
        set_state("values", {} of String => JSON::Any)

        # Form errors
        set_state("errors", {} of String => JSON::Any)

        # Form metadata
        set_state("submitted", false)
        set_state("submitting", false)
      end

      # Get form fields from attributes or use defaults
      private def fields : Array(Field)
        # This would normally be configured via attributes
        # For demo purposes, creating a simple contact form
        [
          Field.new("name", "text", "Name", true, "Enter your name"),
          Field.new("email", "email", "Email", true, "Enter your email"),
          Field.new("message", "textarea", "Message", true, "Enter your message"),
        ]
      end

      # Validate a single field
      private def validate_field(field : Field, value : String) : String?
        # Required validation
        if field.required && value.empty?
          return "#{field.label} is required"
        end

        # Email validation
        if field.type == "email" && !value.empty?
          unless value.matches?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
            return "Please enter a valid email address"
          end
        end

        nil
      end

      # Handle field change
      def field_changed(data : JSON::Any)
        field_name = data["field"]?.try(&.as_s?) || return
        value = data["value"]?.try(&.as_s?) || ""

        # Update value
        values = get_state("values").try(&.as_h?) || {} of String => JSON::Any
        values[field_name] = JSON::Any.new(value)
        set_state("values", values)

        # Validate field
        if field = fields.find { |f| f.name == field_name }
          errors = get_state("errors").try(&.as_h?) || {} of String => JSON::Any

          if error = validate_field(field, value)
            errors[field_name] = JSON::Any.new(error)
          else
            errors.delete(field_name)
          end

          set_state("errors", errors)
        end
      end

      # Handle form submission
      def submit(data : JSON::Any? = nil)
        set_state("submitting", true)

        # Validate all fields
        values = get_state("values").try(&.as_h?) || {} of String => JSON::Any
        errors = {} of String => JSON::Any

        fields.each do |field|
          value = values[field.name]?.try(&.as_s?) || ""
          if error = validate_field(field, value)
            errors[field.name] = JSON::Any.new(error)
          end
        end

        set_state("errors", errors)

        if errors.empty?
          # Form is valid - normally would submit to server
          set_state("submitted", true)
        end

        set_state("submitting", false)
      end

      def render_content : String
        values = get_state("values").try(&.as_h?) || {} of String => JSON::Any
        errors = get_state("errors").try(&.as_h?) || {} of String => JSON::Any
        submitted = get_state("submitted").try(&.as_bool?) || false
        submitting = get_state("submitting").try(&.as_bool?) || false

        if submitted
          # Success message
          success_div = Elements::Div.new(class: "am-alert am-alert--success")
          success_div.set_attribute("role", "status")
          success_div << "Form submitted successfully!"
          return success_div.render
        end

        # Build form
        form = Elements::Form.new(
          action: @attributes["action"]? || "#",
          method: @attributes["method"]? || "POST",
          class: "am-form",
          "data-action": "submit->submit"
        ).build do |f|
          fields.each do |field|
            # Form group
            f << Elements::Div.new(class: "am-field").build do |group|
              # Label
              label = Elements::Label.new(for: field.name)
              label << field.label
              if field.required
                required_span = Elements::Span.new(class: "am-field__required")
                required_span << " *"
                label << required_span
              end
              group << label

              # Input/Textarea
              value = values[field.name]?.try(&.as_s?) || ""
              error = errors[field.name]?.try(&.as_s?)

              input_classes = ["am-input"]
              input_classes << "am-input--invalid" if error
              described_by = error ? "#{field.name}-error" : nil

              if field.type == "textarea"
                textarea = Elements::Textarea.new(
                  name: field.name,
                  id: field.name,
                  class: input_classes.join(" "),
                  placeholder: field.placeholder,
                  "data-action": "input->field_changed",
                  "data-field": field.name
                )
                textarea.set_attribute("required", "required") if field.required
                textarea.set_attribute("aria-invalid", "true") if error
                textarea.set_attribute("aria-describedby", described_by) if described_by
                textarea << value
                group << textarea
              else
                input = Elements::Input.new(
                  type: field.type,
                  name: field.name,
                  id: field.name,
                  value: value,
                  class: input_classes.join(" "),
                  placeholder: field.placeholder,
                  "data-action": "input->field_changed",
                  "data-field": field.name
                )
                input.set_attribute("required", "required") if field.required
                input.set_attribute("aria-invalid", "true") if error
                input.set_attribute("aria-describedby", described_by) if described_by
                group << input
              end

              # Error message
              if error
                error_div = Elements::Div.new(class: "am-field__error")
                error_div.set_attribute("id", "#{field.name}-error")
                error_div << error
                group << error_div
              end
            end
          end

          # Submit button
          submit_btn = Elements::Button.new(
            type: "submit",
            class: "am-button am-button--brand am-button--solid am-button--md"
          )
          submit_btn.set_attribute("disabled", "disabled") if submitting
          submit_btn.set_attribute("aria-busy", "true") if submitting
          submit_btn << (submitting ? "Submitting..." : "Submit")
          f << submit_btn
        end

        form.render
      end
    end
  end
end
