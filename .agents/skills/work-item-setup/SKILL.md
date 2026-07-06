---
name: Work Item Setup
description: creates work items in tracker and branches based on spec_prefix configuration
---

## ⚠️ MANDATORY CHECKLIST — verify EVERY step

0. ☐ **Read `docs_language`** → from `.sdd-config.json`. Work item titles and descriptions MUST be in this language. Default: `"es"`.
1. ☐ **Read config** → .sdd-config.json: spec_prefix, project_host
2. ☐ **Check current branch** → `git rev-parse --abbrev-ref HEAD`
2b. ☐ **Field discovery** → BEFORE creating any WI:
    1. Get custom fields: `get_work_item_type_fields(type)` → filter TWO sets:
       - **Required**: `alwaysRequired = true` AND NOT safe field
       - **Identity**: all fields where `isIdentity = true` (even if not required)
    2. For each custom field, get metadata:
       `curl.exe -s -u ":$PAT" "https://dev.azure.com/{org}/_apis/wit/fields/{fieldReferenceName}?api-version=7.1"`
    3. Handle by field type:
       - `isPicklist: true` → get options via API. Then PROPOSE the most logical value based on context + show 2-3 alternatives inline. If >5 options, do NOT list all. Example: `Prioridad: **Alta** (otras: Media, Baja)`. Present ALL picklists together as a compact confirmation block, not one-by-one.
       - `type: "dateTime"` → auto-fill current date
       - `isIdentity: true` → map SDD role to field, propose `git config user.email` for matching role:
         · analyst/analista fields → fill if current power = requirements-analyst
         · developer/desarrollo fields → fill if current power = solution-designer/implementer
         · sqa fields → fill if current power = qa-engineer
         · negocio fields → ask user
       - `type: "string"` (no picklist) → ask user for value
       - `readOnly: true` or rules affect the field → investigate with `GET _apis/work/processes/{processId}/workItemTypes/{witRefName}/rules` (see azure-devops-workflow.md §Investigation Endpoints). Two cases:
         **Case A — Computed field** (`SetByRule`, `CopyValue`): Field is auto-assembled from other fields.
          · DO NOT send this field. Discover which Custom.* fields feed the rule.
          · Set THOSE source fields instead. ADO will auto-compute the derived field.
          · If source fields don't exist on the WI type → broken template. Inform user: "ADO template has broken rule. Title depends on [fields] but they don't exist on this WI type."
         **Case B — Group permission** (`MakeReadOnly` with group condition): Field is writable only for users in a specific ADO group.
          · ⚠️ This is a **PAT-level block** — ADO checks the PAT owner, NOT `AssignedTo`. Changing assignee does NOT help. The API call itself is rejected.
          · **Query who CAN create it** — filter by PROJECT first, fallback to org:
            1. Convert group GUID to descriptor: `curl.exe -s -u ":$PAT" "https://vssps.dev.azure.com/{org}/_apis/graph/descriptors/{groupGUID}?api-version=7.1-preview.1"` → extract `value`
            2. List group members (direction=down): `curl.exe -s -u ":$PAT" "https://vssps.dev.azure.com/{org}/_apis/graph/Memberships/{descriptor}?direction=down&api-version=7.1-preview.1"` → array of `memberDescriptor`
            3. Resolve each member: `curl.exe -s -u ":$PAT" "https://vssps.dev.azure.com/{org}/_apis/graph/users/{memberDescriptor}?api-version=7.1-preview.1"` → `displayName`, `mailAddress`
            4. Get project team members: `curl.exe -s -u ":$PAT" "https://dev.azure.com/{org}/_apis/projects/{project}/teams/{project}%20Team/members?api-version=7.1"` → project member emails
            5. **Intersect**: show only users who are in BOTH the group AND the project team
            6. If intersection is empty → show ALL org-wide group members
          · Present to user with full WI details for manual creation:
            ```
            ⚠️ Cannot create [WI type] via API — PAT blocked by rule [rule_name].
            ADO validates the PAT owner, not AssignedTo. Your PAT user is not in group [group_name].
            
            Project members who CAN create it:
            1. Ana García (ana@company.com)
            
            WI details for manual creation in ADO:
            - Type: [Servicio]
            - Parent: AB#[ID]
            - Title: [proposed title]
            - Description: [proposed description]
            
            Ask one of the above to create it in ADO, or request group access for your user.
            ```
          · If group member query fails (PAT lacks `vso.graph` scope) → ask user: "Who can create this WI?"
          · **Skip this WI** and continue with other WIs that CAN be created. Do NOT block the entire flow.
    4. **State discovery** → NEVER hardcode state names ("Active", "Closed", etc.):
       a. Get processId: `curl.exe -s -u ":$PAT" "https://dev.azure.com/{org}/_apis/work/processes?api-version=7.1"` → match project's process
       b. Get valid states: `curl.exe -s -u ":$PAT" "https://dev.azure.com/{org}/_apis/work/processes/{processId}/workItemTypes/{witRefName}/states?api-version=7.1"`
       c. Map SDD phase to state by `stateCategory`:
          · `Proposed` → initial (e.g. "Nuevo")
          · `InProgress` → match by phase name pattern (e.g. "En Evaluación", "En construcción")
          · `Completed` → done (e.g. "Cerrado")
          · `Removed` → cancelled
       d. If multiple InProgress states match → show options, let user pick
    5. Pass ALL fields (standard + custom) in `wit_create_work_item`. Exclude `readOnly` fields.
    6. Fallback: if curls fail → ask user for field values manually
    
    ⚠️ RULES:
    - Use raw PAT (`$PAT`), NOT base64-encoded (`$PAT_B64`)
    - **Windows**: Always use `curl.exe` (not `curl`). PowerShell aliases `curl` to `Invoke-WebRequest` which breaks `-u` flag.
    - Run curl inline — do NOT create script files (.sh, .py, .js)
    - Cleanup: delete ONLY temp files YOU created during discovery (e.g. .json dumps)
    - NEVER delete project files (.sdd-config.json, product.md, specs/, etc.)
    
    ### Iteration management (MCP tools — do NOT claim "can't do X")
    | Action | Tool | Key Params |
    |---|---|---|
    | Create iteration + dates | `work_create_iterations` | `iterations: [{iterationName, startDate, finishDate}]` |
    | Assign to team | `work_assign_iterations` | `project, team, iterations` |
    | List iterations | `work_list_iterations` | `project` |
    | Assign WI to iteration | `wit_update_work_item` | set `System.IterationPath` |
    | Query children | `wit_get_work_item` | `expand: "relations"` |
