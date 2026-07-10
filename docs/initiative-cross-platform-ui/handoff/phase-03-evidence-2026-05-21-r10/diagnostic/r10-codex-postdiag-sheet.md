# Codex Checkpoint 1B — sheet evidence sufficiency

Verdict: **EVIDENCE SUFFICIENT for the fix target**; Gap-3 AX-dump
diagnostic still required after Gaps 1+2 ship (as the brief mandates).

Codex quote:
> Yes, mostly.
>
> The data proves the fix should target BX8 sheet presentation state
> wiring, not just the XCTest query.
>
> 1. The test is wrong at launch: it expects sheet-primary before tapping
>    sheet-trigger.
> 2. The demo is also broken: sheet-trigger has an empty on_tap, so it
>    cannot present the sheet.
> 3. The bridge is missing the reactive path from Crystal
>    UI::Sheet#is_presented = true into SwiftUI .sheet(isPresented:).
>
> So the real fix target is: make Sheet presentation/dismissal reactive
> end-to-end from Crystal to SwiftUI, then rewrite the BX8 test around
> opening the sheet first.
>
> What is not yet proved: whether sheet-content, sheet-primary, and
> sheet-cancel are discoverable in the AX tree after the sheet actually
> opens.
>
> Additional instrumentation needed after the reactive bridge lands: tap
> sheet-trigger, wait through animation, dump app.debugDescription, and
> confirm whether the elements appear under app.sheets, app.otherElements,
> or are blocked by the hosted-child accessibility boundary.

Action: proceed to fix design. The AX-dump probe runs after the reactive
bridge is live.
