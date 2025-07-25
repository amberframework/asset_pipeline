/**
 * DOM Utilities - Common DOM manipulation and event handling utilities
 * 
 * This module provides:
 * - Event delegation system
 * - Element creation and manipulation helpers
 * - Data attribute management
 * - CSS class utilities
 * - Query helpers
 */

/**
 * Event delegation utility for efficient event handling
 */
class EventDelegate {
  constructor(rootElement = document.body) {
    this.rootElement = rootElement;
    this.handlers = new Map();
    this.setupDelegation();
  }

  /**
   * Add event listener with delegation
   * @param {string} eventType - Event type (click, change, etc.)
   * @param {string} selector - CSS selector for target elements
   * @param {Function} handler - Event handler function
   * @param {Object} options - Event listener options
   */
  on(eventType, selector, handler, options = {}) {
    if (!this.handlers.has(eventType)) {
      this.handlers.set(eventType, []);
    }
    
    this.handlers.get(eventType).push({
      selector,
      handler,
      options
    });
  }

  /**
   * Remove event listener
   * @param {string} eventType - Event type
   * @param {string} selector - CSS selector
   * @param {Function} handler - Handler to remove
   */
  off(eventType, selector, handler) {
    if (!this.handlers.has(eventType)) return;
    
    const handlers = this.handlers.get(eventType);
    const index = handlers.findIndex(h => 
      h.selector === selector && h.handler === handler
    );
    
    if (index > -1) {
      handlers.splice(index, 1);
    }
  }

  /**
   * Setup event delegation
   * @private
   */
  setupDelegation() {
    // Common events that benefit from delegation
    const delegatedEvents = [
      'click', 'change', 'input', 'submit', 'focus', 'blur',
      'mouseenter', 'mouseleave', 'keydown', 'keyup'
    ];

    delegatedEvents.forEach(eventType => {
      this.rootElement.addEventListener(eventType, (event) => {
        this.handleDelegatedEvent(eventType, event);
      }, { capture: true });
    });
  }

  /**
   * Handle delegated event
   * @private
   */
  handleDelegatedEvent(eventType, event) {
    if (!this.handlers.has(eventType)) return;

    const handlers = this.handlers.get(eventType);
    
    handlers.forEach(({ selector, handler, options }) => {
      const target = event.target.closest(selector);
      if (target && this.rootElement.contains(target)) {
        // Create enhanced event object
        const enhancedEvent = {
          ...event,
          delegateTarget: target,
          originalTarget: event.target
        };
        
        try {
          handler.call(target, enhancedEvent);
        } catch (error) {
          console.error(`[EventDelegate] Error in ${eventType} handler:`, error);
        }
      }
    });
  }

  /**
   * Cleanup all event listeners
   */
  destroy() {
    this.handlers.clear();
    // Note: We can't easily remove the delegated listeners without 
    // storing references, but they'll be cleaned up when rootElement is removed
  }
}

/**
 * DOM manipulation utilities
 */
