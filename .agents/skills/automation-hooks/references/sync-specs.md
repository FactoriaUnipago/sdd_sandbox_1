# Hook: Sync Specs to Azure DevOps

Trigger: After spec approval (requirements.md, design.md, test-plan.md)

## Behavior
1. Detect which spec was approved
2. Ask user: "Sincronizar con Azure DevOps?"
3. If yes:
   - requirements.md -> Create/update Epics + User Stories
   - design.md -> Create/update Tasks linked to Stories
   - test-plan.md -> Create/update Test Plans + Test Cases
4. Link all items with {prefix}IDs
5. Report what was synced

## Rules
- Always ask confirmation before syncing
- Never auto-close work items
- Log all sync operations
