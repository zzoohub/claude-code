---
name: z-software-architecture
description: Produce a Software Architecture Design Document from a PRD. Use when the user says "design doc", "software architecture", "system design", "architect this", "architecture design", "tech spec", "how should I build this", "what's the right architecture for", "help me plan the backend", "design the system", or provides a PRD and asks for technical architecture. Also use when the system involves AI/LLM features (RAG, agents, chat, copilot, semantic search). Generates a design document covering system context, component architecture, data flow, infrastructure decisions, AI/LLM integration patterns, and key decision records. Produces D2 architecture diagrams and outputs a markdown design doc. Make sure to use this skill whenever the user wants to plan or structure a new project, even if they don't explicitly say "architecture."
---

# Software Architect Skill

When given a Product Requirements Document (PRD), produce a **Design Doc** — a decision record that captures the system's structure, trade-offs, and rationale.

## Philosophy

Great architecture documents are **decision records, not implementation manuals**. Every section must answer *why* a choice was made, not just *what* was chosen. If there are no trade-offs to discuss, the section doesn't belong in this document.

---

## Scope Boundaries

This skill produces architecture-level decisions. It deliberately **excludes** the following — they are separate implementation concerns:

| Excluded Topic | Reason |
|---|---|
| Table schemas, column types, indexes, migrations | Implementation detail — derived from data models in the Design Doc |
| API endpoint lists, request/response shapes | Implementation detail — derived from component interfaces in the Design Doc |
| Folder structure, code conventions, linting rules | Codebase concern — belongs in CLAUDE.md or project config |
| Concrete UI component trees, page layouts | Implementation detail — derived from system context in the Design Doc |

**Note**: API *design philosophy* (REST vs GraphQL, versioning strategy, pagination approach) is an architectural decision and IS covered. What's excluded is the concrete endpoint catalog.

If the user asks for any of the excluded topics, explain that this skill focuses on architecture-level decisions and offer to note it as a requirement for the implementation phase.

---

## Process

### Step 0 — Intake

Use `AskUserQuestion` for each phase. Do not infer or auto-fill.

**Phase 1 — Scope & Audience**
- [ ] **Document scope**: Solo (3-6p decision journal) / Team (10-25p design doc)
- [ ] **Target audience**: Global / Region-specific (specify region — e.g., Korea-first, Japan-first, EU-first)

**Phase 2 — Requirements Extraction**
Analyze the PRD and extract architecture-driving requirements:
- Expected scale (users, requests/sec, data volume)
- Latency requirements (real-time needs, p99 targets)
- Consistency model (strong vs eventual, where)
- Multi-tenancy needs
- Regulatory/compliance constraints
- Quality attribute priorities (see `references/design-principles.md` § Quality Attribute Prioritization)

Ask the user to confirm or fill gaps. For Solo scope, focus on scale, real-time, and regulatory. For Team scope, cover all items above.

**Phase 3 — Bundle & Stack Recommendation**
Based on the requirements analysis, **recommend** a platform bundle with trade-off rationale:
- **Cloudflare bundle** (default): Hono + Workers/CF Containers, TanStack Start + SolidJS, Neon + Hyperdrive
- **Vercel bundle**: Next.js (React), Supabase (Korea-first, content-heavy, React ecosystem)
- **Backend framework**: Hono (TS) / Rust/Axum / FastAPI (Python) — independent of bundle
- **Mobile** (if PRD includes mobile): React Native (Expo)

Mark **(Recommended)** with 1-2 sentence rationale. The user confirms or overrides.

> **Note**: This skill is optimized for the platform bundles above. If the project uses a different stack, apply the same architectural patterns and principles — adjust specific tooling to match the target ecosystem.

### Step 1 — Write the Design Document

Based on the project context from Step 0:

- **Solo** → Read `references/template-solo.md` and follow that template
- **Team** → Read `references/template-team.md` and follow that template

Before writing, also read the relevant reference files listed in the Reference Files section below.

