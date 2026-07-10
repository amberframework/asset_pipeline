require "../../../spec_helper"
require "../../../../../src/ui"

# Default-detection invariant spec for Group 3 container widget populators
# (NavigationStack, NavigationLink, NavigationSplitView, TabView, Sheet,
# Popover, Alert, ConfirmationDialog, Toolbar, Form, Grid, Card, Surface,
# MenuButton, ToggleButton).
#
# Each spec exercises the populator with a default-constructed view and
# asserts that none of the optional overrides land on the recording
# sender — the §11 default-detection invariant. Per-property "non-default
# emits setter" specs are added selectively where the populator's slicing
# / array-emission logic is non-trivial.

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
end

describe UI::Native::Populator, "Group 3 default-detection" do
  describe "#populate_navigation_stack" do
    it "emits only title when present; skips on default" do
      view = UI::NavigationStack.new(UI::Label.new("hi"))
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_navigation_stack(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setTitle)
      FakeLibObjCBridge.refute_sent(:setLargeTitle)
    end

    it "emits setLargeTitle:true when overridden" do
      view = UI::NavigationStack.new(UI::Label.new("hi"))
      view.large_title = true
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_navigation_stack(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setLargeTitle, times: 1, args: [target, "true"])
    end
  end

  describe "#populate_navigation_link" do
    it "skips icon + showsDisclosure on default" do
      view = UI::NavigationLink.new("More", UI::Label.new("dest"))
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_navigation_link(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setIcon)
      FakeLibObjCBridge.refute_sent(:setShowsDisclosure)
    end
  end

  describe "#populate_navigation_split_view" do
    it "skips sidebar_width at type default of 250" do
      view = UI::NavigationSplitView.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_navigation_split_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setSidebarWidth)
      FakeLibObjCBridge.refute_sent(:setColumnVisibility)
    end
  end

  describe "#populate_tab_view" do
    it "emits parallel tabLabels + tabIcons even on default" do
      view = UI::TabView.new([
        UI::TabView::Tab.new(label: "One", icon: "1.circle"),
        UI::TabView::Tab.new(label: "Two"),
      ])
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_tab_view(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setTabLabels, times: 1,
        args: [target, "One,Two"])
      FakeLibObjCBridge.assert_sent(:setTabIcons, times: 1,
        args: [target, "1.circle,"])
      FakeLibObjCBridge.refute_sent(:setSelectedTintColor)
      FakeLibObjCBridge.refute_sent(:setSelectedIndex)
    end
  end

  describe "#populate_sheet" do
    it "skips detents at default ([:medium, :large])" do
      view = UI::Sheet.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_sheet(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setDetents)
      FakeLibObjCBridge.refute_sent(:setShowsDragIndicator)
    end

    it "emits setDetents when overridden" do
      view = UI::Sheet.new
      view.detents = [:small, :large]
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_sheet(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setDetents, times: 1,
        args: [target, "small,large"])
    end
  end

  describe "#populate_popover" do
    it "skips arrowEdge at default :bottom" do
      view = UI::Popover.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_popover(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setArrowEdge)
    end
  end

  describe "#populate_alert" do
    it "emits buttonLabels + buttonStyles when buttons set" do
      view = UI::Alert.new("Title")
      view.add_button("OK", :default)
      view.add_button("Cancel", :cancel)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_alert(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setButtonLabels, times: 1,
        args: [target, "OK,Cancel"])
      FakeLibObjCBridge.assert_sent(:setButtonStyles, times: 1,
        args: [target, "default,cancel"])
    end
  end

  describe "#populate_confirmation_dialog" do
    it "skips confirmLabel + cancelLabel at defaults" do
      view = UI::ConfirmationDialog.new("Delete?")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_confirmation_dialog(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setConfirmLabel)
      FakeLibObjCBridge.refute_sent(:setCancelLabel)
      FakeLibObjCBridge.refute_sent(:setConfirmStyle)
    end

    it "emits setConfirmStyle when destructive" do
      view = UI::ConfirmationDialog.new("Delete?")
      view.confirm_style = :destructive
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_confirmation_dialog(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setConfirmStyle, times: 1,
        args: [target, "destructive"])
    end
  end

  describe "#populate_toolbar" do
    it "skips item arrays when items list empty" do
      view = UI::Toolbar.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_toolbar(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setItemLabels)
    end

    it "emits parallel arrays when items added" do
      view = UI::Toolbar.new("Files")
      view.add_item("save", "Save", "square.and.arrow.down")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_toolbar(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setItemLabels, times: 1,
        args: [target, "Save"])
      FakeLibObjCBridge.assert_sent(:setItemIcons, times: 1,
        args: [target, "square.and.arrow.down"])
    end
  end

  describe "#populate_form" do
    it "emits sectionFieldCounts + flat sectionFieldLabels when sections present" do
      view = UI::Form.new
      sec = view.add_section(header: "Account")
      sec.fields << UI::Form::Field.new(label: "Name")
      sec.fields << UI::Form::Field.new(label: "Email")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_form(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setSectionFieldCounts, times: 1,
        args: [target, "2"])
      FakeLibObjCBridge.assert_sent(:setSectionFieldLabels, times: 1,
        args: [target, "Name,Email"])
      FakeLibObjCBridge.assert_sent(:setSectionHeaders, times: 1,
        args: [target, "Account"])
    end
  end

  describe "#populate_grid" do
    it "emits rowCellCounts when rows added" do
      view = UI::Grid.new
      view.add_row([UI::Label.new("a"), UI::Label.new("b")] of UI::View)
      view.add_row([UI::Label.new("c")] of UI::View)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_grid(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setRowCellCounts, times: 1,
        args: [target, "2,1"])
    end

    it "skips spacing setters at defaults" do
      view = UI::Grid.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_grid(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setRowSpacing)
      FakeLibObjCBridge.refute_sent(:setColumnSpacing)
    end
  end

  describe "#populate_card" do
    it "skips title + isOutlined + elevation at defaults" do
      view = UI::Card.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_card(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setTitle)
      FakeLibObjCBridge.refute_sent(:setIsOutlined)
      FakeLibObjCBridge.refute_sent(:setElevation)
      FakeLibObjCBridge.refute_sent(:setMaterial)
    end

    it "emits setTitle when set" do
      view = UI::Card.new
      view.title = "Header"
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_card(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setTitle, times: 1, args: [target, "Header"])
    end
  end

  describe "#populate_surface" do
    it "skips elevation + tonalElevation + shape at defaults" do
      view = UI::Surface.new
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_surface(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setElevation)
      FakeLibObjCBridge.refute_sent(:setTonalElevation)
      FakeLibObjCBridge.refute_sent(:setShape)
    end
  end

  describe "#populate_menu_button" do
    it "skips itemLabels when items list empty" do
      view = UI::MenuButton.new("Options")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_menu_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setItemLabels)
      FakeLibObjCBridge.refute_sent(:setIsPullDown)
    end

    it "emits parallel item arrays" do
      view = UI::MenuButton.new("Edit")
      view.add_item("Copy", "doc.on.doc")
      view.add_item("Delete", "trash", is_destructive: true)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_menu_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setItemLabels, times: 1,
        args: [target, "Copy,Delete"])
      FakeLibObjCBridge.assert_sent(:setItemIsDestructive, times: 1,
        args: [target, "false,true"])
    end
  end

  describe "#populate_toggle_button" do
    it "skips icon + isSelected at defaults" do
      view = UI::ToggleButton.new("Bold")
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_toggle_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.refute_sent(:setIcon)
      FakeLibObjCBridge.refute_sent(:setIsSelected)
    end

    it "emits setIsSelected when toggled on" do
      view = UI::ToggleButton.new("Bold", is_selected: true)
      target = FakeLibObjCBridge.next_sentinel_pointer
      UI::Native::Populator.populate_toggle_button(target, view, RecordingSender.new)
      FakeLibObjCBridge.assert_sent(:setIsSelected, times: 1, args: [target, "true"])
    end
  end
end
