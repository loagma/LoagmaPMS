# ============================================================
# ZERO-TRUST CODE REVIEW — TECHNICAL LEAD ENFORCEMENT
# ============================================================
# Philosophy: Every line is guilty until proven necessary.
# No change is too small to break production.
# ============================================================


# =============================================================
# SECTION 0A: MANDATORY PRE-REVIEW VERIFICATION
# =============================================================

Before reading any code, run these commands to establish ground truth:

1. `gh pr view <N> --json headRefName,baseRefName,files,commits` — Identify the exact branch, base, files, and commit count.
2. `gh pr diff <N> --name-only` — Get the authoritative list of files changed. This is your cross-reference for plan compliance. If this fails (e.g. "diff too large"), use `gh api repos/OWNER/REPO/pulls/<N>/files --jq '.[].filename'` instead.
3. `gh pr diff <N>` — Get the full diff. Review THIS, not individual file reads, to avoid missing deletions. If the diff exceeds limits (e.g. 300 files), document that in your review and focus on high-risk files (auth, payments, data writes, schema, new deps) using `git diff main...HEAD -- <path>` for targeted files.
4. Review commits in order (`--json commits`) — Verify TDD evidence: do test commits precede implementation commits?

CRITICAL: Always review against the FINAL commit state, not intermediate commits. If the PR has 5 commits and commit 2 introduces a problem that commit 4 fixes, the problem does not exist in the deliverable. Conversely, if commit 2 introduces a problem and no later commit fixes it, the problem IS in the deliverable regardless of what earlier commits look like.


# =============================================================
# SECTION 0B: MANDATORY — GATHER ALL EXISTING COMMENTS & REPORTS
# =============================================================

Before writing your review, you MUST fetch and process every existing comment and report on the PR. Do not skip any. Your final review MUST address each one.

### Required API Calls

1. **PR review comments** (line-level code comments):
   `gh api repos/OWNER/REPO/pulls/<N>/comments --jq '.[] | {path: .path, line: .line, body: .body, user: .user.login}'`

2. **PR issue comments** (general discussion, bot reports):
   `gh api repos/OWNER/REPO/issues/<N>/comments --jq '.[] | {body: .body, user: .user.login}'`

3. **PR reviews** (submitted review bodies, e.g. APPROVE/REQUEST_CHANGES):
   `gh api repos/OWNER/REPO/pulls/<N>/reviews --jq '.[] | {state: .state, body: .body, user: .user.login}'`

Replace OWNER/REPO with the repo (e.g. DevAccel-Labs/mystatusflow) and <N> with the PR number.

### What to Do With Each Comment/Report

- **Line-level comments**: For each comment, verify whether the code addresses it. If not, add it to your Critical Issues or Questions for Author. If it was addressed, note that in your Existing Comments section.
- **Issue comments**: Greptile, Vercel, and other bots often post summaries or links to reports. Note what they said. If they report "too many files" or similar limits, document that and explain how your review scope was adjusted (e.g. focused on high-risk files).
- **Submitted reviews**: If a human reviewer already approved or requested changes, catalog their feedback. Your review must either confirm each point is resolved or escalate unresolved items.

### Output Requirement

Your review document MUST include an **Existing Comments & Reports** section that:
1. Lists every PR review comment (path, line, author, summary) and your assessment: resolved / still open / needs follow-up.
2. Summarizes every issue comment and bot report (author, key points).
3. Summarizes any submitted review feedback and whether it was addressed.

Do not produce a review that ignores existing feedback. The author and reviewers need to see that all prior comments were considered.


# =============================================================
# SECTION 0: MANDATORY PLAN — NO PLAN, NO REVIEW
# =============================================================

Every PR MUST contain a committed plan document somewhere in the branch diff.

The plan can live at ANY path — `.cursor/longrunning/`, `docs/`, repo root, or wherever the
author placed it. The filename can be `plan.md`, a dated plan file, or any clearly-named
markdown document that serves as the plan. Location and naming are NOT grounds for rejection.

If NO plan document is found anywhere in the branch diff, the PR is AUTOMATICALLY REJECTED.
Do not review the code. Comment:
  "❌ REJECTED: No plan found in this branch. Every change requires a committed plan that documents intent, decisions, and impact."

