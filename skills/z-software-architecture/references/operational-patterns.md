# Operational Patterns

Practical architecture patterns that almost every production system needs. Reference this for common implementation decisions that sit between "architecture" and "code."

---

## Resilience Patterns

### Timeout Budgets

Every external call needs a timeout. Without one, a single slow dependency freezes the entire request.

| Dependency Type | Timeout | Rationale |
|---|---|---|
| Database | 5s | Longer means something is wrong |
| Payment API (Stripe/Toss) | 10-15s | Processing can be slow; users will wait for payments |
| LLM API | 60-120s | Long generations; use streaming to mask wait |
| Email (Resend) | 5s | Fire-and-forget; queue if slow |
| Object Storage (R2) | 10s | Large file operations |

**Rule**: Total request timeout = sum of sequential dependency timeouts + processing. If the chain exceeds your SLO, make some calls async.

### Retry Policy

Only retry **idempotent** operations.

| Strategy | When |
|---|---|
| **No retry** | Non-idempotent writes without idempotency keys |
| **Retry with backoff** | Reads, idempotent writes |
| **Retry with idempotency key** | Critical writes (Stripe `Idempotency-Key`, etc.) |

Formula: `min(base * 2^attempt + jitter, max_delay)`. Base=100ms, max=5s, max 3 attempts.

### Graceful Degradation

Decide at design time, not at 3 AM:

| Dependency | Strategy |
|---|---|
| LLM API | "AI features temporarily unavailable" + cached responses if possible |
| Payments | "Payments temporarily unavailable", user continues browsing |
| Email | Queue for later, never block user action |
| Analytics (PostHog) | Silent fail — never block for analytics |
| Database | System offline — no degradation for primary data store |

---

## File Upload Architecture

### Presigned URL Pattern

Server-proxied uploads waste bandwidth and compute. Use presigned URLs for direct client-to-storage uploads.

```
1. Client → POST /api/uploads (file metadata)     → Server generates presigned URL
2. Client → PUT presigned URL (file bytes)         → Direct to R2/S3
3. Client → POST /api/uploads/{fileId}/complete    → Server validates & processes
```

### Key Decisions

- **Max file size**: Enforce in presigned URL policy AND client-side
- **Allowed types**: Validate MIME type server-side (client Content-Type is spoofable)
- **Processing**: Thumbnails, text extraction — always async via background job
- **Cleanup**: Orphaned uploads (step 2 done, step 3 never called) need scheduled cleanup

**Our stack**: R2 presigned URLs via S3-compatible API. Zero egress fees for serving uploaded content.

---

## Background Jobs

### Decision Framework

```
Triggered by user action?
├── YES → User can wait < 2s? → Do it inline
│         User can't wait?    → Async job
└── NO  → Scheduled job

Async (CF bundle):
├── Simple fire-and-forget      → Queues → Worker handler
├── Fan-out (one event, many)   → Queues (fan-out) or Pub/Sub
└── Complex multi-step          → Workflows (auto-retry, checkpoint)

Async (Container / Cloud Run):
├── Simple fire-and-forget      → Cloud Tasks (HTTP callback)
├── Fan-out (one event, many)   → Pub/Sub
└── Complex multi-step          → Pub/Sub + Cloud Tasks

Scheduled:
├── CF bundle                    → Cron Triggers (simple) or Workflows (complex)
├── Cloud Run                    → Cloud Scheduler → HTTP trigger
└── Database-level               → pg_cron on Neon
```

### Common Jobs

| Job | Trigger | CF Bundle | Container (Cloud Run) |
|---|---|---|---|
| Send email | User action | Queues → Worker handler | Cloud Tasks → POST /jobs/send-email |
| Process upload | Upload complete | Queues → Worker handler | Cloud Tasks → POST /jobs/process-upload |
| Sync Stripe state | Stripe webhook | Worker handler | Pub/Sub handler |
| Daily metrics | Cron | Cron Trigger → Worker | Cloud Scheduler → POST /jobs/daily-metrics |
| Cleanup orphaned files | Cron | Cron Trigger → Worker | Cloud Scheduler → POST /jobs/cleanup |

**Key insight**: At solo scale, your Workers (or Cloud Run service) handle both user requests AND job callbacks — same service, different routes, different auth. No separate worker service needed.

---

## Durable Execution

