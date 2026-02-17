# Technical SEO Reference

Detailed reference for technical SEO covering crawling, indexing, site architecture, Core Web Vitals, rendering, and AI crawler considerations.

---

## 1. Crawling and Indexing

### How Search Engines Discover Content

Search engines use crawlers (bots) to discover pages by following links and reading sitemaps. A page must be crawled before it can be indexed, and indexed before it can appear in search results.

The process: **Discovery → Crawl → Render → Index → Rank**

### robots.txt

Controls which URLs crawlers can access on your site. Located at `yoursite.com/robots.txt`.

Key rules:
- `User-agent: *` applies to all crawlers
- `Disallow: /path/` blocks crawling of that directory
- `Allow: /path/page` overrides a broader Disallow
- `Sitemap: https://yoursite.com/sitemap.xml` points crawlers to your sitemap

Common mistakes:
- Accidentally blocking CSS/JS files that crawlers need to render pages
- Blocking entire sections of the site without realizing it
- Using robots.txt to try to remove pages from the index (it does not work, use noindex instead)
- Forgetting to update robots.txt after site migrations

### AI Crawler Considerations

AI platforms use their own crawlers. If these are blocked, your content will not appear in AI-generated answers.

| Crawler | Platform | User-Agent |
|---------|----------|------------|
| GPTBot | OpenAI (ChatGPT) | GPTBot |
| Googlebot | Google (including AI Overviews) | Googlebot |
| Google-Extended | Google (Gemini training) | Google-Extended |
| ClaudeBot | Anthropic (Claude) | ClaudeBot |
| PerplexityBot | Perplexity | PerplexityBot |
| Bytespider | ByteDance | Bytespider |
| CCBot | Common Crawl | CCBot |

Important: Blocking Google-Extended blocks Gemini training data but does NOT block AI Overviews (those use Googlebot). Review your robots.txt to confirm you are not unintentionally blocking AI crawlers you want access from.

### XML Sitemaps

A file that lists all URLs you want search engines to index.

Best practices:
- Include only canonical, indexable URLs (200 status, no noindex)
- Keep under 50,000 URLs per sitemap file, under 50MB uncompressed
- Use sitemap index files for large sites
- Include `<lastmod>` dates and keep them accurate (only update when content meaningfully changes)
- Submit via Google Search Console and reference in robots.txt
- Exclude URLs blocked by robots.txt or set to noindex

### Indexation Management

**noindex**: Prevents a page from appearing in search results while still allowing crawling.
- Use `<meta name="robots" content="noindex">` in the HTML head
- Or use the `X-Robots-Tag: noindex` HTTP header
- Use for: thank you pages, internal search results, thin tag/category pages, staging environments

**Canonical tags**: Tell search engines which version of a page is the main one when duplicate or near-duplicate versions exist.
- Use `<link rel="canonical" href="https://yoursite.com/preferred-url">` in the HTML head
- Self-referencing canonicals (a page pointing to itself) are a best practice
- Do not canonical to a completely different page, that is a redirect use case

### Crawl Budget

For large sites (100K+ pages), crawl budget becomes important. Google allocates a finite number of crawls per site per day.

Optimize crawl budget by:
- Ensuring important pages are easily reachable (shallow click depth)
- Removing or noindexing low-value pages (thin content, parameter variations, outdated content)
- Fixing soft 404s and redirect chains
- Keeping server response times fast
- Using internal linking to prioritize important pages
- Monitoring crawl stats in Google Search Console

---

## 2. Site Architecture

### URL Structure Principles

- **Flat but logical**: Important pages should be 2-3 clicks from homepage
- **Consistent hierarchy**: `example.com/category/subcategory/page`
- **Human-readable**: Users should understand the page topic from the URL
- **Hyphens between words**: `example.com/blue-widgets` not `example.com/blue_widgets`
- **Lowercase only**: Avoid mixed case to prevent duplicate URL issues
- **No unnecessary parameters**: Keep URLs clean

### Internal Linking Architecture

