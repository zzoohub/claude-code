# GA4 & GTM Setup Guide

## When to Use This Reference

Use when setting up Google Analytics 4 and/or Google Tag Manager for a new product, migrating from UA to GA4, or auditing an existing GA4 setup. For PostHog-first stacks, GA4 is optional — use it primarily for SEO attribution and Google Ads integration where PostHog falls short.

---

## GA4 vs PostHog: When to Use Which

| Need | Use GA4 | Use PostHog |
|------|---------|-------------|
| Google Ads attribution | Yes | No (no native integration) |
| SEO traffic analysis | Yes (Search Console integration) | Partial |
| Product analytics (retention, funnels) | No | Yes |
| Session replay | No | Yes |
| Feature flags / experiments | No | Yes |
| Privacy-first (EU, no cookie banner) | No | Yes (cookieless mode) |

For solopreneur SaaS: **PostHog is the primary analytics tool.** GA4 supplements it for acquisition channel attribution and Google ecosystem integration.

---

## GA4 Setup

### Step 1: Create GA4 Property

1. Go to [analytics.google.com](https://analytics.google.com)
2. Admin > Create Property
3. Set property name, timezone, currency
4. Choose "Web" as platform
5. Enter site URL and stream name
6. Copy **Measurement ID** (G-XXXXXXXXXX)

### Step 2: Install on Site

**Option A: Direct gtag.js (simplest)**

```html
<!-- In <head> -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

**Option B: Via GTM (recommended if using GTM)**

See GTM Setup section below. Add GA4 Configuration tag in GTM instead.

**Option C: Next.js / React SPA**

```tsx
// app/layout.tsx (Next.js App Router)
import Script from 'next/script'

export default function RootLayout({ children }) {
  return (
    <html>
      <head>
        <Script
          src={`https://www.googletagmanager.com/gtag/js?id=${process.env.NEXT_PUBLIC_GA4_ID}`}
          strategy="afterInteractive"
        />
        <Script id="ga4-init" strategy="afterInteractive">
          {`
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '${process.env.NEXT_PUBLIC_GA4_ID}');
          `}
        </Script>
      </head>
      <body>{children}</body>
    </html>
  )
}
```

For SPAs, track page views on route change:
```ts
// utils/analytics.ts
export function trackPageView(url: string) {
  if (typeof window.gtag === 'function') {
    window.gtag('config', process.env.NEXT_PUBLIC_GA4_ID!, {
      page_path: url,
    });
  }
}
```

### Step 3: Enable Enhanced Measurement

GA4 Admin > Data Streams > Select stream > Enhanced measurement. Enable:
- Page views (on by default)
- Scrolls (90% depth)
- Outbound clicks
- Site search
- Form interactions
- File downloads

These are free and automatic — no code needed.

### Step 4: Configure Custom Events

GA4 has three event tiers:

| Tier | Examples | Setup |
|------|---------|-------|
| **Automatically collected** | `page_view`, `first_visit`, `session_start` | None |
| **Enhanced measurement** | `scroll`, `click`, `file_download` | Toggle in admin |
| **Custom events** | `signup_completed`, `purchase_completed` | Code or GTM |

Custom event implementation:
```js
// Send custom event
gtag('event', 'signup_completed', {
  method: 'email',        // how they signed up
  source: 'hero_cta',     // which CTA
});

// Purchase event (ecommerce)
gtag('event', 'purchase', {
  transaction_id: 'T_12345',
  value: 29.99,
  currency: 'USD',
  items: [{
    item_id: 'plan_pro',
    item_name: 'Pro Plan',
    price: 29.99,
  }]
});
```

### Step 5: Mark Conversions

GA4 Admin > Events > Toggle "Mark as conversion" for key events:
- `signup_completed`
- `purchase` (or `purchase_completed`)
- `demo_requested`

This enables conversion tracking in Google Ads (if running ads) and surfaces these in GA4 reports.

### Step 6: Link Google Search Console

GA4 Admin > Product links > Search Console. This gives you:
- Which search queries drive traffic
- Landing page performance by query
- Click-through rates from search

Essential for SEO tracking that PostHog cannot provide.

---

## GTM Setup

Google Tag Manager is a container that manages all your tracking scripts (GA4, PostHog, Meta Pixel, etc.) without code changes.

### When to Use GTM

- Running multiple tracking tools (GA4 + PostHog + ad pixels)
- Non-technical team needs to add/modify tracking
- Want to manage consent/cookie banners centrally
- Complex event tracking that changes frequently

### When NOT to Use GTM

- PostHog-only stack with no ad pixels
- Simple setup with just GA4 + PostHog installed via code
- Performance-critical pages where every script matters

### GTM Installation

1. Create account at [tagmanager.google.com](https://tagmanager.google.com)
2. Create container (Web)
3. Install the two snippets:

```html
<!-- As high in <head> as possible -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-XXXXXXX');</script>

<!-- Immediately after opening <body> -->
<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-XXXXXXX"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
```

### GTM + GA4 Configuration

**Tag 1: GA4 Configuration**
- Tag type: Google Analytics: GA4 Configuration
- Measurement ID: G-XXXXXXXXXX
- Trigger: All Pages

**Tag 2: Custom Events**
- Tag type: Google Analytics: GA4 Event
- Configuration tag: (select your GA4 config tag)
- Event name: `signup_completed`
- Trigger: Custom Event (when dataLayer event = `signup_completed`)

Push events from code to dataLayer:
```js
window.dataLayer.push({
  event: 'signup_completed',
  method: 'email',
  source: 'hero_cta'
});
```

### GTM + PostHog

Add PostHog via GTM custom HTML tag:
```html
<script>
  !function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.async=!0,p.src=s.api_host+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="init capture register register_once registerForSession unregister unregisterForSession opt_out_capturing has_opted_out_capturing opt_in_capturing reset isFeatureEnabled onFeatureFlags onSessionId getDistinctId getSessionId alias set_config startSessionRecording stopSessionRecording sessionRecordingStarted getFeatureFlag getFeatureFlagPayload reloadFeatureFlags group updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures getActiveMatchingSurveys getSurveys onSurveys".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);
  posthog.init('YOUR_PROJECT_API_KEY', {api_host: 'https://us.i.posthog.com'});
