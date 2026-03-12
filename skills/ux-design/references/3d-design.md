# 3D Interface Design

UX principles for screen-mediated 3D experiences. The user views and manipulates 3D content through a 2D viewport — desktop browser, mobile browser, or embedded viewer. The user is always *outside* the 3D scene, controlling a virtual camera.

For technical implementation (renderers, frameworks, APIs, performance optimization), see the `web3d` skill.

---

## Core Interaction Paradigm

> The screen is a window into a 3D world, not a space the user inhabits. This is fundamentally different from XR, where the user is *inside* the space. See `xr-design.md` for embodied spatial design.

### What Changes from 2D

| 2D Screen | 3D Viewport |
|-----------|-------------|
| Fixed flat layout | Depth axis — objects exist at varying distances |
| Scroll to reveal content | Orbit, pan, zoom to explore |
| Click/tap to interact | Point through camera to select 3D objects |
| Z-index for visual layering | Actual depth in 3D space |
| Single viewing angle | User-controlled camera angle |
| Hover state (mouse) | Intersection highlight on 3D surfaces |

### What Stays the Same

All 2D UX fundamentals still apply — and become even more critical when adding a depth axis:
- Cognitive load limits (Hick's Law, Miller's Law)
- One primary action per context
- Feedback for every user action
- Consistency with platform conventions
- Error prevention and recovery
- Accessibility is not optional

---

## Camera Interaction Design

The camera is the user's primary tool for navigating 3D content. Poor camera controls make everything else irrelevant.

### Expected Controls

**Desktop (Mouse + Keyboard):**

| Action | Input | Behavior |
|--------|-------|----------|
| Orbit (rotate) | Left-click + drag | Rotate around the focus point |
| Zoom | Mouse wheel / trackpad pinch | Move closer to or farther from focus point |
| Pan | Right-click + drag / middle-click + drag | Shift the view |
| Select | Left-click on object | Select the 3D object |
| Reset view | Double-click / R key | Return to initial camera position |

**Mobile (Touch):**

| Action | Gesture | Behavior |
|--------|---------|----------|
| Orbit | One-finger drag | Rotate around the object |
| Zoom | Two-finger pinch | Zoom in/out |
| Pan | Two-finger drag | Shift the view |
| Select | Tap on object | Select the 3D object |
| Reset | Double-tap | Return to initial view |

### Camera Design Principles

1. **The user controls the camera.** Automatic camera movement is only acceptable as an initial entry animation. After that, 100% user control.
2. **Movement must feel natural.** When the user releases, the camera should decelerate smoothly (damping). Instant stops feel mechanical and jarring.
3. **Set boundaries.** Prevent the camera from going inside objects, below the ground, or zooming so far out that context is lost.
4. **Reset must always be available.** Users need a way to return to "home view" at any time (double-click/double-tap).
5. **Signal interactivity.** On desktop, change cursor to grab/grabbing on the 3D canvas. On mobile, use subtle affordance hints.

### Initial Camera Position

Choose based on what helps the user understand the content fastest:

| Content Type | Camera Position | Why |
|-------------|-----------------|-----|
| Product viewer | 3/4 view (slightly above, slightly angled) | Maximizes information per angle |
| Architecture / space | Eye-level, looking at entrance | Matches human perspective |
| Data visualization | 45° above, showing full dataset | Overview-first, detail on demand |
| Character / avatar | Upper body center, slightly above | Natural conversational angle |
| Photorealistic scene (splats) | Best-captured viewpoint | Minimizes artifacts, maximizes quality |

### Camera Transitions

- Between view presets: 0.5–1 second with easing
- Focus on selected object: smooth zoom toward object center
- **Never teleport the camera instantly** — it destroys spatial awareness

---

## 3D Object Interaction

### Interaction Patterns

| Interaction | Desktop | Mobile | Feedback |
|-------------|---------|--------|----------|
| Select | Click | Tap | Highlight outline + subtle audio |
| Hover/Focus | Mouse hover | N/A (use tap) | Outline glow or material shift |
| Grab | Click + drag | Long-press + drag | Object follows cursor + shadow updates |
| Rotate | Drag rotation handle | Two-finger twist | Smooth rotation with momentum |
| Scale | Scroll on object or drag handle | Two-finger pinch on object | Proportional resize + snap guides |
| Place | Drag + release | Drag + release | Snap to surface/grid + settle animation |

