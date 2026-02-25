# Component Patterns

## Pattern 1: Flat API (Simple Components)

Best for components with few visual variations and no behavioral differences between variants. Use constrained props for appearance (size, colorScheme), but never boolean props for modes.

```tsx
// Button — flat with constrained visual props.
interface ButtonProps {
  size?: 'sm' | 'md' | 'lg';
  colorScheme?: 'primary' | 'secondary' | 'danger';
  disabled?: boolean;
  children: React.ReactNode;
  ref?: React.Ref<HTMLButtonElement>;   // React 19: ref is a regular prop
}

export function Button({
  size = 'md',
  colorScheme = 'primary',
  disabled,
  children,
  ref,
  ...props
}: ButtonProps) {
  // size + colorScheme → resolve to tokens
  return <button ref={ref} disabled={disabled} {...props}>{children}</button>;
}

// Usage: simple, no ceremony
<Button size="lg" colorScheme="primary">Save</Button>
```

Good candidates for flat: Button, Badge, Avatar, Input, Chip, Tag, Switch, Spinner.

## Pattern 2: Explicit Variant Components

When a prop changes **behavior** — not just appearance — split into a separate component. Don't add a boolean or mode prop to an existing component.

```tsx
// ❌ Boolean mode prop — changes behavior inside one component
<Button icon={<Trash />} iconOnly />
<Button href="/about" />
<Button type="submit" loading />

// ✅ Explicit variant components — each owns its behavior
<IconButton icon={<Trash />} label="Delete" />
<LinkButton href="/about">About</LinkButton>
<SubmitButton loading>Save</SubmitButton>
```

Why separate components: Each variant has different ARIA needs, event handling, and rendered elements. `<LinkButton>` renders `<a>`, `<SubmitButton>` renders `<button type="submit">`, `<IconButton>` needs `aria-label`. Cramming these into one component with booleans creates untestable branching logic.

### Implementation: Share a base, diverge on behavior

```tsx
// Shared base — visual only
function ButtonBase({
  size = 'md',
  colorScheme = 'primary',
  className,
  children,
  ref,
  ...props
}: ButtonBaseProps) {
  const styles = resolveButtonTokens(size, colorScheme);
  return <Slot ref={ref} className={cn(styles, className)} {...props}>{children}</Slot>;
}

// Variant: standard button
export function Button({ children, ref, ...props }: ButtonProps) {
  return <ButtonBase ref={ref} {...props}><button>{children}</button></ButtonBase>;
}

// Variant: link that looks like a button
export function LinkButton({ href, children, ref, ...props }: LinkButtonProps) {
  return <ButtonBase ref={ref} {...props}><a href={href}>{children}</a></ButtonBase>;
}

// Variant: icon-only button
export function IconButton({ icon, label, ref, ...props }: IconButtonProps) {
  return (
    <ButtonBase ref={ref} {...props}>
      <button aria-label={label}>{icon}</button>
    </ButtonBase>
  );
}
```

When to split: A prop changes the rendered element, ARIA role, event handling, or required children. If the difference is purely visual (color, size), keep it as a prop on the same component.

## Pattern 3: Compound API (Flexible Layout)

Best when internal structure varies between uses. Sub-components share state via a **structured context interface** with `{ state, actions, meta }`.

```tsx
// Structured context — state, actions, and meta are always separate.
// The provider is the ONLY place that knows how state is managed.
interface CardContextValue {
  state: {
    variant: 'elevated' | 'outlined';
    expanded: boolean;
  };
  actions: {
    toggleExpand: () => void;
  };
  meta: {
    id: string;
  };
}

const CardContext = createContext<CardContextValue | null>(null);

function CardRoot({
  variant = 'elevated',
  defaultExpanded = false,
  children,
}: {
  variant?: 'elevated' | 'outlined';
  defaultExpanded?: boolean;
  children: React.ReactNode;
}) {
  const [expanded, setExpanded] = useState(defaultExpanded);
  const id = useId();

  const ctx: CardContextValue = {
    state: { variant, expanded },
    actions: { toggleExpand: () => setExpanded(prev => !prev) },
    meta: { id },
  };

  return (
    <CardContext value={ctx}>
      <div className={cn(styles.card, variant === 'elevated' && styles.elevated)}>
        {children}
      </div>
    </CardContext>
  );
}

// Sub-components read context via use() (React 19)
function CardHeader({ children }: { children: React.ReactNode }) {
  const { state, actions } = use(CardContext)!;
  return (
    <div className={styles.header} onClick={actions.toggleExpand}>
      {children}
      {state.expanded ? <ChevronUp /> : <ChevronDown />}
    </div>
  );
}

function CardContent({ children }: { children: React.ReactNode }) {
  const { state } = use(CardContext)!;
  if (!state.expanded) return null;
  return <div className={styles.content}>{children}</div>;
}

function CardFooter({ children }: { children: React.ReactNode }) {
  return <div className={styles.footer}>{children}</div>;
}

export const Card = Object.assign(CardRoot, {
  Header: CardHeader,
  Content: CardContent,
  Footer: CardFooter,
});

// Usage: flexible composition via children
<Card variant="elevated">
  <Card.Header>Title</Card.Header>
  <Card.Content>Body text</Card.Content>
</Card>

// Different layout, same component
<Card variant="outlined">
  <Card.Content>Just content, no header or footer</Card.Content>
  <Card.Footer><Button>Action</Button></Card.Footer>
</Card>
```

