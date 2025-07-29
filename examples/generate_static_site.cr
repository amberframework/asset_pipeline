require "../src/components/elements/**"
require "../src/components/base/**"
require "../src/components/cache/**"
require "../src/components/elements/grouping/figure"
require "../src/components/elements/base/raw_html"

# Example 1: Blog Post Component
class BlogPostComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Article.new(class: "blog-post").build do |article|
      # Post header
      header = Components::Elements::Header.new(class: "post-header")
      
      h1 = Components::Elements::H1.new
      h1 << (@attributes["title"]? || "Untitled Post")
      header << h1
      
      # Post metadata
      meta_div = Components::Elements::Div.new(class: "post-meta")
      
      author_span = Components::Elements::Span.new(class: "author")
      author_span << "By #{@attributes["author"]? || "Anonymous"}"
      meta_div << author_span
      
      meta_div << " | "
      
      date_span = Components::Elements::Span.new(class: "date")
      date_span << (@attributes["date"]? || Time.utc.to_s("%B %d, %Y"))
      meta_div << date_span
      
      header << meta_div
      article << header
      
      # Post content
      content_div = Components::Elements::Div.new(class: "post-content")
      @children.each do |child|
        case child
        when Components::Component
          content_div << Components::Elements::RawHTML.new(child.render)
        when Components::Elements::HTMLElement
          content_div << child
        when Components::Elements::RawHTML
          content_div << child
        when String
          content_div << child
        end
      end
      article << content_div
      
      # Post footer with tags
      if tags = @attributes["tags"]?
        footer = Components::Elements::Footer.new(class: "post-footer")
        
        tags_div = Components::Elements::Div.new(class: "tags")
        tags_div << "Tags: "
        
        tags.split(",").each_with_index do |tag, i|
          tags_div << ", " if i > 0
          
          tag_link = Components::Elements::A.new(href: "/tags/#{tag.strip}", class: "tag")
          tag_link << tag.strip
          tags_div << tag_link
        end
        
        footer << tags_div
        article << footer
      end
    end.render
  end
end

# Example 2: Navigation Component
class NavigationComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Nav.new(class: "main-nav").build do |nav|
      ul = Components::Elements::Ul.new(class: "nav-list")
      
      links = @attributes["links"]? || "Home:/,About:/about,Contact:/contact"
      
      links.split(",").each do |link_data|
        parts = link_data.split(":")
        next unless parts.size == 2
        
        li = Components::Elements::Li.new
        a = Components::Elements::A.new(href: parts[1])
        a << parts[0]
        li << a
        ul << li
      end
      
      nav << ul
    end.render
  end
end

