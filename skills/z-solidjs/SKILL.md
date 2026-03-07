---
name: z-solidjs
description: |
  SolidJS application development — fine-grained reactivity, component patterns, stores, TypeScript, and performance optimization.
  Use this skill whenever writing SolidJS code, building SolidJS components, debugging SolidJS reactivity issues, or migrating from React to SolidJS.
  Also use when the user mentions signals, createSignal, createEffect, createStore, SolidJS routing, or any SolidJS-specific API.
  When using TanStack Start as the framework, also read `references/tanstack-start.md` for framework-specific patterns.
---

# SolidJS

SolidJS uses **fine-grained reactivity** — no virtual DOM, no re-renders. Components are **setup functions that run once**. Only the specific DOM nodes or computations that depend on a changed signal update. This is the fundamental mental model that drives every pattern below.

## Reactivity Fundamentals

### Signals

```tsx
import { createSignal } from "solid-js"

const [count, setCount] = createSignal(0)
count()              // read (getter function — must call it)
setCount(5)          // set directly
setCount(c => c + 1) // set with previous value
```

- `equals: false` option forces updates even when value is same
- Custom equality: `{ equals: (a, b) => a.id === b.id }`

### Derived Values

Default choice — a plain function that reads signals. Zero overhead, evaluated lazily on each access:

```tsx
const doubled = () => count() * 2
```

Use `createMemo` only when the computation is expensive, read in multiple places, or you need to filter downstream updates when the result hasn't changed:

```tsx
const filtered = createMemo(() => items().filter(expensiveFilter))
```

### Effects

```tsx
createEffect(() => {
  console.log("Count is", count()) // auto-tracks count
})
```

- Runs **after DOM creation** (before paint)
- Auto-tracks all signals read inside
- Use `onCleanup` for teardown — must be called **before** any `await`:

```tsx
createEffect(async () => {
  const controller = new AbortController()
  onCleanup(() => controller.abort()) // before await!
  const data = await fetchData(id(), { signal: controller.signal })
  setResult(data)
})
```

**Do not set signals inside effects when a memo would suffice.** If an effect exists only to derive state, replace it with `createMemo`.

### Lifecycle

```tsx
onMount(() => { /* once, after initial render, non-tracking */ })
onCleanup(() => { /* when owning scope disposes */ })
```

### Batch & Untrack

```tsx
batch(() => {
  setName("Alice")
  setAge(30)
  // downstream computations run once, not twice
})

createEffect(() => {
  console.log(count(), untrack(() => name())) // name not tracked
})
```

### Explicit Dependencies with `on`

```tsx
createEffect(on(count, (value, prev) => {
  console.log("count changed from", prev, "to", value)
}, { defer: true })) // skip first run
```

### Ownership (critical for async)

```tsx
const owner = getOwner()

setTimeout(() => {
  runWithOwner(owner, () => {
    createEffect(() => { /* properly owned, can be cleaned up */ })
  })
}, 1000)
```

Computations without an owner cannot be disposed — `useContext` also walks the owner tree.

## Props — Never Destructure

Props are reactive getters on an object. Destructuring evaluates them once and kills reactivity, because the component function only runs once.

```tsx
// WRONG — reactivity lost
function Greeting({ name }) { return <h1>Hello {name}</h1> }
function Greeting(props) { const { name } = props; ... }

// CORRECT — reactive access
function Greeting(props) { return <h1>Hello {props.name}</h1> }
```

### mergeProps (defaults)

```tsx
const merged = mergeProps({ variant: "primary", size: "md" }, props)
```

### splitProps (separate local vs forwarded)

```tsx
const [local, inputProps] = splitProps(props, ["label", "error"])
return (
  <div>
    <label>{local.label}</label>
    <input {...inputProps} />
  </div>
)
```

### children() helper

Use when you need to inspect or manipulate resolved children:

```tsx
import { children } from "solid-js"

function Wrapper(props) {
  const resolved = children(() => props.children) // "double function" pattern
  return <div>{resolved()}</div>
}
```

## Control Flow

Always use built-in control flow — they create proper reactive boundaries and handle cleanup.

