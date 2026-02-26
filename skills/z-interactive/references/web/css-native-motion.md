# CSS Native Motion APIs

**Role: supplementary.** GSAP is the primary animation engine. These CSS APIs are used in specific cases where zero-JS is a genuine advantage.

## When to Use CSS Native Over GSAP

| CSS Native | GSAP |
|-----------|------|
| Scroll progress bar (simple scaleX) | Stagger, pin, snap, scrub, callbacks |
| Single-element reveal on scroll (no stagger) | Multi-element choreography |
| Page route transitions (View Transitions API) | Complex overlay wipes with timelines |
| Element enter/exit (`@starting-style`) | Sequenced enter/exit with delays |

**Rule of thumb**: if you need stagger, callbacks, dynamic values, or timeline sequencing — skip CSS, use GSAP directly.

---

## CSS Scroll-driven Animations

Zero JS, compositor thread. Good for simple scroll-linked effects.

### Scroll Progress Bar

```css
.scroll-progress {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: var(--color-primary);
  transform-origin: left;
  animation: progress linear;
  animation-timeline: scroll();
}

@keyframes progress {
  from { transform: scaleX(0); }
  to { transform: scaleX(1); }
}
```

### Single Element Reveal

```css
[data-reveal] {
  animation: reveal linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 30%;
}

@keyframes reveal {
  from {
    opacity: 0;
    transform: translateY(40px);
  }
}
```

> For staggered reveals, use GSAP — CSS has no stagger support.

### Parallax Image (Simple)

```css
.parallax-image {
  animation: parallax linear;
  animation-timeline: view();
}

@keyframes parallax {
  from { transform: translateY(-15%); }
  to   { transform: translateY(15%); }
}

.parallax-container {
  overflow: hidden;
}
```

### animation-range Values

```css
animation-range: entry 0% entry 100%;    /* enters viewport */
animation-range: cover 0% cover 100%;    /* covers viewport */
animation-range: contain 0% contain 100%; /* contained in viewport */
animation-range: exit 0% exit 100%;       /* exits viewport */
```

### Browser Support & Progressive Enhancement

```css
/* Feature detection */
@supports (animation-timeline: view()) {
  [data-reveal] {
    animation: reveal linear both;
    animation-timeline: view();
    animation-range: entry 0% entry 30%;
  }
}
/* No support = element is visible by default. No broken state. */
```

Chrome 115+, Safari 18.4+, Firefox behind flag. Always ensure elements are visible without the animation.

### Tailwind Compatibility

These properties have no Tailwind utility classes. Two options:

```tsx
// Option 1: CSS file (recommended — keep animation CSS separate)
// styles/scroll-animations.css
[data-reveal] { animation: reveal linear both; animation-timeline: view(); ... }

// Option 2: Arbitrary values (ugly but works for one-offs)
<div className="[animation-timeline:view()] [animation-range:entry_0%_entry_30%]" />
```

Option 1 is cleaner. Animation CSS in a dedicated file, Tailwind for everything else.

---

## View Transitions API

Native page transitions. The primary tool for route changes.

### Basic Setup

```css
/* globals.css */
::view-transition-old(root) {
  animation: 0.25s ease-out both fade-out;
}
::view-transition-new(root) {
  animation: 0.25s ease-out both fade-in;
}
@keyframes fade-out { to { opacity: 0; } }
@keyframes fade-in { from { opacity: 0; } }
```

```tsx
// components/transition-link.tsx
export function TransitionLink({
  href,
  children,
  navigate,
  className,
}: {
  href: string;
  children: React.ReactNode;
  navigate: (href: string) => void;
  className?: string;
}) {
  const handleClick = (e: React.MouseEvent) => {
    e.preventDefault();
    if (!document.startViewTransition) {
      navigate(href);
      return;
    }
    document.startViewTransition(() => navigate(href));
  };

  return <a href={href} onClick={handleClick} className={className}>{children}</a>;
}
```

