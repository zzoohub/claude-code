# Rapier Physics & @react-three/rapier Reference

Rapier is a Rust-based physics engine compiled to WASM. `@react-three/rapier` v2 provides declarative R3F bindings.

## Setup

```bash
bun add @react-three/rapier
```

v2 supports R3F v9 + React 19. v1 supports R3F v8 + React 18.

```tsx
import { Canvas } from '@react-three/fiber'
import { Physics } from '@react-three/rapier'
import { Suspense } from 'react'

<Canvas>
  <Suspense fallback={null}>
    <Physics gravity={[0, -9.81, 0]} debug={false}>
      <Scene />
    </Physics>
  </Suspense>
</Canvas>
```

Physics must be wrapped in `<Suspense>` (lazy WASM init).

> **Note**: `@react-three/rapier` runs on the **main thread**. For physics-heavy apps (many bodies, complex simulation, 60fps target), use the **Raw Rapier Worker pattern** below instead.

### Physics Props

| Prop | Default | Description |
|---|---|---|
| `gravity` | `[0, -9.81, 0]` | World gravity vector |
| `timeStep` | `1/60` | Fixed timestep or `"vary"` for variable |
| `paused` | `false` | Pause simulation |
| `interpolate` | `true` | Interpolate between physics steps |
| `updateLoop` | `"follow"` | `"follow"` syncs with R3F, `"independent"` runs own rAF |
| `debug` | `false` | Render collider wireframes |
| `numSolverIterations` | `4` | Constraint solver iterations |
| `colliders` | -- | Default auto-collider for all RigidBodies |

## RigidBody

```tsx
import { RigidBody } from '@react-three/rapier'

<RigidBody
  type="dynamic"              // "dynamic" | "fixed" | "kinematicPosition" | "kinematicVelocity"
  position={[0, 5, 0]}
  rotation={[0, 0, 0]}
  colliders="cuboid"          // auto-collider: "cuboid" | "ball" | "hull" | "trimesh" | false
  restitution={0.5}           // bounciness
  friction={0.7}
  mass={1.0}                  // or density={1.0}
  linearDamping={0.0}
  angularDamping={0.0}
  gravityScale={1.0}
  ccd={false}                 // Continuous Collision Detection
  enabledTranslations={[true, true, true]}
  enabledRotations={[true, true, true]}
  // Events
  onCollisionEnter={({ manifold, target, other }) => {}}
  onCollisionExit={({ target, other }) => {}}
  onIntersectionEnter={({ target, other }) => {}}
  onIntersectionExit={({ target, other }) => {}}
  onContactForce={({ totalForceMagnitude, target, other }) => {}}
  // Collision groups
  collisionGroups={interactionGroups(0, [0, 1])}
>
  <mesh>
    <boxGeometry args={[1, 1, 1]} />
    <meshStandardMaterial color="red" />
  </mesh>
</RigidBody>
```

### Body Types

| Type | Description |
|---|---|
| `"dynamic"` | Fully simulated, affected by gravity/forces/collisions |
| `"fixed"` | Immovable, infinite mass (floors, walls) |
| `"kinematicPosition"` | Moved via `nextTranslation`/`nextRotation` each frame |
| `"kinematicVelocity"` | Moved via `linvel`/`angvel` each frame |

### Collision Event Payload

```typescript
interface CollisionPayload {
  target: { rigidBody, rigidBodyObject, collider, colliderObject }
  other: { rigidBody, rigidBodyObject, collider, colliderObject }
  manifold?: ContactManifold  // only onCollisionEnter
}
```

## Colliders

### Auto-Colliders

```tsx
<RigidBody colliders="cuboid">...</RigidBody>  // bounding box
<RigidBody colliders="ball">...</RigidBody>     // bounding sphere
<RigidBody colliders="hull">...</RigidBody>     // convex hull
<RigidBody colliders="trimesh" type="fixed">    // triangle mesh (static only!)
<RigidBody colliders={false}>                   // manual colliders
```

### Explicit Colliders

```tsx
import {
  CuboidCollider, BallCollider, CapsuleCollider,
  CylinderCollider, ConeCollider, HeightfieldCollider,
  ConvexHullCollider, TrimeshCollider, MeshCollider
} from '@react-three/rapier'

<CuboidCollider args={[0.5, 0.5, 0.5]} />       // half-extents
<BallCollider args={[0.5]} />                     // radius
<CapsuleCollider args={[0.5, 0.25]} />            // halfHeight, radius
<HeightfieldCollider args={[w, h, heights, scale]} />
```

### MeshCollider

Generates colliders from mesh geometry:

```tsx
<RigidBody colliders={false}>
  <MeshCollider type="trimesh">
    <mesh geometry={complexGeometry} />
  </MeshCollider>
</RigidBody>
```

### Compound Colliders

Multiple colliders in one RigidBody:

```tsx
<RigidBody colliders={false}>
  <BallCollider args={[0.5]} position={[0, 0, 0]} />
  <BallCollider args={[0.5]} position={[1, 0, 0]} />
</RigidBody>
```

