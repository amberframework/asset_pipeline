require "./html_element"

module AssetPipeline
  module Components
    module Html
      # Convenience methods for creating common HTML elements
      module HTMLHelpers
        # Text content elements
        
        def div(content = "", **attrs)
          HTMLElement.container("div", content, attrs.to_h)
        end
        
        def div(**attrs, &block)
          HTMLElement.container("div", attrs.to_h, &block)
        end
        
        def span(content = "", **attrs)
          HTMLElement.container("span", content, **attrs)
        end
        
        def span(**attrs, &block)
          HTMLElement.container("span", **attrs, &block)
        end
        
        def p(content = "", **attrs)
          HTMLElement.container("p", content, **attrs)
        end
        
        def p(**attrs, &block)
          HTMLElement.container("p", **attrs, &block)
        end
        
        # Heading elements
        
        def h1(content = "", **attrs)
          HTMLElement.container("h1", content, **attrs)
        end
        
        def h1(**attrs, &block)
          HTMLElement.container("h1", **attrs, &block)
        end
        
        def h2(content = "", **attrs)
          HTMLElement.container("h2", content, **attrs)
        end
        
        def h2(**attrs, &block)
          HTMLElement.container("h2", **attrs, &block)
        end
        
        def h3(content = "", **attrs)
          HTMLElement.container("h3", content, **attrs)
        end
        
        def h3(**attrs, &block)
          HTMLElement.container("h3", **attrs, &block)
        end
        
        def h4(content = "", **attrs)
          HTMLElement.container("h4", content, **attrs)
        end
        
        def h4(**attrs, &block)
          HTMLElement.container("h4", **attrs, &block)
        end
        
        def h5(content = "", **attrs)
          HTMLElement.container("h5", content, **attrs)
        end
        
        def h5(**attrs, &block)
          HTMLElement.container("h5", **attrs, &block)
        end
        
        def h6(content = "", **attrs)
          HTMLElement.container("h6", content, **attrs)
        end
        
        def h6(**attrs, &block)
          HTMLElement.container("h6", **attrs, &block)
        end
        
        # Form elements
        
        def input(**attrs)
          HTMLElement.self_closing("input", attrs.to_h)
        end
        
        def textarea(content = "", **attrs)
          HTMLElement.container("textarea", content, attrs.to_h)
        end
        
        def textarea(**attrs, &block)
          HTMLElement.container("textarea", attrs.to_h, &block)
        end
        
        def select(content = "", **attrs)
          HTMLElement.container("select", content, attrs.to_h)
        end
        
        def select(**attrs, &block)
          HTMLElement.container("select", attrs.to_h, &block)
        end
        
        def option(content = "", **attrs)
          HTMLElement.container("option", content, attrs.to_h)
        end
        
        def option(**attrs, &block)
          HTMLElement.container("option", attrs.to_h, &block)
        end
        
        def button(content = "", **attrs)
          HTMLElement.container("button", content, attrs.to_h)
        end
        
        def button(**attrs, &block)
          HTMLElement.container("button", attrs.to_h, &block)
        end
        
        def form(content = "", **attrs)
          HTMLElement.container("form", content, **attrs)
        end
        
        def form(**attrs, &block)
          HTMLElement.container("form", **attrs, &block)
        end
        
        def label(content = "", **attrs)
          HTMLElement.container("label", content, **attrs)
        end
        
        def label(**attrs, &block)
          HTMLElement.container("label", **attrs, &block)
        end
        
        # Semantic elements
        
        def header(content = "", **attrs)
          HTMLElement.container("header", content, **attrs)
        end
        
        def header(**attrs, &block)
          HTMLElement.container("header", **attrs, &block)
        end
        
        def footer(content = "", **attrs)
          HTMLElement.container("footer", content, **attrs)
        end
        
        def footer(**attrs, &block)
          HTMLElement.container("footer", **attrs, &block)
        end
        
        def nav(content = "", **attrs)
          HTMLElement.container("nav", content, **attrs)
        end
        
        def nav(**attrs, &block)
          HTMLElement.container("nav", **attrs, &block)
        end
        
        def main(content = "", **attrs)
          HTMLElement.container("main", content, **attrs)
        end
        
        def main(**attrs, &block)
          HTMLElement.container("main", **attrs, &block)
        end
        
        def section(content = "", **attrs)
          HTMLElement.container("section", content, **attrs)
        end
        
        def section(**attrs, &block)
          HTMLElement.container("section", **attrs, &block)
        end
        
        def article(content = "", **attrs)
          HTMLElement.container("article", content, **attrs)
        end
        
        def article(**attrs, &block)
          HTMLElement.container("article", **attrs, &block)
        end
        
        def aside(content = "", **attrs)
          HTMLElement.container("aside", content, **attrs)
        end
        
        def aside(**attrs, &block)
          HTMLElement.container("aside", **attrs, &block)
        end
        
        # List elements
        
        def ul(content = "", **attrs)
          HTMLElement.container("ul", content, **attrs)
        end
        
        def ul(**attrs, &block)
          HTMLElement.container("ul", **attrs, &block)
        end
        
        def ol(content = "", **attrs)
          HTMLElement.container("ol", content, **attrs)
        end
        
        def ol(**attrs, &block)
          HTMLElement.container("ol", **attrs, &block)
        end
        
        def li(content = "", **attrs)
          HTMLElement.container("li", content, **attrs)
        end
        
        def li(**attrs, &block)
          HTMLElement.container("li", **attrs, &block)
        end
        
        # Link and media elements
        
        def a(content = "", **attrs)
          HTMLElement.container("a", content, **attrs)
        end
        
        def a(**attrs, &block)
          HTMLElement.container("a", **attrs, &block)
        end
        
        def img(**attrs)
          HTMLElement.self_closing("img", **attrs)
        end
        
        def br(**attrs)
          HTMLElement.self_closing("br", **attrs)
        end
        
        def hr(**attrs)
          HTMLElement.self_closing("hr", **attrs)
        end
        
        # Table elements
        
        def table(content = "", **attrs)
          HTMLElement.container("table", content, **attrs)
        end
        
        def table(**attrs, &block)
          HTMLElement.container("table", **attrs, &block)
        end
        
        def thead(content = "", **attrs)
          HTMLElement.container("thead", content, **attrs)
        end
        
        def thead(**attrs, &block)
          HTMLElement.container("thead", **attrs, &block)
        end
        
        def tbody(content = "", **attrs)
          HTMLElement.container("tbody", content, **attrs)
        end
        
        def tbody(**attrs, &block)
          HTMLElement.container("tbody", **attrs, &block)
        end
        
        def tr(content = "", **attrs)
          HTMLElement.container("tr", content, **attrs)
        end
        
        def tr(**attrs, &block)
          HTMLElement.container("tr", **attrs, &block)
        end
        
        def th(content = "", **attrs)
          HTMLElement.container("th", content, **attrs)
        end
        
        def th(**attrs, &block)
          HTMLElement.container("th", **attrs, &block)
        end
        
        def td(content = "", **attrs)
          HTMLElement.container("td", content, **attrs)
        end
        
        def td(**attrs, &block)
          HTMLElement.container("td", **attrs, &block)
        end
      end
      
      # Extend the module to include the helpers
      extend HTMLHelpers
    end
  end
end 