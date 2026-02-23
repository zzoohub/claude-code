# UX Writing

Every word in the interface is a design decision. UX writing guides users through actions, builds trust, and prevents errors.

---

## Core Principle

> The best UX copy is the copy you don't notice. It answers the user's question before they ask it.

If users have to re-read something, the copy failed. If users have to guess what a button does, the label failed.

---

## Voice and Tone

### Voice (Constant)
Voice is who you are. It doesn't change.
- **Clear**: say exactly what you mean, no ambiguity
- **Concise**: use the fewest words that convey full meaning
- **Human**: write like a helpful person, not a robot or a lawyer

### Tone (Variable)
Tone adapts to the user's emotional state.

| User State | Tone | Example |
|-----------|------|---------|
| Exploring / neutral | Friendly, informative | "Choose a plan that works for you" |
| Completing a task | Direct, efficient | "Save changes" |
| Succeeded | Warm, celebratory (subtle) | "You're all set!" |
| Made an error | Calm, helpful | "That email address doesn't look right. Check for typos." |
| Frustrated / blocked | Empathetic, solution-focused | "We're having trouble connecting. Try again, or check your network." |
| Anxious (payment, delete) | Reassuring, transparent | "You won't be charged until your trial ends on March 15" |

---

## Button Labels

### The Verb Rule
Every button label should be a **specific verb** (or verb phrase) that describes exactly what happens when tapped.

| ❌ Vague | ✅ Specific | Why |
|---------|-----------|-----|
| OK | Save Changes | "OK" doesn't tell what happens |
| Submit | Send Message | "Submit" is form-speak, not human |
| Yes | Delete Project | "Yes" requires reading the question |
| Confirm | Place Order | Be explicit about the action |
| Continue | Start Free Trial | What are we continuing to? |
| Next | Review Order | Where does "Next" go? |

### Button Label Rules
1. **Start with a verb**: "Save", "Send", "Create", "Delete"
2. **Include the object**: "Save Changes" not just "Save" (unless context is obvious)
3. **Match the trigger**: if user clicked "Edit Profile", the save button says "Save Profile" not "Submit"
4. **Destructive buttons use the destructive verb**: "Delete" not "Remove", "Cancel Subscription" not "Confirm"
5. **Maximum 3 words** for primary buttons. If longer, reconsider the interaction.

### Primary vs. Secondary Buttons

```
Task: User is leaving a form with unsaved changes

[Discard Changes]  [Save and Exit]
  ↑ Secondary         ↑ Primary (filled)
  
NOT:
[No]  [Yes]           ← Ambiguous
[Cancel]  [OK]        ← What does OK do?
```

---

## Error Messages

### The Error Message Formula

```
What happened + Why + How to fix it
```

| Component | Purpose | Example |
|-----------|---------|---------|
| What happened | State the problem clearly | "We couldn't save your changes" |
| Why (if helpful) | Brief reason, no jargon | "The file is too large" |
| How to fix it | Actionable next step | "Try a file under 10MB, or compress it first" |

### Error Message Rules

1. **Never blame the user**: "Invalid input" → "That doesn't look like an email address"
2. **Never use error codes alone**: "Error 403" → "You don't have access to this page"
3. **Never use technical jargon**: "Network timeout" → "We're having trouble connecting"
4. **Be specific about what failed**: "Something went wrong" → "We couldn't load your messages"
5. **Always provide a recovery path**: retry button, alternative action, or support link
6. **Validate inline, not in a modal**: show errors next to the field, not in a popup

### Error Message Examples

```
❌ "Invalid input"
✅ "Enter a date in MM/DD/YYYY format"

❌ "Error: Request failed"
✅ "We couldn't update your profile. Check your connection and try again."

❌ "Password requirements not met"
✅ "Password needs at least 8 characters, including a number"

❌ "400 Bad Request"
✅ "Something's not right with that info. Double-check and try again."

❌ "Operation failed. Contact support."
✅ "We couldn't process your payment. Try a different card, or contact your bank."
```

---

## Empty States

Empty states are a first impression. They're an opportunity, not a dead end.

### Empty State Formula

```
What this place is + Why it's empty + What to do next
```

### Empty State Types

| Type | User Context | Copy Strategy |
|------|-------------|---------------|
| First-use empty | New user, feature never used | Explain value + CTA to start |
| No results | Search/filter returned nothing | Acknowledge + suggest adjustments |
| User-cleared | User deleted/completed everything | Celebrate + suggest next action |
| Error empty | Content failed to load | Explain + retry |

### Examples

