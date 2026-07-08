---
name: Solution Designer
description: Creates design docs and tasks from approved requirements.. Triggers: design, architecture, task, data model, api contract, ui prompt, ui design
---

## ⚠️ Step 0 — MCP Pre-flight (BEFORE any designing architecture)

**BLOCK**: Do NOT start designing architecture until you have completed this step.

1. ☐ Verify `context7` is reachable (test query for target framework/library). If unavailable → note "[context7 unavailable]"
2. ☐ Call `codebase-memory` → verify project is indexed. If not → index it first. If unavailable → note "[codebase-memory unavailable]"
3. ☐ Verify `sequential-thinking` is reachable. If unavailable → note "[sequential-thinking unavailable]"
4. ☐ Verify `postgresql` is reachable (test connection). If unavailable → note "[postgresql unavailable — DB schema will be unverified]"

Only after ALL checks pass (or are documented as unavailable) → proceed.

## Role: Developer

## ⚠️ MANDATORY CHECKLIST — verify EVERY step

0. ☐ **Read `docs_language`** → from `.sdd-config.json`. Default: `"es"`. ALL generated content (headers, body, ADO fields) in this language. Templates provide structure — translate headers to `docs_language` when generating.
1. ☐ **Requirements approved?** → Check `## Approval` has `- [x]`. If `- [ ]` → **BLOCK** (inform user that requirements need approval first).
2. ☐ **On feature branch?** → `git rev-parse --abbrev-ref HEAD`. Must be `feature/{prefix}[ID]-*`. If on `dev` → switch to feature branch.

2b. ☐ **Read requirements.md** → Load the approved requirements. Extract: REQ list, entities, constraints, tech assumptions.

2c. ☐ **Propose key architecture decisions** → BEFORE generating anything, present the main decisions for user input. Use `sequential-thinking` for complex tradeoffs (monolith vs microservices, SQL vs NoSQL). Use `context7` to verify library/framework docs, latest stable versions, and compatibility before proposing stack:
   - **Stack/Language**: "For this module I propose [X] because [reason]. OK or prefer something else?"
   - **Database**: "Table [X] with columns [Y]. OK or need something different?"
   - **API pattern**: "REST with [N] endpoints: [list]. Adjust?"
   - **Auth/Security**: "Middleware [X] for [reason]"
   - **Deployment**: Propose based on stack (see `deployment-patterns.md`):
      - Read `deployment` from `.sdd-config.json` — if already exists, propose keeping or changing
      - If not present → map stack → recommended deployment
      - If `project_type: "existing"` → detect current deployment, propose keeping or migrating
      - **Mobile targets**:
        - App Store (iOS) via TestFlight
        - Play Store (Android) via Firebase App Distribution
        - Fastlane for automated signing/deploy
        - Capgo/Appflow for Capacitor live updates
   - **Infrastructure**: AWS services based on `deployment.infra` and reqs. → Use `aws-docs` to verify service capabilities/limits. Use `aws-pricing` to estimate costs before committing.
   
   Present as a compact proposal with **justification per line** + **discarded with reason**:
   ```
   Architecture proposal for [Module]:
   
   📦 Stack:
   - **Node.js + Express** _(consistent with [core] which already uses Express)_
   - **PostgreSQL** _(same RDS instance as [core] — avoids cross-service latency)_
   - _Also valid: **Angular**, **Capacitor**, **Flutter** when targeting mobile/cross-platform_
   
   🚀 Deployment: **fullstack-vercel** | **mobile-capacitor** | **mobile-flutter**
   _(React + Express together → native Vercel, no extra config.
   Splitting into monorepo-split would add unnecessary complexity.
   Mobile: Capacitor → TestFlight/Firebase App Distribution. Flutter → Fastlane.)_
   
   ☁️ AWS Infra:
   - **RDS** → `notifications` table in same instance _(avoids latency)_
   - **SES** → email sending _(cheaper than SendGrid < 62K/month)_
   - **EventBridge** → cron every 1h _(serverless, no 24/7 instance needed)_
   
   ❌ Discarded:
   - SendGrid → more expensive, unnecessary external provider
   - monorepo-split → overhead of 2 pipelines for small project
   
   OK or adjust anything?
   ```

   ⚠️ If user asks counter-questions ("which do you recommend?", "why not X?") → answer with reasoning FIRST, then re-confirm.
   ⚠️ Do NOT generate design.md until user confirms the architecture proposal.
   ⚠️ NEVER propose without justification. Each line has the **what** + the **why**.

