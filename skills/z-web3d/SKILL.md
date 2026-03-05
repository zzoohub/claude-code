---
name: z-web3d
description: |
  Build 3D and immersive web experiences with Three.js (WebGPU-first), TSL shaders, Koota ECS, Rapier physics, Rust WASM, and WebXR.
  Use this skill whenever the user works on: 3D scenes, WebGL/WebGPU rendering, Three.js shaders (TSL/node materials), VR/AR/XR/mixed reality, spatial computing, immersive experiences, 3D physics simulation, ECS game architecture, particle systems, procedural geometry, glTF models, spatial audio, hand tracking, controller input, head-mounted displays, or any task involving three/webgpu, three/tsl, koota, @dimforge/rapier3d, or WebXR.
  Also trigger when the user mentions "three.js", "webxr", "webgpu", "TSL", "node material", "shader", "ECS", "rapier", or "wasm" in a 3D/game context.
  Framework-specific implementations (React/R3F, Solid, Svelte) are in `references/<framework>/`.
references:
  - references/shaders.md
  - references/ecs.md
  - references/physics.md
  - references/web-xr.md
  - references/wasm.md
  - references/threading.md
  - references/assets.md
  - references/performance.md
  - references/react/setup.md
  - references/react/drei.md
  - references/react/ecs.md
  - references/react/physics.md
  - references/react/web-xr.md
  - references/react/wasm.md
  - references/react/performance.md
---

# Web 3D & XR Development

## Tech Stack

| Layer | Technology |
|---|---|
| Rendering | Three.js (WebGPU-first, WebGL fallback) |
| Shaders | TSL (Three Shader Language) |
| State (Simulation) | Koota ECS |
| Physics | Rapier (Rust WASM) |
| High-perf Compute | Rust WASM (custom modules) |
| XR | WebXR Device API |
| Assets | glTF 2.0 |

Framework bindings (React Three Fiber, Threlte, etc.) are layered on top. The core stack is framework-agnostic.

## Reference Files

Read the relevant reference file when working on a specific domain:

| File | When to read |
|---|---|
| `references/shaders.md` | TSL syntax, node materials, compute shaders, custom effects |
| `references/ecs.md` | Koota traits, queries, systems, game loop |
| `references/physics.md` | Rapier raw API, rigid bodies, colliders, Worker pattern |
| `references/web-xr.md` | WebXR Device API, session types, input sources, hand tracking |
| `references/wasm.md` | Rust WASM setup, wasm-bindgen, memory patterns |
| `references/threading.md` | Multi-thread architecture, Worker separation, SharedArrayBuffer |
| `references/assets.md` | glTF optimization pipeline, texture best practices |
| `references/performance.md` | General 3D performance: instancing, LOD, draw calls, GPU budget |

### Framework-Specific References

| Framework | References |
|---|---|
| **React** (R3F + Drei) | `references/react/setup.md`, `references/react/drei.md`, `references/react/ecs.md`, `references/react/physics.md`, `references/react/web-xr.md`, `references/react/wasm.md`, `references/react/performance.md` |

## Staying Current

This is a fast-moving domain. The architectural patterns and principles in this skill are stable, but specific API signatures may change. When writing code that touches a specific library's API, verify against the latest documentation using Context7 (`resolve-library-id` then `query-docs`). Prioritize Context7 lookup for: Three.js node material APIs, WebXR hook signatures, Koota trait/query API, and Rapier component props.

---

## WebGPU-First Setup

Import from `three/webgpu` instead of `three`. This gives WebGPU rendering with automatic WebGL 2 fallback (~95% WebGPU browser coverage as of early 2026, remaining ~5% falls back seamlessly).

```typescript
import * as THREE from 'three/webgpu'

const renderer = new THREE.WebGPURenderer({
  antialias: true,
  alpha: true,
  powerPreference: 'high-performance',
})
await renderer.init()

const scene = new THREE.Scene()
const camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000)
camera.position.z = 5

renderer.setSize(width, height)
renderer.setAnimationLoop(() => {
  renderer.render(scene, camera)
})
document.body.appendChild(renderer.domElement)
```

