---
name: i18n
description: |
  Internationalization (i18n) architecture and patterns for web and mobile apps.
  Use when: adding multi-language support, setting up translation structure, configuring locale routing, language switching, pluralization, date/number/currency formatting, translation key design. Also use when user says "translate my app", "make it multilingual", "add Korean/English support", "localize my app", or mentions hreflang, locale detection, or language picker.
  Do not use for: general React/Next.js patterns (use vercel-composition-patterns), general mobile patterns (use expo-app-design:building-native-ui), UX copy decisions (use copywriting).
---

# i18n Architecture

**For latest APIs, always verify with context7 before writing code.**

## Platform → Library Matrix

| Platform | Library | Architecture |
|---|---|---|
| Next.js | `next-intl` v4 | ICU MessageFormat — first-class Server Component support, built-in type safety |
| Web (Vite-based) | `@inlang/paraglide-js` v2 | Compiler — translations become tree-shakable functions |
| Expo / React Native | `expo-localization` + `react-i18next` + `i18next` | Runtime — i18next JSON v4 |

Next.js: next-intl v4 provides ICU MessageFormat with first-class Server Component support, built-in type safety via `AppConfig`, and automatic locale routing.

Web (Vite-based): Paraglide JS v2 compiles translation files into tree-shakable functions with automatic TypeScript type safety. Works with SvelteKit, TanStack Start, Astro, React Router, or any Vite-based framework. v2 merged all framework adapters into the core package.

Mobile: react-i18next provides runtime i18n with React Native constraints (no Suspense, localStorage persistence, RTL via I18nManager).

> **Variable syntax differs between platforms.** Web/Next (ICU MessageFormat via next-intl/Paraglide) uses single braces: `Hello, {name}`. Expo/mobile (i18next) uses double braces: `Hello, {{name}}`. Same string sources across web + mobile require either a syntax-conversion build step or maintaining separate message files. Most teams keep them separate.

---

## Core Principles

### 1. Organize Keys by Feature

Use dot-prefixed keys grouped by domain/feature. Features are stable; pages change.

```json
{
  "auth.login.title": "Sign In",
  "auth.login.submit": "Sign In",
  "common.save": "Save",
  "common.cancel": "Cancel"
}
```

For mobile (i18next), same principle with namespace files: `locales/en/auth.json`, `locales/en/common.json`.

**Rules:**
- Key describes purpose, not the text: `auth.login.submit` not `auth.login.signInButton`
- Never concatenate translated strings — full sentences only
- One key per unique UI instance (even if English text is identical — translations may differ)
- `common.*` prefix for truly shared strings only
- 2-3 levels max: `feature.context.purpose`

### 2. Type Safety Is Mandatory

- Web (Paraglide): Automatic — compiler generates typed functions. No configuration needed.
- Mobile (react-i18next): Module augmentation with `CustomTypeOptions`. See `references/expo-i18n.md`.

### 3. Formatting in Code, Not in Strings

Prefer `Intl` formatters in code or Paraglide's built-in message formatters. Keep translation strings clean.
Exception: Pluralization belongs in the translation string.

### 4. Plural Categories by Language

| Language | Plural categories |
|---|---|
| en, es, pt-BR, id | `one`, `other` |
| ja, ko | `other` only |

### 5. Formatting Utilities (Cross-Platform)

Platform-agnostic `Intl` wrappers. Each platform wraps this with its own locale source (Paraglide: `getLocale()`, i18next: `i18n.language`).

```typescript
export function createFormatters(locale: string) {
  return {
    number: (v: number, opts?: Intl.NumberFormatOptions) =>
      new Intl.NumberFormat(locale, opts).format(v),
    currency: (v: number, cur = 'USD') =>
      new Intl.NumberFormat(locale, { style: 'currency', currency: cur }).format(v),
    date: (d: Date, opts?: Intl.DateTimeFormatOptions) =>
      new Intl.DateTimeFormat(locale, { dateStyle: 'medium', ...opts }).format(d),
    list: (items: string[], type: Intl.ListFormatOptions['type'] = 'conjunction') =>
      new Intl.ListFormat(locale, { type, style: 'long' }).format(items),
    duration: (parts: Intl.DurationInput) =>
      new (Intl as any).DurationFormat(locale, { style: 'long' }).format(parts),
    relativeTime: (d: Date) => {
      const diffSec = Math.floor((Date.now() - d.getTime()) / 1000);
      const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });
      if (Math.abs(diffSec) < 60) return rtf.format(-diffSec, 'second');
      if (Math.abs(diffSec) < 3600) return rtf.format(-Math.floor(diffSec / 60), 'minute');
      if (Math.abs(diffSec) < 86400) return rtf.format(-Math.floor(diffSec / 3600), 'hour');
      return rtf.format(-Math.floor(diffSec / 86400), 'day');
    },
    // Word/grapheme segmentation for ja/ko/zh/th (which don't space-separate)
    segment: (text: string, granularity: 'word' | 'sentence' | 'grapheme' = 'word') =>
      Array.from(new Intl.Segmenter(locale, { granularity }).segment(text)),
  };
}
```

`Intl.ListFormat` (all browsers), `Intl.Segmenter` (Chrome 87+, Safari 14.1+, Firefox 125+), `Intl.DurationFormat` (Chrome 129+, Safari 18.4+; polyfill for older).

### 6. RTL / Bidi Support

For locales like ar, he, fa, ur:

- Set `<html lang="..." dir="rtl">` (or `auto`) based on the active locale's `Intl.Locale.prototype.textInfo.direction`
- Use **CSS logical properties** instead of physical: `margin-inline-start` not `margin-left`, `padding-block-end` not `padding-bottom`, `inset-inline` not `left/right`. Tailwind v4 has `ps-*`/`pe-*`/`ms-*`/`me-*` utilities.
- Mirror icons that imply direction (arrows, chevrons) — leave content-meaningful icons alone (clock, search)
- Test with `dir="rtl"` on a few pages even if you don't ship RTL today — catches physical-property bugs early
- React Native: `I18nManager.forceRTL(true)` + `I18nManager.allowRTL(true)`; requires app restart to apply

```ts
function isRtl(locale: string) {
  return new Intl.Locale(locale).textInfo?.direction === 'rtl';
}
```

---

## Platform-Specific Guides

- **Next.js (next-intl v4):** `references/next-i18n.md`
  - Setup, middleware, Server/Client Component usage
  - ICU MessageFormat, type safety via `AppConfig`, static rendering
  - Localized navigation, SEO, language switcher

- **Web / Vite-based (Paraglide JS):** `references/web-i18n.md`
  - Setup (Vite plugin / CLI), message format, SSR middleware
  - URL localization, language switcher, rich text, SEO
  - Framework notes: SvelteKit, TanStack Start, Astro, React Router

- **Expo (react-i18next + i18next):** `references/expo-i18n.md`
  - Device detection, i18next init, JSON v4 pluralization
  - Lazy loading, RTL, language switching, native locale config

---

## Checklist

- [ ] Keys organized by feature (`auth.login.title`)
- [ ] Type-safe keys (Paraglide: automatic, i18next: `CustomTypeOptions`)
- [ ] Pluralization uses platform-native syntax (Paraglide variants / i18next JSON v4)
- [ ] Formatting done in code, not in translation strings
- [ ] Language persistence: cookie (web), localStorage (mobile)
- [ ] SEO: `<html lang>`, `hreflang` alternates (web only)
- [ ] No string concatenation — full sentences always
- [ ] Generated `src/paraglide/` not manually edited (web)