## Sensors

Detect overlap without contact forces:

```tsx
<RigidBody type="fixed">
  <CuboidCollider
    args={[5, 5, 1]}
    sensor
    onIntersectionEnter={() => console.log('entered zone')}
    onIntersectionExit={() => console.log('left zone')}
  />
</RigidBody>
```

## Collision Groups

```tsx
import { interactionGroups } from '@react-three/rapier'

// interactionGroups(membership, filter) -- groups 0-15
<RigidBody collisionGroups={interactionGroups(0, [0, 1])}>  {/* group 0, interacts with 0,1 */}
<RigidBody collisionGroups={interactionGroups(1, [0, 1])}>  {/* group 1, interacts with 0,1 */}
<CuboidCollider sensor collisionGroups={interactionGroups(2, [0])} /> {/* group 2, only with 0 */}
```

Both colliders must match each other's groups for interaction.

## Joints

All joint hooks take two RigidBody refs:

```tsx
const bodyA = useRef<RapierRigidBody>(null)
const bodyB = useRef<RapierRigidBody>(null)
```

**Fixed** -- no relative motion:

```tsx
const joint = useFixedJoint(bodyA, bodyB, [
  [0, 0, 0], [0, 0, 0, 1],  // anchor + orientation in A
  [0, 0, 0], [0, 0, 0, 1],  // anchor + orientation in B
])
```

**Spherical** -- 3 rotational DOF (ball joint):

```tsx
const joint = useSphericalJoint(bodyA, bodyB, [
  [0, 0, 0],    // anchor in A
  [0, -1, 0],   // anchor in B
])
```

**Revolute** -- rotation around one axis (hinge, wheel):

```tsx
const joint = useRevoluteJoint(bodyA, bodyB, [
  [0, 0, 0],    // anchor in A
  [0, 0, 0],    // anchor in B
  [0, 1, 0],    // rotation axis
])

// Motor
useFrame(() => {
  joint.current?.configureMotorVelocity(10, 1.0)
})
```

**Prismatic** -- translation along one axis (slider, piston):

```tsx
const joint = usePrismaticJoint(bodyA, bodyB, [
  [0, 0, 0], [0, 0, 0], [0, 1, 0],  // anchors + axis
])
```

**Rope** -- max distance limit:

```tsx
const joint = useRopeJoint(bodyA, bodyB, [
  [0, 0, 0], [0, 0, 0], 2.0,  // anchors + length
])
```

**Spring** -- elastic connection:

```tsx
const joint = useSpringJoint(bodyA, bodyB, [
  [0, 0, 0], [0, 0, 0],  // anchors
  1.0,   // rest length
  10.0,  // stiffness
  0.5,   // damping
])
```

## useRapier

Direct access to the Rapier world:

```tsx
const { world, rapier, isPaused, step, setWorld } = useRapier()

// Snapshot / restore
const snapshot = world.takeSnapshot()
const restored = rapier.World.restoreSnapshot(snapshot)
setWorld(restored)

// Manual step
step(1 / 60)
```

## Physics Step Hooks

```tsx
import { useBeforePhysicsStep, useAfterPhysicsStep } from '@react-three/rapier'

// Apply forces before each step
useBeforePhysicsStep((world) => {
  bodyRef.current?.applyImpulse({ x: 0, y: 0, z: -0.1 }, true)
})

// Read results after each step
useAfterPhysicsStep((world) => {
  const pos = bodyRef.current?.translation()
})
```

## Performance: InstancedRigidBodies

For many identical physics objects:

```tsx
import { InstancedRigidBodies, InstancedRigidBodyProps } from '@react-three/rapier'

const COUNT = 500
const instances = useMemo<InstancedRigidBodyProps[]>(() =>
  Array.from({ length: COUNT }, (_, i) => ({
    key: `inst_${i}`,
    position: [Math.random() * 20 - 10, Math.random() * 20 + 10, Math.random() * 20 - 10] as [number, number, number],
    rotation: [Math.random() * Math.PI, Math.random() * Math.PI, 0] as [number, number, number],
  })), [])

<InstancedRigidBodies ref={rigidBodies} instances={instances} colliders="cuboid">
  <instancedMesh args={[undefined, undefined, COUNT]} count={COUNT}>
    <boxGeometry args={[0.5, 0.5, 0.5]} />
    <meshStandardMaterial color="orange" />
  </instancedMesh>
</InstancedRigidBodies>

// Access individual bodies:
rigidBodies.current[40].applyImpulse({ x: 0, y: 10, z: 0 }, true)
```

## Common Patterns

### Character Controller

