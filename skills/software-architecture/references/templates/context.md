# Context

**Date**: {date}
**PRD**: {link or title}

---

## 1. System Boundary

What this system does and does not do.

- **Does**: [core capabilities — verb-centric]
- **Does not**: [explicit exclusions — prevents scope creep]
- **External connections**: [systems this integrates with]

D2 system context diagram (C4 Level 1) — the system as a black box showing actors, external systems, and data flows.

---

## 2. Problem

**What problem, for whom, why now** (one paragraph).

### Core User Behaviors

Verb-centric list extracted from the PRD:
- [User] **searches** for [thing]
- [User] **creates** [thing]
- [User] **subscribes** to [thing]

### Success Criteria

| Path | Target | Drives |
|---|---|---|
| e.g., API response (main flow) | p99 < 500ms | Caching? DB query optimization? |
| e.g., Uptime | 99.5% (3.6h downtime/month) | Health checks, alerting, redundancy |
| e.g., Monthly cost at 1K DAU | < $50 | Stack selection, scale-to-zero |

---

## 3. ASR & Utility Tree

### Architecturally Significant Requirements

| # | ASR | Filter | Rationale |
|---|---|---|---|
| 1 | ... | Business risk | ... |
| 2 | ... | Unusual quality | ... |

### Utility Tree

```
System Utility
├── [Quality Attribute]
│   ├── "[Scenario]" [Importance, Difficulty]
│   └── "[Scenario]" [Importance, Difficulty]
└── [Quality Attribute]
    └── "[Scenario]" [Importance, Difficulty]
```

**Architecture drivers** ([H,H] items):
1. ...
2. ...

### AI ASR

| Question | Answer | Drives |
|---|---|---|
| Streaming required? | ... | ... |
| RAG needed? | ... | ... |
| Agent capabilities? | ... | ... |
| Cost ceiling? | ... | ... |
| Hallucination tolerance? | ... | ... |

---

## 4. Domain Model

### Domain Events

Past-tense verbs extracted from PRD:
- UserRegistered
- [Event]
- [Event]

### Bounded Contexts

D2 context map showing bounded contexts and their relationships.

| Context | Owns | Key Entities |
|---|---|---|
| e.g., Identity | Auth, sessions, profiles | User, Session |
| e.g., Billing | Subscriptions, payments | Subscription, Invoice |

### Ubiquitous Language

| Term | Definition | Code Mapping |
|---|---|---|
| ... | ... | `EntityName`, `field_name` |

---

## 5. Constraints

- **Monthly cost ceiling**: ...
- **Regulatory requirements**: ...
- **Platform constraints**: ...

---

## 6. Assumptions

What the architecture depends on being true. If any assumption is invalidated, revisit the affected design decisions.

- ...
- ...
