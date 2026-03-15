---
name: software-architecture
description: Produce a Software Architecture Design Document from a PRD. Use when the user says "design doc", "software architecture", "system design", "architect this", "architecture design", "tech spec", "how should I build this", "what's the right architecture for", "help me plan the backend", "design the system", "ASR", "utility tree", "domain model", "ATAM", "event storming", or provides a PRD and asks for technical architecture. Also use when the system involves AI/LLM features (RAG, agents, chat, copilot, semantic search). Produces architecture documents covering system context, ASRs, domain model, pattern selection, component design, data architecture, deployment, cross-cutting concerns, and decision records. Produces D2 architecture diagrams. Make sure to use this skill whenever the user wants to plan or structure a new project, even if they don't explicitly say "architecture."
allowed-tools:
  - AskUserQuestion
---

# Software Architect Skill

When given a Product Requirements Document (PRD), produce architecture documents through a 10-stage design flow that captures the system's structure, trade-offs, and rationale.

## Premise

Solopreneur + Claude Code flips traditional architecture methodology:

- **Eliminate**: Team workshops, persuasion docs, onboarding diagrams, convention agreements
- **Strengthen**: Logical rigor of decisions, context-restorable structure (for future self + Claude), fitness functions as automated reviewers

Architecture for **system correctness**, not for persuasion.

## Philosophy

Great architecture documents are **decision records, not implementation manuals**. Every section must answer *why* a choice was made, not just *what* was chosen. If there are no trade-offs to discuss, the section doesn't belong.

**Cost-Aware Architecture**: Infrastructure cost is an architectural constraint on par with performance. Every component justifies its existence against a "what does this cost at low traffic?" test. Prefer scale-to-zero, zero-egress-fee storage, free tiers for development.

**DX as Force Multiplier**: A solo developer's productivity is the binding constraint. Architecture decisions that save 10ms of request latency but add 30 minutes of deployment friction are net negative. Optimize for fast feedback loops.

**The "6-Month Test"**: If you come back to this project after 6 months away, can you read the docs and understand the system well enough to start making changes within 10 minutes? If yes, it's good enough.

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

## Design Flow Overview

| Stage | Name | What It Answers | Output File |
|---|---|---|---|
| 0 | Intake | Who is this for? What constraints exist? | — |
| 1 | Problem Definition | What problem, for whom, why now? | `eng/context.md` §1-2 |
| 2 | ASR Extraction & Utility Tree | Which quality attributes drive the architecture? | `eng/context.md` §3 |
| 3 | Domain Model | What are the core concepts and boundaries? | `eng/context.md` §4 |
| 4 | Pattern Selection & ATAM Gate | What patterns satisfy the architecture drivers? | `eng/design.md` §1 |
| 5 | Component Design & Stack | What are the concrete components? | `eng/design.md` §2 |
| 6 | Data Architecture | Where does data live, how does it flow? | `eng/design.md` §3 |
| 7 | Deployment | How does code get to production? | `eng/design.md` §4 |
| 8 | Cross-cutting Concerns | What properties hold across all components? | `eng/design.md` §5 |
| 9 | ADR & Risk Review | Are all decisions recorded? What could go wrong? | `eng/decisions.md` |

**Stages 2 ↔ 3 ↔ 4 co-evolve** (Twin Peaks model): Domain modeling reveals new ASRs, pattern selection changes domain boundaries. One iteration is usually sufficient at solopreneur scale.

**ADRs are written immediately** when decisions occur — not batched at the end.

See `references/design-flow.md` for detailed methodology for each stage.

---

## Stage 0 — Intake

Use `AskUserQuestion` once to confirm:

- [ ] **Target audience**: Global / Region-specific (specify region — e.g., Korea-first, Japan-first, EU-first)
- [ ] **System boundary scope**: What this system does vs. what's handled externally

Then analyze the PRD and extract architecture-driving requirements:
- Expected scale (users, requests/sec, data volume)
- Latency requirements (real-time needs, p99 targets)
- Consistency model (strong vs eventual, where)
- Regulatory/compliance constraints

If the PRD has clear gaps, ask. Otherwise proceed.

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

---

## Output Structure

The design flow produces three output files:

| File | Stages | Purpose | Template |
|---|---|---|---|
| `eng/context.md` | 0-3 | What and why — problem, ASRs, domain model | `references/templates/context.md` |
| `eng/design.md` | 4-8 | How — patterns, components, data, deployment, cross-cutting | `references/templates/design.md` |
| `eng/decisions.md` | All | Decisions and risks — ADRs, risk register, tech debt | `references/templates/decisions.md` |

