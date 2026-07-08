# Project Initializer — Templates Reference

## Developer-role output message

```
✅ Project initialized: [name]
📝 product.md created with basic info.

Next steps:
1. Pass this project to an Analyst to create requirements:
   bash sdd-sync.sh --role analyst
   → "Create requirements for [feature]"
2. Or add analyst role yourself:
   bash sdd-sync.sh --role developer,analyst
```

## Analyst/All-role — single open prompt

```
Cuéntame del proyecto en tus palabras.
Cualquier detalle ayuda: nombre, qué hace, para quién,
cuántas personas trabajan en él.

Lo que no me digas lo infiero o marco como [TO BE DEFINED].
```

## Proposal example

```
📋 Propuesta de product.md:

Nombre: mi-app-pagos
Descripción: App de gestión de pagos para comercios
Propósito: Eliminar conciliación manual entre bancos
Usuarios: Operadores internos (backoffice) + comercios (portal)
Equipo: 3 personas (1 analyst, 1 dev, 1 QA)
Tracker: Azure DevOps → koneksi
Metodología: Scrum (inferido del equipo)

¿Ajusto algo o procedo?
```

## Ignore file template

Same template for `.dockerignore`, `.vercelignore`, `.ebignore` (when applicable):

```
specs/
tests/
docs/
db/
.kiro/
.cursor/
.windsurf/
.github/copilot/
.sdd-*
sdd-sync.sh
*.md
!README.md
```

## README.md template

```markdown
# {project-name}

{description from product.md}

## Purpose

{purpose/problem from product.md}

## Getting Started

This project follows the [SDD Standard](https://github.com/{org}/sdd-standard).

### Setup
```bash
bash sdd-sync.sh --role {role}
```

## Team

{team info from product.md, or [TO BE DEFINED]}

## Status

🚧 In development
```

If `README.md` already exists, do NOT overwrite — only create if missing.
