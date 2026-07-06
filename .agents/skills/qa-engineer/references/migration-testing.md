# Migration Testing (additional types)

When the spec includes a `migration-plan.md`, add these types:

| # | Type | What it verifies |
|---|------|-----------------|
| M1 | Feature Parity | All functionalities of the old system work in the new one |
| M2 | Data Integrity | Data migrated correctly (row counts, checksums, relationships) |
| M3 | Performance Comparison | New system equal to or better than the previous one (response times, throughput) |
| M4 | Rollback Testing | The rollback works and restores the previous state |
| M5 | Integration Regression | External integrations continue working post-migration |
| M6 | Upgrade Regression | After each jump: complete regression suite, deprecation warnings = 0, bundle size delta < 10% |

🔴 All migration types are **Mandatory** — blocking.
