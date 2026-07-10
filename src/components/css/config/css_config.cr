require "../tokens/design_system_theme"

module Components
  module CSS
    # Configuration for the utility-first CSS system
    class Config
      # Semantic design-system tokens. The storage name remains as an alpha
      # compatibility detail; use `design_system_theme` in new code.
      property amber_theme : Components::CSS::Tokens::Theme

      # Color palette
      property colors : Hash(String, String | Hash(String, String))

      # Spacing scale
      property spacing : Hash(String, String)

      # Font families
      property fonts : Hash(String, String)

      # Breakpoints for responsive design
      property screens : Hash(String, String)

      # Font sizes
      property font_sizes : Hash(String, String)

      # Line heights
      property line_heights : Hash(String, String)

      # Letter spacing
      property letter_spacing : Hash(String, String)

      # Border radius values
      property border_radius : Hash(String, String)

      # Box shadows
      property shadows : Hash(String, String)

      # Transitions
      property transitions : Hash(String, String)

      # Z-index scale
      property z_index : Hash(String, String)

      # Opacity scale
      property opacity : Hash(String, String)

      # Container query breakpoints
      property containers : Hash(String, String)

      # Custom extensions
      property extend : Hash(String, Hash(String, String))

      def initialize
        @amber_theme = Components::CSS::Tokens::Theme.design_system_default
        @colors = default_colors
        @spacing = default_spacing
        @fonts = default_fonts
        @screens = default_screens
        @font_sizes = default_font_sizes
        @line_heights = default_line_heights
        @letter_spacing = default_letter_spacing
        @border_radius = default_border_radius
        @shadows = default_shadows
        @transitions = default_transitions
        @z_index = default_z_index
        @opacity = default_opacity
        @containers = default_containers
        @extend = {} of String => Hash(String, String)
        apply_design_system_theme_colors
      end

      def use_amber_theme(theme : Components::CSS::Tokens::Theme) : self
        use_design_system_theme(theme)
      end

      def design_system_theme : Components::CSS::Tokens::Theme
        @amber_theme
      end

      def design_system_theme=(theme : Components::CSS::Tokens::Theme)
        @amber_theme = theme
        apply_design_system_theme_colors
      end

      def use_design_system_theme(theme : Components::CSS::Tokens::Theme) : self
        self.design_system_theme = theme
        self
      end

      # Default color palette
      private def default_colors
        {
          "transparent" => "transparent",
          "current"     => "currentColor",
          "black"       => "oklch(0 0 0)",
          "white"       => "oklch(1 0 0)",

          # Gray scale
          "gray" => {
            "50"  => "oklch(0.985 0.002 247.839)",
            "100" => "oklch(0.967 0.003 264.542)",
            "200" => "oklch(0.928 0.006 264.531)",
            "300" => "oklch(0.872 0.010 258.338)",
            "400" => "oklch(0.707 0.022 261.325)",
            "500" => "oklch(0.551 0.027 264.364)",
            "600" => "oklch(0.446 0.030 256.802)",
            "700" => "oklch(0.373 0.034 259.733)",
            "800" => "oklch(0.278 0.033 256.848)",
            "900" => "oklch(0.210 0.034 264.665)",
            "950" => "oklch(0.130 0.028 261.692)",
          },

          # Primary colors
          "red" => {
            "50"  => "oklch(0.971 0.013 17.380)",
            "100" => "oklch(0.936 0.032 17.717)",
            "200" => "oklch(0.885 0.062 18.334)",
            "300" => "oklch(0.808 0.114 19.571)",
            "400" => "oklch(0.704 0.191 22.216)",
            "500" => "oklch(0.637 0.237 25.331)",
            "600" => "oklch(0.577 0.245 27.325)",
            "700" => "oklch(0.505 0.213 27.518)",
            "800" => "oklch(0.444 0.177 26.899)",
            "900" => "oklch(0.396 0.141 25.723)",
            "950" => "oklch(0.258 0.092 26.042)",
          },

          "blue" => {
            "50"  => "oklch(0.970 0.014 254.604)",
            "100" => "oklch(0.932 0.032 255.585)",
            "200" => "oklch(0.882 0.059 254.128)",
            "300" => "oklch(0.809 0.105 251.813)",
            "400" => "oklch(0.707 0.165 254.624)",
            "500" => "oklch(0.623 0.214 259.815)",
            "600" => "oklch(0.546 0.245 262.881)",
            "700" => "oklch(0.488 0.243 264.376)",
            "800" => "oklch(0.424 0.199 265.638)",
            "900" => "oklch(0.379 0.146 265.522)",
            "950" => "oklch(0.282 0.091 267.935)",
          },

          "green" => {
            "50"  => "oklch(0.982 0.018 155.826)",
            "100" => "oklch(0.962 0.044 156.743)",
            "200" => "oklch(0.925 0.084 155.995)",
            "300" => "oklch(0.871 0.150 154.449)",
            "400" => "oklch(0.792 0.209 151.711)",
            "500" => "oklch(0.723 0.219 149.579)",
            "600" => "oklch(0.627 0.194 149.214)",
            "700" => "oklch(0.527 0.154 150.069)",
            "800" => "oklch(0.448 0.119 151.328)",
            "900" => "oklch(0.393 0.095 152.535)",
            "950" => "oklch(0.266 0.065 152.934)",
          },
        } of String => String | Hash(String, String)
      end

      # Default spacing scale
      private def default_spacing
        {
          "px"  => "1px",
          "0"   => "0px",
          "0.5" => "0.125rem",
          "1"   => "0.25rem",
          "1.5" => "0.375rem",
          "2"   => "0.5rem",
          "2.5" => "0.625rem",
          "3"   => "0.75rem",
          "3.5" => "0.875rem",
          "4"   => "1rem",
          "5"   => "1.25rem",
          "6"   => "1.5rem",
          "7"   => "1.75rem",
          "8"   => "2rem",
          "9"   => "2.25rem",
          "10"  => "2.5rem",
          "11"  => "2.75rem",
          "12"  => "3rem",
          "14"  => "3.5rem",
          "16"  => "4rem",
          "20"  => "5rem",
          "24"  => "6rem",
          "28"  => "7rem",
          "32"  => "8rem",
          "36"  => "9rem",
          "40"  => "10rem",
          "44"  => "11rem",
          "48"  => "12rem",
          "52"  => "13rem",
          "56"  => "14rem",
          "60"  => "15rem",
          "64"  => "16rem",
          "72"  => "18rem",
          "80"  => "20rem",
          "96"  => "24rem",
        }
      end

      # Default font families
      private def default_fonts
        {
          "sans"    => "#{token_var("font-sans")}, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, \"Helvetica Neue\", Arial, sans-serif",
          "display" => "#{token_var("font-display")}, Georgia, ui-serif, serif",
          "serif"   => "ui-serif, Georgia, Cambria, \"Times New Roman\", Times, serif",
          "mono"    => "#{token_var("font-mono")}, ui-monospace, SFMono-Regular, \"SF Mono\", Consolas, \"Liberation Mono\", Menlo, Courier, monospace",
        }
      end

      # Default breakpoints
      private def default_screens
        {
          "sm"  => "640px",
          "md"  => "768px",
          "lg"  => "1024px",
          "xl"  => "1280px",
          "2xl" => "1536px",
        }
      end

      # Default font sizes
      private def default_font_sizes
        {
          "xs"   => "0.75rem",
          "sm"   => "0.875rem",
          "base" => "1rem",
          "lg"   => "1.125rem",
          "xl"   => "1.25rem",
          "2xl"  => "1.5rem",
          "3xl"  => "1.875rem",
          "4xl"  => "2.25rem",
          "5xl"  => "3rem",
          "6xl"  => "3.75rem",
          "7xl"  => "4.5rem",
          "8xl"  => "6rem",
          "9xl"  => "8rem",
        }
      end

      # Default line heights
      private def default_line_heights
        {
          "none"    => "1",
          "tight"   => "1.25",
          "snug"    => "1.375",
          "normal"  => "1.5",
          "relaxed" => "1.625",
          "loose"   => "2",
          "3"       => ".75rem",
          "4"       => "1rem",
          "5"       => "1.25rem",
          "6"       => "1.5rem",
          "7"       => "1.75rem",
          "8"       => "2rem",
          "9"       => "2.25rem",
          "10"      => "2.5rem",
        }
      end

      # Default letter spacing
      private def default_letter_spacing
        {
          "tighter" => "0em",
          "tight"   => "0em",
          "normal"  => "0em",
          "wide"    => "0em",
          "wider"   => "0em",
          "widest"  => "0em",
        }
      end

      # Default border radius
      private def default_border_radius
        {
          "none"    => "0px",
          "sm"      => "0.125rem",
          "DEFAULT" => "0.25rem",
          "md"      => "0.375rem",
          "lg"      => "0.5rem",
          "xl"      => "0.75rem",
          "2xl"     => "1rem",
          "3xl"     => "1.5rem",
          "full"    => "9999px",
        }
      end

      # Default shadows
      private def default_shadows
        {
          "sm"      => "0 1px 2px 0 rgb(0 0 0 / 0.05)",
          "DEFAULT" => "0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)",
          "md"      => "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)",
          "lg"      => "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)",
          "xl"      => "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)",
          "2xl"     => "0 25px 50px -12px rgb(0 0 0 / 0.25)",
          "inner"   => "inset 0 2px 4px 0 rgb(0 0 0 / 0.05)",
          "none"    => "none",
        }
      end

      # Default transitions
      private def default_transitions
        {
          "none"      => "none",
          "all"       => "all 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "DEFAULT"   => "color 150ms cubic-bezier(0.4, 0, 0.2, 1), background-color 150ms cubic-bezier(0.4, 0, 0.2, 1), border-color 150ms cubic-bezier(0.4, 0, 0.2, 1), text-decoration-color 150ms cubic-bezier(0.4, 0, 0.2, 1), fill 150ms cubic-bezier(0.4, 0, 0.2, 1), stroke 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "colors"    => "color 150ms cubic-bezier(0.4, 0, 0.2, 1), background-color 150ms cubic-bezier(0.4, 0, 0.2, 1), border-color 150ms cubic-bezier(0.4, 0, 0.2, 1), text-decoration-color 150ms cubic-bezier(0.4, 0, 0.2, 1), fill 150ms cubic-bezier(0.4, 0, 0.2, 1), stroke 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "opacity"   => "opacity 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "shadow"    => "box-shadow 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "transform" => "transform 150ms cubic-bezier(0.4, 0, 0.2, 1)",
        }
      end

      # Default z-index
      private def default_z_index
        {
          "auto" => "auto",
          "0"    => "0",
          "10"   => "10",
          "20"   => "20",
          "30"   => "30",
          "40"   => "40",
          "50"   => "50",
        }
      end

      # Default opacity
      private def default_opacity
        {
          "0"   => "0",
          "5"   => "0.05",
          "10"  => "0.1",
          "20"  => "0.2",
          "25"  => "0.25",
          "30"  => "0.3",
          "40"  => "0.4",
          "50"  => "0.5",
          "60"  => "0.6",
          "70"  => "0.7",
          "75"  => "0.75",
          "80"  => "0.8",
          "90"  => "0.9",
          "95"  => "0.95",
          "100" => "1",
        }
      end

      # Default container query breakpoints
      private def default_containers
        {
          "sm"  => "640px",
          "md"  => "768px",
          "lg"  => "1024px",
          "xl"  => "1280px",
          "2xl" => "1536px",
        }
      end

      # Get a color value (handles nested hashes)
      def get_color(name : String) : String?
        parts = name.split("-")

        if parts.size == 1
          # Direct color like "black" or "white"
          value = @colors[parts[0]]?
          return value if value.is_a?(String)
        elsif parts.size == 2
          # Nested color like "gray-500"
          color_group = @colors[parts[0]]?
          if color_group.is_a?(Hash)
            return color_group[parts[1]]?
          end
        end

        nil
      end

      private def apply_design_system_theme_colors
        @colors["brand"] = {
          "primary"   => token_var("color-brand-primary"),
          "secondary" => token_var("color-brand-secondary"),
          "accent"    => token_var("color-brand-accent"),
          "hover"     => token_var("color-brand-primary-hover"),
          "active"    => token_var("color-brand-primary-active"),
        }

        @colors["surface"] = {
          "canvas"   => token_var("color-surface-canvas"),
          "panel"    => token_var("color-surface-panel"),
          "elevated" => token_var("color-surface-elevated"),
          "sunken"   => token_var("color-surface-sunken"),
        }

        %w[success warning danger info].each do |intent|
          @colors[intent] = {
            "indicator" => token_var("color-#{intent}-indicator"),
            "subtle"    => token_var("color-#{intent}-bg"),
            "hover"     => token_var("color-#{intent}-bg-hover"),
            "border"    => token_var("color-#{intent}-border"),
            "strong"    => token_var("color-#{intent}-indicator"),
            "text"      => token_var("color-#{intent}-text"),
            "focus"     => token_var("color-#{intent}-focus-ring"),
          }
        end

        @colors["primary"] = token_var("color-text-primary")
        @colors["secondary"] = token_var("color-text-secondary")
        @colors["muted"] = token_var("color-text-muted")
        @colors["inverse"] = token_var("color-text-inverse")
        @colors["link"] = token_var("color-text-link")
        @colors["focus"] = token_var("color-border-focus")
        @colors["border"] = token_var("color-border-default")
      end

      private def token_var(name : String) : String
        "var(--ap-#{name})"
      end

      # Generate CSS custom property declarations for all design tokens.
      # Returns a multi-line string of custom property declarations (without
      # the :root {} wrapper -- the caller adds that).
      def to_custom_properties : String
        String.build do |str|
          # --- Colors ---
          @colors.each do |name, value|
            case value
            when String
              str << "--color-#{name}: #{value};\n"
            when Hash
              value.each do |shade, color_value|
                str << "--color-#{name}-#{shade}: #{color_value};\n"
              end
            end
          end

          # --- Spacing ---
          @spacing.each do |key, value|
            str << "--spacing-#{key}: #{value};\n"
          end

          # --- Font families ---
          @fonts.each do |key, value|
            str << "--font-#{key}: #{value};\n"
          end

          # --- Font sizes ---
          @font_sizes.each do |key, value|
            str << "--font-size-#{key}: #{value};\n"
          end

          # --- Line heights ---
          @line_heights.each do |key, value|
            str << "--line-height-#{key}: #{value};\n"
          end

          # --- Letter spacing ---
          @letter_spacing.each do |key, value|
            str << "--letter-spacing-#{key}: #{value};\n"
          end

          # --- Border radius ---
          @border_radius.each do |key, value|
            if key == "DEFAULT"
              str << "--radius: #{value};\n"
            else
              str << "--radius-#{key}: #{value};\n"
            end
          end

          # --- Shadows ---
          @shadows.each do |key, value|
            if key == "DEFAULT"
              str << "--shadow: #{value};\n"
            else
              str << "--shadow-#{key}: #{value};\n"
            end
          end

          # --- Transitions ---
          @transitions.each do |key, value|
            if key == "DEFAULT"
              str << "--transition: #{value};\n"
            else
              str << "--transition-#{key}: #{value};\n"
            end
          end

          # --- Z-index ---
          @z_index.each do |key, value|
            str << "--z-#{key}: #{value};\n"
          end

          # --- Opacity ---
          @opacity.each do |key, value|
            str << "--opacity-#{key}: #{value};\n"
          end

          # --- Design-system semantic tokens ---
          str << @amber_theme.to_css_variables(:light)
        end
      end

      def to_dark_custom_properties : String
        @amber_theme.to_css_variables(:dark)
      end

      # Merge with another config
      def merge(other : Config) : Config
        result = Config.new

        result.colors = @colors.merge(other.colors)
        result.spacing = @spacing.merge(other.spacing)
        result.fonts = @fonts.merge(other.fonts)
        result.screens = @screens.merge(other.screens)
        result.font_sizes = @font_sizes.merge(other.font_sizes)
        result.line_heights = @line_heights.merge(other.line_heights)
        result.letter_spacing = @letter_spacing.merge(other.letter_spacing)
        result.border_radius = @border_radius.merge(other.border_radius)
        result.shadows = @shadows.merge(other.shadows)
        result.transitions = @transitions.merge(other.transitions)
        result.z_index = @z_index.merge(other.z_index)
        result.opacity = @opacity.merge(other.opacity)
        result.containers = @containers.merge(other.containers)
        result.extend = @extend.merge(other.extend)

        result
      end
    end
  end
end