### Feedback Rules

- Every interaction needs immediate visual response (<100ms)
- Selection state must be unmistakable: outline, glow, or material change
- Audio feedback reinforces spatial awareness — sound localized to the object's position
- Desktop: hover states on all interactive objects
- Mobile: tap affordances (subtle animation, visual hint) since hover doesn't exist

### Hit Area Sizing

- 3D object hit areas should be **larger** than visual representation
- Mobile: extend hit volume to cover at least 44×44px screen projection
- Small objects need inflated invisible hit volumes for easier targeting

---

## Depth as Visual Hierarchy

Unlike 2D where z-index is abstract, 3D depth is literal and affects perception.

```
Closest to camera (foreground):
  → Active controls, selected objects, modal overlays
  → Use sparingly — foreground clutter is overwhelming

Mid-distance (primary):
  → Main content, primary objects, workspace
  → Keep interactive content at consistent depth for predictability

Far (background):
  → Environmental context, non-interactive reference objects
  → Establishes spatial grounding and atmosphere
```

**Rule**: Avoid large depth jumps between interactive elements. Consistent depth reduces eye refocusing strain and cognitive load.

### Shadows and Grounding

- **Shadows are mandatory.** Objects without shadows appear to float disconnectedly.
- Ground planes, contact shadows, or ambient occlusion provide spatial grounding.
- Match virtual lighting to expected context (neutral studio for products, environmental for architecture).

---

## Discoverability & First-Time Experience

3D viewers present a discoverability challenge — users may not realize they can interact, or may not know what interactions are available.

### Onboarding Patterns

| Pattern | When to Use |
|---------|-------------|
| **"Drag to rotate" hint** | First visit to any 3D viewer. Show for 3–5 seconds, dismiss on first interaction. |
| **Subtle auto-rotation** | On idle after 5+ seconds. Slow speed. Stops immediately on user interaction. |
| **Pulsing hotspots** | Configurators with clickable parts. Shows where interaction is possible. |
| **Guided tour** | Complex 3D scenes (architecture walkthrough). Step-by-step camera movements with annotations. |

### Design Rules

- Assume the user has never used a 3D viewer before
- Place 2D controls (buttons, menus) alongside the 3D viewport — don't hide controls inside the 3D scene
- Label what the viewer shows: "360° Product View" or "Interactive Floor Plan" sets expectations
- Provide a text description or specs table as a non-3D alternative for the same information

---

## Product Configurator UX

### Core Principles

