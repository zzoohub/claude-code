---
name: z-prd-craft
description: >
  Write world-class Product Requirements Documents (PRDs) using proven frameworks
  from top product leaders. Use when user asks to "write a PRD", "create a product
  requirements document", "draft product specs", "define product requirements",
  "write a feature spec", "create a product proposal", or mentions PRD, product spec,
  feature requirements, or product planning documents. Also use when user asks to
  "review a PRD" or "improve my PRD". Do NOT use for purely technical specs,
  API documentation, or architecture decision records.
---

# PRD Craft — Framework for Writing World-Class Product Requirements Documents

This skill codifies the PRD writing principles, structures, and quality standards
used by senior PMs at top-tier companies like Airbnb, Stripe, Linear, and Spotify.

## Core Philosophy

A PRD answers two questions: **WHAT are we building** and **WHY are we building it**.
It does NOT answer HOW (that belongs in technical specs). A great PRD excites the
team to build. It reads like a compelling blog post but contains all the rigor of
a formal requirements document.

### The 5 Qualities of an Excellent PRD

1. **Problem-obsessed, not solution-obsessed** — The problem statement drives everything. A missing feature is never the problem; the pain caused by its absence is.
2. **Quantified** — Every problem and goal has numbers. "Many users churn" is weak. "23% of users churn within 7 days, costing ~$140K/month in lost revenue" is strong.
3. **User-centered** — Every requirement maps back to a real user need, use case, or journey. Requirements that exist "because stakeholder X asked" get challenged.
4. **Complete yet focused** — Covers the full product vision with all functional requirements. Scope boundaries are explicit. A separate MVP PRD then identifies the first deliverable subset.
5. **Stands the test of time** — Focused on user problems and functional needs, not implementation details. A well-written PRD requires minimal updates as design and engineering iterate.

## Step-by-Step PRD Creation Process

When the user asks you to write a PRD, follow this process:

### Phase 0: Check for Existing Context

Before starting discovery, check if a product brief or similar strategic document
already exists (look for `docs/product-brief.md` or ask the user). If one exists,
use it as your primary context source — the problem, target users, hypotheses,
and success criteria are likely already defined. Skip discovery questions that
the brief already answers and focus Phase 1 only on filling gaps (detailed use
cases, edge cases, technical constraints, prioritization).

If no brief exists, proceed normally with Phase 1.

### Phase 1: Discovery Interview

Gather critical context by asking the user questions. Present questions
conversationally, not as a wall of text. Adapt based on what the user (or an
existing brief) has already provided — skip questions that are already answered.

