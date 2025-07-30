module Components
  module CSS
    # Configuration for the utility-first CSS system
    class Config
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
      
      # Custom extensions
      property extend : Hash(String, Hash(String, String))
      
      def initialize
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
        @extend = {} of String => Hash(String, String)
      end
      
      # Default color palette
      private def default_colors
        {
          "transparent" => "transparent",
          "current" => "currentColor",
          "black" => "#000000",
          "white" => "#ffffff",
          
          # Gray scale
          "gray" => {
            "50" => "#f9fafb",
            "100" => "#f3f4f6",
            "200" => "#e5e7eb",
            "300" => "#d1d5db",
            "400" => "#9ca3af",
            "500" => "#6b7280",
            "600" => "#4b5563",
            "700" => "#374151",
            "800" => "#1f2937",
            "900" => "#111827",
            "950" => "#030712",
          },
          
          # Primary colors
          "red" => {
            "50" => "#fef2f2",
            "100" => "#fee2e2",
            "200" => "#fecaca",
            "300" => "#fca5a5",
            "400" => "#f87171",
            "500" => "#ef4444",
            "600" => "#dc2626",
            "700" => "#b91c1c",
            "800" => "#991b1b",
            "900" => "#7f1d1d",
            "950" => "#450a0a",
          },
          
          "blue" => {
            "50" => "#eff6ff",
            "100" => "#dbeafe",
            "200" => "#bfdbfe",
            "300" => "#93c5fd",
            "400" => "#60a5fa",
            "500" => "#3b82f6",
            "600" => "#2563eb",
            "700" => "#1d4ed8",
            "800" => "#1e40af",
            "900" => "#1e3a8a",
            "950" => "#172554",
          },
          
          "green" => {
            "50" => "#f0fdf4",
            "100" => "#dcfce7",
            "200" => "#bbf7d0",
            "300" => "#86efac",
            "400" => "#4ade80",
            "500" => "#22c55e",
            "600" => "#16a34a",
            "700" => "#15803d",
            "800" => "#166534",
            "900" => "#14532d",
            "950" => "#052e16",
          },
        } of String => String | Hash(String, String)
      end
      
      # Default spacing scale
      private def default_spacing
        {
          "px" => "1px",
          "0" => "0px",
          "0.5" => "0.125rem",
          "1" => "0.25rem",
          "1.5" => "0.375rem",
          "2" => "0.5rem",
          "2.5" => "0.625rem",
          "3" => "0.75rem",
          "3.5" => "0.875rem",
          "4" => "1rem",
          "5" => "1.25rem",
          "6" => "1.5rem",
          "7" => "1.75rem",
          "8" => "2rem",
          "9" => "2.25rem",
          "10" => "2.5rem",
          "11" => "2.75rem",
          "12" => "3rem",
          "14" => "3.5rem",
          "16" => "4rem",
          "20" => "5rem",
          "24" => "6rem",
          "28" => "7rem",
          "32" => "8rem",
          "36" => "9rem",
          "40" => "10rem",
          "44" => "11rem",
          "48" => "12rem",
          "52" => "13rem",
          "56" => "14rem",
          "60" => "15rem",
          "64" => "16rem",
          "72" => "18rem",
          "80" => "20rem",
          "96" => "24rem",
        }
      end
      
      # Default font families
      private def default_fonts
        {
          "sans" => "ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, \"Helvetica Neue\", Arial, \"Noto Sans\", sans-serif, \"Apple Color Emoji\", \"Segoe UI Emoji\", \"Segoe UI Symbol\", \"Noto Color Emoji\"",
          "serif" => "ui-serif, Georgia, Cambria, \"Times New Roman\", Times, serif",
          "mono" => "ui-monospace, SFMono-Regular, \"SF Mono\", Consolas, \"Liberation Mono\", Menlo, Courier, monospace",
        }
      end
      
      # Default breakpoints
      private def default_screens
        {
          "sm" => "640px",
          "md" => "768px",
          "lg" => "1024px",
          "xl" => "1280px",
          "2xl" => "1536px",
        }
      end
      
      # Default font sizes
      private def default_font_sizes
        {
          "xs" => "0.75rem",
          "sm" => "0.875rem",
          "base" => "1rem",
          "lg" => "1.125rem",
          "xl" => "1.25rem",
          "2xl" => "1.5rem",
          "3xl" => "1.875rem",
          "4xl" => "2.25rem",
          "5xl" => "3rem",
          "6xl" => "3.75rem",
          "7xl" => "4.5rem",
          "8xl" => "6rem",
          "9xl" => "8rem",
        }
      end
      
      # Default line heights
      private def default_line_heights
        {
          "none" => "1",
          "tight" => "1.25",
          "snug" => "1.375",
          "normal" => "1.5",
          "relaxed" => "1.625",
          "loose" => "2",
          "3" => ".75rem",
          "4" => "1rem",
          "5" => "1.25rem",
          "6" => "1.5rem",
          "7" => "1.75rem",
          "8" => "2rem",
          "9" => "2.25rem",
          "10" => "2.5rem",
        }
      end
      
      # Default letter spacing
      private def default_letter_spacing
        {
          "tighter" => "-0.05em",
          "tight" => "-0.025em",
          "normal" => "0em",
          "wide" => "0.025em",
          "wider" => "0.05em",
          "widest" => "0.1em",
        }
      end
      
      # Default border radius
      private def default_border_radius
        {
          "none" => "0px",
          "sm" => "0.125rem",
          "DEFAULT" => "0.25rem",
          "md" => "0.375rem",
          "lg" => "0.5rem",
          "xl" => "0.75rem",
          "2xl" => "1rem",
          "3xl" => "1.5rem",
          "full" => "9999px",
        }
      end
      
      # Default shadows
      private def default_shadows
        {
          "sm" => "0 1px 2px 0 rgb(0 0 0 / 0.05)",
          "DEFAULT" => "0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)",
          "md" => "0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)",
          "lg" => "0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)",
          "xl" => "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)",
          "2xl" => "0 25px 50px -12px rgb(0 0 0 / 0.25)",
          "inner" => "inset 0 2px 4px 0 rgb(0 0 0 / 0.05)",
          "none" => "none",
        }
      end
      
      # Default transitions
      private def default_transitions
        {
          "none" => "none",
          "all" => "all 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "DEFAULT" => "color 150ms cubic-bezier(0.4, 0, 0.2, 1), background-color 150ms cubic-bezier(0.4, 0, 0.2, 1), border-color 150ms cubic-bezier(0.4, 0, 0.2, 1), text-decoration-color 150ms cubic-bezier(0.4, 0, 0.2, 1), fill 150ms cubic-bezier(0.4, 0, 0.2, 1), stroke 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "colors" => "color 150ms cubic-bezier(0.4, 0, 0.2, 1), background-color 150ms cubic-bezier(0.4, 0, 0.2, 1), border-color 150ms cubic-bezier(0.4, 0, 0.2, 1), text-decoration-color 150ms cubic-bezier(0.4, 0, 0.2, 1), fill 150ms cubic-bezier(0.4, 0, 0.2, 1), stroke 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "opacity" => "opacity 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "shadow" => "box-shadow 150ms cubic-bezier(0.4, 0, 0.2, 1)",
          "transform" => "transform 150ms cubic-bezier(0.4, 0, 0.2, 1)",
        }
      end
      
      # Default z-index
      private def default_z_index
        {
          "auto" => "auto",
          "0" => "0",
          "10" => "10",
          "20" => "20",
          "30" => "30",
          "40" => "40",
          "50" => "50",
        }
      end
      
      # Default opacity
      private def default_opacity
        {
          "0" => "0",
          "5" => "0.05",
          "10" => "0.1",
          "20" => "0.2",
          "25" => "0.25",
          "30" => "0.3",
          "40" => "0.4",
          "50" => "0.5",
          "60" => "0.6",
          "70" => "0.7",
          "75" => "0.75",
          "80" => "0.8",
          "90" => "0.9",
          "95" => "0.95",
          "100" => "1",
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
        result.extend = @extend.merge(other.extend)
        
        result
      end
    end
  end
end