require "../../../spec_helper"
require "../../../../../src/ui"

# Default-detection invariant spec for `UI::Native::Populator.populate_list_view`
# (Phase 3 Remediation 2 — closes the iter-2 "ListView entirely missing"
# substance finding). Mirrors the shape of `group3_overrides_spec.cr`
# (the populator covered there) and `button_overrides_spec.cr` (the
# ViewOverrides common-field grid).

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

  def set_string_array(target : String, setter : Symbol, values : Array(String))
    return if values.empty?
    FakeLibObjCBridge.record(setter, [target, values.join(",")], "")
  end

  def set_int_array(target : String, setter : Symbol, values : Array(Int32))
    return if values.empty?
    FakeLibObjCBridge.record(setter, [target, values.map(&.to_s).join(",")], "")
  end

  def set_uint64_array(target : String, setter : Symbol, values : Array(UInt64))
    return if values.empty?
    FakeLibObjCBridge.record(setter, [target, values.map(&.to_s).join(",")], "")
  end

  def set_bool_array(target : String, setter : Symbol, values : Array(Bool))
    return if values.empty?
    FakeLibObjCBridge.record(setter, [target, values.map(&.to_s).join(",")], "")
  end

  def set_int(target : String, setter : Symbol, value : Int32?)
    return if value.nil?
    FakeLibObjCBridge.record(setter, [target, value.to_s], "")
  end

  private def color_to_s(c : UI::Color) : String
    "rgba(#{c.r},#{c.g},#{c.b},#{c.a})"
  end
end

describe UI::Native::Populator, "#populate_list_view" do
  describe "default-detection invariant" do
    it "sends NO optional setters on a default UI::ListView.new" do
      view = UI::ListView.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)

      # ViewOverrides common-field grid — every optional propagates.
      FakeLibObjCBridge.refute_sent(:setBackgroundColor)
      FakeLibObjCBridge.refute_sent(:setForegroundColor)
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
      FakeLibObjCBridge.refute_sent(:setApskAccessibilityLabel)

      # ListView-specific defaults: style=Plain, shows_separators=true,
      # sections empty. All optional setters skipped; no section arrays.
      FakeLibObjCBridge.refute_sent(:setListStyle)
      FakeLibObjCBridge.refute_sent(:setShowsSeparators)
      FakeLibObjCBridge.refute_sent(:setSectionHeaders)
      FakeLibObjCBridge.refute_sent(:setSectionFooters)
      FakeLibObjCBridge.refute_sent(:setSectionItemCounts)
    end
  end

  describe "list style override" do
    it "emits setListStyle for :inset" do
      view = UI::ListView.new(style: UI::ListStyle::Inset)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setListStyle, times: 1, args: [target, "inset"])
    end

    it "emits setListStyle for :grouped" do
      view = UI::ListView.new(style: UI::ListStyle::Grouped)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setListStyle, times: 1, args: [target, "grouped"])
    end

    it "emits setListStyle for :inset_grouped using camelCase facade key" do
      view = UI::ListView.new(style: UI::ListStyle::InsetGrouped)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setListStyle, times: 1, args: [target, "insetGrouped"])
    end

    it "emits setListStyle for :sidebar" do
      view = UI::ListView.new(style: UI::ListStyle::Sidebar)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setListStyle, times: 1, args: [target, "sidebar"])
    end

    it "skips setListStyle for :plain (type default)" do
      view = UI::ListView.new(style: UI::ListStyle::Plain)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setListStyle)
    end
  end

  describe "shows_separators override" do
    it "skips setShowsSeparators when shows_separators=true (type default)" do
      view = UI::ListView.new
      view.shows_separators = true
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setShowsSeparators)
    end

    it "emits setShowsSeparators:false when overridden off" do
      view = UI::ListView.new
      view.shows_separators = false
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setShowsSeparators, times: 1,
        args: [target, "false"])
    end
  end

  describe "section slicing" do
    it "emits parallel sectionHeaders + sectionFooters + sectionItemCounts" do
      view = UI::ListView.new
      view.sections = [
        UI::ListView::Section.new(
          header: "Today",
          items: [UI::Label.new("a"), UI::Label.new("b")] of UI::View,
          footer: "End",
        ),
        UI::ListView::Section.new(
          header: "Yesterday",
          items: [UI::Label.new("c")] of UI::View,
        ),
      ]
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setSectionHeaders, times: 1,
        args: [target, "Today,Yesterday"])
      FakeLibObjCBridge.assert_sent(:setSectionFooters, times: 1,
        args: [target, "End,"])
      FakeLibObjCBridge.assert_sent(:setSectionItemCounts, times: 1,
        args: [target, "2,1"])
    end

    it "skips section arrays when sections list is empty" do
      view = UI::ListView.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setSectionHeaders)
      FakeLibObjCBridge.refute_sent(:setSectionFooters)
      FakeLibObjCBridge.refute_sent(:setSectionItemCounts)
    end
  end

  describe "ViewOverrides common-field propagation" do
    it "emits setBackgroundColor when background is set" do
      view = UI::ListView.new
      view.background = UI::Color.new(r: 0.1, g: 0.2, b: 0.3)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setBackgroundColor, times: 1,
        args: [target, "rgba(0.1,0.2,0.3,1.0)"])
    end

    it "emits setCornerRadius when corner_radius is set to a non-zero value" do
      view = UI::ListView.new
      view.corner_radius = 12.0
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setCornerRadius, times: 1,
        args: [target, "12.0"])
    end

    it "emits setOpacity when opacity is set to a non-default value" do
      view = UI::ListView.new
      view.opacity = 0.5
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setOpacity, times: 1,
        args: [target, "0.5"])
    end

    it "emits padding setters when padding is set" do
      view = UI::ListView.new
      view.padding = UI::EdgeInsets.new(top: 4.0, leading: 8.0, bottom: 4.0, trailing: 8.0)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setPaddingTop, times: 1, args: [target, "4.0"])
      FakeLibObjCBridge.assert_sent(:setPaddingLeading, times: 1, args: [target, "8.0"])
      FakeLibObjCBridge.assert_sent(:setPaddingBottom, times: 1, args: [target, "4.0"])
      FakeLibObjCBridge.assert_sent(:setPaddingTrailing, times: 1, args: [target, "8.0"])
    end

    it "emits setApskAccessibilityLabel when accessibility_label is set" do
      view = UI::ListView.new
      view.accessibility_label = "Inbox messages"
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_list_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setApskAccessibilityLabel, times: 1,
        args: [target, "Inbox messages"])
    end
  end
end
