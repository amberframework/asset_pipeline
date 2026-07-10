# Voyager web is a static-site target; Amber is a separate full-server proof

**Status:** Architectural position note. Committed as part of Phase 8D.3a.
**Audience:** Future contributors wondering "why doesn't the Voyager web
build use `UI::ActionDispatcher` like macOS / iOS do?"

---

## Position

`UI::App` declares routes + controllers once; native (macOS, iOS) hosts
drive screens through `UI::ActionDispatcher`, and an Amber web host drives
them through `UI::AmberIntegration.routes_for`. Both paths are real and
proven. **Voyager web specifically uses the static-site mode, which is
NOT on the unified dispatcher path** — and that is deliberate.

### Architectural claim split

- **"Unified `UI::App` declaration drives native (macOS + iOS) via
  `UI::ActionDispatcher`"** — TRUE.
  - Proof: Phase 8D.1 (macOS host migration) + Phase 8D.2 (iOS host
    migration).
  - Code: `src/asset_pipeline/action_dispatcher.cr`,
    `samples/initiative-cross-platform-ui-voyager/macos/host_bootstrap.cr`,
    `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr`.

- **"Unified `UI::App` declaration drives a full-server web target via
  `UI::AmberIntegration.routes_for`"** — TRUE.
  - Proof: Phase 8C Amber spike.
  - Code: `samples/phase-08-amber-spike/config/routes.cr`,
    `src/asset_pipeline/amber_integration.cr`.

- **"Voyager web specifically is on the unified dispatcher path"** —
  FALSE, and deliberately so. Voyager web is a *static-site* target:
  build-time HTML emission per known slug, navigation handled in the
  browser by JavaScript. There is no Crystal server in the loop; there
  is no live `UI::ActionDispatcher` to dispatch into.

## Why split web into two targets

Static-site web and full-server web answer different operational
questions. Static-site web optimises for deployable artifacts — a
fragment per slug emitted by `samples/initiative-cross-platform-ui-voyager/web/static_site.cr`,
hostable on any object store with no Crystal runtime at the edge. Amber
web optimises for live dispatch — every action routes through Amber's
request lifecycle into a Crystal-resident `UI::ActionDispatcher`.

Forcing Voyager's static-site target onto the dispatcher path would
require either embedding a Crystal runtime in the browser (out of
scope), or doing a server round-trip per action (defeats the purpose of
a static site). Instead, Voyager web uses `Voyager.build_route` — the
permanent static-site entry point — to render each slug's HTML
fragment at build time, with screen callbacks reduced to no-ops on
this path.

## Code paths

| Target | Entry point | File |
|---|---|---|
| Voyager native (macOS, iOS) | `UI::ActionDispatcher` | `samples/initiative-cross-platform-ui-voyager/ios/bridge.cr`, `samples/initiative-cross-platform-ui-voyager/macos/host_bootstrap.cr` |
| Voyager web (static site) | `Voyager.build_route` | `samples/initiative-cross-platform-ui-voyager/web/static_site.cr` |
| Amber web (full-server) | `UI::AmberIntegration.routes_for` | `samples/phase-08-amber-spike/config/routes.cr` |

`Voyager.build_route` is **not** a transitional shim. Phase 8D.1 originally
framed it that way, but post-8D.2 — once iOS no longer calls it — its
role clarified to *the static-site entry point*. Phase 8D.3a settles its
disposition at D1 (keep, doc) and updates the docstrings in
`samples/initiative-cross-platform-ui-voyager/app.cr` accordingly.

`UI::AmberIntegration.routes_for` is the dispatcher-driven web target.
The Phase 8C Amber spike proves that the same `UI::App` declaration
that drives native can also drive a live-server web stack — but
through a separate code path from Voyager's static-site target.

## Future work

A "Voyager Amber port" — taking the Voyager sample and rebuilding its
web surface as an Amber app on the dispatcher path — is supported by
the Phase 8 architecture. It is **not** a 2026 commitment. The two
targets serve different deployment models; both should remain
demonstrable.

If a future phase elects to merge them, the changes are localised:
register Voyager's controllers with `UI::AmberIntegration.routes_for`,
remove the static-site emitter, and update deployment from
"upload fragments to S3" to "deploy an Amber app."

## Cross-references

- [Phase 8 design overview](../phases/phase-08-ergonomic-mvc-api/design.md)
- [Phase 8D scoping](../phases/phase-08-ergonomic-mvc-api/scoping-8d.md)
- [Phase 8D.3 scoping](../phases/phase-08-ergonomic-mvc-api/scoping-8d.3.md)
- [Phase 8D.3 co-plan](../phases/phase-08-ergonomic-mvc-api/coplan-8d.3-codex-1.md)
- [Phase 8D.3a brief](../phases/phase-08-ergonomic-mvc-api/brief-8d.3a.md)
- Code: `samples/initiative-cross-platform-ui-voyager/app.cr` —
  `Voyager.build_route` docstring describes this position in-context.
