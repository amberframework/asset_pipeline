(() => {
  const THEME_KEY = "ap-theme";
  const LEGACY_THEME_KEY = "amber-theme";
  const AMBER_PREFIX = "data-amber-";
  const AP_PREFIX = "data-ap-";
  const qsa = (root, selector) => Array.from(root.querySelectorAll(selector));
  const hookSelector = (hook) => `[${AMBER_PREFIX}${hook}], [${AP_PREFIX}${hook}]`;
  const elementHookSelector = (element, hook) => `${element}[${AMBER_PREFIX}${hook}], ${element}[${AP_PREFIX}${hook}]`;
  const descendantHookSelector = (hook, descendant) =>
    `[${AMBER_PREFIX}${hook}] ${descendant}, [${AP_PREFIX}${hook}] ${descendant}`;
  const qsaHook = (root, hook) => qsa(root, hookSelector(hook));
  const qsHook = (root, hook) => root.querySelector(hookSelector(hook));
  const hasHook = (el, hook) => el.hasAttribute(`${AMBER_PREFIX}${hook}`) || el.hasAttribute(`${AP_PREFIX}${hook}`);
  const hookValue = (el, hook) => {
    const apValue = el.getAttribute(`${AP_PREFIX}${hook}`);
    if (apValue !== null && apValue !== "") return apValue;
    return el.getAttribute(`${AMBER_PREFIX}${hook}`);
  };
  const reduceMotion = () =>
    globalThis.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;

  let lastPointer = null;
  let activeCommandPanel = null;
  let commandReturnFocus = null;

  const focusableSelector = [
    "button:not([disabled])",
    "[href]",
    "input:not([disabled])",
    "select:not([disabled])",
    "textarea:not([disabled])",
    "[tabindex]:not([tabindex='-1'])",
  ].join(",");

  function focusableWithin(container) {
    return qsa(container, focusableSelector).filter((el) => {
      const styles = getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      return styles.display !== "none" && styles.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
    });
  }

  function preferredTheme() {
    const stored = globalThis.localStorage?.getItem(THEME_KEY) || globalThis.localStorage?.getItem(LEGACY_THEME_KEY);
    if (stored === "light" || stored === "dark") return stored;
    return globalThis.matchMedia?.("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function setTheme(theme, persist = true) {
    const nextTheme = theme === "dark" ? "dark" : "light";
    document.documentElement.dataset.amberTheme = nextTheme;
    document.documentElement.dataset.apTheme = nextTheme;
    document.documentElement.style.colorScheme = nextTheme;
    if (persist) {
      globalThis.localStorage?.setItem(THEME_KEY, nextTheme);
      globalThis.localStorage?.setItem(LEGACY_THEME_KEY, nextTheme);
    }

    qsaHook(document, "theme-toggle").forEach((button) => {
      const pressed = nextTheme === "dark";
      button.setAttribute("aria-pressed", String(pressed));
      const label = qsHook(button, "theme-label");
      if (label) label.textContent = pressed ? "Switch to light" : "Switch to dark";
    });

    qsaHook(document, "theme-set").forEach((button) => {
      const active = hookValue(button, "theme-set") === nextTheme;
      button.setAttribute("aria-pressed", String(active));
      button.dataset.state = active ? "selected" : "default";
    });

    qsaHook(document, "theme-status").forEach((status) => {
      status.textContent = `${nextTheme[0].toUpperCase()}${nextTheme.slice(1)} active`;
    });
  }

  function initThemeControls(root = document) {
    setTheme(preferredTheme(), false);

    qsaHook(root, "theme-toggle").forEach((button) => {
      if (button.dataset.amberBoundThemeToggle === "true") return;
      button.dataset.amberBoundThemeToggle = "true";
      button.addEventListener("click", () => {
        const current = document.documentElement.dataset.amberTheme === "dark" ? "dark" : "light";
        setTheme(current === "dark" ? "light" : "dark");
      });
    });

    qsaHook(root, "theme-set").forEach((button) => {
      if (button.dataset.amberBoundThemeSet === "true") return;
      button.dataset.amberBoundThemeSet = "true";
      button.addEventListener("click", () => setTheme(hookValue(button, "theme-set")));
    });
  }

  function initDisclosures(root = document) {
    qsaHook(root, "disclosure").forEach((button) => {
      if (button.dataset.amberBoundDisclosure === "true") return;
      button.dataset.amberBoundDisclosure = "true";
      const targetId = button.getAttribute("aria-controls");
      const target = targetId ? document.getElementById(targetId) : null;
      if (!target) return;

      button.addEventListener("click", () => {
        const expanded = button.getAttribute("aria-expanded") === "true";
        button.setAttribute("aria-expanded", String(!expanded));
        target.hidden = expanded;
        target.dataset.state = expanded ? "closed" : "open";
      });
    });
  }

  function initDialogs(root = document) {
    qsaHook(root, "dialog-open").forEach((button) => {
      if (button.dataset.amberBoundDialog === "true") return;
      button.dataset.amberBoundDialog = "true";
      const id = hookValue(button, "dialog-open")?.replace(/^#/, "");
      const dialog = id ? document.getElementById(id) : null;
      if (!(dialog instanceof HTMLDialogElement)) return;

      button.addEventListener("click", () => {
        dialog.dataset.returnFocus = button.id || "";
        dialog.__amberReturnFocus = button;
        dialog.showModal();
        requestAnimationFrame(() => {
          focusableWithin(dialog)[0]?.focus();
        });
      });

      if (dialog.dataset.amberBoundDialogTrap !== "true") {
        dialog.dataset.amberBoundDialogTrap = "true";
        dialog.addEventListener("keydown", (event) => {
          if (event.key !== "Tab") return;
          const focusable = focusableWithin(dialog);
          if (focusable.length === 0) return;
          const first = focusable[0];
          const last = focusable[focusable.length - 1];
          if (event.shiftKey && (document.activeElement === first || !dialog.contains(document.activeElement))) {
            event.preventDefault();
            last.focus();
          } else if (!event.shiftKey && document.activeElement === last) {
            event.preventDefault();
            first.focus();
          }
        });

        dialog.addEventListener("close", () => {
          const returnFocus = dialog.__amberReturnFocus;
          if (returnFocus && document.contains(returnFocus)) returnFocus.focus();
        });
      }
    });

    qsaHook(root, "dialog-close").forEach((button) => {
      if (button.dataset.amberBoundDialogClose === "true") return;
      button.dataset.amberBoundDialogClose = "true";
      button.addEventListener("click", () => {
        const dialog = button.closest("dialog");
        if (dialog instanceof HTMLDialogElement) dialog.close();
      });
    });
  }

  function initRowFilters(root = document) {
    qsaHook(root, "filter").forEach((control) => {
      if (control.dataset.amberBoundFilter === "true") return;
      control.dataset.amberBoundFilter = "true";
      const targetSelector = hookValue(control, "filter");
      const target = targetSelector ? document.querySelector(targetSelector) : null;
      if (!target) return;

      const applyFilter = () => {
        const query = control.value.trim().toLowerCase();
        let matchedCount = 0;
        qsa(target, "tbody tr").forEach((row) => {
          const matched = row.textContent.toLowerCase().includes(query);
          if (matched) {
            matchedCount += 1;
            row.hidden = false;
            row.style.animation = "";
            if (!reduceMotion()) {
              row.style.animation = "ap-row-enter var(--ap-motion-duration-base) var(--ap-motion-ease-emphasized) both";
            }
          } else if (reduceMotion()) {
            row.hidden = true;
            row.style.animation = "";
          } else {
            row.style.animation = "ap-row-exit var(--ap-motion-duration-fast) var(--ap-motion-ease-standard) both";
            row.addEventListener("animationend", () => {
              if (!row.textContent.toLowerCase().includes(control.value.trim().toLowerCase())) row.hidden = true;
            }, { once: true });
          }
        });

        const statusSelector = hookValue(control, "filter-status");
        const status = statusSelector
          ? document.querySelector(statusSelector)
          : null;
        if (status) status.textContent = matchedCount === 1 ? "1 matching row" : `${matchedCount} matching rows`;
      };

      control.addEventListener("input", applyFilter);
    });
  }

  function initStickyHover(root = document) {
    // data-amber-bound-* flags are private idempotency markers, not public hooks.
    if (document.documentElement.dataset.amberBoundPointerTracking !== "true") {
      document.documentElement.dataset.amberBoundPointerTracking = "true";
      document.addEventListener("pointermove", (event) => {
        lastPointer = { x: event.clientX, y: event.clientY };
      }, { passive: true });
    }

    qsaHook(root, "sticky-hover").forEach((el) => {
      if (el.dataset.amberBoundStickyHover === "true") return;
      el.dataset.amberBoundStickyHover = "true";
      if (reduceMotion()) return;

      el.addEventListener("pointerenter", (event) => {
        const dx = lastPointer ? event.clientX - lastPointer.x : 0;
        const dy = lastPointer ? event.clientY - lastPointer.y : 0;
        const length = Math.max(1, Math.hypot(dx, dy));
        const bumpX = (dx / length) * 7;
        const bumpY = (dy / length) * 6;
        el.animate([
          { transform: "translate(0, 0)" },
          { transform: `translate(${bumpX.toFixed(2)}px, ${bumpY.toFixed(2)}px)` },
          { transform: "translate(0, 0)" },
        ], {
          duration: 280,
          easing: "cubic-bezier(0.16, 1, 0.3, 1)",
        });
      });

      el.addEventListener("pointermove", (event) => {
        if (reduceMotion()) {
          el.style.transform = "";
          return;
        }
        const rect = el.getBoundingClientRect();
        const x = ((event.clientX - rect.left) / rect.width - 0.5) * 10;
        const y = ((event.clientY - rect.top) / rect.height - 0.5) * 8;
        el.style.transform = `translate(${x.toFixed(2)}px, ${y.toFixed(2)}px)`;
      });

      el.addEventListener("pointerleave", (event) => {
        if (reduceMotion()) {
          el.style.transform = "";
          return;
        }
        const rect = el.getBoundingClientRect();
        const exitX = event.clientX < rect.left ? -5 : event.clientX > rect.right ? 5 : 0;
        const exitY = event.clientY < rect.top ? -5 : event.clientY > rect.bottom ? 5 : 0;
        el.style.transform = "";
        el.animate([
          { transform: `translate(${exitX}px, ${exitY}px)` },
          { transform: "translate(0, 0)" },
        ], {
          duration: 320,
          easing: "cubic-bezier(0.16, 1, 0.3, 1)",
        });
      });
    });
  }

  function setFieldError(field, message) {
    field.setAttribute("aria-invalid", "true");
    const wrapper = field.closest(".am-field") || field.parentElement;
    if (!wrapper) return;
    const baseId = field.id || field.name || `field-${Math.random().toString(36).slice(2)}`;
    if (!field.id) field.id = baseId;
    const errorId = `${field.id}-error`;
    let error = document.getElementById(errorId);
    if (!error) {
      error = document.createElement("span");
      error.className = "am-field__error";
      error.id = errorId;
      wrapper.append(error);
    }
    error.textContent = message;
    const described = new Set((field.getAttribute("aria-describedby") || "").split(/\s+/).filter(Boolean));
    described.add(errorId);
    field.setAttribute("aria-describedby", Array.from(described).join(" "));
  }

  function clearFieldError(field) {
    field.removeAttribute("aria-invalid");
    const errorId = field.id ? `${field.id}-error` : null;
    if (errorId) document.getElementById(errorId)?.remove();
    const described = (field.getAttribute("aria-describedby") || "")
      .split(/\s+/)
      .filter((id) => id && id !== errorId);
    if (described.length) field.setAttribute("aria-describedby", described.join(" "));
    else field.removeAttribute("aria-describedby");
  }

  function passwordMessage(value) {
    const failures = [];
    if (value.length < 10) failures.push("10+ characters");
    if (!/[a-z]/.test(value)) failures.push("lowercase");
    if (!/[A-Z]/.test(value)) failures.push("uppercase");
    if (!/\d/.test(value)) failures.push("number");
    if (!/[^A-Za-z0-9]/.test(value)) failures.push("symbol");
    return failures.length ? `Add ${failures.join(", ")}.` : "";
  }

  function luhnValid(value) {
    const digits = value.replace(/\D/g, "");
    if (digits.length < 13 || digits.length > 19) return false;
    let sum = 0;
    let doubleDigit = false;
    for (let index = digits.length - 1; index >= 0; index -= 1) {
      let digit = Number(digits[index]);
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleDigit = !doubleDigit;
    }
    return sum % 10 === 0;
  }

  function expiryValid(value, now = new Date()) {
    const match = value.match(/^(\d{2})\/(\d{2})$/);
    if (!match) return false;
    const month = Number(match[1]);
    const year = 2000 + Number(match[2]);
    if (month < 1 || month > 12) return false;
    const expiryEnd = new Date(year, month, 0, 23, 59, 59, 999);
    return expiryEnd >= new Date(now.getFullYear(), now.getMonth(), 1);
  }

  function validateForm(form) {
    let valid = true;
    qsa(form, "input, textarea, select").forEach((field) => {
      clearFieldError(field);
      if (field.disabled || field.type === "hidden" || field.type === "button") return;
      if (!field.checkValidity()) {
        valid = false;
        let message = field.validationMessage || "Check this field.";
        if (field.type === "email") message = "Use a valid email address.";
        if (field.validity.valueMissing) message = "This field is required.";
        if (field.validity.tooShort) message = `Use at least ${field.minLength} characters.`;
        if (field.validity.patternMismatch) message = field.dataset.patternMessage || "Use the requested format.";
        setFieldError(field, message);
      }

      if (hasHook(field, "password")) {
        const message = passwordMessage(field.value);
        const rules = field.closest(".am-field")?.querySelector(hookSelector("password-rules"));
        if (rules) {
          rules.textContent = message || "Password meets every rule.";
          rules.dataset.state = message ? "error" : "success";
        }
        if (message) {
          valid = false;
          setFieldError(field, message);
        }
      }

      const passwordConfirm = hookValue(field, "password-confirm");
      if (passwordConfirm) {
        const source = document.getElementById(passwordConfirm);
        if (source && field.value !== source.value) {
          valid = false;
          setFieldError(field, "Passwords must match.");
        }
      }

      if (hasHook(field, "card-number") && field.value.trim() && !luhnValid(field.value)) {
        valid = false;
        setFieldError(field, "Use a valid card number.");
      }

      if (hasHook(field, "card-expiry") && field.value.trim() && !expiryValid(field.value)) {
        valid = false;
        setFieldError(field, "Use a future expiry in MM/YY.");
      }
    });
    return valid;
  }

  function initForms(root = document) {
    qsa(root, `${elementHookSelector("form", "validate")}, form.am-form`).forEach((form) => {
      if (form.dataset.amberBoundValidation === "true") return;
      form.dataset.amberBoundValidation = "true";
      const status = form.querySelector(`${hookSelector("form-status")}, .am-form__status, .am-form-status`);

      qsa(form, "input, textarea, select").forEach((field) => {
        field.addEventListener("input", () => {
          clearFieldError(field);
          if (hasHook(field, "password")) {
            const rules = field.closest(".am-field")?.querySelector(hookSelector("password-rules"));
            const message = passwordMessage(field.value);
            if (rules) {
              rules.textContent = message || "Password meets every rule.";
              rules.dataset.state = message ? "error" : "success";
            }
          }
          const passwordConfirm = hookValue(field, "password-confirm");
          if (passwordConfirm) {
            const source = document.getElementById(passwordConfirm);
            if (source && field.value && field.value !== source.value) setFieldError(field, "Passwords must match.");
          }
        });
      });

      form.addEventListener("submit", (event) => {
        event.preventDefault();
        const valid = validateForm(form);
        if (status) {
          status.dataset.state = valid ? "success" : "error";
          status.textContent = valid
            ? "Preview submitted successfully. No network request was made."
            : "Resolve the highlighted fields before continuing.";
        }
      });
    });
  }

  function initPaymentFormatting(root = document) {
    qsaHook(root, "card-number").forEach((field) => {
      if (field.dataset.amberBoundCardNumber === "true") return;
      field.dataset.amberBoundCardNumber = "true";
      field.addEventListener("input", () => {
        field.value = field.value.replace(/\D/g, "").slice(0, 16).replace(/(\d{4})(?=\d)/g, "$1 ");
      });
    });
    qsaHook(root, "card-expiry").forEach((field) => {
      if (field.dataset.amberBoundCardExpiry === "true") return;
      field.dataset.amberBoundCardExpiry = "true";
      field.dataset.patternMessage = "Use MM/YY.";
      field.addEventListener("input", () => {
        const digits = field.value.replace(/\D/g, "").slice(0, 4);
        field.value = digits.length > 2 ? `${digits.slice(0, 2)}/${digits.slice(2)}` : digits;
      });
    });
    qsaHook(root, "card-cvc").forEach((field) => {
      if (field.dataset.amberBoundCardCvc === "true") return;
      field.dataset.amberBoundCardCvc = "true";
      field.addEventListener("input", () => {
        field.value = field.value.replace(/\D/g, "").slice(0, 4);
      });
    });
    qsaHook(root, "promo-code").forEach((field) => {
      if (field.dataset.amberBoundPromoCode === "true") return;
      field.dataset.amberBoundPromoCode = "true";
      const status = field.closest(".am-field")?.querySelector(hookSelector("promo-status"));
      field.addEventListener("input", () => {
        const value = field.value.trim().toUpperCase();
        if (!status) return;
        if (!value) status.textContent = "Optional. Try AP10.";
        else if (value === "AP10") status.textContent = "Promo accepted: 10% preview discount.";
        else status.textContent = "Promo not recognized in this demo.";
      });
    });
  }

  function initToasts(root = document) {
    qsaHook(root, "toast-dismiss").forEach((button) => {
      if (button.dataset.amberBoundToastDismiss === "true") return;
      button.dataset.amberBoundToastDismiss = "true";
      button.addEventListener("click", () => {
        const toast = button.closest('[data-component="toast"], .am-toast');
        if (toast) toast.hidden = true;
      });
    });
  }

  function initPricing(root = document) {
    qsaHook(root, "pricing").forEach((summary) => {
      if (summary.dataset.amberBoundPricing === "true") return;
      summary.dataset.amberBoundPricing = "true";
      const compatibility = summary.hasAttribute(`${AMBER_PREFIX}pricing`);
      const configured = summary.hasAttribute(`${AP_PREFIX}pricing-seat-price`);
      if (!compatibility && !configured) return;
      const seats = qsHook(summary, "pricing-seats");
      const seatLabel = qsHook(summary, "pricing-seats-label");
      const total = qsHook(summary, "pricing-total");
      const note = qsHook(summary, "pricing-note");
      const billingButtons = qsa(document, descendantHookSelector("billing-toggle", "[data-billing]"));
      const addons = qsaHook(summary, "pricing-addon");
      const readNumber = (value, fallback) => {
        const parsed = Number.parseFloat(value || "");
        return Number.isFinite(parsed) ? parsed : fallback;
      };
      const seatPrice = readNumber(hookValue(summary, "pricing-seat-price"), compatibility ? 99 : 0);
      const annualFactor = readNumber(hookValue(summary, "pricing-annual-factor"), compatibility ? 0.82 : 1);
      const currency = hookValue(summary, "pricing-currency") || "$";
      const period = hookValue(summary, "pricing-period") ?? (compatibility ? "/mo" : "");
      const annualNote = hookValue(summary, "pricing-annual-note") || (compatibility ? "Annual billing saves 18%." : note?.textContent || "");
      const monthlyNote = hookValue(summary, "pricing-monthly-note") || (compatibility ? "Monthly billing keeps the plan flexible." : note?.textContent || "");
      let billing = hookValue(summary, "pricing-billing") || (compatibility ? "annual" : "monthly");

      if (total) {
        if (!total.hasAttribute("aria-live")) total.setAttribute("aria-live", "polite");
        if (!total.hasAttribute("aria-atomic")) total.setAttribute("aria-atomic", "true");
      }

      const render = () => {
        const seatCount = Number.parseInt(seats?.value || "12", 10);
        const addonsTotal = addons.reduce((sum, item) => sum + (item.checked ? Number(item.value || 0) : 0), 0);
        const monthly = seatCount * seatPrice + addonsTotal;
        const discounted = billing === "annual" ? Math.round(monthly * annualFactor) : monthly;
        if (seatLabel) seatLabel.textContent = String(seatCount);
        if (total) total.textContent = `${currency}${discounted.toLocaleString()}${period}`;
        if (note) note.textContent = billing === "annual" ? annualNote : monthlyNote;
        billingButtons.forEach((button) => {
          button.setAttribute("aria-pressed", String(button.dataset.billing === billing));
        });
      };

      seats?.addEventListener("input", render);
      addons.forEach((addon) => addon.addEventListener("change", render));
      billingButtons.forEach((button) => {
        button.addEventListener("click", () => {
          billing = button.dataset.billing || "annual";
          render();
        });
      });
      render();
    });
  }

  const searchItems = [
    { title: "Pricing payment form", detail: "Semantic card fields and promo feedback." },
    { title: "Crystal timeline", detail: "Scroll-reveal milestones and ambient SVG." },
    { title: "Command palette", detail: "Dialog-style quick actions with focus return." },
    { title: "Dashboard table", detail: "Row state indicators and live filtering." },
    { title: "Password confirmation", detail: "Matching validation and live password rules." },
    { title: "Theme editor", detail: "Light and dark token switching." },
  ];

  function initLiveSearch(root = document) {
    qsa(root, `${hookSelector("live-search")}, .am-live-search input`).forEach((input) => {
      if (input.dataset.amberBoundLiveSearch === "true") return;
      input.dataset.amberBoundLiveSearch = "true";
      const container = input.closest(".am-panel, .am-live-search, section") || document;
      const results = container.querySelector(`${hookSelector("search-results")}, .am-live-search__results`);
      if (!results) return;
      if (!results.id) results.id = `${input.id || "ap-search"}-results`;
      input.setAttribute("aria-controls", results.id);

      const render = () => {
        const query = input.value.trim().toLowerCase();
        const matches = query
          ? searchItems.filter((item) => `${item.title} ${item.detail}`.toLowerCase().includes(query))
          : searchItems.slice(0, 4);
        results.replaceChildren();
        if (matches.length === 0) {
          const empty = document.createElement("div");
          empty.className = "am-search-result";
          empty.textContent = "No matching records.";
          results.append(empty);
          return;
        }
        matches.forEach((match) => {
          const item = document.createElement("article");
          item.className = "am-search-result";
          const title = document.createElement("strong");
          title.textContent = match.title;
          const detail = document.createElement("span");
          detail.className = "am-demo-subtle";
          detail.textContent = match.detail;
          item.append(title, detail);
          results.append(item);
        });
      };

      input.addEventListener("input", render);
      render();
    });
  }

  function initChat(root = document) {
    qsa(root, `${hookSelector("chat-form")}, .am-chat form`).forEach((form) => {
      if (form.dataset.amberBoundChat === "true") return;
      form.dataset.amberBoundChat = "true";
      const input = form.querySelector("input[name='message']");
      const log = form.closest(".am-chat-panel, .am-chat")?.querySelector(`${hookSelector("chat-log")}, .am-chat__messages`);
      if (!input || !log) return;
      log.setAttribute("role", log.getAttribute("role") || "log");
      log.setAttribute("aria-live", log.getAttribute("aria-live") || "polite");

      form.addEventListener("submit", (event) => {
        event.preventDefault();
        const text = input.value.trim();
        if (!text) return;
        const message = document.createElement("article");
        message.className = log.classList.contains("am-chat__messages") ? "am-chat__message" : "am-message";
        message.dataset.own = "true";
        const author = document.createElement("strong");
        author.textContent = "You";
        const body = document.createElement("span");
        body.textContent = text;
        message.append(author, body);
        log.append(message);
        input.value = "";
        log.scrollTop = log.scrollHeight;
      });
    });
  }

  function commandItems(panel) {
    return qsa(panel, ".am-command-item").filter((item) => !item.hidden);
  }

  function setActiveCommand(panel, index) {
    const items = commandItems(panel);
    if (items.length === 0) return;
    const nextIndex = (index + items.length) % items.length;
    items.forEach((item, itemIndex) => {
      item.dataset.active = String(itemIndex === nextIndex);
    });
    items[nextIndex].focus();
  }

  function closeCommandPanel(panel = activeCommandPanel) {
    if (!panel) return;
    panel.dataset.state = "closed";
    activeCommandPanel = null;
    const returnFocus = commandReturnFocus;
    commandReturnFocus = null;
    if (returnFocus && document.contains(returnFocus)) returnFocus.focus();
  }

  function openCommandPanel(panel, trigger) {
    commandReturnFocus = trigger || document.activeElement;
    activeCommandPanel = panel;
    panel.dataset.state = "open";
    requestAnimationFrame(() => {
      const search = qsHook(panel, "command-search");
      (search || focusableWithin(panel)[0])?.focus();
    });
  }

  function commandPanelForTrigger(trigger) {
    const target = hookValue(trigger, "command-open");
    if (target) {
      const normalized = target.replace(/^#/, "");
      const byId = document.getElementById(normalized);
      if (byId?.matches?.(hookSelector("command-panel"))) return byId;
      try {
        const bySelector = document.querySelector(target);
        if (bySelector?.matches?.(hookSelector("command-panel"))) return bySelector;
      } catch {
      }
    }
    return document.querySelector(hookSelector("command-panel"));
  }

  function initCommandPalette(root = document) {
    qsaHook(root, "command-panel").forEach((panel) => {
      if (panel.dataset.amberBoundCommand === "true") return;
      panel.dataset.amberBoundCommand = "true";

      qsaHook(panel, "command-close").forEach((button) => button.addEventListener("click", () => closeCommandPanel(panel)));
      qsaHook(panel, "command-search").forEach((input) => {
        input.addEventListener("input", () => {
          const query = input.value.trim().toLowerCase();
          qsa(panel, ".am-command-item").forEach((item) => {
            item.hidden = query.length > 0 && !item.textContent.toLowerCase().includes(query);
            item.dataset.active = "false";
          });
        });
      });

      panel.addEventListener("keydown", (event) => {
        if (event.key === "Escape") {
          event.preventDefault();
          closeCommandPanel(panel);
          return;
        }

        if (event.key === "Tab") {
          const focusable = focusableWithin(panel);
          if (focusable.length === 0) return;
          const first = focusable[0];
          const last = focusable[focusable.length - 1];
          if (event.shiftKey && (document.activeElement === first || !panel.contains(document.activeElement))) {
            event.preventDefault();
            last.focus();
          } else if (!event.shiftKey && document.activeElement === last) {
            event.preventDefault();
            first.focus();
          }
          return;
        }

        const items = commandItems(panel);
        if (items.length === 0) return;
        const currentIndex = Math.max(0, items.indexOf(document.activeElement));
        if (event.key === "ArrowDown") {
          event.preventDefault();
          setActiveCommand(panel, currentIndex + 1);
        } else if (event.key === "ArrowUp") {
          event.preventDefault();
          setActiveCommand(panel, currentIndex - 1);
        } else if (event.key === "Home") {
          event.preventDefault();
          setActiveCommand(panel, 0);
        } else if (event.key === "End") {
          event.preventDefault();
          setActiveCommand(panel, items.length - 1);
        } else if (event.key === "Enter" && document.activeElement?.matches?.(hookSelector("command-search"))) {
          event.preventDefault();
          items.find((item) => !item.hidden)?.click();
        }
      });
    });

    qsaHook(root, "command-open").forEach((button) => {
      if (button.dataset.amberBoundCommandOpen === "true") return;
      button.dataset.amberBoundCommandOpen = "true";
      button.addEventListener("click", () => {
        const panel = commandPanelForTrigger(button);
        if (panel) openCommandPanel(panel, button);
      });
    });

    if (document.documentElement.dataset.amberBoundCommandKeys !== "true") {
      document.documentElement.dataset.amberBoundCommandKeys = "true";
      document.addEventListener("keydown", (event) => {
        if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
          event.preventDefault();
          const panel = document.querySelector(hookSelector("command-panel"));
          if (panel) openCommandPanel(panel, document.activeElement);
        }
        if (event.key === "Escape" && activeCommandPanel?.dataset.state === "open") closeCommandPanel(activeCommandPanel);
      });
    }
  }

  function initTabs(root = document) {
    qsaHook(root, "tabs").forEach((tabs) => {
      if (tabs.dataset.amberBoundTabs === "true") return;
      tabs.dataset.amberBoundTabs = "true";
      const tabButtons = qsa(tabs, "[role='tab']");
      const activate = (button) => {
        tabButtons.forEach((tab) => {
          const selected = tab === button;
          tab.setAttribute("aria-selected", String(selected));
          tab.tabIndex = selected ? 0 : -1;
          const panel = document.getElementById(tab.getAttribute("aria-controls"));
          if (panel) panel.hidden = !selected;
        });
      };
      tabButtons.forEach((button, index) => {
        button.addEventListener("click", () => activate(button));
        button.addEventListener("keydown", (event) => {
          let next = null;
          if (event.key === "ArrowRight") next = tabButtons[(index + 1) % tabButtons.length];
          else if (event.key === "ArrowLeft") next = tabButtons[(index - 1 + tabButtons.length) % tabButtons.length];
          else if (event.key === "Home") next = tabButtons[0];
          else if (event.key === "End") next = tabButtons[tabButtons.length - 1];
          if (!next) return;
          event.preventDefault();
          activate(next);
          next.focus();
        });
      });
    });
  }

  function initCarousel(root = document) {
    qsaHook(root, "carousel").forEach((carousel) => {
      if (carousel.dataset.amberBoundCarousel === "true") return;
      carousel.dataset.amberBoundCarousel = "true";
      const slides = qsa(carousel, ".am-carousel-slide");
      const status = qsHook(carousel, "carousel-status");
      let index = Math.max(0, slides.findIndex((slide) => slide.dataset.active === "true"));
      const render = () => {
        slides.forEach((slide, i) => {
          const active = i === index;
          slide.dataset.active = String(active);
          slide.setAttribute("aria-hidden", String(!active));
        });
        if (status) status.textContent = `Slide ${index + 1} of ${slides.length}`;
      };
      const go = (nextIndex) => {
        index = (nextIndex + slides.length) % slides.length;
        render();
      };
      qsHook(carousel, "carousel-prev")?.addEventListener("click", () => go(index - 1));
      qsHook(carousel, "carousel-next")?.addEventListener("click", () => go(index + 1));
      carousel.addEventListener("keydown", (event) => {
        if (event.key === "ArrowLeft") {
          event.preventDefault();
          go(index - 1);
        } else if (event.key === "ArrowRight") {
          event.preventDefault();
          go(index + 1);
        } else if (event.key === "Home") {
          event.preventDefault();
          go(0);
        } else if (event.key === "End") {
          event.preventDefault();
          go(slides.length - 1);
        }
      });
      render();
    });
  }

  function initTimelineReveal(root = document) {
    const items = qsaHook(root, "reveal").filter((item) => item.dataset.amberBoundReveal !== "true");
    if (items.length === 0) return;
    if (reduceMotion() || !("IntersectionObserver" in globalThis)) {
      items.forEach((item) => {
        item.dataset.amberBoundReveal = "true";
        item.dataset.visible = "true";
      });
      return;
    }
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.dataset.visible = "true";
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.18 });
    items.forEach((item) => {
      item.dataset.amberBoundReveal = "true";
      observer.observe(item);
    });
  }

  function animateSvgParts(root = document) {
    if (reduceMotion()) return;
    qsa(root, "[data-svg-part]").forEach((part, index) => {
      if (part.dataset.amberSequenced === "true") return;
      part.dataset.amberSequenced = "true";
      part.animate([
        { opacity: 0.4, transform: "translateY(4px)" },
        { opacity: 1, transform: "translateY(0)" },
      ], {
        delay: index * 80,
        duration: 520,
        easing: "cubic-bezier(0.16, 1, 0.3, 1)",
        fill: "both",
      });
    });
  }

  function init(root = document) {
    initThemeControls(root);
    initDisclosures(root);
    initDialogs(root);
    initRowFilters(root);
    initPricing(root);
    initPaymentFormatting(root);
    initForms(root);
    initToasts(root);
    initLiveSearch(root);
    initChat(root);
    initCommandPalette(root);
    initTabs(root);
    initCarousel(root);
    initTimelineReveal(root);
    initStickyHover(root);
    animateSvgParts(root);
  }

  const api = {
    init,
    setTheme,
    initThemeControls,
    initDisclosures,
    initDialogs,
    initRowFilters,
    initPricing,
    initForms,
    initToasts,
    initLiveSearch,
    initChat,
    initCommandPalette,
    initTabs,
    initCarousel,
    initTimelineReveal,
    initStickyHover,
    animateSvgParts,
    prefersReducedMotion: reduceMotion,
  };

  globalThis.AssetPipelineDesignSystem = api;
  globalThis.AmberDesignSystem = api;

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => init());
  } else {
    init();
  }
})();
