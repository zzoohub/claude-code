# Backend Architecture Decision Framework

Architecture decisions happen on **two axes**: system architecture and language.

| Axis | Question | Options |
|---|---|---|
| **System Architecture** | How do services/components communicate? | Request-Response, Event-Driven, CQRS, Event Sourcing, Hybrid |
| **Language** | What language/framework? | Rust (Axum) default, Python (FastAPI) when Python-only libraries required |

**Code structure is always Hexagonal (Ports & Adapters).** AI-assisted development eliminates the boilerplate cost that previously made hexagonal feel heavy for simple services. The benefits (testability, swappable adapters, clean domain isolation) apply universally.

---

## Axis 1: System Architecture Patterns

### Request-Response (Synchronous)

The default. Service A calls Service B, waits for the answer, continues.

```
Client → API Gateway → Service A → Service B → DB
                                 ← response ←
```

**Strengths**: Simple to reason about, easy to debug, straightforward error handling, strong consistency natural.
**Trade-offs**: Temporal coupling (caller blocks), cascading failures, harder to scale independently.
**Choose when**: CRUD-dominant apps, simple data flows, small number of services, strong consistency required everywhere.

**Who uses it**: Most startups, early-stage products. Stripe's core payment flow is synchronous by design — money movement needs strong consistency.

**Our stack**: Cloud Run + Neon. No additional infra needed. This is the default.

### Event-Driven Architecture (EDA)

Services communicate by producing and consuming events asynchronously. No service waits for another.

```
Service A ──publishes──▶ Event Broker ──delivers──▶ Service B
                        (Kafka/NATS)  ──delivers──▶ Service C
```

**Strengths**: Loose coupling, services scale independently, natural fault isolation, excellent for fan-out (one event → many consumers), handles traffic spikes via buffering.
**Trade-offs**: Eventual consistency, harder to debug (distributed tracing essential), event ordering complexity, requires message broker infrastructure.
**Choose when**: Multiple consumers need to react to the same event, traffic is spiky, you need async processing (notifications, analytics, ML pipelines), or services must evolve independently.

**Who uses it**:
- **Netflix**: Kafka processes trillions of events/day — playback telemetry, recommendations, A/B test results, analytics all flow as events. Individual services react asynchronously.
- **Uber**: Real-time pricing, fraud detection, trip state management all event-driven via Kafka + Flink. Exactly-once semantics for financial accuracy.
- **Slack**: Message delivery, indexing, and notifications propagated as events through Kafka. Events carry full metadata so consumers don't need to query the producer.

**Our stack**: Cloud Run + Neon + **GCP Pub/Sub**. Pub/Sub is serverless, auto-scales, integrates natively with Cloud Run (push subscriptions), and is pay-per-use. Kafka is overkill until you're processing millions of events/sec with complex stream processing needs. For CDC from Neon, enable logical replication + wal2json.

### CQRS (Command Query Responsibility Segregation)

Separate the write model (commands that change state) from the read model (queries that return data). Each can be independently optimized.

```
             ┌── Command Model ──▶ Write DB (normalized)
User Input ──┤                         │
             │                    sync/async projection
             │                         ▼
             └── Query Model  ◀── Read DB (denormalized, optimized)
```

**Strengths**: Read and write sides scale independently, read models optimized per use case (different views of same data), natural fit for read-heavy systems.
**Trade-offs**: Increased complexity (two models to maintain), eventual consistency between read and write sides, more infrastructure.
**Choose when**: Read/write ratio is heavily skewed (10:1+), different consumers need different views of the same data, or you need to optimize read performance without compromising write consistency.

**Who uses it**:
- **Netflix**: Personalization system — writes capture viewing events, reads serve pre-computed recommendation lists optimized per device type.
- Financial systems where audit trails (write side) and reporting dashboards (read side) have completely different performance characteristics.

**Our stack**: Cloud Run + Neon (write) + **Neon read replica** (read, denormalized views). For heavier read optimization, project from Neon via logical replication to a separate read-optimized store. Upgrade path: AlloyDB for OLTP+OLAP hybrid if Neon read replicas become insufficient.

