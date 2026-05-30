# Testing Web3D / XR Code

The hard truth of this domain: **you cannot unit-test a draw call.** Rendering, shaders, and frame loops need a real GPU context; everything else (simulation, math, data) is ordinary testable code. Split your testing along that line and test the testable layer *first*.

## What to test where

| Layer | How | Notes |
|---|---|---|
| Koota systems | Vitest, plain functions | Systems are `(world, delta) => void` — spawn entities, run the system, assert trait values. No renderer needed. |
| Rapier physics | Vitest, deterministic | Rapier stepping is deterministic for a fixed timestep + seed. Snapshot/restore via `world.takeSnapshot()` / `World.restoreSnapshot()` to assert reproducible state. |
| Rust WASM exports | `wasm-bindgen-test` (Rust) or Vitest against the built pkg | Test the pure compute (terrain heights, particle integration) at the boundary. |
| TSL node graphs | Assert on the built node tree / compiled output | You can build a material's node and assert structure, or compile and snapshot the generated WGSL/GLSL string — catches accidental graph changes without a GPU. |
| Pure math/util | Vitest | Vectors, quaternions, layout offsets, NDC conversion. |
| Render output (shaders, materials, scene) | Playwright/Puppeteer + headless Chrome with `--enable-unsafe-webgpu`, or Deno's native WebGPU | Capture a frame, compare against a reference image (pixel-diff with a tolerance). This is **visual regression**, not unit testing. |
| R3F components | `@react-three/test-renderer` | Renders the R3F tree to a mock scene graph (no real GPU) so you can assert on objects/props and fire events. |

## Koota system test (write this first)

```typescript
import { createWorld, trait } from 'koota'
import { expect, test } from 'vitest'

const Position = trait({ x: 0, y: 0, z: 0 })
const Velocity = trait({ x: 0, y: 0, z: 0 })

function movementSystem(world, delta) {
  world.query(Position, Velocity).updateEach(([pos, vel]) => {
    pos.x += vel.x * delta
  })
}

test('movement integrates velocity', () => {
  const world = createWorld()
  const e = world.spawn(Position({ x: 0 }), Velocity({ x: 2 }))
  movementSystem(world, 0.5)
  expect(e.get(Position).x).toBe(1)
})
```

## Visual regression for shaders (the GPU path)

```typescript
// playwright.config: launch chromium with --enable-unsafe-webgpu --use-gl=angle
import { test, expect } from '@playwright/test'

test('fresnel material renders', async ({ page }) => {
  await page.goto('/scenes/fresnel')
  await page.waitForFunction(() => (window as any).__renderedFrames > 2) // wait for init + a few frames
  expect(await page.locator('canvas').screenshot()).toMatchSnapshot('fresnel.png', { maxDiffPixelRatio: 0.02 })
})
```

Headless WebGPU is still flaky across CI images and driver versions — gate visual tests behind a capability check and keep the simulation-layer unit tests as your fast, reliable signal.

## TDD reality check

"Tests first" here means: write the Koota/physics/WASM/math tests before the implementation. It does **not** mean writing a failing test for "the sphere looks right" — that's a visual-regression baseline you capture once the look is approved, then guard against drift.