Companion artifacts (scratchpad.md, test-scenarios.md) are OPTIONAL. Their absence is not
grounds for rejection or blocking. If present, verify they are consistent with the plan, but
do not flag their absence.

### Plan Content — What Matters

The plan should convey the author's intent and reasoning. Flag gaps as NON-BLOCKING suggestions,
not as rejection criteria. The core requirement is that the plan answers these questions:

1. **What and why** — What is the change trying to achieve? Why does it exist?
   - If this is completely absent or incomprehensibly vague, flag it.

2. **Key decisions** — What approach was chosen and why?
   - For trivial changes, a single sentence is fine.
   - For non-trivial changes, note what alternatives were considered if applicable.

3. **What changed** — Which files were modified and what was done to them?
   - Cross-reference the plan's file list against the actual diff. If a file appears in the
     diff but not in the plan, flag it as a question: "File X was changed but not mentioned
     in the plan — was this intentional?"
   - If a file appears in the plan but not in the diff, ask: "Plan mentions X but it wasn't
     modified. Was this forgotten?"

4. **Impact** — What else might be affected?
   - "None" is acceptable for isolated changes.

Missing sections, imperfect formatting, typos, or a plan that doesn't list itself in its own
file table are NOT blocking issues. Note them as minor suggestions if you want, but do not
make them part of the merge decision.


# =============================================================
# SECTION 1: PRODUCTION IMPACT ANALYSIS (MANDATORY ON EVERY PR)
# =============================================================

Every PR review MUST begin with a "Production Impact Assessment" section that answers:
1. What exact runtime behavior changes in production after this merges?
2. Are there new failure modes introduced? What happens when this code throws?
3. Does this change any API contract — request shape, response shape, status codes, headers?
4. Does this touch any hot path or critical user flow (auth, payments, data writes)?
5. Could this cause data loss, data corruption, or stale data under any circumstance?
If the answer to any of 2-5 is yes or uncertain, flag as CRITICAL.


# =============================================================
# SECTION 2: DEVELOPER ENVIRONMENT &amp; DEPLOYMENT IMPACT
# =============================================================

Flag EVERY instance of:
- New, changed, or removed environment variables — every single one, with a comment asking: "Is this documented? Is it in all environments (local, staging, prod)? What happens if it's missing?"
- Database schema changes — migrations, new columns, altered indexes, dropped tables. Ask: "Is this migration reversible? What happens to existing rows? Is there a backfill needed? Does this lock the table?"
  - CRITICAL: Prisma schema is the source of truth. If raw SQL migration files were manually created, REJECT. Migrations must be generated via Prisma commands.
- New dependencies or dependency version changes — ask: "Why this package? What's the bundle size impact? Is it maintained? Are there known CVEs?"
- Changes to CI/CD config, Docker files, build scripts, or dev tooling — ask: "Does every developer need to do something after pulling this? Is the README updated?"
- Changes to shared configuration (tsconfig, eslint, prettier, turbo, package.json scripts) — these affect every developer on the team, flag them loudly.
- New or changed ports, URLs, service endpoints, or external API integrations.


# =============================================================
# SECTION 3: LINE-BY-LINE TRUST NOTHING
# =============================================================

Review every changed line individually. Do not skim. Do not assume intent. For each change:
- What was here before? Why was it removed or altered?
- Does the new code handle all the edge cases the old code handled?
- Is there an off-by-one error, a missing null check, a swallowed exception?
- Are types narrowed correctly or is there an unsafe cast / type assertion / `any`?
- Is there a race condition, timing issue, or order-of-operations bug?
- Could this behave differently under load, with concurrent users, or with large datasets?

### Cross-Component Boundary Tracing
Do not review files in isolation. When a change spans multiple components (parent/child, wrapper/content, shell/body), trace these cross-cutting concerns:

**CSS Box Model Stacking**:
- When padding, margin, or gap values exist at multiple nesting levels, compute the CUMULATIVE effect on content width/height. A parent with `p-5` (20px) wrapping a child with `pr-5` (20px) yields 40px effective right padding — which may be intentional or may be an oversight that narrows content.
- When `overflow`, `scrollbarGutter`, or scroll containers are involved, trace the full containment chain. Who scrolls? What clips? Where does the scrollbar space come from? Does the reserved space stack with explicit padding?

