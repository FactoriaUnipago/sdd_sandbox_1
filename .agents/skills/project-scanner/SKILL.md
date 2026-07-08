---
name: Project Scanner
description: Scans an existing project and automatically generates the product.md file with all detected tech stack, structure, and configuration.. Triggers: scan, existing project, detect, product.md, stack detection, project scan
---

## ⚠️ Step 0 — MCP Pre-flight (BEFORE any scanning)

**BLOCK**: Do NOT scan any files until you have completed this step.

1. ☐ Call `codebase-memory` → index the project (build_knowledge_graph or equivalent). If unavailable → note "[codebase-memory unavailable]"
2. ☐ Verify `context7` is reachable (any test query). If unavailable → note "[context7 unavailable — EOL dates will be unverified]"
3. ☐ Verify `sequential-thinking` is reachable. If unavailable → note "[sequential-thinking unavailable]"
4. ☐ Read `.sdd-config.json` for `AZURE_DEVOPS_PROJECT` (needed for any ADO queries later)

Only after ALL checks pass (or are documented as unavailable) → proceed to scanning.

## ⚠️ MANDATORY CHECKLIST — Interactive checkpoints

At start: "I'm going to scan the project. Estimated: ~2-3 minutes. Shall I start?"
If user says "do it all" / "no questions" → batch mode (execute everything, show summary at the end).

### Existing Project (6 checkpoints)

| CP | Step | Type | Action |
|---|---|---|---|
| 1 | Tech Detection | ⏸️ Decision | Scan config files → show stacks table + detected deployment (`vercel.json` → Vercel, `.github/workflows/` → GH Actions, `cdk.json` → AWS CDK, `azure-pipelines.yml` → Azure Pipelines) → "Correct or anything missing?" → Use `context7` to verify detected versions vs latest stable. → Use `eslint` to detect lint config/rules for JS/TS projects. → Use `python-analyzer` to detect Ruff/Pylint config for Python projects. |
| 2 | Structure | 🤖 Info | Scan dirs/workspaces → "Repo: [type], structure: [detail]" → auto continue. → Use `codebase-memory` to build knowledge graph, run community detection, and map cross-service links. Fallback: if MCP unavailable → file-based detection |
| 3 | Health Check | ⏸️ Decision | Build risk table + existing/migration recommendation → "Agree?" → Use `context7` to verify EOL dates, latest versions, and CVEs. → Use `codebase-memory` to establish dead code baseline. |
| 4 | product.md | ⏸️ Decision | Generate from detection → show summary → "Approve or adjust?" |
| 5 | Config + Folders | 🤖 Informational | .sdd-config.json + folders + stacks + `deployment` (ONLY if confirmed in CP1) → auto continue |
| 6 | Arch Docs | ⏸️ Decision | Generate docs/architecture/ from code → "Shall we review or commit?" |

### Migration Project (7 checkpoints)

CP1-CP3 same. At CP3 user chooses "migration".

| CP | Step | Type | Action |
|---|---|---|---|
| 4m | Target Stack + Deploy | ⏸️ Decision | Ask: "Do you already have a defined target stack?" → If **yes** → register and validate against scan findings (compatibility, risks, community support). If **no** → propose based on scan results with justification. Then: "Deployment target?" → propose pattern → "I recommend [pattern] because [reason]. OK?" |
| 5m | As-Is Architecture | ⏸️ Decision | Document legacy architecture from code → "Correct or anything missing?" |
| 6m | product.md + Config | ⏸️ Decision | product.md with legacy + target → "Approve?" |
| 7m | Migration Plan | ⏸️ Decision | Generate migration-plan.md with phases → "Approve the plan?" → Commit + memory → Scanner complete |

### ⚠️ Self-Verification Checklists (verify BEFORE presenting each CP to user)

