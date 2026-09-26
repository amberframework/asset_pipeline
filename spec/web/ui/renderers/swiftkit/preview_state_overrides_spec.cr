require "../../../spec_helper"
require "../../../../../src/ui"

private class PreviewStateRecordingSender < UI::Native::Populator::Sender
  def set_color(target : String, setter : Symbol, color : UI::Color?)
  end

  def set_number(target : String, setter : Symbol, value : Float64?)
  end

  def set_bool(target : String, setter : Symbol, value : Bool?)
  end

  def set_string(target : String, setter : Symbol, value : String?)
    return if value.nil?
    FakeLibObjCBridge.record(setter, [target, value], "")
  end
end

describe UI::Native::Populator, "preview_state propagation" do
  it "reaches Toggle through the shared ViewOverrides path" do
    toggle = UI::Toggle.new("Enable")
    toggle.preview_state = UI::PreviewState::Hover
    target = FakeLibObjCBridge.next_sentinel_pointer

    UI::Native::Populator.populate_toggle(target, toggle, PreviewStateRecordingSender.new)

    FakeLibObjCBridge.assert_sent(:setApskPreviewState, args: [target, "hover"])
  end

  it "reaches MenuButton through the shared ViewOverrides path" do
    menu_button = UI::MenuButton.new("Choose")
    menu_button.preview_state = UI::PreviewState::Pressed
    target = FakeLibObjCBridge.next_sentinel_pointer

    UI::Native::Populator.populate_menu_button(target, menu_button, PreviewStateRecordingSender.new)

    FakeLibObjCBridge.assert_sent(:setApskPreviewState, args: [target, "pressed"])
  end

  it "reaches Picker and ColorSwatchPicker through the shared ViewOverrides path" do
    picker = UI::Picker.new(["One", "Two"])
    picker.preview_state = UI::PreviewState::Focus
    picker_target = FakeLibObjCBridge.next_sentinel_pointer
    UI::Native::Populator.populate_picker(picker_target, picker, PreviewStateRecordingSender.new)
    FakeLibObjCBridge.assert_sent(:setApskPreviewState, args: [picker_target, "focus"])

    FakeLibObjCBridge.reset
    swatch_picker = UI::ColorSwatchPicker.new([
      UI::ColorSwatch.new(color_name: "Ocean", swatch_color: UI::ColorRole::BrandPrimary),
    ])
    swatch_picker.preview_state = UI::PreviewState::Hover
    swatch_target = FakeLibObjCBridge.next_sentinel_pointer
    UI::Native::Populator.populate_picker(swatch_target, swatch_picker, PreviewStateRecordingSender.new)
    FakeLibObjCBridge.assert_sent(:setApskPreviewState, args: [swatch_target, "hover"])
  end

  it "reaches Keycap through its Label facade path" do
    keycap = UI::Keycap.new("⌥ S")
    keycap.preview_state = UI::PreviewState::Pressed
    target = FakeLibObjCBridge.next_sentinel_pointer

    UI::Native::Populator.populate_label(target, keycap, PreviewStateRecordingSender.new)

    FakeLibObjCBridge.assert_sent(:setApskPreviewState, args: [target, "pressed"])
  end
end
