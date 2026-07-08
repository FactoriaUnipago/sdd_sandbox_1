---
name: Estimation Strategy
description: Centralized estimation rules for all SDD powers. Covers manual, AI-assisted, and architecture-variant scenarios.
---

# Estimation Strategy

> Single source of truth for estimation rules. All powers that estimate effort MUST reference this file instead of inline rules.
> 
> Updated: July 2026. Based on industry data from Forrester, DORA, DX, and real-world agentic IDE adoption metrics.

## Base Rules (all scenarios)

- Maximum **4 hours** per task (break larger into subtasks)
- Estimates include: implementation + unit tests + code review + **verification** (reviewing AI output)
- If a task exceeds 4h during implementation → split immediately
- Add **20% buffer** to total estimate for unknowns
- Track actual vs estimated for future velocity calibration
- Story points map to hours: 1 pt ≈ 2-4h depending on team calibration

## Estimation Scenarios

Every estimation MUST present **at least 2 scenarios** side by side. The applicable scenarios depend on project context.

### Scenario A — Manual Development (no agentic IDEs)

Traditional development with standard tooling (VSCode, IntelliJ, standard Copilot autocomplete).

| Task Type | Baseline | Notes |
|---|---|---|
| Requirements + design per feature | 4-8h | Analyst + Developer collaboration |
| Simple CRUD screen | 4-6h | Form + table + API |
| Medium screen (business logic) | 8-16h | Validation, state, integrations |
| Complex screen (workflows, multi-step) | 16-32h | Business rules, edge cases |
| API endpoint (REST) | 2-4h | Route + controller + validation |
| API endpoint (SOAP adapter/BFF) | 4-8h | Mapping + transformation |
| DB schema + migration | 2-4h | Per table/entity |
| Unit + integration tests | 30% of implementation time | Per feature |
| CI/CD pipeline setup | 4-8h | Per environment |
| Code review + QA | 20% of implementation time | Per feature |

**Team composition**: Typically segregated — N frontend + N backend devs. Coordination overhead: high (handoffs, API contracts, blocking).

### Scenario B — SDD Standard + Agentic IDEs

Development with Kiro, Antigravity, Cursor, Claude Code or similar + SDD standard powers.

> ⚠️ **Reality check (mid-2026 industry data):**
> - Industry average velocity multiplier: **~1.7x** (elite teams: 1.8x-2.0x)
> - PR throughput increase: **5-15%** at org level (individual tasks: 30-50% faster)
> - AI-authored code merged: **25-35%** average teams, **60-75%** elite SDD teams
> - Developer trust in AI output: **29%** (down from 40% in 2024) — verification time is real
> - The "verification tax": time saved in generation is partially consumed by auditing AI output

| Task Type | AI Multiplier | Effective Time | What AI Does | Verification Overhead |
|---|---|---|---|---|
| Requirements + design | 0.4x | ~2-3h | Agent fills templates, proposes REQs from scan | Low — human reviews structure |
| Simple CRUD screen | 0.5x | ~2-3h | Agent generates full component + API | Low — pattern-based, easy to verify |
| Medium screen | 0.6x | ~5-10h | Agent scaffolds, human adjusts business logic | Medium — logic review needed |
| Complex screen | 0.75x | ~12-24h | Agent helps structure, human owns logic | High — deep review required |
| API endpoint (REST) | 0.4x | ~1-2h | Agent generates route + controller + types | Low — predictable output |
| API endpoint (SOAP/BFF) | 0.4x | ~2-3h | Adapter boilerplate automatable, mapping needs review | Medium — WSDL mapping verification |
| DB schema + migration | 0.6x | ~1-2h | Agent generates from design.md entities | Medium — data integrity review |
| Tests | 0.5x | ~15% of impl | Agent generates test scaffolding + fixtures | Medium — coverage adequacy review |
| CI/CD pipeline | 0.6x | ~2-5h | Agent generates from deployment pattern | Medium — security + secrets review |
| Code review | 0.7x | ~15% of impl | Agent pre-reviews, human validates | High — AI reviewing AI needs human oversight |

> **Why these multipliers are more conservative than 2025 estimates:**
> 1. **Verification tax**: AI generates faster, but reviewing AI output takes ~20-30% of saved time back
> 2. **Trust gap**: Developers spend more time verifying AI suggestions (trust dropped to 29%)
> 3. **Complexity ceiling**: AI gains compress sharply for complex business logic tasks
> 4. **Integration friction**: Real-world projects have auth, legacy APIs, edge cases AI doesn't handle well

> ⚠️ What AI does NOT accelerate (keep at 1.0x):
> - Business logic analysis and extraction from legacy code
> - Stakeholder validation and UAT
> - Integration testing against legacy/external systems
> - Cutover planning and execution
> - Security audits and compliance review
> - Performance tuning under production load
> - Debugging production-only issues (environment-specific, data-dependent)
> - Third-party API integration troubleshooting

**Team composition**: Full-stack per feature. With agentic IDEs, front/back segregation disappears — one dev generates component + endpoint in the same session. Use fewer, more senior full-stack devs.

