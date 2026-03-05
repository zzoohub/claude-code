# React Three Fiber Setup & Core Patterns

R3F v9 + React 19. React Three Fiber is a React renderer for Three.js -- every JSX element maps directly to a Three.js class.

## Setup

```bash
bun add three @react-three/fiber @react-three/drei
bun add -d @types/three
```

### WebGPU-First Canvas

```tsx
import * as THREE from 'three/webgpu'
import { Canvas, extend } from '@react-three/fiber'
import { useState } from 'react'

// Extend R3F's catalog with WebGPU-compatible classes
extend(THREE as any)

function App() {
  const [frameloop, setFrameloop] = useState<'never' | 'always'>('never')

  return (
    <Canvas
      frameloop={frameloop}
      gl={async (props) => {
        const renderer = new THREE.WebGPURenderer({
          ...props,
          antialias: true,
          alpha: true,
          powerPreference: 'high-performance',
        } as any)
        await renderer.init()
        setFrameloop('always')
        return renderer
      }}
    >
      <Scene />
    </Canvas>
  )
}
```

WebGPURenderer init is **async** -- set `frameloop="never"` until ready, then flip to `"always"`.

### Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import wasm from 'vite-plugin-wasm'
import topLevelAwait from 'vite-plugin-top-level-await'

export default defineConfig({
  plugins: [react(), wasm(), topLevelAwait()],
  build: { target: 'esnext' },
  server: {
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    },
  },
})
```

## JSX Maps to Three.js

Every JSX element maps directly to a Three.js class. Constructor args use the `args` prop.

```tsx
<mesh position={[0, 1, 0]} castShadow>
  <sphereGeometry args={[1, 32, 32]} />
  <meshStandardNodeMaterial color="hotpink" roughness={0.4} />
</mesh>
```

Use **Node materials** (`meshStandardNodeMaterial`, `meshPhysicalNodeMaterial`, etc.) when targeting TSL/WebGPU.

## useFrame -- The Render Loop

Mutate refs directly inside `useFrame`. Never call `setState` here -- it triggers 60 re-renders/sec.

```tsx
import { useFrame } from '@react-three/fiber'
import { useRef } from 'react'

function Spinner() {
  const ref = useRef<THREE.Mesh>(null!)
  useFrame((_, delta) => {
    ref.current.rotation.y += delta
  })
  return (
    <mesh ref={ref}>
      <boxGeometry />
      <meshStandardNodeMaterial color="orange" />
    </mesh>
  )
}
```

`delta` is seconds since last frame -- use it for frame-rate-independent animation.

## Loading Assets

```tsx
import { useGLTF, useTexture, useAnimations } from '@react-three/drei'

function Model() {
  const { nodes, materials, animations } = useGLTF('/model.glb')
  const group = useRef<THREE.Group>(null!)
  const { actions } = useAnimations(animations, group)

  useEffect(() => {
    actions['Idle']?.reset().fadeIn(0.5).play()
  }, [])

  return (
    <group ref={group}>
      <mesh geometry={nodes.Body.geometry} material={materials.Skin} />
    </group>
  )
}
useGLTF.preload('/model.glb')
```

Drei's `useGLTF` enables meshoptimizer decompression by default. Use `gltfjsx` CLI to generate typed R3F components from glTF files:

```bash
npx gltfjsx model.glb --transform --types --shadow
```

## Event System

R3F supports pointer events via raycasting. Same events work on desktop, mobile, and XR (controllers/hands).

```tsx
<mesh
  onClick={(e) => { e.stopPropagation(); handleClick(e.point) }}
  onPointerOver={() => setHovered(true)}
  onPointerOut={() => setHovered(false)}
>
```

`e.stopPropagation()` prevents the event from hitting objects behind.

## Common Imports

```tsx
// Core
import * as THREE from 'three/webgpu'
import { Canvas, useFrame, useThree, extend } from '@react-three/fiber'

// TSL
import { Fn, uniform, float, vec2, vec3, vec4, color,
  positionLocal, normalLocal, uv, time,
  sin, cos, mix, smoothstep, mx_noise_float,
  texture, storage, instanceIndex } from 'three/tsl'

// Drei
import { Environment, OrbitControls, useGLTF, useAnimations,
  Text, Html, Instances, Instance, Merged, Float,
  ContactShadows, PerformanceMonitor, AdaptiveDpr } from '@react-three/drei'

// XR
import { createXRStore, XR, XROrigin, XRSpace,
  useXR, useHitTest, useXRInputSourceState,
  IfInSessionMode, TeleportTarget } from '@react-three/xr'

// Physics
import { Physics, RigidBody, CuboidCollider, BallCollider,
  interactionGroups } from '@react-three/rapier'

// ECS
import { createWorld, trait, relation } from 'koota'
import { WorldProvider, useWorld, useQuery, useTrait,
  useActions } from 'koota/react'
```