3. ☐ **Generate design.md** → ONLY AFTER architecture confirmed. Read `specs/_templates/design-template.md` FIRST, use as scaffold. Read `project_type` from `.sdd-config.json`:
   - `new` → design from scratch (architecture, DB schema, API contracts, UI)
   - `existing` → read existing code FIRST (patterns, conventions, architecture). → Use `codebase-memory` to understand existing code structure, patterns, and dependencies. Design must integrate, NOT replace.
   - `migration` → generate as-is architecture + to-be architecture. Reference `migration-plan.md` if exists.
   MANDATORY sections:
   - `# Design: [Feature Name]` — title
   - `## Traceability` — WI link, branch
   - `## Technology Decisions` — chosen stack with rationale
   - `## Data Model` (§3.1-§3.2) — schemas + DB tables
   - `## API Contracts` (§3.3) — endpoints with request/response
   - `## UI Prompts` (§3.4) — if applicable
   - `## Infrastructure` (§3.5) — diagrams
   - `## Approval` — approval checkboxes
   ⚠️ Do NOT improvise NEW sections. Use template as structure reference — omit sections that don't apply, expand sections that need more depth.

   → If `stitch` available: generate UI components from §3.4 UI Prompts.
3a. ☐ **Post-generation compliance check** → After generating design.md, verify ALL section headers from `specs/_templates/design-template.md` exist in output. If ANY is missing → add it NOW before presenting to user.
   ⚠️ **Content is contextual, not copied.** Template items (checklists, table rows, examples) are ILLUSTRATIVE. Generate content from actual project analysis — codebase scan, architecture review, stakeholder context. If a generated section looks identical to the template placeholder, you're doing it wrong.
   ⚠️ **Cross-document coherence**: After saving, check if related docs exist (product.md ↔ migration-plan.md ↔ requirements.md ↔ design.md). Verify shared data (counts, architecture decisions, tech stack) is consistent. If discrepancies → fix or flag `⚠️ REQUIRES REVIEW`.
3b. ☐ **Infrastructure diagram** → If design.md includes infra (cloud, DB, queues):
    - **In design.md** (per-feature) → Mermaid **always**. Sufficient for 2-5 components per feature.
    - **In docs/architecture/system-design.md** (global, accumulates ALL features):
      - If Python + Graphviz available → generate script based on `references/infra-diagram-template.py`
        - Detect cloud from stacks[]: aws → diagrams.aws.*, azure → diagrams.azure.*
        - Output: `docs/diagrams/infrastructure.py` + execute → `docs/diagrams/infrastructure.png`
        - ⚠️ MUST use GRAPH_ATTR + CLUSTER_* styling constants from the template. Do NOT use plain defaults.
      - If NOT available → Mermaid fallback + inform: "Graphviz not installed — simplified global diagram"
    - `migration` → TWO global diagrams: `infrastructure-legacy.py` + `infrastructure-target.py`
3d. ☐ **Cost estimation** → If deployment includes cloud infra:
    - Use `aws-pricing` MCP to get real pricing for selected services
    - Fill `## Cost Estimation` in `docs/architecture/system-design.md` (see template)
    - Include: service spec, monthly cost, free tier notes, total with/without free tier
    - ⚠️ Do NOT skip — this section is REQUIRED in the system-design template
3c. ☐ **Present supporting sections** → BEFORE requesting design approval, proactively present:
   - **Technical Assumptions**: chosen patterns, frameworks, justification for X over Y, stubs or mocks assumed
   - **Limitations/Constraints**: scalability limits, known tradeoffs, performance ceilings, tech debt accepted
   - **Infrastructure Dependencies**: databases, cloud services, third-party APIs, external systems required
   ⚠️ Do NOT wait for user to ask for these — present them proactively as part of the design review.
