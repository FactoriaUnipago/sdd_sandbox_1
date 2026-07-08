# Git Conventions

## Branching

### Main branches

| Branch | Environment | PR Required | Merge Policy |
|--------|------------|:-----------:|-------------|
| `dev` | Development | ❌ | Direct merge or PR per team preference |
| `cert` | Certification/QA | ✅ 1 approval | Branch protection enabled |
| `main` | Production | ✅ 2 approvals | Branch protection enabled |

### Branch prefixes

| Prefix | Purpose | Base → Target |
|--------|---------|---------------|
| `feature/{name}` | New functionality | `dev` → `dev` |
| `fix/{name}` | Bug fix | `dev` → `dev` |
| `hotfix/{name}` | Urgent production fix | `main` → `main` + `dev` |
| `release/{name}` | Planned release | `dev` → `main` |

### Allowed branches by role

| Role | Allowed | Wrong branch warning |
|------|---------|---------------------|
| 📋 Analyst | `dev`, `feature/*` | "As Analyst, switch to `dev` or `feature/*`?" |
| 💻 Developer | `dev`, `feature/*`, `fix/*`, `hotfix/*` | "Branch doesn't match your role. Continue?" |
| 🧪 QA | `dev`, `feature/*`, `cert` | "As QA, switch to `dev`, `feature/*`, or `cert`?" |

Override: `.sdd-config.json` branching config takes precedence.

## Conventional Commits

Format: `type(scope): description {prefix}ID`

Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`

## Pull Requests

Title: `feat(scope): description {prefix}ID` · Link Azure DevOps work item · Squash merge · ≥1 reviewer · CI must pass

## Rules

- No direct push to `main` or `cert`; no force push to shared branches
- Branch protection on `main` and `cert`
- Naming includes ticket: `feature/{prefix}123-pagos-api`
  > Prefix from `.sdd-config.json` → `spec_prefix` (e.g., AB#, GH#, JIRA-, or empty)

## Branch cleanup

- Auto-delete branches on PR merge · Stale >30 days → review/delete · Never delete: `dev`, `cert`, `main`

## Commit & push guidance

After completing ANY artifact, agent MUST offer to commit and push.

### Auto-commit rules

All spec artifacts use branch `feature/{prefix}[ID]-[name]`:

| Artifact | Commit message |
|----------|---------------|
| `requirements.md` | `docs(specs): create requirements for {prefix}[ID]-[name]` |
| `design.md` | `docs(specs): create design for {prefix}[ID]-[name]` |
| `tasks.md` | `docs(specs): create tasks for {prefix}[ID]-[name]` |
| `test-plan.md` | `docs(specs): create test-plan for {prefix}[ID]-[name]` |
| Code implementation | `feat(scope): description` |
| Bug fix (`fix/` branch) | `fix(scope): description` |

### Behavior

1. After artifact → inform path, offer commit+push
2. Approved → git add + commit + push · Declined → continue
3. Implementation tasks → commit after EACH task, not all at once
4. **Never force push. Never commit to `main` or `cert` directly.**
