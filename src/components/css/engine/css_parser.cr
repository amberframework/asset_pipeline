module Components
  module CSS
    module Engine
      # Parses CSS class names and generates appropriate rules
      class Parser
        # Parse a utility class name into property declarations
        def self.parse_utility(class_name : String, config : Config) : Hash(String, String)?
          # Remove any prefix modifiers (hover:, sm:, etc.)
          base_class = class_name.split(":").last
          
          # Parse different utility types
          case base_class
          # Spacing utilities (margin, padding)
          when /^m-(.+)$/
            parse_margin($1, config)
          when /^mx-(.+)$/
            parse_margin_x($1, config)
          when /^my-(.+)$/
            parse_margin_y($1, config)
          when /^mt-(.+)$/, /^mr-(.+)$/, /^mb-(.+)$/, /^ml-(.+)$/
            parse_margin_side(base_class, config)
          when /^p-(.+)$/
            parse_padding($1, config)
          when /^px-(.+)$/
            parse_padding_x($1, config)
          when /^py-(.+)$/
            parse_padding_y($1, config)
          when /^pt-(.+)$/, /^pr-(.+)$/, /^pb-(.+)$/, /^pl-(.+)$/
            parse_padding_side(base_class, config)
            
          # Display & positioning
          when "block"
            {"display" => "block"}
          when "inline-block"
            {"display" => "inline-block"}
          when "inline"
            {"display" => "inline"}
          when "flex"
            {"display" => "flex"}
          when "inline-flex"
            {"display" => "inline-flex"}
          when "grid"
            {"display" => "grid"}
          when "hidden"
            {"display" => "none"}
          when "relative"
            {"position" => "relative"}
          when "absolute"
            {"position" => "absolute"}
          when "fixed"
            {"position" => "fixed"}
          when "sticky"
            {"position" => "sticky"}
            
          # Flexbox
          when "flex-row"
            {"flex-direction" => "row"}
          when "flex-col"
            {"flex-direction" => "column"}
          when "flex-wrap"
            {"flex-wrap" => "wrap"}
          when "flex-nowrap"
            {"flex-wrap" => "nowrap"}
          when "items-center"
            {"align-items" => "center"}
          when "items-start"
            {"align-items" => "flex-start"}
          when "items-end"
            {"align-items" => "flex-end"}
          when "justify-center"
            {"justify-content" => "center"}
          when "justify-between"
            {"justify-content" => "space-between"}
          when "justify-around"
            {"justify-content" => "space-around"}
          when "justify-start"
            {"justify-content" => "flex-start"}
          when "justify-end"
            {"justify-content" => "flex-end"}
          when /^gap-(.+)$/
            if value = config.spacing[$1]?
              {"gap" => value}
            end
            
          # Width & Height
          when "w-full"
            {"width" => "100%"}
          when "w-auto"
            {"width" => "auto"}
          when /^w-(.+)$/
            if value = config.spacing[$1]?
              {"width" => value}
            end
          when "h-full"
            {"height" => "100%"}
          when "h-auto"
            {"height" => "auto"}
          when /^h-(.+)$/
            if value = config.spacing[$1]?
              {"height" => value}
            end
          when "min-w-full"
            {"min-width" => "100%"}
          when "max-w-full"
            {"max-width" => "100%"}
            
          # Typography
          when /^font-(.+)$/
            parse_font($1, config)
          when /^leading-(.+)$/
            if value = config.line_heights[$1]?
              {"line-height" => value}
            end
          when /^tracking-(.+)$/
            if value = config.letter_spacing[$1]?
              {"letter-spacing" => value}
            end
            
          # Colors
          when /^bg-(.+)$/
            if color = config.get_color($1)
              {"background-color" => color}
            end
          when /^text-(.+)$/
            parse_text($1, config)
          when /^border-(.+)$/
            if color = config.get_color($1)
              {"border-color" => color}
            end
            
          # Borders
          when "border"
            {"border-width" => "1px"}
          when /^border-(\d+)$/
            {"border-width" => "#{$1}px"}
          when /^rounded(?:-(.+))?$/
            radius = $1? || "DEFAULT"
            if value = config.border_radius[radius]?
              {"border-radius" => value}
            end
            
          # Shadows
          when /^shadow(?:-(.+))?$/
            size = $1? || "DEFAULT"
            if value = config.shadows[size]?
              {"box-shadow" => value}
            end
            
          # Opacity
          when /^opacity-(.+)$/
            if value = config.opacity[$1]?
              {"opacity" => value}
            end
            
          # Z-index
          when /^z-(.+)$/
            if value = config.z_index[$1]?
              {"z-index" => value}
            end
            
          # Transitions
          when /^transition(?:-(.+))?$/
            type = $1? || "DEFAULT"
            if value = config.transitions[type]?
              {"transition" => value}
            end
            
          # Overflow
          when "overflow-hidden"
            {"overflow" => "hidden"}
          when "overflow-auto"
            {"overflow" => "auto"}
          when "overflow-scroll"
            {"overflow" => "scroll"}
          when "overflow-visible"
            {"overflow" => "visible"}
            
          # Cursor
          when "cursor-pointer"
            {"cursor" => "pointer"}
          when "cursor-default"
            {"cursor" => "default"}
          when "cursor-not-allowed"
            {"cursor" => "not-allowed"}
            
          else
            nil
          end
        end
        
        # Parse margin utilities
        private def self.parse_margin(value : String, config : Config) : Hash(String, String)?
          if spacing = config.spacing[value]?
            {"margin" => spacing}
          end
        end
        
        private def self.parse_margin_x(value : String, config : Config) : Hash(String, String)?
          if spacing = config.spacing[value]?
            {
              "margin-left" => spacing,
              "margin-right" => spacing
            }
          end
        end
        
        private def self.parse_margin_y(value : String, config : Config) : Hash(String, String)?
          if spacing = config.spacing[value]?
            {
              "margin-top" => spacing,
              "margin-bottom" => spacing
            }
          end
        end
        
        private def self.parse_margin_side(class_name : String, config : Config) : Hash(String, String)?
          case class_name
          when /^mt-(.+)$/
            if spacing = config.spacing[$1]?
              {"margin-top" => spacing}
            end
          when /^mr-(.+)$/
            if spacing = config.spacing[$1]?
              {"margin-right" => spacing}
            end
          when /^mb-(.+)$/
            if spacing = config.spacing[$1]?
              {"margin-bottom" => spacing}
            end
          when /^ml-(.+)$/
            if spacing = config.spacing[$1]?
              {"margin-left" => spacing}
            end
          end
        end
        
        # Parse padding utilities
        private def self.parse_padding(value : String, config : Config) : Hash(String, String)?
          if spacing = config.spacing[value]?
            {"padding" => spacing}
          end
        end
        
        private def self.parse_padding_x(value : String, config : Config) : Hash(String, String)?
          if spacing = config.spacing[value]?
            {
              "padding-left" => spacing,
              "padding-right" => spacing
            }
          end
        end
        
        private def self.parse_padding_y(value : String, config : Config) : Hash(String, String)?
          if spacing = config.spacing[value]?
            {
              "padding-top" => spacing,
              "padding-bottom" => spacing
            }
          end
        end
        
        private def self.parse_padding_side(class_name : String, config : Config) : Hash(String, String)?
          case class_name
          when /^pt-(.+)$/
            if spacing = config.spacing[$1]?
              {"padding-top" => spacing}
            end
          when /^pr-(.+)$/
            if spacing = config.spacing[$1]?
              {"padding-right" => spacing}
            end
          when /^pb-(.+)$/
            if spacing = config.spacing[$1]?
              {"padding-bottom" => spacing}
            end
          when /^pl-(.+)$/
            if spacing = config.spacing[$1]?
              {"padding-left" => spacing}
            end
          end
        end
        
        # Parse text utilities
        private def self.parse_text(value : String, config : Config) : Hash(String, String)?
          # Check if it's a font size
          if size = config.font_sizes[value]?
            {"font-size" => size}
          elsif color = config.get_color(value)
            {"color" => color}
          else
            # Text alignment
            case value
            when "left"
              {"text-align" => "left"}
            when "center"
              {"text-align" => "center"}
            when "right"
              {"text-align" => "right"}
            when "justify"
              {"text-align" => "justify"}
            end
          end
        end
        
        # Parse font utilities
        private def self.parse_font(value : String, config : Config) : Hash(String, String)?
          # Font weight
          case value
          when "thin"
            {"font-weight" => "100"}
          when "light"
            {"font-weight" => "300"}
          when "normal"
            {"font-weight" => "400"}
          when "medium"
            {"font-weight" => "500"}
          when "semibold"
            {"font-weight" => "600"}
          when "bold"
            {"font-weight" => "700"}
          when "extrabold"
            {"font-weight" => "800"}
          when "black"
            {"font-weight" => "900"}
          else
            # Font family
            if family = config.fonts[value]?
              {"font-family" => family}
            end
          end
        end
        
        # Extract modifiers from a class name
        def self.extract_modifiers(class_name : String) : {modifiers: Array(String), base: String}
          parts = class_name.split(":")
          if parts.size > 1
            {modifiers: parts[0..-2], base: parts[-1]}
          else
            {modifiers: [] of String, base: class_name}
          end
        end
      end
    end
  end
end