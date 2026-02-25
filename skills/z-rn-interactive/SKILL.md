---
name: z-rn-interactive
description: |
  Advanced motion and visual effects for React Native using Reanimated 3 (primary), react-native-skia, and Gesture Handler.
  Use when: adding animations to RN screens, building gesture-driven interactions, creating scroll-linked animations, implementing shared element transitions, building custom GPU-rendered graphics, creating loading/intro sequences, adding haptic feedback with animation, building interactive charts or visualizations, or any task involving "make the app feel alive", "smooth animation", "gesture", "swipe interaction", "parallax", "shared element transition", "custom shader", "drawing", "canvas graphics" in a React Native context.
  Do not use for: web animations (use z-web-interactive), component structure, navigation flow decisions (use z-ux-design).
  Workflow: z-ux-design (flow) → z-design-system (tokens) → expo-app-design:building-native-ui (implementation) → z-interactive-engineer agent → **this skill** (apply interactive).
references:
  - references/reanimated-patterns.md
  - references/skia-patterns.md
  - references/gesture-patterns.md
  - references/performance.md
---

# React Native Motion

## Philosophy

Motion on mobile serves fundamentally different goals than on web. While the cognitive foundations are the same (attention guidance, working memory limits, physics-based expectation), the **mode of interaction changes everything**.

**Mobile = Efficiency & Immediacy.** Users are task-focused, often in physical motion themselves, and have no hover. Every motion decision must answer:

1. **Does this provide instant feedback?** Touch demands immediate response. A 200ms delay after a tap feels broken. Springs (not timing) are the default because they respond to interruption naturally.
2. **Does this communicate a spatial relationship?** Where did this screen come from? Where does this element go? Shared element transitions and directional slides answer these questions.
3. **Does this respect the user's momentum?** Mobile users scroll fast. Animations that block, hijack, or slow down navigation create frustration, not delight.

The agent's emotional register matrix applies identically — a banking app still needs "Calm / Trust" motion. But the **vocabulary** changes: hover effects become tap feedback, scroll pinning becomes parallax headers, cinematic reveals become fast spring entrances.

## Technology Stack

Three libraries. No overlap. Requires **Reanimated 3.x+** (3.6+ recommended for `useReducedMotion`, `useAnimatedKeyboard`; Reanimated 4.x renames `useScrollViewOffset` → `useScrollOffset`), **react-native-gesture-handler 2.x+**, and **@shopify/react-native-skia 0.1.x+**. Always verify APIs against your installed versions — these libraries evolve quickly.

| Library | Role | Thread |
|---------|------|--------|
| **Reanimated 3** | All view animation: timing, spring, decay, scroll, layout | UI thread (worklet) |
| **react-native-skia** | GPU-rendered graphics: shaders, particles, custom drawing | GPU via Skia |
| **Gesture Handler** | Touch input: tap, pan, pinch, rotation, fling | UI thread (native) |

**Reanimated 3 is the primary animation engine.** It runs on the UI thread via JSI worklets — animations never touch the JS thread, so they stay at 60/120fps even when JS is busy.

### Why This Stack

| Alternative | Why Not |
|------------|---------|
| `Animated` (built-in) | Legacy. JS thread or limited native driver. Reanimated supersedes it completely. |
| `LayoutAnimation` (built-in) | No fine control. Can't target specific elements. Unpredictable. |
| Moti | Wrapper around Reanimated. Adds abstraction without adding capability. |
| Lottie | No runtime interactivity. Good for pre-made designer animations — splash screens, empty states, success confirmations, onboarding illustrations. Use it when a designer provides a Lottie file; don't rebuild those with Reanimated/Skia. |

## Installation

```bash
npx expo install react-native-reanimated react-native-gesture-handler @shopify/react-native-skia
```

```js
// babel.config.js
module.exports = {
  plugins: ['react-native-reanimated/plugin'], // Must be last
};
```

```tsx
// app/_layout.tsx (Expo Router) or App.tsx
import { GestureHandlerRootView } from 'react-native-gesture-handler';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      {/* app content */}
    </GestureHandlerRootView>
  );
}
```

