# Stack Examples Reference

## Complete product.md template

```markdown
# [Project Name]

## Description
[Description provided by the user]

## Purpose
[Problem it solves / reason for existing]

## Tech Stack

### Language and Runtime
- **Language:** [Java 17 / TypeScript 5.x / Python 3.12 / etc.]
- **Runtime:** [Node.js 20 / JVM 17 / Python 3.12 / etc.]

### Frameworks
- **Backend:** [Spring Boot 3.2 / Express 4.x / FastAPI 0.100 / NestJS 10 / etc.]
- **Frontend:** [React 18 / Next.js 14 / Angular 17 / Vue 3 / N/A]
- **ORM:** [Prisma / TypeORM / Hibernate / SQLAlchemy / N/A]

### Database
- **Type:** [PostgreSQL 16 / MySQL 8 / MongoDB 7 / DynamoDB / Oracle 19c / etc.]
- **Migrations:** [Flyway / Liquibase / Prisma Migrate / Alembic / Knex / N/A]

### Infrastructure
- **Deploy:** [AWS ECS / Vercel / AWS Lambda / Kubernetes / etc.]
- **Containers:** [Docker / Docker Compose / N/A]
- **IaC:** [Terraform / CDK / Pulumi / N/A]

### CI/CD
- **Pipeline:** [Azure Pipelines / GitHub Actions / Jenkins / etc.]
- **Stages:** [Build → Test → Deploy Staging → Deploy Prod]

### Testing
- **Unit:** [Jest / JUnit / pytest / etc.]
- **E2E:** [Playwright / Cypress / N/A]
- **API:** [Postman / Supertest / N/A]

## Project Structure
[Initial proposed structure based on the chosen framework]

## Required Environment Variables
[List of known or expected env vars based on the stack]

## Conventions
- **Code style:** [ESLint + Prettier / Checkstyle / Black + Ruff / etc.]
- **Naming:** [camelCase / snake_case / kebab-case]
- **Git branching:** [GitFlow / Trunk-based / etc.]
- **Commits:** [Conventional Commits / etc.]

## Team
- **Size:** [Small / Medium / Large]
- **Roles:** [List of roles]
- **Methodology:** [Scrum / Kanban / etc.]
- **Sprint:** [Duration and current sprint if applicable]

## Users
- **Audience:** [Description of target users]
- **Type:** [Internal / Public / B2B / etc.]

## Integrations
[List of external services it integrates with]

## Notes
[Additional observations from the user]
```

## .sdd-config.json example

```json
{
  "version": "1.0.0",
  "project_type": "new",
  "stacks": [],
  "ides": ["kiro"],
  "verbosity": "detailed",
  "host": "github",
  "detected_by": "project-initializer",
  "last_sync": "2026-06-26T12:00:00Z"
}
```
