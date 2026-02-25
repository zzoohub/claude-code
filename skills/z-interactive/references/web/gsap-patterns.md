# GSAP Patterns

## Installation

```bash
npm install gsap @gsap/react
# ScrollTrigger, Flip, Observer are free plugins included in gsap package
# SplitText requires GSAP Club — use custom splitter below as free alternative
```

## Next.js Setup

```tsx
// lib/gsap.ts — centralized registration
"use client";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { Flip } from "gsap/Flip";
import { Observer } from "gsap/Observer";

if (typeof window !== "undefined") {
  gsap.registerPlugin(useGSAP, ScrollTrigger, Flip, Observer);
}

export { gsap, useGSAP, ScrollTrigger, Flip, Observer };
```

Always import from this file, not directly from `gsap`:
```tsx
import { gsap, useGSAP, ScrollTrigger } from "@/lib/gsap";
```

## Custom Text Splitter (Free Alternative to SplitText)

```tsx
// lib/split-text.ts
export function splitText(
  element: HTMLElement,
  type: "chars" | "words" = "chars"
) {
  const text = element.textContent || "";
  element.setAttribute("aria-label", text);

  if (type === "chars") {
    const words = text.split(" ");
    element.innerHTML = words
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
  } else if (type === "words") {
    element.innerHTML = text
      .split(" ")
      .map(
        (word) =>
          `<span class="word" style="display:inline-block" aria-hidden="true">${word}</span>`
      )
      .join('<span style="display:inline-block;width:0.25em" aria-hidden="true">&nbsp;</span>');
  }

  return {
    chars: Array.from(element.querySelectorAll(".char")),
    words: Array.from(element.querySelectorAll(".word")),
    revert: () => {
      element.innerHTML = text;
      element.removeAttribute("aria-label");
    },
  };
}
```

## Timeline Patterns

### Intro / Loading Sequence

```tsx
"use client";
import { useRef, useState } from "react";
import { gsap, useGSAP } from "@/lib/gsap";

export function IntroSequence({ onComplete }: { onComplete?: () => void }) {
  const overlayRef = useRef<HTMLDivElement>(null);
  const logoRef = useRef<HTMLDivElement>(null);
  const onCompleteRef = useRef(onComplete);
  onCompleteRef.current = onComplete;
  const [done, setDone] = useState(false);

  useGSAP(() => {
    const tl = gsap.timeline({
      onComplete: () => {
        setDone(true);
        onCompleteRef.current?.();
      },
    });

    tl.from(logoRef.current, {
      scale: 0.8,
      opacity: 0,
      duration: 0.6,
      ease: "back.out(1.7)",
    })
      .to(logoRef.current, {
        scale: 1.05,
        duration: 0.3,
        ease: "power2.inOut",
        yoyo: true,
        repeat: 1,
      })
      .to(overlayRef.current, {
        yPercent: -100,
        duration: 0.8,
        ease: "power4.inOut",
        delay: 0.3,
      });
  });

  if (done) return null;

  return (
    <div
      ref={overlayRef}
      className="fixed inset-0 z-[9999] flex items-center justify-center bg-black"
    >
      <div ref={logoRef}>
        {/* Logo or brand element */}
      </div>
    </div>
  );
}
```

### Staggered Section Reveal

```tsx
"use client";
import { useRef } from "react";
import { gsap, useGSAP, ScrollTrigger } from "@/lib/gsap";

export function StaggerSection({ children }: { children: React.ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    const items = ref.current!.querySelectorAll("[data-stagger]");

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
        trigger: ref.current,
        start: "top 75%",
        toggleActions: "play none none none",
      },
    });
  }, { scope: ref });

  return <div ref={ref}>{children}</div>;
}

// Usage:
// <StaggerSection>
//   <Card data-stagger>...</Card>
//   <Card data-stagger>...</Card>
//   <Card data-stagger>...</Card>
// </StaggerSection>
```

## Number Counter / Roll-Up

