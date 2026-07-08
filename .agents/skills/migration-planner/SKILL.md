---
name: Migration Planner
description: Plans and guides technology migrations in a safe and structured way. Supports migrations of: frameworks, databases, infrastructure, and architecture.. Triggers: migration, migrate, convert, upgrade, modernize, legacy, refactor, strangler, replatform
---

## ⚠️ Step 0 — MCP Pre-flight (BEFORE any migration planning)

**BLOCK**: Do NOT start planning until you have completed this step.

1. ☐ Call `codebase-memory` → verify project is indexed. If not → index it first
2. ☐ Verify `context7` is reachable (test query for target framework). If unavailable → note "[context7 unavailable]"
3. ☐ Verify `sequential-thinking` is reachable. If unavailable → note "[sequential-thinking unavailable]"
4. ☐ Read `.sdd-config.json` for `AZURE_DEVOPS_PROJECT`, `docs_language`, `migration.from/to`

Only after ALL checks pass (or are documented as unavailable) → proceed.

## ⚠️ MANDATORY CHECKLIST — verify EVERY step

0. ☐ **Read `docs_language`** → from `.sdd-config.json`. ALL generated content (migration-plan.md, ADO fields) MUST be in this language. Default: `"es"`. Technical terms stay English.
1. ☐ **Scanner completed?** → project-scanner must have run first. Check .sdd-config.json: project_type = migration. Check product.md exists AND is not a placeholder (if it contains "⚠️ This is a placeholder" or has < 50 lines → **BLOCK**: "product.md is empty/placeholder. Run project-scanner first to generate it.").
2. ☐ **Read migration context** → .sdd-config.json: migration.from, migration.to, migration.strategy, migration.scope, migration.phase. If `scope` is set (e.g., `frontend-only`), restrict ALL analysis and planning to that scope — do NOT propose changes outside it.
3. ☐ **Document as-is** → Current architecture, stacks, dependencies, pain points. → Use `codebase-memory` to analyze legacy code structure (modules, patterns, dead code, dependency graph). Use `postgresql` to query existing DB schema if SQL-based.
4. ☐ **Document to-be** → Target architecture, new stacks, expected benefits. → Use `context7` to verify target tech docs (breaking changes, migration guides, API compatibility). → If `aws-docs` available: verify AWS service capabilities if cloud target. → If `aws-iac` available: lint and validate IaC templates (CDK/CloudFormation) for the target architecture.
5. ☐ **Classify migration** → version upgrade, tech change, architecture change, or combination. → Use `sequential-thinking` for complex multi-variable strategy decisions (Strangler Fig vs Big Bang vs Parallel Run).
6. ☐ **Generate migration-plan.md** → Read `specs/_templates/migration-plan-template.md` FIRST for **structure reference**, then adapt to the specific project. Apply **Incremental Review** (see section below) before full generation. → Use `aws-pricing` to estimate cost comparison (current vs target infra) if infrastructure migration.
   Template sections — include, adapt, or omit based on project context:
   - `# Migration Plan: [Name]` — **always**
   - `## Traceability` — **always** (WI, Parent, Branch, Requirements link)
   - `## Executive Summary` — **always**
   - `## Scope Summary` — **always** (in/out scope table)
   - `## Codebase Inventory` — **always** (data-driven from scanner, never estimated)
   - `## Current System` + `## Target System` — **always**
   - `## Feature Parity Matrix` — **always**
   - `## Data Migration` — **if DB involved**, otherwise omit with one-line justification
   - `## Architecture Variants` — **if multiple options exist**, otherwise state chosen variant directly
   - `## Migration Strategy` — **always** (with justification)
   - `## Rollback Plan` — **always**
   - `## Cut-over Checklist` — **always** (pre/during/post)
   - `## Risks` — **always** (numbered table with impact/probability/mitigation)
   - `## Timeline` — **always** (phases with duration and responsible)
   - `## Estimation Matrix` — **always** (manual vs AI-assisted, 3 scenarios each)
   - `## Prerequisites` — **always**
   - `## Pending Decisions` — **if decisions remain**, otherwise omit
   - `## Version Upgrade Steps` — **only if version upgrade**
   - `## Deployment Migration` — **only if deploy platform changes**
   - `## Approval` — **always**
   ⚠️ Do NOT improvise NEW sections not in the template. Do NOT rename headers.
   ⚠️ DO omit sections that don't apply — mark with `> N/A: [one-line reason]` or remove entirely.
   ⚠️ DO expand sections that need more depth — add subsections, tables, diagrams as needed.
