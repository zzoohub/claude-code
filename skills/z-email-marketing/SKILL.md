---
name: z-email-marketing
metadata:
  version: 1.1.0
  category: marketing
description: |
  Email marketing strategy, sequence design, and campaign execution for SaaS products.
  Use when: creating email sequences (welcome, nurture, onboarding, re-engagement, win-back),
  designing drip campaigns, writing cold outreach, planning email strategy, optimizing email copy,
  building email automations, or when user mentions "email sequence", "drip campaign", "welcome email",
  "onboarding email", "cold email", "outreach", "email marketing", "newsletter", "email copy",
  "subject line", "email campaign", "email flow", "email funnel", "automated emails",
  "follow-up sequence", "lead magnet delivery", "email automation".
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

- **One Email, One Job** — Every email has exactly one purpose and one CTA. When an email tries to do two things, neither gets done well — and you can't tell from metrics which one failed. If you need to accomplish two goals, that's two emails.

- **Value Before Ask** — Provide value in early emails before asking for conversion. People ignore emails from senders who only take. The first 2-3 emails in any sequence should make the reader's life better with zero strings attached — that builds the trust that makes later conversion emails work.

- **Relevance Over Volume** — Better to send fewer, targeted emails than many generic ones. Every irrelevant email trains the reader to stop opening your emails. One well-timed, behavior-triggered email outperforms five time-based blasts.

- **Clear Path Forward** — Every email tells the reader exactly what to do next. Ambiguity kills action. If the reader finishes your email thinking "nice, but what now?", the email failed regardless of how good the copy was.

### 3. Sequence Strategy
- **Length**: Match sequence length to the buying cycle (SaaS trial: 5-7 emails, Enterprise: 8-12)
- **Timing**: Respect frequency. Day 0, 1, 3, 5, 7 for intensive onboarding. Weekly for nurture.
- **Subject lines**: Curiosity > benefit > urgency. Keep under 50 characters. Test personalization.
- **Preview text**: Complement the subject line, don't repeat it. Use as a second hook.

---

## When to Use Which Reference

| Scenario | Reference |
|----------|-----------|
| Designing sequence flows and timing | `references/sequence-templates.md` |
| Writing email copy, subject lines, CTAs | `references/copy-guidelines.md` |
| Understanding email categories and what to build first | `references/email-types.md` |
| B2B cold outreach and follow-ups | `references/cold-outreach.md` |
| Deliverability, DNS, warm-up, list hygiene | `references/deliverability.md` |

---

## Sequence Design Process

1. **Define the goal** — One clear outcome for the entire sequence
2. **Map the flow** — Each email's job and how it connects to the next
3. **Add branch points** — Where should the sequence split based on user behavior? (See `references/sequence-templates.md` for branching patterns)
4. **Set timing** — Delays between emails based on urgency and user behavior
5. **Write emails** — Use `references/copy-guidelines.md` for structure and tone
6. **Set up measurement** — Track opens, clicks, conversions, unsubscribes per email

---

## Default Output Format

When creating email sequences, produce this structure unless the user requests something different:

### Sequence Overview
```
Sequence: [Name]
Trigger: [What starts the sequence]
Goal: [Primary outcome]
Length: [N emails over N days]
Exit conditions: [When someone leaves the sequence early]
```

### Per Email
```
Email [#]: [Name]
Send: [Timing / trigger]
Subject: [Subject line]
Preview: [Preview text]
---
[Full email copy]
---
CTA: [Button text] → [Destination]
Branch: [If applicable — what happens based on action/inaction]
```

For strategy-only requests (no copy), produce the overview table with timing, purpose, and subject line direction per email — skip full copy.

---

## Diagnosing Email Problems

When metrics are underperforming, the problem usually lives in a specific layer. Work top-down:

| Symptom | Likely cause | What to check |
|---------|-------------|---------------|
| Low open rate (<20%) | Subject line or deliverability | Are you landing in spam? Check `references/deliverability.md`. If deliverability is fine, the subject lines aren't earning opens — test curiosity and benefit hooks. |
| Opens but low clicks (<2%) | Copy or CTA mismatch | The email isn't delivering on the subject line's promise, or the CTA is unclear/high-friction. Check body copy relevance and CTA placement. |
| Clicks but no conversion | Landing page or offer | The email did its job — the problem is downstream. Check landing page alignment with email promise. |
| High unsubscribe (>0.5%) | Frequency or relevance | Sending too often, or content doesn't match what they signed up for. Segment harder or reduce frequency. |
| Low reply rate on cold (<5%) | Personalization or ask | The email reads like a template or asks too much. See `references/cold-outreach.md`. |
| Declining open rates over time | List fatigue | Re-engagement sequence needed. Sunset non-openers after 90 days. |

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
