---
name: Vercel Deployer
description: Manages Vercel project configuration, environment variables, custom domains, and rollback. Does NOT execute deploys — Vercel handles that automatically via Git integration.. Triggers: vercel, deploy, frontend, preview, production, domain, rollback
---

> Follow standard interaction pattern. See `workflow-router.md`.

## ⚠️ MANDATORY CHECKLIST

0a. ☐ **Read `docs_language`** → from `.sdd-config.json`. Default: `"es"`. ALL output (reports, ADO fields) in this language.
0b. ☐ **Read config** → `.sdd-config.json` → `deployment.app` must include `vercel`. If not → **BLOCK**: "This project does not use Vercel." → Use `server-memory` to load prior deployment config and domain state
1. ☐ **Check `vercel.json` exists** → If missing → generate from `pipeline-builder/references/vercel-config-example.json`
2. ☐ **Verify Vercel connection** → "Is the repo connected to Vercel? If not, follow the setup guide."
3. ☐ **Env vars synced** → Compare `design.md` env requirements vs Vercel Dashboard. → Use `server-memory` to persist env var sync status
4. ☐ **Custom domain** → If production → verify domain configured

# Vercel Deployer

## Role: Developer

> [!IMPORTANT]
> This power **does NOT execute deploys**. Vercel handles them automatically via Git integration.
> This power manages the **configuration** of the Vercel project.

## Keywords
vercel, deploy, frontend, preview, production, domain, rollback, environment variables

## Workflow

| Step | Action |
|------|--------|
| 1 | **Read Config** — Parse `deployment` from `.sdd-config.json`. Verify `deployment.app` includes `vercel` |
| 2 | **Generate `vercel.json`** — Based on `deployment.pattern`. Read `references/vercel-config-example.json` from `pipeline-builder` |
| 3 | **One-time Setup Guide** — Present to user: connect repo in Vercel dashboard, configure production branch (`main`), root directory |
| 4 | **Environment Variables** — Sync env vars: list needed vars from `design.md`, generate Vercel CLI commands or dashboard instructions |
| 5 | **Custom Domains** — Configure production domain + staging subdomain |
| 6 | **Verify** — Check Vercel project status via `vercel` MCP (if available). → Use `server-memory` to persist deployment config and domain mappings |

## MCP
- `vercel` — project status, deployments, env vars, domains
- `server-memory` — deployment config, domain mappings

## Output
- `vercel.json` — Project configuration file
- **Chat**: Setup instructions, env var commands, domain config
- Does NOT produce pipeline YAML — Vercel deploys are automatic

## Vercel Git Integration Model

| Git Event | Vercel Action | URL |
|---|---|---|
| PR opened/updated | Automatic preview deploy | `{branch}-{project}.vercel.app` |
| Merge to `dev` | Staging deploy | `dev-{project}.vercel.app` |
| Merge to `main` | **Production deploy** | `{custom-domain}` or `{project}.vercel.app` |

## Rollback

| Scenario | Method |
|----------|--------|
| Bad production deploy | `vercel rollback` — reverts to previous deployment |
| Preview issues | Fix in PR, Vercel auto-redeploys on push |
| Need specific version | `vercel promote {deployment-url}` |

## Pre-Deploy Checklist

### Configuration
- [ ] `vercel.json` present and valid
- [ ] Correct framework preset (Next.js / Vite / etc.)
- [ ] `rootDirectory` configured (if monorepo-split)
- [ ] `buildCommand` and `outputDirectory` correct

### Environment Variables
- [ ] All env vars from `design.md` configured in Vercel Dashboard
- [ ] Secrets NEVER in `vercel.json` — use `@secret-name`
- [ ] Correct scopes: Production, Preview, Development
- [ ] Env vars synced with AWS (SSM/Secrets Manager ↔ Vercel)

### Domains & DNS
- [ ] Production domain configured (if applicable)
- [ ] DNS records (CNAME/A) pointing to Vercel
- [ ] Automatic SSL active

## Constraints
- **NEVER** deploy via CLI in CI/CD — Vercel Git integration handles this
- **ALWAYS** use Vercel environment variables for secrets (never in `vercel.json`)
- **ALWAYS** configure `vercel.json` before first deploy
- **NEVER** expose API keys or secrets in `vercel.json` — use `@secret-name` references
- **ALWAYS** present setup guide to user — never auto-connect repos
- **ALWAYS** verify env vars are synced between AWS and Vercel when both are used

## Cross-role Handoff
| Receives from | Trigger | Hands off to |
|---|---|---|
| pipeline-builder | `vercel.json` generated | One-time setup + env vars |
| solution-designer | deployment.app = vercel confirmed | Config generation |

## Error Handling
| Scenario | Action |
|----------|--------|
| `deployment.app` doesn't include vercel | STOP. "This project doesn't use Vercel." |
| No `vercel.json` exists | Generate from template based on `deployment.pattern` |
| Vercel MCP not available | Provide manual CLI commands instead |
| Domain DNS not configured | Show DNS records needed (CNAME/A records) |
| Env var missing in Vercel | List missing vars, provide dashboard link |
| Build fails on Vercel | Check `buildCommand`, `outputDirectory`, framework preset |

## Related Skills
- `deployment-patterns.md` — Patterns, promotion, stack→deployment mapping
- `environment-strategy.md` — DEV/CERT/PROD rules
- `security.md` — Secrets management (never in `vercel.json`)
