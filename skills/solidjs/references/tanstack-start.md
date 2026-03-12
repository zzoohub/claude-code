# TanStack Start with SolidJS

> `@tanstack/solid-start` — Full-stack framework built on TanStack Router + Vite.
> SolidJS support is **experimental** (functional but less documented than React adapter).

---

## Project Setup

### Quick Start

```bash
bunx @tanstack/create-start@latest --framework solid --package-manager bun
```

### Manual Setup

```bash
mkdir my-app && cd my-app
bun init
bun add @tanstack/solid-start @tanstack/solid-router solid-js vite vite-plugin-solid
bun add -d typescript vite-tsconfig-paths
```

**`vite.config.ts`** — solid's vite plugin MUST come after start's:

```typescript
import { defineConfig } from 'vite'
import tsConfigPaths from 'vite-tsconfig-paths'
import { tanstackStart } from '@tanstack/solid-start/plugin/vite'
import viteSolid from 'vite-plugin-solid'

export default defineConfig({
  server: { port: 3000 },
  plugins: [
    tsConfigPaths(),
    tanstackStart(),
    viteSolid({ ssr: true }), // MUST be after tanstackStart()
  ],
})
```

tsconfig: `"jsx": "preserve"`, `"jsxImportSource": "solid-js"`, `"moduleResolution": "Bundler"`. Scripts: `"dev": "vite dev"`, `"build": "vite build"`, `"start": "node .output/server/index.mjs"`.

---

## Project Structure (FSD)

Follow Feature-Sliced Design. Key points for TanStack Start + FSD:
- Route files are thin wrappers — routing concerns only (loader, beforeLoad, head). UI goes in `views/`.
- `createServerFn` lives in the `api/` segment of the slice that owns the data (e.g., `entities/post/api/`, `features/auth/api/`).
- API routes in `routes/api/` delegate to slice server functions when logic is involved.

```
src/
├── app/                        # Providers, global styles, initialization
│   ├── providers.tsx
│   └── styles.css
├── routes/                     # TanStack file-based routing (thin wrappers)
│   ├── __root.tsx              # Root layout — imports from app/providers
│   ├── index.tsx               # / — imports from views/
│   ├── [route].tsx             # Static or layout route
│   ├── [route].$param.tsx      # Dynamic route — imports from views/
│   ├── _[layout].tsx           # Pathless layout guard
│   └── api/
│       └── [endpoint].ts       # API route
├── views/                      # Full page layouts (compose widgets + features)
│   └── [view]/
│       └── index.tsx
├── widgets/                    # Standalone UI sections (compose features + entities)
│   └── [widget]/
│       └── index.ts
├── features/                   # User interactions
│   └── [feature]/
│       ├── ui/
│       ├── model/
│       ├── api/                # Server functions (createServerFn)
│       └── index.ts
├── entities/                   # Business objects
│   └── [entity]/
│       ├── ui/
│       ├── model/
│       ├── api/                # Server functions for CRUD
│       └── index.ts
├── shared/                     # ui/, api/, lib/, hooks/, stores/, types/, constants/
├── router.tsx
├── ssr.tsx
└── routeTree.gen.ts            # Auto-generated (DO NOT EDIT)
```

### Entry Files

**`src/router.tsx`**:

```typescript
import { createRouter } from '@tanstack/solid-router'
import { routeTree } from './routeTree.gen'

export function getRouter() {
  return createRouter({ routeTree, scrollRestoration: true })
}

declare module '@tanstack/solid-router' {
  interface Register {
    router: ReturnType<typeof getRouter>
  }
}
```

**`src/ssr.tsx`**:

```typescript
import { getRouter } from './router'
import { createStartHandler, defaultStreamHandler } from '@tanstack/solid-start/server'

export default createStartHandler({ getRouter })(defaultStreamHandler)
```

**`src/routes/__root.tsx`**:

```tsx
/// <reference types="vite/client" />
import * as Solid from 'solid-js'
import { Outlet, createRootRoute, HeadContent, Scripts } from '@tanstack/solid-router'
import { HydrationScript } from 'solid-js/web'
import { Providers } from '~/app/providers'
import '~/app/styles.css'

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { title: 'My App' },
    ],
  }),
  component: RootComponent,
})

function RootComponent() {
  return (
    <html>
      <head>
        <HydrationScript />
      </head>
      <body>
        <HeadContent />
        <Providers>
          <Solid.Suspense>
            <Outlet />
          </Solid.Suspense>
        </Providers>
        <Scripts />
      </body>
    </html>
  )
}
```

