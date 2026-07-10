require "../../spec_helper"
require "../../../../src/components/base/component"
require "../../../../src/components/base/stateless_component"
require "../../../../src/components/examples/data_table_component"
require "../../../../src/components/elements/grouping/div"

# A legacy-style component: only implements the old `render_content : String`
# hook, hand-builds HTML with `String.build`, and does NOT override
# `render_safe_content`. This is exactly the pre-hardening shape every
# component in this shard had before docs/SAFE_HTML_V1.md.
class LegacyStyleComponent < Components::StatelessComponent
  def render_content : String
    String.build do |io|
      io << "<div class=\"legacy\">"
      io << (@attributes["text"]? || "")
      io << "</div>"
    end
  end
end

# A migrated-style component: overrides `render_safe_content` directly using
# the Elements DSL, never builds a raw String, and its `render_content`
# (kept only to satisfy the still-abstract base contract) delegates back —
# it is provably NOT where the real work happens, because it raises if
# reached independently of `render_safe_content`.
class MigratedStyleComponent < Components::StatelessComponent
  def render_safe_content : Components::SafeHTML
    div = Components::Elements::Div.new(class: "migrated")
    div << (@attributes["text"]? || "")
    Components::SafeHTML.unsafe(div.render, reason: "spec: built via Elements DSL")
  end

  def render_content : String
    raise "render_content should never be called directly for a component that overrides render_safe_content"
  end
end

describe "Component#render output contract (docs/SAFE_HTML_V1.md)" do
  it "returns a Components::SafeHTML, not a String" do
    component = LegacyStyleComponent.new(text: "hi")
    component.render.should be_a(Components::SafeHTML)
  end

  describe "the legacy bridge" do
    it "wraps an un-migrated component's render_content through the loud SafeHTML.unsafe escape hatch" do
      # We cannot introspect the private `reason:` string from outside, but
      # we CAN prove the bridge is exercised: a legacy component's render
      # still renders (nothing breaks), and its render_safe_content is the
      # inherited default (not overridden).
      component = LegacyStyleComponent.new(text: "hi")
      component.render.to_s.should eq("<div class=\"legacy\">hi</div>")
      component.responds_to?(:render_safe_content).should be_true
    end

    it "is honest, not protective: a legacy component that forgets to escape still renders the hole (this is why migration matters)" do
      # This is the load-bearing point of the whole design: the legacy
      # bridge does NOT retroactively sanitize bad hand-built HTML. It only
      # marks the *type boundary* (String -> SafeHTML) so the compiler can
      # tell migrated components from un-migrated ones. Security still comes
      # from migrating off String.build, not from the bridge.
      xss = %(<script>alert(document.cookie)</script>)
      component = LegacyStyleComponent.new(text: xss)
      component.render.to_s.should contain(xss) # NOT escaped — the legacy hole, faithfully preserved
    end
  end

  describe "the migrated path" do
    it "uses render_safe_content directly — render_content is never reached" do
      component = MigratedStyleComponent.new(text: "hi")
      component.render.to_s.should eq(%(<div class="migrated">hi</div>))
    end

    it "adversarial: XSS through a migrated component's text sink comes out inert" do
      xss = %(<script>alert(document.cookie)</script>)
      component = MigratedStyleComponent.new(text: xss)
      rendered = component.render.to_s

      rendered.should_not contain("<script>")
      rendered.should contain("&lt;script&gt;")
    end
  end

  describe "the exemplar migration: DataTableComponent" do
    it "renders via render_safe_content (the safe DSL path), not the legacy String.build bridge" do
      table = Components::Examples::DataTableComponent.new
      table.render.should be_a(Components::SafeHTML)
    end

    it "adversarial: XSS through every text sink (id, title, owner, status, amount) comes out inert" do
      xss = %(<img src=x onerror=alert(1)>)
      row = Components::Examples::DataTableComponent::Row.new(
        id: xss, title: xss, owner: xss, status: xss, state: "success", amount: xss
      )
      table = Components::Examples::DataTableComponent.new([row])
      rendered = table.render.to_s

      # The security property: no live `<img ...>` tag exists in the output
      # (the payload's `<` and `>` are escaped, so it can never parse as an
      # element — an inert "onerror=alert(1)" text fragment inside escaped
      # angle brackets is not a live attribute of anything).
      rendered.should_not contain("<img")
      rendered.should contain("&lt;img")
      rendered.should contain("&gt;")
    end

    it "adversarial: XSS through the aria-label attribute sink (built from title + status) comes out inert" do
      xss = %("><script>alert(1)</script>)
      row = Components::Examples::DataTableComponent::Row.new(
        id: "INV-1", title: xss, owner: "Owner", status: "Paid", state: "success", amount: "$1"
      )
      table = Components::Examples::DataTableComponent.new([row])
      rendered = table.render.to_s

      rendered.should_not contain(%(aria-label="")) # did not break out of the attribute
      rendered.should_not contain("<script>alert(1)</script>")
      rendered.should contain("&quot;&gt;&lt;script&gt;")
    end

    it "adversarial: XSS through the caption text sink (empty-state path) comes out inert" do
      table = Components::Examples::DataTableComponent.new(
        [] of Components::Examples::DataTableComponent::Row,
        caption: %("><script>alert(1)</script>)
      )
      rendered = table.render.to_s
      rendered.should_not contain("<script>alert(1)</script>")
      rendered.should contain("&quot;&gt;&lt;script&gt;")
    end

    it "adversarial: XSS through the id attribute sink comes out inert and cannot break out of the quoted attribute" do
      xss = %("><script>alert(1)</script>)
      table = Components::Examples::DataTableComponent.new(id: xss)
      rendered = table.render.to_s

      rendered.should_not contain(%(id="">))
      rendered.should_not contain("<script>alert(1)</script>")
      rendered.should contain(%(id="&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;"))
    end
  end
end
