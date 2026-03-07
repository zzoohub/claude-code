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

### Step 0 — Intake & Clarification

**Complete Step 0 before writing.** Scan the user's prompt for choices already made (e.g., "solo, korea-first, rust/axum, tanstack start"). Extract them, confirm briefly, and only ask what's missing — one question at a time. If all 4 choices are given, skip to Step 0-5.

**Tool note**: Use `AskUserQuestion` for each step. If unavailable, present choices as a numbered list.

**Step 0-1. Project context**
> Call `AskUserQuestion` with these choices:
- **Solo** (solopreneur, indie hacker, side project) — lightweight 3-6 page decision journal
- **Team** (startup team, enterprise, multiple contributors) — comprehensive 10-25 page design doc

This determines which template to use in Step 1.

STOP. Wait for the user's answer. Then proceed to Step 0-2.

**Step 0-2. Target audience**
> Call `AskUserQuestion` with these choices:
- **Global** — Neon (Virginia), Google OAuth, Stripe, us-east region
- **Korea-first** — Supabase (Seoul), Kakao/Naver OAuth, Toss Payments, Seoul region

STOP. Wait for the user's answer. Then proceed to Step 0-3.

**Step 0-3. Backend**
> Call `AskUserQuestion` with these choices. Mark **(Recommended)** based on the requirements.
- **Rust/Axum + GCP Cloud Run** — Performance/cost critical, type safety maximalist (default)
- **Hono + Cloudflare Workers** — Edge-first, fullstack TypeScript, global distribution
- **FastAPI + GCP Cloud Run** — Only when Python-only libraries are required (PyTorch, transformers, etc.)

STOP. Wait for the user's answer. Then proceed to Step 0-4.

**Step 0-4. Frontend**
> Call `AskUserQuestion` with these choices. Mark **(Recommended)** based on the requirements.
- **TanStack Start + SolidJS** — Fine-grained reactivity, smaller bundles, no virtual DOM (default)
- **Next.js (React)** — Rich React ecosystem needed (Radix, shadcn/ui, etc.), SEO-critical content-heavy product, or team has deep React expertise

STOP. Wait for the user's answer. Then proceed to Step 0-5.

**Step 0-5. Clarification**
> Infer from the requirements. Only ask the user if critical information is genuinely missing.

**If Solo**, check for:
1. Expected scale (rough DAU range at launch)
2. Real-time needs (WebSocket, SSE, polling)
3. Regulatory requirements (payments, health data, etc.)

**If Team**, check for:
1. Scale signals (expected users, requests/sec, data volume)
2. Latency requirements (which paths are latency-critical)
3. Consistency model (eventual vs strong, where)
4. Real-time needs (WebSocket, SSE, polling)
5. Multi-tenancy (single vs multi, data isolation)
6. Regulatory (GDPR, CCPA, PCI-DSS, SOC2)

If the requirements cover these, proceed to Step 1. Otherwise ask the missing items first.

### Step 1 — Write the Design Document

Based on the project context from Step 0-1:

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

**`references/architecture-patterns.md`** — System architecture decision framework: patterns (request-response, event-driven, CQRS, event sourcing, modular monolith), language selection, composition flowchart, real-world examples, and anti-patterns.

**`references/stack-templates.md`** — Technology and infrastructure decisions per stack template (Rust/Axum, Hono, FastAPI, TanStack Start, Next.js), shared services, auth patterns, and region strategy.

**`references/design-principles.md`** — Core architecture principles, production incident patterns, security architecture, and observability patterns. Use during self-review to verify your design.

**`references/ai-architecture.md`** — Read if the PRD includes AI-powered features (LLM generation, RAG, semantic search, copilot, chat). Covers LLM integration tiers, RAG architecture, streaming, vector storage, cost optimization, guardrails, and observability. **Important**: verify current pricing and model capabilities before committing.

**`references/ai-agents.md`** — Read if the system includes autonomous agents, multi-step tool orchestration, or human-in-the-loop workflows. Covers agent patterns, protocols (MCP, A2A, AG-UI), context engineering, durable execution, multi-agent systems, and safety.

---

## Output

Save to `docs/design-doc.md`.
