# React Native Motion — Performance Guide

## Threading Model

React Native has three threads. Understanding this is the key to 60fps.

```
JS Thread          ─── React logic, state, business logic
UI Thread          ─── Native view updates, layout
GPU Thread         ─── Rendering pixels to screen
```

**The goal**: keep animations off the JS thread entirely.

| Library | Runs On | Why It's Fast |
|---------|---------|--------------|
| Reanimated 3 | UI thread (worklets via JSI) | Animations never touch JS thread |
| Gesture Handler | UI thread (native modules) | Gesture recognition is native |
| Skia | GPU thread (Metal / Vulkan) | Direct GPU rendering |
| Animated (legacy) | JS thread or partial native driver | JS thread = jank risk |

---

## Rule 1: Never Animate on the JS Thread

### Bad: useState for animation

```tsx
// ❌ Runs on JS thread — will drop frames
const [position, setPosition] = useState(0);
useEffect(() => {
  const interval = setInterval(() => setPosition(p => p + 1), 16);
  return () => clearInterval(interval);
}, []);

<View style={{ transform: [{ translateX: position }] }} />
```

### Good: useSharedValue + useAnimatedStyle

```tsx
// ✅ Runs on UI thread — smooth 60fps
const position = useSharedValue(0);
useEffect(() => {
  position.value = withTiming(100, { duration: 1000 });
}, []);

const style = useAnimatedStyle(() => ({
  transform: [{ translateX: position.value }],
}));

<Animated.View style={style} />
```

---

## Rule 2: scrollEventThrottle={16}

Always set this on ScrollView when using scroll handlers:

```tsx
// ❌ Default throttle is 0 — fires every frame irregularly
<ScrollView onScroll={handler} />

// ✅ 16ms = 60fps — consistent scroll events
<Animated.ScrollView onScroll={handler} scrollEventThrottle={16} />
```

Without this, scroll-linked animations will stutter.

---

## Rule 3: Minimize runOnJS Calls

`runOnJS` bridges from UI thread back to JS thread. Every call is a thread hop.

```tsx
// ❌ Bad: runOnJS on every scroll frame
const scrollHandler = useAnimatedScrollHandler({
  onScroll: (e) => {
    runOnJS(setScrollPosition)(e.contentOffset.y); // 60 calls/second to JS thread
  },
});

// ✅ Good: use shared values, only runOnJS for discrete events
const scrollHandler = useAnimatedScrollHandler({
  onScroll: (e) => {
    scrollY.value = e.contentOffset.y; // stays on UI thread

    // Only hop to JS for threshold events
    if (e.contentOffset.y > 200 && !collapsed.value) {
      collapsed.value = true;
      runOnJS(hapticFeedback)(); // one-time call, acceptable
    }
  },
});
```

---

## Rule 4: useDerivedValue Over Computed Styles

```tsx
// ❌ Recalculates every frame inside useAnimatedStyle
const style = useAnimatedStyle(() => ({
  opacity: interpolate(scrollY.value, [0, 200], [1, 0]),
  transform: [
    { scale: interpolate(scrollY.value, [0, 200], [1, 0.8]) },
    { translateY: interpolate(scrollY.value, [0, 200], [0, -50]) },
  ],
}));

// ✅ Derive once, reuse — cleaner and cacheable
const opacity = useDerivedValue(() =>
  interpolate(scrollY.value, [0, 200], [1, 0])
);
const scale = useDerivedValue(() =>
  interpolate(scrollY.value, [0, 200], [1, 0.8])
);
const translateY = useDerivedValue(() =>
  interpolate(scrollY.value, [0, 200], [0, -50])
);

const style = useAnimatedStyle(() => ({
  opacity: opacity.value,
  transform: [
    { scale: scale.value },
    { translateY: translateY.value },
  ],
}));
```

For simple cases the difference is negligible. For complex animations with many derived values, pre-computing with `useDerivedValue` is cleaner.

---

## Rule 5: Skia Canvas Sizing

```tsx
// ❌ Full-screen Skia canvas for a small decoration
<Canvas style={{ width: Dimensions.get('window').width, height: Dimensions.get('window').height }}>
  <Circle cx={50} cy={50} r={20} color="blue" />
</Canvas>

// ✅ Size canvas to content
<Canvas style={{ width: 100, height: 100 }}>
  <Circle cx={50} cy={50} r={20} color="blue" />
</Canvas>
```

Skia renders the entire canvas area every frame. Smaller canvas = less GPU work.

---

## Rule 6: Reuse Skia Objects

