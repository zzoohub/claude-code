---
name: z-software-architecture
description: Produce a Software Architecture Design Document from a PRD. Use when the user says "design doc", "software architecture", "system design", "architect this", "architecture design", or provides a PRD and asks for technical architecture. Also use when the system involves AI/LLM features (RAG, agents, chat, copilot, semantic search). Generates a comprehensive design document covering system context, component architecture, data flow, infrastructure decisions, AI/LLM integration patterns, cross-cutting concerns, and ADRs — while explicitly excluding DB schemas, API endpoint lists, folder structures, and UI specifics. Produces D2 architecture diagrams and outputs a markdown design doc that serves as the source of truth for implementation.
---

# Software Architect Skill

When given a Product Requirements Document (PRD), produce a **Design Doc** — a decision record that captures the system's structure, trade-offs, and rationale with enough clarity that any engineer can pick it up and start implementing.

## Philosophy

Great architecture documents are **decision records, not implementation manuals**. Every section must answer *why* a choice was made, not just *what* was chosen. If there are no trade-offs to discuss, the section doesn't belong in this document.

Inspired by: Google Design Docs, Uber ERDs, arc42, C4 model, Stripe's engineering culture of writing before building.

---

## Scope Boundaries

This skill produces architecture-level decisions. It deliberately **excludes** the following — they are separate implementation concerns:

| Excluded Topic | Reason |
|---|---|
| Table schemas, column types, indexes, migrations | Implementation detail — derived from data models in the Design Doc |
| API endpoint lists, request/response shapes | Implementation detail — derived from component interfaces in the Design Doc |
| Folder structure, code conventions, linting rules | Codebase concern — belongs in CLAUDE.md or project config |
| Concrete UI component trees, page layouts | Implementation detail — derived from system context in the Design Doc |

**Note**: API *design philosophy* (REST vs GraphQL, versioning strategy, pagination approach) is an architectural decision and IS covered in Section 3.2 of the template. What's excluded is the concrete endpoint catalog.

If the user asks for any of the excluded topics, explain that this skill focuses on architecture-level decisions and offer to note it as a requirement for the implementation phase.

---

## Process

### Step 0 — Intake & Clarification

Before writing anything, read the PRD thoroughly. Then:

**1. Stack template**: Present all three options and mark your recommendation with **(Recommended)** based on the PRD. Ask the user to confirm:
- **Rust**: Rust/Axum + TanStack Start/SolidJS + GCP Cloud Run + Neon
- **TypeScript**: Hono on Workers + TanStack Start/SolidJS + Cloudflare + Neon
- **Python AI**: FastAPI + TanStack Start/SolidJS + GCP Cloud Run + Neon

Recommendation logic: Python AI if the PRD requires Python-only libraries (ML models, transformers). TypeScript if edge-first or fullstack JS fits best. Rust for everything else (default). See `references/stack-templates.md` for full details.

**2. Clarification**: Identify gaps by asking yourself (and the user if needed):

1. **Scale signals**: Expected users, requests/sec, data volume, growth trajectory?
2. **Latency requirements**: Which user-facing paths are latency-critical?
3. **Consistency model**: Is eventual consistency acceptable? Where is strong consistency required?
4. **Offline / real-time**: Does the product need real-time features (WebSocket, SSE, polling)?
5. **Multi-tenancy**: Single-tenant or multi-tenant? Data isolation requirements?
6. **Regulatory**: GDPR, CCPA, PCI-DSS, SOC2, or other compliance needs?
7. **Budget posture**: Solopreneur cost-sensitive vs. enterprise budget?

If the PRD answers these clearly, proceed. If not, ask the user **only the critical missing questions** — do not block on nice-to-haves.

### Step 1 — Write the Design Document

Produce the document following the **Design Document Template** below. Write in clear, direct prose. Avoid filler.

### Step 2 — Self-Review Checklist

Before presenting the document, verify:

