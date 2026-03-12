# PRD Anti-Patterns

Check every PRD against these failure modes before finalizing. Each anti-pattern
includes what it looks like, why it's dangerous, and how to fix it.

---

## 1. The Solution Masquerading as a Problem

**What it looks like:** "We need to build a notification system" stated as the
problem.

**Why it's dangerous:** Skips problem validation entirely. The team builds what
was asked for, not what's actually needed. Maybe the real problem is "users miss
23% of time-sensitive updates because they only check the app once daily" — and
the best solution might not be notifications at all.

**Fix:** Rewrite the problem to start with "Users..." or "Customers..." and
describe pain, not the absence of a feature.

## 2. The Vacuous PRD

**What it looks like:** Every section filled in, but content is meaningless.
"Ensure alignment with legal standards." "Provide a seamless user experience."
"Leverage best practices."

**Why it's dangerous:** Looks complete at a glance. Passes review because nobody
wants to admit they can't extract meaning from it. The team builds something,
but nobody knows if it's right because the requirements never said anything
concrete.

**Fix:** Apply the "could anyone disagree?" test. If no reasonable person would
take the opposite position, the statement adds no information. Replace with
specifics.

## 3. The Novel

**What it looks like:** 30+ pages that nobody reads.

**Why it's dangerous:** Long PRDs get skimmed, not read. Critical details get
buried. Engineers build from memory of a meeting, not from the document.

**Fix:** Keep the full PRD under 10 pages. If it exceeds that, split into a
Product PRD + linked Feature PRDs. Each document should be readable in one
sitting.

## 4. The Design Document in Disguise

**What it looks like:** PRD contains wireframes, UI mockups, layout specs, pixel
values, color codes, or detailed UX flows with screen descriptions.

**Why it's dangerous:** Constrains design before the problem is validated.
Designers can't do their job because the "requirements" already dictate the
solution. The PRD becomes outdated the moment the first usability test produces
insights.

**Fix:** Remove all visual specs. Replace with functional descriptions. "User can
see a summary of their week" — not "Top section shows a card grid with 3 columns
at 280px width."

## 5. The Technical Spec in Disguise

**What it looks like:** PRD names specific libraries, frameworks, APIs, or tools.
"Built with React." "Uses PostgreSQL with B-tree indexes." "Three.js rendering
pipeline." "GraphQL subscriptions for real-time updates."

**Why it's dangerous:** Technology choices are HOW, not WHAT. Embedding them in
the PRD means engineering can't choose the best tool for the job. It also makes
the PRD brittle — technology choices change faster than product requirements.

**Fix:** Describe capabilities, not implementation. "Runs in the browser" not
"Built with React." "Real-time physics simulation" not "Three.js + Rapier WASM."
"Sub-second data sync" not "WebSocket connections."

## 6. The Metrics-Free Zone

**What it looks like:** No numbers anywhere. "Improve user experience." "Reduce
churn." "Increase engagement."

**Why it's dangerous:** Without numbers, you can't tell if you succeeded or
failed. Every post-launch discussion becomes opinion vs opinion.

**Fix:** Quantify everything. Current state (baseline), target state, and
timeframe. If exact numbers aren't available, use estimates with stated
assumptions: "Estimated 20-30% of users affected (based on support tickets,
pending analytics validation)."

## 7. The Everything Bagel

**What it looks like:** No clear scope boundaries. The PRD describes a complete
vision but never says what's NOT included. Every stakeholder's wish is in there
somewhere.

**Why it's dangerous:** Without explicit non-goals, scope creep is inevitable.
The team ships late or ships everything half-built.

**Fix:** Write an explicit "Out of Scope" section. For each excluded item,
explain why. Name the tempting features you're deliberately not building.

## 8. The One-Sided Coin

**What it looks like:** All upside, no tradeoffs. "This will improve conversion,
increase revenue, reduce support costs, and make users happier" — with no
discussion of risks, costs, or what might go wrong.

**Why it's dangerous:** Decision-makers can't make informed choices without
understanding tradeoffs. When (not if) something goes wrong, there's no
mitigation plan.

**Fix:** Add a Risks section with severity and mitigation. Acknowledge tradeoffs
explicitly: "Offering a free trial may increase support volume by 15-20% during
the trial period."

## 9. The Outdated Artifact

**What it looks like:** PRD written once, never updated. The team has pivoted
twice since it was written, but the PRD still describes v1.

**Why it's dangerous:** New team members read the PRD and build the wrong thing.
The document becomes a historical curiosity rather than a living source of truth.

**Fix:** Keep a "Last Updated" date in metadata. Review the PRD at each major
milestone. If it's no longer accurate, update it or mark it as superseded.

## 10. The Missing Competitor

**What it looks like:** No mention of how alternatives solve the same problem.
The solution is presented in a vacuum.

**Why it's dangerous:** Users have choices. If you don't understand the
competitive landscape, you'll build something undifferentiated or solve a problem
that's already well-solved elsewhere.

**Fix:** Include competitive context in the Problem section. Show how competitors
handle this, what they do well, and where the gap is that justifies building
something new.

## 11. The Invisible User

**What it looks like:** Requirements exist because a stakeholder asked for them.
"VP of Sales wants a reporting dashboard." No evidence that users actually need
it.

**Why it's dangerous:** Stakeholder-driven requirements often optimize for
internal visibility, not user value. The product becomes a collection of internal
requests rather than a coherent user experience.

**Fix:** For each requirement, ask: "Which user benefits from this, and how?" If
the answer is only internal stakeholders, challenge it. The underlying need might
be valid, but the solution should serve users, not org charts.

## 12. The Copy-Paste PRD

**What it looks like:** A PRD from another product with names find-and-replaced.
Sections feel generic. Personas don't match the actual audience. Metrics are
borrowed from a different domain. The competitive landscape describes a different
market.

**Why it's dangerous:** Every product has unique context — different users,
different competitive dynamics, different constraints. A recycled PRD gives the
illusion of thoroughness while missing the specific insights that make a PRD
useful. The team builds something that fits the template, not the problem.

**Fix:** Start every PRD from the problem, not from a previous PRD. Use templates
for structure, but fill every section with original research and thinking specific
to this product and these users. If a section feels like it could apply to any
product, it's too generic.
