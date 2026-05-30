---
name: tanstack-start
description: |
  TanStack Start full-stack framework (React) — file-based routing, server functions, middleware, SSR.
  Use when: building full-stack apps with TanStack Start, using TanStack Router file-based routing,
  writing createServerFn or createMiddleware, deploying TanStack Start apps.
  Also use when user mentions TanStack Start or TanStack Router.
  Do not use for: Next.js (use vercel-composition-patterns / vercel:nextjs). For SolidJS apps,
  prefer SolidStart or TanStack Start's Solid adapter — this skill covers React patterns only.
  For React-specific patterns, also read `references/react.md`.
---

# TanStack Start

Explicit over magic. End-to-end type safety. URL as first-class state.

**Package manager**: `bun`.
**Packages**: `@tanstack/react-start` + `@tanstack/react-router` (+ `react`, `react-dom`). Add `@tanstack/react-query` + `@tanstack/react-router-ssr-query` for Query integration. `@tanstack/zod-adapter` + `zod` are optional — only needed for `zodValidator` on route `validateSearch` (under Zod v4 you can pass the schema directly).

> For latest APIs, use context7 MCP: resolve `tanstack/router` → query.

---

## Project Structure (FSD)

Route files are thin wrappers — routing concerns only (loader, beforeLoad, head).
UI goes in `views/`. Server functions live in the slice that owns the data.

```
src/
├── routes/                     # File-based routing (thin wrappers)
│   ├── __root.tsx              # Root layout
│   ├── index.tsx               # / → imports from views/
│   ├── posts.$postId.tsx       # Dynamic route → imports from views/
│   ├── _auth.tsx               # Pathless layout guard
│   └── api/
│       └── users.$id.ts        # API route (external consumers only)
├── views/                      # Page layouts (compose widgets + features)
├── widgets/                    # Composite UI blocks
├── features/
│   └── [feature]/
│       ├── ui/
│       ├── model/
│       └── api/                # Server functions (createServerFn)
├── entities/
│   └── [entity]/
│       ├── ui/
│       ├── model/
│       └── api/
├── shared/                     # ui/, api/, lib/, config/
├── router.tsx                  # Router creation + type registration
└── routeTree.gen.ts            # Auto-generated (DO NOT EDIT)
```

**Rules**: Layers only import downward. Routes are thin glue. `createServerFn` lives in owning slice's `api/`.

---

## Routing

### File Conventions

| File | URL | Notes |
|------|-----|-------|
| `__root.tsx` | — | Root layout |
| `index.tsx` | `/` | |
| `about.tsx` | `/about` | |
| `posts.tsx` | — | Layout for `/posts/*` |
| `posts.index.tsx` | `/posts` | Index under layout |
| `posts.$postId.tsx` | `/posts/:postId` | Dynamic segment |
| `posts/route.tsx` | — | Directory form of the `posts.tsx` layout |
| `_auth.tsx` | — | Pathless layout (no URL segment) |
| `_auth/dashboard.tsx` | `/dashboard` | Under pathless layout |
| `posts_.tsx` | — | Trailing `_` = non-nested (un-nest from parent) |
| `(group)/page.tsx` | `/page` | `()` = organizational group, no URL segment |
| `-components/` | — | Leading `-` = excluded from route generation |
| `$.tsx` | `/*` | Catch-all (splat); remainder at `params._splat` |

`.` in filenames = nesting. `posts.$postId.tsx` ≡ `posts/$postId/index.tsx`.

### Route Definition

```tsx
export const Route = createFileRoute('/posts/$postId')({
  component: PostComponent,
  loader: async ({ params }) => fetchPost(params.postId),
  beforeLoad: async ({ context }) => {
    if (!context.user) throw redirect({ to: '/login' })
  },
  // Zod v4 / Valibot / ArkType implement Standard Schema → pass directly.
  // For Zod v3, wrap with zodValidator from '@tanstack/zod-adapter'.
  validateSearch: z.object({
    tab: z.enum(['info', 'comments']).default('info'),
  }),
  pendingComponent: () => <Spinner />,
  errorComponent: ({ error }) => <ErrorView error={error} />,
  ssr: true,
  head: ({ loaderData }) => ({ meta: [{ title: loaderData.title }] }),
})
```

### Navigation

```tsx
<Link to="/posts/$postId" params={{ postId: '123' }}>View</Link>
<Link to="/posts" search={{ tab: 'comments' }} preload="intent">Comments</Link>

const navigate = useNavigate()
navigate({ to: '/posts', search: { tab: 'info' } })

// Route-scoped accessors are type-safe (Route = the file's createFileRoute export).
const params = Route.useParams()   // typed: { postId: string }
const search = Route.useSearch()   // typed from validateSearch
// From a non-route component: useSearch({ from: '/posts/$postId' })
```

