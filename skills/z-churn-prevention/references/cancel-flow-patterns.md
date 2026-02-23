# Cancel Flow Patterns

Detailed cancel flow design patterns, exit survey strategies, and save offer frameworks.

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
| Switching to competitor | Competitive comparison + discount | Feedback session |
| Technical issues | Escalate to support immediately | Credit + priority fix |
| Temporary / seasonal | Pause subscription | Downgrade temporarily |
| Business closed | Skip offer (respect the situation) | — |

---

## Save Offer Types

### Discount
- 20-30% off for 2-3 months is the sweet spot
- Avoid 50%+ discounts (trains customers to cancel for deals)
- Time-limit the offer ("expires when you leave this page")
- Show dollar amount saved, not just percentage

### Pause Subscription
- 1-3 month pause maximum (longer pauses rarely reactivate)
- 60-80% of pausers eventually return
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

## Cancel Flow UI Pattern

```
┌─────────────────────────────────────┐
│  We're sorry to see you go          │
│                                     │
│  What's the main reason you're      │
│  cancelling?                        │
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
│  [Never mind, keep my subscription] │
└─────────────────────────────────────┘
         ↓ (selects "Too expensive")
┌─────────────────────────────────────┐
│  What if we could help?             │
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
│  [No thanks, continue cancelling]   │
└─────────────────────────────────────┘
```

### UI Principles
- Keep "continue cancelling" option visible (no dark patterns)
- One primary offer + one fallback, not a wall of options
- Show specific dollar savings, not abstract percentages
- Use customer's name and account data when possible
- Mobile-friendly (many cancellations happen on mobile)

---

## Churn Prediction & Proactive Retention

### Risk Signals

| Signal | Risk Level | Timeframe |
|--------|-----------|-----------|
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
- **Guilt-trip copy** — Damages brand trust
- **Not tracking save offer LTV** — "Saved" customer who churns in 30 days wasn't really saved
- **Pausing too long** — Pauses beyond 3 months rarely reactivate

---

## Metrics

| Metric | Target |
|--------|--------|
| Monthly churn rate | <5% B2C, <2% B2B |
| Cancel flow save rate | 25-35% |
| Offer acceptance rate | 15-25% |
| Pause reactivation rate | 60-80% |
| Time to cancel (from first signal) | Track trend |
