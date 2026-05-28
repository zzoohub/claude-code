# Dunning Playbook

Complete payment recovery strategy for involuntary churn prevention.

---

## The Dunning Stack

```
Pre-dunning → Smart retry → Dunning emails → Grace period → Hard cancel
```

Failed payments cause 30-50% of all churn but are the most recoverable.

---

## Pre-Dunning (Prevent Failures)

- **Card expiry alerts**: Email 30, 15, and 7 days before card expires
- **Backup payment method**: Prompt for a second payment method at signup
- **Network tokens** (Visa Token Service, Mastercard MDES, Amex tokenization): Visa/Mastercard now provision network tokens that auto-update on card-on-file when the underlying PAN changes (replaces the older "Account Updater" batch programs). Stripe, Braintree, Adyen, Checkout.com all wire this in by default. Reduces hard declines 20-40%.
- **Pre-billing notification**: Email 3-5 days before charge for annual plans

---

## Smart Retry Logic

Not all failures are the same:

| Decline Type | Examples | Retry Strategy |
|-------------|----------|----------------|
| Soft decline (temporary) | Insufficient funds, processor timeout | ML-driven retry (Stripe Adaptive Acceptance, Adyen Revenue Boost) or static 3-5 retries over 7-10 days |
| Hard decline (permanent) | Card stolen, account closed | Don't retry — ask for new card |
| Authentication required (SCA) | 3D Secure 2 challenge required | Send customer to update payment via authenticated flow — automatic retries fail without consumer challenge |

### Retry Timing — Prefer ML over Static Schedule

Static schedule (acceptable fallback):
- Retry 1: 24 hours after failure
- Retry 2: 3 days after failure
- Retry 3: 5 days after failure
- Retry 4: 7 days after failure (with dunning email escalation)
- After 4 retries: Hard cancel with reactivation path

**ML-driven retry (preferred for >$10k MRR):** Stripe Smart Retries (within Stripe Billing), Stripe Adaptive Acceptance (across Stripe), Adyen Revenue Boost, or churn-recovery tools (Churnkey, Recover, Stunning) pick retry timing per card / per issuer / per failure code. Lifts recovery 10-30% over static schedules in industry benchmarks.

### SCA / 3DS notes (mandatory in EU/UK since 2021)

- Failed retries on SCA-required transactions don't recover without explicit consumer authentication
- Send the customer to an authenticated card-update flow (Stripe's Payment Element / Checkout handles this automatically)
- Excluding low-value or recurring exemptions is provider-specific — verify with your billing provider

---

## Dunning Email Sequence

| Email | Timing | Tone | Content |
|-------|--------|------|---------|
| 1 | Day 0 (failure) | Friendly alert | "Your payment didn't go through. Update your card." |
| 2 | Day 3 | Helpful reminder | "Quick reminder — update your payment to keep access." |
| 3 | Day 7 | Urgency | "Your account will be paused in 3 days. Update now." |
| 4 | Day 10 | Final warning | "Last chance to keep your account active." |

### Email Best Practices
- Direct link to payment update page (no login required if possible)
- Show what they'll lose (their data, their team's access)
- Don't blame ("your payment failed" not "you failed to pay")
- Include support contact for help
- Plain text performs better than designed emails for dunning

---

## Recovery Benchmarks

| Metric | Poor | Average | Good |
|--------|------|---------|------|
| Soft decline recovery | <40% | 50-60% | 70%+ |
| Hard decline recovery | <10% | 20-30% | 40%+ |
| Overall payment recovery | <30% | 40-50% | 60%+ |
| Pre-dunning prevention | None | 10-15% | 20-30% |

---

## Billing Provider Capabilities

| Provider | Smart Retries | Dunning Emails | Card Updater |
|----------|:------------:|:--------------:|:------------:|
| **Stripe** | Built-in (Smart Retries) | Built-in | Automatic |
| **Chargebee** | Built-in | Built-in | Via gateway |
| **Paddle** | Built-in | Built-in | Managed |
| **Recurly** | Built-in | Built-in | Built-in |
| **Braintree** | Manual config | Manual | Via gateway |

---

## Tool Integrations

| Tool | Use For |
|------|---------|
| Stripe | Subscription management, dunning config, payment retries |
| Customer.io | Dunning email sequences, retention campaigns |
| Churnkey | Full cancel flow + dunning, AI-powered adaptive offers |
| ProsperStack | Cancel flows with analytics, Stripe/Chargebee integration |
| Raaft | Simple cancel flow builder |
