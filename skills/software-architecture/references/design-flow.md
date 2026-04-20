# Architecture Design Flow

10-stage methodology for software architecture. Stage 0 (Auto-Classification) lives in SKILL.md. This file covers stages 1-9.

Stages 2, 3, and 4 co-evolve (Twin Peaks model) — domain modeling reveals new ASRs, pattern selection changes domain boundaries. One iteration is usually sufficient.

ADRs are written immediately when decisions occur, not batched at the end.

---

## Stage 1 — Problem Definition

**What it answers**: What problem, for whom, why now?

### Process

1. **Validate the PRD**: Does it describe problems or solutions? If solutions, push back to the underlying problem.
2. **Extract core behaviors** as verbs (e.g., "searches", "uploads", "subscribes", "processes", "compiles"). These become the action vocabulary for the domain model.
3. **Quantify success criteria**: Every goal needs a number. "Fast" -> "p99 < 500ms". "Reliable" -> "99.5% uptime". "Lightweight" -> "< 50MB memory".
4. **Identify system boundary**: What this system does / does not do / what external systems it connects to.

### Output

Write to `docs/arch/context.md` §1 (Problem) and §2 (System Boundary).

---

## Stage 2 — ASR Extraction & Utility Tree

**What it answers**: Which quality attributes drive the architecture?

Architecturally Significant Requirements (ASRs) are the requirements that shape the system's structure. Most PRD requirements are *not* ASRs — they're features that fit into whatever structure exists. ASRs are the ones that *force* structural decisions.

### ASR Filter Criteria

A requirement is architecturally significant if it matches any of these 7 filters:

| # | Filter | Example |
|---|---|---|
| 1 | Business risk — failure would threaten the product | Payment processing correctness |
| 2 | Unusual quality level — beyond typical expectations | Sub-100ms p99 for real-time features |
| 3 | External dependency uncertainty — vendor may change or fail | LLM API pricing, availability, deprecation |
| 4 | Cross-cutting — affects multiple modules | Authentication, logging, error handling |
| 5 | No precedent — team hasn't built this before | First-time real-time collaboration |
| 6 | Past failure — similar systems have failed here | Data migration from legacy system |
| 7 | Regulatory — compliance mandates specific approaches | GDPR data residency, SOC 2 |

### Utility Tree

Organize ASRs into a utility tree that makes priorities explicit:

```
System Utility
+-- Performance
|   +-- "API response < 500ms p99" [H, M]
|   +-- "Search results < 1s" [M, H]
+-- Availability
|   +-- "99.5% uptime" [H, L]
+-- Security
|   +-- "No PII in logs" [H, L]
+-- Cost Efficiency
    +-- "< $X/month at target load" [H, M]
```

Each scenario gets an **[Importance, Difficulty]** rating:
- **Importance**: How critical to business success (H/M/L)
- **Difficulty**: How hard to achieve architecturally (H/M/L)

**[H,H] items are architecture drivers** — they demand explicit patterns and trade-off analysis. Every [H,H] scenario must have a corresponding pattern in stage 4.

### AI ASR Questions

If the PRD involves AI/LLM features, evaluate these concerns:

| Question | Why It Matters | Drives |
|---|---|---|
| Streaming required? | SSE/WebSocket infrastructure, token-by-token rendering | Transport layer, frontend architecture |
| RAG needed? | Vector store, chunking pipeline, retrieval strategy | Data architecture, infrastructure cost |
| Agent capabilities? | Tool orchestration, durable execution, safety boundaries | System pattern, security model |
| Cost ceiling? | Model selection, caching strategy, batch vs real-time | Every AI component decision |
| Hallucination tolerance? | Guardrail depth, human-in-the-loop, citation requirements | Output validation, UX design |

### Quality Attribute Trade-offs

Quality attributes trade off against each other. Make these explicit:

| Attribute | Measures | Typical Trade-off |
|---|---|---|
| Performance | Latency, throughput | vs. Maintainability (optimization adds complexity) |
| Availability | Uptime, fault tolerance | vs. Cost (redundancy is expensive) |
| Scalability | Load handling, growth capacity | vs. Simplicity (distributed systems are complex) |
| Security | Data protection, access control | vs. Usability (more security = more friction) |
| Maintainability | Changeability, debuggability | vs. Performance (abstractions add overhead) |
| Testability | Ease of verification | vs. Time-to-market (test infrastructure takes effort) |
| Deployability | Release frequency, rollback speed | vs. Stability (more deploys = more risk surface) |
| Cost Efficiency | Infrastructure spend per user | vs. Performance/Availability |

