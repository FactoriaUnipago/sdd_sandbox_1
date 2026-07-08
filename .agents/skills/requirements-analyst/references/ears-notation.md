# EARS Notation — Detailed REQ Format

Each REQ in requirements.md follows this structure:

```markdown
### REQ-001 — [Short title]
- **EARS**: WHEN [condition] the system SHALL [action]
- **Entities**: [table/object names involved, with key fields if known]
- **Errors**: [error conditions → expected response/behavior]
- **Accepts if**: [testable acceptance criteria — what proves it works]
- **Depends on**: [REQ-NNN | — if none]
- **Priority**: high | medium | low
```

## Example

```markdown
### REQ-001 — JWT Authentication
- **EARS**: WHEN a request arrives, the API SHALL validate the JWT token in the Authorization header
- **Entities**: users (id, email, created_at)
- **Errors**: Missing token → 401, Expired token → 401 + "Token expired", Invalid signature → 403
- **Accepts if**: Valid token → 200 + user context. Invalid → 401. Expired → 401 with message.
- **Depends on**: —
- **Priority**: high

### REQ-003 — State Machine
- **EARS**: WHEN a user changes task status, the API SHALL validate the transition is allowed
- **Entities**: tasks (id, status), allowed_transitions matrix
- **Errors**: Invalid transition → 400 + "Transition from [X] to [Y] not allowed"
- **Accepts if**: Pendiente→En progreso ✅, Completada→Pendiente ❌ (400)
- **Depends on**: REQ-002
- **Priority**: high
```

## EARS Patterns

| Pattern | Template |
|---------|----------|
| Event-driven | WHEN [event], the system SHALL [action] |
| State-driven | WHILE [state], the system SHALL [action] |
| Unwanted | IF [condition], the system SHALL [action] |
| Ubiquitous | The system SHALL [action] |
| Optional | WHERE [feature], the system SHALL [action] |

## Change Log Table

```
| Date | REQ | Change | By | Reason |
|------|-----|--------|----|--------|
| 2026-07-01 | REQ-004 | Added touch events | analyst | Developer feedback |
```
