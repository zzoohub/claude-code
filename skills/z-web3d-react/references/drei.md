# Drei Essentials Reference

## Environment & Lighting

```tsx
import { Environment, ContactShadows, Float, Sky } from '@react-three/drei'

<Environment preset="sunset" background backgroundBlurriness={0.05} />
<ContactShadows position={[0, -0.5, 0]} opacity={0.5} blur={1} frames={1} />
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

## HTML Overlay in 3D

```tsx
import { Html } from '@react-three/drei'
<mesh>
  <Html center transform distanceFactor={10}>
    <div className="label">Info Panel</div>
  </Html>
</mesh>
```