---

## File-Based Routing

### File Conventions

| File Path | URL |
|---|---|
| `routes/__root.tsx` | Root layout (wraps everything) |
| `routes/index.tsx` | `/` |
| `routes/about.tsx` | `/about` |
| `routes/posts.tsx` | `/posts` layout |
| `routes/posts.index.tsx` | `/posts` index page |
| `routes/posts.$postId.tsx` | `/posts/:postId` |
| `routes/users/$id.tsx` | `/users/:id` |
| `routes/api/file/$.tsx` | `/api/file/*` (catch-all) |
| `routes/_auth.tsx` | Pathless layout (no URL segment) |
| `routes/_auth/dashboard.tsx` | `/dashboard` (under auth layout) |

### Route Definition

```tsx
import { createFileRoute } from '@tanstack/solid-router'

export const Route = createFileRoute('/posts/$postId')({
  component: PostComponent,
  loader: async ({ params }) => await fetchPost(params.postId),
  beforeLoad: async ({ context }) => { /* auth checks, redirects */ },
  validateSearch: (search) => ({ page: Number(search.page) || 1 }),
  pendingComponent: () => <div>Loading...</div>,
  errorComponent: ({ error }) => <div>Error: {error.message}</div>,
  notFoundComponent: () => <div>Not Found</div>,
  ssr: true, // true | false | 'data-only' | ((ctx) => boolean)
  head: () => ({ meta: [{ title: 'Post' }] }),
})

function PostComponent() {
  const post = Route.useLoaderData()
  return <div>{post().title}</div>
}
```

### Navigation & Hooks

```tsx
import { Link, useNavigate, useParams, useLocation, useSearch } from '@tanstack/solid-router'

<Link to="/posts/$postId" params={{ postId: '123' }}>View Post</Link>

const navigate = useNavigate()
navigate({ to: '/posts', search: { page: 2 } })

const params = useParams()       // { id: "123" }
const location = useLocation()   // { pathname, search, hash }
const search = useSearch()       // typed search params
```

---

## Server Functions

Run only on the server. Called from both server (SSR) and client code.

```typescript
import { createServerFn } from '@tanstack/solid-start'
import { z } from 'zod'

// GET — no input
const getUsers = createServerFn({ method: 'GET' }).handler(async () => {
  return await db.query('SELECT * FROM users')
})

// POST — with Zod validation
const createPost = createServerFn({ method: 'POST' })
  .inputValidator(z.object({ title: z.string().min(1), content: z.string() }))
  .handler(async ({ data }) => {
    return await db.insert('posts', data)
  })

// Calling: in components or route loaders
await createPost({ data: { title: 'Hello', content: '...' } })

export const Route = createFileRoute('/users')({
  loader: async () => await getUsers(),
})
```

---

## Data Loading

Route loaders call server functions. Use `Route.useLoaderData()` in components.

```tsx
export const Route = createFileRoute('/dashboard')({
  beforeLoad: async ({ context }) => {
    const user = await fetchUser()
    if (!user) throw redirect({ to: '/login' })
    return { user }
  },
  loader: async ({ context }) => await fetchDashboardData(context.user.id),
  component: Dashboard,
})

function Dashboard() {
  const data = Route.useLoaderData()
  return <For each={data().items}>{(item) => <div>{item.name}</div>}</For>
}
```

SSR control per-route: `ssr: true` (default) | `false` (client-only) | `'data-only'` (loader on server, component on client) | `((ctx) => boolean)`.

### TanStack Query Integration

```tsx
import { createQuery } from '@tanstack/solid-query'

function PostsList() {
  const query = createQuery(() => ({
    queryKey: ['posts'],
    queryFn: () => fetchPosts(),
  }))

  return (
    <Show when={query.data}>
      {(posts) => <For each={posts()}>{(p) => <div>{p.title}</div>}</For>}
    </Show>
  )
}
```

---

## Mutations & Forms

```tsx
import { useRouter } from '@tanstack/solid-router'

// Server function for mutation
const deletePost = createServerFn({ method: 'POST' })
  .inputValidator((d: { id: string }) => d)
  .handler(async ({ data }) => { await db.delete('posts', data.id) })

// Invalidate router after mutation
function DeleteButton(props: { postId: string }) {
  const router = useRouter()
  return (
    <button onClick={() => deletePost({ data: { id: props.postId } }).then(() => router.invalidate())}>
      Delete
    </button>
  )
}
```

