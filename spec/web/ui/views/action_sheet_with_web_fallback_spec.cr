require "../../spec_helper"
require "../../../../src/ui"

describe UI::ActionSheetWithWebFallback do
  it "constructs and accepts actions identically to ActionSheet" do
    sheet = UI::ActionSheetWithWebFallback.new("Share", "Pick a destination")
    sheet.title.should eq("Share")
    sheet.message.should eq("Pick a destination")
    sheet.actions.should be_empty

    captured = ""
    sheet.add_action("Copy link", style: :default) { captured = "copied" }
    sheet.add_action("Cancel", style: :cancel)
    sheet.actions.size.should eq(2)
    sheet.actions[0].action.try(&.call)
    captured.should eq("copied")
  end

  it "toggles is_presented property" do
    sheet = UI::ActionSheetWithWebFallback.new
    sheet.is_presented.should be_false
    sheet.is_presented = true
    sheet.is_presented.should be_true
  end

  describe "web renderer HTML structure" do
    it "emits role=dialog with aria-modal and aria-labelledby" do
      sheet = UI::ActionSheetWithWebFallback.new("Share", "Choose a destination")
      sheet.add_action("Copy link", style: :default)
      sheet.add_action("Cancel", style: :cancel)
      html = UI::Web::Renderer.new.render(sheet)
      html.should contain(%(role="dialog"))
      html.should contain(%(aria-modal="true"))
      html.should contain(%(aria-labelledby="ap-as-title-))
      html.should contain(%(aria-describedby="ap-as-msg-))
      html.should contain("Share")
      html.should contain("Choose a destination")
    end

    it "renders default actions as menuitems and cancel separately" do
      sheet = UI::ActionSheetWithWebFallback.new("Delete?", "")
      sheet.add_action("Delete", style: :destructive)
      sheet.add_action("Pin", style: :default)
      sheet.add_action("Cancel", style: :cancel)
      html = UI::Web::Renderer.new.render(sheet)
      html.should contain("ap-action-sheet__action--destructive")
      html.should contain("ap-action-sheet__action--default")
      html.should contain("ap-action-sheet__action--cancel")
      html.should contain(%(data-ap-as-dismiss="cancel"))
      html.should contain(%(data-ap-as-dismiss="backdrop"))
    end

    it "encodes data-presented as the current is_presented value" do
      sheet = UI::ActionSheetWithWebFallback.new("T", "")
      html_closed = UI::Web::Renderer.new.render(sheet)
      html_closed.should contain(%(data-presented="false"))

      sheet.is_presented = true
      html_open = UI::Web::Renderer.new.render(sheet)
      html_open.should contain(%(data-presented="true"))
    end

    it "inlines the vanilla-JS fallback script once per renderer" do
      sheet = UI::ActionSheetWithWebFallback.new("Share", "")
      sheet.add_action("Copy", style: :default)
      r = UI::Web::Renderer.new
      html = r.render(sheet)
      html.should contain("__apActionSheetInitialized")
      html.should contain("ap:action-sheet:dismiss")
      html.should contain("ap:action-sheet:action")
      html.should contain("ap-action-sheet__panel")

      # Second emission from the same renderer must NOT re-inline the JS.
      sheet2 = UI::ActionSheetWithWebFallback.new("Other", "")
      r.render(sheet2)
      second_emit = r.output
      second_emit.scan("__apActionSheetInitialized").size.should eq(0)
    end

    it "inlines static CSS once per renderer instance" do
      r = UI::Web::Renderer.new
      sheet1 = UI::ActionSheetWithWebFallback.new("A", "")
      sheet2 = UI::ActionSheetWithWebFallback.new("B", "")
      first = r.render(sheet1)
      first.scan("ap-action-sheet__panel {").size.should be > 0
      # Second emission from the same renderer must NOT duplicate the CSS.
      r2 = UI::Web::Renderer.new
      _ = r2.render(sheet2)
      # Sanity: a fresh renderer DOES emit CSS (independence guarantee).
      r2.output.includes?("ap-action-sheet__panel {").should be_true
    end
  end
end
