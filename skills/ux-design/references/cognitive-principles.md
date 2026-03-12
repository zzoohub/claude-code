# Cognitive Principles for UX

Behavioral science applied to interface design. Use this reference when diagnosing why an interface feels wrong or when users struggle.

---

## Hick's Law

**The time to make a decision increases logarithmically with the number and complexity of choices.**

### When to Apply
- User hesitates or freezes on a screen
- Conversion rates drop at decision points
- Users ask "what should I do here?"

### Solutions
- Reduce visible options (progressive disclosure)
- Group related choices into categories
- Highlight recommended option with visual weight
- Remove choices that <5% of users need
- Smart defaults eliminate decisions entirely

### Example
```
❌ Settings page with 40 options visible
✅ Settings grouped into 5 categories, each expandable

❌ "Choose your plan" with 6 tiers + comparison table
✅ 3 plans with one highlighted as "Most Popular"
```

---

## Fitts's Law

**The time to reach a target is a function of distance to and size of the target.**

### When to Apply
- Users miss tap/click targets
- Important actions have low engagement
- Mobile users struggle with certain buttons

### Solutions
- Increase target size (minimum 44×44pt, prefer 48×48pt)
- Reduce distance to frequently used actions
- Place primary actions in thumb-friendly zones
- Add padding around small visual elements (large tap area, small visual)
- Group related actions close together

### Example
```
❌ Small "X" button in corner to close modal
✅ Large "Close" button or tap-outside-to-dismiss + visible close button

❌ Delete button right next to Save button (same size)
✅ Save button large and primary. Delete smaller, separated, different color.
```

---

## Cognitive Load Theory

**Working memory can hold approximately 4±1 chunks of information. Every element competes for attention.**

