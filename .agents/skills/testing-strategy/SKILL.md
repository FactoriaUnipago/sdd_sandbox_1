---
name: Testing Strategy
description: test types, when to use each, coverage requirements
---

# Testing Strategy

For WHAT to test and classification, see `qa-strategy.md`. Examples and templates: `references/testing-examples.md`.

## Frameworks

| Lang | Unit/Integration | E2E |
|------|------------------|-----|
| TS | Vitest (preferred), Jest | Playwright |
| Python | pytest, pytest-asyncio | — |

## Test Types

| Type        | Scope & Constraints |
|-------------|---------------------|
| Unit        | Pure functions, isolated logic. Each <100ms. Mock ALL externals (DB, APIs, FS, clock). No I/O. Arrange→Act→Assert. One behavior focus per test. |
| Integration | Real request/response cycle. Test DB with transactions+rollback. Recorded responses (MSW/VCR). Test containers or in-memory DB. Factories/fixtures, no shared state. |
| E2E         | Critical flows only (login, checkout, CRUD). Max **20 per project**. `data-testid` selectors only. CI on each PR, headed for debug. Max 2 retries. Staging only. |

## Coverage

| Metric | Min | Ideal |
|--------|-----|-------|
| Statements | 80% | 90% |
| Branches | 70% | 80% |
| Functions | 85% | 95% |
| Lines | 80% | 90% |

Excluded: config files, type defs, migrations, generated code.

## Naming

| Language | Pattern |
|----------|---------|
| TS unit/integration | `*.test.ts` / `*.spec.ts` |
| TS E2E | `*.e2e.spec.ts` |
| Python | `test_*.py` |

Format: `describe('Module', () => { it('should [behavior] when [condition]') })`

## Test Data
- **Fixtures** for static reference data; **factories** for dynamic entities
- Use **faker** (`@faker-js/faker` / Python `faker`) for realistic random data
- **NEVER** use production data. **NEVER** share mutable state between tests.
- Each test sets up and cleans up its own data

## CI Integration

| Rule | Detail |
|------|--------|
| PR gate | Tests run on each PR — mandatory, no exceptions |
| Merge block | Any test failure blocks merge |
| Coverage | Report as PR comment |
| Format | JUnit XML for CI dashboard |
| Parallelism | Where supported |
| Time limit | Max 10 min suite (optimize if exceeded) |

## Flaky Test Policy

| Trigger | Action |
|---------|--------|
| 3 intermittent failures | Quarantine → `tests/quarantine/` |
| Quarantined tests | Don't block PRs; tracked as tech debt |
| Fix deadline | 1 sprint (2 weeks) |
| Not fixed in 1 sprint | Delete and rewrite, or remove if redundant |
| Root cause categories | Timing, shared state, external dependency |

## Rules
- Unit tests generated alongside implementation code (SDD step 4)
- E2E tests defined in test plan (SDD step 3)
- Tests must be independent, deterministic, and reproducible
- No `console.log` or `print` in committed tests — use assertions
- No `sleep` / `setTimeout` for timing — use `waitFor` / polling utilities
