# WebXR & @react-three/xr Reference

## WebXR Device API

W3C Candidate Recommendation. The core API is stable; modules (hit test, hand input, plane detection, anchors) are at Working Draft stage.

### Session Types

| Mode | Description |
|---|---|
| `immersive-vr` | Full VR, replaces environment. Most widely supported. |
| `immersive-ar` | AR overlay on real world. Android Chrome, Meta Quest, not yet Safari visionOS. |
| `inline` | Non-immersive, renders in page. Magic window / fallback. |

### Reference Spaces

| Space | Use case |
|---|---|
| `viewer` | Head-locked content (HUDs, reticles). Resets every frame. |
| `local` | Seated experiences. Origin at device start position. |
| `local-floor` | Standing experiences. Origin at floor level. |
| `bounded-floor` | Room-scale VR. Provides boundary polygon. |
| `unbounded` | Large-area tracking (warehouse, outdoor AR). |

### Input Sources

- `targetRayMode`: `"tracked-pointer"` (controller/hand), `"gaze"` (head), `"screen"` (touch), `"transient-pointer"` (Vision Pro eye+pinch)
- `handedness`: `"left"`, `"right"`, `"none"`
- `hand`: `XRHand` with 25 joints (wrist through fingertips)
- `gamepad`: Standard Gamepad interface for buttons/axes

### Browser Support (early 2026)

| Browser | Status |
|---|---|
| Chrome/Edge (desktop + Android) | Full WebXR support |
| Meta Quest Browser | Full support, 90Hz, hands+controllers |
| Safari (visionOS 2+) | immersive-vr only (no immersive-ar yet) |
| Firefox 147+ (Win/macOS) | WebGPU + WebXR |
| Safari (macOS/iOS) | Not supported |

---

## @react-three/xr v6

Completely rewritten in v6. Uses `createXRStore` + `<XR>` component architecture with unified pointer events.

### Setup

```tsx
import { Canvas } from '@react-three/fiber'
import { createXRStore, XR } from '@react-three/xr'

// Create store OUTSIDE component (singleton)
const store = createXRStore({
  hand: { rayPointer: true, grabPointer: true, touchPointer: true },
  controller: { rayPointer: true, grabPointer: true, teleportPointer: true },
})

function App() {
  return (
    <>
      <button onClick={() => store.enterVR()}>Enter VR</button>
      <button onClick={() => store.enterAR()}>Enter AR</button>
      <Canvas>
        <XR store={store}>
          <Scene />
        </XR>
      </Canvas>
    </>
  )
}
```

### createXRStore Options

```typescript
createXRStore({
  // Input sources (each can be false to disable)
  hand: {
    rayPointer: true | { color: 'blue' },
    grabPointer: true,
    touchPointer: true,
    teleportPointer: true,
    left: CustomLeftHand,     // custom component
    right: false,             // disable
  },
  controller: { /* same options */ },
  transientPointer: InputConfig | false,
  gaze: InputConfig | false,
  screenInput: InputConfig | false,

  // Session config
  offerSession: 'immersive-vr' | 'immersive-ar' | false,
  foveation: 0,          // 0-1
  frameRate: 90,
  frameBufferScaling: 1,
})
```

### Hooks

**`useXR(selector?)`** -- Zustand-based XR state:

```tsx
const session = useXR(xr => xr.session)
const mode = useXR(xr => xr.mode)  // 'immersive-vr' | 'immersive-ar' | 'inline' | undefined
const isPresenting = useXR(xr => xr.session != null)
```

**`useXRInputSourceState(type, handedness)`** -- specific input source:

```tsx
const rightController = useXRInputSourceState('controller', 'right')
const leftHand = useXRInputSourceState('hand', 'left')

// Read gamepad
if (rightController) {
  const thumbstick = rightController.gamepad['xr-standard-thumbstick']
  // thumbstick.xAxis, thumbstick.yAxis
  const trigger = rightController.gamepad['xr-standard-trigger']
  // trigger.state, trigger.value (0-1)
}
```

