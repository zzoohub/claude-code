# Multi-Thread Architecture Reference

3D/XR apps must keep the main thread free for rendering and XR frame submission. Offload all heavy computation to background threads. This reference covers every browser multithreading option, when to use each, and how to wire them together.

## Browser Multithreading Options

### 1. Dedicated Worker (`new Worker()`)

The workhorse of browser multithreading. 1:1 thread per Worker instance. Use for physics, ECS ticks, pathfinding, and any sustained background computation.

```typescript
const worker = new Worker(
  new URL('./workers/physics.worker.ts', import.meta.url),
  { type: 'module' }
)
```

- Full browser support
- Each Worker has its own global scope (`self`), no DOM access
- Communication via `postMessage` or `SharedArrayBuffer`

### 2. SharedWorker

A single Worker shared across multiple tabs/iframes. Useful for multi-window XR apps (e.g., spectator view + player view sharing game state).

```typescript
const shared = new SharedWorker(
  new URL('./workers/shared-state.worker.ts', import.meta.url),
  { type: 'module' }
)
shared.port.onmessage = (e) => { /* ... */ }
shared.port.postMessage({ type: 'sync' })
```

- **Limited support**: no Safari, partial Firefox
- Communicates via `MessagePort`
- Niche use case — only reach for this when you genuinely need cross-tab state sharing

### 3. Worker Pool (Manual)

Spawn N Dedicated Workers and distribute tasks across them. Essential for chunked parallel work: terrain generation, mesh processing, LOD computation, batch asset loading.

```typescript
// Simple round-robin pool
class WorkerPool {
  private workers: Worker[]
  private next = 0

  constructor(url: URL, size: number) {
    this.workers = Array.from({ length: size },
      () => new Worker(url, { type: 'module' })
    )
  }

  post(message: any, transfer?: Transferable[]) {
    const worker = this.workers[this.next % this.workers.length]
    this.next++
    return new Promise((resolve) => {
      worker.onmessage = (e) => resolve(e.data)
      worker.postMessage(message, transfer ?? [])
    })
  }

  terminate() { this.workers.forEach(w => w.terminate()) }
}

// Usage
const pool = new WorkerPool(
  new URL('./workers/terrain-chunk.worker.ts', import.meta.url),
  navigator.hardwareConcurrency
)

// Generate terrain chunks in parallel
const chunks = await Promise.all(
  chunkCoords.map(coord => pool.post({ type: 'generate', coord }))
)
```

Libraries like `comlink` (Proxy-based RPC) or `workerpool` can simplify the API, but a manual pool is often sufficient.

### 4. WASM Threads (pthread / rayon)

WASM modules can spawn their own threads internally using `wasm-bindgen-rayon`. Under the hood, this creates Web Workers automatically, but the JS layer doesn't manage them — the WASM runtime does. Best for massive parallel compute: particle simulation, voxel processing, fluid dynamics, large-scale pathfinding.

```rust
use rayon::prelude::*;
pub use wasm_bindgen_rayon::init_thread_pool;

#[wasm_bindgen]
pub fn parallel_particle_update(positions: &mut [f32], velocities: &[f32], dt: f32) {
    positions.par_chunks_mut(3).zip(velocities.par_chunks(3)).for_each(|(pos, vel)| {
        pos[0] += vel[0] * dt;
        pos[1] += vel[1] * dt;
        pos[2] += vel[2] * dt;
    });
}
```

```typescript
import init, { initThreadPool, parallel_particle_update } from '../crates/my-wasm-3d/pkg'

await init()
await initThreadPool(navigator.hardwareConcurrency)
// Now all rayon parallel iterators run across real threads
```

**Requires**: nightly Rust, atomics target feature, COOP/COEP headers, `SharedArrayBuffer` support.

Build command:

```bash
RUSTFLAGS='-C target-feature=+atomics,+bulk-memory,+mutable-globals' \
  rustup run nightly wasm-pack build --target web -- -Z build-std=panic_abort,std
```

### 5. Worklets

Specialized thread-like execution contexts for specific browser subsystems.

| Worklet | Use in 3D/XR | Support |
|---|---|---|
| **AudioWorklet** | Spatial audio processing, HRTF, real-time audio synthesis | Stable, all modern browsers |
| AnimationWorklet | Main-thread-independent animations | Experimental, limited support |
| PaintWorklet | CSS custom painting | Not relevant to 3D/XR |

Only **AudioWorklet** is practical for 3D/XR:

