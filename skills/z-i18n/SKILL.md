---
name: z-i18n
description: |
  Internationalization (i18n) architecture and patterns for web and mobile apps.
  Use when: adding multi-language support, setting up translation structure, configuring locale routing, language switching, pluralization, date/number/currency formatting, translation key design. Also use when user says "translate my app", "make it multilingual", "add Korean/Japanese support", "localize my app", or mentions hreflang, locale detection, or language picker.
  Do not use for: general React/Next.js patterns (use vercel-composition-patterns), general mobile patterns (use expo-app-design:building-native-ui), UX copy decisions (use z-copywriting).
  Workflow: Use alongside vercel-composition-patterns skill (web) or expo-app-design:building-native-ui skill (mobile).
---

# i18n Architecture

**For latest APIs, always verify with context7 before writing code.**

## Platform → Library Matrix

| Platform | Library | Architecture |
|---|---|---|
| Web (any framework) | `@inlang/paraglide-js` v2 | Compiler — translations become tree-shakable functions |
| Expo / React Native | `expo-localization` + `react-i18next` + `i18next` | Runtime — i18next JSON v4 |

Web: Paraglide JS v2 compiles translation files into tree-shakable functions with automatic TypeScript type safety. Works with Next.js, SvelteKit, TanStack Start, Astro, React Router, or any Vite-based framework. v2 merged all framework adapters into the core package.

Mobile: react-i18next provides runtime i18n with React Native constraints (no Suspense, localStorage persistence, RTL via I18nManager).

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
    relativeTime: (d: Date) => {
      const diffSec = Math.floor((Date.now() - d.getTime()) / 1000);
      const rtf = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' });
      if (Math.abs(diffSec) < 60) return rtf.format(-diffSec, 'second');
      if (Math.abs(diffSec) < 3600) return rtf.format(-Math.floor(diffSec / 60), 'minute');
      if (Math.abs(diffSec) < 86400) return rtf.format(-Math.floor(diffSec / 3600), 'hour');
      return rtf.format(-Math.floor(diffSec / 86400), 'day');
    },
  };
}
```

---

## Platform-Specific Guides

- **Web (Paraglide JS):** `references/web-i18n.md`
  - Setup (Vite plugin / CLI), message format, SSR middleware
  - URL localization, language switcher, rich text, SEO
  - Framework notes: Next.js, SvelteKit, TanStack Start, Astro

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
