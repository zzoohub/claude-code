# Cloudflare Platform Reference

Detailed tech stack for the Cloudflare bundle. Priority: ① = default, ② = situational alternative, ③ = last resort. Origin: CF = Cloudflare native, External = third-party.

Read this when designing a system on the Cloudflare bundle. For bundle selection logic, see `stack-templates.md`.

---

## Language / Framework

| Role | Pri | Service | Notes |
|---|---|---|---|
| Language | ① | TypeScript | Default for all web services. Type consistency across Workers, Hono, Drizzle |
| Language | ② | Rust | CPU-intensive or memory-safety-critical. workers-rs + Axum for Workers deploy |
| Client (fullstack, default) | ① | TanStack Start + React (External) | Full-stack React, type-safe routing and server functions. Workers/Node.js deploy |
| Client (fullstack, perf) | ② | TanStack Start + SolidJS (External) | Fine-grained reactivity, minimal bundles, same TanStack Start primitives |
| Server (Workers) | ① | Hono TS (CF) | <4kB, middleware chaining, RPC, Workers-first |
| Server (Workers) | ② | workers-rs + Axum (CF) | CPU-intensive API/parsing. Memory safety required |
| Server (Container) | ① | Rust/Axum | Minimal cold start. Default for CF Containers |
| Server (Container) | ③ | FastAPI Python | Escape hatch: only when Python-only ML libraries (torch, transformers) required |

---

## Compute

| Role | Pri | Service | Notes |
|---|---|---|---|
| Edge compute / API | ① | Workers JS/TS · Rust (CF) | Stateless isolate, 330+ PoP, ~0ms cold start |
| Stateful long-running | ① | Durable Objects (CF) | Global singleton, WebSocket hub, strong consistency, built-in KV storage |
| Async workflows | ① | Workflows + Queues (CF) | Auto-retry, checkpoint, sleep. Temporal-like model. DLQ, schedule triggers |
| Agent (Workers) | ① | Agents SDK (CF) | DO-based. State, memory, MCP, scheduling, real-time WebSocket, voice, email. Zero idle cost via hibernation |
| Agent (durable multi-step) | ① | Agents SDK + Workflows (CF) | Per-step checkpoint, auto-retry, sleep, waitForEvent. Long-running pipelines within Workers |
| Agent (complex graph) | ② | LangGraph.js on Workers (CF+External) | Declarative graph orchestration. Only when imperative Workflows become unmaintainable. Needs custom DO-backed checkpointer |
| Agent (Python ML) | ③ | CF Containers + LangGraph Python | Escape hatch for torch/transformers |
| Container (long-running) | ① | CF Containers + Rust/Axum (CF) | 16vCPU/64GB RAM, sleep/wake cycle. Minimal cold start |
| Container (long-running) | ③ | CF Containers + Python/FastAPI (CF) | Escape hatch: ML library dependency only |
| Container (long-running) | ② | Cloud Run (External) | GPU, GCP services, existing GCP infra |

### Compute Decision Flow

```
Request type?
├── Stateless API, <30s           → Workers (Hono or workers-rs)
├── Stateful, WebSocket, coord    → Durable Objects
├── Async, retry, multi-step      → Workflows + Queues
├── Agent, stateful/real-time     → Agents SDK (DO-based)
├── Agent, durable pipeline       → Agents SDK + Workflows
├── Agent, graph orchestration    → LangGraph.js on Workers
└── Container, CPU/memory heavy   → CF Containers or Cloud Run (Rust or Python)
    ├── CF ecosystem, no GPU       → CF Containers
    └── GPU, GCP services needed   → Cloud Run
```

---

## Database / Storage

