require "../../spec_helper"

# Import all element classes
require "../../../src/components/elements/base/html_element"
require "../../../src/components/elements/base/void_element"
require "../../../src/components/elements/base/container_element"

# Document elements
require "../../../src/components/elements/document/html"
require "../../../src/components/elements/document/head"
require "../../../src/components/elements/document/body"
require "../../../src/components/elements/document/title"
require "../../../src/components/elements/document/meta"
require "../../../src/components/elements/document/link"
require "../../../src/components/elements/document/style"
require "../../../src/components/elements/document/script"

# Section elements
require "../../../src/components/elements/sections/header"
require "../../../src/components/elements/sections/footer"
require "../../../src/components/elements/sections/nav"
require "../../../src/components/elements/sections/main"
require "../../../src/components/elements/sections/section"
require "../../../src/components/elements/sections/article"
require "../../../src/components/elements/sections/aside"
require "../../../src/components/elements/sections/headings"

# Grouping elements
require "../../../src/components/elements/grouping/div"
require "../../../src/components/elements/grouping/p"
require "../../../src/components/elements/grouping/span"
require "../../../src/components/elements/grouping/pre"
require "../../../src/components/elements/grouping/blockquote"
require "../../../src/components/elements/grouping/lists"

# Text elements
require "../../../src/components/elements/text/a"
require "../../../src/components/elements/text/text_semantics"

# Embedded elements
require "../../../src/components/elements/embedded/img"
require "../../../src/components/elements/embedded/media"

# Table elements
require "../../../src/components/elements/tables/table_elements"

# Form elements
require "../../../src/components/elements/forms/form"
require "../../../src/components/elements/forms/input"
require "../../../src/components/elements/forms/form_controls"

# Interactive elements
require "../../../src/components/elements/interactive/interactive_elements"

# Void elements
require "../../../src/components/elements/void/void_elements"

