---
name: IDE × SDD Integration
description: Guide IDE spec/plan modes to use SDD Standard powers, paths, and workflow
---

# IDE × SDD Integration

When the IDE has a native spec or plan mode (requirements → design → tasks), use SDD Standard workflow instead of IDE defaults.

## Spec/Plan mode integration

When the IDE activates a structured mode (spec mode, plan mode, etc.):

### Paths — use SDD structure, not IDE defaults
- Save specs to `specs/{prefix}[ID]-{name}/` (project root), NOT the IDE's internal spec directory
- `{prefix}` and work item ID come from `.sdd-config.json` → `spec_prefix` and Azure DevOps
- Example: `specs/AB#456-kanban-board/requirements.md`
- If no work item exists yet → use `specs/{feature-name}/`

### Workflow — follow SDD powers
- For requirements: use the `requirements-analyst` power workflow (EARS notation, 7 sources, scope analysis)
- For design: use the `solution-designer` power workflow (stack selection from tech.md, component drill-down)
- For tasks: use the `solution-designer` power output format (dependency chains, estimations, REQ references)
- Do NOT use the IDE's default templates — use the SDD power's format

### Do NOT create
- IDE-specific spec config files (e.g., `.config.kiro`, `.plan.json`)
- Files inside IDE-managed spec directories (e.g., `.agents/specs/`, `.cursor/specs/`)
- IDE default requirement/design templates

### DO use
- `precheck.md` on first interaction
- `workflow-router.md` for routing to the correct power
- Azure DevOps MCP for work item tracking
- Server-memory MCP for session persistence
- All SDD hooks for quality gates

## Free chat / vibe mode integration

When in free chat (no structured mode):
- Still follow `precheck.md` on first message
- Still route through `workflow-router.md`
- Powers activate by keyword
- Good for: quick fixes, investigations, explanations, single-task work

## What IDE structured modes add (keep these benefits)
- Phase gates (requirements approved → design → tasks)
- Living spec documents that update as implementation progresses
- Visual progress tracking in the IDE

## What SDD adds on top
- Azure DevOps integration (work items, assignments, state transitions)
- Role enforcement (analyst, developer, qa)
- 20 specialized powers with lifecycle gates
- Cross-role handoff with ADO tags
- Server-memory for persistence across sessions
- MCP health checks and credential management
