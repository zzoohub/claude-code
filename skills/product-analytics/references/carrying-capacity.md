# Carrying Capacity & Kill/Keep/Scale

## What Is Carrying Capacity?

Carrying Capacity (CC) is the natural equilibrium MAU a product settles at without paid marketing. It's borrowed from ecology — just as an ecosystem can only sustain a certain population, a product can only sustain a certain user base given its organic inflow and churn rate.

```
CC = Daily Organic Inflow / Daily Churn Rate
```

Marketing spend can temporarily push MAU above CC, but it always falls back. **The only way to raise CC is to improve the product** — increase organic inflow (word-of-mouth, SEO, virality) or decrease churn (better retention, more value).

CC is the single most honest metric in product analytics. It strips away the noise of launch spikes, ad spend, and press coverage to reveal what the product can sustain on its own.

---

## Components

### Daily Organic Inflow
Users who arrive without paid acquisition. Includes:

| Source | Description | Signal |
|--------|------------|--------|
| **Direct/Organic search** | Users who search for you or your category | Brand awareness, SEO strength |
| **Word-of-mouth** | Users referred by existing users (informally) | Product quality, delight |
| **Referral program** | Users from structured referral loops | Viral mechanics working |
| **Resurrected users** | Previously churned users who return | Product improvements reaching former users |
| **Content/SEO** | Users from blog, guides, free tools | Content marketing working |

**Exclude**: Paid ads, sponsored posts, one-time PR spikes, launch traffic.

### Daily Churn Rate
The percentage of active users who become inactive per day. For practical calculation:

```
Daily Churn Rate = Users who churned this period / Active users at start of period / Days in period
```

Or more commonly, use weekly/monthly and adjust:

```
CC (weekly) = Weekly Organic Inflow / Weekly Churn Rate
CC (monthly) = Monthly Organic Inflow / Monthly Churn Rate
```

---

## Calculating CC

### Method 1: Direct Calculation

```
1. Measure organic inflow over 30 days (exclude all paid channels)
2. Measure churn over same 30 days
3. CC = Monthly Organic Inflow / Monthly Churn Rate
```

**Example:**
- 600 organic signups/month
- 8% monthly churn rate
- CC = 600 / 0.08 = 7,500 MAU

### Method 2: Trailing Average Observation

If you stop all paid acquisition and wait, MAU will converge toward CC. Track:

```
CC (7d trailing) = Average of last 7 days' organic inflow / Average of last 7 days' churn rate
CC (30d trailing) = Same over 30 days
```

**Reading the trailing averages:**
- 7d CC rising + 30d CC rising = Improvements are working, sustained
- 7d CC rising + 30d CC flat = Recent change showing promise, wait to confirm
- 7d CC flat + 30d CC rising = Older improvements still compounding
- 7d CC declining + 30d CC flat = Recent regression, investigate
- Both declining = Product health deteriorating, urgent

### Method 3: Infer from Stable Periods

If there's been a period with no marketing spend changes and MAU was relatively stable, that stable MAU ≈ CC.

---

## CC as a Decision-Making Tool

### Why CC, Not MAU?

MAU is vanity. It includes the effects of ad spend, viral spikes, press mentions — all temporary. CC tells you what's left when the noise stops.

**Example:**
- Product A: 50,000 MAU, $20k/month in ads, CC = 12,000
- Product B: 18,000 MAU, $0 in ads, CC = 18,000

Product B is healthier. Product A's MAU will drop to ~12,000 if ads stop.

### CC Trend Is More Important Than CC Level

A CC of 5,000 that's been rising 10%/month is better than a CC of 20,000 that's been flat. Trend tells you if improvements are working.

Track CC over time and annotate:
- Product changes (new features, UX improvements)
- Onboarding changes
- Viral loop launches
- Content/SEO investments
- **Look for which changes move the 7d CC first, then confirm on 30d**

---

## Kill/Keep/Scale Framework

This is the master decision. Every product should be assessed regularly (weekly for early-stage, monthly for established).

### Decision Matrix

| Signal | Kill | Keep (Fix) | Scale |
|--------|------|------------|-------|
| **Retention plateau** | None after 8+ weeks | Emerging but weak (<15%) | Established (>15%) |
| **CC trend (30d)** | Declining or zero | Flat or slowly rising | Consistently rising |
| **Activation rate** | <10% | 10-30% | >30% |
| **Organic inflow** | Near zero or declining | Steady | Growing without paid push |
| **Usage frequency** | <1x/month | 1-3x/month | >3x/month |
| **Time to Aha Moment** | >14 days or undefined | 3-14 days | <3 days |
| **Qualitative signal** | Users don't care it exists | Users say "nice to have" | Users say "very disappointed" without it |