4. ☐ **Cross-check requirements** → BEFORE presenting design.md, verify EVERY REQ from requirements.md is covered:
   - Read requirements.md → extract all REQ IDs and their rules
   - For each REQ, verify design.md addresses it (data model, endpoint, validation, state machine, etc.)
   - Include a coverage table at the end of design.md:
     ```
     ## Requirements Coverage
     | REQ | Covered by | Status |
     |-----|-----------|--------|
     | REQ-001 | §Auth — JWT validation | ✅ |
     | REQ-002 | §Data Model — tasks table | ✅ |
     ```
   - If ANY REQ is not covered → fix the design BEFORE showing to user. Do NOT present incomplete designs.
   - Also verify: diagrams referenced in requirements (state machine, ER) are reflected in the design.
5. ☐ **Wait for user approval on design.md** → STOP. Do NOT proceed until approved.

--- DESIGN APPROVED — persist immediately ---

6. ☐ **Mark `- [x]`** in `## Approval` section of design.md → Replace `_____` with approver name from `git config user.name` + current date. Example: `- [x] Developer: Ana García Date: 2026-07-05`
7. ☐ **Persist stacks + theme** → Only AFTER design approval:
   1. Update `.sdd-config.json` → `stacks[]`, `theme`, `detected_by: "solution-designer"`, `last_sync` ISO 8601
   2. Detect IDE from `.sdd-config.json` field `ide` (or detect: `.agents/` exists → kiro, `.agents/` exists → antigravity)
   3. Run `bash sdd-sync.sh --ide {detected_ide}` to sync stack skills + theme to the correct IDE folder:
      - Kiro → `.agents/skills/`
      - Antigravity → `.agents/skills/` + `.agents/rules/`
   4. Show what was activated:
      ```
      ✅ Stacks + theme synced:
        📦 stacks: [...] → synced to IDE steering folder
        🎨 {theme} → synced to IDE steering folder
        📦 .sdd-config.json → stacks: [...], theme: "{theme}"
      ```
   - If sdd-sync.sh not found or fails → inform: "Run `bash sdd-sync.sh --ide {ide}` manually to sync stacks."
8. ☐ **Update ADO (design artifacts)** → Tag `design-approved` on Requirement WI + Story Points ← sum of estimates
   - Design WI Description MUST include: `Repo: {repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/design.md`
   - Create **Data Model** WIs (skip if frontend-only / §3.2 empty):
     - 1 per DB table from §3.2. Title: `[product] [module] MD: {table_name}`
     - Description: HTML table with **inline styles on every `<td>`/`<th>`** (see azure-devops-workflow.md §Tables in descriptions). Columns: name, type, nullable, default, constraints, description. + Indexes table below.
     ⚠️ Follow exact template from azure-devops-workflow.md §Description Format — Data Model.
     - `format: "HTML"` in `wit_create_work_item`
     - Parent link: AFTER creation, call `wit_work_items_link` (see azure-devops-workflow.md §5). Do NOT use `System.Parent` field.
   - Create **Service** WIs (skip if frontend-only / §3.3 empty):
     - 1 per endpoint group from §3.3. Title: `[product] [module] SVC: {METHOD} {route}`
     - Description: auth, request/response schemas (use inline-styled HTML tables for schemas), errors, curl example
     ⚠️ Follow exact template from azure-devops-workflow.md §Description Format — Service.
     - `format: "HTML"` if description contains tables, otherwise `format: "Markdown"`
     - Parent link: AFTER creation, call `wit_work_items_link` (see azure-devops-workflow.md §5). Do NOT use `System.Parent` field.
   - Create **Data Structures** WIs (skip if no schemas in §3.1):
     - 1 per major data schema. Title: `[product] [module] ED: {schema_name}`
     - Description: HTML table with inline styles — fields, types, relationships
     ⚠️ Follow exact template from azure-devops-workflow.md §Description Format — Data Structures.
     - `format: "HTML"` in `wit_create_work_item`
     - Parent link: AFTER creation, call `wit_work_items_link` (see azure-devops-workflow.md §5). Do NOT use `System.Parent` field.
   - **Duplicate check**: Before creating, query ADO by title prefix. If found → update Description. If not → create new.
   - **Custom fields**: For each WI created (MD, SVC, ED) → run field discovery (work-item-setup §2b) before `wit_create_work_item`. Present ALL picklists together as a compact confirmation block with PROPOSED values.
   - **State**: use state discovery (§2b.4) → set to first `InProgress` state. ⚠️ NEVER leave as "New".
