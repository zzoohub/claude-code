# Reanimated 3 Patterns

## Core Concepts

### Shared Values

The foundation of all Reanimated animation. Lives on the UI thread.

```tsx
import { useSharedValue } from 'react-native-reanimated';

// Shared value — NOT React state
const opacity = useSharedValue(0);
const translateY = useSharedValue(40);

// Modify directly — triggers animation on UI thread
opacity.value = withTiming(1, { duration: 600 });

// NEVER do this:
// const [opacity, setOpacity] = useState(0); ← JS thread, will jank
```

### Animated Styles

Connect shared values to view properties.

```tsx
import Animated, { useAnimatedStyle } from 'react-native-reanimated';

function Card() {
  const opacity = useSharedValue(0);
  const translateY = useSharedValue(40);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ translateY: translateY.value }],
  }));

  // Must use Animated.View, not View
  return <Animated.View style={[styles.card, animatedStyle]} />;
}
```

### Derived Values

Compute values from other shared values — runs on UI thread.

```tsx
import { useDerivedValue, interpolate } from 'react-native-reanimated';

const scrollY = useSharedValue(0);

// Derives automatically when scrollY changes
const headerOpacity = useDerivedValue(() =>
  interpolate(scrollY.value, [0, 200], [1, 0])
);

const headerScale = useDerivedValue(() =>
  interpolate(scrollY.value, [0, 200], [1, 0.8])
);
```

---

## Animation Primitives

### withTiming (duration-based)

```tsx
import { withTiming, Easing } from 'react-native-reanimated';

// Simple
opacity.value = withTiming(1, { duration: 600 });

// With easing
translateY.value = withTiming(0, {
  duration: 600,
  easing: Easing.out(Easing.cubic), // equivalent to CSS ease-out
});

// Common easing mappings from web:
// CSS ease-out      → Easing.out(Easing.cubic)
// CSS ease-in-out   → Easing.inOut(Easing.cubic)
// power4.out (GSAP) → Easing.bezier(0.22, 1, 0.36, 1)
// power2.out (GSAP) → Easing.out(Easing.quad)
```

### withSpring (physics-based)

```tsx
import { withSpring } from 'react-native-reanimated';

// Default spring
translateY.value = withSpring(0);

// Tuned spring
translateY.value = withSpring(0, {
  damping: 15,        // Higher = less oscillation
  stiffness: 150,     // Higher = faster
  mass: 1,            // Higher = slower, heavier feel
});

// Common presets:
// Snappy button:  { damping: 15, stiffness: 200 }
// Gentle settle:  { damping: 20, stiffness: 100 }
// Bouncy:         { damping: 8,  stiffness: 150 }
// Heavy drag:     { damping: 20, stiffness: 80, mass: 1.5 }
```

### withSequence (chained)

```tsx
import { withSequence, withTiming, withSpring } from 'react-native-reanimated';

// Bounce effect: scale up → overshoot → settle
scale.value = withSequence(
  withTiming(1.2, { duration: 150 }),
  withSpring(1, { damping: 12, stiffness: 200 })
);

// Shake effect
translateX.value = withSequence(
  withTiming(-10, { duration: 50 }),
  withTiming(10, { duration: 50 }),
  withTiming(-5, { duration: 50 }),
  withTiming(5, { duration: 50 }),
  withTiming(0, { duration: 50 })
);
```

### withDelay

```tsx
import { withDelay, withTiming } from 'react-native-reanimated';

// Delay before animation starts
opacity.value = withDelay(300, withTiming(1, { duration: 600 }));
```

### withRepeat

```tsx
import { withRepeat, withTiming, withSequence } from 'react-native-reanimated';

// Infinite pulse
scale.value = withRepeat(
  withSequence(
    withTiming(1.1, { duration: 1000 }),
    withTiming(1, { duration: 1000 })
  ),
  -1,   // -1 = infinite
  true  // reverse
);

// Spin
rotation.value = withRepeat(
  withTiming(360, { duration: 2000, easing: Easing.linear }),
  -1,    // infinite
  false  // don't reverse (continuous spin)
);
```

---

## Scroll Animations

### Scroll Handler

