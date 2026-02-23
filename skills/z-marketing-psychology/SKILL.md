---
name: z-marketing-psychology
description: |
  70+ mental models and psychological principles for marketing, pricing, and growth decisions.
  Use when: applying persuasion principles, understanding buyer psychology, choosing pricing tactics,
  designing nudges, optimizing conversion with psychology, or when user mentions "psychology",
  "mental model", "persuasion", "cognitive bias", "behavioral economics", "nudge", "anchoring",
  "scarcity", "social proof", "loss aversion", "framing effect".
  Do NOT use for: writing copy (use z-copywriting skill), page-level CRO (use z-cro skill),
  or pricing tier design and strategy (use z-pricing skill — this skill covers the psychology
  behind why pricing works; z-pricing covers what to charge and how to structure tiers).
metadata:
  version: 1.1.0
  category: marketing
---

# Marketing Psychology & Mental Models

70+ mental models organized for marketing application. Use these to understand why people buy, influence behavior ethically, and make better marketing decisions.

**Product context**: If `.claude/product-marketing-context.md` exists, read it first to tailor recommendations to the specific product and audience.

---

## How to Use This Skill

1. **Identify the challenge** — What behavior are you trying to influence?
2. **Find relevant models** — Use the Quick Reference table below
3. **Select 2-3 models** — Don't overload; pick the most applicable
4. **Apply with guardrails** — See Ethical Guardrails below
5. **Test the application** — Use z-cro experiments to validate

---

## Ethical Guardrails

These models are for influence, not manipulation. The line:

- **Never fabricate scarcity** — Fake countdown timers, invented "only 3 left" claims, or artificial urgency erode trust and may violate consumer protection laws.
- **Never exploit vulnerability** — Don't target people in distress, financial hardship, or emotional states to push decisions they'd regret.
- **Disclose honestly** — If something is sponsored, paid, or an ad, say so. If a "sale" price is the permanent price, it's not a sale.
- **Preserve autonomy** — Dark patterns (hiding unsubscribe, pre-checked boxes for charges, confusing opt-out flows) are manipulation, not persuasion.
- **The regret test** — If a customer understood exactly what you did and why, would they feel respected or deceived?

---

## Mental Model Categories

### Foundational Thinking Models
Strategy and problem-solving frameworks:
- **First Principles** — Break problems to basic truths, build up
- **Jobs to Be Done** — People hire products for outcomes, not features
- **Circle of Competence** — Stay where you have genuine advantage
- **Inversion** — Ask "what would guarantee failure?" and avoid those
- **Occam's Razor** — Simplest explanation is usually correct
- **Pareto Principle** — 80% of results from 20% of efforts
- **Theory of Constraints** — Find and fix the ONE bottleneck
- **Second-Order Thinking** — Consider effects of effects
- **Barbell Strategy** — 80% proven + 20% experimental

Also in reference: Opportunity Cost, Law of Diminishing Returns, Local vs Global Optima, Map ≠ Territory, Probabilistic Thinking

### Understanding Buyers & Psychology
How customers think and decide:
- **Mere Exposure Effect** — Familiarity breeds preference
- **Confirmation Bias** — People seek info confirming beliefs
- **Mimetic Desire** — People want what others want
- **Endowment Effect** — People value what they already own more
- **IKEA Effect** — People value what they helped create
- **Zero-Price Effect** — "Free" is psychologically different from cheap
- **Status-Quo Bias** — Change feels risky; defaults are powerful
- **Paradox of Choice** — Fewer options lead to more decisions
- **Peak-End Rule** — Experiences judged by peak moment and ending
- **Sunk Cost Fallacy** — Past investment shouldn't justify future spend

Also in reference: Fundamental Attribution Error, Availability Heuristic, Lindy Effect, Hyperbolic Discounting, Default Effect, Goal-Gradient Effect, Zeigarnik Effect, Pratfall Effect, Curse of Knowledge, Regret Aversion, Mental Accounting, Bandwagon Effect

### Influencing Behavior & Persuasion
Ethical influence techniques:
- **Reciprocity** — Give first, people feel obligated to return
- **Commitment & Consistency** — Small commitments lead to larger ones
- **Authority Bias** — People defer to experts and credentials
- **Social Proof** — People follow what others do
- **Scarcity/Urgency** — Limited availability increases perceived value
- **Loss Aversion** — Losses feel 2x more painful than equivalent gains
- **Anchoring** — First number seen influences all subsequent judgments
- **Decoy Effect** — Third option makes preferred choice look better
- **Framing Effect** — Same facts, different presentation, different perception
- **Foot-in-the-Door** — Small request → larger request compliance

