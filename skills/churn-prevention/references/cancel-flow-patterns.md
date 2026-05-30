# Cancel Flow Patterns

Detailed cancel flow design patterns, exit survey strategies, and save offer frameworks.

## Table of Contents

1. [Cancel Flow Structure](#cancel-flow-structure)
2. [Exit Survey Design](#exit-survey-design)
3. [Dynamic Save Offers](#dynamic-save-offers)
4. [Save Offer Types](#save-offer-types)
5. [Refunds, Proration & Credits](#refunds-proration--credits)
6. [Cancel Flow UI Pattern (compliance-safe)](#cancel-flow-ui-pattern-compliance-safe)
7. [Churn Prediction & Proactive Retention](#churn-prediction--proactive-retention)
8. [Common Mistakes](#common-mistakes)
9. [Metrics](#metrics)

---

## Cancel Flow Structure

```
Trigger → Survey → Dynamic Offer → Confirmation → Post-Cancel
```

1. **Trigger** — Customer clicks "Cancel subscription"
2. **Exit Survey** — Ask why (determines which save offer)
3. **Dynamic Save Offer** — Targeted offer based on reason
4. **Confirmation** — Clear end-of-billing-period messaging
5. **Post-Cancel** — Set expectations, easy reactivation, trigger win-back

---

## Exit Survey Design

### Reason Categories

| Reason | What It Tells You |
|--------|-------------------|
| Too expensive | Price sensitivity, may respond to discount or downgrade |
| Not using it enough | Low engagement, may respond to pause or onboarding help |
| Missing a feature | Product gap, show roadmap or workaround |
| Switching to competitor | Competitive pressure, understand what they offer |
| Technical issues / bugs | Product quality, escalate to support |
| Temporary / seasonal need | Usage pattern, offer pause |
| Business closed / changed | Unavoidable, let go gracefully |
| Other | Catch-all with free text field |

### Survey Best Practices
- 1 question, single-select with optional free text
- 5-8 reason options max (avoid decision fatigue)
- Put most common reasons first (review data quarterly)
- Don't make it feel like a guilt trip
- "Help us improve" framing > "Why are you leaving?"

---

## Dynamic Save Offers

**Key insight: match the offer to the reason.**

| Cancel Reason | Primary Offer | Fallback Offer |
|---------------|---------------|----------------|
| Too expensive | Discount (20-30% for 2-3 months) | Downgrade to lower plan |
| Not using enough | Pause (1-3 months) | Free onboarding session |
| Missing feature | Roadmap preview + timeline | Workaround guide |
| Switching to competitor | Competitive comparison / differentiation (what we do that they don't) | Feedback session or targeted feature unlock |
| Technical issues | Escalate to support immediately | Credit + priority fix |
| Temporary / seasonal | Pause subscription | Downgrade temporarily |
| Business closed | Skip offer (respect the situation) | — |

> **Don't discount alternative-seekers.** A customer switching to a competitor is responding to a perceived capability gap, not price — lead with differentiation, not a discount (which also trains cancel-and-return behavior). Reserve discounts for the "Too expensive" reason. This mirrors the core principle in `SKILL.md`.

---

## Save Offer Types

### Discount
- 20-30% off for 2-3 months is the sweet spot
- Avoid 50%+ discounts (trains customers to cancel for deals)
- Only claim the offer is time-limited if it genuinely is — don't use false urgency like "expires when you leave this page" unless the offer truly won't be repeated (fake expiry is a dark pattern the FTC flags and contradicts the "no dark patterns" principle)
- Show dollar amount saved, not just percentage

### Pause Subscription
- 1-3 month pause maximum (longer pauses rarely reactivate)
- Roughly 40-80% of pausers eventually return (well-run, short-duration programs reach 60-80%; many land in 35-60%, and 3-month+ pauses skew lower) — versus only ~3-10% reactivation for fully-cancelled subscribers won back later
- Auto-reactivation with advance notice email
- Keep data and settings intact

### Plan Downgrade
- Offer lower tier instead of full cancellation
- Show what they keep vs. what they lose
- "Right-size your plan" not "downgrade"
- Easy path back up when ready

### Feature Unlock / Extension
- Unlock a premium feature they haven't tried
- Extend trial of a higher tier
- Best for "not getting enough value" reasons

### Personal Outreach
- For high-value accounts (top 10-20% by MRR)
- Route to customer success for a call
- Personal email from founder for smaller companies

---

## Refunds, Proration & Credits

Cancellation and downgrade decisions touch money already collected — address it explicitly:

- **Refund posture at cancellation** — decide and disclose whether cancellation is full-refund, prorated, or no-refund (access continues to end of paid period). State it on the confirmation screen, not just the end-of-billing-period date.
- **Proration on downgrade** — when offering a plan downgrade as a save, specify whether the already-paid period is prorated or credited toward the lower tier.
- **Partial-period credits** — for technical issues / outages, a credit is often a better save than a discount.
- **Compliance interaction** — refund and cancellation-timing obligations can be set by jurisdiction (the auto-renewal and EU/UK consumer laws cited in `SKILL.md` § Compliance). Treat refund posture under the "not legal advice — verify per region" framing, not as a purely discretionary lever.

---

## Cancel Flow UI Pattern (compliance-safe)

> **Compliance note (not legal advice — verify against current law in every region you serve):** Under California AB 2863 (eff. 2025-07-01) and New York's Click-to-Cancel Act (eff. 2025-11-05), the survey and save-offer screens must be **skippable**. A user who signed up online must be able to cancel online with no required multi-step process. The "Skip — cancel now" link below is non-negotiable for US-regulated subscriptions. Note: the FTC's federal Click-to-Cancel Rule was vacated by the 8th Circuit on 2025-07-08, so there is no nationwide click-to-cancel mandate today — obligations currently come from state laws (CA/NY plus the broader auto-renewal patchwork), ROSCA, and general unfair/deceptive-practices (FTC Act §5 / state UDAP) enforcement; the FTC restarted rulemaking via a draft ANPRM on 2026-01-30, so a federal rule may return. See `SKILL.md` § Compliance & Click-to-Cancel.

```
┌─────────────────────────────────────┐
│  We're sorry to see you go          │
│                                     │
│  (Optional) What's the main reason  │
│  you're cancelling?                 │
│                                     │
│  ○ Too expensive                    │
│  ○ Not using it enough              │
│  ○ Missing a feature I need         │
│  ○ Switching to another tool        │
│  ○ Technical issues                 │
│  ○ Temporary / don't need right now │
│  ○ Other: [____________]            │
│                                     │
│  [Continue]                         │
│  [Skip — cancel now]      ← REQUIRED│
│  [Never mind, keep my subscription] │
└─────────────────────────────────────┘
         ↓ (selects "Too expensive" — survey is optional)
┌─────────────────────────────────────┐
│  Before you go — one option         │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  25% off for the next 3 months│  │
│  │  Save $XX/month               │  │
│  │  [Accept Offer]               │  │
│  └───────────────────────────────┘  │
│                                     │
│  Or switch to [Basic Plan] at       │
│  $X/month →                         │
│                                     │
│  [No thanks, cancel now]  ← REQUIRED│
└─────────────────────────────────────┘
         ↓ (one click)
┌─────────────────────────────────────┐
│  ✓ Your subscription is cancelled.  │
│  Effective: [date]                  │
│  Confirmation email sent to you.    │
└─────────────────────────────────────┘
```

### UI Principles
- **"Skip — cancel now" must be visible on every screen** between intent and final cancellation (CA AB 2863 / NY 2025 compliance)
- Survey questions must be **optional** — no required answer to proceed
- On the save-offer screen the cancel action must be **at least as visually prominent as the offer's accept button** — a direct "cancel now" path, not a de-emphasized secondary text link
- One primary offer + one fallback, not a wall of options
- Show specific dollar savings, not abstract percentages
- Use customer's name and account data when possible
- Mobile-friendly (many cancellations happen on mobile)
- Cancellation completes in ≤ 3 clicks from intent
- Confirmation email sent automatically with effective date

---

## Churn Prediction & Proactive Retention

### Risk Signals

Lead times below are directional rules-of-thumb from common SaaS practice, not measured benchmarks — calibrate against your own churned-cohort data before wiring them into intervention timers. For B2B (sales-led / multi-seat / annual), treat seat reduction, declining champion engagement, and renewal proximity as the leading indicators rather than individual login frequency.

| Signal | Risk Level | Typical lead time (heuristic) |
|--------|-----------|-------------------------------|
| Login frequency drops 50%+ | High | 2-4 weeks before cancel |
| Key feature usage stops | High | 1-3 weeks before cancel |
| Support tickets spike then stop | High | 1-2 weeks before cancel |
| Email open rates decline | Medium | 2-6 weeks before cancel |
| Billing page visits increase | High | Days before cancel |
| Team seats removed | High | 1-2 weeks before cancel |
| Data export initiated | Critical | Days before cancel |
| NPS score drops below 6 | Medium | 1-3 months before cancel |

### Proactive Interventions

| Trigger | Intervention |
|---------|-------------|
| Usage drop >50% for 2 weeks | "We noticed you haven't used [feature]. Need help?" |
| No login for 14 days | Re-engagement email with recent product updates |
| NPS detractor (0-6) | Personal follow-up within 24 hours |
| Support ticket unresolved >48h | Escalation + proactive status update |
| Annual renewal in 30 days | Value recap email + renewal confirmation |

---

## Common Mistakes

- **No cancel flow at all** — Even a simple survey + one offer saves 10-15%
- **Making cancellation hard to find** — Hidden cancel buttons breed resentment
- **Same offer for every reason** — Blanket discount doesn't address "missing feature"
- **Discounts too deep** — 50%+ trains cancel-and-return behavior
- **Fake urgency** — Countdown timers or "expires when you leave" claims that aren't real are dark patterns the FTC flags
- **Guilt-trip copy** — Damages brand trust
- **Not tracking save offer LTV** — "Saved" customer who churns in 30 days wasn't really saved
- **Pausing too long** — Pauses beyond 3 months rarely reactivate

---

## Metrics

Save rate is a vanity metric on its own — only count a save that survives the post-save retention window at non-negative net margin (see Common Mistakes: "Not tracking save offer LTV"). Track the durability and economics metrics alongside it.

| Metric | Target |
|--------|--------|
| Monthly churn rate | <5% B2C, <2% B2B |
| Cancel flow save rate | 25-35% |
| Offer acceptance rate | 15-25% blended (directional — varies widely by offer type: discount ~50-60%+, pause ~20%, downgrade <10%) |
| Pause reactivation rate | 40-80% (60-80% for well-run short-pause programs; lower for 3-month+ pauses) |
| Win-back reactivation (fully cancelled) | ~3-10% |
| Post-save retention | ≥70-80% of saved accounts still active at 90 days (tune to baseline) |
| Net incremental revenue per save | Retained MRR over the window minus discount/credit cost — flag negative values as fake saves (ideally measured vs a hold-out of non-offered cancelers) |
| Time to cancel (from first signal) | Track trend |
