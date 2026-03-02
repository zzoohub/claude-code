# XR Interface Design

UX principles for spatially embodied experiences — AR, VR, and MR. The user is *inside* the interface, interacting with their body (gaze, hands, head, voice) rather than through a screen and pointer. Covers headset-native platforms (visionOS, Quest, Android XR) and WebXR immersive sessions.

---

## Core Paradigm Shift

> In 2D, you design within a frame. In 3D viewport design, the user looks *through* a window into a 3D world. In XR, the user exists *inside* the interface. The space is the canvas. The body is the input device.

### What Changes from 2D and 3D Viewport

| 2D / 3D Viewport | XR (Spatial / Embodied) |
|-------------------|-------------------------|
| Fixed viewport size | Infinite canvas, limited by human vision |
| Mouse/touch pointer | Eye gaze, hand tracking, head movement, controllers, voice |
| Flat layout grid (or camera-viewed 3D) | Depth, distance, elevation, curvature — all physical |
| Scroll/orbit to reveal | Walk, turn, or teleport to discover |
| Hover state / raycast highlight | Gaze dwell + highlight state |
| Z-index / camera depth | Actual depth in meters |
| Single viewing angle (user chooses) | 360° potential viewing angle (user is surrounded) |
| Pixel-based sizing | Physical-scale sizing (meters, angular size at distance) |
| User sits at a desk/holds a phone | User stands, sits, moves, reaches with arms |

### What Stays the Same

These 2D UX fundamentals transfer directly — and apply with even greater force:
- Cognitive load limits (Hick's Law, Miller's Law) — spatial overload is more disorienting than screen overload
- Hierarchy and focus: one primary action per context
- Feedback for every user action
- Consistency with platform-standard patterns
- Error prevention and recovery
- Accessibility is not optional

---

## Spatial Comfort Zones

The most critical ergonomic constraint in XR. All content placement starts here.

### Field of View (FOV) — Horizontal

```
                    ┌─────────────────────────────────┐
                    │         IMPOSSIBLE (>50°)        │
                    ├─────────────────────────────────┤
                    │     UNCOMFORTABLE (30°–50°)      │
                    │   Neck strain, occasional use    │
                    ├─────────────────────────────────┤
                    │                                  │
                    │     COMFORTABLE (±30° center)    │
                    │   Primary content lives here     │
                    │                                  │
                    ├─────────────────────────────────┤
                    │     UNCOMFORTABLE (30°–50°)      │
                    ├─────────────────────────────────┤
                    │         IMPOSSIBLE (>50°)        │
                    └─────────────────────────────────┘
                              ← User →
```

- **±30° from center**: Comfortable zone. All primary content and frequent interactions.
- **30°–50°**: Straining. Occasional secondary content only.
- **>50°**: Physically impossible for most users. Never place content here.

### Field of View — Vertical

- **Ideal**: 40° area slightly above center of vision (horizon line)
- **Comfortable**: 0° to +20° above horizon (slight upward gaze)
- **Acceptable**: –15° to +35° from horizon
- **Avoid**: Looking straight up or straight down for extended periods

### Content Distance Zones

```
┌──────────┬─────────────────────┬──────────────────────────────────────┐
│ Distance │ Zone                │ Use Case                             │
├──────────┼─────────────────────┼──────────────────────────────────────┤
│ <0.5m    │ Intimate / Danger   │ NEVER place content here.            │
│          │                     │ Collision risk, eye strain.          │
├──────────┼─────────────────────┼──────────────────────────────────────┤
│ 0.5–1.2m │ Personal            │ Hand-reach tools, object             │
│          │                     │ manipulation, wrist-anchored UI.     │
├──────────┼─────────────────────┼──────────────────────────────────────┤
│ 1.25–2m  │ Optimal Interaction │ Primary UI panels, menus,            │
│          │                     │ dashboards. DEFAULT ZONE.            │
├──────────┼─────────────────────┼──────────────────────────────────────┤
│ 2–5m     │ Social / Reference  │ Shared content, presentations,       │
│          │                     │ environmental storytelling.          │
├──────────┼─────────────────────┼──────────────────────────────────────┤
│ >5m      │ Background          │ Environments, skyboxes, ambient.     │
│          │                     │ Not interactive.                     │
└──────────┴─────────────────────┴──────────────────────────────────────┘
```

