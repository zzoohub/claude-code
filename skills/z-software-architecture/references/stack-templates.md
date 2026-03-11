# Stack Templates

Platform bundles optimized for solopreneur development. Each bundle is a cohesive set of compute, storage, and services from the same ecosystem — unified billing, single CLI, one dashboard.

---

## Bundle Selection

Choose one bundle per project. Backend framework choice is independent of bundle.

| Bundle | Compute | Frontend | DB | Choose When |
|---|---|---|---|---|
| **Cloudflare** (default) | Workers + CF Containers | TanStack Start + SolidJS | Neon + Hyperdrive | Edge-first, global low-latency, TS fullstack, unified CF infra |
| **Vercel** | Vercel Functions | Next.js (React) | Supabase | Content-heavy, SEO, React ecosystem, Korea-first (Supabase Seoul) |

**GCP Cloud Run** = escape hatch when CF Containers can't do it (GPU, Vertex AI, GCP-only integrations).

If the user doesn't specify, use the **Cloudflare bundle**.

### Bundle Decision Flow

```
Project characteristics?
├── Edge-first, API-heavy, TS fullstack     → Cloudflare bundle
├── Content/SEO-heavy, React ecosystem      → Vercel bundle
├── Korea-first + Kakao/Naver auth needed   → Vercel bundle (Supabase Seoul + Auth)
├── Korea-first + edge API priority         → Cloudflare bundle + Supabase via Hyperdrive
└── GPU / GCP-locked legacy                 → Cloudflare bundle + Cloud Run escape hatch
```

---

## Backend Framework Options

Framework choice is independent of bundle. Pick based on workload, not platform.

| Framework | Runtime | Choose When |
|---|---|---|
| **Hono (TS)** (default) | Workers / CF Containers / Node.js | General web services, API, fullstack TS. <4kB, RPC built-in |
| **Rust/Axum** | Workers (workers-rs) / CF Containers / Cloud Run | CPU-intensive, memory safety, maximum performance |
| **FastAPI (Python)** | CF Containers / Cloud Run | Python-only ML libraries (PyTorch, transformers). LLM API calls alone do NOT justify Python |

---

## Frontend Options

| Frontend | Deploy To | Choose When |
|---|---|---|
| **TanStack Start + SolidJS** (default) | CF Workers | Fine-grained reactivity, minimal bundles, Workers binding friendly |
| **Astro** | CF Workers adapter | Content-first, Islands architecture. Blog/marketing/docs pages |
| **Next.js (React)** | Vercel (default) | React ecosystem, SEO-critical content-heavy product, team has React expertise |

---

## Cloudflare Bundle

Default bundle. All services from one platform.

See **`references/cloudflare-platform.md`** for the full tech stack reference with ①② priority rankings per role.

**Key characteristics**:
- Workers: stateless edge compute, 330+ PoP, ~0ms cold start
- CF Containers: long-running containers (16vCPU/64GB), sleep/wake cycle
- Durable Objects: stateful coordination, WebSocket hub
- Workflows + Queues: async processing with retry/checkpoint
- R2, KV, D1, Vectorize: storage primitives
- AI Gateway, Workers AI: LLM proxy and edge inference
- Wrangler CLI: single tool for deploy and config

**Compute decision flow**:
```
├── Stateless API, <30s             → Workers
├── Stateful, WebSocket             → Durable Objects
├── Async, multi-step               → Workflows + Queues
├── Container, CPU/memory heavy     → CF Containers
└── GPU, GCP-locked                 → Cloud Run (escape hatch)
```

---

## Vercel Bundle

For Next.js + Supabase projects. Korea-first or React-ecosystem-heavy products.

### Why This Bundle Exists
- Next.js is first-class on Vercel — OpenNext on CF has friction
- Supabase Seoul region — lowest latency for Korean users
- Supabase Auth with Kakao/Naver/Google OAuth built-in — no custom implementation
- Supabase Realtime — chat, notifications, live updates bundled

### Stack

