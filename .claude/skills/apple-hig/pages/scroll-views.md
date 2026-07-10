---
title: "Scroll views"
slug: "scroll-views"
source_url: "https://developer.apple.com/design/human-interface-guidelines/scroll-views"
role: "article"
abstract: "A scroll view lets people view content that’s larger than the view’s boundaries by moving the content vertically or horizontally."
platforms_mentioned: [iOS, iPadOS, macOS]
related: []
---

# Scroll views

A scroll view lets people view content that’s larger than the view’s boundaries by moving the content vertically or horizontally.

![A stylized representation of a scrollable image view. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](../images/components-scroll-view-intro.png)

The scroll view itself has no appearance, but it can display a translucent *scroll indicator* that typically appears after people begin scrolling the view’s content. Although the appearance and behavior of scroll indicators can vary per platform, all indicators provide visual feedback about the scrolling action. For example, in iOS, iPadOS, macOS, visionOS, and watchOS, the indicator shows whether the currently visible content is near the beginning, middle, or end of the view.

## Best practices

**Support default scrolling gestures and keyboard shortcuts.** People are accustomed to the systemwide scrolling behavior and expect it to work everywhere. If you build custom scrolling for a view, make sure your scroll indicators use the elastic behavior that people expect.

**Make it apparent when content is scrollable.** Because scroll indicators aren’t always visible, it can be helpful to make it obvious when content extends beyond the view. For example, displaying partial content at the edge of a view indicates that there’s more content in that direction. Although most people immediately try scrolling a view to discover if additional content is available, it’s considerate to draw their attention to it.

**Avoid putting a scroll view inside another scroll view with the same orientation.** Nesting scroll views that have the same orientation can create an unpredictable interface that’s difficult to control. It’s alright to place a horizontal scroll view inside a vertical scroll view (or vice versa), however.

**Consider supporting page-by-page scrolling if it makes sense for your content.** In some situations, people appreciate scrolling by a fixed amount of content per interaction instead of scrolling continuously. On most platforms, you can define the size of such a *page* — typically the current height or width of the view — and define an interaction that scrolls one page at a time. To help maintain context during page-by-page scrolling, you can define a unit of overlap, such as a line of text, a row of glyphs, or part of a picture, and subtract the unit from the page size. For developer guidance, see [PagingScrollTargetBehavior](https://developer.apple.com/documentation/SwiftUI/PagingScrollTargetBehavior).

**In some cases, scroll automatically to help people find their place.** Although people initiate almost all scrolling, automatic scrolling can be helpful when relevant content is no longer in view, such as when:

- Your app performs an operation that selects content or places the insertion point in an area that’s currently hidden. For example, when your app locates text that people are searching for, scroll the content to bring the new selection into view.
- People start entering information in a location that’s not currently visible. For example, if the insertion point is on one page and people navigate to another page, scroll back to the insertion point as soon as they begin to enter text.
- The pointer moves past the edge of the view while people are making a selection. In this case, follow the pointer by scrolling in the direction it moves.
- People select something and scroll to a new location before acting on the selection. In this case, scroll until the selection is in view before performing the operation.

In all cases, automatically scroll the content only as much as necessary to help people retain context. For example, if part of a selection is visible, you don’t need to scroll the entire selection into view.

**If you support zoom, set appropriate maximum and minimum scale values.** For example, zooming in on text until a single character fills the screen doesn’t make sense in most situations.

## Scroll edge effects

In iOS, iPadOS, and macOS, a *scroll edge effect* is a variable blur that provides a transition between a content area and an area with [Liquid Glass](./materials.md) controls, such as [Toolbars](./toolbars.md). In most cases, the system applies a scroll edge effect automatically when a pinned element overlaps with scrolling content. If you use custom controls or layouts, the effect might not appear, and you may need to add it manually. For developer guidance, see [ScrollEdgeEffectStyle](https://developer.apple.com/documentation/SwiftUI/ScrollEdgeEffectStyle) and [UIScrollEdgeEffect](https://developer.apple.com/documentation/UIKit/UIScrollEdgeEffect).

There are two styles of scroll edge effect: soft and hard.

- Use a [soft](https://developer.apple.com/documentation/SwiftUI/ScrollEdgeEffectStyle/soft) edge effect in most cases, especially in iOS and iPadOS, to provide a subtle transition that works well for toolbars and interactive elements like buttons.
- Use a [hard](https://developer.apple.com/documentation/SwiftUI/ScrollEdgeEffectStyle/hard) edge effect primarily in macOS for a stronger, more opaque boundary that’s ideal for interactive text, backless controls, or pinned table headers that need extra clarity.

**Only use a scroll edge effect when a scroll view is adjacent to floating interface elements.** Scroll edge effects aren’t decorative. They don’t block or darken like overlays; they exist to clarify where controls and content meet.

**Apply one scroll edge effect per view.** In split view layouts on iPad and Mac, each pane can have its own scroll edge effect; in this case, keep them consistent in height to maintain alignment.

## Platform considerations

### iOS, iPadOS

**Consider showing a page control when a scroll view is in page-by-page mode.** [Page controls](./page-controls.md) show how many pages, screens, or other chunks of content are available and indicates which one is currently visible. For example, Weather uses a page control to indicate movement between people’s saved locations. If you show a page control with a scroll view, don’t show the scrolling indicator on the same axis to avoid confusing people with redundant controls.

### macOS

In macOS, a *scroll indicator* is commonly called a *scroll bar*.

**If necessary, use small or mini scroll bars in a panel.** When space is tight, you can use smaller scroll bars in panels that need to coexist with other windows. Be sure to use the same size for all controls in such a panel.

## Resources

#### Related

[Page controls](./page-controls.md)

[Gestures](./gestures.md)

[Pointing devices](./pointing-devices.md)

#### Developer documentation

[ScrollView](https://developer.apple.com/documentation/SwiftUI/ScrollView) — SwiftUI

[UIScrollView](https://developer.apple.com/documentation/UIKit/UIScrollView) — UIKit

[NSScrollView](https://developer.apple.com/documentation/AppKit/NSScrollView) — AppKit

[WKPageOrientation](https://developer.apple.com/documentation/WatchKit/WKPageOrientation) — WatchKit

[look](https://developer.apple.com/documentation/SwiftUI/ScrollInputKind/look) — SwiftUI

## Change log

| Date | Changes |
| --- | --- |
| March 24, 2026 | Added guidance for Look to Scroll in visionOS. |
| July 28, 2025 | Added guidance for scroll edge effects. |
| February 2, 2024 | Added artwork showing the behavior of the visionOS scroll indicator. |
| December 5, 2023 | Described the visionOS scroll indicator and added guidance for integrating it with window layout. |
| June 5, 2023 | Updated guidance for using scroll views in watchOS. |
