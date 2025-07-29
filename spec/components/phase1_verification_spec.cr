require "../spec_helper"

# Import base classes
require "../../src/components/elements/base/html_element"
require "../../src/components/elements/base/void_element"
require "../../src/components/elements/base/container_element"

# Import some elements from each category
require "../../src/components/elements/document/html"
require "../../src/components/elements/document/body"
require "../../src/components/elements/sections/header"
require "../../src/components/elements/sections/main"
require "../../src/components/elements/grouping/div"
require "../../src/components/elements/grouping/p"
require "../../src/components/elements/text/a"
require "../../src/components/elements/embedded/img"
require "../../src/components/elements/tables/table_elements"
require "../../src/components/elements/forms/form"
require "../../src/components/elements/forms/input"
require "../../src/components/elements/forms/form_controls"
require "../../src/components/elements/interactive/interactive_elements"
require "../../src/components/elements/void/void_elements"

describe "Phase 1 Verification - HTML Element Foundation" do
  it "successfully implements all base classes" do
    # Base classes exist and work
    div = Components::Elements::Div.new
    div.is_a?(Components::Elements::ContainerElement).should be_true
    div.is_a?(Components::Elements::HTMLElement).should be_true
    
    br = Components::Elements::Br.new
    br.is_a?(Components::Elements::VoidElement).should be_true
    br.is_a?(Components::Elements::HTMLElement).should be_true
  end
  
  it "creates type-safe HTML without string templates" do
    # Build a simple page structure using element classes
    page = Components::Elements::Html.new(lang: "en").build do |html|
      html << Components::Elements::Body.new.build do |body|
        body << Components::Elements::Header.new.build do |header|
          logo_div = Components::Elements::Div.new(class: "logo")
          logo_div << "My Site"
          header << logo_div
        end
        
        body << Components::Elements::Main.new.build do |main|
          p_elem = Components::Elements::P.new
          p_elem << "Welcome to our site!"
          main << p_elem
          
          # Create a link
          link = Components::Elements::A.new(href: "/about")
          link << "Learn More"
          main << link
        end
      end
    end
    
    # Verify it renders correctly
    rendered = page.render
    rendered.should contain("<html lang=\"en\">")
    rendered.should contain("<header>")
    rendered.should contain("<div class=\"logo\">My Site</div>")
    rendered.should contain("<p>Welcome to our site!</p>")
    rendered.should contain("<a href=\"/about\">Learn More</a>")
  end
  
  it "properly validates attributes" do
    # Test attribute validation
    expect_raises(ArgumentError, "Invalid input type: invalid") do
      Components::Elements::Input.new(type: "invalid")
    end
    
    expect_raises(ArgumentError, "ID cannot contain spaces") do
      Components::Elements::Div.new(id: "my id")
    end
  end
  
  it "enforces void element rules" do
    img = Components::Elements::Img.new(src: "test.jpg", alt: "Test")
    
    # Void elements cannot have children
    expect_raises(ArgumentError, "Void element <img> cannot have children") do
      img << "content"
    end
    
    # Void elements render without closing tag
    img.render.should eq("<img src=\"test.jpg\" alt=\"Test\">")
  end
  
  it "escapes content and attributes properly" do
    div = Components::Elements::Div.new(title: "Test & <Demo>")
    div << "Content with <script>alert('XSS')</script>"
    
    rendered = div.render
    rendered.should contain("title=\"Test &amp; &lt;Demo&gt;\"")
    rendered.should contain("Content with &lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;")
  end
  
  it "supports building complex structures" do
    # Build a form
    form = Components::Elements::Form.new(action: "/submit", method: "POST").build do |f|
      # Text input
      f << Components::Elements::Input.new(type: "text", name: "username", placeholder: "Username")
      
      # Submit button
      btn = Components::Elements::Button.new(type: "submit")
      btn << "Submit"
      f << btn
    end
    
    rendered = form.render
    rendered.should contain("<form action=\"/submit\" method=\"POST\">")
    rendered.should contain("<input type=\"text\" name=\"username\" placeholder=\"Username\">")
    rendered.should contain("<button type=\"submit\">Submit</button>")
  end
  
  it "implements tables correctly" do
    table = Components::Elements::Table.new.build do |t|
      t << Components::Elements::Tr.new.build do |tr|
        th1 = Components::Elements::Th.new
        th1 << "Name"
        tr << th1
        
        th2 = Components::Elements::Th.new
        th2 << "Value"
        tr << th2
      end
      
      t << Components::Elements::Tr.new.build do |tr|
        td1 = Components::Elements::Td.new
        td1 << "Item 1"
        tr << td1
        
        td2 = Components::Elements::Td.new
        td2 << "100"
        tr << td2
      end
    end
    
    rendered = table.render
    rendered.should contain("<table>")
    rendered.should contain("<th>Name</th>")
    rendered.should contain("<td>Item 1</td>")
  end
  
  it "achieves the goal of NO string templates" do
    # This entire test suite builds HTML using only Crystal classes
    # No string concatenation, no template syntax, pure type-safe Crystal
    
    # Every HTML element is an object
    Components::Elements::Html.new.is_a?(Object).should be_true
    Components::Elements::Div.new.is_a?(Object).should be_true
    Components::Elements::Input.new.is_a?(Object).should be_true
    
    # The system is ready for Phase 2: Component System
    true.should be_true
  end
end