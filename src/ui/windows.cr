# Window configuration types (`WindowConfiguration`, `WindowSize`, titlebar style)
# describing top-level windows for macOS / iPadOS renderers to materialize.

module UI
  enum WindowTitlebarStyle
    Automatic
    Standard
    Unified
    UnifiedCompact
    Hidden
  end

  record WindowSize,
    width : Float64,
    height : Float64 do
    def clamp(minimum : WindowSize? = nil, maximum : WindowSize? = nil) : WindowSize
      clamped_width = clamp_dimension(width, minimum.try(&.width), maximum.try(&.width))
      clamped_height = clamp_dimension(height, minimum.try(&.height), maximum.try(&.height))
      WindowSize.new(clamped_width, clamped_height)
    end

    private def clamp_dimension(value : Float64, minimum : Float64?, maximum : Float64?) : Float64
      clamped = value
      clamped = minimum if minimum && clamped < minimum
      clamped = maximum if maximum && clamped > maximum
      clamped
    end
  end

  class WindowConfiguration
    property title : String
    property subtitle : String? = nil
    property preferred_size : WindowSize? = nil
    property minimum_size : WindowSize? = nil
    property maximum_size : WindowSize? = nil
    property titlebar_style : WindowTitlebarStyle = WindowTitlebarStyle::Standard
    property shows_titlebar : Bool = true
    property shows_toolbar : Bool = true
    property allows_full_screen : Bool = true
    property resizable : Bool = true

    def initialize(
      @title : String,
      @subtitle : String? = nil,
      @preferred_size : WindowSize? = nil,
      @minimum_size : WindowSize? = nil,
      @maximum_size : WindowSize? = nil,
      @titlebar_style : WindowTitlebarStyle = WindowTitlebarStyle::Standard,
      @shows_titlebar : Bool = true,
      @shows_toolbar : Bool = true,
      @allows_full_screen : Bool = true,
      @resizable : Bool = true
    )
    end

    def display_title : String
      return title if subtitle.nil? || subtitle.not_nil!.empty?
      "#{title} — #{subtitle.not_nil!}"
    end

    def normalized_preferred_size : WindowSize?
      size = preferred_size || minimum_size || maximum_size
      size ? size.clamp(minimum_size, maximum_size) : nil
    end

    def preferred_width : Float64?
      normalized_preferred_size.try(&.width)
    end

    def preferred_height : Float64?
      normalized_preferred_size.try(&.height)
    end

    def size_summary : String?
      size = normalized_preferred_size
      return nil unless size
      "#{size.width.round(1)} x #{size.height.round(1)}"
    end

    def apply : Bool
      UI::Windows.apply(self)
    end
  end

  module Windows
    extend self

    {% if flag?(:macos) || flag?(:ios) %}
      lib LibObjCBridge
        fun ap_window_apply_configuration(title : UInt8*, subtitle : UInt8*, width : Float64, height : Float64, min_width : Float64, min_height : Float64, max_width : Float64, max_height : Float64, titlebar_style : Int64, shows_titlebar : Int32, shows_toolbar : Int32, allows_full_screen : Int32, resizable : Int32) : Int32
      end
    {% end %}

    def configure(
      title : String,
      subtitle : String? = nil,
      preferred_width : Float64? = nil,
      preferred_height : Float64? = nil,
      minimum_width : Float64? = nil,
      minimum_height : Float64? = nil,
      maximum_width : Float64? = nil,
      maximum_height : Float64? = nil,
      titlebar_style : WindowTitlebarStyle = WindowTitlebarStyle::Standard,
      shows_titlebar : Bool = true,
      shows_toolbar : Bool = true,
      allows_full_screen : Bool = true,
      resizable : Bool = true
    ) : WindowConfiguration
      WindowConfiguration.new(
        title: title,
        subtitle: subtitle,
        preferred_size: build_size(preferred_width, preferred_height),
        minimum_size: build_size(minimum_width, minimum_height),
        maximum_size: build_size(maximum_width, maximum_height),
        titlebar_style: titlebar_style,
        shows_titlebar: shows_titlebar,
        shows_toolbar: shows_toolbar,
        allows_full_screen: allows_full_screen,
        resizable: resizable
      )
    end

    def apply(configuration : WindowConfiguration) : Bool
      {% if flag?(:macos) || flag?(:ios) %}
        subtitle_ptr = configuration.subtitle ? configuration.subtitle.not_nil!.to_unsafe : Pointer(UInt8).null
        preferred = configuration.normalized_preferred_size
        minimum = configuration.minimum_size
        maximum = configuration.maximum_size

        LibObjCBridge.ap_window_apply_configuration(
          configuration.title.to_unsafe,
          subtitle_ptr,
          preferred ? preferred.not_nil!.width : 0.0,
          preferred ? preferred.not_nil!.height : 0.0,
          minimum ? minimum.not_nil!.width : 0.0,
          minimum ? minimum.not_nil!.height : 0.0,
          maximum ? maximum.not_nil!.width : 0.0,
          maximum ? maximum.not_nil!.height : 0.0,
          configuration.titlebar_style.value,
          configuration.shows_titlebar ? 1 : 0,
          configuration.shows_toolbar ? 1 : 0,
          configuration.allows_full_screen ? 1 : 0,
          configuration.resizable ? 1 : 0
        ) == 1
      {% else %}
        false
      {% end %}
    end

    private def build_size(width : Float64?, height : Float64?) : WindowSize?
      return nil if width.nil? && height.nil?
      raise ArgumentError.new("window width and height must be provided together") if width.nil? || height.nil?
      WindowSize.new(width.not_nil!, height.not_nil!)
    end
  end
end
