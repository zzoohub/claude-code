# Feature Spec — Template & Writing Guide

After writing the PRD (`docs/prd/prd.md`), create a separate spec file for each
feature in `docs/prd/features/`. Each file is a self-contained reference for
implementing that feature.

---

## Why Separate Feature Files?

- The PRD captures the full vision and serves as the long-term source of truth
- Feature specs answer: "What exactly does this feature do, and how should it work?"
- Separation keeps each file small enough for one Claude Code session to consume
- Tasks live in `tasks/` directory (root level), not in feature files — clean separation of spec vs progress

---

## Feature Spec Template

```markdown
# [Feature Name]

## Overview

What this feature does and why it matters. 2-3 sentences connecting back to
the product vision. Reference the PRD problem statement if relevant.

---

## Requirements

Functional requirements specific to this feature. Each requirement should be
independently testable.

- REQ-001: User can sign in with Google OAuth
- REQ-002: User can sign in with GitHub OAuth
- REQ-003: Session expires after 7 days of inactivity
- REQ-004: Protected routes redirect unauthenticated users to login

---

## User Journeys

Step-by-step flows showing how users interact with this feature.

### First-time login
1. User clicks "Sign in with Google"
2. Redirected to Google consent screen
3. After consent, redirected back to app
4. Account created, session started
5. Redirected to onboarding

### Returning user
1. User visits app with expired session
2. Redirected to login page
3. Clicks provider → instant redirect (consent already granted)
4. Session restored, lands on last page

### Error states
- OAuth denied → show message, stay on login
- Provider unavailable → show fallback message
- Account exists with different provider → show linking prompt

---

## Edge Cases

- User revokes OAuth access externally → next API call returns 401, redirect to login
- Multiple tabs open → session refresh in one tab applies to all
- User deletes account → cascade delete sessions, OAuth connections

---

## Dependencies

- None (this is the first feature in dev order)

## Depends On This

- billing (needs authenticated user)
- feed (needs user identity)
```

---

## Writing Guide

### Requirements — Good vs Bad

**Good granularity (independently testable):**

> ```
> REQ-001 User can connect their Jira workspace via OAuth, granting read-only
>         access to project and issue data.
> REQ-002 System syncs connected tool data at least every 15 minutes without
>         manual intervention.
> REQ-003 User can view a per-person summary showing: open tasks, completed
>         tasks (last 7 days), and flagged blockers.
> REQ-004 System automatically flags issues that have been in "In Progress"
>         for more than 3x the team's average cycle time as potential blockers.
> REQ-005 User can dismiss a flagged blocker with an optional note explaining
>         why it's not actually blocked.
> REQ-006 Product team can monitor: daily active users, tool connections per
>         user, blocker flag accuracy (dismissed vs. resolved).
> ```

**Too coarse:**

> "REQ-001 System integrates with project management tools."
>
> (Not testable. Which tools? What data? What access level?)

**Too fine:**

> "REQ-001 The Jira OAuth callback URL is /api/auth/jira/callback."
>
> (Implementation detail. This belongs in a technical spec, not a PRD.)

### User Journeys — Good vs Bad

**Good:**

> **Journey: First-time setup**
> 1. User signs up with work email
> 2. System prompts: "Connect your first tool" → shows supported integrations
> 3. User selects Jira → OAuth flow → grants read-only access
> 4. System begins initial sync (shows progress indicator)
>    - If sync fails → show specific error with retry option
>    - If no projects found → suggest checking permissions
> 5. Once synced, user sees team member list auto-populated from Jira
> 6. User confirms team members (can remove/add manually)
> 7. Dashboard populated with first data → guided tour highlights key areas
>
> **Drop-off risk:** Step 3 (OAuth). Users may hesitate to grant tool access.
> Consider explaining exactly what data is accessed and displaying a "read-only"
> trust signal.

**Bad:**

> "User signs up, connects tools, sees dashboard."
>
> (No decision points. No error states. No drop-off analysis. Not useful for
> anyone building this.)

### Granularity

Each requirement should be independently testable — a QA engineer could
verify it passes or fails.

- Too coarse: "User can manage authentication"
- Too fine: "The login button has 8px border-radius"
- Right level: "User can sign in with Google OAuth and receive a persistent session"

### What Belongs Here vs Elsewhere

| Content | Feature spec | PRD | tasks.md |
|---------|-------------|-----|----------|
| Requirements | Yes | Feature overview only | No |
| User journeys | Yes | No | No |
| Task checklists | No | No | Yes |
| Success metrics | No | Yes | No |
| Dev order | No | Yes | No |

### Length

Target **100-200 lines** per feature. If a feature spec exceeds 200 lines,
consider splitting the feature into sub-features with their own specs.

### Naming Convention

- `docs/prd/features/auth.md`
- `docs/prd/features/billing.md`
- `docs/prd/features/feed.md`

Use short, descriptive names matching the feature name in the PRD's feature
overview table. Filenames should be kebab-case for multi-word features
(e.g., `user-settings.md`, `file-upload.md`).
