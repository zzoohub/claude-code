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

Create a single source of truth for each competitor:

```yaml
competitor:
  name: "[Competitor]"
  tagline: "[Their positioning]"
  target_audience: "[Who they serve]"
  pricing:
    starter: "$X/mo"
    pro: "$Y/mo"
    enterprise: "Custom"
  strengths:
    - "[Strength 1]"
    - "[Strength 2]"
  weaknesses:
    - "[Weakness 1]"
    - "[Weakness 2]"
  best_for: "[Ideal customer profile]"
  not_ideal_for: "[Anti-persona]"
  common_complaints:
    - "[From G2/Capterra reviews]"
  migration_notes: "[What transfers, what needs reconfiguration]"
```

---

## Research Process

### Deep Competitor Research

For each competitor:
1. **Product research** — Sign up, use it, document features/UX/limitations
2. **Pricing research** — Current pricing, what's included, hidden costs
3. **Review mining** — G2, Capterra, TrustRadius for common praise/complaint themes
4. **Customer feedback** — Talk to customers who switched (both directions)
5. **Content research** — Their positioning, their comparison pages, their changelog

### Ongoing Updates
- **Quarterly**: Verify pricing, check for major feature changes
- **When notified**: Customer mentions competitor change
- **Annually**: Full refresh of all competitor data

---

## SEO Considerations

### Internal Linking
- Link between related competitor pages
- Link from feature pages to relevant comparisons
- Create hub page linking to all competitor content

### Schema Markup
Consider FAQ schema for common questions: "What is the best alternative to [Competitor]?"

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
