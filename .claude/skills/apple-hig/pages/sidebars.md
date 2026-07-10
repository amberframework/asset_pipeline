---
title: "Sidebars"
slug: "sidebars"
source_url: "https://developer.apple.com/design/human-interface-guidelines/sidebars"
role: "article"
abstract: "A sidebar appears on the leading side of a view and lets people navigate between sections in your app or game."
platforms_mentioned: [iOS, iPadOS, macOS]
related: []
---

# Sidebars

A sidebar appears on the leading side of a view and lets people navigate between sections in your app or game.

![A stylized representation of the top portion of a window's sidebar displaying a title, a section, and some folders. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](../images/components-sidebar-intro.png)

A sidebar floats above content without being anchored to the edges of the view. It provides a broad, flat view of an app’s information hierarchy, giving people access to several peer content areas or modes at the same time.

A sidebar requires a large amount of vertical and horizontal space. When space is limited or you want to devote more of the screen to other information or functionality, a more compact control such as a [Tab bars](./tab-bars.md) may provide a better navigation experience. For guidance, see [Layout](./layout.md).

## Best practices

**Extend content beneath the sidebar.** In iOS, iPadOS, and macOS, as with other controls such as toolbars and tab bars, sidebars float above content in the [Liquid Glass](./materials.md) layer. To reinforce the separation and floating appearance of the sidebar, extend content beneath it either by letting it horizontally scroll or applying a background extension view, which mirrors adjacent content to give the impression of stretching it under the sidebar. For developer guidance, see [backgroundExtensionEffect()](https://developer.apple.com/documentation/SwiftUI/View/backgroundExtensionEffect()).

![A screenshot of the leading side of an app on iPad. An image spans the upper part of the window, stopping at the edge of the sidebar.](../images/sidebars-extend-content-beneath-sidebar-incorrect.png)

![An X in a circle to indicate incorrect usage.](../images/crossout.png)

![A screenshot of the leading side of an app on iPad. An image spans the upper part of the window, and uses a background extension effect to flip, blur, and extend the image beneath the sidebar to the edge of the window.](../images/sidebars-extend-content-beneath-sidebar-correct.png)

![A checkmark in a circle to indicate correct usage.](../images/checkmark.png)

**When possible, let people customize the contents of a sidebar.** A sidebar lets people navigate to important areas in your app, so it works well when people can decide which areas are most important and in what order they appear.

**Group hierarchy with disclosure controls if your app has a lot of content.** Using [Disclosure controls](./disclosure-controls.md) helps keep the sidebar’s vertical space to a manageable level.

**Consider using familiar symbols to represent items in the sidebar.** [SF Symbols](./sf-symbols.md) provides a wide range of customizable symbols you can use to represent items in your app. If you need to use a custom icon, consider creating a [Custom symbols](./sf-symbols.md) rather than using a bitmap image. Download the SF Symbols app from [Apple Design Resources](https://developer.apple.com/design/resources/#sf-symbols).

**Consider letting people hide the sidebar.** People sometimes want to hide the sidebar to create more room for content details or to reduce distraction. When possible, let people hide and show the sidebar using the platform-specific interactions they already know. For example, in iPadOS, people expect to use the built-in edge swipe gesture; in macOS, you can include a show/hide button or add Show Sidebar and Hide Sidebar commands to your app’s View menu. In visionOS, a window typically expands to accommodate a sidebar, so people rarely need to hide it. Avoid hiding the sidebar by default to ensure that it remains discoverable.

**In general, show no more than two levels of hierarchy in a sidebar.** When a data hierarchy is deeper than two levels, consider using a split view interface that includes a content list between the sidebar items and detail view.

**If you need to include two levels of hierarchy in a sidebar, use succinct, descriptive labels to title each group.** To help keep labels short, omit unnecessary words.

## Platform considerations

*No additional considerations for tvOS. Not supported in watchOS.*

### iOS

**Avoid using a sidebar.** A sidebar takes up a lot of space in landscape orientation and isn’t available in portrait orientation. Instead, consider using a [Tab bars](./tab-bars.md), which takes less space and remains visible in both orientations.

### iPadOS

When you use the [sidebarAdaptable](https://developer.apple.com/documentation/SwiftUI/TabViewStyle/sidebarAdaptable) style of tab view to present a sidebar, you choose whether to display a sidebar or a tab bar when your app opens. Both variations include a button that people can use to switch between them. This style also responds automatically to rotation and window resizing, providing a version of the control that’s appropriate to the width of the view.

> **Note:**
> To display a sidebar only, use [NavigationSplitView](https://developer.apple.com/documentation/SwiftUI/NavigationSplitView) to present a sidebar in the primary pane of a split view, or use [UISplitViewController](https://developer.apple.com/documentation/UIKit/UISplitViewController).

**Consider using a tab bar first.** A tab bar provides more space to feature content, and offers enough flexibility to navigate between many apps’ main areas. If you need to expose more areas than fit in a tab bar, the tab bar’s convertible sidebar-style appearance can provide access to content that people use less frequently. For guidance, see [Tab bars](./tab-bars.md).

**If necessary, apply the correct appearance to a sidebar.** If you’re not using SwiftUI to create a sidebar, you can use the [UICollectionLayoutListConfiguration.Appearance.sidebar](https://developer.apple.com/documentation/UIKit/UICollectionLayoutListConfiguration-swift.struct/Appearance-swift.enum/sidebar) appearance of a collection view list layout. For developer guidance, see [UICollectionLayoutListConfiguration.Appearance](https://developer.apple.com/documentation/UIKit/UICollectionLayoutListConfiguration-swift.struct/Appearance-swift.enum).

### macOS

A sidebar’s row height, text, and glyph size depend on its overall size, which can be small, medium, or large. You can set the size programmatically, but people can also change it by selecting a different sidebar icon size in General settings.

**Avoid stylizing your app by specifying a fixed color for all sidebar icons.** By default, sidebar icons use the current [accent color](https://developer.apple.com/design/human-interface-guidelines/color#App-accent-colors) and people expect to see their chosen accent color throughout all the apps they use. Although a fixed color can help clarify the meaning of an icon, you want to make sure that most sidebar icons display the color people choose.

**Consider automatically hiding and revealing a sidebar when its container window resizes.** For example, reducing the size of a Mail viewer window can automatically collapse its sidebar, making more room for message content.

**Avoid putting critical information or actions at the bottom of a sidebar.** People often relocate a window in a way that hides its bottom edge.

## Resources

#### Related

[Split views](./split-views.md)

[Tab bars](./tab-bars.md)

[Layout](./layout.md)

#### Developer documentation

[sidebarAdaptable](https://developer.apple.com/documentation/SwiftUI/TabViewStyle/sidebarAdaptable) — SwiftUI

[NavigationSplitView](https://developer.apple.com/documentation/SwiftUI/NavigationSplitView) — SwiftUI

[sidebar](https://developer.apple.com/documentation/SwiftUI/ListStyle/sidebar) — SwiftUI

[UICollectionLayoutListConfiguration](https://developer.apple.com/documentation/UIKit/UICollectionLayoutListConfiguration-swift.struct) — UIKit

[NSSplitViewController](https://developer.apple.com/documentation/AppKit/NSSplitViewController) — AppKit

#### Videos

- [Elevate the design of your iPad app](https://developer.apple.com/videos/play/wwdc2025/208)

## Change log

| Date | Changes |
| --- | --- |
| June 9, 2025 | Added guidance for extending content beneath the sidebar. |
| August 6, 2024 | Updated guidance to include the SwiftUI adaptable sidebar style. |
| December 5, 2023 | Added artwork for iPadOS. |
| June 21, 2023 | Updated to include guidance for visionOS. |