```typescript
// Register processor
await audioContext.audioWorklet.addModule('/audio/spatial-processor.js')
const node = new AudioWorkletNode(audioContext, 'spatial-processor')
node.connect(audioContext.destination)

// Send listener position from render loop
node.port.postMessage({ listenerPos: [x, y, z], listenerQuat: [qx, qy, qz, qw] })
```

### 6. GPU Compute (WebGPU Compute Shader)

Not CPU multithreading — this is GPU parallel processing. Thousands of threads executing simultaneously on the GPU. Use for particles, boids, post-processing, and any embarrassingly parallel simulation that operates on large buffers.

Accessible via TSL compute shaders (see `references/shaders.md`) or raw WebGPU `computePipeline`.

**Key tradeoff**: CPU-GPU data transfer has latency. Keep data on the GPU when possible. If you need CPU readback (e.g., collision results), the round-trip cost can negate the GPU speedup for small workloads.

---

## Decision Guide: What Goes Where

| Task | Where | Why |
|---|---|---|
| Rendering, scene graph updates | Main thread | WebGL/WebGPU context is main-thread-only |
| XR frame submission | Main thread | `requestAnimationFrame` callback |
| React UI | Main thread | DOM access required |
| Physics simulation | Dedicated Worker | Rapier WASM is CPU-heavy, deterministic stepping |
| ECS system tick | Dedicated Worker | Batch entity iteration at fixed rate |
| Pathfinding, AI decisions | Dedicated Worker or Pool | Can be async, results consumed next frame |
| Terrain/mesh generation | Worker Pool | Chunked, parallelizable, one-shot |
| Massive parallel compute (>100K elements) | WASM Threads | rayon saturates all cores, no JS overhead |
| Particles, boids (GPU-friendly) | GPU Compute | Massively parallel, data stays on GPU |
| Post-processing effects | GPU Compute / TSL | Fragment shader or compute pipeline |
| Spatial audio | AudioWorklet | Dedicated audio thread, no jank |
| Asset loading/decoding | Dedicated Worker | Prevents main thread stalls on large glTF |

**Rule of thumb**: if the task runs every frame and takes >2ms, move it off the main thread. If it's a one-shot task that takes >16ms, move it off the main thread.

---

## Data Transfer Patterns

The biggest architectural decision in multi-threaded 3D is how data moves between threads.

### Pattern 1: postMessage (Structured Clone)

Data is deep-copied between threads. Simple but expensive for large payloads.

```typescript
// Worker
self.postMessage({ positions: new Float32Array(1000), metadata: { count: 333 } })

// Main thread
worker.onmessage = (e) => {
  const { positions, metadata } = e.data
  // positions is a COPY
}
```

**Cost**: ~1ms per MB of data. A 1M-particle system (12MB of float32 positions) would cost ~12ms per frame just in serialization — unacceptable at 60fps.

**Use for**: Small messages, one-shot results, configuration, events.

### Pattern 2: Transferable Objects (Zero-Copy Ownership Transfer)

Transfer ownership of an `ArrayBuffer` to another thread. The sender loses access (buffer becomes detached, zero-length). Zero-copy — only a pointer changes hands.

```typescript
// Worker: generate terrain, transfer result
const positions = new Float32Array(width * depth * 3)
// ... fill positions ...
self.postMessage(
  { type: 'terrain', positions },
  [positions.buffer]  // Transfer list
)
// positions.byteLength === 0 after this (detached)

// Main thread: receive and use
worker.onmessage = (e) => {
  const positions = e.data.positions  // Now owned by main thread
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3))
}
```

**Cost**: Near-zero (pointer transfer).

**Use for**: One-shot results (generated terrain, decoded assets), ping-pong buffers.

**Limitation**: Only one thread can hold the buffer at a time. Not suitable for continuous shared state.

### Pattern 3: SharedArrayBuffer (Concurrent Shared Memory)

Both threads read/write the same memory simultaneously. The foundation for real-time simulation data sharing.

```typescript
// Main thread: create and share
const sab = new SharedArrayBuffer(ENTITY_COUNT * 3 * 4)  // 3 floats per entity
const positions = new Float32Array(sab)

worker.postMessage({ type: 'init', buffer: sab, count: ENTITY_COUNT })

// Worker: write simulation results directly
self.onmessage = (e) => {
  if (e.data.type === 'init') {
    const positions = new Float32Array(e.data.buffer)
    // Physics/ECS loop writes positions continuously
    function tick() {
      for (let i = 0; i < count * 3; i += 3) {
        positions[i] += velocities[i] * dt
        positions[i + 1] += velocities[i + 1] * dt
        positions[i + 2] += velocities[i + 2] * dt
      }
      setTimeout(tick, 1000 / 60)
    }
    tick()
  }
}

// Main thread render loop: read without any copy
useFrame(() => {
  geometry.attributes.position.needsUpdate = true
  // Three.js reads from the same SharedArrayBuffer
})
```

