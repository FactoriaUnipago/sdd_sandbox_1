---
name: Workflow Router
description: routes user requests to the correct power/role, output format, communication style
---

## ⛔ THE 7 RULES (violating any = failure)

1. **MCP FIRST** — Before any power: execute Step 0 (required MCPs). No verified MCP = do NOT proceed.
2. **TEMPLATE FIRST** — Before generating ANY file: read the template in `specs/_templates/` or `.sdd-config.template.json`. Do NOT invent sections, fields, or structures.
3. **LANGUAGE** — All generated content in `docs_language` from .sdd-config.json (default: `es`). Technical terms in English OK.
4. **ADO SCOPED** — Every ADO operation includes `[System.TeamProject] = '{project}'`. Items from other projects = discard.
5. **ONE AND APPROVE** — Generate one file → show it → wait for explicit approval ("dale", "apruebo", "ok") → advance.
6. **EXISTS = HAS CONTENT** — product.md < 50 lines = placeholder = does not exist → trigger scanner. Spec < 10 lines or no `##` headings = does not exist.
7. **EXPLICIT ACTION** — Greeting, item selection, or "vamos" ≠ "proceed". Only execute with clear instruction. Show context + "¿En qué trabajamos?" and **STOP**.

## ⚠️ MANDATORY — execute before EVERY user request

1. ☐ **Read config** → `.sdd-config.json`: role, verbosity, project_type
2. ☐ **First interaction?** → Read and execute `precheck.md` IN ORDER. Do NOT skip.
3. ☐ **Load steering triggers** → Read files from §1 that apply to this request
4. ☐ **Show context** → §2 format (skip if already shown this session)
5. ☐ **Actionable?** → User stated a clear action? If NO → **STOP: show context + "¿En qué trabajamos?"**. NEVER infer action from branch/files alone
6. ☐ **Match intent** → Find power in routing table (§4). If no match → ask user
7. ☐ **Verify lifecycle** → Check prerequisites (§5). Missing → **BLOCK** with reason
8. ☐ **Load pre-tasks** → Check §3 (work-item-setup, role-enforcement, etc.)
9. ☐ **Delegate** → Execute the matched power's mandatory checklist

**NEVER skip steps 5-7.** Step 5 is a HARD GATE: no clear user action = no power execution.

**ANTI-FLIP-FLOP**: HOLD your technical opinions. Only change if user provides NEW information.

**sdd-config.json**: NEVER edit manually. Use `sdd-sync.sh`:
- Role change → `bash sdd-sync.sh --role [role] --force`
- Standard update → `bash sdd-sync.sh --force`

**RETROFIT**: When touching ANY spec file: verify traceability header + footer + ADO WI link. No spec without traceability.

**CONSULT → CONFIRM → GENERATE**: Before creating ANY spec file:
1. Read inputs → 2. Propose key decisions → 3. Get confirmation → 4. ONLY THEN generate

| Power | Artifact | What to propose before generating |
|---|---|---|
| requirements-analyst | requirements.md | REQ list (ID + title + EARS rule) — review one by one |
| solution-designer | design.md | Stack, DB, API pattern, auth, infra |
| implementer | tasks.md | Task breakdown (list of tasks with estimates) |
| qa-engineer | test-plan.md | Test strategy, types, coverage scope |
| migration-planner | migration-plan.md | Migration approach, phases, rollback strategy |

❌ PROHIBITED: Reading inputs → generating full file → "¿Apruebas?" (no consultation)
✅ CORRECT: Reading inputs → proposing decisions → confirming → generating file

**ADO updates = FIELDS, not just comments.** Content changes → update WI fields. Comments = audit trail only.

---

## 1. Steering triggers — read when applicable

| Trigger | File | What it controls |
|---|---|---|
| Working with specs | `spec-integration.md` | Spec folder naming, template usage, IDE spec mode |
| Choosing tech stack | `tech.md` | Approved stacks, versions, selection criteria |

> `protected-files.md` and `token-optimization.md` are alwaysApply — already in context.
> `tool-protocol.md` loads via globs (specs/, product.md, .sdd-config.json).

## 2. Show context

Read `verbosity` from `.sdd-config.json` (default: `detailed`).