| Role | Pri | Service | Notes |
|---|---|---|---|
| DB (Postgres) | ① | Neon + Hyperdrive (External+CF) | Scale-to-zero serverless Postgres. Hyperdrive handles edge connection pooling + query caching |
| DB (Postgres) | ② | Cloud SQL (External) | GCP legacy lock-in or strict latency SLA only |
| DB (SQLite) | ① | D1 (CF) | Small-medium OLTP, 10GB/DB limit. Single-vendor simplicity |
| Cache (read-heavy) | ① | KV (CF) | Eventually consistent (60s propagation), global replicated. Config, static data, feature flag TTL |
| Cache (realtime) | ① | Upstash Redis (External) | Strong consistent. Session, rate limit, counters. Serverless HTTP |
| Queue (internal) | ① | CF Queues (CF) | At-least-once, DLQ, schedule trigger. Worker-to-Worker async |
| Streaming (external) | ① | Upstash Kafka (External) | High-throughput multi-consumer. External system / data pipeline integration |
| Object storage | ① | R2 (CF) | Egress-free, CDN direct serve. R2 Data Catalog (Iceberg) for analytics lake |
| Analytics / DW | ① | Pipelines + R2 SQL (CF) | Event collect → Parquet → petabyte SQL query. Iceberg table format |
| Image optimization | ① | CF Images (CF) | Resize, WebP/AVIF auto-convert, URL param API. Direct R2 origin integration |
| Video streaming | ① | CF Stream (CF) | Adaptive bitrate (HLS/DASH), global CDN serve |
| Video transform | ① | Media Transformations (CF) | Short video resize, thumbnail, GIF convert. URL param API |
| Vector DB | ① | Vectorize (CF) | Workers AI / AutoRAG native integration. RAG, agent memory, semantic search |

---

## AI

| Role | Pri | Service | Notes |
|---|---|---|---|
| LLM inference | ① | Workers AI (CF) | Edge inference. 50K+ model catalog (Replicate acquisition). Custom fine-tune planned |
| AI gateway | ① | AI Gateway (CF) | Multi-provider proxy (OpenAI, Anthropic, Bedrock etc.), caching, rate limit, cost tracking, fallback |
| RAG (production) | ① | Vectorize direct (CF) | Custom chunking, reranking, hybrid search |
| RAG (simple) | ② | AutoRAG / AI Search (CF) | R2 single-source auto pipeline. No customization. Internal docs / prototype |
| AI security | ① | Firewall for AI (CF) | Prompt injection blocking, Llama Guard content filter |
| AI crawler control | ① | AI Crawl Control (CF) | Allow/block/402 billing for AI crawlers. Content licensing |
| AI DLP | ① | AI Gateway DLP (CF) | Realtime PII/card/HIPAA pattern blocking in prompts/responses. No code change |
| Headless browser | ① | Browser Rendering (CF) | Playwright support. Web scraping, screenshot, Markdown conversion |

---

## Platform

| Role | Pri | Service | Notes |
|---|---|---|---|
| Auth | ① | Better Auth (External) | TS-native, D1/Neon as auth DB. No MAU billing. Runs on frontend server (TanStack Start). Social providers (Google, Kakao, Naver, GitHub) via plugins |
| Email (transactional) | ① | Resend (External) | Proven deliverability. Payment receipts, password resets, security alerts |
| Email (notification) | ① | CF Email Service (CF) | Workers native binding, no API key. SPF/DKIM/DMARC auto. Deliverability unproven |
| Email (notification) | ② | Resend (External) | When notification deliverability also needs guarantee |
| Payments (global) | ① | Stripe (External) | No CF alternative. Extensive API, webhook reliability |
| Payments (Korea) | ① | Toss Payments (External) | Korean payment methods. Two-step authorize → confirm flow |
| Multi-tenant platform | ① | Workers for Platforms (CF) | Dispatch Worker runs customer code in V8 isolation. Vibe coding, web builder, B2B custom logic |
| Legacy VPC connect | ① | Workers VPC (CF) | AWS/GCP/on-prem VPC → Workers private link. Cloudflare Tunnel based |

---

## Security / Secrets

| Role | Pri | Service | Notes |
|---|---|---|---|
| Secrets (per Worker) | ① | Worker Secrets (CF) | `wrangler secret put`. Encrypted, hidden in dashboard/CLI. Per-Worker isolation |
| Secrets (account-wide) | ① | Secrets Store (CF) | AES two-level key hierarchy, RBAC, audit log. Shared across Workers/AI Gateway |
| Internal access control | ① | CF Zero Trust (CF) | ZTNA, SSO integration. Paired with Workers VPC |

---

## Observability

| Role | Pri | Service | Notes |
|---|---|---|---|
| Auto tracing | ① | Workers Automatic Tracing (CF) | Zero-code OTel spans for KV, DO, R2, D1, fetch, queue/scheduled handlers |
| Logs + Tracing + Metrics | ① | Axiom (External) | Unified observability. Logpush + OTLP ingestion. Dashboards, alerts, long-term retention. Free 500GB/mo |
| Error tracking | ① | Sentry via `@sentry/cloudflare` (External) | `withSentry` for Hono, `instrumentDurableObjectWithSentry`, `instrumentWorkflowWithSentry` |
| Uptime monitoring | ① | BetterStack (External) | External health checks, status page, incident management. Free tier: 10 monitors |
| Product analytics | ① | PostHog (External) | Event tracking, session replay, user journey analysis |
| Feature flags | ① | KV + PostHog (CF+External) | KV TTL cache for 0ms edge evaluation. PostHog for flag management + analytics |

