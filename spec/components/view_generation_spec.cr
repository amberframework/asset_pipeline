require "../spec_helper"
require "../../src/components/elements/**"
require "../../src/components/base/**"
require "../../src/components/cache/**"

# Test component for views
class TestArticleComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Article.new(class: "article").build do |article|
      h1 = Components::Elements::H1.new
      h1 << (@attributes["title"]? || "Article")
      article << h1
      
      @children.each do |child|
        article << child.to_s
      end
    end.render
  end
end

describe "View Generation with Components" do
  it "generates a complete HTML document" do
    html = Components::Elements::Html.new(lang: "en").build do |doc|
      # Head section
      head = Components::Elements::Head.new
      
      title = Components::Elements::Title.new
      title << "Test Page"
      head << title
      
      doc << head
      
      # Body section
      body = Components::Elements::Body.new
      
      h1 = Components::Elements::H1.new
      h1 << "Hello World"
      body << h1
      
      doc << body
    end
    
    rendered = html.render
    rendered.should start_with("<!DOCTYPE html>")
    rendered.should contain("<html lang=\"en\">")
    rendered.should contain("<title>Test Page</title>")
    rendered.should contain("<h1>Hello World</h1>")
    rendered.should contain("</html>")
  end
  
  it "generates complex nested structures" do
    # Create a navigation menu
    nav = Components::Elements::Nav.new(class: "main-nav").build do |navigation|
      ul = Components::Elements::Ul.new
      
      ["Home", "About", "Contact"].each do |item|
        li = Components::Elements::Li.new
        a = Components::Elements::A.new(href: "/#{item.downcase}")
        a << item
        li << a
        ul << li
      end
      
      navigation << ul
    end
    
    rendered = nav.render
    rendered.should contain("<nav class=\"main-nav\">")
    rendered.should contain("<ul>")
    rendered.should contain("<li><a href=\"/home\">Home</a></li>")
    rendered.should contain("<li><a href=\"/about\">About</a></li>")
    rendered.should contain("<li><a href=\"/contact\">Contact</a></li>")
    rendered.should contain("</ul></nav>")
  end
  
  it "generates forms with proper structure" do
    form = Components::Elements::Form.new(
      method: "post",
      action: "/submit",
      class: "contact-form"
    ).build do |f|
      # Name field
      name_div = Components::Elements::Div.new(class: "form-group")
      
      label = Components::Elements::Label.new(for: "name")
      label << "Name:"
      name_div << label
      
      input = Components::Elements::Input.new(
        type: "text",
        name: "name",
        id: "name",
        required: "required"
      )
      name_div << input
      
      f << name_div
      
      # Submit button
      button = Components::Elements::Button.new(type: "submit")
      button << "Submit"
      f << button
    end
    
    rendered = form.render
    rendered.should contain("<form method=\"post\" action=\"/submit\" class=\"contact-form\">")
    rendered.should contain("<label for=\"name\">Name:</label>")
    rendered.should contain("<input type=\"text\" name=\"name\" id=\"name\" required=\"required\">")
    rendered.should contain("<button type=\"submit\">Submit</button>")
  end
  
  it "generates tables with data" do
    table = Components::Elements::Table.new(class: "data-table").build do |t|
      # Header
      thead = Components::Elements::Thead.new
      header_row = Components::Elements::Tr.new
      
      ["Name", "Age", "City"].each do |col|
        th = Components::Elements::Th.new
        th << col
        header_row << th
      end
      
      thead << header_row
      t << thead
      
      # Body
      tbody = Components::Elements::Tbody.new
      
      data = [
        ["Alice", "30", "New York"],
        ["Bob", "25", "London"],
        ["Charlie", "35", "Tokyo"]
      ]
      
      data.each do |row_data|
        row = Components::Elements::Tr.new
        
        row_data.each do |cell|
          td = Components::Elements::Td.new
          td << cell
          row << td
        end
        
        tbody << row
      end
      
      t << tbody
    end
    
    rendered = table.render
    rendered.should contain("<table class=\"data-table\">")
    rendered.should contain("<thead>")
    rendered.should contain("<th>Name</th>")
    rendered.should contain("<tbody>")
    rendered.should contain("<td>Alice</td>")
    rendered.should contain("<td>Tokyo</td>")
  end
  
  it "generates semantic HTML5 structure" do
    page = Components::Elements::Div.new(class: "page").build do |div|
      # Header
      header = Components::Elements::Header.new
      h1 = Components::Elements::H1.new
      h1 << "My Website"
      header << h1
      div << header
      
      # Main content
      main = Components::Elements::Main.new
      
      # Article
      article = Components::Elements::Article.new
      
      h2 = Components::Elements::H2.new
      h2 << "Article Title"
      article << h2
      
      p = Components::Elements::P.new
      p << "Article content goes here."
      article << p
      
      main << article
      
      # Aside
      aside = Components::Elements::Aside.new
      h3 = Components::Elements::H3.new
      h3 << "Related Links"
      aside << h3
      main << aside
      
      div << main
      
      # Footer
      footer = Components::Elements::Footer.new
      p = Components::Elements::P.new
      p << "© 2023 My Website"
      footer << p
      div << footer
    end
    
    rendered = page.render
    rendered.should contain("<header>")
    rendered.should contain("<main>")
    rendered.should contain("<article>")
    rendered.should contain("<aside>")
    rendered.should contain("<footer>")
  end
  
  it "composes components to build views" do
    # Create a reusable article component
    article = TestArticleComponent.new(title: "Component Composition")
    
    # Add content to the article
    p1 = Components::Elements::P.new
    p1 << "This demonstrates how components can be composed."
    article << p1.render
    
    p2 = Components::Elements::P.new
    p2 << "Each component is independent and reusable."
    article << p2.render
    
    rendered = article.render
    rendered.should contain("<article class=\"article\">")
    rendered.should contain("<h1>Component Composition</h1>")
    rendered.should contain("This demonstrates how components can be composed.")
    rendered.should contain("Each component is independent and reusable.")
  end
  
  it "handles special characters and escaping properly" do
    div = Components::Elements::Div.new
    div << "This & that"
    div << " <script>alert('xss')</script>"
    
    rendered = div.render
    rendered.should contain("This &amp; that")
    rendered.should contain("&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
  end
  
  it "generates media elements" do
    # Just test img element since figure isn't implemented yet
    img = Components::Elements::Img.new(
      src: "/image.jpg",
      alt: "Test Image",
      width: "300",
      height: "200",
      class: "responsive"
    )
    
    rendered = img.render
    rendered.should eq("<img src=\"/image.jpg\" alt=\"Test Image\" width=\"300\" height=\"200\" class=\"responsive\">")
  end
  
  it "can write generated HTML to files" do
    # Generate a simple page
    html = Components::Elements::Html.new(lang: "en").build do |doc|
      head = Components::Elements::Head.new
      title = Components::Elements::Title.new
      title << "File Output Test"
      head << title
      doc << head
      
      body = Components::Elements::Body.new
      h1 = Components::Elements::H1.new
      h1 << "This page was generated!"
      body << h1
      doc << body
    end
    
    # Write to a temporary file
    filename = "spec/output_test.html"
    File.write(filename, html.render)
    
    # Verify file was created and contains expected content
    File.exists?(filename).should be_true
    content = File.read(filename)
    content.should start_with("<!DOCTYPE html>")
    content.should contain("This page was generated!")
    
    # Clean up
    File.delete(filename) if File.exists?(filename)
  end
end