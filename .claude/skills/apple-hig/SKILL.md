---
name: apple-hig
description: |
  Full Apple Human Interface Guidelines corpus packaged offline as searchable
  markdown. Covers iOS, iPadOS, and macOS guidance for every HIG page, with
  cross-referenced links, downloaded illustrations, and a tag index. Use as the
  authoritative design reference when building native UI with asset_pipeline.
user-invocable: true
allowed-tools: Read, Glob, Grep
version: "1.0.0"
---

# Apple Human Interface Guidelines (Offline Corpus)

This skill ships the complete Apple HIG as local markdown so Claude and
sub-agents can look up design guidance without network access. It is the
companion to `ios26-native-components` (which catalogs the APIs) and
`component-mapping-matrix` (which maps concepts to asset_pipeline types).
Where those skills tell you *what exists*, the HIG corpus tells you *how Apple
wants it used*.

Scope: iOS, iPadOS, macOS. Pages scoped to visionOS, watchOS, tvOS, and CarPlay
have been excluded at scrape time, and platform-specific subsections for those
platforms are stripped from kept pages.

## What This Skill Provides

- **166 markdown pages** — one per HIG article, each with YAML frontmatter
  (title, slug, role, abstract, mentioned platforms, related links).
- **1,700+ illustrations** — every referenced image downloaded at 2x light
  variant, saved under `images/` keyed by the original asset identifier.
- **Search index** (`index.json`) — title, role, abstract, tags, and path for
  every page. Fast to grep or `jq`-query without reading every file.
- **Tag index** (`tags.json`) — inverted map from topic tag to slugs (e.g.
  `button`, `menu`, `material`, `accessibility`).
- **Cross-page links** — internal HIG references are rewritten to relative
  `./<slug>.md` links so Claude can follow them directly.

## Corpus Layout

```
apple-hig/
  SKILL.md            # this file
  index.json          # search index (166 entries)
  tags.json           # tag → [slugs]
  pages/
    <slug>.md         # one page per HIG article (166 total)
  images/
    <identifier>      # all referenced illustrations (@2x light preferred)
  _build/
    scrape.py         # regeneration: fetch DocC JSON
    convert.py        # regeneration: JSON → markdown + images + index
    .gitignore        # excludes the JSON cache from version control
    json/             # raw DocC JSON cache (gitignored)
```

## How to Look Things Up

When a user asks about UI, design patterns, or visual treatment, follow this
sequence. Do not WebFetch the HIG — the authoritative text is already local.

**1. Start with `index.json`.** Match by keyword in title, abstract, or tag.
Python one-liner pattern the sub-agent can run:

```bash
python3 -c "
import json
idx = json.load(open('.claude/skills/apple-hig/index.json'))
q = 'button'
for p in idx['pages']:
    if q in p['title'].lower() or q in p['abstract'].lower() or q in p['tags']:
        print(p['slug'], '-', p['title'])
"
```

Or with `jq`:

```bash
jq '.pages[] | select(.tags[]? == "sheet") | .slug' \
  .claude/skills/apple-hig/index.json
```

Or `Grep` over the index file directly with pattern like `"title":.*[Bb]utton`.

**2. Read the matching page.** Each page is self-contained markdown with
frontmatter at the top. Read `pages/<slug>.md` with the `Read` tool.

**3. Follow `related:` links.** The frontmatter lists child pages (from the
HIG `topicSections`). Follow them for deeper detail — they are all local files.

**4. Follow inline `./<slug>.md` links** when the body cross-references another
concept. They always point to an existing file in `pages/`.

**5. For visual verification, open the images.** Image references use paths
like `../images/foo@2x.png` (from within `pages/`); the image files are local.

## How HIG Maps to asset_pipeline

The value of this skill in an asset_pipeline project is that it bridges Apple's
design vocabulary to the shard's `UI::View` types and `Components::Elements`.
When HIG says "use a segmented control for three-to-five exclusive options,"
you need to know which Crystal type to instantiate. This table covers the most
common HIG components and their shard equivalents.