**`useHitTest(callback)`** -- AR hit testing:

```tsx
function HitTestReticle() {
  const ref = useRef<THREE.Mesh>(null)
  useHitTest((hitMatrix, hit) => {
    hitMatrix.decompose(ref.current!.position, ref.current!.quaternion, ref.current!.scale)
  })
  return (
    <mesh ref={ref}>
      <ringGeometry args={[0.08, 0.1, 32]} />
      <meshBasicMaterial color="white" />
    </mesh>
  )
}
```

**`useXRAnchor()`** -- spatial anchors:

```tsx
const [anchor, requestAnchor] = useXRAnchor()

// Create anchor from hit test
requestAnchor({ relativeTo: 'hitTestResult', hitTestResult: hit })
// Create anchor at world position
requestAnchor({ relativeTo: 'world', transform: rigidTransform })
// Create anchor from input source
requestAnchor({ relativeTo: 'space', space: event.inputSource.targetRaySpace })

if (anchor) {
  return (
    <XRSpace space={anchor.anchorSpace}>
      <mesh><boxGeometry args={[0.1, 0.1, 0.1]} /></mesh>
    </XRSpace>
  )
}
```

**`useXRPlanes(semanticLabel?)`** -- detected planes:

```tsx
const floors = useXRPlanes('floor')
const walls = useXRPlanes('wall')
const allPlanes = useXRPlanes()  // no filter

// Semantic labels: 'floor', 'wall', 'ceiling', 'table', 'door', 'window', 'other'
```

**`useXRMeshes(semanticLabel?)`** -- detected meshes.

**`useXRControllerLocomotion(originRef)`** -- thumbstick locomotion:

```tsx
const originRef = useRef<THREE.Group>(null)
useXRControllerLocomotion(originRef)
return <XROrigin ref={originRef} />
```

**`useXRInputSourceEvent(event, callback, options?)`** -- native XR events:

```tsx
useXRInputSourceEvent('select', (event) => {
  console.log('Selected with', event.inputSource.handedness)
}, { handedness: 'right' })
// Events: 'select', 'selectstart', 'selectend', 'squeeze', 'squeezestart', 'squeezeend'
```

### Components

**`<XR store={store}>`** -- root XR context provider.

**`<XROrigin>`** -- user's origin position in the scene. Controls where the headset maps to.

```tsx
<XROrigin position={[0, 0, 0]} ref={originRef} />
```

**`<XRSpace space={...}>`** -- position children at an XR space:

```tsx
// Attach to controller grip
<XRSpace space="grip-space"><mesh>...</mesh></XRSpace>
// Attach to hand wrist
<XRSpace space="wrist"><mesh>...</mesh></XRSpace>
// Attach to anchor
<XRSpace space={anchor.anchorSpace}><MyModel /></XRSpace>
// Attach to detected plane
<XRSpace space={plane.planeSpace}><XRPlaneModel plane={plane} /></XRSpace>
```

**`<XRPlaneModel>` / `<XRMeshModel>`** -- render detected geometry:

```tsx
<XRPlaneModel plane={plane}>
  <meshBasicMaterial color="green" opacity={0.3} transparent />
</XRPlaneModel>
```

**`<IfInSessionMode>`** -- conditional rendering by session mode:

```tsx
<IfInSessionMode deny={['immersive-ar', 'immersive-vr']}>
  <OrbitControls />
</IfInSessionMode>
<IfInSessionMode allow={['immersive-ar']}>
  <HitTestReticle />
</IfInSessionMode>
```

**`<TeleportTarget>`** -- teleportation destination:

```tsx
const [pos, setPos] = useState<[number, number, number]>([0, 0, 0])

<XROrigin position={pos} />
<TeleportTarget onTeleport={setPos}>
  <mesh rotation={[-Math.PI / 2, 0, 0]}>
    <planeGeometry args={[10, 10]} />
    <meshStandardMaterial color="green" />
  </mesh>
</TeleportTarget>
```