const DOMUtils = {
  /**
   * Create element with attributes and content
   * @param {string} tagName - HTML tag name
   * @param {Object} attributes - Element attributes
   * @param {string|HTMLElement|Array} content - Element content
   * @returns {HTMLElement} Created element
   */
  createElement(tagName, attributes = {}, content = '') {
    const element = document.createElement(tagName);
    
    // Set attributes
    Object.entries(attributes).forEach(([key, value]) => {
      if (key === 'dataset') {
        Object.entries(value).forEach(([dataKey, dataValue]) => {
          element.dataset[dataKey] = dataValue;
        });
      } else if (key === 'style' && typeof value === 'object') {
        Object.entries(value).forEach(([styleProp, styleValue]) => {
          element.style[styleProp] = styleValue;
        });
      } else {
        element.setAttribute(key, value);
      }
    });
    
    // Set content
    if (typeof content === 'string') {
      element.innerHTML = content;
    } else if (content instanceof HTMLElement) {
      element.appendChild(content);
    } else if (Array.isArray(content)) {
      content.forEach(item => {
        if (typeof item === 'string') {
          element.insertAdjacentHTML('beforeend', item);
        } else if (item instanceof HTMLElement) {
          element.appendChild(item);
        }
      });
    }
    
    return element;
  },

  /**
   * Find elements by selector with optional context
   * @param {string} selector - CSS selector
   * @param {HTMLElement} context - Context element (default: document)
   * @returns {Array} Array of elements
   */
  findElements(selector, context = document) {
    return Array.from(context.querySelectorAll(selector));
  },

  /**
   * Find single element by selector with optional context
   * @param {string} selector - CSS selector
   * @param {HTMLElement} context - Context element (default: document)
   * @returns {HTMLElement|null} Found element or null
   */
  findElement(selector, context = document) {
    return context.querySelector(selector);
  },

  /**
   * Check if element matches selector
   * @param {HTMLElement} element - Element to check
   * @param {string} selector - CSS selector
   * @returns {boolean} True if element matches
   */
  matches(element, selector) {
    return element.matches(selector);
  },

  /**
   * Find closest ancestor matching selector
   * @param {HTMLElement} element - Starting element
   * @param {string} selector - CSS selector
   * @returns {HTMLElement|null} Closest matching ancestor or null
   */
  closest(element, selector) {
    return element.closest(selector);
  },

  /**
   * Get/set data attributes
   * @param {HTMLElement} element - Target element
   * @param {string|Object} key - Data key or object of key-value pairs
   * @param {*} value - Value to set (if key is string)
   * @returns {*} Data value or element for chaining
   */
  data(element, key, value) {
    if (typeof key === 'object') {
      // Set multiple data attributes
      Object.entries(key).forEach(([k, v]) => {
        element.dataset[k] = v;
      });
      return element;
    } else if (value !== undefined) {
      // Set single data attribute
      element.dataset[key] = value;
      return element;
    } else {
      // Get data attribute
      return element.dataset[key];
    }
  },

  /**
   * Add CSS classes
   * @param {HTMLElement} element - Target element
   * @param {...string} classes - Classes to add
   * @returns {HTMLElement} Element for chaining
   */
  addClass(element, ...classes) {
    element.classList.add(...classes);
    return element;
  },

  /**
   * Remove CSS classes
   * @param {HTMLElement} element - Target element
   * @param {...string} classes - Classes to remove
   * @returns {HTMLElement} Element for chaining
   */
  removeClass(element, ...classes) {
    element.classList.remove(...classes);
    return element;
  },

  /**
   * Toggle CSS classes
   * @param {HTMLElement} element - Target element
   * @param {string} className - Class to toggle
   * @param {boolean} force - Force add/remove
   * @returns {HTMLElement} Element for chaining
   */
  toggleClass(element, className, force) {
    element.classList.toggle(className, force);
    return element;
  },

  /**
   * Check if element has CSS class
   * @param {HTMLElement} element - Target element
   * @param {string} className - Class to check
   * @returns {boolean} True if element has class
   */
  hasClass(element, className) {
    return element.classList.contains(className);
  },

  /**
   * Show element
   * @param {HTMLElement} element - Element to show
   * @param {string} display - Display value (default: 'block')
   * @returns {HTMLElement} Element for chaining
   */
  show(element, display = 'block') {
    element.style.display = display;
    return element;
  },

  /**
   * Hide element
   * @param {HTMLElement} element - Element to hide
   * @returns {HTMLElement} Element for chaining
   */
  hide(element) {
    element.style.display = 'none';
    return element;
  },

  /**
   * Check if element is visible
   * @param {HTMLElement} element - Element to check
   * @returns {boolean} True if element is visible
   */
  isVisible(element) {
    return element.offsetParent !== null;
  },

  /**
   * Get/set element text content
   * @param {HTMLElement} element - Target element
   * @param {string} text - Text to set (optional)
   * @returns {string|HTMLElement} Text content or element for chaining
   */
  text(element, text) {
    if (text !== undefined) {
      element.textContent = text;
      return element;
    }
    return element.textContent;
  },

  /**
   * Get/set element HTML content
   * @param {HTMLElement} element - Target element
   * @param {string} html - HTML to set (optional)
   * @returns {string|HTMLElement} HTML content or element for chaining
   */
  html(element, html) {
    if (html !== undefined) {
      element.innerHTML = html;
      return element;
    }
    return element.innerHTML;
  },

  /**
   * Remove element from DOM
   * @param {HTMLElement} element - Element to remove
   */
  remove(element) {
    if (element && element.parentNode) {
      element.parentNode.removeChild(element);
    }
  },

  /**
   * Get element dimensions and position
   * @param {HTMLElement} element - Target element
   * @returns {Object} Dimensions and position
   */
  getRect(element) {
    const rect = element.getBoundingClientRect();
    return {
      width: rect.width,
      height: rect.height,
      top: rect.top,
      left: rect.left,
      bottom: rect.bottom,
      right: rect.right,
      x: rect.x,
      y: rect.y
    };
  },

  /**
   * Check if element is in viewport
   * @param {HTMLElement} element - Element to check
   * @param {number} threshold - Threshold percentage (0-1)
   * @returns {boolean} True if element is in viewport
   */
  isInViewport(element, threshold = 0) {
    const rect = element.getBoundingClientRect();
    const windowHeight = window.innerHeight;
    const windowWidth = window.innerWidth;
    
    const verticalInView = (rect.top + rect.height * threshold) < windowHeight && 
                          (rect.bottom - rect.height * threshold) > 0;
    const horizontalInView = (rect.left + rect.width * threshold) < windowWidth && 
                            (rect.right - rect.width * threshold) > 0;
    
    return verticalInView && horizontalInView;
  },

  /**
   * Animate element with CSS transitions
   * @param {HTMLElement} element - Element to animate
   * @param {Object} properties - CSS properties to animate
   * @param {number} duration - Animation duration in ms
   * @param {string} easing - CSS easing function
   * @returns {Promise} Promise that resolves when animation completes
   */
  animate(element, properties, duration = 300, easing = 'ease') {
    return new Promise((resolve) => {
      const originalTransition = element.style.transition;
      
      // Set transition
      element.style.transition = `all ${duration}ms ${easing}`;
      
      // Apply properties
      Object.entries(properties).forEach(([prop, value]) => {
        element.style[prop] = value;
      });
      
      // Cleanup after animation
      const cleanup = () => {
        element.style.transition = originalTransition;
        element.removeEventListener('transitionend', cleanup);
        resolve(element);
      };
      
      element.addEventListener('transitionend', cleanup);
      
      // Fallback in case transitionend doesn't fire
      setTimeout(cleanup, duration + 50);
    });
  },

  /**
   * Debounce function execution
   * @param {Function} func - Function to debounce
   * @param {number} wait - Wait time in ms
   * @param {boolean} immediate - Execute immediately on first call
   * @returns {Function} Debounced function
   */
  debounce(func, wait, immediate = false) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        timeout = null;
        if (!immediate) func.apply(this, args);
      };
      const callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
      if (callNow) func.apply(this, args);
    };
  },

  /**
   * Throttle function execution
   * @param {Function} func - Function to throttle
   * @param {number} limit - Time limit in ms
   * @returns {Function} Throttled function
   */
  throttle(func, limit) {
    let inThrottle;
    return function executedFunction(...args) {
      if (!inThrottle) {
        func.apply(this, args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  }
};

// Create global event delegate instance
const globalEventDelegate = new EventDelegate();

// Export utilities
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { EventDelegate, DOMUtils, globalEventDelegate };
} else if (typeof window !== 'undefined') {
  window.EventDelegate = EventDelegate;
  window.DOMUtils = DOMUtils;
  window.globalEventDelegate = globalEventDelegate;
  
  // Convenient global shortcuts
  window.$ = DOMUtils.findElement;
  window.$$ = DOMUtils.findElements;
} 