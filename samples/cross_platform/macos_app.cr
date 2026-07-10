require "../../src/ui"

# Build a comprehensive showcase of all UI components
def build_showcase : UI::View
  root = UI::VStack.new(spacing: 24.0)

  # --- Section: Base Controls ---
  base_section = UI::VStack.new(spacing: 8.0)
  base_section << UI::Label.new("Base Controls")
  base_section << UI::Button.new("Click Me")
  base_section << UI::TextField.new("Enter text...")
  base_section << UI::Image.new("icon_placeholder")
  root << base_section

  # --- Section: Layout ---
  layout_section = UI::VStack.new(spacing: 8.0)
  layout_section << UI::Label.new("Layout Containers")
  row = UI::HStack.new(spacing: 12.0)
  row << UI::Label.new("Left")
  row << UI::Spacer.new
  row << UI::Label.new("Right")
  layout_section << row
  root << layout_section

  # --- Section: Selection Controls ---
  selection = UI::VStack.new(spacing: 8.0)
  selection << UI::Label.new("Selection Controls")
  selection << UI::Toggle.new("Airplane Mode", false)
  selection << UI::Checkbox.new("Accept Terms")
  selection << UI::RadioGroup.new(["Small", "Medium", "Large"], 1)
  selection << UI::Slider.new(0.0, 100.0, 50.0)
  selection << UI::Stepper.new(0.0, 10.0, 5.0)
  selection << UI::SegmentedControl.new(["Day", "Week", "Month"], 0)
  root << selection

  # --- Section: Navigation ---
  nav = UI::VStack.new(spacing: 8.0)
  nav << UI::Label.new("Navigation")
  nav << UI::NavigationLink.new("Go to Details", UI::Label.new("Detail View"))
  tabs = [
    UI::TabView::Tab.new(label: "Home", content: UI::Label.new("Home Tab")),
    UI::TabView::Tab.new(label: "Settings", icon: "gear", content: UI::Label.new("Settings Tab")),
  ]
  nav << UI::TabView.new(tabs, 0)
  root << nav

  # --- Section: Date & Time ---
  datetime = UI::VStack.new(spacing: 8.0)
  datetime << UI::Label.new("Date & Time")
  datetime << UI::DatePicker.new(UI::DatePickerMode::Date)
  datetime << UI::TimePicker.new
  root << datetime

  # --- Section: Text Input ---
  text = UI::VStack.new(spacing: 8.0)
  text << UI::Label.new("Text Input")
  text << UI::SearchField.new("Search items...")
  text << UI::TextArea.new("Enter notes...")
  text << UI::SecureField.new("Password")
  text << UI::TextEditor.new("Code editor...")
  root << text

  # --- Section: Feedback ---
  feedback = UI::VStack.new(spacing: 8.0)
  feedback << UI::Label.new("Feedback & Status")
  feedback << UI::ProgressView.new(0.65, UI::ProgressStyle::Linear)
  feedback << UI::ProgressView.new(nil, UI::ProgressStyle::Circular)
  feedback << UI::ActivityIndicator.new(true, :medium)
  root << feedback

  # --- Section: Pickers ---
  pickers = UI::VStack.new(spacing: 8.0)
  pickers << UI::Label.new("Pickers & Lists")
  pickers << UI::Picker.new(["Red", "Green", "Blue"], 0)
  items = [UI::Label.new("Item 1"), UI::Label.new("Item 2"), UI::Label.new("Item 3")] of UI::View
  pickers << UI::ListView.flat(items)
  root << pickers

  # --- Section: Buttons ---
  buttons = UI::VStack.new(spacing: 8.0)
  buttons << UI::Label.new("Button Variants")
  buttons << UI::IconButton.new("star.fill")
  buttons << UI::LinkButton.new("Visit Website", "https://example.com")
  menu_btn = UI::MenuButton.new("Options")
  menu_btn.add_item("Edit", "pencil")
  menu_btn.add_item("Delete", "trash", true)
  buttons << menu_btn
  buttons << UI::ToggleButton.new("Bold", false)
  root << buttons

  # --- Section: Dialogs & Overlays ---
  overlays = UI::VStack.new(spacing: 8.0)
  overlays << UI::Label.new("Dialogs & Overlays")
  alert = UI::Alert.new("Warning", "This is an alert message")
  alert.add_button("OK")
  overlays << alert
  overlays << UI::ConfirmationDialog.new("Delete?", "This cannot be undone.")
  overlays << UI::Snackbar.new("Item saved", "Undo")
  root << overlays

  # --- Section: Containers ---
  containers = UI::VStack.new(spacing: 8.0)
  containers << UI::Label.new("Containers & Surfaces")
  containers << UI::Card.new(UI::Label.new("Card Content"))
  containers << UI::Surface.new(UI::Label.new("Surface Content"))
  containers << UI::Divider.new
  containers << UI::GlassBackground.new(UI::Label.new("Glass Effect"), :regular)
  root << containers

  # --- Section: Navigation Advanced ---
  nav_adv = UI::VStack.new(spacing: 8.0)
  nav_adv << UI::Label.new("Advanced Navigation")
  sidebar = UI::Label.new("Sidebar")
  content = UI::Label.new("Content Area")
  nav_adv << UI::NavigationSplitView.new(sidebar, content)
  toolbar = UI::Toolbar.new("Editor")
  toolbar.add_item("bold", "Bold")
  toolbar.add_item("italic", "Italic")
  nav_adv << toolbar
  root << nav_adv

  # --- Section: Grid & Form ---
  grid_form = UI::VStack.new(spacing: 8.0)
  grid_form << UI::Label.new("Grid & Form")
  grid = UI::Grid.new([UI::Grid::Column.new, UI::Grid::Column.new])
  grid.add_row([UI::Label.new("Name"), UI::TextField.new("Enter name")] of UI::View)
  grid.add_row([UI::Label.new("Email"), UI::TextField.new("Enter email")] of UI::View)
  grid_form << grid
  root << grid_form

  # --- Section: Rich Content ---
  rich = UI::VStack.new(spacing: 8.0)
  rich << UI::Label.new("Rich Content")
  rt = UI::RichText.new
  rt.add_span("Hello ", bold: true)
  rt.add_span("World", italic: true, color: UI::Color.new(r: 0.0, g: 0.0, b: 1.0))
  rich << rt
  rich << UI::AsyncImage.new("https://example.com/image.png")
  root << rich

  # --- Section: Shapes ---
  shapes = UI::VStack.new(spacing: 8.0)
  shapes << UI::Label.new("Shapes")
  shapes << UI::Circle.new
  shapes << UI::Rectangle.new
  shapes << UI::RoundedRectangle.new(12.0)
  shapes << UI::Capsule.new
  root << shapes

  # --- Section: Drawing ---
  drawing = UI::VStack.new(spacing: 8.0)
  drawing << UI::Label.new("Drawing")
  canvas = UI::Canvas.new
  drawing << canvas
  path = UI::PathView.new
  drawing << path
  root << drawing

  # --- Section: Media ---
  media = UI::VStack.new(spacing: 8.0)
  media << UI::Label.new("Media")
  media << UI::VideoPlayer.new("https://example.com/video.mp4")
  media << UI::WebViewComponent.new("https://example.com")
  media << UI::MapView.new
  media << UI::ChartView.new
  root << media

  # --- Section: Interactive ---
  interactive = UI::VStack.new(spacing: 8.0)
  interactive << UI::Label.new("Interactive")
  interactive << UI::ColorPicker.new
  interactive << UI::Tooltip.new("Hover for info")
  root << interactive

  root
end

# Render the showcase
showcase = build_showcase
renderer = UI::Web::Renderer.new

# Apply theme
theme = UI::Theme.apple_default
renderer.theme = theme

showcase.accept(renderer)

# Build full HTML page
html = String.build do |io|
  io << "<!DOCTYPE html>\n<html>\n<head>\n"
  io << "<meta charset=\"utf-8\">\n"
  io << "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
  io << "<title>Asset Pipeline UI Showcase</title>\n"
  io << "<style>\n"
  io << theme.to_css_custom_properties
  io << "body { font-family: -apple-system, sans-serif; padding: 24px; background: #f5f5f5; }\n"
  io << "@keyframes spin { to { transform: rotate(360deg); } }\n"
  io << "</style>\n"
  io << "</head>\n<body>\n"
  io << "<h1>Asset Pipeline - Cross-Platform UI Component Showcase</h1>\n"
  io << renderer.output
  io << "\n</body>\n</html>\n"
end

# Write to file
output_path = File.join(__DIR__, "showcase.html")
File.write(output_path, html)
puts "Showcase written to #{output_path}"
puts "Total theme CSS custom properties generated"