**Rule**: Essential interactive UI → 1.25–2m from user. This is non-negotiable. Apple visionOS, Meta Quest, and Android XR all converge on this range.

### Platform-Specific Defaults

| Platform | Default Panel Distance | Vertical Offset | Min Target Area |
|----------|----------------------|-----------------|-----------------|
| visionOS | 1.5m | Slightly below eye level | 60×60pt (eye targeting) |
| Android XR | 1.75m | 5° below eye level | Material Design targets |
| Meta Quest | 1.5m | Eye level | 48×48dp equivalent |

---

## Spatial Interaction Models

### Input Modalities

| Input | Strengths | Limits | Best For |
|-------|-----------|--------|----------|
| Eye gaze + pinch | Hands-free pointing, fastest targeting | Low precision, fatigue from prolonged pinching | Menu selection, navigation, browsing |
| Hand tracking (direct) | Natural, intuitive manipulation | Arm fatigue ("gorilla arm"), occlusion | Object manipulation, sliders, close-range tools |
| Hand tracking (indirect) | Comfortable distance interaction | Less intuitive than direct | Pointing at distant content, ray-cast selection |
| Controllers | Precise, haptic feedback, buttons | Requires physical device, learning curve | Gaming, precise creation tools, extended sessions |
| Voice | Hands-free, natural | Privacy concerns, ambient noise, latency | Commands, search, dictation, accessibility |
| Head gaze | Hands-free fallback | Imprecise, can cause neck fatigue | Accessibility fallback, coarse targeting |

### Multimodal Design Rules

1. **Never rely on a single modality.** Always provide at least one fallback (e.g., gesture + voice, gaze + controller).
2. **Match modality to precision need.** Eye gaze for coarse targeting → hand for fine manipulation → voice for text input.
3. **Allow modality switching at any time.** Users should never feel locked into one input method.

### Gesture Design Principles

```
GOOD Gestures:
✓ Tap (pinch thumb + index) — familiar, low effort
✓ Drag — grab + move, natural physics
✓ Scale — two-hand pinch to resize
✓ Rotate — wrist twist for objects, not navigation

BAD Gestures:
✗ Complex multi-finger combinations (high cognitive load)
✗ Sustained arm-raised positions (gorilla arm fatigue)
✗ Hidden gestures with no visual affordance (undiscoverable)
✗ Fast, precise gestures required for core functions (error-prone)
```

**Rule**: Frequently used interactions must be brief, simple, and achievable with minimum physical effort. Less frequent interactions can require more effort.

---

## Spatial UI Patterns

### UI Anchoring Types

| Type | Behavior | Use Case |
|------|----------|----------|
| **World-anchored** | Fixed in 3D space, stays in place | Dashboards, maps, reference panels |
| **Body-anchored** | Follows user position, stays relative to body | HUD elements, persistent controls |
| **Hand-anchored** | Attached to hand/wrist | Quick-access tools, contextual menus |
| **Gaze-anchored** | Follows gaze direction (tag-along) | Tooltips, notifications (use sparingly) |
| **Surface-anchored** | Attached to real-world surface (AR) | Instructions on machines, labels on objects |

**Default choice**: World-anchored for primary content. Body-anchored for persistent controls.

**Anti-pattern**: Gaze-anchored UI that blocks content or feels "sticky." If UI follows gaze, add dampening (gentle follow with delay) and let users dismiss or pin it.

### Depth as Hierarchy

Unlike 2D z-index, depth in XR is physical and has ergonomic implications.

```
Closest to user (foreground):
  → Active controls, modals, urgent feedback
  → Sparingly — too much close content is claustrophobic

Mid-distance (primary):
  → Main content panels, workspace
  → Keep interactive content at consistent depth for easy transitions

Far (background):
  → Environmental context, reference content
  → Non-interactive or infrequently interactive
```

**Rule**: Maintain interactive content at a consistent depth to reduce eye refocusing strain. Subtle depth differences (not large jumps) communicate hierarchy.

### Curved UI Panels

Flat panels at wide angles create uneven viewing distances from center to edges. Use curved panels to match the user's natural visual arc.

- **Curvature radius**: Match the distance to user (panel at 2m → radius ~2m)
- **When to use**: Panels wider than 60° of FOV
- **When not to use**: Small panels, single-action modals

### Dynamic Scaling

