# Rapier Physics Reference

Rapier is a Rust-based physics engine compiled to WASM. This reference covers the raw Rapier API and Worker-based architecture. For declarative React bindings (`@react-three/rapier`), see `react/physics.md`.

## Setup (Raw Rapier)

```bash
bun add @dimforge/rapier3d
```

```typescript
// @dimforge/rapier3d is the wasm-bindgen "bundler" build: it initializes its WASM
// on import, so there is NO init() to await. (await RAPIER.init() is the
// @dimforge/rapier3d-compat pattern — calling it here throws "init is not a function".)
const RAPIER = await import('@dimforge/rapier3d')

const gravity = { x: 0, y: -9.81, z: 0 }
const world = new RAPIER.World(gravity)
```

## Core Concepts

### Rigid Bodies

```typescript
// Dynamic body (fully simulated)
const bodyDesc = RAPIER.RigidBodyDesc.dynamic()
  .setTranslation(0, 5, 0)
  .setLinearDamping(0.0)
  .setAngularDamping(0.0)
const body = world.createRigidBody(bodyDesc)

// Fixed body (immovable)
const floorDesc = RAPIER.RigidBodyDesc.fixed()
  .setTranslation(0, 0, 0)
const floor = world.createRigidBody(floorDesc)

// Kinematic body (moved programmatically)
const kinDesc = RAPIER.RigidBodyDesc.kinematicPositionBased()
const kinBody = world.createRigidBody(kinDesc)
kinBody.setNextKinematicTranslation({ x: 1, y: 0, z: 0 })
```

### Colliders

```typescript
// Box
const colliderDesc = RAPIER.ColliderDesc.cuboid(0.5, 0.5, 0.5)
  .setRestitution(0.5)
  .setFriction(0.7)
world.createCollider(colliderDesc, body)

// Sphere
world.createCollider(RAPIER.ColliderDesc.ball(0.5), body)

// Capsule
world.createCollider(RAPIER.ColliderDesc.capsule(0.5, 0.25), body)

// Convex hull from mesh vertices -- convexHull() returns ColliderDesc | null, so guard it
const hullDesc = RAPIER.ColliderDesc.convexHull(verticesFloat32Array)
if (hullDesc) world.createCollider(hullDesc, body)

// Triangle mesh (static only!)
world.createCollider(
  RAPIER.ColliderDesc.trimesh(verticesFloat32Array, indicesUint32Array),
  floorBody
)
```

### Simulation Step

```typescript
world.timestep = 1 / 60   // fixed integration step (this is also the default)

function tick() {
  world.step()

  // Read results. NOTE: RigidBodySet.forEach passes ONLY the body (no index), and its
  // iteration order is not guaranteed and shifts as bodies are added/removed — never
  // derive a buffer offset from iteration position (see the Worker pattern below).
  world.bodies.forEach((body) => {
    const pos = body.translation()   // { x, y, z }
    const rot = body.rotation()      // { x, y, z, w } quaternion
  })
}
```

### Forces and Impulses

```typescript
body.applyImpulse({ x: 0, y: 10, z: 0 }, true)    // instant velocity change (one-off)
body.addForce({ x: 0, y: 100, z: 0 }, true)        // persistent force — NOT auto-zeroed each step
body.resetForces(true)                                // clear accumulated forces (also resetTorques)
body.setLinvel({ x: 5, y: body.linvel().y, z: 0 }, true)  // set velocity directly
body.lockRotations(true, true)                        // prevent rotation
```

### Collision Events

```typescript
const eventQueue = new RAPIER.EventQueue(true)

world.step(eventQueue)

eventQueue.drainCollisionEvents((handle1, handle2, started) => {
  const collider1 = world.getCollider(handle1)
  const collider2 = world.getCollider(handle2)
  if (started) { /* collision began */ }
  else { /* collision ended */ }
})

eventQueue.drainContactForceEvents((event) => {
  const totalForce = event.totalForceMagnitude()
})
```

### Collision Groups

```typescript
// Groups are bitmasks: membership | filter
// Group 0 = 0x00010001, Group 1 = 0x00020002, etc.
const GROUP_PLAYER = 0x00010001
const GROUP_ENEMY = 0x00020002
const GROUP_SENSOR = 0x00040001  // sensor in group 2, interacts with group 0

colliderDesc.setCollisionGroups(GROUP_PLAYER)
```

### Sensors

```typescript
const sensorDesc = RAPIER.ColliderDesc.cuboid(5, 5, 1)
  .setSensor(true)
world.createCollider(sensorDesc, body)

// Detect via intersection events
eventQueue.drainIntersectionEvents((handle1, handle2, intersecting) => {
  if (intersecting) { /* entered sensor zone */ }
})
```