Rank the top 3-4 attributes for this system. Identify conflicts and make explicit trade-offs. Each ADR should reference which quality attributes it optimizes and which it trades away.

### Output

Write to `docs/arch/context.md` §3 (ASR & Utility Tree).

---

## Stage 3 — Domain Model

**What it answers**: What are the core domain concepts and their boundaries?

### Event Storming (Solo)

Extract domain events from the PRD:

1. **Read the PRD and list domain events** as past-tense verbs: "UserRegistered", "OrderPlaced", "PaymentProcessed", "ContentPublished".
2. **Group events by aggregate** — which entity's state changed?
3. **Identify commands** — what action triggered each event?
4. **Mark external triggers** — which events come from outside the system?

### Bounded Context Identification

Same term, different rules = different bounded context.

- "User" in auth context (credentials, sessions) vs. "User" in billing context (subscription, payment method) — different bounded contexts.
- If two modules could evolve independently without breaking each other, they're separate contexts.
- If changing one always requires changing the other, they're the same context.

### Ubiquitous Language Glossary

Code terms must match PRD terms 1:1. No synonyms, no abbreviations that diverge from business language.

| Term | Definition | Code Mapping |
|---|---|---|
| e.g., Workspace | A shared collaboration space owned by one user | `Workspace` entity, `workspace_id` |
| e.g., Member | A user with access to a workspace | `Member` value object |

Read `references/service-architecture.md` for DDD tactical patterns (entities, value objects, aggregates, domain events).

### Output

Write to `docs/arch/context.md` §4 (Domain Model).

---

## Stage 4 — Pattern Selection & ATAM Gate

**What it answers**: What architectural patterns satisfy the architecture drivers?

### System Pattern Selection

Default: **Modular Monolith** — gives domain separation without deployment overhead.

Escalate when:
- **CQRS**: Read/write ratio > 10:1 or fundamentally different read/write models
- **Event-driven**: Clear async boundaries, eventual consistency acceptable
- **Event sourcing**: Audit trail is a first-class requirement, need to reconstruct past state

Read `references/system-architecture.md` for the full composition flowchart and pattern catalog.
Read `references/service-architecture.md` for internal service structure decision guide.

### AI Pattern Decision Tree

| If PRD requires... | Pattern | Key characteristics |
|---|---|---|
| Simple LLM call with structured output | Direct API | Schema validation, retry logic |
| Knowledge base Q&A | RAG | Chunking pipeline, vector store, retrieval strategy |
| User-facing AI assistant | Copilot | Streaming, conversation history, context window management |
| Multi-step task execution | Agent | Tool orchestration, durable execution, safety boundaries |
| Domain-specific language understanding | Fine-tuning | Training pipeline, evaluation suite, version management |

Real AI systems often combine patterns — a copilot typically needs RAG + streaming + conversation memory. Read `references/ai-architecture.md` for integration tiers and composition, `references/ai-agents.md` for agent-specific patterns.

### ATAM Gate

**Architecture Tradeoff Analysis Method** — simplified.

For every **[H,H] ASR** from stage 2:

1. **Identify the pattern** that addresses it
2. **Document sensitivity points** — where small changes in the pattern cause large effects
3. **Document trade-offs** — what this pattern sacrifices
4. **Verify** the pattern actually satisfies the scenario's measurement criteria

**Do NOT proceed to stage 5 without passing this gate.** Every [H,H] item must have a verified pattern.

If a [H,H] ASR has no satisfactory pattern:
- Revisit the utility tree — is the importance/difficulty rating correct?
- Consider hybrid patterns
- If still unsatisfied: document the best-effort pattern and its gaps in `docs/arch/system.md` §1, add to `docs/arch/decisions.md` Risk Register as high-impact risk

### Output

Write to `docs/arch/system.md` §1 (Patterns). Write ADRs for pattern decisions to `docs/arch/decisions.md`.

---

