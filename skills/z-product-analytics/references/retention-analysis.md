# Retention & Cohort Analysis

## Why Retention Is the Only Metric That Matters

Acquisition can be bought. Revenue can be inflated. But retention is the unmanipulable signal of whether your product delivers value. A product with 80% D30 retention and 100 users will outperform a product with 10% D30 retention and 10,000 users — every time.

---

## Cohort Types

### Time-Based Cohorts (Acquisition Cohorts)
Group users by signup date (week or month). The standard for tracking retention over time.

```
             Month 0  Month 1  Month 2  Month 3  Month 4
Jan 2025     100%     45%      32%      28%      27%
Feb 2025     100%     48%      35%      30%      29%
Mar 2025     100%     52%      40%      35%      —
```

**How to read:**
- Each row = one cohort (all users who signed up in that month)
- Each column = months since signup
- **Read diagonally** (top-left to bottom-right) = same calendar month across cohorts
- **Read columns** = same lifecycle stage across cohorts (are newer cohorts retaining better?)
- **Read rows** = one cohort's lifecycle

### Behavioral Cohorts
Group users by actions taken (or not taken). Critical for Aha Moment validation.

Examples:
- Users who completed onboarding vs. skipped
- Users who invited a teammate vs. solo users
- Users who used feature X in first week vs. didn't

### Segment-Based Cohorts
Group by user properties. Reveals which segments have fundamentally different retention.

Examples:
- By acquisition channel (organic vs. paid vs. referral)
- By company size (1-10 vs. 11-50 vs. 50+ employees)
- By plan tier (free vs. paid)
- By geography or persona

---

## Retention Intervals

| Interval | Measures | When to Use |
|----------|----------|-------------|
| **D1** | First return after signup | Onboarding quality |
| **D7** | Weekly return | Early habit formation |
| **D14** | Second week | Habit stability |
| **D30** | Monthly return | Core retention |
| **D60** | Two-month | PMF signal |
| **D90** | Quarterly | Long-term viability |

**For SaaS specifically:**
- **Weekly products** (project management, communication): D7 is the key early signal
- **Monthly products** (analytics, invoicing): D30 is the first meaningful signal
- **Usage frequency < 1x/month**: Retention plateau is nearly impossible — reconsider the product

---

## PMF Assessment via Retention Curves

### The Plateau Test

Plot cohort retention curves. The shape tells you everything:

**Shape 1: Continuous decline (no plateau)**
```
100% ─╲
      ╲
       ╲
        ╲
         ╲─── → 0%
```
**Diagnosis**: No PMF. Stop all acquisition spending. Fix the product.

**Shape 2: Decline then flatten (plateau exists)**
```
100% ─╲
      ╲
       ╲___________  → plateau at X%
```
**Diagnosis**: PMF exists. Plateau height determines business ceiling.

**Shape 3: Smile curve (decline, flatten, then rise)**
```
100% ─╲
      ╲
       ╲_____╱─── → expanding
```
**Diagnosis**: Strong PMF with network effects or expanding use cases. Rare and very valuable.

### Plateau Height Benchmarks (2025 B2B SaaS)

| Plateau Height | Assessment | Action |
|---------------|------------|--------|
| < 5% | No PMF | Kill or pivot |
| 5-10% | Weak signal | Focus entirely on retention |
| 10-20% | Early PMF | Optimize activation, cautious acquisition |
| 20-40% | Solid PMF | Scale activation and acquisition |
| > 40% | Strong PMF | Scale aggressively |

**Consumer products** typically need higher plateaus (>20%) due to lower monetization per user.

### Revenue Retention Benchmarks (2025)

| Metric | Median | Top Quartile | Elite |
|--------|--------|--------------|-------|
| GRR (Gross Revenue Retention) | 90% | 95%+ | 97%+ |
| NRR (Net Revenue Retention) | 106% | 115%+ | 120%+ |

**Warning**: High NRR can mask poor GRR. NRR of 130% with GRR of 70% = losing 30% of customers but making it up with upsells. That's fragile.

By company scale:
- **$1M-$10M ARR**: Median NRR ~98%, GRR ~85%
- **$10M-$100M ARR**: Median NRR ~106%, GRR ~90%
- **$100M+ ARR**: Median NRR ~115%, GRR ~94%

---

## Building Cohort Tables

### Step 1: Define the cohort
- What groups users together? (signup date, plan start, first action)
- What's the time interval? (daily, weekly, monthly)
- **Don't mix annual and monthly subscriptions** — analyze separately

