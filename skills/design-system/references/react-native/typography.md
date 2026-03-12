# React Native Typography

## Responsive Typography

```typescript
import { useWindowDimensions } from 'react-native';

function useResponsiveTypography() {
  const { width } = useWindowDimensions();
  const scale = width >= 768 ? 1.1 : 1; // 10% bump on tablets

  return {
    display: { fontSize: 30 * scale, lineHeight: 36 * scale },
    headingLg: { fontSize: 24 * scale, lineHeight: 32 * scale },
    // body stays at 1x
    bodyMd: { fontSize: 16, lineHeight: 24 },
  };
}
```

## Font Loading

React Native requires explicit font registration. Use `expo-font` or link fonts in native config. The type scale values from the design system remain the same — only the loading mechanism differs.
