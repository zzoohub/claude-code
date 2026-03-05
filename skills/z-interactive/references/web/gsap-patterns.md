# GSAP Patterns

> React implementation: `../react/gsap-patterns.md`

## Installation

```bash
npm install gsap
# ScrollTrigger, Flip, Observer are free plugins included in gsap package
# SplitText requires GSAP Club — use custom splitter below as free alternative
```

## Setup

```ts
// lib/gsap.ts — centralized registration
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { Flip } from "gsap/Flip";
import { Observer } from "gsap/Observer";

gsap.registerPlugin(ScrollTrigger, Flip, Observer);

export { gsap, ScrollTrigger, Flip, Observer };
```

Always import from this file, not directly from `gsap`:
```ts
import { gsap, ScrollTrigger } from "@/lib/gsap";
```

## Cleanup Pattern: gsap.context()

Use `gsap.context()` to scope animations to a container and batch-revert them on teardown:

```ts
function initAnimation(container: HTMLElement) {
  const ctx = gsap.context(() => {
    // All GSAP animations here — automatically scoped to container
    gsap.to(".box", { x: 100 });
    ScrollTrigger.create({ trigger: ".section", /* ... */ });
  }, container); // Scope to container element

  // Call ctx.revert() when done (e.g. page teardown, element removal)
  return () => ctx.revert();
}
```

Why `gsap.context()`:
- Scopes all selector-based animations to the container element
- `ctx.revert()` kills all animations and ScrollTriggers created inside
- Prevents memory leaks when elements are removed from the DOM
- Re-initialize by calling the factory function again when inputs change

## Custom Text Splitter (Free Alternative to SplitText)

```ts
// lib/split-text.ts
// NOTE: This utility uses innerHTML to split text nodes into individual
// <span> elements for character/word animation. The input is always the
// element's own textContent — no user-supplied HTML is inserted.

export function splitText(
  element: HTMLElement,
  type: "chars" | "words" = "chars"
) {
  const text = element.textContent || "";
  element.setAttribute("aria-label", text);

  if (type === "chars") {
    const words = text.split(" ");
    const html = words
      .map(
        (word) =>
          `<span class="word" style="display:inline-block;white-space:nowrap">${word
            .split("")
            .map(
              (char) =>
                `<span class="char" style="display:inline-block" aria-hidden="true">${char}</span>`
            )
            .join("")}</span>`
      )
      .join('<span style="display:inline-block;width:0.25em" aria-hidden="true">&nbsp;</span>');
    element.innerHTML = html; // safe: derived from element's own textContent
  } else if (type === "words") {
    const html = text
      .split(" ")
      .map(
        (word) =>
          `<span class="word" style="display:inline-block" aria-hidden="true">${word}</span>`
      )
      .join('<span style="display:inline-block;width:0.25em" aria-hidden="true">&nbsp;</span>');
    element.innerHTML = html; // safe: derived from element's own textContent
  }

  return {
    chars: Array.from(element.querySelectorAll(".char")),
    words: Array.from(element.querySelectorAll(".word")),
    revert: () => {
      element.textContent = text;
      element.removeAttribute("aria-label");
    },
  };
}
```

## Timeline Patterns

### Intro / Loading Sequence

```ts
// Expected HTML:
// <div class="intro-overlay" style="position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;background:black">
//   <div class="intro-logo"><!-- Logo or brand element --></div>
// </div>

interface IntroOptions {
  onComplete?: () => void;
}

function createIntroSequence(
  overlay: HTMLElement,
  options?: IntroOptions
): () => void {
  const logo = overlay.querySelector(".intro-logo") as HTMLElement;

  const ctx = gsap.context(() => {
    const tl = gsap.timeline({
      onComplete: () => {
        overlay.remove();
        options?.onComplete?.();
      },
    });

    tl.from(logo, {
      scale: 0.8,
      opacity: 0,
      duration: 0.6,
      ease: "back.out(1.7)",
    })
      .to(logo, {
        scale: 1.05,
        duration: 0.3,
        ease: "power2.inOut",
        yoyo: true,
        repeat: 1,
      })
      .to(overlay, {
        yPercent: -100,
        duration: 0.8,
        ease: "power4.inOut",
        delay: 0.3,
      });
  }, overlay);

  return () => ctx.revert();
}
```

### Staggered Section Reveal

```ts
// Expected HTML:
// <div class="stagger-section">
//   <div data-stagger>...</div>
//   <div data-stagger>...</div>
//   <div data-stagger>...</div>
// </div>

function createStaggerReveal(element: HTMLElement): () => void {
  const ctx = gsap.context(() => {
    const items = element.querySelectorAll("[data-stagger]");

    gsap.from(items, {
      y: 40,
      opacity: 0,
      stagger: {
        each: 0.08,
        from: "start",
      },
      duration: 0.6,
      ease: "power3.out",
      scrollTrigger: {
        trigger: element,
        start: "top 75%",
        toggleActions: "play none none none",
      },
    });
  }, element);

  return () => ctx.revert();
}
```