WebGPURenderer init is **async** -- await it before starting the render loop.

Use **Node materials** (`MeshStandardNodeMaterial`, `MeshPhysicalNodeMaterial`, etc.) instead of classic materials when targeting TSL/WebGPU.

### Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import wasm from 'vite-plugin-wasm'
import topLevelAwait from 'vite-plugin-top-level-await'

export default defineConfig({
  plugins: [wasm(), topLevelAwait()],
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

Add framework plugin (e.g., `@vitejs/plugin-react`, `vite-plugin-solid`, `@sveltejs/vite-plugin-svelte`) as needed.

---

## Core Three.js Patterns

### Scene Graph

```typescript
const mesh = new THREE.Mesh(
  new THREE.SphereGeometry(1, 32, 32),
  new THREE.MeshStandardNodeMaterial({ color: 'hotpink', roughness: 0.4 })
)
mesh.position.set(0, 1, 0)
mesh.castShadow = true
scene.add(mesh)
```

### Render Loop

Mutate objects directly in the render loop. Never trigger framework re-renders at 60fps.

```typescript
renderer.setAnimationLoop((time) => {
  const delta = clock.getDelta()
  mesh.rotation.y += delta
  renderer.render(scene, camera)
})
```

`delta` is seconds since last frame -- use it for frame-rate-independent animation.

### Loading Assets

```typescript
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js'
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js'

const loader = new GLTFLoader()
loader.setMeshoptDecoder(MeshoptDecoder)

const gltf = await loader.loadAsync('/model.glb')
const model = gltf.scene
scene.add(model)

// Play animations
const mixer = new THREE.AnimationMixer(model)
const action = mixer.clipAction(gltf.animations[0])
action.play()

// In render loop:
mixer.update(delta)
```

### Event System (Raycasting)

```typescript
const raycaster = new THREE.Raycaster()
const pointer = new THREE.Vector2()

canvas.addEventListener('pointermove', (event) => {
  pointer.x = (event.clientX / window.innerWidth) * 2 - 1
  pointer.y = -(event.clientY / window.innerHeight) * 2 + 1
})

// In render loop:
raycaster.setFromCamera(pointer, camera)
const intersects = raycaster.intersectObjects(scene.children)
if (intersects.length > 0) {
  // intersects[0].object, intersects[0].point, etc.
}
```

---

## Architecture: Separating Concerns

### Thread Architecture

3D/XR apps are performance-critical. Offload heavy work from the main thread to keep rendering smooth.

| Thread | Responsibility |
|---|---|
| **Main thread** | Rendering + XR frame + UI |
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
| UI state (menus, HUD, settings) | Framework state (Zustand, signals, stores) | Simple event-driven get/set, no entity overhead |
| Physics state | Rapier | WASM-powered, deterministic, handled by physics world |
| Render state | Three.js | Scene graph, materials, animations |

Koota manages the game/simulation world. Framework state manages everything outside the game loop (pause menu, settings, inventory UI). They coexist cleanly -- see `references/ecs.md` for the core ECS patterns.

### System Execution Order

Systems are plain functions called in order. The order matters.

```typescript
function gameLoop(world: World, delta: number) {
  inputSystem(world)
  movementSystem(world, delta)
  collisionSystem(world)
  syncTransformsSystem(world)   // ECS -> Three.js scene graph
  cleanupSystem(world)
}
```

---

## glTF 2.0 Asset Pipeline

glTF (`.glb`) is the only asset format. See `references/assets.md` for the full optimization pipeline and texture best practices.

---

## Quick Reference: Common Imports

```typescript
// Core
import * as THREE from 'three/webgpu'

// TSL
import { Fn, uniform, float, vec2, vec3, vec4, color,
  positionLocal, normalLocal, uv, time,
  sin, cos, mix, smoothstep, mx_noise_float,
  texture, storage, instanceIndex } from 'three/tsl'

// ECS
import { createWorld, trait, relation } from 'koota'

// Physics (raw Rapier)
import RAPIER from '@dimforge/rapier3d'
```

For framework-specific imports (R3F, Drei, etc.), see `references/react/setup.md`.
