---
name: generate-feature-rtm
description: Generates a requirements traceability matrix (RTM) test-scenario writeup from staged feature changes. Use when the user asks for an RTM, test matrix, QA scenario sheet, or requirement-to-scenario mapping for current staged changes.
---

# Generate Feature RTM

Create concise, testable RTM artifacts for the feature currently represented in staged changes.

## Inputs to gather

1. Target feature name (if not explicit, infer from staged file scope and test names).
2. Active task artifact directory:
   - `.cursor/longrunning/<branch-name>/<task-slug>/`
3. Output filenames:
   - Markdown: `test-scenarios.md`
   - CSV: `test-scenarios.csv`
4. Preferred format reference (default style: `docs/clipboard-integration-test-scenarios.md`).

## Workflow

1. Inspect staged changes (`git diff --cached --name-only` and focused staged diffs).
2. Extract concrete requirements from:
   - Router/schema validation logic
   - UI filter/form behavior
   - Existing staged tests (source of truth for expected behavior)
3. Write RTM rows with pass/fail-testable outcomes only.
4. Keep scenario text fully non-technical and tester-friendly — no code terms, variable names, class names, or internal architecture jargon. Steps describe user actions ("Click the toggle", "Open in another browser"). Expected results describe what the tester sees ("The setting shows as ON"). If a developer action is needed, phrase as "ask a developer to...".
5. Include tester notes with browser and URL/state edge cases when relevant.
6. Write **both** outputs in the active task directory:
   - `.cursor/longrunning/<branch-name>/<task-slug>/test-scenarios.md`
   - `.cursor/longrunning/<branch-name>/<task-slug>/test-scenarios.csv`

## Required RTM format

Use this table shape:

| ID | Capability/Requirement | Scenario | Expected Result | Pass/Fail |
| --- | --- | --- | --- | --- |

Rules:
- 8-15 rows unless user asks otherwise.
- IDs should be stable and feature-prefixed (example: `TAG-001`).
- Expected Result must be objectively verifiable.
- No vague wording like "works correctly".
- Markdown and CSV rows must represent the same scenario set and ordering.
- **Write for non-technical QA testers, not developers.** No code-level terms (variable names, class names, database models, internal architecture jargon). Steps describe user actions. Expected results describe what the tester sees on screen.

## Output template

```markdown
# <Feature Name> - Requirements Traceability Matrix (RTM)

**Feature**: <feature>
**Area**: <scope>

---

| ID | Capability/Requirement | Scenario | Expected Result | Pass/Fail |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | |

---

**Notes for testers**

- <short actionable notes>
```

CSV template:

```csv
ID,Capability/Requirement,Scenario,Expected Result,Pass/Fail
TAG-001,"...","...","...",
TAG-002,"...","...","...",
```

## Quality bar

- Tie each row to behavior visible in staged code/tests.
- Cover happy path + validation + URL/state edge cases where applicable.
- Prefer fewer high-signal rows over exhaustive duplicates.
- If behavior changed for multiple surfaces (for example Program + Project), include coverage for each surface.
- Do not default outputs to `docs/`; task artifacts belong under `.cursor/longrunning/<branch-name>/<task-slug>/`.
