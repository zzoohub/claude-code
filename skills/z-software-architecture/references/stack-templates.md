# Stack Templates

When starting a design doc, ask the user to choose a stack template. Each template is a proven, internally consistent set of technology choices optimized for solopreneur development.

---

## Stack Selection (Two Axes)

The user picks one backend and one frontend independently. Any combination is valid.

### Backend Options

| Backend | Infra | Choose When |
|---|---|---|
| **Rust/Axum** (default) | GCP Cloud Run + Cloudflare | Performance/cost critical, long-running services, type safety maximalist |
| **Hono** | Cloudflare Workers | Edge-first, fullstack TypeScript, global distribution |
| **FastAPI** | GCP Cloud Run + Cloudflare | Core product requires Python-only libraries (PyTorch, transformers, etc.) |

### Frontend Options

| Frontend | Deploy To | Choose When |
|---|---|---|
| **TanStack Start + SolidJS** (default) | Cloudflare Workers | Fine-grained reactivity, smaller bundles, no virtual DOM overhead |
| **Next.js (React)** | Vercel (default) or Cloudflare via OpenNext | Rich React ecosystem needed (Radix, shadcn/ui, etc.), SEO-critical content-heavy product, team has deep React expertise |

### Shared across all combinations
- **Database**: Neon (Serverless PostgreSQL)
- **CDN/DNS**: Cloudflare

If the user doesn't specify, use **Rust/Axum + TanStack Start** as the default combination.

---

## Rust Template

**Backend**: Rust (Axum) on GCP Cloud Run
- Container-based, auto-scaling, generous free tier
- Sub-ms response times, 10-30MB memory, near-zero cold starts
- Compiler as second reviewer -- if it compiles, entire error classes are eliminated
- Lower cloud cost (critical for solopreneur economics)

**Compute**: GCP Cloud Run (us-east4, Virginia)
- Default for container workloads
- Cold starts acceptable for most B2C workloads
- Scaling: horizontal auto-scale, scale-to-zero

**When to deviate**:
- Cloudflare Workers for edge-latency-sensitive paths (auth validation, content personalization) where V8 runtime isn't a blocker
- GCP Compute Engine for persistent processes (WebSocket servers), GPU access

---

## TypeScript Template

**Backend**: Hono on Cloudflare Workers
- Edge-first, near-zero cold starts, global distribution by default
- Lightweight, Web Standards API compatible
- Predictable pricing, generous free tier
- Perfect for API-heavy services and edge computing
- HonoRPC for end-to-end type-safe API calls between frontend and backend (built-in, no extra dependency)

**Compute**: Cloudflare Workers (global edge)
- No region selection needed -- deployed globally by default
- Workers for API/backend logic
- Pages for static assets and frontend

**When to deviate**:
- GCP Cloud Run when you need longer execution times (>30s), larger payloads, or container-based workloads that don't fit the Workers model. Use Hono on Node.js for consistency with the Workers codebase (same API, different runtime), or Fastify if you need its plugin ecosystem.

---

## Python AI Template

**Backend**: FastAPI on GCP Cloud Run
- Only use when the project physically requires Python-only libraries (PyTorch, transformers, pandas/numpy heavy pipelines)
- LLM API calls alone do NOT justify Python -- use the Rust template with reqwest
- Async-first, Pydantic v2 validation built-in

**Compute**: GCP Cloud Run (us-east4, Virginia)
- Same as Rust template -- container-based, auto-scaling
- Set request timeout to 300s for ML inference endpoints

**When to deviate**: Same as Rust template.

---

## Frontend: TanStack Start + SolidJS (default)

- Fine-grained reactivity: no virtual DOM diffing, surgical DOM updates
- TanStack Router: type-safe routing with built-in data loading
- Vinxi/Nitro based: deploys to Cloudflare Workers, Vercel, Node, any platform
- Smaller bundle sizes than React equivalents
- Deploy to Cloudflare Workers (default)

**SSR/SSG trade-off**: TanStack Start's SSR/SSG is less mature than Next.js. For the rare SEO-critical marketing page, consider a static site generator or dedicated landing page. Most solopreneur apps live behind auth where SEO is irrelevant.

---

## Frontend: Next.js (React)

