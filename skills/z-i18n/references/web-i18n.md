# Web i18n with Paraglide JS

Compiler-based i18n — translations compile into tree-shakable JS functions. Unused messages are eliminated from the bundle. Full TypeScript type safety is automatic. Framework-agnostic: Next.js, SvelteKit, TanStack Start, Astro, React Router, or any Vite-based setup.

---

## Setup

```bash
npx @inlang/paraglide-js@latest init
bun add -D @inlang/paraglide-js
```

### Project Structure

```
project-root/
├── project.inlang/
│   └── settings.json
├── messages/
│   ├── en.json
│   ├── es.json
│   ├── id.json
│   ├── ja.json
│   ├── ko.json
│   ├── ar.json
│   └── pt-BR.json
└── src/
    └── paraglide/          # Generated (do NOT edit, add to .gitignore)
        ├── messages.js
        ├── runtime.js      # getLocale, setLocale, localizeHref, locales
        └── server.js       # paraglideMiddleware for SSR
```

### Configuration

```json
// project.inlang/settings.json
{
  "baseLocale": "en",
  "locales": ["en", "es", "id", "ja", "ko", "ar", "pt-BR"],
  "modules": [
    "https://cdn.jsdelivr.net/npm/@inlang/plugin-message-format@latest/dist/index.js"
  ],
  "plugin.inlang.messageFormat": {
    "pathPattern": "./messages/{locale}.json"
  }
}
```

### Vite Plugin (Recommended)

```typescript
// vite.config.ts
import { paraglideVitePlugin } from "@inlang/paraglide-js";

export default defineConfig({
  plugins: [
    paraglideVitePlugin({
      project: "./project.inlang",
      outdir: "./src/paraglide",
      strategy: ["url", "cookie", "baseLocale"],
    }),
    // ... other plugins (sveltekit(), react(), etc.)
  ],
});
```

### Non-Vite (Next.js, etc.)

```json
// package.json
{
  "scripts": {
    "build": "paraglide compile --project ./project.inlang --outdir ./src/paraglide && next build",
    "dev": "paraglide compile --project ./project.inlang --outdir ./src/paraglide --watch & next dev"
  }
}
```

---

## Message Format

### Simple Messages & Interpolation

```json
// messages/en.json
{
  "auth.login.title": "Sign In",
  "greeting": "Hello, {name}!",
  "items_in_cart": "You have {count} items in your cart."
}
```

Variables use `{variableName}` syntax. Keys with dots compile to underscore functions: `m.auth_login_title()`.

### Pluralization (Variants)

Uses `Intl.PluralRules`. Each language needs only its relevant plural categories:

```json
// messages/en.json — one/other
{
  "follower_count": [{
    "declarations": ["input count", "local countPlural = count: plural"],
    "selectors": ["countPlural"],
    "match": {
      "countPlural=one": "{count} follower",
      "countPlural=other": "{count} followers"
    }
  }]
}
```

```json
// messages/ja.json — other only (East Asian languages have no grammatical plural)
{
  "follower_count": [{
    "declarations": ["input count", "local countPlural = count: plural"],
    "selectors": ["countPlural"],
    "match": { "countPlural=other": "フォロワー {count}人" }
  }]
}
```

```json
// messages/ko.json — other only (East Asian languages have no grammatical plural)
{
  "follower_count": [{
    "declarations": ["input count", "local countPlural = count: plural"],
    "selectors": ["countPlural"],
    "match": { "countPlural=other": "팔로워 {count}명" }
  }]
}
```

```json
// messages/ar.json — zero/one/two/few/many/other (Arabic has 6 plural categories)
{
  "follower_count": [{
    "declarations": ["input count", "local countPlural = count: plural"],
    "selectors": ["countPlural"],
    "match": {
      "countPlural=zero": "لا متابعين",
      "countPlural=one": "متابع واحد",
      "countPlural=two": "متابعان",
      "countPlural=few": "{count} متابعين",
      "countPlural=many": "{count} متابعًا",
      "countPlural=other": "{count} متابع"
    }
  }]
}
```

