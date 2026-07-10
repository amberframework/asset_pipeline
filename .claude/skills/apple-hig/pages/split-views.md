---
title: "Split views"
slug: "split-views"
source_url: "https://developer.apple.com/design/human-interface-guidelines/split-views"
role: "article"
abstract: "A split view manages the presentation of multiple adjacent panes of content, each of which can contain a variety of components, including tables, collections, images, and custom views."
platforms_mentioned: [iOS, iPadOS, macOS]
related: []
---

# Split views

A split view manages the presentation of multiple adjacent panes of content, each of which can contain a variety of components, including tables, collections, images, and custom views.

![A stylized representation of a window consisting of three areas: a sidebar, a canvas, and an inspector. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](../images/components-split-view-intro.png)

Typically, you use a split view to show multiple levels of your app’s hierarchy at once and support navigation between them. In this scenario, selecting an item in the view’s primary pane displays the item’s contents in the secondary pane. Similarly, a split view can display a tertiary pane if items in the secondary pane contain additional content.

It’s common to use a split view to display a [Sidebars](./sidebars.md) for navigation, where the leading pane lists the top-level items or collections in an app, and the secondary and optional tertiary panes can present child collections and item details. Rarely, you might also use a split view to provide groups of functionality that supplement the primary view — for example, Keynote in macOS uses split view panes to present the slide navigator, the presenter notes, and the inspector pane in areas that surround the main slide canvas.

## Best practices

**To support navigation, persistently highlight the current selection in each pane that leads to the detail view.** The selected appearance clarifies the relationship between the content in various panes and helps people stay oriented.

**Consider letting people drag and drop content between panes.** Because a split view provides access to multiple levels of hierarchy, people can conveniently move content from one part of your app to another by dragging items to different panes. For guidance, see [Drag and drop](./drag-and-drop.md).

## Platform considerations

### iOS

**Prefer using a split view in a regular — not a compact — environment.** A split view needs horizontal space in which to display multiple panes. In a compact environment, such as iPhone in portrait orientation, it’s difficult to display multiple panes without wrapping or truncating the content, making it less legible and harder to interact with.

### iPadOS

In iPadOS, a split view can include either two vertical panes, like Mail, or three vertical panes, like Keynote.

**Account for narrow, compact, and intermediate window widths.** Since iPad windows are fluidly resizable, it’s important to consider the design of a split view layout at multiple widths. In particular, ensure that it’s possible to navigate between the various panes in a logical way. For guidance, see [Layout](./layout.md). For developer guidance, see [NavigationSplitView](https://developer.apple.com/documentation/SwiftUI/NavigationSplitView) and [UISplitViewController](https://developer.apple.com/documentation/UIKit/UISplitViewController).

### macOS

In macOS, you can arrange the panes of a split view vertically, horizontally, or both. A split view includes dividers between panes that can support dragging to resize them. For developer guidance, see [VSplitView](https://developer.apple.com/documentation/SwiftUI/VSplitView) and [HSplitView](https://developer.apple.com/documentation/SwiftUI/HSplitView).

**Set reasonable defaults for minimum and maximum pane sizes.** If people can resize the panes in your app’s split view, make sure to use sizes that keep the divider visible. If a pane gets too small, the divider can seem to disappear, becoming difficult to use.

**Consider letting people hide a pane when it makes sense.** If your app includes an editing area, for example, consider letting people hide other panes to reduce distractions or allow more room for editing — in Keynote, people can hide the navigator and presenter notes panes when they want to edit slide content.

**Provide multiple ways to reveal hidden panes.** For example, you might provide a toolbar button or a menu command — including a keyboard shortcut — that people can use to restore a hidden pane.

**Prefer the thin divider style.** The thin divider measures one point in width, giving you maximum space for content while remaining easy for people to use. Avoid using thicker divider styles unless you have a specific need. For example, if both sides of a divider present table rows that use strong linear elements that might make a thin divider hard to distinguish, it might work to use a thicker divider. For developer guidance, see [NSSplitView.DividerStyle](https://developer.apple.com/documentation/AppKit/NSSplitView/DividerStyle-swift.enum).

## Resources

#### Related

[Sidebars](./sidebars.md)

[Tab bars](./tab-bars.md)

[Layout](./layout.md)

#### Developer documentation

[NavigationSplitView](https://developer.apple.com/documentation/SwiftUI/NavigationSplitView) — SwiftUI

[UISplitViewController](https://developer.apple.com/documentation/UIKit/UISplitViewController) — UIKit

[NSSplitViewController](https://developer.apple.com/documentation/AppKit/NSSplitViewController) — AppKit

#### Videos

- [Make your UIKit app more flexible](https://developer.apple.com/videos/play/wwdc2025/282)

## Change log

| Date | Changes |
| --- | --- |
| June 9, 2025 | Added iOS and iPadOS platform considerations. |
| December 5, 2023 | Added guidance for split views in visionOS. |
| June 5, 2023 | Added guidance for split views in watchOS. |