### Observability Implementation Guide

This section covers practical setup for a Cloudflare Workers stack. The goal: maximum visibility with minimum cost and setup time.

#### Error Tracking: Sentry on Workers

**Use `@sentry/cloudflare`** (the official first-party SDK). The older `toucan-js` and `@hono/sentry` middleware are both deprecated.

Why `@sentry/cloudflare` over `toucan-js`:
- `toucan-js` sends events in-process, forcing the Worker to stay alive longer (increases billed wall time)
- Official SDK has full performance tracing, cron monitoring, and the unified Sentry API
- `@hono/sentry` middleware (which wrapped `toucan-js`) is deprecated — migrate to `@sentry/cloudflare` directly

**Prerequisites** — `wrangler.jsonc`:
```jsonc
{
  "compatibility_flags": ["nodejs_compat"],  // required — SDK needs AsyncLocalStorage
  "version_metadata": { "binding": "CF_VERSION_METADATA" }  // release tracking
}
```

**Hono Worker** — wrap with `withSentry`:
```typescript
import { Hono } from 'hono';
import * as Sentry from '@sentry/cloudflare';

const app = new Hono<{ Bindings: Env }>();
// ... routes ...

export default Sentry.withSentry(
  (env: Env) => ({
    dsn: env.SENTRY_DSN,
    tracesSampleRate: 1.0,   // 100% early, reduce at scale
    sendDefaultPii: false,
  }),
  app
);
```

**Durable Objects** — wrap class with `instrumentDurableObjectWithSentry`:
```typescript
import { DurableObject } from 'cloudflare:workers';
import * as Sentry from '@sentry/cloudflare';

class MyDOBase extends DurableObject<Env> {
  async fetch(request: Request) { /* ... */ }
}

export const MyDO = Sentry.instrumentDurableObjectWithSentry(
  (env: Env) => ({ dsn: env.SENTRY_DSN, tracesSampleRate: 1.0 }),
  MyDOBase,
);
```

**Workflows** — wrap with `instrumentWorkflowWithSentry`:
```typescript
import * as Sentry from '@sentry/cloudflare';
import { WorkflowEntrypoint } from 'cloudflare:workers';

class MyWorkflowBase extends WorkflowEntrypoint<Env, Params> {
  async run(event: WorkflowEvent<Params>, step: WorkflowStep) {
    await step.do('fetch data', async () => { /* ... */ });
    await step.do('process data', async () => { /* ... */ });
  }
}

// Sentry uses instanceId to generate trace_id, linking all steps into one trace
// Spans should only be created inside step.do() callbacks
export const MyWorkflow = Sentry.instrumentWorkflowWithSentry(
  (env: Env) => ({ dsn: env.SENTRY_DSN, tracesSampleRate: 1.0 }),
  MyWorkflowBase,
);
```

**Cron/Scheduled handlers** — use `Sentry.withMonitor`:
```typescript
async scheduled(controller: ScheduledController, env: Env, ctx: ExecutionContext) {
  ctx.waitUntil(
    Sentry.withMonitor('daily-cleanup', () => runDailyCleanup(env), {
      schedule: { type: 'crontab', value: '0 3 * * *' },
      checkinMargin: 5,    // minutes tolerance for start
      maxRuntime: 30,      // minutes before marked failed
    })
  );
}
```

**Queue consumers** — instrument with custom spans:
```typescript
async queue(batch: MessageBatch, env: Env, ctx: ExecutionContext) {
  for (const message of batch.messages) {
    await Sentry.startSpan(
      { op: 'queue.process', name: `process-${message.id}` },
      async () => { /* process message */ }
    );
  }
}
```

#### Workers Automatic Tracing

Zero-code, OpenTelemetry-compliant spans. Enable in config, get full visibility.

**What it instruments automatically (no code changes):**
| Operation | Captured Attributes |
|---|---|
| Outbound `fetch()` calls | URL, method, status code, timing |
| KV reads/writes | Operation type, key, duration, error |
| R2 get/put/delete | Operation type, object key, duration, error |
| Durable Object calls | Object ID, method, duration |
| D1 queries | Query type, duration |
| Queue/scheduled handlers | Full handler lifecycle |

