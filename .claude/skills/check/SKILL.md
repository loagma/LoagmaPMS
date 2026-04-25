---
name: check
description: Run type checking and fix any issues that arise. Use this skill when you need to verify TypeScript types are correct or when implementing features to ensure type safety.
---

# Type Check and Lint Fix

Run type checking and linting across the monorepo and fix any issues that come up from these checks.

## Command

```bash
npx turbo run typecheck
npx turbo run lint
```

## Process

1. **Run Checks**: Execute `npx turbo run typecheck` and `npx turbo run lint` to identify TypeScript and lint issues
2. **Review Errors**: Analyze each error to understand the root cause
3. **Fix Issues**: Resolve issues systematically:
   - Update type definitions
   - Fix type assertions
   - Correct function signatures
   - Update interface implementations
4. **Re-run Checks**: After fixes, run both checks again to verify all issues are resolved
5. **Iterate**: Continue until both `typecheck` and `lint` pass with no errors

## When to Use

- After implementing new features
- Before committing code
- When refactoring code
- During code review process
- As part of pre-deployment checks

## Best Practices

- Fix type errors at their source, don't just silence them with `any` or `@ts-ignore`
- Ensure type safety is maintained while fixing errors
- Run both checks frequently during development to catch issues early
- Consider the impact of type changes on other parts of the codebase