visionOS and Android XR automatically scale UI as panels move closer/farther. Design for this:
- **Test at multiple distances**: Content must remain legible and interactive at 0.75m–3m
- **Don't rely on fixed pixel sizes**: Use point-based or physical units
- **Typography minimum**: 14dp or equivalent for legibility at distance

---

## Spatial States & Feedback

### The Multisensory Feedback Model

Every interaction needs feedback across multiple sensory channels:

| Channel | Purpose | Examples |
|---------|---------|---------|
| **Visual** | Confirm action, show state | Highlight, glow, particle effect, material change |
| **Audio** | Spatial confirmation, ambient cues | Click sound from UI element position, spatial audio indicators |
| **Haptic** | Physical confirmation (if controller) | Pulse on selection, resistance on limits |

**Rule**: In XR, audio feedback is more important than on flat screens. Sound spatially positioned at the interaction point increases presence and confirms actions.

### Hover & Focus States in 3D Space

Without a mouse cursor, spatial interfaces need alternative focus indicators:

| Trigger | Response | Notes |
|---------|----------|-------|
| Eye gaze dwell (visionOS) | Subtle highlight + depth lift | Don't trigger actions on gaze alone |
| Hand ray intersection | Outline glow or material shift | Must be visible from interaction distance |
| Proximity (hand near object) | Object "breathes" or gently reacts | Only for direct manipulation objects |
| Controller ray | Highlight + audio tick | Standard pattern for controller-based UIs |

### State Transitions in XR

2D screen transitions don't always translate. Spatial alternatives:

| 2D Pattern | XR Equivalent | Notes |
|------------|---------------|-------|
| Page transition | Panel swap (dissolve or slide in z-depth) | Never teleport entire view without warning |
| Modal overlay | Panel floats forward from content | Dim background environment slightly |
| Dropdown menu | Orbiter (panel that expands from anchor point) | Position relative to triggering element |
| Toast notification | Spatial bubble at source location + audio | Audio cue from direction of relevant content |
| Loading spinner | Skeleton shimmer or ambient particle | Keep environment stable while loading |

---

## Cybersickness Prevention

The #1 design failure in XR. If users feel sick, nothing else matters.

### Root Cause

Sensory mismatch between what eyes see (motion) and what the vestibular system feels (no motion). The greater the mismatch, the faster symptoms onset.

### Hard Rules (Never Violate)

1. **Never move the camera without user initiation.** No camera shake, no forced head turns, no cutscene head movement.
2. **Maintain ≥90Hz frame rate** (72Hz absolute minimum). Dropped frames cause immediate discomfort.
3. **Keep latency <20ms** from head movement to visual update.
4. **The horizon must stay stable.** If the world tilts, users will feel sick.
5. **Never change field of view programmatically** without user control.

### Locomotion Hierarchy (Safest → Riskiest)

```
1. Teleportation (safest)
   → Point and blink to new location
   → No continuous motion, no mismatch

2. Snap turning
   → Discrete rotation increments (30°/45°/90°)
   → Avoids continuous rotation conflict

3. Room-scale movement (safe)
   → User physically walks
   → 1:1 motion = zero mismatch

4. Smooth locomotion with vignette
   → Reduce peripheral FOV during movement
   → Reduces visual flow conflict

5. Smooth continuous movement (riskiest)
   → Only for experienced users, opt-in only
   → Always provide comfort alternatives
```

**Rule**: Ship with teleport + snap turn as defaults. Smooth locomotion = opt-in for experienced users.

### Comfort Settings (Must Provide)

- Locomotion mode (teleport / snap / smooth)
- Turning mode (snap angle / smooth)
- Vignette intensity during movement
- Seated / standing / room-scale toggle
- Movement speed adjustment
- FOV restriction during fast motion

---

## Spatial Accessibility

### Extended Requirements Beyond 2D

| Concern | Requirement |
|---------|-------------|
| **Seated use** | All interactions reachable from seated position. Never require standing. |
| **One-handed use** | Core functions must work with single hand input. |
| **Reduced motion** | Respect `prefers-reduced-motion`. Provide static alternatives for all animations. |
| **Vision** | Minimum contrast same as 2D WCAG (4.5:1 text, 3:1 UI). Distance magnifies need. |
| **Hearing** | Never rely on spatial audio alone. Visual indicators for all audio cues. |
| **Motor** | Provide controller, voice, and gaze input alternatives. No precision-dependent core functions. |
| **Cognitive** | Minimize simultaneous 3D stimuli. Progressive disclosure even more critical in XR. |
| **Photosensitivity** | Avoid strobing, rapid flashing, or high-contrast flickering in peripheral vision. |