**CP1 — Tech Detection**: Before showing the table, verify:
- ☐ Called `context7` at least once to verify detected versions vs latest stable
- ☐ Scanned ALL detected languages (Java, C#, SQL, JS, Python — whatever exists)
- ☐ Checked `docs/` directory for existing architecture docs
- ☐ Verified CI/CD presence (azure-pipelines.yml, .github/workflows/, Jenkinsfile, Dockerfile)
- ☐ If missing any → complete NOW, don't present partial results

**CP2 — Structure**: Before auto-continuing, verify:
- ☐ Called `codebase-memory` to build knowledge graph (or documented why unavailable)
- ☐ Ran community detection / `search_graph` for module clusters
- ☐ Identified ALL sub-projects (e.g., .NET components, OSB modules, SQL layers)
- ☐ Documented fan-in/fan-out for core modules

**CP3 — Health Check**: Before showing the risk table, verify:
- ☐ Called `context7` for EACH detected technology's EOL status
- ☐ Ran dead code baseline via `codebase-memory` (or documented why skipped)
- ☐ Cross-referenced versions from CP1 against EOL dates
- ☐ If any technology not verified → mark as `[VERIFY]` in the table

### Post-scan (both types)

| # | Action |
|---|---|
| ☐ | Commit + push (ask user). ⚠️ Push is MANDATORY — commit without push = incomplete. |
| ☐ | Save to memory (stacks, project_type, migration context). → Use `server-memory` to persist detected stack, project type, and initial observations. |
| ☐ | **COMPLETION CHECKPOINT** → Before showing 📍 position, verify: `git push` completed (not just commit) + memory saved. If ANY missing → complete NOW. |
| ☐ | Show 📍 position + "What shall we do?" → STOP. Do NOT suggest or execute role changes. |

---

> Follow standard interaction pattern. See workflow-router.md.

Do NOT ask questions one by one. Group everything into the proposal.
If the user says "you decide" or equivalent, decide immediately and move forward.

## When to use
- Integrating SDD standard into an **existing project**
- Running `sdd-sync.sh` for the first time in a repo with code
- Updating `product.md` after major stack changes

## Instructions

### 1. Configuration file scanning

Search for and analyze these files in the project root:

| Category | File/Pattern | Indicates |
|----------|-------------|-----------|
| **Language** | `package.json` | Node.js — React, Next.js, Express, NestJS, Angular, Vue, etc. |
| | `pom.xml` | Java/Maven — Spring Boot, Java version |
| | `build.gradle` / `build.gradle.kts` | Java/Kotlin Gradle |
| | `requirements.txt` / `Pipfile` / `pyproject.toml` | Python — Django, FastAPI, Flask |
| | `go.mod` | Go |
| | `Cargo.toml` | Rust |
| | `*.csproj` / `*.sln` | .NET/C# |
| | `Gemfile` | Ruby/Rails |
| | `composer.json` | PHP/Laravel |
| | `angular.json` | Angular (standalone components, signals) |
| | `capacitor.config.ts` / `capacitor.config.json` | Capacitor (hybrid mobile) |
| | `pubspec.yaml` | Flutter / Dart |
| | `ios/` + `android/` directories | Mobile native project |
| **Database** | `application.properties` / `application.yml` | Spring Boot DB config |
| | Deps with `pg`, `mysql2`, `mongodb`, `dynamodb`, `oracle` | DB type |
| | `prisma/schema.prisma` | Prisma ORM + provider |
| | `knexfile.js` / `typeorm` config | ORM + DB |
| | `models.py` with Django | Django ORM |
| **Infra** | `Dockerfile` / `docker-compose.yml` | Containerized |
| | `serverless.yml` / `sam-template.yaml` | Serverless (AWS Lambda) |
| | `terraform/` / `*.tf` | IaC Terraform |
| | `cdk.json` / `lib/*.ts` with CDK | AWS CDK |
| | `pulumi.yml` | Pulumi |
| | `k8s/` / `kubernetes/` / `helm/` | Kubernetes |
| **CI/CD** | `azure-pipelines.yml` | Azure Pipelines |
| | `.github/workflows/` | GitHub Actions |
| | `Jenkinsfile` | Jenkins |
| | `.gitlab-ci.yml` | GitLab CI |
| | `bitbucket-pipelines.yml` | Bitbucket Pipelines |
| **Testing** | `jest.config.*` / `vitest.config.*` | Jest / Vitest |
| | `cypress.config.*` / `playwright.config.*` | Cypress / Playwright E2E |
| | `src/test/` (Java) / `tests/` / `test_*.py` | JUnit / pytest |
| | `*.spec.ts` / `*.test.ts` / `__tests__/` | Unit tests TS |
| | `karma.conf.js` / Angular Jest config | Angular testing |
| | `flutter_test` in `pubspec.yaml` | Flutter testing |
| | `*.maestro.yaml` | Maestro E2E (mobile) |

### 2. Project structure scanning

Analyze directory structure: Monorepo or single-project? Frontend/backend separated? Workspaces? Migrations? Seeds/fixtures?

**Repo type detection** — Determine and write `repo_type` to `.sdd-config.json`:
- `packages/`, `apps/`, or workspace config (pnpm-workspace.yaml, nx.json, turbo.json) → `monorepo`
- Single `package.json` at root, no workspace indicators → `single`
- If unclear → default to `single`, note in proposal

### 2.1. Structural analysis with codebase-memory MCP

Use `codebase-memory` MCP as the **primary source** for structural analysis:

1. **Index the project** — builds knowledge graph (functions, classes, call chains, HTTP routes)
2. **Community detection** — identify functional modules. Include in `product.md` under `## Project Structure`
3. **Dead code baseline** — run dead code detection, include count in health check (CP3)
4. **Cross-service links** — if monorepo, map dependencies between services

⚠️ **Fallback**: If `codebase-memory` is unavailable → file-based detection (dirs + config files). Inform user: "codebase-memory unavailable — file-based analysis (less precise)."

### 3. Generating product.md

Generate `./product.md` using template `specs/_templates/product-template.md`. See `references/product-detection-guide.md` for auto-fill sources.

First line: `<!-- Generated by project-scanner on [YYYY-MM-DD]. Safe to edit. -->`

### 3a. ☐ **Post-generation compliance check** → After generating product.md, verify ALL section headers from `specs/_templates/product-template.md` exist in output. If ANY is missing → add it NOW before presenting to user.
   ⚠️ **Content is contextual, not copied.** Template items (checklists, table rows, examples) are ILLUSTRATIVE. Generate content from actual project analysis — codebase scan, architecture review, stakeholder context. If a generated section looks identical to the template placeholder, you're doing it wrong.
   ⚠️ **Cross-document coherence**: After saving, check if related docs exist (product.md ↔ migration-plan.md ↔ requirements.md ↔ design.md). Verify shared data (counts, architecture decisions, tech stack) is consistent. If discrepancies → fix or flag `⚠️ REQUIRES REVIEW`.



### 4. Auto-generate `.sdd-config.json`

Generate in project root with detected stack.

| Detected Technology | Stack Name |
|---------------------|------------|
| TypeScript / Node.js | `typescript`, `node` |
| Python | `python` |
| React / Next.js | `react` |
| AWS (Lambda, CDK, ECS) | `aws` |
| Java / Spring Boot | `java` |
| .NET / C# | `dotnet` |
| Angular | `angular` |
| Capacitor | `capacitor` |
| Flutter | `flutter` |
| Dart | `flutter` (alias) |

**Rules:**
- `project_name`: directory basename in kebab-case (keep existing value if set)
- `project_type`: `"existing"`
- `detected_by` = `"project-scanner"`, `last_sync` = ISO 8601 timestamp
- `"_generated": { "by": "project-scanner", "date": "[YYYY-MM-DD]", "note": "Do not edit manually. Use sdd-sync.sh --refresh to regenerate." }`
- `ides`: array with current IDE, `host` from detected git remote
- Include all detected stacks in `stacks`
- `verbosity`: `"detailed"` (default)\r
- `docs_language`: detect from README/docs language, fallback `"es"`
- `migration`: empty (route to `migration-planner` if user mentions migration)

### 4.1. Fill `env`

| Variable | Detection source |
|----------|--------------------|
| `AZURE_DEVOPS_ORG` | Azure DevOps URL or config files |
| `AZURE_DEVOPS_PROJECT` | Repo name or Azure DevOps config |
| `DB_HOST` / `DB_PORT` / `DB_NAME` | Connection strings, docker-compose, config files |
| `AWS_REGION` | CDK config, AWS config, serverless.yml |

Rules: Only fill detectable values. Include in proposal for confirmation. Mark uncertain as `[VERIFY]`. **NEVER** store personal secrets in `.sdd-config.json` `env`.

### 4.1.1. Merge credentials into MCP

Read `.sdd-credentials.json` if exists → merge into MCP config, replacing `${VAR}` placeholders. Target path depends on IDE:
- Kiro → `.agents/mcp_config.json`
- Antigravity → handled by `sdd-sync.sh` MCP config generation

Rules: `.sdd-config.json` `env` applied first (project-level), `.sdd-credentials.json` second (personal). If credentials file missing, leave `${VAR}` placeholders. **NEVER** store credentials in `.sdd-config.json`.

### 4.2. Activate stacks from cache

1. Read `stacks` from `.sdd-config.json`
2. Detect IDE (`ide` field or detect: `.agents/` → kiro, `.agents/` → antigravity)
3. Run `bash sdd-sync.sh --ide {detected_ide}` to sync stack skills to the correct IDE folder
4. Report activated files

> If `sdd-sync.sh` not found → inform: "Run `bash sdd-sync.sh --ide {ide}` manually to sync stacks."

### 5. Validation

After generating `product.md`: show summary → ask once "Adjust anything or should I proceed?" → apply corrections.

### 5.1. Verify artifact structure

If standard folders don't exist (`specs/`, `tests/`, `docs/`, `docs/diagrams/`, `db/migrations/`), create them and notify.

### 5.2. Verify deploy ignore files

| If exists... | Platform | Verify |
|-------------|----------|--------|
| `Dockerfile` / `docker-compose.yml` | Docker | `.dockerignore` |
| `vercel.json` / `.vercel/` | Vercel | `.vercelignore` |
| `.elasticbeanstalk/` | Elastic Beanstalk | `.ebignore` |

If ignore file missing → generate from standard template (see `artifact-storage.md`).
If exists → verify it includes `specs/`, `tests/`, `docs/`, `.sdd-*`. Suggest adding missing lines.

### 5.3. Generate global architecture docs (CP6)

Create `docs/architecture/` if missing. For each doc, extract from code:

| Arch Doc | Extraction source | What to look for | Output |
|---|---|---|---|
| **system-design.md** | Dirs (`apps/`, `services/`, `packages/`), docker-compose.yml, serverless.yml, k8s/ | Service names, ports, inter-container dependencies | Mermaid diagram with real components, table with tech per component |
| **data-model.md** | `prisma/schema.prisma`, `**/models/*.ts`, `models.py` (Django), `*Entity.ts` (TypeORM), `db/migrations/` | model names, fields, types, relations, indexes | ER diagram Mermaid, table per entity with columns |
| **api-contract.md** | `**/*.controller.ts` (NestJS), `routes/*.ts` (Express), `urls.py` (Django), `openapi.yml`/`swagger.json` | Decorators `@Get/@Post`, `router.get()`, path + method + auth | Endpoints table, request/response if DTOs exist |
| **integrations.md** | `package.json` deps (`stripe`, `@aws-sdk/*`, `nodemailer`, `axios`), imports, env vars `*_API_URL` | SDK imports, HTTP client calls, external URLs | External services table with purpose and auth type |
| **security-model.md** | Auth middleware, `passport.use()`, JWT config, `@UseGuards()`, CORS config, role enums, `.env` secrets | Strategy type, roles, permission patterns, secret names | Auth flow, roles table, secrets inventory |

**Generation rules:**
- Each generated section is marked with `<!-- scanner:[date] -->` to identify auto-generated vs manual
- If unable to confirm a data point → mark `[VERIFY]`
- If `codebase-memory` MCP available → use knowledge graph to enrich
- If no code for an arch doc (e.g., no DB) → copy empty template with `<!-- Not detected by scanner -->`
- Populate from detected code using templates from `docs/architecture/_templates/`
- Mark `[VERIFY]` anything uncertain

**Global infrastructure diagram** (inside `system-design.md`):
- `docs/architecture/` docs are **global** — they accumulate infra from ALL features. They grow fast.
- If Python + Graphviz available → generate `docs/diagrams/infrastructure.py` + execute → `docs/diagrams/infrastructure.png`. Embed in `system-design.md`.
- If NOT available → Mermaid fallback + inform: "Graphviz not installed — simplified global diagram. Install: `winget install Graphviz.Graphviz && pip install diagrams`"
- ⚠️ This is different from diagrams in per-feature `design.md` (Mermaid always — see solution-designer §3b).

### 6. Health Check — Proactive Risk Detection

After scanning, check for technology risks and alert user.

| Risk | How to detect | Severity |
|------|--------------|:--------:|
| Framework EOL | Detected version vs EOL dates | 🔴 Critical |
| Runtime EOL | Node.js, Java, Python version vs LTS schedule | 🔴 Critical |
| Major version lag | Current vs latest stable (3+ majors behind) | 🟡 Warning |
| Deprecated deps | `npm audit`, known deprecation notices | 🟡 Warning |
| Security vulns | `npm audit --json`, known CVEs | 🔴 Critical |

EOL reference: See `references/eol-dates.md`. Always verify with `context7` MCP or official docs.

Output format example: See `references/health-check-example.md`.

**Rules:**
- Show health check AFTER product.md summary
- No risks: `✅ Health Check — No technology risks detected`
- Risks found: list them and suggest `migration-planner`
- NEVER auto-start migration — always ask user first
- ⚠️ **`context7` MCP is MANDATORY** for verifying EOL dates and latest versions. You MUST call `context7` at least once during health check to validate detected versions. If you present a health check without `context7` verification, explicitly disclose: "⚠️ Versions not verified with context7 — EOL dates may be inaccurate."
- If `context7` unavailable → inform: "EOL verification based on local cache — may not reflect recent updates."

## Migration Assessment

After detecting stacks, evaluate each component for migration needs.

### Version analysis classification

| Classification | Criteria | project_type impact |
|---|---|---|
| ✅ Current | Within 1 major version of latest | No action |
| 🔄 Version upgrade | Same technology, needs major version bump | `existing` + upgrade tasks |
| 🔀 Technology change | Technology is EOL or has no upgrade path | `migration` candidate |
| 🟡 Minor update | Patch/minor version behind | No action (npm update) |

Assessment output format: See `references/health-check-example.md`.

### Decision logic
- **All ✅ or 🟡**: Register as `existing`. No migration.
- **Only 🔄**: Register as `existing`. Suggest upgrade tasks. Ask: "Want me to create requirements for the upgrades?"
- **Any 🔀**: Recommend migration with justification. Present which technologies need replacing, suggested target stack. Ask: "Proceed as migration, just upgrade what's possible, or keep as existing?" If accepted: set `project_type: "migration"`, auto-fill `migration.from` and `migration.to`.
- **Mix of 🔄 and 🔀**: Present both. Let user decide scope.

### 7. Constraints
- **Read-only**: This power ONLY reads files, never modifies project code
- **Only generates `product.md` and `.sdd-config.json`**: Does not touch any other file
- **Single confirmation**: Shows complete proposal, asks once: "Adjust anything or should I proceed?"
- **Does not infer what it cannot confirm**: Marks it as `[VERIFY]`
- **Health check is informational**: Alerts are suggestions, not automatic actions

## MCP
- `codebase-memory` — knowledge graph indexing, community detection, dead code baseline
- `context7` — verify EOL dates and current library versions for health check
- `eslint` — detect lint configuration and existing rules
- `python-analyzer` — detect Python tooling configuration
- `server-memory` — persist detected stack, project type, and initial observations

## Related Skills
- `structure.md` — expected project structure
- `tech.md` — approved tech stack for detection matching

## Output
- `./product.md` — auto-generated project profile
- `.sdd-config.json` — stack configuration for dev-sync
- Health check alerts (shown in conversation, not saved to file)
- `docs/architecture/*.md` — auto-generated global architecture docs from code analysis
