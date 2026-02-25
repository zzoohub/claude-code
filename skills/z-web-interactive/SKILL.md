---
name: z-web-interactive
description: |
  Advanced interactive motion and visual effects using GSAP (primary), Three.js WebGPU, Lenis, and CSS native APIs.
  Use when: adding scroll-triggered animations, building 3D scenes or WebGPU effects, creating parallax or reveal animations, implementing smooth scrolling, building cursor/mouse-following effects, creating page transitions, adding particle systems, building interactive hero sections, implementing text split animations, creating loading/intro sequences, adding hover effects beyond CSS, building interactive backgrounds, or any task involving "make it more dynamic", "add wow factor", "interactive", "immersive", "cinematic", "3D effect", "scroll animation", "parallax", "reveal on scroll", "mouse follow", "creative landing page".
  Do not use for: basic CSS transitions or hover states (use z-design-system motion tokens), layout/component structure, routing or data fetching (use z-nextjs), UX flows or user journeys (use z-ux-design).
  Workflow: z-ux-design (journey) → z-design-system (tokens) → frontend-design skill → z-interactive-engineer (agent) → **this skill** (implementation) → z-nextjs (integration).
references:
  - references/gsap-patterns.md
  - references/scroll-patterns.md
  - references/cursor-and-hover.md
  - references/threejs-patterns.md
  - references/css-native-motion.md
  - references/page-transitions.md
  - references/performance.md
---

# Interactive Motion

## Philosophy

Motion is a design material, not decoration. Every animation must serve one of three purposes: **guide attention**, **communicate relationships**, or **create emotional response**. If it doesn't do one of these, remove it.

These principles are grounded in neuroscience. Key constraints to internalize:
- **Stagger 50–100ms**: Creates distinct perceptual events within working memory (~4 chunk limit)
- **ease-out on entrance**: Matches real-world deceleration → brain predicts landing position
- **Parallax depth**: Triggers motion parallax depth cue — faster foreground = perceptually closer
- **Max simultaneous animations**: Keep to 3–4 concurrent motion groups per viewport (working memory limit)

## Technology Stack

Three libraries. No overlap. No redundancy.

| Library | Role | Size | Thread |
|---------|------|------|--------|
| **GSAP** + ScrollTrigger | All DOM animation: timelines, scroll choreography, stagger, text split, cursor interactions | ~35KB | Main thread (JS) |
| **Three.js** WebGPU / R3F | 3D scenes, particles, shaders, GPU compute | ~150-180KB | GPU |
| **Lenis** | Smooth scroll feel | ~8KB | Main thread (JS) |

**GSAP is the primary animation engine.** It handles everything from simple reveals to complex multi-step scroll choreography. It works perfectly with Tailwind — GSAP operates in JS on `transform`/`opacity` while Tailwind handles layout and styling. Zero conflict.

**CSS native APIs** (scroll-driven animations, View Transitions, @starting-style) are used only for specific cases where zero-JS is a genuine advantage — see below.

### When to Use CSS Native Instead of GSAP

CSS native APIs run on the **compositor thread** (off main thread). This matters when:

| Use CSS Native When | Why |
|--------------------|----|
| Page transitions between routes | View Transitions API — browser handles morphing, no JS needed |
| Scroll progress bar (simple scaleX on scroll) | `animation-timeline: scroll()` — one line of CSS, no GSAP import needed |
| Simple single-element reveal on scroll (no stagger, no callback) | `animation-timeline: view()` — works without JS, progressive enhancement |

For anything involving **stagger, pin, snap, scrub, callbacks, dynamic values, text splitting, or timelines** — use GSAP. CSS native APIs cannot express these.

→ CSS native patterns: `references/css-native-motion.md`

### When to Use Three.js

| Three.js | Not Three.js |
|----------|-------------|
| 3D hero backgrounds | 2D parallax (GSAP) |
| Particle systems (1K+) | Fade-ins (GSAP) |
| Custom shaders / materials | Color transitions (CSS) |
| Scroll-linked 3D rotation | Text animation (GSAP) |
| Image hover distortion | Element enter/exit (GSAP or CSS) |

**WebGPU-first, WebGL fallback.** See `references/threejs-patterns.md`.

## Decision Flowchart

