# Skia Patterns (react-native-skia)

## When to Use Skia

Skia renders directly on the GPU via Metal (iOS) / Vulkan or OpenGL (Android). Use when:

| Use Skia | Don't Use Skia |
|----------|---------------|
| Custom gradients, blurs, glows | Simple opacity/transform animation (Reanimated) |
| Particle systems | Basic layout animation (Reanimated) |
| Shader effects (noise, wave, distortion) | Standard UI components (React Native Views) |
| Animated path drawing (charts, signatures) | Text animation (Reanimated + Text) |
| Custom masks and clip paths | Image fade/slide (Reanimated + Image) |
| Data visualization | Simple progress bars (Reanimated) |

**Rule**: if you can do it with Reanimated on a standard View, don't use Skia. Skia adds a separate rendering surface.

## Installation

```bash
npx expo install @shopify/react-native-skia
```

## Canvas Basics

```tsx
import { Canvas, Circle, Rect, Line, vec } from '@shopify/react-native-skia';

function BasicShapes() {
  return (
    <Canvas style={{ width: 300, height: 300 }}>
      <Circle cx={150} cy={150} r={80} color="#6366f1" />
      <Rect x={50} y={50} width={100} height={60} color="rgba(236, 72, 153, 0.5)" />
      <Line p1={vec(0, 0)} p2={vec(300, 300)} color="white" strokeWidth={2} style="stroke" />
    </Canvas>
  );
}
```

Canvas size should match the content. Don't make full-screen canvases unless necessary.

---

## Gradients

### Linear Gradient

```tsx
import { Canvas, Rect, LinearGradient, vec } from '@shopify/react-native-skia';

function GradientBackground() {
  return (
    <Canvas style={{ width: '100%', height: 300 }}>
      <Rect x={0} y={0} width={400} height={300}>
        <LinearGradient
          start={vec(0, 0)}
          end={vec(400, 300)}
          colors={['#6366f1', '#ec4899', '#06b6d4']}
          positions={[0, 0.5, 1]}
        />
      </Rect>
    </Canvas>
  );
}
```

### Radial Gradient

```tsx
import { Canvas, Circle, RadialGradient, vec } from '@shopify/react-native-skia';

function GlowOrb() {
  return (
    <Canvas style={{ width: 200, height: 200 }}>
      <Circle cx={100} cy={100} r={80}>
        <RadialGradient
          c={vec(100, 100)}
          r={80}
          colors={['#6366f1', '#6366f100']}
        />
      </Circle>
    </Canvas>
  );
}
```

---

## Blur and Glow

```tsx
import { Canvas, Circle, BlurMask, Group, BackdropBlur, Rect, Fill } from '@shopify/react-native-skia';

// Glow effect
function GlowingCircle() {
  return (
    <Canvas style={{ width: 200, height: 200 }}>
      {/* Glow layer */}
      <Circle cx={100} cy={100} r={50} color="#6366f1" opacity={0.5}>
        <BlurMask blur={25} style="normal" />
      </Circle>
      {/* Solid core */}
      <Circle cx={100} cy={100} r={40} color="#6366f1" />
    </Canvas>
  );
}

// Backdrop blur (glassmorphism)
function FrostedCard() {
  return (
    <Canvas style={{ width: 300, height: 200 }}>
      {/* Background content would be here */}
      <Fill color="rgba(0,0,0,0.1)" />

      {/* Frosted area */}
      <BackdropBlur blur={15} clip={{ x: 20, y: 20, width: 260, height: 160 }}>
        <Rect x={20} y={20} width={260} height={160} color="rgba(255,255,255,0.15)" />
      </BackdropBlur>
    </Canvas>
  );
}
```

---

## Animated Paths (Charts, Drawing)

### Animated Line Chart

```tsx
import { Canvas, Path, Skia } from '@shopify/react-native-skia';
import { useSharedValue, useDerivedValue, withTiming } from 'react-native-reanimated';

function AnimatedChart({ data }) {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withTiming(1, { duration: 1500 });
  }, []);

  const path = useMemo(() => {
    const p = Skia.Path.Make();
    const stepX = 300 / (data.length - 1);

    data.forEach((value, i) => {
      const x = i * stepX;
      const y = 200 - (value / Math.max(...data)) * 180;
      if (i === 0) p.moveTo(x, y);
      else p.lineTo(x, y);
    });

    return p;
  }, [data]);

  const animatedEnd = useDerivedValue(() => progress.value);

  return (
    <Canvas style={{ width: 300, height: 200 }}>
      <Path
        path={path}
        color="#6366f1"
        style="stroke"
        strokeWidth={3}
        strokeCap="round"
        strokeJoin="round"
        start={0}
        end={animatedEnd}
      />
    </Canvas>
  );
}
```

