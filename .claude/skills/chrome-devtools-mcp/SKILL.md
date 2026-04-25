---

## name: chrome-devtools-mcp
description: Use Chrome DevTools MCP for performance measurement, debugging, and TDD workflows. Measure performance issues, identify bottlenecks, fix problems, and validate improvements using Chrome DevTools automation. Use when working on performance issues, debugging browser behavior, measuring page load times, analyzing network requests, validating performance fixes, or debugging UI issues.

# Chrome DevTools MCP for Performance, Debugging & TDD

When working on performance issues or debugging browser behavior, use Chrome DevTools MCP tools to measure, identify bottlenecks, fix problems, and validate improvements.

## Quick Reference: Common Debugging Patterns

**Element Selection & Interaction:**

- ✅ **Click checkbox in table**: Use `[role="checkbox"]` selector, filter by `aria-label` to exclude "Select all"
- ✅ **Click button by text**: `Array.from(document.querySelectorAll('button')).find(btn => btn.textContent.includes('Delete'))`
- ✅ **Find modal**: `document.querySelector('[role="dialog"][aria-modal="true"]')`
- ✅ **Wait after interaction**: Use promises in `evaluate_script` with `setTimeout` to wait for state changes

**Data Consistency Investigation:**

- ✅ **Find duplicate records**: `SELECT ... GROUP BY ... HAVING COUNT(*) > 1`
- ✅ **Check disabled elements**: Use `evaluate_script` to inspect `disabled` attribute and related count badges
- ✅ **Verify Redux state**: Access `window.__REDUX_DEVTOOLS_EXTENSION__()?.getState()` to compare with database
- ✅ **Cross-reference tables**: Use JOINs to see complete data relationships (boards → columns → cards)

**Debugging Workflow:**

1. `take_screenshot` - See the problem visually
2. `take_snapshot` - Get DOM structure with UIDs
3. `list_console_messages` - Check for JavaScript errors
4. `list_network_requests` - Verify API calls were made
5. `execute_sql` - Query database to verify data exists (source of truth)
6. `evaluate_script` - Inspect Redux/component state and compare with database
7. Check for data consistency issues (duplicates, orphaned records)
8. Fix code, reload with `navigate_page` (type: "reload", ignoreCache: true)
9. Verify fix with screenshot/snapshot

**Page Stability:**

- After `navigate_page` or reload, wait 2-3 seconds with `Bash` sleep before interacting
- If you get "Execution context was destroyed", the page navigated - wait and retry
- For React apps, wait for hydration: look for console logs or use `evaluate_script` to check `window.__REACT_DEVTOOLS_GLOBAL_HOOK__` 

## UI Debugging Workflow

Use this workflow when debugging UI issues (components not appearing, incorrect data displayed, interactions not working).

### Step 1: Visual Inspection

**Take screenshot first** to see what the user sees:

```typescript
take_screenshot()
```

**When to use**:

- Before starting any debugging (baseline)
- After making changes (verify fix)
- When reporting issues to user
- When comparing before/after states

### Step 2: DOM Structure Analysis

**Take snapshot** to get DOM structure with UIDs:

```typescript
take_snapshot()
```

**What you get**:

- Element hierarchy with `uid=XX_YY` identifiers
- ARIA roles, labels, descriptions
- Text content of elements
- Form input states (checked, disabled, etc.)

**Use snapshot output to**:

- Find elements by text content
- Verify modal/dialog presence (`[role="dialog"]`)
- Check button states (disabled vs enabled)
- Identify form controls and their values

**Note**: Snapshot output can be very large. If truncated, use `Grep` to search the snapshot file for specific content.

### Step 3: Check for Errors

**List console messages** to find JavaScript errors:

```typescript
list_console_messages({
  types: ["error", "warn"],
  pageSize: 20
})
```

**Look for**:

- React errors (hydration mismatches, invalid hooks, etc.)
- Network errors (CORS, 404s, 500s)
- Uncaught exceptions
- Deprecation warnings

### Step 4: Verify Network Requests

**List network requests** to ensure API calls succeeded:

```typescript
list_network_requests({
  resourceTypes: ["fetch", "xhr"],
  pageSize: 20
})
```

**Check**:

- Request was made (verify URL and request ID)
- Response status (200 vs 404/500)
- Request payload (check URL parameters)

**IMPORTANT LIMITATION**: Response bodies are often not available after the request completes. If you need to inspect response data:

1. **Option A**: Look for the data in React DevTools state (via evaluate_script)
2. **Option B**: Query the database directly if Supabase MCP is available
3. **Option C**: Add console.log in the component to log response data

**To decode URL parameters**:

```javascript
// In evaluate_script
const url = "http://localhost:3000/api/trpc/...?input=%7B%220%22%3A..."
const params = new URLSearchParams(new URL(url).search)
const input = JSON.parse(decodeURIComponent(params.get('input')))
return input
```

### Step 5: Inspect Component State

**Evaluate script** to check specific state:

```typescript
evaluate_script({
  function: `() => {
    // Check if modal is open
    const modal = document.querySelector('[role="dialog"][aria-modal="true"]')
    return {
      modalFound: !!modal,
      modalText: modal?.textContent.substring(0, 200)
    }
  }`
})
```

**Common patterns**:

- Check React component state: `window.__REACT_DEVTOOLS_GLOBAL_HOOK__`
- Find elements and verify properties
- Trigger interactions and return results using promises
- Extract data from the page for analysis

### Step 6: Fix and Validate

1. Make code changes
2. Let Next.js rebuild (wait 3-5 seconds with `Bash sleep 5`)
3. Reload page: `navigate_page({ type: "reload", ignoreCache: true })`
4. Wait for page to stabilize (2-3 seconds)
5. Repeat steps 1-5 to verify fix

## Common UI Debugging Patterns

### Pattern: Click Checkbox in Table

**Goal**: Select a row in a data table

**Solution**:

```typescript
evaluate_script({
  function: `() => {
    // Find all checkboxes, exclude "Select all"
    const rowCheckboxes = Array.from(document.querySelectorAll('[role="checkbox"]'))
      .filter(cb => cb.getAttribute('aria-label') !== 'Select all');

    if (rowCheckboxes.length === 0) {
      return { error: 'No row checkboxes found' };
    }

    // Click the first row checkbox
    rowCheckboxes[0].click();

    return { success: true, checked: rowCheckboxes[0].getAttribute('aria-checked') };
  }`
})
```

### Pattern: Find and Click Button

**Goal**: Click a button that contains specific text

**Solution**:

```typescript
evaluate_script({
  function: `() => {
    const deleteBtn = Array.from(document.querySelectorAll('button')).find(btn =>
      btn.textContent.includes('Delete') && !btn.disabled
    );

    if (!deleteBtn) {
      return { error: 'Button not found or disabled' };
    }

    deleteBtn.click();
    return { success: true };
  }`
})
```

### Pattern: Wait for Modal to Appear

**Goal**: Click a button and wait for a modal to open

**Solution**:

```typescript
evaluate_script({
  function: `() => {
    const button = document.querySelector('button.open-modal');
    button.click();

    // Wait for modal with promise
    return new Promise(resolve => {
      setTimeout(() => {
        const modal = document.querySelector('[role="dialog"][aria-modal="true"]');
        resolve({
          modalAppeared: !!modal,
          modalTitle: modal?.querySelector('h2')?.textContent
        });
      }, 500); // Wait 500ms for modal to appear
    });
  }`
})
```

### Pattern: Find Row in Table by Text

**Goal**: Find and interact with a specific table row

**Solution**:

```typescript
evaluate_script({
  function: `() => {
    const rows = Array.from(document.querySelectorAll('tr'));

    const targetRow = rows.find(row =>
      row.textContent.includes('Updated the Supplier dropdown')
    );

    if (!targetRow) {
      return { error: 'Row not found', totalRows: rows.length };
    }

    // Find checkbox in this row
    const checkbox = targetRow.querySelector('[role="checkbox"]');
    if (checkbox) {
      checkbox.click();
    }

    return { success: true };
  }`
})
```

### Pattern: Inspect Modal Content

**Goal**: Get text and buttons from an open modal

**Solution**:

```typescript
evaluate_script({
  function: `() => {
    const modal = document.querySelector('[role="dialog"][aria-modal="true"]');
    if (!modal) {
      return { error: 'Modal not found' };
    }

    const buttons = Array.from(modal.querySelectorAll('button')).map(btn => ({
      text: btn.textContent.trim(),
      disabled: btn.disabled,
      ariaLabel: btn.getAttribute('aria-label')
    }));

    return {
      modalFound: true,
      title: modal.querySelector('h1, h2, h3')?.textContent,
      buttons: buttons,
      bodyText: modal.textContent.substring(0, 500)
    };
  }`
})
```

### Pattern: Debug Redux/State Management Issues

**Goal**: Verify what data is in Redux/Zustand store vs what's displayed in UI

**When to use**: When UI appears wrong but database has correct data - the issue is likely in state management or selectors

**Investigation approach**:

```typescript
// 1. Access Redux store from window (if Redux DevTools is available)
evaluate_script({
  function: `() => {
    // For Redux
    const reduxState = window.__REDUX_DEVTOOLS_EXTENSION__?.()?.getState?.();

    // For Zustand (if exposed)
    // const zustandState = window.__ZUSTAND_STORE__?.getState?.();

    if (!reduxState) {
      return { error: 'Redux store not accessible' };
    }

    // Navigate to the slice you're debugging
    const kanbanState = reduxState?.kanban;

    return {
      // Check what's in the store
      boards: kanbanState?.boards ? Object.keys(kanbanState.boards).length : 0,
      currentBoardId: kanbanState?.currentBoardId,
      archivedCards: kanbanState?.archivedCards?.length || 0,

      // Get first few items for inspection
      sampleArchivedCards: kanbanState?.archivedCards?.slice(0, 3),

      // Check if board data exists for current board
      currentBoardExists: kanbanState?.currentBoardId ?
        !!kanbanState?.boards?.[kanbanState.currentBoardId] : false
    };
  }`
})

// 2. If Redux DevTools not available, look for store in React component
evaluate_script({
  function: `() => {
    // Find a component that should have access to the store
    const boardElement = document.querySelector('[data-board-id], .kanban-board');
    if (!boardElement) {
      return { error: 'Board element not found' };
    }

    // Access React Fiber to get props/state
    const fiberKey = Object.keys(boardElement).find(key => key.startsWith('__reactFiber'));
    const fiber = boardElement[fiberKey];

    // Navigate up the fiber tree to find provider or component with store
    let current = fiber;
    let depth = 0;
    while (current && depth < 20) {
      const props = current.memoizedProps;
      const state = current.memoizedState;

      // Look for store-related props
      if (props?.store || props?.archivedCards || state?.archivedCards) {
        return {
          found: true,
          componentType: current.type?.name || 'anonymous',
          archivedCardsFromProps: props?.archivedCards?.length,
          archivedCardsFromState: state?.archivedCards?.length,
          sampleCards: (props?.archivedCards || state?.archivedCards)?.slice(0, 2)
        };
      }

      current = current.return;
      depth++;
    }

    return { error: 'Could not find store in component tree' };
  }`
})

// 3. Test selectors directly (if you know the selector logic)
evaluate_script({
  function: `() => {
    // Simulate what the selector should do
    // Example: selectArchivedCardsByColumn selector

    const reduxState = window.__REDUX_DEVTOOLS_EXTENSION__?.()?.getState?.();
    if (!reduxState) return { error: 'No Redux state' };

    const kanbanState = reduxState?.kanban;
    const currentBoardId = kanbanState?.currentBoardId;

    // Manually run selector logic to see what it returns
    const allCards = kanbanState?.cards || [];
    const archivedCards = allCards.filter(card =>
      card.boardId === currentBoardId && card.archivedAt !== null
    );

    // Group by column like the selector does
    const grouped = archivedCards.reduce((acc, card) => {
      const columnId = card.columnId || 'unknown';
      if (!acc[columnId]) {
        acc[columnId] = [];
      }
      acc[columnId].push(card);
      return acc;
    }, {});

    return {
      totalArchivedCards: archivedCards.length,
      groupedByColumn: Object.keys(grouped).length,
      columns: Object.keys(grouped),
      // Check if selector is filtering out cards correctly
      selectorWorking: archivedCards.length > 0
    };
  }`
})
```

**Compare Redux state with database**:

```sql
-- Query database to see source of truth
SELECT
  kc.id,
  kc.name,
  kc."boardId",
  kc."columnId",
  kc."archivedAt"
FROM "KanbanCard" kc
WHERE kc."boardId" = 'xxx'
  AND kc."archivedAt" IS NOT NULL
ORDER BY kc."archivedAt" DESC;
```

```typescript
// Compare with Redux state
evaluate_script({
  function: `() => {
    const reduxState = window.__REDUX_DEVTOOLS_EXTENSION__?.()?.getState?.();
    const kanbanCards = reduxState?.kanban?.cards || [];

    const archivedInRedux = kanbanCards.filter(c => c.archivedAt !== null);

    return {
      reduxCount: archivedInRedux.length,
      // If DB shows 7 but Redux shows 0, Redux state is stale
      reduxIds: archivedInRedux.map(c => c.id),
      reduxBoardIds: [...new Set(archivedInRedux.map(c => c.boardId))]
    };
  }`
})
```

