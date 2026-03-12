# Expo / React Native i18n with react-i18next

Stack: `expo-localization` + `i18next` + `react-i18next`. TypeScript 5+.

---

## Setup

```bash
bun add expo-localization i18next react-i18next
```

### File Structure

```
src/
├── lib/i18n/
│   ├── index.ts          # i18next init + export
│   ├── resources.ts      # Resource map
│   └── types.ts          # Type definitions
├── locales/
│   ├── en/
│   │   ├── common.json
│   │   ├── auth.json
│   │   └── errors.json
│   ├── es/
│   ├── id/
│   ├── ja/
│   ├── ko/
│   └── pt-BR/
└── app/
    └── _layout.tsx       # Import i18n here
```

### Resources & Config

```typescript
// src/lib/i18n/resources.ts
import enCommon from '@/locales/en/common.json';
import enAuth from '@/locales/en/auth.json';
import enErrors from '@/locales/en/errors.json';
// ... import other locales similarly

export const resources = {
  en: { common: enCommon, auth: enAuth, errors: enErrors },
  es: { common: esCommon, auth: esAuth, errors: esErrors },
  id: { common: idCommon, auth: idAuth, errors: idErrors },
  ja: { common: jaCommon, auth: jaAuth, errors: jaErrors },
  ko: { common: koCommon, auth: koAuth, errors: koErrors },
  'pt-BR': { common: ptBRCommon, auth: ptBRAuth, errors: ptBRErrors },
} as const;

export const defaultNS = 'common';
export type SupportedLocale = keyof typeof resources;
export const supportedLocales = Object.keys(resources) as SupportedLocale[];
```

```typescript
// src/lib/i18n/index.ts
import 'expo-sqlite/localStorage/install'; // localStorage polyfill — must be before any localStorage usage
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { getLocales } from 'expo-localization';
import { resources, defaultNS, supportedLocales, type SupportedLocale } from './resources';

const LANGUAGE_KEY = 'app.language';

function getDeviceLocale(): SupportedLocale {
  const deviceLang = getLocales()[0]?.languageCode ?? 'en';
  return supportedLocales.includes(deviceLang as SupportedLocale)
    ? (deviceLang as SupportedLocale) : 'en';
}

function getSavedLocale(): SupportedLocale | null {
  const saved = localStorage.getItem(LANGUAGE_KEY);
  return saved && supportedLocales.includes(saved as SupportedLocale)
    ? (saved as SupportedLocale) : null;
}

i18n.use(initReactI18next).init({
  resources,
  lng: getSavedLocale() ?? getDeviceLocale(),
  defaultNS,
  fallbackLng: 'en',
  interpolation: { escapeValue: false },
  react: { useSuspense: false },  // required for React Native
});

export default i18n;

export async function changeLanguage(locale: SupportedLocale) {
  await i18n.changeLanguage(locale);
  localStorage.setItem(LANGUAGE_KEY, locale);
}
```

```tsx
// src/app/_layout.tsx
import '@/lib/i18n'; // Side-effect import — must be first
```

---

## Type Safety

```typescript
// src/lib/i18n/types.ts
import { resources, defaultNS } from './resources';

declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: typeof defaultNS;
    resources: (typeof resources)['en'];
  }
}
```

Gives autocomplete for `t('auth:login.title')`, errors on missing keys, namespace-aware resolution. Ensure this file is in `tsconfig.json` includes.

---

## Usage

```tsx
import { useTranslation } from 'react-i18next';

function LoginScreen() {
  const { t } = useTranslation('auth');
  return (
    <View>
      <Text>{t('login.title')}</Text>
      <Button title={t('login.submit')} onPress={handleLogin} />
    </View>
  );
}
```

### Interpolation

```json
{ "greeting": "Hello, {{name}}!" }
```
```tsx
t('greeting', { name: 'Alice' })
```

### Pluralization (JSON v4)

Uses `Intl.PluralRules` suffixes. Variable must be `count`.

```json
// locales/en/common.json — one/other
{ "items_one": "{{count}} item", "items_other": "{{count}} items" }
```

