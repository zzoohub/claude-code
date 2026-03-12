# @react-three/rapier Reference

Declarative R3F bindings for Rapier physics. v2 supports R3F v9 + React 19.

> For raw Rapier API and Worker pattern: `../physics.md`

## Setup

```bash
bun add @react-three/rapier
```

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

> **Note**: `@react-three/rapier` runs on the **main thread**. For physics-heavy apps (many bodies, complex simulation, 60fps target), use the **Raw Rapier Worker pattern** in `../physics.md` instead.

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
  restitution={0.5}
  friction={0.7}
  mass={1.0}
  linearDamping={0.0}
  angularDamping={0.0}
  gravityScale={1.0}
  ccd={false}                 // Continuous Collision Detection
  enabledTranslations={[true, true, true]}
  enabledRotations={[true, true, true]}
  onCollisionEnter={({ manifold, target, other }) => {}}
  onCollisionExit={({ target, other }) => {}}
  onIntersectionEnter={({ target, other }) => {}}
  onIntersectionExit={({ target, other }) => {}}
  onContactForce={({ totalForceMagnitude, target, other }) => {}}
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
```

### Sensors

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

<RigidBody collisionGroups={interactionGroups(0, [0, 1])}>  {/* group 0, interacts with 0,1 */}
<RigidBody collisionGroups={interactionGroups(1, [0, 1])}>  {/* group 1, interacts with 0,1 */}
```

## Joints

```tsx
const bodyA = useRef<RapierRigidBody>(null)
const bodyB = useRef<RapierRigidBody>(null)

// Revolute (hinge)
const joint = useRevoluteJoint(bodyA, bodyB, [
  [0, 0, 0], [0, 0, 0], [0, 1, 0],  // anchors + axis
])

// Motor
useFrame(() => {
  joint.current?.configureMotorVelocity(10, 1.0)
})

// Spring
const spring = useSpringJoint(bodyA, bodyB, [
  [0, 0, 0], [0, 0, 0], 1.0, 10.0, 0.5,  // anchors + rest + stiffness + damping
])
```

Other joints: `useFixedJoint`, `useSphericalJoint`, `usePrismaticJoint`, `useRopeJoint`.

## Hooks

**`useRapier()`** -- direct Rapier world access:

```tsx
const { world, rapier, isPaused, step, setWorld } = useRapier()
```

**`useBeforePhysicsStep` / `useAfterPhysicsStep`:**

```tsx
useBeforePhysicsStep((world) => {
  bodyRef.current?.applyImpulse({ x: 0, y: 0, z: -0.1 }, true)
})
```

## InstancedRigidBodies

For many identical physics objects:

```tsx
import { InstancedRigidBodies, InstancedRigidBodyProps } from '@react-three/rapier'

const instances = useMemo<InstancedRigidBodyProps[]>(() =>
  Array.from({ length: 500 }, (_, i) => ({
    key: `inst_${i}`,
    position: [Math.random() * 20 - 10, Math.random() * 20 + 10, Math.random() * 20 - 10],
    rotation: [Math.random() * Math.PI, Math.random() * Math.PI, 0],
  })), [])

<InstancedRigidBodies ref={rigidBodies} instances={instances} colliders="cuboid">
  <instancedMesh args={[undefined, undefined, 500]} count={500}>
    <boxGeometry args={[0.5, 0.5, 0.5]} />
    <meshStandardMaterial color="orange" />
  </instancedMesh>
</InstancedRigidBodies>
```

## Character Controller Pattern

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