- [ ] Every technology choice has a stated rationale with trade-offs
- [ ] Non-goals are explicit (things you deliberately chose NOT to do)
- [ ] Document length matches complexity tier (Light: 5-8p, Standard: 10-15p, Complex: 15-25p)
- [ ] Cross-cutting concerns (security, observability, error handling, testing) are addressed
- [ ] At least 2 alternatives are considered for each major architectural decision
- [ ] Data flow is traceable end-to-end for the primary user journeys
- [ ] The document is readable by a senior engineer in 15 minutes

---

## Design Document Template

Use the following structure. Every section is mandatory unless marked (optional). Adapt depth per project complexity.

```
# {Project Name} — Software Architecture Design Document

**Status**: Draft | In Review | Approved
**Author**: (auto-filled)
**Date**: {date}
**PRD Reference**: {link or title}

---

## 1. Context & Scope

### 1.1 Problem Statement
One paragraph. What problem does this system solve? Why does it need to exist now?

### 1.2 System Context Diagram
Generate a D2 diagram showing where this system sits in the broader landscape:
- Who are the **actors** (users, external systems, third-party APIs)?
- What existing systems does this interact with?
- What data flows in and out?

Use C4 Level 1 thinking: the system as a black box within its environment. Invoke the `d2:diagram` skill to produce the diagram. If unavailable, use Mermaid or ASCII diagrams as fallback.

### 1.3 Assumptions
List assumptions that the architecture depends on. If any assumption is wrong, the architecture may need to change.

---

## 2. Goals & Non-Goals

### 2.1 Goals
Bulleted list. Each goal should be **measurable** or **verifiable**.
Example: "Support 10K concurrent WebSocket connections with <100ms message delivery"

### 2.2 Non-Goals
Things that could reasonably be goals but are **explicitly excluded** from this version.
Example: "Multi-region active-active replication (planned for v2)"

---

## 3. High-Level Architecture

### 3.1 Architecture Style
Architecture decisions:

**System Architecture** (how services/components communicate):
- Monolith / Modular Monolith / Microservices / Serverless
- Request-Response / Event-Driven / CQRS / Event Sourcing / Hybrid

**Code Structure**: Always Hexagonal (Ports & Adapters). See `references/architecture-patterns.md` for rationale.

**Stack**: Per the chosen stack template from Step 0. See `references/stack-templates.md` for full details.

**Mobile**: React Native (Expo).

**Rationale**: Explain trade-offs for the system architecture choice. Reference team size, expected scale, operational complexity budget, and data consistency needs.

### 3.2 Container Diagram
Generate a D2 diagram (C4 Level 2) showing the major runtime containers. If the `d2:diagram` skill is unavailable, use Mermaid or ASCII diagrams.

For each container, state:
- **Technology**: What runtime/framework
- **Responsibility**: What it does (1-2 sentences)
- **Communication**: Protocol and style (REST, gRPC, WebSocket, pub/sub, etc.)
- **API design philosophy** (for the primary API surface): REST vs GraphQL, versioning strategy (URL path vs header), pagination approach (cursor vs offset)

### 3.3 Component Overview
For the primary backend service, describe (C4 Level 3 — high level only) the major internal components/modules:
- What are the bounded contexts or domain modules?
- How do they relate to each other?
- Which components are on the critical path?

Do NOT specify classes or file structures. Stay at the "module responsibility" level.

---

## 4. Data Architecture

### 4.1 Data Flow
Trace the data journey for the 2-3 most important user flows:
- Where does data enter the system?
- What transformations happen?
- Where is it stored?
- Where is it read from?
- What are the consistency guarantees at each stage?

### 4.2 Storage Strategy
For each data store, explain:
- **What kind of data** it holds (transactional, analytical, cache, files, etc.)
- **Why this storage type** (relational, document, key-value, object storage, etc.)
- **Consistency model** (strong, eventual, causal)
- **Retention / lifecycle** policy if relevant

Do NOT define table schemas — that is an implementation detail derived from the data models above.

### 4.3 Caching Strategy (if applicable)
- What is cached and why
- Cache invalidation approach
- TTL policy rationale

---

## 5. Infrastructure & Deployment

### 5.1 Compute Platform
State the chosen platform and rationale. Address:
- Why this platform over alternatives
- Cold start implications (for serverless)
- Scaling model (horizontal auto-scale, vertical, fixed)
- Region selection rationale

### 5.2 Deployment Strategy
- How code gets from PR merge to production
- Blue-green / canary / rolling / recreate
- Rollback mechanism

### 5.3 Environment Topology
- How many environments (dev, staging, production)?
- What differs between them?

---

## 6. Cross-Cutting Concerns

### 6.1 Authentication & Authorization
- Auth flow (OAuth2, JWT, session-based, etc.)
- Token lifecycle (access token expiry, refresh token rotation)
- Authorization model (RBAC, ABAC, etc.)
- Where auth is enforced (middleware, gateway, per-service)

### 6.2 Observability
- **Logging**: What is logged, structured format, log levels, aggregation
- **Metrics**: Key business and infra metrics, collection mechanism
- **Tracing**: Distributed tracing approach if applicable
- **Alerting**: Critical alert conditions

### 6.3 Error Handling & Resilience
- Retry policies (which calls, backoff strategy)
- Circuit breaker patterns (if applicable)
- Graceful degradation strategy
- Timeout budgets for request chains

### 6.4 Security
- Data in transit (TLS versions)
- Data at rest encryption
- Secret management approach
- Input validation strategy
- Rate limiting / abuse prevention
- OWASP Top 10 considerations relevant to this system

### 6.5 Testing Architecture
- **Testing strategy**: Test pyramid shape (unit-heavy vs integration-heavy) and rationale
- **Unit testing**: What is unit-tested (domain logic in hexagonal core), mocking strategy for ports
- **Integration testing**: Which adapter boundaries are integration-tested (DB, external APIs)
- **E2E testing**: Critical user flows covered, test environment strategy
- **Contract testing** (if multi-service): How service interfaces are verified

### 6.6 Performance & Scalability
- Expected load profile (peak, average, growth)
- Identified bottlenecks and mitigation
- Scaling triggers and limits

---

## 7. Integration Points

For each external system or third-party service:
- What it provides
- Communication protocol
- Failure mode and fallback
- SLA dependency

---

## 8. Migration & Rollout (if applicable)

If replacing or evolving an existing system:
- Migration strategy (big bang, strangler fig, parallel run)
- Data migration approach
- Feature flag strategy
- Rollback plan

---

## 9. Risks & Open Questions

### 9.1 Technical Risks
| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| ... | ... | ... | ... |

### 9.2 Open Questions
Numbered list of unresolved decisions. For each:
- What is the question?
- What are the options?
- What information is needed to decide?
- Who should decide?

---

## 10. Architecture Decision Records (ADRs)

For each significant decision, write a brief ADR:

### ADR-{N}: {Title}
- **Status**: Proposed | Accepted | Deprecated
- **Context**: What situation motivates this decision?
- **Decision**: What did we decide?
- **Alternatives Considered**:
  - Alternative A: description -> rejected because...
  - Alternative B: description -> rejected because...
- **Consequences**: What are the positive and negative outcomes?

Include ADRs for at minimum:
1. Backend language and framework
2. Frontend framework and hosting
3. System architecture pattern (monolith/microservices, sync/async/event-driven)
4. Database platform
5. Compute platform
6. Authentication approach
7. LLM integration approach (if AI features present)

---

## 11. AI/LLM Architecture (if applicable)

Include this section when the system uses LLM-powered features. Cover:
- LLM integration pattern (direct API, gateway, model cascading)
- RAG architecture (if applicable): retrieval strategy, vector storage, chunking approach
- Agent architecture (if applicable): pattern, state management, human-in-the-loop
- Streaming approach for user-facing AI features
- Cost optimization strategy (model cascading, caching, batch vs. real-time)
- Guardrails and safety (input/output validation, PII handling, content safety)
- AI-specific observability (token tracking, cost per request, quality monitoring)

```

