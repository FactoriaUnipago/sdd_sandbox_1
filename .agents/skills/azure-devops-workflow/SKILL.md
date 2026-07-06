---
name: Azure DevOps Workflow — Unipago
description: Event-driven ADO transitions (state changes, element creation) → see §6 in workflow-router.md
---

# Azure DevOps Workflow — Unipago

## Process: CMMI

## Work Item Hierarchy

```
Epic
└── Feature
    └── Requirement
        ├── Task
        ├── Bug
        ├── Modelo de Datos
        ├── Servicio
        └── Estructuras de Datos
```

Epic: solo analyst. Feature: analyst o developer. Requirement: analyst. Bug: developer o qa.

## States (CMMI)

Proposed → Active → Resolved → Closed

> Event-driven ADO transitions (state changes, element creation) → see §6 in workflow-router.md

## Naming Convention

Pattern: `[Producto] [Módulo] [Sub-área?] - Descripción`

Source: `[Producto]` = product name from `product.md`. `[Módulo]` = feature name or spec folder.

| WI Type | Format | Example |
|---|---|---|
| Epic | `[Producto] - {iniciativa}` | `[Unipago] Plataforma de Validaciones TSS` |
| Feature | `[Producto] [Módulo] - {desc}` | `[Koneksi] [Tasks] - API de gestión de tareas` |
| Requirement | `[Producto] [Módulo] [Área] - {desc}` | `[Koneksi] [Tasks] [Due Dates] - Validación de fechas` |
| Task | `[Producto] [Módulo] TASK-{N}: {acción}` | `[Koneksi] [Tasks] TASK-001: Crear endpoint POST /tasks` |
| Bug | `[Producto] [Módulo] BUG: {desc}` | `[Koneksi] [Tasks] BUG: Fecha pasada no retorna 400` |
| Modelo de Datos | `[Producto] [Módulo] MD: {table}` | `[Koneksi] [Tasks] MD: authorization` |
| Servicio | `[Producto] [Módulo] SVC: {METHOD} {route}` | `[Koneksi] [Tasks] SVC: POST /api/v1/tasks` |
| Estructuras de Datos | `[Producto] [Módulo] ED: {schema}` | `[Koneksi] [Tasks] ED: TaskDueDateSchema` |
| Test Plan | `[Producto] [Módulo] TP: {scope}` | `[Koneksi] [Tasks] TP: Sprint 1` |
| Test Case | `[Producto] [Módulo] TC-{NNN}: {scenario}` | `[Koneksi] [Tasks] TC-001: Crear tarea con fecha válida` |

## Linking

- Each commit/PR linked to work item: `AB#123`
- Each test case linked to requirement
- Each bug linked to the test case that found it

## Test Plans

- Create Test Plan per sprint/feature
- Test Cases linked to Requirements
- Results recorded in Azure DevOps

For Definition of Done, see `qa-strategy.md`.

## Element mapping reference

| SDD Artifact | ADO Element | Hierarchy | MCP Tool |
|---|---|---|---|
| Feature (top-level capability) | Feature | Child of Epic | `create_work_item` (type: Feature) |
| Requirement from requirements.md | Requirement | Child of Feature | `create_work_item` (type: Requirement) |
| Task from tasks.md | Task | Child of Requirement | `create_work_item` (type: Task) |
| DB Table from design.md §3.2 | Modelo de Datos | Child of Requirement | `create_work_item` (type: Modelo de Datos) |
| API Endpoint from design.md §3.3 | Servicio | Child of Requirement | `create_work_item` (type: Servicio) |
| Data Schema from design.md §3.1 | Estructuras de Datos | Child of Requirement | `create_work_item` (type: Estructuras de Datos) |
| Test plan | Test Plan | Linked to Requirement | `create_test_plan` |
| Test case | Test Case | Child of Test Plan | `create_test_case` |
| Bug | Bug | Related link to parent | `create_work_item` (type: Bug) |
| Code review | Pull Request | Branch-based | `create_pull_request` |

**Field format:**
- Description: plain text or HTML, max 32KB
- Repro Steps (Bug): numbered steps

## Field fallback (CMMI)

`Acceptance Criteria` is NOT native to CMMI process. Before writing:
1. Try `Acceptance Criteria` field
2. If field not found → write in `Description` (append with `<hr>` separator)
3. Log: "⚠️ Acceptance Criteria no disponible, usando Description"

Safe fields (always exist): Title, Description, Priority, Tags, State, Stack Rank

## Campos por tipo de WI (CMMI nativo)

| WI Type | Description | Impact Assessment | Business Value | Tags |
|---------|-------------|-------------------|----------------|------|
| Epic | Objetivo negocio + alcance + KPIs | ❌ | Numérico (1-100) | — |
| Feature | Contexto + links a specs en Git | ❌ | Numérico (1-100) | stack |
| Requirement | EARS format + spec link | ✅ | ❌ | — |
| Task | Instrucciones implementación | ❌ | ❌ | — |
| Bug | Repro steps + expected vs actual | ❌ | ❌ | severity |
| Modelo de Datos | HTML table: columnas, tipos, FKs | ❌ | ❌ | — |
| Servicio | Endpoint: method, route, schemas | ❌ | ❌ | — |
| Estructuras de Datos | Fields, types, validation rules | ❌ | ❌ | — |

> Git (specs/) = fuente de verdad. ADO = espejo de gestión con link al .md.

## Comment format

All ADO comments follow this structure:

```
[POWER_NAME] — [ACTION]
---
[Details 1-3 lines]
Artifact: [filename]
Branch: [branch]
```

## Iteration Path format

`{project}\Sprint {N}` — set via `System.IterationPath` field.
Sprint number from sprint-planner or ADO board.

## Pull Request fields

| Field | Value |
|---|---|
| Source branch | feature/{prefix}ID-name or fix/{prefix}ID-name |
| Target branch | dev (default) or cert (hotfix) |
| Reviewers | From .sdd-config.json `team` or ask user |
| Work Item link | AB#{ID} from current spec |
| Merge policy | Squash merge, auto-delete branch |

## Repo links in WIs

Every WI created by SDD MUST include a link to its source file in the repo.

| WI Type | Link to | Field |
|---------|---------|-------|
| Requirement | requirements.md | Description or Comment |
| Task (child) | tasks.md#task-N | Description |
| Modelo de Datos | design.md#table-{name} | Description |
| Servicio | design.md#endpoint-{method}-{route} | Description |
| Estructuras de Datos | design.md#schema-{name} | Description |
| Test Plan | test-plan.md | Description |
| Test Case | test-plan.md#TC-NNN | Description |
| Bug | test-plan.md (failed TC) | Repro Steps |

Format: `{repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/{file}`
Where `repo_url` = from `.sdd-config.json` host field or git remote.

### Post-merge link update

After feature branch is merged to `dev` and deleted:

1. All child WIs (Tasks, Modelo de Datos, Servicio, Estructuras de Datos, Test Plans, Test Cases, Bugs): update Description links `blob/feature/...` → `blob/dev/...`
2. Parent WI: state → Resolved, comment: `Merged to dev via PR#{N}`
3. Spec file footers: update branch reference to `dev`

Files in `specs/` survive the merge — only the branch name in URLs changes.
