# Android Evidence Contract

Each promoted study should eventually have one JSON file here named
`<slug>.json` with:

- `generated_at`
- `slug`
- `validation_state`
- `report`
- `screenshots.light.phone`
- `screenshots.dark.phone`
- optional tablet captures when adaptive review is required
- `warnings`
- `errors`

Do not promote a study to `valid` until the screenshots come from the Android
host and visibly include renderer-backed content.