**Event Handler Redundancy**:
- When event handlers (especially `stopPropagation`, `preventDefault`) exist at multiple levels of the component tree, verify each one serves a distinct purpose. If a parent already calls `e.stopPropagation()` for the same event type, a child handler doing the same thing is redundant unless it targets a different propagation path (e.g., portal boundary).
- Ask: "What happens if I remove the inner handler? Does behavior change?" If not, it's dead code.

**Prop/Content Duplication**:
- When content (text, labels, configuration) is hardcoded in an extracted component, check whether it limits reusability. If the component name implies generality (e.g., "Shell", "Layout", "Wrapper") but the content is specific, flag the mismatch — either the component should accept content as props/children, or the name should reflect its specificity.


# =============================================================
# SECTION 4: REGRESSION DETECTION
# =============================================================

For every function or module touched:
- Check if existing tests still cover the changed behavior. If tests were modified, ask WHY — are they being weakened to pass?
- Flag any test that was deleted or had assertions removed or loosened.
- Flag any try-catch that swallows errors silently (empty catch, catch that only logs).
- Flag any change to default values, fallback behavior, or feature flags.
- Flag any change to sort order, filtering logic, or pagination.
- Flag removal of validation, sanitization, or guard clauses.
- If a function signature changed, find every caller — are they all updated? Could any caller pass invalid data now?
- If a shared utility or helper changed, assess blast radius across the entire codebase.

### Replacement Anchoring Bias
When a PR replaces a known-bad pattern with a new implementation, scrutinize the replacement with EQUAL or GREATER rigor. Do not anchor on "this is better than before" — the question is "does this actually work?", not "is this an improvement?"
- If a rigged test is replaced with a new test, verify the new test's assertions are meaningful in the test runtime — not just syntactically different. A test that reads source code strings is rigged; a test that calls `getBoundingClientRect()` in jsdom is ALSO rigged, just in a more sophisticated way.
- If an absolute-positioned element is replaced with flexbox layout, verify the new layout handles the same edge cases (overflow, wrapping, minimum sizes).
- If inline code is extracted into a new component, verify the extracted component is used correctly AND that the extraction didn't lose behavior from the original inline code (missing props, lost context, dropped event handlers).


# =============================================================
# SECTION 5: SECURITY — NON-NEGOTIABLE
# =============================================================

Always flag, never suppress:
- Hardcoded secrets, API keys, tokens, passwords, or credentials in any form.
- SQL injection vectors — any raw string concatenation in queries.
- XSS vectors — any unescaped user input rendered in HTML/JSX.
- Missing authentication or authorization checks on new endpoints.
- Missing input validation or sanitization on user-facing inputs.
- Overly permissive CORS, CSP, or security header changes.
- Exposure of internal error details, stack traces, or system info to clients.
- Changes to auth flows, session handling, token generation, or permission logic.
- New file upload handling without type/size validation.
- Logging that might leak PII or sensitive data (see Logging section below).


# =============================================================
# SECTION 6: LOGGING GUIDELINES ENFORCEMENT
# =============================================================

All logging code in the PR MUST comply with the project's structured logging standards:

### Pino Only — No Console
- Flag ANY use of console.log, console.error, console.warn, console.info, or console.debug in production code paths.
- Server-side logging must use Pino only.
- Client-side code must send logs to server API endpoints — never browser console.

### Error-First Logging
- Errors (status &gt;= 500, exceptions, failures) MUST be logged at 100%.
- Success requests MUST use tail sampling (shouldSample check) — flag any logger.info() call on a success path without a sampling guard.
- If you see `logger.info(event, 'Request completed')` without a sampling check, flag it: "Missing tail sampling — success logs must be sampled in production."

### Wide Events Pattern
- One log event per request/operation — not scattered log lines throughout the code.
- Flag multiple logger.info() calls within the same request handler (should be accumulate-then-emit-once pattern).
- Log events must include high-cardinality identifiers: request_id, user_id (when available), trace_id.

### Field Naming
- ALL log field names must use snake_case. Flag camelCase fields: userId → user_id, requestId → request_id, durationMs → duration_ms.