> ⚠️ **Cognitive load shift**: While coding tasks are faster, the work becomes MORE cognitively demanding. Developers spend more time on architecture decisions, edge cases, and verifying AI output — less on the "relaxing" middle phase of typing code. Factor this into sustained velocity — AI-assisted devs may need more breaks and have lower sustained output in 8h+ days.

| | Manual | AI-assisted |
|---|---|---|
| Team structure | N front + N back | N full-stack |
| How they work | Front waits for back | spec → full feature (same session) |
| Coordination overhead | High (handoffs) | Minimal (one person, one feature) |
| Services to maintain | Separate repos/pipelines | Unified |
| Cognitive load | Distributed across typing + thinking | Concentrated on decisions + verification |

### Scenario C — SDD + Agentic IDEs (Mature Team, 3+ months)

Teams that have been using SDD + agentic IDEs for 3+ months develop patterns, shortcuts, and calibrated trust. Multipliers improve as the "verification tax" decreases with experience.

| Task Type | Mature Multiplier | vs Scenario B | Why |
|---|---|---|---|
| Requirements + design | 0.3x | -0.1x | Team knows templates, less review needed |
| Simple CRUD screen | 0.35x | -0.15x | Patterns established, trust calibrated |
| Medium screen | 0.5x | -0.1x | Business logic patterns recognized |
| Complex screen | 0.7x | -0.05x | Marginal improvement — complexity is the bottleneck |
| API endpoint (REST) | 0.3x | -0.1x | Highly repetitive, agents excel |
| Tests | 0.35x | -0.15x | Test patterns established, fixtures reused |

> Teams reach "mature" status after ~3 sprints of consistent SDD usage. Track calibration metrics to confirm.

### Team Size Scaling

