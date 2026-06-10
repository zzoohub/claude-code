---
name: product-analytics
description: |
  Analytics methodology that fits the product type — picks the right frame before measuring.
  Logged-in product → Aha Moment, retention cohorts, Carrying Capacity, PMF, Kill/Keep/Scale.
  Login-less content site → acquisition, engagement, content performance, lead conversion.
  Use when: choosing an analytics frame, finding Aha Moments, Kill/Keep/Scale calls,
  activation/retention diagnosis, content-site traffic analysis, or when user mentions
  "Aha Moment", "retention curve", "cohort analysis", "Carrying Capacity", "PMF", "kill criteria",
  "activation rate", "tracking plan", "GA4", "UTM", "A/B test results", "Sean Ellis survey",
  "GRR", "NRR".
  Do NOT use for: tracking code implementation (developer task), CRO experiment design (use cro),
  marketing content (use copywriting), SEO/AEO/GEO strategy (use search-visibility), viral-loop
  design and the K model/targets (use growth-loops), or churn intervention and health-score design
  (use churn-prevention; score *execution* against live data stays here).
---

# Product Analytics Methodology

Methodology for turning analytics into one business decision — first picking the frame that fits the
product type, then applying it. The **product frame** (logged-in, repeat-use) discovers what drives
retention and makes kill/keep/scale calls; the **content-site frame** (login-less) measures
acquisition, engagement, and lead conversion.

---

## First: Pick the Analytics Frame

Before any framework below, decide what kind of product you're analyzing — the right metrics differ structurally.

| If the product is… | …use this frame | Spine |
|---|---|---|
| **A logged-in product** — persistent identity, repeat use (SaaS, app) | **Product frame** (this file, Core Mental Model onward) | Aha Moment → Retention → Carrying Capacity → Kill/Keep/Scale |
| **A login-less content / marketing site** — mostly anonymous browsing, conversion = a lead/inquiry (blog, docs, lead-gen) | **Content-site frame** (`references/content-site-analytics.md`) | Acquisition → Engagement → Conversion (lead) |

The frames are not interchangeable: a content site has no persistent identity, no repeat-usage
retention curve, and no usage equilibrium — so Aha Moment, retention cohorts, and Carrying Capacity
don't apply, and forcing them produces noise. Everything from **Core Mental Model** down is the
**product frame**; on a content site, jump to the content-site reference.

**Hybrid** (a logged-in product with a marketing site/blog): run both frames, each scoped to its
surface — content-site frame pre-signup, product frame post-signup. State the split; never average
metrics across the seam.

---

## Core Mental Model *(product frame — logged-in, repeat-use products)*

All product analytics serves one question: **Should this product be killed, kept, or scaled?**

The answer comes from three interconnected frameworks:
1. **Aha Moment** — The action that predicts long-term retention
2. **Retention Analysis** — Whether a retention plateau exists (PMF signal)
3. **Carrying Capacity** — The product's natural equilibrium MAU

These are not independent. Aha Moment drives activation rate, activation rate drives retention, retention determines Carrying Capacity. Improve from the bottom up: Retention → Activation → Acquisition.

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Finding/validating Aha Moments, activation analysis | `references/aha-moment-discovery.md` |
| Retention cohorts, PMF assessment, plateau detection | `references/retention-analysis.md` |
| Carrying Capacity calculation, Kill/Keep/Scale criteria | `references/carrying-capacity.md` |
| Event naming, tracking plan design, validation | `references/event-tracking-design.md` |
| GA4 setup, GTM configuration, UTM strategy | `references/ga4-gtm-setup.md` |
| A/B test results analysis, statistical rigor | `references/ab-test-analysis.md` |
| Content/marketing-site analytics (login-less): acquisition, engagement, content perf, lead conversion | `references/content-site-analytics.md` |

**Output:** analyses and deliverables land under the analytics dir (default `biz/analytics/` —
tracking plan `tracking-plan.md`, funnel/retention analyses `funnels.md`, dashboards `dashboards.md`,
Kill/Keep/Scale + CC `kill-criteria.md`, reports `reports/`; caller may redirect). If no file-write
capability is present, return results inline.

---

## Quick Decision Framework

### Is there PMF?

```
Plot cohort retention curves (D1, D7, D14, D30, D60, D90)
├── Curve keeps declining without flattening → No PMF. Fix product.
├── Curve flattens but plateau < 20% → Weak/early PMF (<5% = treat as no PMF).
│     Raise the plateau first (retention → activation); keep acquisition cautious.
└── Curve flattens with plateau ≥ 20% → PMF established. Optimize growth.
```

Plateau height bands (the single authoritative scale — B2B SaaS, directional; consumer products typically need roughly double): <5% No PMF · 5-10% Weak · 10-20% Early PMF · 20-40% Solid PMF · >40% Strong PMF. See `references/retention-analysis.md` for the full benchmark table and per-band actions.

### What to fix first?

Always in this order (most teams do it backwards):
1. **Retention** — Raise the plateau height
2. **Activation** — Get more users to Aha Moment
3. **Acquisition** — Only after 1 & 2 are healthy

### Kill/Keep/Scale?

| Signal | Kill | Keep | Scale |
|--------|------|------|-------|
| Retention plateau | None after 8+ weeks (<5%) | Emerging (5-20%) | Established (>20%) |
| CC trend (30d) | Declining | Flat | Rising |
| Activation rate | <10% | 10-30% | >30% |
| Organic inflow | Near zero | Steady | Growing |
| Usage frequency | <1x/month | 1-3x/month | >3x/month |

Usage frequency matters: below 1x/month a retention plateau is nearly impossible — reconsider the product; at 1-3x/month habit formation is fragile, so weight the other signals more.

---

## Analysis Principles

1. **CC, not MAU.** MAU is vanity. CC is the truth — the equilibrium your product settles at without paid push.
2. **Cohort retention, not WAU/MAU ratio.** WAU/MAU can't tell you if recent changes are working.
3. **Fix from the bottom up.** Retention → Activation → Acquisition. Always.
4. **Trends > snapshots.** A rising 5% beats a declining 15%.
5. **Segment everything.** The insight is almost always in a segment, not the average.
6. **Small numbers require humility.** <100 users in a cohort = directional only.
7. **Speed over precision.** Directionally correct in 30 minutes > precise in 3 days. (Exception: strategy-defining calls — Aha Moment validation, kill decisions — get the full rigor.)
8. **Correlation ≠ causation.** Especially for Aha Moment candidates — validate with experiments.

---