### PII &amp; Secrets
- Flag logging of email addresses, phone numbers, full names, IP addresses (unhashed), passwords, tokens, API keys.
- Query parameters must use allowlist approach — flag logging all query params without filtering.
- Request/response bodies must NOT be logged unless endpoint is explicitly allowlisted.
- OAuth client secrets (clientSecret, client_secret) must NEVER appear in logs.

### Error Shape
- Error objects must include: type, message, error_category.
- Stack traces: included for 5xx errors only. Flag stack traces on 4xx errors.
- Error fingerprinting should be present when stack is included.

### No Polling or Monitoring Endpoints
- Flag any setInterval/background timer collecting metrics.
- Flag any admin endpoint that returns stored metrics.
- Metrics must be derived from log events, not collected separately.


# =============================================================
# SECTION 7: TDD &amp; TESTING GUIDELINES ENFORCEMENT
# =============================================================

### Test-Driven Development (TDD)
- For every behavior change in the PR, verify that tests were written BEFORE the implementation.
- Look at commit order: test files should appear in commits BEFORE or IN THE SAME commit as the implementation they test. If implementation comes first with no test commit, flag: "Where is the TDD evidence? Tests should be written before implementation for behavior changes."
- Flag any new behavior that has zero test coverage.

### Test Location &amp; Framework
- ALL tests MUST be in /tests directory at project root. Flag any test file inside src/, app/, or co-located with source code.
- ALL tests MUST use Vitest. Flag any Jest, Mocha, or other framework imports.

### Test Quality — No Rigged Tests
- Flag expect(true).toBe(true) or expect(result).toBeDefined() as sole assertions — these always pass and test nothing.
- Flag any test that mocks the function/class being tested — you're testing the mock, not the code.
- Flag tests with no assertions.
- Flag tests that catch errors and do nothing with them.
- Flag any test with only .toBeTruthy() or .toBeDefined() on results — demand specific value assertions.

### jsdom Runtime Limitations — Hidden Rigged Tests
Tests that LOOK like behavior tests but run in jsdom (the default Vitest/RTL environment) can be silently rigged. Flag these patterns as CRITICAL:
- `getBoundingClientRect()` — returns `{top:0, right:0, bottom:0, left:0, width:0, height:0}` for every element. Any assertion comparing position/size values is `expect(0).toBe(0)`.
- `offsetWidth`, `offsetHeight`, `offsetTop`, `offsetLeft` — always 0 in jsdom. Cannot verify element dimensions or positions.
- `scrollTop`, `scrollLeft`, `scrollWidth`, `scrollHeight` — setting these is a no-op. Cannot verify scroll behavior.
- `getComputedStyle()` — returns empty/default values. Cannot verify that CSS classes produce the intended visual result.
- `window.innerWidth`, `window.innerHeight` — fixed defaults, not responsive. Cannot verify responsive breakpoints.
- `IntersectionObserver`, `ResizeObserver` — not implemented. Tests using these need explicit mocks, and the mocks themselves must be verified.
- `element.animate()`, `requestAnimationFrame` — no real animation timeline.

When you see these APIs in a test, ask: "Does this assertion actually test behavior, or does jsdom guarantee this always passes?" If the test claims to verify visual/layout/scroll behavior, it needs a real browser environment (Playwright, Cypress) — not jsdom. Flag the test as rigged and demand either:
1. Remove the assertion (if it adds no value), or
2. Move it to an integration/e2e test suite that runs in a real browser.

Also flag: `expect(element.className).toContain('some-tailwind-class')` — this tests implementation details (class names), not behavior. If the styling approach changes while preserving the same visual result, the test breaks. Class-name assertions are not a substitute for behavioral assertions.

### Test Coverage Requirements
- Every new public function/endpoint must have at least one happy-path test AND one error-path test.
- Edge cases must be tested: empty inputs, boundary values, invalid inputs, null/undefined.
- If the PR modifies error handling, there must be tests that verify the error paths.

### Test Execution
- Flag any evidence of running the entire test suite (npm test, vitest run without file path) during development. Tests should be targeted: vitest run tests/path/to/specific.test.ts.


# =============================================================
# SECTION 8: REACT &amp; NEXT.JS BEST PRACTICES ENFORCEMENT
# =============================================================

### Eliminating Waterfalls (CRITICAL)
- Flag sequential await calls that could be parallelized with Promise.all().
- Flag data fetching waterfalls in page components — parent fetches then child fetches that could run simultaneously.
- Flag await at top of function when the result is only used in one branch — defer the await into the branch.

