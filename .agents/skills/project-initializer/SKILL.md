---
name: Project Initializer
description: Conversational guide for creating the product.md file in new projects through an interactive interview.. Triggers: init, inicializar, nuevo proyecto, product.md, setup, project setup, new project
---

## ⚠️ MANDATORY CHECKLIST — verify EVERY step

1. ☐ **Read context** → README.md, package.json, existing configs, server-memory
2. ☐ **Ask about project** → One open question: "¿De qué trata? Nombre, propósito, audiencia"
3. ☐ **Infer fields** → repo_type (see signals table), team, methodology, ADO project
4. ☐ **Show proposal** → Complete product.md proposal in one block. Include `Tipo de repo: X (razón)`. **Expand** the user's brief description — don't parrot. Infer: typical features, use cases, target users, domain details. The user gave a seed, not the final version.
5. ☐ **Wait for approval** → User confirms or adjusts
6. ☐ **Generate product.md** → In project root (`./product.md`)
7. ☐ **Generate .sdd-config.json** → project_type: new, repo_type, verbosity: detailed, docs_language: detect from user's language or ask
8. ☐ **Create folders** → specs/, docs/, tests/ (conditional: db/migrations if DB)
   > Show each generated file to user before proceeding to next. Approval not required for folders, but product.md and .sdd-config.json should be shown.
9. ☐ **Configure remote** → Ask: "¿URL del repositorio remoto? (GitHub/ADO/otro)"
   - `git remote add origin {url}`
   - If user says "después" or "no tengo" → continue, warn: `⚠️ Sin remote. Ejecuta: git remote add origin {url}`
10. ☐ **Commit + push** → Ask user, then `git add + commit + push` to dev. ⚠️ Push is MANDATORY — commit without push = incomplete.
11. ☐ **Save to memory** → Persist setup decisions and stack choices to server-memory

---

> Follow standard interaction pattern. See workflow-router.md.

## ⚠️ REQUIRE: Read references for stacks

| Situation | You MUST read FIRST |
|-----------|---------------------|
| Configuring stacks in .sdd-config.json | `references/stack-examples.md` |
| Output messages, prompts, README, ignore files | `references/templates.md` |

Available stacks: `typescript`, `python`, `react`, `angular`, `vue`, `aws`, `node`, `java`, `dotnet`, `go`

## When to use

- New project from scratch (no existing code — use `project-scanner` otherwise)
- Setting up SDD standard from day one

## Instructions

### Role-aware flow

Read `role` from `.sdd-config.json`:

| Role | Collect | Then |
|------|---------|------|
| `developer` | Project name (kebab-case) + description (1 sentence) | Generate product.md → print output message from `references/templates.md` |
| `analyst` / `all` | Single open prompt (see `references/templates.md`) → infer all fields below | Present complete proposal → wait for approval |

> Developer role: do NOT ask for purpose, users, integrations, team, or MCP env.

### Fields to extract (analyst/all role)

| Field | Required | Source |
|-------|----------|--------|
| Project name | ✅ | User input or infer from repo/folder name |
| Description (1 sentence) | ✅ | User input |
| Purpose / problem | ✅ | User input |
| Repo type | ✅ | Infer from signals table below |

### Repo type inference

| Señal del usuario | Tipo inferido |
|---|---|
| "una API", "una app", sin mención de múltiples servicios | `single` |
| "frontend y backend en el mismo repo", "monorepo", "workspace" | `monorepo` |
| "microservicios", "repos separados", "deploys independientes" | `multirepo` |
| No menciona arquitectura | `single` (default) |

En la propuesta (step 4), mostrar: `Tipo de repo: single (no se mencionaron múltiples servicios)` — el usuario puede corregir antes de aprobar.
| Target users | Optional | Infer from description |
| Team roles and size | Optional | User input or [TO BE DEFINED] |
| Azure DevOps project | ✅ if ADO | User input or infer from config |
| Sprint/methodology | Optional | Infer from team size |
| Additional notes | Optional | User input |

**Do NOT ask for:** database connection, AWS region, tech stack, integrations, infrastructure — those are developer decisions in solution-designer.

Before asking, read: README.md, package.json, existing configs, `.sdd-config.json`, server-memory.

### MCP Environment

After product.md approval, configure `.sdd-config.json` → `mcp_env`:
- **Azure DevOps project name** — from the proposal
- Other env vars → [TO BE DEFINED], filled later by developer

