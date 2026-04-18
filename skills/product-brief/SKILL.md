---
name: product-brief
description: Creates lean product briefs — strategic one-pagers that define the problem, direction, and success signal. Use when the user asks to "write a product brief", "create a product one-pager", "product pitch", "product concept", or needs help organizing product goals and direction. Also trigger when a user says "I have an idea for a product", "help me think through this feature", "I want to build X", or describes a product concept without naming a specific document type. Also use when reviewing or improving existing product briefs. This skill produces a concise strategic alignment document — it focuses on the "what" and "why", not features, detailed metrics, or scope boundaries (those belong in the PRD).
---

# Product Brief — Strategic One-Pager

A product brief answers one question: **"Should I build this, and why?"**

It sits upstream of the PRD. The brief defines the problem and direction; the PRD
specifies requirements, user journeys, scope, risks, and metrics in detail.
Keep the brief lean — anything the PRD covers in depth does not belong here.

## What a Product Brief Is (and Is Not)

- **Product Brief**: Problem, direction, success signal. One page. A discovery tool, not a commitment to build.
- **PRD**: Requirements, user journeys, detailed metrics, scope, non-goals, risks. Created *after* the brief crystallizes the direction.

Readable in under 3 minutes. If it takes longer, it's too long.

### What Does NOT Belong in the Brief

These belong in the PRD or feature specs:

- Detailed success metrics with counter-metrics and timeframes
- Non-goals and scope boundaries
- Feature lists, acceptance criteria, user stories
- Timeline, milestones, dev order
- UI/UX design, wireframes
- Technical implementation, architecture, tech stack

## Core Principles

1. **Problem-first.** The brief exists to articulate a problem worth solving.
2. **Brief means brief.** One page. If you're adding detail, it belongs in the PRD.
3. **No jargon.** Write it so anyone can understand.
4. **Living document.** Evolves through discovery. Never "done."

## Tone

Direct, confident, jargon-free. Active voice, short sentences.
Match the user's formality level; when in doubt, lean conversational.

## Process

### Step 1: Gather Context

Ask clarifying questions only for what is genuinely missing. Three questions max, then draft.

- **Rich context** (paragraph+): Draft the full brief in one pass. Flag gaps with "[Assumption — verify]".
- **Thin prompt** (e.g., "product brief for a todo app"): Ask 2-3 targeted questions — problem, audience, success — then draft.
- **Unstructured dump** (meeting notes, braindumps): Synthesize into the brief structure.
- **Always present a complete draft**, not section-by-section.

### Step 2: Draft the Brief

Use this template. All four sections are always present.

```markdown
# [Product Name] — Product Brief

**Date:** [Date] | **Status:** [Discovery / In Progress / Approved]
**Tagline:** One sentence that captures what this does.

---

## Problem

**What:** [2-4 sentences. Ground in observed pain — your own, your team's, or your users'. Include how it's handled today and why that's inadequate.]

**Who and when:** [Who has this problem, in what situation? Yourself, a team, or a user group.]

**Why now:** [What changed? New capability, pain threshold crossed, opportunity window.]

---

## Direction

[1-2 paragraphs. The direction, not the detailed solution. "What experience we want to create" not "what features we will build".]

**Core bet:** [What insight makes this worth building?]

---

## Success Signal

[2-3 sentences. What does winning look like? Concrete enough to know if it's working.]

---

## Open Questions

- [ ] [e.g., Which input format to support first?]
- [ ] [e.g., Build or buy for X component?]
```

### Step 3: Quality Check

Before presenting, verify:

- [ ] Problem is grounded in evidence, not assumption
- [ ] Success signal is concrete enough to measure
- [ ] The whole brief fits on one page
- [ ] Open questions are honest — gaps flagged, not papered over

## Calibration: Weak vs. Strong

**Weak:**
> We need a dashboard for our analytics data. Users want better visibility into their metrics.

A solution masquerading as a problem. "Better visibility" is vague.

**Strong:**
> Engineers spend 10-15 minutes after every deploy manually checking three separate dashboards to confirm nothing broke. Most skip it when rushed, and problems get caught hours later by users.

Grounded in evidence, names a specific situation, quantifies the pain.

## When Reviewing an Existing Brief

1. Is there a clear, evidence-based problem — or did they jump to features?
2. Is the success signal concrete enough to measure?
3. Is it concise? If it reads like a PRD, suggest moving detail downstream.

## Output

Save to `docs/prd/product-brief.md`. Always update this single file in place.

- **150-line limit:** If the file exceeds 150 lines, consolidate — tighten wording, merge redundant content, remove resolved questions — then apply changes.
