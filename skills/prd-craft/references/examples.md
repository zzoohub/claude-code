# PRD Section Examples

Concrete examples of what "good" and "bad" look like for each PRD section.
Reference this when writing a PRD to calibrate quality and depth.

---

## Section 1: Problem / Opportunity

**Good:**

> "28% of new users abandon onboarding at the payment step (analytics, Jan-Mar
> 2025). User interviews (n=15) reveal the primary friction: users don't trust
> entering card details before experiencing the product. Competitors (Notion,
> Linear) offer 14-day free trials with no payment required. Our current
> 'pay first' model costs us an estimated $340K/month in lost conversions.
>
> **Why Now:** Notion launched a free tier in Q4 2024, and our competitor
> analysis shows a 15% increase in users citing 'free trial availability' as
> their primary reason for choosing alternatives. Support tickets about pricing
> have doubled since January. Our payment infrastructure upgrade (completed
> last month) now makes trial billing technically feasible for the first time."

**Bad:**

> "Users don't like paying upfront. We should add a free trial to improve
> conversions."
>
> (No numbers. No evidence. Solution stated as fact. No "why now.")

---

## Section 2: Target Users

**Good:**

> **Primary persona: Team Lead (Sarah)**
> Mid-level manager at a 50-200 person company. Manages 5-12 direct reports.
> Spends ~4 hours/week on performance tracking using spreadsheets and email.
> Pain: No single view of team progress; context-switching between 3-4 tools.
>
> **Use case 1: Weekly team check-in** (highest priority)
> Current journey: Opens spreadsheet → cross-references Jira → writes individual
> Slack messages → logs notes in Google Doc.
> What's broken: Takes 45 minutes; information is stale by the time she finishes.
>
> **JTBD:** "When I'm preparing for my weekly 1:1s, I want to see each
> person's recent work and blockers in one place, so I can have focused
> conversations instead of status updates."

**Bad:**

> "Target users: managers. Use case: manage their teams better."
>
> (No specificity. No pain point. No current journey. "Better" means nothing.)

---

## Section 3: Proposed Solution

**Good:**

> **Elevator pitch:** A unified team dashboard that pulls work status from
> existing tools (project management, git, communication) and surfaces what
> matters for each team member — without requiring anyone to manually update
> status.
>
> **Value propositions:**
> 1. See each person's week at a glance → solves the 45-minute prep problem (Section 2)
> 2. Auto-detects blockers from tool signals → no more "any blockers?" in standup (Section 2)
> 3. Trends over time surface coaching opportunities → replaces quarterly scramble (Section 2)
>
> **Mental model:** Think of it as a "team health dashboard" — like a fitness
> tracker, but for your team's work. It observes passively and highlights what
> needs attention.

**Bad:**

> "We will build a React dashboard using GraphQL to aggregate data from
> multiple APIs with real-time WebSocket updates."
>
> (This is a technical spec. Names specific technologies. Doesn't describe the
> user experience or connect to problems.)

---

## Section 4: Success Metrics

**Good:**

> | Goal | Metric | Counter-metric | Target | Timeframe |
> |------|--------|----------------|--------|-----------|
> | Reduce 1:1 prep time | Avg prep minutes/week | Manager satisfaction score | 45min→15min | 3 months |
> | Improve blocker detection | Avg hours-to-resolution | False positive rate | 48h→12h | 6 months |
> | Increase team engagement | Weekly active managers | Feature adoption breadth | 40%→70% | 6 months |

**Bad:**

> "Goals: Improve manager productivity. Increase engagement. Make teams happier."
>
> (No metrics. No targets. No timeframe. Not measurable. "Happier" is not a KPI.)

---

## Section 7: Scope & Non-Goals

**Good:**

> **In scope:**
> - Dashboard for engineering and product team leads
> - Integrations: Jira, GitHub, Linear, Slack
> - Individual and team-level views
> - Automated blocker detection
>
> **Out of scope:**
> - Performance review workflows (adjacent problem, would require separate discovery and different buyer persona — HR)
> - HR-facing analytics (different user with different privacy requirements; revisit after core PMF)
> - Custom integrations / API (premature until core value validated; Phase 2 candidate)
> - Mobile app (web-first; mobile usage data will inform whether to build native vs responsive)

**Bad:**

> "Out of scope: things we're not building."
>
> (Says nothing. The purpose is to name specific temptations and explain why
> you're deliberately not pursuing them.)

---

## Section 8: Assumptions, Constraints & Risks

**Good:**

> **Assumptions:**
> - Team leads will connect at least one project management tool within the
>   first session (based on onboarding research showing 85% do so for similar
>   products). If this doesn't hold, the empty-state experience needs rethinking.
> - Users are willing to grant read-only tool access. Not yet validated — plan
>   to test in beta with n=20 users.
>
> **Constraints:**
> - Must ship before Q3 planning cycle (July 1) to influence budget allocation.
> - GDPR compliance required for EU users from day one — cannot do a
>   "compliance later" phased approach.
>
> **Risks:**
> | Risk | Severity | Likelihood | Mitigation |
> |------|----------|------------|------------|
> | Third-party API rate limits cause stale data | High | Medium | Implement caching layer; degrade gracefully with "last synced" timestamp |
> | Users perceive blocker detection as surveillance | High | Low | Frame as "team health" not "individual tracking"; make flagging opt-out per person |
> | Jira OAuth changes break integration | Medium | Low | Abstract integration layer; monitor Jira changelog |

**Bad:**

> "Risks: There might be some technical challenges. We'll handle them as they
> come up."
>
> (No specifics. No severity. No mitigation. This adds zero information for
> decision-makers.)
