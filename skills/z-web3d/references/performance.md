# 3D Performance Reference

General performance principles for Three.js / WebGPU applications. Framework-agnostic.

> For React-specific performance (R3F patterns, Drei helpers): `react/performance.md`

## Key Rules

1. **Never trigger UI re-renders in the render loop** -- mutate Three.js objects directly
2. **Use instancing** for repeated geometry (reduces thousands of draw calls to 1)
3. **Reuse geometry and materials** -- create once, share across meshes
4. **Dispose resources** -- WebGL/WebGPU resources aren't garbage-collected
5. **Use `DynamicDrawUsage`** for BufferAttributes that update every frame
6. **Render on demand** for non-animated scenes (render only when scene changes)

## Draw Call Budget

| Platform | Target Draw Calls | Target Triangles |
|---|---|---|
| Desktop | < 500 | < 2M |
| Mobile | < 200 | < 500K |
| XR (90fps) | < 300 | < 1M |

Each unique material + geometry combination = one draw call. Instancing collapses many objects with the same material+geometry into one draw call.

## Instancing

```typescript
const COUNT = 1000
const geometry = new THREE.BoxGeometry(1, 1, 1)
const material = new THREE.MeshStandardNodeMaterial({ color: 'orange' })
const mesh = new THREE.InstancedMesh(geometry, material, COUNT)

const dummy = new THREE.Object3D()
for (let i = 0; i < COUNT; i++) {
  dummy.position.set(Math.random() * 20, 0, Math.random() * 20)
  dummy.updateMatrix()
  mesh.setMatrixAt(i, dummy.matrix)
}
mesh.instanceMatrix.needsUpdate = true
scene.add(mesh)
```

Per-instance colors:

```typescript
mesh.instanceColor = new THREE.InstancedBufferAttribute(
  new Float32Array(COUNT * 3), 3
)
mesh.setColorAt(i, new THREE.Color('red'))
mesh.instanceColor.needsUpdate = true
```

## Level of Detail (LOD)

```typescript
const lod = new THREE.LOD()
lod.addLevel(highDetailMesh, 0)    // distance 0-50
lod.addLevel(medDetailMesh, 50)    // distance 50-100
lod.addLevel(lowDetailMesh, 100)   // distance 100+
scene.add(lod)

// In render loop:
lod.update(camera)
```

## Geometry Merging

For static scenes where objects don't move independently:

```typescript
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js'

const geometries = meshes.map(m => {
  const geo = m.geometry.clone()
  geo.applyMatrix4(m.matrixWorld)
  return geo
})
const merged = mergeGeometries(geometries, false)
const mergedMesh = new THREE.Mesh(merged, sharedMaterial)
// Many meshes -> one draw call
```

## Adaptive Resolution

```typescript
function updateDPR(fps: number) {
  if (fps < 50) {
    renderer.setPixelRatio(Math.max(1, window.devicePixelRatio - 0.5))
  } else if (fps > 58) {
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
  }
}
```

## Render on Demand

For scenes that aren't continuously animated:

```typescript
let needsRender = true

function invalidate() { needsRender = true }

renderer.setAnimationLoop(() => {
  if (!needsRender) return
  needsRender = false
  renderer.render(scene, camera)
})

// Call invalidate() when scene changes:
controls.addEventListener('change', invalidate)
```

## Profiling

```typescript
// Frame time
const stats = new Stats()
document.body.appendChild(stats.dom)
renderer.setAnimationLoop(() => {
  stats.begin()
  renderer.render(scene, camera)
  stats.end()
})

// Draw call count
console.log(renderer.info.render.calls)
console.log(renderer.info.render.triangles)

// GPU memory
console.log(renderer.info.memory.geometries)
console.log(renderer.info.memory.textures)
```

## Common Bottlenecks

| Symptom | Likely Cause | Fix |
|---|---|---|
| Low FPS, high draw calls | Too many unique meshes | Instance or merge |
| Low FPS, low draw calls | Heavy fragment shader / overdraw | Simplify materials, reduce transparency |
| Stutter on interaction | GC pauses from allocations in loop | Pre-allocate vectors, reuse objects |
| Slow first load | Large assets | Compress with meshopt, use KTX2 textures |
| Memory leak | Undisposed geometries/materials/textures | `dispose()` on removal |
| Mobile jank | Too many triangles or too-high DPR | Reduce geometry, adaptive DPR |
