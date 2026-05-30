# AI Platform Optimization

Specific tactics for maximizing visibility in AI-powered search and answer platforms. Extends the GEO principles in the main skill with platform-specific and monitoring strategies.

For foundational GEO concepts, see: `geo-content-extractability.md`, `geo-entity-clarity.md`, `geo-multi-platform.md`

---

## How AI Search Platforms Select Sources

| Platform | How It Works | Source Selection |
|----------|-------------|----------------|
| **Google AI Overviews** | Summarizes top-ranking pages | Strong correlation with traditional rankings |
| **ChatGPT (with search)** | Searches web, cites sources | Wider range, not just top-ranked |
| **Perplexity** | Always cites sources with links | Favors authoritative, recent, well-structured content |
| **Gemini** | Google's AI assistant | Google index + Knowledge Graph |
| **Copilot** | Bing-powered AI search | Bing index + authoritative sources |
| **Claude** | Brave Search (when enabled) | Training data + Brave search results |

**Key difference from traditional SEO:** Traditional SEO gets you ranked. AI SEO gets you **cited**. A well-structured page can get cited even if it ranks on page 2 or 3.

**Critical stats** (as of early 2026 — these move fast; keep the date and re-verify):
- AI Overviews appear in roughly **15-25% of Google queries in broad global keyword studies** (Semrush: peaked ~25% mid-2025, ~16% by Nov 2025), but **45-60% in US-focused / curated-keyword trackers** and per Google's own framing (Advanced Web Ranking ~60% of US queries; BrightEdge/Google ~50%). Varies widely by country, intent, device, and measurement method — treat as directional, not a single fact
- AI Overviews can cut click-through to the **top organic result by up to ~58%** when present (Ahrefs, Dec 2025)
- Brands are reportedly cited via third-party sources (Reddit, Wikipedia, review sites) far more than via their own domains
- Well-structured, sourced content is cited materially more often than thin/undated content
- Adding statistics and citing sources are among the highest-leverage on-page tactics (see the GEO study below)

---

## The Three Pillars of AI Optimization

### Pillar 1: Structure — Make Content Extractable

AI systems extract passages, not pages. Every key claim should work as a standalone statement.

**Content block patterns:**
- **Definition blocks** for "What is X?" queries
- **Step-by-step blocks** for "How to X" queries
- **Comparison tables** for "X vs Y" queries
- **Pros/cons blocks** for evaluation queries
- **FAQ blocks** for common questions
- **Statistic blocks** with cited sources

