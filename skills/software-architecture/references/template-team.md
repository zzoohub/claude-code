# Team Architecture Template

A team architecture doc is a **decision record** that captures the system's structure, trade-offs, and rationale with enough clarity that any engineer can pick it up and start implementing. Inspired by Google Design Docs, Uber ERDs, arc42, C4 model, and Stripe's culture of writing before building.

---

## Sections at a Glance

| # | Section | What It Answers |
|---|---|---|
| 1 | Context & Scope | What problem, where does this system fit? |
| 2 | Goals & Non-Goals | What's in scope, what's explicitly out? |
| 3 | High-Level Architecture | What pattern, what stack, how do pieces connect? |
| 4 | Data Architecture | Where does data live, how does it flow, caching? |
| 5 | Infrastructure & Deployment | Where does it run, how does it deploy, DR, cost? |
| 6 | Cross-Cutting Concerns | SLOs, auth, observability, resilience, security, testing, accessibility, governance |
| 7 | Integration Points | What external dependencies, failure modes? |
| 8 | Migration & Rollout | How to migrate from existing system? *(if applicable)* |
| 9 | Risks & Open Questions | What could go wrong, what's undecided? |
| 10 | ADRs | Formal decision records with alternatives analysis |
| 11 | AI/LLM Architecture | How does AI integrate? *(if applicable)* |

---

## Complexity Scaling

Not every project deserves the same depth. Calibrate the document to the system's complexity:

| Complexity | Signals | Document Depth |
|---|---|---|
| **Light** | Single service, CRUD-dominant, no async, no external integrations beyond DB | 5-8 pages. Omit sections 7 (Integration), 8 (Migration), 11 (AI/LLM). Merge 4.2+4.3 into one "Storage" section. Omit 6.3 (Resilience), 6.7 (Accessibility), 6.8 (Data Governance) unless specifically relevant. Keep ADRs to 2-3. Combine sections where there's little to say. |
| **Standard** | Multiple components, some async processing, a few external integrations, auth required | 10-15 pages. Full template. This is the default. |
| **Complex** | Distributed services, event-driven, real-time features, multiple data stores, compliance requirements, AI/LLM integration | 15-25 pages. Full template with deeper treatment. Consider separate D2 diagrams for each major subsystem. Data flow diagrams for all critical paths, not just top 2-3. |

---

## Template

```markdown
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

**Code Structure**: Default Hexagonal (Ports & Adapters). See `references/architecture-patterns.md` for rationale and alternatives.

**Stack**: Per the chosen backend + frontend combination from Step 0. See `references/stack-templates.md` for full details.

**Mobile** (if PRD includes mobile): React Native (Expo). See `references/stack-templates.md` § Mobile for rationale.

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

### 5.4 Disaster Recovery & Business Continuity
- **RTO** (Recovery Time Objective) and **RPO** (Recovery Point Objective) per critical service
- DR pattern: cold / warm / hot standby — justify the choice against cost and RTO
- Backup strategy: what is backed up, frequency, retention, restore testing cadence
- Failover mechanism: automatic vs manual, detection method
- Runbook: link to or outline the incident recovery procedure

### 5.5 Cost Estimation
Estimate infrastructure cost at two scales:
- **Launch** (expected initial traffic): itemize compute, database, storage, third-party APIs, AI inference
- **Growth target** (10x launch): which components scale linearly vs which hit pricing cliffs
- Identify the top 3 cost drivers and the levers available to reduce each
- Flag any components that cost more idle than active (always-on vs scale-to-zero)

---

## 6. Cross-Cutting Concerns

### 6.0 SLA/SLO Definitions
Define measurable targets for the system's critical paths. Without these, observability and alerting have no baseline.
- **Availability SLO**: e.g., 99.9% uptime (8.7h downtime/year)
- **Latency SLO**: e.g., p50 < 100ms, p99 < 500ms for primary API
- **Error budget**: how much failure is tolerable before freezing deployments
- **Business SLOs** (if applicable): e.g., successful payment rate > 99.5%

For each SLO, state: the metric, the threshold, the measurement window, and the alerting condition.

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

### 6.7 Accessibility (if applicable)
- **Compliance target**: WCAG 2.1 AA (default) or AAA — state the target and rationale
- **Automated testing**: Axe-core or similar in CI pipeline to catch regressions
- Component-level accessibility (ARIA, focus management, keyboard navigation) is an implementation concern — note the compliance target here and defer details to the implementation phase

### 6.8 Data Governance (if applicable)
Include when the system handles PII, operates in regulated industries, or includes AI/ML features:
- **Data classification**: What data is collected, sensitivity levels (public, internal, confidential, restricted)
- **Data lineage**: How data flows from ingestion to storage to consumption — who can access what at each stage
- **Retention & deletion**: Per data category — how long is it kept, how is it purged, right-to-erasure compliance
- **Consent management**: How user consent is captured, stored, and enforced across the system
- **AI data governance** (if applicable): Training data provenance, model input/output logging policy, PII masking before LLM calls

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
- **Status**: Proposed | Accepted | Deprecated | Superseded by ADR-{M}
- **Reversibility**: One-way door (irreversible, high analysis) | Two-way door (reversible, decide fast)
- **Context**: What situation motivates this decision?
- **Decision**: What did we decide?
- **Alternatives Considered** (use evaluation matrix for one-way doors):
  | Criterion (weighted) | Option A | Option B | Option C |
  |---|---|---|---|
  | e.g., Latency (30%) | +++ | ++ | + |
  | e.g., Cost (25%) | + | ++ | +++ |
  | e.g., DX (20%) | +++ | ++ | + |
  For two-way doors, a brief prose comparison is sufficient.
- **Consequences**: What are the positive and negative outcomes?
- **Quality Attributes Affected**: Which system qualities change (performance, security, cost, maintainability, etc.)?

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

## Self-Review Checklist

Before presenting the document, verify:

- [ ] Every technology choice has a stated rationale with trade-offs
- [ ] Non-goals are explicit (things you deliberately chose NOT to do)
- [ ] Document length matches complexity tier (Light: 5-8p, Standard: 10-15p, Complex: 15-25p)
- [ ] Cross-cutting concerns (security, observability, error handling, testing) are addressed
- [ ] At least 2 alternatives are considered for each major architectural decision
- [ ] Each ADR classifies decision reversibility (one-way door vs two-way door)
- [ ] SLA/SLO targets are defined for critical paths
- [ ] Cost estimation is included with projections at launch and growth scales
- [ ] DR/BCP strategy addresses RTO/RPO for critical services
- [ ] Data flow is traceable end-to-end for the primary user journeys
- [ ] The document is readable by a senior engineer in 15 minutes

## Quality Bar

The **"3 AM Test"**: If an on-call engineer gets paged at 3 AM for a production issue in this system, can they open this design doc and understand the system well enough to orient themselves within 5 minutes?

If yes, the doc is good enough. If not, it needs more clarity.

## Phase Tagging (optional)

If the input PRD has companion Phase PRDs (`docs/prd-phase-*.md`), write the full architecture for the complete vision but tag sections inline with `[Phase 1]`, `[Phase 2]`, etc. to indicate when each component becomes relevant. Add a brief Phase Implementation Summary at the end. If no Phase PRD exists, omit phase tags entirely.

## Output

Save to `docs/design-doc.md`.

Start the document with a **Table of Contents** (linked to each section heading) right after the title. Long design docs are hard to navigate without one.
