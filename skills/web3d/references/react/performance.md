# R3F Performance Reference

> For general 3D performance principles: `../performance.md`

## Key Rules

1. **Never setState in useFrame** -- mutate refs directly
2. **Use Drei instancing** for repeated geometry
3. **Reuse geometry/materials** via `useMemo`
4. **Use `<Suspense>`** for async loading with fallbacks
5. **Set `frameloop="demand"`** for non-animated scenes (renders only on invalidate)
6. **Dispose resources** -- WebGL/WebGPU resources aren't garbage-collected

## Instancing with Drei

```tsx
import { Instances, Instance } from '@react-three/drei'

<Instances limit={1000}>
  <boxGeometry />
  <meshStandardNodeMaterial />
  {items.map((item, i) => (
    <Instance key={i} position={item.pos} color={item.color} />
  ))}
</Instances>
```

## Merged Meshes (Multi-Geometry Instancing)

```tsx
import { Merged, useGLTF } from '@react-three/drei'

function Scene() {
  const { nodes } = useGLTF('/furniture.glb')
  return (
    <Merged meshes={{ Chair: nodes.Chair, Table: nodes.Table }}>
      {({ Chair, Table }) => (
        <>
          <Chair position={[0, 0, 0]} />
          <Chair position={[2, 0, 0]} />
          <Table position={[1, 0, 1]} />
        </>
      )}
    </Merged>
  )
}
```

Each unique mesh type = **one draw call** regardless of instance count.

## Adaptive Performance

```tsx
import { PerformanceMonitor, AdaptiveDpr } from '@react-three/drei'

<Canvas dpr={[1, 2]}>
  <PerformanceMonitor onDecline={() => setDegraded(true)} onIncline={() => setDegraded(false)}>
    <AdaptiveDpr pixelated />
    <Scene degraded={degraded} />
  </PerformanceMonitor>
</Canvas>
```

## LOD (Level of Detail)

```tsx
import { Detailed } from '@react-three/drei'

<Detailed distances={[0, 50, 100]}>
  <HighDetail />
  <MediumDetail />
  <LowDetail />
</Detailed>
```

## Worker Sync Pattern

When using SharedArrayBuffer from a physics/ECS Worker:

```tsx
function WorkerSyncSystem({ buffer, meshRefs, count }: Props) {
  const transforms = useMemo(() => new Float32Array(buffer), [buffer])

  useFrame(() => {
    for (let i = 0; i < count; i++) {
      const mesh = meshRefs.current[i]
      if (!mesh) continue
      const o = i * 7
      mesh.position.set(transforms[o], transforms[o+1], transforms[o+2])
      mesh.quaternion.set(transforms[o+3], transforms[o+4], transforms[o+5], transforms[o+6])
    }
  })
  return null
}
```
