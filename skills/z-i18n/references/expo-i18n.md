# Expo / React Native i18n with react-i18next

Stack: `expo-localization` v17 + `i18next` v25 + `react-i18next` v16. TypeScript 5+.

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
│   ├── ko/
│   ├── ar/
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
  ko: { common: koCommon, auth: koAuth, errors: koErrors },
  ar: { common: arCommon, auth: arAuth, errors: arErrors },
  'pt-BR': { common: ptBRCommon, auth: ptBRAuth, errors: ptBRErrors },
} as const;

export const defaultNS = 'common';
export type SupportedLocale = keyof typeof resources;
export const supportedLocales = Object.keys(resources) as SupportedLocale[];
```

```typescript
// src/lib/i18n/index.ts
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
// locales/ar/common.json — zero/one/two/few/many/other
{
  "items_zero": "لا عناصر",
  "items_one": "عنصر واحد",
  "items_two": "عنصران",
  "items_few": "{{count}} عناصر",
  "items_many": "{{count}} عنصرًا",
  "items_other": "{{count}} عنصر"
}
```

```json
// locales/ko/common.json — other only
{ "items_other": "{{count}}개 항목" }
```

```tsx
t('items', { count: 0 })   // "لا عناصر" (ar) / "0개 항목" (ko)
t('items', { count: 1 })   // "1 item" (en) / "عنصر واحد" (ar)
t('items', { count: 5 })   // "5 items" (en) / "5 عناصر" (ar)
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

## Language Switching & RTL

```tsx
import { changeLanguage, type SupportedLocale } from '@/lib/i18n';
import { I18nManager, Platform } from 'react-native';
import * as Updates from 'expo-updates';

const LANGUAGES = [
  { code: 'en', name: 'English', dir: 'ltr' },
  { code: 'es', name: 'Español', dir: 'ltr' },
  { code: 'id', name: 'Bahasa Indonesia', dir: 'ltr' },
  { code: 'ko', name: '한국어', dir: 'ltr' },
  { code: 'ar', name: 'العربية', dir: 'rtl' },
  { code: 'pt-BR', name: 'Português (Brasil)', dir: 'ltr' },
] as const;

async function handleChange(locale: SupportedLocale) {
  const isRTL = LANGUAGES.find(l => l.code === locale)?.dir === 'rtl';
  const needsRTLChange = I18nManager.isRTL !== isRTL;

  await changeLanguage(locale);

  if (needsRTLChange && Platform.OS !== 'web') {
    I18nManager.allowRTL(isRTL);
    I18nManager.forceRTL(isRTL);
    await Updates.reloadAsync();  // RTL requires app reload
  }
}
```

**RTL styling tips:**
- Use `start`/`end` instead of `left`/`right` — React Native auto-flips in RTL
- `paddingStart: 16` is RTL-safe, `paddingLeft: 16` is not
- `flexDirection: I18nManager.isRTL ? 'row-reverse' : 'row'` for manual control

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
      "ko": "./languages/ko.json",
      "ar": "./languages/ar.json",
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
| `compatibilityJSON: 'v3'` | Removed in i18next v24 — only JSON v4 supported |
| AsyncStorage for language | Use `localStorage` polyfill — synchronous, no startup flash |
| Missing `react: { useSuspense: false }` | Required for React Native |
| RTL change without reload | `I18nManager.forceRTL()` requires `Updates.reloadAsync()` |
| Format logic in translations | Prefer `Intl` APIs in code |
| Missing `escapeValue: false` | React Native already escapes — double-escaping breaks output |
| Loading all namespaces at startup | Use `i18next-resources-to-backend` for lazy loading |
| `Intl.PluralRules` unavailable | Required since i18next v24 — polyfill if Hermes < 0.70 |
