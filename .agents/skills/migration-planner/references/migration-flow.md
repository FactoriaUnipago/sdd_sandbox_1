## Migration Flow Diagram

### Standard project (new / existing)
```
Trigger → 📋 Analyst requirements → 💻 Developer design + tasks
→ 🧪 QA test plan → Implementation → Release
```

### Migration project (project_type = "migration")
```
Trigger → 💻 Developer scan (product.md)
→ 💻 Developer migration-plan.md (scope, phases, effort, variants)
→ 📋 Analyst requirements PER PHASE (business constraints, acceptance criteria)
→ 💻 Developer design + tasks PER PHASE
→ 🧪 QA test plan → Implementation by module → Cut-over → Release
```

> ⚠️ Key difference: In migrations, the migration-plan comes BEFORE requirements.
> The migration-plan defines WHAT gets migrated and in WHAT order (scope).
> Requirements define the acceptance criteria FOR EACH phase/module.
> You cannot write requirements without knowing the migration scope first.
