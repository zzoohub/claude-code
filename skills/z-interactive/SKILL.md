---
name: z-interactive
description: |
  Build everything interactive — motion, gestures, sensory atmosphere, and visual effects — for web and React Native.
  Use when: user says "make it interactive", "add animations", "more dynamic", "add wow factor", "add scroll effects", "creative landing page", "parallax", "reveal on scroll", "smooth scroll", "cursor effect", "page transition", "loading animation", "intro sequence", "make it feel alive", "more cinematic", "more immersive", "interactive portfolio", "gesture", "swipe interaction", "shared element transition", "spring animation", "hero animation", "micro-interactions", "kinetic typography", "text animation", "loading screen", "splash screen", "marquee", "ticker", "reveal effect", "motion design", or any request to enhance the sensory experience of an existing UI on either web or mobile.
  Do NOT use for: basic CSS hover states (use z-design-system motion tokens), building components from scratch, UX flow decisions (use z-ux-design), data/API work, or 3D/WebGL/WebGPU scenes (consider a dedicated 3D skill).
  Workflow position: z-ux-design (flow) -> z-design-system (tokens) -> UI implementation -> **this skill** (apply interactive).
references:
  - references/motion-theory.md
  - references/web/gsap-patterns.md
  - references/web/scroll-patterns.md
  - references/web/cursor-and-hover.md
  - references/web/css-native-motion.md
  - references/web/page-transitions.md
  - references/web/performance.md
  - references/react/gsap-patterns.md
  - references/react/scroll-patterns.md
  - references/react/cursor-and-hover.md
  - references/react/page-transitions.md
  - references/react/performance.md
  - references/react-native/reanimated-patterns.md
  - references/react-native/skia-patterns.md
  - references/react-native/gesture-patterns.md
  - references/react-native/performance.md
---

# Interactive Motion

## Philosophy

Motion is a design material, not decoration. Every animation must serve one of three purposes: **guide attention**, **communicate relationships**, or **create emotional response**. If it doesn't do one of these, remove it.

Before touching anything, see the page/screen through three questions:

1. **Where does the eye go first?** — Hierarchy. What's the hero moment? What should the user notice in the first 500ms?
2. **What's the rhythm?** — Pacing. Does the page unfold gradually (scroll storytelling) or hit all at once (dashboard)?
3. **What emotion should this evoke?** — Feeling. Calm trust (banking)? Excited energy (gaming)? Elegant restraint (luxury)?

The answers determine every decision — motion, interaction, everything.

> For the cognitive science behind these decisions (why stagger works, why ease-out feels natural, why parallax creates depth), read `references/motion-theory.md`.

## Emotional Register

Commit to one register for the entire project. Mixing registers creates cognitive dissonance.

| Register | Motion | Interaction | Color/Light |
|----------|--------|-------------|-------------|
| **Calm / Trust** | Slow, subtle, fade-only | Gentle hover, no surprise | Warm, muted |
| **Energetic / Playful** | Bouncy, spring, fast stagger | Magnetic, elastic snap | Vivid, saturated |
| **Elegant / Luxury** | Slow reveals, clip-path | Minimal, precise | Dark + gold/silver accents |
| **Tech / Modern** | Precise, geometric | Clean hover states | Monochrome + accent |
| **Dramatic / Cinematic** | Full-screen wipes, camera-like moves | Immersive, scroll-driven | High contrast, volumetric |
| **Minimal / Restrained** | Almost nothing, opacity only | Standard hover | Neutral |

## Transition Semantics

Choose the right transition pattern based on the *relationship* between elements — don't default to cross-fade for everything:

| Pattern | When | Web Implementation | RN Implementation |
|---------|------|-------------------|-------------------|
| **Container Transform** | Element expands into its detail view | View Transitions `view-transition-name` | Reanimated `SharedTransition` (experimental — test on target RN/Expo version) |
| **Shared Axis** | Peer views at same hierarchy level | View Transitions + `translateX` | Stack `slideFromRight` / tab slide |
| **Fade Through** | No spatial relationship between views | Default View Transitions cross-fade | Reanimated `FadeIn`/`FadeOut` |
| **Fade** | Simple appear/disappear of one element | CSS opacity transition | `withTiming` on opacity |

---

## Platform Selection

```
What platform?
│
├─ Web
│  ├─ Stack: GSAP + Lenis + CSS native APIs
│  ├─ Philosophy: Exploration & Discovery
│  │  Users have hover — use it to reveal possibilities
│  │  Larger viewport = room for cinematic scroll storytelling
│  │  Hero moment: first viewport + first scroll
│  ├─ Agnostic References: references/web/*
│  └─ React References: references/react/*
│
└─ Mobile / React Native (Expo)
   ├─ Stack: Reanimated 3 + Gesture Handler + Skia
   ├─ Philosophy: Efficiency & Immediacy
   │  No hover — every affordance visible by default
   │  Touch requires instant feedback (springs, haptics)
   │  Hero moment: first tap response + gesture fluidity
   └─ References: references/react-native/*
```

