# Risks & Open Questions

**Context**: See `docs/arch/context.md` for problem definition and ASRs, `docs/arch/system.md` for architecture, and `docs/arch/adr/` for decision records.

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
