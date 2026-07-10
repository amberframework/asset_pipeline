# Chart View

- Study purpose: eliminate the highest-visibility Android chart placeholder while the renderer and validation host mature together.
- Native classes involved: `android.widget.LinearLayout`, `android.widget.TextView`, `android.view.View`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026.
- Light appearance notes: the study communicates the intended data story cleanly through shared Android primitives and scales well on tablet.
- Dark appearance notes: dark captures are current, but the visual still reads as a composed preview rather than a production chart surface.
- Phone and tablet observations: adaptive screenshots are now current and stable, which makes layout review trustworthy even though the chart implementation is not final.
- Open deviations and promotion impact: a dedicated Android chart implementation is still missing, so promotion remains blocked.