```tsx
import Animated, {
  useSharedValue,
  useAnimatedScrollHandler,
} from 'react-native-reanimated';

function ScrollScreen() {
  const scrollY = useSharedValue(0);

  const scrollHandler = useAnimatedScrollHandler({
    onScroll: (event) => {
      scrollY.value = event.contentOffset.y;
    },
    // Optional:
    onBeginDrag: (event) => { /* user starts scrolling */ },
    onEndDrag: (event) => { /* user lifts finger */ },
    onMomentumBegin: (event) => { /* momentum scroll starts */ },
    onMomentumEnd: (event) => { /* momentum scroll ends */ },
  });

  return (
    <Animated.ScrollView
      onScroll={scrollHandler}
      scrollEventThrottle={16}  // ALWAYS set this
    >
      {/* content */}
    </Animated.ScrollView>
  );
}
```

### Parallax Header

```tsx
function ParallaxScreen() {
  const scrollY = useSharedValue(0);
  const HEADER_HEIGHT = 300;

  const scrollHandler = useAnimatedScrollHandler({
    onScroll: (e) => { scrollY.value = e.contentOffset.y; },
  });

  const imageStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateY: interpolate(
          scrollY.value,
          [-HEADER_HEIGHT, 0, HEADER_HEIGHT],
          [-HEADER_HEIGHT / 2, 0, HEADER_HEIGHT * 0.5],
          Extrapolation.CLAMP
        ),
      },
      {
        scale: interpolate(
          scrollY.value,
          [-HEADER_HEIGHT, 0],
          [2, 1],
          Extrapolation.CLAMP
        ),
      },
    ],
  }));

  const titleStyle = useAnimatedStyle(() => ({
    opacity: interpolate(scrollY.value, [0, HEADER_HEIGHT * 0.6], [1, 0], Extrapolation.CLAMP),
    transform: [
      { translateY: interpolate(scrollY.value, [0, HEADER_HEIGHT], [0, -50], Extrapolation.CLAMP) },
    ],
  }));

  return (
    <View style={{ flex: 1 }}>
      <Animated.Image source={heroImage} style={[styles.headerImage, imageStyle]} />
      <Animated.Text style={[styles.title, titleStyle]}>Title</Animated.Text>
      <Animated.ScrollView onScroll={scrollHandler} scrollEventThrottle={16}>
        <View style={{ height: HEADER_HEIGHT }} /> {/* spacer */}
        {/* content */}
      </Animated.ScrollView>
    </View>
  );
}
```

### Shrinking/Sticky Header

```tsx
function StickyHeader({ scrollY }: { scrollY: SharedValue<number> }) {
  const EXPANDED = 120;
  const COLLAPSED = 60;

  const headerStyle = useAnimatedStyle(() => ({
    height: interpolate(
      scrollY.value,
      [0, EXPANDED - COLLAPSED],
      [EXPANDED, COLLAPSED],
      Extrapolation.CLAMP
    ),
  }));

  const titleScale = useAnimatedStyle(() => ({
    transform: [
      {
        scale: interpolate(
          scrollY.value,
          [0, EXPANDED - COLLAPSED],
          [1, 0.7],
          Extrapolation.CLAMP
        ),
      },
    ],
  }));

  return (
    <Animated.View style={[styles.header, headerStyle]}>
      <Animated.Text style={[styles.headerTitle, titleScale]}>
        Header
      </Animated.Text>
    </Animated.View>
  );
}
```

### Scroll-Triggered Reveal (Stagger)

Unlike web GSAP's ScrollTrigger, Reanimated doesn't have a built-in "trigger when element enters viewport." Manual approach:

```tsx
import { useSharedValue, useAnimatedStyle, withDelay, withTiming, runOnJS } from 'react-native-reanimated';

function StaggerList({ items }) {
  const revealed = useSharedValue(false);

  // Trigger on mount or when scrolled into view
  useEffect(() => {
    revealed.value = true;
  }, []);

  return (
    <View>
      {items.map((item, index) => (
        <StaggerItem key={item.id} index={index} revealed={revealed} />
      ))}
    </View>
  );
}

function StaggerItem({ index, revealed }) {
  const style = useAnimatedStyle(() => {
    if (!revealed.value) {
      return { opacity: 0, transform: [{ translateY: 30 }] };
    }
    return {
      opacity: withDelay(index * 80, withTiming(1, { duration: 400 })),
      transform: [
        { translateY: withDelay(index * 80, withSpring(0, { damping: 15, stiffness: 150 })) },
      ],
    };
  });

  return <Animated.View style={[styles.item, style]}>{/* content */}</Animated.View>;
}
```