## Number Counter / Roll-Up

```ts
// Expected HTML:
// <span class="counter">0</span>

interface CounterOptions {
  end: number;
  duration?: number;
  suffix?: string;
  prefix?: string;
}

// Re-call this function when options change (e.g. new end value)
function createCounter(element: HTMLElement, options: CounterOptions): () => void {
  const { end, duration = 2, suffix = "", prefix = "" } = options;

  const ctx = gsap.context(() => {
    const obj = { value: 0 };

    gsap.to(obj, {
      value: end,
      duration,
      ease: "power2.out",
      scrollTrigger: {
        trigger: element,
        start: "top 85%",
        toggleActions: "play none none none",
      },
      onUpdate: () => {
        element.textContent = `${prefix}${Math.round(obj.value).toLocaleString()}${suffix}`;
      },
    });
  }, element);

  return () => ctx.revert();
}
```

## Image / Clip-Path Reveal

```ts
// Expected HTML:
// <div class="image-reveal" style="overflow:hidden">
//   <img src="..." alt="..." />
// </div>

function createImageReveal(element: HTMLElement): () => void {
  const ctx = gsap.context(() => {
    gsap.from(element, {
      clipPath: "inset(100% 0 0 0)",
      duration: 1,
      ease: "power4.inOut",
      scrollTrigger: {
        trigger: element,
        start: "top 80%",
        toggleActions: "play none none none",
      },
    });

    // Optional: inner image scale for parallax feel
    const img = element.querySelector("img, video");
    if (img) {
      gsap.from(img, {
        scale: 1.3,
        duration: 1.2,
        ease: "power4.inOut",
        scrollTrigger: {
          trigger: element,
          start: "top 80%",
          toggleActions: "play none none none",
        },
      });
    }
  }, element);

  return () => ctx.revert();
}
```

## Infinite Marquee

```ts
// Expected HTML:
// <div class="overflow-hidden">
//   <div class="marquee-track flex w-max">
//     <div class="marquee-content">...</div>
//     <div class="marquee-content">...</div>  <!-- Duplicate for seamless loop -->
//   </div>
// </div>

interface MarqueeOptions {
  speed?: number; // pixels per second
  direction?: "left" | "right";
}

// Re-call this function when speed or direction changes
function createMarquee(track: HTMLElement, options?: MarqueeOptions): () => void {
  const { speed = 50, direction = "left" } = options ?? {};

  const ctx = gsap.context(() => {
    const firstChild = track.children[0] as HTMLElement;
    const width = firstChild.offsetWidth;

    gsap.set(track, { x: 0 });

    gsap.to(track, {
      x: direction === "left" ? -width : width,
      duration: width / speed,
      ease: "none",
      repeat: -1,
      modifiers: {
        x: gsap.utils.unitize((x) => parseFloat(x) % width),
      },
    });
  }, track);

  return () => ctx.revert();
}
```

## gsap.context() Cleanup Pattern (Recommended)

Use `gsap.context()` with manual `ctx.revert()` for all animations:

```ts
const ctx = gsap.context(() => {
  // All GSAP animations here — automatically scoped and cleaned up
  gsap.to(".box", { x: 100 });
  ScrollTrigger.create({ /* ... */ });
}, containerElement); // Scope to container

// When tearing down:
ctx.revert();
```

Why `gsap.context()`:
- Handles cleanup of all animations and ScrollTriggers created inside
- Scopes all selector-based animations to the container element
- Prevents memory leaks when removing elements from the DOM
- Factory function pattern: return `() => ctx.revert()` for easy teardown

## GSAP as the Single Animation Engine

GSAP handles all DOM animation in this stack. There is no second animation library. This eliminates:
- Property conflicts (two libraries fighting over the same `transform`)
- Bundle duplication (no redundant spring/tween engines)
- Mental overhead (one API to learn, one cleanup pattern)

**If the project has Framer Motion / Motion**: replace it with GSAP. Framer Motion re-renders components on every frame through state updates; GSAP mutates the DOM directly — the performance gap is measurable on pages with many simultaneous animations. For common Framer Motion patterns:
- `motion.div` with `animate` prop → `gsap.to()` with `data-*` selector
- `AnimatePresence` enter/exit → CSS `@starting-style` (simple) or GSAP timeline with `onComplete` removal (complex)
- `useScroll` / `useTransform` → GSAP ScrollTrigger
- `layout` prop → GSAP Flip plugin
- `whileHover` → CSS `:hover` for simple states, GSAP for magnetic/tilt effects

For enter/exit animations, use either:
- CSS `@starting-style` + `transition-behavior: allow-discrete` (zero JS, see `css-native-motion.md`)
- GSAP timeline with `onComplete` callback for removal
