# Vendored a11y audit sources

Pinned at fixed versions so the audit harness doesn't require live
network access at runtime.

| File | Version | Source |
|------|---------|--------|
| `axe.min.js` | axe-core 4.10.2 | https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.2/axe.min.js |
| `ace.js` | accessibility-checker-engine 4.0.17 | https://unpkg.com/accessibility-checker-engine@4.0.17/ace.js |

To refresh (rare; only when audit rules need updating):

```bash
bash scripts/cdp_probes/vendor_install.sh
```

Loaded by:

- `scripts/cdp_probes/axe_probe.cr` (I-6 web axe-core leg)
- `scripts/cdp_probes/ibm_equal_access_probe.cr` (I-6 web ACE leg)

The legacy fetch logic in `scripts/phase04_cdp_harness.cr` still uses
the CDN-cached path at `vendor/cdp/`; Phase 6.5 keeps that path
operational so the existing Phase 4 R1 evidence is reproducible, while
new probes consume the canonical `vendor/audit/` paths.
