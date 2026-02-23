# Ergonomics & Accessibility

Layout guidelines, sizing specifications, platform-specific patterns, and accessibility requirements. Non-negotiable standards for every design.

---

## Touch & Click Targets

| Element | Minimum | Recommended | Apple HIG | Material |
|---------|---------|-------------|-----------|----------|
| Touch target | 44×44pt | 48×48pt | 44×44pt | 48×48dp |
| Click target (web) | 24×24px | 32×32px | — | 24×24px |
| Target spacing | 8px | 12px | 8pt | 8dp |

### Small Visual, Large Target
```
Visual element can be small if tap area is large:

┌─────────────────┐
│                 │
│    [icon]       │  ← Visual: 24px
│                 │  ← Tap area: 48px
└─────────────────┘
```

Rule: tap area size is measured in logical points, not visual pixels. A 24px icon inside a 48pt tap area is correct.

---

## Mobile Ergonomics

### Thumb Zone (One-Handed Use)

```
┌─────────────────────┐
│   HARD TO REACH     │  ← Status info, less-used actions
│                     │
├─────────────────────┤
│                     │
│   COMFORTABLE       │  ← Content, secondary actions
│                     │
├─────────────────────┤
│   EASY / PRIMARY    │  ← Primary actions, key navigation
└─────────────────────┘
```

### Placement Rules
- **Primary actions**: Bottom 1/3 of screen
- **Navigation**: Bottom bar (iOS/Android standard)
- **Destructive actions**: NOT in easy-reach zone (prevent accidental activation)
- **Frequently toggled controls**: Within thumb arc (middle-right for right hand)

### One-Handed Design Assumptions
- User's other hand is occupied (holding bag, subway pole, child)
- Reachability matters MORE than visual hierarchy on mobile
- Bottom sheets > top modals for action selection
- Floating action buttons (FAB): bottom-right corner, 56dp

---

## Platform-Specific Patterns

### Safe Areas

#### iOS
```
┌─────────────────────────┐
│░░░░ Status Bar ░░░░░░░░│  ← 54pt (Dynamic Island) / 47pt (notch) / 20pt (legacy)
├─────────────────────────┤
│                         │
│      Safe Content       │
│         Area            │
│                         │
├─────────────────────────┤
│░░░░ Home Indicator ░░░░│  ← 34pt bottom inset
└─────────────────────────┘
```

- Always respect `safeAreaInsets` — never place interactive elements behind system UI
- Dynamic Island: 54pt top inset. Content must not overlap.
- Home indicator: 34pt bottom inset. Tab bars account for this automatically.
- Landscape: additional insets on left/right for notch/island

#### Android
```
┌─────────────────────────┐
│░░░░ Status Bar ░░░░░░░░│  ← 24dp default, varies by device
├─────────────────────────┤
│                         │
│      Safe Content       │
│         Area            │
│                         │
├─────────────────────────┤
│░░░ Navigation Bar ░░░░░│  ← 48dp (3-button) / 16dp (gesture)
└─────────────────────────┘
```

- Gesture navigation: 16dp bottom inset (swipe bar)
- 3-button navigation: 48dp bottom inset
- Edge-to-edge: use `WindowInsets` to handle all safe areas

### Platform Navigation Expectations

| Pattern | iOS Convention | Android Convention |
|---------|---------------|-------------------|
| Back navigation | Edge swipe from left, back chevron top-left | System back button/gesture |
| Tab bar | Bottom, max 5, icon+label | Bottom navigation, max 5 |
| Primary action | Inline button or top-right nav bar | FAB (Floating Action Button) |
| Context menu | Long press → popup menu | Long press → popup, 3-dot overflow |
| Pull to refresh | Native pull-down with spinner | SwipeRefreshLayout |
| Search | Large title collapses, search bar appears | Top app bar with search icon |
| Modals | Slide up from bottom, drag to dismiss | Full-screen or bottom sheet |
| Alerts | Centered dialog, 2 buttons | Material AlertDialog |
| Swipe actions | Swipe left on list item for actions | Swipe left/right for actions |
| Selection | Tap to select, blue checkmark | Checkbox or radio button |

### Web-Specific Patterns

| Element | Desktop | Tablet | Mobile |
|---------|---------|--------|--------|
| Navigation | Top bar or sidebar | Top bar (collapsible sidebar) | Bottom bar or hamburger |
| Primary action | Inline button | Inline button | Fixed bottom button or FAB |
| Forms | Multi-column possible | Single column | Single column |
| Hover states | Essential for interactivity cues | Rare (stylus only) | None — don't rely on hover |
| Right-click | Context menus available | N/A | N/A |

---

## Responsive Breakpoints

