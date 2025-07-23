require "../src/asset_pipeline"

# =============================================================================
# Phase 6.2.2: Complex Multi-Controller Application Examples
# =============================================================================
#
# This file demonstrates complex, real-world setups with multiple controllers
# Shows controller communication, shared state, complex workflows, and advanced patterns

puts "=== Phase 6.2.2: Complex Multi-Controller Application Examples ==="
puts

# Example 1: E-commerce Application with Multiple Controllers
# ----------------------------------------------------------------------------
puts "📝 Example 1: E-commerce Application - Cart, Product, Search Controllers"

def example_1_ecommerce_app
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Framework and external libraries
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm", preload: true)
  import_map.add_import("axios", "https://cdn.jsdelivr.net/npm/axios@1.6.0/+esm")
  
  # E-commerce controllers
  import_map.add_import("ProductController", "controllers/product_controller.js")
  import_map.add_import("CartController", "controllers/cart_controller.js")
  import_map.add_import("SearchController", "controllers/search_controller.js")
  import_map.add_import("CheckoutController", "controllers/checkout_controller.js")
  import_map.add_import("NotificationController", "controllers/notification_controller.js")
  
  # Complex e-commerce initialization
  ecommerce_js = <<-JS
    // Global e-commerce state management
    window.EcommerceApp = {
      cart: {
        items: [],
        total: 0,
        currency: 'USD'
      },
      user: {
        isLoggedIn: false,
        preferences: {}
      },
      notifications: []
    };
    
    // Inter-controller communication via custom events
    window.dispatchCartUpdate = function(cartData) {
      document.dispatchEvent(new CustomEvent('cart:updated', {
        detail: cartData
      }));
    };
    
    window.dispatchProductView = function(productId) {
      document.dispatchEvent(new CustomEvent('product:viewed', {
        detail: { productId, timestamp: Date.now() }
      }));
    };
    
    window.dispatchNotification = function(message, type = 'info') {
      document.dispatchEvent(new CustomEvent('notification:show', {
        detail: { message, type, id: Date.now() }
      }));
    };
    
    // Shared utilities for all controllers
    window.formatPrice = function(price, currency = 'USD') {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: currency
      }).format(price);
    };
    
    window.debounceSearch = debounce(function(query, callback) {
      if (query.length < 2) {
        callback([]);
        return;
      }
      
      // Simulate API search
      axios.get(`/api/search?q=${encodeURIComponent(query)}`)
        .then(response => callback(response.data))
        .catch(error => {
          console.error('Search error:', error);
          callback([]);
        });
    }, 300);
    
    // Analytics tracking
    window.trackEvent = function(category, action, label, value) {
      console.log(`Analytics: ${category} - ${action}`, { label, value });
      // In production: send to analytics service
    };
    
    // Global error handler for AJAX requests
    axios.interceptors.response.use(
      response => response,
      error => {
        dispatchNotification('Network error occurred', 'error');
        return Promise.reject(error);
      }
    );
    
    console.log('E-commerce application with 5 controllers ready');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(ecommerce_js)
  }
end

result = example_1_ecommerce_app
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- 5 interconnected controllers (Product, Cart, Search, Checkout, Notification)"
puts "- Global state management"
puts "- Inter-controller communication via custom events"
puts "- Shared utility functions"
puts "- API integration with error handling"
puts "- Analytics tracking setup"
puts "=" * 80
puts

# Example 2: Dashboard Application with Real-time Updates
# ----------------------------------------------------------------------------
puts "📝 Example 2: Dashboard Application - Charts, Data Tables, Real-time Updates"

