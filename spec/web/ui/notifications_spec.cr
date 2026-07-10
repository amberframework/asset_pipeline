require "spec"
require "../../../src/ui"

describe UI::NotificationRequest do
  it "generates an identifier when omitted" do
    request = UI::NotificationRequest.new("Build finished", "Your export is ready.")
    request.identifier.should start_with("ui-notification-")
  end

  it "keeps caller-provided metadata" do
    request = UI::NotificationRequest.new(
      "Backup complete",
      "Archive synced to iCloud.",
      identifier: "backup-complete",
      subtitle: "Nightly job",
      delay_seconds: 30.0,
      repeats: true,
      sound: false,
      badge: 3,
      thread_id: "sync-status"
    )

    request.identifier.should eq("backup-complete")
    request.subtitle.should eq("Nightly job")
    request.delay_seconds.should eq(30.0)
    request.repeats.should be_true
    request.sound.should be_false
    request.badge.should eq(3)
    request.thread_id.should eq("sync-status")
  end

  it "clamps non-positive delays to a visible minimum" do
    request = UI::NotificationRequest.new("Ping", "Body", delay_seconds: 0.0)
    request.effective_delay_seconds.should eq(0.25)
  end

  it "clamps repeating notifications to the platform minimum" do
    request = UI::NotificationRequest.new("Reminder", "Stand up", delay_seconds: 5.0, repeats: true)
    request.effective_delay_seconds.should eq(60.0)
  end
end

describe UI::NotificationsCatalog do
  it "exports notification categories and actions deterministically" do
    catalog = UI::NotificationsCatalog.new(
      "Asset Pipeline",
      bundle_identifier: "com.example.asset-pipeline"
    )

    catalog.add_category("shipping-updates") do |category|
      category.add_intent_identifier("com.example.track-shipment")
      category.add_option("custom_dismiss_action")
      category.add_action(
        "mark-read",
        "Mark Read",
        options: ["foreground"]
      )
      category.add_action(
        "reply",
        "Reply",
        kind: "text_input",
        options: ["authenticationRequired"],
        text_input_button_title: "Send",
        text_input_placeholder: "Write a reply"
      )
    end

    catalog.add_category(
      "orders",
      options: ["hidden_previews_show_title", "allow_in_car_play"]
    ) do |category|
      category.add_action("open-order", "Open Order", options: ["foreground"])
    end

    manifest = catalog.export_manifest
    manifest.should contain("\"application_name\":\"Asset Pipeline\"")
    manifest.should contain("\"bundle_identifier\":\"com.example.asset-pipeline\"")
    manifest.should contain("\"categories\"")
    manifest.should contain("\"identifier\":\"orders\"")
    manifest.should contain("\"identifier\":\"shipping-updates\"")
    manifest.should contain("\"kind\":\"text_input\"")
    manifest.should contain("\"reply\"")
    manifest.should contain("\"mark-read\"")

    scaffold = catalog.export_swift_scaffold
    scaffold.should contain("import UserNotifications")
    scaffold.should contain("public enum AssetPipelineNotifications")
    scaffold.should contain("public static var categories: Set<UNNotificationCategory>")
    scaffold.should contain("UNNotificationCategory(")
    scaffold.should contain("UNNotificationAction(")
    scaffold.should contain("UNTextInputNotificationAction(")
    scaffold.should contain("UNUserNotificationCenter.current().setNotificationCategories(categories)")
    scaffold.should contain("customDismissAction")
    scaffold.should contain("hiddenPreviewsShowTitle")
    scaffold.should contain("allowInCarPlay")
    scaffold.should contain("\"orders\"")
    scaffold.should contain("\"shipping-updates\"")

    scaffold.should eq(catalog.export_swift_scaffold)
    manifest.should eq(catalog.export_manifest)
  end

  it "adds, finds, and removes categories" do
    catalog = UI::NotificationsCatalog.new("Asset Pipeline")
    catalog.add_category("alerts")
    catalog.find_category("alerts").not_nil!.identifier.should eq("alerts")
    catalog.remove_category("alerts").should be_true
    catalog.find_category("alerts").should be_nil
    catalog.clear
    catalog.categories.should be_empty
  end
end