> ⚠️ Credentials (PAT, passwords, keys) go in `.sdd-credentials.json` (gitignored), NOT in `mcp_env`.

---

## MCP

| Server | Purpose |
|--------|---------|
| `azure-devops` | Create repo, branch policies, work items |
| `context7` | Verify framework versions, starter templates |
| `codebase-memory` | Index new project after scaffold |
| `server-memory` | Persist setup decisions and stack choices |

## Related Skills

`structure.md` (folders), `git-conventions.md` (branches), `environment-strategy.md` (env config)

## Output

- `./product.md` — project profile from interview. First line: `<!-- Generated by project-initializer on [YYYY-MM-DD]. Safe to edit. -->`
- `.sdd-config.json` — stack config (stacks[] empty, filled by solution-designer). Include `"_generated": { "by": "project-initializer", "date": "[YYYY-MM-DD]" }`

---

### Generating product.md

Use the unified template from `core/env/product.md.template`. All sections apply to both new and existing projects.

For **new projects**, the user provides:
- Empresa, dominio, stakeholders (entrevista)
- Descripción, problema, usuarios objetivo (entrevista)
- Módulos funcionales planificados (entrevista)
- Tech stack (entrevista o decisión del developer)
- Sprint / Roadmap (si aplica)

Sections that depend on code (Project Structure, Dependencies, Env Vars, Conventions) se dejan vacías o con placeholder — el developer las llenará cuando implemente.

> See `references/stack-examples.md` for complete template with all fields.

### Auto-generate `.sdd-config.json`

> ⚠️ Tech stack NOT selected here. `stacks` array = empty. Filled by `solution-designer`.

> ⚠️ NO preguntar deployment pattern al inicio — se define en `solution-designer` (Step 2c) cuando se elige el stack. Si el usuario lo especifica explícitamente → guardarlo.

| Field | Value |
|-------|-------|
| `project_name` | Directory basename, kebab-case. **MUST** be set. |
| `project_type` | `"new"` |
| `repo_type` | Inferred (`"single"`, `"monorepo"`, `"multirepo"`) |
| `detected_by` | `"project-initializer"` |
| `last_sync` | Current ISO 8601 timestamp |
| `ides` | Array with current IDE (e.g. `["kiro"]`) |
| `stacks` | `[]` — filled later by `solution-designer` |
| `host` | User preference (`"github"`, `"azure"`) |
| `verbosity` | `"detailed"` |
| `migration` | Empty (not a migration) |

> See `references/stack-examples.md` for complete example.

---

### Create artifact structure

**Always:** `mkdir -p specs tests/postman/collections tests/postman/environments tests/e2e tests/data tests/reports docs/api docs/diagrams docs/releases`

**Only if stack includes a DB:** `mkdir -p db/migrations`

> ⚠️ Empty `stacks[]` → do NOT create `db/` or `db/migrations/`. Created later by `solution-designer`.

Add `tests/reports/` to `.gitignore`.

### Generate ignore files for deploy

| Deploy method | Generated file |
|---------------|---------------|
| Docker (ECS, Fargate, Lambda container) | `.dockerignore` |
| Vercel | `.vercelignore` |
| Elastic Beanstalk | `.ebignore` |
| S3/CloudFront, Lambda ZIP, Amplify | None needed |
| Stack not defined / unknown | **None** — created later by `solution-designer` |

> Template in `references/templates.md`. Only create if stack includes that deploy method.

### Generate README.md

Template in `references/templates.md`. Only create if `README.md` doesn't exist.

---

### Validation

1. Show complete file to user
2. Ask once: "Adjust anything or should I proceed?"
3. Apply changes → confirm saved to `./product.md`

### Git branch workflow

| Situation | Action |
|-----------|--------|
| No commits yet (fresh repo) | Initial commit on `main` → create+switch to `dev` |
| Already has commits | Create+switch to `dev` |

Then offer: **"Commit and push to dev?"**

> ⚠️ Do NOT offer push to `main`/`master`. All SDD work starts on `dev`.

### Constraints

- **Batch proposal**: Infer everything from context. Present complete proposal in one block — never ask one by one
- **Only generates `product.md`**: No code, no project structure, no other files
- **Smart defaults**: "I don't know" → suggest most common option
- **Mark undefined**: `[TO BE DEFINED]` for undecided items
- **Infer first**: Not mentioned → infer from context. Not inferable → include with suggested default or N/A
- **Ask for confirmation**: Always show result before saving
