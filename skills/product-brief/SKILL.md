---
name: product-brief
description: Creates lean product briefs — strategic one-pagers that define the problem, direction, and success signal. Use when the user asks to "write a product brief", "create a product one-pager", "product pitch", "product concept", or needs help organizing product goals and direction. Also trigger when a user says "I have an idea for a product", "help me think through this feature", "I want to build X", or describes a product concept without naming a specific document type. Also use when reviewing or improving existing product briefs. This skill produces a concise strategic alignment document — it focuses on the "what" and "why", not features, detailed metrics, or scope boundaries (those belong in the PRD).
metadata:
  author: custom
  version: 3.0.0
  category: product-management
---

# Product Brief — Strategic One-Pager

A product brief answers one question: **"Should we build this, and why?"**

It sits upstream of the PRD. The brief defines the problem and direction; the PRD
specifies requirements, user journeys, scope, risks, and metrics in detail.
Keep the brief lean — anything the PRD covers in depth does not belong here.

## What a Product Brief Is (and Is Not)

- **Product Brief**: Strategic. Problem, direction, success signal. One page. A discovery tool, not a commitment to build.
- **PRD**: Tactical. Requirements, user journeys, detailed metrics, scope, non-goals, risks. Created *after* the brief aligns the team.

The brief should be readable in under 5 minutes. If it takes longer, it's too long.

### What Does NOT Belong in the Brief

These belong in the PRD or other downstream documents:

- Detailed success metrics with counter-metrics and timeframes (PRD owns this)
- Non-goals and scope boundaries (PRD owns this)
- Feature lists, acceptance criteria, user stories
- Detailed risk/assumption tables
- Target audience deep-dives, competitive landscape tables
- Timeline, milestones, phasing
- UI/UX design, wireframes, interaction patterns
- Technical implementation, architecture, tech stack

## Core Principles

1. **Problem-first.** The brief exists to articulate a problem worth solving. Solutions come later.
2. **Brief means brief.** The entire document should fit on one page. If you're adding detail, ask: "Does the PRD already cover this?"
3. **Audience is everyone.** Engineers, designers, marketers, executives — all should understand it. No jargon.
4. **Living document.** Evolves through discovery. Never "done."

## Tone

Direct, confident, jargon-free. Active voice, short sentences. Like a smart colleague
explaining the situation over coffee. Match the user's formality level; when in doubt,
lean conversational.

## Process

### Step 1: Gather Context

Before writing, understand:

1. **The problem**: What pain or unmet need exists? For whom? How do you know?
2. **Strategic context**: How does this connect to business objectives?
3. **What has been tried**: New problem or known one with failed attempts?

Ask clarifying questions only for what is genuinely missing. Three questions max, then draft.

### Interaction Pattern

- **Rich context** (paragraph+): Draft the full brief in one pass. Flag gaps with "[Assumption — verify]".
- **Thin prompt** (e.g., "product brief for a todo app"): Ask 2-3 targeted questions — problem, audience, success — then draft.
- **Unstructured dump** (meeting notes, braindumps): Synthesize into the brief structure. This is one of the highest-value things this skill does.
- **Always present a complete draft**, not section-by-section.

### Step 2: Draft the Brief

Use this template. All four sections are always present.

```markdown
# [Product Name] — Product Brief

**Author:** [Name] | **Date:** [Date] | **Status:** [Discovery / In Progress / Approved]
**Tagline:** One sentence a customer would understand. Functional clarity, not marketing fluff.

---

## 1. Problem

**What problem are we solving?**
[2-4 sentences. Ground in observed user pain, not business desire. Include evidence: research quotes, support data, usage analytics, competitive gaps.]

**Who has this problem?**
[Specific persona. Role, context, behaviors. "DevOps leads at 50-200 person SaaS companies" not "developers".]

**How do they solve it today?**
[Current workarounds. Often inaction or manual processes, not a named competitor.]

**Why now?**
[What changed? Market shift, churn signal, strategic priority, new capability.]

---

## 2. Proposed Direction

**High-level approach**
[1-2 paragraphs. The direction, not the detailed solution. "What experience we want to create" not "what features we will build".]

**Core insight**
[The key bet behind this approach. What do we believe that others don't, or what advantage do we have?]

---

## 3. Success Signal

What does success look like? 2-3 sentences describing the measurable outcomes we're aiming for.
Not a metrics table — just enough to align the team on what "winning" means.
Detailed metrics with targets, counter-metrics, and timeframes belong in the PRD.

[e.g., "We'll know this is working when onboarding completion rises significantly from its current 34%, and new users reach their first value moment in minutes rather than the current ~45 minutes."]

---

## 4. Open Questions

What we don't know yet. Prevents false confidence and signals where input is needed.

- [ ] [e.g., Which customer segment should we pilot with first?]
- [ ] [e.g., Can we reuse existing data pipeline or do we need a new one?]
- [ ] [e.g., What's the legal review timeline?]
```

### Step 3: Quality Check

Before presenting, verify:

- [ ] Problem is grounded in evidence, not assumption
- [ ] Success signal is concrete enough to know if we're winning
- [ ] The whole brief fits on one page
- [ ] A new team member could understand it without tribal knowledge
- [ ] Open questions are honest — gaps flagged, not papered over

### Step 4: Guide Next Steps

After presenting the brief:

1. **Surface disagreements.** If everyone agrees immediately, the brief may be too vague.
2. **Address open questions.** Assign owners and deadlines.
3. **Suggest next steps.** Once aligned, the user can proceed to write a PRD or other detailed documents as needed.

## Calibration: Weak vs. Strong

### Problem statement

**Weak:**
> We need a dashboard for our analytics data. Users want better visibility into their metrics.

A solution masquerading as a problem. "Better visibility" is a vague desire, not observed pain.

**Strong:**
> Customer success managers spend 2-3 hours per week manually pulling data from three separate tools to prepare account health reports. 4 of our last 10 churned accounts cited "lack of proactive support" in exit interviews — which traces back to CSMs not having a unified view of account signals.

Grounded in evidence, names a specific persona, quantifies the pain.

## When Reviewing an Existing Brief

1. Is there a clear, evidence-based problem — or did they jump to features?
2. Is the success signal concrete enough to know if we're winning?
3. Is it concise? If it reads like a PRD, suggest moving detail downstream.
4. Give specific feedback: not "add more detail" but "the success signal needs a clearer indicator of what winning looks like."

## Output

Save to `docs/product-brief.md`. Always update this single file in place. Do NOT create feature-specific files like `product-brief-search.md`.

- Default: Markdown
- If the user has a company template: follow their structure, supplement from this framework
- Prioritize clarity and brevity over comprehensiveness
- **200-line limit:** If the file exceeds 200 lines before your update, first consolidate — tighten wording, merge redundant content, remove resolved questions — then apply changes.