| Language | Plural categories |
|---|---|
| en, es, pt-BR, id | `one`, `other` |
| ja, ko | `other` only |
| ar | `zero`, `one`, `two`, `few`, `many`, `other` |

### Number & Date Formatting

Built-in formatters map to `Intl` APIs (`number` → `Intl.NumberFormat`, `datetime` → `Intl.DateTimeFormat`):

```json
{
  "total_price": [{
    "declarations": ["input amount", "local formatted = amount: number style=currency currency=USD"],
    "match": { "amount=*": "Total: {formatted}" }
  }]
}
```

### Select (Conditional Variants)

```json
{
  "notification": [{
    "declarations": ["input type"],
    "selectors": ["type"],
    "match": {
      "type=comment": "New comment on your post",
      "type=follow": "New follower",
      "type=*": "New notification"
    }
  }]
}
```

`*` is the catch-all default.

---

## Usage

```typescript
import { m } from "./paraglide/messages.js";
import { getLocale, setLocale, locales, localizeHref } from "./paraglide/runtime.js";

m.auth_login_title();                              // "Sign In"
m.greeting({ name: "Alice" });                     // type-safe params
m.greeting({ name: "Alice" }, { locale: "ko" });   // force specific locale

getLocale();                        // "en"
setLocale("ko");                    // reloads page
setLocale("ko", { reload: false }); // no reload (handle re-render yourself)

localizeHref("/about");                     // "/ko/about"
localizeHref("/about", { locale: "en" });   // "/en/about"
```

### Rich Text Pattern

Paraglide returns plain strings. For embedding components within translations:

```typescript
// src/lib/i18n/rich-text.tsx
import { Fragment, type ReactNode } from "react";

export function richText(
  text: string,
  components: Record<string, (content: string) => ReactNode>
): ReactNode[] {
  const result: ReactNode[] = [];
  let remaining = text;
  let key = 0;
  while (remaining.length > 0) {
    const match = remaining.match(/<(\w+)>(.*?)<\/\1>/);
    if (!match || match.index === undefined) {
      result.push(<Fragment key={key++}>{remaining}</Fragment>);
      break;
    }
    const before = remaining.slice(0, match.index);
    if (before) result.push(<Fragment key={key++}>{before}</Fragment>);
    const [full, tag, content] = match;
    const render = components[tag];
    result.push(<Fragment key={key++}>{render ? render(content) : content}</Fragment>);
    remaining = remaining.slice(match.index + full.length);
  }
  return result;
}
```

```json
{ "terms": "Agree to our <terms>Terms</terms> and <privacy>Privacy Policy</privacy>." }
```

```tsx
richText(m.terms(), {
  terms: (text) => <a href="/terms">{text}</a>,
  privacy: (text) => <a href="/privacy">{text}</a>,
});
```

---

## SSR Middleware

`paraglideMiddleware()` uses `AsyncLocalStorage` to isolate locale per request. Without it, `getLocale()` on the server returns the default locale.

```typescript
// SvelteKit — src/hooks.server.ts
export const handle: Handle = ({ event, resolve }) =>
  paraglideMiddleware(event.request, ({ request }) => resolve({ ...event, request }));

// Next.js — middleware.ts
export function middleware(request: Request) {
  return paraglideMiddleware(request, () => NextResponse.next());
}
export const config = { matcher: ["/((?!api|_next|_vercel|.*\\..*).*)"] };

// TanStack Start — server.ts (pass original req to handler, NOT the modified one)
export default {
  fetch(req: Request) {
    return paraglideMiddleware(req, () => handler.fetch(req));
  },
};

// Astro — src/middleware.ts
export const onRequest = defineMiddleware((context, next) =>
  paraglideMiddleware(context.request, ({ request }) => next(request))
);
```

Client-only SPAs need no middleware — use `["cookie", "globalVariable", "baseLocale"]` strategy.

---

## Strategy Configuration

Evaluated in order — first match wins.

| Strategy | How it works | Best for |
|---|---|---|
| `url` | Locale from URL path (`/ko/about`) | SEO, shareable links |
| `cookie` | Reads/writes cookie | Returning users |
| `baseLocale` | Falls back to base locale | Default fallback |
| `preferredLanguage` | `Accept-Language` header | First-time visitors |
| `globalVariable` | Global JS variable | SPAs without SSR |

