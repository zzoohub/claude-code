# Motion Theory & Design Principles

Deep reference for the cognitive science, design principles, and planning frameworks behind interactive motion. Read this when you need to understand **why** a motion decision works, not just **how** to implement it.

## Table of Contents

1. [Cognitive Foundations](#cognitive-foundations)
2. [12 UX Motion Principles](#12-ux-motion-principles)
3. [Design Principles](#design-principles)
4. [Experience Audit](#experience-audit)
5. [Direction Plan Template](#direction-plan-template)

---

## Cognitive Foundations

Motion decisions are grounded in how the human brain processes movement. Know these so you can explain **why**, not just **what**.

### Visual Attention
The human visual system is hardwired to detect motion — a primal survival mechanism (Pratt et al., *Psychological Science*, 2010). In UI, motion instantly sits at the top of the visual hierarchy. Use this power deliberately: if everything moves, nothing stands out.

### Working Memory Limit
Humans hold ~4 chunks of information in working memory at once. Stagger and sequencing work because they present information in digestible chunks rather than all at once. A stagger of 50–100ms creates distinct perceptual "events" the brain can individually track. Below 30ms = perceived as simultaneous (hierarchy lost). Above 200ms = feels sluggish, narrative breaks.

### Physics-Based Expectation
Our brains expect motion to follow real-world physics — objects decelerate when arriving (ease-out) and accelerate when departing (ease-in). Linear motion feels robotic because nothing in the physical world moves at constant velocity. This is why ease-out on entrance makes elements feel like they're "settling into place" — NN/g research confirms it allows the eye to predict where the object will stop, increasing perceived responsiveness.

### Depth Perception
Motion parallax (closer objects move faster) is a primary depth cue. Layered parallax triggers spatial perception instantly, creating hierarchy without any explicit visual indicator. But excessive parallax can trigger motion sickness in 8–12% of users — always offer reduced-motion fallback.

### Cognitive Load Reduction
Well-designed motion reduces cognitive load by providing visual cues about spatial relationships and state changes. A 2024 study found that staging and tracing animations help users identify patterns more accurately and quickly. Skeleton loaders reduce *perceived* wait time by ~30% compared to spinners because they communicate structure before content arrives.

### Cultural Consideration
Reading direction affects scan patterns (F-pattern in LTR, reversed in RTL). When staggering elements, match the reading direction of your audience for fastest comprehension.

---

## 12 UX Motion Principles

Based on the UX in Motion Manifesto (Willenskomer). Use as a checklist — not every project uses all 12, but consciously decide which apply.

| # | Principle | What It Does | When to Use |
|---|-----------|-------------|-------------|
| 1 | **Easing** | Makes motion feel natural via acceleration/deceleration | Every animation — never use linear |
| 2 | **Offset & Delay** | Stagger creates hierarchy and individuality among grouped elements | Card grids, list items, nav menus |
| 3 | **Parenting** | Child elements inherit parent motion, reinforcing spatial grouping | Expanding cards, nested menus, grouped icons |
| 4 | **Transformation** | Morphing between states chunks separate moments into continuous flow | Button → loader → checkmark, FAB → menu |
| 5 | **Value Change** | Animating data changes (counters, progress) makes updates noticeable | Dashboard KPIs, pricing, progress bars |
| 6 | **Masking** | Revealing/concealing content through shape boundaries | Image reveals, section transitions, clip-path wipes |
| 7 | **Overlay** | Layered content (modals, sheets) maintains spatial context | Modals, bottom sheets, drawers, tooltips |
| 8 | **Cloning** | Element spawns a copy that travels to a new context | Add-to-cart fly animation, avatar → profile |
| 9 | **Obscuration** | Blur/dim separates foreground from background hierarchy | Modal backdrop, focused input, spotlight |
| 10 | **Parallax** | Different scroll speeds create depth and priority separation | Hero backgrounds, layered sections |
| 11 | **Dimensionality** | 3D transforms create spatial relationships (flip, fold) | Card flip, page curl, carousel |
| 12 | **Dolly & Zoom** | Camera-like movement communicates hierarchy navigation depth | Zooming into detail, map drill-down |

---

## Design Principles

### 1. Purpose Test
Every animation must answer: **"What would the user lose if this didn't exist?"** If nothing — remove it.

### 2. First Impression Rule
The most impactful moment is the **first viewport + first scroll**. Budget most of your direction effort here.

### 3. Diminishing Returns
The 5th scroll animation is worth less than the 1st. Strategic stillness is as powerful as motion.

### 4. Cohesion Over Novelty
One consistent emotional register beats five impressive-but-mismatched effects. A luxury brand page with bouncy elastic animations is worse than a simple fade-in that matches the brand.

### 5. Mobile Reality
- No hover/cursor effects
- Simpler or no parallax
- Shorter durations
- No scroll hijacking

### 6. Accessibility is Non-Negotiable
- Every direction plan includes reduced-motion fallback
- Fallback = all content visible, no animation
- No content hidden behind animation

### 7. Performance Awareness
- Full-page pin with scrub → test on iOS Safari
- Too many simultaneous GSAP tweens → prioritize, stagger, or simplify
- Full-screen Skia canvas → test on mid-range Android

---

## Experience Audit

When given an existing UI, analyze:

- **Dead zones**: areas that feel static and lifeless
- **Hierarchy gaps**: elements that compete for attention when they shouldn't
- **Transition seams**: route changes, section boundaries that feel abrupt
- **Scroll story**: does the page have a narrative arc, or is it flat?
- **Interaction desert**: elements you want to engage with but nothing responds
- **Atmosphere**: is there a cohesive sensory feel, or is it generic?

---

## Direction Plan Template

Before writing code, produce a direction plan:

```
PROJECT DIRECTION
Emotion: [register from emotional register matrix]
Platform: [web / mobile]

HERO SECTION
- Headline: chars reveal L→R, 0.03s stagger, power4.out
  Why: 30ms stagger on ~20 chars = distinct perceptual events within working memory
- Background: CSS gradient or animated gradient mesh
- CTA: magnetic hover (web) / spring tap (mobile)
- Timing: headline 0ms → background 200ms → CTA 600ms
- UX Motion Principles: Easing (#1), Offset & Delay (#2), Parallax (#10)

FEATURES (scroll)
- Cards stagger from bottom, y:40→0, 0.08s apart, first 6 items only
- Trigger: section top at 75% viewport
- No parallax (content-focused)

PAGE TRANSITIONS
- Primary nav: Fade Through (no spatial relationship between pages)
- Product card → detail: Container Transform (element expands into its detail)
- Tab switching: Shared Axis horizontal (peer-level navigation)

REDUCED MOTION FALLBACK
- All content visible, no animation

MOBILE ADAPTATION
- Disable cursor effects
- Shorter durations (x0.7)
- No scroll pinning
- Replace hover interactions with tap feedback + spring

SUCCESS METRICS
- Scroll depth: target 70%+
- Hero animation load: <1.5s (progressive reveal)
- CWV: LCP unaffected
```
