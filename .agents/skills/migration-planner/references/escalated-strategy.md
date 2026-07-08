# Escalated Strategy (Detail)

## Workflow per jump
1. Read the official changelog for the target version
2. Identify breaking changes that affect the project
3. Generate a mini migration-plan for this jump
4. Implement changes + fix deprecations
5. QA: regression tests + verify that warnings have disappeared
6. Release the jump
7. Next jump

## Example: Angular 14 → 20

```
Jump 1: Angular 14 → 16
  Breaking: Standalone components by default
  Action: Convert modules to standalone
  QA: Regression ✅ → Release

Jump 2: Angular 16 → 18
  Breaking: Signals, new control flow (@if, @for)
  Action: Migrate from *ngIf/*ngFor to @if/@for
  QA: Regression ✅ → Release

Jump 3: Angular 18 → 20
  Breaking: Zoneless change detection
  Action: Remove Zone.js, migrate to signals
  QA: Regression ✅ → Release
```

## Breaking Changes Sources

ALWAYS consult the official documentation before planning:

| Stack | Breaking changes source |
|-------|------------------------------|
| Angular | `angular.dev/update` + `ng update` tool |
| React | React blog (react.dev/blog) |
| Node.js | `nodejs.org/en/blog/release` |
| Python | `docs.python.org/3/whatsnew` |
| AWS CDK | GitHub releases from the `aws/aws-cdk` repo |
| TypeScript | `typescriptlang.org/docs/handbook/release-notes` |
| Next.js | `nextjs.org/blog` + codemods |

Use MCP Context7 to read official documentation when available.
