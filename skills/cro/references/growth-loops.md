# Growth Loops & Referral Programs

Frameworks for designing compounding user-acquisition loops: viral, content, paid, and integration loops. This file is the canonical reference for the growth-optimizer agent's referral/viral work.

---

## The Loop Mental Model

Growth loops are systems where each cycle of input produces output that feeds the next cycle. They compound; funnels don't. A loop has four parts:

1. **Input** — New user / action / content
2. **Action** — What they do
3. **Output** — Artifact their action produces
4. **Re-entry** — How the output brings the next input back in

If any step breaks, the loop collapses into a one-time funnel.

---

## Loop Types

| Type | Input | Output | Examples |
|------|-------|--------|----------|
| **Viral (direct)** | User signs up | Invites people they know | WhatsApp, Dropbox, Calendly |
| **Viral (content)** | User creates public artifact | Artifact attracts new users | YouTube, Notion public pages, GitHub |
| **Paid** | Revenue | Ad spend acquires users | Most DTC |
| **Sales** | SDR contacts prospect | Prospect becomes customer | Enterprise SaaS |
| **Integration / API** | Product embedded elsewhere | New users discover via partner | Stripe, Intercom embeds, Zapier triggers |
| **UGC / Marketplace** | Supply-side user lists | Demand-side user searches | Airbnb, Etsy, Upwork |

Pick one loop to be dominant. Multiple loops can coexist but one must be primary — two "primary" loops is a way to under-invest in both.

---

## Referral / Viral Loop Design (5 Stages)

The canonical framework for direct viral loops:

### 1. Trigger
**When** does the user get prompted to invite? Match it to a moment of perceived value.
- Bad: immediately after signup (user hasn't experienced value yet)
- Good: right after Aha Moment (user just got the win they came for)
- Great: repeatable trigger on every success event

### 2. Incentive
**Why** would they invite? Two-sided incentives beat one-sided in almost every case.
- One-sided (inviter gets reward): cheap but feels transactional
- Two-sided (both get reward): aligned interests, higher conversion
- No incentive (pure value share): works only when the product is genuinely better with friends (e.g., multiplayer, collaboration)

Match the incentive to the product's value unit. Credits for usage-priced products. Months free for subscriptions. Cash for finance products.

### 3. Mechanism
**How** do they invite? Reduce friction at every step.
- Shareable link (copy + send) — lowest friction
- Native share sheet — capture platform-specific apps
- Email invites — best for professional tools
- Contact import — highest absolute reach but highest friction and privacy risk
- In-product @-mention / co-edit invite — natural, contextual

Pre-fill the message where possible. Never force the inviter to compose from scratch.

### 4. Landing
**Where** does the invitee arrive? Personalized landings convert 2-4x better.
- Show the inviter's name/photo
- Reference the artifact that brought them (if content loop)
- Skip signup form fields you can infer (name from invite)
- Deep-link directly to the action the inviter wanted them to take

### 5. Activation
**How fast** can the invitee hit the Aha Moment? Every extra step halves conversion.
- Skip email verification until necessary (or use magic link)
- Pre-populate sample data so the product isn't empty
- Guide to first-action within one screen

---

## Viral Metrics

### K Factor (Viral Coefficient)

```
K = (invites sent per user) × (conversion rate of invitees)
```

- **K > 1** → Viral growth (each user brings more than one new user; exponential)
- **K = 1** → Stable (each user replaces themselves; linear)
- **K < 1** → Sub-viral (loop amplifies paid/organic but can't sustain alone)

Real K > 1 is extremely rare. Most sustainable growth comes from K between 0.2 and 0.7 compounded with low CAC channels.

### Amplification Factor

```
Amplification = 1 / (1 - K)     (only valid when K < 1)
```

Tells you the multiplier on organic/paid acquisition from viral spread.
- K = 0.3 → 1.43x (each paid user brings 0.43 extra via viral)
- K = 0.6 → 2.5x
- K = 0.9 → 10x

### Loop Cycle Time

Days from a user signing up to their invitees signing up. Shorter cycles compound faster.
- Target: <7 days for consumer, <30 days for B2B
- Optimize: shorten time-to-Aha-Moment, surface invite UI sooner after Aha

### Referral Conversion Rate

Invite → signup → activation. Track each step separately — most loops leak at landing → signup.

---

## Two Anti-Patterns

### Anti-Pattern 1: Incentive Without Value
Paying users to invite a product they don't use churns both sides. K goes up briefly, then retention cliffs. **Rule**: don't launch a referral program until you have a retention plateau.

### Anti-Pattern 2: Trigger Before Aha
Prompting for invites at signup or onboarding trains users to dismiss invite UI. You only get one "first ask." Save it for after the first success.

---

**Where to look first** when improving an existing loop: the step with lowest absolute conversion has highest ROI. Invite sent → invitee signup is the most common leak.

---

## Common Loop Patterns (Reference)

| Product | Loop Shape | What Makes It Work |
|---------|-----------|---------------------|
| **Calendly** | Invite-to-schedule | Every meeting invite is a product demo |
| **Dropbox** | Two-sided storage | Incentive matches value unit |
| **Figma** | Collaboration | Product is better with more editors |
| **Notion** | Public docs + templates | Content loop + utility loop |
| **Linear** | In-product @-mentions | Professional context, no incentive needed |
| **Superhuman** | Keyboard shortcut cult + waitlist | Scarcity + in-signature ad |
| **Typeform** | Branded form footer | Every completed form is an ad |

---

## Output Format (for growth-optimizer agent)

When designing a referral/viral loop, produce:

```markdown
## Loop: [Name]

### Shape
- Type: [direct viral | content | integration | ...]
- Input → Action → Output → Re-entry (one line each)

### 5 Stages
- Trigger: [when]
- Incentive: [what, for whom]
- Mechanism: [how]
- Landing: [where, personalization]
- Activation: [Aha path]

### Target Metrics
- K goal: [number]
- Cycle time goal: [days]
- Per-stage conversion goals

### Risks
- [what could break the loop]
- [churn cliff candidates]

### Test Plan
- [first experiment to validate]
```

---

## Cross-References

- **cro/SKILL.md** — This reference's parent skill; CRO primitives apply within each loop step
- **marketing-psychology** (skill) — Principles behind why incentives, social proof, reciprocity work in loops
- **churn-prevention** (skill) — If the loop brings users who churn, fix retention first
- **product-analytics** (skill) — Aha Moment discovery is a prerequisite to placing the invite trigger
