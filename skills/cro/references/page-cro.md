# Page CRO

Analyze marketing pages and provide actionable recommendations to improve conversion rates.

## Table of Contents

1. [Initial Assessment](#initial-assessment)
2. [CRO Analysis Framework](#cro-analysis-framework)
3. [Output Format](#output-format)
4. [Benchmarks](#benchmarks)
5. [Before/After Example: SaaS Landing Page Hero](#beforeafter-example-saas-landing-page-hero)
6. [Page-Specific Frameworks](#page-specific-frameworks)
7. [Experiment Ideas](#experiment-ideas)

## Initial Assessment

Before providing recommendations, identify:

1. **Page Type**: Homepage, landing page, pricing, feature, blog, about, other
2. **Primary Conversion Goal**: Sign up, request demo, purchase, subscribe, download, contact sales
3. **Traffic Context**: Where are visitors coming from? (organic, paid, email, social)

---

## CRO Analysis Framework

Analyze the page across these dimensions, in order of impact:

### 1. Value Proposition Clarity (Highest Impact)

**Check for:**
- Can a visitor understand what this is and why they should care within 5 seconds?
- Is the primary benefit clear, specific, and differentiated?
- Is it written in the customer's language (not company jargon)?

**Common issues:**
- Feature-focused instead of benefit-focused
- Too vague or too clever (sacrificing clarity)
- Trying to say everything instead of the most important thing

### 2. Headline Effectiveness

**Evaluate:**
- Does it communicate the core value proposition?
- Is it specific enough to be meaningful?
- Does it match the traffic source's messaging?

**Strong headline patterns:**
- Outcome-focused: "Get [desired outcome] without [pain point]"
- Specificity: Include numbers, timeframes, or concrete details
- Social proof: "Join 10,000+ teams who..."

### 3. CTA Placement, Copy, and Hierarchy

**Primary CTA assessment:**
- Is there one clear primary action?
- Is it visible without scrolling?
- Does the button copy communicate value, not just action?
  - Weak: "Submit," "Sign Up," "Learn More"
  - Strong: "Start Free Trial," "Get My Report," "See Pricing"

**CTA hierarchy:**
- Is there a logical primary vs. secondary CTA structure?
- Are CTAs repeated at key decision points?

### 4. Visual Hierarchy and Scannability

**Check:**
- Can someone scanning get the main message?
- Are the most important elements visually prominent?
- Is there enough white space?
- Do images support or distract from the message?

### 5. Trust Signals and Social Proof

**Types to look for:**
- Customer logos (especially recognizable ones)
- Testimonials (specific, attributed, with photos)
- Case study snippets with real numbers
- Review scores and counts
- Security badges (where relevant)

**Placement:** Near CTAs and after benefit claims

### 6. Objection Handling

**Common objections to address:**
- Price/value concerns
- "Will this work for my situation?"
- Implementation difficulty
- "What if it doesn't work?"

**Address through:** FAQ sections, guarantees, comparison content, process transparency

### 7. Friction Points

**Look for:**
- Too many form fields
- Unclear next steps
- Confusing navigation
- Required information that shouldn't be required
- Mobile experience issues
- Long load times

### 8. Performance / Core Web Vitals

Slow pages are one of the cheapest large conversion wins, and the effect is biggest on mobile and paid traffic (where abandonment is already higher).

- Measure **LCP, INP, CLS** via PageSpeed Insights (lab) and CrUX / Search Console (real-user field data).
- Google's "good" thresholds, as rules of thumb: LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1 (targets, not guarantees).
- Treat failing Core Web Vitals as a high-priority blocker — check early, since fixes are often cheap relative to the lift.

---

## Output Format

Structure your recommendations as:

### Quick Wins (Implement Now)
Easy changes with likely immediate impact.

### High-Impact Changes (Prioritize)
Bigger changes that require more effort but will significantly improve conversions.

### A/B Test Ideas
Hypotheses worth A/B testing rather than assuming.

### Copy Direction (hand to copywriting for final variants)
For key elements (headlines, CTAs), describe the problem and the angle to pursue — the copywriting skill produces the final variants.

---

## Benchmarks

| Page Type | Typical Conversion Rate | Good | Excellent |
|-----------|------------------------|------|-----------|
| Landing page (paid traffic) | 2-5% | 5-10% | 10%+ |
| Homepage → signup | 1-3% | 3-7% | 7%+ |
| Pricing page → free trial | 3-5% | 5-8% | 10%+ |
| Pricing page → paid signup | 2-3% | 3-5% | 5%+ |
| Feature page → CTA click | 3-8% | 8-15% | 15%+ |
| Blog → CTA click | 0.5-2% | 2-5% | 5%+ |

These figures are directional and vary by industry, traffic source, period, and price point — validate against your own data. Paid traffic converts higher (intent) but costs more.

---

## Before/After Example: SaaS Landing Page Hero

**Before (weak):**
```
Headline: "Welcome to ProjectFlow"
Subhead: "The all-in-one project management solution for modern teams"
CTA: "Learn More"
[Stock photo of people in office]
```
Problems: Generic headline says nothing specific. "All-in-one" is a cliche that communicates nothing. "Learn More" is a low-commitment CTA that doesn't describe what happens next. Stock photo adds no value.

**After (optimized):**
```
Headline: "Ship projects 2x faster with half the meetings"
Subhead: "ProjectFlow replaces your standup, Kanban board, and status updates
           with one async workspace. Used by 4,000+ remote teams."
CTA: "Start Free — No Credit Card"
[Screenshot of actual product showing a project board]
```
Why it works: Headline states a specific, desirable outcome. Subhead explains how and adds social proof. CTA removes risk ("Free", "No Credit Card"). Product screenshot shows exactly what they get.

---

## Page-Specific Frameworks

### Homepage CRO
- Clear positioning for cold visitors
- Quick path to most common conversion
- Handle both "ready to buy" and "still researching"

### Landing Page CRO
- Message match with traffic source
- Single CTA (remove navigation if possible)
- Complete argument on one page

### Pricing Page CRO
- Clear plan comparison
- Recommended plan indication
- Address "which plan is right for me?" anxiety

### Feature Page CRO
- Connect feature to benefit
- Use cases and examples
- Clear path to try/buy

### Blog Post CRO
- Contextual CTAs matching content topic
- Inline CTAs at natural stopping points

---

## Experiment Ideas

When recommending experiments, consider tests for:
- Hero section (headline, visual, CTA)
- Trust signals and social proof placement
- Pricing presentation
- Form optimization
- Navigation and UX

**For comprehensive experiment ideas by page type**: See [experiments.md](experiments.md)
