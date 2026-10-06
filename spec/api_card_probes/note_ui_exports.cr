require "./probe_support"

vstack = UI::VStack.new(8.0, UI::Alignment::Leading)
widgets = UI::Widgets.new("Notes", "org.example.notes")
color = UI::Color.new(r: 0.96, g: 0.65, b: 0.13, a: 0.42)
toggle = UI::Toggle.new("Completed")
toggle.style = UI::ToggleStyle::Checkbox
toggle.disabled = true

typeof(vstack).should eq(UI::VStack)
typeof(widgets).should eq(UI::Widgets)
typeof(color).should eq(UI::Color)
typeof(toggle.disabled).should eq(Bool)
