---
name: competitor-pages
description: |
  Competitor comparison pages, alternative pages, and vs pages for SEO and conversion.
  Use when: creating "[Competitor] alternative" pages, "vs" comparison pages, competitor
  comparison tables, migration guides, or when user mentions "competitor page", "alternative page",
  "vs page", "comparison page", "switching from", "migrate from", "competitor alternative".
  Do NOT use for: general competitive analysis strategy (use marketer agent), pricing comparison only (use pricing skill),
  SEO optimization (use search-visibility skill), or page conversion optimization (use cro skill).
---

# Competitor Comparison Pages

Create high-converting competitor comparison, alternative, and migration pages that capture high-intent search traffic.

---

## Why Competitor Pages Matter

- **High-intent traffic** — Users searching "[X] alternative" are ready to switch
- **Bottom-of-funnel** — These visitors have the highest conversion potential
- **SEO value** — Competitor name keywords often have significant search volume
- **Brand positioning** — Define how your product compares on your terms

---

## Four Page Formats

| Format | Use When | Example |
|--------|----------|---------|
| **[Competitor] Alternative** | Single competitor, strong differentiator | "Notion Alternative" |
| **[You] vs [Competitor]** | Head-to-head comparison, both well-known | "Linear vs Jira" |
| **Best [Category] Tools** | Category leadership, multiple competitors | "Best Project Management Tools" |
| **Switching from [Competitor]** | Migration-ready users, technical product | "Switching from Heroku" |

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Content architecture, section structure, SEO approach | `references/content-architecture.md` |
| Page templates, copy patterns, example structures | `references/templates.md` |

---

## Workflow

When triggered, follow these steps in order:

### Step 1: Gather Context

Ask the user for the information you need. Don't start drafting until you understand the basics:

- **Your product**: Name, what it does, target audience
- **Competitor(s)**: Which competitor(s) to compare against
- **Key differentiators**: What makes the user's product better for their audience
- **Available data**: Do they have pricing details, feature lists, testimonials, migration docs?
- **Page format**: Which of the four formats fits (suggest one based on their description)

If the user already provided most of this in their prompt, confirm your understanding and ask only about gaps.

### Step 2: Research

Use web search to fill knowledge gaps — see `references/content-architecture.md` for the research process. Focus on publicly available information: pricing pages, feature lists, review sites, changelogs.

### Step 3: Select Format

Pick the right format from the four options below. If unclear, suggest the best fit and explain why.

### Step 4: Draft

Use the matching template from `references/templates.md`. Fill in everything you can from user input and research. Mark gaps with `[TODO: ...]` placeholders — see `references/content-architecture.md` for how to handle incomplete data.

### Step 5: Review and Refine

After drafting, review for: honesty (are competitor strengths acknowledged?), specificity (vague claims replaced with data?), and completeness (all sections filled or marked TODO?).

---

## Output Format

Produce the page in **markdown** by default. Include an HTML block at the top for meta tags (title, description). If the user specifies a different format (HTML, JSX, MDX), adapt accordingly.

---

## Tone Calibration

Match the tone to the target audience:

- **Enterprise / B2B**: Professional, data-driven, emphasize ROI, security, compliance, and scale. Avoid casual language. Use phrases like "designed for teams of 50+", "enterprise-grade".
- **SMB / Startup**: Direct, practical, emphasize speed, simplicity, and value. OK to be conversational. Use phrases like "get started in minutes", "no bloat".
- **Developer / Technical**: Precise, no fluff, emphasize APIs, extensibility, performance. Show code examples or CLI comparisons where relevant. Avoid marketing-speak.
- **Consumer / Creative**: Friendly, benefit-focused, emphasize experience and ease. Use screenshots or visual comparisons where possible.

If the audience isn't obvious, ask. The wrong tone undermines an otherwise good page.

---

## Core Principles

### Be Honest
Don't trash competitors. Acknowledge their strengths. Users can smell bias — balanced comparisons convert better than hit pieces.

### Lead with Your Unique Strengths
Don't organize around competitor weaknesses. Lead with what makes you different and better for your target user.

### Include Specific Comparisons
Features, pricing, use cases — be specific. Vague "we're better" claims don't convince anyone. Tables and data convert.

### Target High-Intent Queries
These pages should be SEO-optimized for queries like:
- "[Competitor] alternative"
- "[Competitor] vs [Your Product]"
- "Best [category] tools"
- "Switch from [Competitor]"

### Include Social Proof
Real migration stories, switch testimonials, and "I switched from X" quotes are the most powerful social proof on competitor pages. If the user doesn't have these yet, add `[TODO: Add testimonial from customer who switched from [Competitor]]` placeholders.

---

## Page Structure Overview

Every competitor page should include:

1. **Hero** — Clear headline addressing the search intent
2. **Quick Comparison Table** — Feature/pricing comparison at a glance
3. **Key Differentiators** — 3-5 areas where you win, with specifics
4. **Honest Acknowledgments** — Where the competitor is strong
5. **Social Proof** — Testimonials from switchers (or TODOs if unavailable)
6. **Migration Path** — How easy it is to switch
7. **CTA** — Clear next step (trial, demo, import)

---

## Cross-References

- **search-visibility** (skill) — For SEO optimization of competitor pages
- **copywriting** (skill) — For persuasive comparison copy
- **cro** (skill) — For conversion optimization of these pages
- **marketing-psychology** (skill) — For comparison framing (anchoring, contrast effect)
