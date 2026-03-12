# Koota ECS Reference

Koota is an archetype-based ECS (Entity Component System) state management library from the pmndrs ecosystem, optimized for real-time apps running at 60fps+. It uses the term **Trait** instead of "Component" to avoid confusion with UI framework components.

> For React integration (WorldProvider, hooks, R3F patterns): `react/ecs.md`

## Core Concepts

### World

The top-level container for all entities.

```typescript
import { createWorld } from 'koota'
const world = createWorld()
```

World-level traits act as singletons (like Bevy's Resources):

```typescript
const GameClock = trait({ elapsed: 0, delta: 0 })
world.add(GameClock)
world.set(GameClock, { elapsed: totalTime, delta: dt })
const clock = world.get(GameClock)
```

### Traits

Traits are the building blocks of state. Three patterns:

**Schema-based (SoA storage)** -- each property stored in its own array. `entity.get()` returns a snapshot.

```typescript
import { trait } from 'koota'

const Position = trait({ x: 0, y: 0, z: 0 })
const Velocity = trait({ x: 0, y: 0, z: 0 })
const Health = trait({ current: 100, max: 100 })
```

**Callback-based (AoS storage)** -- stores the returned object as-is. `entity.get()` returns a reference.

```typescript
const MeshRef = trait(() => new THREE.Mesh())
const Transform = trait(() => new THREE.Object3D())
```

**Tag (no data)** -- boolean marker.

```typescript
const IsPlayer = trait()
const IsEnemy = trait()
const IsDead = trait()
```

### Entities

```typescript
// Spawn with defaults
const player = world.spawn(IsPlayer, Position, Velocity, Health)

// Spawn with initial values
const goblin = world.spawn(
  IsEnemy,
  Position({ x: 10, y: 5, z: 0 }),
  Health({ current: 50, max: 50 })
)

// Entity methods
entity.add(Trait)              // add a trait
entity.add(Trait(initialData)) // add with data
entity.remove(Trait)           // remove a trait
entity.has(Trait)              // check
entity.get(Trait)              // read data
entity.set(Trait, data)        // write data
entity.destroy()               // destroy entity
entity.changed(Trait)          // flag as changed (for change detection)
```

### Queries

```typescript
// Basic query
world.query(Position, Velocity)

// Mutable iteration (auto change detection)
world.query(Position, Velocity).updateEach(([pos, vel]) => {
  pos.x += vel.x * delta
  pos.y += vel.y * delta
  pos.z += vel.z * delta
})

// Read-only iteration
world.query(Position).readEach(([pos]) => {
  console.log(pos.x, pos.y)
})

// Entity iteration
world.query(IsPlayer, Position).forEach((entity) => {
  const pos = entity.get(Position)
})
```

**Query modifiers:**

```typescript
import { Not, Or } from 'koota'

world.query(Position, Not(Velocity))     // exclude
world.query(Or(Velocity, Renderable))    // either
world.query(Position, Not(IsDead))       // combined
```

**Change detection:**

```typescript
import { createAdded, createRemoved, createChanged } from 'koota'

const added = createAdded()
const changed = createChanged()

// Entities where Position was just added
world.query(Position, added(Position)).forEach(entity => { /* ... */ })

// Entities where Velocity changed
world.query(changed(Velocity)).forEach(entity => { /* ... */ })
```

### Relations

Build entity graphs (parent/child, likes, targets):

```typescript
import { relation } from 'koota'

const ChildOf = relation()
child.add(ChildOf(parent))

// Query children of a specific parent
world.query(ChildOf(parent)).forEach(child => { /* ... */ })

// Wildcard removal
player.remove(Likes('*'))
```

**Relation options:**

```typescript
const ChildOf = relation({ exclusive: true })           // only one target
const Owns = relation({ autoRemoveTarget: true })       // destroy target when source destroyed
```

**Ordered relations:**

```typescript
import { ordered } from 'koota'
const OrderedChildren = ordered(ChildOf)
const children = parent.get(OrderedChildren)
children.push(newChild)
children.splice(1, 1)
children.moveTo(0, 2)
```

### Event Subscriptions

```typescript
Position.onAdd((entity) => { /* after trait set */ })
Position.onRemove((entity) => { /* before data removed */ })
Position.onChange((entity) => { /* after set() or changed() */ })
```

### createActions

The recommended way to define world mutations:

```typescript
import { createActions } from 'koota'

export const actions = createActions((world) => ({
  spawnPlayer: () => world.spawn(
    IsPlayer, Position({ x: 0, y: 0, z: 0 }), Velocity, Health({ current: 100, max: 100 })
  ),
  spawnEnemy: (x: number, z: number) => world.spawn(
    IsEnemy, Position({ x, y: 0, z }), Health({ current: 50, max: 50 })
  ),
  destroyAllEnemies: () => {
    world.query(IsEnemy).forEach(e => e.destroy())
  },
}))
```

## Systems as Plain Functions

Koota has no built-in system scheduler. Systems are plain functions called in order:

```typescript
// systems/movement.ts
export function movementSystem(world: World, delta: number) {
  world.query(Position, Velocity).updateEach(([pos, vel]) => {
    pos.x += vel.x * delta
    pos.y += vel.y * delta
    pos.z += vel.z * delta
  })
}

// systems/cleanup.ts
export function cleanupSystem(world: World) {
  world.query(IsDead).forEach(e => e.destroy())
}
```

Execution order matters -- call systems in the right sequence inside your game loop.

## Separating ECS from UI State

```typescript
// Game/simulation state -- Koota
const Position = trait({ x: 0, y: 0, z: 0 })
const Health = trait({ current: 100, max: 100 })

// UI state (menus, HUD, settings) -- use your framework's state management
// React: Zustand, Solid: createSignal, Svelte: writable store
```

Koota excels at many entities updated every frame. Framework state excels at simple event-driven UI state. They coexist cleanly.
