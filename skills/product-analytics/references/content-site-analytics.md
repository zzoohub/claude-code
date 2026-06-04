# Content & Marketing-Site Analytics

The frame for a **login-less content or marketing site** — a blog, docs site, or lead-gen site where
most visitors browse anonymously and never sign in. The product-analytics spine (Aha Moment →
retention cohort → Carrying Capacity) does **not** apply: there is no persistent logged-in identity,
no repeat-usage retention curve, and no usage equilibrium to model. Forcing those frameworks
produces noise.

---

## Core Mental Model

One question: **Which content and channels should we double down on, hold, or drop — and is the site
producing qualified leads?**

The spine is a one-way path, not a retention loop:

```
Acquisition  →  Engagement  →  Conversion (the lead)
(where from)    (did they read)   (did they inquire)
```

Leads are a **rare lagging outcome**. Judge day-to-day by the **leading indicators** (acquisition,
engagement, content performance); judge the lagging lead outcome on a longer window (weekly/monthly).

---

## The Four Metric Tiers

### 1. Acquisition — where visitors come from
- Channel mix from referrer + UTM: organic search / direct / social / referral.
- Split organic search by engine — for KO-market sites, **Naver vs Google vs Daum** matters; one
  number hides the gap.
- Landing pages: which URL is the entry point.
- **Search-query detail is NOT in the analytics tool.** Which keyword someone searched lives only in
  Google Search Console + Naver Webmaster Tools. Unregistered search consoles = the single biggest
  acquisition blind spot. (Deeper SEO/AEO/GEO work → search-visibility skill.)

### 2. Engagement — did they actually read
Raw **time-on-page is dishonest** — a bounce logs as 0, biasing the average. Use instead:
- **Engaged time** (active-tab time), not wall-clock.
- **Scroll depth** (25/50/75/100%).
- **Read-completion rate** (reached the end).
- Pages per session (do they go deeper).

### 3. Content performance — which posts earn their keep
- Baseline: pageviews by path.
- Higher-value: **conversion-assisting content** — which posts were read in the session(s) before a
  lead. "High-traffic" and "lead-producing" are different sets; report both.

### 4. Conversion — the one lagging outcome that matters
- The lead / inquiry submit is the North Star event.
- **Intent split must be a client event property.** If the form distinguishes demo vs download
  (inquiry vs asset), the server often only receives name/email — the intent is lost unless captured
  client-side at submit. This is why content/engagement analytics is structurally a client-layer job.

---

## The Attribution Seam (thin, on purpose)

The only thing the site must hand downstream: tag each lead with its **UTM / source / referring
content** so a CRM can later backtrace "this customer came from post X." One line on the lead
payload. Nothing more.

**Explicitly out of scope:** the downstream B2B funnel (MQL → SQL → closed-won), the real product
activation, and any server-side event stitching beyond the seam. Those belong to the CRM / product
project, not the content site. Pulling them in is the most common over-scoping error.

---

## Tooling

| Need | Tool | Note |
|------|------|------|
| Acquisition + engagement + conversion | PostHog web analytics or GA4 | One client snippet covers all three |
| Search queries (the real keywords) | Google Search Console + Naver Webmaster | Not visible to PostHog/GA4 |
| Region / DPA / data-residency | analytics tool config | One-line setting for a mostly-domestic audience — not a strategy section |

---

## Anti-Patterns (do NOT do on a content site)

- Forcing retention cohorts, Aha Moment, Carrying Capacity, PMF, or a customer health score — no
  logged-in identity to compute them on.
- Returning a "Kill/Keep/Scale the product" verdict — the decision here is per **content cluster &
  channel**, not the product.
- Building server-side `client_event_id` stitching "just in case" — demote to optional; a content
  site rarely needs it.
- Importing the B2B downstream funnel stages — out of scope (see seam above).

---

## Decision Output

Instead of Kill/Keep/Scale, deliver:
- **Double down / hold / drop** per content cluster and per acquisition channel, with the engagement
  + conversion-assist evidence.
- **Is qualified-lead volume & quality trending up?** — the single lagging health read, on a
  weekly/monthly window.
