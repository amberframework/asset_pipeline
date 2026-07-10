# Hierarchical disclosure view backed by NSOutlineView / UITableView with indents.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # OutlineView — Hierarchical disclosure view backed by NSOutlineView / UITableView with indents.
  class OutlineView < View
    class Node
      property title : String
      property icon : String?
      property secondary_text : String?
      property children : Array(Node)
      property expanded : Bool
      property is_selected : Bool

      def initialize(
        @title : String,
        @icon : String? = nil,
        @secondary_text : String? = nil,
        @expanded : Bool = true,
        @children : Array(Node) = [] of Node,
        @is_selected : Bool = false
      )
      end

      def add_child(child : Node) : self
        @children << child
        self
      end

      def branch? : Bool
        !@children.empty?
      end
    end

    property roots : Array(Node) = [] of Node
    property row_spacing : Float64 = 4.0
    property indent_width : Float64 = 18.0
    property row_padding : EdgeInsets = EdgeInsets.new(top: 6.0, trailing: 10.0, bottom: 6.0, leading: 10.0)
    property viewport_width : Float64 = 0.0
    property viewport_height : Float64 = 320.0
    property shows_disclosure_glyphs : Bool = true

    def initialize(@roots : Array(Node) = [] of Node)
    end

    def add_root(node : Node) : self
      @roots << node
      self
    end

    def node_count : Int32
      count_nodes(@roots)
    end

    def fallback_view : View
      stack = UI::VStack.new(spacing: row_spacing, alignment: UI::Alignment::Fill)
      roots.each do |node|
        stack << build_node_view(node, 0)
      end

      scroll = UI::ScrollView.new(stack.as(UI::View))
      scroll.scroll_vertical = true
      scroll.scroll_horizontal = false
      scroll.shows_indicators = true
      scroll.frame_width = preferred_frame_width
      scroll.frame_height = preferred_frame_height
      copy_common_properties(scroll)
      scroll.as(UI::View)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    private def count_nodes(nodes : Array(Node)) : Int32
      nodes.sum do |node|
        1 + count_nodes(node.children)
      end.to_i32
    end

    private def build_node_view(node : Node, depth : Int32) : UI::View
      group = UI::VStack.new(spacing: row_spacing, alignment: UI::Alignment::Fill)

      row = UI::HStack.new(spacing: 8.0, alignment: UI::Alignment::Center)
      row.padding = UI::EdgeInsets.new(
        top: row_padding.top,
        trailing: row_padding.trailing,
        bottom: row_padding.bottom,
        leading: row_padding.leading + depth.to_f64 * indent_width
      )
      if node.is_selected
        row.background = UI::Color.new(r: 0.28, g: 0.46, b: 0.84, a: 0.18)
        row.corner_radius = 8.0
      end

      if shows_disclosure_glyphs
        disclosure = if node.branch?
                       UI::Image.new(node.expanded ? "chevron.down" : "chevron.right")
                     else
                       UI::Image.new("chevron.right")
                     end
        disclosure.minimum_width = 12.0
        disclosure.maximum_width = 12.0
        disclosure.minimum_height = 12.0
        disclosure.maximum_height = 12.0
        disclosure.opacity = node.branch? ? 1.0 : 0.0
        row << disclosure.as(UI::View)
      end

      if icon = node.icon
        icon_view = UI::Image.new(icon)
        icon_view.minimum_width = 16.0
        icon_view.maximum_width = 16.0
        icon_view.minimum_height = 16.0
        icon_view.maximum_height = 16.0
        row << icon_view.as(UI::View)
      end

      title = UI::Label.new(node.title)
      title.font = UI::Font.new(size: 13.0, weight: depth.zero? ? :semibold : :regular)
      row << title.as(UI::View)
      row << UI::Spacer.new.as(UI::View)

      if secondary_text = node.secondary_text
        secondary = UI::Label.new(secondary_text)
        secondary.font = UI::Font.new(size: 12.0, weight: :regular)
        secondary.text_color = UI::Color.new(r: 0.50, g: 0.50, b: 0.50)
        row << secondary.as(UI::View)
      end

      group << row.as(UI::View)

      if node.expanded && !node.children.empty?
        node.children.each do |child|
          group << build_node_view(child, depth + 1)
        end
      end

      group.as(UI::View)
    end

    private def preferred_frame_width : Float64
      return viewport_width if viewport_width > 0.0
      return minimum_width.not_nil! if minimum_width
      return maximum_width.not_nil! if maximum_width
      0.0
    end

    private def preferred_frame_height : Float64
      return viewport_height if viewport_height > 0.0
      return minimum_height.not_nil! if minimum_height
      return maximum_height.not_nil! if maximum_height
      320.0
    end

    private def copy_common_properties(target : UI::View) : Nil
      target.id = id
      target.accessibility_label = accessibility_label
      target.padding = padding
      target.background = background
      target.hidden = hidden
      target.opacity = opacity
      target.corner_radius = corner_radius
      target.clip_to_bounds = clip_to_bounds
      target.shadow_radius = shadow_radius
      target.shadow_color = shadow_color
      target.shadow_offset_x = shadow_offset_x
      target.shadow_offset_y = shadow_offset_y
      target.border_width = border_width
      target.border_color = border_color
      target.blur_radius = blur_radius
      target.minimum_width = minimum_width
      target.minimum_height = minimum_height
      target.maximum_width = maximum_width
      target.maximum_height = maximum_height
      target.test_id = test_id
    end
  end
end