---

## Reference Files

The following reference files contain detailed decision frameworks. Read the relevant ones before making architecture decisions.

**Read `references/architecture-patterns.md`** before choosing system architecture and language — it contains the full decision framework with flowcharts, real-world examples, and anti-patterns.

**Read `references/stack-templates.md`** for the chosen stack template — it contains the full technology and infrastructure decisions per template, plus shared services, auth patterns, and region strategy.

**Read `references/design-principles.md`** during the self-review phase — it contains core architecture principles, production incident patterns, security architecture, and observability patterns to verify your design against.

**Read `references/ai-architecture.md`** if the PRD includes AI-powered features (LLM generation, RAG, agents, semantic search, copilot, chat) — it covers LLM integration tiers, RAG architecture, agent patterns, streaming, vector storage, cost optimization, guardrails, and observability.

---

## Complexity Scaling

Not every project deserves the same depth. Calibrate the document to the system's complexity:

| Complexity | Signals | Document Depth |
|---|---|---|
| **Light** | Single service, CRUD-dominant, no async, no external integrations beyond DB | 5-8 pages. Sections 8 (Migration) and 7 (Integration) can be omitted. Keep ADRs to 2-3. Combine sections where there's little to say. |
| **Standard** | Multiple components, some async processing, a few external integrations, auth required | 10-15 pages. Full template. This is the default. |
| **Complex** | Distributed services, event-driven, real-time features, multiple data stores, compliance requirements, AI/LLM integration | 15-25 pages. Full template with deeper treatment. Consider separate D2 diagrams for each major subsystem. Data flow diagrams for all critical paths, not just top 2-3. |

