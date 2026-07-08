---
name: Pipeline Builder
description: Creates and maintains CI/CD pipelines for Azure Pipelines and GitHub Actions. Detects platform, generates YAML with stages, environment gates, security scanning, and rollback. Integrates with `environment-strategy.md` and `git-conventions.md`.. Triggers: pipeline, ci, cd, azure pipelines, github actions, deploy, yaml, build, test, security scan
---

## ⚠️ Step 0 — MCP Pre-flight (BEFORE any building pipelines)

**BLOCK**: Do NOT start building pipelines until you have completed this step.

1. ☐ Verify `context7` is reachable (test query for CI/CD tool docs). If unavailable → note "[context7 unavailable]"
2. ☐ Verify `eslint` is reachable (test lint command). If unavailable → note "[eslint unavailable — lint stage config will be generic]"

Only after ALL checks pass (or are documented as unavailable) → proceed.

> Follow standard interaction pattern. See `workflow-router.md`.

# Pipeline Builder

## Role: Developer

## Keywords
pipeline, ci, cd, azure pipelines, github actions, deploy, yaml, build, test, security scan

## ⚠️ REQUIRE: Read references before generating

Before generating ANY pipeline YAML, you MUST read the corresponding reference:

| Generating... | You MUST read FIRST |
|---------------|---------------------|
| Azure Pipelines pipeline | `references/azure-pipelines-example.yaml` |
| GitHub Actions pipeline | `references/github-actions-example.yaml` |

NEVER generate a pipeline without reading the corresponding reference.

### Minimum required structure (safety net)

If for any reason you cannot read the reference, use this structure:

```
Azure Pipelines: trigger → Build → Lint → Test → SecurityScan → DeployDev(auto) → DeployCert(manual+gate) → DeployProd(manual+gate) → SmokeTest → Rollback(on failure)
GitHub Actions: on push/pr → build → lint → test → security-scan → deploy-dev(auto) → deploy-cert(manual+approval) → deploy-prod(manual+approval) → smoke-test → rollback(on failure)
```

---

## Workflow

| Step | Action |
|------|--------|
| 0 | ☐ **Read `docs_language`** → from `.sdd-config.json`. Default: `"es"`. ALL output (reports, ADO fields) in this language. |
| Detect Platform | `.azure-pipelines/` → Azure; `.github/workflows/` → GitHub Actions; else infer from context. → Use `azure-devops` or `github` MCP to read repo info and branch policies |
| Read Deployment Config | Parse `deployment` from `.sdd-config.json` — determines CI/CD files to generate |
| Read Config | Parse `design.md`, `environment-strategy.md`, `git-conventions.md` |
| Generate YAML | All required stages + environment-specific gates. → Use `context7` to verify CI/CD library docs and action versions. Use `vercel` MCP if deployment.app includes vercel |
| Security Scan | SAST/DAST stage (Snyk, SonarQube, or built-in). → If `context7` available: verify scanner action versions |
| Rollback Step | Revert deployment if smoke tests fail |
| Present | Show YAML to developer; must approve before commit. → If `azure-devops` available: update pipeline definition in ADO |

---

## MCP
- `azure-devops` — read repo info, branch policies, pipeline status
- `github` — read repo info, create/update GitHub Actions workflows
- `context7` — verify CI/CD library docs and versions
- `vercel` — preview deployments per branch, production deploy for React/Next.js frontends

## Related Skills
- `git-conventions.md` — branch naming, commit format for CI triggers
- `environment-strategy.md` — DEV/CERT/PROD stages
- `security.md` — secrets handling in pipelines

## Output
- `.azure-pipelines/azure-pipelines.yml` — Azure Pipelines YAML (when platform is Azure)
- `.github/workflows/ci-cd.yml` — GitHub Actions YAML (when platform is GitHub)
- Rollback configuration included in pipeline YAML
- **Chat**: Show summary of pipeline configuration (stages, triggers, environments). Never dump full YAML in chat.

---


## Cross-role Handoff
| Receives from | Trigger | Hands off to |
|---|---|---|
| solution-designer | Infrastructure defined in design.md | aws-deployer (deployment) |
| implementer | Code ready for CI/CD | Automated pipeline execution |

---

## Pipeline Stages

Every pipeline MUST include these stages in order:

| # | Stage | Purpose | Fail Behavior |
|---|-------|---------|---------------|
| 1 | **Build** | Compile, install deps | Block all |
| 2 | **Lint** | ESLint, Prettier, etc. | Block all |
| 3 | **Unit Tests** | Test suite + coverage | Block all |
| 4 | **Security Scan** | SAST (Snyk/SonarQube/npm audit) | Block deploy |
| 5 | **DB Migration** | Run pending migrations (if applicable) | Block deploy |
| 6 | **Frontend Build** | Build SPA/SSR bundle (if applicable) | Block deploy |
| 7 | **CDK Synth** | Generate CloudFormation template (if CDK detected) | Block deploy |
| 8 | **Deploy** | Deploy to target env | Trigger rollback |
| 9 | **Smoke Test** | Health checks | Trigger rollback |
| 10 | **Rollback** | Revert if smoke fails | Alert team, manual |

