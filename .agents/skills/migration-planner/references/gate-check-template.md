## Gate Check — Migration Planner Prerequisites

### Required: product.md + scan
When `product.md` or `.sdd-config.json` with `project_type: "migration"` is NOT found, respond:

```
⚠️ Migration planning requires a completed project scan first.

Before I can create the migration plan, I need:
1. product.md with legacy system documentation (As-Is)
2. .sdd-config.json with project_type: "migration"

Run the project-scanner first to generate these.
```

### NOT required: requirements.md
> ⚠️ For migration projects, requirements come AFTER the migration plan, not before.
> The migration plan defines the scope and phases.
> The Analyst then writes requirements PER PHASE using the plan as input.
