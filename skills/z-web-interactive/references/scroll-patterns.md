# Scroll Patterns

## Smooth Scroll with Lenis

### Installation

```bash
npm install lenis
```

### Global Setup (Next.js App Router)

```tsx
// components/smooth-scroll.tsx
"use client";
import { useEffect, useRef } from "react";
import Lenis from "lenis";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function SmoothScroll({ children }: { children: React.ReactNode }) {
  const lenisRef = useRef<Lenis | null>(null);

  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      orientation: "vertical",
      smoothWheel: true,
    });

    lenisRef.current = lenis;

    // Sync Lenis with GSAP ScrollTrigger
    lenis.on("scroll", ScrollTrigger.update);

    gsap.ticker.add((time) => {
      lenis.raf(time * 1000);
    });

    gsap.ticker.lagSmoothing(0);

    return () => {
      lenis.destroy();
      gsap.ticker.remove(lenis.raf);
    };
  }, []);

  return <>{children}</>;
}
```

```tsx
// app/layout.tsx
import { SmoothScroll } from "@/components/smooth-scroll";

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <SmoothScroll>{children}</SmoothScroll>
      </body>
    </html>
  );
}
```

### Lenis + Anchor Links

```tsx
// Smooth scroll to anchor
function scrollToSection(id: string) {
  const target = document.getElementById(id);
  if (target) {
    lenisRef.current?.scrollTo(target, { offset: -80, duration: 1.5 });
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

```tsx
"use client";
import { useRef, useEffect } from "react";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function PinnedSection({
  children,
  panels,
}: {
  children: React.ReactNode;
  panels: React.ReactNode[];
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const panelRefs = useRef<HTMLDivElement[]>([]);

  useEffect(() => {
    const ctx = gsap.context(() => {
      panels.forEach((_, i) => {
        if (i === 0) return; // First panel is visible by default

        ScrollTrigger.create({
          trigger: panelRefs.current[i],
          start: "top top",
          pin: true,
          pinSpacing: false,
        });

        gsap.from(panelRefs.current[i], {
          opacity: 0,
          y: 100,
          scrollTrigger: {
            trigger: panelRefs.current[i],
            start: "top bottom",
            end: "top top",
            scrub: 1,
          },
        });
      });
    }, containerRef);

    return () => ctx.revert();
  }, [panels.length]);

  return (
    <div ref={containerRef}>
      {panels.map((panel, i) => (
        <div
          key={i}
          ref={(el) => { if (el) panelRefs.current[i] = el; }}
          className="min-h-screen"
        >
          {panel}
        </div>
      ))}
    </div>
  );
}
```

### Horizontal Scroll Section

Transform vertical scroll into horizontal movement.

```tsx
"use client";
import { useRef, useEffect } from "react";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function HorizontalScroll({ children }: { children: React.ReactNode }) {
  const containerRef = useRef<HTMLDivElement>(null);
  const trackRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      const track = trackRef.current!;
      const scrollWidth = track.scrollWidth - window.innerWidth;

      gsap.to(track, {
        x: -scrollWidth,
        ease: "none",
        scrollTrigger: {
          trigger: containerRef.current,
          start: "top top",
          end: () => `+=${scrollWidth}`,
          pin: true,
          scrub: 1,
          invalidateOnRefresh: true,
        },
      });
    }, containerRef);

    return () => ctx.revert();
  }, []);

  return (
    <div ref={containerRef} className="overflow-hidden">
      <div ref={trackRef} className="flex w-max">
        {children}
      </div>
    </div>
  );
}

// Usage:
// <HorizontalScroll>
//   <section className="h-screen w-screen">Panel 1</section>
//   <section className="h-screen w-screen">Panel 2</section>
//   <section className="h-screen w-screen">Panel 3</section>
// </HorizontalScroll>
```

### Scroll Progress Indicator

```tsx
"use client";
import { useRef, useEffect } from "react";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function ScrollProgress() {
  const barRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    gsap.to(barRef.current, {
      scaleX: 1,
      ease: "none",
      scrollTrigger: {
        trigger: document.documentElement,
        start: "top top",
        end: "bottom bottom",
        scrub: 0.3,
      },
    });
  }, []);

  return (
    <div className="fixed top-0 left-0 right-0 z-50 h-1 bg-transparent">
      <div
        ref={barRef}
        className="h-full origin-left bg-primary"
        style={{ transform: "scaleX(0)" }}
      />
    </div>
  );
}
```

### Parallax Layers

```tsx
"use client";
import { useRef, useEffect } from "react";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function ParallaxLayer({
  children,
  speed = 0.5,
}: {
  children: React.ReactNode;
  speed?: number; // 0 = no parallax, 1 = full speed, negative = reverse
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.to(ref.current, {
        yPercent: speed * -50,
        ease: "none",
        scrollTrigger: {
          trigger: ref.current,
          start: "top bottom",
          end: "bottom top",
          scrub: true,
        },
      });
    }, ref);

    return () => ctx.revert();
  }, [speed]);

  return <div ref={ref}>{children}</div>;
}

// Usage:
// <div className="relative overflow-hidden">
//   <ParallaxLayer speed={0.3}>
//     <Image src="/bg.jpg" className="scale-125" />  {/* scale to prevent gaps */}
//   </ParallaxLayer>
//   <ParallaxLayer speed={0}>
//     <h1>Static foreground</h1>
//   </ParallaxLayer>
// </div>
```

### Scrub-Linked Progress Animation

Animate a property directly tied to scroll position (0-1 progress).

```tsx
"use client";
import { useRef, useEffect } from "react";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function ScrubPath() {
  const pathRef = useRef<SVGPathElement>(null);

  useEffect(() => {
    const path = pathRef.current!;
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
  }, []);

  return (
    <svg viewBox="0 0 500 500" className="w-full">
      <path
        ref={pathRef}
        d="M 10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80"
        fill="none"
        stroke="currentColor"
        strokeWidth="3"
      />
    </svg>
  );
}
```

---

## Snap Sections

Combine ScrollTrigger snap with full-screen sections.

```tsx
useEffect(() => {
  const sections = gsap.utils.toArray<HTMLElement>(".snap-section");

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
}, []);
```

---

## Mobile Considerations

- Disable parallax on mobile (GPU budget is limited): use `ScrollTrigger.matchMedia`
- Reduce stagger counts (fewer visible items)
- Avoid pinning on iOS Safari (scroll hijacking feels broken)
- Always test with Chrome DevTools device emulation AND real devices

```tsx
ScrollTrigger.matchMedia({
  "(min-width: 768px)": function () {
    // Desktop animations with parallax, pins
  },
  "(max-width: 767px)": function () {
    // Simpler fade-in only
  },
});
```
