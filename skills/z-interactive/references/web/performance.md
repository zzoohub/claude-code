# Performance Guide

## The Stack

```
GSAP (main thread JS)           →  primary engine for all DOM animation
CSS native (compositor thread)  →  supplementary for simple scroll/transition cases
Lenis (main thread JS)          →  smooth scroll feel
```

GSAP is the default. Use CSS native only when zero-JS is genuinely advantageous (progress bar, simple single-element reveal, page transitions).

## The Golden Rule

Animate only **transform** and **opacity**. These are GPU-composited and don't trigger layout or paint.

| Property | Layout | Paint | Composite | Use? |
|----------|--------|-------|-----------|------|
| `transform` | No | No | Yes | Always safe |
| `opacity` | No | No | Yes | Always safe |
| `filter` | No | Yes | No | Sparingly (blur, brightness) |
| `clip-path` | No | Yes | No | OK for reveals |
| `width` / `height` | Yes | Yes | No | Never animate |
| `top` / `left` | Yes | Yes | No | Never — use transform |
| `margin` / `padding` | Yes | Yes | No | Never animate |
| `box-shadow` | No | Yes | No | Avoid — use layered element |

CSS Scroll-driven Animations are compositor-thread by default when animating transform/opacity. This is why they're faster than GSAP for the same visual effect.

## Bundle Size Strategy

### Library Sizes (minified + gzipped)

| Library | Size | Strategy |
|---------|------|----------|
| CSS native APIs | **0KB** | Use for simple cases when GSAP not already loaded |
| GSAP core | ~25KB | Include only on pages with complex animation |
| GSAP + ScrollTrigger | ~35KB | Include on scroll-heavy pages that need pin/stagger |
| GSAP + all free plugins | ~50KB | Only import what you use |
| Lenis | ~8KB | Safe to include globally |

### GSAP Tree-Shaking

```tsx
// ✅ Only import what you use
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

// ❌ Don't import everything
import "gsap/all";
```

### CSS Native: When It Saves Bundle

If a page only needs a scroll progress bar or simple reveals (no stagger, no pin), CSS native saves ~35KB of GSAP. But if GSAP is already loaded on the page for other animations, there's no benefit to mixing — just use GSAP for everything on that page.

| Pattern | CSS When | GSAP When |
|---------|----------|----------|
| Scroll progress bar | Only animation on page | GSAP already loaded |
| Single reveal on scroll | No stagger needed | Part of larger choreography |
| Page transition | View Transitions API covers it | Complex overlay wipe with callbacks |
| Enter/exit | `@starting-style` for simple modal | Sequenced/staggered enter/exit |

---

## Cleanup Patterns

### GSAP Cleanup

Use `useGSAP` from `@gsap/react` — it handles context creation and cleanup automatically:

```tsx
useGSAP(() => {
  gsap.to(".box", { x: 100 });
  ScrollTrigger.create({ trigger: ".section", ... });
}, { scope: containerRef }); // Auto-cleanup on unmount
```

### Lenis Cleanup

```tsx
useEffect(() => {
  const lenis = new Lenis();
  // ... setup
  return () => lenis.destroy();
}, []);
```

### requestAnimationFrame Cleanup

```tsx
useEffect(() => {
  let rafId: number;
  const animate = () => {
    // ... logic
    rafId = requestAnimationFrame(animate);
  };
  rafId = requestAnimationFrame(animate);
  return () => cancelAnimationFrame(rafId);
}, []);
```

---

## will-change Management

`will-change` creates a GPU layer. Each layer costs VRAM.

```tsx
// ✅ Add before animation, remove after
el.style.willChange = "transform";
gsap.to(el, {
  x: 100,
  onComplete: () => { el.style.willChange = "auto"; },
});

// ❌ Never leave permanently in CSS
.card { will-change: transform; } /* BAD */
```

CSS scroll-driven animations handle layer promotion automatically — you don't need `will-change`.
GSAP's `force3D: true` (default) adds `translateZ(0)` — you rarely need `will-change` with GSAP.

---

## Mobile Performance

### Device Tier Detection

```ts
// hooks/use-device-tier.ts
export function useDeviceTier(): "low" | "mid" | "high" {
  if (typeof window === "undefined") return "mid";

  const cores = navigator.hardwareConcurrency || 4;
  const memory = (navigator as any).deviceMemory || 4;
  const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

  if (isMobile && (cores <= 4 || memory <= 2)) return "low";
  if (isMobile || cores <= 4) return "mid";
  return "high";
}
```

### GSAP matchMedia

```tsx
import { ScrollTrigger } from "gsap/ScrollTrigger";

ScrollTrigger.matchMedia({
  "(min-width: 768px)": () => {
    // Full parallax, complex pins
  },
  "(max-width: 767px)": () => {
    // Simple fade only — or rely on CSS scroll-driven animations
  },
});
```

### Responsive Web on Mobile Browsers

- [ ] CSS scroll-driven animations as primary (lighter than GSAP on mobile)
- [ ] No parallax on mobile (disable or simplify)
- [ ] Disable custom cursor (no hover on touch devices)
- [ ] Disable magnetic/tilt effects (no hover)
- [ ] Test on real devices (emulators miss GPU constraints)
- [ ] Avoid scroll hijacking (no GSAP pins on mobile unless essential)
- [ ] Remove Lenis on iOS if causing issues (Safari scroll is already smooth)

---

## Reduced Motion — Implementation

### CSS Level (covers CSS native animations)

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

### JS Level (for GSAP)

```ts
// hooks/use-reduced-motion.ts
import { useState, useEffect } from "react";

export function useReducedMotion() {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    setReduced(mq.matches);
    const handler = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);
  return reduced;
}
```

```tsx
// Pattern: wrap every JS animation component
export function AnimatedHero() {
  const reduced = useReducedMotion();
  if (reduced) return <StaticHero />;
  return <FullAnimatedHero />;
}
```

For GSAP globally:
```tsx
if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
  gsap.globalTimeline.timeScale(100); // Effectively instant
}
```

---

## Profiling Checklist

1. **Chrome DevTools → Performance**: record a scroll session, look for jank (frames > 16ms)
2. **Layers panel**: check layer count — CSS animations should auto-promote, verify GSAP isn't creating excess layers
3. **Coverage tab**: verify GSAP and Lenis aren't loading on pages that don't use them
4. **Lighthouse**: check Total Blocking Time — animation JS shouldn't delay interactivity
5. **Network tab**: confirm GSAP and Lenis aren't loading on pages that don't use them
