---
name: tanstack-start
description: |
  TanStack Start full-stack framework — file-based routing, server functions, middleware, SSR.
  Supports React (`@tanstack/react-start`) and SolidJS (`@tanstack/solid-start`).
  Use when: building full-stack apps with TanStack Start, using TanStack Router file-based routing,
  writing createServerFn or createMiddleware, deploying TanStack Start apps.
  Also use when user mentions TanStack Start, TanStack Router, or @tanstack/solid-start.
  Do not use for: Next.js (use nextjs skill), standalone SolidJS without TanStack Start.
  For React-specific patterns, also read `references/react.md`.
  For SolidJS-specific patterns, also read `references/solidjs.md`.
references:
  - references/react.md
  - references/solidjs.md
---

# TanStack Start

Explicit over magic. End-to-end type safety. URL as first-class state.

**Package manager**: `bun`.
**Packages**: `@tanstack/{react,solid}-start` + `@tanstack/{react,solid}-router` + `@tanstack/zod-adapter` + `zod`.
APIs are identical between React and SolidJS — only import source differs.

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
| `_auth.tsx` | — | Pathless layout (no URL segment) |
| `_auth/dashboard.tsx` | `/dashboard` | Under pathless layout |
| `$.tsx` | `/*` | Catch-all |

`.` in filenames = nesting. `posts.$postId.tsx` ≡ `posts/$postId/index.tsx`.

### Route Definition

```tsx
export const Route = createFileRoute('/posts/$postId')({
  component: PostComponent,
  loader: async ({ params }) => fetchPost(params.postId),
  beforeLoad: async ({ context }) => {
    if (!context.user) throw redirect({ to: '/login' })
  },
  validateSearch: zodValidator(z.object({
    tab: z.enum(['info', 'comments']).default('info'),
  })),
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

const params = useParams()   // typed: { postId: string }
const search = useSearch()   // typed from validateSearch
```

**URL-as-state**: `validateSearch` + `useSearch()` gives type-safe, validated search params. Prefer over client state for shareable/bookmarkable data.

---

## Server Functions

Run only on server. Build replaces with RPC stubs on client. Use for all internal data access.

```tsx
import { zodValidator } from '@tanstack/zod-adapter'

// GET — no input
const getUsers = createServerFn({ method: 'GET' })
  .handler(async () => db.query('SELECT * FROM users'))

// POST — Zod validated
const createPost = createServerFn({ method: 'POST' })
  .validator(zodValidator(z.object({
    title: z.string().min(1),
    content: z.string(),
  })))
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

// In component
await createPost({ data: { title: 'Hello', content: '...' } })
```

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

Client → server context (e.g., sending tokens from client storage):

```tsx
const tokenMiddleware = createMiddleware()
  .client(async ({ next }) => next({ sendContext: { token: getToken() } }))
  .server(async ({ next, context }) => {
    verify(context.token)
    return next()
  })
```

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

### Selective SSR

| Option | Behavior |
|--------|----------|
| `ssr: true` (default) | Loaders + rendering on server |
| `ssr: 'data-only'` | Loaders on server, rendering on client |
| `ssr: false` | Everything on client |
| `ssr: (ctx) => boolean` | Dynamic per-request |

Children cannot be less restrictive than parents.

---

## Mutations

```tsx
const deletePost = createServerFn({ method: 'POST' })
  .validator(zodValidator(z.object({ id: z.string() })))
  .handler(async ({ data }) => db.delete('posts', data.id))

// In component — invalidate router cache after mutation
const router = useRouter()
await deletePost({ data: { id } })
router.invalidate()
```

For TanStack Query: use `useMutation` (React) / `createMutation` (Solid) with `queryClient.invalidateQueries()`.

---

## State Management

| Need | Solution |
|------|----------|
| Server data (route level) | Route `loader` + `useLoaderData()` |
| Server data (dynamic/cached) | TanStack Query |
| URL state (filters, tabs, pagination) | `validateSearch` + `useSearch()` |
| Form validation | Server function + Zod |
| Complex form (dynamic fields) | TanStack Form → server function |
| Global client state | Zustand (React) / createStore (SolidJS) |
| Local UI | useState (React) / createSignal (SolidJS) |

---

## Auth Pattern

Session via server function + pathless layout guard:

```tsx
// features/auth/api/session.ts
const fetchUser = createServerFn({ method: 'GET' })
  .handler(async () => {
    const session = await getSession()
    return session?.user ?? null
  })

// __root.tsx — user in context for all routes
export const Route = createRootRoute({
  beforeLoad: async () => ({ user: await fetchUser() }),
})

// _auth.tsx — pathless guard, all children require auth
export const Route = createFileRoute('/_auth')({
  beforeLoad: ({ context }) => {
    if (!context.user) throw redirect({ to: '/login' })
  },
  component: () => <Outlet />,
})
```

---

## Deployment

| Platform | Configuration |
|----------|---------------|
| Node.js | Default. `bun run build && node .output/server/index.mjs` |
| Bun | Native support |
| Vercel | `tanstackStart({ server: { preset: 'vercel' } })` in vite config |
| Cloudflare | Add `@cloudflare/vite-plugin`, `cloudflare()` in vite plugins |
| Netlify | Add `@netlify/vite-plugin-tanstack-start` |

---

## Anti-Patterns

- **API routes for internal data** → server functions (type-safe, no HTTP overhead)
- **Data fetching in `beforeLoad`** → use `loader` (beforeLoad is sequential; loaders are parallel)
- **Skipping `validateSearch`** → always validate search params for type safety
- **Business logic in route files** → routes are thin. Logic in FSD feature/entity layers
- **Client state for URL-worthy data** → `validateSearch` + `useSearch()`

---

## Checklist

### Architecture
- [ ] FSD layers: no upward imports
- [ ] Route files are thin (import from views/)
- [ ] Server functions in owning slice's api/

### Data
- [ ] Server data via loaders or server functions
- [ ] URL state via validateSearch + useSearch
- [ ] Zod validation on all server function inputs
- [ ] Mutations invalidate router

### SSR
- [ ] Appropriate `ssr` option per route
- [ ] No browser APIs during server render
- [ ] `head()` for SEO on content routes

### Framework-Specific
→ React: `references/react.md`
→ SolidJS: `references/solidjs.md`