```
Need animation?
│
├─ Scroll-linked?
│  ├─ Simple (one element, fade/slide, no stagger) → CSS animation-timeline: view()
│  ├─ Progress bar → CSS animation-timeline: scroll()
│  └─ Everything else (stagger, pin, scrub, snap, callbacks) → GSAP ScrollTrigger
│
├─ Timeline sequence (A→B→C with timing)?
│  └─ → GSAP timeline
│
├─ Text character/word animation?
│  └─ → GSAP + custom splitter
│
├─ Route/page transition?
│  ├─ Cross-fade, shared element morph → View Transitions API (CSS)
│  └─ Complex overlay wipe with callbacks → GSAP timeline
│
├─ 3D / GPU-computed?
│  └─ → Three.js WebGPU
│
├─ Cursor/mouse interaction?
│  ├─ Simple hover color/scale → CSS/Tailwind :hover
│  └─ Magnetic, tilt, custom cursor, spotlight → GSAP
│
├─ Smooth scroll feel?
│  └─ → Lenis
│
└─ Basic hover state?
   └─ → Tailwind/CSS (not this skill — use z-design-system)
```

## Core Patterns

### 1. Scroll Reveal (GSAP — the workhorse)

```tsx
"use client";
import { useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";

export function RevealOnScroll({ children, stagger = 0.08 }: {
  children: React.ReactNode;
  stagger?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    gsap.from("[data-reveal]", {
      y: 40,
      opacity: 0,
      stagger,
      duration: 0.6,
      ease: "power3.out",
      scrollTrigger: {
        trigger: ref.current,
        start: "top 75%",
        toggleActions: "play none none none",
      },
    });
  }, { scope: ref, dependencies: [stagger] });

  return <div ref={ref}>{children}</div>;
}
```

Tailwind handles layout, GSAP handles motion:
```tsx
<RevealOnScroll>
  <div data-reveal className="grid grid-cols-3 gap-6">
    <Card data-reveal className="rounded-xl bg-white p-6 shadow-lg" />
    <Card data-reveal className="rounded-xl bg-white p-6 shadow-lg" />
    <Card data-reveal className="rounded-xl bg-white p-6 shadow-lg" />
  </div>
</RevealOnScroll>
```

→ Pin, horizontal scroll, parallax, snap: `references/scroll-patterns.md`

### 2. Text Split Animation (GSAP)

```tsx
"use client";
import { useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";
import { splitText } from "@/lib/split-text";

export function AnimatedHeading({ text, as: Tag = "h1" }: {
  text: string;
  as?: React.ElementType;
}) {
  const ref = useRef<HTMLElement>(null);

  useGSAP(() => {
    const { chars, revert } = splitText(ref.current!, "chars");
    gsap.from(chars, {
      y: 80, opacity: 0, rotateX: -40,
      stagger: 0.03, duration: 0.7, ease: "power4.out",
    });
    return () => revert();
  }, { scope: ref });

  return <Tag ref={ref}>{text}</Tag>;
}
```

→ Custom splitter utility, more text patterns: `references/gsap-patterns.md`

### 3. Cursor / Mouse Interaction (GSAP)

```tsx
"use client";
import { useRef } from "react";
import { gsap, useGSAP } from "@/lib/gsap";

export function MagneticButton({ children, strength = 0.3 }: {
  children: React.ReactNode;
  strength?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useGSAP(() => {
    if ("ontouchstart" in window) return;
    const el = ref.current!;

    // quickTo creates a reusable tween — much more efficient than gsap.to() per mousemove
    const xTo = gsap.quickTo(el, "x", { duration: 0.3, ease: "power2.out" });
    const yTo = gsap.quickTo(el, "y", { duration: 0.3, ease: "power2.out" });

    const move = (e: MouseEvent) => {
      const { left, top, width, height } = el.getBoundingClientRect();
      xTo((e.clientX - left - width / 2) * strength);
      yTo((e.clientY - top - height / 2) * strength);
    };
    const leave = () => gsap.to(el, { x: 0, y: 0, duration: 0.5, ease: "elastic.out(1, 0.3)" });

    el.addEventListener("mousemove", move);
    el.addEventListener("mouseleave", leave);
    return () => { el.removeEventListener("mousemove", move); el.removeEventListener("mouseleave", leave); };
  }, { scope: ref, dependencies: [strength] });

  return <div ref={ref} className="inline-block">{children}</div>;
}
```

→ Custom cursor, tilt card, spotlight, parallax mouse: `references/cursor-and-hover.md`

### 4. 3D Scenes (Three.js WebGPU)

