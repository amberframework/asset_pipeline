require "./probe_support"

toggle = UI::Toggle.new("Completed")
toggle.style = UI::ToggleStyle::Checkbox
toggle.disabled = true
typeof(toggle.disabled).should eq(Bool)