**Cost**: Zero transfer cost. Potential race conditions on individual values, but for transform data (positions, rotations) this is acceptable — a one-frame-stale position is visually imperceptible.

**Use for**: Continuous simulation data (physics transforms, ECS state, particle positions).

**Requires COOP/COEP headers** (see below).

### Choosing a Pattern

| Scenario | Pattern | Reason |
|---|---|---|
| Physics transforms updated every frame | SharedArrayBuffer | Zero-copy continuous read |
| Generated terrain chunk (one-shot) | Transferable | Zero-copy, ownership transfer |
| "Pause game" command | postMessage | Tiny payload, infrequent |
| Worker reports error/status | postMessage | Small event message |
| Ping-pong double buffer | Transferable | Alternating ownership |
| WASM memory shared with main thread | SharedArrayBuffer (via WASM) | Direct memory view |

---

## COOP/COEP Headers

`SharedArrayBuffer` requires Cross-Origin Isolation. Without these headers, `SharedArrayBuffer` is undefined.

### Vite Dev Server

```typescript
// vite.config.ts
export default defineConfig({
  server: {
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    },
  },
  // Also set for preview server
  preview: {
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    },
  },
})
```

### Production

Set headers at the CDN/server level:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

**Side effects of COEP**: All cross-origin resources (images, scripts, fonts) must either:
- Be served with `Cross-Origin-Resource-Policy: cross-origin` header, or
- Be loaded with `crossorigin` attribute

This affects CDN-hosted assets, Google Fonts, analytics scripts, etc. Plan for this early.

### Feature Detection

```typescript
const canUseSharedArrayBuffer = typeof SharedArrayBuffer !== 'undefined'
const isCrossOriginIsolated = self.crossOriginIsolated === true

if (!isCrossOriginIsolated) {
  console.warn('SharedArrayBuffer unavailable — falling back to postMessage')
  // Use Transferable or postMessage patterns instead
}
```

---

## Typical 3D/XR Threading Architecture

### Layout

```
Main Thread                    Worker Threads
┌──────────────────────┐      ┌──────────────────────┐
│  React UI            │      │  Physics Worker       │
│  R3F Canvas          │      │  (Rapier WASM)        │
│  Three.js Renderer   │◄─SAB─┤  Writes transforms    │
│  XR Frame Loop       │      │  to SharedArrayBuffer  │
│                      │      └──────────────────────┘
│  useFrame():         │      ┌──────────────────────┐
│    read SAB          │      │  ECS Worker           │
│    update scene graph│◄─SAB─┤  (Koota systems)      │
│    needsUpdate=true  │      │  AI, movement, logic   │
│                      │      └──────────────────────┘
│  GPU Compute:        │      ┌──────────────────────┐
│    particles         │      │  Worker Pool          │
│    post-processing   │◄─TFR─┤  Terrain chunks       │
└──────────────────────┘      │  Mesh generation      │
                              │  Asset decoding       │
         ┌──────────────┐     └──────────────────────┘
         │ AudioWorklet  │     ┌──────────────────────┐
         │ Spatial audio │     │  WASM Threads         │
         └──────────────┘     │  (rayon auto-managed)  │
                              │  Massive parallel ops  │
                              └──────────────────────┘

SAB = SharedArrayBuffer (continuous)
TFR = Transferable (one-shot ownership transfer)
```

### SharedArrayBuffer Layout Convention

Define a structured layout so both threads agree on where data lives:

```typescript
// shared/buffer-layout.ts
export const ENTITY_STRIDE = 16  // floats per entity

// Per-entity offsets (in floats)
export const POS_X = 0
export const POS_Y = 1
export const POS_Z = 2
export const ROT_X = 3
export const ROT_Y = 4
export const ROT_Z = 5
export const ROT_W = 6
export const VEL_X = 7
export const VEL_Y = 8
export const VEL_Z = 9
export const FLAGS = 10  // bitfield: alive, active, dirty, etc.
// 11-15 reserved

export function entityOffset(entityIndex: number): number {
  return entityIndex * ENTITY_STRIDE
}

export function createSharedTransformBuffer(maxEntities: number): SharedArrayBuffer {
  return new SharedArrayBuffer(maxEntities * ENTITY_STRIDE * 4)  // 4 bytes per float32
}
```

Both the Worker and main thread import the same layout module. The Worker writes simulation results; the main thread reads them in `useFrame`.

### Worker Setup Pattern

