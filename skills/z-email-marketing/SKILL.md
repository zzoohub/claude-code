---
name: z-email-marketing
metadata:
  version: 1.0.0
  category: marketing
description: |
  Email marketing strategy, sequence design, and campaign execution for SaaS products.
  Use when: creating email sequences (welcome, nurture, onboarding, re-engagement, win-back),
  designing drip campaigns, writing cold outreach, planning email strategy, optimizing email copy,
  or when user mentions "email sequence", "drip campaign", "welcome email", "onboarding email",
  "cold email", "outreach", "email marketing", "newsletter", "email copy", "subject line".
  Do NOT use for: in-app copy (use z-copywriting skill), popup/modal design (use z-cro skill),
  churn-specific emails like dunning (use z-churn-prevention skill), or analytics (use z-product-analytics skill).
---

# Email Marketing

Strategy, sequence design, and execution for email marketing across SaaS lifecycle stages.

---

## Email Marketing Framework

### 1. Assess
- **Sequence type**: Welcome, nurture, onboarding, re-engagement, win-back, cold outreach?
- **Audience context**: Where are they in the journey? What do they know? What do they need?
- **Goals**: Activation, conversion, retention, re-engagement, sales?

### 2. Core Principles
- **One Email, One Job** — Every email has exactly one purpose and one CTA
- **Value Before Ask** — Provide value in early emails before asking for conversion
- **Relevance Over Volume** — Better to send fewer, targeted emails than many generic ones
- **Clear Path Forward** — Every email tells the reader exactly what to do next

### 3. Sequence Strategy
- **Length**: Match sequence length to the buying cycle (SaaS trial: 5-7 emails, Enterprise: 8-12)
- **Timing**: Respect frequency. Day 0, 1, 3, 5, 7 for intensive onboarding. Weekly for nurture.
- **Subject lines**: Curiosity > benefit > urgency. Keep under 50 characters. Test personalization.
- **Preview text**: Complement the subject line, don't repeat it. Use as a second hook.

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Understanding email categories | `references/email-types.md` |
| Designing specific sequence flows | `references/sequence-templates.md` |
| Writing email copy, subject lines | `references/copy-guidelines.md` |
| B2B cold outreach and follow-ups | `references/cold-outreach.md` |

---

## Sequence Types Overview

### Welcome Sequence (5-7 emails, 12-14 days)
Goal: Activate new users, deliver first value, build relationship
Flow: Welcome → Quick win → Feature discovery → Social proof → Conversion nudge

### Lead Nurture (6-8 emails, 2-3 weeks)
Goal: Move leads from awareness to consideration
Flow: Value content → Problem education → Solution introduction → Social proof → Offer

### Re-engagement (3-4 emails, 2 weeks)
Goal: Reactivate dormant users
Flow: "We miss you" → New value/feature → Last chance → Sunset

### Onboarding (5-7 emails, 14 days)
Goal: Guide users to Aha Moment
Flow: Setup help → First action → Feature education → Success story → Upgrade prompt

### Cold Outreach (3-5 emails with follow-ups)
Goal: Start B2B conversations
Flow: Personal hook → Value offer → Social proof → Final ask

---

## Sequence Design Process

1. **Define the goal** — One clear outcome for the entire sequence
2. **Map the flow** — Each email's job and how it connects to the next
3. **Set timing** — Delays between emails based on urgency and user behavior
4. **Write emails** — Use `references/copy-guidelines.md` for structure and tone
5. **Set up measurement** — Track opens, clicks, conversions, unsubscribes per email

---

## Key Metrics

| Metric | Good | Great |
|--------|------|-------|
| Open rate | 20-30% | 30%+ |
| Click rate | 2-5% | 5%+ |
| Unsubscribe rate | < 0.5% | < 0.2% |
| Reply rate (cold) | 5-10% | 10%+ |
| Sequence completion | 60-70% | 80%+ |

---

## Tool Integrations

| Tool | Best For |
|------|----------|
| Customer.io | Behavior-triggered sequences, SaaS onboarding |
| Mailchimp | Newsletter, simple automations |
| Resend | Transactional + marketing for developers |
| SendGrid | High-volume transactional email |
| Kit (ConvertKit) | Creator-focused email marketing |

---

## Cross-References

- **z-copywriting** (skill) — For email copy quality and persuasion
- **z-churn-prevention** (skill) — For dunning and cancel-related emails
- **z-cro** (skill) — For onboarding flow optimization (email + in-app)
- **z-marketing-psychology** (skill) — For persuasion principles in email
