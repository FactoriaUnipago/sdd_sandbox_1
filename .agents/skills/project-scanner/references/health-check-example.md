# Health Check Output Example

```markdown
## ⚠️ Health Check — Riesgos detectados

| # | Riesgo | Detalle | Severidad | Acción recomendada |
|---|--------|---------|:---------:|-------------------|
| 1 | Angular 14 EOL | End-of-Life desde Nov 2023 | 🔴 Crítico | Migrar a Angular 18+ |
| 2 | Node.js 16 EOL | End-of-Life desde Sep 2023 | 🔴 Crítico | Actualizar a Node 20 LTS |

### Recomendación
Este proyecto tiene **2 riesgos críticos**. Se recomienda activar el
**migration-planner** para generar un plan de migración paso a paso.

¿Deseas que inicie la planificación de migración?
```

# Migration Assessment Output Example

```
| Component | Current | Latest | Status | Change type |
|-----------|---------|--------|--------|-------------|
| React     | 16.14   | 18.3   | 🟡 Old | 🔄 Upgrade  |
| PHP       | 5.6     | —      | 🔴 EOL | 🔀 Replace  |
```
