---
name: z-product-brief
description: Creates high-quality product briefs that align cross-functional teams and drive product discovery. Use when the user asks to "write a product brief", "create a product spec", "draft a product one-pager", "define a product plan", "product pitch", "product concept", or needs help organizing product goals, requirements, and direction. Also trigger when a user says "I have an idea for a product", "help me think through this feature", "I want to build X", or describes a product concept without naming a specific document type. Also use when reviewing or improving existing product briefs. Not for detailed PRDs or technical specifications — this skill focuses on the strategic "what" and "why", not the implementation "how".
metadata:
  author: custom
  version: 2.1.0
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

The brief stays at the **problem and strategy level**. It can name broad capability areas ("users need to export data") but should not list specific features, define MVP scope, or prioritize phases — all of that belongs in the PRD.

## Why This Matters

Roughly 30,000 consumer products launch each year, yet only about 40% reach the market, and around 95% fail to generate meaningful revenue. The leading causes are fuzzy goals, scope creep, and teams working at cross-purposes. A well-crafted brief is the single most effective countermeasure.

## Core Principles

1. **Problem-first, always.** The brief exists to articulate a problem worth solving and define the product direction to address it. Solutions come later.
2. **Brief means brief.** The core of the document (Problem, Direction, Success Criteria) should fit on 1-2 pages and be readable in under 10 minutes. Context sections (Audience, Timeline, Team) scale with project size — include them for medium and large initiatives, abbreviate or skip them for small features.
3. **Acknowledge assumptions.** A brief written at the planning stage inevitably contains assumptions. Name them explicitly so the team is aware, but the brief's primary job is to define direction — not to design validation experiments.
4. **Living document.** The brief evolves from problem definition through discovery to delivery. It is never "done" — it is the team's evolving source of truth.
5. **Audience is everyone.** Engineers, designers, marketers, executives, and new team members should all be able to understand it. No jargon that only one function gets.

## Tone

Write in direct, confident, jargon-free prose. Default to active voice and short sentences. The brief should read like a smart colleague explaining the situation over coffee — not like a legal document or a marketing deck. Match the user's level of formality when possible, but when in doubt, lean conversational over corporate.

## The Four Risks Framework (Marty Cagan / SVPG)

Every product brief should address, at minimum implicitly, these four risks:

| Risk | Question | Owner |
|------|----------|-------|
| **Value** | Will customers buy or choose to use this? | PM |
| **Usability** | Can users figure out how to use it? | Design |
| **Feasibility** | Can we build it with our current skills and time? | Engineering |
| **Viability** | Does it work for the business (revenue, legal, compliance, brand)? | PM + Stakeholders |

A brief that ignores any of these is incomplete. The brief does not need to have all the answers — it needs to acknowledge these risks and describe how the team intends to address them.

## Process

### Step 1: Gather Context

Before writing, understand:

1. **The problem**: What pain, frustration, or unmet need exists? For whom? How do you know?
2. **Strategic context**: How does this connect to business objectives, OKRs, or company mission?
3. **What has been tried**: Is this a new problem or a known one with failed past attempts?
4. **Constraints**: Time, budget, team size, regulatory requirements.

Ask the user clarifying questions only for what is genuinely missing. If they have provided rich context, move to drafting.

### Interaction Pattern

How you work with the user matters as much as the template:

- **If the user gives rich context** (a paragraph or more describing the product, audience, and goals): draft the full brief in one pass. Fill gaps with reasonable assumptions and flag them with "[Assumption — verify]" markers.
- **If the user gives a thin prompt** (e.g., "write a product brief for a todo app"): ask 2-3 targeted questions before drafting. Focus on problem, audience, and what success looks like. Don't interrogate — three questions max, then draft.
- **If the user dumps unstructured context** (meeting notes, Slack threads, braindumps): synthesize it into the brief structure. This is one of the highest-value things this skill does — turning chaos into clarity.
- **Always present a complete draft**, not section-by-section. The brief is a cohesive document; the user needs to see it as a whole to judge if it holds together. After presenting, ask for feedback on the whole piece.

### Step 2: Draft the Brief

