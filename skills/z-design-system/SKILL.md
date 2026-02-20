---
name: z-design-system
description: |
  Design token systems and component architecture for web and React Native.
  Use when: implementing design-system, building UI components, defining tokens, creating themed interfaces.
  Do not use for: UX decisions (use z-ux-design), business logic, data fetching.
  Workflow: z-ux-design (what/why) → this skill (tokens, components) → z-nextjs | z-react-native (integration).
references:
  - references/token-examples.md    # W3C DTCG format examples, theme files
  - references/examples.md          # Headless hooks, Compound components, Variant props
  - references/platform-web.md      # Web/Next.js: CSS custom properties, dark mode, usage
  - references/platform-rn.md       # React Native: TS tokens, color scheme, styled example
---

# Design System

## Token Architecture

### Multi-Tier Hierarchy

```
Tier 1: Primitive     →  Raw values, no meaning
Tier 2: Semantic      →  Intent/purpose ← USE THIS
Tier 3: Component     →  (Optional) Component-specific overrides
```

```
color.blue.500              (primitive) - NEVER use directly
    ↓
color.interactive.primary   (semantic) ← use this in components
    ↓
button.bg.primary           (component, optional)
```

**Rule: Components only reference Semantic tokens. Never Primitive.**

→ W3C DTCG format examples and theme files: `references/token-examples.md`

### Semantic Token Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| `color.bg.*` | Backgrounds | primary, secondary, inverse |
| `color.text.*` | Typography | primary, secondary, link |
| `color.interactive.*` | Actions | primary, primaryHover, primaryActive |
| `color.border.*` | Borders | default, strong, focus |
| `color.status.*` | Feedback | error, success, warning |
| `spacing.component.*` | Inside components | xs, sm, md, lg, xl |
| `spacing.layout.*` | Between sections | xs, sm, md, lg, xl |

→ Platform-specific token output: `references/platform-web.md` | `references/platform-rn.md`

---

## Component Architecture

### Headless + Styled Separation

```
┌──────────────────────────────────────┐
│  Headless Layer                      │
│  Behavior + A11y + Keyboard          │
│  No styles, reusable across brands   │
└──────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────┐
│  Styled Layer                        │
│  Headless + Tokens = UI Component    │
└──────────────────────────────────────┘
```

**Rule: Headless handles behavior. Styled handles appearance. Never mix.**

### File Structure

```
src/shared/ui/
├── tokens/          # primitive, semantic, themes
├── headless/        # useButton, useToggle, useDialog
├── styled/          # Button, Toggle, Dialog (uses headless)
├── primitives/      # Box, Text, Stack
└── patterns/        # FormField, ConfirmDialog
```

---

## Preferred Patterns

| Pattern | Preferred | Avoid | Why |
|---------|-----------|-------|-----|
| Props | `variant="primary" size="lg"` | `primary large` (booleans) | Explicit, mutually exclusive |
| Composition | `<Card><Card.Header>` | `<Card showHeader headerTitle="">` | Flexible, readable |
| Polymorphic | `<Box as="section">` | Separate `<Section>` component | Semantic HTML, less components |
| State | Headless hook + Styled | Mixed logic/styles | Separation of concerns |
| Icons | Lucide only | Mixed icon libs, inline SVG | Consistent, tree-shakeable |
| Layout | Mobile-first, scale up | Desktop-first, scale down | Progressive enhancement |

**Rule: Variant props over booleans. Composition over configuration.**

→ Headless hooks and compound component examples: `references/examples.md`

---

## Accessibility Requirements

| Requirement | Value | Non-negotiable |
|-------------|-------|----------------|
| Text contrast | 4.5:1 minimum | ✅ |
| UI component contrast | 3:1 minimum | ✅ |
| Focus indicator | 2px+ visible outline | ✅ |
| Touch targets | 44×44pt minimum | ✅ |

**Rule: Color is never the only indicator. Always pair with icon, text, or pattern.**

---

## Quick Checklist

- [ ] No hardcoded values — all colors, spacing, radii use Semantic tokens
- [ ] Dark theme remaps Semantic tokens only, system preference respected
- [ ] Headless hook for behavior/a11y, Styled component for appearance
- [ ] `variant` / `size` props, not booleans
- [ ] All states: default, hover, focus, active, disabled, loading
- [ ] Mobile-first responsive, no horizontal scroll
- [ ] Lucide icons only, decorative icons hidden from a11y tree
- [ ] Focus visible, touch targets 44pt+, reduced motion respected
- [ ] ARIA attributes correct (web) / accessibilityRole correct (RN)