Recommended: SSR `["url", "cookie", "baseLocale"]`, SPA `["cookie", "globalVariable", "baseLocale"]`.
Subdomains: set `cookieDomain: "example.com"` in plugin config.

---

## Language Switcher

```tsx
import { setLocale, getLocale, locales } from "./paraglide/runtime.js";

const LOCALE_NAMES: Record<string, string> = {
  en: "English",
  es: "Español",
  id: "Bahasa Indonesia",
  ja: "日本語",
  ko: "한국어",
  ar: "العربية",
  "pt-BR": "Português (Brasil)",
};

function LocaleSwitcher() {
  return (
    <select value={getLocale()} onChange={(e) => setLocale(e.target.value)}>
      {locales.map((locale) => (
        <option key={locale} value={locale}>{LOCALE_NAMES[locale] ?? locale}</option>
      ))}
    </select>
  );
}
```

---

## SEO & RTL

```tsx
import { getLocale, locales, localizeHref } from "./paraglide/runtime.js";

const RTL_LOCALES = ["ar", "he", "fa", "ur"];
const locale = getLocale();

// Root layout
<html lang={locale} dir={RTL_LOCALES.includes(locale) ? "rtl" : "ltr"}>

// Alternate links (hreflang)
{locales.map((loc) => (
  <link key={loc} rel="alternate" hrefLang={loc}
    href={`https://example.com${localizeHref(path, { locale: loc })}`} />
))}
```

### RTL with CSS Logical Properties (Tailwind)

`dir="rtl"` flips the entire layout. Use logical properties so styles adapt automatically:

| Physical (avoid) | Logical (use) | CSS property |
|---|---|---|
| `ml-4` | `ms-4` | `margin-inline-start` |
| `mr-4` | `me-4` | `margin-inline-end` |
| `pl-4` | `ps-4` | `padding-inline-start` |
| `pr-4` | `pe-4` | `padding-inline-end` |
| `left-0` | `start-0` | `inset-inline-start` |
| `right-0` | `end-0` | `inset-inline-end` |
| `text-left` | `text-start` | `text-align: start` |
| `text-right` | `text-end` | `text-align: end` |
| `rounded-l-lg` | `rounded-s-lg` | `border-start-start-radius` |
| `border-r` | `border-e` | `border-inline-end` |

`s` = start, `e` = end. Supported since Tailwind CSS v3.

```html
<!-- ❌ Breaks in RTL -->
<div class="ml-4 pr-2 text-left">

<!-- ✅ Works in both LTR and RTL -->
<div class="ms-4 pe-2 text-start">
```

---

## Type Safety

Fully automatic — the compiler generates typed functions:

- Autocomplete for `m.` (all message keys) and parameters (`m.greeting({` → `name: string`)
- Compile error on typos (`m.typo()`) and missing params (`m.greeting()`)
- Typed locale: `import type { Locale } from "./paraglide/runtime.js"`

**VS Code:** Install [Sherlock](https://marketplace.visualstudio.com/items?itemName=inlang.vs-code-extension) for inline translation previews, hover variants, and one-click string extraction.

---

## Common Pitfalls

| Pitfall | Solution |
|---|---|
| Editing `src/paraglide/` | Generated output — never edit, overwritten on compile |
| `getLocale()` wrong on server | Must run inside `paraglideMiddleware()` callback |
| `setLocale()` doesn't update UI | Default reloads page. `{ reload: false }` requires manual re-render |
| Redirect loops with URL strategy | Pass **original** request to framework handler |
| Strategy order wrong for SEO | URL first: `["url", "cookie", "baseLocale"]` |
| `AsyncLocalStorage` unavailable | Edge runtimes: `disableAsyncLocalStorage: true` |
| Forgetting `--watch` in dev | Without Vite plugin, add `--watch` to compiler script |
| Rich text needs components | Use `richText()` helper (see Usage section) |
| Cookie not scoped for subdomains | Set `cookieDomain` in plugin config |
