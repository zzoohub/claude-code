# Competitor Pages Content Architecture

Structure, data management, and SEO approach for competitor comparison pages.

---

## Page Formats and URLs

| Format | URL Pattern | Target Keywords |
|--------|------------|-----------------|
| [Competitor] Alternative (singular) | `/alternatives/[competitor]` | "[Competitor] alternative" |
| [Competitor] Alternatives / Best [Category] Tools (roundup) | `/alternatives/[competitor]-alternatives`, `/best/[category]-tools` | "best [Competitor] alternatives", "best [category] tools" |
| You vs [Competitor] | `/vs/[competitor]` | "[You] vs [Competitor]" |
| [A] vs [B] (third-party) | `/compare/[a]-vs-[b]` | "[A] vs [B]" |
| Switching from [Competitor] (migration) | `/migrate/[competitor]` | "switch from [Competitor]", "migrate from [Competitor]" |

---

## Centralized Competitor Data

When researching, organize findings into this structure. Fill what you can from public sources and mark the rest for the user to provide:

```yaml
competitor:
  name: "[Competitor]"
  data_verified_on: "[YYYY-MM-DD]"   # Re-verify on a cadence — see "Keeping Data Accurate" below
  tagline: "[Their positioning — from their homepage]"
  target_audience: "[Who they serve — from their marketing]"
  pricing:                          # From their pricing page
    source_url: "[link to their pricing page]"
    verified_on: "[YYYY-MM-DD]"     # Pricing changes often — highest-risk field to keep current
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

## Keeping Data Accurate

Competitor pricing and features change constantly. A stale claim ("they charge $Y/seat", "they lack feature X") is both a conversion killer (savvy buyers catch it) and a real legal exposure — a now-false comparative claim about a named competitor is exactly what triggers Lanham Act §43(a) / FTC false-advertising risk (and state comparison-pricing statutes). Treat freshness as a discipline, not a one-time capture:

- **Date-stamp every volatile data point.** Use the `verified_on` / `source_url` fields in the competitor YAML above. Pricing and feature-presence claims are the highest-risk.
- **Re-verify on a cadence.** Review on any competitor pricing/packaging/positioning change, and at least quarterly in fast-moving categories. Update the on-page "verified as of [date]" line on each refresh.
- **Never embed undated screenshots** of competitor pricing/UI — caption any screenshot with its capture date and treat it as expiring on the same cadence.
- **Assign an owner.** Someone owns each competitor page's refresh, or the cadence won't happen.

Upside, not just risk: a visible, truthful "Last updated" date plus freshly re-verified data also strengthens content-freshness signals that both classic search and AI answer engines reward (recently-updated comparison pages earn a disproportionate share of AI citations). Only bump the displayed date on substantive updates, not cosmetic edits.

---

## SEO Considerations

These pages exist primarily to capture search traffic, so SEO structure matters more here than on most content.

### Content Length
Cover the comparison thoroughly enough to answer the searcher's full question. Pages that rank tend to run **~1,500–3,000 words** because they cover pricing, features, use cases, and migration in depth — not because length itself ranks (Google has confirmed word count is not a ranking factor). Match the depth of the pages currently ranking for your term; never pad to hit a count.

### Heading Structure
- **H1**: Include the primary keyword naturally — e.g., "Best Notion Alternatives" or "Linear vs Jira"
- **H2s**: Use for major sections. Include secondary keywords where natural — "Pricing Comparison", "Feature Comparison", "Who Should Switch"
- **H3s**: Use for individual features or comparison dimensions
- Don't skip heading levels (H1 → H3) — clean hierarchy mainly helps accessibility (screen-reader navigation) and scannability; it's at most a minor ranking signal, so do it for users.

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

> **FAQ schema:** FAQ rich results were fully deprecated by Google on May 7, 2026 — they no longer appear in Search for any site (the 2023 health/gov carve-out is gone). FAQPage is still valid and helps AI-search/GEO extractability, but expect zero SERP rich result. See `templates.md` → Schema Templates for the canonical caveat and JSON-LD.

Higher-value schema for comparison pages:
- **`Product`** + **`Offer`** (or **`SoftwareApplication`** for SaaS) on each product compared — makes pricing machine-readable and may aid AI-search eligibility. Note: Google AI Overview/AI Mode shopping cards and Perplexity Shopping are driven mainly by Merchant Center feeds + GTIN, so pure SaaS pages usually won't appear as shopping cards — treat this as machine-readability/AEO, not a guaranteed shopping placement.
- **`ItemList`** for the ranked alternatives list
- **`Review`** / **`AggregateRating`** only with genuine, on-page, third-party reviews — never self-controlled or markup-only ratings (manual-action risk; see the warning in `templates.md`)
- **`Article`** / **`BreadcrumbList`** + **`dateModified`** for SEO hygiene and freshness

See `templates.md` for JSON-LD examples.

### Optimizing for AI Answer Engines (GEO/AEO)
Comparison / "best of" / "vs" pages are among the most-cited content types in AI answers (ChatGPT search, Perplexity, Gemini, Google AI Mode) because "best X for Y" verdicts map directly to the queries those engines fan out. Make the page easy to cite verbatim:
- Put a self-contained verdict in the TL;DR and each "Who it's for" block — one quotable line an engine can lift ("Best for [persona] because [reason]").
- Name entities explicitly and consistently; avoid "we"/"they" near key claims so a lifted sentence isn't ambiguous.
- Keep comparison facts in tables **and** restate the key ones in prose — some engines parse text better than tables.
- Structured data doubles as a GEO signal: Product/ItemList markup and clean question→answer pairs correlate with higher AI-citation rates in 2026.
- Defer the cross-engine measurement layer to the search-visibility skill.

### Priority Order
1. Highest search volume competitor terms first
2. Direct competitors before indirect
3. "[Competitor] alternative" pages before "vs" pages (higher intent)

### Scaling Without Thin Content
The most common real-world use is generating one page per competitor at scale — and the dominant failure mode is templated, near-duplicate alternative/vs pages getting demoted or deindexed as thin/doorway content under Google's scaled-content-abuse policy. If you produce many pages:
- Each needs substantial unique, non-templatable content — genuine review-mined pain points, real migration specifics, distinct use-case fit. Don't ship name-swapped clones; the majority of each page should be unique.
- Prioritize the highest-volume / highest-fit competitors over blanket coverage.
- This complements search-visibility (ranking mechanics); the format playbook lives here.

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
Testimonials specifically from customers who switched from that competitor. Pair first-party switch quotes with third-party validation — embedded G2/Capterra ratings, badges, or awards are more persuasive than self-claims and are the only compliant source for `aggregateRating` schema (see `templates.md`). Distinguish self-claims (your differentiator copy) from independent proof, and lead trust-sensitive buyers with the latter.

### Decision-Stage CRO
These are the highest-intent BOFU pages in the funnel, so conversion treatment matters more than a single "CTA" line suggests:
- Place objection-handling and a risk-reversal block (free trial, no credit card, easy cancellation, security/compliance badges) adjacent to the comparison table.
- Repeat the primary CTA after the table and at section breaks; on long pages use a sticky compare/CTA bar.
- Route the CTA by segment — trial-led for SMB/developer, demo-led for enterprise (ties back to the SKILL's Tone Calibration).
- Put social proof near the CTA. Defer test mechanics to the cro skill; the comparison-page-specific placement lives here.