9. ☐ **Save deployment to config** → If deployment was proposed and confirmed in step 2c, update `.sdd-config.json`:
    - Set `deployment.pattern`, `deployment.app`, `deployment.infra`, `deployment.services`
    - Update `stacks[]` if new stacks were added
    - ⚠️ Only if deployment was newly defined or changed — skip if already set and unchanged
10. ☐ **Update project docs** → Update these if they exist (skip ONLY if file does not exist):
    - **README.md**: Add/update Tech Stack, Architecture, API sections. Don't remove existing content.
    - **product.md**: Update features list if new feature was added. Update stack if changed.
    - **docs/architecture/system-design.md**: Update diagram and component table if infra changed
    - **docs/architecture/data-model.md**: Append new entities from §3.2 (do NOT delete existing from other features)
    - **docs/architecture/api-contract.md**: Append new endpoints from §3.3 (do NOT delete existing)
    - **docs/architecture/integrations.md**: Append new external services
    - **docs/architecture/security-model.md**: Update if auth/roles/secrets changed
    
    ⚠️ **APPEND rule**: Architecture docs accumulate info from ALL features.
    Only add/update sections for the current feature. NEVER delete sections from other features.
    
    ⚠️ **TEMPLATE REPLACEMENT**: Architecture files created by `sdd-sync.sh` contain FAKE placeholder data
    (USERS, ORDERS, PRODUCTS, JWT, Redis, NestJS, etc.). These are EXAMPLES, not real project data.
    If you find placeholder content → **REPLACE it entirely** with real data from design.md §3.1-§3.3.
    Check for the HTML comment `<!-- ⚠️ TEMPLATE -->` at line 1 — if present, the file has never been updated.
11. ☐ **Commit + push design** → `git add + commit + push`. ⚠️ Push is MANDATORY — commit without push = incomplete.

--- DESIGN PERSISTED — now generate tasks ---