describe "HTML Element Integration" do
  describe "Building a complete webpage" do
    it "can build a complete HTML5 document" do
      html = Components::Elements::Html.new(lang: "en").build do |doc|
        doc << Components::Elements::Head.new.build do |head|
          head << Components::Elements::Meta.charset
          head << Components::Elements::Meta.viewport
          head << Components::Elements::Title.new << "Test Page"
          head << Components::Elements::Link.stylesheet("/css/app.css")
          head << Components::Elements::Style.new("body { margin: 0; }")
        end
        
        doc << Components::Elements::Body.new.build do |body|
          body << Components::Elements::Header.new.build do |header|
            header << Components::Elements::Nav.new.build do |nav|
              nav << Components::Elements::Ul.new.build do |ul|
                home_link = Components::Elements::A.new(href: "/")
                home_link << "Home"
                ul << Components::Elements::Li.new << home_link
                
                about_link = Components::Elements::A.new(href: "/about")
                about_link << "About"
                ul << Components::Elements::Li.new << about_link
                
                contact_link = Components::Elements::A.new(href: "/contact")
                contact_link << "Contact"
                ul << Components::Elements::Li.new << contact_link
              end
            end
          end
          
          body << Components::Elements::Main.new.build do |main|
            main << Components::Elements::Article.new.build do |article|
              article << Components::Elements::H1.new << "Welcome"
              article << Components::Elements::P.new << "This is a test page."
              
              article << Components::Elements::Section.new.build do |section|
                section << Components::Elements::H2.new << "Features"
                section << Components::Elements::Ul.new.build do |ul|
                  ul << Components::Elements::Li.new << "Type-safe HTML"
                  ul << Components::Elements::Li.new << "No templates"
                  ul << Components::Elements::Li.new << "Pure Crystal"
                end
              end
            end
            
            main << Components::Elements::Aside.new.build do |aside|
              aside << Components::Elements::H3.new << "Related"
              aside << Components::Elements::P.new << "Check out our other pages."
            end
          end
          
          body << Components::Elements::Footer.new.build do |footer|
            footer << Components::Elements::P.new << "© 2025 Test Site"
          end
          
          body << Components::Elements::Script.new("console.log('Page loaded');")
        end
      end
      
      rendered = html.render
      rendered.should contain("<html lang=\"en\">")
      rendered.should contain("<meta charset=\"UTF-8\">")
      rendered.should contain("<title>Test Page</title>")
      rendered.should contain("<h1>Welcome</h1>")
      rendered.should contain("<nav>")
      rendered.should contain("<footer>")
    end
    
    it "can build a complex form" do
      form = Components::Elements::Form.new(action: "/submit", method: "POST").build do |f|
        f << Components::Elements::Fieldset.new.build do |fieldset|
          fieldset << Components::Elements::Legend.new << "Personal Information"
          
          fieldset << Components::Elements::Div.new(class: "form-group").build do |group|
            group << Components::Elements::Label.new("Name:", "name")
            group << Components::Elements::Input.new(type: "text", name: "name", required: "true")
          end
          
          fieldset << Components::Elements::Div.new(class: "form-group").build do |group|
            group << Components::Elements::Label.new("Email:", "email")
            group << Components::Elements::Input.new(type: "email", name: "email", required: "true")
          end
          
          fieldset << Components::Elements::Div.new(class: "form-group").build do |group|
            group << Components::Elements::Label.new("Bio:", "bio")
            group << Components::Elements::Textarea.new(name: "bio", rows: "4")
          end
          
          fieldset << Components::Elements::Div.new(class: "form-group").build do |group|
            group << Components::Elements::Label.new("Country:", "country")
            group << Components::Elements::Select.new(name: "country").build do |sel|
              sel << Components::Elements::Option.new("United States", "us")
              sel << Components::Elements::Option.new("Canada", "ca")
              sel << Components::Elements::Option.new("Mexico", "mx")
            end
          end
        end
        
        f << Components::Elements::Div.new(class: "form-actions").build do |actions|
          submit_btn = Components::Elements::Button.new(type: "submit", class: "btn-primary")
          submit_btn << "Submit"
          actions << submit_btn
          
          cancel_btn = Components::Elements::Button.new(type: "button", class: "btn-secondary")
          cancel_btn << "Cancel"
          actions << cancel_btn
        end
      end
      
      rendered = form.render
      rendered.should contain("<form action=\"/submit\" method=\"POST\">")
      rendered.should contain("<fieldset>")
      rendered.should contain("<legend>Personal Information</legend>")
      rendered.should contain("<input type=\"text\" name=\"name\" required=\"true\">")
      rendered.should contain("<textarea name=\"bio\" rows=\"4\">")
      rendered.should contain("<option value=\"us\">United States</option>")
    end
    
    it "can build a data table" do
      table = Components::Elements::Table.new(class: "data-table").build do |t|
        t << Components::Elements::Caption.new << "Sales Data"
        
        t << Components::Elements::Thead.new.build do |thead|
          thead << Components::Elements::Tr.new.build do |tr|
            tr << Components::Elements::Th.new(scope: "col") << "Product"
            tr << Components::Elements::Th.new(scope: "col") << "Q1"
            tr << Components::Elements::Th.new(scope: "col") << "Q2"
            tr << Components::Elements::Th.new(scope: "col") << "Total"
          end
        end
        
        t << Components::Elements::Tbody.new.build do |tbody|
          tbody << Components::Elements::Tr.new.build do |tr|
            tr << Components::Elements::Th.new(scope: "row") << "Widget A"
            tr << Components::Elements::Td.new << "100"
            tr << Components::Elements::Td.new << "150"
            tr << Components::Elements::Td.new << "250"
          end
          
          tbody << Components::Elements::Tr.new.build do |tr|
            tr << Components::Elements::Th.new(scope: "row") << "Widget B"
            tr << Components::Elements::Td.new << "200"
            tr << Components::Elements::Td.new << "180"
            tr << Components::Elements::Td.new << "380"
          end
        end
        
        t << Components::Elements::Tfoot.new.build do |tfoot|
          tfoot << Components::Elements::Tr.new.build do |tr|
            tr << Components::Elements::Th.new(scope: "row") << "Total"
            tr << Components::Elements::Td.new << "300"
            tr << Components::Elements::Td.new << "330"
            tr << Components::Elements::Td.new << "630"
          end
        end
      end
      
      rendered = table.render
      rendered.should contain("<table class=\"data-table\">")
      rendered.should contain("<caption>Sales Data</caption>")
      rendered.should contain("<thead>")
      rendered.should contain("<tbody>")
      rendered.should contain("<tfoot>")
      rendered.should contain("<th scope=\"col\">Product</th>")
    end
    
    it "can build media elements" do
      video = Components::Elements::Video.new(controls: "true", width: "640", height: "360").build do |v|
        v << Components::Elements::Source.new(src: "/video.mp4", type: "video/mp4")
        v << Components::Elements::Source.new(src: "/video.webm", type: "video/webm")
        v << Components::Elements::Track.new(
          kind: "subtitles", 
          src: "/subtitles_en.vtt", 
          srclang: "en", 
          label: "English"
        )
        v << "Your browser does not support the video tag."
      end
      
      rendered = video.render
      rendered.should contain("<video controls=\"true\" width=\"640\" height=\"360\">")
      rendered.should contain("<source src=\"/video.mp4\" type=\"video/mp4\">")
      rendered.should contain("<track kind=\"subtitles\"")
    end
    
    it "properly escapes content and attributes" do
      div = Components::Elements::Div.new(
        title: "Test \"Quote\" & <Tag>",
        "data-value": "a > b && c < d"
      ).build do |d|
        d << "<script>alert('XSS')</script>"
        d << Components::Elements::P.new << "Normal & special < characters >"
      end
      
      rendered = div.render
      rendered.should contain("title=\"Test &quot;Quote&quot; &amp; &lt;Tag&gt;\"")
      rendered.should contain("data-value=\"a &gt; b &amp;&amp; c &lt; d\"")
      rendered.should contain("&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;")
      rendered.should contain("Normal &amp; special &lt; characters &gt;")
    end
    
    it "validates element-specific attributes" do
      # Input type validation
      expect_raises(ArgumentError, "Invalid input type: invalid") do
        Components::Elements::Input.new(type: "invalid")
      end
      
      # Form method validation
      expect_raises(ArgumentError, "Invalid form method: PATCH") do
        Components::Elements::Form.new(method: "PATCH")
      end
      
      # Table colspan validation
      expect_raises(ArgumentError, "colspan must be a positive integer") do
        Components::Elements::Td.new(colspan: "abc")
      end
      
      # Link preload validation
      expect_raises(ArgumentError, "Invalid 'as' value for preload: invalid") do
        link = Components::Elements::Link.new(rel: "preload", href: "test.js")
        link.set_attribute("as", "invalid")
      end
    end
  end
  
  describe "Element categories" do
    it "void elements cannot have children" do
      img = Components::Elements::Img.new(src: "test.jpg", alt: "Test")
      
      expect_raises(ArgumentError, "Void element <img> cannot have children") do
        img << "content"
      end
      
      img.void_element?.should be_true
      img.can_have_children?.should be_false
    end
    
    it "container elements can have children" do
      div = Components::Elements::Div.new
      div << "Text"
      div << Components::Elements::Span.new << "Nested"
      
      div.void_element?.should be_false
      div.can_have_children?.should be_true
      div.children_count.should eq(2)
    end
    
    it "special elements handle content correctly" do
      # Pre preserves whitespace
      pre = Components::Elements::Pre.new
      pre << "  Line 1\n  Line 2"
      pre.render.should contain("  Line 1\n  Line 2")
      
      # Style doesn't escape CSS
      style = Components::Elements::Style.new
      style << ".class > div { color: red; }"
      style.render.should contain(".class > div { color: red; }")
      
      # Script doesn't escape JavaScript
      script = Components::Elements::Script.new
      script << "if (x < 10 && y > 5) { alert('test'); }"
      script.render.should contain("if (x < 10 && y > 5) { alert('test'); }")
    end
  end
  
  describe "Convenience constructors" do
    it "provides helpful constructors for common patterns" do
      # Link constructors
      Components::Elements::Link.stylesheet("/app.css").render
        .should eq("<link rel=\"stylesheet\" href=\"/app.css\">")
      
      # Meta constructors
      Components::Elements::Meta.charset.render
        .should eq("<meta charset=\"UTF-8\">")
      
      # Input constructors
      Components::Elements::Input.email("user_email").render
        .should eq("<input type=\"email\" name=\"user_email\">")
      
      # Button constructor
      Components::Elements::Button.new("Click Me", "submit").render
        .should eq("<button type=\"submit\">Click Me</button>")
      
      # A with content
      a_link = Components::Elements::A.new(href: "/home", class: "nav-link")
      a_link << "Home"
      a_link.render.should eq("<a href=\"/home\" class=\"nav-link\">Home</a>")
    end
  end
end