### Event Sourcing

Instead of storing current state, store the sequence of events that led to the current state. State is derived by replaying events.

```
Event Store: [OrderCreated] → [ItemAdded] → [PaymentProcessed] → [Shipped]
Current state = replay all events (or read from snapshot + recent events)
```

**Strengths**: Complete audit trail for free, time-travel debugging (reconstruct state at any point), natural fit for domains where history matters.
**Trade-offs**: Complexity spike (snapshots needed for performance, schema evolution is hard, querying current state requires projections), high learning curve, significantly more infrastructure.
**Choose when**: Audit trail is a regulatory requirement, the domain is inherently event-based (finance, logistics, collaborative editing), or you need time-travel/undo capabilities.

**Who uses it**:
- **Stripe**: Payment state transitions stored as events — enables dispute resolution, audit compliance, and exact state reconstruction for debugging.
- Banking and fintech where every state change must be auditable and reversible.

**Warning**: Event sourcing is powerful but adds substantial complexity. Don't adopt it just because it sounds elegant. Most applications are better served by EDA + a good audit log table.

**Our stack**: Cloud Run + Neon (append-only event tables + snapshot tables) + **Pub/Sub** (event projection/fan-out). Neon's logical replication supports CDC to stream events to downstream consumers. For "event sourcing lite" (audit trail + state reconstruction), Neon alone is sufficient. Upgrade path: GCP Managed Kafka if you need long-term event retention with replay and complex stream processing.

### Saga Pattern (Distributed Transactions)

Coordinates multi-service transactions through a sequence of local transactions, each publishing events for the next step. If a step fails, compensating transactions undo previous steps.

```
Order Service ──▶ Payment Service ──▶ Inventory Service
    │                  │                     │
    ◀── compensate ◀── compensate ◀─── (on failure)
```

**Two variants**:
- **Choreography**: Each service listens for events and knows what to do next. Simpler but harder to track overall flow.
- **Orchestration**: A central coordinator tells each service what to do. More explicit control but introduces a single point of coordination.

**Choose when**: You have distributed transactions across multiple services that need to be eventually consistent. Alternative: if you can avoid distributed transactions by keeping data in one service, always prefer that.

**Who uses it**:
- **Uber**: Trip lifecycle (match rider → assign driver → process payment → rate) is an orchestrated saga.
- Any e-commerce checkout flow that spans order, payment, and inventory services.

**Our stack**: Cloud Run services + **Pub/Sub** (choreography) or **Cloud Tasks** (orchestration with retries/delays). For simple sequential sagas, Cloud Tasks is lighter than Pub/Sub. For fan-out sagas, Pub/Sub.

### Modular Monolith

One deployable unit, but internally organized into strictly isolated modules with clear boundaries. Modules communicate through well-defined interfaces (function calls, internal events), not direct database access.

```
┌─────────────────────────────────────────┐
│              Single Deployment           │
│  ┌──────┐  ┌──────┐  ┌──────┐          │
│  │ Auth │  │Orders│  │Notify│          │
│  │Module│  │Module│  │Module│          │
│  └──┬───┘  └──┬───┘  └──┬───┘          │
│     └────internal API────┘               │
│              Shared DB (schema-separated) │
└─────────────────────────────────────────┘
```

**Strengths**: Simple deployment and ops, no network overhead between modules, easy local development, can extract to microservices later if needed.
**Trade-offs**: Must enforce module boundaries with discipline (easy to cheat), scales as a whole unit, shared database can become a coupling point.
**Choose when**: Small team (1-5 engineers), you want domain separation without microservice overhead, or you're at a stage where operational simplicity matters more than independent scaling.

**Who uses it**:
- **Toss** (Korean fintech): Modular monolith with clear module boundaries — team autonomy without microservice operational overhead. Proven at massive scale in Korean market.
- **Shopify**: Started as a monolith, evolved to modular monolith before selective extraction to services.

**Our stack**: Cloud Run (single service) + Neon. No additional infra. Internal module communication is in-process function calls or in-app event bus. This is the simplest and cheapest configuration.

