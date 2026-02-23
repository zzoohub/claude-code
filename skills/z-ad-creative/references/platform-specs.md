# Ad Platform Specs & Format Variations

Detailed character limits, image dimensions, and format variations for each ad platform.

---

## Google Ads

### Responsive Search Ads (RSAs)

| Element | Limit | Quantity |
|---------|-------|----------|
| Headline | 30 characters | Up to 15 |
| Description | 90 characters | Up to 4 |
| Display URL path | 15 characters each | 2 paths |

**RSA rules:**
- Headlines must make sense independently and in any combination
- Pin headlines to positions only when necessary (reduces optimization)
- Include at least: 1 keyword-focused, 1 benefit-focused, 1 CTA headline
- Use all 15 headline slots for maximum testing
- Vary lengths — mix short (15-20 chars) and full (28-30 chars)

### Performance Max

| Element | Limit |
|---------|-------|
| Short headline | 30 characters (up to 5) |
| Long headline | 90 characters (up to 5) |
| Description | 90 characters (up to 5) |
| Business name | 25 characters |
| CTA | Auto or selected from list |

**Image specs:**

| Placement | Dimensions | Ratio |
|-----------|-----------|-------|
| Landscape | 1200×628 | 1.91:1 |
| Square | 1200×1200 | 1:1 |
| Portrait | 960×1200 | 4:5 |
| Logo (landscape) | 1200×300 | 4:1 |
| Logo (square) | 1200×1200 | 1:1 |

**Video specs:** 10 seconds minimum, horizontal or vertical

### Display Ads

| Size | Dimensions | Placement |
|------|-----------|-----------|
| Medium Rectangle | 300×250 | Most common, inline |
| Leaderboard | 728×90 | Top of page |
| Wide Skyscraper | 160×600 | Sidebar |
| Large Rectangle | 336×280 | Inline content |
| Billboard | 970×250 | Premium top placement |
| Mobile Banner | 320×50 | Mobile sites |
| Mobile Interstitial | 320×480 | Full-screen mobile |

---

## Meta Ads (Facebook/Instagram)

### Feed Ads

| Element | Limit | Notes |
|---------|-------|-------|
| Primary text | 125 chars visible (2,200 max) | Front-load hook |
| Headline | 40 chars recommended (255 max) | Below image |
| Description | 30 chars recommended (2,200 max) | Below headline, not always shown |
| URL display link | 40 characters | Optional custom |

**Image specs:**

| Placement | Dimensions | Ratio |
|-----------|-----------|-------|
| Feed (square) | 1080×1080 | 1:1 |
| Feed (landscape) | 1200×628 | 1.91:1 |
| Feed (portrait) | 1080×1350 | 4:5 |
| Stories/Reels | 1080×1920 | 9:16 |
| Carousel card | 1080×1080 | 1:1 |
| Right column | 1200×628 | 1.91:1 |

**Video specs:**

| Placement | Ratio | Length |
|-----------|-------|--------|
| Feed | 1:1 or 4:5 | Up to 240 min (15s recommended) |
| Stories | 9:16 | Up to 120 seconds |
| Reels | 9:16 | Up to 90 seconds |
| In-stream | 16:9 | 5-15 seconds |

### Carousel Ads
- 2-10 cards per carousel
- Each card: 1080×1080 (1:1)
- Each card has its own headline, description, URL
- Consistent visual style across cards

### Audience Network
Same specs as Feed, but test separately — performance varies significantly.

---

## LinkedIn Ads

### Sponsored Content (Single Image)

| Element | Recommended | Max |
|---------|-------------|-----|
| Intro text | 150 chars | 600 chars |
| Headline | 70 chars | 200 chars |
| Description | 100 chars | 300 chars |

**Image specs:**

| Format | Dimensions | Ratio |
|--------|-----------|-------|
| Single image | 1200×627 | 1.91:1 |
| Carousel card | 1080×1080 | 1:1 |
| Video | 1920×1080 or 1080×1920 | 16:9 or 9:16 |

### Sponsored Messaging (InMail)

| Element | Limit |
|---------|-------|
| Subject line | 60 characters |
| Message body | 1,500 characters |
| CTA button text | 20 characters |
| Banner image | 300×250 |

### Text Ads

| Element | Limit |
|---------|-------|
| Headline | 25 characters |
| Description | 75 characters |
| Image | 100×100 |

### Document Ads
- Upload PDF, DOC, or PPT
- Intro text: 600 chars max
- Headline: 200 chars max
- Documents can be gated (lead gen) or ungated

---

## TikTok Ads

### In-Feed Ads

| Element | Limit | Notes |
|---------|-------|-------|
| Ad text | 80 chars recommended (100 max) | Above video |
| Display name | 40 characters | Brand name |

**Video specs:**

| Spec | Requirement |
|------|------------|
| Aspect ratio | 9:16, 1:1, or 16:9 |
| Resolution | 720×1280 minimum (1080×1920 recommended) |
| Duration | 5-60 seconds (15-30 recommended) |
| File size | Up to 500MB |
| Format | MP4, MOV, AVI |

### TopView Ads
- Full-screen, sound-on, up to 60 seconds
- First ad users see when opening TikTok
- Premium placement, high CPM

### Spark Ads
- Boost organic TikTok posts as ads
- Same specs as organic content
- Engagement counts toward organic post metrics

---

## Twitter/X Ads

### Promoted Tweets

| Element | Limit | Notes |
|---------|-------|-------|
| Tweet text | 280 characters | The ad copy |
| Card headline | 70 characters | Below media |
| Card description | 200 characters | Below headline |

**Image specs:**

