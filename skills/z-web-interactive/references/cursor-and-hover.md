# Cursor & Hover Interaction Patterns

## Custom Cursor

Replace the default cursor with a custom animated element.

```tsx
// components/custom-cursor.tsx
"use client";
import { useRef, useEffect, useState } from "react";
import { gsap } from "@/lib/gsap";

export function CustomCursor() {
  const dotRef = useRef<HTMLDivElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    // Hide on touch devices
    if ("ontouchstart" in window) return;

    const dot = dotRef.current!;
    const ring = ringRef.current!;

    const moveCursor = (e: MouseEvent) => {
      if (!visible) setVisible(true);

      gsap.to(dot, {
        x: e.clientX,
        y: e.clientY,
        duration: 0.1,
        ease: "power2.out",
      });

      gsap.to(ring, {
        x: e.clientX,
        y: e.clientY,
        duration: 0.3,
        ease: "power2.out",
      });
    };

    const handleEnterInteractive = () => {
      gsap.to(ring, { scale: 1.8, opacity: 0.5, duration: 0.3 });
      gsap.to(dot, { scale: 0.5, duration: 0.3 });
    };

    const handleLeaveInteractive = () => {
      gsap.to(ring, { scale: 1, opacity: 1, duration: 0.3 });
      gsap.to(dot, { scale: 1, duration: 0.3 });
    };

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
    };
  }, [visible]);

  if (!visible) return null;

  return (
    <>
      <div
        ref={dotRef}
        className="pointer-events-none fixed left-0 top-0 z-[9999] h-2 w-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white mix-blend-difference"
      />
      <div
        ref={ringRef}
        className="pointer-events-none fixed left-0 top-0 z-[9999] h-8 w-8 -translate-x-1/2 -translate-y-1/2 rounded-full border border-white mix-blend-difference"
      />
    </>
  );
}

// Add to layout.tsx:
// <CustomCursor />
// Add to globals.css:
// * { cursor: none; }  /* Only on desktop via media query */
// @media (pointer: fine) { * { cursor: none; } }
```

### Cursor with Text Label

```tsx
// Extend CustomCursor to show text on specific elements
// Add data-cursor-text="View" to elements

useEffect(() => {
  const textElements = document.querySelectorAll("[data-cursor-text]");

  textElements.forEach((el) => {
    el.addEventListener("mouseenter", () => {
      const text = el.getAttribute("data-cursor-text");
      // Show text inside ring, scale ring up
      gsap.to(ring, { scale: 3, duration: 0.4 });
      labelRef.current!.textContent = text;
      gsap.to(labelRef.current, { opacity: 1, duration: 0.3 });
    });

    el.addEventListener("mouseleave", () => {
      gsap.to(ring, { scale: 1, duration: 0.4 });
      gsap.to(labelRef.current, { opacity: 0, duration: 0.3 });
    });
  });
}, []);
```

---

## Magnetic Button

Elements that pull toward the cursor when nearby.

```tsx
// components/magnetic.tsx
"use client";
import { useRef, useEffect } from "react";
import { gsap } from "@/lib/gsap";

export function Magnetic({
  children,
  strength = 0.35,
  radius = 0.6,
}: {
  children: React.ReactNode;
  strength?: number;
  radius?: number; // How far from center the effect starts (0-1)
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if ("ontouchstart" in window) return; // Skip on mobile

    const el = ref.current!;

    const handleMove = (e: MouseEvent) => {
      const { left, top, width, height } = el.getBoundingClientRect();
      const centerX = left + width / 2;
      const centerY = top + height / 2;
      const distX = e.clientX - centerX;
      const distY = e.clientY - centerY;

      gsap.to(el, {
        x: distX * strength,
        y: distY * strength,
        duration: 0.4,
        ease: "power2.out",
      });
    };

    const handleLeave = () => {
      gsap.to(el, {
        x: 0,
        y: 0,
        duration: 0.7,
        ease: "elastic.out(1, 0.3)",
      });
    };

    el.addEventListener("mousemove", handleMove);
    el.addEventListener("mouseleave", handleLeave);

    return () => {
      el.removeEventListener("mousemove", handleMove);
      el.removeEventListener("mouseleave", handleLeave);
    };
  }, [strength]);

  return (
    <div ref={ref} className="inline-block">
      {children}
    </div>
  );
}
```

