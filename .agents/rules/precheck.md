# Precheck

Run steps 1→5 **in strict order** at conversation start. Do NOT skip ahead.

## ⛔ HARD RULES

1. **NEVER show tool output.** No JSON, no raw entities, no MCP responses.
2. **NEVER expose internal state.** Examples of violations:
   - ❌ "project_type está vacío" / "product.md sin completar" / ".sdd-config.json dice..."
   - ✅ "Proyecto sin configurar. ¿De qué trata?"
3. **Steps IN ORDER.** Complete step 3 before step 4.
4. **Respect `verbosity`** from `.sdd-config.json`:
   - `detailed` → show step results, ask before health check
   - `brief` → run ALL silently, auto-run health check, NO health check report. First visible output = question from step 4/5 or router. MAX 2 lines.
5. **Windows PowerShell:** Use `;` not `&&`.
6. **NEVER call `list_commands` or `list_tools` on any MCP.** Returns thousands of tokens. Use `list_servers` or one cheap operation per server.
7. **NEVER assume MCP availability from tool listings.** You MUST execute an actual call (e.g., `core_list_projects`) to verify. Reading tool names ≠ testing connectivity.

---

## Step 1 — Memory (silent)

If `server-memory` available: `read_graph` → internal only. Filter by `project:` matching current project. No match → proceed.

## Step 2 — Git identity (ALWAYS ask if empty, ignore verbosity)

Check `git config user.email`:

| Result | Action |
|---|---|
| Email is set | Skip silently. Do nothing. |
| Email is empty | 1. Ask user for name + email 2. `git config user.name "Name"` 3. `git config user.email "email"` 4. Run `sdd-sync.sh --refresh` (regenerates MCP config with new identity). Do NOT test ADO here — Step 3 handles it after MCP reloads. |

## Step 3 — MCP health check

Search memory for `mcp_healthcheck_last` with `project:` match.

| Condition | Action |
|---|---|
| No entity / no project match | ASK (detailed) or auto-run (brief) |
| Entity < 24h | Skip silently |
| Entity > 24h | ASK (detailed) or auto-run (brief) |

**How to test (choose ONE path):**

**Path A — lazy-mcp proxy detected:**
1. Call `lazy-mcp` → `list_servers`. This returns all available servers.
2. **Smoke-test critical servers** (via `invoke_command` through lazy-mcp):
   - `server-memory` → `read_graph` (already done in step 1)
   - `azure-devops` → `core_list_projects` — if fails, mark `ado_available: false`
   - If `ado_available: true` → check `.sdd-config.json` `AZURE_DEVOPS_PROJECT`. If empty → ASK user.
3. Mark remaining servers as OK (they only need proxy listing).
4. **Do NOT call `list_commands` or `list_tools`.**

**Path B — no proxy (direct MCP connections):**
1. `server-memory` → `read_graph` (already done in step 1)
2. `azure-devops` → `core_list_projects` (exact command name) — if fails, mark `ado_available: false`
3. If `ado_available: true` → read `.sdd-config.json` field `AZURE_DEVOPS_PROJECT`. If empty → ASK: "¿En qué proyecto de ADO trabajamos?" Save response to config.
4. `sequential-thinking` → `sequentialthinking` with thought:"test"
4. Others: one cheap call each. Retry once on failure.

**After health check (ALWAYS, both modes):**
1. Save to memory via `lazy-mcp` → `invoke_command`:
   ```json
   { "server": "server-memory", "command_name": "create_entities",
     "parameters": {
       "entities": [{ "name": "mcp_healthcheck_last", "entityType": "health_check",
         "observations": ["project:PROJECT_NAME", "date:ISO8601", "result:X OK, Y error", "errors:list"] }]
     }
   }
   ```
   ⚠️ With lazy-mcp: all tool inputs go inside `parameters`, NOT `arguments`.
2. Report to user (detailed only): "Health check: X OK, Y error". Brief = no report.

Then step 4. Do NOT query ADO items here.

## Step 4 — Project type (silent if set)

If `project_type` set AND `product.md` exists AND is NOT a placeholder → skip.
A product.md is a **placeholder** if it contains "⚠️ This is a placeholder" OR has < 50 lines. Treat placeholders as missing → trigger scanner.

If `project_type` empty, **auto-detect** (do NOT ask):

| Detection | Delegate to |
|-----------|------------|
| No code (no package.json, pom.xml, src/, etc.) | `project-initializer` → project_type=new |
| Code exists | `project-scanner` → project_type=existing. Scanner may SUGGEST migration if EOL detected (user decides). |

Scanner handles version comparison + EOL check. If 🔀 detected → scanner asks user "migration, upgrade, or keep?". NEVER auto-assigns migration.

## Step 5 — Readiness

| project_type | Check | If missing |
|---|---|---|
| new | product.md (+ stacks for dev) | → project-initializer |
| existing | stacks populated | → project-scanner |
| migration | stacks + migration.from/to | → project-scanner |

### Stack file sync check

After verifying `.sdd-config.json` has `stacks[]`, verify the **SDD skills** were synced to the IDE folder:

| IDE | Check for |
|---|---|
| Kiro | `.agents/skills/` contains skills (any `.md` beyond defaults) |
| Antigravity | `.agents/skills/` contains skill directories (e.g., `tech/SKILL.md`) |

The `sdd-sync.sh` script generates individual skill directories (e.g., `tech/`, `testing-jest/`, `structure/`), NOT monolithic `stack-{name}.md` files.

If `.sdd-config.json` has stacks but no skill directories exist → **BLOCK**:
```
⚠️ Skills de stacks no encontrados. Corre: bash sdd-sync.sh --ide [tu-ide] para sincronizar.
```
Do NOT proceed to router until skill files are present. This prevents working without stack context after cloning or switching IDEs.

## After all steps → Router

Hand off to `workflow-router.md` silently. No summary, no "all checks passed". If user says "precheck" → force re-run.