---

## Auto-Detection

The pipeline builder automatically detects project capabilities and adds relevant steps:

| Detection | Check | Pipeline Step Added |
|-----------|-------|--------------------| 
| **CDK/IaC** | `cdk.json` exists | `cdk synth` → `cdk diff` → `cdk deploy --context env=$ENV` |
| **DB Migrations** | Detect ORM in package.json/requirements.txt | Migration command per tool (see below) |
| **Frontend** | `next.config.*`, `vite.config.*`, or `angular.json` | `npm run build` → deploy to S3/CloudFront or Vercel |
| **Monorepo** | `pnpm-workspace.yaml` or `workspaces` in package.json | Per-package builds with dependency graph |

### Deployment Pattern Override

If `.sdd-config.json` has `deployment.pattern`, it OVERRIDES auto-detection for deploy targets:

| deployment.pattern | CI Files Generated | CD Frontend | CD Backend |
|---|---|---|---|
| `fullstack-vercel` | `.github/workflows/ci.yml` | `vercel.json` (Vercel Git integration — auto, NOT in GH Actions) | `infra/` (AWS CDK via GH Actions) |
| `monorepo-split` | `.github/workflows/ci.yml` | `vercel.json` (root: frontend/) | `.github/workflows/deploy-backend.yml` + `infra/` |
| `backend-only` | `.github/workflows/ci-cd.yml` | N/A | `.github/workflows/ci-cd.yml` + `infra/` |
| `frontend-only` | `.github/workflows/ci.yml` | `vercel.json` | N/A |

> [!IMPORTANT]
> Cuando `deployment.app` incluye Vercel, el workflow de GH Actions **NO** tiene step de deploy frontend.
> Vercel lo maneja por Git integration. El workflow solo corre tests, lint, y build validation.

> [!NOTE]
> `vercel.json` es config del proyecto, NO pipeline CI/CD. Vercel lo lee del repo directamente.

### DB Migration Commands (auto-detected)
| Tool | Detection | Command |
|------|-----------|--------|
| Prisma | `@prisma/client` in package.json | `npx prisma migrate deploy` |
| TypeORM | `typeorm` in package.json | `npx typeorm migration:run -d dist/data-source.js` |
| Knex | `knex` in package.json | `npx knex migrate:latest` |
| Sequelize | `sequelize` in package.json | `npx sequelize-cli db:migrate` |
| Django | `manage.py` exists | `python manage.py migrate --noinput` |
| Alembic | `alembic.ini` exists | `alembic upgrade head` |
| SQL scripts | `migrations/*.sql` exists | `psql -f migrations/` (ordered by filename) |

### Frontend Deploy Targets (auto-detected)
| Framework | Detection | Deploy To |
|-----------|-----------|----------|
| Next.js | `next.config.*` | Vercel (Git integration — preferred) |
| Vite/React | `vite.config.*` | Vercel (if deployment.app=vercel) or S3+CloudFront |
| Angular | `angular.json` | Vercel (if deployment.app=vercel) or S3+CloudFront |
| Static | `index.html` only | Vercel (if deployment.app=vercel) or S3+CloudFront |

> If `deployment.pattern` is set, it takes precedence over auto-detection.

---

## Environment Gates

| Environment | Branch Trigger | Deploy Type | Approvals |
|-------------|---------------|-------------|-----------|
| **DEV** | Push to `dev`/`develop` | Auto | None |
| **CERT** | Manual from `release/*`/`cert` | Manual + gate | Dev + QA |
| **PROD** | Manual from `main`/`master` | Manual + gate | Dev + QA + BA |

### Approval Matrix
> See `references/approval-matrix.md`

---

## Example: Azure Pipelines YAML
> Full example in `references/azure-pipelines-example.yaml`. Read before generating.

---

## Constraints

- **ALWAYS** include a security scan stage. Pipelines without security scanning are not acceptable.
- **ALWAYS** include a rollback step that triggers on smoke test failure.
- **NEVER** skip tests in any environment. All stages run for every deployment.
- **NEVER** allow auto-deploy to CERT or PROD. These require manual trigger + approval gates.
- **ALWAYS** use environment-specific secrets/variables (never share across environments).
- **ALWAYS** pin action/task versions (e.g., `actions/checkout@v4`, not `@latest`).
- **NEVER** store secrets in pipeline YAML. Use pipeline variables/secrets management.
- **ALWAYS** cache dependencies (npm cache) to speed up builds.
- **ALWAYS** publish test results and coverage reports as artifacts.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| No CI/CD files exist | Infer from context (repo hosting, existing config); include in proposal if not inferable. |
| `environment-strategy.md` missing | Use defaults: `dev`→DEV, `release/*`→CERT, `main`→PROD. Note in YAML. |
| `git-conventions.md` missing | Use default branch conventions. Note in YAML. |
| `design.md` missing | Generate without service-specific deploy steps. Note in YAML. |
| Security tool not configured | Fall back to `npm audit`. Note in YAML. |
| Pipeline YAML already exists | Show diff. Infer intent from context; include in proposal if not inferable. |
