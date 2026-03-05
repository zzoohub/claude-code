---
name: z-web3d-react
description: |
  Build 3D and immersive web experiences with Three.js (WebGPU-first), React Three Fiber, Drei, TSL shaders, Koota ECS, Rapier physics, Rust WASM, and WebXR.
  Use this skill whenever the user works on: 3D scenes, WebGL/WebGPU rendering, R3F components, Three.js shaders (TSL/node materials), VR/AR/XR/mixed reality, spatial computing, immersive experiences, 3D physics simulation, ECS game architecture, particle systems, procedural geometry, glTF models, spatial audio, hand tracking, controller input, head-mounted displays, or any task involving @react-three/fiber, @react-three/drei, @react-three/xr, @react-three/rapier, three/webgpu, three/tsl, or koota.
  Also trigger when the user mentions "three.js", "r3f", "drei", "webxr", "webgpu", "TSL", "node material", "shader", "ECS", "rapier", or "wasm" in a 3D/game context.
---

# Web 3D & XR Development

## Tech Stack

| Layer | Technology |
|---|---|
| Rendering | Three.js (WebGPU-first, WebGL fallback) |
| Shaders | TSL (Three Shader Language) |
| 3D Framework | React Three Fiber v9 + Drei v10 |
| XR | WebXR Device API + @react-three/xr v6 |
| State (UI/Meta) | Zustand |
| State (Simulation) | Koota ECS |
| Physics | Rapier via @react-three/rapier v2 |
| High-perf Compute | Rust WASM (custom modules) |
| Assets | glTF 2.0 |

## Reference Files

Read the relevant reference file when working on a specific domain:

| File | When to read |
|---|---|
| `references/shaders.md` | TSL syntax, node materials, compute shaders, custom effects |
| `references/ecs.md` | Koota traits, queries, systems, React integration, game loop |
| `references/web-xr.md` | VR/AR sessions, controllers, hand tracking, hit testing, anchors |
| `references/physics.md` | Rigid bodies, colliders, joints, character controllers, sensors |
| `references/wasm.md` | Rust WASM setup, wasm-bindgen, memory patterns |
| `references/threading.md` | Multi-thread architecture, Worker separation, SharedArrayBuffer, data transfer |
| `references/drei.md` | Environment, controls, text, HTML overlay helpers |
| `references/performance.md` | Instancing, merged meshes, adaptive DPR, LOD |
| `references/assets.md` | glTF optimization pipeline, texture best practices |

## Staying Current

This is a fast-moving domain. The architectural patterns and principles in this skill are stable, but specific API signatures may change. When writing code that touches a specific library's API, verify against the latest documentation using Context7 (`resolve-library-id` then `query-docs`). Prioritize Context7 lookup for: Three.js node material APIs, @react-three/xr hook signatures, Koota trait/query API, and @react-three/rapier component props.

---

## WebGPU-First R3F Setup

Import from `three/webgpu` instead of `three`. This gives WebGPU rendering with automatic WebGL 2 fallback (~95% WebGPU browser coverage as of early 2026, remaining ~5% falls back seamlessly).

```tsx
import * as THREE from 'three/webgpu'
import { Canvas, extend } from '@react-three/fiber'
import { useState } from 'react'

// Extend R3F's catalog with WebGPU-compatible classes
extend(THREE as any)

function App() {
  const [frameloop, setFrameloop] = useState<'never' | 'always'>('never')

  return (
    <Canvas
      frameloop={frameloop}
      gl={async (props) => {
        const renderer = new THREE.WebGPURenderer({
          ...props,
          antialias: true,
          alpha: true,
          powerPreference: 'high-performance',
        } as any)
        await renderer.init()
        setFrameloop('always')
        return renderer
      }}
    >
      <Scene />
    </Canvas>
  )
}
```

WebGPURenderer init is **async** -- set `frameloop="never"` until ready, then flip to `"always"`.

### Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import wasm from 'vite-plugin-wasm'
import topLevelAwait from 'vite-plugin-top-level-await'

export default defineConfig({
  plugins: [react(), wasm(), topLevelAwait()],
  build: { target: 'esnext' },
  server: {
    headers: {
      // Required only if using SharedArrayBuffer (WASM threads)
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    },
  },
})
```

---

## Core R3F Patterns

### JSX Maps to Three.js

Every JSX element maps directly to a Three.js class. Constructor args use the `args` prop.

```tsx
<mesh position={[0, 1, 0]} castShadow>
  <sphereGeometry args={[1, 32, 32]} />
  <meshStandardNodeMaterial color="hotpink" roughness={0.4} />
</mesh>
```

Use **Node materials** (`MeshStandardNodeMaterial`, `MeshPhysicalNodeMaterial`, etc.) instead of classic materials when targeting TSL/WebGPU.

### useFrame -- The Render Loop

Mutate refs directly inside `useFrame`. Never call `setState` here -- it triggers 60 re-renders/sec.

```tsx
import { useFrame } from '@react-three/fiber'

function Spinner() {
  const ref = useRef<THREE.Mesh>(null!)
  useFrame((_, delta) => {
    ref.current.rotation.y += delta
  })
  return (
    <mesh ref={ref}>
      <boxGeometry />
      <meshStandardNodeMaterial color="orange" />
    </mesh>
  )
}
```

`delta` is seconds since last frame -- use it for frame-rate-independent animation.

### Loading Assets

```tsx
import { useGLTF, useTexture, useAnimations } from '@react-three/drei'

