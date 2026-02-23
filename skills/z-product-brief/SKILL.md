---
name: z-product-brief
description: Creates high-quality product briefs that align cross-functional teams and drive product discovery. Use when the user asks to "write a product brief", "create a product spec", "draft a product one-pager", "define a product plan", or needs help organizing product goals, requirements, and direction. Also use when reviewing or improving existing product briefs. Not for detailed PRDs or technical specifications — this skill focuses on the strategic "what" and "why", not the implementation "how".
metadata:
  author: custom
  version: 2.0.0
  category: product-management
---

# Product Brief — Strategic Framework for Cross-Functional Team Alignment

This skill codifies the product brief writing principles, structures, and quality
standards used by leading product practitioners including Marty Cagan (SVPG),
Lane Shackleton (Coda), Lenny Rachitsky, and Reforge.

## What a Product Brief Is (and Is Not)

A product brief is NOT a PRD (Product Requirements Document). This distinction matters.

- **Product Brief**: Strategic. Defines the problem, the "why", the target user, and success criteria. Intentionally lightweight — often called a "one-pager". It is a discovery plan, not a commitment to build. It sits *upstream* of the PRD and roadmap.
- **PRD**: Tactical. Specifies features, technical requirements, user stories, acceptance criteria. Created *after* the brief has aligned the team on the problem and direction.
- **Roadmap**: Sequencing. Lays out timeline and release order. Informed by the brief.

The brief is the first stage that evolves into a PRD as the team gains confidence. Do not conflate them. If the user needs a PRD, clarify the distinction and offer to help with either or both.

### What a Product Brief Must NEVER Include

The following belong in downstream documents (PRD, design spec, technical spec), NOT in the brief:

- **UI/UX design**: Wireframes, mockups, screen layouts, interaction patterns, visual specifications
- **Technical implementation**: Architecture, database schema, URL/route mapping, API endpoints, tech stack choices
- **Page or screen definitions**: Specific pages, navigation structures, URL paths
- **Detailed feature specs**: Acceptance criteria, user stories with implementation detail, prioritized feature lists (P0/P1/P2 — that's PRD territory)

The brief stays at the **problem and strategy level**. It can name broad capability areas ("users need to export data") but should not list specific features or define MVP scope — that belongs in the PRD.

## Why This Matters

Roughly 30,000 consumer products launch each year, yet only about 40% reach the market, and around 95% fail to generate meaningful revenue. The leading causes are fuzzy goals, scope creep, and teams working at cross-purposes. A well-crafted brief is the single most effective countermeasure.

## Core Principles

1. **Problem-first, always.** The brief exists to articulate and validate a problem worth solving. Solutions come later.
2. **Brief means brief.** Target 1-2 pages for the core document. If it takes longer than 10 minutes to read, it will not be read. Appendices are fine for detail.
3. **Hypotheses over answers.** A brief written at the planning stage is mostly assumptions. Name them explicitly and plan how to validate them.
4. **Living document.** The brief evolves from problem definition through discovery to delivery. It is never "done" — it is the team's evolving source of truth.
5. **Audience is everyone.** Engineers, designers, marketers, executives, and new team members should all be able to understand it. No jargon that only one function gets.

## The Four Risks Framework (Marty Cagan / SVPG)

Every product brief should address, at minimum implicitly, these four risks:

| Risk | Question | Owner |
|------|----------|-------|
| **Value** | Will customers buy or choose to use this? | PM |
| **Usability** | Can users figure out how to use it? | Design |
| **Feasibility** | Can we build it with our current tech, skills, and time? | Engineering |
| **Viability** | Does it work for the business (revenue, legal, compliance, brand)? | PM + Stakeholders |

A brief that ignores any of these is incomplete. The brief does not need to answer these questions — it needs to surface them as hypotheses and outline how the team will validate each.

## Process

### Step 1: Gather Context

Before writing, understand:

1. **The problem**: What pain, frustration, or unmet need exists? For whom? How do you know?
2. **Strategic context**: How does this connect to business objectives, OKRs, or company mission?
3. **What has been tried**: Is this a new problem or a known one with failed past attempts?
4. **Constraints**: Time, budget, team size, technical debt, regulatory requirements.

Ask the user clarifying questions only for what is genuinely missing. If they have provided rich context, move to drafting.

### Step 2: Draft the Brief

Use the Staged Brief structure below. Adapt depth to the project size — small features may only need Problem + Approach. Large initiatives should use all stages.

```markdown
# [Product Name] — Product Brief

**Author:** [Name] | **Date:** [Date] | **Status:** [Discovery / In Progress / Approved]
**Tagline:** One sentence that a customer would understand. Not marketing fluff — functional clarity.

---

## 1. Problem

### What problem are we solving?
[2-4 sentences. Ground this in observed user pain, not business desire. Include evidence: user research quotes, support ticket data, usage analytics, or competitive gaps.]

### Who has this problem?
[Specific persona. Role, context, behaviors. "DevOps leads at 50-200 person SaaS companies" not "developers".]

### How do they solve it today?
[Current workarounds. This reveals the real competitive landscape — which is often inaction or manual processes, not a named competitor.]

### Why now?
[What changed that makes this worth solving today? Market shift, new technology, strategic priority, customer churn signal.]

---

## 2. Hypotheses & Risks

State your key assumptions explicitly. For each, note how you plan to validate it.

| Hypothesis | Risk Type | Validation Plan |
|-----------|-----------|-----------------|
| [e.g., "Users will switch from spreadsheets to our tool"] | Value | [e.g., "5 user interviews with prototype"] |
| [e.g., "We can build this in one sprint"] | Feasibility | [e.g., "Eng spike in week 1"] |
| [e.g., "This fits within our compliance framework"] | Viability | [e.g., "Legal review by [date]"] |

---

## 3. Proposed Direction

### High-level approach
[1-2 paragraphs. Describe the direction, not the detailed solution. Think "what experience we want to create" not "what features we will build".]

### What differentiates this?
[Why our approach is different from competitors or the status quo. Be specific.]

### What this is NOT (Non-Goals)
[Explicitly list what is out of scope. This is as important as what is in scope. Prevents scope creep and aligns expectations.]

Examples:
- This is not a replacement for [X existing tool]
- We will not support [Y use case] in the initial version
- Performance optimization is out of scope for this phase

---

## 4. Success Criteria

Define 2-4 measurable outcomes. Each must be specific enough that the team can later say "we hit this" or "we didn't."

| Metric | Current State | Target | How Measured |
|--------|--------------|--------|-------------|
| [e.g., Onboarding completion rate] | [e.g., 34%] | [e.g., 60%] | [e.g., Amplitude funnel] |
| [e.g., Time to first value] | [e.g., 45 min] | [e.g., <10 min] | [e.g., Event tracking] |

Avoid vanity metrics. "Improve engagement" is not a success criterion. "Increase 7-day retention from 30% to 45%" is.

---

## 5. Audience & Market Context

### Target audience
[Primary persona with specific attributes. Include a brief user story or scenario that makes the persona tangible.]

### Competitive landscape
[2-3 key competitors or alternatives. For each: what they do well, where they fall short, and how we differentiate. A simple table works well here.]

| Competitor | Strength | Weakness | Our Angle |
|-----------|----------|----------|-----------|
| | | | |

### Pricing signal (if applicable)
[Early thinking on pricing model. Not a final decision — a starting hypothesis. Fixed rate, tier system, freemium, usage-based, etc.]

---

## 6. Scope & Timeline

### What needs to be true to test our hypothesis?
[Describe the minimum scope directionally — not as a feature list, but as the capabilities or experiences needed to validate the core hypothesis. Detailed MVP feature breakdown belongs in the PRD.]

### Rough timeline
[Estimates, not commitments. High-level phases only.]

| Phase | Duration | Key Activities |
|-------|----------|---------------|
| Discovery | [e.g., 2 weeks] | User interviews, prototype, eng spike |
| Build + Test | [e.g., 4-5 weeks] | Development and beta |
| Launch | [e.g., target date] | Rollout + measurement |

---

## 7. Open Questions

List what you do NOT know yet. This is one of the most valuable sections — it prevents false confidence and tells stakeholders where input is needed.

- [ ] [e.g., Do we need a new data pipeline or can we reuse existing?]
- [ ] [e.g., What is the legal review timeline for this feature?]
- [ ] [e.g., Which customer segment should we pilot with first?]

---

## 8. Risks & Dependencies

- **Technical:** [e.g., Requires infrastructure we haven't built]
- **Business:** [e.g., Competitor launching similar feature in Q2]
- **Team:** [e.g., Key engineer on leave during build phase]
- **Dependencies:** [e.g., Waiting on design system update from Platform team]

---

## 9. Team & Stakeholders

| Role | Person | Responsibility |
|------|--------|---------------|
| PM (Driver) | | Owns the brief, drives decisions |
| Design | | UX research, prototype |
| Eng Lead | | Feasibility, architecture |
| Stakeholder | | Approval, strategic input |

---

*Appendix: Link to supporting materials — user research, design files, data analysis, prior art, etc.*
```

### Step 3: Apply the Quality Checklist

Before presenting, verify:

- [ ] **Problem is grounded in evidence**, not assumption. Can you point to data, quotes, or observations?
- [ ] **Hypotheses are explicit.** Assumptions are named, not hidden.
- [ ] **Non-Goals are stated.** The reader knows what this is NOT.
- [ ] **Success metrics are specific and measurable.** No vague "improve X" language.
- [ ] **Four risks addressed.** Value, Usability, Feasibility, Viability — at least acknowledged.
- [ ] **A new team member could understand this.** No tribal knowledge required.
- [ ] **Under 2 pages** for the core brief (excluding appendix).
- [ ] **Open questions are honest.** Gaps are flagged, not papered over.

### Step 4: Guide Next Steps

After presenting the brief, recommend:

1. **Share early, share widely.** Circulate for async feedback before any review meeting. Use comments, not meetings, for initial input.
2. **Identify disagreements.** The purpose of sharing is to surface disagreement early. If everyone agrees immediately, the brief may be too vague.
3. **Plan validation.** For each hypothesis, schedule the smallest possible test.
4. **Evolve, don't rewrite.** As discovery progresses, update the brief. It becomes the running record of what the team learned and decided.

## Adapting to Project Size

| Project Size | What to Include |
|-------------|----------------|
| **Small feature** (less than 1 week) | Use the lightweight template below. |
| **Medium feature** (1-4 weeks) | Full brief, lighter on market context. |
| **Large initiative** (1+ months) | Full brief with all sections. Add press release exercise if helpful. |
| **New product** | Full brief + Amazon-style internal press release + detailed competitive analysis in appendix. |

### Lightweight Brief (Small Features)

For features under a week, use this minimal structure instead of the full 9-section template:

```markdown
# [Feature Name] — Brief

**Problem:** [2-3 sentences. What's broken, for whom, and how do we know?]

**Direction:** [1-2 sentences. What experience we want to create.]

**Non-Goals:** [Bullet list of what this is NOT.]

**Success:** [1-2 metrics with targets.]

**Open Questions:** [Anything unresolved.]
```

## The Press Release Exercise (Optional)

For larger initiatives, write a hypothetical press release from the customer's perspective as if the product already launched. This forces the team to:
- Articulate value in plain language
- Align on the customer experience, not the feature list
- Identify disconnects between what the team thinks they are building and what the customer would actually experience

Keep it to one page. Write it in "Oprah-speak, not geek-speak" (Marty Cagan).

## When Reviewing an Existing Brief

If the user asks to review or improve a product brief, evaluate against these criteria:

1. **Check for the Problem-Solution gap.** Is there a clear, evidence-based problem? Or did they jump straight to features?
2. **Look for hidden assumptions.** If the brief reads like certainty, it is probably full of untested assumptions. Surface them.
3. **Check Non-Goals.** If there are none, scope creep is almost guaranteed.
4. **Evaluate success metrics.** Are they specific? Measurable? Connected to the stated problem?
5. **Assess the Four Risks.** Which of Value / Usability / Feasibility / Viability is unaddressed?
6. **Check audience clarity.** If only engineers can understand it, or only executives — it is not doing its job.
7. **Give specific, actionable feedback.** Not "add more detail" — instead "the success metric 'improve engagement' needs a specific number and measurement method."

## Common Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Starting with the solution | Team builds something nobody needs | Rewrite problem section with user evidence |
| No Non-Goals | Scope creep, missed deadlines | Add explicit "What this is NOT" section |
| Vague metrics | No way to know if you succeeded | Define current state, target state, measurement method |
| Brief as commitment | Team afraid to update it | Frame as living document, add "Status" field |
| Written for one audience | Other functions ignore it | Test: can a marketer AND an engineer act on it? |
| No open questions | False confidence, surprises later | Dedicate a section to unknowns |
| Too long | Nobody reads it | Cut to 2 pages. Move detail to appendix |

## Output Format

- Default: Markdown document suitable for Notion, Confluence, Google Docs, or Coda
- If the user requests DOCX, PDF, or slides: adapt accordingly
- If the user has a company template: follow their structure, supplement missing sections from this framework
- Always prioritize clarity and brevity over comprehensiveness
