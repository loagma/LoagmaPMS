---
name: testing-guidelines
description: Enforce comprehensive testing best practices ensuring all tests are real, never rigged to pass. CRITICAL RULES: (1) Never run entire test suite (`npm test`, `vitest run` without file path) - only run specific test files you create or modify. (2) All tests must be in `/tests` directory at project root using Vitest framework. PLANNING RULE: When creating plans that involve testing, the plan must explicitly include testing rules and guidelines to ensure they are never overlooked. Covers unit, integration, e2e, component, performance, and security testing with detailed patterns, anti-patterns, and validation rules. Use when writing tests, reviewing test code, implementing test coverage, creating plans involving testing, or when the user mentions testing, test quality, or test reliability.
---

# Testing Guidelines - MyStatusFlow

**Definitive guide for extreme best-practice testing ensuring all tests are real, never rigged to pass.**

> **Last Updated**: January 2025  
> **Status**: Comprehensive Guidelines  
> **Philosophy**: Tests must validate real behavior, never be rigged to pass

---

## ⚠️ CRITICAL: Core Testing Principles

### The Golden Rule: Tests Must Be Real

**Every test must validate actual behavior, not just pass.**

### Core Principles

1. **Tests Must Validate Real Behavior**
   - Tests verify actual functionality, not just that code runs
   - Tests fail when behavior changes, not just when code breaks
   - Tests catch regressions, not just syntax errors

2. **Never Rig Tests to Pass**
   - Never mock away the thing you're testing
   - Never skip assertions that validate behavior
   - Never use assertions that always pass (`expect(true).toBe(true)`)
   - Never ignore test failures or mark them as "expected"

3. **Tests Must Be Deterministic**
   - Same inputs always produce same outputs
   - No flaky tests that pass/fail randomly
   - No time-dependent tests without proper mocking
   - No race conditions or timing issues

4. **Tests Must Be Independent**
   - Each test can run in isolation
   - Tests don't depend on execution order
   - Tests don't share mutable state
   - Tests clean up after themselves

5. **Tests Must Be Maintainable**
   - Clear test names that describe what they test
   - Well-organized test structure
   - Reusable test utilities and fixtures
   - Tests are easy to understand and modify

6. **⚠️ CRITICAL: Never Run Entire Test Suite**
   - **NEVER run `npm test`, `npm run test`, `vitest run`, or equivalent commands that run all tests**
   - **ONLY run the specific test file(s) you created or modified**
   - Use targeted test execution: `vitest run path/to/specific.test.ts`
   - Use watch mode for the specific file: `vitest path/to/specific.test.ts`
   - Validate only the tests you're working on
   - Running the entire suite wastes time and resources
   - Running the entire suite may expose unrelated failures that distract from your work
   - **This is a hard rule - never run the full test suite during development**

7. **⚠️ CRITICAL: Plans Must Include Testing Rules**
   - **When creating plans that involve testing, the plan MUST explicitly include testing rules and guidelines**
   - Plans must reference key testing principles to ensure they are never overlooked
   - Plans must specify which test types will be used (unit, integration, e2e, etc.)
   - Plans must include test execution rules (never run full suite)
   - Plans must specify test coverage requirements
   - Plans must include edge case and error handling test requirements
   - **This ensures testing guidelines are baked into the planning process, not forgotten**

8. **⚠️ CRITICAL: Test Location & Framework**
   - **All tests MUST be located in `/tests` directory at project root**
   - **All tests MUST use Vitest framework** (not Jest, Mocha, or other frameworks)
   - Test files follow pattern: `tests/**/*.test.{ts,tsx}`
   - Tests are organized by type: `tests/unit/`, `tests/integration/`, `tests/e2e/`, etc.
   - **This is a hard rule - no exceptions for test location or framework**

---

## Planning & Testing Integration

### ⚠️ CRITICAL: Plans Must Include Testing Guidelines

**When creating any plan that involves testing, the plan MUST explicitly include testing rules and guidelines.**

This ensures that:
- Testing requirements are not forgotten or overlooked
- Testing guidelines are part of the planning process from the start
- All team members understand testing expectations
- Testing is treated as a first-class requirement, not an afterthought

### Required Elements in Plans

When creating a plan that involves testing, the plan MUST include:

1. **Test Type Specification**
   - Which test types will be used (unit, integration, component, e2e, performance, security)
   - Rationale for test type choices
   - Test type distribution (e.g., "80% unit tests, 15% integration tests, 5% e2e tests")

2. **Test Execution Rules**
   - Explicit statement: "Never run entire test suite (`npm test`, `vitest run` without file path)"
   - Only run specific test files: `vitest run path/to/specific.test.ts`
   - This rule must be included in every plan involving tests

3. **Test Coverage Requirements**
   - Target coverage percentages (e.g., "80% for business logic, 100% for critical paths")
   - What must be covered (business logic, error handling, edge cases)
   - What doesn't need coverage (simple getters, third-party code)

4. **Testing Principles**
   - Tests must be real (never rigged to pass)
   - Tests must validate actual behavior
   - Tests must be deterministic and independent
   - Reference to core testing principles

5. **Edge Cases & Error Handling**
   - Which edge cases will be tested
   - Which error scenarios will be covered
   - Boundary condition testing requirements

6. **Performance Testing Requirements** (if applicable)
   - **For web performance**: Use Chrome DevTools MCP tools
   - Performance targets (e.g., LCP < 2.5s, FCP < 1.8s, TBT < 300ms)
   - Baseline measurement workflow
   - Validation workflow using `performance_analyze_insight`
   - Network request analysis using `list_network_requests`
   - Console error verification using `list_console_messages`
   - Reference: `@.cursor/skills/chrome-devtools-mcp` for complete workflows

7. **Test Structure Requirements**
   - Test file organization
   - Test naming conventions
   - Test data management approach

### Plan Template Example

