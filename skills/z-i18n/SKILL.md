---
name: z-i18n
description: |
  Internationalization (i18n) architecture and patterns for web and mobile apps.
  Use when: adding multi-language support, setting up translation structure, configuring locale routing, language switching, pluralization, date/number/currency formatting, RTL support, translation key design.
  Do not use for: general React/Next.js patterns (use z-nextjs), general mobile patterns (use z-react-native), UX copy decisions (use z-copywriting).
  Workflow: Use alongside z-nextjs (web) or z-react-native (mobile) skill.
---

# i18n Architecture

**For latest APIs, always verify with context7 before writing code.**

## Platform → Library Matrix

| Platform | Library | Message Format |
|---|---|---|
| Next.js App Router | `next-intl` | ICU MessageFormat |
| Expo / React Native | `expo-localization` + `react-i18next` + `i18next` | i18next JSON v4 |

Both platforms share the same JSON translation files. The difference is how they load and render them.

---

## Core Principles

These apply regardless of platform. Drawn from Airbnb, Shopify, and Lokalise engineering practices.

### 1. Namespace by Feature, Not by Page

Split translation files by domain/feature. Pages change; features are stable.

```
messages/          # next-intl (flat by locale)
├── en.json
└── ko.json

locales/           # i18next (nested by locale + namespace)
├── en/
│   ├── common.json
│   ├── auth.json
│   └── errors.json
└── ko/
    ├── common.json
    ├── auth.json
    └── errors.json
```

### 2. Key Naming Convention

Use **camelCase**, **2-3 levels max**, namespace by feature. The key is a contract between developer, translator, and TMS.

```json
{
  "auth": {
    "login": {
      "title": "Sign In",
      "submit": "Sign In",
      "forgotPassword": "Forgot password?"
    },
    "register": {
      "title": "Create Account",
      "submit": "Sign Up"
    }
  }
}
```

**Rules:**
- Key describes purpose, not the text: `auth.login.submit` not `auth.login.signInButton`
- Never concatenate translated strings — full sentences only
- One key per unique UI instance (even if English text is identical — translations may differ)
- `common` namespace for truly shared strings only: `common.save`, `common.cancel`, `common.loading`
- Never nest deeper than 3 levels

### 3. Type Safety Is Mandatory

Both platforms support type-safe keys. See platform references for setup:
- Next.js: `references/nextjs-i18n.md` → TypeScript augmentation via `next-intl`
- Expo: `references/expo-i18n.md` → Custom resource typing via `react-i18next`

### 4. Never Use Intl Formatters in Translation Strings When Avoidable

For dates, numbers, and currencies, prefer the framework's built-in formatting hooks over embedding format logic in translation strings. This keeps translations clean for translators.

```tsx
// ✅ Formatting in code, translation string stays simple
t('order.total', { price: format.currency(amount, 'USD') })

// ❌ Format logic embedded in translation string
// "order.total": "Total: {{val, currency(USD)}}"
```

Exception: Pluralization belongs in the translation string (ICU `{count, plural, ...}` or i18next `_one`/`_other` suffixes).

### 5. RTL Support from Day One

```typescript
export const LANGUAGES = [
  { code: 'en', name: 'English', dir: 'ltr' },
  { code: 'ko', name: '한국어', dir: 'ltr' },
  { code: 'ar', name: 'العربية', dir: 'rtl' },
] as const;

export type LanguageCode = (typeof LANGUAGES)[number]['code'];
export const isRTL = (code: string) =>
  LANGUAGES.find(l => l.code === code)?.dir === 'rtl';
```

For React Native, RTL requires `I18nManager.forceRTL()` + app reload. See `references/expo-i18n.md`.

### 6. Formatting Hook (Cross-Platform)

For formatting outside of translation strings. Both platforms can share this pattern:

```typescript
export const useFormat = () => {
  const lang = useCurrentLocale(); // abstracted per platform
  return useMemo(() => ({
    number: (v: number, opts?: Intl.NumberFormatOptions) =>
      new Intl.NumberFormat(lang, opts).format(v),
    currency: (v: number, cur = 'USD') =>
      new Intl.NumberFormat(lang, { style: 'currency', currency: cur }).format(v),
    date: (d: Date, opts?: Intl.DateTimeFormatOptions) =>
      new Intl.DateTimeFormat(lang, { dateStyle: 'medium', ...opts }).format(d),
    relativeTime: (d: Date) => {
      const diffSec = Math.floor((Date.now() - d.getTime()) / 1000);
      const rtf = new Intl.RelativeTimeFormat(lang, { numeric: 'auto' });
      if (Math.abs(diffSec) < 60) return rtf.format(-diffSec, 'second');
      if (Math.abs(diffSec) < 3600) return rtf.format(-Math.floor(diffSec / 60), 'minute');
      if (Math.abs(diffSec) < 86400) return rtf.format(-Math.floor(diffSec / 3600), 'hour');
      return rtf.format(-Math.floor(diffSec / 86400), 'day');
    },
  }), [lang]);
};
```

---

## Platform-Specific Guides

Detailed setup, patterns, and code for each platform:

- **Next.js (next-intl):** `references/nextjs-i18n.md`
  - Routing setup, middleware, Server/Client Component patterns
  - Type augmentation with `createMessagesDeclaration`
  - ICU pluralization, rich text, static rendering
  - SEO: `<html lang>`, `alternateLinks`, metadata localization

- **Expo (react-i18next):** `references/expo-i18n.md`
  - `expo-localization` device detection, language persistence (MMKV)
  - i18next init, namespace loading, JSON v4 pluralization
  - RTL with `I18nManager`, app reload pattern
  - iOS/Android native locale config in `app.json`

---

## Checklist

- [ ] Translations split by feature namespace (auth, common, errors, etc.)
- [ ] Key naming: camelCase, 2-3 levels max, descriptive purpose
- [ ] Type-safe keys configured (next-intl augmentation or react-i18next typing)
- [ ] `common` namespace for shared strings only, with strict governance
- [ ] Pluralization uses platform-native syntax (ICU for next-intl, JSON v4 suffixes for i18next)
- [ ] Formatting (dates, numbers, currency) done in code, not in translation strings
- [ ] RTL support planned if targeting Arabic/Hebrew/Persian
- [ ] Language persistence configured (cookie for web, MMKV/AsyncStorage for mobile)
- [ ] SEO: `<html lang>`, `hreflang` alternates, localized metadata (web only)
- [ ] No string concatenation in translations — full sentences always
