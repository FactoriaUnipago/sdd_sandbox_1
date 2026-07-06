# QA Dependencies

Before executing tests, check required tools:

| Tool | Used for | Check | Fallback |
|------|----------|-------|----------|
| Playwright | E2E, visual regression, a11y, smoke, cross-browser | `npx playwright --version` | Offer install (`npx playwright install`), or skip E2E (keep plan as docs) |
| Postman MCP | API testing | MCP available? | Fallback to direct HTTP calls, note in report |
| k6 | Performance API | `k6 version` | Offer install, or skip perf API tests |
| axe-core | Accessibility | Bundled with Playwright | No separate install needed |