12. ☐ **Generate tasks.md** → Read `specs/_templates/tasks-template.md` FIRST, use as scaffold. Implementable task list from design.
   - ⚠️ **Greenfield check**: Before generating tasks, verify the repo has the basic infrastructure the tasks assume:
     - Does `package.json` (or equivalent: `pyproject.toml`, `pom.xml`, `go.mod`, `pubspec.yaml`, `capacitor.config.ts`) exist?
     - Is the DB configured? (e.g. `docker-compose.yml`, `prisma/schema.prisma`, `.env` with DB connection)
     - Is the framework installed? (e.g. `express`, `fastapi`, etc. in dependencies)
     If ANY of these are missing → add a **Wave 0: Project Setup** with tasks for scaffolding BEFORE the implementation waves.
   - ⚠️ **Environment detection for Wave 0** — PROACTIVE, not reactive. Do NOT propose options one by one waiting for rejection.
     **Step A — Silent scan** (run ALL before asking anything):
     1. `docker --version` → Docker available?
     2. `pg_isready` / `mysql --version` → Local DB running?
     3. Read `.sdd-config.json` → `deployment` field (cloud provider, DB type)?
     4. `aws sts get-caller-identity` / `az account show` → Cloud CLI configured?
     **Step B — Ask ONCE** with only the options that are actually available:
     ```
     🔧 Detected: [Docker ✅/❌] · [Local PG ✅/❌] · [AWS CLI ✅/❌]
     Your project uses: [deployment.db from config]

     For local development, these are your options:
     1. [only list what's available]
     2. ...
     Which do you prefer?
     ```
     ❌ NEVER go through options one-by-one ("Docker?" → no → "Neon?" → no → "SQLite?"). Ask ONCE.
     ❌ NEVER dismiss cloud DB for dev if the project IS cloud-native. If `deployment` = AWS and user has AWS CLI → RDS dev instance is a valid option.
     ❌ NEVER generate docker-compose.yml without confirming Docker is available.
     **Step C — If NOTHING is available**, present installation options ranked by effort:
     ```
     ⚠️ You have no Docker, local DB, or configured cloud CLI.
     Options to get started:
     1. 🌐 Free cloud DB (Neon/Supabase) — 2 min, just signup + copy connection string
     2. 🐳 Install Docker Desktop — ~15 min, recommended for serious dev
     3. 🐘 Install native PostgreSQL — ~10 min, permanent background process
     4. ⚠️ Temporary SQLite — 0 min setup, BUT with limitations (see below)
     Which do you prefer?
     ```
     **SQLite as last resort** — ONLY if the user explicitly chooses it. ALWAYS warn:
     - ⚠️ NOT "transparent". Differences: no ENUM, no complex CHECK constraints, no arrays, different date types, no JSONB.
     - ⚠️ Migrations generated for SQLite will NOT work in PostgreSQL production. Will need to be regenerated.
     - ⚠️ Mark in tasks.md: "DB: SQLite (temporary) — migrate to PostgreSQL before CERT".
   - ⚠️ **IaC + Pipeline question** (only if greenfield): Ask the user:
     - "Shall I set up infrastructure as code (CDK/Terraform) from now, or leave it for later?"
     - "Shall I set up the CI/CD pipeline from now?"
     If YES → include as Task 0.3 / 0.4 in Wave 0. If NO → move to last wave or omit.
   - `migration` → include migration-specific tasks: data migration, feature flags, rollback steps
   - tasks.md MUST include the same traceability header as design.md
   - Each task MUST use this format:
     ```markdown
     ### Task N — [Title]
     - **REQ**: REQ-001, REQ-002
     - **Estimate**: [hours]
     - **ADO**: Child Task of {prefix}{ID}
     ```
   MANDATORY sections:
   - `# Tasks: [Feature Name]`
   - `## Metadata` — estimation rules, total
   - `## Dependency Graph` — mermaid diagram
   - `## Wave N: [Title]` — tasks grouped by wave
   - Per task: REQ link, estimate, description, dependencies, acceptance criteria
   - `## Implementation Order Summary` — table
   - `## Completion Checklist`
   ⚠️ Do NOT improvise NEW sections. Use template as structure reference — omit sections that don't apply, expand as needed.
12a. ☐ **Post-generation compliance check** → After generating tasks.md, verify ALL section headers from `specs/_templates/tasks-template.md` exist in output. If ANY is missing → add it NOW before presenting to user.
   ⚠️ **Content is contextual, not copied.** Template items (checklists, table rows, examples) are ILLUSTRATIVE. Generate content from actual project analysis — codebase scan, architecture review, stakeholder context. If a generated section looks identical to the template placeholder, you're doing it wrong.
   ⚠️ **Cross-document coherence**: After saving, check if related docs exist (product.md ↔ migration-plan.md ↔ requirements.md ↔ design.md). Verify shared data (counts, architecture decisions, tech stack) is consistent. If discrepancies → fix or flag `⚠️ REQUIRES REVIEW`.
   ⚠️ **Estimation**: Apply multipliers from `estimation-strategy.md` §Scenario B for AI-assisted tasks. Keep estimates unchanged for business-logic-heavy tasks.
13. ☐ **Show tasks.md summary table** → NOT the full document. This is a SEPARATE approval from design.md.
14. ☐ **Wait for approval on tasks.md** → STOP. Do NOT update ADO or commit until tasks are approved.

--- TASKS APPROVED — persist immediately ---

