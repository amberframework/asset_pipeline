require "../src/asset_pipeline"

# Phase 5: Mixed Scenarios with General JavaScript and Stimulus Examples
# This example demonstrates real-world scenarios where applications use both
# general JavaScript libraries AND Stimulus controllers together

puts "=== Phase 5: Mixed Scenarios with General JavaScript and Stimulus Examples ==="
puts

# Scenario 1: E-commerce application with Stimulus controllers and utility libraries
puts "Scenario 1: E-commerce Application"
puts "  - Stimulus controllers for UI interactions"
puts "  - Lodash for data manipulation"
puts "  - Day.js for date formatting"
puts "  - Chart.js for analytics dashboard"
puts

front_loader = AssetPipeline::FrontLoader.new
import_map = front_loader.get_import_map

# Add the essential libraries
import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm", preload: true)
import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")
import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm")

# Add some Stimulus controllers
import_map.add_import("CartController", "cart_controller.js")
import_map.add_import("SearchController", "search_controller.js")

ecommerce_js = <<-JS
  // E-commerce application initialization
  import { debounce, throttle } from "lodash"
  import dayjs from "dayjs"
  import { Chart, registerables } from "chart.js"
  
  import CartController from "cart_controller.js"
  import SearchController from "search_controller.js"
  import CheckoutController from "checkout_controller.js"
  
  // Register Chart.js components
  Chart.register(...registerables)
  
  // Utility functions using lodash
  const debouncedSearch = debounce((query) => {
    console.log("Searching products for:", query)
    // Search API call would go here
  }, 300)
  
  const throttledScroll = throttle(() => {
    console.log("Lazy loading more products...")
    // Infinite scroll logic
  }, 1000)
  
  // Date formatting utilities
  const formatOrderDate = (date) => {
    return dayjs(date).format("MMM DD, YYYY")
  }
  
  // Initialize analytics chart
  const initAnalyticsChart = (canvasId, data) => {
    const ctx = document.getElementById(canvasId).getContext('2d')
    return new Chart(ctx, {
      type: 'line',
      data: data,
      options: {
        responsive: true,
        plugins: {
          title: {
            display: true,
            text: 'Sales Analytics'
          }
        }
      }
    })
  }
  
  // Register Stimulus controllers
  application.register("cart", CartController)
  application.register("search", SearchController)
  application.register("checkout", CheckoutController)
  
  // Start Stimulus application
  application.start()
  
  // Global app initialization
  document.addEventListener("DOMContentLoaded", () => {
    console.log("E-commerce app initialized at:", formatOrderDate(new Date()))
    
    // Setup global event listeners
    window.addEventListener("scroll", throttledScroll)
    
    // Initialize charts if present
    const salesChart = document.getElementById("sales-chart")
    if (salesChart) {
      initAnalyticsChart("sales-chart", {
        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
        datasets: [{
          label: 'Sales',
          data: [12, 19, 3, 5, 2],
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        }]
      })
    }
  })
JS

puts "E-commerce JavaScript code:"
puts ecommerce_js[0..300] + "..." # Show first part
puts

result_ecommerce = front_loader.render_initialization_script(ecommerce_js)
puts "Generated e-commerce script (general approach):"
puts result_ecommerce[0..500] + "..." # Show first part
puts

result_stimulus_ecommerce = front_loader.render_stimulus_initialization_script(ecommerce_js)
puts "Generated e-commerce script (Stimulus-optimized approach):"
puts result_stimulus_ecommerce[0..500] + "..." # Show first part
puts

# Scenario 2: Real-time dashboard with Stimulus and WebSocket libraries
puts "Scenario 2: Real-time Dashboard Application"
puts "  - Stimulus controllers for widget interactions"
puts "  - Socket.io for real-time updates" 
puts "  - Moment.js for time formatting"
puts "  - D3.js for data visualizations"
puts

dashboard_import_map = front_loader.get_import_map
dashboard_import_map.add_import("socket.io-client", "https://cdn.jsdelivr.net/npm/socket.io-client@4.7.2/+esm")
dashboard_import_map.add_import("moment", "https://cdn.jsdelivr.net/npm/moment@2.29.4/+esm")
dashboard_import_map.add_import("d3", "https://cdn.jsdelivr.net/npm/d3@7.8.5/+esm")

dashboard_js = <<-JS
  // Real-time dashboard
  import { io } from "socket.io-client"
  import moment from "moment"
  import * as d3 from "d3"
  
  import DashboardController from "dashboard_controller.js"
  import WidgetController from "widget_controller.js"
  import NotificationController from "notification_controller.js"
  
  // Setup WebSocket connection
  const socket = io("/dashboard")
  
  // Real-time data handlers
  socket.on("metrics_update", (data) => {
    console.log("Received metrics at:", moment().format("HH:mm:ss"))
    updateDashboardMetrics(data)
  })
  
  socket.on("alert", (alert) => {
    console.log("Alert received:", alert.message)
    showNotification(alert)
  })
  
  // D3.js visualization functions
  const createMetricsChart = (containerId, data) => {
    const svg = d3.select(`#${containerId}`)
      .append("svg")
      .attr("width", 400)
      .attr("height", 200)
    
    // Create visualization with D3
    const circles = svg.selectAll("circle")
      .data(data)
      .enter()
      .append("circle")
      .attr("cx", (d, i) => i * 50 + 25)
      .attr("cy", 100)
      .attr("r", d => d.value * 2)
      .attr("fill", "steelblue")
      
    return circles
  }
  
  // Utility functions
  const updateDashboardMetrics = (metrics) => {
    metrics.forEach(metric => {
      const element = document.querySelector(`[data-metric="${metric.key}"]`)
      if (element) {
        element.textContent = metric.value
        element.setAttribute("data-updated", moment().toISOString())
      }
    })
  }
  
  const showNotification = (alert) => {
    const notification = document.querySelector('[data-controller="notification"]')
    if (notification) {
      // Stimulus will handle the display logic
      notification.setAttribute("data-notification-message-value", alert.message)
      notification.setAttribute("data-notification-type-value", alert.type)
    }
  }
  
  // Register Stimulus controllers for interactive elements
  application.register("dashboard", DashboardController)
  application.register("widget", WidgetController) 
  application.register("notification", NotificationController)
  
  application.start()
  
  // Initialize dashboard
  document.addEventListener("DOMContentLoaded", () => {
    console.log("Dashboard initialized at:", moment().format())
    
    // Create initial visualizations
    const metricsData = [
      { key: "users", value: 42 },
      { key: "revenue", value: 18 },
      { key: "growth", value: 25 }
    ]
    
    createMetricsChart("metrics-container", metricsData)
    
    // Start real-time updates
    socket.emit("subscribe_to_metrics")
  })
