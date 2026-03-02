# 3D Interface Design

UX principles for screen-mediated 3D experiences. The user views and manipulates 3D content through a 2D viewport — desktop browser, mobile browser, or embedded 3D viewer. The user is always *outside* the 3D scene, controlling a virtual camera.

---

## Core Interaction Paradigm

> In 3D viewport design, the user operates a camera to observe and manipulate objects on the other side of a screen. The screen is a window into a 3D world, not a space the user inhabits. This is fundamentally different from XR, where the user is *inside* the space.

### What Changes from 2D

| 2D Screen | 3D Viewport |
|-----------|-------------|
| Fixed flat layout | Depth axis added — objects exist at varying distances |
| Scroll to reveal content | Orbit, pan, zoom to explore |
| Click/tap to interact | Raycast from camera to select 3D objects |
| Z-index for visual layering | Actual depth in 3D space |
| Single viewing angle | User-controlled camera angle |
| Pixel-based sizing | 3D units (meters, scene units) + screen projection |
| Hover state (mouse) | Raycast intersection highlight |

### What Stays the Same

All 2D UX fundamentals still apply:
- Cognitive load limits (Hick's Law, Miller's Law) — even more critical when adding a depth axis
- One primary action per context
- Feedback for every user action
- Consistency with platform conventions
- Error prevention and recovery
- Accessibility is not optional

---

## Camera Controls

The camera is the user's primary tool for navigating 3D content. Poor camera controls make everything else irrelevant.

### Desktop (Mouse + Keyboard)

| Action | Input | Expected Behavior |
|--------|-------|-------------------|
| Orbit (rotate) | Left-click + drag | Rotate camera around the object/focus point |
| Zoom | Mouse wheel / trackpad pinch | Camera moves closer to or farther from focus point |
| Pan | Right-click + drag / middle-click + drag | Shift the view horizontally and vertically |
| Select object | Left-click | Raycast to select a 3D object |
| Reset view | Double-click / keyboard R | Return to initial camera position |
| Free navigation | WASD + mouse look | FPS-style movement (special/editor modes only) |

### Mobile (Touch)

| Action | Gesture | Expected Behavior |
|--------|---------|-------------------|
| Orbit | One-finger drag | Rotate camera around the object |
| Zoom | Two-finger pinch | Zoom in/out |
| Pan | Two-finger drag | Shift the view |
| Select | Tap | Raycast to select a 3D object |
| Reset | Double-tap | Return to initial view |

### Camera Control Principles

1. **The user controls the camera.** Automatic camera movement is only acceptable as an initial entry animation. After that, 100% user control.
2. **Inertia makes it feel natural.** Apply damping (dampingFactor 0.05–0.1). When the user releases the mouse/finger, the camera should decelerate smoothly. Instant stops feel mechanical and jarring.
3. **Set boundaries.** Prevent the camera from penetrating inside objects, going below the ground plane, or zooming so far out that context is lost.
4. **Reset must always be available.** Double-click/double-tap to return to "home view" instantly.
5. **Cursor feedback.** On desktop, change cursor to `grab` on hover over the 3D canvas, and `grabbing` while dragging. This signals interactivity.

### Recommended OrbitControls Configuration

```
minDistance: 1.2× object bounding box (prevent internal penetration)
maxDistance: 5× object size (prevent losing context)
minPolarAngle: 10° (prevent pure top-down — disorienting)
maxPolarAngle: 170° (prevent pure bottom-up — disorienting)
enableDamping: true
dampingFactor: 0.05
autoRotate: false (default; enable only after idle timeout, if at all)
autoRotateSpeed: 1.0 (if enabled — fast rotation causes discomfort)
```

### Initial Camera Position

Choose based on content type:

| Content Type | Camera Position | Rationale |
|-------------|-----------------|-----------|
| Product viewer | 3/4 view (slightly above, slightly angled) | Maximizes information per angle |
| Architecture / space | Eye-level, looking at entrance | Matches human perspective |
| Data visualization | 45° above, showing full dataset | Overview-first, detail on demand |
| Character / avatar | Upper body center, slightly above | Natural conversational angle |

### Camera Transitions

- Transitions between view presets: 0.5–1 second with easing (cubic-bezier)
- Focus on selected object: smooth zoom toward object center
- **Never** teleport the camera instantly — it destroys spatial awareness

---

## 3D Object Interaction

