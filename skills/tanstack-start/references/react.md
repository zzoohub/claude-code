# TanStack Start with React

## Setup

```bash
bun add @tanstack/react-start @tanstack/react-router @tanstack/zod-adapter zod
bun add -d typescript vite
```

**`vite.config.ts`**:

```ts
import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'

export default defineConfig({
  plugins: [tanstackStart()],
})
```

Scripts: `"dev": "vite dev"`, `"build": "vite build"`, `"start": "node .output/server/index.mjs"`.

No additional entry files needed — the Vite plugin handles SSR and client entry automatically.

### Router

```tsx
// src/router.tsx
import { createRouter as createTanStackRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

export function createRouter() {
  return createTanStackRouter({ routeTree, scrollRestoration: true })
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof createRouter>
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

Use `routerWithQueryClient` for router-integrated caching:

```tsx
// src/router.tsx
import { routerWithQueryClient } from '@tanstack/react-router-with-query'
import { QueryClient } from '@tanstack/react-query'

export function createRouter() {
  const queryClient = new QueryClient()
  return routerWithQueryClient(
    createTanStackRouter({
      routeTree,
      scrollRestoration: true,
      context: { queryClient },
    }),
    queryClient,
  )
}
```

Prefetch in loader, consume with `useSuspenseQuery`:

```tsx
// Route
export const Route = createFileRoute('/posts')({
  loader: ({ context }) => {
    context.queryClient.prefetchQuery(postsQueryOptions())
  },
  component: PostsPage,
})

// Component
function PostsPage() {
  const { data: posts } = useSuspenseQuery(postsQueryOptions())
  return <PostList posts={posts} />
}
```

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
