# Platform: Web / Next.js

## Token Output (CSS Custom Properties)

```css
:root {
  --color-bg-primary: #ffffff;
  --color-text-primary: #0f172a;
  --color-interactive-primary: #2563eb;
}

[data-theme="dark"] {
  --color-bg-primary: #0f172a;
  --color-text-primary: #f9fafb;
}
```

## Dark Mode

- Use `data-theme` attribute on `<html>` for theme switching
- Respect `prefers-color-scheme` as default via media query
- Semantic tokens remap only — components stay unchanged

```css
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --color-bg-primary: #0f172a;
    --color-text-primary: #f9fafb;
  }
}
```

## Token Usage

```css
.button-primary {
  background-color: var(--color-interactive-primary);
  color: var(--color-text-inverse);
  padding: var(--spacing-component-md) var(--spacing-component-lg);
  border-radius: var(--radius-md);
}

.button-primary:hover {
  background-color: var(--color-interactive-primaryHover);
}
```

## Responsive

Mobile-first with `min-width` queries:

```css
/* base = mobile */
@media (min-width: 640px)  { /* sm */ }
@media (min-width: 768px)  { /* md */ }
@media (min-width: 1024px) { /* lg */ }
@media (min-width: 1280px) { /* xl */ }
```

## Icons

- Package: `lucide-react`
- Import: `import { ChevronRight } from 'lucide-react'`

## Focus States

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
  }
}
```
