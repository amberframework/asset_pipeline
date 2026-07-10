# Buttons

- Study purpose: validate default emphasis, destructive treatment, and low-emphasis actions for shared Android buttons.
- Native classes involved: `com.google.android.material.button.MaterialButton`, `android.widget.LinearLayout`, `android.widget.Space`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026.
- Light appearance notes: primary, tonal, outlined, and text actions now read with Material spacing and emphasis instead of generic button chrome.
- Dark appearance notes: dark contrast is stable in the current captures, and the destructive action remains readable.
- Phone and tablet observations: both device classes retain sensible spacing, but the study only covers default static states today.
- Open deviations and promotion impact: explicit pressed, disabled, and focus-state evidence plus callback verification are still missing, so promotion stays blocked.
