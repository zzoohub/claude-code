# Web Conventions

Setup patterns, cleanup conventions, and integration gotchas for the web animation stack (GSAP + Lenis + D3 + CSS native).

## Table of Contents

1. [GSAP Setup](#gsap-setup)
2. [Cleanup Pattern](#cleanup-pattern)
3. [Tailwind + GSAP Workflow](#tailwind--gsap-workflow)
4. [Custom Text Splitter](#custom-text-splitter)
5. [Lenis + GSAP Integration](#lenis--gsap-integration)
6. [GSAP + D3 Integration](#gsap--d3-integration)
7. [D3 Chart Factory Contract](#d3-chart-factory-contract)
8. [CSS Native APIs](#css-native-apis)
9. [View Transitions API](#view-transitions-api)
10. [Bundle Strategy](#bundle-strategy)
11. [Reduced Motion (JS)](#reduced-motion-js)
12. [Performance Rules](#performance-rules)
13. [Common Gotchas](#common-gotchas)

---

## GSAP Setup

Centralized registration -- all imports go through one file:

```ts
// lib/gsap.ts
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { Flip } from "gsap/Flip";
import { Observer } from "gsap/Observer";

gsap.registerPlugin(ScrollTrigger, Flip, Observer);

export { gsap, ScrollTrigger, Flip, Observer };
```

Always import from `@/lib/gsap`, never directly from `gsap`.

## Cleanup Pattern

Every animation factory returns a cleanup function. Use `gsap.context()` to batch all animations:

```ts
function createAnimation(container: HTMLElement): () => void {
  const ctx = gsap.context(() => {
    gsap.to(".box", { x: 100 });
    ScrollTrigger.create({ trigger: ".section", /* ... */ });
  }, container); // Scope selectors to container

  return () => ctx.revert(); // Kills all animations + ScrollTriggers inside
}
```

This is the universal pattern for all web animations. `gsap.context()` scopes selector-based animations to the container, and `ctx.revert()` handles full teardown -- preventing memory leaks when elements are removed.

## Tailwind + GSAP Workflow

Tailwind owns **layout and styling**. GSAP owns **motion**. They never overlap. GSAP targets elements via `data-*` attributes or refs -- not Tailwind classes.

```html
<section class="relative flex min-h-screen items-center bg-black px-6">
  <h1 data-reveal class="text-5xl font-bold text-white md:text-7xl">
    Heading
  </h1>
</section>
```

## Custom Text Splitter

Do not import `SplitText` from GSAP — it requires a paid Club membership. Instead, create a `lib/split-text.ts` utility that splits an element's `textContent` into individually animatable `<span>` elements, preserving the original text in an `aria-label` for accessibility. API contract:

```ts
const { chars, words, revert } = splitText(element, "chars");
// chars: HTMLElement[] of individual characters
// words: HTMLElement[] of word groups
// revert(): restores original textContent
```

## Lenis + GSAP Integration

The non-obvious part: syncing Lenis with GSAP's ticker and ScrollTrigger.

```ts
// lib/smooth-scroll.ts
import Lenis from "lenis";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function initSmoothScroll(): () => void {
  const lenis = new Lenis({
    duration: 1.2,
    easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
    smoothWheel: true,
  });

  // Critical: sync Lenis scroll position with ScrollTrigger
  lenis.on("scroll", ScrollTrigger.update);

  // GSAP ticker provides seconds; Lenis.raf() expects milliseconds
  const raf = (time: number) => lenis.raf(time * 1000);
  gsap.ticker.add(raf);
  gsap.ticker.lagSmoothing(0);

  return () => {
    gsap.ticker.remove(raf);
    lenis.destroy();
  };
}
```

**When NOT to use Lenis**: blogs, docs, dashboards, mobile-only sites. Native scroll is better for content reading. Only use on marketing/portfolio sites where the smooth feel adds to the experience.

## GSAP + D3 Integration

D3 owns data binding and SVG structure. GSAP owns scroll-triggered entrance. They complement each other -- D3 doesn't have ScrollTrigger, GSAP doesn't have scales/axes.

```ts
// Build chart with D3 (structure + interactivity)
const chart = createBarChart(container, data);

// GSAP controls scroll-triggered reveal
const bars = container.querySelectorAll(".bar");
gsap.from(bars, {
  scaleY: 0,
  transformOrigin: "bottom",
  stagger: 0.05,
  duration: 0.6,
  ease: "power3.out",
  scrollTrigger: {
    trigger: container,
    start: "top 75%",
    toggleActions: "play none none none",
  },
});
```

When combining: build D3 charts without D3's built-in transitions, then let GSAP handle all animation timing for consistency.

## D3 Chart Factory Contract

Every D3 chart follows the same factory pattern as GSAP animations -- takes a container and data, returns `update` and `destroy`:

```ts
type ChartFactory<T> = (
  container: HTMLElement,
  data: T[],
  options?: { width?: number; height?: number; margin?: { top: number; right: number; bottom: number; left: number } }
) => { update: (newData: T[]) => void; destroy: () => void };
```

Tree-shake D3 imports -- import individual modules (`d3-selection`, `d3-scale`, `d3-shape`, etc.) from a centralized `lib/d3.ts` file, not the full `d3` bundle.

For responsive charts, wrap with `ResizeObserver` to re-render on container size changes.

Add `role="img"` + `aria-label` to every chart SVG. For interactive charts, include a visually-hidden `<table>` as screen-reader fallback.

## CSS Native APIs

Use CSS native only when zero-JS is genuinely advantageous (GSAP not already loaded on page).

| CSS Feature | Use For | Skip When |
|-------------|---------|-----------|
| `animation-timeline: scroll()` | Scroll progress bar | Need callbacks or stagger |
| `animation-timeline: view()` | Single element reveal on scroll | Need stagger or sequencing |
| View Transitions API | Page route transitions, shared elements | Need complex overlay wipes |
| `@starting-style` | Simple element enter/exit (modal, toast) | Need sequenced/staggered enter/exit |

Browser support: scroll-driven (Chrome 115+, Safari 18.4+), View Transitions (Chrome 111+, Safari 18+), @starting-style (Chrome 117+, Safari 17.5+). All degrade gracefully -- elements visible instantly without animation.

Use `@supports (animation-timeline: view())` for feature detection.

## View Transitions API

The primary tool for page route transitions:

```ts
function navigate(href: string, pushFn: (href: string) => void) {
  if (!document.startViewTransition) {
    pushFn(href);
    return;
  }
  document.startViewTransition(() => pushFn(href));
}
```

```css
/* Shared element: same view-transition-name on both pages */
.product-thumbnail { view-transition-name: product-hero; }
.product-hero-image { view-transition-name: product-hero; }

::view-transition-group(product-hero) {
  animation-duration: 0.4s;
  animation-timing-function: cubic-bezier(0.22, 1, 0.36, 1);
}
```

`view-transition-name` must be unique per page. Don't mix View Transitions and GSAP on the same route change -- pick one per project.

## Bundle Strategy

| Library | Size (gzipped) | Strategy |
|---------|------|----------|
| CSS native | **0KB** | Use when GSAP not already loaded |
| GSAP core | ~25KB | Pages with complex animation |
| GSAP + ScrollTrigger | ~35KB | Scroll-heavy pages |
| Lenis | ~8KB | Marketing/portfolio sites only |
| D3 (tree-shaken) | ~30KB | Pages with data visualization |

Import only what you use -- never `import "gsap/all"`.

If a page only needs a scroll progress bar or simple reveals, CSS native saves ~35KB of GSAP. But if GSAP is already loaded for other animations, just use GSAP for everything.

## Reduced Motion (JS)

```ts
function prefersReducedMotion(): boolean {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

// Check before initializing animations
function initAnimatedSection(el: HTMLElement) {
  if (prefersReducedMotion()) return () => {};
  return createFullAnimation(el);
}
```

For GSAP globally: `gsap.globalTimeline.timeScale(100)` makes everything effectively instant.

## Performance Rules

**The golden rule**: Animate only `transform` and `opacity`. These are GPU-composited. Never animate `width`, `height`, `top`, `left`, `margin`, `padding`.

| Property | Safe? | Notes |
|----------|-------|-------|
| `transform`, `opacity` | Yes | Compositor thread |
| `filter`, `clip-path` | Cautious | Triggers paint, OK for reveals |
| `width`, `height`, `top`, `left` | Never | Triggers layout reflow |
| `box-shadow` | Avoid | Use layered element instead |

**will-change**: Add before animation, remove after. Never leave permanently in CSS. GSAP's `force3D: true` (default) handles layer promotion.

**Mobile web**: Disable parallax, custom cursor, magnetic/tilt effects on touch devices. Use `ScrollTrigger.matchMedia` for responsive animation tiers.

## Common Gotchas

1. **Scroll position on navigation**: browser may restore scroll on back. Reset with `window.scrollTo(0, 0)` in transition callback.
2. **Heavy exit animations**: keep under 400ms or users feel stuck.
3. **Lenis on iOS Safari**: can conflict with native momentum scroll. Test on real devices or skip Lenis on iOS.
4. **ScrollTrigger + dynamic content**: call `ScrollTrigger.refresh()` after content changes that affect layout.
5. **Multiple GSAP contexts on same element**: later context doesn't auto-clean earlier one. Each needs its own cleanup.
6. **Custom cursor on touch devices**: always guard with `"ontouchstart" in window` or `@media (pointer: fine)`.
7. **GSAP paid plugins**: `SplitText`, `MorphSVG`, `DrawSVG`, `MotionPath`, `InertiaPlugin` require GSAP Club membership. Never import these — use free alternatives or build custom utilities.
