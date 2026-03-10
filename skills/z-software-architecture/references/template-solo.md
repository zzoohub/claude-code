# Solopreneur Architecture Template

A solopreneur architecture doc is a **decision journal** — it captures what you chose, why, and how things connect. The reader is your future self, 6 months from now, trying to remember why you picked Neon over Supabase or why the auth flow works the way it does.

Target length: **3-6 pages**. If it's longer, you're probably over-documenting. Every section should earn its place — if you have nothing meaningful to say, skip it.

---

## Sections at a Glance

| # | Section | What It Answers |
|---|---|---|
| 1 | Problem & Context | What am I building and why? |
| 2 | Goals & Non-Goals | What's in scope, what's explicitly out? |
| 3 | Architecture | What pattern, what stack, how do pieces connect? |
| 4 | Data | Where does data live, how does it flow? |
| 5 | Infrastructure & Cost | Where does it run, how much does it cost? |
| 6 | Auth & Security | How do users log in, what's locked down? |
| 7 | Observability | How do I know when something breaks? |
| 8 | External Services | What third-party dependencies, what if they break? |
| 9 | AI/LLM Architecture | How does AI integrate? *(only if applicable)* |
| 10 | Risks & Open Questions | What could go wrong, what's undecided? |
| 11 | Key Decisions | Why did I choose X over Y? |

---

## Template

```markdown
# {Project Name} — Architecture Design Doc

**Date**: {date}
**PRD**: {link or title}

---

## 1. Problem & Context

### 1.1 What This Solves
One paragraph. What problem, why now.

### 1.2 System Context
D2 diagram showing the system as a black box: who uses it, what external services it talks to, what data flows in and out.

Use C4 Level 1 thinking. Invoke the `d2:diagram` skill to produce the diagram.

### 1.3 Assumptions
List any assumptions the architecture depends on. If wrong, the architecture may need to change.

---

## 2. Goals & Non-Goals

### Goals
Bulleted. What this system must do. Be specific enough that you can check them off.

### Non-Goals
What you're explicitly not building (yet). This prevents scope creep — future-you will thank present-you.

---

## 3. Architecture

### 3.1 Architecture Style
What pattern and why. For most solo projects this is "Modular Monolith + Request-Response." State that and explain why it fits.

Reference `references/architecture-patterns.md` for the full decision framework.

### 3.2 Stack & Rationale

| Layer | Choice | Why | Considered & Rejected |
|---|---|---|---|
| Backend | e.g., Rust/Axum | ... | ... |
| Frontend | e.g., TanStack Start + SolidJS | ... | ... |
| Database | e.g., Neon | ... | ... |
| Hosting | e.g., Cloud Run + Cloudflare | ... | ... |

Reference `references/stack-templates.md` for full stack details.

### 3.3 Container Diagram
D2 diagram (C4 Level 2) showing major runtime containers. For each container, state what it does and how it communicates with others.

### 3.4 Key Modules
For the backend: what are the main domain modules and how do they relate? Stay at the "what does each module own" level. Don't specify files or classes.

---

## 4. Data

### 4.1 Storage Strategy
For each data store: what it holds, why this storage type, consistency model.

Do NOT define table schemas — that's implementation.

### 4.2 Key Data Flows
Trace 2-3 most important user journeys: where data enters, what transforms happen, where it's stored, where it's read from.

### 4.3 Caching (if needed)
What's cached, why, invalidation approach. Skip if no caching needed.

---

## 5. Infrastructure & Cost

### 5.1 Compute & Deployment
- Where it runs and why
- How code gets from git push to production
- Scaling model (scale-to-zero, auto-scale, etc.)

### 5.2 Cost Estimate

| Component | Launch (~100 DAU) | Growth (~1K DAU) |
|---|---|---|
| Compute | ... | ... |
| Database | ... | ... |
| Storage | ... | ... |
| Third-party APIs | ... | ... |
| **Total** | ... | ... |

Flag anything that costs money while idle. Identify scale-to-zero components vs always-on.

---

## 6. Auth & Security

- Auth flow (who logs in how, token strategy)
- Authorization model (RBAC, etc.)
- Key security measures (encryption, rate limiting, input validation, secret management)

Keep it concise. If it's Google OAuth + JWT + RBAC, say that and move on.

---

## 7. Observability

How you'll know when things break in production. Keep it simple — no distributed tracing or SLO dashboards needed at this stage.

- **Logging**: Structured JSON to stdout. Platform (Cloud Logging / Logpush) handles aggregation.
- **Error tracking**: Sentry — catches unhandled exceptions, gives stack traces with context.
- **Uptime**: Health check endpoint (`GET /health`) + external monitor (e.g., BetterStack, Pinger) to alert when the service is down.

If you're running AI features, also track: token usage per request and cost per user/feature.

---

## 8. External Services

For each third-party dependency:

| Service | Purpose | If It's Down |
|---|---|---|
| e.g., Stripe | Payments | Show "payments temporarily unavailable" |
| e.g., Neon | Database | System offline — no fallback needed for primary DB |

---

## 9. AI/LLM Architecture (if applicable)

Include only if the product has AI features. Cover:
- Integration pattern (direct API, gateway, RAG, agent)
- Streaming approach for user-facing AI
- Cost management strategy (model cascading, caching, batch)
- Key guardrails (input/output validation, PII handling)

Read `references/ai-architecture.md` for detailed patterns. If the system includes agents, also read `references/ai-agents.md`.

---

## 10. Risks & Open Questions

### Risks
| Risk | Impact | What I'll Do |
|---|---|---|
| ... | ... | ... |

### Open Questions
Things you haven't decided yet. For each: what are the options, what do you need to know to decide.

---

## 11. Key Decisions

For each significant choice, a brief record:

### Decision: {Title}
- **Chose**: What you picked
- **Over**: What you considered
- **Because**: The reasoning (1-3 sentences)
- **Revisit when**: What would make you reconsider

Minimum decisions to record:
1. Backend stack
2. Frontend stack
3. Database
4. Architecture pattern (monolith vs services, sync vs async)
5. Auth approach
6. AI integration approach (if applicable)
```

---

## Self-Review

Before finalizing, check:

- [ ] Every technology choice has a "why" and a "what else I considered"
- [ ] Non-goals are listed (prevents future scope creep)
- [ ] Cost estimate exists for launch traffic
- [ ] Data flow is traceable for the main user journey
- [ ] You can re-read this in 15 minutes and understand the full system
- [ ] No section exists just because "a design doc should have it" — every section earns its place

## Quality Bar

The **"6-Month Test"**: If you come back to this project after 6 months away, can you read this doc and understand the system well enough to start making changes within 10 minutes?

If yes, it's good enough. If not, add clarity where you'd be confused.

## Output

Save to `docs/design-doc.md`.