Internal links serve three purposes:
1. **Navigation**: Help users find content
2. **Hierarchy**: Signal to search engines which pages are most important
3. **Authority distribution**: Pass link equity from strong pages to pages that need it

Architecture patterns:
- **Pyramid**: Homepage → Category pages → Detail pages (most common)
- **Hub and spoke**: Pillar content → Cluster content (for content-driven sites)
- **Flat**: All pages roughly equal depth (for smaller sites)

Key principles:
- Every important page should be reachable within 3 clicks from homepage
- Use descriptive anchor text (not "click here")
- Link related content to each other (contextual internal links within body content are most valuable)
- Navigation menus, breadcrumbs, and footer links all count
- Identify and fix orphan pages (no internal links pointing to them)

### Faceted Navigation (E-commerce)

Faceted navigation (filters for size, color, price, etc.) can create massive URL bloat.

Handle with:
- `noindex` on low-value filter combinations
- Canonical tags pointing filter pages to the main category
- robots.txt blocking of parameter-heavy URLs
- AJAX-based filtering that does not create new URLs
- Strategic indexing of only the most valuable filter combinations (those with search volume)

### Pagination

For paginated content (category pages, blog archives):
- Use `rel="next"` and `rel="prev"` (Google says they ignore it, but other engines may not)
- Ensure all paginated pages are crawlable and linked
- Consider a "view all" page if the total content is manageable
- Include self-referencing canonical on each paginated page

---

## 3. Rendering

### Server-Side Rendering (SSR) vs Client-Side Rendering (CSR)

| Aspect | SSR | CSR |
|--------|-----|-----|
| How it works | Server generates complete HTML | Browser downloads JS, then renders |
| SEO friendliness | Excellent, crawlers get complete content immediately | Risky, crawlers may not execute JS |
| AI crawler compatibility | High, all crawlers can read HTML | Low, many AI crawlers do not execute JS |
| Initial load speed | Faster first contentful paint | Slower initial load, faster subsequent navigation |

**Recommendation**: Use SSR or pre-rendering for any content you want discoverable by search engines and AI systems. If your site is built with React, Vue, Angular, or similar frameworks, ensure critical content is server-rendered.

### Pre-rendering / Static Site Generation (SSG)

Generate HTML at build time rather than per request. Best of both worlds for content that does not change frequently. Frameworks: Next.js (React), Nuxt (Vue), Astro, Hugo, Gatsby.

### Dynamic Rendering

Serve pre-rendered HTML to crawlers while serving the SPA to users. Google considers this acceptable but not preferred long-term. Useful as a transitional solution.

### Testing Rendering

- Use Google Search Console URL Inspection tool to see how Google renders your pages
- Check "View Source" vs. rendered DOM in browser DevTools
- Test with JavaScript disabled to see what crawlers with limited JS support see

---

## 4. Core Web Vitals

Google page experience metrics. They are ranking signals (though relatively modest compared to content relevance and links).

### LCP (Largest Contentful Paint)
- **What**: Time until the largest visible element (image, video, text block) is rendered
- **Target**: 2.5 seconds or less
- **Common issues**: Large unoptimized images, slow server response, render-blocking resources, client-side rendering delays
- **Fixes**: Optimize and properly size images (WebP/AVIF), use CDN, preload critical resources, implement lazy loading for below-fold images, reduce server response time (TTFB)

### INP (Interaction to Next Paint)
- **What**: Responsiveness to user interactions (clicks, taps, key presses). Replaced FID in March 2024.
- **Target**: 200 milliseconds or less
- **Common issues**: Long JavaScript tasks blocking the main thread, heavy event handlers, excessive DOM size
- **Fixes**: Break up long tasks, defer non-critical JS, reduce DOM size, use web workers for heavy computation, optimize event handlers

### CLS (Cumulative Layout Shift)
- **What**: Visual stability, how much content shifts unexpectedly during loading
- **Target**: 0.1 or less
- **Common issues**: Images/embeds without dimensions, dynamically injected content, web fonts causing FOIT/FOUT, ads resizing
- **Fixes**: Always set width/height on images and videos, reserve space for ads and embeds, use `font-display: swap` with preloaded fonts, avoid injecting content above existing content

