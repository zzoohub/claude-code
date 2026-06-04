---
name: product-analytics
description: |
  Analytics methodology that fits the product type — picks the right frame before measuring.
  Logged-in SaaS product → Aha Moment discovery, retention cohort analysis, Carrying Capacity
  modeling, PMF assessment, Kill/Keep/Scale. Login-less content/marketing site → acquisition
  channels, top & conversion-assisting content, engagement depth, lead conversion.
  Use when: choosing an analytics frame for a product, finding/validating Aha Moments, making
  Kill/Keep/Scale calls, diagnosing activation bottlenecks, segmenting retained vs churned users,
  evaluating CC trends, analyzing content/traffic for a blog or marketing site, or when user
  mentions "Aha Moment", "retention curve", "cohort analysis", "Carrying Capacity", "PMF",
  "product-market fit", "kill criteria", "activation rate", "retention plateau", "user segmentation",
  "tracking plan", "GA4", "UTM", "A/B test results", "Sean Ellis survey", "GRR", "NRR",
  "revenue retention", "content analytics", "blog analytics", "traffic sources", "top posts",
  "scroll depth", "read completion", "engaged time", "time on page".
  Do NOT use for: tracking code implementation (developer task),
  CRO experiment design (use cro skill), marketing content (use copywriting skill),
  SEO/AEO/GEO strategy and search-query research (use search-visibility skill),
  referral/viral loop design or the K-factor model and targets (use growth-loops skill),
  or churn intervention — cancel-flow, save-offer, dunning, at-risk health-scoring
  (use churn-prevention skill).
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

---

## Quick Decision Framework

### Is there PMF?

```
Plot cohort retention curves (D1, D7, D14, D30, D60, D90)
├── Curve keeps declining without flattening → No PMF. Fix product.
├── Curve flattens but plateau < 10% → Weak/early PMF. Improve activation.
└── Curve flattens with plateau ≥ 10% → PMF exists. Optimize growth.
```

Plateau height bands (the single authoritative scale): <5% No PMF · 5-10% Weak · 10-20% Early PMF · 20-40% Solid PMF · >40% Strong PMF. See `references/retention-analysis.md` for the full benchmark table and per-band actions.

### What to fix first?

Always in this order (most teams do it backwards):
1. **Retention** — Raise the plateau height
2. **Activation** — Get more users to Aha Moment
3. **Acquisition** — Only after 1 & 2 are healthy

### Kill/Keep/Scale?

| Signal | Kill | Keep | Scale |
|--------|------|------|-------|
| Retention plateau | None (<5%) | Emerging (5-20%) | Established (>20%) |
| CC trend (30d) | Declining | Flat | Rising |
| Activation rate | <10% | 10-30% | >30% |
| Organic inflow | Near zero | Steady | Growing |
| Usage frequency | <1x/month | 1-3x/month | >3x/month |

Usage frequency matters: products used <3x/month rarely develop a retention plateau.

---

## Analysis Principles

1. **CC, not MAU.** MAU is vanity. CC is the truth — the equilibrium your product settles at without paid push.
2. **Cohort retention, not WAU/MAU ratio.** WAU/MAU can't tell you if recent changes are working.
3. **Fix from the bottom up.** Retention → Activation → Acquisition. Always.
4. **Trends > snapshots.** A rising 5% beats a declining 15%.
5. **Segment everything.** The insight is almost always in a segment, not the average.
6. **Small numbers require humility.** <100 users in a cohort = directional only.
7. **Speed over precision.** Directionally correct in 30 minutes > precise in 3 days.
8. **Correlation ≠ causation.** Especially for Aha Moment candidates — validate with experiments.

---
