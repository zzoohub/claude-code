---
name: z-nextjs
description: |
  Next.js 15/16 App Router patterns and conventions.
  Use when: setup or building web apps with Next.js, setting up project structure, implementing features, creating pages/components, writing Server Actions, data fetching, error handling, metadata/SEO, route handlers.
  Do not use for: UX decisions (use z-ux-design), token/component design (use z-design-system), mobile apps.
  Workflow: this skill (building web apps) -> vercel-react-best-practices (refactoring and performance optimization if needed).
references:
  - references/examples.md    # Server Actions, Data Fetching, Auth, Route Handler examples
---

# Next.js App Router Patterns

**For latest Next.js APIs, use context7.**

**Package manager**: Use `bun` for all commands.

---

## Project Structure (FSD + Next.js App Router)

**For Feature-Sliced Design use Context7.**

Root `app/` is for Next.js routing only. `src/` holds all FSD layers.
`src/app/` is the FSD app-layer (providers, global styles), NOT routing.

```
app/                 # Next.js App Router — routing only (thin re-exports)
├── layout.tsx       # Root layout (imports @/app/providers, @/app/globals.css)
├── page.tsx         # import { DashboardPage } from '@/views/dashboard'
└── some-page/
    └── page.tsx     # Thin: import page from @/views/, render it

src/                 # All FSD layers
├── app/             # FSD app-layer: providers, global styles (NO routing files)
│   ├── globals.css
│   └── providers/
├── views/           # FSD pages layer (named "views" to avoid Next.js pages/ conflict)
│   └── dashboard/   # Compose widgets into full page layouts
│       └── ui/
├── widgets/         # Sections/blocks (Header, Sidebar, StatsCards, RecentRuns)
├── features/        # User interactions (auth, send-comment, add-to-cart)
│   └── auth/
│       ├── ui/
│       ├── model/
│       ├── api/
│       └── actions/   # Server Actions
├── entities/        # Business entities (user, product, order)
│   └── user/
│       ├── ui/
│       ├── model/
│       └── api/
└── shared/          # Reusable infrastructure
    ├── ui/          # Design system
    ├── lib/         # Utilities, helpers
    ├── api/         # API client
    └── config/      # Environment, constants
```

### FSD Layer Rules

| Layer | Can import from | Cannot import from |
|-------|-----------------|-------------------|
| `app/` (routing) | views, widgets, shared | - |
| `views` | widgets, features, entities, shared | app |
| `widgets` | features, entities, shared | app, views |
| `features` | entities, shared | app, views, widgets |
| `entities` | shared | app, views, widgets, features |
| `shared` | - | All layers above |

**Rule: Layers can only import from layers below. Never above.**

---

## Server vs Client Components

```
Need useState, useEffect, onClick? → 'use client'
Need browser APIs (window, localStorage)? → 'use client'
Everything else → Server Component (default)
```

**Rule: Server Components by default. Add 'use client' only when needed.**

### Composition Pattern

```tsx
// Server Component fetches, Client Component interacts
async function ProductPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const product = await getProduct(id);  // Server-side fetch
  
  return (
    <div>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <AddToCartButton productId={product.id} />  {/* Client leaf */}
    </div>
  );
}
```

---

## Streaming with Suspense

**Rule: Don't block on slow data. Stream progressively.**

```tsx
// Parent is NOT async — children fetch independently and stream in parallel
export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>  {/* Renders immediately */}

      <Suspense fallback={<StatsSkeleton />}>
        <StatsCards />  {/* async SC — streams when ready */}
      </Suspense>

      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />  {/* async SC — streams when ready */}
      </Suspense>
    </div>
  );
}
```

**Share a single fetch across components with `use()`:**

```tsx
function Page() {
  const dataPromise = fetchData(); // start immediately, don't await
  return (
    <Suspense fallback={<Skeleton />}>
      <DataDisplay dataPromise={dataPromise} />
      <DataSummary dataPromise={dataPromise} /> {/* same fetch, no duplication */}
    </Suspense>
  );
}
function DataDisplay({ dataPromise }: { dataPromise: Promise<Data> }) {
  const data = use(dataPromise);
  return <div>{data.content}</div>;
}
```

**Skip Suspense when:** SEO-critical above-fold content, layout-shift-sensitive areas, fast queries where overhead isn't worth it.

---

## State Management

| State Type | Solution |
|------------|----------|
| Server data in Server Component | Direct fetch (no library) |
| Server data in Client Component | TanStack Query |
| URL state (filters, pagination, tabs) | nuqs (`useQueryState` / `useQueryStates`) |
| Form (most cases) | Server Actions + `useActionState` + Zod |
| Form (complex interactive) | TanStack Form + Zod → Server Action |
| Auth | Server session (cookie) + React Context |
| Complex wizard (multi-step) | Zustand → Server Action |
| Local UI | useState |

