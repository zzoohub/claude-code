# Architecture Design Principles & Lessons from Production

Hard-won lessons from companies operating at scale. Reference this when making architecture decisions to avoid known pitfalls.

---

## Core Principles

### 1. Design for Failure, Not Success
Every external dependency will fail. Every network call will timeout. Every disk will fill up. The question isn't "will it fail?" but "how does the system behave when it fails?"

**Application**: For every integration point in your design, document: (a) what happens when it's unavailable, (b) how the user experience degrades, and (c) how the system recovers.

*Reference*: Netflix's Chaos Engineering — they intentionally break production to verify resilience. You don't need to run Chaos Monkey, but you need to think like it.

### 2. Make the Wrong Thing Hard, Not the Right Thing Easy
Good architecture makes it difficult to introduce certain classes of bugs. Compile-time safety (Rust), type systems (TypeScript strict), schema validation (Pydantic, Zod) — these are architectural decisions, not code style preferences.

**Application**: Choose technologies and patterns that prevent errors at the earliest possible stage (compile time > deploy time > runtime > production).

### 3. Delay Irreversible Decisions
Two-way doors (reversible decisions) can be made quickly. One-way doors (irreversible) deserve design docs. Database choice, primary language, authentication architecture — these are one-way doors. Library choice, caching strategy, log format — these are two-way doors.

**Application**: For each ADR in your design doc, classify whether it's a one-way or two-way door. One-way doors get more rigorous analysis.

*Reference*: Amazon's decision-making framework distinguishes Type 1 (irreversible) and Type 2 (reversible) decisions.

### 4. Optimize for Change, Not Performance
Unless you have measured evidence of a performance problem, optimize for maintainability and changeability. Performance optimization without measurement is premature optimization.

**Application**: Choose hexagonal/clean architecture by default because they optimize for change. Switch to layered only when the simplicity benefit is clear and the service is unlikely to evolve significantly.

*Exception*: When the PRD specifies hard latency requirements (e.g., "< 50ms p99"), performance is a first-class architectural concern from day one.

### 5. The Twelve-Factor App (Adapted)

| Factor | Application to Our Stack |
|---|---|
| Codebase | One repo per deployable service. Monorepo acceptable for tightly coupled services. |
| Dependencies | Explicitly declared. Cargo.toml, pyproject.toml, package.json. No implicit system-level deps. |
| Config | Environment variables. Never in code. Use Secret Manager for sensitive values. |
| Backing Services | Treat databases, caches, queues as attached resources. Swappable via config. |
| Build, Release, Run | CI/CD pipeline produces immutable container images. |
| Processes | Stateless processes. Session state in external store (Redis, DB), never in memory. |
| Port Binding | Service exposes itself via port binding. No reliance on runtime injection by app server. |
| Concurrency | Scale horizontally via process model. Cloud Run handles this natively. |
| Disposability | Fast startup, graceful shutdown. Critical for serverless/container environments. |
| Dev/Prod Parity | Minimize gaps. Use same DB engine in dev and prod (Neon branching helps here). |
| Logs | Treat as event streams. Structured JSON to stdout. Platform handles aggregation. |
| Admin Processes | Run management tasks as one-off processes in the same environment. |

### 6. Cost-Aware Architecture

For solopreneur and small-team products, infrastructure cost is an architectural constraint on par with performance. Every component should justify its existence against a "what does this cost at low traffic?" test.

**Application**: Prefer scale-to-zero services (Neon, Cloud Run) over always-on infrastructure. Choose zero-egress-fee storage (R2 over S3). Use free tiers for development (Neon branching, embedding API free tiers). Estimate monthly cost at launch traffic (100-1K DAU) and at growth targets -- if a component costs more idle than active, reconsider.

*Reference*: See `references/stack-templates.md` for platform choices optimized for solopreneur cost profiles.

### 7. Developer Experience as Force Multiplier

A solo developer's productivity is the binding constraint. Architecture decisions that save 10ms of request latency but add 30 minutes of deployment friction are net negative. Optimize for fast feedback loops: local development fidelity, quick deployments, clear error messages, and minimal context-switching between tools.

**Application**: Choose platforms that support local development parity (Neon branching for DB, Docker Compose for services). Prefer unified ecosystems (GCP services together) over best-of-breed when the DX improvement outweighs the capability gap. Minimize the number of dashboards, CLIs, and credentials a single developer must manage.

---

## Lessons from Production Incidents