For true viewport-triggered reveals, use `onLayout` + scroll position comparison, or a library like `react-native-intersection-observer`.

---

## Layout Animations

### Entering / Exiting

```tsx
import Animated, {
  FadeIn,
  FadeOut,
  SlideInRight,
  SlideOutLeft,
  ZoomIn,
  BounceIn,
  Layout,
} from 'react-native-reanimated';

// Built-in presets
<Animated.View entering={FadeIn.duration(400)} exiting={FadeOut.duration(200)}>
  <Text>Appears with fade</Text>
</Animated.View>

// Chained modifiers
<Animated.View
  entering={SlideInRight.duration(300).springify().damping(15)}
  exiting={SlideOutLeft.duration(200)}
>
  <Text>Slides in from right</Text>
</Animated.View>

// With delay (for stagger effect)
<Animated.View entering={FadeIn.delay(index * 100).duration(400)}>
  <Text>Item {index}</Text>
</Animated.View>

// Layout animation — animates position changes when siblings add/remove
<Animated.View layout={Layout.springify()}>
  <Text>Smoothly repositions when list changes</Text>
</Animated.View>
```

### Custom Entering Animation

```tsx
import { EntryAnimationsValues, withTiming, withSpring } from 'react-native-reanimated';

const CustomEntering = (values: EntryAnimationsValues) => {
  'worklet';
  return {
    initialValues: {
      opacity: 0,
      transform: [{ translateY: 50 }, { scale: 0.9 }],
    },
    animations: {
      opacity: withTiming(1, { duration: 400 }),
      transform: [
        { translateY: withSpring(0, { damping: 15 }) },
        { scale: withSpring(1, { damping: 12 }) },
      ],
    },
  };
};

<Animated.View entering={CustomEntering}>
  {/* content */}
</Animated.View>
```

---

## Callbacks and JS Thread Communication

### runOnJS — Call JS functions from worklets

```tsx
import { runOnJS } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';

// Haptic feedback on threshold
const scrollHandler = useAnimatedScrollHandler({
  onScroll: (e) => {
    scrollY.value = e.contentOffset.y;

    if (e.contentOffset.y > 200 && !headerCollapsed.value) {
      headerCollapsed.value = true;
      runOnJS(Haptics.impactAsync)(Haptics.ImpactFeedbackStyle.Light);
    }
  },
});
```

### Animated Reactions

```tsx
import { useAnimatedReaction, runOnJS } from 'react-native-reanimated';

// Watch a shared value and react
useAnimatedReaction(
  () => scrollY.value,
  (currentValue, previousValue) => {
    if (currentValue > 300 && previousValue <= 300) {
      runOnJS(setShowBackToTop)(true);
    }
    if (currentValue <= 300 && previousValue > 300) {
      runOnJS(setShowBackToTop)(false);
    }
  }
);
```

---

## Shared Element Transitions

### Between Screens (React Navigation)

```tsx
import Animated, { SharedTransition, withSpring } from 'react-native-reanimated';

// List screen
function ProductCard({ product, onPress }) {
  return (
    <Pressable onPress={onPress}>
      <Animated.Image
        source={{ uri: product.image }}
        sharedTransitionTag={`product-${product.id}`}
        style={styles.thumbnail}
      />
    </Pressable>
  );
}

// Detail screen
function ProductDetail({ product }) {
  return (
    <Animated.Image
      source={{ uri: product.image }}
      sharedTransitionTag={`product-${product.id}`}
      style={styles.heroImage}
    />
  );
}
```

`sharedTransitionTag` must match between screens. The framework handles the morphing animation.

### Custom Shared Transition

