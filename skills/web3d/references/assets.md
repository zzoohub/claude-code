# glTF 2.0 Asset Pipeline Reference

glTF is the only asset format. All 3D models, animations, and scenes use `.glb` (binary glTF).

## Optimization Pipeline

1. **Author** in Blender/Maya/etc, export as `.glb`
2. **Optimize** with `gltf-transform` CLI or `gltfjsx --transform` (meshoptimizer compression, texture optimization, deduplication)
3. **Load** with Three.js `GLTFLoader` + `MeshoptDecoder` (auto meshoptimizer decompression)
4. **Preload** in module scope or during loading screen

### gltf-transform CLI

```bash
npx @gltf-transform/cli optimize input.glb output.glb \
  --compress meshopt \
  --texture-compress webp
```

### gltfjsx (React projects)

```bash
npx gltfjsx model.glb --transform --types --shadow
```

`--transform` produces a meshoptimizer-compressed, texture-optimized, deduplicated `.glb` (near-instant decode, no WASM decoder overhead unlike Draco).

## Loading with Three.js

```typescript
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js'
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js'

const loader = new GLTFLoader()
loader.setMeshoptDecoder(MeshoptDecoder)

const gltf = await loader.loadAsync('/model.glb')
scene.add(gltf.scene)
```

## Texture Best Practices

- Use KTX2/Basis Universal for GPU-compressed textures (significantly smaller, faster upload)
- Keep power-of-2 dimensions where possible
- Separate PBR maps: albedo, normal, roughness, metalness, AO
- Use `sRGBColorSpace` for albedo/emissive, `LinearSRGBColorSpace` for normal/roughness/metalness

```typescript
import { KTX2Loader } from 'three/addons/loaders/KTX2Loader.js'

const ktx2Loader = new KTX2Loader()
  .setTranscoderPath('/basis/')
  .detectSupport(renderer)

const texture = await ktx2Loader.loadAsync('/texture.ktx2')
```

## Animation

```typescript
const mixer = new THREE.AnimationMixer(gltf.scene)
const action = mixer.clipAction(gltf.animations[0])
action.play()

// In render loop:
mixer.update(delta)

// Crossfade between animations
const idleAction = mixer.clipAction(animations.find(a => a.name === 'Idle'))
const runAction = mixer.clipAction(animations.find(a => a.name === 'Run'))
idleAction.play()

// Transition
idleAction.fadeOut(0.5)
runAction.reset().fadeIn(0.5).play()
```

## Dispose Pattern

WebGL/WebGPU resources are NOT garbage-collected. Always dispose when removing from scene:

```typescript
function disposeModel(object: THREE.Object3D) {
  object.traverse((child) => {
    if (child instanceof THREE.Mesh) {
      child.geometry.dispose()
      if (Array.isArray(child.material)) {
        child.material.forEach(m => m.dispose())
      } else {
        child.material.dispose()
      }
    }
  })
}
```
