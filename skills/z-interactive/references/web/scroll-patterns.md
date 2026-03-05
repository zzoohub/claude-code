# Scroll Patterns

> React implementation: `../react/scroll-patterns.md`

## Smooth Scroll with Lenis

### Installation

```bash
npm install lenis
```

### Global Setup

```ts
// lib/smooth-scroll.ts — Lenis requires browser scroll APIs
import Lenis from "lenis";
import { gsap, ScrollTrigger } from "@/lib/gsap";

let lenisInstance: Lenis | null = null;

export function initSmoothScroll(): () => void {
  const lenis = new Lenis({
    duration: 1.2,
    easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
    orientation: "vertical",
    smoothWheel: true,
  });

  lenisInstance = lenis;

  // Sync Lenis with GSAP ScrollTrigger
  lenis.on("scroll", ScrollTrigger.update);

  // GSAP ticker provides time in seconds; Lenis.raf() expects milliseconds
  const raf = (time: number) => lenis.raf(time * 1000);
  gsap.ticker.add(raf);
  gsap.ticker.lagSmoothing(0);

  return () => {
    gsap.ticker.remove(raf);
    lenis.destroy();
    lenisInstance = null;
  };
}

export function getLenis(): Lenis | null {
  return lenisInstance;
}
```

```ts
// Initialize on page load
const cleanup = initSmoothScroll();

// On teardown (e.g. SPA navigation):
// cleanup();
```

### Lenis + Anchor Links

```ts
// Smooth scroll to anchor
function scrollToSection(id: string) {
  const target = document.getElementById(id);
  if (target) {
    getLenis()?.scrollTo(target, { offset: -80, duration: 1.5 });
  }
}
```

### When NOT to Use Lenis

- Mobile-only apps (native scroll is better on mobile)
- Content-heavy text pages (blogs, docs) — users expect native scroll
- Accessibility: always provide `prefers-reduced-motion` fallback

---

## ScrollTrigger Patterns

### Pinned Section

Content stays pinned while sub-elements animate through scroll progress.

```ts
// Expected HTML:
// <div class="pinned-container">
//   <div class="panel min-h-screen">Panel 1</div>
//   <div class="panel min-h-screen">Panel 2</div>
//   <div class="panel min-h-screen">Panel 3</div>
// </div>

// Re-call this function when the number of panels changes
function createPinnedSection(container: HTMLElement): () => void {
  const ctx = gsap.context(() => {
    const panels = gsap.utils.toArray<HTMLElement>(".panel", container);

    panels.forEach((panel, i) => {
      if (i === 0) return; // First panel is visible by default

      ScrollTrigger.create({
        trigger: panel,
        start: "top top",
        pin: true,
        pinSpacing: false,
      });

      gsap.from(panel, {
        opacity: 0,
        y: 100,
        scrollTrigger: {
          trigger: panel,
          start: "top bottom",
          end: "top top",
          scrub: 1,
        },
      });
    });
  }, container);

  return () => ctx.revert();
}
```

### Horizontal Scroll Section

Transform vertical scroll into horizontal movement.

```ts
// Expected HTML:
// <div class="horizontal-container overflow-hidden">
//   <div class="horizontal-track flex w-max">
//     <section class="h-screen w-screen">Panel 1</section>
//     <section class="h-screen w-screen">Panel 2</section>
//     <section class="h-screen w-screen">Panel 3</section>
//   </div>
// </div>

function createHorizontalScroll(container: HTMLElement): () => void {
  const track = container.querySelector(".horizontal-track") as HTMLElement;

  const ctx = gsap.context(() => {
    const scrollWidth = track.scrollWidth - window.innerWidth;

    gsap.to(track, {
      x: -scrollWidth,
      ease: "none",
      scrollTrigger: {
        trigger: container,
        start: "top top",
        end: () => `+=${scrollWidth}`,
        pin: true,
        scrub: 1,
        invalidateOnRefresh: true,
      },
    });
  }, container);

  return () => ctx.revert();
}
```

### Scroll Progress Indicator

```ts
// Expected HTML:
// <div class="fixed top-0 left-0 right-0 z-50 h-1 bg-transparent">
//   <div class="progress-bar h-full origin-left bg-primary" style="transform:scaleX(0)"></div>
// </div>

function createScrollProgress(bar: HTMLElement): () => void {
  const ctx = gsap.context(() => {
    gsap.to(bar, {
      scaleX: 1,
      ease: "none",
      scrollTrigger: {
        trigger: document.documentElement,
        start: "top top",
        end: "bottom bottom",
        scrub: 0.3,
      },
    });
  });

  return () => ctx.revert();
}
```

### Parallax Layers

```ts
// Expected HTML:
// <div class="relative overflow-hidden">
//   <div class="parallax-layer" data-parallax-speed="0.3">
//     <img src="/bg.jpg" class="scale-125" />  <!-- scale to prevent gaps -->
//   </div>
//   <div class="parallax-layer" data-parallax-speed="0">
//     <h1>Static foreground</h1>
//   </div>
// </div>

// Re-call this function when speed changes
function createParallaxLayer(element: HTMLElement, speed: number = 0.5): () => void {
  const ctx = gsap.context(() => {
    gsap.to(element, {
      yPercent: speed * -50,
      ease: "none",
      scrollTrigger: {
        trigger: element,
        start: "top bottom",
        end: "bottom top",
        scrub: true,
      },
    });
  }, element);

  return () => ctx.revert();
}
```

### Scrub-Linked Progress Animation

Animate a property directly tied to scroll position (0-1 progress).

```ts
// Expected HTML:
// <svg viewBox="0 0 500 500" class="w-full">
//   <path class="scrub-path" d="M 10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80"
//         fill="none" stroke="currentColor" stroke-width="3" />
// </svg>

function createScrubPath(path: SVGPathElement): () => void {
  const ctx = gsap.context(() => {
    const length = path.getTotalLength();

    gsap.set(path, {
      strokeDasharray: length,
      strokeDashoffset: length,
    });

    gsap.to(path, {
      strokeDashoffset: 0,
      ease: "none",
      scrollTrigger: {
        trigger: path.closest("svg"),
        start: "top center",
        end: "bottom center",
        scrub: 1,
      },
    });
  });

  return () => ctx.revert();
}
```

---

## Snap Sections

Combine ScrollTrigger snap with full-screen sections.

```ts
function createSnapSections(container: HTMLElement): () => void {
  const ctx = gsap.context(() => {
    const sections = gsap.utils.toArray<HTMLElement>(".snap-section", container);

    sections.forEach((section) => {
      ScrollTrigger.create({
        trigger: section,
        start: "top top",
        snap: {
          snapTo: 1,
          duration: { min: 0.2, max: 0.6 },
          ease: "power2.inOut",
        },
      });
    });
  }, container);

  return () => ctx.revert();
}
```

---

## Mobile Considerations

- Disable parallax on mobile (GPU budget is limited): use `ScrollTrigger.matchMedia`
- Reduce stagger counts (fewer visible items)
- Avoid pinning on iOS Safari (scroll hijacking feels broken)
- Always test with Chrome DevTools device emulation AND real devices

```ts
ScrollTrigger.matchMedia({
  "(min-width: 768px)": function () {
    // Desktop animations with parallax, pins
  },
  "(max-width: 767px)": function () {
    // Simpler fade-in only
  },
});
```
