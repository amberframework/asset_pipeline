require "../../spec_helper"
require "../../../../src/ui"

describe UI::ContextMenuWithWebFallback do
  it "constructs with empty items" do
    menu = UI::ContextMenuWithWebFallback.new
    menu.items.should be_empty
  end

  it "accumulates items + separators" do
    menu = UI::ContextMenuWithWebFallback.new
    menu.add_item("Open", icon: "doc")
    menu.add_separator
    menu.add_item("Delete", is_destructive: true)
    menu.items.size.should eq(3)
    menu.items[0].should be_a(UI::ContextMenuWithWebFallback::Item)
    menu.items[1].should be_a(UI::ContextMenuWithWebFallback::Separator)
    menu.items[2].as(UI::ContextMenuWithWebFallback::Item).is_destructive.should be_true
  end

  describe "web renderer HTML structure" do
    it "emits role=menu with menuitem children + separator markup" do
      menu = UI::ContextMenuWithWebFallback.new
      menu.add_item("Duplicate", icon: "square.on.square")
      menu.add_separator
      menu.add_item("Delete", is_destructive: true)

      html = UI::Web::Renderer.new.render(menu)
      html.should contain(%(role="menu"))
      html.should contain(%(role="menuitem"))
      html.should contain(%(role="separator"))
      html.should contain("ap-ctx-menu__item--destructive")
      html.should contain(%(data-ap-ctx-action="0"))
      html.should contain(%(data-ap-ctx-action="2"))
    end

    it "inlines the vanilla-JS focus + nav script once per renderer" do
      menu = UI::ContextMenuWithWebFallback.new
      menu.add_item("Pin")
      r = UI::Web::Renderer.new
      html = r.render(menu)
      html.should contain("__apContextMenuInitialized")
      html.should contain("ap:ctx-menu:action")
      html.should contain("ap:ctx-menu:dismiss")
    end

    it "marks disabled items with aria-disabled" do
      menu = UI::ContextMenuWithWebFallback.new
      menu.add_item("Reset", is_disabled: true)
      html = UI::Web::Renderer.new.render(menu)
      html.should contain(%(aria-disabled="true"))
    end

    it "renders an optional trigger as a child of the host" do
      trigger = UI::Button.new("Right-click me")
      menu = UI::ContextMenuWithWebFallback.new(trigger: trigger)
      menu.add_item("Edit")
      html = UI::Web::Renderer.new.render(menu)
      # The trigger appears before the menu in DOM order so the JS
      # `findTrigger(host)` walk lands on it first.
      trigger_idx = html.index("Right-click me").not_nil!
      menu_idx = html.index(%(role="menu")).not_nil!
      trigger_idx.should be < menu_idx
    end
  end
end
