require "../../spec_helper"
require "../../../../src/components/elements/grouping/div"
require "../../../../src/components/elements/text/a"
require "../../../../src/components/elements/embedded/media"
require "../../../../src/components/elements/forms/form"
require "../../../../src/components/elements/forms/form_controls"
require "../../../../src/components/elements/forms/input"
require "../../../../src/components/elements/document/script"
require "../../../../src/components/elements/document/style"

# SafeHTML v1 — RE-GATE (cycle 6): the DIRECT-MUTATION surface, exhaustively.
#
# Prior cycles were defeated by the same structural gap every time: the
# public, mutable `getter`s `attributes : Hash(String, String)` and
# `children : Array(...)` let an attacker skip `#set_attribute` / `#<<`
# entirely. This suite hammers the render chokepoint from EVERY key-casing
# and whitespace variant the mandate names, for EVERY script-executing sink.
#
# The load-bearing property is FAIL-CLOSED: for a direct mutation, the ONLY
# correct render outcome is a raise. NB escaping is NOT a valid neutralization
# for `srcdoc` (attribute values ARE entity-decoded, and srcdoc's decoded
# value is re-parsed as a whole document — a `srcdoc="&lt;script&gt;..."`
# attribute is still a live, executing script after the browser decodes it),
# which is exactly why these assert `expect_raises` rather than a byte-level
# "payload absent" check that a merely-escaping (still-vulnerable) authority
# would pass. That makes them NON-VACUOUS: neuter the render authority
# (`validate_rendered_attribute!` -> no-op, or Script/Style `render_children`
# -> raw passthrough / base escaping) and every `expect_raises` here flips to
# a failure. Verified out-of-band by the gate that owns this file.
describe "SafeHTML v1 RE-GATE — direct-mutation of public getters at the render chokepoint" do
  # ----------------------------------------------------------------------
  # (1) <iframe srcdoc> — HTML-document-valued attribute, on-parse script exec
  # ----------------------------------------------------------------------
  describe "srcdoc via direct attributes[...] mutation, every key variant" do
    payload = "<script>alert(document.cookie)</script>"

    {"srcdoc", "SRCDOC", "Srcdoc", "SrcDoc", " srcdoc", "srcdoc ", "\tsrcdoc"}.each do |key|
      it "attributes[#{key.inspect}] = payload raises fail-closed at render" do
        iframe = Components::Elements::Iframe.new
        iframe.attributes[key] = payload

        expect_raises(ArgumentError, /SafeHTML ban|HTML-DOCUMENT-valued/) do
          iframe.render
        end
      end
    end

    it "a case-varied Srcdoc written ALONGSIDE a legitimately-vouched srcdoc is still caught (two Hash entries)" do
      iframe = Components::Elements::Iframe.srcdoc("<p>legit</p>", reason: "regate: static content")
      iframe.attributes["Srcdoc"] = payload

      expect_raises(ArgumentError, /HTML-DOCUMENT-valued/) do
        iframe.render
      end
    end

    it "overwriting the exact vouched key in-place with a fresh payload is caught (vouch map is separate from @attributes)" do
      iframe = Components::Elements::Iframe.srcdoc("<p>legit</p>", reason: "regate: static content")
      iframe.attributes["srcdoc"] = payload # clobber the vouched value in place

      expect_raises(ArgumentError, /HTML-DOCUMENT-valued/) do
        iframe.render
      end
    end

    it "the vouched-legit case still renders (guards against an over-broad authority)" do
      iframe = Components::Elements::Iframe.srcdoc("<p>legit</p>", reason: "regate: static content")
      iframe.render.should eq(%(<iframe srcdoc="&lt;p&gt;legit&lt;/p&gt;"></iframe>))
    end
  end

  # ----------------------------------------------------------------------
  # (2) on* inline event handlers
  # ----------------------------------------------------------------------
  describe "on* handlers via direct attributes[...] mutation" do
    # Well-formed on*-shaped names: pass name-grammar, caught by the on* ban.
    {"onclick", "OnClick", "ONCLICK", "onCLICK", "onmouseover", "onerror", "onload", "onfocusin"}.each do |key|
      it "attributes[#{key.inspect}] = payload raises via the on* ban at render" do
        div = Components::Elements::Div.new
        div.attributes[key] = "alert(document.cookie)"

        expect_raises(ArgumentError, /event-handler/) do
          div.render
        end
      end
    end

    # Malformed on*-shaped names: caught even earlier by the name-grammar
    # authority (a `/onclick`/` onclick` renders as a LIVE onclick in the
    # browser tokenizer, so this must fail closed, not merely escape).
    {"/onclick", " onclick", "onclick ", "on\tclick", "x onload", %q(x"onmouseover)}.each do |key|
      it "malformed on*-shaped name attributes[#{key.inspect}] raises via the name-grammar authority" do
        div = Components::Elements::Div.new
        div.attributes[key] = "alert(1)"

        expect_raises(ArgumentError, /SafeHTML ban|malformed attribute name/) do
          div.render
        end
      end
    end
  end

  # ----------------------------------------------------------------------
  # (3) javascript:/data: (non-allowlisted) URLs on url-bearing elements
  # ----------------------------------------------------------------------
  describe "non-allowlisted URLs via direct attributes[...] mutation" do
    {"href", "HREF", "Href", "hReF"}.each do |key|
      it "A#href[#{key.inspect}] = javascript: raises via SafeURL at render" do
        a = Components::Elements::A.new
        a.attributes[key] = "javascript:alert(document.cookie)"
        expect_raises(ArgumentError, /SafeHTML ban/) { a.render }
      end
    end

    it "A#href malformed /href name raises via the name-grammar authority" do
      a = Components::Elements::A.new
      a.attributes["/href"] = "javascript:alert(document.cookie)"
      expect_raises(ArgumentError, /SafeHTML ban|malformed attribute name/) { a.render }
    end

    it "Form#action[ACTION] = javascript: raises at render" do
      form = Components::Elements::Form.new
      form.attributes["ACTION"] = "javascript:alert(document.cookie)"
      expect_raises(ArgumentError, /SafeHTML ban/) { form.render }
    end

    it "Iframe#src[SRC] = javascript: raises at render (src loads a full nested browsing context)" do
      iframe = Components::Elements::Iframe.new
      iframe.attributes["SRC"] = "javascript:alert(document.cookie)"
      expect_raises(ArgumentError, /SafeHTML ban/) { iframe.render }
    end

    it "Object#data[DATA] = data:text/html raises at render (on-parse script exec, no user click)" do
      obj = Components::Elements::Object.new
      obj.attributes["DATA"] = "data:text/html,<script>alert(document.cookie)</script>"
      expect_raises(ArgumentError, /SafeHTML ban/) { obj.render }
    end

    # SafeHTML v1 §3.10, closed 2026-07-08: `Button`/`Input#formaction` --
    # every key-casing/whitespace variant the mandate names, mirroring the
    # `Form#action[ACTION]` case directly above.
    {"FORMACTION", "formaction", " formaction"}.each do |key|
      it "Button#formaction[#{key.inspect}] = javascript: raises at render" do
        button = Components::Elements::Button.new(type: "submit")
        button.attributes[key] = "javascript:alert(document.cookie)"
        expect_raises(ArgumentError, /SafeHTML ban/) { button.render }
      end

      it "Input#formaction[#{key.inspect}] = javascript: raises at render" do
        input = Components::Elements::Input.new(type: "submit")
        input.attributes[key] = "javascript:alert(document.cookie)"
        expect_raises(ArgumentError, /SafeHTML ban/) { input.render }
      end
    end

    it "Button#formaction[formaction] = data: raises at render" do
      button = Components::Elements::Button.new(type: "submit")
      button.attributes["formaction"] = "data:text/html,<script>alert(document.cookie)</script>"
      expect_raises(ArgumentError, /SafeHTML ban/) { button.render }
    end

    it "Input#formaction[formaction] = vbscript: raises at render" do
      input = Components::Elements::Input.new(type: "submit")
      input.attributes["formaction"] = "vbscript:msgbox(1)"
      expect_raises(ArgumentError, /SafeHTML ban/) { input.render }
    end

    it "legit https / relative formaction written by direct mutation still renders (over-broad guard)" do
      button = Components::Elements::Button.new(type: "submit")
      button.attributes["formaction"] = "https://example.com/submit"
      button.render.should eq(%(<button type="submit" formaction="https://example.com/submit"></button>))

      input = Components::Elements::Input.new(type: "submit")
      input.attributes["formaction"] = "/alt-submit"
      input.render.should eq(%(<input type="submit" formaction="/alt-submit">))
    end

    it "vbscript: and control-char-obfuscated java\\tscript: are also rejected at render" do
      a1 = Components::Elements::A.new
      a1.attributes["href"] = "vbscript:msgbox(1)"
      expect_raises(ArgumentError, /SafeHTML ban/) { a1.render }

      a2 = Components::Elements::A.new
      a2.attributes["href"] = "java\tscript:alert(1)"
      expect_raises(ArgumentError, /SafeHTML ban/) { a2.render }
    end

    it "legit https / relative URLs written by direct mutation still render (over-broad guard)" do
      a = Components::Elements::A.new
      a.attributes["href"] = "https://example.com/x"
      a.render.should eq(%(<a href="https://example.com/x"></a>))

      a2 = Components::Elements::A.new
      a2.attributes["HREF"] = "/relative/path"
      a2.render.should eq(%(<a HREF="/relative/path"></a>))
    end
  end

  # ----------------------------------------------------------------------
  # (4) </style> breakout — direct children mutation
  # ----------------------------------------------------------------------
  describe "</style> breakout via direct children mutation" do
    payload = "body{}</style><script>alert(document.cookie)</script>"

    it "style.children << plain String raises at render" do
      style = Components::Elements::Style.new
      style.children << payload
      expect_raises(ArgumentError, /does not accept a plain String child/) { style.render }
    end

    it "style.children.concat([...]) raises at render" do
      style = Components::Elements::Style.new
      extra = [payload] of Components::Elements::HTMLElement | String | Components::Elements::RawHTML
      style.children.concat(extra)
      expect_raises(ArgumentError, /does not accept a plain String child/) { style.render }
    end

    it "a static Style.css door still renders verbatim (over-broad guard)" do
      Components::Elements::Style.css("a{color:red}", reason: "regate: static css").render
        .should eq("<style>a{color:red}</style>")
    end
  end

  # ----------------------------------------------------------------------
  # (5) <script> body — direct children mutation
  # ----------------------------------------------------------------------
  describe "<script> body via direct children mutation" do
    payload = "</script><img src=x onerror=alert(document.cookie)>"

    it "script.children << plain String raises at render" do
      script = Components::Elements::Script.new
      script.children << payload
      expect_raises(ArgumentError, /does not accept a plain String child/) { script.render }
    end

    it "script.children.concat([...]) raises at render" do
      script = Components::Elements::Script.new
      extra = [payload] of Components::Elements::HTMLElement | String | Components::Elements::RawHTML
      script.children.concat(extra)
      expect_raises(ArgumentError, /does not accept a plain String child/) { script.render }
    end

    it "a static Script.static door still renders verbatim (over-broad guard)" do
      Components::Elements::Script.static("var x=1;", reason: "regate: static js").render
        .should eq("<script>var x=1;</script>")
    end
  end

  # ----------------------------------------------------------------------
  # Regression floor: the normal set_attribute + constructor-kwarg fail-fast
  # doors are still intact (not just the render-time authority).
  # ----------------------------------------------------------------------
  describe "call-time doors are still intact (fail-fast, not only render-time)" do
    it "Iframe.new(srcdoc:) raises" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Iframe.new(srcdoc: "<script>alert(1)</script>")
      end
    end

    it "A.new(onclick:) raises" do
      expect_raises(ArgumentError, /event-handler/) do
        Components::Elements::A.new(onclick: "alert(1)")
      end
    end

    it "A.new(href: javascript:) raises" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::A.new(href: "javascript:alert(1)")
      end
    end

    it "Object.new(data: data:text/html) raises" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Object.new(data: "data:text/html,<script>alert(1)</script>")
      end
    end

    it "Button.new(formaction: javascript:) raises" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Button.new(type: "submit", formaction: "javascript:alert(1)")
      end
    end

    it "Input.new(formaction: javascript:) raises" do
      expect_raises(ArgumentError, /SafeHTML ban/) do
        Components::Elements::Input.new(type: "submit", formaction: "javascript:alert(1)")
      end
    end

    it "set_attribute('SRCDOC', ...) raises (case-varied call-time door)" do
      iframe = Components::Elements::Iframe.new
      expect_raises(ArgumentError, /SafeHTML ban/) do
        iframe.set_attribute("SRCDOC", "<script>alert(1)</script>")
      end
    end
  end
end
