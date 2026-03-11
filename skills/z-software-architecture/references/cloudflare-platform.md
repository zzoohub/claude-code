# Cloudflare Platform Reference

Detailed tech stack for the Cloudflare bundle. Priority: ① = default, ② = situational alternative, ③ = last resort. Origin: CF = Cloudflare native, External = third-party.

Read this when designing a system on the Cloudflare bundle. For bundle selection logic, see `stack-templates.md`.

---

## Language / Framework

| Role | Pri | Service | Notes |
|---|---|---|---|
| Language | ① | TypeScript | Default for all web services. Type consistency across Workers, Hono, Drizzle |
| Language | ② | Rust | CPU-intensive or memory-safety-critical. workers-rs + Axum for Workers deploy |
| Client (fullstack) | ① | TanStack Start + SolidJS (External) | Fine-grained reactivity, minimal bundles, Workers binding friendly |
| Client (content-first) | ① | Astro (External) | Islands architecture, static-first. Blog/marketing pages. CF Workers adapter native |
| Client (React ecosystem) | ③ | Next.js (External) | Max ecosystem. OpenNext for Workers deploy — overhead vs CF-native options |
| Server (Workers) | ① | Hono TS (CF) | <4kB, middleware chaining, RPC, Workers-first |
| Server (Workers) | ② | workers-rs + Axum (CF) | CPU-intensive API/parsing. Memory safety required |
| Server (Container) | ① | Rust/Axum | Minimal cold start. Default for CF Containers |
| Server (Container) | ② | FastAPI Python | Only when ML libraries (torch, transformers) required |

---

## Compute

| Role | Pri | Service | Notes |
|---|---|---|---|
| Edge compute / API | ① | Workers JS/TS · Rust (CF) | Stateless isolate, 330+ PoP, ~0ms cold start |
| Stateful long-running | ① | Durable Objects (CF) | Global singleton, WebSocket hub, strong consistency, built-in KV storage |
| Async workflows | ① | Workflows + Queues (CF) | Auto-retry, checkpoint, sleep. Temporal-like model. DLQ, schedule triggers |
| Agent (Workers) | ① | Agents SDK (CF) | DO-based. State, memory, MCP tool calls, schedule. Short tool-calling, realtime response |
| Agent (long-running) | ① | LangGraph.js on CF Containers (CF+External) | Multi-step pipelines, heavy reasoning, 10+ min. Node.js container |
| Agent (long-running) | ② | LangGraph.js on Cloud Run (External) | Fallback if CF Containers insufficient |
| Container (long-running) | ① | CF Containers + Rust/Axum (CF) | 16vCPU/64GB RAM, sleep/wake cycle. Minimal cold start |
| Container (long-running) | ② | CF Containers + Python/FastAPI (CF) | ML library dependency only |
| Container (long-running) | ③ | Cloud Run (External) | Escape hatch: GPU, GCP-locked, CF Containers immaturity |

### Compute Decision Flow

```
Request type?
├── Stateless API, <30s           → Workers (Hono or workers-rs)
├── Stateful, WebSocket, coord    → Durable Objects
├── Async, retry, multi-step      → Workflows + Queues
├── Agent, short tool-calling     → Agents SDK
├── Agent, long-running/complex   → LangGraph.js on CF Containers
├── Container, CPU/memory heavy   → CF Containers (Rust or Python)
└── GPU, Vertex AI, GCP-locked    → Cloud Run (escape hatch)
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
| Auth | ① | Better Auth (External) | TS-native, D1/Neon as auth DB directly. No MAU billing |
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
| Auto tracing | ① | Workers Automatic Tracing (CF) | Zero-code OTel spans for KV, DO, R2, D1, fetch |
| Realtime log query | ① | Log Explorer (CF) | Dashboard realtime search/forensics. No external tool for quick debugging |
| Distributed tracing | ① | Honeycomb (External) | OTLP export, high-cardinality query, trace UI. Add when Automatic Tracing isn't enough |
| Log long-term storage | ① | Logpush → R2 → R2 SQL (CF) | Structured logs → Parquet → SQL. 90+ day cost-efficient retention |
| Error tracking | ① | Sentry (External) | Stack traces, issue grouping, alerts. No CF alternative |
| Feature flags | ① | KV + PostHog (CF+External) | KV TTL cache for 0ms edge evaluation. PostHog for flag management + analytics |
| Product analytics | ① | PostHog (External) | Event tracking, session replay, user journey analysis. No CF alternative |

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
