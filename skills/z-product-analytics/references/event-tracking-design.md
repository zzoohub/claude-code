# Event Tracking Design

## When to Use This Reference

Use when designing a new tracking plan, adding events for a new feature, auditing existing tracking, or setting up analytics for a new product. This reference covers the naming, structure, and validation of analytics events — not the implementation code (that's a developer task).

---

## Event Naming Convention

Use **Object-Action** format, lowercase with underscores.

```
{object}_{action}
```

**Examples:**
- `signup_completed` (not `user_signed_up` or `signupComplete`)
- `feature_used` (not `used_feature`)
- `purchase_completed` (not `bought` or `purchase`)
- `cta_hero_clicked` (not `button_clicked`)

### Rules

1. **Object first, then action.** This groups related events together when sorted alphabetically.
2. **Past tense for completed actions.** `signup_completed`, `email_sent`, `file_uploaded`.
3. **Present tense for ongoing states.** `page_viewed`, `feature_used`.
4. **Be specific.** Include context in the event name when it clarifies: `cta_hero_clicked` tells you which CTA. `button_clicked` tells you nothing.
5. **Context in properties, not name.** Don't create `signup_email_completed` and `signup_google_completed`. Use `signup_completed` with a `method` property.

### Anti-Patterns

| Bad | Why | Better |
|-----|-----|--------|
| `click` | Too generic | `cta_hero_clicked` |
| `button_clicked` | No context about what button | `checkout_button_clicked` |
| `user_did_thing` | Redundant "user" prefix | `thing_completed` |
| `signupCompleted` | camelCase breaks convention | `signup_completed` |
| `signup-completed` | Hyphens break some tools | `signup_completed` |
| `SIGNUP_COMPLETED` | Uppercase is inconsistent | `signup_completed` |

---

## Essential Events by Context

### Marketing Site

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `page_viewed` | Page load (auto in most tools) | `page_title`, `page_path`, `referrer` |
| `cta_clicked` | Any CTA button click | `cta_location`, `cta_text`, `destination` |
| `form_submitted` | Contact/demo form submit | `form_type`, `source` |
| `signup_started` | Signup flow initiated | `source`, `plan_type` |
| `signup_completed` | Account created | `method` (email/google/github), `source`, `plan_type` |
| `demo_requested` | Demo form submitted | `company_size`, `source` |

### Product / App

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `onboarding_step_completed` | Each onboarding step | `step_number`, `step_name`, `time_since_signup` |
| `onboarding_completed` | All steps done | `total_time`, `steps_skipped` |
| `feature_used` | Core feature interaction | `feature_name`, `context` |
| `aha_moment_reached` | User hits the Aha Moment action | `time_since_signup`, `method` |
| `purchase_completed` | Subscription or payment | `plan_type`, `amount`, `currency`, `interval` |
| `subscription_upgraded` | Plan upgrade | `from_plan`, `to_plan`, `revenue_delta` |
| `subscription_downgraded` | Plan downgrade | `from_plan`, `to_plan`, `revenue_delta` |
| `subscription_cancelled` | Cancellation | `reason`, `plan_type`, `lifetime_days` |
| `invite_sent` | User invites someone | `invite_method`, `recipient_count` |
| `referral_completed` | Referred user signs up | `referrer_id`, `referral_source` |

### Engagement (Product)

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| `search_performed` | In-app search | `query`, `results_count` |
| `export_completed` | Data export | `format`, `record_count` |
| `integration_connected` | Third-party integration | `integration_name` |
| `error_encountered` | User-facing error | `error_type`, `error_message`, `context` |
| `feedback_submitted` | In-app feedback | `feedback_type`, `rating` |

---

## Standard Properties

Properties add context to events without multiplying event names.

### Global Properties (attach to every event)

| Property | Type | Example |
|----------|------|---------|
| `page_title` | string | "Pricing - ProductName" |
| `page_path` | string | "/pricing" |
| `page_referrer` | string | "https://google.com" |

### User Properties (set once, apply to all events)

| Property | Type | Example |
|----------|------|---------|
| `user_id` | string | "usr_abc123" |
| `user_type` | string | "free" / "pro" / "enterprise" |
| `plan_type` | string | "starter" / "pro" / "team" |
| `signup_date` | datetime | "2025-01-15" |
| `company_size` | string | "1-10" / "11-50" / "50+" |

### Campaign Properties (from UTM parameters)

| Property | Type | Example |
|----------|------|---------|
| `utm_source` | string | "twitter" |
| `utm_medium` | string | "social" |
| `utm_campaign` | string | "launch_2025" |
| `utm_content` | string | "hero_cta" |
| `utm_term` | string | "saas_analytics" |

PostHog captures UTMs automatically as `$initial_utm_*` person properties on first visit.

---

## Tracking Plan Template

A tracking plan is the single source of truth for what to track. Store it at `biz/analytics/tracking-plan.md`.

```markdown
# Tracking Plan — [Product Name]

## Aha Moment
- **Definition**: [Action X] within [Y days] of signup, [Z times]
- **Event**: `aha_moment_reached`
- **Status**: Validated / Hypothesis

## Events

### Marketing Site
| Event | Trigger | Properties | Tool |
|-------|---------|------------|------|
| `signup_completed` | Account created | method, source, plan_type | PostHog + GA4 |
| `cta_clicked` | CTA button click | cta_location, cta_text | PostHog |

### Product
| Event | Trigger | Properties | Tool |
|-------|---------|------------|------|
| `onboarding_step_completed` | Step done | step_number, step_name | PostHog |
| `feature_used` | Core action | feature_name | PostHog |

### Revenue
| Event | Trigger | Properties | Tool |
|-------|---------|------------|------|
| `purchase_completed` | Payment success | plan_type, amount, currency | PostHog + GA4 |

## User Properties
| Property | Set When | Example Values |
|----------|----------|----------------|
| plan_type | Signup / upgrade | free, pro, team |

## Funnels to Track
1. Visit → Signup → Aha Moment → D7 Return → Paid
2. Trial Start → Feature Used → Upgrade
```

---

## Validation Checklist

Before shipping tracking:

- [ ] Events fire on correct triggers (test manually)
- [ ] Properties populate with correct types and values
- [ ] No duplicate events (e.g., double-firing on SPA navigation)
- [ ] Works across browsers (Chrome, Safari, Firefox)
- [ ] Works on mobile viewports
- [ ] Conversions recorded correctly in both PostHog and GA4
- [ ] No PII leaking in event properties (emails, names, addresses)
- [ ] Event names follow naming convention (object_action, lowercase, underscores)
- [ ] Tracking plan document is updated with new events
- [ ] Test accounts are filtered out (PostHog internal user filtering)

---

## Common Mistakes

### Tracking Too Much
Every event has a maintenance cost. Start with 10-15 events maximum. You can always add more when a specific analysis demands it. Tracking 200 events from day one means 190 events nobody looks at.

### Tracking Too Little
At minimum, track: signup, Aha Moment action, core feature usage, payment, and cancellation. Without these five, you cannot calculate CC, retention, or activation rate.

### Inconsistent Naming
`userSignedUp`, `signup_completed`, and `sign-up` all mean the same thing. Pick one convention and enforce it. The naming convention in this document (object_action, lowercase, underscores) is the standard.

### Properties as Event Names
Don't create `clicked_hero_cta`, `clicked_footer_cta`, `clicked_sidebar_cta`. Create `cta_clicked` with a `location` property. This keeps the event count manageable and makes analysis easier.

### Not Tracking Time
For onboarding and activation, always include a `time_since_signup` property. Knowing that users who reach the Aha Moment within 3 days retain 2x better than those who take 14 days is critical for Aha Moment parameter sweeping.
