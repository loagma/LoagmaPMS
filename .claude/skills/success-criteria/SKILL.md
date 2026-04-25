---
name: success-criteria
description: Validate that every task in a plan has clear, testable success criteria with pass/fail verification. Ensures AI can determine completion without asking the user. Use when reviewing or creating plans to ensure completeness.
---

# Validate Testable Success Criteria

**CRITICAL**: Every task in every plan MUST have clear, testable success criteria. The AI implementing the plan needs to know EXACTLY when each task is complete without asking you.

**⚠️ ACTION REQUIRED**: When validating a plan, you MUST directly edit the plan file to add missing success_criteria and fix vague tasks. Do NOT just report findings - make the changes directly in the plan document.

## Validation Process

When reviewing or creating a plan, check EVERY task and ensure:

### 1. Every Task Has Success Criteria

- ✅ Each task includes specific, measurable outcomes
- ✅ Each task can be verified with a pass/fail or yes/no check
- ✅ Success criteria are written as testable assertions

### 2. Criteria Format Requirements

**Required Elements:**
- Specific implementation detail (what to build)
- Measurable outcome (what success looks like)
- Verification method (how to test it)

**Example Good Format:**
```markdown
- id: add-priority-column
  content: Add priority column to users table with default value 'medium'
  status: pending
  success_criteria:
    - "Database migration adds 'priority' column of type VARCHAR(20)"
    - "Column has DEFAULT 'medium' constraint"
    - "Migration runs without errors"
    - "Existing rows have priority='medium' after migration"
    - "INSERT without priority value sets priority='medium'"
```

### 3. Identify and Fix Vague Tasks

**Look for these RED FLAGS (must be rewritten):**
- ❌ "make it good"
- ❌ "make it pretty"
- ❌ "improve performance"
- ❌ "add error handling" (without specifics)
- ❌ "make it work"
- ❌ "ensure it's reliable"
- ❌ "follow best practices"
- ❌ "optimize"
- ❌ "enhance"
- ❌ "better"
- ❌ "improved"

**Rewrite Strategy:**
- Replace vague terms with specific values
- Replace subjective judgments with measurable outcomes
- Replace general statements with exact behaviors

**Examples of Rewriting:**

❌ "Make the UI look better"
→ ✅ "Change button background color from #000000 to #0066CC, button text from white to white, add 8px border-radius"

❌ "Improve error handling"
→ ✅ "Catch all database errors, log with apiLogger.error(), return HTTP 500 with JSON body {error: 'Internal server error'}"

❌ "Optimize performance"
→ ✅ "Reduce API response time from 500ms to <200ms for 95th percentile, add database index on users.email column"

### 4. Verification Checklist

For each task, verify:

- [ ] **Specific**: Uses exact values, not relative terms (e.g., "HTTP 200" not "success")
- [ ] **Measurable**: Can be verified programmatically or through clear manual steps
- [ ] **Testable**: Has clear pass/fail condition
- [ ] **Complete**: Includes all necessary details (status codes, field names, file paths, etc.)
- [ ] **Independent**: Can be verified without human judgment
- [ ] **For test tasks**: Includes testing guidelines adherence (`⚠️ MUST adhere to /testing-guidelines`)
- [ ] **For test tasks**: Specifies test location (`/tests` directory at project root)
- [ ] **For test tasks**: Specifies framework (Vitest, not Jest/Mocha)
- [ ] **For test tasks**: Includes validation command (`vitest run tests/path/to/specific.test.ts`)
- [ ] **For test tasks**: States tests must be real (never rigged), validate actual behavior

### 5. Common Patterns for Good Success Criteria

**API Endpoints:**
- ✅ "POST /api/users returns HTTP 200 with JSON body containing user_id field"
- ✅ "Request with invalid data returns HTTP 400 with error message"

**Database Changes:**
- ✅ "Migration adds 'status' column of type VARCHAR(50) with DEFAULT 'pending'"
- ✅ "Query returns results ordered by created_at DESC"

**UI Components:**
- ✅ "Button displays text 'Submit' and calls onSubmit prop when clicked"
- ✅ "Dropdown shows 4 options: 'all', 'high', 'medium', 'low'"

