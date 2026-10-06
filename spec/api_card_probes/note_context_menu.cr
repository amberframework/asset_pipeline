require "./probe_support"

menu = UI::ContextMenu.new
typeof(menu.add_item("Edit")).should eq(Array(UI::ContextMenu::Entry))
typeof(menu.add_item("Delete", is_destructive: true) { nil }).should eq(Array(UI::ContextMenu::Entry))
typeof(menu.add_separator).should eq(Array(UI::ContextMenu::Entry))
