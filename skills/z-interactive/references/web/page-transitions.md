# Page Transitions

> React implementation: `../react/page-transitions.md`

## Strategy Selection

| Method | Best For | Performance | Browser Support |
|--------|----------|-------------|-----------------|
| **View Transitions API** | All page transitions (primary choice) | Compositor thread | Chrome 111+, Safari 18+ |
| **GSAP timeline** | Complex choreography (overlay wipe, stagger) | Main thread | All |

**View Transitions API is the default.** Use GSAP only when you need multi-step timelines with callbacks that the CSS-based View Transitions API can't express (e.g., stagger text out → wipe overlay → stagger text in).

> View Transitions patterns (cross-fade, shared element, directional): `references/css-native-motion.md`

---

## GSAP Page Transition (Complex Choreography Only)

Use when View Transitions API is insufficient: overlay wipes, staggered exits with callbacks, sequenced multi-element choreography.

### Overlay Wipe Pattern

```ts
// Expected HTML (persistent across page navigations):
// <div data-page-overlay class="fixed inset-0 z-[9999] bg-black pointer-events-none"
//      style="transform-origin:bottom;transform:scaleY(0)"></div>
// <div class="page-content"><!-- page content --></div>

import { gsap } from "@/lib/gsap";

// Call on page enter (after new content is in the DOM)
function createPageEnterTransition(content: HTMLElement): () => void {
  const overlay = document.querySelector("[data-page-overlay]") as HTMLElement;

  const ctx = gsap.context(() => {
    const tl = gsap.timeline();

    tl.to(overlay, {
      scaleY: 0,
      transformOrigin: "top",
      duration: 0.6,
      ease: "power4.inOut",
    }).from(
      content,
      {
        opacity: 0,
        y: 30,
        duration: 0.5,
        ease: "power3.out",
      },
      "-=0.2"
    );
  });

  return () => ctx.revert();
}
```

### Navigate with Exit Animation

```ts
// Call before navigating to a new page
function navigateWithTransition(href: string, pushFn: (href: string) => void) {
  const overlay = document.querySelector("[data-page-overlay]") as HTMLElement;
  if (!overlay) {
    pushFn(href);
    return;
  }

  gsap.to(overlay, {
    scaleY: 1,
    transformOrigin: "bottom",
    duration: 0.6,
    ease: "power4.inOut",
    onComplete: () => pushFn(href),
  });
}
```

### Staggered Exit + Enter

```ts
// Expected HTML:
// <div class="stagger-page">
//   <div data-stagger-enter>...</div>
//   <div data-stagger-enter>...</div>
//   <div data-stagger-enter>...</div>
// </div>

// Re-call this function on each page navigation (new pathname)
function createStaggerPageEnter(container: HTMLElement): () => void {
  const ctx = gsap.context(() => {
    const items = container.querySelectorAll("[data-stagger-enter]");

    gsap.from(items, {
      y: 40,
      opacity: 0,
      stagger: 0.06,
      duration: 0.5,
      ease: "power3.out",
      delay: 0.2, // Wait for any exit animation
    });
  }, container);

  return () => ctx.revert();
}
```

---

## Transition Patterns by Context

| Context | Recommended |
|---------|------------|
| Marketing / portfolio | GSAP overlay wipe — dramatic, memorable |
| SaaS dashboard | View Transitions API — fast cross-fade |
| E-commerce | View Transitions + shared element (product image morphs) |
| Blog / content | View Transitions — simple opacity fade |
| Creative / agency | GSAP timeline — stagger text out, wipe, stagger text in |

---

## Common Gotchas

1. **Scroll position**: browser may restore scroll on back navigation. Reset with `window.scrollTo(0, 0)` in the transition callback.
2. **Heavy exit animations**: keep under 400ms or users feel stuck.
3. **Data loading**: if the next page needs data, show the transition overlay while loading, not after.
4. **Reduced motion**: replace choreographed transitions with instant cross-fade.
5. **View Transitions + GSAP**: don't use both on the same route change. Pick one approach per project.
