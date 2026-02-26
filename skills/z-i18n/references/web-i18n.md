# Web i18n with Paraglide JS v2

> **Version:** Paraglide JS v2.x (`@inlang/paraglide-js@^2.0.0`). v1 framework-specific adapters (`@inlang/paraglide-sveltekit`, `@inlang/paraglide-next`, `@inlang/paraglide-astro`) are deprecated — all functionality is consolidated into the core package.

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
│   └── pt-BR.json
└── src/
    └── paraglide/          # Generated (do NOT edit, add to .gitignore)
        ├── messages.js
        ├── runtime.js      # getLocale, setLocale, localizeHref, locales
        └── server.js       # paraglideMiddleware for SSR
```

### Configuration

```json
// project.inlang/settings.json (v2 — no modules array needed)
{
  "baseLocale": "en",
  "locales": ["en", "es", "id", "ja", "ko", "pt-BR"]
}
```

Message files go in `messages/` by default. Override with compiler `pathPattern` option if needed.

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

### Next.js (Webpack Plugin)

For Next.js and other Webpack-based frameworks, use `@inlang/paraglide-webpack`:

```bash
bun add -D @inlang/paraglide-js @inlang/paraglide-webpack
```

```typescript
// next.config.ts
import { paraglideWebpackPlugin } from "@inlang/paraglide-webpack";

const nextConfig = {
  webpack: (config) => {
    config.plugins.push(
      paraglideWebpackPlugin({
        project: "./project.inlang",
        outdir: "./src/paraglide",
        strategy: ["url", "cookie", "baseLocale"],
      })
    );
    return config;
  },
};
export default nextConfig;
```

**Fallback (no bundler plugin):** Use CLI compile directly:

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

| Language | Plural categories |
|---|---|
| en, es, pt-BR, id | `one`, `other` |
| ja, ko | `other` only |

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
import {
  getLocale, setLocale, locales, baseLocale, isLocale,
  localizeHref, deLocalizeHref,
} from "./paraglide/runtime.js";

m.auth_login_title();                              // "Sign In"
m.greeting({ name: "Alice" });                     // type-safe params
m.greeting({ name: "Alice" }, { locale: "ko" });   // force specific locale

getLocale();                        // "en"
setLocale("ko");                    // reloads page (v2 default behavior)
setLocale("ko", { reload: false }); // no reload (handle re-render yourself)

localizeHref("/about");                     // "/ko/about"
localizeHref("/about", { locale: "en" });   // "/en/about"
deLocalizeHref("/ko/about");                // "/about" (strip locale prefix)

isLocale("en");    // true (type guard)
isLocale("xyz");   // false
baseLocale;        // "en"
locales;           // ["en", "es", "id", "ja", "ko", "pt-BR"]
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

## SSR Middleware (v2)

`paraglideMiddleware()` uses `AsyncLocalStorage` to isolate locale per request. Without it, `getLocale()` on the server returns the default locale. Import from the generated `server.js` module.

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

## SEO

```tsx
import { getLocale, locales, localizeHref } from "./paraglide/runtime.js";

const locale = getLocale();

// Root layout
<html lang={locale}>

// Alternate links (hreflang)
{locales.map((loc) => (
  <link key={loc} rel="alternate" hrefLang={loc}
    href={`https://example.com${localizeHref(path, { locale: loc })}`} />
))}
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
