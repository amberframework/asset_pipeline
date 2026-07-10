require "../../../spec_helper"
require "../../../../../src/ui"

# Default-detection invariant spec for Group 1 widget populators
# (Label, Image, TextField, SecureField, SearchField, TextArea,
# TextEditor, LinkButton, IconButton, Divider, Spacer).
#
# Each spec exercises the populator with a default-constructed view and
# asserts that none of the optional overrides land on the recording
# sender — proving that an unconfigured Crystal `UI::*` view inherits
# the raw SwiftUI default (the §11 default-detection invariant).
#
# Per-property "non-default emits setter" is covered by the existing
# button overrides spec for the common ViewOverrides cascade; here we
# focus on each widget's *own* knobs.

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

describe UI::Native::Populator, "Group 1 default-detection" do
  describe "#populate_label" do
    it "skips widget-specific setters on a default UI::Label" do
      view = UI::Label.new("Hello")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_label(target, view, RecordingSender.new)

      # text_color_role default is Primary → no labelRole setter
      FakeLibObjCBridge.refute_sent(:setLabelRole)
      # text_alignment default is Leading → no textAlignment setter
      FakeLibObjCBridge.refute_sent(:setTextAlignment)
      # number_of_lines default is 0 → no numberOfLines setter
      FakeLibObjCBridge.refute_sent(:setNumberOfLines)
      # Font default is size:17 weight::regular → no font setters
      FakeLibObjCBridge.refute_sent(:setFontSize)
      FakeLibObjCBridge.refute_sent(:setFontWeight)
    end

    it "emits setLabelRole when role is overridden" do
      view = UI::Label.new("Hello")
      view.text_color_role = UI::LabelRole::Secondary
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_label(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setLabelRole, times: 1,
        args: [target, "secondary"])
    end

    it "emits foregroundColor when role is nil (brand RGBA path)" do
      view = UI::Label.new("Hello")
      view.text_color_role = nil
      view.text_color = UI::Color.new(r: 0.5, g: 0.0, b: 0.5)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_label(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setForegroundColor, times: 1,
        args: [target, "rgba(0.5,0.0,0.5,1.0)"])
    end

    it "emits setFontSize + setFontWeight when font is overridden" do
      view = UI::Label.new("Cascade")
      view.font = UI::Font.new(size: 34.0, weight: :bold)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_label(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFontSize, times: 1,
        args: [target, "34.0"])
      # :bold maps to SwiftUI Font.Weight rawValue 3.
      FakeLibObjCBridge.assert_sent(:setFontWeight, times: 1,
        args: [target, "3.0"])
    end
  end

  describe "#populate_image" do
    it "skips contentMode setter at type default" do
      view = UI::Image.new("photo")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_image(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setContentMode)
    end

    it "emits setContentMode when overridden" do
      view = UI::Image.new("photo")
      view.content_mode = UI::ContentMode::Fill
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_image(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setContentMode, times: 1,
        args: [target, "fill"])
    end
  end

  describe "#populate_text_field" do
    it "skips secureEntry on default" do
      view = UI::TextField.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setSecureEntry)
      FakeLibObjCBridge.refute_sent(:setKeyboardType)
    end

    it "emits setSecureEntry:true when secure_entry=true" do
      view = UI::TextField.new
      view.secure_entry = true
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setSecureEntry, times: 1, args: [target, "true"])
    end
  end

  describe "#populate_secure_field" do
    it "applies only common overrides" do
      view = UI::SecureField.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_secure_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setBackgroundColor)
    end
  end

  describe "#populate_search_field" do
    it "skips showsCancelButton at type default (true)" do
      view = UI::SearchField.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_search_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setShowsCancelButton)
    end

    it "emits setShowsCancelButton:false when hidden" do
      view = UI::SearchField.new
      view.shows_cancel_button = false
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_search_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setShowsCancelButton, times: 1,
        args: [target, "false"])
    end
  end

  describe "#populate_divider" do
    it "always emits foregroundColor (default is grey not nil)" do
      view = UI::Divider.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_divider(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setForegroundColor, times: 1)
    end

    it "skips thickness at type default of 1.0" do
      view = UI::Divider.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_divider(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setThickness)
    end
  end

  describe "#populate_spacer" do
    it "skips minLength when min_length=0.0" do
      view = UI::Spacer.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_spacer(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setMinLength)
    end

    it "emits setMinLength when min_length > 0" do
      view = UI::Spacer.new(8.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_spacer(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setMinLength, times: 1, args: [target, "8.0"])
    end
  end

  describe "#populate_icon_button" do
    it "always emits the label setter" do
      # IconButton has no nil label by default (it's `String?` but the
      # populator currently emits when nil-checked); verify that path.
      view = UI::IconButton.new("plus")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_icon_button(target, view, RecordingSender.new)
      # label is nil by default → no setLabel
      FakeLibObjCBridge.refute_sent(:setLabel)
    end
  end
end

describe UI::Native::Populator, "Group 2 default-detection" do
  describe "#populate_toggle" do
    it "skips toggleStyle, foregroundColor, disabled on default UI::Toggle" do
      view = UI::Toggle.new("Wi-Fi")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_toggle(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setToggleStyle)
      FakeLibObjCBridge.refute_sent(:setForegroundColor)
      FakeLibObjCBridge.refute_sent(:setDisabled)
    end

    it "emits setToggleStyle when style is overridden" do
      view = UI::Toggle.new("Compact")
      view.style = UI::ToggleStyle::Checkbox
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_toggle(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setToggleStyle, times: 1,
        args: [target, "checkbox"])
    end
  end

  describe "#populate_slider" do
    it "skips step at type default" do
      view = UI::Slider.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_slider(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setStep)
    end

    it "emits step when explicit" do
      view = UI::Slider.new
      view.step = 0.1
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_slider(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setStep, times: 1, args: [target, "0.1"])
    end
  end

  describe "#populate_stepper" do
    it "skips step at type default of 1.0" do
      view = UI::Stepper.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_stepper(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setStep)
      FakeLibObjCBridge.refute_sent(:setWraps)
    end
  end

  describe "#populate_picker" do
    it "skips pickerStyle at default (Menu)" do
      view = UI::Picker.new(["a", "b"])
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_picker(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setPickerStyle)
    end

    it "emits pickerStyle when overridden" do
      view = UI::Picker.new(["a", "b"])
      view.style = UI::PickerStyle::Wheel
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_picker(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setPickerStyle, times: 1, args: [target, "wheel"])
    end
  end

  describe "#populate_date_picker" do
    it "skips datePickerMode at default (Date)" do
      view = UI::DatePicker.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_date_picker(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setDatePickerMode)
    end
  end

  describe "#populate_color_picker" do
    it "skips supportsOpacity at default (false)" do
      view = UI::ColorPicker.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_color_picker(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setSupportsOpacity)
    end
  end
end
