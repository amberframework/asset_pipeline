# Codex Checkpoint 1A — toggle evidence sufficiency

Verdict: **EVIDENCE SUFFICIENT for fix target**.

Codex quote:
> Yes, but only for the fix target, not the deepest OS-level mechanism.
>
> The data proves the actual problem is: the iOS SwiftUI Toggle facade,
> when hosted through the current UIViewRepresentable / UIHostingController
> path, does not respond to XCUIElement.tap() on the exposed switch
> element, so the binding never flips and CallbackBridge.fire never runs.
>
> It also proves the problem is not BoolStorage, the Crystal callback
> chain, element discovery, or the whole hosting topology, because
> coordinate taps work and the slider callback path passes.
>
> The proposed UISwitch replacement is therefore targeted correctly. The
> slider migration is optional robustness/parity work based on this
> evidence, not required by the failing test.

Optional deeper instrumentation (not blocking R10 progress):
- instrument accessibilityActivate, SwiftUI binding setter invocation, and
  CallbackBridge.fire under both XCUIElement.tap() and coordinate tap to
  prove the exact mechanism.

Action: proceed to fix design for Toggle (UISwitch wrapper). Slider
migration follows per brief but is not load-bearing for any failing test.
