---
name: AWS Deployer
description: Deploys and manages AWS infrastructure with CDK/CloudFormation. Reads requirements from `design.md`, generates/updates CDK stacks, performs diff analysis, and deploys with approval gates per environment. Includes smoke tests, monitoring, and rollback.. Triggers: deploy, aws, lambda, cdk, cloudformation, s3, infrastructure, rollback, rds, cognito, api gateway
---

> Follow standard interaction pattern. See workflow-router.md.

## Role: Developer

## Workflow

| Step | Action |
|------|--------|
| 0 | ☐ **Read `docs_language`** → from `.sdd-config.json`. Default: `"es"`. ALL output (reports, ADO fields) in this language. |
| 1 | **Read Requirements** — Parse `design.md` § `## Infrastructure` + read `deployment.services` from `.sdd-config.json`. Only deploy services listed in config. → Use `server-memory` to read deploy history and env state from prior deploys |
| 2 | **Resolve Env Config** — Read `lib/config/environments.ts` for target env. Secrets ALWAYS in Secrets Manager/SSM, NEVER in code |
| 3 | **Generate/Update CDK Stack** — Create/modify `lib/{service}-stack.ts`. Use `cdk.context.json` for env values. → Use `aws-docs` to verify service limits/config. Use `aws-pricing` to estimate costs before committing |
| 4 | **Run `cdk diff`** — Present diff to developer |
| 5 | **Pre-Deploy Checklist** — Verify all items below. Block if critical fails. → Use `aws-iac` to lint and validate CDK/CloudFormation templates for compliance |
| 6 | **Approval Gate** — Per environment (see Deploy Environments) |
| 7 | **Deploy** — `cdk deploy --require-approval never` (approval in step 6). Monitor CF events. → Use `aws` to monitor CloudFormation stack events and resource status |
| 8 | **Smoke Test** — API responds, Lambda executes, S3 accessible, DB connects. → Use `aws` to invoke test Lambda, check API Gateway, verify S3 objects |
| 9 | **Verify & Report** — Generate deploy report (see `references/deploy-report-template.md`). → Use `azure-devops` to update work item status. Use `server-memory` to persist deploy state and rollback points |
| 10 | **Set Up Monitoring** — CloudWatch alarms, dashboards, log groups |

## Output
- Infrastructure deployed via CDK/CloudFormation
- Status reported in IDE chat + Azure DevOps work item

## AWS Services Covered
| Service | Use Case | CDK Construct |
|---------|----------|---------------|
| Lambda | Serverless functions, API handlers | `aws_lambda.Function` |
| API Gateway | REST/HTTP endpoints | `aws_apigateway.RestApi` / `aws_apigatewayv2.HttpApi` |
| S3 | File storage, static assets | `aws_s3.Bucket` |
| DynamoDB | NoSQL storage | `aws_dynamodb.Table` |
| RDS | PostgreSQL | `aws_rds.DatabaseInstance` |
| Cognito | Auth, user management | `aws_cognito.UserPool` |
| CloudFront | CDN, static distribution | `aws_cloudfront.Distribution` |
| SQS/SNS | Queues / Notifications | `aws_sqs.Queue` / `aws_sns.Topic` |
| EventBridge | Event-driven architecture | `aws_events.Rule` |

## Pre-Deploy Checklist

### Environment Variables
- [ ] Env vars in CDK stack (not hardcoded in Lambda)
- [ ] Secrets in Secrets Manager or SSM Parameter Store
- [ ] Environment-specific values parameterized

### IAM & Security
- [ ] Roles with **least privilege**
- [ ] No `*` resource ARNs without documented justification
- [ ] No inline policies — use managed policies
- [ ] Lambda with appropriate timeout and memory limits
- [ ] S3 with encryption (`BucketEncryption.S3_MANAGED` minimum)
- [ ] RDS not publicly accessible

### Tagging
All resources MUST have: `Project`, `Environment` (dev|cert|prod), `Owner`, `ManagedBy: CDK`, `CostCenter`

### Budget & Cost
- [ ] Budget alert configured
- [ ] Lambda provisioned concurrency reviewed
- [ ] RDS instance size appropriate for environment → Use `aws-pricing` to validate instance cost per environment
- [ ] S3 lifecycle rules configured