Detect: role, branch, environment (dev/cert/main/feature→Dev, hotfix→Prod), assigned work items.

Query ADO for items assigned to user's email:

⚠️ **ALL ADO queries MUST be scoped to the configured project** (`AZURE_DEVOPS_PROJECT` from `.sdd-config.json` env). NEVER query across projects. NEVER list items from other projects. If WIQL is used, always include `[System.TeamProject] = '{project}'`. If a tool returns items from another project, discard them.

| Role | Filter by state |
|------|----------------|
| Analyst | New, Approved, Ready for Design |
| Developer | Ready for Design, In Progress, Ready for QA |
| QA | Ready for QA, In Testing, Ready for Release |

### Cross-branch lifecycle detection

On `dev`/`main`/`cert` (non-feature):
1. Query tracker for assigned items → `git branch -r --list "*/feature/*{ID}-*"`
2. Detect lifecycle remotely: `git ls-tree -r --name-only origin/feature/{prefix}{ID}-xxx -- specs/`
3. Check each spec: requirements.md exists? approved (`- [x]`)? design.md? tasks.md? test-plan.md?
   ⚠️ **Content validation**: A spec file "exists" only if it has > 10 lines AND at least one `##` heading. Empty/stub files (< 10 lines or no headings) = treat as missing.
4. Build 📍 from remote contents → show items with position + branch
5. User picks item → `git checkout feature/{prefix}{ID}-xxx` → re-detect locally

On **feature branch** → skip cross-branch, use local `specs/`.

**Non-feature branch output**: `👤 [Name] · 📋 [role] · 🌿 dev` + items list (`{prefix}{ID} — Title (📍 position) 🌿 branch`) + `¿En cuál trabajamos?`

**`detailed`** — user, role, branch, env, items, review flags. **`brief`** — `📋 [role] · 🌿 [branch] · [N] items` + `¿Cuál?`

**Clear intent** ("diseña", "implementa task 3") → skip items query, proceed. **Ambiguous/greeting** → show FULL context + WAIT. **ADO unavailable** → skip items, continue.

**Selection disambiguation:** Options presented + vague response ("algo sencillo", "el más rápido") → suggest recommendation + ASK. Do NOT auto-select.

**Hypothetical ≠ approval:** "si apruebo...", "¿qué harás?", "¿qué pasaría si..." → DESCRIBE the plan. Do NOT execute. Wait for explicit "sí", "dale", "apruebo".

### Role capabilities (MANDATORY in opening message)

ALWAYS include role capabilities in the opening paragraph, even if health check had errors. Map from §4 powers:

- **Analyst**: requirements-analyst, backlog-manager, sprint-planner, release-notes-writer, test-data-generator, migration-planner
- **Developer**: solution-designer, implementer, code-reviewer, db-migrator, pipeline-builder, aws-deployer, vercel-deployer, migration-planner, doc-generator
- **QA**: qa-engineer, api-tester, regression-analyst, test-data-generator

### Lifecycle position + opening message

Detect current step by scanning spec folder:

| Condition | 📍 Show |
|---|---|
| project_type empty | 📍 Nuevo — proyecto sin configurar |
| No spec folder | 📍 Crear work item |
| requirements.md missing | 📍 Crear requirements.md |
| requirements.md `- [ ]` | 📍 Aprobar requirements.md |
| requirements.md `- [x]`, no design.md | 📍 Crear design.md |
| design.md `- [ ]` | 📍 Aprobar design.md |
| design.md `- [x]`, no tasks.md | 📍 Generar tasks.md |
| All exist, tasks incomplete | 📍 Implementar (N/M tasks) |
| All tasks done | 📍 Ejecutar tests |

**Lifecycle roadmap (MANDATORY in opening message):** Show full path with current step bold:

Standard: `📍 **reqs** → design → tasks → impl → test → PR`

Migration (`project_type = "migration"`): `📍 scan → **migration-plan** → reqs (per phase) → design → tasks → impl → test → cutover`

In progress: `📍 reqs → design → tasks → **impl [3/5]** → test → PR`

`brief` mode: `📍 1/6 reqs`

### ⚠️ HARD GATE — One file at a time

**NEVER create the next lifecycle file without explicit user approval.** Each spec file is a STOP point:

