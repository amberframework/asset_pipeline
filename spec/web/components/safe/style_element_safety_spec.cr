require "../../spec_helper"
require "../../../../src/components/elements/document/style"
require "../../../../src/components/elements/document/html"

# SafeHTML v1 — <style> element BODY closure (docs/SAFE_HTML_V1.md §3.8,
# reclassified from a DOCUMENTED RESIDUAL to CLOSED on 2026-07-08). The
# `<style>` body is not merely a CSS-context sink: `</style>` is a real
# tokenizer-recognized close tag no matter what precedes it in the text, so
# a String containing `</style><script>...</script>` closes the element
# early and runs the injected `<script>` in the surrounding document — full
# script execution, the exact same severity class as `<script>`-body
# interpolation (script_element_safety_spec.cr), just reached through a
# different, public, always-available element class.
describe "SafeHTML v1 — <style> body ban (</style> breakout sink, docs/SAFE_HTML_V1.md §3.8)" do
  describe "adversarial: interpolated data must never reach <style> body as executable markup" do
    it "a plain String child is rejected outright, regardless of content" do
      style = Components::Elements::Style.new
      expect_raises(ArgumentError, "does not accept a plain String child") do
        style << "body { margin: 0; }"
      end
    end

    it "the ban applies even to content that looks harmless" do
      style = Components::Elements::Style.new
      expect_raises(ArgumentError) { style << "h1 { color: blue; }" }
    end
  end

  describe "adversarial: all insertion paths into @children are closed, not just <<" do
    breakout = %(</style><script>alert(document.cookie)</script>)

    it "path 1 (<<): rejected at call time, never reaches render" do
      style = Components::Elements::Style.new
      expect_raises(ArgumentError, "does not accept a plain String child") do
        style << breakout
      end
      style.render.should eq("<style></style>")
    end

    it "path 2 (#add_child, inherited from ContainerElement but overridden here): rejected at call time" do
      style = Components::Elements::Style.new
      expect_raises(ArgumentError, "does not accept a plain String child") do
        style.add_child(breakout)
      end
      style.render.should eq("<style></style>")
    end

    it "path 2b (#add_children, plural): rejected at call time" do
      style = Components::Elements::Style.new
      expect_raises(ArgumentError, "does not accept a plain String child") do
        style.add_children(breakout)
      end
      style.render.should eq("<style></style>")
    end

    it "path 3 (direct `children << string` mutation via the public getter): closed at RENDER time" do
      style = Components::Elements::Style.new
      # `children` is a public, mutable `getter` — nothing stops this at
      # call time, which is exactly why the render-time backstop exists.
      style.children << breakout

      expect_raises(ArgumentError, "does not accept a plain String child") do
        style.render
      end
    end

    it "path 3b (`children.concat`): also closed at render time" do
      style = Components::Elements::Style.new
      extra = [breakout] of Components::Elements::HTMLElement | String | Components::Elements::RawHTML
      style.children.concat(extra)

      expect_raises(ArgumentError, "does not accept a plain String child") do
        style.render
      end
    end

    it "the breakout payload never appears in any rendered output, across all paths" do
      via_shovel = Components::Elements::Style.new
      begin
        via_shovel << breakout
      rescue ArgumentError
      end
      via_shovel.render.should_not contain("<script>alert(document.cookie)</script>")

      via_add_child = Components::Elements::Style.new
      begin
        via_add_child.add_child(breakout)
      rescue ArgumentError
      end
      via_add_child.render.should_not contain("<script>alert(document.cookie)</script>")

      via_direct_mutation = Components::Elements::Style.new
      via_direct_mutation.children << breakout
      rendered = begin
        via_direct_mutation.render
      rescue ArgumentError
        "<style></style>"
      end
      rendered.should_not contain("<script>alert(document.cookie)</script>")
    end

    it "an HTMLElement child (not String, not RawHTML) is also rejected at render time via direct mutation" do
      style = Components::Elements::Style.new
      rogue = Components::Elements::Html.new
      extra = [rogue] of Components::Elements::HTMLElement | String | Components::Elements::RawHTML
      style.children.concat(extra)

      expect_raises(ArgumentError, "should only contain CSS text") do
        style.render
      end
    end
  end

  describe "the one legitimate door" do
    it "Style.css requires a reason and renders the CSS verbatim" do
      style = Components::Elements::Style.css("body { margin: 0; }", reason: "spec: static CSS")
      style.render.should eq("<style>body { margin: 0; }</style>")
    end

    it "Style.css requires a non-empty reason" do
      expect_raises(ArgumentError, "requires a non-empty") do
        Components::Elements::Style.css("body { margin: 0; }", reason: "")
      end
    end

    it "Style.css still accepts and validates other constructor kwargs" do
      style = Components::Elements::Style.css("body { margin: 0; }", reason: "spec", media: "screen")
      style.render.should contain(%(media="screen"))
    end
  end

  describe "explicit RawHTML remains the loud, greppable escape hatch" do
    it "accepts a RawHTML wrapper directly" do
      style = Components::Elements::Style.new
      style << Components::Elements::RawHTML.new(".x { color: red; }")
      style.render.should eq("<style>.x { color: red; }</style>")
    end
  end
end
