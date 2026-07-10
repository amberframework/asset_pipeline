# Phase 1 Baseline

This is the baseline for Phase 2 component/runtime extraction. It predates the
canonical unbranded artifact directory, so its hashes are recorded against the
old compatibility path `test-results/amber-design-system/`. Current validation
writes canonical artifacts to `test-results/web-design-system/` and mirrors
compatibility copies during migration.

Generated on May 9, 2026 with:

```bash
crystal run examples/web_design_system_demo.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/capture_web_demo_screenshots.cr
```

## Line Counts

```text
1     examples/web_design_system_demo.cr
1721  examples/amber_design_system_demo.cr
820   public/js/amber-design-system.js
```

This historical baseline predates the Phase 30 generator rename. The canonical
implementation now lives in `examples/web_design_system_demo.cr`, and
`examples/amber_design_system_demo.cr` remains only as a compatibility wrapper.

## Browser Evidence

`test-results/amber-design-system/browser-audit.json` reported:

```json
{
  "total_screenshots": 57,
  "desktop_light_dark_1440": 14,
  "mobile_light_dark_390": 14,
  "reflow_light_dark_320": 14,
  "reduced_motion_screenshots": 10,
  "interactive_state_screenshots": 7
}
```

Key screenshot hashes, relative to `test-results/amber-design-system/`:

```text
73743ba061076a68f19505c1e88636fe0efe752de0fcc7489135740aa297db50  desktop-light.png
710a4527a2d8f45132578e07257c5cd03b3009d6da53ecaa0a3d133ac2ef63ba  desktop-dark.png
301fde74806c9912d9f294baf95bd3e924500baa943099b8291009bdbe70643e  mobile-light.png
341dc492983144f4149ca2ba13f9d59e3de56416e8a3840d95a9741e25e2b3e1  mobile-dark.png
845747aadbc1742cbf476513dd6190e72b80016100db3f488e81b9cd34d3e3f0  pricing-invalid-state.png
d346bebccd22f366d5f3ffe024f9a3251af7203424b53fb1462ae84b46ff3a16  forms-invalid-state.png
c2a1319cae644f9b6ed2cca9509e53eb77b10bbde55d41d0dd4f923bc25accdd  dashboard-command-open.png
0b7753a905a3f4b51ba85fba5cd0795bc7d79f9848cc417a1ad1b914de411f3c  patterns-tabs-carousel-state.png
63e1f1a872de1b0d10fedf25c4748a5fb10a8102fe13869049719bff7adb306f  patterns-dialog-open.png
```

Phase 2 extractions should compare against this matrix before accepting visual
drift. If the demo intentionally changes, record the reason and replace these
hashes in the phase note with the new accepted baseline.