6a. ☐ **Post-generation compliance check** → After generating, verify all **applicable** headers from template exist in output. Omitted sections should have a justification or be absent entirely (not left as empty placeholders).
   ⚠️ **Content is contextual, not copied.** Template items (checklists, table rows, examples) are ILLUSTRATIVE. Generate content from actual project analysis — codebase scan, architecture review, stakeholder context. If a generated section looks identical to the template placeholder, you're doing it wrong.
   ⚠️ **Cross-document coherence**: After saving, check if related docs exist (product.md ↔ migration-plan.md ↔ requirements.md ↔ design.md). Verify shared data (counts, architecture decisions, tech stack) is consistent. If discrepancies → fix or flag `⚠️ REQUIRES REVIEW`.

6b. ☐ **Present supporting sections** → BEFORE requesting approval on migration-plan.md, proactively present:
   - **Assumptions**: data integrity guarantees, downtime tolerance windows, rollback capability scope, environment parity
   - **Limitations/Risks**: what could go wrong, what's explicitly not covered, partial migration scenarios, data loss risk areas
   - **Dependencies**: infrastructure readiness (target env provisioned), team availability, vendor support contracts, third-party API compatibility
   ⚠️ Do NOT wait for user to ask for these — present them proactively as part of the migration plan review.
6c. ☐ **Propose deployment target** → After defining target stack:
   - Propose deployment pattern based on target stack (see `deployment-patterns.md`):
     "For the target stack [X], I recommend **[pattern]** (Vercel front, AWS back) because [reason]"
   - ⚠️ Wait for confirmation before generating migration-plan.md
   - Save in `.sdd-config.json` → `deployment`
7. ☐ **Validate estimation with MCPs** → BEFORE presenting to user:
   - `sequential-thinking` → validate phase ordering (dependency analysis), risk prioritization, effort distribution across phases. Feed: module count, complexity breakdown, team size assumption.
   - `context7` → verify target stack versions are current, check for known migration pitfalls or breaking changes in proposed target.
   - `codebase-memory` → validate module independence (can phases run in parallel? are there hidden cross-module dependencies?).
   ⚠️ If any MCP is unavailable → proceed but inform user: "Estimation not validated with [MCP] — review recommended."
7b. ☐ **Apply agentic tooling multiplier** → See `estimation-strategy.md` §Scenario B for multipliers. Ask user: "Will the team use agentic IDEs with SDD standard?"
   - If **yes** → apply multipliers from `estimation-strategy.md`. Present BOTH scenarios.
   - If **no** → keep manual estimates. Still present BOTH scenarios for comparison.
   - Team composition: see `estimation-strategy.md` §Team Composition.
   - What does NOT change with AI: see `estimation-strategy.md` §What AI does NOT accelerate.
8. ☐ **Show proposal** → Summary table of phases with effort estimates. MUST include:
   - Three scenarios: optimistic / realistic / pessimistic
   - Two modes: manual development vs AI-assisted (with SDD)
   - Total: 6 cells minimum in the estimation matrix
