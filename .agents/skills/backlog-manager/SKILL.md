---
name: Backlog Manager
description: Manages and analyzes the backlog in Azure DevOps. Evaluates backlog health, identifies stale or blocked items, suggests prioritization using structured frameworks (MoSCoW, RICE), checks sprint readiness, maps dependencies, and generates actionable reports. All actions on items require Analyst approval.. Triggers: backlog, estimation, prioritization, grooming, refinement, RICE, MoSCoW, backlog health, dependencias, listo para sprint, limpieza, filtrar
---

> Follow standard interaction pattern. See workflow-router.md.

# Backlog Manager

## Role: Analyst

## MCP
- `azure-devops` — query work items, backlog health, sprint board, team capacity
- `server-memory` — persist prioritization decisions, backlog health snapshots

## Related Skills
- `azure-devops-workflow.md` — work item types, states, and transitions
- `workflow-router.md` — task routing rules by role

---

## Intent Detection (BEFORE running workflow)

Detect what the user actually wants:

| User says... | Intent | Action |
|---|---|---|
| "qué hay en el backlog", "muéstrame las tareas", "lista" | **Quick list** | → Step 1 only. Compact table. STOP. |
| "analiza el backlog", "prioriza", "grooming", "backlog health" | **Full analysis** | → Full workflow (steps 1-10) |
| "re-prioriza X", "mueve X", "cierra X" | **Action on item** | → Steps 7-8 only (sync + approve) |
| "muéstrame solo los de Auth", "filtrar por módulo" | **Filtered view** | → §Filtered view |
| "¿qué está listo para sprint?", "readiness" | **Sprint readiness** | → §Readiness check |
| "hay items sin desglosar?", "refinar", "features grandes" | **Refinement scan** | → §Refinement scan |
| "dependencias", "qué bloquea qué", "bloqueadores" | **Dependency map** | → §Dependency map |
| "limpia el backlog", "items viejos", "cleanup" | **Cleanup** | → §Cleanup scan |

⚠️ Do NOT run full RICE analysis when user just asks "qué hay?". Match intent FIRST, execute the minimum workflow for that intent.

### Quick list format
```
📋 Backlog — [N] items

| AB#ID | Título | Tipo | Estado | Prioridad |
|---|---|---|---|---|
| AB#104420 | [core] API RESTful | Feature | Pendiente... | Must |
| AB#104433 | [auth] REQ: Login | Requirement | En evaluación | Must |
...

¿Quieres análisis completo (RICE + health) o trabajar en algún item?
```

## Workflow (full analysis — only when intent = Full analysis)

| Step | Action | Details |
|------|--------|---------|
| 1 | Read backlog | → Use `azure-devops` MCP to query items in states with stateCategory: Proposed, InProgress (use state discovery §2b.4) |
| 2 | Analyze health | Metrics: total by state and TYPE (Feature vs Requirement vs Task). Age distribution, blocked, unestimated |
| 3 | Identify stale | Flag items with no updates in >30 days |
| 4 | Identify blockers | Find blocking dependencies or explicitly blocked items |
| 5 | Score priorities | Apply RICE to unscored items (FEATURES and EPICS ONLY); validate existing MoSCoW |
| 6 | Suggest changes | Generate prioritized actions: reorder, close, split, escalate |
| 7 | ☐ **Sync ADO priority** | → Use `azure-devops` MCP: `wit_update_work_item` — Priority + StackRank para cada WI re-priorizado |
| 8 | Analyst approves | Present suggestions. Do NOT move items without approval |
| 9 | Commit + push | Ask user, then `git add + commit + push`. ⚠️ Push is MANDATORY — commit without push = incomplete. |
| 10 | Save to memory | → Use `server-memory` to persist prioritization decisions and backlog health snapshot |

## Prioritization Frameworks

### MoSCoW
| Category | Meaning |
|----------|---------|
| **Must** | Critical — sprint fails without it |
| **Should** | Important — significant value, not critical |
| **Could** | Desirable — nice-to-have if capacity allows |
| **Won't** | Explicitly out of scope for this cycle |

### RICE Score
`RICE = (Reach × Impact × Confidence) / Effort`

| Factor | Scale |
|--------|-------|
| Reach | Users/transactions affected per sprint |
| Impact | 3=massive, 2=high, 1=medium, 0.5=low, 0.25=minimal |
| Confidence | 100%=high, 80%=medium, 50%=low |
| Effort | Person-sprints (e.g., 0.5 = half sprint) |

Higher RICE = higher priority.

## Output Format
See `references/output-template.md` for the full report template.

## Examples
See `references/examples.md` for RICE scoring and backlog health report examples.

---

## §Filtered view

User wants to see a subset of the backlog. Apply filter to step 1 query.

