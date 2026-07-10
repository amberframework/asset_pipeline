# Multi-column information list view (macOS NSTableView column layout).
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A Finder-style column browser made of nested item columns.
  #
  # The primitive is intentionally shared and renderer-agnostic for now.
  # Concrete platform renderers can either add a native bridge later or
  # continue using the fallback tree composed here.
  class ColumnView < View
    class Item
      property title : String
      property icon : String?
      property secondary_text : String?
      property children : Array(Item)

      def initialize(
        @title : String,
        @icon : String? = nil,
        @secondary_text : String? = nil,
        @children : Array(Item) = [] of Item
      )
      end

      def add_child(child : Item) : self
        @children << child
        self
      end

      def branch? : Bool
        !@children.empty?
      end
    end

    property items : Array(Item) = [] of Item
    property selected_indexes : Array(Int32) = [] of Int32
    property default_column_width : Float64 = 220.0
    property column_widths : Array(Float64) = [] of Float64
    property column_spacing : Float64 = 12.0
    property row_spacing : Float64 = 4.0
    property row_padding : EdgeInsets = EdgeInsets.new(top: 6.0, trailing: 10.0, bottom: 6.0, leading: 10.0)
    property viewport_width : Float64 = 0.0
    property viewport_height : Float64 = 320.0
    property shows_disclosure_glyphs : Bool = true

    def initialize(@items : Array(Item) = [] of Item)
    end

    def add_item(item : Item) : self
      @items << item
      self
    end

    def column_count : Int32
      count_visible_columns(@items, 0)
    end

    def item_count : Int32
      count_items(@items)
    end

    def selected_path : Array(Int32)
      path = [] of Int32
      current_items = @items
      depth = 0

      loop do
        break if current_items.empty?

        index = selected_index_for(current_items, depth)
        break unless index

        path << index.not_nil!
        selected_item = current_items[index.not_nil!]
        break if selected_item.children.empty?

        current_items = selected_item.children
        depth += 1
      end

      path
    end

    def fallback_view : View
      stack = UI::HStack.new(spacing: column_spacing, alignment: UI::Alignment::Top)
      build_column_chain(stack, @items, 0)

      scroll = UI::ScrollView.new(stack.as(UI::View))
      scroll.scroll_horizontal = true
      scroll.scroll_vertical = false
      scroll.shows_indicators = true
      scroll.frame_width = preferred_frame_width
      scroll.frame_height = preferred_frame_height
      copy_common_properties(scroll)
      scroll.as(UI::View)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    private def build_column_chain(container : UI::HStack, items : Array(Item), depth : Int32) : Nil
      return if items.empty?

      column = build_column_view(items, depth)
      container << column.as(UI::View)

      if selected_item = selected_item_for(items, depth)
        build_column_chain(container, selected_item.children, depth + 1)
      end
    end

    private def build_column_view(items : Array(Item), depth : Int32) : UI::View
      column = UI::VStack.new(spacing: row_spacing, alignment: UI::Alignment::Fill)
      width = column_width_for(depth)
      column.minimum_width = width
      column.maximum_width = width
      column.padding = EdgeInsets.new(top: 8.0, trailing: 8.0, bottom: 8.0, leading: 8.0)

      items.each_with_index do |item, index|
        row = UI::HStack.new(spacing: 8.0, alignment: UI::Alignment::Center)
        row.padding = row_padding

        if index == selected_index_for(items, depth)
          row.background = UI::Color.new(r: 0.28, g: 0.46, b: 0.84, a: 0.18)
          row.corner_radius = 8.0
        end

        if icon = item.icon
          icon_view = UI::Image.new(icon)
          icon_view.minimum_width = 16.0
          icon_view.maximum_width = 16.0
          icon_view.minimum_height = 16.0
          icon_view.maximum_height = 16.0
          row << icon_view.as(UI::View)
        end

        title = UI::Label.new(item.title)
        title.font = UI::Font.new(size: 13.0, weight: index == selected_index_for(items, depth) ? :semibold : :regular)
        row << title.as(UI::View)
        row << UI::Spacer.new.as(UI::View)

        if secondary_text = item.secondary_text
          secondary = UI::Label.new(secondary_text)
          secondary.font = UI::Font.new(size: 12.0, weight: :regular)
          secondary.text_color = UI::Color.new(r: 0.50, g: 0.50, b: 0.50)
          row << secondary.as(UI::View)
        end

        if shows_disclosure_glyphs && item.branch?
          chevron = UI::Image.new("chevron.right")
          chevron.minimum_width = 10.0
          chevron.maximum_width = 10.0
          chevron.minimum_height = 10.0
          chevron.maximum_height = 10.0
          chevron.opacity = 0.72
          row << chevron.as(UI::View)
        end

        column << row.as(UI::View)
      end

      column.as(UI::View)
    end

    private def selected_index_for(items : Array(Item), depth : Int32) : Int32?
      return nil if items.empty?

      index = @selected_indexes[depth]? || 0
      index = 0 if index < 0
      index = items.size - 1 if index >= items.size
      index
    end

    private def selected_item_for(items : Array(Item), depth : Int32) : Item?
      index = selected_index_for(items, depth)
      return nil unless index
      items[index.not_nil!]
    end

    private def count_visible_columns(items : Array(Item), depth : Int32) : Int32
      return 0 if items.empty?

      count = 1
      if selected_item = selected_item_for(items, depth)
        count += count_visible_columns(selected_item.children, depth + 1)
      end
      count
    end

    private def count_items(items : Array(Item)) : Int32
      items.sum do |item|
        1 + count_items(item.children)
      end.to_i32
    end

    private def column_width_for(depth : Int32) : Float64
      @column_widths[depth]? || default_column_width
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
