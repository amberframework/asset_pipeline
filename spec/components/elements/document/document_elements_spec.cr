require "../../../spec_helper"
require "../../../../src/components/elements/document/html"
require "../../../../src/components/elements/document/head"
require "../../../../src/components/elements/document/body"
require "../../../../src/components/elements/document/title"
require "../../../../src/components/elements/document/meta"
require "../../../../src/components/elements/document/link"
require "../../../../src/components/elements/document/style"
require "../../../../src/components/elements/document/script"

describe "Document Elements" do
  describe Components::Elements::Html do
    it "renders html element" do
      html = Components::Elements::Html.new(lang: "en")
      html.render.should eq("<html lang=\"en\"></html>")
    end
    
    it "validates language tags" do
      # Valid language tags
      Components::Elements::Html.new(lang: "en")
      Components::Elements::Html.new(lang: "en-US")
      Components::Elements::Html.new(lang: "zh-Hans-CN")
      
      # Invalid language tag
      expect_raises(ArgumentError, "Invalid language tag format: e") do
        Components::Elements::Html.new(lang: "e")
      end
    end
  end
  
  describe Components::Elements::Head do
    it "renders head element" do
      head = Components::Elements::Head.new
      head.render.should eq("<head></head>")
    end
  end
  
  describe Components::Elements::Body do
    it "renders body element" do
      body = Components::Elements::Body.new(class: "main")
      body.render.should eq("<body class=\"main\"></body>")
    end
    
    it "accepts event handlers" do
      body = Components::Elements::Body.new(onload: "init()")
      body["onload"].should eq("init()")
    end
  end
  
  describe Components::Elements::Title do
    it "renders title element with text" do
      title = Components::Elements::Title.new
      title << "Page Title"
      title.render.should eq("<title>Page Title</title>")
    end
    
    it "only accepts text content" do
      title = Components::Elements::Title.new
      title << "Valid Text"
      
      expect_raises(ArgumentError, "Title element can only contain text content") do
        title << Components::Elements::Html.new
      end
    end
  end
  
  describe Components::Elements::Meta do
    it "renders meta element" do
      meta = Components::Elements::Meta.new(charset: "UTF-8")
      meta.render.should eq("<meta charset=\"UTF-8\">")
    end
    
    it "provides convenience constructors" do
      Components::Elements::Meta.charset.render.should eq("<meta charset=\"UTF-8\">")
      Components::Elements::Meta.viewport.render.should eq("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">")
      Components::Elements::Meta.description("Test").render.should eq("<meta name=\"description\" content=\"Test\">")
      Components::Elements::Meta.keywords("test,crystal").render.should eq("<meta name=\"keywords\" content=\"test,crystal\">")
      Components::Elements::Meta.author("John Doe").render.should eq("<meta name=\"author\" content=\"John Doe\">")
      Components::Elements::Meta.http_equiv("refresh", "30").render.should eq("<meta http-equiv=\"refresh\" content=\"30\">")
    end
    
    it "is a void element" do
      meta = Components::Elements::Meta.new
      meta.void_element?.should be_true
      
      expect_raises(ArgumentError, "Void element <meta> cannot have children") do
        meta << "content"
      end
    end
  end
  
  describe Components::Elements::Link do
    it "renders link element" do
      link = Components::Elements::Link.new(rel: "stylesheet", href: "style.css")
      link.render.should eq("<link rel=\"stylesheet\" href=\"style.css\">")
    end
    
    it "provides convenience constructors" do
      Components::Elements::Link.stylesheet("app.css").render
        .should eq("<link rel=\"stylesheet\" href=\"app.css\">")
      
      Components::Elements::Link.icon("favicon.ico").render
        .should eq("<link rel=\"icon\" href=\"favicon.ico\" type=\"image/x-icon\">")
      
      Components::Elements::Link.manifest("app.json").render
        .should eq("<link rel=\"manifest\" href=\"app.json\">")
      
      Components::Elements::Link.preconnect("https://fonts.googleapis.com").render
        .should eq("<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">")
      
      Components::Elements::Link.preload("font.woff2", "font").render
        .should eq("<link rel=\"preload\" href=\"font.woff2\" as=\"font\">")
    end
    
    it "validates preload 'as' attribute" do
      expect_raises(ArgumentError, "Invalid 'as' value for preload: invalid") do
        link = Components::Elements::Link.new(rel: "preload", href: "test.js")
        link.set_attribute("as", "invalid")
      end
    end
    
    it "validates MIME types" do
      Components::Elements::Link.new(type: "text/css")
      Components::Elements::Link.new(type: "application/json")
      
      expect_raises(ArgumentError, "Invalid MIME type format: invalid/") do
        Components::Elements::Link.new(type: "invalid/")
      end
    end
  end
  
  describe Components::Elements::Style do
    it "renders style element with CSS" do
      style = Components::Elements::Style.new
      style << "body { margin: 0; }"
      style.render.should eq("<style>body { margin: 0; }</style>")
    end
    
    it "can be initialized with CSS content" do
      style = Components::Elements::Style.new("h1 { color: blue; }")
      style.render.should eq("<style>h1 { color: blue; }</style>")
    end
    
    it "only accepts text content" do
      style = Components::Elements::Style.new
      
      expect_raises(ArgumentError, "Style element should only contain CSS text") do
        style << Components::Elements::Html.new
      end
    end
    
    it "does not escape CSS content" do
      style = Components::Elements::Style.new
      style << ".class > div { color: red; }"
      style.render.should contain(".class > div { color: red; }")
    end
  end
  
  describe Components::Elements::Script do
    it "renders script element with JavaScript" do
      script = Components::Elements::Script.new
      script << "console.log('Hello');"
      script.render.should eq("<script>console.log('Hello');</script>")
    end
    
    it "can be initialized with JavaScript content" do
      script = Components::Elements::Script.new("alert('Hi');")
      script.render.should eq("<script>alert('Hi');</script>")
    end
    
    it "only accepts text content" do
      script = Components::Elements::Script.new
      
      expect_raises(ArgumentError, "Script element should only contain JavaScript text") do
        script << Components::Elements::Html.new
      end
    end
    
    it "validates boolean attributes" do
      script = Components::Elements::Script.new(async: "true", defer: "")
      script["async"].should eq("true")
      script["defer"].should eq("")
      
      expect_raises(ArgumentError, "async is a boolean attribute") do
        Components::Elements::Script.new(async: "yes")
      end
    end
    
    it "validates crossorigin attribute" do
      Components::Elements::Script.new(crossorigin: "anonymous")
      Components::Elements::Script.new(crossorigin: "use-credentials")
      
      expect_raises(ArgumentError, "Invalid crossorigin value: invalid") do
        Components::Elements::Script.new(crossorigin: "invalid")
      end
    end
    
    it "does not escape JavaScript content" do
      script = Components::Elements::Script.new
      script << "if (x < 10 && y > 5) { alert('test'); }"
      script.render.should contain("if (x < 10 && y > 5) { alert('test'); }")
    end
  end
  
  describe "Building a complete HTML document" do
    it "can build a full HTML5 document structure" do
      html = Components::Elements::Html.new(lang: "en").build do |doc|
        doc << Components::Elements::Head.new.build do |head|
          head << Components::Elements::Meta.charset
          head << Components::Elements::Meta.viewport
          title = Components::Elements::Title.new
          title << "Test Page"
          head << title
          head << Components::Elements::Link.stylesheet("/css/app.css")
        end
        
        doc << Components::Elements::Body.new.build do |body|
          body << Components::Elements::Script.new("console.log('Loaded');")
        end
      end
      
      rendered = html.render
      rendered.should contain("<html lang=\"en\">")
      rendered.should contain("<meta charset=\"UTF-8\">")
      rendered.should contain("<title>Test Page</title>")
      rendered.should contain("<link rel=\"stylesheet\" href=\"/css/app.css\">")
      rendered.should contain("<script>console.log('Loaded');</script>")
    end
  end
end