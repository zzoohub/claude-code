# Phase PRD — Template & Scoping Guide

After writing the full PRD (`prd.md`), create a separate Phase PRD (`prd-phase-{n}.md`)
that defines what to build in that phase. This is a companion document — it references
the full PRD, not duplicates it.

---

## Why a Separate Document?

- The full PRD captures the complete vision and serves as the long-term source of truth
- The Phase PRD answers: "Given the full vision, what is the smallest release for this phase that delivers real user value?"
- Separating them prevents phase scoping from shrinking the team's ambition or distorting the product direction

---

## Phase PRD Template

```markdown
# [Product/Feature Name] — Phase {N} PRD
Status: [Draft | In Review | Approved]
Author: [Name]
Last Updated: [Date]
Full PRD: [link to prd.md]

## 1. Phase Goal

One sentence: what is the single most important outcome this phase
must achieve?

## 2. Scoping Rationale

Why this scope? Consider:
- What is the minimum set of requirements that delivers core user value for this phase?
- What technical dependencies force ordering?
- What market timing pressures exist?
- What can we learn from this release that informs Phase {N+1}?

## 3. Phase Requirements

Reference requirements from the full PRD by ID. Assign priority to each.

| Priority | REQ-ID | Requirement | Rationale |
|----------|--------|-------------|-----------|
| P0 | REQ-001 | [from full PRD] | [why essential for this phase] |
| P0 | REQ-003 | [from full PRD] | [why essential for this phase] |
| P1 | REQ-005 | [from full PRD] | [why meaningful value] |
| P2 | REQ-008 | [from full PRD] | [nice to have if time permits] |

## 4. What This Phase Explicitly Defers

| REQ-ID | Requirement | Why Deferred |
|--------|-------------|--------------|
| REQ-002 | [from full PRD] | [e.g., depends on this phase's learnings] |
| REQ-007 | [from full PRD] | [e.g., requires partnership not yet in place] |

## 5. Phase User Journeys

Simplified versions of the full PRD's journeys, scoped to this phase's
capabilities only. Note where the phase journey differs from the full vision.

## 6. Phase Success Criteria

Subset of full PRD's metrics with phase-specific targets (may be lower than
full product targets).

| Goal | Metric | Phase Target | Full Product Target |
|------|--------|--------------|---------------------|
| [e.g., Onboarding] | [e.g., Completion rate] | [e.g., 50%] | [e.g., 80%] |

## 7. Phase Timeline & Milestones

| Milestone | Target Date | Description |
|-----------|-------------|-------------|
| Dev complete | [date] | [description] |
| Beta launch | [date] | [description] |
| GA launch | [date] | [description] |

## 8. Phase Risks

Risks specific to this phase's scope — things that could prevent shipping or
succeeding with this release.
```

---

## Priority Definitions

- **P0 (Must-have):** Without this, the phase cannot launch. The target user cannot complete their primary use case.
- **P1 (Should-have):** High-value for a minimum delightful product. Important but launch is possible without them.
- **P2 (Nice-to-have):** Enhances experience. Include only if time permits.

---

## How to Decide Priority

For each requirement from the full PRD, apply this decision chain:

**Step 1 — The Primary Use Case Test:**
"Can the target user complete their most important job without this?"
- If NO → **P0**
- If YES → continue

**Step 2 — The Delight Test:**
"Would a user trying this for the first time be disappointed if this were
missing?"
- If YES → **P1**
- If NO → continue

**Step 3 — The Deferral Cost Test:**
"Does delaying this make the next phase significantly harder (e.g., data migration,
architectural debt, user habit change)?"
- If YES → **P1**
- If NO → **P2**

When in doubt, defer. Fewer features done well beats many features done poorly.

---

## Scoping Principles

1. **Start from the user's primary use case.** The phase must let the target user complete their most important job. If it can't, it's not viable.

2. **Cut scope, not corners.** Remove entire capabilities rather than half-building them. A polished 3-feature product beats a buggy 8-feature product.

3. **A phase is not the product.** It's one step. Don't let phase constraints permanently reduce the team's ambition — that's what the full PRD protects against.

4. **Every P0 must justify itself.** For each P0 requirement, articulate why the phase fails without it. If you can't, it's P1.

5. **Deferred ≠ rejected.** The "What This Phase Explicitly Defers" section ensures nothing is silently dropped. Deferred items remain in the full PRD for future phases.

---

## Phase-Specific Guidance

The template structure is the same for every phase, but the **emphasis shifts**:

### Phase 1 (First Release)

The product doesn't exist yet. The goal is to **prove the core value hypothesis**.

- **Phase Goal**: Frame as hypothesis validation. "Prove that [target user] gets value from [core experience]."
- **Scoping Rationale**: Emphasize why THIS subset is the minimum viable proof. No existing users or data to reference — justify from first principles and user research.
- **P0 test**: "Can the product exist at all without this?" Infrastructure, core interaction, and analytics are typically P0.
- **Success Criteria**: Focus on viability signals — user acquisition, engagement depth, retention indicators. Targets are estimates (no baseline exists).
- **Risks**: Heavy on feasibility and market risks. "Will this work technically?" "Will anyone care?"

### Phase 2+ (Expansion)

An existing product with users and data exists. The goal is to **expand value based on learnings**.

- **Phase Goal**: Reference what was learned from previous phases. "Based on Phase {N-1} data showing [insight], expand into [new area]."
- **Scoping Rationale**: Cite actual user data from previous phases (retention, feature adoption, feedback). Justify scope with evidence, not assumptions.
- **P0 test**: "Can existing users complete the new use case?" Also consider: "Does this break anything that already works?"
- **Success Criteria**: Baselines exist from previous phases. Set targets relative to actuals. Counter-metrics protect existing engagement.
- **Risks**: Include migration risks (data, UX habits), backward compatibility, and load on existing infrastructure. Less feasibility risk (tech is proven), more execution and adoption risk.
- **Additional section to consider**: "What changed from the original plan" — document deviations from the full PRD based on actual learnings.

---

## Naming Convention

- `docs/prd.md` — Single canonical PRD. Always update in place.
- `docs/prd-phase-{n}.md` — Phase PRDs (e.g., `prd-phase-1.md`, `prd-phase-2.md`)

Do NOT create feature-specific files like `prd-auth.md` or `prd-search.md`. All features belong in the single `prd.md`.
