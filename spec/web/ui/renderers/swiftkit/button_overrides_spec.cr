require "../../../spec_helper"
require "../../../../../src/ui"

# Default-detection invariant spec for `UI::Native::Populator.populate_button`.
# This is implementation.md §11's "single most important behavioral
# invariant of phase 3": when the Crystal view leaves a property at its
# type default, the corresponding Swift setter MUST NOT be called.
# When the property is set, the setter MUST be called with the right value.

# Concrete Sender that pipes every setter through the FakeLibObjCBridge
# recorder. Keeps the spec independent of any AppKit/UIKit framework.
private class RecordingSender < UI::Native::Populator::Sender
  def set_color(target : String, setter : Symbol, color : UI::Color?)
    return if color.nil?
    FakeLibObjCBridge.record(setter, [target, color_to_s(color)], "")
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

  private def color_to_s(c : UI::Color) : String
    "rgba(#{c.r},#{c.g},#{c.b},#{c.a})"
  end
end

describe UI::Native::Populator, "#populate_button" do
  describe "default-detection invariant" do
    it "sends NO setters on a default UI::Button.new(\"Save\")" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)

      # Common ViewOverrides defaults — all skipped.
      FakeLibObjCBridge.refute_sent(:setBackgroundColor)
      FakeLibObjCBridge.refute_sent(:setCornerRadius)
      FakeLibObjCBridge.refute_sent(:setPaddingTop)
      FakeLibObjCBridge.refute_sent(:setPaddingLeading)
      FakeLibObjCBridge.refute_sent(:setPaddingBottom)
      FakeLibObjCBridge.refute_sent(:setPaddingTrailing)
      FakeLibObjCBridge.refute_sent(:setOpacity)
      FakeLibObjCBridge.refute_sent(:setHidden)
      FakeLibObjCBridge.refute_sent(:setBorderWidth)
      FakeLibObjCBridge.refute_sent(:setBorderColor)
      FakeLibObjCBridge.refute_sent(:setShadowRadius)
      FakeLibObjCBridge.refute_sent(:setShadowColor)
      FakeLibObjCBridge.refute_sent(:setShadowOffsetX)
      FakeLibObjCBridge.refute_sent(:setShadowOffsetY)
      FakeLibObjCBridge.refute_sent(:setMinWidth)
      FakeLibObjCBridge.refute_sent(:setMinHeight)
      FakeLibObjCBridge.refute_sent(:setMaxWidth)
      FakeLibObjCBridge.refute_sent(:setMaxHeight)
      FakeLibObjCBridge.refute_sent(:setAccessibilityIdentifier)
      # Renamed selector — see ViewOverrides.swift / swiftkit_overrides.cr.
      FakeLibObjCBridge.refute_sent(:setApskAccessibilityLabel)

      # Button-specific defaults — role=:default, style=Default,
      # disabled=false, symbol=nil — all skipped.
      FakeLibObjCBridge.refute_sent(:setRole)
      FakeLibObjCBridge.refute_sent(:setStyle)
      FakeLibObjCBridge.refute_sent(:setDisabled)
      FakeLibObjCBridge.refute_sent(:setSymbolName)
    end
  end

  describe "background color override" do
    it "sends setBackgroundColor: only when view.background is non-nil" do
      view = UI::Button.new("Save")
      view.background = UI::Color.new(r: 1.0, g: 0.0, b: 0.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)

      FakeLibObjCBridge.assert_sent(:setBackgroundColor, times: 1,
        args: [target, "rgba(1.0,0.0,0.0,1.0)"])
    end
  end

  describe "corner radius override" do
    it "skips setCornerRadius: when value is the 0.0 type default" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setCornerRadius)
    end

    it "sends setCornerRadius: when value is set to a non-zero number" do
      view = UI::Button.new("Save")
      view.corner_radius = 12.0
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setCornerRadius, times: 1,
        args: [target, "12.0"])
    end
  end

  describe "padding override" do
    it "sends only the non-zero padding sides" do
      view = UI::Button.new("Save")
      view.padding = UI::EdgeInsets.new(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 16.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)

      FakeLibObjCBridge.refute_sent(:setPaddingTop)
      FakeLibObjCBridge.refute_sent(:setPaddingBottom)
      FakeLibObjCBridge.assert_sent(:setPaddingLeading, times: 1,
        args: [target, "8.0"])
      FakeLibObjCBridge.assert_sent(:setPaddingTrailing, times: 1,
        args: [target, "16.0"])
    end
  end

  describe "opacity override" do
    it "skips setOpacity: when opacity equals 1.0 (type default)" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setOpacity)
    end

    it "sends setOpacity: when opacity is set to a non-default value" do
      view = UI::Button.new("Save")
      view.opacity = 0.5
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setOpacity, times: 1, args: [target, "0.5"])
    end
  end

  describe "hidden override" do
    it "skips setHidden: when hidden=false (type default)" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setHidden)
    end

    it "sends setHidden:true when hidden=true" do
      view = UI::Button.new("Save")
      view.hidden = true
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setHidden, times: 1, args: [target, "true"])
    end
  end

  describe "role override" do
    it "skips setRole: when role=:default" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setRole)
    end

    it "sends setRole:destructive when role=:destructive" do
      view = UI::Button.new("Delete", role: :destructive)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setRole, times: 1, args: [target, "destructive"])
    end

    it "sends setRole:cancel when role=:cancel" do
      view = UI::Button.new("Cancel", role: :cancel)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setRole, times: 1, args: [target, "cancel"])
    end
  end

  describe "style override" do
    it "skips setStyle: when style=Default" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setStyle)
    end

    it "sends setStyle:prominent when style=Prominent" do
      view = UI::Button.new("Save", style: UI::ButtonStyle::Prominent)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setStyle, times: 1, args: [target, "prominent"])
    end

    it "sends setStyle:tinted when style=Tinted" do
      view = UI::Button.new("Save", style: UI::ButtonStyle::Tinted)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setStyle, times: 1, args: [target, "tinted"])
    end

    it "sends setStyle:borderless when style=Borderless" do
      view = UI::Button.new("Save", style: UI::ButtonStyle::Borderless)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setStyle, times: 1, args: [target, "borderless"])
    end
  end

  describe "disabled override" do
    it "skips setDisabled: when disabled=false (type default)" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setDisabled)
    end

    it "sends setDisabled:true when disabled=true" do
      view = UI::Button.new("Save")
      view.disabled = true
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setDisabled, times: 1, args: [target, "true"])
    end
  end

  describe "symbol override" do
    it "skips setSymbolName: when symbol is nil" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setSymbolName)
    end

    it "sends setSymbolName: when symbol is set" do
      view = UI::Button.new("Save", symbol: "tray.and.arrow.down")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setSymbolName, times: 1,
        args: [target, "tray.and.arrow.down"])
    end
  end

  describe "test_id / accessibility identifier" do
    it "sends setAccessibilityIdentifier: when test_id is set" do
      view = UI::Button.new("Save")
      view.test_id = "primary-save-button"
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setAccessibilityIdentifier, times: 1,
        args: [target, "primary-save-button"])
    end
  end

  describe "minimum/maximum size constraints" do
    it "sends setMinWidth: only when minimum_width is set" do
      view = UI::Button.new("Save")
      view.minimum_width = 88.0
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setMinWidth, times: 1, args: [target, "88.0"])
      FakeLibObjCBridge.refute_sent(:setMinHeight)
      FakeLibObjCBridge.refute_sent(:setMaxWidth)
      FakeLibObjCBridge.refute_sent(:setMaxHeight)
    end
  end
end
