---
name: Sprint Planner
description: Manages the full sprint lifecycle: planning, monitoring, scope changes, close-out, and velocity tracking. All selections require final Analyst approval.. Triggers: sprint, planning, planificación, velocity, capacity, sprint goal, backlog, burndown, cierre, carryover, alcance, tendencia
---

## Role: Analyst

## Keywords
sprint, planning, planificación, velocity, capacity, sprint goal, backlog

## Overview
Assists in sprint planning by calculating team capacity, suggesting prioritized backlog items, and generating a clear sprint goal. All selections require final Analyst approval.

## MCP
- `azure-devops` — query work items, team capacity, sprint board, velocity history
- `server-memory` — persist sprint decisions, velocity trends, capacity calculations

### MCP Tool Reference (use ONLY these — do NOT invent capabilities or claim limitations)

| Action | MCP Tool | Key Parameters |
|---|---|---|
| List project iterations | `work_list_iterations` | `project`, `depth` |
| List team iterations | `work_list_team_iterations` | `project`, `team`, `timeframe` |
| **Create iteration with dates** | `work_create_iterations` | `project`, `iterations: [{iterationName, startDate, finishDate}]` |
| Assign iteration to team | `work_assign_iterations` | `project`, `team`, `iterations` |
| Get iteration capacity | `work_get_iteration_capacities` | `project`, `iterationId` |
| Get team capacity | `work_get_team_capacity` | (check schema) |
| Assign WI to iteration | `wit_update_work_item` | `id`, set `System.IterationPath` |
| Batch assign WIs | `wit_update_work_items_batch` | batch update `System.IterationPath` |
| Query children of Feature | `wit_get_work_item` | `id`, `expand: "relations"` → filter `System.LinkTypes.Hierarchy-Forward` |
| Query WIs for iteration | `wit_get_work_items_for_iteration` | `project`, iteration ID |
| WIQL query | `wit_query_by_wiql` | Custom WIQL for backlog items |

⚠️ **Date format**: ISO 8601 — `"2026-07-06T00:00:00Z"` / `"2026-07-17T23:59:59Z"`
⚠️ **Do NOT claim** "MCP can't do X" without checking the tool list above first.

### API URLs for field/state discovery (via curl, same as work-item-setup §2b)

| Action | URL |
|---|---|
| Get field metadata | `https://dev.azure.com/{org}/_apis/wit/fields/{fieldRef}?api-version=7.1` |
| Get picklist values | `https://dev.azure.com/{org}/_apis/work/processes/lists/{picklistId}?api-version=7.1` |
| Get process ID | `https://dev.azure.com/{org}/_apis/work/processes?api-version=7.1` |
| Get valid states | `https://dev.azure.com/{org}/_apis/work/processes/{processId}/workItemTypes/{witRef}/states?api-version=7.1` |
| Get WI type fields | `get_work_item_type_fields(type)` via MCP |

## Related Skills
- `azure-devops-workflow.md` — sprint structure and work item workflow
- `workflow-router.md` — task assignment rules

---

## Intent Detection (BEFORE running workflow)

Detect what the user actually wants:

| User says... | Intent | Action |
|---|---|---|
| "planificar sprint", "crear sprint", "armar sprint" | **Plan new sprint** | → Workflow completo (steps 1-12) |
| "cómo va el sprint", "estado", "burndown", "progreso" | **Mid-sprint check** | → §Mid-sprint check |
| "cierra el sprint", "terminamos", "fin de sprint" | **Sprint close-out** | → §Close-out |
| "qué quedó pendiente", "carryover", "incompletos" | **Carryover** | → §Carryover |
| "agregaron X", "cambio de alcance", "metieron algo" | **Scope change** | → §Scope change |
| "velocidad", "tendencia", "velocity", "histórico" | **Velocity trend** | → §Velocity trend |

⚠️ Match intent FIRST. Do NOT run full planning workflow for a simple status check.

---

## Workflow (plan new sprint — only when intent = Plan new sprint)

