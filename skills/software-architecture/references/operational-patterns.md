# Operational Patterns

Practical architecture patterns that almost every production system needs. Reference this for common implementation decisions that sit between "architecture" and "code."

---

## Pagination Strategy

**Default to cursor-based pagination.** Consistent performance and correct behavior for mutable data. Use offset only for admin panels and small/static datasets.

**Cursor** (default) — `WHERE (created_at, id) > (:cursor) ORDER BY created_at, id LIMIT :size`.
Consistent performance regardless of dataset size. Ideal for feeds, timelines, infinite scroll, and large datasets. Always use a **composite cursor** `(sort_field, id)`. Cursor is an opaque base64-encoded string in the API; decode in the adapter only.

**Offset** — `LIMIT / OFFSET` + `COUNT(*)`.
Provides `total` count for page number UIs. Suited for admin dashboards, back-office tools, and small/static datasets. Downside: deeper pages get slower, and row mutations between requests cause duplicates or skips.

Document your pagination choice per endpoint in the design doc.

---

## Resilience Patterns

### Timeout Budgets

Every external call needs a timeout. Without one, a single slow dependency freezes the entire request.

| Dependency Type | Typical Timeout | Rationale |
|---|---|---|
| Database | 5s | Longer means something is wrong |
| Payment API | 10-15s | Processing can be slow; users will wait for payments |
| LLM API | 60-120s | Long generations; use streaming to mask wait |
| Email / notification | 5s | Fire-and-forget; queue if slow |
| Object storage | 10s | Large file operations |

**Rule**: Total request timeout = sum of sequential dependency timeouts + processing. If the chain exceeds your SLO, make some calls async.

### Retry Policy

Only retry **idempotent** operations.

| Strategy | When |
|---|---|
| **No retry** | Non-idempotent writes without idempotency keys |
| **Retry with backoff** | Reads, idempotent writes |
| **Retry with idempotency key** | Critical writes (payment APIs, etc.) |

Formula: `min(base * 2^attempt + jitter, max_delay)`. Base=100ms, max=5s, max 3 attempts.

### Graceful Degradation

Decide at design time, not at 3 AM:

| Dependency | Strategy |
|---|---|
| LLM API | "AI features temporarily unavailable" + cached responses if possible |
| Payments | "Payments temporarily unavailable", user continues browsing |
| Email | Queue for later, never block user action |
| Analytics | Silent fail — never block for analytics |
| Database | System offline — no degradation for primary data store |

---

## File Upload Architecture

### Presigned URL Pattern

Server-proxied uploads waste bandwidth and compute. Use presigned URLs for direct client-to-storage uploads.

```
1. Client -> POST /api/uploads (file metadata)     -> Server generates presigned URL
2. Client -> PUT presigned URL (file bytes)         -> Direct to object storage
3. Client -> POST /api/uploads/{fileId}/complete    -> Server validates & processes
```

### Key Decisions

- **Max file size**: Enforce in presigned URL policy AND client-side
- **Allowed types**: Validate MIME type server-side (client Content-Type is spoofable)
- **Processing**: Thumbnails, text extraction — always async via background job
- **Cleanup**: Orphaned uploads (step 2 done, step 3 never called) need scheduled cleanup

---

## Background Jobs

### Decision Framework

```
Triggered by user action?
+-- YES -> User can wait < 2s? -> Do it inline
|         User can't wait?    -> Async job
+-- NO  -> Scheduled job

Async job complexity:
+-- Simple fire-and-forget      -> Message queue -> worker handler
+-- Fan-out (one event, many)   -> Pub/sub or fan-out queue
+-- Complex multi-step          -> Durable execution (see below)

Scheduled:
+-- Simple recurring            -> Cron scheduler -> HTTP trigger / function
+-- Database-level              -> Database-native scheduling (e.g., pg_cron)
```

---

## Durable Execution

When async work involves multiple steps, any of which can fail, simple queues aren't enough. Durable execution treats each step as a **checkpoint** — if the process crashes, it resumes from the last checkpoint, not from scratch.

### When to Use

```
Simple fire-and-forget (send email, resize image)  -> Queue is enough
Multi-step with side effects (payment -> provision -> notify)  -> Durable execution
Long-running with waits (human approval, external callback)  -> Durable execution
```

### Core Primitives

| Primitive | What It Does |
|---|---|
| **step.run()** | Execute a function with automatic retry on failure |
| **step.sleep()** | Pause workflow for a duration (minutes to days) without consuming compute |
| **step.waitForEvent()** | Pause until an external signal arrives (webhook, user action) |
| **checkpoint** | State persisted after each step — crash-safe resume |

**Architecture implication**: Durable execution replaces ad-hoc retry logic, manual state machines, and "check if already processed" patterns. If you find yourself writing status columns (`pending -> processing -> done -> failed`) with polling loops, you likely need durable execution instead.

---

## Webhook Reliability

