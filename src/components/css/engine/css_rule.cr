module Components
  module CSS
    module Engine
      # Represents a single CSS rule
      class Rule
        getter selector : String
        getter declarations : Hash(String, String)
        getter media_query : String?
        getter pseudo_class : String?
        getter priority : Int32
        
        def initialize(@selector : String, @priority : Int32 = 0)
          @declarations = {} of String => String
          @media_query = nil
          @pseudo_class = nil
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
        
        # Get the full selector (with pseudo class if present)
        def full_selector : String
          if pseudo = @pseudo_class
            "#{@selector}:#{pseudo}"
          else
            @selector
          end
        end
        
        # Render to CSS
        def render : String
          return "" if @declarations.empty?
          
          rules = String.build do |str|
            str << full_selector
            str << " {\n"
            
            @declarations.each do |property, value|
              str << "  #{property}: #{value};\n"
            end
            
            str << "}"
          end
          
          # Wrap in media query if present
          if media = @media_query
            <<-CSS
            @media #{media} {
              #{rules}
            }
            CSS
          else
            rules
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