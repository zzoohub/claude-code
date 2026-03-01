# Project Structure

Two project types: **3D-only** (fullscreen canvas, no or minimal 2D pages) and **2D + 3D** (2D web pages coexisting with 3D experiences).

---

## Web 3D / WebXR (3D-Only)

3D/XR-only applications. No or minimal 2D web pages.

### Base Structure
```
src/
├── app/                        # App shell & routing (framework-specific, internals vary)
│   └── ...                     #   Rule: imports downward only. Nothing below imports app/.
│
├── scene/                      # 3D world (R3F components)
│   ├── canvas.tsx              # WebGPU detect → WebGL fallback
│   ├── objects/
│   ├── environments/           # Lighting, skybox, post-processing
│   ├── cameras/
│   ├── materials/
│   │   ├── create-material.ts  # Factory: (type, renderer) → Material
│   │   └── *.ts                # Each file handles its own WebGPU/WebGL branch
│   ├── hooks/                  # Scene-level hooks (add ecs/, physics/ with engine)
│   └── helpers/
│
├── hud/                        # Shared HUD components
│   ├── controls/               # Slider, Toggle, Button (mesh + HTML adaptive)
│   ├── overlays/               # Labels, indicators
│   └── panels/                 # Grouped control panels
│
├── xr/                         # WebXR (omit if not needed)
│   ├── session.tsx
│   ├── controllers/
│   ├── interactions/
│   └── spaces/
│
└── shared/                     # Referenced by all layers above
    ├── ui/                     # DOM overlay outside Canvas (settings modal, loading screen)
    ├── api/                    # HTTP client, interceptors, base URL
    ├── lib/                    # Utilities, helpers
    ├── hooks/
    ├── stores/                 # Zustand — UI/meta (theme, modal, prefs)
    ├── types/
    ├── constants/
    └── assets/                 # glTF, textures, audio
```

Each folder exposes public API via `index.ts` barrel only. No cross-import within same layer.

### Extensions (add only when triggered)
```
+ engine/                       ← Never imports React
│   ├── ecs/                    # Koota — frame loop state (position, velocity, AI)
│   │   ├── components/         #   Pure data definitions
│   │   ├── systems/            #   Pure logic (stateless)
│   │   ├── queries/
│   │   ├── prefabs/
│   │   └── world.ts
│   ├── ports/
│   ├── adapters/
│   │   └── rapier/             # Physics → ECS sync (no React)
│   ├── physics/                ← Imperative Rapier WASM (graduate from @react-three/rapier)
│   └── shaders/                # TSL / GLSL
│
+ scene/hooks/ecs/              ← Add with engine/ (inside existing scene/hooks/)
+ scene/hooks/physics/          ← Add with engine/ (inside existing scene/hooks/)
│
+ domains/                      ← 2+ independent scenes/modes
│   └── [domain-name]/
│       ├── index.tsx           #   Domain entry point
│       ├── use-cases/          #   Domain-specific business logic
│       ├── systems/            #   Domain-specific ECS systems
│       ├── stores/             #   Domain-scoped state
│       ├── hud/                #   Domain-specific HUD elements
│       └── config.ts           #   Domain parameters, constraints
│
+ networking/                   ← Multiplayer or real-time sync
+ content/                      ← External data injected into 3D scene
│
+ workers/
│   └── compute-worker.ts      # Imports bindings from wasm-out/
│
+ crates/                       ← Rust source (project root, Cargo workspace)
│   └── compute/src/
+ wasm-out/                     ← Build artifacts only (project root, gitignored)
```

### Dependency Direction
```
Top-level:

  ┌─────────────────────────────────────────────────────┐
  │  app/              ← framework-specific shell        │
  │    ↓                                                │
  │  domains/          ← composes scene + engine        │
  │    ↓                                                │
  │  scene/  ─reads→  engine/                           │
  │    ↓                 ↓                              │
  │  hud/                                               │
  │    ↓                                                │
  │  shared/           ← referenced by all above        │
  └─────────────────────────────────────────────────────┘

Cross-links (→ means "depends on"):

  xr/           → scene/
  networking/   → engine/
  workers/      → engine/

Bridges:

  scene/hooks/ecs/     → engine/ecs/      React reads ECS (not the reverse)
  engine/adapters/     → engine/ecs/      Physics syncs into ECS (no React)
  domains/stores/      → scene/hooks/     Domain Zustand reads engine via bridge

State ownership:

  Zustand  shared/stores/         UI/meta (theme, modal, prefs)
  Zustand  domains/[name]/stores/ Domain-scoped (editor mode, tool selection)
  Koota    engine/ecs/            Simulation (position, velocity, AI)
```