---

## 3D Tilt Card

Card that tilts toward the cursor on hover.

```tsx
// components/tilt-card.tsx
"use client";
import { useRef, useEffect } from "react";
import { gsap } from "@/lib/gsap";

export function TiltCard({
  children,
  maxTilt = 15,
  scale = 1.02,
  glare = true,
}: {
  children: React.ReactNode;
  maxTilt?: number;
  scale?: number;
  glare?: boolean;
}) {
  const cardRef = useRef<HTMLDivElement>(null);
  const glareRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if ("ontouchstart" in window) return;

    const card = cardRef.current!;

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

      if (glare && glareRef.current) {
        gsap.to(glareRef.current, {
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

      if (glare && glareRef.current) {
        gsap.to(glareRef.current, { opacity: 0, duration: 0.4 });
      }
    };

    card.addEventListener("mousemove", handleMove);
    card.addEventListener("mouseleave", handleLeave);

    return () => {
      card.removeEventListener("mousemove", handleMove);
      card.removeEventListener("mouseleave", handleLeave);
    };
  }, [maxTilt, scale, glare]);

  return (
    <div ref={cardRef} className="relative" style={{ transformStyle: "preserve-3d" }}>
      {children}
      {glare && (
        <div
          ref={glareRef}
          className="pointer-events-none absolute inset-0 rounded-[inherit] opacity-0"
          style={{
            background:
              "radial-gradient(circle at center, rgba(255,255,255,0.5) 0%, transparent 60%)",
          }}
        />
      )}
    </div>
  );
}
```

---

## Mouse Parallax (Background Layers)

Move background layers subtly based on mouse position.

```tsx
// components/mouse-parallax.tsx
"use client";
import { useRef, useEffect } from "react";
import { gsap } from "@/lib/gsap";

export function MouseParallax({
  children,
  depth = 0.02,
}: {
  children: React.ReactNode;
  depth?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if ("ontouchstart" in window) return;

    const handleMove = (e: MouseEvent) => {
      const x = (e.clientX / window.innerWidth - 0.5) * 2; // -1 to 1
      const y = (e.clientY / window.innerHeight - 0.5) * 2;

      const layers = ref.current!.querySelectorAll<HTMLElement>("[data-parallax-depth]");

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
    return () => window.removeEventListener("mousemove", handleMove);
  }, [depth]);

  return <div ref={ref}>{children}</div>;
}

// Usage:
// <MouseParallax>
//   <div data-parallax-depth="1">Background</div>   <!-- moves most -->
//   <div data-parallax-depth="0.5">Midground</div>
//   <div data-parallax-depth="0.2">Foreground</div>  <!-- moves least -->
// </MouseParallax>
```

---

## Glow / Spotlight Follow

Radial gradient that follows the cursor.

```tsx
"use client";
import { useRef, useEffect } from "react";

export function SpotlightCard({ children }: { children: React.ReactNode }) {
  const cardRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const card = cardRef.current!;

    const handleMove = (e: MouseEvent) => {
      const { left, top } = card.getBoundingClientRect();
      const x = e.clientX - left;
      const y = e.clientY - top;

      card.style.setProperty("--spotlight-x", `${x}px`);
      card.style.setProperty("--spotlight-y", `${y}px`);
    };

    card.addEventListener("mousemove", handleMove);
    return () => card.removeEventListener("mousemove", handleMove);
  }, []);

  return (
    <div
      ref={cardRef}
      className="group relative overflow-hidden rounded-xl border border-white/10 bg-black p-8"
    >
      {/* Spotlight gradient */}
      <div
        className="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-300 group-hover:opacity-100"
        style={{
          background:
            "radial-gradient(300px circle at var(--spotlight-x) var(--spotlight-y), rgba(99,102,241,0.15), transparent 60%)",
        }}
      />
      <div className="relative z-10">{children}</div>
    </div>
  );
}
```

---

## Accessibility Notes

- Custom cursors: always keep the native cursor available (`cursor: auto` on interactive elements that need it)
- Magnetic effects: disable on touch devices (no hover on mobile)
- Tilt effects: disable for `prefers-reduced-motion`
- All mouse-dependent interactions must have non-mouse fallbacks
