require "../../spec_helper"
require "../../../../src/ui"

# UI::ActionSheet is Tier 3 (iOS-only) — these specs only run on -Dios.
# The compile-error contract on every other target is asserted by
# spec/ui/views/action_sheet_compile_error_spec.cr.
{% if flag?(:ios) %}
  describe UI::ActionSheet do
    it "constructs with default title and message" do
      sheet = UI::ActionSheet.new
      sheet.title.should eq("")
      sheet.message.should eq("")
      sheet.actions.should be_empty
      sheet.is_presented.should be_false
    end

    it "constructs with explicit title and message" do
      sheet = UI::ActionSheet.new("Delete?", "This cannot be undone.")
      sheet.title.should eq("Delete?")
      sheet.message.should eq("This cannot be undone.")
    end

    it "accumulates actions via add_action with a block" do
      sheet = UI::ActionSheet.new("Title")
      fired = 0
      sheet.add_action("Delete", style: :destructive) { fired += 1 }
      sheet.add_action("Cancel", style: :cancel) { }
      sheet.actions.size.should eq(2)
      sheet.actions[0].label.should eq("Delete")
      sheet.actions[0].style.should eq(:destructive)
      sheet.actions[1].style.should eq(:cancel)
      sheet.actions[0].action.try(&.call)
      fired.should eq(1)
    end

    it "supports add_action without a block" do
      sheet = UI::ActionSheet.new
      sheet.add_action("Pin", style: :default)
      sheet.actions.size.should eq(1)
      sheet.actions[0].action.should be_nil
    end

    it "exposes #primary_action as the first non-cancel action" do
      sheet = UI::ActionSheet.new("T")
      sheet.add_action("Cancel", style: :cancel)
      sheet.add_action("Delete", style: :destructive)
      sheet.add_action("Mute", style: :default)
      primary = sheet.primary_action
      primary.should_not be_nil
      primary.not_nil!.label.should eq("Delete")
    end

    it "exposes #cancel_action when one was added" do
      sheet = UI::ActionSheet.new("T")
      sheet.add_action("Save", style: :default)
      sheet.cancel_action.should be_nil
      sheet.add_action("Cancel", style: :cancel)
      sheet.cancel_action.not_nil!.label.should eq("Cancel")
    end
  end
{% end %}
