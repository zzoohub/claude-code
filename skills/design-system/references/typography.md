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

**Non-Latin scripts:** Inter carries no CJK glyphs — shipping ko/ja/zh means
adding a per-script family to the stack (e.g. `'Inter', 'Pretendard'` for
Korean, `'Noto Sans JP'`/`'Noto Sans SC'` for ja/zh) so CJK doesn't fall to
system default while Latin renders Inter. CJK body text also wants looser
line-height (~1.7× vs the Latin-calibrated values below — dense ideographs
need the air) and no italic styling (CJK fonts don't carry true italics).
Keep the scale's size steps; override `lineHeight` per script via a theme
layer, not per component.

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

Display and heading sizes adapt to the viewport. Body text stays the same — 16px is readable everywhere.

### Web (CSS clamp)

```css
:root {
  --typography-display-fontSize: clamp(24px, 4vw, 30px);
  --typography-heading-lg-fontSize: clamp(20px, 3vw, 24px);
  /* body sizes stay fixed */
}
```

### React Native

> See `references/react-native/typography.md` for responsive typography hook and font loading. (also linked directly from SKILL.md)

> **Cross-platform note:** The two platforms scale type in opposite directions relative to the token. On web, `clamp(24px, 4vw, 30px)` treats the 30px token as the desktop **ceiling** and shrinks toward 24px on small viewports. On React Native, the 30px token is the phone **baseline** and tablets bump it up ~10%. So the same named token does not render at an identical px on every platform/breakpoint — the token defines the reference size, not a fixed rendered size. If you need pixel parity across platforms, pick one convention per token (e.g. treat 30px as the desktop/tablet ceiling everywhere and step phones down).

## Usage Principle

If you're setting a `fontSize` that isn't from the type scale, stop and ask: does the scale need a new entry, or does an existing entry actually fit?

Extend the scale when a legitimate new use case appears (e.g., pricing display, stat counter). Don't create one-off sizes for margin cases.