### Eye Targeting Accessibility

- **Minimum target area**: 60×60pt for eye-gaze targeting (larger than 2D touch targets)
- **Spacing**: ≥8pt between targets in all directions
- **Shape**: Round or rounded-rectangle targets improve gaze accuracy
- **Dwell time**: Provide adjustable gaze dwell timers for activation

---

## Platform Design Languages

### visionOS (Apple Vision Pro)

**Core concepts**: Windows, Volumes, Spaces

| Container | Description | Use Case |
|-----------|-------------|----------|
| **Window** | 2D panel in 3D space (glass material) | Apps, documents, browsing |
| **Volume** | Bounded 3D content box | 3D models, data visualizations |
| **Full Space** | Immersive, single-app environment | Games, immersive experiences, presentations |

**Key design rules**:
- Use glass material (system-provided) for window backgrounds — adapts to lighting, blends with environment
- Point-based units translate from iOS directly
- Tab bar for top-level navigation, toolbar for contextual controls (positioned using depth)
- System handles ornament positioning (close button, grab bar) — don't override
- Multi-layer app icons (up to 3 layers): background + 2 foreground, 1024×1024px each, circular crop auto-applied

### Meta Quest (Horizon OS)

**Key patterns**:
- Panel-based UI with passthrough-aware placement
- Controller-first with hand tracking fallback
- System boundary (Guardian) must be respected — never place content beyond boundary
- Comfort rating system: Comfortable / Moderate / Intense (declare honestly)

### Android XR

**Key patterns**:
- Material Design adapted for spatial (same components, spatial elevation added)
- Dynamic scaling between 0.75m–1.75m (consistent size), then scales at 0.5m per meter beyond
- Orbiters: floating action panels attached to edges of spatial panels (like FABs in 3D)
- Font minimum: 14dp, weight ≥ normal for legibility

---

## Spatial Information Architecture

### Navigation in XR

Traditional navigation patterns need rethinking in spatial environments.

| 2D Pattern | XR Equivalent |
|------------|---------------|
| Tab bar | Spatial tab bar (visionOS) or orbiter navigation |
| Sidebar | Detachable side panel with depth offset |
| Breadcrumb | Spatial trail or minimap |
| Back button | Gesture (swipe back) or persistent control |
| Hamburger menu | Avoid — use spatial tab bar or wrist menu |

### Content Organization

- **Spatial grouping**: Related items physically close together
- **Depth layering**: Primary content forward, secondary behind
- **Environmental zones**: Different functional areas mapped to spatial regions
- **Progressive disclosure**: Start with minimal UI, reveal more based on context and user intent

---

## 3D Content in XR Spaces

### Object Interaction

| Interaction | Input | Feedback |
|-------------|-------|----------|
| Select | Gaze + tap / ray + trigger | Highlight outline + audio |
| Grab | Pinch or grip | Object follows hand + haptic weight simulation |
| Rotate | Wrist rotation or two-hand twist | Smooth rotation with momentum |
| Scale | Two-hand pinch (spread/contract) | Proportional resize + snap guides |
| Place | Move + release | Snap to surface or grid + settle animation |

### Performance & Visual Quality in XR

- **Target**: 90fps at all times. Frame drops → discomfort and potential cybersickness
- **Level of Detail (LOD)**: Use LOD switching. High detail at close range, simplified at distance
- **Lighting**: Match virtual lighting to real-world environment (AR) for believability
- **Shadows**: Essential for spatial grounding. Objects without shadows appear to float unnaturally
- **Occlusion**: Virtual objects must be occluded by real-world objects (AR) for spatial coherence

---

## WebXR Considerations

When delivering XR experiences through the browser rather than native apps.

### Browser WebXR Support (2025–2026)

| Feature | Chrome | Safari | Firefox | Edge |
|---------|--------|--------|---------|------|
| inline XR session | ✅ | ✅ | ✅ | ✅ |
| immersive-vr | ✅ | ✅ (visionOS) | ⚠️ | ✅ |
| immersive-ar | ✅ (Android) | ❌ | ❌ | ✅ (Android XR) |
| Hand tracking | ✅ (partial) | ❌ | ❌ | ✅ (partial) |
| Hit test | ✅ (Android) | ❌ | ❌ | ✅ |
| Depth sensing | ✅ (Android) | ❌ | ❌ | ✅ |

