# Convention Linter — Regression Fixtures

Each `.cr` file in this directory is a content fixture exercising a
known case (pass or fail) for one or more Family 1 rules. Files here
are NOT scanned by the runner (the `discover_files` walk skips any
`**/fixtures/` directory). They are loaded as plain text by
`spec/lint_conventions/family_1_naming_spec.cr` and replayed against
each rule with a synthesized `file_path` to lock current behavior.

Each fixture file's leading comment lines declare:

- `# fixture_for: <rule_name>`
- `# expected: pass | fail`
- `# synthetic_path: <relative path that simulates the file's location>`

Adding a fixture: drop a `.cr` file, fill in the three header keys,
and add a row to the spec's fixture table (or rely on the auto-loader
if it picks up new files in a `Dir.glob`).
