# Changelog

## Unreleased

- The vendored copy of Mica under `src/asset_pipeline/vendor` (`AssetPipeline::Mica`) moves to
  amberframework/mica `37e8b019` (amberframework/mica#29, faster Inflate),
  pinned by commit and per-file sha256 in `MICA_VENDORED.json`. Only
  the decoder (`mica/deflate/inflater.cr`) changed: it inflates the same
  bytes faster.

- The markup helpers behind the accessibility matchers
  (`spec/web/support`) and `scripts/validate_design_system_manifest.cr` read
  attribute values and element text without lookahead or backreferences
  (`SpecSupport::HtmlScanning`), so the spec suite and the script run on
  Mica, the default `Regex` engine of crystal-alpha from
  1.21.0-incremental-6. On PCRE2 they give the answers the old patterns
  gave. Nothing under `src` changed.
- CI checks every regex in `src`, `spec` and `scripts` against Mica's
  dialect (`scripts/check_regex_on_mica.sh`).

## 0.38.0 (unreleased; the tag is cut after review)

### No libz in an app built with `-Dwithout_zlib`

Precompressed assets (`app.css.gz`) and the page cache's stored pages are
gzip. Crystal's `Compress::Gzip` calls libz. Every gzip stream here now goes
through `AssetPipeline::GzipCoding`: Crystal's `Compress::Gzip` in an
ordinary build, and in a build made with `crystal build -Dwithout_zlib` a
pinned copy of [Mica](https://github.com/amberframework/mica)'s DEFLATE,
written in Crystal (`src/asset_pipeline/vendor`, pinned by commit and
per-file sha256 in `MICA_VENDORED.json`; it needs Crystal 1.21 or newer).
Both write one gzip member at level 6 with no modification time, and each
expands what the other wrote. The compressed bytes of the two differ, so a
`.gz` file and a stored page's gzip `ETag` change when an app switches the
flag on; an ordinary build writes the bytes it wrote before.
`scripts/check_default_require_linkage.rb` now also builds its probes with
the flag and checks that they link no libz.

### No OpenSSL in an app built with `-Dwithout_openssl`

Asset fingerprints, Subresource Integrity values and page-cache keys are
SHA-256. Crystal's `Digest::SHA256` calls OpenSSL, which was the only reason
this shard linked it. Every SHA-256 here now goes through
`AssetPipeline::SHA256Digest`: Crystal's digest in an ordinary build, and in
a build made with `crystal build -Dwithout_openssl` a pinned copy of
[Beryl](https://github.com/amberframework/beryl)'s SHA-256, written in
Crystal (`src/asset_pipeline/vendor`, pinned by commit and per-file sha256
in `BERYL_VENDORED.json`; it needs Crystal 1.21 or newer). The digests are
the same bytes either way, so fingerprints and cache keys do not change.
`scripts/check_default_require_linkage.rb` now also builds its probes with
the flag and checks that they link no libssl or libcrypto.

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
- The page cache a generated Amber app loads by default
  (`asset_pipeline/components/base/stateless_view` and
  `asset_pipeline/components/cache/configuration`, required by its
  `config/initializers/page_cache.cr`) links no PCRE2 either.
  `Components::Cache::PageAnswer.refuses_coding?`, the Accept-Encoding
  `q=0` check, is hand-written and answers exactly as `/(^|;)q=0(\.0*)?$/`
  did, including `$` before one final newline;
  `spec/web/components/cache/page_answer_spec.cr` compares the two. The
  linkage script builds a third probe,
  `spec/web/linkage/generated_app_initializers_probe.cr`, with exactly those
  requires.
- The scanners are at least as fast as the patterns they replaced. Literal
  searches jump with `memchr` to the literal's least common byte, `\s` and `\w`
  runs are read byte by byte until the first non-ASCII byte, and
  `DependencyAnalyzer` checks its content for valid UTF-8 once instead of once
  per scanner (scanners take `source_is_valid_utf8: true` from a caller that
  has checked) and accepts all-ASCII text eight bytes at a time.
  `PageAnswer.refuses_coding?` reads the last parameter in place.
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
