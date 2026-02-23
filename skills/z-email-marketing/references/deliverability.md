# Email Deliverability

Getting emails into the inbox instead of spam. None of the copy or strategy guidance matters if your emails aren't being delivered.

---

## Why Deliverability Matters

Email providers (Gmail, Outlook, etc.) use sender reputation, authentication, and engagement signals to decide whether your email reaches the inbox, lands in the promotions tab, or goes straight to spam. A sender with bad reputation can have 30-50% of emails silently dropped. Most senders don't realize this is happening because bounce rates only measure hard bounces, not spam filtering.

---

## DNS Authentication

These three records prove to email providers that you're allowed to send email from your domain. Without them, your emails look like they could be spoofed — and inbox providers treat them accordingly.

### SPF (Sender Policy Framework)
- DNS TXT record that lists which servers can send email on behalf of your domain
- Include your email service provider's servers
- Keep it simple — SPF has a 10 DNS lookup limit, and exceeding it silently fails

### DKIM (DomainKeys Identified Mail)
- Cryptographic signature that proves the email wasn't altered in transit
- Your email provider generates the keys; you add the public key as a DNS record
- Always use 2048-bit keys (1024-bit is deprecated)

### DMARC (Domain-based Message Authentication, Reporting & Conformance)
- Policy that tells receiving servers what to do when SPF/DKIM fail
- Start with `p=none` (monitor only), then move to `p=quarantine`, then `p=reject`
- Set up DMARC reporting to see who is sending email using your domain

### Verification Checklist
Most email providers (Customer.io, Resend, SendGrid, etc.) walk you through this during setup. Verify:
- [ ] SPF record includes your sending service
- [ ] DKIM is configured and verified
- [ ] DMARC policy is set (at minimum `p=none` with reporting)
- [ ] Custom return-path / envelope sender domain is configured
- [ ] Test with mail-tester.com or MXToolbox to confirm passing scores

---

## Domain & IP Warm-Up

New sending domains and IPs have no reputation. Email providers are suspicious of senders they haven't seen before. Sending a large volume from a cold domain triggers spam filters.

### Warm-Up Process
1. **Week 1**: Send 50-100 emails/day to your most engaged contacts (people who opened recently)
2. **Week 2**: Double volume, still targeting engaged contacts
3. **Week 3-4**: Gradually increase volume and broaden audience
4. **Week 5+**: Full volume if engagement metrics look healthy

### Warm-Up Rules
- Only send to opted-in, engaged contacts during warm-up
- Monitor bounce rate (<2%), spam complaints (<0.1%), and open rates during each phase
- If metrics dip, slow down — don't push through bad signals
- Use a subdomain for marketing email (e.g., `mail.yourapp.com`) to protect your root domain reputation

---

## List Hygiene

A dirty list tanks deliverability because bounces and spam complaints are the strongest negative signals.

### Regular Maintenance
- **Remove hard bounces immediately** — most providers do this automatically
- **Sunset inactive subscribers** — if someone hasn't opened in 90 days, move to re-engagement sequence. If they still don't engage, remove them.
- **Watch for spam traps** — recycled email addresses that ISPs use to catch senders with bad practices. They never click, never open. Regular list cleaning catches them.
- **Validate emails on signup** — use double opt-in or email validation APIs to prevent typos and fake addresses from entering your list

### Healthy List Indicators
| Signal | Healthy | Warning |
|--------|---------|---------|
| Hard bounce rate | < 0.5% | > 2% |
| Spam complaint rate | < 0.05% | > 0.1% |
| Unsubscribe rate | < 0.3% | > 0.5% |
| List growth rate | Positive | Shrinking |

---

## Spam Trigger Avoidance

Modern spam filters are sophisticated — they look at sender reputation, engagement, and content together. Single words rarely trigger spam on their own, but patterns do.

### Content Patterns to Avoid
- ALL CAPS in subject lines
- Excessive exclamation marks (!!!)
- Image-only emails with no text (spam filters can't read the image)
- URL shorteners (bit.ly, etc.) — they mask destinations and look suspicious
- Large attachments — use links to hosted files instead
- Misleading subject lines ("Re:" or "Fwd:" when it's not a reply)

### Structural Best Practices
- Include a plain-text version alongside HTML
- Include a visible, working unsubscribe link (required by law, and hiding it hurts reputation)
- Include your physical mailing address (CAN-SPAM requirement)
- Keep HTML clean — avoid copy-pasting from Word/Docs which adds hidden markup
- Maintain a healthy text-to-image ratio (at least 60% text)

---

## Monitoring

### Key Deliverability Metrics
| Metric | What it tells you |
|--------|------------------|
| Inbox placement rate | % of emails reaching inbox vs. spam (use tools like GlockApps or Inbox Monster) |
| Bounce rate | Hard = bad addresses, Soft = temporary issues |
| Spam complaint rate | Subscribers marking you as spam (most damaging signal) |
| Engagement rate | Opens + clicks — high engagement improves future deliverability |

### Google Postmaster Tools
Free tool from Google that shows your domain's reputation with Gmail. Monitor:
- Domain reputation (High/Medium/Low/Bad)
- Spam rate
- Authentication success rates
- Delivery errors

If your Gmail reputation drops to "Low" or "Bad", reduce volume immediately and focus on sending only to engaged segments until it recovers.

---

## Cold Email Deliverability

Cold outreach has stricter deliverability challenges because recipients didn't opt in.

- **Use a separate domain** — never send cold email from your main product domain
- **Warm the domain** for 2-3 weeks before any outreach
- **Keep volume low** — 30-50 emails/day per mailbox to start
- **Rotate sending accounts** — spread volume across multiple mailboxes
- **Personalize meaningfully** — identical emails sent to many recipients look like spam to filters
- **Monitor replies and bounces daily** — fast feedback loops prevent domain damage