1. **Read velocity history** — → Use `azure-devops` MCP to query the last 3-5 sprint velocity values (story points completed).
2. **Calculate capacity** — Apply the capacity formula (see below) using team availability data.
3. **Select candidate items** — Pull top items from the prioritized backlog that fit within capacity, applying selection criteria.
   - ⚠️ **Scope rule**: If user specifies a priority level ("solo prioridad 1", "solo Must"), include ONLY that level. Do NOT auto-fill remaining capacity with lower priority items unless user explicitly says so.
   - ⚠️ **Hierarchy rule**: Sprint items MUST be Requirements or Tasks (child WIs), NOT Features or Epics. Before selecting:
     a. Query children of each Feature: `wit_query_work_items` with parent link
     b. If Feature has child Requirements → select the Requirements, not the Feature
     c. If Feature has NO children → inform user: "Feature X no tiene Requirements hijos. ¿Lo creo primero?"
4. **Check dependencies** — Verify that all dependencies for selected items are resolved or included in the sprint.
5. **Draft sprint goal** — Write a concise sprint goal (1-2 sentences) that captures the sprint's primary objective.
6. **Generate sprint plan** — Produce the structured output (see Output Format).
7. ☐ **Analyst approves** — Present the plan. Analyst may adjust items, reassign, or modify the goal. Do NOT finalize without EXPLICIT approval ("apruebo", "dale", "go").
   ⚠️ Confirming information ("exacto", "sí, ese es el orden") is NOT approval to execute. The user must approve the FULL plan explicitly.
8. ☐ **Create/assign iteration in ADO** — ⚠️ Duplicate check: Before creating, query ADO by title prefix with WIQL CONTAINS (case-insensitive). If found → skip creation.
   ONLY after approval:
   a. Use `work_create_iterations` to create a NEW iteration with proper name and dates (start + end). Do NOT use the default "Iteration 1".
   b. `wit_update_work_item`: `System.IterationPath` ← `Project\Sprint N` para cada WI del sprint
   c. Verify: WIs visible in Taskboard (Requirements/Tasks level, NOT Features)
9. ☐ **Commit + push** — Ask user, then `git add + commit + push`. ⚠️ Push is MANDATORY — commit without push = incomplete.
10. ☐ **Save to memory** — → Use `server-memory` to persist sprint decisions, velocity data, and team capacity snapshot
11. ☐ **COMPLETION CHECKPOINT** — Before showing 📍, verify:
    - [ ] Iteration created with dates (step 8a)
    - [ ] Requirements/Tasks assigned to iteration (step 8b) — NOT Features
    - [ ] `git push` completed (step 9)
    - [ ] Memory saved (step 10)
    If ANY is missing → complete it NOW.
12. ☐ Show 📍 position. STOP. Do NOT suggest or execute role changes.

## Capacity Calculation

```
Sprint Capacity = Team Size × Sprint Days × Availability% × Velocity Factor

Where:
- Team Size      = Number of team members
- Sprint Days    = Working days in sprint (typically 10)
- Availability%  = Average availability (account for PTO, holidays, meetings)
- Velocity Factor = Average story points per person-day (derived from historical velocity)
```

**Example:**
```
Team: 5 devs × 10 days × 80% availability × 1.2 pts/person-day = 48 story points
Buffer (20%): 48 × 0.80 = 38.4 → usable capacity ≈ 38 points
```

## Item Selection Criteria

Items are selected using these criteria in order:

1. **Priority** — MoSCoW ranking:
   - **Must** → Selected first (mandatory for sprint success)
   - **Should** → Selected if capacity allows
   - **Could** → Selected only if significant capacity remains
   - **Won't** → Never selected for this sprint

2. **Dependencies resolved** — All blocking items must be Done or included in the same sprint.

3. **Estimate fits capacity** — Adding the item must not exceed remaining usable capacity.

4. **Team skill match** — At least one available team member has the skills for the item.

---

## Output Format

