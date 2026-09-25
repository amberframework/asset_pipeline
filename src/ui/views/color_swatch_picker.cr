# Single-selection picker specialized for a named color palette.

require "./picker"

module UI
  # Color choice control that reuses Picker's selected-index callback contract.
  class ColorSwatchPicker < Picker
    property list_of_color_swatches : Array(ColorSwatch)
    property appearance : ColorSwatchPickerStyle = ColorSwatchPickerStyle::SwatchButton

    def initialize(
      @list_of_color_swatches : Array(ColorSwatch),
      selected_index : Int32 = 0,
      @appearance : ColorSwatchPickerStyle = ColorSwatchPickerStyle::SwatchButton,
      label : String = "",
    )
      super(@list_of_color_swatches.map(&.color_name), selected_index)
      self.label = label
    end

    def initialize(
      @list_of_color_swatches : Array(ColorSwatch),
      selected_index : Int32 = 0,
      @appearance : ColorSwatchPickerStyle = ColorSwatchPickerStyle::SwatchButton,
      label : String = "",
      &block : Int32 -> Nil
    )
      super(@list_of_color_swatches.map(&.color_name), selected_index, &block)
      self.label = label
    end

    def selected_swatch : ColorSwatch?
      if selected_index >= 0 && selected_index < list_of_color_swatches.size
        list_of_color_swatches[selected_index]?
      end
    end

    # JSON-encode the palette metadata consumed by the native Picker facade.
    def surface_craft_picker_json : String
      JSON.build do |json|
        json.object do
          json.field "appearance", appearance.to_s.underscore
          json.field "swatches" do
            json.array do
              list_of_color_swatches.each do |swatch|
                json.object do
                  json.field "name", swatch.color_name
                  json.field "color", SurfaceCraftEncoding.color_value(swatch.swatch_color)
                end
              end
            end
          end
        end
      end
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self.as(Picker))
    end
  end
end
