# Backlog Manager — Examples

## RICE Scoring Table

```markdown
## 📊 RICE Scoring — Priority Suggestions
| {prefix}ID  | Title                         | Reach | Impact | Confidence | Effort | RICE  | Current  | Suggested |
|--------|-------------------------------|-------|--------|------------|--------|-------|----------|-----------|
| {prefix}301 | Recurring payments            | 5000  | 3      | 80%        | 2.0    | 6000  | Should   | Must      |
| {prefix}315 | Dashboard dark mode           | 8000  | 0.5    | 100%       | 1.0    | 4000  | Could    | Should    |
| {prefix}308 | Export reports to Excel        | 2000  | 2      | 80%        | 1.5    | 2133  | Should   | Should    |
| {prefix}322 | Loading animations            | 8000  | 0.25   | 50%        | 0.5    | 2000  | Could    | Could     |
| {prefix}330 | Refactor auth module          | 500   | 1      | 50%        | 3.0    | 83    | Should   | Could     |
```

## Backlog Health Summary

```markdown
# 📋 Backlog Health Report

**Date:** 2025-01-15
**Total items:** 47
**Last analyzed:** Sprint 14

## Summary by State
| State    | Count | % of Total |
|----------|-------|------------|
| New      | 18    | 38%        |
| Approved | 12    | 26%        |
| Active   | 9     | 19%        |
| Resolved | 8     | 17%        |

## ⚠️ Stale Items (>30 days no update)
| {prefix}ID  | Title                     | Last Updated | Age (days) | Recommendation    |
|--------|---------------------------|--------------|------------|-------------------|
| {prefix}102 | PayPal integration        | 2024-11-20   | 56         | Close — deprioritized by product |
| {prefix}118 | Migrate to React 19       | 2024-12-05   | 41         | Revisit — blocked on React 19 stable release |
| {prefix}125 | Structured logs           | 2024-12-10   | 36         | Split — too large, break into 3 tasks |

## 🎯 Recommended Actions
1. **Close** — {prefix}102 PayPal integration — No product interest in 2 months, confirmed deprioritized
2. **Escalate** — {prefix}290 Fix webhook timeout — Blocked 14 days by {prefix}285, blocking 3 other items
3. **Reprioritize** — {prefix}301 Recurring payments — RICE score 6000, currently "Should", suggest "Must" based on reach
```
