# Drei Essentials Reference

All helpers below render inside `<Canvas>`.

## Environment & Lighting

```tsx
import { Environment, ContactShadows, Float, Sky } from '@react-three/drei'

<Sky sunPosition={[100, 20, 100]} />
<Environment preset="sunset" background backgroundBlurriness={0.05} />
<ContactShadows position={[0, -0.5, 0]} opacity={0.5} blur={1} frames={1} />
<Float speed={2} rotationIntensity={1} floatIntensity={1}>
  <mesh>{/* gently bobs / rotates */}</mesh>
</Float>
```

Presets: `apartment`, `city`, `dawn`, `forest`, `lobby`, `night`, `park`, `studio`, `sunset`, `warehouse`.

## Controls

```tsx
import { OrbitControls } from '@react-three/drei'
<OrbitControls makeDefault maxPolarAngle={Math.PI / 2} />
```

## Text

```tsx
import { Text } from '@react-three/drei'
<Text fontSize={1} color="white" anchorX="center" anchorY="middle">
  Hello World
</Text>
```

`<Text>` loads glyphs asynchronously (wrap in `<Suspense>`); for non-Latin scripts pass `font={url}` to a font that contains the glyphs. Add the `occlude` prop for depth-aware labels that hide behind geometry.

## HTML Overlay in 3D

```tsx
import { Html } from '@react-three/drei'
<mesh>
  <Html center transform distanceFactor={10}>
    <div className="label">Info Panel</div>
  </Html>
</mesh>
```
