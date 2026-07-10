require "../../../spec_helper"
require "../../../../../src/ui"

# Default-detection invariant spec for the Phase 3 Glass facade populator
# (the "headline visual differentiator" the README names). Mirrors the
# pattern in `button_overrides_spec.cr` and `group3_overrides_spec.cr`:
# default-constructed view must produce zero setter records; per-knob
# overrides must surface the corresponding `setMaterial:` /
# `setApskAccessibilityLabel:` invocation.

private class RecordingSender < UI::Native::Populator::Sender
  def set_color(target : String, setter : Symbol, color : UI::Color?)
    return if color.nil?
    FakeLibObjCBridge.record(setter, [target, "color"], "")
  end

  def set_number(target : String, setter : Symbol, value : Float64?)
    return if value.nil?
    FakeLibObjCBridge.record(setter, [target, value.to_s], "")
  end

  def set_bool(target : String, setter : Symbol, value : Bool?)
    return if value.nil?
    FakeLibObjCBridge.record(setter, [target, value.to_s], "")
  end

  def set_string(target : String, setter : Symbol, value : String?)
    return if value.nil?
    FakeLibObjCBridge.record(setter, [target, value], "")
  end
end

describe UI::Native::Populator, "#populate_glass_background" do
  describe "default-detection invariant" do
    it "emits zero setters on a default UI::GlassBackground.new" do
      view = UI::GlassBackground.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)

      # Common ViewOverrides defaults — all skipped.
      FakeLibObjCBridge.refute_sent(:setBackgroundColor)
      FakeLibObjCBridge.refute_sent(:setCornerRadius)
      FakeLibObjCBridge.refute_sent(:setPaddingTop)
      FakeLibObjCBridge.refute_sent(:setOpacity)
      FakeLibObjCBridge.refute_sent(:setHidden)
      FakeLibObjCBridge.refute_sent(:setBorderWidth)
      FakeLibObjCBridge.refute_sent(:setShadowRadius)
      FakeLibObjCBridge.refute_sent(:setMinWidth)
      FakeLibObjCBridge.refute_sent(:setMaxWidth)
      FakeLibObjCBridge.refute_sent(:setAccessibilityIdentifier)
      FakeLibObjCBridge.refute_sent(:setApskAccessibilityLabel)

      # Glass-specific default — :regular material is the type default.
      FakeLibObjCBridge.refute_sent(:setMaterial)
    end
  end

  describe "material override" do
    it "skips setMaterial: when material is :regular (type default)" do
      view = UI::GlassBackground.new(material: :regular)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setMaterial)
    end

    it "emits setMaterial: 'thin' when material is :thin" do
      view = UI::GlassBackground.new(material: :thin)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thin"])
    end

    it "emits setMaterial: 'ultraThin' for :ultra_thin (camelCase normalisation)" do
      view = UI::GlassBackground.new(material: :ultra_thin)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThin"])
    end

    it "emits setMaterial: 'thick' for :thick" do
      view = UI::GlassBackground.new(material: :thick)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thick"])
    end

    it "emits setMaterial: 'ultraThick' for :chrome (closest Material analogue)" do
      view = UI::GlassBackground.new(material: :chrome)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThick"])
    end
  end

  describe "Phase 5 apple_step quantization parameter" do
    it "honors the explicit apple_step override on a :regular-declared view" do
      view = UI::GlassBackground.new(material: :regular)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :thick)
      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thick"])
    end

    it "still emits the resolved key when intensity quantization keeps it at :regular but declared material differs" do
      view = UI::GlassBackground.new(material: :thin)
      target = FakeLibObjCBridge.next_sentinel_pointer
      # Renderer-resolved apple_step normally matches declared step for non-:regular.
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :thin)
      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "thin"])
    end

    it "emits setMaterial: 'ultraThin' when brand intensity quantizes :regular down to :ultra_thin" do
      view = UI::GlassBackground.new(material: :regular)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new, apple_step: :ultra_thin)
      FakeLibObjCBridge.assert_sent(:setMaterial, times: 1, args: [target, "ultraThin"])
    end
  end

  describe "common ViewOverrides cascade" do
    it "forwards corner_radius override to setCornerRadius:" do
      view = UI::GlassBackground.new
      view.corner_radius = 14.0
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setCornerRadius, times: 1, args: [target, "14.0"])
    end

    it "forwards accessibility_label to setApskAccessibilityLabel:" do
      view = UI::GlassBackground.new
      view.accessibility_label = "Background panel"
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setApskAccessibilityLabel,
        times: 1, args: [target, "Background panel"])
    end

    it "forwards background colour override to setBackgroundColor:" do
      view = UI::GlassBackground.new
      view.background = UI::Color.new(r: 0.0, g: 0.0, b: 1.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_glass_background(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setBackgroundColor, times: 1, args: [target, "color"])
    end
  end
end
