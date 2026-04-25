---
name: review-plan
description: Deep critical review of consolidated implementation plans. Compares against the gold-standard example plan, interrogates every decision with "why, why, why" engineering leadership rigor, checks codebase compliance (existing infrastructure, patterns, conventions), and checks plan compliance (required sections, depth, production-readiness). Use when reviewing a plan document, auditing a plan for gaps, or when the user asks to review, critique, or validate a plan before implementation.
---

# Plan Review Skill

Review consolidated implementation plans with engineering leadership rigor. Every claim is guilty until proven necessary. Every "why" gets pushed until the root justification surfaces.

## Inputs

1. **The plan to review** -- a markdown file the user provides
2. **The example plan** -- read `plan review/consolidated-plan.md` at workspace root as the gold standard
3. **AGENTS.md** -- read for learned workspace facts, constraints, and conventions
4. **The actual codebase** -- search to verify every claim the plan makes about existing infrastructure

## Execution Steps

### Phase 0: Load Context

1. Read the plan under review (user provides path)
2. Read `plan review/consolidated-plan.md` as the example/gold standard
3. Read `AGENTS.md` for workspace constraints and learned facts
4. Read `.cursor/skills/planning-guidelines/SKILL.md` for required plan structure
5. Read `.cursor/skills/logging-guidelines/SKILL.md` for logging requirements

### Phase 1: Structural Compliance (Plan vs Example)

Compare the plan section-by-section against the example. For each section in the example, check if the plan has an equivalent and whether it matches the depth. Use this checklist:

| Section | What to check |
|---|---|
| User Intent | Clear, scoped, not aspirational fluff |
| Confirmed Decisions | Each decision is actionable and justified |
| Scope Boundary | Included/Deferred are explicit and complete |
| RTM | Every requirement traces to tasks AND verification |
| Test Scenarios | P0/P1/P2 priorities, step/action/expected format |
| Downstream Impact | Every touched system is listed with specific change |
| Architecture | Diagram (not just text), component relationships |
| Key Decisions | Each has Decision + Why + Rejected alternative |
| Contract Trace | Inbound/Stored/Outbound shapes with real TS types |
| Data Model | Prisma schema, indexes, relations, migration notes |
| Phased Tasks | Files, Implementation, Success Criteria, Verification per task |
| Risks & Mitigations | Likelihood/Impact/Mitigation/Detection per risk |
| Logging Strategy | Wide event field tables per endpoint category |
| Performance & Scalability | p95 targets, caching tables, connection pooling |
| Database Performance | Index-to-query mapping, JSON column limits |
| Graceful Degradation | What happens when each dependency fails |
| Testing Strategy | TDD workflow, cross-boundary contract tests table |
| React/Next.js Practices | Dynamic imports, Suspense, error boundaries |
| Files Impact Summary | New + Modified files with purpose/change columns |
| Production-Ready Checklist | Comprehensive pre-ship verification list |

For each missing or shallow section, output a finding with line numbers.

### Phase 2: "Why, Why, Why" Interrogation

For every Key Decision, Confirmed Decision, and architectural choice, ask "why" three levels deep. The goal is to surface:

- **Unjustified decisions** -- "we decided X" with no rationale or a circular rationale
- **Decisions that contradict the codebase** -- plan says "use pattern X" when the codebase uses pattern Y everywhere
- **Decisions with unstated trade-offs** -- plan picks an approach without acknowledging what it gives up
- **Decisions that solve the wrong problem** -- plan fixes a symptom when the root cause is elsewhere
- **Decisions that are scope-creep in disguise** -- plan builds new infrastructure when existing infrastructure works

For each decision, apply this template:

```
**Line N:** [quote the decision]
- Why this approach? [push for root justification]
- Why not [the obvious alternative from the codebase]?
- What trade-off is unstated?
- Does the codebase already have this? [search to verify]
```

### Phase 3: Codebase Compliance

Search the actual codebase to verify every claim the plan makes. Key areas:

**Realtime infrastructure:**
- What channel families exist? How is routing done?
- What Durable Objects exist? What queues?
- How does `publishToWorker` work?
- How does token authorization work? What's the fallback behavior?
- Does the plan's proposed channel/routing align with existing patterns?

**Existing models and code:**
- Does the plan reference existing tables/models correctly?
- Are there existing implementations of similar features the plan ignores?
- Does the plan know about existing notification-adjacent code?

