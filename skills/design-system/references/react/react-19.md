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
