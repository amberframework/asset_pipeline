// Vanilla-JS bottom-sheet behavior for UI::ActionSheetWithWebFallback.
// Pure DOM; no framework. Idempotent — safe to register multiple times
// (guarded by window.__apActionSheetInitialized).
//
// Behaviors:
//   * Backdrop click dismisses (treated as 'backdrop')
//   * Escape key dismisses (treated as 'escape')
//   * Focus trap inside the panel while presented
//   * On show: save previously focused element, focus first action
//   * On dismiss: restore focus to previously focused element
//   * Optional swipe-down on the handle dismisses on touch devices
//
// Custom-event contract with Crystal-side hosts:
//   * Crystal emits <div class="ap-action-sheet" data-presented="true|false">.
//   * Toggling data-presented opens/closes the sheet.
//   * Action clicks dispatch CustomEvent("ap:action-sheet:action",
//     { detail: { index, label } }) on the root element.
//   * Any dismissal dispatches CustomEvent("ap:action-sheet:dismiss",
//     { detail: { reason } }).
(function () {
  if (window.__apActionSheetInitialized) return;
  window.__apActionSheetInitialized = true;

  var FOCUSABLE =
    'a[href],button:not([disabled]),input:not([disabled]),' +
    'select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])';

  var state = new WeakMap();

  function focusables(panel) {
    return Array.prototype.filter.call(
      panel.querySelectorAll(FOCUSABLE),
      function (el) { return el.offsetParent !== null || el === document.activeElement; }
    );
  }

  function trapFocus(e, root) {
    if (e.key !== 'Tab') return;
    var panel = root.querySelector('.ap-action-sheet__panel');
    if (!panel) return;
    var els = focusables(panel);
    if (els.length === 0) { e.preventDefault(); panel.focus(); return; }
    var first = els[0], last = els[els.length - 1];
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault(); last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault(); first.focus();
    }
  }

  function show(root) {
    var s = state.get(root) || {};
    s.previouslyFocused = document.activeElement;
    state.set(root, s);
    var panel = root.querySelector('.ap-action-sheet__panel');
    if (!panel) return;
    var first = focusables(panel)[0] || panel;
    requestAnimationFrame(function () { first.focus(); });
  }

  function hide(root, reason) {
    var s = state.get(root);
    root.setAttribute('data-presented', 'false');
    root.dispatchEvent(new CustomEvent('ap:action-sheet:dismiss',
      { detail: { reason: reason } }));
    if (s && s.previouslyFocused && typeof s.previouslyFocused.focus === 'function') {
      s.previouslyFocused.focus();
    }
  }

  function attach(root) {
    if (root.__apBound) return;
    root.__apBound = true;

    root.addEventListener('click', function (e) {
      var dismiss = e.target.closest('[data-ap-as-dismiss]');
      if (dismiss) {
        e.preventDefault();
        hide(root, dismiss.getAttribute('data-ap-as-dismiss'));
        return;
      }
      var action = e.target.closest('[data-ap-as-action]');
      if (action) {
        e.preventDefault();
        var index = parseInt(action.getAttribute('data-ap-as-action'), 10);
        root.dispatchEvent(new CustomEvent('ap:action-sheet:action', {
          detail: { index: index, label: (action.textContent || '').trim() }
        }));
        hide(root, 'action');
      }
    });

    root.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') { e.preventDefault(); hide(root, 'escape'); return; }
      trapFocus(e, root);
    });

    var handle = root.querySelector('.ap-action-sheet__handle');
    if (handle && 'ontouchstart' in window) {
      var startY = null;
      handle.addEventListener('touchstart', function (e) {
        startY = e.touches[0].clientY;
      }, { passive: true });
      handle.addEventListener('touchmove', function (e) {
        if (startY === null) return;
        var dy = e.touches[0].clientY - startY;
        if (dy > 48) { hide(root, 'swipe'); startY = null; }
      }, { passive: true });
    }

    // Watch the root for data-presented flips so show() bookkeeping runs.
    // Scope: this single root only. attributeFilter narrows to the one
    // attribute the JS cares about.
    new MutationObserver(function (records) {
      for (var i = 0; i < records.length; i++) {
        var r = records[i];
        if (r.attributeName === 'data-presented' &&
            root.getAttribute('data-presented') === 'true') {
          show(root);
        }
      }
    }).observe(root, { attributes: true, attributeFilter: ['data-presented'] });

    if (root.getAttribute('data-presented') === 'true') show(root);
  }

  function init() {
    var roots = document.querySelectorAll('.ap-action-sheet');
    for (var i = 0; i < roots.length; i++) attach(roots[i]);
  }

  if (document.readyState !== 'loading') init();
  else document.addEventListener('DOMContentLoaded', init);

  // Re-bind when new sheets are inserted by Crystal re-renders. Scope
  // is document-wide because new roots could be inserted anywhere in
  // the layout; childList only minimizes work.
  new MutationObserver(init).observe(document.documentElement,
    { childList: true, subtree: true });
})();
