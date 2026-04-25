---
name: logging-guidelines
description: Apply structured logging best practices using wide events pattern with Pino. Enforces error-first logging, tail sampling for production, snake_case field naming, PII redaction, and high-cardinality identifiers. Use when writing logging code, reviewing logs, implementing error handling, or when the user mentions logging, errors, or observability.
---
# Logging Guidelines - MyStatusFlow

**Definitive guide for extreme best-practice structured logging based on wide events pattern.**

> **Last Updated**: January 2025  
> **Status**: Comprehensive Guidelines (Implementation in Progress)  
> **Based On**: Boris Tane's "Logging Sucks" article and industry best practices

---

## ⚠️ CRITICAL: Production Logging Priorities

**For Production, prioritize ERROR logging over verbose success logging.**

### Production Logging Hierarchy (Priority Order)

1. **ERRORS (100% - Always Log)**
   - All errors (`status_code >= 500`)
   - All exceptions and failures
   - All security events
   - **These are your PRIMARY concern in production**

2. **SLOW REQUESTS (100% - Always Log)**
   - Requests exceeding p99 threshold (default: 2000ms)
   - Performance degradation indicators

3. **VIP USERS (100% - Always Log)**
   - Enterprise customers
   - Internal testing accounts
   - High-value users

4. **SUCCESS REQUESTS (5% - Sample Only)**
   - Successful operations (`status_code < 400`)
   - Normal business operations
   - **MUST use tail sampling** - default 5% sample rate

### ⚠️ Common Mistake: Logging Everything

**❌ WRONG**: Logging all requests without sampling
```typescript
// DON'T DO THIS - logs every single request
logger.info(event, 'Request completed')
```

**✅ CORRECT**: Always check sampling for success requests
```typescript
// DO THIS - sample success requests, always log errors
if (event.status_code >= 500 || event.error) {
  logger.error(event, 'Request failed') // Always log errors
} else if (shouldSample(event)) {
  logger.info(event, 'Request completed') // Sample successes
}
```

### Key Rules

- **Errors**: Log 100% of errors - these are critical for production debugging
- **Success**: Sample success requests at 5% (configurable via `LOG_SAMPLE_RATE`)
- **Never log without sampling** success requests in production (except VIP users)
- **Wide events are good**, but only if properly sampled

**Remember**: In production, you want to see ALL errors but only a SAMPLE of successful operations. This reduces log volume by ~95% while maintaining full error visibility.

---

## Table of Contents