def example_2_dashboard_app
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Framework and visualization libraries
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("chart.js", "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/+esm", preload: true)
  import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
  import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")
  
  # Dashboard controllers
  import_map.add_import("DashboardController", "controllers/dashboard_controller.js")
  import_map.add_import("ChartController", "controllers/chart_controller.js")
  import_map.add_import("DataTableController", "controllers/data_table_controller.js")
  import_map.add_import("WebsocketController", "controllers/websocket_controller.js")
  import_map.add_import("FilterController", "controllers/filter_controller.js")
  import_map.add_import("ExportController", "controllers/export_controller.js")
  
  # Complex dashboard initialization
  dashboard_js = <<-JS
    // Global dashboard state
    window.DashboardApp = {
      data: {
        metrics: {},
        charts: new Map(),
        tables: new Map(),
        filters: {}
      },
      websocket: null,
      updateIntervals: new Map()
    };
    
    // Real-time data management
    window.initializeWebsocket = function() {
      if (DashboardApp.websocket) return;
      
      // Mock WebSocket for demonstration
      DashboardApp.websocket = {
        send: (data) => console.log('WebSocket send:', data),
        close: () => console.log('WebSocket closed'),
        readyState: 1 // OPEN
      };
      
      // Simulate real-time updates
      setInterval(() => {
        const mockData = {
          timestamp: Date.now(),
          metrics: {
            activeUsers: Math.floor(Math.random() * 1000) + 500,
            revenue: Math.floor(Math.random() * 10000) + 5000,
            conversions: Math.floor(Math.random() * 100) + 50
          }
        };
        
        document.dispatchEvent(new CustomEvent('dashboard:data-update', {
          detail: mockData
        }));
      }, 5000);
    };
    
    // Chart management utilities
    window.updateChart = function(chartId, newData) {
      const chart = DashboardApp.data.charts.get(chartId);
      if (chart) {
        chart.data = newData;
        chart.update('none'); // No animation for real-time updates
      }
    };
    
    window.createRealtimeChart = function(ctx, config) {
      const chart = new Chart(ctx, {
        ...config,
        options: {
          ...config.options,
          responsive: true,
          maintainAspectRatio: false,
          interaction: {
            intersect: false,
          },
          scales: {
            x: {
              type: 'time',
              time: {
                unit: 'minute'
              }
            }
          }
        }
      });
      
      DashboardApp.data.charts.set(ctx.canvas.id, chart);
      return chart;
    };
    
    // Data processing utilities
    window.processMetricsData = function(rawData) {
      return {
        processed: true,
        timestamp: dayjs().format('YYYY-MM-DD HH:mm:ss'),
        ...rawData,
        trends: calculateTrends(rawData)
      };
    };
    
    window.calculateTrends = function(data) {
      // Mock trend calculation
      return {
        activeUsers: { direction: 'up', percentage: 5.2 },
        revenue: { direction: 'up', percentage: 12.1 },
        conversions: { direction: 'down', percentage: -2.3 }
      };
    };
    
    // Export functionality
    window.exportToPDF = function(elementId) {
      console.log(`Exporting ${elementId} to PDF`);
      // In production: use jsPDF or similar
    };
    
    window.exportToCSV = function(tableData, filename) {
      const csv = convertToCSV(tableData);
      downloadFile(csv, filename, 'text/csv');
    };
    
    window.convertToCSV = function(data) {
      const headers = Object.keys(data[0]).join(',');
      const rows = data.map(row => Object.values(row).join(',')).join('\\n');
      return headers + '\\n' + rows;
    };
    
    window.downloadFile = function(content, filename, mimeType) {
      const blob = new Blob([content], { type: mimeType });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.click();
      URL.revokeObjectURL(url);
    };
    
    // Performance monitoring for complex dashboards
    window.performanceMonitor = {
      start: (label) => performance.mark(`${label}-start`),
      end: (label) => {
        performance.mark(`${label}-end`);
        performance.measure(label, `${label}-start`, `${label}-end`);
        const measure = performance.getEntriesByName(label)[0];
        console.log(`Performance ${label}: ${measure.duration.toFixed(2)}ms`);
      }
    };
    
    console.log('Dashboard application with 6 controllers ready');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(dashboard_js)
  }
end

result = example_2_dashboard_app
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- 6 specialized controllers for dashboard functionality"
puts "- Real-time data updates via WebSocket simulation"
puts "- Chart.js integration with real-time updates"
puts "- Data processing and trend calculation"
puts "- Export functionality (PDF, CSV)"
puts "- Performance monitoring for complex operations"
puts "=" * 80
puts

# Example 3: Social Media Application with Complex Interactions
# ----------------------------------------------------------------------------
puts "📝 Example 3: Social Media App - Posts, Comments, Likes, Notifications"