## Decision Flowchart

```
Need animation?
│
├─ View property animation (opacity, transform, color)?
│  └─ → Reanimated: useAnimatedStyle + withTiming/withSpring
│
├─ Scroll-linked?
│  └─ → Reanimated: useAnimatedScrollHandler + interpolate
│
├─ Momentum / fling (throw, coast, carousel)?
│  └─ → Reanimated: withDecay (velocity-based deceleration)
│
├─ Need to constrain animation range?
│  └─ → Reanimated: withClamp({ min, max }, animation)
│
├─ Gesture-driven (drag, pinch, swipe)?
│  └─ → Gesture Handler + Reanimated (compose)
│
├─ Keyboard-aware animation?
│  └─ → Reanimated: useAnimatedKeyboard
│
├─ Layout animation (list reorder, enter/exit)?
│  └─ → Reanimated: entering/exiting props or LayoutAnimation
│
├─ Shared element transition (between screens)?
│  └─ → Reanimated: SharedTransition (RN 0.74+) or react-native-shared-element
│
├─ Custom drawing (charts, paths, gradients)?
│  └─ → Skia Canvas
│
├─ GPU shader effect (blur, noise, distortion)?
│  └─ → Skia RuntimeEffect
│
├─ Particle system / complex visual?
│  └─ → Skia Canvas with Reanimated shared values
│
└─ Pre-made animation from designer?
   └─ → Lottie (not in this skill, but acceptable)
```

## Transition Semantics (Mobile)

Same framework as the agent's Transition Semantics, adapted for React Native navigation:

| Pattern | RN Implementation | When |
|---------|-------------------|------|
| **Container Transform** | Reanimated `SharedTransition` between screens — card morphs into detail | List item → detail screen |
| **Shared Axis** | Screen slides L/R or U/D (stack default `slideFromRight`, tab `slideFromBottom`) | Tab switch, wizard steps, onboarding |
| **Fade Through** | `FadeIn` / `FadeOut` entering/exiting on screen container | Unrelated screens (settings → profile) |
| **Fade** | Simple opacity `withTiming` | Modal overlay, toast, tooltip |

The pattern communicates **what just happened spatially**. A Shared Axis slide says "you moved sideways to a peer." A Container Transform says "this expanded from that item." Don't default to fade for everything — it strips spatial meaning from navigation.

```tsx
// Container Transform example — card expands into detail
import { SharedTransition, withSpring } from 'react-native-reanimated';

const customTransition = SharedTransition.custom((values) => {
  'worklet';
  return {
    width: withSpring(values.targetWidth, { damping: 15 }),
    height: withSpring(values.targetHeight, { damping: 15 }),
    originX: withSpring(values.targetOriginX, { damping: 15 }),
    originY: withSpring(values.targetOriginY, { damping: 15 }),
  };
});

// On both screens: same sharedTransitionTag
<Animated.Image sharedTransitionTag={`product-${id}`} sharedTransitionStyle={customTransition} />
```

## Core Patterns

### Why Springs Are the Default on Mobile

On web, `withTiming` (duration-based) is common. On mobile, **prefer `withSpring`** because:

- **Interruptible**: User taps mid-animation → spring naturally adjusts. Timing-based animation either ignores the tap or jumps.
- **Physics-based expectation**: Springs feel like physical objects (cognitive foundations — the brain expects deceleration). A card that springs back after a swipe feels "real."
- **No duration guessing**: Springs resolve naturally based on damping/stiffness. No need to pick arbitrary 300ms durations.
- **Touch feedback**: Spring response within ~16ms (1 frame) after touch = "instant" feel. Timing with easing starts slowly (ease-in) which feels laggy on touch.

Use `withTiming` only for: opacity fades, color transitions, progress bars — cases where physics doesn't apply.

### 1. Basic Animation (Reanimated)