# Example 3: Layout Component
class LayoutComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Html.new(lang: "en").build do |html|
      # Head section
      head = Components::Elements::Head.new
      
      # Meta tags
      charset_meta = Components::Elements::Meta.new(charset: "UTF-8")
      head << charset_meta
      
      viewport_meta = Components::Elements::Meta.new(
        name: "viewport",
        content: "width=device-width, initial-scale=1.0"
      )
      head << viewport_meta
      
      # Title
      title = Components::Elements::Title.new
      title << (@attributes["title"]? || "My Website")
      head << title
      
      # Styles
      style = Components::Elements::Style.new
      style << css_content
      head << style
      
      html << head
      
      # Body section
      body = Components::Elements::Body.new
      
      # Header with navigation
      site_header = Components::Elements::Header.new(class: "site-header")
      
      logo = Components::Elements::Div.new(class: "logo")
      logo_link = Components::Elements::A.new(href: "/")
      logo_link << (@attributes["site_name"]? || "My Blog")
      logo << logo_link
      site_header << logo
      
      # Add navigation
      nav = NavigationComponent.new
      site_header << Components::Elements::RawHTML.new(nav.render)
      
      body << site_header
      
      # Main content
      main = Components::Elements::Main.new(class: "site-main")
      @children.each do |child|
        case child
        when Components::Component
          main << Components::Elements::RawHTML.new(child.render)
        when Components::Elements::HTMLElement
          main << child
        when Components::Elements::RawHTML
          main << child
        when String
          main << child
        end
      end
      body << main
      
      # Footer
      footer = Components::Elements::Footer.new(class: "site-footer")
      footer_p = Components::Elements::P.new
      footer_p << "© #{Time.utc.year} #{@attributes["site_name"]? || "My Blog"}. All rights reserved."
      footer << footer_p
      body << footer
      
      html << body
    end.render
  end
  
  private def css_content : String
    <<-CSS
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      line-height: 1.6;
      color: #333;
      background-color: #f5f5f5;
    }
    
    .site-header {
      background-color: #2c3e50;
      color: white;
      padding: 1rem 0;
      margin-bottom: 2rem;
    }
    
    .site-header .logo {
      font-size: 1.5rem;
      font-weight: bold;
      margin-bottom: 1rem;
      text-align: center;
    }
    
    .site-header a {
      color: white;
      text-decoration: none;
    }
    
    .main-nav {
      text-align: center;
    }
    
    .nav-list {
      list-style: none;
      display: flex;
      justify-content: center;
      gap: 2rem;
    }
    
    .site-main {
      max-width: 800px;
      margin: 0 auto;
      padding: 0 20px;
      background-color: white;
      min-height: 500px;
      box-shadow: 0 0 10px rgba(0,0,0,0.1);
    }
    
    .blog-post {
      padding: 2rem;
    }
    
    .post-header {
      margin-bottom: 2rem;
      border-bottom: 2px solid #eee;
      padding-bottom: 1rem;
    }
    
    .post-header h1 {
      color: #2c3e50;
      margin-bottom: 0.5rem;
    }
    
    .post-meta {
      color: #666;
      font-size: 0.9rem;
    }
    
    .post-content {
      margin-bottom: 2rem;
    }
    
    .post-content p {
      margin-bottom: 1rem;
    }
    
    .post-footer {
      border-top: 1px solid #eee;
      padding-top: 1rem;
    }
    
    .tags {
      color: #666;
    }
    
    .tag {
      color: #3498db;
      text-decoration: none;
    }
    
    .tag:hover {
      text-decoration: underline;
    }
    
    .site-footer {
      text-align: center;
      padding: 2rem 0;
      color: #666;
      font-size: 0.9rem;
    }
    CSS
  end
end

# Example 4: Gallery Component
class GalleryComponent < Components::StatelessComponent
  def render_content : String
    Components::Elements::Div.new(class: "gallery").build do |gallery|
      images = @attributes["images"]? || ""
      
      images.split(",").each do |image_data|
        parts = image_data.split("|")
        next unless parts.size >= 2
        
        figure = Components::Elements::Figure.new(class: "gallery-item")
        
        img = Components::Elements::Img.new(
          src: parts[0],
          alt: parts[1],
          loading: "lazy"
        )
        figure << img
        
        if parts.size > 2
          caption = Components::Elements::Figcaption.new
          caption << parts[2]
          figure << caption
        end
        
        gallery << figure
      end
    end.render
  end
end

