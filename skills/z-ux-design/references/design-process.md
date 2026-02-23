# Design Process

Step-by-step guide for designing user flows and screens. Follow these steps in order. Do not skip or reorder.

---

## Step 1: Research and Define

Before any design work, establish who you're designing for, what they need, and what constraints exist.

### 1a. User Intent
- What is the user trying to accomplish? (Their goal, not your feature)
- What triggered them to be here? (Entry point context: notification, search, link, habit)
- What does success look like from their perspective? (Not completion — satisfaction)

### 1b. User Context
- What environment are they in? (Commuting, working, relaxing, urgency?)
- What's their mental state? (Focused, distracted, stressed, playful?)
- What device and platform? (Mobile one-handed, tablet, desktop with keyboard?)
- What time pressure do they have? (Quick task vs. deep work session?)

### 1c. Lightweight Research Methods

Choose based on what you need to learn:

| Question | Method | Time |
|----------|--------|------|
| Who are the users? | **Proto-persona** sketch | 30 min |
| What do users need? | **User interviews** (5 users) | 1-2 days |
| How do they think about this? | **Card sort** (15+ participants) | 1 day |
| What are they trying to do? | **Jobs-to-be-Done** framing | 1 hour |
| Where do they struggle today? | **Journey map** of current flow | 2-4 hours |

#### Proto-Persona (Quick)
When you can't do full research, create a lightweight persona:
```
Name:           [Realistic name]
Role:           [What they do]
Goal:           [What they're trying to accomplish]
Context:        [When/where/how they'll use this]
Frustrations:   [Current pain points]
Tech comfort:   [Low / Medium / High]
```
Rule: One persona per primary flow. If you have 3+ distinct personas for one feature, the feature is trying to do too much.

#### Jobs-to-be-Done (JTBD)
Frame every feature as a job the user hires the product to do:
```
When [situation], I want to [motivation], so I can [expected outcome].

Example:
When I receive a meeting invite while commuting, I want to quickly see if I'm free, so I can respond before I forget.
```
This framing prevents feature bloat — every element either serves the job or doesn't.

#### Journey Map (Current State)
Map the user's current experience to find pain points:
```
Stage:     Awareness → Consideration → Action → Post-Action
Doing:     [What they do at each stage]
Thinking:  [What they're wondering]
Feeling:   [Emotional state: confident, confused, anxious, relieved]
Pain:      [Where friction or frustration occurs — these are design opportunities]
```

### 1d. Information Needs
- What's the minimum information user needs to proceed at each step?
- What can be deferred to later steps?
- What assumptions can we make (and auto-fill)?
- What's the user's vocabulary? (Use THEIR words, not internal jargon)

---

## Step 2: Map the Critical Path

### 2a. Find the Shortest Route
1. List every step from entry to goal completion
2. For each step, ask: "Is this step necessary for the user's goal?"
3. Remove or combine steps where possible
4. Identify steps that can happen in background (auto-save, async processing)
5. Count remaining steps — if >5, look for more to eliminate

### 2b. Design for Happy Path First
- 80% of users should have a frictionless experience
- Edge cases handled, but not at the cost of main flow
- Error states designed after happy path is solid
- Progressive complexity: simple first, advanced discoverable

### 2c. Map Decision Points
```
Entry → [Decision A] → Action 1 → [Decision B] → Action 2 → Success
              ↓                          ↓
         Alt Path 1                 Alt Path 2
```