## Twin Peaks: Stages 2 <-> 3 <-> 4

These three stages co-evolve iteratively:

- **Domain modeling (3) reveals new ASRs (2)**: "We need real-time sync across workspace members" emerges when modeling the collaboration domain.
- **Pattern selection (4) changes domain boundaries (3)**: Choosing CQRS splits a bounded context into read and write sides.
- **ASR refinement (2) constrains patterns (4)**: Tightening a latency requirement eliminates certain patterns.

One iteration through stages 2->3->4->(back to 2 if needed) is usually sufficient. Don't over-iterate — move to stage 5 once the ATAM gate passes.

---

## Stage 5 — Component Design

**What it answers**: What are the concrete components and how do they connect?

### Tech Stack Selection

Choose technologies that fit the ASRs and patterns from stages 2-4. Record each choice with rationale in the "Core Technology" table of `docs/arch/system.md` §2. Use `references/tech-stack.md` as a reference — selections outside the list are fine if justified.

### Hexagonal Architecture (Default)

Domain never depends on infrastructure. This is non-negotiable for testability and changeability.

```
[Driving Adapters] -> [Ports] -> [Domain] <- [Ports] <- [Driven Adapters]
   (HTTP, CLI)                                        (DB, APIs, Queue)
```

For each bounded context:
1. **Define ports** (interfaces the domain exposes/requires)
2. **Define adapters** (concrete implementations of ports)
3. **Verify domain independence** — domain module imports nothing from infrastructure

Framework-neutral structure:

```
src/
+-- domain/           # Pure business logic — no imports from outside
|   +-- models/       # Entities, value objects, domain errors
|   +-- services/     # Domain services (orchestrate domain logic)
|   +-- ports/        # Interfaces (driven ports)
+-- application/      # Use cases — orchestrate domain + ports
|   +-- use-cases/
+-- adapters/         # Infrastructure implementations
|   +-- http/         # Driving adapter: HTTP handlers
|   +-- persistence/  # Driven adapter: repositories
|   +-- external/     # Driven adapter: third-party API clients
+-- config/           # Wiring: dependency injection, app bootstrap
```

### AI Components

| Component | Responsibility | Isolation rationale |
|---|---|---|
| LLM Gateway | Model routing, caching, cost tracking, abstraction over providers | Swap providers without touching domain |
| Embedding Pipeline | Chunking, embedding, vector store writes | Heavy I/O, different scaling profile |
| Eval Pipeline | Quality measurement, regression detection | Runs offline, different lifecycle |

### Container Diagram

Produce a C4 Level 2 container diagram in D2. Show:
- Runtime containers (services, databases, queues)
- Communication protocols between them
- External system integrations

### Output

Write to `docs/arch/system.md` §2 (Components).

---

## Stage 6 — Data Architecture

**What it answers**: Where does data live, how does it flow, how is consistency maintained?

### Storage Strategy

Choose storage type based on data characteristics, not convention:

| Data Characteristic | Storage Type | Examples |
|---|---|---|
| Structured, relational, ACID needed | Relational DB (PostgreSQL, MySQL) | Core domain data, transactions |
| High-volume key-value access | Key-value store (Redis, DynamoDB) | Sessions, caches, counters |
| Document-oriented, schema-flexible | Document DB (MongoDB, CouchDB) | Content, configurations |
| Time-series, append-heavy | Time-series DB (InfluxDB, TimescaleDB) | Metrics, logs, IoT sensor data |
| Unstructured binary | Object/blob storage (S3, GCS) | Files, media, backups |
| Vector similarity search | Vector store (pgvector, dedicated) | Embeddings, semantic search |
| Graph relationships | Graph DB (Neo4j, DGraph) | Social networks, knowledge graphs |

For each data store, document:
- What it holds
- Why this storage type
- Consistency model (strong, eventual, session)

**Versioned migrations are mandatory** for relational databases — no manual schema changes in production.

### AI Data

| Concern | Guidance |
|---|---|
| Chunking | Semantic chunking with 10-20% overlap. Chunk size depends on retrieval use case (512-1024 tokens typical). |
| Search | Hybrid search (dense vectors + BM25 keyword) outperforms either alone. |
| Context window | Budget tokens: system prompt + retrieved context + conversation history + output must fit model limit. Track and alert on overflow. |

