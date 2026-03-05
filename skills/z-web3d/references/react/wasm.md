# R3F + WASM Integration Patterns

> For core Rust WASM setup and API: `../wasm.md`

## Terrain Generator Component

```tsx
import { useMemo } from 'react'
import * as THREE from 'three'
import { TerrainGenerator } from '../crates/my-wasm-3d/pkg'

function WasmTerrain({ width = 128, depth = 128 }) {
  const geometry = useMemo(() => {
    const terrain = new TerrainGenerator(width, depth, 0.5, 10.0)
    const geo = new THREE.BufferGeometry()
    geo.setAttribute('position', new THREE.BufferAttribute(terrain.positions(), 3))
    geo.setAttribute('normal', new THREE.BufferAttribute(terrain.normals(), 3))
    geo.setAttribute('uv', new THREE.BufferAttribute(terrain.uvs(), 2))
    geo.setIndex(new THREE.BufferAttribute(terrain.indices(), 1))
    terrain.free()
    return geo
  }, [width, depth])

  return (
    <mesh geometry={geometry}>
      <meshStandardMaterial color="#3a7d44" />
    </mesh>
  )
}
```

## Particle System (Zero-Copy)

```tsx
import { useRef, useMemo, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import * as THREE from 'three'
import { ParticleSystem } from '../crates/my-wasm-3d/pkg'
import { memory } from '../crates/my-wasm-3d/pkg/my_wasm_3d_bg.wasm'

function WasmParticles() {
  const pointsRef = useRef<THREE.Points>(null)
  const systemRef = useRef<ParticleSystem | null>(null)

  const geometry = useMemo(() => {
    const system = new ParticleSystem(500_000)
    systemRef.current = system
    const posArray = new Float32Array(memory.buffer, system.positions_ptr(), 500_000 * 3)
    const geo = new THREE.BufferGeometry()
    const attr = new THREE.BufferAttribute(posArray, 3)
    attr.setUsage(THREE.DynamicDrawUsage)
    geo.setAttribute('position', attr)
    return geo
  }, [])

  useFrame((_, delta) => {
    if (!systemRef.current) return
    systemRef.current.update(delta)
    const posAttr = geometry.attributes.position as THREE.BufferAttribute
    if (posAttr.array.buffer !== memory.buffer) {
      const newView = new Float32Array(
        memory.buffer, systemRef.current.positions_ptr(), 500_000 * 3)
      geometry.setAttribute('position', new THREE.BufferAttribute(newView, 3))
    }
    geometry.attributes.position.needsUpdate = true
  })

  useEffect(() => () => { systemRef.current?.free() }, [])

  return (
    <points geometry={geometry}>
      <pointsMaterial size={0.02} color="#88ccff" />
    </points>
  )
}
```

## SharedArrayBuffer Physics Sync

```tsx
function PhysicsSyncSystem({ buffer, count }: { buffer: SharedArrayBuffer; count: number }) {
  const transforms = useMemo(() => new Float32Array(buffer), [buffer])
  const meshRefs = useRef<THREE.Mesh[]>([])

  useFrame(() => {
    for (let i = 0; i < count; i++) {
      const mesh = meshRefs.current[i]
      if (!mesh) continue
      const offset = i * 7
      mesh.position.set(transforms[offset], transforms[offset+1], transforms[offset+2])
      mesh.quaternion.set(transforms[offset+3], transforms[offset+4], transforms[offset+5], transforms[offset+6])
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