```tsx
// ❌ Creates new path every render
function Chart({ data }) {
  const path = Skia.Path.Make(); // NEW object every render
  data.forEach((d, i) => { /* build path */ });

  return <Canvas><Path path={path} /></Canvas>;
}

// ✅ Memoize Skia objects
function Chart({ data }) {
  const path = useMemo(() => {
    const p = Skia.Path.Make();
    data.forEach((d, i) => { /* build path */ });
    return p;
  }, [data]);

  return <Canvas><Path path={path} /></Canvas>;
}
```

---

## Rule 7: Reduce Motion

```tsx
import { ReduceMotion } from 'react-native-reanimated';

// System-aware — resolves instantly when reduce motion is on
opacity.value = withTiming(1, {
  duration: 600,
  reduceMotion: ReduceMotion.System,
});
```

For custom hooks:

```tsx
import { AccessibilityInfo } from 'react-native';

function useReducedMotion() {
  const [reduced, setReduced] = useState(false);

  useEffect(() => {
    AccessibilityInfo.isReduceMotionEnabled().then(setReduced);
    const sub = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduced);
    return () => sub.remove();
  }, []);

  return reduced;
}
```

---

## Rule 8: Test on Real Devices

Simulators don't reflect real performance:

| Factor | Simulator | Real Device |
|--------|----------|-------------|
| CPU | Desktop CPU (fast) | Mobile CPU (slower) |
| GPU | Desktop GPU | Mobile GPU (constrained) |
| Memory | Abundant | Limited (especially old devices) |
| Thermal throttling | None | Significant after 30s+ of heavy animation |

Always test animations on:
- Oldest supported device (e.g., iPhone 11 / Pixel 4a)
- After thermal warmup (scroll for 30+ seconds)

---

## Device Tier Detection

Adjust animation complexity based on device capability.

```tsx
import { Platform } from 'react-native';

function useDeviceTier(): 'high' | 'mid' | 'low' {
  // Simple heuristic — refine based on your user base
  if (Platform.OS === 'ios') {
    // iOS devices are generally capable
    return 'high';
  }

  // Android: check available memory or processor count
  const cores = typeof navigator !== 'undefined' ? navigator.hardwareConcurrency : 4;
  if (cores >= 8) return 'high';
  if (cores >= 4) return 'mid';
  return 'low';
}

// Usage
function ParticleBackground() {
  const tier = useDeviceTier();

  const particleCount = {
    high: 100,
    mid: 50,
    low: 20,
  }[tier];

  return <ParticleField count={particleCount} />;
}
```

---

## Performance Checklist

### Animation
- [ ] All animations use Reanimated shared values (not useState)
- [ ] `scrollEventThrottle={16}` on all animated ScrollViews
- [ ] `runOnJS` only for discrete events, never per-frame
- [ ] Springs use reasonable damping (not infinite oscillation)
- [ ] Complex derived values use `useDerivedValue`
- [ ] `ReduceMotion.System` set on all non-essential animations

### Skia
- [ ] Canvas sized to content, not full-screen unless needed
- [ ] Skia objects (Path, etc.) wrapped in `useMemo`
- [ ] Shader uniforms use `useDerivedValue` (not recalculated in render)
- [ ] Particle count scaled by device tier
- [ ] Images loaded with null state handling

### Gestures
- [ ] Gesture handlers run on UI thread (no JS thread overhead)
- [ ] Complex gesture compositions tested on low-end devices
- [ ] Haptics use `runOnJS` sparingly (threshold-based, not continuous)

### General
- [ ] Tested on real device (not just simulator)
- [ ] Tested after thermal warmup (30s+ of scrolling)
- [ ] No layout thrashing (avoid animating width/height — use transform)
- [ ] FlatList used for long animated lists (not ScrollView + map)
- [ ] Console.log removed from worklets (causes JS thread bridge)

---

## Common Jank Causes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Scroll animation stutters | Missing `scrollEventThrottle` | Add `scrollEventThrottle={16}` |
| Animation freezes during fetch | Animating on JS thread | Switch to Reanimated shared values |
| Gesture feels laggy | Gesture handler on JS thread | Use `react-native-gesture-handler` Gesture API (v2) |
| Skia canvas flickers | Re-creating Skia objects | Memoize with `useMemo` |
| App gets hot / battery drains | Full-screen Skia with complex shader | Reduce canvas size, simplify shader, add frame limiting |
| List scroll jank with animations | Too many animated components | Use `FlatList` with `windowSize` tuning, reduce animation complexity |
| Spring never settles | Damping too low | Increase damping or use `withTiming` instead |
