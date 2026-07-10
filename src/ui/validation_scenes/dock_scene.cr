# DockScene — Phase 6 validation builder. Produces a UI::View tree representing
# a macOS-style dock strip of icon buttons for renderer captures.

require "../view"
require "../views/label"
require "../views/image"
require "../views/button"
require "../views/divider"
require "../views/hstack"
require "../views/vstack"
require "../views/spacer"

module UI
  module ValidationScenes
    # DockScene -- macOS dock bar scene.
    #
    # Plain Crystal class (NOT a UI::View subclass). Call `.build` to get a
    # UI::View tree that the renderer can walk.
    #
    # Renders a macOS-style dock bar at the bottom center of the capture
    # frame with a focal dock-menu popped open above the Amber icon.
    #
    # Layout:
    #   - Background: cream/ember gradient filling the full frame
    #     (approximated via background color; real gradient comes from
    #     HIG_BACKDROP_PATH in the capture harness).
    #   - Dock bar: horizontal strip with 5 app icon placeholders
    #     (Calendar, Mail, Safari, Amber, Settings) -- Amber icon
    #     highlighted with Amber gold border.
    #   - Dock menu: the focal component positioned above the Amber icon
    #     with a small downward arrow tail indicating the source icon.
    #
    # focal_position values:
    #   :above_dock_icon  -- focal (the dock menu surface) floats above
    #                        the Amber dock icon, centered on that icon.
    #
    # Note: DockScene is macOS-only per HIG. The dock-menus slug's iOS
    # capture uses a "Not supported on iOS" placeholder. The scene
    # renders on both platforms via the UI::View tree, but the iOS
    # renderer will produce a simplified flat layout.
    #
    # Example:
    #   scene = DockScene.new(focal: dock_menu, focal_position: :above_dock_icon)
    #   view_tree = scene.build
    #   renderer.render(view_tree)

    class DockScene
      property focal : View
      property focal_position : Symbol  # :above_dock_icon

      # Amber icon index in the dock (0-based). Default 3 (4th slot).
      property amber_icon_index : Int32 = 3

      def initialize(@focal : View, @focal_position : Symbol = :above_dock_icon)
      end

      # Build the full scene tree. Returns a UI::View tree ready for rendering.
      def build : View
        # ----------------------------------------------------------------
        # DOCK BAR -- 5 icon slots
        # ----------------------------------------------------------------
        dock_icons = [
          {"calendar",  "Calendar"},
          {"envelope",  "Mail"},
          {"safari",    "Safari"},
          {"sparkles",  "Amber"},    # 4th slot -- Amber (sparkles as Amber glyph)
          {"gearshape", "Settings"},
        ]

        dock_bar = HStack.new(spacing: 13.0)
        dock_bar.padding = EdgeInsets.new(top: 8.0, trailing: 21.0, bottom: 8.0, leading: 21.0)
        dock_bar.corner_radius = 16.0
        # Light frosted dock tray (approximation -- real Liquid Glass via backdrop)
        dock_bar.background = Color.new(r: 1.0, g: 1.0, b: 1.0, a: 0.55)
        dock_bar.accessibility_label = "Dock bar"

        dock_icons.each_with_index do |(symbol, label_text), idx|
          icon_col = VStack.new(spacing: 4.0)

          # Use UI::Image so the AppKit renderer calls imageWithSystemSymbolName:
          # and the UIKit renderer calls systemImageNamed: -- both resolve the SF
          # Symbol glyph from the system symbol font rather than rendering as text.
          icon_img = Image.new(symbol)
          icon_img.content_mode = ContentMode::Fit
          icon_img.minimum_width = 48.0
          icon_img.minimum_height = 48.0
          icon_img.accessibility_label = "#{label_text} dock icon"

          # Amber icon slot: subtle gold border to show it is the active app.
          if idx == @amber_icon_index
            icon_img.border_color = Color.new(r: 1.0, g: 0.678, b: 0.2)  # Amber gold
            icon_img.border_width = 2.0
            icon_img.corner_radius = 10.0
            icon_img.padding = EdgeInsets.new(top: 4.0, trailing: 4.0, bottom: 4.0, leading: 4.0)
          end

          name_lbl = Label.new(label_text)
          name_lbl.font = Font.new(size: 10.0, weight: :regular)
          name_lbl.accessibility_label = "#{label_text} dock label"

          icon_col << icon_img.as(View)
          icon_col << name_lbl.as(View)
          dock_bar << icon_col.as(View)
        end

        # ----------------------------------------------------------------
        # FOCAL PLACEMENT -- menu above Amber icon
        # ----------------------------------------------------------------
        # The focal (dock menu surface) floats above the dock bar, centered
        # on the Amber icon's horizontal position.
        #
        # Tail arrow: small downward-pointing triangle indicating the menu
        # is anchored to the dock icon below.
        tail_arrow = Label.new("\u25BC")  # BLACK DOWN-POINTING TRIANGLE
        tail_arrow.font = Font.new(size: 12.0, weight: :regular)
        tail_arrow.text_color = Color.new(r: 0.55, g: 0.55, b: 0.55)
        tail_arrow.accessibility_label = "Menu anchor tail"

        # Focal menu + tail stacked vertically.
        # Transparent background so the focal_column VStack does not produce
        # an opaque white/dark fill artifact above the dock bar. The renderer's
        # VStack visit applies a solid white/dark fill when background is nil
        # (the dark-mode legibility fix); setting alpha=0 opts this VStack out.
        focal_column = VStack.new(spacing: 0.0)
        focal_column.background = Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.0)
        focal_column << @focal
        focal_column << tail_arrow.as(View)

        # Horizontal anchor: spacers push focal column to center-right (above Amber slot).
        # Amber is 4th of 5 icons: left spacer = 3 units, right spacer = 1 unit.
        focal_anchor = HStack.new(spacing: 0.0)
        focal_anchor << Spacer.new.as(View)
        focal_anchor << Spacer.new.as(View)
        focal_anchor << Spacer.new.as(View)
        focal_anchor << focal_column.as(View)
        focal_anchor << Spacer.new.as(View)
        focal_anchor.accessibility_label = "Focal menu anchor row"

        # Full scene: spacer (desktop area) -> focal anchor -> dock bar.
        # Pinned to 1200x900 so it fills the capture canvas edge-to-edge.
        # Background color: Amber cream (#FAF6F0) in light mode.
        # Real wallpaper gradient is supplied via HIG_BACKDROP_PATH.
        scene = VStack.new(spacing: 0.0)
        scene.background = Color.new(r: 0.98, g: 0.965, b: 0.941)  # Amber cream fallback
        scene.minimum_width = 1200.0
        scene.maximum_width = 1200.0
        scene.minimum_height = 900.0
        scene.maximum_height = 900.0
        scene << Spacer.new.as(View)
        scene << focal_anchor.as(View)
        scene << dock_bar.as(View)
        scene.padding = EdgeInsets.new(top: 34.0, trailing: 34.0, bottom: 21.0, leading: 34.0)
        scene.accessibility_label = "Dock scene"

        scene.as(View)
      end
    end
  end
end
