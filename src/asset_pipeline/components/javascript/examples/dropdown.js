/**
 * Dropdown - JavaScript implementation for dropdown menus and content
 * 
 * This component manages:
 * - Open/close state
 * - Click outside to close
 * - Keyboard navigation
 * - Focus management
 * - Positioning
 */
class Dropdown extends StatefulComponentJS {
  /**
   * Initialize the dropdown component
   */
  initialize() {
    // Find dropdown elements
    this.trigger = this.find('.dropdown-trigger') || this.find('[data-toggle="dropdown"]');
    this.menu = this.find('.dropdown-menu') || this.find('.dropdown-content');
    this.items = this.findAll('.dropdown-item');
    
    if (!this.trigger) {
      console.warn('[Dropdown] Trigger element not found');
      return;
    }
    
    if (!this.menu) {
      console.warn('[Dropdown] Menu element not found');
      return;
    }
    
    // Set initial state
    if (!this.state.hasOwnProperty('isOpen')) {
      const initialOpen = this.element.dataset.open === 'true' || 
                         this.menu.classList.contains('dropdown-open') ||
                         !this.menu.hidden;
      this.setState('isOpen', initialOpen, true);
    }
    
    // Track focus for accessibility
    this.focusedItemIndex = -1;
    
    // Setup close on outside click
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
    
    // Update display
    this.updateDisplay();
  }

  /**
   * Bind event listeners
   */
  bindEvents() {
    // Trigger click
    this.addEventListener('click', this.trigger, this.handleTriggerClick);
    
    // Trigger keyboard
    this.addEventListener('keydown', this.trigger, this.handleTriggerKeydown);
    
    // Menu keyboard navigation
    this.addEventListener('keydown', this.menu, this.handleMenuKeydown);
    
    // Item clicks
    if (this.items.length > 0) {
      this.addEventListener('click', '.dropdown-item', this.handleItemClick);
    }
    
    // Prevent menu clicks from closing dropdown
    this.addEventListener('click', this.menu, this.handleMenuClick);
  }

  /**
   * Handle trigger click
   * @param {Event} event - Click event
   */
  handleTriggerClick = (event) => {
    event.preventDefault();
    event.stopPropagation();
    this.toggle();
  }

  /**
   * Handle trigger keyboard
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleTriggerKeydown = (event) => {
    switch (event.key) {
      case 'Enter':
      case ' ':
        event.preventDefault();
        this.toggle();
        break;
      case 'ArrowDown':
        event.preventDefault();
        this.open();
        this.focusFirstItem();
        break;
      case 'Escape':
        this.close();
        break;
    }
  }

  /**
   * Handle menu keyboard navigation
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleMenuKeydown = (event) => {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.focusNextItem();
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.focusPreviousItem();
        break;
      case 'Home':
        event.preventDefault();
        this.focusFirstItem();
        break;
      case 'End':
        event.preventDefault();
        this.focusLastItem();
        break;
      case 'Escape':
        event.preventDefault();
        this.close();
        this.trigger.focus();
        break;
      case 'Tab':
        // Allow tab to close dropdown
        this.close();
        break;
    }
  }

  /**
   * Handle dropdown item click
   * @param {Event} event - Click event
   */
  handleItemClick = (event) => {
    const item = event.delegateTarget;
    const value = item.dataset.value || item.textContent.trim();
    
    // Trigger selection event
    this.triggerEvent('dropdown:select', {
      item,
      value,
      index: this.items.indexOf(item)
    });
    
    // Close dropdown unless specified otherwise
    if (item.dataset.keepOpen !== 'true') {
      this.close();
      this.trigger.focus();
    }
  }

  /**
   * Handle menu click (prevent closing)
   * @param {Event} event - Click event
   */
  handleMenuClick = (event) => {
    event.stopPropagation();
  }

  /**
   * Handle outside click to close dropdown
   * @param {Event} event - Click event
   */
  handleOutsideClick = (event) => {
    if (!this.element.contains(event.target)) {
      this.close();
    }
  }

  /**
   * Open the dropdown
   */
  open() {
    if (this.getState('isOpen')) return;
    
    this.setState('isOpen', true);
    
    // Add outside click listener
    document.addEventListener('click', this.boundHandleOutsideClick);
    
    this.triggerEvent('dropdown:open');
  }

  /**
   * Close the dropdown
   */
  close() {
    if (!this.getState('isOpen')) return;
    
    this.setState('isOpen', false);
    this.focusedItemIndex = -1;
    
    // Remove outside click listener
    document.removeEventListener('click', this.boundHandleOutsideClick);
    
    this.triggerEvent('dropdown:close');
  }

