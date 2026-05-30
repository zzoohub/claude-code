# Mode Quick Reference

Loaded by `plan-ceo-review`. Behavior matrix for the three modes. The per-section deltas in `references/review-sections.md` are the source of truth; this table is a lookup.

| | EXPANSION | HOLD SCOPE | REDUCTION |
|---|---|---|---|
| Scope | Push UP | Maintain | Push DOWN |
| 10x check | Mandatory | Optional | Skip |
| Platonic ideal | Yes | No | No |
| Delight opps | 5+ items | Note if seen | Skip |
| Complexity question | "Is it big enough?" | "Is it too complex?" | "Is it the bare minimum?" |
| Taste calibration | Yes | No | No |
| Temporal interrogate | Full (hr 1-6) | Key decisions only | Skip |
| Observability standard | "Joy to operate" | "Can we debug it?" | "Can we see if it's broken?" |
| Deploy standard | Infra as feature scope | Safe deploy + rollback | Simplest possible deploy |
| Error map | Full + chaos scenarios | Full | Critical paths only |
| Phase 2/3 planning | Map it | Note it | Skip |

Minimal-diff note: in EXPANSION, "minimal diff" constrains HOW each chosen capability is built, not WHETHER to add scope. In HOLD/REDUCTION it constrains both.

Error-map note: REDUCTION maps only critical paths, but the deterministic `RESCUED=N AND TEST=N AND Silent → CRITICAL GAP` gate still applies to whatever IS mapped — never soften it (see `references/required-outputs.md`).
