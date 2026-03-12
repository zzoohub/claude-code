# Web i18n with Paraglide JS v2

> **Version:** Paraglide JS v2.x (`@inlang/paraglide-js@^2.0.0`). v1 framework-specific adapters (`@inlang/paraglide-sveltekit`, `@inlang/paraglide-next`, `@inlang/paraglide-astro`) are deprecated — all functionality is consolidated into the core package.

Compiler-based i18n — translations compile into tree-shakable JS functions. Unused messages are eliminated from the bundle. Full TypeScript type safety is automatic. Framework-agnostic: SvelteKit, TanStack Start, Astro, React Router, or any Vite-based setup.

---

## Setup

```bash
bunx @inlang/paraglide-js@latest init
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

Paraglide returns plain strings. For embedding components within translations, parse tags into segments, then render per framework:

```typescript
// src/lib/i18n/rich-text.ts — framework-agnostic parser
interface RichTextSegment {
  type: "text" | "tag";
  content: string;
  tag?: string; // tag name for type === "tag"
}

export function parseRichText(text: string): RichTextSegment[] {
  const segments: RichTextSegment[] = [];
  let remaining = text;
  while (remaining.length > 0) {
    const match = remaining.match(/<(\w+)>(.*?)<\/\1>/);
    if (!match || match.index === undefined) {
      segments.push({ type: "text", content: remaining });
      break;
    }
    const before = remaining.slice(0, match.index);
    if (before) segments.push({ type: "text", content: before });
    const [full, tag, content] = match;
    segments.push({ type: "tag", content, tag });
    remaining = remaining.slice(match.index + full.length);
  }
  return segments;
}
```

```json
{ "terms": "Agree to our <terms>Terms</terms> and <privacy>Privacy Policy</privacy>." }
```

```typescript
// Usage — render segments per framework
const segments = parseRichText(m.terms());
// segments = [
//   { type: "text", content: "Agree to our " },
//   { type: "tag", content: "Terms", tag: "terms" },
//   { type: "text", content: " and " },
//   { type: "tag", content: "Privacy Policy", tag: "privacy" },
//   { type: "text", content: "." },
// ]

// Vanilla JS / any framework: iterate segments, create DOM nodes or framework elements
// React: map to JSX with <Fragment key={i}>
// Solid: map to JSX
// Svelte: use {#each} block
```

---

## SSR Middleware (v2)

`paraglideMiddleware()` uses `AsyncLocalStorage` to isolate locale per request. Without it, `getLocale()` on the server returns the default locale. Import from the generated `server.js` module.

```typescript
// SvelteKit — src/hooks.server.ts
export const handle: Handle = ({ event, resolve }) =>
  paraglideMiddleware(event.request, ({ request }) => resolve({ ...event, request }));

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

```typescript
import { setLocale, getLocale, locales } from "./paraglide/runtime.js";

const LOCALE_NAMES: Record<string, string> = {
  en: "English",
  es: "Español",
  id: "Bahasa Indonesia",
  ja: "日本語",
  ko: "한국어",
  "pt-BR": "Português (Brasil)",
};

// Vanilla JS — create a <select> element
function createLocaleSwitcher(container: HTMLElement) {
  const select = document.createElement("select");
  for (const locale of locales) {
    const option = document.createElement("option");
    option.value = locale;
    option.textContent = LOCALE_NAMES[locale] ?? locale;
    option.selected = locale === getLocale();
    select.appendChild(option);
  }
  select.addEventListener("change", () => setLocale(select.value));
  container.appendChild(select);
}
```

```html
<!-- Or declarative HTML — wire up with any framework -->
<select id="locale-switcher">
  <option value="en">English</option>
  <option value="es">Español</option>
  <option value="ko">한국어</option>
  <!-- ... -->
</select>
<script>
  document.getElementById("locale-switcher")
    .addEventListener("change", (e) => setLocale(e.target.value));
</script>
```

---

## SEO

```html
<!-- Set lang on <html> element -->
<html lang="en"> <!-- dynamically set to getLocale() value -->

<!-- Alternate links (hreflang) — generate for all locales -->
<link rel="alternate" hrefLang="en" href="https://example.com/about" />
<link rel="alternate" hrefLang="es" href="https://example.com/es/about" />
<link rel="alternate" hrefLang="ko" href="https://example.com/ko/about" />
<!-- ... one per locale -->
```

```typescript
// Generate hreflang links programmatically (any framework/SSR)
import { getLocale, locales, localizeHref } from "./paraglide/runtime.js";

const path = "/about";
const hreflangs = locales.map((loc) => ({
  hrefLang: loc,
  href: `https://example.com${localizeHref(path, { locale: loc })}`,
}));
// Inject into <head> using your framework's head management
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