### Joints

```typescript
// Revolute joint (hinge)
const jointData = RAPIER.JointData.revolute(
  { x: 0, y: 0, z: 0 },     // anchor in body A
  { x: 0, y: -1, z: 0 },    // anchor in body B
  { x: 1, y: 0, z: 0 }      // rotation axis
)
const joint = world.createImpulseJoint(jointData, bodyA, bodyB, true)

// Motor
joint.configureMotorVelocity(10, 1.0)  // target velocity, damping

// Spring joint
const springData = RAPIER.JointData.spring(
  1.0,     // rest length
  10.0,    // stiffness
  0.5,     // damping
  { x: 0, y: 0, z: 0 },   // anchor A
  { x: 0, y: 0, z: 0 }    // anchor B
)
world.createImpulseJoint(springData, bodyA, bodyB, true)
```

### Snapshot / Restore

```typescript
const snapshot = world.takeSnapshot()
// ... later ...
const restored = RAPIER.World.restoreSnapshot(snapshot)
```

---

## Worker Pattern

Use when: many rigid bodies, 60fps target, main thread must stay free for rendering.

### Worker Setup

```typescript
// workers/physics.worker.ts
import('@dimforge/rapier3d').then((RAPIER) => {
  // bundler build: WASM is initialized by the import itself — no RAPIER.init() to await

  const gravity = { x: 0, y: -9.81, z: 0 }
  const world = new RAPIER.World(gravity)
  let transforms: Float32Array

  self.onmessage = (e) => {
    const { type, payload } = e.data

    if (type === 'init') {
      transforms = new Float32Array(payload.buffer)
      // spawn bodies from payload.bodies... and push each into `bodies` (below) in order
      self.postMessage({ type: 'ready' })
      tick()
    }

    if (type === 'reset') {
      // re-init world from new challenge config
    }
  }

  // Fixed-step accumulator — keeps timing stable even if tick body is slow.
  const STEP_MS = 1000 / 60
  let last = performance.now()
  let acc = 0
  // Bodies in a STABLE spawn order — populate this in the 'init' handler above.
  // RigidBodySet iteration order is NOT spawn order and shifts on removal, so never
  // key a SharedArrayBuffer slot off iteration position.
  const bodies = []   // RAPIER.RigidBody[]

  function tick() {
    const now = performance.now()
    const elapsed = now - last
    last = now

    // Accumulate elapsed and carry the remainder across ticks (cap to avoid
    // spiral-of-death on tab resume).
    acc = Math.min(acc + elapsed, STEP_MS * 5)
    while (acc >= STEP_MS) {
      world.step()
      acc -= STEP_MS
    }

    // Write results into SharedArrayBuffer, keyed by stable index (NOT iteration order).
    bodies.forEach((body, i) => {
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

    // Schedule next frame relative to start of this tick to minimize drift.
    setTimeout(tick, Math.max(0, STEP_MS - (performance.now() - now)))
  }
  // Worker context — no requestAnimationFrame; setTimeout / setInterval only.
})
```

### Main Thread Sync

```typescript
const MAX_BODIES = 64
const sab = new SharedArrayBuffer(MAX_BODIES * 7 * 4) // 7 floats: xyz + xyzw
const transforms = new Float32Array(sab)

worker.postMessage({ type: 'init', buffer: sab, bodies: [...] })

// In render loop, read transforms and apply to Three.js meshes:
function syncPhysics(meshes: THREE.Mesh[]) {
  meshes.forEach((mesh, i) => {
    const o = i * 7
    mesh.position.set(transforms[o], transforms[o+1], transforms[o+2])
    mesh.quaternion.set(transforms[o+3], transforms[o+4], transforms[o+5], transforms[o+6])
  })
}
```

`meshes[i]` must line up with the worker's stable `bodies[i]` order (above), not iteration order. Reads here are unsynchronized, so a frame can mix a new position with a stale quaternion (tearing). For transforms this is visually imperceptible; if you need consistency, double-buffer or use a seqlock with an `Int32Array` generation counter (see `references/threading.md`).

### postMessage Fallback (no COOP/COEP)

If SharedArrayBuffer is unavailable (no COOP/COEP headers):

```typescript
// Worker: send results each frame
self.postMessage({ type: 'tick', transforms: Float32Array })
// ~98 KB/s for 60 bodies @ 60fps (60 × 7 floats × 4 B × 60 fps) -- acceptable cost
// Use Transferable if needed: self.postMessage(data, [data.transforms.buffer])
```
