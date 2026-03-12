# GEO: Entity Clarity Reference

How AI systems identify, categorize, and evaluate your brand, and how to make those signals clear and consistent.

---

## What Entity Clarity Means

AI systems do not just read text. They build a structured understanding of entities: brands, products, people, organizations, and concepts.

For your brand to appear in AI answers, AI systems need to confidently determine:
- **What** your brand is (product, service, company, individual)
- **What category** it belongs to (CRM software, organic dog food, B2B SaaS, etc.)
- **What topics** it is authoritative for
- **How it differs** from entities with similar names

When these signals are unclear or inconsistent across sources, AI systems have lower confidence in referencing you. Low confidence means less visibility.

---

## Entity Ambiguity

### The Problem

Many brand names overlap with common words or other entities:
- "Monday": Day of the week or project management software?
- "Apple": Fruit or technology company?
- "Mercury": Planet, element, or fintech company?

### How to Resolve It

**On your website**:
- Use full brand identifiers consistently: "monday.com" not just "Monday"
- Include category context near every brand mention: "monday.com, the work management platform" not just "monday.com"
- Homepage and About page should clearly state: [Brand] is a [category] that [value proposition]

**Across platforms**:
- Use identical brand descriptions across LinkedIn, Crunchbase, G2, industry directories
- Wikipedia/Wikidata entries (if your brand qualifies) provide strong entity disambiguation signals
- Google Business Profile should reflect the same category and description

**In structured data**:
- Organization schema with clear `name`, `description`, `url`, and `sameAs` linking to official profiles
- Product schema with unambiguous `name`, `description`, `category`

---

## Brand Consistency Across Platforms

AI systems cross-reference information from multiple sources to build confidence in entity understanding. Inconsistency reduces confidence.

### Critical Platforms to Align

| Platform | What to Align |
|----------|---------------|
| Your website | Brand name, description, category, value proposition |
| LinkedIn (company page) | Description, industry, specialties |
| Crunchbase | Description, category, founding date, key people |
| Google Business Profile | Business name, category, description |
| G2 / Capterra / Trustpilot | Product category, description |
| Wikipedia / Wikidata | Entity description (if notable enough) |
| Industry directories | Category listing, description |
| Social profiles (X, YouTube, etc.) | Bio, description, category |
| App stores (if applicable) | App description, category |
| Google Merchant Center (if applicable) | Product feed descriptions, categories |

### What Consistent Means

It does not mean identical copy-paste everywhere. It means:
- Same core positioning and value proposition
- Same category/industry classification
- Same key features and differentiators highlighted
- No contradictions (e.g., "AI-powered CRM" on website but "email marketing tool" on G2)
- Same founding facts, key people, location info

### Audit Process

1. List all platforms where your brand has a presence
2. Extract the brand description, category, and positioning from each
3. Identify inconsistencies and contradictions
4. Create a canonical brand description document
5. Update all platforms to align with the canonical version
6. Set a quarterly review cadence to catch drift

---

## Structured Data for Entity Clarity

### Organization Schema

Every site should have Organization schema on the homepage (or sitewide). This tells AI systems who you are at a machine-readable level.

Essential properties:
- `@type`: Organization (or more specific: Corporation, LocalBusiness, etc.)
- `name`: Official brand name
- `url`: Official website URL
- `logo`: Official logo URL
- `description`: Clear, concise brand description
- `sameAs`: Array of official social profiles and platform listings
- `foundingDate`: When the company was founded
- `founder`: Key founders (if relevant)

The `sameAs` property is particularly important for entity clarity. It explicitly tells AI systems which external profiles belong to this entity.

### Product Schema

For product pages, clear Product schema helps AI systems understand and categorize what you sell.

Essential properties:
- `name`: Unambiguous product name
- `description`: Clear product description
- `brand`: Link to your Organization entity
- `category`: Product category
- `offers`: Price, availability, currency

### Alignment Principle

Schema markup must mirror visible page content. Do not include information in schema that is not on the page, and do not omit from schema information that is prominent on the page.

The same information should be consistent across:
1. **Visible page content** (what users see)
2. **Schema markup** (what search engines read in JSON-LD)
3. **External data feeds** (Google Merchant Center, product feeds, etc.)

When all three agree, AI systems have maximum confidence in the entity information.

---

## Building Entity Authority on Specific Topics

Entity clarity is not just about identity. It is about topical authority. AI systems need to know what topics you are credible for.

### How to Build Topical Authority

**Content depth**: Publish comprehensive, interconnected content on your core topics (topic clusters / hub-and-spoke model from SEO)

**Consistent publishing**: Regular content on the same topics over time signals sustained expertise, not one-off coverage

**Author credentials**: Connect content to real people with verifiable expertise. Author bios, LinkedIn profiles, speaking engagements, and publications all contribute.

**External validation**: Earn mentions from authoritative sources in your topic area. Guest posts on industry publications, citations in research, mentions in news coverage.

**Cross-platform reinforcement**: If you are authoritative on "email marketing," that should be evident from your website, your YouTube channel, your LinkedIn content, your podcast appearances, and third-party reviews, not just one source.

### Topic-Entity Mapping

For each core topic your brand should be known for:

1. **Website**: Do you have a clear content cluster on this topic?
2. **Schema**: Does your Organization schema reflect expertise in this area?
3. **External sources**: Do third parties mention you in context of this topic?
4. **Social/community**: Are you active in discussions about this topic?
5. **Reviews/testimonials**: Do customers reference this capability?

Gaps in any of these weaken AI confidence in your authority on that topic.

---

## Entity Clarity Audit Checklist

### Brand Identity
- [ ] Homepage clearly states: [Brand] is a [category] that [value proposition]
- [ ] About page provides comprehensive brand information
- [ ] Organization schema with `name`, `description`, `url`, `logo`, `sameAs`
- [ ] `sameAs` includes all official external profiles
- [ ] Brand name is used consistently (no variations that could cause confusion)

### Cross-Platform Consistency
- [ ] Brand description aligned across all platforms
- [ ] Category/industry classification consistent everywhere
- [ ] Key features and positioning consistent
- [ ] No contradictions between any two platforms
- [ ] Contact information consistent (address, phone, email)

### Product/Service Clarity
- [ ] Each product/service has clear, unambiguous description
- [ ] Product schema matches visible page content
- [ ] Product categories correctly assigned
- [ ] Product feeds (Merchant Center, etc.) aligned with website content

### Topical Authority
- [ ] Core topics identified (3-5 key areas)
- [ ] Content clusters exist for each core topic
- [ ] Authors have visible credentials related to topics
- [ ] External sources reference your brand in context of these topics
- [ ] Cross-platform content reinforces topical authority

### Disambiguation (if brand name is ambiguous)
- [ ] Full brand identifier used consistently
- [ ] Category context provided near brand mentions
- [ ] Wikipedia/Wikidata entry exists or is in progress (if notable enough)
- [ ] Google Knowledge Panel claimed and accurate (if available)