| Format | Dimensions | Ratio |
|--------|-----------|-------|
| Single image | 1200×675 | 16:9 |
| Card image | 800×418 | 1.91:1 |
| Carousel card | 800×800 | 1:1 |

**Video specs:**
- Aspect ratio: 16:9 or 1:1
- Duration: Up to 2:20 (15-30s recommended)
- File size: Up to 1GB

---

## Character Count Best Practices

### General Rules
- **Never exceed hard limits** — platforms truncate without warning
- **Target recommended lengths** — not max lengths
- **Front-load key message** — visible portion matters most
- **Count carefully** — spaces, punctuation, and emojis all count
- **Test on mobile** — most users see ads on phones

### Character Counting Tips
- Emojis count as 2 characters on most platforms
- URLs in Meta ads don't count toward primary text limit
- Google Ads counts display URL paths separately from headlines
- LinkedIn truncates intro text at ~150 chars on mobile

### Platform-Specific Nuances

| Platform | Nuance |
|----------|--------|
| Google | Headlines can appear in any order — each must stand alone |
| Meta | First 125 chars of primary text are critical — rest hidden behind "See more" |
| LinkedIn | Desktop shows more text than mobile — optimize for mobile length |
| TikTok | Text overlay on video matters more than caption text |
| Twitter/X | Thread ads auto-expand — first tweet is the hook |

---

## Quick Reference Card

| Platform | Primary Text | Headline | Description | Image (Main) |
|----------|-------------|----------|-------------|-------------|
| Google RSA | — | 30 chars | 90 chars | — |
| Google PMax | — | 30/90 chars | 90 chars | 1200×628 |
| Meta Feed | 125 chars* | 40 chars | 30 chars | 1080×1080 |
| Meta Stories | 125 chars* | 40 chars | — | 1080×1920 |
| LinkedIn | 150 chars* | 70 chars | 100 chars | 1200×627 |
| TikTok | 80 chars | — | — | 1080×1920 |
| Twitter/X | 280 chars | 70 chars | 200 chars | 1200×675 |

*Recommended visible length; max is higher.

---

## Performance Benchmarks (2025-2026)

### Meta (Facebook/Instagram)

| Metric | Average | Good | Top Quartile |
|--------|---------|------|-------------|
| CTR (Feed) | 1.4-1.7% | 2.0%+ | 3.0%+ |
| CPC (Traffic) | $0.70-0.80 | <$0.60 | <$0.40 |
| CPC (Lead Gen) | $1.90-2.10 | <$1.50 | <$1.00 |
| CPL (Lead Ads) | $27.66 | <$20 | <$12 |
| Lead Ad CVR | 7.72% | 10%+ | 15%+ |
| Hook Rate (video) | 20-25% | 25-30% | 30%+ |

**Key 2025-2026 insights**:
- 70-80% of ad performance is creative quality (AppsFlyer report)
- 4:5 vertical outperforms 1:1 by ~15% in Feed
- Poster videos (still + short clips) lift watch time by ~18%
- 60%+ of user time on FB/IG is spent watching video
- Andromeda algorithm update: creative diversity > creative volume
- Advantage+ Shopping Campaigns use AI to auto-optimize creative delivery

### TikTok

| Metric | Average | Good | Top Quartile |
|--------|---------|------|-------------|
| Hook Rate | 25-30% | 30-40% | 40%+ |
| Hold Rate (6s) | 15-20% | 25-30% | 35%+ |
| CTR | 0.5-1.0% | 1.0-2.0% | 2.0%+ |

**Key 2025-2026 insights**:
- UGC outperforms non-UGC by +55% ROI
- Unbranded UGC +19% better than branded UGC
- Content without logos: +81% ROI vs branded content
- 90% of ad recall happens in first 6 seconds
- Refresh creative every 7 days (TikTok recommendation)
- Test 10-20 creative variations per campaign

### Google Ads

**Key 2025-2026 insights**:
- PMax with video-enabled asset groups: 25-40% better performance
- Asset Studio (genAI tools) now free for all advertisers
- Brand guidelines let you control colors/fonts for AI-generated ads
- Asset-level reporting now shows impressions, clicks, cost (not just conversions)
- Replace low-rated assets every 4-6 weeks

### LinkedIn

| Metric | Average | Good | Top Quartile |
|--------|---------|------|-------------|
| CTR (Sponsored) | 0.4-0.6% | 0.7-1.0% | 1.0%+ |
| CPC | $5-8 | $3-5 | <$3 |
| CPL | $50-80 | $30-50 | <$30 |

**Key 2025-2026 insights**:
- Thought Leader Ads: 1.7x higher CTR, 1.6x more engagement
- B2B creator content outperforms brand content
- Algorithm weights meaningful interactions (comments > likes)
- Refresh every 4-6 weeks; narrow B2B audiences fatigue faster

---

## Platform Creative Philosophy (2025-2026)

Each platform has a different content culture. Ads that match it outperform.

| Platform | Culture | Creative That Wins | Creative That Loses |
|----------|---------|-------------------|-------------------|
| **Meta** | Social sharing, discovery | UGC, native video, carousel stories | Corporate stock photos, text-heavy images |
| **TikTok** | Raw, authentic, entertainment | Phone-shot UGC, trending sounds, lo-fi | Polished brand videos, static images |
| **Google** | Intent-driven search | Keyword-match headlines, specific benefits | Vague claims, brand-first messaging |
| **LinkedIn** | Professional insight | Thought leadership, data-driven content | Hard sell, consumer-style creative |
| **Display** | Quick impression | Bold visuals, minimal text, clear CTA | Cluttered designs, multiple messages |
