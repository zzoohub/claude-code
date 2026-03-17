# Architecture

**Date**: {date}
**Context**: See `arch/context.md` for problem definition, ASRs, and domain model.

---

## 1. Patterns

### System Pattern

**Chosen**: [pattern] — [one-line why]

ATAM verification against [H,H] ASRs:

| ASR (from utility tree) | How this pattern satisfies it | Sensitivity point | Trade-off |
|---|---|---|---|
| ... | ... | ... | ... |

### Service Pattern

**Chosen**: [pattern] — [one-line why]

### AI Pattern

**Chosen**: [pattern] — [one-line why]

---

## 2. Components

### Core Technology

<!-- Adapt rows based on software type. Not all systems have all layers. -->

| Concern | Choice | Why | Rejected |
|---|---|---|---|
| Core runtime | ... | ... | ... |
| Data store | ... | ... | ... |
| Communication | ... | ... | ... |
<!-- conditional: add rows as needed for the specific system type -->

### Container Diagram

D2 diagram (C4 Level 2) showing major runtime containers, communication protocols, and external integrations.

### Key Modules

| Module | Owns | Ports |
|---|---|---|
| ... | ... | ... |

### AI Components
<!-- Include only if PRD involves AI/LLM features -->

| Component | Responsibility | Key decisions |
|---|---|---|
| LLM Gateway | Model routing, caching, cost tracking | ... |
| Embedding Pipeline | Chunking, embedding, vector store writes | ... |
| Eval Pipeline | Quality measurement, regression detection | ... |

---

## 3. Data

### Storage Strategy

| Store | Holds | Why This Type | Consistency |
|---|---|---|---|
| ... | ... | ... | ... |

### Key Data Flows

Trace 2-3 critical user journeys:

**[Flow name]**: [step-by-step data path]

### Caching (if needed)

What's cached, why, invalidation approach, stampede prevention.

### AI Data
<!-- Include only if PRD involves AI/LLM features -->

| Concern | Strategy |
|---|---|
| Chunking | [approach, chunk size, overlap %] |
| Search | [dense / BM25 / hybrid] |
| Context window budget | System prompt: N tokens + Retrieved: N tokens + History: N tokens + Output: N tokens = Total |

---

## 4. Deployment & Cost

### CI/CD Pipeline

test -> lint -> security scan -> build -> smoke test -> deploy

### Scaling Model

[Scale-to-zero / auto-scale / always-on / single-instance] — [rationale]

### Cost Estimate

<!-- Use two traffic levels relevant to the system -->

| Component | Baseline | Growth |
|---|---|---|
| Compute | ... | ... |
| Database | ... | ... |
| Storage | ... | ... |
| Third-party APIs | ... | ... |
| **Total** | ... | ... |

Components that cost money while idle: [list or "none"]

### AI Ops
<!-- Include only if PRD involves AI/LLM features -->

| Model | Version (pinned) | Cost per 1K tokens | Fallback |
|---|---|---|---|
| ... | ... | ... | ... |

Cost alerting threshold: [80% of ceiling from ASR]

---

## 5. Cross-cutting

### Fitness Functions

| Property | Check | CI Location |
|---|---|---|
| No circular deps | `madge --circular` | Pre-commit |
| Domain independence | Import rules | CI |
| Response time | Performance test | Post-deploy |

### Auth & Security
<!-- Include if users exist -->

- Auth flow: [how users authenticate]
- Authorization: [RBAC / ABAC / etc.]
- Security layers: Edge -> Transport -> Auth -> AuthZ -> Data -> Audit

### Observability — Day 1

- **Error tracking**: [tool choice]
- **Structured logging**: JSON to stdout with correlation IDs
- **Health checks**: [endpoint or mechanism]
- **Uptime monitoring**: [tool choice]

### Resilience

| Service | Timeout | Retry | If Down |
|---|---|---|---|
| ... | ... | ... | ... |

### AI Security
<!-- Include only if PRD involves AI/LLM features -->

3-layer defense:
1. **Input**: [classification, PII detection, injection detection]
2. **RAG trust**: [source validation, content sanitization]
3. **Output**: [schema validation, content filtering, hallucination detection]

### AI Observability
<!-- Include only if PRD involves AI/LLM features -->

| Metric | Target | Alert |
|---|---|---|
| Time to first token (TTFT) | < 2s | > 5s |
| Cost per request | < $X | Daily budget > 80% |
| Guardrail trigger rate | < 5% | > 10% |
| RAG relevance score | > 0.7 | < 0.5 |
