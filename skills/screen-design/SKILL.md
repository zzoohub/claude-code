---
name: screen-design
description: |
  Design a single screen (or modify an existing one) on a product that already
  has an application-level UX. Creates or updates one
  `docs/ux/screens/{screen}.md` with screen purpose, layout, all 7 states,
  interactions, and UX copy. Touches `docs/ux/ux-design.md` ONLY when IA or
  global patterns genuinely change.
  Use when: designing or redesigning one screen on an existing app. Trigger
  phrases: "design the X screen", "redesign the X page", "spec out the X
  modal", "fix the X flow".
  Do NOT use for: a new product's entire app structure (use ux-design — it
  produces the app-level UX plus all initial screens). Do NOT use for: visual
  styling, color palettes, design tokens (use design-system). Do NOT use for:
  ui code.
---

# Screen Design — Single Screen on Existing App

Designs one screen against an existing app-level UX without rewriting
`docs/ux/ux-design.md`.

## Prerequisites

`docs/ux/ux-design.md` should already exist (defines IA, global patterns,
shared interactions). If your project keeps UX docs elsewhere, see `AGENTS.md`.

## What This Skill Does

1. Reads `docs/ux/ux-design.md` to learn IA, navigation pattern, global
   conventions (toast, modal, error handling), accessibility standards.
2. Reads the feature spec at `docs/prd/features/{feature}.md` if applicable,
   to learn requirements and user journeys for the screen.
3. Asks the minimum questions needed (user goal, entry points, edge cases).
4. Writes one `docs/ux/screens/{screen}.md` covering:
   - Screen purpose (JTBD)
   - Layout and content hierarchy (1 primary action)
   - All 7 states: empty, loading, loaded, error, partial, refreshing, offline
   - Interactions specific to this screen
   - UX copy (labels, errors, empty states, tooltips)
   - Accessibility notes
5. Updates `docs/ux/ux-design.md` ONLY if IA changes (e.g., new nav entry, new
   route). Otherwise leaves it alone.

## What This Skill Does NOT Do

- Does not rewrite app-level UX
- Does not redesign navigation unless the new screen demands it
- Does not produce visual designs, tokens, or component code
- Does not produce tasks

## Workflow

1. **Read app UX** — `docs/ux/ux-design.md` for IA, conventions, accessibility
2. **Read feature spec** (if applicable) — `docs/prd/features/{feature}.md`
3. **Discover the screen** — minimum questions:
   - What is the user's ONE goal on this screen?
   - Where do they arrive from? Where do they go next?
   - Any platform-specific constraints (mobile vs desktop)?
4. **Design with all 7 states** — empty, loading, loaded, error, partial,
   refreshing, offline
5. **Write UX copy** — specific verbs for buttons, "what + how to fix" for
   errors, explanation + CTA for empty states
6. **Patch `ux-design.md` if needed** — only when global IA or conventions
   change

## Quality Bar

- [ ] User's ONE goal stated as JTBD
- [ ] Primary action is ONE and visually dominant
- [ ] All 7 states designed (empty, loading, loaded, error, partial, refreshing, offline)
- [ ] Feedback exists for every user action
- [ ] Button labels are specific verbs (not "OK", "Submit", "Yes")
- [ ] Error messages: what happened + how to fix
- [ ] Empty states: explanation + actionable CTA
- [ ] Accessibility: contrast, focus, keyboard, screen reader labels
- [ ] Mobile: primary actions in thumb zone, safe areas respected

## Output

- `docs/ux/screens/{screen}.md` — new or updated file
- `docs/ux/ux-design.md` — patched only if IA/conventions change

**Line limit:** `docs/ux/screens/{screen}.md` — 300 lines. If exceeded, split
into child screens (e.g., `settings-profile.md`, `settings-billing.md`).

**Naming:** kebab-case matching the screen name. Modals, drawers, and sheets
that belong to a screen live in that screen's file.
