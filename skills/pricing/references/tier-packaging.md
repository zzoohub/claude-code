# Tier Structure & Packaging

Frameworks for designing pricing tiers, packaging features, and making free tier/trial decisions.

---

## Table of Contents

1. [Good-Better-Best Framework](#good-better-best-framework)
2. [Feature Gating Strategy](#feature-gating-strategy)
3. [Value Metrics by Product Type](#value-metrics-by-product-type)
4. [Tier Naming](#tier-naming)
5. [Free Tier & Trial Strategy](#free-tier--trial-strategy)
6. [Enterprise Tier](#enterprise-tier)
7. [Pricing Psychology in Tiers](#pricing-psychology-in-tiers)
8. [Pricing Checklist](#pricing-checklist)

---

## Good-Better-Best Framework

Three tiers is the sweet spot for most B2B SaaS. It keeps choices simple while enabling segmentation. The middle tier is the workhorse — design it to capture the majority.

### Three-Tier Architecture

| Tier | Role | Price Ratio | Target Persona |
|------|------|------------|---------------|
| **Good** (Entry) | Prove value, low barrier | 1x | Individuals, small teams, price-sensitive |
| **Better** (Recommended) | Best value for core use case | 2-3x Good | Teams, core persona, growing companies |
| **Best** (Premium) | Advanced/enterprise needs | 2-3x Better | Large orgs, power users, enterprise |

### What Each Tier Includes

**Good tier — Activate and demonstrate value:**
- Core features that deliver the primary value proposition
- Enough to experience the "aha moment" — never gate this
- Limited usage/seats/projects (enough to start, not enough to scale)
- Self-serve support (docs, community)
- This tier exists to convert, not to generate revenue

**Better tier — The obvious choice (highlight as "Most Popular"):**
- Everything in Good
- Full feature access for the primary use case
- Generous limits that fit the core persona comfortably
- Priority support
- Team collaboration features
- Integrations with common tools
- Design this tier so most customers feel it's exactly what they need

**Best tier — Unlock enterprise and power use:**
- Everything in Better
- Advanced features: SSO/SAML, API access, admin controls, audit logs
- Highest or unlimited limits
- Dedicated support / CSM
- Custom integrations, SLAs
- Advanced security and compliance features

### When to Use Fewer or More Tiers

**Two tiers** — When your product is simple with a clear free/paid divide (e.g., personal vs. team use). Works for early-stage products still discovering segments.

**Four tiers** — When you have genuinely distinct segments (e.g., Solo / Team / Business / Enterprise). Only add the fourth if the third tier can't accommodate both mid-market and enterprise needs.

**Key principle**: if adding a tier doesn't clearly map to a distinct persona with different needs and willingness to pay, don't add it.

---

## Feature Gating Strategy

Feature gating decisions determine upgrade motivation. The goal is creating a natural pull toward higher tiers without crippling the lower ones.

### Gating Framework

Categorize every feature into one of four buckets:

| Category | Placement | Rationale |
|----------|-----------|-----------|
| **Core value** | All tiers | Features needed to experience the product's core value. Gating these causes churn before upgrade. |
| **Growth triggers** | Mid tier+ | Features customers naturally want as they succeed and scale (more seats, projects, storage) |
| **Power features** | Top tier | Advanced capabilities that sophisticated users need (API, automations, custom workflows) |
| **Enterprise controls** | Enterprise only | Admin, security, compliance features that only matter at organizational scale (SSO, SCIM, audit logs) |

### Gating Anti-Patterns

- **Gating the aha moment** — If users can't experience the core value on the entry tier, they leave before upgrading
- **Too many features in the entry tier** — No upgrade motivation; the free/cheap tier becomes "good enough forever"
- **Arbitrary gating** — Moving features to higher tiers without a value-based reason (customers notice and resent this)
- **Gating collaboration** — If your product's value increases with team use, gating collaboration features below the team tier limits viral growth

### Usage Limits as Gating

Usage limits are often better than feature locks because they let everyone try everything, then naturally upgrade as they grow:

```
Good:   3 projects, 1 user, 1GB storage
Better: 25 projects, 10 users, 50GB storage
Best:   Unlimited projects, unlimited users, 500GB storage
```

This approach lets customers experience full product value and creates organic upgrade triggers.

---

## Value Metrics by Product Type

Choose the metric that correlates most directly with value delivered:

| Product Type | Common Metric | Example | Why It Works |
|-------------|---------------|---------|-------------|
| Team collaboration | Per seat/user | Slack, Notion | Value scales with team size |
| Infrastructure/API | Per usage (calls, GB, compute) | AWS, Twilio, Stripe | Value = consumption |
| Marketing automation | Per contacts/emails | Mailchimp, HubSpot | Revenue potential scales with audience |
| CRM | Per seat + contacts | HubSpot, Salesforce | Combines user and data value |
| Design tools | Per editor seat | Figma | Creative output scales with editors |
| Analytics | Per events/MTU | Mixpanel, Amplitude | Value scales with data volume |
| AI copilots | Per seat + credits/usage | GitHub Copilot, Cursor | Seat for access, credits for consumption |
| AI agents | Per task/outcome | AI support bots | Value = work completed |
| Dev tools | Per repo/project | GitHub, Vercel | Value scales with projects |
| Security | Per asset/endpoint | Datadog, CrowdStrike | Value = coverage |

### Choosing Your Metric

Apply the HOPE framework (see SKILL.md Step 2). If two metrics score similarly, favor the one that's more **familiar** to your buyer — unfamiliar metrics create friction in the buying process.

---

## Tier Naming

### Name for the Buyer, Not the Product

Tier names should tell the customer "this is for someone like you."

**Effective naming patterns:**

| Pattern | Tiers | Works Because |
|---------|-------|--------------|
| Journey stage | Starter → Growth → Scale | Maps to company lifecycle |
| Role-based | Solo → Team → Business | Maps to buyer identity |
| Capability | Essential → Professional → Enterprise | Maps to need level |

**Anti-patterns:**

| Names | Problem |
|-------|---------|
| Basic / Standard / Premium | "Basic" feels insulting. Nobody aspires to be "basic." |
| Silver / Gold / Platinum | Says nothing about who it's for or what they get |
| v1 / v2 / v3 | Technical, meaningless to buyers |
| Cute names (Seedling / Sapling / Redwood) | Memorable but confusing — which one has SSO? |

### Naming Tips

- The entry tier name should feel like a *starting point*, not a *lesser version*
- The middle tier name should feel like what most people should choose
- The top tier name should feel aspirational and professional, not exclusionary
- Test names with actual customers — what do they assume each tier includes?

---

## Free Tier & Trial Strategy

### Decision Framework

| Factor | Freemium | Free Trial | Hybrid (Freemium + Trial of Premium) |
|--------|----------|------------|--------------------------------------|
| Time-to-value | Quick (< 5 min) | Longer (needs setup) | Quick core + longer premium |
| Marginal cost per user | Low | N/A | Low |
| Network effects | Strong | Weak | Moderate |
| Product complexity | Simple, self-serve | Complex, needs guidance | Mixed |
| Conversion target | 2-5% (volume play) | 8-25% (quality play) | Best of both |
| Strategic goal | Market penetration | Revenue efficiency | Maximum flexibility |

### Conversion Benchmarks

| Model | Typical Rate | Best-in-Class |
|-------|-------------|---------------|
| Freemium → Paid | 2-5% | 5-7% |
| Free trial, opt-in (no card) | 8-12% | 15-25% |
| Free trial, opt-out (card required) | 25-40% | 40-50% |
| Reverse trial (full → downgrade to free) | 10-15% | 20%+ |

### Freemium Design Principles

Patrick Campbell: "Freemium is an acquisition model, not a revenue model." Only offer freemium when you understand your customer well enough to convert.

- **Provide ~80% of functionality free**, reserve 20% of highest-value features for paid
- The free tier must deliver real value — not a demo, not a teaser
- Core success features are always free; upgrade triggers come from scale, not from missing basics
- Create natural upgrade moments: "You've hit your 3-project limit. Upgrade to continue growing."
- Free users should become advocates — word-of-mouth is the ROI of freemium

### Trial Length

| Duration | Best For | Trade-off |
|----------|----------|-----------|
| 7 days | Simple products, immediate value, self-serve | High urgency but short evaluation window |
| 14 days | Most SaaS products | Good balance of urgency and exploration |
| 30 days | Complex products, long decision cycles, enterprise | More evaluation time but lower urgency |

Shorter trials convert at higher rates (urgency effect) but require faster onboarding. If your time-to-value is >3 days, don't offer a 7-day trial.

### Reverse Trial

Increasingly popular hybrid: give full premium access for 14 days, then downgrade to free tier. Customers experience premium value first, making the free tier feel like a loss — loss aversion drives upgrades.

Companies using reverse trials report **18% higher net dollar retention** compared to pure freemium.

---

## Enterprise Tier

### When to Add "Contact Sales"

Add an enterprise tier when:
- Customers request custom pricing (signal: 3+ requests/month)
- Deals consistently exceed $1,000/month
- Enterprise requirements emerge (SSO, SLA, compliance)
- You have sales capacity to handle inquiries
- Standardized tiers can't accommodate large-org complexity

### What Enterprise Typically Includes

| Category | Features |
|----------|----------|
| **Security** | SSO/SAML, SCIM provisioning, IP allowlisting, encryption at rest |
| **Compliance** | SOC 2 report access, HIPAA BAA, GDPR DPA, audit logs |
| **Administration** | Role-based access, admin dashboard, team management |
| **Support** | Dedicated CSM, SLA guarantees, priority support, training |
| **Scale** | Unlimited usage, custom integrations, API priority access |
| **Customization** | Custom branding, custom contracts, invoicing |

### Enterprise Pricing Approaches

| Approach | When to Use |
|----------|------------|
| **Contact sales** (custom quote) | Large deals, complex requirements, relationship-driven |
| **Published starting price** ("Starting at $X/mo") | Want to qualify leads, reduce tire-kicker calls |
| **Self-serve enterprise** | Low-touch sales, high volume, clear enterprise features |

---

## Pricing Psychology in Tiers

### Anchoring

Display the most expensive tier first (or most prominently) to set price expectations high. When customers see the $299/mo plan first, the $99/mo plan feels like a bargain. Presenting premium first increases average deal value by up to 32%.

### Decoy Effect

Structure pricing so the lowest tier makes the middle tier look like great value:

```
Starter: $29/mo  — 5 projects, 1 user
Pro:     $49/mo  — Unlimited projects, 5 users, priority support  ← Obvious value jump
Business: $149/mo — Everything in Pro + SSO, API, dedicated support
```

The small gap between Starter and Pro ($20) with a large value gap makes Pro the obvious choice. This is intentional — implementing a strategic decoy increases mid-tier selection by up to 43%.

### Compromise Effect

When presented with three options, people gravitate toward the middle. This is why 3-tier pricing works — it naturally funnels customers to the middle tier. If you want more people in the top tier, consider adding a fourth (ultra-premium) tier to shift the "middle" up.

### Charm Pricing vs. Round Pricing

| Context | Approach | Examples |
|---------|----------|---------|
| Value/volume products | Charm pricing ($X9) | $29, $49, $99, $199 |
| Premium/luxury positioning | Round pricing | $50, $100, $200 |
| Enterprise (>$500/mo) | Round pricing | $500, $1,000, $2,500 |

For most SaaS under $200/mo, charm pricing outperforms round pricing. Above $500/mo, the psychological effect weakens and round numbers feel more professional.

### Annual Discount Display

Show the monthly equivalent of annual pricing to make the savings concrete:
- "$49/mo billed annually (save $118/year)" — anchors on the familiar monthly price
- Pre-select the annual toggle — defaults to annual increases annual adoption by 19%
- Show "2 months free" — frames the discount as a bonus rather than a reduction

---

## Pricing Checklist

### Before Launch

- [ ] Defined target persona for each tier (who exactly is this for?)
- [ ] Conducted willingness-to-pay research (Van Westendorp minimum)
- [ ] Identified value metric using HOPE framework
- [ ] Researched competitor pricing (tiers, features, metrics)
- [ ] Mapped features to tiers with clear rationale per feature
- [ ] Validated tier structure with 5-10 target customers
- [ ] Designed natural upgrade triggers (not just feature locks)
- [ ] Set annual discount (15-20% range)

### Tier Structure Validation

- [ ] 3 tiers (or 3 + Enterprise) — not more unless clearly justified
- [ ] Clear differentiation between tiers (no "what's the difference?" confusion)
- [ ] Middle tier highlighted as recommended
- [ ] Entry tier delivers enough value for aha moment
- [ ] Each tier maps to a distinct persona/use case
- [ ] Upgrade path is natural, not forced
- [ ] Enterprise option exists if applicable

### Post-Launch

- [ ] Monitoring upgrade/downgrade patterns (wrong tier → wrong packaging)
- [ ] Tracking tier selection distribution (if >60% choose one tier, rebalance)
- [ ] Reviewing quarterly (not set-and-forget)
- [ ] A/B testing pricing page presentation
- [ ] Gathering qualitative feedback on pricing perception
