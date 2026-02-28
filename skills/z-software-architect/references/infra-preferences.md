# Infrastructure Preferences

This reference contains the preferred infrastructure choices for the solopreneur context. Use as the default starting point for all architecture decisions. Deviate only when project requirements clearly demand it, and document the deviation as an ADR.

---

## Database (PostgreSQL)

| Priority | Platform | Region | When to Use |
|---|---|---|---|
| 1st | **Neon** | us-east-1 (Virginia) | Default for global services. Zero-to-scale pricing, managed, low ops overhead. |
| 2nd | **Supabase** | ap-northeast-2 (Korea) | Korean-audience services needing low latency, real-time features (Supabase Realtime), or when Supabase's auth/storage/edge-functions ecosystem significantly reduces build effort. |
| 3rd | **GCP Cloud SQL** | Flexible | When you need full Postgres feature control, extensions not supported by managed platforms, or vertical scaling beyond managed tier limits. |

### Decision Factors
- **Neon over Supabase**: Neon's serverless branching model is superior for development workflows. Scale-to-zero is critical for solopreneur cost management. Choose Neon unless Supabase's bundled features (Auth, Storage, Realtime) would save significant development time.
- **Supabase over Cloud SQL**: Supabase still provides managed experience. Choose it when the real-time or region-specific needs outweigh Neon's advantages.
- **Cloud SQL last resort**: Only when you need pg_cron, custom extensions, logical replication, or other features not supported by Neon/Supabase.

---

## Backend Compute

| Priority | Platform | Region | When to Use |
|---|---|---|---|
| 1st | **GCP Cloud Run** | us-east4 (Virginia) | Default. Container-based, auto-scaling, generous free tier, supports any language/runtime. Cold starts acceptable for most B2C workloads. |
| 2nd | **Cloudflare Workers** | Edge (global) | When V8 runtime limitations aren't blockers AND edge-locality provides meaningful latency improvement (e.g., auth validation, content personalization, lightweight API proxies). |
| 3rd | **GCP Compute Engine** | Same as Cloud SQL | When you need persistent processes (long-running workers, WebSocket servers), GPU access, or custom kernel/networking requirements. |

### Decision Factors
- **Cloud Run over Workers**: Cloud Run supports any container, any language. Rust binaries, Python ML models, etc. all work natively. Workers are limited to V8 (JavaScript/TypeScript/WASM).
- **Workers over Cloud Run**: For latency-sensitive edge work where the V8 constraint isn't an issue. Workers have near-zero cold starts and global distribution by default.
- **Compute Engine last resort**: Persistent connections, stateful workloads, or heavy computation that doesn't fit the request-response model.

---

## Frontend

| App Type | Framework | Hosting | When to Use |
|---|---|---|---|
| **Client-side** | **TanStack Start** | **Cloudflare Workers** | Dashboards, admin panels, SPAs, post-auth experiences, real-time interactive apps. Client-first with optional SSR. |
| **Server-side** | **Next.js** | **Vercel** | SEO-critical pages, content-heavy sites, marketing pages, SSR/SSG/ISR needed. |

### Decision Factors
- **TanStack Start over Next.js**: When the app lives behind auth and SEO is irrelevant. Lighter runtime, no server component complexity, TanStack Router's type-safe routing and built-in data loading. Better fit for highly interactive client-driven UIs.
- **Next.js over TanStack Start**: When SEO, SSG, or server-side rendering is a core requirement. Mature ecosystem, larger community, more deployment options.
- **TanStack Start → Cloudflare Workers**: Edge delivery, predictable pricing, Vinxi/Nitro on Workers. Ideal for client-heavy apps that don't need Vercel's SSG/ISR pipeline.
- **Next.js → Vercel**: Vercel builds Next.js. SSG/ISR/middleware/image optimization all work best on Vercel. Incremental build cache and edge revalidation are purpose-built for content-heavy rendering.

---

## Mobile

| Platform | Framework | Rationale |
|---|---|---|
| **Always** | Expo (React Native) | React ecosystem familiarity. Single codebase for iOS + Android. Expo's managed workflow reduces native build complexity. EAS for builds and OTA updates. |

---

## Messaging & Async Processing