**Real example - Archive dropdown issue**:

- **Database**: 7 archived cards exist on board `cmjix4cty0005jo047oa90xbw`
- **Redux selector**: `selectArchivedCardsByColumn` was working correctly
- **Root cause**: NOT a selector issue - the issue was that the wrong board ID was being queried
- **The bug**: Duplicate boards in database, `findFirst()` without `orderBy` returned different boards
- **Lesson**: Don't assume the selector is broken - verify the input data is correct first

**Debugging checklist for state management issues**:

1. ✅ Query database to verify data exists (source of truth)
2. ✅ Check network request to see what parameters were sent
3. ✅ Inspect Redux/Zustand store to see what data was loaded
4. ✅ Compare database IDs with Redux IDs to find mismatch
5. ✅ Test selector logic manually to verify it's working correctly
6. ✅ Check if the issue is stale state vs incorrect query
7. ✅ Look for duplicate records in database causing wrong data to be fetched

**Common state management anti-patterns to look for**:

- Stale data in Redux (fetch succeeded but old data still showing)
- Selector filtering too aggressively (correct data in store, selector filters it out)
- Wrong slice/board ID being passed to selector
- Data fetched for one board but UI looking at different board
- Optimistic updates not being reverted on error
- Cache invalidation not happening after mutations

### Pattern: Check React Query/tRPC Data

**Goal**: Verify what data was fetched from an API

**Best approach**: Use database queries if Supabase MCP is available

```sql
-- Check if data exists in database
SELECT * FROM "KanbanCard"
WHERE "taskId" = 'cmkg9l3pu0003kv04981zl70o'
LIMIT 10;
```

**Why**: Network response bodies are often unavailable by the time you inspect them. Database queries give you the source of truth.

### Pattern: Debugging Data Consistency Issues

**Goal**: Investigate when UI shows unexpected or inconsistent data (e.g., dropdown only shows some items, data appears/disappears inconsistently)

**Root cause**: Often caused by duplicate database records or inconsistent query ordering

**Investigation workflow**:

```sql
-- 1. Check for duplicate records that might cause inconsistent selection
-- Example: Finding duplicate KanbanBoard records
SELECT
  "projectId",
  "objectiveId",
  "taskId",
  COUNT(*) as count,
  array_agg(id ORDER BY "createdAt" ASC) as board_ids,
  array_agg("createdAt" ORDER BY "createdAt" ASC) as created_dates
FROM "KanbanBoard"
WHERE "archivedAt" IS NULL
GROUP BY "projectId", "objectiveId", "taskId"
HAVING COUNT(*) > 1;

-- 2. Compare data distribution across duplicate records
-- Example: Checking which board has the archived cards
SELECT
  kb.id as board_id,
  kb."createdAt" as board_created,
  COUNT(CASE WHEN kc."archivedAt" IS NULL THEN 1 END) as active_cards,
  COUNT(CASE WHEN kc."archivedAt" IS NOT NULL THEN 1 END) as archived_cards
FROM "KanbanBoard" kb
LEFT JOIN "KanbanCard" kc ON kc."boardId" = kb.id
WHERE kb."projectId" = 'xxx'
  AND kb."objectiveId" = 'yyy'
  AND kb."taskId" IS NULL
GROUP BY kb.id, kb."createdAt"
ORDER BY kb."createdAt" ASC;

-- 3. Identify which record is being used by the application
-- Look for findFirst() queries without orderBy - these are non-deterministic
```

**Real example**: Archive dropdown only showed some archived cards because:

- 5 duplicate `KanbanBoard` records existed with same `(projectId, objectiveId, taskId)`
- Oldest board had 7 archived cards, newer boards had 0
- `findFirst()` query without `orderBy` returned different boards inconsistently

**Fix pattern**:

```typescript
// Before (non-deterministic):
const board = await db.kanbanBoard.findFirst({
  where: { projectId, objectiveId, taskId: null }
})

// After (consistent):
const board = await db.kanbanBoard.findFirst({
  where: { projectId, objectiveId, taskId: null },
  orderBy: { createdAt: 'asc' } // Always use oldest record
})

// Best (prevent duplicates):
// Add unique constraint in migration:
// UNIQUE(projectId, objectiveId, taskId, archivedAt) WHERE archivedAt IS NULL
```

**When to use this pattern**:

- UI shows different data on each page refresh
- Dropdown/list only shows subset of expected items
- Data appears on one board/view but not another
- User reports "sometimes it works, sometimes it doesn't"

### Pattern: Handle Page Navigation/Reload

**Goal**: Reload page and interact with it safely

**Solution**:

```typescript
// 1. Trigger reload
navigate_page({ type: "reload", ignoreCache: true })

// 2. Wait for page to stabilize (use Bash sleep)
// In a separate tool call:
Bash({ command: "sleep 3" })

// 3. Now safe to interact
evaluate_script({ function: "() => { /* your code */ }" })
```

**Why**: After navigation, the execution context is destroyed. You must wait for the new page to fully load before running scripts.

## Troubleshooting Common Errors

### Error: "Execution context was destroyed"

**Cause**: The page navigated or reloaded while you were executing a script

**Solution**:

1. Wait 2-3 seconds with `Bash sleep 3`
2. Re-run your script
3. For future calls, add waiting after navigation/reload

**Example**:

```typescript
// After this:
navigate_page({ type: "reload", ignoreCache: true })

// Add this before interacting:
Bash({ command: "sleep 3" })
```

### Error: "Element not found" or "null selector"

**Cause**: Element hasn't rendered yet, or selector is incorrect

**Solution**:

1. Take a `snapshot` to verify the element exists
2. Check the snapshot for the actual selector/structure
3. Use `wait_for` with text content to ensure element appears
4. Use more specific selectors (ARIA roles, data attributes)

**Example**:

```typescript
// Instead of:
document.querySelector('.submit-button')

// Use:
document.querySelector('button[type="submit"]')
// or
Array.from(document.querySelectorAll('button')).find(btn => btn.textContent.includes('Submit'))
```

### Error: "Button is disabled"

**Cause**: Button state depends on form validation or other conditions

**Solution**:

1. Take `screenshot` to verify visually
2. Use `evaluate_script` to check button's `disabled` attribute
3. Fill required form fields first
4. Check if checkbox/radio needs to be selected first

**Example**:

```typescript
evaluate_script({
  function: `() => {
    const deleteBtn = document.querySelector('button.delete');
    return {
      exists: !!deleteBtn,
      disabled: deleteBtn?.disabled,
      ariaDisabled: deleteBtn?.getAttribute('aria-disabled'),
      // Check what might enable it:
      checkboxChecked: document.querySelector('[role="checkbox"]')?.getAttribute('aria-checked')
    };
  }`
})
```

### Pattern: Investigating Disabled UI Elements in Detail

**Goal**: Understand why a button/element is disabled when you expect it to be enabled

**When to use**: When debugging reveals an element is disabled but the reason isn't obvious from the UI

**Investigation steps**:

```typescript
// 1. First, verify the element exists and check its basic state
evaluate_script({
  function: `() => {
    const archiveBtn = document.querySelector('[aria-label="View archived items"]');

    return {
      exists: !!archiveBtn,
      disabled: archiveBtn?.disabled,
      ariaDisabled: archiveBtn?.getAttribute('aria-disabled'),
      className: archiveBtn?.className,
      // Get the full element for inspection
      outerHTML: archiveBtn?.outerHTML.substring(0, 200)
    };
  }`
})

// 2. Check what data the button depends on (e.g., count badges, state)
evaluate_script({
  function: `() => {
    const archiveBtn = document.querySelector('[aria-label="View archived items"]');

    // Look for count badge or indicator
    const badge = archiveBtn?.querySelector('.badge, [class*="count"], [class*="badge"]');

    // Check if there's a tooltip explaining why it's disabled
    const title = archiveBtn?.getAttribute('title');
    const ariaDescription = archiveBtn?.getAttribute('aria-describedby');

    return {
      badgeText: badge?.textContent,
      badgeExists: !!badge,
      title: title,
      ariaDescription: ariaDescription,
      // Check related elements
      nearbyText: archiveBtn?.parentElement?.textContent.substring(0, 100)
    };
  }`
})

// 3. If button depends on data count, verify data exists in database
execute_sql({
  query: `
    SELECT COUNT(*) as archived_count
    FROM "KanbanCard"
    WHERE "boardId" = 'xxx'
      AND "archivedAt" IS NOT NULL;
  `
})
```

**Real example**: Archive button was disabled even though 7 archived cards existed:

- Button showed count badge "0" instead of "7"
- Database query confirmed 7 archived cards existed
- Root cause: Duplicate board records - UI was looking at wrong board (newer duplicate with 0 cards)
- Fix: Added `orderBy: { createdAt: 'asc' }` to ensure consistent board selection

**Common patterns for disabled buttons**:

```typescript
// Pattern 1: Count-based (button disabled when count === 0)
evaluate_script({
  function: `() => {
    const btn = document.querySelector('.archive-button');
    const badge = btn?.querySelector('[class*="badge"]');

    // Compare badge count with what should be there
    return {
      displayedCount: parseInt(badge?.textContent || '0'),
      // Get from React state if accessible
      // actualCount: window.__REACT_STATE__?.archivedCount
    };
  }`
})

// Pattern 2: Selection-based (button disabled until item selected)
evaluate_script({
  function: `() => {
    const deleteBtn = document.querySelector('[aria-label="Delete selected"]');
    const selectedCheckboxes = document.querySelectorAll('[role="checkbox"][aria-checked="true"]');

    return {
      buttonDisabled: deleteBtn?.disabled,
      selectedCount: selectedCheckboxes.length,
      // Button should be enabled if selectedCount > 0
      mismatch: deleteBtn?.disabled && selectedCheckboxes.length > 0
    };
  }`
})

// Pattern 3: Form validation (button disabled until form is valid)
evaluate_script({
  function: `() => {
    const submitBtn = document.querySelector('button[type="submit"]');
    const form = submitBtn?.closest('form');
    const requiredInputs = form?.querySelectorAll('[required]');

    const emptyRequired = Array.from(requiredInputs || []).filter(input => !input.value);

    return {
      buttonDisabled: submitBtn?.disabled,
      totalRequired: requiredInputs?.length,
      emptyRequired: emptyRequired.length,
      emptyFields: emptyRequired.map(input => input.name || input.id)
    };
  }`
})
```

**Debugging checklist**:

1. ✅ Verify element exists and is actually disabled
2. ✅ Check for count badges, tooltips, or aria-descriptions explaining why
3. ✅ Investigate what data/state the button depends on
4. ✅ Query database to verify expected data exists
5. ✅ Compare UI state with database state to find discrepancy
6. ✅ Look for duplicate records or inconsistent queries causing mismatch

### Issue: Network Response Body Not Available

**Symptom**: `get_network_request` returns `<not available anymore>`

**Why**: Browser discards response bodies after processing to save memory

**Solutions**:

1. **Use database queries**: If Supabase MCP available, query the DB directly for the data
2. **Check React state**: Use `evaluate_script` to inspect component state/props
3. **Add logging**: Temporarily add `console.log` to the component to log response data
4. **Reproduce request**: Make the request again with fresh context

**Example (database approach)**:

```sql
-- Instead of inspecting network response:
SELECT * FROM "KanbanBoard"
WHERE "projectId" = 'xxx' AND "objectiveId" = 'yyy'
LIMIT 10;
```

### Issue: Snapshot Output Too Large

**Symptom**: Snapshot file saved to disk, output truncated

**Solution**: Use `Grep` to search the snapshot file for specific content

```bash
grep -i "delete button" /path/to/snapshot-file.txt
grep -A 5 -B 5 "modal" /path/to/snapshot-file.txt
```

## Performance Measurement Workflow

### 1. Measure Baseline

**Goal**: Establish current performance metrics before making changes.

**Steps to execute**:

1. Use `navigate_page` with target URL to load the page
2. Call `performance_start_trace` to begin recording
3. Use interaction tools (`click`, `fill`, `hover`, etc.) to simulate user actions
4. Call `performance_stop_trace` to end recording
5. Call `performance_analyze_insight` to get actionable insights

**Key Metrics to Capture**:

- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)
- Time to Interactive (TTI)
- Total Blocking Time (TBT)
- Cumulative Layout Shift (CLS)
- Network request count and timing
- JavaScript execution time

### 2. Identify Issues

**After calling `performance_analyze_insight`, review insights for**:

- Long tasks blocking the main thread
- Large JavaScript bundles
- Slow network requests
- Layout shifts
- Memory leaks

**To check network requests**:

- Call `list_network_requests` to see all requests
- Call `get_network_request` with specific request ID to inspect details
- Look for: slow requests (>1s), large payloads, missing caching headers

