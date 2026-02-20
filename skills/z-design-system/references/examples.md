# Component Patterns

---

## Headless Hook Pattern

Separates behavior from presentation. Headless handles a11y + keyboard + state. Styled applies tokens.

```typescript
// headless/useToggle.ts — controlled + uncontrolled pattern
interface UseToggleProps {
  defaultValue?: boolean;
  value?: boolean;          // controlled
  onChange?: (value: boolean) => void;
}

export function useToggle(props: UseToggleProps) {
  const { defaultValue = false, value: controlledValue, onChange } = props;
  const [internalValue, setInternalValue] = useState(defaultValue);

  const isControlled = controlledValue !== undefined;
  const isOn = isControlled ? controlledValue : internalValue;

  const toggle = useCallback(() => {
    const newValue = !isOn;
    if (!isControlled) setInternalValue(newValue);
    onChange?.(newValue);
  }, [isOn, isControlled, onChange]);

  return {
    toggleProps: { role: 'switch', 'aria-checked': isOn, onClick: toggle },
    state: { isOn },
    toggle,
  };
}
```

**Rule: Every headless hook must support both controlled (`value` prop) and uncontrolled (`defaultValue`) modes.**

Claude can derive useButton, useDialog, etc. from this pattern. Key requirements:
- `role`, `aria-*`, `tabIndex` in returned props object
- Keyboard handling (Enter/Space for buttons, Escape for dialogs)
- Focus trapping for modals (query focusable elements, handle Tab/Shift+Tab)

---

## Compound Components

```tsx
const CardContext = createContext<{ variant: 'elevated' | 'outlined' } | null>(null);

function CardRoot({ variant = 'elevated', children }: { variant?: 'elevated' | 'outlined'; children: React.ReactNode }) {
  return (
    <CardContext.Provider value={{ variant }}>
      <View style={[styles.card, variant === 'elevated' && styles.elevated]}>{children}</View>
    </CardContext.Provider>
  );
}

// Sub-components: CardHeader, CardTitle, CardContent, CardFooter
export const Card = Object.assign(CardRoot, {
  Header: CardHeader, Title: CardTitle, Content: CardContent, Footer: CardFooter,
});

// Usage
<Card variant="elevated">
  <Card.Header><Card.Title>Welcome</Card.Title></Card.Header>
  <Card.Content><Text>Body</Text></Card.Content>
  <Card.Footer><Button>Action</Button></Card.Footer>
</Card>
```

**Rule: Use `Object.assign(Root, { Sub })` for compound export. Context shares variant/state across sub-components.**

---

## Variant Props (not booleans)

```tsx
// ❌ <Button primary large outline /> — conflicting states possible
interface BadProps { primary?: boolean; secondary?: boolean; large?: boolean; }

// ✅ <Button variant="outline" colorScheme="primary" size="lg" /> — mutually exclusive
interface GoodProps {
  variant?: 'solid' | 'outline' | 'ghost';
  colorScheme?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
}
```