Read the template files before writing output. Follow their structure.

---

## Claude Session Guide

For future Claude sessions working on this project:

- **New session** → always load `eng/context.md` first
- **Implementation work** → also load `eng/design.md`
- **Decision point** → append to `eng/decisions.md` immediately

---

## Writing Style

- **Direct and opinionated**. State what you chose and why. Don't hedge excessively.
- **Trade-offs over descriptions**. Every choice should discuss what was gained and what was sacrificed.
- **Concrete over abstract**. "Redis with 15-minute TTL" beats "a caching layer."
- **Diagrams with D2**. Use D2 classes for consistent styling — `person` for actors, `cylinder` for databases, `queue` for message brokers, dashed borders for system boundaries. Minimum: System Context (C4 L1) + Container (C4 L2) diagrams. Invoke the `d2:diagram` skill; if unavailable, use Mermaid or ASCII.
- **No filler**. If you catch yourself writing "it is important to note that" — delete it.
- **Reference real-world precedent** when helpful: "Netflix uses a similar circuit-breaker pattern for their API gateway" adds credibility and context.

---

## Self-Review

Before finalizing, verify:

- [ ] Every [H,H] ASR from the utility tree has a corresponding pattern in the design
- [ ] ATAM gate passed — all [H,H] items verified against chosen patterns
- [ ] Ubiquitous language terms match code terms 1:1
- [ ] Fitness functions defined for key architectural properties (3-5 CI checks)
- [ ] Quality targets have numbers (not "fast" or "reliable" — actual thresholds)
- [ ] Cost estimate exists for launch traffic
- [ ] Every external dependency has a timeout, retry policy, and degradation strategy
- [ ] Data flow is traceable for the main user journey
- [ ] No section exists just because "a design doc should have it" — every section earns its place
- [ ] AI: cost ceiling defined, guardrail layers specified, model versions pinned

**The "6-Month Test"**: If you come back to this project after 6 months away, can you read these docs and understand the system well enough to start making changes within 10 minutes?

---

## Reference Files

Read the relevant references before making architecture decisions.

**`references/design-flow.md`** — Core 10-stage methodology. Detailed process for stages 1-9 including ASR extraction, utility tree, domain modeling, ATAM gate, pattern selection, and cross-cutting concerns. Read this first.

**`references/templates/context.md`** — Template for `eng/context.md` output (stages 0-3): system boundary, problem, ASRs, utility tree, domain model.

**`references/templates/design.md`** — Template for `eng/design.md` output (stages 4-8): patterns, components, data, deployment, cross-cutting concerns.

**`references/templates/decisions.md`** — Template for `eng/decisions.md` output (all stages): ADR format, risk register, tech debt tracking.

**`references/system-architecture.md`** — System architecture patterns (request-response, event-driven, CQRS, event sourcing, saga, modular monolith), composition flowchart, real-world examples, additional patterns (strangler fig, BFF, cell-based, event lakehouse), anti-patterns, and cross-cutting decisions (multi-tenancy, real-time, API versioning, event schema evolution, feature flags).

**`references/service-architecture.md`** — Service architecture patterns for internal service structure: hexagonal (default), clean architecture, vertical slice, functional core/imperative shell. Includes decision guide, in-process domain events, DDD tactical patterns, and anti-patterns.

**`references/stack-templates.md`** — Cloudflare-first stack (Hono + Axum, TanStack Start, Neon/Supabase), language ecosystems (TS and Rust toolchains), shared services, auth patterns, region strategy, and evolution triggers.

**`references/cloudflare-platform.md`** — Full Cloudflare tech stack catalog with priority rankings, compute decision flow, observability implementation guide, and vendor lock-in assessment. Read when designing on the Cloudflare bundle.

**`references/ai-architecture.md`** — LLM integration tiers, RAG architecture, streaming, vector storage, multimodal, cost optimization, guardrails, and observability. Verify current pricing and model capabilities before committing.

**`references/ai-agents.md`** — Agent patterns, protocols (MCP, A2A, AG-UI), context engineering, durable execution, multi-agent systems, safety, and Cloudflare implementation bridge. Read when the system includes autonomous agents or multi-step tool orchestration.

**`references/operational-patterns.md`** — Resilience, file uploads, background jobs, payments & webhooks, caching, rate limiting, and local development. Reference when writing cross-cutting concerns.

**`references/cost-reference.md`** — Service pricing data (free tier + first paid tier), AI/LLM API cost tiers, and solopreneur cost scenarios. **Last verified March 2026** — verify current rates for cost-sensitive decisions.