For each decision point:
- What information does user need to decide?
- Can we reduce options? (see Hick's Law in `references/cognitive-principles.md`)
- Can we recommend a default? (best option pre-selected)
- What happens if user doesn't decide? (timeout, default, or block?)

### 2d. Map State Transitions
For each screen, define ALL possible states:
```
[Empty] → [Loading] → [Loaded] → [Error]
                         ↕
                     [Refreshing]
                         ↕
                     [Partial]
                         ↕
                     [Offline]
```
See `references/interaction-patterns.md` for the 7 Universal Screen States.

### 2e. Information Architecture
For features with multiple screens:
- Define navigation pattern (Tab, Stack, Modal, Drawer)
- Map screen hierarchy (sitemap)
- Validate: can user reach core content in ≤3 taps?
See `references/information-architecture.md` for patterns.

---

## Step 3: Design Each Screen

### 3a. Screen Anatomy
```
┌─────────────────────────────┐
│  Context (where am I?)      │
├─────────────────────────────┤
│                             │
│  Information                │
│  (what do I need to know?)  │
│                             │
├─────────────────────────────┤
│  Primary Action             │
│  (what should I do?)        │
├─────────────────────────────┤
│  Secondary Actions          │
│  (what else can I do?)      │
└─────────────────────────────┘
```

### 3b. Per Screen Specification

For each screen, define:

1. **Identity**: Screen name, URL/route, entry points
2. **Primary action** (ONE — visually dominant)
3. **Information shown** (only what supports the current decision)
4. **Secondary actions** (available but not competing with primary)
5. **Feedback mechanism** (what happens after primary action)
6. **All states** (empty, loading, loaded, error, partial, refreshing, offline)
7. **Exit paths** (where can user go from here)

### 3c. Content Hierarchy
1. What does user need FIRST? → Top of screen / above fold
2. What supports the main decision? → Middle
3. What's optional/secondary? → Bottom or progressive disclosure

### 3d. Interaction Specification

For each interactive element, define:
- **Trigger**: tap, swipe, long-press, hover
- **Response**: what happens visually and functionally
- **Feedback**: immediate visual change + haptic (if mobile)
- **Error case**: what if the action fails
See `references/interaction-patterns.md` for standard patterns.

### 3e. UX Copy

For each screen, specify:
- **Headings and labels** (clear, action-oriented)
- **Button labels** (specific verbs — see `references/ux-writing.md`)
- **Empty state copy** (helpful, not just "Nothing here")
- **Error messages** (what happened + how to fix)
- **Helper text** (if field input format isn't obvious)

---

## Step 4: Remove

After initial design, cut aggressively. This is the most important step.

### 4a. The Removal Test
For every element on every screen, ask:
> "If I remove this, does it block the user from completing their goal?"
> - Yes → keep it
> - No → remove it
> - Unsure → mark it for testing

### 4b. Removal Checklist

| Often Added | Remove If... |
|-------------|-------------|
| Tutorial/onboarding | UI is self-explanatory |
| Confirmation dialogs | Action is non-destructive or reversible |
| "Are you sure?" prompts | Action can be undone |
| Feature explanations | Labels are clear |
| Marketing copy in product | User is mid-task |
| Social proof/badges | They don't help the current decision |
| Settings exposed early | Defaults work for 80%+ of users |
| Multiple CTAs per screen | They compete and reduce all click-through |
| Decorative illustrations | They don't communicate useful information |

### 4c. Step Reduction
- Can any two steps be combined into one?
- Can any step be automated (auto-detect location, auto-fill, auto-save)?
- Can any step be deferred to later (collect info when it's actually needed, not "just in case")?
- Can any decision be made a smart default?

### 4d. The Anti-Pattern Check
Cross-reference against the anti-patterns list in `SKILL.md`. If any element matches an anti-pattern, remove or redesign it.

---

## Step 5: Validate

### 5a. Self-Review Walk-Through
Walk through the entire flow as if you're a new user:
1. Do I know what to do at each step? (No ambiguity)
2. Is there anything confusing? (Flag it)
3. How many taps/clicks from start to goal? (Count them)
4. What could go wrong? (List failure modes)
5. Do all states exist? (Empty, loading, error — not just happy path)

### 5b. Checklist Validation
Run every screen against:
- [ ] Quick Checklist in `SKILL.md`
- [ ] Cognitive principles (justified with principle names)
- [ ] Ergonomics specs (`references/ergonomics.md`)
- [ ] UX writing rules (`references/ux-writing.md`)
- [ ] Interaction patterns (`references/interaction-patterns.md`)
- [ ] IA principles (`references/information-architecture.md`)

### 5c. Five-User Usability Test Protocol

5 users find ~85% of usability issues (Nielsen, 2000). Here's the protocol:

#### Setup
- **Participants**: 5 users matching the proto-persona
- **Tasks**: 3-5 core tasks matching JTBD statements
- **Format**: think-aloud protocol (user narrates their thinking)
- **Duration**: 20-30 minutes per session

#### Script Template
```
1. Intro (2 min):
   "I'm testing the design, not you. There are no wrong answers.
    Think out loud — tell me what you're looking at and what you'd do."

2. Task (repeat for each):
   "Imagine you want to [JTBD scenario]. 
    Starting from this screen, show me how you'd do that."

   Observe. Don't guide. Note:
   - Where they tap first (expected? unexpected?)
   - Where they hesitate (>3 seconds = friction)
   - Where they backtrack (wrong path taken)
   - What they say ("I'm not sure what this means")

3. Post-task (1 min per task):
   "How was that? What was confusing, if anything?"

4. Wrap-up (2 min):
   "Overall, what stood out — good or bad?"
```

#### Analysis
| Finding | Severity | Frequency (out of 5) | Action |
|---------|----------|----------------------|--------|
| [Issue] | Critical / Major / Minor | X/5 | [Fix / Investigate / Defer] |

Severity definitions:
- **Critical**: User cannot complete the task (fix before ship)
- **Major**: User completes with significant difficulty (fix in this iteration)
- **Minor**: User notices but works around it (fix in next iteration)

### 5d. Metrics to Track Post-Launch

| Metric | What It Indicates | Red Flag Threshold |
|--------|------------------|-------------------|
| Completion rate | Flow clarity | <70% for core task |
| Time on task | Efficiency | >2x expected time |
| Drop-off points | Friction location | >30% drop at any step |
| Error rate | Confusion | >10% of users encounter errors |
| Rage taps/clicks | Frustration | Any occurrence |
| Return rate | Value delivered | <30% return within 7 days |
