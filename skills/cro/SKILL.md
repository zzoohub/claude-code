---
name: cro
description: |
  Conversion Rate Optimization for pages, forms, signup flows, onboarding, popups, paywalls, and checkout.
  Use when: analyzing page conversion, optimizing signup flows, improving onboarding activation,
  reducing form abandonment, creating/optimizing popups, improving paywall conversion,
  designing A/B tests, optimizing checkout flows, or when user mentions "conversion", "CRO",
  "optimize", "drop-off", "abandon", "friction", "paywall", "upgrade flow", "popup", "modal",
  "signup optimization", "landing page optimization", "why aren't people signing up",
  "improve my pricing page", "reduce bounce rate", "increase sign-ups", "cart abandonment",
  "checkout optimization", "not converting", "low conversion", "funnel optimization".
  Do NOT use for: writing copy (use copywriting skill), psychological principles (use marketing-psychology skill),
  or email optimization (use email-marketing skill).
---

# Conversion Rate Optimization

Systematic approach to improving conversion rates across pages, flows, forms, popups, and paywalls.

---

## Unified CRO Framework

Every conversion optimization follows this process:

### 1. Identify the Conversion Goal
What is the ONE primary action? Be specific: "signup", "upgrade to paid", "submit form", "complete onboarding step 3."

### 2. Map the Current Funnel
Document every step from entry to conversion. Identify where users enter, what they see, and where they drop off.

### 3. Prioritize by Impact
Analyze in this priority order (highest impact first):
1. **Value Proposition Clarity** — Can users understand what they get in 5 seconds?
2. **CTA Effectiveness** — Is the desired action visible, clear, and compelling?
3. **Friction Points** — What unnecessary steps, fields, or confusion exist?
4. **Trust Signals** — Is there enough social proof and credibility?
5. **Objection Handling** — Are common concerns addressed before the CTA?

Score each recommendation using **ICE**:
- **Impact** (1-10): How much will this move the conversion rate?
- **Confidence** (1-10): How sure are we this will work? (data > best practice > gut)
- **Ease** (1-10): How quickly can this be implemented?

ICE Score = (Impact + Confidence + Ease) / 3. Rank recommendations by score. Present the top items first.

### 4. Generate Recommendations
Structure output as:
- **Quick Wins** — Changes implementable in < 1 day
- **High-Impact Changes** — Larger changes with significant expected lift
- **Test Ideas** — Hypotheses to validate with A/B tests

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Landing/marketing page conversion | `references/page-cro.md` |
| Signup/registration flow | `references/signup-flow-cro.md` |
| Post-signup onboarding/activation | `references/onboarding-cro.md` |
| Lead capture/contact/checkout forms | `references/form-cro.md` |
| Popups/modals/overlays/banners | `references/popup-cro.md` |
| In-app upgrade/paywall/upsell | `references/paywall-upgrade-cro.md` |
| Checkout/cart/purchase flow | `references/checkout-cro.md` |
| A/B test design and analysis | `references/experiments.md` |

**Multi-area requests** (e.g., "optimize my SaaS funnel"): Read the most relevant reference first, then pull in additional references as needed. For full-funnel work, read in order: page → signup → onboarding → paywall. Synthesize into a single cohesive analysis — don't produce separate reports per area.

---

## Core CRO Principles

### Every Interaction Has a Cost
Every form field, every click, every page load reduces the percentage of users who continue. Justify every element.

### Value Before Ask
Show users what they get before asking them to commit. Experience before signup. Benefits before pricing.

### Reduce Perceived Effort
Progress indicators, smart defaults, pre-filled fields, and "just 2 minutes" messaging all reduce the feeling of work.

### One Primary Action Per Screen
Don't compete with yourself. One CTA, one goal, one message. Save secondary actions for after the primary conversion.

### Respect the User's Decision
No dark patterns. Easy to dismiss, easy to cancel, easy to go back. Trust builds long-term conversion.

### Test, Don't Assume
Every hypothesis needs validation. What works on one site may fail on another. See `references/experiments.md` for rigorous test design.

---

## CRO Analysis Output Template

```markdown
## CRO Analysis: [Page/Flow Name]

### Current State
- Conversion rate: X%
- Key drop-off point: [where]
- Primary issue: [what]

### Quick Wins (< 1 day)
1. [Change] — Expected impact: [high/medium/low]
2. [Change] — Expected impact: [high/medium/low]

### High-Impact Changes
1. [Change] — Rationale: [why]
2. [Change] — Rationale: [why]

### A/B Test Ideas
1. Hypothesis: [if we X, then Y, because Z]
2. Hypothesis: [if we X, then Y, because Z]

### Copy Alternatives
- Current: "[text]"
- Option A: "[text]" — [rationale]
- Option B: "[text]" — [rationale]
```

---

## Key Metrics by CRO Type

| Type | Primary Metric | Secondary Metrics |
|------|---------------|-------------------|
| Page | Visit → CTA click rate | Scroll depth, time on page, bounce rate |
| Signup | Form start → completion rate | Field drop-off, time to complete, error rate |
| Onboarding | Signup → Aha Moment rate | Time to first action, step completion |
| Form | Form view → submission rate | Field-level drop-off, error rate |
| Popup | Impression → conversion rate | Close rate, time to close |
| Paywall | View → upgrade rate | Click-through to pricing, plan selection |

---

## Cross-References

- **copywriting** (skill) — For conversion copy, CTA text, value propositions
- **marketing-psychology** (skill) — For persuasion principles behind CRO tactics
- **churn-prevention** (skill) — For post-conversion retention optimization
