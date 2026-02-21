# Tier Structure Design

Frameworks for designing pricing tiers and packaging features.

---

## Good-Better-Best Framework

### Three-Tier Structure

| Tier | Role | Pricing | Target |
|------|------|---------|--------|
| **Good (Entry)** | Low barrier, prove value | Lowest | Price-sensitive, small teams |
| **Better (Recommended)** | Best value, most customers | 2-3x Good | Core target persona |
| **Best (Premium)** | Advanced needs, power users | 2-3x Better | Larger teams, enterprises |

### What Each Tier Should Include

**Good tier:**
- Core features that deliver primary value
- Enough to experience the Aha Moment
- Limited usage/seats/projects
- Self-serve support

**Better tier (highlighted as "Most Popular"):**
- Everything in Good
- Full feature access for primary use case
- Generous limits
- Priority support
- This is your target tier — design it to be the obvious choice

**Best tier:**
- Everything in Better
- Advanced/enterprise features (SSO, API, admin controls)
- Highest or unlimited limits
- Dedicated support
- Custom integrations

---

## Tier Differentiation Strategies

| Strategy | How It Works | Best For |
|----------|-------------|----------|
| **Feature gating** | Basic vs. advanced features | Products with clear feature tiers |
| **Usage limits** | Same features, different limits | Usage-based products |
| **Support level** | Email → Priority → Dedicated | B2B SaaS |
| **Access level** | API, SSO, custom branding | Enterprise needs |
| **Team size** | Individual → Team → Organization | Collaboration tools |

---

## Value Metrics by Product Type

| Product Type | Common Metric | Example |
|-------------|---------------|---------|
| Collaboration | Per seat/user | Slack, Notion |
| Infrastructure | Per usage | AWS, Twilio |
| Marketing | Per contact/email | Mailchimp |
| CRM | Per seat + contacts | HubSpot |
| Design | Per editor seat | Figma |
| Analytics | Per event/MTU | Mixpanel |

---

## Pricing Psychology in Tiers

### Anchoring
Show the most expensive tier first (or most prominently) to anchor expectations high.

### Decoy Effect
The lowest tier should make the middle tier look like great value. If the gap between Good and Better is small but Better offers much more, Better becomes the obvious choice.

### Charm Pricing vs. Round Pricing
- Value-focused products: $49, $99, $199 (charm)
- Premium products: $50, $100, $200 (round)

### Annual Discount
- 15-25% off monthly pricing
- Show monthly equivalent: "$49/mo billed annually (save $118)"
- Pre-select annual toggle

---

## Tier Naming

### Name for the Buyer, Not the Product

**Good names (describe the user):**
- Starter / Professional / Enterprise
- Solo / Team / Business
- Essential / Growth / Scale

**Bad names (describe features):**
- Basic / Standard / Premium (generic, "Basic" feels insulting)
- Silver / Gold / Platinum (says nothing about value)

---

## Free Tier / Trial Strategy

### Freemium vs. Free Trial

| Model | Best For | Key Decision |
|-------|----------|-------------|
| **Freemium** | Products with network effects, low marginal cost | What's free? |
| **Free Trial** | Products with clear Aha Moment in short window | How long? |
| **Reverse Trial** | Best of both — trial premium, then downgrade to free | Which features to trial? |

### Freemium Design Principles
- Free tier must deliver real value (not crippled)
- Core features free, advanced features paid
- Don't gate features that create the Aha Moment
- Free tier should create upgrade desire through natural usage growth

### Trial Length
- 7 days: Simple products, clear immediate value
- 14 days: Most SaaS products
- 30 days: Complex products, longer decision cycles
- Shorter trials create urgency but need faster onboarding

---

## Enterprise Tier

### When to Add "Contact Sales"

Add when you have:
- Customers needing custom pricing
- Deals >$1,000/month
- Enterprise requirements (SSO, SLA, compliance)
- Sales capacity to handle inquiries

### What Enterprise Typically Includes
- Custom pricing
- SSO/SAML
- SLA guarantees
- Dedicated support/CSM
- Custom integrations
- Advanced security/compliance
- Admin controls and audit logs

---

## Pricing Checklist

### Before Launch
- [ ] Defined target personas for each tier
- [ ] Researched competitor pricing
- [ ] Identified value metric
- [ ] Conducted willingness-to-pay research
- [ ] Mapped features to tiers with clear rationale

### Tier Structure
- [ ] 3 tiers (or 3 + Enterprise)
- [ ] Clear differentiation between tiers
- [ ] Middle tier highlighted as recommended
- [ ] Annual discount 15-25%
- [ ] Enterprise/custom option if applicable