More people ≠ proportionally faster. Coordination overhead grows with team size (Brooks's Law).

#### Efficiency by team size

| Team Size | Manual Efficiency | AI-Assisted Efficiency | Coordination Overhead |
|:-:|:-:|:-:|---|
| 1 | 100% | 100% | None — single owner |
| 2 | 95% | 97% | Minimal — pair alignment |
| 3 | 85% | 92% | Daily sync, PR reviews |
| 4 | 75% | 87% | Sprint ceremonies, API contracts, merge conflicts |
| 5 | 65% | 80% | Cross-team dependencies, waiting, context switching |
| 6+ | 55% | 72% | Sub-teams needed, communication explosion |

> AI-assisted teams lose less efficiency per person because:
> - Each dev is self-sufficient (full-stack per feature = less handoff)
> - Agent handles boilerplate = less merge conflict surface
> - SDD specs = shared language, less ambiguity

#### Effective throughput formula

```
Effective Throughput = Team Size × Per-Person Output × Efficiency%

Where:
  Per-Person Output (manual)          = ~5-8 story points / sprint
  Per-Person Output (AI-assisted)     = ~8-12 story points / sprint
  Per-Person Output (AI mature 3mo+)  = ~10-14 story points / sprint
  Efficiency%                         = from table above
```

**Examples:**

| Scenario | Team | Raw Capacity | Efficiency | Effective |
|---|:-:|:-:|:-:|:-:|
| Manual, 4 devs | 4 front+back | 4 × 6 = 24 pts | 75% | **18 pts** |
| AI, 2 full-stack | 2 full-stack | 2 × 10 = 20 pts | 97% | **19.4 pts** |
| Manual, 6 devs | 3+3 | 6 × 6 = 36 pts | 55% | **19.8 pts** |
| AI, 3 full-stack | 3 full-stack | 3 × 10 = 30 pts | 92% | **27.6 pts** |
| AI mature, 3 full-stack | 3 full-stack | 3 × 12 = 36 pts | 92% | **33.1 pts** |

> ⚠️ Key insight: 2 AI-assisted full-stack devs often match or exceed 4 manual devs.
> With 3+ months maturity, 3 AI devs can match 6-8 manual devs.

#### Recommended team sizes

| Project Size | Manual | AI-Assisted | AI Mature (3mo+) |
|---|---|---|---|
| Small (< 20 screens/features) | 2-3 devs | 1-2 full-stack | 1 full-stack |
| Medium (20-100 screens) | 3-5 devs | 2-3 full-stack | 2 full-stack |
| Large (100-300 screens) | 5-8 devs (sub-teams) | 3-4 full-stack | 2-3 full-stack |
| Enterprise (300+ screens) | 8-12 devs (multiple teams) | 4-6 full-stack (2 sub-teams) | 3-5 full-stack |

> Beyond recommended sizes, split into independent sub-teams by domain/module rather than adding more people to a single team.

## Architecture Variant Impact

Architecture choices directly affect effort. Estimate MUST account for which variant is chosen.

### Frontend + BFF (Backend-for-Frontend)

Two separate codebases — React/Angular frontend + Node/Express BFF that wraps legacy APIs.

| Impact | Multiplier | Why |
|---|---|---|
| API layer effort | 1.5x | Every endpoint needs BFF mapping + frontend call |
| Infrastructure | 1.3x | Two deployments, two pipelines, two monitoring |
| Testing | 1.4x | Integration tests for frontend↔BFF + BFF↔legacy |
| Coordination | 1.2x | API contract management between layers |

**When to use**: Legacy APIs are SOAP/XML, need transformation, auth gateway, or API aggregation.

### Frontend-Only with API Proxy

Single codebase — framework handles API proxying to legacy services (Next.js rewrites, Nuxt proxy, nginx).

| Impact | Multiplier | Why |
|---|---|---|
| API layer effort | 0.7x | No separate BFF — proxy config only |
| Infrastructure | 0.8x | Single deployment |
| Testing | 0.8x | Only frontend↔legacy integration |
| Coordination | 0.9x | No API contract management |

**When to use**: Legacy APIs are already REST/JSON, minimal transformation needed, or using API Gateway.

### Full-Stack Framework (Next.js/Nuxt SSR)

Server components call legacy APIs directly — no separate API layer.

| Impact | Multiplier | Why |
|---|---|---|
| API layer effort | 0.5x | Server components ARE the API layer |
| Infrastructure | 0.7x | Single deployment, SSR handles everything |
| Testing | 0.9x | Server component testing adds complexity |
| Coordination | 0.7x | Monolithic — no cross-service coordination |

**When to use**: Greenfield or migration where you control the full stack. Best with agentic IDEs.

## Migration-Specific Estimation

For `project_type = "migration"`, additional factors apply.

### Complexity Classification

Classify items from the codebase inventory scan:

| Complexity | Criteria | Base Effort (manual) | With AI | With AI Mature |
|---|---|---|---|---|
| 🟢 Simple | < 100 lines, no business logic | 0.5 days | 0.25 days | 0.15 days |
| 🟡 Medium | 100–300 lines, some logic | 1-2 days | 0.6-1.2 days | 0.5-1 days |
| 🔴 Complex | 300+ lines, embedded business logic | 3-5 days | 2.2-3.8 days | 2-3.5 days |

### Migration Estimation Formula

```
Total effort = Σ (items × complexity_effort × architecture_multiplier × ai_multiplier) + fixed_overhead

Where:
  fixed_overhead = infrastructure setup + CI/CD + cutover + UAT + verification
  architecture_multiplier = from §Architecture Variant Impact
  ai_multiplier = from §Scenario B or §Scenario C (if applicable)
  verification = 15-25% of AI-generated implementation time (the "verification tax")
```

### Three-Scenario Matrix (mandatory for migrations)

| Scenario | Condition | Buffer |
|---|---|---|
| Optimistic | No blockers, senior team, clean legacy code, mature AI adoption | +0% |
| **Realistic** | Standard contingency, some legacy surprises, AI learning curve | **+25%** |
| Pessimistic | High tech debt, unclear business logic, team new to AI tools | +50% |

Present as 3×3 matrix (3 scenarios × manual / AI new / AI mature):

```
| Scenario | Manual | AI + SDD (new) | AI + SDD (3mo+) |
|---|---|---|---|
| Optimistic | X sprints | X sprints | X sprints |
| Realistic | X sprints | X sprints | X sprints |
| Pessimistic | X sprints | X sprints | X sprints |
```

## Sprint Capacity

```
Sprint Capacity = Team Size × Sprint Days × Availability% × Velocity Factor

Where:
  Team Size       = Number of team members
  Sprint Days     = Working days in sprint (typically 10)
  Availability%   = Account for PTO, holidays, meetings (typically 80%)
  Velocity Factor = Average story points per person-day (from historical data)
```

**Agentic tooling adjustment**: If team uses agentic IDEs + SDD:
- **New team (< 3 months)**: apply **1.3x–1.5x** multiplier on Velocity Factor
- **Mature team (3+ months)**: apply **1.5x–1.8x** multiplier on Velocity Factor
- Does NOT apply to sprints focused on business analysis, UAT, or manual testing

## Calibration

After each sprint, track:

| Metric | Formula | Target | Action if off-target |
|---|---|---|---|
| Estimation accuracy | actual_hours / estimated_hours | 0.8–1.2 | Recalibrate multipliers |
| Velocity trend | story_points_completed per sprint | Stable ± 15% | Check team changes or scope creep |
| AI effectiveness | manual_estimate / actual_with_AI | > 1.4x (new) / > 1.7x (mature) | Verify AI tool adoption |
| Verification ratio | verification_hours / total_hours | 15-25% | If > 30%, AI quality issues; if < 10%, insufficient review |
| AI code share | ai_authored_lines / total_merged_lines | 25-35% (new) / 50-70% (mature) | Track adoption curve |

Store in `server-memory` as `estimation_calibration_{sprint}` for trend analysis.

> If estimation accuracy is consistently < 0.8 (overestimating) or > 1.2 (underestimating) for 3+ sprints → recalibrate multipliers.
> If AI effectiveness < 1.3x for 3+ sprints → investigate: tool usage, task types, team resistance.
