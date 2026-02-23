---
name: z-product-analytics
description: |
  Product analytics methodology for SaaS: Aha Moment discovery, retention cohort analysis,
  Carrying Capacity modeling, PMF assessment, and Kill/Keep/Scale decisions.
  Use when: finding or validating Aha Moments, analyzing retention curves, calculating Carrying Capacity,
  assessing product-market fit, making Kill/Keep/Scale decisions, diagnosing activation bottlenecks,
  building cohort tables, segmenting retained vs churned users, evaluating CC trends,
  designing event tracking plans, setting up GA4/GTM, analyzing A/B test results,
  or when user mentions "Aha Moment", "retention curve", "cohort analysis", "Carrying Capacity",
  "PMF", "product-market fit", "kill criteria", "activation rate", "retention plateau",
  "churn analysis", "user segmentation", "D7 retention", "D30 retention",
  "tracking plan", "GA4", "GTM", "UTM", "A/B test results".
  Do NOT use for: tracking code implementation (developer task),
  CRO experiment design (use z-cro skill), marketing content (use z-copywriting skill).
metadata:
  version: 1.1.0
  category: analytics
---

# Product Analytics Methodology

Frameworks for discovering what drives retention, measuring product health, and making data-driven kill/keep/scale decisions.

---

## Core Mental Model

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

---

## Quick Decision Framework

### Is there PMF?

```
Plot cohort retention curves (D1, D7, D14, D30, D60, D90)
├── Curve keeps declining without flattening → No PMF. Fix product.
├── Curve flattens but plateau < 10% → Weak PMF. Improve activation.
└── Curve flattens with plateau > 15% → PMF exists. Optimize growth.
```

### What to fix first?

Always in this order (most teams do it backwards):
1. **Retention** — Raise the plateau height
2. **Activation** — Get more users to Aha Moment
3. **Acquisition** — Only after 1 & 2 are healthy

### Kill/Keep/Scale?

| Signal | Kill | Keep | Scale |
|--------|------|------|-------|
| Retention plateau | None | Emerging (<15%) | Established (>15%) |
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

## Cross-References

- **z-cro** (skill) — For experiment design to improve activation flows
- **z-growth-optimizer** (skill) — For referral loops and growth experiments
- **z-churn-prevention** (skill) — For post-retention churn interventions
