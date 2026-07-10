# Examples

The canonical Milestone 1 web design-system example is:

```bash
crystal run examples/web_design_system_demo.cr
```

It writes a multi-page static demo starting at
`output/web-design-system-demo.html`, with companion pages for pricing,
forms/auth, dashboard/data, timeline, collaboration, and page patterns. It uses
semantic tokens, `am-*` alpha styling classes, vanilla JavaScript helpers,
first-party SVG charts, semantic HTML forms, working browser-only UI behavior,
the light/dark cascade contract, and promoted Crystal wrappers for command
palette, schedule heatmap, payment/auth forms, theme switching, fields, pricing
cards, tabs, carousel, dialog, and timeline patterns.

The other examples in this directory are historical Asset Pipeline import-map,
Stimulus, dependency-analysis, or earlier Bootstrap-shaped demos. They remain
useful for legacy API behavior, but they are not the canonical design-system
direction. New design-system examples should start from
`examples/web_design_system_demo.cr` and the docs in `docs/web-design-system/`.

`examples/amber_design_system_demo.cr` is now only a compatibility wrapper for
the old alpha command name. Treat that filename as compatibility debt, not as
the naming target for new components or docs.