When integrating with external services that send webhooks (payment providers, SaaS platforms, etc.):

| Concern | Solution |
|---|---|
| Idempotency | Store processed `event.id`. Skip duplicates. |
| Ordering | Use `event.created` timestamp, not arrival order |
| Verification | Always verify webhook signature |
| Slow processing | Return 200 immediately, process async if heavy |
| Missed events | Reconcile DB against provider API on startup / periodically |

### Webhook Fan-out + Durable Wait

When a single webhook triggers multiple downstream actions:

```
Provider -> Webhook endpoint -> return 200 immediately
                |
            Queue fan-out -> Handler A (provision account)
                          -> Handler B (send welcome email)
                          -> Handler C (sync to analytics)
```

**Key decisions**:
- **Immediate 200**: Never do heavy processing in the webhook handler. Return 200, enqueue, process async.
- **Fan-out via queue**: Each downstream action is an independent consumer. One failure doesn't block others.
- **waitForEvent for async flows**: For flows where confirmation arrives later (bank transfers, manual approvals), the workflow sleeps until the confirmation webhook arrives.

---

## Caching Architecture

### Caching Patterns

| Pattern | How It Works | When to Use |
|---|---|---|
| **Cache-Aside (Lazy Loading)** | App checks cache -> miss -> read from DB -> write to cache -> return | Default. Read-heavy workloads. App controls cache population |
| **Write-Through** | App writes to cache AND DB on every write. Reads always hit cache | When cache consistency matters more than write latency |
| **Write-Behind (Write-Back)** | App writes to cache, cache asynchronously syncs to DB | High write throughput. Risk: data loss if cache crashes before sync |
| **Read-Through** | Cache itself loads from DB on miss (cache acts as proxy) | When you want the cache layer to own data loading logic |
| **Refresh-Ahead** | Cache proactively refreshes entries before TTL expires | Predictable access patterns, latency-sensitive reads |

**Default**: Cache-aside. Simple, explicit, and you control exactly what gets cached.

### Cache Invalidation

| Strategy | How It Works | Trade-offs |
|---|---|---|
| **TTL-based** | Set expiry time, accept staleness within window | Simple. Good enough when seconds-old data is acceptable |
| **Event-driven** | Invalidate on write events (DB trigger, app event, webhook) | Consistent but requires event infrastructure |
| **Versioned keys** | Include version/hash in cache key, new version = new key | No explicit invalidation needed. Old entries expire naturally via TTL |

### Stampede Prevention

When a popular cache entry expires, many concurrent requests hit the DB simultaneously (thundering herd). Solutions:

- **Lock-based recomputation**: First request acquires a lock, recomputes, others wait. Use distributed lock for multi-instance
- **Stale-while-revalidate**: Serve stale data while one request refreshes in the background. Best UX — users never see a cache miss
- **Probabilistic early expiration**: Each request has a small random chance of refreshing before TTL. Spreads recomputation over time

**What NOT to cache**: Auth tokens/sessions in eventually-consistent stores (security risk), data that changes per-request, anything where stale data causes financial or safety issues.

---

## Rate Limiting Architecture

### Algorithm Selection

| Algorithm | How It Works | Trade-offs |
|---|---|---|
| **Fixed Window** | Count requests per time window (e.g., 100/min). Reset at boundary | Simple. Burst at window edges (up to 2x limit across boundaries) |
| **Sliding Window Log** | Track timestamp of each request, count within sliding window | Precise. Memory-heavy at high volume |
| **Sliding Window Counter** | Weighted blend of current and previous window counts | Good precision, low memory. Best general-purpose choice |
| **Token Bucket** | Bucket fills at steady rate, each request consumes a token | Allows controlled bursts. Natural rate smoothing |
| **Leaky Bucket** | Requests queue and process at fixed rate | Strict enforcement, no bursts. Good for downstream protection |

**Default**: Sliding window counter — good balance of precision and resource usage. Use token bucket when you want to allow controlled bursts.

### Rate Limit Dimensions

| Dimension | When to Use | Evasion Risk |
|---|---|---|
| **IP address** | Unauthenticated endpoints, public APIs | High — proxies, VPNs, shared IPs |
| **User/API key** | Authenticated endpoints | Low — tied to account |
| **Tenant/org** | Multi-tenant SaaS | Low — tied to billing entity |
| **Endpoint** | Expensive operations (search, AI, exports) | Combine with user dimension |
| **Composite** (user + endpoint) | Granular control per operation | Most flexible, most complex |

**Layered approach**: Apply multiple limits simultaneously — global (per IP), per user, and per endpoint. The tightest limit wins.

### Response Convention

Return rate limit state in headers so clients can self-regulate:

```
RateLimit-Limit: 100
RateLimit-Remaining: 42
RateLimit-Reset: 1678886400
Retry-After: 30          (only on 429 responses)
```

Return `429 Too Many Requests` with a clear error message and `Retry-After` header.
