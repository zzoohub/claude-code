# Aha Moment Discovery

## Definition

The Aha Moment is the single action (or set of actions) that predicts long-term retention:

> **"[Action X] within [Y days] of signup, [Z times]"**

Examples from well-known products:
- **Facebook**: 7 friends in 10 days
- **Twitter**: Follow 30 people
- **Slack**: Team sends 2,000 messages
- **Dropbox**: File saved on multiple devices
- **Stripe**: Use 3+ products in first 30 days (95% 12-month retention vs 65%)

The Aha Moment defines the entire product strategy. Once found, the company's single goal becomes: get more users to complete X within Y days, Z times.

---

## Discovery Process

### Step 1: Identify Power Users

Create a segment of your most retained, most active users. These are users who:
- Have been active for 30+ days
- Use the product regularly (weekly or more)
- Would be "very disappointed" if the product disappeared (Sean Ellis test)

### Step 2: Identify Candidate Actions

List 5-10 actions that represent core value delivery. Focus on:
- Actions that reflect the product's core value proposition
- Actions that require meaningful engagement (not vanity actions like "viewed dashboard")
- Actions that happen relatively early in the user journey

**Good candidates**: Created first project, invited a team member, completed first workflow, exported first report, connected first integration
**Bad candidates**: Viewed settings page, clicked help, updated profile photo

### Step 3: Correlation Analysis

For each candidate action, segment ALL users into 4 groups:

```
             | Retained (D30+) | Not Retained
-------------|-----------------|-------------
Did Action   |    A            |    C
Didn't Do    |    B            |    D
```

Calculate two metrics:

**Retention Predictive Value (RPV)**:
```
RPV = A / (A + B)
```
RPV answers: "Of all retained users, what percentage did this action?"
Target: RPV > 95% (nearly all retained users did this action)

**Intersection (Precision)**:
```
Intersection = A / (A + B + C)
```
Intersection answers: "Of everyone who retained OR did the action, how many did both?"
Maximize this — it balances false positives (C: did action but churned) with coverage.

### Step 4: Sweep Parameters

For each promising candidate (RPV > 80%), sweep:
- **Frequency (Z)**: How many times? (1, 2, 3, 5, 10...)
- **Time window (Y)**: Within how many days? (1, 3, 7, 14, 30...)

Plot Intersection across these combinations. The sweet spot is where Intersection peaks — the specific frequency within the specific time window.

### Step 5: Validate

**Correlation ≠ causation.** Validate with:
1. **A/B test**: Design an onboarding flow that pushes users toward the candidate action. Compare retention vs control.
2. **Qualitative check**: Interview retained users. Do they describe the candidate action as the moment they "got it"?
3. **Segment check**: Does the Aha Moment hold across different user segments (by acquisition channel, persona, geography)?

If the A/B test shows improved retention, you've found your Aha Moment. If not, the action may be a symptom of engaged users, not a cause of engagement.

---

## Common Pitfalls

### Confusing Correlation with Causation
Power users do many things. Not all of those things cause retention. A retained user might also view settings frequently — that doesn't make "view settings" an Aha Moment.

### Vanity Actions
"Completed onboarding tutorial" often has high RPV but low causal power. Users complete it because the product forces them to, not because it delivers value.

### Ignoring Segments
Different personas may have different Aha Moments. A collaboration tool's Aha Moment might be "shared a file" for team leads but "received a notification" for individual contributors. Analyze segments separately.

### Optimizing for Speed Over Accuracy
The Aha Moment defines your entire product strategy. Spend the time to validate properly. A wrong Aha Moment leads to optimizing the wrong thing.

### Not Revisiting
Products evolve. The Aha Moment for a v1 product may differ from v3. Revisit quarterly or after major feature launches.

---

## Activation Rate

Once the Aha Moment is identified, track:

```
Activation Rate = Users who reach Aha Moment / Total signups
```

And the time dimension:

```
Time to Aha Moment = Median time from signup to Aha Moment completion
```

Both should be tracked by cohort, by segment, and over time. Improvements to onboarding should show:
- Rising activation rate
- Declining time to Aha Moment

---

## Implementation in PostHog

All Aha Moment discovery is executed via PostHog MCP server:

| Step | PostHog Feature | How |
|------|----------------|-----|
| Identify power users | **Cohort** | Create cohort: retained D30+ users |
| List candidate actions | **Paths** | Compare paths of retained vs churned |
| Correlation analysis | **Correlation Analysis** | Automates RPV calculation across events |
| Behavioral cohorts | **Cohort** | Create cohort per candidate action (e.g., "completed_import in first 3 days") |
| Retention comparison | **Retention** insight | Compare retention curves: did-action vs didn't |
| Parameter sweeping | **HogQL** | Custom SQL for frequency×timewindow matrix when UI doesn't support it |
| Lifecycle tracking | **Lifecycle** view | Monitor new/returning/resurrecting/dormant after activation changes |
| A/B validation | **Experiments** | Test causal effect of nudging users toward Aha Moment |