### Fallback Strategy Matrix

| Device | WebXR AR | WebXR VR | Inline 3D | Final Fallback |
|--------|----------|----------|-----------|----------------|
| Android (modern) | ✅ Scene Viewer / WebXR | ✅ Cardboard | ✅ Three.js | Static image |
| iPhone / iPad | ❌ → AR Quick Look (.usdz) | ❌ | ✅ Three.js | Static image |
| PC + VR headset | N/A | ✅ SteamVR / Oculus Link | ✅ Three.js | Static image |
| PC (no headset) | N/A | ❌ | ✅ Three.js | Static image |
| Quest browser | ✅ Passthrough | ✅ Native | ✅ | N/A |
| visionOS Safari | ❌ AR | ✅ VR | ✅ | Static image |

### Fallback Principles

1. **Feature detection, not user-agent sniffing**: Use `navigator.xr.isSessionSupported()`. Never use UA string.
2. **Silent degradation**: Don't render buttons for unsupported features. No error messages.
3. **iOS AR special path**: Use `<model-viewer>`'s `ios-src` attribute to provide .usdz file. AR Quick Look handles it automatically.
4. **QR code bridge**: When on desktop and mobile AR is available, show a QR code for the same URL. Let users switch devices seamlessly.

### WebXR-Specific Constraints

- Controller mapping varies by device — use `XRInputSource.profiles` array for identification, never hardcode
- Hand tracking is the default input on Android XR, secondary on Quest
- DOM UI is inaccessible during WebXR immersive sessions — all UI must be rendered in 3D space
- Frame rate targets: ≥72fps (Quest), ≥90fps (PC VR)

### Mobile AR UX Flow (WebXR / AR Quick Look)

#### Platform Split

```
iOS Safari:
├── WebXR immersive-ar: NOT supported (as of 2026)
├── AR Quick Look: Supported via .usdz files
├── <model-viewer ar> → Automatically invokes AR Quick Look
└── Alternative: App Clip-based WebAR (e.g., Variant Launch)

Android Chrome:
├── WebXR immersive-ar: Supported (ARCore-based)
├── Scene Viewer: Supported via .glb files
├── <model-viewer ar> → Scene Viewer or WebXR session
└── Hand tracking: Default input on Android XR devices
```

#### AR Placement Flow

```
1. User taps "View in AR" button
   └── Device support check (silent — no errors)

2. Camera activates + surface detection guidance
   └── "Point at a floor or table surface"
   └── Reticle visualizes detected surface

3. Tap to place object
   └── Immediate placement confirmation animation
   └── Object anchors to surface

4. Post-placement manipulation
   └── One-finger drag: reposition
   └── Two-finger pinch: resize
   └── Two-finger rotate: rotate object
   └── Reset button: clear placement

5. Exit AR session
   └── Explicit "Close" button (always visible)
   └── Back gesture also exits
```

#### Mobile AR Core Rules

- **One-handed operation**: User holds phone with one hand while viewing AR. Minimize complex two-handed gestures.
- **Short session design**: Mobile AR sessions last 30 seconds to 2 minutes. Don't design for long engagement.
- **Camera permission explanation**: Explain *why* camera access is needed before the permission prompt ("Camera is needed to place the product in your space").
- **Lighting guidance**: "Use in a well-lit environment" — prevents tracking failure in dark spaces.
- **True-to-scale**: 3D model must match real product at 1:1 scale. This is the core value proposition of product AR.

---

## Design Process for XR

### Adapted Workflow

1. **Define spatial intent**: What spatial advantage does this provide over a 2D screen? If none → don't force XR.
2. **Map comfort zones**: Sketch content placement in comfort zones before any visual design.
3. **Storyboard spatially**: Draw from user's perspective (first-person POV), not top-down.
4. **Prototype in-headset early**: 2D mockups cannot validate spatial comfort. Test in device ASAP.
5. **Test with diverse users**: Spatial comfort varies widely. Test with motion-sensitive users, seated users, users with different physical capabilities.

### Tools

