# Three.js / React Three Fiber Patterns

## Installation

```bash
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three
```

## Renderer Strategy: WebGPU-First with WebGL Fallback

Three.js r160+ ships `WebGPURenderer`. **Always attempt WebGPU first, fall back to WebGL.**

Why WebGPU: compute shaders, less CPU-GPU bottleneck, better multi-draw, modern GPU API. But browser support is not universal yet (Chrome stable, Safari behind flag, Firefox Nightly only). So WebGL fallback is mandatory for production.

### Renderer Detection Utility

```ts
// lib/gpu-renderer.ts
import * as THREE from "three";

export async function createRenderer(
  canvas: HTMLCanvasElement,
  options?: { antialias?: boolean; alpha?: boolean }
) {
  const opts = { antialias: true, alpha: true, ...options };

  // Attempt WebGPU
  if ("gpu" in navigator) {
    try {
      const { WebGPURenderer } = await import("three/webgpu");
      const renderer = new WebGPURenderer({ canvas, ...opts });
      await renderer.init();
      console.log("[3D] Using WebGPU renderer");
      return { renderer, backend: "webgpu" as const };
    } catch (e) {
      console.warn("[3D] WebGPU init failed, falling back to WebGL", e);
    }
  }

  // Fallback to WebGL
  const renderer = new THREE.WebGLRenderer({ canvas, ...opts });
  console.log("[3D] Using WebGL renderer");
  return { renderer, backend: "webgl" as const };
}
```

### React Three Fiber with WebGPU

R3F doesn't natively support WebGPURenderer yet (as of early 2025). Two approaches:

**Approach A: Use R3F with WebGL (safe default)**
```tsx
// For most cases — R3F handles WebGL automatically
<Canvas dpr={[1, 2]} gl={{ antialias: true, alpha: true }}>
  ...
</Canvas>
```

**Approach B: Vanilla Three.js with WebGPU for heavy scenes**
```tsx
// For compute-heavy scenes (10K+ particles, complex shaders)
// Use vanilla Three.js with the createRenderer utility above
// Wrap in a React component with useEffect + canvas ref
```

**Approach C: R3F with custom renderer (experimental)**
```tsx
import { createRoot, events } from "@react-three/fiber";

// Bring your own renderer — R3F supports this
const root = createRoot(canvas);
// Pass your WebGPURenderer instance
```

**Decision rule**: Use R3F (Approach A) for 90% of cases. Only drop to vanilla Three.js (Approach B) when you need WebGPU compute shaders for particle simulations, physics, or GPU-driven animation with 10K+ objects.

## Next.js Setup

Three.js must be client-only. Always dynamic import heavy scenes.

```tsx
// components/scene-wrapper.tsx
"use client";
import dynamic from "next/dynamic";

const HeroScene = dynamic(() => import("./hero-scene"), {
  ssr: false,
  loading: () => <div className="h-screen bg-black" />,
});

export function SceneWrapper() {
  return <HeroScene />;
}
```

## Canvas Boilerplate (R3F — WebGL, covers 90% of use cases)

```tsx
// components/hero-scene.tsx
"use client";
import { Canvas } from "@react-three/fiber";
import { Suspense } from "react";
import {
  Environment,
  PerspectiveCamera,
} from "@react-three/drei";

export default function HeroScene() {
  return (
    <div className="absolute inset-0 -z-10">
      <Canvas
        dpr={[1, 2]}
        gl={{ antialias: true, alpha: true }}
      >
        <PerspectiveCamera makeDefault position={[0, 0, 5]} fov={45} />
        <Suspense fallback={null}>
          <Scene />
          <Environment preset="city" />
        </Suspense>
      </Canvas>
    </div>
  );
}

function Scene() {
  return (
    <>
      <ambientLight intensity={0.4} />
      <directionalLight position={[5, 5, 5]} intensity={1} castShadow />
      {/* Your 3D content here */}
    </>
  );
}
```

## Vanilla Three.js + WebGPU Boilerplate (for compute-heavy scenes)

