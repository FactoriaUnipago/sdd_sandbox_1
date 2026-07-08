---
name: Technology Stack — SDD
description: approved tech stack, versions, and selection criteria
---

# Technology Stack — SDD

The stack is defined in `.sdd-config.json` field `stacks[]`.

## Detection

- **project-scanner**: automatically detects stacks from existing code
- **solution-designer**: selects stacks for new projects based on requirements

## Available stacks

`typescript` · `python` · `react` · `angular` · `vue` · `aws` · `node` · `java` · `dotnet` · `go` · `capacitor` · `flutter` · `dart`

## Deployment platforms

`vercel` · `github-actions` · `azure-pipelines` · `aws-cdk`

Each platform activates deployment-specific steering. Platform is defined in `.sdd-config.json` field `deployment.host`.

Each stack activates specific steering from `.sdd-cache/stacks/`.

## Rules

- NEVER assume a stack without checking `.sdd-config.json`
- If `stacks[]` is empty in a new project → solution-designer defines it after requirements
- If `stacks[]` is empty in an existing project → project-scanner detects it
- Stack steering is activated from local cache, does not require re-sync
- The Developer can manually add stacks to `.sdd-config.json`
