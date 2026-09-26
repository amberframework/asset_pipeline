# Noise tile reference

The SVG applies the `fractalNoise` turbulence values to the red channel, copies
that channel to opaque grayscale, and composites it at 7% over `#808080`. The
128 by 128 user-unit tile is rendered at 256 by 256 pixels to match a 128 point
native tile on a 2x display. `color-interpolation-filters="sRGB"` keeps the
reference in the color space used by the native tile.

Exact command, run from the repository root:

```sh
rsvg-convert --format=png --output=spec/native_macos/fixtures/noise-tile/reference.png spec/native_macos/fixtures/noise-tile/reference.svg
```

Renderer: `rsvg-convert` 2.62.1, executable SHA-256
`f9a4aa5e7d66f8e61ebbc5f7df3f0966d7d9a5c43d1a691969092c86ebebeb2e`.

Reference PNG SHA-256:
`092d7c643d66b5aab4ec9c224c624833145d0be448e090a74295e93630de832c`.

The native spec allows a maximum per-channel difference of `7/255`. The
measured native/reference maximum is `7/255`; the previous sine-wave tile
measured `26/255` against this fixture. This allowance covers the small
8-bit compositing differences between librsvg and Core Animation at 7%
opacity while still rejecting the visibly different old pattern.

At 7% opacity over the flat fill, the measured native mean is `128.0003` and
standard deviation is `2.1507` on the 0–255 channel scale. The reference mean
is `127.5117` and standard deviation is `2.0295`, so the absolute differences
are `0.4886` and `0.1212` channel values. Both are within `0.5` channel value
(`0.5/255` of full scale).