9. ☐ **Wait for approval** → User confirms scope and approach
10. ☐ **Update .sdd-config.json** → migration.from, migration.to, migration.strategy, migration.scope (what's being migrated), migration.phase (current phase number)
11. ☐ **Commit + push** → Ask user, then `git add + commit + push`. ⚠️ Push is MANDATORY — commit without push = incomplete.
12. ☐ **Save to memory** → Use `server-memory` to persist migration status and decisions. → If `azure-devops` available: update migration work item with plan status and phase summary.
13. ☐ **COMPLETION CHECKPOINT** → Before showing 📍, verify ALL of the following are done:
    - [ ] `git push` completed (step 11) — not just commit
    - [ ] Memory saved (step 12) — migration status persisted
    If ANY is missing → complete it NOW before proceeding.
14. ☐ Show 📍 position. STOP. Do NOT suggest or execute role changes.

---

> Follow standard interaction pattern. See workflow-router.md.

# Migration Planner

## Role: Developer

## ⚠️ REQUIRE: Read references for details

| Planning... | You MUST read FIRST |
|-------------|---------------------|
| Any type of migration | `references/migration-types.md` |
| Escalated version upgrade | `references/escalated-strategy.md` |
| Templates, examples, checklists | `references/templates.md` |

NEVER plan a migration without consulting the documented types and strategies.

## Migration Types (Summary)
See `references/migration-types.md` for detailed tables with examples.

| Category | Types | Complexity |
|----------|-------|:----------:|
| Technology change | Framework, Language, DB, ORM | 🟡-🔴 |
| Version upgrade | Framework, Runtime, Dependency | 🟢-🟡 |
| Infrastructure | Cloud, Serverless, Architecture, Containers, CI/CD | 🟢-🔴 |
| API and communication | Protocol, Communication | 🟡 |
| Frontend | CSS, State mgmt, Build, Testing | 🟢 |
| Security and auth | Authentication | 🟡 |
| Organization | Repository, Storage | 🟢-🟡 |

## Automatic Type Detection

| If the Analyst says... | If the Developer says... | Inferred type | Suggested strategy |
|------------------------|--------------------------|---------------|-------------------|
| "the framework is no longer supported" | "upgrade from Angular 14 to 20" | Version upgrade | Escalated |
| "the framework is obsolete" | "switch from Angular to React" | Framework | Strangler Fig |
| "we need to reduce infra costs" | "move from on-premise to AWS" | Cloud | Parallel Run |
| "the DB license is too expensive" | "migrate from Oracle to PostgreSQL" | Database | Dual-write |
| "the system doesn't scale" | "convert to microservices" | Architecture | Strangler Fig |
| "the API is slow and hard to maintain" | "move from REST to GraphQL" | API | Parallel Run |

User may express in technical OR business language. Infer type regardless. Include in proposal; if ambiguous, present options.

## Escalated Strategy (Version Upgrades)

For upgrades with accumulated breaking changes, go step by step. See `references/escalated-strategy.md`.

| Rule | Detail |
|------|--------|
| Max jump | 2 major versions |
| Per jump | Own `migration-plan-v[N].md` |
| Sequencing | Previous jump in production before starting next |
| Validation | Complete regression suite after each jump |

## Migration Flow

See `references/migration-flow.md` for diagram.

```
Trigger → Dev scan (product.md) → Dev migration-plan.md → Analyst requirements PER PHASE → Dev design + tasks PER PHASE → QA test plan → Implementation by module → Cut-over → Release
```

> ⚠️ In migrations, migration-plan comes BEFORE requirements. The plan defines scope/phases. Requirements define acceptance criteria PER phase.

## Incremental Review Mode

When proposing a list of items during **initial plan generation**, offer the user a choice before generating full details:

> **Ask**: "Shall we detail them one by one or all at once?"

| Mode | When recommended | Behavior |
|------|:----------------:|----------|
| **One by one** (incremental) | ≥ 3 items | Detail each item one at a time. Wait for user OK before proceeding to the next. |
| **All at once** (batch) | < 3 items or user preference | Generate the full document in one pass. |

**Applies to** (during initial plan generation only):

| Artifact | Trigger to ask |
|----------|---------------|
| Migration phases (Phase 4) | After proposing the phase list summary |
| Feature parity matrix (Phase 2) | If the matrix has ≥ 3 rows, offer to review by module/area |
| Schema mappings (Phase 3) | Offer to review table-by-table |

> ⚠️ This applies ONLY to initial plan generation. The post-approval module iteration (see "Post Migration Plan — Module Iteration") already has its own incremental approval gates — do NOT duplicate.

## Role Separation

| Role | Responsibility |
|------|--------------:|
| Developer | Setup + scan → migration plan (scope, phases, effort) → design + implementation per phase |
| Analyst | After migration-plan approved: requirements PER PHASE (business constraints, acceptance criteria) |
| QA | After design per phase: test plan (standard + migration-specific), execution |

### Migration Kickoff (mandatory)

Before any documentation, Developer and Analyst align:

| Developer shares | Analyst shares |
|-----------------|---------------|
| Scan results (stack, deps, EOL dates) | Business motivation (cost, compliance, risk) |
| Technical complexity estimate | Available budget and timeline |
| Risks and unknowns | Critical vs nice-to-have features |
| Candidate target technologies | Acceptable downtime |

Output: shared understanding → Developer writes migration plan → Analyst writes requirements per phase.

> ⚠️ Developer creates migration-plan FIRST (needs codebase scan to define scope). Analyst then writes requirements PER PHASE using the migration plan as input. Requirements without migration scope = guessing.

### Target Stack Decision

Ask first: **"Do you already have a defined target stack or should we define it based on the analysis?"**

- **Pre-decided** (team/CTO already chose): Register the choice → validate against scan findings (compatibility, community support, migration tooling availability, team skills). If scan reveals concerns → present them as risks, do NOT block. The business decision takes priority but risks must be documented.
- **Not decided**: Based on scan + Analyst constraints → analyze problems → propose 2-3 options ranked by fit → justify with technical + business rationale → user decides.

### Update `.sdd-config.json`

After target stack approved: `project_type: "migration"`, `stacks: [target]`, `migration.from/to: [stacks+versions]`, `migration.strategy: "escalated"|"direct"`, `detected_by: "migration-planner"`.

## Workflow

### Gate Check (before anything)
1. Check if `product.md` exists and `.sdd-config.json` has `project_type: "migration"`
2. If product.md NOT found → STOP. Run project-scanner first.
3. If found → READ product.md, extract legacy/target stack info, proceed to Phase 1

> Note: requirements.md is NOT required before migration-plan. Requirements come AFTER, per phase.

### Phase 1: Current System Analysis
Run scanner → document stack (languages, frameworks, DB, infra, deps) → measure baselines (LOC, endpoints, tables, test coverage) → identify risks (unsupported deps, untested code, critical integrations).

### Phase 2: Feature Parity Matrix
Generate current-vs-target feature table. See `references/templates.md` for template.

**Incremental Review**: If the matrix has ≥ 3 rows, present a summary list of modules/areas first, then ask: "Shall we detail them one by one or all at once?" If incremental, detail each module's feature mapping one at a time, waiting for OK before the next.

### Phase 3: Data Migration Plan
If DB involved: schema mapping (field-by-field) → transformation rules → volume estimate → strategy (One-shot | Dual-write | CDC) → post-migration validation (row counts, checksums, queries). See `references/templates.md` for schema mapping example.

**Incremental Review**: Present the list of tables/entities to map first, then ask: "Shall we detail them one by one or all at once?" If incremental, detail each table's schema mapping one at a time, waiting for OK before the next.

### Phase 4: Migration Strategy

**Incremental Review**: After analysis, present a summary list of proposed migration phases with one-line descriptions and effort estimates. Then ask: "Shall we detail them one by one or all at once?" If incremental, detail each phase one at a time (scope, risks, rollback, success criteria), waiting for OK before the next.

| Strategy | When to use | Risk | Downtime |
|----------|-------------|:----:|:--------:|
| **Big Bang** | Small systems, <10K users | 🔴 High | Yes |
| **Strangler Fig** | Large, critical systems | 🟢 Low | No |
| **Parallel Run** | When validation needed first | 🟡 Medium | No |
| **Blue-Green** | Infrastructure, instant rollback | 🟢 Low | Minimal |

Recommend based on: system size, criticality, downtime tolerance.

### Phase 5: Rollback Plan
Define: point of no return → code rollback (feature flags, git revert) → data rollback (snapshots, backups) → infra rollback (DNS, LB) → max rollback time (SLA).

### Phase 6: Cut-over Checklist
See `references/templates.md` for full checklist template (pre/during/post-migration).

### Present Supporting Sections

AFTER all phases are generated and BEFORE requesting user approval on migration-plan.md, proactively present:

- **Assumptions**: data integrity guarantees assumed, downtime tolerance windows, rollback capability scope, environment parity between source and target
- **Limitations/Risks**: what could go wrong during each phase, what's explicitly not covered by this plan, partial migration scenarios, data loss risk areas
- **Dependencies**: infrastructure readiness (target environment provisioned and configured), team availability for each phase, vendor support contracts, third-party API compatibility with target stack

⚠️ Do NOT wait for user to ask for these — present them proactively. Include as a dedicated section in migration-plan.md (e.g., `## Supporting Considerations`) or present in chat alongside the phase summary before requesting approval.

### ⚠️ MCP Self-Verification (verify BEFORE presenting migration-plan.md to user)

- ☐ Called `context7` to verify target framework docs, breaking changes, and migration guides (step 4)
- ☐ Called `codebase-memory` to analyze legacy code structure, dependency graph, and dead code (step 3)
- ☐ Queried `postgresql` for existing DB schema if SQL-based migration (step 3)
- ☐ Used `sequential-thinking` for strategy decision (Strangler Fig vs Big Bang vs Parallel Run) (step 5)
- ☐ Validated estimation with `sequential-thinking` + `context7` + `codebase-memory` (step 7)
- ☐ Saved migration status and decisions to `server-memory` (step 12)
- ☐ If any MCP unavailable → documented as `[NOT VERIFIED]` in output

## Output
`specs/{prefix}[ID]-[name]/migration-plan.md`

## Post Migration Plan — Module Iteration

After `migration-plan.md` approved, implement module by module. See `references/templates.md` for iteration flow, file naming, and server-memory entity.

### Progress recovery (if server-memory is empty)

Before starting iteration, check server-memory for progress entity. If missing, **reconstruct from Git**:

| File exists | Tasks status | Module state |
|---|---|---|
| `design-{module}.md` + all tasks `[x]` | Done | ✅ Completed |
| `design-{module}.md` + tasks incomplete | In progress | 🔄 In progress |
| No `design-{module}.md` | — | ⬜ Pending |

Read `migration-plan.md` for module order. Rebuild progress entity and save to server-memory.

### Iteration cycle (per module)
1. **Propose next module** from migration-plan.md phase order
2. **Requirements** → delegate to requirements-analyst (scope, acceptance criteria, constraints for this module)
   - ☐ **Wait for user approval on requirements** → STOP. Do NOT proceed until approved.
   ⚠️ **NEVER skip this step.** Design depends on approved requirements. The SDD lifecycle is: reqs → design → tasks → impl → test.
3. **Design** → delegate to solution-designer (old→new changes, proxy rules, data migration, rollback for this module)
   - ☐ **Wait for user approval on design** → STOP. Do NOT proceed until approved.
4. **Tasks** → solution-designer generates module tasks
   - ☐ **Wait for user approval on tasks** → STOP. Do NOT proceed until approved.
5. **Implement** → developer implements
   - ☐ **Wait for user approval on implementation** → STOP. Do NOT proceed until approved.
6. **Test** → module tests + regression
   - ☐ **Wait for user approval on test results** → STOP. Do NOT proceed until approved.
7. **Mark complete** → update server-memory module status
8. **Propose next** → STOP. Wait for explicit user approval before starting next module.

### Cut-over
After ALL modules complete: full regression → execute cut-over checklist → update ADO work item → update server-memory: migration complete.

## Specs Organization
Create migration plan in `specs/{prefix}[ID]-[name]/migration-plan.md`. See `references/templates.md` for traceability block.


## Constraints
- REQUIRES: Developer setup + scan FIRST (product.md must exist)
- Migration plan is created BEFORE requirements (Developer defines scope, then Analyst writes requirements per phase)
- Requirements are written PER PHASE, not for the entire migration at once
- The work item in Azure DevOps can be created at any point (trigger does not require a work item)
- Present complete migration plan in one proposal. Developer approves or adjusts once before execution.
- NEVER execute data migration without a verified backup
- NEVER migrate directly to production (always DEV → CERT → PROD)
- ALWAYS keep the old system available during the validation period
- ALWAYS generate a rollback plan before executing

## MCP
- `codebase-memory` — analyze legacy code structure, modules, patterns, dead code before migration planning
- `context7` — verify target technology documentation, breaking changes, migration guides, API compatibility
- `sequential-thinking` — complex migration strategy decisions (Strangler Fig vs Big Bang vs Parallel Run tradeoffs)
- `aws-pricing` — cost comparison between current and target infrastructure
- `postgresql` — query existing DB schema for schema mapping and data migration planning
- `aws` — AWS services
- `aws-iac` — lint, compliance, and IaC template management (covers CDK and CloudFormation)
- `aws-docs` — verify AWS service capabilities, limits, and migration paths
- `azure-devops` — Azure DevOps
- `server-memory` — persist module migration status and migration decisions

## Related Skills
- `tech.md` — approved target stack for migration
- `environment-strategy.md` — migration rollout per environment
- `testing-strategy.md` — validation strategy post-migration
- `estimation-strategy.md` — AI multipliers, architecture variant impact, migration estimation formula
