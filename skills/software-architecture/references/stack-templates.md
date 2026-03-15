# Stack Templates

Cloudflare-first stack for solopreneur development. Unified billing, single CLI, one dashboard.

---

## Platform

All projects run on the **Cloudflare bundle**. No bundle selection needed.

| Compute | Frontend | DB | Escape Hatch |
|---|---|---|---|
| Workers + CF Containers | TanStack Start (React or SolidJS) | Neon + Hyperdrive (global) / Supabase (Korea-first) | GCP Cloud Run (GPU, GCP-locked) |

See **`references/cloudflare-platform.md`** for the full tech stack reference with ①② priority rankings per role.

See **`references/cloudflare-platform.md`** for the full service catalog with ①② priority rankings, and **`references/operational-patterns.md`** for background jobs, retry, and async pipeline patterns.

---

## Backend Framework

| Framework | Runtime | Choose When |
|---|---|---|
| **Hono (TS)** | Workers (edge API) | Default. All web services, API, fullstack TS. <4kB, RPC built-in |
| **Rust/Axum** | CF Containers / Cloud Run | Compute containers. CPU-intensive, memory safety, maximum performance |

> **Escape hatch**: FastAPI (Python) on CF Containers or Cloud Run — only when Python-only ML libraries (PyTorch, transformers) are physically required. LLM API calls alone do NOT justify Python.

### TypeScript Ecosystem (Default)
- **Web framework**: Hono (Workers-first, <4kB, middleware chaining)
- **ORM/Query**: Drizzle ORM (type-safe, lightweight, Workers-compatible)
- **Validation**: Zod (integrated with Hono via `@hono/zod-validator`)
- **HTTP client**: Native `fetch` (Workers environment)
- **RPC**: Hono RPC (end-to-end type safety between backend and frontend)

### Rust Ecosystem (Container / CPU-intensive)
- **Web**: Axum (tower-based, async)
- **ORM/Query**: SQLx (compile-time checking) or SeaORM
- **Serialization**: serde + serde_json
- **Async runtime**: Tokio
- **HTTP client**: reqwest
- **Validation**: validator

---

## Frontend

| Frontend | Deploy To | Choose When |
|---|---|---|
| **TanStack Start (React)** | CF Workers / Node.js | Default. React ecosystem + TanStack Router's type-safe navigation + server functions |
| **TanStack Start (SolidJS)** | CF Workers / Node.js | Fine-grained reactivity, minimal bundles, same TanStack Start primitives. Choose when bundle size and runtime performance are priorities |

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
│   ├── web/                  # TanStack Start (React or SolidJS)
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

## Container Runtime

| Runtime | Choose When |
|---|---|
| **CF Containers** | Default. CF ecosystem, unified billing, sleep/wake cycle. No GPU |
| **Cloud Run** | GPU needed, GCP services (BigQuery, Pub/Sub), existing GCP infra |

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

## Database

Choose based on target audience:

| Audience | Default DB | Region |
|---|---|---|
| **Global** | **Neon** + Hyperdrive | us-east-1 (Virginia) |
| **Korea-first** | **Supabase** (via Hyperdrive) | ap-northeast-2 (Seoul) |

### Neon — Global default

- Scale-to-zero pricing, branching for dev/staging, full PostgreSQL (pgvector, extensions)
- **Hyperdrive** handles connection pooling at the edge — no manual pooler config needed for Workers
- For CF Containers or Cloud Run: use Neon pooler endpoint (`-pooler` URL) as TCP fallback

### Supabase — Korea-first default

- PostgreSQL on AWS ap-northeast-2 (Seoul) — lowest latency for Korean users
- Bundled: Realtime, Storage (use Better Auth for auth)
- Free tier: 2 active projects, 500MB DB, 1GB storage
- Trade-off: no branching (use migrations), less granular scale-to-zero than Neon

---

## Auth Pattern

### Authentication

Choose based on the product's audience:

| Scenario | Primary Method | Notes |
|---|---|---|
| **Global B2C** | Google OAuth2 + self-issued JWT | Widest reach, lowest friction |
| **Korea B2C** | Kakao OAuth2 (primary) + Naver + Google | Kakao dominates Korean market |
| **B2B / SaaS** | Email magic link | Keep it simple for solopreneur B2B |
| **Internal tools** | Google Workspace OAuth2 | Single-click for team members |

**Implementation**: **Better Auth** (TS-native). Open-source, no MAU billing, stores auth data directly in your DB (Neon/D1). Supports social providers (Google, Kakao, Naver, GitHub, etc.) via plugins. Runs on the frontend server (TanStack Start) — no separate auth service needed.

**Exception**: For Rust container backends without a TS frontend server, use **Clerk** (managed, HTTP API) or implement auth directly with the provider's OAuth2 flow + JWT verification.

**Token strategy** (all scenarios):
- Access token: short-lived (15min), in memory or Authorization header
- Refresh token: long-lived, httpOnly secure cookie — 90 days (web), 1 year (mobile)
- **Refresh token rotation (required)**: issue a new refresh token on every use, revoke the old one immediately. Store `jti` + `revokedAt` in DB. Without rotation, a stolen refresh token is usable for its entire lifetime. On logout, revoke all active tokens for the user.

### Authorization
- **Default**: RBAC — sufficient for most apps
- **ABAC**: When permissions depend on resource attributes
- **ReBAC**: When permissions follow relationship graphs (Google Zanzibar pattern)
- **Enforcement**: Middleware layer in backend

---

## CDN & DNS

Cloudflare DNS + CDN for all projects. Unified DNS management, DDoS protection, and WAF.

**Edge caching**: Cache static assets aggressively (immutable hashes, 1yr TTL). Use `stale-while-revalidate` for API responses where eventual consistency is acceptable. Never cache authenticated responses at the edge.

---

## Supporting Services

| Service | Choice | Rationale |
|---|---|---|
| Error Tracking | Sentry | Stack traces, issue grouping, alerts. No platform alternative |
| Observability | Axiom | Unified logs, traces, metrics across all projects. Logpush + OTLP ingestion. Free 500GB/mo |
| Uptime Monitoring | BetterStack | External health checks, status page, incident management. Free tier: 10 monitors |
| Product Analytics | PostHog | Feature flags, session replay, funnels. Privacy-friendly |
| Payments (Global) | Stripe | Extensive API, webhook reliability |
| Payments (Korea) | Toss Payments | Korean payment methods required |
| CI/CD | GitHub Actions + Workers Builds | Test/lint pipeline + auto-deploy |

---

## Region Strategy

| Scenario | Strategy |
|---|---|
| **Global** | Workers (global) + Neon (Virginia) |
| **Korea-first** | Workers (global) + Supabase (Seoul) via Hyperdrive |

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
