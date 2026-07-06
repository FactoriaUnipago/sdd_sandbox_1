# Backlog Health Report — Output Template

```markdown
# 📋 Backlog Health Report

**Date:** [YYYY-MM-DD]
**Total items:** [N]
**Last analyzed:** [sprint_name]

## Summary by State & Type
| Type | State | Count | % of Total |
|---|---|---|---|
| Feature | [State] | [N] | [N%] |
| Requirement | [State] | [N] | [N%] |
| Task/Bug | [State] | [N] | [N%] |

## ⚠️ Stale Items (>30 days no update)
| {prefix}ID   | Title              | Last Updated | Age (days) | Recommendation     |
|---------|--------------------|--------------|------------|-------------------|
| {prefix}[ID] | [Title]            | [date]       | [N]        | [Close/Revisit/Split] |

## 🚫 Blocked Items
| {prefix}ID   | Title              | Blocked By     | Days Blocked | Escalation Needed |
|---------|--------------------|----------------|--------------|-------------------|
| {prefix}[ID] | [Title]            | {prefix}[blocker]   | [N]          | [Yes/No]          |

## 📊 RICE Scoring — Priority Suggestions (Features/Epics only)
> *Note: Requirements, Tasks, and Bugs are excluded from RICE scoring as they inherit priority from their parent Feature.*

| {prefix}ID   | Title              | Reach | Impact | Confidence | Effort | RICE Score | Current Priority | Suggested Priority |
|---------|--------------------|-------|--------|------------|--------|------------|------------------|-------------------|
| {prefix}[ID] | [Title]            | [N]   | [N]    | [N%]       | [N]    | [score]    | [current]        | [suggested]        |

## 🎯 Recommended Actions
1. [Action] — [{prefix}ID] [Title] — [Reasoning]
```