Read `references/ai-architecture.md` §3 for RAG, vector storage, and chunking patterns.

### Key Data Flows

Trace 2-3 critical user journeys through the data layer:
- Where data enters
- What transformations happen
- Where it's stored
- Where it's read from

### Output

Write to `docs/arch/system.md` §3 (Data).

---

## Stage 7 — Deployment

**What it answers**: How does code get to production? How much does it cost?

### CI/CD Pipeline

Minimum gates: **test -> lint -> security scan -> build -> smoke test -> deploy**.

No manual deployment steps. Everything in the pipeline is reproducible.

### Cost Estimation

Estimate at two traffic levels relevant to the system:

| Component | Baseline (lower load) | Growth (higher load) |
|---|---|---|
| Compute | ... | ... |
| Database | ... | ... |
| Storage | ... | ... |
| Third-party APIs | ... | ... |
| **Total** | ... | ... |

Flag anything that costs money while idle.

### AI Ops

- **Model version date-pinning**: Never use "latest" — pin to specific model version dates
- **Cost alerting**: Alert at 80% of the cost ceiling from stage 2 ASRs
- **Fallback models**: Define cheaper fallback when primary model is unavailable or over budget

### Output

Write to `docs/arch/system.md` §4 (Deployment & Cost).

---

## Stage 8 — Cross-cutting Concerns

**What it answers**: What properties must hold across all components?

### Fitness Functions

3-5 automated CI checks that enforce architectural properties:

| Property | Check | Example |
|---|---|---|
| No circular dependencies | Import graph analysis | TS: `madge --circular` · Rust: `cargo-modules` / `cargo-depgraph` · Python: `pydeps --show-cycles` |
| Domain independence | Import rules | TS: `eslint-plugin-boundaries` · Rust: workspace crate boundaries (domain crate has no infra deps in `Cargo.toml`) · Python: `import-linter` contracts |
| Response time | Performance test | k6 / autocannon / wrk smoke test with p99 threshold from ASR |
| Bundle size | Build output analysis | Frontend: `size-limit`, `bundlesize` · Rust WASM: binary size threshold |
| Dependency drift | Lock file audit | Renovate/Dependabot policies, `cargo-deny`, `pip-audit`, `bun audit` |

Pick tools that fit the language of each module. The check matters; the specific tool is interchangeable.

These are the immune system of your architecture — they prevent silent erosion of design decisions. Run in CI on every commit.

### Observability

**RED method** for every service:
- **R**ate: Requests per second
- **E**rrors: Errors per second
- **D**uration: Latency distribution (p50, p95, p99)

**USE method** for every resource:
- **U**tilization: How busy is the resource?
- **S**aturation: How much queued work?
- **E**rrors: How many errors?

**SLO-based alerting** — alert on SLO violations, not symptoms:
- "Error rate > 1% over 5 minutes" (availability SLO)
- "p99 latency > 500ms over 10 minutes" (latency SLO)
- "Successful login rate < 95% over 15 minutes" (business SLO)

Day 1 priorities: error tracking, structured logging (JSON to stdout), health checks, uptime monitoring.

### Security

Defense in depth — never rely on a single security control:

1. **Edge**: Rate limiting, WAF, DDoS protection
2. **Transport**: TLS 1.3
3. **Authentication**: Token validation at gateway/middleware
4. **Authorization**: Permission check at service/handler level
5. **Data**: Encryption at rest, column-level encryption for PII
6. **Audit**: Immutable audit log for sensitive operations

Principle of least privilege: each component gets only the permissions it needs. Zero trust within the network — internal services authenticate to each other.

### AI Security

OWASP LLM Top 10 awareness. 3-layer defense:

1. **Input classification**: Detect and reject prompt injection, PII in prompts
2. **RAG trust boundary**: Treat retrieved context as untrusted — validate, sanitize, attribute
3. **Output validation**: Schema validation, content filtering, hallucination detection

Read `references/ai-architecture.md` guardrails section.

### Resilience

For each external dependency, decide upfront:

| Service | Timeout | Retry | If It's Down |
|---|---|---|---|
| Database | 5s | Backoff x3 | System offline |
| LLM API | 120s | Backoff x2 | "AI unavailable" + cached fallback |
| Payment provider | 15s | Idempotency key | "Payments temporarily unavailable" |
| Email service | 5s | Queue for later | Silent — never block user action |

Key patterns: timeout budgets (outer caller owns the budget), retry at outermost layer only (prevents retry storms), graceful degradation (degrade features, not the whole system).

Read `references/operational-patterns.md` for detailed resilience patterns.

### Production Incident Patterns (Check Against)

Verify your design doesn't contain these known failure modes:

- **N+1 queries**: ORM loads list then lazily loads relations one-by-one. Specify eager loading or dataloader patterns in the design.
- **Thundering herd**: Cache expires, all requests hit DB simultaneously. Specify stampede prevention (lock-based recomputation, stale-while-revalidate).
- **Distributed monolith**: "Microservices" that must be deployed together or share databases. Worse than a monolith.
- **Retry storm**: Nested retry logic causes exponential amplification. Define retry budgets at architecture level.
- **Cold start cascade**: All serverless instances scale to zero, traffic burst requires simultaneous cold starts. Document minimum instances and warm-up strategy.

### Design Principles as Evaluation Criteria

- **Design for failure**: Every integration point has a documented failure mode and recovery path
- **Make the wrong thing hard**: Type systems, schema validation, compile-time safety over runtime checks
- **Delay irreversible decisions**: One-way doors get rigorous analysis, two-way doors get decided fast
- **Optimize for change**: Hexagonal architecture by default because it optimizes for changeability
- **Twelve-Factor adapted**: Stateless processes, config via environment, backing services as attached resources, structured logs as event streams

### Output

Write to `docs/arch/system.md` §5 (Cross-cutting).

---

## Stage 9 — ADR & Risk Review

**What it answers**: Are all decisions recorded? What could go wrong?

Most ADRs are already written during stages 4-8. This stage reviews completeness and adds the risk register.

### ADR Format

Use the Y-statement format for consistency:

```
## ADR-NNN: [Title] — YYYY-MM-DD
- Stage: [which design stage produced this decision]
- Door: One-way (irreversible) | Two-way (reversible)
- Context: [the situation and forces at play]
- Decision: [what was chosen]
- Why: [the reasoning — reference quality attributes]
- Rejected: [alternatives and why they were rejected]
- Tradeoff: [positive and negative consequences]
- Revisit when: [trigger conditions for reconsideration]
```

**One-way doors** (irreversible — analyze carefully): Database choice, primary language, auth architecture, core domain model.
**Two-way doors** (reversible — decide fast): Library choice, caching strategy, log format, CI tool.

### Minimum ADRs

**Always record (all software types):**
1. System architecture pattern
2. Service architecture pattern
3. Primary data storage approach
4. Communication style (sync/async/event-driven)

**Record when applicable:**
- AI integration approach — when AI features exist
- Authentication/authorization — when users exist
- API design philosophy — when external consumers exist
- Offline/sync strategy — when offline capability is needed
- Distribution/packaging — for libraries, CLIs, desktop apps
- Concurrency model — for high-throughput or real-time systems

### Risk Register

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| e.g., LLM API price increase | High — cost ceiling exceeded | Medium | Multi-provider abstraction, usage-based rate limiting |

### AI-Specific Risks

| Risk | Mitigation |
|---|---|
| Hallucination in critical output | Schema validation, citation requirements, human review for high-stakes |
| Model deprecation | Version pinning, abstraction layer, evaluation suite for migration testing |
| Vendor lock-in | LLM Gateway pattern, standardized prompt format |
| Cost explosion | Per-request cost tracking, daily budget alerts, model cascading |
| RAG poisoning | Source trust scoring, content validation pipeline |

### Tech Debt Tracking

| Item | When | Priority | Resolution Condition |
|---|---|---|---|
| e.g., Shared DB between contexts | Stage 5 — accepted for MVP | P2 | Extract to separate DB when contexts need independent scaling |

### Conway's Law as Growth Risk

Architecture built by a small team mirrors that team's communication structure — which is optimal for the current team size. If the team grows, the architecture may need to evolve to match team boundaries. Document which module boundaries could become service boundaries if team structure demands it.

### Output

Final review of `docs/arch/decisions.md`.
