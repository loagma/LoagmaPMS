---
name: planning-guidelines
description: Guidelines for creating comprehensive, production-ready plans that account for extreme scalability, performance, reliability, and best practices. Apply when planning features, creating plan documents, or breaking down complex tasks.
---

# Planning Guidelines

When planning, account for extreme scalability, extreme performance, extreme reliability, extreme best practices as per technology stacks involved. Deeply think about what is needed to make this ACTUALLY production ready, production polish, make sure we are not adding features that are not fully implemented, if we do add features it MUST be fully implemented. Think about rate limiting, upstash redis caching, etc, always research web for best practices, options, and be extremely detailed in your plans.

## Logging Requirements

Remember to also follow the logging guidelines about wide event logging:
- We want pure pino event wide logging
- No datadog, no axiom, nothing else just pino server logging
- No browser console logs either - all sent to server logging pino

## Research Requirements

Always search web for industry standard best practices regarding the implementation.

## Required Skill Checks

When planning, ALWAYS CHECK these skills to ensure comprehensive, focused, and high-quality plans:

- **⚠️ TESTING GUIDELINES** - **MANDATORY**: When plans involve testing, MUST explicitly include testing rules
  - **Reference**: `@.cursor/skills/testing-guidelines` for comprehensive testing requirements
  - **CRITICAL Rules**:
    - All tests MUST be in `/tests` directory at project root using Vitest framework
    - NEVER run entire test suite (`npm test`, `vitest run` without file path)
    - ALL tests MUST be run and validated before marking test tasks complete
    - Tests must be real (never rigged to pass), validate actual behavior
  - **Plan Requirement**: Plans involving testing MUST include testing strategy section with test types, execution rules, coverage requirements, and validation commands
- **@.cursor/skills/avoid-feature-creep** - Prevent scope expansion and stay focused on core value
- **@.cursor/skills/ask-questions-if-underspecified** - Clarify requirements before implementing
- **@.cursor/skills/logging-guidelines** - Apply structured logging best practices with Pino
- **@.cursor/skills/vercel-react-best-practices** - Follow React and Next.js performance optimization patterns
- **@.cursor/skills/web-design-guidelines** - Ensure UI code meets Web Interface Guidelines compliance

**⚠️ CRITICAL**: **When plans involve testing, testing guidelines adherence is MANDATORY** - all tests must be run and validated. These skills provide critical guardrails and best practices that must be considered during the planning phase.

## Rules from Past Mistakes

- Never import from barrel files - Use direct imports: `import Icon from 'package/dist/esm/icons/icon'` or configure optimizePackageImports in Next.js config
- Never conditionally create promises - Start all independent promises immediately, filter results later; use Promise.allSettled for conditionals
- Never create components over 500 lines - Split into focused components with dynamic imports for heavy sections
- Always wrap independent data sections in Suspense - Use Suspense boundaries with skeleton fallbacks for streaming content
- Always use functional setState - Use `setState(prev => ...)` when state depends on previous state
- Always narrow effect dependencies - Use primitive values in dependency arrays, not objects/arrays
- Always add content-visibility CSS - Use `content-visibility: auto` for list items rendering 10+ items
- Always use Map/Set for O(1) lookups - Replace array.find() with Map.get() when checking 5+ items repeatedly
- Always lazy load heavy libraries - Use next/dynamic with ssr: false for drag-drop, virtual scrolling, and other heavy features
- Always minimize RSC payloads - Pass only required fields to client components, create minimal DTOs at server→client boundaries
- Always cache cross-request data - Use LRU cache with TTL for frequently accessed server data (workspace details, projects list)
- Always deduplicate queries - Ensure tRPC queries use proper staleTime/gcTime and React Query deduplication
- Always use useTransition for non-urgent updates - Wrap URL updates, search filters, and other non-critical state changes in startTransition
- Always extract expensive computations - Use useMemo for computations used in render, useCallback for functions passed as props
- Always add error boundaries - Wrap major sections in error boundaries with fallback UI

## Plan Structure Requirements

Plans should include:

1. **Problem Statement** - Clear articulation of what problem is being solved
2. **Success Criteria** - Specific, measurable outcomes that define completion
3. **Technical Approach** - Detailed implementation strategy
4. **Performance Considerations** - Scalability, caching, rate limiting strategies
5. **Error Handling** - How errors will be caught, logged, and reported
6. **Security Considerations** - Authentication, authorization, data validation
7. **Testing Strategy** (if applicable) - Test types, coverage, validation commands
8. **Logging Strategy** - What events will be logged, with what fields
9. **Dependencies** - What needs to be in place before starting
10. **Rollout Strategy** - How the feature will be deployed

## Production-Ready Checklist

Before finalizing a plan, verify:

- [ ] Extreme scalability considered (handles 10x current load)
- [ ] Extreme performance optimized (sub-200ms response times)
- [ ] Extreme reliability ensured (graceful degradation, retry logic)
- [ ] Rate limiting implemented where applicable
- [ ] Caching strategy defined (Upstash Redis where appropriate)
- [ ] Error handling comprehensive (all failure modes covered)
- [ ] Logging complete (wide event pattern with all required fields)
- [ ] Security reviewed (no vulnerabilities, proper validation)
- [ ] Best practices researched (industry standards followed)
- [ ] Testing strategy defined (if applicable - must follow /testing-guidelines)
- [ ] No partial features (everything fully implemented or explicitly deferred)