---

## Code Structure: Hexagonal (Default)

The default code structure is **Hexagonal Architecture (Ports & Adapters)**. Choose it unless you have a specific reason not to.

```
         ┌─────────────────────────────────────┐
         │            Application               │
         │  ┌───────────────────────────────┐   │
Driving  │  │                               │   │  Driven
Adapters │  │     Domain / Business Logic    │   │  Adapters
(HTTP,   │──│                               │──▶│  (DB, Queue,
CLI,     │  │     (Pure, no dependencies)    │   │   External
Events)  │  │                               │   │   APIs)
         │  └───────────────────────────────┘   │
         │         Ports (Interfaces)           │
         └─────────────────────────────────────┘
```

**Why hexagonal by default**: AI-assisted development generates boilerplate instantly — the traditional cost of hexagonal (more files, more wiring) is near-zero. The benefits remain: domain isolation, swappable adapters, pure domain unit tests, and no refactoring needed when complexity grows.

**Dependencies always point inward.** Domain code never imports framework or infrastructure code.

**When to deviate**:
- **Simple CRUD with no business logic** (admin dashboards, internal tools): Framework conventions or layered architecture may be simpler. The overhead of ports/adapters adds indirection without meaningful domain isolation if there's no domain to isolate.
- **Vertical Slice Architecture**: Organize by feature instead of by layer. Each feature owns its full stack (handler → logic → data access). Works well with CQRS where each command/query is a self-contained slice.
- **Team already uses Clean Architecture**: Clean Architecture (Uncle Bob) shares the same core principle (dependency inversion, domain at center). The difference is naming and layer organization, not philosophy. Don't force a migration — the benefits are equivalent.

Document your code structure choice as an ADR with rationale.

---

## Language Selection

| Priority | Language | When to Use |
|---|---|---|
| **Default** | **Rust (Axum)** | All services unless Python-only libraries are required. Sub-ms response times, 10-30MB memory, near-zero cold starts. Compiler as second reviewer — if it compiles, entire error classes are eliminated. Lower cloud cost (critical for solopreneur economics). |
| **Exception** | **Python (FastAPI)** | Only when Python-only libraries are physically required: PyTorch, transformers, pandas/numpy heavy pipelines, or SDKs with no Rust equivalent. LLM API calls and agent patterns do NOT require Python -- implement with `reqwest` + `serde` in Rust. LangGraph is justified only when its graph orchestration + LangSmith debugging provide clear value over a Rust implementation. |

### Rust Ecosystem (Recommended)
- **Web**: Axum (tower-based, async)
- **ORM/Query**: SQLx (compile-time checking) or SeaORM
- **Serialization**: serde + serde_json
- **Async runtime**: Tokio
- **HTTP client**: reqwest
- **Validation**: validator
- **Config**: config + envy

### Python (FastAPI) Ecosystem (Recommended)
- **ORM**: SQLAlchemy 2.0 (async) + Alembic
- **Validation**: Pydantic v2 (built into FastAPI)
- **HTTP client**: httpx (async)
- **Task queue**: Celery or ARQ (lightweight, Redis-based)
- **Testing**: pytest + pytest-asyncio + httpx

---

## Composition Decision Flowchart

```
Step 1: System Architecture
─────────────────────────
Is this a single-purpose service or product?
├── YES → Modular Monolith or Single Service
│         Does it need async processing (notifications, analytics, ML)?
│         ├── YES → Add event-driven for those flows (Hybrid)
│         └── NO  → Request-Response is fine
└── NO (multiple services) →
    Do services need to react to shared events?
    ├── YES → Event-Driven (with Saga for distributed transactions)
    └── NO  → Request-Response between services

    Is read/write ratio heavily skewed (10:1+)?
    ├── YES → Consider CQRS for read-heavy paths
    └── NO  → Standard data access

    Is full audit trail / state history a hard requirement?
    ├── YES → Event Sourcing for that domain
    └── NO  → Don't add it

Step 2: Language (Code structure is always Hexagonal)
─────────────────────────────────────────────────────
Are Python-only libraries required? (LangGraph, PyTorch, transformers, etc.)
├── YES → Python (FastAPI) + Hexagonal
└── NO  → Rust (Axum) + Hexagonal

Note: LLM API calls and agent patterns do NOT require Python.
Use Rust with reqwest + serde for LLM integration and custom agent loops.
```

