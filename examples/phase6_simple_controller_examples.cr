require "../src/asset_pipeline"

# =============================================================================
# Phase 6.2.1: Simple Single-Controller Setup Examples
# =============================================================================
#
# This file demonstrates simple, practical setups with single controllers
# Perfect for learning AssetPipeline basics and understanding the fundamentals

puts "=== Phase 6.2.1: Simple Single-Controller Setup Examples ==="
puts

# Example 1: Basic Hello World Controller
# ----------------------------------------------------------------------------
puts "📝 Example 1: Basic Hello World Controller"

def example_1_basic_hello_world
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Add Stimulus framework
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  
  # Add single hello controller
  import_map.add_import("HelloController", "hello_controller.js")
  
  # Simple initialization with basic logging
  custom_js = <<-JS
    console.log('Hello World Stimulus app ready!');
    
    // Simple custom functionality
    document.addEventListener('DOMContentLoaded', () => {
      console.log('DOM loaded, controllers ready to connect');
    });
  JS
  
  # Generate complete HTML
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(custom_js)
  }
end

result = example_1_basic_hello_world
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- Single controller setup"
puts "- Automatic controller detection"
puts "- Basic Stimulus application initialization"
puts "- Custom JavaScript integration"
puts "=" * 80
puts

# Example 2: Modal Controller with jQuery
# ----------------------------------------------------------------------------
puts "📝 Example 2: Modal Controller with External Library (jQuery)"

def example_2_modal_with_jquery
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Core framework
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  
  # External library
  import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true)
  
  # Single modal controller
  import_map.add_import("ModalController", "modal_controller.js")
  
  # jQuery integration code
  modal_js = <<-JS
    // jQuery utilities available globally for all controllers
    window.showModal = function(selector) {
      $(selector).fadeIn(300);
    };
    
    window.hideModal = function(selector) {
      $(selector).fadeOut(300);
    };
    
    // Global modal event handlers
    $(document).on('click', '.modal-backdrop', function(e) {
      if (e.target === this) {
        hideModal(this);
      }
    });
    
    console.log('Modal system with jQuery ready');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(modal_js)
  }
end

result = example_2_modal_with_jquery
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- External library integration (jQuery)"
puts "- Global utility functions for controller use"
puts "- Event delegation patterns"
puts "- Mixed Stimulus + jQuery approach"
puts "=" * 80
puts

# Example 3: Form Controller with Validation
# ----------------------------------------------------------------------------
puts "📝 Example 3: Form Controller with Client-Side Validation"

def example_3_form_validation
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Framework and utilities
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("validator", "https://cdn.jsdelivr.net/npm/validator@13.11.0/+esm")
  
  # Single form controller
  import_map.add_import("FormController", "form_controller.js")
  
  # Validation setup
  validation_js = <<-JS
    // Global validation utilities using validator.js
    window.validateEmail = function(email) {
      return validator.isEmail(email);
    };
    
    window.validateRequired = function(value) {
      return validator.isLength(value, { min: 1 });
    };
    
    window.validateMinLength = function(value, min = 8) {
      return validator.isLength(value, { min });
    };
    
    // Global form utilities
    window.showValidationError = function(element, message) {
      const errorDiv = element.parentNode.querySelector('.validation-error');
      if (errorDiv) {
        errorDiv.textContent = message;
        errorDiv.style.display = 'block';
      }
      element.classList.add('error');
    };
    
    window.hideValidationError = function(element) {
      const errorDiv = element.parentNode.querySelector('.validation-error');
      if (errorDiv) {
        errorDiv.style.display = 'none';
      }
      element.classList.remove('error');
    };
    
    console.log('Form validation system ready');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(validation_js)
  }
end

result = example_3_form_validation
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- External validation library (validator.js)"
puts "- Global utility functions for form handling"
puts "- Reusable validation helpers"
puts "- Error display management"
puts "=" * 80
puts

# Example 4: Chart Controller with Minimal Setup
# ----------------------------------------------------------------------------
puts "📝 Example 4: Chart Controller with Chart.js"

def example_4_chart_controller
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Framework and charting
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
  
  # Single chart controller
  import_map.add_import("ChartController", "chart_controller.js")
  
  # Chart setup utilities
  chart_js = <<-JS
    // Global chart configuration
    Chart.defaults.responsive = true;
    Chart.defaults.maintainAspectRatio = false;
    
    // Common chart utilities
    window.createLineChart = function(ctx, data, options = {}) {
      return new Chart(ctx, {
        type: 'line',
        data: data,
        options: {
          ...Chart.defaults,
          ...options
        }
      });
    };
    
    window.createBarChart = function(ctx, data, options = {}) {
      return new Chart(ctx, {
        type: 'bar',
        data: data,
        options: {
          ...Chart.defaults,
          ...options
        }
      });
    };
    
    // Sample data generator
    window.generateSampleData = function(labels, dataPoints) {
      return {
        labels: labels,
        datasets: [{
          label: 'Sample Data',
          data: dataPoints,
          borderColor: 'rgb(75, 192, 192)',
          backgroundColor: 'rgba(75, 192, 192, 0.2)',
          tension: 0.1
        }]
      };
    };
    
    console.log('Chart.js system ready');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(chart_js)
  }
end

result = example_4_chart_controller
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- Chart.js integration"
puts "- Global chart configuration"
puts "- Reusable chart creation utilities"
puts "- Sample data generation helpers"
puts "=" * 80
puts

# Example 5: Search Controller with Debouncing
# ----------------------------------------------------------------------------
puts "📝 Example 5: Search Controller with Lodash Debouncing"