### Bundle Size (CRITICAL)
- Flag barrel file imports (import { X } from '@tabler/icons-react' instead of import X from '@tabler/icons-react/dist/esm/icons/IconX').
- Flag heavy components loaded synchronously that should use next/dynamic or React.lazy().
- Flag third-party scripts (analytics, logging, chat widgets) loaded before hydration — these should be deferred.
- Flag new dependencies without justification for bundle impact.

### Server-Side Performance
- Flag duplicate data serialization in RSC props — same data passed to multiple client components.
- Flag missing React.cache() for repeated async calls within the same render.
- Flag large objects passed from server components to client components — minimize serialization boundary.

### Re-render Optimization
- Flag useEffect used to derive state from props — this is the "you might not need an effect" anti-pattern. State should be derived during render with useMemo or computed inline.
- Flag useEffect that syncs props to state — use React key prop pattern instead.
- Flag non-primitive default prop values defined inline (new object/array on every render) — these should be hoisted to module scope.
- Flag state subscriptions for values only used in callbacks — use refs instead.
- Flag expensive computations inside render without useMemo.

### CSS/Tailwind Redundancy
- Flag shorthand/longhand conflicts where a longhand class is redundant with an existing shorthand: `px-5 pr-5` (pr-5 already set by px-5), `m-4 mt-4` (mt-4 already set by m-4), `border rounded-lg border-lg` (double specification).
- Flag redundant `overflow-hidden` on containers that also have `overflow-y-auto` children — verify the clipping intent is correct and not accidentally hiding content.

### Rendering
- Flag conditional rendering using &amp;&amp; with potentially falsy non-boolean values (0, '') — use ternary instead.
- Flag missing key props on list items, or using array index as key when list order can change.


# =============================================================
# SECTION 9: "WHY SHOULD I MERGE THIS" GATE
# =============================================================

Every PR review must include a "Justification Check" section:
- Does the plan.md explain WHY this change exists? Cross-reference the plan's User Intent against the actual diff.
- Does every changed file clearly serve the stated purpose? Flag any file that seems unrelated to the plan.
- Are there drive-by refactors mixed in with feature work? Flag them — they obscure the real changes and make rollback harder. Every change must be in the plan.
- Is this the simplest correct implementation, or is it over-engineered?
- Is there dead code being added? Commented-out code? TODO comments without linked tickets?
- Would I mass rollback to the commit before this PR if something broke at 3 AM? If the answer is "that would be painful," the PR is too large or too risky.


# =============================================================
# SECTION 10: ERROR HANDLING &amp; RESILIENCE
# =============================================================

- Every new async operation MUST have error handling. No fire-and-forget promises.
- Every new external call (API, DB, file system) must handle failure gracefully.
- Flag any new retry logic that doesn't have a maximum retry count and backoff.
- Flag any new timeout that seems too long, too short, or missing entirely.
- Flag missing cleanup (open connections, event listeners, intervals, subscriptions).


# =============================================================
# SECTION 11: DATA INTEGRITY
# =============================================================

- Flag any write operation that doesn't happen inside a transaction when it should.
- Flag any read-modify-write pattern that isn't protected against concurrent modification.
- Flag any cache invalidation that looks incomplete.
- Flag any change to data serialization/deserialization formats.
- Flag any change to ID generation, timestamps, or ordering logic.


# =============================================================
# SECTION 12: NITPICK CALIBRATION
# =============================================================

SUPPRESS these (I do not care):
- Semicolons, trailing commas, bracket style
- Import ordering
- Minor naming preferences that don't affect readability
- Documentation formatting
- Plan file location, naming, or formatting nitpicks
- Missing scratchpad.md or test-scenarios.md
- Plan not listing itself in its own file table
- Minor plan section omissions (e.g., missing "downstream impact" on a trivial change)

NEVER SUPPRESS these:
- Logic errors, no matter how subtle
- Missing error handling
- Security issues of any severity
- Performance regressions (waterfalls, barrel imports, unnecessary re-renders)
- Breaking changes to APIs or contracts
- Missing or weakened tests
- Rigged tests that don't test real behavior
- Environment/infrastructure changes
- Database schema changes
- console.log or console.error in production code
- camelCase log field names (must be snake_case)
- useEffect anti-patterns (prop-to-state sync, derived state in effects)
- No plan at all (complete absence from branch diff)
- Anything that could cause a production incident