**Rule: Server Actions are the default for forms. Use TanStack Form only when you need instant client-side validation, dynamic field arrays, or conditional fields. Zustand only for cross-step wizard state.**

---

## Headless Patterns

**Rule: Separate WHAT (logic) from HOW (presentation).**

```tsx
// ❌ Before: Logic mixed in component
const ProductsPage = () => {
  const [products, setProducts] = useState([]);
  const [filters, setFilters] = useState({});
  const [isLoading, setIsLoading] = useState(true);
  // ... 300+ lines
};
```

```tsx
// ✅ After: Main component is composition only
const ProductsPage = () => {
  const { filters, setFilter, clear } = useProductFilters();
  const { products, isLoading } = useProducts(filters);

  return (
    <Page>
      <FilterBar filters={filters} onChange={setFilter} onClear={clear} />
      <Suspense fallback={<ProductsSkeleton />}>
        <ProductGrid products={products} isLoading={isLoading} />
      </Suspense>
    </Page>
  );
};
```

**Rule: Main component does composition only. Logic goes in hooks.**

---

## Server Actions

**For latest Server Actions API, use `context7` MCP or see [Next.js Server Actions docs](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations).**

**Rule: Server Actions go in `features/*/actions/` directory.**

Pattern:
1. `'use server'` directive at top
2. Zod schema for validation
3. Return `{ error }` or `{ success }` 
4. Call `revalidatePath` or `revalidateTag` after mutation

```tsx
// Client form uses useActionState
const [state, dispatch, isPending] = useActionState(serverAction, initialState);
```

→ Full Server Actions implementation (Zod validation, useActionState, revalidation): `references/examples.md`

---

## Data Caching

