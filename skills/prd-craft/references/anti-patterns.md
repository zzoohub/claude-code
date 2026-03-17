# PRD Anti-Patterns

Check every PRD against these failure modes before finalizing. Each anti-pattern
includes what it looks like, why it's dangerous, and how to fix it.

---

## 1. The Solution Masquerading as a Problem

**What it looks like:** "We need to build a notification system" stated as the problem.

**Why it's dangerous:** Skips problem validation. The team builds what was asked for, not what's needed. Maybe the real problem is "users miss 23% of time-sensitive updates" — and the best solution might not be notifications at all.

**Fix:** Rewrite the problem to describe pain, not the absence of a feature.

## 2. The Vacuous PRD

**What it looks like:** Every section filled in, but content is meaningless. "Ensure alignment with legal standards." "Provide a seamless user experience."

**Why it's dangerous:** Looks complete at a glance. Passes review because nobody can extract meaning. The team builds something, but nobody knows if it's right.

**Fix:** Apply the "could anyone disagree?" test. If no reasonable person would take the opposite position, the statement adds no information. Replace with specifics.

## 3. The Novel

**What it looks like:** 30+ pages that nobody reads.

**Why it's dangerous:** Long PRDs get skimmed. Critical details get buried. People build from memory of a conversation, not the document.

**Fix:** Keep the PRD concise. If it's too long, split into PRD + linked feature specs. Each document should be readable in one sitting.

## 4. The Design Document in Disguise

**What it looks like:** PRD contains wireframes, UI mockups, layout specs, pixel values, or detailed screen descriptions.

**Why it's dangerous:** Constrains design before the problem is validated. The PRD becomes outdated the moment the first usability test produces insights.

**Fix:** Remove all visual specs. Replace with functional descriptions. "User can see a summary of recent activity" — not "top section shows a card grid with 3 columns at 280px width."

## 5. The Technical Spec in Disguise

**What it looks like:** PRD names specific libraries, frameworks, or tools. "Built with React." "Uses PostgreSQL with B-tree indexes." "GraphQL subscriptions."

**Why it's dangerous:** Technology choices are HOW, not WHAT. Embedding them means engineering can't choose the best tool. It also makes the PRD brittle — tech choices change faster than requirements.

**Fix:** Describe capabilities, not implementation. "Runs in the browser" not "built with React." "Sub-second data sync" not "WebSocket connections."

## 6. The Metrics-Free Zone

**What it looks like:** No numbers anywhere. "Improve user experience." "Reduce errors." "Make it faster."

**Why it's dangerous:** Without numbers, you can't tell if you succeeded. Every post-launch discussion becomes opinion vs opinion.

**Fix:** Quantify everything. Current state (baseline), target state, and timeframe. If exact numbers aren't available, use estimates with stated assumptions.

## 7. The Everything Bagel

**What it looks like:** No clear scope boundaries. Every wish is in there somewhere.

**Why it's dangerous:** Without explicit non-goals, scope creep is inevitable. The product ships late or ships everything half-built.

**Fix:** Write an explicit "Out of Scope" section. For each excluded item, explain why. Name the tempting features you're deliberately not building.

## 8. The One-Sided Coin

**What it looks like:** All upside, no tradeoffs. No discussion of risks, costs, or what might go wrong.

**Why it's dangerous:** Decision-makers can't make informed choices without understanding tradeoffs. When something goes wrong, there's no mitigation plan.

**Fix:** Add a Risks section with severity and mitigation. Acknowledge tradeoffs explicitly.

## 9. The Outdated Artifact

**What it looks like:** PRD written once, never updated. The project has pivoted twice since.

**Why it's dangerous:** New contributors read the PRD and build the wrong thing. The document becomes a historical curiosity.

**Fix:** Keep a "Last Updated" date. Review the PRD at each major milestone. If it's no longer accurate, update it or mark it as superseded.

## 10. Missing Alternatives

**What it looks like:** No mention of how the problem is currently handled — existing tools, scripts, manual processes, or competing products.

**Why it's dangerous:** If you don't understand existing approaches, you'll build something undifferentiated or solve a problem that's already well-solved.

**Fix:** Include alternative context in the Problem section. Show how the problem is handled today — whether by other tools, manual workarounds, or existing scripts — and where the gap is that justifies building something new.

## 11. Requirement Without Evidence

**What it looks like:** A requirement exists because someone asked for it or it "sounds useful," with no evidence anyone actually needs it.

**Why it's dangerous:** Requirements without evidence optimize for imagination, not reality. The product becomes a collection of "wouldn't it be cool if" ideas rather than solutions to real problems.

**Fix:** For each requirement, ask: "What evidence do we have that this is needed?" Evidence can be personal experience ("I hit this problem 3x this week"), observed behavior, user feedback, or data. If the answer is only "it seems like a good idea," either validate it first or drop it.

## 12. The Copy-Paste PRD

**What it looks like:** A PRD from another product with names find-and-replaced. Sections feel generic.

**Why it's dangerous:** Every product has unique context. A recycled PRD gives the illusion of thoroughness while missing the specific insights that make a PRD useful.

**Fix:** Start every PRD from the problem, not from a previous PRD. Use templates for structure, but fill every section with original thinking specific to this product.