### Step 2 — Self-Review

Each template includes its own self-review checklist. Complete it before presenting the document.

---

## Writing Style

- **Direct and opinionated**. State what you chose and why. Don't hedge excessively.
- **Trade-offs over descriptions**. Every choice should discuss what was gained and what was sacrificed.
- **Concrete over abstract**. "Redis with 15-minute TTL" beats "a caching layer."
- **Diagrams with D2**. Use D2 classes for consistent styling — `person` for actors, `cylinder` for databases, `queue` for message brokers, dashed borders for system boundaries. Minimum: System Context (C4 L1) + Container (C4 L2) diagrams. Invoke the `d2:diagram` skill; if unavailable, use Mermaid or ASCII.
- **No filler**. If you catch yourself writing "it is important to note that" — delete it.
- **Reference real-world precedent** when helpful: "Netflix uses a similar circuit-breaker pattern for their API gateway" adds credibility and context.

---

## Reference Files

Read the relevant references before making architecture decisions.

**`references/template-solo.md`** — Solopreneur design doc template. Lightweight, 3-6 pages, focused on decisions and rationale.

**`references/template-team.md`** — Team/enterprise design doc template. Comprehensive, 10-25 pages, with full cross-cutting concerns, ADRs, and compliance sections.

**`references/architecture-patterns.md`** — System architecture decision framework: patterns (request-response, event-driven, CQRS, event sourcing, modular monolith), language selection, composition flowchart, real-world examples, anti-patterns, and cross-cutting decisions (multi-tenancy, real-time communication, API versioning, feature flags).

**`references/stack-templates.md`** — Platform bundle selection (Cloudflare, Vercel), backend/frontend framework options, shared services, auth patterns, region strategy, and evolution triggers.

**`references/cloudflare-platform.md`** — Detailed Cloudflare bundle tech stack reference with ①② priority rankings per role. Covers compute (Workers, DO, Containers, Agents SDK), storage (Neon+Hyperdrive, R2, KV, D1), AI services, platform services, security, and deploy tooling. Includes a comprehensive **Observability Implementation Guide** with code examples for Sentry on Workers (`withSentry`, `instrumentDurableObjectWithSentry`, `instrumentWorkflowWithSentry`), Workers Automatic Tracing, structured logging (`workers-tagged-logger`), PostHog on Workers, uptime monitoring, alerting, and phased rollout (Day 1 / Growth / Scale). Read when designing on the Cloudflare bundle.

**`references/design-principles.md`** — Core architecture principles, production incident patterns, security architecture, observability patterns, and quality attribute prioritization framework. Use during self-review to verify your design.

**`references/ai-architecture.md`** — Read if the PRD includes AI-powered features (LLM generation, RAG, semantic search, copilot, chat). Covers LLM integration tiers, RAG architecture, streaming, vector storage, cost optimization, guardrails, and observability. **Important**: verify current pricing and model capabilities before committing.

**`references/ai-agents.md`** — Read if the system includes autonomous agents, multi-step tool orchestration, or human-in-the-loop workflows. Covers agent patterns, protocols (MCP, A2A, AG-UI), context engineering, durable execution, multi-agent systems, safety, and a **Cloudflare implementation bridge** mapping abstract patterns to CF Agents SDK, Workflows, and LangGraph.js.

**`references/operational-patterns.md`** — Practical patterns that almost every production system needs: resilience (timeout budgets, retry, graceful degradation), file upload architecture, background jobs decision framework, payments & webhook reliability, and local development environment setup. Reference when writing the External Services & Resilience section.

**`references/cost-reference.md`** — Service pricing data (free tier + first paid tier) for CF services, Neon, Supabase, Sentry, PostHog, Resend, Stripe, Better Auth, Honeycomb. Includes solopreneur cost scenarios at 100 DAU and 1K DAU. **Last verified March 2026** — verify current rates for cost-sensitive decisions.
