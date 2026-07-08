# Environment Configuration Examples

## environments.ts
```typescript
export const environments = {
  dev:  { account: '111111111111', region: 'us-east-1', dbInstanceClass: 't3.micro', enableWaf: false },
  cert: { account: '222222222222', region: 'us-east-1', dbInstanceClass: 't3.small', enableWaf: true },
  prod: { account: '333333333333', region: 'us-east-1', dbInstanceClass: 'r6g.large', enableWaf: true },
}
```

## Secrets Management Commands
```bash
# DB credentials
aws secretsmanager create-secret --name /app/{env}/db-credentials

# API keys
aws ssm put-parameter --name /app/{env}/api-key --type SecureString

# CDK reads
secretsmanager.Secret.fromSecretNameV2(this, 'DbCreds', '/app/{env}/db-credentials')
```

**Rule:** NEVER hardcode secrets in CDK stacks, env files, or pipeline YAML.