### Measuring Core Web Vitals

- **Field data (real users)**: Google Search Console, PageSpeed Insights (CrUX data), web-vitals JavaScript library
- **Lab data (synthetic)**: Lighthouse, WebPageTest, Chrome DevTools Performance panel
- Field data is what Google uses for ranking. Lab data helps diagnose issues.

---

## 5. HTTPS and Security

- HTTPS is a confirmed (minor) ranking signal
- All pages should be served over HTTPS
- Ensure HTTP to HTTPS redirects are in place
- Avoid mixed content (HTTPS page loading HTTP resources)
- Keep SSL certificates valid and up to date

---

## 6. Structured Data (Schema Markup)

### What It Does

Structured data (typically JSON-LD) helps search engines understand the content type and relationships on your pages. It can enable rich results (star ratings, FAQ dropdowns, product info, etc.) in SERPs.

### Implementation Principles

- Use JSON-LD format (Google recommended format)
- Schema must accurately reflect visible page content. Do not add schema for content that is not on the page
- Validate with Google Rich Results Test and Schema Markup Validator
- Do not add schema for rich results you are not eligible for

### Common Schema Types

| Schema Type | Use For | Rich Result |
|-------------|---------|-------------|
| Article | Blog posts, news articles | Article appearance |
| Product | Product pages | Price, availability, reviews |
| FAQ | FAQ sections | Expandable Q&A in SERPs |
| HowTo | Tutorial/guide content | Step-by-step display |
| Organization | Homepage/about page | Knowledge panel, brand info |
| LocalBusiness | Physical business locations | Local pack, business details |
| BreadcrumbList | Site navigation | Breadcrumb trail in SERPs |
| Review | Review content | Star ratings |
| VideoObject | Video content | Video thumbnails in SERPs |
| Speakable | Voice search priority content | Voice assistant eligibility |

### Schema and AEO/GEO Connection

For AEO purposes, FAQPage and HowTo schema directly enable rich results that serve as answer engine features. Speakable schema signals voice-search-ready content.

For GEO purposes, structured data provides machine-readable entity signals that AI systems can cross-reference when determining brand identity and category.

Ensure your schema markup, visible page content, and any external data feeds (e.g., Google Merchant Center) describe the same information consistently.

---

## 7. Site Migration Checklist

When moving to a new domain, redesigning, or restructuring:

1. **Pre-migration**: Crawl and document all existing URLs, rankings, and backlinks
2. **Redirect mapping**: Create 1:1 redirect map from old URLs to new URLs (301 redirects)
3. **Preserve structure**: Maintain URL patterns where possible
4. **Update internal links**: Point to new URLs directly, do not rely solely on redirects
5. **Update sitemaps**: Submit new sitemap, remove old one
6. **Update Search Console**: Verify new property, use Change of Address tool if domain change
7. **Monitor**: Watch for crawl errors, indexation drops, and ranking changes for 3-6 months
8. **Preserve backlinks**: Redirects pass link equity, but reach out to high-value linking sites to update URLs

---

## 8. Common Technical SEO Issues Checklist

- [ ] No accidental noindex on important pages
- [ ] robots.txt not blocking critical resources or AI crawlers
- [ ] XML sitemap submitted and up to date
- [ ] All important pages return 200 status
- [ ] No redirect chains (A to B to C; should be A to C)
- [ ] No redirect loops
- [ ] Canonical tags present and correct
- [ ] No mixed HTTP/HTTPS content
- [ ] Mobile-friendly / responsive design
- [ ] Core Web Vitals passing (LCP 2.5s or less, INP 200ms or less, CLS 0.1 or less)
- [ ] Hreflang implemented correctly (for multi-language sites)
- [ ] Structured data valid and accurate
- [ ] No soft 404s (pages returning 200 but showing error/empty content)
- [ ] Server response time under 200ms (TTFB)
- [ ] Content accessible without JavaScript execution (for AI crawlers)