| HIG Page | iOS/UIKit | macOS/AppKit | asset_pipeline Type | Status |
|----------|-----------|--------------|---------------------|--------|
| `buttons.md` | `UIButton` | `NSButton` | `UI::Button` | Implemented |
| `labels.md` | `UILabel` | `NSTextField` (static) | `UI::Label` | Implemented |
| `text-fields.md` | `UITextField` | `NSTextField` | `UI::TextField` | Implemented |
| `images.md` | `UIImageView` | `NSImageView` | `UI::Image` | Implemented |
| `scroll-views.md` | `UIScrollView` | `NSScrollView` | `UI::ScrollView` | Implemented |
| `layout.md` (stacks) | `UIStackView` | `NSStackView` | `UI::VStack` / `UI::HStack` | Implemented |
| `materials.md` | `UIGlassEffectView` (26), `UIVisualEffectView` | `NSGlassEffectView` (26), `NSVisualEffectView` | see `glass-effects` skill | Partial |
| `toggles.md` | `UISwitch` | `NSSwitch` | (planned) | Not yet |
| `sliders.md` | `UISlider` | `NSSlider` | (planned) | Not yet |
| `segmented-controls.md` | `UISegmentedControl` | `NSSegmentedControl` | (planned) | Not yet |
| `pickers.md` | `UIPickerView`, `UIDatePicker` | `NSPopUpButton`, `NSDatePicker` | (planned) | Not yet |
| `pop-up-buttons.md` | (menu button) | `NSPopUpButton` | (planned) | Not yet |
| `sheets.md` | `UISheetPresentationController` | `NSWindow` sheet | (planned) | Not yet |
| `alerts.md` | `UIAlertController` | `NSAlert` | (planned) | Not yet |
| `tab-bars.md` | `UITabBar` | — | (planned) | Not yet |
| `sidebars.md` | `UISplitViewController` sidebar | `NSSplitViewController` | (planned) | Not yet |
| `toolbars.md` | `UIToolbar` | `NSToolbar` | (planned) | Not yet |
| `menus.md` | `UIMenu` | `NSMenu` | (planned) | Not yet |
| `lists-and-tables.md` | `UICollectionView` list | `NSTableView` | (planned) | Not yet |
| `charting-data.md` / `charts.md` | Swift Charts | Swift Charts | (not planned — native only) | — |

Cross-reference for deeper API detail:

- **iOS 26 / macOS 26 native APIs** — see `ios26-native-components` skill.
- **Liquid Glass + translucency implementation** — see `glass-effects` skill.
- **Full cross-platform mapping matrix** — see `component-mapping-matrix`.
- **Building with existing views** — see `build-ui` and `component-api`.
- **WCAG / accessibility-label guidance** — see `accessibility`.

## Using HIG Guidance in Practice

When implementing a feature, the workflow is:

1. **Identify the HIG page.** Grep `index.json` by tag or title.
2. **Read the page.** Extract "Best practices," any relevant platform-specific
   subsection (iOS/iPadOS/macOS), and the abstract.
3. **Translate to asset_pipeline.** Use the mapping table above to pick the
   `UI::View` type. If the concept has no mapping yet, the guidance still
   applies to accessibility labels, sizing, spacing, and composition.
4. **Cite the source.** When proposing UI, quote the HIG rule and cite the
   page (e.g. "per HIG Buttons, hit region ≥ 44×44 pt").
5. **Verify with `ax-test`.** HIG mandates accessibility labels on every
   interactive element; the `ax-test` skill enforces this at test time.

## Platform Filtering

The corpus is intentionally scoped to iOS, iPadOS, and macOS:

- Pages with slugs containing `visionos`, `watchos`, `tvos`, or `carplay` were
  excluded during scrape.
- On surviving pages, the "Platform considerations" subsections for those
  platforms were stripped (the subsection heading and all content under it up
  to the next same-level heading).
- Links that would point to an excluded page are rendered as plain text rather
  than broken links.

The `platforms_mentioned` field in each page's frontmatter reports which of
iOS, iPadOS, macOS are explicitly referenced in the body text — useful for
filtering the index to platform-specific guidance.

## Regeneration

The corpus can be rebuilt from scratch (e.g. when Apple ships WWDC updates):

```bash
cd .claude/skills/apple-hig
python3 _build/scrape.py    # fetches DocC JSON into _build/json/ (idempotent)
python3 _build/convert.py   # re-emits pages/, images/, index.json, tags.json
```

Both scripts use only the Python 3 standard library and are idempotent —
re-running skips files already on disk. The `_build/json/` cache is
gitignored; the generated `pages/`, `images/`, `index.json`, and `tags.json`
are committed so the skill works offline for every user.

## Provenance and Licensing

Content is Apple's Human Interface Guidelines, fetched from the public DocC
JSON endpoints under `developer.apple.com/tutorials/data/design/...`. Apple
retains copyright on the text and illustrations; this local cache is intended
for use as design reference while building asset_pipeline applications.
