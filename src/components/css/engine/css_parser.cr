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
            # Opinionated design-system visual utilities
          when "bg-gradient-brand"
            {"background-image" => "linear-gradient(135deg, var(--ap-color-brand-primary), var(--ap-color-brand-accent))"}
          when "bg-size-200"
            {"background-size" => "200% 200%"}
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
          when /^duration-(.+)$/
            {
              "transition-duration" => case $1
              when "instant" then "var(--ap-motion-duration-instant)"
              when "fast"    then "var(--ap-motion-duration-fast)"
              when "base"    then "var(--ap-motion-duration-base)"
              when "slow"    then "var(--ap-motion-duration-slow)"
              else                "#{$1}ms"
              end,
            }
          when /^ease-(.+)$/
            {
              "transition-timing-function" => case $1
              when "standard"   then "var(--ap-motion-ease-standard)"
              when "emphasized" then "var(--ap-motion-ease-emphasized)"
              when "spring"     then "var(--ap-motion-spring)"
              else                   "var(--ap-motion-ease-standard)"
              end,
            }
          when "transform"
            {"transform" => "translateZ(0)"}
          when /^translate-y-(.+)$/
            if value = config.spacing[$1]?
              {"transform" => "translateY(#{value})"}
            end
          when /^-translate-y-(.+)$/
            if value = config.spacing[$1]?
              {"transform" => "translateY(calc(#{value} * -1))"}
            end
          when /^scale-(\d+)$/
            {"transform" => "scale(#{$1.to_f / 100})"}
          when /^rotate-(\-?\d+)$/
            {"transform" => "rotate(#{$1}deg)"}
          when "animate-row-in"
            {"animation" => "ap-row-enter var(--ap-motion-duration-base) var(--ap-motion-ease-emphasized) both"}
          when "animate-row-out"
            {"animation" => "ap-row-exit var(--ap-motion-duration-fast) var(--ap-motion-ease-standard) both"}
          when "animate-section-in"
            {"animation" => "ap-section-reveal var(--ap-motion-duration-slow) var(--ap-motion-ease-emphasized) both"}
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
            # Screen reader utilities (WCAG 1.1.1)
          when "sr-only"
            {
              "position"     => "absolute",
              "width"        => "1px",
              "height"       => "1px",
              "padding"      => "0",
              "margin"       => "-1px",
              "overflow"     => "hidden",
              "clip"         => "rect(0, 0, 0, 0)",
              "white-space"  => "nowrap",
              "border-width" => "0",
            }
          when "not-sr-only"
            {
              "position"    => "static",
              "width"       => "auto",
              "height"      => "auto",
              "padding"     => "0",
              "margin"      => "0",
              "overflow"    => "visible",
              "clip"        => "auto",
              "white-space" => "normal",
            }
            # Focus ring utilities (WCAG 2.4.7)
          when "ring"
            {"box-shadow" => "0 0 0 3px oklch(0.623 0.214 259.815 / 0.5)"}
          when "ring-0"
            {"box-shadow" => "0 0 0 0px oklch(0.623 0.214 259.815 / 0.5)"}
          when "ring-1"
            {"box-shadow" => "0 0 0 1px oklch(0.623 0.214 259.815 / 0.5)"}
          when "ring-2"
            {"box-shadow" => "0 0 0 2px oklch(0.623 0.214 259.815 / 0.5)"}
          when "ring-4"
            {"box-shadow" => "0 0 0 4px oklch(0.623 0.214 259.815 / 0.5)"}
          when "ring-8"
            {"box-shadow" => "0 0 0 8px oklch(0.623 0.214 259.815 / 0.5)"}
          when "ring-inset"
            {"box-shadow" => "inset 0 0 0 3px oklch(0.623 0.214 259.815 / 0.5)"}
          when /^ring-(.+)$/
            if color = config.get_color($1)
              {"box-shadow" => "0 0 0 3px #{color}"}
            end
          when /^outline-(\d+)$/
            {"outline-width" => "#{$1}px"}
          when "outline-none"
            {"outline" => "2px solid transparent", "outline-offset" => "2px"}
          when /^outline-offset-(\d+)$/
            {"outline-offset" => "#{$1}px"}
            # Min-width / Min-height (WCAG 2.5.8 Target Size)
          when "min-w-0"
            {"min-width" => "0px"}
          when /^min-w-(.+)$/
            if value = config.spacing[$1]?
              {"min-width" => value}
            end
          when "min-h-0"
            {"min-height" => "0px"}
          when /^min-h-(.+)$/
            if value = config.spacing[$1]?
              {"min-height" => value}
            end
            # Logical property utilities (ms/me = margin-inline, ps/pe = padding-inline)
          when /^ms-(.+)$/
            if value = config.spacing[$1]?
              {"margin-inline-start" => value}
            end
          when /^me-(.+)$/
            if value = config.spacing[$1]?
              {"margin-inline-end" => value}
            end
          when /^ps-(.+)$/
            if value = config.spacing[$1]?
              {"padding-inline-start" => value}
            end
          when /^pe-(.+)$/
            if value = config.spacing[$1]?
              {"padding-inline-end" => value}
            end
            # Container query utility
          when "container"
            {"container-type" => "inline-size"}
            # Scroll padding/margin (WCAG 2.4.11 Focus Not Obscured)
          when /^scroll-p-(.+)$/
            if value = config.spacing[$1]?
              {"scroll-padding" => value}
            end
          when /^scroll-pt-(.+)$/
            if value = config.spacing[$1]?
              {"scroll-padding-top" => value}
            end
          when /^scroll-pb-(.+)$/
            if value = config.spacing[$1]?
              {"scroll-padding-bottom" => value}
            end
          when /^scroll-m-(.+)$/
            if value = config.spacing[$1]?
              {"scroll-margin" => value}
            end
          when /^scroll-mt-(.+)$/
            if value = config.spacing[$1]?
              {"scroll-margin-top" => value}
            end
          when /^scroll-mb-(.+)$/
            if value = config.spacing[$1]?
              {"scroll-margin-bottom" => value}
            end
            # Touch action (WCAG 2.5.2)
          when "touch-auto"
            {"touch-action" => "auto"}
          when "touch-none"
            {"touch-action" => "none"}
          when "touch-manipulation"
            {"touch-action" => "manipulation"}
            # User select (WCAG 3.3.8)
          when "select-all"
            {"user-select" => "all"}
          when "select-text"
            {"user-select" => "text"}
          when "select-none"
            {"user-select" => "none"}
          when "select-auto"
            {"user-select" => "auto"}
            # Appearance
          when "appearance-none"
            {"appearance" => "none"}
          when "appearance-auto"
            {"appearance" => "auto"}
            # Forced color adjust
          when "forced-color-adjust-auto"
            {"forced-color-adjust" => "auto"}
          when "forced-color-adjust-none"
            {"forced-color-adjust" => "none"}
            # Accent color
          when "accent-auto"
            {"accent-color" => "auto"}
          when /^accent-(.+)$/
            if color = config.get_color($1)
              {"accent-color" => color}
            end
            # Caret color
          when /^caret-(.+)$/
            if color = config.get_color($1)
              {"caret-color" => color}
            end
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
              "margin-left"  => spacing,
              "margin-right" => spacing,
            }
          end
        end

        private def self.parse_margin_y(value : String, config : Config) : Hash(String, String)?
          if spacing = config.spacing[value]?
            {
              "margin-top"    => spacing,
              "margin-bottom" => spacing,
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
              "padding-left"  => spacing,
              "padding-right" => spacing,
            }
          end
        end

        private def self.parse_padding_y(value : String, config : Config) : Hash(String, String)?
          if spacing = config.spacing[value]?
            {
              "padding-top"    => spacing,
              "padding-bottom" => spacing,
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
