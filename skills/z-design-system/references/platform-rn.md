# Platform: React Native

## Token Output (TypeScript)

```typescript
export const tokens = {
  color: {
    bg: { primary: '#ffffff', secondary: '#f9fafb' },
    text: { primary: '#0f172a', secondary: '#475569' },
    interactive: { primary: '#2563eb' },
  },
  spacing: {
    component: { xs: 4, sm: 8, md: 12, lg: 16, xl: 24 },
    layout: { xs: 16, sm: 24, md: 32, lg: 48, xl: 64 },
  },
} as const;
```

## Dark Mode

- Use `useColorScheme()` hook to detect system preference
- Theme provider swaps semantic token set — components stay unchanged

```typescript
import { useColorScheme } from 'react-native';

const scheme = useColorScheme(); // 'light' | 'dark'
const theme = scheme === 'dark' ? darkTokens : lightTokens;
```

## Styled Component Example

Headless hook + tokens applied to a React Native component:

```tsx
import { useButton } from '../headless/useButton';
import { tokens } from '@/shared/ui/tokens';

const variants = {
  solid: { bg: tokens.color.interactive.primary, text: tokens.color.text.inverse },
  outline: { bg: 'transparent', text: tokens.color.interactive.primary, border: tokens.color.interactive.primary },
  ghost: { bg: 'transparent', text: tokens.color.interactive.primary },
};

const sizes = {
  sm: { px: tokens.spacing.component.md, py: tokens.spacing.component.xs, fontSize: 14 },
  md: { px: tokens.spacing.component.lg, py: tokens.spacing.component.sm, fontSize: 16 },
  lg: { px: tokens.spacing.component.xl, py: tokens.spacing.component.md, fontSize: 18 },
};

interface ButtonProps {
  variant?: keyof typeof variants;
  size?: keyof typeof sizes;
  disabled?: boolean;
  loading?: boolean;
  onPress?: () => void;
  children: React.ReactNode;
}

export function Button({ variant = 'solid', size = 'md', children, ...props }: ButtonProps) {
  const { buttonProps, state } = useButton(props);
  const v = variants[variant];
  const s = sizes[size];

  return (
    <Pressable {...buttonProps} style={{
      backgroundColor: v.bg,
      paddingHorizontal: s.px,
      paddingVertical: s.py,
      borderRadius: tokens.radius.md,
      opacity: state.isDisabled ? 0.5 : 1,
    }}>
      {state.isLoading ? <ActivityIndicator color={v.text} /> : (
        <Text style={{ color: v.text, fontSize: s.fontSize, fontWeight: '600' }}>{children}</Text>
      )}
    </Pressable>
  );
}
```

**Rule: Variant/size maps use tokens only. No hardcoded colors or spacing.**

## Token Usage

```typescript
import { tokens } from '@/tokens';

const styles = StyleSheet.create({
  buttonPrimary: {
    backgroundColor: tokens.color.interactive.primary,
    paddingHorizontal: tokens.spacing.component.lg,
    paddingVertical: tokens.spacing.component.md,
    borderRadius: tokens.radius.md,
  },
});
```

## Responsive

Use `useWindowDimensions` for layout adaptation:

```typescript
import { useWindowDimensions } from 'react-native';

const { width } = useWindowDimensions();
const isTablet = width >= 768;
const isDesktop = width >= 1024;
```

## Icons

- Package: `lucide-react-native`
- Import: `import { ChevronRight } from 'lucide-react-native'`

## Accessibility

- Use `accessibilityRole`, `accessibilityLabel` instead of ARIA attributes
- Decorative icons: `accessibilityElementsHidden={true}`
- Touch targets: 44×44pt minimum enforced via `minHeight` / `minWidth`
- Reduced motion: `useReducedMotion()` from `react-native-reanimated`
