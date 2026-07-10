require "../../spec_helper"

describe "Design-system runtime hook aliases" do
  runtime = File.read("public/js/design-system.js")
  compatibility_runtime = File.read("public/js/amber-design-system.js")

  it "keeps the generic runtime file and compatibility runtime synchronized" do
    runtime.should eq(compatibility_runtime)
  end

  it "defines neutral data-ap hooks alongside current compatibility hooks" do
    runtime.should contain(%(const THEME_KEY = "ap-theme"))
    runtime.should contain(%(const LEGACY_THEME_KEY = "amber-theme"))
    runtime.should contain(%(const AMBER_PREFIX = "data-amber-"))
    runtime.should contain(%(const AP_PREFIX = "data-ap-"))
    runtime.should contain(%(const hookSelector = (hook) => `[${AMBER_PREFIX}${hook}], [${AP_PREFIX}${hook}]`))
    runtime.should contain(%(const hookValue = (el, hook) =>))
  end

  it "initializes every public behavior through the shared hook selector" do
    runtime.should contain(%(qsaHook(document, "theme-toggle")))
    runtime.should contain(%(qsaHook(document, "theme-set")))
    runtime.should contain(%(qsaHook(document, "theme-status")))
    runtime.should contain(%(qsaHook(root, "disclosure")))
    runtime.should contain(%(qsaHook(root, "dialog-open")))
    runtime.should contain(%(qsaHook(root, "dialog-close")))
    runtime.should contain(%(qsaHook(root, "filter")))
    runtime.should contain(%(qsaHook(root, "sticky-hover")))
    runtime.should contain(%(elementHookSelector("form", "validate")))
    runtime.should contain(%(qsaHook(root, "card-number")))
    runtime.should contain(%(qsaHook(root, "card-expiry")))
    runtime.should contain(%(qsaHook(root, "card-cvc")))
    runtime.should contain(%(qsaHook(root, "promo-code")))
    runtime.should contain(%(qsaHook(root, "pricing")))
    runtime.should contain(%(qsaHook(root, "toast-dismiss")))
    runtime.should contain(%(hookSelector("live-search")))
    runtime.should contain(%(hookSelector("chat-form")))
    runtime.should contain(%(qsaHook(root, "command-panel")))
    runtime.should contain(%(qsaHook(root, "command-open")))
    runtime.should contain(%(qsaHook(root, "tabs")))
    runtime.should contain(%(qsaHook(root, "carousel")))
    runtime.should contain(%(qsaHook(root, "reveal")))
  end

  it "lets non-empty neutral hook values override compatibility values only intentionally" do
    runtime.should contain(%(if (apValue !== null && apValue !== "") return apValue;))
    runtime.should contain(%(return el.getAttribute(`${AMBER_PREFIX}${hook}`);))
  end

  it "keeps public pricing behavior configurable while preserving demo compatibility fallbacks" do
    runtime.should contain(%(const configured = summary.hasAttribute(`${AP_PREFIX}pricing-seat-price`);))
    runtime.should contain(%(if (!compatibility && !configured) return;))
    runtime.should contain(%(const seatPrice = readNumber(hookValue(summary, "pricing-seat-price"), compatibility ? 99 : 0);))
    runtime.should contain(%(const annualFactor = readNumber(hookValue(summary, "pricing-annual-factor"), compatibility ? 0.82 : 1);))
    runtime.should contain(%(if (!total.hasAttribute("aria-live")) total.setAttribute("aria-live", "polite");))
    runtime.should contain(%(if (!total.hasAttribute("aria-atomic")) total.setAttribute("aria-atomic", "true");))
  end

  it "exports a neutral runtime global while preserving the compatibility global" do
    runtime.should contain(%(globalThis.AssetPipelineDesignSystem = api;))
    runtime.should contain(%(globalThis.AmberDesignSystem = api;))
    runtime.should contain(%(initToasts,))
  end
end
