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
  sprint tickets.
---

# Feature Spec — Single Feature on Existing Product

Brownfield counterpart to `prd-craft`. Use when the product already exists
and you need to add a feature without rewriting the vision PRD.

## Prerequisites

`docs/prd/prd.md` must already exist. If it doesn't, the request is for a new
product — use `prd-craft` instead.

If your project keeps PRDs elsewhere, see `AGENTS.md` at the repo root.

## What This Skill Does

1. Reads the existing `docs/prd/prd.md` to understand the product, target users,
   success metrics, and existing feature list — these constrain the new feature's
   shape and naming.
2. Reads existing `docs/prd/features/*.md` to avoid naming conflicts and to
   reference related features.
3. Asks the minimum questions needed to write the spec (problem, journey,
   acceptance — 3 questions max). Skip what's already clear from prd.md or the
   user's request.
4. Writes one new `docs/prd/features/{feature}.md` using the template from
   `prd-craft/references/feature-spec.md`.
5. Patches `docs/prd/prd.md` in place:
   - Appends one row to the **Feature Overview** table (§5)
   - Inserts the feature into **Dev Order** (§6) at the right position
   - Touches §1-4 only if the feature changes the problem framing or success
     metric — usually it doesn't

## What This Skill Does NOT Do

- Does not rewrite the PRD vision
- Does not touch Problem, Target Users, Success Metrics, Proposed Solution
  unless the new feature genuinely changes them (rare)
- Does not create architecture decisions (use `arch-decision`)
- Does not create UX screens (use `screen-design`)
- Does not create tasks (use `task-add`)

## Feature Spec Template

Reuse the template at `prd-craft/references/feature-spec.md`. Same shape:

```markdown
# [Feature Name]

## Overview
Connects this feature to the product vision (1-2 sentences from prd.md problem statement).

## Requirements
Testable, specific. Number them so tasks can reference (R1, R2, ...).

## User Journeys
Step-by-step flows for each user type.

## Edge Cases & Error States
What happens when things go wrong.

## Technical Decisions
Decisions specific to this feature (not architectural — those go in arch-decision).

## Out of Scope
What this feature does NOT do, with rationale.
```

## Workflow

1. **Read context** — `docs/prd/prd.md` + relevant existing `docs/prd/features/*.md`
2. **Discover the feature** — 3 questions max:
   - What user problem does this solve? (must tie back to prd.md problem)
   - What's the core user journey, end-to-end?
   - What does "done" look like — what acceptance defines success?
3. **Draft the spec** — Use the feature-spec template
4. **Patch prd.md** — Append to §5 Feature Overview and §6 Dev Order
5. **Quality check** — see Quality Bar below

## Quality Bar

- [ ] Feature ties back to a problem stated in `prd.md` §1
- [ ] Requirements are numbered, testable, specific
- [ ] At least one full user journey is mapped
- [ ] Edge cases include nil input, empty input, upstream error
- [ ] `prd.md` Feature Overview row added
- [ ] `prd.md` Dev Order updated with the feature at appropriate position
- [ ] Filename matches kebab-case feature name from prd.md

## Output

- `docs/prd/features/{feature}.md` — new file
- `docs/prd/prd.md` — patched (Feature Overview table + Dev Order)

**Line limit:** `docs/prd/features/{feature}.md` — 200 lines. Consolidate if
over.

## Cross-References

- `prd-craft` — Creates the initial PRD; this skill extends it
- `arch-decision` — Records the architectural decisions this feature introduces
- `screen-design` — Designs the UX for screens this feature touches
- `task-add` — Generates implementation tasks once design is done
