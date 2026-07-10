---
title: "Image views"
slug: "image-views"
source_url: "https://developer.apple.com/design/human-interface-guidelines/image-views"
role: "article"
abstract: "An image view displays a single image — or in some cases, an animated sequence of images — on a transparent or opaque background."
platforms_mentioned: [iOS, iPadOS, macOS]
related: []
---

# Image views

An image view displays a single image — or in some cases, an animated sequence of images — on a transparent or opaque background.

![A stylized representation of a photo. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](../images/components-image-view-intro.png)

Within an image view, you can stretch, scale, size to fit, or pin the image to a specific location. Image views are typically not interactive.

## Best practices

**Use an image view when the primary purpose of the view is simply to display an image.** In rare cases where you might want an image to be interactive, configure a system-provided [button](https://developer.apple.com/design/human-interface-guidelines/buttons) to display the image instead of adding button behaviors to an image view.

**If you want to display an icon in your interface, consider using a symbol or interface icon instead of an image view.** [SF Symbols](./sf-symbols.md) provides a large library of streamlined, vector-based images that you can render with various colors and opacities. An [icon](https://developer.apple.com/design/human-interface-guidelines/icons) (also called a glyph or template image) is typically a bitmap image in which the nontransparent pixels can receive color. Both symbols and interface icons can use the accent colors people choose.

## Content

An image view can contain rich image data in various formats, like PNG, JPEG, and PDF. For more guidance, see [Images](./images.md).

**Take care when overlaying text on images.** Compositing text on top of images can decrease both the clarity of the image and the legibility of the text. To help improve the results, ensure the text contrasts well with the image, and consider ways to make the text object stand out, like adding a text shadow or background layer.

**Aim to use a consistent size for all images in an animated sequence.** When you prescale images to fit the view, the system doesn’t have to perform any scaling. In cases where the system must do the scaling, performance is generally better when all images are the same size and shape.

## Platform considerations

*No additional considerations for iOS or iPadOS.*

### macOS

**If your app needs an editable image view, use an image well.** An [image well](https://developer.apple.com/design/human-interface-guidelines/image-wells) is an image view that supports copying, pasting, dragging, and using the Delete key to clear its content.

**Use an image button instead of an image view to make a clickable image.** An [image button](https://developer.apple.com/design/human-interface-guidelines/buttons#Image-buttons) contains an image or icon, appears in a view, and initiates an instantaneous app-specific action.

## Resources

#### Related

[Images](./images.md)

[Image wells](./image-wells.md)

[Image buttons](./buttons.md)

[SF Symbols](./sf-symbols.md)

#### Developer documentation

[Image](https://developer.apple.com/documentation/SwiftUI/Image) — SwiftUI

[UIImageView](https://developer.apple.com/documentation/UIKit/UIImageView) — UIKit

[NSImageView](https://developer.apple.com/documentation/AppKit/NSImageView) — AppKit

#### Videos

- [Support HDR images in your app](https://developer.apple.com/videos/play/wwdc2023/10181)
- [Add rich graphics to your SwiftUI app](https://developer.apple.com/videos/play/wwdc2021/10021)

## Change log

| Date | Changes |
| --- | --- |
| June 21, 2023 | Updated to include guidance for visionOS. |
