# Gesture Patterns (react-native-gesture-handler + Reanimated)

## Setup

Gesture Handler must wrap the app root:

```tsx
import { GestureHandlerRootView } from 'react-native-gesture-handler';

export default function App() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      {/* app content */}
    </GestureHandlerRootView>
  );
}
```

## Gesture + Reanimated Pattern

All gestures follow the same structure:

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';

function GestureComponent() {
  // 1. Shared values for animation state
  const translateX = useSharedValue(0);

  // 2. Define gesture with callbacks
  const gesture = Gesture.Pan()
    .onUpdate((e) => { translateX.value = e.translationX; })
    .onEnd(() => { translateX.value = withSpring(0); });

  // 3. Connect to animated style
  const style = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
  }));

  // 4. Wrap with GestureDetector
  return (
    <GestureDetector gesture={gesture}>
      <Animated.View style={style} />
    </GestureDetector>
  );
}
```

---

## Swipe to Dismiss

Classic card/notification swipe-away.

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  runOnJS,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';

const SWIPE_THRESHOLD = 120;

function SwipeToDismiss({ onDismiss, children }) {
  const translateX = useSharedValue(0);
  const opacity = useSharedValue(1);
  const height = useSharedValue(80); // item height

  const pan = Gesture.Pan()
    .activeOffsetX([-10, 10]) // activate after 10px horizontal movement
    .onUpdate((e) => {
      translateX.value = e.translationX;
    })
    .onEnd((e) => {
      if (Math.abs(e.translationX) > SWIPE_THRESHOLD) {
        // Dismiss
        const direction = e.translationX > 0 ? 1 : -1;
        translateX.value = withTiming(direction * 500, { duration: 200 });
        opacity.value = withTiming(0, { duration: 200 });
        height.value = withTiming(0, { duration: 300 }, () => {
          runOnJS(onDismiss)();
        });
      } else {
        // Snap back
        translateX.value = withSpring(0, { damping: 15, stiffness: 200 });
      }
    });

  const cardStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
    opacity: interpolate(
      Math.abs(translateX.value),
      [0, SWIPE_THRESHOLD, SWIPE_THRESHOLD * 2],
      [1, 0.8, 0.5],
      Extrapolation.CLAMP
    ),
  }));

  const containerStyle = useAnimatedStyle(() => ({
    height: height.value,
    opacity: opacity.value,
    overflow: 'hidden',
  }));

  return (
    <Animated.View style={containerStyle}>
      <GestureDetector gesture={pan}>
        <Animated.View style={[styles.card, cardStyle]}>
          {children}
        </Animated.View>
      </GestureDetector>
    </Animated.View>
  );
}
```

---

## Pinch to Zoom (Image Viewer)

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';

function ZoomableImage({ source }) {
  const scale = useSharedValue(1);
  const savedScale = useSharedValue(1);
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const savedTranslateX = useSharedValue(0);
  const savedTranslateY = useSharedValue(0);

  const pinch = Gesture.Pinch()
    .onUpdate((e) => {
      scale.value = savedScale.value * e.scale;
    })
    .onEnd(() => {
      if (scale.value < 1) {
        scale.value = withSpring(1);
        savedScale.value = 1;
        translateX.value = withSpring(0);
        translateY.value = withSpring(0);
        savedTranslateX.value = 0;
        savedTranslateY.value = 0;
      } else if (scale.value > 4) {
        scale.value = withSpring(4);
        savedScale.value = 4;
      } else {
        savedScale.value = scale.value;
      }
    });

  const pan = Gesture.Pan()
    .onUpdate((e) => {
      if (scale.value > 1) {
        translateX.value = savedTranslateX.value + e.translationX;
        translateY.value = savedTranslateY.value + e.translationY;
      }
    })
    .onEnd(() => {
      savedTranslateX.value = translateX.value;
      savedTranslateY.value = translateY.value;
    });

  const doubleTap = Gesture.Tap()
    .numberOfTaps(2)
    .onStart(() => {
      if (scale.value > 1) {
        scale.value = withSpring(1);
        savedScale.value = 1;
        translateX.value = withSpring(0);
        translateY.value = withSpring(0);
        savedTranslateX.value = 0;
        savedTranslateY.value = 0;
      } else {
        scale.value = withSpring(2.5);
        savedScale.value = 2.5;
      }
    });

  // Compose: pinch and pan run simultaneously, double tap is separate
  const composed = Gesture.Simultaneous(pinch, pan);
  const gesture = Gesture.Exclusive(doubleTap, composed);

  const imageStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
      { scale: scale.value },
    ],
  }));

  return (
    <GestureDetector gesture={gesture}>
      <Animated.Image source={source} style={[styles.image, imageStyle]} resizeMode="contain" />
    </GestureDetector>
  );
}
```

---

## Bottom Sheet

Draggable sheet from bottom of screen.

```tsx
import { Dimensions } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  interpolate,
  Extrapolation,
  runOnJS,
} from 'react-native-reanimated';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');
const SNAP_POINTS = {
  collapsed: SCREEN_HEIGHT - 80,   // just handle visible
  half: SCREEN_HEIGHT * 0.5,
  expanded: SCREEN_HEIGHT * 0.1,
};

