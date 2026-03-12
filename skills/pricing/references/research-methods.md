# Pricing Research Methods

Methods for determining optimal pricing through customer research. Companies using multiple research methods achieve **30% higher revenue growth** than single-method approaches.

**Recommended stack**: Van Westendorp for range-finding → Gabor-Granger for point optimization → Conjoint for packaging decisions.

---

## Table of Contents

1. [Van Westendorp Price Sensitivity Meter](#van-westendorp-price-sensitivity-meter)
2. [Gabor-Granger Technique](#gabor-granger-technique)
3. [Conjoint Analysis](#conjoint-analysis)
4. [MaxDiff Analysis](#maxdiff-analysis)
5. [Quick Research Methods](#quick-research-methods)
6. [Value-Based Pricing Research](#value-based-pricing-research)
7. [Running Price Tests](#running-price-tests)
8. [Research Method Selection](#research-method-selection)

---

## Van Westendorp Price Sensitivity Meter

**Purpose**: Find the acceptable price range for a product or feature.
**Best for**: New products, early-stage pricing, establishing boundaries before optimization.
**Cost/effort**: Low — a simple 4-question survey.

### The Four Questions

Ask in random order to prevent anchoring:

1. **Too cheap** — "At what price would you question the quality of this product?"
2. **A bargain** — "At what price would you consider this a great deal?"
3. **Getting expensive** — "At what price does this start to feel costly, but you'd still consider buying?"
4. **Too expensive** — "At what price would you absolutely not buy this?"

### Analysis

Plot cumulative distributions. The intersections reveal pricing boundaries:

| Intersection | Meaning | Use |
|-------------|---------|-----|
| **Optimal Price Point (OPP)** | "Too cheap" crosses "too expensive" | Theoretical sweet spot |
| **Indifference Price Point (IDP)** | "Bargain" crosses "expensive" | Market's neutral price |
| **Point of Marginal Cheapness (PMC)** | "Too cheap" crosses "expensive" | Floor of acceptable range |
| **Point of Marginal Expensiveness (PME)** | "Too expensive" crosses "bargain" | Ceiling of acceptable range |
| **Acceptable Range** | Between PMC and PME | Your pricing playground |

### Implementation Requirements

- **Minimum 100 respondents per segment** for statistical significance
- Segment by persona, company size, and use case — aggregate data masks real patterns
- Provide sufficient product context (screenshots, feature list, demo) before asking
- Ask about a specific product configuration, not the abstract product
- Run separately for each major tier or product variant

### Limitations

Van Westendorp tells you what people *say* they'd pay, not what they'll actually pay. Stated willingness-to-pay typically overshoots by 15-20%. Use the range as a starting boundary, then refine with Gabor-Granger or real-world testing.

---

## Gabor-Granger Technique

**Purpose**: Find the specific price point that maximizes revenue.
**Best for**: Optimizing price within a known range, measuring price elasticity.
**Cost/effort**: Low-medium — sequential price testing survey.

### How It Works

1. Show the customer the product at a specific price
2. Ask: "Would you buy this at $X?"
3. If yes → show a higher price. If no → show a lower price
4. Repeat 4-5 times to map the individual's demand curve
5. Aggregate across respondents to find the revenue-maximizing price

### Implementation

**Sequential approach** (recommended):
- Start at the midpoint of your Van Westendorp acceptable range
- Move up or down in fixed increments (e.g., $10 steps for a $50-$150 range)
- Each respondent sees 4-5 prices

**Fixed set approach** (simpler):
- Show 5-7 predetermined prices
- Ask purchase intent at each (5-point scale: definitely would / probably would / might / probably not / definitely not)
- Plot the demand curve

### Key Output

A **demand curve** showing conversion probability at each price point. Multiply price x conversion probability to find the revenue-maximizing point:

```
Revenue at price P = P × Conversion%(P) × Market Size
```

The optimal price often isn't where conversion is highest — it's where price × conversion is maximized.

### Strengths and Limitations

**Strengths**: Directly identifies revenue-maximizing price. Reveals price elasticity (how sensitive demand is to price changes). Easy to implement.

**Limitations**: Evaluates product in isolation (no competitive context). Stated intent doesn't perfectly predict actual behavior — real-world conversion is typically 30-50% of stated "definitely would buy."

---

## Conjoint Analysis

**Purpose**: Understand feature-price tradeoffs and optimal packaging.
**Best for**: Package design, multi-attribute decisions, competitive positioning.
**Cost/effort**: High — requires survey design expertise and statistical analysis.

### How It Works

1. Define 3-5 attributes (features, support level, price, brand, etc.)
2. Each attribute has 2-4 levels (e.g., price: $29, $49, $99)
3. Generate product profiles — combinations of attribute levels
4. Respondents rank, rate, or choose between profiles
5. Statistical analysis (usually hierarchical Bayes) reveals the utility weight of each attribute level

### What You Learn

- **Part-worth utilities**: How much each feature level contributes to perceived value
- **Willingness-to-pay per feature**: How much more customers will pay for Feature X vs. Feature Y
- **Optimal bundles**: Which combination of features at which price maximizes uptake
- **Price sensitivity by segment**: Which customer segments are most/least price-sensitive

### When to Use Conjoint

- Before a major pricing restructure
- When designing tier packaging (which features in which tier?)
- When you need to understand competitive dynamics (include competitor profiles)
- Complex products with many features where intuition fails
- Budget available for proper survey design and analysis ($5K-$50K depending on scope)

### Implementation Notes

- Minimum 200-300 respondents for reliable results
- Use adaptive conjoint (ACBC) for complex designs
- Limit to 5-6 attributes — more than that overwhelms respondents
- Include a "none" option to capture walk-away scenarios
- Tools: Sawtooth Software, Conjointly, SurveyAnalytics

---

## MaxDiff Analysis

**Purpose**: Rank feature importance for tier packaging.
**Best for**: Deciding which features go in which tier.
**Cost/effort**: Low-medium — simpler than conjoint, more rigorous than surveys.

### How It Works

1. List 8-15 features
2. Show sets of 4-5 features at a time
3. Ask: "Which is MOST important? Which is LEAST important?"
4. Repeat with different combinations (8-12 sets)
5. Calculate relative importance scores (ratio-scaled)

### Application to Tier Design

| Importance Score | Tier Placement |
|-----------------|----------------|
| Top 20% | Premium tier differentiators |
| Middle 60% | Core features (all tiers or mid+) |
| Bottom 20% | Include everywhere or cut entirely |

### Why MaxDiff Beats Simple Ranking

Simple "rate importance 1-5" surveys suffer from everyone rating everything as 4-5. MaxDiff forces tradeoffs — respondents must pick a most and least important, revealing true priorities. The forced-choice format produces scores that are 3-5x more discriminating.

---

## Quick Research Methods

For when you need directional insights fast and can't run full surveys.

### Customer Interviews (10-15 interviews)

High-signal questions:
- "Walk me through how you decided to buy [current solution]. What was the budget conversation like?"
- "If this product didn't exist, what would you do instead? How much does that cost you?"
- "What would make this worth 2x the price?"
- "At what price would you not even consider this?"
- "How do you currently justify this expense internally?"

The second question (alternative cost) is the most valuable — it reveals the true competitive frame and reference price.

### Win/Loss Analysis

Track pricing as a factor in every closed deal:

| Signal | Implication |
|--------|------------|
| "Too expensive" < 15% of losses | Prices may be too low |
| "Too expensive" > 30% of losses | Test lower prices or improve value communication |
| Price rarely mentioned in wins | Customers buy on value, not price — room to increase |
| Frequent negotiation/discounting | Published prices may be set too high, or sales team needs training |

### Competitor Pricing Audit

Document systematically:
- All tiers, prices, and included features
- Value metric (what they charge per)
- Price-per-feature ratios
- Positioning (budget, mid-market, premium)
- Recent pricing changes (track quarterly)

**Don't copy competitor pricing.** Use it to understand market expectations and find positioning gaps. If all competitors charge per seat and you charge per usage, that's either a competitive advantage or a friction point — understand which.

---

## Value-Based Pricing Research

### The 10x Rule

Your product should deliver at least 10x the value of its price. If you charge $100/month, customers should be getting $1,000+ in measurable value. This creates an "obvious yes" buying decision.

### Measuring Value (The Value Stack)

Quantify value across four dimensions:

| Value Type | How to Measure | Example |
|-----------|---------------|---------|
| **Time saved** | Hours saved × hourly rate | 10 hrs/week × $50/hr = $2,000/mo |
| **Revenue generated** | Additional revenue attributable to product | +15% conversion = $30K/mo |
| **Cost avoided** | Expenses eliminated | Replaces $500/mo tool + $2K/mo contractor |
| **Risk reduced** | Cost of problems prevented × probability | $50K breach × 10% probability = $5K/mo |

### Willingness-to-Pay Ladder

Use in customer interviews to triangulate:

1. "What's the maximum you'd pay for this?" → Price ceiling
2. "What price feels fair for the value you get?" → Target price
3. "At what price is this an instant yes?" → Price floor

The target price is usually 30-50% of the stated maximum. The gap between floor and ceiling tells you how much room you have for tier differentiation.

### Sequoia's ROI Method

Calculate the ROI your product delivers, then charge 10-20% of that value. This ensures the customer captures 80-90% of the value (a clear win for them) while you capture a meaningful share.

```
Your Price = Customer's Annual Value Gained × 10-20%
```

Production cost should not guide pricing, but do a sanity check on gross margin (target 70%+ for SaaS).

---

## Running Price Tests

### Safe Tests (Always Run)

These test presentation, not price, and don't risk customer trust:

| Test | What You Learn |
|------|---------------|
| Annual/monthly toggle default | Which default converts better |
| Tier highlighting | Does "Most Popular" badge shift tier selection |
| Feature comparison layout | Which format makes differentiation clearest |
| CTA copy | "Start free trial" vs "Get started" vs "Try free" |
| Social proof placement | Logos, testimonials, case study links |
| Price anchoring order | Premium-first vs entry-first |

### Price Point Tests (Handle with Care)

Testing actual prices requires guardrails:

1. **New customer segments only** — Never show different prices to similar existing customers
2. **Geographic testing** — Different prices in different markets (natural boundary)
3. **Cohort testing** — All new signups in week A see price X, week B see price Y
4. **Grandfathering** — Always honor existing customer prices
5. **Time-box** — Run for 2-4 weeks minimum, set end date before starting
6. **Measure beyond conversion** — Track retention, expansion, and LTV, not just signup rate

### Statistical Significance

Pricing page A/B tests need larger sample sizes than typical conversion tests because the effect sizes are often smaller:

- Minimum 1,000 visitors per variant for layout tests
- Minimum 200 conversions per variant for tier selection tests
- Run for at least 2 full business cycles (typically 2-4 weeks)

---

## Research Method Selection

| Situation | Recommended Method | Why |
|-----------|-------------------|-----|
| New product, no pricing data | Van Westendorp + interviews | Establishes range quickly and cheaply |
| Optimizing existing prices | Gabor-Granger | Directly finds revenue-maximizing point |
| Redesigning tier packaging | Conjoint + MaxDiff | Reveals feature-price tradeoffs |
| Quick directional check | 10-15 customer interviews | Fast, qualitative, reveals mental models |
| Validating a price increase | Win/loss analysis + Gabor-Granger | Data on current sensitivity + optimized new point |
| Entering new market | Van Westendorp (by segment) + competitor audit | Range-finding in unfamiliar territory |
