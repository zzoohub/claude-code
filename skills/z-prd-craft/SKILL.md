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
4. **Appropriately scoped** — Covers MVP with clear prioritization (P0/P1/P2). Does not attempt to solve everything. Phases beyond MVP+1 are directional only.
5. **Stands the test of time** — Focused on user problems and functional needs, not implementation details. A well-written PRD requires minimal updates as design and engineering iterate.

## Step-by-Step PRD Creation Process

When the user asks you to write a PRD, follow this process:

### Phase 1: Discovery Interview

Before writing anything, gather critical context by asking the user these questions.
Do NOT skip this phase. Present questions conversationally, not as a wall of text.
Adapt based on what the user has already provided.

**Essential questions (ask what's missing):**

- What specific user or business problem are we solving? What evidence do we have?
- Who are the target users? What are their primary use cases?
- How are users solving this problem today? What's painful about it?
- What does success look like? How will we measure it?
- What constraints exist? (timeline, tech, regulatory, budget)
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

### 6. Functional Requirements (MVP)

This is the core of the PRD. Structure requirements by use case or user journey,
NOT by technical component.

**Format each requirement as:**

```
[Priority] Requirement description
```

**Priority definitions:**
- **P0 (Must-have):** Required for MVP. Product cannot launch without this. If you removed it, the target user cannot complete their primary use case.
- **P1 (Should-have):** High-value additions for a minimum delightful product. Important but launch is possible without them.
- **P2 (Nice-to-have):** Enhances experience but not critical. Can be deferred.

**Writing good requirements:**
- Focus on FUNCTIONALITY: "User can reset their password via email"
- Include telemetry: "Product team can monitor onboarding funnel completion rates"
- Consider full lifecycle: creation, usage, maintenance, edge cases, deletion
- Don't include UI/UX details, wireframes, or design specifications — these belong in separate design documents
- Don't include implementation details: "Store in PostgreSQL with B-tree index"
- Don't include performance metrics unless users specifically need them for adoption

**Critical User Journeys to consider:**
1. First-time experience (onboarding, setup)
2. Core usage (the primary value loop)
3. Returning user experience (what does day 2, week 2 look like?)
4. Management and maintenance (settings, updates, organization)
5. Edge cases and error states (what can go wrong?)
6. Off-boarding / data export (how does a user leave?)

### 7. User Journeys (Functional)

**MANDATORY: Before writing this section, you MUST invoke the `/z-ux-design` skill using the Skill tool.** This is not optional. The z-ux-design skill provides UX design principles, cognitive frameworks, and interaction patterns that are essential for designing high-quality user journeys. Do NOT attempt to write user journeys without first loading z-ux-design — the quality difference is significant.

**Workflow:**
1. Call the Skill tool with `skill: "z-ux-design"` to load UX design context
2. Apply its cognitive principles, ergonomics, and design process frameworks to inform the user journey design
3. Then write the user journeys below using both PRD rigor and UX design expertise

**User Journey requirements:**
- Describe key user journeys as step-by-step functional flows (e.g., "User clicks 'Sign Up' → enters email → receives verification → lands on dashboard")
- Focus on WHAT happens at each step, not HOW it looks
- Apply UX principles from z-ux-design: cognitive load management, progressive disclosure, error prevention, and feedback loops
- Identify friction points, decision points, and moments of delight in each journey
- Do NOT include wireframes, mockups, UI layouts, or any visual/UX specifications — these belong in separate design documents
- The goal is to capture functional logic, decision points, and edge cases, not screen designs

### 8. Scope & Non-Goals

Explicitly state what is NOT included. This prevents scope creep and misaligned expectations.

Format:
- **In scope:** [brief list]
- **Out of scope:** [brief list with brief reasoning]
- **Future consideration:** [things intentionally deferred]

### 9. Assumptions, Constraints & Dependencies

- **Assumptions:** Things believed to be true but not yet validated
- **Constraints:** Hard limits (timeline, budget, tech, regulatory)
- **Dependencies:** Other teams, services, or deliverables this work relies on
- **Risks:** What could go wrong, with severity and mitigation strategy

### 10. Timeline & Milestones

High-level only. Do NOT create a detailed project plan in the PRD.

- Key milestones with target dates
- Maximum 3 phases/milestones (by phase 3, requirements will have changed)
- Note: Detailed sprint planning belongs elsewhere

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
- Clear prioritization (P0/P1/P2)
- Edge cases and error states addressed
- Telemetry and measurement included

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

- Write PRDs in Markdown
- Use tables for structured data (metrics, requirements, timelines)
- Keep total length between 4-10 pages depending on complexity
- Use plain English; avoid jargon unless the audience is technical
- Save to `docs/prd-[product-or-feature-name].md`

## Common PRD Anti-Patterns to Actively Avoid

1. **The Solution Masquerading as a Problem** — "We need to build a notification system" is not a problem. "Users miss 23% of time-sensitive updates because they only check the app once daily" is.

2. **The Vacuous PRD** — Every section filled in but content is meaningless. "Ensure alignment with legal standards" tells nobody anything.

3. **The Novel** — 30+ pages that nobody reads. If your PRD is longer than 10 pages, split it into a Product PRD + linked Feature PRDs.

4. **The Design Document in Disguise** — PRD contains wireframes, UI mockups, layout specs, or UX flows. A PRD defines WHAT to build and WHY, not how it looks. Visual design belongs in separate design documents.

5. **The Metrics-Free Zone** — No numbers anywhere. No way to know if the product succeeded or failed.

6. **The Everything Bagel** — Trying to solve every user problem in one release. Ruthless prioritization is a feature, not a bug.

7. **The One-Sided Coin** — Not acknowledging tradeoffs, risks, or downsides of the proposed approach.

8. **The Outdated Artifact** — PRD written once and never updated. A PRD is a living document.

9. **The Missing Competitor** — No awareness of how alternatives solve the same problem. Your solution exists in a competitive context.

10. **The Invisible User** — Requirements that exist because a stakeholder asked, with no evidence of actual user need.
