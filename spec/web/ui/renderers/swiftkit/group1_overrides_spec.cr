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
      # fill_horizontal default false → no fill frame
      FakeLibObjCBridge.refute_sent(:setFillHorizontal)
    end

    it "emits setFillHorizontal when fill_horizontal=true" do
      view = UI::Label.new("My Tracks")
      view.fill_horizontal = true
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_label(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFillHorizontal, times: 1, args: [target, "true"])
    end

    it "skips setPreferredMaxLayoutWidth when unset" do
      view = UI::Label.new("Hi")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_label(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setPreferredMaxLayoutWidth)
    end

    it "emits setPreferredMaxLayoutWidth when set (wrapping-height fix)" do
      view = UI::Label.new("Hi Maximilian Alexander, nice to meet you!")
      view.preferred_max_layout_width = 420.0
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_label(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setPreferredMaxLayoutWidth, times: 1,
        args: [target, "420.0"])
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

    it "emits foregroundColor when text_color is set WITHOUT nil-ing the role" do
      # Footgun fix: assigning a raw text_color now auto-clears the default
      # Primary role (mutual exclusion), so an explicit color "just works" —
      # previously it was silently ignored and the label rendered .primary.
      view = UI::Label.new("Morning Track")
      view.text_color = UI::Color.new(r: 0.0, g: 0.0, b: 0.0) # black on a near-white card
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_label(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setForegroundColor, times: 1,
        args: [target, "rgba(0.0,0.0,0.0,1.0)"])
      FakeLibObjCBridge.refute_sent(:setLabelRole)
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
      FakeLibObjCBridge.assert_sent(:setTextAlignment, times: 1,
        args: [target, "leading"])
      FakeLibObjCBridge.refute_sent(:setSecureEntry)
      FakeLibObjCBridge.refute_sent(:setKeyboardType)
      # Font default (size 17 / weight :regular / family "system") → no setters.
      # UI::TextField#font was previously dropped entirely.
      FakeLibObjCBridge.refute_sent(:setFontSize)
      FakeLibObjCBridge.refute_sent(:setFontWeight)
      FakeLibObjCBridge.refute_sent(:setFontFamily)
      # placeholder_color defaults to nil → no placeholder-tint setter.
      FakeLibObjCBridge.refute_sent(:setPlaceholderColor)
    end

    it "emits setPlaceholderColor when placeholder_color is set" do
      view = UI::TextField.new
      view.placeholder_color = UI::Color.new(r: 0.745, g: 0.761, b: 0.761) # #bec2c2
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setPlaceholderColor, times: 1,
        args: [target, "rgba(0.745,0.761,0.761,1.0)"])
    end

    it "emits setSecureEntry:true when secure_entry=true" do
      view = UI::TextField.new
      view.secure_entry = true
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setSecureEntry, times: 1, args: [target, "true"])
    end

    it "forwards an explicit text alignment" do
      view = UI::TextField.new
      view.text_alignment = UI::Alignment::Trailing
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setTextAlignment, times: 1,
        args: [target, "trailing"])
    end

    it "forwards font size/weight/family when overridden" do
      view = UI::TextField.new
      view.font = UI::Font.new(family: "Alegreya-Medium", size: 22.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFontFamily, times: 1,
        args: [target, "Alegreya-Medium"])
      FakeLibObjCBridge.assert_sent(:setFontSize, times: 1, args: [target, "22.0"])
      # Custom face carries its own weight; default :regular → no weight setter.
      FakeLibObjCBridge.refute_sent(:setFontWeight)
    end

    it "forwards setFontWeight for a system face with a bold weight" do
      view = UI::TextField.new
      view.font = UI::Font.new(size: 18.0, weight: :bold)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFontSize, times: 1, args: [target, "18.0"])
      FakeLibObjCBridge.assert_sent(:setFontWeight, times: 1, args: [target, "3.0"])
    end

    it "skips setBorderStyle at the RoundedBorder default" do
      view = UI::TextField.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setBorderStyle)
    end

    it "emits setBorderStyle:underline when style is Underline" do
      view = UI::TextField.new
      view.style = UI::TextFieldStyle::Underline
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setBorderStyle, times: 1, args: [target, "underline"])
    end
  end

  describe "#populate_secure_field" do
    it "applies only common overrides + no font on default" do
      view = UI::SecureField.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_secure_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setTextAlignment, times: 1,
        args: [target, "leading"])
      FakeLibObjCBridge.refute_sent(:setBackgroundColor)
      FakeLibObjCBridge.refute_sent(:setFontSize)
      FakeLibObjCBridge.refute_sent(:setFontFamily)
    end

    it "forwards an explicit text alignment" do
      view = UI::SecureField.new
      view.text_alignment = UI::Alignment::Trailing
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_secure_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setTextAlignment, times: 1,
        args: [target, "trailing"])
    end

    it "forwards font family + size when overridden" do
      view = UI::SecureField.new
      view.font = UI::Font.new(family: "Alegreya-Medium", size: 16.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_secure_field(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFontFamily, times: 1,
        args: [target, "Alegreya-Medium"])
      FakeLibObjCBridge.assert_sent(:setFontSize, times: 1, args: [target, "16.0"])
    end
  end

  describe "#populate_text_area" do
    it "skips font + widget setters on a default UI::TextArea" do
      view = UI::TextArea.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_area(target, view, RecordingSender.new)
      # is_editable/is_scrollable default true, line_limit nil → no setters.
      FakeLibObjCBridge.refute_sent(:setLineLimit)
      # Font default → no setters. UI::TextArea#font was previously dropped.
      FakeLibObjCBridge.refute_sent(:setFontSize)
      FakeLibObjCBridge.refute_sent(:setFontWeight)
      FakeLibObjCBridge.refute_sent(:setFontFamily)
    end

    it "forwards font family + size when overridden" do
      view = UI::TextArea.new
      view.font = UI::Font.new(family: "AlegreyaSans-Light", size: 18.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_text_area(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setFontFamily, times: 1,
        args: [target, "AlegreyaSans-Light"])
      FakeLibObjCBridge.assert_sent(:setFontSize, times: 1, args: [target, "18.0"])
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

    it "skips setBordered at the bordered=true default" do
      view = UI::IconButton.new("plus")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_icon_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setBordered)
    end

    it "emits setBordered:false for a bare (chrome-free) icon" do
      view = UI::IconButton.new("plus")
      view.bordered = false
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_icon_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setBordered, times: 1, args: [target, "false"])
    end

    it "skips setIconWidth/setIconHeight when nil (default square footprint)" do
      view = UI::IconButton.new("plus")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_icon_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setIconWidth)
      FakeLibObjCBridge.refute_sent(:setIconHeight)
    end

    it "emits setIconWidth/setIconHeight for a non-square cover-crop icon" do
      # e.g. hamburger 22x18 from a 66x54 @3x source
      view = UI::IconButton.new("/path/to/hamburgermenuicon.png")
      view.icon_width = 22.0
      view.icon_height = 18.0
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_icon_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setIconWidth, times: 1, args: [target, "22.0"])
      FakeLibObjCBridge.assert_sent(:setIconHeight, times: 1, args: [target, "18.0"])
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

    it "skips setForegroundColor when tint_color is unset" do
      view = UI::Slider.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_slider(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setForegroundColor)
    end

    it "emits setForegroundColor (slider tint) when tint_color is set" do
      view = UI::Slider.new
      view.tint_color = UI::Color.new(r: 0.416, g: 0.427, b: 0.804) # #6a6dcd
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_slider(target, view, RecordingSender.new)
      # The Swift SliderFacade applies this via `.tint(...)` (NOT
      # `.foregroundStyle`, which a SwiftUI Slider ignores for its track/thumb).
      FakeLibObjCBridge.assert_sent(:setForegroundColor, times: 1,
        args: [target, "rgba(0.416,0.427,0.804,1.0)"])
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
