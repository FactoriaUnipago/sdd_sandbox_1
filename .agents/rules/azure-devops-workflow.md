# Azure DevOps Workflow

⚠️ **PROJECT ISOLATION**: ALL ADO operations (queries, WI creation, updates) MUST be scoped to `AZURE_DEVOPS_PROJECT` from `.sdd-config.json` env. Read it once at startup. NEVER query across projects. If using `wit_query_by_wiql`, always include `[System.TeamProject] = '{project}'`. If `wit_my_work_items` returns items from other projects, **discard them**. Listing items from outside the configured project is a HARD VIOLATION.

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

### States per WI Type

| WI Type | State Flow | Trigger |
|---|---|---|
| Epic | Proposed → Active → Resolved → Closed | Roll-up of Features |
| Feature | Proposed → Active → Resolved → Closed | Roll-up of Requirements |
| Requirement | Proposed → Active → Ready for Design → In Progress → Ready for QA → Resolved → Closed | SDD lifecycle events |
| Task | Proposed → Active → In Progress → Closed | Implementer selects → codes → completes |
| Modelo de Datos | Proposed → Active → Resolved | Design approved → impl starts → all tasks done |
| Servicio | Proposed → Active → Resolved | Design approved → impl starts → all tasks done |
| Estructuras de Datos | Proposed → Active → Resolved | Design approved → impl starts → all tasks done |
| Test Plan | Proposed → Active → Resolved → Closed | Created → execution → all run → sign-off |
| Test Case | Design → Ready → Passed/Failed/Blocked | Azure Test Plans states |
| Bug | Proposed → Active → Resolved → Closed | Created → dev takes → fixed → QA verifies |

## Universal WI Creation Rule (applies to ALL powers)

⚠️ **BEFORE** any `wit_create_work_item` or `wit_update_work_item` call:

1. **Field discovery (§2b)** → Discover required fields + picklist values for the target WI type
2. **State discovery (§2b.4)** → Discover valid states. Do NOT hardcode "Proposed", "Active", etc.
3. **Propose values proactively** → Present compact confirmation block with values inferred from context
4. **ONLY AFTER confirmation** → Execute the create/update call
5. **Parent link** → AFTER creating the WI, link it to its parent:
   ```
   wit_work_items_link(
     source_work_item_id: {new_wi_id},
     target_work_item_id: {parent_id},
     link_type: "System.LinkTypes.Hierarchy-Reverse"
   )
   ```
   ⚠️ `System.Parent` field in `wit_create_work_item` does **NOT** create the hierarchy link. It is IGNORED by ADO.
   You MUST call `wit_work_items_link` separately after creation. Without this, the WI appears orphaned.

❌ **PROHIBITED**: The "create → fail → ask user" pattern.
❌ **PROHIBITED**: Asking user "what fields are required?" or "(ej. Alta, Media, Baja)".
❌ **PROHIBITED**: Hardcoding states without discovery. Use §2b.4 to get real state names.
❌ **PROHIBITED**: Assuming `System.Parent` in create fields creates a link. It does NOT.

This rule applies to: work-item-setup, requirements-analyst, solution-designer, implementer, qa-engineer, sprint-planner, backlog-manager — any power that touches ADO WIs.

## Naming Convention

Pattern: `[producto] [módulo] [sub-área?] - Descripción`

Separator is ` - ` (space, dash, space). ⚠️ NEVER use `/`, `:`, or other separators between Módulo and Descripción.

Source: `[producto]` = product name from `product.md` (lowercase). `[módulo]` = feature name or spec folder (lowercase).

⚠️ **All text inside brackets `[]` MUST be lowercase**. Examples: `[task-api]`, `[core]`, `[auth]`. NEVER `[Task-API]`, `[Core]`, `[Auth]`.

⚠️ **Duplicate check**: Before creating any WI, query ADO with WIQL using `CONTAINS` (case-insensitive). If a WI with the same type and similar title already exists under the same parent → do NOT create. Inform user of the existing WI.

