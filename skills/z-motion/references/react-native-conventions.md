# React Native Conventions

Patterns, rules, and gotchas for the React Native animation stack (Reanimated 3 + Gesture Handler + Skia).

## Table of Contents

1. [Threading Model](#threading-model)
2. [Springs vs Timing](#springs-vs-timing)
3. [Reanimated Core Pattern](#reanimated-core-pattern)
4. [Gesture + Reanimated Pattern](#gesture--reanimated-pattern)
5. [Gesture Composition](#gesture-composition)
6. [When to Use Skia](#when-to-use-skia)
7. [Skia + Reanimated Integration](#skia--reanimated-integration)
8. [Haptic Feedback](#haptic-feedback)
9. [Layout Animations](#layout-animations)
10. [Shared Element Transitions](#shared-element-transitions)
11. [Performance Rules](#performance-rules)
12. [Reduced Motion](#reduced-motion)
13. [Accessibility](#accessibility)
14. [Common Gotchas](#common-gotchas)

---

## Threading Model

Understanding the three threads is the key to 60fps:

```
JS Thread     -- React logic, state, business logic
UI Thread     -- Native view updates, layout, Reanimated worklets
GPU Thread    -- Rendering pixels, Skia
```

**The goal**: keep animations off the JS thread entirely.

| Library | Runs On | Why It's Fast |
|---------|---------|--------------|
| Reanimated 3 | UI thread (worklets via JSI) | Never touches JS thread |
| Gesture Handler | UI thread (native modules) | Gesture recognition is native |
| Skia | GPU thread | Direct GPU rendering |

## Springs vs Timing

| Use `withSpring` | Use `withTiming` |
|-----------------|-----------------|
| Any touch-triggered animation | Opacity fades |
| Position/transform changes | Color transitions |
| Gesture release (snap back) | Progress bars |
| Interruptible animations | Known-duration sequences |

Springs are interruptible, physics-based, and don't require duration guessing.

Common presets:
- **Snappy button**: `{ damping: 15, stiffness: 200 }`
- **Gentle settle**: `{ damping: 20, stiffness: 100 }`
- **Bouncy**: `{ damping: 8, stiffness: 150 }`
- **Heavy drag**: `{ damping: 20, stiffness: 80, mass: 1.5 }`

## Reanimated Core Pattern

All Reanimated animations follow this structure:

```tsx
const value = useSharedValue(0);           // 1. Shared value (UI thread)
value.value = withSpring(100);             // 2. Animate it

const style = useAnimatedStyle(() => ({    // 3. Connect to style
  transform: [{ translateX: value.value }],
}));

<Animated.View style={style} />            // 4. Use Animated component
```

**Never** use `useState` for animation values -- that runs on JS thread and will jank.

## Gesture + Reanimated Pattern

```tsx
const translateX = useSharedValue(0);

const gesture = Gesture.Pan()
  .onUpdate((e) => { translateX.value = e.translationX; })   // UI thread
  .onEnd(() => { translateX.value = withSpring(0); });        // UI thread

const style = useAnimatedStyle(() => ({
  transform: [{ translateX: translateX.value }],
}));

<GestureDetector gesture={gesture}>
  <Animated.View style={style} />
</GestureDetector>
```

`GestureHandlerRootView` must wrap the app root.

## Gesture Composition

| Method | Behavior | Example |
|--------|----------|---------|
| `Gesture.Simultaneous(a, b)` | Both run at once | Pinch + rotate |
| `Gesture.Exclusive(a, b)` | First match wins | Double tap vs single tap |
| `Gesture.Race(a, b)` | First to activate wins, others cancel | Horizontal vs vertical pan |
| `a.requireExternalGestureToFail(b)` | Sequential -- a fires only if b fails | Single tap after double tap timeout |

## When to Use Skia

| Use Skia | Use Reanimated |
|----------|---------------|
| Custom gradients, blurs, glows | Simple opacity/transform animation |
| Particle systems | Basic layout animation |
| Shader effects (noise, wave) | Standard UI components |
| Animated path drawing (charts) | Text animation |
| Custom masks and clip paths | Image fade/slide |

**Rule**: if Reanimated on a standard View can do it, don't use Skia. Skia adds a separate rendering surface.

## Skia + Reanimated Integration

Skia and Reanimated share values directly -- no bridge overhead:

```tsx
const progress = useSharedValue(0);
const radius = useDerivedValue(() => 20 + progress.value * 15);

<Canvas style={{ width: 100, height: 100 }}>
  <Circle cx={50} cy={50} r={radius} color="#6366f1" />
</Canvas>
```

**Canvas sizing**: size to content, not full-screen. Skia renders the entire canvas area every frame.

**Memoize Skia objects**: Paths, shaders, etc. in `useMemo`. Recreating every render is expensive.

## Haptic Feedback

Pair gestures with haptics at discrete thresholds (not continuously):

```tsx
import * as Haptics from 'expo-haptics';
import { runOnJS } from 'react-native-reanimated';

// Inside gesture handler, at threshold only:
if (Math.abs(e.translationX) > THRESHOLD && !fired.value) {
  fired.value = true;
  runOnJS(Haptics.impactAsync)(Haptics.ImpactFeedbackStyle.Medium);
}
```

Types: Light (subtle tap), Medium (button press), Heavy (significant action), notification (success/warning/error).

## Layout Animations

Built-in entering/exiting presets:

```tsx
<Animated.View entering={FadeIn.duration(400)} exiting={FadeOut.duration(200)} />
```

- Stagger with delay: `FadeIn.delay(index * 100).duration(400)`
- Layout repositioning: `<Animated.View layout={Layout.springify()}>` -- smoothly animates when siblings add/remove
- Custom entering: return `{ initialValues, animations }` from a worklet function

## Shared Element Transitions

**Experimental** -- test thoroughly on your target RN/Expo version. May have bugs on Android or with complex navigation stacks.

```tsx
// List screen
<Animated.Image sharedTransitionTag={`product-${id}`} style={styles.thumb} />

// Detail screen -- same tag
<Animated.Image sharedTransitionTag={`product-${id}`} style={styles.hero} />
```

Tags must be unique per screen. The framework handles morphing.

## Performance Rules

1. **Never animate on JS thread**: use `useSharedValue`, not `useState`
2. **`scrollEventThrottle={16}`**: always set on animated ScrollViews (16ms = 60fps)
3. **Minimize `runOnJS`**: only for discrete events (thresholds, haptics), never per-frame
4. **`useDerivedValue`**: pre-compute complex interpolations, don't repeat in `useAnimatedStyle`
5. **Canvas size**: Skia canvases sized to content, not full-screen
6. **Memoize Skia objects**: `useMemo` for Path, shader, etc.
7. **FlatList for lists**: not ScrollView + map for animated lists
8. **Remove console.log from worklets**: causes JS thread bridge
9. **Test on real devices**: simulators don't reflect thermal throttling or GPU limits
10. **Device tier**: scale particle counts and shader complexity by device capability (use `react-native-device-info` for production)

## Reduced Motion

**Per-animation** (simplest -- add to any animation call):

```tsx
import { ReduceMotion } from 'react-native-reanimated';
opacity.value = withTiming(1, { duration: 600, reduceMotion: ReduceMotion.System });
```

**Conditional logic** (for different UI paths):

```tsx
import { useReducedMotion } from 'react-native-reanimated';
const reduceMotion = useReducedMotion();
const entering = reduceMotion ? FadeIn : BounceIn;
```

Prefer `ReduceMotion.System` per-animation for most cases.

## Accessibility

Every gesture interaction must have a non-gesture fallback:

```tsx
<GestureDetector gesture={swipeGesture}>
  <Animated.View
    accessible={true}
    accessibilityRole="button"
    accessibilityHint="Swipe left to delete, or double tap to select"
    accessibilityActions={[{ name: 'delete', label: 'Delete' }]}
    onAccessibilityAction={(e) => {
      if (e.nativeEvent.actionName === 'delete') onDismiss();
    }}
  />
</GestureDetector>
```

## Common Gotchas

1. **Spring never settles**: damping too low -- increase damping or switch to `withTiming`
2. **Gesture feels laggy**: using old Animated API or JS-thread gesture handler -- switch to Gesture Handler v2 + Reanimated
3. **Skia flickers**: recreating Skia objects every render -- memoize with `useMemo`
4. **App overheats**: full-screen Skia with complex shader -- reduce canvas size, simplify shader
5. **List scroll jank**: too many animated components in ScrollView -- use FlatList with `windowSize` tuning
6. **`withDecay` overshoots bounds**: use `clamp` option or wrap with `withClamp`
7. **Multiple springs on same value**: overlapping springs cause erratic movement -- `cancelAnimation(value)` before starting new one
8. **`useAnimatedKeyboard` on Android**: requires `android:windowSoftInputMode="adjustNothing"` in AndroidManifest.xml
9. **`useScrollViewOffset` renamed**: called `useScrollOffset` in Reanimated 4. Prefer `useScrollOffset` for new code.