**Queue and async patterns:**
- What queues exist? (`BACKGROUND_TASKS`, `CHAT_TASKS`, `KANBAN_SYNC_QUEUE`, `PLAN_PERSISTENCE_QUEUE`, `REPORTS_QUEUE`)
- Does the plan use the established async pattern or invent a new one?
- If it deviates, does it justify the deviation?

**Conventions:**
- Cursor pagination pattern (`limit + 1`, `nextCursor`)
- Feature flag structure (`isFeatureEnabled()`)
- Provider chain order in `providers.tsx`
- Workspace layout structure
- Logging (Pino wide events, snake_case, no console.log)
- File storage (R2 via `createStorageService()`)
- RBAC model (`getEffectiveWorkspaceRoles()`)

For each codebase-contradicting claim, output a finding with line numbers.

**Critical: Vercel-to-CF constraint.** AGENTS.md states: "Vercel cannot directly enqueue to Cloudflare Queues -- CF Queue bindings are only available inside Cloudflare Workers. The Vercel app must POST to the CF Worker's HTTP endpoint, which then enqueues." Verify the plan respects this.

### Phase 4: Contract and Boundary Analysis

For every data shape that crosses a system boundary, verify:

1. The format is explicitly defined on BOTH sides
2. The plan traces the exact shape from producer to consumer
3. There's a contract test specified that uses the REAL format (not simplified test values)

Boundaries to check:
- Producer mutation -> service layer (what shape?)
- Service layer -> DB (what Prisma calls?)
- DB -> query layer -> API response (what DTO?)
- Server -> realtime event -> client hook (what event shape?)
- Client hook -> UI component (what props?)

For each untraced or ambiguous boundary, output a finding.

### Phase 5: Missing Infrastructure Analysis

Check whether the plan addresses:

- **Transaction boundaries** -- are writes in the same TX as the triggering mutation? What happens if they fail?
- **Async vs sync** -- are side-effects synchronous, fire-and-forget, or queued?
- **Fan-out strategy** -- for N recipients, is it N HTTP calls? Batched? Worker-side fan-out?
- **Dead letter / retry** -- what happens when writes fail?
- **Debouncing** -- rapid-fire events creating duplicate notifications?
- **Caching** -- frequently-hit queries cached? With what TTL and invalidation?
- **Error boundaries** -- UI components in the shell layout wrapped in error boundaries?
- **Row count projections** -- how big does the table get? When does cleanup become necessary?

### Phase 6: Security Audit

For any auth-related decision:
- Does the plan close gaps or just add a branch while leaving the root cause open?
- Are authorization checks on all read/write paths?
- Is the plan creating per-user channels without proper token authorization?
- Are there data isolation concerns (cross-workspace, cross-user)?

## Output Format

Output as a single document. Each finding must include:

1. **The exact line number(s)** from the plan file so the user can attach comments
2. **The quoted text** from the plan at that line
3. **The critique** written in "why, why, why" style -- terse, pointed, pushing for root cause
4. **What should be stated** -- the concrete fix or addition

### Format per finding:

```markdown
### [N]. [Short title]

**Line [X]:**
> [exact quote from the plan]

[Critique in why-why-why style. Terse. No filler. Push until the root justification surfaces or the gap is exposed.]

**What should be stated:** [concrete rewrite or addition]
```

### Severity levels:

- **CRITICAL** -- blocks implementation, will cause bugs or security issues
- **HIGH** -- significant gap vs example plan or codebase, needs addition
- **MEDIUM** -- missing depth, should be addressed before implementation
- **LOW** -- polish, nice-to-have, won't block

### Document structure:

```markdown
# Plan Review: [Plan Title]

## Structural Compliance (Plan vs Example)
[Table showing section-by-section comparison]

## Findings

### Critical
[findings...]

### High
[findings...]

### Medium
[findings...]

### Low
[findings...]

## Summary
[Top N actions to fix, ordered by priority]
```

## Anti-Patterns to Flag

- **Circular justification** -- "We do X because X is the right approach"
- **Vague scope** -- "optionally new file" or "may need" in a plan (plans commit, they don't hedge)
- **Phantom resolution** -- "the service resolves recipients" when the caller already resolved them
- **Branch fix for root cause** -- adding one auth check when the underlying system is permissive
- **New infrastructure ignoring existing** -- building new patterns when the codebase has established ones
- **Unstated trade-offs** -- picking an approach without acknowledging what it costs
- **Missing numbers** -- no p95 targets, no row count projections, no cache TTLs
- **Over-segmentation** -- 12 files for an MVP when 4 would do
- **Race condition bait** -- sending count hints over realtime instead of pure invalidation
