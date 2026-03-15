---
name: software-architecture
description: Produce a Software Architecture Design Document from a PRD. Use when the user says "design doc", "software architecture", "system design", "architect this", "architecture design", "tech spec", "how should I build this", "what's the right architecture for", "help me plan the backend", "design the system", or provides a PRD and asks for technical architecture. Also use when the system involves AI/LLM features (RAG, agents, chat, copilot, semantic search). Generates a design document covering system context, component architecture, data flow, infrastructure decisions, AI/LLM integration patterns, and key decision records. Produces D2 architecture diagrams and outputs a markdown design doc. Make sure to use this skill whenever the user wants to plan or structure a new project, even if they don't explicitly say "architecture."
allowed-tools:  
  - AskUserQuestion
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

Use `AskUserQuestion` once to confirm scope and audience. Do not infer these — they affect document depth and DB region.

- [ ] **Document scope**: Solo (3-6p decision journal) / Team (10-25p design doc)
- [ ] **Target audience**: Global / Region-specific (specify region — e.g., Korea-first, Japan-first, EU-first)

Then analyze the PRD and extract architecture-driving requirements:
- Expected scale (users, requests/sec, data volume)
- Latency requirements (real-time needs, p99 targets)
- Consistency model (strong vs eventual, where)
- Multi-tenancy needs
- Regulatory/compliance constraints
- Quality attribute priorities (see `references/design-principles.md` § Quality Attribute Prioritization)

For Solo scope, focus on scale, real-time, and regulatory. For Team scope, cover all items above. If the PRD has clear gaps, ask. Otherwise proceed.

**Stack is auto-decided** from the requirements. Apply these rules:

| Decision | Rule |
|---|---|
| Platform | Cloudflare Workers + CF Containers or Cloud Run. |
| Frontend | TanStack Start (React or SolidJS). SolidJS when PRD demands minimal bundle / fine-grained reactivity; React otherwise. |
| Edge API | Hono (TS). Always for Workers. |
| Container backend | Rust/Axum. Only when PRD requires CPU-intensive processing or long-running containers. |
| DB | Neon + Hyperdrive (global). Supabase via Hyperdrive (Korea-first / Seoul region). |
| Mobile | React Native (Expo). Only when PRD explicitly requires native mobile. |

> **Escape hatch**: FastAPI (Python) only when Python-only ML libraries (PyTorch, transformers) are physically required. State as an ADR if used.

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

**`references/stack-templates.md`** — Cloudflare-first stack (Hono + Axum, TanStack Start, Neon/Supabase), shared services, auth patterns, region strategy, and evolution triggers.

**`references/cloudflare-platform.md`** — Full Cloudflare tech stack catalog with ①② priority rankings, compute decision flow, observability implementation guide, and vendor lock-in assessment. Read when designing on the Cloudflare bundle.

**`references/design-principles.md`** — Core architecture principles, production incident patterns, security architecture, observability patterns, and quality attribute prioritization framework. Use during self-review to verify your design.

**`references/ai-architecture.md`** — Read if the PRD includes AI-powered features. Covers LLM integration tiers, RAG architecture, streaming, vector storage, multimodal, cost optimization, guardrails, and observability. Verify current pricing and model capabilities before committing.

**`references/ai-agents.md`** — Read if the system includes autonomous agents or multi-step tool orchestration. Covers agent patterns, protocols (MCP, A2A, AG-UI), context engineering, durable execution, multi-agent systems, safety, and Cloudflare implementation bridge.

**`references/operational-patterns.md`** — Resilience, file uploads, background jobs, payments & webhooks, caching, rate limiting, and local development. Reference when writing the External Services & Resilience section.

**`references/cost-reference.md`** — Service pricing data (free tier + first paid tier), AI/LLM API cost tiers, and solopreneur cost scenarios. **Last verified March 2026** — verify current rates for cost-sensitive decisions.
