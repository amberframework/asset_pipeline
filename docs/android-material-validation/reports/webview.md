# WebView

- Study purpose: replace the placeholder web surface with a real Android-native web container inside the validation host.
- Native classes involved: `android.webkit.WebView`, `android.widget.LinearLayout`, `android.widget.TextView`.
- Current renderer status: renderer-backed with current phone, tablet, light, and dark captures from April 18, 2026.
- Light appearance notes: the study now captures real inline HTML content inside Android `WebView` after adding an honest settle delay to the capture runner.
- Dark appearance notes: dark captures are current and the mounted HTML still renders reliably inside the shared host frame.
- Phone and tablet observations: tablet captures confirm the WebView surface scales cleanly once it is allowed time to finish loading.
- Open deviations and promotion impact: external-content flow and navigation behavior still need follow-up before this surface can be promoted.
