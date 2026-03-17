---
name: prd-craft
description: >
  Write world-class Product Requirements Documents (PRDs) using proven frameworks
  from top product leaders. Use when user asks to "write a PRD", "create a product
  requirements document", "draft product specs", "define product requirements",
  "write a feature spec", "create a product proposal", "spec out a feature",
  "write requirements for [feature]", or mentions PRD, product spec, feature
  requirements, or product planning documents. Also use when user asks to
  "review a PRD", "improve my PRD", "audit my PRD", or "give feedback on my PRD".
  Even if the user doesn't say "PRD" explicitly, trigger this skill when they're
  describing what a product should do and need a structured requirements document.
  Do NOT use for user stories, sprint tickets, API documentation, or architecture decision records.
---

# PRD Craft — Framework for Writing World-Class PRDs

A PRD defines what to build and why. It works for any product — tools, apps, games, libraries, services.

## Core Philosophy

A PRD answers **WHAT are we building** and **WHY**. It does NOT answer HOW
(that belongs in technical specs and design docs).

### The 5 Qualities of an Excellent PRD

1. **Problem-obsessed** — The problem drives everything. A missing feature is never the problem; the pain caused by its absence is.
2. **Quantified** — Every problem and goal has numbers. "Slow" → "takes 10 minutes of manual work per run."
3. **User-centered** — Every requirement maps back to a real need. Requirements without evidence get challenged.
4. **Complete yet focused** — Covers the full vision with explicit scope boundaries.
5. **Stands the test of time** — Focused on problems and functional needs, not implementation.

## Output Structure

```
docs/prd/
 ├─ product-brief.md       # Upstream (product-brief skill owns this)
 ├─ prd.md                 # Vision + requirements + dev order (~300 lines)
 └─ features/
     └─ [feature].md       # Feature spec: requirements, journeys, decisions
```

**Every file is a single source of truth (SSOT).** If a file already exists, update it in place — never create duplicates. The file should always reflect the latest state.

### Role of Each File

| File | Contains | When Read | When Modified |
|------|----------|-----------|---------------|
| `prd.md` | Vision, constraints, dev order, success metrics, scope | Every session start | When direction, scope, or priorities change |
| `features/*.md` | Feature-level requirements, user journeys, technical decisions | When working on that feature | When requirements change |

## Complexity Calibration

Scale document depth to your product's complexity.

**Signals:** users (yourself / team / external), scope (single feature / multi-feature), state (local / distributed), longevity (experiment / long-term)

- **Lightweight** (personal tool, single-purpose CLI, experiment): prd.md 100-150 lines, feature specs optional, success signal 1-2 sentences
- **Moderate** (team tool, multi-feature app): prd.md 200-300 lines, feature specs per feature, bullet-point metrics
- **Large** (external users, complex state, many features): prd.md ~300 lines, full feature specs, metrics table with targets and timeframes

## Step-by-Step PRD Creation Process

### Phase 0: Check for Existing Context

Before discovery, check if a product brief already exists (look for
`docs/prd/product-brief.md` or ask the user). If a brief exists, use it as a
starting point to accelerate discovery.

### Phase 1: Discovery Interview

Gather context conversationally, not as a question dump. Adapt based on what's
already known.

**How to conduct discovery:**

Start with the problem — it's the foundation everything else builds on. Based
on the user's answer, follow the thread naturally:

1. **Open with the problem:** "What's the specific problem here? What evidence do you have?" If they describe a solution instead of a problem, gently redirect: "That sounds like a potential solution — what's the underlying pain point driving it?"
2. **Understand the user:** "Who experiences this problem most acutely? What are they trying to accomplish?"
3. **Map the current state:** "How is this handled today? What's painful about that?"
4. **Define success:** "If we nail this, what changes? How would we know it's working?"
5. **Scope and constraints:** "What's explicitly out of scope? Any hard constraints — regulatory, performance, compatibility? Existing systems this must work with?"

Don't ask all of these if answers are already clear from context. Skip what you
know, dig deeper on what's vague.

**If the user says "just write it" without context:**

Offer the **Problem-User-Success** rapid discovery — just 3 questions:

1. What specific problem are we solving, and for whom?
2. How is this handled today?
3. What does success look like?

### Phase 2: Write the PRD (`prd.md`)

