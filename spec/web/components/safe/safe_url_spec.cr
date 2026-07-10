require "../../spec_helper"
require "../../../../src/components/safe/safe_url"

describe Components::SafeURL do
  describe "adversarial: script-executing schemes must come out inert" do
    it "rejects javascript: (the canonical href-sink payload)" do
      expect_raises(Components::SafeURL::UnsafeURLError, /scheme "javascript" is not allowed/) do
        Components::SafeURL.parse!("javascript:alert(document.cookie)")
      end
    end

    it "rejects JavaScript: with mixed case (scheme match is case-insensitive)" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::SafeURL.parse!("JaVaScRiPt:alert(1)")
      end
    end

    it "rejects vbscript:" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::SafeURL.parse!("vbscript:msgbox(1)")
      end
    end

    it "rejects data: (not on the v1 allowlist)" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::SafeURL.parse!("data:text/html,<script>alert(1)</script>")
      end
    end

    it "rejects file:" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::SafeURL.parse!("file:///etc/passwd")
      end
    end

    it "defeats the java\\tscript: control-character bypass (browsers strip control chars before scheme-sniffing)" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::SafeURL.parse!("java\tscript:alert(1)")
      end
    end

    it "defeats the newline-injected bypass" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::SafeURL.parse!("java\nscript:alert(1)")
      end
    end

    it "defeats a null-byte-embedded bypass" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::SafeURL.parse!("java\u0000script:alert(1)")
      end
    end

    it "defeats a leading-whitespace bypass" do
      expect_raises(Components::SafeURL::UnsafeURLError) do
        Components::SafeURL.parse!("   javascript:alert(1)")
      end
    end

    it ".parse returns nil instead of raising for unsafe input" do
      Components::SafeURL.parse("javascript:alert(1)").should be_nil
    end
  end

  describe "allowed URLs" do
    it "allows https:" do
      Components::SafeURL.parse!("https://example.com/path?x=1").to_s.should eq("https://example.com/path?x=1")
    end

    it "allows http:" do
      Components::SafeURL.parse!("http://example.com").to_s.should eq("http://example.com")
    end

    it "allows mailto:" do
      Components::SafeURL.parse!("mailto:person@example.com").to_s.should eq("mailto:person@example.com")
    end

    it "allows tel:" do
      Components::SafeURL.parse!("tel:+15555550100").to_s.should eq("tel:+15555550100")
    end

    it "allows an absolute path with no scheme" do
      Components::SafeURL.parse!("/dashboard?tab=billing").to_s.should eq("/dashboard?tab=billing")
    end

    it "allows a protocol-relative URL" do
      Components::SafeURL.parse!("//cdn.example.com/app.js").to_s.should eq("//cdn.example.com/app.js")
    end

    it "allows a fragment-only URL" do
      Components::SafeURL.parse!("#section-2").to_s.should eq("#section-2")
    end

    it "allows a bare relative path" do
      Components::SafeURL.parse!("dashboard.html").to_s.should eq("dashboard.html")
    end
  end

  describe ".unsafe (the loud, explicit opt-out)" do
    it "allows a non-allowlisted scheme only via the reasoned escape hatch" do
      Components::SafeURL.unsafe("myapp://open", reason: "spec: app-custom URI scheme").to_s.should eq("myapp://open")
    end

    it "requires a non-empty reason" do
      expect_raises(ArgumentError, "requires a non-empty") do
        Components::SafeURL.unsafe("myapp://open", reason: "")
      end
    end
  end

  describe "falsifiability" do
    it "empty URL raises" do
      expect_raises(Components::SafeURL::UnsafeURLError, "empty URL") do
        Components::SafeURL.parse!("")
      end
    end
  end
end
