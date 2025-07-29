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
          Field.new("message", "textarea", "Message", true, "Enter your message")
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
          success_div = Elements::Div.new(class: "alert alert-success")
          success_div << "Form submitted successfully!"
          return success_div.render
        end
        
        # Build form
        form = Elements::Form.new(
          action: @attributes["action"]? || "#",
          method: @attributes["method"]? || "POST",
          "data-action": "submit->submit"
        ).build do |f|
          fields.each do |field|
            # Form group
            f << Elements::Div.new(class: "form-group").build do |group|
              # Label
              label = Elements::Label.new(for: field.name)
              label << field.label
              if field.required
                required_span = Elements::Span.new(class: "text-danger")
                required_span << " *"
                label << required_span
              end
              group << label
              
              # Input/Textarea
              value = values[field.name]?.try(&.as_s?) || ""
              error = errors[field.name]?.try(&.as_s?)
              
              input_classes = ["form-control"]
              input_classes << "is-invalid" if error
              
              if field.type == "textarea"
                textarea = Elements::Textarea.new(
                  name: field.name,
                  id: field.name,
                  class: input_classes.join(" "),
                  placeholder: field.placeholder,
                  required: field.required ? "true" : nil,
                  "data-action": "input->field_changed",
                  "data-field": field.name
                )
                textarea << value
                group << textarea
              else
                group << Elements::Input.new(
                  type: field.type,
                  name: field.name,
                  id: field.name,
                  value: value,
                  class: input_classes.join(" "),
                  placeholder: field.placeholder,
                  required: field.required ? "true" : nil,
                  "data-action": "input->field_changed",
                  "data-field": field.name
                )
              end
              
              # Error message
              if error
                error_div = Elements::Div.new(class: "invalid-feedback")
                error_div << error
                group << error_div
              end
            end
          end
          
          # Submit button
          submit_btn = Elements::Button.new(
            type: "submit",
            class: "btn btn-primary",
            disabled: submitting ? "true" : nil
          )
          submit_btn << (submitting ? "Submitting..." : "Submit")
          f << submit_btn
        end
        
        form.render
      end
    end
  end
end