# Platform: Web / Next.js

## Token Output — CSS Custom Properties

Tokens compile to CSS variables. Components reference variables, never raw values.

```css
:root {
  /* Color — semantic */
  --color-bg-primary: #f9fafb;
  --color-bg-secondary: #f3f4f6;
  --color-bg-inverse: #111827;
  --color-bg-overlay: rgba(0, 0, 0, 0.5);
  --color-text-primary: #111827;
  --color-text-secondary: #4b5563;
  --color-text-link: #2563eb;
  --color-text-link-hover: #1d4ed8;
  --color-interactive-primary: #2563eb;
  --color-interactive-primaryHover: #1d4ed8;
  --color-border-default: #e5e7eb;
  --color-border-focus: #3b82f6;
  --color-status-error: #dc2626;
  --color-status-errorBg: #fef2f2;
  --color-status-success: #16a34a;
  --color-status-successBg: #f0fdf4;

  /* Spacing */
  --spacing-component-xs: 4px;
  --spacing-component-sm: 8px;
  --spacing-component-md: 12px;
  --spacing-component-lg: 16px;
  --spacing-component-xl: 24px;
  --spacing-layout-xs: 16px;
  --spacing-layout-sm: 24px;
  --spacing-layout-md: 32px;
  --spacing-layout-lg: 48px;
  --spacing-layout-xl: 64px;

  /* Typography */
  --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;

  /* Motion */
  --duration-instant: 100ms;
  --duration-fast: 200ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;
  --easing-default: cubic-bezier(0.4, 0, 0.2, 1);
  --easing-enter: cubic-bezier(0, 0, 0.2, 1);
  --easing-exit: cubic-bezier(0.4, 0, 1, 1);

  /* Radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-full: 9999px;
}
```

## Dark Mode

Two-layer approach: respect system preference, allow manual override.

```css
/* System preference (auto) */
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --color-bg-primary: #111827;
    --color-bg-secondary: #1f2937;
    --color-bg-inverse: #f9fafb;
    --color-text-primary: #f9fafb;
    --color-text-secondary: #d1d5db;
    --color-text-link: #60a5fa;
    --color-interactive-primary: #3b82f6;
    --color-interactive-primaryHover: #60a5fa;
    --color-border-default: #374151;
    --color-border-focus: #60a5fa;
  }
}

/* Manual override */
[data-theme="dark"] {
  --color-bg-primary: #111827;
  --color-bg-secondary: #1f2937;
  /* ... same remaps ... */
}
```

Set `data-theme` on `<html>`. Components never check theme — they just read CSS variables.

## Responsive

Mobile-first. Base styles are mobile, scale up with `min-width`.

```css
/* Base = mobile */
@media (min-width: 640px)  { /* sm — large phones, landscape */ }
@media (min-width: 768px)  { /* md — tablets */ }
@media (min-width: 1024px) { /* lg — laptops */ }
@media (min-width: 1280px) { /* xl — desktops */ }
```

## Focus States

Visible for keyboard users, hidden for mouse.

```css
:focus-visible {
  outline: 2px solid var(--color-border-focus);
  outline-offset: 2px;
}

:focus:not(:focus-visible) {
  outline: none;
}
```

## Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}
```

## Component Usage Example

```css
.button-primary {
  background-color: var(--color-interactive-primary);
  color: var(--color-text-inverse);
  padding: var(--spacing-component-md) var(--spacing-component-lg);
  border-radius: var(--radius-md);
  font-family: var(--font-sans);
  font-size: 16px;
  font-weight: 600;
  transition: background-color var(--duration-fast) var(--easing-default);
}

.button-primary:hover {
  background-color: var(--color-interactive-primaryHover);
}
```
