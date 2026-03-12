# Experiment Design

Plan, design, and implement A/B tests with statistical rigor.

---

## Core Principles

1. **Start with a Hypothesis** — Specific prediction, based on reasoning or data
2. **Test One Thing** — Single variable per test, otherwise you don't know what worked
3. **Statistical Rigor** — Pre-determine sample size, don't peek and stop early
4. **Measure What Matters** — Primary metric tied to business value

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

| Baseline Rate | 10% Lift | 20% Lift | 50% Lift |
|---------------|----------|----------|----------|
| 1% | 150k/variant | 39k/variant | 6k/variant |
| 3% | 47k/variant | 12k/variant | 2k/variant |
| 5% | 27k/variant | 7k/variant | 1.2k/variant |
| 10% | 12k/variant | 3k/variant | 550/variant |

**Calculators:** [Evan Miller's](https://www.evanmiller.org/ab-testing/sample-size.html), [Optimizely's](https://www.optimizely.com/sample-size-calculator/)

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
- Tools: PostHog, LaunchDarkly, Split

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
| No significant difference | Need more traffic or bolder test |
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