### Core Interactions

| Interaction | Desktop Input | Mobile Input | Visual Feedback |
|-------------|--------------|--------------|-----------------|
| Select | Left-click | Tap | Highlight outline + subtle audio |
| Hover/Focus | Mouse hover (raycast) | N/A (use tap) | Outline glow or material shift |
| Grab | Click + drag | Long-press + drag | Object follows cursor + shadow update |
| Rotate | Click + drag on rotation handle | Two-finger twist | Smooth rotation with momentum |
| Scale | Scroll on selected object or drag handle | Two-finger pinch on object | Proportional resize + snap guides |
| Place | Drag + release | Drag + release | Snap to surface/grid + settle animation |

### Interaction Feedback Rules

- Every interaction needs immediate visual feedback (<100ms)
- Selection state must be clearly visible: outline, glow, or material change
- Audio feedback reinforces spatial awareness — a click sound localized to the object's position
- On desktop, provide hover states for all interactive objects (raycast highlight)
- On mobile, provide tap affordances (subtle animation, visual hint)

### Hit Area Sizing

- 3D object hit areas should be larger than their visual representation
- Mobile minimum: extend hit volume to cover at least 44×44px screen projection
- Small objects should have inflated invisible hit boxes for easier targeting

---

## Depth as Visual Hierarchy

Unlike flat design where z-index is abstract, 3D depth is literal and affects perception.

```
Closest to camera (foreground):
  → Active controls, selected objects, modal overlays
  → Use sparingly — foreground clutter is overwhelming

Mid-distance (primary):
  → Main content, primary objects, workspace
  → Keep interactive content at consistent depth for predictability

Far (background):
  → Environmental context, skybox, non-interactive reference objects
  → Establishes spatial grounding and atmosphere
```

**Rule**: Avoid large depth jumps between interactive elements. Consistent depth reduces eye refocusing strain and cognitive load.

### Shadows and Grounding

- **Shadows are mandatory for spatial coherence.** Objects without shadows appear to float disconnectedly.
- Ground planes, contact shadows, or ambient occlusion provide spatial grounding.
- Match virtual lighting to expected context (e.g., neutral studio lighting for product viewers).

---

## 3D Product Configurator UX

### Core Principles

1. **Real-time feedback**: Color/material changes must reflect on the 3D model instantly. >300ms delay feels sluggish.
2. **Limit choices**: Show 4–8 options at a time. Excessive choice causes decision paralysis.
3. **Guided flow**: Step-by-step progression (shape → color → material → accessories). Allow free exploration but provide a recommended order.
4. **Live price updates**: Price updates instantly when options change. Never surprise the user at checkout.
5. **Mobile-first**: 55–80% of configurator users are on mobile. Design for mobile first.

### Layout Patterns

**Desktop:**
```
┌───────────────────────────────────────────────┐
│  [ 3D Viewer (60–70% width) ] │ [ Option Panel ]│
│                                │ - Categories    │
│    Orbit / Zoom / Pan          │ - Color swatches│
│                                │ - Materials     │
│                                │ - Price         │
└───────────────────────────────────────────────┘
```

**Mobile:**
```
┌───────────────────────┐
│   [ 3D Viewer 50–60% ] │
│   Orbit / Zoom / Pinch  │
├───────────────────────┤
│  [ Tabs: Categories ]   │
│  [ Option grid/swatches]│
│  [ Fixed bottom: Price ]│
└───────────────────────┘
```

### Configurator Interactions

- **Color swatches**: Tap instantly swaps material on 3D model. Must feel instantaneous (no loading indicator needed).
- **Hotspots**: Clickable points on the 3D model surface. "Customize this part" guidance.
- **Comparison mode**: "Current vs. modified" split view or toggle.
- **Shareable state**: Encode configuration in URL parameters. Link sharing reproduces exact configuration.
- **Snapshot**: Save screenshot of current configuration.

---

## Loading UX for 3D Assets

### Why Loading Matters

3D assets are heavy. A typical web page is 2–5MB; a single 3D model can be 5–50MB. Users will not wait more than 3 seconds staring at a blank screen.

### Loading Strategy Hierarchy