### Animated Circular Progress

```tsx
import { Canvas, Path, Skia } from '@shopify/react-native-skia';
import { useSharedValue, useDerivedValue, withTiming } from 'react-native-reanimated';

function CircularProgress({ percentage }) {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withTiming(percentage / 100, { duration: 1200 });
  }, [percentage]);

  const animatedEnd = useDerivedValue(() => progress.value);

  const path = useMemo(() => {
    const p = Skia.Path.Make();
    const r = 80;
    const cx = 100;
    const cy = 100;
    // Arc from top (270°) going clockwise
    p.addArc({ x: cx - r, y: cy - r, width: r * 2, height: r * 2 }, 270, 360);
    return p;
  }, []);

  return (
    <Canvas style={{ width: 200, height: 200 }}>
      {/* Track */}
      <Path path={path} color="rgba(255,255,255,0.1)" style="stroke" strokeWidth={8} />
      {/* Progress */}
      <Path
        path={path}
        color="#6366f1"
        style="stroke"
        strokeWidth={8}
        strokeCap="round"
        start={0}
        end={animatedEnd}
      />
    </Canvas>
  );
}
```

---

## Skia + Reanimated Integration

Skia and Reanimated share values directly — no bridge overhead.

```tsx
import { Canvas, Circle, vec } from '@shopify/react-native-skia';
import { useSharedValue, useDerivedValue, withRepeat, withTiming } from 'react-native-reanimated';

function PulsingDot() {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withRepeat(
      withTiming(1, { duration: 2000 }),
      -1,
      true
    );
  }, []);

  const radius = useDerivedValue(() => 20 + progress.value * 15);
  const opacity = useDerivedValue(() => 1 - progress.value * 0.5);

  return (
    <Canvas style={{ width: 100, height: 100 }}>
      <Circle cx={50} cy={50} r={radius} color="#6366f1" opacity={opacity} />
    </Canvas>
  );
}
```

### Touch-Reactive Skia

```tsx
import { Canvas, Circle, vec } from '@shopify/react-native-skia';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { useSharedValue, useDerivedValue, withSpring } from 'react-native-reanimated';

function TouchRipple() {
  const touchX = useSharedValue(100);
  const touchY = useSharedValue(100);
  const rippleScale = useSharedValue(0);

  const tap = Gesture.Tap().onStart((e) => {
    touchX.value = e.x;
    touchY.value = e.y;
    rippleScale.value = 0;
    rippleScale.value = withSpring(1, { damping: 10, stiffness: 100 });
  });

  const cx = useDerivedValue(() => touchX.value);
  const cy = useDerivedValue(() => touchY.value);
  const r = useDerivedValue(() => rippleScale.value * 50);
  const opacity = useDerivedValue(() => 1 - rippleScale.value);

  return (
    <GestureDetector gesture={tap}>
      <Canvas style={{ width: 300, height: 300, backgroundColor: '#1a1a2e' }}>
        <Circle cx={cx} cy={cy} r={r} color="#6366f1" opacity={opacity} />
      </Canvas>
    </GestureDetector>
  );
}
```

---

## Shader Effects (RuntimeEffect)

Custom GLSL-like shaders for advanced visual effects.

### Noise / Grain

```tsx
import { Canvas, Rect, Skia, RuntimeEffect, Fill } from '@shopify/react-native-skia';
import { useSharedValue, useDerivedValue, withRepeat, withTiming } from 'react-native-reanimated';

const noiseShader = Skia.RuntimeEffect.Make(`
  uniform float time;
  uniform float2 resolution;

  float random(float2 st) {
    return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
  }

  half4 main(float2 fragCoord) {
    float2 uv = fragCoord / resolution;
    float n = random(uv + time);
    return half4(n, n, n, 0.05);
  }
`)!;

function NoiseOverlay() {
  const time = useSharedValue(0);

  useEffect(() => {
    time.value = withRepeat(
      withTiming(100, { duration: 100000 }),
      -1,
      false
    );
  }, []);

  const uniforms = useDerivedValue(() => ({
    time: time.value,
    resolution: [300, 300],
  }));

  return (
    <Canvas style={{ width: 300, height: 300 }}>
      <Fill>
        <RuntimeEffect source={noiseShader} uniforms={uniforms} />
      </Fill>
    </Canvas>
  );
}
```

### Animated Gradient Mesh

