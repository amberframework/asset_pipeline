# Phase 6.10 Remediation 3 — Codex Review 2

**Date:** 2026-05-23
**Commit reviewed:** `56d971f` (iter 2 — initial response to Codex 1)
**Reviewer:** Codex (`codex exec review --commit 56d971f`)

## Verdict

NEEDS_WORK — one residual P2 finding against the iter-2 detach
lifecycle fix; the constraint-priority fix from iter 2 was not flagged
in this review pass.

## Findings (verbatim from Codex)

> The lifecycle fix still does not clean up the documented `.id(slug)`
> discard path because `deinit` cannot run while the controller remains
> retained as a child. The stale child-controller accumulation
> therefore remains in that scenario.

### [P2] Don't rely on deinit for detach cleanup

> `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/HostingHelpers.swift:132-132`
>
> For `.id(slug)` route swaps where UIKit does not send
> `viewWillDisappear`, this `deinit` fallback cannot remove the
> controller from the parent's `children` array: the parent retains
> child view controllers until `removeFromParent()` has already run,
> so ARC will not enter `deinit` while the stale child is still
> parented. Those route swaps therefore still accumulate old hosting
> controllers and their callback closures; the detach needs to be
> triggered by the view leaving the window/superview rather than
> deallocation.

## Implementer response (iter 3 fix)

Codex is correct — the retained-children paradox blocks deinit. The
detach needs a window-leaving signal, not a deallocation signal.

Iter 3 ships a `APSKHostingWindowSentinel` UIView subclass:

1. 0pt × 0pt hidden sentinel UIView installed as a subview of the
   hosting controller's `.view` in `viewDidLoad`.
2. The sentinel overrides `didMoveToWindow`; UIKit forwards window
   membership changes to every subview when the ancestor view's
   window changes, so the sentinel reliably tracks both add and
   remove events.
3. The sentinel's callback drives both `attachIfNeeded` (when window
   != nil) and `detachIfNeeded` (when window == nil).
4. Sentinel is `isHidden = true`, `userInteractionEnabled = false`,
   `isAccessibilityElement = false`, `accessibilityElementsHidden =
   true` so it never appears in the AX tree or intercepts touches.

This is the iter-3 commit `fa428fd`.

— Implementer (Phase 6.10 Rem 3)
