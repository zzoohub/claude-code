# WebXR Device API Reference

W3C Candidate Recommendation. The core API is stable; modules (hit test, hand input, plane detection, anchors) are at Working Draft stage.

> For React bindings (`@react-three/xr v6`): `react/web-xr.md`

## Session Types

| Mode | Description |
|---|---|
| `immersive-vr` | Full VR, replaces environment. Most widely supported. |
| `immersive-ar` | AR overlay on real world. Android Chrome, Meta Quest, not yet Safari visionOS. |
| `inline` | Non-immersive, renders in page. Magic window / fallback. |

## Reference Spaces

| Space | Use case |
|---|---|
| `viewer` | Head-locked content (HUDs, reticles). Resets every frame. |
| `local` | Seated experiences. Origin at device start position. |
| `local-floor` | Standing experiences. Origin at floor level. |
| `bounded-floor` | Room-scale VR. Provides boundary polygon. |
| `unbounded` | Large-area tracking (warehouse, outdoor AR). |

## Input Sources

- `targetRayMode`: `"tracked-pointer"` (controller/hand), `"gaze"` (head), `"screen"` (touch), `"transient-pointer"` (Vision Pro eye+pinch)
- `handedness`: `"left"`, `"right"`, `"none"`
- `hand`: `XRHand` with 25 joints (wrist through fingertips)
- `gamepad`: Standard Gamepad interface for buttons/axes

## Browser Support (early 2026)

| Browser | Status |
|---|---|
| Chrome/Edge (desktop + Android) | Full WebXR support |
| Meta Quest Browser | Full support, 90Hz, hands+controllers |
| Safari (visionOS 2+) | immersive-vr only (no immersive-ar yet) |
| Firefox 147+ (Win/macOS) | WebGPU + WebXR |
| Safari (macOS/iOS) | Not supported |

## Raw WebXR Session Setup

```typescript
// Check support
const isSupported = await navigator.xr?.isSessionSupported('immersive-vr')

// Request session
const session = await navigator.xr!.requestSession('immersive-vr', {
  requiredFeatures: ['local-floor'],
  optionalFeatures: ['hand-tracking', 'hit-test', 'plane-detection', 'anchors'],
})

// Create XR-compatible WebGL layer
const glLayer = new XRWebGLLayer(session, gl)
session.updateRenderState({ baseLayer: glLayer })

// Reference space
const refSpace = await session.requestReferenceSpace('local-floor')

// Frame loop
session.requestAnimationFrame(function onXRFrame(time, frame) {
  session.requestAnimationFrame(onXRFrame)

  const pose = frame.getViewerPose(refSpace)
  if (!pose) return

  for (const view of pose.views) {
    const viewport = glLayer.getViewport(view)
    gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height)
    // Render with view.transform and view.projectionMatrix
  }
})

// End session
session.end()
```

## Input Handling

```typescript
session.addEventListener('inputsourceschange', (event) => {
  for (const source of event.added) {
    console.log('Added:', source.targetRayMode, source.handedness)
  }
})

session.addEventListener('select', (event) => {
  const source = event.inputSource
  const frame = event.frame
  const pose = frame.getPose(source.targetRaySpace, refSpace)
  if (pose) {
    // pose.transform.position, pose.transform.orientation
  }
})

// Read controller state each frame
for (const source of session.inputSources) {
  if (source.gamepad) {
    const trigger = source.gamepad.buttons[0]  // xr-standard-trigger
    const grip = source.gamepad.buttons[1]     // xr-standard-squeeze
    const thumbstick = source.gamepad.axes     // [x, y] for primary thumbstick
  }
}
```

## Hand Tracking

```typescript
for (const source of session.inputSources) {
  if (source.hand) {
    // 25 joints
    const wrist = source.hand.get('wrist')
    const indexTip = source.hand.get('index-finger-tip')

    const jointPose = frame.getJointPose(indexTip, refSpace)
    if (jointPose) {
      // jointPose.transform.position
      // jointPose.radius (joint sphere radius)
    }
  }
}
```

## Hit Testing (AR)

```typescript
const hitTestSource = await session.requestHitTestSource({
  space: viewerSpace,  // or inputSource.targetRaySpace
})

// In frame loop:
const hitResults = frame.getHitTestResults(hitTestSource)
if (hitResults.length > 0) {
  const pose = hitResults[0].getPose(refSpace)
  // Place reticle at pose.transform
}
```

## Anchors

```typescript
// Create anchor from hit test result
const anchor = await hitTestResult.createAnchor()

// In frame loop:
const anchorPose = frame.getPose(anchor.anchorSpace, refSpace)
// Position anchored content at anchorPose.transform

// Delete anchor
anchor.delete()
```

## Plane Detection

```typescript
// In frame loop:
const detectedPlanes = frame.detectedPlanes
for (const plane of detectedPlanes) {
  const planePose = frame.getPose(plane.planeSpace, refSpace)
  const polygon = plane.polygon  // Array of DOMPointReadOnly
  const label = plane.semanticLabel  // 'floor', 'wall', 'ceiling', 'table', etc.
}
```

## Haptic Feedback

```typescript
const actuator = inputSource.gamepad?.hapticActuators?.[0]
actuator?.pulse(0.5, 100)  // strength 0-1, duration ms
```