```tsx
// Conditional
<Show when={user()} fallback={<p>Loading...</p>}>
  {(u) => <p>Hello {u().name}</p>}
</Show>

// List of objects (keyed by reference)
<For each={todos()}>
  {(todo, index) => <li>{index()}: {todo.text}</li>}
</For>

// List of primitives (keyed by index)
<Index each={numbers()}>
  {(num, index) => <li>{index}: {num()}</li>}
</Index>

// Pattern matching
<Switch fallback={<p>Not found</p>}>
  <Match when={state() === "loading"}><Spinner /></Match>
  <Match when={state() === "error"}><ErrorView /></Match>
  <Match when={state() === "ready"}><Content /></Match>
</Switch>

// Dynamic component
<Dynamic component={isAdmin() ? AdminPanel : UserPanel} />

// Portal
<Portal mount={document.getElementById("modal-root")!}>
  <Modal />
</Portal>

// Error boundary + Suspense
<ErrorBoundary fallback={(err, reset) => <div><p>{err.message}</p><button onClick={reset}>Retry</button></div>}>
  <Suspense fallback={<Spinner />}>
    <AsyncContent />
  </Suspense>
</ErrorBoundary>
```

**`<For>` vs `<Index>`**: Use `<For>` for objects (item is value, index is signal). Use `<Index>` for primitives (item is signal, index is number).

## Stores

For nested/complex state. Each property access creates a fine-grained subscription.

```tsx
import { createStore, produce, reconcile, unwrap } from "solid-js/store"

const [store, setStore] = createStore({
  user: { name: "Alice", age: 30 },
  todos: [{ id: 1, text: "Learn Solid", done: false }],
})

// Path-based setter
setStore("user", "name", "Bob")
setStore("todos", 0, "done", true)
setStore("user", "age", a => a + 1)

// Filter function (update matching items)
setStore("todos", todo => todo.done, "text", t => t + " ✓")

// Immer-style mutations
setStore(produce(draft => {
  draft.user.name = "Jane"
  draft.todos.push({ id: 2, text: "Deploy", done: false })
}))

// Replace with API data (minimal diff)
setStore("todos", reconcile(await fetchTodos()))

// Get plain JS object (for serialization / third-party libs)
const raw = unwrap(store)
```

**Signal vs Store**: Use signals for primitives or objects replaced wholesale. Use stores for nested objects with partial updates.

## JSX Differences from React

### Events

```tsx
// Delegated (camelCase) — common events, attached at document level
<button onClick={handleClick}>Click</button>

// Native (on: prefix) — for non-bubbling, custom events, or stopPropagation
<div on:customEvent={handler} />

// Bound handler (avoids closure allocation)
<button onClick={[handler, data]}>Click</button>
// equivalent to: (e) => handler(data, e)
```

**`onInput` for per-keystroke**, not `onChange` (which fires on blur in Solid).

### Attributes

```tsx
// classList — conditional classes
<div classList={{ active: isActive(), disabled: isDisabled() }} />

// style — dash-case keys
<div style={{ "background-color": color(), "font-size": "16px" }} />

// ref — variable assignment (assigned at creation, before DOM insertion)
let myRef!: HTMLDivElement
<div ref={myRef} />

// ref — callback
<input ref={(el) => { /* el available at creation time */ }} />

// Directives
<div use:clickOutside={() => setOpen(false)} />

// Property vs Attribute forcing
<input prop:value={val()} />
<div attr:data-custom="value" />
```

Refs are assigned at element creation time (before DOM insertion), not after mount. Solid does not call ref callbacks with `null` on cleanup — use `onCleanup` separately.

## Context

```tsx
const ThemeContext = createContext<{ theme: string; toggle: () => void }>()

function ThemeProvider(props: ParentProps) {
  const [theme, setTheme] = createSignal("light")
  const value = {
    get theme() { return theme() },
    toggle: () => setTheme(t => t === "light" ? "dark" : "light"),
  }
  return <ThemeContext.Provider value={value}>{props.children}</ThemeContext.Provider>
}

function useTheme() {
  const ctx = useContext(ThemeContext)
  if (!ctx) throw new Error("useTheme must be used within ThemeProvider")
  return ctx
}
```

**SSR warning**: Module-level singletons share state between requests. Use Context for SSR-safe state.

## Resources (Data Fetching)

```tsx
const [userId, setUserId] = createSignal(1)

const [user, { mutate, refetch }] = createResource(userId, async (id) => {
  const res = await fetch(`/api/users/${id}`)
  if (!res.ok) throw new Error("Failed to fetch")
  return res.json()
})

// Properties: user(), user.loading, user.error, user.state, user.latest
```

`user.latest` retains the last successful value during refetches — useful for showing stale data while refreshing.

## TypeScript Patterns

