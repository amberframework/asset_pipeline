# Map View

- Study purpose: eliminate the Android map placeholder family and keep the validation host stable while the platform bridge grows.
- Native classes involved: `android.widget.LinearLayout`, `android.widget.TextView`, `android.view.View`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026, and the prior crash path is fixed.
- Light appearance notes: the study captures reliably and summarizes route, annotations, and user-location state without falling back to a launcher crash.
- Dark appearance notes: dark captures are current, but they still represent a composed preview surface rather than a real map widget.
- Phone and tablet observations: the layout scales to tablet width, which is useful for review, but it is still only a preview composition.
- Open deviations and promotion impact: an SDK-backed map implementation is still missing, so promotion remains blocked.