15. ☐ **Update ADO (task artifacts)** → ⚠️ Duplicate check: Before creating, query ADO by title prefix with WIQL CONTAINS (case-insensitive). If found → skip creation.
   Create child Task WIs from tasks.md
   - Each child Task WI Description MUST include: `Repo: {repo_url}/blob/{branch}/specs/{prefix}{ID}-{name}/tasks.md#task-N`
   ⚠️ Follow exact template from azure-devops-workflow.md §Description Format — Task.
   - **Custom fields**: For each Task WI → run field discovery (work-item-setup §2b) before `wit_create_work_item`.
   - **State**: use state discovery (§2b.4) → set to first `InProgress` state. ⚠️ NEVER leave as "New".
16. ☐ **Commit + push tasks** → `git add + commit + push`. ⚠️ Push is MANDATORY.
17. ☐ **Save to memory** → Use `server-memory` to persist design decisions, stack choices, and deployment patterns.
18. ☐ **COMPLETION CHECKPOINT** → Before showing 📍, verify ALL of the following are done:
    - [ ] MD/SVC/ED WIs created in ADO (step 8) — WI IDs exist
    - [ ] Design committed + pushed (step 11)
    - [ ] Task WIs created in ADO (step 15) — WI IDs exist
    - [ ] Tasks committed + pushed (step 16)
    - [ ] Deployment saved to config (step 9) — if applicable
    - [ ] Memory saved (step 17) — design decisions persisted
    If ANY is missing → complete it NOW before proceeding.
19. ☐ Show 📍 position. STOP. Do NOT suggest or execute role changes.

---

> Follow standard interaction pattern. See workflow-router.md.

## Workflow

0. **Read spec_prefix** from `.sdd-config.json` → use for folder naming: `specs/{spec_prefix}[ID]-[name]/`
   - Empty → `specs/[name]/` · Not configured → infer from context, else include in proposal

0b. **Use templates** — If `specs/_templates/design.md` exists, use as base structure. If not found, use `specs/_templates/design-template.md`.

0c. **Traceability header** → design.md MUST start with:
    ```markdown
    # Design — [Feature Name]

    ## Traceability
    - **Work Item**: [{prefix}{ID}]({tracker_url})        ← Requirement WI (SAME as requirements.md)
    - **Parent**: [{parent_prefix}{parent_ID}]({parent_tracker_url})  ← Feature/Epic (PARENT)
    - **Branch**: [type]/{prefix}[ID]-[name]
    - **Requirements**: [requirements.md](./requirements.md)
    - **Test Plan**: [test-plan.md](./test-plan.md)
    ```
    ⚠️ **Work Item** = the SAME Requirement WI as requirements.md. design.md documents THE SAME requirement, it does not create a new WI.
    ⚠️ **Parent** = Feature/Epic. NEVER put the Requirement here.
    Tracker URL format: Azure DevOps → `https://dev.azure.com/{org}/{project}/_workitems/edit/{ID}`. Others → use URL from `tracker-mapping.md`.

1. Read approved requirements.md

### Branch Creation
1. Read `type` and `branch name` from requirements spec
2. Verify branch doesn't exist: `git branch --list <branch>`
3. Create: `git checkout -b <type>/<name>`
4. Inform user. If spec has no type/branch → infer or include in proposal.

### Tech Selection (step 2)

2. Tech selection: stack, DB engine, cloud/deploy, theme

2.5. **Propose stacks in design.md** — Document proposed techs in design. Do NOT write to `.sdd-config.json` yet. Stacks are persisted only after design approval (checklist step 6).

2.6. **Stack activation deferred** — Stack sync (via `sdd-sync.sh`) happens in step 7, after design approval.

2.7. **Design System Theme Selection** — **Skip if project is backend-only / API-only (no frontend).**

| Project Type | Recommended Theme |
|---|---|
| Payments/Banking/Finance | `fintech` |
| Health/Clinical/Medical | `healthcare` |
| ERP/CRM/Internal tools | `corporate` |
| Insurance/Policies/Claims | `insurtech` |

Available: `fintech`|`healthcare`|`corporate`|`insurtech`|`custom`. Propose in design.md only — do NOT write to config yet. Persisted in step 6 (after approval). `custom` → custom theme file needed.