- Mature SSR/SSG/ISR with excellent SEO support
- Rich React ecosystem: Radix, shadcn/ui, React Three Fiber, Framer Motion, etc.
- App Router with Server Components and Server Actions
- tRPC for end-to-end type-safe API layer when using Next.js as fullstack (API Routes)
- Deploy to Vercel (default) or Cloudflare via OpenNext

**Choose when**: The project depends heavily on React ecosystem libraries with no SolidJS equivalents, the team has deep React expertise, or the product is SEO-critical and content-heavy.

---

## Shared: Database

Choose based on the target audience:

| Audience | Default DB | Region | Rationale |
|---|---|---|---|
| **Global** | **Neon** | us-east-1 (Virginia, AWS) | Scale-to-zero, branching, serverless driver for edge runtimes |
| **Korea-first** | **Supabase** | ap-northeast-2 (Seoul) | Neon has no Korean region — Supabase provides Seoul region with free tier, bundled Auth/Realtime/Storage |

### Neon (Serverless PostgreSQL) — global default

- Scale-to-zero pricing, branching for dev/staging, full PostgreSQL (pgvector, extensions)
- **Cross-cloud latency note**: Neon runs on AWS (us-east-1) while Cloud Run runs on GCP (us-east4). Both are in Virginia — inter-cloud latency within the same geographic area is typically 1-3ms, negligible for most workloads.

**Serverless connection strategy** — serverless environments can exhaust DB connection limits. Choose the right approach per runtime:

| Runtime | Connection Method | Why |
|---|---|---|
| **Cloudflare Workers** | Neon serverless driver (HTTP) | V8 runtime has no TCP sockets — HTTP is the only option |
| **Cloud Run (Rust/SQLx, Python/psycopg2)** | Neon pooler endpoint (`-pooler` URL) | Native Postgres drivers require TCP — use PgBouncer pooler. Keep pool small per instance (`max_connections=5`). |
| **Next.js on Vercel** | Neon serverless driver (HTTP) | Edge Runtime has no TCP; Node.js Runtime also benefits from HTTP — serverless functions have short lifespans making persistent connections wasteful |

Neon pooler endpoint example:
```
# Direct (connection exhaustion risk)
postgresql://user:pass@ep-xxx.us-east-1.aws.neon.tech/db
# Pooler (recommended for TCP clients)
postgresql://user:pass@ep-xxx-pooler.us-east-1.aws.neon.tech/db
```

### Supabase — Korea-first default

- PostgreSQL on AWS ap-northeast-2 (Seoul) — lowest latency for Korean users
- Bundled features save development time: Auth (Kakao/Naver OAuth built-in), Realtime subscriptions, Storage (S3-compatible)
- Free tier: 2 active projects, 500MB DB, 1GB storage
- Supabase client SDK works from both server and edge runtimes
- Trade-off: no branching (use migrations instead), less granular scale-to-zero than Neon

### When to consider GCP Cloud SQL
- Need full Postgres control, pg_cron, custom extensions, or vertical scaling beyond Neon/Supabase limits

---

## Shared: Auth Pattern

### Authentication

Choose based on the product's audience:

| Scenario | Primary Method | Notes |
|---|---|---|
| **Global B2C** | Google OAuth2 + self-issued JWT | Widest reach, lowest friction |
| **Korea B2C** | Kakao OAuth2 (primary) + Naver + Google | Kakao dominates Korean market. Naver is second. Google for non-Korean users. |
| **B2B / SaaS** | Email magic link or SSO (OIDC/SAML) | Enterprise customers expect SSO. Magic link for self-serve signups. |
| **Internal tools** | Google Workspace OAuth2 | Single-click for team members |

**Token strategy** (all scenarios):
- Access token: short-lived (15min), in memory or Authorization header
- Refresh token: long-lived (7-30 days), httpOnly secure cookie

**Future**: Passkey (WebAuthn) as password-free upgrade path for all scenarios.

### Authorization
- **Default model**: RBAC (Role-Based Access Control) — sufficient for most apps
- **Consider ABAC** (Attribute-Based Access Control) when permissions depend on resource attributes (e.g., "users can edit only their own posts")
- **Consider ReBAC** (Relationship-Based Access Control) when permissions follow a graph of relationships (e.g., "org admin can manage all projects in their org") — Google Zanzibar pattern
- **Enforcement**: Middleware layer in backend (not in database, not in frontend)

---

## Shared: CDN & DNS