For TanStack Query mutations, use `createMutation` with `queryClient.invalidateQueries()` on success.

---

## Middleware

```typescript
import { createMiddleware } from '@tanstack/solid-start'

// Auth middleware — adds typed context
const authMiddleware = createMiddleware({ type: 'function' })
  .server(async ({ next }) => {
    const session = await getSession()
    if (!session?.user) throw new Error('Unauthorized')
    return next({ context: { user: session.user } })
  })

// Composing — adminMiddleware depends on authMiddleware
const adminMiddleware = createMiddleware({ type: 'function' })
  .middleware([authMiddleware])
  .server(async ({ next, context }) => {
    if (context.user.role !== 'admin') throw new Error('Forbidden')
    return next({ context: { isAdmin: true } })
  })

// Apply to server functions
const getProtectedData = createServerFn({ method: 'GET' })
  .middleware([authMiddleware])
  .handler(async ({ context }) => {
    return await db.query('SELECT * FROM data WHERE userId = ?', [context.user.id])
  })

// Client → Server context (e.g., sending auth tokens)
const tokenMiddleware = createMiddleware()
  .client(async ({ next }) => {
    return next({ sendContext: { authToken: getAuthToken() } })
  })
  .server(async ({ next, context }) => {
    // context.authToken available
    return next()
  })
```

---

## API Routes

```typescript
// src/routes/api/users/$id.ts
import { createAPIFileRoute } from '@tanstack/solid-start/api'

export const APIRoute = createAPIFileRoute('/api/users/$id')({
  GET: async ({ params }) => {
    const user = await db.findById('users', params.id)
    return Response.json(user)
  },
  POST: async ({ request }) => {
    const body = await request.json()
    const user = await db.update('users', params.id, body)
    return Response.json(user)
  },
})
```

---

## SSR & Hydration

TanStack Start uses streaming SSR by default (`defaultStreamHandler`). Loader data is serialized and embedded in HTML.

**Avoiding hydration mismatches:**
- Don't use `Date.now()` / `Math.random()` during render
- Don't access `window`/`document` during server render
- Include `<HydrationScript />` in `<head>`, wrap children in `<Suspense>`

---

## Authentication

### Session-Based (Cookies)

```typescript
import { useSession } from 'vinxi/http'

type SessionData = { userEmail?: string }

function useAppSession() {
  return useSession<SessionData>({ password: process.env.SESSION_SECRET! })
}

const fetchUser = createServerFn({ method: 'GET' }).handler(async () => {
  const session = await useAppSession()
  if (!session.data.userEmail) return null
  return { email: session.data.userEmail }
})

export const Route = createRootRoute({
  beforeLoad: async () => {
    const user = await fetchUser()
    return { user }
  },
})
```

### Pathless Layout Auth Guard

```typescript
// src/routes/_authenticated.tsx — all child routes require auth
export const Route = createFileRoute('/_authenticated')({
  beforeLoad: async ({ context }) => {
    if (!context.user) throw redirect({ to: '/login' })
  },
  component: () => <Outlet />,
})
```

---

## Deployment

| Platform | Configuration |
|---|---|
| **Node.js** | Default. `bun run build && node .output/server/index.mjs` |
| **Bun** | Native support |
| **Vercel** | `tanstackStart({ server: { preset: 'vercel' } })` |
| **Cloudflare** | `bun add @cloudflare/vite-plugin wrangler`, add `cloudflare()` to vite plugins |

---

## TanStack Start vs SolidStart

| Aspect | TanStack Start | SolidStart |
|---|---|---|
| Router | TanStack Router (fully type-safe) | Solid Router |
| Data loading | Route loaders + `createServerFn` | `createResource`, `"use server"` |
| Type safety | End-to-end inference (routes, params, search) | Good but less comprehensive |
| Middleware | `createMiddleware` composable chains | Vinxi/Nitro middleware |
| Maturity | RC / Experimental for Solid | Stable (1.x) |
| Ecosystem | TanStack Query, Form, Table integration | SolidJS ecosystem |

**Choose TanStack Start when**: you need maximum type safety, incremental adoption, or TanStack ecosystem integration.

**Choose SolidStart when**: you need production stability or SolidJS-native patterns.