### Shared Element Transition

The killer feature — an image morphs smoothly between pages.

```css
/* List page */
.product-thumbnail { view-transition-name: product-hero; }

/* Detail page */
.product-hero-image { view-transition-name: product-hero; }

/* Custom timing */
::view-transition-group(product-hero) {
  animation-duration: 0.4s;
  animation-timing-function: cubic-bezier(0.22, 1, 0.36, 1);
}
```

> `view-transition-name` must be unique per page.

### Directional Transitions

```tsx
export function useDirectionalTransition(
  routerPush: (href: string) => void,
  pathname: string,
) {
  const navigate = (href: string) => {
    const direction = href.length > pathname.length ? "forward" : "back";
    document.documentElement.dataset.transitionDir = direction;

    if (!document.startViewTransition) { routerPush(href); return; }
    document.startViewTransition(() => routerPush(href));
  };

  return { navigate };
}
```

```css
[data-transition-dir="forward"]::view-transition-old(root) {
  animation: 0.3s ease slide-out-left;
}
[data-transition-dir="forward"]::view-transition-new(root) {
  animation: 0.3s ease slide-in-right;
}
[data-transition-dir="back"]::view-transition-old(root) {
  animation: 0.3s ease slide-out-right;
}
[data-transition-dir="back"]::view-transition-new(root) {
  animation: 0.3s ease slide-in-left;
}
```

### Clip / Iris Reveal

```css
::view-transition-new(root) {
  animation: 0.6s cubic-bezier(0.22, 1, 0.36, 1) clip-reveal;
}
@keyframes clip-reveal {
  from { clip-path: circle(0% at 50% 50%); }
  to   { clip-path: circle(150% at 50% 50%); }
}
```

Browser support: Chrome 111+, Safari 18+. Falls back to instant navigation.

---

## @starting-style (Enter/Exit Animations)

Animates elements when they appear/disappear in the DOM. Replaces JS-based enter/exit logic for simple cases.

### Modal

```css
.modal-overlay {
  opacity: 1;
  transition: opacity 0.3s ease;
  transition-behavior: allow-discrete;

  @starting-style { opacity: 0; }
}

.modal-overlay[hidden] {
  opacity: 0;
  display: none;
}

.modal-content {
  opacity: 1;
  transform: translateY(0) scale(1);
  transition: opacity 0.3s, transform 0.3s cubic-bezier(0.22, 1, 0.36, 1);
  transition-behavior: allow-discrete;

  @starting-style {
    opacity: 0;
    transform: translateY(20px) scale(0.95);
  }
}

.modal-content[hidden] {
  opacity: 0;
  transform: translateY(-10px) scale(0.95);
  display: none;
}
```

### Toast / Notification

```css
.toast {
  opacity: 1;
  transform: translateX(0);
  transition: opacity 0.3s, transform 0.3s cubic-bezier(0.22, 1, 0.36, 1);
  transition-behavior: allow-discrete;

  @starting-style {
    opacity: 0;
    transform: translateX(100%);
  }
}

.toast.dismissing {
  opacity: 0;
  transform: translateX(100%);
}
```

### Dropdown / Popover

```css
.dropdown {
  opacity: 1;
  transform: translateY(0);
  transition: opacity 0.2s, transform 0.2s ease;
  transition-behavior: allow-discrete;

  @starting-style {
    opacity: 0;
    transform: translateY(-8px);
  }
}

.dropdown[hidden] {
  opacity: 0;
  transform: translateY(-8px);
  display: none;
}
```

Browser support: Chrome 117+, Safari 17.5+. Unsupported browsers show elements instantly (no broken state).

> For **sequenced** enter/exit (stagger children, wait for async data, chain animations) — use GSAP timelines.

---

## Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

This one rule covers all CSS native animations. GSAP animations need the JS-level `useReducedMotion` hook — see `references/performance.md`.
