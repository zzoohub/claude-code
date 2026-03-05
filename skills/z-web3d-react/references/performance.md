# Performance Reference

## Key Rules

1. **Never setState in useFrame** -- mutate refs directly
2. **Use instancing** for repeated geometry (reduces thousands of draw calls to 1)
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
