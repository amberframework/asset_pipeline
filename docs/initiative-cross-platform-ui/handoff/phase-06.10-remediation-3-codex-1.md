# Phase 6.10 Remediation 3 — Codex Review 1

**Date:** 2026-05-23
**Commit reviewed:** `5c13aee`
**Reviewer:** Codex (`codex exec review --commit 5c13aee`)

## Verdict

NEEDS_WORK — two P2 findings against the diff, both fixable in
iter 2 without changing the architectural direction.

## Findings (verbatim from Codex)

> The new scroll wrapper introduces required Auto Layout constraint
> conflicts for the current fixed-width Voyager roots, and the new
> view-controller parenting path never tears down containment for
> removed hosted views. These are functional/lifecycle regressions
> that should be fixed before considering the patch correct.

### [P2] Avoid conflicting required widths in scroll wrapper

> `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/samples/initiative-cross-platform-ui-voyager/ios/Sources/ContentView.swift:130-130`
>
> When Voyager renders any of these screens on an iPhone-width viewport,
> this new required `crystalRoot.width == scroll.frameLayoutGuide.width`
> constraint conflicts with the root stacks' existing required 340pt
> width constraints (`minimum_width == maximum_width` is emitted as
> priority 1000). On the documented iPhone 17 portrait width this gives
> Auto Layout two incompatible required widths, so UIKit will break one
> unpredictably and can undo the fixed-width layout the screens rely on.

### [P2] Remove child controllers when hosted views detach

> `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:96-97`
>
> When a Crystal-rendered root is discarded, such as every Voyager route
> change caused by `.id(slug)`, the hosting controller added here remains
> in the parent view controller's `children` array because there is no
> matching `willMove(toParent: nil)` / `removeFromParent()` path when
> the hosted view leaves the window. Repeated navigation therefore leaves
> stale `APSKAttachingHostingController` instances parented to the root
> host, keeping their SwiftUI state and callback closures alive after
> their views are gone.

## Implementer response

Both findings are correct and align with the open layout symptoms
observed during iter 1 evidence capture (Settings back button + Todos
list children rendered below the visible viewport — likely the
"UIKit broke one of the conflicting required widths unpredictably"
manifestation Codex predicted).

Iter 2 must:

1. **Constraint conflict fix:** drop the required priority on
   `crystalRoot.widthAnchor == scroll.frameLayoutGuide.widthAnchor`
   constraint to `.defaultHigh` (750) so the inner stack's 340pt
   `min_w == max_w` required constraint wins on iPhone 17 portrait.
   The scroll view's content layout guide already pins the inner edges
   so the only role of the width constraint is to PREVENT horizontal
   overflow — a high (not required) priority is sufficient.

2. **Detach lifecycle fix:** add `viewWillDisappear` or
   `willMove(toSuperview: nil)` override on
   `APSKAttachingHostingController` that calls
   `willMove(toParent: nil)` + `removeFromParent()` when the controller's
   view leaves the window. On `.id(slug)` route swaps SwiftUI discards
   the representable's view tree; we need to detect that and undo the
   VC containment.

3. **Re-capture proof artifacts** after the layout-conflict fix so the
   evidence directory shows Settings / Todos / Editor with their below-
   the-fold elements either visible-and-pinned or genuinely scrollable
   into view (Item 3 acceptance).

4. **Item 1 interaction proof remains BLOCKED on XCUITest tap synthesis
   reliability** independent of these P2s; the codex-blocker doc
   captures the architectural status and proposes Path C
   (UITapGestureRecognizer backup) as the next-iteration fallback if
   hand-test verification on macOS / iOS bin doesn't surface
   interaction working.

— Implementer (Phase 6.10 Rem 3)
