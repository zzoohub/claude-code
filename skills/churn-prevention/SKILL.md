---
name: churn-prevention
description: |
  Churn prevention strategies, cancel flow optimization, payment recovery, and customer health scoring.
  Use when: designing cancel flows, creating save offers, implementing dunning sequences,
  building health scores, reducing involuntary churn, diagnosing churn patterns,
  or when user mentions "churn", "cancel", "retention", "dunning", "payment failed",
  "failed payment", "payment recovery", "save offer", "cancel flow", "downgrade",
  "customer health", "at-risk customers", "subscription cancellation", "reduce churn rate",
  "churn analysis", "why are users leaving", "customer at risk".
  Do NOT use for: onboarding optimization (use cro skill), email sequences including
  win-back campaigns (use email-marketing skill), or pricing changes (use pricing skill).
---

# Churn Prevention

Strategies for reducing both voluntary and involuntary churn through proactive intervention, cancel flow optimization, and payment recovery.

---

## Churn Prevention Framework

### Understand Churn Types

**Voluntary churn** — Customer actively decides to cancel
- Causes: unmet expectations, found alternative, budget cuts, outgrew product
- Prevention: health monitoring, save offers, feature education, value reinforcement

**Involuntary churn** — Payment fails, customer didn't intend to leave
- Causes: expired card, insufficient funds, bank decline, billing errors
- Prevention: dunning sequences, card update prompts, retry logic
- **This is the easiest win** — often 20-40% of total churn

### Prevention Priority Order
1. Fix involuntary churn (dunning) — highest ROI, lowest effort
2. Identify at-risk users early (health scoring)
3. Intervene before they decide to cancel (proactive outreach)
4. Optimize the cancel flow (save offers, alternatives)

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Cancel flow design, save offers, exit surveys, proactive retention | `references/cancel-flow-patterns.md` |
| Payment failure recovery, dunning emails, retry logic | `references/dunning-playbook.md` |

Read the relevant reference when you need implementation details for a specific area. The sections below provide the strategic framework.

---

## Core Principles

### Prevention > Recovery
Catch at-risk users before they decide to leave. A user considering cancellation has already emotionally detached.

### Respect the User's Decision
No dark patterns. Make cancellation possible (don't hide it). Offer alternatives, not obstacles. Trust builds re-subscription later.

### Understand WHY Before Offering Saves
Exit survey data should drive save offer design. Don't offer a discount to someone who found an alternative — offer a feature comparison instead. See the dynamic save offers table in `references/cancel-flow-patterns.md` for the full reason-to-offer mapping with primary and fallback offers.

### Involuntary Churn is the Easiest Win
Payment failures are mechanical problems with mechanical solutions. Fix these first before tackling harder voluntary churn.

---

## Customer Health Score Framework

Track these signals to identify at-risk users before they churn:

### Usage Signals
- Login frequency (declining = risk)
- Feature adoption breadth (using 1 feature vs 5)
- Time spent in product (declining trend)
- Key action completion rate

### Engagement Signals
- Email open/click rates (declining = disengagement)
- Support ticket patterns (many tickets OR zero tickets = risk)
- Community/forum participation
- Feature request activity

### Business Signals
- Payment failures or late payments
- Plan downgrades
- Seat/usage reduction
- Contract renewal timing

### Implementation

Use a weighted composite score. A good starting point:

```
Health Score = (
  Login frequency score × 0.30 +
  Feature usage score   × 0.25 +
  Support sentiment     × 0.15 +
  Billing health        × 0.15 +
  Engagement score      × 0.15
)
```

Each component is scored 0-100. Normalize raw data (e.g., logins per week) into scores using percentile ranks or simple thresholds based on your user base.

| Score | Status | Action |
|-------|--------|--------|
| 80-100 | Healthy | Nurture, upsell opportunities |
| 60-79 | At Risk | Proactive check-in, feature education |
| 40-59 | Declining | Intervention: success call, personalized help |
| 0-39 | Critical | Urgent: executive outreach, retention offer |

For risk signals with specific timeframes and proactive intervention triggers, see the "Churn Prediction & Proactive Retention" section in `references/cancel-flow-patterns.md`.

---

## Churn Diagnosis

When analyzing why users are leaving, segment churn data to find patterns:

### Cohort Dimensions
- **Time cohort** — When did they sign up? (monthly cohorts reveal onboarding issues)
- **Plan tier** — Which plans churn most? (pricing or value mismatch)
- **Acquisition channel** — Organic vs paid vs referral (lead quality differences)
- **Usage pattern** — Power users vs casual (feature adoption gaps)
- **Cancel reason** — Exit survey data grouped by theme

### Key Questions
- What's the churn rate by cohort over time? (improving or worsening?)
- When do users churn? (first 30 days = onboarding problem, months 3-6 = value realization gap)
- What's the last action before churn? (reveals friction points)
- Which features do retained users use that churned users don't? (the "aha moment" gap)
- Is churn voluntary or involuntary? (very different solutions — check the split first)

### Churn Rate Benchmarks

| Segment | Poor | Average | Good |
|---------|------|---------|------|
| B2C monthly | >8% | 5-8% | <5% |
| B2B monthly | >5% | 2-5% | <2% |
| B2B annual (logo churn) | >15% | 8-15% | <8% |

---

## Cross-References

- **cro** (skill) — For optimizing specific flows (signup, onboarding, paywall)
- **email-marketing** (skill) — For win-back campaigns, re-engagement sequences, and dunning email copywriting
- **marketing-psychology** (skill) — For psychological principles in save offers (loss aversion, endowment effect)
- **product-analytics** (skill) — For retention cohort analysis and aha moment discovery
