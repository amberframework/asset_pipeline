module Components
  module CSS
    module Engine
      # Represents a single CSS rule
      class Rule
        getter selector : String
        getter declarations : Hash(String, String)
        getter media_query : String?
        getter pseudo_class : String?
        getter attribute_selector : String?
        getter container_query : String?
        getter priority : Int32

        def initialize(@selector : String, @priority : Int32 = 0)
          @declarations = {} of String => String
          @media_query = nil
          @pseudo_class = nil
          @attribute_selector = nil
          @container_query = nil
        end

        # Add a declaration
        def add_declaration(property : String, value : String)
          @declarations[property] = value
        end

        # Set media query
        def with_media(query : String) : self
          @media_query = query
          self
        end

        # Set pseudo class
        def with_pseudo(pseudo : String) : self
          @pseudo_class = pseudo
          self
        end

        # Set a complex pseudo selector (e.g., ":is([inert], [inert] *)")
        def with_complex_pseudo(selector : String) : self
          @pseudo_class = selector
          self
        end

        # Set attribute selector with value (e.g., [aria-expanded="true"])
        def with_attribute(attr : String, value : String) : self
          @attribute_selector = "[#{attr}=\"#{value}\"]"
          self
        end

        # Set attribute presence selector (e.g., [data-disabled])
        def with_attribute_present(attr : String) : self
          @attribute_selector = "[#{attr}]"
          self
        end

        # Set attribute selector directly
        def set_attribute_selector(selector : String) : self
          @attribute_selector = selector
          self
        end

        # Set container query
        def with_container(query : String) : self
          @container_query = query
          self
        end

        # Get the full selector (with pseudo class and attribute selector)
        def full_selector : String
          sel = @selector
          if attr = @attribute_selector
            sel = "#{sel}#{attr}"
          end
          if pseudo = @pseudo_class
            if pseudo.starts_with?(":")
              # Complex pseudo like :is([inert], [inert] *)
              sel = "#{sel}#{pseudo}"
            else
              sel = "#{sel}:#{pseudo}"
            end
          end
          sel
        end

        # Render to CSS
        def render : String
          return "" if @declarations.empty?

          String.build do |str|
            str << full_selector
            str << " {\n"

            @declarations.each do |property, value|
              str << "  #{property}: #{value};\n"
            end

            str << "}"
          end
        end

        # Check if this rule matches a class name
        def matches_class?(class_name : String) : Bool
          # Handle different selector formats
          case @selector
          when /^\.#{Regex.escape(class_name)}$/
            true
          when /^\.#{Regex.escape(class_name)}[\s:>+~\[]/
            true
          else
            false
          end
        end
      end
    end
  end
end
