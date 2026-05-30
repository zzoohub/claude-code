# glTF 2.0 Asset Pipeline Reference

glTF is the only asset format. All 3D models, animations, and scenes use `.glb` (binary glTF).

## Table of Contents

1. [Optimization Pipeline](#optimization-pipeline)
2. [Loading with Three.js](#loading-with-threejs)
3. [Texture Best Practices](#texture-best-practices)
4. [Animation](#animation)
5. [Dispose Pattern](#dispose-pattern)


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
npx gltfjsx model.glb --transform --types --shadows
```

`--transform` produces a **Draco-compressed**, texture-resized (webp), deduplicated, instanced `.glb` (often 70–90% smaller). Draco needs a WASM decoder at load time, but `useGLTF`/`GLTFLoader` wire it automatically (Draco binaries via CDN). If you want meshopt instead, use `gltf-transform optimize --compress meshopt` (above) and `loader.setMeshoptDecoder(...)`.

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
- WebP (`--texture-compress webp`) shrinks **download** size but decodes to a full uncompressed GPU texture; KTX2/Basis stays GPU-compressed in VRAM. Prefer KTX2 for VRAM-bound/large scenes, WebP for quick download wins.
- For KTX2/GPU-compressed textures keep dimensions a multiple of 4 (block-compression requirement); power-of-2 mainly matters for full mip chains, not as an NPOT-sampling restriction on WebGPU/WebGL 2
- Separate PBR maps: albedo, normal, roughness, metalness, AO
- Use `SRGBColorSpace` for color data (albedo/emissive); use `NoColorSpace` (the default) for non-color data maps (normal/roughness/metalness/AO). `LinearSRGBColorSpace` is the renderer's working space, not a value you assign to a data texture.

```typescript
import { KTX2Loader } from 'three/addons/loaders/KTX2Loader.js'

// .detectSupport(renderer) must run AFTER the WebGPU renderer's async init()
const ktx2Loader = new KTX2Loader()
  .setTranscoderPath('/basis/')
  .detectSupport(renderer)

const texture = await ktx2Loader.loadAsync('/texture.ktx2')

// To transcode KTX2 textures embedded in a .glb (KHR_texture_basisu), wire it INTO GLTFLoader
// (otherwise the load fails with "no KTX2Loader"):
//   gltfLoader.setKTX2Loader(ktx2Loader)
//   gltfLoader.setMeshoptDecoder(MeshoptDecoder)
```

## Animation

```typescript
const mixer = new THREE.AnimationMixer(gltf.scene)
const action = mixer.clipAction(gltf.animations[0])
action.play()

// In render loop:
mixer.update(delta)

// Crossfade between animations (clips live on gltf.animations)
const idleAction = mixer.clipAction(THREE.AnimationClip.findByName(gltf.animations, 'Idle'))
const runAction = mixer.clipAction(THREE.AnimationClip.findByName(gltf.animations, 'Run'))
idleAction.play()

// Transition
idleAction.fadeOut(0.5)
runAction.reset().fadeIn(0.5).play()
```

## Dispose Pattern

WebGL/WebGPU resources are NOT garbage-collected. Always dispose when removing from scene:

```typescript
function disposeModel(object: THREE.Object3D) {
  // Textures are usually the biggest VRAM consumer and are NOT freed by material.dispose()
  // (which only releases the shader program). Collect them — deduped, since textures are
  // frequently shared across materials — and dispose once after traversal.
  const textures = new Set<THREE.Texture>()

  const disposeMaterial = (m: THREE.Material) => {
    for (const value of Object.values(m)) {
      if (value instanceof THREE.Texture) textures.add(value)
    }
    m.dispose()
  }

  object.traverse((child) => {
    if (child instanceof THREE.Mesh) {
      child.geometry.dispose()
      const mats = Array.isArray(child.material) ? child.material : [child.material]
      mats.forEach(disposeMaterial)
    }
  })

  textures.forEach((t) => t.dispose())
}
// Still the caller's responsibility: scene.environment/background, render targets,
// PMREM env maps, post-processing buffers, and renderer.dispose() on teardown.
// removeFromParent() only drops JS scene-graph refs — it frees no GPU memory.
```
