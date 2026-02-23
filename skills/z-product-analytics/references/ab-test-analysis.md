# A/B Test Results Analysis

## When to Use This Reference

Use when analyzing experiment results from PostHog (or any A/B testing tool). This covers the analysis methodology — experiment design and setup is handled by z-growth-optimizer / z-cro.

---

## Analysis Framework

Follow this sequence for every experiment. Skipping steps leads to bad shipping decisions.

### 1. Check Prerequisites

Before looking at results:

- **Minimum sample size reached?** Use power analysis to determine required sample. Rule of thumb: for a 10% MDE (minimum detectable effect), you need ~1,600 users per variant. For 5% MDE, ~6,400 per variant.
- **Minimum runtime reached?** At least 1 full business cycle (7 days minimum, 14 days recommended). Weekend behavior often differs from weekday.
- **No data quality issues?** Check for logging errors, bot traffic, assignment imbalance between variants.

If any of these fail, stop. Do not analyze partial results — that's "peeking" and it inflates false positive rates.

### 2. Primary Metric Analysis

Answer: **Did the variant beat control on the primary metric?**

| Result | Interpretation | Action |
|--------|---------------|--------|
| Significant improvement (p < 0.05) | Variant is better | Proceed to secondary analysis |
| Significant decline (p < 0.05) | Variant is worse | Kill the variant |
| Not significant | Inconclusive | Check if more time/sample would help, or accept null result |

**Report both**:
- **Statistical significance**: p-value or confidence interval
- **Practical significance**: Is the effect size meaningful? A 0.3% improvement might be statistically significant with enough users but practically meaningless.

### 3. Secondary Metrics

Check for unexpected side effects:

- Did the variant improve conversion but decrease retention?
- Did it improve signup but decrease activation?
- Did it improve one metric while degrading revenue?

Secondary metric movements don't need to be statistically significant to be concerning — if you see a trend, note it.

### 4. Segment Analysis

Does the effect differ across user segments?

Priority segments to check:
- **New vs. returning users** — New users respond differently to changes
- **Acquisition channel** — Organic vs. paid users may react differently
- **Device type** — Desktop vs. mobile
- **Plan tier** — Free vs. paid users
- **Geography** — If relevant to the product

A segment-level win can hide in an overall null result. An overall win might be driven by only one segment.

### 5. Novelty Check

Compare **week 1 lift vs. week 2+ lift**.

- If week 1 lift > week 2+: Novelty effect. The improvement will fade. Be cautious about shipping.
- If week 1 lift ≈ week 2+: Sustained effect. Safe to ship.
- If week 1 lift < week 2+: Compound effect. Even better — the improvement grows with time.

### 6. Revenue Impact Estimation

Annualize the observed effect:

```
Daily revenue impact = (Variant conversion rate - Control conversion rate) × Daily traffic × ARPU
Annual revenue impact = Daily impact × 365
```

Include confidence intervals. The point estimate is rarely the actual outcome.

### 7. Final Recommendation

One of three:

| Decision | When |
|----------|------|
| **Ship** | Significant improvement on primary metric, no negative secondary effects, effect is sustained past week 1 |
| **Iterate** | Promising direction but effect is small, or secondary metrics are concerning. Design a follow-up experiment. |
| **Kill** | No improvement or negative impact. Document learnings and move on. |

---

## Statistical Rigor

### Significance Threshold

- Standard: **p < 0.05** (95% confidence)
- For high-stakes changes (pricing, core flow): **p < 0.01** (99% confidence)
- For quick iteration tests: **p < 0.10** (90% confidence) is acceptable if you're running many small experiments

### Multiple Comparisons

If testing multiple metrics or segments, apply **Bonferroni correction**:

```
Adjusted threshold = 0.05 / number of comparisons
```

Testing 5 metrics? Each needs p < 0.01 to claim significance at the 0.05 family-wise level.

### Confidence Intervals Over P-Values

Report confidence intervals, not just p-values. A CI of [+2%, +15%] tells you more than "p = 0.03". It shows the range of plausible effect sizes.

