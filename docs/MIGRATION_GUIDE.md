# AssetPipeline Migration Guide

This guide helps you migrate from manual JavaScript management to the automated AssetPipeline system. Whether you're coming from inline scripts, manual import maps, or other build tools, this guide provides step-by-step migration paths.

## Table of Contents

- [Migration Overview](#migration-overview)
- [Basic Migration Scenarios](#basic-migration-scenarios)
- [Stimulus Framework Migrations](#stimulus-framework-migrations)
- [Advanced Migration Patterns](#advanced-migration-patterns)
- [Step-by-Step Migrations](#step-by-step-migrations)
- [Common Migration Challenges](#common-migration-challenges)
- [Testing Your Migration](#testing-your-migration)

---

## Migration Overview

### Benefits of Migration

**Before AssetPipeline:**
- Manual import map management
- Duplicate import statements
- No dependency analysis
- Manual controller registration
- Complex script coordination

**After AssetPipeline:**
- Automatic import generation
- Smart duplicate removal
- Dependency analysis with warnings
- Automatic controller detection
- Simplified script management

### Migration Strategy

1. **Incremental Migration**: Migrate one page/feature at a time
2. **Parallel Approach**: Run old and new systems side-by-side during testing
3. **Feature Flags**: Use feature flags to control rollout
4. **Testing**: Validate functionality at each step

---

## Basic Migration Scenarios

### 1. From Inline Scripts to Import Maps

**Before: Inline Script Tags**
```html
<!-- old_app.html -->
<script src="https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js"></script>
<script>
  $(document).ready(function() {
    console.log('App ready');
    const data = [1, 2, 3];
    const doubled = _.map(data, n => n * 2);
    console.log(doubled);
  });
</script>
```

**After: AssetPipeline Import Maps**
```crystal
# app_controller.cr (or your template rendering location)
require "asset_pipeline"

def render_page
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Add the same libraries as CDN imports
  import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true)
  import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
  
  # Your custom JavaScript
  custom_js = <<-JS
    $(document).ready(function() {
      console.log('App ready');
      const data = [1, 2, 3];
      const doubled = _.map(data, n => n * 2);
      console.log(doubled);
    });
  JS
  
  # Generate the output
  import_map_html = front_loader.render_import_map_tag
  script_html = front_loader.render_initialization_script(custom_js)
  
  render_template(import_map_html, script_html)
end
```

**Template Output:**
```html
<!-- new_app.html -->
<script type="importmap">{"imports": {"jquery": "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", "lodash": "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm"}}</script>
<link rel="modulepreload" href="https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js">

<script type="module">
import $ from "jquery";
import _ from "lodash";

$(document).ready(function() {
  console.log('App ready');
  const data = [1, 2, 3];
  const doubled = _.map(data, n => n * 2);
  console.log(doubled);
});
</script>
```

### 2. From Manual Import Maps to AssetPipeline

**Before: Manual Import Map**
```html
<!-- manual_setup.html -->
<script type="importmap">
{
  "imports": {
    "jquery": "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js",
    "chart.js": "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm"
  }
}
</script>

<script type="module">
import $ from "jquery";
import Chart from "chart.js";

// Manual setup
$(document).ready(() => {
  const ctx = document.getElementById('chart');
  new Chart(ctx, {
    type: 'bar',
    data: {labels: ['A', 'B'], datasets: [{data: [1, 2]}]}
  });
});
</script>
```

**After: AssetPipeline Management**
```crystal
# Migration to AssetPipeline
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Same imports, but managed programmatically
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true)
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)

# Same custom logic
chart_js = <<-JS
  $(document).ready(() => {
    const ctx = document.getElementById('chart');
    new Chart(ctx, {
      type: 'bar',
      data: {labels: ['A', 'B'], datasets: [{data: [1, 2]}]}
    });
  });
JS

# AssetPipeline automatically generates imports
puts front_loader.render_import_map_tag
puts front_loader.render_initialization_script(chart_js)
```

### 3. From Build Tools to AssetPipeline

**Before: Webpack/Rollup Setup**
```javascript
// webpack.config.js
module.exports = {
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: __dirname + '/dist'
  },
  externals: {
    jquery: 'jQuery',
    lodash: '_'
  }
};

// src/index.js
import $ from 'jquery';
import _ from 'lodash';

$(document).ready(() => {
  const data = [1, 2, 3];
  console.log(_.map(data, n => n * 2));
});
```

**After: AssetPipeline (No Build Step)**
```crystal
# No build configuration needed!
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Define the same external dependencies
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true)
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")

# Same application logic (no bundling needed)
app_js = <<-JS
  $(document).ready(() => {
    const data = [1, 2, 3];
    console.log(_.map(data, n => n * 2));
  });
JS

# AssetPipeline handles the module setup
puts front_loader.render_import_map_tag
puts front_loader.render_initialization_script(app_js)
```

---

## Stimulus Framework Migrations

### 1. Manual Stimulus Setup to AssetPipeline

**Before: Manual Stimulus Configuration**
```html
<!-- manual_stimulus.html -->
<script type="importmap">
{
  "imports": {
    "@hotwired/stimulus": "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm",
    "HelloController": "/assets/hello_controller.js",
    "ModalController": "/assets/modal_controller.js"
  }
}
</script>

<script type="module">
import { Application } from "@hotwired/stimulus";
import HelloController from "HelloController";
import ModalController from "ModalController";

// Manual application setup
const application = Application.start();

// Manual controller registration
application.register("hello", HelloController);
application.register("modal", ModalController);

console.log("Stimulus app started");
</script>
```

**After: AssetPipeline Automation**
```crystal
# Automated Stimulus setup
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Add Stimulus framework
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# Add controllers (automatically detected by AssetPipeline)
import_map.add_import("HelloController", "/assets/hello_controller.js")
import_map.add_import("ModalController", "/assets/modal_controller.js")

# Custom initialization code (AssetPipeline removes duplicates)
stimulus_js = <<-JS
  console.log("Stimulus app started");
JS

# AssetPipeline automatically:
# 1. Imports Stimulus Application
# 2. Imports all controllers
# 3. Creates application instance
# 4. Registers all controllers with kebab-case names
puts front_loader.render_import_map_tag
puts front_loader.render_stimulus_initialization_script(stimulus_js)
```

**Generated Output:**
```html
<script type="importmap">{"imports": {"@hotwired/stimulus": "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", "HelloController": "/assets/hello_controller.js", "ModalController": "/assets/modal_controller.js"}}</script>
<link rel="modulepreload" href="https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm">

<script type="module">
import { Application } from "@hotwired/stimulus";

import HelloController from "HelloController";
import ModalController from "ModalController";

const application = Application.start();

console.log("Stimulus app started");

application.register("hello", HelloController);
application.register("modal", ModalController);
</script>
```

### 2. Rails with Importmap to AssetPipeline

**Before: Rails Importmap-Rails Gem**
```ruby
# config/importmap.rb
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "hello_controller", to: "hello_controller.js"
pin "modal_controller", to: "modal_controller.js"
pin "application", to: "application.js", preload: true

# app/javascript/application.js
import { Application } from "@hotwired/stimulus"
import HelloController from "hello_controller"
import ModalController from "modal_controller"

const application = Application.start()
application.register("hello", HelloController)
application.register("modal", ModalController)
```

**After: Crystal AssetPipeline**
```crystal
# config/asset_pipeline.cr
class AssetConfiguration
  def self.setup_stimulus
    front_loader = AssetPipeline::FrontLoader.new
    import_map = front_loader.get_import_map
    
    # Same imports as Rails importmap
    import_map.add_import("@hotwired/stimulus", "/assets/stimulus.min.js", preload: true)
    import_map.add_import("HelloController", "/assets/hello_controller.js")
    import_map.add_import("ModalController", "/assets/modal_controller.js")
    
    # No application.js needed - AssetPipeline auto-generates
    front_loader
  end
end

# In your controller/template
front_loader = AssetConfiguration.setup_stimulus
puts front_loader.render_import_map_tag
puts front_loader.render_stimulus_initialization_script
```

### 3. From Stimulus + Rails UJS to Pure Stimulus

**Before: Mixed Rails UJS + Stimulus**
```javascript
// application.js (Rails 6 style)
import Rails from "@rails/ujs"
import { Application } from "@hotwired/stimulus"
import HelloController from "hello_controller"

Rails.start()

const application = Application.start()
application.register("hello", HelloController)
```

**After: Pure Stimulus with AssetPipeline**
```crystal
# Migration to pure Stimulus approach
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Stimulus only (no Rails UJS)
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("HelloController", "hello_controller.js")

# Add any additional functionality previously handled by Rails UJS
migration_js = <<-JS
  // Custom form handling (replaces Rails UJS)
  document.addEventListener('submit', (e) => {
    if (e.target.hasAttribute('data-remote')) {
      e.preventDefault();
      // Custom AJAX form handling
    }
  });
  
  console.log('Pure Stimulus setup complete');
JS

puts front_loader.render_stimulus_initialization_script(migration_js)
```

---

## Advanced Migration Patterns

### 1. Multi-Application Migration

**Before: Separate Script Files**
```html
<!-- admin.html -->
<script src="/admin/admin.js"></script>
<script src="/admin/chart.js"></script>

<!-- main.html -->
<script src="/main/app.js"></script>
<script src="/main/ui.js"></script>
```

**After: Multiple Import Maps**
```crystal
# Unified configuration with multiple contexts
front_loader = AssetPipeline::FrontLoader.new do |import_maps|
  # Admin application
  admin_map = AssetPipeline::ImportMap.new("admin")
  admin_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  admin_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
  admin_map.add_import("AdminController", "admin_controller.js")
  import_maps << admin_map
  
  # Main application
  main_map = AssetPipeline::ImportMap.new("application")
  main_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  main_map.add_import("UserController", "user_controller.js")
  import_maps << main_map
end

# Render for admin pages
def render_admin_page
  puts front_loader.render_import_map_tag("admin")
  puts front_loader.render_stimulus_initialization_script("console.log('Admin ready');", "admin")
end

# Render for main pages
def render_main_page
  puts front_loader.render_import_map_tag("application")
  puts front_loader.render_stimulus_initialization_script("console.log('App ready');", "application")
end
```

### 2. Progressive Enhancement Migration

**Before: jQuery + Custom Plugins**
```html
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="/plugins/modal.js"></script>
<script src="/plugins/tooltip.js"></script>
<script>
  $(document).ready(() => {
    $('.modal-trigger').modal();
    $('[data-tooltip]').tooltip();
  });
</script>
```

**After: Stimulus Controllers + Libraries**
```crystal
# Progressive migration to Stimulus pattern
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Keep existing jQuery during transition
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js", preload: true)

# Add Stimulus framework
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# New Stimulus controllers (replace plugins gradually)
import_map.add_import("ModalController", "modal_controller.js")
import_map.add_import("TooltipController", "tooltip_controller.js")

# Transition period: both approaches working
transition_js = <<-JS
  // Legacy jQuery initialization (gradually remove)
  $(document).ready(() => {
    // Keep old functionality for elements without Stimulus
    $('.modal-trigger:not([data-controller])').modal();
    $('[data-tooltip]:not([data-controller])').tooltip();
  });
  
  console.log('Progressive enhancement active');
JS

puts front_loader.render_stimulus_initialization_script(transition_js)
```

### 3. Microservice to Monolith Migration

**Before: Multiple Small Apps**
```javascript
// users-app/index.js
import UserController from './user_controller.js';

// products-app/index.js  
import ProductController from './product_controller.js';

// orders-app/index.js
import OrderController from './order_controller.js';
```

**After: Unified AssetPipeline**
```crystal
# Unified application with all controllers
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Unified Stimulus setup
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)

# All controllers in one import map
import_map.add_import("UserController", "controllers/user_controller.js")
import_map.add_import("ProductController", "controllers/product_controller.js")
import_map.add_import("OrderController", "controllers/order_controller.js")

# Shared utilities
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")

# Unified initialization
unified_js = <<-JS
  // Global utilities available to all controllers
  window.formatDate = (date) => dayjs(date).format('YYYY-MM-DD');
  window.debounce = debounce;
  
  console.log('Unified application ready');
JS

puts front_loader.render_stimulus_initialization_script(unified_js)
```

---

## Step-by-Step Migrations

### Migration Checklist

#### Phase 1: Setup and Planning
- [ ] **Audit Current Setup**: Document all existing script tags, import maps, and dependencies
- [ ] **Identify Dependencies**: List all external libraries (jQuery, Lodash, Chart.js, etc.)
- [ ] **Map Controllers**: Identify all Stimulus controllers (if applicable)
- [ ] **Plan Import Maps**: Decide on import map structure (single vs. multiple)
- [ ] **Setup AssetPipeline**: Initialize AssetPipeline in your application

#### Phase 2: Basic Migration
- [ ] **Create FrontLoader**: Set up AssetPipeline::FrontLoader with initial configuration
- [ ] **Add Core Libraries**: Migrate essential libraries (jQuery, Stimulus, utilities)
- [ ] **Convert Custom Scripts**: Move inline JavaScript to AssetPipeline rendering
- [ ] **Test Basic Functionality**: Verify core features work correctly
- [ ] **Remove Old Script Tags**: Clean up manual script includes

#### Phase 3: Stimulus Integration
- [ ] **Add Stimulus Framework**: Include @hotwired/stimulus in import map
- [ ] **Register Controllers**: Add all controller imports
- [ ] **Convert Manual Registrations**: Remove manual `application.register()` calls
- [ ] **Test Controller Functionality**: Verify all controllers work correctly
- [ ] **Clean Up Duplicates**: Remove redundant imports and registrations

#### Phase 4: Advanced Features
- [ ] **Enable Dependency Analysis**: Use `render_initialization_script_with_analysis`
- [ ] **Add Missing Imports**: Address dependency warnings
- [ ] **Optimize Preloading**: Add `preload: true` for critical dependencies
- [ ] **Performance Testing**: Benchmark before/after performance
- [ ] **Monitor Production**: Watch for any issues in production

### Detailed Step Example

**Step 1: Audit Current Setup**
```html
<!-- Before: Document current state -->
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm" type="module"></script>
<script src="/assets/hello_controller.js" type="module"></script>
<script type="module">
  import { Application } from "@hotwired/stimulus";
  import HelloController from "/assets/hello_controller.js";
  
  const application = Application.start();
  application.register("hello", HelloController);
  
  $(document).ready(() => {
    console.log('App ready');
  });
</script>
```

**Step 2: Setup AssetPipeline**
```crystal
# Create initial AssetPipeline setup
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Add discovered dependencies
import_map.add_import("jquery", "https://code.jquery.com/jquery-3.7.1.min.js", preload: true)
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("HelloController", "/assets/hello_controller.js")

# Move custom JavaScript
app_js = <<-JS
  $(document).ready(() => {
    console.log('App ready');
  });
JS

# Generate AssetPipeline output
puts front_loader.render_import_map_tag
puts front_loader.render_stimulus_initialization_script(app_js)
```

**Step 3: Test and Validate**
```crystal
# Add dependency analysis to catch issues
puts front_loader.render_initialization_script_with_analysis(app_js)
# Check for any warning comments about missing dependencies
```

**Step 4: Clean Up and Optimize**
```crystal
# Final optimized version
front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Optimized imports with preloading
import_map.add_import("jquery", "https://code.jquery.com/jquery-3.7.1.min.js", preload: true)
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("HelloController", "/assets/hello_controller.js")

# Clean, simple custom code
final_js = <<-JS
  $(document).ready(() => {
    console.log('Migration complete!');
  });
JS

# Production-ready output
puts front_loader.render_import_map_tag
puts front_loader.render_stimulus_initialization_script(final_js)
```

---

## Common Migration Challenges

### Challenge 1: Missing Dependencies
**Problem**: Script works manually but fails with AssetPipeline
**Solution**: Use dependency analysis

```crystal
# Identify missing dependencies
problematic_js = <<-JS
  $('.modal').modal();           // Missing jQuery
  moment().format('YYYY-MM-DD'); // Missing moment.js
JS

result = front_loader.render_initialization_script_with_analysis(problematic_js)
# Look for WARNING comments about missing imports
```

### Challenge 2: Import Order Dependencies
**Problem**: Scripts depend on specific loading order
**Solution**: Use preloading and proper sequencing

```crystal
# Ensure critical dependencies load first
import_map.add_import("jquery", "https://code.jquery.com/jquery-3.7.1.min.js", preload: true)
import_map.add_import("jquery-ui", "https://code.jquery.com/ui/1.13.2/jquery-ui.min.js") # Depends on jQuery

# Initialization code runs after all imports
initialization_js = <<-JS
  // jQuery and jQuery UI are guaranteed to be available here
  $('.sortable').sortable();
JS
```

### Challenge 3: Global Variable Conflicts
**Problem**: Different modules defining same global variables
**Solution**: Use import maps to namespace properly

```crystal
# Before: Conflicting globals
# <script>var Utils = {...}</script>
# <script>var Utils = {...}</script> // Conflict!

# After: Proper module imports
import_map.add_import("AppUtils", "app_utils.js")
import_map.add_import("AdminUtils", "admin_utils.js")

namespaced_js = <<-JS
  // No more global conflicts
  import AppUtils from "AppUtils";
  import AdminUtils from "AdminUtils";
  
  AppUtils.formatDate();
  AdminUtils.exportData();
JS
```

### Challenge 4: Controller Name Mismatches
**Problem**: Stimulus controllers not auto-detected
**Solution**: Ensure proper naming conventions

```crystal
# ❌ Won't be detected
import_map.add_import("hello", "hello_controller.js")
import_map.add_import("user-profile", "user_profile_controller.js")

# ✅ Will be auto-detected and registered
import_map.add_import("HelloController", "hello_controller.js")
import_map.add_import("UserProfileController", "user_profile_controller.js")
# Automatically registers as "hello" and "user-profile"
```

---

## Testing Your Migration

### Functionality Testing
```crystal
# Test that all features work correctly
def test_migration
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Add your imports
  import_map.add_import("jquery", "https://code.jquery.com/jquery-3.7.1.min.js")
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm")
  import_map.add_import("HelloController", "hello_controller.js")
  
  test_js = <<-JS
    // Test jQuery
    if (typeof $ === 'undefined') {
      console.error('jQuery not loaded!');
    } else {
      console.log('✅ jQuery loaded');
    }
    
    // Test Stimulus
    document.addEventListener('stimulus:ready', () => {
      console.log('✅ Stimulus loaded');
    });
    
    // Test controller
    if (document.querySelector('[data-controller="hello"]')) {
      console.log('✅ HelloController connected');
    }
  JS
  
  puts front_loader.render_stimulus_initialization_script(test_js)
end
```

### Performance Testing
```crystal
# Compare before/after load times
def benchmark_migration
  start_time = Time.utc
  
  # Your AssetPipeline setup
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Add typical dependencies
  import_map.add_import("jquery", "https://code.jquery.com/jquery-3.7.1.min.js", preload: true)
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  
  result = front_loader.render_stimulus_initialization_script("console.log('ready');")
  
  end_time = Time.utc
  puts "Generation time: #{(end_time - start_time).total_milliseconds}ms"
  puts "Output size: #{result.bytesize} bytes"
end
```

### Regression Testing
```crystal
# Ensure migration doesn't break existing functionality
def regression_test
  # Test all critical user journeys
  test_cases = [
    "User login flow",
    "Form submissions", 
    "Modal interactions",
    "AJAX requests",
    "Controller interactions"
  ]
  
  test_cases.each do |test_case|
    puts "Testing: #{test_case}"
    # Implement your specific tests here
  end
end
```

---

This migration guide provides comprehensive steps for moving to AssetPipeline. For specific technical details, see the [API Reference](API_REFERENCE.md) and [Usage Examples](USAGE_EXAMPLES.md). 