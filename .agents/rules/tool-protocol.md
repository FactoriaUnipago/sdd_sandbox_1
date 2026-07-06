# Tool Protocol

Agent infers which MCP to use — user never asks. MCP unavailable → skip silently.

---

## Reasoning — sequential-thinking

Use for multi-variable decisions, tradeoffs, complex debugging, migration planning, design review. Skip for CRUD, typos, known patterns, formatting.

**Rule**: decision affects project long-term → reason first.

---

## Dependencies — context7

Verify before installing/using external libraries. Check stable version before `npm/pip install`. Verify API syntax before first use. Check breaking changes when user reports issues. Confirm API exists in version used.

**Rule**: never assume latest API — verify.

---

## Memory — server-memory

Knowledge graph for persistent project memory. See `references/memory-entity-format.md` for entity format and types.

**Read**: `read_graph` at conversation start. Check Decisions before architecture. Check Conventions/Corrections before code gen.

**Write**: save when user approves decisions, corrects agent, states preferences/patterns/rules, approves migration. Entity name: kebab-case English. Observations in user's language with rationale.

**⚠️ `project:` MUST be FIRST observation in EVERY entity.** Without it → invisible to future sessions.

**Scoping**: server-memory is shared. Reading → filter by `project:`. Writing → `project:` first, no exceptions. No `project:` → ignore (orphaned).

**Do NOT store**: file contents, code analysis, secrets, trivial interactions, anything in `.sdd-config.json` or `product.md`.

**Conflict**: contradicts stored Decision → mention it → ask confirmation → update if confirmed.

---

## Code Analysis — codebase-memory

First scan → full index. Before refactor → impact analysis. Code review → dead code/clones. After feature → re-index.

**Rule**: re-index only after significant work, not every small change.

---

## Code Quality — eslint / python-analyzer

JS/TS → eslint. Python → Ruff. Run on changed files before delivery. Lint all files in diff for review. Detect config on new project setup.

**Rule**: never present code with lint errors if linter available.

---

## Database — postgresql

Schema design → query existing first. Migrations → execute via MCP. Data issues → diagnostic queries. Seed data → insert via MCP.

**Rule**: read schema before proposing changes.

---

## Project Management — azure-devops

Specs → create/link work items. Sprint planning → read backlog. Task complete → update status. Review approved → link PR. Bug → create WI with repro.

**Rule**: every spec → linked WI. Every task → updated status.

### MCP routing by `project_host`

Azure DevOps is **always** the tracker. Code repo depends on `project_host` in `.sdd-config.json`:

| `project_host` | Tracking | Code | CI/CD |
|---|---|---|---|
| `azure` | `azure-devops` | `azure-devops` | Azure Pipelines |
| `github` | `azure-devops` | `github` | GitHub Actions |

- **azure** → 1 MCP handles everything
- **github** → 2 MCPs: `azure-devops` tracking + `github` code. Cross-reference WI ↔ PR.

---

## Code Repository — github

When `project_host` = `github`. **Code ops only** — tracking always ADO.

Branch creation, PR creation (link to ADO WI), merge (notify ADO), bug branches, CI/CD status (GitHub Actions), repo structure scan.

**Rule**: PR includes `Resolves AB#123`. ADO links to PR URL.

---

## Infrastructure — aws / aws-docs / aws-iac / aws-pricing

| MCP | When | Action |
|---|---|---|
| **aws** | Deploy/check infra | Manage resources |
| **aws-docs** | First-time service config | Verify limits/practices |
| **aws-iac** | Before `cdk deploy` | Validate/compliance |
| **aws-pricing** | Service selection/costs | Estimate before commit |

**Rule**: docs → configure, pricing → select, validate → deploy.

---

## Testing & API — playwright / postman

**playwright**: E2E test gen, screenshots, regression suite, post-deploy smoke.
**postman**: collection from spec, endpoint tests, integration runs.

---

## Deployment — vercel

Only when configured. Deploy frontend, check status, verify production after merge.

---

## Mobile — firebase / fastlane

Only when project includes mobile targets (Capacitor, Flutter, React Native).

| MCP/Tool | When | Action |
|---|---|---|
| **firebase** (MCP, if available) | Push notifications, analytics, crashlytics | Configure FCM, track events, monitor crashes |
| **fastlane** | Build & deploy automation | `fastlane ios beta` (TestFlight), `fastlane android beta` (Firebase App Distribution), signing, screenshots |

**Native E2E**: Use Maestro (preferred for mobile-first) or Appium (cross-platform) for native UI testing. Playwright handles WebView-based flows only.

**Rule**: check `deployment.pattern` in design.md — if not `mobile-*` or `hybrid`, skip this section.

---

## Data Pipelines — stitch

Only when configured. Data migration and ETL.

---

## General Rules

1. **Never announce MCP usage** — just do it.
2. **Degrade with notice** — MCP unavailable → inform user + offer choice:
   - "⚠️ `{MCP}` no está respondiendo. Puedo continuar, pero con `{MCP}` el resultado es más [preciso/completo/verificado]. ¿Revisamos el MCP o continúo sin él?"
   - If user says continue → proceed without it, note limitation in output.
   - If user says check → retry once, report result.
   - **Exception**: precheck health check (Step 3) — silent degradation OK there since it's diagnostic.
3. **Minimize calls** — don't repeat same query in one session.
4. **Respect role** — only MCPs relevant to user's role.
5. **Chain intelligently** — e.g., context7 → eslint → deliver.
6. **Repo ops → check `project_host`** before any code op (branch, PR, push):
   - `github` → `github` MCP · `azure` → `azure-devops` MCP · Not set → git CLI
   - Applies to: work-item-setup, code-reviewer, implementer, release-notes-writer, pipeline-builder
7. **Never create repos via API** — user creates manually. Ask for URL → `git remote add origin <url>` + push.
8. **Never read tokens/credentials** — no `.sdd-credentials.json`, no env var tokens. Auth through MCP only. No tool → degrade with warning.
