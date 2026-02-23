---
name: z-design-system
description: |
  Design token architecture, component patterns, and cross-platform UI for web and React Native.
  Use when: building UI components, defining design tokens, creating themed interfaces, setting up dark mode or theming, configuring Tailwind with design tokens, setting up typography or motion systems, choosing component API patterns (flat vs compound), adding shadows or elevation, or any task involving consistent styling across components. Use this skill whenever the user mentions design tokens, theming, dark mode toggle, component variants, or cross-platform styling — even if they don't explicitly say "design system".
  Do not use for: UX research or user journey decisions (use z-ux-design), business logic, data fetching, API design.
  Workflow: z-ux-design (what/why) → this skill (tokens, components, patterns) → z-nextjs | z-react-native (platform integration).
references:
  - references/tokens.md
  - references/typography.md
  - references/motion.md
  - references/components.md
  - references/platform-web.md
  - references/platform-rn.md
  - references/pipeline.md
---

# Design System

## Philosophy

A design system exists to make the next UI decision faster than the last one. Every token, pattern, and component should reduce future decision cost. When you find yourself hesitating on a color, spacing, or animation value — the system has a gap. Fill it.

Consistency comes from making the right choice the easiest choice, not from enforcing rules. If a pattern is being bypassed, the pattern is wrong — fix it instead of fighting it.

## Token Architecture

Tokens are the single source of truth. Components never hardcode visual values.

```
Primitive   →  Raw values (gray.500, spacing.4). Never use in components.
Semantic    →  Intent (color.bg.primary, spacing.component.md). USE THIS.
Component   →  Override only when a component must deviate from semantic.
```

Why three tiers: Primitive gives a bounded palette. Semantic gives meaning so themes work (dark mode swaps semantic, not every component). Component tier exists for rare exceptions — most components should only need semantic.

→ Full token definitions, dark theme, and W3C DTCG format: `references/tokens.md`

## Typography

A type scale, not ad-hoc font sizes. Every text in the UI maps to a named style.

| Style | Size | Line Height | Weight | Use |
|-------|------|-------------|--------|-----|
| `display` | 30px | 36px | bold | Hero sections |
| `heading.lg` | 24px | 32px | semibold | Page titles |
| `heading.md` | 20px | 28px | semibold | Section titles |
| `heading.sm` | 16px | 24px | semibold | Card titles |
| `body.lg` | 18px | 28px | normal | Long-form |
| `body.md` | 16px | 24px | normal | Default body |
| `body.sm` | 14px | 20px | normal | Secondary text |
| `caption` | 12px | 16px | medium | Labels, metadata |
| `code` | 14px | 20px | normal | Code snippets (mono) |

Why fixed scale: Prevents the "is this 15px or 16px?" decision. Every text element picks from the scale. If nothing fits, the scale needs a new entry — not a one-off value.

→ Full type tokens, responsive scaling, font stack: `references/typography.md`

## Motion

Consistent timing and easing across all animations.

| Token | Value | Use |
|-------|-------|-----|
| `duration.instant` | 100ms | Micro-interactions (toggle, checkbox) |
| `duration.fast` | 200ms | Hovers, fades, small transitions |
| `duration.normal` | 300ms | Modals, drawers, page transitions |
| `duration.slow` | 500ms | Complex choreography, emphasis |
| `easing.default` | cubic-bezier(0.4, 0, 0.2, 1) | Most transitions |
| `easing.enter` | cubic-bezier(0, 0, 0.2, 1) | Elements entering view |
| `easing.exit` | cubic-bezier(0.4, 0, 1, 1) | Elements leaving view |

Always respect `prefers-reduced-motion`. When reduced, skip animation entirely — don't just shorten duration.

→ Motion tokens, platform implementation, reduced motion: `references/motion.md`

## Shadow & Elevation

Shadows communicate depth and hierarchy. Like colors and spacing, shadow values come from tokens — not ad-hoc `box-shadow` strings.

| Token | Use |
|-------|-----|
| `shadow.sm` | Subtle lift — cards, inputs |
| `shadow.md` | Moderate elevation — dropdowns, popovers |
| `shadow.lg` | High elevation — modals, dialogs |
| `shadow.xl` | Max elevation — toasts, command palette |

Dark mode shadows use lower opacity and sometimes darker colors since the base surface is already dark. The semantic shadow tokens remap automatically per theme.