1. Create ONE file (e.g., design.md)
2. Show it to user: `✅ Guardado → 📄 [file]`
3. Ask: `¿Apruebas? ¿Ajustes?`
4. **STOP. WAIT for response.**
5. Only after explicit approval → advance 📍 to next step

**What counts as approval**: "dale", "apruebo", "ok", "sí", "lgtm", "next", checkbox marked `- [x]`.
**What does NOT**: selecting an item, navigating to a branch, saying "vamos", greeting.

**Item selection ≠ action.** When user selects a tracker item ("vamos a ese", "ese", "el primero"):
1. Checkout the branch
2. Re-detect lifecycle
3. Show context: `📍 [position]` + `¿Qué hacemos?`
4. **STOP. Do NOT auto-create any file.**

### Output format

**`detailed`** — `👤 [Name] · 📋 [role] · 🌿 [branch]` + `📍 [position]` + capabilities list (each on own line with `- ` prefix) + `¿En qué trabajamos?`. If role-blocked: `❌ [task] bloqueado — cambiar con: bash sdd-sync.sh --role [role] --force` + list what user CAN do.

**`brief`** — `📋 [role] · 🌿 [branch] · 📍 [position]` + lifecycle question (1 line).

**CRITICAL**: Each capability MUST be on its own line with `- ` prefix. NEVER paragraph. Developer/QA can `➕ Crear nuevo feature/WI`. Analyst cannot.

### New feature branching rule

When user wants to create a NEW feature/WI from ANY branch:
1. Create WI in tracker
2. `git stash` if there are uncommitted changes
3. `git checkout dev` → `git pull origin dev`
4. `git checkout -b feature/{prefix}{ID}-name`
5. Continue with requirements in the new branch

**NEVER create a feature branch from another feature branch.** Always from `dev`.

### Review flags

- Tag `needs-clarification` → `⚠️ needs-clarification` + show feedback comment
- Spec has `⚠️ REQUIRES REVIEW` → `⚠️ design.md requires review`

## 3. Before delegating to a power

| Situation | Load power/skill |
|---|---|
| New feature/fix without branch | work-item-setup |
| Role validation needed | role-enforcement |
| Commit/push | git-conventions |
| Spec changed | change-propagation |

> `project-initializer` and `project-scanner` are triggered by `precheck.md` (first interaction), not by this routing table.

## 4. Route to power

| User asks to... | Step | Role | Output |
|---|---|---|---|
| Create/analyze requirements | 1 | 📋 Analyst | `requirements.md` (EARS) |
| Select technologies | 1.5 | 💻 Developer | Tech in design.md |
| Create design/architecture | 2 | 💻 Developer | `design.md` |
| Create test plan | 3 | 🧪 QA | `test-plan.md` |
| Implement code | 4 | 💻 Developer | Code + tests + tasks.md |
| Review code (PR) | 4.5 | 💻 Developer | PR comments |
| Execute tests | 5 | 🧪 QA | Run test plan |
| Migrate/upgrade/modernize | M | 💻 Developer | `migration-plan.md` |
| Deploy | D | 💻 Developer | AWS CDK + smoke tests |
| Prepare release | 7 | All | Sign-off |

### Lifecycle suggestions

| Event | Suggest power | Condition |
|---|---|---|
| design.md saved with DB changes | db-migrator | New tables/columns |
| First design with Infrastructure | pipeline-builder | No CI/CD yet |
| All tasks complete | code-reviewer | Before QA handoff |
| QA approved | aws-deployer | If stacks include aws |
| QA approved | vercel-deployer | If stacks include vercel |
| Merge to main | release-notes-writer | WIs completed in sprint |

### On-demand powers (cross-role — available regardless of current role)

⚠️ These powers trigger on keywords regardless of whether user is analyst, developer, or QA. Do NOT interpret "qué hay pendiente" as "next lifecycle step" — it means "show me the backlog".

| Keywords | Power |
|---|---|
| backlog, priorizar, grooming, refinement, **qué hay pendiente**, **qué falta**, **items**, **lista de tareas** | backlog-manager |
| sprint, planificar, velocity, capacity, **cómo va el sprint**, **burndown**, **cierre**, **carryover** | sprint-planner |
| test api, postman, endpoint test | api-tester |
| regresión, flaky, test history | regression-analyst |
| test data, seed, fixtures | test-data-generator |
| documentation, readme, api docs, adr | doc-generator |