**What it does NOT cover (gaps):**
- Internal business logic timing (add custom spans via Sentry if needed)
- SQL query details through Neon/Hyperdrive (the HTTP fetch is traced, not the SQL itself)
- Custom business metrics (track via Axiom dashboards)

**Configuration:**
```jsonc
// wrangler.jsonc
{
  "observability": {
    "traces": {
      "enabled": true,
      "head_sample_rate": 1    // 0-1. Use 1 at low traffic, reduce at scale
    }
  }
}
```

**Pricing (as of March 2026):** Each span = one observability event, sharing the same monthly quota and pricing as Workers Logs.

**OTLP export** — send traces to Axiom without code changes:
```jsonc
// wrangler.jsonc — after creating destination in CF dashboard
{
  "observability": {
    "traces": {
      "enabled": true,
      "head_sample_rate": 1,
      "destinations": ["axiom-prod"]   // name from dashboard config
    }
  }
}
```

Configure Axiom OTLP endpoint in CF dashboard > Observability > Trace destinations. Also supports Sentry, Honeycomb, Grafana Cloud, and any OTLP-compatible backend.

#### Structured Logging

**Use `workers-tagged-logger`** — structured JSON logging with automatic context propagation via `AsyncLocalStorage`. No need to pass a logger through every function.

```typescript
import { Logger, withLogTags } from 'workers-tagged-logger';

const logger = new Logger();

// In your fetch handler (or Hono middleware):
return withLogTags({ requestId: crypto.randomUUID() }, async () => {
  logger.setTags({
    method: request.method,
    path: new URL(request.url).pathname,
    userId: getUserId(request),   // add after auth middleware
  });

  logger.info('request started');

  // Deep in your code — no logger parameter needed, tags propagate via ALS
  const result = await handleBusinessLogic(env);

  logger.info('request completed', { status: 200, durationMs: elapsed });
  return new Response(JSON.stringify(result));
});
```

For Durable Objects, use the `@WithLogTags` class method decorator for automatic context per method call.

**What to log:**
| Always | Never |
|---|---|
| Request ID (correlation) | Auth tokens, API keys, passwords |
| Route/path + method | Full request/response bodies in production |
| Response status code | PII without a retention policy |
| Duration (wall time) | |
| User/tenant ID (for debugging) | |
| Error stack traces on failure | |
| Queue: messageId, attempt count, outcome | |
| DO: object ID, operation type, duration | |

**Log levels:**
- `console.log()` → routine (request start/complete, business events)
- `console.warn()` → degraded (retries, fallbacks, slow queries)
- `console.error()` → failures needing investigation

**Sampling strategy:** At < 100K req/day, log everything. Above that, sample routine logs at 10-50% but keep 100% for errors. Use `head_sample_rate` in wrangler config for global sampling; use conditional logging in code for per-level control.

#### PostHog on Workers

Use `posthog-node` for server-side event capture. Critical configuration for Workers:

```typescript
import { PostHog } from 'posthog-node';

// Create per-request (lightweight) — do NOT reuse across requests
const posthog = new PostHog(env.POSTHOG_API_KEY, {
  host: env.POSTHOG_HOST,
  flushAt: 1,          // CRITICAL: send immediately, no batching
  flushInterval: 0,    // CRITICAL: Workers terminate after response
});

// Capture event — use ctx.waitUntil to ensure delivery
ctx.waitUntil(posthog.shutdownAsync());  // flushes all pending events
posthog.capture({
  distinctId: userId,
  event: 'api_called',
  properties: { endpoint: '/api/users', method: 'POST' },
});
```

**Why `flushAt: 1` and `flushInterval: 0`:** Workers can terminate before batched async sends complete, causing silent data loss. These settings force immediate send.

**Known issue:** `captureImmediate()` may not properly await the internal `_capture` promise. Use `ctx.waitUntil(posthog.shutdownAsync())` as the reliable pattern.

#### Uptime Monitoring

You need **external** health checks — something outside Cloudflare pinging your endpoints.

| Service | Free Tier | Paid From | Best For |
|---|---|---|---|
| **BetterStack** | 10 monitors, 3-min checks | ~$21/mo per 50 monitors | Status page + incident management + on-call |
| **OpenStatus** | Hosted free tier; or self-host | Paid tiers available | Open source, 28 global regions, CF Pages status page |
| **UptimeFlare** | 100% free (runs on CF Workers + D1) | Free | Zero cost. Trade-off: monitoring CF from CF |
| **CF Health Checks** | Pro+ plans | Pro plan | Origin monitoring, not Workers-specific |

