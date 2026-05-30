# Experiment Design

**Layer:** experiment **design** (hypothesis, sample size, variant build, ramp, traffic allocation). For **analysis** (significance testing, novelty/segment teardown, revenue impact, ratio-metric delta method, sequential and Bayesian inference), see `product-analytics/references/ab-test-analysis.md`.

Plan, design, and implement A/B tests with statistical rigor.

---

## Core Principles

1. **Start with a Hypothesis** — Specific prediction, based on reasoning or data
2. **Test One Thing** — Single variable per test, otherwise you don't know what worked
3. **Pre-commit Methodology** — Frequentist (fixed-horizon: pre-determine sample size, don't peek) OR Bayesian/sequential (define stopping rule via posterior or SPRT-style boundary). **Mixing modes mid-experiment invalidates inference.**
4. **Measure What Matters** — Primary metric tied to business value
5. **CUPED for variance reduction** when you have pre-experiment user data — cuts required sample size by (1 − ρ²), where ρ is the correlation between a pre-experiment covariate and the metric. Typical gains are ~10–50% depending on covariate quality; *halving* needs a strong covariate (ρ ≈ 0.7). Apply on top of a standard sample-size calc — don't pre-discount traffic assuming 50%.
6. **A/A tests on the platform itself** before relying on any new experimentation tool

**Tool landscape (2026):** Statsig (platform/brand now under Amplitude; team at OpenAI), GrowthBook, Eppo by Datadog, LaunchDarkly, Harness FME (formerly Split), PostHog Experiments. Pick one — don't run experiments across tools without alignment on randomization unit and assignment hash.

---

## Hypothesis Framework

```
Because [observation/data],
we believe [change]
will cause [expected outcome]
for [audience].
We'll know this is true when [metrics].
```

**Weak**: "Changing the button color might increase clicks."

**Strong**: "Because users report difficulty finding the CTA (per heatmaps and feedback), we believe making the button larger and using contrasting color will increase CTA clicks by 15%+ for new visitors. We'll measure click-through rate from page view to signup start."

---

## Test Types

| Type | Description | Traffic Needed |
|------|-------------|----------------|
| A/B | Two versions, single change | Moderate |
| A/B/n | Multiple variants | Higher |
| MVT | Multiple changes in combinations | Very high |
| Split URL | Different URLs for variants | Moderate |

---

## Sample Size Quick Reference

Choose your MDE (the lift you power for) from the business case — the smallest lift that justifies building and maintaining the change — not from whichever column fits your traffic. Statistical significance ≠ practical significance: a result can be significant yet too small to ship.

Per variant, at 80% power, two-sided α = 0.05, rounded up (matches the Evan Miller calculator below). "Lift" is relative.

| Baseline Rate | 10% Lift | 20% Lift | 50% Lift |
|---------------|----------|----------|----------|
| 1% | 164k/variant | 43k/variant | 8k/variant |
| 3% | 54k/variant | 14k/variant | 2.6k/variant |
| 5% | 32k/variant | 8.2k/variant | 1.5k/variant |
| 10% | 15k/variant | 3.9k/variant | 700/variant |

**Calculators:** [Evan Miller's](https://www.evanmiller.org/ab-testing/sample-size.html), [Optimizely's](https://www.optimizely.com/sample-size-calculator/)

### Pick Your Validation Method by Traffic

Most pages can't reach these numbers. If a variant can't hit the required sample within ~4 weeks, do NOT run a fixed-horizon A/B test — you'll either peek (false positives) or stall. Instead:

- **Low traffic** — diagnose qualitatively (session replays, heatmaps, user tests), ship best-practice fixes, and monitor against the guardrail metrics below. Use painted-door / fake-door tests to gauge demand for a new value prop before building it.
- **Moderate traffic** — a Bayesian or sequential design with a pre-committed stopping rule reaches a decision faster than fixed-horizon (see Principle 3); ramping (below) limits the downside.
- **High traffic** — fixed-horizon A/B as specified above.

A flat or negative result is itself a valid, actionable outcome — not a failed test.

---

## Metrics Selection

### Primary Metric
Single metric that matters most, directly tied to hypothesis.

### Secondary Metrics
Support primary metric interpretation, explain why/how change worked.

### Guardrail Metrics
Things that shouldn't get worse. Stop test if significantly negative.

### Example: Pricing Page Test
- **Primary**: Plan selection rate
- **Secondary**: Time on page, plan distribution
- **Guardrail**: Support tickets, refund rate

---

## Designing Variants

| Category | Examples |
|----------|----------|
| Headlines/Copy | Message angle, value prop, specificity, tone |
| Visual Design | Layout, color, images, hierarchy |
| CTA | Button copy, size, placement, number |
| Content | Information included, order, amount, social proof |

**Best practices:** Single meaningful change. Bold enough to make a difference. True to the hypothesis.

---

## Traffic Allocation

| Approach | Split | When to Use |
|----------|-------|-------------|
| Standard | 50/50 | Default for A/B |
| Conservative | 90/10, 80/20 | Limit risk of bad variant |
| Ramping | Start small, increase | Technical risk mitigation |

---

## Implementation

### Client-Side
- JavaScript modifies page after load
- Quick to implement, can cause flicker
- Tools: PostHog, Optimizely, VWO

### Server-Side
- Variant determined before render
- No flicker, requires dev work
- Tools: PostHog, LaunchDarkly, Harness FME (formerly Split)

---

## Running the Test

### Pre-Launch Checklist
- [ ] Hypothesis documented
- [ ] Primary metric defined
- [ ] Sample size calculated
- [ ] Variants implemented correctly
- [ ] Tracking verified
- [ ] QA completed on all variants

### During the Test

**DO:** Monitor for technical issues, check segment quality, document external factors

**DON'T:** Peek at results and stop early, make changes to variants, add traffic from new sources

### The Peeking Problem
Looking at results before reaching sample size and stopping early leads to false positives. Pre-commit to sample size.

---

## Analyzing Results

Before trusting the raw funnel numbers, remember they undercount: consent opt-outs, Safari/Firefox cookie limits, ad-blockers, and GA4 Consent Mode modeling all bias what you measure. For high-stakes decisions, reconcile against server-side or order-level data.

### Statistical Significance
- 95% confidence = p-value < 0.05
- Not a guarantee — just a threshold

### Analysis Checklist
1. Reach sample size?
2. Statistically significant?
3. Effect size meaningful?
4. Secondary metrics consistent?
5. Guardrail concerns?
6. Segment differences?

### Interpreting Results

| Result | Conclusion |
|--------|------------|
| Significant winner | Implement variant |
| Significant loser | Keep control, learn why |
| No significant difference (at the pre-committed sample size) | True effect is likely below your MDE — conclude "no detectable difference" and keep control, or design a NEW bolder test. Don't keep adding traffic to the same test (that reintroduces the peeking problem). If it never reached its planned N, run it to completion first. |
| Mixed signals | Dig deeper, segment |

---

## Common Mistakes

### Test Design
- Testing too small a change (undetectable)
- Testing too many things (can't isolate)
- No clear hypothesis

### Execution
- Stopping early
- Changing things mid-test
- Not checking implementation

### Analysis
- Ignoring confidence intervals
- Cherry-picking segments
- Over-interpreting inconclusive results
