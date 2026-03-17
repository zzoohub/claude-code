---
name: software-architecture
description: Produce a Software Architecture Design Document from a PRD. Use when the user says "design doc", "software architecture", "system design", "architect this", "architecture design", "tech spec", "how should I build this", "what's the right architecture for", "help me plan the backend", "design the system", "ASR", "utility tree", "domain model", "ATAM", "event storming", or provides a PRD and asks for technical architecture. Also use when the system involves AI/LLM features (RAG, agents, chat, copilot, semantic search). Produces architecture documents covering system context, ASRs, domain model, pattern selection, component design, data architecture, deployment, cross-cutting concerns, and decision records. Produces D2 architecture diagrams. Make sure to use this skill whenever the user wants to plan or structure a new project, even if they don't explicitly say "architecture."
---

# Software Architect Skill

When given a Product Requirements Document (PRD), produce architecture documents through a 10-stage design flow that captures the system's structure, trade-offs, and rationale.

## Premise

Architecture for **system correctness**, not for persuasion.

- **Strengthen**: Logical rigor of decisions, context-restorable structure, fitness functions as automated reviewers
- **Eliminate**: Redundant ceremony — sections, diagrams, and documents that don't inform decisions

**The "6-Month Test"**: If you come back to this project after 6 months away, can you read the docs and understand the system well enough to start making changes within 10 minutes? If yes, it's good enough.

## Philosophy

Great architecture documents are **decision records, not implementation manuals**. Every section must answer *why* a choice was made, not just *what* was chosen. If there are no trade-offs to discuss, the section doesn't belong.

---

## Scope Boundaries

This skill produces architecture-level decisions. It deliberately **excludes** the following — they are separate implementation concerns:

| Excluded Topic | Reason |
|---|---|
| Table schemas, column types, indexes, migrations | Implementation detail — derived from data models in the Design Doc |
| API endpoint lists, request/response shapes | Implementation detail — derived from component interfaces in the Design Doc |
| Folder structure, code conventions, linting rules | Codebase concern — belongs in CLAUDE.md or project config |
| Concrete UI component trees, page layouts | Implementation detail — derived from system context in the Design Doc |

**Note**: API *design philosophy* and observability *strategy* are architectural decisions and ARE covered. What's excluded is the concrete endpoint catalog and boilerplate implementation code.

---

## Design Flow Overview

| Stage | Name | What It Answers | Output File |
|---|---|---|---|
| 0 | Auto-Classification | What type of software? What dimensions matter? | — |
| 1 | Problem Definition | What problem, for whom, why now? | `arch/context.md` §1-2 |
| 2 | ASR Extraction & Utility Tree | Which quality attributes drive the architecture? | `arch/context.md` §3 |
| 3 | Domain Model | What are the core concepts and boundaries? | `arch/context.md` §4 |
| 4 | Pattern Selection & ATAM Gate | What patterns satisfy the architecture drivers? | `arch/system.md` §1 |
| 5 | Component Design | What are the concrete components? | `arch/system.md` §2 |
| 6 | Data Architecture | Where does data live, how does it flow? | `arch/system.md` §3 |
| 7 | Deployment | How does code get to production? | `arch/system.md` §4 |
| 8 | Cross-cutting Concerns | What properties hold across all components? | `arch/system.md` §5 |
| 9 | ADR & Risk Review | Are all decisions recorded? What could go wrong? | `arch/decisions.md` |

**Stages 2 <-> 3 <-> 4 co-evolve** (Twin Peaks model): Domain modeling reveals new ASRs, pattern selection changes domain boundaries. One iteration is usually sufficient.

**ADRs are written immediately** when decisions occur — not batched at the end.

See `references/design-flow.md` for detailed methodology for each stage.

---

## Stage 0 — Auto-Classification

Analyze the PRD and classify the software automatically. No user questions — derive everything from the PRD.

### Software Type Classification