## 5. Lifecycle dependency enforcement

**No step can be skipped.** Verify prerequisites:

| Task | Requires | Verify |
|---|---|---|
| Design (2) | requirements.md approved | `## Approval` has `- [x]` |
| Tech selection (1.5) | requirements.md exists | File exists |
| Test plan (3) | requirements.md exists | File exists |
| Implementation (4) | design.md + tasks.md | Both exist |
| Test execution (5) | test-plan.md | File exists |

**Approval flow:**
1. After generating artifact → "¿Lo apruebas?"
2. User approves → update `- [ ]` → `- [x]` with name and date
3. If user says "diseña" but requirements `- [ ]` → **BLOCK**: "Requirements necesita aprobación primero."

Missing prerequisite → **block and explain**. No workarounds.

**Language rule (ALL powers):**
Before generating ANY content (files, ADO fields, chat summaries, output reports):
1. Read `docs_language` from `.sdd-config.json`
2. ALL generated text MUST be in that language. Default: `"es"`
3. **Template Translation:** If a structural template (e.g. from `core/templates/` or `references/`) is written in English, you MUST translate its headers, labels, and table columns to `docs_language` before outputting.
4. Exceptions: EARS keywords (SHALL/WHEN/WHILE/WHERE/IF), code identifiers, technical terms (API, JWT, DB, CRUD), command names
5. Do NOT "detect from user messages" — READ the config

**When blocked by role:** Don't just say "switch roles". Also list what the user CAN do with their current role (from §4 routing table). Example for analyst: "No puedo hacer design (requiere developer). Como analyst puedo: crear requirements para otro WI, organizar backlog, planificar sprints."

**⚠️ Role change restriction:** NEVER run `sdd-sync.sh --role` proactively. The user must EXPLICITLY request a role change ("cambia a developer", "sync con rol developer", etc.). If user says "dale", "sí", "avancemos" after you mention a role switch → that is permission to SUGGEST the command, NOT to execute it. Present: `Corre: bash sdd-sync.sh --role developer` and STOP.

> Output format, interaction pattern, and communication style → see `token-optimization.md` (alwaysApply).

## 6. After commit (all powers)

After ANY `git commit + push`, execute these integrations in order:

⚠️ Push is MANDATORY — commit without push = incomplete. NEVER do commit-only.

