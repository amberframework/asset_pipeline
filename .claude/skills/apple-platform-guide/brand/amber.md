# Amber — the Amber-verse brand persona

A single coherent brand used across every validation capture in the `apple-platform-guide`. Every slug's showcase uses Amber's palette, role colors, and content voice so reviewers judge the default UI system *in character*, not as abstract demos.

Amber is the mascot-personification of the Amber web framework. In the validation harness she supplies the default taste layer: warm gold primary actions, plum destructive/emphasis states, sage success, peach warnings, glass-friendly cream/ember backdrops, and concise app-like copy. A full Amber app shell appears only when a preview stage explicitly needs `app_scene` structure.

## Palette

All values override HIG semantic defaults via a theme layer. HIG semantics still apply — Amber primary fills the role of `systemBlue`, Amber plum fills destructive/emphasis where `systemRed` would go.

### Primary — Amber
- Light: `#FFAD33` (warm gold, 66% saturation)
- Dark:  `#FFB84D` (slightly lighter in dark for better contrast)
- Use: primary CTAs, selection highlights, active states, link text

### Accent — Plum
- Light: `#5B3A94`
- Dark:  `#7D59B8`
- Use: destructive (in place of systemRed where brand voice allows), emphasis, "thinking" states, secondary CTAs

### Success — Sage
- Light: `#6EAD77`
- Dark:  `#7EBD87`
- Use: confirmation, success badges, completed-task indicators

### Warning — Peach
- Light: `#FF8C5A`
- Dark:  `#FF9E73`
- Use: caution, approaching-limit warnings (NOT destructive — plum is destructive)

### Surfaces
- Cream (light mode background): `#FAF6F0`
- Deep ember (dark mode background): `#2A1A08` (burnt amber, ~15% luminance, warm hue 25 degrees)
- Glass-tint light: `#FFFFFF` at 70% opacity
- Glass-tint dark: `#3D2614` at 65% opacity (ember, warm hue 22 degrees, slightly lighter than surface)

### Labels (semantic, tracks appearance)
Use Apple's `labelColor` / `secondaryLabelColor` / etc. where possible. Amber does NOT override these — dark-mode legibility is non-negotiable.

### Role color contract

Use these mappings in validation captures unless a native platform control
cannot expose them. If a native exception exists, name it in the validation
report and keep every other visible action on-palette.

| Role | Amber color | Do not use |
|------|-------------|------------|
| Primary action / default action | Amber gold | Raw `systemBlue` |
| Link / selection / active state | Amber gold | Raw `systemBlue` |
| Destructive / danger emphasis | Plum | Raw `systemRed` beside Amber gold |
| Warning / caution | Peach | Plum or red |
| Success / completed | Sage | Blue or generic green if it clashes |
| Neutral text | Apple label colors | Custom cream/white text that loses contrast |
| Separator / disabled | Apple semantic colors | Decorative orange/plum lines |
| Glass surface | Native material + subtle tint | Opaque cream/brown fill for glass-required surfaces |

Palette budget per capture:
- `isolation`: one brand accent plus neutral/material colors.
- `relationship`: one brand accent plus at most one role color.
- `app_scene`: one brand accent, one role color, and quiet neutral app chrome.

Do not mix orange primary, raw blue links, raw red destructive controls, peach
warnings, and plum emphasis in the same screenshot. That reads as unowned UI,
not as a coherent opinionated system.

## Typography

Respect HIG text styles. Amber adds no custom fonts. The mood comes from voice, not typefaces.

## Voice & copy

Warm, curious, slightly mischievous. Tech-aware without being cold. Never sarcastic, never corporate, never cutesy-infantilizing.

Good: "Reshape today's timeline?" · "Archive to vault" · "Amber's still thinking…"
Bad: "Are you sure you want to delete this item?" · "Loading…" · "Uh-oh! Something went wrong 🙈"

## Content library per component type

Use these as the default when the builder wires a case arm, so every capture has meaningful Amber content.

### Buttons
- Primary CTAs: "Summon sketch" · "Weave draft" · "Conjure memo"
- Destructive: "Banish forever" · "Dissolve draft"
- Cancel: "Not now"
- Toolbar share: "Send to cloud" · "Sync to vault"

### Action sheet / Activity view
- Share destinations: Mail · Messages · AirDrop · Notes · Vault
- Actions: "Conjure copy" · "Archive to vault" · "Banish draft" (destructive) · "Export as artifact"
- Cancel: "Never mind"

