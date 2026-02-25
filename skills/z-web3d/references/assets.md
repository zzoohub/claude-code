# glTF 2.0 Asset Pipeline Reference

glTF is the only asset format. All 3D models, animations, and scenes use `.glb` (binary glTF).

## Optimization Pipeline

1. **Author** in Blender/Maya/etc, export as `.glb`
2. **Optimize** with `gltfjsx --transform` (Draco compression, texture optimization, deduplication)
3. **Load** with Drei's `useGLTF` (auto Draco decompression)
4. **Preload** with `useGLTF.preload('/model.glb')` in module scope

## Texture Best Practices

- Use KTX2/Basis Universal for GPU-compressed textures (significantly smaller, faster upload)
- Keep power-of-2 dimensions where possible
- Use `useTexture` with object syntax for PBR material maps:

```tsx
const textures = useTexture({
  map: '/albedo.jpg',
  normalMap: '/normal.jpg',
  roughnessMap: '/roughness.jpg',
})
<meshStandardNodeMaterial {...textures} />
```