| Breakpoint | Width | Device Category | Layout |
|-----------|-------|----------------|--------|
| Mobile S | 320px | Older iPhones, small Android | Single column, stacked |
| Mobile M | 375px | iPhone 13/14/15, standard Android | Single column |
| Mobile L | 428px | iPhone Pro Max, large Android | Single column, wider margins |
| Tablet | 768px | iPad Mini, small tablets | Two-column possible |
| Tablet L | 1024px | iPad Air/Pro | Two-column, sidebar |
| Desktop | 1280px | Laptops, small monitors | Multi-column, sidebar |
| Desktop L | 1440px+ | Large monitors | Max content width, centered |

### Responsive Design Rules
- **Mobile-first**: design for 375px, then expand
- **Content width cap**: max 680-720px for reading content (optimal line length: 50-75 characters)
- **Touch targets remain 44pt+** on tablet even though screen is larger
- **Don't hide content on mobile** — restructure, don't remove
- **Test at 320px** — if it breaks here, it will break on real devices

---

## Response Time

| Threshold | User Perception | Design Requirement |
|-----------|-----------------|-------------------|
| <100ms | Instant | Button visual feedback (press state) |
| <300ms | Fast, no indicator needed | Transitions, micro-interactions |
| <1000ms | Flow maintained | Page loads, form submissions. Skeleton optional. |
| 1-3s | Noticeable delay | Skeleton screen or shimmer required |
| 3-10s | Significant wait | Progress indicator with context ("Loading messages...") |
| >10s | Unacceptable for foreground | Background process + notification when done |

### Feedback Rules
- **Always**: visual change on press/click within 100ms (color shift, scale, ripple)
- **300ms-1s**: consider skeleton/shimmer
- **>1s**: loading indicator required
- **>3s**: progress indicator with descriptive text
- **>10s**: move to background, notify on completion

---

## Visual Spacing

### Component Spacing (Inside)
| Token | Value | Use For |
|-------|-------|---------|
| 2xs | 2px | Hairline borders, subtle separators |
| xs | 4px | Tight grouping (icon + label) |
| sm | 8px | Related items in a group |
| md | 12px | Default component padding |
| lg | 16px | Comfortable component padding |
| xl | 24px | Generous component padding |

### Layout Spacing (Between Sections)
| Token | Value | Use For |
|-------|-------|---------|
| xs | 16px | Related sections |
| sm | 24px | Default section gap |
| md | 32px | Distinct sections |
| lg | 48px | Major section breaks |
| xl | 64px | Page-level divisions |
| 2xl | 96px | Hero/landing page section spacing (web) |

### Spacing Rules
- Use consistent tokens — never arbitrary values (13px, 17px, etc.)
- Related items: tighter spacing. Unrelated items: wider spacing.
- More whitespace = more perceived quality (Apple uses generous spacing)
- Mobile: reduce layout spacing by one step vs desktop (lg → md)

---

## Typography Scale

### Dynamic Type Support (iOS)

| Text Style | Default Size | Min (Accessibility) | Max (Accessibility) |
|-----------|-------------|--------------------|--------------------|
| Large Title | 34pt | 34pt | 40pt |
| Title 1 | 28pt | 28pt | 34pt |
| Title 2 | 22pt | 22pt | 28pt |
| Title 3 | 20pt | 20pt | 26pt |
| Headline | 17pt (semibold) | 17pt | 23pt |
| Body | 17pt | 17pt | 23pt |
| Callout | 16pt | 16pt | 22pt |
| Subheadline | 15pt | 15pt | 21pt |
| Footnote | 13pt | 13pt | 19pt |
| Caption 1 | 12pt | 12pt | 18pt |
| Caption 2 | 11pt | 11pt | 17pt |

### Rules
- **Never hardcode font sizes** — support Dynamic Type / scalable text
- **Minimum readable body text**: 16px web, 17pt iOS, 14sp Android
- **Line height**: 1.4-1.6x font size for body text
- **Line length**: 50-75 characters for optimal readability
- **Truncation**: use ellipsis (...) for single-line, multi-line clamping for cards
- **Always test with largest accessibility size** — layouts must not break

---

## Accessibility Requirements

### Non-Negotiable (WCAG 2.1 AA Minimum)

| Requirement | Specification | Test Method |
|-------------|---------------|-------------|
| Text contrast | 4.5:1 minimum (3:1 for large text ≥18pt) | Contrast checker tool |
| UI component contrast | 3:1 minimum against adjacent colors | Visual inspection |
| Focus indicator | 2px+ visible outline, 3:1 contrast | Keyboard navigation test |
| Touch targets | 44×44pt minimum | Layout inspection |
| Text resizing | Content usable at 200% zoom | Browser zoom test |
| Keyboard access | All functions via keyboard | Tab through everything |

### Color
- **Never** use color as the only indicator of state
- Always pair with: icon, text label, pattern, or position change
- Test with protanopia, deuteranopia, tritanopia simulators