1. **Instant feedback**: Option changes must reflect on the 3D model immediately. >300ms delay feels sluggish.
2. **Limit choices**: 4–8 options per category. Excessive choice causes decision paralysis (Hick's Law).
3. **Guided flow**: Step-by-step progression (shape → color → material → accessories). Allow free exploration but provide a recommended order.
4. **Live price updates**: Price changes instantly when options change. Never surprise the user at checkout.
5. **Mobile-first**: 55–80% of configurator users are on mobile.

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

### Key Interactions

- **Color swatches**: Tap swaps material instantly on the 3D model
- **Hotspots**: Clickable points on the model surface — "Customize this part"
- **Comparison mode**: "Current vs. modified" split view or toggle
- **Shareable state**: Configuration encoded in URL — link sharing reproduces exact state
- **Snapshot**: Save screenshot of current configuration

---

## Photorealistic Scene Content (Gaussian Splatting)

Gaussian Splatting renders photorealistic scenes captured from real-world photos. Unlike traditional 3D models (polygons + textures), splat scenes feel near-photographic — which changes user expectations.

### When to Use

| Use Case | Why Splats Work |
|----------|-----------------|
| Real estate walkthroughs | Photorealistic room capture from phone photos |
| E-commerce product scans | True-to-life appearance without manual 3D modeling |
| Cultural heritage / museums | Preserve real-world scenes with high fidelity |
| Tourism / location preview | Navigable scenes from photo captures |

### UX Differences from Traditional 3D

- **Users expect photographic quality.** Artifacts at scene boundaries or undersampled areas feel like "broken" content — crop or mask edge regions.
- **Navigation should be constrained.** Splat scenes work best with defined camera paths. Free-roaming exposes rendering artifacts at unobserved angles.
- **Loading is heavier.** Splat files are large (50–200MB). Progressive loading (low-density preview first, then stream detail) is essential.
- **Fallback is critical.** Provide a pre-rendered image gallery or 360° photo viewer for devices that can't render splats.

---

## Scroll-Driven 3D Storytelling

Scroll input controlling 3D animation creates compelling narratives — product reveals, data stories, spatial explainers. This is a distinct paradigm from free-orbit 3D viewers.

### Design Rules

1. **Progress indicator is mandatory.** Users must know where they are in the sequence (dots, bar, or percentage).
2. **Skip control is mandatory.** Users must be able to jump ahead or escape the sequence at any time.
3. **Respect reduced motion preferences.** Provide a static fallback showing key frames without animation.
4. **Content must work without the 3D.** Text, key information, and CTAs must be accessible independently of the animation.
5. **Keep it short.** 3–5 "scenes" or steps. Long sequences (>10) cause fatigue and abandonment.
6. **Don't hijack scroll.** The 3D experience must not prevent the user from scrolling past it to reach other content.

---

## Loading Experience

3D assets are heavy. Users will not wait more than 3 seconds staring at a blank screen.

### Loading Hierarchy

```
1. Instant (0ms)
   └── Container + skeleton/placeholder visible immediately

2. Quick preview (0–2s)
   └── Poster image or ultra-low-poly silhouette

3. Progressive (2–10s)
   └── Base geometry first → textures load after
   └── User can already orbit/zoom during loading

4. Full quality (10s+)
   └── High-resolution textures swap in background
   └── Minimize visible pop-in
```

### Loading UI Patterns

| Pattern | Best For |
|---------|----------|
| Poster image + progress bar | Single product viewer |
| Skeleton placeholder | 3D area within a larger page |
| Low-res → high-res swap | Large scenes (virtual tours, splats) |
| Lazy load on scroll | 3D content below the fold |

### Core Rule

> Allow interaction during loading. Once the low-poly model is ready, enable orbit/zoom immediately. Never block interaction with a loading overlay.

---

## Mobile UX

- **Scroll conflict**: Touch on the 3D canvas conflicts with page scroll. Clearly separate 3D interaction zones from scrollable areas.
- **Small touch targets**: Inflate 3D object tap hit areas to at least 44×44px screen projection.
- **Performance**: High-poly models drop frames on mobile. The experience should automatically adapt quality to maintain smooth interaction.
- **Battery**: Pause the render loop when the user is not interacting.
- **Screen ratio**: In portrait, the 3D viewer should occupy ≤60% of screen height. Place 2D controls in the remaining space.

---

## Progressive Experience Levels

Design 3D experiences as layered capabilities, not single-platform bets:

```
Level 0: Static Fallback
├── High-resolution rendered images or 360° image viewer
└── For: unsupported browsers, accessibility, ultra-low-end devices

Level 1: Inline 3D (Core Experience)
├── Browser 3D viewer with orbit, zoom, pan
└── For: most modern browsers (default experience)

Level 2: Immersive (Optional) — see xr-design.md
├── Mobile AR placement or VR headset session
└── For: compatible devices + explicit user opt-in
```

**Rules:**
- Level 1 must be a complete experience. AR/VR is a bonus, never a requirement.
- Never show error messages for unsupported features. If a device can't do AR, don't show an AR button. Blaming the user's device is poor UX.
- Only show what works.

---

## 3D Accessibility

### Keyboard Navigation

3D viewers must be keyboard-accessible:
- Tab to focus the viewer
- Arrow keys to orbit
- +/- or PgUp/PgDn to zoom
- Enter to select an object
- Escape to release focus

### Alternative Representations

- Provide a text description or specs table alongside the 3D viewer
- Announce major state changes to screen readers ("Color changed to red", "Viewing from front")
- The 3D viewer is an enhancement — the information it conveys must also be available in text

### Motion Sensitivity

- Respect reduced-motion preferences: disable auto-rotation, minimize camera animations
- Disable particle effects and infinite loop animations
- User-initiated motion is acceptable; system-initiated motion is not

### Color and Vision

- Color swatches must include text labels (not color alone)
- Visual distinctions in the 3D model must not rely solely on color
- Provide sufficient zoom range for low-vision users
- Support high-contrast mode for UI overlays

---

## When NOT to Use 3D

Stay in 2D if:

- The task is primarily text-heavy (reading, writing, data entry)
- Speed of execution matters more than spatial understanding
- The data is inherently tabular, sequential, or flat
- The spatial dimension adds no functional value

**Rule**: 3D should solve a problem that 2D cannot. If the primary value is "it looks cool," stay 2D.

---

## Anti-Patterns

| Anti-Pattern | Why It Fails | Alternative |
|-------------|-------------|-------------|
| Blank screen until 3D fully loads | 3+ seconds blank → 50%+ bounce rate | Poster image + progress indicator |
| Same quality model for mobile and desktop | Frame drops, battery drain, overheating | Adaptive quality, separate LOD for mobile |
| 3D canvas fills entire viewport (mobile) | Can't scroll, other content inaccessible | Limit canvas to 50–60% of screen height |
| Error message when AR unsupported | Blames the user's device | Hide the AR button entirely |
| Auto-playing 3D animation + sound | Unexpected motion/sound disrupts context | Start on user interaction, sound off by default |
| Controls only inside the 3D scene | Hard to discover, not accessible | Place 2D controls alongside the 3D viewer |
| No touch handling on mobile | Page scroll gets hijacked by 3D interaction | Separate interaction zones clearly |
| No text alternative for 3D content | Accessibility violation, information locked in visual-only format | Text description/specs alongside viewer |
| Instant camera teleportation | Destroys spatial context and orientation | Smooth transitions with easing |
| Using 3D when 2D suffices | Slower, more complex, no added value | Stay 2D unless 3D solves a problem 2D cannot |
| Unconstrained navigation in photorealistic scenes | Edge artifacts destroy the quality illusion | Constrain camera paths, mask edges |
| Scroll-driven 3D with no skip/escape | Users feel trapped in an unskippable animation | Skip control + jump-to-section |
| Scroll-driven 3D without reduced-motion fallback | Accessibility violation | Static key-frame fallback |

---

## Validation Checklist

### Loading
- [ ] Poster/skeleton displayed before 3D loads
- [ ] First meaningful render within 3 seconds
- [ ] Interaction possible during loading (orbit/zoom on low-poly)
- [ ] Smooth quality improvement (no jarring pop-in)

### Camera & Interaction
- [ ] Desktop (orbit/zoom/pan) and mobile (drag/pinch) both work
- [ ] Camera movement has smooth damping — no instant stops
- [ ] Reset view available (double-click/double-tap)
- [ ] Camera cannot go inside objects or below ground
- [ ] Scroll and 3D interaction don't conflict on mobile

### Discoverability
- [ ] User understands they can interact (hint, label, or affordance)
- [ ] 2D controls placed alongside the 3D viewer (not hidden inside)
- [ ] Content type labeled ("360° View", "Interactive Floor Plan")

### Progressive Experience
- [ ] Static image fallback for unsupported browsers
- [ ] AR/VR buttons hidden (not error-messaged) when unsupported
- [ ] Core experience works without AR/VR

### Accessibility
- [ ] Keyboard navigation works
- [ ] Text alternative provided for 3D content
- [ ] Reduced-motion preferences respected (no auto-rotation)
- [ ] Color selections include text labels
- [ ] Screen reader announcements for state changes

### Configurator (if applicable)
- [ ] Option changes reflected on model in <300ms
- [ ] 4–8 options per category (no choice overload)
- [ ] Price updates in real-time
- [ ] Configuration shareable via URL
- [ ] Mobile layout tested (viewer + controls without scroll conflict)

### Photorealistic Scenes (if applicable)
- [ ] Progressive loading with preview
- [ ] Camera paths constrained to captured viewpoints
- [ ] Edge artifacts masked or cropped
- [ ] Fallback for unsupported devices

### Scroll-Driven 3D (if applicable)
- [ ] Progress indicator visible
- [ ] Skip / jump control available
- [ ] Reduced-motion fallback works
- [ ] Content functional without the 3D animation