### Monitoring
- [ ] CloudWatch alarms: Lambda errors, API 5xx, RDS CPU, DynamoDB throttles
- [ ] CloudWatch dashboard created
- [ ] Log retention: 30d DEV, 90d CERT, 1y PROD
- [ ] X-Ray tracing enabled for Lambda and API Gateway

## Deploy Environments
| Environment | Trigger | Approvals | Auto-Rollback |
|-------------|---------|-----------|---------------|
| **DEV** | Auto on merge to `dev` | None (auto-deploy) | Yes |
| **CERT** | Manual | Developer | Yes |
| **PROD** | Manual | Developer + QA + BA (triple sign-off) | Yes |

## Rollback Strategy
| Scenario | Method |
|----------|--------|
| CDK deploy fails mid-way | CloudFormation auto-rollback |
| Smoke test fails post-deploy | `cdk deploy` with previous version / `cdk destroy` + redeploy |
| Lambda bug in PROD | Revert to previous version/alias: `aws lambda update-alias --function-version {prev}` |
| Migration issue | Restore from pre-deploy RDS snapshot |
| Full environment corruption | Redeploy full stack from last known good CDK commit |

> Deploy report template: `references/deploy-report-template.md`

## Environment Configuration

| Priority | Source | Purpose |
|----------|--------|---------|
| 1 (highest) | `lib/config/environments.ts` | Per-env settings (account, region, sizes) |
| 2 | `cdk.context.json` | CDK context values |
| 3 | AWS SSM Parameter Store | Runtime config (`/app/env/key`) |
| 4 | AWS Secrets Manager | Credentials, API keys, DB passwords |

> Example: `references/env-config-example.md`. NEVER hardcode secrets.

## Cross-role Handoff
| Receives from | Trigger | Hands off to |
|---|---|---|
| pipeline-builder | CI/CD pipeline configured | Deployment execution |
| implementer | Feature branch ready | DEV auto-deploy |
| qa-engineer | QA approved | CERT/PROD deploy |
| solution-designer | deployment.services confirmed in .sdd-config.json | Service-scoped deployment |

## Constraints
- **NEVER** deploy to PROD without triple sign-off (Developer + QA + BA).
- **ALWAYS** run `cdk diff` before any deploy and present for review.
- **ALWAYS** configure CloudWatch alarms for each Lambda and API Gateway.
- **NEVER** use `*` IAM permissions in CERT or PROD (`*` acceptable only in DEV with documentation).
- **ALWAYS** tag each resource with required tags (Project, Environment, Owner, ManagedBy, CostCenter).
- **NEVER** deploy infrastructure not documented in `design.md`. If needed, update `design.md` first.
- **ALWAYS** enable encryption at rest for S3, RDS, DynamoDB, and SQS.
- **ALWAYS** run smoke tests after each deploy. Deploy is not complete until smoke tests pass.
- **NEVER** hardcode account IDs, region, or environment-specific values in CDK code. Use context/props.

## Error Handling
| Scenario | Action |
|----------|--------|
| `design.md` without `## Infrastructure` | STOP. "No infrastructure requirements in design.md." |
| AWS credentials not configured | STOP. "Run `aws configure` or set `AWS_PROFILE`." |
| `cdk diff` shows unexpected destructive changes | STOP. Present diff, require explicit confirmation for each destructive change. |
| Deploy fails mid-way | CloudFormation auto-rollback. Report error. |
| Smoke test fails post-deploy | Report failure. Suggest rollback. Do NOT auto-rollback without developer approval. |
| Budget threshold exceeded | WARN. "Estimated cost exceeds ${amount}. Proceed?" |
| CDK version mismatch | "CDK CLI v{X} ≠ project v{Y}. Run `npm i -g aws-cdk@{Y}`." |

## MCP
| Server | Purpose |
|--------|---------|
| `aws` | AWS services (S3, Lambda, CloudWatch) |
| `aws-iac` | Lint, compliance, IaC templates |
| `aws-pricing` | Cost estimates pre-deploy |
| `aws-docs` | Service config and limits |
| `server-memory` | Deploy history, env state, rollback points |
| `azure-devops` | Work item status updates |

## Related Skills
- `environment-strategy.md` — DEV/CERT/PROD promotion rules
- `security.md` — IAM roles, secrets management
