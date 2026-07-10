# Single-selection picker with platform-idiomatic wheel / inline / menu styles.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A selection control that lets the user choose from a list of options.
  class Picker < View
    # The available options
    property options : Array(String) = [] of String

    # Currently selected option index
    property selected_index : Int32 = 0

    # Label for the picker
    property label : String = ""

    # Visual style
    property style : PickerStyle = PickerStyle::Menu

    # Callback when selection changes
    property on_change : Proc(Int32, Nil)? = nil

    def initialize(@options : Array(String) = [] of String, @selected_index : Int32 = 0)
    end

    def initialize(@options : Array(String), @selected_index : Int32 = 0, &block : Int32 -> Nil)
      @on_change = block
    end

    # The currently selected option text, or nil if no options
    def selected_option : String?
      if selected_index >= 0 && selected_index < options.size
        options[selected_index]
      end
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
