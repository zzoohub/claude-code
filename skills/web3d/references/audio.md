# Spatial Audio Reference

Three.js wraps the Web Audio API with `AudioListener` + `PositionalAudio`, giving you HRTF-based 3D audio that follows the camera (or the XR head pose) automatically. For most apps this built-in path is enough; reach for a raw `AudioWorklet` (see `threading.md`) only when you need custom DSP off the main thread.

## Listener (attach to the camera)

```typescript
const listener = new THREE.AudioListener()
camera.add(listener)
```

The listener's position/orientation track whatever object it's attached to. In XR, add it to the camera that `renderer.xr` drives so the listener follows the head pose every frame — no manual sync needed.

## Positional (3D) source

```typescript
const sound = new THREE.PositionalAudio(listener)

const loader = new THREE.AudioLoader()
loader.load('/sfx/engine.mp3', (buffer) => {
  sound.setBuffer(buffer)
  sound.setRefDistance(2)      // distance at which volume is 1.0
  sound.setRolloffFactor(2)    // how quickly it attenuates with distance
  sound.setDistanceModel('inverse')
  sound.setLoop(true)
  sound.play()
})

mesh.add(sound) // sound now emits from the mesh's world position
```

`PositionalAudio` uses a Web Audio `PannerNode` under the hood; set `panner.panningModel = 'HRTF'` (the default) for binaural spatialization.

## Non-positional (UI / music)

```typescript
const music = new THREE.Audio(listener)
new THREE.AudioLoader().load('/music/theme.mp3', (b) => {
  music.setBuffer(b); music.setVolume(0.4); music.play()
})
```

## Autoplay gate

Browsers suspend the `AudioContext` until a user gesture. Resume it on first interaction:

```typescript
window.addEventListener('pointerdown', () => {
  if (listener.context.state === 'suspended') listener.context.resume()
}, { once: true })
```

In XR, the session start (`enterVR`/`enterAR` button click) is itself the gesture — resume the context there.

## When to drop to AudioWorklet

Use `PositionalAudio` for sample playback and simple 3D panning. Move to an `AudioWorklet` (procedural synthesis, custom HRTF, convolution reverb fed by scene geometry, real-time analysis) when you need DSP that must run on the dedicated audio thread without main-thread jank — see the AudioWorklet pattern in `threading.md`.
