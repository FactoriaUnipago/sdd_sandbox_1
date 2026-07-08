# Code Review — Output Format

## Full Template

```markdown
# Code Review Report
**Branch:** `feature/XYZ` | **Date:** {YYYY-MM-DD}
**Files Reviewed:** {n} | **Findings:** 🔴 {blockers} | 🟡 {warnings} | 🟢 {suggestions}

---
## File: `{path}`

{🔴|🟡|🟢} {LEVEL} | `{path}:{line}`
**Issue:** {description}
**Risk:** {impact}
**Fix:** {suggestion}

---
## Summary
| Severity | Count | Action Required |
|----------|-------|-----------------|
| 🔴 Blocker | {n} | Must fix before merge |
| 🟡 Warning | {n} | Should fix before merge |
| 🟢 Suggestion | {n} | Optional |

**Verdict:** ✅ APPROVED | ❌ CHANGES REQUESTED — Resolve {n} blockers before merge.
```

## Minimal Example

```
🔴 BLOCKER | `src/payments.ts:42`
**Issue:** SQL concatenation — injection risk. **Fix:** Use parameterized query.
```
