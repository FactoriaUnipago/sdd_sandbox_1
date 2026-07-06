---
name: Structure Conventions — SDD
description: project folder structure by project type, repo type, multi-IDE support, and deploy patterns
---

# Structure Conventions — SDD

## Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Files/Folders | kebab-case | `user-service.ts` |
| React Components | PascalCase | `UserProfile.tsx` |
| Tests | suffix/prefix | `*.test.ts`, `*.spec.ts`, `test_*.py` |

## SDD Artifacts (all project types)

`specs/` (per-feature) · `docs/` (generated) · `product.md` (context) · `.sdd-config.json` (config, git-tracked). See `artifact-storage.md`.

## Project Type (`project_type`)

| Type | When | Behavior |
|------|------|----------|
| `new` | Greenfield | Scaffold `app/` with full structure |
| `existing` | In production | Add artifacts around code. NEVER move code |
| `migration` | Rewriting | Like `existing` + migration-plan.md |

## Repo Type (`repo_type`)

| Type | Structure |
|------|-----------|
| `single` | `app/` (new) or root (existing) |
| `monorepo` | `packages/` or `apps/` |
| `multirepo` | Independent SDD per repo |

---

## Structures by Combination

### `new` + `single`

```
project/
├── .agents/ .agents/
├── specs/{feature}/ (requirements.md, design.md, test-plan.md)
├── docs/ (architecture/, api/)
├── app/
│   ├── src/ (routes/ services/ repositories/ models/ middleware/ config/)
│   ├── tests/ (unit/ integration/ e2e/)
│   ├── package.json, tsconfig.json
├── db/migrations/
├── infra/lib/
├── vercel.json              # Configuración de proyecto Vercel (solo si deployment.app incluye Vercel). Generado por pipeline-builder.
├── product.md, .sdd-config.json, sdd-sync.sh
```

> **Why `app/`?** Separates SDD artifacts from code; simplifies .gitignore/CI/Docker; eases monorepo migration.

### `existing` + `single`

SDD adds `.agents/`, `.agents/`, `specs/`, `docs/`, `product.md`, `.sdd-config.json`, `sdd-sync.sh` around existing code. **NEVER restructure existing code.**

### `migration` + `single`

```
project/
├── specs/ (migration-plan.md, {feature}/)
├── docs/architecture/migration-map.md
├── src/  ← migrates in-place (✅ done / 🔄 wip / ❌ pending)
```

> No `legacy/` folder. Code migrates module by module in-place.

### `new` + `monorepo`

```
project/
├── specs/              # by FEATURE (cross-package)
├── packages/
│   ├── api/ web/ mobile/ shared/  (each: src/ tests/ package.json)
├── infra/lib/, db/migrations/
├── package.json (root workspaces), pnpm-workspace.yaml
├── product.md, sdd-sync.sh
```

> Specs per-feature, not per-package. Detection: `pnpm-workspace.yaml`, `workspaces` in package.json, `nx.json`, `lerna.json`, `turbo.json`.

### `existing` + `monorepo`

Same as `existing` + `single`: add artifacts, don't restructure.

### `multirepo`

Apply `single` pattern to each repo independently. `{prefix}ID` coordinates cross-repo features. Shared contracts via OpenAPI/published packages.

### Multi-IDE Support

IDE config dirs are gitignored. `sdd-sync.sh --ide kiro` syncs to `.agents/` only. Config: `.sdd-config.json` → `ides: ["kiro", "cursor", "windsurf"]`.

---

## Deploy Ignore

SDD artifacts NEVER deployed. Each deployable app needs ignore file:

```
specs/ tests/ docs/ db/ .agents/ .cursor/ .windsurf/ .github/copilot/ .sdd-* sdd-sync.sh *.md !README.md
```

---

## Mono vs Multi Decision

| Factor | Monorepo | Multirepo |
|--------|:--------:|:---------:|
| 1 team, shared code | ✅ | — |
| Independent teams | — | ✅ |
| Separate deploys | Both | ✅ natural |
| Onboarding | 1 clone | N clones |
| CI/CD | Path filters | Simple |

---

## Code Structure by Stack

**TypeScript/Node**: `src/` → routes, services, repositories, models, utils, middleware, config · `tests/` → unit, integration, e2e

**Python/FastAPI**: `app/` → routes, services, repositories, models, schemas, utils, config · `tests/` → unit, integration

---

## Rules

1. The IDE config directories (`.agents/`, `.agents/`, etc.) are NOT manually modified — managed by sync
2. SDD NEVER moves or restructures existing code — it adds artifacts around it
3. In monorepos, specs are organized by **feature**, not by package
4. `app/` is the recommended code root for `new` projects — keeps SDD artifacts separate
5. For `existing` projects, code stays wherever it already is
6. NEVER mix specs from different apps in the same `specs/{prefix}[ID]/` folder
7. ALWAYS use {prefix}ID for cross-repo traceability in multirepo
8. ALWAYS each deployable app has its own ignore file
9. NEVER deploy specs/, tests/, docs/, .[ide]/, .sdd-*
10. In monorepo, cross-app features use ONE spec with separate tasks per app
