require "spec"
require "../../../src/ui"

# UI::StatusBarAppearance is universal (no widget refs); the UI::StatusBar
# model itself references UI::ContextMenu (Tier 3 Apple-family only) so
# its specs are gated.
describe UI::StatusBarAppearance do
  it "captures iOS status-bar policy without pretending to render chrome" do
    appearance = UI::StatusBarAppearance.new(
      style: UI::StatusBarContentStyle::LightContent,
      hidden: true,
      animated: false
    )

    appearance.style.should eq(UI::StatusBarContentStyle::LightContent)
    appearance.hidden.should be_true
    appearance.animated.should be_false
  end
end

{% if flag?(:macos) || flag?(:ios) %}
  describe UI::StatusBar do
    it "captures a status item with an attached menu" do
      item = UI::StatusBar.new(
        identifier: "sync",
        title: "Sync",
        icon: "arrow.triangle.2.circlepath",
        tooltip: "Sync status"
      )

      menu = item.with_menu do |m|
        m.add_item("Pause Sync")
        m.add_item("Open Activity")
        m.add_item("Quit", icon: "xmark")
      end

      item.identifier.should eq("sync")
      item.title.should eq("Sync")
      item.icon.should eq("arrow.triangle.2.circlepath")
      item.tooltip.should eq("Sync status")
      item.menu.should eq(menu)
      menu.items.size.should eq(3)
    end

    it "attaches a menu without mutating the identifier" do
      item = UI::StatusBar.new
      menu = UI::ContextMenu.new
      menu.add_item("Open")

      item.attach(menu)
      item.identifier.should eq("status-item")
      item.menu.should eq(menu)
    end
  end
{% end %}
