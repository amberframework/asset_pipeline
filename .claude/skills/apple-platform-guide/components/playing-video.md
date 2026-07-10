---
slug: playing-video
ui_view: UI::VideoPlayer
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/playing-video.md
validation_report: ../validation/reports/playing-video.md
---

# UI::VideoPlayer

> A native video playback surface backed by AVKit. It should feel like the
> system player belongs in your app, not like a custom media experiment.

## Feel of the flow

`UI::VideoPlayer` is for media-first moments: trailers, tutorials, recorded
sessions, narrative clips, and other experiences where playback itself is the
task. The HIG strongly prefers the system player because people already know
how to use it. That matters. Familiar transport controls buy you trust and let
the content do the work.

Use it when video is central to the screen. If playback is secondary, keep the
frame quieter and avoid surrounding it with busy decorative panels.

## Quickstart

```crystal
player = UI::VideoPlayer.new("https://example.com/video.m3u8")
player.shows_controls = true
player.auto_play = false
player.muted = true
player.accessibility_label = "Session playback"
```

Renders with the platform video player: `AVPlayerViewController` on iOS/iPadOS
and `AVPlayerView` on macOS. During HIG validation capture, the harness can
switch to a deterministic poster preview so screenshot evidence stays stable
when static capture misses live AVKit pixels.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `url` | `String` | `""` | Video URL to load into the native player. |
| `shows_controls` | `Bool` | `true` | Shows or hides the system playback controls. |
| `auto_play` | `Bool` | `false` | Begins playback when the player becomes ready. |
| `muted` | `Bool` | `false` | Starts playback muted. |
| `loop` | `Bool` | `false` | Reserved loop intent for future richer playback wiring. |
| `poster_url` | `String?` | `nil` | Poster metadata for future artwork-first flows. |

## Light / dark appearance notes

The strongest default is restraint:

- Keep the player frame at the media's natural aspect ratio.
- Let the transport controls remain the primary chrome.
- Avoid wrapping the player in extra card borders unless the layout truly
  needs separation from surrounding content.

In dark contexts, the system player already does the right thing. Resist the
urge to "brand" the playback chrome unless you have a real reason to diverge.

## Customization / brand override

**Honor the source aspect ratio.**
This is one of the clearest HIG requirements for video. Do not stretch the
media to fit an arbitrary card.

**Prefer supporting copy around the frame, not on top of it.**
If a title, description, or chapter marker is important, place it adjacent to
the player so playback stays visually clean.

## What happens on each platform

- **iOS 26 / iPadOS 26**: `AVPlayerViewController`-backed view with native
  playback controls. The validation harness sets `HIG_VALIDATION_CAPTURE=1`
  so screenshot evidence uses a capture-only poster instead of arbitrary live
  playback frames.
- **macOS 26**: `AVPlayerView` with the standard AppKit playback chrome.
  The offscreen HIG screenshot path also swaps to the same poster treatment so
  evidence remains readable when `CGWindowListCreateImage` misses live AVKit
  composition.

## HIG citations (validated)

- Playing video: "Use the system video player to give people a familiar and
  convenient experience."
- Playing video: "Always display video content at its original aspect ratio."
- Playing video: "Provide additional information when it adds value."

Validation report with side-by-side captures:
[validation/reports/playing-video.md](../validation/reports/playing-video.md)

## Related

- `UI::WebViewComponent` for embedded editorial or help content that accompanies
  media.
- `UI::Sheet` when playback metadata needs a modal complement instead of extra
  chrome around the player itself.