```tsx
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSpring,
  Easing,
} from 'react-native-reanimated';

function FadeInCard() {
  const opacity = useSharedValue(0);
  const translateY = useSharedValue(40);

  useEffect(() => {
    opacity.value = withTiming(1, { duration: 600, easing: Easing.out(Easing.cubic) });
    translateY.value = withSpring(0, { damping: 15, stiffness: 150 });
  }, []);

  const style = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  return <Animated.View style={[styles.card, style]}>{/* content */}</Animated.View>;
}
```

→ Full patterns: `references/reanimated-patterns.md`

### 2. Scroll-Linked Animation (Reanimated)

```tsx
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  useAnimatedScrollHandler,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';

function ParallaxHeader() {
  const scrollY = useSharedValue(0);

  const scrollHandler = useAnimatedScrollHandler({
    onScroll: (e) => { scrollY.value = e.contentOffset.y; },
  });

  const headerStyle = useAnimatedStyle(() => ({
    transform: [
      { translateY: interpolate(scrollY.value, [0, 200], [0, -100], Extrapolation.CLAMP) },
      { scale: interpolate(scrollY.value, [0, 200], [1, 0.8], Extrapolation.CLAMP) },
    ],
    opacity: interpolate(scrollY.value, [0, 200], [1, 0], Extrapolation.CLAMP),
  }));

  return (
    <>
      <Animated.View style={[styles.header, headerStyle]}>
        <HeroImage />
      </Animated.View>
      <Animated.ScrollView onScroll={scrollHandler} scrollEventThrottle={16}>
        {/* content */}
      </Animated.ScrollView>
    </>
  );
}
```

→ More scroll patterns: `references/reanimated-patterns.md`

### 3. Gesture-Driven (Gesture Handler + Reanimated)

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';

function DraggableCard() {
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const scale = useSharedValue(1);

  const pan = Gesture.Pan()
    .onStart(() => { scale.value = withSpring(1.05); })
    .onUpdate((e) => {
      translateX.value = e.translationX;
      translateY.value = e.translationY;
    })
    .onEnd(() => {
      translateX.value = withSpring(0);
      translateY.value = withSpring(0);
      scale.value = withSpring(1);
    });

  const style = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
      { scale: scale.value },
    ],
  }));

  return (
    <GestureDetector gesture={pan}>
      <Animated.View style={[styles.card, style]}>{/* content */}</Animated.View>
    </GestureDetector>
  );
}
```

→ Swipe-to-dismiss, pinch-to-zoom, rotation: `references/gesture-patterns.md`

### 4. GPU Graphics (Skia)

```tsx
import { Canvas, Circle, LinearGradient, vec, BlurMask } from '@shopify/react-native-skia';

function GlowOrb() {
  return (
    <Canvas style={{ width: 200, height: 200 }}>
      <Circle cx={100} cy={100} r={60}>
        <LinearGradient
          start={vec(40, 40)}
          end={vec(160, 160)}
          colors={['#6366f1', '#ec4899']}
        />
        <BlurMask blur={20} style="solid" />
      </Circle>
    </Canvas>
  );
}
```

→ Shaders, animated paths, particles: `references/skia-patterns.md`

### 5. Skia + Reanimated (Animated GPU Graphics)

```tsx
import { Canvas, Circle, vec } from '@shopify/react-native-skia';
import { useSharedValue, useDerivedValue, withRepeat, withTiming } from 'react-native-reanimated';

function PulsingOrb() {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withRepeat(withTiming(1, { duration: 2000 }), -1, true);
  }, []);

  const radius = useDerivedValue(() => 40 + progress.value * 20);

  return (
    <Canvas style={{ width: 200, height: 200 }}>
      <Circle cx={100} cy={100} r={radius} color="#6366f1" />
    </Canvas>
  );
}
```

Reanimated shared values drive Skia properties directly — both run off the JS thread.

### 6. Entering/Exiting Animations (Reanimated Layout)

```tsx
import Animated, { FadeIn, FadeOut, SlideInRight, Layout } from 'react-native-reanimated';

