require "../base/stateless_component"
require "../elements/grouping/div"
require "../elements/sections/headings"
require "../elements/grouping/p"
require "../elements/embedded/img"

module Components
  module Examples
    # A reusable card component
    class CardComponent < StatelessComponent
      def render_content : String
        # Extract component props
        title = @attributes["title"]?
        subtitle = @attributes["subtitle"]?
        image_url = @attributes["image_url"]?
        image_alt = @attributes["image_alt"]? || ""
        
        # Build card structure
        card = Elements::Div.new(class: "card").build do |c|
          # Add image if provided
          if image_url
            c << Elements::Img.new(
              src: image_url,
              alt: image_alt,
              class: "card-img-top"
            )
          end
          
          # Card body
          c << Elements::Div.new(class: "card-body").build do |body|
            # Title
            if title
              h5 = Elements::H5.new(class: "card-title")
              h5 << title
              body << h5
            end
            
            # Subtitle
            if subtitle
              h6 = Elements::H6.new(class: "card-subtitle mb-2 text-muted")
              h6 << subtitle
              body << h6
            end
            
            # Content (children)
            unless @children.empty?
              content_div = Elements::Div.new(class: "card-text")
              @children.each do |child|
                case child
                when Component
                  content_div << child.render
                when Elements::HTMLElement
                  content_div << child
                when String
                  content_div << child
                end
              end
              body << content_div
            end
          end
        end
        
        card.render
      end
    end
  end
end