```
❌ Red = error, Green = success (color only)
✅ ⚠️ Red text + icon = error, ✓ Green text + icon = success

❌ "Click the blue button" (instruction relies on color)
✅ "Click Continue" (instruction relies on label)
```

### Focus States
```css
/* Visible focus for keyboard users */
:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

/* Remove outline for mouse/touch users */
:focus:not(:focus-visible) {
  outline: none;
}
```

Rules:
- Focus indicator must be visible against all backgrounds
- Focus order must match visual order (DOM order = visual order)
- No focus traps (user can always Tab out)
- Modal open: focus moves to modal. Modal close: focus returns to trigger.

### Screen Readers

- All interactive elements need accessible names (`aria-label` or visible text)
- Images: `alt` text for informative images, `alt=""` for decorative
- Form inputs: associated `<label>` elements (not just placeholder)
- Dynamic content: `aria-live="polite"` for updates, `aria-live="assertive"` for errors
- Headings: proper hierarchy (h1 → h2 → h3, no skipping levels)
- Lists: use semantic `<ul>`, `<ol>`, `<li>` elements
- Landmarks: `<main>`, `<nav>`, `<header>`, `<footer>` for page structure

```tsx
// Icon-only button — needs aria-label
<button aria-label="Close dialog">
  <CloseIcon aria-hidden="true" />
</button>

// Form field — label + helper text
<label htmlFor="email">Email address</label>
<input id="email" type="email" aria-describedby="email-hint" />
<span id="email-hint">We'll send a verification link</span>

// Dynamic notification
<div aria-live="polite" role="status">
  {saveStatus === 'saved' && 'Changes saved'}
</div>
```

### Keyboard Navigation
- All interactive elements reachable via Tab
- Logical tab order (visual order = DOM order)
- Escape closes modals/dropdowns/menus
- Enter/Space activates buttons and links
- Arrow keys for menus, tabs, radio groups, sliders
- Home/End for beginning/end of lists

### Cognitive Accessibility
- Use plain language (aim for 8th grade reading level)
- Consistent navigation across all pages/screens
- Predictable behavior (same trigger = same result everywhere)
- No unexpected changes of context (auto-redirect, auto-submit)
- Timeout warnings with option to extend
- Error messages explain clearly what went wrong and how to fix it
- Don't rely on memory: show information, don't expect users to remember it

---

## Motion & Animation

### Reduced Motion
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Additional User Preferences
```css
/* High contrast mode */
@media (prefers-contrast: more) {
  /* Increase border widths, use solid backgrounds, remove transparency */
}

/* Transparency reduction */
@media (prefers-reduced-transparency: reduce) {
  /* Replace translucent backgrounds with solid backgrounds */
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  /* Use dark palette with appropriate contrast ratios */
}
```

### Animation Duration Guide
| Duration | Use For |
|----------|---------|
| 100-150ms | Micro-interactions (hover, press, toggle) |
| 200-300ms | Component transitions (expand, collapse, fade) |
| 300-500ms | Page/screen transitions, modal open/close |

### Easing
| Easing | Use For |
|--------|---------|
| ease-out | Elements entering view (fast start, gentle stop) |
| ease-in | Elements leaving view (gentle start, fast exit) |
| ease-in-out | Elements changing state (position, size) |
| linear | Never for UI transitions (feels mechanical) |

### Avoid
- Flashing content (3+ times per second) — seizure risk
- Auto-playing video/animation without pause control
- Parallax effects that cause vestibular discomfort
- Continuous looping animations that distract from content
- Animation during data entry (disrupts focus)

---

## Checklist

### Layout
- [ ] Touch targets ≥44×44pt (48×48pt preferred)
- [ ] Primary actions in thumb zone (mobile)
- [ ] Safe areas respected (notch, Dynamic Island, home indicator)
- [ ] Consistent spacing using design tokens
- [ ] Visual hierarchy matches task importance
- [ ] Responsive: tested at 320px and 1440px+
- [ ] Content width capped at 720px for reading

### Typography
- [ ] Body text ≥16px (web) / 17pt (iOS) / 14sp (Android)
- [ ] Dynamic Type / scalable text supported
- [ ] Line height 1.4-1.6x for body
- [ ] Tested with max accessibility text size

### Accessibility
- [ ] Contrast ratios passing (4.5:1 text, 3:1 UI)
- [ ] Focus states visible (2px+ outline, 3:1 contrast)
- [ ] Color not sole indicator of state
- [ ] Keyboard navigation complete (all functions accessible)
- [ ] Screen reader labels present on all interactive elements
- [ ] Reduced motion respected (`prefers-reduced-motion`)
- [ ] Form labels visible (not placeholder-only)
- [ ] Error messages accessible and descriptive
- [ ] Heading hierarchy correct (no skipped levels)
- [ ] Semantic HTML landmarks used