```
1. Instant display (0ms)
   └── 3D viewer container + skeleton/placeholder

2. Quick preview (0–2 seconds)
   └── Low-resolution poster image (poster attribute)
   └── Or ultra-low-poly silhouette model

3. Progressive loading (2–10 seconds)
   └── Base geometry first → textures load subsequently
   └── Draco/meshopt compression + KTX2 textures
   └── User can already orbit/zoom during loading

4. Full quality (10+ seconds)
   └── High-resolution textures, environment maps
   └── Swap in background (minimize pop-in)
```

### Loading UI Patterns

| Pattern | Best For | Implementation |
|---------|----------|----------------|
| **Poster + progress bar** | Single model (product viewer) | `<model-viewer poster="img.jpg" loading="eager">` |
| **Skeleton 3D viewer** | 3D area as part of a larger page | Gray box + rotation icon placeholder |
| **Low-res → high-res swap** | Large scenes (virtual tours) | LOD 0 renders immediately → LOD 2 swaps in background |
| **Progressive glTF streaming** | Complex models (architecture, medical) | Meshopt progressive decoding |
| **Lazy load (on viewport entry)** | 3D content below the fold | IntersectionObserver triggers 3D initialization |

### Loading Interaction Rule

> **Rule**: Allow interaction during loading.

- Once the low-poly model is loaded, immediately enable orbit/zoom
- Texture loading happens in the background; swap in seamlessly on completion
- Show loading progress as percentage (based on actual asset size, not arbitrary)
- Never block interaction with a "loading" overlay

---

## Performance & Core Web Vitals

### Impact of 3D on Web Performance

| Web Vital | 3D Impact | Mitigation |
|-----------|-----------|------------|
| **LCP** (Largest Contentful Paint) | 3D canvas as LCP element increases wait | Use poster image for LCP, load 3D afterward |
| **INP** (Interaction to Next Paint) | Heavy render loop blocks main thread | OffscreenCanvas + Web Worker for render separation |
| **CLS** (Cumulative Layout Shift) | Canvas resize causes layout shift | Fix canvas size with CSS, use `aspect-ratio` property |

### Performance Budget Guidelines

```
┌─────────────────────────────┬──────────────────────────────────┐
│ Metric                       │ Budget                           │
├─────────────────────────────┼──────────────────────────────────┤
│ Initial 3D asset size        │ ≤5MB (mobile), ≤15MB (desktop)   │
│ Triangle count (mobile)      │ ≤100K                            │
│ Triangle count (desktop)     │ ≤500K                            │
│ Draw calls per frame         │ ≤100                             │
│ Texture resolution (mobile)  │ ≤1024×1024                       │
│ Texture resolution (desktop) │ ≤2048×2048                       │
│ Target FPS (during interact) │ ≥30fps (mobile), ≥60fps (desktop)│
│ JS bundle (3D-related)       │ ≤200KB (gzip, tree-shaken)       │
│ First meaningful render      │ ≤3 seconds                       │
└─────────────────────────────┴──────────────────────────────────┘
```

### Adaptive Quality

```
Device capability detection:
1. navigator.hardwareConcurrency (CPU core count)
2. renderer.info.render.calls (real-time draw calls)
3. Real-time FPS monitoring (stats-gl)

When FPS < 80% of target:
→ Reduce render resolution (lower renderer.setPixelRatio)
→ Disable post-processing
→ Disable shadows
→ Drop LOD level
→ Disable anti-aliasing

When FPS > 120% of target:
→ Progressively increase quality
```

---

## Web-Specific: Progressive Enhancement

### 3-Level Experience Model

```
Level 0: Static Fallback
├── High-resolution rendered images or image sets
├── 360° image viewer (CSS/JS-based)
└── Target: WebGL unsupported, ultra-low-end devices, accessibility fallback

Level 1: Inline 3D (Core Experience)
├── Browser 3D viewer (Three.js, Babylon.js, model-viewer)
├── Mouse/touch orbit, zoom, pan
├── Responsive canvas (viewport-aware)
└── Target: Most modern browsers

Level 2: Immersive (Bonus) — see xr-design.md
├── immersive-ar: Mobile AR placement (ARCore/ARKit)
├── immersive-vr: Headset VR session
└── Target: Compatible devices + explicit user opt-in
```

### Feature Detection Pattern

```
Capability detection order:
1. navigator.gpu exists? → Use WebGPU renderer
2. WebGL2 supported? → WebGL2 renderer
3. WebGL1 only? → WebGL1 + reduced features
4. None supported? → Level 0 fallback

XR detection (for optional immersive layer):
1. navigator.xr exists?
2. navigator.xr.isSessionSupported('immersive-ar') → Show AR button
3. navigator.xr.isSessionSupported('immersive-vr') → Show VR button
4. Not supported → Hide button entirely (not an error)
```