---

## Real-World Architecture Compositions

| Company | System Architecture | Code Structure | Key Insight |
|---|---|---|---|
| **Netflix** | Microservices + Event-Driven (Kafka, trillions of events/day) + CQRS (personalization) | Hexagonal internally per service (DGS pattern) | Not one pattern — different patterns per domain. Playback is sync; analytics is event-driven; recommendations use CQRS. |
| **Uber** | Microservices organized by domain (DOMA) + Event-Driven (Kafka + Flink) + Saga (trip lifecycle) | Domain-driven internally | Organize services by business domain, not technical layer. Orchestrated sagas for multi-service transactions. |
| **Stripe** | SOA + Event Sourcing (payment state) + Request-Response (API surface) | Clean/hexagonal per service | Synchronous API surface, event-sourced internals for audit. Design docs before code. |
| **Toss** | Modular Monolith + Event-Driven (inter-module) | Clean Architecture per module | Massive Korean fintech — modular monolith proven at scale. Team autonomy without microservice overhead. |
| **Discord** | Microservices + hybrid sync/async | Rust for hot paths (Read States), Elixir for real-time | Migrated Go → Rust for 10x perf. Choose language per service based on performance profile. |
| **Shopify** | Modular Monolith → selective extraction | Rails conventions | Start monolithic, extract only when data proves the boundary. Premature decomposition = distributed monolith. |
| **Airbnb** | Monolith → SOA by domain boundary | Service-specific | Split only when natural domain boundaries are clear. |

---

## Additional Patterns

### Strangler Fig (Legacy Migration)

Incrementally replace a legacy system by routing traffic through a facade that delegates to either old or new code per feature. Over time, the new system takes over completely.

```
Client --> Facade/Router
             |-- /new-feature --> New Service
             |-- /old-feature --> Legacy System
             (gradually migrate routes from legacy to new)
```

**Strengths**: Zero big-bang risk, ship incremental value, old system keeps running during migration.
**Trade-offs**: Facade adds complexity and latency, two systems to maintain in parallel, data synchronization between old and new can be tricky.
**Choose when**: Replacing an existing system that can't be rewritten from scratch. This is almost always the right approach for legacy migration — big-bang rewrites have a high failure rate.

**Who uses it**: Shopify (monolith extraction), Amazon (from monolith to SOA), Airbnb (SOA migration by domain boundary).

**Our stack**: Cloudflare Workers as the routing facade (path-based routing to Cloud Run services). Or within a modular monolith, use feature flags to switch between old and new module implementations.

### Backend-for-Frontend (BFF)

A dedicated backend service per frontend client type. Each BFF aggregates, transforms, and serves data in the shape its client needs.

```
Web App    --> Web BFF    --> Backend Services
Mobile App --> Mobile BFF --> Backend Services
```

**Strengths**: Each client gets an API tailored to its needs (different payload sizes, different data requirements), frontend teams can iterate independently.
**Trade-offs**: Code duplication across BFFs, more services to maintain.
**Choose when**: Web and mobile clients have significantly different data needs, or you want to decouple frontend release cycles from backend.

**Who uses it**: Netflix (per-device BFFs), SoundCloud (pioneered the pattern), Spotify.

**Our stack**: For most products, a single API with response field selection (sparse fieldsets or GraphQL) is simpler than maintaining separate BFFs. Consider BFF only when the divergence between clients is substantial.

### Cell-based Architecture

Partition the system into independent, self-contained cells. Each cell serves a subset of users/tenants and contains a full copy of the service stack. A failure in one cell doesn't affect others.

```
┌─── Cell A (users 1-1000) ───┐  ┌─── Cell B (users 1001-2000) ──┐
│  API → Service → DB          │  │  API → Service → DB            │
└──────────────────────────────┘  └────────────────────────────────┘
         Router / Cell Gateway
```