```tsx
"use client";
import { Canvas, useFrame } from "@react-three/fiber";
import { useRef } from "react";

function FloatingShape() {
  const meshRef = useRef();
  useFrame(({ clock }) => {
    meshRef.current.rotation.y = clock.elapsedTime * 0.3;
    meshRef.current.position.y = Math.sin(clock.elapsedTime * 0.5) * 0.3;
  });
  return (
    <mesh ref={meshRef}>
      <torusKnotGeometry args={[1, 0.3, 128, 32]} />
      <meshStandardMaterial color="#6366f1" roughness={0.2} metalness={0.8} />
    </mesh>
  );
}

export function HeroScene() {
  return (
    <div className="absolute inset-0 -z-10">
      <Canvas camera={{ position: [0, 0, 5], fov: 45 }}>
        <ambientLight intensity={0.5} />
        <directionalLight position={[5, 5, 5]} intensity={1} />
        <FloatingShape />
      </Canvas>
    </div>
  );
}
```

→ WebGPU renderer, particles, shaders, scroll-linked 3D: `references/threejs-patterns.md`

### 5. Page Transitions (View Transitions API)

**Choose the transition pattern based on the relationship between views:**

| Pattern | Implementation | When |
|---------|---------------|------|
| **Container Transform** | View Transitions API with `view-transition-name` on shared element | Card → detail page |
| **Shared Axis** | View Transitions with directional slide (`translateX`) | Tab switching, wizard steps |
| **Fade Through** | Default cross-fade via View Transitions | Unrelated page → page |
| **Fade** | Simple opacity transition | Modal, toast, overlay |
| **Complex wipe** | GSAP timeline overlay (not View Transitions) | Cinematic/immersive transitions |

```tsx
// components/transition-link.tsx — triggers native View Transitions
"use client";
import { useRouter } from "next/navigation";

export function TransitionLink({ href, children, className }: {
  href: string;
  children: React.ReactNode;
  className?: string;
}) {
  const router = useRouter();
  const handleClick = (e: React.MouseEvent) => {
    e.preventDefault();
    if (!document.startViewTransition) { router.push(href); return; }
    document.startViewTransition(() => router.push(href));
  };
  return <a href={href} onClick={handleClick} className={className}>{children}</a>;
}
```

```css
/* globals.css — Fade Through (default for unrelated pages) */
::view-transition-old(root) { animation: 0.25s ease-out both fade-out; }
::view-transition-new(root) { animation: 0.25s ease-out both fade-in; }
@keyframes fade-out { to { opacity: 0; } }
@keyframes fade-in { from { opacity: 0; } }
```

```css
/* Container Transform — shared element expands into detail */
.product-card { view-transition-name: product-hero; }
.product-detail-image { view-transition-name: product-hero; }

::view-transition-group(product-hero) {
  animation-duration: 0.35s;
  animation-timing-function: cubic-bezier(0.22, 1, 0.36, 1);
}
```

→ Shared elements, GSAP overlay wipes: `references/page-transitions.md`

### 6. Smooth Scroll (Lenis)

```tsx
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
    return () => { gsap.ticker.remove(raf); lenis.destroy(); };
  }, []);
  return <>{children}</>;
}
```

→ Full setup, anchor links, mobile considerations: `references/scroll-patterns.md`

## Tailwind + GSAP Workflow

Tailwind owns **layout and styling**. GSAP owns **motion**. They never overlap.

```tsx
{/* Tailwind: structure, spacing, colors, responsive */}
<section className="relative flex min-h-screen items-center justify-center bg-black px-6">

  {/* GSAP: motion via data attributes */}
  <h1 data-reveal className="text-5xl font-bold text-white md:text-7xl">
    Heading
  </h1>

  {/* Three.js: 3D background, completely separate layer */}
  <div className="absolute inset-0 -z-10">
    <HeroScene />
  </div>
</section>
```

GSAP targets elements via `data-*` attributes or refs — never conflicts with Tailwind classes.

## Integration with Existing Skills

### With z-design-system
- Motion tokens (`duration.normal`, `easing.enter`) as CSS custom properties
- GSAP can read them: `gsap.to(el, { duration: parseFloat(getComputedStyle(el).getPropertyValue("--duration-normal")) })`
- Or just use GSAP's own easing — it's more expressive

### With expo-app-design:building-native-ui
- Never modify component internals
- Wrap: `<RevealOnScroll><Card>...</Card></RevealOnScroll>`
- Or mark targets: `<Card data-reveal>`
- Motion logic lives in `components/motion/`, not inside component files

### With z-nextjs
- GSAP/Three.js components: always `"use client"`
- Lazy-load Three.js: `dynamic(() => import('./scene'), { ssr: false })`
- Clean up: `useGSAP` handles cleanup automatically, `lenis.destroy()`, `cancelAnimationFrame()`
- CSS native features (View Transitions, scroll-driven animations) work with SSR

