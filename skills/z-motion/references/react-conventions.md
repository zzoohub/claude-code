# React Conventions

React-specific patterns for the web animation stack. Read `web-conventions.md` first for core patterns -- this file covers only the React wrapper layer.

## Table of Contents

1. [GSAP Setup for React](#gsap-setup-for-react)
2. [useGSAP Hook](#usegsap-hook)
3. [SSR / Server Components](#ssr--server-components)
4. [D3 in React](#d3-in-react)
5. [Lenis in React](#lenis-in-react)
6. [Common React Gotchas](#common-react-gotchas)

---

## GSAP Setup for React

Extends the base setup with `@gsap/react`:

```tsx
// lib/gsap.ts
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

## useGSAP Hook

The single pattern for all GSAP animations in React. Handles `gsap.context()` creation and cleanup automatically:

```tsx
import { useRef } from "react";
import { gsap, useGSAP, ScrollTrigger } from "@/lib/gsap";

function AnimatedSection({ children }: { children: React.ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    // All GSAP code here -- scoped to ref, auto-cleaned on unmount
    gsap.from("[data-stagger]", {
      y: 40, opacity: 0,
      stagger: 0.08,
      scrollTrigger: { trigger: ref.current, start: "top 75%" },
    });
  }, { scope: ref });

  return <div ref={ref}>{children}</div>;
}
```

Key points:
- **`scope`**: scopes all selector-based animations to the container ref
- **`dependencies`**: re-runs when values change: `{ scope: ref, dependencies: [prop] }`
- Handles React strict mode (double mount) correctly
- Replaces manual `useEffect` + `gsap.context` + `ctx.revert()`

## SSR / Server Components

All animation components are client-side only:

```tsx
"use client"; // Required in Next.js App Router / any RSC framework

import { useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";

export function AnimatedHero() {
  // ... animation code
}
```

**Architecture guideline**: Server Components handle data fetching and layout. Client Components handle interactivity. The boundary:

```
ServerComponent (data, structure)
  +-- ClientAnimationWrapper ("use client")
       +-- children (can be server or client)
```

Ensure content is fully visible in server-rendered HTML before JS hydrates -- animations enhance, never gate content.

## D3 in React

D3 operates on refs, same as GSAP. Keep D3 code in effects:

```tsx
function BarChart({ data }: { data: BarDatum[] }) {
  const ref = useRef<HTMLDivElement>(null);
  const chartRef = useRef<ReturnType<typeof createBarChart>>();

  useEffect(() => {
    if (!ref.current) return;
    chartRef.current = createBarChart(ref.current, data);
    return () => chartRef.current?.destroy();
  }, []);

  useEffect(() => {
    chartRef.current?.update(data);
  }, [data]);

  return <div ref={ref} />;
}
```

## Lenis in React

```tsx
// components/smooth-scroll.tsx
"use client";

import { useEffect } from "react";
import Lenis from "lenis";
import { gsap, ScrollTrigger } from "@/lib/gsap";

export function SmoothScroll({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const lenis = new Lenis({ duration: 1.2, smoothWheel: true });
    lenis.on("scroll", ScrollTrigger.update);
    const raf = (time: number) => lenis.raf(time * 1000);
    gsap.ticker.add(raf);
    gsap.ticker.lagSmoothing(0);
    return () => {
      gsap.ticker.remove(raf);
      lenis.destroy();
    };
  }, []);

  return <>{children}</>;
}
```

## Common React Gotchas

1. **Refs are null with conditional rendering**: if a component returns `null` early, refs on hidden elements won't be populated when `useEffect`/`useGSAP` runs. Always render animation target elements (use `opacity: 0` instead of conditional `null`).
2. **`useGSAP` dependencies**: pass props that affect animation values. Without dependencies, animation runs once on mount only.
3. **Motion (Framer Motion) coexistence**: if migrating gradually, ensure GSAP and Motion don't animate the same element's `transform`. GSAP sets inline styles; Motion uses its own transform system. Property conflicts cause flickering.
4. **ScrollTrigger + layout shifts**: if React updates DOM after GSAP measures positions, call `ScrollTrigger.refresh()` after state updates that affect layout.
5. **Strict mode double-mount**: `useGSAP` handles this. Manual `useEffect` + `gsap.context` also works if you return `ctx.revert()` from cleanup.