```tsx
function Character() {
  const bodyRef = useRef<RapierRigidBody>(null)

  useBeforePhysicsStep(() => {
    if (!bodyRef.current) return
    const vel = bodyRef.current.linvel()
    let vx = 0, vz = 0
    if (keys.left) vx = -5
    if (keys.right) vx = 5
    if (keys.forward) vz = -5
    if (keys.back) vz = 5
    bodyRef.current.setLinvel({ x: vx, y: vel.y, z: vz }, true)
    if (keys.jump && isGrounded) {
      bodyRef.current.applyImpulse({ x: 0, y: 8, z: 0 }, true)
    }
  })

  return (
    <RigidBody ref={bodyRef} type="dynamic" lockRotations
      onCollisionEnter={({ other }) => {
        if (other.rigidBodyObject?.name === 'floor') setGrounded(true)
      }}
      onCollisionExit={({ other }) => {
        if (other.rigidBodyObject?.name === 'floor') setGrounded(false)
      }}
    >
      <CapsuleCollider args={[0.5, 0.25]} />
      <mesh><capsuleGeometry args={[0.25, 1]} /><meshStandardMaterial /></mesh>
    </RigidBody>
  )
}
```

### Vehicle (Revolute Joints + Motors)

```tsx
function Car() {
  const chassis = useRef<RapierRigidBody>(null)
  const wheelFL = useRef<RapierRigidBody>(null)
  // ... more wheels

  const jointFL = useRevoluteJoint(chassis, wheelFL, [
    [-1, -0.5, 1.5], [0, 0, 0], [1, 0, 0],
  ])

  useFrame(() => {
    jointFL.current?.configureMotorVelocity(targetSpeed, 1.0)
  })

  return (
    <>
      <RigidBody ref={chassis} colliders="cuboid" type="dynamic">
        <mesh><boxGeometry args={[2, 0.5, 4]} /></mesh>
      </RigidBody>
      <RigidBody ref={wheelFL} colliders="hull" type="dynamic">
        <mesh rotation={[Math.PI / 2, 0, 0]}>
          <cylinderGeometry args={[0.4, 0.4, 0.3, 16]} />
        </mesh>
      </RigidBody>
    </>
  )
}
```

### Independent Physics Loop

For demand-based rendering:

```tsx
<Physics updateLoop="independent">
  {/* Physics runs own rAF, calls invalidate only when bodies active */}
</Physics>
```

---

## Raw Rapier Worker Pattern

Use when: many rigid bodies, 60fps target, main thread must stay free for rendering.

**When to use `@react-three/rapier` (main thread)**
- Simple scenes, <20 bodies
- Prototyping
- Don't need custom Worker logic

**When to use Raw Rapier Worker**
- Physics-heavy simulation (PhysPlay, games)
- Custom Rust WASM solvers alongside Rapier
- 60fps target with complex scenes

### Worker Setup

```typescript
// workers/physics.worker.ts
import('@dimforge/rapier3d').then(async (RAPIER) => {
  await RAPIER.init()

  const gravity = { x: 0, y: -9.81, z: 0 }
  const world = new RAPIER.World(gravity)
  let transforms: Float32Array

  self.onmessage = (e) => {
    const { type, payload } = e.data

    if (type === 'init') {
      transforms = new Float32Array(payload.buffer)
      // spawn bodies from payload.bodies...
      self.postMessage({ type: 'ready' })
      tick()
    }

    if (type === 'reset') {
      // re-init world from new challenge config
    }
  }

  function tick() {
    world.step()

    // Write results into SharedArrayBuffer
    world.bodies.forEach((body, i) => {
      const t = body.translation()
      const r = body.rotation()
      const offset = i * 7
      transforms[offset + 0] = t.x
      transforms[offset + 1] = t.y
      transforms[offset + 2] = t.z
      transforms[offset + 3] = r.x
      transforms[offset + 4] = r.y
      transforms[offset + 5] = r.z
      transforms[offset + 6] = r.w
    })

    setTimeout(tick, 1000 / 60)
  }
})
```

### Main Thread — R3F Sync

```tsx
const MAX_BODIES = 64
const sab = new SharedArrayBuffer(MAX_BODIES * 7 * 4) // 7 floats: xyz + xyzw
const transforms = new Float32Array(sab)

// Send to worker once
worker.postMessage({ type: 'init', buffer: sab, bodies: [...] })

// R3F sync system
function PhysicsSyncSystem({ meshRefs }: { meshRefs: RefObject<THREE.Mesh>[] }) {
  useFrame(() => {
    meshRefs.forEach((ref, i) => {
      if (!ref.current) return
      const o = i * 7
      ref.current.position.set(transforms[o], transforms[o+1], transforms[o+2])
      ref.current.quaternion.set(transforms[o+3], transforms[o+4], transforms[o+5], transforms[o+6])
    })
  })
  return null
}
```

### postMessage Fallback (no COOP/COEP)

If SharedArrayBuffer is unavailable (no COOP/COEP headers):

```typescript
// Worker: send results each frame
self.postMessage({ type: 'tick', transforms: Float32Array })
// ~14KB/s for 60 bodies @ 60fps — acceptable cost
// Use Transferable if needed: self.postMessage(data, [data.transforms.buffer])
```