function TodoItem({ item, onRemove }) {
  return (
    <Animated.View
      entering={SlideInRight.duration(300).springify()}
      exiting={FadeOut.duration(200)}
      layout={Layout.springify()}
      style={styles.item}
    >
      <Text>{item.text}</Text>
    </Animated.View>
  );
}
```

→ Custom entering/exiting, list animations: `references/reanimated-patterns.md`

## Integration with Existing Skills

### With z-design-system
- Use motion tokens (durations, easing curves) as defaults
- Map CSS easing to Reanimated: `Easing.bezier(0.22, 1, 0.36, 1)` for power4.out equivalent

### With expo-app-design:building-native-ui
- Never modify component internals
- Wrap with `Animated.View` or compose gesture handlers on top
- Keep animation logic in dedicated hooks (`useCardAnimation`, `useScrollParallax`)

### With z-interactive-engineer
- Agent reads this skill as reference for RN implementation
- Direction decisions (what, when, emotion) come from the agent's own judgment
- Patterns here are the technical recipes the agent uses

## Accessibility — Non-Negotiable

Every animation must handle reduced motion. Reanimated provides two built-in approaches — use these instead of rolling your own with `AccessibilityInfo`.

**Approach 1: Per-animation flag (simplest)**

```tsx
import { ReduceMotion, withTiming, withSpring } from 'react-native-reanimated';

// Animations resolve instantly when the OS reduce-motion setting is on
opacity.value = withTiming(1, { duration: 600, reduceMotion: ReduceMotion.System });
translateY.value = withSpring(0, { damping: 15, reduceMotion: ReduceMotion.System });
```

**Approach 2: `useReducedMotion` hook (for conditional logic)**

```tsx
import { useReducedMotion } from 'react-native-reanimated';

