# Button that reveals a drop-down menu of actions.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # MenuButton serves two distinct HIG roles depending on `is_pull_down`:
  #
  # * `is_pull_down: false` (default) -- pop-up button.  Presents a flat list
  #   of mutually exclusive options; updates its face to show the current
  #   selection.  Renders as NSPopUpButton (pullsDown: false) on macOS and as
  #   a UIButton capsule with "chevron.up.chevron.down" on iOS.
  #   HIG: "Use a pop-up button to present a flat list of mutually exclusive
  #   options or states." -- Pop-up buttons / Best practices.
  #
  # * `is_pull_down: true` -- pull-down button.  Presents a menu of ACTIONS
  #   that relate to the button's purpose; does NOT track a selected value.
  #   The button face shows the button's own label (a verb like "Add", "Export",
  #   or an icon) plus a single downward chevron (chevron.down).  No checkmarks
  #   are shown on menu items.  Renders as NSPopUpButton (pullsDown: true) on
  #   macOS and as a UIButton with showsMenuAsPrimaryAction + UIMenu on iOS.
  #   HIG: "Use a pull-down button to present commands or items that are
  #   directly related to the button's action." -- Pull-down buttons / Best
  #   practices.
  class MenuButton < View
    record MenuItem,
      label : String = "",
      icon : String? = nil,
      is_destructive : Bool = false,
      action : Proc(Nil)? = nil

    property label : String
    property icon : String? = nil
    # Zero-based index of the currently selected item (pop-up mode only).
    # In pull-down mode this property is ignored -- no item is pre-selected.
    # Default is 0.
    property selected_index : Int32 = 0
    property items : Array(MenuItem) = [] of MenuItem
    # When true, renders as a pull-down button (action list, no selection
    # tracking).  When false (default), renders as a pop-up button (mutually
    # exclusive selection, face updates to current selection).
    property is_pull_down : Bool = false
    # Optional: promoted visual style for the pull-down button chrome.
    # :default uses the system control bezel (NSPopUpButton default).
    # :prominent renders a filled tinted button (useful in toolbars).
    property button_style : Symbol = :default

    def initialize(@label : String)
    end

    def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, &block : -> Nil)
      @items << MenuItem.new(label: label, icon: icon, is_destructive: is_destructive, action: block)
    end

    def add_item(label : String, icon : String? = nil, is_destructive : Bool = false)
      @items << MenuItem.new(label: label, icon: icon, is_destructive: is_destructive)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