# Generate a complete blog post page
def generate_blog_post_page
  layout = LayoutComponent.new(
    title: "Understanding Crystal Components - My Blog",
    site_name: "Crystal Blog"
  )
  
  post = BlogPostComponent.new(
    title: "Building Type-Safe Web Components in Crystal",
    author: "Jane Developer",
    date: "December 15, 2023",
    tags: "crystal, web development, components"
  )
  
  # Add post content
  post << Components::Elements::P.new.build do |p|
    p << "Crystal is a powerful language that combines the elegance of Ruby with the performance of C. "
    p << "In this post, we'll explore how to build type-safe web components that generate HTML without templates."
  end
  
  post << Components::Elements::H2.new.build do |h2|
    h2 << "Why Type-Safe Components?"
  end
  
  post << Components::Elements::P.new.build do |p|
    p << "Traditional template engines offer flexibility but sacrifice compile-time safety. "
    p << "With Crystal components, we get:"
  end
  
  list = Components::Elements::Ul.new.build do |ul|
    ["Compile-time HTML validation", "Type-safe attribute handling", "Better refactoring support", "Performance optimizations"].each do |item|
      li = Components::Elements::Li.new
      li << item
      ul << li
    end
  end
  
  post << list
  
  post << Components::Elements::H2.new.build do |h2|
    h2 << "Example Code"
  end
  
  code_block = Components::Elements::Pre.new.build do |pre|
    code = Components::Elements::Code.new(class: "language-crystal")
    code << <<-CODE
    class ButtonComponent < Components::StatelessComponent
      def render_content : String
        Components::Elements::Button.new(
          class: @attributes["class"]? || "btn",
          type: @attributes["type"]? || "button"
        ).build do |button|
          button << (@attributes["label"]? || "Click me")
        end.render
      end
    end
    CODE
    pre << code
  end
  
  post << code_block
  
  # Add the post to the layout
  layout << Components::Elements::RawHTML.new(post.render)
  
  layout.render
end

# Generate a gallery page
def generate_gallery_page
  layout = LayoutComponent.new(
    title: "Photo Gallery - My Blog",
    site_name: "Crystal Blog"
  )
  
  content = Components::Elements::Div.new(class: "gallery-page").build do |page|
    h1 = Components::Elements::H1.new
    h1 << "Photo Gallery"
    page << h1
    
    intro = Components::Elements::P.new
    intro << "A collection of beautiful images from our travels."
    page << intro
    
    gallery = GalleryComponent.new(
      images: [
        "/images/sunset.jpg|Beautiful sunset|Sunset over the ocean",
        "/images/mountain.jpg|Mountain landscape|Alps in winter",
        "/images/city.jpg|City lights|New York at night",
        "/images/forest.jpg|Forest path|Morning in the woods"
      ].join(",")
    )
    
    page << Components::Elements::RawHTML.new(gallery.render)
  end
  
  layout << Components::Elements::RawHTML.new(content.render)
  layout.render
end

# Generate multiple pages
def generate_static_site
  # Ensure output directory exists
  Dir.mkdir_p("output")
  
  # Generate home page
  home_content = generate_blog_post_page
  File.write("output/index.html", home_content)
  puts "Generated: output/index.html (#{home_content.bytesize} bytes)"
  
  # Generate gallery page
  gallery_content = generate_gallery_page
  File.write("output/gallery.html", gallery_content)
  puts "Generated: output/gallery.html (#{gallery_content.bytesize} bytes)"
  
  # Generate about page
  about_layout = LayoutComponent.new(
    title: "About - My Blog",
    site_name: "Crystal Blog"
  )
  
  about_content = Components::Elements::Div.new(class: "about-page").build do |page|
    h1 = Components::Elements::H1.new
    h1 << "About This Blog"
    page << h1
    
    p1 = Components::Elements::P.new
    p1 << "This blog is built using Crystal's component system, demonstrating type-safe HTML generation."
    page << p1
    
    h2 = Components::Elements::H2.new
    h2 << "Features"
    page << h2
    
    features = Components::Elements::Ul.new.build do |ul|
      [
        "100% type-safe HTML generation",
        "No string templates",
        "Component-based architecture",
        "Built-in caching support",
        "Reactive capabilities"
      ].each do |feature|
        li = Components::Elements::Li.new
        li << feature
        ul << li
      end
    end
    page << Components::Elements::RawHTML.new(features.render)
  end
  
  about_layout << Components::Elements::RawHTML.new(about_content.render)
  File.write("output/about.html", about_layout.render)
  puts "Generated: output/about.html"
  
  puts "\nStatic site generated successfully!"
  puts "Open output/index.html in your browser to view the site."
end

# Run the generator
generate_static_site