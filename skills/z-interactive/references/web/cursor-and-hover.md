# Cursor & Hover Interaction Patterns

> React implementation: `../react/cursor-and-hover.md`

## Custom Cursor

Replace the default cursor with a custom animated element.

```ts
// Expected HTML (append to body):
// <div class="cursor-dot pointer-events-none fixed left-0 top-0 z-[9999] h-2 w-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white mix-blend-difference"></div>
// <div class="cursor-ring pointer-events-none fixed left-0 top-0 z-[9999] h-8 w-8 -translate-x-1/2 -translate-y-1/2 rounded-full border border-white mix-blend-difference"></div>
//
// CSS (desktop only):
// @media (pointer: fine) { * { cursor: none; } }

import { gsap } from "@/lib/gsap";

function createCustomCursor(): () => void {
  // Hide on touch devices
  if ("ontouchstart" in window) return () => {};

  const dot = document.querySelector(".cursor-dot") as HTMLElement;
  const ring = document.querySelector(".cursor-ring") as HTMLElement;
  if (!dot || !ring) return () => {};

  // quickTo creates reusable tweens — far more efficient than gsap.to() per mousemove
  const dotX = gsap.quickTo(dot, "x", { duration: 0.1, ease: "power2.out" });
  const dotY = gsap.quickTo(dot, "y", { duration: 0.1, ease: "power2.out" });
  const ringX = gsap.quickTo(ring, "x", { duration: 0.3, ease: "power2.out" });
  const ringY = gsap.quickTo(ring, "y", { duration: 0.3, ease: "power2.out" });

  let visible = false;

  const moveCursor = (e: MouseEvent) => {
    if (!visible) {
      dot.style.display = "";
      ring.style.display = "";
      visible = true;
    }
    dotX(e.clientX);
    dotY(e.clientY);
    ringX(e.clientX);
    ringY(e.clientY);
  };

  const handleEnterInteractive = () => {
    gsap.to(ring, { scale: 1.8, opacity: 0.5, duration: 0.3 });
    gsap.to(dot, { scale: 0.5, duration: 0.3 });
  };

  const handleLeaveInteractive = () => {
    gsap.to(ring, { scale: 1, opacity: 1, duration: 0.3 });
    gsap.to(dot, { scale: 1, duration: 0.3 });
  };

  // Initially hidden
  dot.style.display = "none";
  ring.style.display = "none";

  window.addEventListener("mousemove", moveCursor);

  // Grow cursor on interactive elements
  const interactives = document.querySelectorAll(
    "a, button, [data-cursor-hover]"
  );
  interactives.forEach((el) => {
    el.addEventListener("mouseenter", handleEnterInteractive);
    el.addEventListener("mouseleave", handleLeaveInteractive);
  });

  return () => {
    window.removeEventListener("mousemove", moveCursor);
    interactives.forEach((el) => {
      el.removeEventListener("mouseenter", handleEnterInteractive);
      el.removeEventListener("mouseleave", handleLeaveInteractive);
    });
    dot.remove();
    ring.remove();
  };
}
```

### Cursor with Text Label

```ts
// Extend createCustomCursor to show text on specific elements.
// Add data-cursor-text="View" to elements.
// Add a label element inside the ring:
// <span class="cursor-label" style="opacity:0;position:absolute;..."></span>

function setupCursorTextLabels(ring: HTMLElement, label: HTMLElement): () => void {
  const textElements = document.querySelectorAll("[data-cursor-text]");
  const listeners: Array<{ el: Element; type: string; fn: EventListener }> = [];

  textElements.forEach((el) => {
    const enterFn = () => {
      const text = el.getAttribute("data-cursor-text");
      // Show text inside ring, scale ring up
      gsap.to(ring, { scale: 3, duration: 0.4 });
      label.textContent = text;
      gsap.to(label, { opacity: 1, duration: 0.3 });
    };

    const leaveFn = () => {
      gsap.to(ring, { scale: 1, duration: 0.4 });
      gsap.to(label, { opacity: 0, duration: 0.3 });
    };

    el.addEventListener("mouseenter", enterFn);
    el.addEventListener("mouseleave", leaveFn);
    listeners.push(
      { el, type: "mouseenter", fn: enterFn },
      { el, type: "mouseleave", fn: leaveFn }
    );
  });

  return () => {
    listeners.forEach(({ el, type, fn }) => el.removeEventListener(type, fn));
  };
}
```

---

## Magnetic Button

Elements that pull toward the cursor when nearby.

```ts
import { gsap } from "@/lib/gsap";

// Expected HTML:
// <div class="magnetic-wrap inline-block">
//   <button>Click me</button>
// </div>

interface MagneticOptions {
  strength?: number;
  radius?: number; // How far from center the effect starts (0-1)
}

// Re-call this function when strength changes
function createMagnetic(element: HTMLElement, options?: MagneticOptions): () => void {
  if ("ontouchstart" in window) return () => {}; // Skip on mobile

  const { strength = 0.35 } = options ?? {};

  const ctx = gsap.context(() => {
    const xTo = gsap.quickTo(element, "x", { duration: 0.4, ease: "power2.out" });
    const yTo = gsap.quickTo(element, "y", { duration: 0.4, ease: "power2.out" });

    const handleMove = (e: MouseEvent) => {
      const { left, top, width, height } = element.getBoundingClientRect();
      const centerX = left + width / 2;
      const centerY = top + height / 2;
      xTo((e.clientX - centerX) * strength);
      yTo((e.clientY - centerY) * strength);
    };

    const handleLeave = () => {
      gsap.to(element, {
        x: 0,
        y: 0,
        duration: 0.7,
        ease: "elastic.out(1, 0.3)",
      });
    };

    element.addEventListener("mousemove", handleMove);
    element.addEventListener("mouseleave", handleLeave);

    // gsap.context does not auto-clean DOM listeners, so return cleanup in the context callback
    return () => {
      element.removeEventListener("mousemove", handleMove);
      element.removeEventListener("mouseleave", handleLeave);
    };
  }, element);

  return () => ctx.revert();
}
```