```tsx
// components/gpu-scene.tsx
"use client";
import { useRef, useEffect } from "react";
import { createRenderer } from "@/lib/gpu-renderer";
import * as THREE from "three";

export default function GPUScene() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    let renderer: THREE.WebGLRenderer | any;
    let rafId: number;
    let disposed = false;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(45, 1, 0.1, 100);
    camera.position.z = 5;

    async function init() {
      const result = await createRenderer(canvasRef.current!);
      if (disposed) { result.renderer.dispose(); return; }
      renderer = result.renderer;

      const resize = () => {
        const w = canvasRef.current!.clientWidth;
        const h = canvasRef.current!.clientHeight;
        renderer.setSize(w, h);
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        camera.aspect = w / h;
        camera.updateProjectionMatrix();
      };
      resize();
      window.addEventListener("resize", resize);

      // Add scene content here
      scene.add(new THREE.AmbientLight(0xffffff, 0.5));

      const animate = () => {
        rafId = requestAnimationFrame(animate);
        renderer.render(scene, camera);
      };
      animate();
    }

    init();

    return () => {
      disposed = true;
      cancelAnimationFrame(rafId);
      renderer?.dispose();
      scene.traverse((child) => {
        if (child instanceof THREE.Mesh) {
          child.geometry.dispose();
          const mat = child.material;
          (Array.isArray(mat) ? mat : [mat]).forEach((m) => m.dispose());
        }
      });
    };
  }, []);

  return <canvas ref={canvasRef} className="h-full w-full" />;
}
```
```

---

## Common 3D Patterns

### Floating / Breathing Object

```tsx
import { useRef } from "react";
import { useFrame } from "@react-three/fiber";
import { MeshDistortMaterial } from "@react-three/drei";
import * as THREE from "three";

export function FloatingBlob() {
  const meshRef = useRef<THREE.Mesh>(null);

  useFrame(({ clock }) => {
    const t = clock.elapsedTime;
    meshRef.current!.rotation.x = t * 0.15;
    meshRef.current!.rotation.y = t * 0.2;
    meshRef.current!.position.y = Math.sin(t * 0.5) * 0.3;
  });

  return (
    <mesh ref={meshRef} scale={2}>
      <sphereGeometry args={[1, 64, 64]} />
      <MeshDistortMaterial
        color="#6366f1"
        roughness={0.1}
        metalness={0.8}
        distort={0.4}
        speed={2}
      />
    </mesh>
  );
}
```

### Particle Field (Instanced)

For thousands of particles, use InstancedMesh (not individual meshes).

```tsx
import { useRef, useMemo } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from "three";

const PARTICLE_COUNT = 2000;

export function ParticleField() {
  const meshRef = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);

  const particles = useMemo(() => {
    return Array.from({ length: PARTICLE_COUNT }, () => ({
      position: [
        (Math.random() - 0.5) * 20,
        (Math.random() - 0.5) * 20,
        (Math.random() - 0.5) * 20,
      ] as [number, number, number],
      speed: 0.01 + Math.random() * 0.02,
      offset: Math.random() * Math.PI * 2,
    }));
  }, []);

  useFrame(({ clock }) => {
    const t = clock.elapsedTime;

    particles.forEach((p, i) => {
      dummy.position.set(
        p.position[0] + Math.sin(t * p.speed + p.offset) * 0.5,
        p.position[1] + Math.cos(t * p.speed + p.offset) * 0.5,
        p.position[2]
      );
      dummy.updateMatrix();
      meshRef.current!.setMatrixAt(i, dummy.matrix);
    });

    meshRef.current!.instanceMatrix.needsUpdate = true;
  });

  return (
    <instancedMesh ref={meshRef} args={[undefined, undefined, PARTICLE_COUNT]}>
      <sphereGeometry args={[0.02, 8, 8]} />
      <meshBasicMaterial color="#ffffff" transparent opacity={0.6} />
    </instancedMesh>
  );
}
```

### Gradient Mesh Background

A soft, animated gradient using a custom shader.

```tsx
import { useRef } from "react";
import { useFrame, extend } from "@react-three/fiber";
import { shaderMaterial } from "@react-three/drei";
import * as THREE from "three";

const GradientMaterial = shaderMaterial(
  {
    uTime: 0,
    uColor1: new THREE.Color("#6366f1"),
    uColor2: new THREE.Color("#ec4899"),
    uColor3: new THREE.Color("#06b6d4"),
  },
  // Vertex
  `varying vec2 vUv;
   void main() {
     vUv = uv;
     gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
   }`,
  // Fragment
  `uniform float uTime;
   uniform vec3 uColor1;
   uniform vec3 uColor2;
   uniform vec3 uColor3;
   varying vec2 vUv;

   void main() {
     float noise = sin(vUv.x * 3.0 + uTime * 0.3) * cos(vUv.y * 3.0 + uTime * 0.2) * 0.5 + 0.5;
     vec3 color = mix(uColor1, uColor2, vUv.x + noise * 0.3);
     color = mix(color, uColor3, vUv.y + noise * 0.2);
     gl_FragColor = vec4(color, 1.0);
   }`
);

