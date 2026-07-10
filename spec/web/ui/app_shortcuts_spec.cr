require "spec"
require "json"
require "../../../src/ui"

describe UI::AppShortcuts do
  it "collects shortcut metadata and exports a structured payload" do
    shortcuts = UI::AppShortcuts.new(
      "Asset Pipeline",
      bundle_identifier: "com.example.asset-pipeline"
    )

    shortcut = shortcuts.add_shortcut(
      "Export Preview",
      subtitle: "Render the current design",
      summary: "Exports the selected preview as PNG",
      icon: "square.and.arrow.down",
      phrases: ["Export preview", "Save current preview"]
    ) do |entry|
      entry.add_parameter(
        "format",
        prompt: "Choose an export format",
        type: "string",
        default_value: "png"
      )
    end

    shortcut.identifier.should eq("export-preview")
    shortcut.phrases.should eq(["Export preview", "Save current preview"])
    shortcut.parameters.size.should eq(1)

    payload = JSON.parse(shortcuts.to_payload)
    payload["application_name"].as_s.should eq("Asset Pipeline")
    payload["bundle_identifier"].as_s.should eq("com.example.asset-pipeline")

    exported = payload["shortcuts"].as_a.first
    exported["identifier"].as_s.should eq("export-preview")
    exported["title"].as_s.should eq("Export Preview")
    exported["phrases"].as_a.map(&.as_s).should eq(["Export preview", "Save current preview"])
    exported["parameters"].as_a.first["name"].as_s.should eq("format")
  end

  it "exports an AppIntents scaffold with deterministic naming" do
    shortcuts = UI::AppShortcuts.new(
      "Asset Pipeline",
      bundle_identifier: "com.example.asset-pipeline"
    )

    shortcuts.add_shortcut(
      "Export Preview",
      subtitle: "Render the current design",
      summary: "Exports the selected preview as PNG",
      icon: "square.and.arrow.down",
      phrases: ["Export preview", "Save current preview"]
    ) do |entry|
      entry.add_parameter(
        "format",
        prompt: "Choose an export format",
        type: "string",
        default_value: "png"
      )
    end

    scaffold = shortcuts.export_app_intents_scaffold
    scaffold.should contain("import AppIntents")
    scaffold.should contain("enum AssetPipelineAppIntentsScaffold")
    scaffold.should contain("static let applicationName = \"Asset Pipeline\"")
    scaffold.should contain("static let bundleIdentifier = \"com.example.asset-pipeline\"")
    scaffold.should contain("static let shortcuts: [AppShortcutSpec] = [")
    scaffold.should contain("AppShortcutSpec(")
    scaffold.should contain("AppShortcutParameterSpec(")
    scaffold.should contain("specTypeName: \"ExportPreviewShortcutSpec\"")
    scaffold.should contain("intentTypeName: \"ExportPreviewIntent\"")
    scaffold.should contain("struct ExportPreviewIntent: AppIntent")
    scaffold.should contain("static var title: LocalizedStringResource { \"Export Preview\" }")
    scaffold.should contain("static var description = IntentDescription(\"Exports the selected preview as PNG\")")
    scaffold.should contain("Summary(\"Export Preview\")")
    scaffold.should contain("isEnabled: true")
  end

  it "removes and clears shortcuts by identifier" do
    shortcuts = UI::AppShortcuts.new("Asset Pipeline")
    shortcuts.add_shortcut("Open Preview", identifier: "open-preview")
    shortcuts.add_shortcut("Refresh Metadata", identifier: "refresh-metadata")

    shortcuts.find_shortcut("open-preview").should_not be_nil
    shortcuts.remove_shortcut("open-preview").should be_true
    shortcuts.find_shortcut("open-preview").should be_nil

    shortcuts.clear
    shortcuts.shortcuts.should be_empty
  end
end
