## Approval Matrix

```
DEV:  push → build → test → scan → deploy (auto)
CERT: manual → build → test → scan → [Dev+QA approve] → deploy → smoke test
PROD: manual → build → test → scan → [Dev+QA+BA approve] → deploy → smoke test → [all verify]
```
