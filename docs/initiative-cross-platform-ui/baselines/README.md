# Visual baselines — canonical tree

Per the Phase 6.5 brief, this directory is the single canonical location
for per-platform visual baselines that the audit harness diffs against.

Layout:

```
baselines/
  ios/    <slug>[-<appearance>].png
          <slug>[-<appearance>].tolerance.json
          <slug>[-<appearance>].fingerprint.json
  macos/  same
  web/    same (no appearance suffix; CDP renders one image per slug)
```

Each baseline has two sidecar files:

- `<slug>.tolerance.json` — per-baseline tolerance with `pixel_diff_max`
  and `channel_diff_max`. `scripts/visual_diff.cr` uses these as the
  acceptance bar when `magick compare -metric AE` runs.
- `<slug>.fingerprint.json` — toolchain fingerprint at capture time
  (macOS version, Xcode version, Crystal version, ImageMagick version).
  Visual regressions caused by toolchain upgrades are diagnosable from
  this metadata.

To regenerate a baseline:

```bash
bash scripts/regenerate_baselines.sh --platform macos --slug phase-03-button-default --appearance light
bash scripts/regenerate_baselines.sh --platform web --slug action_sheet
```

## Migration provenance

The current macOS baselines were migrated from
`docs/initiative-cross-platform-ui/handoff/phase-03-baselines/screenshots/macos/`
in commit `[Phase 6.5 D2] Migrate Phase 3 baselines into canonical baselines/ tree`.
The original Phase 3 directory is preserved as the historical reference
(do not delete it; the per-phase evidence handoffs reference it).

Filename mapping: `phase-03-<slug>-macos-<appearance>.png` →
`phase-03-<slug>-<appearance>.png`. The "-macos-" infix is dropped
because platform is encoded in the parent directory.