The PRD is the **vision document** — concise enough to read every session,
comprehensive enough to guide all feature work. Target ~300 lines (scale down
for lightweight products per Complexity Calibration).

Read `references/examples.md` for concrete good/bad examples.

---

## PRD Template (`docs/prd/prd.md`)

```markdown
# [Product Name] — PRD

**Status:** [Draft | In Review | Approved]
**Author:** [Name]
**Last Updated:** [Date]

---

## Table of Contents
(linked to each section)

---

## 1. Problem / Opportunity

**The Problem** — State from the USER's perspective. Quantify impact.
Show evidence: observed pain, time wasted, errors encountered, existing
tool limitations.

**Why Now** — What has changed? New capability, pain threshold crossed,
dependency unblocked, opportunity window.

---

## 2. Target Users

Who has this problem, and in what situation?

For personal/team tools, a sentence or two is enough.
For products with multiple user types, define personas with context and needs.

**Jobs-to-be-Done:**
> "When [situation], I want to [motivation], so I can [expected outcome]."

---

## 3. Proposed Solution

**Elevator pitch:** 2-3 sentence plain-English description.

**Core value propositions:** Top 3 benefits, each mapped to a problem.

---

## 4. Success Metrics

Scale to complexity:

Lightweight — a sentence or two:
> "I reach for this instead of the manual process at least 3x/week."

Moderate — bullet points:
> - Processes files in under 5 seconds for typical inputs
> - Zero silent data loss — every error reported with location
> - Adopted by 3+ team members within first month

Large — full table:
| Goal | Metric | Counter-metric | Target | Timeframe |
|------|--------|----------------|--------|-----------|
| ... | ... | ... | ... | ... |

---

## 5. Feature Overview

List all features with one-line descriptions. Each has a detailed spec
in `docs/prd/features/`.

| Feature | Description | Spec |
|---------|-------------|------|
| file-parser | Read and validate input files | [features/file-parser.md](features/file-parser.md) |
| transform-engine | Apply transformation rules to parsed data | [features/transform-engine.md](features/transform-engine.md) |

---

## 6. Dev Order

Features ordered by dependency and priority.

### v0.1 — Core (minimum usable state)
1. file-parser — everything depends on parsed input
2. transform-engine — core value of the tool

### v0.2 — Workflow
3. config-loader — user-defined rules
4. output-formatter — multiple output formats

### v0.3 — Polish
5. error-reporting — detailed diagnostics
6. watch-mode — re-run on file changes

---

## 7. Scope & Non-Goals

- **In scope:** The full product vision (brief list)
- **Out of scope:** What this product will NOT do, with reasoning

---

## 8. Assumptions, Constraints & Risks

- **Assumptions:** Things believed true but not yet validated
- **Constraints:** Hard limits (performance, compatibility, platform)
- **Risks:** What could go wrong, with severity and mitigation

---

## 9. Appendix

Links to supporting materials (don't inline them).
```

### Phase 3: Extract Features into Specs

For each feature listed in the PRD, create a spec file in `docs/prd/features/`.

Read `references/feature-spec.md` for the feature spec template.

Each feature file contains:
- Overview and context
- Functional requirements (testable, specific)
- User journeys (step-by-step flows)
- Technical decisions specific to this feature
- Edge cases and error states

---

## Anti-Patterns

Before finalizing, check against common failure modes.
Read `references/anti-patterns.md` for the full list.

The most critical to catch:
1. **Solution masquerading as a problem** — "We need to build X" is not a problem
2. **The metrics-free zone** — No numbers anywhere
3. **The technical spec in disguise** — Names specific libraries or frameworks in requirements (tech stack belongs in the architecture design doc)
4. **The design document in disguise** — Contains wireframes or UI specs

## Line Limits

Before updating, check the file's line count. If it exceeds the limit,
consolidate — merge redundant sections, tighten wording, remove resolved
questions — then apply changes.

- `prd.md`: **400 lines**
- `features/*.md`: **200 lines** per feature

## Iteration & Feedback

After presenting the initial draft:

- Iterate **section-by-section** rather than rewriting the entire document
- When the user provides feedback, update the specific section and confirm
- If feedback reveals a gap in discovery, update Problem and Target Users
  first — then cascade through downstream sections
- When requirements change, update the feature spec
