# Interaction Patterns

How screens respond to user actions. Interaction design is the bridge between static layouts and living interfaces.

---

## Core Principle

> Every user action must produce a visible, immediate, and proportionate response. Silence is the enemy of confidence.

If the user does something and nothing happens, they will either repeat the action (creating errors) or abandon the flow (creating drop-off).

---

## State Machine Design

Every interactive element and every screen exists in one of a finite set of states. Design ALL states before designing the "happy" state.

### The 7 Universal Screen States

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│  Empty  │────▶│ Loading │────▶│ Loaded  │
└─────────┘     └─────────┘     └────┬────┘
                     │               │
                     ▼               ▼
                ┌─────────┐     ┌─────────┐
                │  Error  │     │ Partial │
                └─────────┘     └─────────┘
                                     │
                                     ▼
                                ┌─────────┐
                                │Refreshing│
                                └─────────┘
```

| State | What User Sees | Design Requirements |
|-------|---------------|---------------------|
| **Empty** | No content yet | Explain why empty + clear CTA to create/add first item. Never blank. |
| **Loading** | Content is being fetched | Skeleton shimmer for <3s. Progress bar for >3s. Context: what's loading. |
| **Loaded** | Content is displayed | Primary content visible. Actions available. |
| **Error** | Something failed | What went wrong + what to do (retry, change input, contact support). Never blame user. |
| **Partial** | Some content loaded, some failed | Show what succeeded. Inline error for what failed. Don't block everything. |
| **Refreshing** | Content is being updated | Subtle indicator (pull-to-refresh spinner). Don't replace visible content with skeleton. |
| **Offline** | No network connection | Show cached content if available. Queue actions for sync. Banner: "You're offline — changes will sync when connected." |

### State Checklist
Before finalizing any screen:
- [ ] Designed all 7 states (or explicitly documented why a state is impossible)
- [ ] Empty state has actionable guidance
- [ ] Error state has recovery path
- [ ] Loading state matches expected wait time
- [ ] Transitions between states are smooth (no layout shifts)

---

## System Feedback Patterns

### Feedback Selection Guide

| Scenario | Pattern | Duration | Blocks UI? |
|----------|---------|----------|-----------|
| Action succeeded (non-critical) | Toast / Snackbar | 3-5s auto-dismiss | No |
| Action succeeded (important) | Inline confirmation | Persistent until next action | No |
| Action requires undo window | Snackbar with undo | 5-8s | No |
| Destructive action confirmation | Dialog / Alert | Until user responds | Yes |
| Validation error | Inline error | Until fixed | No |
| System-level issue | Banner | Until resolved | No |
| Background process complete | Push notification / Badge | Until acknowledged | No |

### Toast / Snackbar

```
┌─────────────────────────────────┐
│                                 │
│         Screen Content          │
│                                 │
│                                 │
├─────────────────────────────────┤
│ ✓ Item saved              [Undo]│  ← Snackbar
└─────────────────────────────────┘
```

Rules:
- Position: bottom of screen, above tab bar (mobile) or bottom-left (web)
- Auto-dismiss: 3-5 seconds
- One at a time (queue if multiple)
- Include undo action for reversible operations
- Never use for errors (errors need persistent visibility)

### Inline Feedback

```
┌─────────────────────────────────┐
│ Email                           │
│ ┌─────────────────────────────┐ │
│ │ notanemail                  │ │
│ └─────────────────────────────┘ │
│ ⚠ Enter a valid email address   │  ← Inline error
│                                 │
│ Name                            │
│ ┌─────────────────────────────┐ │
│ │ Jane Doe              ✓    │ │  ← Inline success
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

Rules:
- Show below the input field, not in a separate area
- Validate on blur (not on every keystroke — reduces anxiety)
- Error: red text + icon. Success: green checkmark (optional)
- Error message format: what's wrong + how to fix it
- Never clear user's input on error

### Confirmation Dialog (Destructive Actions Only)

```
┌─────────────────────────────────┐
│                                 │
│  Delete this project?           │
│                                 │
│  This will permanently remove   │
│  "My Project" and all its       │
│  contents. This cannot be       │
│  undone.                        │
│                                 │
│  [Cancel]          [Delete]     │
│                                 │
└─────────────────────────────────┘
```

Rules:
- ONLY for destructive + irreversible actions
- Title: specific action being taken (not "Are you sure?")
- Body: what will happen + consequences
- Primary button: the destructive action (red), labeled with specific verb ("Delete", not "OK")
- Secondary button: cancel (always an escape route)
- Never use for: saving, closing (without data loss), navigation

---

## Gesture Patterns

### Standard Gesture Vocabulary

| Gesture | Standard Meaning | Platform Notes |
|---------|-----------------|----------------|
| Tap | Select / activate | Universal |
| Long press | Context menu / secondary actions | iOS: peek. Android: context menu |
| Swipe left/right | Delete, archive, actions on list item | Reveal action buttons beneath |
| Swipe down | Pull-to-refresh (on scrollable lists) | Spring animation on release |
| Edge swipe (left edge →) | Navigate back | iOS system gesture. Do not override. |
| Pinch | Zoom in/out | Maps, images, documents |
| Two-finger scroll | Scroll content | Standard scroll behavior |
| Double tap | Zoom to fit / Like (social) | Context-dependent |

