require "spec"
require "../../../src/ui"

describe UI::WindowConfiguration do
  it "keeps window identity and chrome intent together" do
    configuration = UI::WindowConfiguration.new(
      "Asset Pipeline",
      subtitle: "Preview shell",
      preferred_size: UI::WindowSize.new(1280.0, 860.0),
      minimum_size: UI::WindowSize.new(960.0, 720.0),
      maximum_size: UI::WindowSize.new(1600.0, 1000.0),
      titlebar_style: UI::WindowTitlebarStyle::UnifiedCompact,
      shows_titlebar: true,
      shows_toolbar: false,
      allows_full_screen: false,
      resizable: true
    )

    configuration.title.should eq("Asset Pipeline")
    configuration.subtitle.should eq("Preview shell")
    configuration.display_title.should eq("Asset Pipeline — Preview shell")
    configuration.preferred_width.should eq(1280.0)
    configuration.preferred_height.should eq(860.0)
    configuration.normalized_preferred_size.should eq(UI::WindowSize.new(1280.0, 860.0))
    configuration.titlebar_style.should eq(UI::WindowTitlebarStyle::UnifiedCompact)
    configuration.shows_titlebar.should be_true
    configuration.shows_toolbar.should be_false
    configuration.allows_full_screen.should be_false
    configuration.resizable.should be_true
  end

  it "clamps a preferred size to the configured bounds" do
    configuration = UI::WindowConfiguration.new(
      "Editor",
      preferred_size: UI::WindowSize.new(2048.0, 1200.0),
      minimum_size: UI::WindowSize.new(960.0, 720.0),
      maximum_size: UI::WindowSize.new(1440.0, 900.0)
    )

    configuration.normalized_preferred_size.should eq(UI::WindowSize.new(1440.0, 900.0))
    configuration.size_summary.should eq("1440.0 x 900.0")
  end
end

describe UI::Windows do
  it "builds a configuration from plain window intent" do
    configuration = UI::Windows.configure(
      title: "Library",
      subtitle: "Inspection",
      preferred_width: 1180.0,
      preferred_height: 820.0,
      minimum_width: 960.0,
      minimum_height: 720.0,
      titlebar_style: UI::WindowTitlebarStyle::Standard,
      shows_toolbar: true,
      allows_full_screen: true,
      resizable: false
    )

    configuration.title.should eq("Library")
    configuration.subtitle.should eq("Inspection")
    configuration.preferred_size.should eq(UI::WindowSize.new(1180.0, 820.0))
    configuration.minimum_size.should eq(UI::WindowSize.new(960.0, 720.0))
    configuration.maximum_size.should be_nil
    configuration.titlebar_style.should eq(UI::WindowTitlebarStyle::Standard)
    configuration.resizable.should be_false
  end

  it "rejects half-specified sizes" do
    expect_raises(ArgumentError, "window width and height must be provided together") do
      UI::Windows.configure(
        title: "Broken",
        preferred_width: 1024.0
      )
    end
  end
end
