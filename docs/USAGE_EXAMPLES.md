# AssetPipeline Usage Examples

This document provides practical usage examples and common patterns for the AssetPipeline library. From basic setups to advanced integration scenarios.

## Table of Contents

- [Basic Usage Patterns](#basic-usage-patterns)
- [Stimulus Framework Integration](#stimulus-framework-integration)
- [Advanced Scenarios](#advanced-scenarios)
- [Common Patterns](#common-patterns)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Basic Usage Patterns

### 1. Simple Library Integration

**Scenario**: Adding jQuery and a utility library to your application.

```crystal
require "asset_pipeline"

# Setup
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Add dependencies
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true)
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")

# Custom JavaScript
custom_js = <<-JS
  $(document).ready(function() {
    console.log('jQuery loaded!');
    
    // Use lodash for utility functions
    const data = [1, 2, 3, 4, 5];
    const doubled = _.map(data, n => n * 2);
    console.log('Doubled:', doubled);
  });
JS

# Generate HTML output
puts front_loader.render_import_map_tag
puts front_loader.render_initialization_script(custom_js)
```

**Output**:
```html
<script type="importmap">{"imports": {"jquery": "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", "lodash": "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm"}}</script>
<link rel="modulepreload" href="https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js">

<script type="module">
import $ from "jquery";
import _ from "lodash";

$(document).ready(function() {
  console.log('jQuery loaded!');
  
  const data = [1, 2, 3, 4, 5];
  const doubled = _.map(data, n => n * 2);
  console.log('Doubled:', doubled);
});
</script>
```

### 2. Multiple Import Maps

**Scenario**: Different import maps for different sections of your application.

```crystal
front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  # Main application import map
  app_map = AssetPipeline::ImportMap.new("application")
  app_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")
  app_map.add_import("UserController", "user_controller.js")
  import_maps << app_map
  
  # Admin-specific import map
  admin_map = AssetPipeline::ImportMap.new("admin")
  admin_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")
  admin_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
  admin_map.add_import("AdminController", "admin_controller.js")
  import_maps << admin_map
end

# Render different scripts for different pages
puts "<!-- Main Application -->"
puts front_loader.render_import_map_tag("application")
puts front_loader.render_initialization_script("console.log('Main app');", "application")

puts "<!-- Admin Dashboard -->"
puts front_loader.render_import_map_tag("admin")
puts front_loader.render_initialization_script("console.log('Admin dashboard');", "admin")
```

### 3. Dependency Analysis for Development

**Scenario**: Using dependency analysis to catch missing imports during development.

```crystal
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")

# JavaScript with missing dependencies
development_js = <<-JS
  // jQuery is available
  $('.app').fadeIn();
  
  // These are missing from import map (will generate warnings)
  const today = dayjs().format('YYYY-MM-DD');
  const debouncedFn = debounce(() => console.log('search'), 300);
  
  // Chart.js also missing
  new Chart(ctx, {type: 'line', data: chartData});
JS

# Use analysis mode to catch missing dependencies
result = front_loader.render_initialization_script_with_analysis(development_js)
puts result
```

**Output with warnings**:
```html
<script type="module">
// WARNING: Add to import map: import_map.add_import("dayjs", "...")
// WARNING: Add to import map: import_map.add_import("lodash", "...")
// WARNING: Add to import map: import_map.add_import("Chart", "...")

import $ from "jquery";

$('.app').fadeIn();

const today = dayjs().format('YYYY-MM-DD');
const debouncedFn = debounce(() => console.log('search'), 300);

new Chart(ctx, {type: 'line', data: chartData});
</script>
```

---

## Stimulus Framework Integration

### 1. Basic Stimulus Setup

**Scenario**: Setting up Stimulus with automatic controller detection.

```crystal
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Add Stimulus framework
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Add controllers (automatically detected)
import_map.add_import("HelloController", "hello_controller.js")
import_map.add_import("DropdownController", "dropdown_controller.js")
import_map.add_import("ModalController", "modal_controller.js")

# Custom initialization code
stimulus_js = <<-JS
  console.log('Stimulus application ready!');
  
  // Custom event handlers
  document.addEventListener('stimulus:ready', () => {
    console.log('All controllers registered');
  });
JS

# Generate Stimulus-optimized output
puts front_loader.render_import_map_tag
puts front_loader.render_stimulus_initialization_script(stimulus_js)
```

**Output**:
```html
<script type="importmap">{"imports": {"@hotwired/stimulus": "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", "HelloController": "/hello_controller.js", "DropdownController": "/dropdown_controller.js", "ModalController": "/modal_controller.js"}}</script>
<link rel="modulepreload" href="https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm">

<script type="module">
import { Application } from "@hotwired/stimulus";

import HelloController from "HelloController";
import DropdownController from "DropdownController";
import ModalController from "ModalController";

const application = Application.start();

console.log('Stimulus application ready!');

document.addEventListener('stimulus:ready', () => {
  console.log('All controllers registered');
});

application.register("hello", HelloController);
application.register("dropdown", DropdownController);
application.register("modal", ModalController);
</script>
```

### 2. Stimulus with Custom Application Name

**Scenario**: Multiple Stimulus applications with different names.

```crystal
# Main application
main_result = front_loader.render_stimulus_initialization_script(
  "console.log('Main Stimulus app');", 
  "application", 
  "mainApp"
)

# Admin application  
admin_result = front_loader.render_stimulus_initialization_script(
  "console.log('Admin Stimulus app');", 
  "admin", 
  "adminApp"
)
```

### 3. Stimulus with Existing Manual Code

**Scenario**: Migrating from manual Stimulus setup to automated detection.

```crystal
# Before: Manual controller imports and registrations
manual_stimulus_js = <<-JS
  import HelloController from "HelloController";
  import { Application } from "@hotwired/stimulus";
  
  const application = Application.start();
  application.register("hello", HelloController);
  
  console.log('Manual setup complete');
JS

# After: AssetPipeline automatically removes duplicates
result = front_loader.render_stimulus_initialization_script(manual_stimulus_js)
# Output will have clean, non-duplicate imports and registrations
```

---

## Advanced Scenarios

### 1. E-commerce Application

**Scenario**: Complex e-commerce application with mixed libraries and Stimulus controllers.

```crystal
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Essential libraries
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")

# E-commerce controllers
import_map.add_import("CartController", "cart_controller.js")
import_map.add_import("ProductController", "product_controller.js")
import_map.add_import("CheckoutController", "checkout_controller.js")
import_map.add_import("SearchController", "search_controller.js")

# Business logic
ecommerce_js = <<-JS
  // Chart.js setup for analytics
  Chart.register(...registerables);
  
  // Utility functions
  const formatPrice = (cents) => {
    return (cents / 100).toLocaleString('en-US', {
      style: 'currency',
      currency: 'USD'
    });
  };
  
  const debouncedSearch = debounce((query) => {
    fetch(`/search?q=${encodeURIComponent(query)}`)
      .then(response => response.json())
      .then(data => console.log('Search results:', data));
  }, 300);
  
  // Analytics initialization
  const initAnalytics = () => {
    const ctx = document.getElementById('sales-chart');
    if (ctx) {
      new Chart(ctx, {
        type: 'line',
        data: {
          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
          datasets: [{
            label: 'Sales',
            data: [12000, 15000, 18000, 14000, 22000],
            borderColor: 'rgb(75, 192, 192)'
          }]
        }
      });
    }
  };
  
  // App initialization
  document.addEventListener('DOMContentLoaded', () => {
    console.log('E-commerce app initialized at:', dayjs().format());
    initAnalytics();
  });
JS

puts front_loader.render_import_map_tag
puts front_loader.render_stimulus_initialization_script(ecommerce_js)
```

### 2. Dashboard Application with Scoped Imports

**Scenario**: Admin dashboard with different import scopes for different sections.

```crystal
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Global imports
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")

# Scoped imports for different admin sections
import_map.add_scope("/admin/users", "UserManagementController", "admin/user_management_controller.js")
import_map.add_scope("/admin/analytics", "AnalyticsController", "admin/analytics_controller.js")
import_map.add_scope("/admin/settings", "SettingsController", "admin/settings_controller.js")

# Global controllers
import_map.add_import("NavigationController", "navigation_controller.js")
import_map.add_import("NotificationController", "notification_controller.js")

dashboard_js = <<-JS
  // Global dashboard setup
  const showNotification = (message, type = 'info') => {
    const event = new CustomEvent('notification:show', {
      detail: { message, type }
    });
    document.dispatchEvent(event);
  };
  
  // Page-specific initialization based on current path
  const currentPath = window.location.pathname;
  
  if (currentPath.startsWith('/admin/analytics')) {
    // Analytics-specific setup
    Chart.register(...registerables);
    console.log('Analytics dashboard loaded');
  } else if (currentPath.startsWith('/admin/users')) {
    // User management setup
    console.log('User management loaded');
  }
  
  showNotification('Dashboard ready', 'success');
JS

puts front_loader.render_import_map_tag
puts front_loader.render_stimulus_initialization_script(dashboard_js)
```

### 3. Progressive Web App (PWA) Setup

**Scenario**: PWA with service worker integration and offline support.

```crystal
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# PWA essentials
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("workbox-sw", "https://storage.googleapis.com/workbox-cdn/releases/6.5.4/workbox-sw.js")

# PWA controllers
import_map.add_import("ServiceWorkerController", "service_worker_controller.js")
import_map.add_import("OfflineController", "offline_controller.js")
import_map.add_import("InstallController", "install_controller.js")

pwa_js = <<-JS
  // Service Worker registration
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js')
      .then(registration => {
        console.log('ServiceWorker registered:', registration);
      })
      .catch(error => {
        console.log('ServiceWorker registration failed:', error);
      });
  }
  
  // PWA install prompt
  let deferredPrompt;
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    
    // Show install button via Stimulus controller
    document.dispatchEvent(new CustomEvent('pwa:installable'));
  });
  
  // Offline detection
  window.addEventListener('online', () => {
    document.dispatchEvent(new CustomEvent('app:online'));
  });
  
  window.addEventListener('offline', () => {
    document.dispatchEvent(new CustomEvent('app:offline'));
  });
  
  console.log('PWA initialization complete');
JS

puts front_loader.render_import_map_tag
puts front_loader.render_stimulus_initialization_script(pwa_js)
```

---

## Common Patterns

### 1. Conditional Loading

**Pattern**: Load different libraries based on page or feature detection.

```crystal
# Base setup
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Conditional imports based on page type
page_type = "dashboard" # This would come from your application context

case page_type
when "dashboard"
  import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
  import_map.add_import("DashboardController", "dashboard_controller.js")
when "ecommerce"
  import_map.add_import("stripe", "https://js.stripe.com/v3/", preload: true)
  import_map.add_import("CartController", "cart_controller.js")
when "blog"
  import_map.add_import("highlight.js", "https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/+esm")
  import_map.add_import("EditorController", "editor_controller.js")
end

conditional_js = <<-JS
  console.log('Page type: #{page_type}');
  
  // Page-specific initialization
  document.addEventListener('DOMContentLoaded', () => {
    const pageType = '#{page_type}';
    document.body.setAttribute('data-page-type', pageType);
  });
JS

puts front_loader.render_stimulus_initialization_script(conditional_js)
```

### 2. Environment-Based Configuration

**Pattern**: Different configurations for development, staging, and production.

```crystal
# Environment detection (would come from your app config)
environment = "development" # or "staging", "production"

front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Always include Stimulus
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Environment-specific libraries
case environment
when "development"
  # Development tools
  import_map.add_import("@axe-core/react", "https://cdn.jsdelivr.net/npm/@axe-core/react@4.8.2/+esm")
  import_map.add_import("DebugController", "debug_controller.js")
when "production"
  # Production analytics
  import_map.add_import("gtag", "https://www.googletagmanager.com/gtag/js?id=GA_TRACKING_ID")
  import_map.add_import("AnalyticsController", "analytics_controller.js")
end

environment_js = <<-JS
  // Environment-specific setup
  const ENV = '#{environment}';
  
  if (ENV === 'development') {
    // Enable debug mode
    window.DEBUG = true;
    console.log('Debug mode enabled');
  } else if (ENV === 'production') {
    // Initialize analytics
    gtag('config', 'GA_TRACKING_ID');
  }
  
  console.log(`App running in ${ENV} mode`);
JS

puts front_loader.render_stimulus_initialization_script(environment_js)
```

### 3. Feature Flag Integration

**Pattern**: Conditionally load functionality based on feature flags.

```crystal
# Feature flags (would come from your feature flag system)
feature_flags = {
  "new_checkout" => true,
  "advanced_analytics" => false,
  "beta_features" => true
}

front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Conditional loading based on feature flags
if feature_flags["new_checkout"]
  import_map.add_import("NewCheckoutController", "new_checkout_controller.js")
  import_map.add_import("stripe", "https://js.stripe.com/v3/")
else
  import_map.add_import("LegacyCheckoutController", "legacy_checkout_controller.js")
end

if feature_flags["advanced_analytics"]
  import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
  import_map.add_import("AdvancedAnalyticsController", "advanced_analytics_controller.js")
end

if feature_flags["beta_features"]
  import_map.add_import("BetaController", "beta_controller.js")
end

feature_js = <<-JS
  // Feature flag configuration
  window.FEATURES = #{feature_flags.to_json};
  
  // Feature-specific initialization
  if (window.FEATURES.beta_features) {
    console.log('Beta features enabled');
    document.body.classList.add('beta-enabled');
  }
  
  console.log('Features loaded:', Object.keys(window.FEATURES).filter(f => window.FEATURES[f]));
JS

puts front_loader.render_stimulus_initialization_script(feature_js)
```

---

## Best Practices

### 1. Import Organization

**Best Practice**: Organize imports by type and priority.

```crystal
# ✅ Good: Organized by priority and type
import_map = front_loader.get_import_map

# Core framework (highest priority, preload)
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Essential libraries (preload if critical)
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true)

# Utility libraries (load on demand)
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")

# Application controllers (organize by feature)
import_map.add_import("NavigationController", "navigation_controller.js")
import_map.add_import("UserController", "user_controller.js")
import_map.add_import("ProductController", "product_controller.js")

# Feature-specific controllers
import_map.add_import("CheckoutController", "checkout_controller.js")
import_map.add_import("AnalyticsController", "analytics_controller.js")
```

### 2. Custom JavaScript Organization

**Best Practice**: Structure custom JavaScript for maintainability.

```crystal
organized_js = <<-JS
  // ===== UTILITY FUNCTIONS =====
  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  };
  
  const debounceSearch = debounce((query) => {
    // Search implementation
  }, 300);
  
  // ===== EVENT HANDLERS =====
  const handleGlobalEvents = () => {
    document.addEventListener('click', (e) => {
      // Global click handling
    });
    
    window.addEventListener('resize', debounce(() => {
      // Responsive adjustments
    }, 250));
  };
  
  // ===== INITIALIZATION =====
  const initializeApp = () => {
    console.log('App initialized');
    handleGlobalEvents();
    
    // Feature detection
    if ('IntersectionObserver' in window) {
      // Initialize lazy loading
    }
  };
  
  // ===== MAIN EXECUTION =====
  document.addEventListener('DOMContentLoaded', initializeApp);
JS

result = front_loader.render_stimulus_initialization_script(organized_js)
```

### 3. Error Handling

**Best Practice**: Include proper error handling and fallbacks.

```crystal
robust_js = <<-JS
  // Error handling setup
  const handleError = (error, context = 'Unknown') => {
    console.error(`Error in ${context}:`, error);
    
    // Send to error tracking service
    if (window.errorTracker) {
      window.errorTracker.report(error, { context });
    }
  };
  
  // Feature detection with fallbacks
  const safelyInitializeFeature = (feature, fallback) => {
    try {
      feature();
    } catch (error) {
      handleError(error, 'Feature initialization');
      if (fallback) fallback();
    }
  };
  
  // Robust initialization
  const initializeWithErrorHandling = () => {
    // Check for required dependencies
    if (typeof $ === 'undefined') {
      console.warn('jQuery not loaded, using vanilla JS fallbacks');
      return;
    }
    
    safelyInitializeFeature(() => {
      // Main feature initialization
      $('.modal').modal();
    }, () => {
      // Fallback implementation
      console.log('Modal fallback active');
    });
  };
  
  document.addEventListener('DOMContentLoaded', initializeWithErrorHandling);
JS

result = front_loader.render_stimulus_initialization_script(robust_js)
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Import Not Found

**Problem**: `import $ from "jquery"` results in module not found error.

**Solution**: Ensure the import is added to the import map:

```crystal
# ❌ Missing import
result = front_loader.render_initialization_script("$('#app').show();")
# Error: module not found

# ✅ Add the import first
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js")
result = front_loader.render_initialization_script("$('#app').show();")
# Works correctly
```

#### 2. Controller Not Registering

**Problem**: Stimulus controller exists in import map but doesn't register.

**Solution**: Ensure controller name ends with "Controller":

```crystal
# ❌ Won't be detected as controller
import_map.add_import("hello", "hello_controller.js")

# ✅ Will be auto-detected and registered
import_map.add_import("HelloController", "hello_controller.js")
```

#### 3. Duplicate Import Statements

**Problem**: Custom JavaScript contains import statements that duplicate import map entries.

**Solution**: Use Stimulus renderer which automatically removes duplicates:

```crystal
js_with_duplicates = <<-JS
  import HelloController from "HelloController"; // Will be removed
  import { Application } from "@hotwired/stimulus"; // Will be removed
  
  console.log('Custom code'); // Will be kept
JS

# ✅ Duplicates automatically removed
result = front_loader.render_stimulus_initialization_script(js_with_duplicates)
```

#### 4. Missing Dependency Warnings

**Problem**: Getting dependency warnings for libraries that should be ignored.

**Solution**: Add them to the import map or use filtering:

```crystal
# ❌ Will generate warnings
result = front_loader.render_initialization_script_with_analysis("dayjs().format();")

# ✅ Add to import map to remove warnings
import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")
result = front_loader.render_initialization_script_with_analysis("dayjs().format();")
```

---

This concludes the comprehensive usage examples. For more specific scenarios, see the [API Reference](API_REFERENCE.md) and [Migration Guide](MIGRATION_GUIDE.md). 