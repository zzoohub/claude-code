# Expo / React Native i18n with react-i18next

**Docs:**
- [Expo Localization](https://docs.expo.dev/guides/localization/)
- [react-i18next](https://react.i18next.com/)
- [i18next](https://www.i18next.com/)

Stack: `expo-localization` (device locale detection) + `i18next` (core engine) + `react-i18next` (React bindings)

---

## Setup

### 1. Install

```bash
bun add expo-localization i18next react-i18next
bun add react-native-mmkv   # for language persistence (faster than AsyncStorage)
```

### 2. File Structure

```
src/
├── lib/
│   └── i18n/
│       ├── index.ts              # i18next init + export
│       ├── resources.ts          # Resource map
│       └── types.ts              # Type definitions
├── locales/
│   ├── en/
│   │   ├── common.json
│   │   ├── auth.json
│   │   └── errors.json
│   └── ko/
│       ├── common.json
│       ├── auth.json
│       └── errors.json
└── app/
    └── _layout.tsx               # Import i18n here
```

### 3. i18next Config

```typescript
// src/lib/i18n/resources.ts
import enCommon from '@/locales/en/common.json';
import enAuth from '@/locales/en/auth.json';
import enErrors from '@/locales/en/errors.json';
import koCommon from '@/locales/ko/common.json';
import koAuth from '@/locales/ko/auth.json';
import koErrors from '@/locales/ko/errors.json';

export const resources = {
  en: {
    common: enCommon,
    auth: enAuth,
    errors: enErrors,
  },
  ko: {
    common: koCommon,
    auth: koAuth,
    errors: koErrors,
  },
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
import { storage } from '@/lib/storage'; // your MMKV instance

const LANGUAGE_KEY = 'app.language';

function getDeviceLocale(): SupportedLocale {
  const deviceLang = getLocales()[0]?.languageCode ?? 'en';
  return supportedLocales.includes(deviceLang as SupportedLocale)
    ? (deviceLang as SupportedLocale)
    : 'en';
}

function getSavedLocale(): SupportedLocale | null {
  const saved = storage.getString(LANGUAGE_KEY);
  if (saved && supportedLocales.includes(saved as SupportedLocale)) {
    return saved as SupportedLocale;
  }
  return null;
}

const initialLocale = getSavedLocale() ?? getDeviceLocale();

i18n.use(initReactI18next).init({
  resources,
  lng: initialLocale,
  defaultNS,
  fallbackLng: 'en',
  interpolation: { escapeValue: false },
  react: { useSuspense: false },
});

export default i18n;

export async function changeLanguage(locale: SupportedLocale) {
  await i18n.changeLanguage(locale);
  storage.set(LANGUAGE_KEY, locale);
}
```

### 4. Import in Root Layout

```tsx
// src/app/_layout.tsx
import '@/lib/i18n'; // Side-effect import — must be first

export default function RootLayout() {
  // ... your layout
}
```

---

## Type Safety

### Define types from resources

```typescript
// src/lib/i18n/types.ts
import { resources, defaultNS } from './resources';

// Augment react-i18next types
declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: typeof defaultNS;
    resources: (typeof resources)['en'];  // Use default locale as type source
  }
}
```

This gives:
- Autocompletion for `t('auth:login.title')`
- Error if key doesn't exist
- Namespace-aware: `t('login.title')` uses `common` (default), `t('auth:login.title')` uses `auth`

### Import the types file

Make sure the types file is included in your `tsconfig.json`:
```json
{
  "include": ["src/**/*.ts", "src/**/*.tsx", "src/lib/i18n/types.ts"]
}
```

---

## Usage

### Basic Translation

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
// locales/en/common.json
{ "greeting": "Hello, {{name}}!" }
```
```tsx
t('greeting', { name: 'Alice' })
```

### Pluralization (JSON v4 — i18next >= 21)

Uses `Intl.PluralRules` suffixes: `_zero`, `_one`, `_two`, `_few`, `_many`, `_other`.
**Variable must be `count`.**

```json
{
  "items_zero": "No items",
  "items_one": "{{count}} item",
  "items_other": "{{count}} items"
}
```
```tsx
t('items', { count: 0 })   // "No items"
t('items', { count: 1 })   // "1 item"
t('items', { count: 5 })   // "5 items"
```

### Ordinal Plurals

```json
{
  "place_ordinal_one": "{{count}}st",
  "place_ordinal_two": "{{count}}nd",
  "place_ordinal_few": "{{count}}rd",
  "place_ordinal_other": "{{count}}th"
}
```
```tsx
t('place', { count: 1, ordinal: true })  // "1st"
t('place', { count: 3, ordinal: true })  // "3rd"
```

### Trans Component (Rich Text)

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

## Built-in Intl Formatters (i18next >= 21.3.0)

Use directly in translation strings without custom code:

```json
{
  "visitors": "Total: {{val, number}}",
  "price": "Price: {{val, currency(USD)}}",
  "createdAt": "Created: {{val, datetime}}",
  "lastSeen": "Active {{val, relativetime}}"
}
```

For more control, pass `formatParams`:
```tsx
t('createdAt', {
  val: new Date(),
  formatParams: {
    val: { weekday: 'long', month: 'long', day: 'numeric' },
  },
});
```

**Rule:** Never use `interpolation.format` — it's legacy since i18next 21.3.0 and triggers deprecation warnings.

---

## Language Switching

```tsx
import { useTranslation } from 'react-i18next';
import { changeLanguage, type SupportedLocale } from '@/lib/i18n';
import { I18nManager, Platform } from 'react-native';
import * as Updates from 'expo-updates';
import { LANGUAGES } from '@/lib/i18n/config';

function LanguagePicker() {
  const { i18n } = useTranslation();

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

  return (
    <View>
      {LANGUAGES.map((lang) => (
        <Pressable key={lang.code} onPress={() => handleChange(lang.code)}>
          <Text style={i18n.language === lang.code ? styles.active : undefined}>
            {lang.name}
          </Text>
        </Pressable>
      ))}
    </View>
  );
}
```

---

## RTL Support

RTL in React Native requires `I18nManager` + app reload:

```typescript
import { I18nManager, Platform } from 'react-native';
import * as Updates from 'expo-updates';

export function applyRTL(isRTL: boolean) {
  if (Platform.OS === 'web') return;
  if (I18nManager.isRTL === isRTL) return;

  I18nManager.allowRTL(isRTL);
  I18nManager.forceRTL(isRTL);
  Updates.reloadAsync();
}
```

For conditional styling:
```tsx
import { I18nManager } from 'react-native';

const styles = StyleSheet.create({
  row: {
    flexDirection: I18nManager.isRTL ? 'row-reverse' : 'row',
  },
});
```

**Tip:** Use `start`/`end` instead of `left`/`right` in styles — React Native auto-flips these in RTL:
```tsx
// ✅ RTL-safe
{ paddingStart: 16, textAlign: 'left' }  // 'left' is logical in RN

// ❌ Not RTL-safe with manual row-reverse
{ paddingLeft: 16 }
```

---

## Native Locale Config (app.json)

For iOS App Store language support and system-level locale strings:

```json
{
  "expo": {
    "ios": {
      "infoPlist": {
        "CFBundleAllowMixedLocalizations": true
      }
    },
    "locales": {
      "ko": "./languages/korean.json",
      "ja": "./languages/japanese.json"
    }
  }
}
```

Locale file format:
```json
{
  "ios": {
    "CFBundleDisplayName": "앱 이름",
    "NSCameraUsageDescription": "카메라 사용 설명"
  },
  "android": {
    "app_name": "앱 이름"
  }
}
```

---

## Language Detection on Android

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

## Domain-Specific Hooks

Create typed convenience hooks per feature to avoid scattering namespace strings:

```typescript
import { useTranslation } from 'react-i18next';

export function useAuthI18n() {
  const { t } = useTranslation('auth');
  return { t };
}

export function useCommonI18n() {
  const { t } = useTranslation('common');
  return { t };
}
```

Usage:
```tsx
function LoginScreen() {
  const { t } = useAuthI18n();
  return <Text>{t('login.title')}</Text>;
}
```

---

## Common Pitfalls

| Pitfall | Solution |
|---|---|
| `compatibilityJSON: 'v3'` in config | Remove it — use JSON v4 (default in i18next >= 21) for proper Intl plurals |
| Using AsyncStorage for language (slow) | Use `react-native-mmkv` — synchronous, no startup flash |
| Forgetting `react: { useSuspense: false }` | Required for React Native — no Suspense boundaries for i18next |
| RTL change without app reload | `I18nManager.forceRTL()` only takes effect after reload via `Updates.reloadAsync()` |
| Embedding format logic in translation strings | Prefer formatting in code with `Intl` APIs; keep translations clean |
| Not setting `escapeValue: false` | React Native already escapes — double-escaping breaks output |
| Loading all namespaces at startup | Bundle only needed namespaces; lazy-load others for large apps |
