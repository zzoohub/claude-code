# Stack Templates

Platform bundles optimized for solopreneur development. Each bundle is a cohesive set of compute, storage, and services from the same ecosystem — unified billing, single CLI, one dashboard.

---

## Bundle Selection

Choose one bundle per project. Backend framework choice is independent of bundle.

| Bundle | Compute | Frontend | DB | Choose When |
|---|---|---|---|---|
| **Cloudflare** (default) | Workers + CF Containers | TanStack Start (React) | Neon + Hyperdrive | Edge-first, global low-latency, TS fullstack, unified CF infra |
| **Vercel** | Vercel Functions | TanStack Start (React) / SvelteKit | Supabase | Content-heavy, Korea-first (Supabase Seoul) |

**GCP Cloud Run** = escape hatch when CF Containers can't do it (GPU, Vertex AI, GCP-only integrations).

If the user doesn't specify, use the **Cloudflare bundle**.

### Bundle Decision Flow

```
Project characteristics?
├── Edge-first, API-heavy, TS fullstack     → Cloudflare bundle
├── Content/SEO-heavy, Supabase needed       → Vercel bundle
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

Frontend choice is independent of backend bundle. Pick based on team expertise and project needs.

| Frontend | Deploy To | Choose When |
|---|---|---|
| **TanStack Start (React)** | CF Workers / Vercel / Node.js | Full-stack React framework with SSR/SSG, type-safe server functions, file-based routing. Default choice — React ecosystem + TanStack Router's type-safe navigation |
| **TanStack Start (SolidJS)** | CF Workers / Vercel / Node.js | Fine-grained reactivity, minimal bundles, same TanStack Start primitives. Choose when bundle size and runtime performance are priorities |
| **SvelteKit** | CF Workers / Vercel / Node.js | Compiler-first, minimal JS shipped, built-in SSR/SSG. Strong DX with runes reactivity. Choose when simplicity and performance are priorities |
| **Astro** | CF Workers adapter | Content-first, Islands architecture. Blog/marketing/docs pages |

**Default guidance**: If unsure, **TanStack Start (React)** is the default choice — React ecosystem benefits (component libraries, talent pool, tutorials) with type-safe routing and server functions. Choose **TanStack Start (SolidJS)** or **SvelteKit** when fine-grained reactivity and minimal bundle size are meaningful differentiators. Both deploy to Workers, Vercel, or Node.js without shims.

---

## Monorepo Structure

Solopreneur projects use a **monorepo always** — one repo, multiple packages. Keeps deployment simple, enables code sharing, and avoids cross-repo dependency hell.

### Bun Workspaces

Use **bun workspaces** for package linking. No Turborepo or Nx — they add build orchestration overhead that a solo developer doesn't need. Bun's native workspace support handles dependency resolution and linking.

```jsonc
// package.json (root)
{
  "private": true,
  "workspaces": ["packages/*"]
}
```

**Typical structure**:
```
project/
├── package.json              # root — workspaces config
├── packages/
│   ├── api/                  # Hono backend (Workers)
│   │   ├── package.json
│   │   ├── wrangler.jsonc
│   │   └── src/
│   ├── web/                  # TanStack Start (React/SolidJS) or SvelteKit
│   │   ├── package.json
│   │   └── src/
│   └── shared/               # Shared types, utils, validation schemas
│       ├── package.json
│       └── src/
```

**Cross-package imports**: Reference workspace packages by name in `package.json` dependencies:
```jsonc
// packages/web/package.json
{
  "dependencies": {
    "@project/shared": "workspace:*",
    "@project/api": "workspace:*"    // for Hono RPC client type
  }
}
```

**Wrangler runs on Node, not Bun**: Wrangler uses Node-specific APIs internally. Run `npx wrangler` (or `bunx wrangler`) — both invoke Node. Don't `bun run wrangler` directly. All other scripts (`bun test`, `bun run dev`) work with Bun.

### Hono RPC (End-to-End Type Safety)

Hono RPC provides type-safe API calls between backend and frontend without code generation. The backend exports its `AppType`, and the frontend uses `hc<AppType>()` to get a fully typed client.

**Backend** — export the app type:
```typescript
// packages/api/src/index.ts
const app = new Hono()
  .get('/users/:id', async (c) => {
    const user = await getUser(c.req.param('id'));
    return c.json(user);
  })
  .post('/users', zValidator('json', createUserSchema), async (c) => {
    const data = c.req.valid('json');
    return c.json(await createUser(data), 201);
  });

export type AppType = typeof app;
```

**Frontend** — import the type, get autocomplete:
```typescript
// packages/web/src/api.ts
import { hc } from 'hono/client';
import type { AppType } from '@project/api';

const client = hc<AppType>('https://api.example.com');

// Fully typed — route params, request body, response shape
const user = await client.users[':id'].$get({ param: { id: '123' } });
const created = await client.users.$post({ json: { name: 'Alice' } });
```

**Why this matters**: No OpenAPI spec generation, no codegen step, no drift between backend and frontend types. Changes to API routes produce instant TypeScript errors in the frontend. This is the primary reason to use Hono over other frameworks in a monorepo.

**Limitation**: Hono RPC only works when both backend and frontend are TypeScript in the same monorepo. For mobile (React Native) or external consumers, expose a standard REST API alongside RPC.

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

For Supabase projects. Korea-first or content-heavy products.

### Why This Bundle Exists
- Supabase Seoul region — lowest latency for Korean users
- Supabase Realtime — chat, notifications, live updates bundled
- Vercel Functions — simple serverless compute with good DX
- Better Auth handles auth the same way as CF bundle — unified auth experience

### Stack

| Role | Service | Notes |
|---|---|---|
| Compute | Vercel Functions | Serverless (Node.js) + Edge Runtime |
| Frontend | TanStack Start (React) / SvelteKit | SSR/SSG, type-safe routing, server functions |
| DB | Supabase PostgreSQL | Seoul region available. Free tier: 2 projects, 500MB |
| Auth | Better Auth | TS-native, stores in Supabase DB. Kakao, Naver, Google via plugins. No MAU billing |
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
| Auth | Better Auth (unified across bundles) | Better Auth (same — unified) |
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
- Bundled: Realtime, Storage (use Better Auth for auth — unified across bundles)
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
| **B2B / SaaS** | Email magic link | Keep it simple for solopreneur B2B |
| **Internal tools** | Google Workspace OAuth2 | Single-click for team members |

**Implementation**: **Better Auth** (TS-native) for all bundles and scenarios. Open-source, no MAU billing, stores auth data directly in your DB (Neon/D1). Supports social providers (Google, Kakao, Naver, GitHub, etc.) via plugins. Runs on the frontend server (TanStack Start / SvelteKit) — no separate auth service needed.

**Exception**: For Rust container backends without a TS frontend server, use **Clerk** (managed, HTTP API) or implement auth directly with the provider's OAuth2 flow + JWT verification.

**Token strategy** (all scenarios):
- Access token: short-lived (15min), in memory or Authorization header
- Refresh token: long-lived (7-30 days), httpOnly secure cookie
- **Refresh token rotation (required)**: issue a new refresh token on every use, revoke the old one immediately. Store `jti` + `revokedAt` in DB. Without rotation, a stolen refresh token is usable for its entire lifetime. On logout, revoke all active tokens for the user.

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
| Observability | Axiom | Unified logs, traces, metrics across all projects. Logpush + OTLP ingestion. Free 500GB/mo |
| Uptime Monitoring | BetterStack | External health checks, status page, incident management. Free tier: 10 monitors |
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
