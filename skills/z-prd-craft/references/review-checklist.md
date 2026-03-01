# PRD Review Framework

When asked to review or improve an existing PRD, evaluate against this weighted
framework. Provide specific, actionable feedback prioritized by impact.

---

## Scoring Rubric

Rate the PRD 1-10 using these anchors:

| Score | Level | Description |
|-------|-------|-------------|
| 1-3 | **Needs Rewrite** | Missing critical sections. Problem is undefined or is a disguised solution. No metrics. Cannot determine what to build from this document. |
| 4-5 | **Weak** | Structure present but content is vague. Problem stated but not quantified. Metrics exist but aren't measurable or lack targets. Requirements mix WHAT with HOW. Significant gaps in user understanding. |
| 6-7 | **Decent** | Solid structure with most sections well-covered. Problem is quantified with evidence. Metrics are measurable with targets. A few gaps: maybe weak competitive context, missing edge cases, or unclear scope boundaries. |
| 8 | **Strong** | Clear problem with evidence and compelling "why now." Quantified metrics with counter-metrics. Complete requirements at the right granularity. Explicit scope. A team could build from this with minimal clarification needed. |
| 9-10 | **Exceptional** | Everything in "Strong" plus: compelling narrative, thorough competitive analysis, thoughtful risk assessment. Would excite a team to build. Could present to executive team as-is. |

---

## Evaluation Dimensions

### Problem Definition (Weight: 30%)

- [ ] Problem stated from user perspective, not company perspective
- [ ] Impact quantified with real numbers (users affected, revenue, time, cost)
- [ ] Evidence provided (research, data, user quotes) with sample sizes
- [ ] "Why now" is compelling, specific, and time-bound
- [ ] Does NOT state a solution as the problem
- [ ] Competitive context included (how alternatives handle this)

### User Focus (Weight: 20%)

- [ ] Clear target users with context, needs, and pain points
- [ ] Use cases are specific, ordered by priority
- [ ] Requirements trace back to user needs (no stakeholder-only requirements)
- [ ] Full user lifecycle considered (onboarding through off-boarding)
- [ ] Jobs-to-be-Done or similar framework applied to articulate user intent

### Requirements Quality (Weight: 25%)

- [ ] Focused on functionality, not implementation
- [ ] Right granularity (each requirement independently testable)
- [ ] Complete — covers the full product vision, not just MVP
- [ ] Edge cases and error states addressed
- [ ] Observability and measurement included
- [ ] Requirements have IDs for cross-referencing
- [ ] No technology choices embedded (no specific libraries, frameworks, or tools)
- [ ] Accessibility and internationalization considered where relevant

### Completeness (Weight: 15%)

- [ ] Success metrics are specific, measurable, with targets and timeframes
- [ ] Counter-metrics included for each primary metric
- [ ] Scope and non-goals explicitly stated with reasoning for each
- [ ] Risks identified with severity and mitigation strategy
- [ ] Assumptions documented as "believed true but not validated"
- [ ] MVP PRD exists as a separate companion document

### Clarity & Persuasiveness (Weight: 10%)

- [ ] Concise — no filler, passes the "could anyone disagree?" test
- [ ] Compelling — would excite a team to build this
- [ ] Readable — a new team member could understand without verbal context
- [ ] Standalone — doesn't require meeting notes to make sense
- [ ] Well-structured — can be skimmed effectively using headers and tables

---

## Review Output Format

Structure every PRD review as follows:

### 1. Overall Score
X/10 with one-sentence justification.

### 2. Dimension Scores

| Dimension | Weight | Score | Key Finding |
|-----------|--------|-------|-------------|
| Problem Definition | 30% | X/10 | [one-line summary] |
| User Focus | 20% | X/10 | [one-line summary] |
| Requirements Quality | 25% | X/10 | [one-line summary] |
| Completeness | 15% | X/10 | [one-line summary] |
| Clarity & Persuasiveness | 10% | X/10 | [one-line summary] |

### 3. Top 3 Improvements
Ordered by impact. For each: what's wrong, why it matters, and a concrete
suggestion for how to fix it.

### 4. Detailed Findings
Section-by-section feedback. Reference specific lines or passages. Offer
rewritten alternatives where helpful.

### 5. What's Working
Acknowledge strengths. Don't just list problems — point out what to keep doing.
