# Sequence Templates

Detailed templates for common email sequence types, including behavioral branching.

---

## Behavioral Branching

Linear sequences treat every subscriber the same. Real sequences branch based on what users do (or don't do). This matters because a user who activated on day 1 doesn't need the same email as someone who hasn't logged in.

### Branch Points

Add a branch after any email where the user's action changes what they need next:

```
Email 2: Quick Win
  ├── [Completed action] → Email 3a: "Nice work! Here's what's next"
  └── [No action after 48h] → Email 3b: "Need help getting started?"
```

### Common Branch Triggers

| Trigger | Branch to |
|---------|-----------|
| Completed setup | Skip setup reminders, advance to feature discovery |
| Opened but didn't click | Resend with different subject/angle |
| Clicked but didn't convert | Follow up on specific interest |
| No open after 48h | Try different subject line, check deliverability |
| Hit Aha Moment | Skip education, move to conversion |
| Upgraded to paid | Exit sequence or move to expansion |

### When to Branch vs. Stay Linear

- **Branch** when the user's next need depends on their action (onboarding, trial conversion)
- **Stay linear** when the content is time-based and universal (newsletter, content nurture)
- **Exit early** when the goal is achieved (user activated, converted, or explicitly disengaged)

---

## Welcome Sequence (Post-Signup)

**Length**: 5-7 emails over 12-14 days
**Goal**: Activate, build trust, convert

| # | Email | Timing | Purpose | Branch |
|---|-------|--------|---------|--------|
| 1 | Welcome + deliver value | Immediate | Set expectations, deliver promised content | — |
| 2 | Quick win | Day 1-2 | Drive to first successful action | If completed → skip to #4 |
| 3 | Story/Why | Day 3-4 | Build connection, share origin story | — |
| 4 | Social proof | Day 5-6 | Build trust with testimonials/results | — |
| 5 | Overcome objection | Day 7-8 | Address top objection proactively | — |
| 6 | Core feature highlight | Day 9-11 | Expand awareness of value | — |
| 7 | Conversion | Day 12-14 | Clear CTA to upgrade/buy | — |

**Branch detail for Email 2:**
```
Email 2: Quick Win
  ├── [User completed first action]
  │   → Skip Email 3, send Email 4 (social proof) on Day 3
  │   → They already trust you enough to act; reinforce with proof
  └── [No action after 48h]
      → Send "Need help?" variant of Email 3 instead of story
      → They're stuck, not uninterested — remove friction
```

---

## Lead Nurture Sequence (Pre-Sale)

**Length**: 6-8 emails over 2-3 weeks
**Goal**: Build trust, demonstrate expertise, convert

| # | Email | Timing | Purpose |
|---|-------|--------|---------|
| 1 | Deliver lead magnet + intro | Immediate | Fulfill promise, introduce yourself |
| 2 | Expand on topic | Day 2-3 | Deep-dive on related concept |
| 3 | Problem deep-dive | Day 4-5 | Articulate their pain clearly |
| 4 | Solution framework | Day 6-8 | Show how to solve (product-agnostic) |
| 5 | Case study | Day 9-11 | Proof it works |
| 6 | Differentiation | Day 12-14 | Why your approach is different |
| 7 | Objection handler | Day 15-18 | Address top concerns |
| 8 | Direct offer | Day 19-21 | Clear CTA with urgency |

**Branch:** If the lead clicks the offer link in any email before #8, exit the nurture sequence and enter a shorter conversion sequence focused on their specific interest.

---

## Onboarding Sequence (Product Users)

**Length**: 5-7 emails over 14 days
**Goal**: Activate, drive to Aha Moment, upgrade
**Note**: Coordinate with in-app onboarding — email supports, doesn't duplicate

| # | Email | Timing | Purpose | Branch |
|---|-------|--------|---------|--------|
| 1 | Welcome + first step | Immediate | Guide to first action | — |
| 2 | Getting started help | Day 1 | Overcome setup friction | If setup complete → skip to #3 |
| 3 | Feature highlight | Day 2-3 | Expand usage | — |
| 4 | Success story | Day 4-5 | Show what's possible | — |
| 5 | Check-in | Day 7 | Personal touch, offer help | If inactive → re-engagement branch |
| 6 | Advanced tip | Day 10-12 | Deepen engagement | — |
| 7 | Upgrade/expand | Day 14+ | Convert to paid/higher tier | — |

**Branch detail for Email 5:**
```
Email 5: Check-in (Day 7)
  ├── [Active user — used product 3+ times this week]
  │   → Send Email 6: Advanced tip (they're ready)
  ├── [Low activity — logged in but hasn't hit Aha Moment]
  │   → Send targeted email about the specific feature closest to their Aha Moment
  └── [Inactive — no login in 5+ days]
      → Enter re-engagement mini-sequence (3 emails)
      → "We noticed you haven't had a chance to try X yet..."
```

---

## Re-Engagement Sequence

**Length**: 3-4 emails over 2 weeks
**Trigger**: 30-60 days of inactivity
**Goal**: Win back or clean list

| # | Email | Timing | Purpose |
|---|-------|--------|---------|
| 1 | Check-in | Day 0 | Genuine concern, "still interested?" |
| 2 | Value reminder | Day 3-4 | What's new, what they're missing |
| 3 | Incentive | Day 7-8 | Special offer to re-engage |
| 4 | Last chance | Day 14 | Stay or unsubscribe (clean list) |

**Exit rule:** If the user re-engages at any point (opens + clicks), exit this sequence and route them back to the appropriate active sequence based on their lifecycle stage.

---

## Output Template

### Sequence Overview
```
Sequence Name: [Name]
Trigger: [What starts the sequence]
Goal: [Primary conversion goal]
Length: [Number of emails]
Timing: [Delay between emails]
Exit Conditions: [When they leave the sequence]
Branch Points: [Key decision points based on user behavior]
```

### Per-Email Template
```
Email [#]: [Name/Purpose]
Send: [Timing]
Subject: [Subject line]
Preview: [Preview text]
Body: [Full copy]
CTA: [Button text] → [Link destination]
Branch: [If action → next email / If no action → alternative]
Segment/Conditions: [If applicable]
```