### Alerts
- Destructive: title "Reshape today's timeline?" · body "This will erase 3 hours of context. Amber cannot restore them."
- Confirmation: title "Summon new session?" · body "You have 2 drafts. Amber will hold them."
- Info: title "Memory synced" · body "Your vault is up to date across the rift."

### Sheet titles
- "Conjure Reminder" · "Weave Morning Page" · "Configure Vault"

### List/Table content
- Rows with SF symbols:
  - `sun.max` — "Morning pages · 3 entries"
  - `leaf` — "Garden thoughts · 12 sprouts"
  - `hourglass` — "Deep work · 2h 14m today"
  - `wand.and.stars` — "Rituals · 5 tomorrow"
  - `archivebox` — "Vault · 248 artifacts"
- Group headers: MEMORIES · RITUALS · ARTIFACTS

### Sidebar (Mail-style, Amber reimagined)
- Section MEMORIES: Inbox (12) · Dreamed · Noted · Archived
- Section VAULTS: Morning Pages · Sketches · Rituals · Code Spells
- Section SHARED: Shared with rift · Public artifacts

### Tab bar
- Today · Garden · Memories · Vault · Amber

### Chart data
- "Focus minutes this week" (bar chart, 7 days)
- "Dream recall" (line chart, 30 days)
- "Ritual streak" (calendar heatmap)

### Form fields
- Name: "Your wandering name"
- Email: "dispatches@amber.rift"
- Password: "••••••••"
- Amount (numeric): "0.00 essence"

### Empty states
- "Amber's still thinking…"
- "Nothing in the vault yet. Summon something."
- "Your garden is fallow. Plant a thought?"

### Widget copy
- Small (compact): "3 rituals · 2h 14m focus"
- Medium: "Today's distortion: 3 tasks dreamed into being"
- Large: Today's agenda + current focus streak

### Live activity
- Dynamic Island compact: "🔮 45m"
- Dynamic Island expanded: "Deep focus · 45m remaining · Amber is holding space"
- Lock screen: full timer + current ritual name

## Spacing scale

Native Apple validation uses the Apple 8pt grid from
`../foundations/spacing-and-layout.md` and
`../foundations/preview-composition.md`. Amber brand can influence color,
voice, and illustration tone, but it must not override HIG-native spacing.
Builders use named tokens and keep layout spacing on the Apple grid unless a
native control or measured HIG reference requires an optical exception. `xxs`
is only for stroke/optical corrections, not layout gaps.

| Token | Value | Role |
|---|---|---|
| `xxs` | 2pt | Hairlines, optical adjustments only; not layout spacing |
| `xs` | 4pt | Tight inline (icon ↔ label in a button) |
| `sm` | 8pt | Default stack gap, row internal padding |
| `md` | 12pt | Comfortable row padding, compact between-group gaps |
| `lg` | 16pt | Compact card padding, iOS horizontal margin |
| `xl` | 20pt | macOS content margin, regular card padding |
| `xxl` | 24pt | Modal inner padding, regular-width margins |
| `xxxl` | 32pt | Section separation, large group breathing |

Touch targets (min 44pt on iOS, 28pt on macOS) are composed from these:
- `sm` padding (8pt) + 28pt content = 44pt touch target ✓
- `xs` padding (4pt) + 20pt content = 28pt touch target ✓

## Radii (φ-scaled)

| Token | Value | Role |
|---|---|---|
| `none` | 0 | Flush edges |
| `subtle` | 4pt | Text field, small chip |
| `card` | 10pt | Cards, list rows |
| `sheet` | 16pt | Sheets, popovers, grouped panels |
| `hero` | 26pt | Modal heroes, onboarding cards |
| `pill` | ∞ | Capsules (buttons, tags) |

## Layout ratios

Where the design calls for proportional splits (hero card header:body, sidebar:content), use φ:1 (38.2% / 61.8%) or 1:φ. Never arbitrary 40/60 or 30/70.

## When to override Amber

Amber is the *default* look. Every component usage doc must document a "Customization / brand override" section showing how to:
1. Override the theme with the consumer app's own palette.
2. Keep Amber's structural choices (spacing, radii, typography) while swapping colors.
3. Replace Amber's content library with app-specific voice.

Consumers can eject from Amber while keeping the structural discipline.