> **Rule**: Never present unsupported features as errors. If a device doesn't support AR, don't show an AR button. Don't show "Your browser doesn't support AR" — that's blaming the user. Only show what works.

### Web-First, Immersive-Optional Flow

```
User arrives at URL
   │
   ▼
[1] Inline 3D (in-browser 3D viewer) ← Default experience for ALL users
   │
   ├── WebGL/WebGPU unsupported? → [Fallback] Static images + 360° gallery
   │
   ▼
[2] "View in VR" / "View in AR" button (optional)
   │
   ├── immersive-vr → VR session if headset connected
   ├── immersive-ar → Mobile ARCore/ARKit session
   └── Unsupported device → Button hidden (never show an error)
```

> **Rule**: Inline 3D must be a complete experience on its own. AR/VR is a bonus layer, never a requirement.

### Cross-Browser WebGL/WebGPU Support (2025–2026)

| Feature | Chrome | Safari | Firefox | Edge |
|---------|--------|--------|---------|------|
| WebGL 2.0 | ✅ | ✅ | ✅ | ✅ |
| WebGPU | ✅ | ✅ (partial) | ⚠️ (in dev) | ✅ |

### WebGPU Transition Strategy

- WebGPU enables more draw calls, compute shaders, better performance
- Three.js r171+ `WebGPURenderer` auto-falls back to WebGL2 when unsupported
- ~60% of users support WebGPU as of 2026 — **always include WebGL fallback**
- Never require WebGPU for core functionality

### model-viewer Component (Recommended for Simple Viewers)

Google's `<model-viewer>` provides the most accessible Web 3D experience as a web component.

**Key attributes for UX optimization:**
- `poster`: Image shown before 3D loads. Essential for LCP optimization.
- `loading="lazy"`: Start loading when viewport is entered.
- `reveal="auto"`: Smooth transition from poster to 3D on load completion.
- `auto-rotate-delay`: Milliseconds of idle before auto-rotation begins. Too fast is distracting.
- `interaction-prompt`: Shows "drag to rotate" hint for first-time visitors.
- `touch-action="pan-y"`: Allows vertical page scroll while enabling 3D interaction on mobile.
- `ar-modes` priority: webxr → scene-viewer → quick-look (attempts in order).
- `ios-src`: Provide .usdz file for iOS AR Quick Look path.

---

## Mobile-Specific Constraints

- **Scroll conflict**: Touch on the 3D canvas conflicts with page scroll. Apply `touch-action: none` to the canvas, but ensure normal scroll works outside it.
- **Small touch targets**: Inflate 3D object tap hit areas to at least 44×44px screen projection.
- **Performance degradation**: High-poly models drop frames on mobile. Automatic LOD switching is required.
- **Battery drain**: 3D rendering is GPU-intensive. Pause the render loop when the user is not interacting with the 3D view.
- **Screen ratio**: In portrait mode, the 3D viewer should occupy ≤60% of screen height. Place 2D controls in the remaining space.

---

## Framework & Tool Selection Guide

| Scenario | Recommended Tool | Rationale |
|----------|-----------------|-----------|
| Single product 3D viewer | `<model-viewer>` | Zero-code, built-in accessibility, auto AR handling |
| Custom product configurator | Three.js + React Three Fiber | Fine-grained control, React ecosystem integration |
| Large 3D scenes (architecture, virtual tours) | Three.js / Babylon.js | Scene graph management, LOD, Octree |
| Rapid prototype / marketing | A-Frame | HTML-like declarative syntax, fast development |
| Game / interactive experience | PlayCanvas / Wonderland Engine | Game loop, physics engine, editor |
| Enterprise CAD / data | Babylon.js | CAD loaders, inspector, measurement tools |

---

## 3D Accessibility

### Keyboard Navigation

3D viewers must be keyboard-accessible:
- `Tab` to focus the viewer
- Arrow keys to orbit the camera
- `+`/`-` or `PgUp`/`PgDn` to zoom
- `Enter` to select an object
- `Escape` to release focus

### Screen Reader Support