1. Parse filter: module name, assignee, priority level, state, or type
2. Query ADO with WIQL filter: `wit_query_by_wiql` with WHERE clause
3. Show compact table (same format as Quick list) with filter applied
4. STOP. Offer: "¿Quieres ver todos o filtrar por otra cosa?"

## §Readiness check

User wants to know if items are ready for sprint planning.

1. Query backlog items in `Proposed` or `InProgress` states
2. For EACH item, check:
   | Criterion | How to check | Symbol |
   |---|---|---|
   | Is Requirement/Task (not Feature) | `System.WorkItemType` | ✅/❌ |
   | Has approved requirements.md | `wit_get_work_item` → tags contains `requirements-ready` | ✅/❌ |
   | Is estimated (story points) | `Microsoft.VSTS.Scheduling.StoryPoints` or `Microsoft.VSTS.Scheduling.Effort` | ✅/❌ |
   | Is assigned | `System.AssignedTo` not empty | ✅/❌ |
   | Dependencies resolved | `expand: relations` → check linked items state | ✅/❌ |
3. Output:
   ```
   🏁 Sprint Readiness — [N] items checked

   | AB#ID | Título | Req/Task | Reqs ✅ | Estimado | Asignado | Deps |
   |---|---|---|---|---|---|---|
   | AB#104433 | [auth] REQ: Login | ✅ | ✅ | ❌ | ✅ | ✅ |
   
   ⚠️ 2 items not ready: missing estimates.
   ¿Quieres que los prepare para sprint?
   ```
4. STOP.

## §Refinement scan

User wants to find items that need to be broken down.

1. Query all Features: `wit_query_by_wiql` type=Feature
2. For each Feature, `wit_get_work_item` with `expand: "relations"` → check for child Requirements
3. Flag:
   - Features with **0 children** → "❌ Sin desglosar"
   - Features with children but **none approved** (no `requirements-ready` tag) → "⚠️ Requirements pendientes"
   - Requirements without acceptance criteria in description → "⚠️ Sin criterios"
4. Output:
   ```
   🔍 Refinement Scan — [N] Features revisados

   | AB#ID | Título | Hijos | Estado |
   |---|---|---|---|
   | AB#104438 | [sub-tasks] | 0 | ❌ Sin desglosar |
   | AB#104437 | [notifications] | 0 | ❌ Sin desglosar |
   | AB#104420 | [core] API | 1 | ✅ Requirements listos |
   
   ¿Creo requirements para alguno de estos?
   ```
5. STOP.

## §Dependency map

User wants to visualize what blocks what.

1. Query all active items (Proposed + InProgress)
2. For each, `wit_get_work_item` with `expand: "relations"` → extract:
   - `System.LinkTypes.Hierarchy-Forward` (parent-child)
   - `System.LinkTypes.Dependency-Forward` (depends on)
   - `Microsoft.VSTS.Common.BlockedBy` or predecessor links
3. Generate Mermaid diagram:
   ```mermaid
   graph TD
     AB104420["[core] API RESTful"] --> AB104429["REQ: API endpoints"]
     AB104432["[auth] Módulo"] --> AB104433["REQ: Login"]
     AB104439["[archivos]"] -.->|depende de| AB104420
   ```
4. Flag circular dependencies or unresolved blockers
5. STOP.

## §Cleanup scan

User wants to clean up the backlog.

1. Query ALL items (including Completed/Closed)
2. Flag candidates for action:
   | Condition | Suggested action |
   |---|---|
   | No updates in >60 days + state=Proposed | Cerrar como Won't o reasignar |
   | State=Completed but children still Open | Cerrar hijos o reabrir padre |
   | Duplicate titles (fuzzy match >80%) | Consolidar |
   | Feature Closed but Requirements still InProgress | Cerrar Requirements |
3. Output:
   ```
   🧹 Cleanup Scan — [N] candidatos

   | AB#ID | Título | Razón | Acción sugerida |
   |---|---|---|---|
   | AB#104438 | [sub-tasks] | 45 días sin update | Cerrar o refinar |
   
   ¿Apruebas estas acciones o ajustamos?
   ```
4. Do NOT execute without approval.
5. STOP.

---

## Output
- Azure DevOps: Work Items created/updated/prioritized
- Summary displayed in IDE chat (no file generated in repo)

## Constraints

- **NEVER move items without Analyst approval.** All state changes, priority changes, and closures require explicit confirmation.
- **ALWAYS show reasoning for priority changes.** Every suggestion must include the RICE calculation or MoSCoW justification.
- **NEVER delete work items.** Suggest closing with a reason, but never permanently delete.
- **ALWAYS use real data from Azure DevOps.** Do not fabricate item counts, dates, or IDs.
- **NEVER change estimates unilaterally.** Estimation is a team activity — suggest re-estimation, don't override.
- **ALWAYS flag items without estimates.** Unestimated items should be highlighted for grooming sessions.
- **Stale threshold is 30 days.** Do not flag items updated within the last 30 days as stale.