## Accessibility — Non-Negotiable

```css
/* CSS-level: kills all animations globally for reduced motion */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

```tsx
// JS-level: for GSAP and Three.js components
import { useReducedMotion } from "@/hooks/use-reduced-motion";

export function AnimatedComponent({ children }) {
  if (useReducedMotion()) return <div>{children}</div>;
  return <AnimatedVersion>{children}</AnimatedVersion>;
}
```

→ `useReducedMotion` hook, device tier detection: `references/performance.md`

## Performance Rules

1. **Animate `transform` and `opacity` only** — GPU-composited, no layout/paint
2. **useGSAP for cleanup** — handles `gsap.context` automatically, no manual `ctx.revert()`
3. **Lazy-load Three.js** — always `dynamic(() => import(), { ssr: false })`
4. **60fps** — profile with Chrome DevTools Performance tab
5. **Mobile**: disable parallax, reduce particles 75%, no hover effects
6. **`will-change` sparingly** — GSAP's `force3D` handles layer promotion

→ Full guide: `references/performance.md`

## File Organization

```
components/
├── motion/              # GSAP animation wrappers
│   ├── reveal-on-scroll.tsx
│   ├── animated-heading.tsx
│   ├── stagger-section.tsx
│   ├── magnetic.tsx
│   ├── tilt-card.tsx
│   ├── custom-cursor.tsx
│   └── smooth-scroll.tsx
├── scenes/              # Three.js 3D scenes
│   ├── hero-scene.tsx
│   ├── particle-field.tsx
│   └── gradient-background.tsx
├── transitions/         # Page transition components
│   └── transition-link.tsx
hooks/
├── use-reduced-motion.ts
└── use-device-tier.ts
lib/
├── gsap.ts              # Centralized GSAP + useGSAP registration
├── gpu-renderer.ts      # WebGPU detection + fallback
└── split-text.ts        # Custom text splitter (free SplitText alternative)
```

## Quick Reference

| Want | Use | Reference |
|------|-----|-----------|
| Fade/slide on scroll (single) | CSS `animation-timeline: view()` | `css-native-motion.md` |
| Stagger reveal on scroll | GSAP ScrollTrigger | `gsap-patterns.md` |
| Pinned section with scrub | GSAP ScrollTrigger pin | `scroll-patterns.md` |
| Horizontal scroll section | GSAP ScrollTrigger | `scroll-patterns.md` |
| Parallax layers | GSAP ScrollTrigger | `scroll-patterns.md` |
| Text character animation | GSAP + custom splitter | `gsap-patterns.md` |
| Counter / number roll | GSAP onUpdate | `gsap-patterns.md` |
| Smooth page scroll | Lenis | `scroll-patterns.md` |
| Custom cursor | GSAP + pointer events | `cursor-and-hover.md` |
| Magnetic buttons | GSAP | `cursor-and-hover.md` |
| 3D tilt card | GSAP | `cursor-and-hover.md` |
| 3D hero background | Three.js WebGPU / R3F | `threejs-patterns.md` |
| Particle effects | Three.js instanced mesh | `threejs-patterns.md` |
| Gradient mesh background | WebGPU shader | `threejs-patterns.md` |
| Page route transition | View Transitions API | `css-native-motion.md` |
| Complex page transition | GSAP timeline overlay | `page-transitions.md` |
| Loading / intro sequence | GSAP timeline | `gsap-patterns.md` |
| Scroll-linked 3D rotation | Three.js + GSAP scrub | `threejs-patterns.md` |
| Image reveal / clip-path | GSAP | `gsap-patterns.md` |
| Hover distortion | WebGPU shader | `threejs-patterns.md` |
| Marquee / infinite scroll | GSAP | `gsap-patterns.md` |
| Container Transform (page) | View Transitions `view-transition-name` | `page-transitions.md` |
| Shared Axis (tab/step) | View Transitions `translateX` | `page-transitions.md` |

## Measuring Impact

Key web-specific metrics to track:

- **Scroll depth**: Target 70%+ (industry avg ~45%). Track via GA `scroll_depth` events.
- **Time on page**: Expect +30–50% with scroll storytelling vs static layout.
- **Bounce rate**: Hero must load <1.5s or progressive reveal. 3+ second intros = bounce.
- **Core Web Vitals**: Three.js must be lazy-loaded — LCP unaffected. No CLS from late-appearing animations. Use `will-change` sparingly.
- **Session recordings**: Watch Hotjar/FullStory for where users pause (engaged) vs rage-click (frustrated).
