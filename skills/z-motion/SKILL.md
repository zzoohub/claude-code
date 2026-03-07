---
name: z-motion
description: |
  Motion design for web and React Native — animation, scroll effects, gestures, page transitions, visual atmosphere, and interactive charts.
  Use when: user says "add animations", "more dynamic", "add wow factor", "add scroll effects", "creative landing page", "parallax", "reveal on scroll", "smooth scroll", "cursor effect", "page transition", "loading animation", "intro sequence", "make it feel alive", "more cinematic", "more immersive", "interactive portfolio", "gesture", "swipe interaction", "shared element transition", "spring animation", "hero animation", "micro-interactions", "kinetic typography", "text animation", "loading screen", "splash screen", "marquee", "ticker", "reveal effect", "motion design", "interactive chart", "animated chart", "data visualization", "bar chart", "line chart", "donut chart", "area chart", "d3", "make it interactive", or any request to add motion, animation, or sensory polish to an existing UI on either web or mobile.
  Do NOT use for: basic CSS hover states (use z-design-system motion tokens), building components from scratch, UX flow decisions (use z-ux-design), data/API work, or 3D/WebGL/WebGPU scenes (consider z-web3d).
  Workflow position: z-ux-design (flow) -> z-design-system (tokens) -> UI implementation -> **this skill** (motion polish).
references:
  - references/motion-theory.md
  - references/web-conventions.md
  - references/react-conventions.md
  - references/react-native-conventions.md
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

Choose the right transition pattern based on the *relationship* between elements:

| Pattern | When | Web | RN |
|---------|------|-----|-----|
| **Container Transform** | Element expands into detail | View Transitions `view-transition-name` | Reanimated `SharedTransition` (experimental) |
| **Shared Axis** | Peer views at same hierarchy | View Transitions + `translateX` | Stack slide / tab slide |
| **Fade Through** | No spatial relationship | Default View Transitions cross-fade | Reanimated `FadeIn`/`FadeOut` |
| **Fade** | Simple appear/disappear | CSS opacity transition | `withTiming` on opacity |

---

## Platform Selection

```
What platform?
|
+-- Web
|   +-- Stack: GSAP + Lenis + D3 + CSS native APIs
|   +-- Philosophy: Exploration & Discovery
|   |   Hover reveals possibilities. Larger viewport = cinematic scroll storytelling.
|   |   Hero moment: first viewport + first scroll.
|   +-- Conventions: references/web-conventions.md
|      For React: also read references/react-conventions.md
|
+-- Mobile / React Native (Expo)
    +-- Stack: Reanimated 3 + Gesture Handler + Skia
    +-- Philosophy: Efficiency & Immediacy
    |   No hover -- every affordance visible. Touch requires instant feedback.
    |   Hero moment: first tap response + gesture fluidity.
    +-- Conventions: references/react-native-conventions.md
```

**Never port web hover interactions to mobile.** Magnetic hover becomes spring tap. The emotional register stays; the implementation vocabulary changes entirely.

---

## Web: Library Stack

| Library | Role | Size | When to Use |
|---------|------|------|-------------|
| **GSAP** + ScrollTrigger | Timeline, scroll choreography, stagger, text split, cursor | ~35KB | Primary engine for all complex DOM animation |
| **D3.js** | Interactive charts: scales, axes, data binding, transitions | ~30KB (tree-shaken) | Any data visualization (bar, line, area, donut) |
| **Lenis** | Smooth scroll feel | ~8KB | Marketing/portfolio sites (skip for blogs, docs, dashboards) |
| **CSS native** | Scroll-driven, View Transitions, `@starting-style` | 0KB | Simple cases where zero-JS is advantageous |

### GSAP as Primary Engine

GSAP is the default animation engine for web. It outperforms alternatives for interactive work: ScrollTrigger (pin, scrub, snap, stagger), timeline sequencing, text splitting, cursor/mouse tracking. It operates directly on the DOM — framework-agnostic.

**If the project uses Motion (formerly Framer Motion)**: evaluate before replacing. Motion's `MotionValue` avoids React re-renders and is fine for simple component animations. Replace with GSAP when you need: ScrollTrigger, complex timelines, text animation, cursor effects, or when multiple animation libraries create property conflicts. Don't refactor stable code without a clear performance or capability reason.

### Web Decision Flowchart

```
Need animation?
|
+-- Scroll-linked?
|   +-- Simple (one element, no stagger) --> CSS animation-timeline: view()
|   +-- Progress bar --> CSS animation-timeline: scroll()
|   +-- Everything else (stagger, pin, scrub, snap) --> GSAP ScrollTrigger
|
+-- Timeline sequence (A->B->C)? --> GSAP timeline
+-- Text character/word animation? --> GSAP + custom splitter
|
+-- Route/page transition?
|   +-- Cross-fade, shared element --> View Transitions API
|   +-- Complex overlay wipe --> GSAP timeline
|
+-- Cursor/mouse interaction?
|   +-- Simple hover --> CSS/Tailwind :hover
|   +-- Magnetic, tilt, cursor, spotlight --> GSAP
|
+-- Interactive chart/graph? --> D3.js
|   +-- Scroll-triggered chart entrance? --> D3 (structure) + GSAP ScrollTrigger (reveal)
|
+-- Smooth scroll? --> Lenis (marketing/portfolio only)
+-- Basic hover state? --> Tailwind/CSS (use z-design-system)
```

