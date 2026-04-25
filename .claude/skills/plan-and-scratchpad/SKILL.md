---
name: plan-and-scratchpad
description: >-
  Definitive guide for creating, structuring, maintaining, and using PLAN.md and scratchpad.md artifacts.
  These are the two core artifacts that govern how agents plan, track progress, persist context across
  turns, and execute work autonomously. Use this skill when: starting a new planning session, creating
  or updating a plan, managing scratchpad working notes, reviewing artifact quality, onboarding new
  agents, or when unclear on artifact lifecycle, phase discipline, or structure. This skill codifies
  the exact patterns, rules, and anti-patterns that produce high-quality autonomous agent work.
---

# PLAN.md & Scratchpad — The Definitive Agent Guide

**The authoritative reference for how AI agents create, structure, maintain, and use the two core planning artifacts: `PLAN.md` and `scratchpad.md`.**

> **Status**: Comprehensive Guidelines
> **Applies To**: All agents operating in Planning, Execution, or Controller phases
> **Philosophy**: Context persistence, quality enforcement, phase discipline, and autonomous progress
> **Enforcement**: Always-applied rule at `.cursor/rules/plan-and-scratchpad.mdc`

### ⚠️ Multi-Agent Safety

This skill is enforced by an always-applied rule (`.cursor/rules/plan-and-scratchpad.mdc`) that ensures every agent uses **worktree-scoped artifact paths**, preventing parallel agents from overwriting each other's context. See section 1 for path details.

---

## Table of Contents