def example_5_search_debounce
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Framework and utilities
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
  
  # Single search controller
  import_map.add_import("SearchController", "search_controller.js")
  
  # Search utilities with debouncing
  search_js = <<-JS
    // Global search utilities using lodash
    window.debouncedSearch = debounce(function(query, callback) {
      if (query.length < 2) {
        callback([]);
        return;
      }
      
      // Simulate API call
      console.log(`Searching for: ${query}`);
      
      // Mock search results
      const mockResults = [
        `Result 1 for "${query}"`,
        `Result 2 for "${query}"`,
        `Result 3 for "${query}"`
      ];
      
      // Simulate network delay
      setTimeout(() => callback(mockResults), 300);
    }, 300);
    
    // Search result rendering utility
    window.renderSearchResults = function(results, container) {
      if (!container) return;
      
      if (results.length === 0) {
        container.innerHTML = '<p class="no-results">No results found</p>';
        return;
      }
      
      const resultHtml = results.map(result => 
        `<div class="search-result">${result}</div>`
      ).join('');
      
      container.innerHTML = resultHtml;
    };
    
    // Loading state management
    window.showSearchLoading = function(container) {
      if (container) {
        container.innerHTML = '<p class="loading">Searching...</p>';
      }
    };
    
    console.log('Search system with debouncing ready');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(search_js)
  }
end

result = example_5_search_debounce
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- Lodash integration for debouncing"
puts "- Search functionality with performance optimization"
puts "- Mock API simulation"
puts "- Result rendering utilities"
puts "=" * 80
puts

# Example 6: Development Mode with Dependency Analysis
# ----------------------------------------------------------------------------
puts "📝 Example 6: Development Mode with Dependency Analysis"

def example_6_development_mode
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Framework only (missing dependencies on purpose for demonstration)
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("DevController", "dev_controller.js")
  
  # JavaScript with missing dependencies (for development analysis)
  dev_js = <<-JS
    // This code has missing dependencies - AssetPipeline will warn us
    const today = dayjs().format('YYYY-MM-DD');
    const debouncedFn = debounce(() => console.log('search'), 300);
    
    // jQuery usage without import
    $('.dev-panel').toggle();
    
    // Chart.js usage without import
    new Chart(ctx, {type: 'line', data: chartData});
    
    console.log('Development mode active');
  JS
  
  # Use dependency analysis to catch missing imports
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_initialization_script_with_analysis(dev_js)
  }
end

result = example_6_development_mode
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script with Analysis:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- Dependency analysis mode"
puts "- Missing dependency warnings"
puts "- Development-time error catching"
puts "- Import suggestions in comments"
puts "=" * 80
puts

# Example 7: Production-Ready Single Controller
# ----------------------------------------------------------------------------
puts "📝 Example 7: Production-Ready Single Controller Setup"

def example_7_production_ready
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Production-optimized imports with preloading
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("NotificationController", "notification_controller.js", preload: true)
  
  # Production JavaScript with error handling
  production_js = <<-JS
    // Error tracking setup for production
    window.logError = function(error, context = 'Unknown') {
      console.error(`[${context}]`, error);
      
      // In production, send to error tracking service
      if (window.errorTracker && typeof window.errorTracker.report === 'function') {
        window.errorTracker.report(error, { context, timestamp: new Date().toISOString() });
      }
    };
    
    // Global error handler
    window.addEventListener('error', (event) => {
      logError(event.error, 'Global Error Handler');
    });
    
    // Unhandled promise rejection handler
    window.addEventListener('unhandledrejection', (event) => {
      logError(event.reason, 'Unhandled Promise Rejection');
    });
    
    // Performance monitoring
    if ('performance' in window && 'measure' in window.performance) {
      window.performance.mark('stimulus-start');
      
      document.addEventListener('DOMContentLoaded', () => {
        window.performance.mark('stimulus-dom-ready');
        window.performance.measure('stimulus-init', 'stimulus-start', 'stimulus-dom-ready');
        
        const measure = window.performance.getEntriesByName('stimulus-init')[0];
        console.log(`Stimulus initialization: ${measure.duration.toFixed(2)}ms`);
      });
    }
    
    console.log('Production Stimulus app initialized');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(production_js)
  }
end

result = example_7_production_ready
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- Production-ready error handling"
puts "- Performance monitoring"
puts "- Global error tracking setup"
puts "- Resource preloading optimization"
puts "=" * 80
puts

# Summary of Simple Controller Examples
# ----------------------------------------------------------------------------
puts "🎯 Summary: Simple Single-Controller Setup Examples"
puts
puts "✅ Completed Examples:"
puts "1. Basic Hello World Controller - Minimal setup"
puts "2. Modal Controller with jQuery - External library integration"
puts "3. Form Controller with Validation - Utility library usage"
puts "4. Chart Controller with Chart.js - Data visualization setup"
puts "5. Search Controller with Debouncing - Performance optimization"
puts "6. Development Mode - Dependency analysis and warnings"
puts "7. Production-Ready Setup - Error handling and monitoring"
puts
puts "📚 Key Concepts Demonstrated:"
puts "- Single controller registration and detection"
puts "- External library integration patterns"
puts "- Global utility function setup"
puts "- Development vs production configurations"
puts "- Dependency analysis and debugging"
puts "- Performance optimization techniques"
puts "- Error handling and monitoring"
puts
puts "📁 Next: Complex multi-controller applications (Phase 6.2.2)"
puts "=" * 80 