```tsx
const customTransition = SharedTransition.custom((values) => {
  'worklet';
  return {
    width: withSpring(values.targetWidth),
    height: withSpring(values.targetHeight),
    originX: withSpring(values.targetOriginX),
    originY: withSpring(values.targetOriginY),
    borderRadius: withTiming(values.targetBorderRadius || 0, { duration: 300 }),
  };
});

<Animated.Image
  sharedTransitionTag="hero"
  sharedTransitionStyle={customTransition}
  style={styles.image}
/>
```

---

## Common Animation Recipes

### Button Press Feedback

```tsx
function AnimatedButton({ onPress, children }) {
  const scale = useSharedValue(1);

  const style = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const handlePressIn = () => {
    scale.value = withSpring(0.95, { damping: 15, stiffness: 300 });
  };

  const handlePressOut = () => {
    scale.value = withSpring(1, { damping: 10, stiffness: 200 });
  };

  return (
    <Pressable onPress={onPress} onPressIn={handlePressIn} onPressOut={handlePressOut}>
      <Animated.View style={[styles.button, style]}>
        {children}
      </Animated.View>
    </Pressable>
  );
}
```

### Skeleton Loading Shimmer

```tsx
function SkeletonShimmer({ width, height }) {
  const translateX = useSharedValue(-width);

  useEffect(() => {
    translateX.value = withRepeat(
      withTiming(width, { duration: 1200, easing: Easing.linear }),
      -1,
      false
    );
  }, []);

  const shimmerStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
  }));

  return (
    <View style={[{ width, height, borderRadius: 8, backgroundColor: '#e0e0e0', overflow: 'hidden' }]}>
      <Animated.View
        style={[
          {
            width: '60%',
            height: '100%',
            backgroundColor: 'rgba(255,255,255,0.4)',
          },
          shimmerStyle,
        ]}
      />
    </View>
  );
}
```

### Number Counter

```tsx
function AnimatedCounter({ target, duration = 1500 }) {
  const value = useSharedValue(0);
  const [display, setDisplay] = useState('0');

  useEffect(() => {
    value.value = withTiming(target, { duration, easing: Easing.out(Easing.cubic) });
  }, [target]);

  useAnimatedReaction(
    () => Math.round(value.value),
    (current) => {
      runOnJS(setDisplay)(current.toLocaleString());
    }
  );

  return <Text style={styles.counter}>{display}</Text>;
}
```

### Tab Indicator (Animated Position)

```tsx
function TabBar({ tabs, activeIndex }) {
  const indicatorX = useSharedValue(0);
  const indicatorWidth = useSharedValue(0);
  const tabLayouts = useRef([]);

  useEffect(() => {
    const layout = tabLayouts.current[activeIndex];
    if (layout) {
      indicatorX.value = withSpring(layout.x, { damping: 20, stiffness: 200 });
      indicatorWidth.value = withSpring(layout.width, { damping: 20, stiffness: 200 });
    }
  }, [activeIndex]);

  const indicatorStyle = useAnimatedStyle(() => ({
    left: indicatorX.value,
    width: indicatorWidth.value,
  }));

  return (
    <View style={styles.tabBar}>
      {tabs.map((tab, i) => (
        <Pressable
          key={i}
          onLayout={(e) => { tabLayouts.current[i] = e.nativeEvent.layout; }}
          onPress={() => onTabPress(i)}
        >
          <Text>{tab}</Text>
        </Pressable>
      ))}
      <Animated.View style={[styles.indicator, indicatorStyle]} />
    </View>
  );
}
```

---

## Reduced Motion

```tsx
import { ReduceMotion, withTiming, withSpring } from 'react-native-reanimated';

// Per-animation: respects system setting
opacity.value = withTiming(1, {
  duration: 600,
  reduceMotion: ReduceMotion.System,  // instant when reduce motion is on
});

translateY.value = withSpring(0, {
  damping: 15,
  reduceMotion: ReduceMotion.System,
});

// Options:
// ReduceMotion.System  — follows OS setting (recommended)
// ReduceMotion.Always  — always skip animation
// ReduceMotion.Never   — never skip (use sparingly, only for essential feedback)
```

Always use `ReduceMotion.System` unless the animation provides essential functional feedback (like a toggle state indicator).