# =============================================================
# SECTION 13: REVIEW OUTPUT FORMAT
# =============================================================

### MANDATORY: Check for Prior Reviews of the Same PR

Before writing any review, check `docs/review/` for an existing folder matching this PR/branch.

1. List `docs/review/` and look for a folder whose name matches the PR title or branch name.
2. If a folder exists, list its contents and read the highest-numbered review file (e.g., `2-task-review.md`).
3. The prior review is your baseline. The new review MUST:
   - Reference the prior review by filename at the top.
   - Include a **"Changes Since Last Review"** section (see structure below) that categorizes every prior issue as: **Resolved**, **Still Open**, or **Partially Addressed**.
   - Only then add new findings from the current diff state.

If no prior review exists, this is review #1 — proceed normally.

---

### MANDATORY: Versioned Review Files

Reviews live at:

  `docs/review/<task>/<N>-task-review.md`

where `<N>` is the review version number (1, 2, 3, ...).

**Naming rules**:
- First review of a PR: `1-task-review.md`
- Second review (re-review after author pushes fixes): `2-task-review.md`
- Third review: `3-task-review.md`, etc.
- NEVER overwrite a previous version. Each review is an immutable snapshot.

**Task folder name derivation** (use first available):
1. PR title — sanitize to kebab-case (lowercase, spaces/slashes to hyphens, remove special chars)
2. Branch name — use the part after the last slash, sanitize to kebab-case
3. Plan document title or task slug — from the plan's first heading or folder name

Create the `docs/review/<task>/` directory if it does not exist.

---

### MANDATORY: Include PR URL in Every Review

The very first line after the H1 title MUST include the GitHub PR URL (or branch name if no PR exists yet). This makes reviews instantly greppable:

```markdown
# Code Review: PR #347 — feat(defect-tracker): structured HTML formatting

**PR**: https://github.com/DevAccel-Labs/mystatusflow/pull/347
**Branch**: `fix/msf_525` → `staging`
**Review version**: 2 (previous: `1-task-review.md`)
```

The user will always provide a GitHub PR URL or branch name. Capture it verbatim.

---

### MANDATORY: Pin Issues to Exact Line Numbers

Every issue reported in the review (Critical Issues, Bugs, Suspicious Patterns) MUST include:
1. **Exact file path** — the full path as it appears in the diff
2. **Line numbers in the PR branch** — use `git show origin/<branch>:<path> | cat -n` to get authoritative line numbers from the final commit state
3. Format: `**File**: \`path/to/file.ts\` **lines N–M**` at the start of each issue

Code snippets in issues SHOULD include inline line-number comments (e.g., `// line 35`) to anchor the reader. The goal: reviewers and authors can jump directly to the problem without searching.

---

### Review Document Structure

For **review version 1** (first review), structure as:

1. **Existing Comments & Reports** — Catalog every PR review comment, issue comment, and submitted review. For each: path/line (if applicable), author, summary, and your assessment (resolved / still open / needs follow-up). Include bot reports (Greptile, Vercel, etc.) and note any scope limits (e.g. "diff too large").
2. **Plan Compliance** — Is a plan present anywhere in the branch diff? Does it explain what changed and why? Flag significant diff-vs-plan discrepancies.
3. **Production Impact Assessment** — What changes in prod, risk level (LOW/MEDIUM/HIGH/CRITICAL)
4. **Environment & Team Impact** — What other devs need to know or do after this merges
5. **Critical Issues** — Things that MUST be fixed before merge (security, data loss, regressions, missing tests). Every critical issue MUST include the **exact file path** and **line numbers** (in the PR branch) where the problem occurs. Use the format: `**File**: \`path/to/file.ts\` **lines N–M**`. Fetch line numbers by reading the file from the PR branch (`git show origin/<branch>:<path> | cat -n`). **Tone**: Write as a senior dev teaching a junior dev. Keep it short — aim for 2-4 sentences per section, not paragraphs. Each issue has three labeled sections: (1) **Why we don't do this in production** — one plain-language sentence on the principle violated, optionally a one-sentence analogy; (2) **How this affects prod** — one concrete consequence with a real number or scenario (e.g., "100 defects = 100 wasted regex passes per render"); (3) **The learning here** — one transferable rule of thumb the author can apply elsewhere. Then a **Fix** with a short code snippet. The goal is density: every sentence teaches, nothing is filler.
6. **Logging Compliance** — Pino only, snake_case fields, tail sampling, wide events, no PII
7. **Testing Compliance** — TDD evidence, tests in /tests with Vitest, real assertions, edge cases covered
8. **React/Next.js Compliance** — No waterfalls, no barrel imports, no useEffect anti-patterns, proper memoization
9. **Bugs & Logic Errors** — Things that are wrong. Include **exact file path and line numbers** for each bug.
10. **Suspicious Patterns** — Things that smell wrong but might be intentional (demand explanation). Include **exact file path and line numbers** for each pattern.
11. **Questions for Author** — Things that need clarification before approval