- Add `role="img"` + descriptive `aria-label` to the `<canvas>` element (e.g., "Interactive 3D product viewer")
- Announce major state changes via `aria-live` region ("Color changed to red")
- Provide a text alternative alongside the 3D viewer (product specs table, text description)

### Motion Sensitivity

- Detect `prefers-reduced-motion: reduce` and disable auto-rotation
- Minimize or eliminate camera transition animations (use instant transitions)
- Disable particle effects and infinite loop animations

### Color Vision Deficiency

- In color selection UI, always pair color swatches with text labels (not just color alone)
- Ensure visual distinctions in the 3D model are not communicated solely through color

### Low Vision

- Provide sufficient zoom range
- Support high-contrast mode for UI overlays

---

## Anti-Patterns (3D Specific)

| Anti-Pattern | Why It Fails | Alternative |
|-------------|-------------|-------------|
| Blank screen until 3D fully loads | 3+ seconds blank → 50%+ bounce rate | Poster image + progress indicator |
| Same model for mobile and desktop | Frame drops, battery drain, overheating on mobile | Separate LOD assets for mobile |
| 3D canvas fills entire viewport (mobile) | Can't scroll, other content inaccessible | Limit canvas to 50–60% of screen height |
| Error message when AR unsupported | Feels like blaming the user | Simply hide the AR button |
| Auto-playing 3D animation + sound | Unexpected motion/sound disrupts context | Start on user interaction, sound off by default |
| Controls only inside the 3D scene (no 2D UI) | Hard to discover in inline 3D contexts | Place 2D HTML controls alongside/below the 3D viewer |
| No `touch-action` setting | Page scroll gets hijacked by 3D interaction | Set `touch-action: pan-y` or explicitly separate interaction zones |
| 3D viewer has no text alternative | Accessibility violation, SEO invisible | `aria-label` + text specs/description alongside |
| WebGPU-only with no fallback | ~40% of users excluded (2026) | Always include WebGL2 automatic fallback |
| Instant camera teleportation | Destroys spatial context and orientation | Smooth transitions with easing |
| Using 3D when 2D suffices | Slower, more complex, no added value | Stay 2D unless 3D solves a problem 2D cannot |

---

## When NOT to Use 3D

Not every interface benefits from a 3D viewport. Stay in 2D if:

- The task is primarily text-heavy (reading, writing, data entry)
- Speed of execution matters more than spatial understanding
- The data is inherently tabular, sequential, or flat
- The spatial dimension adds no functional value ("3D for 3D's sake")

**Rule**: 3D should solve a problem that 2D cannot. If the primary value is "it looks cool," stay 2D.

---

## 3D UX Validation Checklist

### Loading & Performance
- [ ] Poster image or skeleton displayed immediately before 3D loads
- [ ] First meaningful render within 3 seconds (even if low-poly)
- [ ] ≥30fps on mobile, ≥60fps on desktop during interaction
- [ ] Assets use Draco/meshopt compression + KTX2 textures
- [ ] Render loop pauses when 3D viewer is outside viewport
- [ ] Core Web Vitals (LCP, INP, CLS) impact minimized

### Camera & Interaction
- [ ] Mouse (orbit/zoom/pan) and touch (1-finger orbit/pinch zoom) both work
- [ ] Camera damping applied — no instant stops
- [ ] Double-click/double-tap resets view
- [ ] Camera boundaries prevent penetration inside objects and below ground
- [ ] Scroll and 3D interaction don't conflict on mobile

### Cross-Platform
- [ ] Static image fallback when WebGL unsupported
- [ ] AR button hidden (not error-messaged) on unsupported devices
- [ ] iOS AR Quick Look path (.usdz) provided where applicable
- [ ] QR code option for desktop → mobile AR handoff
- [ ] WebGPU → WebGL2 → WebGL1 sequential fallback

### Accessibility
- [ ] Keyboard navigation for the 3D viewer works
- [ ] Canvas has `aria-label` + `role` attributes
- [ ] `prefers-reduced-motion` disables auto-rotation and animations
- [ ] Color selection UI includes text labels
- [ ] Text alternative for 3D content is provided

### Configurator (if applicable)
- [ ] Color/material changes reflect on model in <300ms
- [ ] Options limited to 4–8 per category
- [ ] Price updates in real-time with option changes
- [ ] Configuration shareable via URL parameters
- [ ] Mobile layout tested (3D viewer + controls without scroll conflict)