### Kill Criteria

A product should be killed (or pivoted) when:
- No retention plateau after 8+ weeks with real users
- CC is declining despite product improvements
- Activation rate stays <10% after 3+ onboarding iterations
- Usage frequency <1x/month (habitual use is impossible)
- Sean Ellis survey: <40% "very disappointed"

**Important**: Kill decisions should be made on data, not emotion. The sunk cost fallacy is the biggest enemy.

### Keep (Fix) Criteria

The product shows some promise but isn't ready to scale:
- Retention plateau exists but is low (<15%)
- CC is flat — not declining, but not growing
- Some user segment retains well but overall numbers are weak

**Fix priority** (always this order):
1. Retention — raise the plateau
2. Activation — get more users to Aha Moment
3. Acquisition — only after 1 & 2 are healthy

### Scale Criteria

Scale only when:
- Retention plateau >15% and stable
- CC is rising consistently (30d trend)
- Activation rate >30%
- Organic inflow is growing
- Unit economics are healthy (LTV:CAC > 3:1 or trending toward it)

**Scaling before PMF = burning money.** Every dollar spent acquiring users who won't retain is wasted.

---

## Sean Ellis Survey (PMF Test)

The Sean Ellis survey is a qualitative PMF signal that complements the quantitative Kill/Keep/Scale metrics above. It asks one question: **"How would you feel if you could no longer use [product]?"**

### Setting Up in PostHog

Use PostHog's survey feature to create and distribute the survey:

**Survey configuration:**
- **Type**: Popover (in-app) or Link (email)
- **Question**: "How would you feel if you could no longer use [product name]?"
- **Answer type**: Single choice
- **Options**:
  1. Very disappointed
  2. Somewhat disappointed
  3. Not disappointed

**Targeting** — survey users who have enough experience to give a meaningful answer:
- Completed at least 2 core sessions (not first-time visitors who haven't formed an opinion)
- Signed up at least 7 days ago (enough time to experience the product)
- Haven't already responded to this survey (use PostHog's response limits)

**Timing:**
- Show after completing a core action (not during onboarding — too early)
- Limit to once per user
- Run continuously or in quarterly waves

### Interpreting Results

| "Very disappointed" % | Assessment | Action |
|----------------------|------------|--------|
| < 25% | No PMF signal | Product doesn't solve a real problem. Reconsider value prop. |
| 25-40% | Approaching PMF | Some users love it. Segment and understand who they are. |
| > 40% | PMF signal | Product solves a real problem. Focus on getting more users to this state. |

The 40% threshold comes from Sean Ellis's observation across hundreds of startups: products that cross 40% "very disappointed" almost always find a way to scale.

### Making the Survey Actionable

The raw percentage matters less than understanding **who** is very disappointed and **why**:

1. **Segment by "very disappointed"**: What do these users have in common? (company size, use case, acquisition channel, features used) — this reveals your ideal customer profile.
2. **Follow-up question** (optional): Add "What would you use as an alternative?" and "What is the main benefit you receive?" to understand competitive positioning and core value.
3. **Cross-reference with Aha Moment**: Do "very disappointed" users overwhelmingly complete the Aha Moment action? If yes, the Aha Moment is validated. If not, the Aha Moment hypothesis may be wrong.
4. **Track over time**: Run the survey quarterly. A rising "very disappointed" percentage after product changes confirms you're moving in the right direction.

### PostHog MCP Implementation

| Step | MCP Tool | How |
|------|----------|-----|
| Create survey | `survey-create` | Set question, options, targeting rules |
| Check responses | `survey-get` / `survey-stats` | Read response counts and distribution |
| Analyze segments | `query-run` (HogQL) | Join survey responses with user properties to find patterns |
| Track over time | `surveys-global-stats` | Compare response distributions across survey runs |

---

## Advanced CC Concepts

### CC Components Breakdown

```
Total Organic Inflow = New Organic + Resurrected + Referral

CC = (New Organic + Resurrected + Referral) / Churn Rate
```

