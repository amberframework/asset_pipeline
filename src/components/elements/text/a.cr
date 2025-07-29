require "../base/container_element"

module Components
  module Elements
    # Represents the <a> element - hyperlink
    class A < ContainerElement
      def initialize(**attrs)
        super("a", **attrs)
      end
      
      
      # Validate a-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "target"
          valid_targets = ["_blank", "_self", "_parent", "_top"]
          unless valid_targets.includes?(value) || value.to_s.starts_with?("frame")
            # Custom frame names are allowed
          end
        when "rel"
          # Common rel values for links
          valid_rels = ["noopener", "noreferrer", "nofollow", "alternate", "author", 
                       "bookmark", "external", "help", "license", "next", "prev", 
                       "search", "tag"]
          # Multiple values allowed, space-separated
        when "download"
          # Can be empty (boolean) or contain filename
        end
      end
    end
  end
end