| WI Type | Format | Example |
|---|---|---|
| Epic | `[producto] - {iniciativa}` | `[my-product] - Plataforma de Validaciones TSS` |
| Feature | `[producto] [módulo] - {desc}` | `[koneksi] [tasks] - API de gestión de tareas` |
| Requirement | `[producto] [módulo] [área] - {desc}` | `[koneksi] [tasks] [due-dates] - Validación de fechas` |
| Task | `[producto] [módulo] TASK-{N}: {acción}` | `[koneksi] [tasks] TASK-001: Crear endpoint POST /tasks` |
| Bug | `[producto] [módulo] BUG: {desc}` | `[koneksi] [tasks] BUG: Fecha pasada no retorna 400` |
| Modelo de Datos | `[producto] [módulo] MD: {table}` | `[koneksi] [tasks] MD: tasks` |
| Servicio | `[producto] [módulo] SVC: {METHOD} {route}` | `[koneksi] [tasks] SVC: POST /api/v1/tasks` |
| Estructuras de Datos | `[producto] [módulo] ED: {schema}` | `[koneksi] [tasks] ED: TaskDueDateSchema` |
| Test Plan | `[producto] [módulo] TP: {scope}` | `[koneksi] [tasks] TP: Sprint 1` |
| Test Case | `[producto] [módulo] TC-{NNN}: {scenario}` | `[koneksi] [tasks] TC-001: Crear tarea con fecha válida` |

## Description Format Convention

**Format rules:**
- `wit_create_work_item` → set `format: "Markdown"` for text-only descriptions. Set `format: "HTML"` when description contains tables (MD, SVC, ED types).
- `wit_update_work_item` → JSON Patch has NO format flag — write in HTML (`<h2>`, `<b>`, `<ul>`, `<li>`, `<p>`, `<a>`, `<table>`)
- ⚠️ NEVER send raw Markdown to `wit_update_work_item` — it renders as plain text with literal asterisks

**Standard Description structure by WI type:**

### Epic
```markdown
## Objetivo
{Objetivo de negocio — 1-2 líneas}

## Alcance
- {Módulo o área 1}
- {Módulo o área 2}

## KPIs
- {Métrica medible 1}
- {Métrica medible 2}

## Repo
[Ver specs]({repo_url}/tree/{branch}/specs/)

— 📋 SDD · backlog-manager · {YYYY-MM-DD}
```
Format: `"Markdown"`. Example title: `[koneksi] - Gestión de tareas colaborativas`

### Feature
```markdown
## Resumen
{Qué capability agrega — 1-2 líneas}

## Requerimientos vinculados
- REQ-001: {título corto}
- REQ-002: {título corto}

## Stack
{stack si aplica: node, angular, flutter, etc.}

## Repo
[Ver specs]({repo_url}/tree/{branch}/specs/{prefix}{ID}-{name}/)

— 📋 SDD · requirements-analyst · {YYYY-MM-DD}
```
Format: `"Markdown"`. Updated at two stages: after reqs approved (adds REQs list), after design approved (adds stack tag).

### Requirement
```markdown
## Requerimientos ({módulo})

- **REQ-001:** WHERE {contexto}, WHEN {trigger}, THE {sistema} SHALL {acción}
- **REQ-002:** WHILE {estado}, THE {sistema} SHALL {acción}

---

## Criterios de aceptación
- [ ] {criterio 1}
- [ ] {criterio 2}

## Repo
[Ver requirements.md]({repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/requirements.md)

— 📋 SDD · requirements-analyst · {YYYY-MM-DD}
```
Format: `"Markdown"` for create, HTML for update. Note: CMMI has no Acceptance Criteria field — all goes in Description.

### Task
```markdown
## Descripción
{Qué implementar — instrucciones concretas}

## REQ vinculado
REQ-{NNN}: {título}

## Estimación
{N} horas

## Repo
[Ver tasks.md]({repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/tasks.md#task-{N})

— 📋 SDD · solution-designer · {YYYY-MM-DD}
```
Format: `"Markdown"`.