> Full shadow definitions, dark theme overrides, and platform implementation: `references/tokens.md`

## Z-Index

Layering tokens prevent z-index wars. Every layer has a named token.

| Token | Value | Use |
|-------|-------|-----|
| `zIndex.base` | 0 | Default content |
| `zIndex.dropdown` | 100 | Dropdowns, popovers |
| `zIndex.sticky` | 200 | Sticky headers, navbars |
| `zIndex.overlay` | 300 | Overlay backdrops |
| `zIndex.modal` | 400 | Modals, dialogs |
| `zIndex.toast` | 500 | Toast notifications |

If you need a z-index not on this list, add a new token — don't use a magic number.

## Component Patterns

### Choosing the Right API

Not every component needs the same level of flexibility. Pick based on complexity:

| Complexity | Pattern | Example |
|------------|---------|---------|
| Simple, few variations | **Flat** — props only | `<Button variant="primary" size="md">` |
| Moderate, customizable layout | **Compound** — sub-components | `<Card><Card.Header>...<Card.Content>...` |
| Complex, headless needed | **Headless + Styled** | `useDialog()` hook + styled wrapper |

Why both flat and compound: Flat is fast for simple things — a Button doesn't need sub-components. Compound shines when internal layout varies (Card, Dialog, Dropdown). Forcing compound everywhere adds ceremony without value. Forcing flat everywhere blocks flexibility.

When a component grows past ~5 configuration props, that's the signal to consider compound.

### Architecture

```
src/shared/ui/
├── tokens/          # primitive, semantic, themes
├── headless/        # useButton, useToggle, useDialog (behavior + a11y)
├── styled/          # Button, Toggle, Dialog (headless + tokens = UI)
├── primitives/      # Box, Text, Stack (layout atoms)
└── patterns/        # FormField, ConfirmDialog (compositions)
```

Headless hooks own behavior: ARIA, keyboard, focus, state. Styled components own appearance: tokens, variants, sizing. This separation means a Button's click/keyboard/focus logic is written once and reused whether it looks like a primary button, ghost button, or icon button.

→ Full patterns with Flat, Compound, Headless examples: `references/components.md`

## Icons

Use one icon library per project and enforce it. Mixing libraries causes visual inconsistency (different stroke widths, sizing, metaphors) and bundle bloat.

Recommended defaults: `lucide-react` (web), `lucide-react-native` (RN). These are lightweight and tree-shakeable. But if the project has an existing icon set, use that — the principle is consistency, not a specific library.

Decorative icons are hidden from the a11y tree. Meaningful icons get `aria-label` (web) or `accessibilityLabel` (RN).

## Accessibility

Built into every component from the start. Not a review step after implementation.

| Requirement | Minimum | Why |
|-------------|---------|-----|
| Text contrast | 4.5:1 | WCAG AA readability |
| UI contrast | 3:1 | Controls must be distinguishable |
| Focus indicator | 2px visible outline | Keyboard users need to see focus |
| Touch targets | 44×44pt | Fingers are imprecise |

Color is never the sole indicator of state. Error states use color + icon + text. Disabled states use opacity + cursor change.

## Quick Decision Guide

- **Picking a color?** → Find it in semantic tokens. If it doesn't exist, add to semantic first, then use.
- **Spacing a component?** → `spacing.component.*`. Between sections → `spacing.layout.*`.
- **Sizing text?** → Pick from type scale. If nothing fits, extend the scale.
- **Adding depth/elevation?** → Use shadow tokens (`shadow.sm` through `shadow.xl`). Never inline box-shadow values.
- **Layering elements?** → Use z-index tokens. Never use magic numbers.
- **Animating?** → Use motion tokens. Respect reduced motion.
- **Building a simple component?** → Flat API. Props for variants.
- **Building a complex component?** → Compound API. Sub-components for layout flexibility.
- **Need custom behavior?** → Headless hook first, styled wrapper on top.
- **Using Tailwind?** → Map tokens to `tailwind.config`. See `references/platform-web.md`.
- **Cross-platform?** → Tokens defined once, transformed per platform. See `references/pipeline.md`.

## Platform References

→ Web/Next.js (CSS custom properties, dark mode, responsive): `references/platform-web.md`
→ React Native (TS tokens, color scheme, a11y): `references/platform-rn.md`
→ Token pipeline (Style Dictionary, single-source workflow): `references/pipeline.md`
