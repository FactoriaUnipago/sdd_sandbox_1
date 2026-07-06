Server-memory scope entity for incremental delivery:

```yaml
Entity: {prefix}{ID}-scope
Type: RequirementScope
Observations:
  - project: [project_name]
  - total_proposed: 7
  - completed: REQ-001, REQ-002, REQ-003
  - pending: drag-drop, persistencia, eliminar, filtro-color
```

On subsequent sessions: read scope from memory, show pending, continue.
