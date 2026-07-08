# Product Template — Scanner Reference

<!-- Additive guidance for product.md generation. -->
<!-- Do NOT duplicate POWER.md instructions here. -->

## Auto-fill mapping

| Section | Detection source |
|---------|-----------------|
| Company and Context | README.md, package.json `author`/`description`, pom.xml `groupId` |
| Tech Stack | Config files: package.json, pom.xml, build.gradle, requirements.txt, Cargo.toml |
| Project Structure | Directory listing + framework conventions |
| Main Dependencies | Top 10 from dependency manifest (package.json, pom.xml, requirements.txt, build.gradle) |
| Required Environment Variables | `.env.example`, docker-compose.yml, `application.properties`, config files |
| Detected Conventions | ESLint, Prettier, tsconfig, .editorconfig, checkstyle, spotless |

## Migration projects (project_type = "migration")

When `project_type` is `migration`, ALSO fill:

| Section | Detection source |
|---------|-----------------|
| Legacy System (As-Is) | pom.xml, web.xml, faces-config.xml, weblogic.xml, applicationContext.xml |
| Target Architecture (To-Be) | `.sdd-config.json` → `migration.to` + user input |
| Migration Strategy | `.sdd-config.json` → `migration.strategy` + user confirmation |

Include Mermaid architecture diagrams for both As-Is and To-Be.

If `project_type` is NOT `migration` → omit the migration sections from output.

## Fields the scanner CANNOT fill (user completes in CP4)

| Field | Reason |
|-------|--------|
| Company | Not in code |
| Domain | Business context |
| Stakeholders | People, not code |
| Problem it solves | Business context |
| Target users | Business context |
| Functional modules (names) | Can infer structure, not business names |
| Sprint / Roadmap | Not in code |
| Migration phases (scope) | Business decision |
