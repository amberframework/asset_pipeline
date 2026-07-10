require "../reactive/reactive_component"
require "../elements/forms/input"
require "../elements/grouping/div"
require "../elements/grouping/lists"

module Components
  module Examples
    # Live search component that updates results as you type
    class LiveSearchComponent < Reactive::ReactiveComponent
      component_css <<-CSS
      .am-live-search {
        display: grid;
        gap: 0.875rem;
      }

      .am-live-search__results {
        min-height: 2.75rem;
      }

      .am-live-search__status {
        align-items: center;
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-muted);
        display: flex;
        min-height: 2.75rem;
        padding: 0.75rem 0.875rem;
      }

      .am-live-search__list {
        display: grid;
        gap: 0.5rem;
        list-style: none;
        margin: 0;
        padding: 0;
      }

      .am-live-search__item {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-primary);
        padding: 0.75rem 0.875rem;
        transition: background-color var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          border-color var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          transform var(--ap-motion-duration-fast) var(--ap-motion-ease-standard);
      }

      .am-live-search__item:hover {
        background: var(--ap-color-state-hover);
        border-color: var(--ap-color-border-default);
        transform: translateY(-1px);
      }

      @media (prefers-reduced-motion: reduce) {
        .am-live-search__item {
          transition: none;
        }

        .am-live-search__item:hover {
          transform: none;
        }
      }
      CSS

      def initialize(**attrs)
        super
      end

      protected def initialize_state
        set_state("query", "")
        set_state("results", [] of JSON::Any)
        set_state("searching", false)
      end

      def render_content : String
        Elements::Div.new(class: "am-live-search").build do |container|
          # Search input
          search_input = Elements::Input.new(
            type: "text",
            placeholder: "Search...",
            value: get_state("query").try(&.as_s?) || "",
            class: "am-input",
            role: "searchbox",
            "data-action": "input->search"
          )
          container << search_input

          # Results container
          results_div = Elements::Div.new(class: "am-live-search__results", "aria-live": "polite")

          if get_state("searching").try(&.as_bool?)
            results_div << Elements::Div.new(class: "am-live-search__status", role: "status").build do |div|
              div << "Searching..."
            end
          else
            results = get_state("results").try(&.as_a?) || [] of JSON::Any

            if results.empty? && !get_state("query").try(&.as_s?).try(&.empty?)
              results_div << Elements::Div.new(class: "am-live-search__status", role: "status").build do |div|
                div << "No results found"
              end
            else
              ul = Elements::Ul.new(class: "am-live-search__list", role: "list")
              results.each do |result|
                li = Elements::Li.new(class: "am-live-search__item")
                li << (result["title"]?.try(&.as_s?) || "Untitled")
                ul << li
              end
              results_div << ul
            end
          end

          container << results_div
        end.render
      end

      # Handle search input
      def search(event : JSON::Any)
        query = event["value"]?.try(&.as_s?) || ""

        set_state("query", JSON::Any.new(query))
        set_state("searching", JSON::Any.new(true))

        # Simulate async search (in real app, this would call an API)
        spawn do
          sleep 0.5.seconds # Simulate network delay

          # Mock results based on query
          results = if query.empty?
                      [] of JSON::Any
                    else
                      (1..5).map do |i|
                        JSON::Any.new({
                          "id"    => JSON::Any.new(i),
                          "title" => JSON::Any.new("Result #{i} for '#{query}'"),
                        })
                      end
                    end

          # Update state (this will trigger a re-render)
          update_state do
            set_state("results", JSON::Any.new(results))
            set_state("searching", JSON::Any.new(false))
          end
        end
      end
    end
  end
end