```markdown
## Testing Strategy

### Test Location & Framework
⚠️ **CRITICAL**: All tests must be in `/tests` directory at project root using Vitest
- **Location**: `/tests` at project root (not co-located with source)
- **Framework**: Vitest (not Jest, Mocha, or other frameworks)
- **Structure**:
  ```
  tests/
  ├── unit/
  ├── integration/
  ├── component/
  ├── e2e/
  └── helpers/
  ```

### Test Types
- **Unit Tests**: 80% coverage for business logic functions
- **Integration Tests**: API endpoints with database
- **Component Tests**: React components using Testing Library
- **E2E Tests**: Critical user workflows (authentication, payment)

### Test Execution Rules
⚠️ **CRITICAL**: Never run entire test suite during development
- Only run specific test files: `vitest run tests/path/to/specific.test.ts`
- Use watch mode: `vitest tests/path/to/specific.test.ts`
- Full suite runs only in CI/CD

### Coverage Requirements
- Business logic: 80%+ coverage
- Critical paths (auth, payments): 100% coverage
- Error handling: All error paths tested
- Edge cases: Empty inputs, boundary values, invalid inputs

### Testing Principles
- All tests must be real (never rigged to pass)
- Tests validate actual behavior, not just that code runs
- Tests are deterministic and independent
- Tests clean up after themselves

### Edge Cases to Test
- Empty inputs
- Boundary values (min/max)
- Invalid inputs
- Unicode and special characters
- Concurrent operations (if applicable)

### Performance Testing (if applicable)
- **For web performance**: Use Chrome DevTools MCP tools
- Performance targets: LCP < 2.5s, FCP < 1.8s, TBT < 300ms
- Baseline measurement: `navigate_page` → `performance_start_trace` → `wait_for` → `performance_stop_trace` → `performance_analyze_insight`
- Validation: Compare metrics with targets, check network requests, verify console errors
- Reference: `@.cursor/skills/chrome-devtools-mcp` for complete workflows

### Test Structure
- All tests in `/tests` root directory organized by type
- Use AAA pattern (Arrange-Act-Assert)
- Use descriptive test names
- Create reusable test fixtures in `tests/helpers/`
```

### When This Applies

This rule applies when:
- Creating implementation plans that include testing
- Planning new features that require tests
- Creating task breakdowns that involve testing
- Writing technical specifications that mention testing
- Any plan document that references testing or test coverage

**If a plan involves testing but doesn't include testing rules and guidelines, the plan is incomplete and must be updated.**

---

## Table of Contents