---

## 3D Tilt Card

Card that tilts toward the cursor on hover.

```ts
// Expected HTML:
// <div class="tilt-card relative" style="transform-style:preserve-3d">
//   <!-- card content -->
//   <div class="tilt-glare pointer-events-none absolute inset-0 rounded-[inherit] opacity-0"
//        style="background:radial-gradient(circle at center, rgba(255,255,255,0.5) 0%, transparent 60%)"></div>
// </div>

interface TiltOptions {
  maxTilt?: number;
  scale?: number;
  glare?: boolean;
}

// Re-call this function when options change
function createTiltCard(card: HTMLElement, options?: TiltOptions): () => void {
  if ("ontouchstart" in window) return () => {};

  const { maxTilt = 15, scale = 1.02, glare = true } = options ?? {};
  const glareEl = card.querySelector(".tilt-glare") as HTMLElement | null;

  const ctx = gsap.context(() => {
    const handleMove = (e: MouseEvent) => {
      const { left, top, width, height } = card.getBoundingClientRect();
      const x = (e.clientX - left) / width - 0.5; // -0.5 to 0.5
      const y = (e.clientY - top) / height - 0.5;

      gsap.to(card, {
        rotateY: x * maxTilt,
        rotateX: -y * maxTilt,
        scale,
        duration: 0.4,
        ease: "power2.out",
        transformPerspective: 800,
      });

      if (glare && glareEl) {
        gsap.to(glareEl, {
          opacity: 0.15,
          x: x * 100 + "%",
          y: y * 100 + "%",
          duration: 0.4,
        });
      }
    };

    const handleLeave = () => {
      gsap.to(card, {
        rotateY: 0,
        rotateX: 0,
        scale: 1,
        duration: 0.6,
        ease: "power2.out",
      });

      if (glare && glareEl) {
        gsap.to(glareEl, { opacity: 0, duration: 0.4 });
      }
    };

    card.addEventListener("mousemove", handleMove);
    card.addEventListener("mouseleave", handleLeave);

    return () => {
      card.removeEventListener("mousemove", handleMove);
      card.removeEventListener("mouseleave", handleLeave);
    };
  }, card);

  return () => ctx.revert();
}
```

---

## Mouse Parallax (Background Layers)

Move background layers subtly based on mouse position.

```ts
// Expected HTML:
// <div class="mouse-parallax-container">
//   <div data-parallax-depth="1">Background</div>   <!-- moves most -->
//   <div data-parallax-depth="0.5">Midground</div>
//   <div data-parallax-depth="0.2">Foreground</div>  <!-- moves least -->
// </div>

// Re-call this function when depth changes
function createMouseParallax(container: HTMLElement, depth: number = 0.02): () => void {
  if ("ontouchstart" in window) return () => {};

  const handleMove = (e: MouseEvent) => {
    const x = (e.clientX / window.innerWidth - 0.5) * 2; // -1 to 1
    const y = (e.clientY / window.innerHeight - 0.5) * 2;

    const layers = container.querySelectorAll<HTMLElement>("[data-parallax-depth]");

    layers.forEach((layer) => {
      const d = parseFloat(layer.dataset.parallaxDepth || "1") * depth;
      gsap.to(layer, {
        x: x * d * 100,
        y: y * d * 100,
        duration: 0.8,
        ease: "power2.out",
      });
    });
  };

  window.addEventListener("mousemove", handleMove);

  return () => {
    window.removeEventListener("mousemove", handleMove);
  };
}
```

---

## Glow / Spotlight Follow

Radial gradient that follows the cursor.

```ts
// Expected HTML:
// <div class="spotlight-card group relative overflow-hidden rounded-xl border border-white/10 bg-black p-8">
//   <!-- Spotlight gradient -->
//   <div class="spotlight-gradient pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-300 group-hover:opacity-100"
//        style="background:radial-gradient(300px circle at var(--spotlight-x) var(--spotlight-y), rgba(99,102,241,0.15), transparent 60%)">
//   </div>
//   <div class="relative z-10"><!-- content --></div>
// </div>

function createSpotlightCard(card: HTMLElement): () => void {
  const handleMove = (e: MouseEvent) => {
    const { left, top } = card.getBoundingClientRect();
    const x = e.clientX - left;
    const y = e.clientY - top;

    card.style.setProperty("--spotlight-x", `${x}px`);
    card.style.setProperty("--spotlight-y", `${y}px`);
  };

  card.addEventListener("mousemove", handleMove);

  return () => {
    card.removeEventListener("mousemove", handleMove);
  };
}
```

---

## Accessibility Notes

- Custom cursors: always keep the native cursor available (`cursor: auto` on interactive elements that need it)
- Magnetic effects: disable on touch devices (no hover on mobile)
- Tilt effects: disable for `prefers-reduced-motion`
- All mouse-dependent interactions must have non-mouse fallbacks