```tsx
"use client";
import { useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";

export function Counter({
  end,
  duration = 2,
  suffix = "",
  prefix = "",
}: {
  end: number;
  duration?: number;
  suffix?: string;
  prefix?: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);

  useGSAP(() => {
    const obj = { value: 0 };

    gsap.to(obj, {
      value: end,
      duration,
      ease: "power2.out",
      scrollTrigger: {
        trigger: ref.current,
        start: "top 85%",
        toggleActions: "play none none none",
      },
      onUpdate: () => {
        if (ref.current) {
          ref.current.textContent = `${prefix}${Math.round(obj.value).toLocaleString()}${suffix}`;
        }
      },
    });
  }, { dependencies: [end, duration, suffix, prefix] });

  return <span ref={ref}>0</span>;
}
```

## Image / Clip-Path Reveal

```tsx
"use client";
import { useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";

export function ImageReveal({ children }: { children: React.ReactNode }) {
  const wrapperRef = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    gsap.from(wrapperRef.current, {
      clipPath: "inset(100% 0 0 0)",
      duration: 1,
      ease: "power4.inOut",
      scrollTrigger: {
        trigger: wrapperRef.current,
        start: "top 80%",
        toggleActions: "play none none none",
      },
    });

    // Optional: inner image scale for parallax feel
    const img = wrapperRef.current!.querySelector("img, video");
    if (img) {
      gsap.from(img, {
        scale: 1.3,
        duration: 1.2,
        ease: "power4.inOut",
        scrollTrigger: {
          trigger: wrapperRef.current,
          start: "top 80%",
          toggleActions: "play none none none",
        },
      });
    }
  }, { scope: wrapperRef });

  return (
    <div ref={wrapperRef} style={{ overflow: "hidden" }}>
      {children}
    </div>
  );
}
```

## Infinite Marquee

```tsx
"use client";
import { useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";

export function Marquee({
  children,
  speed = 50,
  direction = "left",
}: {
  children: React.ReactNode;
  speed?: number; // pixels per second
  direction?: "left" | "right";
}) {
  const trackRef = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    const track = trackRef.current!;
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
  }, { dependencies: [speed, direction] });

  return (
    <div className="overflow-hidden">
      <div ref={trackRef} className="flex w-max">
        {children}
        {children} {/* Duplicate for seamless loop */}
      </div>
    </div>
  );
}
```

## useGSAP Hook (Recommended Cleanup Pattern)

Use `useGSAP` from `@gsap/react` instead of manual `useEffect` + `gsap.context`:

```tsx
import { useGSAP } from "@gsap/react";

useGSAP(() => {
  // All GSAP animations here — automatically scoped and cleaned up
  gsap.to(".box", { x: 100 });
  ScrollTrigger.create({ ... });
}, { scope: containerRef }); // Scope to container
```

Why `useGSAP` over manual context:
- Handles `gsap.context()` creation and `ctx.revert()` cleanup automatically
- Scopes all selector-based animations to the container ref
- Prevents memory leaks in React strict mode (double mount)
- Accepts `dependencies` array for re-running: `{ scope: ref, dependencies: [prop] }`

## GSAP as the Single Animation Engine

GSAP handles all DOM animation in this stack. There is no second animation library. This eliminates:
- Property conflicts (two libraries fighting over the same `transform`)
- Bundle duplication (no redundant spring/tween engines)
- Mental overhead (one API to learn, one cleanup pattern)

**If the project has Framer Motion / Motion**: replace it with GSAP. Framer Motion re-renders React components on every frame through state updates; GSAP mutates the DOM directly, bypassing React's reconciliation — the performance gap is measurable on pages with many simultaneous animations. For common Framer Motion patterns:
- `motion.div` with `animate` prop → `gsap.to()` with ref or `data-*` selector
- `AnimatePresence` enter/exit → CSS `@starting-style` (simple) or GSAP timeline with `onComplete` removal (complex)
- `useScroll` / `useTransform` → GSAP ScrollTrigger
- `layout` prop → GSAP Flip plugin
- `whileHover` → CSS `:hover` for simple states, GSAP for magnetic/tilt effects

For enter/exit animations, use either:
- CSS `@starting-style` + `transition-behavior: allow-discrete` (zero JS, see `css-native-motion.md`)
- GSAP timeline with `onComplete` callback for removal
