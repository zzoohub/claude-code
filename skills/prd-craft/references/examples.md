# PRD Section Examples

Concrete examples of what "good" and "bad" look like for each PRD section.
Reference this when writing a PRD to calibrate quality and depth.

---

## Section 1: Problem / Opportunity

**Good:**

> "Engineers run a 3-step manual process after every deploy: check the metrics
> dashboard, scan error logs, and verify key user flows in staging. This takes
> 10-15 minutes and is skipped under time pressure — roughly 40% of deploys
> go unchecked. Unchecked deploys account for 70% of production incidents
> discovered by users rather than the team.
>
> **Why Now:** The team has grown from 3 to 8 engineers in the last quarter.
> Deploy frequency doubled, but the manual verification process didn't scale.
> Last month, two P1 incidents were caught by customers hours after deploy."

**Bad:**

> "Deploys sometimes cause problems. We should add monitoring to catch issues
> faster."
>
> (No numbers. No evidence. Solution stated as fact. No "why now.")

---

## Section 2: Target Users

**Good:**

> **Who and when:** Backend engineers deploying 2-5 times per day to a shared
> staging/production environment. They need confidence that each deploy didn't
> break anything, but can't afford 15 minutes of manual checks every time.
>
> **JTBD:** "When I've just deployed, I want to know within 30 seconds if
> anything broke, so I can fix it immediately instead of context-switching
> back hours later."

**Good (lightweight, personal tool):**

> Me — I maintain 12 git repos across 3 machines and lose track of which
> have uncommitted changes or unpushed branches.

**Bad:**

> "Target users: developers. Use case: deploy better."
>
> (No specificity. No pain point. No current journey. "Better" means nothing.)

---

## Section 3: Proposed Solution

**Good:**

> **Elevator pitch:** A post-deploy verification tool that automatically runs
> health checks, scans error rates, and reports pass/fail within 30 seconds
> of deploy completion.
>
> **Value propositions:**
> 1. Instant deploy confidence → eliminates the 15-minute manual check (Section 1)
> 2. Catches regressions before users do → reduces user-reported incidents (Section 1)
> 3. Runs automatically → no more skipped verifications under time pressure (Section 1)
>
> **Mental model:** Think of it as a "post-deploy smoke test" — like CI, but
> for production. It watches the first few minutes after deploy and tells you
> if anything looks wrong.

**Bad:**

> "We will build a Node.js service using WebSockets to monitor Datadog metrics
> and send Slack alerts via their API."
>
> (This is a technical spec. Names specific technologies. Doesn't describe the
> user experience or connect to problems.)

---

## Section 4: Success Metrics

**Good (lightweight):**

> I use this after every deploy instead of doing manual checks. Deploy
> verification time drops from 10-15 minutes to under 30 seconds.

**Good (full table):**

> | Goal | Metric | Counter-metric | Target | Timeframe |
> |------|--------|----------------|--------|-----------|
> | Eliminate manual checks | % deploys auto-verified | False positive rate | 95% auto-verified | 3 months |
> | Faster incident detection | Time-to-detection after deploy | Alert fatigue (ignored alerts) | <2 min avg | 3 months |
> | Reduce user-reported incidents | User-reported bugs from deploys | Total bug detection rate | 70%→20% | 6 months |

**Bad:**

> "Goals: Improve deploy quality. Increase confidence. Make deploys safer."
>
> (No metrics. No targets. No timeframe. Not measurable. "Safer" is not a KPI.)

---

## Section 7: Scope & Non-Goals

**Good:**

> **In scope:**
> - Post-deploy health checks for web services
> - Error rate monitoring against baseline
> - Pass/fail reporting via CLI and notifications
> - Configuration per project
>
> **Out of scope:**
> - Pre-deploy checks (different problem — belongs in CI, not post-deploy)
> - Performance profiling (adjacent but separate tool; would require different instrumentation)
> - Multi-cloud support (start with single provider; abstract later if demand exists)
> - Mobile app monitoring (different signals; revisit after core tool proves value)

**Bad:**

> "Out of scope: things we're not building."
>
> (Says nothing. The purpose is to name specific temptations and explain why
> you're deliberately not pursuing them.)

---

## Section 8: Assumptions, Constraints & Risks

**Good:**

> **Assumptions:**
> - Services expose a health endpoint or have observable error metrics.
>   If not, the tool degrades to log-based detection only.
> - Deploy events are programmatically detectable (webhook, CI event, or CLI
>   trigger). If manual deploys exist, users must trigger verification manually.
>
> **Constraints:**
> - Must work with existing CI pipeline — cannot require migration.
> - Verification must complete within 60 seconds to avoid blocking the next deploy.
>
> **Risks:**
> | Risk | Severity | Likelihood | Mitigation |
> |------|----------|------------|------------|
> | High false positive rate erodes trust | High | Medium | Tune thresholds per-project; allow snooze; show confidence score |
> | Format changes in input data break parsing | Medium | Medium | Validate schema on read; report specific location of malformed data |
> | Tool adds latency to deploy pipeline | Medium | Low | Run async; never block deploy completion |

**Bad:**

> "Risks: There might be some technical challenges. We'll handle them as they
> come up."
>
> (No specifics. No severity. No mitigation. This adds zero information.)