```
First-use empty:
┌─────────────────────────────────┐
│                                 │
│         📋                      │
│                                 │
│   No projects yet               │
│                                 │
│   Projects help you organize    │
│   your work and collaborate     │
│   with your team.               │
│                                 │
│   [Create Your First Project]   │
│                                 │
└─────────────────────────────────┘

No results:
┌─────────────────────────────────┐
│                                 │
│         🔍                      │
│                                 │
│   No results for "xyz"          │
│                                 │
│   Try different keywords or     │
│   check your spelling.          │
│                                 │
│   [Clear Search]                │
│                                 │
└─────────────────────────────────┘

User-cleared:
┌─────────────────────────────────┐
│                                 │
│         ✅                      │
│                                 │
│   All caught up!                │
│                                 │
│   You've handled all your       │
│   notifications.                │
│                                 │
└─────────────────────────────────┘
```

---

## Onboarding Copy

### Rules
1. **Delay onboarding as long as possible** — let users explore first
2. **Contextual > sequential** — tooltip when user encounters feature > tutorial at start
3. **One concept per step** — never combine two lessons
4. **Show, don't tell** — interactive demos > text explanations
5. **Make it skippable** — always provide "Skip" (not hidden, not guilt-tripping)
6. **Maximum 3-5 steps** — if it needs more, the feature is too complex

### Permission Requests

```
❌ System dialog immediately on launch:
   "App wants to send you notifications"
   [Don't Allow]  [Allow]

✅ Contextual pre-prompt:
   ┌─────────────────────────────────┐
   │                                 │
   │  🔔 Stay in the loop            │
   │                                 │
   │  Get notified when your order   │
   │  ships or when someone replies  │
   │  to your message.               │
   │                                 │
   │  [Not Now]  [Turn On Alerts]    │
   │                                 │
   └─────────────────────────────────┘
   → Only AFTER user taps "Turn On" does the system dialog appear
```

Why: pre-prompts convert at 2-3x the rate of cold system dialogs.

---

## Confirmation Dialogs

### When to Use
- Destructive + irreversible actions
- Actions with significant side effects (sending to others, publishing)
- Actions that can't be easily undone

### When NOT to Use
- Saving (just save)
- Navigating away (unless data loss)
- Closing (unless unsaved changes)
- Any reversible action (use undo instead)

### Copy Pattern

```
Title:   [Specific action]?
Body:    [Consequence in plain language]
Primary: [Same verb as the action]
Cancel:  Cancel (always present)
```

### Examples

```
✅ Good:
   Title:  "Delete 'Q3 Report'?"
   Body:   "This will permanently remove the file and its 3 attachments.
            This can't be undone."
   Actions: [Cancel]  [Delete]

❌ Bad:
   Title:  "Are you sure?"
   Body:   "This action cannot be undone."
   Actions: [No]  [Yes]
```

---

## Placeholder Text

### Input Field Placeholders

Rules:
1. **Placeholders are NOT labels** — always have a visible label above the field
2. **Placeholders show format/example** — "jane@example.com", "MM/DD/YYYY"
3. **Placeholders disappear on focus** — don't rely on them for instructions
4. **Low contrast by design** — they're hints, not content (gray, not black)
5. **Keep them short** — 2-4 words maximum

```
✅ Label: "Email address"
   Placeholder: "jane@example.com"

❌ Placeholder only (no label): "Enter your email address here"
   → Disappears on focus, user forgets what field is for
```

---

## Progress and Status

### Progress Copy

| Stage | Copy Pattern | Example |
|-------|-------------|---------|
| Not started | Action-oriented CTA | "Start verification" |
| In progress | Current step + context | "Uploading photo... 3 of 5" |
| Almost done | Encouragement | "Almost there — just one more step" |
| Complete | Confirmation + next step | "Verified! You can now send payments." |
| Failed mid-process | What happened + how to resume | "Upload paused. Tap to retry." |

### Status Labels

| ❌ Technical | ✅ Human |
|-------------|---------|
| Pending | Waiting for approval |
| Processing | Setting things up... |
| Queued | In line — you're #3 |
| Fulfilled | Delivered |
| Terminated | Ended |

---

## Writing Checklist

Before finalizing any UX copy:

- [ ] Can the user understand it without context? (Show copy to someone unfamiliar)
- [ ] Is it using the simplest possible words? (No jargon, no acronyms)
- [ ] Is the button label a specific verb? (Not "OK", "Submit", "Confirm")
- [ ] Do error messages explain what happened AND what to do?
- [ ] Are empty states helpful (not just empty)?
- [ ] Is the tone appropriate for the user's emotional state?
- [ ] Is the copy under 15 words per sentence? (Shorter = clearer)
- [ ] Can any word be removed without losing meaning? (Remove it)
