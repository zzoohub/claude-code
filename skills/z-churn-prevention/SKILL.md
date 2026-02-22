---
name: z-churn-prevention
description: |
  Churn prevention strategies, cancel flow optimization, payment recovery, and customer health scoring.
  Use when: designing cancel flows, creating save offers, implementing dunning sequences,
  building health scores, reducing involuntary churn, analyzing churn patterns,
  or when user mentions "churn", "cancel", "retention", "dunning", "payment failed",
  "win-back", "save offer", "cancel flow", "downgrade", "customer health".
  Do NOT use for: onboarding optimization (use z-cro), email sequences (use z-email-marketing),
  analytics/data analysis (use z-data-analyst), or pricing changes (use z-pricing).
metadata:
  version: 1.0.0
  category: growth
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
5. Win back churned users (re-engagement campaigns)

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Cancel flow design, save offers, exit surveys | `references/cancel-flow-patterns.md` |
| Payment failure recovery, dunning emails, retry logic | `references/dunning-playbook.md` |

---

## Core Principles

### Prevention > Recovery
Catch at-risk users before they decide to leave. A user considering cancellation has already emotionally detached.

### Respect the User's Decision
No dark patterns. Make cancellation possible (don't hide it). Offer alternatives, not obstacles. Trust builds re-subscription later.

### Understand WHY Before Offering Saves
Exit survey data should drive save offer design. Don't offer a discount to someone who found an alternative — offer a feature comparison instead.

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

### Health Score Actions

| Score | Status | Action |
|-------|--------|--------|
| 80-100 | Healthy | Nurture, upsell opportunities |
| 60-79 | At Risk | Proactive check-in, feature education |
| 40-59 | Declining | Intervention: success call, personalized help |
| 0-39 | Critical | Urgent: executive outreach, retention offer |

---

## Save Offer Decision Tree

Based on cancellation reason:

| Reason | Offer |
|--------|-------|
| Too expensive | Discount, downgrade option, annual pricing |
| Missing feature | Roadmap preview, workaround, feature education |
| Found alternative | Competitive comparison, switching cost reminder |
| Not using enough | Onboarding reset, use case guidance |
| Temporary need | Pause subscription option |
| Budget/downsizing | Pause or reduced plan |

---

## Output Locations

| Deliverable | Path |
|------------|------|
| Churn prevention strategy | `biz/growth/churn-prevention.md` |
| Dunning / payment recovery | `biz/growth/dunning.md` |
| Customer health score | `biz/analytics/health-score.md` |

## Cross-References

- **z-cro** — For optimizing specific flows (signup, onboarding, paywall)
- **z-email-marketing** — For win-back and re-engagement email sequences
- **z-data-analyst** — For churn cohort analysis and health score modeling
- **z-marketing-psychology** — For psychological principles in save offers (loss aversion, endowment effect)
