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
  Do NOT use for user stories, sprint tickets, technical specs, API documentation,
  or architecture decision records.
---

# PRD Craft — Framework for Writing World-Class PRDs

This skill codifies PRD writing principles from senior PMs at companies like
Airbnb, Stripe, Linear, and Spotify — adapted for solopreneur workflows with
Claude Code.

## Core Philosophy

A PRD answers **WHAT are we building** and **WHY**. It does NOT answer HOW
(that belongs in technical specs and design docs). A great PRD excites the team
while maintaining rigor.

### The 5 Qualities of an Excellent PRD

1. **Problem-obsessed, not solution-obsessed** — The problem drives everything. A missing feature is never the problem; the pain caused by its absence is.
2. **Quantified** — Every problem and goal has numbers. "Many users churn" → "23% of users churn within 7 days, costing ~$140K/month."
3. **User-centered** — Every requirement maps back to a real user need. Requirements that exist "because stakeholder X asked" get challenged.
4. **Complete yet focused** — Covers the full vision with explicit scope boundaries.
5. **Stands the test of time** — Focused on user problems and functional needs, not implementation. Requires minimal updates as design and engineering iterate.

## Output Structure

This skill produces three types of documents:

```
docs/prd/
 ├─ product-brief.md       # Upstream (product-brief skill owns this)
 ├─ prd.md                 # Vision + tech stack + dev order (~300 lines)
 └─ features/
     ├─ auth.md            # Feature spec: requirements, journeys, decisions
     ├─ billing.md
     └─ feed.md

TASKS.md                   # Root-level progress tracking (all features)
```

### Role of Each File

| File | Contains | When Read | When Modified |
|------|----------|-----------|---------------|
| `prd.md` | Vision, tech stack, dev order, success metrics, scope | Every session start | Rarely after initial creation |
| `features/*.md` | Feature-level requirements, user journeys, technical decisions | When working on that feature | When requirements change |
| `TASKS.md` | Task checklists grouped by feature, progress state | Every session start | Every task completion |

## Step-by-Step PRD Creation Process

### Phase 0: Check for Existing Context

Before discovery, check if a product brief already exists (look for
`docs/prd/product-brief.md` or ask the user). The brief is a lightweight alignment
document — it captures the problem summary, direction, and success signal.
If a brief exists, use it as a starting point to accelerate discovery.

### Phase 1: Discovery Interview

Gather context conversationally, not as a question dump. Adapt based on what's
already known.

**How to conduct discovery:**

Start with the problem — it's the foundation everything else builds on. Based
on the user's answer, follow the thread naturally:

1. **Open with the problem:** "What's the specific user or business problem here? What evidence do you have?" If they describe a solution instead of a problem, gently redirect: "That sounds like a potential solution — what's the underlying pain point driving it?"
2. **Understand the user:** "Who experiences this problem most acutely? What are they trying to accomplish?"
3. **Map the current state:** "How do they solve this today? What's painful about that?"
4. **Define success:** "If we nail this, what changes? How would we measure it?"
5. **Scope and constraints:** "What's explicitly out of scope? Any hard constraints — timeline, regulatory, budget?"
6. **Tech stack:** "Any technology decisions already made? Preferred stack?"

Don't ask all of these if answers are already clear from context. Skip what you
know, dig deeper on what's vague.

**If the user says "just write it" without context:**

Offer the **Problem-User-Success** rapid discovery — just 3 questions:

1. What specific problem are we solving, and for whom?
2. How do users handle this today?
3. What does success look like in numbers?

### Phase 2: Write the PRD (`prd.md`)

The PRD is the **vision document** — concise enough to read every session,
comprehensive enough to guide all feature work. Target ~300 lines.

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
Show evidence: user research, support data, analytics, competitive gaps.

**Why Now** — What has changed? Market shift, data threshold crossed,
technical enabler, strategic window.

---

## 2. Target Users

Define 1-3 primary personas with context, needs, and pain points.

**Jobs-to-be-Done:**
> "When [situation], I want to [motivation], so I can [expected outcome]."

---

## 3. Proposed Solution

**Elevator pitch:** 2-3 sentence plain-English description.

**Core value propositions:** Top 3 benefits, each mapped to a problem.

---

## 4. Tech Stack

Technologies, frameworks, and infrastructure decisions.

---

## 5. Success Metrics

| Goal | Metric | Counter-metric | Target | Timeframe |
|------|--------|----------------|--------|-----------|
| ... | ... | ... | ... | ... |

---

## 6. Feature Overview

List all features with one-line descriptions. Each has a detailed spec
in `docs/prd/features/`.

| Feature | Description | Spec |
|---------|-------------|------|
| Auth | Social login + session management | [features/auth.md](features/auth.md) |
| Billing | Stripe subscription management | [features/billing.md](features/billing.md) |

---

## 7. Dev Order

Features ordered by dependency and priority. This replaces phase documents.

### v0.1 — Core (usable state)
1. auth — prerequisite for everything
2. core-feature — without this, not a product
3. landing — user acquisition

### v0.2 — Revenue
4. billing
5. usage-limits

### v0.3 — Growth
6. feed
7. notifications

---

## 8. Scope & Non-Goals

- **In scope:** The full product vision (brief list)
- **Out of scope:** What this product will NOT do, with reasoning

---

## 9. Assumptions, Constraints & Risks

- **Assumptions:** Things believed true but not yet validated
- **Constraints:** Hard limits (timeline, budget, regulatory)
- **Risks:** What could go wrong, with severity and mitigation

---

## 10. Appendix

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

### Phase 4: Generate `TASKS.md`

Create `TASKS.md` at the project root. This is the single source of truth for
progress tracking across all features.

```markdown
# Tasks

## auth
- [ ] Supabase project setup
- [ ] Google OAuth integration
- [ ] GitHub OAuth integration
- [ ] Session expiry handling
- [ ] Protected route middleware

## billing
- [ ] Stripe integration
- [ ] Subscription plan setup
- [ ] Webhook handling

## feed
- [ ] Feed API
- [ ] Infinite scroll
```

**Rules for TASKS.md:**
- One section per feature, matching `docs/prd/features/` filenames
- Tasks ordered by dependency (do top-to-bottom)
- Each task = PR-sized unit (completable in one Claude Code session)
- Check off (`- [x]`) after each task is verified and committed
- Feature sections ordered by dev order from `prd.md`

---

## Anti-Patterns

Before finalizing, check against common failure modes.
Read `references/anti-patterns.md` for the full list.

The most critical to catch:
1. **Solution masquerading as a problem** — "We need to build X" is not a problem
2. **The metrics-free zone** — No numbers anywhere
3. **The technical spec in disguise** — Names specific libraries in requirements (tech stack section is fine)
4. **The design document in disguise** — Contains wireframes or UI specs

## Line Limits

Before updating, check the file's line count. If it exceeds the limit,
consolidate — merge redundant sections, tighten wording, remove resolved
questions — then apply changes.

- `prd.md`: **400 lines**
- `features/*.md`: **200 lines** per feature
- `TASKS.md`: no hard limit (grows with project)

## Iteration & Feedback

After presenting the initial draft:

- Iterate **section-by-section** rather than rewriting the entire document
- When the user provides feedback, update the specific section and confirm
- If feedback reveals a gap in discovery, update Problem and Target Users
  first — then cascade through downstream sections
- When requirements change, update both the feature spec AND TASKS.md
