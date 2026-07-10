---
slug: web-views
ui_view: UI::WebViewComponent
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/web-views.md
validation_report: ../validation/reports/web-views.md
---

# UI::WebViewComponent

> An inline browser surface that loads and displays rich web content -- HTML or a
> remote URL -- directly within an app window using WKWebView (WebKit); no Liquid
> Glass material is applied because the surface renders HTML content, not an app-native
> overlay.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Reach for `UI::WebViewComponent` when your app needs to display content that lives on
the web or is authored in HTML -- a help center article, a terms-of-service page, a
rich-text email body, or a product detail page fetched from a CMS. The component
embeds a full WebKit rendering engine in a native view, giving users familiar web
scrolling and link behavior without leaving your app's chrome.

It is NOT for building a general-purpose web browser. The HIG is explicit: "Attempting
to replicate the functionality of Safari in your app is unnecessary and discouraged."
Use it for bounded, contextual web content that supplements your app's native UI, not
as a primary navigation surface.

(HIG: "Avoid using a web view to build a web browser. Using a web view to let people
briefly access a website without leaving the context of your app is fine, but Safari
is the primary way people browse the web." -- Web views / Best practices.)

## Quickstart

```crystal
# Embed a help page URL inside an app detail view.
wv = UI::WebViewComponent.new(url: "https://example.com/help")
wv.title = "Help Center"
wv.allows_navigation = true
wv.on_navigation_request = ->(url : String) { url.starts_with?("https://example.com/") }
wv.on_navigation_finish = ->(url : String) { puts "Loaded #{url}" }
wv.accessibility_label = "Help Center web view"
```

Renders: on macOS and iOS, a native `WKWebView` surface backed by WebKit. In
validation captures on macOS, the runtime view swaps to a capture-only preview
surface because `CGWindowListCreateImage` drops live WebKit pixels from the
offscreen host path. No Liquid Glass material is applied; WKWebView renders
standard HTML content with a white/system background that tracks the page's own
CSS color scheme.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `url` | `String` | `""` | The URL string to load; passed to `WKWebView.load(URLRequest(...))` in production. |
| `title` | `String?` | `nil` | Optional title string stored as `accessibilityLabel` on the native view; useful for screen readers and validation. |
| `allows_navigation` | `Bool` | `true` | Whether forward and back navigation are permitted; set to false for bounded single-page content per HIG guidance. |
| `allows_scripts` | `Bool` | `true` | Whether JavaScript execution is enabled; disable for static content that does not require scripting. |
| `accessibility_label` | `String?` | `nil` | Accessibility label inherited from `UI::View`; mandatory for interactive elements per HIG. |
| `on_navigation_request` | `Proc(String, Bool)?` | `nil` | Synchronous policy hook. Receives the requested URL and returns `true` to allow or `false` to block navigation. |
| `on_navigation_start` | `Proc(String, Nil)?` | `nil` | Fires when a main-frame navigation starts loading. |
| `on_navigation_finish` | `Proc(String, Nil)?` | `nil` | Fires when a main-frame navigation finishes loading. |

**Theming**: `UI::WebViewComponent` does not consume `UI::Theme` color tokens directly.
The rendered web content applies its own CSS color scheme. The surrounding host labels
("Embedded web content", description) in the showcase arm use `Theme.apple_default`
label colors via NSColor.labelColor / UIColor.labelColor. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

`UI::WebViewComponent` is a content view, not a system surface, so its background is
determined by the web page's own CSS rather than a platform material.

**macOS light**: Runtime uses a live `WKWebView`, so the page background follows the
HTML/CSS being rendered. In the validation host the capture-only preview keeps the same
warm neutral palette and rounded frame so the screenshots still judge spacing, hierarchy,
and restraint instead of WebKit capture bugs.

**macOS dark**: Runtime still uses live `WKWebView`; pages that implement
`prefers-color-scheme` adapt automatically. The validation preview mirrors that dark
appearance with the same restrained border and contrast hierarchy so design critique
stays meaningful.

**iOS light**: Live `WKWebView` content sits inside the rounded host frame. Labels use
`UIColor.labelColor` (near-black in light, ~21:1 contrast).

**iOS dark**: The native web view honors `prefers-color-scheme: dark` for pages that
declare dark-mode CSS variables. Labels use `UIColor.labelColor` dark variant
(near-white).

No SF Symbols are used by this component. No Liquid Glass material is used; WKWebView
surfaces are plain content areas. No contrast caveats specific to the view itself
(contrast is the responsibility of the embedded HTML/CSS).

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Inject brand CSS into the web content.**
```crystal
# Load HTML with brand typography and color scheme already embedded.
# The WebViewComponent renders whatever the HTML declares.
wv = UI::WebViewComponent.new(url: "")
wv.title = "Brand content"
# In production, pass HTML via loadHTMLString:baseURL: from Swift/ObjC:
# webView.loadHTMLString("<html><body style='font-family: BrandFont; color: #1A2B3C;'>...</body></html>", baseURL: nil)
```
Note: CSS injection is the recommended brand override path for WKWebView content.
The Crystal view model controls the container; the content styling belongs to the HTML.

**Disable navigation for bounded single-page content.**
```crystal
# For terms-of-service or static help content that should not navigate away.
wv = UI::WebViewComponent.new(url: "https://example.com/terms")
wv.allows_navigation = false   # Disables WKNavigationDelegate forward/back
wv.allows_scripts = false      # Disables JavaScript for static content
wv.accessibility_label = "Terms of Service"
```
HIG guidance: "If people are likely to use your web view to visit multiple pages,
allow forward and back navigation, and provide corresponding controls." Setting
`allows_navigation = false` is appropriate only for single bounded pages.

**Provide a custom accessibility label for VoiceOver.**
```crystal
# VoiceOver reads the accessibilityLabel. Always set it when the URL alone
# is not meaningful to a screen reader user.
wv = UI::WebViewComponent.new(url: "https://cdn.example.com/content/12345.html")
wv.title = "Product description"
wv.accessibility_label = "Product description web view"
```
Hit target note: `UI::WebViewComponent` fills its parent container; no minimum
hit target constraint applies (it is a scroll surface, not a button).

**Gate navigation so the web view stays inside your app's trust boundary.**
```crystal
wv = UI::WebViewComponent.new(url: "https://example.com/help")
wv.on_navigation_request = ->(url : String) do
  url.starts_with?("https://example.com/")
end
wv.on_navigation_finish = ->(url : String) do
  puts "Loaded #{url}"
end
```
This is the HIG-friendly version of "support forward and back navigation when
appropriate": allow the pages that belong in your flow, and politely refuse the
ones that would turn the component into a browser.

## Feel recipes
Short examples that map design intent to code.

**"I want to show a contextual help article inside my app without a modal sheet."**
Place the `UI::WebViewComponent` directly in a `UI::VStack` or `UI::ScrollView` as
a peer to native views. Set `allows_navigation = true` so the user can follow links
within the help system. Set `accessibility_label` to describe the help topic.

**"I want to embed a rich-text email message body (HIG: Mail uses web views for HTML)."**
Set `url = ""` and in production call `loadHTMLString:baseURL:` with the message HTML.
Set `allows_navigation = false` (the user should not navigate away from the email).
Set `allows_scripts = false` (email HTML should not run JavaScript).

## What happens on each platform
- **iOS 26**: Live `WKWebView` with navigation delegate hooks for policy / start /
  finish events. Loads via `loadRequest:` or `loadHTMLString:baseURL:` and honors
  `prefers-color-scheme` automatically.
- **iPadOS 26**: Same as iOS 26. On iPadOS, WKWebView benefits from the larger screen
  with no additional Crystal changes required.
- **macOS 26**: Live `WKWebView` in runtime apps, plus navigation delegate hooks
  matching iOS. Validation captures use a deterministic AppKit preview surface
  because the offscreen `CGWindowListCreateImage` path still drops live WebKit
  pixels.

## HIG citations (validated)
- Web views: "A web view loads and displays rich web content, such as embedded HTML
  and websites, directly within your app."
- Web views -- Best practices: "Support forward and back navigation when appropriate.
  Web views support forward and back navigation, but this behavior isn't available by
  default."
- Web views -- Best practices: "Avoid using a web view to build a web browser. Using
  a web view to let people briefly access a website without leaving the context of
  your app is fine, but Safari is the primary way people browse the web."
- Web views -- Platform considerations: "No additional considerations for iOS, iPadOS,
  macOS, or visionOS. Not supported in tvOS or watchOS."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/web-views.md](../validation/reports/web-views.md)

## Related
- `UI::ScrollView` -- when you need a native scrollable content area (not HTML)
- `UI::Sheet` -- when the web content should appear in a modal overlay presentation
- `recipes/help-center.md` -- multi-component pattern combining NavigationStack
  with WebViewComponent for an in-app help center