```markdown
# 🏃 Sprint Plan — [Sprint Name]

**Sprint Goal:** [1-2 sentence goal describing what the team will achieve]
**Dates:** [start_date] → [end_date]
**Team Size:** [N] members

## Capacity
| Metric              | Value      |
|---------------------|------------|
| Raw Capacity        | [N] points |
| Buffer (20%)        | [N] points |
| Usable Capacity     | [N] points |
| Historical Velocity | [N] avg    |

## Selected Items
| {prefix}ID   | Title                    | Estimate | Priority | Assignee     | Dependencies |
|---------|--------------------------|----------|----------|--------------|--------------|
| {prefix}[ID] | [Title]                  | [N] pts  | Must     | [Name]       | None / {prefix}X  |

## Summary
| Metric         | Value      |
|----------------|------------|
| Total Points   | [N]        |
| Usable Capacity| [N]        |
| Utilization     | [N%]      |
| Items selected | [N]        |

## Risks & Notes
- [Risk or note about the sprint plan]
```

---

## Examples

### Example: Sprint Plan
```markdown
# 🏃 Sprint Plan — Sprint 15

**Sprint Goal:** Complete the credit card payment flow and stabilize the notifications module
**Dates:** 2025-01-20 → 2025-01-31
**Team Size:** 5 members

## Capacity
| Metric              | Value      |
|---------------------|------------|
| Raw Capacity        | 48 points  |
| Buffer (20%)        | 10 points  |
| Usable Capacity     | 38 points  |
| Historical Velocity | 36 avg     |

## Selected Items
| {prefix}ID  | Title                          | Estimate | Priority | Assignee       | Dependencies |
|--------|--------------------------------|----------|----------|----------------|--------------|
| {prefix}200 | Card checkout                  | 8 pts    | Must     | Ana Ruiz       | {prefix}123 ✅    |
| {prefix}205 | CVV validation                 | 3 pts    | Must     | Ana Ruiz       | {prefix}200       |
| {prefix}210 | Fix duplicate notifications    | 5 pts    | Must     | Pedro Gómez    | None         |
| {prefix}215 | Retry logic for webhooks       | 5 pts    | Should   | Luis Chen      | {prefix}210       |
| {prefix}220 | Dashboard advanced filters     | 8 pts    | Should   | María López    | None         |
| {prefix}225 | Improve audit logs             | 5 pts    | Could    | Carlos Díaz    | None         |

## Summary
| Metric          | Value     |
|-----------------|-----------|
| Total Points    | 34        |
| Usable Capacity | 38        |
| Utilization     | 89%       |
| Items selected  | 6         |

## Risks & Notes
- {prefix}205 depends on {prefix}200 — must be completed in order
- Pedro has PTO on Friday the 31st — availability adjusted to 90%
- Buffer of 4 points reserved for production bugs
```

---

## §Mid-sprint check

User wants to know how the current sprint is going.

1. Identify active iteration: `work_list_team_iterations` with `timeframe: "current"`
2. Query all items in iteration: `wit_get_work_items_for_iteration`
3. Classify each item by state:
   | Category | States |
   |---|---|
   | ✅ Done | Completed, Closed, Resolved |
   | 🟡 In Progress | Active, InProgress, Committed |
   | ⚪ Not Started | New, Proposed |
4. Calculate burndown:
   - Días restantes del sprint (finishDate - hoy)
   - Puntos completados vs puntos pendientes
   - Ritmo necesario: puntos_pendientes / días_restantes
5. Flag at-risk items: InProgress >3 días sin cambio de state (`wit_list_work_item_revisions`)
6. Output:
   ```
   🏃 Sprint Status — [Sprint Name]
   Días restantes: [N] | Progreso: [X]/[Y] pts ([Z]%)

   | Estado | Items | Puntos |
   |---|---|---|
   | ✅ Done | 3 | 12 pts |
   | 🟡 In Progress | 2 | 8 pts |
   | ⚪ Not Started | 1 | 4 pts |

   ⚠️ At-risk: AB#104433 (5 días sin progreso)
   Ritmo necesario: 2.4 pts/día (actual: 1.7 pts/día)
   ```
7. STOP.

## §Close-out

User wants to formally close the sprint.

