# MVP PRD — Template & Scoping Guide

After writing the full PRD (`prd.md`), create a separate MVP PRD (`prd-mvp.md`)
that defines what to build first. This is a companion document — it references
the full PRD, not duplicates it.

---

## Why a Separate Document?

- The full PRD captures the complete vision and serves as the long-term source of truth
- The MVP PRD answers: "Given the full vision, what is the smallest first release that delivers real user value?"
- Separating them prevents the MVP from shrinking the team's ambition or distorting the product direction

---

## MVP PRD Template

```markdown
# [Product/Feature Name] — MVP PRD
Status: [Draft | In Review | Approved]
Author: [Name]
Last Updated: [Date]
Full PRD: [link to prd.md]

## 1. MVP Goal

One sentence: what is the single most important outcome this first release
must achieve?

## 2. Scoping Rationale

Why this scope? Consider:
- What is the minimum set of requirements that delivers core user value?
- What technical dependencies force ordering?
- What market timing pressures exist?
- What can we learn from this release that informs Phase 2?

## 3. MVP Requirements

Reference requirements from the full PRD by ID. Assign priority to each.

| Priority | REQ-ID | Requirement | Rationale |
|----------|--------|-------------|-----------|
| P0 | REQ-001 | [from full PRD] | [why essential for MVP] |
| P0 | REQ-003 | [from full PRD] | [why essential for MVP] |
| P1 | REQ-005 | [from full PRD] | [why meaningful value] |
| P2 | REQ-008 | [from full PRD] | [nice to have if time permits] |

## 4. What MVP Explicitly Defers

| REQ-ID | Requirement | Why Deferred |
|--------|-------------|--------------|
| REQ-002 | [from full PRD] | [e.g., depends on Phase 1 learnings] |
| REQ-007 | [from full PRD] | [e.g., requires partnership not yet in place] |

## 5. MVP User Journeys

Simplified versions of the full PRD's journeys, scoped to MVP capabilities
only. Note where the MVP journey differs from the full vision.

## 6. MVP Success Criteria

Subset of full PRD's metrics with MVP-specific targets (may be lower than
full product targets).

| Goal | Metric | MVP Target | Full Product Target |
|------|--------|------------|---------------------|
| [e.g., Onboarding] | [e.g., Completion rate] | [e.g., 50%] | [e.g., 80%] |

## 7. MVP Timeline & Milestones

| Milestone | Target Date | Description |
|-----------|-------------|-------------|
| Dev complete | [date] | [description] |
| Beta launch | [date] | [description] |
| GA launch | [date] | [description] |

## 8. MVP Risks

Risks specific to the MVP scope — things that could prevent shipping or
succeeding with this first release.
```

---

## Priority Definitions

- **P0 (Must-have):** Without this, the MVP cannot launch. The target user cannot complete their primary use case.
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
"Does delaying this make Phase 2 significantly harder (e.g., data migration,
architectural debt, user habit change)?"
- If YES → **P1**
- If NO → **P2**

When in doubt, defer. Fewer features done well beats many features done poorly.

---

## Scoping Principles

1. **Start from the user's primary use case.** The MVP must let the target user complete their most important job. If it can't, it's not viable.

2. **Cut scope, not corners.** Remove entire capabilities rather than half-building them. A polished 3-feature product beats a buggy 8-feature product.

3. **The MVP is not the product.** It's the first step. Don't let MVP constraints permanently reduce the team's ambition — that's what the full PRD protects against.

4. **Every P0 must justify itself.** For each P0 requirement, articulate why the MVP fails without it. If you can't, it's P1.

5. **Deferred ≠ rejected.** The "What MVP Explicitly Defers" section ensures nothing is silently dropped. Deferred items remain in the full PRD for future phases.