**URL-as-state**: `validateSearch` + `Route.useSearch()` gives type-safe, validated search params. Prefer over client state for shareable/bookmarkable data.

---

## Server Functions

Run only on server. Build replaces with RPC stubs on client. Use for all internal data access.

```tsx
import { z } from 'zod'

// GET — no input
const getUsers = createServerFn({ method: 'GET' })
  .handler(async () => db.query('SELECT * FROM users'))

// POST — Zod validated (pass the schema directly to .inputValidator)
const createPost = createServerFn({ method: 'POST' })
  .inputValidator(z.object({
    title: z.string().min(1),
    content: z.string(),
  }))
  .handler(async ({ data }) => db.insert('posts', data))

// With middleware
const getMyPosts = createServerFn({ method: 'GET' })
  .middleware([authMiddleware])
  .handler(async ({ context }) => db.query('...', [context.user.id]))
```

Call from loaders, components, or other server functions:

```tsx
// In loader
export const Route = createFileRoute('/users')({
  loader: () => getUsers(),
})

// In component — direct call works; useServerFn() (from '@tanstack/react-start')
// is preferred so the call participates in router context
const createPostFn = useServerFn(createPost)
await createPostFn({ data: { title: 'Hello', content: '...' } })
```

Server functions may `throw redirect({ to: '/login' })` or `throw notFound()` (both from `@tanstack/react-router`) — these integrate with the route lifecycle.

**Rule: Server functions are the data layer.** API routes only for webhooks/external consumers.

---

## Middleware

Composable typed context chains. Context propagates through `.middleware([parent])`.

```tsx
const authMiddleware = createMiddleware({ type: 'function' })
  .server(async ({ next }) => {
    const session = await getSession()
    if (!session?.user) throw new Error('Unauthorized')
    return next({ context: { user: session.user } })
  })

// Compose — inherits auth context
const adminMiddleware = createMiddleware({ type: 'function' })
  .middleware([authMiddleware])
  .server(async ({ next, context }) => {
    if (context.user.role !== 'admin') throw new Error('Forbidden')
    return next({ context: { isAdmin: true } })
  })
```

Client → server context (e.g., sending tokens from client storage). `.client()` exists only on `type: 'function'` middleware — the default `'request'` type has `.server()` only:

```tsx
const tokenMiddleware = createMiddleware({ type: 'function' })
  .client(async ({ next }) => next({ sendContext: { token: getToken() } }))
  .server(async ({ next, context }) => {
    verify(context.token)
    return next()
  })
```

Register middleware globally in `src/start.ts`:

```tsx
import { createStart } from '@tanstack/react-start'

export const startInstance = createStart(() => ({
  requestMiddleware: [loggingMiddleware],   // global request middleware
  functionMiddleware: [authMiddleware],     // global server-function middleware
}))
```

Server-function middleware can also validate input via `.inputValidator(schema)` (not `.validator`).

---

## Data Loading

```tsx
export const Route = createFileRoute('/dashboard')({
  beforeLoad: async ({ context }) => {
    const user = await fetchUser()
    if (!user) throw redirect({ to: '/login' })
    return { user }  // adds to context for this route and children
  },
  loader: async ({ context }) => fetchDashboard(context.user.id),
})
```

**Execution order**: `beforeLoad` runs parent → child (sequential). `loader` runs all matched routes in parallel.

Use `beforeLoad` for auth guards and context setup. Use `loader` for data fetching.

Loaders are **isomorphic** — they run on both server (SSR) and client (navigation). Never read secrets / `process.env` directly in a loader; wrap server-only work in a `createServerFn()` and call it from the loader. Loaders also cache: default `staleTime: 0` (revalidates in background on re-entry), default `gcTime: 30min` — set a route `staleTime` before reaching for TanStack Query.

### Selective SSR

| Option | Behavior |
|--------|----------|
| `ssr: true` (default) | Loaders + rendering on server |
| `ssr: 'data-only'` | Loaders on server, rendering on client |
| `ssr: false` | Everything on client |
| `ssr: ({ params, search }) => true \| false \| 'data-only'` | Dynamic per-request (runs server-only, stripped from client bundle) |

Children can only become **more** restrictive. Allowed transitions: `true → data-only`/`false`, `data-only → false`.

