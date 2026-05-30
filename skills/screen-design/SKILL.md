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
  produces the app-level UX plus all initial screens). Do NOT use for:
  conversion/funnel-driven flow optimization (use cro — it diagnoses the fix,
  this skill specs the resulting screen) or animation/motion polish (use
  motion); this skill owns structural layout, states, and copy. Do NOT use for:
  visual styling, color palettes, design tokens (use design-system). Do NOT use
  for: frontend/UI implementation code.
---

# Screen Design — Single Screen on Existing App

Designs one screen against an existing app-level UX without rewriting
`docs/ux/ux-design.md`.

## Prerequisites

`docs/ux/ux-design.md` must already exist (defines IA, global patterns, shared
interactions). **If it does not exist, stop — this is greenfield; use
`ux-design` instead.** If your project keeps UX docs elsewhere, see `AGENTS.md`
at the repo root.

**Methodology lives in the `ux-design` skill.** This skill is lean by design and
has no reference files of its own. For the depth behind each quality bar —
JTBD framing, the 7-state state-machine table, undo/feedback patterns,
error/empty-state copy formulas, and contrast/touch-target/safe-area specs —
consult `skills/ux-design/references/{design-process, interaction-patterns,
ux-writing, ergonomics, cognitive-principles}.md` as needed (loaded on demand,
not duplicated here).

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

**Next:** routing hints, not steps this skill performs — once the screen spec is
approved, use `task-add` to break it into implementation tasks, and
`design-system` for visual tokens and components.

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

This is the relevant subset of `ux-design`'s Quick Checklist; keep it in sync
with that canonical list when either changes.

- [ ] User's ONE goal stated as JTBD
- [ ] Primary action is ONE and visually dominant
- [ ] All 7 states designed (empty, loading, loaded, error, partial, refreshing, offline)
- [ ] Feedback exists for every user action
- [ ] Destructive actions confirmed (stating what will happen); reversible actions offer undo
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
