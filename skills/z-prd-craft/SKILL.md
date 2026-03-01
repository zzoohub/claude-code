---
name: z-prd-craft
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
Airbnb, Stripe, Linear, and Spotify.

## Core Philosophy

A PRD answers **WHAT are we building** and **WHY**. It does NOT answer HOW
(that belongs in technical specs and design docs). A great PRD excites the team
while maintaining rigor.

### The 5 Qualities of an Excellent PRD

1. **Problem-obsessed, not solution-obsessed** — The problem drives everything. A missing feature is never the problem; the pain caused by its absence is.
2. **Quantified** — Every problem and goal has numbers. "Many users churn" → "23% of users churn within 7 days, costing ~$140K/month."
3. **User-centered** — Every requirement maps back to a real user need. Requirements that exist "because stakeholder X asked" get challenged.
4. **Complete yet focused** — Covers the full vision with explicit scope boundaries. MVP scoping belongs in the separate MVP PRD.
5. **Stands the test of time** — Focused on user problems and functional needs, not implementation. Requires minimal updates as design and engineering iterate.

## Step-by-Step PRD Creation Process

### Phase 0: Check for Existing Context

Before discovery, check if a product brief or strategic document already exists
(look for `docs/product-brief.md` or ask the user). If no brief exists and the
scope warrants one, suggest creating a product brief first before proceeding
with the PRD. If one exists, use it as primary context — skip questions the
brief already answers and focus Phase 1 only on filling gaps.

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
6. **Competitive context:** "Are there competitor products or prior internal attempts we should know about?"

Don't ask all of these if answers are already clear from context. Skip what you
know, dig deeper on what's vague. The interview should feel like a conversation
with a sharp PM, not a form to fill out.

**If the user says "just write it" without context:**

A PRD without discovery is a prescription without diagnosis. Offer the
**Problem-User-Success** rapid discovery — just 3 questions:

1. What specific problem are we solving, and for whom?
2. How do users handle this today?
3. What does success look like in numbers?

### Phase 2: Determine PRD Type

**Product PRD** — New products or major product areas. Higher-level, focused on
opportunity and target users.

**Feature PRD** — Specific features on existing products. More detailed
requirements, specific user flows.

### Phase 3: Write the PRD

Use the template below. Adapt depth to complexity. Remove sections that
genuinely don't apply, but err on inclusion.

Read `references/examples.md` for concrete good/bad examples of each section.

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

Write this as if convincing a skeptical VP to fund this work.
Structure in three parts:

**The Problem** — State from the USER's perspective. Quantify impact: users
affected, revenue impact, support costs, churn rate, time wasted. Show evidence:
user research quotes (with sample size), support ticket data, analytics,
competitive gaps.

**Why Now** — This separates "good idea" from "fund this now." What has changed?

- Market shift (competitor launched X, regulation Y takes effect)
- Internal data threshold crossed (churn hit Z%, support costs doubled)
- Technical enabler now available (new platform capability, cost reduction)
- Strategic window (partnership opportunity, seasonal timing)

Without a compelling "why now," even great ideas sit in the backlog forever.

**Evidence Summary** — Consolidate: user research quotes (with n=), analytics
snapshots, support ticket volumes, competitive gaps.

**Anti-pattern check before moving on:**
- Is the "problem" actually a disguised solution? ("We need to build X" is not a problem)
- Is impact quantified with real numbers, not "many" or "some"?
- Is there user evidence, not just stakeholder opinion?

### 3. Target Users & Use Cases

- Define 1-3 primary personas with context, needs, and pain points
- List top 3-5 use cases, ordered by importance
- For each: current journey and what's broken

**Use Jobs-to-be-Done format:**
> "When [situation], I want to [motivation], so I can [expected outcome]."

### 4. Proposed Solution

The bridge between "here's the problem" and "here's what we'll build." This
section should make readers nod and think "yes, that would solve it."

- **Elevator pitch:** 2-3 sentence plain-English description of the solution
- **Core value propositions:** Top 3 benefits for the user, each mapped to a problem from Section 2. If a value prop doesn't trace back to a stated problem, challenge whether it belongs.
- **Mental model:** How should users think about this? What familiar concept or metaphor explains it? (Optional: simple conceptual diagram)

This is the WHAT, not the HOW. Describe the experience, not the implementation.
Be concrete enough for feasibility evaluation, abstract enough for design and
engineering to find the best approach.

### 5. Goals & Success Metrics

Define 2-4 measurable outcomes:

| Goal | Metric | Counter-metric | Target | Timeframe |
|------|--------|----------------|--------|-----------|
| Reduce drop-off | Payment step completion | Support ticket volume | 60%→80% | 3 months |
| Increase conversion | Trial→paid rate | Time-to-value | 12%→18% | 6 months |