def example_3_social_media_app
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Framework and utilities
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
  import_map.add_import("axios", "https://cdn.jsdelivr.net/npm/axios@1.6.0/+esm")
  import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")
  
  # Social media controllers
  import_map.add_import("PostController", "controllers/post_controller.js")
  import_map.add_import("CommentController", "controllers/comment_controller.js")
  import_map.add_import("LikeController", "controllers/like_controller.js")
  import_map.add_import("FollowController", "controllers/follow_controller.js")
  import_map.add_import("NotificationController", "controllers/notification_controller.js")
  import_map.add_import("ChatController", "controllers/chat_controller.js")
  import_map.add_import("MediaUploadController", "controllers/media_upload_controller.js")
  
  # Complex social media initialization
  social_js = <<-JS
    // Global social media state
    window.SocialApp = {
      user: {
        id: null,
        username: '',
        followers: 0,
        following: 0
      },
      posts: new Map(),
      comments: new Map(),
      likes: new Set(),
      notifications: [],
      activeChats: new Map()
    };
    
    // Real-time notification system
    window.NotificationSystem = {
      queue: [],
      
      add(notification) {
        const id = Date.now();
        const notif = { id, ...notification, timestamp: dayjs().format('HH:mm') };
        
        this.queue.push(notif);
        SocialApp.notifications.unshift(notif);
        
        document.dispatchEvent(new CustomEvent('notification:new', {
          detail: notif
        }));
        
        // Auto-remove after 5 seconds
        setTimeout(() => this.remove(id), 5000);
      },
      
      remove(id) {
        this.queue = this.queue.filter(n => n.id !== id);
        document.dispatchEvent(new CustomEvent('notification:remove', {
          detail: { id }
        }));
      }
    };
    
    // Post interaction management
    window.PostInteractions = {
      like(postId, userId) {
        const key = `${postId}-${userId}`;
        
        if (SocialApp.likes.has(key)) {
          SocialApp.likes.delete(key);
          this.updateLikeCount(postId, -1);
        } else {
          SocialApp.likes.add(key);
          this.updateLikeCount(postId, 1);
          
          NotificationSystem.add({
            type: 'like',
            message: 'Someone liked your post!',
            postId: postId
          });
        }
        
        document.dispatchEvent(new CustomEvent('post:like-toggled', {
          detail: { postId, userId, isLiked: SocialApp.likes.has(key) }
        }));
      },
      
      updateLikeCount(postId, delta) {
        const post = SocialApp.posts.get(postId);
        if (post) {
          post.likes = Math.max(0, post.likes + delta);
          document.dispatchEvent(new CustomEvent('post:likes-updated', {
            detail: { postId, likes: post.likes }
          }));
        }
      },
      
      addComment(postId, comment) {
        const commentId = Date.now();
        const commentData = {
          id: commentId,
          postId,
          text: comment,
          author: SocialApp.user.username,
          timestamp: dayjs().format('YYYY-MM-DD HH:mm')
        };
        
        SocialApp.comments.set(commentId, commentData);
        
        document.dispatchEvent(new CustomEvent('comment:added', {
          detail: commentData
        }));
        
        NotificationSystem.add({
          type: 'comment',
          message: 'New comment on your post!',
          postId: postId
        });
      }
    };
    
    // Chat system
    window.ChatSystem = {
      activeChats: new Map(),
      
      openChat(userId, username) {
        if (this.activeChats.has(userId)) {
          this.focusChat(userId);
          return;
        }
        
        const chatData = {
          userId,
          username,
          messages: [],
          isTyping: false
        };
        
        this.activeChats.set(userId, chatData);
        SocialApp.activeChats.set(userId, chatData);
        
        document.dispatchEvent(new CustomEvent('chat:opened', {
          detail: chatData
        }));
      },
      
      sendMessage(userId, message) {
        const chat = this.activeChats.get(userId);
        if (!chat) return;
        
        const messageData = {
          id: Date.now(),
          text: message,
          sender: SocialApp.user.username,
          timestamp: dayjs().format('HH:mm'),
          isSent: true
        };
        
        chat.messages.push(messageData);
        
        document.dispatchEvent(new CustomEvent('chat:message-sent', {
          detail: { userId, message: messageData }
        }));
      },
      
      closeChat(userId) {
        this.activeChats.delete(userId);
        SocialApp.activeChats.delete(userId);
        
        document.dispatchEvent(new CustomEvent('chat:closed', {
          detail: { userId }
        }));
      }
    };
    
    // Media upload utilities
    window.MediaUpload = {
      validateFile(file) {
        const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
        const maxSize = 5 * 1024 * 1024; // 5MB
        
        if (!allowedTypes.includes(file.type)) {
          NotificationSystem.add({
            type: 'error',
            message: 'Please upload a valid image file (JPEG, PNG, GIF)'
          });
          return false;
        }
        
        if (file.size > maxSize) {
          NotificationSystem.add({
            type: 'error',
            message: 'File size must be less than 5MB'
          });
          return false;
        }
        
        return true;
      },
      
      uploadFile(file, progressCallback) {
        return new Promise((resolve, reject) => {
          // Simulate file upload with progress
          let progress = 0;
          const interval = setInterval(() => {
            progress += Math.random() * 20;
            if (progress >= 100) {
              progress = 100;
              clearInterval(interval);
              resolve({
                url: URL.createObjectURL(file),
                id: Date.now(),
                filename: file.name
              });
            }
            progressCallback(progress);
          }, 200);
        });
      }
    };
    
    // Infinite scroll management
    window.InfiniteScroll = {
      isLoading: false,
      hasMore: true,
      currentPage: 1,
      
      loadMore() {
        if (this.isLoading || !this.hasMore) return;
        
        this.isLoading = true;
        this.currentPage++;
        
        // Simulate API call
        setTimeout(() => {
          const mockPosts = this.generateMockPosts(10);
          
          document.dispatchEvent(new CustomEvent('posts:loaded', {
            detail: { posts: mockPosts, page: this.currentPage }
          }));
          
          this.isLoading = false;
          
          // Stop loading after 5 pages for demo
          if (this.currentPage >= 5) {
            this.hasMore = false;
          }
        }, 1000);
      },
      
      generateMockPosts(count) {
        return Array.from({ length: count }, (_, i) => ({
          id: Date.now() + i,
          author: `User${Math.floor(Math.random() * 100)}`,
          text: `This is mock post content #${this.currentPage}-${i}`,
          likes: Math.floor(Math.random() * 100),
          comments: Math.floor(Math.random() * 20),
          timestamp: dayjs().subtract(Math.floor(Math.random() * 60), 'minutes').format('YYYY-MM-DD HH:mm')
        }));
      }
    };
    
    console.log('Social media application with 7 controllers ready');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(social_js)
  }
