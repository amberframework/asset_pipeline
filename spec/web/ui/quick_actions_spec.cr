require "spec"
require "../../../src/ui"

describe UI::QuickActionsCatalog do
  it "collects shortcut item metadata into a manifest" do
    catalog = UI::QuickActionsCatalog.new
    catalog.add_action(
      type: "com.assetpipeline.capture",
      title: "Capture Preview",
      subtitle: "Open today's HIG batch",
      system_image: "camera.viewfinder",
      user_info: {"slug" => "activity-rings"}
    )

    manifest = catalog.to_json
    manifest.should contain("com.assetpipeline.capture")
    manifest.should contain("camera.viewfinder")
    manifest.should contain("activity-rings")
  end

  it "exports a plist fragment for UIApplicationShortcutItems" do
    catalog = UI::QuickActionsCatalog.new
    catalog.add_action(
      type: "com.assetpipeline.review",
      title: "Review Status",
      system_image: "checklist"
    )

    plist = UI::HomeScreenQuickActions.export_plist_fragment(catalog)
    plist.should contain("UIApplicationShortcutItemType")
    plist.should contain("com.assetpipeline.review")
    plist.should contain("checklist")
  end

  it "can be applied and cleared as system-owned Home Screen metadata" do
    catalog = UI::QuickActionsCatalog.new
    catalog.add_action(
      type: "com.assetpipeline.compose",
      title: "Compose",
      system_image: "square.and.pencil"
    )

    catalog.apply.should be_false
    catalog.is_applied.should be_false
    catalog.clear
    catalog.actions.should be_empty
    catalog.is_applied.should be_false
  end
end
