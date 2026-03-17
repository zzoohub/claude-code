# TanStack Start with SolidJS

> `@tanstack/solid-start` — functional but less documented than React adapter.

## Setup

```bash
bun add @tanstack/solid-start @tanstack/solid-router solid-js @tanstack/zod-adapter zod
bun add -d typescript vite vite-plugin-solid vite-tsconfig-paths
```

**`vite.config.ts`** — plugin order is CRITICAL:

```ts
import { defineConfig } from 'vite'
import tsConfigPaths from 'vite-tsconfig-paths'
import { tanstackStart } from '@tanstack/solid-start/plugin/vite'
import viteSolid from 'vite-plugin-solid'

export default defineConfig({
  plugins: [
    tsConfigPaths(),
    tanstackStart(),
    viteSolid({ ssr: true }),  // MUST be after tanstackStart()
  ],
})
```

tsconfig: `"jsx": "preserve"`, `"jsxImportSource": "solid-js"`.
Scripts: `"dev": "vite dev"`, `"build": "vite build"`, `"start": "node .output/server/index.mjs"`.

### Entry Files

SolidJS adapter requires explicit `ssr.tsx`:

```tsx
// src/ssr.tsx
import { createStartHandler, defaultStreamHandler } from '@tanstack/solid-start/server'
import { getRouter } from './router'

export default createStartHandler({ getRouter })(defaultStreamHandler)
```

### Router

```tsx
// src/router.tsx
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

### Root Layout

```tsx
// src/routes/__root.tsx
import { Suspense } from 'solid-js'
import { Outlet, createRootRoute, HeadContent, Scripts } from '@tanstack/solid-router'
import { HydrationScript } from 'solid-js/web'

export const Route = createRootRoute({
  component: () => (
    <html>
      <head>
        <HydrationScript />  {/* Required for SolidJS SSR */}
        <HeadContent />
      </head>
      <body>
        <Suspense>
          <Outlet />
        </Suspense>
        <Scripts />
      </body>
    </html>
  ),
})
```

---

## Reactivity Rules

Components are **setup functions that run once**. No re-renders — only reactive subscriptions update.

**Signals** — always call the getter:

```tsx
const [count, setCount] = createSignal(0)
count()  // must call — count without () is the getter function itself
```

**Derived** — plain function for cheap, `createMemo` when expensive or read multiple times:

```tsx
const doubled = () => count() * 2
const filtered = createMemo(() => heavyFilter(items()))
```

**Effects** — `onCleanup` MUST be called before any `await`:

```tsx
createEffect(async () => {
  const ctrl = new AbortController()
  onCleanup(() => ctrl.abort())  // before await!
  const data = await fetch(url(), { signal: ctrl.signal })
  setResult(data)
})
```

**Loader data returns an accessor**:

```tsx
const data = Route.useLoaderData()
data().title  // call data() first, then access properties
```

---

## Props — Never Destructure

Props are reactive getters. Destructuring reads once and kills reactivity.

```tsx
// WRONG
function Card({ title }) { return <h2>{title}</h2> }

// CORRECT
function Card(props) { return <h2>{props.title}</h2> }
```

- `mergeProps({ size: 'md' }, props)` — defaults
- `splitProps(props, ['label', 'error'])` — separate local from forwarded
- `children(() => props.children)` — resolve/memoize children

---

## Control Flow

Built-in components create proper reactive boundaries:

```tsx
<Show when={user()} fallback={<Login />}>
  {(u) => <p>{u().name}</p>}
</Show>

<For each={items()}>           {/* Objects — keyed by reference */}
  {(item, i) => <div>{i()}: {item.name}</div>}
</For>

<Index each={numbers()}>       {/* Primitives — keyed by index */}
  {(num, i) => <div>{i}: {num()}</div>}
</Index>

<Switch fallback={<NotFound />}>
  <Match when={loading()}><Spinner /></Match>
  <Match when={error()}><Error /></Match>
