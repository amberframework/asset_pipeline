---
title: "Labels"
slug: "labels"
source_url: "https://developer.apple.com/design/human-interface-guidelines/labels"
role: "article"
abstract: "A label is a static piece of text that people can read and often copy, but not edit."
platforms_mentioned: [iOS, iPadOS, macOS]
related: []
---

# Labels

A label is a static piece of text that people can read and often copy, but not edit.

![A stylized representation of a text label. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](../images/components-label-intro.png)

Labels display text throughout the interface, in buttons, menu items, and views, helping people understand the current context and what they can do next.

The term *label* refers to uneditable text that can appear in various places. For example:

- Within a button, a label generally conveys what the button does, such as Edit, Cancel, or Send.
- Within many lists, a label can describe each item, often accompanied by a symbol or an image.
- Within a view, a label might provide additional context by introducing a control or describing a common action or task that people can perform in the view.

> **Note:**
> To display uneditable text, SwiftUI defines two components: [Label](https://developer.apple.com/documentation/SwiftUI/Label) and [Text](https://developer.apple.com/documentation/SwiftUI/Text).

The guidance below can help you use a label to display text. In some cases, guidance for specific components — such as [action buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [menus](https://developer.apple.com/design/human-interface-guidelines/menus), and [lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables) — includes additional recommendations for using text.

## Best practices

**Use a label to display a small amount of text that people don’t need to edit.** If you need to let people edit a small amount of text, use a [text field](https://developer.apple.com/design/human-interface-guidelines/text-fields). If you need to display a large amount of text, and optionally let people edit it, use a [text view](https://developer.apple.com/design/human-interface-guidelines/text-views).

**Prefer system fonts.** A label can display plain or styled text, and it supports Dynamic Type (where available) by default. If you adjust the style of a label or use custom fonts, make sure the text remains legible.

**Use system-provided label colors to communicate relative importance.** The system defines four label colors that vary in appearance to help you give text different levels of visual importance. For additional guidance, see [Color](./color.md).

| System color | Example usage | iOS, iPadOS, tvOS, visionOS | macOS |
| --- | --- | --- | --- |
| Label | Primary information | [label](https://developer.apple.com/documentation/UIKit/UIColor/label) | [labelColor](https://developer.apple.com/documentation/AppKit/NSColor/labelColor) |
| Secondary label | A subheading or supplemental text | [secondaryLabel](https://developer.apple.com/documentation/UIKit/UIColor/secondaryLabel) | [secondaryLabelColor](https://developer.apple.com/documentation/AppKit/NSColor/secondaryLabelColor) |
| Tertiary label | Text that describes an unavailable item or behavior | [tertiaryLabel](https://developer.apple.com/documentation/UIKit/UIColor/tertiaryLabel) | [tertiaryLabelColor](https://developer.apple.com/documentation/AppKit/NSColor/tertiaryLabelColor) |
| Quaternary label | Watermark text | [quaternaryLabel](https://developer.apple.com/documentation/UIKit/UIColor/quaternaryLabel) | [quaternaryLabelColor](https://developer.apple.com/documentation/AppKit/NSColor/quaternaryLabelColor) |

**Make useful label text selectable.** If a label contains useful information — like an error message, a location, or an IP address — consider letting people select and copy it for pasting elsewhere.

## Platform considerations

*No additional considerations for iOS, iPadOS, tvOS, or visionOS.*

### macOS

> **Note:**
> To display uneditable text in a label, use the [isEditable](https://developer.apple.com/documentation/AppKit/NSTextField/isEditable) property of [NSTextField](https://developer.apple.com/documentation/AppKit/NSTextField).

## Resources

#### Related

[Text fields](./text-fields.md)

[Text views](./text-views.md)

#### Developer documentation

[Label](https://developer.apple.com/documentation/SwiftUI/Label) — SwiftUI

[Text](https://developer.apple.com/documentation/SwiftUI/Text) — SwiftUI

[UILabel](https://developer.apple.com/documentation/UIKit/UILabel) — UIKit

[NSTextField](https://developer.apple.com/documentation/AppKit/NSTextField) — AppKit

## Change log

| Date | Changes |
| --- | --- |
| June 5, 2023 | Updated guidance to reflect changes in watchOS 10. |