3. ☐ **Infer type** → Epic / Feature / Requirement / Bug from user intent
4. ☐ **Check hierarchy** → Query ADO:
   - If type = Epic → create top-level (no parent needed)
   - If type = Feature → ask: "¿Existe un Epic padre?" → list Epics or create without
   - If type = Requirement → list Features: `wit_query_work_items` type=Feature
     → If user picks existing Feature → create Requirement as child
     → If no Feature → ask "¿Creo Feature padre primero?"
5. ☐ **Apply naming** → Title MUST follow this pattern (⚠️ all text inside `[]` MUST be lowercase):
   - Feature: `[producto] [módulo] - {descripción en docs_language}`
   - Requirement: `[producto] [módulo] REQ: {nombre}`
   - Task: `[producto] [módulo] TASK-{N}: {acción}`
   - Bug: `[producto] [módulo] BUG: {desc}`
   - `[producto]` = product name from `product.md` or `.sdd-config.json` (lowercase)
   - `[módulo]` = module/feature name in brackets, lowercase (e.g. `[auth]`, `[core]`, `[tasks]`)
   - Description in `docs_language` (default: español)
   - ❌ `[Task-API] [Auth] - Module` → ✅ `[task-api] [auth] - Módulo de autenticación`
6. ☐ **Check if WI/branch exist** → Don't create duplicates
7. ☐ **Show proposal** → WI type, title, branch name, spec folder — all in one block
8. ☐ **Wait for confirmation** → User approves or adjusts
9. ☐ **Create WI** → ADO/GitHub/Jira via MCP. Pass `parent_id` from step 4 (Epic→Feature, Feature→Requirement).
   + `System.AssignedTo` ← current user email. Tags: [type], Area Path, Iteration if available.
   + State: use state discovery (§2b.4) → set to first `InProgress` state. ⚠️ NEVER leave as "Nuevo" — the WI was just created with content, it must be InProgress.
   + Inform: WI created + assigned + linked to parent.
10. ☐ **Create branch** → `git checkout -b feature/{prefix}[ID]-[name]`. Inform: branch created
11. ☐ **Create spec folder** → `mkdir specs/{prefix}[ID]-[name]/`
12. ☐ **Show 📍 position + "¿Qué hacemos?"** → STOP. Do NOT suggest or execute role changes.

---

## Work item creation

Read `spec_prefix` from `.sdd-config.json`:

| spec_prefix | System | MCP | Action |
|---|---|---|---|
| AB# | Azure DevOps | azure-devops | create_work_item |
| GH# | GitHub Issues | github | create_issue |
| JIRA- | Jira | (no MCP) | Ask user for ID |
| (empty) | None | — | Skip, no ID |

### Propose before creating

Present to user:
- Work item type: Epic / Feature / Requirement / Bug
- Title: inferred from user request
- Branch: feature/{prefix}{ID}-{name}
- Spec folder: specs/{prefix}{ID}-{name}/

Wait for user confirmation before creating.

**Types NOT created here:** Task, Modelo de Datos, Servicio, Estructuras de Datos — created by solution-designer after design approval.

**Role restrictions:**

| Type | Roles allowed |
|------|---------------|
| Epic | analyst |
| Feature | analyst, developer |
| Requirement | analyst |
| Bug | developer, qa |

### ⚠️ If tracker MCP is unavailable

| spec_prefix | MCP required | If MCP unavailable |
|---|---|---|
| AB# | azure-devops | **BLOCK**: "ADO no disponible. Verifica credenciales o corre `sdd-sync.sh --refresh`." |
| GH# | github | **BLOCK**: "GitHub MCP no disponible." |
| JIRA- | — | Ask user for ID (no MCP needed) |
| (empty) | — | Skip WI, create branch without prefix. **WARN**: `⚠️ Rama sin WI ID. La trazabilidad ADO no funcionará hasta asociar un WI.` |

**NEVER create a branch without the {prefix}{ID} when spec_prefix is configured.** A branch like `feature/validador-cedula` when spec_prefix is `AB#` is a standard violation.

### If branch/WI already exist
- Check if branch exists: `git branch --list feature/*{name}*`
- Check if spec folder exists: `ls specs/*{name}*`
- If found → reuse, don't create duplicates. Inform user.

### After creation
- Switch to the new branch
- Create the spec folder
- Show 📍 position + "¿Qué hacemos?" → STOP
