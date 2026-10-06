require "./probe_support"

sheet = UI::ActionSheet.new("Delete note?", "This action cannot be undone.")
sheet.add_action("Delete", style: :destructive) { nil }
sheet.add_action("Cancel", style: :cancel)
typeof(sheet.primary_action).should eq(UI::ActionSheet::Action?)
typeof(sheet.cancel_action).should eq(UI::ActionSheet::Action?)
