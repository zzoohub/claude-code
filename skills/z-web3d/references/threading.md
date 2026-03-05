# Multi-Thread Architecture Reference

3D/XR apps must keep the main thread free for rendering and XR frame submission. Offload all heavy computation to background threads. This reference covers every browser multithreading option, when to use each, and how to wire them together.

> For framework-specific main thread consumer patterns (R3F useFrame sync): `react/performance.md`

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
- Niche use case -- only reach for this when you genuinely need cross-tab state sharing

### 3. Worker Pool (Manual)

Spawn N Dedicated Workers and distribute tasks across them. Essential for chunked parallel work: terrain generation, mesh processing, LOD computation, batch asset loading.

```typescript
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

const chunks = await Promise.all(
  chunkCoords.map(coord => pool.post({ type: 'generate', coord }))
)
```

### 4. WASM Threads (pthread / rayon)

WASM modules can spawn their own threads internally using `wasm-bindgen-rayon`. Best for massive parallel compute: particle simulation, voxel processing, fluid dynamics, large-scale pathfinding.

See `references/wasm.md` for setup and build instructions.

### 5. Worklets

| Worklet | Use in 3D/XR | Support |
|---|---|---|
| **AudioWorklet** | Spatial audio processing, HRTF, real-time audio synthesis | Stable, all modern browsers |
| AnimationWorklet | Main-thread-independent animations | Experimental, limited support |
| PaintWorklet | CSS custom painting | Not relevant to 3D/XR |

Only **AudioWorklet** is practical for 3D/XR:

```typescript
await audioContext.audioWorklet.addModule('/audio/spatial-processor.js')
const node = new AudioWorkletNode(audioContext, 'spatial-processor')
node.connect(audioContext.destination)

// Send listener position from render loop
node.port.postMessage({ listenerPos: [x, y, z], listenerQuat: [qx, qy, qz, qw] })
```

### 6. GPU Compute (WebGPU Compute Shader)

Not CPU multithreading -- this is GPU parallel processing. Thousands of threads executing simultaneously on the GPU. Use for particles, boids, post-processing, and any embarrassingly parallel simulation that operates on large buffers.

Accessible via TSL compute shaders (see `references/shaders.md`) or raw WebGPU `computePipeline`.

---

## Decision Guide: What Goes Where

| Task | Where | Why |
|---|---|---|
| Rendering, scene graph updates | Main thread | WebGL/WebGPU context is main-thread-only |
| XR frame submission | Main thread | `requestAnimationFrame` callback |
| UI | Main thread | DOM access required |
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

**Cost**: ~1ms per MB of data.

**Use for**: Small messages, one-shot results, configuration, events.

### Pattern 2: Transferable Objects (Zero-Copy Ownership Transfer)

Transfer ownership of an `ArrayBuffer` to another thread. The sender loses access. Zero-copy.

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

### Pattern 3: SharedArrayBuffer (Concurrent Shared Memory)

Both threads read/write the same memory simultaneously.

```typescript
// Main thread: create and share
const sab = new SharedArrayBuffer(ENTITY_COUNT * 3 * 4)
const positions = new Float32Array(sab)

worker.postMessage({ type: 'init', buffer: sab, count: ENTITY_COUNT })

// Worker: write simulation results directly
self.onmessage = (e) => {
  if (e.data.type === 'init') {
    const positions = new Float32Array(e.data.buffer)
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
// geometry.attributes.position.needsUpdate = true
```

**Cost**: Zero transfer cost. Potential race conditions on individual values, but for transform data this is acceptable.

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

`SharedArrayBuffer` requires Cross-Origin Isolation.

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

**Side effects of COEP**: All cross-origin resources must either have `Cross-Origin-Resource-Policy: cross-origin` header or be loaded with `crossorigin` attribute.

### Feature Detection

```typescript
const canUseSharedArrayBuffer = typeof SharedArrayBuffer !== 'undefined'
const isCrossOriginIsolated = self.crossOriginIsolated === true

if (!isCrossOriginIsolated) {
  console.warn('SharedArrayBuffer unavailable -- falling back to postMessage')
}
```

---

## SharedArrayBuffer Layout Convention

Define a structured layout so both threads agree on where data lives:

```typescript
// shared/buffer-layout.ts
export const ENTITY_STRIDE = 16  // floats per entity

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

export function entityOffset(entityIndex: number): number {
  return entityIndex * ENTITY_STRIDE
}

export function createSharedTransformBuffer(maxEntities: number): SharedArrayBuffer {
  return new SharedArrayBuffer(maxEntities * ENTITY_STRIDE * 4)
}
```

Both the Worker and main thread import the same layout module.

---

## Race Conditions and Synchronization

For transform data (positions, rotations), tearing is visually imperceptible -- no synchronization needed.

For data where consistency matters (entity alive/dead flags, state transitions), use `Atomics`:

```typescript
// Worker: set entity as dead
Atomics.store(flagsView, entityIndex, DEAD_FLAG)

// Main thread: check
const flags = Atomics.load(flagsView, entityIndex)
if (flags & DEAD_FLAG) { /* remove from scene */ }
```

---

## Performance Rules

**DO:**
- Pre-allocate all `SharedArrayBuffer`s at startup
- Use `Transferable` for one-shot results
- Keep `postMessage` payloads small (<1KB) for per-frame communication
- Use `DynamicDrawUsage` on BufferAttributes that update from SharedArrayBuffer every frame
- Match Worker tick rate to render rate (60Hz) or use fixed timestep with interpolation

**DON'T:**
- Don't `postMessage` large Float32Arrays every frame
- Don't create/destroy Workers per task (use a pool or long-lived Workers)
- Don't share `WebGLRenderingContext` or `GPUDevice` across threads (not possible)
- Don't use `Atomics.wait()` on the main thread (it blocks rendering)