**For latest caching APIs, use `context7` MCP or see [Next.js Caching docs](https://nextjs.org/docs/app/getting-started/caching-and-revalidating).**

**Critical mental model shift (Next.js 15+): Nothing is cached by default.** In Next.js 14, fetch requests and GET Route Handlers were cached automatically. In 15+, all caching is opt-in. You must explicitly declare what should be cached.

| Pattern | Use for |
|---------|---------|
| `React.cache()` | Per-request deduplication (multiple components, one DB query) |
| LRU cache (`lru-cache`) | Cross-request caching with TTL (stable, no config flags needed) |
| `fetch()` with `next: { revalidate, tags }` | Fetch-level caching with time-based or tag-based revalidation |
| `revalidatePath()` | Invalidate specific path after mutation |
| `revalidateTag()` | Invalidate by tag after mutation |
| `after()` | Non-blocking post-response work (logging, analytics, cache warming) |

**Async dynamic APIs**: `cookies()`, `headers()`, `draftMode()` are all async in Next.js 15+ — must be awaited.

**Rule: Caching is opt-in. Always set an explicit revalidation strategy when you cache.**

---

## Error Handling

Every production app needs these file conventions:

| File | Purpose | Notes |
|------|---------|-------|
| `error.tsx` | Route-level error boundary | Must be `'use client'`. Catches errors in `page.tsx` and nested children. |
| `global-error.tsx` | Root layout error boundary | Must define its own `<html>` and `<body>` (replaces root layout on error). |
| `not-found.tsx` | 404 page | Place at `app/not-found.tsx` for global 404. Also works per-segment. |
| `loading.tsx` | Suspense boundary for route | Auto-wraps `page.tsx`. Shows instantly while streaming. |

**Rendering hierarchy**: `layout` > `template` > `error` (error boundary) > `loading` (suspense boundary) > `not-found` (error boundary) > `page`

```tsx
// app/error.tsx — must be 'use client'
'use client';

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}
```

Use `notFound()` from `next/navigation` to trigger `not-found.tsx` for missing resources (e.g., user not found by ID).

---

## Metadata & SEO

**For latest metadata APIs, use context7.**

```tsx
// Viewport must be a separate export (not inside metadata)
export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
};

// Static metadata
export const metadata: Metadata = {
  title: 'My App',
  description: 'Description',
};

// OR dynamic metadata (async, for pages with params)
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const product = await getProduct(id);
  return {
    title: product.name,
    description: product.description,
    openGraph: { title: product.name, images: [product.image] },
    alternates: { canonical: `https://example.com/products/${id}` },
  };
}
```

**File-based conventions**: Place `favicon.ico`, `icon.png`, `apple-icon.png`, `opengraph-image.png` in `app/` directory. Use `sitemap.ts` and `robots.ts` for generated SEO files.

---

## Route Handlers vs Server Actions

| Use case | Choose |
|----------|--------|
| Form mutations from your React components | **Server Actions** (simpler, type-safe) |
| Public API for external clients | **Route Handlers** |
| Webhook endpoints (Stripe, GitHub) | **Route Handlers** |
| Proxy / BFF pattern | **Route Handlers** |

Route Handlers go in `route.ts` files and export HTTP method functions (`GET`, `POST`, etc.) using Web Request/Response APIs. GET handlers are **uncached by default** in Next.js 15+.

Do not call Route Handlers from Server Components — fetch data directly instead (avoids unnecessary network hop).

-> Route Handler examples: `references/examples.md`

---

## Performance Rules

*Details and code examples: see `vercel-react-best-practices` skill.*

### Eliminating Waterfalls (CRITICAL)

- **Parallel fetching via composition**: Non-async parent + async child Server Components (NOT `Promise.all()` in one component)
- **Defer await**: Move `await` into branches where actually used; early return before expensive fetches
- **Start promises early**: `const p = fetch()` immediately, `await p` later when needed
- **`Promise.all()`**: For truly independent operations that must all complete before rendering

### Bundle Optimization (CRITICAL)

- **Avoid barrel imports**: Import directly (`lucide-react/dist/esm/icons/check`), or use `optimizePackageImports` in `next.config.js`
- **Dynamic imports**: `next/dynamic` with `{ ssr: false }` for heavy components (editors, charts)
- **Defer third-party**: Load analytics/error tracking via dynamic import after hydration
- **Preload on intent**: `void import('./heavy')` on `onMouseEnter`/`onFocus`

### RSC Performance (HIGH)

- **Minimize serialization**: Only pass fields the client component uses, not entire objects
- **`React.cache()`**: Wrap DB queries for per-request dedup across components
- **`after()`**: Schedule logging/analytics/cache invalidation after response is sent

### Client Performance

- **Functional setState**: `setState(prev => ...)` to avoid stale closures and enable stable callbacks
- **Lazy state init**: `useState(() => expensive())` not `useState(expensive())`
- **Derived selectors**: Subscribe to booleans (`useMediaQuery`) not raw values (`useWindowWidth`)
- **Narrow deps**: `[user.id]` not `[user]` in effect dependency arrays
- **`startTransition`**: Wrap non-urgent updates (scroll tracking, search filtering)
- **Ternary over `&&`**: `{count > 0 ? <Badge /> : null}` to avoid rendering `0`
- **Hydration no-flicker**: Inline `<script>` for client-only data (theme, prefs) before React hydrates

---

## Quick Checklist

### Architecture
- [ ] Using FSD layer rules (no upward imports)
- [ ] Main component is composition only
- [ ] Logic extracted to custom hooks
- [ ] Server Actions in features/*/actions/

### Server/Client
- [ ] Server Components by default
- [ ] 'use client' only when needed (useState, onClick, browser APIs)
- [ ] Client components are leaf nodes
- [ ] Only needed fields passed across RSC→Client boundary

### Data
- [ ] Server data fetched in Server Components
- [ ] Slow data wrapped in Suspense (async child SCs, non-async parent)
- [ ] Forms use Server Actions + useActionState
- [ ] Caching is opt-in (nothing cached by default in Next.js 15+)
- [ ] Proper cache invalidation (revalidatePath/revalidateTag)
- [ ] `React.cache()` for repeated queries within a request
- [ ] Dynamic APIs awaited: `cookies()`, `headers()`, `params`, `searchParams`

### Error Handling & SEO
- [ ] `app/error.tsx` for route errors
- [ ] `app/global-error.tsx` with own `<html>`/`<body>`
- [ ] `app/not-found.tsx` for 404
- [ ] `generateMetadata` or static `metadata` on pages
- [ ] `viewport` exported separately from `metadata`

### Bundle
- [ ] No barrel file imports (or `optimizePackageImports` configured)
- [ ] Heavy components use `next/dynamic`
- [ ] Analytics/logging deferred after hydration

### Auth & Security
- [ ] Auth validated at route/component level, not just middleware (CVE-2025-29927)
- [ ] Middleware used for routing concerns (rewrites, redirects, headers), not as sole auth layer
→ Auth patterns: `references/examples.md`

### Design System
- [ ] Using tokens from z-design-system (no hardcoded values)
- [ ] Proper loading/error states

## Security Configuration

| Header | Value |
|--------|-------|
| HSTS | `max-age=63072000; includeSubDomains; preload` |
| X-Frame-Options | `SAMEORIGIN` |
| X-Content-Type-Options | `nosniff` |
| Referrer-Policy | `strict-origin-when-cross-origin` |

| Item | Value |
|------|-------|
| Cookies httpOnly | `true` |
| Cookies secure | `true` |
| Cookies sameSite | `strict` |

**Middleware security**: After CVE-2025-29927 (critical severity 9.1, fixed in 15.2.3), Vercel recommends not relying solely on middleware for auth. Always validate authentication at the route/Server Component level as defense-in-depth. Middleware is best used for routing concerns: rewrites, redirects, header manipulation, locale detection.
