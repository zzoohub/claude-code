---
name: pricing
description: |
  SaaS pricing strategy, tier design, packaging, pricing model selection, and pricing page optimization.
  Use when: setting prices, designing tiers, choosing pricing models (seat/usage/outcome/hybrid/credits),
  creating pricing pages, analyzing competitor pricing, running pricing research, choosing value metrics,
  optimizing expansion revenue, pricing AI/LLM products, or when user mentions "pricing", "price", "tier",
  "plan", "freemium", "trial", "subscription", "packaging", "value metric", "pricing page", "upgrade",
  "annual vs monthly", "usage-based", "per-seat", "credits", "tokens", "ARPU", "NRR", "expansion revenue",
  "price localization", "PPP", "willingness to pay".
  This skill should trigger broadly — pricing touches everything from product design to growth.
  Do NOT use for: paywall UI optimization (use cro), copy on pricing page (use copywriting),
  psychological principles only (use marketing-psychology), revenue analytics (use product-analytics).
---

# Pricing Strategy

Pricing is the single most powerful growth lever — yet the most neglected.

A 1% improvement in pricing yields an **11% increase in profit**. Monetization has **4-8x the impact of acquisition** on bottom-line growth, yet the average SaaS company spends fewer than 10 hours per year on pricing. Companies that review pricing quarterly see 30% higher growth rates.

This skill provides the frameworks, data, and decision tools to get pricing right.

---

## Pricing Strategy Framework

### Step 1: Understand Value Delivery

Before setting any price, answer three questions:

1. **What outcome does the customer achieve?** (time saved, revenue generated, cost avoided, risk reduced)
2. **How do they measure that value?** (the unit they think in)
3. **What's the magnitude?** (quantify it — if your product saves 10 hours/week at $50/hr, that's $2,000/month in value)

Apply the **10x Rule**: your product should deliver at least 10x the value of its price. Charge ~10-20% of the value delivered (Sequoia: "charge 20% of ROI"). This leaves enough surplus for the customer to feel the purchase is obviously worth it.

### Step 2: Choose the Value Metric

The value metric is what you charge for. It determines your entire pricing architecture.

Use the **HOPE Framework** to evaluate candidate metrics:

| Dimension | Question | Weight |
|-----------|----------|--------|
| **Value connection** | Does this metric scale directly with customer value? | Critical |
| **Fairness & familiarity** | Does charging for this feel fair? Is it familiar? | High |
| **Predictability** | Can customers forecast their costs? | High |
| **Scalability** | As usage grows, does this metric scale proportionally? | Medium |

Score 2-4 candidate metrics. The best metric scores high on all four dimensions.

**Common mistake**: 8 out of 10 companies using per-user pricing should be using a different value metric (Patrick Campbell / ProfitWell). Per-seat pricing is familiar but often misaligned with value.

**Companies using a proper value metric grow 2x faster** than those defaulting to per-seat.

### Step 3: Select Pricing Model

Choose based on product type, customer expectations, and value delivery pattern:

| Model | Best For | Expansion Potential |
|-------|----------|-------------------|
| **Seat-based** | Team collaboration, known user count | Medium (org growth) |
| **Usage-based** | API/infra, variable consumption | High (natural growth) |
| **Outcome-based** | AI agents, measurable results | Very high (value aligned) |
| **Hybrid** | Complex SaaS (most products) | Highest (multiple vectors) |
| **Credit-based** | AI/LLM products, variable workloads | High (predictable + flexible) |

**The data is clear**: hybrid models (subscription base + usage component) report the **highest median growth rate (21%)** and **34% higher LTV/CAC ratios**. Pure subscription or pure usage-based both underperform hybrid.

For detailed model analysis and AI pricing patterns, read `references/pricing-models.md`.

### Step 4: Design Tier Structure

**Three tiers is the sweet spot** for most B2B SaaS. The middle tier is the workhorse — most customers should land there.

| Tier | Role | Pricing Ratio | Target |
|------|------|--------------|--------|
| **Good** (Entry) | Low barrier, prove value | 1x | Individual, small teams |
| **Better** (Recommended) | Best value, obvious choice | 2-3x Good | Core persona, teams |
| **Best** (Premium) | Advanced/enterprise needs | 2-3x Better | Large orgs, power users |