| Tool | Use |
|------|-----|
| Figma + visionOS Design Kit | 2D wireframes for spatial panels |
| Spline | Browser-based 3D interface prototyping |
| Reality Composer Pro | visionOS-native 3D content authoring |
| Unity + MRTK | Cross-platform XR prototyping |
| Gravity Sketch | Freeform 3D ideation in VR |
| ShapesXR | Collaborative spatial prototyping in VR |

---

## Anti-Patterns (XR Specific)

| Anti-Pattern | Why It Fails | Alternative |
|-------------|-------------|-------------|
| Replicating flat 2D screens in 3D space | No spatial benefit ("floating monitors") | Redesign for depth, spatial grouping, environment |
| UI behind user or requiring full body rotation | Core functions become physically demanding | Keep all primary UI within ±30° FOV |
| Camera shake, forced camera motion, head-bob | Direct cybersickness trigger | Never move camera without user initiation |
| Smooth locomotion as default | Most users will feel sick | Ship teleport + snap turn as defaults |
| Gaze-triggered actions without confirmation | Accidental activation from natural looking | Require gaze + explicit confirm (pinch, dwell) |
| Too many simultaneous floating panels | Cognitive + visual overload | Start minimal, progressive disclosure |
| Ignoring physical room constraints (AR) | Content clips through walls/furniture | Respect room boundaries, test in real spaces |
| Sustained arm-raised positioning | "Gorilla arm" fatigue within minutes | Move frequent interactions to comfortable zones |
| 2D scrolling for long lists in XR | Doesn't leverage spatial dimension | Spatial pagination or world-anchored list layout |
| Building XR for novelty | 3D for 3D's sake, no functional benefit | Only use XR when it solves a problem 2D cannot |

---

## When NOT to Use XR

Not every experience benefits from spatial design. Stay in 2D (or 3D viewport) if:

- The task is primarily text-heavy (reading, writing, data entry)
- Speed of execution matters more than spatial understanding
- The user base lacks access to XR hardware
- The spatial dimension adds no functional value
- A 3D viewport (screen-mediated) achieves the same goal without requiring a headset

**Rule**: XR should solve a problem that a screen cannot. The embodied, spatial nature of the interaction must provide genuine value — not just novelty.

---

## XR UX Validation Checklist

### Comfort & Safety
- [ ] All interactive content within 1.25–2m comfort zone
- [ ] Primary content within ±30° horizontal FOV
- [ ] No camera movement without user initiation
- [ ] Frame rate ≥90Hz maintained (test under load)
- [ ] Latency <20ms verified
- [ ] Horizon stays stable — no world tilt
- [ ] Comfort settings provided (locomotion, turning, seated mode)
- [ ] Comfort rating honestly assigned (Comfortable / Moderate / Intense)

### Input & Interaction
- [ ] At least 2 input modalities for all core functions
- [ ] Gestures are simple, brief, and low-effort for frequent actions
- [ ] No sustained arm-raised positions required for core tasks
- [ ] Modality switching possible at any time
- [ ] Eye-gaze targets ≥60pt with ≥8pt spacing

### Spatial UI
- [ ] UI anchoring type appropriate for each element
- [ ] Curved panels used for content wider than 60° FOV
- [ ] Depth used consistently for hierarchy (no large random jumps)
- [ ] Audio feedback from spatial position of interaction
- [ ] State transitions use spatial equivalents (not 2D slide/fade)

### Platform
- [ ] Tested on target platform(s) in-headset (not simulator only)
- [ ] Tested seated AND standing
- [ ] Platform design language followed (visionOS glass, Quest panels, Android XR Material)
- [ ] Content doesn't extend past physical room boundaries (AR)

### Accessibility
- [ ] All interactions reachable from seated position
- [ ] Core functions work with one hand
- [ ] `prefers-reduced-motion` respected
- [ ] Visual indicators for all audio cues
- [ ] No precision-dependent core functions
- [ ] Adjustable gaze dwell timers
- [ ] No strobing or high-contrast flickering in peripheral vision

### WebXR (if applicable)
- [ ] Feature detection used (not UA sniffing)
- [ ] Buttons hidden for unsupported features (no error messages)
- [ ] iOS AR Quick Look path (.usdz) provided
- [ ] QR code bridge for desktop → mobile AR
- [ ] DOM UI fully replaced with in-space 3D UI during immersive session
- [ ] Controller mapping uses XRInputSource.profiles (not hardcoded)
- [ ] Graceful fallback to inline 3D if immersive session unavailable