**Counter-metrics** guard against gaming (Goodhart's Law). Optimizing one number
often hurts another. Common pairs:

- Speed ↔ Quality (faster completions, but are they correct?)
- Conversion ↔ Retention (more signups, but do they stay?)
- Engagement ↔ Satisfaction (more sessions, but are they happy?)
- Volume ↔ Support cost (more users, but can we serve them?)

**Rules:**
- Each goal has exactly one primary metric
- Targets are specific numbers, not "improve" or "increase"
- Timeframe is realistic

### 6. Functional Requirements

The core of the PRD. List ALL functional requirements for the complete vision.
This is the "parts list." MVP prioritization belongs in the separate MVP PRD.

**Format:** `[REQ-ID] Requirement description`

Use a simple ID scheme (REQ-001, REQ-002) so the MVP PRD can cross-reference.

**Granularity guide:** Each requirement should be independently testable — a QA
engineer could verify it passes or fails.

- Too coarse: "User can manage their account"
- Too fine: "The reset email subject line reads 'Reset your password'"
- Right level: "User can reset their password via email link that expires after 24 hours"

**Writing good requirements:**
- Describe FUNCTIONALITY: "User can reset their password via email"
- Include observability: "Product team can monitor onboarding funnel completion rates"
- Cover the full lifecycle:
  1. Creation / setup / onboarding
  2. Core usage (the primary value loop)
  3. Returning user experience (day 2, week 2)
  4. Management and maintenance (settings, updates)
  5. Edge cases and error states
  6. Off-boarding / data export
- Consider accessibility and internationalization where relevant
- Don't include UI/UX details (→ design documents)
- Don't name specific technologies (→ technical specs)

### 7. User Journeys

Section 6 is the parts list; Section 7 is the assembly instructions. Journeys
show how atomic requirements compose into end-to-end experiences.

**For each key journey:**
- Write as a numbered step sequence
- Focus on WHAT happens, not HOW it looks
- Call out decision points ("If user already has an account → redirect to login")
- Call out error states ("If email is invalid → show inline error, do not advance")
- Note where users might drop off and why
- Prefer progressive disclosure — collect only what's needed at each stage
- Do NOT include wireframes, mockups, or visual specs

### 8. Scope & Non-Goals

- **In scope:** The full product vision (brief list)
- **Out of scope:** What this product will NOT do, with reasoning for each

Name the tempting features you're deliberately not building. Generic non-goals
("things we're not building") add nothing.

### 9. Assumptions, Constraints & Risks

- **Assumptions:** Things believed true but not yet validated
- **Constraints:** Hard limits (timeline, budget, regulatory) — NOT technology choices
- **Risks:** What could go wrong, with severity and mitigation strategy

### 10. Timeline & Milestones (Optional)

High-level milestones with target dates. Detailed sprint planning belongs
elsewhere. The MVP PRD defines specific milestones for the first release.

This section is optional for early-stage PRDs where timing is uncertain. It can
be replaced with a phasing strategy (Phase 1, Phase 2, ...) without dates.

### 11. Appendix

Link to supporting materials (don't inline them):
- User research findings, competitive analysis, technical feasibility, GTM plan

---

## Output Format

**Always produce two separate documents:**

1. **`docs/prd.md`** — Full PRD covering the complete product vision (Sections 1-11)
2. **`docs/prd-mvp.md`** — MVP PRD scoping the first release

For multi-feature projects, use descriptive names: `docs/prd-[feature-slug].md`
to avoid collisions (e.g., `docs/prd-auth.md`, `docs/prd-billing.md`).

Write both in Markdown. Full PRD first, then derive the MVP PRD from it.
Read `references/prd-mvp.md` for the MVP PRD template and scoping principles.

**Formatting rules:**
- Tables for structured data (metrics, requirements, timelines)
- Plain English; avoid jargon unless the audience is technical

## Anti-Patterns

Before finalizing, check against common failure modes.
Read `references/anti-patterns.md` for the full list of anti-patterns with
explanations and fix guidance.

The most critical to catch:
1. **Solution masquerading as a problem** — "We need to build X" is not a problem
2. **The metrics-free zone** — No numbers anywhere
3. **The technical spec in disguise** — Names specific libraries or frameworks
4. **The design document in disguise** — Contains wireframes or UI specs

## PRD Review Mode

When asked to review or improve an existing PRD, read `references/review-checklist.md`
for the full evaluation framework with a weighted scoring rubric (1-10 scale,
anchored with clear definitions). Score each dimension and provide actionable
feedback prioritized by impact.

## Iteration & Feedback

After presenting the initial draft:

- Iterate **section-by-section** rather than rewriting the entire document
- When the user provides feedback, update the specific section and confirm
  the change before moving on
- If feedback reveals a gap in discovery (e.g., "actually the real user is X"),
  update the Problem and Target Users sections first — then cascade changes
  through downstream sections (requirements, journeys, metrics)
- Mark the PRD status as "In Review" during iteration, "Approved" when finalized