For **review version 2+** (re-reviews), add this section immediately after the header/metadata and BEFORE the rest of the review:

**0. Changes Since Last Review** — a table tracking every issue from the prior review:

```markdown
## 0. Changes Since Last Review

Previous review: `1-task-review.md`

| # | Issue from v1 | Status | Notes |
|---|---|---|---|
| C1 | Cache bypass in filter-counts.ts (lines 35–43) | ✅ Resolved | Normalization moved after cache check |
| C2 | Double formatDescriptionForDisplay call (lines 2995–3006) | ⚠️ Still Open | No change in latest commits |
| Q1 | Downstream consumers of description field? | ✅ Resolved | Author confirmed no external consumers |
```

Status values: `✅ Resolved`, `⚠️ Still Open`, `🔶 Partially Addressed` (explain what remains).

After the tracking table, proceed with a FULL fresh review of the current diff state (sections 1–11). Do not skip sections just because the prior review covered them — the code may have changed. New issues discovered in this pass should be clearly labeled as **[NEW]** in their heading.

Do not say "LGTM" unless you have exhaustively verified every line, confirmed a plan exists in the diff, and found zero issues across all sections. Default posture is skepticism. The burden of proof is on the code, not the reviewer.


# =============================================================
# SECTION 14: POST-REVIEW HANDOFF — USER DIRECTIVES
# =============================================================

After the review is written, the user will follow up with **one of two** instructions. Interpret them exactly as below.

### Directive A — "Fix issues X, Y, Z" (or "fix C1, C2", etc.)

**Meaning**: The user wants **only** the items they name from **§4 Critical Issues** in the review document (`docs/review/<task>/<N>-task-review.md`) addressed — not every nit elsewhere unless they explicitly include it.

**Agent must**:

1. **Identify** which Critical Issues they mean — match labels/numbers from section **4. Critical Issues** (e.g. first critical issue = issue 1, or `C1` if the review uses that convention).
2. **Implement fixes** on the **branch under review** (the PR head branch), commit as appropriate, run typecheck/lint (and relevant tests) so the branch is in a good state.
3. **Merge that branch into local `staging`** — use **local git only**:
   - `git fetch` as needed
   - `git checkout staging` (or the repo’s staging branch name)
   - `git merge <review-branch>` (or rebase if the team convention requires it — default is merge unless documented otherwise)
4. **Do not** run `gh pr merge` or any GitHub merge — merging to remote is the user’s decision. Local `staging` integration is what they asked for.

If the user says "fix all critical issues," fix every item listed under **4. Critical Issues**, then merge the review branch into local `staging` the same way.

### Directive B — "OK, just merge into local staging" / "Don't fix it"

**Meaning**: Do **not** implement review fixes. Only integrate the reviewed branch locally.

**Agent must**:

1. **Merge the branch under review into local `staging`** using the same local-git flow as above (`checkout staging`, `merge <review-branch>`).
2. **Do not** run `gh pr merge`.

### Shared notes

- **Branch under review** = the PR’s head ref (from `gh pr view` / review metadata), unless the user named a different branch.
- If `staging` does not exist locally, ask once or create/track it per repo convention — do not assume remote branch names beyond what `gh pr view` shows for base.
- After either directive, briefly confirm: what was fixed (A only), and that local `staging` now contains the review branch’s commits.