  /**
   * Toggle dropdown state
   */
  toggle() {
    if (this.getState('isOpen')) {
      this.close();
    } else {
      this.open();
    }
  }

  /**
   * Focus management methods
   */
  focusFirstItem() {
    this.focusItemAtIndex(0);
  }

  focusLastItem() {
    this.focusItemAtIndex(this.items.length - 1);
  }

  focusNextItem() {
    const nextIndex = this.focusedItemIndex < this.items.length - 1 
      ? this.focusedItemIndex + 1 
      : 0;
    this.focusItemAtIndex(nextIndex);
  }

  focusPreviousItem() {
    const prevIndex = this.focusedItemIndex > 0 
      ? this.focusedItemIndex - 1 
      : this.items.length - 1;
    this.focusItemAtIndex(prevIndex);
  }

  focusItemAtIndex(index) {
    if (index >= 0 && index < this.items.length) {
      // Remove previous focus
      if (this.focusedItemIndex >= 0) {
        this.items[this.focusedItemIndex].classList.remove('dropdown-item-focused');
      }
      
      // Set new focus
      this.focusedItemIndex = index;
      const item = this.items[index];
      item.classList.add('dropdown-item-focused');
      item.focus();
    }
  }

  /**
   * Update display when state changes
   * @param {Object} prevState - Previous state
   * @param {Object} currentState - Current state
   */
  onStateChange(prevState, currentState) {
    if (prevState.isOpen !== currentState.isOpen) {
      this.updateDisplay();
    }
  }

  /**
   * Update visual state
   */
  updateDisplay() {
    const isOpen = this.getState('isOpen');
    
    // Update classes
    this.element.classList.toggle('dropdown-open', isOpen);
    this.menu.classList.toggle('dropdown-menu-open', isOpen);
    
    // Update ARIA attributes
    this.trigger.setAttribute('aria-expanded', isOpen.toString());
    this.menu.setAttribute('aria-hidden', (!isOpen).toString());
    
    // Update visibility
    if (isOpen) {
      this.menu.hidden = false;
      this.menu.style.display = '';
    } else {
      this.menu.hidden = true;
      // Clear focused items
      this.items.forEach(item => {
        item.classList.remove('dropdown-item-focused');
      });
    }
    
    // Update data attribute
    this.element.dataset.open = isOpen.toString();
  }

  /**
   * Check if dropdown is open
   * @returns {boolean} True if open
   */
  isOpen() {
    return this.getState('isOpen');
  }

  /**
   * Component-specific mount logic
   */
  onMount() {
    // Set up ARIA attributes
    this.trigger.setAttribute('aria-haspopup', 'true');
    
    if (!this.trigger.hasAttribute('aria-controls') && this.menu.id) {
      this.trigger.setAttribute('aria-controls', this.menu.id);
    }
    
    // Ensure menu has role
    if (!this.menu.hasAttribute('role')) {
      this.menu.setAttribute('role', 'menu');
    }
    
    // Set up menu items
    this.items.forEach((item, index) => {
      if (!item.hasAttribute('role')) {
        item.setAttribute('role', 'menuitem');
      }
      if (!item.hasAttribute('tabindex')) {
        item.setAttribute('tabindex', '-1');
      }
    });
    
    // Add interactive class
    this.element.classList.add('dropdown-interactive');
  }

  /**
   * Component-specific unmount logic
   */
  onUnmount() {
    // Clean up outside click listener
    document.removeEventListener('click', this.boundHandleOutsideClick);
    
    // Clean up ARIA attributes
    this.trigger.removeAttribute('aria-expanded');
    this.trigger.removeAttribute('aria-haspopup');
    this.trigger.removeAttribute('aria-controls');
    
    this.menu.removeAttribute('aria-hidden');
    
    // Remove interactive class
    this.element.classList.remove('dropdown-interactive');
  }

  /**
   * Update component display
   */
  update() {
    this.updateDisplay();
  }

  /**
   * Get debug information
   * @returns {Object} Debug information
   */
  getDebugInfo() {
    return {
      ...super.getDebugInfo(),
      isOpen: this.isOpen(),
      focusedItemIndex: this.focusedItemIndex,
      itemCount: this.items.length,
      elements: {
        trigger: !!this.trigger,
        menu: !!this.menu,
        items: this.items.length
      }
    };
  }
}

// Register the component
if (typeof window !== 'undefined' && window.componentManager) {
  window.componentManager.register('dropdown', Dropdown);
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = Dropdown;
} else if (typeof window !== 'undefined') {
  window.Dropdown = Dropdown;
} 