### Gesture Design Rules

1. **Never invent new gestures** — use established vocabulary
2. **Never override system gestures** — iOS edge swipe back is sacred
3. **Always provide a visible alternative** — gestures are invisible, buttons are not. Every gesture action must also be available via a visible control
4. **Provide haptic feedback** — light haptic on swipe threshold, medium on action commit
5. **Swipe actions must be discoverable** — show hint on first encounter or onboarding

### Swipe-to-Action Pattern

```
Normal state:
┌─────────────────────────────────┐
│ 📧 Email from Alice             │
│    Meeting tomorrow at 3pm      │
└─────────────────────────────────┘

Swiped left (partial):
┌──────────────────────┬──────────┐
│ 📧 Email from Alice  │ 🗑 Delete│
│    Meeting tomorrow   │          │
└──────────────────────┴──────────┘

Swiped left (full — destructive):
┌─────────────────────────────────┐
│ 🗑 Deleted              [Undo]  │
└─────────────────────────────────┘
```

Rules:
- Partial swipe: reveal actions (archive, delete, flag)
- Full swipe: commit the primary action
- Always offer undo for destructive swipe actions
- Color coding: red = destructive, green/blue = constructive
- Maximum 3 actions per side (left and right)

---

## Optimistic UI

Update the UI immediately as if the action succeeded, then reconcile with the server response.

### When to Use
- Action has >95% success rate
- Action is reversible
- Failure doesn't cause data corruption
- Examples: liking a post, marking as read, toggling settings

### When NOT to Use
- Payment processing
- Sending messages to others
- Destructive actions (delete, remove)
- Actions with side effects visible to other users

### Pattern

```
1. User taps "Like"
2. UI immediately shows: heart filled, count +1
3. API call fires in background
4. If success: done (UI already correct)
5. If failure: revert UI + show subtle error toast
```

---

## Loading Patterns

### Pattern Selection by Wait Time

| Expected Wait | Pattern | Example |
|--------------|---------|---------|
| <300ms | No indicator | Button state change |
| 300ms-2s | Skeleton screen | Content placeholders matching layout |
| 2s-5s | Skeleton + shimmer animation | Feed loading |
| 5s-15s | Progress bar + context | "Uploading photo..." with % |
| 15s+ | Background process + notification | "We'll notify you when ready" |

### Skeleton Screen

```
┌─────────────────────────────────┐
│ ████████████                    │  ← Title placeholder
│ ██████████████████████████      │  ← Subtitle placeholder
│                                 │
│ ┌────┐ ████████████████████     │  ← Avatar + text
│ └────┘ ██████████████           │
│                                 │
│ ┌────┐ ████████████████████     │
│ └────┘ ██████████████           │
└─────────────────────────────────┘
```

Rules:
- Match the actual content layout (not a generic spinner)
- Animate with shimmer (left-to-right pulse)
- Transition to real content without layout shift
- Never show skeleton for content already in cache

---

## Undo / Redo Patterns

### Undo Strategy Selection

| Action Type | Strategy | Example |
|------------|----------|---------|
| Reversible, low-stakes | Undo via snackbar (5-8s window) | Archive email, remove from list |
| Reversible, medium-stakes | Undo via "Recently Deleted" (30 days) | Delete photo, delete note |
| Irreversible, high-stakes | Confirmation dialog before action | Delete account, send payment |
| Continuous editing | Cmd+Z / Ctrl+Z unlimited undo stack | Text editing, drawing, design |

### Soft Delete Pattern
```
User "deletes" item
→ Item moves to "Recently Deleted" (hidden from main view)
→ 30-day retention before permanent deletion
→ User can restore anytime within window
→ After 30 days: permanent delete (no confirmation needed — user had 30 days)
```

---

## Transitions and Navigation Animation

### Transition Selection

| Navigation Action | Animation | Duration |
|------------------|-----------|----------|
| Push to detail | Slide in from right | 300ms |
| Pop back to list | Slide out to right | 250ms |
| Open modal | Slide up from bottom | 300ms |
| Close modal | Slide down | 250ms |
| Tab switch | Cross-fade (no slide) | 200ms |
| Expand/collapse | Height animation + fade | 200-300ms |

### Rules
- Direction indicates hierarchy: right = deeper, left = back, up = overlay, down = dismiss
- Matching transitions: open and close should be inverse of each other
- Respect `prefers-reduced-motion`: replace animations with instant cuts
- Never use bouncy/spring animations for navigation (only for delight moments)
- Shared element transitions for visual continuity (list thumbnail → detail hero image)

---

## Micro-Interactions

Small, contained animations that provide feedback and delight.

### Essential Micro-Interactions

| Trigger | Response | Purpose |
|---------|----------|---------|
| Button press | Scale down 95% → release to 100% | Confirms touch registration |
| Toggle switch | Slide + color change | State change is visible |
| Pull-to-refresh | Spinner appears, content shifts down | Action is being processed |
| Form submission | Button → spinner → checkmark | Progress → completion |
| Error | Shake animation (2-3 cycles, 4px amplitude) | Draws attention without alarm |
| Like/favorite | Heart fill + scale pop (110% → 100%) | Delight moment |

### Rules
- Micro-interactions should be <300ms
- Never block user input during animation
- Consistent across the entire app
- Haptic feedback paired with visual (where supported)
