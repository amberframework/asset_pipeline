# Public entry point for process-scoped bundled font registration.

require "./native/swiftkit_bridge"

module UI
  # Registers a bundled font file before constructing views that use its
  # PostScript family name through UI::Font.
  module FontRegistry
    # Register one bundled .ttf or .otf file for the current process.
    # Returns false when the file cannot be registered or on non-macOS builds.
    def self.register_bundled_font_file(path : String) : Bool
      {% if flag?(:macos) %}
        LibSwiftKitBridge.apsk_register_font(path.to_unsafe)
      {% else %}
        false
      {% end %}
    end
  end
end
