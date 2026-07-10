# Infrastructure — Task Manager SDD

AWS CDK infrastructure for PostgreSQL 16 RDS database across dev/cert/prod environments.

## Prerequisites

1. **AWS CLI** configured with valid credentials
2. **Node.js** v18+ and npm
3. **AWS CDK** installed globally or via npx

```bash
npm install -g aws-cdk
```

## Quick Start

From the project root (`app/`):

```bash
# Bootstrap AWS account (first time only)
npm run infra:bootstrap

# Deploy development environment
npm run infra:deploy

# Deploy certification environment
npm run infra:deploy:cert

# Deploy production environment
npm run infra:deploy:prod
```

## Environments

| Environment | Instance Type | Storage | Backup | Deletion Protection | Removal Policy |
|-------------|---------------|---------|--------|---------------------|----------------|
| `dev` | t4g.micro | 20 GB | 7 days | ❌ | DESTROY |
| `cert` | t4g.micro | 20 GB | 7 days | ✅ | DESTROY |
| `prod` | t4g.small | 50 GB | 30 days | ✅ | RETAIN |

## Security

- **Dev**: Allows connections from any IP (0.0.0.0/0) for testing
- **Cert**: Restricts to private networks (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- **Prod**: Restricts to VPC CIDR only (10.0.0.0/8) - update with actual VPC CIDR

Credentials are stored in AWS Secrets Manager (auto-generated).

## Useful Commands

```bash
# From app/ directory
npm run infra:deploy          # Deploy dev
npm run infra:deploy:cert     # Deploy cert
npm run infra:deploy:prod     # Deploy prod
npm run infra:destroy         # Destroy dev
npm run infra:destroy:cert    # Destroy cert
npm run infra:destroy:prod    # Destroy prod
npm run infra:synth           # Synthesize CloudFormation template
npm run infra:diff            # Compare with deployed stack
npm run infra:bootstrap       # Bootstrap AWS account

# From infra/ directory
npx cdk synth -c env=dev      # Synthesize for dev
npx cdk diff -c env=dev       # Diff for dev
npx cdk deploy -c env=dev     # Deploy for dev
npx cdk destroy -c env=dev    # Destroy for dev
```

## Outputs

After deployment, CDK outputs:
- **DatabaseEndpoint**: RDS host address
- **DatabasePort**: Connection port (5432)
- **CredentialsSecretArn**: Secrets Manager ARN for DB credentials

Retrieve credentials:
```bash
aws secretsmanager get-secret-value --secret-id task-manager-db-credentials-dev --query SecretString --output text
```

## Configuration

Environment configurations are in `cdk.json` under `context.environments`.

To add a new environment:
1. Add entry in `cdk.json` → `context.environments`
2. Add scripts in `app/package.json`
3. Update this README

## Cost

- **Dev/Cert**: ~$0/month (AWS free tier)
- **Prod**: ~$15/month (without free tier)
- **Prod (Year 1)**: ~$0/month (with free tier)