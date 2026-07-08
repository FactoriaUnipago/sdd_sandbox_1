---
name: Security Standards
description: OWASP, secrets management, auth patterns, input validation
---

# Security Standards

> Code examples: `references/security-examples.md`

## Secrets Management
- **NEVER** hardcode secrets, API keys, passwords, or tokens in source code
- Use AWS Secrets Manager or SSM Parameter Store for all secrets
- Personal credentials in `.sdd-credentials.json` (gitignored, NEVER committed)
- Rotation: 90 days min, 30 days for production DB passwords
- Local dev: `dotenv` with `.env` gitignored
- CI audit: `detect-secrets` or `trufflehog`

## Authentication
- AWS Cognito for user auth; IAM roles for services (least privilege)
- JWT tokens: access=15min, refresh=7d single-use (rotate on refresh)
  - Validate `iss`, `aud`, `exp`, `sub` on every request
  - Refresh tokens: server-side or httpOnly secure cookies (NEVER localStorage)
- Invalidate all sessions on password change
- Rate limit: max 5 failed logins → 15 min lockout
- MFA: required for admin, recommended for all

## Authorization
- RBAC with least privilege; grant minimum permissions needed
- API keys: scope to endpoints/resources, set expiration, log all usage
- Check authorization on EVERY endpoint (never frontend-only)
- Middleware: `authenticate → authorize → handler`

## Data Protection

| Area | Rule |
|------|------|
| At rest | AES-256, RDS encryption enabled |
| In transit | TLS 1.3 minimum |
| PII classify | PII, PHI, financial, public |
| Log redaction | **NEVER** log PII (mask SSN, email, phone) |
| Retention | Define periods per data class |
| Deletion | Support GDPR/data subject requests |
| DB columns | Encrypt sensitive (SSN, payment) at app layer |

## Input Validation
- Validate at API Gateway (JSON schema) AND app layer (Zod/Pydantic)
- Sanitize ALL input against XSS (`DOMPurify` for HTML, escape templates)
- **NEVER** concatenate strings into SQL — use parameterized queries
- File uploads: check MIME, size limits, malware scan
- Strict schema: reject unexpected fields (no extra properties)

## OWASP Top 10

| # | Threat | Mitigation |
|---|--------|------------|
| 1 | Broken Access Control | Server-side authz on every endpoint |
| 2 | Cryptographic Failures | Encrypt at rest + transit, no weak algos |
| 3 | Injection | Parameterized queries, validate input, no eval |
| 4 | Insecure Design | Threat model in design, defense-in-depth |
| 5 | Security Misconfig | No defaults, disable unused, security headers |
| 6 | Vulnerable Components | `npm/pip audit` every build, no critical CVEs |
| 7 | Auth Failures | Rate limiting, MFA, secure sessions |
| 8 | Data Integrity | Verify CI/CD integrity, sign artifacts |
| 9 | Logging Failures | Log auth/access/validation events (never PII) |
| 10 | SSRF | Allowlist outbound URLs, no user-controlled URLs |

## Dependencies
- `npm audit` / `pip audit` on every PR (CI blocks critical/high)
- Renovate or Dependabot for automated updates
- No critical-vuln deps in production
- Lock files committed and verified
- Review new deps: maintainers, downloads, last update

## Security Headers
Required headers — see `references/security-examples.md` for values:
`HSTS`, `CSP`, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`
