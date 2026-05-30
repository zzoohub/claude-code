# Web Conventions

Setup patterns, cleanup conventions, and integration gotchas for the web animation stack (GSAP + Lenis + D3 + CSS native).

## Table of Contents

1. [GSAP Setup](#gsap-setup)
2. [Cleanup Pattern](#cleanup-pattern)
3. [Tailwind + GSAP Workflow](#tailwind--gsap-workflow)
4. [Text Splitting — Use GSAP SplitText (free since 2025)](#text-splitting--use-gsap-splittext-free-since-2025)
5. [Lenis + GSAP Integration](#lenis--gsap-integration)
6. [GSAP + D3 Integration](#gsap--d3-integration)
7. [D3 Chart Factory Contract](#d3-chart-factory-contract)
8. [CSS Native APIs (prefer for simple cases)](#css-native-apis-prefer-for-simple-cases)
9. [View Transitions API](#view-transitions-api)
10. [Bundle Strategy](#bundle-strategy)
11. [Reduced Motion (JS) — listen for live OS toggle changes](#reduced-motion-js--listen-for-live-os-toggle-changes)
12. [Consume design-system motion tokens](#consume-design-system-motion-tokens)
13. [Performance Rules](#performance-rules)
14. [Common Gotchas](#common-gotchas)


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

## Text Splitting — Use GSAP SplitText (free since 2025)

> **Important update (2026):** Webflow acquired GSAP in Fall 2024. As of April 2025, **all GSAP plugins — including SplitText, MorphSVG, DrawSVG, MotionPath, ScrollTrigger, ScrollSmoother, Inertia — are 100% free for commercial use.** No Club membership required.
>
> SplitText was also **completely rewritten** in 2025: ~50% smaller, an opt-out aria handler (default `aria: "auto"` adds `aria-label` to the container and `aria-hidden` to the split chars/words/lines), easy masking for advanced reveals, and improved cross-browser stability. The aria handler reduces letter-by-letter readout but does **not** fully guarantee accessibility — GSAP itself notes it won't preserve nested links/semantics, and char-level splits can still degrade some screen readers. Test with a real screen reader.

Use `SplitText` directly:

```ts
import { gsap } from "gsap";
import { SplitText } from "gsap/SplitText";

gsap.registerPlugin(SplitText);

const split = SplitText.create(element, {
  type: "chars,words",
  // default aria:'auto' adds aria-label + aria-hidden — still verify char-level
  // splits with a real screen reader (won't preserve nested links/semantics)
});

// split.chars / split.words / split.lines available
// Animate:
gsap.from(split.chars, { y: 100, opacity: 0, stagger: 0.02, duration: 0.6 });

// Cleanup:
split.revert();
```

> **Old custom-splitter pattern (deprecated):** Earlier versions of this skill recommended building a custom `lib/split-text.ts` to avoid the paid plugin. That workaround is no longer needed — and the rewritten official SplitText is now smaller and more accessible than any hand-rolled splitter.

## Lenis + GSAP Integration

The non-obvious part: syncing Lenis with GSAP's ticker and ScrollTrigger. (Package is `lenis`; the older `@studio-freight/lenis` is deprecated/renamed.)

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

Minimal reference implementation — every chart `update`/`destroy` follows this shape (D3 join for `update`, listener/DOM teardown for `destroy`):

```ts
import { select } from "d3-selection";
import { scaleBand, scaleLinear } from "d3-scale";
import { max } from "d3-array";

type Bar = { label: string; value: number };

const createBarChart: ChartFactory<Bar> = (container, data, options) => {
  const width = options?.width ?? 600;
  const height = options?.height ?? 300;
  const svg = select(container)
    .append("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("role", "img");
  const x = scaleBand<string>().range([0, width]).padding(0.1);
  const y = scaleLinear().range([height, 0]);

  function update(newData: Bar[]) {
    x.domain(newData.map((d) => d.label));
    y.domain([0, max(newData, (d) => d.value) ?? 0]);
    svg
      .selectAll<SVGRectElement, Bar>("rect")
      .data(newData, (d) => d.label) // key fn = stable join across updates
      .join(
        (enter) => enter.append("rect").attr("class", "bar"),
        (update) => update,
        (exit) => exit.remove(),
      )
      .attr("x", (d) => x(d.label)!)
      .attr("y", (d) => y(d.value))
      .attr("width", x.bandwidth())
      .attr("height", (d) => height - y(d.value));
  }

  update(data);
  return {
    update,
    destroy: () => {
      svg.remove(); // removes the SVG and all bound listeners
    },
  };
};
```

Tree-shake D3 imports -- import individual modules (`d3-selection`, `d3-scale`, `d3-shape`, etc.) from a centralized `lib/d3.ts` file, not the full `d3` bundle.

For responsive charts, wrap with `ResizeObserver` to re-render on container size changes.

Add `role="img"` + `aria-label` to every chart SVG. For interactive charts, include a visually-hidden `<table>` as screen-reader fallback.

## CSS Native APIs (prefer for simple cases)

CSS-native animation is now the **default** for simple reveals and route transitions in 2026. Reach for GSAP only when you need timeline choreography, callbacks, or stagger that CSS can't express.

| CSS Feature | Use For | Skip When |
|-------------|---------|-----------|
| `animation-timeline: scroll()` | Scroll progress bar | Need callbacks or stagger |
| `animation-timeline: view()` | Single element reveal on scroll | Need stagger or sequencing |
| View Transitions API (same-document) | SPA route transitions, shared elements | Need complex overlay wipes |
| View Transitions API (cross-document) | MPA route transitions across pages | Firefox (no support yet) |
| `@starting-style` | Simple element enter/exit (modal, toast) | Need sequenced/staggered enter/exit |

**Browser support (2026-05):**
- Same-document View Transitions: Baseline (newly available) — Chrome 111+, Safari 18+, Firefox 144+ (Oct 2025; sources vary on the exact Firefox build/flag state — verify against your target before relying on it). "Newly available," not "widely available," so older in-field versions still lack it.
- **Cross-document View Transitions** (`@view-transition` at-rule for MPAs): Chrome 126+ (June 2024), Safari 18.2+; **Firefox: not yet** (the at-rule is ignored) — falls back to instant nav, no animation
- Scroll-driven animations: Chrome 115+, **Safari 26+** (unsupported through 18.x); Firefox behind the `layout.css.scroll-driven-animations.enabled` flag, not shipped. **Not Baseline** — always provide a non-scroll-timeline fallback.
- `@starting-style`: Chrome 117+, Safari 17.5+; Firefox 129+ (Baseline)

Feature-detect with property/selector checks that work cross-browser: `@supports (animation-timeline: view())` for scroll-driven, and `@supports (view-transition-name: none)` (or `@supports selector(::view-transition-group(*))`) for View Transitions. **Avoid `@supports at-rule(@view-transition)`** — the `at-rule()` function is Chromium-only and evaluates false in Safari/Firefox, so it would wrongly disable VT on Safari (which supports it).

## View Transitions API

The primary tool for page route transitions:

```ts
function navigate(href: string, pushFn: (href: string) => void | Promise<void>) {
  if (!document.startViewTransition) {
    pushFn(href);
    return;
  }
  // Return the (possibly async) DOM update so the API snapshots AFTER it commits.
  // If pushFn is async and you don't await it, the transition captures stale DOM.
  document.startViewTransition(async () => { await pushFn(href); });
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
| GSAP core | ~27KB | Pages with complex animation |
| GSAP + ScrollTrigger | ~35KB | Scroll-heavy pages |
| Lenis | ~5KB | Marketing/portfolio sites only |
| D3 (tree-shaken) | ~30KB | Pages with data visualization |

Import only what you use -- never `import "gsap/all"`.

If a page only needs a scroll progress bar or simple reveals, CSS native saves ~35KB of GSAP. But if GSAP is already loaded for other animations, just use GSAP for everything.

## Reduced Motion (JS) — listen for live OS toggle changes

Users can toggle the OS reduced-motion preference while your page is open. A one-shot check at init goes stale. Use `matchMedia` + `change` listener:

```ts
const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
let reduce = mq.matches;
mq.addEventListener("change", (e) => {
  reduce = e.matches;
  // Re-evaluate active timelines: kill / skip-to-end, or rebuild without motion.
});

function initAnimatedSection(el: HTMLElement) {
  if (reduce) return () => {}; // render final state, no animation
  return createFullAnimation(el);
}
```

> Don't speed-up to fake reduced-motion. The spec says "remove or replace motion" — flashing through an animation 100× fast still triggers vestibular issues. Skip the animation entirely and render the final state.

For GSAP boundary-style control: prefer `gsap.matchMedia()` with `(prefers-reduced-motion: reduce)` to scope animations cleanly.

## Consume design-system motion tokens

Don't hardcode `duration: 0.6` or `ease: 'power3.out'` in every animation — read from project tokens defined in `design-system/references/motion.md` (durations like `--duration-fast/normal/slow` and easings) so GSAP / Motion / CSS / native animations all share one timing vocabulary.

```ts
const css = getComputedStyle(document.documentElement);
const fast = parseFloat(css.getPropertyValue('--duration-fast')) / 1000;
const normal = parseFloat(css.getPropertyValue('--duration-normal')) / 1000;
gsap.to(el, { duration: normal, opacity: 1 });
```

Or import a typed `tokens.ts` shared with the design system. Either way, swap from literal numbers to token references early — retroactive consolidation is painful.

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

**Animation budget**: cap concurrent animated elements — beyond ~10-15 simultaneous tweens/ScrollTriggers per viewport, prioritize, stagger, or simplify. Profile with DevTools Performance: if a frame's scripting + rendering exceeds the budget (~16ms at 60fps, ~8ms at 120Hz), cut work before adding more motion.

## Common Gotchas

1. **Scroll position on navigation**: browser may restore scroll on back. Reset with `window.scrollTo(0, 0)` in transition callback.
2. **Heavy exit animations**: keep under 400ms or users feel stuck.
3. **Lenis on iOS Safari**: can conflict with native momentum scroll. Test on real devices or skip Lenis on iOS.
4. **ScrollTrigger + dynamic content**: call `ScrollTrigger.refresh()` after content changes that affect layout.
5. **Multiple GSAP contexts on same element**: later context doesn't auto-clean earlier one. Each needs its own cleanup.
6. **Custom cursor on touch devices**: always guard with `"ontouchstart" in window` or `@media (pointer: fine)`.
7. **GSAP plugins (all free since April 2025)**: `SplitText`, `MorphSVG`, `DrawSVG`, `MotionPath`, `InertiaPlugin`, `ScrollTrigger`, `ScrollSmoother` are all 100% free for commercial use after the Webflow acquisition. Older docs referencing "GSAP Club" or "paid plugins" are outdated.
8. **FOUC / JS-failure on scroll reveals**: elements that start at `opacity: 0` and are revealed by JS become permanently invisible if JS fails to load or errors. Gate the hidden state on a `js`-ready class (or `@supports`) added by script, so the no-JS default renders content visible. Always server-render content visible — animation enhances, never gates.