**Health endpoint pattern:**
```typescript
// GET /health — lightweight, frequent checks (every 1 min)
app.get('/health', (c) => c.json({ status: 'ok', timestamp: Date.now() }));

// GET /health/deep — dependency checks, less frequent (every 5 min)
app.get('/health/deep', async (c) => {
  const checks = await Promise.allSettled([
    checkNeon(c.env),        // SELECT 1
    checkR2(c.env),          // HEAD on known object
    checkDurableObject(c.env),
  ]);
  const allHealthy = checks.every(c => c.status === 'fulfilled');
  return c.json({ status: allHealthy ? 'ok' : 'degraded', checks }, allHealthy ? 200 : 503);
});
```

#### Alerting

Cloudflare has limited native alerting for Workers. Combine multiple tools:

| Alert Type | Tool | Setup |
|---|---|---|
| Error spikes | Sentry alerts | Threshold: "new errors > 10/hour" or error rate > 1% |
| Cron missed/failed | Sentry Crons (`withMonitor`) | Automatic via cron instrumentation |
| Endpoint down | BetterStack / OpenStatus | External health check → Slack/email/SMS |
| CPU usage spike | CF Usage Notifications | Built-in: triggers when CPU is 25% above 7-day average |
| Build failures | Workers Builds Events | Event Subscriptions → Queue → Slack webhook |
| Slow queries | Neon dashboard | pg_stat_statements monitoring |

#### Neon Postgres Monitoring

Neon provides built-in monitoring — no extra tooling needed at solopreneur scale.

**Neon Console dashboard:**
- Connection graphs (idle, active, total)
- Pooler client/server connections (PgBouncer metrics)
- Autoscaling event timeline
- Query performance via `pg_stat_statements` (execution counts, avg/total time)
- Active queries via `pg_stat_activity`

**At scale:** Neon exports OpenTelemetry and Datadog metrics (including PgBouncer pooling metrics). Grafana Cloud has a native Neon integration for dashboards.

#### Day 1 Setup

All tools below are free at solopreneur scale. Set up once, reuse across all projects.

| Layer | Tool | Setup |
|---|---|---|
| Error tracking | `@sentry/cloudflare` | 1 hour |
| Logs + Tracing + Metrics | Axiom via Logpush + OTLP export | 30 min |
| Structured logging | `workers-tagged-logger` | 1 hour |
| Product analytics | PostHog | — |
| Uptime | BetterStack free tier (10 monitors) | 30 min |

```jsonc
// wrangler.jsonc observability config
{
  "observability": {
    "logs": { "enabled": true, "head_sample_rate": 1, "invocation_logs": "auto" },
    "traces": { "enabled": true, "head_sample_rate": 1, "destinations": ["axiom-prod"] }
  }
}
```

**At scale:** Lower `head_sample_rate` and `tracesSampleRate` for cost control. Upgrade BetterStack for 1-min checks + SMS alerts.

---

## Infrastructure / Deploy

| Role | Pri | Service | Notes |
|---|---|---|---|
| DNS | ① | Cloudflare DNS (CF) | Fastest authoritative DNS. Proxy mode for WAF/caching |
| CDN | ① | Cloudflare CDN (CF) | Global CDN, DDoS protection, edge caching. Free tier |
| CI/CD | ① | GitHub Actions + Workers Builds (External+CF) | GHA for test/lint, Workers Builds for deploy |
| IaC / Config | ① | Wrangler + wrangler.toml (CF) | CLI-based deploy and config. No separate IaC tool needed |
| Cron (simple) | ① | Cron Triggers (CF) | Worker-native cron. Scheduled tasks |
| Cron (complex) | ① | Workflows (CF) | Multi-step scheduled pipelines with retry/checkpoint |

---

## Vendor Lock-in Assessment

| Service | Portability | Migration Path |
|---|---|---|
| R2 | High | S3-compatible API. Direct migration to any S3-compatible store |
| Neon | High | Standard Postgres. pg_dump/restore to any Postgres |
| KV | Medium | Key-value abstraction. Migrate to Redis/DynamoDB with adapter |
| D1 | Medium | SQLite-compatible. Export and host elsewhere |
| Durable Objects | Low | No equivalent elsewhere. Rewrite to Redis + WebSocket server |
| Agents SDK | Low | DO-based, CF-only. Rewrite to LangGraph or custom agent runtime |
| Workers AI | Medium | Standard model APIs. Switch to direct provider API calls |
| Vectorize | Medium | Standard vector operations. Migrate to pgvector or dedicated vector DB |