**Essential questions (ask what's missing):**

- What specific user or business problem are we solving? What evidence do we have?
- Who are the target users? What are their primary use cases?
- How are users solving this problem today? What's painful about it?
- What does success look like? How will we measure it?
- What constraints exist? (timeline, regulatory, budget)
- What is explicitly OUT of scope?
- Are there competitor products or internal prior attempts we should reference?

**If the user says "just write it" without context:**
Explain that a PRD without discovery is like a prescription without diagnosis.
Offer to do a rapid 3-question discovery: (1) the problem, (2) the user, (3) what success looks like.

### Phase 2: Determine PRD Type

Choose the appropriate format based on scope:

**Product PRD** — For new products or major product areas. Higher-level, focused
on opportunity and target users. Links to Feature PRDs for detailed requirements.
Typically 6-10 pages.

**Feature PRD** — For specific features on existing products. More detailed
requirements, specific user flows. Typically 4-8 pages.

### Phase 3: Write the PRD

Use the structure below. Adapt section depth to the project's complexity.
Remove sections that genuinely don't apply, but err on the side of inclusion.

---

## PRD Template Structure

### 1. Title & Metadata

```
# [Product/Feature Name] — PRD
Status: [Draft | In Review | Approved]
Author: [Name]
Last Updated: [Date]
Stakeholders: [Names and roles]
```

### 2. Problem / Opportunity (MOST CRITICAL SECTION)

Write this section as if you're convincing a skeptical VP to fund this work.

- State the problem from the USER's perspective, not the company's
- Quantify the impact: how many users affected, revenue impact, support cost, churn rate, conversion loss, time wasted
- Show evidence: user research quotes, support ticket data, analytics, competitive gaps
- Explain WHY NOW — what has changed that makes this urgent

**Anti-pattern checklist (verify you avoid these):**
- Do not state a solution as the problem ("We need to build X")
- Do not leave impact unquantified ("Many users are affected")
- Do not use a metric that doesn't reflect actual problem size
- Do not omit user evidence or data

**Good example:**

> "28% of new users abandon onboarding at the payment step (analytics, Jan-Mar 2025).
> User interviews (n=15) reveal the primary friction: users don't trust entering card
> details before experiencing the product. Competitors (Notion, Linear) offer 14-day
> free trials with no payment required. Our current 'pay first' model costs us an
> estimated $340K/month in lost conversions."

### 3. Target Users & Use Cases

- Define 1-3 primary user personas with their context, needs, and pain points
- List the top 3-5 use cases, ordered by importance
- For each use case, briefly describe the current journey and what's broken

**Use the Jobs-to-be-Done format when helpful:**

> "When [situation], I want to [motivation], so I can [expected outcome]."

### 4. Proposed Solution / Elevator Pitch

- 2-3 sentence plain-English description of the solution
- Top 3 value propositions for the user
- Optional: simple conceptual diagram or mental model

**Important:** This is the WHAT, not the HOW. Describe the experience, not the
implementation. Leave room for design and engineering to find the best approach.

### 5. Goals & Success Metrics

Define 2-4 measurable outcomes. Use this format:

| Goal | Metric | Target | Timeframe |
|------|--------|--------|-----------|
| Reduce onboarding drop-off | Payment step completion rate | 60% to 80% | 3 months post-launch |
| Increase trial conversion | Free trial to paid conversion | 12% to 18% | 6 months post-launch |

**Rules for good metrics:**
- Each goal has exactly one primary metric
- Targets are specific numbers, not "improve" or "increase"
- Include a counter-metric to guard against gaming (e.g., if optimizing speed, track quality too)
- Timeframe is realistic

### 6. Functional Requirements

This is the core of the PRD. Describe ALL functional requirements for the complete product vision. Structure by use case or user journey, NOT by technical component. MVP prioritization belongs in the separate MVP PRD document.

**Format each requirement as:**

```
[REQ-ID] Requirement description
```

Use a simple ID scheme (e.g., REQ-001, REQ-002) so the MVP PRD can reference specific requirements.

**Writing good requirements:**
- Focus on FUNCTIONALITY: "User can reset their password via email"
- Include telemetry: "Product team can monitor onboarding funnel completion rates"
- Consider full lifecycle: creation, usage, maintenance, edge cases, deletion
- Don't include UI/UX details, wireframes, or design specifications — these belong in separate design documents
- Don't include implementation details or technology choices: "Store in PostgreSQL with B-tree index", "Built with React and Three.js" — these belong in technical specs
- Don't include performance metrics unless users specifically need them for adoption
- Don't name specific libraries, frameworks, APIs, or tools — describe the capability needed, not how to build it

**Critical User Journeys to consider:**
1. First-time experience (onboarding, setup)
2. Core usage (the primary value loop)
3. Returning user experience (what does day 2, week 2 look like?)
4. Management and maintenance (settings, updates, organization)
5. Edge cases and error states (what can go wrong?)
6. Off-boarding / data export (how does a user leave?)

### 7. User Journeys (Functional)

Describe key user journeys as step-by-step functional flows. These capture the logical sequence of what happens — not how screens look.

**For each journey:**
- Write as a numbered step sequence (e.g., "1. User clicks 'Sign Up' → 2. Enters email → 3. Receives verification → 4. Lands on dashboard")
- Focus on WHAT happens at each step, not HOW it looks
- Call out decision points ("If user already has an account → redirect to login")
- Call out error states ("If email is invalid → show inline error, do not advance")
- Note where the user might drop off or feel friction
- Keep cognitive load in mind: avoid steps that ask for too much at once, prefer progressive disclosure (collect only what's needed at each stage)
- Do NOT include wireframes, mockups, UI layouts, or visual specs — those belong in design documents

### 8. Scope & Non-Goals

Explicitly state what is NOT included. This prevents scope creep and misaligned expectations.

Format:
- **In scope:** [brief list — the full product vision]
- **Out of scope:** [brief list with brief reasoning — things this product will never do]

### 9. Assumptions, Constraints & Risks

- **Assumptions:** Things believed to be true but not yet validated
- **Constraints:** Hard limits (timeline, budget, regulatory). Do NOT list technology choices — those belong in technical specs.
- **Risks:** What could go wrong, with severity and mitigation strategy

### 10. Timeline & Milestones

High-level only. Do NOT create a detailed project plan in the PRD.

- Key milestones with target dates for the full product
- Detailed sprint planning and phase breakdown belong elsewhere
- The MVP PRD will define specific milestones for the first release

### 11. Appendix (Links)

Link to supporting materials rather than inlining them:
- User research findings
- Competitive analysis
- Technical feasibility notes
- Go-to-market plan

---

## PRD Review Mode

When the user asks you to review or improve an existing PRD, evaluate against
these criteria and provide specific, actionable feedback:

### Review Checklist

**Problem Definition (Weight: 30%)**
- Problem stated from user perspective, not company perspective
- Impact is quantified with real numbers
- Evidence provided (research, data, quotes)
- Explains why now
- Does NOT state a solution as the problem

**User Focus (Weight: 20%)**
- Clear target users defined
- Use cases are specific and ordered by priority
- Requirements map back to user needs
- Full user lifecycle considered

**Requirements Quality (Weight: 25%)**
- Focused on functionality, not implementation
- Complete — covers the full product vision, not just MVP
- Edge cases and error states addressed
- Telemetry and measurement included
- Requirements have IDs for MVP PRD cross-referencing

**Completeness (Weight: 15%)**
- Success metrics are specific and measurable
- Scope and non-goals explicitly stated
- Risks and dependencies identified
- Assumptions documented

**Clarity & Persuasiveness (Weight: 10%)**
- Concise — no filler content
- Compelling — would excite a team to build this
- Readable — a new team member could understand it
- Stands alone — doesn't require verbal explanation

### Scoring

Rate the PRD 1-10 with specific justification. Provide the top 3 improvements
that would have the highest impact on PRD quality.

## Output Format

**Always produce two separate documents:**

1. **`prd.md`** — The full PRD covering the complete product vision (Sections 1-11 above)
2. **`mvp-prd.md`** — The MVP PRD that scopes the first release (see MVP PRD section below)

Write both in Markdown. The full PRD is written first; the MVP PRD is derived from it.

**Formatting rules:**
- Use tables for structured data (metrics, requirements, timelines)
- Full PRD: 4-10 pages depending on complexity
- MVP PRD: 2-5 pages (it references the full PRD, so it can be concise)
- Use plain English; avoid jargon unless the audience is technical

## Common PRD Anti-Patterns to Actively Avoid

1. **The Solution Masquerading as a Problem** — "We need to build a notification system" is not a problem. "Users miss 23% of time-sensitive updates because they only check the app once daily" is.

2. **The Vacuous PRD** — Every section filled in but content is meaningless. "Ensure alignment with legal standards" tells nobody anything.

3. **The Novel** — 30+ pages that nobody reads. If your PRD is longer than 10 pages, split it into a Product PRD + linked Feature PRDs.

4. **The Design Document in Disguise** — PRD contains wireframes, UI mockups, layout specs, or UX flows. A PRD defines WHAT to build and WHY, not how it looks. Visual design belongs in separate design documents.

5. **The Technical Spec in Disguise** — PRD names specific libraries, frameworks, APIs, or tools (e.g., "Built with React", "Uses PostgreSQL", "Three.js rendering"). Technology choices are HOW, not WHAT. They belong in technical specs or design docs. The PRD should describe capabilities ("runs in the browser", "real-time physics simulation") not implementation ("Three.js + Rapier WASM").

6. **The Metrics-Free Zone** — No numbers anywhere. No way to know if the product succeeded or failed.

7. **The Everything Bagel** — No clear scope boundaries. The full PRD should describe the complete vision, but scope must be explicit. MVP prioritization belongs in the MVP PRD.

8. **The One-Sided Coin** — Not acknowledging tradeoffs, risks, or downsides of the proposed approach.

9. **The Outdated Artifact** — PRD written once and never updated. A PRD is a living document.

10. **The Missing Competitor** — No awareness of how alternatives solve the same problem. Your solution exists in a competitive context.

11. **The Invisible User** — Requirements that exist because a stakeholder asked, with no evidence of actual user need.

---

## MVP PRD — Scoping the First Release

After writing the full PRD (`prd.md`), create a separate MVP PRD (`mvp-prd.md`) that defines what to build first. The MVP PRD is a companion document that references the full PRD — it does not duplicate content.

### Why a Separate Document?

- The full PRD captures the complete product vision and serves as the long-term source of truth
- The MVP PRD is a tactical scoping decision that answers: "Given the full vision, what is the smallest first release that delivers real user value?"
- Separating them prevents the MVP from shrinking the team's ambition or distorting the product direction

### MVP PRD Template

```
# [Product/Feature Name] — MVP PRD
Status: [Draft | In Review | Approved]
Author: [Name]
Last Updated: [Date]
Full PRD: [link to prd.md]

## 1. MVP Goal

One sentence: what is the single most important outcome this first release must achieve?

## 2. Scoping Rationale

Why this scope? What makes this the right first release? Consider:
- What is the minimum set of requirements that delivers the core user value?
- What technical dependencies force ordering?
- What market timing pressures exist?
- What can we learn from this release that informs Phase 2?

## 3. MVP Requirements

Reference requirements from the full PRD by ID. Assign priority to each.

**Priority definitions:**
- **P0 (Must-have):** Without this, the MVP cannot launch. The target user cannot complete their primary use case.
- **P1 (Should-have):** High-value additions for a minimum delightful product. Important but launch is possible without them.
- **P2 (Nice-to-have):** Enhances experience. Include only if time permits.

| Priority | REQ-ID | Requirement | Rationale for inclusion |
|----------|--------|-------------|----------------------|
| P0 | REQ-001 | [from full PRD] | [why this is essential for MVP] |
| P0 | REQ-003 | [from full PRD] | [why this is essential for MVP] |
| P1 | REQ-005 | [from full PRD] | [why this adds meaningful value] |
| P2 | REQ-008 | [from full PRD] | [nice to have if time permits] |

## 4. What MVP Explicitly Defers

List requirements from the full PRD that are NOT in MVP, with brief reasoning for each.

| REQ-ID | Requirement | Why deferred |
|--------|-------------|-------------|
| REQ-002 | [from full PRD] | [e.g., depends on Phase 1 learnings] |
| REQ-007 | [from full PRD] | [e.g., requires partnership not yet in place] |

## 5. MVP User Journeys

Simplified versions of the full PRD's user journeys, scoped to MVP capabilities only. Note where the MVP journey differs from the full vision.

## 6. MVP Success Criteria

Subset of the full PRD's success metrics, with MVP-specific targets (which may be lower than the full product targets).

| Goal | Metric | MVP Target | Full Product Target |
|------|--------|-----------|-------------------|
| [e.g., Onboarding completion] | [e.g., Completion rate] | [e.g., 50%] | [e.g., 80%] |

## 7. MVP Timeline & Milestones

Specific milestones for the MVP release only.

| Milestone | Target Date | Description |
|-----------|------------|-------------|
| [e.g., Dev complete] | [date] | [description] |
| [e.g., Beta launch] | [date] | [description] |
| [e.g., GA launch] | [date] | [description] |

## 8. MVP Risks

Risks specific to the MVP scope — things that could prevent the first release from shipping or succeeding.
```

### MVP Scoping Principles

1. **Start from the user's primary use case.** The MVP must let the target user complete their most important job. If it can't, it's not viable.
2. **Cut scope, not corners.** Fewer features done well beats many features done poorly. Remove entire capabilities rather than half-building them.
3. **The MVP is not the product.** It's the first step. Don't let MVP constraints permanently reduce the team's ambition — that's what the full PRD protects against.
4. **Every P0 must justify itself.** For each P0 requirement, ask: "If we removed this, could the user still get value?" If yes, it's P1.
5. **Deferred ≠ rejected.** The "What MVP Explicitly Defers" section ensures nothing is silently dropped. Deferred items remain in the full PRD for future phases.