### The N+1 Query Problem (Common at Every Scale)
**Pattern**: ORM loads a list of entities, then lazily loads related entities one-by-one.
**Impact**: A page that should make 2 queries makes 200.
**Architecture implication**: Specify in the design doc whether the service uses eager loading, explicit joins, or dataloader patterns. This is an architectural choice, not a coding detail.

### The Thundering Herd (Cache Stampede)
**Pattern**: Cache expires. All concurrent requests hit the database simultaneously.
**Impact**: Database overload, cascading failure.
**Architecture implication**: If your design includes caching, specify the stampede prevention mechanism (lock-based recomputation, stale-while-revalidate, probabilistic early expiration).

*Reference*: Facebook's Memcached paper describes their approach to cache lease tokens.

### The Distributed Monolith
**Pattern**: Microservices that must be deployed together, share databases, or have synchronous call chains.
**Impact**: All the operational overhead of microservices with none of the benefits.
**Architecture implication**: If your "microservices" can't be deployed independently, they're a distributed monolith. Be honest about this in the design doc. A well-structured monolith is better than a poorly-structured microservice mesh.

*Reference*: Airbnb's post-mortem on their SOA migration acknowledges this trap.

### The Retry Storm
**Pattern**: Service A retries on failure. Service B also retries. Service C also retries. A single downstream failure triggers exponential retry amplification.
**Impact**: A small failure becomes a total outage.
**Architecture implication**: Define retry budgets at the architecture level, not per-service. The outermost caller retries; inner services fail fast.

### Cold Start Cascades (Serverless)
**Pattern**: Low traffic causes all instances to scale to zero. A traffic burst requires all instances to cold-start simultaneously.
**Impact**: First request latency spikes to seconds.
**Architecture implication**: If using serverless, document: (a) minimum instances configuration, (b) cold start time budget, (c) warm-up strategy.

*Reference*: Discord's blog on why they moved from Go to Rust mentioned cold start performance as a factor.

---

## Data Architecture Anti-Patterns

### Shared Database Between Services
**Problem**: Two services read/write the same tables. Schema changes require coordinated deployment.
**Solution**: Each service owns its data. If another service needs data, it goes through an API or event stream.

### Event Sourcing Everywhere
**Problem**: Event sourcing adds complexity (event store, projections, eventual consistency). Using it for a simple CRUD service is over-engineering.
**Solution**: Use event sourcing only when you need: audit trail, temporal queries, or complex event processing. For everything else, simple state-based persistence is fine.

### Premature CQRS
**Problem**: Separate read and write models before you have evidence that read and write patterns diverge.
**Solution**: Start with a single model. Split into CQRS only when: (a) read and write loads are significantly different, or (b) read model needs denormalization that conflicts with write model normalization.

---

## Security Architecture Patterns

### Defense in Depth
Never rely on a single security control. Layer them:
1. **Edge**: Rate limiting, WAF, DDoS protection (Cloudflare)
2. **Transport**: TLS 1.3, certificate pinning for mobile
3. **Authentication**: Token validation at gateway/middleware
4. **Authorization**: Permission check at service/handler level
5. **Data**: Encryption at rest, column-level encryption for PII
6. **Audit**: Immutable audit log for sensitive operations

### Principle of Least Privilege
Each component should have only the permissions it needs:
- Database users per service with minimal grants
- Cloud IAM roles scoped to specific resources
- API keys scoped to specific operations
- Container runtime as non-root user

### Zero Trust Within the Network
Internal services authenticate to each other. "It's inside our VPC" is not an authentication mechanism.

---

## Observability Architecture

### The Three Pillars, Applied

| Pillar | What to Capture | Tool |
|---|---|---|
| **Logs** | Structured events (request received, business event, error occurred). Include correlation IDs. | stdout → Cloud Logging / Logpush |
| **Metrics** | Request rate, error rate, duration (RED method). Resource utilization. Business KPIs. | Prometheus / Cloud Monitoring |
| **Traces** | End-to-end request path across service boundaries. Latency breakdown by component. | OpenTelemetry → Jaeger / Cloud Trace |

### The RED Method (for every service)
- **R**ate: Requests per second
- **E**rrors: Errors per second
- **D**uration: Latency distribution (p50, p95, p99)

### The USE Method (for every resource)
- **U**tilization: How busy is the resource?
- **S**aturation: How much queued work?
- **E**rrors: How many errors?

### SLO-Based Alerting
Don't alert on symptoms. Alert on SLO violations:
- "Error rate > 1% over 5 minutes" (availability SLO)
- "p99 latency > 500ms over 10 minutes" (latency SLO)
- "Successful login rate < 95% over 15 minutes" (business SLO)