### Sequential Testing Caution

If using PostHog's experiment tool with sequential testing (which allows checking results before the experiment ends):
- Sequential testing controls for peeking, so it's safe to check early
- However, stopping early reduces power — you might miss real effects
- If the experiment doesn't reach significance early, let it run to full sample size

---

## Common Pitfalls

### Peeking Without Sequential Testing
Checking results daily and stopping when significant inflates false positives from 5% to 20-30%. Either use sequential testing or commit to a fixed sample size upfront.

### Stopping at First Significance
Statistical significance can fluctuate. A result that's significant at day 5 might not be at day 10. Always run for the pre-committed duration.

### Ignoring Practical Significance
A 0.1% conversion improvement with p = 0.02 on a page with 100 visitors/day = 0.1 additional conversions/day. Probably not worth the complexity of maintaining the variant.

### Not Accounting for Seasonality
An experiment running only on weekdays or only during a holiday period may not generalize. Ensure the test period covers at least one full business cycle.

### Testing Too Many Things Simultaneously
Each concurrent experiment risks interaction effects. If experiments A and B both affect the signup flow, their combined effect may differ from either alone. Limit concurrent experiments on the same user flow.

### SRM (Sample Ratio Mismatch)
If variant assignment is 50/50 but you see 48/52 or worse, there's a bug. Check:
- Is the assignment happening before any filtering?
- Are bots being assigned unevenly?
- Is there a redirect that drops users from one variant?

SRM invalidates the entire experiment. Fix the bug before re-running.

---

## PostHog Experiment Analysis

### Reading PostHog Results

PostHog experiments show:
- **Win probability**: Bayesian probability that a variant beats control (>95% = significant)
- **Credible interval**: Range of plausible effect sizes
- **Trend over time**: How the metric changed during the experiment

### Using PostHog MCP for Analysis

| Analysis | MCP Tool | How |
|----------|----------|-----|
| Get experiment results | `experiment-get` + `experiment-results-get` | Retrieve results by experiment ID |
| Custom metric analysis | `query-run` with HogQL | Filter events by feature flag variant |
| Segment analysis | `query-run` with breakdown | Break down experiment events by user properties |
| Retention impact | `query-run` with retention query | Compare D7/D30 retention between variants |

### HogQL for Custom Experiment Analysis

```sql
-- Compare conversion rate between variants
SELECT
  properties.$feature_flag_response AS variant,
  COUNT(DISTINCT person_id) AS users,
  COUNT(DISTINCT CASE WHEN event = 'purchase_completed' THEN person_id END) AS conversions,
  ROUND(
    COUNT(DISTINCT CASE WHEN event = 'purchase_completed' THEN person_id END) * 100.0 /
    COUNT(DISTINCT person_id), 2
  ) AS conversion_rate
FROM events
WHERE properties.$feature_flag_response IS NOT NULL
  AND properties.$feature_flag = 'experiment-key'
  AND timestamp >= '2025-01-01'
GROUP BY variant
```

---

## Experiment Report Template

Store at `biz/analytics/reports/{experiment-name}-results.md`:

```markdown
# Experiment: [Name]

## Summary
- **Hypothesis**: [If we do X, then Y will improve by Z%]
- **Primary metric**: [Metric name]
- **Duration**: [Start] — [End] ([N] days)
- **Sample size**: Control: [N], Variant: [N]
- **Result**: Ship / Iterate / Kill

## Results

| Metric | Control | Variant | Δ | Significance |
|--------|---------|---------|---|--------------|
| Primary: [name] | X% | Y% | +Z% | p = 0.XX / CI [a%, b%] |
| Secondary: [name] | | | | |

## Segment Analysis
[Notable segment differences]

## Novelty Check
- Week 1 lift: +X%
- Week 2+ lift: +Y%
- Assessment: Sustained / Novelty effect

## Revenue Impact
- Estimated annual impact: $X (CI: $Y — $Z)

## Learnings
[What did we learn, regardless of result?]

## Next Steps
[Ship as-is / Design follow-up / Move to next experiment]
```