| Priority | Service | When to Use |
|---|---|---|
| 1st | **GCP Pub/Sub** | Default for event-driven patterns. Serverless, auto-scales, native Cloud Run push integration. Fan-out (one event → many consumers), event notifications, async pipelines. |
| 2nd | **GCP Cloud Tasks** | Simple async task queues with retries, rate limiting, and delayed execution. Better than Pub/Sub for sequential orchestration (saga orchestrator) or when you need built-in scheduling and deduplication. |
| 3rd | **Memorystore (Redis)** | Lightweight pub/sub within a single service, caching, session storage, rate limiting. Not durable — use only for ephemeral messaging or caching. |

### Decision Factors
- **Pub/Sub over Cloud Tasks**: When multiple consumers need the same event, or when you need topic-based routing. Pub/Sub is the backbone for EDA and saga choreography.
- **Cloud Tasks over Pub/Sub**: When you need exactly-once delivery to a single target, rate-limited dispatch, or scheduled delays. Better for saga orchestration and webhook delivery.
- **When to add Redis**: When you need sub-ms caching, session storage, or simple in-memory queues alongside Pub/Sub. Not a replacement for durable messaging.
- **Kafka/Managed Kafka**: Not needed until you hit millions of events/sec, require complex stream processing (joins, windowing), or need long-term event log retention. Upgrade path exists via GCP Managed Service for Apache Kafka.

### Neon as Event Source (CDC)
Neon supports logical replication with wal2json output. This enables Change Data Capture: stream database changes directly to Pub/Sub, Kafka, or other consumers. Enable via Neon Console → Project Settings → Logical Replication. Useful for event-driven patterns without introducing a separate event store.

---

## Supporting Services

| Service | Choice | Rationale |
|---|---|---|
| Object Storage | Cloudflare R2 | S3-compatible, no egress fees. Use presigned URLs for direct client uploads. |
| Email (Inbound) | Cloudflare Email Routing | Free, simple, integrates with Workers for processing. |
| Email (Outbound) | Resend | Developer-friendly API, React Email for templates, good deliverability. |
| Error Tracking | Sentry | Industry standard. Source maps, breadcrumbs, performance monitoring. |
| Infrastructure as Code | Pulumi | TypeScript-native IaC. Avoids HCL context-switch. |
| Payments (Global) | Stripe | Gold standard for global payments. Extensive API, webhook reliability. |
| Payments (Korea) | Toss Payments | Required for Korean payment methods (카드, 계좌이체, etc.) |
| User Analytics | PostHog | Self-hostable, feature flags, session replay, funnels. Privacy-friendly. |
| CI/CD | GitHub Actions | Integrated with Git workflow. Free tier generous for open source. |

---

## Auth Pattern

### Authentication
- **Primary**: Social login (Google OAuth2) + self-issued JWT
  - Access token: short-lived (15min), in memory or Authorization header
  - Refresh token: long-lived (7-30 days), httpOnly secure cookie
- **Future**: Passkey (WebAuthn) as password-free upgrade path

### Authorization
- **Model**: Role-Based Access Control (RBAC)
- **Enforcement**: Middleware layer in backend (not in database, not in frontend)

---

## Platform Ecosystem Strategy

When choosing ancillary services (cron jobs, queues, caching, pub/sub, secrets, observability), follow the **platform cohesion principle**:

- If backend is on **GCP** → prefer GCP services (Cloud Scheduler, Cloud Tasks, Memorystore, Pub/Sub, Cloud Logging/Monitoring)
- If backend is on **Cloudflare** → prefer Cloudflare services (Cron Triggers, Queues, KV/D1, Pub/Sub via Workers, Logpush)
- **Secrets**: `pulumi config set --secret`. Do not use platform secret managers (GCP Secret Manager, Cloudflare Secrets).

**Why**: Reduced network hops, unified billing, consistent auth model, simpler operational surface. Mixing ecosystems increases cognitive load and failure surface without proportional benefit for a solopreneur.

---

## Region Strategy

| Scenario | Primary Region | Rationale |
|---|---|---|
| Global service | us-east (Virginia) | Central to NA/EU, major cloud provider hubs, lowest inter-service latency for most global architectures |
| Korea-only service | ap-northeast-2 (Seoul/Korea) | Lowest latency for Korean users |
| Edge-first | Cloudflare global | When using Workers, deployment is inherently global |

**Co-location rule**: Keep compute and database in the same region to minimize inter-service latency. This is more important than putting compute close to users — use a CDN/edge for that.
