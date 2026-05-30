# React 19 API Changes

If the project uses React 19+, apply these changes to all component patterns.

## ref is a regular prop — no forwardRef

```tsx
// ❌ React 18 — forwardRef wrapper
const Button = forwardRef<HTMLButtonElement, ButtonProps>((props, ref) => {
  return <button ref={ref} {...props} />;
});

// ✅ React 19 — ref in props directly
function Button({ ref, ...props }: ButtonProps & { ref?: React.Ref<HTMLButtonElement> }) {
  return <button ref={ref} {...props} />;
}
```

## use(Context) replaces useContext(Context)

```tsx
// ❌ React 18
const ctx = useContext(CardContext);

// ✅ React 19
const ctx = use(CardContext);
```

`use()` can be called conditionally and in loops, unlike `useContext()`.

## When to Apply

- Update all headless hooks and compound components accordingly
- No `forwardRef` — `ref` is a regular prop. Just accept `ref` in the props interface
- `use(Context)` replaces `useContext(Context)` — use the `use()` API to read context values

## Form & action APIs (out of scope for the design system)

React 19 also adds the form/action model: `<form action={fn}>`, `useActionState(fn, initialState)` (the stable replacement for the canary-era `useFormState`, imported from `react`), `useFormStatus` (from `react-dom`), and `useOptimistic`. These drive form submission and server actions — wiring that belongs with the consumer/feature layer, not the design-system primitives. A styled `Form`/`Field` here should stay presentational and let the consumer own the action.
