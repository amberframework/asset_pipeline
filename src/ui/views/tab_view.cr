# Tab-bar container that hosts multiple sibling routes.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A container that switches between views using a tab bar.
  #
  # On iOS: UITabBarController (bottom Liquid Glass tab bar per HIG)
  # On macOS: NSTabViewController with toolbar-style tabs
  # On Android: BottomNavigationView + FragmentContainerView
  # On Web: Tab panel with role="tablist"
  #
  # HIG: "A tab bar lets people navigate between top-level sections of your app."
  # HIG tab-bars Platform considerations (iOS): "A tab bar floats above content at
  # the bottom of the screen. Its items rest on a Liquid Glass background that
  # allows content beneath to peek through."
  class TabView < View
    # A single tab entry
    record Tab,
      label : String,
      icon : String? = nil,
      content : View = Label.new("")

    # The available tabs
    property tabs : Array(Tab) = [] of Tab

    # Currently selected tab index (0-based)
    property selected_index : Int32 = 0

    # Callback when tab selection changes
    property on_change : Proc(Int32, Nil)? = nil

    # Whether to apply Liquid Glass to the tab bar surface.
    # Defaults true per HIG iOS tab-bars guidance. Set false for a plain
    # opaque bar (brand override -- see component doc Customization section).
    property glass_bar : Bool = true

    # Tint color applied to the selected tab icon and label.
    # Defaults to nil, which resolves to the system accent color (system blue
    # via UIColor.tintColor / NSColor.controlAccentColor).
    property selected_tint_color : Color? = nil

    # Position of the tab bar relative to the content area.
    # :bottom -- iOS HIG default; bar floats at the bottom of the screen.
    # :top    -- macOS toolbar-style; bar appears above content.
    property bar_position : Symbol = :bottom

    # Phase 5 v2 — Apple semantic material override. nil = HIG-canonical
    # default :system_resolved (SwiftUI's `.toolbarBackground(.bar, for:)`
    # handles tab-bar chrome; AppleSemantic does NOT suppress that). To
    # apply a custom material, set this to a non-default semantic role.
    property material_semantic : Symbol? = nil

    def initialize(@tabs : Array(Tab) = [] of Tab, @selected_index : Int32 = 0)
    end

    def initialize(@tabs : Array(Tab), @selected_index : Int32 = 0, &block : Int32 -> Nil)
      @on_change = block
    end

    # The currently selected tab's content view
    def current_content : View?
      if selected_index >= 0 && selected_index < tabs.size
        tabs[selected_index].content
      end
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