---

## Writing Style

- **Direct and opinionated**. State what you chose and why. Don't hedge excessively.
- **Trade-offs over descriptions**. Every choice should discuss what was gained and what was sacrificed.
- **Concrete over abstract**. "Redis with 15-minute TTL" beats "a caching layer."
- **Diagrams with D2**. Generate architecture diagrams using D2 (invoke the `d2:diagram` skill). If unavailable, use Mermaid or ASCII diagrams. Produce a System Context diagram (C4 Level 1) and Container diagram (C4 Level 2) at minimum. Use D2 classes for consistent styling -- `person` for actors, `cylinder` for databases, `queue` for message brokers, dashed borders for system boundaries.
- **No filler**. If you catch yourself writing "it is important to note that" -- delete it.
- **Reference real-world precedent** when helpful: "Netflix uses a similar circuit-breaker pattern for their API gateway" adds credibility and context.

---

## Quality Bar

The final document should pass the **"3 AM Test"**: If an on-call engineer gets paged at 3 AM for a production issue in this system, can they open this design doc and understand the system well enough to orient themselves within 5 minutes?

If yes, the doc is good enough. If not, it needs more clarity.

## Phase Tagging

When the input PRD has companion Phase PRDs (`docs/prd-phase-*.md`):

1. **Write the full document for the complete vision** -- do not shrink the architecture to fit a single phase
2. **Tag sections inline** -- append `[Phase 1]`, `[Phase 2]`, `[Phase 3+]` etc. to component headings, ADR titles, and integration points to indicate when each becomes relevant
3. **Add a Phase Implementation Summary** at the end of the document:

```
## Phase Implementation Summary

### Phase 1
- Components: ...
- Infrastructure: ...
- Key ADRs: ...

### Phase 2
- Components: ...
- New integrations: ...

### Phase 3+
- Components: ...
- New integrations: ...
```

If no Phase PRD exists, omit phase tags entirely.

---

## Output

Save to `docs/design-doc.md`.
