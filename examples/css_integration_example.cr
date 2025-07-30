require "../src/components"

# Example component using the CSS integration
class StyledCard < Components::Component
  include Components::CSS::Styleable
  include Components::Elements
  
  property title : String
  property content : String
  property? featured : Bool = false
  
  def initialize(@title : String, @content : String, @featured = false)
    super()
  end
  
  def render_content : String
    div(class: card_classes) do
      h2(class: title_classes) { @title }
      p(class: content_classes) { @content }
      
      if featured?
        span(class: badge_classes) { "Featured" }
      end
    end
  end
  
  private def card_classes
    css do |c|
      c.base("bg-white", "rounded-lg", "shadow-md", "p-6", "mb-4")
       .add("border-2 border-blue-500", featured?)
       .hover("shadow-lg")
       .responsive do |r|
         r.md("p-8")
          .lg("p-10")
       end
    end
  end
  
  private def title_classes
    class_names(
      base: "text-xl font-bold mb-2",
      featured: featured? ? "text-blue-600" : "text-gray-900",
      dark: "dark:text-white"
    )
  end
  
  private def content_classes
    variant_classes("text", size: "base", state: "gray-700")
  end
  
  private def badge_classes
    merge_classes(
      "inline-block",
      "px-3 py-1",
      "text-sm",
      "bg-blue-100 text-blue-800",
      "rounded-full"
    )
  end
end

# Example layout using utility classes
class ModernLayout < Components::Component
  include Components::CSS::Styleable
  include Components::Elements
  
  def initialize
    super()
  end
  
  def render_content : String
    div(class: "min-h-screen bg-gray-50") do
      # Header
      header(class: header_classes) do
        div(class: "container mx-auto px-4") do
          nav(class: "flex items-center justify-between h-16") do
            # Logo
            div(class: "text-xl font-bold text-gray-900") { "My App" }
            
            # Navigation
            ul(class: "flex space-x-6") do
              ["Home", "About", "Services", "Contact"].each do |item|
                li do
                  a(href: "#", class: nav_link_classes) { item }
                end
              end
            end
          end
        end
      end
      
      # Main content
      main(class: "container mx-auto px-4 py-8") do
        # Hero section
        section(class: hero_classes) do
          h1(class: "text-4xl md:text-5xl font-bold mb-4") do
            "Welcome to Our Modern App"
          end
          p(class: "text-xl text-gray-600 mb-8") do
            "Built with our powerful component system and utility-first CSS"
          end
          
          # Buttons
          div(class: "flex gap-4") do
            button(class: primary_button_classes) { "Get Started" }
            button(class: secondary_button_classes) { "Learn More" }
          end
        end
        
        # Cards grid
        section(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-12") do
          [
            {title: "Fast", content: "Lightning fast performance with optimized CSS", featured: true},
            {title: "Flexible", content: "Build any design with utility classes", featured: false},
            {title: "Modern", content: "Using the latest web technologies", featured: false},
          ].each do |card_data|
            StyledCard.new(
              card_data[:title],
              card_data[:content],
              card_data[:featured]
            ).render
          end
        end
      end
      
      # Footer
      footer(class: "bg-gray-900 text-white py-8 mt-16") do
        div(class: "container mx-auto px-4 text-center") do
          p { "© 2024 My App. All rights reserved." }
        end
      end
    end
  end
  
  private def header_classes
    css do |c|
      c.base("bg-white", "shadow-sm")
       .add("sticky", "top-0", "z-50")
    end
  end
  
  private def nav_link_classes
    css do |c|
      c.base("text-gray-600", "transition-colors")
       .hover("text-gray-900")
    end
  end
  
  private def hero_classes
    css do |c|
      c.base("text-center", "py-16")
       .responsive do |r|
         r.md("py-20")
          .lg("py-24")
       end
    end
  end
  
  private def primary_button_classes
    css do |c|
      c.base("px-6", "py-3", "bg-blue-600", "text-white", "rounded-lg")
       .add("font-semibold", "transition-all")
       .hover("bg-blue-700", "shadow-lg")
       .focus("outline-none", "ring-4", "ring-blue-300")
    end
  end
  
  private def secondary_button_classes
    css do |c|
      c.base("px-6", "py-3", "bg-gray-200", "text-gray-800", "rounded-lg")
       .add("font-semibold", "transition-all")
       .hover("bg-gray-300")
       .focus("outline-none", "ring-4", "ring-gray-300")
    end
  end
end

# Generate the CSS based on usage
require "../src/components/css/scanner/class_scanner"
require "../src/components/assets/css_asset"

# Scan for classes (in a real app, this would scan your source files)
scanner = Components::CSS::Scanner::ClassScanner.new(["./examples"])
scanner.scan

# Create CSS asset
css_config = Components::CSS::Config.new
css_asset = Components::Assets::CSS.create(css_config, :development)

# Generate the output directly
html_output = String.build do |str|
  str << "<!DOCTYPE html>\n"
  str << "<html lang=\"en\">\n"
  str << "<head>\n"
  str << "  <title>CSS Integration Example</title>\n"
  str << "  " << css_asset.to_style_tag << "\n"
  str << "</head>\n"
  str << "<body>\n"
  str << ModernLayout.new.render
  str << "</body>\n"
  str << "</html>"
end

# Output the example
puts "=== CSS Integration Example ==="
puts html_output
puts "\n=== Generated CSS ==="
puts css_asset.process[0..1000] + "..." # Show first 1000 chars
puts "\n=== Class Registry Stats ==="
puts Components::CSS::ClassRegistry.instance.export_usage