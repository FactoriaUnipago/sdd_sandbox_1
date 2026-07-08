# Deploy Report Template

```markdown
# Deploy Report
**Service:** {name} | **Env:** DEV|CERT|PROD | **Date:** {YYYY-MM-DD HH:MM UTC}
**CDK Stack:** {stack} | **Status:** ✅ SUCCESS | ❌ FAILED | ⚠️ PARTIAL

## Resources
| Action | Type | Name | Status |
|--------|------|------|--------|

## Endpoints
| Service | URL | Status |
|---------|-----|--------|

## Smoke Test Results
| Test | Result |
|------|--------|

## Monitoring
| Alarm | Metric | Threshold | Status |
|-------|--------|-----------|--------|

## Approvals
| Role | Approver | Status |
|------|----------|--------|
```

## Minimal Example
```
**Service:** payments-api | **Env:** DEV | **Status:** ✅ SUCCESS
| CREATE | Lambda | payments-handler | ✅ | | UPDATE | ApiGateway | payments-api | ✅ |
```
