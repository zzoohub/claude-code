# Information Architecture

Structural design of information spaces. IA determines how users find, understand, and move through content.

---

## Core Principle

> IA is invisible when done right. Users find what they need without thinking about structure.

The goal is not to organize content logically — it's to organize content the way **users expect it to be organized**. Logic and user expectation often diverge.

---

## Dan Brown's 8 Principles of IA

### 1. Principle of Objects
Treat content as a living, breathing thing with lifecycles, behaviors, and attributes.
- A "product" isn't just a page — it has a name, price, status, relationships, and history
- Design the object model before designing the navigation

### 2. Principle of Choices
Present meaningful choices. More isn't better — relevant is better.
- Each navigation level: 5-9 options maximum (Miller's Law)
- Every option must be clearly distinct from its siblings
- If users can't predict what's behind a label, the label fails

### 3. Principle of Disclosure
Show only enough information to help users understand what they'll find if they dig deeper.
- Progressive disclosure: summary → detail → full content
- Each level answers: "Do I want to go deeper?"
- Never front-load complexity

### 4. Principle of Exemplars
Show examples of content when describing categories.
- "Electronics" with a thumbnail of a laptop is clearer than "Electronics" alone
- Previews, thumbnets, and excerpts reduce navigation uncertainty

### 5. Principle of Front Doors
Assume users arrive at any page, not just the homepage.
- Every screen needs: identity (where am I?), orientation (what's here?), navigation (where can I go?)
- Deep links, search results, and shared URLs all bypass the homepage

### 6. Principle of Multiple Classification
Offer multiple ways to find the same content.
- Browse by category + search by keyword + filter by attribute
- Users have different mental models — support all of them
- Example: music by artist, genre, mood, or activity

### 7. Principle of Focused Navigation
Don't mix different types of navigation in the same system.
- Primary nav: top-level sections
- Local nav: within-section movement
- Utility nav: account, settings, help
- Never blend these into a single menu

### 8. Principle of Growth
Design for scale. The IA should accommodate 10x content without restructuring.
- Category names should remain accurate as content grows
- Avoid specific counts in labels ("3 Categories" breaks when it becomes 12)
- Plan for content types that don't exist yet

---

## Navigation Patterns

### Pattern Selection Guide

| User Task | Best Pattern | Why |
|-----------|-------------|-----|
| Switch between 3-5 top-level sections | Tab Bar (mobile) / Top Nav (web) | Persistent, visible, one-tap access |
| Drill into hierarchical content | Stack Navigation | Mental model of depth, easy back |
| Access utility/settings without leaving context | Modal / Bottom Sheet | Overlay preserves context |
| Browse many categories on large screens | Sidebar / Drawer | Scalable, collapsible |
| Complete a multi-step linear task | Wizard / Stepper | Progress visible, steps enforced |

### Tab Bar (Mobile)

```
┌─────────────────────────────────┐
│                                 │
│         Content Area            │
│                                 │
├────┬────┬────┬────┬────────────┤
│ 🏠 │ 🔍 │ ➕ │ 💬 │ 👤        │
│Home│Find│New │Chat│Profile     │
└────┴────┴────┴────┴────────────┘
```

Rules:
- 3-5 items maximum (never more than 5)
- Icons + labels always (icon-only fails accessibility)
- Order: most used → least used, left → right
- Highlight current section clearly
- Badge indicators for unread/pending items

### Stack Navigation (Drill-Down)

```
[List] → [Detail] → [Sub-detail]
  ←  Back    ←  Back
```

Rules:
- Always show back affordance (chevron + previous title)
- Title reflects current content, not section name
- Swipe-back gesture on iOS (edge swipe from left)
- Deep stacks (>3 levels) indicate IA needs flattening

### Bottom Sheet

```
┌─────────────────────────────────┐
│      Parent Screen (dimmed)     │
├─────────────────────────────────┤
│  ━━━ (drag handle)              │
│                                 │
│  Sheet Content                  │
│  - Option A                     │
│  - Option B                     │
│  - Option C                     │
│                                 │
└─────────────────────────────────┘
```

Rules:
- Use for contextual actions, filters, selections
- Drag handle always visible
- Tap outside or swipe down to dismiss
- Three snap points: peek (25%), half (50%), full (90%)
- Never nest bottom sheets

### Sidebar (Web / Tablet)

```
┌──────────┬──────────────────────┐
│ Section A│                      │
│ Section B│    Content Area      │
│ Section C│                      │
│ ──────── │                      │
│ Settings │                      │
│ Help     │                      │
└──────────┴──────────────────────┘
```

Rules:
- Collapsible on smaller viewports (hamburger trigger)
- Group related items with dividers or headings
- Current section highlighted
- Utility items (Settings, Help) at bottom, separated
- Max depth: 2 levels (section → subsection)

---

## IA Design Process

### Step 1: Content Inventory
List every piece of content and functionality the product needs to support.
- Pages/screens, features, settings, help content
- Content types: static, dynamic, user-generated, system-generated
- Relationships: parent-child, siblings, cross-references

### Step 2: Card Sort (Discover User Mental Models)
```
Open Sort:  Users create their own groups and name them
Closed Sort: Users sort cards into predefined categories
Hybrid Sort: Predefined categories + option to create new ones
```
- Minimum 15 participants for reliable patterns
- Look for: agreement (>60% same grouping) and disagreement (signals ambiguity)
- Use disagreements to identify content that needs multiple access paths

### Step 3: Define Hierarchy

```
Level 0: App/Site (implicit — user already knows they're "in the app")
Level 1: Primary sections (Tab bar / Top nav — 3-5 items)
Level 2: Sub-sections or content lists
Level 3: Detail views
Level 4+: Avoid if possible — flatten or use search
```

Rule: If a user needs >3 taps/clicks to reach core content, the IA is too deep.

### Step 4: Tree Test (Validate)
- Give users tasks: "Find where you'd change your notification settings"
- Measure: success rate, directness (first click correct?), time
- Pass threshold: >80% success rate, >60% directness
- Fail: restructure and retest

### Step 5: Create Sitemap

```
[App Root]
├── Home
│   ├── Feed
│   └── Recommendations
├── Search
│   ├── Results
│   └── Filters
├── Create
│   ├── New Post
│   └── Drafts
├── Messages
│   ├── Inbox
│   └── Thread
└── Profile
    ├── Settings
    ├── Account
    └── Help
```

Deliverable format: Mermaid diagram or ASCII tree in docs.

---

## Search vs. Browse

| Signal | Favor Search | Favor Browse |
|--------|-------------|-------------|
| Content volume | >100 items | <100 items |
| User knows what they want | Yes — specific query | No — exploring |
| Content is homogeneous | Yes (all products, all articles) | No (mixed types) |
| User vocabulary matches content | Yes | No — needs exposure first |

### Search Best Practices
- Search box: visible on every screen (or one tap away)
- Auto-suggest after 2+ characters
- Show recent searches
- Handle typos (fuzzy matching)
- Empty results: suggest alternatives, never dead-end
- Filter/sort results by relevance, date, category

### Browse Best Practices
- Show content previews (not just labels)
- Enable filtering and sorting
- Support "endless scroll" with clear section breaks
- Provide "back to top" on long lists

---

## Cross-Linking Strategy

Not all content fits neatly into one category. Cross-linking solves this.

### Techniques
- **Related items**: "You might also like" (content-based similarity)
- **Contextual links**: Deep link from one section to another (e.g., product → review)
- **Breadcrumbs**: Show path for deep content (web primarily)
- **Universal search**: Find anything regardless of section
- **Shortcuts/Quick actions**: Jump to frequent destinations (long-press on icon, spotlight search)

### Rule
> Every piece of content should be reachable via at least 2 different paths.

---

## Common IA Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Org-chart nav | Sections mirror internal teams, not user tasks | Redesign around user goals |
| Junk drawer | "More" or "Other" tab catches everything | Re-sort or flatten |
| Deep nesting | 4+ levels to reach content | Flatten with search/filters |
| Ambiguous labels | "Resources" vs "Tools" vs "Library" | Test labels with users |
| Duplicated paths | Same content in 3 places, different names | Canonical location + cross-links |
| Feature-first nav | Organized by features, not user goals | Reframe: what is user trying to do? |
