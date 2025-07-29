/**
 * Amber Reactive Client
 * Real-time component updates via WebSocket
 * 
 * Features:
 * - WebSocket connection management
 * - Component registration and tracking
 * - DOM morphing for efficient updates
 * - Event handling and action dispatch
 * - Update queue management
 * - Mutation observer for dynamic content
 */

(function(window) {
  'use strict';

  // Constants
  const RECONNECT_DELAY = 1000;
  const MAX_RECONNECT_DELAY = 30000;
  const HEARTBEAT_INTERVAL = 30000;

  class AmberReactive {
    constructor(options = {}) {
      this.options = {
        url: options.url || this._buildWebSocketUrl(),
        debug: options.debug || false,
        reconnect: options.reconnect !== false,
        heartbeat: options.heartbeat !== false,
        morphdom: options.morphdom || window.morphdom,
        ...options
      };

      this.components = new Map();
      this.socket = null;
      this.connected = false;
      this.reconnectDelay = RECONNECT_DELAY;
      this.reconnectTimer = null;
      this.heartbeatTimer = null;
      this.messageQueue = [];
      this.sessionId = this._generateSessionId();

      this._bindMethods();
      this._setupMutationObserver();
    }

    // Initialize the reactive system
    init() {
      this._connect();
      this._scanForComponents();
      this._setupEventDelegation();
      
      if (this.options.debug) {
        console.log('AmberReactive initialized', {
          sessionId: this.sessionId,
          url: this.options.url
        });
      }
    }

    // Connect to WebSocket server
    _connect() {
      if (this.socket && this.socket.readyState === WebSocket.OPEN) {
        return;
      }

      try {
        this.socket = new WebSocket(this.options.url);
        this._setupSocketHandlers();
      } catch (error) {
        this._log('error', 'Failed to connect:', error);
        this._scheduleReconnect();
      }
    }

    // Setup WebSocket event handlers
    _setupSocketHandlers() {
      this.socket.onopen = () => {
        this.connected = true;
        this.reconnectDelay = RECONNECT_DELAY;
        this._log('info', 'Connected to server');
        
        // Send registration message
        this._send({
          type: 'register',
          sessionId: this.sessionId,
          components: Array.from(this.components.keys())
        });

        // Process queued messages
        this._flushMessageQueue();

        // Start heartbeat
        if (this.options.heartbeat) {
          this._startHeartbeat();
        }
      };

      this.socket.onclose = () => {
        this.connected = false;
        this._stopHeartbeat();
        this._log('info', 'Disconnected from server');
        
        if (this.options.reconnect) {
          this._scheduleReconnect();
        }
      };

      this.socket.onerror = (error) => {
        this._log('error', 'WebSocket error:', error);
      };

      this.socket.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);
          this._handleMessage(message);
        } catch (error) {
          this._log('error', 'Failed to parse message:', error);
        }
      };
    }

    // Handle incoming messages
    _handleMessage(message) {
      this._log('debug', 'Received message:', message);

      switch (message.type) {
        case 'update':
          this._updateComponent(message.componentId, message.html, message.state);
          break;
        
        case 'batch_update':
          message.updates.forEach(update => {
            this._updateComponent(update.componentId, update.html, update.state);
          });
          break;
        
        case 'reload':
          window.location.reload();
          break;
        
        case 'eval':
          if (message.code) {
            try {
              eval(message.code);
            } catch (error) {
              this._log('error', 'Failed to evaluate code:', error);
            }
          }
          break;
        
        case 'pong':
          // Heartbeat response
          break;
        
        default:
          this._log('warn', 'Unknown message type:', message.type);
      }
    }

    // Update a component's DOM
    _updateComponent(componentId, html, state) {
      const element = document.querySelector(`[data-component-id="${componentId}"]`);
      
      if (!element) {
        this._log('warn', 'Component not found:', componentId);
        return;
      }

      // Use morphdom for efficient DOM updates
      if (this.options.morphdom) {
        this.options.morphdom(element, html, {
          onBeforeElUpdated: (fromEl, toEl) => {
            // Preserve focus state
            if (fromEl === document.activeElement && fromEl.tagName === 'INPUT') {
              const cursorPos = fromEl.selectionStart;
              requestAnimationFrame(() => {
                fromEl.focus();
                fromEl.setSelectionRange(cursorPos, cursorPos);
              });
            }
            return true;
          }
        });
      } else {
        // Fallback to innerHTML
        element.outerHTML = html;
      }

      // Update component state
      if (state && this.components.has(componentId)) {
        this.components.get(componentId).state = state;
      }

      // Re-scan for new components
      this._scanForComponents(element.parentElement);
    }

    // Scan DOM for components
    _scanForComponents(root = document) {
      const elements = root.querySelectorAll('[data-component-id]');
      
      elements.forEach(element => {
        const componentId = element.dataset.componentId;
        
        if (!this.components.has(componentId)) {
          const component = {
            id: componentId,
            element: element,
            type: element.dataset.componentType || 'unknown',
            state: {}
          };
          
          this.components.set(componentId, component);
          
          // Notify server of new component
          if (this.connected) {
            this._send({
              type: 'component_added',
              componentId: componentId,
              componentType: component.type
            });
          }
        }
      });
    }

    // Setup event delegation for actions
    _setupEventDelegation() {
      document.addEventListener('click', this._handleAction);
      document.addEventListener('submit', this._handleAction);
      document.addEventListener('input', this._handleAction);
      document.addEventListener('change', this._handleAction);
    }

    // Handle action events
    _handleAction(event) {
      const target = event.target;
      const action = target.dataset.action;
      
      if (!action) return;

      // Parse action format: "event->method"
      const [eventType, method] = action.split('->');
      
      if (eventType !== event.type) return;

      // Find component
      const componentElement = target.closest('[data-component-id]');
      if (!componentElement) return;

      const componentId = componentElement.dataset.componentId;
      
      // Prevent default for forms
      if (event.type === 'submit') {
        event.preventDefault();
      }

      // Gather event data
      const eventData = this._gatherEventData(event, target);

      // Send action to server
      this._send({
        type: 'action',
        componentId: componentId,
        method: method,
        event: eventData
      });
    }

    // Gather relevant event data
    _gatherEventData(event, target) {
      const data = {
        type: event.type,
        timestamp: Date.now()
      };

      switch (event.type) {
        case 'input':
        case 'change':
          data.value = target.value;
          data.name = target.name;
          break;
        
        case 'submit':
          // Gather form data
          const form = event.target;
          const formData = new FormData(form);
          data.fields = {};
          
          for (const [key, value] of formData.entries()) {
            data.fields[key] = value;
          }
          break;
        
        case 'click':
          data.x = event.clientX;
          data.y = event.clientY;
          break;
      }

      return data;
    }

    // Setup mutation observer for dynamic content
    _setupMutationObserver() {
      if (!window.MutationObserver) return;

      const observer = new MutationObserver((mutations) => {
        mutations.forEach(mutation => {
          if (mutation.type === 'childList') {
            mutation.addedNodes.forEach(node => {
              if (node.nodeType === Node.ELEMENT_NODE) {
                this._scanForComponents(node);
              }
            });
          }
        });
      });

      // Start observing when connected
      this._mutationObserver = observer;
    }

    // Start observing mutations
    _startObserving() {
      if (this._mutationObserver) {
        this._mutationObserver.observe(document.body, {
          childList: true,
          subtree: true
        });
      }
    }

    // Send message to server
    _send(message) {
      if (this.connected && this.socket.readyState === WebSocket.OPEN) {
        this.socket.send(JSON.stringify(message));
      } else {
        // Queue message for later
        this.messageQueue.push(message);
      }
    }

    // Flush queued messages
    _flushMessageQueue() {
      while (this.messageQueue.length > 0) {
        const message = this.messageQueue.shift();
        this._send(message);
      }
    }

    // Heartbeat to keep connection alive
    _startHeartbeat() {
      this._stopHeartbeat();
      
      this.heartbeatTimer = setInterval(() => {
        if (this.connected) {
          this._send({ type: 'ping' });
        }
      }, HEARTBEAT_INTERVAL);
    }

    _stopHeartbeat() {
      if (this.heartbeatTimer) {
        clearInterval(this.heartbeatTimer);
        this.heartbeatTimer = null;
      }
    }

    // Reconnection logic
    _scheduleReconnect() {
      if (this.reconnectTimer) {
        clearTimeout(this.reconnectTimer);
      }

      this.reconnectTimer = setTimeout(() => {
        this._log('info', 'Attempting to reconnect...');
        this._connect();
      }, this.reconnectDelay);

      // Exponential backoff
      this.reconnectDelay = Math.min(this.reconnectDelay * 2, MAX_RECONNECT_DELAY);
    }

    // Utility methods
    _bindMethods() {
      this._handleAction = this._handleAction.bind(this);
    }

    _buildWebSocketUrl() {
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      return `${protocol}//${window.location.host}/components/ws`;
    }

    _generateSessionId() {
      return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    _log(level, ...args) {
      if (this.options.debug || level === 'error') {
        console[level]('[AmberReactive]', ...args);
      }
    }

    // Public API
    
    // Manually trigger component update
    updateComponent(componentId, state) {
      this._send({
        type: 'update_state',
        componentId: componentId,
        state: state
      });
    }

    // Register custom event handler
    on(eventType, handler) {
      document.addEventListener(`amber:${eventType}`, handler);
    }

    // Trigger custom event
    emit(eventType, detail) {
      const event = new CustomEvent(`amber:${eventType}`, { detail });
      document.dispatchEvent(event);
    }

    // Disconnect from server
    disconnect() {
      this.options.reconnect = false;
      
      if (this.socket) {
        this.socket.close();
      }
    }

    // Reconnect to server
    reconnect() {
      this.options.reconnect = true;
      this._connect();
    }
  }

  // Export to window
  window.AmberReactive = AmberReactive;

  // Auto-initialize if data attribute present
  document.addEventListener('DOMContentLoaded', () => {
    if (document.body.dataset.amberReactive) {
      const reactive = new AmberReactive();
      reactive.init();
      window.amberReactive = reactive;
    }
  });

})(window);