### Quick Reference
- [Test Type Decision Tree](#test-type-decision-tree)
- [Test Structure Template](#test-structure-template)
- [Common Patterns](#common-patterns)
- [Anti-Patterns Checklist](#anti-patterns-checklist)

### Core Concepts
1. [Planning & Testing Integration](#planning--testing-integration)
2. [Test Types & When to Use](#test-types--when-to-use)
3. [Test Structure & Organization](#test-structure--organization)
4. [Assertions & Validation](#assertions--validation)
5. [Mocking Guidelines](#mocking-guidelines)
6. [Test Data Management](#test-data-management)

### Test Types (Detailed)
6. [Unit Tests](#unit-tests)
7. [Integration Tests](#integration-tests)
8. [Component Tests](#component-tests)
9. [End-to-End Tests](#end-to-end-tests)
10. [Performance Tests](#performance-tests)
11. [Security Tests](#security-tests)

### Advanced Topics
12. [Edge Cases & Boundary Conditions](#edge-cases--boundary-conditions)
13. [Error Handling Tests](#error-handling-tests)
14. [Concurrency & Race Conditions](#concurrency--race-conditions)
15. [Test Coverage Requirements](#test-coverage-requirements)

### Best Practices
16. [Test Naming Conventions](#test-naming-conventions)
17. [Test Organization](#test-organization)
18. [Test Performance](#test-performance)
19. [CI/CD Integration](#cicd-integration)

### Reference
20. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
21. [Common Mistakes](#common-mistakes)
22. [Testing Checklist](#testing-checklist)

---

## Quick Reference

### ⚠️ CRITICAL: Test Execution Rule

**NEVER run the entire test suite during development:**
- ❌ `npm test`
- ❌ `npm run test`
- ❌ `vitest run` (without file path)
- ❌ `vitest run --coverage` (without file path)

**ONLY run specific test files:**
- ✅ `vitest run path/to/your.test.ts`
- ✅ `vitest path/to/your.test.ts` (watch mode)
- ✅ `vitest run --grep "test pattern"`

**Exception**: Full test suite runs are acceptable ONLY in CI/CD pipelines.

### ⚠️ CRITICAL: Test Location & Framework Rule

**All tests MUST be:**
- Located in `/tests` directory at project root (not co-located with source)
- Written using Vitest framework (not Jest, Mocha, or other frameworks)
- Follow naming: `*.test.{ts,tsx}` for unit/integration, `*.spec.ts` for E2E

**Test structure:**
```
tests/
├── unit/
├── integration/
├── component/
├── e2e/
└── helpers/
```

### ⚠️ CRITICAL: Planning Rule

**When creating plans that involve testing, the plan MUST include:**
- Test type specification (unit, integration, e2e, etc.)
- Test execution rules (never run full suite)
- Test location requirement (`/tests` at root using Vitest)
- Test coverage requirements
- Testing principles (tests must be real, validate behavior)
- Edge cases and error handling requirements

**If a plan involves testing but doesn't include testing rules, the plan is incomplete.**

### Test Type Decision Tree

```
What are you testing?
├─ Single function/class in isolation?
│  └─ YES → Unit Test
│
├─ Multiple components working together?
│  ├─ Database + API + Business Logic?
│  │  └─ YES → Integration Test
│  │
│  └─ UI Components + State + User Interactions?
│     └─ YES → Component Test
│
├─ Full user workflow across multiple pages?
│  └─ YES → E2E Test (Playwright)
│
├─ Performance characteristics?
│  └─ YES → Performance Test
│
└─ Security vulnerabilities?
   └─ YES → Security Test
```

### Test Structure Template

```typescript
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

describe('ComponentName / FunctionName', () => {
  // Setup - runs before each test
  beforeEach(() => {
    // Initialize test data
    // Reset mocks
    // Set up test environment
  })

  // Cleanup - runs after each test
  afterEach(() => {
    // Clean up test data
    // Restore mocks
    // Reset state
  })

  describe('feature or behavior being tested', () => {
    it('should do something specific when given specific input', () => {
      // Arrange: Set up test data and conditions
      const input = createTestInput()
      
      // Act: Execute the code being tested
      const result = functionUnderTest(input)
      
      // Assert: Verify the expected behavior
      expect(result).toMatchExpectedBehavior()
    })

    it('should handle edge case correctly', () => {
      // Test edge cases
    })
  })

  describe('error handling', () => {
    it('should throw appropriate error for invalid input', () => {
      // Test error cases
    })
  })
})
```

### Common Patterns

#### ✅ CORRECT: Real Test

```typescript
describe('calculateTotal', () => {
  it('should sum all items correctly', () => {
    const items = [
      { price: 10, quantity: 2 },
      { price: 5, quantity: 3 },
    ]
    
    const total = calculateTotal(items)
    
    // Real assertion: validates actual calculation
    expect(total).toBe(35) // 10*2 + 5*3 = 35
  })

  it('should return 0 for empty array', () => {
    const total = calculateTotal([])
    expect(total).toBe(0)
  })

  it('should handle negative prices correctly', () => {
    const items = [{ price: -10, quantity: 1 }]
    const total = calculateTotal(items)
    expect(total).toBe(-10)
  })
})
```

#### ❌ WRONG: Rigged Test

```typescript
describe('calculateTotal', () => {
  it('should calculate total', () => {
    const items = [{ price: 10, quantity: 2 }]
    
    // ❌ WRONG: Mocking the function being tested
    const calculateTotal = vi.fn(() => 20)
    
    const total = calculateTotal(items)
    
    // ❌ WRONG: Assertion that always passes
    expect(total).toBeDefined()
    expect(true).toBe(true)
  })
})
```

---

## Test Types & When to Use

### Unit Tests

**Purpose**: Test individual functions, classes, or modules in isolation.

**When to Use**:
- Testing pure functions (same input → same output)
- Testing business logic
- Testing utility functions
- Testing data transformations
- Testing validation logic

**Characteristics**:
- Fast execution (< 10ms per test)
- No external dependencies (database, APIs, file system)
- Deterministic (same inputs = same outputs)
- Isolated (no shared state)

**Example**:
```typescript
describe('sanitizeFilename', () => {
  it('should remove path traversal characters', () => {
    const input = '../../etc/passwd'
    const result = sanitizeFilename(input)
    expect(result).toBe('passwd')
  })

  it('should handle Unicode characters', () => {
    const input = '报告.pdf'
    const result = sanitizeFilename(input)
    expect(result.asciiFallback).toMatch(/^[a-zA-Z0-9._-]+$/)
  })
})
```

### Integration Tests

**Purpose**: Test multiple components working together.

**When to Use**:
- Testing API endpoints with database
- Testing service layer with data layer
- Testing multiple modules interacting
- Testing external service integrations (with mocks)

**Characteristics**:
- Slower than unit tests (10ms - 1000ms)
- May use test database or mocked external services
- Tests real interactions between components
- May require setup/teardown

**Example**:
```typescript
describe('POST /api/tasks', () => {
  it('should create task and return it with correct data', async () => {
    // Arrange: Set up test data in database
    const workspace = await createTestWorkspace()
    const user = await createTestUser({ workspaceId: workspace.id })
    
    // Act: Make real API call
    const response = await request(app)
      .post('/api/tasks')
      .set('Authorization', `Bearer ${user.token}`)
      .send({ title: 'Test Task', workspaceId: workspace.id })
    
    // Assert: Verify database state and response
    expect(response.status).toBe(201)
    expect(response.body.title).toBe('Test Task')
    
    const taskInDb = await db.task.findUnique({ where: { id: response.body.id } })
    expect(taskInDb).toBeTruthy()
    expect(taskInDb.title).toBe('Test Task')
  })
})
```

### Component Tests

**Purpose**: Test React components in isolation.

**When to Use**:
- Testing component rendering
- Testing user interactions
- Testing component state changes
- Testing props handling
- Testing accessibility

**Characteristics**:
- Uses React Testing Library
- Tests user-facing behavior, not implementation
- May mock external dependencies
- Fast execution (< 100ms per test)

**Example**:
```typescript
describe('TaskCard', () => {
  it('should display task title and allow editing', async () => {
    const task = { id: '1', title: 'Test Task', completed: false }
    const onUpdate = vi.fn()
    
    render(<TaskCard task={task} onUpdate={onUpdate} />)
    
    // Verify rendering
    expect(screen.getByText('Test Task')).toBeInTheDocument()
    
    // Test user interaction
    const editButton = screen.getByRole('button', { name: /edit/i })
    await userEvent.click(editButton)
    
    const input = screen.getByDisplayValue('Test Task')
    await userEvent.clear(input)
    await userEvent.type(input, 'Updated Task')
    await userEvent.click(screen.getByRole('button', { name: /save/i }))
    
    // Verify callback was called with correct data
    expect(onUpdate).toHaveBeenCalledWith({ ...task, title: 'Updated Task' })
  })
})
```

### End-to-End Tests

**Purpose**: Test complete user workflows.

**When to Use**:
- Testing critical user journeys
- Testing cross-page workflows
- Testing authentication flows
- Testing payment flows
- Testing complex multi-step processes

**Characteristics**:
- Uses Playwright or similar
- Tests against real or staging environment
- Slow execution (seconds to minutes)
- May require test data setup
- Tests real browser behavior

**Example**:
```typescript
test('user can create and complete a task', async ({ page }) => {
  // Login
  await page.goto('/login')
  await page.fill('[name="email"]', 'test@example.com')
  await page.fill('[name="password"]', 'password123')
  await page.click('button[type="submit"]')
  
  // Navigate to workspace
  await page.waitForURL('/workspace/*')
  await page.click('text=Projects')
  
  // Create task
  await page.click('button:has-text("New Task")')
  await page.fill('[name="title"]', 'E2E Test Task')
  await page.click('button:has-text("Create")')
  
  // Verify task appears
  await expect(page.locator('text=E2E Test Task')).toBeVisible()
  
  // Complete task
  await page.click('input[type="checkbox"]')
  
  // Verify task is marked complete
  await expect(page.locator('text=E2E Test Task').locator('..')).toHaveClass(/completed/)
})
```

### Performance Tests

**Purpose**: Validate performance characteristics.

**When to Use**:
- Testing response times
- Testing throughput
- Testing memory usage
- Testing database query performance
- Testing batch operations
- **Testing web page performance** (LCP, FCP, TBT, CLS, network requests)

**⚠️ CRITICAL: For Web Performance Testing**

When testing web page performance (page load times, Core Web Vitals, network requests), use **Chrome DevTools MCP** tools:

**Reference**: `@.cursor/skills/chrome-devtools-mcp` for complete performance measurement workflows.

**Performance Test Workflow**:
1. Use `navigate_page` to load the page
2. Call `performance_start_trace` to begin recording
3. Use interaction tools (`click`, `fill`, `hover`) to simulate user actions
4. Call `performance_stop_trace` to end recording
5. Call `performance_analyze_insight` to get metrics and insights
6. Extract metrics (LCP, FCP, TBT, CLS) and assert against targets
7. Use `list_network_requests` to check network performance
8. Use `list_console_messages` to verify no errors

**Example Performance Test with Chrome DevTools MCP**:
```typescript
describe('homepage performance', () => {
  it('should load with LCP < 2.5s', async () => {
    // Navigate to page
    await navigatePage('https://example.com')
    
    // Start performance trace
    await performanceStartTrace()
    
    // Wait for page to be fully loaded
    await waitFor({ selector: 'main', timeout: 10000 })
    
    // Stop trace
    const trace = await performanceStopTrace()
    
    // Analyze insights
    const insights = await performanceAnalyzeInsight(trace)
    
    // Extract LCP metric and assert
    const lcp = insights.metrics?.lcp
    expect(lcp).toBeLessThan(2500) // LCP < 2.5s
    
    // Verify no console errors
    const consoleMessages = await listConsoleMessages()
    const errors = consoleMessages.filter(m => m.level === 'error')
    expect(errors).toHaveLength(0)
  })

  it('should have no slow network requests (>1s)', async () => {
    await navigatePage('https://example.com')
    await waitFor({ selector: 'main', timeout: 10000 })
    
    const requests = await listNetworkRequests()
    const slowRequests = requests.filter(r => r.duration > 1000)
    
    expect(slowRequests).toHaveLength(0)
  })
})
```

**Example: Server-Side Performance Tests**:
```typescript
describe('batchUpsert performance', () => {
  it('should handle 1000 items in under 2 seconds', async () => {
    const items = Array.from({ length: 1000 }, (_, i) => ({
      id: `item-${i}`,
      data: `data-${i}`,
    }))
    
    const start = performance.now()
    await batchUpsert(items)
    const duration = performance.now() - start
    
    expect(duration).toBeLessThan(2000)
  })

  it('should not exceed memory threshold', async () => {
    const initialMemory = process.memoryUsage().heapUsed
    await processLargeDataset(10000)
    const finalMemory = process.memoryUsage().heapUsed
    const memoryIncrease = finalMemory - initialMemory
    
    // Should not exceed 100MB
    expect(memoryIncrease).toBeLessThan(100 * 1024 * 1024)
  })
})
```

### Security Tests

**Purpose**: Validate security properties.

**When to Use**:
- Testing authentication/authorization
- Testing input validation
- Testing SQL injection prevention
- Testing XSS prevention
- Testing CSRF protection
- Testing rate limiting

**Example**:
```typescript
describe('authentication security', () => {
  it('should reject requests without valid token', async () => {
    const response = await request(app)
      .get('/api/protected')
      .set('Authorization', 'Bearer invalid-token')
    
    expect(response.status).toBe(401)
  })

  it('should prevent SQL injection in search query', async () => {
    const maliciousInput = "'; DROP TABLE users; --"
    const response = await request(app)
      .get('/api/search')
      .query({ q: maliciousInput })
    
    // Should sanitize input, not execute SQL
    expect(response.status).toBe(200)
    // Verify no SQL execution by checking database still exists
    const users = await db.user.findMany()
    expect(users.length).toBeGreaterThan(0)
  })

  it('should prevent XSS in user-generated content', async () => {
    const xssPayload = '<script>alert("xss")</script>'
    const response = await request(app)
      .post('/api/comments')
      .send({ content: xssPayload })
    
    expect(response.status).toBe(200)
    // Verify content is sanitized
    expect(response.body.content).not.toContain('<script>')
    expect(response.body.content).toContain('&lt;script&gt;')
  })
})
```

---

## Test Structure & Organization

### ⚠️ CRITICAL: Test Location & Framework Requirements

**All tests MUST be:**
- Located in `/tests` directory at project root (not co-located with source)
- Written using Vitest framework (not Jest, Mocha, or other frameworks)
- Follow naming pattern: `*.test.{ts,tsx}` for unit/integration tests
- Follow naming pattern: `*.spec.ts` for E2E tests (Playwright)

### File Naming

- Unit tests: `*.test.ts` or `*.test.tsx` (component tests)
- Integration tests: `*.integration.test.ts` or `*.test.ts` in `tests/integration/`
- E2E tests: `*.spec.ts` (Playwright convention) in `tests/e2e/`
- Performance tests: `*.test.ts` in `tests/performance/`
- Security tests: `*.test.ts` in `tests/security/`

### Test Organization Structure

**✅ CORRECT: All tests in `/tests` root directory**

```
project-root/
├── src/
│   ├── components/
│   │   └── TaskCard.tsx
│   ├── lib/
│   │   └── utils.ts
│   └── server/
│       └── api/
│           └── routers/
│               └── tasks.ts
│
└── tests/                          # All tests here at root
    ├── unit/                       # Unit tests
    │   ├── utils.test.ts
    │   └── task-service.test.ts
    ├── integration/                # Integration tests
    │   ├── api-routes.test.ts
    │   └── database.test.ts
    ├── component/                  # Component tests
    │   └── TaskCard.test.tsx
    ├── e2e/                        # E2E tests (Playwright)
    │   └── user-workflows.spec.ts
    ├── performance/                # Performance tests
    │   └── batch-operations.test.ts
    ├── security/                   # Security tests
    │   └── auth-security.test.ts
    └── helpers/                    # Test utilities
        ├── test-utils.ts
        └── fixtures.ts
```

**❌ WRONG: Tests co-located with source**

```
src/
├── components/
│   ├── TaskCard.tsx
│   └── __tests__/              # ❌ DON'T DO THIS
│       └── TaskCard.test.tsx
└── lib/
    ├── utils.ts
    └── __tests__/              # ❌ DON'T DO THIS
        └── utils.test.ts
```

### Vitest Configuration

Tests must use Vitest. Example `vitest.config.ts`:

```typescript
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    include: ['tests/**/*.test.{ts,tsx}'],
    exclude: ['node_modules', 'dist', '.next'],
    environment: 'jsdom', // For component tests
    globals: true,
  },
})
```

### Running Tests

**✅ CORRECT: Run specific test files from `/tests` directory**

```bash
# Run specific unit test
vitest run tests/unit/utils.test.ts

# Run all unit tests
vitest run tests/unit/

# Run specific integration test
vitest run tests/integration/api-routes.test.ts

# Watch mode for specific test
vitest tests/unit/utils.test.ts

# Run tests matching pattern
vitest run --grep "should handle errors"
```

**❌ WRONG: Running from wrong location or using wrong framework**

```bash
# ❌ DON'T: Run from src directory
vitest run src/components/__tests__/TaskCard.test.tsx

# ❌ DON'T: Use Jest
jest tests/unit/utils.test.ts

# ❌ DON'T: Run entire suite
npm test
```

### Test Structure (AAA Pattern)

Every test should follow Arrange-Act-Assert:

```typescript
it('should do something', () => {
  // Arrange: Set up test data and conditions
  const input = createTestInput()
  const expectedOutput = createExpectedOutput()
  
  // Act: Execute the code being tested
  const result = functionUnderTest(input)
  
  // Assert: Verify the expected behavior
  expect(result).toEqual(expectedOutput)
})
```

---

## Assertions & Validation

### Assertion Best Practices

1. **Be Specific**: Test exact values, not just truthiness
   ```typescript
   // ✅ GOOD
   expect(result).toBe(42)
   expect(result.status).toBe('completed')
   
   // ❌ BAD
   expect(result).toBeTruthy()
   expect(result).toBeDefined()
   ```

2. **Test Behavior, Not Implementation**
   ```typescript
   // ✅ GOOD: Tests behavior
   expect(user.canAccessWorkspace(workspace)).toBe(true)
   
   // ❌ BAD: Tests implementation
   expect(user.roles).toContain('admin')
   ```

3. **Use Descriptive Matchers**
   ```typescript
   // ✅ GOOD
   expect(array).toHaveLength(3)
   expect(string).toContain('expected')
   expect(object).toMatchObject({ id: '123', name: 'Test' })
   
   // ❌ BAD
   expect(array.length === 3).toBe(true)
   expect(string.includes('expected')).toBe(true)
   ```

4. **Test Error Cases**
   ```typescript
   // ✅ GOOD
   expect(() => divide(10, 0)).toThrow('Cannot divide by zero')
   
   // ❌ BAD
   try {
     divide(10, 0)
     expect(true).toBe(false) // This will never run if error is thrown
   } catch (e) {
     expect(e).toBeDefined()
   }
   ```

### Common Assertion Patterns

```typescript
// Equality
expect(actual).toBe(expected)           // Strict equality (===)
expect(actual).toEqual(expected)        // Deep equality
expect(actual).toStrictEqual(expected)  // Deep equality with type checking

// Truthiness
expect(value).toBeTruthy()
expect(value).toBeFalsy()
expect(value).toBeNull()
expect(value).toBeUndefined()

// Numbers
expect(number).toBeGreaterThan(10)
expect(number).toBeLessThan(100)
expect(number).toBeGreaterThanOrEqual(10)
expect(number).toBeLessThanOrEqual(100)
expect(number).toBeCloseTo(0.3, 5)     // Floating point comparison

// Strings
expect(string).toContain('substring')
expect(string).toMatch(/regex/)
expect(string).toHaveLength(10)

// Arrays
expect(array).toHaveLength(5)
expect(array).toContain(item)
expect(array).toContainEqual(item)      // Deep equality

// Objects
expect(object).toHaveProperty('key')
expect(object).toHaveProperty('key', 'value')
expect(object).toMatchObject({ key: 'value' })

// Functions
expect(fn).toThrow()
expect(fn).toThrow('error message')
expect(fn).toThrowError(ErrorClass)

// Async
await expect(promise).resolves.toBe(value)
await expect(promise).rejects.toThrow()
```

---

## Mocking Guidelines

### When to Mock

**Mock external dependencies, not the code you're testing.**

✅ **Good to Mock**:
- External APIs (Stripe, SendGrid, etc.)
- Database (for unit tests)
- File system operations
- Network requests
- Time-dependent functions (`Date.now()`, `setTimeout`)
- Random number generators (for deterministic tests)

❌ **Never Mock**:
- The function/class you're testing
- Pure functions (same input → same output)
- Internal utilities you control
- Business logic

### Mocking Patterns

#### Mock External API

```typescript
import { vi } from 'vitest'

// Mock the external library
vi.mock('stripe', () => ({
  default: vi.fn(() => ({
    customers: {
      create: vi.fn(),
    },
  })),
}))

describe('createCustomer', () => {
  it('should create Stripe customer', async () => {
    const mockStripe = await import('stripe')
    const mockCreate = vi.fn().mockResolvedValue({ id: 'cus_123' })
    mockStripe.default().customers.create = mockCreate
    
    const customer = await createCustomer({ email: 'test@example.com' })
    
    expect(mockCreate).toHaveBeenCalledWith({ email: 'test@example.com' })
    expect(customer.id).toBe('cus_123')
  })
})
```

#### Mock Time

```typescript
describe('scheduledTask', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('should execute after delay', async () => {
    const callback = vi.fn()
    scheduledTask(callback, 1000)
    
    expect(callback).not.toHaveBeenCalled()
    
    vi.advanceTimersByTime(1000)
    
    expect(callback).toHaveBeenCalledTimes(1)
  })
})
```

#### Mock Database (for Unit Tests)

```typescript
vi.mock('~/server/db', () => ({
  db: {
    user: {
      findUnique: vi.fn(),
      create: vi.fn(),
    },
  },
}))

describe('getUser', () => {
  it('should return user from database', async () => {
    const mockUser = { id: '1', email: 'test@example.com' }
    const { db } = await import('~/server/db')
    vi.mocked(db.user.findUnique).mockResolvedValue(mockUser)
    
    const user = await getUser('1')
    
    expect(db.user.findUnique).toHaveBeenCalledWith({ where: { id: '1' } })
    expect(user).toEqual(mockUser)
  })
})
```

### Mock Verification

Always verify mocks were called correctly:

```typescript
it('should call external service with correct parameters', async () => {
  const mockCall = vi.fn().mockResolvedValue({ success: true })
  externalService.call = mockCall
  
  await functionUnderTest({ id: '123', name: 'Test' })
  
  // Verify call count
  expect(mockCall).toHaveBeenCalledTimes(1)
  
  // Verify call arguments
  expect(mockCall).toHaveBeenCalledWith({ id: '123', name: 'Test' })
  
  // Verify call order (if multiple calls)
  expect(mockCall).toHaveBeenNthCalledWith(1, firstArg)
  expect(mockCall).toHaveBeenNthCalledWith(2, secondArg)
})
```

---

## Test Data Management

### Test Fixtures

Create reusable test data factories:

```typescript
// tests/fixtures/users.ts
export function createTestUser(overrides?: Partial<User>): User {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    createdAt: new Date(),
    ...overrides,
  }
}

export function createTestWorkspace(overrides?: Partial<Workspace>): Workspace {
  return {
    id: faker.string.uuid(),
    name: faker.company.name(),
    slug: faker.string.alphanumeric(10),
    createdAt: new Date(),
    ...overrides,
  }
}
```

### Test Database Setup

For integration tests, use test database:

```typescript
beforeAll(async () => {
  // Set up test database
  await setupTestDatabase()
})

afterAll(async () => {
  // Clean up test database
  await teardownTestDatabase()
})

beforeEach(async () => {
  // Clean tables before each test
  await cleanTestDatabase()
})
```

### Isolation

Each test should be independent:

```typescript
describe('userService', () => {
  let testUser: User
  let testWorkspace: Workspace

  beforeEach(async () => {
    // Create fresh test data for each test
    testWorkspace = await createTestWorkspace()
    testUser = await createTestUser({ workspaceId: testWorkspace.id })
  })

  afterEach(async () => {
    // Clean up after each test
    await deleteTestUser(testUser.id)
    await deleteTestWorkspace(testWorkspace.id)
  })

  it('should create user', async () => {
    // Uses fresh testUser and testWorkspace
  })

  it('should update user', async () => {
    // Uses fresh testUser and testWorkspace (different instances)
  })
})
```

---

## Edge Cases & Boundary Conditions

### Always Test Edge Cases

1. **Empty Inputs**
   ```typescript
   it('should handle empty array', () => {
     expect(processItems([])).toEqual([])
   })

   it('should handle empty string', () => {
     expect(validateInput('')).toBe(false)
   })

   it('should handle null input', () => {
     expect(processValue(null)).toBeNull()
   })
   ```

2. **Boundary Values**
   ```typescript
   it('should handle maximum value', () => {
     expect(processValue(Number.MAX_SAFE_INTEGER)).not.toThrow()
   })

   it('should handle minimum value', () => {
     expect(processValue(Number.MIN_SAFE_INTEGER)).not.toThrow()
   })

   it('should handle zero', () => {
     expect(divide(10, 0)).toThrow()
   })
   ```

3. **Extreme Values**
   ```typescript
   it('should handle very long strings', () => {
     const longString = 'a'.repeat(1000000)
     expect(processString(longString)).not.toThrow()
   })

   it('should handle very large arrays', () => {
     const largeArray = Array.from({ length: 100000 }, (_, i) => i)
     expect(processArray(largeArray)).not.toThrow()
   })
   ```

4. **Invalid Inputs**
   ```typescript
   it('should reject invalid email format', () => {
     expect(() => validateEmail('not-an-email')).toThrow()
   })

   it('should reject negative numbers when positive required', () => {
     expect(() => processQuantity(-1)).toThrow()
   })
   ```

5. **Unicode & Special Characters**
   ```typescript
   it('should handle Unicode characters', () => {
     expect(processString('报告.pdf')).not.toThrow()
   })

   it('should handle emoji', () => {
     expect(processString('📄.pdf')).not.toThrow()
   })

   it('should handle control characters', () => {
     expect(processString('file\r\nname.pdf')).toSanitizeControlChars()
   })
   ```

---

## Error Handling Tests

### Test All Error Paths

```typescript
describe('error handling', () => {
  it('should throw specific error for invalid input', () => {
    expect(() => processInput(null)).toThrow('Input is required')
  })

  it('should handle network errors gracefully', async () => {
    vi.mocked(fetch).mockRejectedValueOnce(new Error('Network error'))
    
    await expect(fetchData()).rejects.toThrow('Network error')
  })

  it('should return error response for API errors', async () => {
    vi.mocked(apiCall).mockResolvedValueOnce({ error: 'Not found', status: 404 })
    
    const result = await handleApiCall()
    
    expect(result.success).toBe(false)
    expect(result.error).toBe('Not found')
  })

  it('should log errors appropriately', async () => {
    const loggerSpy = vi.spyOn(logger, 'error')
    
    await expect(riskyOperation()).rejects.toThrow()
    
    expect(loggerSpy).toHaveBeenCalledWith(
      expect.objectContaining({ error: expect.any(Error) }),
      'Operation failed'
    )
  })
})
```

---

## Concurrency & Race Conditions

### Test Concurrent Operations

```typescript
describe('concurrent operations', () => {
  it('should handle concurrent updates correctly', async () => {
    const task = await createTask({ status: 'pending' })
    
    // Simulate concurrent updates
    const promises = [
      updateTask(task.id, { status: 'in-progress' }),
      updateTask(task.id, { status: 'completed' }),
      updateTask(task.id, { status: 'cancelled' }),
    ]
    
    await Promise.all(promises)
    
    // Verify final state is consistent
    const finalTask = await getTask(task.id)
    expect(['in-progress', 'completed', 'cancelled']).toContain(finalTask.status)
    // Or verify optimistic locking prevented conflicts
    expect(finalTask.version).toBeGreaterThan(task.version)
  })

  it('should prevent race conditions with locking', async () => {
    const resource = await createResource()
    
    const update1 = updateResource(resource.id, { value: 1 })
    const update2 = updateResource(resource.id, { value: 2 })
    
    await Promise.allSettled([update1, update2])
    
    // Only one update should succeed
    const final = await getResource(resource.id)
    expect([1, 2]).toContain(final.value)
  })
})
```

---

## Test Coverage Requirements

### Coverage Targets

- **Unit Tests**: 80%+ coverage for business logic
- **Integration Tests**: 70%+ coverage for API endpoints
- **Component Tests**: 60%+ coverage for UI components
- **Critical Paths**: 100% coverage (auth, payments, data mutations)

### What to Cover

✅ **Must Cover**:
- All business logic functions
- All error handling paths
- All edge cases and boundary conditions
- All security-critical code
- All data validation logic

❌ **Don't Need to Cover**:
- Simple getters/setters
- Trivial utility functions (if well-tested elsewhere)
- Third-party library code
- Generated code

### Coverage Tools

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        '**/*.config.{js,ts}',
        '**/*.d.ts',
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 75,
        statements: 80,
      },
    },
  },
})
```

---

## Test Naming Conventions

### Test Names Should Be Descriptive

```typescript
// ✅ GOOD: Describes what is being tested and expected outcome
it('should return error when user is not authorized', () => {})
it('should create task with correct default values', () => {})
it('should handle concurrent updates with optimistic locking', () => {})

// ❌ BAD: Vague or unclear
it('should work', () => {})
it('test create task', () => {})
it('handles error', () => {})
```

### Describe Blocks Should Group Related Tests

```typescript
describe('TaskService', () => {
  describe('createTask', () => {
    it('should create task with valid input', () => {})
    it('should reject invalid input', () => {})
    it('should assign default status', () => {})
  })

  describe('updateTask', () => {
    it('should update existing task', () => {})
    it('should reject update for non-existent task', () => {})
    it('should handle concurrent updates', () => {})
  })
})
```

---

## Test Organization

### Group Tests by Feature

```
tests/
├── unit/
│   ├── services/
│   │   ├── task-service.test.ts
│   │   └── user-service.test.ts
│   └── utils/
│       └── validation.test.ts
├── integration/
│   ├── api/
│   │   └── tasks.test.ts
│   └── database/
│       └── migrations.test.ts
└── e2e/
    ├── authentication.spec.ts
    └── task-management.spec.ts
```

### Use Test Helpers

```typescript
// tests/helpers/test-utils.ts
export async function createTestUserWithWorkspace() {
  const workspace = await createTestWorkspace()
  const user = await createTestUser({ workspaceId: workspace.id })
  return { user, workspace }
}

export function waitFor(condition: () => boolean, timeout = 5000) {
  const start = Date.now()
  while (!condition() && Date.now() - start < timeout) {
    // Poll condition
  }
  if (!condition()) {
    throw new Error('Condition not met within timeout')
  }
}
```

---

## Test Performance

### Keep Tests Fast

- Unit tests: < 10ms each
- Integration tests: < 1000ms each
- Component tests: < 100ms each
- E2E tests: < 30s each

### Optimize Slow Tests

1. **Use Test Database Instead of Real Database**
   ```typescript
   // ✅ GOOD: In-memory database for tests
   const testDb = new TestDatabase()
   
   // ❌ BAD: Real database connection
   const db = new Database(process.env.DATABASE_URL)
   ```

2. **Mock Slow Operations**
   ```typescript
   // ✅ GOOD: Mock file system
   vi.mock('fs/promises', () => ({
     readFile: vi.fn().mockResolvedValue('mock content'),
   }))
   ```

3. **Run Tests in Parallel**
   ```typescript
   // vitest.config.ts
   test: {
     pool: 'threads',
     poolOptions: {
       threads: {
         maxThreads: 8,
       },
     },
   }
   ```

---

## Verification with Verifier Subagent

**After completing test implementation, use `/verifier` subagent to validate**:

- **Test compliance**: Verify tests adhere to `/testing-guidelines`
  - Tests are in `/tests` directory at project root
  - Tests use Vitest framework
  - Tests are real (never rigged to pass)
  - Tests validate actual behavior
- **Test execution**: Verify tests are run and validated
  - Specific test files are run: `vitest run tests/path/to/specific.test.ts`
  - Tests pass with real assertions
  - No entire test suite runs during development
- **Test quality**: Verify tests are well-written
  - Tests are deterministic and independent
  - Tests clean up after themselves
  - Edge cases and error paths are tested
- **Integration**: Verify tests integrate properly
  - Tests work with existing codebase
  - No breaking changes introduced
  - Test helpers and fixtures are properly set up

**Command**: `/verifier` (delegate to verifier subagent)

**Reference**: `.cursor/agents/verifier.md` for complete verification guidelines.

## CI/CD Integration

### ⚠️ CRITICAL: Test Execution Rules

**During Development (Local)**:
- **NEVER run `npm test`, `npm run test`, `vitest run` (without file path)**
- **ONLY run specific test files**: `vitest run path/to/your.test.ts`
- **Use watch mode for specific files**: `vitest path/to/your.test.ts`
- **Validate only the tests you created or modified**
- **After implementation**: Use `/verifier` subagent to validate test compliance

**In CI/CD (Automated)**:
- Full test suite runs are acceptable ONLY in CI/CD pipelines
- CI/CD may run `npm test` or equivalent to validate all tests
- This is the ONLY exception to the "never run full suite" rule

### Test Commands

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:unit": "vitest run tests/unit",
    "test:integration": "vitest run tests/integration",
    "test:e2e": "playwright test"
  }
}
```

**⚠️ IMPORTANT**: The `test` script above is for CI/CD only. During development, always run:
- `vitest run path/to/specific.test.ts` - Run specific test file
- `vitest path/to/specific.test.ts` - Watch mode for specific file
- `vitest run --grep "test name pattern"` - Run tests matching pattern

### CI Pipeline

```yaml
# .github/workflows/test.yml
- name: Run unit tests
  run: npm run test:unit

- name: Run integration tests
  run: npm run test:integration
  env:
    DATABASE_URL: ${{ secrets.TEST_DATABASE_URL }}

- name: Run E2E tests
  run: npm run test:e2e

- name: Check coverage
  run: npm run test:coverage
```

---

## Anti-Patterns to Avoid

### ❌ Never Rig Tests to Pass

```typescript
// ❌ WRONG: Mocking the function being tested
const calculateTotal = vi.fn(() => 20)
expect(calculateTotal([1, 2, 3])).toBe(20)

// ❌ WRONG: Assertion that always passes
expect(true).toBe(true)
expect(result).toBeDefined()

// ❌ WRONG: Skipping real assertions
it('should calculate total', () => {
  const result = calculateTotal([1, 2, 3])
  // Missing assertion - test always passes
})

// ❌ WRONG: Catching and ignoring errors
try {
  riskyOperation()
} catch (e) {
  // Ignoring error - test passes even when it shouldn't
}
```

### ❌ Never Write Flaky Tests

```typescript
// ❌ WRONG: Time-dependent without mocking
it('should process after delay', async () => {
  await processWithDelay(1000)
  expect(processed).toBe(true) // May fail if slow
})

// ✅ GOOD: Mock time
it('should process after delay', async () => {
  vi.useFakeTimers()
  const promise = processWithDelay(1000)
  vi.advanceTimersByTime(1000)
  await promise
  expect(processed).toBe(true)
})
```

### ❌ Never Share Mutable State

```typescript
// ❌ WRONG: Shared mutable state
let sharedData = []

describe('tests', () => {
  it('test 1', () => {
    sharedData.push(1) // Modifies shared state
  })

  it('test 2', () => {
    expect(sharedData).toEqual([]) // May fail if test 1 ran first
  })
})

// ✅ GOOD: Fresh state per test
describe('tests', () => {
  let testData: number[]

  beforeEach(() => {
    testData = [] // Fresh state for each test
  })

  it('test 1', () => {
    testData.push(1)
  })

  it('test 2', () => {
    expect(testData).toEqual([]) // Always fresh
  })
})
```

### ❌ Never Test Implementation Details

```typescript
// ❌ WRONG: Testing implementation
it('should call internal method', () => {
  const spy = vi.spyOn(obj, 'internalMethod')
  obj.publicMethod()
  expect(spy).toHaveBeenCalled() // Tests how it works, not what it does
})

// ✅ GOOD: Testing behavior
it('should return correct result', () => {
  const result = obj.publicMethod()
  expect(result).toBe(expectedResult) // Tests what it does
})
```

### ❌ Never Run Entire Test Suite During Development

```bash
# ❌ WRONG: Running entire test suite
npm test
npm run test
vitest run
vitest run --coverage

# ✅ GOOD: Running specific test files
vitest run tests/unit/my-function.test.ts
vitest run tests/integration/api-routes.test.ts
vitest tests/unit/my-function.test.ts  # Watch mode for specific file

# ✅ GOOD: Running tests matching pattern
vitest run --grep "should handle errors"
```

**Why**: Running the entire suite wastes time, may expose unrelated failures, and slows down development. Only run the tests you're actively working on.

---

## Common Mistakes

### Mistake 1: Not Testing Error Cases

```typescript
// ❌ BAD: Only tests happy path
it('should create user', async () => {
  const user = await createUser({ email: 'test@example.com' })
  expect(user.email).toBe('test@example.com')
})

// ✅ GOOD: Tests both success and error cases
it('should create user with valid email', async () => {
  const user = await createUser({ email: 'test@example.com' })
  expect(user.email).toBe('test@example.com')
})

it('should reject invalid email', async () => {
  await expect(createUser({ email: 'invalid' })).rejects.toThrow('Invalid email')
})
```

### Mistake 2: Testing Multiple Things in One Test

```typescript
// ❌ BAD: Tests multiple behaviors
it('should create and update user', async () => {
  const user = await createUser({ email: 'test@example.com' })
  expect(user.email).toBe('test@example.com')
  
  const updated = await updateUser(user.id, { name: 'Test' })
  expect(updated.name).toBe('Test')
})

// ✅ GOOD: One behavior per test
it('should create user', async () => {
  const user = await createUser({ email: 'test@example.com' })
  expect(user.email).toBe('test@example.com')
})

it('should update user', async () => {
  const user = await createUser({ email: 'test@example.com' })
  const updated = await updateUser(user.id, { name: 'Test' })
  expect(updated.name).toBe('Test')
})
```

### Mistake 3: Not Cleaning Up Test Data

```typescript
// ❌ BAD: Leaves test data in database
it('should create task', async () => {
  const task = await createTask({ title: 'Test' })
  expect(task.title).toBe('Test')
  // Task remains in database
})

// ✅ GOOD: Cleans up after test
it('should create task', async () => {
  const task = await createTask({ title: 'Test' })
  expect(task.title).toBe('Test')
  
  await deleteTask(task.id) // Clean up
})

// Or use beforeEach/afterEach
beforeEach(async () => {
  await cleanTestDatabase()
})
```

### Mistake 4: Running Entire Test Suite

```bash
# ❌ BAD: Running entire test suite during development
npm test
npm run test
vitest run  # Without file path

# ✅ GOOD: Running only specific test files
vitest run tests/unit/my-function.test.ts
vitest tests/integration/api-routes.test.ts  # Watch mode

# ✅ GOOD: Running tests matching pattern
vitest run --grep "should validate input"
```

**Why This Matters**:
- Running entire suite wastes time (minutes vs seconds)
- May expose unrelated failures that distract from your work
- Slows down development feedback loop
- Only CI/CD should run full test suite

### Mistake 5: Wrong Test Location or Framework

```typescript
// ❌ BAD: Tests co-located with source
src/
├── components/
│   └── __tests__/
│       └── TaskCard.test.tsx  // Wrong location

// ❌ BAD: Using Jest instead of Vitest
import { describe, it, expect } from '@jest/globals'  // Wrong framework

// ✅ GOOD: Tests in /tests root directory
tests/
├── unit/
│   └── task-service.test.ts
└── component/
    └── TaskCard.test.tsx

// ✅ GOOD: Using Vitest
import { describe, it, expect } from 'vitest'  // Correct framework
```

**Why This Matters**:
- Consistent test location makes tests easier to find and maintain
- Vitest is faster and has better TypeScript support
- Centralized test directory improves organization
- Easier to configure and run tests consistently

---

## Testing Checklist

Before submitting code, verify:

### Planning (If Creating Plans)
- [ ] **Plan explicitly includes testing rules and guidelines** (if plan involves testing)
- [ ] Plan specifies test types to be used
- [ ] Plan includes test execution rules (never run full suite)
- [ ] Plan specifies test location requirement (`/tests` at root using Vitest)
- [ ] Plan specifies test coverage requirements
- [ ] Plan includes edge case and error handling requirements

### Test Location & Framework
- [ ] **All tests are in `/tests` directory at project root** (not co-located with source)
- [ ] **All tests use Vitest framework** (not Jest, Mocha, or other frameworks)
- [ ] Test files follow correct naming pattern (`*.test.{ts,tsx}` or `*.spec.ts`)
- [ ] Tests are organized by type in subdirectories (`tests/unit/`, `tests/integration/`, etc.)

### Test Execution
- [ ] **Only ran specific test file(s) you created/modified** (never `npm test` or `vitest run` without file path)
- [ ] Used correct command: `vitest run tests/path/to/test.test.ts`
- [ ] Validated the specific tests pass
- [ ] Did not run entire test suite during development
- [ ] **Used `/verifier` subagent** to validate test compliance after implementation

### Test Quality
- [ ] All tests are real (not rigged to pass)
- [ ] Tests validate actual behavior, not just that code runs
- [ ] Tests are deterministic (same inputs = same outputs)
- [ ] Tests are independent (can run in any order)
- [ ] Tests clean up after themselves

### Test Coverage
- [ ] All business logic is tested
- [ ] All error cases are tested
- [ ] All edge cases are tested
- [ ] Critical paths have 100% coverage
- [ ] Security-critical code is tested

### Test Structure
- [ ] Tests follow AAA pattern (Arrange-Act-Assert)
- [ ] Test names clearly describe what they test
- [ ] Tests are well-organized and grouped logically
- [ ] Test helpers are used for common setup

### Mocking
- [ ] External dependencies are mocked appropriately
- [ ] The code being tested is never mocked
- [ ] Mocks are verified (called with correct arguments)
- [ ] Time-dependent code uses fake timers

### Edge Cases
- [ ] Empty inputs are tested
- [ ] Boundary values are tested
- [ ] Invalid inputs are tested
- [ ] Unicode and special characters are tested
- [ ] Concurrent operations are tested (if applicable)

### Performance
- [ ] Tests run in reasonable time
- [ ] Slow operations are mocked or optimized
- [ ] Tests don't have unnecessary delays
- [ ] **For web performance tests**: Used Chrome DevTools MCP tools (`performance_start_trace`, `performance_stop_trace`, `performance_analyze_insight`)
- [ ] **For web performance tests**: Measured baseline, set targets, validated improvements

### Documentation
- [ ] Complex tests have comments explaining why
- [ ] Test data factories are documented
- [ ] Test helpers are documented

---

## Summary

### Key Takeaways

1. **Tests Must Be Real**: Never rig tests to pass. Every test must validate actual behavior.

2. **Never Run Entire Test Suite**: Only run specific test files you create or modify. Never run `npm test` or `vitest run` without a file path during development.

3. **All Tests in `/tests` Root Using Vitest**: All tests MUST be located in `/tests` directory at project root (not co-located with source) and MUST use Vitest framework (not Jest, Mocha, or other frameworks).

4. **Plans Must Include Testing Rules**: When creating plans that involve testing, the plan MUST explicitly include testing rules and guidelines to ensure they are never overlooked.

5. **Test Behavior, Not Implementation**: Focus on what the code does, not how it does it.

6. **Cover Edge Cases**: Always test empty inputs, boundary values, invalid inputs, and error cases.

7. **Keep Tests Fast**: Optimize slow tests by mocking external dependencies and using test databases.

8. **Maintain Independence**: Each test should be able to run in isolation without depending on other tests.

9. **Clean Up**: Always clean up test data and restore mocks after each test.

10. **Be Specific**: Use specific assertions that validate exact behavior, not just truthiness.

11. **Test Error Paths**: Don't just test the happy path - test all error cases and edge conditions.

12. **Use Chrome DevTools MCP for Web Performance**: When testing web page performance, use Chrome DevTools MCP tools to measure Core Web Vitals, network requests, and validate improvements.

13. **Verify with Verifier Subagent**: After completing test implementation, use `/verifier` subagent to validate test compliance, quality, and integration.

---

**Remember**: The goal of testing is to catch bugs before they reach production. Rigged tests that always pass provide false confidence and waste time. Real tests that validate actual behavior catch real bugs and provide real confidence. **All tests must be in `/tests` at project root using Vitest. When planning work that involves testing, always include testing rules and guidelines in the plan to ensure they are never forgotten. For web performance testing, use Chrome DevTools MCP tools. After implementation, use `/verifier` subagent to validate test compliance.**
