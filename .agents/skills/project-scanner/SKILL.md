---
name: Project Scanner
description: Scans an existing project and automatically generates the product.md file with all detected tech stack, structure, and configuration.. Triggers: scan, escanear, existing project, detect, product.md, stack detection, project scan
---

## ⚠️ MANDATORY CHECKLIST — Checkpoints interactivos

Al inicio: "Voy a escanear el proyecto. Estimado: ~2-3 minutos. ¿Arranco?"
Si usuario dice "hazlo todo" / "sin preguntas" → batch mode (ejecuta todo, muestra resumen al final).

### Proyecto Existing (6 checkpoints)

| CP | Paso | Tipo | Acción |
|---|---|---|---|
| 1 | Tech Detection | ⏸️ Decision | Scan config files + **`context7`** (verify detected versions vs latest stable) + **`eslint`** (detect lint config/rules for JS/TS) + **`python-analyzer`** (detect Ruff/Pylint config for Python) → show stacks table + detected deployment (`vercel.json` → Vercel, `.github/workflows/` → GH Actions, `cdk.json` → AWS CDK, `azure-pipelines.yml` → Azure Pipelines) → "Correct or anything missing?" |
| 2 | Structure | 🤖 Info | **`codebase-memory`** (knowledge graph, community detection, cross-service links) + scan dirs/workspaces → "Repo: [type], structure: [detail]" → auto continue. Fallback: if MCP unavailable → file-based detection |
| 3 | Health Check | ⏸️ Decision | **`context7`** (EOL dates, latest versions, CVEs) + `codebase-memory` (dead code baseline) → risk table + existing/migration recommendation → "Agree?" |
| 4 | product.md | ⏸️ Decisión | Generar desde detección → mostrar resumen → "¿Apruebas o ajustas?" |
| 5 | Config + Folders | 🤖 Informativo | .sdd-config.json + folders + stacks + `deployment` (SOLO si confirmado en CP1) → sigue auto |
| 6 | Arch Docs | ⏸️ Decisión | Generar docs/architecture/ desde código → "¿Revisamos o commit?" |

### Proyecto Migration (8 checkpoints)

CP1-CP3 iguales. En CP3 usuario elige "migración".

| CP | Paso | Tipo | Acción |
|---|---|---|---|
| 4m | Target Stack + Deploy | ⏸️ Decisión | "¿A qué stack migrar?" + "¿Deployment target?" → proponer basado en target stack con justificación → "Recomiendo [pattern] porque [razón]. ¿OK?" |
| 5m | As-Is Architecture | ⏸️ Decisión | Documentar arq legacy desde código → "¿Correecto o falta algo?" |
| 6m | product.md + Config | ⏸️ Decisión | product.md con legacy + target → "¿Apruebas?" |
| 7m | Migration Plan | ⏸️ Decisión | Generar migration-plan.md con fases → "¿Apruebas el plan?" |
| 8m | Arch Docs + Diagramas | ⏸️ Decisión | Arch docs + 2 diagramas (legacy + target) → "¿Commit?" |

### Post-scan (ambos tipos)

| # | Acción |
|---|---|
| ☐ | Commit + push (preguntar usuario). ⚠️ Push is MANDATORY — commit without push = incomplete. |
| ☐ | Save to memory (stacks, project_type, migration context) |
| ☐ | **COMPLETION CHECKPOINT** → Before showing 📍 position, verify: `git push` completed (not just commit) + memory saved. If ANY missing → complete NOW. |
| ☐ | Show 📍 position + "¿Qué hacemos?" → STOP. Do NOT suggest or execute role changes. |

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

Generate `./product.md` using template in `references/product-template.md`.

First line: `<!-- Generated by project-scanner on [YYYY-MM-DD]. Safe to edit. -->`

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
| `AZURE_DEVOPS_ORG` | Usually `unipagosa` |
| `AZURE_DEVOPS_PROJECT` | Repo name or Azure DevOps config |
| `DB_HOST` / `DB_PORT` / `DB_NAME` | Connection strings, docker-compose, config files |
| `AWS_REGION` | CDK config, AWS config, serverless.yml |

Rules: Only fill detectable values. Include in proposal for confirmation. Mark uncertain as `[VERIFY]`. **NEVER** store personal secrets in `mcp_env`.

### 4.1.1. Merge credentials into MCP

Read `.sdd-credentials.json` if exists → merge into MCP config, replacing `${VAR}` placeholders. Target path depends on IDE:
- Kiro → `.agents/mcp_config.json`
- Antigravity → handled by `sdd-sync.sh` MCP config generation

Rules: `mcp_env` applied first (project-level), `.sdd-credentials.json` second (personal). If credentials file missing, leave `${VAR}` placeholders. **NEVER** store credentials in `.sdd-config.json`.

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

| Arch Doc | Fuente de extracción | Qué buscar | Output |
|---|---|---|---|
| **system-design.md** | Dirs (`apps/`, `services/`, `packages/`), docker-compose.yml, serverless.yml, k8s/ | Nombres de servicios, puertos, dependencias entre containers | Diagrama Mermaid con componentes reales, tabla con tech por componente |
| **data-model.md** | `prisma/schema.prisma`, `**/models/*.ts`, `models.py` (Django), `*Entity.ts` (TypeORM), `db/migrations/` | model names, fields, types, relations, indexes | ER diagram Mermaid, tabla por entidad con columnas |
| **api-contract.md** | `**/*.controller.ts` (NestJS), `routes/*.ts` (Express), `urls.py` (Django), `openapi.yml`/`swagger.json` | Decorators `@Get/@Post`, `router.get()`, path + method + auth | Tabla de endpoints, request/response si hay DTOs |
| **integrations.md** | `package.json` deps (`stripe`, `@aws-sdk/*`, `nodemailer`, `axios`), imports, env vars `*_API_URL` | SDK imports, HTTP client calls, external URLs | Tabla de servicios externos con propósito y auth type |
| **security-model.md** | Auth middleware, `passport.use()`, JWT config, `@UseGuards()`, CORS config, role enums, `.env` secrets | Strategy type, roles, permission patterns, secret names | Auth flow, roles table, secrets inventory |

**Reglas de generación:**
- Cada sección generada se marca con `<!-- scanner:[fecha] -->` para identificar auto-generado vs manual
- Si no puede confirmar un dato → marcar `[VERIFY]`
- Si `codebase-memory` MCP disponible → usar knowledge graph para enriquecer
- Si no hay código para un arch doc (ej: no hay DB) → copiar template vacío con `<!-- No detectado por scanner -->`
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
- No risks: `✅ Health Check — No se detectaron riesgos tecnológicos`
- Risks found: list them and suggest `migration-planner`
- NEVER auto-start migration — always ask user first
- **`context7`** MCP is the primary source for verifying EOL dates and latest versions. Fallback: `references/eol-dates.md` (may be outdated)
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