### When to Add Each Layer

| Layer | Trigger | Omit when |
|-------|---------|-----------|
| `xr/` | WebXR support needed | No XR |
| `hud/` | In-scene control UI needed | No HUD (e.g., background 3D) |
| `engine/` | ECS, physics, or custom shaders needed | Simple 3D rendering only |
| `domains/` | Independent areas with custom logic/state | Single scene or config-driven variants |
| `networking/` | Multiplayer or real-time sync | Single user |
| `workers/` | CPU-bound computation offload | Main thread sufficient |
| `crates/` | Rust → WASM custom computation | JS/TS sufficient |

---

## Web 2D + 3D / WebXR

Extends the 3D structure above with a `site/` layer for 2D web pages. The 3D layer is wrapped in `experience/` to separate it from `site/`.

- `site/` — 2D layer (FSD). Pure web pages, design system.
- `experience/` — 3D layer. Wraps scene/, hud/, xr/ from Web 3D structure above.
- `engine/` — Framework-agnostic pure logic. Koota ECS, Rapier physics, TSL shaders. Never imports React.
- `domains/` — Independent area composition. Composes experience + engine; may reference shared/.
- `shared/` — Global shared. Referenced by all layers.

**Core rule: `site/` and `experience/` NEVER import each other.** Cross-layer data flows through `shared/` stores.

### Base Structure
```
src/
├── app/                          # App shell & routing (framework-specific)
│   └── ...                       #   Routes to site/ (2D pages) or domains/ (3D experiences)
│
├── site/                         # 2D layer (FSD)
│   ├── views/                    #   Page compositions (landing, dashboard)
│   ├── widgets/                  #   Composite blocks (Header, Footer, Card)
│   ├── features/                 #   User interactions (auth, theme-toggle, i18n-switcher)
│   ├── entities/                 #   Business entities (user, product, order)
│   └── shared/
│       ├── ui/                   #   Design system
│       ├── api/                  #   2D-specific API utilities
│       ├── hooks/                #   DOM hooks
│       └── lib/                  #   2D utilities
│
├── experience/                   # 3D layer (R3F + Three.js)
│   ├── canvas/                   #   WebGPURenderer → WebGLRenderer fallback
│   ├── scene/
│   │   ├── objects/              #   Reusable R3F components
│   │   ├── environments/         #   Lighting, skybox, post-processing
│   │   ├── cameras/              #   OrbitControls, etc. (Drei)
│   │   ├── materials/            #   TSL Node Materials (WebGPU/WebGL branches)
│   │   ├── hooks/                #   Scene-level hooks (add ecs/, physics/ with engine)
│   │   └── helpers/
│   ├── hud/                      #   Shared HUD components
│   │   ├── controls/             #   Slider, Toggle, Button (mesh + HTML adaptive)
│   │   ├── overlays/             #   Labels, indicators
│   │   └── panels/               #   Grouped control panels
│   ├── xr/                       #   @react-three/xr
│   │   ├── session.tsx
│   │   ├── controllers/
│   │   ├── interactions/
│   │   └── spaces/
│   └── shared/
│       ├── hooks/                #   R3F hooks
│       ├── lib/                  #   Three.js utilities
│       └── assets/               #   glTF, KTX2 textures, audio (shared/assets/ in 3D-only)
│
└── shared/                       # Global shared (referenced by all layers)
    ├── ui/                       #   Cross-layer UI primitives (loading, error boundary)
    ├── api/                      #   HTTP client, interceptors, base URL
    ├── lib/                      #   Utilities, helpers
    ├── hooks/
    ├── stores/                   #   Cross-layer state (auth, prefs, etc.)
    │   └── ...                   #     Rule: never imports site/, experience/, engine/, domains/
    ├── types/                    #   Cross-layer types (User, Config, etc.)
    └── constants/
```

### Store Scoping Guide

| Store location | Scope | Example |
|----------------|-------|---------|
| `shared/stores/` | Cross-layer state used by both site/ and experience/ | auth, user, language, theme |
| `domains/[name]/stores/` | Domain-scoped state for a specific domain | editor mode, tool selection, active params |
| `site/shared/` | 2D-only state | form drafts, table sort/filter |
| `experience/shared/` | 3D-only state | camera mode, render quality |
| `engine/ecs/` | Simulation state (Koota) | position, velocity, forces |