**File Operations:**
- ✅ "ZIP file contains all files from folder, filenames match originals"
- ✅ "Downloaded file has Content-Type: application/pdf"

**Rate Limiting:**
- ✅ "10th request returns HTTP 200, 11th request returns HTTP 429"
- ✅ "Rate limit headers include X-RateLimit-Remaining and X-RateLimit-Reset"

**Logging:**
- ✅ "All errors logged with apiLogger.error() including schema_version: '1.0.0'"
- ✅ "Log events include snake_case fields: user_id, workspace_id, file_count"

**Testing (⚠️ CRITICAL - Must Adhere to /testing-guidelines):**
- ✅ "Unit test file created at tests/unit/auth/account-linking.test.ts using Vitest framework"
- ✅ "Test validates actual behavior: expect(autoLinkBlocked).toBe(true), not expect(true).toBe(true)"
- ✅ "Test run and validated: vitest run tests/unit/auth/account-linking.test.ts returns all tests passing"
- ✅ "Test located in /tests directory at project root (not co-located with source)"
- ✅ "Test uses Vitest framework (not Jest, Mocha, or other frameworks)"
- ✅ "Test is deterministic: same inputs produce same outputs, no flaky behavior"
- ✅ "Test is independent: can run in isolation, doesn't depend on other tests"
- ❌ "Test created" (vague - doesn't specify location, framework, or validation)
- ❌ "Tests pass" (vague - doesn't specify which tests or how to run them)

### 6. Action Items

**⚠️ CRITICAL: You MUST directly edit the plan file. Do NOT just report findings.**

When validating a plan:

1. **Read the plan file** - Load the entire plan document
2. **Read through EVERY task** in the plan (check todos section and all implementation sections)
3. **For each task missing success_criteria**:
   - Add a `success_criteria` array with specific, testable criteria
   - Use the format shown in section 2 above
   - Edit the plan file directly using search_replace or write tools
4. **For each vague task**:
   - Rewrite the task content to be specific and measurable
   - Add or update success_criteria with testable assertions
   - Edit the plan file directly
5. **For tasks with existing success_criteria**:
   - Verify each criterion is testable (pass/fail, yes/no)
   - If any criterion is vague, rewrite it to be specific
   - Edit the plan file directly
6. **Update ALL sections** - Don't just update todos, also update implementation sections that describe tasks
7. **Save changes** - The plan file should be updated with all corrections

**DO NOT:**
- ❌ Just list what needs to be fixed
- ❌ Ask the user what to do
- ❌ Report findings without making changes
- ❌ Leave vague tasks unchanged

**DO:**
- ✅ Edit the plan file directly
- ✅ Add success_criteria to every task that lacks them
- ✅ Rewrite vague tasks to be specific
- ✅ Make all changes in one pass

### 7. Enforcement Rules

- **NO task is acceptable** without testable success criteria
- **NO task should require** human judgment to verify completion
- **NO task should use** subjective terms like "good", "better", "improved"
- **ALL tasks must be** verifiable programmatically or through clear manual steps

## Workflow Example

1. Read plan file: `folder_download_zip_implementation_7306e609.plan.md`
2. Find task: `"Improve error handling"` (vague)
3. **Edit plan file directly**:
   - Change task content to: `"Implement error handling with specific HTTP status codes and logging"`
   - Add success_criteria:
     ```markdown
     success_criteria:
       - "Database errors return HTTP 503 with JSON body {error: 'Database error'}"
       - "Validation errors return HTTP 400 with JSON body {error: 'Validation failed'}"
       - "All errors logged with apiLogger.error() including error type and message"
     ```
4. Continue through all tasks, editing the plan file for each issue found
5. Plan file is now updated with all corrections - no report needed

## Remember

**The AI implementing the plan needs to know EXACTLY when each task is complete without asking you.**

If you can't determine completion with a simple yes/no or pass/fail check, the task is not testable and must be rewritten.

**⚠️ ACTION REQUIRED**: When you find issues, EDIT THE PLAN FILE DIRECTLY. Do not report - fix it.