| Type | PRD Signals | Architecture Implications |
|---|---|---|
| Web application | users, pages, dashboard, sign up | Client-server, sessions, rendering strategy |
| API service | endpoints, consumers, rate limits | Interface design, versioning, SLA |
| CLI tool | command, flags, terminal, output | Argument parsing, stdio, exit codes |
| Library/SDK | import, package, API surface | Public API, compatibility, dependency policy |
| Data pipeline | ingest, transform, ETL, batch | Throughput, fault tolerance, idempotency |
| Mobile app | iOS, Android, push, offline | Offline-first, sync strategy |
| Desktop app | native, installer, file system | Distribution, auto-update, OS integration |
| Game | real-time, state sync, tick rate | Determinism, netcode, asset pipeline |
| Embedded/IoT | device, firmware, constrained | Resource constraints, OTA, communication protocol |

### Architecture Dimensions (Auto-Extract)

From the PRD, extract:
- **System boundary** — what this system does vs. what's handled externally
- **Expected scale** — users, requests/sec, data volume, or "single-user tool"
- **Latency requirements** — real-time needs, p99 targets
- **Consistency model** — strong vs eventual, where
- **Deployment constraints** — target environment, distribution method
- **Regulatory/compliance** — data residency, audit requirements
- **AI/LLM features** — whether the system includes AI capabilities

If the PRD has critical gaps that block architecture decisions, note them as assumptions in the output.

---

## Output Structure

The design flow produces three output files:

| File | Stages | Purpose | Template |
|---|---|---|---|
| `arch/context.md` | 0-3 | What and why — problem, ASRs, domain model | `references/templates/context.md` |
| `arch/system.md` | 4-8 | How — patterns, components, data, deployment, cross-cutting | `references/templates/system.md` |
| `arch/decisions.md` | All | Decisions and risks — ADRs, risk register, tech debt | `references/templates/decisions.md` |

Read the template files before writing output. Follow their structure.

---

## Claude Session Guide

For future Claude sessions working on this project:

- **New session** -> always load `arch/context.md` first
- **Implementation work** -> also load `arch/system.md`
- **Decision point** -> append to `arch/decisions.md` immediately

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
- [ ] Cost estimate exists for at least one traffic level
- [ ] Every external dependency has a timeout, retry policy, and degradation strategy
- [ ] Data flow is traceable for the main user journey
- [ ] No section exists just because "a design doc should have it" — every section earns its place
- [ ] AI (if applicable): cost ceiling defined, guardrail layers specified, model versions pinned

**The "6-Month Test"**: If you come back to this project after 6 months away, can you read these docs and understand the system well enough to start making changes within 10 minutes?

---

## Reference Files

### Reading Order

**Always read**: `design-flow.md` + all three templates.

**Read based on Stage 0 findings**:
- Pattern selection -> `system-architecture.md`, `service-architecture.md`
- AI features in PRD -> `ai-architecture.md` (+ `ai-agents.md` if agents needed)
- Cross-cutting -> `operational-patterns.md`

**Skip if PRD has no AI/LLM features**: `ai-architecture.md`, `ai-agents.md`

### Index

| File | Content |
|---|---|
| `references/design-flow.md` | 10-stage methodology (stages 1-9). **Read first.** |
| `references/templates/*.md` | Output templates for `arch/context.md`, `arch/system.md`, `arch/decisions.md` |
| `references/system-architecture.md` | System patterns, composition flowchart, real-world examples |
| `references/service-architecture.md` | Internal service structure: hexagonal (default), clean, vertical slice, FC/IS |
| `references/ai-architecture.md` | LLM integration, RAG, streaming, vector storage, guardrails |
| `references/ai-agents.md` | Agent patterns, protocols (MCP/A2A/AG-UI), durable execution, safety |
| `references/tech-stack.md` | Pre-vetted technology options — language, framework, infra, data, AI, services |
| `references/operational-patterns.md` | Resilience, background jobs, caching, rate limiting |
