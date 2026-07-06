---
name: DB Migrator
description: Manages database migrations: reads target schema from `design.md`, compares with current state, generates versioned scripts with rollback, and executes only with explicit developer approval.. Triggers: migration, database, schema, db, alter table, create table, index, constraint, rollback
---

> Follow standard interaction pattern. See workflow-router.md.

# DB Migrator

## Supported Engines
- **PostgreSQL** (RDS) via TypeORM / Alembic / raw SQL
- **DynamoDB** (schema changes, GSI management)

## Workflow

| Step | Action |
|------|--------|
| 1. Read Target Schema | Parse `design.md` → `## Data Model` / `## Database Schema`: tables, columns, types, constraints, indexes, relationships |
| 2. Inspect Current DB | Connect to target DB (DEV/CERT only). → Use `postgresql` MCP to obtain current schema. Use `context7` to verify ORM/migration tool syntax if using ORM migrations |
| 3. Compute Diff | Compare target vs actual: new/modified/deleted tables, columns, indexes, constraints, types |
| 4. Generate Script | Versioned SQL with UP + DOWN. Naming: `{NNN}_{description}.sql`. See `references/sql-templates.md` |
| 5. Data model update | Update `docs/architecture/data-model.md` if it exists: entity sections, ER diagram (mermaid), changelog entry. Skip if missing |
| 6. Dry Run | Present migration script, change summary, proposed data model updates. Show row counts for destructive ops |
| 7. Developer Approval | **WAIT** for explicit approval. Destructive ops (DROP/DELETE/ALTER type) → double confirmation |
| 8. Backup | Destructive ops → snapshot or export affected tables |
| 9. Execute | Run UP migration |
| 10. Verify | Run verification checks (see Verification section) |
| 11. Record & Save | Record in tracking table. Save data model updates. → Use `azure-devops` to update work item with migration status |
| 12. Save to memory | Persist migration history and schema state to server-memory |

## Output
| File | Purpose |
|------|---------|
| `db/migrations/NNN_description.sql` | Sequential migration scripts |
| `db/migrations/NNN_description_rollback.sql` | Rollback scripts |
| `docs/architecture/data-model.md` | Updated data model docs (if exists) |
| **Chat** | Migration summary (tables, direction, status). Never dump full SQL in chat |

> SQL templates, output format, and examples: `references/sql-templates.md`

## Safety Rules
- **ALWAYS** generate DOWN (rollback) for each migration. No exceptions.
- **NEVER** execute `DROP TABLE`, `DROP COLUMN`, `DELETE FROM` without explicit double confirmation.
- **ALWAYS** backup before destructive ops. RDS: snapshot. Tables: `pg_dump`.
- **ALWAYS** show row count of affected tables before destructive confirmation.
- **NEVER** execute against PROD. Only DEV/CERT. PROD via deployment pipeline.
- **ALWAYS** use `IF EXISTS` / `IF NOT EXISTS` for idempotent migrations.
- **ALWAYS** use `CREATE INDEX CONCURRENTLY` to avoid table locks.
- **NEVER** change column types without explicit USING clause.
- **ALWAYS** wrap multi-statement migrations in transaction (`BEGIN;...COMMIT;`) except with `CONCURRENTLY`.

## Verification
Post-migration checks:

| Check | Query | Expected |
|-------|-------|----------|
| Table exists | `SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '{table}');` | `true` |
| Column exists | `SELECT column_name FROM information_schema.columns WHERE table_name = '{table}' AND column_name = '{col}';` | Returns row |
| Row count | `SELECT COUNT(*) FROM {table};` | Matches pre-migration (non-destructive) |
| Constraints | `SELECT conname FROM pg_constraint WHERE conrelid = '{table}'::regclass;` | Expected constraints |
| Indexes | `SELECT indexname FROM pg_indexes WHERE tablename = '{table}';` | Expected indexes |
| No orphaned data | FK validation queries | No violations |

If verification fails → report and suggest DOWN rollback.

## Error Handling
| Scenario | Action |
|----------|--------|
| `design.md` without `## Data Model` | STOP. "No data model found in design.md." |
| DB connection fails | STOP. "Check connection string and VPN/network." |
| Script fails during execution | Auto-rollback DOWN. Report exact SQL that failed. |
| FK target table missing | STOP. "Cannot create FK to `{table}` — create it first." |
| Type change would lose data | STOP. "Changing `{col}` from `{old}` to `{new}` may lose data. Provide USING conversion." |
| Migration already applied | SKIP. "Migration `{version}` already exists." |

## MCP
- `postgresql` — execute queries, inspect schema, run migrations
- `server-memory` — persist migration history and schema state
- `azure-devops` — update work items with migration status
- `context7` — verify ORM/migration tool documentation


## Cross-role Handoff
| Receives from | Trigger | Hands off to |
|---|---|---|
| solution-designer | Data model changes in design.md | implementer (code changes) |
| migration-planner | Data migration phase | implementer (application code) |

## Related Skills
- `environment-strategy.md` — migration execution per environment
- `security.md` — credential handling for DB connections