2b. **Stack selection** (only if `stacks[]` empty): Read `tech.md`, recommend from approved list as table (Layer|Recommended|Alternative|Justification). Flag unapproved libs ⚠️. Approval → update config → `sdd-sync.sh`.

## ⚠️ REQUIRE: Read references before generating

| Generating... | You MUST read FIRST |
|---|---|
| API contracts | `docs/architecture/_templates/api-contract-template.md` |
| UI design prompts | `references/ui-prompt-template.md` + active theme from `core/themes/THEME_[NAME].md` + `design-system-base.md` |
| Infrastructure diagram (Python) | `references/infra-diagram-template.py` |

NEVER generate API contracts or UI prompts without reading the corresponding references.

### Generate design.md (step 3)

| Section | Contents |
|---|---|
| 3.1 Architecture | Mermaid: component, sequence, deps. Frontend: tree, routing, state. **Skip frontend tree for backend-only. Skip backend deps for frontend-only.** |
| 3.2 DB Schema | Tables, columns, types, indexes, FKs. **Skip for frontend-only (no DB).** |
| 3.3 API Contracts | Read ref template first. Per endpoint: method, route, auth, TS interfaces, errors, curl. Group by resource. Field→DB mapping. **Frontend-only: document consumed APIs only (base URL, auth, endpoints used), not defined endpoints.** |
| 3.4 UI Prompts | Read theme + ref template + design-system-base. Per page: route, auth, visual prompt (hex/px/fonts/shadows). Copy-pasteable to Stitch/v0/Bolt. **Skip for backend-only.** |
| 3.5 Infra | Mermaid (always) + Python `diagrams` (if available): read ref template → `docs/diagrams/infrastructure.py` → PNG. Detect provider from stacks. Migration → 2 scripts. Existing → READ+ADD. Deps: `pip install diagrams` + Graphviz; offer install or Mermaid-only. |

#### 3a. Incremental review mode — design.md

After proposing the design structure (sections list), ask:

> **Shall we detail them one by one or all at once?**

- **Incremental** (recommended for ≥3 sections) → detail each section one at a time, wait for OK before next:
  - §3.1 Data schemas
  - §3.2 DB tables (one table at a time)
  - §3.3 API endpoints (one endpoint group at a time)
  - §3.4 UI prompts
  - §3.5 Infra
- **All at once** → generate the full design.md in a single pass

⚠️ This ask happens BEFORE generating section content, not after. Propose the structure first (section titles + brief summary of what each covers), then ask review mode, then generate.

#### 3b. Present supporting sections — design.md

AFTER all design sections are generated and BEFORE requesting user approval, proactively present:

- **Technical Assumptions**: chosen patterns and frameworks with justification (why X over Y), assumed stubs or mocks, constraints inherited from requirements
- **Limitations/Constraints**: scalability limits of the proposed design, known tradeoffs accepted, performance ceilings, tech debt consciously taken on
- **Infrastructure Dependencies**: databases, cloud services, message queues, third-party APIs, external systems the design depends on

⚠️ Do NOT wait for user to ask for these — present them proactively. Include as a dedicated section in design.md (e.g., `## Supporting Considerations`) or present in chat alongside the design summary before requesting approval.

4. **Wait for user approval on design.md** — Present design.md summary for approval. STOP until approved.

5. **Generate tasks.md** — decomposition into tasks, waves, dependencies, estimates (only after design.md approved)
   ⚠️ **Agentic tooling**: With AI-assisted devs, do NOT split tasks by front/back layer for the same feature (e.g., avoid separate "Create React component" + "Create BFF endpoint" tasks). Instead, create one full-stack task per feature slice — the dev generates both in the same session.

#### 5a. Incremental review mode — tasks.md

After proposing the task list summary (task titles, estimates, REQ mapping), ask:

> **Shall we detail them one by one or all at once?**

- **Incremental** (recommended for ≥3 tasks) → detail each task one at a time, wait for OK before next
- **All at once** → generate the full tasks.md in a single pass

