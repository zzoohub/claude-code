# Competitor Pages Content Architecture

Structure, data management, and SEO approach for competitor comparison pages.

---

## Page Formats and URLs

| Format | URL Pattern | Target Keywords |
|--------|------------|-----------------|
| [Competitor] Alternative (singular) | `/alternatives/[competitor]` | "[Competitor] alternative" |
| [Competitor] Alternatives (plural) | `/alternatives/[competitor]-alternatives` | "best [Competitor] alternatives" |
| You vs [Competitor] | `/vs/[competitor]` | "[You] vs [Competitor]" |
| [A] vs [B] (third-party) | `/compare/[a]-vs-[b]` | "[A] vs [B]" |

---

## Centralized Competitor Data

When researching, organize findings into this structure. Fill what you can from public sources and mark the rest for the user to provide:

```yaml
competitor:
  name: "[Competitor]"
  tagline: "[Their positioning — from their homepage]"
  target_audience: "[Who they serve — from their marketing]"
  pricing:                          # From their pricing page
    starter: "$X/mo"
    pro: "$Y/mo"
    enterprise: "Custom"
    hidden_costs: "[Per-seat fees, overage charges, add-ons]"
  strengths:                        # From reviews + their marketing
    - "[Strength 1]"
    - "[Strength 2]"
  weaknesses:                       # From review site complaint themes
    - "[Weakness 1]"
    - "[Weakness 2]"
  best_for: "[Ideal customer profile]"
  not_ideal_for: "[Anti-persona]"
  common_complaints:                # From G2/Capterra review themes
    - "[Recurring complaint 1]"
    - "[Recurring complaint 2]"
  migration_notes: "[TODO: Ask user — what transfers, what needs reconfiguration]"
```

---

## Research Process

When the user hasn't provided complete competitor data, research using publicly available sources. Focus on what you can actually verify.

### Research Steps

1. **Pricing page** — Web search for "[Competitor] pricing". Capture tier names, prices, what's included, per-seat vs flat pricing, free plan details.
2. **Feature/product page** — Web search for "[Competitor] features" or visit their marketing site. Document key capabilities and positioning.
3. **Review sites** — Search for "[Competitor] reviews G2" or "[Competitor] reviews Capterra". Look for recurring themes in praise and complaints — these become the "why people switch" section.
4. **Competitor's own comparison pages** — Search for "[Competitor] vs" or "[Competitor] alternatives". See how they position themselves and what they consider their strengths.
5. **Changelog / blog** — Search for "[Competitor] changelog" or "[Competitor] blog" for recent direction and feature launches.

### What to Ask the User For

Some things you can't research — ask the user directly:
- Their own product's differentiators and positioning
- Specific pricing if not public
- Customer testimonials or switch stories
- Migration details (what transfers, what doesn't, time estimates)
- Features the competitor lacks that they offer

---

## Handling Incomplete Data

Not every section can always be filled. Handle gaps in this priority order:

### Research it
If the data is publicly available (pricing, features, reviews), look it up. Don't ask the user for information you can find yourself.

### Ask the user
If the data is internal (testimonials, migration details, proprietary differentiators), ask. Be specific: "Do you have any quotes from customers who switched from [Competitor]?" is better than "Do you have testimonials?"

### Use TODO placeholders
If the user doesn't have the data yet, mark the section clearly so they can fill it later:

```
> [TODO: Add testimonial from a customer who switched from [Competitor]]

[TODO: Add migration time estimate — how long does a typical switch take?]
```

Place TODOs inline where the content should go, not in a separate list. This makes it obvious what's missing and where it belongs.

### Skip the section
If a section genuinely doesn't apply (e.g., no migration path because it's a different product category), omit it entirely rather than leaving an empty section.

---

## SEO Considerations

These pages exist primarily to capture search traffic, so SEO structure matters more here than on most content.

### Content Length
Aim for **1,500–3,000 words** for comparison pages. Shorter pages struggle to rank for competitive terms. Longer is fine if the content is substantive — don't pad with fluff.

### Heading Structure
- **H1**: Include the primary keyword naturally — e.g., "Best Notion Alternatives" or "Linear vs Jira"
- **H2s**: Use for major sections. Include secondary keywords where natural — "Pricing Comparison", "Feature Comparison", "Who Should Switch"
- **H3s**: Use for individual features or comparison dimensions
- Don't skip heading levels (H1 → H3). Keep the hierarchy clean.

### Keyword Placement
- Primary keyword in: H1, first paragraph, meta title, meta description, URL slug
- Secondary keywords in: H2s, image alt text, comparison table headers
- Don't force keywords — if it reads awkwardly, rephrase. Search engines are smart enough to understand synonyms.

### Internal Linking
- Link between related competitor pages (e.g., "vs" page links to "alternative" page for the same competitor)
- Link from feature pages to relevant comparisons
- Create a hub page (`/alternatives/` or `/compare/`) linking to all competitor content
- Link from blog posts that mention competitors to the comparison page

### Schema Markup
Add FAQ schema for common questions — see `templates.md` for the JSON-LD template. Good FAQ candidates:
- "What is the best alternative to [Competitor]?"
- "Is [Your Product] better than [Competitor]?"
- "How much does [Competitor] cost?"
- "Can I migrate from [Competitor] to [Your Product]?"

### Priority Order
1. Highest search volume competitor terms first
2. Direct competitors before indirect
3. "[Competitor] alternative" pages before "vs" pages (higher intent)

---

## Section Types

Go beyond feature tables — use varied section types:

### TL;DR Summary
Start every page with a quick summary for scanners.

### Paragraph Comparisons
For each dimension, write a paragraph explaining differences and when each matters.

### Feature Comparison Table
| Feature | You | Competitor |
|---------|-----|-----------|
| Feature A | How you handle it | How they handle it |

### Pricing Comparison
Include tier-by-tier comparison, what's included, hidden costs, total cost for sample team.

### Who It's For
Be explicit about ideal customer for each option. Honest recommendations build trust.

### Migration Section
What transfers, what needs reconfiguration, support offered, quotes from switchers.

### Social Proof
Testimonials specifically from customers who switched from that competitor.
