# @react-three/xr v6 Reference

Completely rewritten in v6. Uses `createXRStore` + `<XR>` component architecture with unified pointer events.

> For raw WebXR Device API: `../web-xr.md`

## Setup

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
  hand: {
    rayPointer: true | { color: 'blue' },
    grabPointer: true,
    touchPointer: true,
    teleportPointer: true,
    left: CustomLeftHand,
    right: false,
  },
  controller: { /* same options */ },
  transientPointer: InputConfig | false,
  gaze: InputConfig | false,
  screenInput: InputConfig | false,
  offerSession: 'immersive-vr' | 'immersive-ar' | false,
  foveation: 0,
  frameRate: 90,
  frameBufferScaling: 1,
})
```

## Hooks

**`useXR(selector?)`** -- Zustand-based XR state:

```tsx
const session = useXR(xr => xr.session)
const mode = useXR(xr => xr.mode)
const isPresenting = useXR(xr => xr.session != null)
```

**`useXRInputSourceState(type, handedness)`:**

```tsx
const rightController = useXRInputSourceState('controller', 'right')
const leftHand = useXRInputSourceState('hand', 'left')

if (rightController) {
  const thumbstick = rightController.gamepad['xr-standard-thumbstick']
  const trigger = rightController.gamepad['xr-standard-trigger']
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

**`useXRAnchor()`:**

```tsx
const [anchor, requestAnchor] = useXRAnchor()
requestAnchor({ relativeTo: 'hitTestResult', hitTestResult: hit })

if (anchor) {
  return (
    <XRSpace space={anchor.anchorSpace}>
      <mesh><boxGeometry args={[0.1, 0.1, 0.1]} /></mesh>
    </XRSpace>
  )
}
```

**`useXRPlanes(semanticLabel?)`:**

```tsx
const floors = useXRPlanes('floor')
const walls = useXRPlanes('wall')
// Labels: 'floor', 'wall', 'ceiling', 'table', 'door', 'window', 'other'
```

**`useXRControllerLocomotion(originRef)`:**

```tsx
const originRef = useRef<THREE.Group>(null)
useXRControllerLocomotion(originRef)
return <XROrigin ref={originRef} />
```

**`useXRInputSourceEvent(event, callback, options?)`:**

```tsx
useXRInputSourceEvent('select', (event) => {
  console.log('Selected with', event.inputSource.handedness)
}, { handedness: 'right' })
```

## Components

**`<XR store={store}>`** -- root XR context provider.

**`<XROrigin>`** -- user's origin position in the scene.

**`<XRSpace space={...}>`** -- position children at an XR space:

```tsx
<XRSpace space="grip-space"><mesh>...</mesh></XRSpace>
<XRSpace space="wrist"><mesh>...</mesh></XRSpace>
<XRSpace space={anchor.anchorSpace}><MyModel /></XRSpace>
<XRSpace space={plane.planeSpace}><XRPlaneModel plane={plane} /></XRSpace>
```

**`<IfInSessionMode>`** -- conditional rendering:

```tsx
<IfInSessionMode deny={['immersive-ar', 'immersive-vr']}>
  <OrbitControls />
</IfInSessionMode>
<IfInSessionMode allow={['immersive-ar']}>
  <HitTestReticle />
</IfInSessionMode>
```

**`<TeleportTarget>`:**

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

**`<XRDomOverlay>`** -- HTML overlay for handheld AR:

```tsx
<XR store={store}>
  <XRDomOverlay>
    <div style={{ padding: 20 }}><h1>AR Instructions</h1></div>
  </XRDomOverlay>
</XR>
```

## Interaction System

v6 uses **unified pointer events** -- same R3F events work across mouse, touch, controllers, hands, gaze.

```tsx
<mesh
  onClick={() => setColor('red')}
  onPointerEnter={() => setHovered(true)}
  onPointerLeave={() => setHovered(false)}
  pointerEventsType={{ deny: 'grab' }}  // filter pointer types
>
```

## Spatial UI

Use `@react-three/uikit` for 3D UI panels:

```tsx
import { Root, Text, Container } from '@react-three/uikit'

<Root position={[0, 1.5, -1]} width={400} height={300}
  backgroundColor="rgba(0,0,0,0.8)" borderRadius={16} padding={24}>
  <Text fontSize={24} color="white">Settings</Text>
</Root>
```

## Haptic Feedback

```tsx
const controller = useXRInputSourceState('controller', 'right')
controller?.inputSource.gamepad?.hapticActuators?.[0]?.pulse(0.5, 100)
```