### Bug
```markdown
## Pasos para reproducir
1. {Paso 1}
2. {Paso 2}
3. {Paso 3}

## Resultado esperado
{Qué debería pasar}

## Resultado actual
{Qué pasa en realidad}

## Evidencia
- Test Case: TC-{NNN}
- Branch: {branch}
- Error: `{mensaje si aplica}`

## Repo
[Ver test-plan.md]({repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/test-plan.md#TC-{NNN})

— 📋 SDD · qa-engineer · {YYYY-MM-DD}
```
Format: `"Markdown"`. Also populate Repro Steps field if available.

### Modelo de Datos
Format: `"HTML"` — table with inline styles on every `<td>`/`<th>` (see §Tables in descriptions below).
Sections: Columns table (name, type, nullable, default, constraints, description) + Indexes table + Repo link.
```
Repo: {repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/design.md#table-{name}
— 📋 SDD · solution-designer · {YYYY-MM-DD}
```

### Servicio
Format: `"HTML"` if contains tables, `"Markdown"` otherwise.
Sections: `## Endpoint` (method + route + auth) + request/response schemas (HTML tables) + errors + curl example + Repo link.
```
Repo: {repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/design.md#endpoint-{method}-{route}
— 📋 SDD · solution-designer · {YYYY-MM-DD}
```

### Estructuras de Datos
Format: `"HTML"` — table with inline styles.
Sections: Schema table (campo, tipo, requerido, validación, descripción) + Relationships + Repo link.
```
Repo: {repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/design.md#schema-{name}
— 📋 SDD · solution-designer · {YYYY-MM-DD}
```

### Test Plan
```markdown
## Alcance
{Qué se prueba — feature/sprint}

## Tipos de testing
- 🔴 {tipo blocking}
- 🟡 {tipo importante}
- 🟢 {tipo opcional}

## Cobertura
- {N} test cases
- {N} requerimientos cubiertos

## Repo
[Ver test-plan.md]({repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/test-plan.md)

— 📋 SDD · qa-engineer · {YYYY-MM-DD}
```
Format: `"Markdown"`.

### Test Case
```markdown
## Pasos
1. {Precondición}
2. {Acción}
3. {Verificación}

## Resultado esperado
{Qué debe pasar exactamente}

## REQ vinculado
REQ-{NNN}: {título}

## Repo
[Ver test-plan.md]({repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/test-plan.md#TC-{NNN})

— 📋 SDD · qa-engineer · {YYYY-MM-DD}
```
Format: `"Markdown"`.

**Tables in descriptions** — ADO strips `border` attributes from `<table>`. The ONLY way to get visible borders is **inline `style` on every `<th>` and `<td>`**:
```html
<table>
  <tr>
    <th style="border:1px solid #ddd;padding:6px;background:#344563;color:white;">Column</th>
    <th style="border:1px solid #ddd;padding:6px;background:#344563;color:white;">Type</th>
    <th style="border:1px solid #ddd;padding:6px;background:#344563;color:white;">Nullable</th>
    <th style="border:1px solid #ddd;padding:6px;background:#344563;color:white;">Default</th>
    <th style="border:1px solid #ddd;padding:6px;background:#344563;color:white;">Constraints</th>
    <th style="border:1px solid #ddd;padding:6px;background:#344563;color:white;">Description</th>
  </tr>
  <tr>
    <td style="border:1px solid #ddd;padding:6px;">id</td>
    <td style="border:1px solid #ddd;padding:6px;">uuid</td>
    <td style="border:1px solid #ddd;padding:6px;">NO</td>
    <td style="border:1px solid #ddd;padding:6px;">gen_random_uuid()</td>
    <td style="border:1px solid #ddd;padding:6px;">PK</td>
    <td style="border:1px solid #ddd;padding:6px;">Identificador único</td>
  </tr>
</table>
```
⚠️ `border="1"` on `<table>` does NOT work in ADO — it gets stripped. You MUST put `style="border:1px solid #ddd;padding:6px;"` on EVERY `<td>` and `<th>`.
⚠️ This applies to BOTH `wit_create_work_item` (set `format: "HTML"`) and `wit_update_work_item`.

