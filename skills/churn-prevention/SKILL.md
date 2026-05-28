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
  Do NOT use for: onboarding optimization (use cro skill), general marketing
  email sequences including win-back campaigns (use email-marketing skill), or
  pricing changes (use pricing skill). Carve-out: dunning emails (payment-failure
  recovery) ARE owned here in `references/dunning-playbook.md` because they're
  tightly coupled to retry logic and billing state, not general marketing.
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

## Compliance & Click-to-Cancel (2025-2026 landscape)

> **Not legal advice — verify against current law in every region you serve before launching any cancel flow.**

### US — FTC
- The FTC's federal "Click to Cancel" Rule was **vacated by the 8th Circuit on 2025-07-08** on procedural grounds (no preliminary regulatory analysis).
- The FTC submitted a draft Advance Notice of Proposed Rulemaking (ANPRM) on 2026-01-30 to restart the rulemaking with proper procedure.
- **Enforcement under existing unfair/deceptive-practices doctrine continues.** State AGs have also stepped up enforcement.

### California — AB 2863 (Automatic Renewal Law amendments)
- **Effective 2025-07-01.** Applies to contracts entered into, amended, or extended on or after that date.
- **Same-medium cancellation** required: if a consumer signs up online, they must be able to cancel online with equal ease. No phone-only or in-person-only cancellation paths.
- "Click-to-cancel" button required for online cancellations; cannot obstruct or delay.
- Expanded definitions of "automatic renewal" and "continuous service" cover **free trials and free-to-pay conversions**.
- **Express affirmative consent** to renewal terms required; records retained ≥3 years (or 1 year post-termination, whichever is longer).
- Enforcement by California AG, district attorneys, and private plaintiffs.

### New York — Click-to-Cancel Act (2025 Budget Bill)
- Signed 2025-05-09 as part of the state budget; **effective 2025-11-05**.
- Simple cancellation mechanism **as easy as the one used to consent, in the same medium**. If consent was online, cancellation must be online; in-person consent must also offer online or phone cancellation.
- Companies cannot impose unreasonable or unlawful conditions, refuse, obstruct, or unreasonably delay cancellation.

### Other US states with auto-renewal rules
Colorado, Vermont, Illinois, and others have analogous 2025 laws — confirm requirements in every state you serve.

### EU/UK
GDPR + the Digital Services Act / Digital Markets Act framework already restrict "dark patterns" around cancellation. Consumer protection authorities (e.g., France's DGCCRF) have started enforcement on subscription-trap patterns from 2024-2025.

### Practical cancel-flow checklist (compliance-safe)
- [ ] **Same-medium cancellation** — if signup was online, cancellation is online (no phone-only)
- [ ] **One-click path** — explicit "Cancel my subscription" button visible without forced multi-step survey
- [ ] **No required survey before cancellation** — surveys must be skippable
- [ ] **No required save-offer view** — offers are skippable, not blocking
- [ ] **Cancellation confirmed by email** with effective date
- [ ] **No re-enrollment without fresh affirmative consent**
- [ ] **Records of consent and cancellation retained** per applicable law (CA: 3 years minimum)
- [ ] **Clear cost disclosure** before any save offer

See `references/cancel-flow-patterns.md` for compliant UI patterns.

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