```typescript
// workers/physics.worker.ts
import init, { PhysicsWorld } from '../crates/my-wasm-3d/pkg'
import { ENTITY_STRIDE, POS_X, POS_Y, POS_Z, ROT_X, ROT_Y, ROT_Z, ROT_W } from '../shared/buffer-layout'

let transforms: Float32Array
let physicsWorld: PhysicsWorld

self.onmessage = async (e: MessageEvent) => {
  const { type, payload } = e.data

  if (type === 'init') {
    await init()
    transforms = new Float32Array(payload.buffer)
    physicsWorld = new PhysicsWorld(payload.entityCount)
    self.postMessage({ type: 'ready' })
    tick()
  }
}

function tick() {
  physicsWorld.step(1 / 60)

  // Write results into SharedArrayBuffer
  for (let i = 0; i < physicsWorld.body_count(); i++) {
    const offset = i * ENTITY_STRIDE
    const pos = physicsWorld.get_position(i)
    const rot = physicsWorld.get_rotation(i)
    transforms[offset + POS_X] = pos.x
    transforms[offset + POS_Y] = pos.y
    transforms[offset + POS_Z] = pos.z
    transforms[offset + ROT_X] = rot.x
    transforms[offset + ROT_Y] = rot.y
    transforms[offset + ROT_Z] = rot.z
    transforms[offset + ROT_W] = rot.w
  }

  setTimeout(tick, 1000 / 60)
}
```

### Main Thread Consumer (R3F)

```tsx
function PhysicsSyncSystem({ buffer, count }: { buffer: SharedArrayBuffer; count: number }) {
  const transforms = useMemo(() => new Float32Array(buffer), [buffer])
  const meshRefs = useRef<THREE.Mesh[]>([])

  useFrame(() => {
    for (let i = 0; i < count; i++) {
      const mesh = meshRefs.current[i]
      if (!mesh) continue
      const offset = i * ENTITY_STRIDE
      mesh.position.set(
        transforms[offset + POS_X],
        transforms[offset + POS_Y],
        transforms[offset + POS_Z]
      )
      mesh.quaternion.set(
        transforms[offset + ROT_X],
        transforms[offset + ROT_Y],
        transforms[offset + ROT_Z],
        transforms[offset + ROT_W]
      )
    }
  })

  return (
    <group>
      {Array.from({ length: count }, (_, i) => (
        <mesh key={i} ref={(el) => { if (el) meshRefs.current[i] = el }}>
          <boxGeometry />
          <meshStandardNodeMaterial />
        </mesh>
      ))}
    </group>
  )
}
```

---

## Race Conditions and Synchronization

For transform data (positions, rotations), tearing across a single frame is visually imperceptible — no synchronization needed. The main thread reads whatever the Worker last wrote.

For data where consistency matters (e.g., entity alive/dead flags, state transitions), use `Atomics`:

```typescript
// Worker: set entity as dead
Atomics.store(flagsView, entityIndex, DEAD_FLAG)

// Main thread: check
const flags = Atomics.load(flagsView, entityIndex)
if (flags & DEAD_FLAG) { /* remove from scene */ }
```

For complex state transitions that span multiple fields, use a dirty flag or double-buffering:

```typescript
// Double buffer pattern
const bufferA = new SharedArrayBuffer(size)
const bufferB = new SharedArrayBuffer(size)
let writeBuffer = new Float32Array(bufferA)
let readBuffer = new Float32Array(bufferB)

// Worker writes to writeBuffer, then swaps via postMessage
// Main thread reads from readBuffer, then swaps on signal
```

---

## Performance Rules

**DO:**
- Pre-allocate all `SharedArrayBuffer`s at startup (avoid runtime growth)
- Use `Transferable` for one-shot results (terrain, decoded assets)
- Keep `postMessage` payloads small (<1KB) for per-frame communication
- Profile Worker overhead with `performance.now()` — the Worker itself has ~0.1ms message overhead
- Use `DynamicDrawUsage` on BufferAttributes that update from SharedArrayBuffer every frame
- Match Worker tick rate to render rate (60Hz) or use fixed timestep with interpolation

**DON'T:**
- Don't `postMessage` large Float32Arrays every frame (use SharedArrayBuffer instead)
- Don't create/destroy Workers per task (use a pool or long-lived Workers)
- Don't assume `setTimeout(fn, 0)` in a Worker runs immediately — it's clamped to ~1ms minimum
- Don't share `WebGLRenderingContext` or `GPUDevice` across threads (not possible, main thread only)
- Don't use `Atomics.wait()` on the main thread (it blocks rendering)