| Role | Service | Notes |
|---|---|---|
| Compute | Vercel Functions | Serverless (Node.js) + Edge Runtime |
| Frontend | Next.js App Router | SSR/SSG/ISR. Server Components + Server Actions |
| DB | Supabase PostgreSQL | Seoul region available. Free tier: 2 projects, 500MB |
| Auth | Supabase Auth | Kakao, Naver, Google OAuth built-in. No MAU billing on free tier |
| Storage | Supabase Storage | S3-compatible. Direct client uploads via signed URLs |
| Realtime | Supabase Realtime | WebSocket subscriptions. Presence, broadcast, DB changes |
| Cache | Vercel KV | Upstash Redis under the hood. Session, rate limit |
| Cron | Vercel Cron Jobs | Simple scheduled tasks via vercel.json |
| Edge Config | Vercel Edge Config | Ultra-low latency reads. Feature flags, A/B config |
| Error Tracking | Sentry | Same as Cloudflare bundle |
| Analytics | PostHog | Same as Cloudflare bundle |
| Email | Resend | Vercel has no native email service |
| Payments | Stripe / Toss Payments | Same as Cloudflare bundle |
| CI/CD | Vercel Git Integration | Auto-deploy on push. Preview deploys per PR |
| DNS/CDN | Cloudflare → Vercel | Cloudflare DNS proxying to Vercel. Best of both |

### Trade-offs vs Cloudflare

| Aspect | Cloudflare | Vercel |
|---|---|---|
| Edge compute | Workers (global, ~0ms cold start) | Edge Functions (limited runtime) |
| Container compute | CF Containers (native) | None — need Cloud Run escape hatch |
| DB flexibility | Neon (any region) + Hyperdrive | Supabase (Seoul, Virginia, Frankfurt, etc.) |
| Realtime | Durable Objects (custom build) | Supabase Realtime (batteries-included) |
| Auth | Better Auth (custom, flexible) | Supabase Auth (batteries-included, Kakao/Naver) |
| AI services | Workers AI, AI Gateway, Vectorize | None native — use external APIs |
| Pricing model | Pay-per-request, predictable | Function invocations + bandwidth |

---

## Container Escape Hatch: GCP Cloud Run

Use only when neither Workers nor CF Containers meet requirements.

| Trigger | Example |
|---|---|
| GPU access | ML training, Vertex AI integration |
| GCP-specific services | BigQuery, Cloud TPU, Firestore |
| Legacy GCP infrastructure | Existing Cloud SQL, Pub/Sub pipelines |

- **Framework**: Rust/Axum (default) or FastAPI (Python ML only)
- **DB connection**: Neon pooler endpoint (`-pooler` URL) for TCP clients. Keep pool small (`max_connections=5`)
- **Region**: us-east4 (Virginia) for global, asia-northeast3 (Seoul) for Korea-first
- **Scaling**: Horizontal auto-scale, scale-to-zero

---

## Mobile: React Native (Expo)

Include only when the PRD specifies mobile app requirements.

- **Framework**: React Native with Expo (managed workflow)
- **Navigation**: Expo Router (file-based routing, deep linking built-in)
- **Styling**: NativeWind (Tailwind CSS for React Native) or StyleSheet API
- **State**: Same approach as web frontend (TanStack Query for server state)
- **Distribution**: EAS Build + EAS Submit for App Store / Play Store
- **OTA Updates**: EAS Update for instant JS-layer patches without store review

**When to include mobile**: Only when the PRD explicitly requires a native mobile app. A responsive web app (PWA) covers most solopreneur use cases.

**Architecture implication**: Mobile adds a second API consumer. Design the backend API for multiple clients — consistent auth tokens, appropriate payload sizes, offline-friendly patterns.

---

## Shared: Database

Choose based on target audience and bundle:

| Audience | Bundle | Default DB | Region |
|---|---|---|---|
| **Global** | Cloudflare | **Neon** + Hyperdrive | us-east-1 (Virginia) |
| **Korea-first** | Vercel | **Supabase** | ap-northeast-2 (Seoul) |
| **Korea-first** | Cloudflare | **Supabase** via Hyperdrive | ap-northeast-2 (Seoul) |

### Neon — Cloudflare bundle default

- Scale-to-zero pricing, branching for dev/staging, full PostgreSQL (pgvector, extensions)
- **Hyperdrive** handles connection pooling at the edge — no manual pooler config needed for Workers
- For CF Containers or Cloud Run: use Neon pooler endpoint (`-pooler` URL) as TCP fallback

### Supabase — Vercel bundle / Korea-first default