```tsx
const meshShader = Skia.RuntimeEffect.Make(`
  uniform float time;
  uniform float2 resolution;

  half4 main(float2 fragCoord) {
    float2 uv = fragCoord / resolution;

    float r = sin(uv.x * 3.0 + time * 0.3) * 0.5 + 0.5;
    float g = cos(uv.y * 3.0 + time * 0.2) * 0.5 + 0.5;
    float b = sin((uv.x + uv.y) * 2.0 + time * 0.4) * 0.5 + 0.5;

    return half4(r * 0.4, g * 0.2, b * 0.8, 1.0);
  }
`)!;
```

Usage is the same as the noise example — pass a `time` uniform driven by Reanimated.

---

## Particle System

Simple particle field using Skia + Reanimated.

```tsx
import { Canvas, Circle } from '@shopify/react-native-skia';
import { useSharedValue, useDerivedValue, withRepeat, withTiming } from 'react-native-reanimated';

const PARTICLE_COUNT = 50;

function generateParticles() {
  return Array.from({ length: PARTICLE_COUNT }, () => ({
    x: Math.random() * 300,
    y: Math.random() * 300,
    r: 1 + Math.random() * 3,
    speed: 0.2 + Math.random() * 0.5,
    offset: Math.random() * Math.PI * 2,
  }));
}

function ParticleField() {
  const particles = useMemo(generateParticles, []);
  const time = useSharedValue(0);

  useEffect(() => {
    time.value = withRepeat(
      withTiming(Math.PI * 2, { duration: 10000 }),
      -1,
      false
    );
  }, []);

  return (
    <Canvas style={{ width: 300, height: 300 }}>
      {particles.map((p, i) => (
        <AnimatedParticle key={i} particle={p} time={time} />
      ))}
    </Canvas>
  );
}

function AnimatedParticle({ particle, time }) {
  const cx = useDerivedValue(
    () => particle.x + Math.sin(time.value * particle.speed + particle.offset) * 20
  );
  const cy = useDerivedValue(
    () => particle.y + Math.cos(time.value * particle.speed + particle.offset) * 15
  );

  return (
    <Circle cx={cx} cy={cy} r={particle.r} color="rgba(99, 102, 241, 0.6)" />
  );
}
```

> For 50-100 particles this works well. For 500+ particles, use a single shader instead of individual Circle components.

---

## Images in Skia

```tsx
import { Canvas, Image, useImage, Rect, ImageShader } from '@shopify/react-native-skia';

function SkiaImage() {
  const image = useImage(require('./photo.jpg'));

  if (!image) return null;

  return (
    <Canvas style={{ width: 300, height: 200 }}>
      <Image image={image} x={0} y={0} width={300} height={200} fit="cover" />
    </Canvas>
  );
}
```

### Image with Shader Effect

```tsx
import { Canvas, Rect, ImageShader, useImage, RuntimeEffect, Skia } from '@shopify/react-native-skia';

const waveShader = Skia.RuntimeEffect.Make(`
  uniform shader image;
  uniform float time;

  half4 main(float2 fragCoord) {
    float2 uv = fragCoord;
    uv.x += sin(uv.y * 0.05 + time * 2.0) * 5.0;
    return image.eval(uv);
  }
`)!;

function WavyImage() {
  const image = useImage(require('./photo.jpg'));
  const time = useSharedValue(0);

  useEffect(() => {
    time.value = withRepeat(withTiming(10, { duration: 10000 }), -1, false);
  }, []);

  const uniforms = useDerivedValue(() => ({ time: time.value }));

  if (!image) return null;

  return (
    <Canvas style={{ width: 300, height: 200 }}>
      <Rect x={0} y={0} width={300} height={200}>
        <RuntimeEffect source={waveShader} uniforms={uniforms}>
          <ImageShader image={image} fit="cover" rect={{ x: 0, y: 0, width: 300, height: 200 }} />
        </RuntimeEffect>
      </Rect>
    </Canvas>
  );
}
```

---

## Performance Notes

1. **Canvas size matters** — smaller canvas = less GPU work. Don't make 1:1 screen-size canvases unless needed.
2. **Fewer draw calls** — combine shapes where possible. One Path with multiple segments > many Circle components.
3. **Shader complexity** — keep fragment shaders simple. Avoid loops and branching.
4. **Image loading** — `useImage` is async. Always handle null state.
5. **Dispose resources** — Skia objects (Path, Image, RuntimeEffect) should be cleaned up when component unmounts.
6. **Avoid re-creating Skia objects** — use `useMemo` for paths, shaders, etc.