**To check console**:

- Call `list_console_messages` to view errors and warnings
- Call `get_console_message` with message ID to inspect specific messages
- Look for: JavaScript errors, deprecation warnings, performance warnings

### 3. Fix Issues

Based on insights, implement fixes:

- Code splitting for large bundles
- Optimize images (lazy loading, proper formats)
- Add caching headers
- Reduce JavaScript execution time
- Fix layout shifts
- Optimize network requests

### 4. Validate Fixes

**After implementing fixes, re-measure**:

1. Use `navigate_page` to load the updated page
2. Call `performance_start_trace`, perform same actions, then `performance_stop_trace`
3. Call `performance_analyze_insight` and compare metrics with baseline
4. Verify improvements meet targets

**Success criteria to check**:

- Metrics improved by target percentage (e.g., 20% faster LCP)
- No regressions in other metrics
- Console errors resolved (verify with `list_console_messages`)
- Network requests optimized (verify with `list_network_requests`)

## TDD Workflow with Chrome DevTools MCP

### Red-Green-Refactor Cycle

**1. Red: Write failing performance test**

Define performance requirement (e.g., LCP < 2.5s), then:

- Call `navigate_page` to load the page
- Call `performance_start_trace`
- Call `wait_for` to ensure page is fully loaded
- Call `performance_stop_trace`
- Call `performance_analyze_insight`
- Check if LCP metric < 2500ms (test should fail initially)

**2. Green: Implement fix to pass test**

Make code changes to meet performance requirement, then re-run the measurement steps above.

**3. Refactor: Optimize while maintaining performance**

Improve code quality while keeping performance metrics passing.

### Example TDD Test Flow

**When testing homepage performance**:

1. Call `navigate_page` with homepage URL
2. Call `performance_start_trace`
3. Call `wait_for` with appropriate selector or timeout
4. Call `performance_stop_trace`
5. Call `performance_analyze_insight`
6. Extract LCP metric and assert it's < 2500ms
7. If failing: Use insights to identify bottleneck, implement fix
8. Re-run steps 1-6 to validate fix

## Key Tools Reference

### Performance Tools

`**performance_start_trace`**

- Starts recording performance trace
- Use before user interactions
- Captures: rendering, JavaScript execution, network activity

`**performance_stop_trace**`

- Stops recording
- Returns trace data
- Use after interactions complete

`**performance_analyze_insight**`

- Analyzes trace data
- Provides actionable insights
- Identifies bottlenecks and optimization opportunities

### Navigation Tools

`**navigate_page**`

- Navigate to URL
- Waits for navigation to complete
- Use for initial page load or navigation

`**wait_for**`

- Wait for conditions (selector, timeout, etc.)
- Use to ensure page is ready before measuring

### Network Tools

`**list_network_requests**`

- Lists all network requests
- Shows: URL, method, status, timing
- Use to identify slow requests

`**get_network_request**`

- Get details for specific request
- Shows: headers, response, timing breakdown
- Use to debug specific requests

### Debugging Tools

`**take_screenshot**`

- Capture visual state
- Use to verify UI or debug layout issues

`**list_console_messages**`

- View console output
- Shows: errors, warnings, logs
- Use to identify JavaScript issues

`**evaluate_script**`

- Execute JavaScript in page context
- Use to check state or trigger actions programmatically

## Common Performance Issues & Solutions

### Issue: Slow First Contentful Paint (FCP)

**To measure**:

- Call `navigate_page` to load page
- Call `performance_start_trace`
- Call `performance_stop_trace` after initial render
- Call `performance_analyze_insight` and extract FCP metric

**Common causes**:

- Large render-blocking CSS
- Slow server response
- Blocking JavaScript

**Solutions to implement**:

- Inline critical CSS
- Optimize server response time
- Defer non-critical JavaScript

### Issue: Large JavaScript Bundle

**To measure**:

- Call `list_network_requests` and filter for .js files
- Analyze bundle sizes from request details
- Call `performance_analyze_insight` and check JavaScript execution time

**Solutions to implement**:

- Code splitting
- Tree shaking
- Dynamic imports
- Remove unused dependencies

### Issue: Slow Network Requests

**To measure**:

- Call `list_network_requests`
- Identify slow requests (>1s) from timing data
- Call `get_network_request` with slow request IDs for details

**Solutions to implement**:

- Add caching headers
- Optimize API responses
- Use CDN for static assets
- Implement request deduplication

### Issue: Layout Shifts (CLS)

**To measure**:

- Call `performance_start_trace`, interact with page, then `performance_stop_trace`
- Call `performance_analyze_insight` and extract CLS metric
- Review trace for layout shift events

**Solutions to implement**:

- Set dimensions for images/iframes
- Reserve space for dynamic content
- Avoid inserting content above existing content

## Measurement Best Practices

### 1. Consistent Test Environment

- Use `resize_page` or `emulate` to set consistent viewport size
- Use `new_page` with isolated context for clean state between tests
- Consider using `emulate` for consistent device/network conditions

### 2. Multiple Measurements

- Run measurement workflow 3-5 times
- Calculate median or average of metrics
- Account for variance in results

### 3. Real User Scenarios

- Use interaction tools (`click`, `fill`, `hover`, `scroll`) to simulate real workflows
- Don't just measure initial page load - include user interactions
- Test complete user journeys, not isolated page loads

### 4. Monitor Trends

- Store baseline metrics for comparison
- Track metrics over time when making changes
- Set performance budgets and validate against them

## Example: Complete Performance Test Workflow

**When testing homepage performance, execute these steps**:

1. **Setup**: Call `navigate_page` with homepage URL
2. **Measure**:
  - Call `performance_start_trace`
  - Call `wait_for` with selector or timeout to ensure page loaded
  - Call `performance_stop_trace`
3. **Analyze**:
  - Call `performance_analyze_insight`
  - Extract LCP, FCP, TBT metrics from insights
  - Identify bottlenecks from insight recommendations
4. **Network**:
  - Call `list_network_requests`
  - Filter for slow (>1s) or large requests
  - Call `get_network_request` for details on problematic requests
  - Check for missing caching headers
5. **Console**:
  - Call `list_console_messages`
  - Filter for errors and warnings
  - Verify no JavaScript errors present
6. **Validate**: Check metrics meet thresholds
  - LCP < 2.5s
  - FCP < 1.8s
  - TBT < 300ms
  - No console errors
7. **Fix**: If failing, use insights to identify root cause and implement optimizations
8. **Re-test**: Repeat steps 1-6 to validate fix improved metrics

## Integration with Supabase MCP