⚠️ This ask happens BEFORE generating task details, not after. Present the summary table first, then ask review mode, then generate full content.

5. **Repo type recommendation** (if `repo_type` not set):

| Architecture | Recommended |
|---|---|
| 1 service/app | `single` |
| 2+ services, same team, shared code | `monorepo` |
| 2+ services, independent teams/deploys | `multirepo` |

Reference `structure.md`. Write approved type to config. If already set → skip.

6. **Global architecture updates** — Identify needed updates:

| Condition | Update |
|---|---|
| New tables/columns | `docs/architecture/data-model.md` |
| New endpoints | `docs/architecture/api-contract.md` |
| New external service | `docs/architecture/integrations.md` |
| Auth/security changed | `docs/architecture/security-model.md` |
| Infra changed | `docs/architecture/system-design.md` |

If `docs/architecture/` missing → create from `docs/architecture/_templates/*-template.md`. Skip if no changes.

7. **Present tasks.md + architecture updates** for approval (design.md was already approved separately)
8. **Save** only after approval

## Spec Organization
- Path: `specs/{prefix}[ID]-[name]/design.md`
- Include traceability header: `## Traceability` → Requirement path + REQ IDs covered

## Footer (all spec files)
---
> 📍 [{prefix}{ID}]({tracker_url}) · 🌿 `feature/{prefix}{ID}-name` · Generated by SDD Standard

## MCP

| Tool | Purpose |
|---|---|
| `context7` | Verify lib/framework docs and compat |
| `stitch` | Generate UI components from design |
| `aws-docs` | Verify AWS service capabilities |
| `aws-pricing` | Estimate architecture costs |
| `server-memory` | Read prior decisions, persist new ones |
| `codebase-memory` | Understand existing code patterns |
| `sequential-thinking` | Complex architecture tradeoffs (monolith vs micro, SQL vs NoSQL, deployment patterns) |

## Related Skills
- `tech.md` — approved stack/constraints
- `security.md` — security requirements
- `design-system-base.md` — UI design tokens
- `estimation-strategy.md` — estimation multipliers and architecture variant impact

### ⚠️ MCP Self-Verification (verify BEFORE presenting design.md and tasks.md to user)

- ☐ Called `context7` to verify library/framework docs, latest stable versions, and compatibility (step 2c)
- ☐ Used `sequential-thinking` for complex architecture tradeoffs (monolith vs micro, SQL vs NoSQL) (step 2c)
- ☐ Called `codebase-memory` to understand existing code structure and patterns (step 3, if `existing` project)
- ☐ Called `aws-pricing` to estimate infrastructure costs and filled `## Cost Estimation` in system-design.md (step 3d)
- ☐ Updated `azure-devops` with MD/SVC/ED and Task WIs after approvals (steps 8, 15)
- ☐ Saved design decisions and stack choices to `server-memory` (step 17)
- ☐ If any MCP unavailable → documented as `[NOT VERIFIED]` in output

## Output
- **Files**: `specs/{prefix}[ID]-[name]/design.md` + `tasks.md`. Update `docs/architecture/*.md` if needed.
- **Chat**: Summary table only (components, tech, REQs). List files. Offer drill-down.
- **Drill-down**: Only requested component. Adjust → update → loop until "done".
- **Tracker**: "In Progress" after design, "Ready for QA" after all tasks.
- **README.md**: Add/update Tech Stack, Architecture, API sections. Don't remove existing. Skip if no README.

## When Modifying an Existing Design
1. **Detect** if `test-plan.md` exists in same folder
2. **If exists** → add to `## Status`: `⚠️ REQUIRES REVIEW — DESIGN-[NNN] was modified on [date]` + change description
3. **Inform user**: "Test Plan marked as requires review"


## Rules
- REQUIRES approved requirements.md
- Does NOT modify requirements.md
- Does NOT create test-plan.md
- MUST recommend technologies from `tech.md` approved stacks first
- If a technology outside the approved list is needed, justify and flag with ⚠️
- After stack selection, update `.sdd-config.json` → `stacks[]`
