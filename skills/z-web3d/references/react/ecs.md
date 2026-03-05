# Koota React Integration (`koota/react`)

> For core Koota API (traits, queries, systems): `../ecs.md`

## WorldProvider

```tsx
import { WorldProvider } from 'koota/react'
import { createWorld } from 'koota'

const world = createWorld()

function App() {
  return (
    <WorldProvider world={world}>
      <Canvas>
        <GameSystems />
        <Entities />
      </Canvas>
    </WorldProvider>
  )
}
```

## Hooks

**`useWorld()`** -- access the world directly.

**`useQuery(...traits)`** -- reactive entity query. Re-renders when matching entities are added/removed.

```tsx
function Enemies() {
  const enemies = useQuery(IsEnemy, Position)
  return (
    <group>
      {enemies.map(entity => (
        <EnemyView key={entity.id()} entity={entity} />
      ))}
    </group>
  )
}
```

**`useQueryFirst(...traits)`** -- first matching entity or `undefined`.

```tsx
const player = useQueryFirst(IsPlayer, Health)
```

**`useTrait(entity, Trait)`** -- observe a trait reactively. Returns value or `undefined`.

```tsx
function HealthBar({ entity }: { entity: Entity }) {
  const health = useTrait(entity, Health)
  if (!health) return null
  return <div style={{ width: `${(health.current / health.max) * 100}%` }} />
}
```

**`useTag(entity, Trait)`** -- boolean, reactively tracks tag presence.

```tsx
const isPlayer = useTag(entity, IsPlayer)
```

**`useTraitEffect(entity, Trait, callback)`** -- subscribe to changes without re-render. For imperative Three.js updates:

```tsx
function MeshSync({ entity }: { entity: Entity }) {
  const meshRef = useRef<THREE.Mesh>(null)
  useTraitEffect(entity, Position, (pos) => {
    if (meshRef.current && pos) {
      meshRef.current.position.set(pos.x, pos.y, pos.z)
    }
  })
  return <mesh ref={meshRef}><boxGeometry /><meshStandardNodeMaterial /></mesh>
}
```

**`useActions(actions)`** -- get world-bound actions.

```tsx
function SpawnButton() {
  const { spawnEnemy } = useActions(actions)
  return <button onClick={() => spawnEnemy(Math.random() * 10, 0)}>Spawn</button>
}
```

## R3F Integration Patterns

### View Injection

Use Koota for all game state, R3F purely as a view layer:

```typescript
// traits.ts
export const Position = trait({ x: 0, y: 0, z: 0 })
export const Rotation = trait({ x: 0, y: 0, z: 0 })
export const MeshRef = trait(() => null as THREE.Mesh | null)
export const IsPlayer = trait()
export const IsEnemy = trait()
```

```tsx
// components/EnemyView.tsx
function EnemyView({ entity }: { entity: Entity }) {
  const meshRef = useRef<THREE.Mesh>(null)

  useEffect(() => {
    if (meshRef.current) entity.set(MeshRef, meshRef.current)
  }, [entity])

  return (
    <mesh ref={meshRef}>
      <boxGeometry />
      <meshStandardNodeMaterial color="red" />
    </mesh>
  )
}
```

### Transform Sync System

Bridge ECS data to Three.js scene graph:

```typescript
// systems/syncTransforms.ts
export function syncTransformsSystem(world: World) {
  world.query(Position, MeshRef).readEach(([pos, mesh]) => {
    if (mesh) mesh.position.set(pos.x, pos.y, pos.z)
  })
}
```

### Game Loop

```tsx
function GameSystems() {
  const world = useWorld()
  useFrame((_, delta) => {
    inputSystem(world)
    movementSystem(world, delta)
    collisionSystem(world)
    syncTransformsSystem(world)
    cleanupSystem(world)
  })
  return null
}
```