| # | Integration | Action | If unavailable |
|---|---|---|---|
| 1 | **server-memory** | Persist power-specific data (each power's checklist defines what) | Skip silently |
| 2 | **ADO** | Update work item per table below | Skip silently |
| 3 | **📍 Refresh** | Recalculate lifecycle, show `✅ Committed: [msg]` + `📍 [next]` | Always |
| 4 | **codebase-memory** | Re-index changed files | Skip silently |

### Post-save checklist (MANDATORY after saving ANY spec file)

1. ☐ **Provenance header** in file → `> 📋 Generated by [power] · [date]` + `> ✅ Approved by: [pending]`
2. ☐ **ADO update** → Acceptance Criteria (fallback: Description) ← actual REQs (not a summary), in HTML format
3. ☐ **ADO signature** → footer: `— 📋 SDD · [power-name] · [YYYY-MM-DD]`
4. ☐ **ADO file links** → file references in ADO use full remote URL (clickable). Build from `git remote` + branch + path. Azure: `https://dev.azure.com/{org}/{project}/_git/{repo}?path=/{file}&version=GB{branch}`. GitHub: `https://github.com/{org}/{repo}/blob/{branch}/{file}`
5. ☐ **docs_language** → file content and ADO fields in `docs_language` from `.sdd-config.json`
6. ☐ **Cross-document coherence** → Check `change-propagation.md` §Propagation Matrix. If the saved file has downstream dependents, verify shared data (counts, decisions, tech stack) is consistent. If discrepancies found → fix or flag with `⚠️ REQUIRES REVIEW` marker.
7. ☐ **Chat output** → `✅ Guardado → 📄 [file](file:///path)` + approval + `📍 [next]`

> **Do NOT skip any step.** All 7 are mandatory every time a spec is saved.

**ADO actions by artifact (centralized — powers do NOT need their own ADO section):**

**WI type detection (BEFORE any update):** Query parent WI type. Feature/Epic → create child **Requirement**. Requirement → update directly (Acceptance Criteria (fallback: Description)). Task/Bug → update directly (Description). Save resolved `work_wi_id` to server-memory — all subsequent actions use this ID.

| Event | ADO Action | Fields / State |
|---|---|---|
| WI selected (Feature/Epic) | ⚠️ Duplicate check: query ADO by title prefix with WIQL CONTAINS (case-insensitive). If found → skip. Then `create_work_item` → child Requirement | Title, Tags: `[type]`, then `wit_work_items_link` for parent |
| WI selected (Requirement) | No action — use directly | — |
| requirements.md created | `update_work_item` work_wi | Acceptance Criteria (fallback: Description) ← REQs, Priority, State → Active |
| requirements.md approved | `update_work_item` work_wi | State → Ready for Design, Tag: `reqs-approved` |
| design.md created | **No ADO update** — draft only. Wait for approval. | — |
| design.md approved | `update_work_item` work_wi | Description += architecture, Tags: `[stack]`, `design-approved`, Repo link, State → In Progress |
| tasks.md committed | `create_work_item` → **Task** × N | Title, Description + Repo link, Remaining Work, then `wit_work_items_link` to work_wi |
| design.md approved | `create_work_item` → **Modelo de Datos** × N | 1 per DB table §3.2. Title: `[producto] [módulo] MD: {table}`. Skip if frontend-only |
| design.md approved | `create_work_item` → **Servicio** × N | 1 per endpoint §3.3. Title: `[producto] [módulo] SVC: {METHOD} {route}`. Skip if frontend-only |
| design.md approved | `create_work_item` → **Estructuras de Datos** × N | 1 per schema §3.1. Title: `[producto] [módulo] ED: {schema}`. Skip if none |
| test-plan.md committed | Create **Test Plan** + **Test Case** × N | Plan name, Cases, Area Path, State → Ready for Testing |
| Task N completed | `update_work_item` child Task | State → Closed, Comment |
| All tasks done | `update_work_item` work_wi | State → Ready for QA, Story Points, Tag: `implementation-complete` |
| All tasks done | `update_work_item` MD/SVC/ED children | State → Resolved (if they exist) |
| Tests pass | `update_work_item` work_wi | State → Resolved, Comment: results summary |
| Tests fail + approved | `create_work_item` → **Bug** | Title, Repro Steps, Severity, Related link to work_wi |
| Code review | `create_pull_request` | Source → target, Reviewers, WI link |
| Backlog re-prioritized | `update_work_item` × N | Priority + StackRank per WI |
| Migration/DB/Pipeline/Deploy/Release | Comment or update | See `azure-devops-workflow.md` |

**ADO content signature:** Every ADO text field MUST end with: `— 📋 SDD · [power-name] · [YYYY-MM-DD]`

**DUAL UPDATE rule:** Every event requires BOTH: (1) Field update (Description, AC, State, Tags) + (2) Audit comment (what, artifact, branch). One without the other is incomplete.

**MD→HTML:** Description and Acceptance Criteria fields = HTML. Comments = markdown. See azure-devops-workflow.md for field fallback.

**Rollback:** Tests fail / CR rejected / Deploy fails → `update_work_item` parent → In Progress, assign `developer_email`. Reqs rejected → Proposed.

**Assignment:** Default = creator. Reqs approved → ask `developer_email` (design/tasks/bugs/PR inherit). All tasks done → ask `qa_email` (Test Plan/Cases inherit). `role: all` → skip asks. Save emails to server-memory per WI.
**Assignment timing by branch type:**

| Branch | Ask dev | Ask QA | Notes |
|---|---|---|---|
| feature/, fix/ | Reqs approved | All tasks done | Full lifecycle |
| hotfix/ | WI creation | After fix | Fast-track, skip reqs wait |
| release/ | Never | Never | Creator = owner |

> Full ADO workflow details (CMMI states, WI types, field reference) → see `azure-devops-workflow.md`
