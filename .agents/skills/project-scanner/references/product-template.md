# Product Template — Scanner Reference

<!-- Este archivo es una referencia rápida para project-scanner. -->
<!-- El template canónico está en core/env/product.md.template -->
<!-- Ambos (project-initializer y project-scanner) usan el mismo template unificado. -->

## Instrucciones para project-scanner

Al generar `product.md` desde un proyecto existente:

1. **Usar template canónico** → `core/env/product.md.template`
2. **Auto-fill desde detección**:
   - § Empresa y Contexto → inferir de README, package.json `author`, `description`
   - § Tech Stack → desde config files detectados (ver POWER.md §1)
   - § Project Structure → desde análisis de directorios (ver POWER.md §2)
   - § Main Dependencies → top 10 de package.json/pom.xml/requirements.txt
   - § Required Environment Variables → de `.env.example`, docker-compose, config files
   - § Detected Conventions → de ESLint, Prettier, tsconfig, .editorconfig
3. **Marcar `[VERIFY]`** → cualquier dato inferido que no sea 100% seguro
4. **Dejar vacío** → secciones que no aplican (Sprint para existing, Modules si no se detectan)

## Campos que project-scanner NO puede llenar (usuario debe completar)

| Campo | Razón |
|-------|-------|
| Empresa | No está en código |
| Dominio | Contexto de negocio |
| Stakeholders | Personas, no código |
| Problema que resuelve | Contexto de negocio |
| Usuarios objetivo | Contexto de negocio |
| Módulos funcionales (nombres) | Puede inferir estructura, no nombres de negocio |
| Sprint / Roadmap | No está en código |

Estos campos se presentan al usuario en CP4 para que los complete.
