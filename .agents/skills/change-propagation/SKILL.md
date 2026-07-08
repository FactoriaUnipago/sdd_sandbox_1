---
name: Change Propagation
description: update related artifacts when specs or code change
---

# Change Propagation

Upstream spec changes → downstream specs MUST be marked `⚠️ REQUIRES REVIEW`.

## Propagation Matrix

### Feature-level specs
| Changed | Mark downstream | Notify |
|---|---|---|
| `requirements.md` | `design.md` + `test-plan.md` + `tasks.md` | Dev → QA |
| `design.md` | `test-plan.md` + `tasks.md` | QA |
| `test-plan.md` (gap) | `requirements.md` or `design.md` | Analyst → Dev |

### Project-level docs
| Changed | Mark downstream | Shared data to verify |
|---|---|---|
| `product.md` | `migration-plan.md` + all `requirements.md` | Scope, modules, screen counts, tech stack |
| `migration-plan.md` | `product.md` + active `design.md` files | Architecture variant, estimation, timeline, scope numbers |
| `migration-plan.md` (architecture decision) | `product.md` § Tech Stack + § Project Structure | BFF vs SSR, monorepo vs single app, framework choice |
| `.sdd-config.json` | `product.md` § Tech Stack | Stack definitions must match |

> ⚠️ **Common coherence failures** (from real incidents):
> - Screen counts differ between product.md and migration-plan.md (e.g. 338 vs 326)
> - Architecture decisions in product.md contradict pending decisions in migration-plan.md
> - Tech stack hardcoded in product.md before migration-plan.md decides it
> - Estimation numbers in migration-plan.md not reflected in sprint planning

## Procedures

**Modifying:** 1) Identify dependents via matrix → 2) Add marker (see `references/change-propagation-marker.md`) → 3) Notify user → 4) Do NOT modify downstream content, marker only.

**Reviewing:** 1) Read marker → 2) Update if necessary → 3) Remove marker only after review → 4) Confirm with user.

## Rules

- NEVER remove `⚠️ REQUIRES REVIEW` without actual review of the content
- NEVER modify downstream specs automatically — only mark for human review
- ALWAYS show the user the list of affected specs before marking them
- ALWAYS include a change summary in the marker to give context to the reviewer
- If a spec has a pending `⚠️ REQUIRES REVIEW`, alert the user before working on that spec

## Auto-detection

On spec modification in `specs/{prefix}[ID]-[name]/`:
1. Check if upstream per matrix → mark downstream
2. Report: "✅ Change applied. ⚠️ N specs marked for review: [list]"

## Escalation (bottom-up)

1. QA/Dev reports gap → 2. Propose upstream update → 3. Wait for approval → 4. Propagate downstream.

## Pending Changes Check

`git fetch origin`; compare `HEAD` vs `origin/<branch>`. If diffs — show by role:

| Role | Watch |
|------|-------|
| Analyst | `specs/{prefix}*/design.md`, `test-plan.md` |
| Developer | `specs/{prefix}*/requirements.md`, `test-plan.md` |
| QA | `specs/{prefix}*/requirements.md`, `design.md`, `src/` |

Ask "X pending changes. Update?" → yes: `git pull`. If `.sdd-config.json` changed → `bash sdd-sync.sh --refresh`. No diffs → silent.

## Pending Review Check

Search `specs/` for `⚠️ REQUIRES REVIEW`. Filter by role: Analyst=designs/test-plans from their reqs; Dev=reqs affecting designs; QA=designs affecting test-plans. Inform count + list. User decides priority.

## Cross-role Feedback

| Scenario | Action |
|----------|--------|
| Dev finds req issue | Note for analyst via ADO MCP + tag `needs-clarification` |
| Analyst sees feedback | Review → modify req → propagation marks downstream → remove tag |
| Dev sees review flag | Review → update design → remove REQUIRES REVIEW |

| ADO Tag | Meaning | Set by | Cleared by |
|---------|---------|--------|------------|
| needs-clarification | Needs review by owner | Any role | Owner after fix |
| requires-review | Dependent artifact outdated | Propagation | Owner after update |
