# Typography System

## Font Stack

```json
{
  "fontFamily": {
    "sans":  { "$value": "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif", "$type": "fontFamily" },
    "mono":  { "$value": "'JetBrains Mono', 'Fira Code', 'SF Mono', monospace", "$type": "fontFamily" }
  }
}
```

Inter is the default recommendation — it has optical sizing, variable weight support, and excellent screen readability. Replace with project's brand font; the scale below stays the same.

## Type Scale

Named styles, not raw sizes. Every text element in the UI maps to one of these.

```json
{
  "typography": {
    "display": {
      "$value": { "fontFamily": "{fontFamily.sans}", "fontSize": "30px", "lineHeight": "36px", "fontWeight": "{fontWeight.bold}", "letterSpacing": "-0.025em" },
      "$type": "typography"
    },
    "heading": {
      "lg": {
        "$value": { "fontFamily": "{fontFamily.sans}", "fontSize": "24px", "lineHeight": "32px", "fontWeight": "{fontWeight.semibold}", "letterSpacing": "-0.02em" },
        "$type": "typography"
      },
      "md": {
        "$value": { "fontFamily": "{fontFamily.sans}", "fontSize": "20px", "lineHeight": "28px", "fontWeight": "{fontWeight.semibold}", "letterSpacing": "-0.015em" },
        "$type": "typography"
      },
      "sm": {
        "$value": { "fontFamily": "{fontFamily.sans}", "fontSize": "16px", "lineHeight": "24px", "fontWeight": "{fontWeight.semibold}", "letterSpacing": "-0.01em" },
        "$type": "typography"
      }
    },
    "body": {
      "lg": {
        "$value": { "fontFamily": "{fontFamily.sans}", "fontSize": "18px", "lineHeight": "28px", "fontWeight": "{fontWeight.normal}", "letterSpacing": "0" },
        "$type": "typography"
      },
      "md": {
        "$value": { "fontFamily": "{fontFamily.sans}", "fontSize": "16px", "lineHeight": "24px", "fontWeight": "{fontWeight.normal}", "letterSpacing": "0" },
        "$type": "typography"
      },
      "sm": {
        "$value": { "fontFamily": "{fontFamily.sans}", "fontSize": "14px", "lineHeight": "20px", "fontWeight": "{fontWeight.normal}", "letterSpacing": "0" },
        "$type": "typography"
      }
    },
    "caption": {
      "$value": { "fontFamily": "{fontFamily.sans}", "fontSize": "12px", "lineHeight": "16px", "fontWeight": "{fontWeight.medium}", "letterSpacing": "0.02em" },
      "$type": "typography"
    },
    "code": {
      "$value": { "fontFamily": "{fontFamily.mono}", "fontSize": "14px", "lineHeight": "20px", "fontWeight": "{fontWeight.normal}", "letterSpacing": "0" },
      "$type": "typography"
    }
  }
}
```

## Responsive Typography

Larger screens get slightly bigger display/heading sizes. Body text stays the same — 16px is readable everywhere.

### Web (CSS clamp)

```css
:root {
  --typography-display-fontSize: clamp(24px, 4vw, 30px);
  --typography-heading-lg-fontSize: clamp(20px, 3vw, 24px);
  /* body sizes stay fixed */
}
```

### React Native

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

## Usage Principle

If you're setting a `fontSize` that isn't from the type scale, stop and ask: does the scale need a new entry, or does an existing entry actually fit?

Extend the scale when a legitimate new use case appears (e.g., pricing display, stat counter). Don't create one-off sizes for margin cases.
