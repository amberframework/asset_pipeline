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
      FakeLibObjCBridge.refute_sent(:setApskPreviewState)

      # Button-specific defaults — role=:default, style=Default,
      # disabled=false, symbol=nil — all skipped.
      FakeLibObjCBridge.refute_sent(:setRole)
      FakeLibObjCBridge.refute_sent(:setStyle)
      FakeLibObjCBridge.refute_sent(:setDisabled)
      FakeLibObjCBridge.refute_sent(:setSymbolName)

      # Font default is size:17 weight::regular family:"system" → no
      # font setters. UI::Button#font was previously dropped entirely;
      # the default-construction case must still emit nothing.
      FakeLibObjCBridge.refute_sent(:setFontSize)
      FakeLibObjCBridge.refute_sent(:setFontWeight)
      FakeLibObjCBridge.refute_sent(:setFontFamily)
      # fill_horizontal default false → no fill frame.
      FakeLibObjCBridge.refute_sent(:setFillHorizontal)
      # foreground_color default (system blue) → not seeded; keep system label.
      FakeLibObjCBridge.refute_sent(:setForegroundColor)
    end

    it "emits the explicit preview state through the shared ViewOverrides slot" do
      view = UI::Button.new("Preview")
      view.preview_state = UI::PreviewState::Pressed
      target = FakeLibObjCBridge.next_sentinel_pointer

      UI::Native::Populator.populate_button(target, view, RecordingSender.new)

      FakeLibObjCBridge.assert_sent(:setApskPreviewState, times: 1, args: [target, "pressed"])
    end

    it "seeds setForegroundColor when foreground_color is explicitly set" do
      view = UI::Button.new("Achieved")
      view.foreground_color = UI::Color.new(r: 0.184, g: 0.608, b: 0.325) # #2F9B53
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setForegroundColor, times: 1)
    end

    it "emits setFillHorizontal when fill_horizontal=true" do
      view = UI::Button.new("I always procrastinate")
      view.fill_horizontal = true
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFillHorizontal, times: 1, args: [target, "true"])
    end
  end

  describe "font override" do
    it "emits setFontSize + setFontWeight when font size/weight overridden" do
      view = UI::Button.new("Start your day")
      view.font = UI::Font.new(size: 22.0, weight: :bold)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFontSize, times: 1,
        args: [target, "22.0"])
      # :bold maps to SwiftUI Font.Weight rawValue 3.
      FakeLibObjCBridge.assert_sent(:setFontWeight, times: 1,
        args: [target, "3.0"])
      FakeLibObjCBridge.refute_sent(:setFontFamily)
    end

    it "emits setFontFamily when a custom family is set" do
      view = UI::Button.new("Start your day")
      view.font = UI::Font.new(family: "Alegreya-Medium", size: 18.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFontFamily, times: 1,
        args: [target, "Alegreya-Medium"])
      FakeLibObjCBridge.assert_sent(:setFontSize, times: 1,
        args: [target, "18.0"])
    end

    it "skips setFontWeight when only family+size are set (regular weight)" do
      view = UI::Button.new("Start your day")
      view.font = UI::Font.new(family: "Alegreya-Medium", size: 18.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      # Custom faces carry their own weight; default :regular → no weight setter.
      FakeLibObjCBridge.refute_sent(:setFontWeight)
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

    # A bordered + rounded button (e.g. an Expo "secondary" outline button) must
    # emit corner radius ALONGSIDE the border so the Swift facade can stroke the
    # outline with the SAME corner radius as the clipped background — otherwise
    # the border rendered as a square rectangle around a rounded pill.
    it "emits setCornerRadius with setBorderWidth/Color for a rounded outline button" do
      view = UI::Button.new("Reset to Defaults")
      view.corner_radius = 10.0
      view.border_width = 1.0
      view.border_color = UI::Color.new(r: 0.847, g: 0.855, b: 0.863) # #d8dadc
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setCornerRadius, times: 1, args: [target, "10.0"])
      FakeLibObjCBridge.assert_sent(:setBorderWidth, times: 1, args: [target, "1.0"])
      FakeLibObjCBridge.assert_sent(:setBorderColor, times: 1,
        args: [target, "rgba(0.847,0.855,0.863,1.0)"])
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

  describe "number_of_lines override" do
    it "skips setNumberOfLines at the single-line default (1)" do
      view = UI::Button.new("Save")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setNumberOfLines)
    end

    it "emits setNumberOfLines:0 when the label opts into wrapping" do
      # A tappable content button (e.g. a thought card) whose long user text
      # must wrap, not truncate.
      view = UI::Button.new("I am not good enough and I constantly feel judged")
      view.number_of_lines = 0
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setNumberOfLines, times: 1, args: [target, "0.0"])
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
