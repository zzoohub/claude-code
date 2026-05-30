# React Native Typography

## Responsive Typography

```typescript
import { useWindowDimensions } from 'react-native';

function useResponsiveTypography() {
  const { width } = useWindowDimensions();
  const scale = width >= 768 ? 1.1 : 1; // 10% bump on tablets

  return {
    // Math.round avoids fractional fontSize/lineHeight, which can blur text on some RN renderers.
    display: { fontSize: Math.round(30 * scale), lineHeight: Math.round(36 * scale) },
    headingLg: { fontSize: Math.round(24 * scale), lineHeight: Math.round(32 * scale) },
    // body stays at 1x
    bodyMd: { fontSize: 16, lineHeight: 24 },
  };
}
```

## Font Scaling & Units

React Native `fontSize` and `lineHeight` are unitless numbers, not CSS `px`: `fontSize` scales like sp (it respects the OS accessibility font setting), while layout dimensions behave like dp. Two consequences for the type scale:

- **OS font scaling is on by default.** Every `<Text>` is multiplied by the user's accessibility font-size setting unless you opt out. Leave it on for body text (accessibility), but cap display/headings so large settings don't break layout: `<Text maxFontSizeMultiplier={1.3}>`. Use `allowFontScaling={false}` only where it is truly unavoidable.
- **`lineHeight` is an absolute number, not a ratio.** Unlike CSS `line-height: 1.5`, RN `lineHeight: 24` is fixed — it does not track `fontSize` automatically. Recompute it whenever `fontSize` changes (including the responsive bump above) to preserve vertical rhythm.

## Font Loading

React Native requires explicit font registration. Use `expo-font` or link fonts in native config. The type scale values from the design system remain the same — only the loading mechanism differs.