Requires `teleportPointer: true` in store config.

**`<XRDomOverlay>`** -- HTML overlay for handheld AR:

```tsx
<XR store={store}>
  <XRDomOverlay>
    <div style={{ padding: 20 }}>
      <h1>AR Instructions</h1>
    </div>
  </XRDomOverlay>
</XR>
```

### Interaction System

v6 uses **unified pointer events** -- same R3F events work across mouse, touch, controllers, hands, gaze, and transient pointers.

```tsx
<mesh
  onClick={() => setColor('red')}
  onPointerEnter={() => setHovered(true)}
  onPointerLeave={() => setHovered(false)}
>
```

**Pointer event type filtering:**

```tsx
// Prevent grab from triggering events
<mesh pointerEventsType={{ deny: 'grab' }}>
// Only allow ray pointer
<mesh pointerEventsType={{ allow: 'ray' }}>
// Disable all pointer events
<group pointerEvents="none">
```

**Pointer capture for dragging:**

```tsx
<mesh
  onPointerDown={(e) => {
    e.target.setPointerCapture(e.pointerId)
    setDragging(true)
  }}
  onPointerMove={(e) => {
    if (dragging) meshRef.current.position.copy(e.point)
  }}
  onPointerUp={(e) => {
    e.target.releasePointerCapture(e.pointerId)
    setDragging(false)
  }}
/>
```

### Dual VR+AR App Pattern

```tsx
const store = createXRStore({
  hand: { grabPointer: true, touchPointer: true, teleportPointer: true },
  controller: { teleportPointer: true },
})

function DualApp() {
  const [pos, setPos] = useState<[number, number, number]>([0, 0, 0])
  return (
    <>
      <button onClick={() => store.enterVR()}>VR</button>
      <button onClick={() => store.enterAR()}>AR</button>
      <Canvas>
        <XR store={store}>
          <ambientLight />
          <SharedContent />

          <IfInSessionMode allow={['immersive-vr']}>
            <Environment preset="sunset" />
            <XROrigin position={pos} />
            <TeleportTarget onTeleport={setPos}>
              <mesh rotation={[-Math.PI / 2, 0, 0]}>
                <planeGeometry args={[20, 20]} />
                <meshStandardMaterial color="#333" />
              </mesh>
            </TeleportTarget>
          </IfInSessionMode>

          <IfInSessionMode allow={['immersive-ar']}>
            <HitTestReticle />
            <DetectedPlanes />
          </IfInSessionMode>

          <IfInSessionMode deny={['immersive-ar', 'immersive-vr']}>
            <OrbitControls />
          </IfInSessionMode>
        </XR>
      </Canvas>
    </>
  )
}
```

### Spatial UI

Use `@react-three/uikit` for 3D UI panels that work with XR pointer events:

```tsx
import { Root, Text, Container } from '@react-three/uikit'

<Root position={[0, 1.5, -1]} width={400} height={300}
  backgroundColor="rgba(0,0,0,0.8)" borderRadius={16} padding={24}>
  <Text fontSize={24} color="white">Settings</Text>
  <Container marginTop={16} backgroundColor="rgba(255,255,255,0.1)"
    borderRadius={8} padding={12}>
    <Text fontSize={16} color="white">Volume: 80%</Text>
  </Container>
</Root>
```

### Custom Input Rendering

```tsx
const store = createXRStore({
  controller: {
    left: CustomController,
    right: CustomController,
  },
})

function CustomController() {
  const state = useXRInputSourceStateContext()
  return (
    <XRSpace space="grip-space">
      <mesh>
        <cylinderGeometry args={[0.02, 0.02, 0.15]} />
        <meshStandardMaterial color="blue" />
      </mesh>
    </XRSpace>
  )
}
```

### Haptic Feedback

```tsx
const controller = useXRInputSourceState('controller', 'right')
// In event handler:
controller?.inputSource.gamepad?.hapticActuators?.[0]?.pulse(0.5, 100)
// (strength 0-1, duration ms)
```
