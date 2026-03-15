# Decision Log

**Context**: See `arch/context.md` for problem definition and ASRs. See `arch/design.md` for architecture.

<!-- Newest first. ADRs are written immediately when decisions occur, not batched at end. -->

---

## ADR-NNN: [Title] — YYYY-MM-DD

- **Stage**: [which design stage produced this decision]
- **Door**: One-way (irreversible) | Two-way (reversible)
- **Context**: [the situation and forces at play]
- **Decision**: [what was chosen]
- **Why**: [reasoning — reference quality attributes from utility tree]
- **Rejected**: [alternatives and why not]
- **Tradeoff**: [positive and negative consequences]
- **Revisit when**: [trigger for reconsideration]

---

## Minimum ADRs to record:

1. System architecture pattern
2. Service architecture pattern
3. Backend stack
4. Frontend stack
5. Database
6. Auth approach
7. AI integration approach

---

# Risk Register

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| ... | ... | ... | ... |

## AI Risks
<!-- Include only if PRD involves AI/LLM features -->

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| Hallucination in critical output | ... | ... | Schema validation, citations, human review |
| Model deprecation | ... | ... | Version pinning, abstraction layer, eval suite |
| Vendor lock-in | ... | ... | LLM Gateway pattern, standardized prompt format |
| Cost explosion | ... | ... | Per-request tracking, daily budget alerts, model cascading |
| RAG poisoning | ... | ... | Source trust scoring, content validation |

---

# Tech Debt

| Item | When | Priority | Resolution Condition |
|---|---|---|---|
| ... | ... | ... | ... |

---

# Open Questions

| Question | Options | Info Needed to Decide |
|---|---|---|
| ... | ... | ... |
