---
name: Environment Strategy
description: dev/cert/prod promotion rules and environment config
---

# Environment Strategy

For testing types and classification by environment, see `qa-strategy.md`.

## Environments

| Environment | Purpose | Deploy | Approval Gate |
|-------------|---------|--------|---------------|
| **DEV/QA** | Development + full testing | Auto (push to branch) | — |
| **CERT** | Pre-production, final validation | Manual trigger | Dev + QA |
| **PROD** | Production | Manual trigger | Dev + QA + BA |

## Promotion Pipeline

El flujo depende de `host` + `deployment.pattern` en `.sdd-config.json`. Ver `deployment-patterns.md` para flujos detallados.

| host + pattern | CI | CD Frontend | CD Backend/Infra |
|---|---|---|---|
| ADO + cualquiera | Azure Pipelines | Pipeline stages | Pipeline stages |
| GitHub + fullstack-vercel | GH Actions | **Vercel Git integration** (auto) | GH Actions → AWS CDK |
| GitHub + monorepo-split | GH Actions | **Vercel Git integration** (root: frontend/) | GH Actions → AWS CDK |
| GitHub + backend-only | GH Actions | N/A | GH Actions → AWS CDK |

> Vercel deploy es automático por Git — NO pasa por GH Actions.

## Rules
- For QA classification and promotion rules, see qa-strategy.md.

## Infrastructure as Code (CDK) Deployment

### Branch → Environment → AWS Account mapping
| Branch | Environment | Deploy | CDK Command |
|--------|-------------|--------|-------------|
| `dev`/`develop` | DEV | Automatic | `cdk deploy --context env=dev` |
| `release/*` | CERT | Manual + approval | `cdk deploy --context env=cert` |
| `main` | PROD | Manual + approval | `cdk deploy --context env=prod` |

### DB Migrations in deployment
Migrations run BEFORE infrastructure deploy:
1. Pipeline detects migration tool (Prisma, TypeORM, Knex, Django, Alembic, SQL scripts)
2. Runs migration against target environment DB
3. On failure → blocks deploy, alerts team
4. On success → proceeds to CDK deploy

### Frontend deployment
- **Vercel (preferred)**: Git integration directa. Preview per PR, staging en `dev`, production en `main`. Zero config.
- **S3 + CloudFront**: Solo cuando el proyecto NO usa Vercel (legacy o requisito específico).
- **Static assets**: Invalidate CloudFront cache after deploy (si aplica).

### Rollback strategy
1. **CDK**: `cdk deploy` with previous template version (CloudFormation rollback)
2. **DB**: Migration rollback only if migration tool supports it (Prisma: `migrate reset` — ONLY in DEV)
3. **Frontend**: Redeploy previous S3 artifact + CloudFront invalidation
4. **PROD rollback**: ALWAYS requires manual approval, NEVER automatic
