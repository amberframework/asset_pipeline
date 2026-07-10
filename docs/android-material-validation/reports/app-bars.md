# App Bars

- Study purpose: validate top app bar structure, title emphasis, and trailing utility actions for the shared Android renderer.
- Native classes involved: `com.google.android.material.appbar.MaterialToolbar`, `android.widget.LinearLayout`, `android.widget.TextView`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026.
- Light appearance notes: the study now mounts `MaterialToolbar`, and tablet captures hold title/action balance much better than the old composed row.
- Dark appearance notes: dark captures stay legible, with current title and action contrast holding across phone and tablet.
- Phone and tablet observations: the structure scales across both device classes, but the validation set still covers only static toolbar states.
- Open deviations and promotion impact: toolbar menu actions are not yet wired through the Android callback bridge, and overflow behavior still lacks coverage, so promotion stays blocked.
