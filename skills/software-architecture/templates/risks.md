# Risks & Open Questions

**Context**: See `docs/arch/context.md` for problem definition and ASRs, `docs/arch/system.md` for architecture, and `docs/arch/adr/` for decision records.

---

# Risk Register

<!-- Seed prompts below mirror the design's highest-leverage non-AI risks — replace with this system's real ones. -->

| Risk | Impact | Probability | Mitigation |
|---|---|---|---|
| e.g. Security: tenant data leak across a trust boundary | ... | ... | STRIDE-surfaced ASR (filter #8) + RLS + per-tenant authz tests |
| e.g. Data: replica lag breaks read-your-writes | ... | ... | Replication topology choice (Stage 6); read-from-leader on critical path |
| e.g. Capacity: traffic spike exceeds modeled QPS | ... | ... | Load test to the ASR p99; autoscale + backpressure |
| e.g. External dependency outage | ... | ... | Timeout + retry budget + graceful degradation (Stage 8) |
| e.g. Write hazard: lost update / double-process | ... | ... | Outbox, idempotency keys, optimistic concurrency |

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