Use the template below. The first four sections (Problem through Success Criteria) are the core — they should always be present. Sections 5-8 scale with project size: include them for medium/large initiatives, skip or abbreviate for small features.

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
[What changed that makes this worth solving today? Market shift, strategic priority, customer churn signal, new capability becoming available.]

---

## 2. Assumptions, Risks & Dependencies

State the key assumptions underlying this product direction, the risks that could derail it, and the dependencies the team needs to track. Making these explicit keeps the team honest about what is known vs. believed.

| Assumption / Risk | Type | Impact | How We'll Address It |
|-------------------|------|--------|---------------------|
| [e.g., "Users will switch from spreadsheets"] | Value | High | [e.g., "User interviews with 10 target customers"] |
| [e.g., "Current team and stack can handle this"] | Feasibility | Medium | [e.g., "Eng spike in week 1"] |
| [e.g., "Fits within compliance framework"] | Viability | High | [e.g., "Legal review by [date]"] |
| [e.g., "Key engineer available through build phase"] | Team | Medium | [e.g., "Confirm with eng manager"] |
| [e.g., "Design system update ships before we need it"] | Dependency | High | [e.g., "Weekly sync with Platform team"] |

Types: Value, Usability, Feasibility, Viability, Team, Dependency

---

## 3. Proposed Direction

### High-level approach
[1-2 paragraphs. Describe the direction, not the detailed solution. Think "what experience we want to create" not "what features we will build".]

