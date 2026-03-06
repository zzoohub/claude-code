# Stack Templates

When starting a design doc, ask the user to choose a stack template. Each template is a proven, internally consistent set of technology choices optimized for solopreneur development.

---

## Template Selection

| Template | Backend | Frontend | DB | Infra | Choose When |
|---|---|---|---|---|---|
| **Rust** (default) | Rust/Axum | TanStack Start + SolidJS | Neon | GCP Cloud Run + Cloudflare | Performance/cost critical, long-running services, type safety maximalist |
| **TypeScript** | Hono on Workers | TanStack Start + SolidJS | Neon | Cloudflare fullstack | Fastest development velocity, edge-first, fullstack JS/TS |
| **Python AI** | FastAPI | TanStack Start + SolidJS | Neon | GCP Cloud Run + Cloudflare | Core product requires Python-only libraries (PyTorch, transformers, etc.) |

If the user doesn't specify, use **Rust** as the default.

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

**Compute**: Cloudflare Workers (global edge)
- No region selection needed -- deployed globally by default
- Workers for API/backend logic
- Pages for static assets and frontend

**When to deviate**:
- GCP Cloud Run when you need longer execution times (>30s), larger payloads, or container-based workloads that don't fit the Workers model

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

## Shared: Frontend (All Templates)

**TanStack Start + SolidJS** -- used across all templates.
- Fine-grained reactivity: no virtual DOM diffing, surgical DOM updates
- TanStack Router: type-safe routing with built-in data loading
- Vinxi/Nitro based: deploys to Cloudflare Workers, Vercel, Node, any platform
- Smaller bundle sizes than React equivalents

**Deployment per template**:
- Rust template -> Cloudflare Pages/Workers
- TypeScript template -> Cloudflare Pages (same platform as backend)
- Python AI template -> Cloudflare Pages/Workers

**SSR/SSG trade-off**: TanStack Start's SSR/SSG is less mature than Next.js. For the rare SEO-critical marketing page, consider a static site generator or dedicated landing page. Most solopreneur apps live behind auth where SEO is irrelevant.

---

## Shared: Database (All Templates)

**Neon (Serverless PostgreSQL)** -- used across all templates.

| Aspect | Detail |
|---|---|
| Default region | us-east-1 (Virginia) for global; ap-northeast-2 (Seoul) for Korea-only |
| Why Neon | Scale-to-zero pricing, branching for dev/staging, full PostgreSQL (pgvector, extensions), serverless driver works from Workers |

**Neon serverless driver** (`@neondatabase/serverless`): Works over HTTP/WebSocket, specifically designed for edge runtimes (Cloudflare Workers, Vercel Edge). No TCP connection needed.

**When to consider alternatives**:
- **Supabase** (ap-northeast-2): When Supabase's bundled features (Auth, Realtime, Storage) would save significant development time AND the project targets Korean users. Note: free tier limited to 2 active projects.
- **GCP Cloud SQL**: When you need full Postgres control, pg_cron, custom extensions, or vertical scaling beyond Neon's limits.

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
- **Model**: Role-Based Access Control (RBAC)
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
| Email (Inbound) | Cloudflare Email Routing | Free, simple, integrates with Workers for processing. |
| Email (Outbound) | Resend | Developer-friendly API, React Email for templates, good deliverability. |
| Error Tracking | Sentry | Industry standard. Source maps, breadcrumbs, performance monitoring. |
| Infrastructure as Code | Pulumi | TypeScript-native IaC. Avoids HCL context-switch. |
| Payments (Global) | Stripe | Gold standard for global payments. Extensive API, webhook reliability. |
| Payments (Korea) | Toss Payments | Required for Korean payment methods. |
| User Analytics | PostHog | Self-hostable, feature flags, session replay, funnels. Privacy-friendly. |
| CI/CD | GitHub Actions | Integrated with Git workflow. Free tier generous for open source. |

---

## Shared: Messaging & Async Processing

| Template | Default | Notes |
|---|---|---|
| **Rust** | GCP Pub/Sub | Native Cloud Run push integration. Cloud Tasks for sequential orchestration. |
| **TypeScript** | Cloudflare Queues | Native Workers integration. For heavier needs, consider GCP Pub/Sub. |
| **Python AI** | GCP Pub/Sub | Same as Rust template. |

**Redis (Memorystore)**: Add when you need sub-ms caching, session storage, or rate limiting. Not a replacement for durable messaging.

**Kafka**: Not needed until millions of events/sec with complex stream processing. Upgrade path via GCP Managed Kafka.

### Neon as Event Source (CDC)
Neon supports logical replication with wal2json output. Stream database changes directly to Pub/Sub, Kafka, or other consumers. Enable via Neon Console -> Project Settings -> Logical Replication.

---

## Shared: Platform Ecosystem Strategy

Follow the **platform cohesion principle** -- prefer services from the same platform as your compute:

| Template | Primary Platform | Prefer Services From |
|---|---|---|
| **Rust** | GCP | Cloud Scheduler, Cloud Tasks, Memorystore, Pub/Sub, Cloud Logging/Monitoring |
| **TypeScript** | Cloudflare | Cron Triggers, Queues, KV, Durable Objects, Logpush |
| **Python AI** | GCP | Same as Rust template |

**Secrets**: `pulumi config set --secret` for solopreneur scale. Upgrade to GCP Secret Manager when you need automated rotation, audit trails, or shared team access -- document the migration as an ADR.

**Why platform cohesion**: Reduced network hops, unified billing, consistent auth model, simpler operational surface. Mixing ecosystems increases cognitive load and failure surface without proportional benefit for a solopreneur.

---

## Shared: Region Strategy

| Scenario | Primary Region | Rationale |
|---|---|---|
| Global service | us-east (Virginia) | Central to NA/EU, major cloud provider hubs |
| Korea-only service | ap-northeast-2 (Seoul) | Lowest latency for Korean users |
| TypeScript template | Cloudflare global | Workers are inherently global |

**Co-location rule**: Keep compute and database in the same region to minimize inter-service latency. This is more important than putting compute close to users -- use Cloudflare CDN/edge for that.