**Repo link format (ALWAYS include):**
- GitHub: `https://github.com/{org}/{repo}/blob/{branch}/{path}`
- Azure: `https://dev.azure.com/{org}/{project}/_git/{repo}?path=/{file}&version=GB{branch}`

**Footer (ALWAYS append):**
```
— 📋 SDD · [power-name] · [YYYY-MM-DD]
```

⚠️ ALL powers MUST follow this convention. Do NOT improvise Description format per power.

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
| Test Plan | Alcance + tipos + cobertura | ❌ | ❌ | — |
| Test Case | Pasos + esperado + REQ vinculado | ❌ | ❌ | — |

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

## Environment Promotion (dev → cert → prod)

> Para flujos GitHub + Vercel, ver `deployment-patterns.md`. Esta sección aplica cuando `host: azure-devops`.

Pipeline-driven with approval gates. No extra branches — environments are stages, not branches.

```
feature/* ──PR──→ dev ──gate──→ cert ──gate──→ prod
                   │              │              │
                Auto-deploy    QA valida     Release tag
                (CI/CD)       Smoke tests    vX.Y.Z
                              Approval gate  Approval gate

hotfix/*  ──PR──→ cert ──gate──→ prod ──→ cherry-pick back to dev
```

### Promotion Gates

| Promotion | Approver | Verifies | ADO State |
|---|---|---|---|
| dev → cert | Tech Lead / Developer | Tests pass, PR reviews done, no open WIs for sprint | WIs remain Resolved |
| cert → prod | Product Owner + QA | Smoke tests OK, regression OK, sign-off | WIs → Closed |
| hotfix cert → prod | Tech Lead (fast-track) | Fix verified, no side effects | Bug → Closed |

### Post-Promotion Actions

| Event | Action |
|---|---|
| Deployed to cert | Run smoke tests + regression suite. Tag: `cert-{date}` |
| Deployed to prod | Create release tag `vX.Y.Z`. WIs → Closed. Release notes generated (release-notes-writer) |
| Hotfix to prod | Cherry-pick commit back to `dev` to keep branches in sync |

### Rules

- ⚠️ NEVER deploy to prod without passing cert first (no dev → prod shortcuts)
- ⚠️ Hotfix skips dev but MUST be cherry-picked back after prod deploy
- ⚠️ Each gate requires EXPLICIT approval — auto-promotion is prohibited for cert → prod

## Custom Fields (CMMI)

Some CMMI processes have mandatory custom fields that vary by organization.

**Limitation**: ADO MCP (`get_work_item_type_fields`) returns `allowedValues: []` empty for custom picklists.

**Solution** (verified): 2 curl.exe calls per custom field:
1. `GET _apis/wit/fields/{fieldReferenceName}` → get `picklistId`
2. `GET _apis/work/processes/lists/{picklistId}` → get `items[]` = dropdown allowed values

**Auth**: `-u ":$PAT"` (raw PAT, curl handles base64 encoding)

⚠️ **Windows**: Always use `curl.exe` (not `curl`). PowerShell aliases `curl` to `Invoke-WebRequest` which breaks `-u` flag.

**Safe fields (always exist)**: Title, Description, Priority, Tags, State, Stack Rank, Area Path, Iteration Path
**Fields requiring discovery**: Acceptance Criteria, Impact Assessment, Custom.*

### ADO REST API — Investigation Endpoints

When field discovery finds `readOnly`, `SetByRule`, or unknown required fields, use these endpoints to investigate:

