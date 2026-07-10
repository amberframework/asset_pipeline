# Codex Checkpoint 2A — Toggle pre-fix review

Verdict: **APPROVE Toggle direction, REJECT Slider as part of minimal fix.**

Action items from review:
1. Skip Slider migration entirely. BX4 already passes via the synthetic-track
   path; touching SliderFacade is unnecessary risk for no test gain.
2. Toggle wrapper MUST set accessibilityIdentifier directly on the UISwitch
   (BX3 looks up `app.switches["toggle-probe-toggle"]`).
3. Raw UISwitch drops the SwiftUI Toggle(label:) text — re-add a SwiftUI
   Text label beside the switch (HStack { Text(label); APSKToggleRepresentable }).
4. Storage must be an `@ObservedObject` on the SwiftUI parent View that
   wraps the representable, so updateUIView fires when storage.value changes.
5. Re-run BX3 AND BX4 to prove no regression.