**Never port web hover interactions to mobile.** A magnetic hover effect on web becomes a spring-loaded tap feedback on mobile. The emotional register stays the same; the implementation vocabulary changes entirely.

---

## Web: GSAP + Lenis + CSS Native

### Tech Stack

| Library | Role | Size | Thread |
|---------|------|------|--------|
| **GSAP** + ScrollTrigger | All DOM animation: timelines, scroll choreography, stagger, text split, cursor | ~35KB | Main (JS) |
| **Lenis** | Smooth scroll feel | ~8KB | Main (JS) |
| **CSS native** | Simple scroll-linked, View Transitions, `@starting-style` | 0KB | Compositor |

> GSAP is free for most uses under its "no charge" license. Check [gsap.com/licensing](https://gsap.com/licensing/) for commercial edge cases.

GSAP is the primary engine. CSS native only when zero-JS is genuinely advantageous.

### Why GSAP, Not Framer Motion

GSAP outperforms Framer Motion in every dimension that matters for interactive work: ScrollTrigger (pin, scrub, snap, stagger), timeline sequencing, text splitting, cursor/mouse tracking via `gsap.quickTo`, and raw animation throughput. GSAP operates directly on the DOM, making it framework-agnostic — the same GSAP code works in React, Solid, Svelte, Vue, or vanilla JS. Framer Motion is React-only and re-renders components on every frame through state. If an existing codebase uses Framer Motion, replace it with GSAP timelines or CSS `@starting-style` (see `references/web/css-native-motion.md`) rather than maintaining two animation engines. One engine, one mental model, no property conflicts.

### Decision Flowchart

```
Need animation?
│
├─ Scroll-linked?
│  ├─ Simple (one element, no stagger) → CSS animation-timeline: view()
│  ├─ Progress bar → CSS animation-timeline: scroll()
│  └─ Everything else (stagger, pin, scrub, snap) → GSAP ScrollTrigger
│
├─ Timeline sequence (A→B→C)? → GSAP timeline
├─ Text character/word animation? → GSAP + custom splitter
│
├─ Route/page transition?
│  ├─ Cross-fade, shared element → View Transitions API
│  └─ Complex overlay wipe → GSAP timeline
│
├─ Cursor/mouse interaction?
│  ├─ Simple hover → CSS/Tailwind :hover
│  └─ Magnetic, tilt, cursor, spotlight → GSAP
│
├─ Smooth scroll? → Lenis
└─ Basic hover state? → Tailwind/CSS (use z-design-system)
```

### Tailwind + GSAP Workflow

Tailwind owns **layout and styling**. GSAP owns **motion**. They never overlap. GSAP targets elements via `data-*` attributes or refs.

```html
<section class="relative flex min-h-screen items-center bg-black px-6">
  <h1 data-reveal class="text-5xl font-bold text-white md:text-7xl">
    Heading
  </h1>
</section>
```

### Core Patterns (see references for full code)

| Pattern | Agnostic Reference | React Reference |
|---------|-------------------|-----------------|
| Scroll reveal, stagger, timeline, intro sequence | `references/web/gsap-patterns.md` | `references/react/gsap-patterns.md` |
| Pin, horizontal scroll, parallax, snap, Lenis setup | `references/web/scroll-patterns.md` | `references/react/scroll-patterns.md` |
| Custom cursor, magnetic button, tilt card, spotlight | `references/web/cursor-and-hover.md` | `references/react/cursor-and-hover.md` |
| CSS scroll-driven, View Transitions, @starting-style | `references/web/css-native-motion.md` | — (CSS, no framework needed) |
| GSAP overlay wipe, staggered page transitions | `references/web/page-transitions.md` | `references/react/page-transitions.md` |
| Bundle size, cleanup, will-change, device tier, reduced motion | `references/web/performance.md` | `references/react/performance.md` |

### Web File Organization

```
lib/
├── gsap.ts              # Centralized GSAP + plugin registration
├── split-text.ts        # Custom text splitter (free SplitText alternative)
├── motion/              # GSAP animation factories (return cleanup functions)
│   ├── reveal-on-scroll.ts
│   ├── stagger-section.ts
│   ├── magnetic.ts
│   ├── tilt-card.ts
│   ├── custom-cursor.ts
│   └── smooth-scroll.ts
└── transitions/         # Page transition utilities
    └── page-transition.ts
```

Framework-specific wrappers (React components, Svelte actions, Vue composables) go in the framework layer and import from `lib/`.

---

## Mobile: Reanimated 3 + Gesture Handler + Skia

### Tech Stack

| Library | Role | Thread |
|---------|------|--------|
| **Reanimated 3** | All view animation: timing, spring, decay, scroll, layout | UI thread (worklet) |
| **react-native-skia** | GPU-rendered graphics: shaders, particles, custom drawing | GPU via Skia |
| **Gesture Handler** | Touch input: tap, pan, pinch, rotation, fling | UI thread (native) |

Reanimated is the primary engine. Skia only for GPU graphics. Lottie only for pre-made designer files.

### Why Springs Are the Default on Mobile

**Prefer `withSpring`** over `withTiming` on mobile because:
- **Interruptible**: user taps mid-animation, spring naturally adjusts
- **Physics-based**: feels like a real object (brain expects deceleration)
- **No duration guessing**: springs resolve naturally from damping/stiffness

Use `withTiming` only for: opacity fades, color transitions, progress bars.

### Decision Flowchart

```
Need animation?
│
├─ View property (opacity, transform, color)? → Reanimated withTiming/withSpring
├─ Scroll-linked? → Reanimated useAnimatedScrollHandler + interpolate
├─ Momentum/fling? → Reanimated withDecay
├─ Gesture-driven (drag, pinch, swipe)? → Gesture Handler + Reanimated
├─ Keyboard-aware? → Reanimated useAnimatedKeyboard
├─ Layout animation (list reorder, enter/exit)? → Reanimated entering/exiting
├─ Shared element transition? → Reanimated SharedTransition
├─ Custom drawing (charts, paths, gradients)? → Skia Canvas
├─ GPU shader effect? → Skia RuntimeEffect
├─ Particle system? → Skia + Reanimated shared values
└─ Pre-made animation from designer? → Lottie
```

### Core Patterns (see references for full code)

| Pattern | Reference |
|---------|-----------|
| Shared values, animated styles, springs, sequences, decay, keyboard | `references/react-native/reanimated-patterns.md` |
| Gradients, blur, animated paths, shaders, particles | `references/react-native/skia-patterns.md` |
| Swipe-to-dismiss, pinch-to-zoom, bottom sheet, card flip, haptics | `references/react-native/gesture-patterns.md` |
| Threading model, jank causes, device tier, reduced motion | `references/react-native/performance.md` |

### Mobile File Organization

```
components/
├── motion/
│   ├── animated-card.tsx
│   ├── parallax-header.tsx
│   ├── stagger-list.tsx
│   ├── swipe-to-dismiss.tsx
│   └── shared-transition.tsx
├── canvas/
│   ├── gradient-orb.tsx
│   ├── particle-field.tsx
│   ├── animated-chart.tsx
│   └── shader-background.tsx
hooks/
├── use-scroll-animation.ts
├── use-spring-entry.ts
└── use-gesture-drag.ts
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| **Animate everything** | No hierarchy = no attention guidance. Working memory holds ~4 chunks. | Pick 1-2 hero moments per viewport. Stillness is a design choice. |
| **3+ second loading animation** | Users bounce at 1.5s. | Progressive reveal. Skeleton loaders for structure. |
| **Parallax on text** | Brain can't read and track motion simultaneously. | Parallax on images/backgrounds only. |
| **Mixed emotional registers** | Bouncy elastic on a luxury brand = cognitive dissonance. | Commit to one register from the matrix above. |
| **Scroll hijacking on content** | 61% of users prefer control. | Reserve for immersive storytelling only. Never on blogs, docs, dashboards. |
| **Hover-only discovery** | ~60% of web traffic has no hover. | All info visible by default. Hover enhances, never reveals. |
| **Stagger > 10 items** | After ~6 items, brain predicts pattern and stops paying attention. | Stagger first 4-6, batch-reveal the rest. |
| **Porting web hover to mobile** | Mobile has no hover. Hover-designed timing feels wrong on tap. | Rethink for touch: magnetic hover → spring tap, hover reveal → always visible. |
| **Timing-based everything (RN)** | `withTiming` can't be interrupted mid-flight. | Default to `withSpring` for touch-related animations. |

## Accessibility — Non-Negotiable

Every animation must handle reduced motion. No content hidden behind animation.

**Web (CSS level — covers all CSS animations):**
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

**Web (JS level — for GSAP):**
```typescript
const prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if (prefersReduced) {
  // Skip GSAP animations, show static content
  gsap.globalTimeline.timeScale(100); // effectively instant
}
```

**React Native (per-animation — simplest):**
```tsx
import { ReduceMotion } from 'react-native-reanimated';
opacity.value = withTiming(1, { duration: 600, reduceMotion: ReduceMotion.System });
```

**React Native (conditional logic):**
```tsx
import { useReducedMotion } from 'react-native-reanimated';
const reduceMotion = useReducedMotion();
const entering = reduceMotion ? FadeIn : BounceIn;
```

## Measuring Impact

| Context | Key Metric | Target |
|---------|-----------|--------|
| Marketing / Portfolio | Scroll depth | 70%+ (industry avg ~45%) |
| Marketing / Portfolio | Time on page | +30-50% vs static |
| SaaS / Dashboard | Task completion time | Never increase |
| SaaS / Dashboard | Perceived performance | Skeleton + shimmer > spinner |
| E-commerce | Add-to-cart rate | +5-15% with product hover effects |
| Mobile app | Gesture success rate | Users complete swipe/drag interactions |
| All | Core Web Vitals / frame rate | No CLS, 60fps maintained |

> Full theory: 12 UX Motion Principles, Cognitive Foundations, Direction Plan template → `references/motion-theory.md`