When async work involves multiple steps, any of which can fail, simple queues aren't enough. Durable execution treats each step as a **checkpoint** — if the process crashes, it resumes from the last checkpoint, not from scratch.

### When to Use

```
Simple fire-and-forget (send email, resize image)  → Queue is enough
Multi-step with side effects (payment → provision → notify)  → Durable execution
Long-running with waits (human approval, external callback)  → Durable execution
```

### Core Primitives

| Primitive | What It Does |
|---|---|
| **step.run()** | Execute a function with automatic retry on failure |
| **step.sleep()** | Pause workflow for a duration (minutes to days) without consuming compute |
| **step.waitForEvent()** | Pause until an external signal arrives (webhook, user action) |
| **checkpoint** | State persisted after each step — crash-safe resume |

### Platform Options

| Platform | Model | Our Stack Fit |
|---|---|---|
| **CF Workflows** | Worker-native, auto-retry, sleep/checkpoint | CF bundle default |
| **Temporal** | Event-history replay, exactly-once, polyglot | Container / Cloud Run |
| **Inngest** | Event-driven harness, step functions, any runtime | Platform-agnostic |

**Architecture implication**: Durable execution replaces ad-hoc retry logic, manual state machines, and "check if already processed" patterns. If you find yourself writing status columns (`pending → processing → done → failed`) with polling loops, you likely need durable execution instead.

---

## Payments & Webhooks

### Core Pattern

```
User → Your API → Stripe/Toss API (create session)
                         ↓
Provider → Webhook → Your API → Update DB
```

**The webhook is the source of truth** for payment state. Don't rely on API responses for state.

### Webhook Reliability

| Concern | Solution |
|---|---|
| Idempotency | Store processed `event.id`. Skip duplicates. |
| Ordering | Use `event.created` timestamp, not arrival order |
| Verification | Always verify webhook signature |
| Slow processing | Return 200 immediately, process async if heavy |
| Missed events | Reconcile DB against provider API on startup / periodically |

### Subscription State

```
active → past_due → canceled
  │         │
  │         └─ payment retry succeeds → active
  └─ user cancels → canceling → canceled (at period end)
```

Map provider statuses to your entitlement model. Gate features via PostHog feature flags by plan tier.

### Webhook Fan-out + Durable Wait

When a single webhook triggers multiple downstream actions (provision, notify, sync analytics), combine queue fan-out with durable execution's `waitForEvent`:

```
Provider → Webhook endpoint → return 200 immediately
                ↓
            Queue fan-out → Handler A (provision account)
                          → Handler B (send welcome email)
                          → Handler C (sync to analytics)

For multi-step flows:
Workflow.step("charge")    → Stripe API
Workflow.waitForEvent("stripe.charge.succeeded", timeout: 10m)
Workflow.step("provision") → Create user resources
Workflow.step("notify")    → Send confirmation
```

**Key decisions**:
- **Immediate 200**: Never do heavy processing in the webhook handler. Return 200, enqueue, process async.
- **Fan-out via queue**: Each downstream action is an independent consumer. One failure doesn't block others.
- **waitForEvent for async providers**: Virtual accounts (가상계좌), bank transfers, and manual approval flows — the workflow sleeps until the confirmation webhook arrives.

### Toss Payments (Korea-specific)

- Two-step: authorize → confirm (다른 결제 플로우)
- Virtual account (가상계좌): async — user transfers later, webhook confirms via `waitForEvent`
- Same webhook reliability patterns apply

---

## Local Development

| Component | Production | Local |
|---|---|---|
| Database | Neon (production branch) | Neon dev branch (`neon branches create`) |
| Object Storage | R2 | R2 same bucket `/dev` prefix, or MinIO for offline |
| Email | Resend | Resend test mode or mailpit (local SMTP) |
| Payments | Stripe / Toss | Test mode + CLI webhook forwarding |

### Essentials

- **Neon branching**: Instant dev branch from production schema. Same engine, free. No Docker Postgres needed.
- **`.env.local`** for local overrides. Never commit `.env`. Maintain `.env.example` as template.
- **Stripe CLI**: `stripe listen --forward-to localhost:PORT/webhooks` for local webhook testing.
- **Hot reload**: Vite dev server (frontend), `wrangler dev` (Workers). Optimize for sub-second feedback.
- **Wrangler dev**: `wrangler dev` for Workers local development with bindings (KV, R2, D1, DO). Use `--remote` flag to test against real services.