</Switch>
```

`<For>` for objects (item is value, index is signal). `<Index>` for primitives (item is signal, index is number).

---

## Stores

Nested/complex state with fine-grained subscriptions:

```tsx
const [store, setStore] = createStore({
  user: { name: 'Alice' },
  todos: [{ id: 1, text: 'Learn', done: false }],
})

setStore('user', 'name', 'Bob')              // path setter
setStore('todos', 0, 'done', true)           // nested path
setStore(produce(d => d.todos.push(item)))   // Immer-style
setStore('todos', reconcile(await fetch()))  // minimal diff with API data
```

Signal for primitives or objects replaced wholesale. Store for nested objects with partial updates.

---

## JSX-as-Props Hydration Bug (CRITICAL)

**Rule: Always wrap JSX props in arrow functions. Never pass JSX directly.**

```tsx
// BAD — hydration mismatch → "template2 is not a function" in dev, silent DOM corruption in prod
<Button icon={<Icon />} />

// GOOD
<Button icon={() => <Icon />} />
```

### Why

SSR compiler wraps JSX props in lazy getters — evaluated inside parent context, hydration key assigned in sequence. Client compiler evaluates eagerly — before parent body — shifting key order. Result: server HTML keys don't match client expectations.

**Worse when prop is accessed multiple times** — each getter call re-creates the element with a new hydration key:

```tsx
// Two accesses to props.icon = two different elements with different keys
<Show when={props.icon}>      {/* access #1 */}
  <span>{props.icon}</span>   {/* access #2 — different element! */}
</Show>
```

### Receiving Side

Resolve with `children()` helper to memoize:

```tsx
import { children } from 'solid-js'

function Button(props) {
  const icon = children(() => props.icon)  // memoize once
  return (
    <button>
      <Show when={icon()}>
        <span>{icon()}</span>  {/* safe — same memoized element */}
      </Show>
      Click
    </button>
  )
}
```

Check prop existence without triggering the getter:

```tsx
// BAD — evaluates the getter, causes hydration issue
<div classList={{ 'has-icon': !!props.icon }}>

// GOOD — checks property existence without calling
<div classList={{ 'has-icon': 'icon' in props }}>
```

### Scope

- Affects **all SolidJS SSR frameworks** (SolidStart, TanStack Start, Astro+Solid)
- `"template2 is not a function"` appears in **dev mode only**
- Production: **silent DOM corruption** (missing/duplicated elements)
- Root cause in SolidJS compiler (`babel-plugin-jsx-dom-expressions`), fix planned for **SolidJS 2.0**
- Known issues: solidjs/solid#2023, #1485, #1729, #2100

---

## TanStack Query (SolidJS)

Options must be wrapped in a callback for reactivity:

```tsx
import { createQuery } from '@tanstack/solid-query'

const query = createQuery(() => ({
  queryKey: ['posts'],
  queryFn: () => getPosts(),
}))

// query.data — no () needed (TanStack Query manages reactivity internally)
```

`createQuery(() => ({...}))` not `useQuery({...})`. The callback wrapper makes options reactive.

---

## Pitfalls Checklist

1. **Destructuring props** → kills reactivity. Use `mergeProps`, `splitProps`, direct access
2. **JSX as props without arrow function** → hydration mismatch. Always `icon={() => <JSX />}`
3. **Reading signals outside tracking scope** → stale value forever
4. **Setting signals in effects** → usually should be `createMemo`
5. **`onChange` for text input** → fires on blur in SolidJS. Use `onInput`
6. **`event.stopPropagation()` on delegated events** → use `on:click` for native attachment
7. **Conditionals without control flow** → `&&` doesn't create reactive boundaries. Use `<Show>`
8. **Module-level singletons with SSR** → shared between requests. Use Context
9. **`onCleanup` after `await`** → async breaks tracking scope. Call before any await
10. **Accessing loader data directly** → `useLoaderData()` returns accessor. Call `data().field`
