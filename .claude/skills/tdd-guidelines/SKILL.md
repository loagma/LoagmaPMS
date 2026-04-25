---
name: tdd-guidelines
description: Enforces strict test-first development with mandatory failing-before-passing test cycles. Use when implementing behavior changes, not for pure docs/review tasks. Applies alongside /plan-and-scratchpad and @.cursor/rules/plan-and-scratchpad.mdc.
---

# TDD Guidelines

## Purpose

This skill enforces a strict, evidence-driven test-driven workflow for implementation work. It makes "tests passing" only a downstream confirmation, never the starting assumption.

## When to use this skill

- You are about to write or modify implementation code (application logic, UI behavior, API behavior, data paths).
- You are making changes that can be validated by automated behavior tests.
- The work request is adjacent to `/plan-and-scratchpad` execution and requires test-backed success criteria.

## Hard rules

- Tests for each new behavior MUST be written first.
- Those tests MUST fail in the current state.
- No implementation change for that behavior is considered done until at least one test has failed and then passed after the implementation change.
- If no test can be made to fail, the behavior is not implemented with enough specificity and must be decomposed further.
- If a test suite contains unrelated changes, split and run only the minimum targeted scope.
- Do not run a full test suite during local implementation cycles.
- Treat any test that always passes as a failure of the test design.
- Every test case must include concrete pass/fail assertions (no `expect(true)`-style assertions).
- Never mock the function/class being tested.

## Cross-boundary contract tests

When a data flow crosses system boundaries (client to server, server to queue, queue to DB, or reverse), the standard unit-test-only approach is insufficient. Identifiers, keys, and data shapes can silently mismatch across boundaries, passing all unit tests while failing in production.

**Hard rules for cross-boundary changes:**

- Before implementation, trace the exact data format at BOTH ends of every boundary the change touches. Record the formats in the scratchpad.
- Write at least one contract test that uses the REAL format from the producer, not a simplified test value. If the server generates `userId-clientSeq-timestamp`, the test must use that format — not `userId-clientSeq`.
- If the implementation depends on an identifier from another system (opId, clientSeq, sessionId, etc.), the test must assert the format the consumer expects matches the format the producer actually sends.
- Contract tests MUST import from the production modules on both sides of the boundary (or reproduce the exact production format). Tests that define their own simplified format will pass but hide mismatches.

**Example — how this prevents bugs:**

```
BAD:  Client test uses opId = "user1-5"
      Server generates opId = "user1-5-1709423456789"
      Test passes. Production: keys never match. Silent accumulation bug.

GOOD: Client test uses opId = "user1-5-1709423456789" (actual server format)
      If client code strips the timestamp, the test FAILS immediately.
```

**When this applies:**
- Any change where one system produces a key/ID and another system consumes it
- Any change to WebSocket message formats, API request/response shapes, or queue payloads
- Any change where Redux state is keyed by an identifier that comes from a server message

## Required workflow

1. Plan
   - Confirm implementation tasks in `PLAN.md` include testable pass/fail success criteria.
   - Identify the exact behaviors to implement and map one or more assertions to each.
2. Write failing tests first
   - Add/modify tests for the target behavior in `/tests` and run only those files.
   - Assert real behavior with concrete input/output and side effects.
3. Verify red
   - Run targeted test command and record that tests fail.
4. Implement minimal change
   - Edit production code only enough to address the failing test(s).
5. Verify green
   - Re-run the same targeted test files and confirm they pass.
6. Hardening checks
   - Add edge/error cases in the same targeted scope.
   - Keep failing+passing transitions reproducible.

## Test execution rules

- For local implementation cycles, run only specific files: `vitest run tests/path/to/changed-behavior.test.ts`.
- Never run full suite commands (`npm test`, `vitest run` without file path, `npx turbo run test` without path).
- Run at least:
  - `vitest run tests/<relevant-scope>/<file>.test.ts`
  - `vitest run tests/<relevant-scope>/**/*.test.ts` only if needed for tightly related edge cases
- Keep tests in `/tests` and use Vitest, as required by repo testing guidance.

## TDD acceptance checklist

Use this checklist before claiming a task is complete:
- [ ] I identified concrete behavior to test in plan tasks.
- [ ] I ran targeted tests before implementation and observed failure.
- [ ] I implemented only after red was observed.
- [ ] I reran the same tests and confirmed green.
- [ ] I added at least one edge/error assertion.
- [ ] Assertions are behavior-based and non-rigged.
- [ ] I did not run an unrelated full test suite.
- [ ] Every new export (function, type, reducer, action) is imported by at least one production file.
- [ ] If the change crosses system boundaries, I traced the data format at both ends and wrote a contract assertion using the real producer format.

## Subagent delegation rules

When delegating behavior-change implementation to subagents (Task tool):

- The delegation prompt MUST include TDD requirements: "Write failing tests first in the appropriate test file, verify red state, then implement minimal change, verify green state."
- The delegation prompt MUST specify test file paths and test execution commands.
- The parent agent MUST verify TDD evidence (red→green) in subagent output before marking the task complete.
- If the subagent returns without TDD evidence for a behavior change, the parent agent must either run the TDD cycle itself or re-delegate with explicit TDD instructions.

## Cross-document alignment

- Must be used with `/testing-guidelines`.
- Must be used with `/plan-and-scratchpad`.
- Must be consistent with `@.cursor/rules/plan-and-scratchpad.mdc`.
- When invoking this skill for execution tasks, align task success criteria to real, behavior-based assertions only.
- This skill is referenced in the mandatory planning cross-check list in `@.cursor/rules/plan-and-scratchpad.mdc` (for tasks involving behavior changes).