| Purpose | Endpoint | What it returns |
|---------|----------|-----------------|
| **List processes** | `GET _apis/work/processes?api-version=7.1` | All processes → get `processId` for your project |
| **List WI types in process** | `GET _apis/work/processes/{processId}/workitemtypes?api-version=7.1` | All WI types → get `witRefName` |
| **Get WI type fields** | `GET _apis/work/processes/{processId}/workItemTypes/{witRefName}/fields?api-version=7.1` | All fields with `readOnly`, `required`, `defaultValue` |
| **Get WI type rules** | `GET _apis/work/processes/{processId}/workItemTypes/{witRefName}/rules?api-version=7.1` | Rules: `SetByRule`, `MakeReadOnly`, `CopyValue`, conditions → reveals which fields feed computed fields like Title |
| **Get form layout** | `GET _apis/work/processes/{processId}/workItemTypes/{witRefName}/layout?api-version=7.1` | Pages, sections, groups, controls → reveals which custom fields are on the form and their order |
| **Get field metadata** | `GET _apis/wit/fields/{fieldReferenceName}?api-version=7.1` | Field type, `picklistId`, `isIdentity`, `readOnly` |
| **Get picklist values** | `GET _apis/work/processes/lists/{picklistId}?api-version=7.1` | `items[]` = allowed dropdown values |
| **Get WI type states** | `GET _apis/work/processes/{processId}/workItemTypes/{witRefName}/states?api-version=7.1` | Valid states with `stateCategory` (Proposed, InProgress, Completed, Removed) |
| **GUID to descriptor** | `GET https://vssps.dev.azure.com/{org}/_apis/graph/descriptors/{storageKey}?api-version=7.1-preview.1` | Converts group GUID (from rule condition) to descriptor string |
| **List group members** | `GET https://vssps.dev.azure.com/{org}/_apis/graph/Memberships/{descriptor}?direction=down&api-version=7.1-preview.1` | Array of `memberDescriptor` values |
| **Resolve member** | `GET https://vssps.dev.azure.com/{org}/_apis/graph/users/{memberDescriptor}?api-version=7.1-preview.1` | `displayName`, `mailAddress` |
| **Project team members** | `GET https://dev.azure.com/{org}/_apis/projects/{project}/teams/{project}%20Team/members?api-version=7.1` | Members of the project’s default team |

### Investigation flow for ReadOnly fields

When a WI creation fails with `ReadOnly, SetByRule, InvalidEmpty`:

```
1. Get processId     → GET _apis/work/processes
2. Get rules         → GET _apis/work/processes/{processId}/workItemTypes/{witRefName}/rules
3. Classify the rule → inspect actions[] and conditions[]:
```

**Case A — Computed field** (actions contain `setValueToField`):
```
4a. Extract sources → conditions show which Custom.* fields feed the title
5a. Get those fields → verify they exist in the WI type fields list
6a. Set source fields → pass them in wit_create_work_item, skip Title
7a. If sources missing → broken template. Inform user.
```

**Case B — Group permission** (actions contain `makeReadOnly` with group condition):
⚠️ PAT-level block — ADO checks PAT owner, NOT AssignedTo. API call is rejected regardless of assignee.
```
4b. Extract group    → conditions give group GUID (e.g. 031175ca-3691-...)
5b. GUID → descriptor → GET vssps.dev.azure.com/{org}/_apis/graph/descriptors/{GUID}
6b. List members     → GET graph/Memberships/{descriptor}?direction=down → resolve each
7b. Project members  → GET dev.azure.com/{org}/_apis/projects/{project}/teams/{project}%20Team/members
8b. Intersect        → show only users in BOTH group AND project
9b. If intersection empty → show ALL org-wide group members
10b. Present WI details → give user the Type, Parent, Title, Description
     so someone with access can create it manually in ADO
11b. Skip blocked WI → continue creating other WIs that CAN be created
12b. If query fails (PAT lacks vso.graph scope) → ask user who can create it
```

See work-item-setup §2b for the full field discovery checklist.
