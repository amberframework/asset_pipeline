# Text field with an associated drop-down list of suggestions.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A hybrid text field + pull-down menu control.
  #
  # Maps to NSComboBox on macOS. On iOS/iPadOS (where HIG states the component
  # is "Not supported"), the UIKit renderer falls back to a UITextField with a
  # trailing chevron.down symbol button — a static representation that conveys
  # the "choose from list OR type freely" shape without native API support.
  #
  # HIG: "A combo box combines a text field with a pull-down button in a single
  # control." — Combo boxes, abstract.
  #
  # HIG: "Populate the field with a meaningful default value from the list.
  # Although the field can be empty by default, it's best when the default
  # value refers to the hidden choices." — Combo boxes, Best practices.
  #
  # HIG: "Use an introductory label to let people know what types of items to
  # expect." — Combo boxes, Best practices.
  class ComboBox < View
    # The current text value typed or selected by the user.
    property value : String

    # The list of preset choices shown in the pull-down menu.
    property options : Array(String)

    # Placeholder text shown when the field is empty.
    property placeholder : String

    # Optional callback invoked with the new value when the user commits
    # a selection or finishes editing. The Proc is retained by CallbackRegistry
    # so the native side can hold a function pointer safely.
    property on_change : Proc(String, Void)?

    # Visual width override (pt). When nil the control uses its intrinsic
    # content width (NSComboBox default, ~150pt).
    property width : Float64?

    def initialize(
      @value : String = "",
      @options : Array(String) = [] of String,
      @placeholder : String = "",
      @on_change : Proc(String, Void)? = nil,
      @width : Float64? = nil
    )
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