```json
// locales/ja/common.json — other only
{ "items_other": "{{count}}個のアイテム" }
```

```json
// locales/ko/common.json — other only
{ "items_other": "{{count}}개 항목" }
```

```tsx
t('items', { count: 0 })   // "0개 항목" (ko) / "0 items" (en)
t('items', { count: 1 })   // "1 item" (en) / "1個のアイテム" (ja)
t('items', { count: 5 })   // "5 items" (en) / "5개 항목" (ko)
```

### Rich Text (Trans Component)

```tsx
import { Trans } from 'react-i18next';

// "terms": "Agree to our <bold>Terms</bold> and <link>Privacy</link>."
<Trans
  i18nKey="terms"
  components={{
    bold: <Text style={{ fontWeight: 'bold' }} />,
    link: <TouchableOpacity onPress={openPrivacy} />,
  }}
/>
```

---

## Lazy Loading Namespaces

For larger apps, use `i18next-resources-to-backend` instead of bundling all translations:

```bash
bun add i18next-resources-to-backend
```

```typescript
import resourcesToBackend from 'i18next-resources-to-backend';

i18n
  .use(initReactI18next)
  .use(resourcesToBackend(
    (language: string, namespace: string) =>
      import(`@/locales/${language}/${namespace}.json`)
  ))
  .init({
    lng: initialLocale,
    fallbackLng: 'en',
    ns: ['common'],
    defaultNS: 'common',
    interpolation: { escapeValue: false },
    react: { useSuspense: false },
  });
```

---

## Language Switching

```tsx
import { changeLanguage, type SupportedLocale } from '@/lib/i18n';

const LANGUAGES = [
  { code: 'en', name: 'English' },
  { code: 'es', name: 'Español' },
  { code: 'id', name: 'Bahasa Indonesia' },
  { code: 'ja', name: '日本語' },
  { code: 'ko', name: '한국어' },
  { code: 'pt-BR', name: 'Português (Brasil)' },
] as const;

async function handleChange(locale: SupportedLocale) {
  await changeLanguage(locale);
}
```

---

## Native Locale Config (app.json)

```json
{
  "expo": {
    "ios": {
      "infoPlist": { "CFBundleAllowMixedLocalizations": true }
    },
    "locales": {
      "es": "./languages/es.json",
      "id": "./languages/id.json",
      "ja": "./languages/ja.json",
      "ko": "./languages/ko.json",
      "pt-BR": "./languages/pt-BR.json"
    }
  }
}
```

Locale file format:
```json
{
  "ios": { "CFBundleDisplayName": "앱 이름", "NSCameraUsageDescription": "카메라 사용 설명" },
  "android": { "app_name": "앱 이름" }
}
```

**expo-localization v17:** `supportedLocales` enables the OS-level "preferred language" picker for your app.

---

## Android Language Detection

Android doesn't reset the app when device language changes. Listen for `AppState`:

```typescript
import { AppState } from 'react-native';
import { getLocales } from 'expo-localization';

AppState.addEventListener('change', (nextState) => {
  if (nextState === 'active') {
    const deviceLocale = getLocales()[0]?.languageCode;
    // Check if device locale changed and handle accordingly
  }
});
```

---

## Common Pitfalls

| Pitfall | Solution |
|---|---|
| `compatibilityJSON: 'v3'` | Removed — only JSON v4 supported |
| AsyncStorage for language | Use `expo-sqlite/localStorage/install` polyfill — synchronous, no startup flash |
| Missing `react: { useSuspense: false }` | Required for React Native |
| RTL change without reload | `I18nManager.forceRTL()` requires `Updates.reloadAsync()` |
| Format logic in translations | Prefer `Intl` APIs in code |
| Missing `escapeValue: false` | React Native already escapes — double-escaping breaks output |
| Loading all namespaces at startup | Use `i18next-resources-to-backend` for lazy loading |
| `Intl.PluralRules` unavailable | Required by modern i18next — polyfill if Hermes < 0.70 |