### Extensions (add only when triggered)
```
+ engine/                         ← Simulation/game logic. Never imports React
│   ├── ecs/                      #   Koota — frame loop state (position, velocity, AI)
│   │   ├── components/           #     Pure data definitions
│   │   ├── systems/              #     Pure logic (stateless)
│   │   ├── queries/
│   │   ├── prefabs/
│   │   └── world.ts
│   ├── ports/
│   ├── adapters/
│   │   └── rapier/               #   Rapier WASM → ECS sync (no React)
│   ├── physics/                  ←   Imperative Rapier (graduate from @react-three/rapier)
│   └── shaders/                  #   TSL / GLSL
│
+ experience/scene/hooks/ecs/     ← Add with engine/ (inside existing scene/hooks/)
+ experience/scene/hooks/physics/ ← Add with engine/ (inside existing scene/hooks/)
│
+ domains/                        ← 2+ independent areas with custom logic/state
│   └── [domain-name]/
│       ├── index.tsx             #   Domain entry point (composes scene + engine + hud)
│       ├── use-cases/            #   Domain-specific business logic
│       ├── systems/              #   Domain-specific ECS systems
│       ├── stores/               #   Domain-scoped state
│       ├── hud/                  #   Domain-specific HUD elements
│       └── config.ts             #   Domain parameters, constraints
│
+ networking/                     ← Multiplayer or real-time sync
+ content/                        ← External data injected into 3D scene
│
+ workers/
│   └── compute-worker.ts        #   Imports bindings from wasm-out/
│
+ crates/                         ← Rust source (project root, Cargo workspace)
│   └── compute/src/
+ wasm-out/                       ← Build artifacts only (project root, gitignored)
```

### Dependency Direction
```
Top-level:

  ┌──────────────────────────────────────────────────────────┐
  │  app/              ← routing shell                        │
  │    ↓                                                     │
  │  domains/          ← composes experience + engine        │
  │    ↓                                                     │
  │  experience/  ─reads→  engine/                           │
  │    ↓                     ↓                               │
  │  shared/           ← referenced by all above             │
  │                                                          │
  │  app/ → site/ → shared/  (independent 2D branch)         │
  │  site/ ✕ experience/     (NEVER import each other)       │
  └──────────────────────────────────────────────────────────┘

Within experience/:

  canvas/           ← Renderer setup, Canvas entry point
    ↓
  scene/            ← R3F components
    ↓
  hud/              ← mesh + HTML HUD components
    ↓
  experience/shared/

Cross-links (→ means "depends on"):

  experience/xr/    → experience/scene/
  networking/       → engine/
  workers/          → engine/

Bridges:

  experience/scene/hooks/ecs/   → engine/ecs/    React reads ECS (not the reverse)
  engine/adapters/              → engine/ecs/    External systems sync into ECS
  domains/                      → engine/        Domain composes engine systems
  domains/                      → experience/    Domain composes scene + hud

Cross-layer data (site ↔ experience):

  shared/stores/ carries cross-layer state (auth, user, prefs).
  site/ and experience/ both read from shared/stores/ independently.
  No direct import between site/ and experience/.

State ownership:

  Zustand   shared/stores/              Cross-layer (auth, user, language, theme)
  Zustand   domains/[name]/stores/      Domain-scoped (editor mode, tool selection)
  Zustand   site/shared/                2D-only (form drafts, table state)
  Zustand   experience/shared/          3D-only (camera mode, render quality)
  Koota     engine/ecs/                 Simulation (position, velocity, forces)
```

### When to Add Each Layer

| Layer | Trigger | Omit when |
|-------|---------|-----------|
| `site/` | Has 2D web pages | Pure 3D/XR app (fullscreen canvas) |
| `experience/` | Has 3D content | Pure 2D app |
| `experience/xr/` | WebXR support needed | No XR |
| `experience/hud/` | In-scene control UI needed | No HUD (e.g., background 3D) |
| `engine/` | ECS, physics, or custom shaders needed | Simple 3D rendering only |
| `domains/` | Independent areas with custom logic/state | Single scene or config-driven variants |
| `networking/` | Multiplayer or real-time sync | Single user |
| `workers/` | CPU-bound computation offload | Main thread sufficient |
| `crates/` | Rust → WASM custom computation | JS/TS sufficient |
