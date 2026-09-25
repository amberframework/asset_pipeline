# Single-selection picker specialized for a named color palette.

require "./picker"

module UI
  # One named color in the serialized palette passed to the SwiftUI facade.
  struct SurfaceCraftSwatchPayload
    include JSON::Serializable

    @[JSON::Field(key: "name")]
    property color_name : String
    @[JSON::Field(key: "color")]
    property swatch_color : String

    def initialize(@color_name : String, @swatch_color : String)
    end
  end

  # Typed palette and appearance payload consumed by the SwiftUI facade.
  struct SurfaceCraftSwatchPickerPayload
    include JSON::Serializable

    property appearance : String
    property swatches : Array(SurfaceCraftSwatchPayload)
    @[JSON::Field(key: "selectionRing")]
    property selection_ring_color : String

    def initialize(
      @appearance : String,
      @swatches : Array(SurfaceCraftSwatchPayload),
      @selection_ring_color : String,
    )
    end
  end

  # Color choice control that reuses Picker's selected-index callback contract.
  class ColorSwatchPicker < Picker
    property list_of_color_swatches : Array(ColorSwatch)
    property appearance : ColorSwatchPickerStyle = ColorSwatchPickerStyle::SwatchButton
    # Color used for the selected swatch ring. Defaults to semantic text ink.
    property selection_ring_color : SurfaceColor = ColorRole::TextPrimary

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
      swatches = list_of_color_swatches.map do |swatch|
        SurfaceCraftSwatchPayload.new(
          color_name: swatch.color_name,
          swatch_color: SurfaceCraftEncoding.color_value(swatch.swatch_color),
        )
      end

      SurfaceCraftSwatchPickerPayload.new(
        appearance: appearance.to_s.underscore,
        swatches: swatches,
        selection_ring_color: SurfaceCraftEncoding.color_value(selection_ring_color),
      ).to_json
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self.as(Picker))
    end
  end
end
