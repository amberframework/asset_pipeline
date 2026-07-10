# Selection Controls

- Study purpose: validate menu, segmented, inline, search, and stepper selection flows through the shared Android renderer.
- Native classes involved: `android.widget.Spinner`, `android.widget.RadioGroup`, `android.widget.RadioButton`, `android.widget.SearchView`, `com.google.android.material.card.MaterialCardView`, `com.google.android.material.button.MaterialButton`, `android.widget.TextView`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026.
- Light appearance notes: the phone and tablet captures show coherent Material card framing, readable segmented and inline selection affordances, and a search field that no longer opens the keyboard by default during screenshot capture.
- Dark appearance notes: the current dark captures preserve label contrast and selection state legibility without collapsing the supporting text or control chrome.
- Phone and tablet observations: the tablet layout scales cleanly and gives the menu, inline options, search field, and stepper enough room to read as one study instead of a cramped stack.
- Open deviations and promotion impact: callback plumbing for spinner selection, search submission, and stepper changes is implemented, but promotion stays blocked until we refresh explicit interaction verification beyond the static matrix captures.