### Quick Reference
- [Field Reference Map](#field-reference-map)
- [Event Type Requirements](#event-type-requirements-map)
- [Pino Signature Quick Reference](#pino-signature-quick-reference)
- [Decision Trees](#decision-trees)

### Core Concepts
1. [The Core Problem](#the-core-problem)
2. [Core Principles](#core-principles)
3. [Wide Events Pattern](#wide-events-pattern)
4. [Event Structure](#event-structure)
   - [Request Context](#1-request-context-always-required)
   - [User Context](#2-user-context-when-available)
   - [Business Context](#3-business-context-operation-specific)
   - [Correlation Propagation](#correlation-propagation)
   - [Operation Naming](#operation-naming-convention)
   - [Event Taxonomy](#6-event-taxonomy--outcome-categorization)
   - [Performance Context](#5-performance-context)

### Schema & Rules
5. [Canonical Schema & Naming Rules](#canonical-schema--naming-rules)
   - [Schema Version](#schema-version)
   - [Field Naming](#field-naming-convention)
   - [Required Fields by Event Type](#required-fields-by-event-type)
   - [Field Types & Enums](#field-types--enums)
6. [Event Types Beyond HTTP](#event-types-beyond-http)
   - [Background Jobs](#background-jobs)
   - [Queue Workers](#queue-workers)
   - [Cron Jobs](#cron-jobs--scheduled-tasks)
   - [Startup/Shutdown](#startup--shutdown-events)

### Security & Compliance
7. [PII & Secrets Redaction Policy](#pii--secrets-redaction-policy)
   - [Redaction Lists](#secrets-redaction-list)
   - [Query Parameters Allowlist](#query-parameters-allowlist)
   - [Headers Allowlist](#headers-allowlist)
   - [Request/Response Body Policy](#requestresponse-body-logging-policy)
8. [Client Logging Endpoint Hardening](#client-logging-endpoint-hardening)
   - [Trust Boundary Rules](#trust-boundary-rules-for-client-logs)
9. [Retention & Access & Compliance](#retention--access--compliance)

### Implementation
10. [Size Limits & Truncation](#size-limits--truncation)
11. [Error Shape & Stack Hygiene](#error-shape--stack-hygiene)
    - [Error Grouping](#error-grouping--fingerprinting)
12. [Environment Rules](#environment-rules)
13. [Sampling Configurability](#sampling-configurability)
14. [Client-Side Logging](#client-side-logging)
15. [Implementation Guide](#implementation-guide)
16. [Tail Sampling](#tail-sampling)

### Reference
17. [Best Practices](#best-practices)
18. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
19. [Querying & Analytics](#querying--analytics)
20. [Performance & Cost](#performance--cost)

---

## Quick Reference

### Common Patterns

```typescript
// ✅ CORRECT: Pino signature
logger.info({ request_id, user_id, operation: 'create_task' }, 'Task created')

// ✅ CORRECT: Wide event pattern with mandatory sampling
const event = { schema_version: '1.0.0', event_type: 'http_request', ... }
event.user = { id: userId, subscription_tier: 'premium' }
event.operation = 'create_task'

// ✅ CORRECT: Error logging (always log errors)
if (event.status_code >= 500 || event.error) {
  event.error = formatError(error, statusCode >= 500)
  logger.error(event, 'Request failed') // Always log errors
} else if (shouldSample(event)) {
  // ✅ CORRECT: Sample success requests (mandatory in production)
  const sanitized = sanitizeEvent(event)
  const limited = enforceSizeLimits(sanitized)
  logger.info(limited, 'Request completed')
}

// ❌ WRONG: Logging without sampling check
// logger.info(event, 'Request completed') // DON'T DO THIS - logs everything!
```

### Field Naming Quick Check

| ✅ Good | ❌ Bad |
|---------|--------|
| `user_id`, `request_id`, `duration_ms` | `userId`, `requestId`, `durationMs` |
| `subscription_tier` | `subscription`, `subscriptionTier` |
| `error_category` | `errorCategory`, `error-category` |
| `operation: 'create_task'` | `operation: 'taskCreation'` |

---

## Field Reference Map

### Core Fields (All Events)

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `schema_version` | string | ✅ | Schema version | `"1.0.0"` |
| `event_type` | string | ✅ | Event type enum | `"http_request"` |
| `timestamp` | string | ✅ | ISO 8601 timestamp | `"2025-01-15T10:23:45.612Z"` |
| `service` | string | ✅ | Service name | `"checkout-service"` |
| `environment` | string | ✅ | Environment enum | `"production"` |

### HTTP Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `request_id` | string | ✅ | Unique request ID |
| `method` | string | ✅ | HTTP method |
| `path` | string | ✅ | Request path |
| `status_code` | number | ✅ | HTTP status code |
| `status_class` | string | ✅ | Status class (`"2xx"`, `"4xx"`, `"5xx"`) |
| `duration_ms` | number | ✅ | Request duration |
| `query_params` | object | ❌ | Filtered query params |
| `headers` | object | ❌ | Filtered headers |
| `ip` | string | ❌ | Hashed IP |
| `user_agent` | string | ❌ | User agent |

### Correlation Fields

| Field | Type | Required | Source |
|-------|------|----------|--------|
| `trace_id` | string | ❌ | `traceparent` header |
| `span_id` | string | ❌ | `traceparent` header |
| `correlation_id` | string | ❌ | `x-correlation-id` header |

### User Context Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `user.id` | string | ✅* | User ID (when available) |
| `user.session_id` | string | ❌ | Session ID |
| `user.workspace_id` | string | ❌ | Workspace ID |
| `user.subscription_tier` | string | ❌ | Subscription tier |

### Error Fields

| Field | Type | Required | When Included |
|-------|------|----------|---------------|
| `error.type` | string | ✅ | Always for errors |
| `error.message` | string | ✅ | Always for errors |
| `error.code` | string | ❌ | When available |
| `error.error_category` | string | ✅ | Always for errors |
| `error.error_fingerprint` | string | ❌ | When stack included |
| `error.stack` | string | ❌ | Only for 5xx errors |

### Performance Fields

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `duration_ms` | number | ms | Total duration |
| `request_size_bytes` | number | bytes | Request body size |
| `response_size_bytes` | number | bytes | Response body size |
| `db_queries` | number | count | DB query count |
| `db_query_time_ms` | number | ms | Total DB time |
| `db_pool_wait_ms` | number | ms | DB pool wait time |
| `cache_hits` | number | count | Cache hits |
| `cache_misses` | number | count | Cache misses |
| `external_calls` | number | count | External API calls |
| `external_call_time_ms` | number | ms | External API time |
| `queue_lag_ms` | number | ms | Queue lag (workers) |
| `retry_count` | number | count | Retry attempts |

---

## Event Type Requirements Map

| Event Type | Required Fields | Additional Required |
|------------|----------------|---------------------|
| `http_request` | Core + `request_id`, `method`, `path`, `status_code`, `status_class`, `duration_ms` | - |
| `job_run` | Core + `job_id`, `job_type`, `status`, `duration_ms` | - |
| `queue_message` | Core + `message_id`, `queue_name`, `status`, `duration_ms` | - |
| `cron_job` | Core + `cron_job_id`, `cron_schedule`, `job_name`, `status`, `duration_ms` | - |
| `audit_event` | Core + `audit_id`, `actor_id`, `action`, `target_type`, `target_id`, `outcome` | `reason` if `outcome=failure` |
| `security_event` | Core + `security_event_id`, `event_category`, `severity`, `action` | - |
| `startup` | Core | - |
| `shutdown` | Core + `reason`, `uptime_seconds` | - |

---

## Pino Signature Quick Reference

```typescript
// ✅ CORRECT: Event first, message second
logger.info(event, 'Request completed')
logger.error(event, 'Error occurred')
logger.warn(event, 'Warning')

// ❌ WRONG: Message first, event second
logger.info('Request completed', event)  // DON'T DO THIS
```

**Rule**: Always `logger.level(event, 'message')` - event object comes first.

---

## Decision Trees

### Should I Log This Event?

```
Is sampling disabled (dev/test)?
├─ YES → Log it
└─ NO → Is it an error (status >= 500)?
    ├─ YES → Log it (100%)
    └─ NO → Is it slow (duration > p99 threshold)?
        ├─ YES → Log it (100%)
        └─ NO → Is user VIP?
            ├─ YES → Log it (100%)
            └─ NO → Random sample at LOG_SAMPLE_RATE
```

### Should I Include Stack Trace?

```
Is status_code >= 500?
├─ YES → Include stack trace
└─ NO → Don't include stack trace
```

### Should I Log Request/Response Body?

```
Is endpoint in ALLOWED_BODY_LOGGING_ENDPOINTS?
├─ YES → Sanitize body → Log sanitized body + metadata
└─ NO → Log metadata only (size, content-type)
```

### Client Log Trust Boundary

```
Receive client log
├─ Override: event_type, request_id, user.id, session_id, ip_hash
├─ Validate: operation, error schema
└─ Add: source='client', server-derived fields
```

---

## The Core Problem

**Logs are optimized for writing, not for querying.**

Traditional logging practices were designed for monoliths and single servers. Today, a single user request might touch 15 services, 3 databases, 2 caches, and a message queue. Your logs are still acting like it's 2005.

### Why Traditional Logging Fails

- **Scattered logs**: 17+ log lines per request, impossible to correlate
- **Missing context**: Logs don't include business context (user tier, cart value, feature flags)
- **String search is broken**: User IDs logged 47 different ways across codebase
- **No correlation**: Can't track requests across services
- **Low cardinality**: Most fields have few unique values (useless for debugging)
- **Low dimensionality**: 5 fields per log (can't answer complex questions)

### The Solution: Wide Events

Instead of logging what your code is doing, **log what happened to this request**.

One comprehensive log event per request with as many fields as needed (typically 20-100+) containing everything you might need to debug. Not just what went wrong, but the full picture of the request.

---

## Core Principles

### 0. Server-Side Pino Only, No Browser Console Logs, No Polling/Monitoring

**Critical**: This project uses **Pino only** for server-side logging. All client-side logs must be sent to server API endpoints that log using Pino. **Never use browser console methods** (`console.log`, `console.error`, etc.) in production code.

- **Server-side**: Use Pino logger directly
- **Client-side**: Send logs to server API endpoints (e.g., `/api/log-error`) which use Pino
- **Never**: Use `console.*` methods in client code - users should never see logs in browser DevTools
- **No polling**: Never use `setInterval` or background timers to collect metrics
- **No monitoring endpoints**: Don't create admin endpoints that poll for metrics
- **Log everything**: Metrics are derived from logs, not collected separately

**Pattern**: Log events as they happen. Query logs for metrics. Don't poll or monitor.

See [Client-Side Logging](#client-side-logging) section for details.

### 1. Error-First Logging: Prioritize Errors Over Success Logs

**CRITICAL FOR PRODUCTION**: In production, **errors are your primary concern**. Success logs should be sampled heavily.

**Production Priority**:
1. **Errors (100%)** - Always log all errors, exceptions, and failures
2. **Slow requests (100%)** - Always log requests exceeding performance thresholds
3. **VIP users (100%)** - Always log requests from high-value users
4. **Success requests (5%)** - Sample only - use tail sampling

❌ **Bad**: Logging all requests without sampling
```typescript
// DON'T DO THIS - logs every single request (expensive!)
logger.info(event, 'Request completed')
```

✅ **Good**: Always check sampling for success requests
```typescript
// DO THIS - sample success requests, always log errors
if (event.status_code >= 500 || event.error) {
  // Always log errors - these are critical
  logger.error(event, 'Request failed')
} else if (shouldSample(event)) {
  // Sample success requests - reduces log volume by 95%
  logger.info(event, 'Request completed')
}
```

**Key Rules**:
- **Never log success requests without sampling** in production (except VIP users)
- **Always log errors** - 100% of errors must be logged
- **Use `shouldSample()` function** before logging success requests
- **Wide events are valuable**, but only if properly sampled

See [Tail Sampling](#tail-sampling) section for implementation details.

### 2. Log What Happened, Not What Your Code Is Doing

❌ **Bad**: Multiple log statements throughout code
```typescript
logger.info('Starting user fetch')
logger.info('Querying database')
logger.info('Found 5 users')
logger.info('Returning results')
```

✅ **Good**: One wide event with accumulated context
```typescript
// Build event throughout request lifecycle
const event = {
  request_id: generateRequestId(),
  operation: 'fetch_users',
  user_id: userId,
  query_params: { limit: 10 },
  duration_ms: 45,
  result_count: 5,
  status: 'success'
}
// Emit once at the end (Pino signature: logger.info(event, 'message'))
logger.info(event, 'Request completed')
```

### 3. High Cardinality Fields Are Essential

**Cardinality**: The number of unique values a field can have.

- **High cardinality** (millions of unique values): `user_id`, `request_id`, `trace_id`, `session_id` → **Essential for debugging**
- **Low cardinality** (few unique values): `http_method`, `environment`, `status_code` → **Useful for filtering, but not debugging**

High-cardinality fields are what make logs actually useful. They enable precise filtering: "Show me all logs for user_456" or "Find request req_abc123".

### 4. High Dimensionality Enables Complex Queries

**Dimensionality**: The number of fields in your log event.

- **Low dimensionality** (5 fields): Can answer simple questions
- **High dimensionality** (typically 20-100+ fields): Can answer complex questions

**Note**: There's no magic number. Include as many fields as needed to answer the questions you care about. Typical wide events range from 20-100+ fields depending on operation complexity.

More dimensions = more questions you can answer:
- "Are premium users experiencing more errors?"
- "What's the error rate for the new checkout feature?"
- "Which deployment caused the latency regression?"

### 5. Accumulate Context, Emit Once

Build the event object throughout the request lifecycle, then emit once at the end. Don't scatter logs across the codebase.

```typescript
// Middleware: Initialize event
const event = {
  request_id: generateRequestId(),
  trace_id: extractTraceId(req),
  method: req.method,
  path: req.path,
  timestamp: new Date().toISOString(),
  service: 'checkout-service',
  version: process.env.VERSION,
  deployment_id: process.env.DEPLOYMENT_ID,
  region: process.env.REGION
}

// After auth: Add user context
event.user = {
  id: user.id,
  subscription_tier: user.plan,
  account_age_days: daysSince(user.createdAt),
  lifetime_value_cents: user.ltv
}

// During processing: Add business context
event.cart = {
  id: cart.id,
  item_count: cart.items.length,
  total_cents: cart.total,
  coupon_applied: cart.coupon?.code
}

event.payment = {
  method: payment.method,
  provider: payment.provider,
  latency_ms: paymentLatency,
  attempt: paymentAttempt
}

// On completion: Add result
event.duration_ms = Date.now() - startTime
event.status_code = 200
event.status = 'success'

// Emit once at the end (Pino signature: logger.info(event, 'message'))
logger.info(event, 'Request completed')
```

### 6. Structured JSON Only

All logs must be structured JSON. Never use string interpolation or plain text messages.

❌ **Bad**:
```typescript
logger.info(`User ${userId} updated project ${projectId}`)
logger.info("Payment failed for user 123")
```

✅ **Good**:
```typescript
logger.info({
  user_id: userId,
  project_id: projectId,
  action: 'update'
}, 'User updated project')

logger.info({
  user_id: 'user_123',
  error_type: 'PaymentError',
  error_code: 'card_declined'
}, 'Payment failed')
```

---

## Wide Events Pattern

### Definition

**Wide Event** (also called **Canonical Log Line**): A single, context-rich log event emitted per request per service. Instead of 13 log lines for one request, you emit 1 line with as many fields as needed (typically 20-100+) containing everything you might need to debug.

### Key Characteristics

1. **One log line per request** (per service hop)
2. **High dimensionality** (typically 20-100+ fields) for complete context
3. **High-cardinality identifiers** (`user_id`, `request_id`, `trace_id`)
4. **Business context included** (subscription tier, cart value, feature flags)
5. **Performance metrics** (duration, DB queries, cache hits)
6. **Error context** (when applicable)
7. **Infrastructure context** (service, version, deployment, region)

### Mental Model Shift

**Old way**: Logs are a debugging diary. Log what your code is doing.

**New way**: Logs are structured records of business events. Log what happened to this request.

---

## Event Structure

Every wide event should include these categories of fields:

### 1. Request Context (Always Required)

```typescript
{
  // High-cardinality identifiers (ESSENTIAL)
  request_id: string          // Unique request identifier
  trace_id?: string          // OpenTelemetry trace ID (from traceparent header)
  span_id?: string          // OpenTelemetry span ID (from traceparent header)
  correlation_id?: string   // Cross-service correlation (from x-correlation-id header)
  
  // Request details
  method: string             // HTTP method
  path: string              // Request path
  query_params?: object     // Query parameters (filtered via allowlist - see PII section)
  headers?: object          // Important headers (filtered via allowlist - see PII section)
  ip?: string               // Client IP (hashed/anonymized)
  user_agent?: string       // Client user agent
  
  // Timing
  timestamp: string         // ISO 8601 timestamp
  duration_ms: number       // Request duration
}
```

### Correlation Propagation

**Cross-service correlation** enables tracking requests across service boundaries. Use standard headers:

#### Traceparent Header (W3C Trace Context)

Extract `trace_id` and `span_id` from the `traceparent` header:

```typescript
import { extractTraceContext } from '@opentelemetry/api'

function extractTraceId(req: Request): string | undefined {
  const traceparent = req.headers.get('traceparent')
  if (!traceparent) return undefined
  
  // Parse traceparent: version-trace_id-parent_id-trace_flags
  // Example: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
  const parts = traceparent.split('-')
  if (parts.length >= 2) {
    return parts[1] // trace_id (32 hex chars)
  }
  return undefined
}

function extractSpanId(req: Request): string | undefined {
  const traceparent = req.headers.get('traceparent')
  if (!traceparent) return undefined
  
  const parts = traceparent.split('-')
  if (parts.length >= 3) {
    return parts[2] // parent_id/span_id (16 hex chars)
  }
  return undefined
}

// Or use OpenTelemetry SDK
const traceContext = extractTraceContext(req.headers)
event.trace_id = traceContext.traceId
event.span_id = traceContext.spanId
```

#### Tracestate Header

Preserve `tracestate` header for vendor-specific trace data:

```typescript
const tracestate = req.headers.get('tracestate')
if (tracestate) {
  event.tracestate = tracestate // Preserve for downstream services
}
```

#### Correlation ID Header

Use `x-correlation-id` header for application-level correlation:

```typescript
function getCorrelationId(req: Request): string | undefined {
  return req.headers.get('x-correlation-id') || undefined
}

// If not present, generate and propagate
const correlationId = getCorrelationId(req) || generateCorrelationId()
event.correlation_id = correlationId

// Propagate to downstream services
req.headers.set('x-correlation-id', correlationId)
```

#### Propagation Rules

1. **Incoming request**: Extract `traceparent`, `tracestate`, `x-correlation-id` from headers
2. **Generate if missing**: If `trace_id` missing, generate new trace (root span)
3. **Create child span**: Generate new `span_id` for this service hop
4. **Propagate downstream**: Include `traceparent`, `tracestate`, `x-correlation-id` in outbound requests
5. **Log all IDs**: Include `trace_id`, `span_id`, `correlation_id` in log event

**Example propagation**:

```typescript
// Service A receives request
const traceId = extractTraceId(req) || generateTraceId()
const spanId = generateSpanId() // New span for this service
const correlationId = getCorrelationId(req) || generateCorrelationId()

event.trace_id = traceId
event.span_id = spanId
event.correlation_id = correlationId

// Service A calls Service B
const downstreamHeaders = {
  'traceparent': `00-${traceId}-${spanId}-01`, // Propagate trace
  'tracestate': req.headers.get('tracestate') || '',
  'x-correlation-id': correlationId,
}
await fetch('http://service-b/api', { headers: downstreamHeaders })
```

### 2. User Context (When Available)

```typescript
{
  user: {
    id: string                    // High-cardinality: Essential
    session_id?: string           // High-cardinality: Essential
    workspace_id?: string         // High-cardinality: Essential
    subscription_tier?: string   // Business context
    account_age_days?: number    // Business context
    lifetime_value_cents?: number // Business context
    org_id?: string              // Business context
    team_id?: string             // Business context
  }
}
```

### 3. Business Context (Operation-Specific)

```typescript
{
  operation: string           // Operation name (e.g., 'create_task') - see Operation Naming Convention
  
  // Business-specific fields (examples)
  project_id?: string
  task_id?: string
  document_id?: string
  order_id?: string
  cart?: {
    id: string
    item_count: number
    total_cents: number
    coupon_applied?: string
  }
  payment?: {
    method: string
    provider: string
    latency_ms: number
    attempt: number
  }
}
```

### Operation Naming Convention

**All `operation` fields must follow the pattern**: `verb_object` (snake_case)

#### Standard Verbs

| Verb | Usage | Example |
|------|-------|---------|
| `create` | Creating new resources | `create_task`, `create_user` |
| `read` / `get` | Reading/fetching resources | `get_task`, `read_document` |
| `update` | Updating existing resources | `update_user`, `update_project` |
| `delete` | Deleting resources | `delete_task`, `delete_project` |
| `list` | Listing multiple resources | `list_tasks`, `list_users` |
| `search` | Searching resources | `search_documents`, `search_users` |
| `authenticate` | Authentication operations | `authenticate_user` |
| `authorize` | Authorization checks | `authorize_access` |
| `process` | Background processing | `process_payment`, `process_email` |
| `validate` | Validation operations | `validate_input`, `validate_token` |

#### Examples

✅ **Good**:
```typescript
operation: 'create_task'
operation: 'update_user'
operation: 'delete_project'
operation: 'list_workspaces'
operation: 'search_documents'
operation: 'authenticate_user'
operation: 'process_payment'
operation: 'validate_input'
```

❌ **Bad**:
```typescript
operation: 'task_creation'        // Wrong order: should be verb_object
operation: 'userUpdate'            // Wrong case: should be snake_case
operation: 'delete'                // Missing object
operation: 'doSomething'           // Not verb_object pattern
operation: 'POST /api/tasks'       // HTTP method/path, not operation name
```

#### Operation Registry (Recommended)

Maintain a registry of allowed operations per service to ensure consistency:

```typescript
// lib/operations.ts
export const OPERATIONS = {
  // Task operations
  CREATE_TASK: 'create_task',
  UPDATE_TASK: 'update_task',
  DELETE_TASK: 'delete_task',
  GET_TASK: 'get_task',
  LIST_TASKS: 'list_tasks',
  
  // User operations
  CREATE_USER: 'create_user',
  UPDATE_USER: 'update_user',
  AUTHENTICATE_USER: 'authenticate_user',
  
  // Project operations
  CREATE_PROJECT: 'create_project',
  UPDATE_PROJECT: 'update_project',
  DELETE_PROJECT: 'delete_project',
  
  // ... etc
} as const

// Usage
event.operation = OPERATIONS.CREATE_TASK
```

**Benefits**:
- Prevents typos
- Enables autocomplete
- Ensures consistency across codebase
- Makes refactoring easier

#### Validation

Validate operation names match the pattern:

```typescript
const OPERATION_PATTERN = /^[a-z]+_[a-z][a-z0-9_]*$/

function validateOperation(operation: string): boolean {
  return OPERATION_PATTERN.test(operation)
}

// In middleware/validation
if (!validateOperation(event.operation)) {
  throw new Error(`Invalid operation name: ${event.operation}. Must match pattern: verb_object`)
}
```

### 4. Feature Flags & Experiments

```typescript
{
  feature_flags?: {
    new_checkout_flow?: boolean
    express_payment?: boolean
    // ... other flags
  }
}
```

**Why this matters**: "What's the error rate for the new checkout feature?" requires feature flag context.

### 5. Performance Context

```typescript
{
  // Request/Response sizes (bytes)
  request_size_bytes?: number      // Total request body size in bytes
  response_size_bytes?: number     // Total response body size in bytes
  
  // Timing (all in milliseconds)
  duration_ms: number               // Total request duration
  db_pool_wait_ms?: number          // Time waiting for DB connection from pool
  db_queries?: number               // Number of DB queries
  db_query_time_ms?: number         // Total DB query time
  
  // Cache performance
  cache_hits?: number               // Cache hit count
  cache_misses?: number             // Cache miss count
  
  // External calls
  external_calls?: number           // Total external API calls
  external_call_time_ms?: number     // Total external API time
  external_calls_by_service?: {     // Per-service breakdown
    [serviceName: string]: {
      count: number
      total_time_ms: number
      errors: number
    }
  }
  
  // Queue performance (for queue workers)
  queue_lag_ms?: number             // Time message spent in queue before processing
  
  // Retry/timeout context
  retry_count?: number              // Number of retries attempted
  timeout_ms?: number                // Timeout threshold (if applicable)
}
```

**Standardization rules**:
- All durations/times: **milliseconds** (`*_ms` suffix)
- All sizes: **bytes** (`*_bytes` suffix)
- All counts: **integers** (no suffix)
- External calls: Track both aggregate (`external_calls`, `external_call_time_ms`) and per-service breakdown (`external_calls_by_service`)

### 6. Event Taxonomy & Outcome Categorization

#### Event Type

Every event must include an `event_type` field for cross-cutting queries:

```typescript
{
  event_type: 'http_request' | 'job_run' | 'queue_message' | 'cron_job' | 'audit_event' | 'security_event' | 'startup' | 'shutdown'
}
```

| Event Type | Description | Use Case |
|------------|-------------|----------|
| `http_request` | HTTP API requests | All HTTP endpoints |
| `job_run` | Background job executions | Async job processing |
| `queue_message` | Queue message processing | Message queue workers |
| `cron_job` | Scheduled/cron job runs | Scheduled tasks |
| `audit_event` | Audit trail events | User actions, data changes |
| `security_event` | Security-related events | Auth failures, suspicious activity |
| `startup` | Application startup | App initialization |
| `shutdown` | Application shutdown | App termination |

#### Status Classification

Include `status_class` for HTTP requests:

```typescript
{
  status_code: number        // HTTP status code (e.g., 200, 404, 500)
  status_class: '2xx' | '3xx' | '4xx' | '5xx'  // Status code class
}
```

**Usage**: Enables queries like "all 5xx errors" without checking individual status codes.

#### Error Category

Include `error_category` for all errors:

```typescript
{
  error?: {
    type: string                    // Error class name
    message: string                 // Error message
    code?: string                   // Error code
    error_category: 'validation' | 'auth' | 'authorization' | 'rate_limit' | 'external' | 'timeout' | 'internal' | 'unknown'
    // ... other error fields
  }
}
```

| Error Category | HTTP Status | Description | Example |
|----------------|-------------|-------------|---------|
| `validation` | 400, 422 | Input validation errors | Invalid email format |
| `auth` | 401 | Authentication errors | Invalid credentials |
| `authorization` | 403 | Permission errors | Insufficient permissions |
| `rate_limit` | 429 | Rate limiting errors | Too many requests |
| `external` | - | External service errors | Payment provider failure |
| `timeout` | 408, 504 | Timeout errors | Request timeout |
| `internal` | 500, 502, 503 | Internal server errors | Database connection failed |
| `unknown` | - | Unclassified errors | Unexpected error type |

**Usage**: Enables queries like "all external service errors" or "rate limit errors by user tier".

### 7. Error Context (When Applicable)

```typescript
{
  error?: {
    type: string             // Error class name
    message: string          // Error message
    code?: string            // Error code
    stack?: string           // Stack trace
    retriable?: boolean      // Can this be retried?
    
    // Provider-specific error codes
    stripe_decline_code?: string
    // ... other provider codes
  }
}
```

### 7. Infrastructure Context (Auto-Added)

```typescript
{
  service: string            // Service name
  version: string            // Service version
  deployment_id: string      // Deployment identifier
  region?: string            // Deployment region
  environment: string        // 'development' | 'staging' | 'production'
  git_commit?: string       // Git commit SHA
}
```

**Why deployment_id matters**: "Which deployment caused the latency regression?" requires deployment context.

### Complete Example Wide Event

```json
{
  "schema_version": "1.0.0",
  "event_type": "http_request",
  "timestamp": "2025-01-15T10:23:45.612Z",
  "request_id": "req_8bf7ec2d",
  "trace_id": "abc123def456",
  "correlation_id": "corr_xyz789",
  
  "service": "checkout-service",
  "version": "2.4.1",
  "deployment_id": "deploy_789",
  "region": "us-east-1",
  "environment": "production",
  
  "method": "POST",
  "path": "/api/checkout",
  "query_params": { "workspace_id": "ws_123" },
  "status_code": 500,
  "status_class": "5xx",
  "duration_ms": 1247,
  
  "user": {
    "id": "user_456",
    "session_id": "sess_abc123",
    "subscription_tier": "premium",
    "account_age_days": 847,
    "lifetime_value_cents": 284700
  },
  
  "cart": {
    "id": "cart_xyz",
    "item_count": 3,
    "total_cents": 15999,
    "coupon_applied": "SAVE20"
  },
  
  "payment": {
    "method": "card",
    "provider": "stripe",
    "latency_ms": 1089,
    "attempt": 3
  },
  
  "error": {
    "type": "PaymentError",
    "code": "card_declined",
    "message": "Card declined by issuer",
    "error_category": "external",
    "error_fingerprint": "a3f2b1c4d5e6f7g8",
    "retriable": false,
    "stripe_decline_code": "insufficient_funds"
  },
  
  "feature_flags": {
    "new_checkout_flow": true,
    "express_payment": false
  },
  
  "performance": {
    "request_size_bytes": 1024,
    "response_size_bytes": 512,
    "db_pool_wait_ms": 5,
    "db_queries": 3,
    "db_query_time_ms": 234,
    "cache_hits": 1,
    "cache_misses": 2,
    "external_calls": 1,
    "external_call_time_ms": 1089,
    "external_calls_by_service": {
      "stripe": {
        "count": 1,
        "total_time_ms": 1089,
        "errors": 1
      }
    }
  },
  
  "operation": "checkout",
  "status": "error"
}
```

**One event. Everything you need.** When this user complains, you search for `user_id = "user_456"` and instantly know:
- They're a premium customer (high priority)
- They've been with you for over 2 years (very high priority)
- Payment failed on the 3rd attempt
- Actual reason: insufficient funds
- They were using the new checkout flow (potential correlation?)

No grep-ing. No guessing. No second search.

---

## Canonical Schema & Naming Rules

### Schema Version

All events must include a `schema_version` field to enable schema evolution:

```typescript
{
  schema_version: '1.0.0', // Semantic versioning
  // ... rest of event
}
```

### Field Naming Convention

**All field names must use `snake_case`** (not `camelCase` or `kebab-case`):

- ✅ `user_id`, `request_id`, `duration_ms`, `query_params`
- ❌ `userId`, `requestId`, `durationMs`, `queryParams`
- ❌ `user-id`, `request-id`, `duration-ms`

**Rationale**: Consistent naming enables reliable querying across services and prevents field name collisions.

### Required Fields by Event Type

#### HTTP Request Events (Always Required)

```typescript
{
  schema_version: string        // Required: '1.0.0'
  event_type: string           // Required: 'http_request'
  request_id: string           // Required: Unique per request
  timestamp: string            // Required: ISO 8601
  method: string               // Required: HTTP method
  path: string                 // Required: Request path
  status_code: number          // Required: HTTP status code
  status_class: string         // Required: '2xx' | '3xx' | '4xx' | '5xx'
  duration_ms: number          // Required: Request duration
  service: string              // Required: Service name
  environment: string          // Required: 'development' | 'staging' | 'production'
}
```

#### Background Job Events (Always Required)

```typescript
{
  schema_version: string        // Required: '1.0.0'
  event_type: string           // Required: 'job_run'
  job_id: string              // Required: Unique job identifier
  job_type: string            // Required: Job type name
  timestamp: string            // Required: ISO 8601
  status: string              // Required: 'success' | 'error' | 'retry'
  duration_ms: number          // Required: Job duration
  service: string              // Required: Service name
  environment: string          // Required: 'development' | 'staging' | 'production'
}
```

#### Queue Worker Events (Always Required)

```typescript
{
  schema_version: string        // Required: '1.0.0'
  event_type: string           // Required: 'queue_message'
  message_id: string          // Required: Unique message identifier
  queue_name: string          // Required: Queue name
  timestamp: string            // Required: ISO 8601
  status: string              // Required: 'success' | 'error' | 'retry'
  duration_ms: number          // Required: Processing duration
  service: string              // Required: Service name
  environment: string          // Required: 'development' | 'staging' | 'production'
}
```

#### Cron Job Events (Always Required)

```typescript
{
  schema_version: string        // Required: '1.0.0'
  event_type: string           // Required: 'cron_job'
  cron_job_id: string         // Required: Unique cron job run identifier
  cron_schedule: string       // Required: Cron schedule expression
  job_name: string            // Required: Cron job name
  timestamp: string            // Required: ISO 8601
  status: string              // Required: 'success' | 'error'
  duration_ms: number          // Required: Job duration
  service: string              // Required: Service name
  environment: string          // Required: 'development' | 'staging' | 'production'
}
```

#### Audit Events (Always Required)

```typescript
{
  schema_version: string        // Required: '1.0.0'
  event_type: string           // Required: 'audit_event'
  audit_id: string            // Required: Unique audit event identifier
  timestamp: string            // Required: ISO 8601
  actor_id: string            // Required: User/service that performed the action
  action: string              // Required: Action performed (e.g., 'create_user', 'delete_project')
  target_type: string         // Required: Type of target (e.g., 'user', 'project', 'document')
  target_id: string           // Required: ID of the target entity
  outcome: string             // Required: 'success' | 'failure'
  reason?: string             // Optional: Reason for the action (required if outcome is 'failure')
  ip_hash?: string            // Optional: Hashed IP address
  user_agent?: string         // Optional: User agent
  service: string              // Required: Service name
  environment: string          // Required: 'development' | 'staging' | 'production'
}
```

#### Security Events (Always Required)

```typescript
{
  schema_version: string        // Required: '1.0.0'
  event_type: string           // Required: 'security_event'
  security_event_id: string   // Required: Unique security event identifier
  timestamp: string            // Required: ISO 8601
  event_category: string      // Required: 'auth_failure' | 'suspicious_activity' | 'rate_limit_exceeded' | 'access_denied' | 'data_breach' | 'other'
  severity: string            // Required: 'low' | 'medium' | 'high' | 'critical'
  actor_id?: string           // Optional: User/service that triggered the event
  action: string              // Required: Security action/event description
  target_type?: string        // Optional: Type of target
  target_id?: string          // Optional: ID of the target entity
  ip_hash?: string            // Optional: Hashed IP address
  user_agent?: string         // Optional: User agent
  reason?: string             // Optional: Detailed reason/description
  service: string              // Required: Service name
  environment: string          // Required: 'development' | 'staging' | 'production'
}
```

**Note**: Audit and security events have **longer retention** (see Retention & Access & Compliance section).

### Field Types & Enums

#### Common Enums

```typescript
// Status values
status: 'success' | 'error' | 'retry' | 'timeout'

// Environment values
environment: 'development' | 'staging' | 'production' | 'test'

// HTTP methods
method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE' | 'HEAD' | 'OPTIONS'

// Subscription tiers (example - adjust to your domain)
subscription_tier: 'free' | 'pro' | 'premium' | 'enterprise'
```

#### Field Type Requirements

- **Strings**: Use for identifiers, paths, messages. Max length enforced (see Size Limits).
- **Numbers**: Use for durations (milliseconds), counts, monetary values (cents).
- **Booleans**: Use for feature flags, retriable flags.
- **Objects**: Use for nested context (user, cart, payment).
- **Arrays**: Use sparingly, with size limits (see Size Limits).

### Optional vs Required

- **Required fields**: Must be present in every event of that type. Missing required fields trigger validation errors.
- **Optional fields**: Include when available/relevant. Omit when not applicable.

---

## Event Types Beyond HTTP

The wide events pattern applies to **all** event types, not just HTTP requests.

### Background Jobs

```typescript
// Initialize event at job start
const event = {
  schema_version: '1.0.0',
  job_id: generateJobId(),
  job_type: 'send_email_batch',
  timestamp: new Date().toISOString(),
  service: 'email-service',
  environment: process.env.NODE_ENV,
  
  // Job-specific context
  batch_size: emailBatch.length,
  template_id: templateId,
  priority: 'high',
}

// Accumulate context during execution
event.recipients_processed = 0
event.recipients_failed = 0
event.external_api_calls = 0

try {
  // Process job...
  event.recipients_processed = results.successCount
  event.recipients_failed = results.failureCount
  event.status = 'success'
} catch (error) {
  event.status = 'error'
  event.error = formatError(error) // See Error Shape section
}

event.duration_ms = Date.now() - startTime

// Emit once at end
logger.info(event, 'Job completed')
```

### Queue Workers

```typescript
// Initialize event when message received
const event = {
  schema_version: '1.0.0',
  message_id: message.id,
  queue_name: 'payment-processing',
  timestamp: new Date().toISOString(),
  service: 'payment-service',
  environment: process.env.NODE_ENV,
  
  // Message context
  message_type: message.type,
  retry_count: message.retryCount,
  correlation_id: message.correlationId,
}

// Process message...
event.status = 'success'
event.duration_ms = Date.now() - startTime

logger.info(event, 'Message processed')
```

### Cron Jobs / Scheduled Tasks

```typescript
const event = {
  schema_version: '1.0.0',
  cron_job_id: generateCronJobId(),
  cron_schedule: '0 */6 * * *', // Every 6 hours
  job_name: 'cleanup_old_sessions',
  timestamp: new Date().toISOString(),
  service: 'session-service',
  environment: process.env.NODE_ENV,
  
  // Execution context
  records_deleted: deletedCount,
  records_checked: checkedCount,
  duration_ms: Date.now() - startTime,
  status: 'success',
}

logger.info(event, 'Cron job completed')
```

### Startup / Shutdown Events

```typescript
// Application startup
logger.info({
  schema_version: '1.0.0',
  event_type: 'startup',
  timestamp: new Date().toISOString(),
  service: process.env.SERVICE_NAME,
  version: process.env.VERSION,
  environment: process.env.NODE_ENV,
  deployment_id: process.env.DEPLOYMENT_ID,
  git_commit: process.env.GIT_COMMIT_SHA,
  node_version: process.version,
  memory_limit_mb: process.memoryUsage().heapTotal / 1024 / 1024,
}, 'Application started')

// Application shutdown
logger.info({
  schema_version: '1.0.0',
  event_type: 'shutdown',
  timestamp: new Date().toISOString(),
  service: process.env.SERVICE_NAME,
  uptime_seconds: process.uptime(),
  reason: 'SIGTERM', // or 'SIGINT', 'uncaught_exception', etc.
}, 'Application shutting down')
```

### Key Principle

**One log event per operation**, regardless of operation type:
- One event per HTTP request
- One event per background job execution
- One event per queue message processed
- One event per cron job run
- One event per startup/shutdown

---

## PII & Secrets Redaction Policy

### Never Log PII

**PII (Personally Identifiable Information)** must never appear in logs:

- Email addresses
- Phone numbers
- Physical addresses
- Full names (use user_id instead)
- Passwords (obviously)
- Credit card numbers
- SSNs / National IDs
- IP addresses (hash/anonymize - see below)

### Secrets Redaction List

| Category | Fields to Redact | Notes |
|----------|------------------|-------|
| **Headers** | `authorization`, `cookie`, `x-api-key`, `x-auth-token`, `x-session-token`, `x-csrf-token`, `x-access-token`, `x-refresh-token` | Always redact |
| **Query Params** | `token`, `api_key`, `secret`, `password`, `access_token`, `refresh_token` | Always redact |
| **Query Params** | `session_id` | Redact unless intentionally logging separately |
| **Body Fields** | `password`, `password_confirmation`, `credit_card`, `cvv`, `ssn`, `social_security_number` | Always redact |
| **OAuth Provider Config** | `clientSecret`, `client_secret` | **CRITICAL**: OAuth client secrets must NEVER be logged, even in development. Auth.js uses a custom sanitized logger that redacts secrets at the source. |

**⚠️ CRITICAL: OAuth Client Secrets**

OAuth client secrets (`clientSecret` or `client_secret`) must **NEVER** be logged, even in development environments. This includes:

- Auth.js provider configuration objects
- OAuth callback request bodies
- Debug logs from authentication libraries
- Any configuration objects containing OAuth credentials

**Implementation**: The codebase uses a custom Auth.js logger (`server/auth/sanitized-logger.ts`) that sanitizes sensitive data **before** logging. This logger is configured in the Auth.js config (`server/auth/config.ts`) and automatically redacts client secrets, tokens, and other sensitive fields. Debug logging is disabled by default and can be enabled via `AUTH_DEBUG=true` or `AUTH_VERBOSE_LOGS=1` environment variables, but secrets will always be redacted.

```typescript
const REDACTED_HEADERS = ['authorization', 'cookie', 'x-api-key', 'x-auth-token', 'x-session-token', 'x-csrf-token', 'x-access-token', 'x-refresh-token']
const REDACTED_QUERY_PARAMS = ['token', 'api_key', 'secret', 'password', 'access_token', 'refresh_token', 'session_id']
const REDACTED_BODY_FIELDS = ['password', 'password_confirmation', 'credit_card', 'cvv', 'ssn', 'social_security_number']
// OAuth client secrets (both camelCase and snake_case) - CRITICAL: Never log these
const REDACTED_OAUTH_FIELDS = ['clientSecret', 'client_secret']
```

### Query Parameters Allowlist

**Never log all query parameters blindly.** Use an allowlist approach:

```typescript
// Define allowed query params per endpoint
const ALLOWED_QUERY_PARAMS = {
  '/api/users': ['limit', 'offset', 'sort', 'filter'],
  '/api/projects': ['workspace_id', 'status', 'limit'],
  '/api/search': ['q', 'type', 'limit'],
  // ... etc
}

function filterQueryParams(query: Record<string, unknown>, allowed: string[]): Record<string, unknown> {
  const filtered: Record<string, unknown> = {}
  for (const key of allowed) {
    if (key in query) {
      filtered[key] = query[key]
    }
  }
  return filtered
}

// Usage
event.query_params = filterQueryParams(req.query, ALLOWED_QUERY_PARAMS[req.path] || [])
```

**Rationale**: Query parameters can contain sensitive tokens, API keys, or PII. Only log what you explicitly allow.

### Request/Response Body Logging Policy

**CRITICAL**: **Never log request or response bodies unless explicitly allowlisted and sanitized.**

Request and response bodies can contain:
- Passwords
- Credit card numbers
- PII (emails, addresses, phone numbers)
- API keys and tokens
- Sensitive business data

#### Body Logging Rules

1. **Default**: **Never log bodies** - Log metadata only (size, content-type, etc.)
2. **Exception**: Only log bodies for specific endpoints that are explicitly allowlisted
3. **Sanitization**: All logged bodies must be sanitized using the same redaction rules as query params/headers

#### Implementation

```typescript
// Define endpoints where body logging is allowed (very restrictive)
const ALLOWED_BODY_LOGGING_ENDPOINTS = [
  '/api/public/contact',  // Public contact form (no sensitive data)
  // Add endpoints only after security review
]

function shouldLogBody(path: string, method: string): boolean {
  // Only allow for specific endpoints
  return ALLOWED_BODY_LOGGING_ENDPOINTS.includes(path)
}

function sanitizeBody(body: unknown, redactedFields: string[]): unknown {
  if (!body || typeof body !== 'object') {
    return body
  }
  
  const sanitized = { ...body as Record<string, unknown> }
  
  // Remove redacted fields
  for (const field of redactedFields) {
    delete sanitized[field]
  }
  
  // Recursively sanitize nested objects
  for (const [key, value] of Object.entries(sanitized)) {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      sanitized[key] = sanitizeBody(value, redactedFields)
    }
  }
  
  return sanitized
}

// Usage in middleware/handler
if (shouldLogBody(req.path, req.method)) {
  const sanitizedBody = sanitizeBody(req.body, REDACTED_BODY_FIELDS)
  event.request_body = sanitizedBody
  event.request_body_size_bytes = JSON.stringify(req.body).length
} else {
  // Log metadata only
  event.request_body_size_bytes = req.headers['content-length'] 
    ? parseInt(req.headers['content-length'])
    : JSON.stringify(req.body || {}).length
  event.request_content_type = req.headers['content-type']
  // Do NOT log request_body
}

// Same for response bodies
if (shouldLogBody(req.path, req.method)) {
  const sanitizedResponse = sanitizeBody(res.body, REDACTED_BODY_FIELDS)
  event.response_body = sanitizedResponse
  event.response_body_size_bytes = JSON.stringify(res.body).length
} else {
  event.response_body_size_bytes = res.headers['content-length']
    ? parseInt(res.headers['content-length'])
    : JSON.stringify(res.body || {}).length
  event.response_content_type = res.headers['content-type']
  // Do NOT log response_body
}
```

#### Body Logging Decision Tree

```
Is endpoint in ALLOWED_BODY_LOGGING_ENDPOINTS?
├─ NO → Log metadata only (size, content-type)
└─ YES → Sanitize body → Log sanitized body + metadata
```

**Rationale**: Bodies are the highest-risk PII source. Default to never logging them. Only log when:
1. Endpoint is explicitly allowlisted
2. Security team has reviewed the endpoint
3. Body is sanitized using redaction rules
4. No sensitive data can leak

### Headers Allowlist

Similarly, use an allowlist for headers:

```typescript
const ALLOWED_HEADERS = [
  'user-agent',
  'accept',
  'accept-language',
  'content-type',
  'x-forwarded-for', // Hash this - see below
  'x-request-id',
  'x-correlation-id',
]

function filterHeaders(headers: Record<string, unknown>, allowed: string[]): Record<string, unknown> {
  const filtered: Record<string, unknown> = {}
  for (const key of allowed) {
    const lowerKey = key.toLowerCase()
    if (lowerKey in headers) {
      filtered[lowerKey] = headers[lowerKey]
    }
  }
  return filtered
}

event.headers = filterHeaders(req.headers, ALLOWED_HEADERS)
```

### IP Address Anonymization

**Always hash or anonymize IP addresses**:

```typescript
import { createHash } from 'crypto'

function hashIP(ip: string): string {
  // Hash IP to prevent PII exposure while maintaining cardinality for abuse detection
  return createHash('sha256').update(ip).digest('hex').substring(0, 16)
}

event.ip = hashIP(req.ip)
event.ip_hash = hashIP(req.ip) // Alternative: explicit naming
```

### Email Redaction

If you must log email-related context, use hashed versions:

```typescript
// ❌ BAD
event.user_email = user.email

// ✅ GOOD
event.user_email_hash = hashEmail(user.email) // Or just use user_id
```

### Implementation Pattern

```typescript
function sanitizeEvent(event: Record<string, unknown>): Record<string, unknown> {
  const sanitized = { ...event }
  
  // Redact headers
  if (sanitized.headers) {
    sanitized.headers = filterHeaders(sanitized.headers as Record<string, unknown>, ALLOWED_HEADERS)
    // Remove redacted headers
    for (const header of REDACTED_HEADERS) {
      delete (sanitized.headers as Record<string, unknown>)[header.toLowerCase()]
    }
  }
  
  // Redact query params
  if (sanitized.query_params) {
    const allowed = ALLOWED_QUERY_PARAMS[sanitized.path as string] || []
    sanitized.query_params = filterQueryParams(
      sanitized.query_params as Record<string, unknown>,
      allowed
    )
    // Remove redacted params
    for (const param of REDACTED_QUERY_PARAMS) {
      delete (sanitized.query_params as Record<string, unknown>)[param]
    }
  }
  
  // Hash IP
  if (sanitized.ip) {
    sanitized.ip = hashIP(sanitized.ip as string)
  }
  
  return sanitized
}

// Before logging
const sanitizedEvent = sanitizeEvent(event)
logger.info(sanitizedEvent, 'Request completed')
```

---

## Size Limits & Truncation

### Maximum Event Size

**Maximum event size: 100 KB** (after JSON serialization).

Events exceeding this limit must be truncated. Log a warning when truncation occurs.

### Field-Level Limits

| Field Type | Limit | Value | Unit |
|------------|-------|-------|------|
| **Strings** | `max_string_length` | 10000 | bytes (10 KB) |
| **Error Messages** | `max_message_length` | 5000 | bytes (5 KB) |
| **Paths** | `max_path_length` | 2048 | bytes (2 KB) |
| **Stack Traces** | `max_stack_trace_length` | 50000 | bytes (50 KB) |
| **Arrays** | `max_array_length` | 1000 | items |
| **Array Items** | `max_array_item_length` | 1000 | bytes (1 KB) |
| **Objects** | `max_object_depth` | 10 | levels |
| **Objects** | `max_object_keys` | 500 | keys |
| **Total Event** | `max_event_size` | 100000 | bytes (100 KB) |

```typescript
const SIZE_LIMITS = {
  max_string_length: 10000,
  max_message_length: 5000,
  max_path_length: 2048,
  max_stack_trace_length: 50000,
  max_array_length: 1000,
  max_array_item_length: 1000,
  max_object_depth: 10,
  max_object_keys: 500,
}
```

### Truncation Strategy

**Truncate, don't drop.** Always indicate truncation:

```typescript
function truncateString(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str
  return str.substring(0, maxLength - 50) + '...[TRUNCATED ' + (str.length - maxLength + 50) + ' chars]'
}

function truncateStack(stack: string): string {
  if (stack.length <= SIZE_LIMITS.max_stack_trace_length) return stack
  
  // Keep first N lines (most important) and last line
  const lines = stack.split('\n')
  const keepFirst = 50
  const keepLast = 5
  
  if (lines.length <= keepFirst + keepLast) return stack
  
  const truncated = [
    ...lines.slice(0, keepFirst),
    `...[TRUNCATED ${lines.length - keepFirst - keepLast} lines]`,
    ...lines.slice(-keepLast)
  ].join('\n')
  
  return truncateString(truncated, SIZE_LIMITS.max_stack_trace_length)
}

function truncateArray<T>(arr: T[], maxLength: number): T[] {
  if (arr.length <= maxLength) return arr
  return [
    ...arr.slice(0, maxLength),
    `...[TRUNCATED ${arr.length - maxLength} items]` as unknown as T
  ]
}
```

### Implementation

```typescript
function enforceSizeLimits(event: Record<string, unknown>): Record<string, unknown> {
  const limited = JSON.parse(JSON.stringify(event)) // Deep clone to avoid mutating original
  let truncated = false
  
  // Recursively truncate nested objects
  function truncateValue(obj: unknown, path: string = ''): unknown {
    if (typeof obj === 'string') {
      const maxLength = path === 'error.stack' || path.endsWith('.stack')
        ? SIZE_LIMITS.max_stack_trace_length
        : path.includes('message') || path.endsWith('.message')
        ? SIZE_LIMITS.max_message_length
        : SIZE_LIMITS.max_string_length
      
      if (obj.length > maxLength) {
        truncated = true
        return truncateString(obj, maxLength)
      }
      return obj
    }
    
    if (Array.isArray(obj)) {
      if (obj.length > SIZE_LIMITS.max_array_length) {
        truncated = true
        return truncateArray(obj, SIZE_LIMITS.max_array_length)
      }
      return obj.map((item, idx) => truncateValue(item, `${path}[${idx}]`))
    }
    
    if (obj && typeof obj === 'object' && !Array.isArray(obj)) {
      const result: Record<string, unknown> = {}
      for (const [key, value] of Object.entries(obj)) {
        const newPath = path ? `${path}.${key}` : key
        result[key] = truncateValue(value, newPath)
      }
      return result
    }
    
    return obj
  }
  
  const truncatedEvent = truncateValue(limited) as Record<string, unknown>
  
  if (truncated) {
    truncatedEvent._truncated = true
    truncatedEvent._truncation_warning = 'Event was truncated due to size limits'
  }
  
  // Check total size
  const jsonSize = JSON.stringify(truncatedEvent).length
  if (jsonSize > 100 * 1024) {
    // Aggressive truncation needed
    truncatedEvent._error = 'Event exceeds 100KB limit - aggressive truncation applied'
    // Remove large optional fields
    if (truncatedEvent.error && typeof truncatedEvent.error === 'object') {
      delete (truncatedEvent.error as Record<string, unknown>).stack
    }
    delete truncatedEvent.headers
    delete truncatedEvent.query_params
  }
  
  return truncatedEvent
}
```

---

## Error Shape & Stack Hygiene

### Standard Error Object Shape

All errors in events must follow this structure:

```typescript
{
  error: {
    type: string              // Required: Error class name (e.g., 'PaymentError', 'ValidationError')
    message: string           // Required: Error message (max 5000 chars)
    code?: string             // Optional: Error code (e.g., 'card_declined', 'invalid_input')
    error_category: string    // Required: See Error Category section ('validation' | 'auth' | 'external' | etc.)
    error_fingerprint?: string // Optional: Hash for error grouping (included when stack is present)
    stack?: string            // Optional: Stack trace (truncated, see rules below)
    retriable?: boolean       // Optional: Can this be retried?
    status_code?: number      // Optional: HTTP status code if applicable
    // Provider-specific fields
    stripe_decline_code?: string
    // ... other provider codes
  }
}
```

**Error Fingerprint**: When a stack trace is included, also include `error_fingerprint` - a hash derived from error type + normalized message + top stack frame. This enables reliable error grouping and alerting (see Error Grouping section).

### Stack Trace Rules

**When to include stack traces**:

- ✅ **Always include** for:
  - Unhandled exceptions (status >= 500)
  - Errors in production (not development)
  - Errors from external services
  
- ❌ **Never include** for:
  - Expected errors (4xx status codes)
  - Validation errors
  - User input errors
  - Rate limiting errors

**Rationale**: Stack traces are large and noisy. Only include when they add debugging value.

### Stack Trace Truncation

Stack traces must be truncated (see Size Limits section):

```typescript
import { createHash } from 'crypto'

function formatError(error: Error | unknown, includeStack: boolean = false): Record<string, unknown> {
  const errorObj: Record<string, unknown> = {
    type: error instanceof Error ? error.constructor.name : 'Error',
    message: error instanceof Error ? error.message : String(error),
    error_category: determineErrorCategory(error), // See determineErrorCategory function below
  }
  
  if (error instanceof Error) {
    if ('code' in error) {
      errorObj.code = error.code
    }
    
    if (includeStack && error.stack) {
      errorObj.stack = truncateStack(error.stack)
      // Generate error fingerprint for grouping/alerting
      errorObj.error_fingerprint = generateErrorFingerprint(error)
    }
    
    // Check if error is retriable
    if ('retriable' in error) {
      errorObj.retriable = error.retriable
    }
    
    // Determine error category
    if ('statusCode' in error) {
      const status = error.statusCode as number
      if (status >= 400 && status < 500) {
        if (status === 401) errorObj.error_category = 'auth'
        else if (status === 403) errorObj.error_category = 'authorization'
        else if (status === 429) errorObj.error_category = 'rate_limit'
        else errorObj.error_category = 'validation'
      } else if (status >= 500) {
        errorObj.error_category = 'internal'
      }
    }
  }
  
  return errorObj
}

### Catch Block Rules

Every `catch` block in the codebase MUST do at least one of:
1. **Log the error** — at minimum `logger.warn` with the error message and context
2. **Re-throw the error** — propagate to a higher-level handler
3. **Return an error response** — with the error info included

**Prohibited patterns:**
- `catch(() => {})` — swallows errors silently, makes debugging impossible
- `catch {}` — empty catch block with no logging
- `catch (e) { /* ignore */ }` — commented-out error handling

**"Fire-and-forget" still requires logging:**
"Fire-and-forget" means "don't block on the result." It does NOT mean "swallow errors silently." Fire-and-forget operations MUST still log failures at `warn` level so they appear in observability tools.

```typescript
// WRONG: fire-and-forget with silent swallow
void sendNotification(payload).catch(() => {})

// CORRECT: fire-and-forget with warn logging
void sendNotification(payload).catch((err) => {
  logger.warn(
    sanitizeAndLimit({ error: err instanceof Error ? err.message : String(err) }),
    'notification_send_failed'
  )
})
```

**Minimum viable catch block:**
```typescript
catch (err) {
  logger.warn({ error: err instanceof Error ? err.message : String(err) }, 'operation_name_failed')
}
```

### Error Grouping & Fingerprinting

**Error fingerprinting** enables reliable error grouping and alerting by creating a stable identifier for similar errors.

**When to include**: Include `error_fingerprint` whenever a stack trace is included (i.e., for 5xx errors).

**Fingerprint generation**:

```typescript
import { createHash } from 'crypto'

function generateErrorFingerprint(error: Error): string {
  // Create fingerprint from: type + normalized message + top stack frame
  // This enables reliable error grouping and alerting
  
  const type = error.constructor.name
  
  // Normalize message: remove variable parts (IDs, timestamps, etc.)
  const normalizedMessage = normalizeErrorMessage(error.message)
  
  // Extract top stack frame (file:line:column)
  let topFrame = ''
  if (error.stack) {
    const lines = error.stack.split('\n')
    if (lines.length > 1) {
      // Match: "at functionName (file:line:column)" or "at file:line:column"
      const match = lines[1].match(/at\s+(?:\S+\s+)?\(?([^:]+):(\d+):(\d+)\)?/)
      if (match) {
        const file = match[1].split('/').pop() // Just filename
        const line = match[2]
        topFrame = `${file}:${line}`
      }
    }
  }
  
  // Create hash
  const fingerprint = `${type}:${normalizedMessage}${topFrame ? `:${topFrame}` : ''}`
  return createHash('sha256').update(fingerprint).digest('hex').substring(0, 16)
}
```

**Benefits**:
- **Error aggregation**: Group similar errors together regardless of variable data (user IDs, timestamps, etc.)
- **Alerting**: Set up alerts based on error fingerprint frequency
- **Trend analysis**: Track error fingerprint trends over time
- **Root cause identification**: Quickly identify which error patterns are most common

**Example**: These errors would have the same fingerprint:
- `PaymentError: Card declined for user_123`
- `PaymentError: Card declined for user_456`
- `PaymentError: Card declined for user_789`

All normalize to: `PaymentError: Card declined for <id>` → same fingerprint.

function normalizeErrorMessage(message: string): string {
  // Remove variable parts that prevent grouping:
  // - UUIDs: replace with <uuid>
  // - IDs: replace with <id>
  // - Timestamps: replace with <timestamp>
  // - Numbers: replace with <number>
  
  return message
    .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '<uuid>')
    .replace(/\b(user_|req_|session_|workspace_)[a-z0-9_]+/gi, '<id>')
    .replace(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/g, '<timestamp>')
    .replace(/\b\d+\b/g, '<number>')
}

function determineErrorCategory(error: unknown): string {
  if (error instanceof Error) {
    const name = error.constructor.name.toLowerCase()
    if (name.includes('validation')) return 'validation'
    if (name.includes('auth')) return 'auth'
    if (name.includes('timeout')) return 'timeout'
    if (name.includes('rate') || name.includes('limit')) return 'rate_limit'
    if ('statusCode' in error) {
      const status = (error as { statusCode: number }).statusCode
      if (status >= 500) return 'internal'
      if (status >= 400) return 'validation'
    }
  }
  return 'unknown'
}

// Usage
if (event.status_code >= 500) {
  event.error = formatError(error, true) // Include stack for 5xx
} else {
  event.error = formatError(error, false) // No stack for 4xx
}
```

### Error Type Enumeration

Define standard error types for consistency:

```typescript
type ErrorType =
  | 'ValidationError'
  | 'AuthenticationError'
  | 'AuthorizationError'
  | 'PaymentError'
  | 'ExternalServiceError'
  | 'DatabaseError'
  | 'RateLimitError'
  | 'TimeoutError'
  | 'InternalError'
  | 'UnknownError'
```

---

## Client Logging Endpoint Hardening

Client-side logging endpoints are an **attack surface**. They must be hardened.

### Required Security Measures

#### 1. Rate Limiting

**Per-IP rate limiting** (using Upstash Redis or similar):

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '1 m'), // 10 requests per minute per IP
  analytics: true,
})

export async function POST(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for') || 'unknown'
  const { success, limit, remaining } = await ratelimit.limit(`client-log:${ip}`)
  
  if (!success) {
    return Response.json(
      { error: 'Rate limit exceeded' },
      { status: 429 }
    )
  }
  
  // Process log...
}
```

#### 2. Payload Size Limits

**Maximum payload size: 50 KB**:

```typescript
const MAX_PAYLOAD_SIZE = 50 * 1024 // 50 KB

export async function POST(request: NextRequest) {
  const contentLength = request.headers.get('content-length')
  if (contentLength && parseInt(contentLength) > MAX_PAYLOAD_SIZE) {
    return Response.json(
      { error: 'Payload too large' },
      { status: 413 }
    )
  }
  
  const body = await request.json()
  const bodySize = JSON.stringify(body).length
  
  if (bodySize > MAX_PAYLOAD_SIZE) {
    return Response.json(
      { error: 'Payload too large' },
      { status: 413 }
    )
  }
  
  // Process log...
}
```

#### 3. Authentication / CSRF Protection

**Require authentication or CSRF token**:

```typescript
// Option 1: Require authenticated session
export async function POST(request: NextRequest) {
  const session = await getSession(request)
  if (!session) {
    return Response.json(
      { error: 'Unauthorized' },
      { status: 401 }
    )
  }
  
  // Process log...
}

// Option 2: CSRF token validation
export async function POST(request: NextRequest) {
  const csrfToken = request.headers.get('x-csrf-token')
  if (!csrfToken || !validateCSRFToken(csrfToken)) {
    return Response.json(
      { error: 'Invalid CSRF token' },
      { status: 403 }
    )
  }
  
  // Process log...
}
```

#### 4. Input Validation & Sanitization

**Validate and sanitize all input**:

```typescript
import { z } from 'zod'

const ClientLogSchema = z.object({
  request_id: z.string().max(100),
  error: z.object({
    type: z.string().max(100),
    message: z.string().max(5000),
    stack: z.string().max(50000).optional(),
  }).optional(),
  operation: z.string().max(100),
  pathname: z.string().max(2048),
  query_params: z.record(z.unknown()).optional(),
  user_agent: z.string().max(1000),
  timestamp: z.string(),
})

export async function POST(request: NextRequest) {
  const body = await request.json()
  
  const validation = ClientLogSchema.safeParse(body)
  if (!validation.success) {
    return Response.json(
      { error: 'Invalid payload', details: validation.error },
      { status: 400 }
    )
  }
  
  const sanitized = sanitizeEvent(validation.data) // Apply PII redaction
  logger.error(sanitized, 'Client error received')
  
  return Response.json({ success: true })
}
```

#### 5. Sampling for Client Logs

**Apply sampling to client logs** to prevent abuse:

```typescript
function shouldSampleClientLog(event: Record<string, unknown>): boolean {
  // Always keep errors from authenticated users
  if (event.user_id && event.error) {
    return true
  }
  
  // Sample other logs at 1% rate
  const sampleRate = parseFloat(process.env.CLIENT_LOG_SAMPLE_RATE || '0.01')
  return Math.random() < sampleRate
}

export async function POST(request: NextRequest) {
  // ... validation, rate limiting, etc.
  
  const event = validation.data
  
  // Sanitize before sampling/logging
  const sanitized = sanitizeEvent(event)
  
  if (shouldSampleClientLog(sanitized)) {
    logger.error(sanitized, 'Client error received')
  }
  
  // Always return success to avoid error loops
  return Response.json({ success: true })
}
```

#### 6. Abuse Detection

**Monitor for abuse patterns**:

```typescript
// Track suspicious patterns
const suspiciousPatterns = [
  /password/i,
  /token/i,
  /secret/i,
  /api[_-]?key/i,
]

function detectAbuse(event: Record<string, unknown>): boolean {
  const eventStr = JSON.stringify(event).toLowerCase()
  return suspiciousPatterns.some(pattern => pattern.test(eventStr))
}

export async function POST(request: NextRequest) {
  // ... validation, etc.
  
  if (detectAbuse(event)) {
    // Log abuse attempt but don't process
    logger.warn({
      ip: request.headers.get('x-forwarded-for'),
      event_preview: JSON.stringify(event).substring(0, 500),
      abuse_detected: true,
    }, 'Client log abuse detected')
    
    return Response.json({ success: true }) // Don't reveal detection
  }
  
  // Process normally...
}
```

### Complete Hardened Endpoint Example

```typescript
// apps/web/src/app/api/log-error/route.ts
import { NextRequest } from 'next/server'
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'
import { z } from 'zod'
import { logger } from '@/lib/logger'
import { sanitizeEvent } from '@/lib/log-sanitizer'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '1 m'),
})

const ClientLogSchema = z.object({
  request_id: z.string().max(100),
  error: z.object({
    type: z.string().max(100),
    message: z.string().max(5000),
    stack: z.string().max(50000).optional(),
  }).optional(),
  operation: z.string().max(100),
  pathname: z.string().max(2048),
  query_params: z.record(z.unknown()).optional(),
  user_agent: z.string().max(1000),
  timestamp: z.string(),
})

const MAX_PAYLOAD_SIZE = 50 * 1024

export async function POST(request: NextRequest) {
  // Rate limiting
  const ip = request.headers.get('x-forwarded-for') || 'unknown'
  const { success } = await ratelimit.limit(`client-log:${ip}`)
  if (!success) {
    return Response.json({ error: 'Rate limit exceeded' }, { status: 429 })
  }
  
  // Payload size check
  const contentLength = request.headers.get('content-length')
  if (contentLength && parseInt(contentLength) > MAX_PAYLOAD_SIZE) {
    return Response.json({ error: 'Payload too large' }, { status: 413 })
  }
  
  // Parse and validate
  const body = await request.json()
  if (JSON.stringify(body).length > MAX_PAYLOAD_SIZE) {
    return Response.json({ error: 'Payload too large' }, { status: 413 })
  }
  
  const validation = ClientLogSchema.safeParse(body)
  if (!validation.success) {
    return Response.json({ error: 'Invalid payload' }, { status: 400 })
  }
  
  // Sanitize and sample
  const sanitized = sanitizeEvent(validation.data)
  
  if (shouldSampleClientLog(sanitized)) {
    logger.error({
      ...sanitized,
      service: 'web',
      source: 'client',
    }, 'Client error received')
  }
  
  // Always return success to avoid error loops
  return Response.json({ success: true })
}
```

---

## Environment Rules

### Environment Rules Summary

| Rule | Development | Test | Production |
|------|-------------|------|------------|
| **Sampling** | Disabled | Disabled | Enabled |
| **Stack Traces** | Always | Always | Only 5xx |
| **Debug Level** | Enabled | Enabled | Disabled |
| **Console Logs** | ❌ No | ❌ No | ❌ No |
| **PII Redaction** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Logger** | Pino | Test logger | Pino |

**Development**: Full visibility, but follows production patterns.  
**Test**: Mock logger for assertions.  
**Production**: Tail sampling, minimal stack traces, strict PII.

**Example test logger**:

```typescript
export const testLogger = {
  logs: [] as Array<{ level: string; event: Record<string, unknown>; message?: string }>,
  info(event: Record<string, unknown>, message?: string) { this.logs.push({ level: 'info', event, message }) },
  error(event: Record<string, unknown>, message?: string) { this.logs.push({ level: 'error', event, message }) },
  clear() { this.logs = [] },
}
```

### Lint Enforcement

**ESLint rules** to enforce no `console.*`:

```json
// .eslintrc.json
{
  "rules": {
    "no-console": ["error", {
      "allow": [] // No console methods allowed
    }]
  }
}
```

**TypeScript**: Consider using a custom type that removes `console` from global scope in production builds.

---

## Retention & Access & Compliance

### Log Retention Policy

| Log Type | Retention | Reason |
|----------|-----------|--------|
| Production logs | 90 days | Standard debugging window |
| Error logs (status >= 500) | 365 days | Trend analysis |
| Audit events | 7 years | Compliance requirement |
| Security events | 2 years | Investigation needs |
| Development logs | 7 days | Short-term debugging |
| Test logs | 1 day | Minimal retention |

**Rationale**: Balance between debugging needs and storage costs. Errors kept longer for trend analysis. Audit and security events have longer retention for compliance and investigation purposes.

### Log Access Control

**Who can access logs**:

- **Engineering team**: Full access to all logs
- **Support team**: Read-only access to production logs (last 30 days)
- **Security team**: Full access + audit logs
- **Compliance team**: Read-only access for audits

**Access logging**: All log access must be logged for audit purposes:

```typescript
logger.info({
  event_type: 'log_access',
  accessed_by: userId,
  accessed_service: serviceName,
  accessed_time_range: { start, end },
  accessed_filters: filters,
}, 'Log access granted')
```

### GDPR / CCPA Compliance

**Right to deletion**: When a user requests deletion:

1. **Identify logs**: Find all logs containing `user_id = X`
2. **Anonymize or delete**: Either delete logs or replace `user_id` with anonymized identifier
3. **Log the action**: Log the deletion/anonymization for audit

```typescript
async function handleUserDeletionRequest(userId: string) {
  // Find all logs for user
  const logs = await findLogsByUserId(userId)
  
  // Anonymize user_id in logs
  for (const log of logs) {
    await updateLog(log.id, {
      user_id: `deleted_${hashUserId(userId)}`,
      user_deleted_at: new Date().toISOString(),
    })
  }
  
  // Log the action
  logger.info({
    event_type: 'user_data_deletion',
    deleted_user_id_hash: hashUserId(userId),
    logs_affected: logs.length,
    deleted_at: new Date().toISOString(),
  }, 'User data deleted from logs')
}
```

**Right to access**: Provide users with their log data upon request (anonymized, no PII).

**Data minimization**: Only log what's necessary for debugging/observability.

---

## Sampling Configurability

### Environment Variables

| Variable | Default | Description | Unit |
|----------|---------|-------------|------|
| `LOG_SAMPLE_RATE` | `0.05` | Success request sampling rate | ratio (5%) |
| `LOG_P99_THRESHOLD_MS` | `2000` | Slow request threshold (always kept) | milliseconds |
| `LOG_VIP_USER_IDS` | - | Comma-separated VIP user IDs (always kept) | list |
| `LOG_ALWAYS_KEEP_FEATURE_FLAGS` | - | Feature flags that trigger "always keep" | list |
| `CLIENT_LOG_SAMPLE_RATE` | `0.01` | Client log sampling rate | ratio (1%) |
| `LOG_DISABLE_SAMPLING` | `false` | Disable sampling (dev only) | boolean |

```bash
LOG_SAMPLE_RATE=0.05
LOG_P99_THRESHOLD_MS=2000
LOG_VIP_USER_IDS=user_123,user_456
LOG_ALWAYS_KEEP_FEATURE_FLAGS=new_checkout_flow,experiment_xyz
CLIENT_LOG_SAMPLE_RATE=0.01
LOG_DISABLE_SAMPLING=false
```

### Sampling Decision Logic

**Order of evaluation** (first match wins):

| Priority | Condition | Action | Rate |
|----------|-----------|--------|------|
| 1 | `status_code >= 500` OR `error` present | Keep | 100% |
| 2 | `duration_ms > LOG_P99_THRESHOLD_MS` | Keep | 100% |
| 3 | `user.id` in `LOG_VIP_USER_IDS` | Keep | 100% |
| 4 | Feature flag in `LOG_ALWAYS_KEEP_FEATURE_FLAGS` is `true` | Keep | 100% |
| 5 | All others | Sample | `LOG_SAMPLE_RATE` |

### Implementation

```typescript
function shouldSample(event: Record<string, unknown>): boolean {
  // Development: Disable sampling
  if (process.env.LOG_DISABLE_SAMPLING === 'true') {
    return true // Always log in dev
  }
  
  // Always keep errors
  if (event.status_code >= 500 || event.error) {
    return true
  }
  
  // Always keep slow requests
  const p99Threshold = parseInt(process.env.LOG_P99_THRESHOLD_MS || '2000')
  if (event.duration_ms > p99Threshold) {
    return true
  }
  
  // Always keep VIP users
  const vipUsers = (process.env.LOG_VIP_USER_IDS || '').split(',').filter(Boolean)
  if (event.user?.id && vipUsers.includes(event.user.id)) {
    return true
  }
  
  // Always keep specific feature flags
  const alwaysKeepFlags = (process.env.LOG_ALWAYS_KEEP_FEATURE_FLAGS || '').split(',').filter(Boolean)
  if (event.feature_flags) {
    for (const flag of alwaysKeepFlags) {
      if (event.feature_flags[flag] === true) {
        return true
      }
    }
  }
  
  // Random sample the rest
  const sampleRate = parseFloat(process.env.LOG_SAMPLE_RATE || '0.05')
  return Math.random() < sampleRate
}
```

### Sampling Metrics (Log Only, No Polling)

**Track sampling rates** by logging them in events:

```typescript
// Log sampling decision for analytics (included in event, not stored separately)
event._sampling = {
  sampled: shouldSample(event),
  reason: getSamplingReason(event), // 'error' | 'slow' | 'vip' | 'feature_flag' | 'random'
  sample_rate: parseFloat(process.env.LOG_SAMPLE_RATE || '0.05'),
}
```

**⚠️ CRITICAL**: Sampling metrics are logged as part of events, not collected via polling or monitoring endpoints. Metrics are derived from logs by querying your log aggregation system (e.g., Axiom, Datadog, etc.).

---

## Client-Side Logging

### Critical Rule: No Browser Console Logs

**NEVER use `console.log()`, `console.error()`, `console.warn()`, or any browser console methods in client-side code.**

Users should **never** be able to open browser DevTools and see logs in the console. All client-side logs must be sent to the server, where they are logged using Pino.

### Why This Matters

1. **Security**: Console logs can expose sensitive information to users
2. **Consistency**: All logs should be centralized on the server for querying and analysis
3. **Production readiness**: Console logs are not production-grade observability
4. **User experience**: Users shouldn't see internal debugging information

### Client-Side Logging Pattern

All client-side code must send logs to server-side API endpoints that use Pino:

```typescript
// ✅ GOOD: Send to server
import { logError } from '@/lib/client-logger'

try {
  // ... code that might error
} catch (error) {
  logError(error, {
    operation: 'checkout_payment',
    user_id: userId,
    cart_id: cartId,
    // ... other context
  })
  // Error is sent to /api/log-error endpoint which logs with Pino
}

// ❌ BAD: Never do this
console.error('Payment failed', error)
console.log('User action:', action)
```

### Client-Side Logging Implementation

1. **Client-side code** calls logging functions (e.g., `logError()`, `logInfo()`)
2. **Logging functions** send structured events to server API endpoints (e.g., `/api/log-error`)
3. **Server API endpoints** receive the events and log them using **Pino only**
4. **Pino** outputs structured JSON logs to stdout/stderr

### Example: Client-Side Error Logging

```typescript
// apps/web/src/lib/client-logger.ts

// Define allowed query params for client-side logging (very restrictive)
const CLIENT_ALLOWED_QUERY_PARAMS = ['workspace_id', 'project_id', 'view']

function filterClientQueryParams(searchParams: URLSearchParams): Record<string, unknown> {
  const filtered: Record<string, unknown> = {}
  for (const key of CLIENT_ALLOWED_QUERY_PARAMS) {
    const value = searchParams.get(key)
    if (value !== null) {
      filtered[key] = value
    }
  }
  return filtered
}

export function logError(error: Error | unknown, context?: Record<string, unknown>) {
  const errorLog = {
    // Server will override/validate these fields (see Trust Boundary section)
    request_id: generateRequestId(),
    correlation_id: context?.correlation_id || generateCorrelationId(),
    error: {
      type: error instanceof Error ? error.name : 'Error',
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    },
    operation: context?.operation || 'client_error',
    pathname: window.location.pathname,
    // Filter query params using allowlist (never send all query params)
    query_params: filterClientQueryParams(new URLSearchParams(window.location.search)),
    user_agent: navigator.userAgent,
    timestamp: new Date().toISOString(),
    ...context,
  }

  // Send to server - fire and forget
  fetch('/api/log-error', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(errorLog),
  }).catch(() => {
    // Silently fail to avoid error loops
  })
}
```

### Example: Server-Side Log Receiver

```typescript
// apps/web/src/app/api/log-error/route.ts
import { logger } from '@/lib/logger' // Pino logger
import { sanitizeEvent } from '@/lib/log-sanitizer'
import { enforceSizeLimits } from '@/lib/log-limits'

export async function POST(request: NextRequest) {
  const body = await request.json()
  
  // TRUST BOUNDARY: Server must override/validate client-provided fields
  const session = await getSession(request) // Get server-validated session
  
  const event = {
    schema_version: '1.0.0',
    event_type: 'http_request', // Server sets this - never trust client
    request_id: generateRequestId(), // Server generates - never trust client
    correlation_id: body.correlation_id || generateCorrelationId(), // Can use client's if present
    timestamp: new Date().toISOString(),
    
    // Server-derived fields (never trust client)
    source: 'client',
    ip_hash: hashIP(request.headers.get('x-forwarded-for') || 'unknown'),
    session_id: session?.id, // Server-validated session
    user: session?.user ? { id: session.user.id } : undefined, // Server-validated user
    
    // Client-provided fields (sanitized)
    error: body.error,
    operation: body.operation || 'client_error',
    pathname: body.pathname,
    query_params: body.query_params, // Already filtered by client allowlist
    user_agent: body.user_agent,
    
    // Infrastructure context
    service: 'web',
    environment: process.env.NODE_ENV,
  }
  
  // Sanitize and enforce size limits
  const sanitized = sanitizeEvent(event)
  const limited = enforceSizeLimits(sanitized)
  
  // Log using Pino with wide event pattern
  logger.error(limited, 'Client error received')
  
  return Response.json({ success: true })
}
```

### Trust Boundary Rules for Client Logs

**CRITICAL**: Client logs are untrusted input. The server must:

1. **Override these fields** (never trust client):
   - `event_type`: Always set to `'http_request'` (or appropriate type)
   - `request_id`: Server generates new ID
   - `user.id`: Server validates from session/auth token
   - `session_id`: Server validates from session
   - `ip_hash`: Server derives from request headers
   - `service`: Server sets based on receiving service
   - `environment`: Server sets from env vars

2. **Validate these fields**:
   - `operation`: Must match allowed patterns (see Operation Naming)
   - `error`: Must match error schema
   - `query_params`: Must be filtered by allowlist (client should pre-filter, server re-validates)

3. **Add server-derived fields**:
   - `source: 'client'`: Indicates this log originated from client
   - `ip_hash`: Hashed IP from `x-forwarded-for` header
   - `session_id`: Validated session ID
   - `user.id`: Validated user ID from session

**Rationale**: Clients can be compromised or malicious. Never trust client-provided identifiers or metadata. Always validate and override critical fields.

### Anti-Patterns: Client-Side Logging

❌ **Bad**: Browser console logs
```typescript
console.log('User clicked button')
console.error('Payment failed', error)
console.warn('Slow network detected')
```

❌ **Bad**: Client-side logging libraries that don't send to server
```typescript
// Don't use client-side only logging libraries
import { logger } from 'some-client-logger'
logger.info('Event') // This goes to browser console - WRONG
```

✅ **Good**: Send all logs to server
```typescript
import { logError, logInfo } from '@/lib/client-logger'

logError(error, { operation: 'checkout' })
logInfo('User action', { action: 'button_click', button_id: 'submit' })
```

### Summary: Client-Side Logging Rules

1. **No `console.*` methods** in production client code
2. **All client logs** must be sent to server API endpoints
3. **Server endpoints** log using **Pino only**
4. **Pino** outputs structured JSON to stdout/stderr
5. **Use fire-and-forget** pattern - don't block UI on logging
6. **Follow wide event pattern** - include all context when sending to server

---

## Implementation Guide

> **Important**: This project uses **Pino only** for server-side logging. All code examples use Pino's signature: `logger.info(event, 'message')` where the event object comes first, followed by an optional message string.
> 
> **Pino Signature**: Always use `logger.info(event, 'message')` or `logger.info(event)` - never `logger.info('message', event)`.
> 
> All client-side logs must be sent to server endpoints that use Pino.

### Pattern: Middleware-Based Wide Event Builder

```typescript
// middleware/wideEvent.ts
export function wideEventMiddleware() {
  return async (ctx: Context, next: NextFunction) => {
    const startTime = Date.now()
    
    // Initialize the wide event with request context
    const event: Record<string, unknown> = {
      schema_version: '1.0.0',
      event_type: 'http_request',
      request_id: ctx.get('requestId') || generateRequestId(),
      trace_id: extractTraceId(ctx.req),
      correlation_id: getCorrelationId(ctx.req) || generateCorrelationId(),
      timestamp: new Date().toISOString(),
      method: ctx.req.method,
      path: ctx.req.path,
      // Filter query params using allowlist (see PII section)
      query_params: filterQueryParams(ctx.req.query, ALLOWED_QUERY_PARAMS[ctx.req.path] || []),
      // Filter headers using allowlist (see PII section)
      headers: filterHeaders(ctx.req.headers, ALLOWED_HEADERS),
      user_agent: ctx.req.headers['user-agent'],
      ip: hashIP(ctx.req.ip), // Always hash/anonymize IPs
      
      // Infrastructure context
      service: process.env.SERVICE_NAME,
      version: process.env.VERSION,
      deployment_id: process.env.DEPLOYMENT_ID,
      region: process.env.REGION,
      environment: process.env.NODE_ENV,
      git_commit: process.env.GIT_COMMIT_SHA,
    }
    
    // Make the event accessible to handlers
    ctx.set('wideEvent', event)
    
    try {
      await next()
      
      event.status_code = ctx.res.status
      event.status_class = `${Math.floor(ctx.res.status / 100)}xx` // e.g., '5xx'
      event.status = ctx.res.status >= 400 ? 'error' : 'success'
      
    } catch (error) {
      event.status_code = 500
      event.status_class = '5xx'
      event.status = 'error'
      event.error = formatError(error, ctx.res.status >= 500) // Include stack for 5xx
      throw error
    } finally {
      event.duration_ms = Date.now() - startTime
      
      // Sanitize and enforce size limits before logging
      const sanitized = sanitizeEvent(event)
      const limited = enforceSizeLimits(sanitized)
      
      // Tail sampling decision
      if (shouldSample(limited)) {
        logger.info(limited, 'Request completed')
      }
    }
  }
}
```

### Pattern: Enrich Event in Handlers

```typescript
app.post('/checkout', async (ctx) => {
  const event = ctx.get('wideEvent')
  const user = ctx.get('user')
  
  // Add user context
  event.user = {
    id: user.id,
    subscription_tier: user.plan,
    account_age_days: daysSince(user.createdAt),
    lifetime_value_cents: user.ltv,
  }
  
  // Add business context as you process
  const cart = await getCart(user.id)
  event.cart = {
    id: cart.id,
    item_count: cart.items.length,
    total_cents: cart.total,
    coupon_applied: cart.coupon?.code,
  }
  
  // Add feature flags
  event.feature_flags = {
    new_checkout_flow: await isFeatureEnabled('new_checkout_flow', user.id),
    express_payment: await isFeatureEnabled('express_payment', user.id),
  }
  
  // Process payment with timing
  const paymentStart = Date.now()
  const payment = await processPayment(cart, user)
  const paymentLatency = Date.now() - paymentStart
  
  event.payment = {
    method: payment.method,
    provider: payment.provider,
    latency_ms: paymentLatency,
    attempt: payment.attemptNumber,
  }
  
  // Track performance
  event.performance = {
    db_queries: getDBQueryCount(),
    db_query_time_ms: getDBQueryTime(),
    cache_hits: getCacheHits(),
    cache_misses: getCacheMisses(),
    external_calls: getExternalCallCount(),
    external_call_time_ms: getExternalCallTime(),
  }
  
  // If payment fails, add error details
  if (payment.error) {
    event.error = {
      type: 'PaymentError',
      code: payment.error.code,
      stripe_decline_code: payment.error.declineCode,
      retriable: payment.error.retriable,
    }
  }
  
  event.operation = 'checkout'
  
  return ctx.json({ orderId: payment.orderId })
})
```

### Pattern: Context Accumulation Throughout Request

The key insight: **Don't log when something happens. Add to the event when something happens.**

```typescript
// Step 1: Request received
const event = {
  request_id: generateRequestId(),
  method: 'POST',
  path: '/api/checkout',
  // ... request context
}

// Step 2: User authenticated
event.user = {
  id: user.id,
  subscription_tier: user.plan,
  // ... user context
}

// Step 3: Cart loaded
event.cart = {
  id: cart.id,
  item_count: cart.items.length,
  // ... cart context
}

// Step 4: Payment processed
event.payment = {
  method: payment.method,
  provider: payment.provider,
  // ... payment context
}

// Step 5: Request complete - emit once (Pino signature: event first, message second)
logger.info(event, 'Request completed')
```

---

## Tail Sampling

### ⚠️ MANDATORY: Tail Sampling is Required for Production

**Tail sampling is NOT optional** - it's mandatory for production logging. Without sampling, you'll log every request, which is:
- **Expensive**: Logging costs scale linearly with volume
- **Noisy**: Hard to find actual errors in a sea of success logs
- **Inefficient**: Most success logs aren't needed for debugging

### The Problem

If you log many fields per request at 10,000 requests per second, your observability bill will bankrupt you.

**Solution**: Tail sampling - make the sampling decision **after** the request completes, based on its outcome.

### ⚠️ Production Sampling Rules (Priority Order)

**Always Keep** (100% - Never Sample):
1. **Errors**: All status >= 500, all exceptions, all failures
   - **These are your PRIMARY concern** - you need 100% error visibility
2. **Slow requests**: Anything above your p99 latency threshold (default: 2000ms)
   - Performance issues are critical
3. **VIP users**: Configured list of users (enterprise customers, internal testing accounts)
   - High-value users need full visibility
4. **Feature flags**: Requests with specific feature flags enabled (for debugging rollouts)
   - New features need monitoring

**Sample** (default: 5% - Must Use Sampling):
- Successful requests (`status_code < 400`)
- Fast requests (< threshold)
- Normal business operations

**Remember**: In production, you want to see **ALL errors** but only a **SAMPLE of successes**. This reduces log volume by ~95% while maintaining full error visibility.

### Implementation

```typescript
function shouldSample(event: WideEvent): boolean {
  // Always keep errors
  if (event.status_code >= 500) return true
  if (event.error) return true
  
  // Always keep slow requests (above p99)
  const p99Threshold = parseInt(process.env.LOG_P99_THRESHOLD_MS || '2000')
  if (event.duration_ms > p99Threshold) return true
  
  // Always keep VIP users
  const vipUsers = process.env.LOG_VIP_USER_IDS?.split(',') || []
  if (event.user?.id && vipUsers.includes(event.user.id)) return true
  
  // Always keep requests with specific feature flags (debugging rollouts)
  if (event.feature_flags?.new_checkout_flow) return true
  
  // Random sample the rest at configured rate (default 5%)
  const sampleRate = parseFloat(process.env.LOG_SAMPLE_RATE || '0.05')
  return Math.random() < sampleRate
}

// ✅ CORRECT: Usage pattern - always check sampling
const event = { /* ... wide event ... */ }

// Sanitize and enforce size limits
const sanitized = sanitizeEvent(event)
const limited = enforceSizeLimits(sanitized)

// Error-first logging: Always log errors, sample successes
if (limited.status_code >= 500 || limited.error) {
  logger.error(limited, 'Request failed') // Always log errors
} else if (shouldSample(limited)) {
  logger.info(limited, 'Request completed') // Sample successes
}
// If shouldSample() returns false, the log is skipped (not logged)

// ❌ WRONG: Don't log without sampling check
// logger.info(limited, 'Request completed') // DON'T DO THIS!
```

### Cost Impact

- **Without sampling**: ~432 GB/day at 10,000 req/sec = ~$975/month
- **With tail sampling**: ~21.6 GB/day (5% success + 100% errors) = ~$50/month
- **Savings**: ~95% cost reduction

### Development vs Production

**Development**: Sampling is **automatically disabled** - see all logs for debugging.

**Production**: Sampling is **automatically enabled** - cost optimized.

---

## Best Practices

### 1. Always Include High-Cardinality Identifiers

Every log must include:
- `request_id` - Track individual requests
- `user.id` - Find all logs for a user (when available, nested under `user` object)
- `trace_id` - Correlate across services (when using OpenTelemetry)
- `correlation_id` - Cross-service correlation

**Note**: User identifier is `user.id` (nested). For query convenience in systems that don't handle nested fields well, you may also include `user_id` at top level that mirrors `user.id`, but `user.id` is the canonical source of truth.

### 2. Always Log Query Parameters (With Allowlist)

Query parameters are often overlooked but critical for debugging. Always include them, but **filter using an allowlist** to prevent logging sensitive data:

```typescript
// Use allowlist to filter query params (see PII Redaction section)
// Note: ALLOWED_QUERY_PARAMS is path-specific - use ALLOWED_QUERY_PARAMS[req.path] || []
event.query_params = filterQueryParams(req.query, ALLOWED_QUERY_PARAMS[req.path] || [])
```

See [PII & Secrets Redaction](#pii--secrets-redaction-policy) section for the allowlist approach.

### 3. Include Business Context

Don't just log technical details. Include business context:
- User subscription tier
- Cart value
- Feature flags enabled
- Account age
- Lifetime value

This enables queries like: "Are premium users experiencing more errors?"

### 4. Include Deployment Context

Always include:
- `deployment_id` - Which deployment
- `version` - Service version
- `git_commit` - Git commit SHA

This enables queries like: "Which deployment caused the latency regression?"

### 5. Track Performance Metrics (Log Only, No Polling)

Include performance context in logs:
- `duration_ms` - Total duration
- `db_queries` - Number of DB queries
- `db_query_time_ms` - Total DB time
- `cache_hits` / `cache_misses` - Cache performance
- `external_calls` - External API calls

**⚠️ CRITICAL: Log Metrics, Don't Poll or Monitor**

- **✅ DO**: Log performance metrics as part of wide events using Pino
- **✅ DO**: Log slow operations immediately (>100ms logged, >500ms warnings)
- **✅ DO**: Include cache hit/miss counts in request logs
- **❌ DON'T**: Create admin endpoints that poll for metrics
- **❌ DON'T**: Use `setInterval` or background timers to collect metrics
- **❌ DON'T**: Create monitoring dashboards that poll endpoints
- **❌ DON'T**: Store metrics in memory for later retrieval

**Pattern**: Log everything as it happens. Metrics are derived from logs, not collected separately.

```typescript
// ✅ CORRECT: Log performance metrics as part of wide event
const event = {
  operation: 'getUserWorkspaces',
  duration_ms: 234,
  cache_hits: 2,
  cache_misses: 1,
  db_queries: 3,
  db_query_time_ms: 180,
  // ... other context
}

if (event.duration_ms > 100) {
  logger.info(event, '[SLOW] getUserWorkspaces took 234ms')
} else {
  logger.info(event, 'getUserWorkspaces completed')
}

// ❌ WRONG: Don't store metrics in memory for polling
// const metrics = { hits: 0, misses: 0 }
// metrics.hits++ // DON'T DO THIS
// setInterval(() => logMetrics(metrics), 5000) // DON'T DO THIS
```

### 6. Never Log PII

Never log:
- Email addresses
- Passwords
- Credit card numbers
- SSNs
- Other sensitive data

Hash/anonymize IPs and other potentially sensitive identifiers.

### 7. Use Appropriate Log Levels

- `error` - Errors requiring immediate attention
- `warn` - Warnings and slow operations
- `info` - Business events and successful operations (wide events)
- `debug` - Development only, not in production

**Note**: All logging uses Pino on the server side. Client-side code sends logs to server endpoints that use Pino. Never use browser `console.*` methods.

### 8. Accumulate Context, Don't Scatter Logs

❌ **Bad**: Multiple log statements
```typescript
logger.info('Starting operation')
logger.info('User authenticated')
logger.info('Database queried')
logger.info('Operation complete')
```

✅ **Good**: One wide event
```typescript
const event = { /* accumulated context */ }
logger.info(event, 'Request completed')
```

### 9. Use Child Loggers for Base Context

Create child loggers with base context to avoid repetition:

```typescript
const requestLogger = logger.child({
  request_id: requestId,
  user_id: userId,
  workspace_id: workspaceId
})

// All subsequent logs include base context (Pino signature: event first, message second)
requestLogger.info({ operation: 'create_task' }, 'Task created')
```

### 10. Make Events Queryable

Design events to answer questions:
- "Why did user X's checkout fail?" → Include payment method, error details
- "Are premium users experiencing more errors?" → Include subscription tier, error type
- "Which deployment caused the latency regression?" → Include deployment_id
- "What's the error rate for the new checkout feature?" → Include feature_flags

---

## Anti-Patterns to Avoid

### 0. Polling, Monitoring Endpoints, or Background Metric Collection

**❌ WRONG**: Creating admin endpoints or background processes to collect metrics

```typescript
// ❌ DON'T: Store metrics in memory for polling
const cacheMetrics = { hits: 0, misses: 0 }
cache.on('hit', () => cacheMetrics.hits++)
setInterval(() => {
  logger.info(cacheMetrics, 'Cache statistics') // Periodic polling
}, 5 * 60 * 1000)

// ❌ DON'T: Create admin endpoints that return metrics
export async function GET() {
  return { metrics: getStoredMetrics() } // Polling endpoint
}
```

**✅ CORRECT**: Log metrics as part of events

```typescript
// ✅ DO: Log cache performance as part of request events
const event = {
  operation: 'getWorkspaceDetails',
  cache_hits: 1,
  cache_misses: 0,
  duration_ms: 45,
  // ... other context
}
logger.info(event, 'getWorkspaceDetails completed')

// ✅ DO: Log slow operations immediately
if (duration > 100) {
  logger.info({ ...event, duration_ms: duration }, '[SLOW] Operation took 234ms')
}
```

**Key Principle**: Log everything as it happens. Metrics are derived from logs by querying your log aggregation system. No polling, no monitoring endpoints, no background metric collection.

### 1. String Interpolation

❌ **Bad**:
```typescript
logger.info(`User ${userId} updated project ${projectId}`)
```

✅ **Good**:
```typescript
logger.info({
  user_id: userId,
  project_id: projectId
}, 'User updated project')
```

### 2. Scattered Logs

❌ **Bad**: Multiple log statements throughout code
```typescript
logger.info('Starting operation')
logger.info('User authenticated')
logger.info('Database queried')
```

✅ **Good**: One wide event with accumulated context

### 3. Missing High-Cardinality Fields

❌ **Bad**: Log without user_id or request_id
```typescript
logger.info('Operation completed', { status: 'success' })
```

✅ **Good**: Always include high-cardinality identifiers
```typescript
logger.info({
  request_id: requestId,
  user_id: userId,
  status: 'success'
}, 'Operation completed')
```

### 4. Low Dimensionality

❌ **Bad**: Only 5 fields
```typescript
logger.info('Request completed', {
  method: 'POST',
  path: '/api/checkout',
  status: 200,
  duration: 45
})
```

✅ **Good**: High dimensionality (20-100+ fields) with complete context

### 5. Logging PII

❌ **Bad**:
```typescript
logger.info('User logged in', {
  email: user.email,
  password: user.password
})
```

✅ **Good**:
```typescript
logger.info({
  user_id: user.id,
  login_method: 'oauth'
}, 'User logged in')
```

### 6. Not Logging Query Parameters

❌ **Bad**: Missing query_params
```typescript
logger.info('Request received', {
  method: 'GET',
  path: '/api/users'
  // Missing query_params!
})
```

✅ **Good**: Always include query_params (with allowlist filtering - see PII section)
```typescript
logger.info({
  method: 'GET',
  path: '/api/users',
  query_params: filterQueryParams(req.query) // See PII redaction section
}, 'Request received')
```

### 7. Random Sampling (Not Tail Sampling)

❌ **Bad**: Sample before request completes
```typescript
if (Math.random() < 0.05) {
  // Log request
}
```

✅ **Good**: Tail sampling after request completes
```typescript
// After request completes
if (shouldSample(event)) {
  logger.info(event, 'Request completed')
}
```

### 9. Thinking Structured Logging = Wide Events

❌ **Bad**: Structured JSON but still useless
```typescript
logger.info({ event: 'payment_failed' }) // Only 1 field!
```

✅ **Good**: Wide event with high dimensionality (typically 20-100+ fields)

### 10. Not Including Business Context

❌ **Bad**: Only technical details
```typescript
logger.info('Request completed', {
  method: 'POST',
  status: 500,
  duration: 45
})
```

✅ **Good**: Include business context
```typescript
logger.info({
  method: 'POST',
  status: 500,
  duration: 45,
  user: { id: 'user_456', subscription_tier: 'premium', account_age_days: 847 },
  cart: { total_cents: 15999 },
  error: { type: 'PaymentError', code: 'card_declined' }
}, 'Request completed')
```

### 11. Not Including Feature Flags

❌ **Bad**: Missing feature flag context
```typescript
logger.info('Request completed', { /* no feature_flags */ })
```

✅ **Good**: Include feature flags
```typescript
logger.info({
  feature_flags: {
    new_checkout_flow: true,
    express_payment: false
  }
}, 'Request completed')
```

---

## Querying & Analytics

With wide events, you're not searching text anymore. You're querying structured data.

### Example Queries

**Find all errors for a user**:
```sql
-- If your system supports nested fields:
SELECT * FROM logs
WHERE user.id = 'user_456'
  AND error IS NOT NULL
ORDER BY timestamp DESC

-- Or if using top-level user_id convenience field:
SELECT * FROM logs
WHERE user_id = 'user_456'
  AND error IS NOT NULL
ORDER BY timestamp DESC
```

**Error rate by subscription tier**:
```sql
SELECT 
  user.subscription_tier,
  COUNT(*) as total_requests,
  SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) as errors,
  (SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as error_rate
FROM logs
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user.subscription_tier
```

**Slowest requests (p99 latency)**:
```sql
SELECT 
  path,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY duration_ms) as p99_latency
FROM logs
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY path
ORDER BY p99_latency DESC
```

**Errors for premium users**:
```sql
SELECT * FROM logs
WHERE user.subscription_tier = 'premium'
  AND error IS NOT NULL
  AND timestamp > NOW() - INTERVAL '1 hour'
```

**Feature flag impact on errors**:
```sql
SELECT 
  feature_flags.new_checkout_flow,
  COUNT(*) as total_requests,
  SUM(CASE WHEN error IS NOT NULL THEN 1 ELSE 0 END) as errors
FROM logs
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY feature_flags.new_checkout_flow
```

**Payment failures by decline code**:
```sql
SELECT 
  error.stripe_decline_code,
  COUNT(*) as failure_count
FROM logs
WHERE error.type = 'PaymentError'
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY error.stripe_decline_code
ORDER BY failure_count DESC
```

**Find user's recent requests**:
```sql
-- If your system supports nested fields:
SELECT * FROM logs
WHERE user.id = 'user_456'
ORDER BY timestamp DESC
LIMIT 100

-- Or if using top-level user_id convenience field:
SELECT * FROM logs
WHERE user_id = 'user_456'
ORDER BY timestamp DESC
LIMIT 100
```

**Which deployment caused the latency regression?**:
```sql
SELECT 
  deployment_id,
  AVG(duration_ms) as avg_latency,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY duration_ms) as p99_latency
FROM logs
WHERE timestamp > NOW() - INTERVAL '1 day'
GROUP BY deployment_id
ORDER BY p99_latency DESC
```

This is the superpower of wide events combined with high-cardinality, high-dimensionality data. You're not searching logs anymore. You're running analytics on your production traffic.

---

## Performance & Cost

### Performance Impact

- **Overhead**: <1% latency increase
- **Memory**: Minimal overhead
- **Throughput**: Handles 10,000+ req/sec easily

### Cost Optimization

1. **Use tail sampling**: Only log 5% of successful requests
2. **Keep all errors**: Never sample errors
3. **Monitor log volume**: Set up alerts for unusual spikes
4. **Use appropriate log levels**: Don't log debug info in production
5. **Avoid logging large payloads**: Log metadata, not full data

### Modern Logging Systems

Modern columnar databases and logging platforms are specifically designed for high-cardinality, high-dimensionality data. The tooling has caught up. Your practices should too.

**The irony**: Most legacy logging systems charge by volume and choke on high-cardinality fields. This is backwards. High cardinality is exactly what you need for debugging.

---

## Monitoring & Metrics: Log Only, No Polling

### ⚠️ CRITICAL: No Polling, No Monitoring Endpoints

**Core Principle**: Log everything as it happens. Metrics are derived from logs by querying your log aggregation system (e.g., Axiom, Datadog, CloudWatch). 

**What to DO**:
- ✅ Log performance metrics as part of wide events
- ✅ Log slow operations immediately (>100ms logged, >500ms warnings)
- ✅ Include cache hit/miss counts in request logs
- ✅ Log errors immediately with full context
- ✅ Query logs for metrics when needed

**What NOT to DO**:
- ❌ Create admin endpoints that poll for metrics (`/api/admin/metrics`, `/api/admin/cache-stats`)
- ❌ Use `setInterval` or background timers to collect metrics
- ❌ Store metrics in memory for later retrieval
- ❌ Create monitoring dashboards that poll endpoints
- ❌ Use background processes to aggregate metrics

### Example: Correct Logging Pattern

```typescript
// ✅ CORRECT: Log performance metrics as part of wide event
const event = {
  operation: 'getUserWorkspaces',
  duration_ms: 234,
  cache_hits: 2,
  cache_misses: 1,
  db_queries: 3,
  db_query_time_ms: 180,
  user_id: userId,
  request_id: requestId,
  // ... other context
}

// Log immediately - no storing, no polling
if (event.duration_ms > 100) {
  logger.info(event, '[SLOW] getUserWorkspaces took 234ms')
} else {
  logger.info(event, 'getUserWorkspaces completed')
}

// Metrics are derived from logs by querying:
// - Cache hit rate: COUNT WHERE cache_hits > 0 / COUNT(*)
// - Average duration: AVG(duration_ms) WHERE operation = 'getUserWorkspaces'
// - Slow operations: WHERE duration_ms > 500
```

### Example: Anti-Pattern (Don't Do This)

```typescript
// ❌ WRONG: Storing metrics in memory for polling
const cacheMetrics = { hits: 0, misses: 0 }
cache.on('hit', () => cacheMetrics.hits++)
cache.on('miss', () => cacheMetrics.misses++)

setInterval(() => {
  logger.info(cacheMetrics, 'Cache statistics') // Periodic polling
}, 5 * 60 * 1000)

// ❌ WRONG: Admin endpoint that returns metrics
export async function GET() {
  return { metrics: getStoredMetrics() } // Polling endpoint
}
```

### Getting Metrics from Logs

Instead of polling endpoints, query your log aggregation system:

```sql
-- Cache hit rate (from logs)
SELECT 
  COUNT(*) FILTER (WHERE cache_hits > 0) * 100.0 / COUNT(*) as hit_rate
FROM logs
WHERE operation = 'getWorkspaceDetails'
  AND timestamp > NOW() - INTERVAL '1 hour'

-- Average duration (from logs)
SELECT AVG(duration_ms) as avg_duration
FROM logs
WHERE operation = 'getUserWorkspaces'
  AND timestamp > NOW() - INTERVAL '1 hour'

-- Slow operations (from logs)
SELECT operation, duration_ms, user_id
FROM logs
WHERE duration_ms > 500
  AND timestamp > NOW() - INTERVAL '1 hour'
ORDER BY duration_ms DESC
```

**Remember**: Logs are your source of truth. Query logs for metrics. Don't poll or monitor.

---

## Summary

### The Payoff

When you implement wide events properly, debugging transforms from archaeology to analytics.

**Instead of**: "The user said checkout failed. Let me grep through 50 services and hope I find something."

**You get**: "Show me all checkout failures for premium users in the last hour where the new checkout flow was enabled, grouped by error code."

One query. Sub-second results. Root cause identified.

Your logs stop lying to you. They start telling the truth. The whole truth.

### Key Takeaways

**⚠️ Production Priority: Error-First Logging**
- **Errors are PRIMARY** - Always log 100% of errors (status >= 500, exceptions, failures)
- **Success requests MUST be sampled** - Use tail sampling (default 5%) for success requests
- **Never log success requests without sampling** in production (except VIP users)

1. **Server-side Pino only** - No browser console logs, all client logs sent to server
2. **Pino signature** - Always use `logger.info(event, 'message')` - event first, message second
3. **Error-first logging** - Always log errors, sample successes (mandatory in production)
4. **Tail sampling is mandatory** - Never log success requests without `shouldSample()` check
5. **One log line per operation** - HTTP requests, background jobs, queue workers, cron jobs
6. **High dimensionality** - Include as many fields as needed (typically 20-100+) for complex queries
7. **High-cardinality identifiers** - `user_id`, `request_id`, `trace_id` (always required)
8. **Schema versioning** - Include `schema_version` field for evolution
9. **Snake_case naming** - All field names use `snake_case`
10. **Business context** - Subscription tier, cart value, feature flags
11. **Accumulate context** - Build event throughout operation lifecycle
12. **Emit once** - At the end of the operation
13. **PII redaction** - Never log PII, use allowlists for query params/headers
14. **Size limits** - Max 100 KB per event, truncate don't drop
15. **Error shape** - Standardized error object with conditional stack traces
16. **Client endpoint hardening** - Rate limiting, auth, CSRF, payload limits, sampling
17. **Structured JSON** - Queryable, not searchable

### Remember

**Log what happened to the request, not what your code is doing.**

One comprehensive event per request with all context accumulated throughout the lifecycle. This is the philosophy of wide events.

**⚠️ Production Focus: Error-First Logging**

- **Errors are your PRIMARY concern** - Always log 100% of errors
- **Success requests MUST be sampled** - Use tail sampling (default 5%)
- **Never log success requests without sampling** in production
- **Wide events are valuable**, but only if properly sampled

**In production, you want to see ALL errors but only a SAMPLE of successes.**

---

## References

- [Boris Tane: "Logging Sucks"](./logging.md) - The definitive article on wide events
- [Logging Implementation Guide](./logging-example.md) - Implementation details
- [OpenTelemetry](https://opentelemetry.io) - Observability framework (just plumbing - you decide what to log)

---

**Remember**: Structured logging is table stakes. Wide events are the philosophy. One comprehensive event per request with all context attached.