Per-route `ssr` needs no global flag. To flip the app-wide default, set `defaultSsr` on the `createStart` instance (`createStart(() => ({ defaultSsr: false }))`). Full SPA mode is a Vite-plugin option: `tanstackStart({ spa: { enabled: true } })`.

---

## Mutations

```tsx
const deletePost = createServerFn({ method: 'POST' })
  .inputValidator(z.object({ id: z.string() }))
  .handler(async ({ data }) => db.delete('posts', data.id))

// In component — invalidate router cache after mutation
const router = useRouter()
await deletePost({ data: { id } })
router.invalidate()
```

For TanStack Query: use `useMutation` with `queryClient.invalidateQueries()`.

---

## State Management

| Need | Solution |
|------|----------|
| Server data (route level) | Route `loader` + `useLoaderData()` |
| Server data (dynamic/cached) | TanStack Query |
| URL state (filters, tabs, pagination) | `validateSearch` + `Route.useSearch()` |
| Form validation | Server function + Zod |
| Complex form (dynamic fields) | TanStack Form → server function |
| Global client state | Zustand |
| Local UI | useState |

---

## Auth Pattern

Session via server function + pathless layout guard. TanStack Start ships a built-in session helper — `useSession` from `@tanstack/react-start/server` (HTTP-only cookie sessions). `getSession()` and `db.*` below are placeholders — wire them to your actual auth and ORM stack.

**Common stacks for the placeholders:**
- Auth: `better-auth`, `clerk`, `workos`, `auth.js`, or your own session store on top of `useSession`
- DB: `drizzle-orm`, `prisma`, `kysely`

```tsx
// features/auth/api/session.ts
const fetchUser = createServerFn({ method: 'GET' })
  .handler(async () => {
    const session = await getSession() // TODO: wire to your auth (better-auth, clerk, workos, ...)
    return session?.user ?? null
  })

// __root.tsx — user in context for all routes
export const Route = createRootRoute({
  beforeLoad: async () => ({ user: await fetchUser() }),
})

// _auth.tsx — pathless guard, all children require auth
export const Route = createFileRoute('/_auth')({
  beforeLoad: ({ context, location }) => {
    // capture the destination so login can send the user back
    if (!context.user) throw redirect({ to: '/login', search: { redirect: location.href } })
  },
  component: () => <Outlet />,
})
```

---

## Deployment

Most targets build through the **Nitro Vite plugin** — `tanstackStart()` takes no preset args:

```ts
// vite.config.ts
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import { nitro } from 'nitro/vite'
import viteReact from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [tanstackStart(), nitro(), viteReact()],
})
```

| Platform | Configuration |
|----------|---------------|
| Node.js | Add the `nitro()` plugin, then `vite build` → `node .output/server/index.mjs` |
| Bun | `nitro({ preset: 'bun' })`; optional Bun-native server (`bun run server.ts`) |
| Vercel | Nitro plugin (auto-detected preset) + one-click deploy. Optionally pin `nitro({ preset: 'vercel' })` |
| Railway / others | Follow the Nitro instructions |
| Cloudflare | `cloudflare({ viteEnvironment: { name: 'ssr' } })` as the **first** plugin + `wrangler.jsonc` (`"main": "@tanstack/react-start/server-entry"`, `"compatibility_flags": ["nodejs_compat"]`). Not Nitro |
| Netlify | `import netlify from '@netlify/vite-plugin-tanstack-start'` → `netlify()`. Not Nitro |

---

## Anti-Patterns

- **API routes for internal data** → server functions (type-safe, no HTTP overhead)
- **Data fetching in `beforeLoad`** → use `loader` (beforeLoad is sequential; loaders are parallel)
- **Skipping `validateSearch`** → always validate search params for type safety
- **Business logic in route files** → routes are thin. Logic in FSD feature/entity layers
- **Client state for URL-worthy data** → `validateSearch` + `Route.useSearch()`
- **`.validator()` / `tanstackStart({ server: { preset } })`** → renamed/removed: use `.inputValidator()` and the Nitro Vite plugin

---

## Checklist

### Architecture
- [ ] FSD layers: no upward imports
- [ ] Route files are thin (import from views/)
- [ ] Server functions in owning slice's api/

### Data
- [ ] Server data via loaders or server functions
- [ ] URL state via validateSearch + Route.useSearch
- [ ] Zod validation on all server function inputs
- [ ] Mutations invalidate router

### SSR
- [ ] Appropriate `ssr` option per route
- [ ] No browser APIs during server render
- [ ] `head()` for SEO on content routes

### Framework-Specific
→ React: `references/react.md`
