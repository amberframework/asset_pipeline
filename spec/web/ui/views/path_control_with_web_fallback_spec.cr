require "../../spec_helper"
require "../../../../src/ui"

describe UI::PathControlWithWebFallback do
  it "constructs and accumulates components" do
    ctrl = UI::PathControlWithWebFallback.new
    ctrl.add_component("Users")
    ctrl.add_component("amber")
    ctrl.add_component("Drafts")
    ctrl.path_string.should eq("/Users/amber/Drafts")
  end

  describe "web renderer HTML structure" do
    it "emits a semantic <nav aria-label=Breadcrumb><ol>" do
      ctrl = UI::PathControlWithWebFallback.new
      ctrl.add_component("Users", url: "/users")
      ctrl.add_component("amber", url: "/users/amber")
      ctrl.add_component("Drafts")
      html = UI::Web::Renderer.new.render(ctrl)
      html.should contain(%(aria-label="Breadcrumb"))
      html.should contain("<ol")
      html.should contain(%(href="/users"))
      html.should contain(%(href="/users/amber"))
      html.should contain(%(aria-current="page"))
      html.should contain("Drafts")
    end
  end
end