```tsx
import type { Component, ParentComponent, VoidComponent } from "solid-js"

// No children
const MyButton: Component<{ label: string }> = (props) => {
  return <button>{props.label}</button>
}

// Optional children
const MyCard: ParentComponent<{ title: string }> = (props) => {
  return <div><h2>{props.title}</h2>{props.children}</div>
}

// No children allowed
const MyIcon: VoidComponent<{ name: string }> = (props) => {
  return <i class={`icon-${props.name}`} />
}

// Generic component (Component type doesn't support generics)
const List = <T,>(props: { items: T[]; render: (item: T) => JSX.Element }): JSX.Element => {
  return <ul><For each={props.items}>{(item) => <li>{props.render(item)}</li>}</For></ul>
}
```

Store typing with path-based setters is fully inferred:

```tsx
const [store, setStore] = createStore<{ user: { name: string; age: number } }>({
  user: { name: "Alice", age: 30 },
})
setStore("user", "name", "Bob") // fully typed
```

## Performance

- **Derived signals** (plain functions) for cheap computations; `createMemo` only when caching helps
- **`<For>`** for object arrays, **`<Index>`** for primitive arrays
- **`<Show>`** over ternaries/`&&` — proper reactive boundaries
- **`batch()`** for multiple signal updates that should trigger one recomputation
- **`lazy()`** for code splitting:

```tsx
const AdminPanel = lazy(() => import("./AdminPanel"))
// Wrap in <Suspense fallback={...}>
```

- **Transitions** to keep current UI while loading new content:

```tsx
const [isPending, start] = useTransition()
start(() => setPage(newPage))
// isPending() is true until async work resolves
```

## Routing (@solidjs/router)

```tsx
import { Router, Route, A, useParams, useNavigate } from "@solidjs/router"

<Router>
  <Route path="/" component={Home} />
  <Route path="/users/:id" component={UserDetail} preload={preloadUser} />
  <Route path="*404" component={NotFound} />
</Router>
```

Data loading with `query` + `createAsync`:

```tsx
import { query, createAsync } from "@solidjs/router"

const getUser = query(async (id: string) => {
  return (await fetch(`/api/users/${id}`)).json()
}, "user")

function preloadUser({ params }) { void getUser(params.id) }

function UserDetail() {
  const params = useParams()
  const user = createAsync(() => getUser(params.id))
  return <Show when={user()}>{(u) => <h1>{u().name}</h1>}</Show>
}
```

## Testing

**TDD**: Write all tests first as a spec, then implement, then verify all pass. (Tests → Impl → Green)

```tsx
import { render, screen } from "@solidjs/testing-library"
import userEvent from "@testing-library/user-event"

test("increments counter", async () => {
  render(() => <Counter />) // note: wrapping function required
  expect(screen.getByText("Count: 0")).toBeInTheDocument()
  await userEvent.click(screen.getByRole("button"))
  expect(screen.getByText("Count: 1")).toBeInTheDocument()
})
```

- `render(() => <Component />)` — wrapping function is required
- No `rerender` method — Solid components don't re-render
- Updates are near-synchronous; `waitFor` rarely needed except for Suspense/resources

## Styling

- **Tailwind CSS**: first-class support. Use `classList` for conditional classes
- **CSS Modules**: built-in via Vite (`.module.css`)
- **solid-styled**: reactive scoped stylesheets (needs babel plugin)

## Common Pitfalls Checklist

1. **Destructuring props or stores** — kills reactivity. Use `mergeProps`, `splitProps`, direct access
2. **Reading signals outside tracking scope** — captures once, never updates. Wrap in reactive context or use derived signal
3. **Setting signals in effects** — usually a `createMemo` instead
4. **`onChange` for text input** — fires on blur. Use `onInput`
5. **`event.stopPropagation()` with delegated events** — delegated events attach at document level. Use `on:click` for native attachment
6. **Conditionals without control flow** — `&&` and ternaries don't create reactive boundaries. Use `<Show>`, `<Switch>/<Match>`
7. **Global singleton state with SSR** — shared between requests. Use Context
8. **`onCleanup` after `await`** — async breaks tracking scope. Call `onCleanup` before any `await`
9. **Refs before mount** — refs are assigned at creation (before DOM insertion). Use `onMount` to interact with mounted elements

## When Using TanStack Start

Read `references/tanstack-start.md` for the complete TanStack Start with SolidJS guide covering project setup, file-based routing, server functions, middleware, SSR, API routes, auth patterns, and deployment.
