---
name: validate-implementation
description: Validate that implemented code/systems match the plan by checking git diffs, staged changes, and actual codebase. Updates plan document with completion status, fixes gaps, and ensures all requirements are met. Use after implementing features to verify completeness.
---

# Validate Implementation Against Plan

Check the attached plan and validate that the implemented code/systems were actually fully implemented as per the plan.

## Validation Methods

Use both methods to get a complete picture of what has been implemented:

1. **Check git diffs** of current changes and staged changes
2. **Check the actual code** in the codebase (read relevant files directly) since the code exists there regardless of git status

## Validation Process

Then:

1. **Update the plan document** itself to mark what's done and what's not (add status markers/comments to each task/item)
2. **Fix and implement any gaps** or missing pieces according to the plan
3. **Ensure all plan requirements** are met
4. **Report back** what gaps were found and what was fixed

Be thorough and ensure complete implementation of all plan tasks.

## Production Data Validation & Real-World Testing

**CRITICAL**: Use production database queries via MCP Supabase tools to create tests that simulate real-world scenarios:

### 1. Query Production Data

- Use `mcp_supabase_execute_sql` to query production database for real data patterns
- Identify edge cases, data anomalies, or problematic records that might have caused the issue being fixed
- Query for:
  - Records matching the bug scenario (e.g., reports with specific statuses, missing data, etc.)
  - Edge cases (null values, boundary conditions, unusual data combinations)
  - Historical problematic data patterns
- **IMPORTANT**: Sanitize/anonymize any PII or sensitive data before using in tests

### 2. Create Real-World Tests

- Generate test cases based on actual production data patterns
- Create tests in `/tests` directory using Vitest framework
- Tests should:
  - Reproduce the issue using real data structures from production
  - Validate that the fix actually resolves the issue
  - Cover edge cases found in production data
  - Use sanitized/anonymized production data as test fixtures
- Follow testing guidelines: tests must be real, never rigged to pass

### 3. Run Tests (⚠️ CRITICAL - Must Adhere to /testing-guidelines)

**ALL tests MUST adhere to `/testing-guidelines`:**
- Located in `/tests` directory at project root (not co-located with source)
- Use Vitest framework (not Jest, Mocha, or other frameworks)
- Tests must be real (never rigged to pass), validate actual behavior
- Tests must be deterministic and independent
- Run ONLY the specific test file(s) created: `vitest run tests/path/to/specific.test.ts`
- **NEVER run the entire test suite** (`npm test` or `vitest run` without file path)
- Verify tests pass with real production data patterns
- If tests fail, investigate and fix the implementation
- **MANDATORY**: All tests MUST be run and validated before marking test tasks complete

### 4. Test Creation Strategy

- **For bug fixes**: Query for records that exhibited the bug, create tests that reproduce it
- **For new features**: Query for related data patterns that should work with the feature
- **For performance fixes**: Query for data volumes/scenarios that caused performance issues
- **Always sanitize PII** (emails, names, etc.) - replace with test-safe values while preserving data structure

### 5. Example Workflow

```
- Identify what data/entities are involved in the fix
- Query production DB for relevant records: SELECT * FROM table WHERE condition LIMIT 10
- Analyze the data patterns (nulls, edge cases, relationships)
- Create test file: tests/feature/real-world-scenario.test.ts
- Use sanitized production data as test fixtures
- Write tests that reproduce the issue and validate the fix
- Run: vitest run tests/feature/real-world-scenario.test.ts
- Ensure tests pass, proving the fix works with real data patterns
```

This ensures fixes are validated against actual production scenarios, not just synthetic test data.

## Dead Code and Wiring Verification

After verifying the plan matches the diff, check for dead code and unwired integrations:

1. **Every new file/module is imported by production code** — search the codebase for imports of the new module. If only test files import it, flag as potential dead code.
2. **Every new Redux action/reducer is dispatched somewhere in production** — search for the action name in hook/component files, not just test files. A reducer that's only tested but never dispatched is dead code.
3. **Every new function export has at least one production caller** — if you create a utility function and export it, verify it's imported by the code that needs it (not just tested in isolation).
4. **New modules are used, not just defined** — creating `persisted-message.ts` with `handlePersistedMessage()` is not useful if the hook inlines the same logic instead of importing the function.

**How to check:**
```bash
# For each new file, search for its imports
rg "from.*'~/lib/kanban/persisted-message'" apps/web/src/ --type ts

# For each new Redux action, search for dispatches
rg "dispatch\(addUnconfirmedOp" apps/web/src/ --type ts

# For each new function, search for calls
rg "isValidPersistedMessage" apps/web/src/ --type ts
```

If any new export has zero production callers, either wire it in or remove it.

## Validation Checklist

For each task in the plan:

- [ ] **Code exists** - Implementation is present in the codebase
- [ ] **Matches specification** - Code does what the plan describes
- [ ] **Success criteria met** - All success criteria from the plan are satisfied
- [ ] **Tests exist** (if applicable) - Tests are in `/tests` directory using Vitest
- [ ] **Tests pass** (if applicable) - Specific test files run and pass
- [ ] **Error handling** - Errors are handled as specified in the plan
- [ ] **Logging** - Events are logged with correct fields as specified
- [ ] **Performance** - Performance requirements are met
- [ ] **Security** - Security requirements are implemented
- [ ] **Documentation** - Code is documented if required by plan

## Reporting Format

After validation, provide:

### Summary
- Total tasks in plan: X
- Fully implemented: Y
- Partially implemented: Z
- Not implemented: W

### Detailed Findings

For each task:
```
Task: [Task description]
Status: [COMPLETE|INCOMPLETE|NOT STARTED]
Issues Found:
- [List any gaps or issues]
Actions Taken:
- [What was fixed or implemented]
Verification:
- [How completeness was verified]
```

### Next Steps
- [ ] List any remaining work
- [ ] Identify blockers or dependencies
- [ ] Recommend follow-up actions

## Integration with Verifier Subagent

This skill can be run via the verifier subagent for automated validation. The verifier will:
- Check git diffs and codebase state
- Validate against plan requirements
- Update plan document with status
- Fix gaps automatically where possible
- Report findings and actions taken