Each component has its own levers:
- **New Organic**: SEO, content marketing, word-of-mouth, brand
- **Resurrected**: Product improvements that bring back churned users, re-engagement emails
- **Referral**: Viral loops, referral programs (Viral K × existing users)
- **Churn Rate**: Product quality, retention features, onboarding, value delivery

### Viral K and CC

If your product has a referral loop:

```
Viral K = Invitations per user × Conversion rate of invitations

If K < 1: CC = Organic Inflow / (Churn Rate - (K × Churn Rate))
If K = 1: CC → ∞ (theoretically, growth is self-sustaining)
If K > 1: Exponential growth (extremely rare, usually temporary)
```

Most products have K between 0.1 and 0.5. Even small K values meaningfully increase CC.

### Segment-Level CC

Different user segments may have very different CC values. Calculate CC per segment to find where the product works best:

```
Segment A (SMB): CC = 3,000 (flat)
Segment B (Mid-market): CC = 8,000 (rising)
Segment C (Enterprise): CC = 500 (rising fast)
```

This reveals which segment to double down on.

---

## Dashboard Design for CC Monitoring

### Primary Dashboard: CC Monitor

| Metric | Display | Frequency |
|--------|---------|-----------|
| CC (7d trailing) | Line chart with trend | Daily |
| CC (30d trailing) | Line chart with trend | Daily |
| Daily organic inflow breakdown | Stacked bar (new/resurrected/referral) | Daily |
| Daily churn rate | Line chart | Daily |
| Annotations | Product changes, experiments | As they happen |

### Supporting Dashboards

- **Retention**: Cohort tables, plateau detection, segment comparison
- **Activation**: Funnel to Aha Moment, time-to-activation, segment comparison
- **Growth Engine**: Inflow by type, Viral K, referral loop metrics
- **Revenue**: MRR, conversion rate, expansion/contraction

---

## Weekly Report Template

```markdown
# Week [YYYY-WW] — [Product Name]

## CC Status
- CC (7d trailing): ___
- CC (30d trailing): ___
- Trend: rising / flat / declining
- Change from last week: +/- ___

## Retention
- D7 retention (latest cohort): ___%
- Retention plateau: exists / not yet
- Plateau height: ___%
- Plateau trend: improving / stable / declining

## Activation
- Activation rate (signup → Aha Moment): ___%
- Time to Aha Moment (median): ___ days
- Change from last week: +/- ___

## Funnel
| Stage | Rate | Δ Week | Note |
|-------|------|--------|------|
| Visit → Signup | | | |
| Signup → Aha Moment | | | |
| Aha → D7 Return | | | |
| D7 → Paid | | | |

## Top Priority
[The ONE thing that would most improve CC right now]

## Kill/Keep/Scale Assessment
[Current assessment with key supporting data]
```

---

## CC and Revenue Metrics

CC measures product health (user retention). It doesn't measure revenue health. When CC looks good but revenue doesn't (or vice versa), these diagnostics help:

| Situation | Diagnosis | Fix |
|-----------|-----------|-----|
| CC rising + revenue flat | Users stay but don't pay enough | Pricing/packaging problem. See pricing. |
| CC flat + revenue rising | Existing users expand, but no new organic growth | Good short-term, fragile long-term. Improve product or top-of-funnel. |
| CC rising + revenue rising | Healthy | Keep going. |
| Both declining | Urgent | Fix retention first (see Kill/Keep/Scale above). |

For products without paid acquisition, track your **organic ratio** (organic signups / total signups). Target > 70%. If it's high and CC is rising, your business is fundamentally healthy.

---

## Common Mistakes

### Counting Paid Traffic in CC
CC must exclude paid channels. If you include paid users in "inflow," you're measuring something that disappears when you stop paying.

### Measuring CC Too Early
CC needs at least 4-8 weeks of data after launch spike subsides. Launch traffic is not organic inflow.

### Ignoring Resurrection
Resurrected users (previously churned, now returned) are organic inflow. They indicate product improvements are reaching former users. Track this separately — a rising resurrection rate is a very positive signal.

### Optimizing Acquisition Before Retention
Pouring users into a leaky bucket doesn't raise CC. It temporarily inflates MAU. Fix the bucket first.

### Using CC for Enterprise Products
CC works best for self-serve and product-led products with meaningful user volumes. For enterprise (10-50 customers), use NRR and logo retention instead. CC requires statistical volume to be meaningful.
