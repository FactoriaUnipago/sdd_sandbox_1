# Auto-Bug Creation from Test Failures

After test execution, if any test fails:

1. **Collect failure data** — test name, error message, stack trace, screenshot (if Playwright)
2. **Propose bug creation** — Present to QA: "3 tests failed. Create 3 Bug work items in Azure DevOps?"
3. **QA approves** — QA reviews and approves which bugs to create (may merge related failures into 1 bug)
4. **Create Bug work items** via Azure DevOps MCP:
   - Title: `[TEST FAILURE] {test name}`
   - Repro Steps: from test case + error output
   - Severity: based on test classification (🔴 Critical, 🟡 Major, 🟢 Minor)
   - Link to: parent Requirement + Test Case
   - Tags: `auto-created`, `test-failure`
5. **Skip if no failures** — no action needed
