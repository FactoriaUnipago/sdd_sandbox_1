## Feature Parity Table Template

```
| # | Feature | Current stack | Target stack | Complexity | Notes |
|---|---------|--------------|--------------|:----------:|-------|
| 1 | Authentication | Passport.js | Cognito | 🟡 Medium | Migrate existing users |
```

## Schema Mapping Example (Oracle → PostgreSQL)

```
| Source (Oracle) | Target (PostgreSQL) | Transformation |
|-----------------|---------------------|---------------|
| NUMBER(10) | BIGINT | Direct |
| VARCHAR2(255) | VARCHAR(255) | Direct |
| DATE | TIMESTAMP WITH TZ | Add UTC timezone |
| CLOB/BLOB | TEXT/BYTEA | Encoding change |
| SYS_GUID() | gen_random_uuid() | Regenerate UUIDs |
```

## Cut-over Checklist Template

```markdown
## Cut-over Checklist
### Pre-migration
- [ ] Full source DB backup + infrastructure snapshot
- [ ] Feature flags configured
- [ ] Team notified (Dev + QA + BA + Ops) + maintenance window communicated to users
### During migration
- [ ] Run data migration scripts + verify row counts
- [ ] Smoke tests on new system + verify external integrations
### Post-migration
- [ ] DNS/LB pointing to new system + active monitoring (errors, latency, CPU)
- [ ] Manually validate critical flows + communicate to users
- [ ] Keep old system available for 72h (rollback)
```

## Module Iteration Flow

```
Module N → design-{module}.md → tasks-{module}.md → implement → test → ✅ next module
```

## Per-Module File Naming

```
specs/{prefix}[ID]-{migration-name}/
  ├── requirements.md          ← analyst (one for entire migration)
  ├── migration-plan.md        ← migration-planner (one for entire migration)
  ├── design-auth.md           ← solution-designer (module 1)
  ├── tasks-auth.md            ← solution-designer (module 1)
  ├── design-crud.md           ← solution-designer (module 2)
  ├── tasks-crud.md            ← solution-designer (module 2)
  ├── design-dashboard.md      ← solution-designer (module 3)
  ├── tasks-dashboard.md       ← solution-designer (module 3)
  ├── design-data-migration.md ← solution-designer (module 4)
  ├── tasks-data-migration.md  ← solution-designer (module 4)
  ├── design-infra.md          ← solution-designer (module 5)
  ├── tasks-infra.md           ← solution-designer (module 5)
  └── test-plan.md             ← qa-engineer (one for entire migration + per-module tests)
```

## Server-Memory Progress Entity

```
Entity: {prefix}{ID}-migration-progress
Type: MigrationProgress
Observations:
  - project: [project_name]
  - total_modules: 5
  - completed: auth, crud
  - in_progress: dashboard
  - pending: data-migration, infra
  - current_phase: 3
  - last_completed: 2026-07-01
```

## Traceability Block

```
## Traceability
- Work Item: {prefix}[ID]
- Requirement: specs/{prefix}[ID]-[name]/requirements.md
- Type: migration
- Branch: migration/{prefix}[ID]-[name]
```