> Setup patterns, cleanup conventions, and integration gotchas: `references/web-conventions.md`
> React-specific hooks and SSR/RSC: `references/react-conventions.md`

---

## Mobile: Library Stack

| Library | Role | Thread |
|---------|------|--------|
| **Reanimated 3** | All view animation: timing, spring, decay, scroll, layout | UI thread (worklet) |
| **react-native-skia** | GPU-rendered graphics: shaders, particles, custom drawing | GPU via Skia |
| **Gesture Handler** | Touch input: tap, pan, pinch, rotation, fling | UI thread (native) |

Reanimated is the primary engine. Skia only for GPU graphics that Reanimated can't handle.

### Why Springs Are the Default on Mobile

**Prefer `withSpring`** over `withTiming` because:
- **Interruptible**: user taps mid-animation, spring naturally adjusts
- **Physics-based**: feels like a real object
- **No duration guessing**: resolves naturally from damping/stiffness

Use `withTiming` only for: opacity fades, color transitions, progress bars.

### Mobile Decision Flowchart

```
Need animation?
|
+-- View property (opacity, transform, color)? --> Reanimated withTiming/withSpring
+-- Scroll-linked? --> Reanimated useAnimatedScrollHandler + interpolate
+-- Momentum/fling? --> Reanimated withDecay
+-- Gesture-driven (drag, pinch, swipe)? --> Gesture Handler + Reanimated
+-- Keyboard-aware? --> Reanimated useAnimatedKeyboard
+-- Layout animation (list reorder, enter/exit)? --> Reanimated entering/exiting
+-- Shared element transition? --> Reanimated SharedTransition (experimental)
+-- Custom drawing (charts, paths, gradients)? --> Skia Canvas
+-- GPU shader effect? --> Skia RuntimeEffect
+-- Particle system? --> Skia + Reanimated shared values
```

> Threading model, cleanup patterns, performance rules: `references/react-native-conventions.md`

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Fix |
|-------------|-------------|-----|
| **Animate everything** | No hierarchy = no attention guidance | Pick 1-2 hero moments per viewport. Stillness is a design choice. |
| **3+ second loading animation** | Users bounce at 1.5s | Progressive reveal. Skeleton loaders for structure. |
| **Parallax on text** | Brain can't read and track motion simultaneously | Parallax on images/backgrounds only. |
| **Mixed emotional registers** | Bouncy elastic on a luxury brand = cognitive dissonance | Commit to one register. |
| **Scroll hijacking on content** | Users prefer control | Reserve for immersive storytelling only. Never on blogs, docs, dashboards. |
| **Hover-only discovery** | ~60% of web traffic has no hover | All info visible by default. Hover enhances, never reveals. |
| **Stagger > 10 items** | After ~6, brain predicts pattern and stops noticing | Stagger first 4-6, batch-reveal the rest. |
| **Porting web hover to mobile** | Mobile has no hover | Rethink: magnetic hover -> spring tap, hover reveal -> always visible. |
| **Timing-based everything (RN)** | `withTiming` can't be interrupted mid-flight | Default to `withSpring` for touch-related animations. |
| **Multiple animation engines** | Property conflicts, bundle bloat, mental overhead | One primary engine per platform. |

## Accessibility — Non-Negotiable

Every animation must handle reduced motion. No content hidden behind animation. Focus must be managed during page transitions.

**Web (CSS level):**
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
  gsap.globalTimeline.timeScale(100);
}
```

**React Native:**
```tsx
import { ReduceMotion } from 'react-native-reanimated';
opacity.value = withTiming(1, { duration: 600, reduceMotion: ReduceMotion.System });
```

For conditional UI paths, use `useReducedMotion()` hook from Reanimated.

## Measuring Impact

| Context | Key Metric | Target |
|---------|-----------|--------|
| Marketing / Portfolio | Scroll depth | 70%+ |
| Marketing / Portfolio | Time on page | +30-50% vs static |
| SaaS / Dashboard | Task completion time | Never increase |
| SaaS / Dashboard | Perceived performance | Skeleton + shimmer > spinner |
| E-commerce | Add-to-cart rate | +5-15% with product hover effects |
| Mobile app | Gesture success rate | Users complete swipe/drag interactions |
| All | Core Web Vitals / frame rate | No CLS, 60fps maintained |

> Full theory: 12 UX Motion Principles, Cognitive Foundations, Direction Plan template -> `references/motion-theory.md`
