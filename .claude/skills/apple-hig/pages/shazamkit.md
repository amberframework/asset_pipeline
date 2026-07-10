---
title: "ShazamKit"
slug: "shazamkit"
source_url: "https://developer.apple.com/design/human-interface-guidelines/shazamkit"
role: "article"
abstract: "ShazamKit supports audio recognition by matching an audio sample against the ShazamKit catalog or a custom audio catalog."
platforms_mentioned: [iOS, iPadOS, macOS]
related: []
---

# ShazamKit

ShazamKit supports audio recognition by matching an audio sample against the ShazamKit catalog or a custom audio catalog.

![A sketch of the ShazamKit icon. The image is overlaid with rectangular and circular grid lines and is tinted blue to subtly reflect the blue in the original six-color Apple logo.](../images/technologies-ShazamKit-intro.png)

You can use ShazamKit to provide features like:

- Enhancing experiences with graphics that correspond with the genre of currently playing music
- Making media content accessible to people with hearing disabilities by providing closed captions or sign language that syncs with the audio
- Synchronizing in-app experiences with virtual content in contexts like online learning and retail

If you need the device microphone to get audio samples for your app to recognize, you must request access to it. As with all types of permission requests, it’s important to help people understand why you’re asking for access. For guidance, see [Privacy](./privacy.md).

![A screenshot of the Math School app’s permission alert on iPhone. The alert reads 'Math School would like to access your microphone. Synchronize reading and math exercises with videos played by your teacher.' There are two buttons available: Not Now and Allow.](../images/shazamkit-mic-permission.png)

## Best practices

After you receive permission to access the microphone for features that use ShazamKit, follow these guidelines.

**Stop recording as soon as possible.** When people allow your app to record audio for recognition, they don’t expect the microphone to stay on. To help preserve privacy, only record for as long as it takes to get the sample you need.

**Let people opt in to storing your app’s recognized songs to their iCloud library.** If your app can store recognized songs to iCloud, give people a way to first approve this action. Even though both the Music Recognition control and the Shazam app show your app as the source of the recognized song, people appreciate having control over which apps can store content in their library.

## Platform considerations

*No additional considerations for iOS, iPadOS, macOS, tvOS, visionOS, or watchOS.*

## Resources

#### Developer documentation

[ShazamKit](https://developer.apple.com/documentation/ShazamKit)

#### Videos

- [Explore ShazamKit](https://developer.apple.com/videos/play/wwdc2021/10044)