| Service | Choice | Rationale |
|---|---|---|
| **CDN** | Cloudflare | Already in stack (all templates). Free tier includes global CDN, DDoS protection, and edge caching. |
| **DNS** | Cloudflare DNS | Fastest authoritative DNS. Unified with CDN and edge services. Proxy mode enables WAF and caching without infrastructure changes. |

**Edge caching strategy**: Cache static assets aggressively (immutable hashes, 1yr TTL). Use `stale-while-revalidate` for API responses where eventual consistency is acceptable. Never cache authenticated API responses at the edge.

---

## Shared: Supporting Services

| Service | Choice | Rationale |
|---|---|---|
| Object Storage | Cloudflare R2 | S3-compatible, no egress fees. Use presigned URLs for direct client uploads. |
| Email (Outbound) | Resend | Developer-friendly API, React Email for templates, good deliverability. 100 emails/day free tier. |
| Email (Inbound) | Cloudflare Email Routing | Only if the app needs to receive/process emails. Free, integrates with Workers. Most apps don't need this. |
| Error Tracking | Sentry | Industry standard. Source maps, breadcrumbs, performance monitoring. |
| Infrastructure as Code | Pulumi | TypeScript-native IaC. Avoids HCL context-switch. |
| Payments (Global) | Stripe | Gold standard for global payments. Extensive API, webhook reliability. |
| Payments (Korea) | Toss Payments | Required for Korean payment methods. |
| User Analytics | PostHog | Self-hostable, feature flags, session replay, funnels. Privacy-friendly. |
| CI/CD | GitHub Actions | Integrated with Git workflow. Free tier generous for open source. |

---

## Shared: Messaging & Async Processing

| Backend | Default | Notes |
|---|---|---|
| **Rust/Axum** (Cloud Run) | GCP Pub/Sub | Native Cloud Run push integration. Cloud Tasks for sequential orchestration. |
| **Hono** (Workers) | Cloudflare Queues | Native Workers integration. For heavier needs, consider GCP Pub/Sub. |
| **FastAPI** (Cloud Run) | GCP Pub/Sub | Same as Rust. |

**Redis (Upstash)**: Add when you need caching, session storage, or rate limiting. Supports both HTTP and TCP — HTTP for Workers/Edge (no TCP sockets), TCP for Cloud Run (lower latency). Scale-to-zero pricing aligns with solopreneur cost model. Upstash also provides rate limiting SDK (`@upstash/ratelimit`) out of the box. Upgrade path: GCP Memorystore when you need sub-ms latency at high throughput and are on Cloud Run only.

**Kafka**: Not needed until millions of events/sec with complex stream processing. Upgrade path via GCP Managed Kafka.

### Neon as Event Source (CDC)
Neon supports logical replication with wal2json output. Stream database changes directly to Pub/Sub, Kafka, or other consumers. Enable via Neon Console -> Project Settings -> Logical Replication.

---

## Shared: Platform Ecosystem Strategy

Follow the **platform cohesion principle** -- prefer services from the same platform as your compute:

| Backend | Primary Platform | Prefer Services From |
|---|---|---|
| **Rust/Axum** | GCP | Cloud Scheduler, Cloud Tasks, Pub/Sub, Cloud Logging/Monitoring |
| **Hono** | Cloudflare | Cron Triggers, Queues, KV, Durable Objects, Logpush |
| **FastAPI** | GCP | Same as Rust/Axum |

**Secrets**: `pulumi config set --secret` for solopreneur scale. Upgrade to GCP Secret Manager when you need automated rotation, audit trails, or shared team access -- document the migration as an ADR.

**Why platform cohesion**: Reduced network hops, unified billing, consistent auth model, simpler operational surface. Mixing ecosystems increases cognitive load and failure surface without proportional benefit for a solopreneur.

---

## Shared: Region Strategy

| Scenario | Compute | DB | Region |
|---|---|---|---|
| **Global** | Cloud Run (us-east4) or Workers (global) | Neon (us-east-1) | Virginia |
| **Korea-first** | Cloud Run (asia-northeast3, Seoul) | Supabase (ap-northeast-2, Seoul) | Seoul |
| **Hono backend** | Cloudflare Workers | Neon or Supabase per audience | Workers are inherently global |

**Co-location rule**: Keep compute and database in the same geographic region to minimize inter-service latency. For Korea-first apps, co-locate both in Seoul. This is more important than putting compute close to users -- use Cloudflare CDN/edge for that.
