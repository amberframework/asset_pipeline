# Text Fields

- Study purpose: validate the first shared Material default pass for text entry, placeholder treatment, and combo-box selection.
- Native classes involved: `com.google.android.material.textfield.TextInputLayout`, `com.google.android.material.textfield.TextInputEditText`, `com.google.android.material.textfield.MaterialAutoCompleteTextView`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026.
- Light appearance notes: the study now mounts Material-backed input classes, and the combo box reads as an outlined dropdown instead of a generic placeholder surface.
- Dark appearance notes: dark contrast is current and usable, but the filled-field label spacing still needs another Material 3 fidelity pass.
- Phone and tablet observations: both device classes capture cleanly, although the filled-field density is still slightly off relative to Material 3 references.
- Open deviations and promotion impact: combo-box options are not yet backed by a live adapter-driven dropdown, and filled-field polish is still in flight, so promotion remains blocked.