function AnimatedCard() {
  const reduceMotion = useReducedMotion(); // returns boolean

  // Use it to pick different entering animations or skip effects entirely
  const entering = reduceMotion ? FadeIn : BounceIn;

  return <Animated.View entering={entering}>{/* content */}</Animated.View>;
}
```

`useReducedMotion` reads the OS setting synchronously at startup. Prefer `ReduceMotion.System` per-animation when you just want animations to skip; use the hook when you need to conditionally render entirely different UI or pick alternative animation strategies.

## Performance Rules

1. **Never animate on JS thread** — all animation via Reanimated worklets or Skia
2. **`scrollEventThrottle={16}`** — always set on ScrollView when using scroll handlers
3. **Avoid `useAnimatedStyle` recalculation storms** — keep derived computations in `useDerivedValue`
4. **Skia canvas size** — don't make full-screen Skia canvases unless necessary
5. **Shared values, not state** — `useSharedValue` for animation, `useState` for UI logic. Never mix.
6. **Dispose Skia resources** — textures, images, fonts need cleanup
7. **Test on real devices** — simulators don't reflect real GPU/CPU constraints

→ Full guide: `references/performance.md`

## Mobile Anti-Patterns

| Anti-Pattern | Why It's Bad on Mobile | The Fix |
|-------------|----------------------|--------|
| **Porting web hover to mobile** | Mobile has no hover. Making interactions tap-only but with hover-designed timing feels wrong — taps need instant spring feedback, not slow ease-in-out. | Rethink for touch: magnetic hover → spring tap scale, hover reveal → always visible, cursor effect → N/A. |
| **Scroll hijacking** | Mobile users scroll with momentum and muscle memory. Hijacking scroll feels like the phone is broken. | Never hijack scroll on mobile. Use scroll-linked parallax or sticky headers instead. |
| **Long intro animations** | Mobile users are impatient and often multi-tasking. A 3s intro means they've switched apps. | Content visible within 500ms. Any intro animation must be skippable or under 1s. |
| **Full-screen Skia canvas** | GPU-intensive, drains battery, heats device, drops frames on mid-range hardware. | Keep Skia canvases sized to what they render. Use device tier detection to simplify on low-end. |
| **Timing-based everything** | `withTiming` can't be interrupted mid-flight. User taps during animation → unresponsive feel. | Default to `withSpring` for anything touch-related. `withTiming` only for opacity, color, progress. |
| **Stagger > 6 items in a list** | On mobile screens, users see 4–6 items at once. Staggering 20 items means watching a waterfall for seconds. | Stagger the visible items only (first 4–6), then batch-reveal the rest instantly. |

## Measuring Impact (Mobile)

- **Gesture success rate**: Do users complete swipe/drag interactions? Low completion = animation too complex or gesture zone too small.
- **App store ratings**: Motion quality directly correlates with "feels premium" reviews.
- **Scroll depth**: Same as web — target 70%+ on marketing screens.
- **Perceived performance**: Does the app *feel* fast? Skeleton loaders + spring entrances > spinners.
- **Battery impact**: Profile animation-heavy screens with Xcode Instruments / Android Profiler. Motion should not measurably increase battery drain.
- **Core metrics unchanged**: Task completion time, error rate, and conversion should never degrade from adding motion. If they do, you've over-animated.

## File Organization

```
components/
├── motion/
│   ├── animated-card.tsx
│   ├── parallax-header.tsx
│   ├── stagger-list.tsx
│   ├── swipe-to-dismiss.tsx
│   └── shared-transition.tsx
├── canvas/
│   ├── gradient-orb.tsx
│   ├── particle-field.tsx
│   ├── animated-chart.tsx
│   └── shader-background.tsx
hooks/
├── use-reduced-motion.ts
├── use-scroll-animation.ts
├── use-spring-entry.ts
└── use-gesture-drag.ts
```

## Quick Reference

| Want | Use | Reference |
|------|-----|-----------|
| Fade/slide in | Reanimated withTiming/withSpring | `reanimated-patterns.md` |
| Momentum / fling coast | Reanimated withDecay | `reanimated-patterns.md` |
| Clamp animation range | Reanimated withClamp | `reanimated-patterns.md` |
| Keyboard-aware layout | Reanimated useAnimatedKeyboard | `reanimated-patterns.md` |
| Simple scroll offset | Reanimated useScrollOffset | `reanimated-patterns.md` |
| Scroll parallax | Reanimated useAnimatedScrollHandler | `reanimated-patterns.md` |
| Sticky/shrinking header | Reanimated interpolate on scrollY | `reanimated-patterns.md` |
| List enter/exit | Reanimated entering/exiting | `reanimated-patterns.md` |
| Shared element (screen transition) | Reanimated SharedTransition | `reanimated-patterns.md` |
| Swipe to dismiss | Gesture Handler Pan + Reanimated | `gesture-patterns.md` |
| Pinch to zoom | Gesture Handler Pinch + Reanimated | `gesture-patterns.md` |
| Bottom sheet | Gesture Handler Pan + Reanimated | `gesture-patterns.md` |
| Card flip / rotation | Gesture Handler + Reanimated | `gesture-patterns.md` |
| Custom gradient / glow | Skia Canvas | `skia-patterns.md` |
| GPU shader (noise, wave) | Skia RuntimeEffect | `skia-patterns.md` |
| Animated path drawing | Skia Path + Reanimated | `skia-patterns.md` |
| Particle system | Skia + Reanimated shared values | `skia-patterns.md` |
| Many sprites efficiently | Skia Atlas + useRSXformBuffer | `skia-patterns.md` |
| Chart / data viz | Skia Path + Reanimated | `skia-patterns.md` |
| Haptic feedback with animation | Reanimated runOnJS + Haptics | `reanimated-patterns.md` |
| Reduced motion | Reanimated ReduceMotion.System / useReducedMotion | Accessibility above |
| Container Transform (screen) | Reanimated SharedTransition | Transition Semantics above |
| Shared Axis (tab/step) | Stack `slideFromRight` / tab animation | Transition Semantics above |
| Fade Through (unrelated screens) | Reanimated FadeIn/FadeOut | Transition Semantics above |
| Spring tap feedback | `withSpring` on `scale` | Why Springs section above |
