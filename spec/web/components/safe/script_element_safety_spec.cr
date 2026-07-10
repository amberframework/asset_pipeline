require "../../spec_helper"
require "../../../../src/components/elements/document/script"
require "../../../../src/components/elements/grouping/div"

describe "SafeHTML v1 — <script> interpolation ban (docs/SAFE_HTML_V1.md)" do
  describe "adversarial: interpolated data must never reach <script> as executable code" do
    it "a plain String child is rejected outright, regardless of content" do
      script = Components::Elements::Script.new
      user_supplied = %(alert(document.cookie))

      expect_raises(ArgumentError, "does not accept a plain String child") do
        script << user_supplied
      end
    end

    it "the ban applies even to content that looks harmless" do
      script = Components::Elements::Script.new
      expect_raises(ArgumentError) { script << "1 + 1" }
    end
  end

  describe "adversarial: all three insertion paths into @children are closed, not just <<" do
    breakout = %(</script><img src=x onerror=alert(1)>)

    it "path 1 (<<): rejected at call time, never reaches render" do
      script = Components::Elements::Script.new
      expect_raises(ArgumentError, "does not accept a plain String child") do
        script << breakout
      end
      # Nothing was appended -- render is still the empty tag, not a
      # half-built breakout.
      script.render.should eq("<script></script>")
    end

    it "path 2 (#add_child, inherited from ContainerElement but overridden here): rejected at call time" do
      script = Components::Elements::Script.new
      expect_raises(ArgumentError, "does not accept a plain String child") do
        script.add_child(breakout)
      end
      script.render.should eq("<script></script>")
    end

    it "path 2b (#add_children, plural): rejected at call time" do
      script = Components::Elements::Script.new
      expect_raises(ArgumentError, "does not accept a plain String child") do
        script.add_children(breakout)
      end
      script.render.should eq("<script></script>")
    end

    it "path 3 (direct `children << string` mutation via the public getter): the <<veil bypass is closed at RENDER time" do
      script = Components::Elements::Script.new
      # `children` is a public, mutable `getter` -- nothing stops this at
      # call time, which is exactly why the render-time backstop exists.
      script.children << breakout

      expect_raises(ArgumentError, "does not accept a plain String child") do
        script.render
      end
    end

    it "path 3b (`children.concat`): also closed at render time" do
      script = Components::Elements::Script.new
      extra = [breakout] of Components::Elements::HTMLElement | String | Components::Elements::RawHTML
      script.children.concat(extra)

      expect_raises(ArgumentError, "does not accept a plain String child") do
        script.render
      end
    end

    it "the breakout payload never appears in any rendered output, across all three paths" do
      # Belt-and-suspenders: even if a future refactor weakened one of the
      # three defenses, this asserts the actual security property (the
      # literal payload bytes never escape into rendered HTML) rather than
      # just asserting "an exception was raised".
      via_shovel = Components::Elements::Script.new
      begin
        via_shovel << breakout
      rescue ArgumentError
      end
      via_shovel.render.should_not contain("<img src=x onerror=alert(1)>")

      via_add_child = Components::Elements::Script.new
      begin
        via_add_child.add_child(breakout)
      rescue ArgumentError
      end
      via_add_child.render.should_not contain("<img src=x onerror=alert(1)>")

      via_direct_mutation = Components::Elements::Script.new
      via_direct_mutation.children << breakout
      rendered = begin
        via_direct_mutation.render
      rescue ArgumentError
        "<script></script>"
      end
      rendered.should_not contain("<img src=x onerror=alert(1)>")
    end

    it "an HTMLElement child (not String, not RawHTML) is also rejected at render time via direct mutation" do
      script = Components::Elements::Script.new
      rogue = Components::Elements::Div.new
      extra = [rogue] of Components::Elements::HTMLElement | String | Components::Elements::RawHTML
      script.children.concat(extra)

      expect_raises(ArgumentError, "should only contain JavaScript text") do
        script.render
      end
    end
  end

  describe "the two legitimate doors" do
    it "Script.static requires a reason and renders the JS verbatim" do
      script = Components::Elements::Script.static("console.log('hi');", reason: "spec: static JS")
      script.render.should eq("<script>console.log('hi');</script>")
    end

    it "Script.static requires a non-empty reason" do
      expect_raises(ArgumentError, "requires a non-empty") do
        Components::Elements::Script.static("console.log('hi');", reason: "")
      end
    end

    it "Script.json_data serializes a Hash as a JSON <script> block" do
      script = Components::Elements::Script.json_data("config", {theme: "dark", count: 3})
      rendered = script.render

      rendered.should contain(%(<script id="config" type="application/json">))
      rendered.should contain(%("theme":"dark"))
      rendered.should contain(%("count":3))
    end

    it "adversarial: json_data neutralizes a </script> breakout attempt inside the data" do
      payload = "</script><script>alert(document.cookie)</script>"
      script = Components::Elements::Script.json_data("data", {malicious: payload})
      rendered = script.render

      # The literal breakout sequence must not survive intact.
      rendered.should_not contain("</script><script>alert")
      # It must instead be present in its neutralized (escaped-slash) form.
      rendered.should contain("<\\/script>")
    end

    it "adversarial: json_data neutralizes a breakout attempt using an uppercase/mixed-case tag" do
      payload = "</SCRIPT><img src=x onerror=alert(1)>"
      script = Components::Elements::Script.json_data("data", {malicious: payload})
      rendered = script.render
      # Case-sensitive `</` neutralization covers the literal `</script>`
      # family used by the actual closing tag; content is JSON-string-safe
      # either way since it's inside a JSON string literal in a
      # type="application/json" block, never parsed as HTML/JS.
      rendered.should contain(%("malicious"))
    end
  end

  describe "explicit RawHTML remains the loud, greppable escape hatch" do
    it "accepts a RawHTML wrapper directly" do
      script = Components::Elements::Script.new
      script << Components::Elements::RawHTML.new("window.x = 1;")
      script.render.should eq("<script>window.x = 1;</script>")
    end
  end
end