**Critical rule**: never lock features behind a higher tier if those features are needed for customers to succeed with the product. If customers can't reach their "aha moment" on the entry tier, they'll churn before upgrading.

For tier design frameworks, feature gating strategy, naming, and free tier decisions, read `references/tier-packaging.md`.

### Step 5: Set Price Points

Never set prices by gut feeling or by copying competitors. Use research:

1. **Van Westendorp** — Find the acceptable price range (4-question survey, 100+ respondents)
2. **Gabor-Granger** — Find the revenue-maximizing price point within that range
3. **Conjoint Analysis** — Understand feature-price tradeoffs for packaging decisions

Companies using multiple research methods achieve **30% higher revenue growth** than single-method approaches.

For detailed research methods, read `references/research-methods.md`.

### Step 6: Optimize Pricing Page & Billing

Pricing page design directly impacts conversion. Key defaults:

- **Default to annual billing** on toggle (19% increase in annual adoption)
- **Offer 15-20% annual discount** (below 15% doesn't motivate; above 20% sacrifices revenue)
- **Highlight the recommended plan** with "Most Popular" badge
- **Display premium plan first** (left-to-right) to anchor expectations high
- **Limit to 3-4 options** — more creates decision paralysis
- **Include social proof** near CTAs

Annual plans show **30-40% lower churn** than monthly. This alone justifies the discount.

For pricing page optimization, localization, and expansion revenue strategy, read `references/pricing-page-optimization.md`.

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Running pricing research, surveys, willingness-to-pay studies | `references/research-methods.md` |
| Designing tiers, packaging features, free tier/trial decisions | `references/tier-packaging.md` |
| Choosing between pricing models, AI/agent pricing, credits | `references/pricing-models.md` |
| Optimizing pricing page, localization, annual/monthly, expansion | `references/pricing-page-optimization.md` |

---

## Quick Decision Trees

### "Freemium or Free Trial?"

- Product is self-serve with quick time-to-value + low marginal cost + network effects → **Freemium**
- Product needs setup/config, clear aha moment in short window → **Free Trial**
- Want both acquisition scale and conversion urgency → **Hybrid** (freemium core + trial of premium features)

Conversion benchmarks: Freemium 2-5%, Free trial (opt-in) 8-12%, Free trial (credit card required) 25-40%.

### "How should I price my AI product?"

1. **LLM API / infrastructure** → Token-based or credit-based pricing
2. **AI copilot** (human-in-the-loop) → Per-seat + usage caps or credits
3. **AI agent** (autonomous tasks) → Per-task or per-outcome pricing
4. **AI feature in existing SaaS** → Bundle into higher tier or add-on, raise base price $2.50-$5/user

Credits are the bridge model: customers get budget predictability (like a subscription) while vendors get usage alignment. 126% YoY growth in credit-based models across top SaaS companies.

---

## Core Pricing Principles (Data-Backed)

1. **Value-based over cost-plus** — Price reflects customer value, not your costs. 78% of high-growth SaaS companies use value-based pricing.
2. **The value metric determines everything** — Get this right and the rest follows. Wrong metric = wrong architecture.
3. **Hybrid models win** — Base subscription + usage component = highest growth, best LTV/CAC.
4. **Design the product around the price** — Determine willingness to pay before building. 72% of innovations fail because pricing is an afterthought (Ramanujam).
5. **Anchor high** — Premium plan displayed first increases average purchase value by up to 32%.
6. **Build expansion loops into pricing** — Target 110-125% NRR. Usage-based or credit components create natural expansion.
7. **Simplify** — If you can't explain pricing in 10 seconds, it's too complex.
8. **Pricing is never done** — Revisit quarterly. Companies updating pricing quarterly see 2-4x higher ARPU.

---

## Cross-References

- **cro** — Paywall/upgrade flow optimization, conversion funnel design
- **marketing-psychology** — Anchoring, decoy effect, compromise effect, loss aversion
- **copywriting** — Pricing page copy, tier descriptions, CTA language
- **competitor-pages** — Competitor pricing comparison and "vs" pages
- **product-analytics** — Revenue metrics, cohort analysis, PMF assessment
- **churn-prevention** — Cancel flow, payment recovery, retention strategies