extend({ GradientMaterial });

export function GradientBackground() {
  const matRef = useRef<any>(null);

  useFrame(({ clock }) => {
    matRef.current.uTime = clock.elapsedTime;
  });

  return (
    <mesh scale={[20, 20, 1]} position={[0, 0, -5]}>
      <planeGeometry args={[1, 1, 1, 1]} />
      {/* @ts-ignore */}
      <gradientMaterial ref={matRef} />
    </mesh>
  );
}
```

### Scroll-Linked 3D Rotation

Connect scroll progress to 3D object rotation using GSAP ScrollTrigger.

```tsx
"use client";
import { useRef, useEffect, useState } from "react";
import { Canvas, useFrame } from "@react-three/fiber";
import { gsap, ScrollTrigger } from "@/lib/gsap";
import * as THREE from "three";

function RotatingModel({ progress }: { progress: { value: number } }) {
  const meshRef = useRef<THREE.Mesh>(null);

  useFrame(() => {
    meshRef.current!.rotation.y = progress.value * Math.PI * 2;
    meshRef.current!.position.y = Math.sin(progress.value * Math.PI) * 0.5;
  });

  return (
    <mesh ref={meshRef}>
      <boxGeometry args={[1.5, 1.5, 1.5]} />
      <meshStandardMaterial color="#6366f1" roughness={0.3} metalness={0.7} />
    </mesh>
  );
}

export function ScrollLinked3D() {
  const containerRef = useRef<HTMLDivElement>(null);
  const progressRef = useRef({ value: 0 });

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.to(progressRef.current, {
        value: 1,
        ease: "none",
        scrollTrigger: {
          trigger: containerRef.current,
          start: "top top",
          end: "bottom bottom",
          scrub: 1,
        },
      });
    }, containerRef);

    return () => ctx.revert();
  }, []);

  return (
    <div ref={containerRef} className="relative h-[300vh]">
      <div className="sticky top-0 h-screen">
        <Canvas camera={{ position: [0, 0, 5] }}>
          <ambientLight intensity={0.5} />
          <directionalLight position={[3, 3, 3]} />
          <RotatingModel progress={progressRef.current} />
        </Canvas>
      </div>
    </div>
  );
}
```

---

## Image / Hover Distortion (WebGL)

Distort an image on hover using a displacement shader.

```tsx
import { useRef, useState } from "react";
import { useFrame, useLoader } from "@react-three/fiber";
import { shaderMaterial } from "@react-three/drei";
import * as THREE from "three";

// Simplified — full distortion shader would use a noise/displacement texture
export function HoverDistortImage({ src }: { src: string }) {
  const texture = useLoader(THREE.TextureLoader, src);
  const [hovered, setHovered] = useState(false);
  const matRef = useRef<any>(null);
  const targetRef = useRef(0);

  useFrame(() => {
    targetRef.current += ((hovered ? 1 : 0) - targetRef.current) * 0.05;
    if (matRef.current) {
      matRef.current.uniforms.uHover.value = targetRef.current;
    }
  });

  return (
    <mesh
      onPointerEnter={() => setHovered(true)}
      onPointerLeave={() => setHovered(false)}
    >
      <planeGeometry args={[4, 3, 32, 32]} />
      <shaderMaterial
        ref={matRef}
        uniforms={{
          uTexture: { value: texture },
          uHover: { value: 0 },
        }}
        vertexShader={`
          uniform float uHover;
          varying vec2 vUv;
          void main() {
            vUv = uv;
            vec3 pos = position;
            pos.z += sin(pos.x * 5.0 + pos.y * 5.0) * uHover * 0.1;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
          }
        `}
        fragmentShader={`
          uniform sampler2D uTexture;
          varying vec2 vUv;
          void main() {
            gl_FragColor = texture2D(uTexture, vUv);
          }
        `}
      />
    </mesh>
  );
}
```

---

## Performance Rules for 3D

1. **Limit draw calls**: use InstancedMesh for repeated geometry
2. **dpr={[1, 2]}**: cap pixel ratio on Canvas
3. **Dispose on unmount**: textures, geometries, materials need `.dispose()`
4. **Use `<Suspense>`**: always wrap scenes for async loading
5. **Lazy-load entire Canvas**: `dynamic(() => import('./scene'), { ssr: false })`
6. **Simplify on mobile**: reduce particle count, lower geometry detail via `ScrollTrigger.matchMedia` or viewport width check
7. **No orbit controls in production** unless the interaction requires it
8. **Profile**: use `window.__THREE_DEVTOOLS__` or Chrome Performance tab