- PostgreSQL on AWS ap-northeast-2 (Seoul) — lowest latency for Korean users
- Bundled: Auth (Kakao/Naver built-in), Realtime, Storage
- Free tier: 2 active projects, 500MB DB, 1GB storage
- Trade-off: no branching (use migrations), less granular scale-to-zero than Neon

---

## Shared: Auth Pattern

### Authentication

Choose based on the product's audience:

| Scenario | Primary Method | Notes |
|---|---|---|
| **Global B2C** | Google OAuth2 + self-issued JWT | Widest reach, lowest friction |
| **Korea B2C** | Kakao OAuth2 (primary) + Naver + Google | Kakao dominates Korean market |
| **B2B / SaaS** | Email magic link or SSO (OIDC/SAML) | Enterprise expects SSO |
| **Internal tools** | Google Workspace OAuth2 | Single-click for team members |

**Implementation by bundle**:
- **Cloudflare**: Better Auth (TS-native, D1/Neon as auth DB, no MAU billing)
- **Vercel**: Supabase Auth (Kakao/Naver built-in, no custom implementation)

**Token strategy** (all scenarios):
- Access token: short-lived (15min), in memory or Authorization header
- Refresh token: long-lived (7-30 days), httpOnly secure cookie

### Authorization
- **Default**: RBAC — sufficient for most apps
- **ABAC**: When permissions depend on resource attributes
- **ReBAC**: When permissions follow relationship graphs (Google Zanzibar pattern)
- **Enforcement**: Middleware layer in backend

---

## Shared: CDN & DNS

Cloudflare DNS + CDN regardless of bundle. Even Vercel bundle uses Cloudflare DNS proxying to Vercel for unified DNS management, DDoS protection, and WAF.

**Edge caching**: Cache static assets aggressively (immutable hashes, 1yr TTL). Use `stale-while-revalidate` for API responses where eventual consistency is acceptable. Never cache authenticated responses at the edge.

---

## Shared: Supporting Services

Cross-bundle services — no native alternative in either platform:

| Service | Choice | Rationale |
|---|---|---|
| Error Tracking | Sentry | Stack traces, issue grouping, alerts. No platform alternative |
| Product Analytics | PostHog | Feature flags, session replay, funnels. Privacy-friendly |
| Payments (Global) | Stripe | Extensive API, webhook reliability |
| Payments (Korea) | Toss Payments | Korean payment methods required |
| CI/CD | GitHub Actions | Test/lint pipeline. Pairs with Workers Builds (CF) or Vercel Git Integration |

---

## Shared: Region Strategy

| Scenario | Cloudflare Bundle | Vercel Bundle |
|---|---|---|
| **Global** | Workers (global) + Neon (Virginia) | Vercel (auto) + Supabase (Virginia) |
| **Korea-first** | Workers (global) + Supabase (Seoul) via Hyperdrive | Vercel (icn1) + Supabase (Seoul) |

**Co-location rule**: Keep compute and database in the same geographic region. For Korea-first, co-locate DB in Seoul. Workers are inherently global — Hyperdrive optimizes the edge-to-DB connection.

---

## Evolution Triggers

When to revisit architecture decisions. Don't optimize prematurely — wait for these signals.

| Signal | Threshold | Action |
|---|---|---|
| DB query latency climbing | p99 > 200ms consistently | Add read replica, review N+1 queries, add caching |
| DB connections exhausting | > 80% pool utilization | Verify Hyperdrive/pooler config, reduce per-instance pool |
| API response time degrading | Exceeding quality targets | Profile hot paths, add caching, async offloading |
| Background job queue growing | Processing delay > 5min | Separate worker, increase concurrency |
| Monthly infra cost spiking | > 2x previous month | Audit usage, check scale-to-zero, review LLM costs |
| Cold starts impacting UX | > 3s first request | Set minimum instances, prewarming, or switch runtime |
| Single service doing too much | > 5 unrelated domain modules | Tighten module boundaries, consider service extraction |
| LLM costs dominating spend | > 40% of total infra | Add model cascading, semantic caching, review prompt lengths |
| Workers CPU limit hit | Regular 50ms+ CPU time | Move hot path to CF Containers or Rust (workers-rs) |

**Rule of thumb**: If you're spending more time operating infrastructure than building product, something needs to change. But don't change it until you feel the pain.
