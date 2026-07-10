---
title: "Image wells"
slug: "image-wells"
source_url: "https://developer.apple.com/design/human-interface-guidelines/image-wells"
role: "article"
abstract: "An image well is an editable version of an image view."
platforms_mentioned: [iOS, iPadOS]
related: []
---

# Image wells

An image well is an editable version of an image view.

![A stylized representation of an image well. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](../images/components-image-well-intro.png)

After selecting an image well, people can copy and paste its image or delete it. People can also drag a new image into an image well without selecting it first.

## Best practices

**Revert to a default image when necessary.** If your image well requires an image, display the default image again if people clear the content of the image well.

**If your image well supports copy and paste, make sure the standard copy and paste menu items are available.** People generally expect to choose these menu items — or use the standard keyboard shortcuts — to interact with an image well. For guidance, see [Edit menu](./the-menu-bar.md).

For related guidance, see [Image views](./image-views.md).

## Platform considerations

*Not supported in iOS, iPadOS, tvOS, visionOS, or watchOS.*

## Resources

#### Related

[Image views](./image-views.md)

#### Developer documentation

[NSImageView](https://developer.apple.com/documentation/AppKit/NSImageView) — AppKit