**Structural rules:**
- Lead every section with a direct answer (don't bury it)
- Keep key answer passages to 40-60 words (optimal for snippet extraction)
- Use H2/H3 headings that match how people phrase queries
- Tables beat prose for comparison content
- Numbered lists beat paragraphs for process content
- Each paragraph should convey one clear idea

### Pillar 2: Authority — Make Content Citable

The **GEO study** (Aggarwal et al., *GEO: Generative Engine Optimization*, KDD 2024 — [arXiv:2311.09735](https://arxiv.org/abs/2311.09735); a Princeton / Georgia Tech / Allen AI / IIT Delhi paper, tested across multiple generative engines, **not** a "Perplexity.ai study") found GEO methods can boost visibility by **up to ~40%**. Its three strongest methods are citing sources, adding quotations, and adding statistics (collectively a 30-40% relative improvement on the paper's Position-Adjusted Word Count metric):

| Method | Effect | How to apply |
|--------|--------|--------------|
| **Cite sources** | Top tier | Add authoritative references with links |
| **Add quotations** | Top tier (strongest single method on one metric) | Expert quotes with name and title |
| **Add statistics** | Top tier | Include specific numbers with sources |
| **Authoritative tone / clarity / fluency** | Positive, smaller | Write with demonstrated expertise; simplify; improve flow |
| ~~Keyword stuffing~~ | **Counterproductive** | Do not do it — does not help and can hurt AI visibility |

**Biggest lever for underdogs:** citing credible external sources gave a **~115% visibility increase specifically for pages ranked ~5th** in the SERP (while top-ranked pages actually *lost* ~30%) — i.e., citations help lower-ranked pages most. The paper's exact per-method percentages depend on which metric you read (Position-Adjusted Word Count vs Subjective Impression), so pull them from its tables if you need precise figures rather than treating any single number as canonical.

**Freshness signals:**
- "Last updated: [date]" prominently displayed
- Regular content refreshes (quarterly minimum)
- Current year references and recent statistics
- Remove or update outdated information

### Pillar 3: Presence — Be Where AI Looks

AI systems don't just cite your website — they cite where you appear.

**Third-party sources matter more than your own site:**
- **Reddit** — typically the single most-cited domain across AI platforms (leads Google AI Overviews and Perplexity; ~12% of ChatGPT citations in Q1 2026, up sharply from ~2% in 2024-25). Highly volatile — Reddit's ChatGPT share swung from ~60% to ~10% of responses within two weeks in Sept 2025
- **Wikipedia** — consistently a top source (~8% of ChatGPT citations in 2024-25 per Profound; ~13% in Q1 2026 per 5W/Similarweb)
- Industry publications and guest posts
- Review sites (G2, Capterra, TrustRadius for B2B SaaS)
- YouTube (frequently cited by Google AI Overviews)
- Quora answers

(Citation shares vary by platform, study, and month — treat all figures as directional and re-check quarterly.)

**Actions:**
- Ensure your Wikipedia page is accurate and current
- Participate authentically in Reddit communities
- Get featured in industry roundups and comparison articles
- Maintain updated profiles on relevant review platforms
- Create YouTube content for key how-to queries

---

## AI Visibility Audit

### Step 1: Check AI Answers for Key Queries

Test 10-20 important queries across platforms:

| Query | Google AI Overview | ChatGPT | Perplexity | You Cited? | Competitors Cited? |
|-------|:-----------------:|:-------:|:----------:|:----------:|:-----------------:|
| [query 1] | Yes/No | Yes/No | Yes/No | Yes/No | [who] |

**Query types to test:**
- "What is [your product category]?"
- "Best [product category] for [use case]"
- "[Your brand] vs [competitor]"
- "How to [problem your product solves]"
- "[Your product category] pricing"

### Step 2: Analyze Citation Patterns

When competitors get cited and you don't, examine:
- **Content structure** — Is their content more extractable?
- **Authority signals** — More citations, stats, expert quotes?
- **Freshness** — More recently updated?
- **Schema markup** — Structured data you're missing?
- **Third-party presence** — Cited via Wikipedia, Reddit, review sites?

### Step 3: Content Extractability Check

For each priority page, verify:

| Check | Pass/Fail |
|-------|-----------|
| Clear definition in first paragraph? | |
| Self-contained answer blocks? | |
| Statistics with sources cited? | |
| Comparison tables for "X vs Y" queries? | |
| FAQ section with natural-language questions? | |
| Schema markup (FAQ, HowTo, Article, Product)? | |
| Expert attribution (author name, credentials)? | |
| Recently updated (within 6 months)? | |
| Heading structure matches query patterns? | |
| AI bots allowed in robots.txt? | |

### Step 4: AI Bot Access Check

Verify robots.txt allows the AI crawlers you want (see the canonical table in `technical-seo.md`):
- **OAI-SearchBot** (ChatGPT Search citation — this is the one that controls ChatGPT Search visibility), **ChatGPT-User** (live fetch), **GPTBot** (training) — OpenAI
- **PerplexityBot**, **Perplexity-User** — Perplexity
- **Claude-SearchBot** (search), **Claude-User** (live fetch), **ClaudeBot** (training) — Anthropic
- **Googlebot** — powers Google AI Overviews and AI Mode
- **Google-Extended** / **Applebot-Extended** — opt-out *tokens* for Gemini / Apple Intelligence training (not fetchers)
- **Bingbot** — Microsoft Copilot

Blocking the **search/citation** bots (OAI-SearchBot, PerplexityBot, Claude-SearchBot) prevents those platforms from citing you. You can allow search bots while blocking training-only crawlers (GPTBot, ClaudeBot, CCBot). Caveat: robots.txt does not reliably control every vendor — Cloudflare documented (Aug 2025) PerplexityBot using **undeclared stealth crawlers** that rotate IPs and impersonate browsers to evade no-crawl directives, and de-listed it as a verified bot.

---

## Content Types That Get Cited Most

Ranked roughly by how often each format gets cited (published citation-share percentages vary widely by study and shift month to month — e.g., listicle citation rates moved sharply over a single month in late 2025 — so rank the formats rather than trusting fixed percentages):

| Content Type | Why AI cites it |
|-------------|----------------|
| **Best-of / listicles** | Clear structure, entity-rich — often the single most-cited format |
| **Comparison / "X vs Y" articles** | Structured, balanced, high-intent |
| **Definitive guides** | Comprehensive, authoritative |
| **Original research / data** | Unique, citable statistics |
| **Product pages** | Specific details AI can extract |
| **How-to guides** | Step-by-step structure |

**Underperformers:** Generic blog posts, thin product pages, gated content, content without dates/author attribution, PDF-only content.

---

## Schema Markup for AI

| Content Type | Schema | Why It Helps |
|-------------|--------|-------------|
| Articles/Blog posts | `Article`, `BlogPosting` | Author, date, topic identification |
| How-to content | `HowTo` | Step extraction for process queries |
| FAQs | `FAQPage` | Direct Q&A extraction |
| Products | `Product` | Pricing, features, reviews |
| Comparisons | `ItemList` | Structured comparison data |
| Organization | `Organization` | Entity recognition |

Structured data helps AI systems reliably parse entities, pricing, and Q&A, which can improve extractability. The exact visibility impact is not well-quantified and the evidence is mixed, so treat schema as a parsing aid, not a guaranteed visibility multiplier.

---

## Monitoring AI Visibility

### Metrics to Track

| Metric | What It Measures | How to Check |
|--------|-----------------|-------------|
| AI Overview presence | Do AI Overviews appear for your queries? | Manual check or Semrush/Ahrefs |
| Brand citation rate | How often you're cited in AI answers | AI visibility tools |
| Share of AI voice | Your citations vs. competitors | Peec AI, Otterly, ZipTie |
| Citation sentiment | How AI describes your brand | Manual review |
| Source attribution | Which pages get cited | Track referral traffic from AI sources |

### AI Visibility Monitoring Tools

This market moves fast — verify current coverage and pricing before committing.

| Tool | Coverage | Best For |
|------|----------|----------|
| **Profound** | ChatGPT, Perplexity, Google AI Overviews/AI Mode, Gemini, Copilot | Enterprise-scale AI-visibility tracking (current category leader) |
| **Otterly AI** | ChatGPT, Perplexity, Google AI Overviews | Share of AI voice tracking |
| **Peec AI** | ChatGPT, Gemini, Perplexity, Claude, Copilot+ | Multi-platform monitoring at scale |
| **ZipTie** | Google AI Overviews, ChatGPT, Perplexity | Brand mention + sentiment tracking |
| **LLMrefs** | ChatGPT, Perplexity, AI Overviews, Gemini | SEO keyword to AI visibility mapping |

### DIY Monitoring (No Tools)

Monthly manual check:
1. Pick your top 20 queries
2. Run each through ChatGPT, Perplexity, and Google
3. Record: Are you cited? Who is? What page?
4. Log in a spreadsheet, track month-over-month

---

## Common Mistakes

- **Ignoring AI search** — AI Overviews now appear on a large and growing share of Google searches (see Critical stats above)
- **Treating AI SEO as separate from SEO** — Good traditional SEO is the foundation
- **Writing for AI, not humans** — Content must read naturally
- **No freshness signals** — Undated content loses to dated content
- **Gating all content** — AI can't access gated content
- **Ignoring third-party presence** — Wikipedia mentions may matter more than your blog
- **Keyword stuffing** — Actively reduces AI visibility by 10%
- **Blocking AI bots** — Prevents those platforms from citing you
- **Generic content without data** — "We're the best" won't get cited

---

## 2025-2026 AI Search Landscape Updates

The AI search surface is fragmenting. Optimize per platform — not just for "AI" in general. (Landscape as of early 2026 — these facts move quickly; re-verify and re-date this table.)

| Surface | What changed | What to do |
|---|---|---|
| **Google AI Mode** (separate from AI Overviews) | Agentic "query fan-out" SERP launched 2025; distinct ranking signals from classic SERP / Overviews | Check both surfaces; optimize for the implied sub-questions (see "Optimizing for AI Mode" below); favors structured, source-able content |
| **Google AI Overviews** | On a large share of searches (~15-25% in broad global studies, 45-60% in US/curated trackers); appearance volatile | Optimize for citation, not click — measure mentions, not just CTR |
| **ChatGPT Search** (search.chatgpt.com) | Launched late 2024; distinct from ChatGPT-with-browsing. Controlled by OAI-SearchBot in robots.txt | Source-citation behavior differs from Perplexity; track separately |
| **Perplexity Spaces / Shopping** | Product-recommendation surfaces with structured product data | Product schema (Offer, Review, AggregateRating) is now key for product visibility |
| **Apple Intelligence / Gemini-powered Siri** (iOS 26.x, rolling out 2026) | Jan 2026: Apple signed a multi-year deal (reported ~$1B/yr) for a custom Google **Gemini** model to power the rebuilt Siri and Apple Foundation Models; first features in iOS 26.4, fuller conversational Siri expected at iOS 27 (Sept 2026). ChatGPT (GPT-5) remains an optional handoff, not the default | Gemini/Google signals increasingly drive Apple-device AI answers — prioritize the same structured, source-able content that helps in Gemini / AI Overviews. ChatGPT still matters as a secondary handoff |
| **Reddit Answers** | Reddit's own AI answer feature launched 2024 | Reddit presence (genuine, not spam) matters even more |
| **llms.txt** | A community convention (~10% site adoption); **no major AI vendor documents consuming it** — Google's John Mueller likened it to the deprecated keywords meta tag, and crawlers fetch HTML, not llms.txt | Low cost, speculative benefit — publish if trivial (see "llms.txt" below), but do not prioritize it or expect citation impact |
| **Cloudflare "Content Independence Day"** (July 1 2025) | New domains **block all known AI crawlers by default**, plus a "Pay Per Crawl" marketplace for paid access. Cloudflare fronts ~22% of the web, so this is a structural shift in AI crawl access | Audit your CDN/bot settings so you are not blocking the search/citation crawlers you want (OAI-SearchBot, PerplexityBot, Claude-SearchBot) |

**Practical implication:** measure citation share across at least Google AI Mode, AI Overviews, ChatGPT (Search + browsing), Perplexity, and Gemini. A tool like Profound, Peec AI, or Otterly will cover the spread; rolling your own monthly check works for smaller sites.

### Optimizing for Google AI Mode (query fan-out)

AI Mode does not answer your exact query directly — it decomposes it into multiple related sub-questions ("query fan-out"), retrieves passages for each, and synthesizes one answer. Practical implications:

- Optimize for the **sub-questions implied by a topic**, not just the head query. A page that only answers "best CRM" may be skipped in favor of pages that cleanly answer "best CRM for small teams," "CRM with the easiest setup," "CRM pricing compared," etc.
- Cover a topic comprehensively with **self-contained, individually-extractable passages** (one clear answer per heading) so different fan-out sub-questions can each retrieve a relevant chunk.
- Entity clarity and topical authority (see `geo-entity-clarity.md`) matter more here than exact-match keywords, because retrieval is semantic.
- There is no "rank 1" in AI Mode — success is being one of the sourced passages across several sub-questions for a topic.

### llms.txt (how-to, with caveat)

`llms.txt` is a proposed plain-Markdown file at `/llms.txt` that lists your most important URLs (and optionally `/llms-full.txt` with full content) so LLMs can find canonical content. To publish one: place a Markdown file at the site root with an H1 title, a short summary blockquote, and sectioned lists of links with brief descriptions.

**Caveat (important):** as of early 2026 **no major AI vendor has confirmed reading llms.txt**; crawlers fetch your HTML, and Google's John Mueller compared it to the deprecated keywords meta tag. Adoption is ~10%. It is cheap to publish but should be treated as a speculative, low-priority gesture — do not invest heavily or expect a citation lift.