1. Identify active iteration: `work_list_team_iterations` with `timeframe: "current"`
2. Query all items: `wit_get_work_items_for_iteration`
3. Classify:
   - **Completed**: items in Done/Closed/Resolved states → sum story points = velocity real
   - **Incomplete**: items NOT done → propose moving back to backlog
4. Calculate metrics:
   | Metric | Value |
   |---|---|
   | Velocidad planificada | [N] pts |
   | Velocidad real | [N] pts |
   | % Completado | [N]% |
   | Items completados | [N]/[M] |
   | Items incompletos | [N] |
5. For incomplete items:
   - `wit_update_work_item`: reset `System.IterationPath` to backlog root
   - Propose for carryover (§Carryover)
6. Save velocity real to server-memory: `sprint_velocity_{sprint_name}` with date, planned, actual
7. Output: resumen de cierre + "¿Apruebas mover los incompletos al backlog?"
8. Require approval → STOP.

## §Carryover

Manage items not completed in previous sprint.

1. Query server-memory for last closed sprint OR query previous iteration items
2. Find items NOT in Done/Closed state from that iteration
3. For each incomplete item:
   - Keep original estimate or adjust?
   - Same assignee or reassign?
   - Priority bump? (carried over = higher urgency)
4. Output:
   ```
   🔄 Carryover — [N] items del Sprint [X]

   | AB#ID | Título | Puntos | Assignee | Sugerencia |
   |---|---|---|---|---|
   | AB#104433 | [auth] REQ: Login | 5 pts | jsolano | → Sprint [X+1], prioridad Must |

   ¿Incluyo estos en el próximo sprint?
   ```
5. If approved → assign to next iteration via `wit_update_work_item`
6. STOP.

## §Scope change

User reports a new item was added mid-sprint.

1. Identify the new item (AB#ID or description)
2. Get current sprint capacity from memory
3. Calculate impact:
   - Current load: sum of assigned points
   - New item estimate: story points (ask if not estimated)
   - New total vs usable capacity
4. If new total > usable capacity:
   ```
   ⚠️ Scope Alert — Capacidad excedida

   Capacidad usable: 24 pts
   Carga actual:     22 pts
   Nuevo item:       +5 pts
   Total:            27 pts (❌ excede por 3 pts)

   Opciones:
   1. Sacar un item Should/Could para hacer espacio
   2. Aceptar el riesgo (sprint overloaded)
   3. Rechazar el nuevo item → backlog
   ```
5. If fits → confirm and assign to iteration
6. Require approval → STOP.

## §Velocity trend

User wants to see velocity over time.

1. Query server-memory for all `sprint_velocity_*` entities
2. If <3 sprints of data → inform "Historial insuficiente (solo [N] sprints)"
3. Calculate:
   - Promedio móvil (últimos 3-5 sprints)
   - Tendencia: mejorando / estable / bajando
   - Predicción para próximo sprint
4. Output:
   ```
   📈 Velocity Trend — Últimos [N] sprints

   | Sprint | Planificado | Real | % |
   |---|---|---|---|
   | Sprint 1 | 24 pts | 20 pts | 83% |
   | Sprint 2 | 24 pts | 22 pts | 92% |
   | Sprint 3 | 26 pts | 25 pts | 96% |

   Promedio: 22.3 pts | Tendencia: ⬆️ Mejorando
   Predicción Sprint 4: ~24 pts
   ```
5. STOP.

---

## Output
- Azure DevOps: Sprint Board updated with planned items
- Summary shown in IDE chat (does not generate a file in the repo)

## Constraints

- **NEVER exceed usable capacity.** Total selected points must be ≤ usable capacity.
- **ALWAYS leave 20% buffer** for unplanned bugs, support requests, and production incidents.
- **REQUIRE Analyst final approval** on item selection, assignments, and sprint goal.
- **NEVER select items with unresolved blockers** unless the blocker is also included in the sprint.
- **ALWAYS show the math** — capacity calculation must be visible and verifiable.
- **NEVER assign items** to team members without considering their current load and skills.
- **ALWAYS base velocity on historical data** — minimum 3 sprints of history. If fewer, state "Insufficient history" and use conservative estimates.