### Step 2: Define retention
- What counts as "retained"? (logged in, performed core action, paid)
- Be precise: "logged in" ≠ "got value"
- Best practice: define retention as performing the **core value action**, not just any activity

### Step 3: Build the table
```sql
-- Basic cohort retention query
WITH cohorts AS (
  SELECT
    user_id,
    DATE_TRUNC('month', signup_date) AS cohort_month,
    DATE_TRUNC('month', activity_date) AS activity_month
  FROM user_activity
),
cohort_sizes AS (
  SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_size
  FROM cohorts
  GROUP BY 1
),
retention AS (
  SELECT
    cohort_month,
    DATE_DIFF('month', cohort_month, activity_month) AS months_since,
    COUNT(DISTINCT user_id) AS active_users
  FROM cohorts
  GROUP BY 1, 2
)
SELECT
  r.cohort_month,
  r.months_since,
  r.active_users,
  ROUND(r.active_users * 100.0 / cs.cohort_size, 1) AS retention_pct
FROM retention r
JOIN cohort_sizes cs ON r.cohort_month = cs.cohort_month
ORDER BY 1, 2;
```

### Step 4: Read the table

**Diagonal reading** (left-aligned table): Sum values moving from Month 0 up and to the right = total active users in a given calendar month.

**Column comparison**: Are newer cohorts retaining better at the same lifecycle stage? If yes, product improvements are working.

**Row analysis**: Where does each cohort's biggest drop happen? That's your highest-leverage fix.

---

## Common Retention Patterns & Diagnoses

### Massive D1 Drop (>70% lost on Day 1)
**Problem**: Onboarding failure. Users don't understand what to do or can't get first value.
**Fix**: Simplify onboarding, reduce time-to-first-value.

### Steady Decline Through D30 (Never Flattens)
**Problem**: Product doesn't create a habit. No retention plateau = no PMF.
**Fix**: Find or strengthen the Aha Moment. Consult `aha-moment-discovery.md`.

### D7 Plateau Then D30 Drop
**Problem**: Initial novelty wears off. Product solves a one-time problem, not an ongoing need.
**Fix**: Create recurring value (regular reports, ongoing workflows, fresh content).

### Newer Cohorts Retaining Worse
**Problem**: Quality of acquisition is declining (bad channels, broad targeting) or recent product changes hurt.
**Fix**: Segment by acquisition channel. Check if product changes correlate.

### Newer Cohorts Retaining Better
**Signal**: Product improvements are working. Keep going.

---

## Segmented Analysis

**Always segment.** The average hides the insight.

Priority segments:
1. **By acquisition channel** — Organic users almost always retain better than paid. Quantify the gap.
2. **By Aha Moment completion** — Compare users who reached vs. didn't reach the Aha Moment. The gap should be dramatic (2-5x).
3. **By plan/tier** — Free vs. paid retention tells you about activation and value perception.
4. **By company size/persona** — Different segments may have fundamentally different retention profiles.
5. **By feature usage** — Which features correlate with retention? This is Aha Moment discovery.

---

## Tools & Implementation

| Tool | Strength |
|------|----------|
| **PostHog** | Retention tables with behavioral cohorts. Lifecycle view (new/returning/resurrecting/dormant). |
| **Amplitude** | Retention analysis with advanced segmentation. Stickiness charts. |
| **Mixpanel** | Retention reports with flexible cohort definitions. Signal reports for automated correlation. |
| **SQL/Warehouse** | Full control for custom analysis. Required for revenue retention cohorts. |
| **ChartMogul** | Revenue cohort analysis. GRR/NRR tracking by cohort. |

### PostHog Specifics
- **Retention insight**: Set start event (signup) and return event (core action). Choose period (day/week/month).
- **Lifecycle view**: Shows new, returning, resurrecting, dormant users per period. Rising "resurrecting" = win-back is working.
- **Stickiness**: Shows distribution of how many days/weeks users were active. Bimodal distribution = healthy (casual + power users).
- **Paths**: Show common user journeys. Compare paths of retained vs. churned users.

---

## LTV Estimation from Cohorts

If cohort retention stabilizes, estimate LTV:

```
Estimated Lifetime (months) = 1 / Monthly Churn Rate at Plateau

LTV = ARPU × Estimated Lifetime

LTV:CAC Ratio Target: ≥ 3:1
CAC Payback Period Target: ≤ 12 months
```

If the plateau hasn't formed yet, use the most recent cohort's decay rate as a conservative estimate. Do not extrapolate from early, unstable cohorts.