**Strengths**: Blast radius limited to one cell, scales horizontally by adding cells, each cell can be independently deployed and version-tested.
**Trade-offs**: Data isolation means cross-cell queries are hard, cell routing adds complexity, operational overhead of managing many cells.
**Choose when**: You need to limit blast radius (regulatory or high-availability requirements), or you're at a scale where a single deployment unit is a risk.

**Who uses it**: AWS (all major services are cell-based internally), DoorDash, Slack.

**Our stack**: Overkill for most single-product systems. Consider when your system grows to multi-tenant with strict isolation requirements or SLA commitments that demand blast radius containment.

### Event Lakehouse

Replace traditional data warehouses with an object-storage-native analytics pipeline. Events flow through a queue, are transformed into columnar format (Parquet/Iceberg), and queried in-place with a serverless SQL engine.

```
App events → Queue/Stream → Transform → Object Storage (Parquet/Iceberg) → SQL Engine
                                              ↓
                                        Dashboard / BI tool
```

**Strengths**: Pay-per-query (no always-on warehouse), storage and compute scale independently, open formats (no vendor lock-in), same pipeline handles both operational analytics and data science.
**Trade-offs**: Query latency higher than a dedicated warehouse (seconds, not milliseconds). Not for real-time dashboards.
**Choose when**: You need analytics beyond what PostHog provides, data volume grows past what a Postgres materialized view handles comfortably, or you want a unified data lake for multiple consumers.

**Our stack**: CF Pipelines + R2 (Parquet/Iceberg via R2 Data Catalog) + R2 SQL for petabyte-scale analytics. For GCP: Cloud Storage + BigQuery. The key insight is that object storage is the new data warehouse — Parquet on R2/S3 is durable, cheap, and queryable.

---

## Anti-Patterns to Watch For

**Distributed Monolith**: Microservices that can't deploy independently because they share a database or have synchronous call chains. Worse than a monolith — all the complexity, none of the benefits.

**Event Sourcing Everywhere**: Using event sourcing for domains where a simple audit log table would suffice. Reserve it for domains where state history is a core requirement.

**Premature CQRS**: Adding read/write separation when your read/write ratio is 2:1 and a single database handles both fine. CQRS adds operational overhead — justify it with data.

**Pattern Resume-Driven Development**: Choosing microservices + event sourcing + CQRS + Kubernetes for a todo app because the tech stack looks impressive. Match complexity to the problem.

---

## Cross-Cutting Architecture Decisions

### Multi-Tenancy

How to isolate data and compute between tenants (customers, organizations, workspaces).

| Model | Isolation Level | Complexity | Cost | Choose When |
|---|---|---|---|---|
| **Shared everything** (tenant_id column) | Logical | Low | Lowest | Early stage, < 100 tenants, no compliance requirements |
| **Schema-per-tenant** | Schema | Medium | Medium | Stronger isolation needed without separate databases, moderate tenant count |
| **Database-per-tenant** | Physical | High | Highest | Regulatory requirements (data residency), enterprise customers demanding full isolation |

**Default**: Shared everything with `tenant_id` on every table + Row-Level Security (RLS) in PostgreSQL. This covers 90% of SaaS products. RLS enforces isolation at the database level — application bugs can't leak data across tenants.

**Scaling pattern**: Start shared, extract high-value or regulated tenants to dedicated schemas/databases as needed. The tenant routing layer should be an architectural boundary from day one, even if the implementation is just a `WHERE tenant_id = ?`.

**Who uses it**: Slack (workspace-per-tenant, shared infrastructure), Salesforce (shared database with org isolation), Neon (database-per-tenant for their own product).

### Real-Time Communication

Patterns for bidirectional or push-based communication beyond LLM streaming (for LLM-specific streaming, see `references/ai-architecture.md` § Streaming Architecture).

| Protocol | Direction | Use Case | Complexity |
|---|---|---|---|
| **SSE (Server-Sent Events)** | Server → Client | Notifications, live feeds, status updates | Low |
| **WebSocket** | Bidirectional | Chat, collaborative editing, gaming, live dashboards | Medium |
| **WebTransport** | Bidirectional | Low-latency, multiplexed streams (next-gen WebSocket) | High |

