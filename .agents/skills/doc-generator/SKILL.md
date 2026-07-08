---
name: Doc Generator
description: Automatically generates technical documentation from source code. Produces API docs (OpenAPI 3.0), module READMEs, docstrings, ADRs, and Mermaid diagrams. All documentation requires Developer approval.. Triggers: documentation, api docs, swagger, readme, adr, openapi, mermaid, docstrings
---

## ⚠️ Step 0 — MCP Pre-flight (BEFORE any generating documentation)

**BLOCK**: Do NOT start generating documentation until you have completed this step.

1. ☐ Verify `context7` is reachable (test query for library API docs). If unavailable → note "[context7 unavailable]"
2. ☐ Call `codebase-memory` → verify project is indexed (module analysis, undocumented API detection). If unavailable → note "[codebase-memory unavailable]"
3. ☐ Verify `postgresql` is reachable (test connection for DB schema docs). If unavailable → note "[postgresql unavailable — DB docs will be manual]"

Only after ALL checks pass (or are documented as unavailable) → proceed.

## Role: Developer

## Keywords
documentation, api docs, swagger, readme, adr, openapi, mermaid, docstrings

## Overview
Automatically generates technical documentation from source code. Produces API docs (OpenAPI 3.0), module READMEs, docstrings, ADRs, and Mermaid diagrams. All documentation requires Developer approval.

---

## Workflow
0. ☐ **Read `docs_language`** → from `.sdd-config.json`. Default: `"es"`. ALL generated content (headers, body, ADO fields) in this language. Templates provide structure — translate headers to `docs_language` when generating.
1. **Analyze codebase** — Scan source files. Identify public APIs, exported functions, classes, and modules. → Use `codebase-memory` to analyze code structure and identify modules.
2. **Identify gaps** — Compare existing documentation vs code. Flag undocumented public APIs, missing READMEs, outdated docs. → Use `codebase-memory` to detect undocumented public APIs and stale references.
3. **Generate docs** — Produce documentation of the appropriate type (see Doc Types) for each gap. → Use `context7` to verify library APIs and usage patterns referenced in docs.
4. **Cross-reference** — Ensure docs reference related modules, link to ADRs, and include relevant Mermaid diagrams. → Use `azure-devops` to link documentation to related work items.
5. **Drift detection** — Compare generated diagrams/docs against `specs/{name}/design.md`. If code structure diverges from design (missing components, extra endpoints, different data model), flag: "⚠️ Code differs from design in [X]. Update design.md or fix code." → Use `codebase-memory` to compare current code structure against design specs.

### README.md drift detection

When triggered (merge to main, doc update), check README.md for drift:

| Check | Source of truth | Action if drifted |
|-------|----------------|-------------------|
| Tech stack listed | `.sdd-config.json` → stacks | Update `## Tech Stack` section |
| Install instructions | `package.json` scripts | Update `## Getting Started` |
| API endpoints listed | `docs/architecture/api-contract.md` | Update `## API` section |
| Project description | `product.md` | Update header description |

If drift detected → show changes → ask for approval → then include in commit.

6. **Developer approves** — Present documentation for review. Do NOT merge without approval.

## Doc Types

### 1. API Docs (OpenAPI 3.0)
OpenAPI 3.0 YAML for each REST endpoint. Include: path, method, parameters, request/response schemas (200, 400, 401, 404, 500), examples.
Output: `docs/api/openapi.yaml`
```yaml
paths:
  /payments:
    post:
      summary: Create payment
      responses:
        '201': { description: Payment created }
```

### 2. Module README
One `README.md` per module. Sections: Overview, Installation, Usage, API Reference, Examples, Contributing.
Output: `[module]/README.md`

### 3. Function/Class Docstrings
JSDoc (JS/TS), docstrings (Python). Include: description, `@param` with types, `@returns`, `@throws`, `@example`.
Inline in source files.

### 4. Architecture Decision Records (ADRs)
One ADR per significant architectural decision. Numbered: `docs/adr/ADR-001-[slug].md`

### 5. Mermaid Diagrams
Sequence (API flows), Component (module relationships), ER (DB schema).
Output: embedded in README or standalone in `docs/diagrams/`

---

## ADR Format
```markdown
# ADR-[NNN]: [Title]
**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-XXX]
**Date:** [YYYY-MM-DD]
**Deciders:** [names or roles]

## Context
[What problem motivates this decision]

## Decision
[What change is proposed/implemented]

## Consequences
### Positive
- [benefit]
### Negative
- [tradeoff]
### Risks
- [risk and mitigation]
```

---

## Output Conventions
- **Language:** Technical docs in English. User-facing descriptions may be in Spanish.
- **Links:** Cross-references use relative paths.
- **Examples:** Each public API must include at least one usage example.
- **Footer:** Each generated doc includes `_Last updated: [date]_`.

---

## Example: ADR
```markdown
# ADR-003: Use PostgreSQL as Primary Database
**Status:** Accepted | **Date:** 2025-01-10 | **Deciders:** Tech Lead, Backend Team

## Context
The application needs a relational DB with ACID transactions, native JSON, and scalability via read replicas. PostgreSQL, MySQL, and CockroachDB were evaluated.

## Decision
Use PostgreSQL 16 as the primary DB for transactional services.

## Consequences
### Positive
- Native JSONB support for payment metadata
- Mature extensions (pg_cron, PostGIS)
### Negative
- More complex to operate than MySQL
- Write scaling requires manual sharding
### Risks
- If volume > 50K TPS, sharding needed — mitigation: monitor from day 1
```

---

## MCP
- `context7` — verify library/framework documentation references
- `azure-devops` — link docs to work items
- `codebase-memory` — extract function signatures, call chains for API docs

## Related Skills
- `structure.md` — project structure conventions
- `artifact-storage.md` — where to store generated docs

## Output
- `docs/api/openapi.yaml` — OpenAPI spec generated from design.md
- `docs/api/README.md` — readable API documentation

## Constraints
- **NEVER** invent functionality that does not exist in code. Document only what is implemented.
- **ALWAYS** verify against actual source code. Do not document based on assumptions.
- **REQUIRE** Developer approval before merging generated documentation.
- **NEVER** overwrite manually written documentation without explicit approval. Prefer appending or suggesting changes.
- **ALWAYS** include examples for each public API — docs without examples are incomplete.
- **ALWAYS** keep ADRs immutable once Accepted. To change a decision, create a new ADR that supersedes it.
- **NEVER** include internal/private APIs in public documentation. Only exported/public interfaces.
