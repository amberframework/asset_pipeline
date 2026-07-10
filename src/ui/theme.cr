# Material-Design-3-flavoured `ThemeColor` and Apple `LabelRole` types that bridge
# the design-token system to the legacy MD3 CSS emitter and native dynamic colors.

require "./design_tokens"
require "../components/css/tokens/amber_theme"

module UI
  # Material-Design-3-flavoured RGBA bag used by `UI::Theme`.
  #
  # Phase 6.12A added `css_override` so a colour derived from a
  # `UI::DesignTokens::Color` sentinel (e.g. `Color::SYSTEM_ACCENT`) can
  # round-trip its platform-resolved token through the legacy MD3 CSS
  # emitter rather than baking the sentinel's zeroed RGB into a literal
  # `rgba(0, 0, 0, 0.0)`. The default `nil` keeps every existing call
  # site unchanged.
  record ThemeColor,
    r : Float64,
    g : Float64,
    b : Float64,
    a : Float64 = 1.0,
    css_override : String? = nil

  # Semantic Apple label roles. Unlike `ThemeColor` (a baked RGBA value),
  # a `LabelRole` is a symbolic reference that the AppKit / UIKit renderers
  # resolve at render time to the platform's dynamic system color
  # (`NSColor.labelColor` / `UIColor.labelColor` and siblings). These track
  # the current appearance (light / dark) and accessibility Increase
  # Contrast automatically.
  enum LabelRole
    Primary
    Secondary
    Tertiary
    Quaternary
  end

  # `UI::Theme` is now an adapter over `UI::DesignTokens::Tokens`. The public
  # API (the `primary`, `surface`, `font_family`, `corner_radius_*` accessors
  # and the named factories `design_system_default` / `apple_default` /
  # `material_baseline`) is preserved verbatim so existing call sites keep
  # compiling, but every default value is now derived from the canonical
  # `UI::DesignTokens::Tokens.default` palette and scales.
  #
  # The Android renderer continues to read brand decisions through this
  # adapter — its visit-method literal-scrub is deferred to a follow-up phase
  # per `docs/initiative-cross-platform-ui/handoff/phase-01-architect-scope-deferral-2026-05-20.md`.
  class Theme
    # Material Design 3 semantic color roles
    property primary : ThemeColor = ThemeColor.new(r: 0.0, g: 0.478, b: 1.0)
    property on_primary : ThemeColor = ThemeColor.new(r: 1.0, g: 1.0, b: 1.0)
    property primary_container : ThemeColor = ThemeColor.new(r: 0.85, g: 0.92, b: 1.0)
    property on_primary_container : ThemeColor = ThemeColor.new(r: 0.0, g: 0.13, b: 0.34)
    property secondary : ThemeColor = ThemeColor.new(r: 0.39, g: 0.45, b: 0.55)
    property on_secondary : ThemeColor = ThemeColor.new(r: 1.0, g: 1.0, b: 1.0)
    property secondary_container : ThemeColor = ThemeColor.new(r: 0.85, g: 0.9, b: 0.96)
    property on_secondary_container : ThemeColor = ThemeColor.new(r: 0.1, g: 0.16, b: 0.24)
    property tertiary : ThemeColor = ThemeColor.new(r: 0.47, g: 0.38, b: 0.56)
    property on_tertiary : ThemeColor = ThemeColor.new(r: 1.0, g: 1.0, b: 1.0)
    property tertiary_container : ThemeColor = ThemeColor.new(r: 0.92, g: 0.87, b: 1.0)
    property on_tertiary_container : ThemeColor = ThemeColor.new(r: 0.16, g: 0.08, b: 0.25)
    property error : ThemeColor = ThemeColor.new(r: 0.73, g: 0.11, b: 0.11)
    property on_error : ThemeColor = ThemeColor.new(r: 1.0, g: 1.0, b: 1.0)
    property error_container : ThemeColor = ThemeColor.new(r: 0.98, g: 0.87, b: 0.87)
    property on_error_container : ThemeColor = ThemeColor.new(r: 0.25, g: 0.0, b: 0.0)
    property background : ThemeColor = ThemeColor.new(r: 0.98, g: 0.98, b: 1.0)
    property on_background : ThemeColor = ThemeColor.new(r: 0.11, g: 0.11, b: 0.13)
    property surface : ThemeColor = ThemeColor.new(r: 0.98, g: 0.98, b: 1.0)
    property on_surface : ThemeColor = ThemeColor.new(r: 0.11, g: 0.11, b: 0.13)
    property surface_variant : ThemeColor = ThemeColor.new(r: 0.89, g: 0.89, b: 0.93)
    property on_surface_variant : ThemeColor = ThemeColor.new(r: 0.27, g: 0.28, b: 0.31)
    property outline : ThemeColor = ThemeColor.new(r: 0.46, g: 0.47, b: 0.5)
    property outline_variant : ThemeColor = ThemeColor.new(r: 0.77, g: 0.77, b: 0.82)
    property inverse_surface : ThemeColor = ThemeColor.new(r: 0.19, g: 0.19, b: 0.22)
    property inverse_on_surface : ThemeColor = ThemeColor.new(r: 0.94, g: 0.94, b: 0.96)

    # Apple semantic label-color roles. These resolve to dynamic
    # appearance-tracking system colors in the AppKit / UIKit renderers
    # (NSColor.labelColor / UIColor.labelColor and siblings). The stored
    # symbol simply names the role; the renderer owns the lookup.
    property label_primary : LabelRole = LabelRole::Primary
    property label_secondary : LabelRole = LabelRole::Secondary
    property label_tertiary : LabelRole = LabelRole::Tertiary
    property label_quaternary : LabelRole = LabelRole::Quaternary

    # Typography
    property font_family : String = "system"
    property font_size_body : Float64 = 16.0
    property font_size_title : Float64 = 22.0
    property font_size_headline : Float64 = 28.0
    property font_size_caption : Float64 = 12.0

    # Shape
    property corner_radius_small : Float64 = 4.0
    property corner_radius_medium : Float64 = 8.0
    property corner_radius_large : Float64 = 16.0

    def initialize
    end

    # Apple-style theme (HIG defaults). Derived from
    # `UI::DesignTokens::Tokens.default`'s Apple-leaning typography +
    # corner radii; brand colors mirror Apple's stock System Blue / Red /
    # Gray so existing AppKit callers see no visual change.
    def self.apple_default : Theme
      theme = new
      theme.primary = ThemeColor.new(r: 0.0, g: 0.478, b: 1.0) # System Blue
      theme.on_primary = ThemeColor.new(r: 1.0, g: 1.0, b: 1.0)
      theme.secondary = ThemeColor.new(r: 0.34, g: 0.34, b: 0.36) # System Gray
      theme.error = ThemeColor.new(r: 1.0, g: 0.23, b: 0.19)      # System Red
      theme.background = ThemeColor.new(r: 1.0, g: 1.0, b: 1.0)
      theme.on_background = ThemeColor.new(r: 0.0, g: 0.0, b: 0.0)
      theme.surface = ThemeColor.new(r: 0.97, g: 0.97, b: 0.97)
      theme.on_surface = ThemeColor.new(r: 0.0, g: 0.0, b: 0.0)
      theme.outline = ThemeColor.new(r: 0.78, g: 0.78, b: 0.78)
      theme.font_family = "-apple-system"
      theme.font_size_body = 17.0
      theme.corner_radius_small = 6.0
      theme.corner_radius_medium = 10.0
      theme.corner_radius_large = 20.0
      theme
    end

    # Material Design 3 baseline theme. Brand colors are derived from
    # `UI::DesignTokens::Tokens.default.colors_light.brand_*` so a brand
    # override on the unified tokens cascades to this adapter automatically.
    def self.material_baseline : Theme
      from_design_tokens(UI::DesignTokens::Tokens.default,
        font_family: "Roboto",
        body_size: 16.0,
        title_size: 22.0,
        headline_size: 28.0,
        caption_size: 12.0,
        corner_small: 4.0,
        corner_medium: 12.0,
        corner_large: 28.0,
      )
    end

    # Web design-system theme. Brand colors and typography track the
    # canonical `UI::DesignTokens::Tokens.default`.
    def self.amber_default : Theme
      from_design_tokens(UI::DesignTokens::Tokens.default,
        font_family: "var(--ap-font-sans)",
        body_size: 16.0,
        title_size: 22.0,
        headline_size: 34.0,
        caption_size: 12.5,
        corner_small: 8.0,
        corner_medium: 12.0,
        corner_large: 16.0,
      )
    end

    def self.design_system_default : Theme
      amber_default
    end

    def self.amber_tokens : Components::CSS::Tokens::Theme
      design_system_tokens
    end

    def self.design_system_tokens : Components::CSS::Tokens::Theme
      Components::CSS::Tokens::Theme.design_system_default
    end

    # Build a `Theme` from a `UI::DesignTokens::Tokens` instance. Used by the
    # named factories above; also a convenience entry point for downstream
    # apps that want to inject their own branded tokens into the legacy
    # `UI::Theme` adapter without forking it.
    def self.from_design_tokens(
      tokens : UI::DesignTokens::Tokens,
      font_family : String,
      body_size : Float64,
      title_size : Float64,
      headline_size : Float64,
      caption_size : Float64,
      corner_small : Float64,
      corner_medium : Float64,
      corner_large : Float64,
    ) : Theme
      theme = new
      light = tokens.colors_light
      theme.primary = theme_color_from(light.brand_primary)
      theme.on_primary = theme_color_from(light.text_inverse)
      theme.primary_container = theme_color_from(light.brand_accent)
      theme.on_primary_container = theme_color_from(light.text_primary)
      theme.secondary = theme_color_from(light.brand_secondary)
      theme.on_secondary = theme_color_from(light.text_inverse)
      theme.tertiary = theme_color_from(light.brand_accent)
      theme.on_tertiary = theme_color_from(light.text_inverse)
      theme.error = theme_color_from(light.danger)
      theme.background = theme_color_from(light.surface_canvas)
      theme.on_background = theme_color_from(light.text_primary)
      theme.surface = theme_color_from(light.surface_panel)
      theme.on_surface = theme_color_from(light.text_primary)
      theme.surface_variant = theme_color_from(light.surface_sunken)
      theme.on_surface_variant = theme_color_from(light.text_secondary)
      theme.outline = theme_color_from(light.border_strong)
      theme.outline_variant = theme_color_from(light.border_default)
      theme.font_family = font_family
      theme.font_size_body = body_size
      theme.font_size_title = title_size
      theme.font_size_headline = headline_size
      theme.font_size_caption = caption_size
      theme.corner_radius_small = corner_small
      theme.corner_radius_medium = corner_medium
      theme.corner_radius_large = corner_large
      theme
    end

    # Generate CSS custom properties string for web rendering.
    def to_css_custom_properties : String
      String.build do |io|
        io << ":root {\n"
        io << "  --md-sys-color-primary: #{color_to_css(primary)};\n"
        io << "  --md-sys-color-on-primary: #{color_to_css(on_primary)};\n"
        io << "  --md-sys-color-primary-container: #{color_to_css(primary_container)};\n"
        io << "  --md-sys-color-on-primary-container: #{color_to_css(on_primary_container)};\n"
        io << "  --md-sys-color-secondary: #{color_to_css(secondary)};\n"
        io << "  --md-sys-color-on-secondary: #{color_to_css(on_secondary)};\n"
        io << "  --md-sys-color-secondary-container: #{color_to_css(secondary_container)};\n"
        io << "  --md-sys-color-on-secondary-container: #{color_to_css(on_secondary_container)};\n"
        io << "  --md-sys-color-tertiary: #{color_to_css(tertiary)};\n"
        io << "  --md-sys-color-on-tertiary: #{color_to_css(on_tertiary)};\n"
        io << "  --md-sys-color-tertiary-container: #{color_to_css(tertiary_container)};\n"
        io << "  --md-sys-color-on-tertiary-container: #{color_to_css(on_tertiary_container)};\n"
        io << "  --md-sys-color-error: #{color_to_css(error)};\n"
        io << "  --md-sys-color-on-error: #{color_to_css(on_error)};\n"
        io << "  --md-sys-color-error-container: #{color_to_css(error_container)};\n"
        io << "  --md-sys-color-on-error-container: #{color_to_css(on_error_container)};\n"
        io << "  --md-sys-color-background: #{color_to_css(background)};\n"
        io << "  --md-sys-color-on-background: #{color_to_css(on_background)};\n"
        io << "  --md-sys-color-surface: #{color_to_css(surface)};\n"
        io << "  --md-sys-color-on-surface: #{color_to_css(on_surface)};\n"
        io << "  --md-sys-color-surface-variant: #{color_to_css(surface_variant)};\n"
        io << "  --md-sys-color-on-surface-variant: #{color_to_css(on_surface_variant)};\n"
        io << "  --md-sys-color-outline: #{color_to_css(outline)};\n"
        io << "  --md-sys-color-outline-variant: #{color_to_css(outline_variant)};\n"
        io << "  --md-sys-color-inverse-surface: #{color_to_css(inverse_surface)};\n"
        io << "  --md-sys-color-inverse-on-surface: #{color_to_css(inverse_on_surface)};\n"
        io << "  --md-sys-typescale-body-font: #{font_family};\n"
        io << "  --md-sys-typescale-body-size: #{font_size_body}px;\n"
        io << "  --md-sys-typescale-title-size: #{font_size_title}px;\n"
        io << "  --md-sys-typescale-headline-size: #{font_size_headline}px;\n"
        io << "  --md-sys-typescale-caption-size: #{font_size_caption}px;\n"
        io << "  --md-sys-shape-corner-small: #{corner_radius_small}px;\n"
        io << "  --md-sys-shape-corner-medium: #{corner_radius_medium}px;\n"
        io << "  --md-sys-shape-corner-large: #{corner_radius_large}px;\n"
        io << "}\n"
      end
    end

    private def self.theme_color_from(c : UI::DesignTokens::Color) : ThemeColor
      # Phase 6.12A — preserve the platform-resolved CSS token when the
      # source design-token is a sentinel (e.g. SYSTEM_ACCENT). Without
      # this, the legacy MD3 CSS emitter would bake the sentinel's
      # zeroed RGB into a literal `rgba(0, 0, 0, 0.0)`.
      override = c.system_accent? ? c.to_css : nil
      ThemeColor.new(r: c.r, g: c.g, b: c.b, a: c.alpha, css_override: override)
    end

    private def color_to_css(c : ThemeColor) : String
      if over = c.css_override
        return over
      end
      r = (c.r * 255).round.to_i.clamp(0, 255)
      g = (c.g * 255).round.to_i.clamp(0, 255)
      b = (c.b * 255).round.to_i.clamp(0, 255)
      "rgba(#{r}, #{g}, #{b}, #{c.a})"
    end
  end
end