function BottomSheet({ children }) {
  const translateY = useSharedValue(SNAP_POINTS.collapsed);
  const context = useSharedValue({ y: 0 });

  const pan = Gesture.Pan()
    .onStart(() => {
      context.value = { y: translateY.value };
    })
    .onUpdate((e) => {
      translateY.value = Math.max(
        SNAP_POINTS.expanded,
        context.value.y + e.translationY
      );
    })
    .onEnd((e) => {
      // Snap to closest point based on velocity and position
      const currentY = translateY.value;
      const velocity = e.velocityY;

      if (velocity > 500) {
        // Flick down → collapse
        translateY.value = withSpring(SNAP_POINTS.collapsed, { damping: 20, stiffness: 150 });
      } else if (velocity < -500) {
        // Flick up → expand
        translateY.value = withSpring(SNAP_POINTS.expanded, { damping: 20, stiffness: 150 });
      } else {
        // Snap to nearest
        const distances = Object.values(SNAP_POINTS).map((p) => ({
          point: p,
          distance: Math.abs(currentY - p),
        }));
        const nearest = distances.sort((a, b) => a.distance - b.distance)[0];
        translateY.value = withSpring(nearest.point, { damping: 20, stiffness: 150 });
      }
    });

  const sheetStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
  }));

  const backdropStyle = useAnimatedStyle(() => ({
    opacity: interpolate(
      translateY.value,
      [SNAP_POINTS.expanded, SNAP_POINTS.collapsed],
      [0.5, 0],
      Extrapolation.CLAMP
    ),
    pointerEvents: translateY.value < SNAP_POINTS.collapsed ? 'auto' : 'none',
  }));

  return (
    <>
      <Animated.View style={[styles.backdrop, backdropStyle]} />
      <GestureDetector gesture={pan}>
        <Animated.View style={[styles.sheet, sheetStyle]}>
          <View style={styles.handle} />
          {children}
        </Animated.View>
      </GestureDetector>
    </>
  );
}
```

---

## Card Flip

```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  interpolate,
} from 'react-native-reanimated';

function FlipCard({ front, back }) {
  const rotation = useSharedValue(0);
  const isFlipped = useSharedValue(false);

  const tap = Gesture.Tap().onStart(() => {
    isFlipped.value = !isFlipped.value;
    rotation.value = withSpring(isFlipped.value ? 180 : 0, {
      damping: 15,
      stiffness: 100,
    });
  });

  const frontStyle = useAnimatedStyle(() => ({
    transform: [
      { perspective: 1000 },
      { rotateY: `${rotation.value}deg` },
    ],
    backfaceVisibility: 'hidden',
    opacity: interpolate(rotation.value, [0, 90, 180], [1, 0, 0]),
  }));

  const backStyle = useAnimatedStyle(() => ({
    transform: [
      { perspective: 1000 },
      { rotateY: `${rotation.value + 180}deg` },
    ],
    backfaceVisibility: 'hidden',
    opacity: interpolate(rotation.value, [0, 90, 180], [0, 0, 1]),
  }));

  return (
    <GestureDetector gesture={tap}>
      <View style={styles.flipContainer}>
        <Animated.View style={[styles.flipFace, frontStyle]}>{front}</Animated.View>
        <Animated.View style={[styles.flipFace, styles.flipBack, backStyle]}>{back}</Animated.View>
      </View>
    </GestureDetector>
  );
}
```

---

## Gesture Composition

### Simultaneous (both at once)

```tsx
const pinch = Gesture.Pinch().onUpdate(/* ... */);
const rotate = Gesture.Rotation().onUpdate(/* ... */);

const composed = Gesture.Simultaneous(pinch, rotate);
```

### Exclusive (first match wins)

```tsx
const doubleTap = Gesture.Tap().numberOfTaps(2).onStart(/* ... */);
const singleTap = Gesture.Tap().onStart(/* ... */);

// Double tap takes priority over single tap
const composed = Gesture.Exclusive(doubleTap, singleTap);
```

### Race (first to activate wins, others cancel)

```tsx
const horizontal = Gesture.Pan().activeOffsetX([-10, 10]);
const vertical = Gesture.Pan().activeOffsetY([-10, 10]);

const composed = Gesture.Race(horizontal, vertical);
```

### Requiring Failure (sequential)

```tsx
// Single tap only fires if double tap fails (times out)
const singleTap = Gesture.Tap().requireExternalGestureToFail(doubleTap);
```

---

## Haptic Feedback

Pair gestures with haptics for physical feedback.

```tsx
import * as Haptics from 'expo-haptics';
import { runOnJS } from 'react-native-reanimated';

const pan = Gesture.Pan()
  .onUpdate((e) => {
    translateX.value = e.translationX;

    // Haptic at threshold
    if (Math.abs(e.translationX) > SWIPE_THRESHOLD && !hapticFired.value) {
      hapticFired.value = true;
      runOnJS(Haptics.impactAsync)(Haptics.ImpactFeedbackStyle.Medium);
    }
  })
  .onEnd(() => {
    hapticFired.value = false;
  });
```

Haptic types:
- `ImpactFeedbackStyle.Light` — subtle tap
- `ImpactFeedbackStyle.Medium` — button press
- `ImpactFeedbackStyle.Heavy` — significant action
- `Haptics.notificationAsync(NotificationFeedbackType.Success)` — success/warning/error

---

## Accessibility with Gestures

```tsx
// Always provide accessible alternatives
<GestureDetector gesture={swipeGesture}>
  <Animated.View
    accessible={true}
    accessibilityRole="button"
    accessibilityHint="Swipe left to delete, or double tap to select"
    accessibilityActions={[
      { name: 'delete', label: 'Delete' },
    ]}
    onAccessibilityAction={(event) => {
      if (event.nativeEvent.actionName === 'delete') {
        onDismiss();
      }
    }}
    style={cardStyle}
  >
    {children}
  </Animated.View>
</GestureDetector>
```

Every gesture interaction must have a non-gesture fallback accessible via screen reader.