**Architecture decision**: SSE handles most "real-time" needs (notifications, feeds, progress). Use WebSocket only when the client needs to send frequent messages to the server (chat, collaboration). Don't use WebSocket just because "it's real-time."

**Our stack**:
- **Cloud Run**: Supports WebSocket with session affinity. Set timeout to match max connection duration.
- **Cloudflare Workers**: Use Durable Objects for WebSocket state management. Each Durable Object holds connections for a room/channel.
- **Scaling**: For presence and pub/sub across instances, use Redis (Upstash) or Neon `LISTEN/NOTIFY` for low-scale, Pub/Sub for high-scale.

**Connection management**: WebSocket connections are stateful. Plan for: reconnection with message replay, heartbeat/ping-pong for dead connection detection, graceful connection draining during deployments, and connection limits per instance.

### API Versioning Strategy

How to evolve APIs without breaking existing clients.

| Strategy | Mechanism | Trade-off |
|---|---|---|
| **URL path versioning** (`/v1/users`) | Version in URL | Simple and explicit. But proliferates endpoints and pollutes routing. |
| **Header versioning** (`Accept: application/vnd.api+json;version=2`) | Version in header | Cleaner URLs. But less visible, harder to test in browser. |
| **Query parameter** (`/users?version=2`) | Version in query | Easy to default. But mixes concerns in query string. |
| **No versioning (additive only)** | Never break, only add | Zero overhead. Requires discipline — no field removal, no type changes. |

**Default for most products**: **Additive changes only**. Add new fields, never remove or rename existing ones. This eliminates versioning complexity entirely and works until you need a fundamental API redesign.

**When to version**: Breaking changes to core resources, fundamental data model changes, or when supporting enterprise clients with long upgrade cycles.

**Our stack**: For internal APIs (backend ↔ frontend you control), additive changes are sufficient. For public APIs, URL path versioning (`/v1/`) — it's the most explicit and debuggable option.

### Event Schema Evolution

When using event-driven architecture, event schemas will change over time. Without a strategy, schema changes break consumers silently.

| Strategy | How It Works | When |
|---|---|---|
| **Additive only** | Never remove or rename fields, only add new ones | Default. Covers 90% of cases. |
| **Versioned events** | `OrderCreatedV1`, `OrderCreatedV2` as separate event types | Breaking changes to event structure |
| **Schema envelope** | Wrap payload in `{ version, schema, data }` | Multiple consumers at different versions |

**Key rules**:
- **Producers** must be backward compatible — old consumers should still work with new events
- **Consumers** must be forward compatible — ignore unknown fields
- **Never delete fields** that consumers might depend on. Deprecate first, remove after all consumers are updated.

For solo/small team: additive-only is almost always sufficient. If you find yourself needing versioned events, that's a signal the domain boundary might be wrong.

### Feature Flag Architecture

Decouple deployment from release. Ship code to production without exposing it to users until ready.

**Use cases**:
- **Gradual rollout**: Release to 1% → 10% → 50% → 100% of users
- **Kill switch**: Instantly disable a broken feature without redeployment
- **A/B testing**: Route users to different feature variants
- **Entitlements**: Gate features by plan tier (free, pro, enterprise)

**Architecture**:
```
Client/Server --> Flag evaluation (local SDK) --> Flag configuration store
                                                  (PostHog / LaunchDarkly)
```

**Key decisions**:
- **Server-side vs client-side evaluation**: Server-side for security-sensitive flags (plan gating, beta access). Client-side for UI experiments where latency matters.
- **Flag lifecycle**: Every flag should have an owner and an expiration date. Permanent flags (entitlements) are fine; temporary flags (rollouts) that linger become tech debt.
- **Default values**: Always define a safe default (typically `false` / control variant) for when the flag service is unreachable.

**Our stack**: PostHog (already in stack) provides feature flags with targeting rules, percentage rollouts, and A/B testing. No additional infrastructure needed.