function Model() {
  const { nodes, materials, animations } = useGLTF('/model.glb')
  const group = useRef<THREE.Group>(null!)
  const { actions } = useAnimations(animations, group)

  useEffect(() => {
    actions['Idle']?.reset().fadeIn(0.5).play()
  }, [])

  return (
    <group ref={group}>
      <mesh geometry={nodes.Body.geometry} material={materials.Skin} />
    </group>
  )
}
useGLTF.preload('/model.glb')
```

Drei's `useGLTF` enables meshoptimizer decompression by default. Use `gltfjsx` CLI to generate typed R3F components from glTF files:

```bash
npx gltfjsx model.glb --transform --types --shadow
```

`--transform` produces a meshoptimizer-compressed, texture-optimized, deduplicated `.glb` (near-instant decode, no WASM decoder overhead unlike Draco).

### Event System

R3F supports pointer events via raycasting. Same events work on desktop, mobile, and XR (controllers/hands).

```tsx
<mesh
  onClick={(e) => { e.stopPropagation(); handleClick(e.point) }}
  onPointerOver={() => setHovered(true)}
  onPointerOut={() => setHovered(false)}
>
```

`e.stopPropagation()` prevents the event from hitting objects behind.

---

## Drei Essentials

Drei provides Environment/lighting presets, OrbitControls, 3D Text, Html overlays, and more. See `references/drei.md` for usage examples.

---

## Performance

### Key Rules

1. **Never setState in useFrame** -- mutate refs directly
2. **Use instancing** for repeated geometry (reduces thousands of draw calls to 1)
3. **Reuse geometry/materials** via `useMemo`
4. **Use `<Suspense>`** for async loading with fallbacks
5. **Set `frameloop="demand"`** for non-animated scenes (renders only on invalidate)
6. **Dispose resources** -- WebGL/WebGPU resources aren't garbage-collected

See `references/performance.md` for instancing patterns, merged meshes, adaptive DPR, and LOD.

---

## Architecture: Separating Concerns

### Thread Architecture

3D/XR apps are performance-critical. Offload heavy work from the main thread to keep rendering smooth.

| Thread | Responsibility |
|---|---|
| **Main thread** | Rendering + XR frame + React UI |
| **Worker 1** | Physics (Rapier WASM) |
| **Worker 2** | ECS system tick (Koota) |
| **Worker N** | Procedural generation, pathfinding, etc. (pool) |
| **WASM Threads** | Massive parallel compute (Rust rayon) |
| **GPU Compute** | Particles, boids, post-processing (TSL compute shaders) |
| **AudioWorklet** | Spatial audio processing |

The general pattern: Workers write simulation results into `SharedArrayBuffer`, main thread reads every frame to update Three.js transforms. This requires COOP/COEP headers (already in the Vite config above).

For full details on Worker separation, data transfer patterns (postMessage vs SharedArrayBuffer vs Transferable), and WASM threading setup, see `references/threading.md`.

### State Boundaries

| Domain | Tool | Why |
|---|---|---|
| Simulation state (entities, positions, health, AI) | Koota ECS | Archetype storage, batch iteration, 60fps+ updates |
| UI state (menus, HUD, settings) | Zustand | Simple event-driven get/set, no entity overhead |
| Physics state | Rapier | WASM-powered, deterministic, handled by physics world |
| Render state | R3F / Three.js | Scene graph, materials, animations |

Koota manages the game/simulation world. Zustand manages everything outside the game loop (pause menu, settings, inventory UI). They coexist cleanly -- see `references/ecs.md` for the integration pattern.

### System Execution Order

Systems are plain functions called in `useFrame`. Order matters.

```tsx
function GameSystems() {
  const world = useWorld()
  useFrame((_, delta) => {
    inputSystem(world)
    movementSystem(world, delta)
    collisionSystem(world)
    syncTransformsSystem(world)   // ECS -> Three.js scene graph
    cleanupSystem(world)
  })
  return null
}
```

---

## glTF 2.0 Asset Pipeline

glTF (`.glb`) is the only asset format. Use `gltfjsx --transform` for Draco compression + texture optimization (70-90% size reduction), `useGLTF` to load, and `useGLTF.preload()` in module scope.

See `references/assets.md` for the full optimization pipeline and texture best practices.

---

## Quick Reference: Common Imports

```tsx
// Core
import * as THREE from 'three/webgpu'
import { Canvas, useFrame, useThree, extend } from '@react-three/fiber'

// TSL
import { Fn, uniform, float, vec2, vec3, vec4, color,
  positionLocal, normalLocal, uv, time,
  sin, cos, mix, smoothstep, mx_noise_float,
  texture, storage, instanceIndex } from 'three/tsl'

// Drei
import { Environment, OrbitControls, useGLTF, useAnimations,
  Text, Html, Instances, Instance, Merged, Float,
  ContactShadows, PerformanceMonitor, AdaptiveDpr } from '@react-three/drei'

// XR
import { createXRStore, XR, XROrigin, XRSpace,
  useXR, useHitTest, useXRInputSourceState,
  IfInSessionMode, TeleportTarget } from '@react-three/xr'

// Physics
import { Physics, RigidBody, CuboidCollider, BallCollider,
  interactionGroups } from '@react-three/rapier'

// ECS
import { createWorld, trait, relation } from 'koota'
import { WorldProvider, useWorld, useQuery, useTrait,
  useActions } from 'koota/react'
```
