require "../base/stateful_component"

module AssetPipeline
  module Components
    module Examples
      # Counter component with JavaScript state management
      class Counter < StatefulComponent
        property initial_count : Int32
        property min_value : Int32?
        property max_value : Int32?
        property step : Int32
        
        def initialize(@initial_count = 0, @min_value = nil, @max_value = nil, @step = 1, **attrs)
          super(**attrs)
          # Initialize CSS classes for different elements
          @css_classes = {
            "container" => ["counter", "counter-widget"],
            "display" => ["count", "count-display"],
            "increment" => ["btn", "btn-increment", "btn-small"],
            "decrement" => ["btn", "btn-decrement", "btn-small"],
            "controls" => ["counter-controls", "btn-group"]
          }
        end
        
        def render_content : String
          container_attrs = {
            "class" => css_classes["container"].join(" ")
          }
          
          # Add data attributes
          build_data_attributes.each do |key, value|
            container_attrs["data-#{key}"] = value
          end
          
          controls_attrs = {
            "class" => css_classes["controls"].join(" ")
          }
          
          decrement_attrs = {
            "class" => css_classes["decrement"].join(" "),
            "data-action" => "decrement",
            "type" => "button"
          }
          if at_min_value?
            decrement_attrs["disabled"] = "disabled"
          end
          
          display_attrs = {
            "class" => css_classes["display"].join(" ")
          }
          
          increment_attrs = {
            "class" => css_classes["increment"].join(" "),
            "data-action" => "increment",
            "type" => "button"
          }
          if at_max_value?
            increment_attrs["disabled"] = "disabled"
          end
          
          controls_content = build_tag("button", "-", decrement_attrs) +
                           build_tag("span", @initial_count.to_s, display_attrs) +
                           build_tag("button", "+", increment_attrs)
          
          controls_div = build_tag("div", controls_content, controls_attrs)
          build_tag("div", controls_div, container_attrs)
        end
        
        private def build_tag(name : String, content : String, attrs : Hash(String, String)) : String
          attr_string = serialize_tag_attributes(attrs)
          "<#{name}#{attr_string}>#{escape_html(content)}</#{name}>"
        end
        
        private def serialize_tag_attributes(attrs : Hash(String, String)) : String
          return "" if attrs.empty?
          
          attr_pairs = attrs.map do |key, value|
            escaped_value = escape_html_attribute(value)
            %(#{key}="#{escaped_value}")
          end
          
          " #{attr_pairs.join(" ")}"
        end
        
        private def escape_html(content : String) : String
          content
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub("\"", "&quot;")
            .gsub("'", "&#39;")
        end
        
        private def escape_html_attribute(value : String) : String
          value
            .gsub("&", "&amp;")
            .gsub("\"", "&quot;")
            .gsub("'", "&#39;")
        end
        
        def javascript_content : String
          <<-JS
          class #{javascript_class_name} {
            constructor(element) {
              this.element = element;
              this.countElement = element.querySelector('#{css_selectors["display"]}');
              this.incrementBtn = element.querySelector('#{css_selectors["increment"]}');
              this.decrementBtn = element.querySelector('#{css_selectors["decrement"]}');
              
              // Initialize state from data attributes
              this.count = parseInt(element.dataset.count) || 0;
              this.minValue = element.dataset.minValue ? parseInt(element.dataset.minValue) : null;
              this.maxValue = element.dataset.maxValue ? parseInt(element.dataset.maxValue) : null;
              this.step = parseInt(element.dataset.step) || 1;
              
              this.bindEvents();
              this.updateDisplay();
            }
            
            bindEvents() {
              this.incrementBtn.addEventListener('click', () => this.increment());
              this.decrementBtn.addEventListener('click', () => this.decrement());
              
              // Custom events for external integration
              this.element.addEventListener('counter:set', (event) => {
                this.setValue(event.detail.value);
              });
              
              this.element.addEventListener('counter:reset', () => {
                this.reset();
              });
            }
            
            increment() {
              if (this.canIncrement()) {
                this.count += this.step;
                this.updateDisplay();
                this.emitChangeEvent();
              }
            }
            
            decrement() {
              if (this.canDecrement()) {
                this.count -= this.step;
                this.updateDisplay();
                this.emitChangeEvent();
              }
            }
            
            setValue(value) {
              const newValue = parseInt(value);
              if (!isNaN(newValue)) {
                this.count = this.clampValue(newValue);
                this.updateDisplay();
                this.emitChangeEvent();
              }
            }
            
            reset() {
              this.count = parseInt(this.element.dataset.initialCount) || 0;
              this.updateDisplay();
              this.emitChangeEvent();
            }
            
            canIncrement() {
              return this.maxValue === null || this.count < this.maxValue;
            }
            
            canDecrement() {
              return this.minValue === null || this.count > this.minValue;
            }
            
            clampValue(value) {
              if (this.minValue !== null && value < this.minValue) return this.minValue;
              if (this.maxValue !== null && value > this.maxValue) return this.maxValue;
              return value;
            }
            
            updateDisplay() {
              this.countElement.textContent = this.count;
              
              // Update button states
              this.incrementBtn.disabled = !this.canIncrement();
              this.decrementBtn.disabled = !this.canDecrement();
              
              // Update CSS classes based on state
              this.element.classList.toggle('at-min', !this.canDecrement());
              this.element.classList.toggle('at-max', !this.canIncrement());
            }
            
            emitChangeEvent() {
              const event = new CustomEvent('counter:change', {
                detail: { 
                  value: this.count,
                  canIncrement: this.canIncrement(),
                  canDecrement: this.canDecrement()
                },
                bubbles: true
              });
              this.element.dispatchEvent(event);
            }
          }
          JS
        end
        
        def css_content : String
          <<-CSS
          .counter {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem;
            border: 1px solid #ddd;
            border-radius: 0.25rem;
            background: #fff;
          }
          
          .counter-controls {
            display: flex;
            align-items: center;
            gap: 0.25rem;
          }
          
          .count-display {
            min-width: 3rem;
            text-align: center;
            font-weight: bold;
            font-size: 1.1rem;
            padding: 0.25rem 0.5rem;
            border: 1px solid #eee;
            border-radius: 0.125rem;
            background: #f9f9f9;
          }
          
          .btn-increment,
          .btn-decrement {
            width: 2rem;
            height: 2rem;
            border: 1px solid #ccc;
            background: #fff;
            border-radius: 0.25rem;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.2s ease;
          }
          
          .btn-increment:hover:not(:disabled),
          .btn-decrement:hover:not(:disabled) {
            background: #f0f0f0;
            border-color: #999;
          }
          
          .btn-increment:disabled,
          .btn-decrement:disabled {
            opacity: 0.5;
            cursor: not-allowed;
          }
          
          .counter.at-min .btn-decrement,
          .counter.at-max .btn-increment {
            opacity: 0.3;
          }
          CSS
        end
        
        # Check if at minimum value
        def at_min_value? : Bool
          return false if @min_value.nil?
          @initial_count <= @min_value.not_nil!
        end
        
        # Check if at maximum value
        def at_max_value? : Bool
          return false if @max_value.nil?
          @initial_count >= @max_value.not_nil!
        end
        
        # Static constructor methods
        def self.with_range(initial = 0, min = 0, max = 100, **attrs)
          new(initial, min, max, **attrs)
        end
        
        def self.unlimited(initial = 0, **attrs)
          new(initial, **attrs)
        end
        
        private def build_data_attributes
          data = {
            "component" => "counter",
            "count" => @initial_count.to_s,
            "initial-count" => @initial_count.to_s,
            "step" => @step.to_s
          }
          
          data["min-value"] = @min_value.to_s if @min_value
          data["max-value"] = @max_value.to_s if @max_value
          
          data
        end

        # Provide JavaScript content for this stateful component
        def javascript_content : String
          <<-JS
          // Counter Component JavaScript - Embedded implementation
          if (typeof Counter === 'undefined') {
            class Counter extends StatefulComponentJS {
              initialize() {
                this.minValue = parseInt(this.element.dataset.minValue) || null;
                this.maxValue = parseInt(this.element.dataset.maxValue) || null;
                
                this.countDisplay = this.find('.count-display');
                this.incrementButton = this.find('[data-action="increment"]');
                this.decrementButton = this.find('[data-action="decrement"]');
                
                if (!this.state.hasOwnProperty('count')) {
                  this.setState('count', parseInt(this.element.dataset.count) || 0, true);
                }
                
                this.updateDisplay();
              }

              bindEvents() {
                this.addEventListener('click', '[data-action="increment"]', this.handleIncrement.bind(this));
                this.addEventListener('click', '[data-action="decrement"]', this.handleDecrement.bind(this));
                this.addEventListener('keydown', this.element, this.handleKeydown.bind(this));
                
                if (!this.element.hasAttribute('tabindex')) {
                  this.element.setAttribute('tabindex', '0');
                }
              }

              handleIncrement(event) {
                event.preventDefault();
                this.increment();
              }

              handleDecrement(event) {
                event.preventDefault();
                this.decrement();
              }

              handleKeydown(event) {
                switch (event.key) {
                  case 'ArrowUp':
                  case '+':
                    event.preventDefault();
                    this.increment();
                    break;
                  case 'ArrowDown':
                  case '-':
                    event.preventDefault();
                    this.decrement();
                    break;
                }
              }

              increment() {
                const currentCount = this.getState('count');
                const newCount = currentCount + 1;
                
                if (this.maxValue === null || newCount <= this.maxValue) {
                  this.setCount(newCount);
                }
              }

              decrement() {
                const currentCount = this.getState('count');
                const newCount = currentCount - 1;
                
                if (this.minValue === null || newCount >= this.minValue) {
                  this.setCount(newCount);
                }
              }

              setCount(value) {
                const numValue = parseInt(value);
                if (isNaN(numValue)) return;
                
                if (this.minValue !== null && numValue < this.minValue) {
                  value = this.minValue;
                }
                if (this.maxValue !== null && numValue > this.maxValue) {
                  value = this.maxValue;
                }
                
                this.setState('count', value);
              }

              onStateChange(prevState, currentState) {
                if (prevState.count !== currentState.count) {
                  this.updateDisplay();
                  this.updateButtonStates();
                }
              }

              updateDisplay() {
                if (this.countDisplay) {
                  const count = this.getState('count');
                  this.countDisplay.textContent = count.toString();
                }
              }

              updateButtonStates() {
                const count = this.getState('count');
                
                if (this.incrementButton) {
                  const canIncrement = this.maxValue === null || count < this.maxValue;
                  this.incrementButton.disabled = !canIncrement;
                }
                
                if (this.decrementButton) {
                  const canDecrement = this.minValue === null || count > this.minValue;
                  this.decrementButton.disabled = !canDecrement;
                }
              }

              onMount() {
                this.element.setAttribute('role', 'spinbutton');
                this.updateButtonStates();
              }

              update() {
                this.updateDisplay();
                this.updateButtonStates();
              }
            }

            // Register the component
            if (typeof window !== 'undefined' && window.componentManager) {
              window.componentManager.register('counter', Counter);
            }
          }
          JS
        end
      end
    end
  end
end 