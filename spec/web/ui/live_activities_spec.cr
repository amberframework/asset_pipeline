require "spec"
require "json"
require "../../../src/ui"

describe UI::LiveActivities do
  it "collects attributes, content state, and update intent metadata" do
    live_activities = UI::LiveActivities.new(
      "Asset Pipeline",
      bundle_identifier: "com.example.asset-pipeline"
    )

    activity = live_activities.add_activity("RideStatusAttributes") do |entry|
      entry.add_attribute("driver_name", "Avery")
      entry.add_attribute("phase", "enroute")
      entry.add_content_state_field("eta_minutes", "12")
      entry.add_content_state_field("progress", "0.64")
      entry.build_update_intent(
        "open-ride",
        title: "Open Ride",
        subtitle: "Bring the app to the foreground",
        system_image: "car",
        user_info: {"ride_id" => "ride-42"}
      )
    end

    activity.identifier.should eq("ride-status-attributes")
    activity.attributes_type.should eq("RideStatusAttributes")
    activity.attributes["driver_name"].should eq("Avery")
    activity.content_state["progress"].should eq("0.64")
    activity.update_intent.not_nil!.identifier.should eq("open-ride")

    payload = JSON.parse(live_activities.to_payload)
    payload["application_name"].as_s.should eq("Asset Pipeline")
    payload["bundle_identifier"].as_s.should eq("com.example.asset-pipeline")

    exported = payload["activities"].as_a.first
    exported["identifier"].as_s.should eq("ride-status-attributes")
    exported["attributes_type"].as_s.should eq("RideStatusAttributes")
    exported["attributes"].as_h["driver_name"].as_s.should eq("Avery")
    exported["content_state"].as_h["eta_minutes"].as_s.should eq("12")
    exported["update_intent"].as_h["identifier"].as_s.should eq("open-ride")
  end

  it "removes and clears activities" do
    live_activities = UI::LiveActivities.new("Asset Pipeline")
    live_activities.add_activity("RideStatusAttributes", identifier: "ride-1")
    live_activities.add_activity("DeliveryAttributes", identifier: "delivery-1")

    live_activities.find_activity("ride-1").should_not be_nil
    live_activities.remove_activity("ride-1").should be_true
    live_activities.find_activity("ride-1").should be_nil

    live_activities.clear
    live_activities.activities.should be_empty
  end

  it "exports a deterministic ActivityKit scaffold" do
    live_activities = UI::LiveActivities.new(
      "Asset Pipeline",
      bundle_identifier: "com.example.asset-pipeline"
    )

    live_activities.add_activity("RideStatusAttributes", identifier: "ride-1") do |entry|
      entry.add_attribute("phase", "enroute")
      entry.add_attribute("driver_name", "Avery")
      entry.add_content_state_field("progress", "0.64")
      entry.add_content_state_field("eta_minutes", "12")
      entry.build_update_intent(
        "open-ride",
        title: "Open Ride",
        subtitle: "Bring the app to the foreground",
        system_image: "car",
        user_info: {"ride_id" => "ride-42", "zone" => "north"}
      )
    end

    scaffold = live_activities.export_activitykit_scaffold
    scaffold.should contain("import ActivityKit")
    scaffold.should contain("import WidgetKit")
    scaffold.should contain("public enum AssetPipelineLiveActivities")
    scaffold.should contain("public struct RideStatusAttributes: ActivityAttributes")
    scaffold.should contain("public var eta_minutes: String")
    scaffold.should contain("public var progress: String")
    scaffold.should contain("public static let identifier = \"ride-1\"")
    scaffold.should contain("public static let attributesType = \"RideStatusAttributes\"")
    scaffold.should contain("public static let updateIntentIdentifier = \"open-ride\"")
    scaffold.should contain("\"ride_id\": \"ride-42\"")
    scaffold.should contain("\"zone\": \"north\"")
    scaffold.should contain("public static let contentStateKeys = [")
    scaffold.should contain("\"eta_minutes\"")
    scaffold.should contain("\"progress\"")

    scaffold.should eq(live_activities.export_activitykit_scaffold)
  end
end