end

result = example_3_social_media_app
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- 7 interconnected controllers for social features"
puts "- Complex state management for posts, comments, likes"
puts "- Real-time notification system"
puts "- Chat system with multiple active conversations"
puts "- Media upload with validation and progress tracking"
puts "- Infinite scroll implementation"
puts "=" * 80
puts

# Example 4: Project Management Application
# ----------------------------------------------------------------------------
puts "📝 Example 4: Project Management App - Tasks, Teams, Calendar, Time Tracking"

def example_4_project_management_app
  front_loader = AssetPipeline::FrontLoader.new
  import_map = front_loader.get_import_map
  
  # Framework and specialized libraries
  import_map.add_import("@hotwired/stimulus", "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm", preload: true)
  import_map.add_import("sortablejs", "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/+esm")
  import_map.add_import("dayjs", "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/+esm")
  import_map.add_import("lodash", "https://cdn.jsdelivr.net/npm/lodash@4.17.21/+esm")
  
  # Project management controllers
  import_map.add_import("ProjectController", "controllers/project_controller.js")
  import_map.add_import("TaskController", "controllers/task_controller.js")
  import_map.add_import("KanbanController", "controllers/kanban_controller.js")
  import_map.add_import("CalendarController", "controllers/calendar_controller.js")
  import_map.add_import("TimeTrackerController", "controllers/time_tracker_controller.js")
  import_map.add_import("TeamController", "controllers/team_controller.js")
  import_map.add_import("GanttController", "controllers/gantt_controller.js")
  
  # Complex project management initialization
  project_js = <<-JS
    // Global project management state
    window.ProjectApp = {
      currentProject: null,
      projects: new Map(),
      tasks: new Map(),
      teams: new Map(),
      timeEntries: [],
      activeTimers: new Map()
    };
    
    // Task management system
    window.TaskManager = {
      statuses: ['todo', 'in-progress', 'review', 'done'],
      priorities: ['low', 'medium', 'high', 'urgent'],
      
      createTask(taskData) {
        const task = {
          id: Date.now(),
          ...taskData,
          createdAt: dayjs().toISOString(),
          updatedAt: dayjs().toISOString()
        };
        
        ProjectApp.tasks.set(task.id, task);
        
        document.dispatchEvent(new CustomEvent('task:created', {
          detail: task
        }));
        
        return task;
      },
      
      updateTask(taskId, updates) {
        const task = ProjectApp.tasks.get(taskId);
        if (!task) return null;
        
        Object.assign(task, updates, {
          updatedAt: dayjs().toISOString()
        });
        
        document.dispatchEvent(new CustomEvent('task:updated', {
          detail: { taskId, updates, task }
        }));
        
        return task;
      },
      
      moveTask(taskId, newStatus, newPosition) {
        const task = this.updateTask(taskId, { 
          status: newStatus,
          position: newPosition 
        });
        
        if (task) {
          document.dispatchEvent(new CustomEvent('task:moved', {
            detail: { task, newStatus, newPosition }
          }));
        }
      },
      
      assignTask(taskId, userId) {
        const task = this.updateTask(taskId, { assignedTo: userId });
        
        if (task) {
          document.dispatchEvent(new CustomEvent('task:assigned', {
            detail: { task, userId }
          }));
        }
      }
    };
    
    // Kanban board management
    window.KanbanManager = {
      initializeSortable(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;
        
        return Sortable.create(container, {
          group: 'kanban',
          animation: 150,
          ghostClass: 'sortable-ghost',
          chosenClass: 'sortable-chosen',
          dragClass: 'sortable-drag',
          
          onEnd: (evt) => {
            const taskId = evt.item.dataset.taskId;
            const newStatus = evt.to.dataset.status;
            const newPosition = evt.newIndex;
            
            TaskManager.moveTask(taskId, newStatus, newPosition);
          }
        });
      },
      
      updateColumnCounts() {
        this.statuses.forEach(status => {
          const column = document.querySelector(`[data-status="${status}"]`);
          if (column) {
            const count = column.querySelectorAll('.task-card').length;
            const header = column.querySelector('.column-header .count');
            if (header) header.textContent = count;
          }
        });
      }
    };
    
    // Time tracking system
    window.TimeTracker = {
      startTimer(taskId, userId) {
        const timerId = `${taskId}-${userId}`;
        
        if (ProjectApp.activeTimers.has(timerId)) {
          console.warn('Timer already running for this task');
          return;
        }
        
        const timer = {
          taskId,
          userId,
          startTime: Date.now(),
          intervalId: null
        };
        
        timer.intervalId = setInterval(() => {
          const elapsed = Date.now() - timer.startTime;
          document.dispatchEvent(new CustomEvent('timer:tick', {
            detail: { timerId, elapsed, taskId }
          }));
        }, 1000);
        
        ProjectApp.activeTimers.set(timerId, timer);
        
        document.dispatchEvent(new CustomEvent('timer:started', {
          detail: { timerId, taskId, userId }
        }));
      },
      
      stopTimer(taskId, userId) {
        const timerId = `${taskId}-${userId}`;
        const timer = ProjectApp.activeTimers.get(timerId);
        
        if (!timer) return;
        
        clearInterval(timer.intervalId);
        const duration = Date.now() - timer.startTime;
        
        const timeEntry = {
          id: Date.now(),
          taskId,
          userId,
          duration,
          startTime: dayjs(timer.startTime).toISOString(),
          endTime: dayjs().toISOString()
        };
        
        ProjectApp.timeEntries.push(timeEntry);
        ProjectApp.activeTimers.delete(timerId);
        
        document.dispatchEvent(new CustomEvent('timer:stopped', {
          detail: { timerId, timeEntry }
        }));
        
        return timeEntry;
      },
      
      formatDuration(milliseconds) {
        const seconds = Math.floor(milliseconds / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        
        return `${hours.toString().padStart(2, '0')}:${(minutes % 60).toString().padStart(2, '0')}:${(seconds % 60).toString().padStart(2, '0')}`;
      }
    };
    
    // Calendar and scheduling
    window.CalendarManager = {
      events: new Map(),
      
      addEvent(eventData) {
        const event = {
          id: Date.now(),
          ...eventData,
          createdAt: dayjs().toISOString()
        };
        
        this.events.set(event.id, event);
        
        document.dispatchEvent(new CustomEvent('calendar:event-added', {
          detail: event
        }));
        
        return event;
      },
      
      getEventsForDate(date) {
        const targetDate = dayjs(date).format('YYYY-MM-DD');
        
        return Array.from(this.events.values()).filter(event => {
          const eventDate = dayjs(event.startDate).format('YYYY-MM-DD');
          return eventDate === targetDate;
        });
      },
      
      generateWeekView(startDate) {
        const week = [];
        const start = dayjs(startDate).startOf('week');
        
        for (let i = 0; i < 7; i++) {
          const date = start.add(i, 'day');
          const events = this.getEventsForDate(date);
          
          week.push({
            date: date.format('YYYY-MM-DD'),
            dayName: date.format('dddd'),
            dayNumber: date.format('D'),
            events: events,
            isToday: date.isSame(dayjs(), 'day')
          });
        }
        
        return week;
      }
    };
    
    // Team collaboration
    window.TeamManager = {
      members: new Map(),
      
      addMember(memberData) {
        const member = {
          id: Date.now(),
          ...memberData,
          joinedAt: dayjs().toISOString(),
          isOnline: false
        };
        
        this.members.set(member.id, member);
        
        document.dispatchEvent(new CustomEvent('team:member-added', {
          detail: member
        }));
        
        return member;
      },
      
      updateMemberStatus(memberId, isOnline) {
        const member = this.members.get(memberId);
        if (!member) return;
        
        member.isOnline = isOnline;
        member.lastSeen = dayjs().toISOString();
        
        document.dispatchEvent(new CustomEvent('team:member-status-updated', {
          detail: { memberId, isOnline, member }
        }));
      },
      
      getOnlineMembers() {
        return Array.from(this.members.values()).filter(member => member.isOnline);
      }
    };
    
    // Gantt chart utilities
    window.GanttChart = {
      generateTimeline(tasks, startDate, endDate) {
        const start = dayjs(startDate);
        const end = dayjs(endDate);
        const totalDays = end.diff(start, 'days');
        
        return tasks.map(task => {
          const taskStart = dayjs(task.startDate);
          const taskEnd = dayjs(task.endDate);
          
          const startOffset = Math.max(0, taskStart.diff(start, 'days'));
          const duration = taskEnd.diff(taskStart, 'days') + 1;
          
          return {
            ...task,
            startOffset,
            duration,
            progress: task.progress || 0,
            isOverdue: taskEnd.isBefore(dayjs()) && task.status !== 'done'
          };
        });
      }
    };
    
    console.log('Project management application with 7 controllers ready');
  JS
  
  {
    import_map_html: front_loader.render_import_map_tag,
    script_html: front_loader.render_stimulus_initialization_script(project_js)
  }
end

result = example_4_project_management_app
puts "Import Map:"
puts result[:import_map_html]
puts
puts "Initialization Script:"
puts result[:script_html]
puts
puts "🎯 Key Features Demonstrated:"
puts "- 7 specialized controllers for project management"
puts "- Drag-and-drop Kanban boards with SortableJS"
puts "- Time tracking with active timers"
puts "- Calendar and scheduling system"
puts "- Team collaboration features"
puts "- Gantt chart timeline generation"
puts "=" * 80
puts

# Summary of Complex Multi-Controller Examples
# ----------------------------------------------------------------------------
puts "🎯 Summary: Complex Multi-Controller Application Examples"
puts
puts "✅ Completed Examples:"
puts "1. E-commerce Application (5 controllers) - Cart, Product, Search, Checkout, Notification"
puts "2. Dashboard Application (6 controllers) - Charts, Data Tables, WebSocket, Filters, Export"
puts "3. Social Media Application (7 controllers) - Posts, Comments, Likes, Chat, Media Upload"
puts "4. Project Management Application (7 controllers) - Tasks, Kanban, Calendar, Time Tracking"
puts
puts "📚 Advanced Concepts Demonstrated:"
puts "- Inter-controller communication via custom events"
puts "- Complex state management across multiple controllers"
puts "- Real-time updates and WebSocket integration"
puts "- Drag-and-drop functionality with external libraries"
puts "- Time tracking and performance monitoring"
puts "- File upload with progress tracking"
puts "- Calendar and scheduling systems"
puts "- Advanced data processing and visualization"
puts
puts "🔧 Technical Patterns Shown:"
puts "- Global application state management"
puts "- Event-driven architecture"
puts "- Shared utility functions"
puts "- Error handling and user feedback"
puts "- Performance optimization techniques"
puts "- Complex user interactions"
puts
puts "📁 Next: Integration examples with different view templates (Phase 6.2.3)"
puts "=" * 80 