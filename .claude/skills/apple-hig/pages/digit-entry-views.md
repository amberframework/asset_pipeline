---
title: "Digit entry views"
slug: "digit-entry-views"
source_url: "https://developer.apple.com/design/human-interface-guidelines/digit-entry-views"
role: "article"
abstract: "A digit entry view fills the entire screen and prompts people to enter a series of digits, like a PIN, using a digit-specific keyboard."
platforms_mentioned: [iOS, iPadOS, macOS]
related: []
---

# Digit entry views

A digit entry view fills the entire screen and prompts people to enter a series of digits, like a PIN, using a digit-specific keyboard.

![A stylized representation of an Apple TV five-digit passcode entry screen. The image is tinted red to subtly reflect the red in the original six-color Apple logo.](../images/components-digit-entry-view-intro.png)

You can add an optional title and prompt above the line of digits.

## Best practices

**Use secure digit fields.** Secure digit fields display asterisks instead of the entered digit onscreen. Always use a secure digit field when your app asks for sensitive data.

**Clearly state the purpose of the digit entry view.** Use a title and prompt that explains why someone needs to enter digits.

## Platform considerations

*Not supported in iOS, iPadOS, macOS, visionOS, or watchOS.*

## Resources

#### Related

[Virtual keyboards](./virtual-keyboards.md)

#### Developer documentation

[TVDigitEntryViewController](https://developer.apple.com/documentation/TVUIKit/TVDigitEntryViewController) — TVUIKit