When debugging UI issues where data isn't displaying correctly, **use Supabase MCP to query the database directly**. This is often faster and more reliable than trying to inspect network responses.

### When to Use Database Queries

✅ **Use database queries when**:

- Network response body shows `<not available anymore>`
- You need to verify if data actually exists
- You want to see the raw data structure
- You're debugging why a query returned no results

❌ **Don't use database queries when**:

- You need to debug the API query logic itself
- You want to see what parameters were sent
- You're testing authentication/permissions

### Example Debugging Flow

**Problem**: Modal shows "No Kanban cards found" but user says cards exist

**Solution**:

```typescript
// 1. Check network request to see what was sent
list_network_requests({ resourceTypes: ["fetch", "xhr"] })

// Request URL shows: taskId=cmkg9l3pu0003kv04981zl70o

// 2. Query database to verify cards exist
execute_sql({
  query: `
    SELECT kc.id, kc.name, kc."taskId", kc."columnId", kc."boardId", kc."archivedAt"
    FROM "KanbanCard" kc
    WHERE kc."taskId" = 'cmkg9l3pu0003kv04981zl70o'
    LIMIT 20
  `
})

// 3. If cards exist, check what board they belong to
execute_sql({
  query: `
    SELECT kb.id, kb."taskId", kb."objectiveId", kb."projectId"
    FROM "KanbanBoard" kb
    WHERE kb.id = 'cmjix4cty0005jo047oa90xbw'
  `
})

// 4. Compare with API request - found the bug!
// API request missing objectiveId parameter
```

### Common Database Queries for Debugging

**Check if related records exist**:

```sql
SELECT * FROM "KanbanCard"
WHERE "taskId" = 'xxx'
AND "archivedAt" IS NULL
LIMIT 10;
```

**Check board configuration**:

```sql
SELECT kb.id, kb."projectId", kb."objectiveId", kb."taskId",
       COUNT(kc.id) as card_count
FROM "KanbanBoard" kb
LEFT JOIN "KanbanCard" kc ON kc."boardId" = kb.id
WHERE kb."projectId" = 'xxx'
GROUP BY kb.id
LIMIT 10;
```

**Find records by text content**:

```sql
SELECT * FROM "ProjectTask"
WHERE name ILIKE '%Supplier dropdown%'
LIMIT 10;
```

### Advanced Database Investigation Patterns

**Cross-reference related tables to understand data relationships**:

```sql
-- Get complete picture of board, columns, and cards
SELECT
  kb.id as board_id,
  kb."createdAt" as board_created,
  kb."taskId",
  pt.name as task_name,
  kc.id as column_id,
  kc.name as column_name,
  COUNT(DISTINCT card.id) FILTER (WHERE card."archivedAt" IS NULL) as active_cards,
  COUNT(DISTINCT card.id) FILTER (WHERE card."archivedAt" IS NOT NULL) as archived_cards
FROM "KanbanBoard" kb
LEFT JOIN "ProjectTask" pt ON pt.id = kb."taskId"
LEFT JOIN "KanbanColumn" kc ON kc."boardId" = kb.id AND kc."archivedAt" IS NULL
LEFT JOIN "KanbanCard" card ON card."columnId" = kc.id
WHERE kb."projectId" = 'xxx'
  AND kb."objectiveId" = 'yyy'
  AND kb."archivedAt" IS NULL
GROUP BY kb.id, kb."createdAt", kb."taskId", pt.name, kc.id, kc.name
ORDER BY kb."createdAt" ASC, kc."orderKey" ASC;
```

**Detect duplicate records causing inconsistent behavior**:

```sql
-- Find duplicate boards (should have unique constraint but doesn't)
SELECT
  "projectId",
  "objectiveId",
  "taskId",
  COUNT(*) as duplicate_count,
  array_agg(id ORDER BY "createdAt" ASC) as board_ids,
  array_agg("createdAt" ORDER BY "createdAt" ASC) as created_at_times,
  MIN("createdAt") as oldest_created,
  MAX("createdAt") as newest_created
FROM "KanbanBoard"
WHERE "archivedAt" IS NULL
GROUP BY "projectId", "objectiveId", "taskId"
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Check data distribution across duplicates to see which is "active"
WITH duplicate_boards AS (
  SELECT unnest(ARRAY['board_id_1', 'board_id_2', 'board_id_3']) as board_id
)
SELECT
  db.board_id,
  kb."createdAt",
  COUNT(DISTINCT kc.id) as column_count,
  COUNT(DISTINCT card.id) FILTER (WHERE card."archivedAt" IS NULL) as active_cards,
  COUNT(DISTINCT card.id) FILTER (WHERE card."archivedAt" IS NOT NULL) as archived_cards,
  -- If all cards are on oldest board, it's the "real" one
  CASE
    WHEN kb."createdAt" = MIN(kb."createdAt") OVER () THEN 'OLDEST (likely correct)'
    ELSE 'newer duplicate'
  END as status
FROM duplicate_boards db
JOIN "KanbanBoard" kb ON kb.id = db.board_id
LEFT JOIN "KanbanColumn" kc ON kc."boardId" = kb.id
LEFT JOIN "KanbanCard" card ON card."columnId" = kc.id
GROUP BY db.board_id, kb."createdAt"
ORDER BY kb."createdAt" ASC;
```

**Investigate orphaned records (cards without valid board/column)**:

```sql
-- Find cards pointing to non-existent or archived columns
SELECT
  kc.id as card_id,
  kc.name as card_name,
  kc."columnId",
  kc."boardId",
  CASE
    WHEN col.id IS NULL THEN 'Column does not exist'
    WHEN col."archivedAt" IS NOT NULL THEN 'Column is archived'
    ELSE 'Column is valid'
  END as column_status,
  CASE
    WHEN board.id IS NULL THEN 'Board does not exist'
    WHEN board."archivedAt" IS NOT NULL THEN 'Board is archived'
    ELSE 'Board is valid'
  END as board_status
FROM "KanbanCard" kc
LEFT JOIN "KanbanColumn" col ON col.id = kc."columnId"
LEFT JOIN "KanbanBoard" board ON board.id = kc."boardId"
WHERE kc."archivedAt" IS NULL
  AND (col.id IS NULL OR col."archivedAt" IS NOT NULL OR board.id IS NULL OR board."archivedAt" IS NOT NULL);
```

**Verify data integrity with aggregation mismatches**:

```sql
-- Compare what UI thinks vs what database has
-- Example: Archive dropdown shows 0, but database has 7
SELECT
  kb.id as board_id,
  kb."createdAt",
  -- What the query should return
  (
    SELECT COUNT(*)
    FROM "KanbanCard" kc2
    JOIN "KanbanColumn" col2 ON col2.id = kc2."columnId"
    WHERE col2."boardId" = kb.id
      AND kc2."archivedAt" IS NOT NULL
  ) as archived_cards_via_join,
  -- Direct count on board
  (
    SELECT COUNT(*)
    FROM "KanbanCard" kc3
    WHERE kc3."boardId" = kb.id
      AND kc3."archivedAt" IS NOT NULL
  ) as archived_cards_direct,
  -- If these differ, there's data inconsistency
  CASE
    WHEN (
      SELECT COUNT(*) FROM "KanbanCard" kc2 JOIN "KanbanColumn" col2 ON col2.id = kc2."columnId"
      WHERE col2."boardId" = kb.id AND kc2."archivedAt" IS NOT NULL
    ) != (
      SELECT COUNT(*) FROM "KanbanCard" kc3
      WHERE kc3."boardId" = kb.id AND kc3."archivedAt" IS NOT NULL
    ) THEN 'MISMATCH - Data integrity issue'
    ELSE 'OK'
  END as integrity_check
FROM "KanbanBoard" kb
WHERE kb."projectId" = 'xxx'
  AND kb."objectiveId" = 'yyy';
```

**When to use these patterns**:

- UI shows unexpected counts or missing data
- Data appears in one view but not another
- Investigating "data disappeared" bugs
- Before adding unique constraints (find existing duplicates first)
- Debugging complex JOIN queries or aggregations
- Verifying data migration or consolidation scripts

## Advanced Debugging Techniques

### Using Promises in evaluate_script

When you need to wait for async operations or delayed UI updates:

```typescript
evaluate_script({
  function: `() => {
    return new Promise((resolve) => {
      // Click button
      const button = document.querySelector('.submit');
      button.click();

      // Wait for result
      setTimeout(() => {
        const successMessage = document.querySelector('.success-toast');
        resolve({
          success: !!successMessage,
          message: successMessage?.textContent
        });
      }, 1000);
    });
  }`
})
```

**Use cases**:

- Click button and wait for modal to appear
- Submit form and wait for success message
- Toggle switch and wait for state update
- Trigger action and wait for network request to complete

### Chaining Interactions Safely

When you need multiple sequential interactions:

```typescript
evaluate_script({
  function: `() => {
    return new Promise(async (resolve) => {
      // Step 1: Fill form
      const emailInput = document.querySelector('input[type="email"]');
      emailInput.value = 'test@example.com';

      // Step 2: Click submit
      const submitBtn = document.querySelector('button[type="submit"]');
      submitBtn.click();

      // Step 3: Wait for response
      await new Promise(r => setTimeout(r, 500));

      // Step 4: Check result
      const modal = document.querySelector('[role="dialog"]');
      resolve({
        modalAppeared: !!modal,
        modalTitle: modal?.querySelector('h2')?.textContent
      });
    });
  }`
})
```

### Extracting Complex Data Structures

When debugging component state or props:

```typescript
evaluate_script({
  function: `() => {
    // Find React component instance
    const element = document.querySelector('.my-component');

    // Access React Fiber to get props (advanced)
    const fiberKey = Object.keys(element).find(key => key.startsWith('__reactFiber'));
    const fiber = element[fiberKey];

    // Extract what you need
    return {
      props: fiber?.memoizedProps,
      state: fiber?.memoizedState,
      // Simplify complex objects
      taskIds: fiber?.memoizedProps?.taskIds,
      objectiveId: fiber?.memoizedProps?.objectiveId
    };
  }`
})
```

**Warning**: Accessing React internals is fragile and can break between React versions. Use only for debugging, not production code.

### Debugging Workflow Template

Copy this checklist when debugging a UI issue:

```
## Debugging: [Brief description of issue]

### 1. Visual Inspection
- [ ] take_screenshot - Capture current state
- [ ] Describe what's wrong visually

### 2. DOM Structure
- [ ] take_snapshot - Get DOM structure
- [ ] Verify element exists in snapshot
- [ ] Note element UIDs if needed

### 3. Console Errors
- [ ] list_console_messages (types: ["error", "warn"])
- [ ] Document any errors found

### 4. Network Requests
- [ ] list_network_requests (resourceTypes: ["fetch", "xhr"])
- [ ] Identify relevant API call (note reqid)
- [ ] Check request URL parameters
- [ ] Note: Response body likely unavailable

### 5. Database Verification (if applicable)
- [ ] execute_sql - Check if data exists
- [ ] Compare DB data with expected UI state
- [ ] Identify discrepancies

### 6. Component State
- [ ] evaluate_script - Inspect specific state
- [ ] Document findings

### 7. Root Cause
- [ ] Describe the bug
- [ ] Explain why it's happening

### 8. Fix Implementation
- [ ] Make code changes
- [ ] Bash sleep 5 - Wait for rebuild
- [ ] navigate_page (reload: true, ignoreCache: true)
- [ ] Bash sleep 3 - Wait for page load

### 9. Validation
- [ ] take_screenshot - Verify fix visually
- [ ] Repeat steps 2-6 to confirm fix
- [ ] Document results
```

## Summary

### UI Debugging Workflow

1. **Visual** → `take_screenshot` to see the problem
2. **Structure** → `take_snapshot` to get DOM hierarchy
3. **Errors** → `list_console_messages` to find JS errors
4. **Network** → `list_network_requests` to verify API calls
5. **Data** → `execute_sql` (Supabase) to check database (source of truth)
6. **State** → `evaluate_script` to inspect Redux/component state
7. **Data Consistency** → Check for duplicates with `GROUP BY ... HAVING COUNT(*) > 1`
8. **Fix** → Make changes, reload, wait, validate

### Performance Workflow

1. **Measure** → Establish baseline metrics
2. **Identify** → Find bottlenecks and issues
3. **Fix** → Implement optimizations
4. **Validate** → Re-measure to confirm improvements

### Essential Tools

**UI Debugging**:

- `take_screenshot` - Visual inspection
- `take_snapshot` - DOM structure with UIDs
- `evaluate_script` - Run JS in page context, use promises for async
- `list_console_messages` - Find errors/warnings
- `list_network_requests` - Verify API calls (note: response bodies often unavailable)
- `execute_sql` (Supabase MCP) - Query database directly when network responses unavailable

**Performance Measurement**:

- `performance_start_trace` / `performance_stop_trace` / `performance_analyze_insight`
- `list_network_requests` / `get_network_request` - Network analysis

**Navigation & Stability**:

- `navigate_page` - Navigate or reload pages
- `wait_for` - Wait for text/selector
- `Bash sleep X` - Wait for page stability after navigation (critical!)
- `press_key` - Keyboard shortcuts (e.g., Escape to close modal)

### Critical Best Practices

**Waiting for Page Stability**:

- ⚠️ **Always wait 2-3 seconds after `navigate_page` or reload**
- Use `Bash sleep 3` before interacting with the page
- Failure to wait causes "Execution context was destroyed" errors

**Network Response Debugging**:

- ⚠️ **Response bodies are often unavailable** - use Supabase MCP to query DB instead
- Check request URL parameters to debug what was sent
- For missing data issues, verify data exists in database first

**Element Selection**:

- Prefer ARIA selectors: `[role="checkbox"]`, `[role="dialog"]`, `[aria-label="..."]`
- Use `Array.from(document.querySelectorAll(...)).find(...)` for text matching
- Check element state (disabled, aria-checked) before assuming interaction worked

**Async Operations**:

- Use promises in `evaluate_script` for delayed operations
- Structure: `return new Promise(resolve => { setTimeout(() => {...}, 500) })`
- Common use case: Click button and wait for modal/toast to appear

**Database Integration**:

- When network response unavailable, query database directly
- Use database to verify data exists before debugging query logic
- Faster and more reliable than trying to inspect stale network responses
- Check for duplicate records with `GROUP BY ... HAVING COUNT(*) > 1` when data appears inconsistent
- Use JOINs to cross-reference related tables and understand data relationships
- Compare database state with Redux/UI state to identify where mismatch occurs

## Workflow Optimization Tips

Learnings from real debugging sessions to speed up your workflow:

### 1. Use `wait_for` Instead of Multiple Snapshots

**Anti-pattern**: Repeatedly calling `take_snapshot` to check if UI loaded

```typescript
// Slow - multiple round trips
take_snapshot()  // Shows "Loading..."
take_snapshot()  // Still loading
take_snapshot()  // Finally loaded
```

**Better approach**: Use `wait_for` to block until content appears

```typescript
// Fast - single call that waits
wait_for({ text: "Restore to current board" })
take_snapshot()  // Content ready
```

**Use `wait_for` when**:

- Dialogs/modals have async data fetching ("Loading available boards...")
- Forms need to populate dropdowns
- Tables need to load data
- Any UI that shows loading states

### 2. Anticipate Loading States in Dialogs

Dialogs and modals often fetch data asynchronously. After clicking to open a dialog:

1. **Expect** a loading state first
2. **Wait** for the loading to complete
3. **Then** interact with the loaded content

```typescript
// Click to open dialog
click({ uid: "button_uid" })

// Wait for data to load (not just dialog to appear)
wait_for({ text: "Expected loaded content" })

// Now safe to interact
click({ uid: "loaded_button_uid" })
```

### 3. Hard Reload After Server-Side Code Changes

**Critical**: Next.js dev server may not hot-reload all server-side changes.

After modifying:

- API routes (`/api/...`)
- tRPC routers
- Server components
- Database queries

**Always hard reload**:

```typescript
navigate_page({ type: "reload", ignoreCache: true })
```

Without this, you may test stale code and waste debugging cycles.

### 4. Capture Before/After States for Validation

When validating fixes, explicitly document state changes:

```typescript
// BEFORE action
take_snapshot()
// Note: "Archived items: 9"

// Perform action
click({ uid: "restore_button" })

// AFTER action
take_snapshot()
// Verify: "Archived items: 0" (or button disabled)
```

This creates clear evidence and catches partial fixes.

### 5. Use URL Parameters for Quick State Setup

Instead of clicking through UI to apply filters or navigate to specific views:

```typescript
// Slow - click through UI
click({ uid: "filter_button" })
wait_for({ text: "Filter options" })
click({ uid: "task_filter" })
// ... more clicks

// Fast - navigate directly with URL params
navigate_page({
  type: "url",
  url: "http://localhost:3000/kanban?taskId=xxx&taskCode=yyy&taskName=Task%20Name"
})
```

**Use for**:

- Testing task filters
- Deep-linking to specific boards/views
- Reproducing specific application states

### 6. Disabled Buttons Indicate State

When a button is disabled, that's often enough information:

```typescript
// If archived items button shows:
// uid=XX_YY button "Archived items" disableable disabled

// This MEANS: 0 archived items
// No need to click and verify - the disabled state IS the verification
```

**Disabled states to recognize**:

- `disableable disabled` - Button is disabled
- No count badge - Usually means 0 items
- `aria-disabled="true"` - Accessibility disabled state

### 7. Combine Database + UI Verification

The most powerful debugging pattern is comparing:

1. **Database** (source of truth)
2. **UI state** (what user sees)

```typescript
// Step 1: Check database
execute_sql({ query: `SELECT COUNT(*) FROM "KanbanCard" WHERE "archivedAt" IS NULL` })
// Result: 8 cards

// Step 2: Check UI
take_snapshot()
// Backlog column shows "8" cards

// Step 3: Compare - if they match, data flow is correct
// If they don't match, investigate the mismatch point
```

**This quickly identifies**:

- API not returning correct data
- Redux state not updating
- UI not reflecting state
- Duplicate records causing inconsistency

### 8. Use Snapshot UIDs for Reliable Element Selection

After `take_snapshot`, use the `uid` values directly with interaction tools:

```typescript
// Snapshot shows:
// uid=42_15 button "Restore"

// Use UID directly - more reliable than text search
click({ uid: "42_15" })
```

**Benefits**:

- No ambiguity if multiple elements have same text
- Works even if text changes slightly
- Faster than evaluate_script DOM queries

### Quick Reference: Optimal Tool Sequences

**Testing a feature after code change**:

```
1. navigate_page({ type: "reload", ignoreCache: true })
2. Bash({ command: "sleep 2" })
3. take_snapshot()
4. [perform test actions]
5. take_snapshot() // verify result
```

**Opening and interacting with a dialog**:

```
1. click({ uid: "open_dialog_button" })
2. wait_for({ text: "expected loaded content" })
3. take_snapshot()
4. click({ uid: "dialog_action_button" })
```

**Validating archive/unarchive cycle**:

```
1. take_snapshot() // Note initial archived count
2. execute_sql() // Verify database state
3. [perform archive/unarchive]
4. take_snapshot() // Verify UI updated
5. execute_sql() // Verify database updated
```

**Debugging "data not showing" issues**:

```
1. execute_sql() // Does data exist in DB?
2. list_network_requests() // Was API called?
3. take_snapshot() // What does UI show?
4. evaluate_script() // What's in Redux/state?
5. Compare all four to find mismatch point
```