### Why structured context `{ state, actions, meta }`

The provider is the **only** place that knows how state is managed. Sub-components and consumers interact through the context interface — they never know if state comes from `useState`, Zustand, or a URL param. This makes the state implementation swappable without changing any consumers.

- `state` — read-only current values
- `actions` — functions to mutate state (the "how" is hidden)
- `meta` — derived/stable values like IDs, computed labels

### Children over render props

Always compose via `children`. Avoid `renderX` props.

```tsx
// ❌ Render prop — pushes control to parent unnecessarily
<Card renderHeader={(ctx) => <h2>{ctx.title}</h2>} />

// ✅ Children — consumer composes freely
<Card>
  <Card.Header><h2>Title</h2></Card.Header>
</Card>
```

Render props are only acceptable when the parent must pass **computed data** to the child (e.g., `<Virtualizer renderItem={(item, index) => ...} />`).

Good candidates for compound: Card, Dialog, Dropdown, Accordion, Tabs, Form, NavigationMenu.

## Pattern 4: Headless Hook (Reusable Behavior)

Separates behavior from appearance entirely. The hook handles a11y, keyboard, and state. The styled component applies tokens.

```typescript
// headless/useToggle.ts
interface UseToggleProps {
  defaultValue?: boolean;
  value?: boolean;           // controlled mode
  onChange?: (value: boolean) => void;
  disabled?: boolean;
}

export function useToggle(props: UseToggleProps) {
  const { defaultValue = false, value: controlled, onChange, disabled } = props;
  const [internal, setInternal] = useState(defaultValue);

  const isControlled = controlled !== undefined;
  const isOn = isControlled ? controlled : internal;

  const toggle = useCallback(() => {
    if (disabled) return;
    const next = !isOn;
    if (!isControlled) setInternal(next);
    onChange?.(next);
  }, [isOn, isControlled, onChange, disabled]);

  return {
    toggleProps: {
      role: 'switch' as const,
      'aria-checked': isOn,
      'aria-disabled': disabled || undefined,
      onClick: toggle,
      onKeyDown: (e: KeyboardEvent) => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); }
      },
      tabIndex: disabled ? -1 : 0,
    },
    state: { isOn, isDisabled: !!disabled },
    toggle,
  };
}
```

Every headless hook must support:
- **Controlled + uncontrolled**: `value` prop (controlled) and `defaultValue` (uncontrolled)
- **ARIA attributes**: role, aria-checked/aria-expanded/etc
- **Keyboard**: Enter/Space for actions, Escape for dismiss, Tab for navigation
- **Disabled state**: No interaction, removed from tab order

Good candidates for headless: Toggle, Dialog, Dropdown, Accordion, Tooltip, Combobox — anything with complex keyboard/focus patterns.

## React 19 API Changes

If the project uses React 19+, apply these changes to all component patterns:

### ref is a regular prop — no forwardRef

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

### use(Context) replaces useContext(Context)

```tsx
// ❌ React 18
const ctx = useContext(CardContext);

// ✅ React 19
const ctx = use(CardContext);
```

`use()` can be called conditionally and in loops, unlike `useContext()`.

## When to Upgrade

A flat component should split into **explicit variant components** when:
- A prop changes the rendered element (`<a>` vs `<button>`)
- A prop changes ARIA roles or required attributes
- A prop changes event handling or interaction model
- You're adding boolean modes like `iconOnly`, `asLink`, `isSubmit`

A flat component should become **compound** when:
- It has 5+ configuration props for layout control
- Consumers need different internal arrangements
- You're adding `showHeader`, `headerTitle`, `showFooter` type props

A standalone component should get a **headless hook** when:
- The same behavior appears in multiple visual forms
- Keyboard/focus logic is complex enough to be buggy if duplicated
- You need the behavior without any specific UI (e.g., form validation state)

## States Checklist

Every interactive component covers these states:

| State | Visual | Behavior |
|-------|--------|----------|
| Default | Base appearance | Responds to interaction |
| Hover | Subtle highlight | Cursor pointer |
| Focus | Visible outline (2px+) | Keyboard reachable |
| Active/Pressed | Depressed appearance | Action fires |
| Disabled | Reduced opacity (0.5) | No interaction, no tab |
| Loading | Spinner or skeleton | No interaction during |
