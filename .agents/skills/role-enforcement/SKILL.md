---
name: Role Enforcement
description: role validation, enforcement, blocked guidance, and handoff detection
---

## Validate branch vs role

If the current branch does not correspond to the role, warn:

| Role | Allowed branches | If on another |
|------|-----------------|---------------|
| Analyst | `dev` | ⚠️ "As an Analyst, you should be on the `dev` branch. Do you want to switch?" |
| Developer | `dev`, `feature/*`, `fix/*`, `hotfix/*` | ⚠️ "This branch does not correspond to your role. Continue?" |
| QA | `dev`, `cert` | ⚠️ "As QA, you should be on `dev` or `cert`. Do you want to switch?" |

If there is a branching override in `.sdd-config.json`, use those branch names instead of the defaults.

### Detect handoff (change of responsible person)

Only execute handoff detection if:
- The user selected a specific work item
- Or if it is the first time they work in a specs/ folder

Do not execute if:
- The user is already working on the same item (same session)
- The user is performing a task that does not involve specs/ (e.g.: "format this file")

When the user selects a work item to work on:

1. Check `git log` of the `specs/{prefix}[ID]-[name]/` folder — are the previous commits from another author?
2. If the previous author is different from the current `git config user.email` → **handoff detected**
3. Show context summary:

```
🔄 Handoff detected — this item was worked on by [previous name]

📄 Specs status:
  ✅ requirements.md (approved)
  ✅ design.md (approved)
  🔄 tasks.md:
     [x] Task 1: DB schema
     [x] Task 2: API endpoints
     [ ] Task 3: Payment gateway     ← next
     [ ] Task 4: Error handling

📝 Last commits from [previous name]:
  • abc1234: "feat: add payments table schema"
  • def5678: "feat: implement POST /api/payments"

Shall we continue with Task 3?
```

4. If there is no handoff (same author) → continue normally without showing this

> This applies to all roles: a QA can resume a test plan from another QA, an Analyst can refine requirements from another Analyst.

### Role enforcement

**CRITICAL**: Before executing any task, check if it matches the user's configured role(s) in `.sdd-config.json`.

Read the `role` field from `.sdd-config.json`. It can be:
- A single role: `"role": "developer"`
- Multiple roles (comma-separated): `"role": "developer,analyst"`
- All roles: `"role": "all"`

**Rules:**
1. If `role` is `"all"` → no restrictions, proceed with any task
2. If the requested task's role is included in the user's role(s) → proceed normally
3. If the requested task's role is NOT in the user's role(s) → **BLOCK** with this message:

```
🚫 This task requires the [task_role] role. You're configured as [user_role].

Options:
1. Re-sync with the needed role: bash sdd-sync.sh --role [current],[needed]
2. Re-sync with all roles: bash sdd-sync.sh --role all
```

**Do NOT proceed with the task. Do NOT offer to "continue anyway".** The user must re-sync to add the role.

Examples:
- Developer asks "create requirements" → 🚫 Blocked (needs analyst)
- Developer,Analyst asks "create requirements" → ✅ Allowed
- QA asks "deploy to AWS" → 🚫 Blocked (needs developer)
- All asks anything → ✅ Allowed

### Blocked role guidance

When a task is blocked by role enforcement, don't just show the error. **Guide the user to what they CAN do:**

For **Developer** blocked from analyst/qa tasks:
```
🚫 Creating requirements requires the analyst role.

As Developer, you can:
- 📝 Update product.md with the feature you want to build
- ⏳ Wait for the Analyst to create requirements.md in specs/
- 🔄 Or add the role: bash sdd-sync.sh --role developer,analyst

The Analyst will see your feature in product.md when they sync.
```

For **Developer** with NO requirements yet (even if allowed by role):
```
⚠️ No requirements.md found in specs/. The SDD lifecycle requires:

  1. Analyst creates requirements.md (EARS format)
  2. Developer creates design.md AFTER requirements are approved
  3. QA creates test-plan.md in parallel or after design

You can:
- 📝 Update product.md to describe the feature
- 📋 Create requirements yourself (if you have analyst role)
- ⏳ Wait for the Analyst
```

> **NEVER suggest "start with design" or "start coding" if `requirements.md` does not exist for that feature.** This violates the SDD lifecycle and produces untracked work.

For **Analyst** blocked from developer tasks:
```
🚫 Designing architecture requires the developer role.

As Analyst, you can:
- 📋 Create or refine requirements in specs/
- 📊 Manage backlog and sprint planning
- 🔄 Or add the role: bash sdd-sync.sh --role analyst,developer
```

For **QA** blocked from other tasks:
```
🚫 This requires the [role] role.

As QA, you can:
- 🧪 Create test plans from approved requirements
- 📊 Analyze regression and test history
- 🔄 Or add the role: bash sdd-sync.sh --role qa,[needed]
```

### Cross-role feedback

When a user tries to modify an artifact that belongs to another role:

1. **BLOCK** the modification (existing behavior)
2. **Offer feedback option**: "Cannot modify [artifact] with your role. Create a note for the [owner role] in the work item?"
3. If user accepts:
   - Read `spec_prefix` from `.sdd-config.json`
   - If azure-devops MCP available:
     - `add_comment` to the work item with the feedback text
     - Add tag `needs-clarification`
     - Confirm: "Note added to {prefix}{ID}. The [owner role] will see it when reviewing their items."
   - If no azure-devops MCP:
     - Add a `## Feedback` section to the artifact file with the note
     - Confirm: "Note added to file. The [owner role] will see it when they open the project."
4. If user declines → just show the block message

### Exception: propagation marks

⚠️ **ANY role** can add `⚠️ REQUIRES REVIEW` to artifacts they do NOT own. This is NOT a content modification — it is a propagation signal.

**Allowed without blocking:**
- Analyst modifies requirements.md → adds `⚠️ REQUIRES REVIEW` to `## Status` of design.md, tasks.md, test-plan.md
- Developer modifies design.md → adds `⚠️ REQUIRES REVIEW` to test-plan.md
- QA reports gap in test-plan.md → adds `⚠️ REQUIRES REVIEW` to requirements.md or design.md

**Mark format:**
```markdown
## Status
⚠️ REQUIRES REVIEW — [source-artifact] modified on [date]. Changes: [brief summary].
```

**Rules:**
- Only add the mark in `## Status`. Do NOT touch the technical content of the artifact.
- The artifact owner is the one who reviews, updates, and removes the mark.
- If `## Status` does not exist in the artifact → create it at the end, before the footer.

### Artifact ownership by role
| Artifact | Owner role | Can modify | Can add `⚠️ REQUIRES REVIEW` |
|----------|-----------|------------|-------------------------------|
| requirements.md | analyst | analyst, all | any role |
| design.md | developer | developer, all | any role |
| tasks.md | developer | developer, all | any role |
| test-plan.md | qa | qa, all | any role |
| product.md | analyst | analyst, all | any role |

### First-interaction guidance by role and project state

First-interaction readiness is handled by precheck. See precheck.md.
