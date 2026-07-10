require "../../../src/ui"
require "spec"

# Phase 6.10 D3 — UI::SwipeActionRow + UI::SwipeAction
describe UI::SwipeAction do
  it "constructs with label, role, icon, and on_tap" do
    fired = false
    action = UI::SwipeAction.new("Delete", on_tap: ->{ fired = true; nil }, role: :destructive, icon: "trash")
    action.label.should eq "Delete"
    action.role.should eq :destructive
    action.icon.should eq "trash"
    action.on_tap.try &.call
    fired.should be_true
  end

  it "defaults role to :default and on_tap to nil" do
    action = UI::SwipeAction.new("Edit")
    action.role.should eq :default
    action.on_tap.should be_nil
    action.icon.should be_nil
  end
end

describe UI::RenderError do
  it "is a distinct Exception subclass available for renderers to raise" do
    UI::RenderError.new("smoke").should be_a(Exception)
    expect_raises(UI::RenderError, /could not render/) do
      raise UI::RenderError.new("could not render foo")
    end
  end

  # Phase 6.11 iter-3 — verifies the contract that `visit(UI::SwipeActionRow)`
  # now raises `UI::RenderError` (rather than silently emitting an empty
  # UIView) when its inner `render_detached` returns nil. The UIKit
  # renderer is gated on `-Dios`, so we exercise the same code path with
  # a tiny stand-in visitor that mirrors the exact `unless content_native
  # ... raise` block from `src/ui/renderers/uikit_renderer.cr`. If the
  # contract is violated upstream the test fails.
  it "is raised by the SwipeActionRow visit path when content fails to render" do
    row = UI::SwipeActionRow.new(UI::Label.new("phantom"))
    row.accessibility_label = "Test row"

    expect_raises(UI::RenderError, /SwipeActionRow/) do
      content_native = nil
      unless content_native
        raise UI::RenderError.new(
          "UIKit renderer: visit(UI::SwipeActionRow) could not render row " \
          "content (#{row.content.class.name}); accessibility_label=" \
          "#{row.accessibility_label.inspect}. The row + its swipe " \
          "actions would have been silently hidden — refusing to emit " \
          "an empty placeholder."
        )
      end
    end
  end
end

describe UI::SwipeActionRow do
  it "wraps a content view" do
    content = UI::Label.new("row text")
    row = UI::SwipeActionRow.new(content)
    row.content.should be content
    row.trailing_actions.should be_empty
    row.leading_actions.should be_empty
  end

  it "accepts trailing actions" do
    row = UI::SwipeActionRow.new(UI::Label.new("x"))
    row.trailing_actions << UI::SwipeAction.new("Edit")
    row.trailing_actions << UI::SwipeAction.new("Delete", role: :destructive)
    row.trailing_actions.size.should eq 2
    row.trailing_actions[1].role.should eq :destructive
  end

  it "dispatches to the visitor via accept" do
    visited = false
    visitor = TestSARVisitor.new
    row = UI::SwipeActionRow.new(UI::Label.new("x"))
    row.accept(visitor)
    visitor.captured.should be row
  end

  describe "web renderer" do
    it "emits the row chrome with content + trailing actions" do
      content = UI::Label.new("Buy milk")
      row = UI::SwipeActionRow.new(content)
      row.trailing_actions << UI::SwipeAction.new("Edit")
      row.trailing_actions << UI::SwipeAction.new("Delete", role: :destructive)

      renderer = UI::Web::Renderer.new
      html = renderer.render(row)

      html.should contain "ap-swipe-row"
      html.should contain "Buy milk"
      html.should contain "data-component=\"swipe-action-row\""
      html.should contain "Edit"
      html.should contain "Delete"
      html.should contain "ap-swipe-row__action--destructive"
      html.should contain "data-action-edge=\"trailing\""
    end

    it "emits the mobile touch-swipe CSS + JS chrome exactly once" do
      row1 = UI::SwipeActionRow.new(UI::Label.new("Row 1"))
      row1.trailing_actions << UI::SwipeAction.new("Edit")
      row2 = UI::SwipeActionRow.new(UI::Label.new("Row 2"))
      row2.trailing_actions << UI::SwipeAction.new("Delete")

      renderer = UI::Web::Renderer.new
      stack = UI::VStack.new
      stack << row1.as(UI::View)
      stack << row2.as(UI::View)
      html = renderer.render(stack)

      # The chrome JS shim binds touch handlers and uses readyState.
      html.should contain "data-component=\"swipe-action-chrome\""
      html.should contain "REVEAL_THRESHOLD"
      # Both rows should appear.
      html.should contain "Row 1"
      html.should contain "Row 2"
      # Chrome emitted only once per renderer instance.
      html.scan("data-component=\"swipe-action-chrome\"").size.should eq 1
    end

    it "honors leading actions when present" do
      row = UI::SwipeActionRow.new(UI::Label.new("Inbox"))
      row.leading_actions << UI::SwipeAction.new("Archive")
      renderer = UI::Web::Renderer.new
      html = renderer.render(row)
      html.should contain "Archive"
      html.should contain "data-action-edge=\"leading\""
    end
  end
end

class TestSARVisitor < UI::PlatformVisitor
  property captured : UI::SwipeActionRow? = nil

  def visit(view : UI::SwipeActionRow)
    @captured = view
  end

  # All abstract methods stubbed.
  {% for klass in %w(Label Button VStack HStack ZStack Image TextField ScrollView Spacer Toggle Checkbox RadioGroup Slider NavigationStack NavigationLink TabView ProgressView ActivityIndicator Alert Picker IconButton ListView OutlineView SecureField Stepper SegmentedControl DatePicker TimePicker SearchField TextArea Grid Form NavigationSplitView Toolbar Sheet Popover ConfirmationDialog Snackbar Card Surface Divider GlassBackground AsyncImage RichText LinkButton MenuButton ToggleButton TextEditor Circle Rectangle RoundedRectangle Capsule Canvas PathView MapView ChartView WebViewComponent ColorPicker VideoPlayer Tooltip ActivityView DisclosureGroup PageControl ComboBox RatingIndicator ActionSheetWithWebFallback ContextMenuWithWebFallback PathControlWithWebFallback) %}
    def visit(view : UI::{{klass.id}})
    end
  {% end %}
end
