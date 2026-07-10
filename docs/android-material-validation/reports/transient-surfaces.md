# Transient Surfaces

- Study purpose: validate Android-owned transient surfaces after replacing placeholder sheet, popover, and snackbar boxes with renderer-backed compositions.
- Native classes involved: `com.google.android.material.card.MaterialCardView`, `android.widget.LinearLayout`, `android.widget.Space`, `android.widget.TextView`, `android.view.View`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026.
- Light appearance notes: the sheet now reads as a real elevated Material surface, the popover carries arrow-edge intent, and the snackbar is no longer a plain text placeholder.
- Dark appearance notes: contrast remains stable in the current dark matrix, but the study still reads as a stacked showcase instead of a fully resolved transient layering story.
- Phone and tablet observations: the tablet captures have enough room for the three transient surfaces to coexist more clearly, while the phone capture still lets the sheet dominate the frame and compress the lower surfaces.
- Open deviations and promotion impact: current captures are honest and useful, but the phone layering and callback behavior still need another review pass before this study should be promoted.
