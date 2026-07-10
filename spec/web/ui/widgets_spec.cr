require "spec"
require "json"
require "../../../src/ui"

describe UI::Widgets do
  it "collects widget metadata and exports a structured payload" do
    widgets = UI::Widgets.new(
      "Asset Pipeline",
      bundle_identifier: "com.example.asset-pipeline"
    )

    widget = widgets.add_widget(
      "Daily Summary",
      summary: "Shows the current build status and latest export"
    ) do |entry|
      entry.add_placement(
        "home_screen",
        families: ["systemSmall", "systemMedium"],
        timeline_intent: "scheduled",
        refresh_policy: "after:15m"
      ) do |placement|
        placement.add_family("systemLarge")
      end
    end

    widget.identifier.should eq("daily-summary")
    widget.placements.size.should eq(1)
    widget.placements.first.families.should eq(["systemSmall", "systemMedium", "systemLarge"])

    payload = JSON.parse(widgets.to_payload)
    payload["application_name"].as_s.should eq("Asset Pipeline")
    payload["bundle_identifier"].as_s.should eq("com.example.asset-pipeline")

    exported = payload["widgets"].as_a.first
    exported["identifier"].as_s.should eq("daily-summary")
    exported["title"].as_s.should eq("Daily Summary")
    exported["placements"].as_a.first["surface"].as_s.should eq("home_screen")
    exported["placements"].as_a.first["timeline_intent"].as_s.should eq("scheduled")
  end

  it "exports a WidgetKit scaffold with concrete extension stubs" do
    widgets = UI::Widgets.new(
      "Asset Pipeline",
      bundle_identifier: "com.example.asset-pipeline"
    )

    widgets.add_widget(
      "Daily Summary",
      summary: "Shows the current build status and latest export"
    ) do |entry|
      entry.add_placement(
        "home_screen",
        families: ["systemSmall", "systemMedium"],
        timeline_intent: "scheduled",
        refresh_policy: "after:15m"
      ) do |placement|
        placement.add_family("systemLarge")
      end
    end

    scaffold = widgets.export_widgetkit_scaffold
    scaffold.should contain("import WidgetKit")
    scaffold.should contain("enum AssetPipelineWidgetKitScaffold")
    scaffold.should contain("static let applicationName = \"Asset Pipeline\"")
    scaffold.should contain("static let bundleIdentifier = \"com.example.asset-pipeline\"")
    scaffold.should contain("static let widgets: [WidgetSpec] = [")
    scaffold.should contain("WidgetSpec(")
    scaffold.should contain("WidgetPlacementSpec(")
    scaffold.should contain("DailySummaryWidget: Widget")
    scaffold.should contain("StaticConfiguration(kind: \"daily-summary\"")
    scaffold.should contain(".configurationDisplayName(\"Daily Summary\")")
    scaffold.should contain(".description(\"Shows the current build status and latest export\")")
    scaffold.should contain(".supportedFamilies([.systemSmall, .systemMedium, .systemLarge])")
    scaffold.should contain("struct DailySummaryProvider: TimelineProvider")
    scaffold.should contain("struct DailySummaryEntry: TimelineEntry")
    scaffold.should contain("struct DailySummaryWidgetView: View")
    scaffold.should contain("Text(\"Daily Summary\")")
  end

  it "normalizes supported family names for widgetkit output" do
    widget = UI::Widget.new("Compact Status", identifier: "compact-status")
    widget.add_placement(
      "lock_screen",
      families: ["system_small", "accessory_rectangular", "systemSmall"]
    )

    widget.widgetkit_supported_families.should eq(["systemSmall", "accessoryRectangular"])

    scaffold = widget.export_widgetkit_scaffold
    scaffold.should contain(".supportedFamilies([.systemSmall, .accessoryRectangular])")
  end

  it "removes and clears widget declarations" do
    widgets = UI::Widgets.new("Asset Pipeline")
    widgets.add_widget("Inbox Status", identifier: "inbox-status")
    widgets.add_widget("Queue Health", identifier: "queue-health")

    widgets.find_widget("inbox-status").should_not be_nil
    widgets.remove_widget("inbox-status").should be_true
    widgets.find_widget("inbox-status").should be_nil

    widgets.clear
    widgets.widgets.should be_empty
  end
end
