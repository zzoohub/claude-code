---
name: feature-spec
description: |
  Write a single feature spec for an existing product. Creates one
  `docs/prd/features/{feature}.md` with requirements, user journeys, edge cases,
  and decisions for the feature. Appends the feature to the existing PRD's
  Feature Overview table and Dev Order WITHOUT rewriting the PRD vision.
  Use when: adding a feature to a product that already has `docs/prd/prd.md`.
  Trigger phrases: "spec out a feature", "write requirements for [feature]",
  "add a feature to the PRD", "feature spec for X".
  Do NOT use for: a new product from scratch (use prd-craft — it creates the
  full PRD plus all feature specs at once). Do NOT use for user stories or
  sprint tickets, breaking the feature into tasks (use task-add), architecture
  decisions (use arch-decision), or screen design (use screen-design).
---

# Feature Spec — Single Feature on Existing Product

Use when the product already exists and you need to add a feature without
rewriting the vision PRD.

## Prerequisites

`docs/prd/prd.md` must already exist.

**If no PRD exists yet**, stop — this is the wrong skill. A single feature spec
with no product vision to anchor it has nothing to tie back to. Tell the user
and route to `prd-craft` (which creates the full PRD plus feature specs), or to
`product-brief` if the idea is still unvalidated.

## What This Skill Does

1. Reads the existing `docs/prd/prd.md` to understand the product, target users,
   success metrics, and existing feature list — these constrain the new feature's
   shape and naming.
2. Reads existing `docs/prd/features/*.md` to avoid naming conflicts and to
   reference related features.
3. Asks the minimum questions needed to write the spec (problem, journey,
   acceptance — ~3 for a typical feature; ask more only if the feature is
   genuinely complex — multiple user types, compliance, cross-feature
   dependencies). Skip what's already clear from prd.md or the user's request.
4. Writes one new `docs/prd/features/{feature}.md` following the template below.
5. Patches `docs/prd/prd.md` in place. Locate sections by **role**, not by fixed
   number (a hand-written or differently-organized PRD may number or title them
   differently; §5/§6 are just the prd-craft default layout):
   - Find the **Feature Overview** table and add a row for the feature. If a row
     for it already exists, **update it in place** — don't append a duplicate.
   - Find the **Dev Order** / roadmap section and insert (or update) the feature
     at the right position.
   - If the PRD has no such table/section, ask the user where to record it rather
     than inventing one.
   - Touch the problem/users/metrics sections only if the feature changes the
     problem framing or success metric — usually it doesn't.

## What This Skill Does NOT Do

- Does not rewrite the PRD vision
- Does not touch Problem, Target Users, Success Metrics, Proposed Solution
  unless the new feature genuinely changes them (rare)
- Does not create architecture decisions
- Does not create UX screens
- Does not create tasks

## Feature Spec Template

Same shape used across feature specs:

```markdown
# [Feature Name]

## Overview
Connects this feature to the product vision (1-2 sentences tied to the PRD's
problem statement).

## Requirements
Testable, specific. Give each a stable ID (`REQ-001`, `REQ-002`, ...) so tasks
and tests can reference it. Format: `REQ-` plus a zero-padded 3-digit sequence.

## User Journeys
Step-by-step flows for each user type.

## Edge Cases & Error States
The failure modes that matter for THIS feature. Cover the relevant categories —
invalid/empty input, unauthorized actor, concurrent or duplicate action,
limit/quota exceeded, upstream/dependency failure, partial success — not a fixed
checklist.

## Technical Decisions
Decisions specific to this feature (not architectural).

## Out of Scope
What this feature does NOT do, with rationale.

## Open Questions
Unknowns still being resolved. Flag them — don't invent answers. Remove as they resolve.
```

## Workflow

1. **Read context** — `docs/prd/prd.md` + relevant existing `docs/prd/features/*.md`
2. **Discover the feature** — ask the questions from "What This Skill Does" step 3:
   - What user problem does this solve? (must tie back to prd.md problem)
   - What's the core user journey, end-to-end?
   - What does "done" look like — what acceptance defines success?
3. **Draft the spec** — Use the feature-spec template; keep it within the 200-line limit
4. **Patch prd.md** — Add (or update, if already present) the feature's Feature
   Overview row and Dev Order entry, locating those sections by role. Check
   prd.md against its 400-line limit first; consolidate if it would exceed.
5. **Quality check** — see Quality Bar below

## Quality Bar

- [ ] Feature ties back to the problem stated in the PRD's problem/opportunity section
- [ ] Requirements are numbered with `REQ-NNN` IDs, testable, specific
- [ ] At least one full user journey is mapped
- [ ] Edge cases cover the failure modes relevant to this feature (invalid/empty input, unauthorized, concurrent/duplicate, limit exceeded, upstream failure, partial success)
- [ ] Open questions are flagged — no invented answers
- [ ] Passes the critical PRD anti-patterns: no solution-as-problem Overview, no library/framework names in Requirements, every requirement has evidence (see `prd-craft/references/anti-patterns.md`)
- [ ] Feature appears exactly once in `prd.md` Feature Overview and once in Dev Order (update in place on re-run, don't duplicate)
- [ ] Filename matches the kebab-case feature name from prd.md

## Output

- `docs/prd/features/{feature}.md` — new file
- `docs/prd/prd.md` — patched (Feature Overview table + Dev Order)

**Line limit:** `docs/prd/features/{feature}.md` — 200 lines. Consolidate if
over.

**Next:** once the spec is approved, the feature flows into the same downstream
stages as any PRD feature — `arch-decision` (if it needs an architecture call),
`screen-design` (if it has UI), then `task-add` to break it into tasks. Routing
hints, not steps this skill performs.
