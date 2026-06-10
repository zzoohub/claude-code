---
name: competitor-pages
description: |
  Competitor comparison pages, alternative pages, and vs pages for SEO and conversion.
  Use when: creating "[Competitor] alternative" pages, "vs" comparison pages, competitor
  comparison tables, migration guides, or when user mentions "competitor page", "alternative page",
  "vs page", "comparison page", "switching from", "migrate from", "competitor alternative".
  Do NOT use for: general competitive analysis strategy (use marketer agent — this skill produces the published
  page artifact; competitive analysis is the internal strategy doc biz/marketing/competitors.md), pricing strategy
  or competitor-pricing analysis (use pricing skill — this skill only renders a pricing-comparison table from prices you already have),
  standalone SEO/AEO/GEO strategy, keyword research, or site-wide technical SEO (use search-visibility skill — it
  layers deeper optimization on top of the page this skill produces), or page conversion optimization (use cro skill).
---

# Competitor Comparison Pages

Create high-converting competitor comparison, alternative, and migration pages that capture high-intent search traffic.

---

## Why Competitor Pages Matter

- **High-intent traffic** — Users searching "[X] alternative" are ready to switch
- **Bottom-of-funnel** — These visitors have the highest conversion potential
- **Intent over volume** — Competitor and "alternative" keywords convert because of buyer intent, not volume; some big competitors have meaningful volume, but many terms are low-volume and extremely high-converting. Prioritize by intent, not raw volume
- **Brand positioning** — Define how your product compares on your terms

---

## Five Page Formats

| Format | Use When | Example | Template |
|--------|----------|---------|----------|
| **[Competitor] Alternative** (singular) | Single competitor, strong differentiator | "Notion Alternative" | Format 1 |
| **[Competitor] Alternatives / Best [Category] Tools** (roundup) | Multiple options; category leadership; earlier-stage research | "Best Project Management Tools" | Format 2 |
| **[You] vs [Competitor]** | Head-to-head, both well-known | "Linear vs Jira" | Format 3 |
| **[A] vs [B]** (third-party) | User comparing two others; you're the relevant third option | "Asana vs Monday" | Format 4 |
| **Switching from [Competitor]** (migration) | Migration-ready users, technical product | "Switching from Heroku" | Format 5 |

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Research process, competitor-data model, handling incomplete data, SEO/heading/schema strategy, GEO, data-freshness discipline | `references/content-architecture.md` |
| Copy-paste page skeletons per format, section copy patterns, meta-tag templates, JSON-LD schema examples | `references/templates.md` |

---

## Workflow

When triggered, follow these steps in order:

### Step 1: Gather Context

Ask the user for the information you need. Don't start drafting until you understand the basics:

- **Your product**: Name, what it does, target audience
- **Competitor(s)**: Which competitor(s) to compare against
- **Key differentiators**: What makes the user's product better for their audience
- **Available data**: Do they have pricing details, feature lists, testimonials, migration docs?
- **Page format**: Which of the five formats fits (suggest one based on their description)

If the user already provided most of this in their prompt, confirm your understanding and ask only about gaps.

### Step 2: Research

Use web search to fill knowledge gaps — see `references/content-architecture.md` for the research process. Focus on publicly available information: pricing pages, feature lists, review sites, changelogs.

### Step 3: Select Format

Pick the right format from the Five Page Formats table above (each maps to a template in `references/templates.md`). If unclear, suggest the best fit and explain why.

### Step 4: Draft

Use the matching template from `references/templates.md`. Fill in everything you can from user input and research. Mark gaps with `[TODO: ...]` placeholders — see `references/content-architecture.md` for how to handle incomplete data.

### Step 5: Review and Refine

After drafting, review for: honesty (are competitor strengths acknowledged?), specificity (vague claims replaced with data?), and completeness (all sections filled or marked TODO?).

---

## Output Format

Produce the page in **markdown** by default. Include an HTML block at the top for meta tags (title, description). If the user specifies a different format (HTML, JSX, MDX), adapt accordingly.

When asked to save the draft (and a file-write capability is present), write it to the competitor-pages dir (default `biz/marketing/competitor-pages/{slug}.md`; caller may redirect the `biz/<area>/` root) — the published page itself lives wherever the project's site content lives.

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

### Make Claims Defensible
Every comparative claim about a named competitor must be (1) true at publish time, (2) backed by a citable public source (link their pricing/docs page), (3) objective and verifiable rather than vague superiority, and (4) kept current. Comparative advertising is legally risky — a false or stale claim about a named competitor can create Lanham Act §43(a) and FTC exposure, not just lost trust. Date-stamp competitor data and re-verify it on a cadence (see `references/content-architecture.md`).

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

Head-to-head pages (singular Alternative, You vs [Competitor]) typically include these sections. Roundup (plural / "Best [Category]") and third-party ([A] vs [B]) pages use a different structure — see `references/templates.md` — and omit any section that doesn't apply:

1. **Trust header** — Author or "Reviewed by [role]", "Last updated: [date]", and "Competitor pricing/features verified as of [date]" (E-E-A-T + freshness; pair with `Article`/`dateModified` schema)
2. **Hero** — Clear headline addressing the search intent
3. **Quick Comparison Table** — Feature/pricing comparison at a glance
4. **Key Differentiators** — 3-5 areas where you win, with specifics
5. **Honest Acknowledgments** — Where the competitor is strong
6. **Social Proof** — Testimonials from switchers + third-party ratings/badges (or TODOs if unavailable)
7. **Migration Path** — How easy it is to switch
8. **CTA** — Clear next step (trial, demo, import). On long pages repeat it after the comparison table and at decision points, add risk-reversal near the table (free trial, no credit card, easy cancellation, security/compliance badges), and consider a sticky compare/CTA bar. Route by segment: trial-led for SMB/developer, demo-led for enterprise (see Tone Calibration)

---