1. [Overview & Purpose](#1-overview--purpose)
2. [The Scratchpad — Complete Guide](#2-the-scratchpad--complete-guide)
3. [PLAN.md — Complete Guide](#3-planmd--complete-guide)
4. [Phase Discipline](#4-phase-discipline)
5. [Lifecycle Management](#5-lifecycle-management)
6. [Integration with Tools & Skills](#6-integration-with-tools--skills)
7. [Templates](#7-templates)
8. [Checklists](#8-checklists)
9. [Real-World Examples](#9-real-world-examples)
10. [Anti-Patterns Reference](#10-anti-patterns-reference)
11. [Rules from Past Mistakes](#11-rules-from-past-mistakes)

---

## 1. Overview & Purpose

### What These Artifacts Are

AI agents operate with **context resets between turns** — conversation history and local state do not persist automatically. Two artifacts solve this problem:

| Artifact | Purpose | Analogy |
|----------|---------|---------|
| **scratchpad.md** | Persistent working memory — raw research notes, current state, decisions, open questions | Engineer's personal notebook |
| **PLAN.md** | Formal implementation contract — structured plan with phases, tasks, success criteria | Technical design document / PRD |

### Where They Live

| Context | scratchpad.md Location | PLAN.md Location |
|---------|----------------------|------------------|
| **Worktree-scoped (DEFAULT)** | `.cursor/longrunning/<branch-name>/<task-slug>/scratchpad.md` | `.cursor/longrunning/<branch-name>/<task-slug>/plan.md` |
| **Grind Mode sessions** | `/opt/cursor/artifacts/scratchpad.md` | `/opt/cursor/artifacts/PLAN.md` |
| **Ralphy-compatible plans** | N/A (scratchpad is agent-internal) | `.cursor/plans/<plan-name>.plan.md` |

#### ⚠️ Worktree-Scoped Paths (Multi-Agent Safe)

**The default and recommended approach** is worktree-scoped paths plus task-scoped folders. Each agent determines its scope from the current git branch, then creates per-task artifacts under `.cursor/longrunning/<branch-name>/<task-slug>/`. This prevents multiple parallel agents from overwriting each other's context and prevents unrelated tasks from being mixed into one plan file.

```bash
# Determine your artifact directory
BRANCH=$(git branch --show-current)
# e.g., cursor/kanban-fix-abc123

# Artifacts live at:
# .cursor/longrunning/kanban-fix-abc123/fix-render-loop/scratchpad.md
# .cursor/longrunning/kanban-fix-abc123/fix-render-loop/plan.md
```

Branch scope sanitization:
- Replace `/` with `-` (example: `defect/135` -> `defect-135`)
- Replace spaces with `-`
- Use lowercase kebab-case for new branch-scope directories

The always-applied rule at `.cursor/rules/plan-and-scratchpad.mdc` enforces this pattern for all agents.

#### ⚠️ One Task, One Artifact Pair

- Every distinct task in the same branch gets a new `<task-slug>/` folder.
- Edit an existing `plan.md`/`scratchpad.md` only when the request is directly relevant to that same task.
- Never append unrelated follow-up tasks into an existing plan file.
- If uncertain whether the request is continuation or new work, default to a new `<task-slug>/` folder and add a "Related Work" link to prior artifacts.

#### ⚠️ Mandatory Similar-Task Discovery

For every new task (and before any major re-plan), you MUST review related historical tasks in `.cursor/longrunning` before drafting/updating `plan.md`.

Required behavior:
- Search `.cursor/longrunning/<branch-scope>/` first using task slug similarity, domain keywords, and overlapping file paths.
- If needed, expand to all branch scopes under `.cursor/longrunning/`.
- For each relevant match (target 1-5), read `plan.md` and `scratchpad.md` (and `test-scenarios.md` when present).
- Extract prior intent, decisions, rejected alternatives, touched files, validation outcomes, and unresolved blockers.
- Record those findings in the current scratchpad under a dedicated "Related Past Tasks" section.
- Reuse or explicitly reject prior decisions in the current plan's Context/Key Decisions/Downstream Impact sections.
- If historical context conflicts with current request, ask targeted clarifying questions before finalizing the plan.

#### ⚠️ Directory Invariants (Required)

Canonical shape:

```
.cursor/longrunning/
  <branch-scope>/
    <task-slug>/
      plan.md
      scratchpad.md
      [task-scoped artifacts]
```

Rules:
- Do not store `plan.md`/`scratchpad.md` directly under `.cursor/longrunning/<branch-scope>/`.
- Treat branch-scope folders as containers of task folders only.
- If legacy branch-root files exist, move them into `.cursor/longrunning/<branch-scope>/legacy-root-task/` before starting/continuing task work.

**Grind Mode** sessions use `/opt/cursor/artifacts/` — this is a system-managed path specific to Grind Mode and does not conflict with worktree-scoped paths since Grind Mode runs single-agent.

### How They Relate

```
┌─────────────────────────────────────────────────────────────┐
│                      PLANNING PHASE                         │
│                                                             │
│  ┌──────────────┐     informs      ┌──────────────────┐    │
│  │  Scratchpad   │ ──────────────→ │     PLAN.md       │    │
│  │              │                  │                    │    │
│  │ • Research    │                  │ • Executive Summary│    │
│  │ • File audit  │                  │ • Phases & Tasks   │    │
│  │ • Observations│                  │ • Success Criteria │    │
│  │ • Decisions   │                  │ • Testing Strategy │    │
│  │ • Questions   │                  │ • Risks            │    │
│  └──────────────┘                  └──────────────────┘    │
│                                            │                │
│                                     user approves           │
│                                            │                │
├────────────────────────────────────────────▼────────────────┤
│                     EXECUTION PHASE                         │
│                                                             │
│  ┌──────────────┐     follows      ┌──────────────────┐    │
│  │  Scratchpad   │ ←─────────────  │     PLAN.md       │    │
│  │              │                  │                    │    │
│  │ • Progress    │  tracks status   │ • Task statuses    │    │
│  │ • Discoveries │ ──────────────→ │ • Deviations noted │    │
│  │ • Blockers    │                  │ • Updated scope    │    │
│  │ • Status      │                  │                    │    │
│  └──────────────┘                  └──────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Why They Matter

1. **Context Persistence**: Without the scratchpad, every turn starts from zero. Agents lose track of what they were doing, what they learned, and what decisions they made.
2. **Quality Enforcement**: Without the plan, agents produce inconsistent work — missing edge cases, skipping tests, implementing vague requirements.
3. **Phase Discipline**: The plan enforces separation between thinking and doing. Planners don't implement; executors don't redesign.
4. **Autonomous Progress**: With both artifacts, an agent can work for hours without user intervention, maintaining context and following a clear path.
5. **Handoff Quality**: When work is complete, the artifacts provide a clear record of what was done, what was decided, and why — enabling clean handoffs.

### Prisma Migration SQL Guardrail

When database schema changes are needed:

- Never manually create SQL migration files.
- Edit the Prisma schema as the source of truth.
- Explicitly tell the user to generate Prisma migration SQL files via Prisma migration commands so Prisma does not detect migration drift.

---

## 2. The Scratchpad — Complete Guide

### 2.1 Purpose

The scratchpad is your **persistent working memory**. It survives context resets between turns. It is the ONLY mechanism you have to remember what you were doing, what you found, what you decided, and where you left off.

**Think of it as**: your personal engineering notebook that you read every morning and update every evening.

### 2.2 The Three Mandatory Rules

These are non-negotiable. Violating any of them causes context loss and wasted work.

#### ⚠️ Rule 1: READ IT AT THE START OF EVERY TURN

```
FIRST action of every turn:
  1. Determine branch: git branch --show-current
  2. Determine task slug (continuation: existing task; new request: create new slug)
  3. Read .cursor/longrunning/<branch-name>/<task-slug>/scratchpad.md
  4. If this is a new task or major re-plan, discover similar past tasks in .cursor/longrunning and capture reusable context
  5. Assess: What was I doing? Did it work? Am I stuck?
  6. Then proceed with work
```

**Why**: Your context resets between turns. The scratchpad is the ONLY way to recover your state. If you don't read it, you will repeat work, make contradictory decisions, or lose track of progress.

#### ⚠️ Rule 2: UPDATE IT BEFORE FINISHING EVERY TURN

```
LAST action of every turn (before responding):
  1. Update scratchpad with: what you did, what worked, what didn't, what's next
  2. Ensure current status is accurate
  3. Ensure any new decisions are logged with rationale
```

**Why**: The next turn (possibly a different agent instance) needs to know exactly where things stand. If you don't update, the next turn starts blind.

#### ⚠️ Rule 3: REWRITE FROM SCRATCH PERIODICALLY

```
Rewrite triggers:
  - After 3+ turns of appending
  - When notes feel stale or contradictory
  - When pivoting to a different approach
  - When starting a new phase (planning → execution)
  - When the scratchpad exceeds ~200 lines
```

**Why**: Endless appending creates drift and staleness. Old observations may no longer be accurate. Outdated hypotheses pollute decision-making. A clean rewrite forces you to summarize only what's currently true and relevant.

**How to rewrite**:
1. Read the entire current scratchpad
2. Create a new version from scratch
3. Preserve: active decisions with rationale, current status, open questions, relevant file paths
4. Drop: obsolete observations, rejected approaches, completed items, stale questions
5. Write the new version to the same file path (overwrite)

### 2.3 Structure

The scratchpad should contain these sections. Not all sections are needed every time — use what's relevant. But the **Task** and **Current Status** sections are always required.

```markdown
# Scratchpad

## Task
[One-line description of what you're working on]

## Current Status
[What phase you're in, what's done, what's in progress, what's next]
- Completed: [list]
- In Progress: [current work]
- Next: [upcoming work]
- Blocked: [if anything]

## Current Understanding
[Architecture overview, key patterns, relevant technology context]

## Relevant Files & Modules
[Files you've examined, with what you found and why they matter]
- `path/to/file.ts` (245 lines) — [what it does, why it matters]
- `path/to/other.ts` (89 lines) — [what it does, why it matters]

## Observations & Concerns
[Things you noticed — risks, edge cases, gotchas, code smells]
- [Specific observation with file path and line number]
- [Quantified concern: "6254-line router" not "large router"]

## Approach Notes
[Options you considered, tradeoffs, decisions made]
- Option A: [description] — rejected because [reason]
- Option B: [description] — chosen because [reason]

## Open Questions
[Things you don't know yet, things to verify, assumptions to validate]
- [ ] [Question with context on why it matters]
- [ ] [Question with where to look for the answer]

## Decisions Log
[Key decisions with rationale — these survive rewrites]
- **Decision**: [what you decided]
  - **Why**: [reasoning]
  - **Alternatives rejected**: [what you didn't do and why]
  - **Date/Turn**: [when]
```

### 2.4 Content Guidelines

#### Be Specific, Not Vague

```markdown
❌ BAD:
- "The file is large"
- "There are some issues"
- "Looked at the router"

✅ GOOD:
- "kanban.ts tRPC router is 6254 lines — needs splitting into logical modules"
- "3 barrel file imports from @tabler/icons-react adding ~200ms import cost"
- "Examined apps/web/src/server/api/routers/kanban.ts — 47 procedures, no rate limiting on mutations"
```

#### Include File Paths and Line Numbers

```markdown
❌ BAD:
- "Found the bug in the auth code"

✅ GOOD:
- "Bug at apps/web/src/lib/auth.ts:142 — null check missing on session.user.workspaceId"
```

#### Quantify Everything

```markdown
❌ BAD:
- "Several components need updating"
- "Performance is slow"

✅ GOOD:
- "8 components need updating (list: EditableTextCell, EditableSelectCell, ...)"
- "API response p95 is 2.3s, target is <200ms — 11.5x over budget"
```

#### Track Decisions With Rationale

```markdown
❌ BAD:
- "Using key prop pattern"

✅ GOOD:
- **Decision**: Use React key prop pattern to reset editable cell state instead of useEffect sync
  - **Why**: React docs recommend this as the canonical solution for "reset state when prop changes"
  - **Alternatives rejected**: useEffect sync (causes extra renders, sync bugs), uncontrolled components (lose validation capability)
```

### 2.5 Scratchpad During Planning vs Execution

| Phase | Scratchpad Focus |
|-------|-----------------|
| **Planning** | Research findings, architecture analysis, file audit results, pattern observations, options analysis, open questions |
| **Execution** | Progress tracking, test results, bugs found, deviations from plan, blockers, what's done vs pending |

During **planning**, the scratchpad is exploratory — you're learning the codebase and forming opinions.

During **execution**, the scratchpad is operational — you're tracking progress and recording runtime discoveries.

**When transitioning from planning to execution**, REWRITE the scratchpad. The planning-phase research notes become background context; the execution-phase status tracking becomes the primary content.

---

## 3. PLAN.md — Complete Guide

### 3.1 Purpose

PLAN.md is the **formal implementation contract** between the planning phase and the execution phase. It specifies:
- **What** will be built (tasks with exact details)
- **How** success is measured (testable criteria for every task)
- **How** it will be verified (testing strategy)
- **What** could go wrong (risks and mitigations)
- **What** files will be touched (exact paths)

The planner creates it. The executor follows it. The verifier validates against it.

### 3.2 When to Create a Plan

**Always create a plan when**:
- The task has 3+ distinct steps
- The task involves multiple files
- The task requires research or exploration first
- The task involves testing, performance, or security concerns
- The task is non-trivial and the user would benefit from reviewing the approach before implementation
- You are operating in Grind Mode (plan is mandatory)

**You may skip creating a new plan file only when there is no repository change**, for example:
- Purely informational requests ("what does this function do?")
- Clarifications or status questions in controller mode
- Explanations of existing code without edits

If any file in the repository will be modified, a plan is mandatory (including small or trivial changes).

**When in doubt, create a plan.** Over-planning is recoverable; under-planning wastes time.

### 3.2.1 Task Sizing Rubric

Use this to calibrate planning depth and execution strategy:

| Size | Typical Scope | Artifact Depth | Validation Cadence |
|------|----------------|----------------|--------------------|
| **Small** | 1-2 files, clear behavior | Quick plan + concise scratchpad | Targeted checks + final full checks |
| **Medium** | 3-8 files, moderate ambiguity | Multi-task plan with explicit verification | Targeted checks per milestone + final full checks |
| **Large** | 8+ files, cross-system impact, external APIs, new data models | Comprehensive phased plan + full supporting sections | Frequent targeted checks, full checks at major milestones and completion |

If uncertain between two sizes, choose the larger size to avoid under-specifying success criteria.

#### Required Plan Sections by Size

| Section | Small | Medium | Large |
|---------|-------|--------|-------|
| User Intent | Required | Required | Required |
| Scope Boundary (Included / Deferred) | Required (1-2 lines) | Required | Required (detailed) |
| Confirmed Decisions | If any exist | Required | Required |
| Executive Summary | Required | Required | Required |
| Context | Optional | Required | Required |
| Tasks with Success Criteria | Required | Required | Required |
| Key Decisions | Required | Required | Required (with alternatives) |
| Downstream Impact | Required | Required | Required (per-system detail) |
| Files to Modify (New/Modified/Deleted) | Required | Required | Required (categorized table) |
| Architecture Diagram | Skip | If cross-system | Required |
| Contract Trace (request/response shapes) | Skip | If API/cross-boundary | Required |
| Data Model (schema changes) | Skip | If schema changes | Required |
| Performance & Scalability Strategy | Skip | If perf-sensitive paths | Required |
| Logging Strategy (wide events table) | Skip | If new endpoints | Required |
| Graceful Degradation | Skip | Skip | Required if external deps |
| Testing Strategy | If testable | Required | Required |
| Cross-Boundary Contract Tests table | Skip | If cross-boundary | Required |
| Risks & Edge Cases | Optional | Required | Required |
| RTM (Requirements Traceability Matrix) | Skip | If 5+ requirements | Required |
| Phase-to-Scenario Mapping | Skip | Skip | Required |
| Production-Ready Checklist | Skip | Optional | Required |
| Test Scenarios (P0/P1/P2) | If behavior change | Required | Required |

### 3.3 Plan Types

#### Quick Plan (Small Tasks, 3-10 Steps)

For focused changes — a bug fix, a small feature, a refactor of 2-3 files.

```markdown
# Plan: [Descriptive Title]

## Executive Summary
[2-3 sentences: what we're doing, why, scope]

## Tasks

### Task 1: [Specific Description]
- **Files**: `path/to/file.ts`
- **Success Criteria**:
  - [Pass/fail criterion 1]
  - [Pass/fail criterion 2]
- **Verification**: [How to test]

### Task 2: [Specific Description]
...

## Files to Modify
- `path/to/file1.ts` — [what changes]
- `path/to/file2.ts` — [what changes]
```

#### Comprehensive Plan (Large Features, 10+ Steps)

For significant features, multi-phase refactors, or anything touching many files.

```markdown
# Plan: [Descriptive Title]

## Executive Summary
[2-3 sentences: what, why, scope]

## Context
[Current architecture, relevant patterns, why this matters, what exists today]

## Phase 1: [Phase Name]

### Task 1.1: [Specific Description]
- **Files**: `path/to/file.ts`
- **Success Criteria**:
  - [Exact pass/fail criterion]
  - [Exact pass/fail criterion]
- **Verification**: [How to test — command, UI check, etc.]

### Task 1.2: [Specific Description]
...

## Phase 2: [Phase Name]

### Task 2.1: [Specific Description]
...

## Testing Strategy
[What tests to write, where they go, how to run them]
- ⚠️ Reference: `@.cursor/skills/testing-guidelines`
- All tests in `/tests` directory using Vitest
- Specific test files to create: [list]
- Validation commands: `vitest run tests/path/to/specific.test.ts`

## Risks & Edge Cases
- **Risk**: [What could go wrong]
  - **Mitigation**: [How to prevent/handle it]
  - **Detection**: [How to know if it happened]

## Files to Modify
- `path/to/file1.ts` — [what changes and why]
- `path/to/file2.ts` — [what changes and why]
```

#### Long-Running Plan (Persistent Across Sessions)

For projects that span multiple sessions. Stored in the repo itself.

**Location**: `.cursor/longrunning/<project-name>/plan.md` with a companion `scratchpad.md`

**Or** for Ralphy-compatible plans: `.cursor/plans/<descriptive-name>.plan.md`

#### Ralphy-Compatible Plan (For Automated Task Execution)

Plans stored in `.cursor/plans/` use YAML frontmatter for automated task extraction:

```yaml
---
name: [Plan Title]
overview: [One paragraph description]
todos:
  - id: task-identifier
    content: [Task description]
    status: pending
  - id: another-task
    content: [Task description]
    status: pending
isProject: false
---
```

Reference: `@.cursor/skills/convert-plan-to-ralphy` for converting plans to executable Ralphy YAML tasks.

### 3.4 The Mandatory Task Format

**Every task in every plan MUST follow this format. No exceptions.**

This is enforced by `@.cursor/skills/planning-guidelines` and `@.cursor/skills/success-criteria`.

#### Required Elements

Every task MUST include:

1. **Specific implementation detail** — what to build, with exact values, exact behaviors, exact file paths
2. **Measurable outcome** — what success looks like, described in pass/fail terms
3. **Verification method** — how to test it (command to run, UI to check, log to inspect)

#### Task Structure

```markdown
### Task N.N: [Action Verb] [What] [Where]

- **Files**: `exact/path/to/file.ts` (lines X-Y if relevant)
- **Implementation**:
  - [Specific step 1 with exact values]
  - [Specific step 2 with exact values]
- **Success Criteria**:
  - "Database migration adds 'priority' column of type VARCHAR(20)" → PASS/FAIL
  - "Column has DEFAULT 'medium' constraint" → PASS/FAIL
  - "INSERT without priority value sets priority='medium'" → PASS/FAIL
- **Verification**: Run migration, insert test row, query and verify default value
```

#### ⚠️ Forbidden Terms in Tasks

These words signal vague, untestable tasks. **They are REJECTED on sight:**

| ❌ Forbidden | ✅ Replace With |
|-------------|----------------|
| "make it good" | Exact specification of what "good" means |
| "make it pretty" | Exact CSS/styling values (colors, spacing, borders) |
| "improve performance" | "Reduce p95 response time from 500ms to <200ms" |
| "add error handling" | "Catch DatabaseError, log with apiLogger.error(), return HTTP 500 with {error: 'Internal server error'}" |
| "make it work" | Exact behavior specification with inputs and outputs |
| "ensure it's reliable" | Exact retry logic, timeout values, fallback behavior |
| "follow best practices" | List the specific practices to follow |
| "optimize" | Exact metric, current value, target value |
| "enhance" | Exact feature specification |
| "better" | Exact before/after comparison |
| "clean up" | List exact changes: remove X, rename Y, extract Z |

#### Rewriting Vague Tasks — Examples

```markdown
❌ "Make the UI look better"
✅ "Change button background from #000000 to #0066CC, add 8px border-radius,
    increase padding from 8px to 12px 24px, set font-weight to 600"

❌ "Improve error handling"
✅ "Wrap all database calls in try/catch. On DatabaseError: log with
    apiLogger.error({error, operation, table}), return HTTP 503.
    On ValidationError: return HTTP 400 with {error: validation.message}.
    On unknown error: log with apiLogger.error(), return HTTP 500."

❌ "Optimize the query"
✅ "Add composite index on (workspace_id, created_at DESC) to kanban_cards table.
    Current query time: 340ms for 5000-card boards.
    Target: <50ms. Verify with EXPLAIN ANALYZE."

❌ "Add logging"
✅ "Add Pino wide-event log at function entry with fields:
    {operation: 'create_task', workspace_id, user_id, task_count, duration_ms}.
    Use apiLogger.info(). Follow snake_case field naming per logging guidelines."
```

### 3.5 Plan Sections — Detailed Guidance

#### Executive Summary

2-3 sentences maximum. Answer: What are we doing? Why? What's the scope?

```markdown
## Executive Summary
Refactor 5 editable cell components in plan-builder-v4 to eliminate useEffect
prop-to-state syncing anti-patterns. Replace with React key prop pattern per
React docs recommendation. Affects EditableTextCell, EditableSelectCell,
EditableDateCell, EditableNumberCell, and EditableNumberWithDropdown.
```

**Rules:**
- State the exact count of things being changed
- Name the specific technique/approach
- Keep to 2-3 sentences — details go in later sections

#### Context

Provide enough background for an executor who has never seen this codebase to understand WHY this plan exists and HOW the current system works.

```markdown
## Context
The plan-builder-v4 uses editable cell components for inline table editing.
Currently, 5 components sync props to local state via useEffect, which causes:
- Unnecessary re-renders on every prop change
- Potential state synchronization bugs when props update mid-edit
- Violation of React's recommended patterns (react.dev/learn/you-might-not-need-an-effect)

The fix uses React's key prop to force component remount when the data source
changes, naturally resetting state without useEffect.

Affected components are in:
apps/web/src/app/workspace/[slug]/projects/[projectId]/plan-builder-v4/components/cells/
```

**Rules:**
- Include file paths to the relevant code
- Explain the current behavior and why it's a problem
- Explain the proposed solution and why it's correct
- Link to relevant documentation/references if applicable

#### Phases & Tasks

Organize tasks into logical phases. Phases represent sequential groups — Phase 2 should not start until Phase 1 is complete (unless explicitly noted as parallelizable).

**Numbering**: Use `Phase N` → `Task N.M` format for clear referencing.

```markdown
## Phase 1: Core Cell Refactoring

### Task 1.1: Remove useEffect from EditableTextCell
...

### Task 1.2: Remove useEffect from EditableSelectCell
...

## Phase 2: Call Site Updates

### Task 2.1: Add key props in PlanTable.tsx
...
```

**Rules:**
- Each phase has a clear theme/purpose
- Tasks within a phase are ordered by dependency
- If tasks are independent, note it: "Tasks 1.1-1.4 can be done in any order"
- Never create a task without success criteria

#### Testing Strategy

**Required when the plan involves any testable changes.** Reference `@.cursor/skills/testing-guidelines`.

```markdown
## Testing Strategy

### Test Location & Framework
⚠️ All tests MUST be in `/tests` directory at project root using Vitest.

### Test Types
- **Unit Tests**: For pure logic changes (cell state management)
- **Component Tests**: For rendered component behavior
- **Integration Tests**: For end-to-end data flow

### Test Files to Create
- `tests/plan-builder/editable-cells.test.tsx` — cell remount behavior
- `tests/plan-builder/plan-table-keys.test.tsx` — key prop uniqueness

### Execution
⚠️ NEVER run entire test suite. Only run specific test files:
- `vitest run tests/plan-builder/editable-cells.test.tsx`
- `vitest run tests/plan-builder/plan-table-keys.test.tsx`

### Coverage Requirements
- All 5 cell components tested for state reset on key change
- Error cases: invalid props, undefined values
- Edge cases: rapid re-keying, empty values
```

#### Risks & Edge Cases

```markdown
## Risks & Edge Cases

### Risk 1: Key prop remount loses unsaved edits
- **Likelihood**: Medium
- **Impact**: User data loss during active editing
- **Mitigation**: Only change key when row.id changes (stable during editing).
  Add onBlur save to persist edits before potential remount.
- **Detection**: Manual test — edit a cell, trigger data refresh, verify edit is preserved

### Risk 2: Performance impact of frequent remounts
- **Likelihood**: Low
- **Impact**: Jank during rapid scrolling/filtering
- **Mitigation**: Key includes only row.id + columnKey (stable values).
  Remount only occurs when actual data source changes.
- **Detection**: Profile with React DevTools — verify no excessive mounts during scroll
```

**Rules:**
- Each risk has: likelihood, impact, mitigation, detection
- Be specific about the failure mode
- Provide concrete mitigation steps, not "be careful"

#### Files Impact Summary

For **small/medium plans**, a flat list is sufficient. For **large plans**, categorize files into New, Modified, and Deleted tables — each category carries different review risk profiles:

```markdown
## Files Impact Summary

### New Files
| File | Purpose |
|------|---------|
| `apps/web/src/server/services/foo.ts` | Shared service extracted from router |
| `tests/integration/foo.test.ts` | Integration tests for new service |

### Modified Files
| File | Change |
|------|--------|
| `apps/web/.../cells/EditableTextCell.tsx` | Remove useEffect (lines 180-185), init state from props |
| `apps/web/.../PlanTable.tsx` | Add key={`${row.id}-${columnKey}`} to all editable cell usages |

### Deleted Files
| File | Reason |
|------|--------|
| `apps/web/src/legacy/old-handler.ts` | Replaced by new shared service |
```

**Rules:**
- List every file that will be touched
- Include what changes and why for each file
- Include line numbers when known
- This list is the executor's roadmap — it should be exhaustive
- For large plans, categorize into New/Modified/Deleted — reviewers assess creation risk differently from modification risk

#### Scope Boundary

```markdown
## Scope Boundary
**Included:** external defect ingest, schema registration, partner attachment upload,
signed webhook delivery, project integration settings, defect UI support for
structured fields, /workspace/support unification (new submissions only)

**Deferred:** historical support data migration, reply and conversation sync back
to external apps, upload virus scanning, data retention policy enforcement
```

**Rules:**
- Always explicitly state what is deferred, even if "nothing"
- The deferred list prevents agents from drifting into out-of-scope work
- Reviewers use this to validate that the diff doesn't exceed stated scope
- If deferred items were previously completed, note that (e.g., "already completed separately")

#### Confirmed Decisions

```markdown
## Confirmed Decisions
- Each project's defect tracker connects to at most one external application.
  If a second app needs defect tracking, it gets its own project.
- The public HTTP API and an official TypeScript SDK ship as part of this implementation.
- Reply and conversation mirroring back to external apps is explicitly deferred.
```

**Rules:**
- Capture decisions the user stated or confirmed *before* the agent started planning
- These are constraints that the plan must respect — not suggestions to evaluate
- Distinct from Key Decisions, which the agent makes during planning with alternatives analysis
- If the user confirmed nothing specific, state: "No pre-confirmed decisions"

#### Contract Trace (cross-boundary plans)

```markdown
## Contract Trace

### Inbound: Defect Creation
REST POST /api/v1/defects
Headers: Authorization: Bearer msf_dk_...
{
  subject: string,
  external_id?: string,
  fields: Record<string, unknown>
}
→ response:
{
  id: string,
  defect_id: string,
  status: string
}
```

**Rules:**
- Required for any plan where data crosses system boundaries
- Show exact request/response shapes with example values
- Each boundary gets its own subsection
- These become the basis for cross-boundary contract tests (see Testing Strategy)
- The agent traces the exact format at BOTH ends per AGENTS.md Rule 10

#### Architecture Diagram (large / cross-system plans)

```markdown
## Architecture
[Mermaid flowchart or text diagram showing system connections,
data flow direction, and external dependencies]
```

**Rules:**
- Required for large plans and any plan touching 3+ systems
- Show data flow direction (arrows)
- Label system boundaries (Vercel, CF Worker, external)
- Include external dependencies (Redis, QStash, R2)
- A reviewer should understand the system topology from this diagram alone

#### Performance & Scalability Strategy (large plans / perf-sensitive)

```markdown
## Performance & Scalability Strategy

### Response Time Targets
| Endpoint | p95 Target | Rationale |
|----------|-----------|-----------|
| POST /api/v1/defects | <200ms | Critical ingest path |

### Caching Strategy
| Cache Target | TTL | Key Pattern | Invalidation |
|-------------|-----|-------------|-------------|
| API key verify | 5s | dk:{prefix} | On revoke via shared service |

### Graceful Degradation
- If Redis unavailable: fall back to direct DB lookup, in-memory rate limits
```

**Rules:**
- Required for plans that introduce new endpoints or touch performance-sensitive paths
- Include measurable targets (not "make it fast" but "p95 < 200ms")
- Document caching with invalidation strategy — cache without invalidation is a bug
- Document degradation behavior for each external dependency

#### Production-Ready Checklist (large plans)

Feature-specific quality checklist that reviewers and executors use to validate completeness. Unlike the generic Execution Completion Checklist (§8.4), this is tailored to the specific plan's concerns.

**Rules:**
- Required for large plans
- Each item must be specific to this feature (not generic "did you push")
- Cover: scalability, performance, reliability, caching, error handling, logging, security, database, testing
- Executor checks these items before claiming completion

#### Requirements Traceability Matrix — RTM (large plans with 5+ requirements)

For large plans, include an RTM table that traces each requirement from its source through implementation tasks to verification and test scenarios. This prevents "we implemented something that wasn't asked for" and "we forgot a requirement."

```markdown
## Requirements Traceability Matrix

| Req ID | Requirement | Source | Plan Tasks | Verification | Test Scenario IDs |
|--------|-------------|--------|-----------|-------------|-------------------|
| R01 | External defect ingest via public REST API | Scope: external defect ingest | 3.1 | Integration tests: auth, validation, creation | TS-ED-001 – TS-ED-006 |
| R02 | Field schema registration and versioning | Scope: schema registration | 2.1, 3.1, 3.2 | Schema registration tests | TS-FS-001 – TS-FS-005 |
| R03 | RBAC: only OWNER + PROGRAM_MANAGER | Confirmed: Auth/RBAC | 2.1 | Role-matrix tests | TS-IS-004 |

### Traceability Notes
- "(dev verification)" means verified by automated tests, not UI test scenarios
- Each test scenario ID maps to the test-scenarios.md artifact
```

**Rules:**
- Required for large plans with 5+ distinct requirements
- Every requirement must trace to at least one plan task AND one verification method
- Test Scenario IDs must map to the test-scenarios.md artifact
- Mark deferred requirements explicitly (strikethrough or "DEFERRED" label)
- Include a notes section explaining any non-obvious notation

#### Phase-to-Scenario Mapping (large phased plans)

For plans delivered in phases, map each phase to which test scenarios become testable when that phase lands. This coordinates QA timing — testers know when to start.

```markdown
## Phase-to-Scenario Mapping

| Phase | Ready to Test | Scenarios |
|-------|--------------|-----------|
| Phase 1: Domain Foundation | After schema + shared service land | (backend only, no UI to test yet) |
| Phase 2: Integration Management | After settings UI is complete | TS-IS-*, TS-AK-*, TS-FS-* |
| Phase 3: Public API & SDK | After REST API routes are live | TS-ED-*, TS-SC-002, TS-SC-003 |
| Phase 4: UI & Support Unification | After custom fields + support rewrite | TS-CF-*, TS-DL-*, TS-SP-* |
| Phase 5: Outbound & Realtime | After webhooks + realtime land | TS-WH-*, TS-RT-* |
| Phase 6: Rollout | After feature flags enabled | Re-run all P0 scenarios as regression |
```

**Rules:**
- Required for large plans with 3+ phases
- Each phase should list which test scenario groups become testable
- Phases with only backend changes should say "(backend only, no UI to test yet)"
- Final phase should include regression re-runs of all P0 scenarios

### 3.6 Plan Quality Standards

A plan is ready for user review when ALL of these are true:

1. **Every task has testable success criteria** with pass/fail verification
2. **No task uses vague terms** (good, better, improved, optimize, enhance)
3. **All tasks can be verified** without asking the user
4. **Success criteria are specific** (exact values, exact behaviors, exact outcomes)
5. **Success criteria are measurable** (counts, status codes, file contents, timing)
6. **File paths are exact** (not "the auth file" but `apps/web/src/lib/auth.ts`)
7. **Scope Boundary is explicit** — what's included AND what's deferred
8. **Confirmed Decisions are documented** — user-stated constraints captured before planning
9. **Testing strategy is included** if the plan involves testable changes
10. **Risks are identified** with concrete mitigations
11. **Phase ordering is logical** — no forward dependencies
12. **The plan is self-contained** — an executor can follow it without asking questions
13. **Size-appropriate sections are present** — see Task Sizing Rubric (§3.2.1) for which sections are required at each plan size

---

## 4. Phase Discipline

### 4.1 Overview

> **Identity Rule**: During each phase, you **ARE** that role. A planner who implements is broken. An executor who redesigns is broken. A controller who starts coding is broken. Treat phase violations as identity violations, not minor mistakes.

Agents operate in one of three phases. **Phase violations are serious errors.** Even if a task seems trivially simple, you must not cross phase boundaries.

| Phase | Scratchpad | PLAN.md | Code Changes |
|-------|-----------|---------|--------------|
| **Planning** | Create & populate with research | Create with full structure | ❌ FORBIDDEN |
| **Execution** | Update with progress & discoveries | Follow task by task; update if deviating | ✅ Required |
| **Controller** | Read only (for context) | Read only (for context) | ❌ FORBIDDEN |

### 4.2 Planning Phase Rules

**Goal**: Capture user intent, explore the codebase, understand the problem, create a comprehensive plan. Zero code changes.

**What you DO**:
- **Capture intent FIRST** — understand what the user wants before anything else
- **Ask clarifying questions** if the request is vague or ambiguous (see `@.cursor/skills/ask-questions-if-underspecified`)
- **Discover similar past tasks in `.cursor/longrunning` before drafting/updating the plan**
  - Branch scope first: `.cursor/longrunning/<branch-scope>/`
  - Global fallback: `.cursor/longrunning/` across branch scopes
  - Read each match's `plan.md` + `scratchpad.md` (+ `test-scenarios.md` when present)
  - Reuse decisions where valid, and log explicit rejections when not valid
  - Ask targeted follow-up questions when prior artifacts expose conflicting assumptions
- **Explore the codebase exhaustively** before creating the plan
  - Identify entry points (routes, handlers, commands)
  - Trace data flow end-to-end (input -> processing -> output/storage)
  - Catalog dependencies and downstream consumers
  - Match existing conventions by reviewing similar implementations
  - Examine test coverage and identify untested paths
  - Record findings with exact file paths and quantified observations
- Read files, search code, analyze architecture
- Write findings to scratchpad
- **Think deeply** — evaluate at least 2 approaches and document why the chosen approach is superior in Key Decisions
- **Data flow trace (mandatory for cross-boundary changes)**: When a task involves data flowing across system boundaries (client to server, worker to DO, queue to DB, or reverse), the plan MUST include a trace showing:
  - The exact data shape/keys at each boundary
  - Example values in the format the producer sends and the consumer expects
  - This trace becomes a testable contract the implementation must match
  - Example: "DO ack sends `opId: 'user1-5-1709423456789'` → client stores in `unconfirmedOps[opId]` → persisted message carries same `opId` → client deletes from `unconfirmedOps`"
- Create PLAN.md with full structure — including User Intent, Scope Boundary, Confirmed Decisions, Key Decisions, and Downstream Impact sections. For large plans, also include Contract Trace, Architecture, Data Model, Performance Strategy, Logging Strategy, and Production-Ready Checklist (see Task Sizing Rubric §3.2.1)
- Research best practices (web search if needed)
- Reference relevant skills (@.cursor/skills/*)
- **Mandatory planning cross-check**: explicitly review and apply:
  - `.cursor/skills/logging-guidelines`
  - `.cursor/skills/supabase-postgres-best-practices`
  - `.cursor/skills/vercel-react-best-practices`
  - `.cursor/commands/you-might-not-need-an-effect.md`
 - `.cursor/skills/success-criteria/SKILL.md`
- Iterate with user on plan until approved

**What you DO NOT DO**:
- ❌ Edit any file in the repository
- ❌ Run any command that modifies state (git commit, npm install, file writes) without explicit user approval
- ❌ Make "quick fixes" or "trivial changes"
- ❌ Say "this is simple enough to just do" and skip planning
- ❌ Start execution before the user approves the plan
- ❌ Proceed with ambiguous requirements without asking clarifying questions
- ❌ Skip the User Intent, Scope Boundary, or Confirmed Decisions sections in the plan

**Phase Violation Examples**:
```
❌ "Let me just fix this typo while I'm looking at the file"
   → NO. You are in planning. Note it in the plan, fix it during execution.

❌ "This is a one-line change, I'll just do it"
   → NO. Document it as a task with success criteria. Execute after approval.

❌ "I'll install this dependency now so I can check if it works"
   → NO. Note the dependency in the plan. Install during execution.
```

### 4.3 Execution Phase Rules

**Goal**: Follow the plan. Ship working code. Commit and push at logical milestones only when the user explicitly approves this task.

**What you DO**:
- **Commit the plan first** — only when user-approved: `git add .cursor/longrunning/<branch>/plan.md && git commit -m "docs: add implementation plan" && git push` — so the plan is part of the PR diff for reviewers
- Read scratchpad at turn start to recover context
- Follow plan tasks in order
- Write code, run tests, debug
- Run touched-scope validation while iterating; keep test scope proportional to changed code paths.
- Do not add broad unrelated parity test suites unless concrete bug/risk evidence links them to the current change.
- Run repo-root validation at milestone user-approved commit/push boundaries:
  - `npx turbo run typecheck`
  - `npx turbo run lint`
- Run heavy parity commands only when the touched subsystem requires them.
- Use these checks to prevent avoidable pre-commit/CI failures without blocking delivery on unrelated parity drift.
- Update scratchpad with progress and discoveries
- Use TodoWrite to track task status
- Commit and push at logical milestones (one cohesive task chunk per commit), only when explicitly requested and approved by the user
- Keep scratchpad updates frequent, but batch their commit with related implementation changes
- Avoid scratchpad-only/docs-only checkpoint commits unless docs are the primary deliverable
- Do not create standalone "execution status" or "validation status" commits between related code/test changes
- Batch code + tests + related plan/scratchpad updates into the same milestone commit whenever possible
- Update plan if deviating (document why)
- Update scratchpad before turn end
- **Mandatory pre-completion plan sync**: Before claiming any task complete:
  1. Run `git diff --stat` and confirm every changed file appears in `plan.md`
  2. Every NEW file created during implementation has a justification in the plan
  3. Every file the plan says should change IS actually changed
  4. If files diverge from the plan, update the plan FIRST, then claim complete
  This prevents the "plan describes a different PR than the actual diff" failure mode.

**What you DO NOT DO**:
- ❌ Redesign the approach mid-execution without documenting the deviation
- ❌ Skip tasks from the plan
- ❌ Add scope that wasn't in the plan (scope creep)
- ❌ Forget to commit the plan to the repo
- ❌ Forget to update scratchpad before turn end
- ❌ Batch unrelated changes into one commit
- ❌ Commit without pushing (when commit/push is approved, they should be one atomic action)

**Handling Deviations During Execution**:
```

**Handling Failures (Bounded Retries)**:
- Retry transient command/tool failures up to **2 times**
- If still failing, document attempts and failure mode in scratchpad
- Pivot to an alternative approach instead of repeating the same failing path
- Do not let one flaky operation stall the entire task
- If a heavy parity command (for example, `test:weekend-matrix-parity-cli`) times out twice, record blocker evidence and continue with fallback validation (`npx turbo run typecheck`, `npx turbo run lint`, and touched-scope checks)

#### Autonomous / Extended Execution

When working autonomously (Grind Mode, background tasks, or extended sessions with an approved plan):

- **Keep going** when the plan is clear, tasks are succeeding, and validation passes
- **Pause and check** when blockers are outside plan scope, assumptions are invalidated, or 3+ consecutive operations fail
- **Self-monitor failure streaks** and reassess direction instead of retrying the same failing path

When reality differs from the plan:
1. Note the deviation in scratchpad
2. Update PLAN.md with what changed and why
3. Continue with the adjusted approach
4. Report deviations in completion handoff

Example scratchpad entry:
  ## Deviation from Plan
  - **Plan said**: Remove useEffect from EditableTextCell (Task 1.1)
  - **Reality**: EditableTextCell also has a second useEffect for validation error
    reset (line 192) that was not in the plan
  - **Decision**: Keep the validation error useEffect — it's a legitimate side
    effect, not prop-to-state sync. Only remove the prop sync useEffect (line 180).
  - **Plan updated**: Added note to Task 1.1 clarifying which useEffect to remove
```

### 4.4 Controller Phase Rules

**Goal**: User interrupted during execution. Answer questions only. No implementation work. Resume execution when user says to continue.

**What you DO**:
- Read scratchpad and plan for context
- Answer questions about the plan, progress, codebase
- Transition back to execution when user says to continue

**What you DO NOT DO**:
- ❌ Write code
- ❌ Modify any files
- ❌ Start working on tasks
- ❌ Update the plan (unless user asks for plan changes)

#### Controller Interruption Checklist (Operational SOP)

When execution is interrupted:

1. Confirm you are now in Controller mode.
2. Answer only the user’s question(s) using current scratchpad/plan context.
3. Do not run implementation commands or edit files while in Controller mode.
4. Wait for explicit continuation intent from the user ("continue", "proceed", etc.).
5. On continuation, transition back to Execution and resume planned tasks.

### 4.5 Phase Transitions

```
Planning ──── user approves plan ────→ Execution
Execution ─── user interrupts ───────→ Controller
Controller ── user says continue ────→ Execution
Execution ─── plan complete ─────────→ Done (handoff)
```

**Critical**: The transition from Planning → Execution requires **explicit user approval**. Never self-approve.

### 4.6 Role Clarity: Planner vs Worker

For long-running or parallelized execution, keep responsibilities strict:

- **Planner role**
  - Owns objective decomposition and ordering
  - Defines clear, testable task contracts
  - Reviews handoffs and decides next tasks
  - Avoids doing implementation work directly
- **Worker role**
  - Owns one assigned task end-to-end
  - Executes within scope, records deviations, ships handoff
  - Does not coordinate laterally with other workers
  - Escalates blockers to planner via handoff notes

Even in single-agent sessions, emulate this split mentally: plan first, then execute one scoped task at a time.

---

## 4.5 Plans as Code Review Artifacts

### The Problem

AI-assisted coding has created a code review crisis. When AI writes the code:

- **Authors can't explain the "why"** — they didn't write the code, the AI did
- **Diffs show what changed, not why** — a 500-line diff tells you nothing about intent
- **AI review tools guess at intent** — they analyze code patterns but lack the original context
- **Decisions are invisible** — why was approach A chosen over B? Nobody knows.
- **Deviations are undetectable** — did the implementation match what was intended? Without a plan, there's no baseline to compare against
- **AI slop proliferates** — random refactors, unnecessary changes, unexplainable modifications

This problem gets worse as AI generates more code. The percentage of code that a human can explain drops with every passing month.

### The Solution: Commit the Plan

**The plan IS the code review artifact.** It gets committed alongside the code, referenced from the PR, and serves as the reviewable "why" behind every "what".

When a reviewer opens a PR, they see:
1. **The plan** — committed at `.cursor/longrunning/<branch-name>/<task-slug>/plan.md`
2. **The code changes** — the actual diff

The plan tells them:
- What the user originally asked for (User Intent)
- What clarifying questions were asked and answered
- What decisions were made and why (Key Decisions)
- What alternatives were considered and rejected
- What downstream systems are affected (Downstream Impact)
- What success looks like (testable criteria)
- What risks were identified and how they're mitigated

The code diff tells them whether the implementation matches the plan.

### What Reviewers Look For

When reviewing a PR with a committed plan:

| Reviewer Question | Where to Find the Answer |
|------------------|-------------------------|
| What was the user trying to achieve? | Plan → User Intent |
| What's in scope and what's not? | Plan → Scope Boundary |
| What did the user confirm upfront? | Plan → Confirmed Decisions |
| Why was this approach chosen? | Plan → Key Decisions |
| What alternatives were considered? | Plan → Key Decisions (alternatives rejected) |
| What else could this break? | Plan → Downstream Impact + Risks |
| Does the code match the intent? | Compare Plan tasks vs actual diff |
| Do data contracts match across boundaries? | Plan → Contract Trace (large plans) |
| Were any requirements missed? | Compare Plan success criteria vs implementation; RTM for large plans |
| Did the implementation deviate? | PR description → Deviations from Plan |

### The Commitment Rule

1. **Every change gets a plan** — no exceptions (even small fixes get a quick plan)
2. **The plan MUST be committed** to `.cursor/longrunning/<branch-name>/<task-slug>/plan.md`
3. **Commit the plan first** — before any implementation code, only when user-approved, so the plan is part of the PR diff
4. **If a PR is created (user-requested), reference the plan in the PR** — the PR description should link to the plan file
5. **If a PR is created (user-requested), include Key Decisions in the PR description** — top 3-5 decisions with brief rationale for quick scanning

### Benefits

- **For reviewers**: No more guessing at intent. The plan tells them exactly what was intended, why, and what decisions were made. They can validate implementation against intent.
- **For authors**: The plan serves as your "cover letter" for the PR. Even if AI wrote the code, you directed the plan.
- **For teams**: Decisions are documented. Six months from now, someone can read the plan to understand why this code exists.
- **For OSS projects**: Combat AI slop by requiring committed plans. Contributions without plans can be rejected — "show me the plan that drove this change."
- **For compliance**: Audit trail of intent → decisions → implementation for every change.

---

## 5. Lifecycle Management

### 5.1 Artifact Creation

| Event | Scratchpad Action | Plan Action |
|-------|------------------|-------------|
| **New task received** | Create new task folder, initialize scratchpad, and add "Related Past Tasks" findings from `.cursor/longrunning` | Create new task plan after related-task discovery + research are sufficient |
| **Task is trivial** | Skip (< 3 steps) | Skip (< 3 steps) |
| **Grind Mode starts** | Create at `/opt/cursor/artifacts/scratchpad.md` | Create at `/opt/cursor/artifacts/PLAN.md` |
| **Long-running project** | Create at `.cursor/longrunning/<branch-name>/<task-slug>/scratchpad.md` | Create at `.cursor/longrunning/<branch-name>/<task-slug>/plan.md` |

### 5.2 Updates During Execution

#### When to Update the Scratchpad

- **Every turn**: Read at start, update before end (mandatory)
- **After completing a task**: Update status, note what you learned
- **After hitting a blocker**: Document what's blocking and hypotheses
- **After a discovery**: Note unexpected findings (bugs, patterns, risks)
- **After a decision**: Log the decision with rationale

#### When to Update the Plan

- **Discovery changes scope**: A task is harder/different than expected
- **Approach pivot**: You found a better way to solve the problem
- **Blocker**: A task is blocked and needs to be restructured
- **New risk identified**: You found a risk not covered in the plan
- **Task was wrong**: The plan task doesn't match reality

**How to update the plan during execution**:
```markdown
### Task 1.1: Remove useEffect from EditableTextCell
- **Status**: COMPLETED (with deviation)
- **Deviation**: Found second useEffect for validation error reset (line 192).
  Kept it — it's a legitimate side effect, not prop-to-state sync.
```

#### 5.2.1 Tester Scenario Artifact (Short RTM)

For any implementation that changes user-visible behavior, create and maintain:

- `.cursor/longrunning/<branch-name>/<task-slug>/test-scenarios.md`

Requirements:
- Keep it concise (typically 8-15 scenarios).
- Use table columns: `ID`, `Priority`, `Feature`, `Steps to Test`, `Expected Result`.
- Priority levels: **P0** = blocks release, **P1** = must fix before GA, **P2** = nice to have.
- Expected results must be objectively pass/fail testable.
- Update this file when implementation scope changes.
- If there is no behavior change, add one line: `No new test scenarios required (no user-visible behavior change).`
- **Write for non-technical QA testers, not developers.** This is mandatory:
  - No code-level terms (variable names, class names, function names, database models, internal architecture terms like "WebSocket", "Durable Object", "state.sync", "hydration").
  - Steps describe user actions ("Click the toggle", "Open in another browser"), not system internals.
  - Expected results describe what the tester sees ("The toggle shows as ON"), not what the code does.
  - Include a Prerequisites section listing what the tester needs before starting.
  - If a scenario requires a developer action (e.g., server restart), phrase it as "ask a developer to..." instead of naming internal components.

### 5.3 Scratchpad Rewrite Triggers

| Trigger | Action |
|---------|--------|
| 3+ turns of appending | Full rewrite — summarize current state from scratch |
| Notes feel stale/contradictory | Full rewrite — drop obsolete info, keep active decisions |
| Pivoting approach | Full rewrite — new approach section, archive old one |
| Starting new phase (planning → execution) | Full rewrite — shift from research focus to progress tracking |
| Scratchpad exceeds ~150 lines | Full rewrite — compress and summarize |
| Returning after long gap | Full rewrite — re-verify all claims by reading current code |

### 5.4 Staleness Detection

Your scratchpad or plan is stale when:

- **File paths reference files that no longer exist or have been renamed**
- **Observations describe code that has since been changed**
- **Status says "in progress" but the work was completed turns ago**
- **Decisions reference approaches that were abandoned**
- **Questions list items that have already been answered**
- **Line numbers are wrong** (code was edited since the note was written)

**When you detect staleness**: Rewrite the scratchpad. Do not just patch individual lines — rewrite from scratch to ensure consistency.

### 5.5 Plan Completion & Handoff

When all plan tasks are complete:

1. **Update plan**: Mark all tasks as COMPLETED with final status
2. **Update scratchpad**: Write final status summary
3. **Ensure all changes are pushed**: `git status` should show clean working tree
4. **Ensure tester scenario artifact is present**: `.cursor/longrunning/<branch-name>/<task-slug>/test-scenarios.md` is updated for QA handoff
5. **Do not create or edit PRs automatically**. Only run `gh pr create` / PR body edits when the user explicitly asks.
6. **Report to user** (per agent rule #13) with:
   - What you did (exact changes, files modified, tests written)
   - A suggested PR title/body if useful for manual PR creation
   - What concerns you have (edge cases, known limitations)
   - Any deviations from the original plan (what changed and why)
   - Anything surprising you found (unexpected behavior, code patterns)
   - Exact quantities (not "several files" but "8 files modified, 3 tests added")
7. **Do NOT merge** — the user reviews and decides when/how to merge

---

## 6. Integration with Tools & Skills

### 6.1 TodoWrite Integration

Use TodoWrite to create a trackable task list from the plan. This provides real-time status tracking visible in the conversation.

```
Plan Phase 1 Tasks → TodoWrite todos (status: pending)
Start Task 1.1     → Update todo status: in_progress
Complete Task 1.1   → Update todo status: completed
```

**Rules**:
- Create todos when starting execution (from plan tasks)
- Only one todo `in_progress` at a time
- Mark complete IMMEDIATELY after finishing (don't batch)
- Add new todos if plan changes introduce new tasks
- Cancel todos if plan changes remove tasks

### 6.2 Git Integration

**Mapping plan structure to git workflow**:

| Plan Element | Git Equivalent |
|-------------|----------------|
| Plan title | Branch name / PR title |
| Phase completion | Logical commit boundary |
| Individual task | One or more commits |
| Plan completion | Handoff report to user (optional PR draft only if requested) |

**Critical git rules during execution**:
- Commit and push at logical milestones (typically one completed task chunk) only after explicit user approval
- Small commits — one logical, cohesive change per commit
- Do not create scratchpad-only checkpoint commits; include scratchpad updates with related code/test/docs work when possible
- Never commit without pushing (when commit/push is approved, they are one operation)
- Descriptive commit messages that reference what was done
- `git add -A && git commit -m "descriptive message" && git push` (only when the user explicitly asks and approves commit/push)

**Throughput-oriented validation**:
- During iterative execution, prefer targeted checks for touched scope.
- Run full-repo validation (`npx turbo run typecheck` and `npx turbo run lint`) at milestone boundaries and before final handoff.
- This preserves quality while reducing unnecessary serialization.
- During autonomous runs, pause and reassess after 3+ consecutive failures.

**On task completion**:
- Push all remaining changes only when explicitly approved by the user
- Do not run `gh pr create` unless the user explicitly requests PR creation/edits
- Report completion details to the user and include a suggested PR title/body if helpful
- Do NOT merge — user reviews and decides

### 6.3 Skill References

When creating a plan, reference relevant skills to ensure the plan accounts for all guidelines:

| Plan Involves | Reference This Skill |
|--------------|---------------------|
| Writing tests | `@.cursor/skills/testing-guidelines` |
| Adding logging | `@.cursor/skills/logging-guidelines` |
| Success criteria validation | `@.cursor/skills/success-criteria` |
| Post-execution verification | `@.cursor/skills/validate-implementation` |
| Converting plan to tasks | `@.cursor/skills/convert-plan-to-ralphy` |
| Type checking | `@.cursor/skills/check` |
| Web performance | `@.cursor/skills/chrome-devtools-mcp` |
| React/Next.js patterns | `@.cursor/skills/vercel-react-best-practices` |
| Database best practices | `@.cursor/skills/supabase-postgres-best-practices` |
| Cloudflare Workers/DOs | `@.cursor/skills/durable-objects` |
| Planning quality | `@.cursor/skills/planning-guidelines` |

Mandatory baseline for planning and implementation validation:
- `.cursor/skills/logging-guidelines`
- `.cursor/skills/supabase-postgres-best-practices`
- `.cursor/skills/vercel-react-best-practices`
- `.cursor/commands/you-might-not-need-an-effect.md`
  - `.cursor/skills/success-criteria/SKILL.md`

### 6.6 Prompting Principles for Long-Running Work

Use constraints to define boundaries, not exhaustive checklists:

- Prefer: **"No TODOs, no partial implementations, no automatic PR actions."**
- Avoid over-prescribing actions the model already knows by default.
- State intent clearly, then let the agent use judgment inside explicit constraints.
- For scope-sensitive tasks, provide concrete ranges (e.g., expected task count or milestone count) instead of vague words like "many".

### 6.7 Adapter Drift Prevention

To prevent policy divergence across model-specific entrypoints:

1. Keep `.github/copilot-instructions.md`, `AGENTS.md`, and `CLAUDE.md` as thin adapters only.
2. Do not duplicate long-form policy text in adapters.
3. Periodically scan duplicate skill trees (for example `.claude/skills/**`) for stale instructions that conflict with canonical policy.
4. Prefer replacing duplicate skill copies with pointers to canonical `.cursor/skills/*` content.

### 6.8 Codex 5.3 Extra High Prompt Profile

For Codex 5.3 Extra High, instruction quality improves when prompts are:

1. **Constraint-first**: put hard rules before optional rationale.
2. **Deterministic**: prefer explicit trigger words and pass/fail language.
3. **Non-duplicative**: avoid repeating the same policy in multiple files.
4. **Token-aware**: keep adapters concise and push detail into one canonical location.
5. **Verification-friendly**: include command-checkable assertions where possible.

Reference runbook: `docs/devtools/codex-53-extra-high-optimization.md`

### 6.4 Verifier Integration

After execution is complete, the verifier agent (`@.cursor/agents/verifier.md`) validates that the plan was fully implemented:

1. Cross-references plan requirements against actual code
2. Verifies all success criteria are met
3. Validates tests adhere to testing guidelines
4. Checks for gaps, missing features, incomplete work
5. Reports findings with specific examples

**When to invoke**: After marking all plan tasks complete, before reporting to the user.

### 6.5 Ralphy Integration

Plans in `.cursor/plans/` can be converted to executable Ralphy YAML tasks for automated sequential execution by multiple agents.

**Workflow**:
1. Create plan in `.cursor/plans/<name>.plan.md` with frontmatter
2. Convert using `@.cursor/skills/convert-plan-to-ralphy`
3. Execute: `ralphy --cursor --yaml .ralphy/tasks.yaml` (sequential, recommended)

**Plan requirements for Ralphy compatibility**:
- YAML frontmatter with name, overview, todos
- Task titles include `(File: path)` and `(Plan: section X)` references
- All implementation details in plan body (not just task titles)
- Each task is self-contained with all necessary context

---

## 7. Templates

### 7.1 Scratchpad — Quick Template

For focused, short-lived tasks:

```markdown
# Scratchpad

## Task
[One-line description]

## Current Status
- Phase: [Planning / Execution]
- Completed: [none yet / list]
- In Progress: [current work]
- Next: [upcoming]

## Key Files
- `path/to/main-file.ts` — [what and why]

## Notes
- [Observation 1]
- [Observation 2]

## Decisions
- [Decision]: [rationale]
```

### 7.2 Scratchpad — Comprehensive Template

For complex, multi-session projects:

```markdown
# Scratchpad — [Project Name]

## Task
[Description of the overall task/project]

## Current Status
- **Phase**: [Planning / Execution / Blocked]
- **Completed**:
  - [x] Task 1.1 — [brief result]
  - [x] Task 1.2 — [brief result]
- **In Progress**:
  - [ ] Task 2.1 — [what you're doing, where you left off]
- **Next**:
  - [ ] Task 2.2
  - [ ] Task 3.1
- **Blocked**: [nothing / description of blocker]

## Current Understanding

### Architecture
- [System overview relevant to the task]
- [Key patterns, technologies, constraints]

### Key Components
- `path/to/component.tsx` (N lines) — [role in system]
- `path/to/service.ts` (N lines) — [role in system]
- `path/to/router.ts` (N lines) — [role in system]

## Relevant Files Examined
- `path/to/file1.ts` — [what you found, key observations]
- `path/to/file2.ts` — [what you found, key observations]
- `path/to/file3.ts` — [what you found, key observations]

## Observations & Concerns
- [Specific observation with file:line reference]
- [Quantified concern — e.g., "6254-line file exceeds 500-line limit"]
- [Risk identified — e.g., "no rate limiting on mutation endpoints"]

## Approach Notes
- **Option A**: [description] — rejected because [reason]
- **Option B**: [description] — chosen because [reason]
- **Alternative considered**: [description] — deferred because [reason]

## Open Questions
- [ ] [Question 1 — where to look for answer]
- [ ] [Question 2 — why it matters]

## Decisions Log
- **[Date/Turn] Decision**: [what you decided]
  - Why: [reasoning]
  - Alternatives rejected: [list]

## Deviations from Plan
- **Task N.N**: [what was different from plan, what you did instead, why]
```

### 7.3 PLAN.md — Quick Template

```markdown
# Plan: [Descriptive Title]

## User Intent
[What the user asked for, in your own words. Include their motivation if stated.]

## Scope Boundary
- **Included**: [what this change covers]
- **Deferred**: [what it intentionally does NOT cover, or "Nothing — complete change"]

## Executive Summary
[2-3 sentences: what we're doing, why, scope]

## Tasks

### Task 1: [Action Verb] [What] [Where]
- **Files**: `path/to/file.ts`
- **Success Criteria**:
  - "[Exact pass/fail criterion]"
  - "[Exact pass/fail criterion]"
- **Verification**: [How to test]

### Task 2: [Action Verb] [What] [Where]
- **Files**: `path/to/file.ts`
- **Success Criteria**:
  - "[Exact pass/fail criterion]"
- **Verification**: [How to test]

## Key Decisions
- **[Decision]**: [Why this approach — what alternatives were considered and rejected]

## Downstream Impact
- [What other systems/files/features are affected, or "None — isolated change"]

## Files to Modify
- `path/to/file1.ts` — [what changes]
- `path/to/file2.ts` — [what changes]
```

### 7.4 PLAN.md — Comprehensive Template

Use the Task Sizing Rubric (§3.2.1) to determine which sections are required. Sections marked "Large only" can be skipped for small/medium plans.

```markdown
# Plan: [Descriptive Title]

## User Intent
[What the user asked for, in your own words. Include their exact words if helpful.
Capture: what they want to achieve (goal), why they want it (motivation),
any constraints they mentioned, any specific approach they requested.]

## Scope Boundary
**Included:** [Explicit list of what this plan covers]
**Deferred:** [What is intentionally NOT in scope, with brief reason for deferral]

## Confirmed Decisions
[Decisions the user stated or confirmed before planning began. These are
constraints the plan must respect — distinct from Key Decisions the agent makes.]

- [Decision]: [User's rationale or context]
- [Decision]: [User's rationale or context]
- If none: "No pre-confirmed decisions — all decisions made during planning."

## Clarifying Questions
[Questions you asked the user before planning, and their answers.
If no questions were needed, state: "Requirements were clear — no clarification needed."]

- **Q**: [Question you asked]
  **A**: [User's answer]

## Executive Summary
[2-3 sentences: what we're doing, why, exact scope — include counts]

## Context
[Current architecture, relevant patterns, why this matters]
[Key file paths and their roles]
[References to documentation or prior art]

## Architecture (Large plans / cross-system)
[Mermaid diagram or text description showing how systems connect.
Include: data flow direction, system boundaries, external dependencies.]

## Data Model (when schema changes are involved)
[Document new models, modified models, new columns, new indexes.
For Prisma: show the schema additions. For SQL: show the DDL.
This lets reviewers validate the data design before implementation.]

## Contract Trace (when crossing system boundaries)
[For each boundary crossing (client→server, API→service, webhook→partner),
document the exact data shape at both ends with example values.]

### [Boundary Name — e.g., "REST Ingest → Shared Service"]
- **Producer sends**: [exact request shape with example values]
- **Consumer expects**: [exact input shape with example values]
- **Contract test**: [what the test verifies about format agreement]

## Phase 1: [Phase Name — e.g., "Core Refactoring"]

### Task 1.1: [Action Verb] [Specific Thing] in [Specific File]
- **Files**: `exact/path/to/file.ts` (lines X-Y)
- **Implementation**:
  - [Step 1 with exact values]
  - [Step 2 with exact values]
- **Success Criteria**:
  - "[Criterion 1 — exact pass/fail check]"
  - "[Criterion 2 — exact pass/fail check]"
  - "[Criterion 3 — exact pass/fail check]"
- **Verification**: [Command to run, UI to check, or log to inspect]

### Task 1.2: [Action Verb] [Specific Thing] in [Specific File]
...

## Phase 2: [Phase Name — e.g., "Testing"]

### Task 2.1: [Write Tests for ...]
- **Files**: `tests/path/to/test-file.test.ts`
- **Implementation**:
  - [Test case 1 description]
  - [Test case 2 description]
  - [Edge case description]
- **Success Criteria**:
  - "Test file exists at tests/path/to/test-file.test.ts"
  - "Test validates [specific behavior]: expect(result).toBe(expected)"
  - "All tests pass: vitest run tests/path/to/test-file.test.ts"
- **Verification**: `vitest run tests/path/to/test-file.test.ts`
- ⚠️ MUST adhere to `@.cursor/skills/testing-guidelines`

## Key Decisions
[Top decisions made during planning. For each: what was decided, why, and what
alternatives were rejected. This section is specifically for PR reviewers —
it's the most important section for understanding "why".]

- **[Decision 1]**: [What you decided]
  - Why: [Reasoning]
  - Alternatives rejected: [What you didn't do and why]

- **[Decision 2]**: [What you decided]
  - Why: [Reasoning]
  - Alternatives rejected: [What you didn't do and why]

## Downstream Impact
[What other systems, files, features, or workflows are affected by these changes.
This helps reviewers understand the blast radius.]

- [System/feature affected]: [How it's affected]
- [System/feature affected]: [How it's affected]
- If isolated: "These changes are isolated to [scope] and do not affect other systems."

## Testing Strategy
- **Location**: All tests in `/tests` directory using Vitest
- **Types**: [Unit / Integration / Component / E2E]
- **Files to create**: [exact paths]
- **Execution**: `vitest run tests/path/to/specific.test.ts`
- ⚠️ NEVER run entire test suite
- Reference: `@.cursor/skills/testing-guidelines`

### Cross-Boundary Contract Tests (when crossing system boundaries)
[Table mapping each boundary to what the contract test must verify.
Use the REAL format from the producer, not simplified test values.]

| Boundary | Producer Format | Consumer | Contract Test |
|----------|----------------|----------|---------------|
| [e.g., REST ingest → shared service] | [exact shape] | [consuming module] | [what test verifies] |
| [e.g., webhook payload → SDK verify] | [exact shape] | [consuming module] | [what test verifies] |

## Performance & Scalability Strategy (Large plans / perf-sensitive paths)
[Response time targets, caching strategy, rate limiting, connection pooling,
graceful degradation when external dependencies fail.]

### Response Time Targets
| Endpoint | p95 Target | Rationale |
|----------|-----------|-----------|
| [endpoint] | [target] | [why this target] |

### Caching Strategy
| Cache Target | TTL | Key Pattern | Invalidation |
|-------------|-----|-------------|-------------|
| [what's cached] | [duration] | [key format] | [when/how invalidated] |

### Graceful Degradation
- **If [dependency] is unavailable**: [fallback behavior]
- **Logging**: [how failures are surfaced]

## Logging Strategy (when adding new endpoints or services)
[Wide event fields for each new endpoint/service, per logging guidelines.]

| Field | Source | Required |
|-------|--------|----------|
| [field_name] | [where it comes from] | [Yes/No/On error] |

### Tail Sampling
- **Errors (100%)**: [which error types]
- **Slow requests (100%)**: [threshold]
- **Success**: [sample rate]

### PII Redaction
- [what is redacted and how]

## Risks & Edge Cases
### Risk 1: [What Could Go Wrong]
- **Likelihood**: [Low / Medium / High]
- **Impact**: [Description of failure mode]
- **Mitigation**: [Concrete prevention steps]
- **Detection**: [How to know if it happened]

### Edge Case 1: [Description]
- **Scenario**: [When this occurs]
- **Expected Behavior**: [What should happen]
- **Test**: [How to verify]

## Files Impact Summary

### New Files
| File | Purpose |
|------|---------|
| `path/to/new-file.ts` | [why this file is needed] |

### Modified Files
| File | Change |
|------|--------|
| `path/to/existing.ts` | [what changes, why, which lines] |

### Deleted Files
| File | Reason |
|------|--------|
| `path/to/removed.ts` | [why it's being removed] |

## Production-Ready Checklist (Large plans)
[Feature-specific quality checklist. Covers the dimensions relevant to THIS plan,
not generic process steps. Check each item before claiming completion.]

- [ ] **Scalability**: [how this handles growth — e.g., "rate limits configurable per-project"]
- [ ] **Performance**: [targets met — e.g., "p95 < 200ms for ingest endpoint"]
- [ ] **Reliability**: [failure handling — e.g., "webhook retries via QStash, dead-letter after 5 attempts"]
- [ ] **Caching**: [strategy verified — e.g., "Redis cache invalidated on key revoke"]
- [ ] **Error handling**: [all catch blocks log or re-throw, no silent swallows]
- [ ] **Logging**: [Pino wide events on all new endpoints, no console.log]
- [ ] **Security**: [secrets hashed, RBAC enforced, PII redacted from logs]
- [ ] **Database**: [indexes defined, JSON columns not queried relationally, size limits enforced]
- [ ] **Testing**: [TDD red→green, contract tests, all test files pass]
- [ ] **Types**: [`npx turbo run typecheck` passes]
- [ ] **Lint**: [`npx turbo run lint` passes]

## Skill References
- `@.cursor/skills/testing-guidelines` — [why referenced]
- `@.cursor/skills/logging-guidelines` — [why referenced]
- `@.cursor/skills/planning-guidelines` — success criteria enforcement
```

### 7.5 Plan Frontmatter Template (for `.cursor/plans/`)

```yaml
---
name: [Descriptive Plan Title]
overview: >-
  [One paragraph describing what this plan achieves, the approach taken,
  and the key components affected. Be specific about counts and scope.]
todos:
  - id: [kebab-case-identifier]
    content: [Task description with enough detail to understand scope]
    status: pending
  - id: [kebab-case-identifier]
    content: [Task description]
    status: pending
  - id: [kebab-case-identifier]
    content: [Task description]
    status: pending
isProject: false
---
```

### 7.6 Tester Scenario Template (Short RTM)

Use this in:

- `.cursor/longrunning/<branch-name>/<task-slug>/test-scenarios.md`

```markdown
# Test Scenarios — [Feature Name]

## Prerequisites

- [What the tester needs: access, accounts, browsers, test data, etc.]

## Priority Key

- **P0** = blocks release — must pass before any deployment
- **P1** = must fix before GA — critical but not blocking initial deploy
- **P2** = nice to have — can ship without but should be addressed

---

| ID | Priority | Feature | Steps to Test | Expected Result |
|----|----------|---------|---------------|-----------------|
| TS-01 | P0 | [User-facing feature] | [Step-by-step user actions in plain language] | [What the tester will see — pass/fail observable] |
| TS-02 | P1 | [User-facing feature] | [Step-by-step user actions in plain language] | [What the tester will see — pass/fail observable] |
| TS-03 | P2 | [Edge case] | [Boundary condition described as user action] | [What happens — described without code terms] |

---

## Test Execution Summary

| Priority | Count | Status |
|----------|-------|--------|
| P0 | [N] | [all must pass] |
| P1 | [N] | [must pass before GA] |
| P2 | [N] | [nice to have] |
| **Total** | [N] | |
```

Guidance:
- Keep it short and handoff-ready (usually 8-15 rows).
- Assign priority to every scenario. P0 scenarios should be testable first.
- Prefer user-visible scenarios over implementation details.
- Keep wording deterministic and executable by a QA tester.
- **No code-level terms anywhere** — no variable names, class names, function names, database model names, or internal architecture jargon. A tester who has never seen the codebase must be able to follow every scenario.
- Steps must describe what to click, type, or navigate to — not what the system does internally.
- Expected results must describe what the tester will see on screen — not what the database stores or what the API returns.

---

## 8. Checklists

### 8.1 Scratchpad Pre-Update Checklist

Run this checklist before ending every turn:

- [ ] **Task** section reflects current task accurately
- [ ] **Current Status** is up to date (completed, in progress, next, blocked)
- [ ] **Related Past Tasks** section is present and updated when relevant prior work exists
- [ ] Any new **decisions** are logged with rationale
- [ ] Any new **discoveries** or observations are recorded
- [ ] Any **deviations** from the plan are documented
- [ ] Any **open questions** that were answered are marked resolved
- [ ] Any new **open questions** are added
- [ ] **File paths** are accurate (verify against actual file system)
- [ ] Content is **concise** — not endlessly appended without summarizing
- [ ] If 3+ turns since last rewrite → **trigger full rewrite**

### 8.2 Plan Pre-Finalization Checklist

Run this before presenting a plan to the user:

**Required for all plans:**
- [ ] **User Intent** documented — what the user asked for in your own words
- [ ] **Scope Boundary** is explicit — what's included AND what's deferred
- [ ] **Confirmed Decisions** captured — user-stated constraints documented before planning
- [ ] **Executive Summary** is 2-3 sentences, specific, includes counts
- [ ] **Context** explains current state and why change is needed
- [ ] **Similar-task discovery completed** in `.cursor/longrunning` (branch scope first, global fallback if needed)
- [ ] **Plan reflects prior decisions** (reused or explicitly rejected with rationale)
- [ ] **Clarifying questions asked** when prior artifacts conflict with current request
- [ ] **Every task has testable success criteria** (pass/fail, yes/no)
- [ ] **No task uses vague terms** (good, better, improved, optimize, enhance)
- [ ] **All tasks can be verified** without asking the user
- [ ] **Success criteria are specific** (exact values, exact behaviors, exact outcomes)
- [ ] **Success criteria are measurable** (counts, status codes, file contents, timing)
- [ ] **File paths are exact** — every affected file listed with what changes
- [ ] **Phase ordering is logical** — no forward dependencies
- [ ] **Testing strategy included** (if plan involves testable changes)
- [ ] **Testing strategy references** `@.cursor/skills/testing-guidelines`
- [ ] **Planning cross-check complete** for:
  - `.cursor/skills/logging-guidelines`
  - `.cursor/skills/supabase-postgres-best-practices`
  - `.cursor/skills/vercel-react-best-practices`
  - `.cursor/commands/you-might-not-need-an-effect.md`
  - `.cursor/skills/success-criteria/SKILL.md`
- [ ] **Risks identified** with likelihood, impact, mitigation, detection
- [ ] **No scope creep** — every task relates to the stated objective
- [ ] **Plan is self-contained** — executor can follow without asking questions
- [ ] **Relevant skills referenced** (testing, logging, etc.)

**Additional checks for large plans (see Task Sizing Rubric §3.2.1):**
- [ ] **Architecture diagram** included for cross-system plans
- [ ] **Contract Trace** documents exact data shapes at each boundary crossing
- [ ] **Data Model** documents schema changes with annotations
- [ ] **Cross-Boundary Contract Tests table** maps each boundary to its contract test
- [ ] **Performance Strategy** includes measurable targets, caching with invalidation, graceful degradation
- [ ] **Logging Strategy** documents wide event fields per endpoint
- [ ] **Files categorized** into New/Modified/Deleted tables
- [ ] **RTM** traces requirements → tasks → verification → test scenarios
- [ ] **Phase-to-Scenario Mapping** tells testers when to test what
- [ ] **Production-Ready Checklist** covers feature-specific quality dimensions

### 8.3 Plan Review Checklist (from planning-guidelines.mdc)

- [ ] Every task has testable success criteria (pass/fail, yes/no)
- [ ] No tasks use vague terms (good, pretty, better, improved)
- [ ] All tasks can be verified without asking the user
- [ ] Success criteria are specific (exact values, exact behaviors, exact outcomes)
- [ ] Success criteria are measurable (counts, status codes, file contents, etc.)
- [ ] If plan involves testing: Testing strategy section included
- [ ] If plan involves testing: Test tasks include validation commands
- [ ] If plan involves testing: Test tasks specify `/tests` directory and Vitest
- [ ] If plan involves performance: Performance measurement steps included
- [ ] If plan involves performance: Performance targets specified (e.g., LCP < 2.5s)
- [ ] If plan involves logging: Pino wide-event pattern specified, snake_case fields

### 8.4 Execution Completion Checklist

Run this before reporting task completion:

- [ ] **All plan tasks** are marked COMPLETED (or CANCELLED with explanation)
- [ ] **Root validation passed** — `npx turbo run typecheck` and `npx turbo run lint` at milestone/completion checkpoints; if required heavy parity is blocked after bounded retries, blocker evidence + fallback validation are documented
- [ ] **All changes committed and pushed (when user-approved)** — verify with `git status` and `git log`
- [ ] **Plan file committed to repo** — `.cursor/longrunning/<branch>/plan.md` is in the branch diff
- [ ] **Plan includes User Intent** — reviewer can understand what was requested
- [ ] **Plan includes Scope Boundary** — reviewer can see what's included vs deferred
- [ ] **Plan includes Confirmed Decisions** — reviewer can see user-stated constraints
- [ ] **Plan includes Key Decisions** — reviewer can understand why this approach was taken
- [ ] **Plan includes Downstream Impact** — reviewer can understand the blast radius
- [ ] **Size-appropriate sections present** — large plans include Contract Trace, Architecture, Performance Strategy, Production-Ready Checklist (see §3.2.1)
- [ ] **Tests written and passing** (if applicable) — specific test files run
- [ ] **Tester scenarios artifact exists** — `.cursor/longrunning/<branch>/<task-slug>/test-scenarios.md` updated (or explicit no-behavior-change note)
- [ ] **No temporary debug code** left in codebase (debug logs, hardcoded overrides)
- [ ] **No TODO comments** introduced in code
- [ ] **No stub implementations** — everything written is complete and functional
- [ ] **Scratchpad updated** with final status
- [ ] **Plan updated** with completion status on all tasks
- [ ] **Deviations documented** — every deviation from plan noted with reason
- [ ] **Implementation validation cross-check complete** for:
  - `.cursor/skills/logging-guidelines`
  - `.cursor/skills/supabase-postgres-best-practices`
  - `.cursor/skills/vercel-react-best-practices`
  - `.cursor/commands/you-might-not-need-an-effect.md`
  - `.cursor/skills/success-criteria/SKILL.md`
- [ ] **No automatic PR action taken** unless explicitly requested by the user
- [ ] **Handoff report prepared** with: what you did, concerns, deviations, surprises
- [ ] **Quantities are exact** — not "several files" but "8 files modified, 3 tests added"
- [ ] **Retry policy respected** — transient failures retried with bounds, then pivoted (no infinite loops)

---

## 9. Real-World Examples

### 9.1 Good Scratchpad Example

Based on actual patterns from `.cursor/longrunning/kanbanv5-opti/scratchpad.md`:

```markdown
# Scratchpad - KanbanV5 System Optimization

## Task
Comprehensive optimization of the KanbanV5 system spanning apps/web (Next.js),
apps/realtime-worker (Cloudflare Durable Object), and the integration layer
between KanbanV5 and PlanBuilderV4.

## Current Status
- **Phase**: Planning (research complete, drafting plan)
- **Completed**:
  - [x] Full architecture audit of kanban-v5 components
  - [x] Bundle size analysis (barrel imports, dynamic imports)
  - [x] Waterfall identification in data fetching
  - [x] Redux selector performance analysis
- **In Progress**:
  - [ ] Drafting Phase 1 (Bundle Size) plan tasks
- **Next**:
  - [ ] Draft remaining phases
  - [ ] User review

## Architecture Overview

### apps/web (Next.js)
- **Page**: `app/workspace/[slug]/kanban-v5/page.tsx` — server component, resolves boardId
- **Client**: `kanban-v5-client.tsx` (1163 lines) — My Tasks dashboard + sidebar + board routing
- **KanbanBoard**: `KanbanBoard.tsx` (1094 lines) — main board with DnD, filters, WebSocket
- **KanbanHeaderV5**: `KanbanHeaderV5.tsx` (2730 lines) — MASSIVE — filters, archive, task selector
- **Redux Store**: `store/kanban/kanban-slice.ts` (632 lines)
- **tRPC Router**: `server/api/routers/kanban.ts` (6254 lines) — MASSIVE

### apps/realtime-worker (Cloudflare Durable Object)
- **kanban-do.ts**: 3846 lines — WebSocket handling, OT, sync queue

## Critical Issues Identified (13 total)

1. **MASSIVE FILE SIZES**: 4 files over 1000 lines (max should be 500)
   - KanbanHeaderV5.tsx: 2730 lines
   - kanban.ts tRPC router: 6254 lines
   - kanban-do.ts: 3846 lines
   - KanbanColumn.tsx: 1703 lines

2. **BARREL FILE IMPORTS**: 3 libraries imported via barrel files
   - `@tabler/icons-react` — adds ~200ms import cost
   - `lucide-react` — not in optimizePackageImports
   - `@dnd-kit/core` — tree-shaking issue

3. **WATERFALL DATA FETCHING**: Sequential awaits in page.tsx
   - getProjectWithTemplate → getBoardV2 → redirect (3-step waterfall)

[...8 more issues with specific file paths and measurements...]

## Optimization Priorities (by impact)
1. Bundle size (barrel imports, dynamic imports)
2. Waterfall elimination (parallel fetching)
3. Component splitting (>500 line files)
4. Redux selector memoization
5. Server-side caching (LRU for access checks)

## Decisions Log
- **Decision**: Split optimization into 9 phases by subsystem
  - Why: Each phase is independently testable and deployable
  - Alternatives: Single massive refactor (rejected — too risky, blocks deploys)
```

**Why this is good**:
- Quantified observations (exact line counts, exact file paths)
- Clear status tracking (completed, in progress, next)
- Architecture overview for context recovery
- Prioritized list of issues
- Decisions logged with rationale

### 9.2 Bad Scratchpad Example

```markdown
# Notes

- Looked at the kanban code
- It's pretty big
- Found some issues
- Need to optimize things
- The header component is large
- Some imports could be better
- Will fix the waterfall issue
```

**Why this is bad**:
- ❌ No Task section — what are we doing?
- ❌ No Status section — what's done, what's next?
- ❌ No file paths — "the kanban code" is useless for context recovery
- ❌ No quantities — "pretty big" tells us nothing
- ❌ Vague observations — "some issues", "could be better"
- ❌ No decisions or rationale
- ❌ No structure — just a flat list of vague bullets

### 9.3 Good Plan Example

Based on actual patterns from `.cursor/plans/`:

```markdown
---
name: Fix useEffect Anti-Patterns in Plan Builder V4
overview: >-
  Remove 8 useEffect anti-patterns in plan-builder-v4: 5 prop-to-state syncing
  instances in editable cell components, 2 visual settings sync instances, and
  1 derived data computation. Uses React key prop pattern and useMemo per React
  docs recommendation.
todos:
  - id: fix-editable-text-cell
    content: Remove useEffect prop-to-state sync from EditableTextCell.tsx
    status: pending
  - id: fix-editable-select-cell
    content: Remove useEffect prop-to-state sync from EditableSelectCell.tsx
    status: pending
  # ... more todos
isProject: false
---

# Fix useEffect Anti-Patterns in Plan Builder V4

## Executive Summary
Remove 8 validated useEffect anti-patterns in plan-builder-v4: 5 instances of
prop-to-state syncing in editable cell components, 2 visual settings sync
instances, and 1 derived data computation. Uses React key prop pattern and
useMemo per react.dev/learn/you-might-not-need-an-effect.

## Context
The plan-builder-v4 uses editable cell components for inline table editing.
5 components sync props to local state via useEffect, causing unnecessary
re-renders and potential state sync bugs.

Affected files are in:
apps/web/src/app/workspace/[slug]/projects/[projectId]/plan-builder-v4/components/cells/

## Phase 1: Core Cell Refactoring

### Task 1.1: Remove useEffect from EditableTextCell
- **Files**: `.../cells/EditableTextCell.tsx` (lines 180-185)
- **Implementation**:
  - Remove useEffect that syncs `value` prop to `localValue` state
  - Initialize useState directly from prop: `useState(value)`
  - Keep validation error reset useEffect (line 192) — it's a legitimate side effect
- **Success Criteria**:
  - "useEffect at lines 180-185 is removed"
  - "useState is initialized from prop value directly"
  - "Component renders correctly with initial prop value"
  - "Component resets state when key prop changes (tested via PlanTable)"
- **Verification**: `vitest run tests/plan-builder/editable-cells.test.tsx`

[...more tasks with same level of detail...]
```

**Why this is good**:
- ✅ Exact count in summary (8 anti-patterns, 5+2+1)
- ✅ References to documentation (react.dev link)
- ✅ Every task has file paths with line numbers
- ✅ Every task has implementation steps with exact actions
- ✅ Every task has pass/fail success criteria
- ✅ Verification method specified for each task
- ✅ Frontmatter enables Ralphy conversion

### 9.4 Bad Plan Example

```markdown
# Plan: Fix some issues

## What to do
- Clean up the cell components
- Make the effects better
- Improve how state is handled
- Add some tests
- Make it more performant

## Notes
- The components have some problems
- React says to avoid effects for certain things
- Should probably use memoization somewhere
```

**Why this is bad**:
- ❌ Vague title ("some issues")
- ❌ No executive summary
- ❌ No context section
- ❌ No file paths anywhere
- ❌ Every task uses forbidden vague terms ("clean up", "better", "improve")
- ❌ No success criteria on any task
- ❌ No verification methods
- ❌ No testing strategy
- ❌ No risks section
- ❌ No files to modify list
- ❌ "Should probably" indicates uncertainty — decisions not made
- ❌ An executor cannot follow this plan without asking many questions

---

## 10. Anti-Patterns Reference

### 10.1 Scratchpad Anti-Patterns

| # | ❌ Anti-Pattern | ✅ Correct Pattern |
|---|----------------|-------------------|
| S1 | **Endlessly appending** without summarizing — scratchpad grows to 500+ lines of accumulated notes | **Rewrite from scratch** every 3+ turns — summarize current state, drop obsolete notes |
| S2 | **Forgetting to read** scratchpad at turn start — losing all context from previous turns | **First action of every turn**: read scratchpad, assess state, then proceed |
| S3 | **Forgetting to update** before turn end — next turn has stale information | **Last action of every turn**: update scratchpad with progress, discoveries, decisions |
| S4 | **Storing stale information** — file paths or observations that are no longer accurate | **Verify claims** against actual code when rewriting — delete anything outdated |
| S5 | **Missing file paths** — "the auth code" instead of `apps/web/src/lib/auth.ts:142` | **Always include exact file paths** and line numbers when referencing code |
| S6 | **Vague observations** — "the file is large" | **Quantify everything** — "kanban.ts is 6254 lines, exceeding 500-line limit by 12.5x" |
| S7 | **No status tracking** — no way to tell what's done vs pending | **Always maintain Current Status** section with completed/in-progress/next/blocked |
| S8 | **No decisions log** — decisions made but rationale not recorded | **Log every non-trivial decision** with: what, why, alternatives rejected |
| S9 | **Mixing phases** — execution progress notes mixed with planning research | **Rewrite when transitioning phases** — shift from research focus to progress tracking |
| S10 | **No deviation tracking** — deviations from plan not recorded | **Document every deviation** with: plan said X, reality is Y, decided to do Z because W |

### 10.2 Plan Anti-Patterns

| # | ❌ Anti-Pattern | ✅ Correct Pattern |
|---|----------------|-------------------|
| P1 | **Vague tasks** — "improve error handling" | **Specific tasks** — "Catch DatabaseError, log with apiLogger.error(), return HTTP 503" |
| P2 | **Missing success criteria** — tasks with no way to verify completion | **Every task has pass/fail criteria** — "Column has DEFAULT 'medium' constraint" → PASS/FAIL |
| P3 | **Missing verification methods** — criteria exist but no way to test them | **Every task has a verification method** — command, UI check, log inspection |
| P4 | **Scope creep** — adding tasks unrelated to the stated objective | **Every task traces back** to the executive summary objective |
| P5 | **Implementing during planning** — "let me just fix this while I'm here" | **Zero code changes during planning** — note it as a task, implement during execution |
| P6 | **No testing strategy** — plan involves testable changes but no test plan | **Include testing strategy** section referencing `@.cursor/skills/testing-guidelines` |
| P7 | **Missing file paths** — "update the component" instead of exact path | **Exact file paths** in every task: `apps/web/src/components/kanban/KanbanBoard.tsx` |
| P8 | **Forward dependencies** — Phase 2 depends on Phase 3 results | **Logical ordering** — each phase depends only on prior phases |
| P9 | **Tasks requiring human judgment** — "make sure it looks good" | **Objectively verifiable tasks** — "button background is #0066CC, border-radius is 8px" |
| P10 | **Starting before approval** — executing plan before user says "go ahead" | **Wait for explicit approval** — Planning → Execution transition requires user confirmation |
| P11 | **Forbidden terms** — using "optimize", "enhance", "better", "clean up" | **Specific terms** — exact metrics, exact values, exact before/after states |
| P12 | **No risks section** — pretending nothing could go wrong | **Identify risks** with likelihood, impact, mitigation, and detection |
| P13 | **Monolithic tasks** — single task covering 500+ lines of changes across 10 files | **Break into focused tasks** — each task is one logical change, ideally in 1-3 files |
| P14 | **No context section** — executor doesn't understand why this plan exists | **Context section** explains current state, why change is needed, approach rationale |
| P15 | **Missing files-to-modify list** — no roadmap of what will be touched | **Exhaustive file list** — every file that will be changed, with what changes and why |
| P16 | **Not committing the plan** — PR has no reviewable intent artifact | **Commit the plan first** — `git add .cursor/longrunning/<branch>/<task-slug>/plan.md` before implementation only after user approval |
| P17 | **Missing User Intent section** — reviewer can't tell what was requested | **Always include User Intent** — what the user asked for, in your own words |
| P18 | **Missing Key Decisions** — reviewer can't tell why this approach was taken | **Always include Key Decisions** — what was decided, why, alternatives rejected |
| P19 | **Proceeding on ambiguous requirements** — guessing instead of asking | **Ask clarifying questions first** — see `@.cursor/skills/ask-questions-if-underspecified` |
| P20 | **PR description without plan reference** — reviewer has to hunt for context | **Link the plan in the PR** — include path to committed plan file in PR body |
| P21 | **Missing Scope Boundary** — agent drifts into deferred work or reviewer can't tell what was intentionally excluded | **Always include Scope Boundary** — explicit Included/Deferred lists prevent drift |
| P22 | **Missing Confirmed Decisions** — agent re-evaluates decisions the user already confirmed | **Capture Confirmed Decisions** separately from Key Decisions — user constraints are not suggestions |
| P23 | **Flat file list for large plans** — no distinction between new and modified files | **Categorize files** into New/Modified/Deleted tables — each carries different review risk |
| P24 | **Missing Contract Trace for cross-boundary plans** — data format mismatches cause production bugs | **Document exact data shapes** at both ends of every boundary crossing (AGENTS.md Rule 10) |
| P25 | **No Production-Ready Checklist for large plans** — feature-specific quality dimensions unchecked | **Include feature-specific checklist** covering scalability, performance, caching, security, etc. |

---

## 11. Rules from Past Mistakes

These rules were learned from real failures. Each captures a pattern that has caused problems and the corrective behavior that prevents recurrence.

### Rule 1: Never Endlessly Append to the Scratchpad

**What went wrong**: Agent accumulated 400+ lines of notes over 8 turns. Notes contradicted each other. Agent followed an obsolete approach from turn 2 that was superseded in turn 5 but never removed.

**The rule**: Rewrite the scratchpad from scratch every 3 turns or when it exceeds ~200 lines. A clean, current summary beats a comprehensive but stale history.

*Cross-reference: Agent Rule #5 — "Rewrite your working notes from scratch periodically."*

### Rule 2: Never Skip Reading the Scratchpad

**What went wrong**: Agent started a turn without reading the scratchpad. Spent 15 minutes re-discovering information that was already recorded. Made a decision that contradicted a decision from the previous turn.

**The rule**: The FIRST action of every turn is reading the scratchpad. No exceptions. This is how you recover context.

### Rule 3: Never Implement During Planning

**What went wrong**: Agent found a "trivial" bug during planning and fixed it. The fix introduced a regression. The regression was discovered during execution, causing confusion about whether it was a pre-existing issue or caused by the planned changes.

**The rule**: During planning, make ZERO code changes. Document everything as plan tasks. Implement during execution.

*Cross-reference: Phase Discipline — "A planner who implements is broken."*

### Rule 4: Never Use Vague Terms in Plan Tasks

**What went wrong**: Plan task said "improve error handling." Three different agents interpreted this differently. One added try/catch blocks. Another added error boundaries. A third added logging. None of them did what the user wanted, which was specific HTTP error codes.

**The rule**: Every plan task must be specific enough that any agent would implement it the same way. Use exact values, exact behaviors, exact file paths.

*Cross-reference: Agent Rule #8 — "Prefer constraints over aspirations."*

### Rule 5: Never Commit Without Pushing

**What went wrong**: Agent committed 4 changes locally but didn't push. Session ended. All work was lost. The commits existed only on the ephemeral VM.

**The rule**: `git commit` and `git push` are one atomic operation. Never do one without the other. `git add -A && git commit -m "message" && git push` — always, and only with explicit user approval.

### Rule 6: Never Claim Premature Completion

**What went wrong**: Agent reported "all tasks complete" but 2 tests were failing and one component had a TypeScript error. User discovered the failures during review.

**The rule**: Run the execution completion checklist before reporting. If tests fail, code doesn't compile, or requirements aren't met, you are NOT done. Keep working.

*Cross-reference: Agent Rule #2 — "Never claim premature completion."*

### Rule 7: Never Make Decisions Without Logging Rationale

**What went wrong**: Agent chose approach A over approach B during turn 3. By turn 7, agent forgot why and second-guessed the decision, wasting time re-evaluating options that had already been considered and rejected.

**The rule**: Every non-trivial decision goes in the scratchpad Decisions Log with: what you decided, why, and what alternatives were rejected.

*Cross-reference: Agent Rule #6 — "Challenge your own assumptions continuously."*

### Rule 8: Never Leave the Scratchpad Without a Status Section

**What went wrong**: Agent was interrupted mid-task. Next turn, agent read the scratchpad but couldn't determine what was done, what was in progress, or what was next. Spent significant time reconstructing the state by reading git history.

**The rule**: The **Current Status** section is mandatory. It must always reflect: what's completed, what's in progress, what's next, and what's blocked.

### Rule 9: Never Add Scope During Execution Without Documentation

**What went wrong**: Agent noticed an unrelated issue during execution and fixed it without updating the plan. The fix conflicted with another agent's work on a different branch. The merge conflict was traced back to an undocumented scope addition.

**The rule**: If you must add scope during execution, update both the plan (new task with criteria) and the scratchpad (deviation log). But strongly prefer staying in scope — trust that other issues will be handled separately.

*Cross-reference: Agent Rule #1 — "You own only your assigned task."*

### Rule 10: Never Create Plans Without a Files-to-Modify List

**What went wrong**: Plan had detailed tasks but no consolidated list of files. Agent modified 12 files. A 13th file that should have been updated was missed because it wasn't explicitly listed. The omission caused a runtime error in production.

**The rule**: Every plan ends with an exhaustive **Files to Modify** section. This list is the executor's roadmap. If a file isn't listed, it shouldn't be touched. If it should be touched, it must be listed.

### Rule 11: Never Skip the Testing Strategy for Testable Changes

**What went wrong**: Plan involved modifying 5 components. No testing strategy was included. Agent wrote the code but no tests. A regression was introduced that would have been caught by even basic component tests.

**The rule**: If the plan involves testable changes (which is nearly always), include a Testing Strategy section. Reference `@.cursor/skills/testing-guidelines`. Specify test file paths, test types, and execution commands.

### Rule 12: Always Quantify, Never Approximate

**What went wrong**: Scratchpad said "several files need updating." During execution, agent updated 3 files. Actually 7 needed updating. The vague "several" hid the true scope.

**The rule**: Use exact numbers everywhere. "7 files need updating: [list them]." "3 anti-patterns found in EditableTextCell (lines 180, 192, 205)."

*Cross-reference: Agent Rule #14 — "Be specific with quantities."*

---

## Summary

### The 5 Non-Negotiable Rules

1. **Read scratchpad at the start of every turn** — context recovery is mandatory
2. **Update scratchpad before the end of every turn** — future turns depend on it
3. **Rewrite scratchpad from scratch periodically** — prevent drift and staleness
4. **Every plan task has testable success criteria** — no vague, no subjective, no human judgment required
5. **Never cross phase boundaries** — planners don't implement, executors don't redesign, controllers don't code

### Quick Reference

| Question | Answer |
|----------|--------|
| Where do artifacts live? | `.cursor/longrunning/<branch-name>/<task-slug>/scratchpad.md` and `plan.md` (default) or `/opt/cursor/artifacts/` (Grind Mode) |
| How to determine scope? | `git branch --show-current` → use branch name as directory under `.cursor/longrunning/` |
| Must similar past tasks be reviewed first? | Yes — scan `.cursor/longrunning` (branch scope first), record reusable decisions, and ask follow-up questions when context conflicts |
| What validation must run before commit/push? | Touched-scope checks while iterating; `npx turbo run typecheck` + `npx turbo run lint` at user-approved milestones; heavy parity only when subsystem-relevant |
| When to rewrite scratchpad? | Every 3+ turns, >200 lines, phase transition, stale data, pivot |
| When to create a plan? | 3+ step tasks, multi-file changes, non-trivial work, Grind Mode |
| What makes a task valid? | Specific implementation + measurable outcome + verification method |
| What terms are forbidden? | good, better, improved, optimize, enhance, clean up, make it work |
| What's the commit rule? | `git add -A && git commit -m "msg" && git push` — always together, milestone-based, batch code+tests(+docs), avoid status-only docs checkpoint commits; only when explicitly requested and approved by the user |
| What must every plan include? | User Intent, Scope Boundary, Confirmed Decisions, Key Decisions, Downstream Impact. Large plans add: Contract Trace, Architecture, Data Model, Performance Strategy, Production-Ready Checklist (see §3.2.1) |
| Where should QA scenarios live? | `.cursor/longrunning/<branch-name>/<task-slug>/test-scenarios.md` (short RTM with P0/P1/P2 priority, pass/fail expected results) |
| What is Phase Identity? | You ARE the role. Planner != executor != controller. Do not cross boundaries. |
| When to pause autonomous runs? | After 3+ consecutive failures or when blocker is outside plan scope. |
| What to do on completion? | Push all changes only when explicitly requested and approved by the user, report to user, and only create/edit PRs when explicitly requested |
| Is there an enforcing rule? | Yes — `.cursor/rules/plan-and-scratchpad.mdc` (alwaysApply: true) |

**Remember**: These artifacts are the foundation of autonomous agent work. A well-maintained scratchpad and a high-quality plan enable hours of productive, independent work. A neglected scratchpad and a vague plan produce confusion, wasted effort, and incomplete results.