JS

puts "Dashboard JavaScript code:"
puts dashboard_js[0..300] + "..." # Show first part
puts

result_dashboard = front_loader.render_stimulus_initialization_script(dashboard_js)
puts "Generated dashboard script with mixed libraries:"
puts result_dashboard[0..500] + "..." # Show first part
puts

# Scenario 3: Content Management System with form handling and rich text
puts "Scenario 3: Content Management System"
puts "  - Stimulus controllers for form interactions"
puts "  - TinyMCE for rich text editing"
puts "  - Alpine.js for simple reactivity"
puts "  - Axios for API calls"
puts

cms_import_map = front_loader.get_import_map
cms_import_map.add_import("tinymce", "https://cdn.jsdelivr.net/npm/tinymce@6.7.2/+esm")
cms_import_map.add_import("alpinejs", "https://cdn.jsdelivr.net/npm/alpinejs@3.13.1/dist/module.esm.js", preload: true)
cms_import_map.add_import("axios", "https://cdn.jsdelivr.net/npm/axios@1.5.0/+esm")

cms_js = <<-JS
  // Content Management System
  import { tinymce } from "tinymce"
  import Alpine from "alpinejs"
  import axios from "axios"
  
  import FormController from "form_controller.js"
  import MediaLibraryController from "media_library_controller.js"
  import PreviewController from "preview_controller.js"
  
  // Configure Alpine.js data
  Alpine.data('contentEditor', () => ({
    saving: false,
    saved: false,
    wordCount: 0,
    
    async saveContent() {
      this.saving = true
      try {
        const content = tinymce.activeEditor.getContent()
        await axios.post('/api/content', { content })
        this.saved = true
        setTimeout(() => this.saved = false, 3000)
      } catch (error) {
        console.error('Save failed:', error)
      } finally {
        this.saving = false
      }
    },
    
    updateWordCount(content) {
      this.wordCount = content.split(' ').length
    }
  }))
  
  // Initialize TinyMCE
  const initRichTextEditor = () => {
    tinymce.init({
      selector: 'textarea[data-rich-text]',
      plugins: 'link image code',
      toolbar: 'undo redo | bold italic | link image | code',
      setup: (editor) => {
        editor.on('keyup', () => {
          const content = editor.getContent()
          Alpine.store('editor').updateWordCount(content)
        })
      }
    })
  }
  
  // API helper functions
  const apiClient = axios.create({
    baseURL: '/api',
    headers: {
      'X-Requested-With': 'XMLHttpRequest'
    }
  })
  
  // Add CSRF token to requests
  apiClient.interceptors.request.use(config => {
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (token) {
      config.headers['X-CSRF-Token'] = token
    }
    return config
  })
  
  // Register Stimulus controllers
  application.register("form", FormController)
  application.register("media-library", MediaLibraryController) 
  application.register("preview", PreviewController)
  
  application.start()
  
  // Start Alpine.js (for simple reactivity)
  Alpine.start()
  
  // Initialize CMS
  document.addEventListener("DOMContentLoaded", () => {
    console.log("CMS initialized")
    
    // Initialize rich text editors
    initRichTextEditor()
    
    // Setup auto-save functionality
    setInterval(() => {
      const autosaveEnabled = document.querySelector('[data-autosave="true"]')
      if (autosaveEnabled && tinymce.activeEditor) {
        console.log("Auto-saving content...")
        Alpine.store('editor').saveContent()
      }
    }, 30000) // Auto-save every 30 seconds
  })
JS

puts "CMS JavaScript code:"
puts cms_js[0..300] + "..." # Show first part
puts

result_cms = front_loader.render_initialization_script_with_analysis(cms_js)
puts "Generated CMS script with dependency analysis:"
puts result_cms[0..500] + "..." # Show first part
puts

puts "=== Summary: Mixed Scenarios demonstrate how the AssetPipeline handles:"
puts "1. 🎯 Stimulus controllers alongside utility libraries (lodash, dayjs, chart.js)"
puts "2. 🔄 Real-time features with WebSocket libraries and data visualization"
puts "3. 📝 Rich content editing with multiple frontend frameworks"
puts "4. 🚀 Automatic dependency detection across all scenarios"
puts "5. ⚡ Framework-agnostic rendering that works with any combination"
puts
puts "All scenarios completed successfully! 🎉" 