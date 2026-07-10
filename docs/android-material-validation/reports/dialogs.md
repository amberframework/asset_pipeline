# Dialogs

- Study purpose: validate the first Material-style pass for alert and confirmation actions in the Android renderer.
- Native classes involved: `com.google.android.material.card.MaterialCardView`, `android.widget.LinearLayout`, `android.widget.TextView`, `com.google.android.material.button.MaterialButton`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026.
- Light appearance notes: title, body copy, and action ordering now read like Material dialog studies instead of raw placeholder boxes.
- Dark appearance notes: dark captures are current and the action layout remains legible on both device classes.
- Phone and tablet observations: the inline study scales cleanly to tablet width, but it is still an in-host composition rather than a real modal surface.
- Open deviations and promotion impact: the renderer still needs honest platform dialog presentation and callback verification, so promotion remains blocked.