Also in reference: Liking/Similarity Bias, Unity Principle, Door-in-the-Face, Contrast Effect

### Pricing Psychology
- **Charm Pricing** — $99 feels much cheaper than $100
- **Rounded-Price Effect** — Round numbers signal premium ($100 vs $99)
- **Rule of 100** — Under $100: use %; over $100: use absolute discount
- **Price Relativity** — Middle tier seems reasonable between cheap and expensive
- **Mental Accounting** — "$1/day" feels cheaper than "$30/month"

### Design & Delivery Models
- **Hick's Law** — More choices = slower decisions = more abandonment
- **AIDA** — Attention → Interest → Desire → Action
- **BJ Fogg Model** — Behavior = Motivation × Ability × Prompt
- **EAST Framework** — Easy, Attractive, Social, Timely
- **Activation Energy** — Reduce starting friction for action

Also in reference: Rule of 7, Nudge Theory/Choice Architecture, COM-B Model, North Star Metric, Cobra Effect

### Growth & Scaling Models
- **Feedback Loops** — Output becomes input, creating cycles
- **Network Effects** — Product value increases with more users
- **Flywheel Effect** — Sustained effort creates self-maintaining momentum
- **Switching Costs** — High switching costs create retention
- **Critical Mass** — Threshold where growth becomes self-sustaining

Also in reference: Compounding, Exploration vs Exploitation, Survivorship Bias

Full descriptions with marketing applications: `references/mental-models-reference.md`

---

## Quick Reference

| Marketing Challenge | Models to Apply |
|---------------------|----------------|
| Low conversions | Hick's Law, Activation Energy, BJ Fogg, EAST Framework |
| Price objections | Anchoring, Framing, Mental Accounting, Loss Aversion |
| Building trust | Authority, Social Proof, Reciprocity, Pratfall Effect |
| Increasing urgency | Scarcity, Loss Aversion, Zeigarnik Effect |
| Retention/churn | Endowment Effect, Switching Costs, Status-Quo Bias |
| Growth stalling | Theory of Constraints, Local vs Global Optima, Compounding |
| Decision paralysis | Paradox of Choice, Default Effect, Nudge Theory |
| Onboarding | Goal-Gradient, IKEA Effect, Commitment & Consistency |
| Pricing feels wrong | Charm Pricing, Decoy Effect, Price Relativity, Rule of 100 |
| Users not activating | IKEA Effect, Endowment Effect, Foot-in-the-Door |
| High churn | Sunk Cost awareness, Switching Costs, Status-Quo Bias |

---

## Worked Example: Improving Onboarding Activation

**Challenge**: Users sign up for a project management tool but 60% never create their first project.

**Models selected**: Foot-in-the-Door + Goal-Gradient Effect + IKEA Effect

**How they combine**:
1. **Foot-in-the-Door**: Don't ask users to set up their whole workspace. Start with one tiny ask: "Name your first project." This small commitment makes the next step feel natural.
2. **Goal-Gradient Effect**: Show a progress bar — "3 of 5 steps complete." As users approach the finish, they accelerate. The bar creates pull toward completion.
3. **IKEA Effect**: Let users customize their project (choose a color, add a description, invite one teammate). The effort they invest makes the project feel like *theirs*, increasing reluctance to abandon it.

**Result framing**: Instead of "Set up your workspace" (high activation energy, vague), the flow becomes a series of small, visible, personally invested steps that compound into commitment.

---

## Application Process

1. **Diagnose the barrier** — What's preventing the desired behavior?
2. **Match models** — Which mental models explain the barrier?
3. **Design intervention** — How can you apply the model within ethical guardrails?
4. **Implement** — Use z-copywriting for messaging, z-cro for flow changes
5. **Measure** — Use z-data-analyst to track impact

---

## Cross-References

- **z-cro** (skill) — Apply psychological models to specific conversion scenarios
- **z-copywriting** (skill) — Use models to inform persuasive copy
- **z-pricing** (skill) — Pricing strategy and tier design (this skill covers the psychology; z-pricing covers what to charge)
- **z-churn-prevention** (skill) — Retention psychology for cancel flows
