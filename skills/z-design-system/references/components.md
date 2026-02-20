# Component Patterns

## Pattern 1: Flat API (Simple Components)

Best for components with few, well-defined variations. Fast to write, easy to use.

```tsx
// Button — flat is enough. No sub-components needed.
interface ButtonProps {
  variant?: 'solid' | 'outline' | 'ghost';
  colorScheme?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  children: React.ReactNode;
  onPress?: () => void;
}

export function Button({
  variant = 'solid',
  colorScheme = 'primary',
  size = 'md',
  children,
  ...props
}: ButtonProps) {
  const { buttonProps, state } = useButton(props);
  // variant + colorScheme + size → resolve to tokens
  return <Pressable {...buttonProps}>...</Pressable>;
}

// Usage: simple, no ceremony
<Button variant="outline" size="lg">Save</Button>
```

Why variant props over booleans: `<Button primary large>` allows `<Button primary secondary>` — conflicting states. Variant unions are mutually exclusive by type system.

Good candidates for flat: Button, Badge, Avatar, Input, Chip, Tag, Switch, Spinner.

## Pattern 2: Compound API (Flexible Layout)

Best when internal structure varies between uses. Sub-components share state via context.

```tsx
// Card — layout varies. Sometimes has footer, sometimes not.
const CardContext = createContext<{ variant: 'elevated' | 'outlined' } | null>(null);

function CardRoot({
  variant = 'elevated',
  children,
}: {
  variant?: 'elevated' | 'outlined';
  children: React.ReactNode;
}) {
  return (
    <CardContext.Provider value={{ variant }}>
      <View style={[styles.card, variant === 'elevated' && styles.elevated]}>
        {children}
      </View>
    </CardContext.Provider>
  );
}

function CardHeader({ children }: { children: React.ReactNode }) {
  return <View style={styles.header}>{children}</View>;
}

function CardContent({ children }: { children: React.ReactNode }) {
  return <View style={styles.content}>{children}</View>;
}

function CardFooter({ children }: { children: React.ReactNode }) {
  return <View style={styles.footer}>{children}</View>;
}

export const Card = Object.assign(CardRoot, {
  Header: CardHeader,
  Content: CardContent,
  Footer: CardFooter,
});

// Usage: flexible composition
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

Why `Object.assign`: Keeps the compound API ergonomic (`Card.Header` not `CardHeader`), and auto-complete works in editors.

Good candidates for compound: Card, Dialog, Dropdown, Accordion, Tabs, Form, NavigationMenu.

## Pattern 3: Headless Hook (Reusable Behavior)

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

## When to Upgrade

A flat component should become compound when:
- It has 5+ configuration props for layout control
- Consumers need different internal arrangements
- You're adding `showHeader`, `headerTitle`, `showFooter` type props

A standalone component should get a headless hook when:
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
