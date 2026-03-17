# Tech Stack

## Language

| Role | Options |
|---|---|
| Language | TypeScript, Rust, Python |

---

## Framework

| Role | Options |
|---|---|
| Server (Workers) | Hono, workers-rs |
| Server (Container) | Axum, FastAPI |
| Frontend | TanStack Start (React or Solid), Next.js |
| Mobile | React Native (Expo) + Expo Router + EAS |
| Desktop | Tauri |
| CLI | Rust |
| Game | Godot, Bevy |
| Data Pipeline | Cloudflare Pipelines, Cloud Dataflow, dbt |

---

## Infrastructure

| Role | Options |
|---|---|
| Edge API | Workers, Cloud Run |
| Stateful / WebSocket | Durable Objects, Cloud Run |
| Async workflows | Workflows + Queues, Cloud Tasks + Pub/Sub |
| Container | CF Containers, Cloud Run |
| Cron | Cron Triggers, Cloud Scheduler |
| Multi-tenant | Workers for Platforms |
| DNS + CDN | Cloudflare, Cloud CDN + Cloud DNS |
| CI/CD | GitHub Actions + Workers Builds |
| Config | Wrangler, Pulumi |
| Secrets | Worker Secrets / Secrets Store, Secret Manager |
| Zero Trust | CF Zero Trust + Workers VPC |

---

## Data

| Role | Options |
|---|---|
| Postgres (global) | Neon + Hyperdrive |
| Postgres (Korea) | Supabase + Hyperdrive, Cloud SQL |
| SQLite | D1, Turso |
| Cache (eventual) | KV |
| Cache (strong) | Upstash Redis |
| Queue | CF Queues, Cloud Tasks |
| Streaming | Upstash Kafka, Cloud Pub/Sub |
| Objects | R2 |
| Analytics / DW | BigQuery, Pipelines + R2 SQL |
| Vector | Vectorize, pgvector on Supabase/Neon |
| Images | CF Images |
| Video | CF Stream + Media Transforms |

---

## AI

| Role | Options |
|---|---|
| LLM inference | Workers AI, Vertex AI |
| Gateway | AI Gateway |
| RAG | Vectorize, AutoRAG |
| Security | Firewall for AI, AI Gateway DLP |
| Crawlers | AI Crawl Control, Firecrawl |
| Browser | Browser Rendering, Playwright (CF Containers) |
| Agent (Workers) | CF Agents SDK |
| Agent (Python)  | PydanticAI, LangGraph |
| Agent (durable) | CF Workflows + PydanticAI or LangGraph |
| Agent (protocol) | MCP on Workers |

---

## External Services

| Role | Options |
|---|---|
| Auth | Better Auth, Clerk, OAuth2 + JWT |
| Social (global) | Google |
| Social (Korea) | Google, Kakao |
| Payments (global) | Stripe |
| Payments (Korea) | Toss Payments |
| Email (transactional) | Resend |
| Email (notification) | Resend, CF Email Service |
| Errors | Sentry |
| Tracing + Logging | Axiom, CF Workers Logpush |
| Uptime | BetterStack |
| Analytics | PostHog |
| Feature flags | KV + PostHog |