### Core insight
[What is the key bet or insight behind this approach? What do we believe that others don't, or what advantage do we have? This is the "why this approach" — the strategic reasoning, not just a description of the plan.]

### What differentiates this?
[Why our approach is different from competitors or the status quo. Be specific.]

### What this is NOT (Non-Goals)
[Explicitly list what is out of scope. This is as important as what is in scope. Prevents scope creep and aligns expectations.]

Examples:
- This is not a replacement for [X existing tool]
- We will not support [Y use case] — it is a separate problem space
- Enterprise compliance (SOC2, HIPAA) is outside the scope of this product

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
[Early thinking on pricing model. Not a final decision — an initial direction. Fixed rate, tier system, freemium, usage-based, etc.]

---

## 6. Scope & Timeline

### Product scope
[Describe what this product aims to deliver. Think in terms of capabilities and user outcomes, not feature lists. This is the full vision — what the product looks like when fully realized.]

### Rough timeline
[Estimates, not commitments. High-level milestones only. Phasing and MVP scoping belong in the PRD.]

| Milestone | Target | Description |
|-----------|--------|-------------|
| [e.g., Discovery complete] | [e.g., Week 2] | [e.g., User research and competitive analysis done] |
| [e.g., Initial launch] | [e.g., Week 8] | [e.g., First version available to users] |
| [e.g., Full rollout] | [e.g., Q3] | [e.g., Complete product vision delivered] |

---

## 7. Open Questions

List what you do NOT know yet. This is one of the most valuable sections — it prevents false confidence and tells stakeholders where input is needed.

- [ ] [e.g., Do we need a new data pipeline or can we reuse existing?]
- [ ] [e.g., What is the legal review timeline for this feature?]
- [ ] [e.g., Which customer segment should we pilot with first?]

---

## 8. Team & Stakeholders

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
- [ ] **Assumptions are explicit.** Key assumptions are named, not hidden.
- [ ] **Non-Goals are stated.** The reader knows what this is NOT.
- [ ] **Success metrics are specific and measurable.** No vague "improve X" language.
- [ ] **Four risks addressed.** Value, Usability, Feasibility, Viability — at least acknowledged.
- [ ] **Full vision is clear.** The brief describes the complete product direction, not a constrained MVP.
- [ ] **A new team member could understand this.** No tribal knowledge required.
- [ ] **Core brief (sections 1-4) fits in 1-2 pages.** Context sections add length as needed.
- [ ] **Open questions are honest.** Gaps are flagged, not papered over.

### Step 4: Guide Next Steps

After presenting the brief, recommend:

1. **Share early, share widely.** Circulate for async feedback before any review meeting. Use comments, not meetings, for initial input.
2. **Identify disagreements.** The purpose of sharing is to surface disagreement early. If everyone agrees immediately, the brief may be too vague.
3. **Address open questions.** Assign owners and deadlines to the items in the Open Questions section.
4. **Evolve, don't rewrite.** As discovery progresses, update the brief. It becomes the running record of what the team learned and decided.

## Calibration Examples

### Problem statement: weak vs. strong

**Weak:**
> We need a dashboard for our analytics data. Users want better visibility into their metrics.

This is a solution masquerading as a problem. "Users want better visibility" is a vague desire, not an observed pain.

**Strong:**
> Customer success managers spend 2-3 hours per week manually pulling data from three separate tools (Mixpanel, Salesforce, Zendesk) to prepare account health reports. In exit interviews, 4 of our last 10 churned accounts cited "lack of proactive support" — which traces back to CSMs not having a unified view of account signals. The current workflow is: export CSV from each tool, paste into a spreadsheet, eyeball for anomalies. By the time a CSM spots a problem, the customer is already frustrated.

This is grounded in evidence (exit interviews, observed workflow), names a specific persona (CSMs), quantifies the pain (2-3 hours/week), and explains the downstream impact (churn).

### Non-Goals: weak vs. strong

**Weak:**
> Non-goals: Don't over-engineer it.

This is meaningless — it doesn't help anyone make a scoping decision.

**Strong:**
> - This is not a general-purpose BI tool. We are solving the account health report problem, not replacing Looker.
> - We will not build custom alerting in v1. If CSMs need alerts, they can set them up in Slack via existing integrations.
> - Multi-tenant data isolation (separate databases per customer) is out of scope — we'll use row-level security on the existing schema.

Each non-goal draws a clear line that prevents a specific scope creep scenario.

## Adapting to Project Size

| Project Size | What to Include |
|-------------|----------------|
| **Small feature** (less than 1 week) | Use the lightweight template below. |
| **Medium feature** (1-4 weeks) | Core sections (1-4) plus Open Questions. Lighter on market context. |
| **Large initiative** (1+ months) | All 8 sections. |
| **New product** | All 8 sections + press release exercise + detailed competitive analysis in appendix. |

### Lightweight Brief (Small Features)

For features under a week, use this minimal structure instead of the full template:

```markdown
# [Feature Name] — Brief

**Problem:** [2-3 sentences. What's broken, for whom, and how do we know?]

**Direction:** [1-2 sentences. What experience we want to create.]

**Non-Goals:** [Bullet list of what this is NOT.]

**Success:** [1-2 metrics with targets.]

**Open Questions:** [Anything unresolved.]
```

## The Press Release Exercise (Optional)

For larger initiatives, write a hypothetical press release from the customer's perspective as if the product already launched. This forces the team to articulate value in plain language, align on the customer experience rather than the feature list, and spot disconnects between what the team thinks they are building and what the customer would actually experience.

Keep it to one page. Write it in "Oprah-speak, not geek-speak" (Marty Cagan).

```markdown
# [Product Name]: [Headline that captures the customer benefit]

**[City, Date]** — [Company name] today announced [product name], which [one sentence describing what it does for the customer].

**The problem:** [1-2 sentences describing the customer pain in their words, not yours.]

**The solution:** [2-3 sentences describing the experience. Focus on what the customer can now do, not how the technology works.]

**Customer quote:** "[A fictional but realistic quote from your target persona describing why this matters to them.]" — [Name, Title, Company]

**How it works:** [2-3 sentences. The simplest possible explanation. If a non-technical friend wouldn't understand it, rewrite it.]

**Availability:** [When and how customers can get it.]
```

If the press release feels forced or hollow, the product vision likely needs more work.

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
| Too long | Nobody reads it | Keep core to 1-2 pages. Move context to later sections or appendix |

## Output Format

- Default: Markdown document suitable for Notion, Confluence, Google Docs, or Coda
- If the user requests DOCX, PDF, or slides: adapt accordingly
- If the user has a company template: follow their structure, supplement missing sections from this framework
- Always prioritize clarity and brevity over comprehensiveness
