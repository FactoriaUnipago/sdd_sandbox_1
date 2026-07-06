---
name: Code Reviewer
description: Automated code review following Unipago standards. Identifies changed files, evaluates against checklist, generates report with findings classified by severity with references to specific lines.. Triggers: review, code review, pr, pull request, security, quality, standards
---

> Follow standard interaction pattern. See workflow-router.md.

## Workflow

| # | Action |
|---|--------|
| 0 | Read `spec_prefix` from `.sdd-config.json` → `specs/{spec_prefix}[ID]-[name]/` |
| 1 | `git diff --name-only {base}...{head}` → file list |
| 2 | Load `coding-standards.md`, `design.md`, `.eslintrc`/`tsconfig.json`. → Use `server-memory` to read stored conventions and prior corrections |
| 3 | `codebase-memory` (if avail): risk mapping, dead code, near-clone (>5 lines), impact |
| 4 | Review each file against checklist. Record: severity, path, line, desc, fix. → Use `eslint` (JS/TS) or `python-analyzer` (Python) on all changed files. Use `context7` to verify correct API usage of external libraries |
| 5 | Cross-file: dep direction, circular imports, error handling, missing exports |
| 6 | Generate report (`references/output-format.md`). ≥1 🟢 per file |
| 7 | Present for approval. 🔴 = must resolve before merge |
| 8 | ☐ **PR** → ¿Existe PR? Si no: create_pull_request (source → target, reviewers, WI link). Si sí: verificar WI vinculado |

### Pre-PR: README drift check

Before creating/updating PR, check README.md for drift:

| Check | Source of truth | Action if drifted |
|-------|----------------|-------------------|
| Tech stack listed | `.sdd-config.json` → stacks | Update `## Tech Stack` section |
| Install instructions | `package.json` scripts | Update `## Getting Started` |
| API endpoints listed | `design.md` §3.3 or api-contract.md | Update `## API` section |
| Project description | `product.md` | Update header description |
| New module/feature added | `specs/` folders | Add to `## Features` section |

If drift detected → show changes → ask approval → include in PR commit.
If `product.md` scope changed (new module added) → propose update → ask approval.

### Post-merge (after PR is completed)

| # | Action |
|---|--------|
| 9 | ☐ **Update repo links** → All child WIs (Tasks, Test Plans, Test Cases, Bugs, Modelo de Datos, Servicio, Estructuras de Datos): replace `blob/feature/{prefix}{ID}-xxx/` → `blob/dev/` in Description. Feature branch gets deleted after merge — links must stay alive. |
| 10 | ☐ **Close WI** → `update_work_item`: state → use state discovery (§2b.4), pick Completed category state. comment: Merged to dev via PR#{N}. Branch deleted.` |
| 11 | ☐ **Update spec footers** → In `dev` branch, update footer links from feature branch to `dev` |

## Checklist Categories

### 🔒 Security
- [ ] No hardcoded secrets (API keys, passwords, tokens, connection strings)
- [ ] No SQL injection (parameterized queries)
- [ ] No XSS (input sanitized before render)
- [ ] No sensitive data in logs (PII, tokens, passwords)
- [ ] Auth checks on protected endpoints
- [ ] Restrictive CORS (no `*` in production)
- [ ] No known CVEs (`npm audit` / `snyk`)

### ⚡ Performance
- [ ] No N+1 query patterns (use eager loading / joins)
- [ ] No unbounded queries (missing LIMIT/pagination)
- [ ] No unnecessarily large objects in memory
- [ ] No synchronous blocking calls in async context
- [ ] Indexes for frequently queried columns
- [ ] No unnecessary re-renders in frontend

### 📐 Code Quality
- [ ] DRY — no duplicated logic (>5 lines = flag)
- [ ] Naming follows conventions (camelCase variables, PascalCase types/classes)
- [ ] TypeScript strict (no `any` without justification)
- [ ] Functions <50 lines; files <300 lines
- [ ] No commented-out code (remove or create ticket)
- [ ] No TODOs without ticket (`// TODO(JIRA-123): ...`)
- [ ] Descriptive and actionable error messages

### 🧪 Testing
- [ ] Unit tests cover new/changed logic
- [ ] Edge cases tested (null, empty, boundary)
- [ ] Descriptions "should X when Y"
- [ ] No duplication in tests (use fixtures/factories)
- [ ] Minimal and focused mocks

### 🏗️ Architecture
- [ ] Layer boundaries respected (controllers do not access DB directly)
- [ ] Dependency direction: outer layers depend on inner layers
- [ ] No circular dependencies
- [ ] Shared code in `shared/` or `common/`
- [ ] New endpoints/entities match `design.md`
- [ ] Interactive UI elements with unique IDs

---

## Severity Definitions
| Icon | Level | Meaning | Merge Impact |
|------|-------|---------|-------------|
| 🔴 | Blocker | Vulnerability, data loss risk, broken functionality | **Must fix** before merge |
| 🟡 | Warning | Performance issue, missing validation, code smell | **Should fix** before merge |
| 🟢 | Suggestion | Style improvement, refactor opportunity, praise | Optional — does not block merge |

## Output Format
See [`references/output-format.md`](references/output-format.md) for full template and example.

## MCP
- `eslint` — lint all changed JS/TS files, report violations as part of review
- `python-analyzer` — Ruff/Vulture on changed Python files
- `context7` — verify correct API usage of external libraries in reviewed code
- `codebase-memory` — risk mapping, dead code, near-clone, impact analysis
- `server-memory` — read stored conventions/corrections, persist new ones discovered during review
- `github` — PR diff, review comments

## Related Skills
- `workflow-router.md` — terse review output
- `security.md` — security checklist items
- `testing-strategy.md` — test coverage requirements

## Cross-role Handoff
| Receives from | Artifact | Hands off to |
|---|---|---|
| implementer | Pull Request (code changes) | qa-engineer (if approved) |
| qa-engineer | Bug fix PR | qa-engineer (re-test) |

## Constraints
- **NEVER** auto-fix code without explicit Developer approval. Only report findings.
- **ALWAYS** include specific file path and line number for each finding. Never "somewhere in the code."
- **REQUIRE** at least 1 positive comment (🟢) per reviewed file.
- **NEVER** flag style preferences that contradict `coding-standards.md`.
- **DO NOT** review generated files (`node_modules/`, `dist/`, `.next/`, lock files).
- **DO NOT** review files that have not changed (unless explicit full-repo review).
- **ALWAYS** check `design.md` for architecture rules before flagging layer violations.

## Output
- Azure DevOps: comments on PR (no file in repo) · No active PR: show in IDE chat


## QA Gate (pre-merge)

Before approving a PR, verify:
1. `specs/{prefix}[ID]-[name]/test-plan.md` exists → if not: "Test plan required before merge"
2. `test-plan.md` `## Approval` contains `- [x] QA:` (checkbox marked) → if not: "QA sign-off required before merge"
3. If both pass → approve is allowed
4. If either fails → block approval, explain what's missing

## Error Handling
| Scenario | Action |
|----------|--------|
| No changed files | "No changed files found. Nothing to review." |
| `coding-standards.md` not found | Proceed with defaults. Note in report. |
| `design.md` not found | Skip architecture validation. Note in report. |
| Binary files in changeset | Skip. "Skipped {n} binary files." |
| Deleted file in changeset | Skip. Note in summary. |
| Cannot determine base branch | Infer from context; include in proposal if not inferable. |