</script>
```
- Trigger: All Pages
- Tag firing priority: Set higher than GA4 if PostHog is primary

---

## UTM Parameter Strategy

UTM parameters are the bridge between marketing efforts and analytics. They work in both GA4 and PostHog.

### UTM Parameter Definitions

| Parameter | Purpose | Example |
|-----------|---------|---------|
| `utm_source` | Where traffic comes from | `twitter`, `newsletter`, `google` |
| `utm_medium` | Marketing medium | `social`, `email`, `cpc`, `organic` |
| `utm_campaign` | Campaign name | `launch_2025`, `black_friday` |
| `utm_content` | Differentiates creative/links | `hero_cta`, `footer_link`, `variant_b` |
| `utm_term` | Paid search keywords | `saas_analytics`, `product_tool` |

### Naming Conventions

- All lowercase: `twitter` not `Twitter`
- Underscores for spaces: `black_friday` not `black-friday` or `black friday`
- Be specific: `blog_footer_cta` not `cta1`
- Consistent across team: document all UTMs in tracking plan

### UTM Templates by Channel

```
# Social media posts
?utm_source=twitter&utm_medium=social&utm_campaign={campaign}&utm_content={post_topic}

# Email campaigns
?utm_source=newsletter&utm_medium=email&utm_campaign={campaign}&utm_content={section}

# Paid search
?utm_source=google&utm_medium=cpc&utm_campaign={campaign}&utm_term={keyword}

# Partner/guest posts
?utm_source={partner_name}&utm_medium=referral&utm_campaign={campaign}

# Product Hunt
?utm_source=producthunt&utm_medium=referral&utm_campaign=launch_2025
```

### UTM in PostHog

PostHog automatically captures UTM parameters as person properties:
- `$initial_utm_source`, `$initial_utm_medium`, etc. (first touch)
- Available for segmentation in retention, funnels, and cohorts

Use these to segment retention by acquisition channel — organic users almost always retain better than paid.

---

## Validation Checklist

After setup, verify everything works:

- [ ] GA4 Realtime report shows your visits
- [ ] Enhanced measurement events appear in GA4 Events report
- [ ] Custom events fire on correct triggers (use GA4 DebugView)
- [ ] Conversions are marked and recording
- [ ] Search Console is linked and showing data
- [ ] UTM parameters are captured correctly (check GA4 Traffic acquisition report)
- [ ] GTM Preview mode shows tags firing correctly (if using GTM)
- [ ] PostHog and GA4 are not double-counting (compare session counts)
- [ ] No PII leaking in event parameters (check for emails, names in custom dimensions)
- [ ] Cookie consent banner works correctly with GTM consent mode (if required)

---

## GA4 + PostHog Dual Setup Tips

Running both tools means double the tracking code but not double the work. Keep it clean:

1. **GA4 for acquisition, PostHog for product.** Don't try to replicate product analytics in GA4 — its retention and funnel tools are inferior to PostHog.
2. **Share event names.** Use the same event naming convention (object_action, lowercase, underscores) in both tools for consistency.
3. **UTMs bridge the gap.** GA4 captures UTM attribution automatically. PostHog captures initial UTMs as person properties. Together they give you full-funnel attribution.
4. **Don't duplicate funnels.** Build acquisition funnels (visit → signup) in GA4. Build product funnels (signup → Aha Moment → retention) in PostHog.
5. **GA4 for Google Ads only.** If you're not running Google Ads, GA4's main value is Search Console integration. Consider whether that alone justifies the setup.
