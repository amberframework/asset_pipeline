require "../base/container_element"
require "../base/void_element"

module Components
  module Elements
    # Represents the <video> element - video content
    class Video < ContainerElement
      def initialize(**attrs)
        super("video", **attrs)
      end
      
      # Validate video-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "controls", "autoplay", "loop", "muted", "playsinline"
          # Boolean attributes
        when "preload"
          valid_values = ["none", "metadata", "auto"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid preload value: #{value}")
          end
        when "crossorigin"
          valid_values = ["anonymous", "use-credentials"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid crossorigin value: #{value}")
          end
        end
      end
    end
    
    # Represents the <audio> element - audio content
    class Audio < ContainerElement
      def initialize(**attrs)
        super("audio", **attrs)
      end
      
      # Validate audio-specific attributes (similar to video)
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "controls", "autoplay", "loop", "muted"
          # Boolean attributes
        when "preload"
          valid_values = ["none", "metadata", "auto"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid preload value: #{value}")
          end
        when "crossorigin"
          valid_values = ["anonymous", "use-credentials"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid crossorigin value: #{value}")
          end
        end
      end
    end
    
    # Represents the <source> element - media resource
    class Source < VoidElement
      def initialize(**attrs)
        super("source", **attrs)
      end
      
      
      # Validate source-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          # Should be a valid MIME type
          unless value.to_s.match(/^[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*$/)
            raise ArgumentError.new("Invalid MIME type format: #{value}")
          end
        when "media"
          # Media queries are complex to validate
        end
      end
    end
    
    # Represents the <track> element - text track for media
    class Track < VoidElement
      def initialize(**attrs)
        super("track", **attrs)
      end
      
      # Validate track-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "kind"
          valid_kinds = ["subtitles", "captions", "descriptions", "chapters", "metadata"]
          if value && !valid_kinds.includes?(value)
            raise ArgumentError.new("Invalid track kind: #{value}")
          end
        when "srclang"
          # Should be a valid language code
        end
      end
    end
    
    # Represents the <iframe> element - nested browsing context
    class Iframe < ContainerElement
      def initialize(**attrs)
        super("iframe", **attrs)
      end
      
      # Validate iframe-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "sandbox"
          # Can be empty or space-separated list of allowed features
          valid_tokens = ["allow-downloads", "allow-forms", "allow-modals", 
                         "allow-orientation-lock", "allow-pointer-lock", 
                         "allow-popups", "allow-popups-to-escape-sandbox",
                         "allow-presentation", "allow-same-origin", 
                         "allow-scripts", "allow-top-navigation"]
          # Validate tokens if needed
        when "loading"
          valid_values = ["lazy", "eager"]
          if value && !valid_values.includes?(value)
            raise ArgumentError.new("Invalid loading value: #{value}")
          end
        end
      end
    end
    
    # Represents the <embed> element - external content
    class Embed < VoidElement
      def initialize(**attrs)
        super("embed", **attrs)
      end
      
      # Validate embed-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          # Should be a valid MIME type
          unless value.to_s.match(/^[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*$/)
            raise ArgumentError.new("Invalid MIME type format: #{value}")
          end
        end
      end
    end
    
    # Represents the <object> element - external resource
    class Object < ContainerElement
      def initialize(**attrs)
        super("object", **attrs)
      end
      
      # Validate object-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "type"
          # Should be a valid MIME type
          unless value.to_s.match(/^[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*\/[a-zA-Z0-9][a-zA-Z0-9!#$&\-\^_+\.]*$/)
            raise ArgumentError.new("Invalid MIME type format: #{value}")
          end
        end
      end
    end
    
    # Represents the <param> element - parameter for object
    class Param < VoidElement
      def initialize(**attrs)
        super("param", **attrs)
      end
      
      # Validate param-specific attributes
      protected def validate_attribute(name : String, value : String?)
        super
        
        case name
        when "name", "value"
          # Both are required for param element
          if value.nil? || value.empty?
            raise ArgumentError.new("param element requires both name and value attributes")
          end
        end
      end
    end
    
    # Represents the <canvas> element - graphics canvas
    class Canvas < ContainerElement
      def initialize(**attrs)
        super("canvas", **attrs)
      end
    end
    
    # Represents the <svg> element - scalable vector graphics
    class Svg < ContainerElement
      def initialize(**attrs)
        super("svg", **attrs)
      end
      
      # SVG content is not escaped like HTML
      protected def render_children : String
        @children.map do |child|
          case child
          when HTMLElement
            child.render
          when String
            # Don't escape SVG content
            child
          else
            child.to_s
          end
        end.join
      end
    end
    
    # Represents the <picture> element - multiple image sources
    class Picture < ContainerElement
      def initialize(**attrs)
        super("picture", **attrs)
      end
    end
  end
end