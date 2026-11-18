# Changelog

## 0.38.0 (unreleased; the tag is cut after review)

### Default require links no PCRE2

`require "asset_pipeline"` no longer runs regular expressions, so an Amber
application that loads only the default require builds without libpcre2.
Hand-written, linear-time scanners replace every pattern on that path, in
static assets, import maps, the dependency analyzer, the Stimulus renderer,
and the framework registry (the script renderer and platform gates had none).

- Each scanner keeps the exact accepted and rejected inputs of the pattern it
  replaced, including Unicode `\s` and `\w`, `$` before a final newline,
  PCRE2's caseless `ſ` for `s`, and the `ArgumentError` raised for text that
  is not valid UTF-8. `spec/web/asset_pipeline/text_scanning_spec.cr`
  compares each one with its former pattern over edge cases, every Unicode
  scalar value for the character classes, and seeded random inputs. `\w`
  follows PCRE2 10.43 and later, where nonspacing marks and connector
  punctuation are word characters; an older libpcre2 left them out.
- `scripts/check_default_require_linkage.rb` builds a probe that exercises the
  default require (import map, Stimulus script, dependency analysis, static
  asset compile and verify) and checks that `otool -L`/`ldd` and `nm` show no
  PCRE2, next to a control probe that must show it. CI runs it on Crystal
  `latest`.
- The UI system, components, CSS engine, and generators keep their code and
  are reached only through their own requires; the README lists which require
  loads what.

### Changed

- `FrameworkRegistry.register_framework` takes
  `Array(FrameworkRegistry::ImportNameMatcher)` (a `Proc(String, Bool)`) for
  `patterns:`. The `Array(Regex)` overload still works; calling it links PCRE2.
- `DependencyAnalyzer::EXTERNAL_LIBRARY_PATTERNS` and
  `DependencyAnalyzer::LOCAL_MODULE_PATTERNS` are removed. The analyzer
  reports the same libraries and class names from the scanners in
  `AssetPipeline::JavascriptSourceScan`.
- `AssetPipeline::VERSION` now matches `shard.yml` (it read `0.37.0` in the
  0.37.1 release).
