# TanStack Start with React

## Table of Contents

1. [Setup](#setup)
2. [TanStack Query Integration](#tanstack-query-integration)
3. [Headless Pattern](#headless-pattern)
4. [Streaming](#streaming)

## Setup

```bash
bun add @tanstack/react-start @tanstack/react-router react react-dom
bun add -d vite @vitejs/plugin-react typescript @types/react @types/react-dom @types/node
# Optional: only if you use zodValidator for route validateSearch (under Zod v4 you can pass the schema directly)
bun add @tanstack/zod-adapter zod
```

**`vite.config.ts`** — the React plugin must come *after* `tanstackStart()`. This is the minimal
framework setup; for production deployment add the `nitro()` plugin (see Deployment in SKILL.md):

```ts
import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import viteReact from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    tanstackStart(),
    viteReact(), // must come after tanstackStart()
  ],
})
```

Scripts: `"dev": "vite dev"`, `"build": "vite build"`. There is no base `start` script — the
production-serve command is deployment-target specific (see Deployment in SKILL.md; e.g. Node via the
Nitro plugin → `node .output/server/index.mjs`).

`src/router.tsx` and `src/routes/__root.tsx` are the two required files. The server entry
(`src/server.ts`) and client entry (`src/client.tsx`) are optional — the Vite plugin provides
defaults if you omit them. Those default entries import a **`getRouter`** factory from
`src/router.tsx`, so the router file must export the factory under exactly that name (see Router below).

Optional TypeScript config: set `"jsx": "react-jsx"` and `"moduleResolution": "Bundler"` in tsconfig,
and enable path aliases with `resolve: { tsconfigPaths: true }` in `vite.config.ts`.

### Router

```tsx
// src/router.tsx
import { createRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

// MUST be exported as `getRouter` — the framework's default server/client
// entries import this exact name. Exporting `createRouter` is a build error.
export function getRouter() {
  return createRouter({ routeTree, scrollRestoration: true })
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof getRouter>
  }
}
```

### Root Layout

```tsx
// src/routes/__root.tsx
import { Outlet, createRootRoute, HeadContent, Scripts } from '@tanstack/react-router'

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
    ],
  }),
  component: () => (
    <html>
      <head>
        <HeadContent />
      </head>
      <body>
        <Outlet />
        <Scripts />
      </body>
    </html>
  ),
})
```

---

## TanStack Query Integration

Install `@tanstack/react-query` + `@tanstack/react-router-ssr-query`, then wire SSR caching with
`setupRouterSsrQueryIntegration` (a side-effect call — it does NOT wrap the router):

```tsx
// src/router.tsx
import { createRouter } from '@tanstack/react-router'
import { setupRouterSsrQueryIntegration } from '@tanstack/react-router-ssr-query'
import { QueryClient } from '@tanstack/react-query'
import { routeTree } from './routeTree.gen'

export function getRouter() {
  const queryClient = new QueryClient()
  const router = createRouter({
    routeTree,
    scrollRestoration: true,
    context: { queryClient },
  })
  setupRouterSsrQueryIntegration({ router, queryClient })
  return router
}
```

Ensure data in the loader (awaited), consume with `useSuspenseQuery`:

```tsx
// Route — await ensureQueryData so the suspense query has data during SSR
export const Route = createFileRoute('/posts')({
  loader: async ({ context }) => {
    await context.queryClient.ensureQueryData(postsQueryOptions())
  },
  component: PostsPage,
})

// Component
function PostsPage() {
  const { data: posts } = useSuspenseQuery(postsQueryOptions())
  return <PostList posts={posts} />
}
```

> Use awaited `ensureQueryData`, not fire-and-forget `prefetchQuery` — `useSuspenseQuery` suspends
> until data is cached, and an unawaited prefetch does not guarantee it's present during SSR.

Query options in entity/feature `api/`:

```tsx
// entities/post/api/queries.ts
export const postsQueryOptions = () =>
  queryOptions({
    queryKey: ['posts'],
    queryFn: () => getPosts(),
  })

export const postQueryOptions = (id: string) =>
  queryOptions({
    queryKey: ['posts', id],
    queryFn: () => getPost({ data: { id } }),
  })
```

Mutations with cache invalidation:

```tsx
const { mutateAsync } = useMutation({
  mutationFn: (data) => createPost({ data }),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['posts'] }),
})
```

---

## Headless Pattern

Logic in hooks, components do composition only:

```tsx
// features/products/hooks/useProductFilters.ts
export function useProductFilters() {
  const search = Route.useSearch()
  const navigate = useNavigate()
  const setFilter = (key: string, value: string) =>
    navigate({ search: (prev) => ({ ...prev, [key]: value }) })

  return { filters: search, setFilter }
}

// views/products/index.tsx — composition only
function ProductsPage() {
  const { filters, setFilter } = useProductFilters()
  return (
    <div>
      <FilterBar filters={filters} onChange={setFilter} />
      <Suspense fallback={<Skeleton />}>
        <ProductGrid />
      </Suspense>
    </div>
  )
}
```

---

## Streaming

Suspense boundaries for parallel loading — each child loads independently:

```tsx
function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsPanel />
      </Suspense>
      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />
      </Suspense>
    </div>
  )
}
```