### Three Types of Cognitive Load
1. **Intrinsic**: complexity inherent to the task (can't reduce — tax forms are complex)
2. **Extraneous**: unnecessary complexity from poor design (CAN and MUST reduce)
3. **Germane**: effort spent learning/understanding (helpful — support it)

### When to Apply
- Users feel overwhelmed
- Users miss important information
- Error rates increase on complex forms
- Users abandon mid-task

### Solutions
- Show only information needed for current decision (nothing extra)
- Break complex tasks into steps (chunking)
- Use progressive disclosure — details on demand
- Remove decorative elements that carry no information
- Provide smart defaults to reduce decisions
- Use recognition over recall (show options, don't make users remember)

### Example
```
❌ Checkout form with 15 fields on one page
✅ 3-step checkout: Shipping → Payment → Review

❌ Dashboard showing 20 metrics simultaneously
✅ 3-5 key metrics visible, rest available via drill-down
```

---

## Goal Gradient Effect

**Motivation increases as people get closer to their goal.**

### When to Apply
- Users abandon multi-step processes
- Completion rates are low
- Users lose interest midway

### Solutions
- Show progress indicators (step X of Y, progress bar)
- Start progress bar at >0% (artificial advancement — e.g., "Profile 20% complete" before user does anything)
- Break large tasks into visible milestones
- Celebrate micro-completions
- Show what's left, not just what's done

### Example
```
❌ 7-step form with no progress indicator
✅ "Step 3 of 4 — Almost done!"

❌ Loyalty card: "Buy 10, get 1 free" (start at 0)
✅ Loyalty card: 12 slots, 2 pre-stamped (start at 2/12 — same 10 needed, but feels closer)
```

---

## Peak-End Rule

**People judge experiences based on the most intense moment (peak) and the ending, not the average.**

### When to Apply
- Users report negative experiences despite mostly smooth flow
- NPS scores are lower than expected
- Users don't return after completing a task

### Solutions
- Identify and fix the most painful moment (peak negative → biggest ROI)
- Create a delightful ending (confirmation, celebration, clear next step)
- End on user's accomplishment, not your upsell
- Smooth the worst friction point, even if average experience is "fine"

### Example
```
❌ After purchase: immediately show "You might also like..."
✅ After purchase: "You're all set! Order #123 confirmed." → clear next steps → THEN suggestions

❌ Onboarding ends with a wall of settings
✅ Onboarding ends with user's first successful action ("Your first workspace is ready!")
```

---

## Miller's Law

**Average person can hold 7±2 items in working memory. (Modern research suggests 4±1 for complex items.)**

### When to Apply
- Navigation has many top-level items
- Lists feel endless without structure
- Users can't remember options from previous screen

### Solutions
- Limit navigation to 5 items (mobile) or 7 items (desktop)
- Chunk information into groups of 3-5
- Use visual hierarchy to reduce perceived item count
- Persist important context across screens (don't make users memorize)
- Use headings to chunk long lists

---

## Von Restorff Effect (Isolation Effect)

**Items that are visually distinct from their surroundings are more likely to be remembered and acted upon.**

### When to Apply
- Primary action doesn't get enough clicks
- Users miss important warnings
- Key information gets lost in the page

### Solutions
- Make ONE thing visually distinct per screen (the primary action)
- Use color, size, or position to isolate the primary element
- Don't make everything "stand out" — if everything is bold, nothing is bold
- Reserve your accent color for interactive/actionable elements only

### Example
```
❌ Three buttons: [Cancel] [Save Draft] [Publish] all same style
✅ [Cancel] and [Save Draft] as text/ghost buttons, [Publish] as filled primary

❌ Every section header is bright blue and bold
✅ Content hierarchy via size/weight, color reserved for actions
```

---

## Jakob's Law

**Users spend most of their time on OTHER apps. They expect your app to work the same way.**

### When to Apply
- Designing novel interactions for standard tasks
- Tempted to "innovate" on navigation or common patterns
- Users struggle with a custom component that replaces a standard one

### Solutions
- Use platform-standard patterns for standard tasks (iOS tab bar, Android material nav)
- Custom patterns only for custom functionality
- If you must deviate, ensure the custom pattern is obviously better (not just different)
- Study competitor and category leader patterns — users carry expectations from them

### Example
```
❌ Custom hamburger menu instead of tab bar for a social app (because "cleaner")
✅ Standard tab bar — users know exactly how it works from every other social app

❌ Custom date picker widget with novel interaction
✅ Native date picker (users know it, accessible by default)
```

---

## Doherty Threshold

**Productivity soars when response time is <400ms. Above this, users perceive delay and lose flow.**

### When to Apply
- System feels "sluggish" despite functioning correctly
- Users double-tap/click because they think the first didn't register
- User engagement drops on technically correct screens

### Solutions
- Target <100ms for input feedback (button press visual change)
- Target <400ms for system responses (navigation, data display)
- Use optimistic UI for >400ms operations
- Show skeleton screens immediately for loading content
- Animations should complete within 300ms for transitions

---

## Aesthetic-Usability Effect

**Users perceive aesthetically pleasing designs as more usable, even when they objectively aren't.**

### When to Apply
- Users report an interface is "hard to use" but usability metrics are fine
- Users prefer a competitor's product despite similar functionality
- Trying to build trust with new users

### Solutions
- Visual polish creates forgiveness for minor usability issues
- First impressions matter disproportionately — invest in visual quality for entry screens
- BUT: aesthetic design cannot compensate for fundamentally broken flows
- Beauty + usability together is the standard, not beauty OR usability

---

## Serial Position Effect

**People remember the first (primacy) and last (recency) items in a list better than middle items.**

### When to Apply
- Designing navigation order
- Ordering items in lists, menus, or onboarding steps
- Structuring content on a page

### Solutions
- Place most important navigation items first and last (Home left, Profile right)
- In long lists, front-load key content and add a strong ending
- Middle items need extra visual emphasis to be noticed
- For onboarding: first and last steps leave the strongest impression

---

## Zeigarnik Effect

**People remember incomplete tasks better than completed ones.**

### When to Apply
- Designing save/resume experiences
- Encouraging users to complete profiles or processes
- Designing notification strategies

### Solutions
- Show incomplete items prominently (progress bars, "Continue where you left off")
- Save partial progress automatically (never lose user's work)
- Use incompleteness as motivation: "Your profile is 60% complete"
- But don't weaponize it — nagging creates anxiety, not motivation

---

## Principle Selection Guide

| User Problem | Primary Principle | Supporting Principles |
|-------------|------------------|----------------------|
| User hesitates | Hick's Law | Cognitive Load |
| User misses targets | Fitts's Law | Von Restorff |
| User overwhelmed | Cognitive Load | Miller's Law, Hick's Law |
| User abandons midway | Goal Gradient | Zeigarnik, Peak-End |
| User remembers negatively | Peak-End Rule | Aesthetic-Usability |
| User confused by custom patterns | Jakob's Law | Cognitive Load |
| Primary action ignored | Von Restorff | Fitts's Law, Serial Position |
| System feels slow | Doherty Threshold | Goal Gradient |
| Users don't return | Aesthetic-Usability | Peak-End, Jakob's Law |
| Users don't complete profiles | Zeigarnik Effect | Goal Gradient |
