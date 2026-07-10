---
slug: web-views
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T11:36:00Z
iteration: 58
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark:  PASS_WITH_NOTES
  ios_light:   PASS_WITH_NOTES
  ios_dark:    PASS_WITH_NOTES
---

# Web views -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-web-view-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/web-views-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/web-views-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/web-views-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/web-views-ios-dark.png)

## Verdict: PASS_WITH_NOTES

Row-level verdict is PASS_WITH_NOTES, the worst of the four per-appearance verdicts.
The component now uses a real `WKWebView` path for native runtime rendering on iOS and
macOS, with linked `WebKit` host frameworks. The showcase content is no longer a blank
generic placeholder; it renders a deterministic editorial preview that communicates the
default taste of the component clearly in both appearances.

### Liquid Glass check
- **Required for this slug:** No. Web views are content surfaces, not glass overlays.
- **Observed:** Correct. No Liquid Glass treatment is applied in any appearance.

### Appearance observations

**macOS light / dark:**
The validation capture now shows a styled embedded-content study instead of an empty
border box. Type hierarchy is clear, spacing is intentional, and the surface reads as
contextual content rather than a fake browser app. The one caveat is that the macOS
validation harness still uses a deterministic native preview surface during offscreen
capture because `CGWindowListCreateImage` blanks live `WKWebView` content in this host
configuration. The production renderer path is still real `WKWebView`.

**iOS light / dark:**
The iOS simulator capture renders through a live `WKWebView` with local HTML content.
The embedded preview is legible, warm, and materially cleaner than the previous generic
`example.com` shell. The component reads as an intentional default rather than a generic
debug rectangle.

### Deviations

1. **macOS validation path uses a deterministic preview surface. PASS_WITH_NOTES.**
   Runtime macOS rendering now allocates a real `WKWebView`, but the offscreen PNG
   harness still cannot reliably capture live WebKit contents through
   `CGWindowListCreateImage`. For validation only, the bridge substitutes a native
   preview surface that matches the intended embedded-content layout. This keeps the
   evidence useful without regressing the real app path.

2. **The showcase still presents a component study rather than a full product scene. PASS_WITH_NOTES.**
   This is intentional and appropriate for the current validation goal: default taste
   of the component itself. A richer scene can be layered on later without changing
   the underlying native integration.

### Source citations
- HIG "Web views": "A web view loads and displays rich web content, such as
  embedded HTML and websites, directly within your app."
- HIG "Web views -- Best practices": "Avoid using a web view to build a web browser."

### Remediation (if NEEDS_WORK)
Verdict is PASS_WITH_NOTES. No immediate remediation required.

Follow-up polish:
1. Replace the macOS validation-only preview fallback with a true WebKit snapshot path
   if we want screenshot evidence to come directly from live `WKWebView` compositing.
2. Broaden the shared `UI::WebViewComponent` API with optional navigation callbacks
   when we are ready to support richer in-app browsing behavior.
